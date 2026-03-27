#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUT_DIR="artifacts/xX/p0/0/0"
mkdir -p "$OUT_DIR"

MNEMONIC_DEFAULT="abandon ability able about above absent absorb abstract absurd abuse access accident"
MNEMONIC="${1:-$MNEMONIC_DEFAULT}"

SAMPLE_TXT="$OUT_DIR/mnemonic_sample.txt"
SAMPLE_BIN="$OUT_DIR/mnemonic_sample.bin"
BOARD_OUT="$OUT_DIR/mnemonic_board.txt"
BRAILLE_OUT="$OUT_DIR/mnemonic_braille.txt"
JSON_OUT="$OUT_DIR/mnemonic_braille.json"

printf '%s\n' "$MNEMONIC" > "$SAMPLE_TXT"
printf '%s\n' "$MNEMONIC" > "$SAMPLE_BIN"

./bin/ttc_canonical_runtime encode --blocks blocks < "$SAMPLE_BIN" > "$BOARD_OUT"

# Build a human-readable braille trace with glyphs.
gawk '
function hexcp_to_char(cphex,  cp) {
  cp = strtonum("0x" cphex)
  return sprintf("%c", cp)
}
function get_field(line, key,   m, pat) {
  pat = key "=([^ ]+)"
  if (match(line, pat, m)) return m[1]
  return ""
}
BEGIN {
  print "# TTC Braille Mnemonic Sample"
  print "# mnemonic=" ENVIRON["MNEMONIC"]
  print "# columns: tick input_hex state_hex braille_cp braille_glyph"
}
{
  tick = get_field($0, "tick")
  inhex = get_field($0, "input")
  sthex = get_field($0, "state")
  bcp = get_field($0, "braille")
  sub(/^U\+/, "", bcp)
  glyph = hexcp_to_char(bcp)
  printf "%s %s %s U+%s %s\n", tick, inhex, sthex, bcp, glyph
}
' "$BOARD_OUT" > "$BRAILLE_OUT"

# JSON variant.
gawk '
function get_field(line, key,   m, pat) {
  pat = key "=([^ ]+)"
  if (match(line, pat, m)) return m[1]
  return ""
}
BEGIN { print "["; first = 1 }
{
  tick = get_field($0, "tick")
  inhex = get_field($0, "input")
  sthex = get_field($0, "state")
  bcp = get_field($0, "braille")
  if (!first) print ","
  printf "  {\"tick\":%s,\"input\":\"%s\",\"state\":\"%s\",\"braille\":\"%s\"}", tick, inhex, sthex, bcp
  first = 0
}
END { print "\n]" }
' "$BOARD_OUT" > "$JSON_OUT"

./scripts/materialize_factoradic_5040.sh --binary --out-root artifacts < "$SAMPLE_BIN"

echo "braille mnemonic sample written"
echo "  mnemonic: $SAMPLE_TXT"
echo "  board:    $BOARD_OUT"
echo "  braille:  $BRAILLE_OUT"
echo "  json:     $JSON_OUT"
