#!/usr/bin/env python3

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

parser = argparse.ArgumentParser(
    description="Generate and formally validate one EquivSVA family."
)
parser.add_argument(
    "family",
    help="Family directory, e.g. dataset/handshake_0001"
)
args = parser.parse_args()

FAMILY = Path(args.family).resolve()
SPEC = FAMILY / "spec.json"

if not SPEC.exists():
    raise SystemExit(f"Missing spec: {SPEC}")

spec = json.loads(SPEC.read_text())
design_id = spec["design_id"]

SBY_DIR = ROOT / "build" / "sby" / design_id
RUN_DIR = ROOT / "build" / "runs" / design_id
SUMMARY_DIR = ROOT / "build" / "validation"

SUMMARY_DIR.mkdir(parents=True, exist_ok=True)

if RUN_DIR.exists():
    shutil.rmtree(RUN_DIR)

RUN_DIR.mkdir(parents=True, exist_ok=True)


def run(cmd, cwd=ROOT):
    print("+", " ".join(map(str, cmd)))

    return subprocess.run(
        cmd,
        cwd=cwd,
        text=True,
    )


# Toolchain.
if run([
    sys.executable,
    str(ROOT / "scripts" / "check_tools.py")
]).returncode != 0:
    sys.exit(1)


# Generate RTL/properties/mutants from BehaviorSpec.
model_type = spec.get("model_type", "fsm")

if model_type == "fsm":
    generator = ROOT / "generator" / "generate_family.py"
elif model_type == "register_rules":
    generator = (
        ROOT
        / "generator"
        / "generate_register_family.py"
    )
elif model_type == "multi_register_rules":
    generator = (
        ROOT
        / "generator"
        / "generate_multi_register_family.py"
    )
else:
    raise SystemExit(
        f"Unsupported model_type: {model_type}"
    )

if run([
    sys.executable,
    str(generator),
    "--spec",
    str(SPEC),
]).returncode != 0:
    sys.exit(1)


# Generate formal jobs for this family.
if run([
    sys.executable,
    str(ROOT / "scripts" / "generate_sby.py"),
    str(FAMILY),
]).returncode != 0:
    sys.exit(1)


jobs = sorted(SBY_DIR.glob("*.sby"))

if not jobs:
    raise SystemExit(
        f"No SBY jobs generated for {design_id}"
    )

summary = []
failed = False

for cfg in jobs:

    workdir = RUN_DIR / cfg.stem

    rc = run([
        "sby",
        "-f",
        "-d",
        str(workdir),
        str(cfg),
    ]).returncode

    ok = rc == 0

    summary.append({
        "design_id": design_id,
        "job": cfg.stem,
        "pass": ok,
        "returncode": rc,
    })

    if not ok:
        failed = True


out = SUMMARY_DIR / f"{design_id}.json"

out.write_text(
    json.dumps(summary, indent=2) + "\n"
)

print(
    f"\n=== EquivSVA validation: {design_id} ==="
)

for row in summary:

    status = "PASS" if row["pass"] else "FAIL"

    print(
        f"{status:4}  {row['job']}"
    )

print(
    f"\nJobs: {len(summary)}"
)

print(
    f"Summary: {out}"
)

if failed:
    print(
        "One or more validation jobs failed."
    )
    sys.exit(1)

print(
    f"ALL VALIDATION JOBS PASSED: {design_id}"
)
