#Requires -Version 7
# Run-CognitiveEconomicValidation.ps1 — TEIA P41.0 Empirical Dogfooding
# Le cognitive_prompts_real.json, submete cada prompt ao TEIA-Cognitive-Router.ps1,
# compara custo Baseline (100% Cloud) vs TEIA-Routed (apenas Cloud onde necessario).
# Output: tabela de vereditos + resumo de economia de GPU-segundos e USD.
# Idempotente: re-execucao produz mesmos resultados para mesmo corpus.
# Delta sempre por extenso.

[CmdletBinding()]
param(
    [string]$CorpusFile  = '',
    [string]$RouterScript = '',
    [string]$OutputJson  = '',
    [double]$GpuCostPerSecondUsd   = 0.002,
    [int]$CloudTokensPerSecond     = 50,
    [int]$LocalTokensPerSecond     = 5
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($scriptDir)) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }

if ([string]::IsNullOrEmpty($CorpusFile)) {
    $CorpusFile = Join-Path (Split-Path $scriptDir -Parent) 'benchmark_multidomain\cognitive_prompts_real.json'
}
if ([string]::IsNullOrEmpty($RouterScript)) {
    $RouterScript = Join-Path $scriptDir 'TEIA-Cognitive-Router.ps1'
}

foreach ($p in @($CorpusFile, $RouterScript)) {
    if (!(Test-Path $p)) { throw "Arquivo nao encontrado: $p" }
}

$prompts = Get-Content $CorpusFile -Raw -Encoding UTF8 | ConvertFrom-Json
if ($prompts.Count -eq 0) { throw "Corpus vazio: $CorpusFile" }

Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  TEIA P41.0 — Cognitive Economic Validation'                -ForegroundColor Cyan
Write-Host '  Dogfooding: Baseline Cloud vs TEIA-Routed'                 -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host "  Corpus  : $CorpusFile" -ForegroundColor White
Write-Host "  Tarefas : $($prompts.Count)" -ForegroundColor White
Write-Host "  Router  : $RouterScript" -ForegroundColor White
Write-Host ''

# ─── Processar cada prompt ────────────────────────────────────────────────────
$results = [System.Collections.Generic.List[pscustomobject]]::new()

foreach ($task in $prompts) {
    $jsonStr = & pwsh -NoProfile -ExecutionPolicy Bypass -File $RouterScript `
        -InputText $task.prompt `
        -GpuCostPerSecondUsd $GpuCostPerSecondUsd `
        -CloudTokensPerSecond $CloudTokensPerSecond `
        -LocalTokensPerSecond $LocalTokensPerSecond 2>$null

    $r = $jsonStr | ConvertFrom-Json

    $results.Add([pscustomobject]@{
        id                    = $task.id
        label                 = $task.label
        category              = $task.category
        expected_route        = $task.expected_route
        actual_route          = $r.routing_decision
        semantic_entropy      = $r.semantic_entropy_score
        confidence            = $r.routing_confidence
        token_estimate        = $r.input_token_estimate
        cloud_gpu_seconds     = $r.gpu_economics.cloud_gpu_seconds_estimate
        delta_gpu_seconds_saved = $r.gpu_economics.delta_gpu_seconds_saved
        delta_usd_saved       = $r.gpu_economics.delta_usd_saved
        route_match           = ($task.expected_route -eq $r.routing_decision)
    })
}

# ─── Calcular totais ─────────────────────────────────────────────────────────
$totalCloudGpu        = ($results | Measure-Object cloud_gpu_seconds     -Sum).Sum
$totalDeltaGpuSaved   = ($results | Measure-Object delta_gpu_seconds_saved -Sum).Sum
$totalDeltaUsdSaved   = ($results | Measure-Object delta_usd_saved        -Sum).Sum
$totalBaselineUsd     = [math]::Round($totalCloudGpu * $GpuCostPerSecondUsd, 6)
$totalRoutedUsd       = [math]::Round($totalBaselineUsd - $totalDeltaUsdSaved, 6)
$routeMatchCount      = ($results | Where-Object { $_.route_match }).Count
$routeAccuracyPct     = [math]::Round(100.0 * $routeMatchCount / $results.Count, 1)

$cloudCount  = ($results | Where-Object { $_.actual_route -eq 'Cloud'  }).Count
$hybridCount = ($results | Where-Object { $_.actual_route -eq 'Hybrid' }).Count
$localCount  = ($results | Where-Object { $_.actual_route -eq 'Local'  }).Count

# ─── Tabela de resultados ─────────────────────────────────────────────────────
Write-Host ('  {0,-5} {1,-32} {2,-8} {3,-8} {4,-8} {5,-10} {6}' -f `
    'ID','Tarefa','Entropia','Veredito','Esperado','DeltaUSD','Match') -ForegroundColor DarkGray
Write-Host ('  ' + ('-'*4) + ' ' + ('-'*31) + ' ' + ('-'*7) + ' ' + ('-'*7) + ' ' + ('-'*7) + ' ' + ('-'*9) + ' ' + ('-'*5)) -ForegroundColor DarkGray

foreach ($res in $results) {
    $rColor = switch ($res.actual_route) {
        'Local'  { 'Green'  }
        'Hybrid' { 'Yellow' }
        'Cloud'  { 'Red'    }
    }
    $matchStr   = if ($res.route_match) { 'OK' } else { 'MISS' }
    $matchColor = if ($res.route_match) { 'DarkGreen' } else { 'DarkYellow' }
    $labelShort = if ($res.label.Length -gt 31) { $res.label.Substring(0,28) + '...' } else { $res.label }

    Write-Host ('  {0,-5} {1,-32} {2,-8:F4}' -f $res.id, $labelShort, $res.semantic_entropy) -NoNewline -ForegroundColor White
    Write-Host ('{0,-8}' -f $res.actual_route) -NoNewline -ForegroundColor $rColor
    $expColor = switch ($res.expected_route) { 'Local' {'Green'} 'Hybrid' {'Yellow'} 'Cloud' {'Red'} }
    Write-Host ('{0,-8}' -f $res.expected_route) -NoNewline -ForegroundColor $expColor
    Write-Host ('{0,-10:F6}' -f $res.delta_usd_saved) -NoNewline -ForegroundColor Green
    Write-Host $matchStr -ForegroundColor $matchColor
}

# ─── Resumo economico ─────────────────────────────────────────────────────────
Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  RESUMO ECONOMICO — P41.0 Dogfooding'                       -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host ('  Distribuicao de roteamento:') -ForegroundColor White
Write-Host ("    Local  : {0,3} tarefas ({1:F0}%)" -f $localCount,  (100.0*$localCount/$results.Count))  -ForegroundColor Green
Write-Host ("    Hybrid : {0,3} tarefas ({1:F0}%)" -f $hybridCount, (100.0*$hybridCount/$results.Count)) -ForegroundColor Yellow
Write-Host ("    Cloud  : {0,3} tarefas ({1:F0}%)" -f $cloudCount,  (100.0*$cloudCount/$results.Count))  -ForegroundColor Red
Write-Host ''
Write-Host ('  Custo GPU (benchmark corpus):') -ForegroundColor White
Write-Host ("    Baseline  (100% Cloud) : {0:F3} GPU-s  = USD {1:F6}" -f $totalCloudGpu, $totalBaselineUsd)     -ForegroundColor Red
Write-Host ("    TEIA-Routed            : {0:F3} GPU-s  = USD {1:F6}" -f ($totalCloudGpu - $totalDeltaGpuSaved), $totalRoutedUsd) -ForegroundColor Cyan
Write-Host ("    Delta GPU-s poupados   : {0:F3} s"                   -f $totalDeltaGpuSaved)                   -ForegroundColor Green
Write-Host ("    Delta USD poupados     : USD {0:F6}"                  -f $totalDeltaUsdSaved)                   -ForegroundColor Green
Write-Host ''
$savingsPct = if ($totalBaselineUsd -gt 0) { [math]::Round(100.0 * $totalDeltaUsdSaved / $totalBaselineUsd, 1) } else { 0.0 }
Write-Host ("    Reducao de custo       : {0}% vs Baseline" -f $savingsPct)    -ForegroundColor Green
Write-Host ("    Acuracia de roteamento : {0}% ({1}/{2} corretos)" -f $routeAccuracyPct, $routeMatchCount, $results.Count) -ForegroundColor White
Write-Host ''

# Projecao mensal: assumindo 10.000 prompts/dia com distribuicao similar ao corpus
$scaleFactor       = 10000.0 / $results.Count
$monthlyDeltaUsd   = [math]::Round($totalDeltaUsdSaved * $scaleFactor * 30, 2)
$monthlyBaselineUsd = [math]::Round($totalBaselineUsd   * $scaleFactor * 30, 2)
Write-Host ('  Projecao mensal (10.000 prompts/dia, distribuicao similar):') -ForegroundColor White
Write-Host ("    Baseline mensal        : USD {0:F2}"  -f $monthlyBaselineUsd) -ForegroundColor Red
Write-Host ("    Delta mensal poupado   : USD {0:F2}"  -f $monthlyDeltaUsd)    -ForegroundColor Green
Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan

# ─── Construir JSON canonico de saida ─────────────────────────────────────────
$jsonResult = [ordered]@{
    validation_version       = '1.0'
    protocol                 = 'P41.0'
    corpus_file              = $CorpusFile.Replace('\','/')
    router_script            = $RouterScript.Replace('\','/')
    task_count               = $results.Count
    routing_distribution     = [ordered]@{
        local_count  = $localCount
        hybrid_count = $hybridCount
        cloud_count  = $cloudCount
    }
    economics = [ordered]@{
        baseline_cloud_gpu_seconds        = [math]::Round($totalCloudGpu, 3)
        baseline_cloud_usd                = $totalBaselineUsd
        teia_routed_gpu_seconds           = [math]::Round($totalCloudGpu - $totalDeltaGpuSaved, 3)
        teia_routed_usd                   = $totalRoutedUsd
        delta_gpu_seconds_saved           = [math]::Round($totalDeltaGpuSaved, 3)
        delta_usd_saved                   = [math]::Round($totalDeltaUsdSaved, 6)
        savings_pct                       = $savingsPct
        projected_monthly_delta_usd       = $monthlyDeltaUsd
        projected_monthly_baseline_usd    = $monthlyBaselineUsd
    }
    routing_accuracy_pct     = $routeAccuracyPct
    gpu_cost_per_second_usd  = $GpuCostPerSecondUsd
    tasks = @($results | ForEach-Object {
        [ordered]@{
            id                      = $_.id
            label                   = $_.label
            category                = $_.category
            expected_route          = $_.expected_route
            actual_route            = $_.actual_route
            semantic_entropy        = $_.semantic_entropy
            confidence              = $_.confidence
            token_estimate          = $_.token_estimate
            cloud_gpu_seconds       = $_.cloud_gpu_seconds
            delta_gpu_seconds_saved = $_.delta_gpu_seconds_saved
            delta_usd_saved         = $_.delta_usd_saved
            route_match             = $_.route_match
        }
    })
    calibration_note = 'Benchmark P41.0. Entropia Semantica heuristica. Delta por extenso.'
}

$jsonOut = $jsonResult | ConvertTo-Json -Depth 8

if ([string]::IsNullOrEmpty($OutputJson)) {
    $OutputJson = Join-Path (Split-Path $CorpusFile -Parent) 'cognitive_validation_results.json'
}

[System.IO.File]::WriteAllText($OutputJson, $jsonOut, [System.Text.Encoding]::UTF8)
$hash = (Get-FileHash $OutputJson -Algorithm SHA256).Hash.ToLower()
Write-Host "  JSON     : $OutputJson" -ForegroundColor White
Write-Host "  SHA-256  : $hash"       -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''

return $jsonResult
