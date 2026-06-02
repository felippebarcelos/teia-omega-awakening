#Requires -Version 7
# TEIA-NStar-Predictor.ps1 — Preditor Heurístico de Massa Crítica N*
# Lente de análise PURA: não comprime, não gera seeds, não modifica arquivos.
# Amostra o corpus, calcula cardinalidade das colunas, estima N* matematicamente.
# Saída: JSON canônico com projeção de economia de disco e latência.
# Delta sempre por extenso (nunca símbolo matemático).
#
# Modelo calibrado empiricamente sobre P36/P38:
#   brotli_ratio_estimate = 0.021 + 0.52 * mean_col_entropy
#   delta_efficiency = 0.040 + 0.050 * residual_entropy
#   delta_per_file = brotli_per_file * dict_density * delta_efficiency
#   N_star = ceil(overhead_bytes / delta_per_file)

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$InputPath,
    [int]$SampleFiles    = 10,
    [int]$SampleRows     = 500,
    [int]$DictThreshold  = 50,
    [long]$OverheadBytes = 5000,
    [string]$OutputJson  = '',
    [int]$CorpusN        = -1
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference       = 'SilentlyContinue'

# ─── Descobrir arquivos CSV ────────────────────────────────────────────────────
$InputPath = (Resolve-Path $InputPath -ErrorAction Stop).Path
$csvFiles  = @(Get-ChildItem $InputPath -Filter '*.csv' -Recurse:($false) -ErrorAction SilentlyContinue |
               Sort-Object Name)
if ($csvFiles.Count -eq 0) {
    throw "Nenhum arquivo CSV encontrado em: $InputPath"
}

$actualN     = $csvFiles.Count
$actualNStar = if ($CorpusN -gt 0) { $CorpusN } else { $actualN }
$sample      = $csvFiles | Select-Object -First $SampleFiles

# ─── Ler amostras e acumular estatísticas de colunas ─────────────────────────
# perFile: por arquivo → por coluna → HashSet de valores únicos + contagem
$schema          = $null
$colCardPerFile  = [System.Collections.Generic.Dictionary[string, [System.Collections.Generic.List[int]]]]::new()
$colAvgLenPerFile = [System.Collections.Generic.Dictionary[string, [System.Collections.Generic.List[double]]]]::new()
$fileSizes       = [System.Collections.Generic.List[long]]::new()
$rowsPerFileSampled = [System.Collections.Generic.List[int]]::new()

foreach ($f in $sample) {
    try {
        $rawLines = [System.IO.File]::ReadAllLines($f.FullName, [System.Text.Encoding]::UTF8)
        if ($rawLines.Length -lt 2) { continue }
        $hdr      = $rawLines[0].Trim().Split(',')
        if ($null -eq $schema) { $schema = $rawLines[0].Trim() }
        elseif ($rawLines[0].Trim() -ne $schema) { continue }  # schema mismatch — skip

        $dataRows = $rawLines[1..[math]::Min($SampleRows, $rawLines.Length - 1)]
        $rowCount = $dataRows.Count

        $colSets = @{}
        $colLens = @{}
        foreach ($col in $hdr) {
            $colSets[$col] = [System.Collections.Generic.HashSet[string]]::new()
            $colLens[$col] = [System.Collections.Generic.List[int]]::new()
        }
        foreach ($line in $dataRows) {
            $cells = $line.Split(',')
            for ($ci = 0; $ci -lt [math]::Min($cells.Count, $hdr.Count); $ci++) {
                $v = $cells[$ci]
                $colSets[$hdr[$ci]].Add($v) | Out-Null
                $colLens[$hdr[$ci]].Add($v.Length) | Out-Null
            }
        }

        foreach ($col in $hdr) {
            if (!$colCardPerFile.ContainsKey($col)) {
                $colCardPerFile[$col]   = [System.Collections.Generic.List[int]]::new()
                $colAvgLenPerFile[$col] = [System.Collections.Generic.List[double]]::new()
            }
            $colCardPerFile[$col].Add($colSets[$col].Count)
            $avgLen = if ($colLens[$col].Count -gt 0) {
                ($colLens[$col] | Measure-Object -Average).Average
            } else { 0.0 }
            $colAvgLenPerFile[$col].Add($avgLen)
        }
        $fileSizes.Add($f.Length)
        $rowsPerFileSampled.Add($rowCount)

    } catch { <# skip files with parse errors #> }
}

if ($null -eq $schema -or $colCardPerFile.Count -eq 0) {
    throw "Nenhum arquivo CSV válido com schema uniforme encontrado."
}

$avgFileSizeBytes  = [long]($fileSizes | Measure-Object -Average).Average
$avgRowsPerFile    = [int][math]::Round(($rowsPerFileSampled | Measure-Object -Average).Average)
$cols              = $schema.Split(',')
$totalCols         = $cols.Count

# ─── Classificar colunas: DICT vs RESIDUAL ────────────────────────────────────
$columnDetails = [System.Collections.Generic.List[pscustomobject]]::new()
$dictCols      = 0
$residualCols  = 0

$sumMeanColEntropy      = 0.0
$sumResidualEntropy     = 0.0
$sumDictAvgLen          = 0.0
$residualColCount       = 0

foreach ($col in $cols) {
    if (!$colCardPerFile.ContainsKey($col)) { continue }

    $cards         = $colCardPerFile[$col]
    $avgCard       = [int][math]::Round(($cards | Measure-Object -Average).Average)
    $avgLen        = [math]::Round(($colAvgLenPerFile[$col] | Measure-Object -Average).Average, 2)
    $avgRowsUsed   = [math]::Max(1, $avgRowsPerFile)
    $entropyRatio  = [math]::Round([math]::Min(1.0, $avgCard / $avgRowsUsed), 4)

    $isDict        = $avgCard -le $DictThreshold

    if ($isDict) {
        $dictCols++
        $sumDictAvgLen += $avgLen
    } else {
        $residualCols++
        $sumResidualEntropy += $entropyRatio
        $residualColCount++
    }
    $sumMeanColEntropy += $entropyRatio

    $indexBytesPerCell = if ($avgCard -le 256) { 1 } elseif ($avgCard -le 65536) { 2 } else { 3 }

    $columnDetails.Add([pscustomobject]@{
        name                    = $col
        classification          = if ($isDict) { 'DICT' } else { 'RESIDUAL' }
        avg_cardinality         = $avgCard
        avg_value_len_bytes     = $avgLen
        entropy_ratio           = $entropyRatio
        index_bytes_if_dict     = if ($isDict) { $indexBytesPerCell } else { $null }
        dict_savings_per_cell   = if ($isDict) { [math]::Round([math]::Max(0.0, $avgLen - $indexBytesPerCell), 2) } else { $null }
    })
}

$dictDensity     = if ($totalCols -gt 0) { [math]::Round($dictCols / $totalCols, 4) } else { 0.0 }
$meanColEntropy  = if ($totalCols -gt 0) { [math]::Round($sumMeanColEntropy / $totalCols, 4) } else { 0.0 }
$residualEntropy = if ($residualColCount -gt 0) { [math]::Round($sumResidualEntropy / $residualColCount, 4) } else { 0.0 }

# ─── Modelo de estimativa (calibrado P36/P38) ─────────────────────────────────
# brotli_ratio_estimate: regressão linear sobre 2 pontos de calibração:
#   Corpus_Transversal (Apache CLF):  meanColEntropy=0.163, brotli_ratio=0.106
#   Corpus30 (Alta Entropia):         meanColEntropy=0.691, brotli_ratio=0.381
$brotliRatioEst = [math]::Min(0.97, [math]::Max(0.05, 0.021 + 0.52 * $meanColEntropy))

# delta_efficiency: quanto o grammar salva relativo ao brotli_per_file, por unidade dict_density
#   Calibrado: 0.040 (baixa entropia residual) a 0.090 (alta entropia residual)
$deltaEfficiency = 0.040 + 0.050 * $residualEntropy

$brotliPerFileBytes = [long]($avgFileSizeBytes * $brotliRatioEst)
$deltaPerFileBytes  = [long]($brotliPerFileBytes * $dictDensity * $deltaEfficiency)
$seedPerFileBytes   = $brotliPerFileBytes - $deltaPerFileBytes

# ─── Cálculo N* ──────────────────────────────────────────────────────────────
$nstarValue  = $null
$nstarStr    = ''
$decision    = ''
$rationale   = ''
$savingsPct  = 0.0
$latency     = 'O(1)'

if ($dictDensity -lt 0.05) {
    $nstarStr  = 'never'
    $decision  = 'PassThrough'
    $rationale = "dict_density=$([math]::Round($dictDensity*100,1))% — sem colunas dicionarizaveis; TEIA inaplicavel"
    $latency   = 'N/A'
} elseif ($deltaPerFileBytes -le 0) {
    $nstarStr  = 'never'
    $decision  = 'Brotli'
    $rationale = "delta_per_file estimado <= 0 — seeds nao menores que Brotli individual"
} else {
    $nstarValue = [int][math]::Ceiling($OverheadBytes / $deltaPerFileBytes)
    $nstarStr   = $nstarValue.ToString()
    if ($actualNStar -ge $nstarValue) {
        $decision  = 'TEIA'
        $rationale = "N_atual=$actualNStar >= N_star=$nstarValue — TEIA vence Brotli em disco + acesso O(1)"
    } else {
        $decision  = 'Brotli'
        $rationale = "N_atual=$actualNStar < N_star=$nstarValue — faltam $($nstarValue - $actualNStar) arquivos para TEIA vencer"
    }
    $savingsPct = if ($brotliPerFileBytes -gt 0) {
        [math]::Round(100.0 * $deltaPerFileBytes / $avgFileSizeBytes, 2)
    } else { 0.0 }
}

# Grau de confiança baseado na calibração
$confidence = if ($meanColEntropy -ge 0.10 -and $meanColEntropy -le 0.75 -and $dictDensity -ge 0.20) {
    'high'   # dentro do intervalo calibrado
} elseif ($dictDensity -ge 0.10) {
    'medium' # fora do intervalo mas dict detectado
} else {
    'low'    # dados muito aleatórios ou sem dict — estimativa não confiável
}

# ─── Montar JSON canônico ─────────────────────────────────────────────────────
$colsForJson = $columnDetails | Sort-Object { $cols.IndexOf($_.name) } | ForEach-Object {
    $entry = [ordered]@{
        name           = $_.name
        classification = $_.classification
        avg_cardinality = $_.avg_cardinality
        avg_value_len_bytes = $_.avg_value_len_bytes
        entropy_ratio  = $_.entropy_ratio
    }
    if ($_.classification -eq 'DICT') {
        $entry['index_bytes_if_dict']   = $_.index_bytes_if_dict
        $entry['dict_savings_per_cell'] = $_.dict_savings_per_cell
    }
    $entry
}

$result = [ordered]@{
    predictor_version       = '1.0'
    input_path              = $InputPath.Replace('\','/')
    files_discovered        = $actualN
    files_sampled           = $sample.Count
    rows_sampled_per_file   = $avgRowsPerFile
    schema                  = $schema
    total_columns           = $totalCols
    dict_column_count       = $dictCols
    residual_column_count   = $residualCols
    dict_density_pct        = [int][math]::Round($dictDensity * 100)
    mean_col_entropy        = $meanColEntropy
    residual_entropy        = $residualEntropy
    avg_file_size_bytes     = $avgFileSizeBytes
    columns                 = @($colsForJson)
    prediction = [ordered]@{
        model_version                  = 'empirical_p36p38_v1'
        overhead_estimate_bytes        = $OverheadBytes
        brotli_ratio_estimate          = [math]::Round($brotliRatioEst, 4)
        brotli_estimate_bytes_per_file = $brotliPerFileBytes
        delta_efficiency               = [math]::Round($deltaEfficiency, 4)
        delta_per_file_bytes           = $deltaPerFileBytes
        seed_estimate_bytes_per_file   = $seedPerFileBytes
        n_star                         = $nstarStr
        n_corpus                       = $actualNStar
        n_star_confidence              = $confidence
        decision                       = $decision
        rationale                      = $rationale
        projected_savings_pct          = $savingsPct
        latency_class                  = $latency
        note                           = 'Estimativa heuristica. Para N* preciso: Invoke-TeiaArchiveRouter (compressao real).'
    }
}

$jsonOut = $result | ConvertTo-Json -Depth 10

# ─── Saída ────────────────────────────────────────────────────────────────────
if ([string]::IsNullOrEmpty($OutputJson)) {
    Write-Output $jsonOut
} else {
    [System.IO.File]::WriteAllText($OutputJson, $jsonOut, [System.Text.Encoding]::UTF8)
    $hash = (Get-FileHash $OutputJson -Algorithm SHA256).Hash.ToLower()
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '  TEIA NStar Predictor — P39.0'                               -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host "  Corpus       : $InputPath" -ForegroundColor White
    Write-Host "  Arquivos     : $actualN (amostrados: $($sample.Count))"     -ForegroundColor White
    Write-Host "  Schema       : $schema"                                     -ForegroundColor DarkGray
    Write-Host "  Dict cols    : $dictCols / $totalCols ($([int][math]::Round($dictDensity*100))%)" -ForegroundColor White
    Write-Host ''
    $dColor = switch ($decision) { 'TEIA' { 'Cyan' } 'Brotli' { 'Green' } default { 'DarkGray' } }
    Write-Host "  DECISÃO      : $decision"     -ForegroundColor $dColor
    Write-Host "  N*           : $nstarStr"     -ForegroundColor $dColor
    Write-Host "  N corpus     : $actualNStar"  -ForegroundColor White
    Write-Host "  Confiança    : $confidence"   -ForegroundColor White
    Write-Host "  Economia     : $savingsPct%"  -ForegroundColor White
    Write-Host ''
    Write-Host "  JSON         : $OutputJson"   -ForegroundColor White
    Write-Host "  SHA-256      : $hash"         -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
}
