# AION-RISPA-PocketKernel.ps1 — Bootstrap compacto do sistema AION-RISPA-NDC
# Usa Start-Process (processo independente) em vez de Start-Job para que o
# servidor HTTP sobreviva alem da sessao PowerShell que o invocou.
# Uso: .\AION-RISPA-PocketKernel.ps1 [-Port 8123] [-OpenBrowser]
param(
    [int]$Port         = 8123,
    [string]$Root      = $PSScriptRoot,
    [switch]$OpenBrowser,
    [switch]$SkipWatcher
)
$ErrorActionPreference = 'Stop'
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-Location $Root

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-K($m) { Write-Host "[POCKET-KERNEL] $m" }

# ── Ambiente ─────────────────────────────────────────────────────────────────
if (-not $env:AION_HTTP_TOKEN -or [string]::IsNullOrWhiteSpace($env:AION_HTTP_TOKEN)) {
    $env:AION_HTTP_TOKEN = [Guid]::NewGuid().ToString('N')
}
$env:AION_LOGS      = Join-Path $Root 'logs'
$env:AION_QUEUE     = Join-Path $Root 'aion_restore_queue.jsonl'
$env:AION_BIN       = Join-Path $Root 'bin'
$env:AION_HTTP_PORT = [string]$Port
$env:AION_ROOT      = $Root
$env:AION_WATCHER_STATE = 'ACTIVE'

New-Item -ItemType Directory -Force -Path $env:AION_LOGS, $env:AION_BIN | Out-Null
if (!(Test-Path $env:AION_QUEUE)) { New-Item -ItemType File -Force -Path $env:AION_QUEUE | Out-Null }

# Persistir vars (best-effort)
@('AION_HTTP_TOKEN','AION_LOGS','AION_QUEUE','AION_BIN','AION_HTTP_PORT','AION_ROOT','AION_WATCHER_STATE') | ForEach-Object {
    try { & cmd /c setx $_ ([System.Environment]::GetEnvironmentVariable($_)) 2>$null | Out-Null } catch {}
}

# netsh urlacl (best-effort, necessario em alguns ambientes)
try { & netsh http add urlacl url=http://127.0.0.1:$Port/ user=$env:UserName 2>$null | Out-Null } catch {}

# ── Verificar dependencias ───────────────────────────────────────────────────
$httpScript    = Join-Path $Root 'AION-Local-Http.ps1'
$watcherScript = Join-Path $Root 'AION-Restore-Watcher.ps1'
if (!(Test-Path $httpScript)) { throw "AION-Local-Http.ps1 nao encontrado em $Root" }

# ── Matar processo anterior na porta (se houver) ─────────────────────────────
$oldConn = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
if ($oldConn -and $oldConn.OwningProcess -gt 0) {
    Write-K "Encerrando processo anterior na porta $Port (PID $($oldConn.OwningProcess))..."
    Stop-Process -Id $oldConn.OwningProcess -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 400
}

# ── Gerar wrapper script — evita problemas de quoting em Start-Process ───────
# Set-ExecutionPolicy nao pode ser chamado em contexto -NonInteractive;
# o bypass e passado via -ExecutionPolicy Bypass no argumento do processo.
$wrapperScript = Join-Path $Root 'aion_http_start.ps1'
@"
`$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
`$env:AION_HTTP_TOKEN    = '$($env:AION_HTTP_TOKEN)'
`$env:AION_WATCHER_STATE = 'ACTIVE'
`$env:AION_ROOT          = '$Root'
`$env:AION_QUEUE         = '$($env:AION_QUEUE)'
`$env:AION_LOGS          = '$($env:AION_LOGS)'
& '$httpScript' -Port $Port -Root '$Root' -QueuePath '$($env:AION_QUEUE)' -LogPath '$(Join-Path $env:AION_LOGS 'restore_watcher.log')'
"@ | Set-Content $wrapperScript -Encoding UTF8

# ── Iniciar servidor HTTP como processo independente ─────────────────────────
Write-K "Iniciando HTTP em :$Port (processo independente)..."
$httpProc = Start-Process 'powershell.exe' `
    -ArgumentList "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$wrapperScript`"" `
    -RedirectStandardOutput (Join-Path $env:AION_LOGS 'http_stdout.log') `
    -RedirectStandardError  (Join-Path $env:AION_LOGS 'http_stderr.log') `
    -WindowStyle Hidden -PassThru
Write-K "HTTP Process PID: $($httpProc.Id)"

Start-Sleep -Milliseconds 1200

# Smoke test
$httpOk = $false
try { $r = Invoke-RestMethod "http://127.0.0.1:$Port/" -TimeoutSec 4; Write-K "HTTP OK � brand=$($r.brand)"; $httpOk = $true } catch { Write-K "AVISO: HTTP nao respondeu no tempo esperado. PID=$($httpProc.Id) � aguarde alguns segundos." }

# ── Iniciar Watcher como processo independente ───────────────────────────────
$watcherPid = $null
if (-not $SkipWatcher -and (Test-Path $watcherScript)) {
    Write-K "Iniciando Restore Watcher (processo independente)..."
    $watcherArgs = "-NoProfile -NonInteractive -ExecutionPolicy Bypass " +
                   "-File '$watcherScript' " +
                   "-Queue '$($env:AION_QUEUE)' " +
                   "-Log '$(Join-Path $env:AION_LOGS 'restore_watcher.log')'"
    $watcherProc = Start-Process 'powershell.exe' -ArgumentList $watcherArgs -WindowStyle Hidden -PassThru
    $watcherPid  = $watcherProc.Id
    Write-K "Watcher PID: $watcherPid"
}

# ── Salvar estado ────────────────────────────────────────────────────────────
$state = @{
    started        = (Get-Date).ToString('o')
    token          = $env:AION_HTTP_TOKEN
    port           = $Port
    root           = $Root
    http_url       = "http://127.0.0.1:$Port/"
    http_pid       = $httpProc.Id
    watcher_pid    = $watcherPid
    http_ok        = $httpOk
    queue          = $env:AION_QUEUE
    logs           = $env:AION_LOGS
}
$state | ConvertTo-Json -Compress | Set-Content -Path (Join-Path $Root 'aion_kernel.state.json') -Encoding utf8

Write-K "==================================================="
Write-K "AION-RISPA-NDC PocketKernel ATIVO"
Write-K "HTTP:  http://127.0.0.1:$Port/"
Write-K "Token: $($env:AION_HTTP_TOKEN)"
Write-K "Queue: $($env:AION_QUEUE)"
Write-K "==================================================="

if ($OpenBrowser) {
    $patchedUI   = Join-Path $Root 'index30.aion.html'
    $patchScript = Join-Path $Root 'Patch-Index30-For-AION.ps1'
    if (!(Test-Path $patchedUI) -and (Test-Path $patchScript)) {
        Write-K "Aplicando patch visual → index30.aion.html ..."
        & $patchScript -IndexPath (Join-Path $Root 'index30.html') -OutPath $patchedUI -AionPort $Port
}
    if (Test-Path $patchedUI) {
        Start-Process $patchedUI
    } elseif (Test-Path (Join-Path $Root 'index30.html')) {
        Start-Process (Join-Path $Root 'index30.html')
}
}

$state

