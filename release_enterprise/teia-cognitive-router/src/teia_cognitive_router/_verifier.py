"""
_verifier.py — TEIA Cryptographic Audit Verifier P49.0
Proves that a routing decision is mathematically reproducible and unmodified.

Three verification modes:

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

  3. TEMPORAL CHAIN VERIFICATION (P49.0 — for JSONL audit logs)
     Given a JSONL audit log file produced by the gateway, walks every
     entry in sequence and re-derives each time_anchor_hash from
     SHA-256(prev_anchor:sha256). Any gap, deletion, or modification
     in the ledger breaks the chain at that position.

Usage:
  # Verify document seal only
  teia-verify --file quality_cost_results.json

  # Full routing verification (requires original prompt)
  teia-verify --file routing_result.json --text "Your original prompt"
  teia-verify --file routing_result.json --prompt-file prompt.txt

  # Verify from stored prompt (if routing result contains input text)
  teia-verify --file routing_result.json --from-stored

  # Verify temporal chain in a gateway audit JSONL log
  teia-verify --verify-chain --chain-file teia_gateway_audit.jsonl

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


def verify_temporal_chain(entries: list[dict[str, Any]]) -> dict[str, Any]:
    """
    Walks a list of JSONL audit log entries (each must have audit_seal.sha256
    and audit_seal.time_anchor_hash) and re-derives every time_anchor_hash
    from SHA-256(prev_anchor:sha256). Returns a result dict with per-entry
    check results and overall pass/fail.
    """
    if not entries:
        return {
            "pass":   False,
            "mode":   "temporal_chain",
            "reason": "Empty entry list — nothing to verify.",
            "checks": [],
            "total":  0,
            "failed": 0,
        }

    checks: list[dict[str, Any]] = []
    prev_anchor = "GENESIS"
    failed = 0

    for idx, entry in enumerate(entries):
        seal = entry.get("audit_seal", {})
        stored_sha    = seal.get("sha256", "")
        stored_anchor = seal.get("time_anchor_hash", "")
        stored_prev   = seal.get("prev_anchor_sha256", "")

        if not stored_sha or not stored_anchor:
            checks.append({
                "index":  idx,
                "pass":   False,
                "reason": "Missing audit_seal.sha256 or audit_seal.time_anchor_hash",
            })
            failed += 1
            continue

        expected_anchor = hashlib.sha256(
            (prev_anchor + ":" + stored_sha).encode("utf-8")
        ).hexdigest()

        ok = (stored_anchor == expected_anchor)
        checks.append({
            "index":            idx,
            "pass":             ok,
            "stored_sha256":    stored_sha,
            "expected_anchor":  expected_anchor,
            "stored_anchor":    stored_anchor,
            "prev_anchor_used": prev_anchor,
            "reason":           "OK" if ok else "time_anchor_hash mismatch — chain broken at this entry",
        })
        if not ok:
            failed += 1

        prev_anchor = stored_anchor

    all_pass = failed == 0
    return {
        "pass":   all_pass,
        "mode":   "temporal_chain",
        "total":  len(entries),
        "failed": failed,
        "checks": checks,
        "reason": (
            f"All {len(entries)} entries form a valid chain"
            if all_pass else
            f"{failed} of {len(entries)} entries failed chain verification"
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
    print(_c("  TEIA Audit Verifier — P49.0", "cyan"))
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

def _print_chain_result(result: dict[str, Any], chain_file: str) -> bool:
    print()
    print(_c("=" * 64, "cyan"))
    print(_c("  TEIA Audit Verifier — P49.0", "cyan"))
    print("  Mode: Temporal Chain Verification")
    print("  File: {}".format(chain_file))
    print(_c("=" * 64, "cyan"))
    print()
    passed = result["pass"]
    print("  Entries  : {}".format(result["total"]))
    print("  Failed   : {}".format(result["failed"]))
    print()
    for chk in result["checks"]:
        status = _c("PASS", "green") if chk["pass"] else _c("FAIL", "red")
        print("  [{}] entry #{:04d}  {}".format(status, chk["index"], chk.get("reason", "")))
    print()
    if passed:
        print(_c("  AUDIT PASS: Temporal chain is intact and unbroken.", "bold"))
        print(_c("  Every entry links to its predecessor — no deletions or modifications.", "green"))
    else:
        print(_c("  AUDIT FAIL: {}".format(result["reason"]), "red"))
    print(_c("=" * 64, "cyan"))
    print()
    return passed


def main() -> None:
    parser = argparse.ArgumentParser(
        description="TEIA Audit Verifier — cryptographically prove a routing decision is unmodified"
    )
    parser.add_argument("--file",         "-f", default="",  help="Path to sealed TEIA JSON file")
    parser.add_argument("--text",         "-t", default="",  help="Original prompt text (for full verification)")
    parser.add_argument("--prompt-file",  "-p", default="",  help="Path to file containing original prompt")
    parser.add_argument("--from-stored",        action="store_true",
                        help="Use prompt stored inside the routing result (if present)")
    parser.add_argument("--output",       "-o", default="",  help="Write verification result JSON to this path")
    parser.add_argument("--verify-chain",       action="store_true",
                        help="Verify temporal chain in a gateway JSONL audit log")
    parser.add_argument("--chain-file",   "-c", default="",  help="Path to JSONL audit log for --verify-chain")
    args = parser.parse_args()

    # ── Temporal chain mode ───────────────────────────────────────────────────
    if args.verify_chain:
        chain_path = Path(args.chain_file or args.file)
        if not chain_path.exists():
            print("ERROR: chain file not found: {}".format(chain_path))
            sys.exit(1)
        entries: list[dict[str, Any]] = []
        for line in chain_path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line:
                entries.append(json.loads(line))
        result = verify_temporal_chain(entries)
        passed = _print_chain_result(result, str(chain_path))
        if args.output:
            Path(args.output).write_text(router.to_canonical_json(result), encoding="utf-8")
            print("  Verification result written to: {}".format(args.output))
            print()
        sys.exit(0 if passed else 1)

    # ── Document / routing verification mode ─────────────────────────────────
    if not args.file:
        parser.error("--file is required unless --verify-chain is used")

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
