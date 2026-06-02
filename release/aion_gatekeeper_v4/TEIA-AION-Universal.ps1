#Requires -Version 7
# Protocol P31.0 - TEIA AION UNIVERSAL MOTOR + ORACULO GATEKEEPER
# Motor AION RISPA NDC v4.0.0 - Recuo Autonomo Ativado

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$GATEKEEPER_MASS_THRESHOLD = 500 * 1024  # 500 KB — abaixo disso o overhead do motor anula o ganho
$DECODER_OVERHEAD_BYTES    = 1900        # tamanho fixo estimado do script decodificador gerado

function Get-CompressedSize {
    param(
        [byte[]]$Data,
        [type]$StreamType,
        [System.IO.Compression.CompressionLevel]$Level
    )
    $ms = New-Object System.IO.MemoryStream
    $cs = New-Object $StreamType($ms, $Level, $true)
    $cs.Write($Data, 0, $Data.Length)
    $cs.Dispose()
    $size = $ms.Length
    $ms.Dispose()
    return $size
}

function New-TeiaDecoder {
    param([string]$OutFile, [int]$ColCount)
    $code = @"
#Requires -Version 7
[CmdletBinding()]
param([string]`$SeedMetaFile, [string]`$SeedBinFile, [string]`$OutputFile)
`$ErrorActionPreference = "Stop"
`$utf8 = [System.Text.UTF8Encoding]::new(`$false)
`$s = Get-Content `$SeedMetaFile -Raw | ConvertFrom-Json
`$bin = [System.IO.File]::ReadAllBytes(`$SeedBinFile)
`$ms  = New-Object System.IO.MemoryStream(`$bin,0,`$bin.Length)
`$bs  = New-Object System.IO.Compression.BrotliStream(`$ms,[System.IO.Compression.CompressionMode]::Decompress)
`$o   = New-Object System.IO.MemoryStream; `$bs.CopyTo(`$o); `$bs.Dispose()
`$resLines = `$utf8.GetString(`$o.ToArray()) -split "\n"
`$nl = if (`$s.newline -eq 'crlf') { "`r`n" } else { "`n" }
`$sw = [System.IO.StreamWriter]::new(`$OutputFile, `$false, `$utf8)
`$sw.Write(`$s.header + `$nl)

`$dicts = @{}
foreach (`$col in `$s.columns) { `$dicts[`$col.Index] = `$col.Dictionary }

for (`$r = 0; `$r -lt `$s.rowCount; `$r++) {
    `$parts = `$resLines[`$r] -split '\|'
    `$rowValues = New-Object string[] $ColCount

    for (`$i = 0; `$i -lt `$s.residueMap.Count; `$i++) {
        `$map = `$s.residueMap[`$i]
        if (`$map.Type -eq "Index") {
            `$dictIdx = [int]`$parts[`$i]
            `$val = `$dicts[`$map.Index][`$dictIdx]
            if (`$val.Contains(',')) { `$val = '"{0}"' -f `$val }
            `$rowValues[`$map.Index] = `$val
        } else {
            `$rowValues[`$map.Index] = `$parts[`$i]
        }
    }

    `$sw.Write((`$rowValues -join ','))
    if (`$r -lt `$s.rowCount - 1) {
        `$sw.Write(`$nl)
    } elseif (`$s.hasTrailingNewline) {
        `$sw.Write(`$nl)
    }
}
`$sw.Close()
"@
    [System.IO.File]::WriteAllText($OutFile, $code, $utf8NoBom)
}

function Invoke-AionUniversal {
    param([string]$InputFile, [string]$OutputDir)

    $rawBytes = [System.IO.File]::ReadAllBytes($InputFile)
    $fileSize = $rawBytes.Length

    # =========================================================
    # ORACULO GATEKEEPER — REGRA 1: Massa Critica
    # Arquivos abaixo de 500 KB nao atingem o volume estrutural
    # minimo para cobrir o overhead fixo do motor decodificador.
    # =========================================================
    if ($fileSize -lt $GATEKEEPER_MASS_THRESHOLD) {
        $brotliSize = Get-CompressedSize -Data $rawBytes `
            -StreamType System.IO.Compression.BrotliStream `
            -Level SmallestSize
        return [PSCustomObject]@{
            Decision   = "Recuo Seguro (Massa Insuficiente)"
            BrotliSize = $brotliSize
            TeiaSize   = $brotliSize
            Delta      = 0
            ShaPass    = "N/A"
        }
    }

    # --- Analise completa de cardinalidade ---
    $brotliSize = Get-CompressedSize -Data $rawBytes `
        -StreamType System.IO.Compression.BrotliStream `
        -Level SmallestSize

    $rawString       = [System.Text.Encoding]::UTF8.GetString($rawBytes)
    $newline         = if ($rawString -match "`r`n") { "`r`n" } else { "`n" }
    $nlStr           = if ($newline -eq "`r`n") { "crlf" } else { "lf" }
    $hasTrailingNl   = $rawString.EndsWith($newline)

    $lines = $rawString -split $newline
    if ($lines[-1].Trim() -eq "") { $lines = $lines[0..($lines.Length - 2)] }

    $header    = $lines[0].Trim()
    $csvRegex  = [regex]',(?=(?:[^"]*"[^"]*")*[^"]*$)'
    $colNames  = $csvRegex.Split($header) | ForEach-Object { $_.Trim().Trim('"') }
    $rowCount  = $lines.Length - 1

    $columns = @()
    for ($c = 0; $c -lt $colNames.Length; $c++) {
        $values    = New-Object string[] $rowCount
        $uniqueSet = [System.Collections.Generic.HashSet[string]]::new()
        for ($r = 1; $r -lt $lines.Length; $r++) {
            $parts = $csvRegex.Split($lines[$r])
            $val   = if ($parts.Length -gt $c) { $parts[$c].Trim().Trim('"') } else { "" }
            $values[$r-1] = $val
            $uniqueSet.Add($val) | Out-Null
        }
        $uniqueArr = [string[]]([System.Linq.Enumerable]::ToArray($uniqueSet))
        $columns += @{
            Index       = $c
            UniqueCount = $uniqueArr.Length
            Cardinality = $uniqueArr.Length / $rowCount
            Values      = $values
            Unique      = $uniqueArr
        }
    }

    $metaColumns   = @()
    $residueColMap = @()
    for ($c = 0; $c -lt $colNames.Length; $c++) {
        $col = $columns[$c]
        if ($col.Cardinality -lt 0.05) {
            $metaColumns   += @{ Index = $c; Type = "Dictionary"; Dictionary = $col.Unique }
            $residueColMap += @{ Index = $c; Type = "Index" }
            $dictLookup = @{}
            for ($i = 0; $i -lt $col.Unique.Length; $i++) { $dictLookup[$col.Unique[$i]] = $i }
            $col["Lookup"] = $dictLookup
        } else {
            $residueColMap += @{ Index = $c; Type = "Raw" }
        }
    }

    # Constroi o residuo em memoria — unica vez, reutilizado pelo Gatekeeper e pela Forja
    $sb = [System.Text.StringBuilder]::new()
    for ($r = 0; $r -lt $rowCount; $r++) {
        $rowParts = New-Object string[] $residueColMap.Count
        for ($i = 0; $i -lt $residueColMap.Count; $i++) {
            $map = $residueColMap[$i]
            $col = $columns[$map.Index]
            if ($map.Type -eq "Index") {
                $rowParts[$i] = $col.Lookup[$col.Values[$r]].ToString()
            } else {
                $val = $col.Values[$r]
                if ($val.Contains(',')) { $val = "`"$val`"" }
                $rowParts[$i] = $val
            }
        }
        $sb.Append(($rowParts -join '|')) | Out-Null
        if ($r -lt $rowCount - 1) { $sb.Append("`n") | Out-Null }
    }
    $residueBytes = $utf8NoBom.GetBytes($sb.ToString())

    # Comprime o residuo em memoria — inline para evitar ambiguidade de retorno de funcao
    $msBin = New-Object System.IO.MemoryStream
    $bsBin = New-Object System.IO.Compression.BrotliStream($msBin, [System.IO.Compression.CompressionLevel]::SmallestSize, $true)
    $bsBin.Write($residueBytes, 0, $residueBytes.Length)
    $bsBin.Dispose()
    $compressedResidueBytes = $msBin.ToArray()
    $msBin.Dispose()
    $estimatedBinSize = $compressedResidueBytes.Length

    # Estima o tamanho do meta JSON
    $tempMeta = @{
        header             = $header
        newline            = $nlStr
        rowCount           = $rowCount
        columns            = $metaColumns
        residueMap         = $residueColMap
        hasTrailingNewline = $hasTrailingNl
    }
    $tempMetaJson      = $tempMeta | ConvertTo-Json -Depth 10 -Compress
    $estimatedMetaSize = $utf8NoBom.GetByteCount($tempMetaJson)

    $estimatedTeiaTotal = $estimatedBinSize + $estimatedMetaSize + $DECODER_OVERHEAD_BYTES

    # =========================================================
    # ORACULO GATEKEEPER — REGRA 2: Vantagem Estrutural
    # Se o seed estimado nao supera o Brotli puro, o motor
    # recua: a entropia organica domina, o overhead estrutural
    # nao e suficiente para cobrir o custo do decodificador.
    # =========================================================
    if ($estimatedTeiaTotal -ge $brotliSize) {
        return [PSCustomObject]@{
            Decision   = "Recuo Seguro (Entropia Dominante)"
            BrotliSize = $brotliSize
            TeiaSize   = $brotliSize
            Delta      = 0
            ShaPass    = "N/A"
        }
    }

    # =========================================================
    # FORJA AUTORIZADA — o ganho estrutural supera o overhead.
    # Os bytes ja comprimidos sao gravados sem recomputacao.
    # =========================================================
    if (!(Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }

    $seedMetaFile = Join-Path $OutputDir "seed.json"
    $seedBinFile  = Join-Path $OutputDir "seed.bin"
    $decoderFile  = Join-Path $OutputDir "Decode.ps1"

    [System.IO.File]::WriteAllText($seedMetaFile, $tempMetaJson, $utf8NoBom)
    [System.IO.File]::WriteAllBytes($seedBinFile, $compressedResidueBytes)
    New-TeiaDecoder -OutFile $decoderFile -ColCount $colNames.Length

    return [PSCustomObject]@{
        Decision   = "Forja Autorizada"
        BrotliSize = $brotliSize
        Meta       = $seedMetaFile
        Bin        = $seedBinFile
        Decoder    = $decoderFile
    }
}
