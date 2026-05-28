<#
.SYNOPSIS
    Test-ObjHypothesis-v0211.ps1 — Validador de Hipóteses Pattern Hunter (OBJ/3D)

.DESCRIPTION
    Lê um arquivo {sha256}_{model}_theory.md gerado pelo Pattern Hunter e aplica
    critérios de aprovação semântica por Regex para determinar se o LLM produziu
    uma hipótese ontoprocedural válida (com raciocínio geométrico/paramétrico)
    ou uma alucinação de domínio (confundiu o arquivo com outro tipo).

    Critérios (para arquivos model/obj):
      C1 — VOCABULÁRIO_GEOMETRICO : teoria menciona OBJ, malha, vértice, 3D, geometria, mesh, topologia
      C2 — AUSENCIA_ALUCINACAO    : teoria NÃO menciona JPEG, fotografia, DCT de imagem, codec de vídeo
      C3 — HR6_PARAMETRICA        : teoria propõe HR6 com modelagem matemática/paramétrica (não dicionário)

    Saída:
      PASS — todos os critérios aprovados → hipótese válida para análise humana
      FAIL — um ou mais critérios reprovados → hipótese inválida, requer re-run com modelo superior

.PARAMETER TheoryFile
    Caminho para o arquivo _theory.md a validar.

.PARAMETER ExpectedType
    Tipo de arquivo esperado para calibrar os critérios. Padrão: 'model/obj'

.EXAMPLE
    .\Test-ObjHypothesis-v0211.ps1 -TheoryFile "D:\TEIA_CORE\neuroplanner\hypotheses\abc..._qwen2.5-coder_7b_theory.md"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TheoryFile,

    [string]$ExpectedType = 'model/obj'
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ── critérios configuráveis por tipo de arquivo ──────────────────────────────

$criteria = @{
    'model/obj' = [ordered]@{
        C1 = [ordered]@{
            id      = 'VOCABULARIO_GEOMETRICO'
            desc    = 'Teoria menciona vocabulário geométrico/3D relevante'
            pattern = '(?i)(OBJ|\bmalha\b|\bv[eé]rtic[e|es]\b|v[eé]rtex|vertices|\b3D\b|geometri|topologi|\bmesh\b|poligon|polygon|tri[aâ]ngul|modelo\s+3|faceta|face\s+index)'
            expect  = $true
        }
        C2 = [ordered]@{
            id      = 'AUSENCIA_ALUCINACAO'
            desc    = 'Teoria NÃO menciona domínios errados (JPEG/vídeo/fotografia)'
            pattern = '(?i)(JPEG|image/jpeg|\bJPG\b|fotografi|fotografo|HEVC|DCT\s+de\s+imagem|codec\s+de\s+v[ií]deo|inter.frame|I-frame|P-frame|HEIC|PNG\b|bitmap|pixel\s+values?\s*=)'
            expect  = $false
        }
        C3 = [ordered]@{
            id      = 'HR6_PARAMETRICA'
            desc    = 'Teoria propõe HR6 com modelagem paramétrica/matemática (não dicionário)'
            pattern = '(?i)(HR6|Hard\s+Rule\s+6|gen\.[a-z_]+|opcode.*gen|param[eé]tric|modelo\s+matem[aá]|fun[çc][aã]o\s+param|topologi|vértice.*fun|fun[çc][aã]o.*vért|esfer[ao].*f\(|cubo.*f\(|bbox|bounding.box|coord.*min.*max|AABB)'
            expect  = $true
        }
    }
}

# ── validação ─────────────────────────────────────────────────────────────────

Write-Host @"
======================================================================
 [VALIDATOR_v0211] Test-ObjHypothesis-v0211.ps1
 Arquivo : $TheoryFile
 Tipo    : $ExpectedType
======================================================================
"@ -ForegroundColor Cyan

if (-not (Test-Path $TheoryFile)) {
    Write-Host "[VAL] ERRO: arquivo nao encontrado: $TheoryFile" -ForegroundColor Red; exit 1
}

$text = Get-Content -LiteralPath $TheoryFile -Raw -Encoding UTF8

# Extrair apenas a seção de hipótese (entre "## Hipotese LLM" e "## Prompt Enviado")
$llmSection = $text
if ($text -match '(?s)## Hipot[eé]se LLM.*?\n(.*?)\n---\n\s*## Prompt Enviado') {
    $llmSection = $matches[1]
    Write-Host " Secao LLM extraida: $($llmSection.Length) chars" -ForegroundColor White
} else {
    Write-Host " [AVISO] Nao foi possivel isolar secao LLM — analisando documento completo" -ForegroundColor DarkYellow
}

# Metadados do arquivo
$modelLine = ($text -split "`n" | Where-Object { $_ -match '\*\*Modelo LLM\*\*' } | Select-Object -First 1)
$sha256Line = ($text -split "`n" | Where-Object { $_ -match 'SHA-256' -and $_ -notmatch '##' } | Select-Object -First 1)
Write-Host " $modelLine"
Write-Host " $sha256Line"
Write-Host ''

# Aplicar critérios
if (-not $criteria.ContainsKey($ExpectedType)) {
    Write-Host "[VAL] AVISO: nenhum critério configurado para tipo '$ExpectedType' — usando model/obj" -ForegroundColor DarkYellow
    $ExpectedType = 'model/obj'
}

$ruleset    = $criteria[$ExpectedType]
$results    = [System.Collections.Generic.List[object]]::new()
$allPass    = $true

Write-Host (' {0,-28} {1,-10} {2}' -f 'Critério', 'Resultado', 'Detalhe') -ForegroundColor White
Write-Host (' {0,-28} {1,-10} {2}' -f ('-'*28), ('-'*10), ('-'*40))

foreach ($key in $ruleset.Keys) {
    $rule    = $ruleset[$key]
    $matched = [bool]($llmSection -match $rule.pattern)
    $pass    = ($matched -eq $rule.expect)

    if (-not $pass) { $allPass = $false }

    $verdict = if ($pass) { 'PASS' } else { 'FAIL' }
    $color   = if ($pass) { 'Green' } else { 'Red' }

    # Encontrar trecho que casou (ou não) para evidência
    $evidence = ''
    if ($matched) {
        if ($llmSection -match $rule.pattern) {
            $ev = $matches[0]
            if ($ev.Length -gt 60) { $ev = $ev.Substring(0,60) + '...' }
            $evidence = "match=`"$ev`""
        }
    } else {
        $evidence = '(nenhum match)'
    }

    Write-Host (' {0,-28} {1,-10} {2}' -f $rule.id, $verdict, $evidence) -ForegroundColor $color

    $null = $results.Add([ordered]@{
        criterion = $rule.id
        desc      = $rule.desc
        pattern   = $rule.pattern
        matched   = $matched
        expected  = $rule.expect
        pass      = $pass
        evidence  = $evidence
    })
}

Write-Host ''
$overallColor  = if ($allPass) { 'Green' } else { 'Red' }
$overallVerdict = if ($allPass) { 'PASS — hipotese valida para analise humana' } else { 'FAIL — hipotese invalida, re-run com modelo superior' }
Write-Host (" VEREDICTO FINAL: $overallVerdict") -ForegroundColor $overallColor
Write-Host ('=' * 70) -ForegroundColor Cyan

# Retornar objeto estruturado para uso programático
[pscustomobject]@{
    theory_file     = $TheoryFile
    expected_type   = $ExpectedType
    overall_pass    = $allPass
    criteria_results = $results.ToArray()
}
