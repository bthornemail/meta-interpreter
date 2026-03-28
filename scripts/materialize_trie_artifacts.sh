#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

. "$ROOT_DIR/scripts/leaf_contract.sh"

BOARD_FILE=""
OUT_ROOT="artifacts"
CLEAR_TARGETS="false"

usage() {
  cat <<'EOF'
Usage: scripts/materialize_trie_artifacts.sh [--board-file FILE] [--out-root DIR] [--clear-targets]

Reads canonical runtime board lines and writes trie artifacts under:
  artifacts/{xx|xX|Xx|XX}/{p0|p1|p2}/{lane}/{leaf}/
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --board-file) BOARD_FILE="$2"; shift 2 ;;
    --out-root) OUT_ROOT="$2"; shift 2 ;;
    --clear-targets) CLEAR_TARGETS="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

TMP_TSV="$(mktemp)"
TMP_DIRS="$(mktemp)"

if [[ -n "$BOARD_FILE" ]]; then
  IN_SRC="$BOARD_FILE"
else
  IN_SRC="/dev/stdin"
fi

gawk -v out_root="$OUT_ROOT" '
function get_kv(line, k,   m, pat) {
  pat = k "=([^ ]+)"
  if (match(line, pat, m)) return m[1]
  return ""
}
function bits(n, w,   i, b, s) {
  s = ""
  for (i = w - 1; i >= 0; i--) {
    b = and(rshift(n, i), 1)
    s = s b
  }
  return s
}
BEGIN {
  cls[0] = "xx"; cls[1] = "xX"; cls[2] = "Xx"; cls[3] = "XX"
  prev = out_root "/xx/p0/0/0"
}
{
  line = $0
  tick_s = get_kv(line, "tick")
  in_s = get_kv(line, "input")
  state_s = get_kv(line, "state")
  winner_s = get_kv(line, "winner")
  board = get_kv(line, "board")

  if (tick_s == "" || in_s == "" || state_s == "" || winner_s == "" || board == "") next

  tick = tick_s + 0
  gsub(/^0x/, "", in_s); input = strtonum("0x" in_s)
  gsub(/^0x/, "", state_s); state = strtonum("0x" state_s)
  winner = winner_s + 0

  c0 = and(rshift(input, 5), 1)
  c1 = and(tick, 1)
  cls_idx = or(lshift(c1, 1), c0)

  class = cls[cls_idx]
  point_idx = winner % 3
  point = sprintf("p%d", point_idx)
  lane = and(or(lshift(winner, 2), rshift(input, 4)), 15)
  leaf = and(input, 15)

  lane_hex = sprintf("%x", lane)
  leaf_hex = sprintf("%x", leaf)

  class_bits = bits(cls_idx, 2)
  point_bits = bits(point_idx, 2)
  lane_bits = bits(lane, 4)
  leaf_bits = bits(leaf, 4)
  addr_bits = class_bits " " point_bits " " lane_bits " " leaf_bits

  dir = out_root "/" class "/" point "/" lane_hex "/" leaf_hex
  print dir "\t" class "\t" cls_idx "\t" point "\t" point_idx "\t" lane_hex "\t" lane "\t" leaf_hex "\t" leaf "\t" addr_bits "\t" prev "\t" tick "\t" input "\t" state "\t" board "\t" line
  prev = dir
}
' "$IN_SRC" > "$TMP_TSV"

cut -f1 "$TMP_TSV" | sort -u > "$TMP_DIRS"

if [[ "$CLEAR_TARGETS" == "true" ]]; then
  while IFS= read -r d; do
    rm -f "$d/trace.log" "$d/state.bin" "$d/board.txt" "$d/aztec.txt" "$d/meta.json" \
      "$d/.canon" "$d/.block" "$d/.artifact" "$d/.bitboard" "$d/.golden" "$d/.negative"
  done < "$TMP_DIRS"
fi

while IFS=$'\t' read -r dir class class_idx point point_idx lane_hex lane_val leaf_hex leaf_val addr_bits parent tick input state board line; do
  mkdir -p "$dir"

  ttc_write_leaf_contract "$dir" "ttc.artifact.addr.v1" "$class" "$point" "$lane_hex" "$leaf_hex" "$addr_bits" "$tick" "$input" "$state" "$parent" "scripts/materialize_trie_artifacts.sh" "$board"

done < "$TMP_TSV"

rm -f "$TMP_TSV" "$TMP_DIRS"

echo "materialized trie artifacts under $OUT_ROOT"
