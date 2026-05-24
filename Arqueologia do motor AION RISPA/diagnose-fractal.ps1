diagnose-fractal.ps1
Set-StrictMode -Version Latest
param([string]$TargetDir=".",[int]$TestSizeMB=32,[int]$RandomReads=4096,[int]$BlockSize=4096)
$benchDir = Join-Path $TargetDir ".diagnose_fractal"
if (!(Test-Path $benchDir)) { New-Item -ItemType Directory -Path $benchDir | Out-Null }
$testFile = Join-Path $benchDir "perf_test.dat"
$benchLog = Join-Path $benchDir "diagnose_fractal_benchmarks.jsonl"
function New-TestFile([string]$Path,[int]$SizeMB){
$sizeBytes = [int64]$SizeMB * 1MB
$rng = New-Object System.Random
$buf = New-Object byte[] 1048576
$fs = [System.IO.File]::Open($Path,[System.IO.FileMode]::Create,[System.IO.FileAccess]::Write,[System.IO.FileShare]::None)
try {
$remaining = $sizeBytes
while ($remaining -gt 0) {
$rng.NextBytes($buf)
$toWrite = [Math]::Min($buf.Length,$remaining)
$fs.Write($buf,0,$toWrite)
$remaining -= $toWrite
}
} finally { $fs.Dispose() }
}
function Measure-Sequential([string]$Path,[int]$BlockSize){
$fs = [System.IO.File]::Open($Path,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::Read)
$buf = New-Object byte[] $BlockSize
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$total = 0L
try {
while ($true) {
$read = $fs.Read($buf,0,$buf.Length)
if ($read -le 0) { break }
$total += $read
}
} finally { $fs.Dispose(); $sw.Stop() }
$mb = [double]$total / 1MB
$mbps = if ($sw.Elapsed.TotalSeconds -gt 0) { $mb / $sw.Elapsed.TotalSeconds } else { 0.0 }
return @{ bytes = $total; seconds = $sw.Elapsed.TotalSeconds; mbps = $mbps }
}
function Measure-Random([string]$Path,[int]$Reads,[int]$BlockSize){
$len = (Get-Item $Path).Length
$fs = [System.IO.File]::Open($Path,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::Read)
$buf = New-Object byte[] $BlockSize
$rng = New-Object System.Random 1337
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$done = 0
try {
for ($i=0; $i -lt $Reads; $i++) {
$pos = [int64]($rng.NextDouble() * [double]$len)
if ($pos -gt ($len - $BlockSize)) { $pos = $len - $BlockSize }
if ($pos -lt 0) { $pos = 0 }
$fs.Seek($pos,[System.IO.SeekOrigin]::Begin) | Out-Null
[void]$fs.Read($buf,0,$buf.Length)
$done++
}
} finally { $fs.Dispose(); $sw.Stop() }
$bytes = [int64]$done * $BlockSize
$mb = [double]$bytes / 1MB
$mbps = if ($sw.Elapsed.TotalSeconds -gt 0) { $mb / $sw.Elapsed.TotalSeconds } else { 0.0 }
return @{ bytes = $bytes; seconds = $sw.Elapsed.TotalSeconds; mbps = $mbps; reads = $done }
}
if (!(Test-Path $testFile)) {
Write-Host "[TEIA] Criando arquivo de teste"
New-TestFile -Path $testFile -SizeMB $TestSizeMB
}
$seq = $null
$rand = $null
try { Write-Host "[TEIA] Medindo leitura sequencial"; $seq = Measure-Sequential -Path $testFile -BlockSize ($BlockSize * 32) } catch { Write-Host "[AVISO] Falha medicao sequencial" }
try { Write-Host "[TEIA] Medindo leitura aleatoria"; $rand = Measure-Random -Path $testFile -Reads $RandomReads -BlockSize $BlockSize } catch { Write-Host "[AVISO] Falha medicao aleatoria" }
$now = Get-Date
$entry = [ordered]@{ timestamp = $now.ToString("s"); file = $testFile; size_mb = $TestSizeMB; block_size = $BlockSize; random_reads = $RandomReads; sequential = $seq; random = $rand }
try { ($entry | ConvertTo-Json -Depth 6) | Add-Content -Path $benchLog -Encoding UTF8 } catch { Write-Host "[AVISO] Falha ao registrar benchmark" }
$prev = @()
try {
if (Test-Path $benchLog) {
$lines = Get-Content -Path $benchLog -ErrorAction Stop
foreach ($ln in $lines) { if (-not [string]::IsNullOrWhiteSpace($ln)) { $prev += ($ln | ConvertFrom-Json) } }
}
} catch {}
$degraded = $false
try {
$values = @()
foreach ($p in $prev) { if ($p.random -and $p.random.mbps) { $values += [double]$p.random.mbps } }
if ($values.Count -ge 3 -and $rand -and $rand.mbps) {
$sorted = $values | Sort-Object
if ($sorted.Count % 2 -eq 1) { $median = $sorted[int
] } else { $median = (($sorted[$sorted.Count/2-1] + $sorted[$sorted.Count/2]) / 2.0) }
if ($rand.mbps -lt (0.8 * $median)) { $degraded = $true }
}
} catch {}
if ($degraded) {
Write-Host "[TEIA] Degradacao detectada"
$CodexCliPath = "codex"
$q = @"
Como posso melhorar a eficiencia de leitura aleatoria de arquivos fractais neste disco, mantendo compatibilidade com o padrao TEIA?
Responder com script PowerShell puro, sem markdown.
"@
$patchOut = ("fractal_patch_{0}.ps1" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
try {
if (Get-Command $CodexCliPath -ErrorAction SilentlyContinue) {
Get-Content -Raw -Path (New-TemporaryFile) | Out-Null
$null = $q | & $CodexCliPath exec - --output-last-message $patchOut
} else {
Write-Host "[AVISO] Codex CLI not available for patch generation"
}
} catch { Write-Host "[AVISO] Falha ao invocar Codex" }
try {
if (Test-Path -Path $patchOut -PathType Leaf) {
$raw = Get-Content -Path $patchOut -Raw -ErrorAction Stop
$m = [regex]::Match($raw,'(?ms)powershell\s*(.*?)\s*')
$clean = if ($m.Success) { $m.Groups[1].Value } else { $raw }
Set-Content -Path $patchOut -Value $clean -Encoding UTF8
Write-Host ("[TEIA] Patch fractal gerado: {0}" -f $patchOut)
}
} catch { Write-Host "[AVISO] Falha ao normalizar patch" }
} else {
Write-Host "[TEIA] Sem degradacao detectada"
}
Write-Host "[TEIA] Diagnose fractal concluida"