# AION-RISPA-AuditOrchestrator.ps1 — Orquestrador de auditoria AION-RISPA-NDC
# Ciclo: inicia serviços → roda paradoxador → verifica seeds → gera dossiê JSON
# Uso: .\AION-RISPA-AuditOrchestrator.ps1 [-SkipBoot] [-SkipParadoxador] [-OutDir .\logs]
param(
    [string]$Root             = $PSScriptRoot,
    [string]$OutDir           = '',
    [switch]$SkipBoot,
    [switch]$SkipParadoxador,
    [switch]$SkipSeedAudit,
    [int]$HttpPort            = 8123
)
$ErrorActionPreference = 'SilentlyContinue'
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-Location $Root

$OutDir   = if ($OutDir) { $OutDir } else { Join-Path $Root 'logs' }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$ts       = (Get-Date).ToString('yyyyMMdd_HHmmss')
$dossieF  = Join-Path $OutDir "dossie_audit_$ts.json"
$logF     = Join-Path $OutDir "orchestrator_$ts.log"

function Write-O($m) {
    $line = "$((Get-Date).ToString('s'))`t$m"
    Add-Content -LiteralPath $logF -Value $line -Encoding utf8
    Write-Host $line
}

$dossie = [ordered]@{
    version          = 'aion.audit.v1'
    generated_utc    = (Get-Date).ToUniversalTime().ToString('o')
    root             = $Root
    phases           = [ordered]@{}
}

# ── FASE 1: Boot ────────────────────────────────────────────
if (-not $SkipBoot) {
    Write-O "[FASE1] Iniciando PocketKernel ..."
    $pocketKernel = Join-Path $Root 'AION-RISPA-PocketKernel.ps1'
    if (Test-Path $pocketKernel) {
        try {
            $state = & $pocketKernel -Port $HttpPort -Root $Root
            $dossie.phases['boot'] = @{ status='ok'; http_job=$state.http_job_id; watcher_job=$state.watcher_job_id; port=$HttpPort }
            Write-O "[FASE1] OK — HTTP Job #$($state.http_job_id)"
        } catch {
            $dossie.phases['boot'] = @{ status='error'; error=$_.Exception.Message }
            Write-O "[FASE1] ERRO: $($_.Exception.Message)"
        }
    } else {
        $dossie.phases['boot'] = @{ status='skip'; reason='PocketKernel.ps1 ausente' }
        Write-O "[FASE1] SKIP — PocketKernel.ps1 não encontrado"
    }
    Start-Sleep -Seconds 1
} else {
    $dossie.phases['boot'] = @{ status='skip'; reason='-SkipBoot' }
    Write-O "[FASE1] SKIP (parâmetro -SkipBoot)"
}

# ── FASE 2: Health Check HTTP ────────────────────────────────
Write-O "[FASE2] Health check em :$HttpPort ..."
try {
    $resp = Invoke-RestMethod "http://127.0.0.1:$HttpPort/health" -TimeoutSec 4
    $dossie.phases['health'] = @{ status='ok'; watcher_state=$resp.watcher_state; queue_size=$resp.queue_size }
    Write-O "[FASE2] OK — watcher_state=$($resp.watcher_state)"
} catch {
    $dossie.phases['health'] = @{ status='unreachable'; error=$_.Exception.Message }
    Write-O "[FASE2] WARN — HTTP não respondeu: $($_.Exception.Message)"
}

# ── FASE 3: Métricas ─────────────────────────────────────────
try {
    $met = Invoke-RestMethod "http://127.0.0.1:$HttpPort/metrics" -TimeoutSec 4
    $dossie.phases['metrics'] = @{ status='ok'; ok=$met.ok; err=$met.err }
    Write-O "[FASE3] Métricas OK=$($met.ok) ERR=$($met.err)"
} catch {
    $dossie.phases['metrics'] = @{ status='skip'; reason='HTTP indisponível' }
    Write-O "[FASE3] SKIP — HTTP indisponível"
}

# ── FASE 4: Paradoxador ──────────────────────────────────────
if (-not $SkipParadoxador) {
    Write-O "[FASE4] Executando Paradoxador ..."
    $paradoxScript = Join-Path $Root 'TEIA-Paradoxador-Auto.ps1'
    if (Test-Path $paradoxScript) {
        try {
            $pr = & $paradoxScript -Root $Root -OutDir $OutDir
            $dossie.phases['paradoxador'] = @{
                status    = 'ok'
                total     = $pr.total
                p0_count  = $pr.p0_count
                p1_count  = $pr.p1_count
                p2_count  = $pr.p2_count
            }
            Write-O "[FASE4] Paradoxador OK — total=$($pr.total)"
        } catch {
            $dossie.phases['paradoxador'] = @{ status='error'; error=$_.Exception.Message }
            Write-O "[FASE4] ERRO: $($_.Exception.Message)"
        }
    } else {
        $dossie.phases['paradoxador'] = @{ status='skip'; reason='TEIA-Paradoxador-Auto.ps1 ausente' }
        Write-O "[FASE4] SKIP — script ausente"
    }
} else {
    $dossie.phases['paradoxador'] = @{ status='skip'; reason='-SkipParadoxador' }
}

# ── FASE 5: Auditoria de Seeds ───────────────────────────────
if (-not $SkipSeedAudit) {
    Write-O "[FASE5] Auditando seeds ..."
    $seedDir   = Join-Path $Root 'seeds'
    $seedFiles = if (Test-Path $seedDir) { Get-ChildItem $seedDir -Filter '*.seed.json' -ErrorAction SilentlyContinue } else { @() }
    $seedAudit = @{ total=0; valid=0; invalid=0; errors=@() }
    foreach ($sf in $seedFiles) {
        $seedAudit.total++
        try {
            $s = Get-Content $sf.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
            $req = @('version','target_hash','method')
            $missing = $req | Where-Object { -not $s.$_ }
            if ($missing) { throw "Campos obrigatórios ausentes: $($missing -join ', ')" }
            $seedAudit.valid++
        } catch {
            $seedAudit.invalid++
            $seedAudit.errors += @{ file=$sf.Name; error=$_.Exception.Message }
        }
    }
    $dossie.phases['seed_audit'] = @{ status='ok'; total=$seedAudit.total; valid=$seedAudit.valid; invalid=$seedAudit.invalid }
    Write-O "[FASE5] Seeds total=$($seedAudit.total) válidas=$($seedAudit.valid) inválidas=$($seedAudit.invalid)"
} else {
    $dossie.phases['seed_audit'] = @{ status='skip'; reason='-SkipSeedAudit' }
}

# ── FASE 6: Inventário de arquivos canônicos ─────────────────
Write-O "[FASE6] Inventário canônico ..."
$canonical = @(
    'AION-RISPA-PocketKernel.ps1','AION-RISPA-NDC-UniProc-v05.ps1','NDC_core.bin',
    'TEIA-OntoSeed-Gen.ps1','TEIA-Paradoxador-Auto.ps1',
    'AION-RISPA-HTTP.ps1','AION-Local-Http.ps1','AION-Restore-Watcher.ps1',
    'index30.html','AION-RISPA-NDC.html','Patch-Index30-For-AION.ps1','teia-delta-panel.js',
    '00-AION-Migrate.ps1','AION-RISPA-AuditOrchestrator.ps1'
)
$inventory = @{ present=@(); absent=@() }
foreach ($f in $canonical) {
    $found = Get-ChildItem -Path $Root -Filter $f -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $h = (Get-FileHash $found.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        $inventory.present += @{ name=$f; path=$found.FullName; sha256=$h; size=$found.Length }
    } else {
        $inventory.absent += $f
    }
}
$dossie.phases['inventory'] = @{
    status      = if ($inventory.absent.Count -eq 0) { 'ok' } else { 'partial' }
    present     = $inventory.present.Count
    absent      = $inventory.absent.Count
    absent_list = $inventory.absent
}
Write-O "[FASE6] Presentes=$($inventory.present.Count) Ausentes=$($inventory.absent.Count)"

# ── Dossiê final ─────────────────────────────────────────────
$dossie['summary'] = @{
    total_phases   = $dossie.phases.Keys.Count
    phases_ok      = ($dossie.phases.Values | Where-Object { $_.status -eq 'ok' }).Count
    phases_warn    = ($dossie.phases.Values | Where-Object { $_.status -in 'partial','unreachable' }).Count
    phases_error   = ($dossie.phases.Values | Where-Object { $_.status -eq 'error' }).Count
}

$dossie | ConvertTo-Json -Depth 8 | Set-Content -Path $dossieF -Encoding utf8
Write-O "[ORQUESTRADOR] Dossiê gerado: $dossieF"
Write-O "[ORQUESTRADOR] OK=$($dossie.summary.phases_ok) WARN=$($dossie.summary.phases_warn) ERR=$($dossie.summary.phases_error)"

$dossie
