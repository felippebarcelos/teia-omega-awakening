<#
.SYNOPSIS
    TEIA-Global-VFS-v0900.ps1 — Omni-VFS Global com Chunk-On-Demand Nativo (Drive T:\)
.DESCRIPTION
    Daemon HTTP via TcpListener (porta 8772) que serve dois planos de dados:

    PLANO A — gen.procedural.native (T:\lunatic\Syslog_Lunatic.log)
        Bytes pre-gerados em memória (1MB array). Range GET = single TCP Write(headers+body).
        TCP_NODELAY=true, sem HTTP.sys. Alvo: P90 < 50ms.

    PLANO B — estratégias herdadas do v0800 (stubs de D:\TEIA_USER\Managed_Zone\)
        gen.repeat / gen.pattern / gen.procedural / cmp.lzma / cmp.brotli / cas.raw

    Montagem WebDAV (T:\):
        Start-Service WebClient
        net use T: \\localhost@8772\DavWWWRoot\ /persistent:no
#>
[CmdletBinding()]
param(
    [string]$VFSRoot    = 'D:\TEIA_USER\Managed_Zone',
    [string]$Port       = '8772',
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
    $t = New-Object long[] ($script:L_COUNT + 2)
    $t[0] = 0L
    $t[1] = 72L
    $pos  = 72L
    for ($i = 1; $i -le $script:L_COUNT; $i++) {
        $lLen = if (($i - 1) % 4 -ge 2) { 5 } else { 4 }
        $hLen = if (($i - 1) % 5 -ge 3) { 9 } else { 6 }
        $lat  = ($i % 500) + 1
        $dLat = if ($lat -lt 10) { 1 } elseif ($lat -lt 100) { 2 } else { 3 }
        $dSeq = if ($i -lt 10) { 1 } elseif ($i -lt 100) { 2 } elseif ($i -lt 1000) { 3 } elseif ($i -lt 10000) { 4 } else { 5 }
        $crlf = if ($i -lt $script:L_COUNT) { 2 } else { 0 }
        $pos += 81 + $lLen + $hLen + $dLat + $dSeq + $crlf
        $t[$i + 1] = $pos
    }
    return $t
}

# ── Cache completo em memória (pre-gera 1MB uma vez; range GET = single Write) ─

function Build-LunaticBytes {
    $enc = [System.Text.Encoding]::UTF8
    $ms  = [System.IO.MemoryStream]::new($script:L_SIZE + 16)
    $hdr = $enc.GetBytes($script:L_HEADER + "`r`n")
    $ms.Write($hdr, 0, $hdr.Length)
    for ($i = 1; $i -le $script:L_COUNT; $i++) {
        $hh  = [int][Math]::Truncate($i / 3600) % 24
        $mm  = [int][Math]::Truncate(($i % 3600) / 60)
        $ss  = $i % 60; $xx = $i % 1000
        $ts  = [string]::Format("2026-01-01T{0:D2}:{1:D2}:{2:D2}.{3:D3}Z", $hh, $mm, $ss, $xx)
        $lv  = $script:L_LEVELS[($i - 1) % 4]; $hn = $script:L_HOSTS[($i - 1) % 5]
        $lat = ($i % 500) + 1; $job = $i.ToString('D7')
        $line   = [string]::Format("{0} {1} [{2}] job={3} status=running latency={4}ms seq={5} retries=0",
                      $ts, $lv, $hn, $job, $lat, $i)
        $suffix = if ($i -lt $script:L_COUNT) { "`r`n" } else { '' }
        $lb = $enc.GetBytes($line + $suffix)
        $ms.Write($lb, 0, $lb.Length)
    }
    return $ms.ToArray()
}

Write-Host ''
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host '  TEIA-Global-VFS v0.90.0 — TcpListener com Chunk-On-Demand Nativo (T:\)' -ForegroundColor Cyan
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

$swBytes = [System.Diagnostics.Stopwatch]::StartNew()
$script:lunaticData = [byte[]](Build-LunaticBytes)
$swBytes.Stop()
Write-Host "  Lunatic cache: $($script:lunaticData.Length)B em $($swBytes.ElapsedMilliseconds)ms" -ForegroundColor Green

if ($script:lunaticData.Length -ne $script:L_SIZE) {
    Write-Host "  AVISO: cache size $($script:lunaticData.Length) != esperado $script:L_SIZE" -ForegroundColor Red
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

# ── Helpers de mime / XML ─────────────────────────────────────────────────────

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

# ── TCP Transport Helpers ─────────────────────────────────────────────────────

$script:enc_a = [System.Text.Encoding]::ASCII

# Parse HTTP request from NetworkStream (single Read, loopback-safe)
function Read-TcpRequest([System.Net.Sockets.NetworkStream]$Stream) {
    $buf = [byte[]]::new(16384)
    $n   = 0
    try {
        $Stream.ReadTimeout = 3000
        $n = $Stream.Read($buf, 0, $buf.Length)
    } catch { return $null }
    if ($n -le 0) { return $null }

    $raw   = $script:enc_a.GetString($buf, 0, $n)
    $lines = $raw -split "`r`n"
    $parts = $lines[0] -split ' ', 3
    if ($parts.Count -lt 2) { return $null }

    $headers = [System.Collections.Generic.Dictionary[string,string]]::new(
                   [System.StringComparer]::OrdinalIgnoreCase)
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '') { break }
        $colon = $lines[$i].IndexOf(':')
        if ($colon -ge 0) {
            $headers[$lines[$i].Substring(0, $colon).Trim()] = $lines[$i].Substring($colon + 1).Trim()
        }
    }
    return @{ Method = $parts[0]; RawPath = $parts[1]; Headers = $headers }
}

# Write response with headers+body in a single TCP Write (critical for latency)
function Write-TcpFull([System.IO.Stream]$S, [int]$Code, [string]$Text,
                       [System.Collections.Specialized.OrderedDictionary]$H, [byte[]]$Body) {
    $H['Content-Length'] = $Body.Length
    $sb = [System.Text.StringBuilder]::new(512)
    [void]$sb.Append("HTTP/1.1 $Code $Text`r`n")
    foreach ($kv in $H.GetEnumerator()) { [void]$sb.Append("$($kv.Key): $($kv.Value)`r`n") }
    [void]$sb.Append("Connection: close`r`n`r`n")
    $hb  = $script:enc_a.GetBytes($sb.ToString())
    $tot = [byte[]]::new($hb.Length + $Body.Length)
    [System.Buffer]::BlockCopy($hb,   0, $tot, 0,          $hb.Length)
    [System.Buffer]::BlockCopy($Body, 0, $tot, $hb.Length, $Body.Length)
    $S.Write($tot, 0, $tot.Length)
    $S.Flush()
}

# Write headers-only response (no body)
function Write-TcpHeaders([System.IO.Stream]$S, [int]$Code, [string]$Text,
                          [System.Collections.Specialized.OrderedDictionary]$H) {
    $sb = [System.Text.StringBuilder]::new(512)
    [void]$sb.Append("HTTP/1.1 $Code $Text`r`n")
    foreach ($kv in $H.GetEnumerator()) { [void]$sb.Append("$($kv.Key): $($kv.Value)`r`n") }
    [void]$sb.Append("Connection: close`r`n`r`n")
    $b = $script:enc_a.GetBytes($sb.ToString())
    $S.Write($b, 0, $b.Length)
    $S.Flush()
}

function Write-TcpEmpty([System.IO.Stream]$S, [int]$Code, [string]$Text) {
    $h = [ordered]@{ 'Content-Length' = '0' }
    Write-TcpHeaders $S $Code $Text $h
}

function Write-TcpXml([System.IO.Stream]$S, [int]$Code, [string]$Text, [string]$Xml) {
    $body = [System.Text.Encoding]::UTF8.GetBytes($Xml)
    $h    = [ordered]@{ 'Content-Type' = 'application/xml; charset=utf-8' }
    Write-TcpFull $S $Code $Text $h $body
}

# ── TCP Request Handlers ──────────────────────────────────────────────────────

function Handle-TcpOptions([System.IO.Stream]$S) {
    $h = [ordered]@{
        'DAV'            = '1, 2'
        'MS-Author-Via'  = 'DAV'
        'Allow'          = 'OPTIONS, GET, HEAD, PROPFIND, LOCK, UNLOCK'
        'Content-Length' = '0'
    }
    Write-TcpHeaders $S 200 'OK' $h
}

function Handle-TcpPropfind([hashtable]$Req, [System.IO.Stream]$S, [string]$NormPath) {
    Invoke-ManifestRefreshIfDue
    $depth = $Req.Headers['Depth']
    if ([string]::IsNullOrEmpty($depth)) { $depth = '1' }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('<?xml version="1.0" encoding="utf-8"?><D:multistatus xmlns:D="DAV:">')

    if ($NormPath -eq '/') {
        [void]$sb.Append((Build-CollectionProps '/' 'TEIA-T'))
        if ($depth -ne '0') {
            [void]$sb.Append((Build-CollectionProps '/lunatic' 'lunatic'))
            foreach ($ve in $script:manifest.Values | Sort-Object { $_.name }) {
                [void]$sb.Append((Build-FileProps $ve $null))
            }
        }
    } elseif ($NormPath -match '^/lunatic/?$') {
        [void]$sb.Append((Build-CollectionProps '/lunatic' 'lunatic'))
        if ($depth -ne '0') {
            [void]$sb.Append((Build-FileProps $script:lunaticEntry '/lunatic/Syslog_Lunatic.log'))
        }
    } elseif ($NormPath -match '^/lunatic/(.+)$') {
        $fn = $Matches[1]
        if ($fn -ieq 'Syslog_Lunatic.log') {
            [void]$sb.Append((Build-FileProps $script:lunaticEntry "/lunatic/$fn"))
        } else {
            Write-TcpXml $S 404 'Not Found' '<?xml version="1.0"?><D:error xmlns:D="DAV:"><D:resource-must-be-null/></D:error>'
            return
        }
    } elseif ($NormPath -match '^/(.+)$') {
        $fn = [System.Uri]::UnescapeDataString($Matches[1])
        if ($script:manifest.ContainsKey($fn)) {
            [void]$sb.Append((Build-FileProps $script:manifest[$fn] $null))
        } else {
            Write-TcpXml $S 404 'Not Found' '<?xml version="1.0"?><D:error xmlns:D="DAV:"><D:resource-must-be-null/></D:error>'
            return
        }
    } else {
        Write-TcpXml $S 404 'Not Found' '<?xml version="1.0"?><D:error xmlns:D="DAV:"><D:resource-must-be-null/></D:error>'
        return
    }

    [void]$sb.Append('</D:multistatus>')
    Write-TcpXml $S 207 'Multi-Status' $sb.ToString()
}

function Handle-TcpLock([System.IO.Stream]$S, [string]$NormPath) {
    $token = 'opaquelocktoken:teia-' + [Guid]::NewGuid().ToString('N')
    $xml   = '<?xml version="1.0"?><D:prop xmlns:D="DAV:"><D:lockdiscovery><D:activelock>' +
             '<D:locktype><D:write/></D:locktype><D:lockscope><D:exclusive/></D:lockscope>' +
             '<D:depth>0</D:depth><D:owner><D:href>TEIA-VFS-v0900</D:href></D:owner>' +
             "<D:timeout>Second-3600</D:timeout><D:locktoken><D:href>$token</D:href></D:locktoken>" +
             '</D:activelock></D:lockdiscovery></D:prop>'
    $body = [System.Text.Encoding]::UTF8.GetBytes($xml)
    $h    = [ordered]@{
        'Content-Type' = 'application/xml; charset=utf-8'
        'Lock-Token'   = "<$token>"
    }
    Write-TcpFull $S 200 'OK' $h $body
}

function Handle-TcpRootGet([System.IO.Stream]$S) {
    Invoke-ManifestRefreshIfDue
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('<html><head><meta charset="utf-8"/><title>TEIA VFS T:\</title>')
    [void]$sb.Append('<style>body{font-family:monospace;background:#111;color:#eee}table{border-collapse:collapse}td,th{border:1px solid #444;padding:4px 8px}th{background:#222}</style>')
    [void]$sb.Append('</head><body><h2>TEIA Global VFS v0.90.0 — T:\</h2>')
    [void]$sb.Append('<table><tr><th>Nome</th><th>Tamanho Virtual</th><th>Estrategia</th><th>CAS (B)</th></tr>')
    [void]$sb.Append("<tr><td><a href='/lunatic/Syslog_Lunatic.log'>lunatic/Syslog_Lunatic.log</a></td>")
    [void]$sb.Append("<td>$($script:lunaticEntry.original_size_bytes)</td><td style='color:#0f0'>$($script:lunaticEntry.final_strategy)</td>")
    [void]$sb.Append("<td>$($script:lunaticEntry.cas_size_bytes)</td></tr>")
    foreach ($ve in $script:manifest.Values | Sort-Object { $_.name }) {
        $href = '/' + [System.Uri]::EscapeDataString($ve.name)
        [void]$sb.Append("<tr><td><a href='$href'>$(Escape-Xml $ve.name)</a></td>")
        [void]$sb.Append("<td>$($ve.original_size_bytes)</td><td>$($ve.final_strategy)</td><td>$($ve.cas_size_bytes)</td></tr>")
    }
    [void]$sb.Append('</table></body></html>')
    $body = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
    $h    = [ordered]@{ 'Content-Type' = 'text/html; charset=utf-8' }
    Write-TcpFull $S 200 'OK' $h $body
}

# ── Hot Path: Range GET / HEAD (TcpListener, TCP_NODELAY) ────────────────────

function Handle-TcpReadOrHead([hashtable]$Req, [System.IO.Stream]$S, [hashtable]$VE, [string]$LogKey) {
    $fileSize = [long]$VE.original_size_bytes
    $mime     = Get-MimeType $VE.name
    $etag     = '"' + $VE.original_sha256.Substring(0, 16) + '"'
    $lm       = $script:vfsDate.ToString($IC_DATE_LM, $IC)

    if ($Req.Method -eq 'HEAD') {
        $h = [ordered]@{
            'Content-Type'           = $mime
            'Content-Length'         = $fileSize
            'Accept-Ranges'          = 'bytes'
            'ETag'                   = $etag
            'Last-Modified'          = $lm
            'X-TEIA-Strategy'        = $VE.final_strategy
            'X-TEIA-Original-SHA256' = $VE.original_sha256
        }
        Write-TcpHeaders $S 200 'OK' $h
        Write-Log "HEAD $LogKey  Length=$fileSize  [$($VE.final_strategy)]" 'DarkGray'
        return
    }

    [long]$offset = 0; [long]$length = $fileSize; $isRange = $false; $code = 200; $codeText = 'OK'
    $rangeHdr = $Req.Headers['Range']
    if ($rangeHdr -and $rangeHdr -match 'bytes=(\d+)-(\d*)') {
        $offset  = [long]$Matches[1]
        $endByte = if ($Matches[2]) { [long]$Matches[2] } else { $fileSize - 1 }
        $length  = $endByte - $offset + 1
        $isRange = $true; $code = 206; $codeText = 'Partial Content'
    }
    $offset  = [Math]::Max(0L, [Math]::Min($offset, $fileSize))
    $length  = [Math]::Max(0L, [Math]::Min($length, $fileSize - $offset))
    $endByte = $offset + $length - 1

    if ($length -le 0) {
        $h = [ordered]@{ 'Content-Range' = "bytes */$fileSize"; 'Content-Length' = '0' }
        Write-TcpHeaders $S 416 'Range Not Satisfiable' $h
        return
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    if ($VE.final_strategy -eq 'gen.procedural.native') {
        # Hot path: combine headers+body into single Write → avoids TCP delayed-ACK stall
        $cr     = if ($isRange) { "Content-Range: bytes $offset-$endByte/$fileSize`r`n" } else { '' }
        $hdrStr = "HTTP/1.1 $code $codeText`r`nContent-Type: $mime`r`nContent-Length: $length`r`n" +
                  $cr + "Accept-Ranges: bytes`r`nETag: $etag`r`nLast-Modified: $lm`r`n" +
                  "X-TEIA-Strategy: $($VE.final_strategy)`r`nConnection: close`r`n`r`n"
        $hdrBytes = $script:enc_a.GetBytes($hdrStr)
        $effLen   = [int][Math]::Min($length, $script:L_SIZE - $offset)
        $tot      = [byte[]]::new($hdrBytes.Length + $effLen)
        [System.Buffer]::BlockCopy($hdrBytes,           0,              $tot, 0,               $hdrBytes.Length)
        [System.Buffer]::BlockCopy($script:lunaticData, [int]$offset,   $tot, $hdrBytes.Length, $effLen)
        $S.Write($tot, 0, $tot.Length)
        $S.Flush()
    } else {
        # Other strategies: write headers then stream body
        $cr     = if ($isRange) { "Content-Range: bytes $offset-$endByte/$fileSize`r`n" } else { '' }
        $hdrStr = "HTTP/1.1 $code $codeText`r`nContent-Type: $mime`r`nContent-Length: $length`r`n" +
                  $cr + "Accept-Ranges: bytes`r`nETag: $etag`r`nLast-Modified: $lm`r`n" +
                  "X-TEIA-Strategy: $($VE.final_strategy)`r`nConnection: close`r`n`r`n"
        $hdrBytes = $script:enc_a.GetBytes($hdrStr)
        $S.Write($hdrBytes, 0, $hdrBytes.Length)
        switch ($VE.final_strategy) {
            'cas.raw'        { Read-CasRaw     $VE.cas_path $offset $length $S }
            'gen.repeat'     { Read-GenRepeat  $VE.cas_path $offset $length $S }
            'gen.pattern'    { Read-GenPattern $VE.cas_path $offset $length $S }
            'gen.procedural' { Read-GenProcedural $VE $offset $length $S }
            default {
                $cachedPath = Get-DecompressedCache $VE
                Read-CasRaw $cachedPath $offset $length $S
            }
        }
        $S.Flush()
    }

    $sw.Stop(); $ms = $sw.ElapsedMilliseconds
    $mbps = if ($ms -gt 0) { [math]::Round($length / $ms * 1000 / 1MB, 2) } else { '∞' }
    Write-Log "GET $LogKey  off=$offset  len=$length  ${ms}ms  $mbps MB/s  [$($VE.final_strategy)]" $(if ($ms -lt 50) { 'Cyan' } else { 'Yellow' })
}

# ── Dispatcher ────────────────────────────────────────────────────────────────

function Dispatch-TcpRequest([hashtable]$Req, [System.IO.Stream]$S) {
    $method  = $Req.Method
    $rawPath = $Req.RawPath
    $norm    = ([System.Uri]::UnescapeDataString($rawPath)).TrimEnd('/')
    if ($norm -eq '') { $norm = '/' }
    if ($norm -match '^/DavWWWRoot(/.*)?$') {
        $norm = if ($Matches[1]) { $Matches[1].TrimEnd('/') } else { '/' }
        if ($norm -eq '') { $norm = '/' }
    }

    try {
        switch ($method) {
            'OPTIONS'  { Handle-TcpOptions $S }
            'PROPFIND' { Handle-TcpPropfind $Req $S $norm }
            { $_ -eq 'GET' -or $_ -eq 'HEAD' } {
                if ($norm -eq '/') {
                    Handle-TcpRootGet $S
                } elseif ($norm -match '^/lunatic/(.+)$') {
                    $fn = $Matches[1]
                    if ($fn -ieq 'Syslog_Lunatic.log') {
                        Handle-TcpReadOrHead $Req $S $script:lunaticEntry "lunatic/$fn"
                    } else { Write-TcpEmpty $S 404 'Not Found' }
                } elseif ($norm -match '^/(.+)$') {
                    $fn = [System.Uri]::UnescapeDataString($Matches[1])
                    if ($script:manifest.ContainsKey($fn)) {
                        Handle-TcpReadOrHead $Req $S $script:manifest[$fn] $fn
                    } else { Write-TcpEmpty $S 404 'Not Found' }
                } else { Write-TcpEmpty $S 404 'Not Found' }
            }
            'LOCK'   { Handle-TcpLock $S $norm }
            'UNLOCK' { Write-TcpEmpty $S 204 'No Content' }
            default  {
                $h = [ordered]@{
                    'Allow'          = 'OPTIONS, GET, HEAD, PROPFIND, LOCK, UNLOCK'
                    'Content-Length' = '0'
                }
                Write-TcpHeaders $S 405 'Method Not Allowed' $h
            }
        }
    } catch {
        Write-Log "ERRO dispatcher [$method $rawPath]: $_" 'Red'
        try { Write-TcpEmpty $S 500 'Internal Server Error' } catch {}
    }
}

# ── Inicializar TcpListener (bypass HTTP.sys, TCP_NODELAY=true) ───────────────

$portInt  = [int]$Port
$server   = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $portInt)
$server.Start()

Write-Host ''
Write-Host "  Daemon TCP ativo em http://localhost:$Port/" -ForegroundColor Green
Write-Host "  TCP_NODELAY=true  HTTP.sys=bypass" -ForegroundColor DarkGreen
Write-Host ''
Write-Host '  Montagem como T:\:' -ForegroundColor White
Write-Host "    Start-Service WebClient"
Write-Host "    net use T: \\localhost@$Port\DavWWWRoot\ /persistent:no"
Write-Host ''
Write-Host '  Arquivo procedural:' -ForegroundColor White
Write-Host "    lunatic/Syslog_Lunatic.log  ($($script:L_SIZE) bytes, gen.procedural.native)"
Write-Host ''
Write-Host '  Pressione Ctrl+C para parar.' -ForegroundColor DarkGray
Write-Host ('─' * 78)

try {
    while ($true) {
        $client = $server.AcceptTcpClient()
        $client.NoDelay        = $true
        $client.SendTimeout    = 5000
        $client.ReceiveTimeout = 3000
        try {
            $ns  = $client.GetStream()
            $req = Read-TcpRequest $ns
            if ($req) { Dispatch-TcpRequest $req $ns }
        } catch { Write-Log "ERRO client: $_" 'Red' }
        finally  { try { $client.Close() } catch {} }
    }
} finally {
    $server.Stop()
    $uptime = [int]((Get-Date) - $script:startTime).TotalSeconds
    Write-Host ''
    Write-Host ('─' * 78)
    Write-Host "  VFS TCP encerrado. Uptime: ${uptime}s" -ForegroundColor DarkGray
    Write-Host ('=' * 78)
}
