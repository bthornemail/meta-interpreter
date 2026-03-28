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

tmp_rdf="$(mktemp)"
tmp_uri="$(mktemp)"

gawk '
function trimq(s) { gsub(/^"/, "", s); gsub(/"$/, "", s); return s }
function finalize() {
  if (!in_event) return
  if (tick == "" || cls == "" || point == "" || lane == "" || leaf == "" || uri == "") {
    print "invalid_rdf_event" > "/dev/stderr"
    exit 2
  }
  n = split(uri, p, ":")
  if (n < 9 || p[1] != "urn" || p[2] != "ttc" || p[3] != "artifact") {
    print "invalid_rdf_uri " uri > "/dev/stderr"
    exit 2
  }
  u_cls = p[4]; u_point = p[5]; u_lane = p[6]; u_leaf = p[7]
  u_tick = p[8]; sub(/^t/, "", u_tick)
  if (u_cls != cls || u_point != point || u_lane != lane || u_leaf != leaf || u_tick != tick) {
    print "rdf_uri_mismatch tick=" tick " cls=" cls " point=" point " lane=" lane " leaf=" leaf " uri=" uri > "/dev/stderr"
    exit 2
  }
  print tick "\t" cls "\t" point "\t" lane "\t" leaf "\t" uri
  in_event = 0
}
BEGIN { in_event = 0 }
/^ttc:e_t[0-9]+_b[0-9]+ a ttc:ArtifactEvent ;$/ {
  finalize()
  in_event = 1
  tick = cls = point = lane = leaf = uri = ""
}
in_event && /ttc:hasClass ttc:[^ ]+ ;$/ {
  s = $2; sub(/^ttc:/, "", s)
  cls = s
}
in_event && /ttc:point "[^"]+" ;$/ {
  s = $2; point = trimq(s)
}
in_event && /ttc:laneHex "[^"]+" ;$/ {
  s = $2; lane = trimq(s)
}
in_event && /ttc:leafHex "[^"]+" ;$/ {
  s = $2; leaf = trimq(s)
}
in_event && /ttc:tick "[0-9]+"\^\^xsd:integer ;$/ {
  s = $2
  gsub(/[^0-9]/, "", s)
  tick = s
}
in_event && /ttc:uri "urn:ttc:artifact:[^"]+" \.$/ {
  s = $2; uri = trimq(s)
  finalize()
}
END { finalize() }
' "$RDF_FILE" | sort -n > "$tmp_rdf"

gawk '
/^urn:ttc:artifact:/ {
  uri = $0
  n = split(uri, p, ":")
  if (n < 9) {
    print "invalid_uri_line " uri > "/dev/stderr"
    exit 2
  }
  cls = p[4]; point = p[5]; lane = p[6]; leaf = p[7]
  tick = p[8]; sub(/^t/, "", tick)
  print tick "\t" cls "\t" point "\t" lane "\t" leaf "\t" uri
}
' "$URI_FILE" | sort -n > "$tmp_uri"

if ! diff -u "$tmp_rdf" "$tmp_uri" >/dev/null; then
  echo "triangulation mismatch: RDF event identity does not align with URI identity" >&2
  diff -u "$tmp_rdf" "$tmp_uri" || true
  rm -f "$tmp_rdf" "$tmp_uri"
  exit 1
fi

rm -f "$tmp_rdf" "$tmp_uri"

echo "adapters validation passed (events=$rdf_events)"
