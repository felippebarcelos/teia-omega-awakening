<#
.SYNOPSIS
    Fetch-Public-Dataset.ps1 — Coleta dataset público para testes TEIA P3

.DESCRIPTION
    Baixa 13 arquivos variados de domínio público e salva em D:\TEIA_USER\Inbox.
    Idempotente: pula arquivos já presentes. Registra sucesso/falha por URL.
    Zero escrita em CAS ou candidates.

.PARAMETER OutDir
    Diretório de destino. Padrão: D:\TEIA_USER\Inbox

.EXAMPLE
    .\Fetch-Public-Dataset.ps1
    .\Fetch-Public-Dataset.ps1 -OutDir "D:\outro\caminho"
#>
[CmdletBinding()]
param(
    [string]$OutDir = "D:\TEIA_USER\Inbox"
)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

# Dataset: 13 arquivos públicos com diversidade de tipo e tamanho
# Fontes: Project Gutenberg, JSONPlaceholder, Wikimedia Commons,
#         GitHub Raw (jbrownlee/Datasets), RFC Editor (IETF)
$dataset = @(
    # ── Livros .txt (domínio público — Project Gutenberg) ─────────────────────
    [ordered]@{
        url      = 'https://www.gutenberg.org/files/1342/1342-0.txt'
        file     = 'gutenberg_pride_prejudice.txt'
        category = 'book'
        desc     = 'Pride and Prejudice — Jane Austen (PG #1342)'
    },
    [ordered]@{
        url      = 'https://www.gutenberg.org/files/11/11-0.txt'
        file     = 'gutenberg_alice_wonderland.txt'
        category = 'book'
        desc     = "Alice's Adventures in Wonderland — Lewis Carroll (PG #11)"
    },
    [ordered]@{
        url      = 'https://www.gutenberg.org/files/84/84-0.txt'
        file     = 'gutenberg_frankenstein.txt'
        category = 'book'
        desc     = 'Frankenstein — Mary Shelley (PG #84)'
    },

    # ── JSON estruturados (JSONPlaceholder — API pública estável) ────────────
    [ordered]@{
        url      = 'https://jsonplaceholder.typicode.com/posts'
        file     = 'jsonplaceholder_posts.json'
        category = 'json'
        desc     = 'JSONPlaceholder /posts — 100 posts (array JSON)'
    },
    [ordered]@{
        url      = 'https://jsonplaceholder.typicode.com/users'
        file     = 'jsonplaceholder_users.json'
        category = 'json'
        desc     = 'JSONPlaceholder /users — 10 usuários com endereços e geo'
    },
    [ordered]@{
        url      = 'https://jsonplaceholder.typicode.com/todos'
        file     = 'jsonplaceholder_todos.json'
        category = 'json'
        desc     = 'JSONPlaceholder /todos — 200 tarefas (chaves repetitivas)'
    },

    # ── Imagens (Wikimedia Commons — domínio público) ────────────────────────
    [ordered]@{
        url      = 'https://upload.wikimedia.org/wikipedia/commons/6/63/Wikipedia-logo.png'
        file     = 'wikimedia_wikipedia_logo.png'
        category = 'image'
        desc     = 'Logo Wikipedia PNG (Wikimedia Commons)'
    },
    [ordered]@{
        url      = 'https://upload.wikimedia.org/wikipedia/commons/a/a7/Camponotus_flavomarginatus_ant.jpg'
        file     = 'wikimedia_ant_macro.jpg'
        category = 'image'
        desc     = 'Fotografia macro de formiga JPG (Wikimedia Commons)'
    },
    [ordered]@{
        url      = 'https://upload.wikimedia.org/wikipedia/en/a/a9/Example.jpg'
        file     = 'wikimedia_example.jpg'
        category = 'image'
        desc     = 'Imagem exemplo padrão JPG (Wikimedia EN)'
    },

    # ── CSV (GitHub Raw — datasets clássicos de ML) ──────────────────────────
    [ordered]@{
        url      = 'https://raw.githubusercontent.com/jbrownlee/Datasets/master/iris.csv'
        file     = 'dataset_iris.csv'
        category = 'csv'
        desc     = 'Iris dataset — 150 amostras, 4 features + classe'
    },
    [ordered]@{
        url      = 'https://raw.githubusercontent.com/jbrownlee/Datasets/master/housing.csv'
        file     = 'dataset_housing.csv'
        category = 'csv'
        desc     = 'Boston Housing dataset — 506 amostras, 13 features'
    },

    # ── PDFs públicos (RFC Editor — IETF) ───────────────────────────────────
    [ordered]@{
        url      = 'https://www.rfc-editor.org/rfc/rfc8259.pdf'
        file     = 'rfc8259_json_spec.pdf'
        category = 'pdf'
        desc     = 'RFC 8259 — The JSON Data Interchange Standard (IETF)'
    },
    [ordered]@{
        url      = 'https://www.rfc-editor.org/rfc/rfc7230.pdf'
        file     = 'rfc7230_http11_spec.pdf'
        category = 'pdf'
        desc     = 'RFC 7230 — HTTP/1.1 Message Syntax and Routing (IETF)'
    }
)

$ua        = 'Mozilla/5.0 (compatible; TEIA-Fetch/1.0; +educational)'
$ok        = 0
$skipped   = 0
$failed    = 0
$results   = [System.Collections.Generic.List[object]]::new()

Write-Host @"
======================================================================
 [FETCH] Fetch-Public-Dataset.ps1 — Dataset Público TEIA P3
 Destino : $OutDir
 Arquivos: $($dataset.Count)
======================================================================
"@ -ForegroundColor Cyan

foreach ($item in $dataset) {
    $outPath = Join-Path $OutDir $item.file

    if (Test-Path $outPath) {
        $existingSize = (Get-Item $outPath).Length
        $skipped++
        Write-Host ("[SKIP] {0,-42} já existe ({1} KB)" -f $item.file, [math]::Round($existingSize/1KB,1)) -ForegroundColor DarkGray
        $null = $results.Add([ordered]@{
            file     = $item.file
            category = $item.category
            status   = 'skipped'
            size_kb  = [math]::Round($existingSize/1KB, 1)
            desc     = $item.desc
        })
        continue
    }

    Write-Host ("[FETCH] {0}" -f $item.desc) -ForegroundColor Yellow -NoNewline

    try {
        $response = Invoke-WebRequest -Uri $item.url `
                        -OutFile $outPath `
                        -UserAgent $ua `
                        -TimeoutSec 60 `
                        -UseBasicParsing `
                        -ErrorAction Stop

        $size = (Get-Item $outPath).Length
        $ok++
        Write-Host (" → OK ({0} KB)" -f [math]::Round($size/1KB, 1)) -ForegroundColor Green
        $null = $results.Add([ordered]@{
            file     = $item.file
            category = $item.category
            status   = 'ok'
            size_kb  = [math]::Round($size/1KB, 1)
            url      = $item.url
            desc     = $item.desc
        })
    } catch {
        $failed++
        $errMsg = $_.Exception.Message -replace "`n",' '
        Write-Host (" → FALHA: $errMsg") -ForegroundColor Red
        # Remove arquivo parcial se existir
        if (Test-Path $outPath) { Remove-Item $outPath -Force -ErrorAction SilentlyContinue }
        $null = $results.Add([ordered]@{
            file     = $item.file
            category = $item.category
            status   = 'failed'
            error    = $errMsg
            url      = $item.url
            desc     = $item.desc
        })
    }
}

Write-Host ''
Write-Host $('=' * 70) -ForegroundColor Cyan
Write-Host (" OK: $ok  |  Skip: $skipped  |  Falha: $failed  |  Total: $($dataset.Count)") -ForegroundColor White

$resultPath = "D:\TEIA_CORE\logs\fetch_public_dataset.jsonl"
foreach ($r in $results) {
    $r | ConvertTo-Json -Compress | Add-Content -LiteralPath $resultPath -Encoding UTF8
}
Write-Host " Log: $resultPath"
Write-Host $('=' * 70)

# Exibir conteúdo atual do Inbox
Write-Host ''
Write-Host ' Inbox atual:' -ForegroundColor Cyan
Get-ChildItem $OutDir -File | Sort-Object Name | ForEach-Object {
    Write-Host ("   {0,-50} {1,8} KB" -f $_.Name, [math]::Round($_.Length/1KB,1))
}
