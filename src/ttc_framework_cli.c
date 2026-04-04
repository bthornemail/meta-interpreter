#include "ttc_framework.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void usage(const char *argv0) {
    fprintf(stderr,
        "usage:\n"
        "  %s runtime [--rule current|delta64] [--seed N]\n"
        "  %s witness-slot-encode\n"
        "  %s witness-slot-decode\n"
        "  %s witness-render\n"
        "  %s matrix-encode [--ascii|--pbm|--pgm] [--module-px N]\n"
        "  %s matrix-decode\n"
        "  %s aztec-encode [compat alias; not standards Aztec]\n"
        "  %s aztec-decode [compat alias; not standards Aztec]\n",
        argv0, argv0, argv0, argv0, argv0, argv0, argv0, argv0);
}

static uint8_t *read_all_stdin(size_t *out_len) {
    uint8_t *buf = NULL;
    size_t len = 0;
    size_t cap = 0;
    int ch;
    while ((ch = fgetc(stdin)) != EOF) {
        if (len == cap) {
            size_t new_cap = cap ? cap * 2u : 1024u;
            uint8_t *next = (uint8_t *)realloc(buf, new_cap);
            if (!next) {
                free(buf);
                return NULL;
            }
            buf = next;
            cap = new_cap;
        }
        buf[len++] = (uint8_t)ch;
    }
    *out_len = len;
    return buf;
}

typedef enum {
    TTC_ARTIFACT_CLASS_CLAIM = 0,
    TTC_ARTIFACT_CLASS_PROPOSAL = 1,
    TTC_ARTIFACT_CLASS_CLOSURE = 2,
    TTC_ARTIFACT_CLASS_RECEIPT = 3
} ttc_artifact_class_state;

static const char *artifact_class_name(ttc_artifact_class_state cls) {
    switch (cls) {
        case TTC_ARTIFACT_CLASS_PROPOSAL: return "proposal";
        case TTC_ARTIFACT_CLASS_CLOSURE: return "closure";
        case TTC_ARTIFACT_CLASS_RECEIPT: return "receipt";
        case TTC_ARTIFACT_CLASS_CLAIM:
        default:
            return "claim";
    }
}

static const char *workflow_mode_name(ttc_artifact_class_state cls) {
    switch (cls) {
        case TTC_ARTIFACT_CLASS_PROPOSAL: return "evaluate";
        case TTC_ARTIFACT_CLASS_CLOSURE: return "apply";
        case TTC_ARTIFACT_CLASS_RECEIPT: return "verify";
        case TTC_ARTIFACT_CLASS_CLAIM:
        default:
            return "inspect";
    }
}

static const char *frame_scope_kind_name(ttc_artifact_class_state cls) {
    switch (cls) {
        case TTC_ARTIFACT_CLASS_PROPOSAL: return "path";
        case TTC_ARTIFACT_CLASS_CLOSURE: return "constraint";
        case TTC_ARTIFACT_CLASS_RECEIPT: return "event";
        case TTC_ARTIFACT_CLASS_CLAIM:
        default:
            return "point";
    }
}

static const char *contract_ref_name(ttc_artifact_class_state cls) {
    switch (cls) {
        case TTC_ARTIFACT_CLASS_PROPOSAL: return "control.gs.evaluate.v1";
        case TTC_ARTIFACT_CLASS_CLOSURE: return "control.rs.apply.v1";
        case TTC_ARTIFACT_CLASS_RECEIPT: return "control.us.verify.v1";
        case TTC_ARTIFACT_CLASS_CLAIM:
        default:
            return "control.fs.inspect.v1";
    }
}

static ttc_artifact_class_state class_from_grammar_role(ttc_grammar_role role, ttc_artifact_class_state prior) {
    switch (role) {
        case TTC_GRAMMAR_ROLE_FS: return TTC_ARTIFACT_CLASS_CLAIM;
        case TTC_GRAMMAR_ROLE_GS: return TTC_ARTIFACT_CLASS_PROPOSAL;
        case TTC_GRAMMAR_ROLE_RS: return TTC_ARTIFACT_CLASS_CLOSURE;
        case TTC_GRAMMAR_ROLE_US: return TTC_ARTIFACT_CLASS_RECEIPT;
        case TTC_GRAMMAR_ROLE_PAYLOAD:
        case TTC_GRAMMAR_ROLE_ESC:
        case TTC_GRAMMAR_ROLE_NULL:
        default:
            return prior;
    }
}

static int cmd_runtime(int argc, char **argv) {
    ttc_runtime_config config;
    ttc_runtime rt;
    int i;
    int ch;
    uint8_t escape_depth = 0u;
    ttc_artifact_class_state active_class = TTC_ARTIFACT_CLASS_CLAIM;

    ttc_runtime_config_default(&config);
    for (i = 0; i < argc; i++) {
        if (strcmp(argv[i], "--rule") == 0 && i + 1 < argc) {
            config.rule_version = (strcmp(argv[++i], "delta64") == 0) ? TTC_RULE_V2_DELTA64 : TTC_RULE_V1_CURRENT;
        } else if (strcmp(argv[i], "--seed") == 0 && i + 1 < argc) {
            config.seed = (uint64_t)strtoull(argv[++i], NULL, 0);
        } else {
            usage("ttc_framework");
            return 1;
        }
    }

    ttc_runtime_init(&rt, &config);
    while ((ch = getchar()) != EOF) {
        ttc_event ev;
        ttc_incidence incidence;
        ttc_grammar_state grammar;
        ttc_address address;
        ttc_carrier_resolution carrier_resolution;
        ttc_artifact_class_state record_class;
        const char *artifact_class;
        const char *workflow_mode;
        const char *frame_scope_kind;
        const char *contract_ref;
        const char *material_class;
        const char *state_class;
        const char *closure_class;
        const char *point_or_region;
        unsigned long long source_step;
        if (ttc_runtime_step(&rt, (uint8_t)ch, &ev) != 0) {
            return 1;
        }
        ttc_incidence_from_step_digest(ev.tick, ev.step_digest, ev.winner, &incidence);
        ttc_grammar_interpret_byte(ev.input, escape_depth, &grammar);
        escape_depth = grammar.escape_depth;
        if (ttc_address_from_structure(&incidence, &grammar, ev.winner, &address) != 0) {
            return 1;
        }
        record_class = class_from_grammar_role(grammar.role, active_class);
        active_class = record_class;
        ttc_carrier_resolution_from_tuple(&ev, &grammar, &address, &carrier_resolution);
        artifact_class = artifact_class_name(record_class);
        workflow_mode = workflow_mode_name(record_class);
        frame_scope_kind = frame_scope_kind_name(record_class);
        contract_ref = contract_ref_name(record_class);
        material_class = ttc_material_class_name(carrier_resolution.material_class);
        state_class = ttc_state_class_name(carrier_resolution.state_class);
        closure_class = ttc_carrier_closure_class_name(&carrier_resolution);
        point_or_region = ttc_carrier_point_or_region_name(&carrier_resolution);
        source_step = ev.tick > 0u ? (unsigned long long)(ev.tick - 1u) : 0ull;

        printf("{\"rule_version\":%d,\"tick\":%llu,\"input\":%u,\"state8\":%u,\"curr_state\":%llu,\"step_digest\":%llu,\"triplet\":[%u,%u,%u],\"order\":[%u,%u,%u],\"seq56\":%u,\"incidence_layer\":%u,\"incidence_x\":%u,\"incidence_y\":%u,\"incidence_z\":%u,\"incidence_coeff\":%u,\"grammar_role\":%u,\"escape_depth\":%u,\"address_slot\":%u,\"address_lane\":%u,\"address_channel\":%u,\"address_orient\":%u,\"address_quadrant\":%u,\"address_word\":\"0x%04X\",\"material_class\":\"%s\",\"state_class\":\"%s\",\"carrier_resolution\":{\"resolved_scope\":%u,\"resolvable_scope\":%u,\"scope_rank\":%u,\"closure_rank\":%u,\"closure_class\":\"%s\",\"point_or_region\":\"%s\",\"deterministic_closure\":%s},\"artifact_class\":\"%s\",\"workflow_mode\":\"%s\",\"frame_scope_kind\":\"%s\",\"frame_scope_ref\":",
               (int)ev.rule_version, (unsigned long long)ev.tick, ev.input, ev.state8,
               (unsigned long long)ev.curr_state, (unsigned long long)ev.step_digest,
               (unsigned)ev.triplet[0], (unsigned)ev.triplet[1], (unsigned)ev.triplet[2],
               (unsigned)ev.order[0], (unsigned)ev.order[1], (unsigned)ev.order[2],
               (unsigned)ev.seq56,
               (unsigned)incidence.layer, (unsigned)incidence.x, (unsigned)incidence.y, (unsigned)incidence.z,
               incidence.trinomial_coeff, (unsigned)grammar.role, (unsigned)grammar.escape_depth,
               (unsigned)address.slot, (unsigned)address.lane, (unsigned)address.channel,
               (unsigned)address.orient, (unsigned)address.quadrant, (unsigned)address.addr_word, material_class, state_class,
               (unsigned)carrier_resolution.resolved_scope, (unsigned)carrier_resolution.resolvable_scope, (unsigned)carrier_resolution.scope_rank,
               (unsigned)carrier_resolution.closure_rank, closure_class, point_or_region,
               carrier_resolution.deterministic_closure ? "true" : "false",
               artifact_class, workflow_mode, frame_scope_kind);
        switch (record_class) {
            case TTC_ARTIFACT_CLASS_PROPOSAL:
                printf("{\"kind\":\"path\",\"source_step\":\"%llu\",\"target_step\":\"%llu\",\"address\":\"0x%04X\",\"contract\":\"%s\"}",
                       source_step, (unsigned long long)ev.tick, (unsigned)address.addr_word, contract_ref);
                break;
            case TTC_ARTIFACT_CLASS_CLOSURE:
                printf("{\"kind\":\"constraint\",\"closure_scope\":\"lane:%u/channel:%u/slot:%u\",\"contract\":\"%s\"}",
                       (unsigned)address.lane, (unsigned)address.channel, (unsigned)address.slot, contract_ref);
                break;
            case TTC_ARTIFACT_CLASS_RECEIPT:
                printf("{\"kind\":\"event\",\"receipt_event\":\"tick:%llu:input:%u\",\"object_step\":\"%llu\",\"contract\":\"%s\"}",
                       (unsigned long long)ev.tick, (unsigned)ev.input, (unsigned long long)ev.tick, contract_ref);
                break;
            case TTC_ARTIFACT_CLASS_CLAIM:
            default:
                printf("{\"kind\":\"point\",\"point\":\"p%u\",\"address\":\"0x%04X\"}",
                       (unsigned)ev.winner, (unsigned)address.addr_word);
                break;
        }
        printf(",\"resolved_step_identity\":{\"step\":\"%llu\",\"step_digest\":\"%llu\",\"address\":\"0x%04X\",\"lane\":\"%u\",\"channel\":\"%u\",\"slot\":\"%u\"},\"ui_frame_resolution\":{\"artifact_class\":\"%s\",\"workflow_mode\":\"%s\",\"step_identity\":{\"step\":\"%llu\",\"step_digest\":\"%llu\",\"address\":\"0x%04X\",\"lane\":\"%u\",\"channel\":\"%u\",\"slot\":\"%u\"},\"frame_scope\":",
               (unsigned long long)ev.tick, (unsigned long long)ev.step_digest, (unsigned)address.addr_word,
               (unsigned)address.lane, (unsigned)address.channel, (unsigned)address.slot,
               artifact_class, workflow_mode,
               (unsigned long long)ev.tick, (unsigned long long)ev.step_digest, (unsigned)address.addr_word,
               (unsigned)address.lane, (unsigned)address.channel, (unsigned)address.slot);
        switch (record_class) {
            case TTC_ARTIFACT_CLASS_PROPOSAL:
                printf("{\"kind\":\"path\",\"source_step\":\"%llu\",\"target_step\":\"%llu\",\"contract\":\"%s\"}}}\n",
                       source_step, (unsigned long long)ev.tick, contract_ref);
                break;
            case TTC_ARTIFACT_CLASS_CLOSURE:
                printf("{\"kind\":\"constraint\",\"closure_scope\":\"lane:%u/channel:%u/slot:%u\",\"contract\":\"%s\"}}}\n",
                       (unsigned)address.lane, (unsigned)address.channel, (unsigned)address.slot, contract_ref);
                break;
            case TTC_ARTIFACT_CLASS_RECEIPT:
                printf("{\"kind\":\"event\",\"receipt_event\":\"tick:%llu:input:%u\",\"contract\":\"%s\"}}}\n",
                       (unsigned long long)ev.tick, (unsigned)ev.input, contract_ref);
                break;
            case TTC_ARTIFACT_CLASS_CLAIM:
            default:
                printf("{\"kind\":\"point\",\"point\":\"p%u\"}}}\n", (unsigned)ev.winner);
                break;
        }
    }
    return 0;
}

static int cmd_witness_slot_encode(void) {
    size_t input_len = 0;
    uint8_t *buf = read_all_stdin(&input_len);
    uint8_t *a13 = NULL;
    ttc_witness_symbol *symbols = NULL;
    size_t count = 0;
    size_t a13_len = 0;
    int rc;
    size_t i;

    if (input_len > 0u && !buf) return 1;
    rc = ttc_witness_a13_encode(buf, input_len, &a13, &a13_len);
    if (rc != TTC_WITNESS_OK) {
        free(buf);
        return 1;
    }
    rc = ttc_witness_stream_to_symbols(a13, a13_len, &symbols, &count);
    if (rc != TTC_WITNESS_OK) {
        free(a13);
        free(buf);
        return 1;
    }
    for (i = 0; i < count; i++) {
        size_t j;
        for (j = 0; j < TTC_WITNESS_SYMBOL_SLOTS; j++) {
            if (j) putchar(' ');
            printf("%u", (unsigned)symbols[i].coords[j]);
        }
        putchar('\n');
    }
    free(symbols);
    free(a13);
    free(buf);
    return 0;
}

static int cmd_witness_slot_decode(void) {
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
            free(symbols);
            return 1;
        }
        if (idx % TTC_WITNESS_SYMBOL_SLOTS == 0u) {
            size_t new_count = symbol_count + 1u;
            if (new_count > cap) {
                size_t new_cap = cap ? cap * 2u : 8u;
                next = (ttc_witness_symbol *)realloc(symbols, new_cap * sizeof(*symbols));
                if (!next) {
                    free(symbols);
                    return 1;
                }
                symbols = next;
                cap = new_cap;
            }
            symbol_count = new_count;
        }
        symbols[symbol_count - 1u].coords[idx % TTC_WITNESS_SYMBOL_SLOTS] = (uint8_t)value;
        idx++;
    }
    if (idx % TTC_WITNESS_SYMBOL_SLOTS != 0u) {
        free(symbols);
        return 1;
    }
    rc = ttc_witness_symbols_to_stream(symbols, symbol_count, &stream, &stream_len);
    free(symbols);
    if (rc != TTC_WITNESS_OK) return 1;
    rc = ttc_witness_a13_decode(stream, stream_len, &artifact, &artifact_len);
    free(stream);
    if (rc != TTC_WITNESS_OK) {
        free(artifact);
        return 1;
    }
    if (artifact_len > 0u) fwrite(artifact, 1u, artifact_len, stdout);
    free(artifact);
    return 0;
}

static int cmd_witness_render(void) {
    ttc_witness_symbol *symbols = NULL;
    size_t symbol_count = 0;
    size_t cap = 0;
    unsigned int value;
    size_t idx = 0;

    while (scanf("%u", &value) == 1) {
        ttc_witness_symbol *next;
        if (value > 255u) {
            free(symbols);
            return 1;
        }
        if (idx % TTC_WITNESS_SYMBOL_SLOTS == 0u) {
            size_t new_count = symbol_count + 1u;
            if (new_count > cap) {
                size_t new_cap = cap ? cap * 2u : 8u;
                next = (ttc_witness_symbol *)realloc(symbols, new_cap * sizeof(*symbols));
                if (!next) {
                    free(symbols);
                    return 1;
                }
                symbols = next;
                cap = new_cap;
            }
            symbol_count = new_count;
        }
        symbols[symbol_count - 1u].coords[idx % TTC_WITNESS_SYMBOL_SLOTS] = (uint8_t)value;
        idx++;
    }
    if (idx % TTC_WITNESS_SYMBOL_SLOTS != 0u) {
        free(symbols);
        return 1;
    }
    if (symbol_count > 0u) {
        uint8_t grid[TTC_WITNESS_HEIGHT][TTC_WITNESS_WIDTH];
        ttc_projection_symbol_to_grid(&symbols[0], grid);
        free(symbols);
        return ttc_projection_render_ascii(grid, stdout) == TTC_WITNESS_OK ? 0 : 1;
    }
    free(symbols);
    return 0;
}

static int cmd_matrix_encode(int argc, char **argv) {
    ttc_matrix_symbol sym;
    ttc_matrix_policy policy;
    size_t len = 0;
    uint8_t *buf;
    unsigned module_px = 4u;
    enum { MODE_ASCII, MODE_PBM, MODE_PGM } mode = MODE_ASCII;
    int i;
    int rc;

    for (i = 0; i < argc; i++) {
        if (strcmp(argv[i], "--ascii") == 0) mode = MODE_ASCII;
        else if (strcmp(argv[i], "--pbm") == 0) mode = MODE_PBM;
        else if (strcmp(argv[i], "--pgm") == 0) mode = MODE_PGM;
        else if (strcmp(argv[i], "--module-px") == 0 && i + 1 < argc) module_px = (unsigned)strtoul(argv[++i], NULL, 0);
        else {
            usage("ttc_framework");
            return 1;
        }
    }

    buf = read_all_stdin(&len);
    if (len > 0u && !buf) return 1;
    ttc_matrix_policy_default(&policy);
    ttc_matrix_symbol_init(&sym);
    rc = ttc_matrix_encode_bytes(buf, len, &policy, &sym);
    free(buf);
    if (rc != TTC_MATRIX_OK) return 1;
    if (mode == MODE_ASCII) rc = ttc_matrix_render_ascii(&sym, stdout);
    else if (mode == MODE_PBM) rc = ttc_matrix_render_pbm(&sym, stdout);
    else rc = ttc_matrix_render_pgm(&sym, module_px, stdout);
    ttc_matrix_symbol_free(&sym);
    return rc == TTC_MATRIX_OK ? 0 : 1;
}

static int cmd_matrix_decode(void) {
    size_t len = 0;
    uint8_t *buf = read_all_stdin(&len);
    uint8_t *out = NULL;
    size_t out_len = 0;
    int rc;

    if (!buf || len != (27u * 27u)) {
        free(buf);
        return 1;
    }
    rc = ttc_matrix_decode_modules(buf, 27u, 27u, &out, &out_len, NULL);
    free(buf);
    if (rc != TTC_MATRIX_OK) {
        free(out);
        return 1;
    }
    if (out_len > 0u) fwrite(out, 1u, out_len, stdout);
    free(out);
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        usage(argv[0]);
        return 1;
    }
    if (strcmp(argv[1], "runtime") == 0) return cmd_runtime(argc - 2, argv + 2);
    if (strcmp(argv[1], "witness-slot-encode") == 0) return cmd_witness_slot_encode();
    if (strcmp(argv[1], "witness-slot-decode") == 0) return cmd_witness_slot_decode();
    if (strcmp(argv[1], "witness-render") == 0) return cmd_witness_render();
    if (strcmp(argv[1], "matrix-encode") == 0) return cmd_matrix_encode(argc - 2, argv + 2);
    if (strcmp(argv[1], "matrix-decode") == 0) return cmd_matrix_decode();
    if (strcmp(argv[1], "aztec-encode") == 0) return cmd_matrix_encode(argc - 2, argv + 2);
    if (strcmp(argv[1], "aztec-decode") == 0) return cmd_matrix_decode();
    usage(argv[0]);
    return 1;
}
