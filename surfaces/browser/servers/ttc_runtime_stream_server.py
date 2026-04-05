#!/usr/bin/env python3
"""
TTC runtime SSE bridge.

This bridge forwards runtime NDJSON unchanged.
It is a transport adapter, not a schema or projection authority.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import urllib.parse
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
DEMO_DIR = ROOT / "demo"
FRAMEWORK_BIN = ROOT / "bin" / "ttc_framework"


def content_type_for(path: Path) -> str:
    if path.suffix == ".html":
        return "text/html; charset=utf-8"
    if path.suffix == ".js":
        return "application/javascript; charset=utf-8"
    if path.suffix == ".json":
        return "application/json; charset=utf-8"
    if path.suffix == ".ndjson":
        return "application/x-ndjson; charset=utf-8"
    return "text/plain; charset=utf-8"


class TTCBridgeHandler(BaseHTTPRequestHandler):
    server_version = "TTCBridge/1.0"

    def do_GET(self) -> None:  # noqa: N802
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/events":
            self.handle_events(parsed)
            return
        self.handle_static(parsed.path)

    def log_message(self, fmt: str, *args) -> None:  # noqa: A003
        sys.stderr.write("%s - - [%s] %s\n" % (self.address_string(), self.log_date_time_string(), fmt % args))

    def handle_static(self, path: str) -> None:
        if path in ("", "/"):
            path = "/browser/index.html"
        rel = path.lstrip("/")
        target = (DEMO_DIR / rel).resolve()
        if DEMO_DIR not in target.parents and target != DEMO_DIR:
            self.send_error(HTTPStatus.FORBIDDEN, "forbidden")
            return
        if not target.exists() or not target.is_file():
            self.send_error(HTTPStatus.NOT_FOUND, "not found")
            return

        data = target.read_bytes()
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", content_type_for(target))
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def handle_events(self, parsed: urllib.parse.ParseResult) -> None:
        params = urllib.parse.parse_qs(parsed.query)
        input_text = params.get("input", ["ABC"])[0]
        rule = params.get("rule", ["current"])[0]
        seed = params.get("seed", [None])[0]

        if not FRAMEWORK_BIN.exists():
            self.send_error(HTTPStatus.SERVICE_UNAVAILABLE, "bin/ttc_framework missing; run make build first")
            return

        cmd = [str(FRAMEWORK_BIN), "runtime"]
        if rule in ("current", "delta64"):
            cmd.extend(["--rule", rule])
        if seed:
            cmd.extend(["--seed", seed])

        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "keep-alive")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

        proc = subprocess.Popen(
            cmd,
            cwd=str(ROOT),
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            bufsize=1,
        )

        try:
            assert proc.stdin is not None
            proc.stdin.write(input_text)
            proc.stdin.close()

            assert proc.stdout is not None
            for line in proc.stdout:
                line = line.strip()
                if not line:
                    continue
                self.wfile.write(b"event: step\n")
                self.wfile.write(f"data: {line}\n\n".encode("utf-8"))
                self.wfile.flush()
        except BrokenPipeError:
            pass
        finally:
            proc.wait(timeout=5)
            stderr_text = ""
            if proc.stderr is not None:
                stderr_text = proc.stderr.read().strip()
            payload = {
                "kind": "ttc.stream.end",
                "exit_code": proc.returncode,
                "stderr": stderr_text,
            }
            try:
                self.wfile.write(b"event: end\n")
                self.wfile.write(f"data: {json.dumps(payload)}\n\n".encode("utf-8"))
                self.wfile.flush()
            except BrokenPipeError:
                pass


def main() -> int:
    parser = argparse.ArgumentParser(description="Serve TTC runtime NDJSON over SSE.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), TTCBridgeHandler)
    print(f"TTC runtime stream server listening on http://{args.host}:{args.port}/browser/index.html")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
