#ifndef TTC_INCIDENCE_H
#define TTC_INCIDENCE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint64_t tick;
    uint8_t arity;
    uint8_t line_index;
    uint8_t chiral;
    uint8_t branch;
    uint8_t layer;
    uint8_t lane_mod;
    uint16_t binomial_left;
    uint16_t binomial_right;
    uint32_t trinomial_coeff;
} ttc_incidence;

void ttc_incidence_from_tick(uint64_t tick, uint8_t winner, ttc_incidence *out);

#ifdef __cplusplus
}
#endif

#endif
