#!/usr/bin/env python3

import argparse
import hashlib
import json
import platform
import sys
import time
from pathlib import Path

import torch
import transformers
from transformers import AutoModelForCausalLM, AutoTokenizer


ROOT = Path(__file__).resolve().parents[1]


def sha256(text):
    return hashlib.sha256(text.encode()).hexdigest()


def choose_device(requested):
    if requested != "auto":
        return requested

    if torch.cuda.is_available():
        return "cuda"

    if (
        hasattr(torch.backends, "mps")
        and torch.backends.mps.is_available()
    ):
        return "mps"

    return "cpu"


def load_tasks(path):
    rows = []

    with path.open() as f:
        for line in f:
            line = line.strip()

            if line:
                rows.append(json.loads(line))

    return rows


def existing_ids(path):
    if not path.exists():
        return set()

    ids = set()

    with path.open() as f:
        for line in f:
            line = line.strip()

            if not line:
                continue

            try:
                row = json.loads(line)
                ids.add(row["task_id"])
            except Exception:
                pass

    return ids


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--model",
        required=True,
    )

    parser.add_argument(
        "--split",
        choices=["train", "dev", "test"],
        default="dev",
    )

    parser.add_argument(
        "--device",
        default="auto",
    )

    parser.add_argument(
        "--limit",
        type=int,
        default=None,
    )

    parser.add_argument(
        "--max-new-tokens",
        type=int,
        default=1024,
    )

    parser.add_argument(
        "--trust-remote-code",
        action="store_true",
    )

    parser.add_argument(
        "--output-name",
        default=None,
    )

    args = parser.parse_args()

    task_path = (
        ROOT
        / "experiments"
        / "tasks"
        / f"{args.split}.jsonl"
    )

    tasks = load_tasks(task_path)

    if args.limit is not None:
        tasks = tasks[:args.limit]

    device = choose_device(args.device)

    safe_model = (
        args.output_name
        or args.model.replace("/", "__")
    )

    output_dir = (
        ROOT
        / "experiments"
        / "results"
        / safe_model
    )

    output_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    output_path = (
        output_dir
        / f"{args.split}.jsonl"
    )

    completed = existing_ids(output_path)

    print("Model:", args.model)
    print("Split:", args.split)
    print("Tasks requested:", len(tasks))
    print("Already completed:", len(completed))
    print("Device:", device)
    print("Output:", output_path)
    print()

    print("Loading tokenizer...")

    tokenizer = AutoTokenizer.from_pretrained(
        args.model,
        trust_remote_code=args.trust_remote_code,
    )

    print("Loading model...")

    if device in {"cuda", "mps"}:
        dtype = torch.float16
    else:
        dtype = torch.float32

    model = AutoModelForCausalLM.from_pretrained(
        args.model,
        torch_dtype=dtype,
        trust_remote_code=args.trust_remote_code,
        low_cpu_mem_usage=True,
    )

    model.to(device)
    model.eval()

    revision = getattr(
        model.config,
        "_commit_hash",
        None,
    )

    print("Resolved revision:", revision)
    print()

    generated_count = 0

    with output_path.open("a") as out:
        for index, task in enumerate(
            tasks,
            start=1,
        ):
            task_id = task["task_id"]

            if task_id in completed:
                print(
                    f"[{index}/{len(tasks)}] "
                    f"SKIP {task_id}"
                )
                continue

            prompt = task["prompt"]

            messages = [
                {
                    "role": "user",
                    "content": prompt,
                }
            ]

            formatted = (
                tokenizer.apply_chat_template(
                    messages,
                    tokenize=False,
                    add_generation_prompt=True,
                )
            )

            inputs = tokenizer(
                formatted,
                return_tensors="pt",
                add_special_tokens=False,
            )

            inputs = {
                k: v.to(device)
                for k, v in inputs.items()
            }

            input_tokens = (
                inputs["input_ids"].shape[-1]
            )

            print(
                f"[{index}/{len(tasks)}] "
                f"RUN {task_id} "
                f"({input_tokens} input tokens)"
            )

            start = time.time()

            with torch.inference_mode():
                generated = model.generate(
                    **inputs,
                    max_new_tokens=args.max_new_tokens,
                    do_sample=False,
                    num_beams=1,
                    repetition_penalty=1.0,
                    use_cache=True,
                )

            elapsed = time.time() - start

            generated_tokens = generated[
                0,
                input_tokens:,
            ]

            response = tokenizer.decode(
                generated_tokens,
                skip_special_tokens=True,
            ).strip()

            row = {
                "task_id": task_id,
                "design_id": task["design_id"],
                "category": task["category"],
                "model_type": task["model_type"],
                "split": task["split"],
                "rtl_variant": task["rtl_variant"],
                "rtl_file": task["rtl_file"],

                "model": args.model,
                "model_revision": revision,

                "decoding": {
                    "method": "greedy",
                    "do_sample": False,
                    "num_beams": 1,
                    "repetition_penalty": 1.0,
                    "max_new_tokens": (
                        args.max_new_tokens
                    ),
                },

                "prompt_sha256": sha256(prompt),

                "input_tokens": input_tokens,
                "output_tokens": int(
                    generated_tokens.shape[-1]
                ),

                "elapsed_seconds": round(
                    elapsed,
                    3,
                ),

                "response": response,

                "environment": {
                    "python": sys.version.split()[0],
                    "platform": platform.platform(),
                    "torch": torch.__version__,
                    "transformers": (
                        transformers.__version__
                    ),
                    "device": device,
                },
            }

            out.write(
                json.dumps(row) + "\n"
            )
            out.flush()

            generated_count += 1

            print(
                f"    output tokens: "
                f"{row['output_tokens']}"
            )
            print(
                f"    seconds: "
                f"{row['elapsed_seconds']}"
            )

    print()
    print(
        f"Completed new tasks: "
        f"{generated_count}"
    )
    print("RESULT:", output_path)


if __name__ == "__main__":
    main()
