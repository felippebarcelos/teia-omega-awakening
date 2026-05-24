# TEIA-Paradoxador-Auto.ps1 — Motor autônomo de detecção e log de paradoxos operacionais
# Varre o ambiente AION-RISPA e registra divergências como "paradoxos" auditáveis
# Saída: paradoxos_<timestamp>.json + resumo no stdout
param(
    [string]$Root       = $PSScriptRoot,
    [string]$SeedDir    = '',
    [string]$CASRoot    = '',
    [string]$OutDir     = '',
    [switch]$Verbose
)
$ErrorActionPreference = 'SilentlyContinue'
Set-Location $Root

$SeedDir = if ($SeedDir) { $SeedDir } else { Join-Path $Root 'seeds' }
$CASRoot  = if ($CASRoot) { $CASRoot } else { Join-Path $Root 'mem\obj' }
$OutDir   = if ($OutDir)  { $OutDir }  else { Join-Path $Root 'logs' }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$ts        = (Get-Date).ToString('yyyyMMdd_HHmmss')
$outFile   = Join-Path $OutDir "paradoxos_$ts.json"
$paradoxos = [System.Collections.Generic.List[object]]::new()

function Add-Paradox($id, $desc, $severity, $context) {
    $p = [ordered]@{
        id        = $id
        timestamp = (Get-Date).ToString('o')
        desc      = $desc
        severity  = $severity   # P0 | P1 | P2
        context   = $context
    }
    $paradoxos.Add($p)
    if ($Verbose) { Write-Host "[$severity] $id — $desc" }
}

# P1: Serviços AION esperados mas não rodando
$stateFile = Join-Path $Root 'aion_kernel.state.json'
if (Test-Path $stateFile) {
    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
    if ($state.http_job_id) {
        $job = Get-Job -Id $state.http_job_id -ErrorAction SilentlyContinue
        if (-not $job -or $job.State -notin 'Running','NotStarted') {
            Add-Paradox 'SVC_HTTP_DOWN' "HTTP Job #$($state.http_job_id) não está rodando (state=$($job.State))" 'P1' @{ job_id=$state.http_job_id; port=$state.port }
        }
    }
    if ($state.watcher_job_id) {
        $job = Get-Job -Id $state.watcher_job_id -ErrorAction SilentlyContinue
        if (-not $job -or $job.State -notin 'Running','NotStarted') {
            Add-Paradox 'SVC_WATCHER_DOWN' "Watcher Job #$($state.watcher_job_id) não está rodando" 'P1' @{ job_id=$state.watcher_job_id }
        }
    }
} else {
    Add-Paradox 'STATE_MISSING' 'aion_kernel.state.json ausente — PocketKernel nunca foi executado?' 'P2' @{ expected=$stateFile }
}

# P1: Seeds sem CAS blob correspondente
if (Test-Path $SeedDir) {
    $seedFiles = Get-ChildItem -Path $SeedDir -Filter '*.seed.json' -ErrorAction SilentlyContinue
    foreach ($sf in $seedFiles) {
        try {
            $seed = Get-Content $sf.FullName -Raw | ConvertFrom-Json
            # Verificar patch/payload no CAS se method=delta
            if ($seed.method -eq 'delta' -and $seed.source_hash) {
                $h    = $seed.source_hash.ToLower()
                $blob = Join-Path $CASRoot ($h.Substring(0,2)) ($h.Substring(2,2)) $h
                if (!(Test-Path $blob)) {
                    Add-Paradox "CAS_MISS_SOURCE_$($h.Substring(0,8))" `
                        "Seed $($sf.Name) aponta para source_hash que não está no CAS" 'P1' `
                        @{ seed=$sf.FullName; source_hash=$h; expected_blob=$blob }
                }
            }
            if ($seed.method -in 'delta','dict' -and $seed.patch_hash) {
                $h    = $seed.patch_hash.ToLower()
                $blob = Join-Path $CASRoot ($h.Substring(0,2)) ($h.Substring(2,2)) $h
                if (!(Test-Path $blob)) {
                    Add-Paradox "CAS_MISS_PATCH_$($h.Substring(0,8))" `
                        "Seed $($sf.Name) aponta para patch_hash que não está no CAS" 'P1' `
                        @{ seed=$sf.FullName; patch_hash=$h; expected_blob=$blob }
                }
            }
        } catch {
            Add-Paradox "SEED_PARSE_ERR_$($sf.Name)" "Falha ao parsear seed: $($_.Exception.Message)" 'P2' @{ file=$sf.FullName }
        }
    }
}

# P2: Fila de restauração não vazia há mais de 5 min (jobs travados)
$queueFile = if ($env:AION_QUEUE) { $env:AION_QUEUE } else { Join-Path $env:TEMP 'aion_restore_queue.jsonl' }
if (Test-Path $queueFile) {
    $qi = Get-Item $queueFile
    if ($qi.Length -gt 0 -and ((Get-Date) - $qi.LastWriteTime).TotalMinutes -gt 5) {
        Add-Paradox 'QUEUE_STALE' "Fila de restauração não vazia há >5min — watcher pode estar parado" 'P1' `
            @{ queue=$queueFile; size_bytes=$qi.Length; last_write=$qi.LastWriteTime.ToString('o') }
    }
}

# P2: Arquivos canônicos do AION ausentes na raiz
$canonical = @(
    'AION-RISPA-PocketKernel.ps1','AION-Local-Http.ps1','AION-Restore-Watcher.ps1',
    'AION-RISPA-HTTP.ps1','AION-RISPA-NDC-UniProc-v05.ps1','TEIA-OntoSeed-Gen.ps1'
)
foreach ($f in $canonical) {
    if (!(Get-ChildItem -Path $Root -Filter $f -Recurse -ErrorAction SilentlyContinue)) {
        Add-Paradox "FILE_ABSENT_$f" "Arquivo canônico AION ausente: $f" 'P2' @{ expected_path="$Root\$f" }
    }
}

# Saída
$report = [ordered]@{
    version       = 'paradoxador.v1'
    generated_utc = (Get-Date).ToUniversalTime().ToString('o')
    root          = $Root
    total         = $paradoxos.Count
    p0_count      = ($paradoxos | Where-Object { $_.severity -eq 'P0' }).Count
    p1_count      = ($paradoxos | Where-Object { $_.severity -eq 'P1' }).Count
    p2_count      = ($paradoxos | Where-Object { $_.severity -eq 'P2' }).Count
    paradoxos     = @($paradoxos)
}
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $outFile -Encoding utf8
Write-Host "[PARADOXADOR] Total=$($paradoxos.Count) P0=$($report.p0_count) P1=$($report.p1_count) P2=$($report.p2_count)"
Write-Host "[PARADOXADOR] Relatório: $outFile"
$report
