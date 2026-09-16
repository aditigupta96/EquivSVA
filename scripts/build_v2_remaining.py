#!/usr/bin/env python3
"""
Build the remaining EquivSVA v2 BehaviorSpecs.

Target after running this script:
  12 categories x 10 families = 120 families total.

This script creates only the remaining 84 specs:
  - +5 each for the six original categories (30)
  - +9 each for the six new categories after the validated pilot (54)

It does NOT run formal verification.

Usage:
  python scripts/build_v2_remaining.py
  python scripts/build_v2_remaining.py --generate

With --generate, it invokes the existing EquivSVA generators after writing/checking
the specs. It still does not run validate_family.py or any SBY jobs.
"""

import argparse
import copy
import json
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
    "behavior_spec_creation": "programmatic_template_instantiation",
    "rtl_generation": "programmatic_from_behavior_spec",
    "derived_from_external_benchmark": False,
}


def write_spec(spec):
    d = ROOT / spec["design_id"]
    d.mkdir(parents=True, exist_ok=True)
    p = d / "spec.json"
    text = json.dumps(spec, indent=2) + "\n"

    if p.exists():
        old = json.loads(p.read_text())
        if old != spec:
            raise RuntimeError(f"Existing spec differs: {p}")
        print("SKIP ", p)
        return

    p.write_text(text)
    print("WROTE", p)


def next_prop(pid, name, nl, antecedent, consequent, disable="rst"):
    d = {
        "id": pid,
        "sva_name": name,
        "type": "next_cycle_implication",
        "natural_language": nl,
        "antecedent": antecedent,
        "consequent": consequent,
        "delay": 1,
    }
    if disable:
        d["disable"] = disable
    return d


def inv_prop(pid, name, nl, expr, disable="rst"):
    d = {
        "id": pid,
        "sva_name": name,
        "type": "invariant",
        "natural_language": nl,
        "expression": expr,
    }
    if disable:
        d["disable"] = disable
    return d


def state_pred(outputs, values):
    terms = []
    for o in outputs:
        v = values[o]
        terms.append(o if v else f"!{o}")
    return " && ".join(terms) if terms else "1'b1"


def make_fsm(
    design_id,
    category,
    template,
    description,
    inputs,
    outputs,
    states,
    reset_state,
    state_outputs,
    transitions,
    mutant_transition_indices=(0, 1, 2),
    notes=None,
):
    props = [
        inv_prop(
            "P1_STATE_ENCODING",
            "p_state_encoding",
            "observable state outputs always encode at most one active mode",
            "$onehot0({" + ", ".join(outputs) + "})",
        ),
        next_prop(
            "P2_RESET",
            "p_reset_state",
            "reset returns the controller to its reset behavior",
            "rst",
            state_pred(outputs, state_outputs[reset_state]),
            disable=None,
        ),
    ]

    for i, t in enumerate(transitions, start=3):
        src = state_pred(outputs, state_outputs[t["from"]])
        dst = state_pred(outputs, state_outputs[t["to"]])
        guard = t["when"]
        ant = src if guard == "true" else f"({src}) && ({guard})"
        props.append(
            next_prop(
                f"P{i}_T{i-2}",
                f"p_t{i-2}",
                f"{t['from']} transitions to {t['to']} when {guard}",
                ant,
                dst,
            )
        )

    nontrivial = [
        i for i, t in enumerate(transitions)
        if t["when"] != "true" and t["from"] != t["to"]
    ]
    chosen = []
    for idx in mutant_transition_indices:
        if (
            idx < len(transitions)
            and transitions[idx]["when"] != "true"
            and transitions[idx]["from"] != transitions[idx]["to"]
        ):
            chosen.append(idx)
    for i in nontrivial:
        if len(chosen) >= 3:
            break
        if i not in chosen:
            chosen.append(i)
    chosen = chosen[:3]

    mutants = []
    for n, idx in enumerate(chosen, start=1):
        t = transitions[idx]
        mutants.append(
            {
                "name": f"drop_t{idx+1}",
                "kind": "replace_transition_guard",
                "from": t["from"],
                "old": t["when"],
                "new": "false",
            }
        )

    # Some FSMs have fewer than three guarded transitions.
    # Fill the remaining mutant slots by redirecting an
    # unconditional transition to a different valid state.
    if len(mutants) < 3:
        for idx, t in enumerate(transitions):
            if t["when"] != "true":
                continue

            if t["to"] != reset_state:
                alternate = reset_state
            else:
                alternate = next(
                    (state for state in states if state != t["to"]),
                    None,
                )

            if alternate is None or alternate == t["to"]:
                continue

            mutants.append(
                {
                    "name": f"redirect_t{idx+1}",
                    "kind": "force_transition",
                    "from": t["from"],
                    "to": alternate,
                }
            )

            if len(mutants) == 3:
                break

    if len(mutants) != 3:
        raise RuntimeError(
            f"{design_id}: expected exactly 3 mutants, got {len(mutants)}"
        )

    spec = {
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
        "notes": notes or [
            "All benchmark properties use interface-visible signals only.",
            "All RTL variants must be observationally equivalent after reset.",
        ],
        "properties": props,
        "mutants": mutants,
        "provenance": PROVENANCE,
    }
    write_spec(spec)


def past_expr(expr, reg):
    # Register-rule values below intentionally use only constants and the register
    # itself, so this conservative substitution is sufficient.
    return expr.replace(reg, f"$past({reg})")


def make_register(
    design_id,
    category,
    template,
    description,
    inputs,
    reg,
    width,
    reset_value,
    derived_outputs,
    rules,
    mutants,
    notes=None,
):
    outputs = [reg] + list(derived_outputs)
    sigw = {reg: width}

    props = [
        next_prop(
            "P1_RESET",
            "p_reset_value",
            "reset restores the register to its reset value",
            "rst",
            f"{reg} == {reset_value}",
            disable=None,
        )
    ]

    pnum = 2
    for out, expr in derived_outputs.items():
        props.append(
            inv_prop(
                f"P{pnum}_{out.upper()}",
                f"p_{out}",
                f"{out} is consistent with the observable register value",
                f"{out} == ({expr})",
            )
        )
        pnum += 1

    action_guards = []
    for r in rules:
        if r["when"] == "true":
            continue
        action_guards.append(r["when"])
        props.append(
            next_prop(
                f"P{pnum}_RULE",
                f"p_rule_{pnum}",
                f"update rule {r['when']} produces the specified next value",
                r["when"],
                f"{reg} == ({past_expr(r['value'], reg)})",
            )
        )
        pnum += 1

    if action_guards:
        hold_ant = " && ".join(f"!({g})" for g in action_guards)
        props.append(
            next_prop(
                f"P{pnum}_HOLD",
                "p_hold",
                "when no update rule fires the register holds its value",
                hold_ant,
                f"{reg} == $past({reg})",
            )
        )

    spec = {
        "design_id": design_id,
        "category": category,
        "model_type": "register_rules",
        "template": template,
        "description": description,
        "clock": {"name": "clk", "edge": "posedge"},
        "reset": {"name": "rst", "active": "high", "synchronous": True},
        "inputs": inputs,
        "outputs": outputs,
        "signal_widths": sigw,
        "registers": [
            {
                "name": reg,
                "width": width,
                "reset_value": reset_value,
                "observable": True,
            }
        ],
        "derived_outputs": derived_outputs,
        "update_rules": rules,
        "rtl_variants": REG_VARIANTS,
        "notes": notes or [
            "The state register is interface-visible and part of observable equivalence.",
            "All benchmark properties use interface-visible signals only.",
        ],
        "properties": props,
        "mutants": mutants,
        "provenance": PROVENANCE,
    }
    write_spec(spec)


def make_fifo(
    design_id,
    template,
    description,
    inputs,
    registers,
    derived_outputs,
    update_rules,
    properties,
    mutants,
):
    outputs = list(derived_outputs)
    widths = {}
    for r in registers:
        if r["width"] > 1:
            widths[r["name"]] = r["width"]
    for name, expr in derived_outputs.items():
        # Explicit widths are added by callers when output aliases a data register.
        pass

    spec = {
        "design_id": design_id,
        "category": "fifo_control",
        "model_type": "multi_register_rules",
        "template": template,
        "description": description,
        "clock": {"name": "clk", "edge": "posedge"},
        "reset": {"name": "rst", "active": "high", "synchronous": True},
        "inputs": inputs,
        "outputs": outputs,
        "signal_widths": {},
        "registers": registers,
        "rtl_variants": REG_VARIANTS,
        "notes": [
            "Properties use interface-visible behavior only.",
            "All variants must be observationally equivalent.",
        ],
        "provenance": PROVENANCE,
        "derived_outputs": derived_outputs,
        "update_rules": update_rules,
        "properties": properties,
        "mutants": mutants,
    }

    # Infer widths for simple output aliases and the conventional data input.
    reg_width = {r["name"]: r["width"] for r in registers}
    data_width = None
    for out, expr in derived_outputs.items():
        if expr in reg_width and reg_width[expr] > 1:
            spec["signal_widths"][out] = reg_width[expr]
            if out == "dout":
                data_width = reg_width[expr]
    if "din" in inputs and data_width:
        spec["signal_widths"]["din"] = data_width

    write_spec(spec)


# ---------------------------------------------------------------------------
# ORIGINAL CATEGORY EXPANSION: +5 EACH
# ---------------------------------------------------------------------------

def build_handshakes():
    configs = [
        (
            "handshake_0006",
            "held_request_ack",
            "Request remains active until acknowledge, then waits for request release.",
            ["req", "accept"],
            ["busy", "ack"],
            ["IDLE", "WAIT", "ACK"],
            {
                "IDLE": {"busy": 0, "ack": 0},
                "WAIT": {"busy": 1, "ack": 0},
                "ACK": {"busy": 0, "ack": 1},
            },
            [
                {"from": "IDLE", "when": "req", "to": "WAIT"},
                {"from": "IDLE", "when": "!req", "to": "IDLE"},
                {"from": "WAIT", "when": "accept", "to": "ACK"},
                {"from": "WAIT", "when": "!accept", "to": "WAIT"},
                {"from": "ACK", "when": "req", "to": "ACK"},
                {"from": "ACK", "when": "!req", "to": "IDLE"},
            ],
        ),
        (
            "handshake_0007",
            "valid_ready_completion",
            "Producer raises valid, waits for ready, then emits a completion state.",
            ["produce", "ready"],
            ["valid", "done"],
            ["IDLE", "VALID", "DONE"],
            {
                "IDLE": {"valid": 0, "done": 0},
                "VALID": {"valid": 1, "done": 0},
                "DONE": {"valid": 0, "done": 1},
            },
            [
                {"from": "IDLE", "when": "produce", "to": "VALID"},
                {"from": "IDLE", "when": "!produce", "to": "IDLE"},
                {"from": "VALID", "when": "ready", "to": "DONE"},
                {"from": "VALID", "when": "!ready", "to": "VALID"},
                {"from": "DONE", "when": "true", "to": "IDLE"},
            ],
        ),
        (
            "handshake_0008",
            "retry_handshake",
            "Request can be accepted, retried, or completed.",
            ["req", "accept", "retry"],
            ["busy", "retrying", "done"],
            ["IDLE", "WAIT", "RETRY", "DONE"],
            {
                "IDLE": {"busy": 0, "retrying": 0, "done": 0},
                "WAIT": {"busy": 1, "retrying": 0, "done": 0},
                "RETRY": {"busy": 0, "retrying": 1, "done": 0},
                "DONE": {"busy": 0, "retrying": 0, "done": 1},
            },
            [
                {"from": "IDLE", "when": "req", "to": "WAIT"},
                {"from": "IDLE", "when": "!req", "to": "IDLE"},
                {"from": "WAIT", "when": "retry", "to": "RETRY"},
                {"from": "WAIT", "when": "!retry && accept", "to": "DONE"},
                {"from": "WAIT", "when": "!retry && !accept", "to": "WAIT"},
                {"from": "RETRY", "when": "true", "to": "WAIT"},
                {"from": "DONE", "when": "true", "to": "IDLE"},
            ],
        ),
        (
            "handshake_0009",
            "cancelable_valid_ready",
            "Valid/ready transfer can be cancelled before acceptance.",
            ["start", "ready", "cancel"],
            ["valid", "cancelled", "done"],
            ["IDLE", "VALID", "CANCEL", "DONE"],
            {
                "IDLE": {"valid": 0, "cancelled": 0, "done": 0},
                "VALID": {"valid": 1, "cancelled": 0, "done": 0},
                "CANCEL": {"valid": 0, "cancelled": 1, "done": 0},
                "DONE": {"valid": 0, "cancelled": 0, "done": 1},
            },
            [
                {"from": "IDLE", "when": "start", "to": "VALID"},
                {"from": "IDLE", "when": "!start", "to": "IDLE"},
                {"from": "VALID", "when": "cancel", "to": "CANCEL"},
                {"from": "VALID", "when": "!cancel && ready", "to": "DONE"},
                {"from": "VALID", "when": "!cancel && !ready", "to": "VALID"},
                {"from": "CANCEL", "when": "true", "to": "IDLE"},
                {"from": "DONE", "when": "true", "to": "IDLE"},
            ],
        ),
        (
            "handshake_0010",
            "two_phase_release",
            "Two-phase handshake waits for request assertion, acknowledge, and request release.",
            ["req", "peer_ack"],
            ["waiting", "acked", "release"],
            ["IDLE", "WAIT_ACK", "ACKED", "WAIT_RELEASE"],
            {
                "IDLE": {"waiting": 0, "acked": 0, "release": 0},
                "WAIT_ACK": {"waiting": 1, "acked": 0, "release": 0},
                "ACKED": {"waiting": 0, "acked": 1, "release": 0},
                "WAIT_RELEASE": {"waiting": 0, "acked": 0, "release": 1},
            },
            [
                {"from": "IDLE", "when": "req", "to": "WAIT_ACK"},
                {"from": "IDLE", "when": "!req", "to": "IDLE"},
                {"from": "WAIT_ACK", "when": "peer_ack", "to": "ACKED"},
                {"from": "WAIT_ACK", "when": "!peer_ack", "to": "WAIT_ACK"},
                {"from": "ACKED", "when": "true", "to": "WAIT_RELEASE"},
                {"from": "WAIT_RELEASE", "when": "req", "to": "WAIT_RELEASE"},
                {"from": "WAIT_RELEASE", "when": "!req", "to": "IDLE"},
            ],
        ),
    ]

    for cfg in configs:
        make_fsm(
            cfg[0], "handshake", cfg[1], cfg[2],
            cfg[3], cfg[4], cfg[5], "IDLE", cfg[6], cfg[7]
        )


def build_timers():
    configs = [
        ("timer_0006", "saturating_elapsed_timer", "Elapsed-cycle timer that saturates at seven.",
         ["clear", "tick"], "elapsed", 3, "3'd0",
         {"expired": "elapsed == 3'd7"},
         [
             {"when": "clear", "value": "3'd0"},
             {"when": "tick && (elapsed < 3'd7)", "value": "elapsed + 3'd1"},
             {"when": "true", "value": "elapsed"},
         ],
         [
             {"name": "ignore_clear", "kind": "replace_update_guard", "old": "clear", "new": "false"},
             {"name": "ignore_tick", "kind": "replace_update_guard", "old": "tick && (elapsed < 3'd7)", "new": "false"},
             {"name": "tick_without_enable", "kind": "replace_update_guard", "old": "tick && (elapsed < 3'd7)", "new": "elapsed < 3'd7"},
         ]),
        ("timer_0007", "countdown_timer", "Countdown timer loaded to seven and decremented on tick.",
         ["load", "tick"], "remaining", 3, "3'd0",
         {"expired": "remaining == 3'd0"},
         [
             {"when": "load", "value": "3'd7"},
             {"when": "!load && tick && (remaining > 3'd0)", "value": "remaining - 3'd1"},
             {"when": "true", "value": "remaining"},
         ],
         [
             {"name": "ignore_load", "kind": "replace_update_guard", "old": "load", "new": "false"},
             {"name": "ignore_tick", "kind": "replace_update_guard", "old": "!load && tick && (remaining > 3'd0)", "new": "false"},
             {"name": "count_without_tick", "kind": "replace_update_guard", "old": "!load && tick && (remaining > 3'd0)", "new": "!load && (remaining > 3'd0)"},
         ]),
        ("timer_0008", "reloadable_watchdog", "Watchdog increments until kick resets it and saturates at timeout.",
         ["kick", "tick"], "age", 3, "3'd0",
         {"timeout": "age == 3'd7"},
         [
             {"when": "kick", "value": "3'd0"},
             {"when": "!kick && tick && (age < 3'd7)", "value": "age + 3'd1"},
             {"when": "true", "value": "age"},
         ],
         [
             {"name": "ignore_kick", "kind": "replace_update_guard", "old": "kick", "new": "false"},
             {"name": "ignore_tick", "kind": "replace_update_guard", "old": "!kick && tick && (age < 3'd7)", "new": "false"},
             {"name": "age_without_tick", "kind": "replace_update_guard", "old": "!kick && tick && (age < 3'd7)", "new": "!kick && (age < 3'd7)"},
         ]),
        ("timer_0009", "pausable_timer", "Pausable elapsed timer with clear and enable.",
         ["clear", "enable"], "count", 3, "3'd0",
         {"done": "count == 3'd5"},
         [
             {"when": "clear", "value": "3'd0"},
             {"when": "!clear && enable && (count < 3'd5)", "value": "count + 3'd1"},
             {"when": "true", "value": "count"},
         ],
         [
             {"name": "ignore_clear", "kind": "replace_update_guard", "old": "clear", "new": "false"},
             {"name": "ignore_enable", "kind": "replace_update_guard", "old": "!clear && enable && (count < 3'd5)", "new": "!clear && (count < 3'd5)"},
             {"name": "never_advance", "kind": "replace_update_guard", "old": "!clear && enable && (count < 3'd5)", "new": "false"},
         ]),
        ("timer_0010", "periodic_phase_timer", "Modulo-eight phase timer with synchronous restart.",
         ["restart", "tick"], "phase", 3, "3'd0",
         {"terminal": "phase == 3'd7"},
         [
             {"when": "restart", "value": "3'd0"},
             {"when": "!restart && tick && (phase < 3'd7)", "value": "phase + 3'd1"},
             {"when": "!restart && tick && (phase == 3'd7)", "value": "3'd0"},
             {"when": "true", "value": "phase"},
         ],
         [
             {"name": "ignore_restart", "kind": "replace_update_guard", "old": "restart", "new": "false"},
             {"name": "stop_at_terminal", "kind": "replace_update_guard", "old": "!restart && tick && (phase == 3'd7)", "new": "false"},
             {"name": "ignore_tick", "kind": "replace_update_guard", "old": "!restart && tick && (phase < 3'd7)", "new": "false"},
         ]),
    ]

    for c in configs:
        make_register(c[0], "timer_watchdog", c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9])


def build_counters():
    configs = [
        ("counter_0006", "modulo_six_counter", "Modulo-six counter with clear and enable.",
         ["clear", "enable"], "count", 3, "3'd0", {"terminal": "count == 3'd5"},
         [
             {"when": "clear", "value": "3'd0"},
             {"when": "!clear && enable && (count < 3'd5)", "value": "count + 3'd1"},
             {"when": "!clear && enable && (count == 3'd5)", "value": "3'd0"},
             {"when": "true", "value": "count"},
         ],
         [
             {"name": "ignore_clear", "kind": "replace_update_guard", "old": "clear", "new": "false"},
             {"name": "fail_wrap", "kind": "replace_update_guard", "old": "!clear && enable && (count == 3'd5)", "new": "false"},
             {"name": "ignore_enable", "kind": "replace_update_guard", "old": "!clear && enable && (count < 3'd5)", "new": "!clear && (count < 3'd5)"},
         ]),
        ("counter_0007", "saturating_down_counter", "Saturating down-counter starting from seven.",
         ["reload", "enable"], "count", 3, "3'd7", {"at_zero": "count == 3'd0"},
         [
             {"when": "reload", "value": "3'd7"},
             {"when": "!reload && enable && (count > 3'd0)", "value": "count - 3'd1"},
             {"when": "true", "value": "count"},
         ],
         [
             {"name": "ignore_reload", "kind": "replace_update_guard", "old": "reload", "new": "false"},
             {"name": "ignore_enable", "kind": "replace_update_guard", "old": "!reload && enable && (count > 3'd0)", "new": "!reload && (count > 3'd0)"},
             {"name": "never_decrement", "kind": "replace_update_guard", "old": "!reload && enable && (count > 3'd0)", "new": "false"},
         ]),
        ("counter_0008", "step_two_counter", "Counter advances by two and saturates at six.",
         ["clear", "step"], "count", 3, "3'd0", {"at_limit": "count == 3'd6"},
         [
             {"when": "clear", "value": "3'd0"},
             {"when": "!clear && step && (count < 3'd6)", "value": "count + 3'd2"},
             {"when": "true", "value": "count"},
         ],
         [
             {"name": "ignore_clear", "kind": "replace_update_guard", "old": "clear", "new": "false"},
             {"name": "step_without_request", "kind": "replace_update_guard", "old": "!clear && step && (count < 3'd6)", "new": "!clear && (count < 3'd6)"},
             {"name": "never_step", "kind": "replace_update_guard", "old": "!clear && step && (count < 3'd6)", "new": "false"},
         ]),
        ("counter_0009", "bounded_up_down_counter", "Three-bit up/down counter bounded at zero and seven.",
         ["up", "down"], "count", 3, "3'd0",
         {"at_zero": "count == 3'd0", "at_max": "count == 3'd7"},
         [
             {"when": "up && !down && (count < 3'd7)", "value": "count + 3'd1"},
             {"when": "down && !up && (count > 3'd0)", "value": "count - 3'd1"},
             {"when": "true", "value": "count"},
         ],
         [
             {"name": "ignore_up", "kind": "replace_update_guard", "old": "up && !down && (count < 3'd7)", "new": "false"},
             {"name": "ignore_down", "kind": "replace_update_guard", "old": "down && !up && (count > 3'd0)", "new": "false"},
             {"name": "up_when_both", "kind": "replace_update_guard", "old": "up && !down && (count < 3'd7)", "new": "up && (count < 3'd7)"},
         ]),
        ("counter_0010", "priority_load_counter", "Loadable counter where load has priority over increment.",
         ["load", "increment"], "count", 3, "3'd0", {"nonzero": "count != 3'd0"},
         [
             {"when": "load", "value": "3'd4"},
             {"when": "!load && increment && (count < 3'd7)", "value": "count + 3'd1"},
             {"when": "true", "value": "count"},
         ],
         [
             {"name": "ignore_load", "kind": "replace_update_guard", "old": "load", "new": "false"},
             {"name": "ignore_increment", "kind": "replace_update_guard", "old": "!load && increment && (count < 3'd7)", "new": "false"},
             {"name": "increment_beats_load", "kind": "replace_update_guard", "old": "!load && increment && (count < 3'd7)", "new": "increment && (count < 3'd7)"},
         ]),
    ]
    for c in configs:
        make_register(c[0], "counter", c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9])


def build_arbiters():
    # New arbitration behaviors intentionally expose grant/service phase at the interface.
    configs = [
        ("arbiter_0006", "sticky_grant0", "Sticky two-client arbiter: a grant is held until release.",
         ["req0", "req1", "release"],
         ["grant0", "grant1"],
         ["IDLE", "G0", "G1"],
         {
             "IDLE": {"grant0": 0, "grant1": 0},
             "G0": {"grant0": 1, "grant1": 0},
             "G1": {"grant0": 0, "grant1": 1},
         },
         [
             {"from": "IDLE", "when": "req0", "to": "G0"},
             {"from": "IDLE", "when": "!req0 && req1", "to": "G1"},
             {"from": "IDLE", "when": "!req0 && !req1", "to": "IDLE"},
             {"from": "G0", "when": "release", "to": "IDLE"},
             {"from": "G0", "when": "!release", "to": "G0"},
             {"from": "G1", "when": "release", "to": "IDLE"},
             {"from": "G1", "when": "!release", "to": "G1"},
         ]),
        ("arbiter_0007", "grant0_then_grant1", "Two-client arbiter gives req0 priority after idle and req1 priority after serving req0.",
         ["req0", "req1", "done"],
         ["grant0", "grant1"],
         ["IDLE", "G0", "G1"],
         {
             "IDLE": {"grant0": 0, "grant1": 0},
             "G0": {"grant0": 1, "grant1": 0},
             "G1": {"grant0": 0, "grant1": 1},
         },
         [
             {"from": "IDLE", "when": "req0", "to": "G0"},
             {"from": "IDLE", "when": "!req0 && req1", "to": "G1"},
             {"from": "IDLE", "when": "!req0 && !req1", "to": "IDLE"},
             {"from": "G0", "when": "done && req1", "to": "G1"},
             {"from": "G0", "when": "done && !req1", "to": "IDLE"},
             {"from": "G0", "when": "!done", "to": "G0"},
             {"from": "G1", "when": "done && req0", "to": "G0"},
             {"from": "G1", "when": "done && !req0", "to": "IDLE"},
             {"from": "G1", "when": "!done", "to": "G1"},
         ]),
        ("arbiter_0008", "three_client_fixed", "Three-client fixed-priority arbiter with one-cycle grants.",
         ["req0", "req1", "req2"],
         ["grant0", "grant1", "grant2"],
         ["IDLE", "G0", "G1", "G2"],
         {
             "IDLE": {"grant0": 0, "grant1": 0, "grant2": 0},
             "G0": {"grant0": 1, "grant1": 0, "grant2": 0},
             "G1": {"grant0": 0, "grant1": 1, "grant2": 0},
             "G2": {"grant0": 0, "grant1": 0, "grant2": 1},
         },
         [
             {"from": "IDLE", "when": "req0", "to": "G0"},
             {"from": "IDLE", "when": "!req0 && req1", "to": "G1"},
             {"from": "IDLE", "when": "!req0 && !req1 && req2", "to": "G2"},
             {"from": "IDLE", "when": "!req0 && !req1 && !req2", "to": "IDLE"},
             {"from": "G0", "when": "true", "to": "IDLE"},
             {"from": "G1", "when": "true", "to": "IDLE"},
             {"from": "G2", "when": "true", "to": "IDLE"},
         ]),
        ("arbiter_0009", "lockable_two_client", "Two-client arbiter whose active grant can be locked.",
         ["req0", "req1", "lock"],
         ["grant0", "grant1"],
         ["IDLE", "G0", "G1"],
         {
             "IDLE": {"grant0": 0, "grant1": 0},
             "G0": {"grant0": 1, "grant1": 0},
             "G1": {"grant0": 0, "grant1": 1},
         },
         [
             {"from": "IDLE", "when": "req1", "to": "G1"},
             {"from": "IDLE", "when": "!req1 && req0", "to": "G0"},
             {"from": "IDLE", "when": "!req1 && !req0", "to": "IDLE"},
             {"from": "G0", "when": "lock", "to": "G0"},
             {"from": "G0", "when": "!lock", "to": "IDLE"},
             {"from": "G1", "when": "lock", "to": "G1"},
             {"from": "G1", "when": "!lock", "to": "IDLE"},
         ]),
        ("arbiter_0010", "handoff_arbiter", "Grant handoff prefers a waiting peer when the active client completes.",
         ["req0", "req1", "done"],
         ["grant0", "grant1"],
         ["IDLE", "G0", "G1"],
         {
             "IDLE": {"grant0": 0, "grant1": 0},
             "G0": {"grant0": 1, "grant1": 0},
             "G1": {"grant0": 0, "grant1": 1},
         },
         [
             {"from": "IDLE", "when": "req0", "to": "G0"},
             {"from": "IDLE", "when": "!req0 && req1", "to": "G1"},
             {"from": "IDLE", "when": "!req0 && !req1", "to": "IDLE"},
             {"from": "G0", "when": "done && req1", "to": "G1"},
             {"from": "G0", "when": "done && !req1 && req0", "to": "G0"},
             {"from": "G0", "when": "done && !req1 && !req0", "to": "IDLE"},
             {"from": "G0", "when": "!done", "to": "G0"},
             {"from": "G1", "when": "done && req0", "to": "G0"},
             {"from": "G1", "when": "done && !req0 && req1", "to": "G1"},
             {"from": "G1", "when": "done && !req0 && !req1", "to": "IDLE"},
             {"from": "G1", "when": "!done", "to": "G1"},
         ]),
    ]
    for c in configs:
        make_fsm(c[0], "arbiter", c[1], c[2], c[3], c[4], c[5], "IDLE", c[6], c[7])


def build_interrupts():
    configs = [
        ("interrupt_0006", "masked_latched_irq", "Masked interrupt is latched when enabled and cleared by acknowledge.",
         ["irq", "mask", "ack"], ["pending", "servicing"],
         ["IDLE", "PENDING", "SERVICE"],
         {"IDLE": {"pending": 0, "servicing": 0}, "PENDING": {"pending": 1, "servicing": 0}, "SERVICE": {"pending": 0, "servicing": 1}},
         [
             {"from": "IDLE", "when": "irq && !mask", "to": "PENDING"},
             {"from": "IDLE", "when": "!(irq && !mask)", "to": "IDLE"},
             {"from": "PENDING", "when": "ack", "to": "SERVICE"},
             {"from": "PENDING", "when": "!ack", "to": "PENDING"},
             {"from": "SERVICE", "when": "true", "to": "IDLE"},
         ]),
        ("interrupt_0007", "deferred_mask_irq", "Pending interrupt survives later masking until acknowledged.",
         ["irq", "mask", "ack"], ["pending", "done"],
         ["IDLE", "PENDING", "DONE"],
         {"IDLE": {"pending": 0, "done": 0}, "PENDING": {"pending": 1, "done": 0}, "DONE": {"pending": 0, "done": 1}},
         [
             {"from": "IDLE", "when": "irq && !mask", "to": "PENDING"},
             {"from": "IDLE", "when": "!(irq && !mask)", "to": "IDLE"},
             {"from": "PENDING", "when": "ack", "to": "DONE"},
             {"from": "PENDING", "when": "!ack", "to": "PENDING"},
             {"from": "DONE", "when": "true", "to": "IDLE"},
         ]),
        ("interrupt_0008", "priority_two_level_irq", "High-priority interrupt can preempt a low-priority pending request.",
         ["irq_hi", "irq_lo", "ack"], ["low_pending", "high_pending", "service"],
         ["IDLE", "LOW", "HIGH", "SERVICE"],
         {"IDLE": {"low_pending": 0, "high_pending": 0, "service": 0},
          "LOW": {"low_pending": 1, "high_pending": 0, "service": 0},
          "HIGH": {"low_pending": 0, "high_pending": 1, "service": 0},
          "SERVICE": {"low_pending": 0, "high_pending": 0, "service": 1}},
         [
             {"from": "IDLE", "when": "irq_hi", "to": "HIGH"},
             {"from": "IDLE", "when": "!irq_hi && irq_lo", "to": "LOW"},
             {"from": "IDLE", "when": "!irq_hi && !irq_lo", "to": "IDLE"},
             {"from": "LOW", "when": "irq_hi", "to": "HIGH"},
             {"from": "LOW", "when": "!irq_hi && ack", "to": "SERVICE"},
             {"from": "LOW", "when": "!irq_hi && !ack", "to": "LOW"},
             {"from": "HIGH", "when": "ack", "to": "SERVICE"},
             {"from": "HIGH", "when": "!ack", "to": "HIGH"},
             {"from": "SERVICE", "when": "true", "to": "IDLE"},
         ]),
        ("interrupt_0009", "irq_cooldown", "Interrupt service is followed by a cooldown state before rearming.",
         ["irq", "ack"], ["pending", "service", "cooldown"],
         ["IDLE", "PENDING", "SERVICE", "COOL"],
         {"IDLE": {"pending": 0, "service": 0, "cooldown": 0},
          "PENDING": {"pending": 1, "service": 0, "cooldown": 0},
          "SERVICE": {"pending": 0, "service": 1, "cooldown": 0},
          "COOL": {"pending": 0, "service": 0, "cooldown": 1}},
         [
             {"from": "IDLE", "when": "irq", "to": "PENDING"},
             {"from": "IDLE", "when": "!irq", "to": "IDLE"},
             {"from": "PENDING", "when": "ack", "to": "SERVICE"},
             {"from": "PENDING", "when": "!ack", "to": "PENDING"},
             {"from": "SERVICE", "when": "true", "to": "COOL"},
             {"from": "COOL", "when": "irq", "to": "COOL"},
             {"from": "COOL", "when": "!irq", "to": "IDLE"},
         ]),
        ("interrupt_0010", "cancelable_irq", "Pending interrupt may be explicitly cancelled before service.",
         ["irq", "cancel", "ack"], ["pending", "service", "cancelled"],
         ["IDLE", "PENDING", "SERVICE", "CANCEL"],
         {"IDLE": {"pending": 0, "service": 0, "cancelled": 0},
          "PENDING": {"pending": 1, "service": 0, "cancelled": 0},
          "SERVICE": {"pending": 0, "service": 1, "cancelled": 0},
          "CANCEL": {"pending": 0, "service": 0, "cancelled": 1}},
         [
             {"from": "IDLE", "when": "irq", "to": "PENDING"},
             {"from": "IDLE", "when": "!irq", "to": "IDLE"},
             {"from": "PENDING", "when": "cancel", "to": "CANCEL"},
             {"from": "PENDING", "when": "!cancel && ack", "to": "SERVICE"},
             {"from": "PENDING", "when": "!cancel && !ack", "to": "PENDING"},
             {"from": "SERVICE", "when": "true", "to": "IDLE"},
             {"from": "CANCEL", "when": "true", "to": "IDLE"},
         ]),
    ]
    for c in configs:
        make_fsm(c[0], "interrupt_control", c[1], c[2], c[3], c[4], c[5], "IDLE", c[6], c[7])


def fifo_properties(prefix, data_width=2):
    # Common properties for a one-entry or mailbox-style two-register buffer.
    return [
        inv_prop("P1_READY", "p_ready", "ready reflects whether a new item can be accepted", "ready == (!valid || pop)"),
        next_prop("P2_RESET", "p_reset_empty", "reset leaves the buffer empty", "rst", "!valid", disable=None),
        next_prop("P3_PUSH", "p_push", "an accepted push captures the input item",
                  "!valid && push", "valid && (dout == $past(din))"),
        next_prop("P4_HOLD", "p_hold", "a full unpopped buffer retains its item",
                  "valid && !pop", "valid && (dout == $past(dout))"),
        next_prop("P5_POP", "p_pop", "a pop without replacement empties the buffer",
                  "valid && pop && !push", "!valid"),
        next_prop("P6_REPLACE", "p_replace", "simultaneous pop and push replaces the item",
                  "valid && pop && push", "valid && (dout == $past(din))"),
    ]


def build_fifos():
    # fifo_0006: elastic one-entry queue, simultaneous pop+push replaces data.
    regs = [
        {"name": "data_reg", "width": 3, "reset_value": "3'd0"},
        {"name": "valid_reg", "width": 1, "reset_value": "1'b0"},
    ]
    derived = {"dout": "data_reg", "valid": "valid_reg", "ready": "!valid_reg || pop"}
    rules = {
        "data_reg": [
            {"when": "push && (!valid_reg || pop)", "value": "din"},
            {"when": "true", "value": "data_reg"},
        ],
        "valid_reg": [
            {"when": "push && (!valid_reg || pop)", "value": "1'b1"},
            {"when": "pop && valid_reg", "value": "1'b0"},
            {"when": "true", "value": "valid_reg"},
        ],
    }
    props = [
        inv_prop("P1_READY", "p_ready", "ready reflects elastic acceptance", "ready == (!valid || pop)"),
        next_prop("P2_RESET", "p_reset", "reset empties the queue", "rst", "!valid", disable=None),
        next_prop("P3_PUSH_EMPTY", "p_push_empty", "push into empty captures data", "!valid && push", "valid && (dout == $past(din))"),
        next_prop("P4_HOLD_FULL", "p_hold_full", "full queue without pop holds data", "valid && !pop", "valid && (dout == $past(dout))"),
        next_prop("P5_POP", "p_pop", "pop without replacement empties queue", "valid && pop && !push", "!valid"),
        next_prop("P6_REPLACE", "p_replace", "simultaneous pop and push replaces item", "valid && pop && push", "valid && (dout == $past(din))"),
    ]
    mutants = [
        {"name": "ignore_pop", "register": "valid_reg", "kind": "replace_update_guard", "old": "pop && valid_reg", "new": "false"},
        {"name": "drop_replacement", "register": "valid_reg", "kind": "replace_update_guard", "old": "push && (!valid_reg || pop)", "new": "push && !valid_reg"},
        {"name": "overwrite_without_accept", "register": "data_reg", "kind": "replace_update_guard", "old": "push && (!valid_reg || pop)", "new": "push"},
    ]
    make_fifo("fifo_0006", "elastic_mailbox", "Elastic one-entry queue with same-cycle pop-and-replace.", ["push", "pop", "din"], regs, derived, rules, props, mutants)

    # fifo_0007: strict queue. A push presented while full is rejected even if pop
    # occurs in the same cycle; the pop empties the queue.
    regs = [
        {"name": "data_reg", "width": 2, "reset_value": "2'd0"},
        {"name": "valid_reg", "width": 1, "reset_value": "1'b0"},
    ]
    derived = {"dout": "data_reg", "valid": "valid_reg", "ready": "!valid_reg"}
    rules = {
        "data_reg": [
            {"when": "push && !valid_reg", "value": "din"},
            {"when": "true", "value": "data_reg"},
        ],
        "valid_reg": [
            {"when": "push && !valid_reg", "value": "1'b1"},
            {"when": "pop && valid_reg", "value": "1'b0"},
            {"when": "true", "value": "valid_reg"},
        ],
    }
    props = [
        inv_prop("P1_READY", "p_ready", "ready is asserted only when empty", "ready == !valid"),
        next_prop("P2_RESET", "p_reset", "reset empties the queue", "rst", "!valid", disable=None),
        next_prop("P3_ACCEPT", "p_accept", "accepted push captures input", "!valid && push", "valid && (dout == $past(din))"),
        next_prop("P4_BACKPRESSURE", "p_backpressure", "full queue rejects push while not popped", "valid && !pop && push", "valid && (dout == $past(dout))"),
        next_prop("P5_POP_WINS", "p_pop_wins", "pop from full empties even if push is also asserted", "valid && pop", "!valid"),
        next_prop("P6_HOLD", "p_hold", "full queue holds without pop", "valid && !pop", "valid && (dout == $past(dout))"),
    ]
    mutants = [
        {"name": "ignore_pop", "register": "valid_reg", "kind": "replace_update_guard", "old": "pop && valid_reg", "new": "false"},
        {"name": "accept_replacement", "register": "valid_reg", "kind": "replace_update_guard", "old": "push && !valid_reg", "new": "push && (!valid_reg || pop)"},
        {"name": "overwrite_full", "register": "data_reg", "kind": "replace_update_guard", "old": "push && !valid_reg", "new": "push"},
    ]
    make_fifo("fifo_0007", "strict_single_slot_fifo", "Strict one-entry FIFO that rejects a full-cycle replacement push.", ["push", "pop", "din"], regs, derived, rules, props, mutants)

    # fifo_0008: flushable elastic queue. Flush has highest priority.
    regs = [
        {"name": "data_reg", "width": 3, "reset_value": "3'd0"},
        {"name": "valid_reg", "width": 1, "reset_value": "1'b0"},
    ]
    derived = {"dout": "data_reg", "valid": "valid_reg", "ready": "!valid_reg || pop || flush"}
    rules = {
        "data_reg": [
            {"when": "!flush && push && (!valid_reg || pop)", "value": "din"},
            {"when": "true", "value": "data_reg"},
        ],
        "valid_reg": [
            {"when": "flush", "value": "1'b0"},
            {"when": "!flush && push && (!valid_reg || pop)", "value": "1'b1"},
            {"when": "!flush && pop && valid_reg", "value": "1'b0"},
            {"when": "true", "value": "valid_reg"},
        ],
    }
    props = [
        inv_prop("P1_READY", "p_ready", "flush or available capacity permits acceptance", "ready == (!valid || pop || flush)"),
        next_prop("P2_RESET", "p_reset", "reset empties queue", "rst", "!valid", disable=None),
        next_prop("P3_FLUSH", "p_flush", "flush empties queue and preserves stored data bits", "flush", "!valid && (dout == $past(dout))"),
        next_prop("P4_PUSH", "p_push", "non-flushed accepted push captures data", "!flush && !valid && push", "valid && (dout == $past(din))"),
        next_prop("P5_POP", "p_pop", "non-flushed pop without replacement empties", "!flush && valid && pop && !push", "!valid"),
        next_prop("P6_REPLACE", "p_replace", "non-flushed pop plus push replaces data", "!flush && valid && pop && push", "valid && (dout == $past(din))"),
        next_prop("P7_HOLD", "p_hold", "full non-flushed queue without pop holds", "!flush && valid && !pop", "valid && (dout == $past(dout))"),
    ]
    mutants = [
        {"name": "ignore_flush", "register": "valid_reg", "kind": "replace_update_guard", "old": "flush", "new": "false"},
        {"name": "push_changes_data_during_flush", "register": "data_reg", "kind": "replace_update_guard", "old": "!flush && push && (!valid_reg || pop)", "new": "push && (!valid_reg || pop)"},
        {"name": "overwrite_full", "register": "data_reg", "kind": "replace_update_guard", "old": "!flush && push && (!valid_reg || pop)", "new": "!flush && push"},
    ]
    make_fifo("fifo_0008", "flushable_elastic_fifo", "Flushable elastic one-entry FIFO with flush priority.", ["push", "pop", "flush", "din"], regs, derived, rules, props, mutants)

    # fifo_0009: overwrite mailbox. Push always stores newest data; push wins over pop.
    regs = [
        {"name": "data_reg", "width": 2, "reset_value": "2'd0"},
        {"name": "valid_reg", "width": 1, "reset_value": "1'b0"},
    ]
    derived = {"dout": "data_reg", "valid": "valid_reg", "ready": "1'b1"}
    rules = {
        "data_reg": [
            {"when": "push", "value": "din"},
            {"when": "true", "value": "data_reg"},
        ],
        "valid_reg": [
            {"when": "push", "value": "1'b1"},
            {"when": "!push && pop && valid_reg", "value": "1'b0"},
            {"when": "true", "value": "valid_reg"},
        ],
    }
    props = [
        inv_prop("P1_READY", "p_ready", "overwrite mailbox is always ready", "ready"),
        next_prop("P2_RESET", "p_reset", "reset empties mailbox", "rst", "!valid", disable=None),
        next_prop("P3_PUSH", "p_push", "every push stores the newest item", "push", "valid && (dout == $past(din))"),
        next_prop("P4_POP", "p_pop", "pop without simultaneous push empties mailbox", "!push && valid && pop", "!valid"),
        next_prop("P5_HOLD", "p_hold", "without push or pop mailbox holds", "valid && !push && !pop", "valid && (dout == $past(dout))"),
    ]
    mutants = [
        {"name": "drop_push_data", "register": "data_reg", "kind": "replace_update_guard", "old": "push", "new": "push && !valid_reg"},
        {"name": "drop_push_valid", "register": "valid_reg", "kind": "replace_update_guard", "old": "push", "new": "false"},
        {"name": "ignore_pop", "register": "valid_reg", "kind": "replace_update_guard", "old": "!push && pop && valid_reg", "new": "false"},
    ]
    make_fifo("fifo_0009", "overwrite_mailbox", "Always-ready mailbox where newest push overwrites older data.", ["push", "pop", "din"], regs, derived, rules, props, mutants)

    # fifo_0010: acknowledge-cleared mailbox.
    regs = [
        {"name": "data_reg", "width": 3, "reset_value": "3'd0"},
        {"name": "valid_reg", "width": 1, "reset_value": "1'b0"},
    ]
    derived = {"dout": "data_reg", "valid": "valid_reg", "ready": "!valid_reg"}
    rules = {
        "data_reg": [
            {"when": "push && !valid_reg", "value": "din"},
            {"when": "true", "value": "data_reg"},
        ],
        "valid_reg": [
            {"when": "push && !valid_reg", "value": "1'b1"},
            {"when": "ack && valid_reg", "value": "1'b0"},
            {"when": "true", "value": "valid_reg"},
        ],
    }
    props = [
        inv_prop("P1_READY", "p_ready", "mailbox is ready exactly when empty", "ready == !valid"),
        next_prop("P2_RESET", "p_reset", "reset empties mailbox", "rst", "!valid", disable=None),
        next_prop("P3_PUSH", "p_push", "push into empty mailbox captures data", "!valid && push", "valid && (dout == $past(din))"),
        next_prop("P4_ACK", "p_ack", "acknowledging a valid mailbox clears it", "valid && ack", "!valid"),
        next_prop("P5_HOLD", "p_hold", "unacknowledged valid mailbox retains data", "valid && !ack", "valid && (dout == $past(dout))"),
        next_prop("P6_REJECT_FULL", "p_reject_full", "push while full without ack cannot overwrite data", "valid && !ack && push", "valid && (dout == $past(dout))"),
    ]
    mutants = [
        {"name": "ignore_ack", "register": "valid_reg", "kind": "replace_update_guard", "old": "ack && valid_reg", "new": "false"},
        {"name": "overwrite_full", "register": "data_reg", "kind": "replace_update_guard", "old": "push && !valid_reg", "new": "push"},
        {"name": "accept_push_when_full", "register": "valid_reg", "kind": "replace_update_guard", "old": "push && !valid_reg", "new": "push"},
    ]
    make_fifo("fifo_0010", "acknowledged_mailbox", "Single-entry mailbox cleared by explicit acknowledge.", ["push", "ack", "din"], regs, derived, rules, props, mutants)


# ---------------------------------------------------------------------------
# NEW CATEGORY EXPANSION: pilot 0001 already exists, create 0002..0010
# ---------------------------------------------------------------------------

def build_pulse_events():
    # Each configuration changes trigger/rearm/cooldown semantics rather than only widths.
    configs = []
    for idx, kind in enumerate([
        "rising_rearm",
        "falling_rearm",
        "level_one_shot",
        "acknowledged_pulse",
        "cancelable_pulse",
        "two_cycle_cooldown",
        "armed_gate",
        "request_complete_pulse",
        "toggle_rearm",
    ], start=2):
        did = f"pulse_event_{idx:04d}"

        if kind == "rising_rearm":
            inputs = ["event_in"]
            outputs = ["armed", "pulse", "blocked"]
            states = ["ARMED", "PULSE", "BLOCKED"]
            so = {"ARMED": {"armed": 1, "pulse": 0, "blocked": 0},
                  "PULSE": {"armed": 0, "pulse": 1, "blocked": 0},
                  "BLOCKED": {"armed": 0, "pulse": 0, "blocked": 1}}
            tr = [
                {"from": "ARMED", "when": "event_in", "to": "PULSE"},
                {"from": "ARMED", "when": "!event_in", "to": "ARMED"},
                {"from": "PULSE", "when": "true", "to": "BLOCKED"},
                {"from": "BLOCKED", "when": "event_in", "to": "BLOCKED"},
                {"from": "BLOCKED", "when": "!event_in", "to": "ARMED"},
            ]
            reset = "ARMED"

        elif kind == "falling_rearm":
            inputs = ["event_in"]
            outputs = ["waiting_high", "pulse", "waiting_low"]
            states = ["WAIT_HIGH", "PULSE", "WAIT_LOW"]
            so = {"WAIT_HIGH": {"waiting_high": 1, "pulse": 0, "waiting_low": 0},
                  "PULSE": {"waiting_high": 0, "pulse": 1, "waiting_low": 0},
                  "WAIT_LOW": {"waiting_high": 0, "pulse": 0, "waiting_low": 1}}
            tr = [
                {"from": "WAIT_HIGH", "when": "event_in", "to": "WAIT_LOW"},
                {"from": "WAIT_HIGH", "when": "!event_in", "to": "WAIT_HIGH"},
                {"from": "WAIT_LOW", "when": "!event_in", "to": "PULSE"},
                {"from": "WAIT_LOW", "when": "event_in", "to": "WAIT_LOW"},
                {"from": "PULSE", "when": "true", "to": "WAIT_HIGH"},
            ]
            reset = "WAIT_HIGH"

        elif kind == "level_one_shot":
            inputs = ["trigger", "clear"]
            outputs = ["armed", "pulse", "latched"]
            states = ["ARMED", "PULSE", "LATCHED"]
            so = {"ARMED": {"armed": 1, "pulse": 0, "latched": 0},
                  "PULSE": {"armed": 0, "pulse": 1, "latched": 0},
                  "LATCHED": {"armed": 0, "pulse": 0, "latched": 1}}
            tr = [
                {"from": "ARMED", "when": "trigger", "to": "PULSE"},
                {"from": "ARMED", "when": "!trigger", "to": "ARMED"},
                {"from": "PULSE", "when": "true", "to": "LATCHED"},
                {"from": "LATCHED", "when": "clear", "to": "ARMED"},
                {"from": "LATCHED", "when": "!clear", "to": "LATCHED"},
            ]
            reset = "ARMED"

        elif kind == "acknowledged_pulse":
            inputs = ["trigger", "ack"]
            outputs = ["armed", "pulse", "wait_ack"]
            states = ["ARMED", "PULSE", "WAIT_ACK"]
            so = {"ARMED": {"armed": 1, "pulse": 0, "wait_ack": 0},
                  "PULSE": {"armed": 0, "pulse": 1, "wait_ack": 0},
                  "WAIT_ACK": {"armed": 0, "pulse": 0, "wait_ack": 1}}
            tr = [
                {"from": "ARMED", "when": "trigger", "to": "PULSE"},
                {"from": "ARMED", "when": "!trigger", "to": "ARMED"},
                {"from": "PULSE", "when": "true", "to": "WAIT_ACK"},
                {"from": "WAIT_ACK", "when": "ack", "to": "ARMED"},
                {"from": "WAIT_ACK", "when": "!ack", "to": "WAIT_ACK"},
            ]
            reset = "ARMED"

        elif kind == "cancelable_pulse":
            inputs = ["trigger", "cancel"]
            outputs = ["armed", "pulse", "cancelled"]
            states = ["ARMED", "PULSE", "CANCEL"]
            so = {"ARMED": {"armed": 1, "pulse": 0, "cancelled": 0},
                  "PULSE": {"armed": 0, "pulse": 1, "cancelled": 0},
                  "CANCEL": {"armed": 0, "pulse": 0, "cancelled": 1}}
            tr = [
                {"from": "ARMED", "when": "trigger && !cancel", "to": "PULSE"},
                {"from": "ARMED", "when": "cancel", "to": "CANCEL"},
                {"from": "ARMED", "when": "!trigger && !cancel", "to": "ARMED"},
                {"from": "PULSE", "when": "true", "to": "ARMED"},
                {"from": "CANCEL", "when": "true", "to": "ARMED"},
            ]
            reset = "ARMED"

        elif kind == "two_cycle_cooldown":
            inputs = ["trigger"]
            outputs = ["armed", "pulse", "cooldown"]
            states = ["ARMED", "PULSE", "COOL1", "COOL2"]
            so = {"ARMED": {"armed": 1, "pulse": 0, "cooldown": 0},
                  "PULSE": {"armed": 0, "pulse": 1, "cooldown": 0},
                  "COOL1": {"armed": 0, "pulse": 0, "cooldown": 1},
                  "COOL2": {"armed": 0, "pulse": 0, "cooldown": 1}}
            tr = [
                {"from": "ARMED", "when": "trigger", "to": "PULSE"},
                {"from": "ARMED", "when": "!trigger", "to": "ARMED"},
                {"from": "PULSE", "when": "true", "to": "COOL1"},
                {"from": "COOL1", "when": "true", "to": "COOL2"},
                {"from": "COOL2", "when": "true", "to": "ARMED"},
            ]
            reset = "ARMED"

        elif kind == "armed_gate":
            inputs = ["trigger", "enable"]
            outputs = ["armed", "pulse", "disabled"]
            states = ["DISABLED", "ARMED", "PULSE"]
            so = {"DISABLED": {"armed": 0, "pulse": 0, "disabled": 1},
                  "ARMED": {"armed": 1, "pulse": 0, "disabled": 0},
                  "PULSE": {"armed": 0, "pulse": 1, "disabled": 0}}
            tr = [
                {"from": "DISABLED", "when": "enable", "to": "ARMED"},
                {"from": "DISABLED", "when": "!enable", "to": "DISABLED"},
                {"from": "ARMED", "when": "!enable", "to": "DISABLED"},
                {"from": "ARMED", "when": "enable && trigger", "to": "PULSE"},
                {"from": "ARMED", "when": "enable && !trigger", "to": "ARMED"},
                {"from": "PULSE", "when": "enable", "to": "ARMED"},
                {"from": "PULSE", "when": "!enable", "to": "DISABLED"},
            ]
            reset = "DISABLED"

        elif kind == "request_complete_pulse":
            inputs = ["request", "complete"]
            outputs = ["waiting", "pulse", "idle"]
            states = ["IDLE", "WAIT", "PULSE"]
            so = {"IDLE": {"waiting": 0, "pulse": 0, "idle": 1},
                  "WAIT": {"waiting": 1, "pulse": 0, "idle": 0},
                  "PULSE": {"waiting": 0, "pulse": 1, "idle": 0}}
            tr = [
                {"from": "IDLE", "when": "request", "to": "WAIT"},
                {"from": "IDLE", "when": "!request", "to": "IDLE"},
                {"from": "WAIT", "when": "complete", "to": "PULSE"},
                {"from": "WAIT", "when": "!complete", "to": "WAIT"},
                {"from": "PULSE", "when": "true", "to": "IDLE"},
            ]
            reset = "IDLE"

        else:  # toggle_rearm
            inputs = ["trigger", "rearm"]
            outputs = ["armed", "pulse", "spent"]
            states = ["ARMED", "PULSE", "SPENT"]
            so = {"ARMED": {"armed": 1, "pulse": 0, "spent": 0},
                  "PULSE": {"armed": 0, "pulse": 1, "spent": 0},
                  "SPENT": {"armed": 0, "pulse": 0, "spent": 1}}
            tr = [
                {"from": "ARMED", "when": "trigger", "to": "PULSE"},
                {"from": "ARMED", "when": "!trigger", "to": "ARMED"},
                {"from": "PULSE", "when": "true", "to": "SPENT"},
                {"from": "SPENT", "when": "rearm", "to": "ARMED"},
                {"from": "SPENT", "when": "!rearm", "to": "SPENT"},
            ]
            reset = "ARMED"

        configs.append((did, kind, f"Pulse/event controller implementing {kind.replace('_', ' ')} semantics.",
                        inputs, outputs, states, reset, so, tr))

    for c in configs:
        make_fsm(c[0], "pulse_event", c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8])


def kmp_next(pattern, prefix, bit):
    s = prefix + bit
    best = ""
    for k in range(min(len(pattern) - 1, len(s)), -1, -1):
        if s.endswith(pattern[:k]):
            best = pattern[:k]
            break
    return best


def build_sequence_detectors():
    patterns = [
        "110", "001", "101", "1110", "0101", "1001", "0110", "1101", "0011"
    ]

    for idx, pat in enumerate(patterns, start=2):
        did = f"sequence_detector_{idx:04d}"
        prefixes = [""] + [pat[:k] for k in range(1, len(pat))]
        states = [f"S{k}" for k in range(len(prefixes))] + ["MATCH"]
        outputs = [f"progress{k}" for k in range(1, len(prefixes))] + ["match"]

        so = {}
        so["S0"] = {o: 0 for o in outputs}
        for k in range(1, len(prefixes)):
            vals = {o: 0 for o in outputs}
            vals[f"progress{k}"] = 1
            so[f"S{k}"] = vals
        vals = {o: 0 for o in outputs}
        vals["match"] = 1
        so["MATCH"] = vals

        transitions = []
        for k, prefix in enumerate(prefixes):
            state = f"S{k}"
            for bit in ("0", "1"):
                s = prefix + bit
                if s.endswith(pat):
                    dst = "MATCH"
                else:
                    nxt = kmp_next(pat, prefix, bit)
                    dst = f"S{len(nxt)}"
                guard = "bit_in" if bit == "1" else "!bit_in"
                transitions.append({"from": state, "when": guard, "to": dst})

        # After a match, consume the next input while preserving overlap.
        for bit in ("0", "1"):
            nxt = kmp_next(pat, pat, bit)
            dst = f"S{len(nxt)}"
            guard = "bit_in" if bit == "1" else "!bit_in"
            transitions.append({"from": "MATCH", "when": guard, "to": dst})

        make_fsm(
            did,
            "sequence_detector",
            f"pattern_{pat}",
            f"Overlapping serial sequence detector for pattern {pat}.",
            ["bit_in"],
            outputs,
            states,
            "S0",
            so,
            transitions,
        )


def build_protocols():
    configs = [
        ("command_response", ["cmd", "resp"], ["busy", "done"], ["IDLE", "WAIT", "DONE"],
         {"IDLE": {"busy": 0, "done": 0}, "WAIT": {"busy": 1, "done": 0}, "DONE": {"busy": 0, "done": 1}},
         [
             {"from": "IDLE", "when": "cmd", "to": "WAIT"}, {"from": "IDLE", "when": "!cmd", "to": "IDLE"},
             {"from": "WAIT", "when": "resp", "to": "DONE"}, {"from": "WAIT", "when": "!resp", "to": "WAIT"},
             {"from": "DONE", "when": "true", "to": "IDLE"},
         ]),
        ("request_cancel", ["request", "grant", "cancel"], ["waiting", "done", "cancelled"], ["IDLE", "WAIT", "DONE", "CANCEL"],
         {"IDLE": {"waiting": 0, "done": 0, "cancelled": 0}, "WAIT": {"waiting": 1, "done": 0, "cancelled": 0},
          "DONE": {"waiting": 0, "done": 1, "cancelled": 0}, "CANCEL": {"waiting": 0, "done": 0, "cancelled": 1}},
         [
             {"from": "IDLE", "when": "request", "to": "WAIT"}, {"from": "IDLE", "when": "!request", "to": "IDLE"},
             {"from": "WAIT", "when": "cancel", "to": "CANCEL"}, {"from": "WAIT", "when": "!cancel && grant", "to": "DONE"},
             {"from": "WAIT", "when": "!cancel && !grant", "to": "WAIT"},
             {"from": "DONE", "when": "true", "to": "IDLE"}, {"from": "CANCEL", "when": "true", "to": "IDLE"},
         ]),
        ("retry_response", ["start", "ok", "retry"], ["busy", "retrying", "done"], ["IDLE", "WAIT", "RETRY", "DONE"],
         {"IDLE": {"busy": 0, "retrying": 0, "done": 0}, "WAIT": {"busy": 1, "retrying": 0, "done": 0},
          "RETRY": {"busy": 0, "retrying": 1, "done": 0}, "DONE": {"busy": 0, "retrying": 0, "done": 1}},
         [
             {"from": "IDLE", "when": "start", "to": "WAIT"}, {"from": "IDLE", "when": "!start", "to": "IDLE"},
             {"from": "WAIT", "when": "retry", "to": "RETRY"}, {"from": "WAIT", "when": "!retry && ok", "to": "DONE"},
             {"from": "WAIT", "when": "!retry && !ok", "to": "WAIT"},
             {"from": "RETRY", "when": "true", "to": "WAIT"}, {"from": "DONE", "when": "true", "to": "IDLE"},
         ]),
        ("two_stage_commit", ["start", "prepare_ok", "commit_ok"], ["preparing", "committing", "done"], ["IDLE", "PREP", "COMMIT", "DONE"],
         {"IDLE": {"preparing": 0, "committing": 0, "done": 0}, "PREP": {"preparing": 1, "committing": 0, "done": 0},
          "COMMIT": {"preparing": 0, "committing": 1, "done": 0}, "DONE": {"preparing": 0, "committing": 0, "done": 1}},
         [
             {"from": "IDLE", "when": "start", "to": "PREP"}, {"from": "IDLE", "when": "!start", "to": "IDLE"},
             {"from": "PREP", "when": "prepare_ok", "to": "COMMIT"}, {"from": "PREP", "when": "!prepare_ok", "to": "PREP"},
             {"from": "COMMIT", "when": "commit_ok", "to": "DONE"}, {"from": "COMMIT", "when": "!commit_ok", "to": "COMMIT"},
             {"from": "DONE", "when": "true", "to": "IDLE"},
         ]),
        ("lock_unlock", ["acquire", "release"], ["waiting", "held"], ["IDLE", "WAIT", "HELD"],
         {"IDLE": {"waiting": 0, "held": 0}, "WAIT": {"waiting": 1, "held": 0}, "HELD": {"waiting": 0, "held": 1}},
         [
             {"from": "IDLE", "when": "acquire", "to": "WAIT"}, {"from": "IDLE", "when": "!acquire", "to": "IDLE"},
             {"from": "WAIT", "when": "acquire", "to": "HELD"}, {"from": "WAIT", "when": "!acquire", "to": "WAIT"},
             {"from": "HELD", "when": "release", "to": "IDLE"}, {"from": "HELD", "when": "!release", "to": "HELD"},
         ]),
        ("start_pause_resume", ["start", "pause", "resume", "done_in"], ["running", "paused", "done"], ["IDLE", "RUN", "PAUSE", "DONE"],
         {"IDLE": {"running": 0, "paused": 0, "done": 0}, "RUN": {"running": 1, "paused": 0, "done": 0},
          "PAUSE": {"running": 0, "paused": 1, "done": 0}, "DONE": {"running": 0, "paused": 0, "done": 1}},
         [
             {"from": "IDLE", "when": "start", "to": "RUN"}, {"from": "IDLE", "when": "!start", "to": "IDLE"},
             {"from": "RUN", "when": "done_in", "to": "DONE"}, {"from": "RUN", "when": "!done_in && pause", "to": "PAUSE"},
             {"from": "RUN", "when": "!done_in && !pause", "to": "RUN"},
             {"from": "PAUSE", "when": "resume", "to": "RUN"}, {"from": "PAUSE", "when": "!resume", "to": "PAUSE"},
             {"from": "DONE", "when": "true", "to": "IDLE"},
         ]),
        ("request_reject", ["request", "accept", "reject"], ["pending", "accepted", "rejected"], ["IDLE", "WAIT", "ACCEPT", "REJECT"],
         {"IDLE": {"pending": 0, "accepted": 0, "rejected": 0}, "WAIT": {"pending": 1, "accepted": 0, "rejected": 0},
          "ACCEPT": {"pending": 0, "accepted": 1, "rejected": 0}, "REJECT": {"pending": 0, "accepted": 0, "rejected": 1}},
         [
             {"from": "IDLE", "when": "request", "to": "WAIT"}, {"from": "IDLE", "when": "!request", "to": "IDLE"},
             {"from": "WAIT", "when": "reject", "to": "REJECT"}, {"from": "WAIT", "when": "!reject && accept", "to": "ACCEPT"},
             {"from": "WAIT", "when": "!reject && !accept", "to": "WAIT"},
             {"from": "ACCEPT", "when": "true", "to": "IDLE"}, {"from": "REJECT", "when": "true", "to": "IDLE"},
         ]),
        ("open_transfer_close", ["open", "transfer_done", "close"], ["opened", "transferring", "closed"], ["IDLE", "OPEN", "XFER", "CLOSE"],
         {"IDLE": {"opened": 0, "transferring": 0, "closed": 0}, "OPEN": {"opened": 1, "transferring": 0, "closed": 0},
          "XFER": {"opened": 0, "transferring": 1, "closed": 0}, "CLOSE": {"opened": 0, "transferring": 0, "closed": 1}},
         [
             {"from": "IDLE", "when": "open", "to": "OPEN"}, {"from": "IDLE", "when": "!open", "to": "IDLE"},
             {"from": "OPEN", "when": "true", "to": "XFER"},
             {"from": "XFER", "when": "transfer_done", "to": "CLOSE"}, {"from": "XFER", "when": "!transfer_done", "to": "XFER"},
             {"from": "CLOSE", "when": "close", "to": "IDLE"}, {"from": "CLOSE", "when": "!close", "to": "CLOSE"},
         ]),
        ("enable_quiesce", ["enable", "quiesce", "idle_seen"], ["running", "draining", "stopped"], ["STOP", "RUN", "DRAIN"],
         {"STOP": {"running": 0, "draining": 0, "stopped": 1}, "RUN": {"running": 1, "draining": 0, "stopped": 0},
          "DRAIN": {"running": 0, "draining": 1, "stopped": 0}},
         [
             {"from": "STOP", "when": "enable", "to": "RUN"}, {"from": "STOP", "when": "!enable", "to": "STOP"},
             {"from": "RUN", "when": "quiesce", "to": "DRAIN"}, {"from": "RUN", "when": "!quiesce", "to": "RUN"},
             {"from": "DRAIN", "when": "idle_seen", "to": "STOP"}, {"from": "DRAIN", "when": "!idle_seen", "to": "DRAIN"},
         ]),
    ]

    for idx, c in enumerate(configs, start=2):
        did = f"protocol_controller_{idx:04d}"
        reset = c[3][0]
        make_fsm(did, "protocol_controller", c[0],
                 f"Protocol controller implementing {c[0].replace('_', ' ')} behavior.",
                 c[1], c[2], c[3], reset, c[4], c[5])


def build_saturating_arithmetic():
    configs = [
        ("sat_increment_5", ["clear", "inc"], "value", 3, "3'd0", {"at_limit": "value == 3'd5"},
         [{"when": "clear", "value": "3'd0"}, {"when": "!clear && inc && (value < 3'd5)", "value": "value + 3'd1"}, {"when": "true", "value": "value"}]),
        ("sat_decrement", ["reload", "dec"], "value", 3, "3'd7", {"at_zero": "value == 3'd0"},
         [{"when": "reload", "value": "3'd7"}, {"when": "!reload && dec && (value > 3'd0)", "value": "value - 3'd1"}, {"when": "true", "value": "value"}]),
        ("sat_step_two", ["clear", "add"], "value", 4, "4'd0", {"at_limit": "value == 4'd12"},
         [{"when": "clear", "value": "4'd0"}, {"when": "!clear && add && (value < 4'd12)", "value": "value + 4'd2"}, {"when": "true", "value": "value"}]),
        ("sat_up_down", ["up", "down"], "value", 3, "3'd0", {"at_zero": "value == 3'd0", "at_max": "value == 3'd7"},
         [{"when": "up && !down && (value < 3'd7)", "value": "value + 3'd1"}, {"when": "down && !up && (value > 3'd0)", "value": "value - 3'd1"}, {"when": "true", "value": "value"}]),
        ("sat_bias_reload", ["reload", "inc"], "value", 3, "3'd2", {"at_max": "value == 3'd7"},
         [{"when": "reload", "value": "3'd2"}, {"when": "!reload && inc && (value < 3'd7)", "value": "value + 3'd1"}, {"when": "true", "value": "value"}]),
        ("sat_floor_two", ["dec", "restore"], "value", 3, "3'd7", {"at_floor": "value == 3'd2"},
         [{"when": "restore", "value": "3'd7"}, {"when": "!restore && dec && (value > 3'd2)", "value": "value - 3'd1"}, {"when": "true", "value": "value"}]),
        ("sat_ceiling_six", ["zero", "inc"], "value", 3, "3'd0", {"at_limit": "value == 3'd6"},
         [{"when": "zero", "value": "3'd0"}, {"when": "!zero && inc && (value < 3'd6)", "value": "value + 3'd1"}, {"when": "true", "value": "value"}]),
        ("sat_step_three", ["clear", "add"], "value", 4, "4'd0", {"at_limit": "value == 4'd15"},
         [{"when": "clear", "value": "4'd0"}, {"when": "!clear && add && (value < 4'd13)", "value": "value + 4'd3"}, {"when": "true", "value": "value"}]),
        ("sat_priority_clear", ["clear", "inc", "dec"], "value", 3, "3'd3", {"at_zero": "value == 3'd0", "at_max": "value == 3'd7"},
         [{"when": "clear", "value": "3'd3"}, {"when": "!clear && inc && !dec && (value < 3'd7)", "value": "value + 3'd1"}, {"when": "!clear && dec && !inc && (value > 3'd0)", "value": "value - 3'd1"}, {"when": "true", "value": "value"}]),
    ]

    for idx, c in enumerate(configs, start=2):
        did = f"saturating_arithmetic_{idx:04d}"
        guards = [r["when"] for r in c[6] if r["when"] != "true"]
        mutants = []
        for m, g in enumerate(guards[:3], start=1):
            mutants.append({"name": f"drop_rule_{m}", "kind": "replace_update_guard", "old": g, "new": "false"})
        while len(mutants) < 3:
            g = guards[-1]
            mutants.append({"name": f"broaden_rule_{len(mutants)+1}", "kind": "replace_update_guard", "old": g, "new": "true"})
        make_register(did, "saturating_arithmetic", c[0],
                      f"Saturating arithmetic unit implementing {c[0].replace('_', ' ')}.",
                      c[1], c[2], c[3], c[4], c[5], c[6], mutants)


def build_rate_limiters():
    configs = [
        ("token_refill_priority", ["refill", "consume"], "tokens", 3, "3'd0", {"allow": "tokens != 3'd0", "full": "tokens == 3'd7"},
         [{"when": "refill && (tokens < 3'd7)", "value": "tokens + 3'd1"}, {"when": "!refill && consume && (tokens > 3'd0)", "value": "tokens - 3'd1"}, {"when": "true", "value": "tokens"}]),
        ("token_consume_priority", ["refill", "consume"], "tokens", 3, "3'd4", {"allow": "tokens != 3'd0", "full": "tokens == 3'd7"},
         [{"when": "consume && (tokens > 3'd0)", "value": "tokens - 3'd1"}, {"when": "!consume && refill && (tokens < 3'd7)", "value": "tokens + 3'd1"}, {"when": "true", "value": "tokens"}]),
        ("small_bucket", ["refill", "consume"], "tokens", 2, "2'd0", {"allow": "tokens != 2'd0", "full": "tokens == 2'd3"},
         [{"when": "refill && (tokens < 2'd3)", "value": "tokens + 2'd1"}, {"when": "!refill && consume && (tokens > 2'd0)", "value": "tokens - 2'd1"}, {"when": "true", "value": "tokens"}]),
        ("cooldown_budget", ["grant", "recover"], "budget", 3, "3'd7", {"allow": "budget != 3'd0"},
         [{"when": "recover && (budget < 3'd7)", "value": "budget + 3'd1"}, {"when": "!recover && grant && (budget > 3'd0)", "value": "budget - 3'd1"}, {"when": "true", "value": "budget"}]),
        ("quota_counter", ["use", "reset_quota"], "quota", 3, "3'd5", {"allow": "quota != 3'd0"},
         [{"when": "reset_quota", "value": "3'd5"}, {"when": "!reset_quota && use && (quota > 3'd0)", "value": "quota - 3'd1"}, {"when": "true", "value": "quota"}]),
        ("burst_credit", ["earn", "spend"], "credit", 3, "3'd1", {"allow": "credit != 3'd0", "full": "credit == 3'd6"},
         [{"when": "earn && (credit < 3'd6)", "value": "credit + 3'd1"}, {"when": "!earn && spend && (credit > 3'd0)", "value": "credit - 3'd1"}, {"when": "true", "value": "credit"}]),
        ("leaky_budget", ["add", "leak"], "level", 3, "3'd0", {"blocked": "level == 3'd7"},
         [{"when": "add && (level < 3'd7)", "value": "level + 3'd1"}, {"when": "!add && leak && (level > 3'd0)", "value": "level - 3'd1"}, {"when": "true", "value": "level"}]),
        ("admission_tokens", ["admit", "return_token"], "tokens", 3, "3'd3", {"allow": "tokens != 3'd0"},
         [{"when": "return_token && (tokens < 3'd7)", "value": "tokens + 3'd1"}, {"when": "!return_token && admit && (tokens > 3'd0)", "value": "tokens - 3'd1"}, {"when": "true", "value": "tokens"}]),
        ("throttle_score", ["penalty", "recover"], "score", 3, "3'd0", {"blocked": "score == 3'd7"},
         [{"when": "penalty && (score < 3'd7)", "value": "score + 3'd1"}, {"when": "!penalty && recover && (score > 3'd0)", "value": "score - 3'd1"}, {"when": "true", "value": "score"}]),
    ]

    for idx, c in enumerate(configs, start=2):
        did = f"rate_limiter_{idx:04d}"
        guards = [r["when"] for r in c[6] if r["when"] != "true"]
        mutants = [
            {"name": "drop_first_rule", "kind": "replace_update_guard", "old": guards[0], "new": "false"},
            {"name": "drop_second_rule", "kind": "replace_update_guard", "old": guards[1], "new": "false"},
            {"name": "broaden_second_rule", "kind": "replace_update_guard", "old": guards[1], "new": "true"},
        ]
        make_register(did, "rate_limiter", c[0],
                      f"Rate-control state implementing {c[0].replace('_', ' ')}.",
                      c[1], c[2], c[3], c[4], c[5], c[6], mutants)


def build_modes():
    configs = [
        ("sleep_wake", ["enable", "sleep", "wake"], ["active", "sleeping", "off"], ["OFF", "ACTIVE", "SLEEP"],
         {"OFF": {"active": 0, "sleeping": 0, "off": 1}, "ACTIVE": {"active": 1, "sleeping": 0, "off": 0}, "SLEEP": {"active": 0, "sleeping": 1, "off": 0}},
         [
             {"from": "OFF", "when": "enable", "to": "ACTIVE"}, {"from": "OFF", "when": "!enable", "to": "OFF"},
             {"from": "ACTIVE", "when": "!enable", "to": "OFF"}, {"from": "ACTIVE", "when": "enable && sleep", "to": "SLEEP"},
             {"from": "ACTIVE", "when": "enable && !sleep", "to": "ACTIVE"},
             {"from": "SLEEP", "when": "!enable", "to": "OFF"}, {"from": "SLEEP", "when": "enable && wake", "to": "ACTIVE"},
             {"from": "SLEEP", "when": "enable && !wake", "to": "SLEEP"},
         ]),
        ("normal_maintenance", ["enable", "maintenance", "exit_maintenance"], ["normal", "maint", "off"], ["OFF", "NORMAL", "MAINT"],
         {"OFF": {"normal": 0, "maint": 0, "off": 1}, "NORMAL": {"normal": 1, "maint": 0, "off": 0}, "MAINT": {"normal": 0, "maint": 1, "off": 0}},
         [
             {"from": "OFF", "when": "enable", "to": "NORMAL"}, {"from": "OFF", "when": "!enable", "to": "OFF"},
             {"from": "NORMAL", "when": "maintenance", "to": "MAINT"}, {"from": "NORMAL", "when": "!maintenance && !enable", "to": "OFF"},
             {"from": "NORMAL", "when": "!maintenance && enable", "to": "NORMAL"},
             {"from": "MAINT", "when": "exit_maintenance", "to": "NORMAL"}, {"from": "MAINT", "when": "!exit_maintenance", "to": "MAINT"},
         ]),
        ("safe_fault", ["start", "fault", "clear"], ["running", "safe", "faulted"], ["SAFE", "RUN", "FAULT"],
         {"SAFE": {"running": 0, "safe": 1, "faulted": 0}, "RUN": {"running": 1, "safe": 0, "faulted": 0}, "FAULT": {"running": 0, "safe": 0, "faulted": 1}},
         [
             {"from": "SAFE", "when": "start", "to": "RUN"}, {"from": "SAFE", "when": "!start", "to": "SAFE"},
             {"from": "RUN", "when": "fault", "to": "FAULT"}, {"from": "RUN", "when": "!fault", "to": "RUN"},
             {"from": "FAULT", "when": "clear", "to": "SAFE"}, {"from": "FAULT", "when": "!clear", "to": "FAULT"},
         ]),
        ("idle_active_boost", ["activate", "boost", "idle"], ["active", "boosted", "idle_mode"], ["IDLE", "ACTIVE", "BOOST"],
         {"IDLE": {"active": 0, "boosted": 0, "idle_mode": 1}, "ACTIVE": {"active": 1, "boosted": 0, "idle_mode": 0}, "BOOST": {"active": 0, "boosted": 1, "idle_mode": 0}},
         [
             {"from": "IDLE", "when": "activate", "to": "ACTIVE"}, {"from": "IDLE", "when": "!activate", "to": "IDLE"},
             {"from": "ACTIVE", "when": "boost", "to": "BOOST"}, {"from": "ACTIVE", "when": "!boost && idle", "to": "IDLE"},
             {"from": "ACTIVE", "when": "!boost && !idle", "to": "ACTIVE"},
             {"from": "BOOST", "when": "boost", "to": "BOOST"}, {"from": "BOOST", "when": "!boost", "to": "ACTIVE"},
         ]),
        ("locked_unlocked", ["unlock", "lock", "operate"], ["locked", "ready", "active"], ["LOCKED", "READY", "ACTIVE"],
         {"LOCKED": {"locked": 1, "ready": 0, "active": 0}, "READY": {"locked": 0, "ready": 1, "active": 0}, "ACTIVE": {"locked": 0, "ready": 0, "active": 1}},
         [
             {"from": "LOCKED", "when": "unlock", "to": "READY"}, {"from": "LOCKED", "when": "!unlock", "to": "LOCKED"},
             {"from": "READY", "when": "lock", "to": "LOCKED"}, {"from": "READY", "when": "!lock && operate", "to": "ACTIVE"},
             {"from": "READY", "when": "!lock && !operate", "to": "READY"},
             {"from": "ACTIVE", "when": "lock", "to": "LOCKED"}, {"from": "ACTIVE", "when": "!lock && !operate", "to": "READY"},
             {"from": "ACTIVE", "when": "!lock && operate", "to": "ACTIVE"},
         ]),
        ("standby_run_fault", ["run", "fault", "clear"], ["standby", "running", "faulted"], ["STANDBY", "RUN", "FAULT"],
         {"STANDBY": {"standby": 1, "running": 0, "faulted": 0}, "RUN": {"standby": 0, "running": 1, "faulted": 0}, "FAULT": {"standby": 0, "running": 0, "faulted": 1}},
         [
             {"from": "STANDBY", "when": "run", "to": "RUN"}, {"from": "STANDBY", "when": "!run", "to": "STANDBY"},
             {"from": "RUN", "when": "fault", "to": "FAULT"}, {"from": "RUN", "when": "!fault && run", "to": "RUN"},
             {"from": "RUN", "when": "!fault && !run", "to": "STANDBY"},
             {"from": "FAULT", "when": "clear", "to": "STANDBY"}, {"from": "FAULT", "when": "!clear", "to": "FAULT"},
         ]),
        ("boot_ready_run", ["boot_ok", "start", "stop"], ["booting", "ready", "running"], ["BOOT", "READY", "RUN"],
         {"BOOT": {"booting": 1, "ready": 0, "running": 0}, "READY": {"booting": 0, "ready": 1, "running": 0}, "RUN": {"booting": 0, "ready": 0, "running": 1}},
         [
             {"from": "BOOT", "when": "boot_ok", "to": "READY"}, {"from": "BOOT", "when": "!boot_ok", "to": "BOOT"},
             {"from": "READY", "when": "start", "to": "RUN"}, {"from": "READY", "when": "!start", "to": "READY"},
             {"from": "RUN", "when": "stop", "to": "READY"}, {"from": "RUN", "when": "!stop", "to": "RUN"},
         ]),
        ("primary_backup", ["enable", "fail", "recover"], ["primary", "backup", "off"], ["OFF", "PRIMARY", "BACKUP"],
         {"OFF": {"primary": 0, "backup": 0, "off": 1}, "PRIMARY": {"primary": 1, "backup": 0, "off": 0}, "BACKUP": {"primary": 0, "backup": 1, "off": 0}},
         [
             {"from": "OFF", "when": "enable", "to": "PRIMARY"}, {"from": "OFF", "when": "!enable", "to": "OFF"},
             {"from": "PRIMARY", "when": "fail", "to": "BACKUP"}, {"from": "PRIMARY", "when": "!fail && enable", "to": "PRIMARY"},
             {"from": "PRIMARY", "when": "!fail && !enable", "to": "OFF"},
             {"from": "BACKUP", "when": "recover", "to": "PRIMARY"}, {"from": "BACKUP", "when": "!recover && enable", "to": "BACKUP"},
             {"from": "BACKUP", "when": "!recover && !enable", "to": "OFF"},
         ]),
        ("manual_auto", ["enable", "auto_mode", "disable"], ["manual", "auto_active", "off"], ["OFF", "MANUAL", "AUTO"],
         {"OFF": {"manual": 0, "auto_active": 0, "off": 1}, "MANUAL": {"manual": 1, "auto_active": 0, "off": 0}, "AUTO": {"manual": 0, "auto_active": 1, "off": 0}},
         [
             {"from": "OFF", "when": "enable && auto_mode", "to": "AUTO"}, {"from": "OFF", "when": "enable && !auto_mode", "to": "MANUAL"},
             {"from": "OFF", "when": "!enable", "to": "OFF"},
             {"from": "MANUAL", "when": "disable", "to": "OFF"}, {"from": "MANUAL", "when": "!disable && auto_mode", "to": "AUTO"},
             {"from": "MANUAL", "when": "!disable && !auto_mode", "to": "MANUAL"},
             {"from": "AUTO", "when": "disable", "to": "OFF"}, {"from": "AUTO", "when": "!disable && !auto_mode", "to": "MANUAL"},
             {"from": "AUTO", "when": "!disable && auto_mode", "to": "AUTO"},
         ]),
    ]
    for idx, c in enumerate(configs, start=2):
        did = f"mode_controller_{idx:04d}"
        make_fsm(did, "mode_controller", c[0],
                 f"Mode controller implementing {c[0].replace('_', ' ')} behavior.",
                 c[1], c[2], c[3], c[3][0], c[4], c[5])


def generate_created_specs():
    specs = []
    for p in ROOT.glob("*/spec.json"):
        name = p.parent.name
        # Only v2 additions: old categories 0006..0010 or new categories 0002..0010.
        prefix, n = name.rsplit("_", 1)
        try:
            idx = int(n)
        except ValueError:
            continue
        if prefix in {"handshake", "timer", "arbiter", "counter", "fifo", "interrupt"}:
            if 6 <= idx <= 10:
                specs.append(p)
        elif prefix in {
            "pulse_event", "sequence_detector", "protocol_controller",
            "saturating_arithmetic", "rate_limiter", "mode_controller",
        }:
            if 2 <= idx <= 10:
                specs.append(p)

    specs = sorted(specs)

    for p in specs:
        spec = json.loads(p.read_text())
        mt = spec.get("model_type")
        if mt == "register_rules":
            gen = "generator/generate_register_family.py"
        elif mt == "multi_register_rules":
            gen = "generator/generate_multi_register_family.py"
        else:
            gen = "generator/generate_family.py"

        print("GENERATE", p.parent.name)
        subprocess.run([sys.executable, gen, "--spec", str(p)], check=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--generate",
        action="store_true",
        help="Also run the existing RTL/property/mutant generators. No formal validation.",
    )
    args = ap.parse_args()

    build_handshakes()
    build_timers()
    build_arbiters()
    build_counters()
    build_fifos()
    build_interrupts()

    build_pulse_events()
    build_sequence_detectors()
    build_protocols()
    build_saturating_arithmetic()
    build_rate_limiters()
    build_modes()

    print("\nBehaviorSpec expansion complete.")

    if args.generate:
        print("\nGenerating RTL/properties/mutants for the 84 new families...")
        generate_created_specs()
        print("\nGeneration complete. No formal validation was run.")


if __name__ == "__main__":
    main()
