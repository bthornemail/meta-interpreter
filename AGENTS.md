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

## 18. Type Invariants (8-tuple)

An embeddable artifact MUST satisfy these invariants:

1. **Structure completeness** - all required fields present
2. **Boundary conditions** - well-defined input/output edges
3. **Transformation capability** - deterministic state transition
4. **Terminal conditions** - defined halting or continuation states
5. **Control/payload separation** - type distinction preserved
6. **Selector isolation** - choice mechanism isolated from computation
7. **Witness surface** - trace or receipt surface exists
8. **Addressability** - replay can locate and reproduce the artifact

These define what a well-formed artifact IS, not whether it is true.

## 19. Congruence Questions (7 Questions)

The 7 questions test whether an artifact is congruent with system law:

- Q1: Address existence proof (control plane alignment)
- Q2: Closure determinism (replay produces same result)
- Q3: Projection fidelity (projection derives from canonical)
- Q4: Escape scope (proposal bounded by law)
- Q5: Fano path (information preserved through transform)
- Q6: Proposal/receipt discipline (intervention lawful)
- Q7: Branch reconciliation (divergence reconcilable)
- Q8: Openness accountability (differences bounded by contract)

These are NOT structure checks. They test system alignment.

## 20. Promotion Levels (4 Levels)

Artifacts progress through evaluation states:

1. **Proposal** - satisfies 8-tuple minimally, MAY satisfy questions
2. **Claim** - satisfies 8-tuple, SHOULD satisfy questions (partially grounded)
3. **Closure** - MUST satisfy all relevant questions (fully congruent)
4. **Receipt** - closure processed, replay/validation occurred, artifact witnessed

Promotion never changes the artifact—only its evaluated status.

## 21. Normative Force (RFC 2119)

RFC 2119 controls how strongly congruence is enforced:

- **MUST / MUST NOT** - closure-level constraints (required for receipt)
- **SHOULD / SHOULD NOT** - claim-level expectations (advisory at proposal)
- **MAY / MAY NOT** - proposal-level possibilities (exploratory)

## 22. Step Identity

step_identity is the semantic replay identity, derived from the dev-docs.org tree:

```
step_identity := {artifact_role}.{question}.{algorithm}.{status}
                | {chapter_id}.{scene_id}.{semantic_transition_id}.{step}
```

NOT a UUID. Derived from document structure.

Property schema for headings:

```org
:PROPERTIES:
:artifact_role: proposal|claim|closure|receipt
:question: Q1-Q8
:algorithm: Transition|Projection|Proposal|Receipt|Closure
:status: open|closed
:step_identity: derived-from-tree
:maps_to: reference-to-implementation
:constructive_complexity: P|NP|EXPTIME|...
:falsification_complexity: P|NP|EXPTIME|...
:END:
```

Source blocks inherit from parent heading. Use #+NAME for Babel callable, ID/CUSTOM_ID for Org linking.

## 23. TRAMP Execution

TRAMP is projection + transport surface, NOT truth source.

```
dev-docs.org (brain)
→ babel blocks (formalism)
→ tangle/export (artifact emission)
→ TRAMP (transport to execution environment)
→ runtime (replay / validation)
→ receipt (proof)
```

**TRAMP Execution Rule**

- TRAMP MAY execute, tangle, or export artifacts on remote systems
- TRAMP MUST NOT be treated as a source of truth
- All results MUST be validated through replay and receipts
- Remote state ≠ canonical state
- Agents cannot define law, only execute it

Agent tagging pattern:

```org
:AGENT: agent-vps
:ENV: production
:SURFACE: deployment
```

## 24. Replayable Artifact as Binary Proof

An idea is not real until it can be replayed as an artifact.

```
idea → proposal → claim → closure → artifact → receipt
       (structured) (formal) (axiomatic) (embedded) (verified)
```

- **Artifact** - replayable binary embedding of formalism
- **Receipt** - proof that embedding and replay succeed
- **Formalism** - expressible as pure function OR finite axiomatic relation

Questions act as reduction operators transforming ideas into formalisms.

## 25. Lambda Encoding (S-expressions and M-expressions)

S-expressions and M-expressions MAY be used as portable encodings of lambda-form structure.

They SHOULD serve as structural expression surfaces for proposals, claims, closures, and receipts.

They MUST remain reducible to replayable artifact form.

- s-expr = canonical lambda surface
- m-expr = conversational lambda surface
- artifact = replayable proof of embedding

## 26. Receipt Schema

A receipt MUST contain:

```org
:PROPERTIES:
:step_identity: {derived-from-tree}
:artifact_role: receipt
:hash: {sha256|blake3}
:replay_result: {pass|fail}
:timestamp: {deterministic-clock}
:END:
```

Receipts witness execution + hash + replay proof.

## 27. Compile Section Requirements

All compile-relevant sections MUST declare:
- artifact_role
- question
- algorithm
- step_identity
- constructive_complexity
- falsification_complexity

Source blocks MAY be named with #+NAME.
Org IDs MAY be used for linking.
Semantic identity MUST come from step_identity, not from UUIDs.

Promotion MAY proceed:
proposal -> claim -> closure -> receipt

A promotion is valid only if replay remains authoritative and the resulting artifact is receiptable.

## 28. Promotion Links

Promotion edges MUST be declared explicitly, not inferred from naming:

```org
:step_identity: proposals.q1.escape
:derived_from: claims.q1.transition
:promotes_to: closure.q1.branch-reconciliation
```

Receipts MUST declare what they receipt:

```org
:step_identity: receipts.q1.projection
:receipt_for: closure.q1.branch-reconciliation
```

This makes the chain machine-readable and prevents silent assumption of promotion paths.

## 29. Edge Law

A node MAY declare:
- derived_from (backward reference)
- promotes_to (forward intent)
- receipt_for (proof binding)

But promotion MUST follow these rules:

- proposal MUST derive_from claim
- closure MUST derive_from proposal or claim
- receipt MUST reference closure

No node MAY skip closure when producing a receipt.

A valid promotion chain:
```
claim → proposal → closure → receipt
```

Invalid chains (MUST be rejected):
```
proposal → receipt (skips closure)
receipt → proposal (wrong direction)
```

## 30. Execution Substrate

The implementation MUST declare its execution substrate.

Core completion is measured first by conformance to that substrate.

Functional, stress, performance, and speculative behavior are secondary
and MUST NOT redefine the conformance boundary.

### Target Tiers

- **substrate_core**: BusyBox ash + POSIX sh + awk + core POSIX file/process model
- **substrate_extended**: POSIX system interface subset, Python helpers, browser demos
- **substrate_speculative**: Prolog/WordNet, semantic adapters, higher-order proof tooling

### Compliance Model

1. Conformance - MUST pass on declared substrate
2. Functional - SHOULD pass once conformance is met
3. Stress - MAY pass once functional works
4. Performance - MAY pass once stress is stable
5. Speculative - experimental, separate from core

### Short Freeze

The implementation is complete when the system is conformant to the declared
BusyBox/POSIX substrate. Everything beyond that is extension, optimization,
or speculation.

## 31. Typed Scaffolding

Typed scaffolds are acceptable when they are used to define scope and can later
be lowered to the same replayable bitwise law.

No scaffold is final unless removing it changes canonical replay.

### Development Ladder

| Stage | Tool | Purpose |
|-------|------|---------|
| Proof pressure | Coq | Test whether the law can be stated rigorously |
| Scope definition | Haskell | Define real boundaries and executable law |
| Surface language | EDSL/DSL | Shape expression and interfaces |
| Interface boundary | ABI/EABI | Freeze lowering targets |
| Substrate embodiment | C/gawk | Current target (substrate_core) |
| Final kernel | pure bitwise | Intentional lowering when possible |

### Foundational Files

The Haskell files in =research/foundations/= are the typed law-and-scope
scaffold that the current C/gawk framework lowers from:

- AtomicConstitution.hs - constitutional alphabet, quotient test, delta law
- AtomicKernel.hs - pure DSL with named algorithms, no hidden state
- Composition.hs - delta law, replay, phase factorization, header packing
- ClosureRuntime.hs - shaped for ABI/EABI lowering, deterministic scheduling
- Automaton_v2/v3.hs - canonical stream decoupler, point-set lifting
- Matroid_v2/v3.hs - ABI-oriented block design, bounded symbolic families
- Artifact.hs, Tetragrammaton.hs - law/carrier split, simplex resolution
- PortMatroid.ts - same law exported in TypeScript artifact form

### Post-Freeze Scoping

After the core was frozen, the methodology ladder above is no longer needed for discovery.
The new scoping tests are:

1. Can it be a surface?
2. Can it achieve POSIX compliance?

These two questions replace the full methodology ladder as the boundary for new work.
