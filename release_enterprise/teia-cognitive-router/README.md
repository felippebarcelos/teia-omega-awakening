# TEIA Cognitive Router

[![PyPI](https://img.shields.io/pypi/v/teia-cognitive-router)](https://pypi.org/project/teia-cognitive-router/1.5.0/)
[![Python](https://img.shields.io/pypi/pyversions/teia-cognitive-router)](https://pypi.org/project/teia-cognitive-router/)
[![License](https://img.shields.io/pypi/l/teia-cognitive-router)](https://pypi.org/project/teia-cognitive-router/)

**Compliance-First LLM Routing · Deterministic Cost Optimization · Cryptographic Audit Trails**

> *"The only router that can mathematically prove its own decisions."*

```bash
pip install teia-cognitive-router           # core router + audit verifier
pip install teia-cognitive-router[gateway]  # + Deterministic LLM Gateway (FastAPI proxy)
```

---

## The Problem With ML-Based Routers

Every production LLM routing system faces the same regulatory wall:

| ML Router Flaw | Compliance Consequence |
|---|---|
| Shifting weights after retraining | Same prompt routes differently next month — audit trail breaks |
| Non-reproducible outputs | Regulator asks "why did this go to GPT-4?" — you cannot answer |
| External model dependencies | Router behavior depends on third-party training data you don't control |
| GPU/network requirements | Adds latency and infrastructure cost to every request |

Financial institutions, healthcare providers, and government contractors operating under **EU AI Act, GDPR, HIPAA, SEC/FINRA, or Basel III** cannot pass compliance audits with routers that produce non-reproducible decisions.

**TEIA Cognitive Router is 100% mathematical, offline, and verifiable.**

---

## What TEIA Does

TEIA routes each AI prompt to the cheapest tier that can handle it — Local SLM, Hybrid quantized model, or Cloud frontier LLM — using a fixed 6-axis arithmetic formula. No neural weights. No training data. No external calls.

Every decision is:

- **Reproducible**: same input text → same routing decision → same SHA-256 hash, always
- **Explainable**: the `routing_rationale` field states in plain English exactly which features drove the verdict
- **Auditable**: the `audit_seal.sha256` field is a cryptographic commitment to the decision body
- **Offline**: zero network calls, zero GPU requirement, < 5 MB memory footprint

---

## Quick Start

```bash
pip install teia-cognitive-router   # or: copy src/ into your project
```

```python
from teia_cognitive_router import route_and_seal

# Compliance-safe mode (default since v1.2.0):
# Local only for entropy < 0.20 — provably trivial tasks, zero quality delta
sealed, json_str = route_and_seal("Extract all invoice numbers from this document")
print(sealed["routing_decision"])          # "Local"  (entropy < 0.20)
print(sealed["routing_mode"])              # "compliance_safe"
print(sealed["gpu_economics"]["delta_usd_saved"])  # 0.000440
print(sealed["audit_seal"]["sha256"])      # deterministic SHA-256

# Opt-in to max-savings mode (P43.0 behavior, allows Hybrid routing):
sealed, _ = route_and_seal("Analyze root cause of this failure", compliance_safe_mode=False)
print(sealed["routing_decision"])          # "Hybrid" or "Cloud"
print(sealed["routing_mode"])              # "max_savings"
```

```bash
# CLI — route and seal a prompt
python src/teia_cognitive_router.py --text "Analyze root cause of this distributed failure"
# → VERDICT: Cloud | entropy: 0.72 | SHA-256 audit seal attached

# Verify any stored routing decision is unmodified
python src/teia_audit_verifier.py --file routing_result.json
# → AUDIT PASS: The document seal is valid.

# Full determinism proof (for compliance officers)
python src/teia_audit_verifier.py --file routing_result.json --text "original prompt"
# → AUDIT PASS: The routing decision is mathematically proven and unmodified.
```

---

## How Routing Works

TEIA computes a **Semantic Entropy Score** [0..1] from six measurable text features:

| Feature | Weight | Description |
|---|:---:|---|
| Token score | 20% | Normalized prompt length |
| Vocabulary diversity | 15% | Unique token ratio |
| Reasoning verb density | 30% | Presence of analytical verbs (analyze, synthesize, evaluate…) |
| Data operation score | 15% | Simple extraction/formatting tasks (inverted — reduces score) |
| Structural complexity | 10% | Multi-part questions, numbered lists, nested conditions |
| Constraint density | 10% | Hard requirements, format specs, compliance constraints |

**Routing thresholds:**

| Score | Tier | Typical task |
|---|---|---|
| 0.00 – 0.35 | **Local** | Extraction, reformatting, translation, simple lookup |
| 0.35 – 0.65 | **Hybrid** | Code review, summarization, moderate reasoning |
| 0.65 – 1.00 | **Cloud** | Root cause analysis, architecture design, synthesis |

The formula and weights are **fixed at P40.0** and will never change without a version increment. Any change to weights produces a different version identifier.

---

## Drop-In Middleware

### vLLM / FastAPI

```python
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import httpx
from teia_cognitive_router import route, seal

app = FastAPI()

ENDPOINT_MAP = {
    "Local":  "http://localhost:8000/v1/chat/completions",
    "Hybrid": "http://localhost:8001/v1/chat/completions",
    "Cloud":  "https://api.openai.com/v1/chat/completions",
}

@app.post("/v1/chat/completions")
async def interceptor(request: Request):
    body        = await request.json()
    prompt_text = " ".join(
        m.get("content", "") for m in body.get("messages", [])
        if m.get("role") == "user"
    )
    routing  = seal(route(prompt_text))
    decision = routing["routing_decision"]

    headers = {k: v for k, v in request.headers.items() if k != "host"}
    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(ENDPOINT_MAP[decision], json=body, headers=headers)

    result = resp.json()
    result["teia_routing"] = {
        "decision":   decision,
        "entropy":    routing["semantic_entropy_score"],
        "audit_seal": routing["audit_seal"]["sha256"],
    }
    return JSONResponse(content=result, status_code=resp.status_code)
```

### LiteLLM Router

```python
from litellm import Router
from teia_cognitive_router import route

model_list = [
    {"model_name": "local-llm",  "litellm_params": {"model": "ollama/llama3"}},
    {"model_name": "hybrid-llm", "litellm_params": {"model": "ollama/mistral"}},
    {"model_name": "cloud-llm",  "litellm_params": {"model": "gpt-4o"}},
]
litellm_router = Router(model_list=model_list)

def route_and_complete(messages: list[dict]) -> str:
    prompt    = " ".join(m["content"] for m in messages if m["role"] == "user")
    decision  = route(prompt)["routing_decision"]
    model_map = {"Local": "local-llm", "Hybrid": "hybrid-llm", "Cloud": "cloud-llm"}
    return litellm_router.completion(model=model_map[decision], messages=messages)
```

### OpenAI SDK Wrapper

```python
import openai
from teia_cognitive_router import route, seal

LOCAL_MODEL  = "llama-3-8b-instruct"
HYBRID_MODEL = "mistral-22b-instruct-q4"
CLOUD_MODEL  = "gpt-4o"

def teia_complete(messages: list[dict], **kwargs):
    prompt_text = " ".join(m["content"] for m in messages if m.get("role") == "user")
    routing     = seal(route(prompt_text))
    decision    = routing["routing_decision"]

    model_map = {"Local": LOCAL_MODEL, "Hybrid": HYBRID_MODEL, "Cloud": CLOUD_MODEL}
    response  = openai.chat.completions.create(
        model=model_map[decision], messages=messages, **kwargs
    )
    response._routing_audit = {
        "decision":  decision,
        "entropy":   routing["semantic_entropy_score"],
        "audit_sha": routing["audit_seal"]["sha256"],
    }
    return response
```

### Kubernetes Sidecar

```yaml
- name: teia-cognitive-router
  image: python:3.11-slim
  command: ["python", "-m", "uvicorn", "teia_proxy:app", "--host", "0.0.0.0", "--port", "8080"]
  resources:
    requests:
      cpu: "50m"      # < 1 ms routing latency
      memory: "32Mi"
    limits:
      cpu: "200m"
      memory: "64Mi"
```

No GPU. No model download. No sidecar warmup time.

---

## Cryptographic Audit Verification

The audit verifier enables compliance officers to prove that any stored routing decision is mathematically reproducible and has not been tampered with — a requirement no ML-based router can meet.

```bash
# Mode 1 — Document integrity check
python src/teia_audit_verifier.py --file routing_result.json
# Strips the audit_seal, recomputes SHA-256 of canonical JSON body, compares.
# Exit code 0 = PASS, 1 = FAIL — integrates with CI/CD and compliance pipelines.

# Mode 2 — Full determinism proof
python src/teia_audit_verifier.py \
  --file routing_result.json \
  --text "Your original prompt text"
# Re-runs the full 6-axis entropy math from the original prompt.
# Proves: (a) document unmodified, (b) routing decision mathematically reproducible.
```

The verifier returns exit code `0` on PASS, `1` on FAIL.

---

## Performance

| Metric | Value |
|---|---|
| Routing latency | < 1 ms per prompt |
| Memory footprint | < 5 MB |
| CPU requirement | < 50 millicores |
| GPU requirement | **Zero** |
| Network calls | **Zero** |
| External dependencies | **Zero** (Python 3.8+ stdlib only) |
| Throughput | > 15,000 prompts / second |

---

## Benchmarks

100-prompt MT-Bench / AlpacaEval scale simulation (see `tests/run_quality_cost_benchmark.py`):

| Metric | Result |
|---|---|
| Prompts routed to Local | 50% |
| Prompts routed to Hybrid | 47% |
| Prompts routed to Cloud | 3% |
| GPU cost reduction vs 100% Cloud | 98.4% |
| Quality retention (deterministic model) | 73.8% |
| Throughput | 15,361 prompts / second |

Quality retention reflects the honest trade-off: routing High-complexity prompts to Hybrid achieves 55% quality vs Cloud. The `routing_confidence` field signals when quality trade-off is material.

---

## API Reference

```python
from teia_cognitive_router import route, seal, route_and_seal, to_canonical_json, generate_html_report
```

| Function | Returns | Description |
|---|---|---|
| `route(text)` | `dict` | Full routing result with all 6 feature scores |
| `seal(result)` | `dict` | Attaches SHA-256 audit seal to any routing dict |
| `route_and_seal(text)` | `(dict, str)` | Route + seal + canonical JSON string |
| `to_canonical_json(obj)` | `str` | Deterministic JSON (`sort_keys=True`, no whitespace) |
| `generate_html_report(chain_file, org)` | `str` | Self-contained HTML compliance report from JSONL chain |
| `enforce(routing_result, policy)` | `dict` | Apply policy rules; adds deterministic `policy_seal` |
| `enforce_chain(chain_file, policy)` | `list[dict]` | Batch-apply policy to JSONL audit chain |
| `load_policy(path_or_dict)` | `dict` | Load and validate a policy JSON |
| `validate_policy(policy)` | `list[str]` | Return list of validation errors (empty = valid) |

### Output Fields

| Field | Type | Description |
|---|---|---|
| `routing_decision` | string | `Local`, `Hybrid`, or `Cloud` |
| `semantic_entropy_score` | float | Composite score [0..1] |
| `routing_confidence` | string | `high`, `medium`, or `low` |
| `routing_rationale` | string | Human-readable justification |
| `entropy_features` | object | All 6 individual feature scores |
| `gpu_economics.delta_usd_saved` | float | USD saved vs routing everything to Cloud |
| `audit_seal.sha256` | string | SHA-256 of canonical JSON body |

---

## Regulatory Alignment

| Framework | TEIA Compliance Property |
|---|---|
| **EU AI Act** (High-Risk Systems) | Provides reproducible routing logs that support human oversight requirements |
| **GDPR / Right to Explanation** | `routing_rationale` provides human-readable justification for every decision |
| **SEC / FINRA** (Algorithmic Accountability) | SHA-256 audit seal enables exact reproduction of any past routing decision |
| **HIPAA** (Audit Controls) | No prompt text leaves the local process — supports data locality controls |
| **Basel III** (Model Risk) | Fixed heuristic formula has no model drift |

*Full regulatory compliance requires legal review for your specific deployment context.*

---

## Cryptographic Time Chain (v1.2.0+)

Every routing decision now carries a `time_anchor_hash` — a Merkle-style chain link that ties each audit entry to the one before it:

```
time_anchor_hash = SHA-256(prev_anchor + ":" + body_sha256)
```

The first entry in a new log uses `"GENESIS"` as `prev_anchor`. Modifying, deleting, or reordering any past entry breaks the chain at that position — mathematically detectable by any auditor.

```python
from teia_cognitive_router import route_and_seal

# First decision — genesis entry
sealed, _ = route_and_seal("Extract invoice numbers", prev_anchor="")
print(sealed["audit_seal"]["time_anchor_hash"])   # chain starts here
print(sealed["audit_seal"]["prev_anchor_sha256"]) # "GENESIS"

# Second decision — chained to first
sealed2, _ = route_and_seal(
    "Analyze root cause of the distributed failure",
    prev_anchor=sealed["audit_seal"]["time_anchor_hash"],
)
print(sealed2["audit_seal"]["prev_anchor_sha256"]) # == first time_anchor_hash
```

Verify any JSONL audit log from the gateway:

```bash
teia-verify --verify-chain --chain-file teia_gateway_audit.jsonl
# → AUDIT PASS: Temporal chain is intact and unbroken.
# → Every entry links to its predecessor — no deletions or modifications.
```

The `body sha256` field remains fully deterministic (same input → same hash). The `timestamp_utc` is per-invocation and is **not** deterministic by design — it is the observable event time. The `time_anchor_hash` is deterministic given the sequence: `SHA-256(prev:sha256)` is fixed.

This architecture is the foundation for [RFC 3161](https://www.rfc-editor.org/rfc/rfc3161) trusted timestamping integration — you can submit any `time_anchor_hash` to a TSA to obtain a legally-binding timestamp.

---

## Deterministic LLM Gateway (v1.2.0+)

A drop-in FastAPI proxy that intercepts every OpenAI-compatible request, applies the compliance-safe routing policy, and forwards to the appropriate endpoint — appending a SHA-256-sealed, time-chained entry to the GRC audit log per request.

```bash
pip install teia-cognitive-router[gateway]
teia-gateway                          # starts on http://127.0.0.1:8080
```

| Tier | Forwarded to |
|---|---|
| Local / Hybrid | `TEIA_LOCAL_ENDPOINT` (default: Ollama at `:11434`) |
| Cloud | `https://api.openai.com/v1/chat/completions` |

```bash
# Environment variables
export TEIA_LOCAL_ENDPOINT="http://localhost:11434/v1/chat/completions"
export OPENAI_API_KEY="sk-..."          # only needed for Cloud-tier requests
export TEIA_AUDIT_LOG="./audit.jsonl"  # SHA-256 sealed, time-chained JSONL log

teia-gateway --host 127.0.0.1 --port 8080
```

Every response includes a `teia_routing` field with the temporal chain anchor:

```json
{
  "teia_routing": {
    "decision": "Local",
    "entropy": 0.21,
    "delta_usd_saved": 0.000440,
    "audit_seal_sha256": "a3f8c1...",
    "time_anchor_hash": "b7e4d2..."
  }
}
```

---

## RFC 3161 Legal Notarization (v1.3.0+)

Close the retroactive forgery window by submitting any `time_anchor_hash` to a public Trusted Timestamp Authority (TSA). The TSA returns a signed `TimeStampResponse (.tsr)` — an externally-witnessed cryptographic proof that the hash existed at or before the certified time.

```bash
pip install teia-cognitive-router   # teia-notarize included

# Notarize the last anchor in your gateway audit log
teia-notarize --chain teia_gateway_audit.jsonl

# Or notarize any explicit SHA-256 hex
teia-notarize --hash <64-char-hex> --out notarized/

# Verify the TSR offline with OpenSSL (no internet required)
openssl ts -verify -in <file.tsr> -queryfile <file.tsq> -CAfile freetsa_ca.crt
```

Output files saved to `notarized/`:

| File | Contents |
|---|---|
| `<ts>_<hash16>.tsq` | Binary TimeStampRequest (sent to TSA) |
| `<ts>_<hash16>.tsr` | Binary TimeStampResponse — the legal proof |
| `<ts>_<hash16>.json` | Metadata: hash, TSA URL, SHA-256 of both files, compliance note |

**Three-layer proof**: SHA-256 body seal + Merkle chain + RFC 3161 TSR = an adversary must compromise both the audit log *and* a trusted third-party TSA to forge history.

Foundation for [RFC 3161](https://www.rfc-editor.org/rfc/rfc3161) / eIDAS Art. 41 qualified timestamps. Default TSA: FreeTSA.org (free, no account required). Override with `--tsa <url>`.

---

## Routing Policy Engine (v1.5.0+)

Enforce hard compliance rules **on top** of entropy-based routing. A policy overrides the entropy verdict when a business rule requires it — and every enforcement action is sealed with its own deterministic SHA-256.

```bash
pip install teia-cognitive-router==1.5.0

# Print the built-in example policy
teia-policy example > healthcare.json

# Validate a policy file
teia-policy validate --policy healthcare.json
# → POLICY VALID: 4 rule(s) — teia-example-policy v1.0

# Apply policy to a single routing result
teia-policy enforce --policy healthcare.json --input routing_result.json
# → POLICY ENFORCED — decision overridden
#   Rule     : HIPAA-001
#   Original : Cloud
#   Enforced : Local
#   Reason   : HIPAA-001: PHI data locality requirement

# Batch-apply policy to an entire audit chain
teia-policy enforce --policy healthcare.json --chain audit_chain.jsonl
# → Enforced 1200 entries  →  audit_chain.enforced.jsonl
#   Overridden : 47
#   Flagged    : 12
#   Unchanged  : 1141
```

### Policy JSON format

```json
{
  "name": "acme-hipaa-policy",
  "version": "1.0",
  "rules": [
    {
      "id":          "HIPAA-001",
      "description": "PHI data must never leave local infrastructure",
      "priority":    10,
      "if":          { "decision": "cloud" },
      "then":        { "force_decision": "local",
                       "add_flag":       "hipaa_enforced",
                       "override_reason": "HIPAA-001: PHI data locality" }
    },
    {
      "id":          "GDPR-DPO-001",
      "description": "High-entropy cloud decisions flagged for DPO review",
      "priority":    20,
      "if":          { "entropy_range": [0.85, 1.0], "decision": "cloud" },
      "then":        { "add_flag": "dpo_review_required",
                       "override_reason": "GDPR-DPO-001: high-entropy cloud flagged" }
    }
  ]
}
```

### Rule conditions (`if`)

| Key | Type | Description |
|---|---|---|
| `decision` | `"local"` / `"hybrid"` / `"cloud"` | Match specific routing tier |
| `entropy_range` | `[min, max]` | Entropy score range [0.0, 1.0] |
| `confidence` | `"high"` / `"medium"` / `"low"` | Routing confidence level |
| `always` | `true` | Catch-all — always matches |

### Rule actions (`then`)

| Key | Type | Description |
|---|---|---|
| `force_decision` | `"local"` / `"hybrid"` / `"cloud"` | Override the routing decision |
| `add_flag` | string | Add a compliance flag to the record |
| `override_reason` | string | Human-readable justification logged in `policy_seal` |

### Determinism guarantee

`policy_seal.sha256 = SHA-256(original_audit_sha256 + ":" + canonical(enforcement))`

The original `audit_seal` is **never modified** — it remains a valid proof of the original routing decision. The `policy_seal` is a second, independent layer:

```
SHA-256 body seal → audit_seal (original routing)
     ↓
Policy enforcement  → policy_seal (compliance override)
     ↓
RFC 3161 TSR        → external trusted timestamp
```

### Python API

```python
from teia_cognitive_router import route_and_seal, enforce, load_policy, EXAMPLE_POLICY
from pathlib import Path

# Use the built-in example or load your own
policy = load_policy(Path("acme-hipaa-policy.json"))

sealed, _ = route_and_seal("Summarize this patient diagnosis report")
enforced  = enforce(sealed, policy)

print(enforced["routing_decision"])          # "Local"  (overridden from "Cloud")
print(enforced["policy_seal"]["rule_applied"])  # "HIPAA-001"
print(enforced["policy_seal"]["sha256"])        # deterministic SHA-256
print(enforced["policy_seal"]["decision_changed"])  # True
```

---

## Compliance Report Generator (v1.4.0+)

Turn any TEIA JSONL audit chain into a self-contained HTML compliance report — no server, no install, printable to PDF directly from the browser.

```bash
teia-report audit_chain.jsonl
# → audit_chain.report.html (SHA-256 printed)
# Open in any browser, print to PDF for the auditor

teia-report audit_chain.jsonl --output quarterly_q2_2026.html --org "ACME Financial"
```

The report covers:

| Section | Content |
|---|---|
| **Chain integrity verdict** | CHAIN INTACT / CHAIN BROKEN banner with entry count |
| **Metrics grid** | Total decisions · Local/Cloud/Hybrid counts · avg entropy · tokens saved · seal coverage |
| **EU AI Act checklist** | Art. 12 (record-keeping, immutability) · Art. 13 (transparency, human oversight) · Annex IV §2/§5 |
| **GDPR Art. 22 checklist** | Automated decision-making · right to explanation · integrity · Art. 30 records |
| **SOC 2 CC7 checklist** | CC7.2 monitoring · CC7.3 incident detection · CC6.1 logical access |
| **Audit hash trail** | SHA-256 prefix · time anchor · prev anchor · timestamp per entry |

All checklist items show `PASS` when the audit seal is present and chain is intact. The HTML is fully self-contained — works from `file://` in all browsers.

```python
from teia_cognitive_router import generate_html_report
from pathlib import Path

html = generate_html_report(Path("audit_chain.jsonl"), organization="ACME Corp")
Path("report.html").write_text(html, encoding="utf-8")
```

---

## Repository Structure

```
teia-cognitive-router/
├── src/teia_cognitive_router/
│   ├── __init__.py     # Public API: route, seal, route_and_seal, generate_html_report
│   ├── _router.py      # Core 6-axis semantic entropy engine (stdlib only)
│   ├── _verifier.py    # Cryptographic audit verifier + temporal chain verification
│   ├── _gateway.py     # Deterministic LLM Gateway (requires [gateway] extra)
│   ├── _notary.py      # RFC 3161 TSA client — legal notarization (stdlib only)
│   ├── _reporter.py    # Compliance Report Generator — HTML/EU AI Act/GDPR/SOC 2 (stdlib only)
│   └── _policy.py      # Routing Policy Engine — hard compliance rules + policy_seal (stdlib only)
├── tests/
│   ├── run_quality_cost_benchmark.py
│   └── teia_router_bench_harness.py
└── docs/
    └── INTEGRATION_GUIDE.md
```

---

## Requirements

| Install | Dependencies |
|---|---|
| `pip install teia-cognitive-router` | Python 3.8+ stdlib only |
| `pip install teia-cognitive-router[gateway]` | + fastapi, uvicorn, httpx |

---

## License

Apache 2.0 — see LICENSE file.

---

*TEIA Cognitive Router v1.5.0 | Protocol P54.0 | 2026-06-03*
