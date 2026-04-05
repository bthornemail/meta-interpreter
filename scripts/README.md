# Scripts Index

Scripts for the meta-interpreter project, organized by function.

## Invariant

No script may:
- redefine runtime state
- derive canonical meaning outside runtime
- introduce non-replayable behavior

All scripts must be classifiable into exactly one layer.

## Status Legend

| Status | Meaning |
|--------|---------|
| `implemented` | Working, tested, part of core substrate |
| `target_state` | Designed but not yet implemented |
| `research_open` | Active research, may change |
| `research_open_inferred` | Inferred from research, not yet validated |
| `deprecated` | Retained for reference, do not use |

## Modality Legend

| Modality | Meaning |
|----------|---------|
| `core` | POSIX substrate (authoritative execution path) |
| `surface` | Projection consumers (non-authoritative) |
| `governance` | Validation only (non-authoritative) |
| `research` | Pre-freeze / experimental |

## Layer Mapping

The canonical flow is:

```
runtime → step_digest → incidence → grammar → address → witness → matrix → projection
```

Scripts are tagged by which layer they operate on.

---

## Core Runtime

**authority: YES**

| Script | Layer | Status | Modality | Purpose |
|--------|-------|--------|----------|---------|
| `ttc_busybox.sh` | runtime | `implemented` | `core` | BusyBox-first bitwise triangulation runner |
| `smoke_canonical_runtime.sh` | runtime | `implemented` | `core` | Canonical runtime smoke test |
| `rule_runtime.sh` | runtime | `implemented` | `core` | Rule-driven runtime execution wrapper |
| `rule_runtime.awk` | runtime | `implemented` | `core` | AWK core for rule processing |

---

## Encoding/Decoding

**authority: YES** (canonical encoding/decoding is part of runtime contract)

| Script | Layer | Status | Modality | Purpose |
|--------|-------|--------|----------|---------|
| `ttc_symbolic_encode` | witness | `implemented` | `core` | Encode bytes to symbolic representation |
| `ttc_symbolic_decode` | witness | `implemented` | `core` | Decode symbolic back to bytes |
| `ttc_uri.awk` | address | `implemented` | `core` | URI encoding for artifacts |

---

## Artifact Management

**authority: YES** (artifact identity is part of the address layer)

| Script | Layer | Status | Modality | Purpose |
|--------|-------|--------|----------|---------|
| `artifact_path.awk` | address | `implemented` | `core` | Compute artifact paths from coordinates |
| `artifact_resolve.awk` | address | `implemented` | `core` | Resolve artifact references |
| `materialize_trie_artifacts.sh` | address | `implemented` | `core` | Generate trie artifacts |
| `leaf_contract.sh` | address | `implemented` | `core` | Leaf contract processing |

---

## Fano/Materialization

**authority: YES** (Fano paths affect incidence selection)

| Script | Layer | Status | Modality | Purpose |
|--------|-------|--------|----------|---------|
| `fano.awk` | incidence | `implemented` | `core` | Fano path processing |
| `materialize_factoradic_5040.sh` | incidence | `implemented` | `core` | Factoradic 5040 materialization |
| `factoradic_fifo_demo.sh` | transport | `implemented` | `core` | Factoradic FIFO demo |

---

## Projection/Rendering

**authority: NO** (projection is downstream, non-authoritative)

| Script | Layer | Status | Modality | Purpose |
|--------|-------|--------|----------|---------|
| `validate_projection_render.py` | projection | `implemented` | `surface` | Validate projection rendering |
| `validate_media_render.py` | projection | `implemented` | `surface` | Validate media rendering |
| `generate_matrix_seal_page.py` | matrix | `implemented` | `surface` | Generate matrix seal HTML |

---

## Governance/Lexicon

**authority: NO** (governance validates, does not define)

| Script | Layer | Status | Modality | Purpose |
|--------|-------|--------|----------|---------|
| `validate_lexicon.sh` | grammar | `implemented` | `governance` | Lexicon validation |
| `validate_surfaces.sh` | projection | `implemented` | `governance` | Surface validation |
| `validate_ontology.sh` | ontology | `implemented` | `governance` | Ontology validation |
| `validate_governance_audit.sh` | governance | `implemented` | `governance` | Governance audit runner |
| `governance_audit.py` | governance | `implemented` | `governance` | Audit reporting |

---

## Narrative/Witness

**authority: NO** (witness is derived from runtime, not authoritative)

| Script | Layer | Status | Modality | Purpose |
|--------|-------|--------|----------|---------|
| `bind_narrative_to_witness.py` | witness | `implemented` | `surface` | Bind narrative to witness |
| `validate_narrative_binding.py` | witness | `implemented` | `surface` | Validate binding |
| `validate_narrative_frame_export.py` | witness | `implemented` | `surface` | Validate frame export |
| `export_narrative_frames.mjs` | witness | `implemented` | `surface` | Export narrative frames |

---

## Rules Processing

**authority: YES** (rules define runtime behavior)

| Script | Layer | Status | Modality | Purpose |
|--------|-------|--------|----------|---------|
| `extract_rules.sh` | runtime | `implemented` | `core` | Extract rules from source |
| `rules_digest.sh` | runtime | `implemented` | `core` | Digest rules |
| `validate_rules.sh` | runtime | `implemented` | `core` | Validate rules |
| `infer_missing_a_rules.awk` | runtime | `research_open_inferred` | `research` | Infer missing rules |

---

## Validation (Standalone)

**authority: NO** (validation verifies, does not execute)

| Script | Layer | Status | Modality | Purpose |
|--------|-------|--------|----------|---------|
| `validate_framework.sh` | runtime | `implemented` | `core` | Framework validation |
| `validate_adapters.sh` | runtime | `implemented` | `core` | Adapter validation |
| `validate_symbolic.sh` | witness | `implemented` | `core` | Symbolic validation |
| `validate_aztec_transport.sh` | transport | `implemented` | `core` | Aztec compat alias validation |

---

## Build/Demos

**authority: NO** (build/export is materialization, not runtime)

| Script | Layer | Status | Modality | Purpose |
|--------|-------|--------|----------|---------|
| `export_adapters.sh` | runtime | `implemented` | `core` | Export adapters |
| `build_braille_mnemonic_sample.sh` | witness | `implemented` | `core` | Build braille samples |
| `hexglyph.sh` | witness | `implemented` | `core` | Hex glyph processing |

---

## Running Tests

```bash
# Core substrate tests
make canonical-smoke
make busybox-smoke

# Governance/lexicon
./scripts/validate_lexicon.sh
./scripts/validate_surfaces.sh
./scripts/validate_ontology.sh

# Validation
./scripts/validate_framework.sh
./scripts/validate_rules.sh

# Projection tests (requires Python)
./scripts/projection/validate_projection_render.py
./scripts/projection/validate_media_render.py
```

---

## Adding New Scripts

1. Add to appropriate category above
2. Identify the **layer** it operates on (runtime/step_digest/incidence/grammar/address/witness/matrix/projection)
3. Declare **status**: `implemented`, `target_state`, `research_open`, or `research_open_inferred`
4. Declare **modality**: `core`, `surface`, `governance`, or `research`
5. Set **authority**: YES if it affects canonical runtime state, NO otherwise
6. Use `set -euo pipefail` for bash scripts
7. Use POSIX sh/AWK for substrate_core compliance
8. Scripts that modify runtime behavior MUST be in the core modality

---

## Minimal Distribution

To build a pure POSIX runtime package, include only:

```
layer: runtime | incidence | grammar | address
modality: core
```

This ensures only authoritative, replayable code is included.
