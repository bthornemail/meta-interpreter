#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define AZTEC_W 27
#define AZTEC_H 27
#define SLOTS_PER_SYMBOL 60

static const int FANO_LINES[7][3] = {
    {0,1,3}, {0,2,5}, {0,4,6},
    {1,2,4}, {1,5,6}, {2,3,6}, {3,4,5}
};

static const uint8_t HEX_WEIGHT[8] = {
    0x01, 0x02, 0x04, 0x40, 0x10, 0x08, 0x20, 0x80
};

static const int AZTEC_TABLE[SLOTS_PER_SYMBOL][2] = {
    {17,13},{16,17},{11,17},{ 9,15},{ 9,11},{12, 9},{18, 8},{18,12},{18,16},{15,18},{10,18},{ 8,16},{ 8,12},{ 9, 8},{14, 8},
    {19,13},{18,19},{11,19},{ 7,17},{ 7,11},{10, 7},{17, 7},{20,10},{20,16},{17,20},{10,20},{ 6,18},{ 6,12},{ 7, 6},{14, 6},
    {21,13},{20,21},{11,21},{ 5,19},{ 5,11},{ 8, 5},{17, 5},{22, 8},{22,16},{19,22},{10,22},{ 4,20},{ 4,12},{ 5, 4},{14, 4},
    {23,13},{22,23},{11,23},{ 3,21},{ 3,11},{ 6, 3},{17, 3},{24, 6},{24,16},{21,24},{10,24},{ 2,22},{ 2,12},{ 3, 2},{14, 2}
};

typedef enum { MODE_ASCII=0, MODE_PGM=1, MODE_JSON=2 } Mode;

static int fano_winner(int tick) {
    int line = tick % 7;
    int chiral = (tick / 7) % 2;
    return chiral ? FANO_LINES[line][2] : FANO_LINES[line][0];
}

static uint8_t braille_hexwt(uint8_t byte) {
    int i;
    uint8_t out = 0;
    for (i = 0; i < 8; i++) if (byte & (uint8_t)(1u << i)) out = (uint8_t)(out + HEX_WEIGHT[i]);
    return out;
}

static char glyph(uint8_t v) {
    if (v == 0) return ' ';
    if (v <= 1) return '.';
    if (v <= 2) return ':';
    if (v <= 3) return '-';
    if (v <= 4) return '=';
    if (v <= 5) return '+';
    if (v <= 6) return '*';
    if (v <= 7) return '#';
    if (v <= 8) return '@';
    return '%';
}

static void render_symbol(const uint8_t coords[SLOTS_PER_SYMBOL], uint8_t grid[AZTEC_H][AZTEC_W]) {
    int i;
    memset(grid, 0, AZTEC_H * AZTEC_W);
    for (i = 0; i < SLOTS_PER_SYMBOL; i++) {
      int x = AZTEC_TABLE[i][0];
      int y = AZTEC_TABLE[i][1];
      int winner = fano_winner(i);
      uint8_t b = coords[i];
      uint8_t hexwt = braille_hexwt(b);
      uint8_t intensity = (uint8_t)(((hexwt + winner) % 10) + 1);
      grid[y][x] = intensity;
    }
}

int main(int argc, char **argv) {
    Mode mode = MODE_ASCII;
    uint8_t coords[SLOTS_PER_SYMBOL];
    uint8_t grid[AZTEC_H][AZTEC_W];
    size_t idx = 0;
    unsigned int v;
    int sym = 0;
    int i;

    for (i = 1; i < argc; i++) {
      if (strcmp(argv[i], "-m") == 0 && i + 1 < argc) {
        i++;
        if (strcmp(argv[i], "ascii") == 0) mode = MODE_ASCII;
        else if (strcmp(argv[i], "pgm") == 0 || strcmp(argv[i], "raw") == 0) mode = MODE_PGM;
        else if (strcmp(argv[i], "json") == 0) mode = MODE_JSON;
        else {
          fprintf(stderr, "usage: %s [-m ascii|pgm|json]\n", argv[0]);
          return 2;
        }
      }
    }

    if (mode == MODE_PGM) printf("P2\n%d %d\n255\n", AZTEC_W, AZTEC_H);
    if (mode == MODE_JSON) printf("{\"kind\":\"ttc.witness.v1\",\"symbols\":[\n");

    while (scanf("%u", &v) == 1) {
      if (v > 255) {
        fprintf(stderr, "ERROR: slot out of range\n");
        return 2;
      }
      coords[idx++] = (uint8_t)v;
      if (idx == SLOTS_PER_SYMBOL) {
        int y, x;
        render_symbol(coords, grid);
        if (mode == MODE_ASCII) {
          printf("symbol %d\n", sym);
          for (y = 0; y < AZTEC_H; y++) {
            for (x = 0; x < AZTEC_W; x++) putchar(glyph(grid[y][x]));
            putchar('\n');
          }
        } else if (mode == MODE_PGM) {
          for (y = 0; y < AZTEC_H; y++) {
            for (x = 0; x < AZTEC_W; x++) {
              int px = grid[y][x] * 25;
              if (px > 255) px = 255;
              printf("%d", px);
              if (x + 1 < AZTEC_W) putchar(' ');
            }
            putchar('\n');
          }
        } else {
          printf("{\"index\":%d,\"chunk_len\":%u,\"continuation\":%u}%s\n",
                 sym, (unsigned)coords[0], (unsigned)coords[1], ",");
        }

        idx = 0;
        sym++;
      }
    }

    if (idx != 0) {
      fprintf(stderr, "ERROR: expected full 60-slot symbols\n");
      return 2;
    }

    if (mode == MODE_JSON) printf("{}]}\n");
    return 0;
}
