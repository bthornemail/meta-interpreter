# Runtime

This directory is the **only authoritative layer** in the system.

## Structure

```
runtime/
  kernel/      # Implementation of runtime law (C, awk sources)
  contracts/   # Ontology, lexicon, and surface rules (normative)
  blocks/      # Canonical registries
```

## Definitions

**runtime**:
- Defines canonical state evolution
- Produces step_digest
- Determines replay
- The only authoritative layer

**kernel**:
- Implementation of runtime law
- Executable realization (C, awk, etc.)
- The physical embodiment of runtime authority

**contracts**:
- Define ontology, lexicon, and surface rules
- Normative specifications
- Examples: LEXICON.md, ONTOLOGY.md, SURFACES.md

**blocks**:
- Canonical registries
- Artifact identity surfaces

## Authority

All other directories in this repo are downstream or support:

- `substrate/` - execution support (BusyBox, WordNet)
- `system-image/` - deployment manifests
- `surfaces/` - projections (browser, narrative)
- `artifacts/` - generated outputs
- `scripts/` - operational tooling

## Invariant

Nothing outside `runtime/` may:
- Define canonical state
- Produce authoritative step_digest
- Mutate replay law

The runtime is the kernel law; everything else is a surface.
