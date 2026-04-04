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
-> claim
-> carrier exchange
-> provenance
-> reconciliation
-> federation
```

Derived downstream relations:

```text
derives(artifact + role + provenance, claim)
carries(claim + carrier + receipt, federation_exchange)
compares(multiple_claims, reconciliation)
classifies(reconciliation, accept | reject | defer | fork)
```

Rules:

```text
claims do not create truth
receipts do not create truth
federation does not create truth
convergence does not create truth
translation may change carrier, witness surface, transport form, or presentation form
translation must not change canonical replay identity without explicit revision law
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
