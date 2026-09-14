#!/usr/bin/env python3

import json
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATASET = ROOT / "dataset"

SPLITS_PATH = DATASET / "splits_v0.1.json"


def main():
    manifest = json.loads(
        (DATASET / "manifest.json").read_text()
    )

    splits = json.loads(
        SPLITS_PATH.read_text()
    )

    family_to_category = {
        family["design_id"]: family["category"]
        for family in manifest["families"]
    }

    expected = set(family_to_category)

    seen = {}
    problems = []

    for split in ["train", "dev", "test"]:
        for family in splits.get(split, []):
            if family not in expected:
                problems.append(
                    f"{family}: appears in {split} but is "
                    "not present in the dataset manifest"
                )
                continue

            if family in seen:
                problems.append(
                    f"{family}: appears in both "
                    f"{seen[family]} and {split}"
                )
            else:
                seen[family] = split

    missing = sorted(expected - set(seen))

    if missing:
        problems.append(
            "Families missing from splits: "
            + ", ".join(missing)
        )

    extra = sorted(set(seen) - expected)

    if extra:
        problems.append(
            "Unknown families in splits: "
            + ", ".join(extra)
        )

    print("EquivSVA Split Validation")
    print("=========================")

    for split in ["train", "dev", "test"]:
        families = splits[split]

        categories = Counter(
            family_to_category[f]
            for f in families
            if f in family_to_category
        )

        print()
        print(f"{split.upper()}: {len(families)} families")

        for category in sorted(categories):
            print(
                f"  {category}: "
                f"{categories[category]}"
            )

    print()

    if problems:
        print("SPLIT VALIDATION FAILED")

        for problem in problems:
            print(f"  - {problem}")

        raise SystemExit(1)

    print(
        f"Families accounted for: "
        f"{len(seen)}/{len(expected)}"
    )
    print("No family leakage detected.")
    print("SPLIT VALIDATION PASS")


if __name__ == "__main__":
    main()
