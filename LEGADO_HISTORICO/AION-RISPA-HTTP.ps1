# AION-RISPA-HTTP.ps1 — Wrapper de inicialização do HTTP bridge AION-RISPA-NDC
# Configura vars de ambiente e lança AION-Local-Http.ps1 como Job de fundo
# ou diretamente se -Foreground for passado
param(
    [int]$Port       = 8123,
    [string]$Root    = $PSScriptRoot,
    [switch]$Foreground
)
$ErrorActionPreference = 'Stop'
Set-Location $Root

if (-not $env:AION_HTTP_TOKEN -or [string]::IsNullOrWhiteSpace($env:AION_HTTP_TOKEN)) {
    $env:AION_HTTP_TOKEN = [Guid]::NewGuid().ToString('N')
}
$env:AION_LOGS  = Join-Path $Root 'logs'
$env:AION_QUEUE = Join-Path $Root 'aion_restore_queue.jsonl'

New-Item -ItemType Directory -Force -Path $env:AION_LOGS | Out-Null
if (!(Test-Path $env:AION_QUEUE)) { New-Item -ItemType File -Force -Path $env:AION_QUEUE | Out-Null }

# Netsh urlacl (best-effort, permite listener sem admin em alguns casos)
try { & netsh http add urlacl url=http://127.0.0.1:$Port/ user=$env:UserName 2>$null | Out-Null } catch {}

$httpScript = Join-Path $Root 'AION-Local-Http.ps1'
if (!(Test-Path $httpScript)) { throw "AION-Local-Http.ps1 não encontrado em $Root" }

Write-Host "[AION-HTTP] Token: $($env:AION_HTTP_TOKEN)"
Write-Host "[AION-HTTP] Queue: $env:AION_QUEUE"
Write-Host "[AION-HTTP] Logs:  $env:AION_LOGS"

if ($Foreground) {
    & $httpScript -Port $Port -QueuePath $env:AION_QUEUE -LogPath (Join-Path $env:AION_LOGS 'restore_watcher.log')
} else {
    $job = Start-Job -FilePath $httpScript -ArgumentList $Port, $env:AION_QUEUE, (Join-Path $env:AION_LOGS 'restore_watcher.log')
    Write-Host "[AION-HTTP] Servidor iniciado como Job #$($job.Id). Acesso: http://127.0.0.1:$Port/"
    Write-Host "[AION-HTTP] Para parar: Stop-Job -Id $($job.Id)"
    $job
}
