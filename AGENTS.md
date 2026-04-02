# AGENTS

This repository is governed by runtime law, not prose convenience.

Any agent, assistant, tool, or contributor working here must follow the rules below.

## 1. First Principle

The only authoritative source of truth is replayable runtime behavior.

When there is conflict between:

- prose
- diagrams
- filenames
- comments
- historical notes
- generated artifacts

and executable deterministic replay, executable deterministic replay wins.

## 2. What An Agent Must Optimize For

An agent working in this repository must preserve:

- determinism
- bitwise purity
- type discipline
- replayability
- artifact reproducibility
- explicit authority boundaries

An agent must not optimize for:

- prettier narrative
- easier metaphors
- fashionable abstractions
- hidden convenience state
- silent coercions

## 3. Constitutional Working Rules

1. Runtime truth outranks explanation.
2. Types outrank projections.
3. Replay outranks naming.
4. Derived identity outranks file layout.
5. Canonical emission outranks descriptive interpretation.
6. Golden artifacts are normative witnesses, not suggestions.
7. Negative artifacts are lawful counter-witnesses, not trash output.

## 4. Primitive Semantic Objects

Agents must treat these as the irreducible semantic layer:

- `Bit`
- `BitVector`
- `Type`
- `State`
- `Trace`
- `Clock`
- `Selector`
- `Artifact`

Everything else is derived.

## 5. Determinism Rules

Given the same:

- initial state
- typed trace
- base clock configuration
- rule set version

the system must produce the same:

- next states
- selections
- closures
- addresses
- canonical artifacts
- golden comparisons
- negative artifacts

Agents must not introduce:

- randomness
- hidden mutable ambient state
- wall-clock dependence
- process-order dependence
- machine-local authority

## 6. Bitwise Rules

Semantic transition law must be expressible in bitwise terms.

Allowed primitive operations are:

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

Arithmetic may appear as a derived view or implementation convenience, but not as the primitive semantic basis of the law.

## 7. Numbers

Numbers are not primitive ontology here.

Agents must assume:

- counts are derived
- indices are derived
- addresses are derived
- lanes are derived
- leaves are derived
- ordinals are derived

Exception:

- declared base clock rotations may be treated as primitive constitutional constants

## 8. Types

A bit pattern without type is not yet lawful state.

At minimum, agents must preserve the distinction between:

- `Control`
- `Payload`
- `Selector`
- `Witness`
- `Address`
- `ArtifactSurface`

Projection must never silently change semantic type.

## 9. Replay and Selection

Identity comes from replay.

Order comes from replay.

Selection must be derived from lawful state, lawful phase, and declared type.

An agent must not inject authority by:

- hand-assigning meaning to labels
- treating paths as primary ontology
- using UI order as semantic order
- preferring prose claims over replay output

## 10. Artifact Surfaces

Every authoritative artifact belongs to one of three lawful surfaces:

- `Canonical`
- `Golden`
- `Negative`

### Canonical

The direct deterministic emission of runtime law from the typed trace.

### Golden

The fixed normative witness used to verify that canonical behavior remains aligned with declared law.

### Negative

The lawful counter-witness derived by the repository's declared negation, inversion, or rejection rule.

Agents must not treat any of these as decorative.

## 11. Paths and Filesystem Materialization

Filesystem structure is a witness surface.

It may materialize derived identity, but it does not create identity.

If runtime replay and path naming disagree, replay wins.

## 12. Docs, Comments, and Generated Output

Documentation, comments, and generated files may explain or witness runtime law.

They do not define runtime law.

If code and prose disagree:

1. verify replayable runtime behavior
2. preserve runtime authority
3. update the prose or artifact description
4. do not silently reinterpret runtime behavior to save the wording

## 13. Projection Discipline

Braille, Unicode, Aztec, lattice layouts, JSON, text, diagrams, and path trees are projection layers.

They are useful.

They are not sovereign.

An agent must not confuse projection stability with semantic authority.

## 14. Required Behavior Before Making Claims

Before declaring something canonical, an agent must be able to answer:

1. What typed input trace produced this?
2. What replay law produced this?
3. What base clocks were assumed?
4. Can the artifact be reproduced exactly?
5. Is this canonical, golden, or negative?

If those answers are not available, the claim is not authoritative.

## 15. Change Discipline

When changing code or documentation:

1. State which law is being preserved or revised.
2. State whether the change affects canonical, golden, or negative artifacts.
3. Never silently redefine identity through a path or projection change.
4. Never present an inferred layer as primitive law.

## 16. Agent Failure Modes To Avoid

Agents working here must explicitly avoid:

- paraphrasing drift into fake certainty
- replacing runtime law with narrative summaries
- flattening distinct layers into one ontology
- inventing semantic meaning from filenames alone
- confusing implementation convenience with constitutional law

## 17. Short Form

If an agent remembers only one sentence, it is this:

Typed deterministic replay is sovereign; everything else is witness, projection, or derivative.
