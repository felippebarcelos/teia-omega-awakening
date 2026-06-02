"""
teia_cognitive_router.py — TEIA Cognitive Router P40.0 (Python Port)
Heuristic Semantic Entropy analysis for AI prompt routing.
Pure Python stdlib — zero ML dependencies — sub-millisecond O(1) inference.

Routing tiers:
  Local  (<0.35)  — SLM 1-7B / edge inference, zero GPU-seconds
  Hybrid (0.35–0.65) — quantized 13-34B, reduced GPU footprint
  Cloud  (≥0.65)  — Frontier LLM (GPT-4/Claude-Opus), full GPU inference

Output: canonical JSON sealed with SHA-256 for audit trails.
Write==Read invariant: identical input → identical JSON → identical SHA-256.
Delta always written in full — mathematical symbol prohibited.
"""

from __future__ import annotations

import hashlib
import json
import math
import re
import sys
from typing import Any

# ── Feature vocabulary ────────────────────────────────────────────────────────

_REASONING_VERBS: frozenset[str] = frozenset([
    "analyze", "analyse", "synthesize", "synthesise", "compare", "evaluate",
    "assess", "argue", "explain", "reason", "consider", "critique", "design",
    "architect", "hypothesize", "investigate", "interpret", "infer", "deduce",
    "formulate", "justify", "elaborate", "contrast", "differentiate",
    "reconcile", "extrapolate",
    "analisar", "avaliar", "comparar", "sintetizar", "explicar", "argumentar",
    "considerar", "raciocinar", "deduzir", "interpretar", "investigar",
    "justificar", "elaborar", "contrastar", "diferenciar", "reconciliar",
    "hipotetizar", "extrapolar",
])

_DATA_VERBS: frozenset[str] = frozenset([
    "list", "extract", "format", "convert", "parse", "count", "find", "get",
    "show", "translate", "summarize", "summarise", "filter", "sort", "map",
    "join", "split", "replace", "rename", "copy", "move", "delete", "insert",
    "append", "merge",
    "listar", "extrair", "formatar", "converter", "contar", "filtrar",
    "ordenar", "traduzir", "resumir", "substituir", "transformar", "renomear",
    "copiar", "mover", "inserir", "anexar", "mesclar", "dividir", "combinar",
])

_CONSTRAINT_PHRASES: tuple[str, ...] = (
    " but ", " however ", " although ", " unless ", " except ", " while ",
    " whereas ", " despite ", " considering ", " assuming ", " given that ",
    " provided that ", " on condition ", " in contrast ", " on the other hand ",
    " mas ", " porem ", " entretanto ", " embora ", " a menos ", " exceto ",
    " enquanto ", " dado que ", " considerando ", " supondo ", " desde que ",
)

# ── Feature weights (P40.0 calibration) ──────────────────────────────────────

WEIGHTS: dict[str, float] = {
    "token_score":          0.20,
    "vocab_diversity":      0.15,
    "reasoning_verb_score": 0.30,
    "data_op_score":        0.15,
    "structural_score":     0.10,
    "constraint_score":     0.10,
}

LOCAL_THRESHOLD:  float = 0.35
HYBRID_THRESHOLD: float = 0.65

# ── GPU economics defaults ────────────────────────────────────────────────────

GPU_COST_PER_SECOND_USD:  float = 0.002
CLOUD_TOKENS_PER_SECOND:  int   = 50
LOCAL_TOKENS_PER_SECOND:  int   = 5


# ── Feature computation ───────────────────────────────────────────────────────

def _tokenize(text: str) -> list[str]:
    return [w for w in re.split(r"[^a-záàâãéêíóôõúüçA-ZÁÀÂÃÉÊÍÓÔÕÚÜÇ0-9]+", text.lower()) if len(w) > 1]


def _token_score(char_count: int) -> float:
    return round(min(1.0, char_count / 4 / 4000.0), 4)


def _vocab_diversity(words: list[str]) -> float:
    if not words:
        return 0.0
    unique_ratio = len(set(words)) / len(words)
    return round(max(0.0, min(1.0, (unique_ratio - 0.3) / 0.6)), 4)


def _reasoning_verb_score(text_lower: str, word_count: int) -> tuple[float, int]:
    count = sum(1 for v in _REASONING_VERBS if v in text_lower)
    density = count / max(1, word_count)
    return round(min(1.0, density / 0.04), 4), count


def _data_op_score(text_lower: str, word_count: int) -> tuple[float, int]:
    count = sum(1 for v in _DATA_VERBS if v in text_lower)
    density = count / max(1, word_count)
    return round(max(0.0, 1.0 - min(1.0, density / 0.04)), 4), count


def _structural_score(text: str) -> float:
    line_count   = text.count("\n") + 1
    code_blocks  = len(re.findall(r"```", text)) / 2
    bullet_pts   = len(re.findall(r"(?m)^\s*[-*•]", text))
    header_count = len(re.findall(r"(?m)^#+\s", text))
    total = code_blocks * 3 + bullet_pts * 0.5 + header_count + line_count / 20
    return round(min(1.0, total / 15.0), 4)


def _constraint_score(text: str, word_count: int) -> tuple[float, int]:
    text_lower = text.lower()
    c_count = sum(text_lower.count(p) for p in _CONSTRAINT_PHRASES)
    q_count = text.count("?")
    total   = c_count + q_count * 0.5
    density = total / max(1, word_count)
    return round(min(1.0, density / 0.10), 4), c_count


# ── Composite score and routing ───────────────────────────────────────────────

def compute_semantic_entropy(text: str) -> dict[str, Any]:
    char_count  = len(text)
    token_est   = char_count // 4
    text_lower  = text.lower()
    words       = _tokenize(text)
    word_count  = max(1, len(words))

    ts = _token_score(char_count)
    vs = _vocab_diversity(words)
    rs, r_count = _reasoning_verb_score(text_lower, word_count)
    ds, d_count = _data_op_score(text_lower, word_count)
    ss = _structural_score(text)
    cs, c_count = _constraint_score(text, word_count)

    entropy = round(max(0.0, min(1.0,
        WEIGHTS["token_score"]          * ts +
        WEIGHTS["vocab_diversity"]      * vs +
        WEIGHTS["reasoning_verb_score"] * rs +
        WEIGHTS["data_op_score"]        * ds +
        WEIGHTS["structural_score"]     * ss +
        WEIGHTS["constraint_score"]     * cs
    )), 4)

    return {
        "char_count":       char_count,
        "token_estimate":   token_est,
        "word_count":       word_count,
        "entropy":          entropy,
        "features": {
            "token_score":          ts,
            "vocab_diversity":      vs,
            "reasoning_verb_score": rs,
            "data_op_score":        ds,
            "structural_score":     ss,
            "constraint_score":     cs,
        },
        "_reasoning_count": r_count,
        "_data_count":      d_count,
        "_constraint_count": c_count,
    }


def _routing_confidence(entropy: float) -> str:
    dist_local  = abs(entropy - LOCAL_THRESHOLD)
    dist_hybrid = abs(entropy - HYBRID_THRESHOLD)
    min_dist    = min(dist_local, dist_hybrid)
    if min_dist > 0.12:
        return "high"
    if min_dist > 0.05:
        return "medium"
    return "low"


def _routing_rationale(features: dict[str, float], r_count: int, d_count: int,
                        token_est: int, route: str) -> str:
    parts: list[str] = []
    if features["token_score"] > 0.4:
        parts.append(f"long context ({token_est} tokens est.)")
    if features["reasoning_verb_score"] > 0.4:
        parts.append(f"reasoning verbs present ({r_count})")
    if features["data_op_score"] < 0.3:
        parts.append(f"task dominated by data operations ({d_count})")
    if features["structural_score"] > 0.4:
        parts.append("rich structural complexity")
    if features["constraint_score"] > 0.4:
        parts.append("high logical constraint density")
    if not parts:
        parts.append("moderate entropy — no dominant signal")
    return "; ".join(parts)


def _gpu_economics(token_est: int, route: str) -> dict[str, Any]:
    output_tokens      = token_est // 2
    cloud_gpu_seconds  = round(output_tokens / CLOUD_TOKENS_PER_SECOND, 3)
    local_cpu_seconds  = round(output_tokens / LOCAL_TOKENS_PER_SECOND, 3)
    delta_gpu_saved    = 0.0 if route == "Cloud" else cloud_gpu_seconds
    delta_usd_saved    = round(delta_gpu_saved * GPU_COST_PER_SECOND_USD, 6)
    model_avoided = {
        "Local":  "Frontier LLM (GPT-4/Claude-Opus) — not activated",
        "Hybrid": "Frontier LLM (GPT-4/Claude-Opus) — not activated; quantized sufficient",
        "Cloud":  "None — complexity justifies frontier model",
    }[route]
    return {
        "output_tokens_estimate":     output_tokens,
        "cloud_gpu_seconds_estimate": cloud_gpu_seconds,
        "local_cpu_seconds_estimate": local_cpu_seconds,
        "delta_gpu_seconds_saved":    delta_gpu_saved,
        "delta_usd_saved":            delta_usd_saved,
        "gpu_cost_per_second_usd":    GPU_COST_PER_SECOND_USD,
        "model_avoided":              model_avoided,
    }


# ── Public API ────────────────────────────────────────────────────────────────

def route(text: str) -> dict[str, Any]:
    """Route a prompt. Returns canonical dict (use to_canonical_json for serialization)."""
    m = compute_semantic_entropy(text)

    entropy = m["entropy"]
    if entropy < LOCAL_THRESHOLD:
        decision = "Local"
    elif entropy < HYBRID_THRESHOLD:
        decision = "Hybrid"
    else:
        decision = "Cloud"

    confidence = _routing_confidence(entropy)
    rationale  = _routing_rationale(
        m["features"], m["_reasoning_count"], m["_data_count"],
        m["token_estimate"], decision
    )
    economics = _gpu_economics(m["token_estimate"], decision)

    result = {
        "router_version":         "1.0",
        "protocol":               "P40.0",
        "input_char_count":       m["char_count"],
        "input_token_estimate":   m["token_estimate"],
        "input_word_count":       m["word_count"],
        "semantic_entropy_score": entropy,
        "routing_decision":       decision,
        "routing_confidence":     confidence,
        "routing_rationale":      rationale,
        "entropy_features":       m["features"],
        "feature_weights":        WEIGHTS,
        "thresholds": {
            "local_max":  LOCAL_THRESHOLD,
            "hybrid_max": HYBRID_THRESHOLD,
        },
        "gpu_economics": economics,
        "routing_map": {
            "Local":  "SLM 1-7B or pure script (CPU inference, zero GPU-seconds)",
            "Hybrid": "Quantized model 13-34B (reduced GPU footprint)",
            "Cloud":  "Frontier LLM GPT-4/Claude-Opus (full GPU inference)",
        },
        "calibration_note": "Heuristic model P40.0. No network calls. Delta written in full.",
    }
    return result


def seal(result: dict[str, Any]) -> dict[str, Any]:
    """Attach SHA-256 audit seal to a routing result dict (non-destructive copy)."""
    canonical = to_canonical_json(result)
    digest    = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    sealed    = dict(result)
    sealed["audit_seal"] = {
        "sha256":    digest,
        "algorithm": "SHA-256",
        "scope":     "canonical_json_utf8",
        "note":      "Deterministic seal. Identical input produces identical digest. Suitable for compliance audit trails.",
    }
    return sealed


def to_canonical_json(obj: Any) -> str:
    """Canonical JSON: sorted keys, no extra spaces, UTF-8 safe, no trailing newline."""
    return json.dumps(obj, sort_keys=True, ensure_ascii=False, separators=(",", ":"))


def route_and_seal(text: str) -> tuple[dict[str, Any], str]:
    """Convenience: route + seal + return (sealed_dict, canonical_json_string)."""
    result = route(text)
    sealed = seal(result)
    return sealed, to_canonical_json(sealed)


# ── CLI entry point ───────────────────────────────────────────────────────────

def _cli() -> None:
    import argparse
    import pathlib

    parser = argparse.ArgumentParser(
        description="TEIA Cognitive Router P40.0 — Semantic Entropy routing for AI prompts"
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--text",  "-t", help="Prompt text (inline)")
    group.add_argument("--file",  "-f", help="Path to file containing the prompt")
    parser.add_argument("--output", "-o", help="Write sealed JSON to this path")
    parser.add_argument("--no-seal", action="store_true", help="Skip SHA-256 audit seal")
    args = parser.parse_args()

    text = args.text if args.text else pathlib.Path(args.file).read_text(encoding="utf-8")

    result = route(text)
    if not args.no_seal:
        result = seal(result)

    json_out = to_canonical_json(result)

    if args.output:
        pathlib.Path(args.output).write_text(json_out, encoding="utf-8")
        digest = hashlib.sha256(json_out.encode()).hexdigest()
        dec    = result["routing_decision"]
        colors = {"Local": "\033[32m", "Hybrid": "\033[33m", "Cloud": "\033[31m"}
        reset  = "\033[0m"
        print(f"\n{'='*60}")
        print(f"  TEIA Cognitive Router — P40.0")
        print(f"{'='*60}")
        print(f"  Tokens (est.)  : {result['input_token_estimate']}")
        print(f"  Semantic Ent.  : {result['semantic_entropy_score']:.4f}")
        print(f"  VERDICT        : {colors.get(dec,'')}{dec}{reset}")
        print(f"  Confidence     : {result['routing_confidence']}")
        gpu = result["gpu_economics"]
        print(f"  GPU delta saved: {gpu['delta_gpu_seconds_saved']} s  (USD {gpu['delta_usd_saved']:.6f})")
        print(f"  JSON           : {args.output}")
        print(f"  SHA-256        : {digest}")
        print(f"{'='*60}\n")
    else:
        print(json_out)


if __name__ == "__main__":
    _cli()
