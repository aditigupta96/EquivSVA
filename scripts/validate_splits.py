#!/usr/bin/env python3

import argparse
import json
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATASET = ROOT / "dataset"


def main():
    parser = argparse.ArgumentParser(
        description="Validate EquivSVA family-safe splits."
    )
    parser.add_argument(
        "--splits",
        default=str(DATASET / "splits_v0.2.json"),
        help="Split JSON to validate.",
    )
    args = parser.parse_args()

    splits_path = Path(args.splits).resolve()

    if not splits_path.exists():
        raise SystemExit(
            f"Split file not found: {splits_path}"
        )

    manifest_path = DATASET / "manifest.json"

    if not manifest_path.exists():
        raise SystemExit(
            "dataset/manifest.json not found. "
            "Run scripts/build_manifest.py first."
        )

    manifest = json.loads(
        manifest_path.read_text()
    )

    splits = json.loads(
        splits_path.read_text()
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
    print(f"Split file: {splits_path.name}")

    for split in ["train", "dev", "test"]:
        families = splits.get(split, [])

        categories = Counter(
            family_to_category[f]
            for f in families
            if f in family_to_category
        )

        print()
        print(
            f"{split.upper()}: "
            f"{len(families)} families"
        )

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
