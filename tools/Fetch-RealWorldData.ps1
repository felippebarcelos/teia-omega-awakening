#Requires -Version 7
<#
.SYNOPSIS
    P22.0 — Ingesta de datasets orgânicos do mundo real para o Real-World Crucible.
    Baixa 3 arquivos públicos, verifica SHA-256 e registra metadados.
#>
[CmdletBinding()]
param(
    [string]$OutputDir = 'D:\TEIA_USER\MyRealData\RealWorld_Crucible'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$datasets = @(
    @{
        Name   = 'covid_countries_aggregated.csv'
        Url    = 'https://raw.githubusercontent.com/datasets/covid-19/main/data/countries-aggregated.csv'
        Desc   = 'COVID-19 cases by country by date (long format CSV)'
    },
    @{
        Name   = 'countries.json'
        Url    = 'https://raw.githubusercontent.com/mledoze/countries/master/countries.json'
        Desc   = 'World countries with capitals, currencies, languages (JSON array)'
    },
    @{
        Name   = 'world_map.svg'
        Url    = 'https://upload.wikimedia.org/wikipedia/commons/3/3d/Flag_of_Switzerland_%28Pantone%29.svg'
        Desc   = 'Public domain SVG — flag geometry (paths, circles, rects)'
    }
)

Write-Host ''
Write-Host '======================================================================'
Write-Host '  TEIA P22.0 — Real-World Crucible: Data Ingestion'
Write-Host '======================================================================'
Write-Host "  Output dir : $OutputDir"
Write-Host "  Timestamp  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host '======================================================================'
Write-Host ''

$results = @()

foreach ($ds in $datasets) {
    $dest = Join-Path $OutputDir $ds.Name
    Write-Host "  Baixando : $($ds.Name)"
    Write-Host "  URL      : $($ds.Url)"

    try {
        Invoke-WebRequest -Uri $ds.Url -OutFile $dest -UseBasicParsing -TimeoutSec 60
        $hash = (Get-FileHash $dest -Algorithm SHA256).Hash.ToLower()
        $size = (Get-Item $dest).Length
        Write-Host ("  Tamanho  : {0:N0} B ({1:F2} KB)" -f $size, ($size / 1KB))
        Write-Host "  SHA-256  : $hash"
        Write-Host ''
        $results += [PSCustomObject]@{
            Name    = $ds.Name
            Size    = $size
            SHA256  = $hash
            Path    = $dest
            Status  = 'OK'
        }
    } catch {
        Write-Warning "  FALHOU: $_"
        $results += [PSCustomObject]@{
            Name    = $ds.Name
            Size    = 0
            SHA256  = ''
            Path    = $dest
            Status  = "FAIL: $_"
        }
    }
}

Write-Host '======================================================================'
Write-Host '  RESUMO'
Write-Host '======================================================================'
foreach ($r in $results) {
    $mark = if ($r.Status -eq 'OK') { 'OK' } else { 'FAIL' }
    Write-Host ("  [{0}] {1,-40} {2,8:N0} B" -f $mark, $r.Name, $r.Size)
}
Write-Host ''

$manifestPath = Join-Path $OutputDir 'ingestion_manifest.json'
$results | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath -Encoding UTF8
Write-Host "  Manifesto gravado em: $manifestPath"
Write-Host ''
