# TTC Block Definitions v1

Status: normative for block mapping in this repo.

Sources:
- `blocks/U+280x-U+283x`
- `blocks/U+284x-U+28Fx`

## 1. Purpose

Define the two Braille-derived fixed-point scales used by runtime clocking and control-plane header partitioning.

## 2. Block Sets

### Block A: `U+280x`..`U+283x`

- Range: `U+2800`..`U+283F`
- Size: `0x40 = 64` code points
- Semantic: 6-dot closure set (end of 6-dot patterns)
- Runtime role: work/law payload space

### Block B: `U+284x`..`U+28Fx`

- Range: `U+2840`..`U+28FF`
- Size: `0xC0 = 192` code points
- Semantic: extended/control-capable set (adds 7/8-dot region)
- Runtime role: control-plane header and extensions

## 3. Fixed-Point Scales

These are the two block scales:

- `FP_SCALE_A = 64`  (for Block A)
- `FP_SCALE_B = 192` (for Block B)

Recommended runtime representation:

- store both as decimal strings in serialized objects
- use integer arithmetic only

Example:

```json
{
  "block_scale_a": "64",
  "block_scale_b": "192"
}
```

## 4. Header Partition Rule

Given a Braille code-point offset byte `b` (`0x00..0xFF`):

- if `0x00 <= b <= 0x3F`, classify as `BLOCK_A`
- if `0x40 <= b <= 0xFF`, classify as `BLOCK_B`

Equivalent test:

- `BLOCK_A` iff `b < FP_SCALE_A`
- `BLOCK_B` iff `b >= FP_SCALE_A`

This gives a deterministic low/high partition aligned with the two block files.

## 5. Clock Binding

Use the block scales as fixed-point bases while keeping existing time clocks explicit:

- `CLOCK_T7 = 7` (Fano line period)
- `CLOCK_T240 = 240` (address-space period)

Binding policy:

- Block A (`64`) is the default payload scale for T7-driven work lanes.
- Block B (`192`) is the control/header scale for T240-driven addressing and extension lanes.

## 6. Canonical Serialization

When emitting block metadata in NDJSON/JSON:

- required keys (ordered): `kind`, `block_set`, `range_start`, `range_end`, `scale`
- values as strings

Example object:

```json
{
  "kind": "ttc.block.scale.v1",
  "block_set": "A",
  "range_start": "U+2800",
  "range_end": "U+283F",
  "scale": "64"
}
```

And for set B:

```json
{
  "kind": "ttc.block.scale.v1",
  "block_set": "B",
  "range_start": "U+2840",
  "range_end": "U+28FF",
  "scale": "192"
}
```

## 7. Validation Rules

A block definition is valid iff:

1. Range A size is exactly `64`.
2. Range B size is exactly `192`.
3. `A ∩ B = ∅` and `A ∪ B = U+2800..U+28FF`.
4. Header partition classification uses the rule in section 4.

## 8. Notes

- This file intentionally defines only the two scale blocks requested.
- Other Unicode block inventories are research material and are not normative here.
