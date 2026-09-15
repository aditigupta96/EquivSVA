#!/usr/bin/env python3

import argparse
import hashlib
import json
import re
from itertools import combinations
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATASET = ROOT / "dataset"
REPORT_DIR = ROOT / "build" / "audit"

NEAR_DUPLICATE_THRESHOLD = 0.90
SHINGLE_SIZE = 5


def replace_identifiers(text, mapping):
    if text is None:
        return None

    result = str(text)

    # Longest names first to avoid partial replacement.
    for old in sorted(mapping, key=len, reverse=True):
        result = re.sub(
            rf"\b{re.escape(old)}\b",
            mapping[old],
            result,
        )

    # Normalize whitespace.
    result = re.sub(r"\s+", " ", result).strip()

    return result


def canonical_properties(spec, mapping):
    properties = []

    for prop in spec.get("properties", []):
        canonical_property = {
            "type": prop.get("type"),
        }

        for field in [
            "expression",
            "antecedent",
            "consequent",
            "disable",
        ]:
            if field in prop:
                canonical_property[field] = (
                    replace_identifiers(
                        prop[field],
                        mapping,
                    )
                )

        if "delay" in prop:
            canonical_property["delay"] = prop["delay"]

        properties.append(canonical_property)

    return properties


def canonical_behavior(spec):
    """
    Build a behavior representation that removes superficial
    identifier choices while retaining behavioral structure.

    FSM families preserve ordered transitions.

    register_rules families preserve register widths, ordered
    update rules, derived outputs, and interface properties.
    """
    model_type = spec.get("model_type", "fsm")

    inputs = spec.get("inputs", [])
    outputs = spec.get("outputs", [])

    mapping = {}

    for i, name in enumerate(inputs):
        mapping[name] = f"I{i}"

    for i, name in enumerate(outputs):
        mapping[name] = f"O{i}"

    widths = spec.get("signal_widths", {})

    common = {
        "model_type": model_type,
        "input_count": len(inputs),
        "output_count": len(outputs),
        "input_widths": [
            int(widths.get(name, 1))
            for name in inputs
        ],
        "output_widths": [
            int(widths.get(name, 1))
            for name in outputs
        ],
    }

    if model_type == "register_rules":
        registers = spec.get("registers", [])

        for i, register in enumerate(registers):
            name = register["name"]

            if name not in mapping:
                mapping[name] = f"R{i}"

        canonical_registers = []

        for register in registers:
            canonical_registers.append({
                "name": mapping[register["name"]],
                "width": int(register["width"]),
                "reset_value": replace_identifiers(
                    register.get("reset_value"),
                    mapping,
                ),
                "observable": bool(
                    register.get("observable", False)
                ),
            })

        derived_outputs = []

        for output in outputs:
            expression = spec.get(
                "derived_outputs",
                {},
            ).get(output)

            if expression is not None:
                derived_outputs.append({
                    "output": mapping[output],
                    "expression": replace_identifiers(
                        expression,
                        mapping,
                    ),
                })

        update_rules = []

        # Rule ordering is semantically significant because it
        # defines update priority.
        for rule in spec.get("update_rules", []):
            update_rules.append({
                "when": replace_identifiers(
                    rule["when"],
                    mapping,
                ),
                "value": replace_identifiers(
                    rule["value"],
                    mapping,
                ),
            })

        common.update({
            "registers": canonical_registers,
            "derived_outputs": derived_outputs,
            "update_rules": update_rules,
            "properties": canonical_properties(
                spec,
                mapping,
            ),
        })

        return common

    if model_type != "fsm":
        raise ValueError(
            f"Unsupported model_type for overlap audit: "
            f"{model_type}"
        )

    states = spec.get("states", [])

    for i, name in enumerate(states):
        mapping[name] = f"S{i}"

    reset = spec.get("reset", {})

    state_outputs = []

    for state in states:
        output_values = spec.get(
            "state_outputs",
            {},
        ).get(state, {})

        canonical_outputs = [
            (
                mapping[output],
                output_values.get(output, 0),
            )
            for output in outputs
        ]

        state_outputs.append(
            (
                mapping[state],
                canonical_outputs,
            )
        )

    transitions = []

    # Preserve transition order because it encodes priority.
    for transition in spec.get("transitions", []):
        transitions.append({
            "from": mapping[transition["from"]],
            "when": replace_identifiers(
                transition["when"],
                mapping,
            ),
            "to": mapping[transition["to"]],
        })

    common.update({
        "state_count": len(states),
        "reset_state": mapping.get(
            reset.get("state"),
            reset.get("state"),
        ),
        "state_outputs": state_outputs,
        "transitions": transitions,
        "properties": canonical_properties(
            spec,
            mapping,
        ),
    })

    return common


def canonical_text(behavior):
    return json.dumps(
        behavior,
        sort_keys=True,
        separators=(",", ":"),
    )


def fingerprint(text):
    return hashlib.sha256(
        text.encode("utf-8")
    ).hexdigest()


def tokens(text):
    return re.findall(
        r"[A-Za-z0-9_]+|&&|\|\||!|==|!=|[(){}:,]",
        text,
    )


def shingles(text, size=SHINGLE_SIZE):
    ts = tokens(text)

    if len(ts) < size:
        return {tuple(ts)}

    return {
        tuple(ts[i:i + size])
        for i in range(len(ts) - size + 1)
    }


def jaccard(a, b):
    if not a and not b:
        return 1.0

    union = a | b

    if not union:
        return 0.0

    return len(a & b) / len(union)


def load_splits(path):
    if not path.exists():
        return {}

    data = json.loads(path.read_text())
    mapping = {}

    for split in ["train", "dev", "test"]:
        for design_id in data.get(split, []):
            mapping[design_id] = split

    return mapping


def main():
    parser = argparse.ArgumentParser(
        description="Audit internal EquivSVA behavior overlap."
    )
    parser.add_argument(
        "--splits",
        default=str(DATASET / "splits_v0.2.json"),
        help="Split file used for split annotations.",
    )
    args = parser.parse_args()

    split_path = Path(args.splits).resolve()

    specs = sorted(DATASET.glob("*/spec.json"))

    if not specs:
        raise SystemExit(
            "No dataset families found."
        )

    split_map = load_splits(split_path)

    families = []

    for path in specs:
        spec = json.loads(path.read_text())

        behavior = canonical_behavior(spec)
        text = canonical_text(behavior)

        families.append({
            "design_id": spec["design_id"],
            "category": spec["category"],
            "split": split_map.get(
                spec["design_id"],
                "unassigned",
            ),
            "fingerprint": fingerprint(text),
            "shingles": shingles(text),
        })

    exact_duplicates = []
    near_duplicates = []

    for left, right in combinations(families, 2):
        same_fingerprint = (
            left["fingerprint"]
            == right["fingerprint"]
        )

        similarity = jaccard(
            left["shingles"],
            right["shingles"],
        )

        pair = {
            "left": left["design_id"],
            "right": right["design_id"],
            "left_category": left["category"],
            "right_category": right["category"],
            "left_split": left["split"],
            "right_split": right["split"],
            "similarity": round(similarity, 4),
        }

        if same_fingerprint:
            exact_duplicates.append(pair)

        elif similarity >= NEAR_DUPLICATE_THRESHOLD:
            near_duplicates.append(pair)

    near_duplicates.sort(
        key=lambda x: x["similarity"],
        reverse=True,
    )

    report = {
        "benchmark": "EquivSVA",
        "audit": "internal_behavior_overlap",
        "families_checked": len(families),
        "pairs_checked": (
            len(families) * (len(families) - 1) // 2
        ),
        "near_duplicate_threshold": (
            NEAR_DUPLICATE_THRESHOLD
        ),
        "shingle_size": SHINGLE_SIZE,
        "exact_duplicates": exact_duplicates,
        "near_duplicates": near_duplicates,
    }

    REPORT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    report_path = (
        REPORT_DIR
        / "internal_overlap.json"
    )

    report_path.write_text(
        json.dumps(report, indent=2)
        + "\n"
    )

    print("EquivSVA Internal Overlap Audit")
    print("===============================")
    print(
        f"Families checked: "
        f"{len(families)}"
    )
    print(
        f"Family pairs:     "
        f"{report['pairs_checked']}"
    )
    print(
        f"Exact duplicates: "
        f"{len(exact_duplicates)}"
    )
    print(
        f"Near duplicates:  "
        f"{len(near_duplicates)} "
        f"(threshold >= {NEAR_DUPLICATE_THRESHOLD})"
    )

    if near_duplicates:
        print()
        print("Near-duplicate candidates:")

        for pair in near_duplicates:
            print(
                f"  {pair['left']} "
                f"<-> {pair['right']}: "
                f"{pair['similarity']:.4f}"
            )

    print()
    print(
        "Report: "
        f"{report_path.relative_to(ROOT)}"
    )

    if exact_duplicates:
        print()
        print("OVERLAP AUDIT FAILED")
        print(
            "Exact canonical behavior duplicates detected."
        )

        for pair in exact_duplicates:
            print(
                f"  {pair['left']} "
                f"<-> {pair['right']}"
            )

        raise SystemExit(1)

    print()
    print("INTERNAL OVERLAP AUDIT PASS")


if __name__ == "__main__":
    main()
