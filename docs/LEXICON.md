# TTC Authoritative Lexicon v1

Typed deterministic replay is sovereign; everything else is witness, projection, or derivative.

## Global Rule

Each keyword belongs to exactly one layer.
If a term appears in another layer, it must be explicitly marked as a projection or transport usage.

Exception:
`bytes` belongs to the substrate category, not to an ordinary layer.
`step_digest` belongs to the runtime-to-incidence boundary category, not to an ordinary layer.

## Layer Map

`runtime -> timing -> incidence -> grammar -> address -> witness -> matrix -> projection -> transport -> barcode -> artifact`

## Boundary

Keywords:
- step_digest

Definition:
Deterministic bitwise reduction of a runtime step used to seed incidence and structural expansion.

Rule:
`step_digest` is the canonicalization boundary between runtime event material and incidence.
`step_digest` is not grammar.
`step_digest` is not artifact identity.
`step_digest` does not define semantics directly.
`step_digest` feeds incidence.
`step_digest` is replayable and deterministic.
`step_digest` drives structural derivation.
`step_digest` selects a point in incidence space by determining a simplex layer and coordinates within that layer.

## Substrate

Keywords:
- bytes

Definition:
Canonical byte substrate from which artifact identity is computed.

Rule:
`bytes` is upstream of transport and projection.
`bytes` is not transport.
`bytes` is not artifact.

## Runtime

Keywords:
- runtime
- state
- tick
- step
- delta
- replay
- determinism

Definition:
Canonical state evolution.

## Timing

Keywords:
- timing
- phase
- clock
- chirality
- orientation
- cycle
- schedule
- A14

Definition:
Selection/orientation derived from runtime.

## Incidence

Keywords:
- incidence
- step seed
- incidence seed
- Pascal
- Pascal triangle
- Pascal matrix
- simplex
- tetrahedron
- trinomial
- binomial
- combinatorics
- adjacency
- multiplicity
- expansion
- face
- edge
- vertex

Definition:
Combinatorial expansion law.

Identity:
Pascal/simplex = incidence algebra

## Grammar

Keywords:
- grammar
- structure
- NULL
- ESC
- FS
- GS
- RS
- US
- Header8
- control symbols
- escape depth
- context boundary

Definition:
Structural interpretation of symbols.

## Address

Keywords:
- address
- lane
- channel
- slot
- coordinate (logical)
- address word
- index
- offset (logical)

Definition:
Reference system derived from structure.

## Witness

Keywords:
- witness
- witness step
- witness symbol
- semantic encoding
- observation surface
- signal
- Braille
- hexagram
- tap code
- Morse

Definition:
Semantic representation of state.

Clarifications:
- Braille = witness-layer symbolic encoding of bits
- hexagram = structured symbolic state
- Braille (projection) must be marked explicitly when rendered visually

## Matrix

Keywords:
- matrix
- transport grid
- arrangement
- layout (structural)
- encoding surface
- matrix symbol

Definition:
Structured transport-ready arrangement of bytes.

Identity:
matrix = arranged structural surface for transport

## Projection

Keywords:
- projection
- grid
- render
- ASCII
- PGM
- SVG
- mesh
- 2D
- 3D
- AR
- VR
- screen
- visualization

Definition:
Rendering of witness or matrix into visual/material form.

Clarification:
matrix = internal structure
grid = projection

## Structured Data Carriers

Rule:
All TTC data reduces to canonical bytes.
All external structured surfaces are non-authoritative carriers or projections of those bytes.

### Byte-Compatible Carriers

Keywords:
- bytes
- string
- ArrayBuffer
- BLOB

Definitions:
- `bytes`: canonical substrate
- `string`: UTF-8 textual carrier of bytes
- `ArrayBuffer`: byte container for canonical or transport use
- `BLOB`: byte container for canonical or transport use

Primary layers:
- `bytes` -> substrate
- `string` -> projection
- `ArrayBuffer` -> transport
- `BLOB` -> transport

### Stream Transport

Keywords:
- FIFO
- pipe
- socket

Definition:
Process-to-process byte-stream transport.

Rule:
FIFO carries bytes.
FIFO does not define semantics.

Primary layer:
- `FIFO` -> transport
- `pipe` -> transport
- `socket` -> transport

### Structured Documents

Keywords:
- JSON
- NDJSON
- JSON Canvas

Definitions:
- `JSON`: structured document projection
- `NDJSON`: structured event-stream projection
- `JSON Canvas`: layout/graph projection

Primary layers:
- `JSON` -> projection
- `NDJSON` -> projection
- `JSON Canvas` -> projection

Rules:
- JSON is not canonical.
- NDJSON is not canonical.
- JSON Canvas is not canonical.
- JSON Canvas does not define meaning.
- Structured surfaces that claim reversibility must round-trip to canonical bytes without loss.

## Transport

Keywords:
- transport
- encode
- decode
- byte stream
- carrier
- packet
- TTC matrix transport

Definition:
Byte movement layer.

## Barcode

Keywords:
- barcode
- QR
- Aztec
- scanner
- scan
- decoding camera

Definition:
Scannable projection plus transport constraint.

Restriction:
`Aztec` belongs here only when standards-compliant.

## Artifact

Keywords:
- artifact
- package
- payload
- hash
- fingerprint
- identity
- verification
- receipt

Definition:
Canonical package with identity and verification.

Identity:
artifact = canonical identity + payload

Clarifications:
- `artifact_hash` proves identity
- `step_digest` seeds structure

## Downstream Extension Vocabulary

These terms are downstream and artifact-/transport-adjacent. They do not revise the sovereign layer map.

Keywords:
- claim
- receipt
- provenance
- contract
- participant
- peer
- federation
- reconciliation
- convergence point
- translation

Definitions:
- `claim`: typed assertion about a declared layer or relation between layers
- `receipt`: deterministic witness that a claim, validation, transfer, or reconciliation step occurred
- `provenance`: replayable derivation and custody chain for claims, receipts, and artifacts
- `contract`: declared authority boundary under which a role may emit, verify, reject, accept, or reconcile
- `participant`: actor capable of emitting, receiving, verifying, rejecting, or reconciling claims and receipts
- `peer`: participant in declared federated relation to another participant
- `federation`: exchange discipline among participants and peers under declared contracts
- `reconciliation`: deterministic comparison of claims and receipts against replay and declared contract
- `convergence point`: site or process where multiple claims or receipts are compared under contract
- `translation`: change of carrier, witness surface, transport form, or presentation form that preserves canonical identity

Placement:
- `claim`, `receipt`, `provenance`, `contract`, `participant`, `peer`, `federation`, `reconciliation`, `convergence point` remain artifact-adjacent downstream terms
- `translation` remains a downstream transport/projection/witness term

Rules:
- claims do not create truth
- receipts do not create truth
- federation does not create truth
- convergence does not create truth
- translation may change carrier or presentation, but it must not silently change canonical replay identity

## Critical Disambiguations

- Braille (witness) != Braille (projection)
- hexagram != geometry
- coordinate (address) != coordinate (pixel)
- matrix != grid

## Forbidden Collisions

- `Aztec transport`
- `artifact encoding`
- `matrix rendering`
- `witness grid`
- `Braille transport`
- `JSON is canonical`
- `NDJSON is canonical`
- `Canvas defines meaning`

## Required Clarifications

- `Braille (witness)`
- `Braille (projection)`
- `hexagram (witness)`
- `grid (projection)`
- `matrix (transport)`
- `JSON Canvas (projection)`
- `FIFO (transport)`
- `step_digest (boundary)`
- `artifact_hash (artifact)`

## Canonical Sentence

runtime generates state
timing selects orientation
step_digest seeds incidence
incidence expands structure (Pascal/simplex)
grammar interprets structure
address names structure
witness encodes meaning (Braille, hexagrams)
matrix arranges bytes
projection renders it
barcode makes it scannable
artifact proves identity

For structured data and process composition:
- bytes remain canonical
- FIFO/pipe/socket carry byte streams
- NDJSON and JSON carry structured projections
- JSON Canvas carries layout projections
- step_digest is the deterministic reduction of runtime event material used to seed incidence and structural expansion
- peers exchange claims and receipts, not truth itself
- truth remains canonical replay
