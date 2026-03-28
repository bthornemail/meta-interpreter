#!/bin/sh
# Shared leaf declaration contract for artifact trie nodes.
# Writes declaration surfaces:
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

    # 1) Canonical identity declaration (authoritative leaf identity)
    cat > "$dir/.canon" <<EOF_CANON
{"kind":"ttc.leaf.canon.v1","schema":"$schema","class":"$class","point":"$point","lane":"$lane","leaf":"$leaf","address_bits":"$address_bits","tick":$tick,"input":$input,"state":$state}
EOF_CANON

    # 2) Block/interface declaration (reusable vocabulary references)
    braille_cp=""
    if [ "$state" -ge 0 ] 2>/dev/null; then
      braille_cp=$(printf 'U+%04X' $((0x2800 + state)))
    fi
    cat > "$dir/.block" <<EOF_BLOCK
{"kind":"ttc.leaf.block.v1","block_registry":"blocks/registry/blocks.normalized.tsv","class":"$class","point":"$point","braille_cp":"$braille_cp","source":"$source"}
EOF_BLOCK

    # 3) Artifact declaration (materialized instance linkage)
    cat > "$dir/.artifact" <<EOF_ART
{"kind":"ttc.leaf.artifact.v1","path":"$dir","parent":"$parent","source":"$source"}
EOF_ART

    # 4) Bitboard declaration (explicit board/state surface)
    if [ -n "$board" ]; then
      printf '%s
' "$board" > "$dir/.bitboard"
    else
      if [ "$state" -ge 0 ] 2>/dev/null; then
        ttc_bits8 "$state" > "$dir/.bitboard"
        printf '
' >> "$dir/.bitboard"
      else
        printf '
' > "$dir/.bitboard"
      fi
    fi

    # 5) Golden declaration (positive expectation surface)
    cat > "$dir/.golden" <<EOF_G
{"kind":"ttc.leaf.golden.v1","status":"unset","source":"$source"}
EOF_G

    # 6) Negative declaration (negative-case expectation surface)
    cat > "$dir/.negative" <<EOF_N
{"kind":"ttc.leaf.negative.v1","status":"unset","source":"$source"}
EOF_N

    # 7) Blocks mirror leaf (deterministic addressed structure + inclusion dotfiles)
    blocks_root="${TTC_BLOCKS_ROOT:-blocks}"
    block_dir="${blocks_root}/${class}/${point}/${lane}/${leaf}"
    mkdir -p "$block_dir"

    cat > "$block_dir/.canon" <<EOF_BCANON
{"kind":"ttc.block.leaf.canon.v1","class":"$class","point":"$point","lane":"$lane","leaf":"$leaf","address_bits":"$address_bits","tick":$tick,"input":$input,"state":$state}
EOF_BCANON

    cat > "$block_dir/.artifact" <<EOF_BART
{"kind":"ttc.block.leaf.ref.v1","artifact_path":"$dir","source":"$source"}
EOF_BART

    cat > "$block_dir/.registry" <<EOF_BREG
{"kind":"ttc.block.leaf.registry.v1","blocks_registry":"blocks/registry/blocks.normalized.tsv","scales_registry":"blocks/registry/block_scales.tsv","divisors_registry":"blocks/registry/divisors_5040.tsv"}
EOF_BREG

    rm -f "$block_dir/.include.control_plane_header" \
          "$block_dir/.include.braille_patterns" \
          "$block_dir/.include.braille_a_6dot" \
          "$block_dir/.include.braille_b_extended"

    : > "$block_dir/.include.braille_patterns"
    if [ "$state" -ge 0 ] 2>/dev/null && [ "$state" -le 63 ] 2>/dev/null; then
      : > "$block_dir/.include.braille_a_6dot"
    else
      : > "$block_dir/.include.braille_b_extended"
    fi
    if [ "$input" -ge 28 ] 2>/dev/null && [ "$input" -le 31 ] 2>/dev/null; then
      : > "$block_dir/.include.control_plane_header"
    fi
  )
}
