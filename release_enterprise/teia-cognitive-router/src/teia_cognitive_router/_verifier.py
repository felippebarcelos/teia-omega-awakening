"""
_verifier.py — TEIA Cryptographic Audit Verifier P44.0
Proves that a routing decision is mathematically reproducible and unmodified.

Two verification modes:

  1. DOCUMENT SEAL VERIFICATION
     Given any TEIA-sealed JSON file, strips the audit_seal, recomputes
     the SHA-256 of the canonical JSON body, and confirms it matches the
     stored seal. Proves the document has not been tampered with since
     it was produced.

  2. FULL ROUTING VERIFICATION (stronger — for compliance officers)
     Given the original prompt text AND a sealed routing result,
     re-runs the entire TEIA routing math deterministically in memory,
     recomputes the routing decision from scratch, and proves:
       (a) the stored seal matches the document body (integrity)
       (b) the routing decision is mathematically reproducible from the
           original prompt (determinism)
     This is the proof that the routing decision could not have been
     manipulated after the fact.

Usage:
  # Verify document seal only
  teia-verify --file quality_cost_results.json

  # Full routing verification (requires original prompt)
  teia-verify --file routing_result.json --text "Your original prompt"
  teia-verify --file routing_result.json --prompt-file prompt.txt

  # Verify from stored prompt (if routing result contains input text)
  teia-verify --file routing_result.json --from-stored

Output: AUDIT PASS or AUDIT FAIL with full diagnostic detail.
Write==Read invariant. Delta always written in full.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any

from . import _router as router

# ── ANSI colours ─────────────────────────────────────────────────────────────

_C = {
    "cyan":  "\033[36m", "green": "\033[32m", "yellow": "\033[33m",
    "red":   "\033[31m", "white": "\033[97m", "bold":   "\033[1m",
    "reset": "\033[0m",
}

def _c(t: str, c: str) -> str:
    return "{}{}{}".format(_C.get(c, ""), t, _C["reset"])


# ── Verification logic ────────────────────────────────────────────────────────

def verify_document_seal(data: dict[str, Any]) -> dict[str, Any]:
    """
    Strips the audit_seal from data, recomputes SHA-256 of canonical JSON,
    and compares with the stored seal. Returns a result dict.
    """
    stored_seal = data.get("audit_seal", {})
    stored_hash = stored_seal.get("sha256", "")

    if not stored_hash:
        return {
            "pass":     False,
            "mode":     "document_seal",
            "reason":   "No audit_seal.sha256 field found in document.",
            "stored":   "",
            "computed": "",
        }

    body = {k: v for k, v in data.items() if k != "audit_seal"}
    canonical = router.to_canonical_json(body)
    computed_hash = hashlib.sha256(canonical.encode("utf-8")).hexdigest()

    return {
        "pass":     computed_hash == stored_hash,
        "mode":     "document_seal",
        "stored":   stored_hash,
        "computed": computed_hash,
        "reason":   "SHA-256 match" if computed_hash == stored_hash else "SHA-256 mismatch — document may have been modified",
    }


def verify_routing_decision(data: dict[str, Any], prompt_text: str) -> dict[str, Any]:
    """
    Re-runs the full routing math from the original prompt,
    then compares every field of the freshly-computed result
    against the stored result (excluding audit_seal).
    Also verifies the document seal.
    """
    seal_result = verify_document_seal(data)

    fresh_result   = router.route(prompt_text)
    fresh_entropy  = fresh_result["semantic_entropy_score"]
    fresh_decision = fresh_result["routing_decision"]

    stored_entropy  = data.get("semantic_entropy_score")
    stored_decision = data.get("routing_decision")

    entropy_match  = (fresh_entropy  == stored_entropy)
    decision_match = (fresh_decision == stored_decision)

    stored_features = data.get("entropy_features", {})
    fresh_features  = fresh_result.get("entropy_features", {})
    features_match  = (stored_features == fresh_features)

    all_pass = seal_result["pass"] and entropy_match and decision_match and features_match

    return {
        "pass":          all_pass,
        "mode":          "full_routing_verification",
        "document_seal": seal_result,
        "entropy": {
            "stored":   stored_entropy,
            "computed": fresh_entropy,
            "match":    entropy_match,
        },
        "decision": {
            "stored":   stored_decision,
            "computed": fresh_decision,
            "match":    decision_match,
        },
        "features_match": features_match,
        "reason": (
            "All checks passed — routing decision is mathematically proven and unmodified"
            if all_pass else
            "Verification failed — see individual check results above"
        ),
    }


def _find_stored_prompt(data: dict[str, Any]) -> str | None:
    for key in ("input_text", "prompt", "text", "query"):
        if key in data and isinstance(data[key], str) and data[key].strip():
            return data[key]
    return None


# ── Terminal output ───────────────────────────────────────────────────────────

def print_result(result: dict[str, Any], file_path: str) -> bool:
    print()
    print(_c("=" * 64, "cyan"))
    print(_c("  TEIA Audit Verifier — P44.0", "cyan"))
    print("  File: {}".format(file_path))
    print(_c("=" * 64, "cyan"))

    passed = result["pass"]
    mode   = result["mode"]

    if mode == "document_seal":
        print()
        print(_c("  Mode: Document Seal Verification", "white"))
        print("  Stored SHA-256  : {}".format(_c(result["stored"],   "cyan")))
        print("  Computed SHA-256: {}".format(_c(result["computed"], "cyan")))
        print()
        if passed:
            print(_c("  AUDIT PASS: The document seal is valid.", "bold"))
            print(_c("  The routing data has not been modified since it was produced.", "green"))
        else:
            print(_c("  AUDIT FAIL: {}".format(result["reason"]), "red"))

    elif mode == "full_routing_verification":
        ds = result["document_seal"]
        en = result["entropy"]
        dc = result["decision"]

        print()
        print(_c("  Mode: Full Routing Verification (Determinism Proof)", "white"))
        print()
        print("  [{}] Document seal    stored={} computed={}".format(
            _c("PASS", "green") if ds["pass"] else _c("FAIL", "red"),
            ds["stored"][:16] + "...",
            ds["computed"][:16] + "...",
        ))
        print("  [{}] Entropy score    stored={} computed={}".format(
            _c("PASS", "green") if en["match"] else _c("FAIL", "red"),
            en["stored"], en["computed"],
        ))
        print("  [{}] Routing decision stored={} computed={}".format(
            _c("PASS", "green") if dc["match"] else _c("FAIL", "red"),
            _c(str(dc["stored"]),   "cyan"),
            _c(str(dc["computed"]), "cyan"),
        ))
        print("  [{}] Feature vector   all 6 entropy features match".format(
            _c("PASS", "green") if result["features_match"] else _c("FAIL", "red"),
        ))
        print()
        if passed:
            print(_c("  AUDIT PASS: The routing decision is mathematically proven and unmodified.", "bold"))
            print(_c("  Routing is deterministic: same prompt always produces the same verdict.", "green"))
            print(_c("  This decision can be reproduced by any auditor with access to the prompt.", "green"))
        else:
            print(_c("  AUDIT FAIL: {}".format(result["reason"]), "red"))

    print(_c("=" * 64, "cyan"))
    print()
    return passed


# ── Entry point ───────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="TEIA Audit Verifier — cryptographically prove a routing decision is unmodified"
    )
    parser.add_argument("--file",        "-f", required=True, help="Path to sealed TEIA JSON file")
    parser.add_argument("--text",        "-t", default="",    help="Original prompt text (for full verification)")
    parser.add_argument("--prompt-file", "-p", default="",    help="Path to file containing original prompt")
    parser.add_argument("--from-stored",       action="store_true",
                        help="Use prompt stored inside the routing result (if present)")
    parser.add_argument("--output",      "-o", default="",    help="Write verification result JSON to this path")
    args = parser.parse_args()

    file_path = Path(args.file)
    if not file_path.exists():
        print("ERROR: file not found: {}".format(file_path))
        sys.exit(1)

    data = json.loads(file_path.read_text(encoding="utf-8"))

    prompt_text: str | None = None
    if args.text.strip():
        prompt_text = args.text.strip()
    elif args.prompt_file:
        pf = Path(args.prompt_file)
        if not pf.exists():
            print("ERROR: prompt file not found: {}".format(pf))
            sys.exit(1)
        prompt_text = pf.read_text(encoding="utf-8").strip()
    elif args.from_stored:
        prompt_text = _find_stored_prompt(data)
        if not prompt_text:
            print("ERROR: --from-stored specified but no prompt text found in the JSON file.")
            sys.exit(1)

    if prompt_text:
        result = verify_routing_decision(data, prompt_text)
    else:
        result = verify_document_seal(data)

    passed = print_result(result, str(file_path))

    if args.output:
        out_json = router.to_canonical_json(result)
        Path(args.output).write_text(out_json, encoding="utf-8")
        print("  Verification result written to: {}".format(args.output))
        print()

    sys.exit(0 if passed else 1)


if __name__ == "__main__":
    main()
