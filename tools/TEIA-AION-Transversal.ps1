#Requires -Version 7
# TEIA-AION-Transversal.ps1 — Motor Hiper-Relacional v1.0.0
# Extrai uma Master Grammar global de um diretório de CSVs com schema idêntico.
# Forja: master_seed_meta.json + Master_Decode.ps1 + N × [file].seed.bin

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Invoke-AionTransversal {
    param(
        [Parameter(Mandatory)][string]$InputDir,
        [Parameter(Mandatory)][string]$OutputDir,
        [int]$CardinalityThreshold = 50
    )

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $files = Get-ChildItem -Path $InputDir -Filter "*.csv" | Sort-Object Name
    if ($files.Count -eq 0) { throw "Nenhum CSV encontrado em: $InputDir" }

    # FASE 1 — Análise de cardinalidade global (varredura completa do corpus)
    Write-Host "    [Fase 1] Cardinalidade global — $($files.Count) arquivos..." -ForegroundColor Yellow
    $headerLine = (Get-Content $files[0].FullName -TotalCount 1)
    $header     = $headerLine.Split(',')
    $colCount   = $header.Length

    $colSets = [object[]]::new($colCount)
    for ($ci = 0; $ci -lt $colCount; $ci++) {
        $colSets[$ci] = [System.Collections.Generic.HashSet[string]]::new()
    }

    foreach ($f in $files) {
        $lines = [System.IO.File]::ReadAllLines($f.FullName)
        for ($i = 1; $i -lt $lines.Length; $i++) {
            if ([string]::IsNullOrWhiteSpace($lines[$i])) { continue }
            $parts = $lines[$i].Split(',')
            for ($c = 0; $c -lt $colCount; $c++) {
                if ($c -lt $parts.Length) { $null = $colSets[$c].Add($parts[$c]) }
            }
        }
    }

    # FASE 2 — Seleção de colunas dicionário
    Write-Host "    [Fase 2] Selecionando dicionários (threshold=$CardinalityThreshold)..." -ForegroundColor Yellow
    $dictMask    = New-Object bool[] $colCount
    $dictColName = [System.Collections.Generic.List[string]]::new()
    $dictArrMap  = @{}     # colIndex -> sorted string[]
    $dictLookup  = @{}     # colIndex -> {value -> intIndex}

    for ($c = 0; $c -lt $colCount; $c++) {
        if ($colSets[$c].Count -le $CardinalityThreshold) {
            $sorted = @($colSets[$c] | Sort-Object)
            $dictMask[$c] = $true
            $dictColName.Add($header[$c])
            $dictArrMap[$c] = $sorted
            $lk = @{}
            for ($i = 0; $i -lt $sorted.Length; $i++) { $lk[$sorted[$i]] = $i }
            $dictLookup[$c] = $lk
            Write-Host "      Dict : $($header[$c]) ($($sorted.Length) valores)" -ForegroundColor DarkGreen
        } else {
            Write-Host "      Res  : $($header[$c]) ($($colSets[$c].Count) valores)" -ForegroundColor DarkYellow
        }
    }

    # FASE 3 — Baseline: concat de todos os arquivos → BrotliStream SmallestSize
    Write-Host "    [Fase 3] Baseline concat+Brotli..." -ForegroundColor Yellow
    $msBase = New-Object System.IO.MemoryStream
    $bsBase = New-Object System.IO.Compression.BrotliStream($msBase, [System.IO.Compression.CompressionLevel]::SmallestSize, $true)
    foreach ($f in $files) {
        $rawBytes = [System.IO.File]::ReadAllBytes($f.FullName)
        $bsBase.Write($rawBytes, 0, $rawBytes.Length)
    }
    $bsBase.Dispose()
    $baselineSize = [long]$msBase.Length
    $msBase.Dispose()
    Write-Host "      Baseline: $baselineSize bytes" -ForegroundColor White

    # FASE 4 — Forja: residue → Brotli → [file].seed.bin
    Write-Host "    [Fase 4] Forjando $($files.Count) seeds..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

    $perFileMeta   = [System.Collections.Generic.List[hashtable]]::new()
    $totalSeedBins = [long]0

    foreach ($f in $files) {
        $lines = [System.IO.File]::ReadAllLines($f.FullName)
        $sbRes = [System.Text.StringBuilder]::new($lines.Length * 55)
        $null  = $sbRes.AppendLine($headerLine)

        $rowCount = 0
        for ($i = 1; $i -lt $lines.Length; $i++) {
            if ([string]::IsNullOrWhiteSpace($lines[$i])) { continue }
            $parts = $lines[$i].Split(',')
            for ($c = 0; $c -lt $colCount; $c++) {
                if ($c -gt 0) { $null = $sbRes.Append(',') }
                if ($dictMask[$c]) {
                    $val  = if ($c -lt $parts.Length) { $parts[$c] } else { "" }
                    $null = $sbRes.Append($dictLookup[$c][$val])
                } else {
                    $raw  = if ($c -lt $parts.Length) { $parts[$c] } else { "" }
                    $null = $sbRes.Append($raw)
                }
            }
            $null = $sbRes.AppendLine()
            $rowCount++
        }

        $residueBytes = $utf8NoBom.GetBytes($sbRes.ToString())

        $msBin = New-Object System.IO.MemoryStream
        $bsBin = New-Object System.IO.Compression.BrotliStream($msBin, [System.IO.Compression.CompressionLevel]::SmallestSize, $true)
        $bsBin.Write($residueBytes, 0, $residueBytes.Length)
        $bsBin.Dispose()
        $seedBinData = $msBin.ToArray()
        $msBin.Dispose()

        $seedBinFile = Join-Path $OutputDir "$($f.BaseName).seed.bin"
        [System.IO.File]::WriteAllBytes($seedBinFile, $seedBinData)
        $totalSeedBins += $seedBinData.Length

        $perFileMeta.Add(@{
            FileName    = $f.Name
            RowCount    = $rowCount
            OrigSize    = $f.Length
            SeedBinSize = $seedBinData.Length
        })
    }

    # FASE 5 — master_seed_meta.json
    Write-Host "    [Fase 5] Escrevendo artefatos mestres..." -ForegroundColor Yellow

    $dictColsObj = [ordered]@{}
    foreach ($c in ($dictArrMap.Keys | Sort-Object)) {
        $dictColsObj[$header[$c]] = $dictArrMap[$c]
    }

    $masterMeta = [ordered]@{
        Version           = "1.0.0"
        Schema            = $header
        DictionaryColumns = $dictColsObj
        FileCount         = $files.Count
        Files             = @($perFileMeta)
    }

    $masterMetaFile = Join-Path $OutputDir "master_seed_meta.json"
    $masterMetaJson = $masterMeta | ConvertTo-Json -Depth 10 -Compress
    [System.IO.File]::WriteAllText($masterMetaFile, $masterMetaJson, $utf8NoBom)
    $masterMetaSize = (Get-Item $masterMetaFile).Length

    # FASE 6 — Master_Decode.ps1 (decoder standalone compartilhado)
    $decoderScript = @'
#Requires -Version 7
# Master_Decode.ps1 — TEIA AION Transversal Decoder v1.0.0
# Reconstrói um arquivo CSV individual a partir do master_seed_meta.json e de um .seed.bin
#
# Uso:
#   pwsh -NoProfile -File Master_Decode.ps1 `
#        -MasterMetaFile master_seed_meta.json `
#        -SeedBinFile    log_2024_01_01.seed.bin `
#        -OutputFile     output.csv

param(
    [Parameter(Mandatory)][string]$MasterMetaFile,
    [Parameter(Mandatory)][string]$SeedBinFile,
    [Parameter(Mandatory)][string]$OutputFile
)

$ErrorActionPreference = "Stop"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$meta      = Get-Content -Path $MasterMetaFile -Raw | ConvertFrom-Json
$schemaArr = @($meta.schema)
$colCount  = $schemaArr.Count

$dictCols = @{}
foreach ($prop in $meta.dictionaryColumns.PSObject.Properties) {
    $dictCols[$prop.Name] = @($prop.Value)
}

$seedBytes = [System.IO.File]::ReadAllBytes($SeedBinFile)
$msIn      = New-Object System.IO.MemoryStream(,$seedBytes)
$bsIn      = New-Object System.IO.Compression.BrotliStream($msIn, [System.IO.Compression.CompressionMode]::Decompress)
$msOut     = New-Object System.IO.MemoryStream
$bsIn.CopyTo($msOut)
$bsIn.Dispose()
$msIn.Dispose()
$residue   = [System.Text.Encoding]::UTF8.GetString($msOut.ToArray())
$msOut.Dispose()

$lines = $residue.Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries)
$sb    = [System.Text.StringBuilder]::new($lines.Count * 80)
$null  = $sb.AppendLine($lines[0].TrimEnd("`r"))

for ($i = 1; $i -lt $lines.Count; $i++) {
    $parts = $lines[$i].TrimEnd("`r").Split(',')
    for ($c = 0; $c -lt $colCount; $c++) {
        if ($c -gt 0) { $null = $sb.Append(',') }
        $col = $schemaArr[$c]
        $raw = if ($c -lt $parts.Count) { $parts[$c] } else { "" }
        if ($dictCols.ContainsKey($col)) {
            $null = $sb.Append($dictCols[$col][[int]$raw])
        } else {
            $null = $sb.Append($raw)
        }
    }
    $null = $sb.AppendLine()
}

[System.IO.File]::WriteAllText($OutputFile, $sb.ToString(), $utf8NoBom)
'@

    $decoderFile = Join-Path $OutputDir "Master_Decode.ps1"
    [System.IO.File]::WriteAllText($decoderFile, $decoderScript, $utf8NoBom)
    $decoderSize = (Get-Item $decoderFile).Length

    $teiaTotalSize = $totalSeedBins + $masterMetaSize + $decoderSize

    return [PSCustomObject]@{
        FileCount      = $files.Count
        TotalOrigSize  = [long]($files | Measure-Object -Property Length -Sum).Sum
        BaselineSize   = $baselineSize
        TeiaTotalSize  = $teiaTotalSize
        TotalSeedBins  = $totalSeedBins
        MasterMetaSize = $masterMetaSize
        DecoderSize    = $decoderSize
        Delta          = $baselineSize - $teiaTotalSize
        DictColumns    = @($dictColName)
        Header         = $header
        OutputDir      = $OutputDir
        MasterMetaFile = $masterMetaFile
        DecoderFile    = $decoderFile
    }
}

function Invoke-AionTransversalDecode {
    param(
        [Parameter(Mandatory)][string]$MasterMetaFile,
        [Parameter(Mandatory)][string]$SeedBinFile,
        [Parameter(Mandatory)][string]$OutputFile
    )

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $meta      = Get-Content -Path $MasterMetaFile -Raw | ConvertFrom-Json
    $schemaArr = @($meta.schema)
    $colCount  = $schemaArr.Count

    $dictCols = @{}
    foreach ($prop in $meta.dictionaryColumns.PSObject.Properties) {
        $dictCols[$prop.Name] = @($prop.Value)
    }

    $seedBytes = [System.IO.File]::ReadAllBytes($SeedBinFile)
    $msIn      = New-Object System.IO.MemoryStream(,$seedBytes)
    $bsIn      = New-Object System.IO.Compression.BrotliStream($msIn, [System.IO.Compression.CompressionMode]::Decompress)
    $msOut     = New-Object System.IO.MemoryStream
    $bsIn.CopyTo($msOut)
    $bsIn.Dispose()
    $msIn.Dispose()
    $residue   = [System.Text.Encoding]::UTF8.GetString($msOut.ToArray())
    $msOut.Dispose()

    $lines = $residue.Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries)
    $sb    = [System.Text.StringBuilder]::new($lines.Count * 80)
    $null  = $sb.AppendLine($lines[0].TrimEnd("`r"))

    for ($i = 1; $i -lt $lines.Count; $i++) {
        $parts = $lines[$i].TrimEnd("`r").Split(',')
        for ($c = 0; $c -lt $colCount; $c++) {
            if ($c -gt 0) { $null = $sb.Append(',') }
            $col = $schemaArr[$c]
            $raw = if ($c -lt $parts.Count) { $parts[$c] } else { "" }
            if ($dictCols.ContainsKey($col)) {
                $null = $sb.Append($dictCols[$col][[int]$raw])
            } else {
                $null = $sb.Append($raw)
            }
        }
        $null = $sb.AppendLine()
    }

    [System.IO.File]::WriteAllText($OutputFile, $sb.ToString(), $utf8NoBom)
}
