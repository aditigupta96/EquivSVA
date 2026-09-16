#!/usr/bin/env python3
"""
Replace only v2-added families that are exact behavioral clones.

This script does not touch any original v1 family.
With --generate it regenerates only the rewritten families.
It never runs formal validation.
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


def inv(pid, name, nl, expr, disable="rst"):
    p = {
        "id": pid,
        "sva_name": name,
        "type": "invariant",
        "natural_language": nl,
        "expression": expr,
    }
    if disable:
        p["disable"] = disable
    return p


def nxt(pid, name, nl, ant, cons, disable="rst"):
    p = {
        "id": pid,
        "sva_name": name,
        "type": "next_cycle_implication",
        "natural_language": nl,
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


def fsm(design_id, category, template, description,
        inputs, outputs, states, reset_state, state_outputs,
        transitions, properties, mutants):
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


def reg(design_id, category, template, description,
        inputs, reg_name, width, reset_value,
        derived_outputs, rules, properties, mutants):
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


def multi(design_id, category, template, description,
          inputs, outputs, signal_widths, registers,
          derived_outputs, update_rules, properties, mutants):
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


# 1) Replace saturating_arithmetic_0003
def build_sat3():
    multi(
        "saturating_arithmetic_0003",
        "saturating_arithmetic",
        "clamped_accumulator_with_direction",
        "Clamped accumulator records the direction of the most recent successful update.",
        ["clear", "inc", "dec"],
        ["value", "last_up", "last_down", "at_low", "at_high"],
        {"value": 3},
        [
            {"name": "value_reg", "width": 3, "reset_value": "3'd3"},
            {"name": "dir_reg", "width": 2, "reset_value": "2'd0"},
        ],
        {
            "value": "value_reg",
            "last_up": "dir_reg == 2'd1",
            "last_down": "dir_reg == 2'd2",
            "at_low": "value_reg == 3'd1",
            "at_high": "value_reg == 3'd6",
        },
        {
            "value_reg": [
                {"when": "clear", "value": "3'd3"},
                {"when": "!clear && inc && !dec && (value_reg < 3'd6)", "value": "value_reg + 3'd1"},
                {"when": "!clear && dec && !inc && (value_reg > 3'd1)", "value": "value_reg - 3'd1"},
                {"when": "true", "value": "value_reg"},
            ],
            "dir_reg": [
                {"when": "clear", "value": "2'd0"},
                {"when": "!clear && inc && !dec && (value_reg < 3'd6)", "value": "2'd1"},
                {"when": "!clear && dec && !inc && (value_reg > 3'd1)", "value": "2'd2"},
                {"when": "true", "value": "dir_reg"},
            ],
        },
        [
            inv("P1_LOW", "p_low", "at_low reflects the lower clamp", "at_low == (value == 3'd1)"),
            inv("P2_HIGH", "p_high", "at_high reflects the upper clamp", "at_high == (value == 3'd6)"),
            inv("P3_DIR_MUTEX", "p_dir_mutex", "last_up and last_down are mutually exclusive", "!(last_up && last_down)"),
            nxt("P4_RESET", "p_reset", "reset restores midpoint and clears direction", "rst",
                "(value == 3'd3) && !last_up && !last_down", disable=None),
            nxt("P5_INC", "p_inc", "successful increment advances value and records upward direction",
                "!clear && inc && !dec && (value < 3'd6)",
                "(value == ($past(value) + 3'd1)) && last_up"),
            nxt("P6_DEC", "p_dec", "successful decrement advances value and records downward direction",
                "!clear && dec && !inc && (value > 3'd1)",
                "(value == ($past(value) - 3'd1)) && last_down"),
        ],
        [
            {"name": "ignore_inc_value", "register": "value_reg", "kind": "replace_update_guard",
             "old": "!clear && inc && !dec && (value_reg < 3'd6)", "new": "false"},
            {"name": "ignore_dec_direction", "register": "dir_reg", "kind": "replace_update_guard",
             "old": "!clear && dec && !inc && (value_reg > 3'd1)", "new": "false"},
            {"name": "ignore_clear_direction", "register": "dir_reg", "kind": "replace_update_guard",
             "old": "clear", "new": "false"},
        ],
    )


# 2) Replace saturating_arithmetic_0005
def build_sat5():
    reg(
        "saturating_arithmetic_0005",
        "saturating_arithmetic",
        "priority_asymmetric_steps",
        "Priority arithmetic unit with reset-to-center, +3 boost, and -2 drain.",
        ["center", "boost", "drain"],
        "value", 4, "4'd6",
        {"high": "value >= 4'd9", "low": "value <= 4'd3"},
        [
            {"when": "center", "value": "4'd6"},
            {"when": "!center && boost && (value <= 4'd9)", "value": "value + 4'd3"},
            {"when": "!center && boost && (value > 4'd9)", "value": "4'd12"},
            {"when": "!center && !boost && drain && (value >= 4'd4)", "value": "value - 4'd2"},
            {"when": "!center && !boost && drain && (value < 4'd4)", "value": "4'd2"},
            {"when": "true", "value": "value"},
        ],
        [
            inv("P1_HIGH", "p_high", "high reflects values nine and above", "high == (value >= 4'd9)"),
            inv("P2_LOW", "p_low", "low reflects values three and below", "low == (value <= 4'd3)"),
            nxt("P3_RESET", "p_reset", "reset restores center value", "rst", "value == 4'd6", disable=None),
            nxt("P4_CENTER", "p_center", "center has priority", "center", "value == 4'd6"),
            nxt("P5_BOOST", "p_boost", "boost adds three when not near the upper clamp",
                "!center && boost && (value <= 4'd9)", "value == ($past(value) + 4'd3)"),
            nxt("P6_DRAIN", "p_drain", "drain subtracts two when boost is absent",
                "!center && !boost && drain && (value >= 4'd4)", "value == ($past(value) - 4'd2)"),
        ],
        [
            {"name": "ignore_center", "kind": "replace_update_guard", "old": "center", "new": "false"},
            {"name": "ignore_boost", "kind": "replace_update_guard",
             "old": "!center && boost && (value <= 4'd9)", "new": "false"},
            {"name": "ignore_drain", "kind": "replace_update_guard",
             "old": "!center && !boost && drain && (value >= 4'd4)", "new": "false"},
        ],
    )


# 3) Replace protocol_controller_0002
def build_protocol2():
    fsm(
        "protocol_controller_0002",
        "protocol_controller",
        "authorize_execute_complete",
        "Request must be authorized before execution can begin and then complete.",
        ["request", "authorized", "complete", "cancel"],
        ["authorizing", "executing", "done", "cancelled"],
        ["IDLE", "AUTH", "EXEC", "DONE", "CANCEL"],
        "IDLE",
        {
            "IDLE": {"authorizing": 0, "executing": 0, "done": 0, "cancelled": 0},
            "AUTH": {"authorizing": 1, "executing": 0, "done": 0, "cancelled": 0},
            "EXEC": {"authorizing": 0, "executing": 1, "done": 0, "cancelled": 0},
            "DONE": {"authorizing": 0, "executing": 0, "done": 1, "cancelled": 0},
            "CANCEL": {"authorizing": 0, "executing": 0, "done": 0, "cancelled": 1},
        },
        [
            {"from": "IDLE", "when": "request", "to": "AUTH"},
            {"from": "IDLE", "when": "!request", "to": "IDLE"},
            {"from": "AUTH", "when": "cancel", "to": "CANCEL"},
            {"from": "AUTH", "when": "!cancel && authorized", "to": "EXEC"},
            {"from": "AUTH", "when": "!cancel && !authorized", "to": "AUTH"},
            {"from": "EXEC", "when": "cancel", "to": "CANCEL"},
            {"from": "EXEC", "when": "!cancel && complete", "to": "DONE"},
            {"from": "EXEC", "when": "!cancel && !complete", "to": "EXEC"},
            {"from": "DONE", "when": "true", "to": "IDLE"},
            {"from": "CANCEL", "when": "true", "to": "IDLE"},
        ],
        [
            inv("P1_MUTEX", "p_mutex", "protocol output phases are mutually exclusive",
                "$onehot0({authorizing, executing, done, cancelled})"),
            nxt("P2_RESET", "p_reset", "reset returns to idle", "rst",
                "!authorizing && !executing && !done && !cancelled", disable=None),
            nxt("P3_REQUEST", "p_request", "a request begins authorization",
                "!authorizing && !executing && !done && !cancelled && request", "authorizing"),
            nxt("P4_AUTH", "p_auth", "authorization begins execution",
                "authorizing && authorized && !cancel", "executing"),
            nxt("P5_CANCEL_AUTH", "p_cancel_auth", "cancel during authorization terminates the request",
                "authorizing && cancel", "cancelled"),
            nxt("P6_COMPLETE", "p_complete", "completion ends execution successfully",
                "executing && complete && !cancel", "done"),
        ],
        [
            {"name": "ignore_authorized", "kind": "replace_transition_guard", "from": "AUTH",
             "old": "!cancel && authorized", "new": "false"},
            {"name": "ignore_exec_cancel", "kind": "replace_transition_guard", "from": "EXEC",
             "old": "cancel", "new": "false"},
            {"name": "never_complete", "kind": "replace_transition_guard", "from": "EXEC",
             "old": "!cancel && complete", "new": "false"},
        ],
    )


# 4) Replace protocol_controller_0004
def build_protocol4():
    fsm(
        "protocol_controller_0004",
        "protocol_controller",
        "retry_then_fail",
        "Operation can retry once before succeeding or entering a terminal failure state.",
        ["start", "success", "retry", "reset_fail"],
        ["attempting", "retrying", "done", "failed"],
        ["IDLE", "ATTEMPT1", "RETRY", "ATTEMPT2", "DONE", "FAILED"],
        "IDLE",
        {
            "IDLE": {"attempting": 0, "retrying": 0, "done": 0, "failed": 0},
            "ATTEMPT1": {"attempting": 1, "retrying": 0, "done": 0, "failed": 0},
            "RETRY": {"attempting": 0, "retrying": 1, "done": 0, "failed": 0},
            "ATTEMPT2": {"attempting": 1, "retrying": 0, "done": 0, "failed": 0},
            "DONE": {"attempting": 0, "retrying": 0, "done": 1, "failed": 0},
            "FAILED": {"attempting": 0, "retrying": 0, "done": 0, "failed": 1},
        },
        [
            {"from": "IDLE", "when": "start", "to": "ATTEMPT1"},
            {"from": "IDLE", "when": "!start", "to": "IDLE"},
            {"from": "ATTEMPT1", "when": "success", "to": "DONE"},
            {"from": "ATTEMPT1", "when": "!success && retry", "to": "RETRY"},
            {"from": "ATTEMPT1", "when": "!success && !retry", "to": "FAILED"},
            {"from": "RETRY", "when": "true", "to": "ATTEMPT2"},
            {"from": "ATTEMPT2", "when": "success", "to": "DONE"},
            {"from": "ATTEMPT2", "when": "!success", "to": "FAILED"},
            {"from": "DONE", "when": "true", "to": "IDLE"},
            {"from": "FAILED", "when": "reset_fail", "to": "IDLE"},
            {"from": "FAILED", "when": "!reset_fail", "to": "FAILED"},
        ],
        [
            inv("P1_MUTEX", "p_mutex", "terminal and active phases are mutually exclusive",
                "$onehot0({retrying, done, failed}) && !(attempting && (retrying || done || failed))"),
            nxt("P2_RESET", "p_reset", "reset returns to idle", "rst",
                "!attempting && !retrying && !done && !failed", disable=None),
            nxt("P3_START", "p_start", "start begins the first attempt",
                "!attempting && !retrying && !done && !failed && start", "attempting"),
            nxt("P4_RETRY", "p_retry", "retry request after first failure enters retry state",
                "attempting && !success && retry && !$past(retrying)", "retrying || failed"),
            nxt("P5_DONE", "p_done", "success from an attempt enters done",
                "attempting && success", "done"),
            nxt("P6_FAIL_STICKY", "p_fail_sticky", "failure remains until reset_fail",
                "failed && !reset_fail", "failed"),
        ],
        [
            {"name": "first_success_ignored", "kind": "replace_transition_guard", "from": "ATTEMPT1",
             "old": "success", "new": "false"},
            {"name": "second_success_ignored", "kind": "replace_transition_guard", "from": "ATTEMPT2",
             "old": "success", "new": "false"},
            {"name": "failure_never_resets", "kind": "replace_transition_guard", "from": "FAILED",
             "old": "reset_fail", "new": "false"},
        ],
    )


# 5) Replace interrupt_0007
def build_interrupt7():
    fsm(
        "interrupt_0007",
        "interrupt_control",
        "masked_hold_then_service",
        "Interrupt can become pending, be held by a later mask, then resume and service.",
        ["irq", "mask", "ack"],
        ["pending", "held_masked", "servicing"],
        ["IDLE", "PENDING", "HELD", "SERVICE"],
        "IDLE",
        {
            "IDLE": {"pending": 0, "held_masked": 0, "servicing": 0},
            "PENDING": {"pending": 1, "held_masked": 0, "servicing": 0},
            "HELD": {"pending": 0, "held_masked": 1, "servicing": 0},
            "SERVICE": {"pending": 0, "held_masked": 0, "servicing": 1},
        },
        [
            {"from": "IDLE", "when": "irq && !mask", "to": "PENDING"},
            {"from": "IDLE", "when": "!(irq && !mask)", "to": "IDLE"},
            {"from": "PENDING", "when": "mask", "to": "HELD"},
            {"from": "PENDING", "when": "!mask && ack", "to": "SERVICE"},
            {"from": "PENDING", "when": "!mask && !ack", "to": "PENDING"},
            {"from": "HELD", "when": "mask", "to": "HELD"},
            {"from": "HELD", "when": "!mask", "to": "PENDING"},
            {"from": "SERVICE", "when": "true", "to": "IDLE"},
        ],
        [
            inv("P1_ONEHOT", "p_onehot", "interrupt control phases are mutually exclusive",
                "$onehot0({pending, held_masked, servicing})"),
            nxt("P2_RESET", "p_reset", "reset returns to idle", "rst",
                "!pending && !held_masked && !servicing", disable=None),
            nxt("P3_CAPTURE", "p_capture", "unmasked irq becomes pending",
                "!pending && !held_masked && !servicing && irq && !mask", "pending"),
            nxt("P4_MASK_HOLD", "p_mask_hold", "masking a pending interrupt holds it",
                "pending && mask", "held_masked"),
            nxt("P5_UNMASK", "p_unmask", "unmasking a held interrupt returns it to pending",
                "held_masked && !mask", "pending"),
            nxt("P6_SERVICE", "p_service", "acknowledging an unmasked pending interrupt services it",
                "pending && !mask && ack", "servicing"),
        ],
        [
            {"name": "ignore_mask_pending", "kind": "replace_transition_guard", "from": "PENDING",
             "old": "mask", "new": "false"},
            {"name": "never_unmask", "kind": "replace_transition_guard", "from": "HELD",
             "old": "!mask", "new": "false"},
            {"name": "ignore_ack", "kind": "replace_transition_guard", "from": "PENDING",
             "old": "!mask && ack", "new": "false"},
        ],
    )


# 6) Replace interrupt_0009
def build_interrupt9():
    fsm(
        "interrupt_0009",
        "interrupt_control",
        "service_then_rearm_low",
        "Interrupt service waits for irq to deassert before rearming.",
        ["irq", "ack"],
        ["pending", "servicing", "wait_low", "armed"],
        ["ARMED", "PENDING", "SERVICE", "WAIT_LOW"],
        "ARMED",
        {
            "ARMED": {"pending": 0, "servicing": 0, "wait_low": 0, "armed": 1},
            "PENDING": {"pending": 1, "servicing": 0, "wait_low": 0, "armed": 0},
            "SERVICE": {"pending": 0, "servicing": 1, "wait_low": 0, "armed": 0},
            "WAIT_LOW": {"pending": 0, "servicing": 0, "wait_low": 1, "armed": 0},
        },
        [
            {"from": "ARMED", "when": "irq", "to": "PENDING"},
            {"from": "ARMED", "when": "!irq", "to": "ARMED"},
            {"from": "PENDING", "when": "ack", "to": "SERVICE"},
            {"from": "PENDING", "when": "!ack", "to": "PENDING"},
            {"from": "SERVICE", "when": "true", "to": "WAIT_LOW"},
            {"from": "WAIT_LOW", "when": "irq", "to": "WAIT_LOW"},
            {"from": "WAIT_LOW", "when": "!irq", "to": "ARMED"},
        ],
        [
            inv("P1_ONEHOT", "p_onehot", "interrupt phases are mutually exclusive",
                "$onehot({pending, servicing, wait_low, armed})"),
            nxt("P2_RESET", "p_reset", "reset arms interrupt capture", "rst", "armed", disable=None),
            nxt("P3_IRQ", "p_irq", "irq while armed becomes pending", "armed && irq", "pending"),
            nxt("P4_ACK", "p_ack", "acknowledge services a pending interrupt", "pending && ack", "servicing"),
            nxt("P5_WAIT_LOW", "p_wait_low", "service completion waits for irq deassertion", "servicing", "wait_low"),
            nxt("P6_REARM", "p_rearm", "irq deassertion rearms capture", "wait_low && !irq", "armed"),
        ],
        [
            {"name": "ignore_irq", "kind": "replace_transition_guard", "from": "ARMED",
             "old": "irq", "new": "false"},
            {"name": "ignore_ack", "kind": "replace_transition_guard", "from": "PENDING",
             "old": "ack", "new": "false"},
            {"name": "premature_rearm", "kind": "force_transition", "from": "SERVICE", "to": "ARMED"},
        ],
    )


# 7) Replace protocol_controller_0008
def build_protocol8():
    fsm(
        "protocol_controller_0008",
        "protocol_controller",
        "open_auth_transfer_close",
        "Session protocol opens, authenticates, transfers, closes, then signals completion.",
        ["open_ok", "auth_ok", "transfer_done", "close_ok", "abort"],
        ["opening", "authenticating", "transferring", "closing", "done", "failed"],
        ["OPEN", "AUTH", "TRANSFER", "CLOSE", "DONE", "FAILED"],
        "OPEN",
        {
            "OPEN": {"opening": 1, "authenticating": 0, "transferring": 0, "closing": 0, "done": 0, "failed": 0},
            "AUTH": {"opening": 0, "authenticating": 1, "transferring": 0, "closing": 0, "done": 0, "failed": 0},
            "TRANSFER": {"opening": 0, "authenticating": 0, "transferring": 1, "closing": 0, "done": 0, "failed": 0},
            "CLOSE": {"opening": 0, "authenticating": 0, "transferring": 0, "closing": 1, "done": 0, "failed": 0},
            "DONE": {"opening": 0, "authenticating": 0, "transferring": 0, "closing": 0, "done": 1, "failed": 0},
            "FAILED": {"opening": 0, "authenticating": 0, "transferring": 0, "closing": 0, "done": 0, "failed": 1},
        },
        [
            {"from": "OPEN", "when": "abort", "to": "FAILED"},
            {"from": "OPEN", "when": "!abort && open_ok", "to": "AUTH"},
            {"from": "OPEN", "when": "!abort && !open_ok", "to": "OPEN"},
            {"from": "AUTH", "when": "abort", "to": "FAILED"},
            {"from": "AUTH", "when": "!abort && auth_ok", "to": "TRANSFER"},
            {"from": "AUTH", "when": "!abort && !auth_ok", "to": "AUTH"},
            {"from": "TRANSFER", "when": "abort", "to": "FAILED"},
            {"from": "TRANSFER", "when": "!abort && transfer_done", "to": "CLOSE"},
            {"from": "TRANSFER", "when": "!abort && !transfer_done", "to": "TRANSFER"},
            {"from": "CLOSE", "when": "abort", "to": "FAILED"},
            {"from": "CLOSE", "when": "!abort && close_ok", "to": "DONE"},
            {"from": "CLOSE", "when": "!abort && !close_ok", "to": "CLOSE"},
            {"from": "DONE", "when": "true", "to": "OPEN"},
            {"from": "FAILED", "when": "true", "to": "OPEN"},
        ],
        [
            inv("P1_ONEHOT", "p_onehot", "session phases are mutually exclusive",
                "$onehot({opening, authenticating, transferring, closing, done, failed})"),
            nxt("P2_RESET", "p_reset", "reset begins in opening phase", "rst", "opening", disable=None),
            nxt("P3_OPEN", "p_open", "successful open advances to authentication",
                "opening && open_ok && !abort", "authenticating"),
            nxt("P4_AUTH", "p_auth", "successful authentication begins transfer",
                "authenticating && auth_ok && !abort", "transferring"),
            nxt("P5_TRANSFER", "p_transfer", "completed transfer enters closing",
                "transferring && transfer_done && !abort", "closing"),
            nxt("P6_CLOSE", "p_close", "successful close completes the session",
                "closing && close_ok && !abort", "done"),
            nxt("P7_ABORT", "p_abort", "abort from an active phase produces failure",
                "(opening || authenticating || transferring || closing) && abort", "failed"),
        ],
        [
            {"name": "ignore_auth", "kind": "replace_transition_guard", "from": "AUTH",
             "old": "!abort && auth_ok", "new": "false"},
            {"name": "ignore_transfer_done", "kind": "replace_transition_guard", "from": "TRANSFER",
             "old": "!abort && transfer_done", "new": "false"},
            {"name": "ignore_close", "kind": "replace_transition_guard", "from": "CLOSE",
             "old": "!abort && close_ok", "new": "false"},
        ],
    )


# 8) Replace rate_limiter_0002
def build_rate2():
    multi(
        "rate_limiter_0002",
        "rate_limiter",
        "fixed_window_quota_with_epoch",
        "Fixed-window limiter tracks quota usage and toggles an observable epoch on window reset.",
        ["request", "new_window"],
        ["used", "epoch", "allow", "exhausted"],
        {"used": 2},
        [
            {"name": "used_reg", "width": 2, "reset_value": "2'd0"},
            {"name": "epoch_reg", "width": 1, "reset_value": "1'b0"},
        ],
        {
            "used": "used_reg",
            "epoch": "epoch_reg",
            "allow": "used_reg < 2'd3",
            "exhausted": "used_reg == 2'd3",
        },
        {
            "used_reg": [
                {"when": "new_window", "value": "2'd0"},
                {"when": "!new_window && request && (used_reg < 2'd3)", "value": "used_reg + 2'd1"},
                {"when": "true", "value": "used_reg"},
            ],
            "epoch_reg": [
                {"when": "new_window", "value": "!epoch_reg"},
                {"when": "true", "value": "epoch_reg"},
            ],
        },
        [
            inv("P1_ALLOW", "p_allow", "allow is true before quota exhaustion", "allow == (used < 2'd3)"),
            inv("P2_EXHAUSTED", "p_exhausted", "exhausted marks full quota usage", "exhausted == (used == 2'd3)"),
            nxt("P3_RESET", "p_reset", "reset starts with unused quota and epoch zero", "rst",
                "(used == 2'd0) && !epoch", disable=None),
            nxt("P4_USE", "p_use", "an allowed request consumes one quota unit",
                "!new_window && request && (used < 2'd3)", "used == ($past(used) + 2'd1)"),
            nxt("P5_WINDOW", "p_window", "new window clears quota usage",
                "new_window", "used == 2'd0"),
            nxt("P6_EPOCH", "p_epoch", "new window toggles the epoch marker",
                "new_window", "epoch != $past(epoch)"),
            nxt("P7_HOLD", "p_hold", "without request or window reset usage holds",
                "!new_window && !request", "used == $past(used)"),
        ],
        [
            {"name": "never_reset_usage", "register": "used_reg",
             "kind": "replace_update_guard", "old": "new_window", "new": "false"},
            {"name": "ignore_request", "register": "used_reg",
             "kind": "replace_update_guard", "old": "!new_window && request && (used_reg < 2'd3)", "new": "false"},
            {"name": "epoch_never_toggles", "register": "epoch_reg",
             "kind": "replace_update_guard", "old": "new_window", "new": "false"},
        ],
    )


# 9) Replace pulse_event_0010
def build_pulse10():
    fsm(
        "pulse_event_0010",
        "pulse_event",
        "qualified_arm_fire_rearm",
        "Pulse requires explicit arm, a trigger, then explicit rearm after firing.",
        ["arm", "trigger", "rearm"],
        ["disarmed", "armed", "pulse", "spent"],
        ["DISARMED", "ARMED", "PULSE", "SPENT"],
        "DISARMED",
        {
            "DISARMED": {"disarmed": 1, "armed": 0, "pulse": 0, "spent": 0},
            "ARMED": {"disarmed": 0, "armed": 1, "pulse": 0, "spent": 0},
            "PULSE": {"disarmed": 0, "armed": 0, "pulse": 1, "spent": 0},
            "SPENT": {"disarmed": 0, "armed": 0, "pulse": 0, "spent": 1},
        },
        [
            {"from": "DISARMED", "when": "arm", "to": "ARMED"},
            {"from": "DISARMED", "when": "!arm", "to": "DISARMED"},
            {"from": "ARMED", "when": "trigger", "to": "PULSE"},
            {"from": "ARMED", "when": "!trigger", "to": "ARMED"},
            {"from": "PULSE", "when": "true", "to": "SPENT"},
            {"from": "SPENT", "when": "rearm", "to": "ARMED"},
            {"from": "SPENT", "when": "!rearm", "to": "SPENT"},
        ],
        [
            inv("P1_ONEHOT", "p_onehot", "event detector modes are mutually exclusive",
                "$onehot({disarmed, armed, pulse, spent})"),
            nxt("P2_RESET", "p_reset", "reset disarms the detector", "rst", "disarmed", disable=None),
            nxt("P3_ARM", "p_arm", "arm enables triggering", "disarmed && arm", "armed"),
            nxt("P4_FIRE", "p_fire", "trigger while armed emits a pulse", "armed && trigger", "pulse"),
            nxt("P5_SPENT", "p_spent", "a pulse becomes spent after one cycle", "pulse", "spent"),
            nxt("P6_REARM", "p_rearm", "explicit rearm makes a spent detector armed again",
                "spent && rearm", "armed"),
        ],
        [
            {"name": "arm_ignored", "kind": "replace_transition_guard", "from": "DISARMED",
             "old": "arm", "new": "false"},
            {"name": "trigger_ignored", "kind": "replace_transition_guard", "from": "ARMED",
             "old": "trigger", "new": "false"},
            {"name": "premature_rearm", "kind": "force_transition", "from": "PULSE", "to": "ARMED"},
        ],
    )


# 10) Replace rate_limiter_0010
def build_rate10():
    fsm(
        "rate_limiter_0010",
        "rate_limiter",
        "three_strike_lockout",
        "Three consecutive violations move the limiter into lockout until clear.",
        ["violation", "clear"],
        ["clean", "strike1", "strike2", "blocked"],
        ["CLEAN", "S1", "S2", "BLOCKED"],
        "CLEAN",
        {
            "CLEAN": {"clean": 1, "strike1": 0, "strike2": 0, "blocked": 0},
            "S1": {"clean": 0, "strike1": 1, "strike2": 0, "blocked": 0},
            "S2": {"clean": 0, "strike1": 0, "strike2": 1, "blocked": 0},
            "BLOCKED": {"clean": 0, "strike1": 0, "strike2": 0, "blocked": 1},
        },
        [
            {"from": "CLEAN", "when": "violation", "to": "S1"},
            {"from": "CLEAN", "when": "!violation", "to": "CLEAN"},
            {"from": "S1", "when": "violation", "to": "S2"},
            {"from": "S1", "when": "!violation", "to": "CLEAN"},
            {"from": "S2", "when": "violation", "to": "BLOCKED"},
            {"from": "S2", "when": "!violation", "to": "CLEAN"},
            {"from": "BLOCKED", "when": "clear", "to": "CLEAN"},
            {"from": "BLOCKED", "when": "!clear", "to": "BLOCKED"},
        ],
        [
            inv("P1_ONEHOT", "p_onehot", "strike states are mutually exclusive",
                "$onehot({clean, strike1, strike2, blocked})"),
            nxt("P2_RESET", "p_reset", "reset clears all strikes", "rst", "clean", disable=None),
            nxt("P3_FIRST", "p_first", "first consecutive violation records strike one",
                "clean && violation", "strike1"),
            nxt("P4_SECOND", "p_second", "second consecutive violation records strike two",
                "strike1 && violation", "strike2"),
            nxt("P5_THIRD", "p_third", "third consecutive violation enters lockout",
                "strike2 && violation", "blocked"),
            nxt("P6_RECOVER_SEQUENCE", "p_recover_sequence", "a clean cycle before lockout clears strikes",
                "(strike1 || strike2) && !violation", "clean"),
            nxt("P7_CLEAR", "p_clear", "clear releases lockout", "blocked && clear", "clean"),
        ],
        [
            {"name": "first_strike_ignored", "kind": "replace_transition_guard", "from": "CLEAN",
             "old": "violation", "new": "false"},
            {"name": "third_strike_ignored", "kind": "replace_transition_guard", "from": "S2",
             "old": "violation", "new": "false"},
            {"name": "lockout_never_clears", "kind": "replace_transition_guard", "from": "BLOCKED",
             "old": "clear", "new": "false"},
        ],
    )


# 11) Replace timer_0006
def build_timer6():
    fsm(
        "timer_0006",
        "timer_watchdog",
        "three_phase_watchdog",
        "Watchdog progresses through warning and timeout phases and is reset by kick.",
        ["tick", "kick"],
        ["armed", "warning", "timeout"],
        ["ARMED", "WARN", "TIMEOUT"],
        "ARMED",
        {
            "ARMED": {"armed": 1, "warning": 0, "timeout": 0},
            "WARN": {"armed": 0, "warning": 1, "timeout": 0},
            "TIMEOUT": {"armed": 0, "warning": 0, "timeout": 1},
        },
        [
            {"from": "ARMED", "when": "kick", "to": "ARMED"},
            {"from": "ARMED", "when": "!kick && tick", "to": "WARN"},
            {"from": "ARMED", "when": "!kick && !tick", "to": "ARMED"},
            {"from": "WARN", "when": "kick", "to": "ARMED"},
            {"from": "WARN", "when": "!kick && tick", "to": "TIMEOUT"},
            {"from": "WARN", "when": "!kick && !tick", "to": "WARN"},
            {"from": "TIMEOUT", "when": "kick", "to": "ARMED"},
            {"from": "TIMEOUT", "when": "!kick", "to": "TIMEOUT"},
        ],
        [
            inv("P1_ONEHOT", "p_onehot", "watchdog phases are mutually exclusive",
                "$onehot({armed, warning, timeout})"),
            nxt("P2_RESET", "p_reset", "reset arms the watchdog", "rst", "armed", disable=None),
            nxt("P3_WARN", "p_warn", "first un-kicked tick enters warning",
                "armed && !kick && tick", "warning"),
            nxt("P4_TIMEOUT", "p_timeout", "second un-kicked tick enters timeout",
                "warning && !kick && tick", "timeout"),
            nxt("P5_KICK_WARN", "p_kick_warn", "kick from warning rearms the watchdog",
                "warning && kick", "armed"),
            nxt("P6_KICK_TIMEOUT", "p_kick_timeout", "kick from timeout rearms the watchdog",
                "timeout && kick", "armed"),
            nxt("P7_TIMEOUT_STICKY", "p_timeout_sticky", "timeout persists without kick",
                "timeout && !kick", "timeout"),
        ],
        [
            {"name": "warning_skipped", "kind": "force_transition", "from": "ARMED", "to": "TIMEOUT"},
            {"name": "never_timeout", "kind": "replace_transition_guard", "from": "WARN",
             "old": "!kick && tick", "new": "false"},
            {"name": "kick_ignored_timeout", "kind": "replace_transition_guard", "from": "TIMEOUT",
             "old": "kick", "new": "false"},
        ],
    )


def build_all():
    build_sat3()
    build_sat5()
    build_protocol2()
    build_protocol4()
    build_interrupt7()
    build_interrupt9()
    build_protocol8()
    build_rate2()
    build_pulse10()
    build_rate10()
    build_timer6()


def regenerate():
    for design_id in REPLACED:
        d = ROOT / design_id

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

    build_all()
    print(f"\nReplaced {len(REPLACED)} exact-clone v2 families.")

    if args.generate:
        regenerate()
        print("\nRegeneration complete. No formal validation was run.")


if __name__ == "__main__":
    main()
