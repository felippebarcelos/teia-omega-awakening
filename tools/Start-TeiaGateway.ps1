<#
.SYNOPSIS
    Starts the TEIA Ouroboros Gateway on http://127.0.0.1:8080.

.DESCRIPTION
    Idempotent launcher for teia_local_gateway.py (P47.0).
    Uses the official teia-cognitive-router PyPI package.
    Routes Local/Hybrid prompts to the local LLM endpoint and
    Cloud prompts to the OpenAI API.

.PARAMETER LocalEndpoint
    Local LLM URL (Ollama / LM Studio / GPT4All).
    Default: http://localhost:11434/v1/chat/completions

.PARAMETER Port
    Gateway port. Default: 8080.

.PARAMETER OpenAIKey
    OpenAI API key for Cloud-tier forwarding. Can also be set via
    the OPENAI_API_KEY environment variable.

.EXAMPLE
    # Ollama on default port
    pwsh -ExecutionPolicy Bypass -File .\tools\Start-TeiaGateway.ps1

    # LM Studio on port 1234 with OpenAI fallback
    pwsh -ExecutionPolicy Bypass -File .\tools\Start-TeiaGateway.ps1 `
        -LocalEndpoint "http://localhost:1234/v1/chat/completions" `
        -OpenAIKey "sk-..."

.NOTES
    Point your clients to: http://127.0.0.1:8080/v1/chat/completions
    Audit log written to:  tools\teia_gateway_audit.jsonl
#>

[CmdletBinding()]
param(
    [string]$LocalEndpoint = "http://localhost:11434/v1/chat/completions",
    [int]$Port             = 8080,
    [string]$OpenAIKey     = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Validate Python ───────────────────────────────────────────────────────────
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python not found on PATH. Install Python 3.8+ and retry."
}

# ── Validate teia-cognitive-router is installed ───────────────────────────────
$pkgCheck = python -c "import teia_cognitive_router; print(teia_cognitive_router.__version__)" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing teia-cognitive-router from PyPI..." -ForegroundColor Yellow
    python -m pip install teia-cognitive-router fastapi uvicorn httpx
}

Write-Host ""
Write-Host "  teia-cognitive-router $pkgCheck" -ForegroundColor Cyan

# ── Set environment variables ─────────────────────────────────────────────────
$env:TEIA_LOCAL_ENDPOINT = $LocalEndpoint
if ($OpenAIKey) { $env:OPENAI_API_KEY = $OpenAIKey }

# ── Launch uvicorn ────────────────────────────────────────────────────────────
$gatewayScript = Join-Path $PSScriptRoot "teia_local_gateway.py"
if (-not (Test-Path $gatewayScript)) {
    Write-Error "Gateway script not found: $gatewayScript"
}

Set-Location $PSScriptRoot

Write-Host ""
Write-Host "  Starting TEIA Ouroboros Gateway on port $Port..." -ForegroundColor Cyan
Write-Host "  Local endpoint : $LocalEndpoint" -ForegroundColor White
Write-Host "  Press Ctrl+C to stop." -ForegroundColor Gray
Write-Host ""

python -m uvicorn teia_local_gateway:app --host 127.0.0.1 --port $Port
