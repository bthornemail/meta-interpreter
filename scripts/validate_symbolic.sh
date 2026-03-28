#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# 1) Lossless core roundtrip (line -> symbolic -> decode), with VS on/off invariance
INPUT_SEQ="27 28 29 30 31 33 44 46 58 59 63 48 38 63 0 120 88 95 255 42"
printf '%s\n' "$INPUT_SEQ" | ./scripts/ttc_busybox.sh --no-write > "$TMP_DIR/core_in.txt"
./scripts/ttc_symbolic_encode --format line --vs-overlay on < "$TMP_DIR/core_in.txt" > "$TMP_DIR/symbolic_on.line"
./scripts/ttc_symbolic_encode --format line --vs-overlay off < "$TMP_DIR/core_in.txt" > "$TMP_DIR/symbolic_off.line"
./scripts/ttc_symbolic_decode --format line < "$TMP_DIR/symbolic_on.line" > "$TMP_DIR/core_out_on.txt"
./scripts/ttc_symbolic_decode --format line < "$TMP_DIR/symbolic_off.line" > "$TMP_DIR/core_out_off.txt"

gawk '
function kv(line, k,   m, pat) {
  pat = k "=([^ ]+)"
  if (match(line, pat, m)) return m[1]
  return ""
}
function qv(line, k,   m, pat) {
  pat = k "=\"([^\"]*)\""
  if (match(line, pat, m)) return m[1]
  return ""
}
{
  t = kv($0, "tick")
  i = kv($0, "input")
  s = kv($0, "state")
  w = kv($0, "winner")
  c = kv($0, "class")
  p = kv($0, "point")
  l = kv($0, "lane")
  f = kv($0, "leaf")
  a = qv($0, "address_bits")
  print t "\t" i "\t" s "\t" w "\t" c "\t" p "\t" l "\t" f "\t" a
}
' "$TMP_DIR/core_in.txt" > "$TMP_DIR/core_in.norm"

gawk '
function kv(line, k,   m, pat) {
  pat = k "=([^ ]+)"
  if (match(line, pat, m)) return m[1]
  return ""
}
function qv(line, k,   m, pat) {
  pat = k "=\"([^\"]*)\""
  if (match(line, pat, m)) return m[1]
  return ""
}
{
  t = kv($0, "tick")
  i = kv($0, "input")
  s = kv($0, "state")
  w = kv($0, "winner")
  c = kv($0, "class")
  p = kv($0, "point")
  l = kv($0, "lane")
  f = kv($0, "leaf")
  a = qv($0, "address_bits")
  print t "\t" i "\t" s "\t" w "\t" c "\t" p "\t" l "\t" f "\t" a
}
' "$TMP_DIR/core_out_on.txt" > "$TMP_DIR/core_out_on.norm"

gawk '
function kv(line, k,   m, pat) {
  pat = k "=([^ ]+)"
  if (match(line, pat, m)) return m[1]
  return ""
}
function qv(line, k,   m, pat) {
  pat = k "=\"([^\"]*)\""
  if (match(line, pat, m)) return m[1]
  return ""
}
{
  t = kv($0, "tick")
  i = kv($0, "input")
  s = kv($0, "state")
  w = kv($0, "winner")
  c = kv($0, "class")
  p = kv($0, "point")
  l = kv($0, "lane")
  f = kv($0, "leaf")
  a = qv($0, "address_bits")
  print t "\t" i "\t" s "\t" w "\t" c "\t" p "\t" l "\t" f "\t" a
}
' "$TMP_DIR/core_out_off.txt" > "$TMP_DIR/core_out_off.norm"

if ! diff -u "$TMP_DIR/core_in.norm" "$TMP_DIR/core_out_on.norm" >/dev/null; then
  echo "symbolic roundtrip mismatch" >&2
  diff -u "$TMP_DIR/core_in.norm" "$TMP_DIR/core_out_on.norm" || true
  exit 1
fi

if ! diff -u "$TMP_DIR/core_in.norm" "$TMP_DIR/core_out_off.norm" >/dev/null; then
  echo "symbolic roundtrip mismatch (vs off)" >&2
  diff -u "$TMP_DIR/core_in.norm" "$TMP_DIR/core_out_off.norm" || true
  exit 1
fi

if ! diff -u "$TMP_DIR/core_out_on.norm" "$TMP_DIR/core_out_off.norm" >/dev/null; then
  echo "VS overlay altered canonical reconstructed core tuples" >&2
  diff -u "$TMP_DIR/core_out_on.norm" "$TMP_DIR/core_out_off.norm" || true
  exit 1
fi

# 2) VS overlay correctness (known punctuation + non-mapped)
./scripts/ttc_symbolic_encode --format ndjson --vs-overlay on < "$TMP_DIR/core_in.txt" > "$TMP_DIR/vs_on.ndjson"
if ! rg -q '"input":33.*"vs_applied":true.*"vs_cp":"U\+FE0[01]"' "$TMP_DIR/vs_on.ndjson"; then
  echo "expected VS mapping for input=33 not found" >&2
  exit 1
fi
if ! rg -q '"input":48.*"vs_applied":true' "$TMP_DIR/vs_on.ndjson"; then
  echo "expected VS mapping for input=48 not found" >&2
  exit 1
fi
if ! rg -q '"input":120.*"vs_applied":false' "$TMP_DIR/vs_on.ndjson"; then
  echo "expected non-mapped VS false for input=120 not found" >&2
  exit 1
fi

# 3) SID/OID gating
printf '%s\n' "38 63" | ./scripts/ttc_busybox.sh --no-write | ./scripts/ttc_symbolic_encode --format ndjson > "$TMP_DIR/gate_pending.ndjson"
if ! rg -q '"control_role":"OID".*"oid_state":"oid_pending"' "$TMP_DIR/gate_pending.ndjson"; then
  echo "expected OID pending state not found" >&2
  exit 1
fi

printf '%s\n' "38 38 63" | ./scripts/ttc_busybox.sh --no-write | ./scripts/ttc_symbolic_encode --format ndjson > "$TMP_DIR/gate_ok.ndjson"
if ! rg -q '"control_role":"OID".*"oid_state":"consolidated"' "$TMP_DIR/gate_ok.ndjson"; then
  echo "expected OID consolidated state not found" >&2
  exit 1
fi

# 4) NULL reset clears SID consolidation window deterministically
printf '%s\n' "38 0 63" | ./scripts/ttc_busybox.sh --no-write | ./scripts/ttc_symbolic_encode --format ndjson > "$TMP_DIR/gate_null.ndjson"
if ! rg -q '"control_role":"OID".*"oid_state":"oid_pending"' "$TMP_DIR/gate_null.ndjson"; then
  echo "expected OID pending after NULL reset not found" >&2
  exit 1
fi

# 5) Epoch boundary reset (tick 5040) for SID window
cat > "$TMP_DIR/epoch_lines.txt" <<'EOL'
tick=5039 input=0x26 state=0x01 winner=0 class=xx point=p0 lane=0 leaf=6 address_bits="00 00 0000 0110"
tick=5040 input=0x26 state=0x01 winner=0 class=xx point=p0 lane=0 leaf=6 address_bits="00 00 0000 0110"
tick=5041 input=0x3F state=0x01 winner=0 class=xx point=p0 lane=0 leaf=15 address_bits="00 00 0000 1111"
EOL
./scripts/ttc_symbolic_encode --format ndjson < "$TMP_DIR/epoch_lines.txt" > "$TMP_DIR/epoch_out.ndjson"
if ! rg -q '"tick":5041.*"control_role":"OID".*"oid_state":"oid_pending"' "$TMP_DIR/epoch_out.ndjson"; then
  echo "expected epoch reset behavior not found" >&2
  exit 1
fi

# 6) Symbolic-derived identity alignment against URI tuples
./scripts/ttc_symbolic_encode --format ndjson --vs-overlay on < "$TMP_DIR/core_in.txt" > "$TMP_DIR/symbolic.ndjson"

gawk '
function jstr(line, key,   m, pat) { pat = "\"" key "\":\"([^\"]*)\""; if (match(line, pat, m)) return m[1]; return "" }
function jint(line, key,   m, pat) { pat = "\"" key "\":([0-9]+)"; if (match(line, pat, m)) return m[1] + 0; return -1 }
{
  t = jint($0, "tick")
  c = jstr($0, "class")
  p = jstr($0, "point")
  l = jint($0, "lane")
  f = jint($0, "leaf")
  if (t >= 0) {
    lhex = sprintf("%x", l)
    fhex = sprintf("%x", f)
    uri = "urn:ttc:artifact:" c ":" p ":" lhex ":" fhex ":t" t
    print t "\t" c "\t" p "\t" lhex "\t" fhex "\t" uri
  }
}
' "$TMP_DIR/symbolic.ndjson" | sort -n > "$TMP_DIR/symbolic.identity"

gawk '
function kv(line, k,   m, pat) { pat = k "=([^ ]+)"; if (match(line, pat, m)) return m[1]; return "" }
{
  t = kv($0, "tick") + 0
  c = kv($0, "class")
  p = kv($0, "point")
  l = kv($0, "lane") + 0
  f = kv($0, "leaf") + 0
  lhex = sprintf("%x", l)
  fhex = sprintf("%x", f)
  uri = "urn:ttc:artifact:" c ":" p ":" lhex ":" fhex ":t" t
  print t "\t" c "\t" p "\t" lhex "\t" fhex "\t" uri
}
' "$TMP_DIR/core_in.txt" | sort -n > "$TMP_DIR/core.identity"

if ! diff -u "$TMP_DIR/core.identity" "$TMP_DIR/symbolic.identity" >/dev/null; then
  echo "symbolic identity mismatch against runtime tuples" >&2
  diff -u "$TMP_DIR/core.identity" "$TMP_DIR/symbolic.identity" || true
  exit 1
fi

# 7) Overlay declaration dotfile at artifact leaves
printf '%s\n' "33 44 120" | ./scripts/ttc_busybox.sh --no-write > "$TMP_DIR/overlay_in.txt"
./scripts/ttc_symbolic_encode --format ndjson --vs-overlay on --write-overlay --out-root "$TMP_DIR/overlay_artifacts" < "$TMP_DIR/overlay_in.txt" >/dev/null
if ! find "$TMP_DIR/overlay_artifacts" -type f -name '.vs_overlay' | grep -q .; then
  echo "expected .vs_overlay declaration files not found" >&2
  exit 1
fi

# 8) Leaf contract dotfiles at materialized addressed nodes
printf '%s\n' "120 88 95" | TTC_BLOCKS_ROOT="$TMP_DIR/contract_blocks" ./scripts/ttc_busybox.sh --out-root "$TMP_DIR/contract_artifacts" >/dev/null
leaf_dir="$(find "$TMP_DIR/contract_artifacts" -type d -path '*/[0-9a-f]/[0-9a-f]' | head -n 1 || true)"
if [[ -z "$leaf_dir" ]]; then
  echo "expected materialized leaf directory not found" >&2
  exit 1
fi
for f in .canon .block .artifact .bitboard .golden .negative; do
  if [[ ! -s "$leaf_dir/$f" ]]; then
    echo "missing leaf contract file: $leaf_dir/$f" >&2
    exit 1
  fi
done

# 9) Blocks mirror leaf structure mirrors fixed six-file contract
block_leaf="${leaf_dir/contract_artifacts/contract_blocks}"
for f in .canon .block .artifact .bitboard .golden .negative; do
  if [[ ! -e "$block_leaf/$f" ]]; then
    echo "missing block mirror file: $block_leaf/$f" >&2
    exit 1
  fi
done

echo "symbolic validation passed"
