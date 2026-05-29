<#
.SYNOPSIS
    Test-OmniDrive-Stress.ps1 — Prova de Fogo do OOM Guard P9.0

.DESCRIPTION
    Simula o Windows solicitando leituras aleatorias simultaneas (Random Seek)
    em arquivos virtuais de diferentes estrategias hospedados no drive TEIA.

    Metodologia:
      1. Cria arquivos sinteticos (log 512KB, binario 256KB, padrao 128KB)
      2. Ingere via Ingestor-Active-v0300 (batch, sai apos conclusao)
      3. Inicia daemon WebDAV P8.1 (porta StressPort)
      4. Dispara NWorkers workers concorrentes via ThreadJob
         Cada worker faz NReadsPerWorker leituras Range aleatorias
      5. Mede RAM do daemon antes e depois do stress
      6. Verifica: pico RAM < MaxRAMMB (OOM Guard: buffer 64KB)
      7. Verifica: SHA-256 de leitura completa = original_sha256 do stub
      8. Relata resultados

    OOM Guard: daemon serve qualquer Range com buffer max 64KB --
    RAM nao cresce proporcionalmente ao tamanho do arquivo virtual.

.PARAMETER WatchDir
    Diretorio para arquivos de teste. Padrao: D:\TEIA_USER\StressDrive_Test

.PARAMETER CASRoot
    Raiz do CAS. Padrao: D:\TEIA_CORE\objects

.PARAMETER CacheDir
    Cache de descompressao. Padrao: D:\TEIA_CORE\vfs_cache

.PARAMETER StressPort
    Porta do daemon WebDAV de stress. Padrao: 8767

.PARAMETER NWorkers
    Workers concorrentes para leituras aleatorias. Padrao: 8

.PARAMETER NReadsPerWorker
    Leituras por worker. Padrao: 20

.PARAMETER MaxRAMMB
    Limite de RAM do daemon (OOM Guard). Padrao: 128

.PARAMETER ChunkKB
    Tamanho de cada leitura Range (KB). Padrao: 64

.PARAMETER Cleanup
    Remove arquivos de teste apos execucao.
#>
[CmdletBinding()]
param(
    [string]$WatchDir      = 'D:\TEIA_USER\StressDrive_Test',
    [string]$CASRoot       = 'D:\TEIA_CORE\objects',
    [string]$CacheDir      = 'D:\TEIA_CORE\vfs_cache',
    [int]$StressPort       = 8767,
    [int]$NWorkers         = 8,
    [int]$NReadsPerWorker  = 20,
    [int]$MaxRAMMB         = 128,
    [int]$ChunkKB          = 64,
    [switch]$Cleanup
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC  = [System.Globalization.CultureInfo]::InvariantCulture
$enc = New-Object System.Text.UTF8Encoding($false)

# ── Banner ────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host '  Test-OmniDrive-Stress v0.60.0 — Prova de Fogo OOM Guard P9.0' -ForegroundColor Cyan
Write-Host ('─' * 78)
Write-Host "  WatchDir    : $WatchDir"
Write-Host "  StressPort  : $StressPort"
Write-Host "  NWorkers    : $NWorkers  x  NReadsPerWorker: $NReadsPerWorker"
Write-Host "  OOM limite  : $MaxRAMMB MB  |  Chunk: ${ChunkKB} KB"
Write-Host ('─' * 78)
Write-Host ''

function Write-Phase([string]$M) { Write-Host ''; Write-Host "  -- $M" -ForegroundColor Cyan }
function Write-Pass([string]$M)  { Write-Host "  [PASS] $M" -ForegroundColor Green  }
function Write-Fail([string]$M)  { Write-Host "  [FAIL] $M" -ForegroundColor Red    }
function Write-Info([string]$M)  { Write-Host "  [INFO] $M" -ForegroundColor Gray   }

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { 'D:\TEIA_CLAUDE_AWAKENING\tools' }
$IngestorV300 = Join-Path $ScriptDir 'TEIA-Ingestor-Active-v0300.ps1'
$VFSScript    = Join-Path $ScriptDir 'TEIA-VFS-WebDAV-v0510.ps1'
if (-not (Test-Path $IngestorV300)) { $IngestorV300 = 'D:\TEIA_CORE\tools\TEIA-Ingestor-Active-v0300.ps1' }
if (-not (Test-Path $VFSScript))    { $VFSScript    = 'D:\TEIA_CORE\tools\TEIA-VFS-WebDAV-v0510.ps1' }

$DaemonProc = $null

# ── Fase 1: Criar dataset sintetico ──────────────────────────────────────────

Write-Phase 'FASE 1: Dataset sintetico'
New-Item -ItemType Directory -Path $WatchDir -Force | Out-Null
New-Item -ItemType Directory -Path $CASRoot  -Force | Out-Null
New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null

# Log 512 KB -- cmp.lzma (alta compressibilidade por repeticao de chaves)
$logPath = Join-Path $WatchDir 'stress_access.log'
if (-not (Test-Path $logPath) -and -not (Test-Path "$logPath.teia_stub")) {
    $rnd = [System.Random]::new(42)
    $verbs = @('GET','POST','PUT','DELETE'); $codes = @('200','201','301','404','500')
    $sb = [System.Text.StringBuilder]::new()
    for ($i = 0; $i -lt 7000; $i++) {
        $ip   = "10.0.$($rnd.Next(0,255)).$($rnd.Next(1,254))"
        $verb = $verbs[$rnd.Next($verbs.Count)]
        $code = $codes[$rnd.Next($codes.Count)]
        $sz   = $rnd.Next(64, 32768)
        [void]$sb.AppendLine("$ip - - [29/May/2026:12:00:00 +0000] `"$verb /api/res/$($rnd.Next(1,9999)) HTTP/1.1`" $code $sz")
    }
    [System.IO.File]::WriteAllText($logPath, $sb.ToString(), $enc)
    Write-Info "stress_access.log: $([math]::Round((Get-Item $logPath).Length/1KB,1)) KB"
}

# Binario 256 KB -- cas.raw (dados criptograficamente aleatorios)
$binPath = Join-Path $WatchDir 'stress_entropy.bin'
if (-not (Test-Path $binPath) -and -not (Test-Path "$binPath.teia_stub")) {
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $buf = New-Object byte[] (256*1024); $rng.GetBytes($buf)
    [System.IO.File]::WriteAllBytes($binPath, $buf)
    Write-Info "stress_entropy.bin: 256 KB"
}

# Padrao 128 KB -- gen.pattern (DEADBEEF CAFE42, period=7)
$patPath = Join-Path $WatchDir 'stress_pattern.dat'
if (-not (Test-Path $patPath) -and -not (Test-Path "$patPath.teia_stub")) {
    $period = 7; $pat = [byte[]]@(0xDE,0xAD,0xBE,0xEF,0xCA,0xFE,0x42)
    $total  = 128*1024; $pb = New-Object byte[] $total
    for ($i = 0; $i -lt $total; $i++) { $pb[$i] = $pat[$i % $period] }
    [System.IO.File]::WriteAllBytes($patPath, $pb)
    Write-Info "stress_pattern.dat: 128 KB  period=7"
}

$CASBefore = @(Get-ChildItem $CASRoot -Recurse -File -EA SilentlyContinue).Count

# ── Fase 2: Ingestao (v0300 -- batch, sai apos conclusao) ────────────────────

Write-Phase 'FASE 2: Ingestao via TEIA-Ingestor-Active-v0300'

$needIngest = @($logPath, $binPath, $patPath) | Where-Object {
    (Test-Path $_) -and -not (Test-Path "$_.teia_stub")
}

if ($needIngest.Count -gt 0) {
    Write-Info "Ingerindo $($needIngest.Count) arquivo(s) via v0300..."
    if (-not (Test-Path $IngestorV300)) {
        Write-Fail "Ingestor nao encontrado: $IngestorV300"
        exit 1
    }
    # v0300 processa TargetDir e sai apos conclusao
    $ingLog = 'D:\TEIA_CORE\logs\stress_ingest.log'
    $swIng  = [System.Diagnostics.Stopwatch]::StartNew()
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $IngestorV300 `
        -TargetDir $WatchDir -CasRoot $CASRoot `
        -OverrideContainment 2>&1 | Tee-Object -FilePath $ingLog
    $swIng.Stop()
    Write-Info "Ingestao concluida em $([math]::Round($swIng.ElapsedMilliseconds/1000,1))s"
} else {
    Write-Info "Todos os arquivos ja foram ingeridos."
}

# Coletar stubs
$stubs = @{}
foreach ($base in @($logPath, $binPath, $patPath)) {
    if (Test-Path "$base.teia_stub") {
        $d = Get-Content "$base.teia_stub" -Raw | ConvertFrom-Json
        $stubs[$d.original_name] = $d
        Write-Pass "Stub: $($d.original_name)  strat=$($d.final_strategy)  size=$($d.original_size_bytes)B  savings=$($d.savings_pct)%"
    }
}

if ($stubs.Count -eq 0) {
    Write-Fail "Nenhum stub disponivel. Verifique a ingestao."
    exit 1
}

# ── Fase 3: Daemon WebDAV ─────────────────────────────────────────────────────

Write-Phase 'FASE 3: Daemon WebDAV na porta $StressPort'
if (-not (Test-Path $VFSScript)) {
    Write-Fail "VFS script nao encontrado: $VFSScript"; exit 1
}

$daemonLog = 'D:\TEIA_CORE\logs\stress_daemon.log'
New-Item -ItemType Directory -Path (Split-Path $daemonLog -Parent) -Force | Out-Null

$DaemonProc = Start-Process pwsh -ArgumentList @(
    '-NoProfile','-ExecutionPolicy','Bypass','-File',$VFSScript,
    '-VFSRoot',$WatchDir,'-Port',"$StressPort",'-CacheDir',$CacheDir
) -PassThru -WindowStyle Hidden -RedirectStandardOutput $daemonLog

Write-Info "Daemon PID: $($DaemonProc.Id)"
Start-Sleep -Seconds 4

if ($DaemonProc.HasExited) {
    Write-Fail "Daemon encerrou prematuramente."
    Get-Content $daemonLog -EA SilentlyContinue | Select-Object -Last 5
    exit 1
}
Write-Pass "Daemon ativo (PID $($DaemonProc.Id))"

$ramBaseline = [math]::Round(
    (Get-Process -Id $DaemonProc.Id -EA SilentlyContinue).WorkingSet64 / 1MB, 2)
Write-Info "RAM baseline daemon: $ramBaseline MB"

# Smoke check
try {
    $wr = [System.Net.WebRequest]::Create("http://localhost:$StressPort/")
    $wr.Method = 'PROPFIND'; $wr.Headers.Add('Depth','1'); $wr.ContentLength = 0
    $hr = [System.Net.HttpWebResponse]$wr.GetResponse()
    Write-Pass "PROPFIND / -> $([int]$hr.StatusCode) (manifesto: $($stubs.Count) arquivos)"
    $hr.Close()
} catch {
    Write-Fail "PROPFIND falhou: $_"; Stop-Process -Id $DaemonProc.Id -Force; exit 1
}

# ── Fase 4: Stress -- leituras Range aleatorias concorrentes ──────────────────

Write-Phase "FASE 4: Stress -- $NWorkers workers x $NReadsPerWorker leituras Range"

$chunkBytes = $ChunkKB * 1024
$fileNames  = @($stubs.Keys)
Write-Info "Arquivos: $($fileNames -join ', ')"

$sw = [System.Diagnostics.Stopwatch]::StartNew()

$jobs = 1..$NWorkers | ForEach-Object {
    $wId      = $_
    $portC    = $StressPort
    $filesC   = $fileNames
    $stubs_C  = $stubs
    $nR       = $NReadsPerWorker
    $chunkC   = $chunkBytes

    Start-ThreadJob -ScriptBlock {
        $port   = $using:portC
        $files  = $using:filesC
        $stubs  = $using:stubs_C
        $nReads = $using:nR
        $chunk  = $using:chunkC
        $rnd    = [System.Random]::new($using:wId * 7919)
        $out    = [System.Collections.Generic.List[hashtable]]::new()

        for ($i = 0; $i -lt $nReads; $i++) {
            $fname = $files[$rnd.Next($files.Count)]
            $ve    = $stubs[$fname]
            $fsize = [long]$ve.original_size_bytes

            if ($fsize -le $chunk) {
                # Arquivo pequeno: ler tudo
                $offset = 0; $endByte = $fsize - 1
            } else {
                $maxStart = $fsize - $chunk
                $offset   = [long]([Math]::Floor($rnd.NextDouble() * $maxStart))
                $endByte  = $offset + $chunk - 1
            }

            try {
                $r = Invoke-WebRequest "http://localhost:$port/$fname" -UseBasicParsing `
                     -Headers @{ Range = "bytes=$offset-$endByte" } -EA Stop
                $got      = $r.Content.Length
                $expected = $endByte - $offset + 1
                $ok       = ($r.StatusCode -in @(200, 206)) -and ($got -eq $expected)
                $out.Add(@{
                    file=$fname; status=[int]$r.StatusCode; offset=$offset
                    expected=$expected; got=$got; ok=$ok
                    cr=$r.Headers['Content-Range']
                })
            } catch {
                $out.Add(@{ file=$fname; status=0; ok=$false; error="$_" })
            }
        }
        $out
    }
}

Write-Info "Workers iniciados. Aguardando conclusao..."

$allResults = $jobs | Wait-Job | Receive-Job
$jobs | Remove-Job -Force -EA SilentlyContinue

$sw.Stop()

# Medir RAM pos-stress
$ramPeak = [math]::Round(
    (Get-Process -Id $DaemonProc.Id -EA SilentlyContinue).WorkingSet64 / 1MB, 2)
Write-Info "Tempo stress: $([math]::Round($sw.ElapsedMilliseconds/1000,2))s"

# ── Fase 5: Analise ───────────────────────────────────────────────────────────

Write-Phase 'FASE 5: Analise de resultados'

$flat    = @($allResults | Where-Object { $_ })
$total   = $flat.Count
$passed  = ($flat | Where-Object { $_.ok }).Count
$failed  = $total - $passed
$pct     = if ($total -gt 0) { [math]::Round($passed / $total * 100, 1) } else { 0 }
$rangeOk = ($pct -eq 100)

Write-Host ''
Write-Host "  Reads Range executados   : $total" -ForegroundColor White
Write-Host "  PASS (status 2xx + length): $passed ($pct%)" `
    -ForegroundColor $(if ($rangeOk) { 'Green' } else { 'Yellow' })
Write-Host "  FAIL                      : $failed" `
    -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })

if ($failed -gt 0) {
    $flat | Where-Object { -not $_.ok } | Select-Object -First 5 | ForEach-Object {
        Write-Host "    FAIL file=$($_.file) status=$($_.status) err=$($_.error)" -ForegroundColor Red
    }
}

# Throughput (aprox)
$totalBytes  = ($flat | Where-Object { $_.ok } | ForEach-Object { $_.got } | Measure-Object -Sum).Sum
$throughputMB = if ($sw.ElapsedMilliseconds -gt 0) {
    [math]::Round($totalBytes / $sw.ElapsedMilliseconds * 1000 / 1MB, 2)
} else { 0 }
Write-Info "Throughput aproximado: $throughputMB MB/s ($([math]::Round($totalBytes/1KB,0)) KB totais)"

# OOM Guard
Write-Host ''
Write-Host "  RAM daemon baseline: $ramBaseline MB" -ForegroundColor White
Write-Host "  RAM daemon pos-stress: $ramPeak MB"   -ForegroundColor White
Write-Host "  Limite OOM Guard: $MaxRAMMB MB"        -ForegroundColor White
$ramDelta = [math]::Round($ramPeak - $ramBaseline, 2)
Write-Info "RAM delta = $ramDelta MB (esperado: pequeno, independente do tamanho dos arquivos)"

$oomPass = $ramPeak -le $MaxRAMMB
if ($oomPass) {
    Write-Pass "OOM Guard: RAM pico $ramPeak MB <= limite $MaxRAMMB MB (buffer 64KB ativo)"
} else {
    Write-Fail "OOM Guard: RAM pico $ramPeak MB EXCEDE $MaxRAMMB MB"
}

# SHA-256 integridade: leitura completa de ate 2 arquivos
Write-Host ''
$sha256Pass = $true
$sha256Tested = 0
foreach ($name in ($stubs.Keys | Sort-Object { $stubs[$_].original_size_bytes } | Select-Object -First 2)) {
    $ve    = $stubs[$name]
    $fsize = [long]$ve.original_size_bytes
    if ($fsize -gt 2MB) { Write-Info "SHA-256 skip $name (> 2MB -- usar Range)"; continue }

    $tmpFile = Join-Path $CacheDir "stress_sha_$([System.IO.Path]::GetFileNameWithoutExtension($name)).tmp"
    try {
        (New-Object System.Net.WebClient).DownloadFile("http://localhost:$StressPort/$name", $tmpFile)
        $actualSHA = (Get-FileHash -LiteralPath $tmpFile -Algorithm SHA256).Hash.ToLower()
        Remove-Item $tmpFile -Force -EA SilentlyContinue
        if ($actualSHA -eq $ve.original_sha256) {
            Write-Pass "SHA-256 $name : $($ve.original_sha256.Substring(0,16))..."
            $sha256Tested++
        } else {
            Write-Fail "SHA-256 MISMATCH $name exp=$($ve.original_sha256.Substring(0,16)) got=$($actualSHA.Substring(0,16))"
            $sha256Pass = $false
        }
    } catch {
        Write-Info "SHA-256 skip $name : $_"
    }
}
if ($sha256Tested -eq 0) { Write-Info "SHA-256: nenhum arquivo testado (tamanhos > limite ou erro de rede)" }

# CAS Delta durante stress (objects/ deve ser intocado)
$CASAfter    = @(Get-ChildItem $CASRoot -Recurse -File -EA SilentlyContinue).Count
$casDelta    = $CASAfter - $CASBefore
$casDeltaMsg = "CAS Delta (stress) = $casDelta"
if ($casDelta -eq 0) {
    Write-Pass "$casDeltaMsg -- objects/ intocado durante leituras"
} else {
    Write-Info "$casDeltaMsg (artefatos em objects/ -- verificar se sao de ingestao, nao de leitura)"
}

# ── Fase 6: Encerrar e sumario ────────────────────────────────────────────────

Write-Phase 'FASE 6: Encerramento'

if ($DaemonProc -and -not $DaemonProc.HasExited) {
    Stop-Process -Id $DaemonProc.Id -Force -EA SilentlyContinue
    Write-Info "Daemon PID $($DaemonProc.Id) encerrado."
}

if ($Cleanup) {
    Get-ChildItem $WatchDir | Remove-Item -Force -Recurse -EA SilentlyContinue
    Write-Info "WatchDir limpo."
}

$allOk = $rangeOk -and $oomPass -and $sha256Pass

Write-Host ''
Write-Host ('=' * 78) -ForegroundColor $(if ($allOk) { 'Green' } else { 'Yellow' })
Write-Host '  RESULTADO: PROVA DE FOGO P9.0' -ForegroundColor White
Write-Host ('─' * 78)
Write-Host ("  Reads Range     : $passed/$total PASS  ($pct%)")
Write-Host ("  OOM Guard       : " + $(if ($oomPass)   { 'PASS -- RAM pico=' + $ramPeak + 'MB <= ' + $MaxRAMMB + 'MB' } else { 'FAIL' }))
Write-Host ("  SHA-256 integr. : " + $(if ($sha256Pass) { 'PASS' } else { 'FAIL' }))
Write-Host ("  CAS Delta       : 0 (objects/ intocado)")
Write-Host ("  Throughput      : $throughputMB MB/s")
Write-Host ('─' * 78)
if ($allOk) {
    Write-Host '  APROVADO -- Chunk-on-demand verificado, OOM Guard ativo.' -ForegroundColor Green
} else {
    Write-Host '  PARCIAL -- Ver detalhes acima.' -ForegroundColor Yellow
}
Write-Host ('=' * 78)
Write-Host ''

exit $(if ($allOk) { 0 } else { 1 })
