#!/usr/bin/env python3

import json
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATASET = ROOT / "dataset"
BUILD_VALIDATION = ROOT / "build" / "validation"

DEFAULT_RTL_VARIANTS = [
    "canonical_case.sv",
    "onehot_case.sv",
    "nested_if.sv",
    "factored_flags.sv",
]


def expected_rtl_variants(spec):
    raw = spec.get("rtl_variants")

    if not raw:
        return list(DEFAULT_RTL_VARIANTS)

    result = []

    for variant in raw:
        if isinstance(variant, str):
            filename = (
                variant
                if variant.endswith(".sv")
                else f"{variant}.sv"
            )
        elif isinstance(variant, dict):
            filename = variant.get("file")

            if not filename:
                raise ValueError(
                    f"{spec['design_id']}: RTL variant "
                    "dictionary is missing 'file'"
                )
        else:
            raise ValueError(
                f"{spec['design_id']}: unsupported "
                "rtl_variants entry"
            )

        result.append(filename)

    return result


def validation_status(design_id):
    path = BUILD_VALIDATION / f"{design_id}.json"

    if not path.exists():
        return {
            "status": "missing",
            "report": str(path.relative_to(ROOT)),
        }

    try:
        data = json.loads(path.read_text())
    except Exception:
        return {
            "status": "unreadable",
            "report": str(path.relative_to(ROOT)),
        }

    # validate_family.py may store either:
    #   1. a top-level list of job results, or
    #   2. a dictionary containing job results/status fields.
    if isinstance(data, list):
        jobs = data

    elif isinstance(data, dict):
        if data.get("all_passed") is True:
            return {
                "status": "passed",
                "report": str(path.relative_to(ROOT)),
            }

        if data.get("all_passed") is False:
            return {
                "status": "failed",
                "report": str(path.relative_to(ROOT)),
            }

        if data.get("passed") is True:
            return {
                "status": "passed",
                "report": str(path.relative_to(ROOT)),
            }

        if data.get("passed") is False:
            return {
                "status": "failed",
                "report": str(path.relative_to(ROOT)),
            }

        if data.get("success") is True:
            return {
                "status": "passed",
                "report": str(path.relative_to(ROOT)),
            }

        if data.get("success") is False:
            return {
                "status": "failed",
                "report": str(path.relative_to(ROOT)),
            }

        jobs = data.get(
            "jobs",
            data.get("results", [])
        )

        if isinstance(jobs, dict):
            jobs = list(jobs.values())

    else:
        return {
            "status": "unknown",
            "report": str(path.relative_to(ROOT)),
        }

    statuses = []

    if isinstance(jobs, list):
        for job in jobs:
            if not isinstance(job, dict):
                continue

            if "passed" in job:
                statuses.append(bool(job["passed"]))

            elif "success" in job:
                statuses.append(bool(job["success"]))

            elif "ok" in job:
                statuses.append(bool(job["ok"]))

            elif "returncode" in job:
                statuses.append(
                    job["returncode"] == 0
                )

            elif "status" in job:
                statuses.append(
                    str(job["status"]).lower()
                    in {
                        "pass",
                        "passed",
                        "success",
                        "ok",
                    }
                )

    if statuses:
        status = (
            "passed"
            if all(statuses)
            else "failed"
        )
    else:
        status = "unknown"

    return {
        "status": status,
        "report": str(path.relative_to(ROOT)),
    }


def main():
    specs = sorted(DATASET.glob("*/spec.json"))

    if not specs:
        raise SystemExit("No dataset/*/spec.json files found.")

    families = []
    category_counts = Counter()
    category_properties = Counter()
    category_mutants = Counter()
    category_rtl = Counter()

    total_properties = 0
    total_mutants = 0
    total_rtl = 0
    total_expected_formal_jobs = 0

    problems = []

    for spec_path in specs:
        spec = json.loads(spec_path.read_text())

        design_id = spec["design_id"]
        category = spec["category"]
        family_dir = spec_path.parent

        properties = spec.get("properties", [])
        mutants = spec.get("mutants", [])

        rtl_dir = family_dir / "rtl"
        mutant_dir = family_dir / "mutants"

        expected_rtl = expected_rtl_variants(spec)

        present_rtl = [
            name
            for name in expected_rtl
            if (rtl_dir / name).exists()
        ]

        missing_rtl = [
            name
            for name in expected_rtl
            if name not in present_rtl
        ]

        present_mutants = sorted(
            p.name
            for p in mutant_dir.glob("*.sv")
        ) if mutant_dir.exists() else []

        if missing_rtl:
            problems.append(
                f"{design_id}: missing RTL {missing_rtl}"
            )

        if len(present_mutants) != len(mutants):
            problems.append(
                f"{design_id}: spec has {len(mutants)} mutants "
                f"but {len(present_mutants)} mutant RTL files exist"
            )

        # Current formal pipeline:
        # 3 equivalence jobs
        # 4 property proof jobs
        # 4 property cover jobs
        # 2 jobs per mutant:
        #   observable difference + property detection
        expected_formal_jobs = (
            3
            + 4
            + 4
            + (2 * len(mutants))
        )

        validation = validation_status(design_id)

        family = {
            "design_id": design_id,
            "category": category,
            "model_type": spec.get("model_type", "fsm"),
            "template": spec.get("template"),
            "description": spec.get("description"),
            "inputs": spec.get("inputs", []),
            "outputs": spec.get("outputs", []),
            "states": spec.get("states", []),
            "rtl_variants": present_rtl,
            "rtl_variant_count": len(present_rtl),
            "property_count": len(properties),
            "mutant_count": len(mutants),
            "expected_formal_jobs": expected_formal_jobs,
            "validation": validation,
        }

        families.append(family)

        category_counts[category] += 1
        category_properties[category] += len(properties)
        category_mutants[category] += len(mutants)
        category_rtl[category] += len(present_rtl)

        total_properties += len(properties)
        total_mutants += len(mutants)
        total_rtl += len(present_rtl)
        total_expected_formal_jobs += expected_formal_jobs

    categories = {}

    for category in sorted(category_counts):
        categories[category] = {
            "families": category_counts[category],
            "rtl_variants": category_rtl[category],
            "properties": category_properties[category],
            "mutants": category_mutants[category],
        }

    manifest = {
        "benchmark": "EquivSVA",
        "schema_version": "1.0",
        "summary": {
            "categories": len(category_counts),
            "families": len(families),
            "rtl_variants": total_rtl,
            "properties": total_properties,
            "mutants": total_mutants,
            "expected_formal_jobs": total_expected_formal_jobs,
        },
        "categories": categories,
        "families": families,
    }

    manifest_path = DATASET / "manifest.json"
    manifest_path.write_text(
        json.dumps(
            manifest,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    BUILD_VALIDATION.mkdir(
        parents=True,
        exist_ok=True,
    )

    validation_snapshot = {
        "benchmark": "EquivSVA",
        "families": {
            family["design_id"]: family["validation"]
            for family in families
        },
    }

    validation_path = (
        BUILD_VALIDATION
        / "dataset_inventory.json"
    )

    validation_path.write_text(
        json.dumps(
            validation_snapshot,
            indent=2,
            sort_keys=True,
        )
        + "\n"
    )

    print("EquivSVA Dataset Inventory")
    print("==========================")
    print(f"Categories:           {len(category_counts)}")
    print(f"Families:             {len(families)}")
    print(f"RTL implementations:  {total_rtl}")
    print(f"Gold properties:      {total_properties}")
    print(f"Controlled mutants:   {total_mutants}")
    print(
        f"Expected formal jobs: "
        f"{total_expected_formal_jobs}"
    )

    print()
    print("By category:")

    for category in sorted(categories):
        stats = categories[category]

        print(
            f"  {category}: "
            f"{stats['families']} families, "
            f"{stats['rtl_variants']} RTL, "
            f"{stats['properties']} properties, "
            f"{stats['mutants']} mutants"
        )

    print()
    print("Validation reports:")

    status_counts = Counter(
        family["validation"]["status"]
        for family in families
    )

    for status in sorted(status_counts):
        print(
            f"  {status}: "
            f"{status_counts[status]}"
        )

    print()
    print(
        "Manifest: "
        f"{manifest_path.relative_to(ROOT)}"
    )

    if problems:
        print()
        print("INVENTORY PROBLEMS:")
        for problem in problems:
            print(f"  - {problem}")

        raise SystemExit(1)

    print()
    print("DATASET INVENTORY PASS")


if __name__ == "__main__":
    main()
