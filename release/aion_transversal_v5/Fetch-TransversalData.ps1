#Requires -Version 7
# Fetch-TransversalData.ps1 — Gera corpus transversal sintético determinístico
# 60 arquivos CSV diários, 3000 linhas por arquivo, schema idêntico, ~14 MB total

param(
    [string]$OutputDir   = "D:\TEIA_USER\MyRealData\Corpus_Transversal\LogsDiarios",
    [int]   $NumFiles    = 60,
    [int]   $RowsPerFile = 3000
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$actions     = @("LOGIN","LOGOUT","VIEW_PAGE","PURCHASE","SEARCH","BOOKMARK","SHARE","PROFILE_UPDATE")
$statusCodes = @("200","201","400","401","403","404","500","503")
$regions     = @("NA","EU","APAC","LATAM","MEA")
$deviceTypes = @("MOBILE","DESKTOP","TABLET","TV","WEARABLE")

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$rng       = [System.Random]::new(42)
$startDate = [datetime]::new(2024, 1, 1)

Write-Host ""
Write-Host "=== TEIA Corpus Transversal — Gerador ===" -ForegroundColor Cyan
Write-Host "  Destino : $OutputDir"                    -ForegroundColor White
Write-Host "  Arquivos: $NumFiles"                     -ForegroundColor White
Write-Host "  Linhas  : $RowsPerFile por arquivo"      -ForegroundColor White
Write-Host ""

for ($f = 0; $f -lt $NumFiles; $f++) {
    $date     = $startDate.AddDays($f)
    $fileName = "log_{0:yyyy_MM_dd}.csv" -f $date
    $filePath = Join-Path $OutputDir $fileName

    if (Test-Path $filePath) {
        Write-Host "  $fileName [já existe — ignorado]" -ForegroundColor DarkGray
        continue
    }

    $sb = [System.Text.StringBuilder]::new(($RowsPerFile + 1) * 90)
    $null = $sb.AppendLine("Timestamp,UserID,Action,StatusCode,Duration_ms,Region,DeviceType,PageID")

    for ($r = 0; $r -lt $RowsPerFile; $r++) {
        $hour   = $rng.Next(0, 24)
        $min    = $rng.Next(0, 60)
        $sec    = $rng.Next(0, 60)
        $ts     = "{0:yyyy-MM-dd} {1:D2}:{2:D2}:{3:D2}" -f $date, $hour, $min, $sec
        $uid    = "U{0:D5}" -f $rng.Next(1, 1001)
        $action = $actions[$rng.Next(0, $actions.Length)]
        $status = $statusCodes[$rng.Next(0, $statusCodes.Length)]
        $dur    = $rng.Next(10, 30001)
        $region = $regions[$rng.Next(0, $regions.Length)]
        $device = $deviceTypes[$rng.Next(0, $deviceTypes.Length)]
        $pageId = "P{0:D4}" -f $rng.Next(1, 501)
        $null = $sb.AppendLine("$ts,$uid,$action,$status,$dur,$region,$device,$pageId")
    }

    [System.IO.File]::WriteAllText($filePath, $sb.ToString(), $utf8NoBom)
    Write-Host "  $fileName" -ForegroundColor DarkGreen
}

$csvFiles = Get-ChildItem -Path $OutputDir -Filter "*.csv"
$total    = ($csvFiles | Measure-Object -Property Length -Sum).Sum
Write-Host ""
Write-Host "Corpus pronto: $($csvFiles.Count) arquivos" -ForegroundColor Green
Write-Host "Tamanho total: $([math]::Round($total / 1MB, 1)) MB ($total bytes)" -ForegroundColor Cyan
