#!/usr/bin/env python3
"""
Validate deterministic narrative frame export.

Frame export is projection-only. It derives frame witnesses and projection
receipts from normalized scenes and local interpolation; it does not alter
canonical narrative authority.
"""

from __future__ import annotations

import filecmp
import html
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import urllib.request
from contextlib import closing
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
EXPORTER = ROOT / "scripts" / "narrative" / "export_narrative_frames.mjs"
DEMO_SERVER = ROOT / "demo" / "browser" / "servers" / "ttc_runtime_stream_server.py"
PAGE = ROOT / "demo" / "browser" / "narrative" / "ttc_narrative_frame_witness.html"
SNAPSHOT_RE = re.compile(
    r'<script[^>]*id=["\']ttc-narrative-frame-witness-snapshot["\'][^>]*>(.*?)</script>',
    re.DOTALL | re.IGNORECASE,
)


def find_port() -> int:
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def find_chromium() -> str:
    for candidate in ("google-chrome", "chromium", "chromium-browser", "/snap/bin/chromium"):
        path = shutil.which(candidate) if not candidate.startswith("/") else candidate
        if path and Path(path).exists():
            return path
    raise SystemExit("narrative frame export check failed: chromium not found")


def wait_for_server(url: str, timeout: float = 10.0) -> None:
    deadline = time.time() + timeout
    last_error: Exception | None = None
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(url, timeout=1.0) as response:
                if 200 <= response.status < 500:
                    return
        except Exception as exc:  # noqa: BLE001
            last_error = exc
            time.sleep(0.1)
    raise SystemExit(f"narrative frame export check failed: server did not start ({last_error})")


def dump_dom(chromium: str, url: str) -> str:
    result = subprocess.run(
        [
            chromium,
            "--headless=new",
            "--disable-gpu",
            "--no-sandbox",
            "--run-all-compositor-stages-before-draw",
            "--virtual-time-budget=6000",
            "--dump-dom",
            url,
        ],
        cwd=str(ROOT),
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    return result.stdout


def extract_snapshot(dom: str) -> dict[str, object]:
    match = SNAPSHOT_RE.search(dom)
    if not match:
        raise SystemExit("narrative frame export check failed: witness snapshot missing from DOM")
    return json.loads(html.unescape(match.group(1)).strip())


def run_server(port: int) -> subprocess.Popen[str]:
    env = os.environ.copy()
    return subprocess.Popen(
        [sys.executable, str(DEMO_SERVER), "--host", "127.0.0.1", "--port", str(port)],
        cwd=str(ROOT),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=env,
    )


def run_export(out_dir: Path) -> None:
    subprocess.run(
        [
            "node",
            str(EXPORTER),
            "--chapter",
            "ch_dcdf6301992e",
            "--from-step",
            "16",
            "--to-step",
            "17",
            "--out-dir",
            str(out_dir),
            "--mode",
            "witness",
            "--frame",
            "replay_timeline",
            "--attention",
            "narrow",
            "--depth",
            "more",
            "--frames",
            "8",
        ],
        cwd=str(ROOT),
        check=True,
        stdout=subprocess.DEVNULL,
    )


def assert_page_controls() -> None:
    page_text = PAGE.read_text(encoding="utf-8")
    for label in ("Mode", "Frame", "Narrow", "Expand", "More", "Less"):
        if label not in page_text:
            raise SystemExit(f"narrative frame export check failed: missing attention-law control label {label!r}")
    for marker in ("Primary Public Entry Surface", "public-witness-law", "poly-shell-a"):
        if marker not in page_text:
            raise SystemExit(f"narrative frame export check failed: missing public-entry witness marker {marker!r}")


def main() -> int:
    if not shutil.which("node"):
        raise SystemExit("narrative frame export check failed: node not found")
    chromium = find_chromium()
    assert_page_controls()

    with tempfile.TemporaryDirectory() as first_tmp, tempfile.TemporaryDirectory() as second_tmp:
        first = Path(first_tmp)
        second = Path(second_tmp)
        run_export(first)
        run_export(second)

        first_manifest = first / "manifest.json"
        second_manifest = second / "manifest.json"
        first_receipts = first / "projection_receipts.ndjson"
        second_receipts = second / "projection_receipts.ndjson"

        if not filecmp.cmp(first_manifest, second_manifest, shallow=False):
            raise SystemExit("narrative frame export check failed: manifest drift")
        if not filecmp.cmp(first_receipts, second_receipts, shallow=False):
            raise SystemExit("narrative frame export check failed: receipt drift")

        manifest = json.loads(first_manifest.read_text(encoding="utf-8"))
        receipts = [json.loads(line) for line in first_receipts.read_text(encoding="utf-8").splitlines() if line.strip()]

        if manifest.get("frame_total") != 8 or len(receipts) != 8:
            raise SystemExit("narrative frame export check failed: unexpected frame count")
        if receipts[0]["scene_hash"] == receipts[-1]["scene_hash"]:
            raise SystemExit("narrative frame export check failed: interpolation did not change scene hash")
        if receipts[0]["svg_hash"] == receipts[-1]["svg_hash"]:
            raise SystemExit("narrative frame export check failed: interpolation did not change SVG hash")
        if receipts[0]["aframe_scene_hash"] == receipts[-1]["aframe_scene_hash"]:
            raise SystemExit("narrative frame export check failed: interpolation did not change A-Frame scene hash")

        for index in range(8):
            frame_name = f"frame_{index:03d}.svg"
            if not filecmp.cmp(first / "frames" / frame_name, second / "frames" / frame_name, shallow=False):
                raise SystemExit(f"narrative frame export check failed: frame drift for {frame_name}")

        summary = {
            "chapter_id": manifest["chapter_id"],
            "from_step": manifest["from_step"],
            "to_step": manifest["to_step"],
            "frame_total": manifest["frame_total"],
            "first_scene_hash": receipts[0]["scene_hash"],
            "last_scene_hash": receipts[-1]["scene_hash"],
        }

        demo_export_root = ROOT / "demo" / "narrative" / "derived" / "_frame_export_check"
        if demo_export_root.exists():
            shutil.rmtree(demo_export_root)
        shutil.copytree(first, demo_export_root)
        port = find_port()
        server = run_server(port)
        try:
            wait_for_server(f"http://127.0.0.1:{port}/browser/narrative/ttc_narrative_frame_witness.html")
            base_url = (
                f"http://127.0.0.1:{port}/browser/narrative/ttc_narrative_frame_witness.html"
                "?manifest=narrative/derived/_frame_export_check/manifest.json"
                "&receipts=narrative/derived/_frame_export_check/projection_receipts.ndjson"
                "&frame=3"
            )
            snapshot = extract_snapshot(
                dump_dom(
                    chromium,
                    base_url,
                )
            )
            receipt = receipts[3]
            if snapshot.get("chapter_id") != manifest["chapter_id"]:
                raise SystemExit("narrative frame export check failed: witness page chapter mismatch")
            if snapshot.get("mode") != "replay":
                raise SystemExit("narrative frame export check failed: witness page did not default to replay")
            if snapshot.get("default_mode_expected") != "replay":
                raise SystemExit("narrative frame export check failed: witness snapshot lost replay expectation")
            if snapshot.get("hash_summary_visible"):
                raise SystemExit("narrative frame export check failed: hash summary visible on first paint")
            if snapshot.get("operator_detail_visible"):
                raise SystemExit("narrative frame export check failed: operator detail visible on first paint")
            if snapshot.get("secondary_tools_visible"):
                raise SystemExit("narrative frame export check failed: loader tools visible on first paint")
            if not snapshot.get("hero_frame_loaded"):
                raise SystemExit("narrative frame export check failed: hero witness did not load")
            if snapshot.get("frame_index") != receipt["frame_index"]:
                raise SystemExit("narrative frame export check failed: witness page frame index mismatch")
            if snapshot.get("scene_hash") != receipt["scene_hash"]:
                raise SystemExit("narrative frame export check failed: witness page scene hash mismatch")
            if snapshot.get("svg_hash") != receipt["svg_hash"]:
                raise SystemExit("narrative frame export check failed: witness page SVG hash mismatch")
            if snapshot.get("aframe_scene_hash") != receipt["aframe_scene_hash"]:
                raise SystemExit("narrative frame export check failed: witness page A-Frame scene hash mismatch")
            if snapshot.get("aframe_markup_hash") != receipt["aframe_markup_hash"]:
                raise SystemExit("narrative frame export check failed: witness page A-Frame markup hash mismatch")
            if snapshot.get("visible_hashes") != {}:
                raise SystemExit("narrative frame export check failed: narrow attention exposed hashes")

            expanded = extract_snapshot(dump_dom(chromium, base_url + "&attention=expand"))
            if not expanded.get("hash_summary_visible"):
                raise SystemExit("narrative frame export check failed: expand did not reveal hashes")
            if expanded.get("operator_detail_visible"):
                raise SystemExit("narrative frame export check failed: expand alone should not reveal operator detail")
            if expanded.get("scene_hash") != receipt["scene_hash"] or expanded.get("svg_hash") != receipt["svg_hash"]:
                raise SystemExit("narrative frame export check failed: expand changed receipt identity")
            if expanded.get("visible_hashes", {}).get("scene_hash") != receipt["scene_hash"]:
                raise SystemExit("narrative frame export check failed: expand visible hashes mismatch")

            deep = extract_snapshot(dump_dom(chromium, base_url + "&attention=expand&depth=more"))
            if not deep.get("operator_detail_visible") or not deep.get("secondary_tools_visible"):
                raise SystemExit("narrative frame export check failed: depth more did not reveal operator detail")
            if deep.get("scene_hash") != receipt["scene_hash"] or deep.get("svg_hash") != receipt["svg_hash"]:
                raise SystemExit("narrative frame export check failed: depth reveal changed receipt identity")
        finally:
            server.terminate()
            try:
                server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait(timeout=5)
            shutil.rmtree(demo_export_root, ignore_errors=True)

        print("narrative frame export check passed")
        print(json.dumps(summary, indent=2, sort_keys=True))
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
