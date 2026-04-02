#include "ttc_witness.h"

#include <stdio.h>
#include <stdlib.h>

int main(void) {
    ttc_witness_symbol *symbols = NULL;
    size_t symbol_count = 0;
    size_t cap = 0;
    unsigned int value;
    size_t idx = 0;
    uint8_t *stream = NULL;
    uint8_t *artifact = NULL;
    size_t stream_len = 0;
    size_t artifact_len = 0;
    int rc;

    while (scanf("%u", &value) == 1) {
        ttc_witness_symbol *next;
        if (value > 255u) {
            fprintf(stderr, "ERROR: slot value out of range\n");
            free(symbols);
            return 2;
        }
        if (idx % TTC_WITNESS_SYMBOL_SLOTS == 0u) {
            size_t new_count = symbol_count + 1u;
            if (new_count > cap) {
                size_t new_cap = cap ? cap * 2u : 8u;
                next = (ttc_witness_symbol *)realloc(symbols, new_cap * sizeof(*symbols));
                if (!next) {
                    free(symbols);
                    fprintf(stderr, "ERROR: allocation failure\n");
                    return 2;
                }
                symbols = next;
                cap = new_cap;
            }
            symbols[symbol_count].coords[0] = 0u;
            symbol_count = new_count;
        }
        symbols[symbol_count - 1u].coords[idx % TTC_WITNESS_SYMBOL_SLOTS] = (uint8_t)value;
        idx++;
    }

    if (idx % TTC_WITNESS_SYMBOL_SLOTS != 0u) {
        free(symbols);
        fprintf(stderr, "ERROR: input must contain full 60-slot symbols\n");
        return 2;
    }

    rc = ttc_witness_symbols_to_stream(symbols, symbol_count, &stream, &stream_len);
    if (rc != TTC_WITNESS_OK) {
        free(symbols);
        fprintf(stderr, "ERROR: witness stream recovery failed\n");
        return 2;
    }
    rc = ttc_witness_a13_decode(stream, stream_len, &artifact, &artifact_len);
    if (rc != TTC_WITNESS_OK) {
        free(stream);
        free(symbols);
        fprintf(stderr, "ERROR: witness A13 decode failed\n");
        return 2;
    }
    if (artifact_len > 0u) {
        fwrite(artifact, 1u, artifact_len, stdout);
    }

    free(artifact);
    free(stream);
    free(symbols);
    return 0;
}
