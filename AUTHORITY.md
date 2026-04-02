# AUTHORITY

This file defines the current law freeze for the repository.

It is intentionally written as authority order, not as tutorial prose.

## 1. Authority Order

Authority descends in this order:

1. Replayable deterministic runtime behavior
2. Explicit type law
3. Declared base clock law
4. Canonical artifact emission
5. Golden artifact comparison
6. Negative artifact derivation
7. Projection surfaces
8. Human explanation

Anything lower in the list may witness higher authority, but may not override it.

## 2. Primitive Law

The primitive semantic layer consists only of:

- `Bit`
- `BitVector`
- `Type`
- `State`
- `Trace`
- `Clock`
- `Selector`
- `Artifact`

Everything else is derived.

## 3. Determinism Law

For fixed:

- initial state
- typed trace
- base clocks
- rule set version

the system must emit exactly one deterministic replay result.

That replay result determines all lawful downstream surfaces.

No lawful output may depend on:

- randomness
- wall time
- local machine identity
- execution race order
- hidden mutable environment

## 4. Bitwise Law

Semantic transition law is bitwise.

Primitive operations are:

- `and`
- `or`
- `xor`
- `not`
- `rotl`
- `rotr`
- `mask`
- `test`
- `project`
- `select`
- `close`

These operations act over finite typed bit-vectors.

Arithmetic is not primitive semantic law.

If arithmetic appears, it is an implementation-level rendering of a bitwise relation or a human-readable projection.

## 5. Number Law

Numbers are not primitive ontology in this system.

The following must be treated as derived:

- ordinals
- counts
- indices
- lanes
- leaves
- addresses
- identifiers

Exception:

- base clock rotation constants may be primitive constitutional constants

Derived numeric views may be emitted for:

- readability
- storage layout
- projection
- debugging

But those views must not be mistaken for primitive semantic law.

## 6. Base Clock Law

Base clocks are the only permitted primitive cyclic anchors.

They may be declared as fixed constitutional rotations.

All higher periodicity, synchronization, and address structure must be derived from replay and clock composition.

## 7. Type Law

A bit pattern without type is not yet lawful state.

At minimum, the system distinguishes:

- `Control`
- `Payload`
- `Selector`
- `Witness`
- `Address`
- `ArtifactSurface`

Type determines interpretation before projection.

Projection may reveal type, but may not redefine it.

## 8. Replay Law

Replay is sovereign.

From replay come:

- identity
- order
- state continuity
- lawful selection context
- lawful closure context

Naming does not create identity.
Storage position does not create identity.
UI order does not create identity.

## 9. Selector Law

A selector may only derive from:

- lawful state
- lawful replay position
- lawful phase
- declared type
- declared base clock relations

A selector may not inject new authority.

If a selector conflicts with replay, replay wins.

## 10. Closure Law

Closure is lawful consequence, not arbitrary aggregation.

A closed result must be reproducible from the same replay context.

If closure cannot be replayed, it is descriptive only and has no constitutional authority.

## 11. Artifact Law

Every authoritative output artifact must belong to exactly one lawful surface:

- `Canonical`
- `Golden`
- `Negative`

### Canonical Artifact Law

The canonical artifact is the direct deterministic emission of replay law from typed input.

It is authoritative because it is what the runtime actually produced.

### Golden Artifact Law

The golden artifact is the fixed normative witness against which canonical emission is checked.

It is authoritative as a standard of declared alignment.

### Negative Artifact Law

The negative artifact is the lawful counter-witness produced by declared inversion, complement, rejection, or opposition rules.

It is authoritative because it expresses the system's explicit non-affirmed branch under law.

## 12. Artifact Backing Law

No artifact is authoritative unless it is reproducible from:

- typed input trace
- initial state
- base clocks
- rule set version
- declared artifact surface

If reproducibility is missing, authority is missing.

## 13. Path Law

Paths are projections of derived identity.

They may witness address structure.

They may materialize replay results.

They may not generate semantic truth on their own.

If replay identity and path identity diverge, replay identity is authoritative.

## 14. Prose and Witness Law

Comments, markdown, diagrams, filenames, and generated witness surfaces are subordinate to replay law.

If they conflict with replayable runtime behavior:

1. runtime law is authoritative
2. the witness surface is stale, partial, or wrong
3. authority does not move downward to rescue the prose

## 15. Projection Law

The following are projection surfaces:

- Braille
- Unicode
- Aztec
- lattice coordinates
- JSON
- text rows
- diagrams
- filesystem trees

Projection surfaces may stabilize witness.

They may not outrank replay law, type law, or artifact law.

## 16. Validation Law

An authoritative claim must answer:

1. What typed trace produced this?
2. What replay law produced this?
3. What base clocks governed it?
4. Which artifact surface does it belong to?
5. Can it be reproduced exactly?

If any answer is unavailable, the claim is non-authoritative.

## 17. Revision Law

Law may only be changed by explicit revision.

When law changes:

- canonical output changes as a consequence
- golden output changes by deliberate re-baselining
- negative output changes by lawful consequence

No silent revision is valid.

## 18. Interpretive Rule

When there is tension between:

- runtime behavior
- type expectations
- artifact layout
- human explanation

resolve in this order:

1. replayable runtime behavior
2. explicit type law
3. explicit artifact law
4. projection form
5. prose explanation

## 19. Freeze Sentence

This repository is governed by typed, purely bitwise, fully deterministic replay law in which only base clocks are primitive, all numbers are derived, and every authoritative output must exist as canonical, golden, or negative artifact.
