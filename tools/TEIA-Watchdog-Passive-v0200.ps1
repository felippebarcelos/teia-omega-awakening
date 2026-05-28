<#
.SYNOPSIS
    TEIA-Watchdog-Passive-v0200.ps1 — Sentinela Passivo de Ingestão

.DESCRIPTION
    Monitora um diretório, detecta arquivos novos (sem candidate.json),
    executa o NeuroPlanner para cada um e registra os resultados em JSONL.

    CONTRATO ABSOLUTO: nunca move, apaga ou grava no CAS.
    Apenas lê arquivos e produz .candidate.json + log de telemetria.

.PARAMETER WatchDir
    Diretório a monitorar. Padrão: D:\TEIA_USER\Inbox

.PARAMETER CandidatesRoot
    Pasta de candidates. Padrão: D:\TEIA_CORE\neuroplanner\candidates

.PARAMETER PlannerScript
    Script NeuroPlanner a invocar. Padrão: D:\TEIA_CORE\tools\TEIA-NeuroPlanner-v0199.ps1

.PARAMETER LogFile
    Log de telemetria JSONL. Padrão: D:\TEIA_CORE\logs\watchdog_passive.jsonl

.PARAMETER OllamaUrl
    Endpoint Ollama. Padrão: http://localhost:11434/api/generate

.PARAMETER Model
    Modelo LLM. Padrão: qwen2.5-coder:7b

.PARAMETER Recurse
    Varre subdiretórios recursivamente.

.EXAMPLE
    .\TEIA-Watchdog-Passive-v0200.ps1
    .\TEIA-Watchdog-Passive-v0200.ps1 -WatchDir "D:\TEIA_USER" -Recurse
    .\TEIA-Watchdog-Passive-v0200.ps1 -WatchDir "D:\TEIA_CLAUDE_AWAKENING\6_arquivos_teste"
#>
[CmdletBinding()]
param(
    [string]$WatchDir       = "D:\TEIA_USER\Inbox",
    [string]$CandidatesRoot = "D:\TEIA_CORE\neuroplanner\candidates",
    [string]$PlannerScript  = "D:\TEIA_CORE\tools\TEIA-NeuroPlanner-v0199.ps1",
    [string]$LogFile        = "D:\TEIA_CORE\logs\watchdog_passive.jsonl",
    [string]$OllamaUrl      = "http://localhost:11434/api/generate",
    [string]$Model          = "qwen2.5-coder:7b",
    [switch]$Recurse
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ── helper: SHA-256 leve (identidade de arquivo, sem análise pesada) ──────────

function Get-FileSha256([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLower()
}

# ── helper: escreve uma entrada JSONL no log ──────────────────────────────────

function Write-WatchdogLog {
    param([object]$Entry)
    $json = $Entry | ConvertTo-Json -Compress -Depth 6
    Add-Content -LiteralPath $LogFile -Value $json -Encoding UTF8
}

# ── init ──────────────────────────────────────────────────────────────────────

foreach ($dir in @([System.IO.Path]::GetDirectoryName($LogFile), $CandidatesRoot)) {
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

if (-not (Test-Path $WatchDir)) {
    Write-Host "[WD] ERRO: WatchDir não encontrado: $WatchDir" -ForegroundColor Red; exit 1
}
if (-not (Test-Path $PlannerScript)) {
    Write-Host "[WD] ERRO: PlannerScript não encontrado: $PlannerScript" -ForegroundColor Red; exit 1
}

$sessionId    = (Get-Date -Format 'yyyyMMddTHHmmss') + '_' + [System.Guid]::NewGuid().ToString('N').Substring(0,6)
$sessionStart = Get-Date
$newCount     = 0
$skipCount    = 0
$failCount    = 0

Write-Host @"
======================================================================
 [WD/SENTINELA_v0200] TEIA-Watchdog-Passive-v0200.ps1
 WatchDir : $WatchDir$(if ($Recurse) { ' [RECURSIVO]' } else { '' })
 Planner  : $(Split-Path $PlannerScript -Leaf)
 Log      : $LogFile
 Session  : $sessionId
======================================================================
"@ -ForegroundColor Cyan

Write-WatchdogLog ([ordered]@{
    timestamp  = (Get-Date -Format 'o')
    event      = 'session_start'
    session_id = $sessionId
    watch_dir  = $WatchDir
    recurse    = [bool]$Recurse
    planner    = $PlannerScript
})

# ── varredura de arquivos ─────────────────────────────────────────────────────

$gciArgs = @{ Path = $WatchDir; File = $true; ErrorAction = 'SilentlyContinue' }
if ($Recurse) { $gciArgs['Recurse'] = $true }
[object[]]$files = @(Get-ChildItem @gciArgs)

Write-Host " Arquivos encontrados: $($files.Count)" -ForegroundColor White
Write-Host ''

foreach ($file in $files) {
    $t0 = Get-Date

    # Pré-checagem por SHA-256 — operação leve, apenas identidade
    $sha256        = Get-FileSha256 -Path $file.FullName
    $candidatePath = Join-Path $CandidatesRoot "$sha256.candidate.json"

    if (Test-Path $candidatePath) {
        # Já processado — skip silencioso
        $skipCount++
        Write-Host ("[WD] SKIP  {0,-48} {1}" -f $file.Name, $sha256.Substring(0,16) + '...') -ForegroundColor DarkGray
        Write-WatchdogLog ([ordered]@{
            timestamp  = (Get-Date -Format 'o')
            event      = 'skipped'
            session_id = $sessionId
            file       = $file.FullName
            name       = $file.Name
            sha256     = $sha256
            size_bytes = $file.Length
            reason     = 'candidate_exists'
        })
        continue
    }

    # Arquivo novo — delegar análise completa ao NeuroPlanner
    $sizeLabel = "$([math]::Round($file.Length / 1KB, 1)) KB"
    Write-Host ("[WD] NEW   {0} ({1})" -f $file.Name, $sizeLabel) -ForegroundColor Yellow

    try {
        # Invocar o NeuroPlanner suprimindo sua saída verbosa
        # Telemetria capturada via candidate.json após execução
        $null = & $PlannerScript `
                    -Files     $file.FullName `
                    -OllamaUrl $OllamaUrl `
                    -Model     $Model `
                    *>&1

        $elapsed = [int]((Get-Date) - $t0).TotalMilliseconds

        if (Test-Path $candidatePath) {
            # Ler resultado para telemetria
            $c          = Get-Content -LiteralPath $candidatePath -Raw | ConvertFrom-Json
            $strategy   = [string]$c.final_strategy
            $ruleSource = [string]$c.hard_rule_decision.source
            $ruleId     = [string]$c.hard_rule_decision.rule_id
            $verdict    = [string]$c.planner_verdict
            $entropy    = [string]$c.metrics.entropy

            $ruleLabel = if ($ruleSource -eq 'hard_rule') { "[$ruleId]" } else { '[LLM]' }
            $color = switch ($strategy) {
                'gen.repeat'  { 'Green'  }
                'gen.pattern' { 'Green'  }
                'cas.raw'     { 'Gray'   }
                'cmp.brotli'  { 'Cyan'   }
                'cmp.lzma'    { 'Yellow' }
                default       { 'White'  }
            }
            Write-Host ("         → {0,-10} {1,-18} e={2}  {3}ms" -f `
                $ruleLabel, $strategy, $entropy, $elapsed) -ForegroundColor $color

            $newCount++
            Write-WatchdogLog ([ordered]@{
                timestamp       = (Get-Date -Format 'o')
                event           = 'candidate_generated'
                session_id      = $sessionId
                file            = $file.FullName
                name            = $file.Name
                sha256          = $sha256
                size_bytes      = $file.Length
                entropy         = [double]$c.metrics.entropy
                final_strategy  = $strategy
                rule_source     = $ruleSource
                rule_id         = $ruleId
                planner_verdict = $verdict
                elapsed_ms      = $elapsed
            })
        } else {
            throw "NeuroPlanner concluiu mas candidate não foi criado (SHA: $($sha256.Substring(0,16))...)"
        }

    } catch {
        $failCount++
        $errMsg = $_.Exception.Message
        Write-Host "         FALHA: $errMsg" -ForegroundColor Red
        Write-WatchdogLog ([ordered]@{
            timestamp  = (Get-Date -Format 'o')
            event      = 'error'
            session_id = $sessionId
            file       = $file.FullName
            name       = $file.Name
            sha256     = $sha256
            size_bytes = $file.Length
            error      = $errMsg
        })
    }
}

# ── sumário da sessão ─────────────────────────────────────────────────────────

$totalElapsed = [int]((Get-Date) - $sessionStart).TotalSeconds

Write-Host ''
Write-Host $('=' * 70) -ForegroundColor Cyan
Write-Host " SENTINELA — Sessão $sessionId" -ForegroundColor Cyan
Write-Host $('=' * 70)
Write-Host (" Arquivos : {0}  |  Novos : {1}  |  Skip : {2}  |  Fail : {3}  |  Tempo : {4}s" -f `
    $files.Count, $newCount, $skipCount, $failCount, $totalElapsed)
Write-Host " CAS      : intocado (zero writes em objects/)"
Write-Host " Log      : $LogFile"
Write-Host $('=' * 70)

Write-WatchdogLog ([ordered]@{
    timestamp     = (Get-Date -Format 'o')
    event         = 'session_end'
    session_id    = $sessionId
    total_files   = $files.Count
    new_count     = $newCount
    skip_count    = $skipCount
    fail_count    = $failCount
    elapsed_s     = $totalElapsed
})
