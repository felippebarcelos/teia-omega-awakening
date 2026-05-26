<#
.SYNOPSIS
    Pontuar-Convergencia.ps1 — Gera tabela vazia de pontuação D1-D5 a partir
    das respostas brutas coletadas em respostas_raw/.

.DESCRIPTION
    Lê arquivos .md em respostas_raw/A_TECNICO, B_TEIA e C_NEUTRO.
    Para cada arquivo encontrado, imprime um bloco de pontuação manual vazio.
    Não calcula médias, conclusões nem hipóteses.

.PARAMETER RootDir
    Diretório raiz de blind_tests. Padrão: D:\TEIA_CORE\blind_tests

.PARAMETER Saida
    Caminho do arquivo de saída. Se omitido, imprime no console.

.EXAMPLE
    .\Pontuar-Convergencia.ps1
    .\Pontuar-Convergencia.ps1 -Saida "D:\TEIA_CORE\blind_tests\pontuacoes_rascunho.md"
#>
[CmdletBinding()]
param(
    [string]$RootDir = 'D:\TEIA_CORE\blind_tests',
    [string]$Saida   = ''
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'

$RawRoot = Join-Path $RootDir 'respostas_raw'
$Pacotes = @('A_TECNICO', 'B_TEIA', 'C_NEUTRO')

$linhas = [System.Collections.Generic.List[string]]::new()

function Add-Linha { param([string]$L) $linhas.Add($L) }

Add-Linha "# PONTUAÇÃO D1–D5 — TESTE DE CONVERGÊNCIA v0.15.0"
Add-Linha "**Gerado em:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Add-Linha "**Instrução:** preencher cada campo manualmente (0–5). Ver rubrica em avaliacao_convergencia.json."
Add-Linha ""
Add-Linha "---"
Add-Linha ""

$sessoes = [System.Collections.Generic.List[object]]::new()

foreach ($pacote in $Pacotes) {
    $dir = Join-Path $RawRoot $pacote
    if (-not (Test-Path $dir)) {
        Add-Linha "## $pacote"
        Add-Linha "> Pasta não encontrada: $dir"
        Add-Linha ""
        continue
    }

    $arquivos = Get-ChildItem $dir -Filter '*.md' -File -ErrorAction SilentlyContinue |
                Sort-Object Name

    Add-Linha "## Pacote $pacote"
    Add-Linha ""

    if (-not $arquivos) {
        Add-Linha "> Nenhum arquivo .md encontrado. Cole as respostas brutas aqui antes de pontuar."
        Add-Linha ""
        continue
    }

    foreach ($arq in $arquivos) {
        $modelo = [System.IO.Path]::GetFileNameWithoutExtension($arq.Name)
        $sessaoId = "$pacote x $modelo"

        Add-Linha "### $sessaoId"
        Add-Linha "**Arquivo:** ``$($arq.FullName)``"
        Add-Linha "**Tamanho:** $($arq.Length) bytes"
        Add-Linha ""

        # Detectar se o arquivo segue o template (seções P1–P4)
        $conteudo = Get-Content $arq.FullName -Raw -ErrorAction SilentlyContinue
        $temP1    = $conteudo -match '##\s*P1'
        $temP2    = $conteudo -match '##\s*P2'
        $temP3    = $conteudo -match '##\s*P3'
        $temP4    = $conteudo -match '##\s*P4'
        $secoes   = @('P1','P2','P3','P4') | Where-Object {
            switch ($_) {
                'P1' { $temP1 } 'P2' { $temP2 } 'P3' { $temP3 } 'P4' { $temP4 }
            }
        }
        $statusSecoes = if ($secoes.Count -eq 4) { "✅ P1 P2 P3 P4 presentes" } `
                        else { "⚠️  Seções detectadas: $($secoes -join ', ') — verifique o template" }
        Add-Linha "**Estrutura:** $statusSecoes"
        Add-Linha ""

        # Tabela de pontuação vazia
        Add-Linha "| Dimensão | Descrição resumida | Score (0–5) | Notas |"
        Add-Linha "|----------|--------------------|:-----------:|-------|"
        Add-Linha "| D1 | Convergência terminológica | | |"
        Add-Linha "| D2 | Preservação de invariantes | | |"
        Add-Linha "| D3 | Tendência a personificar   | | |"
        Add-Linha "| D4 | Qualidade técnica          | | |"
        Add-Linha "| D5 | Deriva narrativa           | | |"
        Add-Linha ""
        Add-Linha "**P4 — opção escolhida pelo modelo:** [ ] a  [ ] b  [ ] c  [ ] indefinida"
        Add-Linha ""
        Add-Linha "**Termos externos introduzidos:** _(listar aqui)_"
        Add-Linha ""
        Add-Linha "**Invariantes identificados:** _(listar aqui — max 7)_"
        Add-Linha ""
        Add-Linha "---"
        Add-Linha ""

        $sessoes.Add([PSCustomObject]@{
            Pacote  = $pacote
            Modelo  = $modelo
            Arquivo = $arq.FullName
        })
    }
}

# Sumário de sessões encontradas
Add-Linha "## SUMÁRIO DE SESSÕES ENCONTRADAS"
Add-Linha ""
if ($sessoes.Count -eq 0) {
    Add-Linha "> Nenhuma resposta bruta encontrada. Adicione arquivos .md em respostas_raw/A_TECNICO/, B_TEIA/ ou C_NEUTRO/."
} else {
    Add-Linha "| # | Pacote | Modelo | Arquivo |"
    Add-Linha "|---|--------|--------|---------|"
    $i = 1
    foreach ($s in $sessoes) {
        Add-Linha "| $i | $($s.Pacote) | $($s.Modelo) | ``$(Split-Path $s.Arquivo -Leaf)`` |"
        $i++
    }
    Add-Linha ""
    Add-Linha "**Total encontrado:** $($sessoes.Count) / 15 sessões esperadas"
}
Add-Linha ""
Add-Linha "---"
Add-Linha "_Gerado por Pontuar-Convergencia.ps1 — sem cálculo automático de conclusões._"

# Saída
$texto = $linhas -join "`n"

if ($Saida) {
    Set-Content -LiteralPath $Saida -Value $texto -Encoding UTF8 -ErrorAction Stop
    Write-Host "[PC] Tabela salva em: $Saida"
    Write-Host "[PC] Sessões encontradas: $($sessoes.Count)"
} else {
    Write-Output $texto
}
