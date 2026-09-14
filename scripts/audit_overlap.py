#!/usr/bin/env python3

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


def canonical_behavior(spec):
    """
    Build a behavior representation that ignores superficial names such as:

        req   vs request
        WAIT  vs BUSY
        ack   vs grant

    while preserving transition ordering, because transition ordering
    represents priority semantics.
    """

    inputs = spec.get("inputs", [])
    outputs = spec.get("outputs", [])
    states = spec.get("states", [])

    mapping = {}

    for i, name in enumerate(inputs):
        mapping[name] = f"I{i}"

    for i, name in enumerate(outputs):
        mapping[name] = f"O{i}"

    for i, name in enumerate(states):
        mapping[name] = f"S{i}"

    reset = spec.get("reset", {})

    state_outputs = []

    for state in states:
        output_values = spec.get(
            "state_outputs",
            {}
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

    # Preserve transition order.
    for transition in spec.get("transitions", []):
        transitions.append({
            "from": mapping[transition["from"]],
            "when": replace_identifiers(
                transition["when"],
                mapping,
            ),
            "to": mapping[transition["to"]],
        })

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

    return {
        "input_count": len(inputs),
        "output_count": len(outputs),
        "state_count": len(states),
        "reset_state": mapping.get(
            reset.get("state"),
            reset.get("state"),
        ),
        "state_outputs": state_outputs,
        "transitions": transitions,
        "properties": properties,
    }


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


def load_splits():
    path = DATASET / "splits_v0.1.json"

    if not path.exists():
        return {}

    data = json.loads(path.read_text())

    mapping = {}

    for split in ["train", "dev", "test"]:
        for design_id in data.get(split, []):
            mapping[design_id] = split

    return mapping


def main():
    specs = sorted(DATASET.glob("*/spec.json"))

    if not specs:
        raise SystemExit(
            "No dataset families found."
        )

    split_map = load_splits()

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
