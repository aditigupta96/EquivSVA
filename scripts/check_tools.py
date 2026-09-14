#!/usr/bin/env python3
import shutil
import subprocess
import sys

TOOLS = ["yosys", "sby"]
OPTIONAL_SOLVERS = ["bitwuzla", "yices-smt2", "z3"]

missing = [tool for tool in TOOLS if shutil.which(tool) is None]
if missing:
    print("Missing required tools:", ", ".join(missing))
    print("Install the YosysHQ OSS CAD Suite and source its environment first.")
    sys.exit(1)

print("Required tools:")
for tool in TOOLS:
    path = shutil.which(tool)
    print(f"  {tool}: {path}")
    try:
        out = subprocess.run([tool, "--version"], capture_output=True, text=True, timeout=10)
        first = (out.stdout or out.stderr).strip().splitlines()
        if first:
            print(f"    {first[0]}")
    except Exception:
        pass

solvers = [s for s in OPTIONAL_SOLVERS if shutil.which(s)]
if not solvers:
    print("No supported SMT solver found (expected bitwuzla, yices-smt2, or z3).")
    sys.exit(1)
print("Solver(s):", ", ".join(solvers))
print("Tool check PASS")
