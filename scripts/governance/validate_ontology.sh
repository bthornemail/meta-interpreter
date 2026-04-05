#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

doc="runtime/contracts/ONTOLOGY.md"
json_doc="docs/ONTOLOGY.json"

if [[ ! -f "$doc" ]]; then
  echo "ontology violation: $doc missing" >&2
  exit 1
fi

if [[ ! -f "$json_doc" ]]; then
  echo "ontology violation: $json_doc missing" >&2
  exit 1
fi

required_patterns=(
  "^# TTC Ontology v1"
  "All constructs reduce to canonical bytes"
  "All derived structures originate from runtime steps"
  "All higher-order structure is a function of step_digest"
  "produces\\(runtime, event\\)"
  "derives\\(event, timing\\)"
  "derives\\(event, step_digest\\)"
  "drives\\(step_digest, incidence\\)"
  "expands\\(event, incidence\\)"
  "interprets\\(incidence, grammar\\)"
  "assigns\\(grammar, address\\)"
  "constructs\\(address, witness\\)"
  "arranges\\(witness, matrix\\)"
  "renders\\(matrix, projection\\)"
  "carries\\(bytes, transport\\)"
  "identifies\\(bytes, artifact\\)"
  "step_digest does not define identity"
  "step_digest does not define grammar"
  "projection must not influence check ordering"
  "transport must not influence check ordering"
  "artifact_hash must not influence check ordering"
  "Check ordering is determined only by tick and authoritative step_digest, never by projection, transport, or artifact identity"
  "runtime is the only authority"
)

for pattern in "${required_patterns[@]}"; do
  if ! rg -q "$pattern" "$doc"; then
    echo "ontology violation: missing pattern '$pattern' in $doc" >&2
    exit 1
  fi
done

if ! python3 - <<'PY'
import json
from pathlib import Path

path = Path("docs/ONTOLOGY.json")
data = json.loads(path.read_text(encoding="utf-8"))

required_types = {
    "bytes",
    "event",
    "step_digest",
    "incidence",
    "grammar",
    "address",
    "witness",
    "matrix",
    "projection",
    "transport",
    "artifact",
}

types = set(data.get("types", []))
if not required_types.issubset(types):
    missing = sorted(required_types - types)
    raise SystemExit(f"ontology violation: missing types {missing}")

relations = {tuple(item) for item in data.get("relations", [])}
required_relations = {
    ("runtime", "produces", "event"),
    ("event", "derives", "timing"),
    ("event", "derives", "step_digest"),
    ("step_digest", "drives", "incidence"),
    ("event", "expands", "incidence"),
    ("incidence", "interprets", "grammar"),
    ("grammar", "assigns", "address"),
    ("address", "constructs", "witness"),
    ("witness", "arranges", "matrix"),
    ("matrix", "renders", "projection"),
    ("bytes", "carries", "transport"),
    ("bytes", "identifies", "artifact"),
}
if not required_relations.issubset(relations):
    missing = sorted(required_relations - relations)
    raise SystemExit(f"ontology violation: missing relations {missing}")

forbidden = {tuple(item) for item in data.get("forbidden_relations", [])}
required_forbidden = {
    ("projection", "affects", "runtime"),
    ("runtime", "depends_on", "projection"),
    ("transport", "defines", "semantics"),
    ("matrix", "defines", "identity"),
    ("artifact", "defines", "structure"),
    ("Aztec", "defines", "structure"),
    ("step_digest", "defines", "grammar"),
    ("step_digest", "defines", "identity"),
}
if not required_forbidden.issubset(forbidden):
    missing = sorted(required_forbidden - forbidden)
    raise SystemExit(f"ontology violation: missing forbidden relations {missing}")
PY
then
  exit 1
fi

echo "ontology validation passed"
