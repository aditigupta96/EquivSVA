#!/usr/bin/env python3
"""
Diversify EquivSVA v2 by replacing only repetitive NEW families.

This intentionally leaves all v1 families (0001..0005 in original categories)
untouched. It rewrites 12 v2-added families with behaviorally distinct designs.

Usage:
  python scripts/diversify_v2.py
  python scripts/diversify_v2.py --generate

--generate removes generated rtl/properties/mutants only for the replaced
families and regenerates them with the existing EquivSVA generators.
It does NOT run formal validation.
"""

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path("dataset")

FSM_VARIANTS = [
    "canonical_case",
    "onehot_case",
    "nested_if",
    "factored_flags",
]

REG_VARIANTS = [
    {"name": "canonical", "module_suffix": "canonical_next", "file": "canonical_next.sv"},
    {"name": "sequential", "module_suffix": "sequential_priority", "file": "sequential_priority.sv"},
    {"name": "ternary", "module_suffix": "ternary_next", "file": "ternary_next.sv"},
    {"name": "function", "module_suffix": "function_update", "file": "function_update.sv"},
]

PROVENANCE = {
    "source_type": "original_synthetic",
    "source": "EquivSVA",
    "behavior_spec_creation": "manually_authored",
    "rtl_generation": "programmatic_from_behavior_spec",
    "derived_from_external_benchmark": False,
}

REPLACED = []


def inv(pid, name, text, expr, disable="rst"):
    p = {
        "id": pid,
        "sva_name": name,
        "type": "invariant",
        "natural_language": text,
        "expression": expr,
    }
    if disable:
        p["disable"] = disable
    return p


def nxt(pid, name, text, ant, cons, disable="rst"):
    p = {
        "id": pid,
        "sva_name": name,
        "type": "next_cycle_implication",
        "natural_language": text,
        "antecedent": ant,
        "consequent": cons,
        "delay": 1,
    }
    if disable:
        p["disable"] = disable
    return p


def write(spec):
    d = ROOT / spec["design_id"]
    d.mkdir(parents=True, exist_ok=True)
    (d / "spec.json").write_text(json.dumps(spec, indent=2) + "\n")
    REPLACED.append(spec["design_id"])
    print("WROTE", spec["design_id"])


def fsm(
    design_id, category, template, description,
    inputs, outputs, states, reset_state, state_outputs,
    transitions, properties, mutants,
):
    write({
        "design_id": design_id,
        "category": category,
        "template": template,
        "description": description,
        "clock": {"name": "clk", "edge": "posedge"},
        "reset": {
            "name": "rst",
            "active": "high",
            "synchronous": True,
            "state": reset_state,
        },
        "inputs": inputs,
        "outputs": outputs,
        "states": states,
        "state_outputs": state_outputs,
        "transitions": transitions,
        "rtl_variants": FSM_VARIANTS,
        "notes": [
            "All benchmark properties use interface-visible signals only.",
            "All RTL variants must be observationally equivalent after reset.",
        ],
        "properties": properties,
        "mutants": mutants,
        "provenance": PROVENANCE,
    })


def reg(
    design_id, category, template, description,
    inputs, reg_name, width, reset_value,
    derived_outputs, rules, properties, mutants,
):
    write({
        "design_id": design_id,
        "category": category,
        "model_type": "register_rules",
        "template": template,
        "description": description,
        "clock": {"name": "clk", "edge": "posedge"},
        "reset": {"name": "rst", "active": "high", "synchronous": True},
        "inputs": inputs,
        "outputs": [reg_name] + list(derived_outputs),
        "signal_widths": {reg_name: width},
        "registers": [{
            "name": reg_name,
            "width": width,
            "reset_value": reset_value,
            "observable": True,
        }],
        "derived_outputs": derived_outputs,
        "update_rules": rules,
        "rtl_variants": REG_VARIANTS,
        "notes": [
            "The state register is interface-visible and part of observable equivalence.",
            "All benchmark properties use interface-visible signals only.",
        ],
        "properties": properties,
        "mutants": mutants,
        "provenance": PROVENANCE,
    })


def multi(
    design_id, category, template, description,
    inputs, outputs, signal_widths, registers,
    derived_outputs, update_rules, properties, mutants,
):
    write({
        "design_id": design_id,
        "category": category,
        "model_type": "multi_register_rules",
        "template": template,
        "description": description,
        "clock": {"name": "clk", "edge": "posedge"},
        "reset": {"name": "rst", "active": "high", "synchronous": True},
        "inputs": inputs,
        "outputs": outputs,
        "signal_widths": signal_widths,
        "registers": registers,
        "rtl_variants": REG_VARIANTS,
        "notes": [
            "Properties use interface-visible behavior only.",
            "All RTL variants must be observationally equivalent.",
        ],
        "provenance": PROVENANCE,
        "derived_outputs": derived_outputs,
        "update_rules": update_rules,
        "properties": properties,
        "mutants": mutants,
    })


# ----------------------------------------------------------------------
# SATURATING_ARITHMETIC: replace 5 repetitive register shapes
# ----------------------------------------------------------------------

def sat_0002():
    # Load / increment / decrement with asymmetric saturation.
    reg(
        "saturating_arithmetic_0002",
        "saturating_arithmetic",
        "loadable_bidirectional_saturator",
        "Loadable four-bit accumulator with asymmetric saturating increment and decrement.",
        ["load_mid", "inc", "dec"],
        "value", 4, "4'd8",
        {"at_min": "value == 4'd2", "at_max": "value == 4'd13"},
        [
            {"when": "load_mid", "value": "4'd8"},
            {"when": "!load_mid && inc && !dec && (value < 4'd13)", "value": "value + 4'd1"},
            {"when": "!load_mid && dec && !inc && (value > 4'd2)", "value": "value - 4'd1"},
            {"when": "true", "value": "value"},
        ],
        [
            inv("P1_MIN", "p_min", "at_min reflects the lower saturation point", "at_min == (value == 4'd2)"),
            inv("P2_MAX", "p_max", "at_max reflects the upper saturation point", "at_max == (value == 4'd13)"),
            nxt("P3_RESET", "p_reset", "reset restores the midpoint", "rst", "value == 4'd8", disable=None),
            nxt("P4_LOAD", "p_load", "load_mid restores the midpoint", "load_mid", "value == 4'd8"),
            nxt("P5_INC", "p_inc", "exclusive increment advances below the upper bound",
                "!load_mid && inc && !dec && (value < 4'd13)", "value == ($past(value) + 4'd1)"),
            nxt("P6_DEC", "p_dec", "exclusive decrement advances toward the lower bound",
                "!load_mid && dec && !inc && (value > 4'd2)", "value == ($past(value) - 4'd1)"),
            nxt("P7_BOTH_HOLD", "p_both_hold", "simultaneous increment and decrement cancel",
                "!load_mid && inc && dec", "value == $past(value)"),
        ],
        [
            {"name": "ignore_load", "kind": "replace_update_guard", "old": "load_mid", "new": "false"},
            {"name": "inc_when_both", "kind": "replace_update_guard",
             "old": "!load_mid && inc && !dec && (value < 4'd13)",
             "new": "!load_mid && inc && (value < 4'd13)"},
            {"name": "ignore_decrement", "kind": "replace_update_guard",
             "old": "!load_mid && dec && !inc && (value > 4'd2)", "new": "false"},
        ],
    )


def sat_0004():
    # Sticky saturation event tracked separately from arithmetic value.
    multi(
        "saturating_arithmetic_0004",
        "saturating_arithmetic",
        "sticky_overflow_accumulator",
        "Accumulator saturates at fifteen and latches a sticky overflow indication until clear.",
        ["clear", "add"],
        ["value", "overflowed", "at_max"],
        {"value": 4},
        [
            {"name": "value_reg", "width": 4, "reset_value": "4'd0"},
            {"name": "overflow_reg", "width": 1, "reset_value": "1'b0"},
        ],
        {
            "value": "value_reg",
            "overflowed": "overflow_reg",
            "at_max": "value_reg == 4'd15",
        },
        {
            "value_reg": [
                {"when": "clear", "value": "4'd0"},
                {"when": "!clear && add && (value_reg < 4'd15)", "value": "value_reg + 4'd1"},
                {"when": "true", "value": "value_reg"},
            ],
            "overflow_reg": [
                {"when": "clear", "value": "1'b0"},
                {"when": "!clear && add && (value_reg == 4'd15)", "value": "1'b1"},
                {"when": "true", "value": "overflow_reg"},
            ],
        },
        [
            inv("P1_MAX", "p_max", "at_max matches the saturated arithmetic value", "at_max == (value == 4'd15)"),
            nxt("P2_RESET", "p_reset", "reset clears value and sticky overflow", "rst",
                "(value == 4'd0) && !overflowed", disable=None),
            nxt("P3_CLEAR", "p_clear", "clear resets both outputs", "clear",
                "(value == 4'd0) && !overflowed"),
            nxt("P4_ADD", "p_add", "add increments value below saturation",
                "!clear && add && (value < 4'd15)", "value == ($past(value) + 4'd1)"),
            nxt("P5_OVERFLOW", "p_overflow", "adding at saturation latches overflowed",
                "!clear && add && (value == 4'd15)", "(value == 4'd15) && overflowed"),
            nxt("P6_STICKY", "p_sticky", "overflowed remains set without clear",
                "overflowed && !clear", "overflowed"),
        ],
        [
            {"name": "ignore_clear_overflow", "register": "overflow_reg",
             "kind": "replace_update_guard", "old": "clear", "new": "false"},
            {"name": "never_latch_overflow", "register": "overflow_reg",
             "kind": "replace_update_guard",
             "old": "!clear && add && (value_reg == 4'd15)", "new": "false"},
            {"name": "value_wraps", "register": "value_reg",
             "kind": "insert_update_rule", "before": "true",
             "when": "!clear && add && (value_reg == 4'd15)", "value": "4'd0"},
        ],
    )


def sat_0006():
    # Arithmetic threshold controller as FSM: qualitatively different state semantics.
    fsm(
        "saturating_arithmetic_0006",
        "saturating_arithmetic",
        "three_band_clamped_controller",
        "Three-band arithmetic controller that moves between low, nominal, and high saturation bands.",
        ["raise", "lower"],
        ["low", "nominal", "high"],
        ["LOW", "NOMINAL", "HIGH"],
        "NOMINAL",
        {
            "LOW": {"low": 1, "nominal": 0, "high": 0},
            "NOMINAL": {"low": 0, "nominal": 1, "high": 0},
            "HIGH": {"low": 0, "nominal": 0, "high": 1},
        },
        [
            {"from": "LOW", "when": "raise && !lower", "to": "NOMINAL"},
            {"from": "LOW", "when": "!(raise && !lower)", "to": "LOW"},
            {"from": "NOMINAL", "when": "raise && !lower", "to": "HIGH"},
            {"from": "NOMINAL", "when": "lower && !raise", "to": "LOW"},
            {"from": "NOMINAL", "when": "(raise && lower) || (!raise && !lower)", "to": "NOMINAL"},
            {"from": "HIGH", "when": "lower && !raise", "to": "NOMINAL"},
            {"from": "HIGH", "when": "!(lower && !raise)", "to": "HIGH"},
        ],
        [
            inv("P1_ONEHOT", "p_onehot", "exactly one arithmetic band is observable",
                "$onehot({low, nominal, high})"),
            nxt("P2_RESET", "p_reset", "reset selects the nominal band", "rst", "nominal", disable=None),
            nxt("P3_LOW_UP", "p_low_up", "raising from low enters nominal",
                "low && raise && !lower", "nominal"),
            nxt("P4_NOM_UP", "p_nom_up", "raising from nominal saturates high",
                "nominal && raise && !lower", "high"),
            nxt("P5_NOM_DOWN", "p_nom_down", "lowering from nominal saturates low",
                "nominal && lower && !raise", "low"),
            nxt("P6_HIGH_DOWN", "p_high_down", "lowering from high enters nominal",
                "high && lower && !raise", "nominal"),
            nxt("P7_HIGH_SAT", "p_high_sat", "high remains saturated without an exclusive lower",
                "high && !(lower && !raise)", "high"),
        ],
        [
            {"name": "low_never_rises", "kind": "replace_transition_guard",
             "from": "LOW", "old": "raise && !lower", "new": "false"},
            {"name": "nominal_never_lowers", "kind": "replace_transition_guard",
             "from": "NOMINAL", "old": "lower && !raise", "new": "false"},
            {"name": "high_never_lowers", "kind": "replace_transition_guard",
             "from": "HIGH", "old": "lower && !raise", "new": "false"},
        ],
    )


def sat_0008():
    # Mixed step sizes + explicit clamp priority.
    reg(
        "saturating_arithmetic_0008",
        "saturating_arithmetic",
        "asymmetric_step_saturator",
        "Four-bit accumulator with +2, -1, and clamp-to-center priority behavior.",
        ["center", "boost", "drain"],
        "value", 4, "4'd6",
        {"high": "value >= 4'd10", "low": "value <= 4'd3"},
        [
            {"when": "center", "value": "4'd6"},
            {"when": "!center && boost && !drain && (value <= 4'd11)", "value": "value + 4'd2"},
            {"when": "!center && boost && !drain && (value > 4'd11)", "value": "4'd13"},
            {"when": "!center && drain && !boost && (value > 4'd1)", "value": "value - 4'd1"},
            {"when": "!center && drain && !boost && (value == 4'd1)", "value": "4'd1"},
            {"when": "true", "value": "value"},
        ],
        [
            inv("P1_HIGH", "p_high", "high marks values at or above ten", "high == (value >= 4'd10)"),
            inv("P2_LOW", "p_low", "low marks values at or below three", "low == (value <= 4'd3)"),
            nxt("P3_RESET", "p_reset", "reset restores the center value", "rst", "value == 4'd6", disable=None),
            nxt("P4_CENTER", "p_center", "center has priority over arithmetic updates", "center", "value == 4'd6"),
            nxt("P5_BOOST", "p_boost", "boost adds two when there is room",
                "!center && boost && !drain && (value <= 4'd11)", "value == ($past(value) + 4'd2)"),
            nxt("P6_BOOST_CLAMP", "p_boost_clamp", "boost near the top clamps to thirteen",
                "!center && boost && !drain && (value > 4'd11)", "value == 4'd13"),
            nxt("P7_DRAIN", "p_drain", "drain subtracts one above the lower bound",
                "!center && drain && !boost && (value > 4'd1)", "value == ($past(value) - 4'd1)"),
        ],
        [
            {"name": "ignore_center", "kind": "replace_update_guard", "old": "center", "new": "false"},
            {"name": "boost_never_clamps", "kind": "replace_update_guard",
             "old": "!center && boost && !drain && (value > 4'd11)", "new": "false"},
            {"name": "ignore_drain", "kind": "replace_update_guard",
             "old": "!center && drain && !boost && (value > 4'd1)", "new": "false"},
        ],
    )


def sat_0009():
    # Two-register accumulator with sticky min/max hit history.
    multi(
        "saturating_arithmetic_0009",
        "saturating_arithmetic",
        "saturation_history_accumulator",
        "Accumulator records whether either saturation boundary has ever been reached.",
        ["clear_history", "inc", "dec"],
        ["value", "hit_low", "hit_high"],
        {"value": 3},
        [
            {"name": "value_reg", "width": 3, "reset_value": "3'd3"},
            {"name": "low_reg", "width": 1, "reset_value": "1'b0"},
            {"name": "high_reg", "width": 1, "reset_value": "1'b0"},
        ],
        {
            "value": "value_reg",
            "hit_low": "low_reg",
            "hit_high": "high_reg",
        },
        {
            "value_reg": [
                {"when": "inc && !dec && (value_reg < 3'd6)", "value": "value_reg + 3'd1"},
                {"when": "dec && !inc && (value_reg > 3'd1)", "value": "value_reg - 3'd1"},
                {"when": "true", "value": "value_reg"},
            ],
            "low_reg": [
                {"when": "clear_history", "value": "1'b0"},
                {"when": "dec && !inc && (value_reg == 3'd2)", "value": "1'b1"},
                {"when": "true", "value": "low_reg"},
            ],
            "high_reg": [
                {"when": "clear_history", "value": "1'b0"},
                {"when": "inc && !dec && (value_reg == 3'd5)", "value": "1'b1"},
                {"when": "true", "value": "high_reg"},
            ],
        },
        [
            nxt("P1_RESET", "p_reset", "reset starts at the midpoint with clear history",
                "rst", "(value == 3'd3) && !hit_low && !hit_high", disable=None),
            nxt("P2_INC", "p_inc", "exclusive increment advances below the high bound",
                "inc && !dec && (value < 3'd6)", "value == ($past(value) + 3'd1)"),
            nxt("P3_DEC", "p_dec", "exclusive decrement advances above the low bound",
                "dec && !inc && (value > 3'd1)", "value == ($past(value) - 3'd1)"),
            nxt("P4_HIGH_HISTORY", "p_high_history", "reaching the high boundary records high history",
                "inc && !dec && (value == 3'd5)", "hit_high"),
            nxt("P5_LOW_HISTORY", "p_low_history", "reaching the low boundary records low history",
                "dec && !inc && (value == 3'd2)", "hit_low"),
            nxt("P6_CLEAR_HISTORY", "p_clear_history", "clear_history clears both sticky history bits",
                "clear_history", "!hit_low && !hit_high"),
        ],
        [
            {"name": "never_record_low", "register": "low_reg",
             "kind": "replace_update_guard", "old": "dec && !inc && (value_reg == 3'd2)", "new": "false"},
            {"name": "never_record_high", "register": "high_reg",
             "kind": "replace_update_guard", "old": "inc && !dec && (value_reg == 3'd5)", "new": "false"},
            {"name": "ignore_clear_high", "register": "high_reg",
             "kind": "replace_update_guard", "old": "clear_history", "new": "false"},
        ],
    )


# ----------------------------------------------------------------------
# RATE_LIMITER: replace 3 token-bucket clones with stateful policies
# ----------------------------------------------------------------------

def rate_0002():
    fsm(
        "rate_limiter_0002", "rate_limiter", "cooldown_after_grant",
        "A request is granted once, then blocked until an explicit cooldown tick completes.",
        ["request", "cooldown_done"],
        ["ready", "granted", "blocked"],
        ["READY", "GRANT", "BLOCKED"],
        "READY",
        {
            "READY": {"ready": 1, "granted": 0, "blocked": 0},
            "GRANT": {"ready": 0, "granted": 1, "blocked": 0},
            "BLOCKED": {"ready": 0, "granted": 0, "blocked": 1},
        },
        [
            {"from": "READY", "when": "request", "to": "GRANT"},
            {"from": "READY", "when": "!request", "to": "READY"},
            {"from": "GRANT", "when": "true", "to": "BLOCKED"},
            {"from": "BLOCKED", "when": "cooldown_done", "to": "READY"},
            {"from": "BLOCKED", "when": "!cooldown_done", "to": "BLOCKED"},
        ],
        [
            inv("P1_ONEHOT", "p_onehot", "rate-limiter modes are mutually exclusive", "$onehot({ready, granted, blocked})"),
            nxt("P2_RESET", "p_reset", "reset makes the limiter ready", "rst", "ready", disable=None),
            nxt("P3_GRANT", "p_grant", "a request while ready is granted", "ready && request", "granted"),
            nxt("P4_BLOCK", "p_block", "a grant enters blocked cooldown", "granted", "blocked"),
            nxt("P5_RELEASE", "p_release", "cooldown completion rearms the limiter",
                "blocked && cooldown_done", "ready"),
            nxt("P6_STAY_BLOCKED", "p_stay_blocked", "without cooldown completion the limiter remains blocked",
                "blocked && !cooldown_done", "blocked"),
        ],
        [
            {"name": "grant_without_request", "kind": "replace_transition_guard",
             "from": "READY", "old": "request", "new": "true"},
            {"name": "never_release", "kind": "replace_transition_guard",
             "from": "BLOCKED", "old": "cooldown_done", "new": "false"},
            {"name": "skip_block", "kind": "force_transition", "from": "GRANT", "to": "READY"},
        ],
    )


def rate_0004():
    fsm(
        "rate_limiter_0004", "rate_limiter", "two_burst_lockout",
        "Allows two grants in a burst, then enters lockout until reset_window.",
        ["request", "reset_window"],
        ["ready_first", "ready_last", "granted", "locked"],
        ["FIRST", "GRANT1", "LAST", "GRANT2", "LOCKED"],
        "FIRST",
        {
            "FIRST": {"ready_first": 1, "ready_last": 0, "granted": 0, "locked": 0},
            "GRANT1": {"ready_first": 0, "ready_last": 0, "granted": 1, "locked": 0},
            "LAST": {"ready_first": 0, "ready_last": 1, "granted": 0, "locked": 0},
            "GRANT2": {"ready_first": 0, "ready_last": 0, "granted": 1, "locked": 0},
            "LOCKED": {"ready_first": 0, "ready_last": 0, "granted": 0, "locked": 1},
        },
        [
            {"from": "FIRST", "when": "request", "to": "GRANT1"},
            {"from": "FIRST", "when": "!request", "to": "FIRST"},
            {"from": "GRANT1", "when": "true", "to": "LAST"},
            {"from": "LAST", "when": "request", "to": "GRANT2"},
            {"from": "LAST", "when": "!request", "to": "LAST"},
            {"from": "GRANT2", "when": "true", "to": "LOCKED"},
            {"from": "LOCKED", "when": "reset_window", "to": "FIRST"},
            {"from": "LOCKED", "when": "!reset_window", "to": "LOCKED"},
        ],
        [
            inv("P1_ONEHOT", "p_onehot", "burst limiter modes are mutually exclusive",
                "$onehot({ready_first, ready_last, granted, locked})"),
            nxt("P2_RESET", "p_reset", "reset restores the first burst slot", "rst", "ready_first", disable=None),
            nxt("P3_FIRST_GRANT", "p_first_grant", "the first request is granted",
                "ready_first && request", "granted"),
            nxt("P4_LAST_SLOT", "p_last_slot", "after the first grant only one slot remains",
                "granted && !$past(ready_last)", "ready_last"),
            nxt("P5_SECOND_GRANT", "p_second_grant", "a request in the last slot is granted",
                "ready_last && request", "granted"),
            nxt("P6_LOCK", "p_lock", "the second grant enters lockout",
                "granted && $past(ready_last)", "locked"),
            nxt("P7_WINDOW_RESET", "p_window_reset", "reset_window releases lockout",
                "locked && reset_window", "ready_first"),
        ],
        [
            {"name": "first_never_grants", "kind": "replace_transition_guard",
             "from": "FIRST", "old": "request", "new": "false"},
            {"name": "second_never_grants", "kind": "replace_transition_guard",
             "from": "LAST", "old": "request", "new": "false"},
            {"name": "never_unlock", "kind": "replace_transition_guard",
             "from": "LOCKED", "old": "reset_window", "new": "false"},
        ],
    )


def rate_0007():
    multi(
        "rate_limiter_0007", "rate_limiter", "windowed_quota",
        "Windowed quota tracks both requests used and the current phase before quota reset.",
        ["request", "advance_window"],
        ["used", "phase", "allow", "exhausted"],
        {"used": 2, "phase": 2},
        [
            {"name": "used_reg", "width": 2, "reset_value": "2'd0"},
            {"name": "phase_reg", "width": 2, "reset_value": "2'd0"},
        ],
        {
            "used": "used_reg",
            "phase": "phase_reg",
            "allow": "used_reg < 2'd3",
            "exhausted": "used_reg == 2'd3",
        },
        {
            "used_reg": [
                {"when": "advance_window", "value": "2'd0"},
                {"when": "!advance_window && request && (used_reg < 2'd3)", "value": "used_reg + 2'd1"},
                {"when": "true", "value": "used_reg"},
            ],
            "phase_reg": [
                {"when": "advance_window && (phase_reg < 2'd3)", "value": "phase_reg + 2'd1"},
                {"when": "advance_window && (phase_reg == 2'd3)", "value": "2'd0"},
                {"when": "true", "value": "phase_reg"},
            ],
        },
        [
            inv("P1_ALLOW", "p_allow", "allow is true until three requests are used", "allow == (used < 2'd3)"),
            inv("P2_EXHAUSTED", "p_exhausted", "exhausted is true at quota three", "exhausted == (used == 2'd3)"),
            nxt("P3_RESET", "p_reset", "reset starts at phase zero with unused quota",
                "rst", "(used == 2'd0) && (phase == 2'd0)", disable=None),
            nxt("P4_USE", "p_use", "an allowed request consumes one unit",
                "!advance_window && request && (used < 2'd3)", "used == ($past(used) + 2'd1)"),
            nxt("P5_NEW_WINDOW", "p_new_window", "advancing the window resets quota usage",
                "advance_window", "used == 2'd0"),
            nxt("P6_PHASE_ADV", "p_phase_adv", "advance_window increments phase before wrap",
                "advance_window && (phase < 2'd3)", "phase == ($past(phase) + 2'd1)"),
            nxt("P7_EXHAUST_HOLD", "p_exhaust_hold", "requests cannot exceed the exhausted quota",
                "!advance_window && request && exhausted", "used == 2'd3"),
        ],
        [
            {"name": "never_reset_quota", "register": "used_reg",
             "kind": "replace_update_guard", "old": "advance_window", "new": "false"},
            {"name": "ignore_request", "register": "used_reg",
             "kind": "replace_update_guard",
             "old": "!advance_window && request && (used_reg < 2'd3)", "new": "false"},
            {"name": "never_wrap_phase", "register": "phase_reg",
             "kind": "replace_update_guard",
             "old": "advance_window && (phase_reg == 2'd3)", "new": "false"},
        ],
    )


# ----------------------------------------------------------------------
# FIFO: replace two mailbox clones with occupancy/control semantics
# ----------------------------------------------------------------------

def fifo_0007():
    fsm(
        "fifo_0007", "fifo_control", "two_slot_occupancy_fsm",
        "Two-slot FIFO occupancy controller exposing empty, one-entry, and full states.",
        ["push", "pop"],
        ["empty", "one", "full"],
        ["EMPTY", "ONE", "FULL"],
        "EMPTY",
        {
            "EMPTY": {"empty": 1, "one": 0, "full": 0},
            "ONE": {"empty": 0, "one": 1, "full": 0},
            "FULL": {"empty": 0, "one": 0, "full": 1},
        },
        [
            {"from": "EMPTY", "when": "push", "to": "ONE"},
            {"from": "EMPTY", "when": "!push", "to": "EMPTY"},
            {"from": "ONE", "when": "push && !pop", "to": "FULL"},
            {"from": "ONE", "when": "pop && !push", "to": "EMPTY"},
            {"from": "ONE", "when": "(push && pop) || (!push && !pop)", "to": "ONE"},
            {"from": "FULL", "when": "pop", "to": "ONE"},
            {"from": "FULL", "when": "!pop", "to": "FULL"},
        ],
        [
            inv("P1_ONEHOT", "p_onehot", "exactly one occupancy state is visible",
                "$onehot({empty, one, full})"),
            nxt("P2_RESET", "p_reset", "reset empties the FIFO", "rst", "empty", disable=None),
            nxt("P3_EMPTY_PUSH", "p_empty_push", "pushing an empty FIFO creates one entry",
                "empty && push", "one"),
            nxt("P4_ONE_PUSH", "p_one_push", "push without pop fills a one-entry FIFO",
                "one && push && !pop", "full"),
            nxt("P5_ONE_POP", "p_one_pop", "pop without push empties a one-entry FIFO",
                "one && pop && !push", "empty"),
            nxt("P6_SIMULTANEOUS", "p_simultaneous", "simultaneous push and pop preserves one-entry occupancy",
                "one && push && pop", "one"),
            nxt("P7_FULL_POP", "p_full_pop", "popping a full FIFO leaves one entry",
                "full && pop", "one"),
        ],
        [
            {"name": "empty_ignores_push", "kind": "replace_transition_guard",
             "from": "EMPTY", "old": "push", "new": "false"},
            {"name": "one_never_fills", "kind": "replace_transition_guard",
             "from": "ONE", "old": "push && !pop", "new": "false"},
            {"name": "full_ignores_pop", "kind": "replace_transition_guard",
             "from": "FULL", "old": "pop", "new": "false"},
        ],
    )


def fifo_0010():
    reg(
        "fifo_0010", "fifo_control", "four_slot_occupancy_counter",
        "Four-slot FIFO occupancy counter with simultaneous push/pop cancellation and overflow/underflow protection.",
        ["push", "pop", "flush"],
        "count", 3, "3'd0",
        {
            "empty": "count == 3'd0",
            "full": "count == 3'd4",
            "almost_full": "count >= 3'd3",
        },
        [
            {"when": "flush", "value": "3'd0"},
            {"when": "!flush && push && !pop && (count < 3'd4)", "value": "count + 3'd1"},
            {"when": "!flush && pop && !push && (count > 3'd0)", "value": "count - 3'd1"},
            {"when": "true", "value": "count"},
        ],
        [
            inv("P1_EMPTY", "p_empty", "empty reflects zero occupancy", "empty == (count == 3'd0)"),
            inv("P2_FULL", "p_full", "full reflects four entries", "full == (count == 3'd4)"),
            inv("P3_AF", "p_almost_full", "almost_full reflects occupancy of at least three", "almost_full == (count >= 3'd3)"),
            nxt("P4_RESET", "p_reset", "reset empties the FIFO", "rst", "count == 3'd0", disable=None),
            nxt("P5_FLUSH", "p_flush", "flush empties the FIFO", "flush", "count == 3'd0"),
            nxt("P6_PUSH", "p_push", "push without pop increments occupancy",
                "!flush && push && !pop && (count < 3'd4)", "count == ($past(count) + 3'd1)"),
            nxt("P7_POP", "p_pop", "pop without push decrements occupancy",
                "!flush && pop && !push && (count > 3'd0)", "count == ($past(count) - 3'd1)"),
            nxt("P8_SIMULTANEOUS", "p_simultaneous", "simultaneous push and pop preserves occupancy",
                "!flush && push && pop", "count == $past(count)"),
        ],
        [
            {"name": "ignore_flush", "kind": "replace_update_guard", "old": "flush", "new": "false"},
            {"name": "push_without_space", "kind": "replace_update_guard",
             "old": "!flush && push && !pop && (count < 3'd4)",
             "new": "!flush && push && !pop"},
            {"name": "ignore_pop", "kind": "replace_update_guard",
             "old": "!flush && pop && !push && (count > 3'd0)", "new": "false"},
        ],
    )


# ----------------------------------------------------------------------
# PROTOCOL: replace one repeated wait/done shape
# ----------------------------------------------------------------------

def protocol_0003():
    fsm(
        "protocol_controller_0003", "protocol_controller", "prepare_commit_abort",
        "Transactional protocol with prepare, commit, and abort recovery phases.",
        ["start", "prepared", "commit", "abort", "recover"],
        ["preparing", "ready_commit", "committed", "aborted"],
        ["IDLE", "PREPARE", "READY", "COMMITTED", "ABORTED"],
        "IDLE",
        {
            "IDLE": {"preparing": 0, "ready_commit": 0, "committed": 0, "aborted": 0},
            "PREPARE": {"preparing": 1, "ready_commit": 0, "committed": 0, "aborted": 0},
            "READY": {"preparing": 0, "ready_commit": 1, "committed": 0, "aborted": 0},
            "COMMITTED": {"preparing": 0, "ready_commit": 0, "committed": 1, "aborted": 0},
            "ABORTED": {"preparing": 0, "ready_commit": 0, "committed": 0, "aborted": 1},
        },
        [
            {"from": "IDLE", "when": "start", "to": "PREPARE"},
            {"from": "IDLE", "when": "!start", "to": "IDLE"},
            {"from": "PREPARE", "when": "abort", "to": "ABORTED"},
            {"from": "PREPARE", "when": "!abort && prepared", "to": "READY"},
            {"from": "PREPARE", "when": "!abort && !prepared", "to": "PREPARE"},
            {"from": "READY", "when": "abort", "to": "ABORTED"},
            {"from": "READY", "when": "!abort && commit", "to": "COMMITTED"},
            {"from": "READY", "when": "!abort && !commit", "to": "READY"},
            {"from": "COMMITTED", "when": "true", "to": "IDLE"},
            {"from": "ABORTED", "when": "recover", "to": "IDLE"},
            {"from": "ABORTED", "when": "!recover", "to": "ABORTED"},
        ],
        [
            inv("P1_ONEHOT", "p_onehot", "protocol phases are mutually exclusive",
                "$onehot0({preparing, ready_commit, committed, aborted})"),
            nxt("P2_RESET", "p_reset", "reset returns the protocol to idle",
                "rst", "!preparing && !ready_commit && !committed && !aborted", disable=None),
            nxt("P3_START", "p_start", "start begins prepare", "!preparing && !ready_commit && !committed && !aborted && start", "preparing"),
            nxt("P4_PREPARED", "p_prepared", "prepared advances to commit-ready",
                "preparing && prepared && !abort", "ready_commit"),
            nxt("P5_ABORT_PREP", "p_abort_prep", "abort during prepare enters aborted",
                "preparing && abort", "aborted"),
            nxt("P6_COMMIT", "p_commit", "commit from ready completes the transaction",
                "ready_commit && commit && !abort", "committed"),
            nxt("P7_RECOVER", "p_recover", "recover leaves aborted state",
                "aborted && recover", "!preparing && !ready_commit && !committed && !aborted"),
        ],
        [
            {"name": "ignore_prepare_abort", "kind": "replace_transition_guard",
             "from": "PREPARE", "old": "abort", "new": "false"},
            {"name": "ignore_commit", "kind": "replace_transition_guard",
             "from": "READY", "old": "!abort && commit", "new": "false"},
            {"name": "never_recover", "kind": "replace_transition_guard",
             "from": "ABORTED", "old": "recover", "new": "false"},
        ],
    )


# ----------------------------------------------------------------------
# PULSE: replace one one-shot clone with a debounce detector
# ----------------------------------------------------------------------

def pulse_0005():
    fsm(
        "pulse_event_0005", "pulse_event", "two_sample_debounced_pulse",
        "Pulse generator requires two consecutive high samples before firing and two low samples before rearming.",
        ["event_in"],
        ["armed", "qualifying", "pulse", "rearming"],
        ["ARMED", "HIGH1", "PULSE", "WAIT_LOW", "LOW1"],
        "ARMED",
        {
            "ARMED": {"armed": 1, "qualifying": 0, "pulse": 0, "rearming": 0},
            "HIGH1": {"armed": 0, "qualifying": 1, "pulse": 0, "rearming": 0},
            "PULSE": {"armed": 0, "qualifying": 0, "pulse": 1, "rearming": 0},
            "WAIT_LOW": {"armed": 0, "qualifying": 0, "pulse": 0, "rearming": 1},
            "LOW1": {"armed": 0, "qualifying": 0, "pulse": 0, "rearming": 1},
        },
        [
            {"from": "ARMED", "when": "event_in", "to": "HIGH1"},
            {"from": "ARMED", "when": "!event_in", "to": "ARMED"},
            {"from": "HIGH1", "when": "event_in", "to": "PULSE"},
            {"from": "HIGH1", "when": "!event_in", "to": "ARMED"},
            {"from": "PULSE", "when": "true", "to": "WAIT_LOW"},
            {"from": "WAIT_LOW", "when": "!event_in", "to": "LOW1"},
            {"from": "WAIT_LOW", "when": "event_in", "to": "WAIT_LOW"},
            {"from": "LOW1", "when": "!event_in", "to": "ARMED"},
            {"from": "LOW1", "when": "event_in", "to": "WAIT_LOW"},
        ],
        [
            inv("P1_ONEHOT", "p_onehot", "debounce phases are mutually exclusive",
                "$onehot0({armed, qualifying, pulse})"),
            nxt("P2_RESET", "p_reset", "reset arms the detector", "rst", "armed", disable=None),
            nxt("P3_FIRST_HIGH", "p_first_high", "the first high sample begins qualification",
                "armed && event_in", "qualifying"),
            nxt("P4_SECOND_HIGH", "p_second_high", "a second consecutive high sample emits a pulse",
                "qualifying && event_in", "pulse"),
            nxt("P5_GLITCH", "p_glitch", "a one-cycle high glitch does not emit a pulse",
                "qualifying && !event_in", "armed"),
            nxt("P6_FIRST_LOW", "p_first_low", "the first low after a pulse begins rearming",
                "rearming && !event_in", "rearming || armed"),
            nxt("P7_HIGH_INTERRUPTS_REARM", "p_high_interrupt", "a high sample interrupts low rearming",
                "rearming && event_in", "rearming"),
        ],
        [
            {"name": "fire_after_one_high", "kind": "force_transition", "from": "ARMED", "to": "PULSE"},
            {"name": "never_fire", "kind": "replace_transition_guard", "from": "HIGH1",
             "old": "event_in", "new": "false"},
            {"name": "rearm_after_one_low", "kind": "force_transition", "from": "WAIT_LOW", "to": "ARMED"},
        ],
    )


def build():
    sat_0002()
    sat_0004()
    sat_0006()
    sat_0008()
    sat_0009()

    rate_0002()
    rate_0004()
    rate_0007()

    fifo_0007()
    fifo_0010()

    protocol_0003()
    pulse_0005()


def regenerate():
    for design_id in REPLACED:
        d = ROOT / design_id

        # Remove only generated artifacts for the rewritten family so stale
        # mutant names or RTL files cannot survive.
        for child in ("rtl", "mutants", "properties"):
            p = d / child
            if p.exists():
                shutil.rmtree(p)

        spec_path = d / "spec.json"
        spec = json.loads(spec_path.read_text())
        mt = spec.get("model_type")

        if mt == "register_rules":
            gen = "generator/generate_register_family.py"
        elif mt == "multi_register_rules":
            gen = "generator/generate_multi_register_family.py"
        else:
            gen = "generator/generate_family.py"

        print("GENERATE", design_id)
        subprocess.run([sys.executable, gen, "--spec", str(spec_path)], check=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--generate", action="store_true")
    args = ap.parse_args()

    build()

    print(f"\nReplaced {len(REPLACED)} repetitive v2 families.")

    if args.generate:
        regenerate()
        print("\nRegeneration complete. No formal validation was run.")


if __name__ == "__main__":
    main()
