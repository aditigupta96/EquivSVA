#!/usr/bin/env python3

import re
import sys
from pathlib import Path


def normalize_response(text):
    text = text.strip()

    # Remove markdown code fences only.
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

    # Remove model transport token if present.
    text = text.replace("<|im_end|>", "")

    return text.strip() + "\n"


if __name__ == "__main__":
    src = Path(sys.argv[1])
    dst = Path(sys.argv[2])

    dst.write_text(
        normalize_response(src.read_text())
    )

    print(dst)
