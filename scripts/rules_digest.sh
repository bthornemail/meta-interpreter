#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUT_DIR="research/rules"

{
  for f in $(ls "$OUT_DIR"/*.rules.ndjson | sort); do
    sha256sum "$f"
  done
  sha256sum "$OUT_DIR/traceability.tsv"
  sha256sum "$OUT_DIR/policy.ndjson"
} > "$OUT_DIR/digests.sha256"

# Optional allowlist: inferred-rule digest pins (not active by default).
grep -h '"inferred":true' "$OUT_DIR"/*.rules.ndjson | sha256sum | awk '{print $1 "  inferred.rules.ndjson"}' > "$OUT_DIR/allowlist.sha256"

echo "wrote $OUT_DIR/digests.sha256 and $OUT_DIR/allowlist.sha256"
