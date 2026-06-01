<#
.SYNOPSIS
    Discover-Generators.ps1 - P24.0 Law vs Noise Mapper

.DESCRIPTION
    Scans local files and estimates where data is mostly law, hybrid, or noise.
    The script is read-only for the scanned corpus: it never compresses, ingests,
    deletes, rewrites, or stubs input files.

    Invariant: "Delta" is always written as text if needed. The mathematical
    symbol is forbidden in generated code and reports.

.PARAMETER ScanRoot
    Root folder to scan. Defaults to D:\TEIA_USER\MyRealData.

.PARAMETER ReportPath
    Markdown matrix path. Defaults to D:\TEIA_CORE\docs\TEIA_LAW_VS_NOISE_MATRIX.md.

.PARAMETER MaxFiles
    Optional cap for deterministic sampling. 0 means no cap.

.PARAMETER MaxSampleBytes
    Maximum bytes read per file for heuristic analysis.

.PARAMETER IncludeTeiaControl
    Include .teia_stub and .teia_seed files. By default these are skipped.

.PARAMETER Quiet
    Suppress the final summary object.
#>
[CmdletBinding()]
param(
    [string]$ScanRoot       = 'D:\TEIA_USER\MyRealData',
    [string]$ReportPath     = 'D:\TEIA_CORE\docs\TEIA_LAW_VS_NOISE_MATRIX.md',
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

function Get-NextAction([string]$Category, [string]$Kind) {
    switch ($Category) {
        'DOMINIO PROCEDURAL' { return "Forja: sintetizar gerador $Kind e provar Write == Read" }
        'DOMINIO HIBRIDO'    { return "Roteador: extrair gramatica para codigo e isolar residuo" }
        default              { return "Indexacao: preservar por CAS/hash e evitar forja especulativa" }
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

    return [pscustomobject]@{
        RelativePath = $relative
        Extension = if ([string]::IsNullOrWhiteSpace($ext)) { '[none]' } else { $ext }
        Bytes = [int64]$File.Length
        SampleBytes = [int]$bytes.Length
        SignalKind = $best.Kind
        LawIndex = Round4 $law
        NoiseIndex = Round4 $noise
        LawToNoiseRatio = Round4 $ratio
        Category = $category
        Evidence = $evidence
        NextAction = Get-NextAction $category $best.Kind
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

    [void]$sb.AppendLine('# TEIA P24.0 - Law vs Noise Matrix')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Status: deterministic discovery report for Storage as Computation.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Invariantes')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('- P0 Core remains read-only: no file is compressed, stubbed, deleted, or moved.')
    [void]$sb.AppendLine('- Write == Read is preserved: the mapper reads samples and writes only this matrix.')
    [void]$sb.AppendLine('- The report contains no wall-clock timestamp, so identical input produces identical output.')
    [void]$sb.AppendLine('- TEIA control files are skipped by default because stubs are pointers, not organic samples.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Scan Scope')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("| Field | Value |")
    [void]$sb.AppendLine("|---|---:|")
    [void]$sb.AppendLine("| Scan root | $(Sanitize-MarkdownCell $Root) |")
    [void]$sb.AppendLine("| Files analyzed | $($Rows.Count) |")
    [void]$sb.AppendLine("| TEIA control files skipped | $Skipped |")
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
    [void]$sb.AppendLine('## Candidate Matrix')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Path | Class | Signal | Bytes | Law | Noise | Ratio | Evidence | Next action |')
    [void]$sb.AppendLine('|---|---|---|---:|---:|---:|---:|---|---|')
    foreach ($r in $ordered) {
        [void]$sb.AppendLine((
            '| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} |' -f
            (Sanitize-MarkdownCell $r.RelativePath),
            $r.Category,
            $r.SignalKind,
            $r.Bytes,
            (Format-Score $r.LawIndex),
            (Format-Score $r.NoiseIndex),
            (Format-Score $r.LawToNoiseRatio),
            (Sanitize-MarkdownCell $r.Evidence),
            (Sanitize-MarkdownCell $r.NextAction)
        ))
    }
    if ($ordered.Count -eq 0) {
        [void]$sb.AppendLine('| [none] | [none] | [none] | 0 | 0.00 | 0.00 | 0.00 | No eligible file. | Provide organic samples or include TEIA control explicitly. |')
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
        if ($f.Extension -in @('.teia_stub', '.teia_seed')) {
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

if (-not $Quiet) {
    [pscustomobject]@{
        ScanRoot = $rootItem.FullName
        ReportPath = $ReportPath
        FilesAnalyzed = $rows.Count
        TeiaControlSkipped = $skipped
        Errors = $errors.Count
        ReportChanged = $changed
    }
}
