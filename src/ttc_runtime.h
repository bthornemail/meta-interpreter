#ifndef TTC_RUNTIME_H
#define TTC_RUNTIME_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define TTC_BOARD_SLOTS 60u
#define TTC_MASTER_RESET 5040u
#define TTC_GS 0x1Du
#define TTC_RUNTIME_FLAG_STRICT 0x00000001u

typedef enum {
    TTC_RULE_V1_CURRENT = 1,
    TTC_RULE_V2_DELTA64 = 2
} ttc_rule_version;

typedef struct {
    ttc_rule_version rule_version;
    uint64_t seed;
    uint32_t flags;
} ttc_runtime_config;

typedef struct {
    ttc_rule_version rule_version;
    uint64_t tick;
    uint8_t input;
    uint64_t prev_state;
    uint64_t curr_state;
    uint8_t state8;
    uint8_t basis7;
    uint8_t basis8;
    uint8_t law;
    uint8_t edit;
    uint8_t boundary;
    uint8_t winner;
    uint16_t braille;
    uint8_t board[TTC_BOARD_SLOTS];
} ttc_event;

typedef struct {
    ttc_runtime_config config;
    uint64_t tick;
    uint64_t state;
    uint8_t initialized;
} ttc_runtime;

void ttc_runtime_config_default(ttc_runtime_config *config);
void ttc_runtime_init(ttc_runtime *rt, const ttc_runtime_config *config);
void ttc_runtime_reset(ttc_runtime *rt, const ttc_runtime_config *config);
int ttc_runtime_step(ttc_runtime *rt, uint8_t input, ttc_event *out);
void ttc_project_board_for_state(ttc_rule_version rule_version, uint64_t state, uint64_t tick, uint8_t board[TTC_BOARD_SLOTS]);
void ttc_project_board_for_runtime(const ttc_runtime *rt, uint8_t board[TTC_BOARD_SLOTS]);

#ifdef __cplusplus
}
#endif

#endif
