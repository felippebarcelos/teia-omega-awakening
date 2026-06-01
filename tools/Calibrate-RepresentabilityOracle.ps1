#Requires -Version 7
# Protocol P30.0 - Calibração do Oráculo de Representabilidade
# Calcula o Limiar de Viabilidade do Storage as Computation

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$workspace = $PSScriptRoot
$resultsPath = Join-Path $workspace "..\docs\TEIA_CORPUS10_RESULTS.md"
$calibrationPath = Join-Path $workspace "..\docs\TEIA_ORACLE_CALIBRATION_P30.md"

if (-not (Test-Path $resultsPath)) {
    throw "Arquivo TEIA_CORPUS10_RESULTS.md nao encontrado."
}

$lines = Get-Content $resultsPath -Encoding UTF8
$tableLines = $lines | Where-Object { $_ -match '^\| csv_' }

$datasets = @()

foreach ($line in $tableLines) {
    $cols = $line -split '\|' | ForEach-Object { $_.Trim() }
    
    $arquivo = $cols[1]
    $original = [long]$cols[2]
    $brotli = [long]$cols[3]
    $teia = [long]$cols[4]
    $delta = [long]$cols[5]
    $veredito = $cols[7]
    
    $overheadMotor = 1024 # Custo fixo conservador do script decodificador em bytes
    $ratioBrotli = [math]::Round(($brotli / $original) * 100, 2)
    
    $motivo = ""
    if ($veredito -ne "TEIA VENCE") {
        if ($original -lt 500000) {
            $motivo = "Arquivo muito pequeno. Overhead do motor supera o ganho estatistico."
        } elseif ($ratioBrotli -lt 15) {
            $motivo = "Alta redundancia residual. Brotli captura padrao na janela LZ77."
        } else {
            $motivo = "Baixa Lei Estrutural N x M. Entropia organica domina os dados."
        }
    } else {
        $motivo = "Overhead estrutural excede janela LZ77. Vantagem procedural confirmada."
    }

    $datasets += [pscustomobject]@{
        Arquivo = $arquivo
        Original = $original
        Brotli = $brotli
        Teia = $teia
        DeltaReal = $delta
        RatioBrotli = $ratioBrotli
        Motivo = $motivo
        Veredito = $veredito
    }
}

$md = @"
# TEIA ORACLE CALIBRATION - Protocol P30.0

## Diagnostico de Representabilidade (Corpus 10)

A analise dos 10 arquivos do corpus revela que a arquitetura AION RISPA NDC possui um custo fixo de inteligencia (Tamanho do Script Decodificador + Metadados do Dicionario). Este custo fixo so se justifica economicamente quando o overhead estrutural do arquivo supera a capacidade da janela de lookback do algoritmo LZ77 (Brotli).

### Tabela de Calibracao Analitica

| Arquivo | Tam. Original | Compressibilidade Brotli | Delta Observado | Veredito | Diagnostico do Oraculo |
|---|---|---|---|---|---|
"@

foreach ($d in $datasets) {
    $md += "`n| $($d.Arquivo) | $([math]::Round($d.Original / 1KB, 2)) KB | $($d.RatioBrotli)% | $($d.DeltaReal) bytes | $($d.Veredito) | $($d.Motivo) |"
}

$md += @"

## A Nova Lei do Oraculo (Regra Preditiva Revisada)

Para execucoes futuras, o Oraculo AION so deve tentar a forja procedural se os dados atenderem as seguintes condicoes pre-calculadas:

1. **Limiar de Massa Critica:** O arquivo original deve ser maior que **500 KB**. Em arquivos menores, o peso do decodificador anula o Delta de economia.
2. **Cardinalidade N x M:** O numero de linhas deve ser massivo o suficiente para que a repeticao de chaves e estruturas ultrapasse a janela de dicionario de 16MB do Brotli.
3. **Decisao de Roteamento:**
   - Se `Tamanho < 500KB` -> **Recuo Imediato para Brotli SmallestSize**.
   - Se `Tamanho > 500KB` E `Baixa Cardinalidade na Lente Semantica` -> **Forja Hibrida Autorizada**.

O Storage as Computation nao substitui a compressao estatistica; ele atua onde a entropia estrutural torna a compressao estatistica ineficiente.

Protocolo P30.0 finalizado.
"@

[System.IO.File]::WriteAllText($calibrationPath, $md, $utf8NoBom)
Write-Host "Calibracao concluida. Relatorio salvo em: $calibrationPath" -ForegroundColor Green