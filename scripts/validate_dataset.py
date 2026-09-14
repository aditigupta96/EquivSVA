#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATASET = ROOT / "dataset"
SUMMARY_DIR = ROOT / "build" / "validation"

SUMMARY_DIR.mkdir(parents=True, exist_ok=True)

specs = sorted(DATASET.glob("*/spec.json"))

if not specs:
    raise SystemExit("No dataset families found.")

families = []
failed = False

print("=== EquivSVA dataset validation ===")
print(f"Found {len(specs)} families\n")

for spec_path in specs:
    family_dir = spec_path.parent
    spec = json.loads(spec_path.read_text())
    design_id = spec["design_id"]

    print("=" * 60)
    print(f"Validating {design_id}")
    print("=" * 60)

    result = subprocess.run(
        [
            sys.executable,
            str(ROOT / "scripts" / "validate_family.py"),
            str(family_dir),
        ],
        cwd=ROOT,
        text=True,
    )

    family_summary_path = SUMMARY_DIR / f"{design_id}.json"

    jobs = []

    if family_summary_path.exists():
        jobs = json.loads(
            family_summary_path.read_text()
        )

    passed_jobs = sum(
        1 for job in jobs if job.get("pass")
    )

    total_jobs = len(jobs)

    family_pass = (
        result.returncode == 0
        and total_jobs > 0
        and passed_jobs == total_jobs
    )

    families.append({
        "design_id": design_id,
        "category": spec.get("category"),
        "template": spec.get("template"),
        "pass": family_pass,
        "jobs_passed": passed_jobs,
        "jobs_total": total_jobs,
    })

    if not family_pass:
        failed = True


total_families = len(families)
passed_families = sum(
    1 for family in families
    if family["pass"]
)

total_jobs = sum(
    family["jobs_total"]
    for family in families
)

passed_jobs = sum(
    family["jobs_passed"]
    for family in families
)

dataset_summary = {
    "families_total": total_families,
    "families_passed": passed_families,
    "jobs_total": total_jobs,
    "jobs_passed": passed_jobs,
    "families": families,
}

out = SUMMARY_DIR / "dataset_summary.json"

out.write_text(
    json.dumps(dataset_summary, indent=2) + "\n"
)

print("\n")
print("=" * 60)
print("=== EquivSVA dataset summary ===")
print("=" * 60)

for family in families:
    status = "PASS" if family["pass"] else "FAIL"

    print(
        f"{status:4}  "
        f"{family['design_id']:<20} "
        f"{family['jobs_passed']}/"
        f"{family['jobs_total']} jobs"
    )

print()
print(
    f"Families: {passed_families}/"
    f"{total_families} passed"
)

print(
    f"Formal jobs: {passed_jobs}/"
    f"{total_jobs} passed"
)

print(f"Summary: {out}")

if failed:
    print("\nDATASET VALIDATION FAILED")
    sys.exit(1)

print("\nALL DATASET FAMILIES PASSED")
