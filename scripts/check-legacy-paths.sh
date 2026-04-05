#!/bin/sh
set -eu

# Three-tier classification:
# 1. forbidden - real repo references that need migration
# 2. symbolic - embedded references (witness-layer, allowed)
# 3. ignored - third-party substrate code

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Checking canonical path alignment..."

# Find raw matches
raw_matches="$(grep -RInE '\b(src/|blocks/|demo/|deploy/|packages/)\b' \
  README.md AGENTS.md Makefile scripts runtime docs org dev-docs.org system-image surfaces 2>/dev/null | \
  grep -v 'system-image/deploy' | \
  grep -v 'runtime/blocks' | \
  grep -v 'runtime/kernel' | \
  grep -v '\.ndjson:' | \
  grep -v '\.js:' | \
  grep -v '.git' || true)"

# Filter to forbidden (real repo paths, not symbolic references)
forbidden="$(echo "$raw_matches" | grep -vE 'aligned_runtime:|research/archive:|substrate/' || true)"

if [ -n "$forbidden" ]; then
  echo "FAIL: forbidden legacy paths found:"
  echo "$forbidden"
  exit 1
fi

# Report what was found (informational only)
symbolic_matches="$(echo "$raw_matches" | grep -E 'aligned_runtime:|research/archive/' || true)"
substrate_matches="$(echo "$raw_matches" | grep -E 'substrate/' || true)"

if [ -n "$symbolic_matches" ]; then
  symbolic_count=$(echo "$symbolic_matches" | wc -l)
  echo "INFO: $symbolic_count symbolic references preserved (witness-layer)"
fi

if [ -n "$substrate_matches" ]; then
  substrate_count=$(echo "$substrate_matches" | wc -l)
  echo "INFO: $substrate_count substrate references ignored (third-party)"
fi

echo "ok no forbidden legacy paths"
