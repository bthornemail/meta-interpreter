#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define AZTEC_W 27
#define AZTEC_H 27
#define SLOTS_PER_SYMBOL 60
#define PAYLOAD_PER_SYMBOL 58

static const int AZTEC_TABLE[SLOTS_PER_SYMBOL][2] = {
    {17,13},{16,17},{11,17},{ 9,15},{ 9,11},{12, 9},{18, 8},{18,12},{18,16},{15,18},{10,18},{ 8,16},{ 8,12},{ 9, 8},{14, 8},
    {19,13},{18,19},{11,19},{ 7,17},{ 7,11},{10, 7},{17, 7},{20,10},{20,16},{17,20},{10,20},{ 6,18},{ 6,12},{ 7, 6},{14, 6},
    {21,13},{20,21},{11,21},{ 5,19},{ 5,11},{ 8, 5},{17, 5},{22, 8},{22,16},{19,22},{10,22},{ 4,20},{ 4,12},{ 5, 4},{14, 4},
    {23,13},{22,23},{11,23},{ 3,21},{ 3,11},{ 6, 3},{17, 3},{24, 6},{24,16},{21,24},{10,24},{ 2,22},{ 2,12},{ 3, 2},{14, 2}
};

typedef enum {
    MODE_JSON = 0,
    MODE_ASCII = 1,
    MODE_SLOTS = 2,
    MODE_PGM = 3
} OutputMode;

typedef struct {
    uint8_t coords[SLOTS_PER_SYMBOL];
} Symbol;

static void die(const char *msg) {
    fprintf(stderr, "ERROR: %s\n", msg);
    exit(2);
}

static uint8_t *read_all_stdin(size_t *out_len) {
    size_t cap = 1024;
    size_t n = 0;
    uint8_t *buf = (uint8_t *)malloc(cap);
    int c;
    if (!buf) die("malloc failed");
    while ((c = fgetc(stdin)) != EOF) {
      if (n == cap) {
        cap *= 2;
        uint8_t *next = (uint8_t *)realloc(buf, cap);
        if (!next) {
          free(buf);
          die("realloc failed");
        }
        buf = next;
      }
      buf[n++] = (uint8_t)c;
    }
    *out_len = n;
    return buf;
}

/* A13 profile (v1 here): SLIP-style self-delimiting byte stream. */
static uint8_t *a13_encode(const uint8_t *in, size_t in_len, size_t *out_len) {
    size_t cap = (in_len * 2) + 2;
    size_t n = 0;
    size_t i;
    uint8_t *out = (uint8_t *)malloc(cap);
    if (!out) die("malloc failed");

    out[n++] = 0xC0;
    for (i = 0; i < in_len; i++) {
      uint8_t b = in[i];
      if (b == 0xC0) {
        out[n++] = 0xDB;
        out[n++] = 0xDC;
      } else if (b == 0xDB) {
        out[n++] = 0xDB;
        out[n++] = 0xDD;
      } else {
        out[n++] = b;
      }
    }
    out[n++] = 0xC0;

    *out_len = n;
    return out;
}

static Symbol *stream_to_symbols(const uint8_t *stream, size_t stream_len, size_t *sym_count) {
    size_t nsyms = (stream_len + PAYLOAD_PER_SYMBOL - 1) / PAYLOAD_PER_SYMBOL;
    size_t s;
    Symbol *syms;
    if (nsyms == 0) nsyms = 1;
    syms = (Symbol *)calloc(nsyms, sizeof(Symbol));
    if (!syms) die("calloc failed");

    for (s = 0; s < nsyms; s++) {
      size_t offset = s * PAYLOAD_PER_SYMBOL;
      size_t remain = (stream_len > offset) ? (stream_len - offset) : 0;
      size_t take = remain > PAYLOAD_PER_SYMBOL ? PAYLOAD_PER_SYMBOL : remain;
      size_t i;
      syms[s].coords[0] = (uint8_t)take;
      syms[s].coords[1] = (uint8_t)((s + 1 < nsyms) ? 1 : 0);
      for (i = 0; i < take; i++) {
        syms[s].coords[2 + i] = stream[offset + i];
      }
    }

    *sym_count = nsyms;
    return syms;
}

static void symbol_to_grid(const Symbol *s, uint8_t grid[AZTEC_H][AZTEC_W]) {
    int y, x, i;
    memset(grid, 0, AZTEC_H * AZTEC_W);
    for (i = 0; i < SLOTS_PER_SYMBOL; i++) {
      x = AZTEC_TABLE[i][0];
      y = AZTEC_TABLE[i][1];
      grid[y][x] = s->coords[i];
    }
}

static char glyph(uint8_t v) {
    if (v == 0) return ' ';
    if (v < 32) return '.';
    if (v < 64) return ':';
    if (v < 96) return '-';
    if (v < 128) return '=';
    if (v < 160) return '+';
    if (v < 192) return '*';
    if (v < 224) return '#';
    return '@';
}

static void emit_ascii(const Symbol *syms, size_t nsyms) {
    size_t s;
    for (s = 0; s < nsyms; s++) {
      int y, x;
      uint8_t grid[AZTEC_H][AZTEC_W];
      symbol_to_grid(&syms[s], grid);
      printf("symbol %zu\n", s);
      for (y = 0; y < AZTEC_H; y++) {
        for (x = 0; x < AZTEC_W; x++) putchar(glyph(grid[y][x]));
        putchar('\n');
      }
    }
}

static void emit_slots(const Symbol *syms, size_t nsyms) {
    size_t s;
    for (s = 0; s < nsyms; s++) {
      int i;
      for (i = 0; i < SLOTS_PER_SYMBOL; i++) {
        if (i) putchar(' ');
        printf("%u", (unsigned)syms[s].coords[i]);
      }
      putchar('\n');
    }
}

static void emit_pgm(const Symbol *syms, size_t nsyms) {
    uint8_t grid[AZTEC_H][AZTEC_W];
    int y, x;
    if (nsyms == 0) return;
    symbol_to_grid(&syms[0], grid);
    printf("P2\n%d %d\n255\n", AZTEC_W, AZTEC_H);
    for (y = 0; y < AZTEC_H; y++) {
      for (x = 0; x < AZTEC_W; x++) {
        printf("%u", (unsigned)grid[y][x]);
        if (x + 1 < AZTEC_W) putchar(' ');
      }
      putchar('\n');
    }
}

static void emit_hex(const uint8_t *buf, size_t n) {
    size_t i;
    for (i = 0; i < n; i++) printf("%02x", (unsigned)buf[i]);
}

static void emit_json(const Symbol *syms, size_t nsyms, const uint8_t *a13, size_t a13_len) {
    size_t s;
    printf("{\n");
    printf("  \"kind\":\"ttc.encode.v1\",\n");
    printf("  \"a13_profile\":\"slip-v1\",\n");
    printf("  \"symbols\":[\n");
    for (s = 0; s < nsyms; s++) {
      int i;
      printf("    {\"index\":%zu,\"chunk_len\":%u,\"continuation\":%u,\"coords\":[", s,
             (unsigned)syms[s].coords[0], (unsigned)syms[s].coords[1]);
      for (i = 0; i < SLOTS_PER_SYMBOL; i++) {
        if (i) putchar(',');
        printf("%u", (unsigned)syms[s].coords[i]);
      }
      printf("]}%s\n", (s + 1 < nsyms) ? "," : "");
    }
    printf("  ],\n");
    printf("  \"a13_hex\":\"");
    emit_hex(a13, a13_len);
    printf("\"\n");
    printf("}\n");
}

static OutputMode parse_mode(const char *m) {
    if (strcmp(m, "json") == 0) return MODE_JSON;
    if (strcmp(m, "ascii") == 0) return MODE_ASCII;
    if (strcmp(m, "slots") == 0) return MODE_SLOTS;
    if (strcmp(m, "pgm") == 0 || strcmp(m, "raw") == 0) return MODE_PGM;
    die("invalid mode");
    return MODE_JSON;
}

int main(int argc, char **argv) {
    OutputMode mode = MODE_JSON;
    uint8_t *artifact = NULL;
    uint8_t *a13 = NULL;
    Symbol *symbols = NULL;
    size_t artifact_len = 0;
    size_t a13_len = 0;
    size_t sym_count = 0;
    int i;

    for (i = 1; i < argc; i++) {
      if (strcmp(argv[i], "-m") == 0 && i + 1 < argc) {
        mode = parse_mode(argv[++i]);
      } else {
        fprintf(stderr, "usage: %s [-m json|ascii|slots|pgm]\n", argv[0]);
        return 2;
      }
    }

    artifact = read_all_stdin(&artifact_len);
    a13 = a13_encode(artifact, artifact_len, &a13_len);
    symbols = stream_to_symbols(a13, a13_len, &sym_count);

    if (mode == MODE_JSON) emit_json(symbols, sym_count, a13, a13_len);
    else if (mode == MODE_ASCII) emit_ascii(symbols, sym_count);
    else if (mode == MODE_SLOTS) emit_slots(symbols, sym_count);
    else emit_pgm(symbols, sym_count);

    free(symbols);
    free(a13);
    free(artifact);
    return 0;
}
