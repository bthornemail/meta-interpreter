#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RULE_DIR="research/rules"
RULE_FILES=("$RULE_DIR"/*.rules.ndjson)

required='"kind" "rule_id" "domain" "inputs" "when" "then" "invariants" "status" "sources"'

# Schema + status + duplicate rule_id checks.
gawk '
BEGIN {
  split("implemented target_state research_open deprecated research_open_inferred", a, " ")
  for (i in a) valid[a[i]] = 1
}
{
  if ($0 == "") next
  file = FILENAME
  for (k in req) delete req[k]
  req["kind"]=1; req["rule_id"]=1; req["domain"]=1; req["inputs"]=1; req["when"]=1; req["then"]=1; req["invariants"]=1; req["status"]=1; req["sources"]=1
  for (k in req) if ($0 !~ "\"" k "\"[[:space:]]*:") { print "ERROR: missing key " k " in " file > "/dev/stderr"; exit 2 }

  if (match($0, /"rule_id"[[:space:]]*:[[:space:]]*"([^"]+)"/, m) == 0) { print "ERROR: invalid rule_id in " file > "/dev/stderr"; exit 2 }
  rid = m[1]
  if (rid_seen[rid]++) { print "ERROR: duplicate rule_id " rid > "/dev/stderr"; exit 2 }

  if (match($0, /"status"[[:space:]]*:[[:space:]]*"([^"]+)"/, s) == 0) { print "ERROR: invalid status in " file > "/dev/stderr"; exit 2 }
  if (!(s[1] in valid)) { print "ERROR: invalid status " s[1] " for " rid > "/dev/stderr"; exit 2 }

  if (s[1] == "implemented") {
    if ($0 !~ /src\// && $0 !~ /docs\/ttc_canonical_spec_v1.md/) {
      print "ERROR: implemented rule lacks runtime/canonical anchor: " rid > "/dev/stderr"
      exit 2
    }
  }
}
' "${RULE_FILES[@]}"

# Inferred set must be exact.
actual_inferred="$(grep -h '"inferred":true' "${RULE_FILES[@]}" | sed -E 's/.*"rule_id":"([^"]+)".*/\1/' | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
expected_inferred="A14 A28 A4 A5 A6 A7 A8 A9"
if [[ "$actual_inferred" != "$expected_inferred" ]]; then
  echo "ERROR: inferred rule set mismatch" >&2
  echo "  expected: $expected_inferred" >&2
  echo "  actual:   $actual_inferred" >&2
  exit 2
fi

# Explicit A* traceability coverage.
for id in A1 A2 A3 A10 A11.1 A11.2 A12 A13 A15 A16 A17 A18 A19 A20 A21.1 A21.2 A22 A23 A24 A25 A26 A27 A29 A30; do
  if ! awk -F '\t' -v id="$id" 'NR>1 && $2==id {found=1} END{exit(found?0:1)}' "$RULE_DIR/traceability.tsv"; then
    echo "ERROR: traceability missing explicit $id" >&2
    exit 2
  fi
done

# Determinism: regenerate twice and compare.
TMP1="$(mktemp)"
TMP2="$(mktemp)"
./scripts/extract_rules.sh >/dev/null
sha256sum "$RULE_DIR"/*.rules.ndjson "$RULE_DIR/traceability.tsv" "$RULE_DIR/digests.sha256" > "$TMP1"
./scripts/extract_rules.sh >/dev/null
sha256sum "$RULE_DIR"/*.rules.ndjson "$RULE_DIR/traceability.tsv" "$RULE_DIR/digests.sha256" > "$TMP2"
if ! diff -u "$TMP1" "$TMP2" >/dev/null; then
  echo "ERROR: extraction is not byte-deterministic" >&2
  rm -f "$TMP1" "$TMP2"
  exit 2
fi
rm -f "$TMP1" "$TMP2"

echo "rules validation passed"
