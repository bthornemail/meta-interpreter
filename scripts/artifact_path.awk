#!/usr/bin/awk -f

# Input: whitespace-separated byte values (0..255)
# Output TSV fields:
# tick byte class point winner lane lane_hex leaf leaf_hex lane_divisor path

BEGIN {
    x = 0x78
    X = 0x58
    x_toggle = xor(x, X)   # 0x20

    split("0,1,3:0,2,5:0,4,6:1,2,4:1,5,6:2,3,6:3,4,5", lines, ":")
    DIVS_FILE = (DIVS_FILE == "" ? "blocks/registry/divisors_5040.tsv" : DIVS_FILE)
    nd = 0
    while ((getline line < DIVS_FILE) > 0) {
        if (line ~ /^#/ || line ~ /^[[:space:]]*$/) continue
        split(line, f, "\t")
        idx = f[1] + 0
        val = f[2] + 0
        divs[idx + 1] = val
        nd++
    }
    close(DIVS_FILE)
    if (nd != 60) {
        split("1 2 3 4 5 6 7 8 9 10 12 14 15 16 18 20 21 24 28 30 35 36 40 42 45 48 56 60 63 70 72 80 84 90 105 112 120 126 140 144 168 180 210 240 252 280 315 336 360 420 504 560 630 720 840 1008 1260 1680 2520 5040", divs, " ")
    }

    tick = 0
}

{
    for (i = 1; i <= NF; i++) {
        byte = $i + 0
        if (byte < 0 || byte > 255) continue
        tick++

        # Level 1: epistemic transform class
        c0 = and(rshift(byte, 5), 1)
        c1 = and(tick, 1)
        cls_idx = or(lshift(c1, 1), c0)

        if (cls_idx == 0) cls = "xx"
        else if (cls_idx == 1) cls = "xX"
        else if (cls_idx == 2) cls = "Xx"
        else cls = "XX"

        # Level 2: Fano-derived point
        line_idx = (tick - 1) % 7 + 1
        split(lines[line_idx], pts, ",")
        winner = c0 ? pts[3] + 0 : pts[1] + 0
        point_idx = winner % 3
        point = sprintf("p%d", point_idx)

        # Level 3: 60-way lane
        lane = and(or(lshift(winner, 2), rshift(byte, 2)), 63) % 60
        lane_str = sprintf("%02x", lane)
        lane_divisor = divs[lane + 1] + 0

        # Level 4: 5040 residue leaf
        mix = or(lshift(and(byte, 0xFF), 5), and(tick, 31))
        leaf = mix % 5040
        leaf_str = sprintf("%04x", leaf)

        path = sprintf("artifacts/%s/%s/%s/%s", cls, point, lane_str, leaf_str)

        printf("%d\t%d\t%s\t%s\t%d\t%d\t%s\t%d\t%s\t%d\t%s\n",
               tick, byte, cls, point, winner, lane, lane_str, leaf, leaf_str, lane_divisor, path)
    }
}
