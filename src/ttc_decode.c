#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define SLOTS_PER_SYMBOL 60
#define PAYLOAD_PER_SYMBOL 58

static void die(const char *msg) {
    fprintf(stderr, "ERROR: %s\n", msg);
    exit(2);
}

static void push(uint8_t **buf, size_t *n, size_t *cap, uint8_t v) {
    if (*n == *cap) {
      size_t next = (*cap == 0) ? 256 : (*cap * 2);
      uint8_t *tmp = (uint8_t *)realloc(*buf, next);
      if (!tmp) die("realloc failed");
      *buf = tmp;
      *cap = next;
    }
    (*buf)[(*n)++] = v;
}

/* Inverse A13 profile (slip-v1). */
static uint8_t *a13_decode(const uint8_t *in, size_t in_len, size_t *out_len) {
    size_t i;
    int in_frame = 0;
    uint8_t *out = NULL;
    size_t n = 0, cap = 0;

    for (i = 0; i < in_len; i++) {
      uint8_t b = in[i];
      if (!in_frame) {
        if (b == 0xC0) in_frame = 1;
        continue;
      }
      if (b == 0xC0) {
        *out_len = n;
        return out;
      }
      if (b == 0xDB) {
        if (i + 1 >= in_len) die("truncated escape in A13 stream");
        i++;
        if (in[i] == 0xDC) push(&out, &n, &cap, 0xC0);
        else if (in[i] == 0xDD) push(&out, &n, &cap, 0xDB);
        else die("invalid escape in A13 stream");
      } else {
        push(&out, &n, &cap, b);
      }
    }

    die("unterminated A13 frame");
    return NULL;
}

int main(void) {
    uint8_t *a13 = NULL;
    uint8_t *artifact = NULL;
    size_t a13_n = 0, a13_cap = 0, art_n = 0;
    unsigned int v;
    uint8_t slots[SLOTS_PER_SYMBOL];
    size_t i = 0;

    while (scanf("%u", &v) == 1) {
      if (v > 255) die("slot value out of range");
      slots[i++] = (uint8_t)v;
      if (i == SLOTS_PER_SYMBOL) {
        size_t take = slots[0];
        size_t k;
        if (take > PAYLOAD_PER_SYMBOL) die("chunk_len exceeds payload capacity");
        for (k = 0; k < take; k++) push(&a13, &a13_n, &a13_cap, slots[2 + k]);
        i = 0;
      }
    }

    if (i != 0) die("input must contain full 60-slot symbols");
    artifact = a13_decode(a13, a13_n, &art_n);
    if (art_n > 0) fwrite(artifact, 1, art_n, stdout);

    free(artifact);
    free(a13);
    return 0;
}
