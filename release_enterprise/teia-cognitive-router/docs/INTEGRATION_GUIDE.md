# TEIA Cognitive Router — Integration Guide
## Compliance-First LLM Routing for Regulated Environments

**Version:** 1.0 | **Date:** 2026-06-02

---

## Why Deterministic Heuristics Beat ML Routers in Regulated Environments

### The Compliance Problem with ML Routers

Modern AI routing systems use fine-tuned classifiers or embedding-based similarity models
to decide which prompts go to expensive frontier LLMs versus cheaper local models. While
these approaches achieve high benchmark accuracy, they create a fundamental conflict with
regulatory compliance requirements:

| Flaw | Impact in Finance / Healthcare |
|---|---|
| **Non-determinism** | Same input may produce different routing decisions across runs — audit reproduction is impossible |
| **Opacity** | Regulators cannot inspect neural network weights to verify a routing decision was correct |
| **Training data dependency** | Router behavior depends on training data that may be proprietary, expired, or contaminated |

### Why TEIA Supports Compliance Workflows

TEIA Cognitive Router computes routing decisions from **six measurable text features**
using a fixed arithmetic formula. Every decision is:

- **Reproducible**: identical input text → identical SHA-256 of the routing output
- **Explainable**: the `routing_rationale` field names exactly which features drove the verdict
- **Auditable**: the `audit_seal.sha256` field provides a cryptographic commitment to the decision
- **Stateless**: no training data, no model weights, no external dependencies

In environments where a compliance officer must reproduce a routing decision from 18 months
ago and explain it to a regulator in plain language, statistical accuracy is worthless
without determinism.

### Regulatory Alignment

| Framework | TEIA Compliance Property |
|---|---|
| **EU AI Act** (High-Risk Systems) | Provides reproducible routing logs that support human oversight requirements — compliance validation requires legal review |
| **GDPR / Right to Explanation** | `routing_rationale` provides human-readable justification for every decision — supports explainability audits |
| **SEC / FINRA** (Algorithmic Accountability) | SHA-256 audit seal enables exact reproduction of any past routing decision — supports audit trail requirements |
| **HIPAA** (Audit Controls) | No prompt text leaves the local process — supports data locality controls; full compliance requires broader system assessment |
| **Basel III** (Model Risk) | Fixed heuristic formula has no model drift — supports model stability requirements; regulatory applicability depends on deployment context |

---

## Integration Patterns

### Pattern 1: OpenAI API Drop-In Middleware

Insert routing before any `openai.chat.completions.create()` call:

```python
import openai
from teia_cognitive_router import route, seal

LOCAL_MODEL  = "llama-3-8b-instruct"    # vLLM local endpoint
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

### Pattern 2: vLLM / LiteLLM FastAPI Middleware

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
        "decision":    decision,
        "entropy":     routing["semantic_entropy_score"],
        "audit_seal":  routing["audit_seal"]["sha256"],
    }
    return JSONResponse(content=result, status_code=resp.status_code)
```

### Pattern 3: Kubernetes Sidecar Proxy

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ai-service-with-teia-router
spec:
  containers:
  - name: application
    image: your-app:latest
    env:
    - name: LLM_ENDPOINT
      value: "http://localhost:8080/v1/chat/completions"

  - name: teia-cognitive-router
    image: python:3.11-slim
    command: ["python", "-m", "uvicorn", "teia_proxy:app", "--host", "0.0.0.0", "--port", "8080"]
    resources:
      requests:
        cpu: "50m"       # < 1ms routing latency — negligible overhead
        memory: "32Mi"
      limits:
        cpu: "200m"
        memory: "64Mi"
```

No GPU required. No model downloads. The entire router is pure Python arithmetic.

### Pattern 4: LiteLLM Router Integration

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

---

## Library API Reference

```python
from teia_cognitive_router import route, seal, route_and_seal, to_canonical_json

# Route a prompt — returns full routing dict
result = route("Analyze root cause of this distributed system failure...")
print(result["routing_decision"])        # "Hybrid"
print(result["semantic_entropy_score"])  # 0.6014

# Route and attach SHA-256 audit seal
sealed, json_str = route_and_seal("Extract all email addresses from this text")
print(sealed["routing_decision"])       # "Local"
print(sealed["audit_seal"]["sha256"])   # "a3f8c1..."

# Canonical JSON — Write==Read invariant
json1 = to_canonical_json(route_and_seal("same prompt")[0])
json2 = to_canonical_json(route_and_seal("same prompt")[0])
assert json1 == json2  # always true
```

### Output JSON Fields

| Field | Type | Description |
|---|---|---|
| `routing_decision` | string | `Local`, `Hybrid`, or `Cloud` |
| `semantic_entropy_score` | float | Composite score [0..1] |
| `routing_confidence` | string | `high`, `medium`, or `low` |
| `routing_rationale` | string | Human-readable justification |
| `entropy_features` | object | All 6 individual feature scores |
| `feature_weights` | object | Model weights (fixed, P40.0) |
| `gpu_economics.delta_gpu_seconds_saved` | float | GPU-seconds saved vs Cloud |
| `gpu_economics.delta_usd_saved` | float | USD saved per prompt |
| `audit_seal.sha256` | string | SHA-256 of canonical JSON body |

---

## Performance Characteristics

| Metric | Value |
|---|---|
| Routing latency | < 1 ms per prompt |
| Memory footprint | < 5 MB (no model weights) |
| CPU requirement | < 50 millicores |
| GPU requirement | **Zero** |
| Network calls | **Zero** |
| External dependencies | **Zero** (Python 3.8+ stdlib only) |
| Throughput | > 15,000 prompts/second on entry-level hardware |

---

## Audit Verification

```bash
# Verify any stored routing decision has not been tampered with
python src/teia_audit_verifier.py --file routing_result.json

# Full determinism proof: re-run math from original prompt
python src/teia_audit_verifier.py \
  --file routing_result.json \
  --text "Your original prompt"
# → AUDIT PASS: The routing decision is mathematically proven and unmodified.
```

The verifier returns exit code `0` on PASS, `1` on FAIL — suitable for CI/CD pipelines
and automated compliance checks.
