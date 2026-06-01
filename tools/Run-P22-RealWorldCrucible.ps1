#Requires -Version 7
<#
.SYNOPSIS
    P22.0 — Real-World Crucible: aplica motor TEIA híbrido a 3 datasets orgânicos reais.
    Prova (ou refuta) que TEIA bate Brotli em dados reais com estrutura procedural significativa.
#>
[CmdletBinding()]
param(
    [string]$DataDir   = 'D:\TEIA_USER\MyRealData\RealWorld_Crucible',
    [string]$OutputDir = 'D:\TEIA_CLAUDE_AWAKENING\sandbox\crucible_p22'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

New-Item -ItemType Directory -Path "$OutputDir\seeds"    -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputDir\decoders" -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputDir\rebuilt"  -Force | Out-Null

# ─── Compression helpers ─────────────────────────────────────────────────────

function Measure-Compressed([string]$Path) {
    $raw = [System.IO.File]::ReadAllBytes($Path)
    # GZip — leaveOpen=$true prevents MemoryStream disposal on GZipStream.Dispose()
    $msGz = New-Object System.IO.MemoryStream
    $gz   = New-Object System.IO.Compression.GZipStream($msGz, [System.IO.Compression.CompressionLevel]::SmallestSize, $true)
    $gz.Write($raw, 0, $raw.Length); $gz.Dispose()
    # Brotli — leaveOpen=$true
    $msBr = New-Object System.IO.MemoryStream
    $br   = New-Object System.IO.Compression.BrotliStream($msBr, [System.IO.Compression.CompressionLevel]::SmallestSize, $true)
    $br.Write($raw, 0, $raw.Length); $br.Dispose()
    [PSCustomObject]@{ Original = $raw.Length; GZip = $msGz.Length; Brotli = $msBr.Length }
}

function Compress-Brotli-B64([byte[]]$data) {
    $ms = New-Object System.IO.MemoryStream
    $bs = New-Object System.IO.Compression.BrotliStream($ms, [System.IO.Compression.CompressionLevel]::SmallestSize, $true)
    $bs.Write($data, 0, $data.Length); $bs.Dispose()
    [Convert]::ToBase64String($ms.ToArray())
}

function Decompress-Brotli-B64([string]$b64) {
    $compressed = [Convert]::FromBase64String($b64)
    $ms  = New-Object System.IO.MemoryStream($compressed, 0, $compressed.Length)
    $bs  = New-Object System.IO.Compression.BrotliStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
    $out = New-Object System.IO.MemoryStream
    $bs.CopyTo($out); $bs.Dispose()
    $out.ToArray()
}

function Format-Bytes([long]$b) {
    if ($b -ge 1MB) { '{0:F2} MB' -f ($b / 1MB) }
    elseif ($b -ge 1KB) { '{0:F1} KB' -f ($b / 1KB) }
    else { "$b B" }
}

function Pct-Delta([long]$teia, [long]$brotli) {
    if ($brotli -le 0) { return '  N/A' }
    $d = ($brotli - $teia) / $brotli * 100
    '{0:F1}%' -f $d
}

# ─── BANNER ──────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host '======================================================================'
Write-Host '  TEIA P22.0 — Real-World Crucible'
Write-Host '  Hybrid Ontoprocedural Encoding: Real Organic Datasets'
Write-Host '======================================================================'
Write-Host "  Data dir   : $DataDir"
Write-Host "  Timestamp  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host '======================================================================'

# ═════════════════════════════════════════════════════════════════════════════
# DATASET 1: COVID-19 Countries Aggregated CSV
# Structure: 198 countries × 816 dates = 161,568 rows (sorted Country/Date)
# Procedural: dates (formula), countries (dictionary)
# Organic: Confirmed, Recovered, Deaths (3 integer columns)
# ═════════════════════════════════════════════════════════════════════════════

Write-Host ''
Write-Host '[1/3] COVID-19 Countries Aggregated CSV'
Write-Host '      Analisando estrutura e medindo baselines...'

$covidPath = Join-Path $DataDir 'covid_countries_aggregated.csv'
$sw1 = [System.Diagnostics.Stopwatch]::StartNew()

# Measure baselines
$b1 = Measure-Compressed $covidPath
Write-Host ("      Original: {0}  GZip: {1}  Brotli: {2}" -f (Format-Bytes $b1.Original),(Format-Bytes $b1.GZip),(Format-Bytes $b1.Brotli))

# Detect line ending from raw bytes
$rawCovid = [System.IO.File]::ReadAllBytes($covidPath)
$hasCRLF  = ($rawCovid | Where-Object { $_ -eq 13 } | Measure-Object).Count -gt 0
$nlBytes  = if ($hasCRLF) { [byte[]](13, 10) } else { [byte[]](10) }
$nlStr    = if ($hasCRLF) { "`r`n" } else { "`n" }

# Parse CSV using raw string split for speed
$utf8     = [System.Text.UTF8Encoding]::new($false)
$rawText  = $utf8.GetString($rawCovid)
$allLines = $rawText -split $nlStr
# Remove trailing empty line
if ($allLines[-1] -eq '') { $allLines = $allLines[0..($allLines.Count - 2)] }
$header   = $allLines[0]  # "Date,Country,Confirmed,Recovered,Deaths"
$dataLines = $allLines[1..($allLines.Count - 1)]

Write-Host "      Rows: $($dataLines.Count)  Header: [$header]"

# Extract unique countries IN ORDER of appearance (first occurrence per country)
$countries   = [System.Collections.Generic.List[string]]::new()
$seen        = [System.Collections.Generic.HashSet[string]]::new()
$dateStart   = ''
$dateCount   = 0

foreach ($line in $dataLines) {
    $comma1 = $line.IndexOf(',')
    $comma2 = $line.IndexOf(',', $comma1 + 1)
    $d = $line.Substring(0, $comma1)
    $c = $line.Substring($comma1 + 1, $comma2 - $comma1 - 1)
    if ($seen.Add($c)) {
        $countries.Add($c)
        if ($dateStart -eq '') { $dateStart = $d }
    }
    if ($countries.Count -eq 1) { $dateCount++ }
}

Write-Host "      Countries: $($countries.Count)  DateStart: $dateStart  DateCount: $dateCount"

# Extract ONLY the organic columns (Confirmed,Recovered,Deaths) as a flat text blob
# Row order: Country outer, Date inner (exactly as in the file)
$organicLines = [System.Collections.Generic.List[string]]::new($dataLines.Count)
foreach ($line in $dataLines) {
    $p1 = $line.IndexOf(',')
    $p2 = $line.IndexOf(',', $p1 + 1)
    $organicLines.Add($line.Substring($p2 + 1))
}
$organicText  = [string]::Join("`n", $organicLines)
$organicBytes = $utf8.GetBytes($organicText)

Write-Host ("      Coluna orgânica: {0}  Comprimindo com Brotli..." -f (Format-Bytes $organicBytes.Length))
# Binary seed: raw Brotli bytes saved to .bin (no Base64 overhead)
$msBin = New-Object System.IO.MemoryStream
$bsBin = New-Object System.IO.Compression.BrotliStream($msBin, [System.IO.Compression.CompressionLevel]::SmallestSize, $true)
$bsBin.Write($organicBytes, 0, $organicBytes.Length); $bsBin.Dispose()
$rawBlobBytes = $msBin.ToArray()
$blobSize     = $rawBlobBytes.Length

Write-Host ("      Brotli blob (raw binary): {0}" -f (Format-Bytes $blobSize))

# Build seed: JSON meta + binary blob (two files, zero Base64 overhead)
$seed1Meta = [ordered]@{
    format     = 'teia_covid_hybrid_v1_binary'
    date_start = $dateStart
    date_step  = 1
    date_count = $dateCount
    countries  = $countries.ToArray()
    newline    = if ($hasCRLF) { 'crlf' } else { 'lf' }
    header     = $header
    data_blob  = 'seed_covid_data.bin'
}
$seedMetaJson = $seed1Meta | ConvertTo-Json -Depth 10 -Compress
$seedMetaPath = "$OutputDir\seeds\seed_covid_meta.json"
$seedBinPath  = "$OutputDir\seeds\seed_covid_data.bin"
[System.IO.File]::WriteAllText($seedMetaPath, $seedMetaJson, $utf8)
[System.IO.File]::WriteAllBytes($seedBinPath, $rawBlobBytes)
$seedSize1 = (Get-Item $seedMetaPath).Length + (Get-Item $seedBinPath).Length
Write-Host ("      Seed (meta+bin): {0}" -f (Format-Bytes $seedSize1))

# ─── Decode ──────────────────────────────────────────────────────────────────
Write-Host '      Reconstruindo arquivo a partir do seed...'
$rebuildPath1 = "$OutputDir\rebuilt\covid_rebuilt.csv"

$s = Get-Content $seedMetaPath -Raw | ConvertFrom-Json

# Generate dates
$dates = [System.Collections.Generic.List[string]]::new($s.date_count)
$base  = [datetime]::Parse($s.date_start)
for ($i = 0; $i -lt $s.date_count; $i++) {
    $dates.Add($base.AddDays($i).ToString('yyyy-MM-dd'))
}

# Decompress organic data from binary blob
$binData  = [System.IO.File]::ReadAllBytes($seedBinPath)
$msDec    = New-Object System.IO.MemoryStream($binData, 0, $binData.Length)
$bsDec    = New-Object System.IO.Compression.BrotliStream($msDec, [System.IO.Compression.CompressionMode]::Decompress)
$msOut    = New-Object System.IO.MemoryStream
$bsDec.CopyTo($msOut); $bsDec.Dispose()
$orgText  = $utf8.GetString($msOut.ToArray())
$orgArr   = $orgText -split "`n"
$nlWrite  = if ($s.newline -eq 'crlf') { "`r`n" } else { "`n" }

# Write reconstructed CSV
$sw = [System.IO.StreamWriter]::new($rebuildPath1, $false, $utf8)
$sw.Write($s.header + $nlWrite)
$idx = 0
foreach ($country in $s.countries) {
    foreach ($date in $dates) {
        $sw.Write("$date,$country,$($orgArr[$idx])$nlWrite")
        $idx++
    }
}
$sw.Close()

# Verify SHA-256
$hashOrig = (Get-FileHash $covidPath    -Algorithm SHA256).Hash.ToLower()
$hashReb  = (Get-FileHash $rebuildPath1 -Algorithm SHA256).Hash.ToLower()
$sha1Pass = $hashOrig -eq $hashReb
$verdict1 = if ($sha1Pass) { 'SHA-256 PASS' } else { 'SHA-256 FAIL' }

# Write decoder script
$decoderContent1 = @"
#Requires -Version 7
[CmdletBinding()]
param([string]`$SeedMetaFile, [string]`$SeedBinFile, [string]`$OutputFile)
`$utf8 = [System.Text.UTF8Encoding]::new(`$false)
`$s = Get-Content `$SeedMetaFile -Raw | ConvertFrom-Json
`$dates = @(); `$base = [datetime]::Parse(`$s.date_start)
for (`$i=0;`$i -lt `$s.date_count;`$i++) { `$dates += `$base.AddDays(`$i).ToString('yyyy-MM-dd') }
`$bin = [System.IO.File]::ReadAllBytes(`$SeedBinFile)
`$ms  = New-Object System.IO.MemoryStream(`$bin,0,`$bin.Length)
`$bs  = New-Object System.IO.Compression.BrotliStream(`$ms,[System.IO.Compression.CompressionMode]::Decompress)
`$o   = New-Object System.IO.MemoryStream; `$bs.CopyTo(`$o); `$bs.Dispose()
`$orgArr = `$utf8.GetString(`$o.ToArray()) -split '`n'
`$nl = if (`$s.newline -eq 'crlf') { "`r`n" } else { "`n" }
`$sw = [System.IO.StreamWriter]::new(`$OutputFile, `$false, `$utf8)
`$sw.Write(`$s.header + `$nl)
`$idx = 0
foreach (`$country in `$s.countries) { foreach (`$date in `$dates) { `$sw.Write("`$date,`$country,`$(`$orgArr[`$idx])`$nl"); `$idx++ } }
`$sw.Close()
"@
[System.IO.File]::WriteAllText("$OutputDir\decoders\Decode-covid.ps1", $decoderContent1, $utf8)
$decSize1 = (Get-Item "$OutputDir\decoders\Decode-covid.ps1").Length

$totalTeia1 = $seedSize1 + $decSize1
$bestCls1   = [Math]::Min($b1.GZip, $b1.Brotli)
$delta1     = Pct-Delta $totalTeia1 $bestCls1
$sw1.Stop()

Write-Host ("      [{0}] Seed+Decoder: {1}  vs Brotli: {2}  Delta (Ganho): {3}  ({4:F1}s)" -f $verdict1,(Format-Bytes $totalTeia1),(Format-Bytes $bestCls1),$delta1,($sw1.Elapsed.TotalSeconds))


# ═════════════════════════════════════════════════════════════════════════════
# DATASET 2: Countries JSON (250 world countries reference database)
# Structure: 250 country objects, high-entropy translations/names
# Procedural: region, subregion, landlocked, unMember, status (low-cardinality)
# Organic: translations, native names, alt spellings (dominate the size)
# ═════════════════════════════════════════════════════════════════════════════

Write-Host ''
Write-Host '[2/3] Countries Reference JSON'
Write-Host '      Analisando estrutura e medindo baselines...'

$countriesPath = Join-Path $DataDir 'countries.json'
$sw2 = [System.Diagnostics.Stopwatch]::StartNew()

$b2 = Measure-Compressed $countriesPath
Write-Host ("      Original: {0}  GZip: {1}  Brotli: {2}" -f (Format-Bytes $b2.Original),(Format-Bytes $b2.GZip),(Format-Bytes $b2.Brotli))

# For countries.json, the dominant size is translations + native names (high entropy)
# TEIA strategy: keep sparse structural fields literal; Brotli-compress remainder
# We separate: (a) structural lookup [cca2,cca3,region,subregion,landlocked,unMember,latlng,area,borders]
#              (b) organic content [everything else] → Brotli blob

$countriesRaw = [System.IO.File]::ReadAllBytes($countriesPath)
$countriesText = [System.Text.UTF8Encoding]::new($false).GetString($countriesRaw)
$items = $countriesText | ConvertFrom-Json

Write-Host "      Records: $($items.Count)"

# Extract structural fields (the ones that are low-cardinality or formula-derivable)
$structural = $items | ForEach-Object {
    [ordered]@{
        cca2        = $_.cca2
        cca3        = $_.cca3
        ccn3        = $_.ccn3
        cioc        = $_.cioc
        region      = $_.region
        subregion   = $_.subregion
        landlocked  = $_.landlocked
        unMember    = $_.unMember
        independent = $_.independent
        status      = $_.status
        area        = $_.area
        latlng      = $_.latlng
        borders     = $_.borders
    }
}
$structText  = ($structural | ConvertTo-Json -Depth 10 -Compress)
$structBytes = $utf8.GetBytes($structText)
Write-Host ("      Campos estruturais: {0}" -f (Format-Bytes $structBytes.Length))

# Organic content: Brotli-compress full original (countries.json is mostly reference data)
# TEIA hybrid: structural lookup (literal JSON ~50KB) + Brotli blob of full content
$fullBrotliBlob = Compress-Brotli-B64 $countriesRaw
$blobRawSize    = [Convert]::FromBase64String($fullBrotliBlob).Length
Write-Host ("      Brotli blob (full): {0}" -f (Format-Bytes $blobRawSize))

# Build seed: structural fields as-is + Brotli of organic remainder
# For honest P22: we store the FULL Brotli-compressed content plus structural index
# This allows reconstruction but the gain is small (we're just repackaging Brotli)
$structBrotliBlob = Compress-Brotli-B64 $structBytes

$seed2 = [ordered]@{
    format           = 'teia_countries_hybrid_v1'
    count            = $items.Count
    structural_brotli = $structBrotliBlob
    full_brotli      = $fullBrotliBlob
}
$seed2Json = $seed2 | ConvertTo-Json -Depth 10 -Compress
$seedPath2 = "$OutputDir\seeds\seed_countries.json"
[System.IO.File]::WriteAllText($seedPath2, $seed2Json, $utf8)
$seedSize2 = (Get-Item $seedPath2).Length
Write-Host ("      Seed JSON: {0}" -f (Format-Bytes $seedSize2))

# Decode: decompress full_brotli blob → write output
$rebuildPath2 = "$OutputDir\rebuilt\countries_rebuilt.json"

$s2       = Get-Content $seedPath2 -Raw | ConvertFrom-Json
$outBytes = Decompress-Brotli-B64 $s2.full_brotli
[System.IO.File]::WriteAllBytes($rebuildPath2, $outBytes)

$hashOrig2 = (Get-FileHash $countriesPath  -Algorithm SHA256).Hash.ToLower()
$hashReb2  = (Get-FileHash $rebuildPath2   -Algorithm SHA256).Hash.ToLower()
$sha2Pass  = $hashOrig2 -eq $hashReb2
$verdict2  = if ($sha2Pass) { 'SHA-256 PASS' } else { 'SHA-256 FAIL' }

$decoderContent2 = @"
#Requires -Version 7
[CmdletBinding()]
param([string]`$SeedFile, [string]`$OutputFile)
function Decomp([string]`$b64) {
    `$c=([Convert]::FromBase64String(`$b64))
    `$ms=New-Object System.IO.MemoryStream(`$c,0,`$c.Length)
    `$bs=New-Object System.IO.Compression.BrotliStream(`$ms,[System.IO.Compression.CompressionMode]::Decompress)
    `$o=New-Object System.IO.MemoryStream;`$bs.CopyTo(`$o);`$bs.Dispose();`$o.ToArray()
}
`$s = Get-Content `$SeedFile -Raw | ConvertFrom-Json
[System.IO.File]::WriteAllBytes(`$OutputFile, (Decomp `$s.full_brotli))
"@
[System.IO.File]::WriteAllText("$OutputDir\decoders\Decode-countries.ps1", $decoderContent2, $utf8)
$decSize2 = (Get-Item "$OutputDir\decoders\Decode-countries.ps1").Length

$totalTeia2 = $seedSize2 + $decSize2
$bestCls2   = [Math]::Min($b2.GZip, $b2.Brotli)
$delta2     = Pct-Delta $totalTeia2 $bestCls2
$sw2.Stop()

Write-Host ("      [{0}] Seed+Decoder: {1}  vs Brotli: {2}  Delta (Ganho): {3}  ({4:F1}s)" -f $verdict2,(Format-Bytes $totalTeia2),(Format-Bytes $bestCls2),$delta2,($sw2.Elapsed.TotalSeconds))


# ═════════════════════════════════════════════════════════════════════════════
# DATASET 3: World Bank GDP per capita JSON (6650 records)
# Structure: 250 countries × ~25 years, constant indicator, constant unit/obs
# Procedural: date years (formula), indicator (constant), unit (constant)
# Organic: GDP value floats (high entropy)
# ═════════════════════════════════════════════════════════════════════════════

Write-Host ''
Write-Host '[3/3] World Bank GDP per capita JSON'
Write-Host '      Analisando estrutura e medindo baselines...'

$wbPath = Join-Path $DataDir 'worldbank_gdp.json'
$sw3 = [System.Diagnostics.Stopwatch]::StartNew()

$b3 = Measure-Compressed $wbPath
Write-Host ("      Original: {0}  GZip: {1}  Brotli: {2}" -f (Format-Bytes $b3.Original),(Format-Bytes $b3.GZip),(Format-Bytes $b3.Brotli))

$wbRaw  = [System.IO.File]::ReadAllBytes($wbPath)
$wbText = $utf8.GetString($wbRaw)
$wbFull = $wbText | ConvertFrom-Json
$wbMeta = $wbFull[0]   # {"page":1,...}
$wbData = $wbFull[1]   # array of 6650 records

Write-Host "      Records: $($wbData.Count)  Total API: $($wbMeta.total)"

# TEIA strategy: constant indicator extracted once; country+code lookup table;
# date+value as parallel arrays (date is formula-ish, value is organic float)

# Extract country lookup (unique country objects in order of appearance)
$ctryLookup   = [System.Collections.Generic.List[object]]::new()
$ctryIdxMap   = [System.Collections.Generic.Dictionary[string,int]]::new()
$ctrySeenKeys = [System.Collections.Generic.HashSet[string]]::new()

foreach ($rec in $wbData) {
    $key = "$($rec.country.id)|$($rec.countryiso3code)"
    if ($ctrySeenKeys.Add($key)) {
        $ctryIdxMap[$key] = $ctryLookup.Count
        $ctryLookup.Add([ordered]@{ id = $rec.country.id; value = $rec.country.value; iso3 = $rec.countryiso3code })
    }
}
Write-Host "      Unique countries: $($ctryLookup.Count)"

# Extract structure per record: countryIdx, date, decimal (rest is constant)
# Build parallel arrays
$recCountryIdx = [int[]]::new($wbData.Count)
$recDate       = [string[]]::new($wbData.Count)
$recDecimal    = [int[]]::new($wbData.Count)
$recValue      = [double[]]::new($wbData.Count)

for ($i = 0; $i -lt $wbData.Count; $i++) {
    $rec = $wbData[$i]
    $key = "$($rec.country.id)|$($rec.countryiso3code)"
    $recCountryIdx[$i] = $ctryIdxMap[$key]
    $recDate[$i]       = $rec.date
    $recDecimal[$i]    = [int]$rec.decimal
    $recValue[$i]      = if ($null -eq $rec.value) { [double]::NaN } else { [double]$rec.value }
}

# Build organic data blob: "value\n" per record (floats as they appear in original JSON)
# For exact reconstruction, we need to preserve the exact original JSON float representation
# Strategy: extract the raw JSON value text from each record
$valueTexts = [System.Collections.Generic.List[string]]::new($wbData.Count)
$inDateList = [System.Collections.Generic.List[string]]::new($wbData.Count)
$inDecList  = [System.Collections.Generic.List[string]]::new($wbData.Count)

for ($i = 0; $i -lt $wbData.Count; $i++) {
    $rec = $wbData[$i]
    $valStr = if ($null -eq $rec.value) { 'null' } else { "$($rec.value)" }
    $valueTexts.Add($valStr)
    $inDateList.Add($rec.date)
    $inDecList.Add("$($rec.decimal)")
}

# Organic data: value strings joined by newline
$valBlob      = [string]::Join("`n", $valueTexts)
$valBlobBytes = $utf8.GetBytes($valBlob)
Write-Host ("      Blob valores: {0}" -f (Format-Bytes $valBlobBytes.Length))
$valBrotliB64 = Compress-Brotli-B64 $valBlobBytes
$valBlobSize  = [Convert]::FromBase64String($valBrotliB64).Length
Write-Host ("      Brotli blob: {0}" -f (Format-Bytes $valBlobSize))

# For exact JSON reconstruction, we also need date and decimal per record
# (decimal varies: mostly 0 or 1)
$dateBlob      = [string]::Join("`n", $inDateList)
$dateB64       = Compress-Brotli-B64 ($utf8.GetBytes($dateBlob))
$decBlob       = [string]::Join("`n", $inDecList)
$decB64        = Compress-Brotli-B64 ($utf8.GetBytes($decBlob))
$ctryIdxBlob   = [string]::Join("`n", $recCountryIdx)
$ctryIdxB64    = Compress-Brotli-B64 ($utf8.GetBytes($ctryIdxBlob))

$seed3 = [ordered]@{
    format          = 'teia_worldbank_hybrid_v1'
    total_records   = $wbData.Count
    metadata        = [ordered]@{
        page = [int]$wbMeta.page; pages = [int]$wbMeta.pages
        per_page = [int]$wbMeta.per_page; total = [int]$wbMeta.total
        sourceid = "$($wbMeta.sourceid)"; lastupdated = "$($wbMeta.lastupdated)"
    }
    indicator_id    = "$($wbData[0].indicator.id)"
    indicator_value = "$($wbData[0].indicator.value)"
    countries       = $ctryLookup.ToArray()
    country_idx     = $ctryIdxB64
    dates           = $dateB64
    decimals        = $decB64
    values          = $valBrotliB64
}
$seed3Json = $seed3 | ConvertTo-Json -Depth 10 -Compress
$seedPath3 = "$OutputDir\seeds\seed_worldbank.json"
[System.IO.File]::WriteAllText($seedPath3, $seed3Json, $utf8)
$seedSize3 = (Get-Item $seedPath3).Length
Write-Host ("      Seed JSON: {0}" -f (Format-Bytes $seedSize3))

# ─── Decode World Bank ────────────────────────────────────────────────────────
Write-Host '      Reconstruindo JSON a partir do seed...'
$rebuildPath3 = "$OutputDir\rebuilt\worldbank_rebuilt.json"

$s3 = Get-Content $seedPath3 -Raw | ConvertFrom-Json

$decCtryIdx = ($utf8.GetString((Decompress-Brotli-B64 $s3.country_idx)) -split "`n") | ForEach-Object { [int]$_ }
$decDates   = $utf8.GetString((Decompress-Brotli-B64 $s3.dates))   -split "`n"
$decDecs    = $utf8.GetString((Decompress-Brotli-B64 $s3.decimals)) -split "`n"
$decVals    = $utf8.GetString((Decompress-Brotli-B64 $s3.values))   -split "`n"

$ctries = $s3.countries

# Reconstruct JSON matching World Bank API format exactly
$sb = [System.Text.StringBuilder]::new()
$sb.Append('[{"page":') | Out-Null
$sb.Append($s3.metadata.page) | Out-Null
$sb.Append(',"pages":') | Out-Null; $sb.Append($s3.metadata.pages) | Out-Null
$sb.Append(',"per_page":') | Out-Null; $sb.Append($s3.metadata.per_page) | Out-Null
$sb.Append(',"total":') | Out-Null; $sb.Append($s3.metadata.total) | Out-Null
$sb.Append(',"sourceid":"') | Out-Null; $sb.Append($s3.metadata.sourceid) | Out-Null
$sb.Append('","lastupdated":"') | Out-Null; $sb.Append($s3.metadata.lastupdated) | Out-Null
$sb.Append('"},[') | Out-Null

for ($i = 0; $i -lt $s3.total_records; $i++) {
    if ($i -gt 0) { $sb.Append(',') | Out-Null }
    $ci = $decCtryIdx[$i]
    $ct = $ctries[$ci]
    $valRaw = $decVals[$i]
    $sb.Append('{"indicator":{"id":"') | Out-Null
    $sb.Append($s3.indicator_id) | Out-Null
    $sb.Append('","value":"') | Out-Null
    $sb.Append($s3.indicator_value) | Out-Null
    $sb.Append('"},"country":{"id":"') | Out-Null
    $sb.Append($ct.id) | Out-Null
    $sb.Append('","value":"') | Out-Null
    $sb.Append($ct.value) | Out-Null
    $sb.Append('"},"countryiso3code":"') | Out-Null
    $sb.Append($ct.iso3) | Out-Null
    $sb.Append('","date":"') | Out-Null
    $sb.Append($decDates[$i]) | Out-Null
    $sb.Append('","value":') | Out-Null
    $sb.Append($valRaw) | Out-Null
    $sb.Append(',"unit":"","obs_status":"","decimal":') | Out-Null
    $sb.Append($decDecs[$i]) | Out-Null
    $sb.Append('}') | Out-Null
}
$sb.Append(']]') | Out-Null

$outBytes3 = $utf8.GetBytes($sb.ToString())
[System.IO.File]::WriteAllBytes($rebuildPath3, $outBytes3)

$hashOrig3 = (Get-FileHash $wbPath      -Algorithm SHA256).Hash.ToLower()
$hashReb3  = (Get-FileHash $rebuildPath3 -Algorithm SHA256).Hash.ToLower()
$sha3Pass  = $hashOrig3 -eq $hashReb3
$verdict3  = if ($sha3Pass) { 'SHA-256 PASS' } else { 'SHA-256 FAIL' }

$decoderContent3 = @"
#Requires -Version 7
[CmdletBinding()]
param([string]`$SeedFile, [string]`$OutputFile)
`$utf8 = [System.Text.UTF8Encoding]::new(`$false)
function Decomp([string]`$b64) {
    `$c=([Convert]::FromBase64String(`$b64))
    `$ms=New-Object System.IO.MemoryStream(`$c,0,`$c.Length)
    `$bs=New-Object System.IO.Compression.BrotliStream(`$ms,[System.IO.Compression.CompressionMode]::Decompress)
    `$o=New-Object System.IO.MemoryStream;`$bs.CopyTo(`$o);`$bs.Dispose();`$o.ToArray()
}
`$s = Get-Content `$SeedFile -Raw | ConvertFrom-Json
`$ctryIdx = (`$utf8.GetString((Decomp `$s.country_idx)) -split '`n') | % { [int]`$_ }
`$dates   = `$utf8.GetString((Decomp `$s.dates))   -split '`n'
`$decs    = `$utf8.GetString((Decomp `$s.decimals)) -split '`n'
`$vals    = `$utf8.GetString((Decomp `$s.values))   -split '`n'
`$ctries  = `$s.countries
`$sb = [System.Text.StringBuilder]::new()
`$sb.Append('[{"page":'+`$s.metadata.page+',"pages":'+`$s.metadata.pages+',"per_page":'+`$s.metadata.per_page+',"total":'+`$s.metadata.total+',"sourceid":"'+`$s.metadata.sourceid+'","lastupdated":"'+`$s.metadata.lastupdated+'"},[') | Out-Null
for (`$i=0;`$i -lt `$s.total_records;`$i++) {
    if (`$i -gt 0) { `$sb.Append(',') | Out-Null }
    `$ci=`$ctryIdx[`$i]; `$ct=`$ctries[`$ci]
    `$sb.Append('{"indicator":{"id":"'+`$s.indicator_id+'","value":"'+`$s.indicator_value+'"},"country":{"id":"'+`$ct.id+'","value":"'+`$ct.value+'"},"countryiso3code":"'+`$ct.iso3+'","date":"'+`$dates[`$i]+'","value":'+`$vals[`$i]+',"unit":"","obs_status":"","decimal":'+`$decs[`$i]+'}') | Out-Null
}
`$sb.Append(']]') | Out-Null
[System.IO.File]::WriteAllBytes(`$OutputFile, `$utf8.GetBytes(`$sb.ToString()))
"@
[System.IO.File]::WriteAllText("$OutputDir\decoders\Decode-worldbank.ps1", $decoderContent3, $utf8)
$decSize3 = (Get-Item "$OutputDir\decoders\Decode-worldbank.ps1").Length

$totalTeia3 = $seedSize3 + $decSize3
$bestCls3   = [Math]::Min($b3.GZip, $b3.Brotli)
$delta3     = Pct-Delta $totalTeia3 $bestCls3
$sw3.Stop()

Write-Host ("      [{0}] Seed+Decoder: {1}  vs Brotli: {2}  Delta (Ganho): {3}  ({4:F1}s)" -f $verdict3,(Format-Bytes $totalTeia3),(Format-Bytes $bestCls3),$delta3,($sw3.Elapsed.TotalSeconds))


# ═════════════════════════════════════════════════════════════════════════════
# RESULTS TABLE
# ═════════════════════════════════════════════════════════════════════════════

Write-Host ''
Write-Host '======================================================================'
Write-Host '  P22.0 RESULTADOS — MUNDO REAL'
Write-Host '======================================================================'
Write-Host ''
$fmt = '{0,-34} {1,10} {2,10} {3,12} {4,15} {5,8}'
Write-Host ($fmt -f 'Arquivo','Original','Brotli','TEIA Hybrid','Delta (Ganho)','SHA-256')
Write-Host ($fmt -f ('─'*34),('─'*10),('─'*10),('─'*12),('─'*15),('─'*8))

$row1 = @($sha1Pass,$b1.Original,$b1.Brotli,$totalTeia1,$delta1,'covid_countries_aggregated.csv')
$row2 = @($sha2Pass,$b2.Original,$b2.Brotli,$totalTeia2,$delta2,'countries.json')
$row3 = @($sha3Pass,$b3.Original,$b3.Brotli,$totalTeia3,$delta3,'worldbank_gdp.json')

foreach ($row in @($row1,$row2,$row3)) {
    $pass    = [bool]$row[0]
    $orig    = [long]$row[1]
    $brotli  = [long]$row[2]
    $teia    = [long]$row[3]
    $delta   = $row[4]
    $name    = $row[5]
    $sha     = if ($pass) { 'PASS' } else { 'FAIL' }
    $color   = if ($pass) { 'Green' } else { 'Red' }
    Write-Host ($fmt -f $name,(Format-Bytes $orig),(Format-Bytes $brotli),(Format-Bytes $teia),$delta,$sha) -ForegroundColor $color
}

Write-Host ''
$allPass = $sha1Pass -and $sha2Pass -and $sha3Pass
$passCount = @($sha1Pass,$sha2Pass,$sha3Pass).Where({$_}).Count

Write-Host "  SHA-256: $passCount/3 PASS"

# Delta analysis
$wins = 0
foreach ($row in @(($totalTeia1,$bestCls1),($totalTeia2,$bestCls2),($totalTeia3,$bestCls3))) {
    if ([long]$row[0] -lt [long]$row[1]) { $wins++ }
}
Write-Host "  Delta positivo (TEIA < Brotli): $wins/3 datasets"
Write-Host ''
Write-Host '======================================================================'

# Save results JSON
$results = [ordered]@{
    protocol  = 'P22.0'
    timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    datasets  = @(
        [ordered]@{ name='covid_countries_aggregated.csv'; original=$b1.Original; gzip=$b1.GZip; brotli=$b1.Brotli; teia=($totalTeia1); seed=$seedSize1; decoder=$decSize1; delta=$delta1; sha256=if($sha1Pass){'PASS'}else{'FAIL'}; hash_original=$hashOrig; hash_rebuilt=$hashReb }
        [ordered]@{ name='countries.json';                 original=$b2.Original; gzip=$b2.GZip; brotli=$b2.Brotli; teia=($totalTeia2); seed=$seedSize2; decoder=$decSize2; delta=$delta2; sha256=if($sha2Pass){'PASS'}else{'FAIL'}; hash_original=$hashOrig2; hash_rebuilt=$hashReb2 }
        [ordered]@{ name='worldbank_gdp.json';             original=$b3.Original; gzip=$b3.GZip; brotli=$b3.Brotli; teia=($totalTeia3); seed=$seedSize3; decoder=$decSize3; delta=$delta3; sha256=if($sha3Pass){'PASS'}else{'FAIL'}; hash_original=$hashOrig3; hash_rebuilt=$hashReb3 }
    )
}
$results | ConvertTo-Json -Depth 10 | Set-Content "$OutputDir\p22_results.json" -Encoding UTF8
Write-Host "  Resultados salvos em: $OutputDir\p22_results.json"
Write-Host ''
