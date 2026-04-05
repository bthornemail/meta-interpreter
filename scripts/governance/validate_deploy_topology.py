#!/usr/bin/env python3
"""Validate deployment Fano topology against current deploy assets.

This check is non-authoritative. It ensures the downstream deployment witness
stays aligned with the current nginx/systemd asset split.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TOPOLOGY = ROOT / "deploy" / "fano_service_topology.json"
MEDIUM_NGINX = ROOT / "deploy" / "nginx" / "medium" / "universal-life-protocol.com.conf"
SMALL_NGINX = ROOT / "deploy" / "nginx" / "small" / "artifact.small.universal-life-protocol.com.conf"
LARGE_SYSTEMD = ROOT / "deploy" / "systemd" / "ttc-runtime-sse.service"
DOC = ROOT / "docs" / "DEPLOYMENT_FANO_TOPOLOGY.md"

EXPECTED_POINTS = {
    "public_site",
    "browser_projection",
    "browser_narrative",
    "runtime_sse",
    "api_service",
    "downloads",
    "admin_mcp",
}


def fail(message: str) -> int:
    print(f"deploy topology validation failed: {message}", file=sys.stderr)
    return 1


def load_topology() -> dict[str, object]:
    return json.loads(TOPOLOGY.read_text(encoding="utf-8"))


def pair_key(a: str, b: str) -> tuple[str, str]:
    return tuple(sorted((a, b)))


def main() -> int:
    if not TOPOLOGY.exists():
        return fail("missing system-image/deploy/fano_service_topology.json")
    if not DOC.exists():
        return fail("missing docs/DEPLOYMENT_FANO_TOPOLOGY.md")

    topology = load_topology()
    points = topology.get("points")
    if not isinstance(points, list):
        return fail("points is not a list")
    if set(points) != EXPECTED_POINTS:
        return fail("points do not match the frozen 7-point deployment set")
    if len(points) != len(EXPECTED_POINTS):
        return fail("points contain duplicates")

    hosts = topology.get("hosts")
    if not isinstance(hosts, dict):
        return fail("hosts is not a mapping")
    if set(hosts.keys()) != {"medium", "large", "small"}:
        return fail("hosts do not match medium/large/small")

    seen: dict[str, str] = {}
    for host, assigned in hosts.items():
        if not isinstance(assigned, list):
            return fail(f"host assignment for {host} is not a list")
        for point in assigned:
            if point not in EXPECTED_POINTS:
                return fail(f"undeclared point in host assignment: {point}")
            if point in seen:
                return fail(f"point {point} assigned to multiple hosts")
            seen[point] = host
    if set(seen.keys()) != EXPECTED_POINTS:
        return fail("not all points are assigned exactly once")

    lines = topology.get("lines")
    if not isinstance(lines, list) or len(lines) != 7:
        return fail("lines must contain exactly 7 triplets")
    for triplet in lines:
        if not isinstance(triplet, list) or len(triplet) != 3:
            return fail("each Fano line must be a triplet")
        if len(set(triplet)) != 3:
            return fail("Fano line contains duplicate points")
        for point in triplet:
            if point not in EXPECTED_POINTS:
                return fail(f"undeclared point in Fano line: {point}")

    allowed_pairs = topology.get("allowed_pairs")
    if not isinstance(allowed_pairs, list):
        return fail("allowed_pairs is not a list")
    allowed_pair_set = set()
    for pair in allowed_pairs:
        if not isinstance(pair, list) or len(pair) != 2:
            return fail("each allowed pair must contain exactly two points")
        a, b = pair
        if a not in EXPECTED_POINTS or b not in EXPECTED_POINTS:
            return fail(f"undeclared point in allowed pair: {pair}")
        allowed_pair_set.add(pair_key(a, b))

    if pair_key("public_site", "browser_projection") not in allowed_pair_set:
        return fail("public_site/browser_projection adjacency missing")
    if pair_key("public_site", "browser_narrative") not in allowed_pair_set:
        return fail("public_site/browser_narrative adjacency missing")
    if pair_key("browser_projection", "runtime_sse") not in allowed_pair_set:
        return fail("browser_projection/runtime_sse adjacency missing")
    if pair_key("browser_narrative", "runtime_sse") not in allowed_pair_set:
        return fail("browser_narrative/runtime_sse adjacency missing")
    if pair_key("downloads", "runtime_sse") not in allowed_pair_set:
        return fail("downloads/runtime_sse adjacency missing from frozen topology")

    proxy_paths = topology.get("intended_proxy_paths")
    if proxy_paths != {"/events": "runtime_sse", "/api/": "api_service"}:
        return fail("intended proxy path map drifted")

    medium_conf = MEDIUM_NGINX.read_text(encoding="utf-8")
    small_conf = SMALL_NGINX.read_text(encoding="utf-8")
    large_service = LARGE_SYSTEMD.read_text(encoding="utf-8")

    if "/browser/" not in medium_conf:
        return fail("medium nginx does not serve /browser/")
    if "location /events" not in medium_conf:
        return fail("medium nginx does not proxy /events")
    if "proxy_pass http://ttc_runtime_sse;" not in medium_conf:
        return fail("medium nginx /events is not wired to runtime_sse")
    if "matroid-garden.com" in medium_conf:
        return fail("medium nginx incorrectly references downloads host")
    if "server 74.208.190.29:8000;" not in medium_conf:
        return fail("medium nginx does not point runtime_sse at large")

    if "proxy_pass" in small_conf:
        return fail("small nginx must not proxy runtime or API traffic")
    if "location /events" in small_conf:
        return fail("small nginx must not expose /events")
    if "matroid-garden.com" not in small_conf:
        return fail("small nginx does not materialize downloads host")

    if "--port 8000" not in large_service:
        return fail("large systemd unit is not bound to runtime_sse port 8000")
    if "ttc_runtime_stream_server.py" not in large_service:
        return fail("large systemd unit is not serving the SSE bridge")
    if "medium host" not in large_service:
        return fail("large systemd notes lost medium/large separation comment")

    doc_text = DOC.read_text(encoding="utf-8")
    for token in ("public_site", "browser_projection", "browser_narrative", "runtime_sse", "api_service", "downloads", "admin_mcp"):
        if token not in doc_text:
            return fail(f"deployment topology doc missing point {token}")

    print("deploy topology validation passed")
    print(
        json.dumps(
            {
                "points": points,
                "hosts": hosts,
                "medium_serves_browser": True,
                "large_serves_runtime_sse": True,
                "small_serves_downloads": True,
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
