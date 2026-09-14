#!/usr/bin/env python3

import argparse
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

parser = argparse.ArgumentParser(
    description="Generate formal jobs for one EquivSVA family."
)
parser.add_argument(
    "family",
    help="Family directory, e.g. dataset/handshake_0001"
)
args = parser.parse_args()

DATA = Path(args.family).resolve()
SPEC_PATH = DATA / "spec.json"

if not SPEC_PATH.exists():
    raise SystemExit(f"Missing spec: {SPEC_PATH}")

spec = json.loads(SPEC_PATH.read_text())

design_id = spec["design_id"]
module_prefix = design_id

clock = spec["clock"]["name"]
reset = spec["reset"]["name"]
inputs = spec["inputs"]
outputs = spec["outputs"]

if not outputs:
    raise SystemExit("A family must have at least one observable output.")

BUILD = ROOT / "build" / "sby" / design_id
GENERATED = ROOT / "build" / "generated" / design_id

if BUILD.exists():
    shutil.rmtree(BUILD)

BUILD.mkdir(parents=True, exist_ok=True)
GENERATED.mkdir(parents=True, exist_ok=True)

variants = {
    "canonical": (
        f"{module_prefix}_canonical_case",
        DATA / "rtl" / "canonical_case.sv"
    ),
    "onehot": (
        f"{module_prefix}_onehot_case",
        DATA / "rtl" / "onehot_case.sv"
    ),
    "nested_if": (
        f"{module_prefix}_nested_if",
        DATA / "rtl" / "nested_if.sv"
    ),
    "factored": (
        f"{module_prefix}_factored_flags",
        DATA / "rtl" / "factored_flags.sv"
    ),
}

mutants = {
    mutant["name"]: (
        f"{module_prefix}_mutant_{mutant['name']}",
        DATA / "mutants" / f"{mutant['name']}.sv"
    )
    for mutant in spec.get("mutants", [])
}

SOLVER = "bitwuzla"


def rel(path: Path) -> str:
    return str(path.resolve())


def write(name: str, text: str):
    path = BUILD / f"{name}.sby"
    path.write_text(text)
    print(path)


def render_interface_harness(mode: str) -> str:
    if mode not in {"equiv", "difference"}:
        raise ValueError(mode)

    top = (
        "equiv_harness"
        if mode == "equiv"
        else "difference_harness"
    )

    lines = [
        "`ifndef GOLD_MODULE",
        "`define GOLD_MODULE missing_gold_module",
        "`endif",
        "",
        "`ifndef GATE_MODULE",
        "`define GATE_MODULE missing_gate_module",
        "`endif",
        "",
        f"module {top};",
        "",
        "    (* gclk *) reg formal_clock;",
        f"    reg {clock} = 1'b0;",
        "",
        "    always @(posedge formal_clock)",
        f"        {clock} <= !{clock};",
        "",
        f"    (* anyseq *) reg {reset};",
    ]

    for signal in inputs:
        lines.append(f"    (* anyseq *) reg {signal};")

    lines.append("")

    for signal in outputs:
        lines.append(f"    wire gold_{signal};")
        lines.append(f"    wire gate_{signal};")

    interface_inputs = [clock, reset] + inputs

    gold_ports = [
        f".{signal}({signal})"
        for signal in interface_inputs
    ] + [
        f".{signal}(gold_{signal})"
        for signal in outputs
    ]

    gate_ports = [
        f".{signal}({signal})"
        for signal in interface_inputs
    ] + [
        f".{signal}(gate_{signal})"
        for signal in outputs
    ]

    lines.extend([
        "",
        "    `GOLD_MODULE gold (",
        "        " + ", ".join(gold_ports),
        "    );",
        "",
        "    `GATE_MODULE gate (",
        "        " + ", ".join(gate_ports),
        "    );",
        "",
        "    reg f_past_valid = 1'b0;",
        "",
        f"    always @(posedge {clock}) begin",
        "        if (!f_past_valid)",
        f"            assume({reset});",
        "",
        "        if (f_past_valid) begin",
    ])

    if mode == "equiv":
        for signal in outputs:
            lines.append(
                f"            assert("
                f"gold_{signal} == gate_{signal});"
            )
    else:
        differences = " || ".join(
            f"(gold_{signal} != gate_{signal})"
            for signal in outputs
        )
        lines.append(
            f"            cover({differences});"
        )

    lines.extend([
        "        end",
        "",
        "        f_past_valid <= 1'b1;",
        "    end",
        "",
        "endmodule",
        "",
    ])

    return "\n".join(lines)


equiv_harness = GENERATED / "equiv_harness.sv"
difference_harness = GENERATED / "difference_harness.sv"

equiv_harness.write_text(
    render_interface_harness("equiv")
)

difference_harness.write_text(
    render_interface_harness("difference")
)


def property_cfg(
    module,
    rtl,
    mode="prove",
    expect="pass",
    depth=24,
):
    harness = GENERATED / "property_harness.sv"

    return f"""[options]
mode {mode}
depth {depth}
expect {expect}
multiclock on

[engines]
smtbmc {SOLVER}

[script]
read -formal -sv -DDUT_MODULE={module} {rtl.name} {harness.name}
prep -top property_harness

[files]
{rel(rtl)}
{rel(harness)}
"""


def equiv_cfg(
    gold_mod,
    gold_rtl,
    gate_mod,
    gate_rtl,
    difference=False,
):
    harness = (
        difference_harness
        if difference
        else equiv_harness
    )

    top = (
        "difference_harness"
        if difference
        else "equiv_harness"
    )

    mode = "cover" if difference else "prove"
    depth = 24 if difference else 30

    return f"""[options]
mode {mode}
depth {depth}
expect pass
multiclock on

[engines]
smtbmc {SOLVER}

[script]
read -formal -sv -DGOLD_MODULE={gold_mod} -DGATE_MODULE={gate_mod} {gold_rtl.name} {gate_rtl.name} {harness.name}
prep -top {top}

[files]
{rel(gold_rtl)}
{rel(gate_rtl)}
{rel(harness)}
"""


# Verify required RTL files exist.
for _, rtl in variants.values():
    if not rtl.exists():
        raise SystemExit(f"Missing generated RTL: {rtl}")

for _, rtl in mutants.values():
    if not rtl.exists():
        raise SystemExit(f"Missing generated mutant: {rtl}")


# Property proofs and non-vacuity checks.
for name, (module, rtl) in variants.items():

    write(
        f"prop_prove_{name}",
        property_cfg(
            module,
            rtl,
            mode="prove",
            expect="pass",
            depth=30,
        )
    )

    write(
        f"prop_cover_{name}",
        property_cfg(
            module,
            rtl,
            mode="cover",
            expect="pass",
            depth=24,
        )
    )


# Equivalence against canonical implementation.
gold_mod, gold_rtl = variants["canonical"]

for name, (module, rtl) in variants.items():

    if name == "canonical":
        continue

    write(
        f"equiv_{name}",
        equiv_cfg(
            gold_mod,
            gold_rtl,
            module,
            rtl,
            difference=False,
        )
    )


# Controlled mutants:
# 1. Must differ observably from canonical.
# 2. Must violate at least one gold property.
for name, (module, rtl) in mutants.items():

    write(
        f"mutant_diff_{name}",
        equiv_cfg(
            gold_mod,
            gold_rtl,
            module,
            rtl,
            difference=True,
        )
    )

    write(
        f"mutant_prop_{name}",
        property_cfg(
            module,
            rtl,
            mode="bmc",
            expect="fail",
            depth=24,
        )
    )

print(
    f"\nGenerated formal jobs for {design_id}: "
    f"{len(list(BUILD.glob('*.sby')))} jobs"
)
