#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/hexglyph.sh <file>

Description:
  Hexdump-style view with UTF-8 glyph column (not ASCII-dot preview).
  Left columns remain offset + 16 hex bytes (8|8 grouping).
EOF
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

file="$1"
if [[ ! -f "$file" ]]; then
  echo "file not found: $file" >&2
  exit 1
fi

offset=0
while IFS= read -r line; do
  [[ -z "${line// }" ]] && continue

  # shellcheck disable=SC2086
  set -- $line
  count=$#

  # Build fixed-width hex columns.
  hexcol=""
  idx=1
  for ((i=1; i<=16; i++)); do
    if (( idx <= count )); then
      b="${!idx}"
      hexcol+="$b "
      idx=$((idx + 1))
    else
      hexcol+="   "
    fi
    if (( i == 8 )); then
      hexcol+=" "
    fi
  done

  # UTF-8 glyph preview.
  # Keep hexdump-like layout, but decode UTF-8 glyphs instead of ASCII dots.
  # Invalid UTF-8 fragments at line boundaries are dropped deterministically.
  raw=""
  for b in "$@"; do
    v=$((16#$b))
    if (( v < 32 || v == 127 )); then
      raw+="."
    else
      raw+="$(printf "\\x$b")"
    fi
  done
  glyph="$(printf '%b' "$raw" | iconv -f UTF-8 -t UTF-8 -c 2>/dev/null || true)"

  printf '%08x  %s |%s|\n' "$offset" "$hexcol" "$glyph"
  offset=$((offset + count))
done < <(od -An -tx1 -v -w16 "$file")
