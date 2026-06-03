"""
teia_router_bench_harness.py — TEIA P44.0 Public Benchmark Harness
Processes a local benchmark dataset (MT-Bench, RouterBench, or generic JSON)
through the TEIA Cognitive Router and exports a sealed evaluation report.

Supported input formats (auto-detected):
  MT-Bench:     array of {question_id, category, turns: [...], ...}
  RouterBench:  array of {id, prompt, category, ...}
  Generic:      array of {id/question_id, prompt/turns/question, ...}

Usage:
  python teia_router_bench_harness.py --input mt_bench_subset.json
  python teia_router_bench_harness.py --input routerbench.json --output evaluation.json
  python teia_router_bench_harness.py --input data.json --category coding

No internet required. Fully offline. Write==Read invariant guaranteed.
Delta always written in full.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
import time
from collections import defaultdict
from pathlib import Path
from typing import Any

_HERE = Path(__file__).parent
sys.path.insert(0, str(_HERE))
import teia_cognitive_router as router  # noqa: E402


# ── Format detection and prompt extraction ────────────────────────────────────

def _extract_prompt(item: dict) -> str | None:
    """Extract the primary prompt text from any supported benchmark format."""
    # MT-Bench: turns is a list; first turn is the human message
    if "turns" in item and isinstance(item["turns"], list) and item["turns"]:
        return str(item["turns"][0])
    # RouterBench / generic
    for key in ("prompt", "question", "input", "text", "instruction", "user"):
        if key in item and item[key]:
            return str(item[key])
    return None


def _extract_id(item: dict, idx: int) -> str:
    for key in ("question_id", "id", "idx", "index"):
        if key in item:
            return str(item[key])
    return str(idx)


def _extract_category(item: dict) -> str:
    for key in ("category", "domain", "type", "task_type", "subject"):
        if key in item and item[key]:
            return str(item[key])
    return "unknown"


def _detect_format(data: list[dict]) -> str:
    if not data:
        return "unknown"
    sample = data[0]
    if "turns" in sample:
        return "mt_bench"
    if "prompt" in sample or "instruction" in sample:
        return "generic"
    return "generic"


# ── Core evaluation ───────────────────────────────────────────────────────────

def evaluate(
    data: list[dict],
    category_filter: str | None = None,
    max_items: int | None = None,
) -> dict[str, Any]:

    detected_format = _detect_format(data)

    rows        : list[dict]          = []
    skipped     : int                 = 0
    cat_dist    : dict[str, dict]     = defaultdict(lambda: {"Local": 0, "Hybrid": 0, "Cloud": 0, "count": 0})
    route_dist  : dict[str, int]      = {"Local": 0, "Hybrid": 0, "Cloud": 0}

    t0 = time.perf_counter()

    for idx, item in enumerate(data):
        if max_items and len(rows) >= max_items:
            break

        category = _extract_category(item)
        if category_filter and category.lower() != category_filter.lower():
            skipped += 1
            continue

        prompt = _extract_prompt(item)
        if not prompt or not prompt.strip():
            skipped += 1
            continue

        r        = router.route(prompt)
        decision = r["routing_decision"]

        route_dist[decision] += 1
        cat_dist[category][decision] += 1
        cat_dist[category]["count"]  += 1

        rows.append({
            "id":               _extract_id(item, idx),
            "category":         category,
            "prompt_chars":     r["input_char_count"],
            "token_estimate":   r["input_token_estimate"],
            "semantic_entropy": r["semantic_entropy_score"],
            "confidence":       r["routing_confidence"],
            "routing_decision": decision,
            "rationale":        r["routing_rationale"],
            "delta_usd_saved":  r["gpu_economics"]["delta_usd_saved"],
            "cloud_gpu_seconds": r["gpu_economics"]["cloud_gpu_seconds_estimate"],
        })

    elapsed_ms = round((time.perf_counter() - t0) * 1000, 2)
    n = len(rows)

    if n == 0:
        raise ValueError("No valid prompts found in dataset after filtering.")

    # ── Aggregate economics ───────────────────────────────────────────────────
    total_cloud_gpu  = sum(r["cloud_gpu_seconds"] for r in rows)
    total_delta_usd  = sum(r["delta_usd_saved"]   for r in rows)
    baseline_usd     = round(total_cloud_gpu * router.GPU_COST_PER_SECOND_USD, 6)
    routed_usd       = round(baseline_usd - total_delta_usd, 6)
    savings_pct      = round(100.0 * total_delta_usd / baseline_usd, 1) if baseline_usd > 0 else 0.0
    avg_entropy      = round(sum(r["semantic_entropy"] for r in rows) / n, 4)

    high_conf  = sum(1 for r in rows if r["confidence"] == "high")
    med_conf   = sum(1 for r in rows if r["confidence"] == "medium")
    low_conf   = sum(1 for r in rows if r["confidence"] == "low")

    scale              = 10000.0 / n
    monthly_baseline   = round(baseline_usd * scale * 30, 2)
    monthly_delta      = round(total_delta_usd * scale * 30, 2)

    by_category = {}
    for cat, d in sorted(cat_dist.items()):
        cnt = d["count"]
        by_category[cat] = {
            "count":       cnt,
            "local_count": d["Local"],
            "hybrid_count": d["Hybrid"],
            "cloud_count": d["Cloud"],
            "local_pct":   round(100.0 * d["Local"]  / cnt, 1) if cnt else 0.0,
            "hybrid_pct":  round(100.0 * d["Hybrid"] / cnt, 1) if cnt else 0.0,
            "cloud_pct":   round(100.0 * d["Cloud"]  / cnt, 1) if cnt else 0.0,
        }

    result: dict[str, Any] = {
        "harness_version":    "1.0",
        "protocol":           "P44.0",
        "input_format":       detected_format,
        "category_filter":    category_filter or "none",
        "items_evaluated":    n,
        "items_skipped":      skipped,
        "elapsed_ms":         elapsed_ms,
        "throughput_per_sec": round(n / elapsed_ms * 1000) if elapsed_ms > 0 else 0,
        "routing_distribution": {
            "local_count":  route_dist["Local"],
            "hybrid_count": route_dist["Hybrid"],
            "cloud_count":  route_dist["Cloud"],
            "local_pct":    round(100.0 * route_dist["Local"]  / n, 1),
            "hybrid_pct":   round(100.0 * route_dist["Hybrid"] / n, 1),
            "cloud_pct":    round(100.0 * route_dist["Cloud"]  / n, 1),
        },
        "confidence_distribution": {
            "high_count":   high_conf,
            "medium_count": med_conf,
            "low_count":    low_conf,
            "high_pct":     round(100.0 * high_conf / n, 1),
        },
        "entropy_stats": {
            "mean": avg_entropy,
            "min":  min(r["semantic_entropy"] for r in rows),
            "max":  max(r["semantic_entropy"] for r in rows),
        },
        "economics": {
            "baseline_cloud_gpu_seconds":     round(total_cloud_gpu, 3),
            "baseline_cloud_usd":             baseline_usd,
            "teia_routed_usd":                routed_usd,
            "delta_usd_saved":                round(total_delta_usd, 6),
            "savings_pct":                    savings_pct,
            "projected_monthly_baseline_usd": monthly_baseline,
            "projected_monthly_delta_usd":    monthly_delta,
            "gpu_cost_per_second_usd":        router.GPU_COST_PER_SECOND_USD,
        },
        "by_category":     by_category,
        "rows":            rows,
        "calibration_note": "P44.0 harness. Offline. No network calls. Delta written in full.",
    }

    return router.seal(result)


# ── Terminal report ───────────────────────────────────────────────────────────

_C = {
    "cyan": "\033[36m", "green": "\033[32m", "yellow": "\033[33m",
    "red":  "\033[31m", "gray":  "\033[90m", "white":  "\033[97m",
    "bold": "\033[1m",  "reset": "\033[0m",
}

def _c(t: str, c: str) -> str:
    return "{}{}{}".format(_C.get(c, ""), t, _C["reset"])


def print_report(ev: dict, out_path: str) -> None:
    rd = ev["routing_distribution"]
    ec = ev["economics"]
    es = ev["entropy_stats"]
    cd = ev["confidence_distribution"]
    n  = ev["items_evaluated"]

    print()
    print(_c("=" * 64, "cyan"))
    print(_c("  TEIA P44.0 — Public Benchmark Harness", "cyan"))
    print(_c("  Format: {}  |  Items: {}  |  {} ms  |  {} items/s".format(
        ev["input_format"], n, ev["elapsed_ms"], ev["throughput_per_sec"]), "cyan"))
    print(_c("=" * 64, "cyan"))
    print()
    print(_c("  ROUTING DISTRIBUTION", "white"))
    print("  {:32s}: {} ({:.0f}%)".format("Local  (SLM / zero GPU-s)", _c(str(rd["local_count"]),  "green"),  rd["local_pct"]))
    print("  {:32s}: {} ({:.0f}%)".format("Hybrid (quantized 13-34B)", _c(str(rd["hybrid_count"]), "yellow"), rd["hybrid_pct"]))
    print("  {:32s}: {} ({:.0f}%)".format("Cloud  (Frontier LLM)",     _c(str(rd["cloud_count"]),  "red"),    rd["cloud_pct"]))
    print()
    print(_c("  ENTROPY STATISTICS", "white"))
    print("  {:32s}: {:.4f}".format("Mean semantic entropy", es["mean"]))
    print("  {:32s}: {:.4f} — {:.4f}".format("Range", es["min"], es["max"]))
    print("  {:32s}: {}% of decisions".format("High confidence",        _c(str(cd["high_pct"]) + "%", "green")))
    print()
    print(_c("  ECONOMICS", "white"))
    baseline_str = "USD {:.6f}".format(ec["baseline_cloud_usd"])
    routed_str   = "USD {:.6f}".format(ec["teia_routed_usd"])
    delta_str    = "USD {:.6f}".format(ec["delta_usd_saved"])
    savings_str  = "{:.1f}%".format(ec["savings_pct"])
    mo_base_str  = "USD {:.2f}/mo".format(ec["projected_monthly_baseline_usd"])
    mo_delta_str = "USD {:.2f}/mo saved".format(ec["projected_monthly_delta_usd"])
    print("  {:32s}: {}".format("Baseline (100% Cloud)",     _c(baseline_str, "red")))
    print("  {:32s}: {}".format("TEIA-Routed",               _c(routed_str,   "cyan")))
    print("  {:32s}: {}  ({})".format("Delta saved",         _c(delta_str, "green"), _c(savings_str, "green")))
    print("  {:32s}: {}".format("Projected baseline/mo",     _c(mo_base_str,  "red")))
    print("  {:32s}: {}".format("Projected delta saved/mo",  _c(mo_delta_str, "green")))

    if ev["by_category"]:
        print()
        print(_c("  BY CATEGORY", "white"))
        for cat, d in ev["by_category"].items():
            print("  {:20s} n={:4d}  L={:.0f}%  H={:.0f}%  C={:.0f}%".format(
                cat[:20], d["count"], d["local_pct"], d["hybrid_pct"], d["cloud_pct"]))

    seal = ev.get("audit_seal", {})
    print()
    print(_c("  AUDIT SEAL", "white"))
    print("  SHA-256  : {}".format(_c(seal.get("sha256", ""), "cyan")))
    print("  Output   : {}".format(out_path))
    print(_c("=" * 64, "cyan"))
    print()


# ── Entry point ───────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="TEIA P44.0 — Public Benchmark Harness (offline, deterministic)"
    )
    parser.add_argument("--input",    "-i", required=True,  help="Path to benchmark JSON file")
    parser.add_argument("--output",   "-o", default="",     help="Output path for evaluation JSON")
    parser.add_argument("--category", "-c", default="",     help="Filter to a single category")
    parser.add_argument("--max",      "-n", type=int, default=0, help="Max items to evaluate (0 = all)")
    args = parser.parse_args()

    in_path = Path(args.input)
    if not in_path.exists():
        print("ERROR: input file not found: {}".format(in_path))
        sys.exit(1)

    raw = json.loads(in_path.read_text(encoding="utf-8"))

    # Unwrap common wrappers: {"data": [...]} or {"questions": [...]} or plain list
    if isinstance(raw, dict):
        for key in ("data", "questions", "items", "prompts", "examples"):
            if key in raw and isinstance(raw[key], list):
                raw = raw[key]
                break
    if not isinstance(raw, list):
        print("ERROR: expected a JSON array at top level (or nested under 'data'/'questions').")
        sys.exit(1)

    cat_filter = args.category.strip() or None
    max_items  = args.max if args.max > 0 else None

    ev = evaluate(raw, category_filter=cat_filter, max_items=max_items)

    out_path = args.output or str(in_path.parent / "public_benchmark_evaluation.json")
    json_str = router.to_canonical_json(ev)
    Path(out_path).write_text(json_str, encoding="utf-8")
    digest = hashlib.sha256(json_str.encode()).hexdigest()

    print_report(ev, out_path)
    print("  JSON SHA-256 : {}".format(digest))
    print()


if __name__ == "__main__":
    main()
