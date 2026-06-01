#Requires -Version 7
# Protocol P29.1 - TEIA AION UNIVERSAL MOTOR
# Motor AION RISPA NDC v3.1.0 - Estabilizado

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

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
    
    if (!(Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
    
    $rawBytes = [System.IO.File]::ReadAllBytes($InputFile)
    $rawString = [System.Text.Encoding]::UTF8.GetString($rawBytes)
    $newline = if ($rawString -match "`r`n") { "`r`n" } else { "`n" }
    $nlStr = if ($newline -eq "`r`n") { "crlf" } else { "lf" }
    $hasTrailingNewline = $rawString.EndsWith($newline)

    $lines = $rawString -split $newline
    if ($lines[-1].Trim() -eq "") { $lines = $lines[0..($lines.Length - 2)] }

    $header = $lines[0].Trim()
    $csvRegex = [regex]',(?=(?:[^"]*"[^"]*")*[^"]*$)'
    $colNames = $csvRegex.Split($header) | ForEach-Object { $_.Trim().Trim('"') }
    $rowCount = $lines.Length - 1

    $columns = @()
    for ($c = 0; $c -lt $colNames.Length; $c++) {
        $values = New-Object string[] $rowCount
        $uniqueSet = [System.Collections.Generic.HashSet[string]]::new()
        for ($r = 1; $r -lt $lines.Length; $r++) {
            $parts = $csvRegex.Split($lines[$r])
            $val = if ($parts.Length -gt $c) { $parts[$c].Trim().Trim('"') } else { "" }
            $values[$r-1] = $val
            $uniqueSet.Add($val) | Out-Null
        }
        $uniqueArr = [string[]]([System.Linq.Enumerable]::ToArray($uniqueSet))
        $columns += @{
            Index = $c
            UniqueCount = $uniqueArr.Length
            Cardinality = $uniqueArr.Length / $rowCount
            Values = $values
            Unique = $uniqueArr
        }
    }

    $metaColumns = @()
    $residueColMap = @() 
    for ($c = 0; $c -lt $colNames.Length; $c++) {
        $col = $columns[$c]
        if ($col.Cardinality -lt 0.05) {
            $metaColumns += @{ Index = $c; Type = "Dictionary"; Dictionary = $col.Unique }
            $residueColMap += @{ Index = $c; Type = "Index" }
            $dictLookup = @{}
            for ($i = 0; $i -lt $col.Unique.Length; $i++) { $dictLookup[$col.Unique[$i]] = $i }
            $col["Lookup"] = $dictLookup
        } else {
            $residueColMap += @{ Index = $c; Type = "Raw" }
        }
    }

    $seedMetaFile = Join-Path $OutputDir "seed.json"
    $seedBinFile = Join-Path $OutputDir "seed.bin"
    $decoderFile = Join-Path $OutputDir "Decode.ps1"

    $meta = @{ 
        header = $header; 
        newline = $nlStr; 
        rowCount = $rowCount; 
        columns = $metaColumns; 
        residueMap = $residueColMap;
        hasTrailingNewline = $hasTrailingNewline
    }
    [System.IO.File]::WriteAllText($seedMetaFile, ($meta | ConvertTo-Json -Depth 10 -Compress), $utf8NoBom)

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
    $msRes = New-Object System.IO.MemoryStream
    $bsRes = New-Object System.IO.Compression.BrotliStream($msRes, [System.IO.Compression.CompressionLevel]::SmallestSize, $true)
    $bsRes.Write($residueBytes, 0, $residueBytes.Length)
    $bsRes.Dispose()
    [System.IO.File]::WriteAllBytes($seedBinFile, $msRes.ToArray())
    $msRes.Dispose()

    New-TeiaDecoder -OutFile $decoderFile -ColCount $colNames.Length
    
    return @{ Meta = $seedMetaFile; Bin = $seedBinFile; Decoder = $decoderFile }
}
