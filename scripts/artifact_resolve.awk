#!/usr/bin/awk -f

# Input: one path per line, e.g.
# artifacts/xX/p2/2a/0078
# Output: TSV
# path class class_bits point point_index lane_hex lane_dec leaf_hex leaf_dec address_23b

BEGIN {
    FS = "\n"
    OFS = "\t"
}

function class_bits(c) {
    if (c == "xx") return 0
    if (c == "xX") return 1
    if (c == "Xx") return 2
    if (c == "XX") return 3
    return -1
}

{
    p = $0
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", p)
    if (p == "") next

    n = split(p, a, "/")
    if (n < 5 || a[1] != "artifacts") {
        print p, "ERROR", "invalid_path"
        next
    }

    cls = a[2]
    point = a[3]
    lane_hex = a[4]
    leaf_hex = a[5]

    cb = class_bits(cls)
    if (cb < 0) {
        print p, "ERROR", "invalid_class"
        next
    }

    if (point !~ /^p[0-2]$/) {
        print p, "ERROR", "invalid_point"
        next
    }
    pi = substr(point, 2, 1) + 0

    lane = strtonum("0x" lane_hex)
    leaf = strtonum("0x" leaf_hex)
    if (lane < 0 || lane > 59) {
        print p, "ERROR", "invalid_lane"
        next
    }
    if (leaf < 0 || leaf > 5039) {
        print p, "ERROR", "invalid_leaf"
        next
    }

    # 23-bit packed address:
    # class(2) | point(2) | lane(6) | leaf(13)
    addr = or(lshift(cb, 21), lshift(pi, 19))
    addr = or(addr, lshift(lane, 13))
    addr = or(addr, leaf)

    printf("%s\t%s\t%d\t%s\t%d\t%s\t%d\t%s\t%d\t0x%06x\n",
           p, cls, cb, point, pi, lane_hex, lane, leaf_hex, leaf, addr)
}
