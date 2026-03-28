# Hyperverse TTC

Public package for the TTC dual-time toolchain.

## Layout

- `src/` runtime sources
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

## Canonical Encode/Decode Split

Canonical path (artifact -> A13 stream -> 60-slot coordinates -> Aztec geometry):

```bash
make codec
```

Roundtrip check (artifact -> slots -> artifact):

```bash
make codec-test
```

Direct tools:

```bash
cat artifact.bin | ./bin/ttc_encode -m slots > /tmp/coords.txt
cat /tmp/coords.txt | ./bin/ttc_decode > /tmp/recovered.bin
cat /tmp/coords.txt | ./bin/ttc_witness -m ascii > /tmp/witness.txt
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
