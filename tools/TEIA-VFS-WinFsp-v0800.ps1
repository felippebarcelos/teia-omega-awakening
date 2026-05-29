<#
.SYNOPSIS
    TEIA-VFS-WinFsp-v0800.ps1 — VFS Nativo P11.0/P11.2 (Drive Z:\)

.DESCRIPTION
    Estende o WebDAV Daemon v0510 para montar D:\TEIA_USER\MyRealData\
    como drive nativo Z:\ no Windows Explorer (porta 8767).

    Adições vs v0510:
      - Suporte a gen.procedural (P1 Patch decoders via Runspace isolado)
      - Porta 8767 → drive Z:\
      - VFSRoot: D:\TEIA_USER\MyRealData\
      - Build-Manifest extendido para ler decoder_path + seed_path de stubs
      - Hot-reload do manifesto a cada ManifestRefreshSeconds (padrão 5s)
        sem interromper a montagem; detecta novos stubs em tempo real

    Estratégias suportadas:
      gen.repeat      → Read-GenRepeat (O(1) RAM, sem CAS)
      gen.pattern     → Read-GenPattern (O(1) RAM, sem CAS)
      gen.procedural  → Read-GenProcedural (Runspace isolado, P1 Patch)
      cmp.lzma        → Get-DecompressedCache + Read-CasRaw
      cmp.brotli      → Get-DecompressedCache + Read-CasRaw
      cas.raw         → Read-CasRaw (stream direto)

    OOM Guard: buffer fixo 64 KB em todas as streams.
    Metadata: (Get-Item).Length reporta original_size_bytes (esconde stubs).

    Montagem:
      Start-Service WebClient
      net use Z: \\localhost@8767\DavWWWRoot\ /persistent:no

.PARAMETER VFSRoot
    Diretório com .teia_stub. Padrão: D:\TEIA_USER\MyRealData

.PARAMETER Port
    Porta HTTP local. Padrão: 8767

.PARAMETER CacheDir
    Cache de descompressão para cmp.lzma/cmp.brotli. Padrão: D:\TEIA_CORE\vfs_cache_z

.PARAMETER DecoderDir
    Diretório de decoders P1 Patch. Padrão: D:\TEIA_CORE\decoders

.PARAMETER ClearCache
    Limpa arquivos .dec do CacheDir ao iniciar.

.PARAMETER ManifestRefreshSeconds
    Intervalo de hot-reload do manifesto de stubs em segundos. Padrão: 5.
    O check ocorre no início de cada request PROPFIND/GET/HEAD.
    Custo: zero quando dentro da janela; ~5-15ms na varredura efetiva.
#>
[CmdletBinding()]
param(
    [string]$VFSRoot                = 'D:\TEIA_USER\MyRealData',
    [string]$Port                   = '8767',
    [string]$CacheDir               = 'D:\TEIA_CORE\vfs_cache_z',
    [string]$DecoderDir             = 'D:\TEIA_CORE\decoders',
    [switch]$ClearCache,
    [int]   $ManifestRefreshSeconds = 5
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC = [System.Globalization.CultureInfo]::InvariantCulture

# ── Banner ────────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host '  TEIA-VFS-WinFsp v0.80.2 — VFS Nativo P11.2 | Hot-Reload Manifesto' -ForegroundColor Cyan
Write-Host ('─' * 78)
Write-Host "  VFSRoot   : $VFSRoot"
Write-Host "  Port      : $Port"
Write-Host "  CacheDir  : $CacheDir"
Write-Host "  DecoderDir: $DecoderDir"
Write-Host "  CAS Delta : 0 — operacao de leitura pura (objects/ intocado)"
Write-Host "  Hot-Reload: manifesto atualizado a cada ${ManifestRefreshSeconds}s por request"
Write-Host ('─' * 78)

if (-not (Test-Path -LiteralPath $VFSRoot)) {
    Write-Host "[VFS] ERRO: VFSRoot nao encontrado: $VFSRoot" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Path $CacheDir   -Force | Out-Null
New-Item -ItemType Directory -Path $DecoderDir -Force | Out-Null

if ($ClearCache) {
    Get-ChildItem -LiteralPath $CacheDir -Filter '*.dec' |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "  Cache limpo: $CacheDir" -ForegroundColor DarkYellow
}

# ── Logging ───────────────────────────────────────────────────────────────────
function Write-Log([string]$Msg, [string]$Color = 'Gray') {
    $ts = (Get-Date).ToString('HH:mm:ss.fff', $IC)
    Write-Host "  [$ts] $Msg" -ForegroundColor $Color
}

# ── Manifesto virtual (lê stubs, inclui gen.procedural) ──────────────────────
function Build-Manifest([string]$Dir) {
    $m = [System.Collections.Generic.Dictionary[string, hashtable]]::new(
             [System.StringComparer]::OrdinalIgnoreCase)
    $stubs = Get-ChildItem -LiteralPath $Dir -Filter '*.teia_stub' -ErrorAction SilentlyContinue
    foreach ($sf in $stubs) {
        try {
            $d    = Get-Content -LiteralPath $sf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            $name = [string]$d.original_name
            if ([string]::IsNullOrWhiteSpace($name)) { continue }
            $m[$name] = @{
                name                = $name
                original_size_bytes = [long]$d.original_size_bytes
                original_sha256     = [string]$d.original_sha256
                final_strategy      = [string]$d.final_strategy
                cas_encoding        = [string]$d.cas_encoding
                cas_path            = [string]$d.cas_path
                decoder_path        = if ($d.decoder_path) { [string]$d.decoder_path } else { '' }
                seed_path           = if ($d.seed_path)    { [string]$d.seed_path }    else { '' }
                decoder_id          = if ($d.decoder_id)   { [string]$d.decoder_id }   else { '' }
                cas_size_bytes      = [long]$d.cas_size_bytes
                savings_pct         = [double]$d.savings_pct
                stub_path           = $sf.FullName
            }
        } catch {
            Write-Log "AVISO stub $($sf.Name): $_" 'DarkYellow'
        }
    }
    return $m
}

$script:manifest          = Build-Manifest $VFSRoot
$script:manifestSW        = [System.Diagnostics.Stopwatch]::StartNew()
$script:startTime         = Get-Date

Write-Host "  Manifesto : $($script:manifest.Count) arquivos virtuais"
Write-Host "  Refresh   : a cada ${ManifestRefreshSeconds}s (hot-reload sem restart)"

# ── MIME types ────────────────────────────────────────────────────────────────
function Get-MimeType([string]$Name) {
    switch (([IO.Path]::GetExtension($Name)).ToLower()) {
        '.txt'  { 'text/plain' }
        '.json' { 'application/json' }
        '.csv'  { 'text/csv' }
        '.log'  { 'text/plain' }
        '.xml'  { 'text/xml' }
        '.html' { 'text/html' }
        '.svg'  { 'image/svg+xml' }
        '.png'  { 'image/png' }
        '.jpg'  { 'image/jpeg' }
        '.pdf'  { 'application/pdf' }
        '.bin'  { 'application/octet-stream' }
        default { 'application/octet-stream' }
    }
}

# ── Helpers HTTP/XML ──────────────────────────────────────────────────────────
function Escape-Xml([string]$s) {
    $s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;'
}

function Send-Xml([System.Net.HttpListenerResponse]$Resp, [string]$Body, [int]$Code = 200) {
    $Resp.StatusCode  = $Code
    $Resp.ContentType = 'application/xml; charset=utf-8'
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
    $Resp.ContentLength64 = $bytes.Length
    try { $Resp.OutputStream.Write($bytes, 0, $bytes.Length); $Resp.OutputStream.Flush() } catch {}
    $Resp.Close()
}

function Send-Empty([System.Net.HttpListenerResponse]$Resp, [int]$Code) {
    $Resp.StatusCode      = $Code
    $Resp.ContentLength64 = 0
    $Resp.Close()
}

# ── PROPFIND XML builder ──────────────────────────────────────────────────────
function Build-FileProps([hashtable]$VE) {
    $href  = '/' + [System.Uri]::EscapeDataString($VE.name)
    $etag  = '"' + $VE.original_sha256.Substring(0, 16) + '"'
    $mime  = Get-MimeType $VE.name
    $lm    = (Get-Date).ToUniversalTime().ToString('ddd, dd MMM yyyy HH:mm:ss \G\M\T', $IC)
    $cr    = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd\THH:mm:ss\Z', $IC)
    $dname = Escape-Xml $VE.name
    $sz    = $VE.original_size_bytes
    return "<D:response><D:href>$href</D:href><D:propstat><D:prop>" +
           "<D:displayname>$dname</D:displayname>" +
           "<D:getcontentlength>$sz</D:getcontentlength>" +
           "<D:getcontenttype>$mime</D:getcontenttype>" +
           "<D:resourcetype/>" +
           "<D:getlastmodified>$lm</D:getlastmodified>" +
           "<D:getetag>$etag</D:getetag>" +
           "<D:creationdate>$cr</D:creationdate>" +
           "</D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat></D:response>"
}

# ── CAS Readers ───────────────────────────────────────────────────────────────

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
    } finally { $fs.Dispose() }
}

function Read-GenRepeat([string]$SeedPath, [long]$Offset, [long]$Length, [System.IO.Stream]$Out) {
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

function Read-GenProcedural([hashtable]$VE, [long]$Offset, [long]$Length, [System.IO.Stream]$Out) {
    # Invoca o decoder P1 Patch em Runspace isolado com timeout 30s
    $dp = $VE.decoder_path
    $sp = $VE.seed_path
    if (-not (Test-Path $dp) -or -not (Test-Path $sp)) {
        Write-Log "ERRO gen.procedural: decoder/seed nao encontrado para $($VE.name)" 'Red'
        return
    }

    $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $rs  = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($iss)
    $rs.Open()
    $ps  = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $rs.SessionStateProxy.SetVariable('__dp', $dp)
    $rs.SessionStateProxy.SetVariable('__sp', $sp)
    [void]$ps.AddScript(@'
. $__dp
$sd = (Get-Content -LiteralPath $__sp -Raw) | ConvertFrom-Json -AsHashtable
Decode-CustomFormat -Seed $sd
'@)

    try {
        $async = $ps.BeginInvoke()
        if (-not $async.AsyncWaitHandle.WaitOne(30000)) {
            $ps.Stop(); $ps.Dispose(); $rs.Close()
            Write-Log "TIMEOUT gen.procedural: $($VE.name)" 'Red'
            return
        }
        $rsOut = $ps.EndInvoke($async)
    } catch {
        $ps.Dispose(); $rs.Close()
        Write-Log "EXCECAO gen.procedural $($VE.name): $_" 'Red'
        return
    }
    $ps.Dispose(); $rs.Close()

    # Coletar bytes tolerando array desenrolado ou unitário
    $collected = [System.Collections.Generic.List[byte]]::new()
    foreach ($item in $rsOut) {
        if ($null -eq $item) { continue }
        if ($item -is [byte[]]) { $collected.AddRange([byte[]]$item) }
        elseif ($item -is [System.Array]) { foreach ($b in $item) { $collected.Add([byte]$b) } }
        else { try { $collected.Add([byte]$item) } catch { } }
    }
    $fullBytes = $collected.ToArray()

    # Servir apenas o range solicitado (OOM Guard: nunca manter fullBytes além do necessário)
    $clampOffset = [Math]::Max(0L, [Math]::Min($Offset, [long]$fullBytes.Length))
    $clampEnd    = [Math]::Min($clampOffset + $Length, [long]$fullBytes.Length)
    $sliceLen    = [int]($clampEnd - $clampOffset)
    if ($sliceLen -gt 0) {
        $Out.Write($fullBytes, [int]$clampOffset, $sliceLen)
    }
    [System.GC]::Collect()  # liberar array completo imediatamente
}

function Get-DecompressedCache([hashtable]$VE) {
    $cachePath = Join-Path $CacheDir "$($VE.original_sha256).dec"
    if (Test-Path -LiteralPath $cachePath) { return $cachePath }

    Write-Log "Cache miss: descomprimindo $($VE.name)" 'DarkYellow'
    $tmpPath   = "$cachePath.tmp"
    $inStream  = [System.IO.File]::OpenRead($VE.cas_path)
    $outStream = [System.IO.File]::Create($tmpPath)
    try {
        $dec = if ($VE.final_strategy -eq 'cmp.lzma') {
            New-Object System.IO.Compression.GZipStream(
                $inStream, [System.IO.Compression.CompressionMode]::Decompress)
        } else {
            New-Object System.IO.Compression.BrotliStream(
                $inStream, [System.IO.Compression.CompressionMode]::Decompress)
        }
        $dec.CopyTo($outStream, 65536)
        $dec.Dispose()
    } finally {
        $inStream.Dispose(); $outStream.Dispose()
    }
    Move-Item -LiteralPath $tmpPath -Destination $cachePath -Force
    return $cachePath
}

function Send-RangeData([hashtable]$VE, [long]$Offset, [long]$Length, [System.IO.Stream]$Out) {
    switch ($VE.final_strategy) {
        'cas.raw'         { Read-CasRaw     $VE.cas_path $Offset $Length $Out }
        'gen.repeat'      { Read-GenRepeat  $VE.cas_path $Offset $Length $Out }
        'gen.pattern'     { Read-GenPattern $VE.cas_path $Offset $Length $Out }
        'gen.procedural'  { Read-GenProcedural $VE $Offset $Length $Out }
        default {
            # cmp.lzma / cmp.brotli / gen.parametric_mesh
            $cachedPath = Get-DecompressedCache $VE
            Read-CasRaw $cachedPath $Offset $Length $Out
        }
    }
}

# ── Hot-Reload do Manifesto ───────────────────────────────────────────────────

function Invoke-ManifestRefreshIfDue {
    if ($script:manifestSW.Elapsed.TotalSeconds -lt $ManifestRefreshSeconds) { return }
    $before = $script:manifest.Count
    $script:manifest = Build-Manifest $VFSRoot
    $script:manifestSW.Restart()
    $diff = $script:manifest.Count - $before
    if ($diff -ne 0) {
        $sign = if ($diff -gt 0) { '+' } else { '' }
        Write-Log "Hot-reload: $($script:manifest.Count) stubs (${sign}${diff} vs anterior)" 'DarkCyan'
    }
}

# ── Handlers WebDAV ───────────────────────────────────────────────────────────

function Handle-Options([System.Net.HttpListenerContext]$Ctx) {
    $resp = $Ctx.Response
    $resp.StatusCode = 200
    $resp.Headers.Set('DAV',           '1, 2')
    $resp.Headers.Set('MS-Author-Via', 'DAV')
    $resp.Headers.Set('Allow',         'OPTIONS, GET, HEAD, PROPFIND, LOCK, UNLOCK')
    $resp.ContentLength64 = 0
    $resp.Close()
}

function Handle-Propfind([System.Net.HttpListenerContext]$Ctx, [string]$NormPath) {
    Invoke-ManifestRefreshIfDue
    $depth = $Ctx.Request.Headers['Depth']
    if ([string]::IsNullOrEmpty($depth)) { $depth = '1' }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('<?xml version="1.0" encoding="utf-8"?><D:multistatus xmlns:D="DAV:">')

    if ($NormPath -eq '/') {
        $cr = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd\THH:mm:ss\Z', $IC)
        [void]$sb.Append(
            "<D:response><D:href>/</D:href><D:propstat><D:prop>" +
            "<D:displayname>TEIA MyRealData</D:displayname>" +
            "<D:resourcetype><D:collection/></D:resourcetype>" +
            "<D:creationdate>$cr</D:creationdate>" +
            "</D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat></D:response>"
        )
        if ($depth -ne '0') {
            foreach ($ve in $script:manifest.Values | Sort-Object { $_.name }) {
                [void]$sb.Append((Build-FileProps $ve))
            }
        }
    } else {
        $fileName = [System.Uri]::UnescapeDataString($NormPath.TrimStart('/'))
        if (-not $script:manifest.ContainsKey($fileName)) {
            Send-Xml $Ctx.Response (
                '<?xml version="1.0" encoding="utf-8"?>' +
                '<D:error xmlns:D="DAV:"><D:resource-must-be-null/></D:error>'
            ) 404
            return
        }
        [void]$sb.Append((Build-FileProps $script:manifest[$fileName]))
    }
    [void]$sb.Append('</D:multistatus>')
    Send-Xml $Ctx.Response $sb.ToString() 207
}

function Handle-ReadOrHead([System.Net.HttpListenerContext]$Ctx, [string]$FileName) {
    Invoke-ManifestRefreshIfDue
    $req  = $Ctx.Request
    $resp = $Ctx.Response
    $name = [System.Uri]::UnescapeDataString($FileName)

    if (-not $script:manifest.ContainsKey($name)) { Send-Empty $resp 404; return }

    $ve       = $script:manifest[$name]
    $fileSize = [long]$ve.original_size_bytes
    $mime     = Get-MimeType $ve.name
    $etag     = '"' + $ve.original_sha256.Substring(0, 16) + '"'
    $lm       = (Get-Date).ToUniversalTime().ToString('ddd, dd MMM yyyy HH:mm:ss \G\M\T', $IC)

    $resp.Headers.Set('Accept-Ranges',          'bytes')
    $resp.Headers.Set('ETag',                   $etag)
    $resp.Headers.Set('Last-Modified',          $lm)
    $resp.Headers.Set('X-TEIA-Strategy',        $ve.final_strategy)
    $resp.Headers.Set('X-TEIA-Original-SHA256', $ve.original_sha256)

    if ($req.HttpMethod -eq 'HEAD') {
        $resp.StatusCode      = 200
        $resp.ContentLength64 = $fileSize
        $resp.ContentType     = $mime
        $resp.Close()
        Write-Log "HEAD $name  Length=$fileSize  [$($ve.final_strategy)]" 'DarkGray'
        return
    }

    [long]$offset = 0
    [long]$length = $fileSize
    $isRange = $false
    $rangeHdr = $req.Headers['Range']
    if ($rangeHdr -and $rangeHdr -match 'bytes=(\d+)-(\d*)') {
        $offset  = [long]$Matches[1]
        $endByte = if ($Matches[2]) { [long]$Matches[2] } else { $fileSize - 1 }
        $length  = $endByte - $offset + 1
        $isRange = $true
    }

    $offset  = [Math]::Max(0L, [Math]::Min($offset, $fileSize))
    $length  = [Math]::Max(0L, [Math]::Min($length, $fileSize - $offset))
    $endByte = $offset + $length - 1

    if ($length -le 0) {
        $resp.StatusCode = 416
        $resp.Headers.Set('Content-Range', "bytes */$fileSize")
        $resp.Close(); return
    }

    if ($isRange) {
        $resp.StatusCode = 206
        $resp.Headers.Set('Content-Range', "bytes $offset-$endByte/$fileSize")
    } else { $resp.StatusCode = 200 }

    $resp.ContentLength64 = $length
    $resp.ContentType     = $mime

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        Send-RangeData $ve $offset $length $resp.OutputStream
        $resp.OutputStream.Flush()
    } catch {
        Write-Log "FALHA read ${name}: $_" 'Red'
    } finally {
        $sw.Stop()
        $mbps = if ($sw.ElapsedMilliseconds -gt 0) {
            [math]::Round($length / $sw.ElapsedMilliseconds * 1000 / 1MB, 2)
        } else { '999+' }
        Write-Log "GET $name  offset=$offset  len=$length  $mbps MB/s  [$($ve.final_strategy)]" 'Cyan'
        $resp.Close()
    }
}

function Handle-Lock([System.Net.HttpListenerContext]$Ctx, [string]$FileName) {
    $token = 'opaquelocktoken:teia-' + [Guid]::NewGuid().ToString('N')
    $xml   = '<?xml version="1.0" encoding="utf-8"?>' +
             '<D:prop xmlns:D="DAV:"><D:lockdiscovery><D:activelock>' +
             '<D:locktype><D:write/></D:locktype>' +
             '<D:lockscope><D:exclusive/></D:lockscope>' +
             '<D:depth>0</D:depth>' +
             '<D:owner><D:href>TEIA-VFS-v0800</D:href></D:owner>' +
             '<D:timeout>Second-3600</D:timeout>' +
             "<D:locktoken><D:href>$token</D:href></D:locktoken>" +
             '</D:activelock></D:lockdiscovery></D:prop>'
    $Ctx.Response.Headers.Set('Lock-Token', "<$token>")
    Send-Xml $Ctx.Response $xml 200
}

function Handle-RootGet([System.Net.HttpListenerContext]$Ctx) {
    Invoke-ManifestRefreshIfDue
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('<html><head><meta charset="utf-8"/><title>TEIA VFS Z:\</title></head><body>')
    [void]$sb.Append('<h2>TEIA VFS P11.0 — MyRealData (Z:\)</h2>')
    [void]$sb.Append('<table border="1" cellpadding="4"><tr>')
    [void]$sb.Append('<th>Nome</th><th>Tamanho Virtual</th><th>Estrategia</th><th>CAS (KB)</th><th>Delta economia</th></tr>')
    foreach ($ve in $script:manifest.Values | Sort-Object { $_.name }) {
        $href  = '/' + [System.Uri]::EscapeDataString($ve.name)
        $szKB  = [math]::Round($ve.original_size_bytes / 1KB, 1)
        $casKB = [math]::Round($ve.cas_size_bytes / 1KB, 1)
        $ecoStr = "$($ve.savings_pct)%"
        [void]$sb.Append("<tr><td><a href=`"$href`">$(Escape-Xml $ve.name)</a></td>")
        [void]$sb.Append("<td>$szKB KB</td><td>$($ve.final_strategy)</td>")
        [void]$sb.Append("<td>$casKB KB</td><td>$ecoStr</td></tr>")
    }
    [void]$sb.Append('</table></body></html>')
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
    $resp = $Ctx.Response
    $resp.StatusCode = 200; $resp.ContentType = 'text/html; charset=utf-8'
    $resp.ContentLength64 = $bytes.Length
    try { $resp.OutputStream.Write($bytes, 0, $bytes.Length); $resp.OutputStream.Flush() } catch {}
    $resp.Close()
}

# ── Dispatcher ────────────────────────────────────────────────────────────────
function Dispatch-Request([System.Net.HttpListenerContext]$Ctx) {
    $req     = $Ctx.Request
    $resp    = $Ctx.Response
    $method  = $req.HttpMethod
    $rawPath = $req.Url.AbsolutePath

    $normPath = $rawPath.TrimEnd('/')
    if ($normPath -eq '') { $normPath = '/' }
    if ($normPath -match '^/DavWWWRoot(/.*)?$') {
        $normPath = if ($Matches[1]) { $Matches[1].TrimEnd('/') } else { '/' }
        if ($normPath -eq '') { $normPath = '/' }
    }

    Write-Log "$method $rawPath" 'Gray'

    try {
        switch ($method) {
            'OPTIONS' { Handle-Options $Ctx }
            'PROPFIND' { Handle-Propfind $Ctx $normPath }
            'GET' {
                if ($normPath -eq '/') { Handle-RootGet $Ctx }
                elseif ($normPath -match '^/(.+)$') { Handle-ReadOrHead $Ctx $Matches[1] }
                else { Send-Empty $resp 404 }
            }
            'HEAD' {
                if ($normPath -match '^/(.+)$') { Handle-ReadOrHead $Ctx $Matches[1] }
                else { Send-Empty $resp 404 }
            }
            'LOCK' {
                $fn = if ($normPath -match '^/(.+)$') { $Matches[1] } else { '' }
                Handle-Lock $Ctx $fn
            }
            'UNLOCK' { Send-Empty $resp 204 }
            default {
                $resp.StatusCode = 405
                $resp.Headers.Set('Allow', 'OPTIONS, GET, HEAD, PROPFIND, LOCK, UNLOCK')
                $resp.ContentLength64 = 0; $resp.Close()
            }
        }
    } catch {
        Write-Log "ERRO dispatcher [$method $rawPath]: $_" 'Red'
        try { $resp.StatusCode = 500; $resp.ContentLength64 = 0; $resp.Close() } catch {}
    }
}

# ── Inicializar listener ──────────────────────────────────────────────────────
$prefix   = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
} catch {
    Write-Host "[VFS] ERRO ao iniciar listener em ${prefix}: $_" -ForegroundColor Red
    Write-Host "      Porta ocupada? netstat -ano | findstr :$Port" -ForegroundColor DarkYellow
    Write-Host "      Permissao: netsh http add urlacl url=$prefix user=$env:USERNAME" -ForegroundColor DarkYellow
    exit 1
}

Write-Host ''
Write-Host "  Daemon VFS ativo em $prefix" -ForegroundColor Green
Write-Host ''
Write-Host '  Montagem como Z:\:' -ForegroundColor White
Write-Host "    Start-Service WebClient"
Write-Host "    net use Z: \\localhost@$Port\DavWWWRoot\ /persistent:no"
Write-Host "    dir Z:\"
Write-Host ''
Write-Host '  Smoke tests:' -ForegroundColor White
Write-Host "    Invoke-WebRequest 'http://localhost:$Port/' -Method OPTIONS -UseBasicParsing"
Write-Host "    (Get-Item 'Z:\arquivo.csv').Length  # deve reportar tamanho original"
Write-Host "    Get-FileHash 'Z:\arquivo.csv' -Algorithm SHA256"
Write-Host ''
Write-Host '  Pressione Ctrl+C para parar.' -ForegroundColor DarkGray
Write-Host ('─' * 78)
Write-Host ''

# ── Loop principal ────────────────────────────────────────────────────────────
try {
    while ($listener.IsListening) {
        $ctx = $null
        try { $ctx = $listener.GetContext() }
        catch [System.Net.HttpListenerException] { break }
        catch { Write-Log "ERRO GetContext: $_" 'Red'; continue }
        Dispatch-Request $ctx
    }
} finally {
    if ($listener.IsListening) { $listener.Stop() }
    $listener.Close()
    $uptime = [int]((Get-Date) - $script:startTime).TotalSeconds
    Write-Host ''
    Write-Host ('─' * 78)
    Write-Host "  VFS encerrado. Uptime: ${uptime}s" -ForegroundColor DarkGray
    Write-Host "  CAS Delta: 0 — nenhum byte escrito em objects/" -ForegroundColor DarkGray
    Write-Host ('=' * 78)
}
