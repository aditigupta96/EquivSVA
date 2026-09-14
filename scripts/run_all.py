#!/usr/bin/env python3

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

cmd = [
    sys.executable,
    str(ROOT / "scripts" / "validate_family.py"),
    str(ROOT / "dataset" / "handshake_0001"),
]

raise SystemExit(
    subprocess.run(cmd, cwd=ROOT).returncode
)
