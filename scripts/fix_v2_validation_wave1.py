#!/usr/bin/env python3
"""
Repair the failure classes observed in EquivSVA v2's first full validation.

Edits specs and optionally regenerates ONLY patched families.
It does NOT run formal validation.

Usage:
  python scripts/fix_v2_validation_wave1.py
  python scripts/fix_v2_validation_wave1.py --generate
"""

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path("dataset")
VALIDATION = Path("build/validation")
CHANGED = set()


def load(design_id):
    p = ROOT / design_id / "spec.json"
    return p, json.loads(p.read_text())


def save(p, spec):
    p.write_text(json.dumps(spec, indent=2) + "\n")
    CHANGED.add(spec["design_id"])
    print("PATCHED", spec["design_id"])


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


def add_prop(spec, prop):
    ids = {p["id"] for p in spec.get("properties", [])}
    names = {p["sva_name"] for p in spec.get("properties", [])}
    if prop["id"] not in ids and prop["sva_name"] not in names:
        spec.setdefault("properties", []).append(prop)


def validation_records():
    out = {}
    for p in sorted(VALIDATION.glob("*.json")):
        if p.name == "dataset_summary.json":
            continue
        try:
            data = json.loads(p.read_text())
        except Exception:
            continue
        if isinstance(data, list):
            out[p.stem] = data
    return out


def patch_failed_self_loop_mutants():
    """
    Generated FSM RTL defaults next_state to the current state. Therefore:
        S --guard--> S
    changed to guard=false is behaviorally identical and is a bad mutant.

    Replace only failed mutant_diff_drop_tN jobs with rc=2 whose referenced
    transition is actually a self-loop. The replacement forces an incorrect
    exit from that state, producing an observable behavioral defect.
    """
    records = validation_records()
    pat = re.compile(r"^mutant_diff_drop_t(\d+)$")
    repairs = []

    for design_id, rows in records.items():
        p, spec = load(design_id)

        # Generic drop_tN mutations are for FSM specs.
        if spec.get("model_type"):
            continue

        transitions = spec.get("transitions", [])
        mutants = spec.get("mutants", [])

        for row in rows:
            if not isinstance(row, dict) or row.get("returncode") != 2:
                continue

            m = pat.match(row.get("job") or "")
            if not m:
                continue

            idx = int(m.group(1))
            if idx < 1 or idx > len(transitions):
                print("WARNING bad transition index:", design_id, idx)
                continue

            t = transitions[idx - 1]

            if t["from"] != t["to"]:
                print(
                    "MANUAL_REVIEW:",
                    design_id,
                    f"drop_t{idx}",
                    "failed but is not a self-loop:",
                    t,
                )
                continue

            exits = [
                x for x in transitions
                if x["from"] == t["from"] and x["to"] != t["from"]
            ]
            if not exits:
                print(
                    "MANUAL_REVIEW:",
                    design_id,
                    f"drop_t{idx}",
                    "has no state-changing exit from",
                    t["from"],
                )
                continue

            old_name = f"drop_t{idx}"
            pos = next(
                (i for i, mut in enumerate(mutants)
                 if mut.get("name") == old_name),
                None,
            )
            if pos is None:
                print("WARNING mutant not found:", design_id, old_name)
                continue

            target = exits[0]["to"]
            mutants[pos] = {
                "name": f"force_exit_t{idx}",
                "kind": "force_transition",
                "from": t["from"],
                "to": target,
            }
            repairs.append((design_id, old_name, f"force_exit_t{idx}"))
            spec["mutants"] = mutants
            save(p, spec)

    print()
    print("Systematic no-op FSM mutants repaired:", len(repairs))
    for design_id, old, new in repairs:
        print(f"  {design_id}: {old} -> {new}")


def patch_mode_controller_0010():
    p, spec = load("mode_controller_0010")

    # "disable" is a SystemVerilog keyword. Rename only string values,
    # preserving dict keys such as the property metadata key "disable".
    def rec(x):
        if isinstance(x, str):
            return re.sub(r"\bdisable\b", "turn_off", x)
        if isinstance(x, list):
            return [rec(v) for v in x]
        if isinstance(x, dict):
            return {k: rec(v) for k, v in x.items()}
        return x

    new_spec = rec(spec)
    if new_spec != spec:
        save(p, new_spec)


def patch_counter_0010():
    p, spec = load("counter_0010")
    for i, m in enumerate(spec.get("mutants", [])):
        if m.get("name") == "increment_beats_load":
            # Broadening a lower-priority rule was shadowed by load, so the old
            # mutant was equivalent. Make increment improperly suppress load.
            spec["mutants"][i] = {
                "name": "load_blocked_by_increment",
                "kind": "replace_update_guard",
                "old": "load",
                "new": "load && !increment",
            }
            save(p, spec)
            return


def patch_fifo_0010():
    p, spec = load("fifo_0010")
    add_prop(
        spec,
        nxt(
            "P9_FULL_PUSH_HOLD",
            "p_full_push_hold",
            "a push into a full FIFO without a simultaneous pop leaves occupancy full",
            "!flush && (count == 3'd4) && push && !pop",
            "count == 3'd4",
        ),
    )
    save(p, spec)


def patch_protocol_0002():
    p, spec = load("protocol_controller_0002")
    add_prop(
        spec,
        nxt(
            "P7_CANCEL_EXEC",
            "p_cancel_exec",
            "cancel during execution terminates the operation",
            "executing && cancel",
            "cancelled",
        ),
    )
    save(p, spec)


def patch_protocol_0004():
    p, spec = load("protocol_controller_0004")
    add_prop(
        spec,
        nxt(
            "P7_RESET_FAILURE",
            "p_reset_failure",
            "reset_fail releases the terminal failure state",
            "failed && reset_fail",
            "!attempting && !retrying && !done && !failed",
        ),
    )
    save(p, spec)


def patch_rate_0007():
    p, spec = load("rate_limiter_0007")
    add_prop(
        spec,
        nxt(
            "P8_PHASE_WRAP",
            "p_phase_wrap",
            "advancing the final phase wraps the window phase to zero",
            "advance_window && (phase == 2'd3)",
            "phase == 2'd0",
        ),
    )
    save(p, spec)


def patch_sat_0003():
    p, spec = load("saturating_arithmetic_0003")
    add_prop(
        spec,
        nxt(
            "P7_CLEAR_DIRECTION",
            "p_clear_direction",
            "clear removes the remembered update direction",
            "clear",
            "!last_up && !last_down",
        ),
    )
    save(p, spec)


def patch_sat_0004():
    p, spec = load("saturating_arithmetic_0004")

    # Preserve sticky-overflow semantics but move the saturation point from 15
    # to 3 so cover and mutant-difference witnesses fit the benchmark's
    # intentionally shallow formal horizon.
    def rec(x):
        if isinstance(x, str):
            return x.replace("4'd15", "4'd3")
        if isinstance(x, list):
            return [rec(v) for v in x]
        if isinstance(x, dict):
            return {k: rec(v) for k, v in x.items()}
        return x

    spec = rec(spec)
    spec["description"] = (
        "Accumulator saturates at three and latches a sticky overflow "
        "indication until clear."
    )
    save(p, spec)


def patch_sat_0009():
    p, spec = load("saturating_arithmetic_0009")

    # clear_history has priority over setting either sticky history bit.
    for prop in spec.get("properties", []):
        if prop.get("id") == "P4_HIGH_HISTORY":
            prop["antecedent"] = (
                "!clear_history && inc && !dec && (value == 3'd5)"
            )
        elif prop.get("id") == "P5_LOW_HISTORY":
            prop["antecedent"] = (
                "!clear_history && dec && !inc && (value == 3'd2)"
            )

    save(p, spec)


def patch_pulse_0007():
    p, spec = load("pulse_event_0007")

    # COOL1 and COOL2 previously had the exact same external outputs.
    # Interface-only properties therefore could not distinguish the phases.
    spec["outputs"] = ["armed", "pulse", "cooldown1", "cooldown2"]
    spec["state_outputs"] = {
        "ARMED": {
            "armed": 1, "pulse": 0, "cooldown1": 0, "cooldown2": 0
        },
        "PULSE": {
            "armed": 0, "pulse": 1, "cooldown1": 0, "cooldown2": 0
        },
        "COOL1": {
            "armed": 0, "pulse": 0, "cooldown1": 1, "cooldown2": 0
        },
        "COOL2": {
            "armed": 0, "pulse": 0, "cooldown1": 0, "cooldown2": 1
        },
    }

    spec["properties"] = [
        inv(
            "P1_ONEHOT",
            "p_onehot",
            "exactly one pulse-controller phase is externally visible",
            "$onehot({armed, pulse, cooldown1, cooldown2})",
        ),
        nxt(
            "P2_RESET",
            "p_reset",
            "reset arms the pulse controller",
            "rst",
            "armed",
            disable=None,
        ),
        nxt(
            "P3_FIRE",
            "p_fire",
            "a trigger while armed emits a one-cycle pulse",
            "armed && trigger",
            "pulse",
        ),
        nxt(
            "P4_IDLE",
            "p_idle",
            "without a trigger the armed controller remains armed",
            "armed && !trigger",
            "armed",
        ),
        nxt(
            "P5_COOL1",
            "p_cool1",
            "a pulse enters the first cooldown phase",
            "pulse",
            "cooldown1",
        ),
        nxt(
            "P6_COOL2",
            "p_cool2",
            "the first cooldown phase advances to the second",
            "cooldown1",
            "cooldown2",
        ),
        nxt(
            "P7_REARM",
            "p_rearm",
            "the second cooldown phase rearms the controller",
            "cooldown2",
            "armed",
        ),
    ]

    save(p, spec)


def regenerate():
    for design_id in sorted(CHANGED):
        d = ROOT / design_id

        for child in ("rtl", "mutants", "properties"):
            q = d / child
            if q.exists():
                shutil.rmtree(q)

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
        subprocess.run(
            [sys.executable, gen, "--spec", str(spec_path)],
            check=True,
        )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--generate", action="store_true")
    args = ap.parse_args()

    patch_failed_self_loop_mutants()

    patch_mode_controller_0010()
    patch_counter_0010()
    patch_fifo_0010()
    patch_protocol_0002()
    patch_protocol_0004()
    patch_rate_0007()
    patch_sat_0003()
    patch_sat_0004()
    patch_sat_0009()
    patch_pulse_0007()

    print()
    print("Families patched:", len(CHANGED))
    for design_id in sorted(CHANGED):
        print(" ", design_id)

    if args.generate:
        print()
        regenerate()
        print()
        print("Regeneration complete. No formal validation was run.")


if __name__ == "__main__":
    main()
