#!/usr/bin/env python3

import json
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path("dataset")

SV_LITERAL = re.compile(r"\b\d+'[sS]?[bBdDhHoO][0-9a-fA-F_xXzZ]+\b")
NUMBER = re.compile(r"\b\d+\b")
IDENT = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\b")

KEYWORDS = {
    "true", "false", "posedge", "negedge",
    "past", "onehot", "onehot0",
}


def norm_expr(expr, mapping, shape=False):
    if expr is None:
        return None

    expr = str(expr)

    def repl_ident(m):
        x = m.group(0)
        if x in mapping:
            return mapping[x]
        return x

    expr = IDENT.sub(repl_ident, expr)

    if shape:
        expr = SV_LITERAL.sub("CONST", expr)
        expr = NUMBER.sub("N", expr)

    return " ".join(expr.split())


def mappings(spec):
    inputs = spec.get("inputs", [])
    outputs = spec.get("outputs", [])
    registers = [r["name"] for r in spec.get("registers", [])]
    states = spec.get("states", [])

    m = {}

    for i, x in enumerate(inputs):
        m[x] = f"I{i}"

    for i, x in enumerate(outputs):
        m[x] = f"O{i}"

    for i, x in enumerate(registers):
        if x not in m:
            m[x] = f"R{i}"

    for i, x in enumerate(states):
        m[x] = f"S{i}"

    return m


def signature(spec, shape=False):
    m = mappings(spec)

    model = spec.get("model_type")

    # FSM specs do not have an explicit model_type.
    if not model:
        outputs = spec["outputs"]
        states = spec["states"]

        state_outputs = tuple(
            tuple(spec["state_outputs"][s][o] for o in outputs)
            for s in states
        )

        transitions = tuple(
            (
                m[t["from"]],
                norm_expr(t["when"], m, shape),
                m[t["to"]],
            )
            for t in spec["transitions"]
        )

        return (
            "fsm",
            len(spec.get("inputs", [])),
            len(outputs),
            len(states),
            m[spec["reset"]["state"]],
            state_outputs,
            transitions,
        )

    if model == "register_rules":
        reg = spec["registers"][0]

        width = "W" if shape else reg["width"]
        reset = norm_expr(reg["reset_value"], m, shape)

        derived = tuple(
            (
                m.get(name, name),
                norm_expr(expr, m, shape),
            )
            for name, expr in spec.get("derived_outputs", {}).items()
        )

        rules = tuple(
            (
                norm_expr(r["when"], m, shape),
                norm_expr(r["value"], m, shape),
            )
            for r in spec["update_rules"]
        )

        return (
            "register_rules",
            len(spec.get("inputs", [])),
            len(spec.get("outputs", [])),
            width,
            reset,
            derived,
            rules,
        )

    if model == "multi_register_rules":
        regs = spec["registers"]

        reg_shape = tuple(
            (
                "W" if shape else r["width"],
                norm_expr(r["reset_value"], m, shape),
            )
            for r in regs
        )

        derived = tuple(
            (
                m.get(name, name),
                norm_expr(expr, m, shape),
            )
            for name, expr in spec.get("derived_outputs", {}).items()
        )

        rules = []

        for r in regs:
            name = r["name"]
            rr = spec["update_rules"][name]

            rules.append(
                (
                    m[name],
                    tuple(
                        (
                            norm_expr(x["when"], m, shape),
                            norm_expr(x["value"], m, shape),
                        )
                        for x in rr
                    ),
                )
            )

        return (
            "multi_register_rules",
            len(spec.get("inputs", [])),
            len(spec.get("outputs", [])),
            reg_shape,
            derived,
            tuple(rules),
        )

    return ("unknown", model)


specs = {}

for p in sorted(ROOT.glob("*/spec.json")):
    spec = json.loads(p.read_text())
    specs[spec["design_id"]] = spec


print("=" * 76)
print("DATASET SUMMARY")
print("=" * 76)

print("Families:", len(specs))

category_counts = Counter(s["category"] for s in specs.values())

for k, v in sorted(category_counts.items()):
    print(f"{k:<28} {v}")

property_counts = [
    len(s.get("properties", []))
    for s in specs.values()
]

print()
print("Gold properties:", sum(property_counts))
print("Properties/family:",
      f"min={min(property_counts)}",
      f"max={max(property_counts)}",
      f"avg={sum(property_counts)/len(property_counts):.2f}")


# ------------------------------------------------------------
# Basic consistency checks
# ------------------------------------------------------------

problems = []

for design_id, spec in specs.items():

    properties = spec.get("properties", [])
    mutants = spec.get("mutants", [])

    prop_ids = [p["id"] for p in properties]
    sva_names = [p["sva_name"] for p in properties]

    if len(prop_ids) != len(set(prop_ids)):
        problems.append((design_id, "duplicate property IDs"))

    if len(sva_names) != len(set(sva_names)):
        problems.append((design_id, "duplicate SVA names"))

    if len(mutants) != 3:
        problems.append(
            (design_id, f"expected 3 mutants, found {len(mutants)}")
        )

    variant_count = len(spec.get("rtl_variants", []))

    # Older v1 FSM specs predate the rtl_variants metadata field.
    # For those, use the generated RTL files as the source of truth.
    if variant_count == 0:
        variant_count = len(
            list((ROOT / design_id / "rtl").glob("*.sv"))
        )

    if variant_count != 4:
        problems.append(
            (
                design_id,
                f"expected 4 RTL variants, found {variant_count}",
            )
        )

    model = spec.get("model_type")

    if not model:
        states = set(spec.get("states", []))

        if spec["reset"]["state"] not in states:
            problems.append((design_id, "reset state missing"))

        for t in spec.get("transitions", []):
            if t["from"] not in states:
                problems.append(
                    (design_id, f"bad transition source {t['from']}")
                )
            if t["to"] not in states:
                problems.append(
                    (design_id, f"bad transition target {t['to']}")
                )

        used_sources = {t["from"] for t in spec.get("transitions", [])}

        missing = states - used_sources

        if missing:
            problems.append(
                (
                    design_id,
                    "states without outgoing transitions: "
                    + ",".join(sorted(missing)),
                )
            )

    elif model == "register_rules":
        rules = spec.get("update_rules", [])

        if not rules or rules[-1].get("when") != "true":
            problems.append(
                (design_id, "register rules do not end in true hold rule")
            )

    elif model == "multi_register_rules":
        for reg in spec.get("registers", []):
            name = reg["name"]
            rules = spec.get("update_rules", {}).get(name, [])

            if not rules or rules[-1].get("when") != "true":
                problems.append(
                    (
                        design_id,
                        f"{name} rules do not end in true hold rule",
                    )
                )


print()
print("=" * 76)
print("CONSISTENCY")
print("=" * 76)

if problems:
    print("FAIL:", len(problems), "issues")
    for family, issue in problems:
        print(f"{family:<32} {issue}")
else:
    print("PASS")


# ------------------------------------------------------------
# Exact behavior duplicates after renaming signals/states.
# ------------------------------------------------------------

exact = defaultdict(list)

for design_id, spec in specs.items():
    exact[signature(spec, shape=False)].append(design_id)

exact_groups = [
    group
    for group in exact.values()
    if len(group) > 1
]

print()
print("=" * 76)
print("EXACT BEHAVIOR CLONES")
print("=" * 76)

if not exact_groups:
    print("None")
else:
    for group in sorted(exact_groups):
        print("  " + ", ".join(group))


# ------------------------------------------------------------
# Shape duplicates: ignores literal widths/numeric constants.
#
# These are not automatically wrong. They identify families that
# may differ mainly by parameters and deserve manual review.
# ------------------------------------------------------------

shape = defaultdict(list)

for design_id, spec in specs.items():
    shape[signature(spec, shape=True)].append(design_id)

shape_groups = [
    group
    for group in shape.values()
    if len(group) > 1
]

print()
print("=" * 76)
print("PARAMETER/SHAPE-SIMILAR GROUPS")
print("=" * 76)

if not shape_groups:
    print("None")
else:
    for group in sorted(
        shape_groups,
        key=lambda x: (-len(x), x),
    ):
        cats = sorted({
            specs[x]["category"]
            for x in group
        })

        print(
            f"[{len(group)}] "
            + ", ".join(group)
            + "    categories="
            + ",".join(cats)
        )


# ------------------------------------------------------------
# Category-local template uniqueness
# ------------------------------------------------------------

print()
print("=" * 76)
print("TEMPLATES")
print("=" * 76)

for category in sorted(category_counts):
    members = sorted(
        (
            s for s in specs.values()
            if s["category"] == category
        ),
        key=lambda s: s["design_id"],
    )

    templates = [
        s.get("template", "<none>")
        for s in members
    ]

    duplicates = [
        k
        for k, v in Counter(templates).items()
        if v > 1
    ]

    print(
        f"{category:<28}"
        f"families={len(members):2d}  "
        f"unique_templates={len(set(templates)):2d}"
    )

    if duplicates:
        print("   repeated:", ", ".join(duplicates))


print()
print("=" * 76)
print("AUDIT COMPLETE")
print("=" * 76)
