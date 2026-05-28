<#
.SYNOPSIS
    TEIA-Pattern-Hunter-v0210.ps1 — Caçador de Padrões para HR6+ Discovery

.DESCRIPTION
    Analisa a estrutura de arquivos de alta complexidade (vídeo, 3D, áudio, imagem)
    e solicita ao LLM que teorize sobre modelos procedurais/paramétricos de compressão
    candidatos a novas Hard Rules (HR6+).

    Etapas:
    1. SHA-256 via streaming (identidade absoluta)
    2. Detecção de tipo por magic bytes (extendida: obj, heic, flac, avi, ogg)
    3. Header hex dump (primeiros 256 B)
    4. Distribuição de bytes — Top-16 (amostra de 64 KB)
    5. Mapa de entropia local (chunks de ChunkSizeKB KB, máx MaxChunks)
    6. Prompt estruturado ao LLM como "Arquiteto Ontoprocedural"
    7. Salva hipótese em {sha256}_theory.md

    CONTRATO ABSOLUTO: zero escrita no CAS. Zero execução de compressor.
    O resultado é uma hipótese de pesquisa — não um candidate executável.

.PARAMETER InputFile
    Arquivo a analisar (.mp4, .obj, .wav, .m4v, .heic, etc.).

.PARAMETER OutputRoot
    Diretório de hipóteses. Padrão: D:\TEIA_CORE\neuroplanner\hypotheses

.PARAMETER OllamaUrl
    Endpoint Ollama. Padrão: http://localhost:11434/api/generate

.PARAMETER Model
    Modelo LLM. Padrão: deepseek-r1:1.5b (reasoning; use deepseek-r1:14b para maior profundidade)

.PARAMETER ChunkSizeKB
    Tamanho do chunk para mapa de entropia local (KB). Padrão: 4

.PARAMETER MaxChunks
    Máximo de chunks no mapa de entropia. Padrão: 16

.EXAMPLE
    .\TEIA-Pattern-Hunter-v0210.ps1 -InputFile "D:\TEIA_USER\Inbox\model.obj"
    .\TEIA-Pattern-Hunter-v0210.ps1 -InputFile "D:\video.mp4" -Model "deepseek-r1:14b"
    .\TEIA-Pattern-Hunter-v0210.ps1 -InputFile "D:\foto.heic"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$InputFile,

    [string]$OutputRoot  = 'D:\TEIA_CORE\neuroplanner\hypotheses',
    [string]$OllamaUrl   = 'http://localhost:11434/api/generate',
    [string]$Model       = 'deepseek-r1:1.5b',
    [int]   $ChunkSizeKB = 4,
    [int]   $MaxChunks   = 16
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$script:Version = '0.21.0'

# ── low-level helpers ────────────────────────────────────────────────────────

function Get-FileSha256Stream([string]$Path) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $fs  = [System.IO.File]::OpenRead($Path)
    try { -join ($sha.ComputeHash($fs) | ForEach-Object { $_.ToString('x2') }) }
    finally { $sha.Dispose(); $fs.Dispose() }
}

function Get-Entropy([byte[]]$b) {
    if ($b.Length -eq 0) { return 0.0 }
    $freq = New-Object int[] 256
    foreach ($byte in $b) { $freq[$byte]++ }
    $len = $b.Length; $e = 0.0
    foreach ($c in $freq) {
        if ($c -gt 0) { $p = $c / $len; $e -= $p * [Math]::Log($p, 2) }
    }
    [math]::Round($e, 4)
}

function Get-UniqueBytes([byte[]]$b) {
    $seen = New-Object bool[] 256
    foreach ($byte in $b) { $seen[$byte] = $true }
    ($seen | Where-Object { $_ }).Count
}

function Detect-MagicType([byte[]]$b) {
    if ($b.Length -lt 4) { return 'unknown' }
    $h = $b[0..[Math]::Min(15, $b.Length-1)]

    # ── images ──
    if ($h[0] -eq 0x89 -and $h[1] -eq 0x50 -and $h[2] -eq 0x4E -and $h[3] -eq 0x47) { return 'image/png'  }
    if ($h[0] -eq 0xFF -and $h[1] -eq 0xD8 -and $h[2] -eq 0xFF)                      { return 'image/jpeg' }
    if ($h[0] -eq 0x47 -and $h[1] -eq 0x49 -and $h[2] -eq 0x46)                      { return 'image/gif'  }
    # HEIC/MP4: ISO Base Media File Format — ftyp box at offset 4
    if ($b.Length -ge 8 -and $b[4] -eq 0x66 -and $b[5] -eq 0x74 -and $b[6] -eq 0x79 -and $b[7] -eq 0x70) {
        if ($b.Length -ge 12) {
            $brand = [System.Text.Encoding]::ASCII.GetString($b[8..11])
            if ($brand -in @('heic','mif1','heif','avif','heis')) { return 'image/heic' }
        }
        return 'video/mp4'
    }

    # ── audio / video ──
    if ($h[0] -eq 0x66 -and $h[1] -eq 0x4C -and $h[2] -eq 0x61 -and $h[3] -eq 0x43) { return 'audio/flac'    }
    if ($h[0] -eq 0x4F -and $h[1] -eq 0x67 -and $h[2] -eq 0x67 -and $h[3] -eq 0x53) { return 'audio/ogg'     }
    if ($h[0] -eq 0xFF -and ($h[1] -band 0xE0) -eq 0xE0)                              { return 'audio/mp3'     }
    if ($h[0] -eq 0x49 -and $h[1] -eq 0x44 -and $h[2] -eq 0x33)                      { return 'audio/mp3-id3' }
    if ($h[0] -eq 0x52 -and $h[1] -eq 0x49 -and $h[2] -eq 0x46 -and $h[3] -eq 0x46) {
        if ($b.Length -ge 12 -and $b[8] -eq 0x57 -and $b[9] -eq 0x41 -and $b[10] -eq 0x56 -and $b[11] -eq 0x45) { return 'audio/wav'  }
        if ($b.Length -ge 12 -and $b[8] -eq 0x41 -and $b[9] -eq 0x56 -and $b[10] -eq 0x49 -and $b[11] -eq 0x20) { return 'video/avi'  }
        return 'audio/riff'
    }

    # ── archives / executables ──
    if ($h[0] -eq 0x25 -and $h[1] -eq 0x50 -and $h[2] -eq 0x44 -and $h[3] -eq 0x46) { return 'application/pdf'   }
    if ($h[0] -eq 0x50 -and $h[1] -eq 0x4B -and $h[2] -eq 0x03 -and $h[3] -eq 0x04) { return 'application/zip'   }
    if ($h[0] -eq 0x1F -and $h[1] -eq 0x8B)                                           { return 'application/gzip'  }
    if ($h[0] -eq 0x42 -and $h[1] -eq 0x5A -and $h[2] -eq 0x68)                      { return 'application/bzip2' }
    if ($h[0] -eq 0xFD -and $h[1] -eq 0x37 -and $h[2] -eq 0x7A -and $h[3] -eq 0x58) { return 'application/xz'    }
    if ($h[0] -eq 0x37 -and $h[1] -eq 0x7A -and $h[2] -eq 0xBC -and $h[3] -eq 0xAF) { return 'application/7z'    }
    if ($h[0] -eq 0x4D -and $h[1] -eq 0x5A)                                           { return 'application/pe'    }

    # ── text-based formats ──
    $checkLen = [Math]::Min(256, $b.Length)
    $isText   = $true
    for ($i = 0; $i -lt $checkLen; $i++) {
        if ($b[$i] -eq 0x00) { $isText = $false; break }
    }
    if ($isText) {
        $head = [System.Text.Encoding]::UTF8.GetString($b[0..[Math]::Min(255, $b.Length-1)])
        # Wavefront OBJ: starts with vertex/face/comment keywords
        if ($head -match '(?m)^(#|v |vn |vt |f |o |g |mtllib|usemtl|s )') { return 'model/obj'        }
        if ($head -match '^<\?xml|^<!DOCTYPE|^<html')                       { return 'text/html-xml'    }
        if ($head -match '^\{|^\[')                                          { return 'application/json' }
        return 'text/plain'
    }
    return 'application/octet-stream'
}

# ── structural analysis ───────────────────────────────────────────────────────

function Get-LocalEntropyMap {
    param([byte[]]$Bytes, [int]$ChunkSize, [int]$MaxC)
    $results     = [System.Collections.Generic.List[object]]::new()
    $totalChunks = [int][Math]::Ceiling($Bytes.Length / $ChunkSize)
    $step        = [Math]::Max(1, [int][Math]::Ceiling($totalChunks / $MaxC))
    $idx         = 0
    for ($off = 0; $off -lt $Bytes.Length -and $results.Count -lt $MaxC; $off += $ChunkSize * $step) {
        $end  = [Math]::Min($off + $ChunkSize - 1, $Bytes.Length - 1)
        $chunk = $Bytes[$off..$end]
        $null  = $results.Add([pscustomobject]@{
            idx     = $idx++
            off_hex = '0x{0:X6}' -f $off
            size    = $chunk.Length
            e       = Get-Entropy $chunk
        })
    }
    ,$results.ToArray()
}

function Get-ByteFreqTop16 {
    param([byte[]]$Bytes, [int]$MaxSample = 65536)
    $sample = if ($Bytes.Length -gt $MaxSample) { $Bytes[0..($MaxSample-1)] } else { $Bytes }
    $freq   = New-Object long[] 256
    foreach ($bv in $sample) { $freq[$bv]++ }
    $table = for ($i = 0; $i -lt 256; $i++) {
        [pscustomobject]@{
            v   = $i
            hex = '0x{0:X2}' -f $i
            n   = $freq[$i]
            pct = [math]::Round($freq[$i] * 100.0 / $sample.Length, 2)
        }
    }
    $table | Sort-Object n -Descending | Select-Object -First 16
}

function Get-HexDumpStr {
    param([byte[]]$Bytes, [int]$MaxB = 256)
    $limit = [Math]::Min($MaxB, $Bytes.Length)
    $sb    = [System.Text.StringBuilder]::new()
    for ($i = 0; $i -lt $limit; $i += 16) {
        $end = [Math]::Min($i + 15, $limit - 1)
        $hex = ($Bytes[$i..$end] | ForEach-Object { $_.ToString('X2') }) -join ' '
        $asc = -join ($Bytes[$i..$end] | ForEach-Object {
            if ($_ -ge 0x20 -and $_ -le 0x7E) { [char]$_ } else { '.' }
        })
        [void]$sb.AppendLine(('  {0:X6}  {1,-47}  |{2}|' -f $i, $hex, $asc))
    }
    $sb.ToString().TrimEnd()
}

function Format-EntropyMap {
    param([object[]]$Map)
    $sb = [System.Text.StringBuilder]::new()
    foreach ($entry in $Map) {
        $bars = '█' * [int]($entry.e / 8.0 * 40)
        [void]$sb.AppendLine(('  Chunk {0,2} @ {1} ({2,6} B): {3:F4}  {4}' -f `
            $entry.idx, $entry.off_hex, $entry.size, $entry.e, $bars))
    }
    $sb.ToString().TrimEnd()
}

# ── prompt builder ────────────────────────────────────────────────────────────

function Build-HunterPrompt {
    param(
        [string]$FileName, [long]$SizeBytes, [string]$MagicType, [string]$Sha256,
        [double]$Entropy,  [int]$UniqB,      [string]$HexDump,
        [string]$FreqTable,[string]$EntropyMapTxt, [int]$TotalChunks
    )
    $sizeMB = [math]::Round($SizeBytes / 1MB, 3)
    @"
Atue como Arquiteto Ontoprocedural da TEIA (Sistema de Compressão Fractal Avançado).

Você é especialista em análise de formatos binários e modelos generativos. Sua tarefa é
teorizar sobre modelos matemáticos que possam descrever a estrutura deste arquivo de forma
mais eficiente que compressores genéricos (LZMA/Brotli).

=== PERFIL DO ARQUIVO ===
Nome           : $FileName
Tamanho        : $SizeBytes bytes (${sizeMB} MB)
Tipo Detectado : $MagicType
Entropia Global: $Entropy bits/byte (máx=8.0 — próximo de 8 = pré-comprimido ou cifrado)
Bytes Únicos   : $UniqB / 256
SHA-256        : $Sha256

=== HEADER — Primeiros 256 bytes (Hex + ASCII) ===
$HexDump

=== DISTRIBUIÇÃO DE BYTES — Top-16 mais frequentes (amostra de 64 KB) ===
$FreqTable

=== MAPA DE ENTROPIA LOCAL — $TotalChunks chunks totais (amostra abaixo) ===
$EntropyMapTxt

=== TAREFA ===

Analise os dados acima e responda às perguntas a seguir:

1. **DIAGNÓSTICO ESTRUTURAL**: O que o header e a distribuição de bytes revelam sobre a
   estrutura interna deste formato? Identifique seções, índices, frames, blocos, metadados.

2. **MODELO GENERATIVO/PARAMÉTRICO**: Existe um modelo matemático que represente este
   arquivo mais compactamente que LZMA? Exemplos por tipo:
   - video/mp4 : vetores de movimento inter-frame, DCT residual, modelo de cena 3D
   - model/obj  : topologia de malha + função paramétrica de vértices (ex: esfera = f(theta,phi))
   - audio/wav  : síntese (harmônicos, LPC, ADSR), modulação paramétrica
   - image/heic : blocos HEVC, CTU structure, modos intra-prediction, paleta de cores
   - image/jpeg : coeficientes DCT por bloco 8x8, tabelas de quantização Huffman

3. **PROPOSTA HR6+ (pseudocódigo)**:
   ```
   IF detect_magic(file) == '$MagicType' AND <condicao_detectavel_sem_descompressao>:
       APPLY opcode: gen.<nome_modelo>
       PARAMETERS: { <lista de parametros minimos para reconstrucao> }
       ESTIMATED_SAVINGS: <percentual>%
       CONFIDENCE: <0-100>%
   ```

4. **EVIDENCIAS E CONTRADICOES**: Quais elementos nos dados (header, entropia local,
   distribuicao de bytes) suportam ou contradizem a hipotese proposta?

5. **PROXIMO EXPERIMENTO**: Que dados adicionais sao necessarios para validar empiricamente?
   (ex: analisar 3+ arquivos do mesmo tipo, extrair frames/vertices, estudar tabela de indices)

Responda em portugues. Seja especifico e baseie conclusoes nos dados fornecidos.
LEMBRETE: esta e uma HIPOTESE DE PESQUISA — nao sera executada imediatamente.
"@
}

# ── Ollama — free-text (sem format:json — queremos prosa + pseudocodigo) ──────

function Invoke-OllamaHunter {
    param([string]$Prompt, [string]$Url, [string]$Model)
    $body = [ordered]@{
        model  = $Model
        prompt = $Prompt
        stream = $false
    } | ConvertTo-Json -Compress -Depth 3

    $resp = Invoke-RestMethod -Uri $Url -Method Post -Body $body `
                -ContentType 'application/json; charset=utf-8' `
                -TimeoutSec 300 -ErrorAction Stop
    [string]$resp.response
}

# ── main ──────────────────────────────────────────────────────────────────────

Write-Host @"
======================================================================
 [TCT/PATTERN_HUNTER_v0210] TEIA-Pattern-Hunter-v0210.ps1 v$($script:Version)
 Modo    : Analise Estrutural Off-line + Teorizacao LLM (HR6+ Discovery)
 Modelo  : $Model
 Output  : $OutputRoot
======================================================================
"@ -ForegroundColor Cyan

if (-not (Test-Path $OutputRoot)) {
    New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
}

$file = Get-Item -LiteralPath $InputFile -Force -ErrorAction SilentlyContinue
if (-not $file -or $file.PSIsContainer) {
    Write-Host "[PH] ERRO: nao encontrado ou e diretorio: $InputFile" -ForegroundColor Red; exit 1
}

Write-Host "[PH] Arquivo: $($file.Name)  ($([math]::Round($file.Length/1KB,1)) KB)" -ForegroundColor Yellow

# SHA-256 via streaming (seguro para arquivos grandes)
Write-Host "[PH] SHA-256 (streaming)..." -ForegroundColor White
$sha256 = Get-FileSha256Stream $file.FullName
Write-Host "     $sha256"

# Idempotency guard
$theoryPath = Join-Path $OutputRoot "${sha256}_theory.md"
if (Test-Path $theoryPath) {
    Write-Host "[PH] SKIP — hipotese ja existe: ${sha256}_theory.md" -ForegroundColor DarkGray
    exit 0
}

# Carregar amostra (max 8 MB para analise; SHA ja computado via stream)
$sampleMax = 8 * 1024 * 1024
if ($file.Length -gt $sampleMax) {
    Write-Host ("     [AVISO] Arquivo grande ({0:F1} MB) — usando amostra de 8 MB" -f ($file.Length/1MB)) -ForegroundColor DarkYellow
}
$readLen = [Math]::Min($sampleMax, $file.Length)
$fs      = [System.IO.File]::OpenRead($file.FullName)
$bytes   = New-Object byte[] $readLen
[void]$fs.Read($bytes, 0, $readLen)
$fs.Dispose()

# Analise estrutural
Write-Host "[PH] Analise estrutural..." -ForegroundColor White
$magicType = Detect-MagicType $bytes
$entropy   = Get-Entropy $bytes
$uniqB     = Get-UniqueBytes $bytes
Write-Host "     tipo=$magicType  e=$entropy  unique_bytes=$uniqB"

# Header hex dump (256 bytes)
$hexDump = Get-HexDumpStr $bytes 256

# Byte frequency Top-16
$freqTop = Get-ByteFreqTop16 $bytes
$freqStr = ($freqTop | ForEach-Object {
    '  byte={0,3} ({1})  n={2,7}  {3,5}%' -f $_.v, $_.hex, $_.n, $_.pct
}) -join "`n"

# Mapa de entropia local
$chunkBytes  = $ChunkSizeKB * 1024
$totalChunks = [int][Math]::Ceiling($bytes.Length / $chunkBytes)
$entMap      = @(Get-LocalEntropyMap $bytes $chunkBytes $MaxChunks)
$entMapStr   = Format-EntropyMap $entMap
Write-Host "     Chunks: $($entMap.Count) amostrados de $totalChunks totais ($ChunkSizeKB KB cada)"

# Construir prompt
$prompt = Build-HunterPrompt `
    -FileName    $file.Name `
    -SizeBytes   $file.Length `
    -MagicType   $magicType `
    -Sha256      $sha256 `
    -Entropy     $entropy `
    -UniqB       $uniqB `
    -HexDump     $hexDump `
    -FreqTable   $freqStr `
    -EntropyMapTxt $entMapStr `
    -TotalChunks $totalChunks

Write-Host "[PH] Prompt: $($prompt.Length) chars — invocando $Model..." -ForegroundColor Yellow
$t0 = Get-Date
try {
    $llmText = Invoke-OllamaHunter -Prompt $prompt -Url $OllamaUrl -Model $Model
    $elapsed = [int]((Get-Date) - $t0).TotalSeconds
    Write-Host "     Resposta: $($llmText.Length) chars  Tempo: ${elapsed}s" -ForegroundColor Green
} catch {
    Write-Host "[PH] FALHA LLM: $_" -ForegroundColor Red; exit 1
}

# ── salvar hipotese (Set-Content + Add-Content para evitar interpolacao de $ no LLM) ──

$now    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$sizeMB = [math]::Round($file.Length / 1MB, 3)

$header = @"
# TEIA — Pattern Hunter Hypothesis
**Gerado:** $now
**Script:** TEIA-Pattern-Hunter-v0210.ps1 v$($script:Version)
**Modelo LLM:** $Model
**Status:** HIPOTESE_PESQUISA — nao validada, nao executavel

---

## Arquivo Analisado

| Campo | Valor |
|-------|-------|
| Nome | ``$($file.Name)`` |
| Tamanho | $($file.Length) bytes (${sizeMB} MB) |
| Tipo Detectado | ``$magicType`` |
| Entropia Global | $entropy bits/byte |
| SHA-256 | ``$sha256`` |

---

## Hipotese LLM — $Model

"@

Set-Content  -LiteralPath $theoryPath -Value $header  -Encoding UTF8
Add-Content  -LiteralPath $theoryPath -Value $llmText -Encoding UTF8

$sep = @"


---

## Prompt Enviado

<details>
<summary>Expandir prompt completo</summary>

``````
"@
Add-Content -LiteralPath $theoryPath -Value $sep    -Encoding UTF8
Add-Content -LiteralPath $theoryPath -Value $prompt -Encoding UTF8
Add-Content -LiteralPath $theoryPath -Value @'

```

</details>

---

*Hipotese de pesquisa. Zero bytes escritos no CAS.*
*Proxima acao: validacao empirica com 3+ arquivos do mesmo tipo.*
'@ -Encoding UTF8

Write-Host ''
Write-Host ('=' * 70) -ForegroundColor Cyan
Write-Host " [PH] Hipotese salva : $theoryPath" -ForegroundColor Green
Write-Host " [PH] CAS            : intocado — zero writes em objects/" -ForegroundColor Cyan
Write-Host ('=' * 70)
