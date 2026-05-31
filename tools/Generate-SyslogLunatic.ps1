<#
.SYNOPSIS
    Generate-SyslogLunatic.ps1 — Gerador de syslog determinístico para P13.1
.DESCRIPTION
    Gera 10000 linhas de log com fórmulas procedurais EXPLICITAMENTE INFERÍVEIS:
      - Level     : levels[(i-1) % 4]   — começa em INFO para i=1
      - Host      : hosts[(i-1) % 5]    — começa em api-01 para i=1
      - Latência  : (i % 500) + 1       — ciclo 2→500→1→2... (wrap em 500 visível)
      - JobID     : i formatado com 7 dígitos
      - Timestamp : floor(i/3600)h floor((i%3600)/60)m (i%60)s (i%1000)ms
    Line ending: CRLF (AppendLine .NET)
#>
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$enc      = New-Object System.Text.UTF8Encoding($false)
$sb       = [System.Text.StringBuilder]::new(1100000)

$levels   = @('INFO','WARN','ERROR','DEBUG')
$hostPool = @('api-01','api-02','api-03','worker-01','worker-02')

[void]$sb.AppendLine("# TEIA Lunatic Log — 10000 linhas — semente deterministica v0.90.1")

for ($i = 1; $i -le 10000; $i++) {
    # Divisão inteira via [Math]::Truncate — sem arredondamento banker's
    $hh  = [int][Math]::Truncate($i / 3600) % 24
    $mm  = [int][Math]::Truncate(($i % 3600) / 60)
    $ss  = $i % 60
    $xx  = $i % 1000
    $ts  = [string]::Format("2026-01-01T{0:D2}:{1:D2}:{2:D2}.{3:D3}Z", $hh, $mm, $ss, $xx)

    $lv  = $levels[($i - 1) % 4]       # INFO→WARN→ERROR→DEBUG, começa em INFO para i=1
    $hn  = $hostPool[($i - 1) % 5]     # api-01..worker-02, começa em api-01 para i=1
    $lat = ($i % 500) + 1              # ciclo 2,3,...,500,1,2,... — wrap visível nas últimas linhas
    $job = $i.ToString('D7')

    if ($i -lt 10000) {
        [void]$sb.AppendLine([string]::Format("{0} {1} [{2}] job={3} status=running latency={4}ms seq={5} retries=0",
            $ts, $lv, $hn, $job, $lat, $i))
    } else {
        [void]$sb.Append([string]::Format("{0} {1} [{2}] job={3} status=running latency={4}ms seq={5} retries=0",
            $ts, $lv, $hn, $job, $lat, $i))
    }
}

$outPath = "D:\TEIA_USER\MyRealData\Syslog_Lunatic.log"
New-Item -ItemType Directory -Path "D:\TEIA_USER\MyRealData" -Force | Out-Null
[System.IO.File]::WriteAllBytes($outPath, $enc.GetBytes($sb.ToString()))

$info = Get-Item $outPath
$hash = Get-FileHash $outPath -Algorithm SHA256

# Calcular compressão clássica
$bytes = [System.IO.File]::ReadAllBytes($outPath)
$opts  = [System.IO.Compression.CompressionLevel]::Optimal
$ms1 = New-Object System.IO.MemoryStream
$gz  = New-Object System.IO.Compression.GZipStream($ms1, $opts, $true)
$gz.Write($bytes, 0, $bytes.Length); $gz.Dispose()
$gzSz = [long]$ms1.Length; $ms1.Dispose()
$ms2 = New-Object System.IO.MemoryStream
$br  = New-Object System.IO.Compression.BrotliStream($ms2, $opts, $true)
$br.Write($bytes, 0, $bytes.Length); $br.Dispose()
$brSz = [long]$ms2.Length; $ms2.Dispose()

Write-Host "=== Syslog_Lunatic.log gerado ===" -ForegroundColor Green
Write-Host "Tamanho  : $($info.Length) bytes"
Write-Host "SHA-256  : $($hash.Hash)"
Write-Host "GZip     : $gzSz bytes ($([Math]::Round(100.0*$gzSz/$info.Length,2))%)"
Write-Host "Brotli   : $brSz bytes ($([Math]::Round(100.0*$brSz/$info.Length,2))%)"
Write-Host ""
Write-Host "=== Primeiras 6 linhas ===" -ForegroundColor Cyan
$content = [System.IO.File]::ReadAllText($outPath, [System.Text.Encoding]::UTF8)
$allLines = $content -split "`r`n"
$allLines[0..5] | ForEach-Object { Write-Host "  $_" }
Write-Host ""
Write-Host "=== Últimas 4 linhas ===" -ForegroundColor Cyan
$allLines[($allLines.Count-4)..($allLines.Count-1)] | ForEach-Object { Write-Host "  $_" }
Write-Host ""
Write-Host "Total de linhas (split CRLF): $($allLines.Count)"
Write-Host "Últimas latências: $($allLines[9997] -replace '.*latency=(\d+)ms.*','$1'), $($allLines[9998] -replace '.*latency=(\d+)ms.*','$1'), $($allLines[9999] -replace '.*latency=(\d+)ms.*','$1'), $($allLines[10000] -replace '.*latency=(\d+)ms.*','$1')"
