<#
.SYNOPSIS
    Analyze-SemanticSchema.ps1 — Lente Semantica TEIA v1.0

.DESCRIPTION
    Extrai a "gramatica" de um arquivo JSON ou CSV, reduzindo megabytes de dados
    para um esqueleto semantico compacto (poucos KB) adequado como entrada para um LLM.

    Para JSON:
      - Parse completo via ConvertFrom-Json
      - Mapa de todas as chaves existentes com tipos (String, Int, Float, Bool, Null, Array, Object)
      - Dicionario de frequencia para campos com cardinalidade baixa (string/bool)
      - Deteccao de padroes numericos: constante, aritmetico, aleatorio
      - Arrays homogeneos: schema + todos os dados (arrays pequenos) ou sample+stats (grandes)

    Para CSV:
      - Mapa de cabecalhos e tipos por coluna
      - Cardinalidade de cada coluna (unique count)
      - Valores de amostra

    INVARIANTE: "Delta" sempre por extenso. Simbolo matematico proibido.

.PARAMETER InputFile
    Arquivo a analisar (.json, .jsonl, .csv, .tsv)

.PARAMETER Mode
    JSON, CSV ou AUTO (detecta pela extensao). Padrao: AUTO

.PARAMETER MaxUniqueDisplay
    Numero maximo de valores unicos exibidos por campo. Padrao: 25

.PARAMETER MaxArrayInline
    Tamanho maximo de array para exibicao inline completa. Padrao: 20

.PARAMETER OutputJson
    Se especificado, escreve o skeleton estruturado como JSON neste caminho.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$InputFile,

    [ValidateSet('JSON','CSV','AUTO')]
    [string]$Mode           = 'AUTO',

    [int]$MaxUniqueDisplay  = 25,
    [int]$MaxArrayInline    = 20,
    [string]$OutputJson     = ''
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC  = [System.Globalization.CultureInfo]::InvariantCulture
$enc = New-Object System.Text.UTF8Encoding($false)

# ── Utilitarios ───────────────────────────────────────────────────────────────

function Get-PsType([object]$v) {
    if ($null -eq $v)                          { return 'Null'    }
    if ($v -is [bool])                         { return 'Bool'    }
    if ($v -is [long] -or $v -is [int] -or $v -is [System.Int64] -or $v -is [System.Int32]) { return 'Int' }
    if ($v -is [double] -or $v -is [float] -or $v -is [decimal])  { return 'Float'  }
    if ($v -is [string])                       { return 'String'  }
    if ($v -is [System.Object[]] -or $v -is [System.Array]) { return 'Array' }
    if ($v -is [System.Management.Automation.PSCustomObject]) { return 'Object' }
    return $v.GetType().Name
}

function Detect-NumericPattern([object[]]$vals) {
    # Returns: Constant | Arithmetic | Random
    $nums = $vals | Where-Object { $null -ne $_ } | ForEach-Object { [double]$_ }
    if ($nums.Count -lt 2) { return 'Constant' }
    $first = $nums[0]
    $allSame = $true
    foreach ($n in $nums) { if ($n -ne $first) { $allSame = $false; break } }
    if ($allSame) { return 'Constant' }
    $step = $nums[1] - $nums[0]
    $isArith = $true
    for ($i = 1; $i -lt [Math]::Min($nums.Count, 20); $i++) {
        if ([Math]::Abs(($nums[$i] - $nums[$i-1]) - $step) -gt 0.001) { $isArith = $false; break }
    }
    if ($isArith) { return "Arithmetic(step=$step)" }
    return 'Random'
}

# ── Analise JSON ──────────────────────────────────────────────────────────────

function Analyze-JsonArray {
    param([object[]]$Arr, [string]$ArrayPath, [int]$MaxInline)

    $n = $Arr.Count
    if ($n -eq 0) { return [ordered]@{ count=0; schema='(empty)'; items=@() } }

    # Collect all unique keys (if objects) or element types (if scalars)
    $firstEl = $Arr[0]
    $elType  = Get-PsType $firstEl

    if ($elType -eq 'Object') {
        # Homogeneous object array: build schema from all items' keys
        $allKeys = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($item in $Arr) {
            if ($item -is [System.Management.Automation.PSCustomObject]) {
                foreach ($p in $item.PSObject.Properties) { [void]$allKeys.Add($p.Name) }
            }
        }
        $keys = $allKeys | Sort-Object

        # For each key: collect type + unique values
        $fieldSchema = [ordered]@{}
        foreach ($key in $keys) {
            $vals     = $Arr | ForEach-Object {
                if ($_.PSObject.Properties[$key]) { $_.($key) } else { $null }
            }
            $types    = ($vals | Where-Object {$null -ne $_} | ForEach-Object { Get-PsType $_ } | Sort-Object -Unique) -join '|'
            $uniq     = ($vals | ForEach-Object { "$_" } | Sort-Object -Unique)
            $uniqCount = $uniq.Count

            if ($uniqCount -le 2 -and $types -eq 'Bool') {
                $fieldSchema[$key] = "Bool unique=($($uniq -join ','))"
            } elseif ($types -in @('Int','Float','Int|Float') -and $uniqCount -gt 2) {
                $pattern = Detect-NumericPattern ($vals | Where-Object { $null -ne $_ })
                $mn = ($vals | Where-Object {$null -ne $_} | Measure-Object -Minimum).Minimum
                $mx = ($vals | Where-Object {$null -ne $_} | Measure-Object -Maximum).Maximum
                $fieldSchema[$key] = "$types unique=$uniqCount min=$mn max=$mx pattern=$pattern"
            } elseif ($types -eq 'String' -and $uniqCount -le 25) {
                $sample = ($uniq | Select-Object -First 10 | ForEach-Object { "`"$_`"" }) -join ', '
                $fieldSchema[$key] = "String unique=$uniqCount [$sample]"
            } elseif ($types -eq 'String') {
                $sample = ($uniq | Select-Object -First 5 | ForEach-Object { "`"$_`"" }) -join ', '
                $fieldSchema[$key] = "String unique=$uniqCount sample=[$sample ...]"
            } else {
                $fieldSchema[$key] = "$types unique=$uniqCount"
            }
        }

        # Items: inline all if small, else first+last samples
        $items = @()
        if ($n -le $MaxInline) {
            $items = $Arr | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 3 }
        } else {
            $items  = $Arr[0..([Math]::Min(4,$n-1))] | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 3 }
            $items += "... ($($n-10) items omitted) ..."
            $items += $Arr[($n-5)..($n-1)] | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 3 }
        }

        return [ordered]@{
            count       = $n
            element_type= 'Object'
            schema      = $fieldSchema
            items       = $items
        }

    } elseif ($elType -in @('Int','Float','String','Bool')) {
        $vals     = $Arr | ForEach-Object { $_ }
        $uniq     = ($vals | ForEach-Object { "$_" } | Sort-Object -Unique)
        $items    = if ($n -le $MaxInline) { $vals } else { @($vals[0..4]) + @("...") + @($vals[($n-5)..($n-1)]) }
        return [ordered]@{
            count       = $n
            element_type= $elType
            unique      = $uniq.Count
            items       = $items
        }
    } else {
        return [ordered]@{ count=$n; element_type=$elType; items=@() }
    }
}

function Build-JsonSkeleton {
    param($root, [string]$FilePath, [long]$FileSize, [string]$Sha256,
          [int]$MaxInline)

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("FILE: $(Split-Path $FilePath -Leaf)  SIZE: $FileSize bytes  SHA256: $Sha256")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("TOP-LEVEL KEYS:")

    $topKeys = $root.PSObject.Properties | Sort-Object Name
    foreach ($prop in $topKeys) {
        $val  = $prop.Value
        $type = Get-PsType $val
        if ($type -eq 'Array') {
            [void]$sb.AppendLine("  $($prop.Name): Array[$($val.Count)]")
        } elseif ($type -eq 'Object') {
            [void]$sb.AppendLine("  $($prop.Name): Object{$($val.PSObject.Properties.Name -join ', ')}")
        } elseif ($type -in @('String','Bool','Int','Float')) {
            $display = if ("$val".Length -gt 60) { ("$val").Substring(0,57) + '...' } else { "$val" }
            [void]$sb.AppendLine("  $($prop.Name): $type = `"$display`"")
        } else {
            [void]$sb.AppendLine("  $($prop.Name): $type")
        }
    }

    [void]$sb.AppendLine("")

    # Analyze each top-level array / object
    foreach ($prop in $topKeys) {
        $val  = $prop.Value
        $type = Get-PsType $val

        if ($type -eq 'Array') {
            [void]$sb.AppendLine("═══ ARRAY: $($prop.Name) ($($val.Count) items) ═══")
            $analysis = Analyze-JsonArray -Arr ([object[]]$val) -ArrayPath $prop.Name -MaxInline $MaxInline

            if ($analysis.element_type -eq 'Object' -and $analysis.schema) {
                [void]$sb.AppendLine("FIELD SCHEMA:")
                foreach ($kv in $analysis.schema.GetEnumerator()) {
                    [void]$sb.AppendLine("  $($kv.Key): $($kv.Value)")
                }
            }

            [void]$sb.AppendLine("DATA ($($analysis.count) items):")
            foreach ($item in $analysis.items) {
                [void]$sb.AppendLine("  $item")
            }
            [void]$sb.AppendLine("")
        }
    }

    return $sb.ToString()
}

# ── Analise CSV ───────────────────────────────────────────────────────────────

function Build-CsvSkeleton {
    param([string]$FilePath, [long]$FileSize, [string]$Sha256, [int]$MaxUniq)

    $rows = Import-Csv $FilePath -Encoding UTF8
    if (-not $rows) { return "CSV empty" }

    $headers = $rows[0].PSObject.Properties.Name
    $n       = $rows.Count

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("FILE: $(Split-Path $FilePath -Leaf)  SIZE: $FileSize bytes  SHA256: $Sha256")
    [void]$sb.AppendLine("ROWS: $n  COLUMNS: $($headers.Count)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("COLUMN SCHEMA:")

    foreach ($h in $headers) {
        $vals   = $rows | ForEach-Object { $_.$h }
        $uniq   = ($vals | Sort-Object -Unique)
        $sample = ($uniq | Select-Object -First 8 | ForEach-Object { "`"$_`"" }) -join ', '
        $numTest = 0
        $notNum  = $false
        foreach ($v in ($vals | Select-Object -First 20)) {
            $dummy = 0
            if (-not [double]::TryParse($v, [System.Globalization.NumberStyles]::Any, $IC, [ref]$dummy)) {
                $notNum = $true; break
            }
        }
        $colType = if ($notNum) { 'String' } else { 'Numeric' }
        [void]$sb.AppendLine("  ${h}: $colType unique=$($uniq.Count) sample=[$sample $(if($uniq.Count -gt 8){'...'})]")
    }

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("FIRST 5 ROWS (raw CSV):")
    $rawLines = Get-Content $FilePath -Encoding UTF8 -TotalCount 6
    foreach ($l in $rawLines) { [void]$sb.AppendLine("  $l") }

    return $sb.ToString()
}

# ── Main ──────────────────────────────────────────────────────────────────────

if (-not (Test-Path -LiteralPath $InputFile)) {
    Write-Error "Arquivo nao encontrado: $InputFile"; exit 1
}

$fi      = Get-Item -LiteralPath $InputFile
$size    = $fi.Length
$sha256  = (Get-FileHash -LiteralPath $InputFile -Algorithm SHA256).Hash.ToLower()
$ext     = $fi.Extension.ToLower()

# Detectar modo
$detectedMode = $Mode
if ($Mode -eq 'AUTO') {
    if ($ext -in @('.json', '.jsonl'))    { $detectedMode = 'JSON' }
    elseif ($ext -in @('.csv', '.tsv'))   { $detectedMode = 'CSV'  }
    else {
        # Try JSON parse
        try {
            $sample = Get-Content -LiteralPath $InputFile -Raw -Encoding UTF8 -ErrorAction Stop
            $null = $sample.Substring(0,1).Trim()
            if ($sample.TrimStart()[0] -in @('{','[')) { $detectedMode = 'JSON' }
            else { Write-Error "Modo AUTO nao reconhece extensao '$ext' e conteudo nao e JSON."; exit 1 }
        } catch { Write-Error "Modo AUTO falhou: $_"; exit 1 }
    }
}

$skeleton = ''
$jsonResult = $null

if ($detectedMode -eq 'JSON') {
    $rawText = Get-Content -LiteralPath $InputFile -Raw -Encoding UTF8
    try {
        $root = $rawText | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Error "Falha ao parsear JSON: $_"; exit 1
    }
    $skeleton   = Build-JsonSkeleton -root $root -FilePath $InputFile -FileSize $size -Sha256 $sha256 -MaxInline $MaxArrayInline
    $jsonResult = [ordered]@{
        mode      = 'JSON'
        file      = $InputFile
        size      = $size
        sha256    = $sha256
        skeleton  = $skeleton
    }
} elseif ($detectedMode -eq 'CSV') {
    $skeleton   = Build-CsvSkeleton -FilePath $InputFile -FileSize $size -Sha256 $sha256 -MaxUniq $MaxUniqueDisplay
    $jsonResult = [ordered]@{
        mode      = 'CSV'
        file      = $InputFile
        size      = $size
        sha256    = $sha256
        skeleton  = $skeleton
    }
} else {
    Write-Error "Modo nao suportado: $detectedMode"; exit 1
}

if ($OutputJson) {
    New-Item -ItemType Directory -Path (Split-Path $OutputJson -Parent) -Force -ErrorAction SilentlyContinue | Out-Null
    $jsonBytes = $enc.GetBytes(($jsonResult | ConvertTo-Json -Depth 5 -Compress))
    [System.IO.File]::WriteAllBytes($OutputJson, $jsonBytes)
}

Write-Output $skeleton
