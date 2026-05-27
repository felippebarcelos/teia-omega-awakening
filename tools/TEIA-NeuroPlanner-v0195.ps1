<#
.SYNOPSIS
    TEIA-NeuroPlanner-v0195.ps1 — Motor Seletor Determinístico (Rule-First)

.DESCRIPTION
    Arquitetura v0.19.5 — árvore de decisão "Regra Primeiro, IA Depois":

      1. Hard Rules (determinísticas, sem LLM):
           unique_bytes == 1          → gen.repeat
           period_bytes in (0, 512]   → gen.pattern
           entropy >= 7.0             → cas.raw
           magic_type em comprimidos  → cas.raw

      2. LLM (apenas quando nenhuma hard rule se aplica):
           Pergunta restrita: "LZMA ou Brotli?"
           Nunca inventa bytes, tamanhos ou padrões.

      3. Build-Recipe: parâmetros reais sempre extraídos do perfil estrutural.

      4. Integrity Proof (sem execução destrutiva):
           gen.repeat / gen.pattern: SHA-256 computado em memória e comparado.
           cmp.lzma / cmp.brotli / cas.raw: marcado como não verificável aqui.

.PARAMETER Files
    Caminhos dos arquivos a analisar. Aceita pipeline de Get-ChildItem.

.PARAMETER OllamaUrl
    Endpoint da API Ollama. Padrão: http://localhost:11434/api/generate

.PARAMETER Model
    Modelo Ollama a usar. Padrão: qwen2.5-coder:7b

.PARAMETER OutputRoot
    Diretório para salvar os candidates. Padrão: D:\TEIA_CORE\neuroplanner\candidates

.PARAMETER PromptTemplatePath
    Prompt canônico v0.19.5. Padrão: D:\TEIA_CORE\config\neuroplanner_prompt_v0195.md

.PARAMETER EntropySampleBytes
    Tamanho da amostra para cálculo de entropia. Padrão: 524288 (512 KB)

.PARAMETER DryRun
    Análise estrutural + hard rules apenas — sem LLM, sem escrita de candidates.

.EXAMPLE
    .\TEIA-NeuroPlanner-v0195.ps1 -Files "D:\TEIA_CORE\benchmarks\synth_planner\*.bin" -DryRun
    Get-ChildItem D:\TEIA_USER\Inbox -File | .\TEIA-NeuroPlanner-v0195.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string[]]$Files,

    [string]$OllamaUrl          = 'http://localhost:11434/api/generate',
    [string]$Model              = 'qwen2.5-coder:7b',
    [string]$OutputRoot         = 'D:\TEIA_CORE\neuroplanner\candidates',
    [string]$PromptTemplatePath = 'D:\TEIA_CORE\config\neuroplanner_prompt_v0195.md',
    [int]   $EntropySampleBytes = 524288,
    [switch]$DryRun
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ── low-level helpers ────────────────────────────────────────────────────────

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
    # Cap: 5 entradas / 128 chars por entrada / 512 chars total
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

# ── structural profiler ───────────────────────────────────────────────────────

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
    }
}

# ── métricas determinísticas ──────────────────────────────────────────────────

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

    [ordered]@{
        entropy        = $Profile.entropy
        unique_bytes   = $Profile.unique_bytes
        period_bytes   = $Profile.period_bytes
        size_bytes     = $Profile.size_bytes
        structure_type = $Profile.structure_type
        magic_type     = $Profile.magic_type
        first_byte_hex = $firstByteHex
        period_hex     = $periodHex
    }
}

# ── v0.19.5: árvore de hard rules ────────────────────────────────────────────

$COMPRESSED_MAGIC = @('application/zip','application/gzip','application/bzip2',
                      'application/xz','application/7z')

function Get-HardRuleDecision {
    param([object]$Metrics)

    # Regra 1: arquivo de byte único → gen.repeat
    if ([int]$Metrics.unique_bytes -eq 1) {
        return [ordered]@{
            source   = 'hard_rule'
            rule_id  = 'HR1'
            rule     = 'unique_bytes == 1'
            strategy = 'gen.repeat'
        }
    }
    # Regra 2: padrão periódico detectado → gen.pattern
    if ([int]$Metrics.period_bytes -gt 0 -and [int]$Metrics.period_bytes -le 512) {
        return [ordered]@{
            source   = 'hard_rule'
            rule_id  = 'HR2'
            rule     = "period_bytes=$($Metrics.period_bytes) ∈ (0, 512]"
            strategy = 'gen.pattern'
        }
    }
    # Regra 3: entropia máxima → cas.raw
    if ($Metrics.entropy -ge 7.0) {
        return [ordered]@{
            source   = 'hard_rule'
            rule_id  = 'HR3'
            rule     = "entropy=$($Metrics.entropy) >= 7.0"
            strategy = 'cas.raw'
        }
    }
    # Regra 4: magic de arquivo já comprimido → cas.raw
    if ($Metrics.magic_type -in $script:COMPRESSED_MAGIC) {
        return [ordered]@{
            source   = 'hard_rule'
            rule_id  = 'HR4'
            rule     = "magic_type=$($Metrics.magic_type) (arquivo já comprimido)"
            strategy = 'cas.raw'
        }
    }
    # Nenhuma regra se aplica → delegar ao LLM
    return [ordered]@{
        source   = 'llm_needed'
        rule_id  = $null
        rule     = 'entropy∈[2,7) sem período — LLM decide lzma vs brotli'
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
                op          = 'gen.pattern'
                pattern_b64 = [Convert]::ToBase64String($patB)
                pattern_hex = $hex
                repeat      = $repeat
                period_bytes = [int]$Metrics.period_bytes
            }
        }
        'cmp.lzma'   { [ordered]@{ op='cmp.lzma'  } }
        'cmp.brotli' { [ordered]@{ op='cmp.brotli' } }
        default      { [ordered]@{ op='cas.raw'    } }
    }
}

function Get-PlannerVerdict([string]$Strategy) {
    switch ($Strategy) {
        'gen.repeat'  { 'PROCEDURAL_CANDIDATE' }
        'gen.pattern' { 'PROCEDURAL_CANDIDATE' }
        'cmp.lzma'    { 'LZMA_PREFERRED' }
        'cmp.brotli'  { 'LZMA_PREFERRED' }
        default       { 'CAS_RAW' }
    }
}

# ── prova de integridade em memória (sem execução destrutiva) ─────────────────

function Test-RecipeIntegrity {
    param([object]$Recipe, [object]$Profile)

    switch ($Recipe.op) {
        'gen.repeat' {
            $byteVal = [Convert]::ToByte([string]$Recipe.value_hex, 16)
            $data    = New-Object byte[] $Recipe.size
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
        default {
            [ordered]@{
                verifiable = $false
                method     = "op=$($Recipe.op) requer execução de compressor externo"
                pass       = $null
            }
        }
    }
}

# ── LLM interface — só para lzma vs brotli ───────────────────────────────────

function Invoke-OllamaPlanner {
    param([string]$PromptTemplate, [object]$Metrics, [string]$Url, [string]$Model)

    # Envia apenas o subconjunto de métricas relevante para a escolha de compressor
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
        # Aceitar apenas cmp.lzma ou cmp.brotli; qualquer outro → fallback lzma
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
 [TCT/NEUROPLANNER_v0195] TEIA-NeuroPlanner-v0195.ps1
 Modo    : Rule-First → LLM apenas para lzma vs brotli
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
        Write-Host "[ERRO] Prompt não encontrado: $PromptTemplatePath" -ForegroundColor Red; exit 1
    }
    $promptTemplate = Get-Content $PromptTemplatePath -Raw -Encoding UTF8
}

$allProfiles  = [System.Collections.Generic.List[object]]::new()
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
        Write-Host "     e=$($profile.entropy)  u=$($profile.unique_bytes)  p=$($profile.period_bytes)  [$($profile.structure_type)]"
    } catch {
        Write-Host "[NP] FALHA análise: $_" -ForegroundColor Red; $totalFail++; continue
    }
    $null = $allProfiles.Add($profile)

    # 2 — Métricas determinísticas
    $metrics = Get-StructuralMetrics -Profile $profile

    # 3 — Hard Rules (sem LLM)
    $hrDecision = Get-HardRuleDecision -Metrics $metrics

    if ($hrDecision.source -eq 'hard_rule') {
        Write-Host "     [$(($hrDecision.rule_id))] $($hrDecision.rule) → $($hrDecision.strategy)" -ForegroundColor Green
    } else {
        Write-Host "     [LLM] $($hrDecision.rule)" -ForegroundColor Cyan
    }

    if ($DryRun) { Write-Host "     [DRY-RUN] sem LLM, sem escrita."; $totalOk++; continue }

    # 4 — Idempotência
    $candidatePath = Join-Path $OutputRoot "$($profile.sha256).candidate.json"
    if (Test-Path $candidatePath) {
        Write-Host "     [SKIP] candidate já existe."; $totalSkipped++; continue
    }

    # 5 — LLM apenas se nenhuma hard rule se aplicou
    $llmStrategy = $null; $llmReason = $null
    if ($hrDecision.source -eq 'llm_needed') {
        try {
            Write-Host "     LLM ($Model): lzma vs brotli..." -NoNewline
            $llmResp     = Invoke-OllamaPlanner -PromptTemplate $promptTemplate `
                               -Metrics $metrics -Url $OllamaUrl -Model $Model
            $llmStrategy = [string]$llmResp.strategy
            $llmReason   = [string]$llmResp.reason
            Write-Host " → $llmStrategy"
        } catch {
            Write-Host " FALHA LLM: $_" -ForegroundColor Red
            $llmStrategy = 'cmp.lzma'
            $llmReason   = "timeout/erro — fallback cmp.lzma"
        }
    }

    # 6 — Estratégia final e recipe
    $finalStrategy = if ($hrDecision.source -eq 'hard_rule') { $hrDecision.strategy } else { $llmStrategy }
    $recipe        = Build-Recipe -Strategy $finalStrategy -Metrics $metrics
    $verdict       = Get-PlannerVerdict -Strategy $finalStrategy

    # 7 — Prova de integridade em memória (sem execução destrutiva)
    $proof = Test-RecipeIntegrity -Recipe $recipe -Profile $profile
    if ($proof.verifiable) {
        $proofColor = if ($proof.pass) { 'Green' } else { 'Red' }
        $proofLabel = if ($proof.pass) { 'PASS' } else { 'FAIL' }
        Write-Host "     Prova SHA-256: $proofLabel — $($proof.method)" -ForegroundColor $proofColor
    }

    $verdictColor = if ($verdict -eq 'PROCEDURAL_CANDIDATE') { 'Green' }
                    elseif ($verdict -eq 'LZMA_PREFERRED')   { 'Yellow' }
                    else                                      { 'Gray' }
    Write-Host "     Verdict: $verdict" -ForegroundColor $verdictColor

    # 8 — Gravar candidate (atômico)
    $candidate = [ordered]@{
        version            = '0.19.5'
        analyzed_at        = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        file               = $profile.file
        sha256             = $profile.sha256
        size_bytes         = $profile.size_bytes
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
    } catch {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        Write-Host "[NP] FALHA escrita: $_" -ForegroundColor Red; $totalFail++
    }
}

# ── relatório final ───────────────────────────────────────────────────────────

Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
Write-Host ' RELATÓRIO FINAL — TEIA-NeuroPlanner-v0195' -ForegroundColor Cyan
Write-Host $('=' * 70)

[object[]]$proc   = @($allProfiles | Where-Object { $_.period_bytes -gt 0 -or $_.unique_bytes -le 1 -or $_.entropy -lt 2.0 })
[object[]]$highE  = @($allProfiles | Where-Object { $_.entropy -ge 7.0 })
[object[]]$medium = @($allProfiles | Where-Object { $_.entropy -ge 2.0 -and $_.entropy -lt 7.0 -and $_.period_bytes -eq 0 -and $_.unique_bytes -gt 1 })

Write-Host "`n Analisados: $($allProfiles.Count)  OK: $totalOk  Skip: $totalSkipped  Fail: $totalFail"
Write-Host ''
if ($proc.Count -gt 0) {
    Write-Host "  PROCEDURAIS ($($proc.Count)) — Hard Rules HR1/HR2:" -ForegroundColor Green
    foreach ($p in $proc) {
        $why = if ($p.unique_bytes -eq 1) { "HR1 byte-único e=$($p.entropy)" }
               elseif ($p.period_bytes -gt 0) { "HR2 período=$($p.period_bytes)B e=$($p.entropy)" }
               else { "e=$($p.entropy)" }
        Write-Host "    ✓ $($p.name) [$why]" -ForegroundColor Green
    }
}
if ($medium.Count -gt 0) {
    Write-Host "  LZMA/BROTLI ($($medium.Count)) — LLM decide:" -ForegroundColor Yellow
    foreach ($p in $medium) { Write-Host "    ~ $($p.name) [e=$($p.entropy) $($p.structure_type)]" -ForegroundColor Yellow }
}
if ($highE.Count -gt 0) {
    Write-Host "  CAS_RAW ($($highE.Count)) — HR3/HR4:" -ForegroundColor Gray
    foreach ($p in $highE) { Write-Host "    - $($p.name) [e=$($p.entropy) $($p.magic_type)]" -ForegroundColor Gray }
}
Write-Host ''
if ($DryRun) { Write-Host ' DRY-RUN: zero arquivos criados/modificados.' -ForegroundColor Yellow
} else        { Write-Host " Candidates em: $OutputRoot" -ForegroundColor Green }
Write-Host $('=' * 70)
