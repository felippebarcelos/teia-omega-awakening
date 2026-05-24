$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:AION_HTTP_TOKEN    = 'dd8d91a5bf264a7aa303a42aab4125ca'
$env:AION_WATCHER_STATE = 'ACTIVE'
$env:AION_ROOT          = 'D:\TEIA_CLAUDE_AWAKENING'
$env:AION_QUEUE         = 'D:\TEIA_CLAUDE_AWAKENING\aion_restore_queue.jsonl'
$env:AION_LOGS          = 'D:\TEIA_CLAUDE_AWAKENING\logs'

function L($m) { $ts = (Get-Date).ToString('HH:mm:ss.fff'); "$ts $m" | Out-File 'D:\TEIA_CLAUDE_AWAKENING\logs\http_debug.log' -Append -Encoding utf8; Write-Host "$ts $m" }

function AppendCors($ctx) {
    L "CORS: AppendHeader start"
    $ctx.Response.AppendHeader('Access-Control-Allow-Origin', '*')
    L "CORS: after Allow-Origin"
    $ctx.Response.AppendHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
    L "CORS: after Allow-Methods"
    $ctx.Response.AppendHeader('Access-Control-Allow-Headers', 'Content-Type,X-AION-TOKEN')
    L "CORS: done"
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add('http://127.0.0.1:8123/')
$listener.Start()
L "[DEBUG-HTTP] Started"

$i = 0
while ($i -lt 10) {
    L "GetContext() waiting..."
    $ctx = $listener.GetContext()
    $i++
    $method = $ctx.Request.HttpMethod
    $url    = $ctx.Request.RawUrl
    L "Request $i: $method $url"
    try {
        if ($method -eq 'OPTIONS') {
            L "OPTIONS handler"
            try { $ctx.Response.StatusCode = 204; AppendCors $ctx } finally { try { $ctx.Response.Close() } catch {} }
            L "OPTIONS done"
            continue
        }
        $json  = '{"ok":true,"msg":"debug"}'
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        L "SendJson start"
        $ctx.Response.StatusCode  = 200
        $ctx.Response.ContentType = 'application/json; charset=utf-8'
        AppendCors $ctx
        L "Before Write"
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        L "After Write"
    } finally {
        try { $ctx.Response.Close() } catch { L "Close error: $_" }
        L "Context closed"
    }
}
$listener.Stop()
L "Stopped after 10 requests"
