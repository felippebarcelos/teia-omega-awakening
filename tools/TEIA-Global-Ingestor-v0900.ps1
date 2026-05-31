<#
.SYNOPSIS
    TEIA-Global-Ingestor-v0900.ps1 — Ingestor Silencioso de Background
.DESCRIPTION
    Daemon contínuo que monitora D:\TEIA_USER\Managed_Zone\ via FileSystemWatcher.
    Para cada arquivo novo elegível:
      1. NeuroPlanner: calcula entropia, detecta tipo, decide estratégia
      2. Invoca TEIA-AutoSynth-v0720.ps1 para sintetizar decoder + semente
      3. Cria .teia_stub atômico (write-to-tmp + rename) na mesma pasta
    O VFS v0900 detecta o novo stub via hot-reload e o expõe em T:\ automaticamente.

    Critério de elegibilidade: arquivo texto/log com entropia < 5.5 bits/byte.
    Arquivos .teia_stub, .tmp, .dec são ignorados.
#>
[CmdletBinding()]
param(
    [string]$WatchDir     = 'D:\TEIA_USER\Managed_Zone',
    [string]$AutoSynthPath = 'D:\TEIA_CORE\tools\TEIA-AutoSynth-v0720.ps1',
    [string]$CasRoot      = 'D:\TEIA_CORE\objects',
    [string]$DecoderDir   = 'D:\TEIA_CORE\decoders',
    [string]$LogFile      = 'D:\TEIA_CORE\logs\ingestor_v0900.log',
    [int]   $SynthTimeout = 300,
    [switch]$ProcessExisting
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC = [System.Globalization.CultureInfo]::InvariantCulture

New-Item -ItemType Directory -Path $WatchDir -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null

$script:queue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()

function Write-Log([string]$Msg, [string]$Color = 'Gray') {
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff', $IC)
    $line = "[$ts] $Msg"
    Write-Host "  $line" -ForegroundColor $Color
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 } catch {}
}

# ── NeuroPlanner mínimo: entropia Shannon + classificação ─────────────────────

function Get-Entropy([byte[]]$Bytes) {
    if ($Bytes.Length -eq 0) { return 0.0 }
    $freq = New-Object int[] 256
    foreach ($b in $Bytes) { $freq[$b]++ }
    $len = [double]$Bytes.Length; $entropy = 0.0
    foreach ($f in $freq) {
        if ($f -gt 0) {
            $p = $f / $len
            $entropy -= $p * [Math]::Log($p, 2)
        }
    }
    return $entropy
}

function Invoke-NeuroPlanner([string]$FilePath) {
    $info    = Get-Item -LiteralPath $FilePath
    $ext     = $info.Extension.ToLower()
    $sampleSz = [int][Math]::Min($info.Length, 8192)
    $bytes   = New-Object byte[] $sampleSz
    $fs      = [System.IO.File]::OpenRead($FilePath)
    try { [void]$fs.Read($bytes, 0, $sampleSz) } finally { $fs.Dispose() }

    $entropy = Get-Entropy $bytes

    # Detectar line ending e tipo
    $sample     = [System.Text.Encoding]::UTF8.GetString($bytes, 0, [Math]::Min($sampleSz, 2048))
    $lineEnding = if ($sample -match "\r\n") { 'CRLF' } elseif ($sample -match "\n") { 'LF' } else { 'NONE' }
    $isText     = $entropy -lt 5.5 -and $lineEnding -ne 'NONE'
    $isLog      = $ext -in @('.log', '.txt', '.csv') -and $isText

    return @{
        file_path    = $FilePath
        file_size    = $info.Length
        entropy      = [math]::Round($entropy, 4)
        line_ending  = $lineEnding
        is_text      = $isText
        is_log       = $isLog
        eligible     = $isLog
        strategy_hint = if ($isLog) { 'autosynth' } else { 'cmp.lzma' }
    }
}

# ── Criação atômica do stub ───────────────────────────────────────────────────

function Write-Stub([hashtable]$Result, [string]$OriginalFile) {
    $stubPath = $OriginalFile + '.teia_stub'
    $tmpPath  = $stubPath + '.tmp'
    $stub = [ordered]@{
        original_name       = [System.IO.Path]::GetFileName($OriginalFile)
        original_size_bytes = $Result.original_size
        original_sha256     = $Result.original_sha256
        final_strategy      = $Result.final_strategy
        cas_encoding        = if ($Result.cas_encoding) { $Result.cas_encoding } else { 'none' }
        cas_path            = if ($Result.cas_path)     { $Result.cas_path }     else { '' }
        cas_size_bytes      = $Result.cas_size
        savings_pct         = [math]::Round(100.0 * (1.0 - $Result.cas_size / $Result.original_size), 2)
        decoder_path        = if ($Result.decoder_path) { $Result.decoder_path } else { '' }
        seed_path           = if ($Result.seed_path)    { $Result.seed_path }    else { '' }
        ingestor_ts         = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ', $IC)
    }
    $json = $stub | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllText($tmpPath, $json, [System.Text.Encoding]::UTF8)
    Move-Item -LiteralPath $tmpPath -Destination $stubPath -Force
    Write-Log "Stub criado: $([System.IO.Path]::GetFileName($stubPath)) — $($stub.final_strategy) — savings=$($stub.savings_pct)%" 'Green'
}

# ── Processa um arquivo ───────────────────────────────────────────────────────

function Invoke-ProcessFile([string]$FilePath) {
    if (-not (Test-Path -LiteralPath $FilePath)) { return }
    $ext = [System.IO.Path]::GetExtension($FilePath).ToLower()
    if ($ext -in @('.teia_stub', '.tmp', '.dec', '.ps1', '.py')) {
        Write-Log "Ignorado (tipo): $([System.IO.Path]::GetFileName($FilePath))" 'DarkGray'
        return
    }
    $stubPath = $FilePath + '.teia_stub'
    if (Test-Path -LiteralPath $stubPath) {
        Write-Log "Já processado (stub existe): $([System.IO.Path]::GetFileName($FilePath))" 'DarkGray'
        return
    }

    $plan = Invoke-NeuroPlanner $FilePath
    Write-Log "NeuroPlanner: $([System.IO.Path]::GetFileName($FilePath))  entropy=$($plan.entropy)  eligible=$($plan.eligible)" 'Cyan'

    if (-not $plan.eligible) {
        Write-Log "Não elegível para AutoSynth — estratégia sugerida: $($plan.strategy_hint)" 'DarkYellow'
        return
    }

    if (-not (Test-Path -LiteralPath $AutoSynthPath)) {
        Write-Log "AutoSynth não encontrado: $AutoSynthPath" 'Red'; return
    }

    Write-Log "Iniciando AutoSynth para: $([System.IO.Path]::GetFileName($FilePath))" 'White'
    $resultFile = "$FilePath.autosynth_result.json"

    $proc = Start-Process -FilePath 'pwsh.exe' `
        -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$AutoSynthPath,
                      '-TargetFile',$FilePath,'-ResultFile',$resultFile,
                      '-DecoderDir',$DecoderDir,'-CasRoot',$CasRoot `
        -PassThru -NoNewWindow

    $timeout = [System.Diagnostics.Stopwatch]::StartNew()
    while (-not $proc.HasExited -and $timeout.Elapsed.TotalSeconds -lt $SynthTimeout) {
        Start-Sleep -Milliseconds 500
    }

    if (-not $proc.HasExited) {
        $proc.Kill()
        Write-Log "TIMEOUT AutoSynth para $([System.IO.Path]::GetFileName($FilePath)) após ${SynthTimeout}s" 'Red'
        return
    }

    if (-not (Test-Path -LiteralPath $resultFile)) {
        Write-Log "AutoSynth sem ResultFile para $([System.IO.Path]::GetFileName($FilePath))" 'Red'
        return
    }

    try {
        $result = Get-Content -LiteralPath $resultFile -Raw | ConvertFrom-Json -AsHashtable
        Remove-Item -LiteralPath $resultFile -Force -ErrorAction SilentlyContinue

        if ($result.verdict -eq 'ONTOPROCEDURAL' -or $result.verdict -eq 'CLASSICAL') {
            Write-Stub $result $FilePath
        } else {
            Write-Log "AutoSynth FAILED para $([System.IO.Path]::GetFileName($FilePath)): $($result.verdict)" 'Yellow'
        }
    } catch {
        Write-Log "Erro ao processar resultado AutoSynth: $_" 'Red'
    }
}

# ── FileSystemWatcher ─────────────────────────────────────────────────────────

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path                = $WatchDir
$watcher.Filter              = '*.*'
$watcher.IncludeSubdirectories = $false
$watcher.NotifyFilter        = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite

$onCreated = Register-ObjectEvent -InputObject $watcher -EventName Created -Action {
    $script:queue.Enqueue($Event.SourceEventArgs.FullPath)
}
$onChanged = Register-ObjectEvent -InputObject $watcher -EventName Changed -Action {
    $script:queue.Enqueue($Event.SourceEventArgs.FullPath)
}

$watcher.EnableRaisingEvents = $true

Write-Host ''
Write-Host ('=' * 70) -ForegroundColor Cyan
Write-Host '  TEIA-Global-Ingestor v0.90.0 — Daemon de Ingestão Silenciosa' -ForegroundColor Cyan
Write-Host ('─' * 70)
Write-Host "  WatchDir   : $WatchDir"
Write-Host "  AutoSynth  : $AutoSynthPath"
Write-Host "  DecoderDir : $DecoderDir"
Write-Host "  CasRoot    : $CasRoot"
Write-Host "  Timeout    : ${SynthTimeout}s por arquivo"
Write-Host ''
Write-Host '  Aguardando arquivos novos em WatchDir...' -ForegroundColor Green
Write-Host '  Pressione Ctrl+C para parar.' -ForegroundColor DarkGray
Write-Host ('─' * 70)

# Processar arquivos existentes se solicitado
if ($ProcessExisting) {
    Write-Log "Processando arquivos existentes em $WatchDir..." 'DarkCyan'
    Get-ChildItem -LiteralPath $WatchDir -File | ForEach-Object {
        $script:queue.Enqueue($_.FullName)
    }
}

# ── Loop principal ────────────────────────────────────────────────────────────

$seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

try {
    while ($true) {
        $path = $null
        while ($script:queue.TryDequeue([ref]$path)) {
            if ($seen.Add($path)) {
                # Debounce: aguarda 1s para garantir que a escrita terminou
                Start-Sleep -Milliseconds 1000
                try { Invoke-ProcessFile $path }
                catch { Write-Log "ERRO processando $path: $_" 'Red' }
                [void]$seen.Remove($path)  # permite reprocessar se modificado novamente
            }
        }
        Start-Sleep -Milliseconds 200
    }
} finally {
    $watcher.EnableRaisingEvents = $false
    Unregister-Event -SourceIdentifier $onCreated.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $onChanged.Name -ErrorAction SilentlyContinue
    $watcher.Dispose()
    Write-Host ''
    Write-Host '  Ingestor encerrado.' -ForegroundColor DarkGray
}
