#Requires -Version 7
# audit-one-click-v8.ps1 — TEIA Cognitive Router v8.0.0
# Demo P41.0: Validacao Economica de Roteamento Cognitivo
#
#   [1/3] Submete corpus de 12 tarefas reais ao Roteador Cognitivo P40.0
#   [2/3] Compara custo Baseline (100% Cloud) vs TEIA-Routed
#   [3/3] Exibe tabela + resumo de economia de GPU-segundos e USD
#
# Pre-requisito: PowerShell 7+. Sem chamadas de rede.
# Delta sempre por extenso.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$workspace = $PSScriptRoot

Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  TEIA Cognitive Router v8.0.0 — 1-Click Demo'              -ForegroundColor Cyan
Write-Host '  P41.0: Dogfooding de Economia de Inferencia de IA'        -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan

$repoRoot      = Split-Path (Split-Path $workspace -Parent) -Parent
$routerPath    = Join-Path $repoRoot 'tools\TEIA-Cognitive-Router.ps1'
$validatorPath = Join-Path $repoRoot 'tools\Run-CognitiveEconomicValidation.ps1'
$corpusPath    = Join-Path $repoRoot 'benchmark_multidomain\cognitive_prompts_real.json'

foreach ($p in @($routerPath, $validatorPath, $corpusPath)) {
    if (!(Test-Path $p)) { throw "Componente nao encontrado: $p" }
}

Write-Host ''
Write-Host 'Componentes verificados.' -ForegroundColor DarkGray
Write-Host ''
Write-Host '[1/3] Submetendo corpus ao Roteador Cognitivo P40.0...' -ForegroundColor Yellow
Write-Host ''

& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorPath `
    -CorpusFile $corpusPath `
    -RouterScript $routerPath

Write-Host ''
Write-Host '[2/3] Verificando idempotencia (segunda execucao)...' -ForegroundColor Yellow
$run1 = & pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorPath `
    -CorpusFile $corpusPath -RouterScript $routerPath 2>$null | Out-String
$run2 = & pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorPath `
    -CorpusFile $corpusPath -RouterScript $routerPath 2>$null | Out-String

$resultsFile = Join-Path (Split-Path $corpusPath -Parent) 'cognitive_validation_results.json'
$hash1 = (Get-FileHash $resultsFile -Algorithm SHA256).Hash.ToLower()
& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorPath `
    -CorpusFile $corpusPath -RouterScript $routerPath 2>$null | Out-Null
$hash2 = (Get-FileHash $resultsFile -Algorithm SHA256).Hash.ToLower()

if ($hash1 -eq $hash2) {
    Write-Host "  Write==Read: PASS — SHA-256 identico em duas execucoes" -ForegroundColor Green
    Write-Host "  Hash: $hash1" -ForegroundColor Cyan
} else {
    Write-Host "  Write==Read: FAIL — hashes divergentes!" -ForegroundColor Red
    Write-Host "  Run1: $hash1" -ForegroundColor Red
    Write-Host "  Run2: $hash2" -ForegroundColor Red
}

Write-Host ''
Write-Host '[3/3] Demo concluido.' -ForegroundColor Yellow
Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  TEIA Cognitive Router v8.0.0 — Prova Material'            -ForegroundColor Cyan
Write-Host '  docs\TEIA_P41_COGNITIVE_ECONOMICS_PROOF.md'               -ForegroundColor White
Write-Host '============================================================' -ForegroundColor Cyan
