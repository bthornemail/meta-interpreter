# TTC Projection UI

Typed deterministic replay is sovereign. This document explains the browser UI surfaces as downstream projection consumers only.

## Purpose

This document exists so contributors can understand:

- what the browser demos are
- what contract they consume
- what was refactored
- why the UI must remain downstream of runtime law

It does not define runtime law, schema authority, or transport semantics.

## Core Rule

```text
The UI is a projection consumer only.
It may display or update projection-local DOM state, but it must not define schema, runtime logic, or transport semantics.
```

Companion rule:

```text
data-ttc-* is derived projection metadata only.
It must never drive runtime or canonical decisions.
```

## What The UI Surfaces Are

The browser projection lane currently has three surfaces:

1. Static demo

- file: `demo/ttc_projection_demo.html`
- role: frozen reference projection
- input source: embedded `data-ttc-*`
- purpose: show the projection contract without any stream adapter

2. NDJSON stream demo

- file: `demo/ttc_projection_stream.html`
- role: file/text adapter over the same contract
- input source: pasted or fetched NDJSON
- purpose: prove that runtime NDJSON can feed the same projection surface unchanged

3. Live SSE demo

- file: `demo/ttc_projection_live.html`
- role: live transport adapter over the same contract
- input source: SSE events from `demo/ttc_runtime_stream_server.py`
- purpose: prove that a live runtime stream can feed the same projection surface unchanged

These pages are schema consumers, not schema definers.

## Frozen DOM Contract

The UI contract is the `data-ttc-*` projection metadata carried by the step element.

Frozen fields:

- `data-ttc-surface`
- `data-ttc-step`
- `data-ttc-digest`
- `data-ttc-triplet`
- `data-ttc-order`
- `data-ttc-seq56`
- `data-ttc-incidence-layer`
- `data-ttc-incidence-coords`
- `data-ttc-incidence-coeff`

These are derived from canonical runtime output. They are not canonical themselves.

## Shared Renderer

Shared renderer:

- file: `demo/ttc_projection_renderer.js`
- exported surface: `renderTtcProjection(stepEl, step)`

Responsibilities:

- optionally write projection-local dataset fields onto the selected step element
- read the frozen `data-ttc-*` contract
- update projection-local panel text
- render the canvas surface
- publish a projection-local snapshot for automated equivalence checking

Non-responsibilities:

- runtime stepping
- step selection law
- incidence derivation
- grammar interpretation
- address semantics
- transport semantics
- artifact identity

## What Was Refactored

Originally, the demo pages each carried their own copy of canvas rendering and step-application logic.

That duplication was removed by extracting the shared renderer into:

- `demo/ttc_projection_renderer.js`

The pages are now thin adapters:

- static page: chooses which embedded step card is active
- stream page: parses NDJSON and applies one step at a time
- live page: receives SSE events and applies one step at a time

This keeps the architecture clean:

```text
runtime NDJSON -> adapter -> data-ttc-* -> renderer -> canvas
```

## Why The Precision Fix Matters

Large `step_digest` values must be preserved exactly in projection.

Browser JSON parsing can coerce large integers into unsafe floating-point numbers. That caused projection drift for `step_digest` until the stream and live adapters were corrected to preserve the emitted digest as text.

This is a hard correctness boundary in the projection layer:

```text
projection must preserve runtime-emitted identifiers exactly
even when the browser would otherwise round them
```

That fix lives in:

- `demo/ttc_projection_stream.html`
- `demo/ttc_projection_live.html`

It does not change runtime law. It only preserves runtime-emitted text correctly downstream.

## Deterministic Projection Output

For a given step, the UI renders:

- normalized metadata fields
- deterministic canvas output

Normalized fields:

- step
- digest
- triplet
- order
- seq56
- incidence layer
- incidence coords
- incidence coeff

Canvas output is compared via a stable snapshot (`toDataURL()`).

## Continuous Projection Check

Projection equivalence is continuously enforced by:

- target: `make projection-check`
- script: `scripts/validate_projection_render.py`

That check loads:

- the static demo
- the NDJSON demo fed from `demo/ttc_runtime_sample.ndjson`
- the live demo fed through SSE

It asserts one downstream invariant:

```text
same step -> same metadata -> same canvas
```

Important limit:

```text
projection-check validates projection equivalence only
it does not validate runtime law
```

## Current Invariant

The current UI/projection invariant is:

```text
For any canonical runtime step,
all projection surfaces must render identical metadata
and identical visual output.
```

This has been verified across:

- embedded static projection
- file-based NDJSON projection
- live SSE-fed projection

## Change Discipline For UI Work

If you change the browser projection layer, preserve these boundaries:

1. Do not change the `data-ttc-*` schema casually.
2. Do not let renderer code define runtime or transport meaning.
3. Do not let adapters invent new field names.
4. Do not compute canonical state in the browser.
5. Do not treat projection stability as runtime authority.

If a change affects equivalence, update the projection check and prove the new behavior intentionally.
