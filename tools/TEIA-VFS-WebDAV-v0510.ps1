<#
.SYNOPSIS
    TEIA-VFS-WebDAV-v0510.ps1 — WebDAV Daemon P8.1 para montagem como T:\

.DESCRIPTION
    Extende o protocolo P8.0 com WebDAV completo (RFC 4918).
    Windows monta via: net use T: \\localhost@8766\DavWWWRoot\ /persistent:no

    Metodos WebDAV implementados:
      OPTIONS   -> DAV: 1, 2 | MS-Author-Via: DAV | Allow: ...
      PROPFIND  -> 207 Multi-Status XML com original_size_bytes por arquivo
      GET+Range -> stream chunk-on-demand do CAS (206 Partial Content)
      HEAD      -> Content-Length = original_size_bytes
      LOCK      -> dummy lock token (VFS read-only)
      UNLOCK    -> 204 No Content

    Invariantes (identicos ao P8.0):
      CAS Delta = 0 -- objects/ intocado, zero bytes escritos
      OOM Guard  -- buffer fixo 64 KB em todas as streams
      Stubs      -- nenhum .teia_stub modificado
      Cache      -- descompressao isolada em CacheDir/{sha256}.dec

    Montagem Windows:
      Start-Service WebClient
      net use T: \\localhost@8766\DavWWWRoot\ /persistent:no
      dir T:\

.PARAMETER VFSRoot
    Diretorio com .teia_stub. Padrao: D:\TEIA_USER\ActiveDrive_Test

.PARAMETER Port
    Porta HTTP local. Padrao: 8766

.PARAMETER CacheDir
    Cache de descompressao. Padrao: D:\TEIA_CORE\vfs_cache

.PARAMETER ClearCache
    Limpa .dec do CacheDir ao iniciar.
#>
[CmdletBinding()]
param(
    [string]$VFSRoot   = 'D:\TEIA_USER\ActiveDrive_Test',
    [string]$Port      = '8766',
    [string]$CacheDir  = 'D:\TEIA_CORE\vfs_cache',
    [switch]$ClearCache
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC = [System.Globalization.CultureInfo]::InvariantCulture

# ── Banner ────────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host '  TEIA-VFS-WebDAV v0.51.0 — WebDAV Daemon P8.1 (montagem T:\ nativa)' -ForegroundColor Cyan
Write-Host ('─' * 78)
Write-Host "  VFSRoot  : $VFSRoot"
Write-Host "  Port     : $Port"
Write-Host "  CacheDir : $CacheDir"
Write-Host "  CAS Delta: 0 -- operacao de leitura pura (objects/ intocado)"
Write-Host ('─' * 78)

# ── Validacoes ────────────────────────────────────────────────────────────────────

if (-not (Test-Path -LiteralPath $VFSRoot)) {
    Write-Host "[DAV] ERRO: VFSRoot nao encontrado: $VFSRoot" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null

if ($ClearCache) {
    Get-ChildItem -LiteralPath $CacheDir -Filter '*.dec' |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "  Cache limpo: $CacheDir" -ForegroundColor DarkYellow
}

# ── Logging ───────────────────────────────────────────────────────────────────────

function Write-Log([string]$Msg, [string]$Color = 'Gray') {
    $ts = (Get-Date).ToString('HH:mm:ss.fff', $IC)
    Write-Host "  [$ts] $Msg" -ForegroundColor $Color
}

# ── Manifesto virtual ─────────────────────────────────────────────────────────────

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
            Write-Log "AVISO: stub $($sf.Name): $_" 'DarkYellow'
        }
    }
    return $m
}

$script:manifest  = Build-Manifest $VFSRoot
$script:startTime = Get-Date

Write-Host "  Manifesto  : $($script:manifest.Count) arquivos virtuais"

# ── MIME types ────────────────────────────────────────────────────────────────────

function Get-MimeType([string]$Name) {
    switch (([IO.Path]::GetExtension($Name)).ToLower()) {
        '.txt'  { return 'text/plain' }
        '.json' { return 'application/json' }
        '.obj'  { return 'model/obj' }
        '.log'  { return 'text/plain' }
        '.html' { return 'text/html' }
        '.xml'  { return 'text/xml' }
        '.png'  { return 'image/png' }
        '.jpg'  { return 'image/jpeg' }
        '.pdf'  { return 'application/pdf' }
        '.bin'  { return 'application/octet-stream' }
        default { return 'application/octet-stream' }
    }
}

# ── Helpers HTTP/XML ──────────────────────────────────────────────────────────────

function Escape-Xml([string]$s) {
    $s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;'
}

function Escape-Json([string]$s) {
    $s -replace '\\','\\' -replace '"','\"' -replace "`n",'\n' -replace "`r",'\r'
}

function Send-Xml([System.Net.HttpListenerResponse]$Resp, [string]$Body, [int]$Code = 200) {
    $Resp.StatusCode  = $Code
    $Resp.ContentType = 'application/xml; charset=utf-8'
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
    $Resp.ContentLength64 = $bytes.Length
    try {
        $Resp.OutputStream.Write($bytes, 0, $bytes.Length)
        $Resp.OutputStream.Flush()
    } catch {}
    $Resp.Close()
}

function Send-Empty([System.Net.HttpListenerResponse]$Resp, [int]$Code) {
    $Resp.StatusCode      = $Code
    $Resp.ContentLength64 = 0
    $Resp.Close()
}

# ── PROPFIND XML builder ──────────────────────────────────────────────────────────

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

# ── CAS Readers (identicos ao v0500) ─────────────────────────────────────────────

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

function Get-DecompressedCache([hashtable]$VE) {
    $cachePath = Join-Path $CacheDir "$($VE.original_sha256).dec"
    if (Test-Path -LiteralPath $cachePath) { return $cachePath }

    Write-Log "Cache miss: descomprimindo $($VE.name) -> $(Split-Path $cachePath -Leaf)" 'DarkYellow'
    $tmpPath   = "$cachePath.tmp"
    $inStream  = [System.IO.File]::OpenRead($VE.cas_path)
    $outStream = [System.IO.File]::Create($tmpPath)
    try {
        if ($VE.final_strategy -eq 'cmp.lzma') {
            $dec = New-Object System.IO.Compression.GZipStream(
                       $inStream, [System.IO.Compression.CompressionMode]::Decompress)
        } else {
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
    Write-Log "Cache criado: $(Split-Path $cachePath -Leaf)" 'DarkGray'
    return $cachePath
}

function Send-RangeData([hashtable]$VE, [long]$Offset, [long]$Length, [System.IO.Stream]$Out) {
    switch ($VE.final_strategy) {
        'cas.raw'     { Read-CasRaw    $VE.cas_path $Offset $Length $Out }
        'gen.repeat'  { Read-GenRepeat $VE.cas_path $Offset $Length $Out }
        'gen.pattern' { Read-GenPattern $VE.cas_path $Offset $Length $Out }
        default {
            # cmp.lzma / cmp.brotli / gen.parametric_mesh
            $cachedPath = Get-DecompressedCache $VE
            Read-CasRaw $cachedPath $Offset $Length $Out
        }
    }
}

# ── Handlers WebDAV ───────────────────────────────────────────────────────────────

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
    $req   = $Ctx.Request
    $depth = $req.Headers['Depth']
    if ([string]::IsNullOrEmpty($depth)) { $depth = '1' }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('<?xml version="1.0" encoding="utf-8"?><D:multistatus xmlns:D="DAV:">')

    if ($NormPath -eq '/') {
        $cr = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd\THH:mm:ss\Z', $IC)
        [void]$sb.Append(
            "<D:response><D:href>/</D:href><D:propstat><D:prop>" +
            "<D:displayname>TEIA VFS</D:displayname>" +
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
    $req  = $Ctx.Request
    $resp = $Ctx.Response

    $name = [System.Uri]::UnescapeDataString($FileName)
    if (-not $script:manifest.ContainsKey($name)) {
        Send-Empty $resp 404
        return
    }

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
        Write-Log "HEAD $name  Content-Length=$fileSize  [$($ve.final_strategy)]" 'DarkGray'
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

    $offset  = [Math]::Max(0, [Math]::Min($offset, $fileSize))
    $length  = [Math]::Max(0, [Math]::Min($length, $fileSize - $offset))
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
        } else { '∞' }
        Write-Log "GET $name  offset=$offset  len=$length  ${mbps} MB/s  [$($ve.final_strategy)]" 'Cyan'
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
             '<D:owner><D:href>TEIA-VFS</D:href></D:owner>' +
             '<D:timeout>Second-3600</D:timeout>' +
             "<D:locktoken><D:href>$token</D:href></D:locktoken>" +
             '</D:activelock></D:lockdiscovery></D:prop>'
    $Ctx.Response.Headers.Set('Lock-Token', "<$token>")
    Send-Xml $Ctx.Response $xml 200
    Write-Log "LOCK $FileName -> $($token.Substring(0,36))..." 'DarkGray'
}

function Handle-RootGet([System.Net.HttpListenerContext]$Ctx) {
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('<html><head><meta charset="utf-8"/></head><body>')
    [void]$sb.Append('<h2>TEIA VFS WebDAV P8.1</h2><table border="1" cellpadding="4">')
    [void]$sb.Append('<tr><th>Nome</th><th>Tamanho Virtual</th><th>Estrategia</th><th>CAS (KB)</th></tr>')
    foreach ($ve in $script:manifest.Values | Sort-Object { $_.name }) {
        $href  = '/' + [System.Uri]::EscapeDataString($ve.name)
        $szKB  = [math]::Round($ve.original_size_bytes / 1KB, 1)
        $casKB = [math]::Round($ve.cas_size_bytes / 1KB, 1)
        [void]$sb.Append("<tr><td><a href=`"$href`">$(Escape-Xml $ve.name)</a></td>")
        [void]$sb.Append("<td>${szKB} KB</td><td>$($ve.final_strategy)</td><td>${casKB} KB</td></tr>")
    }
    [void]$sb.Append('</table></body></html>')
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
    $resp = $Ctx.Response
    $resp.StatusCode      = 200
    $resp.ContentType     = 'text/html; charset=utf-8'
    $resp.ContentLength64 = $bytes.Length
    try { $resp.OutputStream.Write($bytes, 0, $bytes.Length); $resp.OutputStream.Flush() } catch {}
    $resp.Close()
}

# ── Dispatcher ────────────────────────────────────────────────────────────────────

function Dispatch-Request([System.Net.HttpListenerContext]$Ctx) {
    $req    = $Ctx.Request
    $resp   = $Ctx.Response
    $method = $req.HttpMethod
    $rawPath = $req.Url.AbsolutePath

    # Normalizar: strip trailing slash (exceto raiz) e /DavWWWRoot prefix (quirk Windows UNC)
    $normPath = $rawPath.TrimEnd('/')
    if ($normPath -eq '') { $normPath = '/' }
    if ($normPath -match '^/DavWWWRoot(/.*)?$') {
        $normPath = if ($Matches[1]) { $Matches[1].TrimEnd('/') } else { '/' }
        if ($normPath -eq '') { $normPath = '/' }
    }

    Write-Log "$method $rawPath" 'Gray'

    try {
        switch ($method) {
            'OPTIONS' {
                Handle-Options $Ctx
            }
            'PROPFIND' {
                Handle-Propfind $Ctx $normPath
            }
            'GET' {
                if ($normPath -eq '/') {
                    Handle-RootGet $Ctx
                } elseif ($normPath -match '^/(.+)$') {
                    Handle-ReadOrHead $Ctx $Matches[1]
                } else {
                    Send-Empty $resp 404
                }
            }
            'HEAD' {
                if ($normPath -match '^/(.+)$') {
                    Handle-ReadOrHead $Ctx $Matches[1]
                } else {
                    Send-Empty $resp 404
                }
            }
            'LOCK' {
                $fn = if ($normPath -match '^/(.+)$') { $Matches[1] } else { '' }
                Handle-Lock $Ctx $fn
            }
            'UNLOCK' {
                Send-Empty $resp 204
            }
            default {
                $resp.StatusCode = 405
                $resp.Headers.Set('Allow', 'OPTIONS, GET, HEAD, PROPFIND, LOCK, UNLOCK')
                $resp.ContentLength64 = 0
                $resp.Close()
            }
        }
    } catch {
        Write-Log "ERRO dispatcher [$method $rawPath]: $_" 'Red'
        try { $resp.StatusCode = 500; $resp.ContentLength64 = 0; $resp.Close() } catch {}
    }
}

# ── Inicializar listener ──────────────────────────────────────────────────────────

$prefix = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
} catch {
    Write-Host "[DAV] ERRO ao iniciar listener em ${prefix}: $_" -ForegroundColor Red
    Write-Host "      Porta ocupada? netstat -ano | findstr :$Port" -ForegroundColor DarkYellow
    Write-Host "      Permissao negada? netsh http add urlacl url=$prefix user=$env:USERNAME" -ForegroundColor DarkYellow
    exit 1
}

Write-Host ''
Write-Host "  Daemon WebDAV ativo em $prefix" -ForegroundColor Green
Write-Host ''
Write-Host '  Montagem como T:\:' -ForegroundColor White
Write-Host "    Start-Service WebClient"
Write-Host "    net use T: \\localhost@$Port\DavWWWRoot\ /persistent:no"
Write-Host "    dir T:\"
Write-Host "    type T:\alice_wonderland.txt"
Write-Host ''
Write-Host '  Smoke tests (Terminal 2):' -ForegroundColor White
Write-Host "    Invoke-WebRequest 'http://localhost:$Port/' -Method OPTIONS -UseBasicParsing"
Write-Host "    Invoke-WebRequest 'http://localhost:$Port/' -Method PROPFIND -UseBasicParsing -Headers @{Depth='1'}"
Write-Host "    Invoke-WebRequest 'http://localhost:$Port/alice_wonderland.txt' -Method HEAD -UseBasicParsing"
Write-Host ''
Write-Host '  Pressione Ctrl+C para parar.' -ForegroundColor DarkGray
Write-Host ('─' * 78)
Write-Host ''

# ── Loop principal ────────────────────────────────────────────────────────────────

try {
    while ($listener.IsListening) {
        $ctx = $null
        try {
            $ctx = $listener.GetContext()
        } catch [System.Net.HttpListenerException] {
            break
        } catch {
            Write-Log "ERRO GetContext: $_" 'Red'
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
    Write-Host "  Daemon encerrado. Uptime: ${uptime}s" -ForegroundColor DarkGray
    Write-Host "  CAS Delta: 0 -- nenhum byte escrito em objects/" -ForegroundColor DarkGray
    Write-Host ('=' * 78)
}
