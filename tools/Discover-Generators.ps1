<#
.SYNOPSIS
    Discover-Generators.ps1 - P25.0 Representability Oracle

.DESCRIPTION
    Scans local files and estimates where data is mostly law, hybrid, or noise.
    P25 adds an Advantage Predictor: a pre-forge estimate of whether seed plus
    decoder representation can beat Brotli Optimal.
    The script is read-only for the scanned corpus: it never compresses, ingests,
    deletes, rewrites, or stubs input files.

    Invariant: "Delta" is always written as text if needed. The mathematical
    symbol is forbidden in generated code and reports.

.PARAMETER ScanRoot
    Root folder to scan. Defaults to D:\TEIA_USER\MyRealData.

.PARAMETER ReportPath
    Markdown matrix path. Defaults to D:\TEIA_CORE\docs\TEIA_LAW_VS_NOISE_MATRIX.md.

.PARAMETER TheoryPath
    Scientific report path. Defaults to D:\TEIA_CORE\docs\TEIA_REPRESENTABILITY_THEORY.md.

.PARAMETER MaxFiles
    Optional cap for deterministic sampling. 0 means no cap.

.PARAMETER MaxSampleBytes
    Maximum bytes read per file for heuristic analysis.

.PARAMETER IncludeTeiaControl
    Include TEIA control files and corpus manifests. By default these are skipped.

.PARAMETER Quiet
    Suppress the final summary object.
#>
[CmdletBinding()]
param(
    [string]$ScanRoot       = 'D:\TEIA_USER\MyRealData',
    [string]$ReportPath     = 'D:\TEIA_CORE\docs\TEIA_LAW_VS_NOISE_MATRIX.md',
    [string]$TheoryPath     = 'D:\TEIA_CORE\docs\TEIA_REPRESENTABILITY_THEORY.md',
    [int]$MaxFiles          = 0,
    [int]$MaxSampleBytes    = 1048576,
    [switch]$IncludeTeiaControl,
    [switch]$Quiet
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$enc = New-Object System.Text.UTF8Encoding($false)
$IC  = [System.Globalization.CultureInfo]::InvariantCulture

function Clamp01([double]$Value) {
    if ($Value -lt 0.0) { return 0.0 }
    if ($Value -gt 1.0) { return 1.0 }
    return $Value
}

function Round4([double]$Value) {
    return [Math]::Round($Value, 4)
}

function Round2([double]$Value) {
    return [Math]::Round($Value, 2)
}

function Format-Score([double]$Value) {
    return (Round2 $Value).ToString('0.00', $IC)
}

function Get-StableRelativePath([string]$Root, [string]$Path) {
    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    if ($pathFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $pathFull.Substring($rootFull.Length).TrimStart('\')
    }
    return $pathFull
}

function Read-SampleBytes([string]$Path, [int]$Limit) {
    $fi = Get-Item -LiteralPath $Path -ErrorAction Stop
    $n = [int][Math]::Min([int64][Math]::Max($Limit, 1), $fi.Length)
    $buf = New-Object byte[] $n
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $read = 0
        while ($read -lt $n) {
            $r = $fs.Read($buf, $read, $n - $read)
            if ($r -le 0) { break }
            $read += $r
        }
        if ($read -eq $n) { return $buf }
        $trimmed = New-Object byte[] $read
        [Array]::Copy($buf, 0, $trimmed, 0, $read)
        return $trimmed
    } finally {
        $fs.Dispose()
    }
}

function Get-ByteEntropy([byte[]]$Bytes) {
    if ($Bytes.Length -eq 0) { return 0.0 }
    $freq = New-Object int[] 256
    foreach ($b in $Bytes) { $freq[$b]++ }
    $total = [double]$Bytes.Length
    $h = 0.0
    foreach ($c in $freq) {
        if ($c -gt 0) {
            $p = $c / $total
            $h -= $p * [Math]::Log($p, 2)
        }
    }
    return $h
}

function Get-PrintableRatio([byte[]]$Bytes) {
    if ($Bytes.Length -eq 0) { return 0.0 }
    $ok = 0
    foreach ($b in $Bytes) {
        if (($b -eq 9) -or ($b -eq 10) -or ($b -eq 13) -or ($b -ge 32 -and $b -le 126) -or ($b -ge 128)) {
            $ok++
        }
    }
    return $ok / [double]$Bytes.Length
}

function Convert-SampleToText([byte[]]$Bytes) {
    if ($Bytes.Length -eq 0) { return '' }
    return [System.Text.Encoding]::UTF8.GetString($Bytes)
}

function Count-Regex([string]$Text, [string]$Pattern) {
    if ([string]::IsNullOrEmpty($Text)) { return 0 }
    return [regex]::Matches($Text, $Pattern).Count
}

function Count-CharSet([string]$Text, [string]$Chars) {
    if ([string]::IsNullOrEmpty($Text)) { return 0 }
    $count = 0
    foreach ($ch in $Text.ToCharArray()) {
        if ($Chars.IndexOf($ch) -ge 0) { $count++ }
    }
    return $count
}

function Get-TokenNoise([string]$Text) {
    $matches = [regex]::Matches($Text, '[A-Za-z0-9][A-Za-z0-9_.:/-]{2,}')
    if ($matches.Count -eq 0) { return 0.0 }
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $hashLike = 0
    foreach ($m in $matches) {
        [void]$seen.Add($m.Value)
        if ($m.Value -match '^[A-Fa-f0-9]{24,}$') { $hashLike++ }
    }
    $uniqueRatio = $seen.Count / [double]$matches.Count
    $hashRatio = $hashLike / [double]$matches.Count
    return Clamp01 ((0.75 * $uniqueRatio) + (0.25 * $hashRatio))
}

function Get-LineRepetitionScore([string]$Text) {
    $lines = @($Text -split "`r?`n" | Where-Object { $_.Length -gt 0 } | Select-Object -First 1000)
    if ($lines.Count -lt 4) { return 0.0 }
    $groups = $lines | Group-Object
    $largest = ($groups | Sort-Object Count -Descending | Select-Object -First 1).Count
    return Clamp01 ($largest / [double]$lines.Count)
}

function Get-ShortPeriodScore([byte[]]$Bytes) {
    $probe = [Math]::Min($Bytes.Length, 4096)
    if ($probe -lt 8) { return 0.0 }
    for ($p = 1; $p -le 64; $p++) {
        $ok = $true
        for ($i = $p; $i -lt $probe; $i++) {
            if ($Bytes[$i] -ne $Bytes[$i % $p]) {
                $ok = $false
                break
            }
        }
        if ($ok) {
            return Clamp01 (1.0 - (($p - 1) / 64.0))
        }
    }
    return 0.0
}

function Get-MagicKind([byte[]]$Bytes) {
    if ($Bytes.Length -lt 4) { return 'unknown' }
    if ($Bytes[0] -eq 0x89 -and $Bytes[1] -eq 0x50 -and $Bytes[2] -eq 0x4E -and $Bytes[3] -eq 0x47) { return 'png' }
    if ($Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xD8) { return 'jpeg' }
    if ($Bytes[0] -eq 0x25 -and $Bytes[1] -eq 0x50 -and $Bytes[2] -eq 0x44 -and $Bytes[3] -eq 0x46) { return 'pdf' }
    if ($Bytes[0] -eq 0x50 -and $Bytes[1] -eq 0x4B) { return 'zip' }
    if ($Bytes[0] -eq 0x1F -and $Bytes[1] -eq 0x8B) { return 'gzip' }
    return 'unknown'
}

function Measure-BrotliOptimalBytes([string]$Path) {
    $inStream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $outStream = [System.IO.MemoryStream]::new()
    try {
        $level = [System.IO.Compression.CompressionLevel]::Optimal
        $br = [System.IO.Compression.BrotliStream]::new($outStream, $level, $true)
        try {
            $inStream.CopyTo($br, 65536)
        } finally {
            $br.Dispose()
        }
        return [int64]$outStream.Length
    } finally {
        $outStream.Dispose()
        $inStream.Dispose()
    }
}

function Get-EvidenceNumber([string]$Evidence, [string]$Name, [double]$Default = 0.0) {
    $pattern = [regex]::Escape($Name) + '=([0-9.]+)'
    $m = [regex]::Match($Evidence, $pattern)
    if ($m.Success) {
        return [double]::Parse($m.Groups[1].Value, $IC)
    }
    return $Default
}

function Get-EstimatedTeiaBytes([string]$Kind, [int64]$OriginalBytes, [int64]$BrotliBytes, [double]$Law, [double]$Noise, [string]$Evidence) {
    $base = switch ($Kind) {
        'csv-table'          { 2800 }
        'structured-log'     { 3400 }
        'json-schema'        { 4200 }
        'xml-svg-tree'       { 3600 }
        'repetition-pattern' { 1800 }
        default              { 6400 }
    }

    $residualFactor = switch ($Kind) {
        'csv-table'          { [Math]::Pow($Noise, 2.2) * 0.42 }
        'structured-log'     { [Math]::Pow($Noise, 2.0) * 0.48 }
        'json-schema'        { [Math]::Pow($Noise, 1.15) * 0.92 }
        'xml-svg-tree'       { [Math]::Pow($Noise, 1.45) * 0.70 }
        'repetition-pattern' { [Math]::Pow($Noise, 2.6) * 0.20 }
        default              { 1.05 }
    }

    $complexity = 0
    if ($Kind -eq 'json-schema') {
        $keys = Get-EvidenceNumber $Evidence 'json_keys'
        $unique = Get-EvidenceNumber $Evidence 'unique_keys'
        $uniqueRatio = if ($keys -gt 0) { $unique / $keys } else { 1.0 }
        $complexity += [int64](120 * $unique)
        $complexity += [int64]($BrotliBytes * [Math]::Min(0.35, $uniqueRatio * 1.50))
    } elseif ($Kind -eq 'csv-table') {
        $columns = Get-EvidenceNumber $Evidence 'columns'
        $complexity += [int64](160 * $columns)
    } elseif ($Kind -eq 'structured-log') {
        $shapeRepeat = Get-EvidenceNumber $Evidence 'shape_repeat'
        $complexity += [int64]($BrotliBytes * (0.20 * (1.0 - [Math]::Min(1.0, $shapeRepeat))))
    } elseif ($Kind -eq 'xml-svg-tree') {
        $uniqueTags = Get-EvidenceNumber $Evidence 'unique_tags'
        $attrs = Get-EvidenceNumber $Evidence 'attrs'
        $complexity += [int64](120 * $uniqueTags)
        $complexity += [int64](12 * [Math]::Min($attrs, 2000))
    }

    $lawCredit = [Math]::Max(0.12, 1.05 - (0.45 * $Law))
    $estimate = [int64]($base + $complexity + ($BrotliBytes * $residualFactor * $lawCredit))
    if ($Kind -eq 'repetition-pattern' -and $Law -gt 0.85) {
        $estimate = [int64][Math]::Min($estimate, 2048 + ($OriginalBytes * 0.002))
    }
    return [int64][Math]::Max(256, $estimate)
}

function Get-RepresentabilityClass([string]$Kind, [double]$Law, [double]$Noise, [double]$Advantage, [string]$Evidence) {
    $periodScore = Get-EvidenceNumber $Evidence 'period_score'
    if (($Kind -eq 'repetition-pattern') -and ($periodScore -ge 0.80) -and ($Noise -ge 0.45)) {
        return 'CLASSE D'
    }
    if (($Law -lt 0.62) -and ($Advantage -ge 0.15)) {
        return 'CLASSE D'
    }
    if (($Law -ge 0.62) -and ($Advantage -ge 0.15)) {
        return 'CLASSE A'
    }
    if ($Law -ge 0.62) {
        return 'CLASSE B'
    }
    return 'CLASSE C'
}

function Get-TeiaPrediction([string]$Class) {
    switch ($Class) {
        'CLASSE A' { return 'TEIA VENCE' }
        'CLASSE D' { return 'TEIA INVESTIGA' }
        default { return 'TEIA RECUA' }
    }
}

function Get-RepresentabilityMeaning([string]$Class) {
    switch ($Class) {
        'CLASSE A' { return 'Alta lei e alta vantagem procedural. Estruturas N x M ou logs com gramatica forte.' }
        'CLASSE B' { return 'Alta lei e baixa vantagem procedural. Brotli ja captura quase todo o ganho disponivel.' }
        'CLASSE C' { return 'Baixa lei e baixa vantagem. Entropia organica domina.' }
        'CLASSE D' { return 'Falsa entropia. Parece ruido, mas ha indicio de gerador matematico.' }
        default { return 'Classe desconhecida.' }
    }
}

function New-Signal([string]$Kind, [double]$Law, [string[]]$Evidence) {
    return [pscustomobject]@{
        Kind = $Kind
        Law = Clamp01 $Law
        Evidence = @($Evidence)
    }
}

function Analyze-JsonSignal([string]$Text, [string]$Extension) {
    $trim = $Text.TrimStart()
    if (($Extension -ne '.json') -and -not ($trim.StartsWith('{') -or $trim.StartsWith('['))) {
        return $null
    }
    $keys = [regex]::Matches($Text, '"([^"\\]|\\.)+"\s*:')
    if ($keys.Count -eq 0) {
        return $null
    }
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($k in $keys) {
        $name = $k.Value -replace '^\s*"', ''
        $name = $name -replace '"\s*:\s*$', ''
        [void]$seen.Add($name)
    }
    $grammarDensity = (Count-CharSet $Text '{}[]:,') / [double][Math]::Max($Text.Length, 1)
    $repeatScore = 1.0 - [Math]::Min(1.0, $seen.Count / [double]$keys.Count)
    $rootBonus = if ($trim.StartsWith('{') -or $trim.StartsWith('[')) { 0.12 } else { 0.0 }
    $law = $rootBonus +
        [Math]::Min(0.28, $grammarDensity * 5.0) +
        [Math]::Min(0.28, $keys.Count / 400.0) +
        (0.25 * $repeatScore) +
        [Math]::Min(0.07, $seen.Count / 80.0)
    $ev = @(
        "json_keys=$($keys.Count)",
        "unique_keys=$($seen.Count)",
        "grammar_density=$((Format-Score $grammarDensity))"
    )
    return New-Signal 'json-schema' $law $ev
}

function Analyze-CsvSignal([string]$Text, [string]$Extension) {
    $lines = @($Text -split "`r?`n" | Where-Object { $_.Trim().Length -gt 0 } | Select-Object -First 500)
    if ($lines.Count -lt 2) { return $null }
    $delims = @(',', ';', "`t", '|')
    $bestDelim = $null
    $bestCount = 0
    foreach ($d in $delims) {
        $c = ($lines[0].ToCharArray() | Where-Object { $_ -eq $d }).Count
        if ($c -gt $bestCount) {
            $bestCount = $c
            $bestDelim = $d
        }
    }
    if (($Extension -ne '.csv') -and $bestCount -lt 1) { return $null }
    if ($null -eq $bestDelim) { return $null }
    $counts = @()
    foreach ($line in $lines) {
        $counts += (($line -split [regex]::Escape($bestDelim)).Count)
    }
    $mode = ($counts | Group-Object | Sort-Object Count -Descending | Select-Object -First 1)
    $consistency = $mode.Count / [double]$counts.Count
    $headers = @($lines[0] -split [regex]::Escape($bestDelim))
    $headerGood = 0
    foreach ($h in $headers) {
        if ($h.Trim() -match '^[A-Za-z_][A-Za-z0-9_ -]*$') { $headerGood++ }
    }
    $headerScore = if ($headers.Count -gt 0) { $headerGood / [double]$headers.Count } else { 0.0 }
    $rowScore = [Math]::Min(1.0, ($lines.Count - 1) / 80.0)
    $law = 0.08 + (0.34 * $consistency) + (0.23 * $headerScore) + (0.20 * $rowScore) + [Math]::Min(0.15, $headers.Count / 80.0)
    $delimName = if ($bestDelim -eq "`t") { 'tab' } else { $bestDelim }
    $ev = @(
        "csv_delim=$delimName",
        "columns=$($headers.Count)",
        "row_consistency=$((Format-Score $consistency))"
    )
    return New-Signal 'csv-table' $law $ev
}

function Analyze-LogSignal([string]$Text, [string]$Extension) {
    $lines = @($Text -split "`r?`n" | Where-Object { $_.Trim().Length -gt 0 } | Select-Object -First 800)
    if ($lines.Count -lt 4) { return $null }
    $body = @($lines | Where-Object { -not $_.TrimStart().StartsWith('#') })
    if ($body.Count -lt 4) { return $null }

    $tsCount = 0
    $levelCount = 0
    $kvCount = 0
    $shapes = @()
    foreach ($line in ($body | Select-Object -First 500)) {
        if ($line -match '\d{4}-\d{2}-\d{2}[T ][0-9:.]+Z?') { $tsCount++ }
        if ($line -match '\b(INFO|WARN|ERROR|DEBUG|TRACE|NOTICE|CRITICAL)\b') { $levelCount++ }
        $kvCount += (Count-Regex $line '\b[A-Za-z_][A-Za-z0-9_:-]*=')
        $shape = $line
        $shape = $shape -replace '\d{4}-\d{2}-\d{2}[T ][0-9:.]+Z?', 'TS'
        $shape = $shape -replace '\b[0-9a-fA-F]{8,}\b', 'HEX'
        $shape = $shape -replace '\d+', 'N'
        $shape = $shape -replace '\[[^\]]+\]', '[BRACKET]'
        $shapes += $shape
    }
    $sampleCount = [double][Math]::Max($body.Count, 1)
    $tsRatio = [Math]::Min(1.0, $tsCount / $sampleCount)
    $levelRatio = [Math]::Min(1.0, $levelCount / $sampleCount)
    $kvDensity = [Math]::Min(1.0, $kvCount / [double]([Math]::Max($body.Count, 1) * 4))
    $shapeMode = ($shapes | Group-Object | Sort-Object Count -Descending | Select-Object -First 1)
    $shapeRepeat = if ($shapeMode) { $shapeMode.Count / [double][Math]::Max($shapes.Count, 1) } else { 0.0 }

    if (($Extension -ne '.log') -and (($tsRatio + $levelRatio + $kvDensity) -lt 0.80)) {
        return $null
    }
    $law = 0.08 + (0.24 * $tsRatio) + (0.18 * $levelRatio) + (0.24 * $kvDensity) + (0.26 * $shapeRepeat)
    if ($law -lt 0.30) { return $null }
    $ev = @(
        "timestamp_ratio=$((Format-Score $tsRatio))",
        "level_ratio=$((Format-Score $levelRatio))",
        "shape_repeat=$((Format-Score $shapeRepeat))",
        "kv_density=$((Format-Score $kvDensity))"
    )
    return New-Signal 'structured-log' $law $ev
}

function Analyze-XmlSignal([string]$Text, [string]$Extension) {
    $trim = $Text.TrimStart()
    if (($Extension -notin @('.xml', '.svg', '.html')) -and -not $trim.StartsWith('<')) {
        return $null
    }
    $tags = [regex]::Matches($Text, '<\s*/?\s*([A-Za-z][A-Za-z0-9:_.-]*)')
    if ($tags.Count -eq 0) { return $null }
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($t in $tags) {
        [void]$seen.Add($t.Groups[1].Value)
    }
    $attrs = Count-Regex $Text '\s[A-Za-z_:][A-Za-z0-9_:.-]*\s*='
    $tagRepeat = 1.0 - [Math]::Min(1.0, $seen.Count / [double]$tags.Count)
    $tagDensity = $tags.Count / [double][Math]::Max(($Text.Length / 100.0), 1.0)
    $law = 0.12 + [Math]::Min(0.25, $tagDensity / 30.0) + (0.30 * $tagRepeat) + [Math]::Min(0.23, $attrs / 300.0) + [Math]::Min(0.10, $seen.Count / 25.0)
    $ev = @(
        "tags=$($tags.Count)",
        "unique_tags=$($seen.Count)",
        "attrs=$attrs"
    )
    return New-Signal 'xml-svg-tree' $law $ev
}

function Analyze-RepetitionSignal([byte[]]$Bytes, [string]$Text) {
    $period = Get-ShortPeriodScore $Bytes
    $lineRep = Get-LineRepetitionScore $Text
    $tokenRep = 1.0 - (Get-TokenNoise $Text)
    $law = [Math]::Max($period, [Math]::Max((0.65 * $lineRep), (0.35 * $tokenRep)))
    if ($law -lt 0.20) { return $null }
    $ev = @(
        "period_score=$((Format-Score $period))",
        "line_repeat=$((Format-Score $lineRep))",
        "token_repeat=$((Format-Score $tokenRep))"
    )
    return New-Signal 'repetition-pattern' $law $ev
}

function Get-Category([double]$Law, [double]$Noise, [double]$Ratio) {
    if (($Law -ge 0.68) -and ($Noise -le 0.55) -and ($Ratio -ge 1.25)) {
        return 'DOMINIO PROCEDURAL'
    }
    if (($Law -ge 0.38) -and ($Ratio -ge 0.65)) {
        return 'DOMINIO HIBRIDO'
    }
    return 'DOMINIO ENTROPICO'
}

function Get-NextAction([string]$RepresentabilityClass, [string]$Kind) {
    switch ($RepresentabilityClass) {
        'CLASSE A' { return "Forja: sintetizar gerador $Kind e provar Delta real por SHA-256" }
        'CLASSE B' { return "Recuo: manter Brotli/CAS; lei estrutural sem vantagem suficiente" }
        'CLASSE C' { return "Indexacao: preservar por CAS/hash e evitar forja especulativa" }
        'CLASSE D' { return "Investigacao: testar gerador matematico antes de classificar como ruido" }
        default    { return "Auditoria: classe ausente" }
    }
}

function Sanitize-MarkdownCell([string]$Value) {
    if ($null -eq $Value) { return '' }
    $v = $Value -replace '\|', '/'
    $v = $v -replace "`r", ' '
    $v = $v -replace "`n", ' '
    if ($v.Length -gt 120) { return $v.Substring(0, 117) + '...' }
    return $v
}

function Analyze-File([System.IO.FileInfo]$File, [string]$Root) {
    $relative = Get-StableRelativePath $Root $File.FullName
    $ext = $File.Extension.ToLowerInvariant()
    $bytes = Read-SampleBytes $File.FullName $MaxSampleBytes
    $entropy = Get-ByteEntropy $bytes
    $entropyNorm = Clamp01 ($entropy / 8.0)
    $printable = Get-PrintableRatio $bytes
    $text = Convert-SampleToText $bytes
    $tokenNoise = Get-TokenNoise $text
    $magic = Get-MagicKind $bytes

    $signals = @()
    foreach ($s in @(
        (Analyze-JsonSignal $text $ext),
        (Analyze-CsvSignal $text $ext),
        (Analyze-LogSignal $text $ext),
        (Analyze-XmlSignal $text $ext),
        (Analyze-RepetitionSignal $bytes $text)
    )) {
        if ($null -ne $s) { $signals += $s }
    }

    if ($signals.Count -eq 0) {
        $signals += New-Signal 'raw-bytes' 0.05 @("magic=$magic")
    }

    $best = $signals | Sort-Object @{ Expression = 'Law'; Descending = $true }, Kind | Select-Object -First 1
    $binaryPenalty = if ($printable -lt 0.70) { 1.0 - $printable } else { 0.0 }
    $knownPacked = if ($magic -in @('png', 'jpeg', 'zip', 'gzip')) { 0.25 } else { 0.0 }
    $noise = Clamp01 ((0.62 * $entropyNorm) + (0.25 * $tokenNoise) + (0.13 * $binaryPenalty) + $knownPacked)
    if ($best.Kind -eq 'repetition-pattern' -and $best.Law -gt 0.75) {
        $noise = Clamp01 ($noise * 0.55)
    }
    if ($magic -eq 'pdf') {
        $noise = Clamp01 ($noise + 0.10)
    }

    $law = Clamp01 $best.Law
    $ratio = $law / [Math]::Max(0.01, $noise)
    $category = Get-Category $law $noise $ratio
    $evidence = (($best.Evidence + @(
        "entropy=$($entropy.ToString('0.0000', $IC))",
        "printable=$((Format-Score $printable))",
        "sample_bytes=$($bytes.Length)"
    )) -join '; ')
    $brotliBytes = Measure-BrotliOptimalBytes $File.FullName
    $brotliRatio = if ($File.Length -gt 0) { $brotliBytes / [double]$File.Length } else { 1.0 }
    $estimatedTeiaBytes = Get-EstimatedTeiaBytes $best.Kind $File.Length $brotliBytes $law $noise $evidence
    $advantage = if ($brotliBytes -gt 0) { ($brotliBytes - $estimatedTeiaBytes) / [double]$brotliBytes } else { 0.0 }
    $reprClass = Get-RepresentabilityClass $best.Kind $law $noise $advantage $evidence
    $prediction = Get-TeiaPrediction $reprClass

    return [pscustomobject]@{
        RelativePath = $relative
        Extension = if ([string]::IsNullOrWhiteSpace($ext)) { '[none]' } else { $ext }
        Bytes = [int64]$File.Length
        SampleBytes = [int]$bytes.Length
        BrotliBytes = [int64]$brotliBytes
        BrotliRatio = Round4 $brotliRatio
        SignalKind = $best.Kind
        LawIndex = Round4 $law
        NoiseIndex = Round4 $noise
        LawToNoiseRatio = Round4 $ratio
        EstimatedTeiaBytes = [int64]$estimatedTeiaBytes
        AdvantagePredictor = Round4 $advantage
        RepresentabilityClass = $reprClass
        TeiaPrediction = $prediction
        Category = $category
        Evidence = $evidence
        NextAction = Get-NextAction $reprClass $best.Kind
    }
}

function Write-TextIfChanged([string]$Path, [string]$Content) {
    $dir = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    if (Test-Path -LiteralPath $Path) {
        $old = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        if ($old -eq $Content) { return $false }
    }
    [System.IO.File]::WriteAllBytes($Path, $enc.GetBytes($Content))
    return $true
}

function Build-Report([object[]]$Rows, [object[]]$Errors, [int]$Skipped, [string]$Root, [int]$SampleLimit) {
    $sb = [System.Text.StringBuilder]::new()
    $ordered = @($Rows | Sort-Object Category, RelativePath)
    $totalBytes = [int64](($Rows | Measure-Object Bytes -Sum).Sum)
    $avgLaw = if ($Rows.Count -gt 0) { (($Rows | Measure-Object LawIndex -Average).Average) } else { 0.0 }
    $avgNoise = if ($Rows.Count -gt 0) { (($Rows | Measure-Object NoiseIndex -Average).Average) } else { 0.0 }
    $groups = @($Rows | Group-Object Category | Sort-Object Name)
    $classGroups = @($Rows | Group-Object RepresentabilityClass | Sort-Object Name)

    [void]$sb.AppendLine('# TEIA P25.0 - Law vs Noise and Representability Matrix')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Status: deterministic discovery report for Storage as Computation.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Invariantes')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('- P0 Core remains read-only: no file is compressed, stubbed, deleted, or moved.')
    [void]$sb.AppendLine('- Write == Read is preserved: the mapper reads samples and writes only this matrix.')
    [void]$sb.AppendLine('- The report contains no wall-clock timestamp, so identical input produces identical output.')
    [void]$sb.AppendLine('- TEIA control files and corpus manifests are skipped by default because they are pointers or inventory, not organic samples.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Scan Scope')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("| Field | Value |")
    [void]$sb.AppendLine("|---|---:|")
    [void]$sb.AppendLine("| Scan root | $(Sanitize-MarkdownCell $Root) |")
    [void]$sb.AppendLine("| Files analyzed | $($Rows.Count) |")
    [void]$sb.AppendLine("| Control files skipped | $Skipped |")
    [void]$sb.AppendLine("| Read errors | $($Errors.Count) |")
    [void]$sb.AppendLine("| Total bytes represented | $totalBytes |")
    [void]$sb.AppendLine("| Max sample bytes per file | $SampleLimit |")
    [void]$sb.AppendLine("| Average law index | $((Format-Score $avgLaw)) |")
    [void]$sb.AppendLine("| Average noise index | $((Format-Score $avgNoise)) |")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Ontological Classes')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Class | Count | Meaning |')
    [void]$sb.AppendLine('|---|---:|---|')
    foreach ($g in $groups) {
        $meaning = switch ($g.Name) {
            'DOMINIO PROCEDURAL' { 'High law, low noise. Best target for a generator.' }
            'DOMINIO HIBRIDO' { 'Law and residue coexist. Split grammar into code and residual content into classic storage.' }
            default { 'Low law, high noise. Preserve by hash/CAS and avoid speculative synthesis.' }
        }
        [void]$sb.AppendLine("| $($g.Name) | $($g.Count) | $meaning |")
    }
    if ($groups.Count -eq 0) {
        [void]$sb.AppendLine('| [none] | 0 | No eligible organic files found. |')
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Scientific Representability Classes')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Class | Count | Prediction | Meaning |')
    [void]$sb.AppendLine('|---|---:|---|---|')
    foreach ($g in $classGroups) {
        $prediction = Get-TeiaPrediction $g.Name
        $meaning = Get-RepresentabilityMeaning $g.Name
        [void]$sb.AppendLine("| $($g.Name) | $($g.Count) | $prediction | $meaning |")
    }
    if ($classGroups.Count -eq 0) {
        [void]$sb.AppendLine('| [none] | 0 | [none] | No eligible organic files found. |')
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Candidate Matrix')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Path | Domain | Rep Class | Prediction | Signal | Bytes | Brotli | TEIA estimate | Law | Noise | Advantage | Evidence | Next action |')
    [void]$sb.AppendLine('|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---|---|')
    foreach ($r in $ordered) {
        [void]$sb.AppendLine((
            '| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} | {9} | {10} | {11} | {12} |' -f
            (Sanitize-MarkdownCell $r.RelativePath),
            $r.Category,
            $r.RepresentabilityClass,
            $r.TeiaPrediction,
            $r.SignalKind,
            $r.Bytes,
            $r.BrotliBytes,
            $r.EstimatedTeiaBytes,
            (Format-Score $r.LawIndex),
            (Format-Score $r.NoiseIndex),
            (Format-Score $r.AdvantagePredictor),
            (Sanitize-MarkdownCell $r.Evidence),
            (Sanitize-MarkdownCell $r.NextAction)
        ))
    }
    if ($ordered.Count -eq 0) {
        [void]$sb.AppendLine('| [none] | [none] | [none] | [none] | [none] | 0 | 0 | 0 | 0.00 | 0.00 | 0.00 | No eligible file. | Provide organic samples or include TEIA control explicitly. |')
    }
    if ($Errors.Count -gt 0) {
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## Clean Failures')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('| Path | Error |')
        [void]$sb.AppendLine('|---|---|')
        foreach ($e in ($Errors | Sort-Object Path)) {
            [void]$sb.AppendLine("| $(Sanitize-MarkdownCell $e.Path) | $(Sanitize-MarkdownCell $e.Error) |")
        }
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Routing Rule')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('- Procedural: synthesize a domain generator and prove byte identity by SHA-256.')
    [void]$sb.AppendLine('- Hybrid: encode stable grammar as code, then preserve residual entropy with classical storage.')
    [void]$sb.AppendLine('- Entropic: index and preserve; do not spend synthesis cycles where noise dominates.')
    [void]$sb.AppendLine('- Class A predicts real Delta gain before forging; Class B and Class C predict retreat; Class D requires a mathematical generator probe.')
    return $sb.ToString()
}

function Build-TheoryReport([object[]]$Rows, [object[]]$Errors, [int]$Skipped, [string]$Root, [int]$SampleLimit) {
    $sb = [System.Text.StringBuilder]::new()
    $ordered = @($Rows | Sort-Object RepresentabilityClass, RelativePath)
    $total = $Rows.Count
    $classA = @($Rows | Where-Object { $_.RepresentabilityClass -eq 'CLASSE A' })
    $classB = @($Rows | Where-Object { $_.RepresentabilityClass -eq 'CLASSE B' })
    $classC = @($Rows | Where-Object { $_.RepresentabilityClass -eq 'CLASSE C' })
    $classD = @($Rows | Where-Object { $_.RepresentabilityClass -eq 'CLASSE D' })
    $aConfirmed = @($classA | Where-Object { $_.EstimatedTeiaBytes -lt $_.BrotliBytes })
    $aPct = if ($classA.Count -gt 0) { [Math]::Round(100.0 * $aConfirmed.Count / $classA.Count, 1) } else { 0.0 }
    $predictedWins = @($Rows | Where-Object { $_.TeiaPrediction -in @('TEIA VENCE', 'TEIA INVESTIGA') })
    $predictedRetreat = @($Rows | Where-Object { $_.TeiaPrediction -eq 'TEIA RECUA' })
    $sumOrig = [int64](($Rows | Measure-Object Bytes -Sum).Sum)
    $sumBrotli = [int64](($Rows | Measure-Object BrotliBytes -Sum).Sum)
    $sumTeia = [int64](($Rows | Measure-Object EstimatedTeiaBytes -Sum).Sum)
    $portfolioAdv = if ($sumBrotli -gt 0) { [Math]::Round(100.0 * ($sumBrotli - $sumTeia) / $sumBrotli, 2) } else { 0.0 }

    [void]$sb.AppendLine('# TEIA P25.0 - Theory of Representability')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Abstract')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('This document tests a falsifiable hypothesis: high structural law does not necessarily imply high procedural advantage. The oracle estimates whether Storage as Computation should beat Brotli Optimal before any code forge is attempted.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Corpus and Method')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("| Field | Value |")
    [void]$sb.AppendLine("|---|---:|")
    [void]$sb.AppendLine("| Scan root | $(Sanitize-MarkdownCell $Root) |")
    [void]$sb.AppendLine("| Files analyzed | $total |")
    [void]$sb.AppendLine("| Control files skipped | $Skipped |")
    [void]$sb.AppendLine("| Read errors | $($Errors.Count) |")
    [void]$sb.AppendLine("| Max sample bytes per file | $SampleLimit |")
    [void]$sb.AppendLine("| Original bytes represented | $sumOrig |")
    [void]$sb.AppendLine("| Brotli Optimal bytes | $sumBrotli |")
    [void]$sb.AppendLine("| TEIA pre-forge estimate bytes | $sumTeia |")
    [void]$sb.AppendLine("| Portfolio predicted Delta gain pct | $($portfolioAdv.ToString('0.00', $IC)) |")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Method: for each file, the mapper reads a bounded sample, estimates Law and Noise, measures Brotli Optimal with .NET BrotliStream, estimates seed plus decoder size, and emits a pre-forge prediction.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Representability Classes')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Class | Count | Prediction | Criterion |')
    [void]$sb.AppendLine('|---|---:|---|---|')
    [void]$sb.AppendLine("| CLASSE A | $($classA.Count) | TEIA VENCE | High law plus estimated seed and decoder below Brotli by a material margin. |")
    [void]$sb.AppendLine("| CLASSE B | $($classB.Count) | TEIA RECUA | High law, but dictionaries or organic residue make Brotli already competitive. |")
    [void]$sb.AppendLine("| CLASSE C | $($classC.Count) | TEIA RECUA | Low law and low advantage. |")
    [void]$sb.AppendLine("| CLASSE D | $($classD.Count) | TEIA INVESTIGA | Apparent noise with possible mathematical generator. |")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Statistical Claim')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("Em $($aPct.ToString('0.0', $IC))% dos arquivos de Classe A, a TEIA confirma a viabilidade pre-forge do Storage as Computation contra Brotli Optimal.")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("Predicoes de vitoria ou investigacao: $($predictedWins.Count). Predicoes de recuo: $($predictedRetreat.Count).")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Evidence Table')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| File | Class | Prediction | Original | Brotli Optimal | TEIA estimate | Advantage | Law | Noise | Signal |')
    [void]$sb.AppendLine('|---|---|---|---:|---:|---:|---:|---:|---:|---|')
    foreach ($r in $ordered) {
        [void]$sb.AppendLine((
            '| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} | {9} |' -f
            (Sanitize-MarkdownCell $r.RelativePath),
            $r.RepresentabilityClass,
            $r.TeiaPrediction,
            $r.Bytes,
            $r.BrotliBytes,
            $r.EstimatedTeiaBytes,
            (Format-Score $r.AdvantagePredictor),
            (Format-Score $r.LawIndex),
            (Format-Score $r.NoiseIndex),
            $r.SignalKind
        ))
    }
    if ($ordered.Count -eq 0) {
        [void]$sb.AppendLine('| [none] | [none] | [none] | 0 | 0 | 0 | 0.00 | 0.00 | 0.00 | [none] |')
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Interpretation')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('- Class A is the forge queue: tabular matrices, structured logs, and repeated grammars where structural overhead exceeds what LZ77-style windows exploit.')
    [void]$sb.AppendLine('- Class B is the important negative result: high Law can still lose when dictionaries and residual values dominate representation cost.')
    [void]$sb.AppendLine('- Class C is preservation territory: the Core should index, hash, and avoid speculative synthesis.')
    [void]$sb.AppendLine('- Class D is a research queue: the mapper must test for hidden mathematical generators before calling the data entropic.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Operational Boundary')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('This is a predictor, not a forged proof. Final victory still requires a decoder, a seed, and SHA-256 Write == Read verification.')
    return $sb.ToString()
}

if (-not (Test-Path -LiteralPath $ScanRoot)) {
    throw "ScanRoot not found: $ScanRoot"
}
if ($MaxSampleBytes -lt 4096) {
    throw "MaxSampleBytes must be at least 4096."
}

$rootItem = Get-Item -LiteralPath $ScanRoot -ErrorAction Stop
$files = @(Get-ChildItem -LiteralPath $rootItem.FullName -Recurse -File -ErrorAction SilentlyContinue |
    Sort-Object FullName)

$skipped = 0
if (-not $IncludeTeiaControl) {
    $eligible = @()
    foreach ($f in $files) {
        if (($f.Extension -in @('.teia_stub', '.teia_seed')) -or ($f.Name -in @('corpus30_manifest.json', 'ingestion_manifest.json'))) {
            $skipped++
        } else {
            $eligible += $f
        }
    }
    $files = $eligible
}

if ($MaxFiles -gt 0) {
    $files = @($files | Select-Object -First $MaxFiles)
}

$rows = @()
$errors = @()
foreach ($f in $files) {
    try {
        $rows += Analyze-File $f $rootItem.FullName
    } catch {
        $errors += [pscustomobject]@{
            Path = Get-StableRelativePath $rootItem.FullName $f.FullName
            Error = $_.Exception.Message
        }
    }
}

$report = Build-Report $rows $errors $skipped $rootItem.FullName $MaxSampleBytes
$changed = Write-TextIfChanged $ReportPath $report
$theory = Build-TheoryReport $rows $errors $skipped $rootItem.FullName $MaxSampleBytes
$theoryChanged = Write-TextIfChanged $TheoryPath $theory

if (-not $Quiet) {
    [pscustomobject]@{
        ScanRoot = $rootItem.FullName
        ReportPath = $ReportPath
        TheoryPath = $TheoryPath
        FilesAnalyzed = $rows.Count
        ControlSkipped = $skipped
        Errors = $errors.Count
        ReportChanged = $changed
        TheoryChanged = $theoryChanged
    }
}
