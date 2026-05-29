<#
.SYNOPSIS
    TEIA-System-Manager-v0800.ps1 — Omni-Gestor de Serviço P11.0

.DESCRIPTION
    Serviço de background que monitora D:\TEIA_USER\MyRealData\ e invoca
    o pipeline completo de ingestão TEIA para cada arquivo detectado.

    Pipeline por arquivo:
      FileSystemWatcher → NeuroPlanner inline (HR1→HR6) → AutoSynth (se elegível)
      → Julgamento de Eficiência → CAS write → Substituição por .teia_stub

    Estratégias:
      gen.repeat        → seed JSON (~35B, byte único repetido)
      gen.pattern       → seed JSON (<512B, padrão periódico)
      gen.procedural    → decoder P1 Patch (AutoSynth v0710 ganhou vs LZMA/Brotli)
      cmp.lzma          → GZip Optimal (.gz) — fallback padrão
      cmp.brotli        → Brotli Optimal (.br)
      cas.raw           → cópia raw content-addressed (.raw)

    Contenção P11.0:
      SOMENTE opera em D:\TEIA_USER\MyRealData\.
      Jamais assume raiz C:\ ou D:\.

    Invariante: "Delta" por extenso. Símbolo matemático proibido.

.PARAMETER WatchDir
    Diretório a monitorar. DEVE ser D:\TEIA_USER\MyRealData\ ou subpasta.

.PARAMETER CasRoot
    Raiz do CAS. Padrão: D:\TEIA_CORE\objects

.PARAMETER DecoderDir
    Diretório de decoders P1 Patch. Padrão: D:\TEIA_CORE\decoders

.PARAMETER AutoSynthScript
    Caminho para TEIA-AutoSynth-v0710.ps1. Padrão: D:\TEIA_CORE\tools\TEIA-AutoSynth-v0710.ps1

.PARAMETER OllamaUrl
    URL do servidor Ollama para AutoSynth. Padrão: http://localhost:11434

.PARAMETER Model
    Modelo LLM para AutoSynth. Padrão: qwen2.5-coder:7b

.PARAMETER AutoSynthMaxBytes
    Tamanho máximo de arquivo elegível para AutoSynth. Padrão: 8192

.PARAMETER AutoSynthMaxEntropy
    Entropia máxima para AutoSynth (arquivos mais estruturados). Padrão: 4.8

.PARAMETER PollMs
    Intervalo de polling da fila em ms. Padrão: 250
#>
[CmdletBinding()]
param(
    [string]$WatchDir           = 'D:\TEIA_USER\MyRealData',
    [string]$CasRoot            = 'D:\TEIA_CORE\objects',
    [string]$DecoderDir         = 'D:\TEIA_CORE\decoders',
    [string]$AutoSynthScript    = 'D:\TEIA_CORE\tools\TEIA-AutoSynth-v0710.ps1',
    [string]$SandboxDir         = 'D:\TEIA_CORE\sandbox\autosynth',
    [string]$LogFile            = 'D:\TEIA_CORE\logs\system_manager_v0800.log',
    [string]$OllamaUrl          = 'http://localhost:11434',
    [string]$Model              = 'qwen2.5-coder:7b',
    [int]   $AutoSynthMaxBytes  = 8192,
    [double]$AutoSynthMaxEntropy = 4.8,
    [int]   $PollMs             = 250,
    [switch]$ProcessExisting
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC  = [System.Globalization.CultureInfo]::InvariantCulture
$enc = New-Object System.Text.UTF8Encoding($false)

# ── Contenção P11.0 ───────────────────────────────────────────────────────────
if ($WatchDir -notmatch 'MyRealData') {
    Write-Host "[MGR] CONTENCAO P11.0: WatchDir deve conter 'MyRealData': $WatchDir" -ForegroundColor Red
    exit 1
}

# ── Diretórios ────────────────────────────────────────────────────────────────
New-Item -ItemType Directory -Path $WatchDir    -Force | Out-Null
New-Item -ItemType Directory -Path $CasRoot     -Force | Out-Null
New-Item -ItemType Directory -Path $DecoderDir  -Force | Out-Null
New-Item -ItemType Directory -Path $SandboxDir  -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null

# ── Logging ───────────────────────────────────────────────────────────────────
function Write-Log([string]$msg, [string]$color = 'Gray') {
    $ts   = (Get-Date).ToString('HH:mm:ss.fff', $IC)
    $line = "[$ts] $msg"
    Write-Host "  $line" -ForegroundColor $color
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 -EA SilentlyContinue } catch {}
}

Write-Host ''
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host '  TEIA-System-Manager v0.80.0 — Omni-Gestor P11.0' -ForegroundColor Cyan
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host "  WatchDir  : $WatchDir"
Write-Host "  CasRoot   : $CasRoot"
Write-Host "  AutoSynth : $AutoSynthScript"
Write-Host "  Model     : $Model"
Write-Host "  AutoSynth : max $AutoSynthMaxBytes bytes / entropia < $AutoSynthMaxEntropy"
Write-Host ''

# ── Extensões excluídas (nunca ingerir) ───────────────────────────────────────
$SKIP_EXT = [System.Collections.Generic.HashSet[string]]::new([string[]]@(
    '.dll','.exe','.sys','.drv','.ocx','.scr','.com','.bat','.cmd','.msc',
    '.cpl','.acm','.ax','.mui','.mun','.ptxml','.lnk','.ini','.msi','.cat',
    '.inf','.reg','.manifest','.mof','.teia_stub','.teia_seed',
    '.tmp','.temp','.lock','.part','.crdownload'
), [System.StringComparer]::OrdinalIgnoreCase)

# ── Helpers: SHA-256, Entropia ────────────────────────────────────────────────
function Get-Sha256([string]$path) {
    (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLower()
}

function Compute-Entropy([byte[]]$bytes) {
    if ($bytes.Length -eq 0) { return 0.0 }
    $freq  = New-Object int[] 256
    foreach ($b in $bytes) { $freq[$b]++ }
    $total = [double]$bytes.Length
    $H     = 0.0
    foreach ($c in $freq) {
        if ($c -gt 0) { $p = $c / $total; $H -= $p * [Math]::Log($p, 2) }
    }
    [Math]::Round($H, 4)
}

# ── CAS path builder ──────────────────────────────────────────────────────────
function Get-CasPath([string]$sha256, [string]$ext) {
    $a = $sha256.Substring(0, 2); $b = $sha256.Substring(2, 2)
    $dir = Join-Path $CasRoot "$a\$b"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Join-Path $dir "${sha256}${ext}"
}

# ── NeuroPlanner inline (HR1→HR6→LLM_FALLBACK) ───────────────────────────────
function Get-UniqueByte([byte[]]$bytes) {
    if ($bytes.Length -eq 0) { return -1 }
    $first = $bytes[0]
    foreach ($b in $bytes) { if ($b -ne $first) { return -1 } }
    return $first
}

function Find-Period([byte[]]$bytes) {
    $probe = [Math]::Min($bytes.Length, 512)
    for ($p = 1; $p -le 64; $p++) {
        $ok = $true
        for ($j = $p; $j -lt $probe; $j++) {
            if ($bytes[$j] -ne $bytes[$j % $p]) { $ok = $false; break }
        }
        if ($ok) { return $p }
    }
    return 0
}

function Test-CompressedMagic([byte[]]$sample) {
    if ($sample.Length -lt 4) { return $false }
    $h = $sample[0..3]
    ($h[0] -eq 0x1F -and $h[1] -eq 0x8B) -or   # GZip
    ($h[0] -eq 0x50 -and $h[1] -eq 0x4B) -or   # ZIP/PK
    ($h[0] -eq 0x89 -and $h[1] -eq 0x50 -and $h[2] -eq 0x4E -and $h[3] -eq 0x47) -or # PNG
    ($h[0] -eq 0xFF -and $h[1] -eq 0xD8) -or   # JPEG
    ($h[0] -eq 0x52 -and $h[1] -eq 0x61 -and $h[2] -eq 0x72)  # RAR
}

function Get-NeuroRoute([string]$path, [byte[]]$bytes, [long]$fileSize) {
    $sampleLen = [Math]::Min(65536, $bytes.Length)
    $sample    = $bytes[0..($sampleLen - 1)]
    $entropy   = Compute-Entropy $bytes

    # HR4: magic bytes de formato já comprimido
    if (Test-CompressedMagic $sample) { return @{ Strategy='cas.raw'; Rule='HR4'; Entropy=$entropy } }

    # HR3: entropia muito alta → cas.raw
    if ($entropy -ge 7.0) { return @{ Strategy='cas.raw'; Rule='HR3'; Entropy=$entropy } }

    # HR1: byte único repetido
    $uByte = Get-UniqueByte $sample
    if ($uByte -ge 0) { return @{ Strategy='gen.repeat'; Rule='HR1'; ByteVal=$uByte; Entropy=$entropy } }

    # HR2: padrão periódico curto
    $period = Find-Period $sample
    if ($period -gt 0) { return @{ Strategy='gen.pattern'; Rule='HR2'; Period=$period; Entropy=$entropy } }

    # HR5: arquivo pequeno → brotli
    if ($fileSize -lt 8192) { return @{ Strategy='cmp.brotli'; Rule='HR5'; Entropy=$entropy } }

    # LLM_FALLBACK: cmp.lzma (GZip Optimal)
    return @{ Strategy='cmp.lzma'; Rule='LLM_FALLBACK'; Entropy=$entropy }
}

# ── Compressão LZMA (GZip) e Brotli ──────────────────────────────────────────
function Compress-ToLzma([byte[]]$bytes) {
    $ms  = New-Object System.IO.MemoryStream
    $gz  = New-Object System.IO.Compression.GZipStream($ms,
               [System.IO.Compression.CompressionLevel]::Optimal)
    $gz.Write($bytes, 0, $bytes.Length); $gz.Close()
    $result = $ms.ToArray(); $ms.Dispose(); $result
}

function Compress-ToBrotli([byte[]]$bytes) {
    $ms  = New-Object System.IO.MemoryStream
    $br  = New-Object System.IO.Compression.BrotliStream($ms,
               [System.IO.Compression.CompressionLevel]::Optimal)
    $br.Write($bytes, 0, $bytes.Length); $br.Close()
    $result = $ms.ToArray(); $ms.Dispose(); $result
}

# ── AutoSynth: elegibilidade e invocação ─────────────────────────────────────
function Test-AutoSynthEligible([byte[]]$bytes, [long]$fileSize, [double]$entropy, [string]$ext) {
    if ($fileSize -gt $AutoSynthMaxBytes) { return $false }
    if ($entropy -gt $AutoSynthMaxEntropy) { return $false }
    if ($ext -in @('.bin','.exe','.dll','.png','.jpg','.mp4','.gz','.br')) { return $false }
    if (-not (Test-Path $AutoSynthScript)) { return $false }
    return $true
}

function Invoke-AutoSynth([string]$filePath) {
    $resultFile = Join-Path $SandboxDir "mgr_result_$(Get-Random).json"
    try {
        $proc = Start-Process pwsh -ArgumentList @(
            '-ExecutionPolicy', 'Bypass',
            '-NonInteractive',
            '-File', $AutoSynthScript,
            '-InputFile', $filePath,
            '-ResultFile', $resultFile,
            '-Silent',
            '-Tries', '2',
            '-LlmTimeoutSec', '180'
        ) -Wait -PassThru -WindowStyle Hidden
        if ((Test-Path $resultFile)) {
            $r = Get-Content $resultFile -Raw | ConvertFrom-Json
            Remove-Item $resultFile -Force -EA SilentlyContinue
            return $r
        }
    } catch {
        Write-Log "AutoSynth excecao: $_" 'DarkYellow'
    }
    Remove-Item $resultFile -Force -EA SilentlyContinue
    return $null
}

# ── Criação de stub ───────────────────────────────────────────────────────────
function Write-Stub([string]$originalPath, [hashtable]$fields) {
    $stubPath = "${originalPath}.teia_stub"
    $json     = $fields | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllBytes($stubPath, $enc.GetBytes($json))
}

# ── Ingestão de um arquivo ───────────────────────────────────────────────────
function Invoke-IngestFile([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return }
    if ($path -like '*.teia_stub') { return }
    if ($path -like '*.teia_seed') { return }

    $fi  = Get-Item -LiteralPath $path -EA SilentlyContinue
    if ($null -eq $fi) { return }

    $ext = $fi.Extension.ToLower()
    if ($SKIP_EXT.Contains($ext)) {
        Write-Log "SKIP ext: $($fi.Name)" 'DarkGray'; return
    }

    # Verificar se já tem stub (idempotência)
    if (Test-Path "${path}.teia_stub") {
        Write-Log "SKIP (stub existe): $($fi.Name)" 'DarkGray'; return
    }

    $fileSize = $fi.Length
    if ($fileSize -eq 0) { Write-Log "SKIP (vazio): $($fi.Name)" 'DarkGray'; return }

    Write-Log "INGERINDO: $($fi.Name) ($fileSize bytes)" 'White'

    $bytes    = [System.IO.File]::ReadAllBytes($path)
    $origSha  = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLower()
    $entropy  = Compute-Entropy $bytes
    $ts       = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')

    # ── AutoSynth path (P1 Patch) ─────────────────────────────────────────────
    if (Test-AutoSynthEligible $bytes $fileSize $entropy $ext) {
        Write-Log "  AutoSynth elegivel — invocando forja..." 'Yellow'
        $asResult = Invoke-AutoSynth $path
        if ($asResult -and $asResult.verdict -eq 'ONTOPROCEDURAL') {
            $casSize     = $asResult.combined_size
            $savingsPct  = if ($fileSize -gt 0) { [Math]::Round(100.0 * ($fileSize - $casSize) / $fileSize, 1) } else { 0.0 }
            Write-Log "  P1 PATCH APROVADO: gen.procedural ($casSize bytes, Delta economia: $savingsPct%)" 'Green'
            Write-Stub $path @{
                original_name        = $fi.Name
                original_size_bytes  = $fileSize
                original_sha256      = $origSha
                final_strategy       = 'gen.procedural'
                cas_encoding         = 'procedure'
                cas_path             = $null
                decoder_id           = $asResult.decoder_id
                decoder_path         = $asResult.decoder_path
                seed_path            = $asResult.seed_path
                cas_size_bytes       = $casSize
                savings_pct          = $savingsPct
                ingest_timestamp     = $ts
            }
            Remove-Item -LiteralPath $path -Force
            Write-Log "  CONCLUIDO gen.procedural: $($fi.Name)" 'Green'
            return
        }
        Write-Log "  AutoSynth: classico vence — prosseguindo via NeuroPlanner" 'DarkYellow'
    }

    # ── NeuroPlanner routing (HR1→HR6→LLM_FALLBACK) ──────────────────────────
    $route   = Get-NeuroRoute $path $bytes $fileSize
    $strat   = $route.Strategy
    $rule    = $route.Rule
    Write-Log "  Rota: $strat ($rule | entropia=$($route.Entropy))" 'DarkCyan'

    $casExt  = switch ($strat) {
        'gen.repeat'  { '.teia_seed' }
        'gen.pattern' { '.teia_seed' }
        'cmp.lzma'    { '.gz'        }
        'cmp.brotli'  { '.br'        }
        default       { '.raw'       }
    }
    $casPath = Get-CasPath $origSha $casExt

    # Idempotência: se CAS já existe com mesmo hash, pular compressão
    $casSha   = $null
    $casBytes = 0

    switch ($strat) {
        'gen.repeat' {
            $byteVal = $route.ByteVal
            $seed    = @{ strategy='gen.repeat'; value_hex=$byteVal.ToString('X2'); size=$fileSize } | ConvertTo-Json
            if (-not (Test-Path $casPath)) { [System.IO.File]::WriteAllBytes($casPath, $enc.GetBytes($seed)) }
            $casBytes = (Get-Item $casPath).Length
            $casSha   = (Get-FileHash $casPath -Algorithm SHA256).Hash.ToLower()
        }
        'gen.pattern' {
            $period  = $route.Period
            $pattern = $bytes[0..($period - 1)]
            $patB64  = [Convert]::ToBase64String($pattern)
            $seed    = @{ strategy='gen.pattern'; pattern_b64=$patB64; period=$period; size=$fileSize } | ConvertTo-Json
            if (-not (Test-Path $casPath)) { [System.IO.File]::WriteAllBytes($casPath, $enc.GetBytes($seed)) }
            $casBytes = (Get-Item $casPath).Length
            $casSha   = (Get-FileHash $casPath -Algorithm SHA256).Hash.ToLower()
        }
        'cmp.lzma' {
            if (-not (Test-Path $casPath)) {
                $compressed = Compress-ToLzma $bytes
                [System.IO.File]::WriteAllBytes($casPath, $compressed)
            }
            $casBytes = (Get-Item $casPath).Length
            $casSha   = (Get-FileHash $casPath -Algorithm SHA256).Hash.ToLower()
        }
        'cmp.brotli' {
            if (-not (Test-Path $casPath)) {
                $compressed = Compress-ToBrotli $bytes
                [System.IO.File]::WriteAllBytes($casPath, $compressed)
            }
            $casBytes = (Get-Item $casPath).Length
            $casSha   = (Get-FileHash $casPath -Algorithm SHA256).Hash.ToLower()
        }
        default {  # cas.raw
            if (-not (Test-Path $casPath)) {
                [System.IO.File]::Copy($path, $casPath, $false)
            }
            $casBytes = (Get-Item $casPath).Length
            $casSha   = $origSha
        }
    }

    $savingsPct = if ($fileSize -gt 0) { [Math]::Round(100.0 * ($fileSize - $casBytes) / $fileSize, 1) } else { 0.0 }

    Write-Stub $path @{
        original_name        = $fi.Name
        original_size_bytes  = $fileSize
        original_sha256      = $origSha
        final_strategy       = $strat
        cas_encoding         = switch ($strat) {
            'gen.repeat'   { 'teia_seed' }
            'gen.pattern'  { 'teia_seed' }
            'cmp.lzma'     { 'gz' }
            'cmp.brotli'   { 'br' }
            default        { 'raw' }
        }
        cas_path             = $casPath
        cas_sha256           = $casSha
        cas_size_bytes       = $casBytes
        savings_pct          = $savingsPct
        ingest_timestamp     = $ts
    }

    Remove-Item -LiteralPath $path -Force
    Write-Log "  CONCLUIDO ${strat}: $($fi.Name) | CAS $casBytes bytes | Delta economia: $savingsPct%" 'Green'
}

# ── Processar arquivos existentes ─────────────────────────────────────────────
Write-Log "Processando arquivos existentes em $WatchDir..." 'Cyan'
$existing = Get-ChildItem -LiteralPath $WatchDir -Recurse -File -EA SilentlyContinue |
    Where-Object { $_.Extension -ne '.teia_stub' -and $_.Extension -ne '.teia_seed' }
foreach ($f in $existing) {
    try { Invoke-IngestFile $f.FullName } catch { Write-Log "ERRO $($f.Name): $_" 'Red' }
}
Write-Log "Arquivos existentes processados: $($existing.Count)" 'Cyan'

if ($ProcessExisting) {
    Write-Log "Modo -ProcessExisting: encerrando apos ingestao inicial." 'Cyan'
    exit 0
}

# ── FileSystemWatcher + ConcurrentQueue ──────────────────────────────────────
$script:queue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()

$fsw = New-Object System.IO.FileSystemWatcher
$fsw.Path                  = $WatchDir
$fsw.NotifyFilter          = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite
$fsw.IncludeSubdirectories = $false
$fsw.EnableRaisingEvents   = $true

$enqueue = {
    param($s, $e)
    $p = $e.FullPath
    if ($p -notlike '*.teia_stub' -and $p -notlike '*.teia_seed') {
        $script:queue.Enqueue($p)
    }
}
Register-ObjectEvent -InputObject $fsw -EventName Created -Action $enqueue | Out-Null
Register-ObjectEvent -InputObject $fsw -EventName Changed -Action $enqueue | Out-Null

Write-Log "FileSystemWatcher ativo em $WatchDir" 'Green'
Write-Log "Aguardando eventos... (Ctrl+C para parar)" 'Cyan'
Write-Host ''

# ── Main loop ─────────────────────────────────────────────────────────────────
try {
    while ($true) {
        $path = [string]$null
        while ($script:queue.TryDequeue([ref]$path)) {
            try {
                Start-Sleep -Milliseconds 200  # wait for file write to complete
                Invoke-IngestFile $path
            } catch {
                Write-Log "ERRO processando ${path}: $_" 'Red'
            }
        }
        Start-Sleep -Milliseconds $PollMs
    }
} finally {
    $fsw.EnableRaisingEvents = $false
    $fsw.Dispose()
    Write-Log "Omni-Gestor encerrado." 'DarkYellow'
}
