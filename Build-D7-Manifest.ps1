#Requires -Version 7
# Build-D7-Manifest.ps1
# Gera D7_REAL_MANIFEST.json: corpus heterogeneo 100+ arquivos, zero overlap com D4
# Fontes: botocore paginators/service-2/endpoint-rule-set + Google API discovery
# Shuffle deterministico Fisher-Yates seed=42

$ErrorActionPreference = 'Continue'
Set-Location "D:\TEIA_CLAUDE_AWAKENING"

$OUTPUT_PATH   = "D:\TEIA_CLAUDE_AWAKENING\D7_REAL_MANIFEST.json"
$BOTOCORE_ROOT = "D:\TEIA OS\google-cloud-sdk\lib\third_party\botocore\data"
$GAPI_ROOT     = "D:\bruto\TEIA\Miniconda\envs\agents_v2\Lib\site-packages\googleapiclient\discovery_cache\documents"

$TINY_MAX   = [long]5000
$SMALL_MAX  = [long]100000
$MEDIUM_MAX = [long]500000
$MAX_FILE   = [long]5000000  # cap 5MB para LZMA nao timeout

# Alvos por bucket
$WANT_TINY         = 20
$WANT_SMALL_BOTO   = 25
$WANT_SMALL_GAPI   = 20
$WANT_MEDIUM       = 25
$WANT_LARGE        = 15

# Arquivos de treino do dict-small (excluir do D7)
$DICT_SMALL_TRAIN = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
@(
    "advisorynotifications.v1.json","apikeys.v2.json","baremetalsolution.v1alpha1.json",
    "blogger.v2.json","businessprofileperformance.v1.json","chromeuxreport.v1.json",
    "cloudshell.v1.json","cloudtrace.v2.json","dfareporting.v3.5.json","discovery.v1.json"
) | ForEach-Object { [void]$DICT_SMALL_TRAIN.Add($_) }

# Carregar D4 para exclusao de paths duplicados
$d4 = Get-Content "D:\TEIA_CLAUDE_AWAKENING\D4_REAL_MANIFEST.json" -Raw | ConvertFrom-Json
$D4_PATHS = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($f in $d4.files) { [void]$D4_PATHS.Add($f.path) }
Write-Host "[D7] D4 exclusoes carregadas: $($D4_PATHS.Count) paths"

function Invoke-FisherYates {
    param([object[]]$InputArray, [int]$Seed = 42)
    if ($InputArray.Count -eq 0) { return @() }
    $arr = [object[]]::new($InputArray.Count)
    [Array]::Copy($InputArray, $arr, $InputArray.Count)
    $rng = [System.Random]::new($Seed)
    for ($i = $arr.Length - 1; $i -gt 0; $i--) {
        $j = $rng.Next(0, $i + 1)
        $tmp = $arr[$i]; $arr[$i] = $arr[$j]; $arr[$j] = $tmp
    }
    return $arr
}

function Scan-Botocore {
    param([string]$Filter, [long]$MinSz, [long]$MaxSz)
    if (-not (Test-Path $BOTOCORE_ROOT)) { return @() }
    $items = Get-ChildItem -Path $BOTOCORE_ROOT -Recurse -Filter $Filter -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Length -ge $MinSz -and $_.Length -lt $MaxSz -and
            $_.Length -lt $MAX_FILE -and
            -not $D4_PATHS.Contains($_.FullName)
        }
    return @($items | ForEach-Object {
        [pscustomobject]@{ Path=$_.FullName; Name=$_.Name; Size=$_.Length }
    })
}

function Scan-Gapi {
    param([long]$MinSz, [long]$MaxSz)
    if (-not (Test-Path $GAPI_ROOT)) { return @() }
    $items = Get-ChildItem -Path $GAPI_ROOT -Filter "*.json" -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Length -ge $MinSz -and $_.Length -lt $MaxSz -and
            -not $D4_PATHS.Contains($_.FullName) -and
            -not $DICT_SMALL_TRAIN.Contains($_.Name)
        }
    return @($items | ForEach-Object {
        [pscustomobject]@{ Path=$_.FullName; Name=$_.Name; Size=$_.Length }
    })
}

Write-Host ""
Write-Host "[D7] Escaneando candidatos..."

# Tiny: botocore paginators-1.json (tipicamente 1-5KB)
$tinyC = Scan-Botocore "paginators-1.json" 1000 $TINY_MAX
Write-Host "  tiny (paginators-1.json):          $($tinyC.Count) candidatos"

# Small botocore: service-2.json 5-100KB + waiters-2.json 5-100KB
$smallBoto1 = Scan-Botocore "service-2.json" $TINY_MAX $SMALL_MAX
$smallBoto2 = Scan-Botocore "waiters-2.json" $TINY_MAX $SMALL_MAX
$smallBotoC = @($smallBoto1) + @($smallBoto2)
Write-Host "  small-boto (service-2 + waiters):  $($smallBotoC.Count) candidatos"

# Small Google API discovery
$smallGapiC = Scan-Gapi $TINY_MAX $SMALL_MAX
Write-Host "  small-gapi (discovery docs):       $($smallGapiC.Count) candidatos"

# Medium: service-2.json 100-500KB + endpoint-rule-set-1.json 100-500KB
$mediumC1 = Scan-Botocore "service-2.json"       $SMALL_MAX $MEDIUM_MAX
$mediumC2 = Scan-Botocore "endpoint-rule-set-1.json" $SMALL_MAX $MEDIUM_MAX
$mediumC  = @($mediumC1) + @($mediumC2)
Write-Host "  medium (service-2 + endpoint):     $($mediumC.Count) candidatos"

# Large: service-2.json 500KB-5MB
$largeC = Scan-Botocore "service-2.json" $MEDIUM_MAX $MAX_FILE
Write-Host "  large (service-2 >=500KB):         $($largeC.Count) candidatos"

# Shuffle e selecionar
$SEED = 42
$tinySelected  = @(Invoke-FisherYates $tinyC     $SEED | Select-Object -First $WANT_TINY)
$smallBSelected= @(Invoke-FisherYates $smallBotoC $SEED | Select-Object -First $WANT_SMALL_BOTO)
$smallGSelected= @(Invoke-FisherYates $smallGapiC $SEED | Select-Object -First $WANT_SMALL_GAPI)
$medSelected   = @(Invoke-FisherYates $mediumC    $SEED | Select-Object -First $WANT_MEDIUM)
$largeSelected = @(Invoke-FisherYates $largeC     $SEED | Select-Object -First $WANT_LARGE)

$allSelected = @($tinySelected) + @($smallBSelected) + @($smallGSelected) + @($medSelected) + @($largeSelected)

Write-Host ""
Write-Host ("[D7] Selecionados: tiny={0} small={1} medium={2} large={3} total={4}" -f `
    $tinySelected.Count, ($smallBSelected.Count + $smallGSelected.Count), $medSelected.Count, $largeSelected.Count, $allSelected.Count)

# Computar SHA-256 e montar manifest
Write-Host ""
Write-Host "[D7] Computando SHA-256 e construindo manifest..."
$files  = [System.Collections.ArrayList]::new()
$idx    = 1
$errCnt = 0

foreach ($item in $allSelected) {
    try {
        $sz   = (Get-Item $item.Path -ErrorAction Stop).Length
        $hash = (Get-FileHash $item.Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToLower()

        $bkt = if ($sz -lt $TINY_MAX) { "tiny" }
               elseif ($sz -lt $SMALL_MAX) { "small" }
               elseif ($sz -lt $MEDIUM_MAX) { "medium" }
               else { "large" }

        [void]$files.Add([ordered]@{
            id         = "R$idx"
            path       = $item.Path
            name       = $item.Name
            size_bytes = $sz
            sha256     = $hash
            bucket     = $bkt
        })
        Write-Host ("  R{0,-4} {1,-6} {2,9}B  {3}...  {4}" -f $idx, $bkt, $sz, $hash.Substring(0,16), $item.Name)
        $idx++
    } catch {
        $errCnt++
        Write-Warning "  SKIP: $($item.Path) — $_"
    }
}

# Estatistica final
$bktCounts = @{}
foreach ($f in $files) { $bktCounts[$f.bucket] = ($bktCounts[$f.bucket] -as [int]) + 1 }
Write-Host ""
Write-Host ("[D7] Total: {0} arquivos | tiny={1} small={2} medium={3} large={4} | erros_skip={5}" -f `
    $files.Count, $bktCounts["tiny"], $bktCounts["small"], $bktCounts["medium"], $bktCounts["large"], $errCnt)

if ($files.Count -lt 50) {
    Write-Warning "[D7] AVISO: menos de 50 arquivos selecionados — verificar disponibilidade das fontes"
}

# Serializar e salvar
$manifest = [ordered]@{
    version     = "7.0.0"
    created_utc = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    description = "D7_REAL: corpus heterogeneo Benchmark Robusto TEIA v0.8.1 — zero overlap D4, seed=42"
    total_files = $files.Count
    seed        = $SEED
    sources     = @(
        "botocore/data/**/paginators-1.json (tiny ~2KB)",
        "botocore/data/**/service-2.json (small/medium/large)",
        "botocore/data/**/waiters-2.json (small)",
        "botocore/data/**/endpoint-rule-set-1.json (medium)",
        "googleapiclient/discovery_cache/documents/*.json (small, exclui 10 arquivos treino dict-small)"
    )
    bucket_counts = $bktCounts
    files = @($files)
}

$json      = $manifest | ConvertTo-Json -Depth 10
$utf8NoBom = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($OUTPUT_PATH, $json, $utf8NoBom)

# Verificar roundtrip
$readBack = (Get-Content $OUTPUT_PATH -Raw | ConvertFrom-Json).files.Count
if ($readBack -ne $files.Count) { Write-Warning "[D7] Roundtrip count mismatch: wrote=$($files.Count) read=$readBack" }

Write-Host ""
Write-Host "[D7] COMPLETO — $OUTPUT_PATH"
Write-Host "[D7] $($files.Count) arquivos prontos para Benchmark_Harness_v7.ps1"
