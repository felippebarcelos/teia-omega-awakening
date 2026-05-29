<#
.SYNOPSIS
    TEIA-AutoSynth-v0710.ps1 — Forja Ontoprocedural P11.0 (Julgamento de Eficiencia)

.DESCRIPTION
    Usa LLM local (Ollama) para analisar a estrutura binária de um arquivo
    e sintetizar automaticamente um micro-motor de reconstrução procedural:
      - Função PowerShell   Decode-CustomFormat (decoder)
      - Semente JSON mínima (parâmetros para o decoder)

    Fases de Execução:
      FASE 1 — Análise Estrutural: HexDump + frequência de bytes + entropia
      FASE 2 — Síntese via LLM: prompt contextual enviado ao Ollama
      FASE 3 — Parsing: extrai bloco powershell + bloco json da resposta
      FASE 4   — Crucível: Runspace isolado + SHA-256(gerado) == SHA-256(original)
      FASE 4.5 — Julgamento de Eficiencia: Ontoprocedural vs LZMA vs Brotli
      FASE 5   — Cristalização: P1 Patch aprovado SOMENTE se Ontoprocedural vence

    Invariantes:
      - "Delta" sempre por extenso. Símbolo matemático correspondente é PROIBIDO.
      - Decoder deve garantir Write == Read sem dependências externas.
      - Runspace isolado com timeout de 30s evita corrupção de estado e loops.

.PARAMETER InputFile
    Arquivo a analisar. Bons candidatos: CSV estruturado, SVG, log com template.

.PARAMETER OllamaUrl
    URL base do servidor Ollama. Padrão: http://localhost:11434

.PARAMETER Model
    Modelo Ollama. Padrão: qwen2.5-coder:7b

.PARAMETER Tries
    Tentativas de síntese em caso de falha de validação. Padrão: 3

.PARAMETER HexSampleBytes
    Bytes enviados no hexdump ao LLM (máximo). Padrão: 256

.PARAMETER DecoderTimeoutMs
    Timeout de execução do decoder no Runspace em ms. Padrão: 30000

.PARAMETER LlmTimeoutSec
    Timeout HTTP da chamada ao LLM em segundos. Padrão: 300

.PARAMETER DryRun
    Executa fases 1-2 (análise + geração de prompt) sem chamar o LLM.

.PARAMETER ResultFile
    Se especificado, escreve resultado JSON (verdict, sizes, paths) para o chamador.

.PARAMETER Silent
    Suprime toda saída Write-Host (útil quando invocado pelo System Manager).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$InputFile,

    [string]$OllamaUrl        = 'http://localhost:11434',
    [string]$Model            = 'qwen2.5-coder:7b',
    [string]$SandboxDir       = 'D:\TEIA_CORE\sandbox\autosynth',
    [string]$DecoderDir       = 'D:\TEIA_CORE\decoders',
    [int]$Tries               = 3,
    [int]$HexSampleBytes      = 256,
    [int]$DecoderTimeoutMs    = 30000,
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

# ── Logging ($Silent suprime toda saída) ─────────────────────────────────────
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

# ── Julgamento de Eficiência: calcula tamanho LZMA e Brotli ──────────────────
function Compare-ClassicalCompression([byte[]]$bytes) {
    $opts = [System.IO.Compression.CompressionLevel]::Optimal

    $ms1  = New-Object System.IO.MemoryStream
    $gz   = New-Object System.IO.Compression.GZipStream($ms1, $opts)
    $gz.Write($bytes, 0, $bytes.Length); $gz.Close()
    $lzmaSize = $ms1.Length; $ms1.Dispose()

    $ms2  = New-Object System.IO.MemoryStream
    $br   = New-Object System.IO.Compression.BrotliStream($ms2, $opts)
    $br.Write($bytes, 0, $bytes.Length); $br.Close()
    $brotliSize = $ms2.Length; $ms2.Dispose()

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
    Write-Host '  TEIA-AutoSynth v0.71.0 — Forja Ontoprocedural (Julgamento de Eficiencia)' -ForegroundColor Cyan
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host "  Arquivo  : $InputFile"
    Write-Host "  Modelo   : $Model  (Tries: $Tries)"
    Write-Host "  Modo     : $(if ($DryRun) { 'DRY-RUN' } else { 'ATIVO' })"
    Write-Host ''
}

# ── Validação de entrada ───────────────────────────────────────────────────────
if (-not (Test-Path -LiteralPath $InputFile)) {
    Write-FAIL "Arquivo nao encontrado: $InputFile"
    Write-INFO 'Bons candidatos: arquivo .csv estruturado, .svg, .log com template fixo, .ini'
    exit 1
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
    $total = [double]$bytes.Length
    $H     = 0.0
    foreach ($c in $freq) {
        if ($c -gt 0) {
            $p  = $c / $total
            $H -= $p * [Math]::Log($p, 2)
        }
    }
    [Math]::Round($H, 4)
}

function Build-HexDump([byte[]]$sample) {
    $sb = [System.Text.StringBuilder]::new()
    for ($i = 0; $i -lt $sample.Length; $i += 16) {
        $end   = [Math]::Min($i + 15, $sample.Length - 1)
        $chunk = $sample[$i..$end]
        $hex   = ($chunk | ForEach-Object { $_.ToString('X2', $IC) }) -join ' '
        $asc   = ($chunk | ForEach-Object {
            if ($_ -ge 32 -and $_ -le 126) { [char]$_ } else { '.' }
        }) -join ''
        [void]$sb.AppendLine(("{0:X4}  {1,-47}  {2}" -f $i, $hex, $asc))
    }
    $sb.ToString().TrimEnd()
}

function Get-TopFrequency([byte[]]$bytes, [int]$top = 12) {
    $freq  = New-Object int[] 256
    foreach ($b in $bytes) { $freq[$b]++ }
    $total = $bytes.Length
    $lines = [System.Collections.Generic.List[string]]::new()
    $sorted = (0..255) |
        Where-Object { $freq[$_] -gt 0 } |
        Sort-Object   { -$freq[$_] } |
        Select-Object -First $top
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
# FUNÇÕES — FASE 2: Síntese via LLM
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
        [string]$RawContent     = '',   # full text for small text files
        [string]$LineEnding     = 'LF'  # 'LF' or 'CRLF'
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

FULL FILE CONTENT (use this to reconstruct the file exactly — encode as seed['content']):
---BEGIN---
$RawContent
---END---

IMPORTANT: The seed MUST store this text in field "content". The decoder returns:
  [System.Text.Encoding]::UTF8.GetBytes(`$Seed['content'])
This guarantees bit-perfect reconstruction. If you see a mathematical pattern,
encode BOTH: the content string AND the pattern params so the decoder uses the pattern.
"@
    } else { '' }

    return @"
You are an expert compression researcher who invents procedural reconstruction algorithms.

MISSION: Reverse-engineer the file below and create a minimal procedural reconstruction engine.

$hintSection
$lineEndingNote

OUTPUT EXACTLY TWO CODE BLOCKS — no other text, no explanation outside the blocks:

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

VALIDATION COMMAND I WILL RUN:
  `$seed  = (Get-Content seed.json) | ConvertFrom-Json -AsHashtable
  `$bytes = Decode-CustomFormat -Seed `$seed
  SHA256(`$bytes) must equal: $Sha256

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

SEED STRATEGY (choose the most elegant that still produces the exact SHA-256):
- text file: seed["content"] = exact file text → decoder returns UTF8.GetBytes(content)
- repeating byte: seed["byte_value"], seed["count"] → fill loop
- repeating pattern: seed["pattern"] = [b0..bN] → modulo loop
- arithmetic sequence: seed["start"], seed["step"], seed["rows"] → generate lines
- IMPORTANT: if in doubt, use seed["content"] = exact text — correctness first
"@
}

# ─────────────────────────────────────────────────────────────────────────────
# FUNÇÕES — FASE 3: Parsing da Resposta do LLM
# ─────────────────────────────────────────────────────────────────────────────

function Extract-Block([string]$text, [string]$lang) {
    # Primary: ```lang\n...\n```
    $pat = '(?s)' + '```' + $lang + '[ \t]*[\r\n]+(.*?)[\r\n]+' + '```'
    $m   = [regex]::Match($text, $pat)
    if ($m.Success) { return $m.Groups[1].Value.Trim() }

    # Fallback: ```\n...\n```
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
        [int]   $TimeoutMs = 30000
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

    $out    = $null
    $errors = $null
    try {
        $async = $ps.BeginInvoke()
        $done  = $async.AsyncWaitHandle.WaitOne($TimeoutMs)
        if (-not $done) {
            $ps.Stop()
            $ps.Dispose(); $rs.Close()
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

    # Coleta bytes tolerando tanto array desenrolado quanto retorno unitário
    $collected = [System.Collections.Generic.List[byte]]::new()
    foreach ($item in $out) {
        if ($null -eq $item) { continue }
        if ($item -is [byte[]]) {
            $collected.AddRange([byte[]]$item)
        } elseif ($item -is [System.Array]) {
            foreach ($b in $item) { $collected.Add([byte]$b) }
        } else {
            try { $collected.Add([byte]$item) } catch { }
        }
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
# FASE 1 — Análise Estrutural
# ─────────────────────────────────────────────────────────────────────────────

Write-Phase "FASE 1 — Analise Estrutural: $($fileInfo.Name)"

$allBytes  = [System.IO.File]::ReadAllBytes($InputFile)
$fileSize  = $allBytes.Length
$fileSha   = (Get-FileHash -LiteralPath $InputFile -Algorithm SHA256).Hash.ToLower()
$entropy   = Compute-Entropy $allBytes

# Para arquivos pequenos (<= 4096 bytes), sempre enviar o hexdump completo
$effectiveSample = if ($fileSize -le 4096) { $fileSize } else { $HexSampleBytes }
$sampleLen = [Math]::Min($effectiveSample, $fileSize)
$sample    = $allBytes[0..($sampleLen - 1)]
$hexDump   = Build-HexDump $sample
$freqTable = Get-TopFrequency $allBytes

# Classificação estrutural automática
$uByte  = Detect-UniqueByteRun $sample
$period = Detect-Period $sample

$structHint = if ($null -ne $uByte) {
    'uniform-byte'
} elseif ($period -gt 0 -and $period -le 64) {
    'periodic'
} elseif ($entropy -lt 4.5) {
    'text'
} else {
    'binary'
}

# Detecção de line ending
$hasCR = $allBytes -contains 13
$lineEnding = if ($hasCR) { 'CRLF' } else { 'LF' }

# Para arquivos texto pequenos, incluir conteúdo completo no prompt
$rawContent = ''
if ($structHint -in @('text','periodic') -and $fileSize -le 8192) {
    try {
        $rawContent = [System.Text.Encoding]::UTF8.GetString($allBytes)
    } catch {
        $rawContent = ''
    }
}

Write-INFO "Tamanho   : $fileSize bytes"
Write-INFO "SHA-256   : $fileSha"
Write-INFO "Entropia  : $entropy bits/byte"
Write-INFO "Line ending: $lineEnding"
Write-INFO "Amostra   : $sampleLen bytes no hexdump (arquivo completo: $(if ($sampleLen -eq $fileSize) {'sim'} else {'nao'}))"
Write-INFO "Hint      : $structHint$(if ($null -ne $uByte) { " (byte=0x$($uByte.ToString('X2'))" + ')' } elseif ($period -gt 0) { " (periodo=$period)" } else { '' })"
if ($rawContent) { Write-INFO "RawContent: sim ($($rawContent.Length) chars)" }

# ─────────────────────────────────────────────────────────────────────────────
# FASE 2 — Geração do Prompt
# ─────────────────────────────────────────────────────────────────────────────

Write-Phase "FASE 2 — Construcao do Prompt"

$prompt = Build-SynthPrompt `
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

Write-INFO "Prompt: $($prompt.Length) caracteres"

if ($DryRun) {
    Write-INFO "DRY-RUN — exibindo primeiros 800 chars do prompt:"
    Write-Host ''
    Write-Host $prompt.Substring(0, [Math]::Min(800, $prompt.Length)) -ForegroundColor DarkGray
    Write-Host ''
    Write-INFO "DRY-RUN concluido. Remova -DryRun para invocar o LLM."
    exit 0
}

if (-not (Test-OllamaAlive $OllamaUrl)) {
    Write-FAIL "Ollama nao responde em $OllamaUrl."
    Write-INFO "Para iniciar: ollama serve"
    Write-INFO "Para instalar modelo: ollama pull qwen2.5-coder:7b"
    exit 1
}

$availModels = Get-AvailableModels $OllamaUrl
if ($Model -notin $availModels) {
    Write-FAIL "Modelo '$Model' nao encontrado. Disponíveis: $($availModels -join ', ')"
    Write-INFO "Execute: ollama pull $Model"
    exit 1
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

    # FASE 2b: Chamar LLM ──────────────────────────────────────────────────────
    Write-SYNTH "Invocando $Model ($($prompt.Length) chars de prompt)..."
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $bodyJson = [ordered]@{
            model   = $Model
            prompt  = $prompt
            stream  = $false
            options = [ordered]@{
                temperature = 0.1
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
        if ($attempt -lt $Tries) {
            Write-INFO "Aguardando 3s..."; Start-Sleep 3; continue
        }
        break
    }

    # FASE 3: Parsing da Resposta ──────────────────────────────────────────────
    Write-SYNTH "Extraindo blocos powershell e json da resposta..."

    $decoderCode = Extract-Block $llmText 'powershell'
    $seedJson    = Extract-Block $llmText 'json'

    if (-not $decoderCode) {
        Write-FAIL "Nao foi possivel extrair bloco powershell da resposta do LLM."
        $dbg = Join-Path $SandboxDir "llm_raw_attempt${attempt}.txt"
        [System.IO.File]::WriteAllBytes($dbg, $enc.GetBytes($llmText))
        Write-INFO "Resposta bruta salva em: $dbg"
        continue
    }

    if (-not $seedJson) {
        Write-FAIL "Nao foi possivel extrair bloco json da resposta do LLM."
        $dbg = Join-Path $SandboxDir "llm_raw_attempt${attempt}.txt"
        [System.IO.File]::WriteAllBytes($dbg, $enc.GetBytes($llmText))
        Write-INFO "Resposta bruta salva em: $dbg"
        continue
    }

    Write-OK "Blocos extraidos — decoder: $($decoderCode.Length) chars | semente: $($seedJson.Length) chars"

    # Validar que semente é JSON válido
    try {
        $seedObj = $seedJson | ConvertFrom-Json
        Write-INFO "Semente JSON valida. Formato detectado: $($seedObj.format)"
    } catch {
        Write-FAIL "JSON inválido na semente: $_"
        continue
    }

    # Salvar no sandbox
    [System.IO.File]::WriteAllBytes($decoderPath, $enc.GetBytes($decoderCode))
    [System.IO.File]::WriteAllBytes($seedPath,    $enc.GetBytes($seedJson))
    Write-INFO "Sandbox: $decoderPath"
    Write-INFO "Sandbox: $seedPath"

    # FASE 4: Crucível de Validação ────────────────────────────────────────────
    Write-Phase "FASE 4 — Crucivel: Runspace Isolado + SHA-256"
    Write-SYNTH "Executando Decode-CustomFormat em Runspace isolado (timeout: $($DecoderTimeoutMs)ms)..."

    $vr = Test-DecoderInRunspace `
        -DecoderPath  $decoderPath `
        -SeedPath     $seedPath `
        -OriginalBytes $allBytes `
        -TimeoutMs    $DecoderTimeoutMs

    if ($vr.Pass) {
        Write-OK "SHA-256 COINCIDE — Dissonancia Cognitiva Positiva Resolvida!"
        Write-OK "  Original : $($vr.OriginalHash)"
        Write-OK "  Gerado   : $($vr.GeneratedHash)"
        $synthResult = @{
            Attempt      = $attempt
            DecoderCode  = $decoderCode
            SeedJson     = $seedJson
            SeedObj      = $seedObj
            DecoderPath  = $decoderPath
            SeedPath     = $seedPath
            OriginalHash = $vr.OriginalHash
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
        Write-INFO "Sugestoes:"
        Write-INFO "  1. Use um arquivo menor e mais estruturado (CSV, SVG simples, .ini)"
        Write-INFO "  2. Tente -Tries 5 para mais tentativas"
        Write-INFO "  3. Tente um modelo maior: -Model deepseek-r1:14b"
        Write-Host ''
    }
    if ($ResultFile) {
        $resultObj = [ordered]@{
            verdict            = 'FAILED'
            decoder_id         = $null
            decoder_path       = $null
            seed_path          = $null
            combined_size      = $null
            lzma_size          = $null
            brotli_size        = $null
            best_classical     = $null
            classical_strategy = $null
            original_sha256    = $fileSha
            original_size      = $fileSize
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
        Write-OK "ONTOPROCEDURAL VENCE — Delta de ganho: $($bestClassical - $combinedSize) bytes ($deltaGanhoPct%)"
    }
    $efficiencyVerdict = 'ONTOPROCEDURAL'
} else {
    if (-not $Silent) {
        Write-INFO "Classico vence por $($combinedSize - $bestClassical) bytes. Fallback: $($classicalResult.BestStrategy)"
    }
    $efficiencyVerdict = 'CLASSICAL'
}

# ─────────────────────────────────────────────────────────────────────────────
# FASE 5 — Cristalização (P1 Patch Aprovado — apenas se ONTOPROCEDURAL)
# ─────────────────────────────────────────────────────────────────────────────

if ($efficiencyVerdict -eq 'ONTOPROCEDURAL') {

Write-Phase "FASE 5 — Cristalizacao: P1 Patch Aprovado"

$safeBase   = [System.IO.Path]::GetFileNameWithoutExtension($fileInfo.Name) -replace '[^a-zA-Z0-9_-]', '_'
$safeExt    = $fileInfo.Extension.TrimStart('.').ToLower() -replace '[^a-zA-Z0-9]', ''
$hashPrefix = $fileSha.Substring(0, 8)
$baseName   = "decoder_${safeBase}_${safeExt}_${hashPrefix}"

$finalDecPath  = Join-Path $DecoderDir "${baseName}.ps1"
$finalSeedPath = Join-Path $DecoderDir "${baseName}.seed.json"
$manifestPath  = Join-Path $DecoderDir "${baseName}.manifest.json"

[System.IO.File]::Copy($synthResult.DecoderPath, $finalDecPath,  $true)
[System.IO.File]::Copy($synthResult.SeedPath,    $finalSeedPath, $true)

$decFileSize  = (Get-Item $finalDecPath).Length
$seedFileSize = (Get-Item $finalSeedPath).Length
$combinedSize = $decFileSize + $seedFileSize

# Delta de economia em bytes (palavra por extenso — símbolo proibido no pipeline)
$deltaSavingsBytes = $fileSize - $combinedSize
$deltaSavingsPct   = if ($fileSize -gt 0) {
    [Math]::Round(100.0 * $deltaSavingsBytes / $fileSize, 1)
} else { 0.0 }

$detectedFormat = if ($synthResult.SeedObj.format) { $synthResult.SeedObj.format } else { 'unknown' }
$description    = if ($synthResult.SeedObj.description) { $synthResult.SeedObj.description } else { 'N/A' }

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
    Write-INFO "  Descricao : $description"
    Write-INFO "  Delta de economia: $deltaSavingsBytes bytes ($deltaSavingsPct%)"

    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor Green
    Write-Host '  RESULTADO: SINTESE APROVADA' -ForegroundColor Green
    Write-Host "  A TEIA criou um micro-motor inedito para: $detectedFormat" -ForegroundColor Green
    Write-Host "  Tentativa: $($synthResult.Attempt) / $Tries" -ForegroundColor Green
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
    }
    [System.IO.File]::WriteAllBytes($ResultFile, $enc.GetBytes(($resultObj | ConvertTo-Json -Depth 2)))
}

} else {
    # CLASSICAL fallback — cristalização não realizada
    if (-not $Silent) {
        Write-Host ''
        Write-Host ('=' * 72) -ForegroundColor Yellow
        Write-Host '  RESULTADO: FALLBACK CLASSICO' -ForegroundColor Yellow
        Write-Host "  Estrategia: $($classicalResult.BestStrategy) ($bestClassical bytes)" -ForegroundColor Yellow
        Write-Host "  Ontoprocedural combinado: $combinedSize bytes — nao compensa" -ForegroundColor Yellow
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
        }
        [System.IO.File]::WriteAllBytes($ResultFile, $enc.GetBytes(($resultObj | ConvertTo-Json -Depth 2)))
    }
}
