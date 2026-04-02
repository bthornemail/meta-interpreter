#ifndef TTC_GRAMMAR_H
#define TTC_GRAMMAR_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    TTC_GRAMMAR_ROLE_PAYLOAD = 0,
    TTC_GRAMMAR_ROLE_NULL = 1,
    TTC_GRAMMAR_ROLE_ESC = 2,
    TTC_GRAMMAR_ROLE_FS = 3,
    TTC_GRAMMAR_ROLE_GS = 4,
    TTC_GRAMMAR_ROLE_RS = 5,
    TTC_GRAMMAR_ROLE_US = 6
} ttc_grammar_role;

typedef struct {
    uint8_t input;
    ttc_grammar_role role;
    uint8_t escape_depth;
    uint8_t scope_axis;
    uint8_t structural_anchor;
    uint8_t header8_class;
} ttc_grammar_state;

void ttc_grammar_interpret_byte(uint8_t input, uint8_t prior_escape_depth, ttc_grammar_state *out);

#ifdef __cplusplus
}
#endif

#endif
