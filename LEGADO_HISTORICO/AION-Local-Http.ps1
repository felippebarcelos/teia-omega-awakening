# AION-Local-Http.ps1 — Servidor HTTP local AION-RISPA-NDC em :8123
# Extraido de 00-AION-Migrate.ps1 + parametrizado standalone
# Endpoints: / /health /metrics /log/tail /enqueue(POST) /restore(POST)
param(
    [int]$Port      = 8123,
    [string]$Root   = '',
    [string]$QueuePath = '',
    [string]$LogPath   = ''
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ── Helpers de rede ──────────────────────────────────────────────────────────
function Set-Cors($ctx) {
    # AppendHeader e sempre seguro — nao passa pelo check de headers restritos
    try { $ctx.Response.AppendHeader('Access-Control-Allow-Origin',  '*') } catch {}
    try { $ctx.Response.AppendHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS') } catch {}
    try { $ctx.Response.AppendHeader('Access-Control-Allow-Headers', 'Content-Type,X-AION-TOKEN') } catch {}
}
function SendJson($ctx, $obj, [int]$code = 200) {
    try {
        $json  = $obj | ConvertTo-Json -Depth 8 -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $ctx.Response.StatusCode  = $code
        $ctx.Response.ContentType = 'application/json; charset=utf-8'
        Set-Cors $ctx
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } finally {
        # Close sempre executado — evita acumulo de contextos em CLOSE_WAIT
        try { $ctx.Response.Close() } catch {}
    }
}
function TailLog([string]$path, [int]$lines) {
    if (!(Test-Path $path)) { return @('<no-log>') }
    Get-Content -LiteralPath $path -Tail $lines
}
function Parse-Query([string]$query) {
    $r = @{}
    if ([string]::IsNullOrEmpty($query)) { return $r }
    $q = $query.TrimStart('?')
    foreach ($pair in $q -split '&') {
        if ([string]::IsNullOrWhiteSpace($pair)) { continue }
        $kv = $pair -split '=', 2
        $k  = [Uri]::UnescapeDataString($kv[0])
        $v  = if ($kv.Count -gt 1) { [Uri]::UnescapeDataString($kv[1]) } else { '' }
        $r[$k] = $v
    }
    return $r
}

# ── Decode engine v0.5.2 (AION-RISPA Delta procedural) ──────────────────────
function Expand-GZipBytes([byte[]]$Bytes) {
    $ms  = [System.IO.MemoryStream]::new($Bytes)
    $gz  = [System.IO.Compression.GZipStream]::new($ms, [System.IO.Compression.CompressionMode]::Decompress)
    $out = [System.IO.MemoryStream]::new()
    $gz.CopyTo($out); $gz.Dispose()
    $out.ToArray()
}

function Decode-RLEBytes([byte[]]$Bytes) {
    # Reverso de Encode-RepeatRLE do UniProc-v05: pares [count, byte]
    $out = [System.IO.MemoryStream]::new()
    $i   = 0
    while ($i + 1 -lt $Bytes.Length) {
        $run   = [int]$Bytes[$i]
        $b     = $Bytes[$i + 1]
        $chunk = [byte[]]::new($run)
        for ($j = 0; $j -lt $run; $j++) { $chunk[$j] = $b }
        $out.Write($chunk, 0, $chunk.Length)
        $i += 2
    }
    $out.ToArray()
}

function Decode-VMPayload([string]$vm, [string]$payloadB64) {
    $raw = [Convert]::FromBase64String($payloadB64)
    switch ($vm) {
        'raw'          { $raw }
        'gzipref@1'    { Expand-GZipBytes $raw }
        'lzss@1'       { Expand-GZipBytes $raw }   # lzss@1 usa gzip internamente no UniProc-v05
        'repeatrle@1'  { Decode-RLEBytes $raw }
        default        { throw "VM desconhecida no motor Delta: $vm" }
    }
}

function SHA256Hex-Bytes([byte[]]$bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { -join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) }
    finally { $sha.Dispose() }
}

function Restore-SeedV052([object]$seed) {
    if ($seed.v -ne '0.5.2') {
        throw "Versao de seed incompativel com o motor Delta: $($seed.v) (esperado 0.5.2)"
    }
    if ($seed.mode -eq 'stream') {
        # Seed multi-chunk — arquivo maior que ChunkSize
        $ms = [System.IO.MemoryStream]::new()
        foreach ($chunk in $seed.chunks) {
            $decoded = Decode-VMPayload -vm $chunk.vm -payloadB64 $chunk.seed_b64
            $ms.Write($decoded, 0, $decoded.Length)
        }
        $ms.ToArray()
    } else {
        # Seed chunk unico
        Decode-VMPayload -vm $seed.vm -payloadB64 $seed.payload_b64
    }
}

# ── Resolucao de caminhos ────────────────────────────────────────────────────
$logs  = if ($LogPath)    { Split-Path -Parent $LogPath } `
         elseif ($env:AION_LOGS) { $env:AION_LOGS } `
         else { Join-Path $env:LOCALAPPDATA 'AION\logs' }
$wlog  = if ($LogPath)    { $LogPath } else { Join-Path $logs 'restore_watcher.log' }
$queue = if ($QueuePath)  { $QueuePath } `
         elseif ($env:AION_QUEUE) { $env:AION_QUEUE } `
         else { Join-Path $env:TEMP 'aion_restore_queue.jsonl' }
$token = $env:AION_HTTP_TOKEN

# Root: base para salvar arquivos restaurados
$rootDir = if ($Root) { $Root } `
           elseif ($QueuePath) { Split-Path -Parent $QueuePath } `
           elseif ($env:AION_ROOT) { $env:AION_ROOT } `
           elseif ($env:AION_QUEUE) { Split-Path -Parent $env:AION_QUEUE } `
           else { $env:TEMP }

New-Item -ItemType Directory -Force -Path $logs | Out-Null
if (!(Test-Path $queue)) { New-Item -ItemType File -Force -Path $queue | Out-Null }

$prefix   = "http://127.0.0.1:$Port/"
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($prefix)
$listener.IgnoreWriteExceptions = $true   # evita crash por broken-pipe quando cliente desconecta antes da resposta
try { $listener.Start() } catch { throw "Falha ao iniciar listener em $prefix : $_" }
Write-Host "[AION-HTTP] Escutando em $prefix  root=$rootDir"

# ── Loop principal ───────────────────────────────────────────────────────────
while ($listener.IsListening) {
    $ctx = $null
    try {
        $ctx = $listener.GetContext()
        try {
            $req = $ctx.Request

            # ── OPTIONS (CORS preflight) ─────────────────────────────────────
            if ($req.HttpMethod -eq 'OPTIONS') {
                $ctx.Response.StatusCode = 204
                Set-Cors $ctx
                continue
            }

            # ── GET / ────────────────────────────────────────────────────────
            if ($req.HttpMethod -eq 'GET' -and ($req.RawUrl -eq '/' -or $req.RawUrl -like '/index*')) {
                SendJson $ctx @{
                    brand     = 'AION-RISPA-NDC'
                    port      = $Port
                    endpoints = @('GET /health','GET /metrics','GET /log/tail?lines=N','POST /enqueue','POST /restore')
                }
                continue
            }

            # ── GET /health ──────────────────────────────────────────────────
            if ($req.HttpMethod -eq 'GET' -and $req.RawUrl -like '/health*') {
                $watcherState = if ($env:AION_WATCHER_STATE) { $env:AION_WATCHER_STATE } else { 'ACTIVE' }
                $queueSize    = (Get-Item $queue -ErrorAction SilentlyContinue).Length
                SendJson $ctx @{ watcher_state=$watcherState; queue_size=$queueSize; root=$rootDir }
                continue
            }

            # ── GET /metrics ─────────────────────────────────────────────────
            if ($req.HttpMethod -eq 'GET' -and $req.RawUrl -like '/metrics*') {
                $ls  = TailLog $wlog 1000
                $ok  = ($ls | Where-Object { $_ -like '*[OK]*' }).Count
                $err = ($ls | Where-Object { $_ -like '*[ERR]*' }).Count
                SendJson $ctx @{ ok=$ok; err=$err }
                continue
            }

            # ── GET /log/tail ────────────────────────────────────────────────
            if ($req.HttpMethod -eq 'GET' -and $req.RawUrl -like '/log/tail*') {
                $qs = Parse-Query $req.Url.Query
                $n  = 200
                if ($qs.ContainsKey('lines')) { [void][int]::TryParse($qs['lines'], [ref]$n) }
                SendJson $ctx @{ lines=(TailLog $wlog $n) }
                continue
            }

            # ── POST /enqueue ────────────────────────────────────────────────
            if ($req.HttpMethod -eq 'POST' -and $req.RawUrl -like '/enqueue*') {
                if ($token -and $req.Headers['X-AION-TOKEN'] -ne $token) {
                    SendJson $ctx @{ error='unauthorized' } 401; continue
                }
                $reader = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
                $body   = $reader.ReadToEnd(); $reader.Dispose()
                try { $null = $body | ConvertFrom-Json -ErrorAction Stop } catch {
                    SendJson $ctx @{ error='invalid_json' } 400; continue
                }
                Add-Content -LiteralPath $queue -Value ($body + "`n") -Encoding UTF8
                SendJson $ctx @{ queued=$true; len=(Get-Item $queue).Length }
                continue
            }

            # ── POST /restore ────────────────────────────────────────────────
            if ($req.HttpMethod -eq 'POST' -and $req.RawUrl -like '/restore*') {
                if ($token -and $req.Headers['X-AION-TOKEN'] -ne $token) {
                    SendJson $ctx @{ error='unauthorized' } 401; continue
                }
                $reader = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
                $body   = $reader.ReadToEnd(); $reader.Dispose()

                $reqObj = $null
                try { $reqObj = $body | ConvertFrom-Json -ErrorAction Stop } catch {
                    SendJson $ctx @{ error='invalid_json'; detail=$_.Exception.Message } 400; continue
                }

                $seedObj = if ($reqObj.PSObject.Properties.Name -contains 'seed') { $reqObj.seed } else { $reqObj }
                $outName = if ($reqObj.PSObject.Properties.Name -contains 'out' -and $reqObj.out) {
                               $reqObj.out
                           } else {
                               'restored_' + [Guid]::NewGuid().ToString('N').Substring(0, 12) + '.bin'
                           }

                $outName = [System.IO.Path]::GetFileName($outName)

                try {
                    $restoredBytes = Restore-SeedV052 $seedObj
                    $sha256        = SHA256Hex-Bytes $restoredBytes

                    $restoreDir = Join-Path $rootDir 'restored'
                    New-Item -ItemType Directory -Force -Path $restoreDir | Out-Null
                    $outPath = Join-Path $restoreDir $outName
                    [System.IO.File]::WriteAllBytes($outPath, $restoredBytes)

                    $logLine = "$((Get-Date).ToString('s'))`t[OK-RESTORE] vm=$($seedObj.vm) size=$($restoredBytes.Length) sha256=$sha256 out=$outPath"
                    Add-Content -LiteralPath $wlog -Value $logLine -Encoding UTF8 -ErrorAction SilentlyContinue

                    SendJson $ctx @{
                        restored = $true
                        sha256   = $sha256
                        path     = $outPath
                        size     = $restoredBytes.Length
                        vm       = [string]$seedObj.vm
                        seed_v   = [string]$seedObj.v
                    }
                } catch {
                    $errMsg = $_.Exception.Message
                    $logLine = "$((Get-Date).ToString('s'))`t[ERR-RESTORE] $errMsg"
                    Add-Content -LiteralPath $wlog -Value $logLine -Encoding UTF8 -ErrorAction SilentlyContinue
                    SendJson $ctx @{ error='restore_failed'; detail=$errMsg } 500
                }
                continue
            }

            SendJson $ctx @{ error='not_found' } 404
        } finally {
            try { $ctx.Response.Close() } catch {}
        }
    } catch {
        # Erro fatal no GetContext ou falha critica no processamento
        Write-Warning "[AION-HTTP] Erro no loop: $_"
    }
}
