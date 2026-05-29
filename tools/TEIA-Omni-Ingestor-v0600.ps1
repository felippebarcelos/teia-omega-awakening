<#
.SYNOPSIS
    TEIA-Omni-Ingestor-v0600.ps1 — Ingestor Global em Background (P9.0)

.DESCRIPTION
    Evolucao do Ingestor Ativo para servico de background continuo.

    Monitora um diretorio raiz extenso via FileSystemWatcher.
    Aplica NeuroPlanner (HR1->HR2->HR3->HR4->HR6->HR5->LLM_FALLBACK)
    em cada novo arquivo silenciosamente. Transforma arquivo em stub,
    envia payload para CAS, libera espaco fisico real.

    Invariantes P9.0:
      CAS Delta = 0 em stubs e cache -- apenas objects/ recebe escrita
      OOM Guard -- amostra 64KB para analise; CopyTo 64KB para compressao
      Idempotencia -- skip se .teia_stub ja existe para o arquivo
      Stubs atomicos -- escrita via .tmp -> Move-Item -> delete original
      Safety -- OS criticos, dlls de boot e extensoes perigosas ignorados

    Routing (sem NeuroPlanner externo -- hard rules inline):
      HR1 byte_unico        -> gen.repeat   (.teia_seed)
      HR2 padrao_periodico  -> gen.pattern  (.teia_seed)
      HR3 entropia >= 7.0   -> cas.raw      (.raw)
      HR4 magic_comprimido  -> cas.raw      (.raw)
      HR6 .obj < 4096 v<20  -> gen.parametric_mesh (.br)
      HR5 tamanho < 8192    -> cmp.brotli   (.br)
      LLM_FALLBACK          -> cmp.lzma     (.gz)

.PARAMETER WatchDir
    Diretorio raiz a monitorar continuamente.
    Padrao: D:\TEIA_USER\Managed_Drive

.PARAMETER CASRoot
    Raiz do CAS (Content-Addressable Storage).
    Padrao: D:\TEIA_CORE\objects

.PARAMETER LogFile
    Arquivo de log estruturado (CSV-like).
    Padrao: D:\TEIA_CORE\logs\omni_ingestor.log

.PARAMETER MaxFileSizeMB
    Tamanho maximo de arquivo para ingestao (seguranca).
    Padrao: 500

.PARAMETER SampleBytes
    Bytes lidos para analise de entropia/padrao.
    Padrao: 65536 (64 KB)

.PARAMETER ProcessExisting
    Processa todos os arquivos existentes no WatchDir ao iniciar.

.PARAMETER DryRun
    Analisa sem modificar arquivos, CAS ou criar stubs.
#>
[CmdletBinding()]
param(
    [string]$WatchDir      = 'D:\TEIA_USER\Managed_Drive',
    [string]$CASRoot       = 'D:\TEIA_CORE\objects',
    [string]$LogFile       = 'D:\TEIA_CORE\logs\omni_ingestor.log',
    [int]$MaxFileSizeMB    = 500,
    [int]$SampleBytes      = 65536,
    [switch]$ProcessExisting,
    [switch]$DryRun
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC  = [System.Globalization.CultureInfo]::InvariantCulture
$enc = New-Object System.Text.UTF8Encoding($false)

# ── Banner ────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host '  TEIA-Omni-Ingestor v0.60.0 — Ingestor Global Background (P9.0)' -ForegroundColor Cyan
Write-Host ('─' * 78)
Write-Host "  WatchDir     : $WatchDir"
Write-Host "  CASRoot      : $CASRoot"
Write-Host "  LogFile      : $LogFile"
Write-Host "  MaxFileSizeMB: $MaxFileSizeMB"
Write-Host "  DryRun       : $DryRun"
Write-Host "  Routing      : HR1->HR2->HR3->HR4->HR6->HR5->LLM_FALLBACK"
Write-Host ('─' * 78)
Write-Host ''

# ── Validacoes ────────────────────────────────────────────────────────────────

if (-not (Test-Path -LiteralPath $WatchDir)) {
    New-Item -ItemType Directory -Path $WatchDir -Force | Out-Null
    Write-Host "  WatchDir criado: $WatchDir" -ForegroundColor DarkYellow
}
if (-not $DryRun) {
    New-Item -ItemType Directory -Path (Split-Path $LogFile -Parent) -Force | Out-Null
    New-Item -ItemType Directory -Path $CASRoot -Force | Out-Null
}

# ── Safety: extensoes e caminhos excluidos ────────────────────────────────────

$SKIP_EXTENSIONS = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@(
        # Binarios e drivers Windows
        '.dll', '.exe', '.sys', '.drv', '.ocx', '.scr', '.com', '.bat', '.cmd', '.msc',
        '.cpl', '.acm', '.ax', '.mui', '.mun', '.ptxml',
        # Config e metadados Windows
        '.lnk', '.ini', '.msi', '.cat', '.inf', '.reg', '.manifest', '.mof',
        # Ja processados
        '.teia_stub', '.teia_seed',
        # Temporarios e locks
        '.tmp', '.temp', '.lock', '.part', '.crdownload', '.!qb',
        # Pagefile e hibernacao
        '.sys'
    ),
    [System.StringComparer]::OrdinalIgnoreCase
)

$SKIP_PATH_PATTERNS = @(
    'C:\Windows\',
    'C:\Program Files\',
    'C:\Program Files (x86)\',
    '\AppData\Local\Temp\',
    '\AppData\Roaming\Microsoft\',
    'D:\TEIA_CORE\objects\',
    'D:\TEIA_CORE\vfs_cache\',
    '$Recycle.Bin',
    'System Volume Information'
)

function Test-SafeToIngest([string]$Path) {
    $ext = [IO.Path]::GetExtension($Path)
    if ($SKIP_EXTENSIONS.Contains($ext)) { return $false }
    foreach ($pat in $SKIP_PATH_PATTERNS) {
        if ($Path.IndexOf($pat, [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $false }
    }
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $fi = [System.IO.FileInfo]::new($Path)
    if (-not $fi.Exists -or $fi.Length -eq 0) { return $false }
    if ($fi.Length -gt ($MaxFileSizeMB * 1MB)) { return $false }
    return $true
}

# ── Logging ───────────────────────────────────────────────────────────────────

$script:logLock = [System.Threading.Mutex]::new($false, 'TEIA_Ingestor_Log')

function Write-Log([string]$Msg, [string]$Color = 'Gray') {
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff', $IC)
    Write-Host "  [$ts] $Msg" -ForegroundColor $Color
    if (-not $DryRun) {
        try {
            $script:logLock.WaitOne(500) | Out-Null
            Add-Content -LiteralPath $LogFile -Value "[$ts] $Msg" -Encoding UTF8 -ErrorAction SilentlyContinue
        } finally {
            $script:logLock.ReleaseMutex() | Out-Null
        }
    }
}

# ── SHA-256 ───────────────────────────────────────────────────────────────────

function Get-SHA256File([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLower()
}

function Get-SHA256Bytes([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $h   = $sha.ComputeHash($Bytes)
    $sha.Dispose()
    [BitConverter]::ToString($h).Replace('-', '').ToLower()
}

# SHA-256 esperado de um bloco repeat (sem ReadAllBytes) -- O(1) RAM
function Get-RepeatSHA256([byte]$Val, [long]$Size) {
    $sha  = [System.Security.Cryptography.SHA256]::Create()
    $buf  = New-Object byte[] 65536
    for ($i = 0; $i -lt 65536; $i++) { $buf[$i] = $Val }
    $rem  = $Size
    while ($rem -gt 0) {
        $n = [int][Math]::Min($rem, 65536)
        if ($rem -gt $n) { [void]$sha.TransformBlock($buf, 0, $n, $null, 0) }
        else             { [void]$sha.TransformFinalBlock($buf, 0, $n) }
        $rem -= $n
    }
    [BitConverter]::ToString($sha.Hash).Replace('-', '').ToLower()
}

# SHA-256 esperado de padrao periodico -- O(period) RAM
function Get-PatternSHA256([byte[]]$Pattern, [long]$Size) {
    $sha  = [System.Security.Cryptography.SHA256]::Create()
    $pLen = $Pattern.Length
    $buf  = New-Object byte[] 65536
    $pos  = [long]0
    $rem  = $Size
    while ($rem -gt 0) {
        $n = [int][Math]::Min($rem, 65536)
        for ($i = 0; $i -lt $n; $i++) { $buf[$i] = $Pattern[($pos + $i) % $pLen] }
        if ($rem -gt $n) { [void]$sha.TransformBlock($buf, 0, $n, $null, 0) }
        else             { [void]$sha.TransformFinalBlock($buf, 0, $n) }
        $rem -= $n; $pos += $n
    }
    [BitConverter]::ToString($sha.Hash).Replace('-', '').ToLower()
}

# ── CAS path ──────────────────────────────────────────────────────────────────

function Get-CASPath([string]$SHA256, [string]$Ext) {
    $a = $SHA256.Substring(0, 2); $b = $SHA256.Substring(2, 2)
    $dir = Join-Path $CASRoot "$a\$b"
    if (-not $DryRun) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    return Join-Path $dir "${SHA256}${Ext}"
}

# ── Analise de sample (OOM-safe: max SampleBytes) ────────────────────────────

function Read-Sample([string]$Path) {
    $fs  = [System.IO.File]::OpenRead($Path)
    $buf = New-Object byte[] $SampleBytes
    $n   = $fs.Read($buf, 0, $SampleBytes)
    $fs.Dispose()
    if ($n -lt $SampleBytes) { $buf = $buf[0..($n - 1)] }
    return $buf
}

function Get-Entropy([byte[]]$Sample) {
    if ($Sample.Length -eq 0) { return 0.0 }
    $freq = New-Object long[] 256
    foreach ($b in $Sample) { $freq[$b]++ }
    $n = [double]$Sample.Length; $e = 0.0
    foreach ($c in $freq) {
        if ($c -gt 0) { $p = $c / $n; $e -= $p * [Math]::Log($p, 2) }
    }
    [Math]::Round($e, 4)
}

function Get-UniqueByte([byte[]]$Sample) {
    if ($Sample.Length -eq 0) { return -1 }
    $val = $Sample[0]
    foreach ($b in $Sample) { if ($b -ne $val) { return -1 } }
    return [int]$val
}

function Find-Period([byte[]]$Sample) {
    $n = $Sample.Length
    $maxP = [int][Math]::Min(512, $n / 4)
    for ($p = 1; $p -le $maxP; $p++) {
        $ok = $true
        $check = [int][Math]::Min($n, $p * 64)
        for ($i = $p; $i -lt $check; $i++) {
            if ($Sample[$i] -ne $Sample[$i % $p]) { $ok = $false; break }
        }
        if ($ok -and $check -ge $p * 4) { return $p }
    }
    return -1
}

function Test-CompressedMagic([byte[]]$Header) {
    if ($Header.Length -lt 4) { return $false }
    $a = $Header[0]; $b = $Header[1]; $c = $Header[2]; $d = $Header[3]
    # GZip
    if ($a -eq 0x1F -and $b -eq 0x8B) { return $true }
    # ZIP/JAR/DOCX/XLSX
    if ($a -eq 0x50 -and $b -eq 0x4B -and $c -eq 0x03 -and $d -eq 0x04) { return $true }
    # PNG
    if ($a -eq 0x89 -and $b -eq 0x50 -and $c -eq 0x4E -and $d -eq 0x47) { return $true }
    # JPEG
    if ($a -eq 0xFF -and $b -eq 0xD8 -and $c -eq 0xFF) { return $true }
    # 7-zip
    if ($a -eq 0x37 -and $b -eq 0x7A -and $c -eq 0xBC -and $d -eq 0xAF) { return $true }
    # BZip2
    if ($a -eq 0x42 -and $b -eq 0x5A -and $c -eq 0x68) { return $true }
    # XZ
    if ($a -eq 0xFD -and $b -eq 0x37 -and $c -eq 0x7A -and $d -eq 0x58) { return $true }
    # LZ4
    if ($a -eq 0x04 -and $b -eq 0x22 -and $c -eq 0x4D -and $d -eq 0x18) { return $true }
    # Zstd
    if ($a -eq 0x28 -and $b -eq 0xB5 -and $c -eq 0x2F -and $d -eq 0xFD) { return $true }
    # MZ (EXE/DLL)
    if ($a -eq 0x4D -and $b -eq 0x5A) { return $true }
    # MP4/MOV/M4A (ftyp at offset 4)
    if ($Header.Length -ge 8 -and $Header[4] -eq 0x66 -and $Header[5] -eq 0x74 -and
        $Header[6] -eq 0x79 -and $Header[7] -eq 0x70) { return $true }
    return $false
}

function Count-ObjVertices([string]$Path) {
    $v = 0
    foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
        if ($line -match '^v\s') { $v++; if ($v -ge 20) { break } }
    }
    return $v
}

# ── NeuroPlanner inline (Rule-First) ──────────────────────────────────────────

function Get-Route([string]$Path, [long]$FileSize) {
    $ext    = [IO.Path]::GetExtension($Path).ToLower()
    $sample = Read-Sample $Path

    # HR4 primeiro: magic bytes indicam dado ja comprimido/binario
    if (Test-CompressedMagic $sample) {
        return @{ Strategy = 'cas.raw'; Rule = 'HR4' }
    }

    $entropy = Get-Entropy $sample

    # HR3: alta entropia -> incompressivel -> cas.raw
    if ($entropy -ge 7.0) {
        return @{ Strategy = 'cas.raw'; Rule = 'HR3'; Entropy = $entropy }
    }

    # HR1: byte unico -> gen.repeat (verificacao por SHA-256 esperado)
    $uByte = Get-UniqueByte $sample
    if ($uByte -ge 0) {
        return @{ Strategy = 'gen.repeat'; Rule = 'HR1'; ByteVal = $uByte }
    }

    # HR2: padrao periodico -> gen.pattern
    $period = Find-Period $sample
    if ($period -gt 0) {
        return @{ Strategy = 'gen.pattern'; Rule = 'HR2'; Period = $period }
    }

    # HR6: OBJ mesh pequeno -> gen.parametric_mesh
    if ($ext -eq '.obj' -and $FileSize -lt 4096) {
        $vCount = Count-ObjVertices $Path
        if ($vCount -gt 0 -and $vCount -lt 20) {
            return @{ Strategy = 'gen.parametric_mesh'; Rule = 'HR6'; VCount = $vCount }
        }
    }

    # HR5: arquivo pequeno -> cmp.brotli
    if ($FileSize -lt 8192) {
        return @{ Strategy = 'cmp.brotli'; Rule = 'HR5' }
    }

    # LLM_FALLBACK: texto/dados estruturados -> cmp.lzma (GZip no .NET BCL)
    return @{ Strategy = 'cmp.lzma'; Rule = 'LLM_FALLBACK'; Entropy = $entropy }
}

# ── Compressores (OOM guard: CopyTo 64KB) ────────────────────────────────────

function Compress-GZip([string]$Src, [string]$Dst) {
    $in  = [System.IO.File]::OpenRead($Src)
    $out = [System.IO.File]::Create($Dst)
    $gz  = New-Object System.IO.Compression.GZipStream($out,
               [System.IO.Compression.CompressionLevel]::Optimal)
    try { $in.CopyTo($gz, 65536) } finally { $gz.Dispose(); $in.Dispose(); $out.Dispose() }
}

function Compress-Brotli([string]$Src, [string]$Dst) {
    $in  = [System.IO.File]::OpenRead($Src)
    $out = [System.IO.File]::Create($Dst)
    $br  = New-Object System.IO.Compression.BrotliStream($out,
               [System.IO.Compression.CompressionLevel]::Optimal)
    try { $in.CopyTo($br, 65536) } finally { $br.Dispose(); $in.Dispose(); $out.Dispose() }
}

function Copy-RawCAS([string]$Src, [string]$Dst) {
    $in  = [System.IO.File]::OpenRead($Src)
    $out = [System.IO.File]::Create($Dst)
    try { $in.CopyTo($out, 65536) } finally { $in.Dispose(); $out.Dispose() }
}

# ── Ingestao de um arquivo ────────────────────────────────────────────────────

function Invoke-IngestFile([string]$Path) {
    $fi = [System.IO.FileInfo]::new($Path)
    if (-not $fi.Exists) { return }

    # Aguardar arquivo estavel (nao em escrita)
    $waitMs = 0
    while ($waitMs -lt 3000) {
        try {
            $fs = [System.IO.File]::Open($Path, 'Open', 'Read', 'None')
            $fs.Dispose(); break
        } catch { Start-Sleep -Milliseconds 300; $waitMs += 300 }
    }
    if (-not (Test-Path -LiteralPath $Path)) { return }

    $fi  = [System.IO.FileInfo]::new($Path)
    $stubPath = "$Path.teia_stub"

    # Idempotencia: ja ingerido
    if (Test-Path -LiteralPath $stubPath) {
        Write-Log "SKIP_STUB_EXISTS $($fi.Name)" 'DarkGray'
        return
    }

    $route = Get-Route -Path $Path -FileSize $fi.Length
    $strat = $route.Strategy

    $casExt = switch ($strat) {
        'gen.repeat'          { '.teia_seed' }
        'gen.pattern'         { '.teia_seed' }
        'gen.parametric_mesh' { '.br' }
        'cmp.lzma'            { '.gz' }
        'cmp.brotli'          { '.br' }
        default               { '.raw' }
    }

    $origSHA = Get-SHA256File $Path
    $casPath  = Get-CASPath -SHA256 $origSHA -Ext $casExt

    if ($DryRun) {
        Write-Log ("DRYRUN $($fi.Name) strat=$strat rule=$($route.Rule) size=$($fi.Length)") 'DarkYellow'
        return
    }

    try {
        $casTmp  = "$casPath.tmp"
        $stubTmp = "$stubPath.tmp"
        $seedObj = $null

        switch ($strat) {
            'gen.repeat' {
                $bv  = [byte]$route.ByteVal
                $exp = Get-RepeatSHA256 $bv $fi.Length
                if ($exp -ne $origSHA) {
                    # Amostra positiva mas arquivo nao é repeat puro -> fallback lzma
                    $strat = 'cmp.lzma'; $casExt = '.gz'
                    $casPath = Get-CASPath $origSHA $casExt; $casTmp = "$casPath.tmp"
                    Compress-GZip $Path $casTmp
                } else {
                    $seedObj = [ordered]@{
                        opcode = 'gen.repeat'; value_hex = $bv.ToString('x2')
                        size_bytes = [long]$fi.Length; original_sha256 = $origSHA
                    }
                    $seedJson = $seedObj | ConvertTo-Json -Compress
                    [System.IO.File]::WriteAllText($casTmp, $seedJson, $enc)
                }
            }
            'gen.pattern' {
                $p   = [int]$route.Period
                $pat = (Read-Sample $Path)[0..($p - 1)]
                $exp = Get-PatternSHA256 $pat $fi.Length
                if ($exp -ne $origSHA) {
                    $strat = 'cmp.lzma'; $casExt = '.gz'
                    $casPath = Get-CASPath $origSHA $casExt; $casTmp = "$casPath.tmp"
                    Compress-GZip $Path $casTmp
                } else {
                    $seedObj = [ordered]@{
                        opcode = 'gen.pattern'
                        pattern_b64 = [Convert]::ToBase64String($pat)
                        period_bytes = $p; size_bytes = [long]$fi.Length
                        original_sha256 = $origSHA
                    }
                    $seedJson = $seedObj | ConvertTo-Json -Compress
                    [System.IO.File]::WriteAllText($casTmp, $seedJson, $enc)
                }
            }
            'gen.parametric_mesh' {
                Compress-Brotli $Path $casTmp
            }
            'cmp.lzma' {
                Compress-GZip $Path $casTmp
            }
            'cmp.brotli' {
                Compress-Brotli $Path $casTmp
            }
            default {
                Copy-RawCAS $Path $casTmp
            }
        }

        # Atomic: move .tmp -> CAS final
        Move-Item -LiteralPath $casTmp -Destination $casPath -Force

        $casSize = (Get-Item $casPath).Length
        $savings = if ($fi.Length -gt 0) { [Math]::Round((1 - $casSize / $fi.Length) * 100, 2) } else { 0 }

        # Stub JSON
        $stubData = [ordered]@{
            schema              = 'teia_stub_v2'
            original_name       = $fi.Name
            original_path       = $fi.FullName
            original_size_bytes = [long]$fi.Length
            original_sha256     = $origSHA
            final_strategy      = $strat
            cas_encoding        = $casExt.TrimStart('.')
            cas_path            = $casPath
            cas_sha256          = (Get-SHA256File $casPath)
            cas_size_bytes      = $casSize
            savings_pct         = $savings
            ingest_timestamp    = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
        }
        $stubJson = $stubData | ConvertTo-Json -Compress
        [System.IO.File]::WriteAllText($stubTmp, $stubJson, $enc)

        # Atomic: move stub .tmp -> stub final -> delete original
        Move-Item -LiteralPath $stubTmp -Destination $stubPath -Force
        Remove-Item -LiteralPath $Path -Force

        $deltaKB = [Math]::Round(($fi.Length - $casSize) / 1KB, 1)
        Write-Log ("INGEST $($fi.Name)  strat=$strat  orig=$([math]::Round($fi.Length/1KB,1))KB  cas=$([math]::Round($casSize/1KB,1))KB  savings=$savings%  delta=-${deltaKB}KB") 'Green'
    } catch {
        Write-Log "FALHA $($fi.Name): $_" 'Red'
        # Limpeza de temporarios em caso de falha
        if (Test-Path "$casPath.tmp")  { Remove-Item "$casPath.tmp"  -Force -EA SilentlyContinue }
        if (Test-Path "$stubPath.tmp") { Remove-Item "$stubPath.tmp" -Force -EA SilentlyContinue }
    }
}

# ── Fila concorrente (FSW -> queue -> processing loop) ────────────────────────

$script:queue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()

$onCreated = {
    $p = $Event.SourceEventArgs.FullPath
    if (Test-SafeToIngest $p) { $script:queue.Enqueue($p) }
}
$onChanged = {
    $p = $Event.SourceEventArgs.FullPath
    if (Test-SafeToIngest $p) { $script:queue.Enqueue($p) }
}

# ── FileSystemWatcher ─────────────────────────────────────────────────────────

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path                  = $WatchDir
$watcher.IncludeSubdirectories = $true
$watcher.Filter                = '*'
$watcher.NotifyFilter          = [System.IO.NotifyFilters]'FileName,LastWrite,Size'
$watcher.EnableRaisingEvents   = $false

$subCreated = Register-ObjectEvent -InputObject $watcher -EventName 'Created' -Action $onCreated
$subChanged = Register-ObjectEvent -InputObject $watcher -EventName 'Renamed' -Action $onCreated

$script:startTime = Get-Date
$script:ingestCount = 0
$script:skipCount   = 0
$script:failCount   = 0

Write-Host "  Monitorando: $WatchDir" -ForegroundColor Green
Write-Host ''

# ── Processar arquivos existentes (se solicitado) ────────────────────────────

if ($ProcessExisting) {
    Write-Host '  [BATCH] Enfileirando arquivos existentes...' -ForegroundColor Cyan
    $existing = Get-ChildItem -LiteralPath $WatchDir -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { Test-SafeToIngest $_.FullName }
    foreach ($f in $existing) { $script:queue.Enqueue($f.FullName) }
    Write-Host "  [BATCH] $($existing.Count) arquivos enfileirados." -ForegroundColor Cyan
    Write-Host ''
}

# ── Ativar FSW e iniciar loop principal ──────────────────────────────────────

$watcher.EnableRaisingEvents = $true
Write-Host '  Pressione Ctrl+C para parar.' -ForegroundColor DarkGray
Write-Host ('─' * 78)
Write-Host ''

try {
    while ($true) {
        $path = [string]$null
        while ($script:queue.TryDequeue([ref]$path)) {
            if ([string]::IsNullOrEmpty($path)) { continue }
            try {
                Invoke-IngestFile $path
                $script:ingestCount++
            } catch {
                $script:failCount++
                Write-Log "ERRO_QUEUE $path: $_" 'Red'
            }
        }
        Start-Sleep -Milliseconds 250
    }
} finally {
    $watcher.EnableRaisingEvents = $false
    Unregister-Event -SubscriptionId $subCreated.Id -ErrorAction SilentlyContinue
    Unregister-Event -SubscriptionId $subChanged.Id -ErrorAction SilentlyContinue
    $watcher.Dispose()

    $uptime = [int]((Get-Date) - $script:startTime).TotalSeconds
    Write-Host ''
    Write-Host ('─' * 78) -ForegroundColor DarkGray
    Write-Host "  Omni-Ingestor encerrado. Uptime: ${uptime}s" -ForegroundColor DarkGray
    Write-Host "  Ingeridos : $($script:ingestCount)" -ForegroundColor DarkGray
    Write-Host "  Falhas    : $($script:failCount)" -ForegroundColor DarkGray
    Write-Host "  CAS Delta : escrita apenas em $CASRoot" -ForegroundColor DarkGray
    Write-Host ('=' * 78) -ForegroundColor DarkGray
}
