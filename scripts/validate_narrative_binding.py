#!/usr/bin/env python3
"""
Validate that narrative witness binding artifacts are reproducible.

Frozen invariant:
Same canonical chapter corpus + same templates + same witness hooks must
always yield the same narrative witness artifact; any witness/media/UI
adaptation may change only downstream presentation, never canonical
narrative authority.

Scene/SVG invariant:
Same bound narrative step must yield the same normalized scene object and
the same SVG witness. Attention/depth may change presentation only, never
selected chapter/step identity.
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


ROOT = Path(__file__).resolve().parents[1]
BINDER = ROOT / "scripts" / "bind_narrative_to_witness.py"
EXPECTED_NDJSON = ROOT / "demo" / "narrative_data" / "narrative.bound.v0.ndjson"
EXPECTED_JS = ROOT / "demo" / "narrative_data" / "narrative_bound_bundle.js"
PAGE = ROOT / "demo" / "ttc_narrative_witness.html"
DEMO_SERVER = ROOT / "demo" / "ttc_runtime_stream_server.py"
SNAPSHOT_RE = re.compile(
    r'<script[^>]*id=["\']ttc-narrative-scene-snapshot["\'][^>]*>(.*?)</script>',
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
    raise SystemExit("narrative binding check failed: chromium not found")


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
    raise SystemExit(f"narrative binding check failed: server did not start ({last_error})")


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
        raise SystemExit("narrative binding check failed: narrative snapshot missing from DOM")
    payload = html.unescape(match.group(1)).strip()
    return json.loads(payload)


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


def load_snapshot(chromium: str, port: int, **params: str) -> dict[str, object]:
    query = "&".join(f"{key}={value}" for key, value in params.items())
    url = f"http://127.0.0.1:{port}/ttc_narrative_witness.html?{query}"
    return extract_snapshot(dump_dom(chromium, url))


def assert_page_controls() -> None:
    page_text = PAGE.read_text(encoding="utf-8")
    required_controls = ["Mode", "Frame", "Narrow", "Expand", "More", "Less"]
    for label in required_controls:
        if label not in page_text:
            raise SystemExit(f"narrative binding check failed: missing attention-law control label {label!r}")


def assert_reproducible_binding() -> None:
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        ndjson_out = tmp / "narrative.bound.v0.ndjson"
        js_out = tmp / "narrative_bound_bundle.js"
        subprocess.run(
            [
                sys.executable,
                str(BINDER),
                "--out-ndjson",
                str(ndjson_out),
                "--out-js",
                str(js_out),
            ],
            cwd=str(ROOT),
            check=True,
            stdout=subprocess.DEVNULL,
        )
        if not filecmp.cmp(ndjson_out, EXPECTED_NDJSON, shallow=False):
            raise SystemExit("narrative binding check failed: NDJSON artifact drift")
        if not filecmp.cmp(js_out, EXPECTED_JS, shallow=False):
            raise SystemExit("narrative binding check failed: JS bundle drift")


def assert_identical_identity(left: dict[str, object], right: dict[str, object]) -> None:
    identity_keys = ["chapter_id", "step", "scene_id", "template_id"]
    for key in identity_keys:
        if left.get(key) != right.get(key):
            raise SystemExit(
                f"narrative binding check failed: identity drift for {key}: {left.get(key)!r} != {right.get(key)!r}"
            )


def assert_text_stability(snapshot: dict[str, object]) -> None:
    for key in ("chapter_id", "scene_id", "template_id"):
        value = snapshot.get(key)
        if not isinstance(value, str) or not value:
            raise SystemExit(f"narrative binding check failed: {key} is not a stable text identifier")
    active_transition = snapshot.get("active_transition")
    if not isinstance(active_transition, dict):
        raise SystemExit("narrative binding check failed: active_transition missing from snapshot")
    for key in ("semantic_transition_id", "template_transition_id", "template_edge_id"):
        value = active_transition.get(key)
        if not isinstance(value, str) or not value:
            raise SystemExit(f"narrative binding check failed: active transition field {key} lost text stability")


def assert_svg_determinism(chromium: str, port: int, **params: str) -> dict[str, object]:
    first = load_snapshot(chromium, port, **params)
    second = load_snapshot(chromium, port, **params)
    if first.get("scene_json") != second.get("scene_json"):
        raise SystemExit("narrative binding check failed: normalized scene drift for identical input")
    if first.get("svg_markup") != second.get("svg_markup"):
        raise SystemExit("narrative binding check failed: SVG drift for identical scene")
    assert_text_stability(first)
    return first


def assert_presentation_only_variants(
    chromium: str,
    port: int,
    *,
    chapter: str,
    step: str,
    mode: str,
    frame: str,
) -> None:
    narrow = load_snapshot(
        chromium,
        port,
        chapter=chapter,
        step=step,
        mode=mode,
        frame=frame,
        attention="narrow",
        depth="less",
    )
    expand = load_snapshot(
        chromium,
        port,
        chapter=chapter,
        step=step,
        mode=mode,
        frame=frame,
        attention="expand",
        depth="less",
    )
    more = load_snapshot(
        chromium,
        port,
        chapter=chapter,
        step=step,
        mode=mode,
        frame=frame,
        attention="narrow",
        depth="more",
    )

    assert_identical_identity(narrow, expand)
    assert_identical_identity(narrow, more)

    if narrow.get("svg_markup") == expand.get("svg_markup"):
        raise SystemExit("narrative binding check failed: attention change did not affect SVG presentation")
    if narrow.get("svg_markup") == more.get("svg_markup"):
        raise SystemExit("narrative binding check failed: depth change did not affect SVG presentation")


def main() -> int:
    assert_reproducible_binding()
    assert_page_controls()

    chromium = find_chromium()
    port = find_port()
    server = run_server(port)

    try:
        wait_for_server(f"http://127.0.0.1:{port}/ttc_narrative_witness.html")

        scenarios = [
            {
                "chapter": "ch_0185dd34c89e",
                "step": "1",
                "mode": "narrative",
                "frame": "semantic_graph",
            },
            {
                "chapter": "ch_c429d3abd60e",
                "step": "21",
                "mode": "narrative",
                "frame": "world",
            },
            {
                "chapter": "ch_dcdf6301992e",
                "step": "17",
                "mode": "witness",
                "frame": "replay_timeline",
            },
        ]

        snapshots = [assert_svg_determinism(chromium, port, **scenario) for scenario in scenarios]
        assert_presentation_only_variants(
            chromium,
            port,
            chapter="ch_dcdf6301992e",
            step="17",
            mode="witness",
            frame="replay_timeline",
        )

        summary = [
            {
                "chapter_id": snapshot["chapter_id"],
                "step": snapshot["step"],
                "scene_id": snapshot["scene_id"],
                "template_id": snapshot["template_id"],
            }
            for snapshot in snapshots
        ]
        print("narrative binding check passed")
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
