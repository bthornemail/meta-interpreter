#!/usr/bin/awk -f

BEGIN {
  emit("A4",  "alphabet", "A3",   "A10")
  emit("A5",  "alphabet", "A4",   "A3")
  emit("A6",  "alphabet", "A5",   "A4")
  emit("A7",  "alphabet", "A6",   "A5")
  emit("A8",  "alphabet", "A7",   "A6")
  emit("A9",  "alphabet", "A8",   "A7")
  emit("A14", "projection", "A13", "A15")
  emit("A28", "consensus",  "A27", "A29")
}

function emit(rule_id, domain, b1, b2) {
  print "{" \
    "\"kind\":\"ttc.rule.v1\"," \
    "\"rule_id\":\"" rule_id "\"," \
    "\"domain\":\"" domain "\"," \
    "\"inputs\":[\"inferred_input\"]," \
    "\"when\":[\"inferred_template=true\"]," \
    "\"then\":[\"inferred_effect=deterministic_placeholder\"]," \
    "\"invariants\":[\"inferred_from_nearest_neighbors\",\"disabled_by_default_policy\"]," \
    "\"status\":\"research_open_inferred\"," \
    "\"sources\":[]," \
    "\"inferred\":true," \
    "\"template_basis\":[\"" b1 "\",\"" b2 "\"]," \
    "\"inference_version\":\"v1\"" \
    "}"
}
