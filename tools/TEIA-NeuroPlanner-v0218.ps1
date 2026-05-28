<#
.SYNOPSIS
    TEIA-NeuroPlanner-v0218.ps1 — Motor Seletor Determinístico (Rule-First + HR6)

.DESCRIPTION
    Arquitetura v0.21.8 — árvore de decisão "Regra Primeiro, IA Depois":

      1. Hard Rules (determinísticas, sem LLM):
           unique_bytes == 1              → gen.repeat
           period_bytes in (0, 512]       → gen.pattern
           entropy >= 7.0                 → cas.raw
           magic_type em comprimidos      → cas.raw
           model/obj AND size<4096 AND v<20 → gen.parametric_mesh (HR6 — CANDIDATO)
           size_bytes < 8192              → cmp.brotli (HR5)

      2. LLM (apenas quando nenhuma hard rule se aplica):
           Pergunta restrita: "LZMA ou Brotli?"

      3. Contenção HR6: execution_status = candidate_only
           O Planner delibera a intenção. O código Encode/Decode NÃO está na UVM.

.PARAMETER Files
    Caminhos dos arquivos a analisar. Aceita pipeline de Get-ChildItem.

.PARAMETER OllamaUrl
    Endpoint da API Ollama. Padrão: http://localhost:11434/api/generate

.PARAMETER Model
    Modelo Ollama a usar. Padrão: qwen2.5-coder:7b

.PARAMETER OutputRoot
    Diretório para salvar os candidates. Padrão: D:\TEIA_CORE\neuroplanner\candidates

.PARAMETER PromptTemplatePath
    Prompt canônico v0.19.7. Padrão: D:\TEIA_CORE\config\neuroplanner_prompt_v0197.md

.PARAMETER EntropySampleBytes
    Tamanho da amostra para cálculo de entropia. Padrão: 524288 (512 KB)

.PARAMETER DryRun
    Análise estrutural + hard rules apenas — sem LLM, sem escrita de candidates.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string[]]$Files,

    [string]$OllamaUrl          = 'http://localhost:11434/api/generate',
    [string]$Model              = 'qwen2.5-coder:7b',
    [string]$OutputRoot         = 'D:\TEIA_CORE\neuroplanner\candidates',
    [string]$PromptTemplatePath = 'D:\TEIA_CORE\config\neuroplanner_prompt_v0197.md',
    [int]   $EntropySampleBytes = 524288,
    [switch]$DryRun
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ── low-level helpers (inalterados de v0199) ──────────────────────────────────

function sha256hex([byte[]]$b) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { -join ($sha.ComputeHash($b) | ForEach-Object { $_.ToString('x2') }) }
    finally { $sha.Dispose() }
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

function Get-RunStats([byte[]]$b) {
    if ($b.Length -eq 0) { return @{ runs=0; maxRun=0; avgRunLen=0.0 } }
    $runs = 1; $maxRun = 1; $cur = 1
    for ($i = 1; $i -lt $b.Length; $i++) {
        if ($b[$i] -eq $b[$i-1]) { $cur++ }
        else { if ($cur -gt $maxRun) { $maxRun = $cur }; $runs++; $cur = 1 }
    }
    if ($cur -gt $maxRun) { $maxRun = $cur }
    @{ runs=$runs; maxRun=$maxRun; avgRunLen=[math]::Round($b.Length/$runs,1) }
}

function Find-Period([byte[]]$b) {
    $maxP = [Math]::Min(512, [Math]::Floor($b.Length / 4))
    for ($p = 1; $p -le $maxP; $p++) {
        if ($b.Length % $p -ne 0) { continue }
        $ok    = $true
        $check = [Math]::Min(65536, $b.Length)
        for ($i = $p; $i -lt $check; $i++) {
            if ($b[$i] -ne $b[$i % $p]) { $ok = $false; break }
        }
        if ($ok) {
            for ($i = $check; $i -lt $b.Length; $i++) {
                if ($b[$i] -ne $b[$i % $p]) { $ok = $false; break }
            }
        }
        if ($ok) { return $p }
    }
    return 0
}

function Get-IsText([byte[]]$b) {
    $check = [Math]::Min(4096, $b.Length)
    for ($i = 0; $i -lt $check; $i++) { if ($b[$i] -eq 0) { return $false } }
    return $true
}

function Detect-MagicType([byte[]]$b) {
    if ($b.Length -lt 4) { return 'unknown' }
    $h = $b[0..([Math]::Min(15, $b.Length-1))]
    if ($h[0] -eq 0x89 -and $h[1] -eq 0x50 -and $h[2] -eq 0x4E -and $h[3] -eq 0x47) { return 'image/png' }
    if ($h[0] -eq 0xFF -and $h[1] -eq 0xD8 -and $h[2] -eq 0xFF)                      { return 'image/jpeg' }
    if ($h[0] -eq 0x25 -and $h[1] -eq 0x50 -and $h[2] -eq 0x44 -and $h[3] -eq 0x46) { return 'application/pdf' }
    if ($h[0] -eq 0x50 -and $h[1] -eq 0x4B -and $h[2] -eq 0x03 -and $h[3] -eq 0x04) { return 'application/zip' }
    if ($h[0] -eq 0x4D -and $h[1] -eq 0x5A)                                           { return 'application/pe' }
    if ($h[0] -eq 0x1F -and $h[1] -eq 0x8B)                                           { return 'application/gzip' }
    if ($h[0] -eq 0x42 -and $h[1] -eq 0x5A -and $h[2] -eq 0x68)                      { return 'application/bzip2' }
    if ($h[0] -eq 0xFD -and $h[1] -eq 0x37 -and $h[2] -eq 0x7A -and $h[3] -eq 0x58) { return 'application/xz' }
    if ($h[0] -eq 0x37 -and $h[1] -eq 0x7A -and $h[2] -eq 0xBC -and $h[3] -eq 0xAF) { return 'application/7z' }
    if ($h[0] -eq 0x52 -and $h[1] -eq 0x49 -and $h[2] -eq 0x46 -and $h[3] -eq 0x46) { return 'audio/wav' }
    if ($h[0] -eq 0xFF -and ($h[1] -band 0xE0) -eq 0xE0)                              { return 'audio/mp3' }
    if ($h[0] -eq 0x49 -and $h[1] -eq 0x44 -and $h[2] -eq 0x33)                      { return 'audio/mp3-id3' }
    if ($b.Length -ge 8 -and $h[4] -eq 0x66 -and $h[5] -eq 0x74 -and $h[6] -eq 0x79 -and $h[7] -eq 0x70) { return 'video/mp4' }
    if ($h[0] -eq 0xEF -and $h[1] -eq 0xBB -and $h[2] -eq 0xBF)                      { return 'text/utf8bom' }
    return 'application/octet-stream'
}

function Get-StringsSample([byte[]]$b, [int]$minLen = 8) {
    $results  = [System.Collections.Generic.List[string]]::new()
    $cur      = [System.Text.StringBuilder]::new()
    $limit    = [Math]::Min(65536, $b.Length)
    $totalLen = 0
    for ($i = 0; $i -lt $limit -and $results.Count -lt 5; $i++) {
        $byte = $b[$i]
        if ($byte -ge 0x20 -and $byte -le 0x7E) {
            [void]$cur.Append([char]$byte)
        } else {
            if ($cur.Length -ge $minLen) {
                $s = $cur.ToString()
                if ($s.Length -gt 128) { $s = $s.Substring(0, 128) }
                if (-not $results.Contains($s) -and ($totalLen + $s.Length) -le 512) {
                    $results.Add($s); $totalLen += $s.Length
                }
            }
            [void]$cur.Clear()
        }
    }
    if ($cur.Length -ge $minLen -and $results.Count -lt 5) {
        $s = $cur.ToString()
        if ($s.Length -gt 128) { $s = $s.Substring(0, 128) }
        if (-not $results.Contains($s) -and ($totalLen + $s.Length) -le 512) { $results.Add($s) }
    }
    if ($results.Count -eq 0) { return $null }
    $results.ToArray()
}

# ── HR6 — OBJ quick scan (NOVO v0218) ────────────────────────────────────────
# Conta `v ` e `f ` lines com early-exit em vertex_count >= 20 (HR6 threshold).
# Chamado apenas para arquivos OBJ com size_bytes < 4096 (pelo profiler).

function Get-ObjQuickScan([byte[]]$Bytes) {
    $text   = [System.Text.Encoding]::UTF8.GetString($Bytes)
    $vCount = 0; $fCount = 0
    foreach ($raw in ($text -split '\n')) {
        if ($vCount -ge 20) { break }   # early-exit: HR6 condition already false
        $line = $raw.Trim()
        if ($line -match '^v\s+')  { $vCount++ }
        elseif ($line -match '^f\s+(.+)') {
            $tokens = ($Matches[1].Trim() -split '\s+').Count
            $fCount += if ($tokens -eq 4) { 2 } else { 1 }
        }
    }
    return @{ vertex_count = $vCount; face_count = $fCount }
}

# ── structural profiler (v0218: adiciona OBJ detection + obj_quick_scan) ──────

function Get-FileStructuralProfile {
    param([System.IO.FileInfo]$File, [int]$SampleBytes = 524288)

    $bytes     = [System.IO.File]::ReadAllBytes($File.FullName)
    $sha256    = sha256hex $bytes
    $headerLen = [Math]::Min(32, $bytes.Length)
    $headerHex = -join ($bytes[0..($headerLen-1)] | ForEach-Object { $_.ToString('x2') })
    $magicType = Detect-MagicType $bytes

    $sampleSize = [Math]::Min($SampleBytes, $bytes.Length)
    $sample     = if ($sampleSize -lt $bytes.Length) { $bytes[0..($sampleSize-1)] } else { $bytes }

    $entropy   = Get-Entropy $sample
    $uniqueB   = Get-UniqueBytes $sample
    $runs      = Get-RunStats $sample
    $period    = Find-Period $sample
    $isText    = Get-IsText ($bytes[0..[Math]::Min(4095, $bytes.Length-1)])

    # HR6: detecta model/obj — .obj pode ter BOM (text/utf8bom) ou sem magic binário
    if ($magicType -in @('application/octet-stream','text/utf8bom') -and $isText -and
        $File.Extension.ToLower() -eq '.obj') {
        $magicType = 'model/obj'
    }

    # OBJ quick scan — apenas para arquivos pequenos elegíveis para HR6
    $objQuickScan = $null
    if ($magicType -eq 'model/obj' -and $File.Length -lt 4096) {
        $objQuickScan = Get-ObjQuickScan $bytes
    }

    $structType = if (-not $isText) { 'binary' } else { 'text' }
    $jsonKeys   = $null
    $xmlHint    = $false

    if ($isText -and $bytes.Length -gt 0) {
        $textSample = [System.Text.Encoding]::UTF8.GetString($bytes[0..[Math]::Min(131071, $bytes.Length-1)])
        $trimmed    = $textSample.TrimStart()
        if ($trimmed.Length -gt 0 -and $trimmed[0] -in @('{','[')) {
            try {
                $null = $textSample | ConvertFrom-Json -ErrorAction Stop
                $structType = 'json'
                $m = [regex]::Matches($textSample, '"([a-zA-Z_]\w{0,30})"\s*:')
                $freq = @{}
                foreach ($mm in $m) { $k = $mm.Groups[1].Value; $freq[$k] = ($freq[$k] ?? 0) + 1 }
                if ($freq.Count -gt 0) {
                    $top5 = ($freq.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 |
                             ForEach-Object { "$($_.Key)($($_.Value))" }) -join ', '
                    $jsonKeys = [ordered]@{ unique_keys=$freq.Count; total_keys=($freq.Values|Measure-Object -Sum).Sum; top5=$top5 }
                }
            } catch { $structType = 'text' }
        } elseif ($trimmed.StartsWith('<?xml') -or ($trimmed.Length -gt 0 -and $trimmed[0] -eq '<')) {
            $structType = 'xml'; $xmlHint = $true
        }
    }

    return [ordered]@{
        file           = $File.FullName
        name           = $File.Name
        ext            = $File.Extension.ToLower()
        size_bytes     = $File.Length
        sha256         = $sha256
        header_hex     = $headerHex
        magic_type     = $magicType
        structure_type = $structType
        xml_hint       = $xmlHint
        entropy        = $entropy
        unique_bytes   = $uniqueB
        period_bytes   = $period
        runs           = $runs
        json_keys      = $jsonKeys
        strings_sample = (Get-StringsSample $bytes)
        sample_bytes   = $sampleSize
        obj_quick_scan = $objQuickScan   # null para não-OBJ ou OBJ >= 4096B
    }
}

# ── métricas determinísticas (v0218: adiciona obj_vertex_count, obj_face_count) ─

function Get-StructuralMetrics {
    param([object]$Profile)

    $firstByteHex = if ($Profile.header_hex -and $Profile.header_hex.Length -ge 2) {
        $Profile.header_hex.Substring(0, 2)
    } else { '00' }

    $periodHex = ''
    if ($Profile.period_bytes -gt 0 -and $Profile.header_hex -and
        $Profile.header_hex.Length -ge ($Profile.period_bytes * 2)) {
        $periodHex = $Profile.header_hex.Substring(0, [int]$Profile.period_bytes * 2)
    }

    $oqs = $Profile.obj_quick_scan
    [ordered]@{
        entropy          = $Profile.entropy
        unique_bytes     = $Profile.unique_bytes
        period_bytes     = $Profile.period_bytes
        size_bytes       = $Profile.size_bytes
        structure_type   = $Profile.structure_type
        magic_type       = $Profile.magic_type
        first_byte_hex   = $firstByteHex
        period_hex       = $periodHex
        obj_vertex_count = if ($oqs) { [int]$oqs.vertex_count } else { -1 }
        obj_face_count   = if ($oqs) { [int]$oqs.face_count   } else { -1 }
    }
}

# ── v0218: árvore de hard rules (HR1-HR6, ordem de prioridade) ───────────────

$COMPRESSED_MAGIC = @('application/zip','application/gzip','application/bzip2',
                      'application/xz','application/7z')

function Get-HardRuleDecision {
    param([object]$Metrics)

    # HR1: arquivo de byte único → gen.repeat
    if ([int]$Metrics.unique_bytes -eq 1) {
        return [ordered]@{
            source   = 'hard_rule'
            rule_id  = 'HR1'
            rule     = 'unique_bytes == 1'
            strategy = 'gen.repeat'
        }
    }
    # HR2: padrão periódico detectado → gen.pattern
    if ([int]$Metrics.period_bytes -gt 0 -and [int]$Metrics.period_bytes -le 512) {
        return [ordered]@{
            source   = 'hard_rule'
            rule_id  = 'HR2'
            rule     = "period_bytes=$($Metrics.period_bytes) in (0, 512]"
            strategy = 'gen.pattern'
        }
    }
    # HR3: entropia máxima → cas.raw
    if ($Metrics.entropy -ge 7.0) {
        return [ordered]@{
            source   = 'hard_rule'
            rule_id  = 'HR3'
            rule     = "entropy=$($Metrics.entropy) >= 7.0"
            strategy = 'cas.raw'
        }
    }
    # HR4: magic de arquivo já comprimido → cas.raw
    if ($Metrics.magic_type -in $script:COMPRESSED_MAGIC) {
        return [ordered]@{
            source   = 'hard_rule'
            rule_id  = 'HR4'
            rule     = "magic_type=$($Metrics.magic_type) (arquivo já comprimido)"
            strategy = 'cas.raw'
        }
    }
    # HR6: primitiva 3D paramétrica (ANTES do HR5 — geometria supera heurística de tamanho)
    # Condições: model/obj AND size < 4096B AND 0 < vertex_count < 20
    if ($Metrics.magic_type -eq 'model/obj' -and
        [long]$Metrics.size_bytes -lt 4096 -and
        [int]$Metrics.obj_vertex_count -gt 0 -and
        [int]$Metrics.obj_vertex_count -lt 20) {
        return [ordered]@{
            source   = 'hard_rule'
            rule_id  = 'HR6'
            rule     = "model/obj v=$($Metrics.obj_vertex_count) f=$($Metrics.obj_face_count) size=$($Metrics.size_bytes) < 4096"
            strategy = 'gen.parametric_mesh'
        }
    }
    # HR5: arquivo pequeno (< 8 KB) → cmp.brotli
    if ([long]$Metrics.size_bytes -lt 8192) {
        return [ordered]@{
            source   = 'hard_rule'
            rule_id  = 'HR5'
            rule     = "size_bytes=$($Metrics.size_bytes) < 8192 (Brotli supera LZMA por dicionário estático)"
            strategy = 'cmp.brotli'
        }
    }
    # Nenhuma regra se aplica → delegar ao LLM
    return [ordered]@{
        source   = 'llm_needed'
        rule_id  = $null
        rule     = 'entropy in [2,7) sem período, size >= 8KB — LLM decide lzma vs brotli'
        strategy = $null
    }
}

function Build-Recipe {
    param([string]$Strategy, [object]$Metrics)

    switch ($Strategy) {
        'gen.repeat' {
            [ordered]@{
                op        = 'gen.repeat'
                value_hex = $Metrics.first_byte_hex
                size      = $Metrics.size_bytes
            }
        }
        'gen.pattern' {
            $hex     = [string]$Metrics.period_hex
            $patB    = [byte[]]@(for ($i = 0; $i -lt $hex.Length; $i += 2) {
                [Convert]::ToByte($hex.Substring($i,2), 16) })
            $repeat  = if ([int]$Metrics.period_bytes -gt 0) {
                [Math]::Floor([long]$Metrics.size_bytes / [int]$Metrics.period_bytes) } else { 0 }
            [ordered]@{
                op           = 'gen.pattern'
                pattern_b64  = [Convert]::ToBase64String($patB)
                pattern_hex  = $hex
                repeat       = $repeat
                period_bytes = [int]$Metrics.period_bytes
            }
        }
        # HR6: recipe declara intenção sem executar o encoder
        'gen.parametric_mesh' {
            [ordered]@{
                op               = 'gen.parametric_mesh'
                execution_status = 'candidate_only'
                note             = 'HR6: Encode-ParametricMesh pendente aprovação C7 — roteamento declarado, execução bloqueada'
            }
        }
        'cmp.lzma'   { [ordered]@{ op='cmp.lzma'   } }
        'cmp.brotli' { [ordered]@{ op='cmp.brotli'  } }
        default      { [ordered]@{ op='cas.raw'     } }
    }
}

function Get-PlannerVerdict([string]$Strategy) {
    switch ($Strategy) {
        'gen.repeat'          { 'PROCEDURAL_CANDIDATE' }
        'gen.pattern'         { 'PROCEDURAL_CANDIDATE' }
        'gen.parametric_mesh' { 'PARAMETRIC_CANDIDATE' }
        'cmp.lzma'            { 'LZMA_PREFERRED' }
        'cmp.brotli'          { 'BROTLI_PREFERRED' }
        default               { 'CAS_RAW' }
    }
}

# ── prova de integridade em memória (inalterada de v0199) ─────────────────────

function Test-RecipeIntegrity {
    param([object]$Recipe, [object]$Profile)

    switch ($Recipe.op) {
        'gen.repeat' {
            $byteVal  = [Convert]::ToByte([string]$Recipe.value_hex, 16)
            $data     = New-Object byte[] $Recipe.size
            for ($i = 0; $i -lt $Recipe.size; $i++) { $data[$i] = $byteVal }
            $computed = sha256hex $data
            [ordered]@{
                verifiable      = $true
                method          = "gen.repeat(0x$($Recipe.value_hex.ToUpper()), $($Recipe.size))"
                computed_sha256 = $computed
                expected_sha256 = $Profile.sha256
                pass            = ($computed -eq $Profile.sha256)
            }
        }
        'gen.pattern' {
            $patBytes    = [Convert]::FromBase64String([string]$Recipe.pattern_b64)
            $repeatCount = [int]$Recipe.repeat
            $totalSize   = $patBytes.Length * $repeatCount
            $data        = New-Object byte[] $totalSize
            for ($r = 0; $r -lt $repeatCount; $r++) {
                [Array]::Copy($patBytes, 0, $data, $r * $patBytes.Length, $patBytes.Length)
            }
            $computed = sha256hex $data
            [ordered]@{
                verifiable      = $true
                method          = "gen.pattern(period=$($patBytes.Length)B, repeat=$repeatCount)"
                computed_sha256 = $computed
                expected_sha256 = $Profile.sha256
                pass            = ($computed -eq $Profile.sha256)
            }
        }
        # HR6: não verificável aqui — verifica ao executar Encode-ParametricMesh
        'gen.parametric_mesh' {
            [ordered]@{
                verifiable = $false
                method     = 'gen.parametric_mesh: requer Encode-ParametricMesh (candidate_only — C7 pendente)'
                pass       = $null
            }
        }
        default {
            [ordered]@{
                verifiable = $false
                method     = "op=$($Recipe.op) requer execução de compressor externo"
                pass       = $null
            }
        }
    }
}

# ── LLM interface (inalterada de v0199) ───────────────────────────────────────

function Invoke-OllamaPlanner {
    param([string]$PromptTemplate, [object]$Metrics, [string]$Url, [string]$Model)

    $llmMetrics = [ordered]@{
        entropy        = $Metrics.entropy
        unique_bytes   = $Metrics.unique_bytes
        size_bytes     = $Metrics.size_bytes
        structure_type = $Metrics.structure_type
        magic_type     = $Metrics.magic_type
    }
    $metricsJson = $llmMetrics | ConvertTo-Json -Compress
    $fullPrompt  = $PromptTemplate -replace '\{\{METRICS_JSON\}\}', $metricsJson

    $body = [ordered]@{
        model  = $Model
        prompt = $fullPrompt
        stream = $false
        format = 'json'
    } | ConvertTo-Json -Compress

    $response = Invoke-RestMethod -Uri $Url -Method Post -Body $body `
                    -ContentType 'application/json; charset=utf-8' `
                    -TimeoutSec 180 -ErrorAction Stop

    try {
        $parsed = $response.response | ConvertFrom-Json -ErrorAction Stop
        if ($parsed.strategy -notin @('cmp.lzma','cmp.brotli')) {
            return [ordered]@{ strategy='cmp.lzma'
                reason="LLM retornou '$($parsed.strategy)' — fora do escopo; fallback cmp.lzma" }
        }
        return $parsed
    } catch {
        return [ordered]@{ strategy='cmp.lzma'
            reason="JSON inválido do LLM: $($_.Exception.Message)" }
    }
}

# ── begin ─────────────────────────────────────────────────────────────────────

$banner = @"
======================================================================
 [TCT/NEUROPLANNER_v0218] TEIA-NeuroPlanner-v0218.ps1
 Modo    : Rule-First (HR1-HR6) → LLM apenas para arquivos >= 8KB sem período/OBJ
 HR6     : model/obj AND size<4096B AND v<20 → gen.parametric_mesh (candidate_only)
 Modelo  : $Model  |  Modo: $(if ($DryRun) { 'DRY-RUN' } else { 'ATIVO' })
 Output  : $OutputRoot
======================================================================
"@
Write-Host $banner -ForegroundColor Cyan

foreach ($d in @($OutputRoot, (Split-Path $PromptTemplatePath))) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$promptTemplate = $null
if (-not $DryRun) {
    if (-not (Test-Path $PromptTemplatePath)) {
        Write-Host "[AVISO] Prompt não encontrado: $PromptTemplatePath — LLM desabilitado (fallback cmp.lzma)" -ForegroundColor Yellow
    } else {
        $promptTemplate = Get-Content $PromptTemplatePath -Raw -Encoding UTF8
    }
}

$allProfiles  = [System.Collections.Generic.List[object]]::new()
$allDecisions = [System.Collections.Generic.List[hashtable]]::new()
$totalOk      = 0
$totalFail    = 0
$totalSkipped = 0

# ── process ───────────────────────────────────────────────────────────────────

foreach ($filePath in $Files) {
    $file = Get-Item -LiteralPath $filePath -Force -ErrorAction SilentlyContinue
    if (-not $file -or $file.PSIsContainer) { Write-Host "[NP] Ignorado: $filePath"; continue }

    Write-Host "`n[NP] $($file.Name) ($([math]::Round($file.Length/1KB,1)) KB)" -ForegroundColor Yellow

    # 1 — Perfil estrutural
    $profile = $null
    try {
        $profile = Get-FileStructuralProfile -File $file -SampleBytes $EntropySampleBytes
        $objInfo = if ($profile.obj_quick_scan) { " v=$($profile.obj_quick_scan.vertex_count) f=$($profile.obj_quick_scan.face_count)" } else { '' }
        Write-Host "     e=$($profile.entropy)  u=$($profile.unique_bytes)  p=$($profile.period_bytes)  [$($profile.magic_type)]$objInfo"
    } catch {
        Write-Host "[NP] FALHA análise: $_" -ForegroundColor Red; $totalFail++; continue
    }
    $null = $allProfiles.Add($profile)

    # 2 — Métricas determinísticas
    $metrics = Get-StructuralMetrics -Profile $profile

    # 3 — Hard Rules (sem LLM)
    $hrDecision = Get-HardRuleDecision -Metrics $metrics

    if ($hrDecision.source -eq 'hard_rule') {
        $ruleColor = switch ($hrDecision.rule_id) {
            'HR6' { 'Magenta' }
            'HR5' { 'Cyan' }
            { $_ -in 'HR1','HR2' } { 'Green' }
            default { 'Gray' }
        }
        Write-Host "     [$($hrDecision.rule_id)] $($hrDecision.rule) → $($hrDecision.strategy)" -ForegroundColor $ruleColor
    } else {
        Write-Host "     [LLM] $($hrDecision.rule)" -ForegroundColor Cyan
    }

    if ($DryRun) { Write-Host "     [DRY-RUN] sem LLM, sem escrita."; $totalOk++
        $null = $allDecisions.Add(@{ Name=$file.Name; Strategy=$hrDecision.strategy ?? 'llm_needed'; RuleId=$hrDecision.rule_id })
        continue
    }

    # 4 — Idempotência
    $candidatePath = Join-Path $OutputRoot "$($profile.sha256).candidate.json"
    if (Test-Path $candidatePath) {
        Write-Host "     [SKIP] candidate já existe."; $totalSkipped++
        $null = $allDecisions.Add(@{ Name=$file.Name; Strategy='skip'; RuleId='SKIP' })
        continue
    }

    # 5 — LLM apenas se nenhuma hard rule se aplicou
    $llmStrategy = $null; $llmReason = $null
    if ($hrDecision.source -eq 'llm_needed') {
        if ($promptTemplate) {
            try {
                Write-Host "     LLM ($Model): lzma vs brotli..." -NoNewline
                $llmResp     = Invoke-OllamaPlanner -PromptTemplate $promptTemplate `
                                   -Metrics $metrics -Url $OllamaUrl -Model $Model
                $llmStrategy = [string]$llmResp.strategy
                $llmReason   = [string]$llmResp.reason
                Write-Host " → $llmStrategy"
            } catch {
                Write-Host " FALHA LLM: $_" -ForegroundColor Red
                $llmStrategy = 'cmp.lzma'; $llmReason = "timeout/erro — fallback cmp.lzma"
            }
        } else {
            $llmStrategy = 'cmp.lzma'; $llmReason = 'prompt ausente — fallback cmp.lzma'
            Write-Host "     [LLM-SKIP] prompt ausente → fallback cmp.lzma" -ForegroundColor Yellow
        }
    }

    # 6 — Estratégia final e recipe
    $finalStrategy = if ($hrDecision.source -eq 'hard_rule') { $hrDecision.strategy } else { $llmStrategy }
    $recipe        = Build-Recipe -Strategy $finalStrategy -Metrics $metrics
    $verdict       = Get-PlannerVerdict -Strategy $finalStrategy

    # 7 — Prova de integridade
    $proof = Test-RecipeIntegrity -Recipe $recipe -Profile $profile
    if ($proof.verifiable) {
        $proofColor = if ($proof.pass) { 'Green' } else { 'Red' }
        Write-Host "     Prova SHA-256: $(if($proof.pass){'PASS'}else{'FAIL'}) — $($proof.method)" -ForegroundColor $proofColor
    }

    $verdictColor = switch ($verdict) {
        'PARAMETRIC_CANDIDATE' { 'Magenta' }
        'PROCEDURAL_CANDIDATE' { 'Green'   }
        'BROTLI_PREFERRED'     { 'Cyan'    }
        'LZMA_PREFERRED'       { 'Yellow'  }
        default                { 'Gray'    }
    }
    Write-Host "     Verdict: $verdict" -ForegroundColor $verdictColor

    # 8 — Gravar candidate (atômico)
    # HR6: execution_status = candidate_only — o encoder não está integrado na UVM
    $candidate = [ordered]@{
        version            = '0.21.8'
        analyzed_at        = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        file               = $profile.file
        sha256             = $profile.sha256
        size_bytes         = $profile.size_bytes
        execution_status   = if ($finalStrategy -eq 'gen.parametric_mesh') { 'candidate_only' } else { 'active' }
        structural_profile = $profile
        metrics            = $metrics
        hard_rule_decision = $hrDecision
        llm_model          = if ($hrDecision.source -eq 'llm_needed') { $Model } else { $null }
        llm_strategy       = $llmStrategy
        llm_reason         = $llmReason
        final_strategy     = $finalStrategy
        recipe             = $recipe
        integrity_proof    = $proof
        planner_verdict    = $verdict
    }

    $tmp = "$candidatePath.tmp"
    try {
        $json = $candidate | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($tmp, $json, [System.Text.Encoding]::UTF8)
        $null = Get-Content $tmp -Raw | ConvertFrom-Json -ErrorAction Stop
        Move-Item -LiteralPath $tmp -Destination $candidatePath -Force -ErrorAction Stop
        Write-Host "     Gravado: $($profile.sha256.Substring(0,16))..."
        $totalOk++
        $null = $allDecisions.Add(@{ Name=$file.Name; Strategy=$finalStrategy; RuleId=$hrDecision.rule_id ?? 'LLM'; Verdict=$verdict })
    } catch {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        Write-Host "[NP] FALHA escrita: $_" -ForegroundColor Red; $totalFail++
    }
}

# ── relatório final ───────────────────────────────────────────────────────────

Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
Write-Host ' RELATÓRIO FINAL — TEIA-NeuroPlanner-v0218' -ForegroundColor Cyan
Write-Host $('=' * 70)

# HR6 filter: profiles roteados para gen.parametric_mesh
$hr6Dec   = @($allDecisions | Where-Object { $_.Strategy -eq 'gen.parametric_mesh' })
$hr6Names = $hr6Dec | ForEach-Object { $_.Name }

[object[]]$proc    = @($allProfiles | Where-Object { $_.name -notin $hr6Names -and ($_.period_bytes -gt 0 -or $_.unique_bytes -le 1 -or $_.entropy -lt 2.0) })
[object[]]$highE   = @($allProfiles | Where-Object { $_.name -notin $hr6Names -and $_.entropy -ge 7.0 })
[object[]]$hrSmall = @($allProfiles | Where-Object { $_.name -notin $hr6Names -and $_.entropy -ge 2.0 -and $_.entropy -lt 7.0 -and $_.period_bytes -eq 0 -and $_.unique_bytes -gt 1 -and [long]$_.size_bytes -lt 8192 })
[object[]]$medium  = @($allProfiles | Where-Object { $_.name -notin $hr6Names -and $_.entropy -ge 2.0 -and $_.entropy -lt 7.0 -and $_.period_bytes -eq 0 -and $_.unique_bytes -gt 1 -and [long]$_.size_bytes -ge 8192 })

Write-Host "`n Analisados: $($allProfiles.Count)  OK: $totalOk  Skip: $totalSkipped  Fail: $totalFail"
Write-Host ''

if ($hr6Dec.Count -gt 0) {
    Write-Host "  HR6_PARAMETRIC ($($hr6Dec.Count)) — gen.parametric_mesh [candidate_only]:" -ForegroundColor Magenta
    foreach ($d in $hr6Dec) {
        $p = $allProfiles | Where-Object { $_.name -eq $d.Name } | Select-Object -First 1
        $vInfo = if ($p.obj_quick_scan) { "v=$($p.obj_quick_scan.vertex_count) f=$($p.obj_quick_scan.face_count)" } else { '' }
        Write-Host "    ✓ $($d.Name) [HR6 $vInfo size=$($p.size_bytes)B → candidate_only]" -ForegroundColor Magenta
    }
}
if ($proc.Count -gt 0) {
    Write-Host "  PROCEDURAIS ($($proc.Count)) — Hard Rules HR1/HR2:" -ForegroundColor Green
    foreach ($p in $proc) {
        $why = if ($p.unique_bytes -eq 1) { "HR1" } elseif ($p.period_bytes -gt 0) { "HR2 p=$($p.period_bytes)B" } else { "e=$($p.entropy)" }
        Write-Host "    ✓ $($p.name) [$why]" -ForegroundColor Green
    }
}
if ($hrSmall.Count -gt 0) {
    Write-Host "  HR5_BROTLI ($($hrSmall.Count)) — Hard Rule HR5 (size < 8 KB):" -ForegroundColor Cyan
    foreach ($p in $hrSmall) { Write-Host "    ✓ $($p.name) [HR5 size=$($p.size_bytes)B → cmp.brotli]" -ForegroundColor Cyan }
}
if ($medium.Count -gt 0) {
    Write-Host "  LZMA/BROTLI ($($medium.Count)) — LLM decide (size >= 8 KB):" -ForegroundColor Yellow
    foreach ($p in $medium) { Write-Host "    ~ $($p.name) [e=$($p.entropy) $($p.magic_type) $($p.size_bytes)B]" -ForegroundColor Yellow }
}
if ($highE.Count -gt 0) {
    Write-Host "  CAS_RAW ($($highE.Count)) — HR3/HR4:" -ForegroundColor Gray
    foreach ($p in $highE) { Write-Host "    - $($p.name) [e=$($p.entropy)]" -ForegroundColor Gray }
}
Write-Host ''
if ($DryRun) { Write-Host ' DRY-RUN: zero arquivos criados/modificados.' -ForegroundColor Yellow
} else        { Write-Host " Candidates em: $OutputRoot" -ForegroundColor Green }
Write-Host $('=' * 70)
