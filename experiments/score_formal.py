#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
from pathlib import Path

from lower_sva import (
    extract_assertions,
    lower_property,
)

ROOT = Path(__file__).resolve().parents[1]


def module_name(rtl):
    m = re.search(
        r"\bmodule\s+([A-Za-z_][A-Za-z0-9_$]*)",
        rtl,
    )

    if not m:
        raise ValueError(
            "Could not determine module name"
        )

    return m.group(1)


def interface_names(spec, rtl):
    names = set()

    for key in ("inputs", "outputs"):
        value = spec.get(key, [])

        if isinstance(value, dict):
            names.update(value.keys())

        elif isinstance(value, list):
            for item in value:
                if isinstance(item, str):
                    names.add(item)

                elif isinstance(item, dict):
                    name = item.get("name")

                    if name:
                        names.add(name)

    for key in ("clock", "reset"):
        value = spec.get(key)

        if isinstance(value, str):
            names.add(value)

        elif isinstance(value, dict):
            name = value.get("name")

            if name:
                names.add(name)

    # Also recover ANSI-style ports from the actual RTL.
    m = re.search(
        r"\bmodule\b.*?\((.*?)\)\s*;",
        rtl,
        re.DOTALL,
    )

    if m:
        header = re.sub(
            r"//.*?$|/\*.*?\*/",
            " ",
            m.group(1),
            flags=re.MULTILINE | re.DOTALL,
        )

        for part in header.split(","):
            ids = re.findall(
                r"[A-Za-z_][A-Za-z0-9_$]*",
                part,
            )

            if ids:
                candidate = ids[-1]

                if candidate not in {
                    "input",
                    "output",
                    "inout",
                    "wire",
                    "logic",
                    "reg",
                    "signed",
                    "unsigned",
                }:
                    names.add(candidate)

    return names


def expression_identifiers(expr):
    expr = re.sub(
        r"\d+'[sS]?[bBoOdDhH][0-9a-fA-F_xXzZ?]+",
        " ",
        expr,
    )

    expr = re.sub(
        r"\$[A-Za-z_][A-Za-z0-9_$]*",
        " ",
        expr,
    )

    ids = set(
        re.findall(
            r"\b[A-Za-z_][A-Za-z0-9_$]*\b",
            expr,
        )
    )

    return ids - {
        "true",
        "false",
    }


def property_identifiers(prop):
    expressions = [
        prop.get("disable", ""),
        prop.get("antecedent", ""),
        prop.get("consequent", ""),
        prop.get("expression", ""),
    ]

    result = set()

    for expr in expressions:
        result |= expression_identifiers(expr)

    return result


def clock_and_reset(spec):
    clock = spec.get(
        "clock",
        {"name": "clk"},
    )

    clock_name = (
        clock
        if isinstance(clock, str)
        else clock.get("name", "clk")
    )

    reset = spec.get(
        "reset",
        {"name": "rst", "active": "high"},
    )

    reset_name = (
        reset
        if isinstance(reset, str)
        else reset.get("name", "rst")
    )

    active = (
        "high"
        if isinstance(reset, str)
        else str(
            reset.get("active", "high")
        ).lower()
    )

    reset_asserted = (
        f"!{reset_name}"
        if active in {
            "low",
            "0",
            "active_low",
        }
        else reset_name
    )

    return (
        clock_name,
        reset_asserted,
    )


def make_formal(rtl, prop, spec):
    clock, reset_asserted = (
        clock_and_reset(spec)
    )

    lowered = lower_property(
        prop,
        0,
    )

    monitor = f"""
reg formal_started = 1'b0;
reg f_past_valid = 1'b0;

always @(posedge {clock}) begin
    formal_started <= 1'b1;
    f_past_valid <= 1'b1;

    if (!formal_started)
        assume({reset_asserted});

{lowered}
end
"""

    pos = rtl.rfind("endmodule")

    if pos < 0:
        raise ValueError(
            "endmodule not found"
        )

    return (
        rtl[:pos]
        + "\n\n"
        + monitor
        + "\n"
        + rtl[pos:]
    )


def formal_status(
    workdir,
    returncode,
):
    run = workdir / "prove"

    if (run / "PASS").exists():
        return "pass"

    if (run / "FAIL").exists():
        return "fail"

    if (run / "UNKNOWN").exists():
        return "unknown"

    if returncode == 0:
        return "pass"

    if returncode == 2:
        return "fail"

    if returncode == 4:
        return "unknown"

    return "compile_error"


def compile_error_text(workdir):
    log = (
        workdir
        / "prove"
        / "logfile.txt"
    )

    if not log.exists():
        return "no logfile"

    lines = log.read_text(
        errors="ignore"
    ).splitlines()

    errors = [
        line.strip()
        for line in lines
        if "ERROR:" in line
    ]

    if errors:
        return errors[-1]

    return lines[-1].strip() if lines else "empty logfile"


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--results",
        required=True,
    )

    parser.add_argument(
        "--syntax-scores",
        required=True,
    )

    parser.add_argument(
        "--depth",
        type=int,
        default=30,
    )

    args = parser.parse_args()

    results_path = Path(
        args.results
    )

    syntax_path = Path(
        args.syntax_scores
    )

    results = {
        row["task_id"]: row
        for row in (
            json.loads(line)
            for line
            in results_path.read_text().splitlines()
            if line.strip()
        )
    }

    syntax_rows = [
        json.loads(line)
        for line
        in syntax_path.read_text().splitlines()
        if line.strip()
    ]

    output_path = (
        results_path.with_name(
            results_path.stem
            + "_formal_scores.jsonl"
        )
    )

    output_rows = []

    for syntax_row in syntax_rows:
        task_id = syntax_row["task_id"]
        result = results[task_id]

        print()
        print("=" * 70)
        print(task_id)

        task_score = {
            "task_id": task_id,
            "design_id": result["design_id"],
            "rtl_variant": result["rtl_variant"],
            "syntax_valid": syntax_row[
                "syntax_valid"
            ],
            "properties": [],
        }

        if not syntax_row[
            "syntax_valid"
        ]:
            task_score[
                "formal_status"
            ] = "not_run_syntax_invalid"

            output_rows.append(
                task_score
            )

            print(
                "SKIP: syntax invalid"
            )
            continue

        text = syntax_row[
            "normalized_response"
        ]

        _, assertions = (
            extract_assertions(text)
        )

        family = (
            ROOT
            / "dataset"
            / result["design_id"]
        )

        spec = json.loads(
            (
                family
                / "spec.json"
            ).read_text()
        )

        rtl_path = (
            family
            / "rtl"
            / result["rtl_file"]
        )

        rtl = rtl_path.read_text()
        top = module_name(rtl)

        interface = interface_names(
            spec,
            rtl,
        )

        for prop in assertions:
            name = prop["name"]

            print()
            print(
                "PROPERTY:",
                name,
                f"({prop.get('source_kind')})",
            )

            item = {
                "name": name,
                "source_kind": prop.get(
                    "source_kind"
                ),
                "lowering_supported": bool(
                    prop.get("supported")
                ),
            }

            if not prop.get(
                "supported"
            ):
                item[
                    "interface_only"
                ] = None

                item[
                    "formal_status"
                ] = "not_run_lowering_unsupported"

                item["reason"] = prop.get(
                    "reason",
                    "unsupported",
                )

                task_score[
                    "properties"
                ].append(item)

                print(
                    "  LOWERING UNSUPPORTED:",
                    item["reason"],
                )

                continue

            used_ids = property_identifiers(
                prop
            )

            non_interface = sorted(
                used_ids - interface
            )

            item[
                "referenced_identifiers"
            ] = sorted(used_ids)

            item[
                "non_interface_identifiers"
            ] = non_interface

            item[
                "interface_only"
            ] = not non_interface

            if non_interface:
                item[
                    "formal_status"
                ] = "not_run_interface_violation"

                task_score[
                    "properties"
                ].append(item)

                print(
                    "  INTERFACE VIOLATION:",
                    ", ".join(
                        non_interface
                    ),
                )

                continue

            safe_task = re.sub(
                r"[^A-Za-z0-9_.-]",
                "_",
                task_id,
            )

            safe_prop = re.sub(
                r"[^A-Za-z0-9_.-]",
                "_",
                name,
            )

            workdir = (
                ROOT
                / "build"
                / "llm_eval"
                / safe_task
                / safe_prop
            )

            workdir.mkdir(
                parents=True,
                exist_ok=True,
            )

            formal = make_formal(
                rtl,
                prop,
                spec,
            )

            (
                workdir
                / "formal.sv"
            ).write_text(formal)

            sby = f"""[options]
mode prove
depth {args.depth}

[engines]
smtbmc bitwuzla

[script]
read -formal -sv formal.sv
prep -top {top}

[files]
formal.sv
"""

            (
                workdir
                / "prove.sby"
            ).write_text(sby)

            proc = subprocess.run(
                [
                    "sby",
                    "-f",
                    "prove.sby",
                ],
                cwd=workdir,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )

            status = formal_status(
                workdir,
                proc.returncode,
            )

            item[
                "formal_status"
            ] = status

            item[
                "sby_returncode"
            ] = proc.returncode

            item[
                "workdir"
            ] = str(
                workdir.relative_to(
                    ROOT
                )
            )

            if status == "compile_error":
                item[
                    "compile_error"
                ] = compile_error_text(
                    workdir
                )

            task_score[
                "properties"
            ].append(item)

            print(
                " ",
                status.upper(),
            )

            if status == "compile_error":
                print(
                    "   ",
                    item[
                        "compile_error"
                    ],
                )

        props = task_score[
            "properties"
        ]

        task_score[
            "properties_asserted"
        ] = len(props)

        task_score[
            "properties_lowerable"
        ] = sum(
            p[
                "lowering_supported"
            ]
            for p in props
        )

        task_score[
            "properties_interface_only"
        ] = sum(
            p.get(
                "interface_only"
            ) is True
            for p in props
        )

        task_score[
            "properties_passed"
        ] = sum(
            p["formal_status"]
            == "pass"
            for p in props
        )

        task_score[
            "properties_failed"
        ] = sum(
            p["formal_status"]
            == "fail"
            for p in props
        )

        task_score[
            "properties_unknown"
        ] = sum(
            p["formal_status"]
            == "unknown"
            for p in props
        )

        task_score[
            "properties_compile_error"
        ] = sum(
            p["formal_status"]
            == "compile_error"
            for p in props
        )

        task_score[
            "properties_interface_violation"
        ] = sum(
            p["formal_status"]
            == "not_run_interface_violation"
            for p in props
        )

        task_score[
            "properties_lowering_unsupported"
        ] = sum(
            p["formal_status"]
            == "not_run_lowering_unsupported"
            for p in props
        )

        output_rows.append(
            task_score
        )

        print()
        print(
            "ASSERTED:",
            task_score[
                "properties_asserted"
            ],
            "INTERFACE-ONLY:",
            task_score[
                "properties_interface_only"
            ],
            "PASS:",
            task_score[
                "properties_passed"
            ],
            "FAIL:",
            task_score[
                "properties_failed"
            ],
        )

    with output_path.open(
        "w"
    ) as f:
        for row in output_rows:
            f.write(
                json.dumps(row)
                + "\n"
            )

    print()
    print("=" * 70)
    print(
        "FORMAL SCORING COMPLETE"
    )
    print(
        "Output:",
        output_path,
    )


if __name__ == "__main__":
    main()
