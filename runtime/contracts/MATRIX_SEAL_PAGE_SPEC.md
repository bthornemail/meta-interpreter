# Matrix Seal Page Spec

Typed deterministic replay is sovereign. This document specifies a generated matrix seal page as a downstream witness surface, not as canonical authority.

## Core Rule

```text
This page is a generated seal surface.
Canonical authority remains the embedded artifact bytes and verified identity, not the page markup or rendering.
```

Companion rule:

```text
The matrix seal page is generated from canonical bytes and artifact identity.
It does not define runtime law, schema authority, or transport semantics.
```

## Purpose

The matrix seal page is intended as a single generated deliverable that can carry:

- artifact identity
- canonical payload views
- the current TTC matrix seal surface
- replay preview data
- a projection viewer based on the frozen browser contract

It is a publishable witness surface for the project state at generation time.

## Naming

Use:

- `matrix_seal_page`
- `artifact_seal_page`

Do not use:

- `aztec_page`

Reason:

```text
The current TTC matrix transport is a TTC-specific reversible 27x27 transport grid.
It is not standards Aztec framing with mode message, Reed-Solomon ECC, or scanner interoperability.
```

The name `Aztec` remains reserved for a future standards-compliant barcode layer.

## Data Model

Freeze the seal-page model as:

```text
canonical bytes
-> artifact identity
-> TTC matrix seal
-> generated HTML seal page
```

The generated page is downstream of canonical bytes and artifact identity.

## Authority Boundary

The generated page may embed or display:

- canonical payload views
- artifact hash
- claims about identity or derivation
- receipts about generation or validation
- provenance notes
- runtime NDJSON samples
- projection metadata
- TTC matrix symbols

It does not become canonical by containing those things.

## Required Sections

The generated page should contain the following sections.

### 1. Identity

Required fields:

- artifact hash
- rule version
- seal format version

Optional fields:

- provenance note
- generator version
- build note
- generation receipt note

Purpose:

- identify the sealed artifact deterministically
- state which law version and seal format were used

### 2. Canonical Payload

Required fields:

- payload bytes as hex
- payload length

Optional fields:

- payload bytes as base64
- content-type hint

Purpose:

- expose the canonical payload in a readable and copyable witness form

### 3. Seal Surface

Required fields:

- current TTC matrix symbol or symbols

Optional fields:

- multiple matrix surfaces for different views
- reserved placeholder for future standards Aztec barcode framing

Purpose:

- provide the current honest transport-ready seal surface

Rule:

```text
TTC matrix is the current honest seal surface.
Standards Aztec remains reserved for future implementation.
```

### 4. Replay Preview

Required fields:

- sample runtime NDJSON
- sample step metadata

Suggested contents:

- step index
- step_digest
- triplet
- order
- seq56
- incidence layer
- incidence coordinates
- incidence coefficient

Purpose:

- let a reader inspect a replay witness without treating the page as runtime authority

### 5. Projection Viewer

Required fields:

- frozen `data-ttc-*` projection metadata
- shared renderer canvas output

Contract fields:

- `data-ttc-surface`
- `data-ttc-step`
- `data-ttc-digest`
- `data-ttc-triplet`
- `data-ttc-order`
- `data-ttc-seq56`
- `data-ttc-incidence-layer`
- `data-ttc-incidence-coords`
- `data-ttc-incidence-coeff`

Purpose:

- reuse the existing browser projection contract and renderer
- show that the seal page can contain a deterministic viewer without redefining projection law

Rule:

```text
The browser viewer remains projection-only.
It must not compute runtime state or redefine schema.
```

### 6. Footer

Required statement:

```text
This page is a generated seal surface.
Canonical authority remains the embedded artifact bytes and verified identity, not the page markup or rendering.
```

Optional additions:

- generation note
- repository reference
- projection-check note
- validation receipt note

Rules:

```text
claims and receipts displayed on the seal page remain downstream witnesses
provenance notes may explain derivation or custody
the page itself does not become authoritative by containing those claims or receipts
```

## Honest Scope

The matrix seal page may be built now because the current TTC matrix transport exists and is governed honestly.

It must not misrepresent the current transport as standards Aztec.

If a future standards-compliant Aztec layer lands, the seal page may gain a second seal pane or alternate encoding section. That should be treated as a versioned seal-law expansion, not as a rename of the current TTC matrix surface.

## Recommended Page Layout

A recommended top-level layout is:

1. Header
- project title
- artifact hash
- rule version
- seal format version

2. Seal section
- TTC matrix seal
- reserved future Aztec placeholder

3. Canonical section
- payload hex
- optional base64
- length and identity summary

4. Replay section
- runtime NDJSON sample
- step metadata sample

5. Projection section
- shared renderer canvas
- frozen `data-ttc-*` metadata

6. Footer
- explicit non-authority statement

## Change Discipline

If contributors implement this page:

1. Keep artifact identity authoritative, not the HTML file itself.
2. Keep the page generated, not hand-authored as canonical content.
3. Keep the browser viewer downstream of the frozen projection contract.
4. Keep TTC matrix naming honest until standards Aztec exists.
5. Version any change that alters embedded sections or seal semantics.

## Non-Goals

This spec does not:

- redefine runtime law
- redefine artifact identity law
- promote HTML to canonical authority
- claim standards Aztec support
- replace the existing projection demo surfaces

## Next Implementation Step

The next implementation artifact after this spec is:

```text
generator
-> self-contained matrix_seal_page
```

That generator should consume canonical bytes and artifact identity, then emit one self-contained HTML witness surface.
