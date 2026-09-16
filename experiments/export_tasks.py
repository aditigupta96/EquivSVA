#!/usr/bin/env python3

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATASET = ROOT / "dataset"
SPLIT_FILE = DATASET / "splits_v2.0.json"
OUT = ROOT / "experiments" / "tasks"


PROMPT = """You are given synthesizable SystemVerilog RTL.

Generate a concise set of SystemVerilog Assertions (SVA) that specify the externally observable functional behavior of the module.

Requirements:
- Use only module interface signals.
- Do not reference internal state, internal registers, or implementation-specific names.
- Capture important safety and temporal behavior.
- Describe functional behavior rather than coding style.
- Use the provided clock and reset semantics.
- Do not assume behavior that is not implied by the RTL.
- Return only standard SystemVerilog property and assert property declarations.
- Each property declaration must contain exactly one clocking event.
- Instantiate each property using legal concurrent assertion syntax such as:
  a_example: assert property (p_example);
- Never use pseudocode syntax such as "assert NAME of PROPERTY".
- Do not include markdown, code fences, explanations, or prose.

Clock: {clock}
Reset: {reset}

RTL:
{rtl}
"""


def get_split_lists(data):
    if all(k in data for k in ("train", "dev", "test")):
        return {
            "train": data["train"],
            "dev": data["dev"],
            "test": data["test"],
        }

    if "splits" in data:
        return {
            "train": data["splits"]["train"],
            "dev": data["splits"]["dev"],
            "test": data["splits"]["test"],
        }

    raise ValueError("Unrecognized split-file structure")


def describe_clock(spec):
    c = spec.get("clock", "clk")

    if isinstance(c, str):
        return c

    if isinstance(c, dict):
        name = c.get("name", "clk")
        edge = c.get("edge", "posedge")
        return f"{edge} {name}"

    return "posedge clk"


def describe_reset(spec):
    r = spec.get("reset")

    if not r:
        return "not specified"

    if isinstance(r, str):
        return r

    if isinstance(r, dict):
        name = r.get("name", "rst")
        active = r.get(
            "active",
            r.get("active_level", "high"),
        )

        sync = r.get(
            "synchronous",
            r.get("sync"),
        )

        if sync is True:
            timing = "synchronous"
        elif sync is False:
            timing = "asynchronous"
        else:
            timing = "reset"

        return f"{name}, active {active}, {timing}"

    return str(r)


def variant_files(spec, family_dir):
    result = []

    for v in spec.get("rtl_variants", []):
        if isinstance(v, str):
            filename = v if v.endswith(".sv") else f"{v}.sv"
            result.append((Path(filename).stem, filename))

        elif isinstance(v, dict):
            result.append((
                v.get("name", Path(v["file"]).stem),
                v["file"],
            ))

    # Older FSM specs rely on generator defaults and do not
    # explicitly list rtl_variants. In that case, use the
    # generated benchmark RTL files themselves.
    if not result:
        rtl_dir = family_dir / "rtl"

        files = sorted(rtl_dir.glob("*.sv"))

        result = [
            (path.stem, path.name)
            for path in files
        ]

    return result


split_data = json.loads(SPLIT_FILE.read_text())
splits = get_split_lists(split_data)

family_to_split = {}

for split, families in splits.items():
    for family in families:
        if family in family_to_split:
            raise ValueError(f"Family appears twice: {family}")

        family_to_split[family] = split


rows = {
    "train": [],
    "dev": [],
    "test": [],
}

for spec_path in sorted(DATASET.glob("*/spec.json")):
    spec = json.loads(spec_path.read_text())

    design_id = spec["design_id"]

    if design_id not in family_to_split:
        continue

    split = family_to_split[design_id]

    variants = variant_files(
        spec,
        spec_path.parent,
    )

    if len(variants) != 4:
        raise ValueError(
            f"{design_id}: expected 4 RTL variants, got {len(variants)}"
        )

    for variant_name, filename in variants:
        rtl_path = spec_path.parent / "rtl" / filename

        if not rtl_path.exists():
            raise FileNotFoundError(rtl_path)

        rtl = rtl_path.read_text()

        task = {
            "task_id": f"{design_id}__{variant_name}",
            "design_id": design_id,
            "category": spec.get("category"),
            "model_type": spec.get("model_type", "fsm"),
            "split": split,
            "rtl_variant": variant_name,
            "rtl_file": filename,
            "prompt": PROMPT.format(
                clock=describe_clock(spec),
                reset=describe_reset(spec),
                rtl=rtl,
            ),
        }

        rows[split].append(task)


OUT.mkdir(parents=True, exist_ok=True)

total = 0

for split in ("train", "dev", "test"):
    path = OUT / f"{split}.jsonl"

    with path.open("w") as f:
        for row in rows[split]:
            f.write(json.dumps(row) + "\n")

    total += len(rows[split])
    print(f"{split}: {len(rows[split])} tasks")

print(f"total: {total} tasks")

if total != 480:
    raise SystemExit(f"Expected 480 tasks, got {total}")

if len(rows["train"]) != 288:
    raise SystemExit("Expected 288 train tasks")

if len(rows["dev"]) != 96:
    raise SystemExit("Expected 96 dev tasks")

if len(rows["test"]) != 96:
    raise SystemExit("Expected 96 test tasks")

print("TASK EXPORT PASS")
