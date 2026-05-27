<#
.SYNOPSIS
    TEIA-NeuroPlanner-v0194.ps1 — Planner híbrido: LLM como roteador, UVM como executor de medidas reais

.DESCRIPTION
    Arquitetura v0.19.4 — separação estrita de agência:
      Camada 1 (PowerShell): extrai todos os parâmetros deterministicamente do perfil estrutural.
      Camada 2 (LLM/Ollama): decide APENAS a estratégia (gen.repeat|gen.pattern|cmp.lzma|cas.raw).
      Camada 3 (Vacina/PS):  valida coerência matemática da estratégia; sobrescreve se incoerente.
      Camada 4 (PS):         monta a recipe final com parâmetros reais — nunca parâmetros do LLM.

    O LLM nunca mais sugere value_hex, size ou pattern. A Regra de Ouro (SHA-256) pode ser
    verificada deterministicamente porque todos os parâmetros vêm do arquivo original.

.PARAMETER Files
    Caminhos dos arquivos a analisar. Aceita pipeline de Get-ChildItem.

.PARAMETER OllamaUrl
    Endpoint da API Ollama. Padrão: http://localhost:11434/api/generate

.PARAMETER Model
    Modelo Ollama a usar. Padrão: qwen2.5-coder:7b

.PARAMETER OutputRoot
    Diretório para salvar os candidates. Padrão: D:\TEIA_CORE\neuroplanner\candidates

.PARAMETER PromptTemplatePath
    Caminho do prompt canônico v0.19.4. Padrão: D:\TEIA_CORE\config\neuroplanner_prompt_v0194.md

.PARAMETER EntropySampleBytes
    Tamanho da amostra para cálculo de entropia. Padrão: 524288 (512 KB)

.PARAMETER DryRun
    Executa apenas a análise estrutural; não chama LLM e não grava candidates.

.EXAMPLE
    .\TEIA-NeuroPlanner-v0194.ps1 -Files "D:\TEIA_CORE\benchmarks\synth_planner\*.bin" -DryRun
    Get-ChildItem D:\TEIA_USER\Inbox -File | .\TEIA-NeuroPlanner-v0194.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string[]]$Files,

    [string]$OllamaUrl          = 'http://localhost:11434/api/generate',
    [string]$Model              = 'qwen2.5-coder:7b',
    [string]$OutputRoot         = 'D:\TEIA_CORE\neuroplanner\candidates',
    [string]$PromptTemplatePath = 'D:\TEIA_CORE\config\neuroplanner_prompt_v0194.md',
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
        $ok = $true
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
    # Cap: máx 5 strings, cada uma com máx 128 chars, total máx 512 chars
    # Evita context flooding do LLM quando o arquivo é ASCII-printável (bug #5 v0.19.3)
    $results = [System.Collections.Generic.List[string]]::new()
    $cur     = [System.Text.StringBuilder]::new()
    $limit   = [Math]::Min(65536, $b.Length)
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
                    $results.Add($s)
                    $totalLen += $s.Length
                }
            }
            [void]$cur.Clear()
        }
    }
    if ($cur.Length -ge $minLen -and $results.Count -lt 5) {
        $s = $cur.ToString()
        if ($s.Length -gt 128) { $s = $s.Substring(0, 128) }
        if (-not $results.Contains($s) -and ($totalLen + $s.Length) -le 512) {
            $results.Add($s)
        }
    }
    if ($results.Count -eq 0) { return $null }
    $results.ToArray()
}

# ── structural profiler ───────────────────────────────────────────────────────

function Get-FileStructuralProfile {
    param(
        [System.IO.FileInfo]$File,
        [int]$SampleBytes = 524288
    )

    $bytes      = [System.IO.File]::ReadAllBytes($File.FullName)
    $sha256     = sha256hex $bytes
    $headerLen  = [Math]::Min(32, $bytes.Length)
    $headerHex  = -join ($bytes[0..($headerLen-1)] | ForEach-Object { $_.ToString('x2') })
    $magicType  = Detect-MagicType $bytes

    $sampleSize = [Math]::Min($SampleBytes, $bytes.Length)
    $sample     = if ($sampleSize -lt $bytes.Length) { $bytes[0..($sampleSize-1)] } else { $bytes }

    $entropy    = Get-Entropy $sample
    $uniqueB    = Get-UniqueBytes $sample
    $runs       = Get-RunStats $sample
    $period     = Find-Period $sample
    $isText     = Get-IsText ($bytes[0..[Math]::Min(4095, $bytes.Length-1)])

    $structType = if (-not $isText) { 'binary' } else { 'text' }
    $jsonKeys   = $null
    $xmlHint    = $false

    if ($isText -and $bytes.Length -gt 0) {
        $textSample = [System.Text.Encoding]::UTF8.GetString($bytes[0..[Math]::Min(131071, $bytes.Length-1)])
        $trimmed    = $textSample.TrimStart()
        if ($trimmed.Length -gt 0 -and $trimmed[0] -in @('{', '[')) {
            try {
                $null = $textSample | ConvertFrom-Json -ErrorAction Stop
                $structType = 'json'
                $matches = [regex]::Matches($textSample, '"([a-zA-Z_]\w{0,30})"\s*:')
                $freq = @{}
                foreach ($m in $matches) { $k = $m.Groups[1].Value; $freq[$k] = ($freq[$k] ?? 0) + 1 }
                if ($freq.Count -gt 0) {
                    $top5 = ($freq.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 |
                             ForEach-Object { "$($_.Key)($($_.Value))" }) -join ', '
                    $jsonKeys = [ordered]@{
                        unique_keys = $freq.Count
                        total_keys  = ($freq.Values | Measure-Object -Sum).Sum
                        top5        = $top5
                    }
                }
            } catch { $structType = 'text' }
        } elseif ($trimmed.StartsWith('<?xml') -or ($trimmed.Length -gt 0 -and $trimmed[0] -eq '<')) {
            $structType = 'xml'
            $xmlHint    = $true
        }
    }

    $strings = Get-StringsSample $bytes

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
        strings_sample = $strings
        sample_bytes   = $sampleSize
    }
}

# ── v0.19.4: nova camada analítica determinística ─────────────────────────────

function Get-StructuralMetrics {
    param([object]$Profile)

    # first_byte_hex: primeiros 2 chars de header_hex = o byte de repetição para gen.repeat
    $firstByteHex = if ($Profile.header_hex -and $Profile.header_hex.Length -ge 2) {
        $Profile.header_hex.Substring(0, 2)
    } else { '00' }

    # period_hex: primeiros (period_bytes * 2) chars de header_hex = o padrão para gen.pattern
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

function Test-StrategyCoherence {
    param([string]$Strategy, [object]$Metrics)

    $compressedMagic = @('application/zip','application/gzip','application/bzip2',
                          'application/xz','application/7z')

    # Vacina 1: gen.repeat exige único byte e entropia zero
    if ($Strategy -eq 'gen.repeat' -and $Metrics.entropy -gt 0.1) {
        return [ordered]@{ ok=$false; fallback='cmp.lzma'
            reason="gen.repeat bloqueado: entropy=$($Metrics.entropy) > 0.1 (arquivo não é byte único)" }
    }
    if ($Strategy -eq 'gen.repeat' -and $Metrics.unique_bytes -gt 1) {
        return [ordered]@{ ok=$false; fallback='cmp.lzma'
            reason="gen.repeat bloqueado: unique_bytes=$($Metrics.unique_bytes) > 1" }
    }
    # Vacina 2: gen.pattern exige período detectado
    if ($Strategy -eq 'gen.pattern' -and [int]$Metrics.period_bytes -le 1) {
        return [ordered]@{ ok=$false; fallback='cmp.lzma'
            reason="gen.pattern bloqueado: period_bytes=$($Metrics.period_bytes) ≤ 1 (nenhum padrão detectado)" }
    }
    # Vacina 3: entropia alta força cas.raw
    if ($Metrics.entropy -ge 7.0 -and $Strategy -ne 'cas.raw') {
        return [ordered]@{ ok=$false; fallback='cas.raw'
            reason="entropia=$($Metrics.entropy) ≥ 7.0 → cas.raw forçado" }
    }
    # Vacina 4: magic de arquivo comprimido força cas.raw
    if ($Metrics.magic_type -in $compressedMagic -and $Strategy -ne 'cas.raw') {
        return [ordered]@{ ok=$false; fallback='cas.raw'
            reason="magic_type=$($Metrics.magic_type) indica arquivo já comprimido → cas.raw forçado" }
    }

    return [ordered]@{ ok=$true; fallback=$null; reason='ok' }
}

function Build-Recipe {
    param([string]$Strategy, [object]$Metrics)

    switch ($Strategy) {
        'gen.repeat' {
            return [ordered]@{
                op        = 'gen.repeat'
                value_hex = $Metrics.first_byte_hex
                size      = $Metrics.size_bytes
            }
        }
        'gen.pattern' {
            $hexStr   = [string]$Metrics.period_hex
            $patBytes = [byte[]]@(for ($i = 0; $i -lt $hexStr.Length; $i += 2) {
                [byte][Convert]::ToByte($hexStr.Substring($i, 2), 16)
            })
            $patB64      = [Convert]::ToBase64String($patBytes)
            $repeatCount = if ([int]$Metrics.period_bytes -gt 0) {
                [Math]::Floor([long]$Metrics.size_bytes / [int]$Metrics.period_bytes)
            } else { 0 }
            return [ordered]@{
                op          = 'gen.pattern'
                pattern_b64 = $patB64
                repeat      = $repeatCount
            }
        }
        'cmp.lzma' {
            return [ordered]@{ op = 'cmp.lzma' }
        }
        default {
            return [ordered]@{ op = 'cas.raw' }
        }
    }
}

function Get-PlannerVerdict([string]$Strategy) {
    switch ($Strategy) {
        'gen.repeat'  { return 'PROCEDURAL_CANDIDATE' }
        'gen.pattern' { return 'PROCEDURAL_CANDIDATE' }
        'cmp.lzma'    { return 'LZMA_PREFERRED' }
        'cmp.brotli'  { return 'LZMA_PREFERRED' }
        default       { return 'CAS_RAW' }
    }
}

# ── LLM interface (decisão estratégica apenas) ────────────────────────────────

function Invoke-OllamaPlanner {
    param(
        [string]$PromptTemplate,
        [object]$Metrics,
        [string]$Url,
        [string]$Model
    )

    # Injeta apenas as métricas compactas (sem strings_sample, sem header_hex completo)
    # O LLM não precisa de parâmetros — só das assinaturas estruturais para decidir a estratégia
    $metricsForLlm = [ordered]@{
        entropy        = $Metrics.entropy
        unique_bytes   = $Metrics.unique_bytes
        period_bytes   = $Metrics.period_bytes
        size_bytes     = $Metrics.size_bytes
        structure_type = $Metrics.structure_type
        magic_type     = $Metrics.magic_type
    }
    $metricsJson = $metricsForLlm | ConvertTo-Json -Compress
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

    $llmText = $response.response
    try {
        $parsed = $llmText | ConvertFrom-Json -ErrorAction Stop
        # Garantir que strategy é uma string válida
        if (-not $parsed.strategy -or $parsed.strategy -notin @('gen.repeat','gen.pattern','cmp.lzma','cas.raw')) {
            return [ordered]@{ strategy='cas.raw'; reason="LLM retornou estratégia inválida: '$($parsed.strategy)' — fallback cas.raw" }
        }
        return $parsed
    } catch {
        return [ordered]@{ strategy='cas.raw'; reason="LLM retornou JSON inválido: $($_.Exception.Message)" }
    }
}

# ── begin ─────────────────────────────────────────────────────────────────────

$banner = @"
======================================================================
 [TCT/NEUROPLANNER_v0194] TEIA-NeuroPlanner-v0194.ps1
 Arquitetura : LLM = roteador estratégico | PS = executor de medidas reais
 Modo        : $(if ($DryRun) { 'DRY-RUN (read-only — sem LLM, sem escrita)' } else { 'ATIVO (análise + LLM + candidates)' })
 Modelo      : $Model
 Output      : $OutputRoot
======================================================================
"@
Write-Host $banner -ForegroundColor Cyan

foreach ($d in @($OutputRoot, (Split-Path $PromptTemplatePath))) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Write-Host "[INIT] Diretório criado: $d"
    }
}

$promptTemplate = $null
if (-not $DryRun) {
    if (-not (Test-Path $PromptTemplatePath)) {
        Write-Host "[ERRO] Prompt canônico não encontrado: $PromptTemplatePath" -ForegroundColor Red
        exit 1
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
    if (-not $file -or $file.PSIsContainer) {
        Write-Host "[NP] Ignorado (inexistente ou pasta): $filePath"
        continue
    }

    Write-Host "`n[NP] Analisando: $($file.Name) ($([math]::Round($file.Length/1KB,1)) KB)" -ForegroundColor Yellow

    # 1 — Perfil estrutural (sempre read-only)
    $profile = $null
    try {
        $profile = Get-FileStructuralProfile -File $file -SampleBytes $EntropySampleBytes
        Write-Host "     SHA-256    : $($profile.sha256.Substring(0,16))..."
        Write-Host "     Entropia   : $($profile.entropy) bits/byte"
        Write-Host "     Únicos     : $($profile.unique_bytes) / 256"
        Write-Host "     Período    : $(if ($profile.period_bytes -gt 0) { "$($profile.period_bytes)B" } else { 'nenhum' })"
        Write-Host "     Estrutura  : $($profile.structure_type) | $($profile.magic_type)"
    } catch {
        Write-Host "[NP] FALHA ao analisar: $($file.Name) — $_" -ForegroundColor Red
        $totalFail++
        continue
    }

    $null = $allProfiles.Add($profile)

    if ($DryRun) {
        Write-Host "     [DRY-RUN] Análise estrutural concluída — LLM e escrita omitidos."
        $totalOk++
        continue
    }

    # 2 — Idempotência
    $candidatePath = Join-Path $OutputRoot "$($profile.sha256).candidate.json"
    if (Test-Path $candidatePath) {
        Write-Host "     [SKIP] Candidate já existe: $($profile.sha256.Substring(0,16))..."
        $totalSkipped++
        continue
    }

    # 3 — Extrair métricas determinísticas (parâmetros reais do arquivo)
    $metrics = Get-StructuralMetrics -Profile $profile

    # 4 — Consulta ao LLM: APENAS decisão de estratégia
    $llmResponse = $null
    $llmStrategy = 'cas.raw'
    $llmReason   = 'não consultado'
    try {
        Write-Host "     LLM ($Model): decidindo estratégia..." -NoNewline
        $llmResponse = Invoke-OllamaPlanner -PromptTemplate $promptTemplate `
                           -Metrics $metrics -Url $OllamaUrl -Model $Model
        $llmStrategy = [string]$llmResponse.strategy
        $llmReason   = [string]$llmResponse.reason
        Write-Host " LLM→ $llmStrategy"
    } catch {
        Write-Host " FALHA LLM: $_" -ForegroundColor Red
        $llmStrategy = 'cas.raw'
        $llmReason   = "Erro de comunicação: $($_.Exception.Message)"
    }

    # 5 — Vacina: verifica coerência matemática da estratégia
    $sanity        = Test-StrategyCoherence -Strategy $llmStrategy -Metrics $metrics
    $finalStrategy = if ($sanity.ok) { $llmStrategy } else {
        Write-Host "     [VACINA] $($sanity.reason) → fallback: $($sanity.fallback)" -ForegroundColor Magenta
        $sanity.fallback
    }
    $overridden = -not $sanity.ok

    # 6 — Montar recipe com parâmetros reais (nunca parâmetros do LLM)
    $recipe  = Build-Recipe -Strategy $finalStrategy -Metrics $metrics
    $verdict = Get-PlannerVerdict -Strategy $finalStrategy

    $verdictColor = if ($verdict -eq 'PROCEDURAL_CANDIDATE') { 'Green' }
                    elseif ($verdict -eq 'LZMA_PREFERRED')   { 'Yellow' }
                    else                                      { 'Gray' }
    Write-Host "     Final: $finalStrategy$(if ($overridden) { ' [OVERRIDDEN]' }) → $verdict" -ForegroundColor $verdictColor

    # 7 — Gravar candidate (atômico: .tmp → rename)
    $candidate = [ordered]@{
        version              = '0.19.4'
        analyzed_at          = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        file                 = $profile.file
        sha256               = $profile.sha256
        size_bytes           = $profile.size_bytes
        structural_profile   = $profile
        metrics              = $metrics
        llm_model            = $Model
        llm_strategy         = $llmStrategy
        llm_reason           = $llmReason
        sanity_check         = $sanity
        strategy_overridden  = $overridden
        final_strategy       = $finalStrategy
        recipe               = $recipe
        planner_verdict      = $verdict
    }

    $tmp = "$candidatePath.tmp"
    try {
        $json = $candidate | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($tmp, $json, [System.Text.Encoding]::UTF8)
        $verify = Get-Content $tmp -Raw | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $verify) { throw 'Verificação JSON do .tmp falhou' }
        Move-Item -LiteralPath $tmp -Destination $candidatePath -Force -ErrorAction Stop
        Write-Host "     Candidate gravado: $($profile.sha256.Substring(0,16))..."
        $totalOk++
    } catch {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        Write-Host "[NP] FALHA ao gravar candidate: $($file.Name) — $_" -ForegroundColor Red
        $totalFail++
    }
}

# ── relatório final ───────────────────────────────────────────────────────────

Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
Write-Host ' RELATÓRIO FINAL — TEIA-NeuroPlanner-v0194' -ForegroundColor Cyan
Write-Host $('=' * 70)

[object[]]$procCandidates = @($allProfiles | Where-Object { $_.period_bytes -gt 0 -or $_.unique_bytes -le 2 -or $_.entropy -lt 2.0 })
[object[]]$highEntropy    = @($allProfiles | Where-Object { $_.entropy -ge 7.0 })
[object[]]$medium         = @($allProfiles | Where-Object { $_.entropy -ge 2.0 -and $_.entropy -lt 7.0 -and $_.period_bytes -eq 0 -and $_.unique_bytes -gt 2 })

Write-Host ''
Write-Host " Arquivos analisados     : $($allProfiles.Count)"
Write-Host " Processados com sucesso : $totalOk"
Write-Host " Pulados (já existiam)   : $totalSkipped"
Write-Host " Falhas                  : $totalFail"
Write-Host ''
Write-Host ' [CLASSIFICAÇÃO ESTRUTURAL]'

if ($procCandidates.Count -gt 0) {
    Write-Host "`n  CANDIDATOS PROCEDURAIS ($($procCandidates.Count)):" -ForegroundColor Green
    foreach ($p in $procCandidates) {
        $why = if ($p.unique_bytes -le 1)    { "byte único e=$($p.entropy)" }
               elseif ($p.period_bytes -gt 0) { "período=$($p.period_bytes)B e=$($p.entropy)" }
               else                           { "e=$($p.entropy)" }
        Write-Host "    ✓ $($p.name) [$why]" -ForegroundColor Green
    }
}
if ($medium.Count -gt 0) {
    Write-Host "`n  LZMA/BROTLI ($($medium.Count)):" -ForegroundColor Yellow
    foreach ($p in $medium) {
        Write-Host "    ~ $($p.name) [e=$($p.entropy)]" -ForegroundColor Yellow
    }
}
if ($highEntropy.Count -gt 0) {
    Write-Host "`n  CAS_RAW / ALTA ENTROPIA ($($highEntropy.Count)):" -ForegroundColor Gray
    foreach ($p in $highEntropy) {
        Write-Host "    - $($p.name) [e=$($p.entropy) | $($p.magic_type)]" -ForegroundColor Gray
    }
}

Write-Host ''
if ($DryRun) {
    Write-Host ' MODO DRY-RUN: nenhum arquivo foi criado, movido ou apagado.' -ForegroundColor Yellow
} else {
    Write-Host " Candidates em: $OutputRoot" -ForegroundColor Green
}
Write-Host $('=' * 70)
