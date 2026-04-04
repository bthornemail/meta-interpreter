#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

doc="docs/SURFACES.md"

if [[ ! -f "$doc" ]]; then
  echo "missing $doc" >&2
  exit 1
fi

required_patterns=(
  "Surfaces expose derived structure"
  "Surfaces do not define canonical state"
  "No surface defines canonical state except bytes"
  "No surface may influence runtime"
  "No projection defines structure"
  "No transport defines semantics"
  "No matrix defines identity"
  "No artifact defines structure"
  "Projection must not influence check ordering"
  "Transport must not influence check ordering"
  "Artifact hash must not influence check ordering"
  "event stream"
  "step_digest"
  "TTC matrix"
  "JSON Canvas"
  "Aztec refers only to standards-compliant barcode framing"
  "artifact = identity plus payload"
  "Surfaces expose derived representations of the system; they do not define its canonical state"
  "Check ordering is determined only by tick and authoritative step_digest, never by projection, transport, or artifact identity"
)

for pattern in "${required_patterns[@]}"; do
  if ! grep -Fq "$pattern" "$doc"; then
    echo "surfaces validation failed: missing pattern: $pattern" >&2
    exit 1
  fi
done

if ! python3 - <<'PY'
import json
from pathlib import Path

path = Path("docs/SURFACES.json")
if not path.exists():
    raise SystemExit("surfaces validation failed: docs/SURFACES.json missing")

data = json.loads(path.read_text(encoding="utf-8"))
order = data.get("surface_order")
if not isinstance(order, list) or not order:
    raise SystemExit("surfaces validation failed: missing surface_order")

surfaces = data.get("surfaces")
if not isinstance(surfaces, dict) or not surfaces:
    raise SystemExit("surfaces validation failed: missing surfaces map")

required = {
    "bytes": ("substrate", True, True),
    "event stream": ("runtime", True, True),
    "step_digest": ("incidence", False, False),
    "matrix": ("matrix", False, False),
    "JSON Canvas": ("projection", False, False),
    "FIFO": ("transport", False, False),
    "Aztec": ("barcode", False, False),
    "artifact": ("artifact", False, True),
}

for name, (category, canonical, authoritative) in required.items():
    entry = surfaces.get(name)
    if not isinstance(entry, dict):
        raise SystemExit(f"surfaces validation failed: missing surface {name!r}")
    if entry.get("category") != category:
        raise SystemExit(f"surfaces validation failed: {name!r} must map to {category!r}")
    if entry.get("canonical") != canonical:
        raise SystemExit(f"surfaces validation failed: {name!r} canonical mismatch")
    if entry.get("authoritative") != authoritative:
        raise SystemExit(f"surfaces validation failed: {name!r} authoritative mismatch")

for relation in (
    "projection -> runtime",
    "runtime -> projection",
    "transport -> semantics",
    "matrix -> identity",
    "artifact -> structure",
    "Aztec -> structure",
    "step_digest -> grammar",
    "step_digest -> identity",
):
    if relation not in data.get("forbidden_relations", []):
        raise SystemExit(f"surfaces validation failed: missing forbidden relation {relation!r}")

for claim in (
    "PGM is canonical",
    "JSON Canvas defines structure",
    "matrix is identity",
    "step_digest is artifact hash",
):
    if claim not in data.get("forbidden_surface_claims", []):
        raise SystemExit(f"surfaces validation failed: missing forbidden surface claim {claim!r}")
PY
then
  exit 1
fi

echo "surfaces validation passed"
