<#
.SYNOPSIS
    TEIA-Run-PassiveDaily.ps1 — Wrapper de Rotina Passiva Diária

.DESCRIPTION
    Consolida a operação passiva em um único comando:
      1. Executa TEIA-Watchdog-Passive-v0200.ps1 (silencioso)
      2. Exibe TEIA-Watchdog-Report.ps1 -ShowFiles (output limpo)
      3. Grava linha de log em passive_daily.log

    REGRA DE OURO: CAS Delta = 0. Nenhum arquivo original é alterado.

.PARAMETER InboxDir
    Diretório a analisar. Padrão: D:\TEIA_USER\Inbox

.PARAMETER PlannerScript
    Motor de roteamento. Padrão: TEIA-NeuroPlanner-v0218.ps1

.PARAMETER DailyLog
    Log acumulado por execução. Padrão: D:\TEIA_CORE\logs\passive_daily.log
#>
[CmdletBinding()]
param(
    [string]$InboxDir      = 'D:\TEIA_USER\Inbox',
    [string]$PlannerScript = 'D:\TEIA_CORE\tools\TEIA-NeuroPlanner-v0218.ps1',
    [string]$WatchdogScript= 'D:\TEIA_CORE\tools\TEIA-Watchdog-Passive-v0200.ps1',
    [string]$ReportScript  = 'D:\TEIA_CORE\tools\TEIA-Watchdog-Report.ps1',
    [string]$DailyLog      = 'D:\TEIA_CORE\logs\passive_daily.log'
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$runStart = Get-Date

# ── Validações ────────────────────────────────────────────────────────────────

foreach ($p in @($WatchdogScript, $ReportScript, $PlannerScript)) {
    if (-not (Test-Path -LiteralPath $p)) {
        Write-Host "[PassiveDaily] ERRO: script nao encontrado: $p" -ForegroundColor Red
        exit 1
    }
}
if (-not (Test-Path -LiteralPath $InboxDir)) {
    Write-Host "[PassiveDaily] ERRO: InboxDir nao encontrado: $InboxDir" -ForegroundColor Red
    exit 1
}
New-Item -ItemType Directory -Path ([System.IO.Path]::GetDirectoryName($DailyLog)) -Force | Out-Null

# ── Fase 1: Watchdog Passivo (silencioso) ─────────────────────────────────────

Write-Host ("[PassiveDaily] {0:yyyy-MM-dd HH:mm:ss} — analisando {1}..." -f $runStart, $InboxDir) -ForegroundColor Cyan

$wdOutput = & pwsh -NoProfile -File $WatchdogScript `
                -WatchDir      $InboxDir `
                -PlannerScript $PlannerScript `
                2>&1

# Extrair estatísticas da linha de sumário do Watchdog
$summaryLine = "$( $wdOutput | Where-Object { "$_" -match 'Novos\s*:' } | Select-Object -Last 1 )"
$novos = if ($summaryLine -match 'Novos\s*:\s*(\d+)')  { [int]$Matches[1] } else { 0 }
$skip  = if ($summaryLine -match 'Skip\s*:\s*(\d+)')   { [int]$Matches[1] } else { 0 }
$fail  = if ($summaryLine -match 'Fail\s*:\s*(\d+)')   { [int]$Matches[1] } else { 0 }
$tempo = if ($summaryLine -match 'Tempo\s*:\s*(\d+)')  { [int]$Matches[1] } else { 0 }

Write-Host ("[PassiveDaily] Watchdog: novos={0}  skip={1}  fail={2}  tempo={3}s" -f $novos, $skip, $fail, $tempo) -ForegroundColor $(if ($fail -gt 0) { 'Yellow' } else { 'Green' })

# ── Fase 2: Relatório (output limpo para o console) ───────────────────────────

Write-Host ''
$reportOutput = & pwsh -NoProfile -File $ReportScript -ShowFiles 2>&1
$reportOutput | ForEach-Object { Write-Host "$_" }

# Extrair linha de economia para o log
$econLine  = "$( $reportOutput | Where-Object { "$_" -match 'conomizaria' } | Select-Object -Last 1 )"
$econEntry = if ($econLine -match 'economizaria\s+([\d,\.]+\s*MB)\s*\(([^)]+)\)') {
    "economia=$($Matches[1].Trim()) ($($Matches[2].Trim()))"
} else { 'economia=n/a' }

# ── Fase 3: Log diário ────────────────────────────────────────────────────────

$elapsed  = [int]((Get-Date) - $runStart).TotalSeconds
$logLine  = "{0:yyyy-MM-dd HH:mm:ss} | novos={1} skip={2} fail={3} tempo={4}s | {5} | inbox={6}" -f `
            $runStart, $novos, $skip, $fail, $elapsed, $econEntry, $InboxDir

$encLog = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::AppendAllText($DailyLog, $logLine + [System.Environment]::NewLine, $encLog)

Write-Host ''
Write-Host ("[PassiveDaily] Log: $DailyLog") -ForegroundColor DarkGray
