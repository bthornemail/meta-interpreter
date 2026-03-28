#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUT_DIR="artifacts/xX/p0/0/0/adapters"
BINARY_MODE="false"
PREFIX="ttc_adapters"
SYMBOLIC_EVENTS=""

usage() {
  cat <<'USAGE'
Usage:
  echo "120 88 95" | scripts/export_adapters.sh
  cat payload.bin | scripts/export_adapters.sh --binary

Options:
  --out-dir DIR   Output directory (default: artifacts/xX/p0/0/0/adapters)
  --prefix NAME   Output filename prefix (default: ttc_adapters)
  --binary        Read raw bytes from stdin
  --symbolic-events FILE  Read ttc.symbolic.event.v1 NDJSON instead of raw bytes
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --prefix) PREFIX="$2"; shift 2 ;;
    --binary) BINARY_MODE="true"; shift ;;
    --symbolic-events) SYMBOLIC_EVENTS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

mkdir -p "$OUT_DIR"

TMP_TSV="$(mktemp)"
if [[ -n "$SYMBOLIC_EVENTS" ]]; then
  gawk '
  function jstr(line, key,    m, pat) {
    pat = "\"" key "\":\"([^\"]*)\""
    if (match(line, pat, m)) return m[1]
    return ""
  }
  function jint(line, key,    m, pat) {
    pat = "\"" key "\":([0-9]+)"
    if (match(line, pat, m)) return m[1] + 0
    return -1
  }
  BEGIN {
    split("1 2 3 4 5 6 7 8 9 10 12 14 15 16 18 20 21 24 28 30 35 36 40 42 45 48 56 60 63 70 72 80 84 90 105 112 120 126 140 144 168 180 210 240 252 280 315 336 360 420 504 560 630 720 840 1008 1260 1680 2520 5040", divs, " ")
  }
  {
    tick = jint($0, "tick")
    byte = jint($0, "input")
    cls = jstr($0, "class")
    point = jstr($0, "point")
    winner = jint($0, "winner")
    lane = jint($0, "lane")
    leaf = jint($0, "leaf")
    vs_applied = ($0 ~ /"vs_applied":true/ ? "true" : "false")
    vs_cp = jstr($0, "vs_cp")
    vs_mode = jstr($0, "vs_mode")
    vs_supp_cp = jstr($0, "vs_supp_cp")
    if (tick < 0 || byte < 0 || cls == "" || point == "" || winner < 0 || lane < 0 || leaf < 0) next
    lane_hex = sprintf("%02x", lane)
    leaf_hex = sprintf("%04x", leaf)
    lane_divisor = divs[lane + 1] + 0
    path = sprintf("artifacts/%s/%s/%s/%s", cls, point, lane_hex, leaf_hex)
    printf("%d\t%d\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%s\t%s\t%s\t%s\t%s\n",
      tick, byte, cls, point, winner, lane, lane_hex, leaf, leaf_hex, lane_divisor, path, vs_applied, vs_cp, vs_mode, vs_supp_cp)
  }' "$SYMBOLIC_EVENTS" > "$TMP_TSV"
elif [[ "$BINARY_MODE" == "true" ]]; then
  od -An -v -t u1 | tr -s '[:space:]' ' ' | sed 's/^ //' | gawk -f scripts/artifact_path.awk > "$TMP_TSV"
else
  cat | gawk -f scripts/artifact_path.awk > "$TMP_TSV"
fi

RDF_FILE="$OUT_DIR/${PREFIX}.rdf.ttl"
RDFS_FILE="$OUT_DIR/${PREFIX}.rdfs.ttl"
OWL_FILE="$OUT_DIR/${PREFIX}.owl.ttl"
RIF_FILE="$OUT_DIR/${PREFIX}.rif.xml"
SPARQL_FILE="$OUT_DIR/${PREFIX}.sparql"
UNICODE_FILE="$OUT_DIR/${PREFIX}.unicode.ndjson"
URI_FILE="$OUT_DIR/${PREFIX}.uri.txt"
XML_FILE="$OUT_DIR/${PREFIX}.xml"

cat > "$RDFS_FILE" <<'RDFS'
@prefix ttc: <urn:ttc:ontology#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

# TTC extension adapter schema

ttc:ArtifactEvent a rdfs:Class ;
  rdfs:label "TTC Artifact Event" .

ttc:TransformClass a rdfs:Class ;
  rdfs:label "Transform Class" .

ttc:hasClass a rdfs:Property ;
  rdfs:domain ttc:ArtifactEvent ;
  rdfs:range ttc:TransformClass .

ttc:point a rdfs:Property ;
  rdfs:domain ttc:ArtifactEvent ;
  rdfs:range rdfs:Literal .

ttc:laneHex a rdfs:Property ;
  rdfs:domain ttc:ArtifactEvent ;
  rdfs:range rdfs:Literal .

ttc:leafHex a rdfs:Property ;
  rdfs:domain ttc:ArtifactEvent ;
  rdfs:range rdfs:Literal .

ttc:tick a rdfs:Property ;
  rdfs:domain ttc:ArtifactEvent ;
  rdfs:range rdfs:Literal .

ttc:byte a rdfs:Property ;
  rdfs:domain ttc:ArtifactEvent ;
  rdfs:range rdfs:Literal .

ttc:laneDivisor a rdfs:Property ;
  rdfs:domain ttc:ArtifactEvent ;
  rdfs:range rdfs:Literal .

ttc:uri a rdfs:Property ;
  rdfs:domain ttc:ArtifactEvent ;
  rdfs:range rdfs:Literal .

RDFS

cat > "$OWL_FILE" <<'OWL'
@prefix ttc: <urn:ttc:ontology#> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

<urn:ttc:ontology> a owl:Ontology ;
  rdfs:label "TTC Artifact Adapter Ontology v1" .

ttc:ArtifactEvent a owl:Class .
ttc:TransformClass a owl:Class .

ttc:hasClass a owl:ObjectProperty ;
  rdfs:domain ttc:ArtifactEvent ;
  rdfs:range ttc:TransformClass .

ttc:point a owl:DatatypeProperty .
ttc:laneHex a owl:DatatypeProperty .
ttc:leafHex a owl:DatatypeProperty .
ttc:tick a owl:DatatypeProperty .
ttc:byte a owl:DatatypeProperty .
ttc:laneDivisor a owl:DatatypeProperty .
ttc:uri a owl:DatatypeProperty .
OWL

cat > "$SPARQL_FILE" <<'SPARQL'
PREFIX ttc: <urn:ttc:ontology#>

# Q1: class distribution
SELECT ?class (COUNT(?e) AS ?count)
WHERE {
  ?e a ttc:ArtifactEvent ;
     ttc:hasClass ?class .
}
GROUP BY ?class
ORDER BY ?class
;

# Q2: deterministic order by tick
SELECT ?e ?tick ?class ?point ?lane ?leaf
WHERE {
  ?e a ttc:ArtifactEvent ;
     ttc:tick ?tick ;
     ttc:hasClass ?class ;
     ttc:point ?point ;
     ttc:laneHex ?lane ;
     ttc:leafHex ?leaf .
}
ORDER BY ?tick
;

# Q3: promoted transform events
SELECT ?e ?tick ?uri
WHERE {
  ?e a ttc:ArtifactEvent ;
     ttc:hasClass ttc:XX ;
     ttc:tick ?tick ;
     ttc:uri ?uri .
}
ORDER BY ?tick
;
SPARQL

cat > "$RIF_FILE" <<'RIF'
<?xml version="1.0" encoding="UTF-8"?>
<rif:Document xmlns:rif="http://www.w3.org/2007/rif#" xmlns:ttc="urn:ttc:ontology#">
  <rif:payload>
    <rif:Group>
      <rif:sentence>
        <rif:Forall>
          <rif:formula>
            <rif:Implies>
              <rif:if>
                <rif:Atom>
                  <rif:op><rif:Const>ttc:hasClassXX</rif:Const></rif:op>
                  <rif:args><rif:Var>e</rif:Var></rif:args>
                </rif:Atom>
              </rif:if>
              <rif:then>
                <rif:Atom>
                  <rif:op><rif:Const>ttc:isPromoted</rif:Const></rif:op>
                  <rif:args><rif:Var>e</rif:Var></rif:args>
                </rif:Atom>
              </rif:then>
            </rif:Implies>
          </rif:formula>
        </rif:Forall>
      </rif:sentence>
    </rif:Group>
  </rif:payload>
</rif:Document>
RIF

# RDF facts + URI + Unicode NDJSON + XML

gawk -F '\t' '
BEGIN {
  print "@prefix ttc: <urn:ttc:ontology#> ."
  print "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> ."
  print ""
  print "ttc:xx a ttc:TransformClass ."
  print "ttc:xX a ttc:TransformClass ."
  print "ttc:Xx a ttc:TransformClass ."
  print "ttc:XX a ttc:TransformClass ."
  print ""
}
{
  tick=$1; byte=$2; cls=$3; point=$4; winner=$5; lane=$6; lane_hex=$7; leaf=$8; leaf_hex=$9; lane_div=$10
  vs_applied=($12 == "" ? "false" : $12)
  vs_cp=$13
  vs_mode=$14
  vs_supp_cp=$15
  subj=sprintf("ttc:e_t%s_b%s", tick, byte)
  cls_iri=sprintf("ttc:%s", cls)
  uri=sprintf("urn:ttc:artifact:%s:%s:%s:%s:t%s:b%s", cls, point, lane_hex, leaf_hex, tick, byte)
  cp=0x2800 + byte
  cp_hex=toupper(sprintf("%04x", cp))
  print subj " a ttc:ArtifactEvent ;"
  print "  ttc:hasClass " cls_iri " ;"
  print "  ttc:point \"" point "\" ;"
  print "  ttc:laneHex \"" lane_hex "\" ;"
  print "  ttc:leafHex \"" leaf_hex "\" ;"
  print "  ttc:tick \"" tick "\"^^xsd:integer ;"
  print "  ttc:byte \"" byte "\"^^xsd:integer ;"
  print "  ttc:winner \"" winner "\"^^xsd:integer ;"
  print "  ttc:laneDivisor \"" lane_div "\"^^xsd:integer ;"
  print "  ttc:unicodeBraille \"U+" cp_hex "\" ;"
  if (vs_applied == "true") {
    print "  ttc:vsApplied \"true\"^^xsd:boolean ;"
    print "  ttc:vsCP \"" vs_cp "\" ;"
    print "  ttc:vsMode \"" vs_mode "\" ;"
    if (vs_supp_cp != "") print "  ttc:vsSuppCP \"" vs_supp_cp "\" ;"
  }
  print "  ttc:uri \"" uri "\" ."
  print ""
}
' "$TMP_TSV" > "$RDF_FILE"

gawk -F '\t' '{
  tick=$1; byte=$2; cls=$3; point=$4; lane_hex=$7; leaf_hex=$9
  uri=sprintf("urn:ttc:artifact:%s:%s:%s:%s:t%s:b%s", cls, point, lane_hex, leaf_hex, tick, byte)
  print uri
}' "$TMP_TSV" > "$URI_FILE"

gawk -F '\t' '
BEGIN { print "["; first=1 }
{
  tick=$1; byte=$2; cls=$3; point=$4; winner=$5; lane=$6; lane_hex=$7; leaf=$8; leaf_hex=$9; lane_div=$10
  vs_applied=($12 == "" ? "false" : $12)
  vs_cp=$13
  vs_mode=$14
  vs_supp_cp=$15
  cp=0x2800 + byte
  cp_hex=toupper(sprintf("%04x", cp))
  glyph=sprintf("%c", cp)
  if (!first) print ","
  printf "  {\"kind\":\"ttc.unicode.event.v1\",\"tick\":%d,\"byte\":%d,\"class\":\"%s\",\"point\":\"%s\",\"winner\":%d,\"lane\":%d,\"lane_hex\":\"%s\",\"leaf\":%d,\"leaf_hex\":\"%s\",\"lane_divisor\":%d,\"braille_cp\":\"U+%s\",\"braille_glyph\":\"%s\",\"vs_applied\":%s,\"vs_cp\":\"%s\",\"vs_mode\":\"%s\",\"vs_supp_cp\":\"%s\"}", tick, byte, cls, point, winner, lane, lane_hex, leaf, leaf_hex, lane_div, cp_hex, glyph, vs_applied, vs_cp, vs_mode, vs_supp_cp
  first=0
}
END { print "\n]" }
' "$TMP_TSV" > "$UNICODE_FILE"

gawk -F '\t' '
BEGIN {
  print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  print "<ttc:ArtifactEvents xmlns:ttc=\"urn:ttc:ontology#\">"
}
{
  tick=$1; byte=$2; cls=$3; point=$4; winner=$5; lane=$6; lane_hex=$7; leaf=$8; leaf_hex=$9; lane_div=$10
  vs_applied=($12 == "" ? "false" : $12)
  vs_cp=$13
  vs_mode=$14
  vs_supp_cp=$15
  cp=0x2800 + byte
  cp_hex=toupper(sprintf("%04x", cp))
  uri=sprintf("urn:ttc:artifact:%s:%s:%s:%s:t%s:b%s", cls, point, lane_hex, leaf_hex, tick, byte)
  print "  <ttc:Event>"
  print "    <ttc:tick>" tick "</ttc:tick>"
  print "    <ttc:byte>" byte "</ttc:byte>"
  print "    <ttc:class>" cls "</ttc:class>"
  print "    <ttc:point>" point "</ttc:point>"
  print "    <ttc:winner>" winner "</ttc:winner>"
  print "    <ttc:laneHex>" lane_hex "</ttc:laneHex>"
  print "    <ttc:leafHex>" leaf_hex "</ttc:leafHex>"
  print "    <ttc:laneDivisor>" lane_div "</ttc:laneDivisor>"
  print "    <ttc:brailleCP>U+" cp_hex "</ttc:brailleCP>"
  if (vs_applied == "true") {
    print "    <ttc:vsApplied>true</ttc:vsApplied>"
    print "    <ttc:vsCP>" vs_cp "</ttc:vsCP>"
    print "    <ttc:vsMode>" vs_mode "</ttc:vsMode>"
    if (vs_supp_cp != "") print "    <ttc:vsSuppCP>" vs_supp_cp "</ttc:vsSuppCP>"
  }
  print "    <ttc:uri>" uri "</ttc:uri>"
  print "  </ttc:Event>"
}
END { print "</ttc:ArtifactEvents>" }
' "$TMP_TSV" > "$XML_FILE"

rm -f "$TMP_TSV"

echo "adapter exports written to $OUT_DIR"
echo "  $RDF_FILE"
echo "  $RDFS_FILE"
echo "  $OWL_FILE"
echo "  $RIF_FILE"
echo "  $SPARQL_FILE"
echo "  $UNICODE_FILE"
echo "  $URI_FILE"
echo "  $XML_FILE"
