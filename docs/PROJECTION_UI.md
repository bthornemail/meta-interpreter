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

Projection pages may present downstream claims, receipts, provenance notes, and reconciliation outcomes.
Those displays remain non-authoritative witness surfaces only.

## What The UI Surfaces Are

The browser projection lane currently has three surfaces:

1. Static demo

- file: `demo/browser/projection/ttc_projection_demo.html`
- role: frozen reference projection
- input source: embedded `data-ttc-*`
- purpose: show the projection contract without any stream adapter

2. NDJSON stream demo

- file: `demo/browser/projection/ttc_projection_stream.html`
- role: file/text adapter over the same contract
- input source: pasted or fetched NDJSON
- purpose: prove that runtime NDJSON can feed the same projection surface unchanged

3. Live SSE demo

- file: `demo/browser/projection/ttc_projection_live.html`
- role: primary live canvas surface over the same contract
- input source: SSE events from `demo/browser/servers/ttc_runtime_stream_server.py`
- purpose: present the living browser surface while proving that a live runtime stream can feed the same projection surface unchanged

4. SVG witness export

- source: generated from the normalized projection object
- role: export/share/print witness of the same selected step
- purpose: provide a stable vector projection without introducing a second schema

5. Future A-Frame surface

- status: Phase 2 only
- role: immersive projection consumer of the same normalized projection object
- purpose: offer a 3D witness surface without redefining runtime, structure, or semantics

6. Timed media surface

- file: `demo/browser/projection/ttc_projection_media.html`
- role: secondary timed media witness
- input source: SSE events plus the same selected step consumed by canvas/SVG
- purpose: prove that MSE, Media Session, and capture probes can remain downstream consumers only

These pages are schema consumers, not schema definers.
They may present claim/receipt material, but they do not originate canonical truth from those displays.

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

- file: `demo/browser/projection/ttc_projection_renderer.js`
- exported surface: `renderTtcProjection(stepEl, step)`
- normalized extraction surface: `readTtcProjection(stepEl)`
- svg surface: `renderTtcProjectionSvg(projection)`

Responsibilities:

- optionally write projection-local dataset fields onto the selected step element
- read the frozen `data-ttc-*` contract
- normalize the selected step into a projection-local object
- update projection-local panel text
- render the canvas surface
- render the SVG witness surface
- publish a projection-local snapshot for automated equivalence checking

Non-responsibilities:

- runtime stepping
- step selection law
- incidence derivation
- grammar interpretation
- address semantics
- transport semantics
- artifact identity

## Timed Media Adapter

Timed media adapter:

- file: `demo/browser/projection/ttc_media_adapter.js`

Responsibilities:

- choose a playback profile using MediaCapabilities and MSE support
- build a timed media surface from the same selected step stream already used by canvas
- install basic Media Session metadata and play/pause handlers
- probe supported constraints and track settings for display-only capture inspection

Non-responsibilities:

- runtime stepping
- step selection law
- incidence derivation
- schema definition
- capture-to-runtime authority

Rules:

```text
MediaCapabilities selects projection/playback suitability, not canonical computation.
MediaSource is a timed media projection/transport adapter, not a schema or runtime authority.
Media Session is a platform control surface only.
Capture constraints may tune device-facing behavior, but they must not influence runtime law.
```

## What Was Refactored

Originally, the demo pages each carried their own copy of canvas rendering and step-application logic.

That duplication was removed by extracting the shared renderer into:

- `demo/browser/projection/ttc_projection_renderer.js`

The pages are now thin adapters:

- static page: chooses which embedded step card is active
- stream page: parses NDJSON and applies one step at a time
- live page: receives SSE events and applies one step at a time

This keeps the architecture clean:

```text
runtime NDJSON -> adapter -> data-ttc-* -> normalized projection -> canvas/svg
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

- `demo/browser/projection/ttc_projection_stream.html`
- `demo/browser/projection/ttc_projection_live.html`

It does not change runtime law. It only preserves runtime-emitted text correctly downstream.

## Deterministic Projection Output

For a given step, the UI renders:

- normalized metadata fields
- deterministic canvas output
- deterministic SVG witness output

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
SVG output is compared as deterministic markup containing the same digest and projection content.

## Continuous Projection Check

Projection equivalence is continuously enforced by:

- target: `make projection-check`
- script: `scripts/projection/validate_projection_render.py`

That check loads:

- the static demo
- the NDJSON demo fed from `demo/samples/ttc_runtime_sample.ndjson`
- the live demo fed through SSE

It asserts one downstream invariant:

```text
same step -> same metadata -> same canvas
```

And it additionally checks that SVG generated from the same selected step:

- preserves the digest as text
- stays deterministic across projection surfaces

Important limit:

```text
projection-check validates projection equivalence only
it does not validate runtime law
```

Claims, receipts, provenance overlays, and reconciliation summaries shown in the UI are presentation surfaces only.
They must not mutate runtime law or redefine canonical replay identity.

Timed media and capture probe behavior is validated separately by:

- target: `make media-check`
- script: `scripts/projection/validate_media_render.py`

That check asserts:

- the media page preserves the same selected step metadata as the static projection surface
- timed media profile selection is deterministic on the same browser
- Media Session installs basic metadata/play-pause control without changing runtime-derived fields
- supported constraints can be listed without affecting runtime output

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
6. Canvas is the primary live surface.
7. SVG is a downstream witness/export surface from the same contract.
8. A-Frame, when used, must consume the same normalized projection object and must not invent a new schema.

If a change affects equivalence, update the projection check and prove the new behavior intentionally.
