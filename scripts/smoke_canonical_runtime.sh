#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p artifacts

sample="$(mktemp)"
board="$(mktemp)"
json="$(mktemp)"
manifest1="$(mktemp)"
manifest2="$(mktemp)"
decoded="artifacts/xx/p0/0/0/decode_preview.txt"

printf 'TICK_A TICK_B REFLECT ROTATE TANGENT\n' > "$sample"

./bin/ttc_canonical_runtime encode --blocks blocks < "$sample" > "$board"
./bin/ttc_canonical_runtime encode --json --blocks blocks < "$sample" > "$json"
./scripts/materialize_trie_artifacts.sh --board-file "$board" --out-root artifacts --clear-targets

# Determinism smoke: same input produces byte-identical meta.json set.
find artifacts -type f -name meta.json -print | sort | while read -r f; do sha256sum "$f"; done > "$manifest1"
./bin/ttc_canonical_runtime encode --blocks blocks < "$sample" > "$board"
./scripts/materialize_trie_artifacts.sh --board-file "$board" --out-root artifacts --clear-targets
find artifacts -type f -name meta.json -print | sort | while read -r f; do sha256sum "$f"; done > "$manifest2"
cmp "$manifest1" "$manifest2"

mkdir -p "$(dirname "$decoded")"
./bin/ttc_canonical_runtime decode --blocks blocks < "$board" > "$decoded"

rm -f "$sample" "$board" "$json" "$manifest1" "$manifest2"

echo "canonical runtime smoke passed"
echo "  trie root: artifacts/{xx|xX|Xx|XX}/..."
echo "  decode preview: $decoded"
