<#
.SYNOPSIS
    TEIA-AutoSynth-v0800.ps1 — Forja Ontoprocedural com Lente Semantica

.DESCRIPTION
    Versao v0800: adiciona dois novos modos de analise para dados complexos reais.

    NOVO EM v0800:
      - Modo JSON: chama Analyze-SemanticSchema.ps1 e envia o Esqueleto Semantico ao LLM.
        Instrucao ao LLM: "Reconstrua o JSON usando loops sobre os arrays da semente".
      - Modo CSV: analise de cabecalhos e cardinalidade por coluna.
      - Modo LOG aprimorado: detecta campos nao-aritmeticos (latencia aleatoria)
        e os embute como array na semente, eliminando a dependencia de formula.
      - Prompt LOG mais flexivel: mostra 8 linhas iniciais para que o LLM infira
        o mapeamento exato de $line para nivel/host/index.

    Fases de Execucao:
      FASE 1   — Analise Estrutural (HexDump | Log Sintatico | JSON Semantico | CSV)
      FASE 2   — Construcao do Prompt (modo-especifico)
      FASE 3   — Sintese via LLM (Ollama)
      FASE 4   — Crucivel: Runspace isolado + SHA-256
      FASE 4.5 — Julgamento de Eficiencia: Ontoprocedural vs LZMA vs Brotli
      FASE 5   — Cristalizacao (apenas se ONTOPROCEDURAL)

    INVARIANTES:
      - "Delta" sempre por extenso. Simbolo matematico correspondente PROIBIDO.
      - Decoder deve garantir Write == Read sem dependencias externas.
      - Runspace isolado com timeout de 60s.

.PARAMETER InputFile
    Arquivo a analisar.

.PARAMETER SemanticTool
    Caminho para Analyze-SemanticSchema.ps1. Padrao: mesma pasta deste script.

.PARAMETER OllamaUrl
    URL base do servidor Ollama. Padrao: http://localhost:11434

.PARAMETER Model
    Modelo Ollama. Padrao: qwen2.5-coder:7b

.PARAMETER Tries
    Tentativas de sintese em caso de falha. Padrao: 3

.PARAMETER SampleLines
    Linhas amostradas do inicio e fim para analise de log. Padrao: 8

.PARAMETER HexSampleBytes
    Bytes enviados no hexdump (apenas arquivos binarios). Padrao: 512

.PARAMETER DecoderTimeoutMs
    Timeout do decoder no Runspace. Padrao: 120000

.PARAMETER LlmTimeoutSec
    Timeout HTTP da chamada ao LLM. Padrao: 300

.PARAMETER DryRun
    Executa fases 1-2 (analise + prompt) sem chamar o LLM.

.PARAMETER ResultFile
    Se especificado, escreve resultado JSON (verdict, sizes) para o chamador.

.PARAMETER Silent
    Suprime toda saida Write-Host.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$InputFile,

    [string]$SemanticTool     = '',
    [string]$OllamaUrl        = 'http://localhost:11434',
    [string]$Model            = 'qwen2.5-coder:7b',
    [string]$SandboxDir       = 'D:\TEIA_CORE\sandbox\autosynth_v0800',
    [string]$DecoderDir       = 'D:\TEIA_CORE\decoders',
    [int]$Tries               = 3,
    [int]$SampleLines         = 8,
    [int]$HexSampleBytes      = 512,
    [int]$DecoderTimeoutMs    = 120000,
    [int]$LlmTimeoutSec       = 300,
    [switch]$DryRun,
    [string]$ResultFile       = '',
    [switch]$Silent
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC  = [System.Globalization.CultureInfo]::InvariantCulture
$enc = New-Object System.Text.UTF8Encoding($false)

# Resolver SemanticTool se nao especificado
if (-not $SemanticTool) {
    $SemanticTool = Join-Path (Split-Path $PSCommandPath -Parent) 'Analyze-SemanticSchema.ps1'
}

# ── Logging ───────────────────────────────────────────────────────────────────
function Write-Phase([string]$t) {
    if ($Silent) { return }
    Write-Host ''; Write-Host ('─' * 72) -ForegroundColor Cyan
    Write-Host "  $t" -ForegroundColor Cyan
    Write-Host ('─' * 72) -ForegroundColor Cyan
}
function Write-OK   ([string]$t) { if (-not $Silent) { Write-Host "  [OK]    $t" -ForegroundColor Green  } }
function Write-FAIL ([string]$t) { if (-not $Silent) { Write-Host "  [FAIL]  $t" -ForegroundColor Red    } }
function Write-INFO ([string]$t) { if (-not $Silent) { Write-Host "  [INFO]  $t" -ForegroundColor Gray   } }
function Write-SYNTH([string]$t) { if (-not $Silent) { Write-Host "  [SYNTH] $t" -ForegroundColor Yellow } }

# ── Julgamento de Eficiencia ──────────────────────────────────────────────────
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

# ── Utilitarios de Analise ────────────────────────────────────────────────────
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
# ANALISE LOG APRIMORADA (v0800) — detecta campos nao-aritmeticos
# ─────────────────────────────────────────────────────────────────────────────

function Analyze-LogSchemaV2 {
    param(
        [string[]]$AllLines,
        [string]  $LineEnding,
        [int]     $SampleN = 8
    )

    # Detectar linha vazia terminal (artefato de AppendLine — indica trailing CRLF no arquivo)
    $hasTrailingNewline = ($AllLines.Count -gt 0 -and $AllLines[-1] -eq '')
    # Remover linhas vazias do final para contar corretamente
    $trimmed = [System.Collections.Generic.List[string]]::new($AllLines)
    while ($trimmed.Count -gt 0 -and $trimmed[$trimmed.Count - 1] -eq '') {
        $trimmed.RemoveAt($trimmed.Count - 1)
    }
    $AllLines = $trimmed.ToArray()

    $total = $AllLines.Count

    $firstN = $AllLines[0..[Math]::Min($SampleN - 1, $total - 1)]
    $lastN  = if ($total -gt $SampleN) {
        $AllLines[($total - $SampleN)..($total - 1)]
    } else { @() }

    # Extrair valores unicos de LEVEL
    $levelPattern = '\b(INFO|WARN|WARNING|ERROR|DEBUG|TRACE|FATAL|CRITICAL)\b'
    $uniqueLevels = ($AllLines | ForEach-Object {
        if ($_ -match $levelPattern) { $Matches[1] }
    } | Sort-Object -Unique) -join ', '

    # Extrair valores unicos de HOST (padrao [xxx])
    $hostPattern = '\[([^\]]{2,30})\]'
    $uniqueHosts = ($AllLines | ForEach-Object {
        if ($_ -match $hostPattern) { $Matches[1] }
    } | Sort-Object -Unique | Select-Object -First 20) -join ', '

    # Extrair TODAS as latencias (para detectar se sao aritmeticas ou aleatorias)
    $latPattern  = 'latency=(\d+)ms'
    $allLats     = $AllLines | ForEach-Object {
        if ($_ -match $latPattern) { [int]$Matches[1] }
    }

    $latIsArray   = $false
    $latArray     = @()
    $latFormula   = 'unknown'
    $latSamples   = ''
    $latStep      = 0
    $latLast      = ''

    if ($allLats.Count -ge 2) {
        # Verificar se e aritmetico: step constante entre os primeiros 10 valores
        $step  = $allLats[1] - $allLats[0]
        $isArith = $true
        for ($j = 1; $j -lt [Math]::Min($allLats.Count, 15); $j++) {
            if ($allLats[$j] - $allLats[$j-1] -ne $step) { $isArith = $false; break }
        }

        # Verificar se e modular (ultimo valor < penultimo indica wrap)
        $lastFew = $allLats[([Math]::Max(0,$allLats.Count-5))..($allLats.Count-1)]

        if ($isArith) {
            $latStep    = $step
            $latFormula = "Arithmetic step=$step"
            $latSamples = ($allLats | Select-Object -First 10) -join ', '
            $latLast    = $lastFew -join ', '
        } else {
            # Nao aritmetico: verificar se e modular com multiplicador
            $isModular = $false
            # Testar formulas (i * k) % M + 1 para k=1..20, M em {499,500,997,1000}
            foreach ($k in @(1,3,7,11,13,17)) {
                foreach ($M in @(499,500,997,1000)) {
                    $pred = 1..$allLats.Count | ForEach-Object { ($_ * $k) % $M + 1 }
                    $matches = 0
                    for ($j = 0; $j -lt [Math]::Min($allLats.Count, 20); $j++) {
                        if ($pred[$j] -eq $allLats[$j]) { $matches++ }
                    }
                    if ($matches -ge [Math]::Min(15, $allLats.Count)) {
                        $isModular = $true
                        $latFormula = "(i * $k) % $M + 1"
                        $latStep    = $k
                        break
                    }
                }
                if ($isModular) { break }
            }

            if (-not $isModular) {
                # Valores sao aleatorios — embute array na semente
                $latIsArray = $true
                $latArray   = $allLats
                $latFormula = 'array (valores aleatorios — armazenados na semente)'
            }
            $latSamples = ($allLats | Select-Object -First 10) -join ', '
            $latLast    = $lastFew -join ', '
        }
    }

    # Extrair timestamp para detectar formulas dos campos HH/MM/SS/mmm
    $tsPat = '(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2}):(\d{2})\.(\d{3})Z'
    $tsDate = ''
    $firstDataLines = $AllLines | Where-Object { $_ -match $tsPat } | Select-Object -First 2
    if ($firstDataLines.Count -gt 0 -and $firstDataLines[0] -match $tsPat) {
        $tsDate = $Matches[1]
    }

    return [ordered]@{
        TotalLines          = $total
        LineEnding          = $LineEnding
        HasTrailingNewline  = $hasTrailingNewline
        FirstLines          = $firstN
        LastLines           = $lastN
        UniqueLevels        = $uniqueLevels
        UniqueHosts         = $uniqueHosts
        LatSamples          = $latSamples
        LatStep             = $latStep
        LatLast             = $latLast
        LatIsArray          = $latIsArray
        LatArray            = $latArray
        LatFormula          = $latFormula
        TimestampDate       = $tsDate
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# PROMPT LOG V2 — suporta array de latencia e indexacao flexivel
# ─────────────────────────────────────────────────────────────────────────────

function Build-LogSynthPromptV2 {
    param(
        [string]    $FileName,
        [long]      $FileSize,
        [string]    $Sha256,
        [hashtable] $Schema
    )

    $bt = '```'
    $le = if ($Schema.LineEnding -eq 'CRLF') { '`r`n (CRLF — Windows)' } else { '`n (LF only)' }
    $trailNote = if ($Schema.HasTrailingNewline) { 'INCLUDE trailing "`r`n" after last line.' } else { 'NO trailing newline after last line.' }
    $leJoin = if ($Schema.LineEnding -eq 'CRLF') { "Join lines with `"`r`n`". $trailNote" } else { "Join lines with `"`n`". $trailNote" }
    $trailExpr = if ($Schema.HasTrailingNewline) { ' + "`r`n"' } else { '' }

    $firstBlock = ($Schema.FirstLines | ForEach-Object { "  [line] $_" }) -join "`n"
    $lastBlock  = ($Schema.LastLines  | ForEach-Object { "  [line] $_" }) -join "`n"

    # Construir secao de latencia
    $latSection = ''
    if ($Schema.LatIsArray) {
        $latsJson = '[' + ($Schema.LatArray -join ',') + ']'
        $latSection = @"

LATENCY FIELD — RANDOM VALUES (not arithmetic — must be stored):
  All $($Schema.LatArray.Count) latency values are stored in the seed under key "lats".
  In decoder: `$lat = `$Seed['lats'][`$i - 1]   (NOT a formula)
  SEED MUST INCLUDE: "lats": $latsJson
"@
    } else {
        $latSection = @"

LATENCY FIELD — FORMULA DETECTED: $($Schema.LatFormula)
  Samples (first 10): $($Schema.LatSamples)
  Last values: $($Schema.LatLast)
  Use the formula above — do NOT embed individual values.
"@
    }

    # Construir seed template
    $latsEntry = if ($Schema.LatIsArray) {
        $latsJson = '[' + ($Schema.LatArray -join ',') + ']'
        ",`n  `"lats`": $latsJson"
    } else { '' }

    return @"
You are an expert compression researcher who invents procedural reconstruction algorithms.

MISSION: Write a PowerShell FOR LOOP that regenerates this structured log file EXACTLY.
Deduce the formula for EVERY deterministic field from the samples below.
Store only parameters (arrays + constants) in the seed — NO raw file content except where specified.

FILE INFO:
  Name        : $FileName
  Size        : $FileSize bytes (return EXACTLY this many bytes)
  Total lines : $($Schema.TotalLines)
  Line ending : $le
  SHA-256     : $Sha256

STRUCTURAL CONTEXT:
  Unique LEVELS seen in file: $($Schema.UniqueLevels)
  Unique HOSTS  seen in file: $($Schema.UniqueHosts)
  Timestamp date: $($Schema.TimestampDate) (constant for all lines)
$latSection

FIRST $($Schema.FirstLines.Count) LINES:
$firstBlock

LAST $($Schema.LastLines.Count) LINES:
$lastBlock

INSTRUCTIONS — READ CAREFULLY:
1. Analyze the first lines to identify: timestamp formula (HH, MM, SS, mmm as functions of `$i),
   the EXACT arrays for levels/hosts AND the indexing formula (${'$'}i % N or (${'$'}i-1) % N).
   CLUE: Check whether line 1 maps to index 0 or index 1 of the arrays.
2. Identify seq and job formulas from the patterns in first/last lines.
3. For milliseconds: check whether it uses (${'$'}i * k) % 1000 or (${'$'}seq * k) % 1000.
4. $leJoin
5. FORBIDDEN functions/variables:
   - Get-Content, Set-Content, Invoke-WebRequest, Start-Process, Get-Date (any I/O)
   - Variable name `$host (RESERVED in PowerShell — use `$hostName instead)
6. Use [Math]::Truncate (NOT [int]) for integer division. Use [string]::Format for padding.
7. The "lats" key in seed (if present) is [object[]]. Cast: `$lat = [int](`$Seed['lats'][`$i - 1])

OUTPUT EXACTLY TWO CODE BLOCKS — no other text outside the blocks:

${bt}powershell
function Decode-CustomFormat {
    param([hashtable]`$Seed)
    [long]`$sz = `$Seed['size']
    `$lines = [System.Collections.Generic.List[string]]::new()
    `$lines.Add(`$Seed['header'])
    for (`$i = 1; `$i -le `$Seed['line_count']; `$i++) {
        # TODO: compute all fields from `$i and `$Seed
        `$lines.Add(...)
    }
    return , [System.Text.Encoding]::UTF8.GetBytes((`$lines -join "`r`n")$trailExpr)
}
${bt}

${bt}json
{
  "size": $FileSize,
  "format": "teia-syslog-p7",
  "line_count": $(if ($Schema.LatIsArray) { $Schema.LatArray.Count } else { $Schema.TotalLines - 1 }),
  "header": "$($Schema.FirstLines[0] -replace '"','\"')"$latsEntry
}
${bt}

VALIDATION:
  `$seed  = (Get-Content seed.json) | ConvertFrom-Json -AsHashtable
  `$bytes = Decode-CustomFormat -Seed `$seed
  SHA256(`$bytes) must equal: $Sha256
"@
}

# ─────────────────────────────────────────────────────────────────────────────
# PROMPT LOG LEGACY (v0720) — mantido para logs tipo Lunatic
# ─────────────────────────────────────────────────────────────────────────────

function Build-LogSynthPromptLegacy {
    param(
        [string]    $FileName,
        [long]      $FileSize,
        [string]    $Sha256,
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
    $latHint    = "Latency samples (first 10): $($Schema.LatSamples). Formula: $($Schema.LatFormula)"

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

INSTRUCTIONS:
1. HH=Truncate(i/3600)%24, MM=Truncate((i%3600)/60), SS=i%60, mmm=i%1000
2. Level: levels[(`$i - 1) % levels.Count]  Host: hosts[(`$i - 1) % hosts.Count]
3. Use [Math]::Truncate for integer division.
4. $leNote
5. FORBIDDEN: Get-Content, Set-Content, Invoke-WebRequest, Start-Process, Get-Date, `$host

OUTPUT EXACTLY TWO CODE BLOCKS:

${bt}powershell
function Decode-CustomFormat {
    param([hashtable]`$Seed)
    [long]`$sz = `$Seed['size']
    `$lines = [System.Collections.Generic.List[string]]::new()
    `$lines.Add(`$Seed['header'])
    for (`$i = 1; `$i -le `$Seed['line_count']; `$i++) {
        # TODO: compute all fields
        `$lines.Add(...)
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
  "description": "Deterministic syslog"
}
${bt}

VALIDATION: SHA256(output) must equal: $Sha256
"@
}

# ─────────────────────────────────────────────────────────────────────────────
# PROMPT JSON SEMANTICO (v0800 — novo)
# ─────────────────────────────────────────────────────────────────────────────

function Build-JsonSynthPrompt {
    param(
        [string]$FileName,
        [long]  $FileSize,
        [string]$Sha256,
        [string]$SemanticSkeleton,
        [string]$LineEnding
    )

    $bt = '```'
    $leNote = if ($LineEnding -eq 'CRLF') {
        'The file uses CRLF line endings (0x0D 0x0A).'
    } else {
        'The file uses LF line endings (0x0A only).'
    }

    return @"
You are an expert compression researcher who invents procedural reconstruction algorithms.

MISSION: Write a PowerShell function that reconstructs this JSON file EXACTLY (byte-for-byte).
Analyze the semantic skeleton below. Store all necessary data in the seed JSON.
The decoder must produce the EXACT original bytes — identical field order, spacing, and values.

FILE INFO:
  Name    : $FileName
  Size    : $FileSize bytes
  SHA-256 : $Sha256
  $leNote

SEMANTIC SKELETON (full structure analysis):
─────────────────────────────────────────────
$SemanticSkeleton
─────────────────────────────────────────────

STRATEGY GUIDANCE:
- If the file has arrays of objects with a cross-product pattern (e.g. datasets x modes = results),
  reconstruct by looping over the cross-product and looking up metadata from seed arrays.
- For each object field in results, store its values as a parallel array in the seed.
- Reconstruct the EXACT JSON indentation and field order (use 2-space indent, same key order as original).
- FORBIDDEN: Get-Content, Set-Content, Invoke-WebRequest, Start-Process, Get-Date, any I/O.
- Variable `$host is RESERVED in PowerShell. Use `$hostName or another name.

OUTPUT EXACTLY TWO CODE BLOCKS — no other text:

${bt}powershell
function Decode-CustomFormat {
    param([hashtable]`$Seed)
    [long]`$sz = `$Seed['size']
    `$sb = [System.Text.StringBuilder]::new()
    # TODO: reconstruct JSON using seed data
    `$text = `$sb.ToString()
    return , [System.Text.Encoding]::UTF8.GetBytes(`$text)
}
${bt}

${bt}json
{
  "size": $FileSize,
  "format": "teia-benchmark-json",
  "description": "..."
  // TODO: store all necessary data arrays here
}
${bt}

VALIDATION:
  `$seed  = (Get-Content seed.json) | ConvertFrom-Json -AsHashtable
  `$bytes = Decode-CustomFormat -Seed `$seed
  SHA256(`$bytes) must equal: $Sha256
"@
}

# ─────────────────────────────────────────────────────────────────────────────
# PROMPT CSV (v0800 — novo)
# ─────────────────────────────────────────────────────────────────────────────

function Build-CsvSynthPrompt {
    param(
        [string]$FileName,
        [long]  $FileSize,
        [string]$Sha256,
        [string]$SemanticSkeleton,
        [string]$LineEnding
    )

    $bt = '```'
    return @"
You are an expert compression researcher who invents procedural reconstruction algorithms.

MISSION: Write a PowerShell function that reconstructs this CSV file EXACTLY (byte-for-byte).
Store all necessary data in the seed JSON. The decoder must produce EXACT original bytes.

FILE INFO:
  Name    : $FileName
  Size    : $FileSize bytes
  SHA-256 : $Sha256

SEMANTIC SKELETON:
─────────────────────
$SemanticSkeleton
─────────────────────

STRATEGY:
- Store column headers and all row data in the seed.
- Reconstruct the exact CSV format (commas, quoting, line endings).
- FORBIDDEN: Get-Content, Set-Content, Invoke-WebRequest, Start-Process, Get-Date, any I/O.

OUTPUT EXACTLY TWO CODE BLOCKS:

${bt}powershell
function Decode-CustomFormat {
    param([hashtable]`$Seed)
    [long]`$sz = `$Seed['size']
    `$lines = [System.Collections.Generic.List[string]]::new()
    # TODO: reconstruct CSV
    return , [System.Text.Encoding]::UTF8.GetBytes((`$lines -join "`n"))
}
${bt}

${bt}json
{
  "size": $FileSize,
  "format": "teia-csv",
  "description": "CSV reconstruction"
}
${bt}

VALIDATION: SHA256(output) must equal: $Sha256
"@
}

# ─────────────────────────────────────────────────────────────────────────────
# PROMPT LEGACY HEXDUMP — mantido para binarios
# ─────────────────────────────────────────────────────────────────────────────

function Build-SynthPrompt {
    param(
        [string]$FileName, [long]$FileSize, [double]$Entropy, [string]$Sha256,
        [string]$HexDump, [string]$FreqTable, [int]$SampleSize,
        [string]$StructureHint, [string]$RawContent = '', [string]$LineEnding = 'LF'
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

FULL FILE CONTENT:
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
    return , [System.Text.Encoding]::UTF8.GetBytes(`$Seed['content'])
}
${bt}
${bt}json
{ "size": $FileSize, "format": "detected-format", "content": "..." }
${bt}
VALIDATION: SHA256(output) must equal: $Sha256
FILE INFO: Name=$FileName  Size=$FileSize  Entropy=$Entropy  SHA-256=$Sha256
$fullContentSection
HEX DUMP — $SampleSize of $FileSize bytes:
$HexDump
TOP-12 BYTE FREQUENCIES:
$FreqTable
"@
}

# ─────────────────────────────────────────────────────────────────────────────
# FASE 3: Parsing da Resposta
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
# FASE 4: Crucivel de Validacao (Runspace Isolado)
# ─────────────────────────────────────────────────────────────────────────────

function Test-DecoderInRunspace {
    param(
        [string]$DecoderPath,
        [string]$SeedPath,
        [byte[]]$OriginalBytes,
        [int]   $TimeoutMs = 120000
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
        GeneratedSize = $genBytes.Length
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Ollama helpers
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
# BANNER
# ─────────────────────────────────────────────────────────────────────────────

if (-not $Silent) {
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host '  TEIA-AutoSynth v0.80.0 — Forja com Lente Semantica' -ForegroundColor Cyan
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host "  Arquivo  : $InputFile"
    Write-Host "  Modelo   : $Model  (Tries: $Tries)"
    Write-Host "  Modo     : $(if ($DryRun) { 'DRY-RUN' } else { 'ATIVO' })"
    Write-Host ''
}

# ─────────────────────────────────────────────────────────────────────────────
# Validacao
# ─────────────────────────────────────────────────────────────────────────────

if (-not (Test-Path -LiteralPath $InputFile)) {
    Write-FAIL "Arquivo nao encontrado: $InputFile"; exit 1
}
$fileInfo = Get-Item -LiteralPath $InputFile
if ($fileInfo.Length -eq 0) { Write-FAIL 'Arquivo vazio.'; exit 1 }

foreach ($d in @($SandboxDir, $DecoderDir)) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

# ─────────────────────────────────────────────────────────────────────────────
# FASE 1 — Analise Estrutural
# ─────────────────────────────────────────────────────────────────────────────

Write-Phase "FASE 1 — Analise Estrutural: $($fileInfo.Name)"

$allBytes  = [System.IO.File]::ReadAllBytes($InputFile)
$fileSize  = $allBytes.Length
$fileSha   = (Get-FileHash -LiteralPath $InputFile -Algorithm SHA256).Hash.ToLower()
$entropy   = Compute-Entropy $allBytes

$hasCR      = $allBytes -contains 13
$lineEnding = if ($hasCR) { 'CRLF' } else { 'LF' }

$ext = $fileInfo.Extension.ToLower()
Write-INFO "Tamanho    : $fileSize bytes"
Write-INFO "SHA-256    : $fileSha"
Write-INFO "Entropia   : $entropy bits/byte"
Write-INFO "Extensao   : $ext"
Write-INFO "Line ending: $lineEnding"

# ── Selecionar modo de analise ─────────────────────────────────────────────
$promptMode    = 'hexdump-legacy'
$prompt        = $null
$logSchema     = $null
$semanticSkel  = $null

if ($ext -in @('.json', '.jsonl') -or
    ($ext -notin @('.log','.txt','.csv','.tsv') -and $entropy -lt 5.5 -and $allBytes[0] -in @(0x7B, 0x5B))) {

    # ── Modo JSON Semantico ───────────────────────────────────────────────────
    Write-INFO "[v0800] Modo JSON SEMANTICO — chamando Lente Semantica"
    $promptMode = 'json-semantic-v0800'

    if (-not (Test-Path $SemanticTool)) {
        Write-FAIL "Lente Semantica nao encontrada: $SemanticTool"; exit 1
    }

    $skelJsonPath = Join-Path $SandboxDir 'semantic_skeleton.json'
    try {
        & $SemanticTool -InputFile $InputFile -Mode JSON -OutputJson $skelJsonPath | Out-Null
        $skelObj       = Get-Content $skelJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $semanticSkel  = $skelObj.skeleton
        Write-OK "Esqueleto semantico gerado: $($semanticSkel.Length) chars"
    } catch {
        Write-FAIL "Erro na Lente Semantica: $_"; exit 1
    }

} elseif ($ext -in @('.csv', '.tsv')) {

    # ── Modo CSV ─────────────────────────────────────────────────────────────
    Write-INFO "[v0800] Modo CSV — chamando Lente Semantica"
    $promptMode = 'csv-semantic-v0800'

    if (-not (Test-Path $SemanticTool)) {
        Write-FAIL "Lente Semantica nao encontrada: $SemanticTool"; exit 1
    }

    $skelJsonPath = Join-Path $SandboxDir 'semantic_skeleton.json'
    try {
        & $SemanticTool -InputFile $InputFile -Mode CSV -OutputJson $skelJsonPath | Out-Null
        $skelObj       = Get-Content $skelJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $semanticSkel  = $skelObj.skeleton
        Write-OK "Esqueleto CSV gerado: $($semanticSkel.Length) chars"
    } catch {
        Write-FAIL "Erro na Lente Semantica (CSV): $_"; exit 1
    }

} elseif ($entropy -lt 5.5 -or $ext -in @('.log','.txt')) {

    # ── Modo Log Sintatico Aprimorado (v0800) ────────────────────────────────
    Write-INFO "[v0800] Modo LOG SINTATICO APRIMORADO — analise de linhas com deteccao de array"
    $promptMode = 'log-syntactic-v0800'

    $textContent  = [System.Text.Encoding]::UTF8.GetString($allBytes)
    $splitChar    = if ($lineEnding -eq 'CRLF') { "`r`n" } else { "`n" }
    $allTextLines = $textContent -split [regex]::Escape($splitChar)
    $logSchema    = Analyze-LogSchemaV2 -AllLines $allTextLines -LineEnding $lineEnding -SampleN $SampleLines

    Write-INFO "  Total linhas  : $($logSchema.TotalLines)"
    Write-INFO "  Levels unicos : $($logSchema.UniqueLevels)"
    Write-INFO "  Hosts unicos  : $($logSchema.UniqueHosts)"
    Write-INFO "  Lat formula   : $($logSchema.LatFormula)"
    if ($logSchema.LatIsArray) {
        Write-INFO "  Lat array     : $($logSchema.LatArray.Count) valores embutidos na semente"
    }

} else {

    # ── Modo HexDump Legacy ───────────────────────────────────────────────────
    Write-INFO "[v0800] Modo HexDump (binario ou alta entropia)"
    $promptMode = 'hexdump-legacy'

    $uByte  = Detect-UniqueByteRun $allBytes[0..[Math]::Min(511, $fileSize - 1)]
    $period = Detect-Period        $allBytes[0..[Math]::Min(511, $fileSize - 1)]
    $structHint = if ($null -ne $uByte) { 'uniform-byte' }
                  elseif ($period -gt 0) { 'periodic' }
                  elseif ($entropy -lt 5.5) { 'text' }
                  else { 'binary' }

    $effectiveSample = if ($fileSize -le 4096) { $fileSize } else { $HexSampleBytes }
    $sampleLen  = [Math]::Min($effectiveSample, $fileSize)
    $sample     = $allBytes[0..($sampleLen - 1)]
    $hexDump    = Build-HexDump $sample
    $freqTable  = Get-TopFrequency $allBytes
    $rawContent = ''
    if ($structHint -in @('text','periodic') -and $fileSize -le 8192) {
        try { $rawContent = [System.Text.Encoding]::UTF8.GetString($allBytes) } catch { }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# FASE 2 — Construcao do Prompt
# ─────────────────────────────────────────────────────────────────────────────

Write-Phase "FASE 2 — Construcao do Prompt (modo: $promptMode)"

$prompt = switch ($promptMode) {
    'json-semantic-v0800' {
        Build-JsonSynthPrompt `
            -FileName         $fileInfo.Name `
            -FileSize         $fileSize `
            -Sha256           $fileSha `
            -SemanticSkeleton $semanticSkel `
            -LineEnding       $lineEnding
    }
    'csv-semantic-v0800' {
        Build-CsvSynthPrompt `
            -FileName         $fileInfo.Name `
            -FileSize         $fileSize `
            -Sha256           $fileSha `
            -SemanticSkeleton $semanticSkel `
            -LineEnding       $lineEnding
    }
    'log-syntactic-v0800' {
        if ($logSchema.LatIsArray -or $logSchema.LatFormula -ne 'unknown') {
            Build-LogSynthPromptV2 `
                -FileName  $fileInfo.Name `
                -FileSize  $fileSize `
                -Sha256    $fileSha `
                -Schema    $logSchema
        } else {
            Build-LogSynthPromptLegacy `
                -FileName  $fileInfo.Name `
                -FileSize  $fileSize `
                -Sha256    $fileSha `
                -Schema    $logSchema
        }
    }
    default {
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
}

Write-INFO "Modo prompt : $promptMode"
Write-INFO "Prompt      : $($prompt.Length) caracteres"

# Salvar prompt para debug
$promptDebugPath = Join-Path $SandboxDir 'last_prompt.txt'
[System.IO.File]::WriteAllBytes($promptDebugPath, $enc.GetBytes($prompt))

if ($DryRun) {
    Write-INFO "DRY-RUN — primeiros 1500 chars do prompt:"
    Write-Host ''
    Write-Host $prompt.Substring(0, [Math]::Min(1500, $prompt.Length)) -ForegroundColor DarkGray
    Write-Host ''
    Write-INFO "DRY-RUN concluido. Remova -DryRun para invocar o LLM."
    exit 0
}

if (-not (Test-OllamaAlive $OllamaUrl)) {
    Write-FAIL "Ollama nao responde em $OllamaUrl."; exit 1
}

$availModels = Get-AvailableModels $OllamaUrl
if ($Model -notin $availModels) {
    Write-FAIL "Modelo '$Model' nao disponivel. Disponiveis: $($availModels -join ', ')"; exit 1
}
Write-OK "Ollama OK | Modelo '$Model' disponivel"

# ─────────────────────────────────────────────────────────────────────────────
# LOOP DE TENTATIVAS — Fases 3 + 4
# ─────────────────────────────────────────────────────────────────────────────

$synthResult = $null
$decoderPath = Join-Path $SandboxDir 'temp_decoder.ps1'
$seedPath    = Join-Path $SandboxDir 'temp_seed.json'

for ($attempt = 1; $attempt -le $Tries; $attempt++) {

    Write-Phase "TENTATIVA ${attempt} / $Tries"
    Write-SYNTH "Invocando $Model ($($prompt.Length) chars)..."
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $bodyJson = [ordered]@{
            model   = $Model
            prompt  = $prompt
            stream  = $false
            options = [ordered]@{
                temperature = 0.05
                num_predict = 8192
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
        Write-FAIL "JSON invalido na semente: $_"
        $dbg = Join-Path $SandboxDir "llm_raw_attempt${attempt}.txt"
        [System.IO.File]::WriteAllBytes($dbg, $enc.GetBytes($llmText))
        continue
    }

    [System.IO.File]::WriteAllBytes($decoderPath, $enc.GetBytes($decoderCode))
    [System.IO.File]::WriteAllBytes($seedPath,    $enc.GetBytes($seedJson))

    # FASE 4: Crucivel ────────────────────────────────────────────────────────
    Write-Phase "FASE 4 — Crucivel: Runspace Isolado + SHA-256"
    Write-SYNTH "Executando Decode-CustomFormat (timeout: ${DecoderTimeoutMs}ms)..."

    $vr = Test-DecoderInRunspace `
        -DecoderPath   $decoderPath `
        -SeedPath      $seedPath `
        -OriginalBytes $allBytes `
        -TimeoutMs     $DecoderTimeoutMs

    if ($vr.Pass) {
        Write-OK "SHA-256 COINCIDE — Forja Ontoprocedural Validada!"
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
# FASE 4.5 — Julgamento de Eficiencia
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
            prompt_mode        = $promptMode
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
# FASE 5 — Cristalizacao
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

    $manifest = [ordered]@{
        decoder_id       = $baseName
        input_file       = $InputFile
        input_sha256     = $fileSha
        input_size       = $fileSize
        decoder_path     = $finalDecPath
        seed_path        = $finalSeedPath
        decoder_size     = $decFileSize
        seed_size        = $seedFileSize
        combined_size    = $combinedSize
        lzma_size        = $classicalResult.LzmaBytes
        brotli_size      = $classicalResult.BrotliBytes
        best_classical   = $bestClassical
        delta_savings_b  = $deltaSavingsBytes
        delta_savings_pct= $deltaSavingsPct
        verdict          = 'ONTOPROCEDURAL'
        prompt_mode      = $promptMode
        model            = $Model
        attempt          = $synthResult.Attempt
        detected_format  = $detectedFormat
        created_at       = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    }
    [System.IO.File]::WriteAllBytes($manifestPath, $enc.GetBytes(($manifest | ConvertTo-Json -Depth 2)))

    Write-OK "Decoder cristalizado : $finalDecPath ($decFileSize B)"
    Write-OK "Semente cristalizada : $finalSeedPath ($seedFileSize B)"
    Write-OK "Manifesto            : $manifestPath"
    Write-OK "Delta de economia    : ${deltaSavingsBytes} bytes (${deltaSavingsPct}% sobre original)"
}

# ─────────────────────────────────────────────────────────────────────────────
# Resultado Final
# ─────────────────────────────────────────────────────────────────────────────

if ($ResultFile) {
    $resultObj = [ordered]@{
        verdict            = $efficiencyVerdict
        decoder_id         = if ($efficiencyVerdict -eq 'ONTOPROCEDURAL') { $baseName } else { $null }
        decoder_path       = if ($efficiencyVerdict -eq 'ONTOPROCEDURAL') { $finalDecPath } else { $null }
        seed_path          = if ($efficiencyVerdict -eq 'ONTOPROCEDURAL') { $finalSeedPath } else { $null }
        combined_size      = $combinedSize
        lzma_size          = $classicalResult.LzmaBytes
        brotli_size        = $classicalResult.BrotliBytes
        best_classical     = $bestClassical
        classical_strategy = $classicalResult.BestStrategy
        original_sha256    = $fileSha
        original_size      = $fileSize
        prompt_mode        = $promptMode
    }
    [System.IO.File]::WriteAllBytes($ResultFile, $enc.GetBytes(($resultObj | ConvertTo-Json -Depth 2)))
}

Write-Phase "FORJA CONCLUIDA"
Write-INFO "Veredito  : $efficiencyVerdict"
Write-INFO "Modo      : $promptMode"
if ($classicalResult) {
    Write-INFO "LZMA      : $($classicalResult.LzmaBytes) bytes"
    Write-INFO "Brotli    : $($classicalResult.BrotliBytes) bytes"
}
if ($synthResult) {
    Write-INFO "AutoSynth : $combinedSize bytes (decoder+semente)"
}
