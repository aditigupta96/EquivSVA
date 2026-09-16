#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def normalize(text):
    text = text.strip()

    had_markdown = bool(
        re.search(r"```", text)
    )

    had_transport = (
        "<|im_end|>" in text
    )

    text = re.sub(
        r"^\s*```(?:systemverilog|sv|verilog)?\s*\n?",
        "",
        text,
        flags=re.IGNORECASE,
    )

    text = re.sub(
        r"\n?\s*```\s*(?:<\|im_end\|>)?\s*$",
        "",
        text,
        flags=re.IGNORECASE,
    )

    text = text.replace(
        "<|im_end|>",
        "",
    ).strip()

    return (
        text + "\n",
        not had_markdown
        and not had_transport,
    )


def combine(rtl, sva):
    pos = rtl.rfind("endmodule")

    if pos < 0:
        raise ValueError(
            "RTL has no endmodule"
        )

    return (
        rtl[:pos]
        + "\n\n"
        + sva
        + "\n"
        + rtl[pos:]
    )


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--results",
        required=True,
    )

    args = parser.parse_args()

    source = Path(args.results)

    output = source.with_name(
        source.stem + "_syntax_scores.jsonl"
    )

    rows = [
        json.loads(line)
        for line in source.read_text().splitlines()
        if line.strip()
    ]

    scored = []

    for row in rows:
        cleaned, format_compliant = normalize(
            row["response"]
        )

        rtl_path = (
            ROOT
            / "dataset"
            / row["design_id"]
            / "rtl"
            / row["rtl_file"]
        )

        rtl = rtl_path.read_text()

        combined = combine(
            rtl,
            cleaned,
        )

        with tempfile.NamedTemporaryFile(
            mode="w",
            suffix=".sv",
            delete=False,
        ) as f:
            f.write(combined)
            temp_path = Path(f.name)

        proc = subprocess.run(
            ["slang", str(temp_path)],
            capture_output=True,
            text=True,
        )

        temp_path.unlink(
            missing_ok=True
        )

        score = {
            "task_id": row["task_id"],
            "design_id": row["design_id"],
            "rtl_variant": row["rtl_variant"],
            "format_compliant": (
                format_compliant
            ),
            "syntax_valid": (
                proc.returncode == 0
            ),
            "slang_exit_code": (
                proc.returncode
            ),
            "slang_output": (
                proc.stdout
                + proc.stderr
            ).strip(),
            "normalized_response": (
                cleaned
            ),
        }

        scored.append(score)

        print(
            row["task_id"],
            "format=",
            format_compliant,
            "syntax=",
            proc.returncode == 0,
        )

    with output.open("w") as f:
        for row in scored:
            f.write(
                json.dumps(row)
                + "\n"
            )

    print()
    print("Scores:", output)


if __name__ == "__main__":
    main()
