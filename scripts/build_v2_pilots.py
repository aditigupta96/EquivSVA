#!/usr/bin/env python3

import json
from pathlib import Path

ROOT = Path("dataset")

FSM_VARIANTS = [
    "canonical_case",
    "onehot_case",
    "nested_if",
    "factored_flags",
]

REG_VARIANTS = [
    {
        "name": "canonical",
        "module_suffix": "canonical_next",
        "file": "canonical_next.sv",
    },
    {
        "name": "sequential",
        "module_suffix": "sequential_priority",
        "file": "sequential_priority.sv",
    },
    {
        "name": "ternary",
        "module_suffix": "ternary_next",
        "file": "ternary_next.sv",
    },
    {
        "name": "function",
        "module_suffix": "function_update",
        "file": "function_update.sv",
    },
]

PROVENANCE = {
    "source_type": "original_synthetic",
    "source": "EquivSVA",
    "behavior_spec_creation": "manually_authored",
    "rtl_generation": "programmatic_from_behavior_spec",
    "derived_from_external_benchmark": False,
}


def write(spec):
    path = ROOT / spec["design_id"]
    if path.exists():
        raise RuntimeError(f"Refusing to overwrite {path}")

    path.mkdir(parents=True)
    (path / "spec.json").write_text(
        json.dumps(spec, indent=2) + "\n"
    )
    print("WROTE", path / "spec.json")


# ------------------------------------------------------------------
# 1. pulse_event_0001
# One pulse for each continuous high episode of event_in.
# ------------------------------------------------------------------

write({
    "design_id": "pulse_event_0001",
    "category": "pulse_event",
    "description": "One-cycle pulse generator that fires once for each high episode of event_in.",
    "clock": {"name": "clk", "edge": "posedge"},
    "reset": {
        "name": "rst",
        "active": "high",
        "synchronous": True,
        "state": "IDLE",
    },
    "inputs": ["event_in"],
    "outputs": ["pulse", "armed"],
    "states": ["IDLE", "FIRE", "WAIT_LOW"],
    "state_outputs": {
        "IDLE": {"pulse": 0, "armed": 1},
        "FIRE": {"pulse": 1, "armed": 0},
        "WAIT_LOW": {"pulse": 0, "armed": 0},
    },
    "transitions": [
        {"from": "IDLE", "when": "event_in", "to": "FIRE"},
        {"from": "IDLE", "when": "!event_in", "to": "IDLE"},
        {"from": "FIRE", "when": "true", "to": "WAIT_LOW"},
        {"from": "WAIT_LOW", "when": "event_in", "to": "WAIT_LOW"},
        {"from": "WAIT_LOW", "when": "!event_in", "to": "IDLE"},
    ],
    "rtl_variants": FSM_VARIANTS,
    "notes": [
        "A continuously asserted input produces only one pulse.",
        "All benchmark properties use interface-visible signals only.",
    ],
    "properties": [
        {
            "id": "P1_MUTEX",
            "sva_name": "p_pulse_not_armed",
            "type": "invariant",
            "natural_language": "pulse and armed are never asserted together",
            "disable": "rst",
            "expression": "!(pulse && armed)",
        },
        {
            "id": "P2_RESET",
            "sva_name": "p_reset_armed",
            "type": "next_cycle_implication",
            "natural_language": "reset returns the detector to the armed state",
            "antecedent": "rst",
            "consequent": "!pulse && armed",
            "delay": 1,
        },
        {
            "id": "P3_EVENT_FIRE",
            "sva_name": "p_event_fire",
            "type": "next_cycle_implication",
            "natural_language": "an event while armed produces a pulse",
            "disable": "rst",
            "antecedent": "armed && event_in",
            "consequent": "pulse && !armed",
            "delay": 1,
        },
        {
            "id": "P4_FIRE_ONE_CYCLE",
            "sva_name": "p_fire_one_cycle",
            "type": "next_cycle_implication",
            "natural_language": "pulse lasts exactly one state cycle",
            "disable": "rst",
            "antecedent": "pulse",
            "consequent": "!pulse && !armed",
            "delay": 1,
        },
        {
            "id": "P5_REARM",
            "sva_name": "p_rearm",
            "type": "next_cycle_implication",
            "natural_language": "the detector rearms after the input returns low",
            "disable": "rst",
            "antecedent": "!pulse && !armed && !event_in",
            "consequent": "armed",
            "delay": 1,
        },
    ],
    "mutants": [
        {
            "name": "repeat_while_high",
            "kind": "force_transition",
            "from": "FIRE",
            "to": "IDLE",
        },
        {
            "name": "never_rearm",
            "kind": "replace_transition_guard",
            "from": "WAIT_LOW",
            "old": "!event_in",
            "new": "false",
        },
        {
            "name": "fire_without_event",
            "kind": "replace_transition_guard",
            "from": "IDLE",
            "old": "event_in",
            "new": "true",
        },
    ],
    "provenance": PROVENANCE,
})


# ------------------------------------------------------------------
# 2. sequence_detector_0001
# Detect 1011 with explicit observable progress.
# ------------------------------------------------------------------

write({
    "design_id": "sequence_detector_0001",
    "category": "sequence_detector",
    "description": "Overlapping serial detector for the bit pattern 1011.",
    "clock": {"name": "clk", "edge": "posedge"},
    "reset": {
        "name": "rst",
        "active": "high",
        "synchronous": True,
        "state": "S0",
    },
    "inputs": ["bit_in"],
    "outputs": ["seen1", "seen10", "seen101", "match"],
    "states": ["S0", "S1", "S10", "S101", "MATCH"],
    "state_outputs": {
        "S0":    {"seen1": 0, "seen10": 0, "seen101": 0, "match": 0},
        "S1":    {"seen1": 1, "seen10": 0, "seen101": 0, "match": 0},
        "S10":   {"seen1": 0, "seen10": 1, "seen101": 0, "match": 0},
        "S101":  {"seen1": 0, "seen10": 0, "seen101": 1, "match": 0},
        "MATCH": {"seen1": 0, "seen10": 0, "seen101": 0, "match": 1},
    },
    "transitions": [
        {"from": "S0", "when": "bit_in", "to": "S1"},
        {"from": "S0", "when": "!bit_in", "to": "S0"},

        {"from": "S1", "when": "bit_in", "to": "S1"},
        {"from": "S1", "when": "!bit_in", "to": "S10"},

        {"from": "S10", "when": "bit_in", "to": "S101"},
        {"from": "S10", "when": "!bit_in", "to": "S0"},

        {"from": "S101", "when": "bit_in", "to": "MATCH"},
        {"from": "S101", "when": "!bit_in", "to": "S10"},

        {"from": "MATCH", "when": "bit_in", "to": "S1"},
        {"from": "MATCH", "when": "!bit_in", "to": "S10"},
    ],
    "rtl_variants": FSM_VARIANTS,
    "notes": [
        "Progress outputs make intermediate behavior externally observable.",
        "The detector permits overlapping matches.",
    ],
    "properties": [
        {
            "id": "P1_ONEHOT_PROGRESS",
            "sva_name": "p_onehot_progress",
            "type": "invariant",
            "natural_language": "at most one progress output is active",
            "disable": "rst",
            "expression": "$onehot0({seen1, seen10, seen101, match})",
        },
        {
            "id": "P2_RESET",
            "sva_name": "p_reset_empty",
            "type": "next_cycle_implication",
            "natural_language": "reset clears all detector progress",
            "antecedent": "rst",
            "consequent": "!seen1 && !seen10 && !seen101 && !match",
            "delay": 1,
        },
        {
            "id": "P3_FIRST_ONE",
            "sva_name": "p_first_one",
            "type": "next_cycle_implication",
            "natural_language": "a one from the empty state begins the sequence",
            "disable": "rst",
            "antecedent": "!seen1 && !seen10 && !seen101 && !match && bit_in",
            "consequent": "seen1",
            "delay": 1,
        },
        {
            "id": "P4_ONE_ZERO",
            "sva_name": "p_one_zero",
            "type": "next_cycle_implication",
            "natural_language": "10 advances to the second progress state",
            "disable": "rst",
            "antecedent": "seen1 && !bit_in",
            "consequent": "seen10",
            "delay": 1,
        },
        {
            "id": "P5_101",
            "sva_name": "p_101",
            "type": "next_cycle_implication",
            "natural_language": "101 advances to the third progress state",
            "disable": "rst",
            "antecedent": "seen10 && bit_in",
            "consequent": "seen101",
            "delay": 1,
        },
        {
            "id": "P6_MATCH",
            "sva_name": "p_1011_match",
            "type": "next_cycle_implication",
            "natural_language": "1011 produces match",
            "disable": "rst",
            "antecedent": "seen101 && bit_in",
            "consequent": "match",
            "delay": 1,
        },
    ],
    "mutants": [
        {
            "name": "miss_final_one",
            "kind": "replace_transition_guard",
            "from": "S101",
            "old": "bit_in",
            "new": "false",
        },
        {
            "name": "wrong_10_progress",
            "kind": "force_transition",
            "from": "S1",
            "to": "S0",
        },
        {
            "name": "lose_overlap",
            "kind": "force_transition",
            "from": "MATCH",
            "to": "S0",
        },
    ],
    "provenance": PROVENANCE,
})


# ------------------------------------------------------------------
# 3. protocol_controller_0001
# ------------------------------------------------------------------

write({
    "design_id": "protocol_controller_0001",
    "category": "protocol_controller",
    "description": "Start/acknowledge transaction controller with abort and completion pulse.",
    "clock": {"name": "clk", "edge": "posedge"},
    "reset": {
        "name": "rst",
        "active": "high",
        "synchronous": True,
        "state": "IDLE",
    },
    "inputs": ["start", "ack", "abort"],
    "outputs": ["busy", "done", "error"],
    "states": ["IDLE", "WAIT_ACK", "DONE", "ERROR"],
    "state_outputs": {
        "IDLE":     {"busy": 0, "done": 0, "error": 0},
        "WAIT_ACK": {"busy": 1, "done": 0, "error": 0},
        "DONE":     {"busy": 0, "done": 1, "error": 0},
        "ERROR":    {"busy": 0, "done": 0, "error": 1},
    },
    "transitions": [
        {"from": "IDLE", "when": "start", "to": "WAIT_ACK"},
        {"from": "IDLE", "when": "!start", "to": "IDLE"},

        {"from": "WAIT_ACK", "when": "abort", "to": "ERROR"},
        {"from": "WAIT_ACK", "when": "!abort && ack", "to": "DONE"},
        {"from": "WAIT_ACK", "when": "!abort && !ack", "to": "WAIT_ACK"},

        {"from": "DONE", "when": "true", "to": "IDLE"},
        {"from": "ERROR", "when": "true", "to": "IDLE"},
    ],
    "rtl_variants": FSM_VARIANTS,
    "notes": [
        "Abort has priority over acknowledge.",
        "done and error are one-cycle terminal states.",
    ],
    "properties": [
        {
            "id": "P1_MUTEX",
            "sva_name": "p_outputs_mutex",
            "type": "invariant",
            "natural_language": "busy, done, and error are mutually exclusive",
            "disable": "rst",
            "expression": "$onehot0({busy, done, error})",
        },
        {
            "id": "P2_RESET",
            "sva_name": "p_reset_idle",
            "type": "next_cycle_implication",
            "natural_language": "reset returns the controller to idle",
            "antecedent": "rst",
            "consequent": "!busy && !done && !error",
            "delay": 1,
        },
        {
            "id": "P3_START",
            "sva_name": "p_start_busy",
            "type": "next_cycle_implication",
            "natural_language": "start begins a transaction",
            "disable": "rst",
            "antecedent": "!busy && !done && !error && start",
            "consequent": "busy",
            "delay": 1,
        },
        {
            "id": "P4_ACK",
            "sva_name": "p_ack_done",
            "type": "next_cycle_implication",
            "natural_language": "ack completes a non-aborted transaction",
            "disable": "rst",
            "antecedent": "busy && ack && !abort",
            "consequent": "done",
            "delay": 1,
        },
        {
            "id": "P5_ABORT",
            "sva_name": "p_abort_error",
            "type": "next_cycle_implication",
            "natural_language": "abort terminates the transaction with error",
            "disable": "rst",
            "antecedent": "busy && abort",
            "consequent": "error",
            "delay": 1,
        },
        {
            "id": "P6_DONE_PULSE",
            "sva_name": "p_done_pulse",
            "type": "next_cycle_implication",
            "natural_language": "done returns to idle after one cycle",
            "disable": "rst",
            "antecedent": "done",
            "consequent": "!busy && !done && !error",
            "delay": 1,
        },
    ],
    "mutants": [
        {
            "name": "ignore_abort",
            "kind": "replace_transition_guard",
            "from": "WAIT_ACK",
            "old": "abort",
            "new": "false",
        },
        {
            "name": "ack_to_error",
            "kind": "force_transition",
            "from": "WAIT_ACK",
            "to": "ERROR",
        },
        {
            "name": "done_stuck",
            "kind": "force_transition",
            "from": "DONE",
            "to": "DONE",
        },
    ],
    "provenance": PROVENANCE,
})


# ------------------------------------------------------------------
# 4. saturating_arithmetic_0001
# ------------------------------------------------------------------

write({
    "design_id": "saturating_arithmetic_0001",
    "category": "saturating_arithmetic",
    "model_type": "register_rules",
    "template": "saturating_accumulator",
    "description": "Three-bit accumulator with saturating increment and synchronous clear.",
    "clock": {"name": "clk", "edge": "posedge"},
    "reset": {
        "name": "rst",
        "active": "high",
        "synchronous": True,
    },
    "inputs": ["clear", "add"],
    "outputs": ["value", "at_max"],
    "signal_widths": {"value": 3},
    "registers": [
        {
            "name": "value",
            "width": 3,
            "reset_value": "3'd0",
            "observable": True,
        }
    ],
    "derived_outputs": {
        "at_max": "value == 3'd7",
    },
    "update_rules": [
        {"when": "clear", "value": "3'd0"},
        {"when": "add && (value < 3'd7)", "value": "value + 3'd1"},
        {"when": "true", "value": "value"},
    ],
    "rtl_variants": REG_VARIANTS,
    "notes": [
        "The accumulator saturates instead of wrapping.",
        "value is interface-visible.",
    ],
    "properties": [
        {
            "id": "P1_MAX",
            "sva_name": "p_at_max",
            "type": "invariant",
            "natural_language": "at_max exactly reflects the saturated value",
            "disable": "rst",
            "expression": "at_max == (value == 3'd7)",
        },
        {
            "id": "P2_RESET",
            "sva_name": "p_reset_zero",
            "type": "next_cycle_implication",
            "natural_language": "reset clears the accumulator",
            "antecedent": "rst",
            "consequent": "(value == 3'd0) && !at_max",
            "delay": 1,
        },
        {
            "id": "P3_CLEAR",
            "sva_name": "p_clear_zero",
            "type": "next_cycle_implication",
            "natural_language": "clear has priority",
            "disable": "rst",
            "antecedent": "clear",
            "consequent": "value == 3'd0",
            "delay": 1,
        },
        {
            "id": "P4_ADD",
            "sva_name": "p_add_increment",
            "type": "next_cycle_implication",
            "natural_language": "add increments the accumulator below saturation",
            "disable": "rst",
            "antecedent": "!clear && add && (value < 3'd7)",
            "consequent": "value == ($past(value) + 3'd1)",
            "delay": 1,
        },
        {
            "id": "P5_SATURATE",
            "sva_name": "p_saturate",
            "type": "next_cycle_implication",
            "natural_language": "an add at the maximum stays saturated",
            "disable": "rst",
            "antecedent": "!clear && add && (value == 3'd7)",
            "consequent": "(value == 3'd7) && at_max",
            "delay": 1,
        },
        {
            "id": "P6_HOLD",
            "sva_name": "p_hold",
            "type": "next_cycle_implication",
            "natural_language": "without clear or add the accumulator holds",
            "disable": "rst",
            "antecedent": "!clear && !add",
            "consequent": "value == $past(value)",
            "delay": 1,
        },
    ],
    "mutants": [
        {
            "name": "wrap_at_max",
            "kind": "insert_update_rule",
            "before": "true",
            "when": "add && (value == 3'd7)",
            "value": "3'd0",
        },
        {
            "name": "ignore_clear",
            "kind": "replace_update_guard",
            "old": "clear",
            "new": "false",
        },
        {
            "name": "increment_without_add",
            "kind": "replace_update_guard",
            "old": "add && (value < 3'd7)",
            "new": "value < 3'd7",
        },
    ],
    "provenance": PROVENANCE,
})


# ------------------------------------------------------------------
# 5. rate_limiter_0001
# Token bucket simplified to one register.
# ------------------------------------------------------------------

write({
    "design_id": "rate_limiter_0001",
    "category": "rate_limiter",
    "model_type": "register_rules",
    "template": "token_bucket",
    "description": "Three-bit token bucket with refill priority and guarded consumption.",
    "clock": {"name": "clk", "edge": "posedge"},
    "reset": {
        "name": "rst",
        "active": "high",
        "synchronous": True,
    },
    "inputs": ["refill", "consume"],
    "outputs": ["tokens", "allow", "full"],
    "signal_widths": {"tokens": 3},
    "registers": [
        {
            "name": "tokens",
            "width": 3,
            "reset_value": "3'd0",
            "observable": True,
        }
    ],
    "derived_outputs": {
        "allow": "tokens != 3'd0",
        "full": "tokens == 3'd7",
    },
    "update_rules": [
        {
            "when": "refill && (tokens < 3'd7)",
            "value": "tokens + 3'd1",
        },
        {
            "when": "!refill && consume && (tokens > 3'd0)",
            "value": "tokens - 3'd1",
        },
        {
            "when": "true",
            "value": "tokens",
        },
    ],
    "rtl_variants": REG_VARIANTS,
    "notes": [
        "Refill has priority over consume.",
        "The bucket saturates at seven tokens.",
    ],
    "properties": [
        {
            "id": "P1_ALLOW",
            "sva_name": "p_allow",
            "type": "invariant",
            "natural_language": "allow is asserted exactly when a token is available",
            "disable": "rst",
            "expression": "allow == (tokens != 3'd0)",
        },
        {
            "id": "P2_FULL",
            "sva_name": "p_full",
            "type": "invariant",
            "natural_language": "full is asserted exactly at capacity",
            "disable": "rst",
            "expression": "full == (tokens == 3'd7)",
        },
        {
            "id": "P3_RESET",
            "sva_name": "p_reset_empty",
            "type": "next_cycle_implication",
            "natural_language": "reset empties the token bucket",
            "antecedent": "rst",
            "consequent": "(tokens == 3'd0) && !allow",
            "delay": 1,
        },
        {
            "id": "P4_REFILL",
            "sva_name": "p_refill",
            "type": "next_cycle_implication",
            "natural_language": "refill adds one token below capacity",
            "disable": "rst",
            "antecedent": "refill && (tokens < 3'd7)",
            "consequent": "tokens == ($past(tokens) + 3'd1)",
            "delay": 1,
        },
        {
            "id": "P5_CONSUME",
            "sva_name": "p_consume",
            "type": "next_cycle_implication",
            "natural_language": "consume removes one token when refill is absent",
            "disable": "rst",
            "antecedent": "!refill && consume && (tokens > 3'd0)",
            "consequent": "tokens == ($past(tokens) - 3'd1)",
            "delay": 1,
        },
        {
            "id": "P6_EMPTY_HOLD",
            "sva_name": "p_empty_no_underflow",
            "type": "next_cycle_implication",
            "natural_language": "consuming an empty bucket cannot underflow",
            "disable": "rst",
            "antecedent": "!refill && consume && (tokens == 3'd0)",
            "consequent": "tokens == 3'd0",
            "delay": 1,
        },
    ],
    "mutants": [
        {
            "name": "ignore_refill",
            "kind": "replace_update_guard",
            "old": "refill && (tokens < 3'd7)",
            "new": "false",
        },
        {
            "name": "ignore_consume",
            "kind": "replace_update_guard",
            "old": "!refill && consume && (tokens > 3'd0)",
            "new": "false",
        },
        {
            "name": "consume_without_request",
            "kind": "replace_update_guard",
            "old": "!refill && consume && (tokens > 3'd0)",
            "new": "!refill && (tokens > 3'd0)",
        },
    ],
    "provenance": PROVENANCE,
})


# ------------------------------------------------------------------
# 6. mode_controller_0001
# ------------------------------------------------------------------

write({
    "design_id": "mode_controller_0001",
    "category": "mode_controller",
    "description": "Four-mode controller supporting standby, active operation, and recoverable fault.",
    "clock": {"name": "clk", "edge": "posedge"},
    "reset": {
        "name": "rst",
        "active": "high",
        "synchronous": True,
        "state": "OFF",
    },
    "inputs": ["enable", "wake", "fault", "clear_fault"],
    "outputs": ["standby", "active", "faulted"],
    "states": ["OFF", "STANDBY", "ACTIVE", "FAULT"],
    "state_outputs": {
        "OFF":     {"standby": 0, "active": 0, "faulted": 0},
        "STANDBY": {"standby": 1, "active": 0, "faulted": 0},
        "ACTIVE":  {"standby": 0, "active": 1, "faulted": 0},
        "FAULT":   {"standby": 0, "active": 0, "faulted": 1},
    },
    "transitions": [
        {"from": "OFF", "when": "enable", "to": "STANDBY"},
        {"from": "OFF", "when": "!enable", "to": "OFF"},

        {"from": "STANDBY", "when": "fault", "to": "FAULT"},
        {"from": "STANDBY", "when": "!fault && !enable", "to": "OFF"},
        {"from": "STANDBY", "when": "!fault && enable && wake", "to": "ACTIVE"},
        {"from": "STANDBY", "when": "!fault && enable && !wake", "to": "STANDBY"},

        {"from": "ACTIVE", "when": "fault", "to": "FAULT"},
        {"from": "ACTIVE", "when": "!fault && !enable", "to": "OFF"},
        {"from": "ACTIVE", "when": "!fault && enable && !wake", "to": "STANDBY"},
        {"from": "ACTIVE", "when": "!fault && enable && wake", "to": "ACTIVE"},

        {"from": "FAULT", "when": "clear_fault", "to": "OFF"},
        {"from": "FAULT", "when": "!clear_fault", "to": "FAULT"},
    ],
    "rtl_variants": FSM_VARIANTS,
    "notes": [
        "Fault has priority over normal mode changes.",
        "The fault state remains sticky until clear_fault.",
    ],
    "properties": [
        {
            "id": "P1_MUTEX",
            "sva_name": "p_modes_mutex",
            "type": "invariant",
            "natural_language": "standby, active, and faulted are mutually exclusive",
            "disable": "rst",
            "expression": "$onehot0({standby, active, faulted})",
        },
        {
            "id": "P2_RESET",
            "sva_name": "p_reset_off",
            "type": "next_cycle_implication",
            "natural_language": "reset puts the controller in off mode",
            "antecedent": "rst",
            "consequent": "!standby && !active && !faulted",
            "delay": 1,
        },
        {
            "id": "P3_ENABLE",
            "sva_name": "p_enable_standby",
            "type": "next_cycle_implication",
            "natural_language": "enabling from off enters standby",
            "disable": "rst",
            "antecedent": "!standby && !active && !faulted && enable",
            "consequent": "standby",
            "delay": 1,
        },
        {
            "id": "P4_WAKE",
            "sva_name": "p_wake_active",
            "type": "next_cycle_implication",
            "natural_language": "wake while enabled in standby enters active mode",
            "disable": "rst",
            "antecedent": "standby && enable && wake && !fault",
            "consequent": "active",
            "delay": 1,
        },
        {
            "id": "P5_FAULT",
            "sva_name": "p_fault",
            "type": "next_cycle_implication",
            "natural_language": "a fault from an enabled mode enters fault state",
            "disable": "rst",
            "antecedent": "(standby || active) && fault",
            "consequent": "faulted",
            "delay": 1,
        },
        {
            "id": "P6_FAULT_STICKY",
            "sva_name": "p_fault_sticky",
            "type": "next_cycle_implication",
            "natural_language": "fault remains asserted until cleared",
            "disable": "rst",
            "antecedent": "faulted && !clear_fault",
            "consequent": "faulted",
            "delay": 1,
        },
        {
            "id": "P7_CLEAR",
            "sva_name": "p_clear_fault",
            "type": "next_cycle_implication",
            "natural_language": "clearing a fault returns to off",
            "disable": "rst",
            "antecedent": "faulted && clear_fault",
            "consequent": "!standby && !active && !faulted",
            "delay": 1,
        },
    ],
    "mutants": [
        {
            "name": "ignore_fault_active",
            "kind": "replace_transition_guard",
            "from": "ACTIVE",
            "old": "fault",
            "new": "false",
        },
        {
            "name": "fault_not_sticky",
            "kind": "force_transition",
            "from": "FAULT",
            "to": "OFF",
        },
        {
            "name": "wake_ignored",
            "kind": "replace_transition_guard",
            "from": "STANDBY",
            "old": "!fault && enable && wake",
            "new": "false",
        },
    ],
    "provenance": PROVENANCE,
})


print()
print("Created 6 EquivSVA v2 pilot BehaviorSpecs.")
