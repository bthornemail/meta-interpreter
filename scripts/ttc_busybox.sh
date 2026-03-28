#!/bin/sh
set -eu

# BusyBox-first canonical bitwise triangulation runner.
# Layers:
#   replay_seq     = (tick,state)
#   incidence_seq  = (winner,class,point,lane)
#   config_seq     = (leaf,address_bits)

BINARY_MODE=0
WRITE_MODE=1
OUT_ROOT="artifacts"
STATE=29   # GS anchor (0x1d)
TICK=0
PREV_PATH="artifacts/xx/p0/0/0"

usage() {
  cat <<'USAGE'
Usage:
  echo "120 88 95" | scripts/ttc_busybox.sh
  cat payload.bin | scripts/ttc_busybox.sh --binary
  echo "120 88 95" | scripts/ttc_busybox.sh --out-root artifacts
  echo "120 88 95" | scripts/ttc_busybox.sh --no-write

Output:
  canonical per-tick lines containing replay/incidence/config sequences
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --binary) BINARY_MODE=1; shift ;;
    --out-root) OUT_ROOT="$2"; shift 2 ;;
    --no-write) WRITE_MODE=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

PREV_PATH="${OUT_ROOT}/xx/p0/0/0"

. "$(
  cd "$(dirname "$0")" && pwd
)/leaf_contract.sh"

bitstr() {
  n="$1"
  width="$2"
  out=""
  i=$((width - 1))
  while [ "$i" -ge 0 ]; do
    bit=$(((n >> i) & 1))
    out="${out}${bit}"
    i=$((i - 1))
  done
  printf '%s' "$out"
}

class_name() {
  case "$1" in
    0) printf 'xx' ;;
    1) printf 'xX' ;;
    2) printf 'Xx' ;;
    3) printf 'XX' ;;
    *) printf 'xx' ;;
  esac
}

fano_winner() {
  basis7="$1"
  chiral="$2"

  # canonical 7 lines: {0,1,3} {0,2,5} {0,4,6} {1,2,4} {1,5,6} {2,3,6} {3,4,5}
  case "$basis7" in
    0) p0=0; p2=3 ;;
    1) p0=0; p2=5 ;;
    2) p0=0; p2=6 ;;
    3) p0=1; p2=4 ;;
    4) p0=1; p2=6 ;;
    5) p0=2; p2=6 ;;
    6) p0=3; p2=5 ;;
    *) p0=0; p2=3 ;;
  esac

  if [ "$chiral" -eq 1 ]; then
    printf '%s' "$p2"
  else
    printf '%s' "$p0"
  fi
}

process_byte() {
  input="$1"

  basis7=$((TICK % 7))
  basis8=$((TICK & 7))

  if [ "$input" -eq 0 ]; then
    STATE=0
  else
    law=$(((STATE ^ ((input << 1) & 255)) & 3))
    proj=$(((((STATE << 1) | (STATE >> 7)) ^ input ^ basis7 ^ (basis8 << 2)) & 12))
    STATE=$((law | proj))
    if [ $((input & 128)) -ne 0 ]; then
      STATE=$((STATE | 128))
    fi
  fi

  chiral=$(((TICK / 7) % 2))
  winner=$(fano_winner "$basis7" "$chiral")

  c0=$(((input >> 5) & 1))
  c1=$((TICK & 1))
  class_idx=$(((c1 << 1) | c0))
  class=$(class_name "$class_idx")

  point_idx=$((winner % 3))
  point="p${point_idx}"

  lane=$((((winner << 2) | (input >> 4)) & 15))
  leaf=$((input & 15))

  class_bits=$(bitstr "$class_idx" 2)
  point_bits=$(bitstr "$point_idx" 2)
  lane_bits=$(bitstr "$lane" 4)
  leaf_bits=$(bitstr "$leaf" 4)
  address_bits="${class_bits} ${point_bits} ${lane_bits} ${leaf_bits}"

  lane_hex=$(printf '%x' "$lane")
  leaf_hex=$(printf '%x' "$leaf")
  path="${OUT_ROOT}/${class}/${point}/${lane_hex}/${leaf_hex}"

  replay_seq="${TICK},${STATE}"
  incidence_seq="${winner},${class},${point},${lane}"
  config_seq="${leaf},${address_bits}"

  if [ "$WRITE_MODE" -eq 1 ]; then
    mkdir -p "$path"
    printf 'tick=%d input=0x%02X state=0x%02X basis7=%d basis8=%d winner=%d class=%s point=%s lane=%d leaf=%d replay_seq=%s incidence_seq=%s config_seq=%s address_bits="%s" parent=%s path=%s\n' \
      "$TICK" "$input" "$STATE" "$basis7" "$basis8" "$winner" "$class" "$point" "$lane" "$leaf" \
      "$replay_seq" "$incidence_seq" "$config_seq" "$address_bits" "$PREV_PATH" "$path" >> "$path/trace.log"
    cat > "$path/meta.json" <<EOF
{"schema":"ttc.busybox.addr.v1","tick":$TICK,"input":$input,"state":$STATE,"basis7":$basis7,"basis8":$basis8,"winner":$winner,"class":"$class","class_bits":$class_idx,"point":"$point","point_index":$point_idx,"lane":"$lane_hex","lane_value":$lane,"leaf":"$leaf_hex","leaf_value":$leaf,"address_bits":"$address_bits","parent":"$PREV_PATH","path":"$path"}
EOF
    ttc_write_leaf_contract "$path" "ttc.busybox.addr.v1" "$class" "$point" "$lane_hex" "$leaf_hex" "$address_bits" "$TICK" "$input" "$STATE" "$PREV_PATH" "scripts/ttc_busybox.sh"
  fi

  printf 'tick=%d input=0x%02X state=0x%02X basis7=%d basis8=%d winner=%d class=%s point=%s lane=%d leaf=%d replay_seq=%s incidence_seq=%s config_seq=%s address_bits="%s" parent=%s path=%s\n' \
    "$TICK" "$input" "$STATE" "$basis7" "$basis8" "$winner" "$class" "$point" "$lane" "$leaf" \
    "$replay_seq" "$incidence_seq" "$config_seq" "$address_bits" "$PREV_PATH" "$path"

  PREV_PATH="$path"
  TICK=$((TICK + 1))
}

if [ "$BINARY_MODE" -eq 1 ]; then
  od -An -v -t u1 | tr -s '[:space:]' ' ' | sed 's/^ //' | while IFS= read -r line; do
    for b in $line; do
      process_byte "$b"
    done
  done
else
  while IFS= read -r line; do
    for b in $line; do
      process_byte "$b"
    done
  done
fi
