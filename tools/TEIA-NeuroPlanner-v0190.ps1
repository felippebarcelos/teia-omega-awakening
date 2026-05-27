<#
.SYNOPSIS
    TEIA-NeuroPlanner-v0190.ps1 — Analisador estrutural neuro-simbólico

.DESCRIPTION
    Analisa arquivos, gera perfis estruturais e consulta um LLM local (Ollama)
    para propor recipes procedurais. Nunca escreve no CAS. Nunca move arquivos.
    Em modo DryRun, executa apenas a análise estrutural (sem LLM, sem escrita).

.PARAMETER Files
    Caminhos dos arquivos a analisar. Aceita pipeline de Get-ChildItem.

.PARAMETER OllamaUrl
    Endpoint da API Ollama. Padrão: http://localhost:11434/api/generate

.PARAMETER Model
    Modelo Ollama a usar. Padrão: deepseek-r1:1.5b

.PARAMETER OutputRoot
    Diretório para salvar os candidates. Padrão: D:\TEIA_CORE\neuroplanner\candidates

.PARAMETER PromptTemplatePath
    Caminho do prompt canônico. Padrão: D:\TEIA_CORE\config\neuroplanner_prompt_v0190.md

.PARAMETER EntropySampleBytes
    Tamanho da amostra para cálculo de entropia. Padrão: 524288 (512 KB)

.PARAMETER DryRun
    Executa apenas a análise estrutural; não chama LLM e não grava candidates.

.EXAMPLE
    .\TEIA-NeuroPlanner-v0190.ps1 -Files "D:\TEIA_CORE\seeds\*.json" -DryRun
    Get-ChildItem D:\TEIA_USER\Inbox -File | .\TEIA-NeuroPlanner-v0190.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string[]]$Files,

    [string]$OllamaUrl            = 'http://localhost:11434/api/generate',
    [string]$Model                = 'deepseek-r1:1.5b',
    [string]$OutputRoot           = 'D:\TEIA_CORE\neuroplanner\candidates',
    [string]$PromptTemplatePath   = 'D:\TEIA_CORE\config\neuroplanner_prompt_v0190.md',
    [int]   $EntropySampleBytes   = 524288,
    [switch]$DryRun
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ── helpers ──────────────────────────────────────────────────────────────────

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

function Get-StringsSample([byte[]]$b, [int]$minLen = 8, [int]$maxResults = 20) {
    $results = [System.Collections.Generic.List[string]]::new()
    $cur     = [System.Text.StringBuilder]::new()
    $limit   = [Math]::Min(65536, $b.Length)
    for ($i = 0; $i -lt $limit -and $results.Count -lt $maxResults; $i++) {
        $byte = $b[$i]
        if ($byte -ge 0x20 -and $byte -le 0x7E) {
            [void]$cur.Append([char]$byte)
        } else {
            if ($cur.Length -ge $minLen) {
                $s = $cur.ToString()
                if (-not $results.Contains($s)) { $results.Add($s) }
            }
            [void]$cur.Clear()
        }
    }
    if ($cur.Length -ge $minLen -and -not $results.Contains($cur.ToString())) {
        $results.Add($cur.ToString())
    }
    $results.ToArray()
}

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

function Invoke-OllamaPlanner {
    param(
        [string]$PromptTemplate,
        [object]$Profile,
        [string]$Url,
        [string]$Model
    )

    $profileJson = $Profile | ConvertTo-Json -Depth 6 -Compress
    $fullPrompt  = $PromptTemplate -replace '\{\{STRUCTURAL_PROFILE\}\}', $profileJson

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
        return $llmText | ConvertFrom-Json -ErrorAction Stop
    } catch {
        return [ordered]@{
            candidate         = $false
            reason            = "LLM retornou JSON inválido: $($_.Exception.Message)"
            proposed_strategy = 'fallback: cas.raw'
            recipe            = @{}
            risk              = 'high'
        }
    }
}

function Get-PlannerVerdict([object]$Profile, [object]$LlmResponse) {
    if ($null -eq $LlmResponse -or $LlmResponse.candidate -eq $false) {
        return 'CAS_RAW'
    }
    $strategy = [string]$LlmResponse.proposed_strategy
    if ($strategy -match 'cas\.raw|fallback') { return 'CAS_RAW' }
    if ($strategy -match 'cmp\.lzma|cmp\.brotli') { return 'LZMA_PREFERRED' }
    return 'PROCEDURAL_CANDIDATE'
}

# ── begin ─────────────────────────────────────────────────────────────────────

$banner = @"
======================================================================
 [TCT/NEUROPLANNER_v0190] TEIA-NeuroPlanner-v0190.ps1
 Modo    : $(if ($DryRun) { 'DRY-RUN (read-only — sem LLM, sem escrita)' } else { 'ATIVO (análise + LLM + candidates)' })
 Modelo  : $Model
 Output  : $OutputRoot
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
        Write-Host "       Execute primeiro para criar o prompt, ou use -DryRun." -ForegroundColor Yellow
        exit 1
    }
    $promptTemplate = Get-Content $PromptTemplatePath -Raw -Encoding UTF8
}

$allProfiles   = [System.Collections.Generic.List[object]]::new()
$totalOk       = 0
$totalFail     = 0
$totalSkipped  = 0

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
        Write-Host "     Magic      : $($profile.magic_type)"
        Write-Host "     Estrutura  : $($profile.structure_type)"
        Write-Host "     Entropia   : $($profile.entropy) / 8.0 bits/byte"
        Write-Host "     Bytes únicos: $($profile.unique_bytes) / 256"
        Write-Host "     Período    : $(if ($profile.period_bytes -gt 0) { "$($profile.period_bytes)B detectado" } else { 'nenhum' })"
        Write-Host "     Runs       : $($profile.runs.runs) runs · max=$($profile.runs.maxRun)B · avg=$($profile.runs.avgRunLen)B"
    } catch {
        Write-Host "[NP] FALHA ao analisar: $($file.Name) — $_" -ForegroundColor Red
        $totalFail++
        continue
    }

    $null = $allProfiles.Add($profile)

    # 2 — DRY-RUN: guarda que bloqueia LLM e escrita
    if ($DryRun) {
        Write-Host "     [DRY-RUN] Modo Read-Only — LLM e escrita omitidos para este arquivo."
        $totalOk++
        continue
    }

    # 3 — Idempotência: candidate já existe?
    $candidatePath = Join-Path $OutputRoot "$($profile.sha256).candidate.json"
    if (Test-Path $candidatePath) {
        Write-Host "     [SKIP] Candidate já existe: $($profile.sha256.Substring(0,16))..."
        $totalSkipped++
        continue
    }

    # 4 — Consulta ao LLM local (Ollama)
    $llmResponse = $null
    try {
        Write-Host "     Consultando LLM ($Model)..." -NoNewline
        $llmResponse = Invoke-OllamaPlanner -PromptTemplate $promptTemplate `
                           -Profile $profile -Url $OllamaUrl -Model $Model
        $verdict     = Get-PlannerVerdict -Profile $profile -LlmResponse $llmResponse
        $verdictColor = if ($verdict -eq 'PROCEDURAL_CANDIDATE') { 'Green' }
                        elseif ($verdict -eq 'LZMA_PREFERRED')   { 'Yellow' }
                        else                                      { 'Gray' }
        Write-Host " $verdict" -ForegroundColor $verdictColor
    } catch {
        Write-Host " FALHA LLM: $_" -ForegroundColor Red
        $llmResponse = [ordered]@{
            candidate         = $false
            reason            = "Erro de comunicação com Ollama: $($_.Exception.Message)"
            proposed_strategy = 'fallback: cas.raw'
            recipe            = @{}
            risk              = 'high'
        }
        $verdict = 'CAS_RAW'
    }

    # 5 — Gravar candidate (atômico: .tmp → rename)
    $candidate = [ordered]@{
        version            = '0.19.0'
        analyzed_at        = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        file               = $profile.file
        sha256             = $profile.sha256
        size_bytes         = $profile.size_bytes
        structural_profile = $profile
        llm_model          = $Model
        llm_response       = $llmResponse
        planner_verdict    = $verdict
    }

    $tmp = "$candidatePath.tmp"
    try {
        $json = $candidate | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($tmp, $json, [System.Text.Encoding]::UTF8)
        $verify = Get-Content $tmp -Raw | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $verify) { throw "Verificação JSON do .tmp falhou" }
        Move-Item -LiteralPath $tmp -Destination $candidatePath -Force -ErrorAction Stop
        Write-Host "     Candidate gravado: $($profile.sha256.Substring(0,16))..."
        $totalOk++
    } catch {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        Write-Host "[NP] FALHA ao gravar candidate: $($file.Name) — $_" -ForegroundColor Red
        $totalFail++
    }
}

# ── end: relatório ────────────────────────────────────────────────────────────

Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
Write-Host ' RELATÓRIO FINAL — TEIA-NeuroPlanner-v0190' -ForegroundColor Cyan
Write-Host $('=' * 70)

$totalAnalyzed = $allProfiles.Count
# @() força array — evita que Where-Object com 1 resultado retorne hashtable solta
# cujo .Count seria número de chaves (16) em vez do número de itens (1)
[object[]]$candidates   = @($allProfiles | Where-Object { $_.period_bytes -gt 0 -or $_.unique_bytes -le 2 -or $_.entropy -lt 2.0 })
[object[]]$highEntropy  = @($allProfiles | Where-Object { $_.entropy -ge 7.0 })
[object[]]$medium       = @($allProfiles | Where-Object { $_.entropy -ge 2.0 -and $_.entropy -lt 7.0 -and $_.period_bytes -eq 0 -and $_.unique_bytes -gt 2 })

Write-Host ''
Write-Host " Arquivos analisados     : $totalAnalyzed"
Write-Host " Processados com sucesso : $totalOk"
Write-Host " Pulados (já existiam)   : $totalSkipped"
Write-Host " Falhas                  : $totalFail"
Write-Host ''
Write-Host ' [CLASSIFICAÇÃO ESTRUTURAL]'

if ($candidates.Count -gt 0) {
    Write-Host "`n  CANDIDATOS A PROCEDURAL ($($candidates.Count)):" -ForegroundColor Green
    foreach ($p in $candidates) {
        $reason = if ($p.unique_bytes -le 1)     { "byte único" }
                  elseif ($p.period_bytes -gt 0)  { "período=$($p.period_bytes)B" }
                  elseif ($p.entropy -lt 2.0)      { "entropia=$($p.entropy)" }
                  else { "baixa entropia" }
        Write-Host "    ✓ $($p.name) [$reason | e=$($p.entropy) | $($p.magic_type)]" -ForegroundColor Green
    }
}

if ($medium.Count -gt 0) {
    Write-Host "`n  LZMA/BROTLI PREFERÍVEL ($($medium.Count)):" -ForegroundColor Yellow
    foreach ($p in $medium) {
        Write-Host "    ~ $($p.name) [e=$($p.entropy) | $($p.magic_type)]" -ForegroundColor Yellow
    }
}

if ($highEntropy.Count -gt 0) {
    Write-Host "`n  CAS BRUTO / ALTA ENTROPIA ($($highEntropy.Count)):" -ForegroundColor Gray
    foreach ($p in $highEntropy) {
        Write-Host "    - $($p.name) [e=$($p.entropy) | $($p.magic_type)]" -ForegroundColor Gray
    }
}

Write-Host ''
if ($DryRun) {
    Write-Host ' MODO DRY-RUN: nenhum arquivo foi criado, movido ou apagado.' -ForegroundColor Yellow
} else {
    Write-Host " Candidates gravados em: $OutputRoot" -ForegroundColor Green
}
Write-Host $('=' * 70)
