# TEIA — Stream + Relay (PowerShell 7)
param(
    [int]$StreamPort = 8080,
    [int]$ControlPort = 8081,
    [int]$Fps = 12,
    [string]$BindAddress = '0.0.0.0',
    [string]$LogFile = '.\teia_stream_relay.log',
    [string]$PidFile = '.\teia_stream_relay.pid',
    [switch]$ForceRestart
)

# Idempotent checks
function Write-Log {
    param($m)
    $t = (Get-Date).ToString('o')
    $line = "$t`t$m"
    Add-Content -Path $LogFile -Value $line -Encoding utf8
    Write-Output $line
}

try {
    # Ensure UTF8 output
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

Write-Log "STARTING teia_stream_relay.ps1 (PowerShell $($PSVersionTable.PSVersion))"

if (Test-Path $PidFile -and -not $ForceRestart) {
    try {
        $existing = Get-Content $PidFile -ErrorAction Stop | ConvertFrom-Json
        if ($existing.listener_pid -and (Get-Process -Id $existing.listener_pid -ErrorAction SilentlyContinue)) {
            Write-Log "Service already running (listener PID $($existing.listener_pid)). Exiting (use -ForceRestart to restart)."
            $existing | ConvertTo-Json -Compress
            return
        }
    } catch {
        # stale pidfile or unreadable — continue to start
        Write-Log "Stale or unreadable pidfile; continuing startup."
    }
}

# Generate a secure token (idempotent per run)
function New-Token {
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object 'byte[]' 32
    $rng.GetBytes($bytes)
    [System.Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+','-').Replace('/','_')
}

$Token = New-Token
Write-Log "Generated token (len=$($Token.Length)). Keep secret."

# Start ffmpeg MJPEG stream (desktop capture) if available
$ffmpegPath = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
$ffmpegPid = $null
$streamUrl = "http://$BindAddress`:$StreamPort/stream.mjpg"

if ($ffmpegPath) {
    Write-Log "ffmpeg found at $ffmpegPath — attempting to start MJPEG stream."
    # Build ffmpeg args (gdigrab for Windows). If running on other OS, user should adapt (x11grab, avfoundation, etc).
    $ffmpegArgs = @(
        '-f', 'gdigrab',
        '-framerate', $Fps.ToString(),
        '-i', 'desktop',
        '-vcodec', 'mjpeg',
        '-q:v', '5',
        '-f', 'mjpeg',
        "http://$BindAddress:$StreamPort/stream.mjpg"
    )

    # Start ffmpeg as background process
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $ffmpegPath
    $startInfo.Arguments = ($ffmpegArgs -join ' ')
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $startInfo
    $null = $proc.Start()
    $ffmpegPid = $proc.Id
    Write-Log "ffmpeg started (PID $ffmpegPid) streaming to $streamUrl"
} else {
    Write-Log "ffmpeg not found. Stream will not start automatically. To enable: install ffmpeg and re-run."
    $streamUrl = $null
}

# Start WebSocket control listener (HTTPListener -> AcceptWebSocketAsync)
# Requires .NET types available in PowerShell 7
$listener = New-Object System.Net.HttpListener
$prefix = "http://$BindAddress:$ControlPort/"
$listener.Prefixes.Add($prefix)
try {
    $listener.Start()
    Write-Log "HTTP listener started on $prefix"
} catch {
    Write-Log "Failed to start HTTP listener on $prefix — error: $($_.Exception.Message)"
    throw
}

# Helper: send JSON response
function Send-JsonResponse {
    param($context, $obj, $statusCode = 200)
    $resp = $context.Response
    $resp.StatusCode = $statusCode
    $json = $obj | ConvertTo-Json -Depth 6
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
    $resp.ContentType = 'application/json; charset=utf-8'
    $resp.ContentEncoding = [System.Text.Encoding]::UTF8
    $resp.ContentLength64 = $buffer.Length
    $resp.OutputStream.Write($buffer, 0, $buffer.Length)
    $resp.OutputStream.Close()
}

# Asynchronous accept loop
$listenerTokenSource = New-Object System.Threading.CancellationTokenSource
$cts = $listenerTokenSource.Token

$clients = [System.Collections.Concurrent.ConcurrentDictionary[System.String,object]]::new()

$acceptLoop = {
    param($listener, $cts)
    while (-not $cts.IsCancellationRequested) {
        try {
            $context = $listener.GetContext()
        } catch [System.Net.HttpListenerException] {
            break
        } catch {
            Start-Sleep -Milliseconds 100
            continue
        }

        Start-Job -ArgumentList $context -ScriptBlock {
            param($context)
            try {
                $reqUrl = $context.Request.RawUrl
                if ($reqUrl -eq '/info') {
                    # return metadata
                    $meta = @{
                        stream_url = $using:streamUrl
                        ws_url     = "ws://$($using:BindAddress):$($using:ControlPort)/ws"
                        token      = $using:Token
                        timestamp  = (Get-Date).ToString('o')
                    }
                    Send-JsonResponse -context $context -obj $meta
                    return
                }

                # Upgrade to websocket if path /ws
                if ($context.Request.RawUrl -like '/ws*') {
                    # Authentication: Authorization header Bearer <token>
                    $auth = $context.Request.Headers['Authorization']
                    if (-not $auth -or -not $auth.StartsWith('Bearer ')) {
                        Send-JsonResponse -context $context -obj @{ error = 'missing_authorization' } -statusCode 401
                        return
                    }
                    $provided = $auth.Substring(7).Trim()
                    if ($provided -ne $using:Token) {
                        Send-JsonResponse -context $context -obj @{ error = 'invalid_token' } -statusCode 403
                        return
                    }

                    $wsContextTask = $context.AcceptWebSocketAsync([System.Net.WebSockets.WebSocketProtocol]::Empty)
                    $wsContextTask.Wait()
                    $wsContext = $wsContextTask.Result
                    $websocket = $wsContext.WebSocket
                    $clientId = [System.Guid]::NewGuid().ToString()
                    $clients[$clientId] = $websocket
                    Write-Output "WS connected: $clientId" | Out-String | Write-Log

                    # Echo loop: receive JSON commands and respond with ack
                    $buffer = New-Object 'byte[]' 8192
                    while ($websocket.State -eq 'Open') {
                        $receiveResult = $websocket.ReceiveAsync([System.ArraySegment[byte]]::new($buffer), [System.Threading.CancellationToken]::None)
                        $receiveResult.Wait()
                        $count = $receiveResult.Result.Count
                        if ($count -eq 0) { break }
                        $payload = [System.Text.Encoding]::UTF8.GetString($buffer,0,$count)
                        # try parse json
                        try {
                            $cmd = $payload | ConvertFrom-Json
                        } catch {
                            $cmd = @{ raw = $payload }
                        }
                        # Validate idempotent shape
                        if (-not $cmd.id) { $cmd.id = [System.Guid]::NewGuid().ToString() }
                        # Log command
                        Write-Log "CMD recv id=$($cmd.id) cmd=$($cmd.cmd) payload=$($payload.Substring(0,[Math]::Min(200,$payload.Length)))"
                        # Simple processing: write to file for local actor to pick up
                        $outFile = ".\teia_cmd_$($cmd.id).json"
                        $cmd | ConvertTo-Json -Depth 8 | Set-Content -Path $outFile -Encoding utf8
                        # ack back
                        $ack = @{ id = $cmd.id; status = 'queued'; timestamp = (Get-Date).ToString('o') }
                        $ackBytes = [System.Text.Encoding]::UTF8.GetBytes(($ack | ConvertTo-Json -Compress))
                        $sendTask = $websocket.SendAsync([System.ArraySegment[byte]]::new($ackBytes), [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None)
                        $sendTask.Wait()
                    }

                    # cleanup
                    $clients.TryRemove($clientId, [ref]$null) | Out-Null
                    Write-Log "WS disconnected: $clientId"
                    return
                }

                # Other paths: 404
                Send-JsonResponse -context $context -obj @{ error = 'not_found' } -statusCode 404
            } catch {
                Write-Log "Handler error: $($_.Exception.Message)"
                try { Send-JsonResponse -context $context -obj @{ error = $_.Exception.Message } -statusCode 500 } catch {}
            }
        } | Out-Null
    }
}

# Start accept loop in background job
$job = Start-Job -ScriptBlock $acceptLoop -ArgumentList $listener, $cts

# Save pidfile metadata
$meta = @{
    listener_pid = $PID
    listener_job = $job.Id
    listener_port = $ControlPort
    stream_port = $StreamPort
    stream_url = $streamUrl
    ws_url = if ($streamUrl) { "ws://$BindAddress:$ControlPort/ws" } else { "ws://$BindAddress:$ControlPort/ws" }
    token = $Token
    ffmpeg_pid = $ffmpegPid
    started = (Get-Date).ToString('o')
}
$meta | ConvertTo-Json -Compress | Set-Content -Path $PidFile -Encoding utf8

# Output metadata to stdout as single JSON line (for Codex CLI to parse)
$metaJson = $meta | ConvertTo-Json -Depth 6
Write-Output $metaJson
Write-Log "Service started and metadata emitted."

Write-Log "To stop: Remove-Item $PidFile; Stop-Process -Id <ffmpeg_pid> (if present); Stop-Job -Id $($job.Id); $listener.Stop()"
