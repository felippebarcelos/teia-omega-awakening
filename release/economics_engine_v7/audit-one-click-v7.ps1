#Requires -Version 7
# audit-one-click-v7.ps1 — TEIA Information Economics Engine v7.0.0
# Demo P39.0: Preditor Heuristico N* vs Roteador Real (lado a lado)
#
#   [1/4] Gera Corpus30 alta entropia + baixa corpus transversal real
#   [2/4] Preditor N* (heuristico, sem compressao) — milissegundos
#   [3/4] Roteador Adaptativo (compressao real) — minutos
#   [4/4] Tabela comparativa: N* previsto vs N* medido + acuracia do modelo
#
# Pre-requisito: PowerShell 7+. Internet para corpus real.
# Delta sempre por extenso.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$workspace = $PSScriptRoot

Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  TEIA Information Economics Engine v7.0.0 — 1-Click Demo'   -ForegroundColor Cyan
Write-Host '  Preditor Heuristico N* vs Roteador Adaptativo Real'         -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan

# ─── Caminhos ────────────────────────────────────────────────────────────────
$motorPath     = Join-Path $workspace 'TEIA-AION-Transversal.ps1'
$routerPath    = Join-Path $workspace 'TEIA-Archive-Router.ps1'
$predictorPath = Join-Path $workspace 'TEIA-NStar-Predictor.ps1'
$fetchPath     = Join-Path $workspace 'Fetch-RealTransversalCorpus.ps1'

foreach ($p in @($motorPath, $routerPath, $predictorPath, $fetchPath)) {
    if (!(Test-Path $p)) { throw "Componente nao encontrado: $p" }
}

# ─── Inicializar Router em LibraryMode ───────────────────────────────────────
Write-Host ''
Write-Host 'Inicializando Router + C# JIT...' -ForegroundColor DarkGray
. $routerPath -MotorPath $motorPath -LibraryMode
Write-Host '  Pronto.' -ForegroundColor DarkGray

# ─── [1/4] Preparar corpora ───────────────────────────────────────────────────
Write-Host ''
Write-Host '[1/4] Preparando corpora...' -ForegroundColor Yellow

$corpus30Dir = Join-Path $workspace 'corpus_high_entropy'
$transDir    = Join-Path $workspace 'corpus_transversal'

Write-Host '  Corpus30 (alta entropia, N=30)...' -ForegroundColor DarkGray
New-Corpus30HighEntropy -OutputDir $corpus30Dir -N 30 -LinesPerFile 500

Write-Host '  Corpus Transversal (Apache CLF real, N>=10)...' -ForegroundColor DarkGray
& pwsh -NoProfile -ExecutionPolicy Bypass -File $fetchPath `
    -OutputDir $transDir -MinPartitions 10 | Out-Null
$transFiles = @(Get-ChildItem $transDir -Filter '*.csv' -ErrorAction SilentlyContinue)
if ($transFiles.Count -eq 0) { throw "Corpus Transversal vazio: $transDir" }
Write-Host "  Corpus Transversal: $($transFiles.Count) arquivos." -ForegroundColor DarkGreen

$corpora = @(
    [pscustomobject]@{ Label='Corpus30 (Alta Entropia)'; Dir=$corpus30Dir; HypN=10 }
    [pscustomobject]@{ Label='Apache CLF Real         '; Dir=$transDir;    HypN=15 }
)

# ─── [2/4] Preditor heuristico ───────────────────────────────────────────────
Write-Host ''
Write-Host '[2/4] Preditor Heuristico N* (sem compressao)...' -ForegroundColor Yellow

$predictions = [System.Collections.Generic.List[pscustomobject]]::new()
foreach ($c in $corpora) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $jsonStr = & pwsh -NoProfile -ExecutionPolicy Bypass -File $predictorPath `
                 -InputPath $c.Dir -SampleFiles 10 -SampleRows 500 2>$null
    $sw.Stop()
    $pred = $jsonStr | ConvertFrom-Json
    $predictions.Add([pscustomobject]@{
        Label     = $c.Label
        Dir       = $c.Dir
        NStarPred = $pred.prediction.n_star
        Decision  = $pred.prediction.decision
        DictDens  = $pred.dict_density_pct
        Confidence = $pred.prediction.n_star_confidence
        ElapsedMs = $sw.ElapsedMilliseconds
    })
    $color = switch ($pred.prediction.decision) { 'TEIA' {'Cyan'} 'Brotli' {'Green'} default {'DarkGray'} }
    Write-Host ("  {0}: N*={1,-6} decisao={2,-8} [{3}ms]" -f `
        $c.Label.Trim(), $pred.prediction.n_star, $pred.prediction.decision, $sw.ElapsedMilliseconds) `
        -ForegroundColor $color
}

# ─── [3/4] Roteador real (compressao Brotli SmallestSize) ────────────────────
Write-Host ''
Write-Host '[3/4] Roteador Adaptativo (compressao real, Balanced)...' -ForegroundColor Yellow

$routerResults = [System.Collections.Generic.List[pscustomobject]]::new()
foreach ($c in $corpora) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Host ("  {0}..." -f $c.Label.Trim()) -ForegroundColor DarkGray -NoNewline
    $r = Invoke-TeiaArchiveRouter -InputDir $c.Dir -Objective 'Balanced'
    $sw.Stop()
    $routerResults.Add([pscustomobject]@{
        Label     = $c.Label
        NStarReal = $r.NCritSizeVsBrotli
        Winner    = $r.Winner
        Score     = [math]::Round($r.Scores[$r.Winner], 3)
        ElapsedMs = $sw.ElapsedMilliseconds
    })
    $color = switch ($r.Winner) { 'TEIA' {'Cyan'} 'Brotli' {'Green'} default {'Yellow'} }
    Write-Host (" WINNER=$($r.Winner) N*=$($r.NCritSizeVsBrotli) [{0}s]" -f [int]($sw.ElapsedMilliseconds/1000)) -ForegroundColor $color
}

# ─── [4/4] Tabela comparativa ────────────────────────────────────────────────
Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  TABELA COMPARATIVA — Preditor vs Roteador Real'             -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host ('  {0,-28} {1,-10} {2,-10} {3,-8} {4,-10} {5}' -f `
    'Corpus','N* Pred.','N* Real','Erro%','Decisao','Confianca') -ForegroundColor DarkGray
Write-Host ('  ' + ('-'*27) + ' ' + ('-'*9) + ' ' + ('-'*9) + ' ' + ('-'*7) + ' ' + ('-'*9) + ' ' + ('-'*10)) -ForegroundColor DarkGray

for ($i = 0; $i -lt $predictions.Count; $i++) {
    $pred   = $predictions[$i]
    $router = $routerResults[$i]

    $nPred = if ($pred.NStarPred -match '^\d+$') { [int]$pred.NStarPred } else { $null }
    $nReal = if ($router.NStarReal -match '^\d+$') { [int]$router.NStarReal } else { $null }

    $erroPct = if ($nPred -and $nReal -and $nReal -gt 0) {
        '{0:F0}%' -f ([math]::Abs($nPred - $nReal) / $nReal * 100)
    } else { 'N/A' }

    $decColor = switch ($pred.Decision) { 'TEIA' {'Cyan'} 'Brotli' {'Green'} default {'DarkGray'} }
    Write-Host ('  {0,-28} {1,-10} {2,-10} {3,-8}' -f `
        $pred.Label.Trim(), $pred.NStarPred, $router.NStarReal, $erroPct) -NoNewline -ForegroundColor White
    Write-Host ('{0,-10}' -f $pred.Decision) -NoNewline -ForegroundColor $decColor
    Write-Host $pred.Confidence -ForegroundColor DarkGray
}

Write-Host ''
Write-Host '  Velocidade:' -ForegroundColor DarkGray
$totalPredMs   = ($predictions   | Measure-Object ElapsedMs -Sum).Sum
$totalRouterMs = ($routerResults | Measure-Object ElapsedMs -Sum).Sum
Write-Host ('    Preditor  : {0} ms total (heuristico, sem compressao)' -f $totalPredMs)   -ForegroundColor Cyan
Write-Host ('    Roteador  : {0} ms total (compressao Brotli real)'     -f $totalRouterMs) -ForegroundColor Yellow
$speedup = if ($totalPredMs -gt 0) { [int]($totalRouterMs / $totalPredMs) } else { 0 }
Write-Host ("    Speedup   : {0}x mais rapido (Preditor vs Roteador)" -f $speedup)         -ForegroundColor Green

Write-Host ''
Write-Host '  Calibracao do modelo (P36/P38):' -ForegroundColor DarkGray
Write-Host '    brotli_ratio  = 0.021 + 0.52 x mean_col_entropy'          -ForegroundColor DarkGray
Write-Host '    delta_ef.     = 0.040 + 0.050 x residual_entropy'         -ForegroundColor DarkGray
Write-Host '    delta_per_arq = brotli_per_arq x dict_dens x delta_ef.'   -ForegroundColor DarkGray
Write-Host '    N*            = ceil(overhead / delta_per_arq)'            -ForegroundColor DarkGray

Write-Host ''
Write-Host '  Honestidade Entropica:' -ForegroundColor White
Write-Host '    dict_density = 0%  -> PassThrough (incompressivel)' -ForegroundColor DarkGray
Write-Host '    N_atual < N*       -> Brotli/arquivo'                -ForegroundColor Green
Write-Host '    N_atual >= N*      -> TEIA (O(1) + economia de disco)'  -ForegroundColor Cyan

Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  TEIA Information Economics Engine v7.0.0 — Demo concluido' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
