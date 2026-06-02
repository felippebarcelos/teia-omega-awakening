#Requires -Version 7
# TEIA-Cognitive-Router.ps1 — Roteador Cognitivo P40.0
# Aplica Honestidade Entropica ao custo de inferencia de IA.
# Analisa a Entropia Semantica de um prompt/tarefa (sem chamadas de rede)
# e emite veredito deterministico em milissegundos:
#   Local  (Edge/SLM)    — baixa entropia cognitiva
#   Hybrid (Mid-tier)    — entropia media
#   Cloud  (Frontier LLM) — alta entropia cognitiva
#
# Output: JSON canonico com score, veredito e projecao de economia GPU.
# Invariante: Write==Read — mesmo texto = mesmo JSON = mesmo SHA-256.
# Delta sempre por extenso (nunca simbolo matematico).
#
# Modelo de Entropia Semantica calibrado sobre quatro eixos:
#   token_score          (peso 0.20) — tamanho do contexto
#   vocab_diversity      (peso 0.15) — riqueza lexical
#   reasoning_verb_score (peso 0.30) — presenca de verbos de raciocinio
#   data_op_score        (peso 0.15) — presenca de operacoes de dados (reduz entropia)
#   structural_score     (peso 0.10) — profundidade estrutural (listas, codigo)
#   constraint_score     (peso 0.10) — densidade de restricoes logicas

[CmdletBinding()]
param(
    [string]$InputText   = '',
    [string]$InputFile   = '',
    [string]$OutputJson  = '',
    [double]$LocalThreshold  = 0.35,
    [double]$HybridThreshold = 0.65,
    [double]$GpuCostPerSecondUsd  = 0.002,
    [int]$CloudTokensPerSecond = 50,
    [int]$LocalTokensPerSecond = 5
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ─── Carregar texto de entrada ────────────────────────────────────────────────
if (![string]::IsNullOrEmpty($InputFile)) {
    if (!(Test-Path $InputFile)) { throw "Arquivo de entrada nao encontrado: $InputFile" }
    $InputText = [System.IO.File]::ReadAllText($InputFile, [System.Text.Encoding]::UTF8)
}
if ([string]::IsNullOrEmpty($InputText)) { throw "Forneça -InputText ou -InputFile." }

# ─── Tokenizacao e palavras ───────────────────────────────────────────────────
$charCount  = $InputText.Length
$tokenEst   = [int]($charCount / 4)
$textLower  = $InputText.ToLower()
$words      = @($textLower -split '[^a-záàâãéêíóôõúüçA-ZÁÀÂÃÉÊÍÓÔÕÚÜÇ0-9]+' |
                 Where-Object { $_.Length -gt 1 })
$wordCount  = [math]::Max(1, $words.Count)
$uniqueWords = @($words | Sort-Object -Unique)

# ─── Feature 1: Token score ───────────────────────────────────────────────────
# Satura em 4000 tokens (contexto tipico de frontier model)
$tokenScore = [math]::Round([math]::Min(1.0, $tokenEst / 4000.0), 4)

# ─── Feature 2: Diversidade de vocabulario ───────────────────────────────────
# Racio unico/total normalizado: 0.3 (repetitivo) -> 0.9 (maximamente diverso)
$uniqueRatio = [math]::Round($uniqueWords.Count / $wordCount, 4)
$vocabScore  = [math]::Round([math]::Max(0.0, [math]::Min(1.0, ($uniqueRatio - 0.3) / 0.6)), 4)

# ─── Feature 3: Verbos de raciocinio (maior peso — 0.30) ─────────────────────
$reasoningVerbs = @(
    'analyze','analyse','synthesize','synthesise','compare','evaluate','assess',
    'argue','explain','reason','consider','critique','design','architect',
    'hypothesize','investigate','interpret','infer','deduce','formulate',
    'justify','elaborate','contrast','differentiate','reconcile','extrapolate',
    'analisar','avaliar','comparar','sintetizar','explicar','argumentar',
    'considerar','raciocinar','deduzir','interpretar','investigar','justificar',
    'elaborar','contrastar','diferenciar','reconciliar','hipotetizar','extrapolar'
)
$reasoningCount = 0
foreach ($v in $reasoningVerbs) {
    if ($textLower.Contains($v)) { $reasoningCount++ }
}
$reasoningDensity = $reasoningCount / $wordCount
$reasoningScore   = [math]::Round([math]::Min(1.0, $reasoningDensity / 0.04), 4)

# ─── Feature 4: Verbos de operacao de dados (reduz entropia — inverted) ──────
$dataVerbs = @(
    'list','extract','format','convert','parse','count','find','get','show',
    'translate','summarize','summarise','filter','sort','map','join','split',
    'replace','rename','copy','move','delete','insert','append','merge',
    'listar','extrair','formatar','converter','contar','filtrar','ordenar',
    'traduzir','resumir','substituir','transformar','renomear','copiar','mover',
    'inserir','anexar','mesclar','dividir','combinar'
)
$dataCount = 0
foreach ($v in $dataVerbs) {
    if ($textLower.Contains($v)) { $dataCount++ }
}
$dataDensity = $dataCount / $wordCount
# Invertido: mais operacoes de dados = menor entropia cognitiva
$dataOpScore = [math]::Round([math]::Max(0.0, 1.0 - [math]::Min(1.0, $dataDensity / 0.04)), 4)

# ─── Feature 5: Complexidade estrutural ──────────────────────────────────────
$lineCount      = ($InputText -split "`n").Count
$codeBlocks     = ([regex]::Matches($InputText, '```')).Count / 2
$bulletPoints   = ([regex]::Matches($InputText, '(?m)^\s*[-*•]')).Count
$headerCount    = ([regex]::Matches($InputText, '(?m)^#+\s')).Count
$structureTotal = $codeBlocks * 3 + $bulletPoints * 0.5 + $headerCount * 1 + ($lineCount / 20)
$structureScore = [math]::Round([math]::Min(1.0, $structureTotal / 15.0), 4)

# ─── Feature 6: Densidade de restricoes logicas ───────────────────────────────
$constraintPhrases = @(
    ' but ',' however ',' although ',' unless ',' except ',' while ',' whereas ',
    ' despite ',' considering ',' assuming ',' given that ',' provided that ',
    ' on condition ',' in contrast ',' on the other hand ',
    ' mas ',' porém ',' entretanto ',' embora ',' a menos ',' exceto ',
    ' enquanto ',' dado que ',' considerando ',' supondo ',' desde que '
)
$constraintCount = 0
foreach ($p in $constraintPhrases) {
    $constraintCount += ([regex]::Matches($textLower, [regex]::Escape($p.Trim()))).Count
}
$questionCount    = ([regex]::Matches($InputText, '\?')).Count
$constraintTotal  = $constraintCount + $questionCount * 0.5
$constraintDensity = $constraintTotal / $wordCount
$constraintScore   = [math]::Round([math]::Min(1.0, $constraintDensity / 0.10), 4)

# ─── Score composto de Entropia Semantica ─────────────────────────────────────
# Pesos calibrados para maximizar separacao Local/Cloud:
#   reasoning_verb_score tem o maior peso (0.30) — discriminador principal
#   token_score = 0.20 — tamanho importa mas nao domina
#   data_op_score = 0.15 (inverted) — operacoes de dados puxam para Local
#   vocab_diversity = 0.15 — riqueza lexical indica sofisticacao
#   structural_score = 0.10 — estrutura rica indica tarefa complexa
#   constraint_score = 0.10 — restricoes logicas indicam raciocinio
$semanticEntropy = (
    0.20 * $tokenScore     +
    0.15 * $vocabScore     +
    0.30 * $reasoningScore +
    0.15 * $dataOpScore    +
    0.10 * $structureScore +
    0.10 * $constraintScore
)
$semanticEntropy = [math]::Round([math]::Max(0.0, [math]::Min(1.0, $semanticEntropy)), 4)

# ─── Veredito de roteamento ───────────────────────────────────────────────────
$route = if ($semanticEntropy -lt $LocalThreshold) {
    'Local'
} elseif ($semanticEntropy -lt $HybridThreshold) {
    'Hybrid'
} else {
    'Cloud'
}

# Confianca: baixa quando proximo das bordas dos thresholds
$distToLocalBound  = [math]::Abs($semanticEntropy - $LocalThreshold)
$distToHybridBound = [math]::Abs($semanticEntropy - $HybridThreshold)
$minDist           = [math]::Min($distToLocalBound, $distToHybridBound)
$confidence = if ($minDist -gt 0.12) { 'high' } elseif ($minDist -gt 0.05) { 'medium' } else { 'low' }

# Rationale baseado nos features dominantes
$dominantFeatures = [System.Collections.Generic.List[string]]::new()
if ($tokenScore -gt 0.4)     { $dominantFeatures.Add("contexto longo ($tokenEst tokens est.)") }
if ($reasoningScore -gt 0.4) { $dominantFeatures.Add("verbos de raciocinio presentes ($reasoningCount)") }
if ($dataOpScore -lt 0.3)    { $dominantFeatures.Add("tarefa dominada por operacoes de dados ($dataCount)") }
if ($structureScore -gt 0.4) { $dominantFeatures.Add("estrutura rica ($codeBlocks blocos, $bulletPoints bullets)") }
if ($constraintScore -gt 0.4){ $dominantFeatures.Add("alta densidade de restricoes logicas ($constraintCount)") }
if ($dominantFeatures.Count -eq 0) { $dominantFeatures.Add("entropia moderada sem dominante claro") }
$rationale = $dominantFeatures -join '; '

# ─── Projecao de economia GPU ────────────────────────────────────────────────
$outputTokensEst      = [int]($tokenEst * 0.5)
$cloudGpuSecondsEst   = [math]::Round($outputTokensEst / $CloudTokensPerSecond, 3)
$localCpuSecondsEst   = [math]::Round($outputTokensEst / $LocalTokensPerSecond, 3)

# delta_gpu_seconds = GPU-segundos poupados ao evitar o modelo de fronteira
$deltaGpuSeconds = if ($route -eq 'Cloud') { 0.0 } else { $cloudGpuSecondsEst }
$deltaUsd        = [math]::Round($deltaGpuSeconds * $GpuCostPerSecondUsd, 6)
$modelAvoided    = switch ($route) {
    'Local'  { 'Frontier LLM (GPT-4/Claude-Opus) — nao ativado' }
    'Hybrid' { 'Frontier LLM (GPT-4/Claude-Opus) — nao ativado; quantizado suficiente' }
    'Cloud'  { 'Nenhum — complexidade exige modelo de fronteira' }
}

# ─── Construir JSON canonico ─────────────────────────────────────────────────
$result = [ordered]@{
    router_version           = '1.0'
    protocol                 = 'P40.0'
    input_char_count         = $charCount
    input_token_estimate     = $tokenEst
    input_word_count         = $wordCount
    semantic_entropy_score   = $semanticEntropy
    routing_decision         = $route
    routing_confidence       = $confidence
    routing_rationale        = $rationale
    entropy_features         = [ordered]@{
        token_score              = $tokenScore
        vocab_diversity_score    = $vocabScore
        reasoning_verb_score     = $reasoningScore
        data_operation_score     = $dataOpScore
        structural_complexity    = $structureScore
        constraint_density_score = $constraintScore
    }
    feature_weights          = [ordered]@{
        token_score              = 0.20
        vocab_diversity_score    = 0.15
        reasoning_verb_score     = 0.30
        data_operation_score     = 0.15
        structural_complexity    = 0.10
        constraint_density_score = 0.10
    }
    thresholds               = [ordered]@{
        local_max  = $LocalThreshold
        hybrid_max = $HybridThreshold
    }
    gpu_economics            = [ordered]@{
        output_tokens_estimate      = $outputTokensEst
        cloud_gpu_seconds_estimate  = $cloudGpuSecondsEst
        local_cpu_seconds_estimate  = $localCpuSecondsEst
        delta_gpu_seconds_saved     = $deltaGpuSeconds
        delta_usd_saved             = $deltaUsd
        gpu_cost_per_second_usd     = $GpuCostPerSecondUsd
        model_avoided               = $modelAvoided
    }
    routing_map              = [ordered]@{
        Local  = 'SLM 1-7B ou script puro (CPU inference, zero GPU-seconds)'
        Hybrid = 'Modelo quantizado 13-34B (footprint GPU reduzido)'
        Cloud  = 'Frontier LLM GPT-4/Claude-Opus (inferencia GPU completa)'
    }
    calibration_note = 'Modelo heuristico P40.0. Sem chamadas de rede. Delta por extenso.'
}

$jsonOut = $result | ConvertTo-Json -Depth 6

# ─── Saida ────────────────────────────────────────────────────────────────────
if ([string]::IsNullOrEmpty($OutputJson)) {
    Write-Output $jsonOut
} else {
    [System.IO.File]::WriteAllText($OutputJson, $jsonOut, [System.Text.Encoding]::UTF8)
    $hash  = (Get-FileHash $OutputJson -Algorithm SHA256).Hash.ToLower()
    $rColor = switch ($route) { 'Local' {'Green'} 'Hybrid' {'Yellow'} 'Cloud' {'Red'} }

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '  TEIA Cognitive Router — P40.0'                              -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ("  Tokens (est.)  : {0}"     -f $tokenEst)                    -ForegroundColor White
    Write-Host ("  Entropia Sem.  : {0:F4}" -f $semanticEntropy)              -ForegroundColor White
    Write-Host ''
    Write-Host ("  VEREDITO       : {0}"     -f $route) -ForegroundColor $rColor
    Write-Host ("  Confianca      : {0}"     -f $confidence)                  -ForegroundColor White
    Write-Host ("  Racional       : {0}"     -f $rationale)                   -ForegroundColor DarkGray
    Write-Host ''
    Write-Host ("  GPU delta poup.: {0} s   ({1:F6} USD)" -f $deltaGpuSeconds, $deltaUsd) -ForegroundColor Green
    Write-Host ("  Modelo evitado : {0}"     -f $modelAvoided)                -ForegroundColor DarkGray
    Write-Host ''
    Write-Host ("  JSON           : {0}"     -f $OutputJson)                  -ForegroundColor White
    Write-Host ("  SHA-256        : {0}"     -f $hash)                        -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
}
