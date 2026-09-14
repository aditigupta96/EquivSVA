# EquivSVA prototype

This is the first end-to-end prototype for a future EquivSVA benchmark.

It contains one behavior family (`handshake_0001`):

- 1 machine-readable BehaviorSpec
- 4 independently structured RTL implementations
- 7 implementation-independent behavioral properties
- 3 intentionally buggy mutants
- open-source formal harnesses for:
  - property proof
  - non-vacuity / reachability cover
  - sequential interface equivalence
  - mutant-difference reachability

## Semantics

All validation traces start with one asserted synchronous reset cycle. After that,
inputs are unconstrained. Equivalent RTL implementations must produce identical
`busy` and `ack` outputs for every input trace.

## Install tools (recommended)

Use the YosysHQ OSS CAD Suite. It bundles Yosys, SBY and formal solvers.

1. Download the archive for your OS/architecture from:
   https://github.com/YosysHQ/oss-cad-suite-build/releases
2. Extract it.
3. On macOS, from the extracted directory run:

```bash
./activate
source ./environment
```

Or add the suite permanently to PATH by sourcing its `environment` file from
`~/.zshrc`.

Verify:

```bash
yosys --version
sby --version
bitwuzla --version
```

## Run the prototype

```bash
cd equivsva-prototype
python3 scripts/check_tools.py
python3 scripts/generate_sby.py
python3 scripts/run_all.py
```

or simply:

```bash
make validate
```

The final machine-readable result is written to:

```text
build/validation_summary.json
```

A successful run should show PASS for:

- property proof on all 4 good implementations
- reachability/non-vacuity cover on all 4 good implementations
- equivalence of each alternate implementation to the canonical implementation
- a reachable behavioral difference for each mutant
- a golden-property counterexample for each mutant

## Why the mutant property jobs say `expect fail`

For a mutant, finding an assertion failure is the desired outcome. The generated
SBY configuration therefore uses `expect fail`; SBY returns success only when it
finds the expected counterexample.

## Important

This is a research prototype, not the final benchmark. Do not publish or freeze
v1.0 until the generator, schema, formal semantics, licensing, and manual audit
procedure have been reviewed.
