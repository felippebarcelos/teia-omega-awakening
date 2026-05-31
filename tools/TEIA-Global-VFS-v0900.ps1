<#
.SYNOPSIS
    TEIA-Global-VFS-v0900.ps1 — Omni-VFS Global com Chunk-On-Demand Nativo (Drive T:\)
.DESCRIPTION
    Daemon WebDAV (porta 8769) que monta T:\ com dois planos de dados:

    PLANO A — gen.procedural.native (T:\lunatic\Syslog_Lunatic.log)
        Computa apenas os bytes solicitados via tabela de offsets de linhas pré-calculada.
        O(chunk_size) tempo, O(1) RAM. Alvo: <50ms por leitura de 64 KB.
        Regra Write==Read: bytes derivados deterministicamente do SHA-256 original.

    PLANO B — estratégias herdadas do v0800 (stubs de D:\TEIA_USER\Managed_Zone\)
        gen.repeat / gen.pattern / gen.procedural / cmp.lzma / cmp.brotli / cas.raw

    Montagem:
        Start-Service WebClient
        net use T: \\localhost@8769\DavWWWRoot\ /persistent:no
#>
[CmdletBinding()]
param(
    [string]$VFSRoot    = 'D:\TEIA_USER\Managed_Zone',
    [string]$Port       = '8769',
    [string]$CacheDir   = 'D:\TEIA_CORE\vfs_cache_t',
    [string]$DecoderDir = 'D:\TEIA_CORE\decoders',
    [switch]$ClearCache,
    [int]   $ManifestRefreshSeconds = 5
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC = [System.Globalization.CultureInfo]::InvariantCulture

# ── Constantes Lunatic ────────────────────────────────────────────────────────

$script:L_LEVELS  = @('INFO','WARN','ERROR','DEBUG')
$script:L_HOSTS   = @('api-01','api-02','api-03','worker-01','worker-02')
$script:L_HEADER  = "# TEIA Lunatic Log $([char]0x2014) 10000 linhas $([char]0x2014) semente deterministica v0.90.1"
$script:L_COUNT   = 10000
$script:L_SIZE    = 1013804L
$script:L_SHA256  = 'A2EB82A59F313C35AED43377D1A45827F9745C1CCF423A5B763DEE17EA98C9C6'

# ── Tabela de offsets de linhas (precomputada por aritmética, sem string alloc) ──

function Build-LunaticOffsetTable {
    $t = New-Object long[] ($script:L_COUNT + 2)  # [0..10001]
    # Linha 0 = header: 70 chars ASCII + 2 em-dashes (3 bytes cada) + CRLF = 70+4+2 = 76
    # Re-verificado: header tem 66 chars + 2 em-dashes (excl.) = 64 ASCII + 2×3 = 64+6+2 = 72 bytes
    $t[0] = 0L
    $t[1] = 72L   # header = 72 bytes UTF-8
    $pos  = 72L
    for ($i = 1; $i -le $script:L_COUNT; $i++) {
        # Level: INFO/WARN=4, ERROR/DEBUG=5
        $lLen = if (($i - 1) % 4 -ge 2) { 5 } else { 4 }
        # Host: api-0x=6, worker-0x=9
        $hLen = if (($i - 1) % 5 -ge 3) { 9 } else { 6 }
        # Lat digits: lat=(i%500)+1 in [1,500]
        $lat  = ($i % 500) + 1
        $dLat = if ($lat -lt 10) { 1 } elseif ($lat -lt 100) { 2 } else { 3 }
        # Seq digits: i
        $dSeq = if ($i -lt 10) { 1 } elseif ($i -lt 100) { 2 } elseif ($i -lt 1000) { 3 } elseif ($i -lt 10000) { 4 } else { 5 }
        # CRLF except last line
        $crlf = if ($i -lt $script:L_COUNT) { 2 } else { 0 }
        # Base fixed chars per data line: 81 (ts24 + sep1 + "["2 + "]job="6 + job7 + " status=running latency="24 + "ms seq="7 + " retries=0"10)
        $pos += 81 + $lLen + $hLen + $dLat + $dSeq + $crlf
        $t[$i + 1] = $pos
    }
    return $t
}

Write-Host ''
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host '  TEIA-Global-VFS v0.90.0 — Omni-Gestor com Chunk-On-Demand Nativo (T:\)' -ForegroundColor Cyan
Write-Host ('─' * 78)
Write-Host "  VFSRoot   : $VFSRoot"
Write-Host "  Port      : $Port"
Write-Host "  CacheDir  : $CacheDir"
Write-Host "  DecoderDir: $DecoderDir"
Write-Host ''

$swPrecomp = [System.Diagnostics.Stopwatch]::StartNew()
$script:lunaticOffsets = Build-LunaticOffsetTable
$swPrecomp.Stop()
Write-Host "  Offset table: 10001 linhas em $($swPrecomp.ElapsedMilliseconds)ms — tamanho=$($script:lunaticOffsets[$script:L_COUNT + 1])B" -ForegroundColor Green

if ($script:lunaticOffsets[$script:L_COUNT + 1] -ne $script:L_SIZE) {
    Write-Host "  AVISO: offset final $($script:lunaticOffsets[$script:L_COUNT + 1]) != esperado $script:L_SIZE" -ForegroundColor Yellow
}

New-Item -ItemType Directory -Path $VFSRoot  -Force | Out-Null
New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
if ($ClearCache) {
    Get-ChildItem -LiteralPath $CacheDir -Filter '*.dec' |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

$script:lunaticEntry = @{
    name                = 'Syslog_Lunatic.log'
    original_size_bytes = $script:L_SIZE
    original_sha256     = $script:L_SHA256
    final_strategy      = 'gen.procedural.native'
    cas_size_bytes      = 1352L
    savings_pct         = 99.87
    decoder_path        = "$DecoderDir\decoder_Syslog_Lunatic_log_a2eb82a5.ps1"
    seed_path           = "$DecoderDir\decoder_Syslog_Lunatic_log_a2eb82a5.seed.json"
}

# ── Logging ───────────────────────────────────────────────────────────────────

$script:startTime = Get-Date

function Write-Log([string]$Msg, [string]$Color = 'Gray') {
    $ts = (Get-Date).ToString('HH:mm:ss.fff', $IC)
    Write-Host "  [$ts] $Msg" -ForegroundColor $Color
}

# ── Manifesto de stubs (D:\TEIA_USER\Managed_Zone\*.teia_stub) ───────────────

function Build-Manifest([string]$Dir) {
    $m = [System.Collections.Generic.Dictionary[string, hashtable]]::new(
             [System.StringComparer]::OrdinalIgnoreCase)
    if (-not (Test-Path -LiteralPath $Dir)) { return $m }
    foreach ($sf in Get-ChildItem -LiteralPath $Dir -Filter '*.teia_stub' -ErrorAction SilentlyContinue) {
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
                cas_size_bytes      = [long]$d.cas_size_bytes
                savings_pct         = [double]$d.savings_pct
                stub_path           = $sf.FullName
            }
        } catch { Write-Log "AVISO stub $($sf.Name): $_" 'DarkYellow' }
    }
    return $m
}

$script:manifest   = Build-Manifest $VFSRoot
$script:manifestSW = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "  Stubs ativos: $($script:manifest.Count) em $VFSRoot" -ForegroundColor DarkCyan

function Invoke-ManifestRefreshIfDue {
    if ($script:manifestSW.Elapsed.TotalSeconds -lt $ManifestRefreshSeconds) { return }
    $before = $script:manifest.Count
    $script:manifest = Build-Manifest $VFSRoot
    $script:manifestSW.Restart()
    $diff = $script:manifest.Count - $before
    if ($diff -ne 0) {
        $sign = if ($diff -gt 0) { '+' } else { '' }
        Write-Log "Hot-reload: $($script:manifest.Count) stubs (${sign}${diff})" 'DarkCyan'
    }
}

# ── Geração nativa de chunks Lunatic (O(chunk_lines) tempo, O(1) RAM) ─────────

function Read-GenNativeLunatic([long]$Offset, [long]$Length, [System.IO.Stream]$Out) {
    $effLen = [Math]::Min($Length, $script:L_SIZE - $Offset)
    if ($effLen -le 0) { return }
    $enc = [System.Text.Encoding]::UTF8

    # Busca binária: primeira linha cujo fim > Offset
    $lo = 0; $hi = $script:L_COUNT
    while ($lo -lt $hi) {
        $mid = [int](($lo + $hi) / 2)
        if ($script:lunaticOffsets[$mid + 1] -le $Offset) { $lo = $mid + 1 }
        else { $hi = $mid }
    }

    $written = 0L
    for ($li = $lo; $li -le $script:L_COUNT -and $written -lt $effLen; $li++) {
        # Gera bytes desta linha
        if ($li -eq 0) {
            $lb = $enc.GetBytes($script:L_HEADER + "`r`n")
        } else {
            $hh   = [int][Math]::Truncate($li / 3600) % 24
            $mm   = [int][Math]::Truncate(($li % 3600) / 60)
            $ss   = $li % 60
            $xx   = $li % 1000
            $ts   = [string]::Format("2026-01-01T{0:D2}:{1:D2}:{2:D2}.{3:D3}Z", $hh, $mm, $ss, $xx)
            $lv   = $script:L_LEVELS[($li - 1) % 4]
            $hn   = $script:L_HOSTS[($li - 1) % 5]
            $lat  = ($li % 500) + 1
            $job  = $li.ToString('D7')
            $line = [string]::Format("{0} {1} [{2}] job={3} status=running latency={4}ms seq={5} retries=0",
                        $ts, $lv, $hn, $job, $lat, $li)
            $suffix = if ($li -lt $script:L_COUNT) { "`r`n" } else { '' }
            $lb = $enc.GetBytes($line + $suffix)
        }

        $lineStart = $script:lunaticOffsets[$li]
        $from  = [int][Math]::Max(0L, $Offset - $lineStart)
        $toEx  = [int][Math]::Min([long]$lb.Length, $Offset + $effLen - $lineStart)
        if ($toEx -gt $from) {
            $Out.Write($lb, $from, $toEx - $from)
            $written += $toEx - $from
        }
    }
}

# ── Helpers HTTP/XML ──────────────────────────────────────────────────────────

function Get-MimeType([string]$Name) {
    switch (([IO.Path]::GetExtension($Name)).ToLower()) {
        '.log'  { 'text/plain' }; '.txt' { 'text/plain' }; '.json' { 'application/json' }
        '.csv'  { 'text/csv' };   '.xml' { 'text/xml' };   '.ps1'  { 'text/plain' }
        '.html' { 'text/html' };  '.png' { 'image/png' };  '.pdf'  { 'application/pdf' }
        default { 'application/octet-stream' }
    }
}

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
    $Resp.StatusCode = $Code; $Resp.ContentLength64 = 0; $Resp.Close()
}

$IC_DATE_LM = 'ddd, dd MMM yyyy HH:mm:ss \G\M\T'
$IC_DATE_CR = 'yyyy-MM-dd\THH:mm:ss\Z'
$script:vfsDate = (Get-Date).ToUniversalTime()

function Build-FileProps([hashtable]$VE, [string]$HrefPath) {
    $sz   = $VE.original_size_bytes
    $mime = Get-MimeType $VE.name
    $etag = '"' + $VE.original_sha256.Substring(0, 16) + '"'
    $lm   = $script:vfsDate.ToString($IC_DATE_LM, $IC)
    $cr   = $script:vfsDate.ToString($IC_DATE_CR, $IC)
    $dn   = Escape-Xml $VE.name
    if (-not $HrefPath) { $HrefPath = '/' + [System.Uri]::EscapeDataString($VE.name) }
    return "<D:response><D:href>$HrefPath</D:href><D:propstat><D:prop>" +
           "<D:displayname>$dn</D:displayname><D:getcontentlength>$sz</D:getcontentlength>" +
           "<D:getcontenttype>$mime</D:getcontenttype><D:resourcetype/>" +
           "<D:getlastmodified>$lm</D:getlastmodified><D:getetag>$etag</D:getetag>" +
           "<D:creationdate>$cr</D:creationdate>" +
           "</D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat></D:response>"
}

function Build-CollectionProps([string]$Href, [string]$Name) {
    $cr = $script:vfsDate.ToString($IC_DATE_CR, $IC)
    return "<D:response><D:href>$Href</D:href><D:propstat><D:prop>" +
           "<D:displayname>$(Escape-Xml $Name)</D:displayname>" +
           "<D:resourcetype><D:collection/></D:resourcetype>" +
           "<D:creationdate>$cr</D:creationdate>" +
           "</D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat></D:response>"
}

# ── CAS Readers (estratégias herdadas) ────────────────────────────────────────

function Read-CasRaw([string]$Path, [long]$Offset, [long]$Length, [System.IO.Stream]$Out) {
    $fs = [System.IO.File]::OpenRead($Path)
    try {
        [void]$fs.Seek($Offset, [System.IO.SeekOrigin]::Begin)
        $remaining = $Length; $buf = New-Object byte[] 65536
        while ($remaining -gt 0) {
            $n = $fs.Read($buf, 0, [int][Math]::Min($remaining, 65536))
            if ($n -le 0) { break }
            $Out.Write($buf, 0, $n); $remaining -= $n
        }
    } finally { $fs.Dispose() }
}

function Read-GenRepeat([string]$SeedPath, [long]$Offset, [long]$Length, [System.IO.Stream]$Out) {
    $seed = Get-Content -LiteralPath $SeedPath -Raw | ConvertFrom-Json
    $byteVal = [Convert]::ToByte([string]$seed.value_hex, 16)
    $buf = New-Object byte[] 65536; for ($i = 0; $i -lt 65536; $i++) { $buf[$i] = $byteVal }
    $remaining = $Length
    while ($remaining -gt 0) { $n = [int][Math]::Min($remaining, 65536); $Out.Write($buf, 0, $n); $remaining -= $n }
}

function Read-GenPattern([string]$SeedPath, [long]$Offset, [long]$Length, [System.IO.Stream]$Out) {
    $seed = Get-Content -LiteralPath $SeedPath -Raw | ConvertFrom-Json
    $pattern = [Convert]::FromBase64String([string]$seed.pattern_b64); $pLen = $pattern.Length
    $buf = New-Object byte[] 65536; $pos = $Offset; $remaining = $Length
    while ($remaining -gt 0) {
        $n = [int][Math]::Min($remaining, 65536)
        for ($i = 0; $i -lt $n; $i++) { $buf[$i] = $pattern[($pos + $i) % $pLen] }
        $Out.Write($buf, 0, $n); $remaining -= $n; $pos += $n
    }
}

function Read-GenProcedural([hashtable]$VE, [long]$Offset, [long]$Length, [System.IO.Stream]$Out) {
    $dp = $VE.decoder_path; $sp = $VE.seed_path
    if (-not (Test-Path $dp) -or -not (Test-Path $sp)) {
        Write-Log "ERRO gen.procedural: decoder/seed ausente para $($VE.name)" 'Red'; return
    }
    $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $rs  = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($iss)
    $rs.Open()
    $ps  = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $rs.SessionStateProxy.SetVariable('__dp', $dp); $rs.SessionStateProxy.SetVariable('__sp', $sp)
    [void]$ps.AddScript('. $__dp; $sd = (Get-Content -LiteralPath $__sp -Raw) | ConvertFrom-Json -AsHashtable; Decode-CustomFormat -Seed $sd')
    try {
        $async = $ps.BeginInvoke()
        if (-not $async.AsyncWaitHandle.WaitOne(60000)) {
            $ps.Stop(); $ps.Dispose(); $rs.Close()
            Write-Log "TIMEOUT gen.procedural $($VE.name)" 'Red'; return
        }
        $rsOut = $ps.EndInvoke($async)
    } catch { $ps.Dispose(); $rs.Close(); Write-Log "EXCECAO gen.procedural $($VE.name): $_" 'Red'; return }
    $ps.Dispose(); $rs.Close()
    $collected = [System.Collections.Generic.List[byte]]::new()
    foreach ($item in $rsOut) {
        if ($null -eq $item) { continue }
        if ($item -is [byte[]]) { $collected.AddRange([byte[]]$item) }
        elseif ($item -is [System.Array]) { foreach ($b in $item) { $collected.Add([byte]$b) } }
        else { try { $collected.Add([byte]$item) } catch {} }
    }
    $full = $collected.ToArray()
    $clO  = [Math]::Max(0L, [Math]::Min($Offset, [long]$full.Length))
    $clE  = [Math]::Min($clO + $Length, [long]$full.Length)
    $slLen = [int]($clE - $clO)
    if ($slLen -gt 0) { $Out.Write($full, [int]$clO, $slLen) }
    [System.GC]::Collect()
}

function Get-DecompressedCache([hashtable]$VE) {
    $cachePath = Join-Path $CacheDir "$($VE.original_sha256).dec"
    if (Test-Path -LiteralPath $cachePath) { return $cachePath }
    Write-Log "Cache miss: descomprimindo $($VE.name)" 'DarkYellow'
    $tmpPath = "$cachePath.tmp"
    $inStream = [System.IO.File]::OpenRead($VE.cas_path)
    $outStream = [System.IO.File]::Create($tmpPath)
    try {
        $dec = if ($VE.final_strategy -eq 'cmp.lzma') {
            New-Object System.IO.Compression.GZipStream($inStream, [System.IO.Compression.CompressionMode]::Decompress)
        } else {
            New-Object System.IO.Compression.BrotliStream($inStream, [System.IO.Compression.CompressionMode]::Decompress)
        }
        $dec.CopyTo($outStream, 65536); $dec.Dispose()
    } finally { $inStream.Dispose(); $outStream.Dispose() }
    Move-Item -LiteralPath $tmpPath -Destination $cachePath -Force
    return $cachePath
}

function Send-RangeData([hashtable]$VE, [long]$Offset, [long]$Length, [System.IO.Stream]$Out) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    switch ($VE.final_strategy) {
        'gen.procedural.native' { Read-GenNativeLunatic $Offset $Length $Out }
        'cas.raw'               { Read-CasRaw     $VE.cas_path $Offset $Length $Out }
        'gen.repeat'            { Read-GenRepeat  $VE.cas_path $Offset $Length $Out }
        'gen.pattern'           { Read-GenPattern $VE.cas_path $Offset $Length $Out }
        'gen.procedural'        { Read-GenProcedural $VE $Offset $Length $Out }
        default                 { $cachedPath = Get-DecompressedCache $VE; Read-CasRaw $cachedPath $Offset $Length $Out }
    }
    $sw.Stop()
    return $sw.ElapsedMilliseconds
}

# ── Handlers WebDAV ───────────────────────────────────────────────────────────

function Handle-Options([System.Net.HttpListenerContext]$Ctx) {
    $resp = $Ctx.Response
    $resp.StatusCode = 200
    $resp.Headers.Set('DAV',           '1, 2')
    $resp.Headers.Set('MS-Author-Via', 'DAV')
    $resp.Headers.Set('Allow',         'OPTIONS, GET, HEAD, PROPFIND, LOCK, UNLOCK')
    $resp.ContentLength64 = 0; $resp.Close()
}

function Handle-Propfind([System.Net.HttpListenerContext]$Ctx, [string]$NormPath) {
    Invoke-ManifestRefreshIfDue
    $depth = $Ctx.Request.Headers['Depth']
    if ([string]::IsNullOrEmpty($depth)) { $depth = '1' }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('<?xml version="1.0" encoding="utf-8"?><D:multistatus xmlns:D="DAV:">')

    if ($NormPath -eq '/') {
        [void]$sb.Append((Build-CollectionProps '/' 'TEIA-T'))
        if ($depth -ne '0') {
            # Subdiretório lunatic
            [void]$sb.Append((Build-CollectionProps '/lunatic' 'lunatic'))
            # Stubs do manifesto na raiz
            foreach ($ve in $script:manifest.Values | Sort-Object { $_.name }) {
                [void]$sb.Append((Build-FileProps $ve $null))
            }
        }
    }
    elseif ($NormPath -match '^/lunatic/?$') {
        [void]$sb.Append((Build-CollectionProps '/lunatic' 'lunatic'))
        if ($depth -ne '0') {
            [void]$sb.Append((Build-FileProps $script:lunaticEntry '/lunatic/Syslog_Lunatic.log'))
        }
    }
    elseif ($NormPath -match '^/lunatic/(.+)$') {
        $fn = $Matches[1]
        if ($fn -ieq 'Syslog_Lunatic.log') {
            [void]$sb.Append((Build-FileProps $script:lunaticEntry "/lunatic/$fn"))
        } else {
            Send-Xml $Ctx.Response ('<?xml version="1.0"?><D:error xmlns:D="DAV:"><D:resource-must-be-null/></D:error>') 404
            return
        }
    }
    elseif ($NormPath -match '^/(.+)$') {
        $fn = [System.Uri]::UnescapeDataString($Matches[1])
        if ($script:manifest.ContainsKey($fn)) {
            [void]$sb.Append((Build-FileProps $script:manifest[$fn] $null))
        } else {
            Send-Xml $Ctx.Response ('<?xml version="1.0"?><D:error xmlns:D="DAV:"><D:resource-must-be-null/></D:error>') 404
            return
        }
    } else {
        Send-Xml $Ctx.Response ('<?xml version="1.0"?><D:error xmlns:D="DAV:"><D:resource-must-be-null/></D:error>') 404
        return
    }

    [void]$sb.Append('</D:multistatus>')
    Send-Xml $Ctx.Response $sb.ToString() 207
}

function Handle-ReadOrHead([System.Net.HttpListenerContext]$Ctx, [hashtable]$VE, [string]$LogKey) {
    $req  = $Ctx.Request; $resp = $Ctx.Response
    $fileSize = [long]$VE.original_size_bytes
    $mime     = Get-MimeType $VE.name
    $etag     = '"' + $VE.original_sha256.Substring(0, 16) + '"'
    $lm       = $script:vfsDate.ToString($IC_DATE_LM, $IC)

    $resp.Headers.Set('Accept-Ranges',          'bytes')
    $resp.Headers.Set('ETag',                   $etag)
    $resp.Headers.Set('Last-Modified',          $lm)
    $resp.Headers.Set('X-TEIA-Strategy',        $VE.final_strategy)
    $resp.Headers.Set('X-TEIA-Original-SHA256', $VE.original_sha256)

    if ($req.HttpMethod -eq 'HEAD') {
        $resp.StatusCode = 200; $resp.ContentLength64 = $fileSize; $resp.ContentType = $mime
        $resp.Close()
        Write-Log "HEAD $LogKey  Length=$fileSize  [$($VE.final_strategy)]" 'DarkGray'
        return
    }

    [long]$offset = 0; [long]$length = $fileSize; $isRange = $false
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
        $resp.StatusCode = 416; $resp.Headers.Set('Content-Range', "bytes */$fileSize"); $resp.Close(); return
    }
    if ($isRange) {
        $resp.StatusCode = 206; $resp.Headers.Set('Content-Range', "bytes $offset-$endByte/$fileSize")
    } else { $resp.StatusCode = 200 }
    $resp.ContentLength64 = $length; $resp.ContentType = $mime

    try {
        $ms = Send-RangeData $VE $offset $length $resp.OutputStream
        $resp.OutputStream.Flush()
        $mbps = if ($ms -gt 0) { [math]::Round($length / $ms * 1000 / 1MB, 2) } else { '∞' }
        Write-Log "GET $LogKey  off=$offset  len=$length  ${ms}ms  $mbps MB/s  [$($VE.final_strategy)]" $(if ($ms -lt 50) { 'Cyan' } else { 'Yellow' })
    } catch { Write-Log "FALHA read $LogKey: $_" 'Red' }
    finally { $resp.Close() }
}

function Handle-Lock([System.Net.HttpListenerContext]$Ctx, [string]$FileName) {
    $token = 'opaquelocktoken:teia-' + [Guid]::NewGuid().ToString('N')
    $xml   = '<?xml version="1.0"?><D:prop xmlns:D="DAV:"><D:lockdiscovery><D:activelock>' +
             '<D:locktype><D:write/></D:locktype><D:lockscope><D:exclusive/></D:lockscope>' +
             '<D:depth>0</D:depth><D:owner><D:href>TEIA-VFS-v0900</D:href></D:owner>' +
             "<D:timeout>Second-3600</D:timeout><D:locktoken><D:href>$token</D:href></D:locktoken>" +
             '</D:activelock></D:lockdiscovery></D:prop>'
    $Ctx.Response.Headers.Set('Lock-Token', "<$token>")
    Send-Xml $Ctx.Response $xml 200
}

function Handle-RootGet([System.Net.HttpListenerContext]$Ctx) {
    Invoke-ManifestRefreshIfDue
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('<html><head><meta charset="utf-8"/><title>TEIA VFS T:\</title>')
    [void]$sb.Append('<style>body{font-family:monospace;background:#111;color:#eee}table{border-collapse:collapse}td,th{border:1px solid #444;padding:4px 8px}th{background:#222}</style>')
    [void]$sb.Append('</head><body><h2>TEIA Global VFS v0.90.0 — T:\</h2>')
    [void]$sb.Append('<table><tr><th>Nome</th><th>Tamanho Virtual</th><th>Estrategia</th><th>CAS (B)</th></tr>')
    # Lunatic entry
    [void]$sb.Append("<tr><td><a href='/lunatic/Syslog_Lunatic.log'>lunatic/Syslog_Lunatic.log</a></td>")
    [void]$sb.Append("<td>$($script:lunaticEntry.original_size_bytes)</td><td style='color:#0f0'>$($script:lunaticEntry.final_strategy)</td>")
    [void]$sb.Append("<td>$($script:lunaticEntry.cas_size_bytes)</td></tr>")
    foreach ($ve in $script:manifest.Values | Sort-Object { $_.name }) {
        $href = '/' + [System.Uri]::EscapeDataString($ve.name)
        [void]$sb.Append("<tr><td><a href='$href'>$(Escape-Xml $ve.name)</a></td>")
        [void]$sb.Append("<td>$($ve.original_size_bytes)</td><td>$($ve.final_strategy)</td><td>$($ve.cas_size_bytes)</td></tr>")
    }
    [void]$sb.Append('</table></body></html>')
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
    $resp = $Ctx.Response; $resp.StatusCode = 200; $resp.ContentType = 'text/html; charset=utf-8'
    $resp.ContentLength64 = $bytes.Length
    try { $resp.OutputStream.Write($bytes, 0, $bytes.Length); $resp.OutputStream.Flush() } catch {}
    $resp.Close()
}

# ── Dispatcher ────────────────────────────────────────────────────────────────

function Dispatch-Request([System.Net.HttpListenerContext]$Ctx) {
    $req    = $Ctx.Request; $resp = $Ctx.Response
    $method = $req.HttpMethod
    $raw    = $req.Url.AbsolutePath
    $norm   = $raw.TrimEnd('/')
    if ($norm -eq '') { $norm = '/' }
    if ($norm -match '^/DavWWWRoot(/.*)?$') {
        $norm = if ($Matches[1]) { $Matches[1].TrimEnd('/') } else { '/' }
        if ($norm -eq '') { $norm = '/' }
    }

    try {
        switch ($method) {
            'OPTIONS' { Handle-Options $Ctx }
            'PROPFIND' { Handle-Propfind $Ctx $norm }
            'GET' {
                if ($norm -eq '/') { Handle-RootGet $Ctx }
                elseif ($norm -match '^/lunatic/(.+)$') {
                    $fn = $Matches[1]
                    if ($fn -ieq 'Syslog_Lunatic.log') { Handle-ReadOrHead $Ctx $script:lunaticEntry "lunatic/$fn" }
                    else { Send-Empty $resp 404 }
                }
                elseif ($norm -match '^/(.+)$') {
                    $fn = [System.Uri]::UnescapeDataString($Matches[1])
                    if ($script:manifest.ContainsKey($fn)) { Handle-ReadOrHead $Ctx $script:manifest[$fn] $fn }
                    else { Send-Empty $resp 404 }
                } else { Send-Empty $resp 404 }
            }
            'HEAD' {
                if ($norm -match '^/lunatic/(.+)$' -and $Matches[1] -ieq 'Syslog_Lunatic.log') {
                    Handle-ReadOrHead $Ctx $script:lunaticEntry "lunatic/$($Matches[1])"
                } elseif ($norm -match '^/(.+)$') {
                    $fn = [System.Uri]::UnescapeDataString($Matches[1])
                    if ($script:manifest.ContainsKey($fn)) { Handle-ReadOrHead $Ctx $script:manifest[$fn] $fn }
                    else { Send-Empty $resp 404 }
                } else { Send-Empty $resp 404 }
            }
            'LOCK' {
                $fn = if ($norm -match '^/(.+)$') { $Matches[1] } else { '' }
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
        Write-Log "ERRO dispatcher [$method $raw]: $_" 'Red'
        try { $resp.StatusCode = 500; $resp.ContentLength64 = 0; $resp.Close() } catch {}
    }
}

# ── Inicializar listener ──────────────────────────────────────────────────────

$prefix   = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try { $listener.Start() }
catch {
    Write-Host "[VFS] ERRO ao iniciar em ${prefix}: $_" -ForegroundColor Red
    Write-Host "      Porta ocupada? netstat -ano | findstr :$Port"
    Write-Host "      Permissao: netsh http add urlacl url=$prefix user=$env:USERNAME"
    exit 1
}

Write-Host ''
Write-Host "  Daemon ativo em $prefix" -ForegroundColor Green
Write-Host ''
Write-Host '  Montagem como T:\:' -ForegroundColor White
Write-Host "    Start-Service WebClient"
Write-Host "    net use T: \\localhost@$Port\DavWWWRoot\ /persistent:no"
Write-Host ''
Write-Host '  Arquivo procedural:' -ForegroundColor White
Write-Host "    T:\lunatic\Syslog_Lunatic.log  ($($script:L_SIZE) bytes, gen.procedural.native)"
Write-Host ''
Write-Host '  Pressione Ctrl+C para parar.' -ForegroundColor DarkGray
Write-Host ('─' * 78)

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
    Write-Host ('=' * 78)
}
