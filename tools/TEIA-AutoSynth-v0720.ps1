<#
.SYNOPSIS
    TEIA-AutoSynth-v0720.ps1 — Forja Ontoprocedural P13.1 (Análise Sintática de Logs)

.DESCRIPTION
    Versão v0720: adiciona análise semântica para arquivos de log/text estruturados.
    Para esses arquivos, substitui o HexDump truncado por:
      - line_count         — número exato de linhas
      - first_lines        — primeiras N linhas completas (padrão: 6)
      - last_lines         — últimas N linhas completas
      - unique_levels      — valores únicos de nível (INFO/WARN/etc.) via regex
      - unique_hosts       — valores únicos de host ([...]) via regex
      - latency_samples    — amostra de latências para inferência de fórmula
    O prompt instrui o LLM a escrever um FOR LOOP, proibindo embed-content.

    Fases de Execução (idênticas ao v0710 após a Fase 1):
      FASE 1   — Análise Estrutural: HexDump OU Análise de Log
      FASE 2   — Síntese via LLM
      FASE 3   — Parsing da Resposta
      FASE 4   — Crucível: Runspace isolado + SHA-256
      FASE 4.5 — Julgamento de Eficiência: Ontoprocedural vs LZMA vs Brotli
      FASE 5   — Cristalização (apenas se ONTOPROCEDURAL)

    Invariantes:
      - "Delta" sempre por extenso. Símbolo matemático correspondente é PROIBIDO.
      - Decoder deve garantir Write == Read sem dependências externas.
      - Runspace isolado com timeout de 30s.

.PARAMETER InputFile
    Arquivo a analisar. Para log analysis: .log, .csv, .txt com entropy < 5.5

.PARAMETER OllamaUrl
    URL base do servidor Ollama. Padrão: http://localhost:11434

.PARAMETER Model
    Modelo Ollama. Padrão: qwen2.5-coder:7b

.PARAMETER Tries
    Tentativas de síntese em caso de falha. Padrão: 3

.PARAMETER SampleLines
    Linhas amostradas do início e fim para análise de log. Padrão: 6

.PARAMETER HexSampleBytes
    Bytes enviados no hexdump (apenas para arquivos não-log). Padrão: 512

.PARAMETER DecoderTimeoutMs
    Timeout do decoder no Runspace. Padrão: 60000

.PARAMETER LlmTimeoutSec
    Timeout HTTP da chamada ao LLM. Padrão: 300

.PARAMETER DryRun
    Executa fases 1-2 (análise + prompt) sem chamar o LLM.

.PARAMETER ResultFile
    Se especificado, escreve resultado JSON (verdict, sizes) para o chamador.

.PARAMETER Silent
    Suprime toda saída Write-Host.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$InputFile,

    [string]$OllamaUrl       = 'http://localhost:11434',
    [string]$Model           = 'qwen2.5-coder:7b',
    [string]$SandboxDir      = 'D:\TEIA_CORE\sandbox\autosynth',
    [string]$DecoderDir      = 'D:\TEIA_CORE\decoders',
    [int]$Tries              = 3,
    [int]$SampleLines        = 6,
    [int]$HexSampleBytes     = 512,
    [int]$DecoderTimeoutMs   = 60000,
    [int]$LlmTimeoutSec      = 300,
    [switch]$DryRun,
    [string]$ResultFile      = '',
    [switch]$Silent
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC  = [System.Globalization.CultureInfo]::InvariantCulture
$enc = New-Object System.Text.UTF8Encoding($false)

# ── Logging ───────────────────────────────────────────────────────────────────
function Write-Phase([string]$t) {
    if ($Silent) { return }
    Write-Host ''
    Write-Host ('─' * 72) -ForegroundColor Cyan
    Write-Host "  $t" -ForegroundColor Cyan
    Write-Host ('─' * 72) -ForegroundColor Cyan
}
function Write-OK   ([string]$t) { if (-not $Silent) { Write-Host "  [OK]    $t" -ForegroundColor Green  } }
function Write-FAIL ([string]$t) { if (-not $Silent) { Write-Host "  [FAIL]  $t" -ForegroundColor Red    } }
function Write-INFO ([string]$t) { if (-not $Silent) { Write-Host "  [INFO]  $t" -ForegroundColor Gray   } }
function Write-SYNTH([string]$t) { if (-not $Silent) { Write-Host "  [SYNTH] $t" -ForegroundColor Yellow } }

# ── Julgamento de Eficiência ──────────────────────────────────────────────────
function Compare-ClassicalCompression([byte[]]$bytes) {
    $opts = [System.IO.Compression.CompressionLevel]::Optimal
    $ms1  = New-Object System.IO.MemoryStream
    $gz   = New-Object System.IO.Compression.GZipStream($ms1, $opts, $true)
    $gz.Write($bytes, 0, $bytes.Length); $gz.Dispose()
    $lzmaSize = [long]$ms1.Length; $ms1.Dispose()

    $ms2  = New-Object System.IO.MemoryStream
    $br   = New-Object System.IO.Compression.BrotliStream($ms2, $opts, $true)
    $br.Write($bytes, 0, $bytes.Length); $br.Dispose()
    $brotliSize = [long]$ms2.Length; $ms2.Dispose()

    $best = if ($brotliSize -lt $lzmaSize) { 'cmp.brotli' } else { 'cmp.lzma' }
    return @{
        LzmaBytes    = $lzmaSize
        BrotliBytes  = $brotliSize
        BestBytes    = [Math]::Min($lzmaSize, $brotliSize)
        BestStrategy = $best
    }
}

if (-not $Silent) {
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host '  TEIA-AutoSynth v0.72.0 — Forja Ontoprocedural (Log Syntax Analysis)' -ForegroundColor Cyan
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host "  Arquivo  : $InputFile"
    Write-Host "  Modelo   : $Model  (Tries: $Tries)"
    Write-Host "  Modo     : $(if ($DryRun) { 'DRY-RUN' } else { 'ATIVO' })"
    Write-Host ''
}

# ── Validação de entrada ──────────────────────────────────────────────────────
if (-not (Test-Path -LiteralPath $InputFile)) {
    Write-FAIL "Arquivo nao encontrado: $InputFile"; exit 1
}
$fileInfo = Get-Item -LiteralPath $InputFile
if ($fileInfo.Length -eq 0) { Write-FAIL 'Arquivo vazio.'; exit 1 }

foreach ($d in @($SandboxDir, $DecoderDir)) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

# ─────────────────────────────────────────────────────────────────────────────
# FUNÇÕES — FASE 1: Análise Estrutural
# ─────────────────────────────────────────────────────────────────────────────

function Compute-Entropy([byte[]]$bytes) {
    if ($bytes.Length -eq 0) { return 0.0 }
    $freq  = New-Object int[] 256
    foreach ($b in $bytes) { $freq[$b]++ }
    $total = [double]$bytes.Length; $H = 0.0
    foreach ($c in $freq) {
        if ($c -gt 0) { $p = $c / $total; $H -= $p * [Math]::Log($p, 2) }
    }
    [Math]::Round($H, 4)
}

function Build-HexDump([byte[]]$sample) {
    $sb = [System.Text.StringBuilder]::new()
    for ($i = 0; $i -lt $sample.Length; $i += 16) {
        $end   = [Math]::Min($i + 15, $sample.Length - 1)
        $chunk = $sample[$i..$end]
        $hex   = ($chunk | ForEach-Object { $_.ToString('X2', $IC) }) -join ' '
        $asc   = ($chunk | ForEach-Object { if ($_ -ge 32 -and $_ -le 126) { [char]$_ } else { '.' } }) -join ''
        [void]$sb.AppendLine(("{0:X4}  {1,-47}  {2}" -f $i, $hex, $asc))
    }
    $sb.ToString().TrimEnd()
}

function Get-TopFrequency([byte[]]$bytes, [int]$top = 12) {
    $freq  = New-Object int[] 256
    foreach ($b in $bytes) { $freq[$b]++ }
    $total = $bytes.Length
    $lines = [System.Collections.Generic.List[string]]::new()
    $sorted = (0..255) | Where-Object { $freq[$_] -gt 0 } | Sort-Object { -$freq[$_] } | Select-Object -First $top
    foreach ($v in $sorted) {
        $pct  = [Math]::Round(100.0 * $freq[$v] / $total, 1)
        $repr = if ($v -ge 32 -and $v -le 126) { [char]$v } else { '·' }
        $lines.Add(("  0x{0:X2} ('{1}'): {2,8} ocorrencias ({3}%)" -f $v, $repr, $freq[$v], $pct))
    }
    $lines -join "`n"
}

function Detect-UniqueByteRun([byte[]]$bytes) {
    if ($bytes.Length -eq 0) { return $null }
    $first = $bytes[0]
    foreach ($b in $bytes) { if ($b -ne $first) { return $null } }
    return $first
}

function Detect-Period([byte[]]$bytes, [int]$maxPeriod = 64) {
    if ($bytes.Length -lt 4) { return 0 }
    $probe = [Math]::Min($bytes.Length, 512)
    for ($p = 1; $p -le $maxPeriod; $p++) {
        $ok = $true
        for ($j = $p; $j -lt $probe; $j++) {
            if ($bytes[$j] -ne $bytes[$j % $p]) { $ok = $false; break }
        }
        if ($ok) { return $p }
    }
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# NOVA EM v0720 — Análise Semântica de Log/Texto Estruturado
# ─────────────────────────────────────────────────────────────────────────────

function Analyze-LogSchema {
    param(
        [string[]]$AllLines,
        [string]  $LineEnding,
        [int]     $SampleN = 6
    )

    $total = $AllLines.Count

    # Linhas de amostra (início e fim)
    $firstN = $AllLines[0..[Math]::Min($SampleN - 1, $total - 1)]
    $lastN  = if ($total -gt $SampleN) {
        $AllLines[($total - $SampleN)..($total - 1)]
    } else { @() }

    # Extrair valores únicos de LEVEL (INFO/WARN/ERROR/DEBUG/TRACE/FATAL)
    $levelPattern = '\b(INFO|WARN|WARNING|ERROR|DEBUG|TRACE|FATAL|CRITICAL)\b'
    $uniqueLevels = ($AllLines | ForEach-Object {
        if ($_ -match $levelPattern) { $Matches[1] }
    } | Sort-Object -Unique) -join ', '

    # Extrair valores únicos de HOST (padrão [xxx])
    $hostPattern  = '\[([^\]]{2,30})\]'
    $uniqueHosts  = ($AllLines | ForEach-Object {
        if ($_ -match $hostPattern) { $Matches[1] }
    } | Sort-Object -Unique | Select-Object -First 20) -join ', '

    # Extrair amostras de latência (padrão latency=NNNms ou Nms)
    $latPattern   = 'latency=(\d+)ms'
    $latSamples   = ($AllLines[0..[Math]::Min(9, $total - 1)] | ForEach-Object {
        if ($_ -match $latPattern) { $Matches[1] }
    }) -join ', '

    # Diferenças entre primeiras latências (para detectar passo aritmético)
    $latVals = ($AllLines[0..[Math]::Min(9, $total - 1)] | ForEach-Object {
        if ($_ -match $latPattern) { [int]$Matches[1] }
    })
    $latStep = if ($latVals.Count -ge 2) { $latVals[1] - $latVals[0] } else { 0 }

    # Últimas latências (para detectar wrap/modulo)
    $latLast = ($AllLines[($total - 4)..($total - 1)] | ForEach-Object {
        if ($_ -match $latPattern) { $Matches[1] }
    }) -join ', '

    return [ordered]@{
        TotalLines    = $total
        LineEnding    = $LineEnding
        FirstLines    = $firstN
        LastLines     = $lastN
        UniqueLevels  = $uniqueLevels
        UniqueHosts   = $uniqueHosts
        LatSamples    = $latSamples
        LatStep       = $latStep
        LatLast       = $latLast
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# NOVA EM v0720 — Prompt Especializado para Log com FOR LOOP
# ─────────────────────────────────────────────────────────────────────────────

function Build-LogSynthPrompt {
    param(
        [string]  $FileName,
        [long]    $FileSize,
        [string]  $Sha256,
        [hashtable] $Schema
    )

    $bt = '```'
    $le = if ($Schema.LineEnding -eq 'CRLF') { '`r`n (CRLF — Windows)' } else { '`n (LF only)' }
    $leNote = if ($Schema.LineEnding -eq 'CRLF') {
        'Join all lines with "`r`n" — NO trailing newline at end of file.'
    } else {
        'Join all lines with "`n" — NO trailing newline at end of file.'
    }

    $firstBlock = ($Schema.FirstLines | ForEach-Object { "  [line] $_" }) -join "`n"
    $lastBlock  = ($Schema.LastLines  | ForEach-Object { "  [line] $_" }) -join "`n"

    $latHint = if ($Schema.LatStep -ne 0) {
        "Latency samples (first 10 data lines): $($Schema.LatSamples)  (step between consecutive values: $($Schema.LatStep))`n  Latency last 4 lines: $($Schema.LatLast)  (look for modulo wrap here)"
    } else {
        "Latency samples (first 10): $($Schema.LatSamples)"
    }

    return @"
You are an expert compression researcher who invents procedural reconstruction algorithms.

MISSION: Write a PowerShell FOR LOOP that regenerates this structured log file EXACTLY.
The file has a DETERMINISTIC FORMULA for each field — DO NOT embed file content in the seed.

FILE INFO:
  Name        : $FileName
  Size        : $FileSize bytes (return EXACTLY this many bytes)
  Total lines : $($Schema.TotalLines)
  Line ending : $le
  SHA-256     : $Sha256

STRUCTURAL ANALYSIS:
  Unique LEVELS: $($Schema.UniqueLevels)
  Unique HOSTS : $($Schema.UniqueHosts)
  $latHint

FIRST $($Schema.FirstLines.Count) LINES:
$firstBlock

LAST $($Schema.LastLines.Count) LINES:
$lastBlock

INSTRUCTIONS — READ CAREFULLY:
1. Identify the line template from the first lines (timestamp format, field names, order).
   NOTE: Line 1 is the header (starts with #). Data lines start at line 2 (i=1).
2. Find the formula for each variable field using `$i` = data line index (1 to line_count):
   - Timestamp: HH=Truncate(i/3600)%24, MM=Truncate((i%3600)/60), SS=i%60, mmm=i%1000
     Use [string]::Format("{0:D2}:{1:D2}:{2:D2}.{3:D3}", [int]HH, [int]MM, SS, mmm)
   - Level: i=1 maps to the FIRST element of the levels array (see first data line above).
     → use levels[(`$i - 1) % levels.Count]  (NOT `$i % levels.Count which starts at index 1)
   - Host: same — use hosts[(`$i - 1) % hosts.Count]
   - Latency: step=$($Schema.LatStep), last 4 values=$($Schema.LatLast) → wrap detected → formula: (`$i % 500) + 1
   - JobID: i.ToString('D7'), seq: i (no leading zeros)
3. Use [Math]::Truncate (NOT [int], NOT Get-Date) for integer division in timestamps.
4. The seed JSON must contain ONLY parameters (arrays + constants), NO raw content.
5. $leNote
6. FORBIDDEN functions/variables:
   - Get-Content, Set-Content, Invoke-WebRequest, Start-Process, Get-Date (any I/O)
   - Variable name `$host` (RESERVED in PowerShell — use `$hostName` instead)
7. The latency field has NO space: "latency=8ms" NOT "latency=8 ms".

OUTPUT EXACTLY TWO CODE BLOCKS — no other text, no explanation outside the blocks:

${bt}powershell
function Decode-CustomFormat {
    param([hashtable]`$Seed)
    [long]`$sz = `$Seed['size']
    `$lines = [System.Collections.Generic.List[string]]::new()
    `$lines.Add(`$Seed['header'])
    for (`$i = 1; `$i -le `$Seed['line_count']; `$i++) {
        `$hh       = [int][Math]::Truncate(`$i / 3600) % 24
        `$mm       = [int][Math]::Truncate((`$i % 3600) / 60)
        `$ss       = `$i % 60
        `$xx       = `$i % 1000
        `$ts       = [string]::Format("2026-01-01T{0:D2}:{1:D2}:{2:D2}.{3:D3}Z", `$hh, `$mm, `$ss, `$xx)
        `$lv       = `$Seed['levels'][(`$i - 1) % `$Seed['levels'].Count]
        `$hostName = `$Seed['hosts'][(`$i - 1) % `$Seed['hosts'].Count]
        `$lat      = (`$i % 500) + 1
        `$job      = `$i.ToString('D7')
        `$lines.Add([string]::Format("{0} {1} [{2}] job={3} status=running latency={4}ms seq={5} retries=0",
            `$ts, `$lv, `$hostName, `$job, `$lat, `$i))
    }
    return , [System.Text.Encoding]::UTF8.GetBytes((`$lines -join "`r`n"))
}
${bt}

${bt}json
{
  "size": $FileSize,
  "format": "teia-lunatic-log",
  "line_count": $($Schema.TotalLines - 1),
  "header": "$($Schema.FirstLines[0] -replace '"','\"')",
  "levels": ["INFO","WARN","ERROR","DEBUG"],
  "hosts": ["api-01","api-02","api-03","worker-01","worker-02"],
  "description": "Deterministic syslog: timestamps by Truncate(i/3600), levels/hosts by (i-1)%N, latency by i%500+1"
}
${bt}

VALIDATION COMMAND I WILL RUN:
  `$seed  = (Get-Content seed.json) | ConvertFrom-Json -AsHashtable
  `$bytes = Decode-CustomFormat -Seed `$seed
  SHA256(`$bytes) must equal: $Sha256
"@
}

# ─────────────────────────────────────────────────────────────────────────────
# FUNÇÕES — FASE 2: Ollama
# ─────────────────────────────────────────────────────────────────────────────

function Test-OllamaAlive([string]$baseUrl) {
    try {
        $r = Invoke-WebRequest "$baseUrl/api/tags" -UseBasicParsing -TimeoutSec 5 -EA Stop
        return $r.StatusCode -eq 200
    } catch { return $false }
}

function Get-AvailableModels([string]$baseUrl) {
    try {
        $r = Invoke-WebRequest "$baseUrl/api/tags" -UseBasicParsing -TimeoutSec 5 -EA Stop
        return (($r.Content | ConvertFrom-Json).models | ForEach-Object { $_.name })
    } catch { return @() }
}

# ─────────────────────────────────────────────────────────────────────────────
# FUNÇÕES — FASE 2b: Prompt Legacy (HexDump) — mantido para arquivos binários
# ─────────────────────────────────────────────────────────────────────────────

function Build-SynthPrompt {
    param(
        [string]$FileName,
        [long]  $FileSize,
        [double]$Entropy,
        [string]$Sha256,
        [string]$HexDump,
        [string]$FreqTable,
        [int]   $SampleSize,
        [string]$StructureHint,
        [string]$RawContent  = '',
        [string]$LineEnding  = 'LF'
    )
    $bt = '```'
    $hintSection = switch ($StructureHint) {
        'uniform-byte' { "HINT: All bytes appear to be the same value. The decoder is a simple fill loop." }
        'periodic'     { "HINT: The data appears to repeat a short pattern. Find the period and encode it." }
        'text'         { "HINT: Entropy is low and bytes suggest structured text. Model the template/schema." }
        'binary'       { "HINT: Binary file. Look for repeating structures, magic bytes, or block patterns." }
        default        { "Analyze the hex dump carefully to identify the dominant structural pattern." }
    }
    $lineEndingNote = if ($LineEnding -eq 'CRLF') {
        "LINE ENDINGS: The file uses CRLF (0x0D 0x0A). Use `` `r`n `` in PowerShell strings."
    } else {
        "LINE ENDINGS: The file uses LF only (0x0A). Use `` `n `` in PowerShell strings."
    }
    $fullContentSection = if ($RawContent -ne '') {
        @"

FULL FILE CONTENT (use this to reconstruct the file exactly):
---BEGIN---
$RawContent
---END---
IMPORTANT: seed MUST store this in "content". Decoder returns:
  [System.Text.Encoding]::UTF8.GetBytes(`$Seed['content'])
"@
    } else { '' }

    return @"
You are an expert compression researcher who invents procedural reconstruction algorithms.
MISSION: Reverse-engineer the file below and create a minimal procedural reconstruction engine.
$hintSection
$lineEndingNote
OUTPUT EXACTLY TWO CODE BLOCKS — no other text:
${bt}powershell
function Decode-CustomFormat {
    param([hashtable]`$Seed)
    [long]`$sz = `$Seed['size']
    # ALLOWED: loops, arithmetic, [byte[]], [System.Text.Encoding]::UTF8.GetBytes(), string ops
    # FORBIDDEN: Get-Content, Set-Content, Invoke-WebRequest, Start-Process, any I/O
    return , [System.Text.Encoding]::UTF8.GetBytes(`$Seed['content'])
}
${bt}
${bt}json
{
  "size": $FileSize,
  "format": "detected-format-name",
  "content": "...full or compressed content here...",
  "description": "what pattern was detected"
}
${bt}
VALIDATION: SHA256(output) must equal: $Sha256
FILE INFO:
  Name    : $FileName
  Size    : $FileSize bytes (return EXACTLY this many bytes)
  Entropy : $Entropy bits/byte
  SHA-256 : $Sha256
$fullContentSection
HEX DUMP — $SampleSize of $FileSize bytes:
$HexDump
TOP-12 BYTE FREQUENCIES:
$FreqTable
SEED STRATEGY:
- text file: seed["content"] = exact file text
- repeating byte: seed["byte_value"], seed["count"]
- repeating pattern: seed["pattern"] = [b0..bN]
- arithmetic: seed["start"], seed["step"], seed["rows"]
"@
}

# ─────────────────────────────────────────────────────────────────────────────
# FUNÇÕES — FASE 3: Parsing da Resposta
# ─────────────────────────────────────────────────────────────────────────────

function Extract-Block([string]$text, [string]$lang) {
    $pat = '(?s)' + '```' + $lang + '[ \t]*[\r\n]+(.*?)[\r\n]+' + '```'
    $m   = [regex]::Match($text, $pat)
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    $pat2 = '(?s)' + '```' + '[ \t]*[\r\n]+(.*?)[\r\n]+' + '```'
    $m2   = [regex]::Match($text, $pat2)
    if ($m2.Success) { return $m2.Groups[1].Value.Trim() }
    return $null
}

# ─────────────────────────────────────────────────────────────────────────────
# FUNÇÕES — FASE 4: Crucível de Validação (Runspace Isolado)
# ─────────────────────────────────────────────────────────────────────────────

function Test-DecoderInRunspace {
    param(
        [string]$DecoderPath,
        [string]$SeedPath,
        [byte[]]$OriginalBytes,
        [int]   $TimeoutMs = 60000
    )
    $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $rs  = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($iss)
    $rs.Open()
    $ps  = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $rs.SessionStateProxy.SetVariable('__dp', $DecoderPath)
    $rs.SessionStateProxy.SetVariable('__sp', $SeedPath)
    [void]$ps.AddScript(@'
. $__dp
$sd = (Get-Content -LiteralPath $__sp -Raw) | ConvertFrom-Json -AsHashtable
Decode-CustomFormat -Seed $sd
'@)
    $out = $null
    try {
        $async = $ps.BeginInvoke()
        $done  = $async.AsyncWaitHandle.WaitOne($TimeoutMs)
        if (-not $done) {
            $ps.Stop(); $ps.Dispose(); $rs.Close()
            return @{ Pass = $false; Error = "Timeout: decoder excedeu ${TimeoutMs}ms" }
        }
        $out    = $ps.EndInvoke($async)
        $errors = @($ps.Streams.Error)
    } catch {
        $ps.Dispose(); $rs.Close()
        return @{ Pass = $false; Error = "Excecao no Runspace: $_" }
    }
    $ps.Dispose(); $rs.Close()

    if ($errors.Count -gt 0) {
        $errMsg = ($errors | ForEach-Object { $_.ToString() }) -join ' | '
        return @{ Pass = $false; Error = "Erros de execucao: $errMsg" }
    }

    $collected = [System.Collections.Generic.List[byte]]::new()
    foreach ($item in $out) {
        if ($null -eq $item) { continue }
        if ($item -is [byte[]]) { $collected.AddRange([byte[]]$item) }
        elseif ($item -is [System.Array]) { foreach ($b in $item) { $collected.Add([byte]$b) } }
        else { try { $collected.Add([byte]$item) } catch { } }
    }
    $genBytes = $collected.ToArray()

    if ($genBytes.Length -ne $OriginalBytes.Length) {
        return @{
            Pass  = $false
            Error = "Tamanho incorreto: gerado=$($genBytes.Length) esperado=$($OriginalBytes.Length)"
        }
    }
    $sha      = [System.Security.Cryptography.SHA256]::Create()
    $genHash  = [BitConverter]::ToString($sha.ComputeHash($genBytes)).Replace('-', '').ToLower()
    $origHash = [BitConverter]::ToString($sha.ComputeHash($OriginalBytes)).Replace('-', '').ToLower()
    $sha.Dispose()
    return @{
        Pass          = ($genHash -eq $origHash)
        GeneratedHash = $genHash
        OriginalHash  = $origHash
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# FASE 1 — Análise Estrutural (com ramo de Log Sintático em v0720)
# ─────────────────────────────────────────────────────────────────────────────

Write-Phase "FASE 1 — Analise Estrutural: $($fileInfo.Name)"

$allBytes  = [System.IO.File]::ReadAllBytes($InputFile)
$fileSize  = $allBytes.Length
$fileSha   = (Get-FileHash -LiteralPath $InputFile -Algorithm SHA256).Hash.ToLower()
$entropy   = Compute-Entropy $allBytes

$hasCR      = $allBytes -contains 13
$lineEnding = if ($hasCR) { 'CRLF' } else { 'LF' }

$uByte  = Detect-UniqueByteRun $allBytes[0..[Math]::Min(511, $fileSize - 1)]
$period = Detect-Period        $allBytes[0..[Math]::Min(511, $fileSize - 1)]

$structHint = if ($null -ne $uByte) {
    'uniform-byte'
} elseif ($period -gt 0 -and $period -le 64) {
    'periodic'
} elseif ($entropy -lt 5.5) {
    'text'
} else {
    'binary'
}

Write-INFO "Tamanho    : $fileSize bytes"
Write-INFO "SHA-256    : $fileSha"
Write-INFO "Entropia   : $entropy bits/byte"
Write-INFO "Line ending: $lineEnding"
Write-INFO "Hint       : $structHint"

# ── Decisão: Log Sintático (v0720) ou HexDump (legacy v0710) ─────────────────
$logSchema = $null
$useLogPrompt = $structHint -in @('text') -or ($entropy -lt 5.5 -and $lineEnding -in @('CRLF','LF'))

if ($useLogPrompt) {
    Write-INFO "[v0720] Modo LOG SINTÁTICO ativado — substituindo HexDump por análise de linhas"
    $textContent = [System.Text.Encoding]::UTF8.GetString($allBytes)
    $splitChar   = if ($lineEnding -eq 'CRLF') { "`r`n" } else { "`n" }
    $allTextLines = $textContent -split [regex]::Escape($splitChar)
    $logSchema = Analyze-LogSchema -AllLines $allTextLines -LineEnding $lineEnding -SampleN $SampleLines
    Write-INFO "  Total linhas  : $($logSchema.TotalLines)"
    Write-INFO "  Levels únicos : $($logSchema.UniqueLevels)"
    Write-INFO "  Hosts únicos  : $($logSchema.UniqueHosts)"
    Write-INFO "  Lat amostras  : $($logSchema.LatSamples) (step=$($logSchema.LatStep))"
    Write-INFO "  Lat últimas 4 : $($logSchema.LatLast)"
} else {
    Write-INFO "[v0720] Modo HexDump (arquivo binário ou alta entropia)"
    $effectiveSample = if ($fileSize -le 4096) { $fileSize } else { $HexSampleBytes }
    $sampleLen = [Math]::Min($effectiveSample, $fileSize)
    $sample    = $allBytes[0..($sampleLen - 1)]
    $hexDump   = Build-HexDump $sample
    $freqTable = Get-TopFrequency $allBytes
    $rawContent = ''
    if ($structHint -in @('text','periodic') -and $fileSize -le 8192) {
        try { $rawContent = [System.Text.Encoding]::UTF8.GetString($allBytes) } catch { }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# FASE 2 — Construção do Prompt
# ─────────────────────────────────────────────────────────────────────────────

Write-Phase "FASE 2 — Construcao do Prompt"

$prompt = if ($logSchema) {
    Build-LogSynthPrompt `
        -FileName  $fileInfo.Name `
        -FileSize  $fileSize `
        -Sha256    $fileSha `
        -Schema    $logSchema
} else {
    Build-SynthPrompt `
        -FileName      $fileInfo.Name `
        -FileSize      $fileSize `
        -Entropy       $entropy `
        -Sha256        $fileSha `
        -HexDump       $hexDump `
        -FreqTable     $freqTable `
        -SampleSize    $sampleLen `
        -StructureHint $structHint `
        -RawContent    $rawContent `
        -LineEnding    $lineEnding
}

Write-INFO "Modo prompt : $(if ($logSchema) { 'LOG SINTÁTICO (v0720)' } else { 'HexDump (legacy)' })"
Write-INFO "Prompt      : $($prompt.Length) caracteres"

if ($DryRun) {
    Write-INFO "DRY-RUN — primeiros 1000 chars do prompt:"
    Write-Host ''
    Write-Host $prompt.Substring(0, [Math]::Min(1000, $prompt.Length)) -ForegroundColor DarkGray
    Write-Host ''
    Write-INFO "DRY-RUN concluido. Remova -DryRun para invocar o LLM."
    exit 0
}

if (-not (Test-OllamaAlive $OllamaUrl)) {
    Write-FAIL "Ollama nao responde em $OllamaUrl."; exit 1
}

$availModels = Get-AvailableModels $OllamaUrl
if ($Model -notin $availModels) {
    Write-FAIL "Modelo '$Model' nao disponível. Disponíveis: $($availModels -join ', ')"; exit 1
}
Write-OK "Ollama OK | Modelo '$Model' disponível"

# ─────────────────────────────────────────────────────────────────────────────
# LOOP DE TENTATIVAS — Fases 3 + 4
# ─────────────────────────────────────────────────────────────────────────────

$synthResult = $null
$decoderPath = Join-Path $SandboxDir 'temp_decoder.ps1'
$seedPath    = Join-Path $SandboxDir 'temp_seed.json'

for ($attempt = 1; $attempt -le $Tries; $attempt++) {

    Write-Phase "TENTATIVA ${attempt} / $Tries"

    Write-SYNTH "Invocando $Model ($($prompt.Length) chars de prompt)..."
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $bodyJson = [ordered]@{
            model   = $Model
            prompt  = $prompt
            stream  = $false
            options = [ordered]@{
                temperature = 0.05
                num_predict = 4096
                top_p       = 0.9
            }
        } | ConvertTo-Json -Depth 3 -Compress

        $resp = Invoke-WebRequest "$OllamaUrl/api/generate" `
            -Method POST `
            -ContentType 'application/json; charset=utf-8' `
            -Body $bodyJson `
            -TimeoutSec $LlmTimeoutSec `
            -UseBasicParsing -EA Stop

        $sw.Stop()
        $llmText = ($resp.Content | ConvertFrom-Json).response
        Write-OK "LLM respondeu em $($sw.Elapsed.TotalSeconds.ToString('F1'))s ($($llmText.Length) chars)"

    } catch {
        $sw.Stop()
        Write-FAIL "Falha na chamada ao LLM: $_"
        if ($attempt -lt $Tries) { Write-INFO "Aguardando 3s..."; Start-Sleep 3; continue }
        break
    }

    # FASE 3: Parsing ─────────────────────────────────────────────────────────
    Write-SYNTH "Extraindo blocos powershell e json da resposta..."

    $decoderCode = Extract-Block $llmText 'powershell'
    $seedJson    = Extract-Block $llmText 'json'

    if (-not $decoderCode) {
        Write-FAIL "Nao foi possivel extrair bloco powershell."
        $dbg = Join-Path $SandboxDir "llm_raw_attempt${attempt}.txt"
        [System.IO.File]::WriteAllBytes($dbg, $enc.GetBytes($llmText))
        Write-INFO "Resposta bruta: $dbg"; continue
    }
    if (-not $seedJson) {
        Write-FAIL "Nao foi possivel extrair bloco json."
        $dbg = Join-Path $SandboxDir "llm_raw_attempt${attempt}.txt"
        [System.IO.File]::WriteAllBytes($dbg, $enc.GetBytes($llmText))
        Write-INFO "Resposta bruta: $dbg"; continue
    }

    Write-OK "Blocos extraidos — decoder: $($decoderCode.Length) chars | semente: $($seedJson.Length) chars"

    try {
        $seedObj = $seedJson | ConvertFrom-Json
        Write-INFO "Semente JSON valida. Formato: $($seedObj.format)"
    } catch {
        Write-FAIL "JSON invalido na semente: $_"; continue
    }

    [System.IO.File]::WriteAllBytes($decoderPath, $enc.GetBytes($decoderCode))
    [System.IO.File]::WriteAllBytes($seedPath,    $enc.GetBytes($seedJson))
    Write-INFO "Sandbox decoder: $decoderPath"
    Write-INFO "Sandbox semente: $seedPath"

    # FASE 4: Crucível ────────────────────────────────────────────────────────
    Write-Phase "FASE 4 — Crucivel: Runspace Isolado + SHA-256"
    Write-SYNTH "Executando Decode-CustomFormat (timeout: $($DecoderTimeoutMs)ms)..."

    $vr = Test-DecoderInRunspace `
        -DecoderPath   $decoderPath `
        -SeedPath      $seedPath `
        -OriginalBytes $allBytes `
        -TimeoutMs     $DecoderTimeoutMs

    if ($vr.Pass) {
        Write-OK "SHA-256 COINCIDE — Compressao Lunatica Validada!"
        Write-OK "  Original : $($vr.OriginalHash)"
        Write-OK "  Gerado   : $($vr.GeneratedHash)"
        $synthResult = @{
            Attempt     = $attempt
            DecoderCode = $decoderCode
            SeedJson    = $seedJson
            SeedObj     = $seedObj
            DecoderPath = $decoderPath
            SeedPath    = $seedPath
            OriginalHash= $vr.OriginalHash
        }
        break
    }

    Write-FAIL "SHA-256 NAO COINCIDE na tentativa ${attempt}."
    Write-INFO "  Esperado : $($vr.OriginalHash)"
    Write-INFO "  Gerado   : $($vr.GeneratedHash)"
    Write-INFO "  Detalhe  : $($vr.Error)"
    $dbg = Join-Path $SandboxDir "llm_raw_attempt${attempt}.txt"
    [System.IO.File]::WriteAllBytes($dbg, $enc.GetBytes($llmText))
}

# ─────────────────────────────────────────────────────────────────────────────
# FASE 4.5 — Julgamento de Eficiência
# ─────────────────────────────────────────────────────────────────────────────

$efficiencyVerdict = 'FAILED'
$classicalResult   = $null

if (-not $synthResult) {
    if (-not $Silent) {
        Write-Host ''
        Write-FAIL "Sintese falhou apos $Tries tentativas."
        Write-INFO "Arquivos de debug em: $SandboxDir"
        Write-Host ''
    }
    if ($ResultFile) {
        $resultObj = [ordered]@{
            verdict            = 'FAILED'
            decoder_id         = $null; decoder_path = $null; seed_path = $null
            combined_size      = $null; lzma_size = $null; brotli_size = $null
            best_classical     = $null; classical_strategy = $null
            original_sha256    = $fileSha; original_size = $fileSize
            prompt_mode        = if ($logSchema) { 'log-syntactic-v0720' } else { 'hexdump-legacy' }
        }
        [System.IO.File]::WriteAllBytes($ResultFile, $enc.GetBytes(($resultObj | ConvertTo-Json -Depth 2)))
    }
    exit 2
}

Write-Phase "FASE 4.5 — Julgamento de Eficiencia"
$combinedSize    = $synthResult.DecoderCode.Length + $synthResult.SeedJson.Length
$classicalResult = Compare-ClassicalCompression $allBytes
$bestClassical   = $classicalResult.BestBytes

if (-not $Silent) {
    Write-INFO "Ontoprocedural : $combinedSize bytes (decoder + semente)"
    Write-INFO "LZMA (GZip)    : $($classicalResult.LzmaBytes) bytes"
    Write-INFO "Brotli         : $($classicalResult.BrotliBytes) bytes"
    Write-INFO "Melhor classico: $bestClassical bytes ($($classicalResult.BestStrategy))"
}

if ($combinedSize -lt $bestClassical) {
    $deltaGanhoPct = [Math]::Round(100.0 * ($bestClassical - $combinedSize) / $bestClassical, 1)
    if (-not $Silent) {
        Write-OK "ONTOPROCEDURAL VENCE — Delta de ganho: $($bestClassical - $combinedSize) bytes ($deltaGanhoPct% sobre melhor classico)"
    }
    $efficiencyVerdict = 'ONTOPROCEDURAL'
} else {
    if (-not $Silent) {
        Write-INFO "Classico vence por $($combinedSize - $bestClassical) bytes. Fallback: $($classicalResult.BestStrategy)"
    }
    $efficiencyVerdict = 'CLASSICAL'
}

# ─────────────────────────────────────────────────────────────────────────────
# FASE 5 — Cristalização
# ─────────────────────────────────────────────────────────────────────────────

if ($efficiencyVerdict -eq 'ONTOPROCEDURAL') {

    Write-Phase "FASE 5 — Cristalizacao: P1 Patch Aprovado"

    $safeBase  = [System.IO.Path]::GetFileNameWithoutExtension($fileInfo.Name) -replace '[^a-zA-Z0-9_-]', '_'
    $safeExt   = $fileInfo.Extension.TrimStart('.').ToLower() -replace '[^a-zA-Z0-9]', ''
    $hashPfx   = $fileSha.Substring(0, 8)
    $baseName  = "decoder_${safeBase}_${safeExt}_${hashPfx}"

    $finalDecPath  = Join-Path $DecoderDir "${baseName}.ps1"
    $finalSeedPath = Join-Path $DecoderDir "${baseName}.seed.json"
    $manifestPath  = Join-Path $DecoderDir "${baseName}.manifest.json"

    [System.IO.File]::Copy($synthResult.DecoderPath, $finalDecPath,  $true)
    [System.IO.File]::Copy($synthResult.SeedPath,    $finalSeedPath, $true)

    $decFileSize  = (Get-Item $finalDecPath).Length
    $seedFileSize = (Get-Item $finalSeedPath).Length
    $combinedSize = $decFileSize + $seedFileSize

    $deltaSavingsBytes = $fileSize - $combinedSize
    $deltaSavingsPct   = if ($fileSize -gt 0) { [Math]::Round(100.0 * $deltaSavingsBytes / $fileSize, 1) } else { 0.0 }
    $detectedFormat    = if ($synthResult.SeedObj.format) { $synthResult.SeedObj.format } else { 'unknown' }
    $description       = if ($synthResult.SeedObj.description) { $synthResult.SeedObj.description } else { 'N/A' }

    $manifest = [ordered]@{
        schema_version       = '1.0'
        p1_patch_status      = 'APPROVED'
        decoder_id           = $baseName
        original_file        = $fileInfo.Name
        original_sha256      = $fileSha
        original_size_bytes  = $fileSize
        decoder_size_bytes   = $decFileSize
        seed_size_bytes      = $seedFileSize
        combined_size_bytes  = $combinedSize
        delta_savings_bytes  = $deltaSavingsBytes
        delta_savings_pct    = $deltaSavingsPct
        entropy_bits_per_byte = $entropy
        structure_hint       = $structHint
        detected_format      = $detectedFormat
        description          = $description
        prompt_mode          = if ($logSchema) { 'log-syntactic-v0720' } else { 'hexdump-legacy' }
        llm_model            = $Model
        synthesis_attempts   = $synthResult.Attempt
        validated            = $true
        validation_sha256    = $synthResult.OriginalHash
        synthesized_at       = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
    }

    $manifestJson = $manifest | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllBytes($manifestPath, $enc.GetBytes($manifestJson))

    if (-not $Silent) {
        Write-OK "P1 Patch cristalizado:"
        Write-INFO "  Decoder   : $finalDecPath  ($decFileSize bytes)"
        Write-INFO "  Semente   : $finalSeedPath  ($seedFileSize bytes)"
        Write-INFO "  Manifesto : $manifestPath"
        Write-INFO "  Formato   : $detectedFormat"
        Write-INFO "  Delta de economia: $deltaSavingsBytes bytes ($deltaSavingsPct% do original)"
        Write-Host ''
        Write-Host ('=' * 72) -ForegroundColor Green
        Write-Host '  RESULTADO: COMPRESSAO LUNATICA ATINGIDA — SINTESE APROVADA' -ForegroundColor Green
        Write-Host "  Motor criou micro-decoder para: $detectedFormat" -ForegroundColor Green
        Write-Host "  Prompt: log-syntactic-v0720  |  Tentativa: $($synthResult.Attempt) / $Tries" -ForegroundColor Green
        Write-Host ('=' * 72) -ForegroundColor Green
        Write-Host ''
    }

    if ($ResultFile) {
        $resultObj = [ordered]@{
            verdict            = 'ONTOPROCEDURAL'
            decoder_id         = $baseName
            decoder_path       = $finalDecPath
            seed_path          = $finalSeedPath
            combined_size      = $combinedSize
            lzma_size          = $classicalResult.LzmaBytes
            brotli_size        = $classicalResult.BrotliBytes
            best_classical     = $bestClassical
            classical_strategy = $classicalResult.BestStrategy
            original_sha256    = $fileSha
            original_size      = $fileSize
            prompt_mode        = 'log-syntactic-v0720'
        }
        [System.IO.File]::WriteAllBytes($ResultFile, $enc.GetBytes(($resultObj | ConvertTo-Json -Depth 2)))
    }

} else {
    # CLASSICAL fallback
    if (-not $Silent) {
        Write-Host ''
        Write-Host ('=' * 72) -ForegroundColor Yellow
        Write-Host '  RESULTADO: FALLBACK CLASSICO' -ForegroundColor Yellow
        Write-Host "  Estrategia: $($classicalResult.BestStrategy) ($bestClassical bytes)" -ForegroundColor Yellow
        Write-Host "  Ontoprocedural: $combinedSize bytes — nao compensa" -ForegroundColor Yellow
        Write-Host ('=' * 72) -ForegroundColor Yellow
        Write-Host ''
    }
    if ($ResultFile) {
        $resultObj = [ordered]@{
            verdict            = 'CLASSICAL'
            decoder_id         = $null
            decoder_path       = $null
            seed_path          = $null
            combined_size      = $combinedSize
            lzma_size          = $classicalResult.LzmaBytes
            brotli_size        = $classicalResult.BrotliBytes
            best_classical     = $bestClassical
            classical_strategy = $classicalResult.BestStrategy
            original_sha256    = $fileSha
            original_size      = $fileSize
            prompt_mode        = 'log-syntactic-v0720'
        }
        [System.IO.File]::WriteAllBytes($ResultFile, $enc.GetBytes(($resultObj | ConvertTo-Json -Depth 2)))
    }
}
