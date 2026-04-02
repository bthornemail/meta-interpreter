#ifndef TTC_AZTEC_H
#define TTC_AZTEC_H

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

#define TTC_AZTEC_MAX_DIM 151

typedef enum {
    TTC_AZTEC_OK = 0,
    TTC_AZTEC_ERR_ARG = -1,
    TTC_AZTEC_ERR_RANGE = -2,
    TTC_AZTEC_ERR_NOMEM = -3,
    TTC_AZTEC_ERR_UNSUPPORTED = -4,
    TTC_AZTEC_ERR_ECC = -5,
    TTC_AZTEC_ERR_FORMAT = -6,
    TTC_AZTEC_ERR_MISMATCH = -7
} ttc_aztec_status;

typedef enum {
    TTC_AZTEC_ECC_CHECKSUM8 = 8
} ttc_aztec_ecc_percent;

typedef enum {
    TTC_AZTEC_SYMBOL_FULL = 1
} ttc_aztec_symbol_kind;

typedef struct {
    uint16_t width;
    uint16_t height;
    uint16_t layers;
    uint16_t data_codewords;
    uint16_t ecc_codewords;
    uint8_t compact;
    uint8_t reserved[7];
} ttc_aztec_meta;

typedef struct {
    ttc_aztec_meta meta;
    uint8_t *modules;
} ttc_aztec_symbol;

typedef struct {
    ttc_aztec_symbol_kind symbol_kind;
    ttc_aztec_ecc_percent ecc_percent;
    uint8_t byte_mode_only;
    uint8_t reserved[7];
} ttc_aztec_policy;

typedef struct {
    uint16_t width;
    uint16_t height;
    uint16_t layers;
    uint8_t ecc_ok;
    uint8_t compact;
    uint8_t reserved[4];
} ttc_aztec_decode_report;

void ttc_aztec_policy_default(ttc_aztec_policy *policy);
void ttc_aztec_symbol_init(ttc_aztec_symbol *sym);
void ttc_aztec_symbol_free(ttc_aztec_symbol *sym);
int ttc_aztec_encode_bytes(const uint8_t *in_bytes, size_t in_len, const ttc_aztec_policy *policy, ttc_aztec_symbol *out_sym);
int ttc_aztec_decode_modules(const uint8_t *modules, uint16_t width, uint16_t height, uint8_t **out_bytes, size_t *out_len, ttc_aztec_decode_report *out_report);
int ttc_aztec_render_ascii(const ttc_aztec_symbol *sym, FILE *out);
int ttc_aztec_render_pbm(const ttc_aztec_symbol *sym, FILE *out);
int ttc_aztec_render_pgm(const ttc_aztec_symbol *sym, unsigned module_px, FILE *out);
int ttc_aztec_verify_roundtrip(const uint8_t *in_bytes, size_t in_len, const ttc_aztec_policy *policy);

#ifdef __cplusplus
}
#endif

#endif
