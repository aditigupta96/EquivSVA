#!/usr/bin/env python3

import argparse
import hashlib
import json
import time
from pathlib import Path

from mlx_lm import load, stream_generate

ROOT = Path(__file__).resolve().parents[1]


def sha256(text):
    return hashlib.sha256(text.encode()).hexdigest()


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

    result = set()

    with path.open() as f:
        for line in f:
            line = line.strip()

            if line:
                result.add(
                    json.loads(line)["task_id"]
                )

    return result


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--model",
        default="mlx-community/Qwen2.5-Coder-7B-Instruct-4bit",
    )

    parser.add_argument(
        "--split",
        choices=["train", "dev", "test"],
        default="dev",
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

    args = parser.parse_args()

    tasks_path = (
        ROOT
        / "experiments"
        / "tasks"
        / f"{args.split}.jsonl"
    )

    tasks = load_tasks(tasks_path)

    if args.limit is not None:
        tasks = tasks[:args.limit]

    safe_model = args.model.replace("/", "__")

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

    done = existing_ids(output_path)

    print("Model:", args.model)
    print("Split:", args.split)
    print("Tasks:", len(tasks))
    print("Already completed:", len(done))
    print("Output:", output_path)
    print()

    print("Loading MLX model...")

    model, tokenizer = load(args.model)

    print("MODEL LOADED")
    print()

    with output_path.open("a") as out:
        for index, task in enumerate(
            tasks,
            start=1,
        ):
            task_id = task["task_id"]

            if task_id in done:
                print(
                    f"[{index}/{len(tasks)}] "
                    f"SKIP {task_id}"
                )
                continue

            messages = [
                {
                    "role": "user",
                    "content": task["prompt"],
                }
            ]

            formatted = tokenizer.apply_chat_template(
                messages,
                tokenize=False,
                add_generation_prompt=True,
            )

            input_tokens = len(
                tokenizer.encode(formatted)
            )

            print()
            print(
                f"[{index}/{len(tasks)}] "
                f"RUN {task_id}"
            )
            print(
                f"Input tokens: {input_tokens}"
            )
            print("Generating:")
            print("-" * 60)

            start = time.time()

            pieces = []
            output_tokens = 0

            for response in stream_generate(
                model,
                tokenizer,
                prompt=formatted,
                max_tokens=args.max_new_tokens,
            ):
                print(
                    response.text,
                    end="",
                    flush=True,
                )

                pieces.append(response.text)
                output_tokens += 1

            elapsed = time.time() - start

            print()
            print("-" * 60)

            text = "".join(pieces).strip()

            row = {
                "task_id": task_id,
                "design_id": task["design_id"],
                "category": task["category"],
                "model_type": task["model_type"],
                "split": task["split"],
                "rtl_variant": task["rtl_variant"],
                "rtl_file": task["rtl_file"],

                "model": args.model,

                "inference_backend": "mlx-lm",
                "quantization": "4-bit",

                "decoding": {
                    "method": "greedy",
                    "temperature": 0.0,
                    "max_new_tokens": (
                        args.max_new_tokens
                    ),
                },

                "prompt_sha256": sha256(
                    task["prompt"]
                ),

                "input_tokens": input_tokens,
                "output_tokens": output_tokens,

                "elapsed_seconds": round(
                    elapsed,
                    3,
                ),

                "response": text,
            }

            out.write(
                json.dumps(row) + "\n"
            )
            out.flush()

            print(
                f"Output tokens: "
                f"{output_tokens}"
            )

            print(
                f"Seconds: "
                f"{elapsed:.2f}"
            )

    print()
    print("RESULT:", output_path)


if __name__ == "__main__":
    main()
