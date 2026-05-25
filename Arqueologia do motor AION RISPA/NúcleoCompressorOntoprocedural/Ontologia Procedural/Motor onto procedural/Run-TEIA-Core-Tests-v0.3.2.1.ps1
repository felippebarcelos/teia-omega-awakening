param(
  [string]$ReportDir,
  [switch]$RunBigTest
)

# Hardening do harness (v0.3.2.1): ReportDir param, _work_<ts> por default, Big Test com pico de RAM.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Ensure-Dir([string]$p){ if(-not(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Path $p -Force | Out-Null } }
function SHA256-File([string]$Path){
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $fs = [System.IO.File]::OpenRead($Path); try{
    $buf = New-Object byte[] 1048576
    while(($n=$fs.Read($buf,0,$buf.Length)) -gt 0){ $sha.TransformBlock($buf,0,$n,$null,0) | Out-Null }
    $sha.TransformFinalBlock(@(),0,0) | Out-Null
    -join ($sha.Hash | ForEach-Object { $_.ToString('x2') })
  } finally { $fs.Dispose() }
}
function New-RandomFile([string]$Path,[long]$Bytes,[double]$Skew=0.0){
  $dir = Split-Path -Parent $Path; Ensure-Dir $dir
  $fs=[System.IO.File]::Open($Path,'Create','Write','None')
  try{
    $buf=New-Object byte[] 65536
    $rng=[System.Random]::new(12345)
    $rem=$Bytes
    while($rem -gt 0){
      $n=[Math]::Min($rem,$buf.Length)
      if($Skew -gt 0){
        for($i=0;$i -lt $n;$i++){ $buf[$i] = $(if($rng.NextDouble() -lt $Skew){ 0 } else { $rng.Next(0,256) }) }
      } else { $rng.NextBytes($buf) }
      $fs.Write($buf,0,$n); $rem-=$n
    }
  } finally { $fs.Dispose() }
  return $Path
}
function Start-PeakProcess([string]$Command,[string]$WorkDir){
  # Executa um pwsh externo, aguarda finalizar e devolve @{ ExitCode; PeakWS; ElapsedMS; StdOut; StdErr }
  $tmp = [System.IO.Path]::GetTempFileName().Replace('.tmp','.ps1')
  try {
    [System.IO.File]::WriteAllText($tmp, $Command, [System.Text.UTF8Encoding]::new($false))
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'pwsh'
    $psi.Arguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$tmp`""
    if ($WorkDir) { $psi.WorkingDirectory = $WorkDir }
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $null = $proc.Start()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $peak = $proc.PeakWorkingSet64
    while(-not $proc.HasExited){
      Start-Sleep -Milliseconds 150
      $p2 = $proc.PeakWorkingSet64
      if($p2 -gt $peak){ $peak = $p2 }
    }
    $sw.Stop()
    $stdOut = $proc.StandardOutput.ReadToEnd()
    $stdErr = $proc.StandardError.ReadToEnd()
    return [pscustomobject]@{
      ExitCode = $proc.ExitCode
      PeakWS   = [int64]$peak
      ElapsedMS= [int64]$sw.ElapsedMilliseconds
      StdOut   = $stdOut
      StdErr   = $stdErr
    }
  } finally { if (Test-Path $tmp) { Remove-Item -Force $tmp -ErrorAction SilentlyContinue } }
}

# Resolve ReportDir
if([string]::IsNullOrWhiteSpace($ReportDir)){
  $ReportDir = Join-Path $PSScriptRoot ("_work_" + (Get-Date -Format 'yyyyMMddHHmmss'))
}
$dirTargets   = Join-Path $ReportDir 'targets'
$dirSeeds     = Join-Path $ReportDir 'seeds'
$dirRestored  = Join-Path $ReportDir 'restored'
$dirPredict   = Join-Path $ReportDir 'predictive'
$verPath      = Join-Path $ReportDir 'verification_report.json'
$opsPath      = Join-Path $ReportDir 'ops_summary.json'
Ensure-Dir $ReportDir; Ensure-Dir $dirTargets; Ensure-Dir $dirSeeds; Ensure-Dir $dirRestored; Ensure-Dir $dirPredict

# Carrega Core v0.3.2
$corePath = Join-Path $PSScriptRoot 'TEIA-Core-v0.3.2.ps1'
if(-not(Test-Path -LiteralPath $corePath)){ throw "Core não encontrado: $corePath" }
. $corePath
$coreSha = SHA256-File $corePath

# Gera targets pequenos (rápidos)
$T = @()
$T += New-RandomFile (Join-Path $dirTargets 'sample_skew_512k.bin')  (512KB) 0.85
$T += New-RandomFile (Join-Path $dirTargets 'sample_256k.bin')       (256KB) 0.0
$T += New-RandomFile (Join-Path $dirTargets 'one_symbol_128k.bin')   (128KB) 1.0
$null = New-Item -ItemType File -Path (Join-Path $dirTargets 'empty.bin') -Force
$T += Join-Path $dirTargets 'empty.bin'

function File-Len([string]$p){ if(Test-Path $p){ (Get-Item $p).Length } else { 0 } }

# Executa compactação/restauração por alvo e coleta telemetria
$targetsReport = @()
$huffRatios = @()
$huffCount  = 0

foreach($input in $T){
  $origBytes = File-Len $input
  $dry = Build-Seed-From-Stream -InputPath $input -SeedPath (Join-Path $dirSeeds 'dry.seed.json') -DryRun
  $seedPath = Join-Path $dirSeeds ((Split-Path -Leaf $input) + '.seed.json')
  [void](Build-Seed-From-Stream -InputPath $input -SeedPath $seedPath)

  # Decide plano a partir do header real (mais confiável)
  $info = Read-SeedHeaderAndOpenPayload -SeedPath $seedPath
  try{
    $algo = $info.Header.algo
  } finally { $info.Reader.Dispose(); $info.Stream.Dispose() }

  $plan = @{ op = $(if($algo -eq 'huffman_deterministic'){ 'apply.huffman_deterministic' } else { 'apply.raw_copy' }) }
  $outPath = Join-Path $dirRestored ((Split-Path -Leaf $input) + '.restored')
  [void](Execute-Plan -Plan $plan -SeedPath $seedPath -OutPath $outPath)

  $seedBytes = File-Len $seedPath
  $restBytes = File-Len $outPath
  $okSha = $true
  if($origBytes -ne 0){
    $okSha = (SHA256-File $input) -eq (SHA256-File $outPath)
  }

  $ratioSeed = if($origBytes -gt 0){ [double]$seedBytes / [double]$origBytes } else { 0.0 }
  if($algo -eq 'huffman_deterministic'){
    $huffCount++
    if($origBytes -gt 0){ $huffRatios += $ratioSeed }
  }

  $targetsReport += [pscustomobject]@{
    name         = (Split-Path -Leaf $input)
    algo         = $algo
    mdl          = [pscustomobject]@{
      decision              = $dry.decision
      entropy_bits_per_byte = [double]$dry.entropy_bits_per_byte
      estimated_gain        = [double]$dry.estimated_gain
    }
    seed_size    = [int64]$seedBytes
    orig_size    = [int64]$origBytes
    real_gain    = [int64]($origBytes - $seedBytes)
    round_trip_ok= [bool]$okSha
  }
}

$avgSeedRatio = if($huffRatios.Count -gt 0){ [double]([Math]::Round((($huffRatios | Measure-Object -Average).Average), 4)) } else { $null }

# Big Test (opcional): 1.2 GiB one-symbol com medição de pico de RAM e throughput
$big = $null
if($RunBigTest){
  $bigTarget = Join-Path $dirTargets 'one_symbol_1.2GiB.bin'
  if(-not(Test-Path $bigTarget)){
    $fs=[System.IO.File]::Open($bigTarget,'Create','Write','None')
    try{
      $buf = New-Object byte[] 1048576
      [Array]::Clear($buf,0,$buf.Length)
      [long]$rem = 1200MB
      while($rem -gt 0){ $n=[Math]::Min($rem,$buf.Length); $fs.Write($buf,0,$n); $rem-=$n }
    } finally { $fs.Dispose() }
  }

  $bigSeed  = Join-Path $dirSeeds 'big.seed.json'
  $bigOut   = Join-Path $dirRestored 'big.out'

  # Compress (processo externo)
  $cmdCompress = ". '$corePath'; [void](Build-Seed-From-Stream -InputPath '$bigTarget' -SeedPath '$bigSeed' -ChunkSizeKB 1024)"
  $rC = Start-PeakProcess -Command $cmdCompress -WorkDir $PSScriptRoot

  # Descobre plano pelo header real
  $h = Read-SeedHeaderAndOpenPayload -SeedPath $bigSeed
  try{ $algoBig = $h.Header.algo } finally { $h.Reader.Dispose(); $h.Stream.Dispose() }
  $planBig = @{ op = $(if($algoBig -eq 'huffman_deterministic'){ 'apply.huffman_deterministic' } else { 'apply.raw_copy' }) }

  # Restore (processo externo)
  $cmdRestore = ". '$corePath'; [void](Execute-Plan -Plan @{ op = '$($planBig.op)' } -SeedPath '$bigSeed' -OutPath '$bigOut')"
  $rR = Start-PeakProcess -Command $cmdRestore -WorkDir $PSScriptRoot

  $bigBytes = (Get-Item $bigTarget).Length
  $bigMiB = [double]($bigBytes / 1MB)
  $tpC = if($rC.ElapsedMS -gt 0){ [Math]::Round(($bigMiB / ($rC.ElapsedMS/1000.0)), 3) } else { $null }
  $tpR = if($rR.ElapsedMS -gt 0){ [Math]::Round(($bigMiB / ($rR.ElapsedMS/1000.0)), 3) } else { $null }

  $big = [pscustomobject]@{
    file                  = (Split-Path -Leaf $bigTarget)
    algo                  = $algoBig
    peak_ws_mb_compress   = [double]([math]::Round(($rC.PeakWS/1MB),3))
    peak_ws_mb_restore    = [double]([math]::Round(($rR.PeakWS/1MB),3))
    elapsed_ms_compress   = [int64]$rC.ElapsedMS
    elapsed_ms_restore    = [int64]$rR.ElapsedMS
    throughput_mb_s_comp  = $tpC
    throughput_mb_s_rest  = $tpR
  }

  # Gate de segurança (96 MB)
  if(($big.peak_ws_mb_compress -gt 96) -or ($big.peak_ws_mb_restore -gt 96)){
    $pass = $false
  }
}

# Verificação geral
$allRoundTrips = $true
foreach($t in $targetsReport){ if(-not $t.round_trip_ok){ $allRoundTrips = $false; break } }
$pass = $allRoundTrips
if($RunBigTest -and $big){
  if(($big.peak_ws_mb_compress -gt 96) -or ($big.peak_ws_mb_restore -gt 96)){ $pass = $false }
}

# Relatórios
$ops = [ordered]@{
  huffman_det = @{
    count         = [int]$huffCount
    avg_seed_ratio= $avgSeedRatio
  }
}
if($big){ $ops.big_test = $big }

$ops | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $opsPath -Encoding utf8

$report = [ordered]@{
  pass         = [bool]$pass
  core_sha256  = $coreSha
  core_version = $script:core_version
  targets      = $targetsReport
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $verPath -Encoding utf8

Write-Host ("PASS: TEIA Core v0.3.2.1 harness OK -> Reports: " + $ReportDir)
Write-Host (" - verification_report.json: " + $verPath)
Write-Host (" - ops_summary.json: " + $opsPath)

if(-not $pass){ exit 1 }