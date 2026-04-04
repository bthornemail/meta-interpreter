#!/usr/bin/env python3
"""
Timed media surface smoke check.

This validates downstream media/capture surface behavior only.
It does not validate runtime law.
"""

from __future__ import annotations

import html
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import time
import urllib.request
from contextlib import closing
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEMO_SERVER = ROOT / "demo" / "browser" / "servers" / "ttc_runtime_stream_server.py"
SNAPSHOT_RE = re.compile(
    r'<script[^>]*id=["\'](?P<id>ttc-(?:projection|media)-snapshot)["\'][^>]*>(?P<payload>.*?)</script>',
    re.DOTALL | re.IGNORECASE,
)


def find_port() -> int:
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def find_chromium() -> str:
    for candidate in ("chromium", "chromium-browser", "google-chrome", "/snap/bin/chromium"):
        path = shutil.which(candidate) if not candidate.startswith("/") else candidate
        if path and Path(path).exists():
            return path
    raise SystemExit("media check failed: chromium not found")


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
    raise SystemExit(f"media check failed: server did not start ({last_error})")


def dump_dom(chromium: str, url: str) -> str:
    result = subprocess.run(
        [
            chromium,
            "--headless=new",
            "--disable-gpu",
            "--no-sandbox",
            "--run-all-compositor-stages-before-draw",
            "--virtual-time-budget=9000",
            "--dump-dom",
            url,
        ],
        check=True,
        cwd=str(ROOT),
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    return result.stdout


def extract_snapshots(dom: str) -> dict[str, dict[str, object]]:
    found: dict[str, dict[str, object]] = {}
    for match in SNAPSHOT_RE.finditer(dom):
        found[match.group("id")] = json.loads(html.unescape(match.group("payload")).strip())
    return found


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


def main() -> int:
    chromium = find_chromium()
    port = find_port()
    server = run_server(port)

    try:
        wait_for_server(f"http://127.0.0.1:{port}/browser/projection/ttc_projection_media.html")
        static_dom = dump_dom(chromium, f"http://127.0.0.1:{port}/browser/projection/ttc_projection_demo.html?projection_check=1")
        media_dom = dump_dom(
            chromium,
            (
                f"http://127.0.0.1:{port}/browser/projection/ttc_projection_media.html"
                "?autoconnect=1&autostart_media=1&probe_constraints=1&input=A&rule=current&stop_after=1"
            ),
        )

        static_snapshots = extract_snapshots(static_dom)
        media_snapshots = extract_snapshots(media_dom)
        baseline = static_snapshots.get("ttc-projection-snapshot")
        projection = media_snapshots.get("ttc-projection-snapshot")
        media = media_snapshots.get("ttc-media-snapshot")

        if not baseline or not projection or not media:
            raise SystemExit("media check failed: required snapshot(s) missing")

        fields = [
            "step",
            "digest",
            "triplet",
            "order",
            "seq56",
            "layer",
            "coords",
            "coeff",
            "material_class",
            "state_class",
            "carrier_resolution",
            "artifact_class",
            "workflow_mode",
            "frame_scope_kind",
            "frame_scope_ref",
            "resolved_step_identity",
            "ui_frame_resolution",
            "canvas_data_url",
        ]
        for field in fields:
            if projection.get(field) != baseline.get(field):
                raise SystemExit(
                    f"media check failed: projection divergence on {field}: {projection.get(field)!r} != {baseline.get(field)!r}"
                )
            if media.get(field) != baseline.get(field):
                raise SystemExit(
                    f"media check failed: media snapshot divergence on {field}: {media.get(field)!r} != {baseline.get(field)!r}"
                )

        if media.get("digest_preserved") is not True:
            raise SystemExit("media check failed: digest not preserved as text")
        if not isinstance(media.get("supported_constraints_count"), int) or media["supported_constraints_count"] <= 0:
            raise SystemExit("media check failed: supported constraints probe empty")
        if media.get("media_source_supported") is not True:
            raise SystemExit("media check failed: MediaSource unsupported in check browser")
        if media.get("media_profile") not in {"high", "fallback"}:
            raise SystemExit(f"media check failed: unexpected media profile {media.get('media_profile')!r}")
        if media.get("media_session_available") is not True:
            raise SystemExit("media check failed: Media Session unavailable in check browser")
        if media.get("media_session_installed") is not True:
            raise SystemExit("media check failed: Media Session handlers not installed")
        if media.get("mse_started_once") is not True:
            raise SystemExit("media check failed: timed media path never started")

        summary = {
            "step": media["step"],
            "digest": media["digest"],
            "triplet": media["triplet"],
            "order": media["order"],
            "seq56": media["seq56"],
            "layer": media["layer"],
            "coords": media["coords"],
            "coeff": media["coeff"],
            "material_class": media["material_class"],
            "state_class": media["state_class"],
            "carrier_resolution": media["carrier_resolution"],
            "artifact_class": media["artifact_class"],
            "workflow_mode": media["workflow_mode"],
            "frame_scope_kind": media["frame_scope_kind"],
            "resolved_step_identity": media["resolved_step_identity"],
            "media_profile": media["media_profile"],
            "supported_constraints_count": media["supported_constraints_count"],
        }
        print("media surface check passed")
        print(json.dumps(summary, indent=2, sort_keys=True))
        return 0
    finally:
        server.terminate()
        try:
            server.wait(timeout=5)
        except subprocess.TimeoutExpired:
            server.kill()
            server.wait(timeout=5)


if __name__ == "__main__":
    raise SystemExit(main())
