# Hyperverse TTC

Public package for the TTC unified framework.

## Layout

- `src/` framework sources
- `docs/` canonical public spec
- `research/` non-normative derivation material
- `artifacts/` canonical trie outputs: `{xx|xX|Xx|XX}/{p0|p1|p2}/{lane}/{leaf}/`
- `blocks/registry/` canonical block lookup tables
- `blocks/archive/` archived legacy block sources
- `bin/` compiled binaries (generated)

## Build

```bash
make build
```

Primary framework artifacts:

- `bin/libttc_framework.a`
- `bin/libttc_runtime.a`
- `bin/libttc_witness.a`
- `bin/libttc_matrix.a`
- `bin/libttc_aztec.a`
- `bin/ttc_framework`

Primary umbrella header:

```c
#include "ttc_framework.h"
```

Normative terminology is frozen in:
- [LEXICON.md](/home/main/Programs/meta-interpreter/docs/LEXICON.md)
- [LEXICON.json](/home/main/Programs/meta-interpreter/docs/LEXICON.json)

Normative system structure is frozen in:
- [ONTOLOGY.md](/home/main/Programs/meta-interpreter/docs/ONTOLOGY.md)
- [ONTOLOGY.json](/home/main/Programs/meta-interpreter/docs/ONTOLOGY.json)

Normative observable forms are frozen in:
- [SURFACES.md](/home/main/Programs/meta-interpreter/docs/SURFACES.md)
- [SURFACES.json](/home/main/Programs/meta-interpreter/docs/SURFACES.json)

Governance audit policy and exemptions are driven by:
- [GOVERNANCE_ALLOWLIST.json](/home/main/Programs/meta-interpreter/docs/GOVERNANCE_ALLOWLIST.json)
- [GOVERNANCE_RULES.json](/home/main/Programs/meta-interpreter/docs/GOVERNANCE_RULES.json)

All documentation and code comments are subject to lexical, structural, and relational validation against the lexicon, ontology, and governance audit.
The audit engine is not an authority source; it executes machine-readable governance data from the lexicon, ontology, surfaces, and rule registries.

`step_digest` is the deterministic reduction of runtime event material used to seed incidence and structural expansion. It is not grammar and it is not artifact identity.

Surfaces expose derived representations of the system; they do not define its canonical state.

## Unified Framework

The framework exposes three explicit surfaces under one namespace:

- `runtime`: canonical replay law, versioned by rule set
- `witness`: slot codec and semantic projection
- `matrix`: TTC-specific deterministic reversible byte transport grid
- `aztec`: compatibility name only, reserved for future standards-compliant framing

Rule defaults:

- `TTC_RULE_V1_CURRENT` remains the default authoritative runtime law
- `TTC_RULE_V2_DELTA64` is available only through explicit rule selection

## Governance Audit

Run the repo-wide governance audit:

```bash
make governance-audit
```

This writes:
- `artifacts/governance/active_audit.ndjson`
- `artifacts/governance/archive_audit.ndjson`
- `artifacts/governance/summary.txt`

Active surfaces hard-fail. `archive/` and `research/` are warn-only in v1.

## Static Projection Demo

Open the frozen projection demo at:

- `demo/ttc_projection_demo.html`

It is a projection-only surface using embedded `data-ttc-*` metadata plus canvas rendering. It does not compute runtime state.

Open the NDJSON adapter demo at:

- `demo/ttc_projection_stream.html`
- `demo/ttc_runtime_sample.ndjson` is a real runtime-emitted sample the stream demo can consume unchanged.

It consumes runtime NDJSON, updates the same frozen `data-ttc-*` contract, and reuses the projection renderer without computing runtime state.
The projection demos are schema consumers, not schema definers.
The shared renderer is a projection consumer only. It may read and update projection-local DOM state, but it must not define schema, runtime logic, or transport semantics.
Projection equivalence can be checked continuously with `make projection-check`.
That check validates projection equivalence only. It does not validate runtime law.
See `docs/PROJECTION_UI.md` for the authoritative explanation of the browser projection surfaces, shared renderer, adapters, and why the UI is kept strictly downstream.
See `docs/MATRIX_SEAL_PAGE_SPEC.md` for the generated matrix seal page specification and the non-authority rule for HTML seal surfaces.

Open the live SSE demo at:

- `demo/ttc_projection_live.html`

Start the local bridge:

```bash
python3 demo/ttc_runtime_stream_server.py --port 8000
```

Then open:

```text
http://127.0.0.1:8000/ttc_projection_live.html
```

The live bridge forwards runtime NDJSON unchanged. It is a transport adapter, not a schema or projection authority.
The live canvas page is the primary browser projection surface.
SVG is a downstream export/share witness generated from the same selected step and the same frozen contract.
A-Frame remains a Phase 2 projection consumer and is not part of the current implementation.

Open the timed media page at:

- `demo/ttc_projection_media.html`

It keeps canvas as the primary live surface while adding:
- MSE-backed timed media playback
- MediaCapabilities profile selection
- basic Media Session metadata + play/pause control
- display-only capture probing via supported constraints and track settings

Timed media and capture remain downstream adapters only. They do not alter runtime law, `step_digest`, incidence, or scheduling.

Check the media lane with:

```bash
make media-check
```

## Matrix Seal Page

Generate a self-contained matrix seal page from canonical payload bytes:

```bash
make seal-page INPUT=artifact.bin OUTPUT=artifacts/seal/matrix_seal_page.html
```

Working sample:

```bash
make seal-page INPUT=demo/ttc_payload_sample.bin OUTPUT=artifacts/seal/matrix_seal_page.html
```

Optional overrides:

```bash
make seal-page \
  INPUT=artifact.bin \
  OUTPUT=artifacts/seal/custom_seal.html \
  RULE=current \
  TITLE="TTC Matrix Seal Page" \
  NOTE="generated from canonical payload bytes"
```

The seal page is a generated seal surface. Canonical authority remains the embedded
artifact bytes and verified identity, not the page markup or rendering.
It carries:

- artifact identity
- payload hex and base64 witness views
- the current TTC matrix seal surface
- runtime NDJSON replay preview
- the frozen browser projection viewer

## Run End-to-End

```bash
make pipe
```

Output defaults to `artifacts/xX/p0/0/0/aztec_legacy.txt` for the legacy witness path.

## Alternate Output Modes

```bash
make pipe MODE=raw OUT=artifacts/aztec.pgm
make pipe MODE=json OUT=artifacts/aztec.json
```

## Witness Slot Encode/Decode

Witness path (artifact -> A13 stream -> 60-slot witness coordinates -> witness geometry):

```bash
make codec
```

Roundtrip check (artifact -> slots -> artifact):

```bash
make codec-test
```

Legacy-compatible wrappers:

```bash
cat artifact.bin | ./bin/ttc_encode -m slots > /tmp/coords.txt
cat /tmp/coords.txt | ./bin/ttc_decode > /tmp/recovered.bin
cat /tmp/coords.txt | ./bin/ttc_witness -m ascii > /tmp/witness.txt
```

Unified CLI equivalents:

```bash
cat artifact.bin | ./bin/ttc_framework witness-slot-encode > /tmp/coords.txt
cat /tmp/coords.txt | ./bin/ttc_framework witness-slot-decode > /tmp/recovered.bin
cat /tmp/coords.txt | ./bin/ttc_framework witness-render > /tmp/witness.txt
```

## Canonical Runtime

Build and run smoke:

```bash
make canonical-smoke
```

BusyBox-first bitwise triangulation smoke:

```bash
make busybox-smoke
echo "120 88 95 1 2 3 255 0 42" | ./scripts/ttc_busybox.sh
cat payload.bin | ./scripts/ttc_busybox.sh --binary
echo "120 88 95" | ./scripts/ttc_busybox.sh --no-write
```

This emits per-tick canonical lines with:
- replay sequence: `(tick,state)`
- incidence sequence: `(winner,class,point,lane)`
- configuration sequence: `(leaf,address_bits)`

By default it also writes directly to trie leaf paths:
- `artifacts/{xx|xX|Xx|XX}/{p0|p1|p2}/{lane}/{leaf}/trace.log`
- `.../meta.json`
- declaration surfaces at each leaf:
  - `.canon`
  - `.block`
  - `.artifact`
  - `.bitboard`
  - `.golden`
  - `.negative`

And a deterministic blocks mirror leaf with the same fixed contract:
- `blocks/{xx|xX|Xx|XX}/{p0|p1|p2}/{lane}/{leaf}/`
  - `.canon`
  - `.block`
  - `.artifact`
  - `.bitboard`
  - `.golden`
  - `.negative`

URI/RDF adapter from busybox lines:

```bash
make busybox-uri-smoke
gawk -f scripts/ttc_uri.awk < artifacts/xX/p0/0/0/busybox_trace_uri.txt
gawk -v MODE=rdf -f scripts/ttc_uri.awk < artifacts/xX/p0/0/0/busybox_trace_uri.txt
```

## Symbolic Encoder Layer

Runtime stays canonical; symbolic layer is a separate projection/roundtrip pair:

```bash
make symbolic-smoke
cat events.txt | ./scripts/ttc_symbolic_encode --format line
cat events.txt | ./scripts/ttc_symbolic_encode --format ndjson
cat symbolic.line | ./scripts/ttc_symbolic_decode --format line
cat events.txt | ./scripts/ttc_symbolic_encode --format ndjson --vs-overlay on --write-overlay --out-root artifacts
```

Symbolic controls in v1:
- `FS`, `GS`, `RS`, `US`, `ESC`, `NULL`, `SID`, `OID`
- `NULL` is centroid/pause marker in symbolic output; runtime reset law is unchanged.
- SID/OID gating is symbolic-only:
  - `OID` is `oid_pending` unless `sid_count_in_epoch >= 2`
  - never mutates canonical runtime transition.
- VS overlay (annotation-only, non-authoritative):
  - emitted fields: `vs_applied`, `vs_cp`, `vs_mode`, `vs_supp_cp`
  - FE00/FE01 alignment overlay for mapped fullwidth punctuation forms
  - optional leaf declaration dotfile: `.vs_overlay`
  - never used to derive canonical address or URI identity.

Validation:

```bash
make symbolic-check
```

Manual usage:

```bash
cat input.bin | ./bin/ttc_canonical_runtime encode > board.txt
cat input.bin | ./bin/ttc_canonical_runtime encode --blocks blocks > board.txt
cat board.txt | ./scripts/materialize_trie_artifacts.sh --board-file board.txt --out-root artifacts --clear-targets
cat board.txt | ./bin/ttc_canonical_runtime decode --blocks blocks > recovered.txt
```

Rule-version examples:

```bash
cat input.bin | ./bin/ttc_canonical_runtime encode --rule current
cat input.bin | ./bin/ttc_canonical_runtime encode --rule delta64 --seed 0x1234
cat input.bin | ./bin/ttc_framework runtime --rule delta64 --seed 0x1234
```

## Matrix Transport

The framework now includes a deterministic TTC matrix transport subsystem distinct from the witness and projection layers.

Freeze:

- projection renders witness or matrix surfaces
- transport carries bytes
- projection is not transport
- current matrix transport is not standards Aztec
- `ttc_aztec` is currently a compatibility alias over `ttc_matrix`

Validation:

```bash
make aztec-transport-check
```

CLI example:

```bash
cat artifact.bin | ./bin/ttc_framework matrix-encode --ascii
cat artifact.bin | ./bin/ttc_framework aztec-encode --ascii   # compatibility alias only
```

## Factoradic 5040 Trie

BIP-32-style sparse radix trie materialization from bytes:
- canonical path law: `artifacts/{xx|xX|Xx|XX}/{p0|p1|p2}/{00..3b}/{0000..13af}/`
- lane namespace source: `blocks/registry/divisors_5040.tsv` (60 divisors of `5040`)

```bash
make factoradic-smoke
make factoradic-fifo-demo
echo "120 88 95 255 0" | ./scripts/materialize_factoradic_5040.sh
cat payload.bin | ./scripts/materialize_factoradic_5040.sh --binary
```

## Braille Mnemonic Sample

Generate a deterministic mnemonic sample and Braille trace:

```bash
make braille-mnemonic
# optional custom phrase:
./scripts/build_braille_mnemonic_sample.sh "abandon ability able about above absent absorb abstract absurd abuse access accident"
```

## Extension Adapters

Generate deterministic adapter artifacts for:
- `RDF` / `RDFS` / `OWL`
- `RIF` (XML payload)
- `SPARQL` query templates
- `Unicode` event stream + Braille code points
- `URI` list (`urn:ttc:artifact:...`)
- `XML` event export

```bash
make adapters-smoke
make adapters-check
echo "120 88 95 255 0" | ./scripts/export_adapters.sh
cat payload.bin | ./scripts/export_adapters.sh --binary
```

Default output directory:
- `artifacts/xX/p0/0/0/adapters/`

Validation gate:
- `scripts/validate_adapters.sh` (called by `make adapters-check`)
- includes triangulation checks:
  - RDF event identity matches URI identity (`class/point/lane/leaf/tick`)
  - fails closed on structural drift across semantic layers
