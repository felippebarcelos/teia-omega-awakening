"""
teia_cognitive_router — Deterministic, compliance-first LLM routing.

Public API:
  route(text)            -> dict   — route a prompt, returns full result dict
  seal(result)           -> dict   — attach SHA-256 audit seal
  route_and_seal(text)   -> (dict, str) — route + seal + canonical JSON string
  to_canonical_json(obj) -> str    — deterministic JSON (sort_keys, no whitespace)

Write==Read invariant: identical input -> identical JSON -> identical SHA-256.
Delta always written in full — mathematical symbol prohibited.
"""

from teia_cognitive_router._router import (
    route,
    seal,
    route_and_seal,
    to_canonical_json,
    GPU_COST_PER_SECOND_USD,
    WEIGHTS,
    LOCAL_THRESHOLD,
    HYBRID_THRESHOLD,
)

__version__ = "1.1.0"

__all__ = [
    "route",
    "seal",
    "route_and_seal",
    "to_canonical_json",
    "GPU_COST_PER_SECOND_USD",
    "WEIGHTS",
    "LOCAL_THRESHOLD",
    "HYBRID_THRESHOLD",
]
