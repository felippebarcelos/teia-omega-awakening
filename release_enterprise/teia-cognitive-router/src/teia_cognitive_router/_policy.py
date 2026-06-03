"""
P54.0 — Routing Policy Engine
Apply hard compliance rules on top of entropy-based routing decisions.
Deterministic: identical routing_result + identical policy -> identical output.
Pure stdlib — no dependencies.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any

_POLICY_VERSION  = "1.5.0"
_POLICY_PROTOCOL = "P54.0"

# ── Built-in example policy ───────────────────────────────────────────────────

EXAMPLE_POLICY: dict[str, Any] = {
    "name":        "teia-example-policy",
    "version":     "1.0",
    "description": "Example compliance routing policy for regulated TEIA deployments",
    "rules": [
        {
            "id":          "HIPAA-001",
            "description": "PHI data must never leave local infrastructure",
            "priority":    10,
            "if":          {"decision": "cloud"},
            "then":        {
                "force_decision":  "local",
                "add_flag":        "hipaa_enforced",
                "override_reason": "HIPAA-001: PHI data locality requirement"
            },
        },
        {
            "id":          "GDPR-DPO-001",
            "description": "High-entropy cloud decisions flagged for DPO review",
            "priority":    20,
            "if":          {"entropy_range": [0.85, 1.0], "decision": "cloud"},
            "then":        {
                "add_flag":        "dpo_review_required",
                "override_reason": "GDPR-DPO-001: high-entropy cloud routing flagged"
            },
        },
        {
            "id":          "LOCAL-FLOOR",
            "description": "Trivially simple tasks (entropy < 0.10) must stay local",
            "priority":    30,
            "if":          {"entropy_range": [0.0, 0.10]},
            "then":        {
                "force_decision":  "local",
                "override_reason": "LOCAL-FLOOR: trivially simple task, cloud prohibited"
            },
        },
        {
            "id":          "HYBRID-BLOCK",
            "description": "Hybrid tier not approved — collapse to local",
            "priority":    40,
            "if":          {"decision": "hybrid"},
            "then":        {
                "force_decision":  "local",
                "override_reason": "HYBRID-BLOCK: hybrid tier not in approved tier list"
            },
        },
    ],
}


# ── Policy loader + validator ─────────────────────────────────────────────────

def load_policy(source: "Path | dict[str, Any]") -> "dict[str, Any]":
    """Load a policy from a JSON file path or an already-parsed dict."""
    if isinstance(source, Path):
        policy: dict[str, Any] = json.loads(source.read_text(encoding="utf-8"))
    else:
        policy = dict(source)

    errors = validate_policy(policy)
    if errors:
        raise ValueError(
            "Policy validation failed:\n" + "\n".join(f"  - {e}" for e in errors)
        )
    return policy


def validate_policy(policy: "dict[str, Any]") -> "list[str]":
    """Return a list of validation error strings (empty = valid)."""
    errors: list[str] = []

    if not isinstance(policy, dict):
        return ["Policy must be a JSON object"]
    if "name" not in policy:
        errors.append("Missing required field: 'name'")
    if "rules" not in policy:
        errors.append("Missing required field: 'rules'")
        return errors
    if not isinstance(policy["rules"], list):
        errors.append("'rules' must be an array")
        return errors

    ids_seen: set[str] = set()
    for i, rule in enumerate(policy["rules"]):
        tag = f"rules[{i}]"
        if not isinstance(rule, dict):
            errors.append(f"{tag}: must be an object")
            continue
        if "id" not in rule:
            errors.append(f"{tag}: missing 'id'")
        elif rule["id"] in ids_seen:
            errors.append(f"{tag}: duplicate rule id '{rule['id']}'")
        else:
            ids_seen.add(rule["id"])
        if "if" not in rule:
            errors.append(f"{tag}: missing 'if' condition block")
        if "then" not in rule:
            errors.append(f"{tag}: missing 'then' action block")
        elif "force_decision" in rule["then"]:
            fd = str(rule["then"]["force_decision"]).lower()
            if fd not in ("local", "hybrid", "cloud"):
                errors.append(f"{tag}: force_decision must be 'local', 'hybrid', or 'cloud'")

    return errors


# ── Condition matching ────────────────────────────────────────────────────────

def _matches(cond: "dict[str, Any]", result: "dict[str, Any]") -> bool:
    """
    Return True iff every key in `cond` is satisfied by `result`.
    Empty condition = always True.
    """
    if cond.get("always"):
        return True

    entropy    = float(result.get("semantic_entropy_score", 0.0))
    decision   = str(result.get("routing_decision", "")).lower()
    confidence = str(result.get("routing_confidence", "")).lower()

    if "entropy_range" in cond:
        lo = float(cond["entropy_range"][0])
        hi = float(cond["entropy_range"][1])
        if not (lo <= entropy <= hi):
            return False

    if "min_entropy" in cond:
        if entropy < float(cond["min_entropy"]):
            return False

    if "max_entropy" in cond:
        if entropy > float(cond["max_entropy"]):
            return False

    if "decision" in cond:
        if decision != str(cond["decision"]).lower():
            return False

    if "confidence" in cond:
        if confidence != str(cond["confidence"]).lower():
            return False

    return True


# ── Core enforcement ──────────────────────────────────────────────────────────

def _canonical(obj: Any) -> str:
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def enforce(
    routing_result: "dict[str, Any]",
    policy: "dict[str, Any]",
) -> "dict[str, Any]":
    """
    Apply policy rules to a routing result. Returns a new dict.

    Adds a top-level 'policy_seal' field; the original 'audit_seal' is preserved.

    Write==Read invariant:
      identical routing_result + identical policy -> identical policy_seal.sha256.

    policy_seal.sha256 = SHA-256(original_audit_sha256 + ":" + canonical(enforcement))
    """
    rules = sorted(
        [r for r in policy.get("rules", []) if isinstance(r, dict)],
        key=lambda r: (int(r.get("priority", 999)), str(r.get("id", ""))),
    )

    applied: "dict[str, Any] | None" = None
    for rule in rules:
        if _matches(rule.get("if", {}), routing_result):
            applied = rule
            break

    original_decision = str(routing_result.get("routing_decision", ""))
    result            = dict(routing_result)

    if applied is not None:
        action = applied.get("then", {})
        if "force_decision" in action:
            result["routing_decision"] = str(action["force_decision"]).capitalize()

    enforced_decision = str(result.get("routing_decision", original_decision))

    flags: list[str] = []
    if applied is not None and "add_flag" in applied.get("then", {}):
        flags.append(str(applied["then"]["add_flag"]))

    enforcement: dict[str, Any] = {
        "policy_name":       str(policy.get("name", "")),
        "policy_version":    str(policy.get("version", "1.0")),
        "rule_applied":      applied["id"] if applied else None,
        "rule_description":  applied.get("description", "") if applied else None,
        "original_decision": original_decision,
        "enforced_decision": enforced_decision,
        "decision_changed":  enforced_decision != original_decision,
        "override_reason":   applied["then"].get("override_reason", "") if applied else None,
        "flags":             flags,
        "rule_matched":      applied is not None,
    }

    original_sha = ""
    if isinstance(routing_result.get("audit_seal"), dict):
        original_sha = str(routing_result["audit_seal"].get("sha256", ""))

    seal_input  = original_sha + ":" + _canonical(enforcement)
    policy_sha  = hashlib.sha256(seal_input.encode("utf-8")).hexdigest()

    result["policy_seal"] = {
        "sha256":    policy_sha,
        "algorithm": "SHA-256",
        "scope":     "original_audit_sha256:canonical_enforcement_json",
        **enforcement,
    }
    return result


def enforce_chain(
    chain_file: Path,
    policy: "dict[str, Any]",
) -> "list[dict[str, Any]]":
    """Apply policy to every entry in a JSONL audit chain."""
    results: list[dict[str, Any]] = []
    with chain_file.open("r", encoding="utf-8") as fh:
        for raw in fh:
            raw = raw.strip()
            if raw:
                results.append(enforce(json.loads(raw), policy))
    return results


# ── CLI ───────────────────────────────────────────────────────────────────────

def _print_enforcement(enforced: "dict[str, Any]") -> None:
    ps = enforced.get("policy_seal", {})
    matched = ps.get("rule_matched", False)
    changed = ps.get("decision_changed", False)
    sha     = ps.get("sha256", "")[:32]

    if not matched:
        print("  POLICY PASS     — no rule matched; decision unchanged")
    elif changed:
        print("  POLICY ENFORCED — decision overridden by policy rule")
        print(f"  Rule            : {ps.get('rule_applied', '—')}")
        print(f"  Original        : {ps.get('original_decision', '—')}")
        print(f"  Enforced        : {ps.get('enforced_decision', '—')}")
        print(f"  Reason          : {ps.get('override_reason', '—')}")
    else:
        print("  POLICY FLAGGED  — decision unchanged, compliance flag added")
        print(f"  Rule            : {ps.get('rule_applied', '—')}")
        print(f"  Reason          : {ps.get('override_reason', '—')}")

    if ps.get("flags"):
        print(f"  Flags           : {', '.join(ps['flags'])}")
    print(f"  Policy SHA-256  : {sha}…")


def _cli() -> None:
    parser = argparse.ArgumentParser(
        prog="teia-policy",
        description=(
            "Apply compliance routing policies to TEIA audit records. "
            "Deterministic: same inputs -> same policy_seal.sha256."
        ),
    )
    sub = parser.add_subparsers(dest="command", required=True)

    # ── enforce ──
    p_e = sub.add_parser("enforce", help="Apply policy to a JSON result or JSONL chain")
    p_e.add_argument("--policy", "-p", type=Path, required=True,
                     help="Policy JSON file")
    g = p_e.add_mutually_exclusive_group(required=True)
    g.add_argument("--input",  "-i", type=Path,
                   help="Single routing_result.json")
    g.add_argument("--chain",  "-c", type=Path,
                   help="JSONL audit chain (batch)")
    p_e.add_argument("--output", "-o", type=Path, default=None,
                     help="Output file (auto-named if omitted)")

    # ── validate ──
    p_v = sub.add_parser("validate", help="Validate a policy JSON file")
    p_v.add_argument("policy_file", type=Path, help="Policy JSON file")

    # ── example ──
    sub.add_parser("example", help="Print a sample policy JSON to stdout")

    args = parser.parse_args()

    # ── example ──────────────────────────────────────────────────────────────
    if args.command == "example":
        print(json.dumps(EXAMPLE_POLICY, indent=2, ensure_ascii=False))
        return

    # ── validate ─────────────────────────────────────────────────────────────
    if args.command == "validate":
        p = args.policy_file.resolve()
        if not p.exists():
            print(f"ERROR: {p} not found", file=sys.stderr); sys.exit(1)
        try:
            policy = load_policy(p)
        except (ValueError, json.JSONDecodeError) as exc:
            print(f"POLICY INVALID: {exc}", file=sys.stderr); sys.exit(1)
        n = len(policy.get("rules", []))
        print(f"POLICY VALID: {n} rule(s) — {policy.get('name', '?')} v{policy.get('version', '?')}")
        for r in policy.get("rules", []):
            pri  = r.get("priority", "—")
            rid  = r.get("id", "?")
            desc = r.get("description", "")
            print(f"  [{rid:16s}] priority={pri:>4}  {desc}")
        return

    # ── enforce ───────────────────────────────────────────────────────────────
    if args.command == "enforce":
        policy_path = args.policy.resolve()
        if not policy_path.exists():
            print(f"ERROR: policy not found: {policy_path}", file=sys.stderr); sys.exit(1)
        try:
            policy = load_policy(policy_path)
        except (ValueError, json.JSONDecodeError) as exc:
            print(f"ERROR loading policy: {exc}", file=sys.stderr); sys.exit(1)

        if args.chain:
            chain_path = args.chain.resolve()
            if not chain_path.exists():
                print(f"ERROR: chain not found: {chain_path}", file=sys.stderr); sys.exit(1)
            results = enforce_chain(chain_path, policy)
            out: Path = args.output or chain_path.with_suffix("").with_suffix(".enforced.jsonl")
            with out.open("w", encoding="utf-8") as fh:
                for r in results:
                    fh.write(json.dumps(r, ensure_ascii=False) + "\n")
            n_changed = sum(1 for r in results if r.get("policy_seal", {}).get("decision_changed"))
            n_flagged = sum(
                1 for r in results
                if r.get("policy_seal", {}).get("flags")
                and not r.get("policy_seal", {}).get("decision_changed")
            )
            print(f"Enforced {len(results)} entries  →  {out}")
            print(f"  Overridden : {n_changed}")
            print(f"  Flagged    : {n_flagged}")
            print(f"  Unchanged  : {len(results) - n_changed - n_flagged}")
            return

        in_path = args.input.resolve()
        if not in_path.exists():
            print(f"ERROR: input not found: {in_path}", file=sys.stderr); sys.exit(1)
        routing_result = json.loads(in_path.read_text(encoding="utf-8"))
        enforced = enforce(routing_result, policy)
        out = args.output or in_path.with_suffix("").with_suffix(".enforced.json")
        out.write_text(
            json.dumps(enforced, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
        _print_enforcement(enforced)
        print(f"  Output          : {out}")


if __name__ == "__main__":
    _cli()
