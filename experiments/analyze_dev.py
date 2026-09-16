#!/usr/bin/env python3

import json
from collections import defaultdict
from pathlib import Path

BASE = Path(
    "experiments/results/"
    "mlx-community__Qwen2.5-Coder-7B-Instruct-4bit"
)

syntax = {
    x["task_id"]: x
    for x in (
        json.loads(line)
        for line in (BASE / "dev_syntax_scores.jsonl").read_text().splitlines()
        if line.strip()
    )
}

formal = {
    x["task_id"]: x
    for x in (
        json.loads(line)
        for line in (BASE / "dev_formal_scores.jsonl").read_text().splitlines()
        if line.strip()
    )
}

mutants = {
    x["task_id"]: x
    for x in (
        json.loads(line)
        for line in (BASE / "dev_mutant_scores.jsonl").read_text().splitlines()
        if line.strip()
    )
}

tasks = []

for task_id in syntax:
    s = syntax[task_id]
    f = formal.get(task_id, {})
    m = mutants.get(task_id, {})

    passed = f.get("properties_passed", 0)
    failed = f.get("properties_failed", 0)
    checked = passed + failed

    soundness = (
        passed / checked
        if checked
        else None
    )

    unique_detected = set()

    pair_detected = 0
    pair_checks = 0

    for prop in m.get("properties", []):
        for mutant in prop.get("mutants", []):
            if mutant["detection"] in {
                "detected",
                "not_detected",
            }:
                pair_checks += 1

            if mutant["detection"] == "detected":
                pair_detected += 1
                unique_detected.add(
                    mutant["mutant"]
                )

    row = {
        "task_id": task_id,
        "design_id": s["design_id"],
        "variant": s["rtl_variant"],
        "syntax_valid": s["syntax_valid"],
        "format_compliant": s["format_compliant"],

        "assertions": f.get(
            "properties_asserted",
            0,
        ),

        "interface_only": f.get(
            "properties_interface_only",
            0,
        ),

        "sound": passed,
        "false": failed,

        "soundness": soundness,

        "internal_violations": f.get(
            "properties_interface_violation",
            0,
        ),

        "lowering_unsupported": f.get(
            "properties_lowering_unsupported",
            0,
        ),

        "mutant_pair_checks": pair_checks,
        "mutant_pair_detected": pair_detected,

        "unique_mutants_detected": len(
            unique_detected
        ),

        "detected_mutants": sorted(
            unique_detected
        ),
    }

    tasks.append(row)


print()
print("=" * 100)
print("PER RTL VARIANT")
print("=" * 100)

for x in tasks:
    soundness = (
        f"{100*x['soundness']:.1f}%"
        if x["soundness"] is not None
        else "N/A"
    )

    print(
        f"{x['task_id']:<45}",
        f"syntax={'Y' if x['syntax_valid'] else 'N'}",
        f"sound={x['sound']}/{x['sound'] + x['false']}",
        f"({soundness})",
        f"mutants={x['unique_mutants_detected']}/3",
    )


families = defaultdict(list)

for row in tasks:
    families[row["design_id"]].append(row)


print()
print("=" * 100)
print("PER BEHAVIOR FAMILY — FOUR FORMALLY EQUIVALENT RTL VARIANTS")
print("=" * 100)

for family, rows in sorted(families.items()):
    rows = sorted(
        rows,
        key=lambda x: x["variant"],
    )

    valid = sum(
        r["syntax_valid"]
        for r in rows
    )

    total_sound = sum(
        r["sound"]
        for r in rows
    )

    total_false = sum(
        r["false"]
        for r in rows
    )

    checked = (
        total_sound
        + total_false
    )

    family_soundness = (
        total_sound / checked
        if checked
        else None
    )

    per_variant_sound = [
        r["sound"]
        for r in rows
    ]

    per_variant_mutants = [
        r["unique_mutants_detected"]
        for r in rows
    ]

    all_detected = set()

    for r in rows:
        all_detected.update(
            r["detected_mutants"]
        )

    print()
    print(family)

    print(
        "  syntax-valid variants:",
        f"{valid}/4",
    )

    print(
        "  sound assertions by variant:",
        per_variant_sound,
        "range=",
        max(per_variant_sound)
        - min(per_variant_sound),
    )

    if family_soundness is not None:
        print(
            "  pooled formal soundness:",
            f"{total_sound}/{checked}",
            f"({100*family_soundness:.1f}%)",
        )

    print(
        "  unique mutants caught by variant:",
        per_variant_mutants,
    )

    print(
        "  family mutant coverage:",
        f"{len(all_detected)}/3",
    )

    for r in rows:
        print(
            f"    {r['variant']:<20}",
            f"sound={r['sound']}",
            f"false={r['false']}",
            f"internal={r['internal_violations']}",
            f"mutants={r['unique_mutants_detected']}/3",
        )


print()
print("=" * 100)
print("OVERALL")
print("=" * 100)

all_unique_family_mutants = 0
total_family_mutants = 3 * len(families)

for family, rows in families.items():
    detected = set()

    for row in rows:
        detected.update(
            row["detected_mutants"]
        )

    all_unique_family_mutants += len(
        detected
    )

pair_checks = sum(
    x["mutant_pair_checks"]
    for x in tasks
)

pair_detected = sum(
    x["mutant_pair_detected"]
    for x in tasks
)

print(
    "Syntax-valid RTL variants:",
    f"{sum(x['syntax_valid'] for x in tasks)}/{len(tasks)}",
)

print(
    "Families with syntax failure on >=1 equivalent RTL:",
    sum(
        any(not x["syntax_valid"] for x in rows)
        for rows in families.values()
    ),
    "/",
    len(families),
)

print(
    "Unique family mutants caught:",
    f"{all_unique_family_mutants}/{total_family_mutants}",
)

if total_family_mutants:
    print(
        "Unique-mutant coverage:",
        f"{100*all_unique_family_mutants/total_family_mutants:.1f}%",
    )

print(
    "Property-mutant pair detection:",
    f"{pair_detected}/{pair_checks}",
)

if pair_checks:
    print(
        "Property-mutant pair rate:",
        f"{100*pair_detected/pair_checks:.1f}%",
    )
