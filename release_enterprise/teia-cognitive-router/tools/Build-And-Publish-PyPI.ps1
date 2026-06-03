<#
.SYNOPSIS
    Build wheel + sdist for teia-cognitive-router and optionally upload to PyPI.

.DESCRIPTION
    Idempotent build script for TEIA Cognitive Router P46.0.
    By default runs in dry-run mode — artifacts are built but NOT uploaded.
    Pass -DryRun:$false with TWINE_PASSWORD set to publish to PyPI.
    Delta always written in full — mathematical symbol prohibited.

.PARAMETER PackageRoot
    Root directory of the package (default: parent of this script).

.PARAMETER DryRun
    If true (default), build and check artifacts without uploading.
    Set to $false to upload. Requires TWINE_PASSWORD env var.

.EXAMPLE
    # Build only (dry-run)
    pwsh -ExecutionPolicy Bypass -File .\tools\Build-And-Publish-PyPI.ps1

    # Publish to PyPI
    $env:TWINE_PASSWORD = "pypi-YOURTOKEN..."
    pwsh -ExecutionPolicy Bypass -File .\tools\Build-And-Publish-PyPI.ps1 -DryRun:$false
#>

[CmdletBinding()]
param(
    [string]$PackageRoot = (Join-Path $PSScriptRoot ".."),
    [bool]$DryRun = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PackageRoot = (Resolve-Path $PackageRoot).Path
$distDir     = Join-Path $PackageRoot "dist"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TEIA Cognitive Router — PyPI Build   " -ForegroundColor Cyan
Write-Host "  P46.0 | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ── 1. Validate Python ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[1] Validating Python environment..." -ForegroundColor White

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Error "Python not found on PATH. Install Python 3.8+ and retry."
}
$pythonVersion = (python --version 2>&1).ToString()
Write-Host "    $pythonVersion" -ForegroundColor Green

# ── 2. Install/validate build tools ──────────────────────────────────────────
Write-Host ""
Write-Host "[2] Ensuring build tools (build, twine)..." -ForegroundColor White

$buildCheck = python -m build --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "    Installing 'build'..." -ForegroundColor Yellow
    python -m pip install --quiet build
}

$twineCheck = python -m twine --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "    Installing 'twine'..." -ForegroundColor Yellow
    python -m pip install --quiet twine
}

Write-Host "    build : $(python -m build --version 2>&1)" -ForegroundColor Green
Write-Host "    twine : $(python -m twine --version 2>&1)" -ForegroundColor Green

# ── 3. Clean dist/ ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3] Cleaning dist/..." -ForegroundColor White

if (Test-Path $distDir) {
    Remove-Item (Join-Path $distDir "*") -Recurse -Force
    Write-Host "    dist/ cleared." -ForegroundColor Green
} else {
    New-Item -ItemType Directory -Path $distDir | Out-Null
    Write-Host "    dist/ created." -ForegroundColor Green
}

# ── 4. Build wheel + sdist ────────────────────────────────────────────────────
Write-Host ""
Write-Host "[4] Building wheel and sdist..." -ForegroundColor White

Push-Location $PackageRoot
try {
    python -m build --outdir dist 2>&1 | ForEach-Object { Write-Host "    $_" }
    if ($LASTEXITCODE -ne 0) { Write-Error "Build failed." }
} finally {
    Pop-Location
}

$artifacts = Get-ChildItem $distDir -ErrorAction SilentlyContinue
if (-not $artifacts -or $artifacts.Count -eq 0) {
    Write-Error "Build produced no artifacts in dist/. Review output above."
}

Write-Host ""
Write-Host "    Artifacts:" -ForegroundColor Green
foreach ($a in $artifacts) {
    $hash = (Get-FileHash $a.FullName -Algorithm SHA256).Hash.ToLower()
    Write-Host "      $($a.Name)" -ForegroundColor Cyan
    Write-Host "      SHA-256: $hash" -ForegroundColor Gray
}

# ── 5. Twine check ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[5] Running twine check..." -ForegroundColor White

$twineCheckResult = python -m twine check (Join-Path $distDir "*") 2>&1
$twineCheckResult | ForEach-Object { Write-Host "    $_" }

if ($twineCheckResult -match "FAILED") {
    Write-Error "Twine check reported failures. Fix metadata before publishing."
}
Write-Host "    Twine check passed." -ForegroundColor Green

# ── 6. Publish or dry-run summary ────────────────────────────────────────────
Write-Host ""
Write-Host "[6] Publish step..." -ForegroundColor White

if ($DryRun) {
    Write-Host @"

    DRY-RUN MODE (default — no upload performed).
    Artifacts are ready in dist/ and have passed twine check.

    ── HOW TO PUBLISH TO PyPI ──────────────────────────────────────
    Step 1: Create an account at https://pypi.org/account/register/

    Step 2: Generate an API token:
            https://pypi.org/manage/account/token/
            Scope: "Entire account" for first upload, then project-scoped.

    Step 3: Set the token and run this script without -DryRun:
            `$env:TWINE_PASSWORD = "pypi-YOUR_TOKEN_HERE"
            pwsh -ExecutionPolicy Bypass -File .\tools\Build-And-Publish-PyPI.ps1 -DryRun:`$false

    After publication, users install with:
            pip install teia-cognitive-router
    ────────────────────────────────────────────────────────────────

"@ -ForegroundColor Yellow
} else {
    if (-not $env:TWINE_PASSWORD) {
        Write-Error "TWINE_PASSWORD is not set. Export your PyPI API token before running with -DryRun:`$false."
    }
    $env:TWINE_USERNAME = "__token__"
    Write-Host "    Uploading to PyPI..." -ForegroundColor Yellow
    python -m twine upload (Join-Path $distDir "*") 2>&1 | ForEach-Object { Write-Host "    $_" }
    if ($LASTEXITCODE -ne 0) { Write-Error "Twine upload failed." }
    Write-Host "    Published successfully." -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build complete." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
