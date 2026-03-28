#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

. "$ROOT_DIR/scripts/leaf_contract.sh"

OUT_ROOT="artifacts"
BINARY_MODE="false"

usage() {
  cat <<'EOF'
Usage:
  # numeric bytes
  echo "120 88 95" | scripts/materialize_factoradic_5040.sh

  # raw binary bytes
  cat payload.bin | scripts/materialize_factoradic_5040.sh --binary
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --binary) BINARY_MODE="true"; shift ;;
    --out-root) OUT_ROOT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

TMP="$(mktemp)"
if [[ "$BINARY_MODE" == "true" ]]; then
  od -An -v -t u1 | tr -s '[:space:]' ' ' | sed 's/^ //' | gawk -f scripts/artifact_path.awk > "$TMP"
else
  cat | gawk -f scripts/artifact_path.awk > "$TMP"
fi

to_bin_padded() {
  local n="$1"
  local width="$2"
  local out=""
  local i
  for ((i = 0; i < width; i++)); do
    out="$((n & 1))$out"
    n=$((n >> 1))
  done
  printf '%s' "$out"
}

class_to_bits() {
  case "$1" in
    xx) printf '0' ;;
    xX) printf '1' ;;
    Xx) printf '2' ;;
    XX) printf '3' ;;
    *)  printf '0' ;;
  esac
}

prev="$OUT_ROOT/xx/p0/00/0000"
while IFS=$'\t' read -r tick byte class point winner lane lane_hex leaf leaf_hex lane_divisor path; do
  path_root="${path#artifacts/}"
  dir="$OUT_ROOT/$path_root"
  mkdir -p "$dir"

  class_bits_dec="$(class_to_bits "$class")"
  point_idx="${point#p}"
  class_bits_bin="$(to_bin_padded "$class_bits_dec" 2)"
  point_bits_bin="$(to_bin_padded "$point_idx" 2)"
  lane_bits_bin="$(to_bin_padded "$lane" 6)"
  leaf_bits_bin="$(to_bin_padded "$leaf" 13)"

  ttc_write_leaf_contract "$dir" "ttc.artifact.addr.v1" "$class" "$point" "$lane_hex" "$leaf_hex" \
    "$class_bits_bin $point_bits_bin $lane_bits_bin $leaf_bits_bin" "$tick" "$byte" "$byte" "$prev" "scripts/materialize_factoradic_5040.sh"

  prev="$dir"
done < "$TMP"

rm -f "$TMP"
echo "materialized factoradic-5040 trie under $OUT_ROOT"
