#Requires -Version 7
# audit-one-click-router.ps1 — TEIA Adaptive Archive Router v6.0.0
# Auditoria completa em 1 clique:
#   [1/3] Gera Corpus30 alta entropia (N=30) + baixa Corpus Transversal real (N=10)
#   [2/3] Executa Router nas 6 permutacoes (2 corpora x 3 objetivos)
#   [3/3] Imprime tabela de decisao com projecoes N* (Massa Critica)
#
# Pre-requisito: PowerShell 7+ no Windows.
# Tempo estimado: ~2 minutos (6 forjas + medicoes reais de compressao).

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = "SilentlyContinue"
$workspace = $PSScriptRoot

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  TEIA Adaptive Archive Router v6.0.0 — 1-Click Audit"     -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# ─── Importar funcoes do Router (dot-source em LibraryMode) ──────────────────
$motorPath  = Join-Path $workspace "TEIA-AION-Transversal.ps1"
$routerPath = Join-Path $workspace "TEIA-Archive-Router.ps1"

if (!(Test-Path $motorPath))  { throw "Motor nao encontrado: $motorPath" }
if (!(Test-Path $routerPath)) { throw "Router nao encontrado: $routerPath" }

Write-Host ""
Write-Host "Inicializando Router + C# JIT..." -ForegroundColor DarkGray
. $routerPath -MotorPath $motorPath -LibraryMode
Write-Host "  Pronto." -ForegroundColor DarkGray

# ─── [1/3] Preparar corpora ───────────────────────────────────────────────────
Write-Host ""
Write-Host "[1/3] Preparando corpora..." -ForegroundColor Yellow

$corpus30Dir = Join-Path $workspace "corpus_high_entropy"
$transDir    = Join-Path $workspace "corpus_transversal"

Write-Host "  Corpus30 (alta entropia, N=30, 500 linhas/arq)..." -ForegroundColor DarkGray
New-Corpus30HighEntropy -OutputDir $corpus30Dir -N 30 -LinesPerFile 500

Write-Host "  Corpus Transversal (Apache CLF real, N>=10)..." -ForegroundColor DarkGray
& pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $workspace "Fetch-RealTransversalCorpus.ps1") `
    -OutputDir $transDir -MinPartitions 10 | Out-Null
$transFiles = @(Get-ChildItem $transDir -Filter "*.csv" -ErrorAction SilentlyContinue)
if ($transFiles.Count -eq 0) { throw "Corpus Transversal vazio em: $transDir" }
Write-Host "  Corpus Transversal: $($transFiles.Count) arquivos." -ForegroundColor DarkGreen

# ─── [2/3] Executar 6 permutacoes ────────────────────────────────────────────
Write-Host ""
Write-Host "[2/3] Executando 6 permutacoes (2 corpora x 3 objetivos)..." -ForegroundColor Yellow

$corpora = @(
    @{ Dir=$corpus30Dir; Label="Corpus30" ;     Short="C30 (N=30, AltaEnt.)" }
    @{ Dir=$transDir;    Label="Corpus_Trans";  Short="CLF (N=10, Real)    " }
)
$objectives = @("Size","Latency","Balanced")

$results = [System.Collections.Generic.List[pscustomobject]]::new()
$run = 0
foreach ($corpus in $corpora) {
    foreach ($obj in $objectives) {
        $run++
        Write-Host ("  [{0}/6] {1,-25} + {2,-8} ..." -f $run, $corpus.Label, $obj) `
            -ForegroundColor DarkGray -NoNewline
        $r = Invoke-TeiaArchiveRouter -InputDir $corpus.Dir -Objective $obj
        $color = switch ($r.Winner) { 'TEIA' {'Cyan'} 'Brotli' {'Green'} default {'Yellow'} }
        Write-Host (" WINNER: {0,-8} score={1:F3}" -f $r.Winner, $r.Scores[$r.Winner]) -ForegroundColor $color
        $results.Add([pscustomobject]@{
            CorpusShort = $corpus.Short
            Objective   = $obj
            Result      = $r
        })
    }
}

# ─── [3/3] Tabela de Decisao ─────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  TABELA DE DECISAO — Adaptive Archive Router v6.0.0"       -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Corpus                     Objetivo  Winner     Score   N* (TEIA vs Brotli/arq)" -ForegroundColor DarkGray
Write-Host ("  " + ("-"*26) + " " + ("-"*9) + " " + ("-"*10) + " " + ("-"*7) + " " + ("-"*26)) -ForegroundColor DarkGray

foreach ($row in $results) {
    $r       = $row.Result
    $winner  = $r.Winner
    $score   = "{0:F3}" -f $r.Scores[$winner]
    $nCrit   = $r.NCritSizeVsBrotli
    $nNote   = if ($nCrit -match '^\d+$') {
        $nc = [int]$nCrit
        if ($nc -le $r.N) { "N*=$nc [ATINGIDO]" } else { "N*=$nc (faltam $($nc - $r.N) arqs)" }
    } else {
        "N*=nunca (alta entropia)"
    }
    $color   = switch ($winner) { 'TEIA' {'Cyan'} 'Brotli' {'Green'} default {'Yellow'} }
    Write-Host ("  {0,-26} {1,-9} " -f $row.CorpusShort, $row.Objective) -NoNewline -ForegroundColor White
    Write-Host ("{0,-10}" -f $winner) -NoNewline -ForegroundColor $color
    Write-Host ("{0,-7} {1}" -f $score, $nNote) -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  Legenda:" -ForegroundColor DarkGray
Write-Host "    Score = 0 -> melhor | Score = 1 -> pior (normalizado por dimensao)" -ForegroundColor DarkGray
Write-Host "    N*    = N onde TEIA vence Brotli/arquivo em TAMANHO" -ForegroundColor DarkGray
Write-Host "    [ATINGIDO] = N atual >= N* (TEIA ja e menor que Brotli/arquivo)" -ForegroundColor DarkGray

Write-Host ""
Write-Host "  SABEDORIA DO SUPERVISOR:" -ForegroundColor White
Write-Host "    Objetivo=Size:     Concat+Brotli vence (LZ77 cross-file dominante)" -ForegroundColor Yellow
Write-Host "    Objetivo=Latency:  TEIA/Brotli vencem (ambos O(1) — Concat e O(N))" -ForegroundColor Cyan
Write-Host "    Objetivo=Balanced: TEIA vence para N grande; Brotli para N pequeno" -ForegroundColor Cyan
Write-Host "    Schemas distintos: TEIA nao se aplica — Brotli/Concat ganham" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  A TEIA nao e sempre o melhor formato." -ForegroundColor White
Write-Host "  A TEIA e o sistema que descobre qual formato deve vencer." -ForegroundColor Cyan
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  TEIA Adaptive Archive Router v6.0.0 — Auditoria concluida" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
