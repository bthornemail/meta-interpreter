Typed deterministic replay is sovereign; peers exchange claims and receipts, not truth itself.

# TTC Propagation, Claims, and Federation v1

## 1. Authority and Non-Authority

Freeze sentence:

```text
Peers exchange claims and receipts, not truth itself;
truth remains canonical replay.
```

Authority order remains:

```text
bytes
-> replayable deterministic runtime behavior
-> explicit type law
-> declared base clock law
-> canonical artifact emission
-> golden artifact comparison
-> negative artifact derivation
-> projection surfaces
-> human explanation
```

Rules:

```text
Federation does not create truth.
Claims do not create truth.
Receipts do not create truth.
Convergence does not create truth.
Canonical replay remains the only source of truth.
```

## 2. Canonical Flow and Downstream Extension

The canonical flow remains:

```text
bytes
-> runtime event
-> step_digest
-> incidence
-> grammar
-> address
-> witness
-> matrix
-> projection
```

The downstream extension frozen here is:

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

This extension wraps the existing system and does not replace it.

Primary material class system:

```text
xx/xX/Xx/XX
```

Frozen class table:

```text
xx = affine / affine
xX = affine / projective
Xx = projective / affine
XX = projective / projective
```

Rules:

```text
xx/xX/Xx/XX is the primary material class system for shared artifact and block surfaces
claim_artifact, proposal_artifact, closure_artifact, and receipt_artifact are downstream symbolic-role views over existing class surfaces, not a replacement taxonomy
```

Control-plane multiplex may separate:

- artifact class
- workflow scope
- record boundaries
- field boundaries

It does not create truth.

## 3. Definitions

### propagation

```text
propagation := lawful forward derivation from canonical bytes through replay into derived surfaces
```

Includes:

- runtime emission
- step-digest-conditioned incidence
- grammar interpretation
- address derivation
- witness construction
- matrix arrangement
- projection materialization
- artifact packaging
- transport carriage

Symbolic role is downstream of the primary xx/xX/Xx/XX material class system.

### translation

```text
translation := a change of carrier, witness surface, transport form, or presentation form that preserves canonical identity
```

Rules:

```text
translation may change carrier
translation may change witness surface
translation may change transport form
translation may change presentation form
translation must not change canonical replay identity without explicit revision law
```

Canonical embedding and scannable variants are translation forms of artifacts, not artifact types.

### ui_frame_resolution

```text
ui_frame_resolution := downstream resolved frame object combining artifact class, workflow mode, step identity, and frame scope for projection consumers
```

Rules:

```text
UI framing is resolved from artifact class and canonical step identity, not from projection form.
The UI workflow is determined by the resolved artifact class.
Step resolution precedes render comparison.
Projection witnesses the resolved frame; it does not define it.
```

### carrier_resolution

```text
carrier_resolution := downstream witness of material class, scope rank, and closure form over typed carriers
```

Rules:

```text
carrier_resolution is derived from replay-visible event, grammar, and address tuples
carrier_resolution witnesses rank and closure; it does not create truth
material_class remains the portable xx/xX/Xx/XX witness string
carrier_resolution is downstream of address reconstruction
```

### affine

```text
affine := locally instantiated address side
```

### projective

```text
projective := projected or shared address side
```

### participant

```text
participant := an actor capable of emitting, receiving, verifying, rejecting, or reconciling claims and receipts
```

### peer

```text
peer := a participant in declared federated relation to another participant
```

### role

```text
role := a declared responsibility and authority boundary under which a participant may act
```

### contract

```text
contract := the declared authority boundary describing what a role may emit, verify, reject, accept, or reconcile
```

### claim

```text
claim := a typed assertion about a declared layer or relation between layers
```

### claim_artifact

```text
claim_artifact := point artifact materializing an asserted point in canonical or derived state space
```

### receipt

```text
receipt := a deterministic witness that a claim, validation event, transfer event, or reconciliation step occurred
```

### proposal_artifact

```text
proposal_artifact := path artifact materializing a candidate path or transformation between points
```

### closure_artifact

```text
closure_artifact := constraint artifact materializing the admissible constraint surface over points and paths
```

Contract rule:

```text
contract := declared closure law
closure_artifact := canonical artifact carrying that law
```

### receipt_artifact

```text
receipt_artifact := event witness artifact materializing an observed event over claims, proposals, closures, or their validation and transfer
```

### provenance

```text
provenance := the replayable derivation and custody chain for a claim, receipt, witness, transport event, or artifact
```

### convergence point

```text
convergence point := a participant, site, process, or boundary where multiple claims or receipts are compared under contract
```

### federation

```text
federation := the exchange discipline among participants and peers for claims and receipts under declared contracts
```

## 4. Propagation vs Back-Propagation

Propagation is lawful forward derivation:

```text
bytes
-> replay
-> step_digest
-> incidence
-> grammar
-> address
-> witness
-> matrix
-> projection
-> point | path | constraint | event witness artifacts
```

Back-propagation is not runtime mutation.

```text
back-propagation := downstream evidence flowing upward as challenge, confirmation, refusal, acceptance, deferment, or fork against replayable evidence
```

Allowed forms:

- validation
- contradiction
- counter-witness
- refusal
- rejection
- acceptance
- deferment
- fork proposal

Forbidden forms:

- mutating runtime truth from projection state
- mutating runtime truth from prose
- mutating runtime truth from carrier success
- mutating runtime truth from social agreement alone

## 4A. Address-First Reconstruction

First-principles explanation begins with address existence and address decomposition.

```text
either the address exists
or it does not
```

If the address exists, the lawful order is:

```text
replay
-> class
-> point
-> lane
-> leaf
-> address bits / address word
-> downstream witness surfaces
```

Rules:

```text
x/X expresses closure-sided witness inside address construction
xx/xX/Xx/XX expresses closure composition
what follows xx/xX/Xx/XX is address decomposition, not runtime classification
projective must not be treated as local replay substance
affine must not be treated as a mere shareable carrier surface
```

## 5. Translation Discipline

A translation is lawful only when:

1. canonical identity is preserved
2. declared surface change is explicit
3. contract allows the translation
4. provenance remains reconstructible
5. validation receipts can witness the translation if required

Examples:

```text
witness slots -> ASCII witness
matrix symbol -> seal page
runtime NDJSON -> browser dataset fields
artifact bytes -> base64 witness view
```

Non-example:

```text
projection-local edits treated as canonical replay changes
```

## 6. Claims and Receipts

A claim should minimally declare:

1. layer
2. subject
3. claimant role
4. contract context
5. evidence references
6. reproducibility or verification basis

Recommended claim classes:

- `existence_claim`
- `identity_claim`
- `derivation_claim`
- `translation_claim`
- `validation_claim`
- `transfer_claim`
- `reconciliation_claim`
- `fork_claim`

Frozen symbolic artifact classes:

- `claim_artifact` = point artifact
- `proposal_artifact` = path artifact
- `closure_artifact` = constraint artifact
- `receipt_artifact` = event witness artifact

Receipt rule:

```text
receipt witnesses occurrence and reproducibility
receipt does not replace the thing witnessed
```

Recommended receipt classes:

- `emission_receipt`
- `validation_receipt`
- `transfer_receipt`
- `translation_receipt`
- `comparison_receipt`
- `reconciliation_receipt`
- `fork_receipt`

## 7. Provenance

Minimal provenance chain:

```text
source identity
-> derivation context
-> emitting role
-> transport or carrier history
-> validation receipts
-> reconciliation outcomes
```

Rules:

```text
missing provenance weakens trust but does not rewrite replay
broken provenance may justify rejection or deferment
fabricated provenance is a contradiction subject to rejection
```

## 8. Federation Roles and Contracts

Federated roles should declare at least:

- authority boundary
- permitted layers
- emission rights
- verification obligations
- rejection rights
- receipt obligations
- escalation conditions

Possible role families:

- canonical emitter
- witness producer
- validator
- transport bridge
- reconciler
- publisher
- observer

Narrative witness roles remain advisory unless separately elevated by explicit law.

## 9. Convergence Points

A convergence point is where federated comparison happens.

Process:

```text
collect
-> verify
-> compare
-> classify
-> emit outcome receipt
```

Resolution order:

1. canonical replay evidence
2. explicit type and contract law
3. canonical artifact identity
4. reproducible receipts
5. downstream witness or projection evidence
6. human explanation

## 10. Reconciliation Outcomes

```text
reconciliation := deterministic comparison of claims and receipts against replay and declared contract
```

Outcomes:

- `accept`
- `reject`
- `defer`
- `fork`

Rules:

```text
If claim and replay diverge, replay wins.
If claim and contract diverge, the claim fails under that contract.
If two claims conflict and both cannot be sustained under the same replay and contract context, at least one must be rejected or a lawful fork must be declared.
```

## 11. Relation to Existing Repository Law

This document is a downstream extension.

It does not change:

- runtime stepping law
- step_digest law
- incidence law
- grammar law
- address law
- witness law
- matrix law
- projection law
- artifact identity law

It defines how participants behave around those layers.

## 12. Canonical Sentences and Non-Goals

Canonical sentences:

```text
Propagation is lawful forward derivation from canonical bytes through replay into derived surfaces.
Translation changes carrier, witness surface, transport form, or presentation form without changing canonical identity.
A claim is a typed assertion about a declared layer or relation between layers.
A claim artifact materializes an asserted point in canonical or derived state space.
A proposal artifact materializes a candidate path or transformation between points.
A closure artifact materializes the admissible constraint surface over points and paths.
A receipt artifact materializes an observed event over those objects.
A receipt is a deterministic witness that a claim, validation, transfer, or reconciliation step occurred.
Provenance is the replayable derivation and custody chain for claims, receipts, and artifacts.
Reconciliation is deterministic comparison of claims and receipts against replay and declared contract.
Federation is the exchange discipline among participants and peers under declared contracts.
Peers exchange claims and receipts, not truth itself; truth remains canonical replay.
Artifacts are classified by symbolic role, not by encoding.
Canonical embedding and scannable variants are translation forms of artifacts, not artifact types.
Claims may be compared.
Proposals may be evaluated.
Closures may be applied.
Receipts may be verified.
```

Non-goals:

- promote social consensus to truth
- define a network protocol
- define cryptographic signatures
- redefine transport semantics
- redefine canonical artifact identity
- treat browser state as authoritative
- collapse witness, artifact, transport, and projection into one layer
