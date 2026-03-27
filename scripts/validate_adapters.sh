#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUT_DIR="artifacts/xX/p0/0/0/adapters"
PREFIX="ttc_adapters"

usage() {
  cat <<'USAGE'
Usage:
  scripts/validate_adapters.sh [--out-dir DIR] [--prefix NAME]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --prefix) PREFIX="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

RDF_FILE="$OUT_DIR/${PREFIX}.rdf.ttl"
RDFS_FILE="$OUT_DIR/${PREFIX}.rdfs.ttl"
OWL_FILE="$OUT_DIR/${PREFIX}.owl.ttl"
RIF_FILE="$OUT_DIR/${PREFIX}.rif.xml"
SPARQL_FILE="$OUT_DIR/${PREFIX}.sparql"
UNICODE_FILE="$OUT_DIR/${PREFIX}.unicode.ndjson"
URI_FILE="$OUT_DIR/${PREFIX}.uri.txt"
XML_FILE="$OUT_DIR/${PREFIX}.xml"

require_file() {
  local f="$1"
  [[ -s "$f" ]] || { echo "missing or empty: $f" >&2; exit 1; }
}

require_grep() {
  local pat="$1"
  local f="$2"
  grep -Eq "$pat" "$f" || { echo "pattern not found in $f: $pat" >&2; exit 1; }
}

require_file "$RDF_FILE"
require_file "$RDFS_FILE"
require_file "$OWL_FILE"
require_file "$RIF_FILE"
require_file "$SPARQL_FILE"
require_file "$UNICODE_FILE"
require_file "$URI_FILE"
require_file "$XML_FILE"

require_grep '^@prefix ttc: <urn:ttc:ontology#> \.$' "$RDF_FILE"
require_grep 'a ttc:ArtifactEvent ;' "$RDF_FILE"
require_grep 'ttc:uri "urn:ttc:artifact:' "$RDF_FILE"

require_grep '^ttc:ArtifactEvent a rdfs:Class ;$' "$RDFS_FILE"
require_grep '^ttc:hasClass a rdfs:Property ;$' "$RDFS_FILE"

require_grep '^<urn:ttc:ontology> a owl:Ontology ;$' "$OWL_FILE"
require_grep '^ttc:ArtifactEvent a owl:Class \.$' "$OWL_FILE"

require_grep '^<rif:Document ' "$RIF_FILE"
require_grep 'ttc:hasClassXX' "$RIF_FILE"

require_grep '^PREFIX ttc: <urn:ttc:ontology#>$' "$SPARQL_FILE"
require_grep '^SELECT \?class \(COUNT\(\?e\) AS \?count\)$' "$SPARQL_FILE"
require_grep '^ORDER BY \?tick$' "$SPARQL_FILE"

require_grep '^\[$' "$UNICODE_FILE"
require_grep '"kind":"ttc\.unicode\.event\.v1"' "$UNICODE_FILE"
require_grep '"braille_cp":"U\+' "$UNICODE_FILE"

require_grep '^urn:ttc:artifact:' "$URI_FILE"

require_grep '^<\?xml version="1\.0" encoding="UTF-8"\?>$' "$XML_FILE"
require_grep '^<ttc:ArtifactEvents xmlns:ttc="urn:ttc:ontology#">$' "$XML_FILE"
require_grep '^</ttc:ArtifactEvents>$' "$XML_FILE"
require_grep '<ttc:Event>' "$XML_FILE"

rdf_events=$(grep -c 'a ttc:ArtifactEvent ;' "$RDF_FILE")
unicode_events=$(grep -c '"kind":"ttc.unicode.event.v1"' "$UNICODE_FILE")
uri_events=$(grep -c '^urn:ttc:artifact:' "$URI_FILE")
xml_events=$(grep -c '<ttc:Event>' "$XML_FILE")

if [[ "$rdf_events" -eq 0 ]]; then
  echo "no adapter events found" >&2
  exit 1
fi

if [[ "$rdf_events" -ne "$unicode_events" || "$rdf_events" -ne "$uri_events" || "$rdf_events" -ne "$xml_events" ]]; then
  echo "event count mismatch rdf=$rdf_events unicode=$unicode_events uri=$uri_events xml=$xml_events" >&2
  exit 1
fi

echo "adapters validation passed (events=$rdf_events)"
