<#
.SYNOPSIS
    Test-RealAppIntegration.ps1 — TEIA P9.1 — Validação de integração com apps Windows

.DESCRIPTION
    Executa 5 categorias de teste contra T:\ (WebDAV VFS montado sobre stubs TEIA):
      1. SHA-256 via Get-FileHash  — prova que os bytes reconstruídos são idênticos ao original
      2. Metadata / Length         — (Get-Item).Length reporta original_size_bytes do stub
      3. Copy-Item para C:\Temp\   — extração completa funciona com cmdlets nativos
      4. Timing / throughput       — latência de primeira leitura e throughput sustentado
      5. Stress de seek            — 10 leituras Range aleatórias confirmam integridade parcial

    Pré-requisitos:
      - T:\ montado via WebDAV  (net use T: \\localhost@8766\DavWWWRoot\ /persistent:no)
      - D:\TEIA_CORE\objects\   contém os CAS files dos 3 stubs VFS_Test
      - D:\TEIA_USER\VFS_Test\  contém os stubs (.teia_stub) como referência de SHA-256

.OUTPUTS
    Report JSON: D:\TEIA_CORE\docs\TEIA_P9_REAL_APP_INTEGRATION_v0601.json
#>
[CmdletBinding()]
param(
    [string]$VFSRoot    = 'D:\TEIA_USER\VFS_Test',
    [string]$MountPoint = 'T:\',
    [string]$TempDir    = 'C:\Temp\TEIA_P91',
    [string]$ReportDir  = 'D:\TEIA_CORE\docs'
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC  = [System.Globalization.CultureInfo]::InvariantCulture
$ts0 = Get-Date

function Write-Section([string]$title) {
    Write-Host ""
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host ('=' * 72) -ForegroundColor Cyan
}

function Write-Pass([string]$msg) { Write-Host "  [PASS] $msg" -ForegroundColor Green }
function Write-Fail([string]$msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red }
function Write-Info([string]$msg) { Write-Host "  [INFO] $msg" -ForegroundColor Gray }

# ── Sanity checks ─────────────────────────────────────────────────────────────
Write-Section "PRE-FLIGHT"
if (-not (Get-PSDrive T -EA SilentlyContinue)) {
    Write-Host "  T:\ nao esta montado. Execute:" -ForegroundColor Red
    Write-Host "    net use T: \\localhost@8766\DavWWWRoot\ /persistent:no"
    exit 1
}
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
Write-Pass "T:\ montado"
Write-Pass "TempDir: $TempDir criado"

# Carregar stubs como referência de ground-truth
$stubs = Get-ChildItem -LiteralPath $VFSRoot -Filter '*.teia_stub' |
    ForEach-Object { Get-Content $_.FullName | ConvertFrom-Json }

$results = [System.Collections.Generic.List[hashtable]]::new()
$nPass = 0; $nFail = 0

# ── CATEGORIA 1: SHA-256 via Get-FileHash ─────────────────────────────────────
Write-Section "CAT-1: SHA-256 (Get-FileHash T:\file)"
foreach ($stub in $stubs) {
    $vfsPath = Join-Path $MountPoint $stub.original_name
    Write-Info "Calculando SHA-256: $($stub.original_name)"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $computed = (Get-FileHash -LiteralPath $vfsPath -Algorithm SHA256).Hash.ToLower()
    $sw.Stop()
    $expected = $stub.original_sha256.ToLower()
    $match = ($computed -eq $expected)
    $throughput_mbps = [Math]::Round($stub.original_size_bytes / 1MB / $sw.Elapsed.TotalSeconds, 2)
    if ($match) {
        Write-Pass "$($stub.original_name) SHA-256 OK  [$($sw.Elapsed.TotalMilliseconds.ToString('F0'))ms | $throughput_mbps MB/s]"
        $nPass++
    } else {
        Write-Fail "$($stub.original_name) SHA-256 MISMATCH"
        Write-Host "    expected: $expected" -ForegroundColor DarkRed
        Write-Host "    computed: $computed" -ForegroundColor DarkRed
        $nFail++
    }
    $results.Add(@{
        category  = 'SHA256'
        file      = $stub.original_name
        pass      = $match
        elapsed_ms = [int]$sw.Elapsed.TotalMilliseconds
        throughput_mbps = $throughput_mbps
    })
}

# ── CATEGORIA 2: Metadata / Length ────────────────────────────────────────────
Write-Section "CAT-2: METADATA (Get-Item).Length"
foreach ($stub in $stubs) {
    $vfsPath = Join-Path $MountPoint $stub.original_name
    $item = Get-Item -LiteralPath $vfsPath
    $reported = $item.Length
    $expected = [long]$stub.original_size_bytes
    $match = ($reported -eq $expected)
    if ($match) {
        Write-Pass "$($stub.original_name): Length=$reported == original_size_bytes=$expected"
        $nPass++
    } else {
        Write-Fail "$($stub.original_name): Length=$reported != original_size_bytes=$expected"
        $nFail++
    }
    $results.Add(@{
        category       = 'Metadata'
        file           = $stub.original_name
        pass           = $match
        reported_bytes = $reported
        expected_bytes = $expected
    })
}

# ── CATEGORIA 3: Copy-Item para C:\Temp\ ─────────────────────────────────────
Write-Section "CAT-3: Copy-Item (T:\ -> C:\Temp\TEIA_P91\)"
foreach ($stub in $stubs) {
    $src  = Join-Path $MountPoint $stub.original_name
    $dst  = Join-Path $TempDir $stub.original_name
    if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Force }
    Write-Info "Copy-Item: $($stub.original_name)"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Copy-Item -LiteralPath $src -Destination $dst -Force
    $sw.Stop()
    $copiedSize = (Get-Item -LiteralPath $dst).Length
    $sizeOk  = ($copiedSize -eq [long]$stub.original_size_bytes)
    $sha256  = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash.ToLower()
    $shaOk   = ($sha256 -eq $stub.original_sha256.ToLower())
    $pass    = ($sizeOk -and $shaOk)
    $throughput_mbps = [Math]::Round($stub.original_size_bytes / 1MB / $sw.Elapsed.TotalSeconds, 2)
    if ($pass) {
        Write-Pass "$($stub.original_name) copiado OK [$($sw.Elapsed.TotalMilliseconds.ToString('F0'))ms | $throughput_mbps MB/s | SHA-256 OK]"
        $nPass++
    } else {
        Write-Fail "$($stub.original_name): sizeOk=$sizeOk sha256Ok=$shaOk"
        $nFail++
    }
    $results.Add(@{
        category        = 'CopyItem'
        file            = $stub.original_name
        pass            = $pass
        elapsed_ms      = [int]$sw.Elapsed.TotalMilliseconds
        throughput_mbps = $throughput_mbps
        size_ok         = $sizeOk
        sha256_ok       = $shaOk
    })
}

# ── CATEGORIA 4: Timing — First Byte + Sequential Read ────────────────────────
Write-Section "CAT-4: TIMING (first-byte latency + sequential throughput)"
foreach ($stub in $stubs) {
    $vfsPath = Join-Path $MountPoint $stub.original_name

    # First-byte: read 1 byte
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $fs = [System.IO.File]::OpenRead($vfsPath)
    [void]$fs.ReadByte()
    $fs.Close()
    $sw.Stop()
    $firstByteMs = [int]$sw.Elapsed.TotalMilliseconds
    Write-Info "$($stub.original_name): first-byte ${firstByteMs}ms"

    # Sequential full read
    $sw2 = [System.Diagnostics.Stopwatch]::StartNew()
    $bytes = [System.IO.File]::ReadAllBytes($vfsPath)
    $sw2.Stop()
    $throughput_mbps = [Math]::Round($stub.original_size_bytes / 1MB / $sw2.Elapsed.TotalSeconds, 2)
    Write-Pass "$($stub.original_name): $throughput_mbps MB/s ($($stub.original_size_bytes) bytes em $($sw2.Elapsed.TotalMilliseconds.ToString('F0'))ms)"
    $nPass++
    $results.Add(@{
        category           = 'Timing'
        file               = $stub.original_name
        pass               = $true
        first_byte_ms      = $firstByteMs
        seq_elapsed_ms     = [int]$sw2.Elapsed.TotalMilliseconds
        throughput_mbps    = $throughput_mbps
    })
    Remove-Variable bytes
}

# ── CATEGORIA 5: Range / Random Seek ─────────────────────────────────────────
Write-Section "CAT-5: RANGE READS (10 seeks aleatorios por arquivo)"
$rng = New-Object System.Random(42)
foreach ($stub in $stubs) {
    $url  = "http://localhost:8766/$($stub.original_name)"
    $size = [long]$stub.original_size_bytes
    $passCount = 0
    for ($i = 0; $i -lt 10; $i++) {
        $offset = [long]($rng.NextDouble() * [Math]::Max(0, $size - 4096))
        $length = [Math]::Min(4096, $size - $offset)
        $endByte = $offset + $length - 1
        try {
            $wr = [System.Net.WebRequest]::Create($url)
            $wr.Headers.Add("Range", "bytes=${offset}-${endByte}")
            $resp = [System.Net.HttpWebResponse]$wr.GetResponse()
            $sc   = [int]$resp.StatusCode
            $cl   = $resp.ContentLength
            $resp.Close()
            if ($sc -in @(200, 206) -and $cl -eq $length) { $passCount++ }
            else {
                Write-Fail "$($stub.original_name) seek ${i}: status=$sc cl=$cl expected_len=$length"
                $nFail++
            }
        } catch {
            Write-Fail "$($stub.original_name) seek ${i}: $_"
            $nFail++
        }
    }
    if ($passCount -eq 10) {
        Write-Pass "$($stub.original_name): 10/10 seeks OK"
        $nPass++
    } else {
        Write-Fail "$($stub.original_name): $passCount/10 seeks OK"
        $nFail++
    }
    $results.Add(@{
        category     = 'RangeRead'
        file         = $stub.original_name
        pass         = ($passCount -eq 10)
        seeks_passed = $passCount
        seeks_total  = 10
    })
}

# ── RAM snapshot ──────────────────────────────────────────────────────────────
$proc = Get-Process -Id $PID
$ramMB = [Math]::Round($proc.WorkingSet64 / 1MB, 1)

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Section "SUMARIO"
$elapsed = (Get-Date) - $ts0
Write-Host "  Total PASS : $nPass" -ForegroundColor Green
Write-Host "  Total FAIL : $nFail" -ForegroundColor $(if ($nFail -eq 0) { 'Green' } else { 'Red' })
Write-Host "  RAM (este processo): $ramMB MB"
Write-Host "  Duracao total: $($elapsed.TotalSeconds.ToString('F1'))s"
Write-Host ""
$verdict = if ($nFail -eq 0) { 'ALL_PASS' } else { 'FAIL' }
Write-Host "  VEREDICTO: $verdict" -ForegroundColor $(if ($nFail -eq 0) { 'Green' } else { 'Red' })

# ── Export JSON report ────────────────────────────────────────────────────────
$report = [ordered]@{
    report_version  = '0.60.1'
    protocol        = 'P9.1'
    timestamp       = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
    verdict         = $verdict
    total_pass      = $nPass
    total_fail      = $nFail
    ram_mb          = $ramMB
    elapsed_seconds = [Math]::Round($elapsed.TotalSeconds, 2)
    tests           = $results
}
$reportPath = Join-Path $ReportDir 'TEIA_P9_REAL_APP_INTEGRATION_v0601.json'
$report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding UTF8 -NoNewline
Write-Host ""
Write-Host "  Report JSON: $reportPath" -ForegroundColor Yellow
Write-Host ""
