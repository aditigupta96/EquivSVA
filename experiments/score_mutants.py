#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
from pathlib import Path

from lower_sva import extract_assertions
from score_formal import (
    make_formal,
    module_name,
    formal_status,
)

ROOT = Path(__file__).resolve().parents[1]


def safe(text):
    return re.sub(
        r"[^A-Za-z0-9_.-]",
        "_",
        text,
    )


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
        "--formal-scores",
        required=True,
    )

    parser.add_argument(
        "--depth",
        type=int,
        default=30,
    )

    args = parser.parse_args()

    results_path = Path(args.results)

    results = {
        x["task_id"]: x
        for x in (
            json.loads(line)
            for line in results_path.read_text().splitlines()
            if line.strip()
        )
    }

    syntax = {
        x["task_id"]: x
        for x in (
            json.loads(line)
            for line in Path(
                args.syntax_scores
            ).read_text().splitlines()
            if line.strip()
        )
    }

    formal = {
        x["task_id"]: x
        for x in (
            json.loads(line)
            for line in Path(
                args.formal_scores
            ).read_text().splitlines()
            if line.strip()
        )
    }

    output = results_path.with_name(
        results_path.stem
        + "_mutant_scores.jsonl"
    )

    output_rows = []

    for task_id, result in results.items():
        fscore = formal.get(task_id, {})

        good_names = {
            p["name"]
            for p in fscore.get(
                "properties",
                [],
            )
            if (
                p.get("formal_status") == "pass"
                and p.get("interface_only") is True
            )
        }

        task_result = {
            "task_id": task_id,
            "design_id": result["design_id"],
            "rtl_variant": result["rtl_variant"],
            "source_sound_properties": len(
                good_names
            ),
            "properties": [],
        }

        if not good_names:
            output_rows.append(task_result)

            print(
                task_id,
                "sound=0",
                "skip",
            )

            continue

        normalized = syntax[
            task_id
        ]["normalized_response"]

        _, assertions = extract_assertions(
            normalized
        )

        prop_map = {
            p["name"]: p
            for p in assertions
        }

        family = (
            ROOT
            / "dataset"
            / result["design_id"]
        )

        spec = json.loads(
            (family / "spec.json").read_text()
        )

        mutants = sorted(
            (family / "mutants").glob("*.sv")
        )

        if len(mutants) != 3:
            raise SystemExit(
                f"{result['design_id']}: "
                f"expected 3 mutants, "
                f"found {len(mutants)}"
            )

        print()
        print("=" * 70)
        print(task_id)
        print(
            "Sound properties:",
            len(good_names),
        )

        for name in sorted(good_names):
            prop = prop_map[name]

            prop_result = {
                "name": name,
                "mutants": [],
            }

            for mutant in mutants:
                rtl = mutant.read_text()
                top = module_name(rtl)

                formal_sv = make_formal(
                    rtl,
                    prop,
                    spec,
                )

                workdir = (
                    ROOT
                    / "build"
                    / "llm_mutant_eval"
                    / safe(task_id)
                    / safe(name)
                    / safe(mutant.stem)
                )

                workdir.mkdir(
                    parents=True,
                    exist_ok=True,
                )

                (
                    workdir
                    / "formal.sv"
                ).write_text(formal_sv)

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

                # FAIL means the assertion found the mutant.
                if status == "fail":
                    detection = "detected"

                elif status == "pass":
                    detection = "not_detected"

                else:
                    detection = status

                prop_result[
                    "mutants"
                ].append({
                    "mutant": mutant.stem,
                    "formal_status": status,
                    "detection": detection,
                })

                print(
                    f"  {name:<35}",
                    f"{mutant.stem:<25}",
                    detection,
                )

            detections = [
                x["detection"]
                for x in prop_result["mutants"]
            ]

            prop_result[
                "mutants_detected"
            ] = detections.count(
                "detected"
            )

            prop_result[
                "mutants_total"
            ] = len(detections)

            task_result[
                "properties"
            ].append(prop_result)

        all_checks = [
            m
            for p in task_result["properties"]
            for m in p["mutants"]
        ]

        task_result[
            "mutant_checks"
        ] = len(all_checks)

        task_result[
            "mutants_detected"
        ] = sum(
            x["detection"] == "detected"
            for x in all_checks
        )

        task_result[
            "mutants_not_detected"
        ] = sum(
            x["detection"] == "not_detected"
            for x in all_checks
        )

        output_rows.append(
            task_result
        )

    with output.open("w") as f:
        for row in output_rows:
            f.write(
                json.dumps(row)
                + "\n"
            )

    print()
    print("MUTANT SCORING COMPLETE")
    print("Output:", output)


if __name__ == "__main__":
    main()
