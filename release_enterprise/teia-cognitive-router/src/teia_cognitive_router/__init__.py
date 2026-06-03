"""
teia_cognitive_router — Deterministic, compliance-first LLM routing.

Public API:
  route(text, compliance_safe_mode=True, allow_hybrid=False) -> dict
  seal(result)                                               -> dict
  route_and_seal(text, compliance_safe_mode=True, ...)       -> (dict, str)
  to_canonical_json(obj)                                     -> str

Compliance-safe mode (default since v1.2.0):
  Only routes to Local when entropy < COMPLIANCE_SAFE_LOCAL_MAX (0.20).
  Everything above that threshold goes to Cloud.
  Premise: save only when quality degradation is rigorously zero.

Write==Read invariant: identical input -> identical JSON -> identical SHA-256.
Delta always written in full — mathematical symbol prohibited.
"""

from teia_cognitive_router._router import (
    route,
    seal,
    route_and_seal,
    to_canonical_json,
    GPU_COST_PER_SECOND_USD,
    CLOUD_TOKENS_PER_SECOND,
    LOCAL_TOKENS_PER_SECOND,
    WEIGHTS,
    LOCAL_THRESHOLD,
    HYBRID_THRESHOLD,
    COMPLIANCE_SAFE_MODE,
    COMPLIANCE_SAFE_LOCAL_MAX,
)

__version__ = "1.3.0"

__all__ = [
    "route",
    "seal",
    "route_and_seal",
    "to_canonical_json",
    "GPU_COST_PER_SECOND_USD",
    "CLOUD_TOKENS_PER_SECOND",
    "LOCAL_TOKENS_PER_SECOND",
    "WEIGHTS",
    "LOCAL_THRESHOLD",
    "HYBRID_THRESHOLD",
    "COMPLIANCE_SAFE_MODE",
    "COMPLIANCE_SAFE_LOCAL_MAX",
]
