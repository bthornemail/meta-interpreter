# TTC Ontology v1

Typed deterministic replay is sovereign; ontology describes derived structure, not runtime authority.

## 0. Axiom

All constructs reduce to canonical bytes.

## 1. Primitive Types

```text
bytes        : substrate
event        : runtime step result
step_digest  : deterministic structural seed
structure    : interpreted symbol relations
address      : reference within structure
witness      : semantic encoding of structure
matrix       : arranged byte surface
projection   : rendered surface
transport    : byte carrier
artifact     : identity + payload
```

## 2. Core Relations

```text
produces(runtime, event)
derives(event, timing)
derives(event, step_digest)
drives(step_digest, incidence)
step_digest selects a point in incidence space by determining a simplex layer and coordinates within that layer.
Fano selects the active incidence line.
step_digest selects the deterministic local traversal of that line.
expands(event, incidence)
interprets(incidence, grammar)
assigns(grammar, address)
constructs(address, witness)
arranges(witness, matrix)
renders(matrix, projection)
carries(bytes, transport)
identifies(bytes, artifact)
```

## 3. Canonical Flow

```text
runtime
  -> event
  -> step_digest
  -> incidence
  -> grammar
  -> address
  -> witness
  -> matrix
  -> projection
```

Parallel relations:

```text
bytes <-> transport
bytes -> artifact
```

## 3A. Primary Material Class System

The primary material delineation for shared block and artifact surfaces is the existing four-class contract:

```text
xx/xX/Xx/XX
```

This class system is already materialized in:

- `artifacts/{xx|xX|Xx|XX}/...`
- `runtime/blocks/{xx|xX|Xx|XX}/...`
- `scripts/leaf_contract.sh`

Frozen class table:

```text
xx = affine / affine
xX = affine / projective
Xx = projective / affine
XX = projective / projective
```

This is the primary material class system for shared artifact and block surfaces.

Newer downstream symbolic-role language does not replace it.

## 4. Step-Centric Model

```text
event := runtime step result
step_digest := deterministic reduction of event
stream := ordered sequence of events
```

Streaming rule:

```text
for each event in stream:
  compute step_digest
  derive structure
```

Core principle:

```text
step = smallest unit of computation
step_digest = smallest unit of structure
```

All derived structures originate from runtime steps.
All higher-order structure is a function of step_digest.
step_digest is local.
artifact_hash is global.
Pascal/simplex coefficients are derived from the selected incidence point, not from projection or transport.
Check ordering is determined only by tick and authoritative step_digest, never by projection, transport, or artifact identity.

## 5. Type Constraints

```text
runtime does not depend on projection
projection does not affect runtime
transport does not define semantics
matrix does not define identity
artifact does not define structure
step_digest does not define identity
step_digest does not define grammar
projection must not influence check ordering
transport must not influence check ordering
artifact_hash must not influence check ordering
```

## 5A. Address-First Reconstruction

First-principles reconstruction begins with replay and address, not with emitted runtime labels.

```text
either the address exists
or it does not
```

If the address exists, the lawful reconstruction order is:

```text
replay
-> class
-> point
-> lane
-> leaf
-> address bits / address word
-> witness materialization
```

Rules:

```text
x/X expresses closure-sided witness inside address construction
xx/xX/Xx/XX expresses closure composition inside the primary material class system
what follows xx/xX/Xx/XX is address decomposition, not runtime classification
point, lane, leaf, and address words belong to address law
```

Surface reading:

```text
affine := locally instantiated address side
projective := projected or shared address side
```

This distinction is carried first by x/X and then by xx/xX/Xx/XX.

Emitted runtime witness labels may summarize later behavior, but they do not replace address law and they do not belong to first-principles ontology.

## 6. Structural Geometry

### Points

```text
point := byte | symbol | unit
```

### Lines

```text
line := ordered relation between points
```

Examples:
- Morse = line of timing and signal
- Braille = point set to encoded witness pattern
- hexagram = structured six-line witness state

### Higher Structures

```text
simplex := combinatorial relation of points
pascal  := expansion law over simplex
matrix  := linearized arrangement of relations
```

Backbone:

```text
point -> line -> simplex -> matrix
```

## 7. Incidence Law

```text
incidence defines adjacency and expansion
```

Formal primitives:

```text
adjacent(a, b)
expands(a, {b,c,d})
multiplicity(n, k)
```

Pascal is recurrence over relations.

Structural seed:

```text
incidence := f(step_digest)
```

## 8. Step Digest Law

```text
step_digest := deterministic reduction of runtime event into structural seed
```

Relations:

```text
derives(event, step_digest)
drives(step_digest, incidence)
```

Constraints:

```text
deterministic(step_digest)
replayable(step_digest)
independent_of_projection(step_digest)
not_identity(step_digest)
```

Step-centric consequence:

```text
All structure is derived from step_digest.
```

## 9. Grammar Law

```text
interprets(incidence, grammar)
```

Control anchors:

```text
ESC  -> depth
FS   -> boundary axis
GS   -> boundary axis
RS   -> boundary axis
US   -> boundary axis
NULL -> anchor
```

Grammar interprets bytes under incidence-conditioned structure.
This is projective structure, not geometry.

## 10. Address Law

```text
address := function(structure, timing, incidence)
```

Constraints:

```text
deterministic(address)
replayable(address)
independent_of_projection(address)
```

## 11. Witness Law

```text
witness := semantic_surface(structure, address)
```

Examples:
- Braille = bit witness
- hexagram = symbolic witness

## 12. Matrix Law

```text
matrix := arrange(bytes, structure)
```

Constraints:

```text
reversible(matrix)
deterministic(matrix)
byte_preserving(matrix)
```

## 13. Projection Law

```text
projection := render(matrix | witness)
```

Invariant:

```text
projection != canonical
projection witnesses resolved structure; it does not define it
```

## 14. Downstream Symbolic Roles

The following remain valid, but they are downstream symbolic-role views over the primary material class system:

```text
claim_artifact
proposal_artifact
closure_artifact
receipt_artifact
```

Rules:

```text
claim_artifact, proposal_artifact, closure_artifact, and receipt_artifact are symbolic-role views over existing class surfaces, not a replacement taxonomy
the role classes are orthogonal symbolic acts
the four material classes are the primary surface and material contract
future runtime and schema work must map role and material class explicitly rather than inferring one from the other
```

## 14. Transport Law

```text
transport := carry(bytes)
```

Examples:
- FIFO
- pipe
- socket
- TTC matrix transport
- future standards Aztec

## 15. Barcode Law

```text
barcode := projection intersect transport intersect standard
```

## 16. Artifact Law

```text
artifact := { bytes, hash(bytes) }
```

Constraints:

```text
identity = hash(bytes)
verification = recompute(hash)
```

Clarification:

```text
artifact_hash != step_digest
```

## 17. Downstream Extension

The downstream extension around the canonical stack is:

```text
canonical replay
-> propagation
-> witness
-> claim_artifact | proposal_artifact | closure_artifact | receipt_artifact
-> carrier exchange
-> provenance
-> reconciliation
-> federation
```

Derived downstream relations:

```text
derives(witness + role + provenance, claim_artifact)
derives(addressed_transition + role + provenance, proposal_artifact)
derives(contract + role + provenance, closure_artifact)
derives(event + validation + transfer, receipt_artifact)
carries(artifact + carrier + translation, federation_exchange)
compares(multiple_claims, reconciliation)
classifies(reconciliation, accept | reject | defer | fork)
derives(control_plane + step_identity + workflow, ui_frame_resolution)
```

Rules:

```text
claims do not create truth
receipts do not create truth
federation does not create truth
convergence does not create truth
translation may change carrier, witness surface, transport form, or presentation form
translation must not change canonical replay identity without explicit revision law
artifacts are classified by symbolic role, not by encoding
canonical embedding and scannable variants are translation forms of artifacts, not artifact types
control-plane multiplex may distinguish artifact class, workflow scope, record, and field boundaries without creating truth
ui_frame_resolution is downstream of replay and control resolution
```

This extension is downstream of replay and does not replace the canonical flow.

## 18. Invariants

```text
bytes are canonical
everything else is derived
```

```text
structure != transport != projection
```

```text
runtime is the only authority
```

## 19. Minimal Prolog Form

```prolog
produces(runtime, event).
derives(event, timing).
derives(event, step_digest).
drives(step_digest, incidence).
expands(event, incidence).
interprets(incidence, grammar).
assigns(grammar, address).
constructs(address, witness).
arranges(witness, matrix).
renders(matrix, projection).
carries(bytes, transport).
identifies(bytes, artifact).
```
