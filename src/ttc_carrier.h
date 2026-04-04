#ifndef TTC_CARRIER_H
#define TTC_CARRIER_H

#include <stdint.h>

#include "ttc_runtime.h"
#include "ttc_grammar.h"
#include "ttc_address.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    TTC_STATE_CLASS_NULL_VOID = 0,
    TTC_STATE_CLASS_LOW_LAW = 1,
    TTC_STATE_CLASS_HIGH_EDIT = 2
} ttc_state_class;

typedef enum {
    TTC_MATERIAL_CLASS_xx = 0,
    TTC_MATERIAL_CLASS_xX = 1,
    TTC_MATERIAL_CLASS_Xx = 2,
    TTC_MATERIAL_CLASS_XX = 3
} ttc_material_class;

typedef struct {
    ttc_state_class state_class;
    ttc_material_class material_class;
    uint8_t resolved_scope;
    uint8_t resolvable_scope;
    uint8_t scope_rank;
    uint8_t closure_rank;
    uint8_t deterministic_closure;
} ttc_carrier_resolution;

ttc_state_class ttc_state_class_from_state8(uint8_t state8);
ttc_material_class ttc_material_class_from_input_tick(uint8_t input, uint64_t tick);
const char *ttc_state_class_name(ttc_state_class state_class);
const char *ttc_material_class_name(ttc_material_class material_class);
const char *ttc_carrier_closure_class_name(const ttc_carrier_resolution *resolution);
const char *ttc_carrier_point_or_region_name(const ttc_carrier_resolution *resolution);
void ttc_carrier_resolution_from_tuple(const ttc_event *event, const ttc_grammar_state *grammar, const ttc_address *address, ttc_carrier_resolution *out);

#ifdef __cplusplus
}
#endif

#endif
