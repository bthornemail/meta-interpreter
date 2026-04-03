#!/usr/bin/env python3
"""
Projection render smoke check.

This validates projection equivalence only.
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


ROOT = Path(__file__).resolve().parents[1]
DEMO_SERVER = ROOT / "demo" / "ttc_runtime_stream_server.py"
FRAMEWORK_BIN = ROOT / "bin" / "ttc_framework"
SNAPSHOT_RE = re.compile(
    r'<script[^>]*id=["\']ttc-projection-snapshot["\'][^>]*>(.*?)</script>',
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
    raise SystemExit("projection check failed: chromium not found")


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
    raise SystemExit(f"projection check failed: server did not start ({last_error})")


def dump_dom(chromium: str, url: str) -> str:
    cmd = [
        chromium,
        "--headless=new",
        "--disable-gpu",
        "--no-sandbox",
        "--run-all-compositor-stages-before-draw",
        "--virtual-time-budget=6000",
        "--dump-dom",
        url,
    ]
    result = subprocess.run(
        cmd,
        check=True,
        text=True,
        cwd=str(ROOT),
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    return result.stdout


def extract_snapshot(dom: str) -> dict[str, str]:
    match = SNAPSHOT_RE.search(dom)
    if not match:
        raise SystemExit("projection check failed: snapshot element missing from DOM")
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


def main() -> int:
    if not FRAMEWORK_BIN.exists():
        raise SystemExit("projection check failed: bin/ttc_framework missing; run make build first")

    chromium = find_chromium()
    port = find_port()
    server = run_server(port)

    try:
        wait_for_server(f"http://127.0.0.1:{port}/ttc_projection_demo.html")

        urls = {
            "static": f"http://127.0.0.1:{port}/ttc_projection_demo.html?projection_check=1",
            "stream": (
                f"http://127.0.0.1:{port}/ttc_projection_stream.html"
                "?projection_check=1&autoload=1&source=ttc_runtime_sample.ndjson&index=0"
            ),
            "live": (
                f"http://127.0.0.1:{port}/ttc_projection_live.html"
                "?projection_check=1&autoconnect=1&input=A&rule=current&stop_after=1"
            ),
        }

        snapshots = {name: extract_snapshot(dump_dom(chromium, url)) for name, url in urls.items()}
        baseline = snapshots["static"]

        required = ["step", "digest", "triplet", "order", "seq56", "layer", "coords", "coeff", "canvas_data_url"]
        for key in required:
            if key not in baseline:
                raise SystemExit(f"projection check failed: baseline missing key {key}")

        for name, snapshot in snapshots.items():
            for key in required:
                if snapshot.get(key) != baseline.get(key):
                    raise SystemExit(
                        "projection check failed: "
                        f"{name} diverged on {key}: {snapshot.get(key)!r} != {baseline.get(key)!r}"
                    )

        summary = {
            "step": baseline["step"],
            "digest": baseline["digest"],
            "triplet": baseline["triplet"],
            "order": baseline["order"],
            "seq56": baseline["seq56"],
            "layer": baseline["layer"],
            "coords": baseline["coords"],
            "coeff": baseline["coeff"],
        }
        print("projection render check passed")
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
