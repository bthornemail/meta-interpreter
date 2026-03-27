#!/usr/bin/awk -f

# TTC Rule Runtime v1 (deterministic, fail-closed)
# Inputs via -v:
#   rules_file, facts_file, queries_file, policy_file

BEGIN {
  FS = "\n"
  OFS = ""
  US = sprintf("%c", 31)

  valid_status["implemented"] = 1
  valid_status["target_state"] = 1
  valid_status["research_open"] = 1
  valid_status["deprecated"] = 1
  valid_status["research_open_inferred"] = 1

  required_rule["kind"] = 1
  required_rule["rule_id"] = 1
  required_rule["domain"] = 1
  required_rule["inputs"] = 1
  required_rule["when"] = 1
  required_rule["then"] = 1
  required_rule["invariants"] = 1
  required_rule["status"] = 1
  required_rule["sources"] = 1

  allowed_rule_key["kind"] = 1
  allowed_rule_key["rule_id"] = 1
  allowed_rule_key["domain"] = 1
  allowed_rule_key["inputs"] = 1
  allowed_rule_key["when"] = 1
  allowed_rule_key["then"] = 1
  allowed_rule_key["invariants"] = 1
  allowed_rule_key["status"] = 1
  allowed_rule_key["sources"] = 1
  allowed_rule_key["inferred"] = 1
  allowed_rule_key["template_basis"] = 1
  allowed_rule_key["inference_version"] = 1

  required_fact["kind"] = 1
  required_fact["fact_id"] = 1
  required_fact["domain"] = 1
  required_fact["payload"] = 1
  required_fact["sources"] = 1

  required_query["kind"] = 1
  required_query["query_id"] = 1
  required_query["select"] = 1
  required_query["where"] = 1
  required_query["order"] = 1
  required_query["limit"] = 1

  required_policy["kind"] = 1
  required_policy["allow_status"] = 1
  required_policy["allow_inferred"] = 1
  required_policy["fail_on_unknown_rule"] = 1
  required_policy["fail_on_schema_error"] = 1

  if (rules_file == "" || facts_file == "" || queries_file == "" || policy_file == "") {
    die("missing input file path(s): rules_file/facts_file/queries_file/policy_file")
  }

  load_policy(policy_file)
  load_rules(rules_file)
  load_facts(facts_file)
  load_queries(queries_file)
  run_queries()
  exit 0
}

function die(msg) {
  print "ERROR: ", msg > "/dev/stderr"
  exit 2
}

function trim(s,   t) {
  t = s
  sub(/^[[:space:]]+/, "", t)
  sub(/[[:space:]]+$/, "", t)
  return t
}

function stripq(s,   t) {
  t = trim(s)
  if (t ~ /^"/ && t ~ /"$/) {
    sub(/^"/, "", t)
    sub(/"$/, "", t)
  }
  return t
}

function json_get_string(line, key,   pat, out) {
  pat = "\"" key "\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""
  if (match(line, pat, out)) return out[1]
  return ""
}

function json_has_key(line, key) {
  return match(line, "\"" key "\"[[:space:]]*:") > 0
}

function json_get_raw_value(line, key,   pos, start, ch, depth, in_str, esc, out) {
  pos = match(line, "\"" key "\"[[:space:]]*:")
  if (!pos) return ""
  start = pos + RLENGTH
  while (start <= length(line) && substr(line, start, 1) ~ /[[:space:]]/) start++
  if (start > length(line)) return ""

  ch = substr(line, start, 1)
  if (ch == "[") {
    depth = 1
    in_str = 0
    esc = 0
    out = "["
    for (i = start + 1; i <= length(line); i++) {
      ch = substr(line, i, 1)
      out = out ch
      if (in_str) {
        if (esc) esc = 0
        else if (ch == "\\") esc = 1
        else if (ch == "\"") in_str = 0
      } else {
        if (ch == "\"") in_str = 1
        else if (ch == "[") depth++
        else if (ch == "]") {
          depth--
          if (depth == 0) return out
        }
      }
    }
    return ""
  }

  if (ch == "{") {
    depth = 1
    in_str = 0
    esc = 0
    out = "{"
    for (i = start + 1; i <= length(line); i++) {
      ch = substr(line, i, 1)
      out = out ch
      if (in_str) {
        if (esc) esc = 0
        else if (ch == "\\") esc = 1
        else if (ch == "\"") in_str = 0
      } else {
        if (ch == "\"") in_str = 1
        else if (ch == "{") depth++
        else if (ch == "}") {
          depth--
          if (depth == 0) return out
        }
      }
    }
    return ""
  }

  out = ""
  for (i = start; i <= length(line); i++) {
    ch = substr(line, i, 1)
    if (ch == "," || ch == "}") break
    out = out ch
  }
  return trim(out)
}

function json_array_to_usv(raw,   s, parts, n, i, item, out) {
  s = trim(raw)
  if (s == "[]") return ""
  sub(/^\[/, "", s)
  sub(/\]$/, "", s)
  n = split(s, parts, /,[[:space:]]*/)
  out = ""
  for (i = 1; i <= n; i++) {
    item = stripq(parts[i])
    if (out != "") out = out US
    out = out item
  }
  return out
}

function collect_keys(line, out_arr,   start, tail, k, m) {
  delete out_arr
  tail = line
  while (match(tail, /"([^"]+)"[[:space:]]*:/, m)) {
    k = m[1]
    out_arr[k] = 1
    tail = substr(tail, RSTART + RLENGTH)
  }
}

function must_have_keys(obj_line, required, kind_name, id,   k) {
  for (k in required) {
    if (!json_has_key(obj_line, k)) die(kind_name " missing required key '" k "' for " id)
  }
}

function enforce_known_keys(obj_line, allowed, kind_name, id,   ks, k) {
  collect_keys(obj_line, ks)
  for (k in ks) {
    if (!(k in allowed)) die(kind_name " has unknown key '" k "' for " id)
  }
}

function parse_bool(v) {
  v = trim(v)
  if (v == "true") return 1
  if (v == "false") return 0
  return -1
}

function list_contains_usv(list, val,   parts, n, i) {
  if (list == "") return 0
  n = split(list, parts, US)
  for (i = 1; i <= n; i++) if (parts[i] == val) return 1
  return 0
}

function load_policy(file,   line, kind, v, n, arr, i) {
  if ((getline line < file) <= 0) die("failed to read policy file: " file)
  close(file)

  must_have_keys(line, required_policy, "policy", "policy")

  kind = json_get_string(line, "kind")
  if (kind != "ttc.policy.v1") die("policy.kind must be ttc.policy.v1")

  policy_allow_status = json_array_to_usv(json_get_raw_value(line, "allow_status"))
  if (policy_allow_status == "") die("policy.allow_status cannot be empty")

  n = split(policy_allow_status, arr, US)
  for (i = 1; i <= n; i++) {
    if (!(arr[i] in valid_status)) die("policy.allow_status invalid enum: " arr[i])
  }

  v = parse_bool(json_get_raw_value(line, "allow_inferred"))
  if (v < 0) die("policy.allow_inferred must be boolean")
  policy_allow_inferred = v

  v = parse_bool(json_get_raw_value(line, "fail_on_unknown_rule"))
  if (v < 0) die("policy.fail_on_unknown_rule must be boolean")
  policy_fail_unknown = v

  v = parse_bool(json_get_raw_value(line, "fail_on_schema_error"))
  if (v < 0) die("policy.fail_on_schema_error must be boolean")
  policy_fail_schema = v
}

function load_rules(file,   line, idx, rid, status, inferred_raw, inferred_val, domain) {
  idx = 0
  while ((getline line < file) > 0) {
    line = trim(line)
    if (line == "") continue

    must_have_keys(line, required_rule, "rule", "line:" (idx + 1))
    if (policy_fail_unknown) enforce_known_keys(line, allowed_rule_key, "rule", "line:" (idx + 1))

    if (json_get_string(line, "kind") != "ttc.rule.v1") {
      if (policy_fail_schema) die("invalid rule kind at line " (idx + 1))
      else continue
    }

    rid = json_get_string(line, "rule_id")
    if (rid == "") die("empty rule_id at line " (idx + 1))
    if (rid in rule_seen) die("duplicate rule_id: " rid)

    domain = json_get_string(line, "domain")
    status = json_get_string(line, "status")
    if (!(status in valid_status)) die("invalid status for " rid ": " status)

    inferred_raw = json_get_raw_value(line, "inferred")
    if (inferred_raw == "") inferred_val = 0
    else {
      inferred_val = parse_bool(inferred_raw)
      if (inferred_val < 0) die("invalid inferred bool for " rid)
    }

    idx++
    rule_seen[rid] = 1
    rule_line[idx] = line
    rule_id[idx] = rid
    rule_domain[idx] = domain
    rule_status[idx] = status
    rule_inferred[idx] = inferred_val
    rule_inputs[idx] = json_array_to_usv(json_get_raw_value(line, "inputs"))
    rule_when[idx] = json_array_to_usv(json_get_raw_value(line, "when"))
    rule_then[idx] = json_array_to_usv(json_get_raw_value(line, "then"))
    rule_invariants[idx] = json_array_to_usv(json_get_raw_value(line, "invariants"))
    rule_sources[idx] = json_array_to_usv(json_get_raw_value(line, "sources"))

    rule_sort_key[idx] = rule_domain[idx] SUBSEP rule_id_sort_key(rule_id[idx]) SUBSEP first_source(rule_sources[idx])
  }
  close(file)

  rule_count = idx
  if (rule_count == 0) die("no rules loaded")

  n_sorted = asorti(rule_sort_key, sorted_rule_index, "cmp_by_value")
}

function first_source(s,   arr, n) {
  if (s == "") return ""
  n = split(s, arr, US)
  return arr[1]
}

function rule_id_sort_key(id,   a, n, num, suffix, out) {
  n = split(id, a, /[.]/)
  num = id
  sub(/^A/, "", num)
  suffix = ""
  if (n > 1) suffix = a[2]
  out = sprintf("%08d|%s", num + 0, suffix)
  return out
}

function cmp_by_value(i1, v1, i2, v2) {
  if (v1 < v2) return -1
  if (v1 > v2) return 1
  if (i1 < i2) return -1
  if (i1 > i2) return 1
  return 0
}

function load_facts(file,   line, idx, id) {
  idx = 0
  while ((getline line < file) > 0) {
    line = trim(line)
    if (line == "") continue
    must_have_keys(line, required_fact, "fact", "line:" (idx + 1))
    if (json_get_string(line, "kind") != "ttc.fact.v1") die("invalid fact kind at line " (idx + 1))
    id = json_get_string(line, "fact_id")
    if (id == "") die("empty fact_id at line " (idx + 1))
    idx++
  }
  close(file)
}

function load_queries(file,   line, idx, id) {
  idx = 0
  while ((getline line < file) > 0) {
    line = trim(line)
    if (line == "") continue
    must_have_keys(line, required_query, "query", "line:" (idx + 1))
    if (json_get_string(line, "kind") != "ttc.query.v1") die("invalid query kind at line " (idx + 1))
    id = json_get_string(line, "query_id")
    if (id == "") die("empty query_id at line " (idx + 1))
    idx++
    query_line[idx] = line
    query_id[idx] = id
    query_select[idx] = json_array_to_usv(json_get_raw_value(line, "select"))
    query_where[idx] = json_array_to_usv(json_get_raw_value(line, "where"))
    query_order[idx] = json_array_to_usv(json_get_raw_value(line, "order"))
    query_limit[idx] = json_get_raw_value(line, "limit")
  }
  close(file)
  query_count = idx
}

function parse_filter(pred,   p, k, v, op) {
  p = pred
  if (index(p, "=") == 0) return 0
  split(p, kv, "=")
  k = trim(kv[1])
  v = trim(kv[2])
  filter_key = k
  filter_val = v
  return 1
}

function rule_matches(idx, where_usv,   n, arr, i, pred, k, v) {
  if (where_usv == "") return 1
  n = split(where_usv, arr, US)
  for (i = 1; i <= n; i++) {
    pred = arr[i]
    if (!parse_filter(pred)) die("invalid where predicate: " pred)
    k = filter_key
    v = filter_val

    if (k == "domain") { if (rule_domain[idx] != v) return 0; continue }
    if (k == "status") { if (rule_status[idx] != v) return 0; continue }
    if (k == "rule_id") { if (rule_id[idx] != v) return 0; continue }
    if (k == "inferred") {
      if (v != "true" && v != "false") die("where inferred must be true|false")
      if ((v == "true" ? 1 : 0) != rule_inferred[idx]) return 0
      continue
    }

    die("unsupported where key: " k)
  }
  return 1
}

function rule_allowed(idx) {
  if (!list_contains_usv(policy_allow_status, rule_status[idx])) return 0
  if (!policy_allow_inferred && rule_inferred[idx]) return 0
  return 1
}

function json_escape(s,   t) {
  t = s
  gsub(/\\/, "\\\\", t)
  gsub(/"/, "\\\"", t)
  return t
}

function array_push(arr_name, v,   nvar) {
  nvar = arr_name "_n"
  tmp = ++cnt[nvar]
  data[arr_name, tmp] = v
}

function emit_json_array(arr_name,   nvar, n, i, s, out) {
  nvar = arr_name "_n"
  n = cnt[nvar] + 0
  out = "["
  for (i = 1; i <= n; i++) {
    s = data[arr_name, i]
    if (i > 1) out = out ","
    out = out "\"" json_escape(s) "\""
  }
  out = out "]"
  return out
}

function clear_array(arr_name,   nvar, n, i) {
  nvar = arr_name "_n"
  n = cnt[nvar] + 0
  for (i = 1; i <= n; i++) delete data[arr_name, i]
  cnt[nvar] = 0
}

function compute_digest(preimage,   cmd, out, parts, n) {
  cmd = "printf '%s' \"" json_escape_shell(preimage) "\" | sha256sum"
  cmd | getline out
  close(cmd)
  n = split(out, parts, /[[:space:]]+/)
  return "sha256:" parts[1]
}

function json_escape_shell(s,   t) {
  t = s
  gsub(/\\/, "\\\\", t)
  gsub(/"/, "\\\"", t)
  gsub(/\$/, "\\$", t)
  gsub(/`/, "\\`", t)
  return t
}

function run_queries(   q, i, idx, rid, key, limit_num, applied_n, selected_n, preimage, digest, status) {
  for (q = 1; q <= query_count; q++) {
    clear_array("applied")
    clear_array("skipped")
    clear_array("selected")

    limit_num = query_limit[q] + 0
    if (limit_num <= 0) limit_num = 1000000000

    for (i = 1; i <= n_sorted; i++) {
      idx = sorted_rule_index[i]
      if (!rule_matches(idx, query_where[q])) continue

      rid = rule_id[idx]
      if (!rule_allowed(idx)) {
        array_push("skipped", rid)
        continue
      }

      if (cnt["selected_n"] >= limit_num) continue

      array_push("applied", rid)
      array_push("selected", select_repr(q, idx))
    }

    sort_tmp("applied")
    sort_tmp("skipped")

    status = "ok"
    preimage = query_id[q] "|" join_tmp("selected") "|" join_tmp("applied") "|" join_tmp("skipped") "|" status
    digest = compute_digest(preimage)

    print "{",
      "\"query_id\":\"", json_escape(query_id[q]), "\",",
      "\"selected\":", emit_json_array("selected"), ",",
      "\"applied_rules\":", emit_json_array("applied"), ",",
      "\"skipped_rules\":", emit_json_array("skipped"), ",",
      "\"digest\":\"", digest, "\",",
      "\"status\":\"", status, "\"",
      "}"
  }
}

function select_repr(q, idx,   sel, n, arr, i, f, out) {
  sel = query_select[q]
  if (sel == "" || sel == "*") return rule_id[idx]
  n = split(sel, arr, US)
  out = ""
  for (i = 1; i <= n; i++) {
    f = arr[i]
    if (f == "rule_id") out = append_field(out, "rule_id=" rule_id[idx])
    else if (f == "domain") out = append_field(out, "domain=" rule_domain[idx])
    else if (f == "status") out = append_field(out, "status=" rule_status[idx])
    else if (f == "inferred") out = append_field(out, "inferred=" (rule_inferred[idx] ? "true" : "false"))
    else die("unsupported select field: " f)
  }
  return out
}

function append_field(out, add) {
  if (out == "") return add
  return out ";" add
}

function sort_tmp(arr_name,   nvar, n, i, j, a, b, t) {
  nvar = arr_name "_n"
  n = cnt[nvar] + 0
  for (i = 1; i <= n; i++) {
    for (j = i + 1; j <= n; j++) {
      a = data[arr_name, i]
      b = data[arr_name, j]
      if (a > b) {
        t = data[arr_name, i]
        data[arr_name, i] = data[arr_name, j]
        data[arr_name, j] = t
      }
    }
  }
}

function join_tmp(arr_name,   nvar, n, i, out) {
  nvar = arr_name "_n"
  n = cnt[nvar] + 0
  out = ""
  for (i = 1; i <= n; i++) {
    if (out != "") out = out US
    out = out data[arr_name, i]
  }
  return out
}
