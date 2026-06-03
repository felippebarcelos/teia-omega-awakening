"""
fetch_and_prep_mt_bench.py — TEIA P48.0 MT-Bench Dataset Fetcher
Downloads the official MT-Bench question set from the FastChat repository
(GitHub Raw) and converts JSONL to a JSON array for use with the benchmark
harness. Uses Python stdlib only (urllib.request). No third-party dependencies.

Source (publicly available, Apache-2.0):
  https://raw.githubusercontent.com/lm-sys/FastChat/main/
  fastchat/llm_judge/data/mt_bench/question.jsonl

Output:
  tests/mt_bench_questions.json  — JSON array, 80 questions

Idempotent: re-running overwrites the output only if the downloaded content
differs from the stored version (SHA-256 comparison). Delta always written
in full — mathematical symbol prohibited.
"""

from __future__ import annotations

import hashlib
import json
import sys
import urllib.request
from pathlib import Path

MT_BENCH_URL = (
    "https://raw.githubusercontent.com/lm-sys/FastChat/main"
    "/fastchat/llm_judge/data/mt_bench/question.jsonl"
)

OUTPUT_FILE = Path(__file__).parent / "mt_bench_questions.json"

_C = {
    "cyan": "\033[36m", "green": "\033[32m", "yellow": "\033[33m",
    "red":  "\033[31m", "white": "\033[97m", "reset": "\033[0m",
}

def _c(t: str, c: str) -> str:
    return "{}{}{}".format(_C.get(c, ""), t, _C["reset"])


def fetch(url: str = MT_BENCH_URL, output: Path = OUTPUT_FILE, force: bool = False) -> Path:
    print()
    print(_c("=" * 60, "cyan"))
    print(_c("  TEIA P48.0 — MT-Bench Dataset Fetcher", "cyan"))
    print(_c("=" * 60, "cyan"))
    print()
    print("  Source : {}".format(url))
    print("  Output : {}".format(output))
    print()

    # ── Download ──────────────────────────────────────────────────────────────
    print("  Downloading MT-Bench questions...", end=" ", flush=True)
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "teia-cognitive-router/1.2.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw_bytes = resp.read()
    except Exception as exc:
        print(_c("FAILED", "red"))
        print("  ERROR: {}".format(exc))
        sys.exit(1)

    print(_c("OK", "green"), "({} bytes)".format(len(raw_bytes)))

    # ── Parse JSONL ───────────────────────────────────────────────────────────
    questions: list[dict] = []
    for i, line in enumerate(raw_bytes.decode("utf-8").splitlines(), start=1):
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
            questions.append(obj)
        except json.JSONDecodeError as exc:
            print("  WARNING: skipping malformed line {}: {}".format(i, exc))

    if not questions:
        print(_c("  ERROR: no valid questions parsed from JSONL.", "red"))
        sys.exit(1)

    print("  Parsed  : {} questions".format(len(questions)))

    # Summarise categories
    categories: dict[str, int] = {}
    for q in questions:
        cat = q.get("category", "unknown")
        categories[cat] = categories.get(cat, 0) + 1
    for cat, count in sorted(categories.items()):
        print("    {:20s}: {}".format(cat, count))

    # ── Idempotence check ─────────────────────────────────────────────────────
    json_out = json.dumps(questions, ensure_ascii=False, indent=2, sort_keys=False)
    new_hash = hashlib.sha256(json_out.encode("utf-8")).hexdigest()

    if output.exists() and not force:
        existing_hash = hashlib.sha256(output.read_bytes()).hexdigest()
        if existing_hash == new_hash:
            print()
            print(_c("  IDEMPOTENT: output unchanged (SHA-256 match).", "green"))
            print("  SHA-256 : {}".format(_c(new_hash, "cyan")))
            print(_c("=" * 60, "cyan"))
            print()
            return output

    # ── Write ─────────────────────────────────────────────────────────────────
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json_out, encoding="utf-8")

    print()
    print(_c("  WRITTEN: mt_bench_questions.json", "green"))
    print("  SHA-256 : {}".format(_c(new_hash, "cyan")))
    print(_c("=" * 60, "cyan"))
    print()

    return output


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Fetch and prepare MT-Bench questions for TEIA benchmark"
    )
    parser.add_argument("--output", "-o", default=str(OUTPUT_FILE),
                        help="Output JSON file path")
    parser.add_argument("--force",  "-f", action="store_true",
                        help="Force re-download even if output exists")
    args = parser.parse_args()

    fetch(output=Path(args.output), force=args.force)
