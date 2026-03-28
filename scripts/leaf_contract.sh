#!/bin/sh
# Shared leaf declaration contract for artifact and block trie nodes.
# Fixed surfaces:
#   .canon .block .artifact .bitboard .golden .negative

ttc_bits8() {
  (
    n="$1"
    i=7
    out=""
    while [ "$i" -ge 0 ]; do
      out="${out}$(((n >> i) & 1))"
      i=$((i - 1))
    done
    printf '%s' "$out"
  )
}

ttc_popcount8() {
  (
    n=$(( $1 & 255 ))
    c=0
    while [ "$n" -gt 0 ]; do
      c=$((c + (n & 1)))
      n=$((n >> 1))
    done
    printf '%s' "$c"
  )
}

ttc_class_idx() {
  case "$1" in
    xx) printf '0' ;;
    xX) printf '1' ;;
    Xx) printf '2' ;;
    XX) printf '3' ;;
    *)  printf '0' ;;
  esac
}

ttc_point_idx() {
  p="$1"
  case "$p" in
    p0|0) printf '0' ;;
    p1|1) printf '1' ;;
    p2|2) printf '2' ;;
    *)    printf '0' ;;
  esac
}

ttc_braille_range() {
  case "$1" in
    xx) printf 'U+2800:U+280F' ;;
    xX) printf 'U+2810:U+281F' ;;
    Xx) printf 'U+2820:U+282F' ;;
    XX) printf 'U+2830:U+283F' ;;
    *)  printf 'U+2800:U+280F' ;;
  esac
}

ttc_hex2() {
  printf '%02x' $(( $1 & 255 ))
}

ttc_write_leaf_contract() {
  (
    dir="$1"
    schema="$2"
    class="$3"
    point="$4"
    lane="$5"
    leaf="$6"
    address_bits="$7"
    tick="$8"
    input="$9"
    state="${10}"
    parent="${11}"
    source="${12}"
    board="${13:-}"

    mkdir -p "$dir"

    class_idx="$(ttc_class_idx "$class")"
    point_idx="$(ttc_point_idx "$point")"
    lane_dec=$((0x$lane))
    leaf_dec=$((0x$leaf))

    b0=$((input & 255))
    b1=$((state & 255))
    b2=$((tick & 255))
    b3=$(((tick >> 8) & 255))
    b4=$((class_idx & 255))
    b5=$((point_idx & 255))
    b6=$((lane_dec & 255))
    b7=$((leaf_dec & 255))
    b8="$(ttc_popcount8 "$b0")"
    b9="$(ttc_popcount8 "$b1")"
    b10=$((b0 ^ b1))
    b11=$(((b0 << 1) & 255))
    b12=$(((b1 >> 1) & 255))
    b13=$((((b6 & 15) << 4) | (b7 & 15)))
    b14=$((((b4 & 3) << 6) | ((b5 & 3) << 4) | (b6 & 15)))
    b15=0

    left_hex="$(ttc_hex2 "$b0") $(ttc_hex2 "$b1") $(ttc_hex2 "$b2") $(ttc_hex2 "$b3") $(ttc_hex2 "$b4") $(ttc_hex2 "$b5") $(ttc_hex2 "$b6") $(ttc_hex2 "$b7")"
    right_hex="$(ttc_hex2 "$b8") $(ttc_hex2 "$b9") $(ttc_hex2 "$b10") $(ttc_hex2 "$b11") $(ttc_hex2 "$b12") $(ttc_hex2 "$b13") $(ttc_hex2 "$b14") $(ttc_hex2 "$b15")"
    row_addr="$(printf '%08x' $((tick * 16)))"
    braille_range="$(ttc_braille_range "$class")"

    mode_left="affine"
    mode_right="affine"
    case "$class" in
      xX) mode_right="projective" ;;
      Xx) mode_left="projective" ;;
      XX) mode_left="projective"; mode_right="projective" ;;
    esac

    # artifacts leaf surfaces (FS-framed deterministic parse surface)
    cat > "$dir/.canon" <<EOF_CANON
FS ADDR ${class}/${point}/${lane}/${leaf} GS PREIMAGE schema=${schema} tick=${tick} input=0x$(ttc_hex2 "$b0") state=0x$(ttc_hex2 "$b1") class=${class} point=${point} lane=${lane} leaf=${leaf} US ADDRESS_BITS "${address_bits}" RS
EOF_CANON

    cat > "$dir/.block" <<EOF_BLOCK
FS ADDR ${class}/${point}/${lane}/${leaf} GS DECLARE inclusion=declared mode_left=${mode_left} mode_right=${mode_right} source=${source} US FRAME ${braille_range} RS
EOF_BLOCK

    cat > "$dir/.artifact" <<EOF_ART
FS ADDR ${class}/${point}/${lane}/${leaf} GS LEFT ${left_hex} US RIGHT ${right_hex} RS
EOF_ART

    if [ -n "$board" ]; then
      board_payload="$board"
    else
      board_payload="$(ttc_bits8 "$state")"
    fi
    cat > "$dir/.bitboard" <<EOF_BB
FS ADDR ${class}/${point}/${lane}/${leaf} GS BITBOARD ${board_payload} US FRAME16 ${left_hex} ${right_hex} RS
EOF_BB

    cat > "$dir/.golden" <<EOF_G
FS ADDR ${class}/${point}/${lane}/${leaf} GS MUST_ACCEPT ${left_hex} US ${right_hex} RS
EOF_G

    neg0="$(ttc_hex2 $((b0 ^ 1)))"
    cat > "$dir/.negative" <<EOF_N
FS ADDR ${class}/${point}/${lane}/${leaf} GS MUST_REJECT ${neg0} $(ttc_hex2 "$b1") $(ttc_hex2 "$b2") $(ttc_hex2 "$b3") $(ttc_hex2 "$b4") $(ttc_hex2 "$b5") $(ttc_hex2 "$b6") $(ttc_hex2 "$b7") US ${right_hex} RS
EOF_N

    # blocks mirror surfaces (Braille-framed human/control surface)
    blocks_root="${TTC_BLOCKS_ROOT:-blocks}"
    block_dir="${blocks_root}/${class}/${point}/${lane}/${leaf}"
    mkdir -p "$block_dir"

    cat > "$block_dir/.canon" <<EOF_BCANON
${braille_range}  ${row_addr}  ${left_hex}  ${right_hex}
EOF_BCANON

    cat > "$block_dir/.block" <<EOF_BBLOCK
${braille_range}  DECLARE class=${class} point=${point} mode_left=${mode_left} mode_right=${mode_right}
EOF_BBLOCK

    cat > "$block_dir/.artifact" <<EOF_BART
${braille_range}  ${left_hex}  ${right_hex}  |artifact_ref:${dir}|
EOF_BART

    cat > "$block_dir/.bitboard" <<EOF_BBIT
${braille_range}  BITBOARD ${board_payload}
EOF_BBIT

    cat > "$block_dir/.golden" <<EOF_BG
${braille_range}  MUST_ACCEPT ${left_hex}  ${right_hex}
EOF_BG

    cat > "$block_dir/.negative" <<EOF_BN
${braille_range}  MUST_REJECT ${neg0} $(ttc_hex2 "$b1") $(ttc_hex2 "$b2") $(ttc_hex2 "$b3") $(ttc_hex2 "$b4") $(ttc_hex2 "$b5") $(ttc_hex2 "$b6") $(ttc_hex2 "$b7")  ${right_hex}
EOF_BN
  )
}
