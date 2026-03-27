#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RULES_DIR="research/rules"
RULES_MERGED=""
FACTS_FILE="research/rules/facts.ndjson"
QUERIES_FILE="research/rules/queries.ndjson"
POLICY_FILE="research/rules/policy.ndjson"
ALLOW_INFERRED_OVERRIDE=""

usage() {
  cat <<'EOF'
Usage: scripts/rule_runtime.sh [options]
  --rules-dir PATH       Directory with *.rules.ndjson (default: research/rules)
  --facts FILE           Facts NDJSON file (default: research/rules/facts.ndjson)
  --queries FILE         Queries NDJSON file (default: research/rules/queries.ndjson)
  --policy FILE          Policy NDJSON singleton (default: research/rules/policy.ndjson)
  --allow-inferred       Override policy to allow inferred rules for this run
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rules-dir) RULES_DIR="$2"; shift 2 ;;
    --facts) FACTS_FILE="$2"; shift 2 ;;
    --queries) QUERIES_FILE="$2"; shift 2 ;;
    --policy) POLICY_FILE="$2"; shift 2 ;;
    --allow-inferred) ALLOW_INFERRED_OVERRIDE="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

for f in "$FACTS_FILE" "$QUERIES_FILE" "$POLICY_FILE"; do
  [[ -f "$f" ]] || { echo "missing required file: $f" >&2; exit 2; }
done

RULES_MERGED="$(mktemp)"
for f in $(ls "$RULES_DIR"/*.rules.ndjson | sort); do
  cat "$f" >> "$RULES_MERGED"
done

RUNTIME_POLICY="$POLICY_FILE"
if [[ -n "$ALLOW_INFERRED_OVERRIDE" ]]; then
  RUNTIME_POLICY="$(mktemp)"
  gawk '{
    line=$0
    gsub(/"allow_inferred"[[:space:]]*:[[:space:]]*false/, "\"allow_inferred\":true", line)
    gsub(/"allow_status"[[:space:]]*:[[:space:]]*\[[^]]+\]/, "\"allow_status\":[\"implemented\",\"target_state\",\"research_open_inferred\"]", line)
    print line
  }' "$POLICY_FILE" > "$RUNTIME_POLICY"
fi

gawk \
  -v rules_file="$RULES_MERGED" \
  -v facts_file="$FACTS_FILE" \
  -v queries_file="$QUERIES_FILE" \
  -v policy_file="$RUNTIME_POLICY" \
  -f scripts/rule_runtime.awk

rm -f "$RULES_MERGED"
if [[ "$RUNTIME_POLICY" != "$POLICY_FILE" ]]; then
  rm -f "$RUNTIME_POLICY"
fi
