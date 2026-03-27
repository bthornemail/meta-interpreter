#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUT_ROOT="artifacts"
DEMO_DIR="$(mktemp -d)"
IN_FIFO="$DEMO_DIR/in.fifo"
SAMPLE_BIN="$DEMO_DIR/sample.bin"

cleanup() {
  rm -f "$IN_FIFO" "$SAMPLE_BIN"
  rmdir "$DEMO_DIR" 2>/dev/null || true
}
trap cleanup EXIT

mkfifo "$IN_FIFO"

# Simple deterministic payload for the demo.
printf 'hyperverse-ttc-factoradic-5040\n' > "$SAMPLE_BIN"

# Materializer consumes binary byte stream through FIFO.
./scripts/materialize_factoradic_5040.sh --binary --out-root "$OUT_ROOT" < "$IN_FIFO" &
consumer_pid=$!

cat "$SAMPLE_BIN" > "$IN_FIFO"
wait "$consumer_pid"

echo "factoradic fifo demo complete"
echo "  sample: $SAMPLE_BIN"
echo "  out:    $OUT_ROOT/{xx|xX|Xx|XX}/..."

if command -v nc >/dev/null 2>&1; then
  echo "nc available: you can stream similarly with:"
  echo "  nc -l 5040 | ./scripts/materialize_factoradic_5040.sh --binary"
fi
