# TTC Surfaces v1

Typed deterministic replay is sovereign; surfaces expose derived structure and do not define canonical state.

Authoritative runtime emits canonical events and authoritative step_digest; all other surfaces are downstream derived surfaces unless explicitly marked as substrate or artifact identity.

## Core Rule

```text
Surfaces expose derived structure.
Surfaces do not define canonical state.
```

## Surface Categories

Surfaces are classified by role, not by file format.

## 1. Substrate Surface

```text
bytes
```

- layer: substrate
- canonical: yes
- reversible: n/a
- authority: canonical

Notes:
- bytes are included for completeness even though they are not a UI surface
- bytes are upstream of transport, projection, and artifact identity

## 2. Runtime Surface

```text
event stream
```

- layer: runtime to boundary
- forms: NDJSON, FIFO, stdout, byte stream
- reversible: yes
- authority: canonical replay emission

Includes:
- triplet
- order
- seq56

## 3. Incidence Surface

```text
step_digest
incidence metadata
```

- layer: runtime to incidence boundary, incidence
- forms: structured NDJSON or JSON
- reversible: yes, from event material
- authority: derived, not canonical

Includes:
- simplex layer
- incidence coordinates
- Pascal/simplex coefficients

## 4. Structural Surface

```text
grammar output
address output
```

- layer: grammar and address
- forms: structured NDJSON or JSON
- reversible: yes, from step-digest-conditioned structure
- authority: derived

Includes:
- control structure
- lanes
- channels
- slots
- address words

## 5. Witness Surface

```text
Braille
hexagram
symbolic encodings
```

- layer: witness
- forms: symbolic encodings
- reversible: yes, to addressed structure
- authority: semantic, not canonical

## 6. Matrix Surface

```text
TTC matrix
```

- layer: matrix
- forms: transport-ready byte arrangement
- reversible: yes
- authority: transport-ready, not identity

Rule:

```text
TTC matrix is not a barcode.
```

## 7. Projection Surfaces

```text
ASCII
PGM
SVG
JSON Canvas
2D
3D
AR
VR
timed media
```

- layer: projection
- reversible: sometimes; reversibility must be declared per surface
- authority: none

Rule:

```text
projection does not define structure
```

Timed media notes:

- MSE-backed `<audio>` / `<video>` is a timed media projection surface
- MediaCapabilities is a projection suitability probe
- Media Session is a platform control adapter
- capture constraints are device-facing tuning only and do not influence runtime law

## 8. Transport Surfaces

```text
FIFO
pipe
socket
binary stream
```

- layer: transport
- reversible: yes
- authority: none

Rule:

```text
transport does not define semantics
```

## 9. Barcode Surfaces

```text
Aztec
QR
```

- layer: barcode
- status: future or standards-specific
- reversible: yes, with the declared barcode standard and integrity rules
- authority: none

Rules:

```text
barcode is projection constrained by transport interoperability
Aztec refers only to standards-compliant barcode framing
```

## 10. Artifact Surface

```text
artifact package
```

- layer: artifact
- forms: bytes plus identity material
- reversible: yes
- authority: identity only

Rule:

```text
artifact = identity plus payload
```

Downstream structured witnesses that remain artifact-adjacent:

- claims
- receipts
- provenance chains
- reconciliation outcomes

These may be packaged with artifacts or validation output, but they do not redefine canonical state.

## 11. Downstream Claim and Receipt Surfaces

Claims and receipts are structured downstream witness or artifact surfaces.

Rules:

```text
claims do not create truth
receipts do not create truth
provenance is a witness chain, not a sovereign layer
reconciliation outputs are downstream witness/artifact products
projection may display claims and receipts, but display does not create authority
```

## Surface Invariants

```text
No surface defines canonical state except bytes.
No surface may influence runtime.
No projection defines structure.
No transport defines semantics.
No matrix defines identity.
No artifact defines structure.
Projection must not influence check ordering.
Transport must not influence check ordering.
Artifact hash must not influence check ordering.
Claims must not influence runtime.
Receipts must not influence runtime.
```

## Surface Flow

```text
event
  -> step_digest
  -> incidence surface
  -> structural surface
  -> witness surface
  -> matrix surface
  -> projection surface
```

Parallel:

```text
bytes -> transport
bytes -> artifact
```

## Surface Classification Table

| Surface      | Layer      | Reversible | Authority       |
| ------------ | ---------- | ---------- | --------------- |
| bytes        | substrate  | n/a        | canonical       |
| event stream | runtime    | yes        | canonical       |
| step_digest  | boundary   | yes        | derived         |
| incidence    | incidence  | yes        | derived         |
| grammar      | grammar    | yes        | derived         |
| address      | address    | yes        | derived         |
| witness      | witness    | yes        | semantic        |
| matrix       | matrix     | yes        | transport-ready |
| projection   | projection | maybe      | none            |
| transport    | transport  | yes        | none            |
| barcode      | barcode    | yes        | none            |
| artifact     | artifact   | yes        | identity        |

## Repository Rule

```text
Surfaces expose derived representations of the system; they do not define its canonical state.
```

```text
Check ordering is determined only by tick and authoritative step_digest, never by projection, transport, or artifact identity.
```
