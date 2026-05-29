<#
.SYNOPSIS
    TEIA-VFS-Daemon-v0500.ps1 — Servidor HTTP de Interceptação VFS (P8.0)

.DESCRIPTION
    Protótipo funcional do TEIA Virtual File System Daemon.

    Expõe uma API REST local que:
      - Lê .teia_stub files de VFSRoot e constrói um manifesto virtual em memória
      - Reporta o tamanho original de cada arquivo (original_size_bytes) em vez do stub
      - Serve ranges de bytes diretamente do CAS (objects/) em streaming

    Invariantes:
      - CAS Delta = 0: zero bytes escritos em objects/ — operação pura de leitura
      - Stubs intocados: nenhum .teia_stub é modificado
      - OOM Guard: buffer fixo 64 KB em todas as operações de stream
      - Cache isolado: descompressão temporária em CacheDir, nunca no ActiveDrive

    Estratégias com chunk-on-demand verdadeiro (O(length) RAM):
      cas.raw      → FileStream.Seek(offset) + Read(length)
      gen.repeat   → gerar bytes do valor fixo para o range solicitado
      gen.pattern  → calcular pattern[(offset+i) % period] para o range

    Estratégias com cache de descompressão (full decompress na 1ª leitura):
      cmp.lzma            → GZipStream → CacheDir/{sha256}.dec → seek
      cmp.brotli          → BrotliStream → CacheDir/{sha256}.dec → seek
      gen.parametric_mesh → BrotliStream → CacheDir/{sha256}.dec → seek

    Endpoints:
      GET  /status              → JSON: saúde do daemon e contagem do manifesto
      GET  /api/list            → JSON: lista de arquivos virtuais com metadados
      GET  /api/meta/{nome}     → JSON: metadados de um arquivo específico
      GET  /api/read/{nome}     → stream: conteúdo completo ou range (206)
      HEAD /api/read/{nome}     → headers: Content-Length = original_size_bytes

    Range de bytes suportado via:
      - Header HTTP: Range: bytes=N-M
      - Query params: ?offset=N&length=M

.PARAMETER VFSRoot
    Diretório com os .teia_stub a expor. Padrão: D:\TEIA_USER\ActiveDrive_Test

.PARAMETER Port
    Porta HTTP local. Padrão: 8765

.PARAMETER CacheDir
    Diretório de cache para arquivos descomprimidos.
    Padrão: D:\TEIA_CORE\vfs_cache

.PARAMETER ClearCache
    Limpa o CacheDir ao iniciar (recomendado após atualização do CAS).
#>
[CmdletBinding()]
param(
    [string]$VFSRoot   = 'D:\TEIA_USER\ActiveDrive_Test',
    [string]$Port      = '8765',
    [string]$CacheDir  = 'D:\TEIA_CORE\vfs_cache',
    [switch]$ClearCache
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC = [System.Globalization.CultureInfo]::InvariantCulture

# ── Banner ────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host '  TEIA-VFS-Daemon v0.50.0 — Virtual File System HTTP Daemon (P8.0)' -ForegroundColor Cyan
Write-Host ('─' * 78)
Write-Host ("  VFSRoot  : $VFSRoot")
Write-Host ("  Port     : $Port")
Write-Host ("  CacheDir : $CacheDir")
Write-Host ("  CAS Delta: 0 — operacao de leitura pura (objects/ intocado)")
Write-Host ('─' * 78)

# ── Validações de inicialização ───────────────────────────────────────────────

if (-not (Test-Path -LiteralPath $VFSRoot)) {
    Write-Host "[VFS] ERRO: VFSRoot nao encontrado: $VFSRoot" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null

if ($ClearCache) {
    Get-ChildItem -LiteralPath $CacheDir -Filter '*.dec' |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host ("  Cache limpo: $CacheDir") -ForegroundColor DarkYellow
}

# ── Logging ───────────────────────────────────────────────────────────────────

function Write-Log([string]$Msg, [string]$Color = 'Gray') {
    $ts = (Get-Date).ToString('HH:mm:ss.fff', $IC)
    Write-Host ("  [$ts] $Msg") -ForegroundColor $Color
}

# ── Manifesto virtual ─────────────────────────────────────────────────────────

function Build-Manifest([string]$Dir) {
    $m = [System.Collections.Generic.Dictionary[string, hashtable]]::new(
             [System.StringComparer]::OrdinalIgnoreCase)

    $stubs = Get-ChildItem -LiteralPath $Dir -Filter '*.teia_stub' -ErrorAction SilentlyContinue
    foreach ($sf in $stubs) {
        try {
            $d = Get-Content -LiteralPath $sf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            $name = [string]$d.original_name
            if ([string]::IsNullOrWhiteSpace($name)) { continue }
            $m[$name] = @{
                name                = $name
                original_size_bytes = [long]$d.original_size_bytes
                original_sha256     = [string]$d.original_sha256
                final_strategy      = [string]$d.final_strategy
                cas_encoding        = [string]$d.cas_encoding
                cas_path            = [string]$d.cas_path
                cas_size_bytes      = [long]$d.cas_size_bytes
                savings_pct         = [double]$d.savings_pct
                stub_path           = $sf.FullName
            }
        } catch {
            Write-Log "AVISO: falha ao ler stub $($sf.Name): $_" 'DarkYellow'
        }
    }
    return $m
}

$script:manifest = Build-Manifest $VFSRoot
Write-Host ("  Manifesto  : $($script:manifest.Count) arquivos virtuais carregados")

if ($script:manifest.Count -eq 0) {
    Write-Host "  AVISO: nenhum .teia_stub encontrado em $VFSRoot" -ForegroundColor DarkYellow
}

# ── Helpers HTTP ──────────────────────────────────────────────────────────────

function Send-Json([System.Net.HttpListenerResponse]$Resp, [string]$Body, [int]$Code = 200) {
    $Resp.StatusCode     = $Code
    $Resp.ContentType    = 'application/json; charset=utf-8'
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
    $Resp.ContentLength64 = $bytes.Length
    try {
        $Resp.OutputStream.Write($bytes, 0, $bytes.Length)
        $Resp.OutputStream.Flush()
    } catch {}
    $Resp.Close()
}

function Escape-Json([string]$s) { $s -replace '\\','\\' -replace '"','\"' -replace "`n",'\n' -replace "`r",'\r' }

# ── Leitores por estratégia ───────────────────────────────────────────────────

function Read-CasRaw([string]$Path, [long]$Offset, [long]$Length, [System.IO.Stream]$Out) {
    $fs = [System.IO.File]::OpenRead($Path)
    try {
        [void]$fs.Seek($Offset, [System.IO.SeekOrigin]::Begin)
        $remaining = $Length
        $buf = New-Object byte[] 65536
        while ($remaining -gt 0) {
            $toRead = [int][Math]::Min($remaining, 65536)
            $n = $fs.Read($buf, 0, $toRead)
            if ($n -le 0) { break }
            $Out.Write($buf, 0, $n)
            $remaining -= $n
        }
    } finally {
        $fs.Dispose()
    }
}

function Read-GenRepeat([string]$SeedPath, [long]$Offset, [long]$Length, [System.IO.Stream]$Out) {
    # Offset ignorado — todos os bytes têm o mesmo valor
    $seed    = Get-Content -LiteralPath $SeedPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $byteVal = [Convert]::ToByte([string]$seed.value_hex, 16)
    $buf     = New-Object byte[] 65536
    for ($i = 0; $i -lt 65536; $i++) { $buf[$i] = $byteVal }
    $remaining = $Length
    while ($remaining -gt 0) {
        $n = [int][Math]::Min($remaining, 65536)
        $Out.Write($buf, 0, $n)
        $remaining -= $n
    }
}

function Read-GenPattern([string]$SeedPath, [long]$Offset, [long]$Length, [System.IO.Stream]$Out) {
    $seed    = Get-Content -LiteralPath $SeedPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $pattern = [Convert]::FromBase64String([string]$seed.pattern_b64)
    $pLen    = $pattern.Length
    $buf     = New-Object byte[] 65536
    $pos     = $Offset
    $remaining = $Length
    while ($remaining -gt 0) {
        $n = [int][Math]::Min($remaining, 65536)
        for ($i = 0; $i -lt $n; $i++) { $buf[$i] = $pattern[($pos + $i) % $pLen] }
        $Out.Write($buf, 0, $n)
        $remaining -= $n
        $pos += $n
    }
}

function Get-DecompressedCache([hashtable]$VE) {
    $cachePath = Join-Path $CacheDir "$($VE.original_sha256).dec"
    if (Test-Path -LiteralPath $cachePath) { return $cachePath }

    Write-Log "Cache miss: descomprimindo $($VE.name) → $cachePath" 'DarkYellow'
    $tmpPath   = "$cachePath.tmp"
    $inStream  = [System.IO.File]::OpenRead($VE.cas_path)
    $outStream = [System.IO.File]::Create($tmpPath)
    try {
        if ($VE.final_strategy -eq 'cmp.lzma') {
            $dec = New-Object System.IO.Compression.GZipStream(
                       $inStream, [System.IO.Compression.CompressionMode]::Decompress)
        } else {
            # cmp.brotli, gen.parametric_mesh
            $dec = New-Object System.IO.Compression.BrotliStream(
                       $inStream, [System.IO.Compression.CompressionMode]::Decompress)
        }
        $dec.CopyTo($outStream, 65536)
        $dec.Dispose()
    } finally {
        $inStream.Dispose()
        $outStream.Dispose()
    }
    Move-Item -LiteralPath $tmpPath -Destination $cachePath -Force
    Write-Log "Cache hit criado: $(Split-Path $cachePath -Leaf)" 'DarkGray'
    return $cachePath
}

function Send-RangeData([hashtable]$VE, [long]$Offset, [long]$Length, [System.IO.Stream]$Out) {
    switch ($VE.final_strategy) {
        'cas.raw'    { Read-CasRaw    $VE.cas_path $Offset $Length $Out }
        'gen.repeat' { Read-GenRepeat $VE.cas_path $Offset $Length $Out }
        'gen.pattern'{ Read-GenPattern $VE.cas_path $Offset $Length $Out }
        default {
            # cmp.lzma / cmp.brotli / gen.parametric_mesh
            $cachedPath = Get-DecompressedCache $VE
            Read-CasRaw $cachedPath $Offset $Length $Out
        }
    }
}

# ── Handlers HTTP ─────────────────────────────────────────────────────────────

function Handle-Status([System.Net.HttpListenerContext]$Ctx) {
    $uptime = [int]((Get-Date) - $script:startTime).TotalSeconds
    $cacheFiles = @(Get-ChildItem -LiteralPath $CacheDir -Filter '*.dec' -ErrorAction SilentlyContinue).Count
    $body = @"
{"daemon":"TEIA-VFS-Daemon","version":"v0.50.0","protocol":"P8.0","vfs_root":"$(Escape-Json $VFSRoot)","port":$Port,"virtual_files":$($script:manifest.Count),"cache_entries":$cacheFiles,"uptime_s":$uptime,"cas_delta":0,"oom_guard":"64KB buffer","status":"running"}
"@
    Send-Json $Ctx.Response $body.Trim()
}

function Handle-List([System.Net.HttpListenerContext]$Ctx) {
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('[')
    $first = $true
    foreach ($ve in $script:manifest.Values | Sort-Object { $_.name }) {
        if (-not $first) { [void]$sb.Append(',') }
        $first = $false
        $entry = '{"name":"' + (Escape-Json $ve.name) +
                 '","virtual_size_bytes":' + $ve.original_size_bytes +
                 ',"strategy":"' + $ve.final_strategy +
                 '","cas_size_bytes":' + $ve.cas_size_bytes +
                 ',"savings_pct":' + $ve.savings_pct.ToString('F1',$IC) +
                 ',"sha256":"' + $ve.original_sha256.Substring(0,16) + '..."}'
        [void]$sb.Append($entry)
    }
    [void]$sb.Append(']')
    Send-Json $Ctx.Response $sb.ToString()
}

function Handle-Meta([System.Net.HttpListenerContext]$Ctx, [string]$FileName) {
    $name = [System.Uri]::UnescapeDataString($FileName)
    if (-not $script:manifest.ContainsKey($name)) {
        Send-Json $Ctx.Response '{"error":"file not found in manifest"}' 404
        return
    }
    $ve = $script:manifest[$name]
    $body = '{"name":"' + (Escape-Json $ve.name) +
            '","virtual_size_bytes":' + $ve.original_size_bytes +
            ',"original_sha256":"' + $ve.original_sha256 +
            '","final_strategy":"' + $ve.final_strategy +
            '","cas_path":"' + (Escape-Json $ve.cas_path) +
            '","cas_size_bytes":' + $ve.cas_size_bytes +
            ',"savings_pct":' + $ve.savings_pct.ToString('F1',$IC) +
            ',"stub_path":"' + (Escape-Json $ve.stub_path) + '"}'
    Send-Json $Ctx.Response $body
}

function Handle-Read([System.Net.HttpListenerContext]$Ctx, [string]$FileName) {
    $req  = $Ctx.Request
    $resp = $Ctx.Response

    $name = [System.Uri]::UnescapeDataString($FileName)
    if (-not $script:manifest.ContainsKey($name)) {
        Send-Json $resp '{"error":"file not found in manifest"}' 404
        return
    }

    $ve       = $script:manifest[$name]
    $fileSize = [long]$ve.original_size_bytes

    $resp.Headers.Set('Accept-Ranges', 'bytes')
    $resp.Headers.Set('X-TEIA-Strategy', $ve.final_strategy)
    $resp.Headers.Set('X-TEIA-Original-SHA256', $ve.original_sha256)

    # Para HEAD: retorna só os headers
    if ($req.HttpMethod -eq 'HEAD') {
        $resp.StatusCode      = 200
        $resp.ContentLength64 = $fileSize
        $resp.ContentType     = 'application/octet-stream'
        $resp.Close()
        return
    }

    # Determinar offset e length
    [long]$offset = 0
    [long]$length = $fileSize
    $isRange = $false

    $rangeHdr = $req.Headers['Range']
    $qOffset  = $req.QueryString['offset']
    $qLength  = $req.QueryString['length']

    if ($qOffset -and $qLength) {
        $offset  = [long]$qOffset
        $length  = [long]$qLength
        $isRange = $true
    } elseif ($rangeHdr -and $rangeHdr -match 'bytes=(\d+)-(\d*)') {
        $offset  = [long]$Matches[1]
        $endByte = if ($Matches[2]) { [long]$Matches[2] } else { $fileSize - 1 }
        $length  = $endByte - $offset + 1
        $isRange = $true
    }

    # Clampar dentro dos limites
    $offset = [Math]::Max(0, [Math]::Min($offset, $fileSize))
    $length = [Math]::Max(0, [Math]::Min($length, $fileSize - $offset))
    $endByte = $offset + $length - 1

    if ($length -le 0) {
        $resp.StatusCode = 416
        $resp.Headers.Set('Content-Range', "bytes */$fileSize")
        $resp.Close()
        return
    }

    if ($isRange) {
        $resp.StatusCode = 206
        $resp.Headers.Set('Content-Range', "bytes $offset-$endByte/$fileSize")
    } else {
        $resp.StatusCode = 200
    }

    $resp.ContentLength64 = $length
    $resp.ContentType     = 'application/octet-stream'

    $swRead = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        Send-RangeData $ve $offset $length $resp.OutputStream
        $resp.OutputStream.Flush()
    } catch {
        Write-Log "FALHA na leitura de $name offset=$offset length=$length : $_" 'Red'
    } finally {
        $swRead.Stop()
        $throughputMBs = if ($swRead.ElapsedMilliseconds -gt 0) {
            [math]::Round($length / $swRead.ElapsedMilliseconds * 1000 / 1MB, 2)
        } else { '∞' }
        Write-Log ("READ $name  offset=$offset  length=$length  ${throughputMBs} MB/s  [$($ve.final_strategy)]") 'Cyan'
        $resp.Close()
    }
}

# ── Dispatcher ────────────────────────────────────────────────────────────────

function Dispatch-Request([System.Net.HttpListenerContext]$Ctx) {
    $req  = $Ctx.Request
    $resp = $Ctx.Response
    $method = $req.HttpMethod
    $path   = $req.Url.AbsolutePath.TrimEnd('/')
    if ($path -eq '') { $path = '/' }

    Write-Log "$method $path" 'Gray'

    try {
        if ($path -eq '/' -or $path -eq '/status') {
            Handle-Status $Ctx
        } elseif ($path -eq '/api/list') {
            Handle-List $Ctx
        } elseif ($path -match '^/api/meta/(.+)$') {
            Handle-Meta $Ctx $Matches[1]
        } elseif ($path -match '^/api/read/(.+)$') {
            Handle-Read $Ctx $Matches[1]
        } else {
            $routes = '{"routes":["/status","/api/list","/api/meta/{nome}","/api/read/{nome}"]}'
            Send-Json $resp $routes 404
        }
    } catch {
        $errMsg = Escape-Json "$_"
        try { Send-Json $resp "{`"error`":`"$errMsg`"}" 500 } catch {}
        Write-Log "ERRO no handler: $_" 'Red'
    }
}

# ── Inicializar listener ──────────────────────────────────────────────────────

$prefix = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
} catch {
    Write-Host "[VFS] ERRO ao iniciar listener em ${prefix}: $_" -ForegroundColor Red
    Write-Host "      Se a porta esta ocupada: netstat -ano | findstr :$Port" -ForegroundColor DarkYellow
    Write-Host "      Se permissao negada: netsh http add urlacl url=$prefix user=$env:USERNAME" -ForegroundColor DarkYellow
    exit 1
}

$script:startTime = Get-Date

Write-Host ''
Write-Host ("  Daemon ativo em $prefix") -ForegroundColor Green
Write-Host ''
Write-Host '  Comandos de teste (Terminal 2):' -ForegroundColor White
Write-Host ("    Invoke-RestMethod http://localhost:$Port/status")
Write-Host ("    Invoke-RestMethod http://localhost:$Port/api/list | Format-Table name, virtual_size_bytes, strategy")
Write-Host ("    Invoke-WebRequest 'http://localhost:$Port/api/read/alice_wonderland.txt?offset=0&length=100'")
Write-Host ''
Write-Host '  Pressione Ctrl+C para parar.' -ForegroundColor DarkGray
Write-Host ('─' * 78)
Write-Host ''

# ── Loop principal ────────────────────────────────────────────────────────────

try {
    while ($listener.IsListening) {
        $ctx = $null
        try {
            $ctx = $listener.GetContext()
        } catch [System.Net.HttpListenerException] {
            break   # listener foi parado (Ctrl+C)
        } catch {
            Write-Log "ERRO no GetContext: $_" 'Red'
            continue
        }
        Dispatch-Request $ctx
    }
} finally {
    if ($listener.IsListening) { $listener.Stop() }
    $listener.Close()

    $uptime = [int]((Get-Date) - $script:startTime).TotalSeconds
    Write-Host ''
    Write-Host ('─' * 78)
    Write-Host ("  Daemon encerrado. Uptime: ${uptime}s") -ForegroundColor DarkGray
    Write-Host ("  CAS Delta: 0 — nenhum byte escrito em objects/") -ForegroundColor DarkGray
    Write-Host ('=' * 78)
}
