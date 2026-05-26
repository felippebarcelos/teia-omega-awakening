<#
.SYNOPSIS
    Limpar-Temporarios.ps1 — Limpeza de artefatos temporários do ecossistema TEIA.

.DESCRIPTION
    Remove conteúdo de _bench_v*/tmp/ e logs obsoletos quando o espaço em D: cair
    abaixo do limiar configurável. Idempotente: re-execução é segura.
    Nunca apaga objetos CAS, manifests ou scripts.

.PARAMETER LimiarGB
    Limiar de espaço livre (GB) abaixo do qual a limpeza é ativada. Padrão: 10.

.PARAMETER Forcar
    Executa a limpeza mesmo que o espaço livre esteja acima do limiar.

.EXAMPLE
    .\Limpar-Temporarios.ps1                  # verifica limiar e limpa se necessário
    .\Limpar-Temporarios.ps1 -Forcar          # limpa incondicionalmente
    .\Limpar-Temporarios.ps1 -LimiarGB 20     # limiar mais conservador
#>
[CmdletBinding()]
param(
    [double]$LimiarGB = 10.0,
    [switch]$Forcar
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'

$EventLog    = 'D:\TEIA_CORE\dna_events.jsonl'
$BenchRoot   = 'D:\TEIA_CLAUDE_AWAKENING'
$LogsDir     = 'D:\TEIA_CLAUDE_AWAKENING\logs'

# Diretórios seguros para limpeza — NUNCA incluir CAS, manifests ou tools
$AlvosTmp = @(
    'D:\TEIA_CLAUDE_AWAKENING\_bench_v4\tmp',
    'D:\TEIA_CLAUDE_AWAKENING\_bench_v5\tmp',
    'D:\TEIA_CLAUDE_AWAKENING\_bench_v5_full\tmp',
    'D:\TEIA_CLAUDE_AWAKENING\_bench_v6\tmp',
    'D:\TEIA_CLAUDE_AWAKENING\_bench_v7\tmp',
    'D:\TEIA_CLAUDE_AWAKENING\_bench_v8\tmp',
    'D:\TEIA_CLAUDE_AWAKENING\_bench_v9\tmp',
    'D:\TEIA_CLAUDE_AWAKENING\_bench_v10\tmp',
    'D:\TEIA_CLAUDE_AWAKENING\_bench_v11\tmp',
    'D:\TEIA_CLAUDE_AWAKENING\_bench_v12\tmp',
    'D:\TEIA_CLAUDE_AWAKENING\_bench_canonical\tmp',
    'D:\TEIA_CLAUDE_AWAKENING\_bench_real\tmp'
)

# Padrões de log obsoleto (mais de 30 dias, extensão .log ou .tmp)
$LogIdadeDias = 30

function Write-LimpEvent {
    param([string]$Act, [hashtable]$Data)
    $line = ([ordered]@{
        ts   = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
        src  = 'Limpar-Temporarios'
        act  = $Act
        data = $Data
    } | ConvertTo-Json -Compress -Depth 4)
    Add-Content -LiteralPath $EventLog -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

function Get-FreeGB {
    $drive = Get-PSDrive D -ErrorAction SilentlyContinue
    if (-not $drive) { return 0.0 }
    return [math]::Round($drive.Free / 1GB, 2)
}

function Remove-DirContents {
    param([string]$Dir)
    if (-not (Test-Path $Dir)) { return 0L }
    $files = Get-ChildItem $Dir -Recurse -File -Force -ErrorAction SilentlyContinue
    $totalBytes = 0L
    foreach ($f in $files) {
        $totalBytes += $f.Length
        Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
    }
    # Remove subdiretórios vazios resultantes
    Get-ChildItem $Dir -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        ForEach-Object { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }
    return $totalBytes
}

# ── Verificação de limiar ─────────────────────────────────────────────────────
$freeGB = Get-FreeGB

if (-not $Forcar -and $freeGB -ge $LimiarGB) {
    Write-Host "[LIMP] Espaço livre: ${freeGB}GB >= limiar ${LimiarGB}GB — limpeza não necessária."
    Write-LimpEvent 'LIMP_SKIP' @{ livre_gb = $freeGB; limiar_gb = $LimiarGB }
    exit 0
}

Write-Host "[LIMP] Iniciando limpeza — espaço livre: ${freeGB}GB (limiar: ${LimiarGB}GB)"
Write-LimpEvent 'LIMP_START' @{ livre_gb = $freeGB; limiar_gb = $LimiarGB; forcado = $Forcar.IsPresent }

$totalLiberado = 0L
$dirsLimpos    = 0

# ── Limpar tmp de benchmarks ──────────────────────────────────────────────────
foreach ($dir in $AlvosTmp) {
    if (-not (Test-Path $dir)) { continue }
    $antes = (Get-ChildItem $dir -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    if ($antes -eq 0) { continue }
    $removidos = Remove-DirContents -Dir $dir
    $totalLiberado += $removidos
    $dirsLimpos++
    $mb = [math]::Round($removidos / 1MB, 2)
    Write-Host "[LIMP] Limpo: $dir — ${mb}MB removidos"
    Write-LimpEvent 'LIMP_TMP_CLEARED' @{ dir = $dir; bytes_removidos = $removidos }
}

# ── Limpar logs com mais de $LogIdadeDias dias ────────────────────────────────
if (Test-Path $LogsDir) {
    $corte = (Get-Date).AddDays(-$LogIdadeDias)
    $logsObsoletos = Get-ChildItem $LogsDir -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in @('.log', '.tmp', '.bak') -and $_.LastWriteTime -lt $corte }
    foreach ($log in $logsObsoletos) {
        $totalLiberado += $log.Length
        Remove-Item $log.FullName -Force -ErrorAction SilentlyContinue
        Write-Host "[LIMP] Log obsoleto removido: $($log.Name)"
    }
    if ($logsObsoletos.Count -gt 0) {
        Write-LimpEvent 'LIMP_LOGS_CLEARED' @{ count = $logsObsoletos.Count }
    }
}

# ── Resumo ────────────────────────────────────────────────────────────────────
$livreDepois = Get-FreeGB
$liberadoMB  = [math]::Round($totalLiberado / 1MB, 2)
Write-Host "[LIMP] Concluído — Liberado: ${liberadoMB}MB | Dirs limpos: $dirsLimpos | Livre agora: ${livreDepois}GB"
Write-LimpEvent 'LIMP_END' @{
    liberado_mb  = $liberadoMB
    dirs_limpos  = $dirsLimpos
    livre_antes  = $freeGB
    livre_depois = $livreDepois
}
