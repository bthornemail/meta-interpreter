/* LAYER: witness
 * Owns downstream carrier-resolution witnesses only.
 */
#include "ttc_carrier.h"

ttc_state_class ttc_state_class_from_state8(uint8_t state8) {
    if (state8 == 0u) {
        return TTC_STATE_CLASS_NULL_VOID;
    }
    if ((state8 & 0x0Cu) != 0u) {
        return TTC_STATE_CLASS_HIGH_EDIT;
    }
    return TTC_STATE_CLASS_LOW_LAW;
}

ttc_material_class ttc_material_class_from_input_tick(uint8_t input, uint64_t tick) {
    uint8_t c0 = (uint8_t)((input >> 5u) & 1u);
    uint8_t c1 = (uint8_t)(tick & 1u);
    return (ttc_material_class)((c1 << 1u) | c0);
}

const char *ttc_state_class_name(ttc_state_class state_class) {
    switch (state_class) {
        case TTC_STATE_CLASS_LOW_LAW: return "LOW_LAW";
        case TTC_STATE_CLASS_HIGH_EDIT: return "HIGH_EDIT";
        case TTC_STATE_CLASS_NULL_VOID:
        default:
            return "NULL_VOID";
    }
}

const char *ttc_material_class_name(ttc_material_class material_class) {
    switch (material_class) {
        case TTC_MATERIAL_CLASS_xX: return "xX";
        case TTC_MATERIAL_CLASS_Xx: return "Xx";
        case TTC_MATERIAL_CLASS_XX: return "XX";
        case TTC_MATERIAL_CLASS_xx:
        default:
            return "xx";
    }
}

static uint8_t resolved_scope_for_class(ttc_material_class material_class) {
    switch (material_class) {
        case TTC_MATERIAL_CLASS_xX:
        case TTC_MATERIAL_CLASS_Xx:
            return 1u;
        case TTC_MATERIAL_CLASS_XX:
            return 0u;
        case TTC_MATERIAL_CLASS_xx:
        default:
            return 2u;
    }
}

const char *ttc_carrier_closure_class_name(const ttc_carrier_resolution *resolution) {
    if (!resolution) {
        return "unavailable";
    }
    switch (resolution->state_class) {
        case TTC_STATE_CLASS_NULL_VOID:
            return "null_void";
        case TTC_STATE_CLASS_LOW_LAW:
            return resolution->material_class == TTC_MATERIAL_CLASS_xx ? "deterministic_point" : "deterministic_projection";
        case TTC_STATE_CLASS_HIGH_EDIT:
        default:
            return resolution->material_class == TTC_MATERIAL_CLASS_XX ? "open_region" : "candidate_region";
    }
}

const char *ttc_carrier_point_or_region_name(const ttc_carrier_resolution *resolution) {
    if (!resolution) {
        return "region";
    }
    if (resolution->state_class == TTC_STATE_CLASS_LOW_LAW && resolution->material_class == TTC_MATERIAL_CLASS_xx) {
        return "point";
    }
    return "region";
}

void ttc_carrier_resolution_from_tuple(const ttc_event *event, const ttc_grammar_state *grammar, const ttc_address *address, ttc_carrier_resolution *out) {
    uint8_t resolved_scope;
    ttc_material_class material_class;

    (void)grammar;
    (void)address;

    if (!event || !out) {
        return;
    }

    material_class = ttc_material_class_from_input_tick(event->input, event->tick);
    resolved_scope = resolved_scope_for_class(material_class);

    out->state_class = ttc_state_class_from_state8(event->state8);
    out->material_class = material_class;
    out->resolved_scope = resolved_scope;
    out->resolvable_scope = (uint8_t)(2u - resolved_scope);
    out->scope_rank = resolved_scope;
    out->closure_rank = out->state_class == TTC_STATE_CLASS_LOW_LAW ? 2u : resolved_scope;
    out->deterministic_closure = (uint8_t)(out->state_class == TTC_STATE_CLASS_LOW_LAW ? 1u : 0u);
}
