#!/bin/sh
set -eu

# Entrypoint Inventory Generator
# Part of Big Pickle audit system

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== Entrypoint Inventory ==="
echo ""

echo "## C CLI Entrypoints"
echo ""
for f in runtime/kernel/ttc_*.c; do
  if grep -q "^int main(" "$f" 2>/dev/null; then
    name="$(basename "$f" .c)"
    layer="$(grep -E 'LAYER:' "$f" | head -1 || echo 'entrypoint')"
    echo "- $name: $layer"
  fi
done

echo ""
echo "## AWK Entrypoints"
echo ""
for f in runtime/kernel/*.awk; do
  name="$(basename "$f")"
  fns="$(awk '/^function / {count++} END {print count}' "$f" 2>/dev/null || echo 0)"
  echo "- $name: $fns functions"
done

echo ""
echo "## Shell Scripts"
echo ""
ls scripts/*.sh 2>/dev/null | while read f; do
  name="$(basename "$f")"
  echo "- $name"
done

echo ""
echo "## Python Scripts"
echo ""
ls scripts/**/*.py 2>/dev/null | while read f; do
  name="$(basename "$f")"
  echo "- $name"
done

echo ""
echo "## Make Targets (runnable)"
echo ""
grep -E '^[a-zA-Z0-9_-]+:[^=]*$' Makefile | grep -v '^clean:' | while read target; do
  name="$(echo "$target" | cut -d: -f1)"
  echo "- $name"
done

echo ""
echo "=== Inventory Complete ==="