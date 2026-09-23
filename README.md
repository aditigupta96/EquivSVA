# EquivSVA

**EquivSVA** is a formally verified dataset of behavioral SystemVerilog Assertions (SVA) across equivalent RTL implementations.

The dataset is organized around **behavior families**. Each family contains multiple structurally distinct RTL implementations that realize the same externally observable behavior, together with shared gold behavioral properties, controlled mutants, and formal-validation evidence.

EquivSVA is intended to support research on assertion generation, formal verification, and robustness of generated assertions across different implementations of the same behavior.

**Paper:** [EquivSVA: A Formally Verified Dataset of Behavioral Assertions Across Equivalent RTL Implementations](https://arxiv.org/abs/2609.26751) (arXiv:2609.26751).

**Hugging Face dataset:** [aditigupta/EquivSVA](https://huggingface.co/datasets/aditigupta/EquivSVA).

## Dataset

EquivSVA v2.0 contains:

- **120 behavior families**
- **12 behavioral categories**
- **480 reference RTL implementations**
- **914 gold behavioral properties**
- **360 controlled mutants**
- **4 formally equivalent RTL implementations per family**
- **3 controlled mutants per family**
- **5–13 gold properties per family** (7.62 average)

The 12 categories are:

- arbiter
- counter
- FIFO control
- handshake
- interrupt control
- mode controller
- protocol controller
- pulse/event
- rate limiter
- saturating arithmetic
- sequence detector
- timer/watchdog

The dataset contains:

- 80 FSM-based families
- 27 register-rule families
- 13 multi-register-rule families

Gold properties include:

- 131 invariants
- 783 next-cycle implications

## Behavior-Family Structure

The basic unit of EquivSVA is a behavior family:

```text
Behavior specification
    |
    +-- RTL implementation 1
    +-- RTL implementation 2
    +-- RTL implementation 3
    +-- RTL implementation 4
    |
    +-- Shared gold behavioral properties
    |
    +-- Controlled mutant 1
    +-- Controlled mutant 2
    +-- Controlled mutant 3
    |
    +-- Formal-validation evidence
```

The four reference RTL implementations within a family are structurally different but are formally checked to produce the same externally observable behavior.

Gold properties are written over module-interface signals rather than implementation-specific internal state.

## Formal Validation

Every final behavior family passes a fixed **17-job formal-validation suite**:

| Validation check | Jobs per family | Total |
|---|---:|---:|
| RTL equivalence | 3 | 360 |
| Gold-property proofs | 4 | 480 |
| Property reachability / cover | 4 | 480 |
| Mutant distinguishability | 3 | 360 |
| Gold-property checks on mutants | 3 | 360 |
| **Total** | **17** | **2,040** |

Every final family passed its complete 17-job validation suite.

Formal validation uses open-source tooling from the YosysHQ OSS CAD Suite, including Yosys, SymbiYosys, and SMT/formal backends.

## Dataset Splits

The fixed v2.0 split is stored in:

```text
dataset/splits_v2.0.json
```

The split is family-safe and category-stratified:

| Split | Families | RTLs | Gold properties | Mutants |
|---|---:|---:|---:|---:|
| Train | 72 | 288 | 544 | 216 |
| Dev | 24 | 96 | 178 | 72 |
| Test | 24 | 96 | 192 | 72 |

Each category contributes exactly:

- 6 families to train
- 2 families to dev
- 2 families to test

No behavior family appears in more than one split.

## Repository Structure

```text
dataset/
    <family>/
        spec.json
        rtl/
        properties/
        mutants/
    manifest.json
    splits_v2.0.json

generator/
    Dataset generators

formal/
    Formal-verification infrastructure

scripts/
    Dataset construction, validation, audit, and manifest tools

experiments/
    Task export, model inference, and evaluation scripts

experiments/results_v2/
    Results associated with the EquivSVA v2.0 case study
```

## Dataset Audit

The final dataset diversity audit reports:

- 120 behavior families
- 12 categories
- 10 families per category
- no exact normalized behavioral clones
- 914 gold properties
- 5–13 properties per family

Run the audit with:

```bash
python scripts/audit_v2_diversity.py
```

## Manifest and Split Validation

Regenerate the dataset manifest with:

```bash
python scripts/build_manifest.py
```

Validate the fixed v2.0 split with:

```bash
python scripts/validate_splits.py
```

## Experimental Tasks

Model-evaluation tasks are generated from the fixed v2.0 split using:

```bash
python experiments/export_tasks.py
```

This produces:

- 288 train RTL tasks
- 96 dev RTL tasks
- 96 test RTL tasks

Each behavior family contributes four RTL tasks, one for each equivalent implementation.

## Qwen2.5-Coder-7B Case Study

As a small demonstration of how EquivSVA can be used, we evaluated **Qwen2.5-Coder-7B-Instruct** on the held-out test split.

The test set contains 24 behavior families and 96 RTL implementations.

| Metric | Result |
|---|---:|
| Syntactically valid outputs | 68/96 (70.8%) |
| Formally sound interface-only properties | 93/293 (31.7%) |
| Tasks with at least one sound property | 45/96 (46.9%) |
| Families with sound properties on all four equivalent RTLs | 8/24 (33.3%) |
| Families where the number of sound properties varies across equivalent RTLs | 14/24 (58.3%) |
| Detected property-mutant pairs | 16/279 (5.7%) |
| Unique controlled mutants detected | 11/72 (15.3%) |

The case study is intended to demonstrate analyses enabled by the dataset rather than provide a comprehensive comparison of assertion-generation models.

The associated outputs and evaluation results are under:

```text
experiments/results_v2/
```

## Legacy Experimental Results

The directory:

```text
experiments/results/
```

contains earlier prototype and pre-v2 experimental artifacts retained for provenance.

Results associated with the final EquivSVA v2.0 dataset and paper should use:

```text
experiments/results_v2/
```

## Installation

The recommended formal environment is the YosysHQ OSS CAD Suite.

Verify that the required tools are available:

```bash
yosys --version
sby --version
bitwuzla --version
```

Python dependencies for model experiments are separate from the formal-tool environment.

## Citation

If you use EquivSVA in your research, please cite the [paper](https://arxiv.org/abs/2609.26751):

```bibtex
@misc{aditi2026equivsva,
  title         = {EquivSVA: A Formally Verified Dataset of Behavioral Assertions Across Equivalent RTL Implementations},
  author        = {Aditi, FNU},
  year          = {2026},
  eprint        = {2609.26751},
  archivePrefix = {arXiv},
  primaryClass  = {cs.LG},
  url           = {https://arxiv.org/abs/2609.26751}
}
```

## License

EquivSVA uses separate licenses for code and dataset artifacts:

- Source code and scripts are released under the **Apache License 2.0**. See `LICENSE`.
- The EquivSVA dataset is released under the **Creative Commons Attribution 4.0 International (CC BY 4.0)** license. See `LICENSE-DATASET`.
