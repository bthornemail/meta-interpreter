#!/usr/bin/awk -f

# Input: ttc_busybox.sh lines (key=value tokens)
# Modes:
#   MODE=uri (default) -> uri<TAB>path
#   MODE=rdf           -> Turtle triples

function get_kv(line, key,   m, pat) {
    pat = key "=([^ ]+)"
    if (match(line, pat, m)) return m[1]
    return ""
}

BEGIN {
    mode = (MODE == "" ? "uri" : MODE)
    if (mode == "rdf") {
        print "@prefix ttc: <urn:ttc:ontology#> ."
        print "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> ."
        print ""
    }
}

{
    tick = get_kv($0, "tick")
    inhex = get_kv($0, "input")
    cls = get_kv($0, "class")
    point = get_kv($0, "point")
    path = get_kv($0, "path")

    n = split(path, a, "/")
    lane = a[n - 1]
    leaf = a[n]

    gsub(/^0x/, "", inhex)
    uri = "urn:ttc:artifact:" cls ":" point ":" lane ":" leaf ":t" tick ":i" inhex

    if (mode == "rdf") {
        subj = "ttc:e_t" tick "_i" inhex
        print subj " a ttc:ArtifactEvent ;"
        print "  ttc:hasClass ttc:" cls " ;"
        print "  ttc:point \"" point "\" ;"
        print "  ttc:laneHex \"" lane "\" ;"
        print "  ttc:leafHex \"" leaf "\" ;"
        print "  ttc:tick \"" tick "\"^^xsd:integer ;"
        print "  ttc:uri \"" uri "\" ."
        print ""
    } else {
        print uri "\t" path
    }
}
