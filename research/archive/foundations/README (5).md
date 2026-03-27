# Atomic Kernel — Aztec Renderer Package

Two HTML files. No build step. Open in any browser.

---

## Files

### `index.html` — Full renderer (real scannable codes)

Produces actual Aztec barcodes that phone cameras can read, plus the
coordinate overlay showing the canonical (channel, lane) slot mapping.

**Requires network** — loads `bwip-js` from jsDelivr CDN for the
Reed-Solomon encoding that makes codes scannable.

Features:
- Real Aztec byte-mode output via bwip-js (correct RS over GF(2^8))
- Adjustable ECC level (23% / 36% / 50% / 66%)
- Adjustable module pixel size (4–20px)
- Live pipeline display showing byte counts at each stage
- FNV-1a artifact hash
- PNG download (pixel-exact, no anti-aliasing)
- SVG overlay download
- Hover tooltips on every module

**To test with a phone:** open in browser, click Render, point camera at
the top half. Any standard QR/barcode app reads Aztec codes. iOS Camera
app, Google Lens, and ZXing-based apps all work.

### `overlay.html` — Standalone SVG overlay (no network required)

Pure coordinate geometry visualiser. Works fully offline.

Features:
- 27×27 grid with all 60 canonical (channel, lane) slots marked
- Bull's-eye, mode ring, null lanes, ECC regions all distinct
- Adjustable cell size (8–28px)
- Label mode: lane numbers, coord identifiers, or none
- Per-channel highlight (all / US / RS / GS / FS)
- Ring boundary guides and crosshairs
- Hover tooltips with (x, y, r, channel, lane) for every cell
- SVG download

---

## Architecture

Both files implement the same JS port of the Haskell pipeline:

```
Artifact
→ canonicalBits        text → UTF-8 bytes
→ A13 stream           ESC-depth self-delimiting encoding
→ coord field          mixed-radix projection
→ lattice placement    60 canonical (channel, lane) slots
```

The scannable Aztec in `index.html` is produced by bwip-js operating
directly on the input text in byte mode. The coordinate overlay shows
where the kernel's canonical slots sit within the 27×27 grid geometry,
independent of the ECC layer.

These are two views of the same artifact:
- bwip-js handles RS ECC so the code is physically scannable
- The overlay shows the kernel's coordinate semantics on the same grid

---

## Why bwip-js for the scannable code

Aztec Reed-Solomon ECC uses GF(2^8) polynomials with specific generator
coefficients from ISO/IEC 24778. Implementing this correctly from scratch
is ~300 lines of finite field arithmetic that is easy to get subtly wrong.
bwip-js (Barry Zubel's barcode library) implements the full Aztec spec
including byte mode, the mode message, the reference grid, and RS — and
has been validated against real scanners for years.

The kernel's A13/A2/A15 pipeline owns the coordinate semantics.
bwip-js owns the physical scannability.
Neither trespasses on the other's layer.

---

## Channel / Ring mapping (AZTEC_COORD_TABLE §3)

| Channel | Plane | Ring r | Role               |
|---------|-------|--------|--------------------|
| 0       | US    | 4, 5   | unit (innermost)   |
| 1       | RS    | 6, 7   | record             |
| 2       | GS    | 8, 9   | group              |
| 3       | FS    | 10, 11 | file (outermost)   |

Each channel has 15 non-null lanes (1–15) at fixed positions.
Lane 0 is the null lane (zero vector of GF(2)^4).
Total canonical data slots: 60.
