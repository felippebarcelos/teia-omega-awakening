"""
_gateway.py — TEIA P47.0 Ouroboros Gateway
FastAPI proxy that routes every OpenAI-compatible request through the
teia-cognitive-router entropy engine, then forwards to the appropriate
LLM endpoint. Logs every decision with SHA-256 audit seal to JSONL.

Install with gateway extras:
  pip install teia-cognitive-router[gateway]

Run:
  teia-gateway                                    # default: 127.0.0.1:8080
  teia-gateway --host 0.0.0.0 --port 9090

Environment variables:
  TEIA_LOCAL_ENDPOINT   Local LLM URL   (default: http://localhost:11434/v1/chat/completions)
  OPENAI_API_KEY        OpenAI key      (required only for Cloud-tier requests)
  TEIA_AUDIT_LOG        Audit log path  (default: ./teia_gateway_audit.jsonl)
  TEIA_CLOUD_MODEL      Model override when routing to Cloud (default: gpt-4o)

Write==Read invariant. Delta always written in full.
"""

from __future__ import annotations

import json
import logging
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

# ── Gateway dependencies (installed via [gateway] extra) ──────────────────────
try:
    import httpx
    from fastapi import FastAPI, HTTPException, Request
    from fastapi.responses import JSONResponse
except ImportError:
    print("ERROR: gateway dependencies not installed.")
    print("  Run: pip install teia-cognitive-router[gateway]")
    sys.exit(1)

from ._router import route_and_seal

# ── Configuration ─────────────────────────────────────────────────────────────

LOCAL_ENDPOINT: str = os.getenv(
    "TEIA_LOCAL_ENDPOINT",
    "http://localhost:11434/v1/chat/completions",
)
CLOUD_ENDPOINT:  str = "https://api.openai.com/v1/chat/completions"
OPENAI_API_KEY:  str = os.getenv("OPENAI_API_KEY", "")
CLOUD_MODEL:     str = os.getenv("TEIA_CLOUD_MODEL", "gpt-4o")

_AUDIT_LOG_DEFAULT = str(Path.cwd() / "teia_gateway_audit.jsonl")
AUDIT_LOG: Path = Path(os.getenv("TEIA_AUDIT_LOG", _AUDIT_LOG_DEFAULT))

# ── Logging ───────────────────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [TEIA] %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
log = logging.getLogger("teia_gateway")

# ── FastAPI app ───────────────────────────────────────────────────────────────

app = FastAPI(
    title="TEIA Ouroboros Gateway",
    description=(
        "Compliance-first LLM proxy. Routes prompts via semantic entropy. "
        "Every decision is logged with a SHA-256 audit seal."
    ),
    version="1.1.0",
)


# ── Helpers ───────────────────────────────────────────────────────────────────

def _extract_prompt(body: dict[str, Any]) -> str:
    messages = body.get("messages", [])
    return " ".join(
        m.get("content", "") for m in messages if m.get("role") == "user"
    ).strip()


def _append_audit(entry: dict[str, Any]) -> None:
    try:
        AUDIT_LOG.parent.mkdir(parents=True, exist_ok=True)
        with AUDIT_LOG.open("a", encoding="utf-8") as fh:
            fh.write(
                json.dumps(entry, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
                + "\n"
            )
    except OSError as exc:
        log.warning("Audit log write failed: %s", exc)


# ── Routes ────────────────────────────────────────────────────────────────────

@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok", "gateway": "teia-ouroboros", "version": "1.1.0"}


@app.post("/v1/chat/completions")
async def completions(request: Request) -> JSONResponse:
    try:
        body: dict[str, Any] = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON body.")

    prompt_text = _extract_prompt(body)
    if not prompt_text:
        prompt_text = json.dumps(body.get("messages", []))

    # ── Route ─────────────────────────────────────────────────────────────────
    sealed, _ = route_and_seal(prompt_text)
    decision   = sealed["routing_decision"]
    entropy    = sealed["semantic_entropy_score"]
    confidence = sealed["routing_confidence"]
    rationale  = sealed["routing_rationale"]
    delta_usd  = sealed["gpu_economics"]["delta_usd_saved"]
    audit_sha  = sealed["audit_seal"]["sha256"]

    # ── Select target ─────────────────────────────────────────────────────────
    forward_headers: dict[str, str] = {
        k: v for k, v in request.headers.items()
        if k.lower() not in ("host", "content-length", "authorization")
    }

    if decision in ("Local", "Hybrid"):
        target = LOCAL_ENDPOINT
        log.info("ROUTE %-6s | entropy=%.4f | %s | delta=USD %.6f → LOCAL",
                 decision, entropy, confidence, delta_usd)
    else:
        target = CLOUD_ENDPOINT
        if not OPENAI_API_KEY:
            log.warning("Cloud tier selected but OPENAI_API_KEY is not set.")
        else:
            forward_headers["authorization"] = f"Bearer {OPENAI_API_KEY}"
        if "model" not in body:
            body["model"] = CLOUD_MODEL
        log.info("ROUTE %-6s | entropy=%.4f | %s | delta=USD 0.000000 → CLOUD",
                 decision, entropy, confidence)

    # ── Forward ───────────────────────────────────────────────────────────────
    status_code = 502
    result:    dict[str, Any] = {}
    error_msg: str = ""

    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            resp = await client.post(target, json=body, headers=forward_headers)
        status_code = resp.status_code
        try:
            result = resp.json()
        except Exception:
            result = {"raw_response": resp.text}
    except httpx.ConnectError as exc:
        error_msg = f"Cannot reach {target}: {exc}"
        log.error(error_msg)
        result = {"error": {"message": error_msg, "type": "gateway_connect_error"}}
        status_code = 502
    except httpx.TimeoutException as exc:
        error_msg = f"Timeout reaching {target}: {exc}"
        log.error(error_msg)
        result = {"error": {"message": error_msg, "type": "gateway_timeout"}}
        status_code = 504

    # ── Inject routing metadata ───────────────────────────────────────────────
    result["teia_routing"] = {
        "decision":          decision,
        "entropy":           entropy,
        "confidence":        confidence,
        "rationale":         rationale,
        "delta_usd_saved":   delta_usd,
        "audit_seal_sha256": audit_sha,
        "target_endpoint":   target,
    }

    # ── Audit log ─────────────────────────────────────────────────────────────
    _append_audit({
        "timestamp":          datetime.now(timezone.utc).isoformat(),
        "routing_decision":   decision,
        "semantic_entropy":   entropy,
        "routing_confidence": confidence,
        "delta_usd_saved":    delta_usd,
        "audit_seal_sha256":  audit_sha,
        "target_endpoint":    target,
        "response_status":    status_code,
        "error":              error_msg or None,
    })

    return JSONResponse(content=result, status_code=status_code)


# ── Startup banner ────────────────────────────────────────────────────────────

@app.on_event("startup")
async def _startup_banner() -> None:
    print("")
    print("\033[36m" + "=" * 60 + "\033[0m")
    print("\033[36m  TEIA Ouroboros Gateway — P47.0 (v1.1.0)\033[0m")
    print(f"  Endpoint   : http://127.0.0.1:8080/v1/chat/completions")
    print(f"  Local LLM  : {LOCAL_ENDPOINT}")
    print(f"  Cloud API  : {CLOUD_ENDPOINT}")
    print(f"  Cloud key  : {'SET' if OPENAI_API_KEY else 'NOT SET (Cloud tier will fail)'}")
    print(f"  Audit log  : {AUDIT_LOG}")
    print("\033[36m" + "=" * 60 + "\033[0m")
    print("")


# ── CLI entry point ───────────────────────────────────────────────────────────

def _cli() -> None:
    import argparse
    import uvicorn

    parser = argparse.ArgumentParser(
        description="TEIA Ouroboros Gateway — compliance-first LLM proxy"
    )
    parser.add_argument("--host", default="127.0.0.1", help="Bind host (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=8080, help="Bind port (default: 8080)")
    args = parser.parse_args()

    uvicorn.run(app, host=args.host, port=args.port)


if __name__ == "__main__":
    _cli()
