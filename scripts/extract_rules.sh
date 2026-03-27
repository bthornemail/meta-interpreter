#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUT_DIR="research/rules"
TMP_DIR="$OUT_DIR/tmp"
mkdir -p "$TMP_DIR"

cat > "$TMP_DIR/alphabet.base.ndjson" <<'EOF'
{"kind":"ttc.rule.v1","rule_id":"A1","domain":"alphabet","inputs":["x","C","n"],"when":["bitwise_context=true"],"then":["state_next=delta(x,C,n)","mask_enforced=true"],"invariants":["deterministic_transition","aligned_runtime:src/ttc_vm.awk:158-160"],"status":"implemented","sources":["research/archive/research/The 8-Symbol Alphabet as Projective Vertices.md:99"]}
{"kind":"ttc.rule.v1","rule_id":"A2","domain":"alphabet","inputs":["v","R[]"],"when":["radix_list_defined=true"],"then":["coords=mixed_encode(v,R)"],"invariants":["coordinate_determinism"],"status":"target_state","sources":["research/archive/research/The 8-Symbol Alphabet as Projective Vertices.md:108"]}
{"kind":"ttc.rule.v1","rule_id":"A3","domain":"alphabet","inputs":["v","R[]"],"when":["mixed_radix_context=true"],"then":["quotient_tail_retained=true"],"invariants":["mixed_radix_roundtrip_target"],"status":"target_state","sources":["research/archive/research/The 8-Symbol Alphabet as Projective Vertices.md:108"]}
EOF

cat > "$TMP_DIR/braille.base.ndjson" <<'EOF'
{"kind":"ttc.rule.v1","rule_id":"BRL16_TOKEN_CONTRACT","domain":"braille","inputs":["token16"],"when":["token_stream_mode=v2"],"then":["type=token16[15:12]","value=token16[11:0]"],"invariants":["big_endian","source_contract:research/archive/research/Braille.md:36-46"],"status":"target_state","sources":["research/archive/research/Braille.md:17","research/archive/research/Braille.md:36"]}
{"kind":"ttc.rule.v1","rule_id":"BRL_RELATION_OPCODE_MAP","domain":"braille","inputs":["relation_token"],"when":["type=0x1"],"then":["TICK_A=0x1001","TICK_B=0x1002","REFLECT=0x1003","ROTATE=0x1004","TANGENT=0x1005","BOUNDARY_MARK=0x1006"],"invariants":["compatible_mapping:docs/ttc_canonical_spec_v1.md:94-121"],"status":"target_state","sources":["research/archive/research/Braille.md:80"]}
EOF

cat > "$TMP_DIR/projection.base.ndjson" <<'EOF'
{"kind":"ttc.rule.v1","rule_id":"A10","domain":"projection","inputs":["epoch_state"],"when":["fold_boundary_reached=true"],"then":["new_zero=derived"],"invariants":["folded_identity_semantics"],"status":"research_open","sources":["research/archive/research/Law and Projection.md:494"]}
{"kind":"ttc.rule.v1","rule_id":"A11.1","domain":"projection","inputs":["state","constant","n"],"when":["fold_cycle=true"],"then":["fold_state=delta_iter(state,constant,7)"],"invariants":["7_fold_operator"],"status":"target_state","sources":["research/archive/research/Law and Projection.md:182"]}
{"kind":"ttc.rule.v1","rule_id":"A11.2","domain":"projection","inputs":["state","constant","n"],"when":["fold_cycle=true"],"then":["master_hex=fold_state(state,constant,n)"],"invariants":["duplicate_variant_preserved"],"status":"target_state","sources":["research/archive/research/Law and Projection.md:313"]}
{"kind":"ttc.rule.v1","rule_id":"A12","domain":"projection","inputs":["fold_count"],"when":["epoch_transition=true"],"then":["sid_marker_emitted=true"],"invariants":["bijective_successor_intent"],"status":"research_open","sources":["research/archive/research/Law and Projection.md:542"]}
{"kind":"ttc.rule.v1","rule_id":"A13","domain":"projection","inputs":["state_vec"],"when":["metric_projection=true"],"then":["packing_metric_estimate=computed"],"invariants":["24d_metric_placeholder"],"status":"research_open","sources":["research/archive/research/Law and Projection.md:577"]}
{"kind":"ttc.rule.v1","rule_id":"A15","domain":"projection","inputs":["byte"],"when":["stream_processing=true"],"then":["class=divider|control|data"],"invariants":["runtime_boundary_conflict_flagged","canonical_conflict:docs/ttc_canonical_spec_v1.md:131-154"],"status":"research_open","sources":["research/archive/research/Law and Projection.md:644"]}
{"kind":"ttc.rule.v1","rule_id":"A16","domain":"projection","inputs":["f","s","o"],"when":["steiner_check=true"],"then":["sync_state=evaluated"],"invariants":["triplet_validation"],"status":"research_open","sources":["research/archive/research/Law and Projection.md:710"]}
{"kind":"ttc.rule.v1","rule_id":"A17","domain":"projection","inputs":["tick"],"when":["tick_mod_5040=true"],"then":["master_period_event=true"],"invariants":["5040_combinator"],"status":"target_state","sources":["research/archive/research/Law and Projection.md:902"]}
{"kind":"ttc.rule.v1","rule_id":"A18","domain":"projection","inputs":["lane_state"],"when":["gearbox_mode=true"],"then":["ratio_15_16_applied=true"],"invariants":["transmission_mapping"],"status":"target_state","sources":["research/archive/research/Law and Projection.md:954"]}
{"kind":"ttc.rule.v1","rule_id":"A19","domain":"projection","inputs":["codepoint32"],"when":["unicode_wrap=true"],"then":["block4_header_emitted=true"],"invariants":["wrapper_determinism"],"status":"target_state","sources":["research/archive/research/Law and Projection.md:1007"]}
{"kind":"ttc.rule.v1","rule_id":"A20","domain":"projection","inputs":["damaged_stream"],"when":["recovery_mode=true"],"then":["hadamard_recovery_attempted=true"],"invariants":["recovery_is_deterministic"],"status":"research_open","sources":["research/archive/research/Law and Projection.md:1121"]}
{"kind":"ttc.rule.v1","rule_id":"A21.1","domain":"projection","inputs":["n","symbol"],"when":["scaling_mode=true"],"then":["hadamard_radix_scale_applied=true"],"invariants":["scaling_formula_declared"],"status":"research_open","sources":["research/archive/research/Law and Projection.md:1201"]}
{"kind":"ttc.rule.v1","rule_id":"A21.2","domain":"projection","inputs":["n","symbol"],"when":["scaling_mode=true"],"then":["hadamard_radix_scale_applied=true"],"invariants":["duplicate_variant_preserved"],"status":"research_open","sources":["research/archive/research/Law and Projection.md:1265"]}
{"kind":"ttc.rule.v1","rule_id":"A22","domain":"projection","inputs":["math_symbol"],"when":["inverse_mode=true"],"then":["symbol_to_instruction_inversion=true"],"invariants":["inversion_trace_required"],"status":"research_open","sources":["research/archive/research/Law and Projection.md:1324"]}
EOF

cat > "$TMP_DIR/consensus.base.ndjson" <<'EOF'
{"kind":"ttc.rule.v1","rule_id":"A23","domain":"consensus","inputs":["oid_state","axes_count"],"when":["promotion_check=true"],"then":["sid_promote_if_axes_count_eq_4"],"invariants":["promotion_gate_is_total"],"status":"target_state","sources":["research/archive/research/Consensus Promotion Logic..md:22"]}
{"kind":"ttc.rule.v1","rule_id":"A24","domain":"consensus","inputs":["fs","rs","us"],"when":["local_consensus_check=true"],"then":["local_sid_if_two_of_three"],"invariants":["steiner_2_of_3_rule"],"status":"target_state","sources":["research/archive/research/Consensus Promotion Logic..md:87"]}
{"kind":"ttc.rule.v1","rule_id":"A25","domain":"consensus","inputs":["gs_choice","us_agreement"],"when":["epoch_process=true"],"then":["divergent_or_consolidated_state"],"invariants":["choice_agreement_separation"],"status":"target_state","sources":["research/archive/research/Consensus Promotion Logic..md:154"]}
{"kind":"ttc.rule.v1","rule_id":"A26","domain":"consensus","inputs":["local_rs","universal_fs"],"when":["reality_check=true"],"then":["common_ground_or_void"],"invariants":["fs_anchor_required"],"status":"target_state","sources":["research/archive/research/Consensus Promotion Logic..md:234"]}
{"kind":"ttc.rule.v1","rule_id":"A27","domain":"consensus","inputs":["private_branch","universal_fs"],"when":["alignment_check=true"],"then":["sync_acquired_or_branch_active"],"invariants":["incidence_not_distance"],"status":"target_state","sources":["research/archive/research/Consensus Promotion Logic..md:298"]}
{"kind":"ttc.rule.v1","rule_id":"A29","domain":"consensus","inputs":["entropy_source"],"when":["virtual_address_resolve=true"],"then":["folded_hash_to_ipv6"],"invariants":["7_fold_transform_declared"],"status":"research_open","sources":["research/archive/research/Consensus Promotion Logic..md:354"]}
{"kind":"ttc.rule.v1","rule_id":"A30","domain":"consensus","inputs":["input_stream"],"when":["agnostic_filter=true"],"then":["pass_or_restrict"],"invariants":["restriction_over_granting"],"status":"target_state","sources":["research/archive/research/Consensus Promotion Logic..md:412"]}
EOF

cat > "$TMP_DIR/boot.base.ndjson" <<'EOF'
{"kind":"ttc.rule.v1","rule_id":"BOOT_RANK_PIPELINE_V1","domain":"boot","inputs":["tick_line"],"when":["router_pipeline_active=true"],"then":["rank_assignment_emitted"],"invariants":["script_pattern_preserved"],"status":"target_state","sources":["research/archive/research/Sovereign Boot for the Triple Tetrahedral Complex.md:99"]}
EOF

./scripts/infer_missing_a_rules.awk > "$TMP_DIR/inferred.all.ndjson"

cat "$TMP_DIR/alphabet.base.ndjson" > "$OUT_DIR/alphabet.rules.ndjson"
grep '"domain":"alphabet"' "$TMP_DIR/inferred.all.ndjson" >> "$OUT_DIR/alphabet.rules.ndjson"

cp "$TMP_DIR/braille.base.ndjson" "$OUT_DIR/braille.rules.ndjson"

cat "$TMP_DIR/projection.base.ndjson" > "$OUT_DIR/projection.rules.ndjson"
grep '"domain":"projection"' "$TMP_DIR/inferred.all.ndjson" >> "$OUT_DIR/projection.rules.ndjson"

cat "$TMP_DIR/consensus.base.ndjson" > "$OUT_DIR/consensus.rules.ndjson"
grep '"domain":"consensus"' "$TMP_DIR/inferred.all.ndjson" >> "$OUT_DIR/consensus.rules.ndjson"

cp "$TMP_DIR/boot.base.ndjson" "$OUT_DIR/boot.rules.ndjson"

: > "$OUT_DIR/complex.rules.ndjson"

cat > "$OUT_DIR/traceability.tsv" <<'EOF'
source_doc_line	rule_id	status	domain	note
research/archive/research/The 8-Symbol Alphabet as Projective Vertices.md:99	A1	implemented	alphabet	explicit A-header
research/archive/research/The 8-Symbol Alphabet as Projective Vertices.md:108	A2	target_state	alphabet	explicit A-header A2/A3
research/archive/research/The 8-Symbol Alphabet as Projective Vertices.md:108	A3	target_state	alphabet	explicit A-header A2/A3
research/archive/research/Law and Projection.md:494	A10	research_open	projection	explicit A-header
research/archive/research/Law and Projection.md:182	A11.1	target_state	projection	explicit A-header occurrence 1
research/archive/research/Law and Projection.md:313	A11.2	target_state	projection	explicit A-header occurrence 2
research/archive/research/Law and Projection.md:542	A12	research_open	projection	explicit A-header
research/archive/research/Law and Projection.md:577	A13	research_open	projection	explicit A-header
research/archive/research/Law and Projection.md:644	A15	research_open	projection	explicit A-header
research/archive/research/Law and Projection.md:710	A16	research_open	projection	explicit A-header
research/archive/research/Law and Projection.md:902	A17	target_state	projection	explicit A-header
research/archive/research/Law and Projection.md:954	A18	target_state	projection	explicit A-header
research/archive/research/Law and Projection.md:1007	A19	target_state	projection	explicit A-header
research/archive/research/Law and Projection.md:1121	A20	research_open	projection	explicit A-header
research/archive/research/Law and Projection.md:1201	A21.1	research_open	projection	explicit A-header occurrence 1
research/archive/research/Law and Projection.md:1265	A21.2	research_open	projection	explicit A-header occurrence 2
research/archive/research/Law and Projection.md:1324	A22	research_open	projection	explicit A-header
research/archive/research/Consensus Promotion Logic..md:22	A23	target_state	consensus	explicit A-header
research/archive/research/Consensus Promotion Logic..md:87	A24	target_state	consensus	explicit A-header
research/archive/research/Consensus Promotion Logic..md:154	A25	target_state	consensus	explicit A-header
research/archive/research/Consensus Promotion Logic..md:234	A26	target_state	consensus	explicit A-header
research/archive/research/Consensus Promotion Logic..md:298	A27	target_state	consensus	explicit A-header
research/archive/research/Consensus Promotion Logic..md:354	A29	research_open	consensus	explicit A-header
research/archive/research/Consensus Promotion Logic..md:412	A30	target_state	consensus	explicit A-header
inferred	A4	research_open_inferred	alphabet	template-inferred-nearest-neighbors
inferred	A5	research_open_inferred	alphabet	template-inferred-nearest-neighbors
inferred	A6	research_open_inferred	alphabet	template-inferred-nearest-neighbors
inferred	A7	research_open_inferred	alphabet	template-inferred-nearest-neighbors
inferred	A8	research_open_inferred	alphabet	template-inferred-nearest-neighbors
inferred	A9	research_open_inferred	alphabet	template-inferred-nearest-neighbors
inferred	A14	research_open_inferred	projection	template-inferred-nearest-neighbors
inferred	A28	research_open_inferred	consensus	template-inferred-nearest-neighbors
EOF

# Sanity check that anchored source lines still reference the intended A-id token.
awk -F '\t' 'NR>1 && $1 != "inferred" {
  split($1, p, ":")
  file=p[1]; line=p[2]
  cmd = "sed -n \"" line "p\" \"" file "\""
  cmd | getline text
  close(cmd)
  if (index(text, substr($2,1,3)) == 0) {
    printf("ERROR: source anchor mismatch for %s at %s\n", $2, $1) > "/dev/stderr"
    exit 2
  }
}' "$OUT_DIR/traceability.tsv"

./scripts/rules_digest.sh

rm -rf "$TMP_DIR"
echo "rules extracted into $OUT_DIR"
