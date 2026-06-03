#Requires -Version 5.1
<#
.SYNOPSIS
    Compila docs/teia_arxiv_paper.tex para PDF.
    Se pdflatex nao estiver disponivel, exibe instrucoes para Overleaf
    e exporta docs/TEIA_WHITEPAPER_FINAL.md identico ao LaTeX.

.EXAMPLE
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    .\compile_whitepaper.ps1
#>

[CmdletBinding()]
param()

$Root    = "D:\TEIA_CLAUDE_AWAKENING"
$TexFile = Join-Path $Root "docs\teia_arxiv_paper.tex"
$DocsDir = Join-Path $Root "docs"
$PdfOut  = Join-Path $DocsDir "teia_whitepaper.pdf"
$MdFinal = Join-Path $DocsDir "TEIA_WHITEPAPER_FINAL.md"

function Write-Banner {
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "  TEIA Whitepaper Compiler — P52.0" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host ""
}

function Copy-MarkdownFinal {
    $src = Join-Path $DocsDir "TEIA_WHITEPAPER_DRAFT.md"
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $MdFinal -Force
        $hash = (Get-FileHash $MdFinal -Algorithm SHA256).Hash.ToLower()
        Write-Host "  TEIA_WHITEPAPER_FINAL.md exportado." -ForegroundColor Green
        Write-Host "  SHA-256: $hash"
        Write-Host "  Caminho: $MdFinal"
    } else {
        Write-Host "  AVISO: TEIA_WHITEPAPER_DRAFT.md nao encontrado." -ForegroundColor Yellow
    }
}

function Show-OverleafInstructions {
    Write-Host ""
    Write-Host "  pdflatex NAO encontrado neste sistema." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  OPCAO A — Overleaf (recomendado, gratuito):" -ForegroundColor White
    Write-Host "    1. Acesse https://overleaf.com e crie uma conta gratuita."
    Write-Host "    2. Clique em 'New Project' -> 'Upload Project'."
    Write-Host "    3. Faca upload do arquivo:"
    Write-Host "       $TexFile" -ForegroundColor Cyan
    Write-Host "    4. Clique em 'Recompile'. O PDF sera gerado automaticamente."
    Write-Host "    5. Clique em 'Download PDF' -> salve como teia_whitepaper.pdf."
    Write-Host ""
    Write-Host "  OPCAO B — Instalar MiKTeX (Windows, gratuito):" -ForegroundColor White
    Write-Host "    1. Baixe em https://miktex.org/download"
    Write-Host "    2. Instale com opcao 'Install missing packages on-the-fly'"
    Write-Host "    3. Execute novamente este script."
    Write-Host ""
    Write-Host "  OPCAO C — Instalar TeX Live (Windows):" -ForegroundColor White
    Write-Host "    winget install --id TeXLive.TeXLive"
    Write-Host "    (requer ~4GB de espaco em disco)"
    Write-Host ""
}

function Show-ZenodoInstructions {
    Write-Host ""
    Write-Host "  COMO OBTER DOI GRATUITO VIA ZENODO:" -ForegroundColor Cyan
    Write-Host "  ============================================="
    Write-Host ""
    Write-Host "  1. Acesse https://zenodo.org e crie uma conta (gratuita)."
    Write-Host "     (pode usar sua conta GitHub para login)"
    Write-Host ""
    Write-Host "  2. Clique em 'New Upload'."
    Write-Host ""
    Write-Host "  3. Faca upload dos seguintes arquivos:"
    Write-Host "     - teia_whitepaper.pdf (o PDF compilado)"
    Write-Host "     - teia_arxiv_paper.tex (o LaTeX fonte)"
    Write-Host "     - TEIA_WHITEPAPER_FINAL.md (versao Markdown)"
    Write-Host ""
    Write-Host "  4. Preencha os metadados:"
    Write-Host "     Title  : Deterministic and Auditable Routing for"
    Write-Host "              Artificial Intelligence in Regulated Environments"
    Write-Host "     Authors: Felippe Barcelos"
    Write-Host "     Type   : Publication -> Preprint"
    Write-Host "     License: Creative Commons Attribution 4.0 (CC BY 4.0)"
    Write-Host "     Keywords: LLM routing, compliance, determinism, audit, EU AI Act"
    Write-Host ""
    Write-Host "  5. Clique em 'Publish'. O DOI sera emitido em menos de 1 minuto."
    Write-Host "     Formato: https://doi.org/10.5281/zenodo.XXXXXXX"
    Write-Host ""
    Write-Host "  6. Adicione o DOI no README do GitHub e no PyPI."
    Write-Host ""
    Write-Host "  NOTA: O Zenodo e indexado pelo Google Scholar, OpenAIRE e"
    Write-Host "  BASE (Bielefeld Academic Search Engine). O artigo sera"
    Write-Host "  descoberto por pesquisadores de IA e compliance mundialmente."
    Write-Host ""
}

# ── Main ──────────────────────────────────────────────────────────────────────

Write-Banner

if (-not (Test-Path $TexFile)) {
    Write-Host "  ERRO: arquivo .tex nao encontrado: $TexFile" -ForegroundColor Red
    exit 1
}

Write-Host "  Arquivo LaTeX: $TexFile"
Write-Host "  Output PDF  : $PdfOut"
Write-Host ""

# Detect pdflatex
$pdflatex = Get-Command pdflatex -ErrorAction SilentlyContinue

if ($pdflatex) {
    Write-Host "  pdflatex encontrado: $($pdflatex.Source)" -ForegroundColor Green
    Write-Host "  Compilando (passagem 1/2)..."

    $args1 = @("-interaction=nonstopmode", "-output-directory=$DocsDir", $TexFile)
    $result1 = & pdflatex @args1 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  AVISO: passagem 1 retornou codigo $LASTEXITCODE" -ForegroundColor Yellow
    }

    Write-Host "  Compilando (passagem 2/2 — indice/refs)..."
    $result2 = & pdflatex @args1 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  AVISO: passagem 2 retornou codigo $LASTEXITCODE" -ForegroundColor Yellow
    }

    if (Test-Path $PdfOut) {
        $hash = (Get-FileHash $PdfOut -Algorithm SHA256).Hash.ToLower()
        $size = (Get-Item $PdfOut).Length
        Write-Host ""
        Write-Host "  PDF gerado com sucesso!" -ForegroundColor Green
        Write-Host "  Arquivo : $PdfOut"
        Write-Host "  Tamanho : $size bytes"
        Write-Host "  SHA-256 : $hash"
    } else {
        Write-Host "  ERRO: PDF nao gerado. Verifique o log acima." -ForegroundColor Red
        exit 1
    }
} else {
    Show-OverleafInstructions
}

# Always export Markdown final
Write-Host "  Exportando versao Markdown final..."
Copy-MarkdownFinal

# Always show Zenodo instructions
Show-ZenodoInstructions

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""
