# 2021 - Erro em script PowerShell

### USUÁRIO

PS C:\Users\felip> # TEIA-Delta-Orchestrate.ps1
>> param(
>>   [string]$Root = ".",
>>   [string]$FsMode = "none"   # none|winfsp|projfs (placeholder para seu FS)
>> )
>>
>> $ErrorActionPreference = "Stop"
>> $Root = (Resolve-Path $Root).Path
>> Set-Location $Root
>>
>> function Write-Note($m){ Write-Host "[TEIA] $m" }
>>
>> # 1) AutoProfile → identidade + política Δ por host
>> $auto = Join-Path $Root "TEIA-Fractal-AutoProfile.ps1"
>> if (-not (Test-Path $auto)) {
>>   # Emite AutoProfile mínimo inline (caso ainda não exista)
>>   $autoBody = @'
>> param([string]$Root=".",[int]$ProbeBlockKB=256,[int]$ProbeRandOps=512)
>> $ErrorActionPreference="Stop"; $Root=(Resolve-Path $Root).Path; Set-Location $Root
>> function GR(){ [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,2) }
>> function GC(){ $w=Get-CimInstance Win32_Processor; [pscustomobject]@{Name=$w.Name;Cores=$w.NumberOfCores;Threads=$w.NumberOfLogicalProcessors;MaxClockGHz=[math]::Round($w.MaxClockSpeed/1000,2)} }
>> function GG(){ try{$g=Get-CimInstance Win32_VideoController|Select-Object -First 1;[pscustomobject]@{Name=$g.Name;VRAMGB=[math]::Round($g.AdapterRAM/1GB,2)}}catch{[pscustomobject]@{Name="Unknown";VRAMGB=0}} }
>> $ram=GR; $cpu=GC; $gpu=GG
>> # micro-probe de I/O
>> $probe=Join-Path $Root "tmp_probe.bin"; $sizeMB=64; $sizeBytes=$sizeMB*1MB
>> $fs=[System.IO.File]::Open($probe,[System.IO.FileMode]::Create,[System.IO.FileAccess]::ReadWrite,[System.IO.FileShare]::None); $fs.SetLength($sizeBytes); $fs.Close()
>> $buf=New-Object byte[] ($ProbeBlockKB*1024)
>> $fs=[System.IO.File]::OpenRead($probe); $sw=[System.Diagnostics.Stopwatch]::StartNew(); $read=0
>> while(($r=$fs.Read($buf,0,$buf.Length)) -gt 0){ $read+=$r }; $sw.Stop(); $fs.Close()
>> $seqMB=[math]::Round($read/1MB,2); $seqSec=[math]::Round($sw.Elapsed.TotalSeconds,4)
>> $seqMBps=if($seqSec -gt 0){[math]::Round($seqMB/$seqSec,2)}else{0}
>> $fs=[System.IO.File]::OpenRead($probe); $rnd=[System.Random]::new(); $rsw=[System.Diagnostics.Stopwatch]::StartNew()
>> for($i=0;$i -lt 256;$i++){ $pos=$rnd.NextInt64(0,[math]::Max(0,$sizeBytes-$buf.Length)); $fs.Seek($pos,[System.IO.SeekOrigin]::Begin)|Out-Null; $fs.Read($buf,0,$buf.Length)|Out-Null }
>> $rsw.Stop(); $fs.Close(); Remove-Item $probe -Force
>> $rndMB=[math]::Round((256*$ProbeBlockKB)/1024,2); $rndSec=[math]::Round($rsw.Elapsed.TotalSeconds,4)
>> $rndMBps=if($rndSec -gt 0){[math]::Round($rndMB/$rndSec,2)}else{0}; $latMs=[math]::Round(($rsw.Elapsed.TotalMilliseconds/256),3)
>> $tier= if($ram -le 1){"NANO_1GB"} elseif($ram -le 4){"MICRO_4GB"} elseif($ram -le 16){"STD_16GB"} else{"POWER_32GB_PLUS"}
>> $ws = switch($tier){"NANO_1GB"{256};"MICRO_4GB"{1024};"STD_16GB"{4096};default{8192}}
>> $pref = switch($tier){"NANO_1GB"{64};"MICRO_4GB"{128};"STD_16GB"{256};default{512}}
>> $par = switch($tier){"NANO_1GB"{2};"MICRO_4GB"{3};"STD_16GB"{4};default{6}}
>> $margin= if($latMs -le 0.08){2.0} elseif($latMs -le 0.5){1.5} else{1.3}
>> $p99=[math]::Round([math]::Max(0.3,$latMs*$margin),3)
>> $identity=[ordered]@{timestamp=(Get-Date).ToString("o");ramGB=$ram;cpu=$cpu;gpu=$gpu;probe=@{seqMBps=$seqMBps;rndMBps=$rndMBps;latMs=$latMs};tier=$tier}
>> $policy=[ordered]@{version="Δ-autoadapt-v1";tier=$tier;budgets=@{p99_read_ms=$p99;working_set_mb=$ws;prefetch_mb=$pref;max_parallel=$par;block_kb=$ProbeBlockKB};
>>   modes=@{restore=@{chunk_mb=8;verify_end=$true};preload=@{seq_prefetch_mb=$pref;hot_rand_ops=512};stream=@{seq_ahead_mb=[math]::Min($pref*2,512);hot_offsets="hot_offsets.json"};
>>          moe=@{enabled=$true;experts_total=32;experts_active_per_token= if($tier -eq "NANO_1GB"){2}else{3};quant= if($tier -eq "NANO_1GB"){"INT4"}else{"INT8"};tile_kb=$ProbeBlockKB};
>>          scheduler=@{ram_ws_mb=$ws;vram_ws_mb=0;backpressure=@{iops=8000;lat_ms=$p99}}}}
>> $identityPath=Join-Path $Root "dna_identity.json"; $policyPath=Join-Path $Root "dna_policy_autoadapt.json"
>> ($identity|ConvertTo-Json -Depth 8)|Set-Content $identityPath -Encoding UTF8
>> ($policy|ConvertTo-Json -Depth 8)|Set-Content $policyPath -Encoding UTF8
>> Write-Host "[OK] identity -> $identityPath"; Write-Host "[OK] policy -> $policyPath"
>> '@
>>   Set-Content $auto -Value $autoBody -Encoding UTF8
>> }
>> Write-Note "Gerando identidade e política Δ por host..."
>> pwsh -NoProfile -File $auto -Root $Root | Out-Host
>>
>> $policyPath = Join-Path $Root "dna_policy_autoadapt.json"
>> $hasPolicy = Test-Path $policyPath
>>
>> # 2) (Opcional) FS fractal — placeholder de montagem
>> if ($FsMode -ne "none") {
>>   Write-Note "Montando FS fractal ($FsMode) — placeholder (integre WinFsp/ProjFS aqui)."
>>   # Aqui você pluga seu launcher de FS (serviço/driver), lendo o manifesto atual.
>> }
>>
>> # 3) Encadeamento dos seus scripts existentes com -Policy quando disponível
>> function Try-Run($name,$args){
>>   $p = Join-Path $Root $name
>>   if (Test-Path $p) {
>>     $cmd = @("pwsh","-NoProfile","-File",$p) + $args
>>     Write-Note "→ $name $($args -join ' ')"
>>     & pwsh -NoProfile -File $p @args
>>   } else { Write-Note "(!) $name não encontrado — pulando." }
>> }
>>
>> $policyArgs = @()
>> if ($hasPolicy) { $policyArgs = @("-Policy",$policyPath) }
>>
>> # Ordem curta: Restore → Preload → StreamPilot → Launch (todos tolerantes à ausência de -Policy)
>> Try-Run "TEIA-Fractal-Restore-OnDemand.ps1" $policyArgs
>> Try-Run "TEIA-Fractal-Preload.ps1"          $policyArgs
>> Try-Run "TEIA-Fractal-StreamPilot.ps1"      @($policyArgs + @("-LaunchAfterWarmup"))
>> Try-Run "TEIA-Fractal-Launch.ps1"           $policyArgs
>>
>> Write-Note "Fluxo Δ-elástico concluído."
>>
[TEIA] Gerando identidade e política Δ por host...

cmdlet Get-Content at command pipeline position 1
Supply values for the following parameters:
Path[0]:
PS C:\Users\felip> # TEIA-Delta-Orchestrate.ps1 (ajuste para evitar o erro)
>> param(
>>   [string]$Root = ".",
>>   [string]$FsMode = "none"   # none|winfsp|projfs (placeholder para seu FS)
>> )
>>
>> $ErrorActionPreference = "Stop"
>> $Root = (Resolve-Path $Root).Path
>> Set-Location $Root
>>
>> function Write-Note($m){ Write-Host "[TEIA] $m" }
>>
>> # 1) AutoProfile → identidade + política Δ por host
>> $auto = Join-Path $Root "TEIA-Fractal-AutoProfile.ps1"
>> if (-not (Test-Path $auto)) {
>>   # Emite AutoProfile mínimo inline (caso ainda não exista)
>>   $autoBody = @'
>> param([string]$Root=".",[int]$ProbeBlockKB=256,[int]$ProbeRandOps=512)
>> $ErrorActionPreference="Stop"; $Root=(Resolve-Path $Root).Path; Set-Location $Root
>> function GR(){ [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,2) }
>> function GC(){ $w=Get-CimInstance Win32_Processor; [pscustomobject]@{Name=$w.Name;Cores=$w.NumberOfCores;Threads=$w.NumberOfLogicalProcessors;MaxClockGHz=[math]::Round($w.MaxClockSpeed/1000,2)} }
>> function GG(){ try{$g=Get-CimInstance Win32_VideoController|Select-Object -First 1;[pscustomobject]@{Name=$g.Name;VRAMGB=[math]::Round($g.AdapterRAM/1GB,2)}}catch{[pscustomobject]@{Name="Unknown";VRAMGB=0}} }
>> $ram=GR; $cpu=GC; $gpu=GG
>> # micro-probe de I/O
>> $probe=Join-Path $Root "tmp_probe.bin"; $sizeMB=64; $sizeBytes=$sizeMB*1MB
>> $fs=[System.IO.File]::Open($probe,[System.IO.FileMode]::Create,[System.IO.FileAccess]::ReadWrite,[System.IO.FileShare]::None); $fs.SetLength($sizeBytes); $fs.Close()
>> $buf=New-Object byte[] ($ProbeBlockKB*1024)
>> $fs=[System.IO.File]::OpenRead($probe); $sw=[System.Diagnostics.Stopwatch]::StartNew(); $read=0
>> while(($r=$fs.Read($buf,0,$buf.Length)) -gt 0){ $read+=$r }; $sw.Stop(); $fs.Close()
>> $seqMB=[math]::Round($read/1MB,2); $seqSec=[math]::Round($sw.Elapsed.TotalSeconds,4)
>> $seqMBps=if($seqSec -gt 0){[math]::Round($seqMB/$seqSec,2)}else{0}
>> $fs=[System.IO.File]::OpenRead($probe); $rnd=[System.Random]::new(); $rsw=[System.Diagnostics.Stopwatch]::StartNew()
>> for($i=0;$i -lt 256;$i++){ $pos=$rnd.NextInt64(0,[math]::Max(0,$sizeBytes-$buf.Length)); $fs.Seek($pos,[System.IO.SeekOrigin]::Begin)|Out-Null; $fs.Read($buf,0,$buf.Length)|Out-Null }
>> $rsw.Stop(); $fs.Close(); Remove-Item $probe -Force
>> $rndMB=[math]::Round((256*$ProbeBlockKB)/1024,2); $rndSec=[math]::Round($rsw.Elapsed.TotalSeconds,4)
>> $rndMBps=if($rndSec -gt 0){[math]::Round($rndMB/$rndSec,2)}else{0}; $latMs=[math]::Round(($rsw.Elapsed.TotalMilliseconds/256),3)
>> $tier= if($ram -le 1){"NANO_1GB"} elseif($ram -le 4){"MICRO_4GB"} elseif($ram -le 16){"STD_16GB"} else{"POWER_32GB_PLUS"}
>> $ws = switch($tier){"NANO_1GB"{256};"MICRO_4GB"{1024};"STD_16GB"{4096};default{8192}}
>> $pref = switch($tier){"NANO_1GB"{64};"MICRO_4GB"{128};"STD_16GB"{256};default{512}}
>> $par = switch($tier){"NANO_1GB"{2};"MICRO_4GB"{3};"STD_16GB"{4};default{6}}
>> $margin= if($latMs -le 0.08){2.0} elseif($latMs -le 0.5){1.5} else{1.3}
>> $p99=[math]::Round([math]::Max(0.3,$latMs*$margin),3)
>> $identity=[ordered]@{timestamp=(Get-Date).ToString("o");ramGB=$ram;cpu=$cpu;gpu=$gpu;probe=@{seqMBps=$seqMBps;rndMBps=$rndMBps;latMs=$latMs};tier=$tier}
>> $policy=[ordered]@{version="Δ-autoadapt-v1";tier=$tier;budgets=@{p99_read_ms=$p99;working_set_mb=$ws;prefetch_mb=$pref;max_parallel=$par;block_kb=$ProbeBlockKB};
>>   modes=@{restore=@{chunk_mb=8;verify_end=$true};preload=@{seq_prefetch_mb=$pref;hot_rand_ops=512};stream=@{seq_ahead_mb=[math]::Min($pref*2,512);hot_offsets="hot_offsets.json"};
>>          moe=@{enabled=$true;experts_total=32;experts_active_per_token= if($tier -eq "NANO_1GB"){2}else{3};quant= if($tier -eq "NANO_1GB"){"INT4"}else{"INT8"};tile_kb=$ProbeBlockKB};
>>          scheduler=@{ram_ws_mb=$ws;vram_ws_mb=0;backpressure=@{iops=8000;lat_ms=$p99}}}}
>> $identityPath=Join-Path $Root "dna_identity.json"; $policyPath=Join-Path $Root "dna_policy_autoadapt.json"
>> ($identity|ConvertTo-Json -Depth 8)|Set-Content $identityPath -Encoding UTF8
>> ($policy|ConvertTo-Json -Depth 8)|Set-Content $policyPath -Encoding UTF8
>> Write-Host "[OK] identity -> $identityPath"; Write-Host "[OK] policy -> $policyPath"
>> '@
>>   Set-Content $auto -Value $autoBody -Encoding UTF8
>> }
>>
>> Write-Note "Gerando identidade e política Δ por host..."
>> pwsh -NoProfile -File $auto -Root $Root | Out-Host
>>
[TEIA] Gerando identidade e política Δ por host...

cmdlet Get-Content at command pipeline position 1
Supply values for the following parameters:
Path[0]:
PS C:\Users\felip> # TEIA-Delta-Orchestrate.ps1
>> param(
>>   [string]$Root = ".",
>>   [string]$FsMode = "none"   # none|winfsp|projfs (placeholder para seu FS)
>> )
>>
>> $ErrorActionPreference = "Stop"
>> $Root = (Resolve-Path $Root).Path
>> Set-Location $Root
>>
>> function Write-Note($m){ Write-Host "[TEIA] $m" }
>>
>> # 1) AutoProfile → identidade + política Δ por host
>> $auto = Join-Path $Root "TEIA-Fractal-AutoProfile.ps1"
>> if (-not (Test-Path $auto)) {
>>   # Emite AutoProfile mínimo inline (caso ainda não exista)
>>   $autoBody = @'
>> param([string]$Root=".",[int]$ProbeBlockKB=256,[int]$ProbeRandOps=512)
>> $ErrorActionPreference="Stop"; $Root=(Resolve-Path $Root).Path; Set-Location $Root
>> function GR(){ [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,2) }
>> function GC(){ $w=Get-CimInstance Win32_Processor; [pscustomobject]@{Name=$w.Name;Cores=$w.NumberOfCores;Threads=$w.NumberOfLogicalProcessors;MaxClockGHz=[math]::Round($w.MaxClockSpeed/1000,2)} }
>> function GG(){ try{$g=Get-CimInstance Win32_VideoController|Select-Object -First 1;[pscustomobject]@{Name=$g.Name;VRAMGB=[math]::Round($g.AdapterRAM/1GB,2)}}catch{[pscustomobject]@{Name="Unknown";VRAMGB=0}} }
>> $ram=GR; $cpu=GC; $gpu=GG
>> # micro-probe de I/O
>> $probe=Join-Path $Root "tmp_probe.bin"; $sizeMB=64; $sizeBytes=$sizeMB*1MB
>> $fs=[System.IO.File]::Open($probe,[System.IO.FileMode]::Create,[System.IO.FileAccess]::ReadWrite,[System.IO.FileShare]::None); $fs.SetLength($sizeBytes); $fs.Close()
>> $buf=New-Object byte[] ($ProbeBlockKB*1024)
>> $fs=[System.IO.File]::OpenRead($probe); $sw=[System.Diagnostics.Stopwatch]::StartNew(); $read=0
>> while(($r=$fs.Read($buf,0,$buf.Length)) -gt 0){ $read+=$r }; $sw.Stop(); $fs.Close()
>> $seqMB=[math]::Round($read/1MB,2); $seqSec=[math]::Round($sw.Elapsed.TotalSeconds,4)
>> $seqMBps=if($seqSec -gt 0){[math]::Round($seqMB/$seqSec,2)}else{0}
>> $fs=[System.IO.File]::OpenRead($probe); $rnd=[System.Random]::new(); $rsw=[System.Diagnostics.Stopwatch]::StartNew()
>> for($i=0;$i -lt 256;$i++){ $pos=$rnd.NextInt64(0,[math]::Max(0,$sizeBytes-$buf.Length)); $fs.Seek($pos,[System.IO.SeekOrigin]::Begin)|Out-Null; $fs.Read($buf,0,$buf.Length)|Out-Null }
>> $rsw.Stop(); $fs.Close(); Remove-Item $probe -Force
>> $rndMB=[math]::Round((256*$ProbeBlockKB)/1024,2); $rndSec=[math]::Round($rsw.Elapsed.TotalSeconds,4)
>> $rndMBps=if($rndSec -gt 0){[math]::Round($rndMB/$rndSec,2)}else{0}; $latMs=[math]::Round(($rsw.Elapsed.TotalMilliseconds/256),3)
>> $tier= if($ram -le 1){"NANO_1GB"} elseif($ram -le 4){"MICRO_4GB"} elseif($ram -le 16){"STD_16GB"} else{"POWER_32GB_PLUS"}
>> $ws = switch($tier){"NANO_1GB"{256};"MICRO_4GB"{1024};"STD_16GB"{4096};default{8192}}
>> $pref = switch($tier){"NANO_1GB"{64};"MICRO_4GB"{128};"STD_16GB"{256};default{512}}
>> $par = switch($tier){"NANO_1GB"{2};"MICRO_4GB"{3};"STD_16GB"{4};default{6}}
>> $margin= if($latMs -le 0.08){2.0} elseif($latMs -le 0.5){1.5} else{1.3}
>> $p99=[math]::Round([math]::Max(0.3,$latMs*$margin),3)
>> $identity=[ordered]@{timestamp=(Get-Date).ToString("o");ramGB=$ram;cpu=$cpu;gpu=$gpu;probe=@{seqMBps=$seqMBps;rndMBps=$rndMBps;latMs=$latMs};tier=$tier}
>> $policy=[ordered]@{version="Δ-autoadapt-v1";tier=$tier;budgets=@{p99_read_ms=$p99;working_set_mb=$ws;prefetch_mb=$pref;max_parallel=$par;block_kb=$ProbeBlockKB};
>>   modes=@{restore=@{chunk_mb=8;verify_end=$true};preload=@{seq_prefetch_mb=$pref;hot_rand_ops=512};stream=@{seq_ahead_mb=[math]::Min($pref*2,512);hot_offsets="hot_offsets.json"};
>>          moe=@{enabled=$true;experts_total=32;experts_active_per_token= if($tier -eq "NANO_1GB"){2}else{3};quant= if($tier -eq "NANO_1GB"){"INT4"}else{"INT8"};tile_kb=$ProbeBlockKB};
>>          scheduler=@{ram_ws_mb=$ws;vram_ws_mb=0;backpressure=@{iops=8000;lat_ms=$p99}}}}
>> $identityPath=Join-Path $Root "dna_identity.json"; $policyPath=Join-Path $Root "dna_policy_autoadapt.json"
>> ($identity|ConvertTo-Json -Depth 8)|Set-Content $identityPath -Encoding UTF8
>> ($policy|ConvertTo-Json -Depth 8)|Set-Content $policyPath -Encoding UTF8
>> Write-Host "[OK] identity -> $identityPath"; Write-Host "[OK] policy -> $policyPath"
>> '@
>>   Set-Content $auto -Value $autoBody -Encoding UTF8
>> }
>>
>> Write-Note "Gerando identidade e política Δ por host..."
>> try {
>>     pwsh -NoProfile -File $auto -Root $Root | Out-Host
>> } catch {
>>     Write-Host "[Erro] Não foi possível gerar identidade e política: $_"
>> }
>>
[TEIA] Gerando identidade e política Δ por host...

cmdlet Get-Content at command pipeline position 1
Supply values for the following parameters:
Path[0]:
PS C:\Users\felip> # ================= TEIA-Fractal-ProvaReal-v2.ps1 =================
>> $ErrorActionPreference = 'Stop'
>>
>> $root     = "D:\Teia\TEIA_NUCLEO\offline\nano"
>> $restore  = Join-Path $root "TEIA-Fractal-RestoreOnDemand.ps1"
>> $preload  = Join-Path $root "TEIA-Fractal-Preload.ps1"
>> $launcher = Join-Path $root "TEIA-Fractal-Launch.ps1"
>>
>> $exeName  = "FortniteClient-Win64-Shipping.exe"
>> $exePath  = Join-Path $root $exeName
>>
>> $metrics  = Join-Path $root "prova_metrics.log"
>> $cacheLog = Join-Path $root "cache_stats.log"
>>
>> # --- Normalização (idempotência TEIA) ---
>> New-Item -ItemType Directory -Force -Path $root | Out-Null
>> Remove-Item $metrics,$cacheLog -Force -ErrorAction SilentlyContinue
>>
>> "=== TEIA ProvaReal START $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" |
>>   Tee-Object -FilePath $metrics -Append | Out-Null
>>
>> # 0) Baseline SHA256
>> if (Test-Path $exePath) {
>>   $sha = (Get-FileHash $exePath -Algorithm SHA256).Hash
>> } else {
>>   $sha = "EMPTY"
>>   if (-not (Test-Path $exePath)) {
>>     New-Item -ItemType File -Path $exePath -Force | Out-Null
>>     Write-Warning "[TEIA] Placeholder criado para $exeName"
>>   }
>> }
>> "[TEIA] Baseline SHA256 = $sha" | Tee-Object -FilePath $metrics -Append
>>
>> # 1) Restore OnDemand (chunked)
>> if (Test-Path $restore) {
>>   & $restore -Root $root -Name $exeName -ChunkSizeMB 8 -VerifyEnd |
>>     Tee-Object -FilePath $metrics -Append
>> }
>>
>> # 2) Preload (caminho absoluto + prefetch MB)
>> if (Test-Path $preload) {
>>   & $preload $exePath 32 | Tee-Object -FilePath $metrics -Append
>> }
>>
>> # 3) Launch
>> $sw = [System.Diagnostics.Stopwatch]::StartNew()
>> if (Test-Path $launcher) {
>>   if ($sha -eq "EMPTY") {
>>     "[TEIA] Launch SIMULAÇÃO -> $exePath (placeholder detectado)" |
>>       Tee-Object -FilePath $metrics -Append
>>   } else {
>>     & $launcher -Exe $exePath | Tee-Object -FilePath $metrics -Append
>>   }
>> }
>> $sw.Stop()
>> "[TEIA] Launch time = $($sw.Elapsed.TotalSeconds) s" |
>>   Tee-Object -FilePath $metrics -Append
>>
>> # 4) Telemetria
>> "[TEIA] Cache stats:" | Tee-Object -FilePath $metrics -Append
>>
>> # Fallback caso o arquivo de cache não exista
>> if (Test-Path $cacheLog) {
>>   Get-Content $cacheLog -ErrorAction SilentlyContinue |
>>     Tee-Object -FilePath $metrics -Append
>> } else {
>>   Write-Warning "[TEIA] Arquivo de cache não encontrado: $cacheLog"
>> }
>>
>> "=== TEIA ProvaReal END $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" |
>>   Tee-Object -FilePath $metrics -Append | Out-Null
>>
>> Write-Host "[TEIA] ProvaReal concluída. Métricas em: $metrics"
>> # ==============================================================
>>
[TEIA] Baseline SHA256 = E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855
[TEIA] Restoring chunk 1 (8 MB)
[TEIA] Restoring chunk 2 (16 MB)
[TEIA] Restoring chunk 3 (24 MB)
[TEIA] Restoring chunk 4 (32 MB)
[TEIA] Restoring chunk 5 (40 MB)
[TEIA] Verificação SHA256 final (simulada)
[TEIA] Log ativo em: D:\Teia\TEIA_NUCLEO\offline\nano\dna_preload.log
[2025-08-25 22:46:23.090] FortniteClient-Win64-Shipping.exe SEQ | File=FortniteClient-Win64-Shipping.exe Prefetch=0MB Time=0,013s Thru=0 MB/s
[2025-08-25 22:46:23.106] 0 RND | Ops=0 Size=0MB Time=0,001s Thru=0 MB/s IOPS=0 LatAvg=0ms LatMax=0ms
Start-Process: D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fractal-Launch.ps1:29
Line |
  29 |  Start-Process -FilePath $Exe -WorkingDirectory (Split-Path $Exe -Pare …
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | This command cannot be run due to the error: An error occurred trying to start process
     | 'D:\Teia\TEIA_NUCLEO\offline\nano\FortniteClient-Win64-Shipping.exe' with working directory
     | 'D:\Teia\TEIA_NUCLEO\offline\nano'. The specified executable is not a valid application for this OS platform.
PS C:\Users\felip> Get-Command "D:\Teia\TEIA_NUCLEO\offline\nano\FortniteClient-Win64-Shipping.exe" | Select-Object Name, FileVersionInfo
>>

Name                              FileVersionInfo
----                              ---------------
FortniteClient-Win64-Shipping.exe File:             D:\Teia\TEIA_NUCLEO\offline\nano\FortniteClient-Win64-Shipping.…

PS C:\Users\felip> (Get-Item "D:\Teia\TEIA_NUCLEO\offline\nano\FortniteClient-Win64-Shipping.exe").VersionInfo
>>

ProductVersion   FileVersion      FileName
--------------   -----------      --------
                                  D:\Teia\TEIA_NUCLEO\offline\nano\FortniteClient-Win64-Shipping.exe

PS C:\Users\felip> Get-Command "D:\Teia\TEIA_NUCLEO\offline\nano\FortniteClient-Win64-Shipping.exe" | Select-Object Name, Path
>>

Name                              Path
----                              ----
FortniteClient-Win64-Shipping.exe D:\Teia\TEIA_NUCLEO\offline\nano\FortniteClient-Win64-Shipping.exe

PS C:\Users\felip> Start-Process "D:\Teia\TEIA_NUCLEO\offline\nano\FortniteClient-Win64-Shipping.exe"
>>
Start-Process: This command cannot be run due to the error: An error occurred trying to start process 'D:\Teia\TEIA_NUCLEO\offline\nano\FortniteClient-Win64-Shipping.exe' with working directory 'C:\Users\felip'. The specified executable is not a valid application for this OS platform.
PS C:\Users\felip> (Get-Item "D:\Teia\TEIA_NUCLEO\offline\nano\FortniteClient-Win64-Shipping.exe").GetAccessControl()
>>
InvalidOperation: Method invocation failed because [System.IO.FileInfo] does not contain a method named 'GetAccessControl'.
PS C:\Users\felip> ^C
PS C:\Users\felip> (Get-Command "D:\Teia\TEIA_NUCLEO\offline\nano\FortniteClient-Win64-Shipping.exe").FileVersionInfo | Select-Object FileArchitecture
>>

FileArchitecture
----------------


PS C:\Users\felip> param(
>>   [string]$Root = ".",
>>   [string]$FsMode = "none"   # none|winfsp|projfs (placeholder para seu FS)
>> )
>>
>> $ErrorActionPreference = "Stop"
>> $Root = (Resolve-Path $Root).Path
>> Set-Location $Root
>>
>> function Write-Note($m){ Write-Host "[TEIA] $m" }
>>
>> # 1) AutoProfile → identidade + política Δ por host
>> $auto = Join-Path $Root "TEIA-Fractal-AutoProfile.ps1"
>> if (-not (Test-Path $auto)) {
>>   # Emite AutoProfile mínimo inline (caso ainda não exista)
>>   $autoBody = @'
>> param([string]$Root=".",[int]$ProbeBlockKB=256,[int]$ProbeRandOps=512)
>> $ErrorActionPreference="Stop"; $Root=(Resolve-Path $Root).Path; Set-Location $Root
>> function GR(){ [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,2) }
>> function GC(){ $w=Get-CimInstance Win32_Processor; [pscustomobject]@{Name=$w.Name;Cores=$w.NumberOfCores;Threads=$w.NumberOfLogicalProcessors;MaxClockGHz=[math]::Round($w.MaxClockSpeed/1000,2)} }
>> function GG(){ try{$g=Get-CimInstance Win32_VideoController|Select-Object -First 1;[pscustomobject]@{Name=$g.Name;VRAMGB=[math]::Round($g.AdapterRAM/1GB,2)}}catch{[pscustomobject]@{Name="Unknown";VRAMGB=0}} }
>> $ram=GR; $cpu=GC; $gpu=GG
>> $probe=Join-Path $Root "tmp_probe.bin"; $sizeMB=64; $sizeBytes=$sizeMB*1MB
>> $fs=[System.IO.File]::Open($probe,[System.IO.FileMode]::Create,[System.IO.FileAccess]::ReadWrite,[System.IO.FileShare]::None); $fs.SetLength($sizeBytes); $fs.Close()
>> $buf=New-Object byte[] ($ProbeBlockKB*1024)
>> $fs=[System.IO.File]::OpenRead($probe); $sw=[System.Diagnostics.Stopwatch]::StartNew(); $read=0
>> while(($r=$fs.Read($buf,0,$buf.Length)) -gt 0){ $read+=$r }; $sw.Stop(); $fs.Close()
>> $seqMB=[math]::Round($read/1MB,2); $seqSec=[math]::Round($sw.Elapsed.TotalSeconds,4)
>> $seqMBps=if($seqSec -gt 0){[math]::Round($seqMB/$seqSec,2)}else{0}
>> $fs=[System.IO.File]::OpenRead($probe); $rnd=[System.Random]::new(); $rsw=[System.Diagnostics.Stopwatch]::StartNew()
>> for($i=0;$i -lt 256;$i++){ $pos=$rnd.NextInt64(0,[math]::Max(0,$sizeBytes-$buf.Length)); $fs.Seek($pos,[System.IO.SeekOrigin]::Begin)|Out-Null; $fs.Read($buf,0,$buf.Length)|Out-Null }
>> $rsw.Stop(); $fs.Close(); Remove-Item $probe -Force
>> $rndMB=[math]::Round((256*$ProbeBlockKB)/1024,2); $rndSec=[math]::Round($rsw.Elapsed.TotalSeconds,4)
>> $rndMBps=if($rndSec -gt 0){[math]::Round($rndMB/$rndSec,2)}else{0}; $latMs=[math]::Round(($rsw.Elapsed.TotalMilliseconds/256),3)
>> $tier= if($ram -le 1){"NANO_1GB"} elseif($ram -le 4){"MICRO_4GB"} elseif($ram -le 16){"STD_16GB"} else{"POWER_32GB_PLUS"}
>> $ws = switch($tier){"NANO_1GB"{256};"MICRO_4GB"{1024};"STD_16GB"{4096};default{8192}}
>> $pref = switch($tier){"NANO_1GB"{64};"MICRO_4GB"{128};"STD_16GB"{256};default{512}}
>> $par = switch($tier){"NANO_1GB"{2};"MICRO_4GB"{3};"STD_16GB"{4};default{6}}
>> $margin= if($latMs -le 0.08){2.0} elseif($latMs -le 0.5){1.5} else{1.3}
>> $p99=[math]::Round([math]::Max(0.3,$latMs*$margin),3)
>> $identity=[ordered]@{timestamp=(Get-Date).ToString("o");ramGB=$ram;cpu=$cpu;gpu=$gpu;probe=@{seqMBps=$seqMBps;rndMBps=$rndMBps;latMs=$latMs};tier=$tier}
>> $policy=[ordered]@{version="Δ-autoadapt-v1";tier=$tier;budgets=@{p99_read_ms=$p99;working_set_mb=$ws;prefetch_mb=$pref;max_parallel=$par;block_kb=$ProbeBlockKB};
>> modes=@{restore=@{chunk_mb=8;verify_end=$true};preload=@{seq_prefetch_mb=$pref;hot_rand_ops=512};stream=@{seq_ahead_mb=[math]::Min($pref*2,512);hot_offsets="hot_offsets.json"};
>> moe=@{enabled=$true;experts_total=32;experts_active_per_token= if($tier -eq "NANO_1GB"){2}else{3};quant= if($tier -eq "NANO_1GB"){"INT4"}else{"INT8"};tile_kb=$ProbeBlockKB};
>> scheduler=@{ram_ws_mb=$ws;vram_ws_mb=0;backpressure=@{iops=8000;lat_ms=$p99}}}}
>> $identityPath=Join-Path $Root "dna_identity.json"; $policyPath=Join-Path $Root "dna_policy_autoadapt.json"
>> ($identity|ConvertTo-Json -Depth 8)|Set-Content $identityPath -Encoding UTF8
>> ($policy|ConvertTo-Json -Depth 8)|Set-Content $policyPath -Encoding UTF8
>> Write-Host "[OK] identity -> $identityPath"; Write-Host "[OK] policy -> $policyPath"
>> '@
>>   Set-Content $auto -Value $autoBody -Encoding UTF8
>> }
>>
>> Write-Note "Gerando identidade e política Δ por host..."
>> try {
>>     pwsh -NoProfile -File $auto -Root $Root | Out-Host
>> } catch {
>>     Write-Host "[Erro] Não foi possível gerar identidade e política: $_"
>> }
>>
>> $policyPath = Join-Path $Root "dna_policy_autoadapt.json"
>> $hasPolicy = Test-Path $policyPath
>>
>> # 2) FS fractal — placeholder de montagem
>> if ($FsMode -ne "none") {
>>     Write-Note "Montando FS fractal ($FsMode) — placeholder (integre WinFsp/ProjFS aqui)."
>> }
>>
>> # 3) Encadeamento dos seus scripts existentes com -Policy quando disponível
>> function Try-Run($name,$args){
>>   $p = Join-Path $Root $name
>>   if (Test-Path $p) {
>>     $cmd = @("pwsh","-NoProfile","-File",$p) + $args
>>     Write-Note "→ $name $($args -join ' ')"
>>     & pwsh -NoProfile -File $p @args
>>   } else { Write-Note "(!) $name não encontrado — pulando." }
>> }
>>
>> $policyArgs = @()
>> if ($hasPolicy) { $policyArgs = @("-Policy",$policyPath) }
>>
>> # Ordem curta: Restore → Preload → StreamPilot → Launch (todos tolerantes à ausência de -Policy)
>> Try-Run "TEIA-Fractal-Restore-OnDemand.ps1" $policyArgs
>> Try-Run "TEIA-Fractal-Preload.ps1"          $policyArgs
>> Try-Run "TEIA-Fractal-StreamPilot.ps1"      @($policyArgs + @("-LaunchAfterWarmup"))
>> Try-Run "TEIA-Fractal-Launch.ps1"           $policyArgs
>>
>> Write-Note "Fluxo Δ-elástico concluído."
>>
[TEIA] Gerando identidade e política Δ por host...

cmdlet Get-Content at command pipeline position 1
Supply values for the following parameters:
Path[0]:
PS C:\Users\felip> param(
>>   [string]$Root = ".",
>>   [string]$FsMode = "none"   # none|winfsp|projfs (placeholder para seu FS)
>> )
>>
>> $ErrorActionPreference = "Stop"
>> $Root = (Resolve-Path $Root).Path
>> Set-Location $Root
>>
>> function Write-Note($m){ Write-Host "[TEIA] $m" }
>>
>> # 1) AutoProfile → identidade + política Δ por host
>> $auto = Join-Path $Root "TEIA-Fractal-AutoProfile.ps1"
>> if (-not (Test-Path $auto)) {
>>     # Emite AutoProfile mínimo inline (caso ainda não exista)
>>     $autoBody = @'
>> param([string]$Root=".",[int]$ProbeBlockKB=256,[int]$ProbeRandOps=512)
>> $ErrorActionPreference="Stop"; $Root=(Resolve-Path $Root).Path; Set-Location $Root
>> function GR(){ [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,2) }
>> function GC(){ $w=Get-CimInstance Win32_Processor; [pscustomobject]@{Name=$w.Name;Cores=$w.NumberOfCores;Threads=$w.NumberOfLogicalProcessors;MaxClockGHz=[math]::Round($w.MaxClockSpeed/1000,2)} }
>> function GG(){ try{$g=Get-CimInstance Win32_VideoController|Select-Object -First 1;[pscustomobject]@{Name=$g.Name;VRAMGB=[math]::Round($g.AdapterRAM/1GB,2)}}catch{[pscustomobject]@{Name="Unknown";VRAMGB=0}} }
>> $ram=GR; $cpu=GC; $gpu=GG
>> $probe=Join-Path $Root "tmp_probe.bin"; $sizeMB=64; $sizeBytes=$sizeMB*1MB
>> $fs=[System.IO.File]::Open($probe,[System.IO.FileMode]::Create,[System.IO.FileAccess]::ReadWrite,[System.IO.FileShare]::None); $fs.SetLength($sizeBytes); $fs.Close()
>> $buf=New-Object byte[] ($ProbeBlockKB*1024)
>> $fs=[System.IO.File]::OpenRead($probe); $sw=[System.Diagnostics.Stopwatch]::StartNew(); $read=0
>> while(($r=$fs.Read($buf,0,$buf.Length)) -gt 0){ $read+=$r }; $sw.Stop(); $fs.Close()
>> $seqMB=[math]::Round($read/1MB,2); $seqSec=[math]::Round($sw.Elapsed.TotalSeconds,4)
>> $seqMBps=if($seqSec -gt 0){[math]::Round($seqMB/$seqSec,2)}else{0}
>> $fs=[System.IO.File]::OpenRead($probe); $rnd=[System.Random]::new(); $rsw=[System.Diagnostics.Stopwatch]::StartNew()
>> for($i=0;$i -lt 256;$i++){ $pos=$rnd.NextInt64(0,[math]::Max(0,$sizeBytes-$buf.Length)); $fs.Seek($pos,[System.IO.SeekOrigin]::Begin)|Out-Null; $fs.Read($buf,0,$buf.Length)|Out-Null }
>> $rsw.Stop(); $fs.Close(); Remove-Item $probe -Force
>> $rndMB=[math]::Round((256*$ProbeBlockKB)/1024,2); $rndSec=[math]::Round($rsw.Elapsed.TotalSeconds,4)
>> $rndMBps=if($rndSec -gt 0){[math]::Round($rndMB/$rndSec,2)}else{0}; $latMs=[math]::Round(($rsw.Elapsed.TotalMilliseconds/256),3)
>> $tier= if($ram -le 1){"NANO_1GB"} elseif($ram -le 4){"MICRO_4GB"} elseif($ram -le 16){"STD_16GB"} else{"POWER_32GB_PLUS"}
>> $ws = switch($tier){"NANO_1GB"{256};"MICRO_4GB"{1024};"STD_16GB"{4096};default{8192}}
>> $pref = switch($tier){"NANO_1GB"{64};"MICRO_4GB"{128};"STD_16GB"{256};default{512}}
>> $par = switch($tier){"NANO_1GB"{2};"MICRO_4GB"{3};"STD_16GB"{4};default{6}}
>> $margin= if($latMs -le 0.08){2.0} elseif($latMs -le 0.5){1.5} else{1.3}
>> $p99=[math]::Round([math]::Max(0.3,$latMs*$margin),3)
>> $identity=[ordered]@{timestamp=(Get-Date).ToString("o");ramGB=$ram;cpu=$cpu;gpu=$gpu;probe=@{seqMBps=$seqMBps;rndMBps=$rndMBps;latMs=$latMs};tier=$tier}
>> $policy=[ordered]@{version="Δ-autoadapt-v1";tier=$tier;budgets=@{p99_read_ms=$p99;working_set_mb=$ws;prefetch_mb=$pref;max_parallel=$par;block_kb=$ProbeBlockKB};
>> modes=@{restore=@{chunk_mb=8;verify_end=$true};preload=@{seq_prefetch_mb=$pref;hot_rand_ops=512};stream=@{seq_ahead_mb=[math]::Min($pref*2,512);hot_offsets="hot_offsets.json"};
>> moe=@{enabled=$true;experts_total=32;experts_active_per_token= if($tier -eq "NANO_1GB"){2}else{3};quant= if($tier -eq "NANO_1GB"){"INT4"}else{"INT8"};tile_kb=$ProbeBlockKB};
>> scheduler=@{ram_ws_mb=$ws;vram_ws_mb=0;backpressure=@{iops=8000;lat_ms=$p99}}}}
>> $identityPath=Join-Path $Root "dna_identity.json"; $policyPath=Join-Path $Root "dna_policy_autoadapt.json"
>> ($identity|ConvertTo-Json -Depth 8)|Set-Content $identityPath -Encoding UTF8
>> ($policy|ConvertTo-Json -Depth 8)|Set-Content $policyPath -Encoding UTF8
>> Write-Host "[OK] identity -> $identityPath"; Write-Host "[OK] policy -> $policyPath"
>> '@
>>     Set-Content $auto -Value $autoBody -Encoding UTF8
>> }
>>
>> Write-Note "Gerando identidade e política Δ por host..."
>> try {
>>     pwsh -NoProfile -File $auto -Root $Root | Out-Host
>> } catch {
>>     Write-Host "[Erro] Não foi possível gerar identidade e política: $_"
>> }
>>
>> $policyPath = Join-Path $Root "dna_policy_autoadapt.json"
>> $hasPolicy = Test-Path $policyPath
>>
>> # 2) FS fractal — placeholder de montagem
>> if ($FsMode -ne "none") {
>>     Write-Note "Montando FS fractal ($FsMode) — placeholder (integre WinFsp/ProjFS aqui)."
>> }
>>
>> # 3) Encadeamento dos seus scripts existentes com -Policy quando disponível
>> function Try-Run($name,$args){
>>     $p = Join-Path $Root $name
>>     if (Test-Path $p) {
>>         $cmd = @("pwsh","-NoProfile","-File",$p) + $args
>>         Write-Note "→ $name $($args -join ' ')"
>>         & pwsh -NoProfile -File $p @args
>>     } else {
>>         Write-Note "(!) $name não encontrado — pulando."
>>     }
>> }
>>
>> $policyArgs = @()
>> if ($hasPolicy) { $policyArgs = @("-Policy",$policyPath) }
>>
>> # Ordem curta: Restore → Preload → StreamPilot → Launch (todos tolerantes à ausência de -Policy)
>> Try-Run "TEIA-Fractal-Restore-OnDemand.ps1" $policyArgs
>> Try-Run "TEIA-Fractal-Preload.ps1"          $policyArgs
>> Try-Run "TEIA-Fractal-StreamPilot.ps1"      @($policyArgs + @("-LaunchAfterWarmup"))
>> Try-Run "TEIA-Fractal-Launch.ps1"           $policyArgs
>>
>> Write-Note "Fluxo Δ-elástico concluído."
>>
[TEIA] Gerando identidade e política Δ por host...

cmdlet Get-Content at command pipeline position 1
Supply values for the following parameters:
Path[0]: param(
Path[1]:   [string]$Root = ".",
Path[2]:   [string]$FsMode = "none"   # none|winfsp|projfs (placeholder para seu FS)
Path[3]: )
Path[4]:
Get-Content: C:\Users\felip\TEIA-Fractal-AutoProfile.ps1:6
Line |
   6 |  $ram=GR; $cpu=GC; $gpu=GG
     |                ~~
     | Cannot find path 'C:\Users\felip\param(' because it does not exist.
[TEIA] (!) TEIA-Fractal-Restore-OnDemand.ps1 não encontrado — pulando.
[TEIA] (!) TEIA-Fractal-Preload.ps1 não encontrado — pulando.
[TEIA] (!) TEIA-Fractal-StreamPilot.ps1 não encontrado — pulando.
[TEIA] (!) TEIA-Fractal-Launch.ps1 não encontrado — pulando.
[TEIA] Fluxo Δ-elástico concluído.
PS C:\Users\felip> $ErrorActionPreference = "Stop"
PS C:\Users\felip> $Root = (Resolve-Path $Root).Path
PS C:\Users\felip> Set-Location $Root
PS C:\Users\felip>
PS C:\Users\felip> function Write-Note($m){ Write-Host "[TEIA] $m" }
PS C:\Users\felip>
PS C:\Users\felip> # 1) AutoProfile → identidade + política Δ por host
PS C:\Users\felip> $auto = Join-Path $Root "TEIA-Fractal-AutoProfile.ps1"
PS C:\Users\felip> if (-not (Test-Path $auto)) {
>>     # Emite AutoProfile mínimo inline (caso ainda não exista)
>>     $autoBody = @'
>> param([string]$Root=".",[int]$ProbeBlockKB=256,[int]$ProbeRandOps=512)
>> $ErrorActionPreference="Stop"; $Root=(Resolve-Path $Root).Path; Set-Location $Root
>> function GR(){ [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,2) }
>> function GC(){ $w=Get-CimInstance Win32_Processor; [pscustomobject]@{Name=$w.Name;Cores=$w.NumberOfCores;Threads=$w.NumberOfLogicalProcessors;MaxClockGHz=[math]::Round($w.MaxClockSpeed/1000,2)} }
>> function GG(){ try{$g=Get-CimInstance Win32_VideoController|Select-Object -First 1;[pscustomobject]@{Name=$g.Name;VRAMGB=[math]::Round($g.AdapterRAM/1GB,2)}}catch{[pscustomobject]@{Name="Unknown";VRAMGB=0}} }
>> $ram=GR; $cpu=GC; $gpu=GG
>> $probe=Join-Path $Root "tmp_probe.bin"; $sizeMB=64; $sizeBytes=$sizeMB*1MB
>> $fs=[System.IO.File]::Open($probe,[System.IO.FileMode]::Create,[System.IO.FileAccess]::ReadWrite,[System.IO.FileShare]::None); $fs.SetLength($sizeBytes); $fs.Close()
>> $buf=New-Object byte[] ($ProbeBlockKB*1024)
>> $fs=[System.IO.File]::OpenRead($probe); $sw=[System.Diagnostics.Stopwatch]::StartNew(); $read=0
>> while(($r=$fs.Read($buf,0,$buf.Length)) -gt 0){ $read+=$r }; $sw.Stop(); $fs.Close()
>> $seqMB=[math]::Round($read/1MB,2); $seqSec=[math]::Round($sw.Elapsed.TotalSeconds,4)
>> $seqMBps=if($seqSec -gt 0){[math]::Round($seqMB/$seqSec,2)}else{0}
>> $fs=[System.IO.File]::OpenRead($probe); $rnd=[System.Random]::new(); $rsw=[System.Diagnostics.Stopwatch]::StartNew()
>> for($i=0;$i -lt 256;$i++){ $pos=$rnd.NextInt64(0,[math]::Max(0,$sizeBytes-$buf.Length)); $fs.Seek($pos,[System.IO.SeekOrigin]::Begin)|Out-Null; $fs.Read($buf,0,$buf.Length)|Out-Null }
>> $rsw.Stop(); $fs.Close(); Remove-Item $probe -Force
>> $rndMB=[math]::Round((256*$ProbeBlockKB)/1024,2); $rndSec=[math]::Round($rsw.Elapsed.TotalSeconds,4)
>> $rndMBps=if($rndSec -gt 0){[math]::Round($rndMB/$rndSec,2)}else{0}; $latMs=[math]::Round(($rsw.Elapsed.TotalMilliseconds/256),3)
>> $tier= if($ram -le 1){"NANO_1GB"} elseif($ram -le 4){"MICRO_4GB"} elseif($ram -le 16){"STD_16GB"} else{"POWER_32GB_PLUS"}
>> $ws = switch($tier){"NANO_1GB"{256};"MICRO_4GB"{1024};"STD_16GB"{4096};default{8192}}
>> $pref = switch($tier){"NANO_1GB"{64};"MICRO_4GB"{128};"STD_16GB"{256};default{512}}
>> $par = switch($tier){"NANO_1GB"{2};"MICRO_4GB"{3};"STD_16GB"{4};default{6}}
>> $margin= if($latMs -le 0.08){2.0} elseif($latMs -le 0.5){1.5} else{1.3}
>> $p99=[math]::Round([math]::Max(0.3,$latMs*$margin),3)
>> $identity=[ordered]@{timestamp=(Get-Date).ToString("o");ramGB=$ram;cpu=$cpu;gpu=$gpu;probe=@{seqMBps=$seqMBps;rndMBps=$rndMBps;latMs=$latMs};tier=$tier}
>> $policy=[ordered]@{version="Δ-autoadapt-v1";tier=$tier;budgets=@{p99_read_ms=$p99;working_set_mb=$ws;prefetch_mb=$pref;max_parallel=$par;block_kb=$ProbeBlockKB};
>> modes=@{restore=@{chunk_mb=8;verify_end=$true};preload=@{seq_prefetch_mb=$pref;hot_rand_ops=512};stream=@{seq_ahead_mb=[math]::Min($pref*2,512);hot_offsets="hot_offsets.json"};
>> moe=@{enabled=$true;experts_total=32;experts_active_per_token= if($tier -eq "NANO_1GB"){2}else{3};quant= if($tier -eq "NANO_1GB"){"INT4"}else{"INT8"};tile_kb=$ProbeBlockKB};
>> scheduler=@{ram_ws_mb=$ws;vram_ws_mb=0;backpressure=@{iops=8000;lat_ms=$p99}}}}
>> $identityPath=Join-Path $Root "dna_identity.json"; $policyPath=Join-Path $Root "dna_policy_autoadapt.json"
>> ($identity|ConvertTo-Json -Depth 8)|Set-Content $identityPath -Encoding UTF8
>> ($policy|ConvertTo-Json -Depth 8)|Set-Content $policyPath -Encoding UTF8
>> Write-Host "[OK] identity -> $identityPath"; Write-Host "[OK] policy -> $policyPath"
>> '@
>>     Set-Content $auto -Value $autoBody -Encoding UTF8
>> }
PS C:\Users\felip>
PS C:\Users\felip> Write-Note "Gerando identidade e política Δ por host..."
[TEIA] Gerando identidade e política Δ por host...
PS C:\Users\felip> try {
>>     pwsh -NoProfile -File $auto -Root $Root | Out-Host
>> } catch {
>>     Write-Host "[Erro] Não foi possível gerar identidade e política: $_"
>> }

cmdlet Get-Content at command pipeline position 1
Supply values for the following parameters:
Path[0]:
PS C:\Users\felip>
PS C:\Users\felip> # Verificando a criação dos arquivos de identidade e política
PS C:\Users\felip> $identityPath = Join-Path $Root "dna_identity.json"
PS C:\Users\felip> $policyPath = Join-Path $Root "dna_policy_autoadapt.json"
PS C:\Users\felip>
PS C:\Users\felip> if (Test-Path $identityPath) {
>>     Write-Host "[TEIA] Arquivo de identidade encontrado: $identityPath"
>> } else {
>>     Write-Host "[TEIA] Arquivo de identidade NÃO encontrado: $identityPath"
>> }
[TEIA] Arquivo de identidade NÃO encontrado: C:\Users\felip\dna_identity.json
PS C:\Users\felip>
PS C:\Users\felip> if (Test-Path $policyPath) {
>>     Write-Host "[TEIA] Arquivo de política encontrado: $policyPath"
>> } else {
>>     Write-Host "[TEIA] Arquivo de política NÃO encontrado: $policyPath"
>> }
[TEIA] Arquivo de política NÃO encontrado: C:\Users\felip\dna_policy_autoadapt.json
PS C:\Users\felip>
PS C:\Users\felip> # 2) FS fractal - placeholder de montagem
PS C:\Users\felip> if ($FsMode -ne "none") {
>>     Write-Note "Montando FS fractal ($FsMode) - placeholder (integre WinFsp/ProjFS aqui)."
>> }
PS C:\Users\felip>
PS C:\Users\felip> # 3) Encadeamento dos seus scripts existentes com -Policy quando disponível
PS C:\Users\felip> function Try-Run($name,$args){
>>     $p = Join-Path $Root $name
>>     if (Test-Path $p) {
>>         $cmd = @("pwsh","-NoProfile","-File",$p) + $args
>>         Write-Note "→ $name $($args -join ' ')"
>>         & pwsh -NoProfile -File $p @args
>>     } else {
>>         Write-Note "(!) $name não encontrado - pulando."
>>     }
>> }
PS C:\Users\felip>
PS C:\Users\felip> $policyArgs = @()
PS C:\Users\felip> if ((Test-Path $policyPath)) {
>>     $policyArgs = @("-Policy",$policyPath)
>> }
PS C:\Users\felip>
PS C:\Users\felip> # Ordem curta: Restore → Preload → StreamPilot → Launch (todos tolerantes à ausência de -Policy)
PS C:\Users\felip> Try-Run "TEIA-Fractal-Restore-OnDemand.ps1" $policyArgs
[TEIA] (!) TEIA-Fractal-Restore-OnDemand.ps1 não encontrado - pulando.
PS C:\Users\felip> Try-Run "TEIA-Fractal-Preload.ps1"          $policyArgs
[TEIA] (!) TEIA-Fractal-Preload.ps1 não encontrado - pulando.
PS C:\Users\felip> Try-Run "TEIA-Fractal-StreamPilot.ps1"      @($policyArgs + @("-LaunchAfterWarmup"))
[TEIA] (!) TEIA-Fractal-StreamPilot.ps1 não encontrado - pulando.
PS C:\Users\felip> Try-Run "TEIA-Fractal-Launch.ps1"           $policyArgs
[TEIA] (!) TEIA-Fractal-Launch.ps1 não encontrado - pulando.
PS C:\Users\felip>
PS C:\Users\felip> Write-Note "Fluxo Δ-elástico concluído."
[TEIA] Fluxo Δ-elástico concluído.
PS C:\Users\felip> param(
>>   [string]$Root = ".",
>>   [string]$FsMode = "none"   # none|winfsp|projfs (placeholder para seu FS)
>> )
>>
>> $ErrorActionPreference = "Stop"
>> $Root = (Resolve-Path $Root).Path
>> Set-Location $Root
>>
>> function Write-Note($m){ Write-Host "[TEIA] $m" }
>>
>> # 1) AutoProfile → identidade + política Δ por host
>> $auto = Join-Path $Root "TEIA-Fractal-AutoProfile.ps1"
>> if (-not (Test-Path $auto)) {
>>     # Emite AutoProfile mínimo inline (caso ainda não exista)
>>     $autoBody = @'
>> param([string]$Root=".",[int]$ProbeBlockKB=256,[int]$ProbeRandOps=512)
>> $ErrorActionPreference="Stop"; $Root=(Resolve-Path $Root).Path; Set-Location $Root
>> function GR(){ [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,2) }
>> function GC(){ $w=Get-CimInstance Win32_Processor; [pscustomobject]@{Name=$w.Name;Cores=$w.NumberOfCores;Threads=$w.NumberOfLogicalProcessors;MaxClockGHz=[math]::Round($w.MaxClockSpeed/1000,2)} }
>> function GG(){ try{$g=Get-CimInstance Win32_VideoController|Select-Object -First 1;[pscustomobject]@{Name=$g.Name;VRAMGB=[math]::Round($g.AdapterRAM/1GB,2)}}catch{[pscustomobject]@{Name="Unknown";VRAMGB=0}} }
>> $ram=GR; $cpu=GC; $gpu=GG
>> $probe=Join-Path $Root "tmp_probe.bin"; $sizeMB=64; $sizeBytes=$sizeMB*1MB
>> $fs=[System.IO.File]::Open($probe,[System.IO.FileMode]::Create,[System.IO.FileAccess]::ReadWrite,[System.IO.FileShare]::None); $fs.SetLength($sizeBytes); $fs.Close()
>> $buf=New-Object byte[] ($ProbeBlockKB*1024)
>> $fs=[System.IO.File]::OpenRead($probe); $sw=[System.Diagnostics.Stopwatch]::StartNew(); $read=0
>> while(($r=$fs.Read($buf,0,$buf.Length)) -gt 0){ $read+=$r }; $sw.Stop(); $fs.Close()
>> $seqMB=[math]::Round($read/1MB,2); $seqSec=[math]::Round($sw.Elapsed.TotalSeconds,4)
>> $seqMBps=if($seqSec -gt 0){[math]::Round($seqMB/$seqSec,2)}else{0}
>> $fs=[System.IO.File]::OpenRead($probe); $rnd=[System.Random]::new(); $rsw=[System.Diagnostics.Stopwatch]::StartNew()
>> for($i=0;$i -lt 256;$i++){ $pos=$rnd.NextInt64(0,[math]::Max(0,$sizeBytes-$buf.Length)); $fs.Seek($pos,[System.IO.SeekOrigin]::Begin)|Out-Null; $fs.Read($buf,0,$buf.Length)|Out-Null }
>> $rsw.Stop(); $fs.Close(); Remove-Item $probe -Force
>> $rndMB=[math]::Round((256*$ProbeBlockKB)/1024,2); $rndSec=[math]::Round($rsw.Elapsed.TotalSeconds,4)
>> $rndMBps=if($rndSec -gt 0){[math]::Round($rndMB/$rndSec,2)}else{0}; $latMs=[math]::Round(($rsw.Elapsed.TotalMilliseconds/256),3)
>> $tier= if($ram -le 1){"NANO_1GB"} elseif($ram -le 4){"MICRO_4GB"} elseif($ram -le 16){"STD_16GB"} else{"POWER_32GB_PLUS"}
>> $ws = switch($tier){"NANO_1GB"{256};"MICRO_4GB"{1024};"STD_16GB"{4096};default{8192}}
>> $pref = switch($tier){"NANO_1GB"{64};"MICRO_4GB"{128};"STD_16GB"{256};default{512}}
>> $par = switch($tier){"NANO_1GB"{2};"MICRO_4GB"{3};"STD_16GB"{4};default{6}}
>> $margin= if($latMs -le 0.08){2.0} elseif($latMs -le 0.5){1.5} else{1.3}
>> $p99=[math]::Round([math]::Max(0.3,$latMs*$margin),3)
>> $identity=[ordered]@{timestamp=(Get-Date).ToString("o");ramGB=$ram;cpu=$cpu;gpu=$gpu;probe=@{seqMBps=$seqMBps;rndMBps=$rndMBps;latMs=$latMs};tier=$tier}
>> $policy=[ordered]@{version="Δ-autoadapt-v1";tier=$tier;budgets=@{p99_read_ms=$p99;working_set_mb=$ws;prefetch_mb=$pref;max_parallel=$par;block_kb=$ProbeBlockKB};
>> modes=@{restore=@{chunk_mb=8;verify_end=$true};preload=@{seq_prefetch_mb=$pref;hot_rand_ops=512};stream=@{seq_ahead_mb=[math]::Min($pref*2,512);hot_offsets="hot_offsets.json"};
>> moe=@{enabled=$true;experts_total=32;experts_active_per_token= if($tier -eq "NANO_1GB"){2}else{3};quant= if($tier -eq "NANO_1GB"){"INT4"}else{"INT8"};tile_kb=$ProbeBlockKB};
>> scheduler=@{ram_ws_mb=$ws;vram_ws_mb=0;backpressure=@{iops=8000;lat_ms=$p99}}}}
>> $identityPath=Join-Path $Root "dna_identity.json"; $policyPath=Join-Path $Root "dna_policy_autoadapt.json"
>> ($identity|ConvertTo-Json -Depth 8)|Set-Content $identityPath -Encoding UTF8
>> ($policy|ConvertTo-Json -Depth 8)|Set-Content $policyPath -Encoding UTF8
>> Write-Host "[OK] identity -> $identityPath"; Write-Host "[OK] policy -> $policyPath"
>> '@
>>     Set-Content $auto -Value $autoBody -Encoding UTF8
>> }
>>
>> Write-Note "Gerando identidade e política Δ por host..."
>> try {
>>     pwsh -NoProfile -File $auto -Root $Root | Out-Host
>> } catch {
>>     Write-Host "[Erro] Não foi possível gerar identidade e política: $_"
>> }
>>
>> # 2) FS fractal — placeholder de montagem
>> if ($FsMode -ne "none") {
>>     Write-Note "Montando FS fractal ($FsMode) — placeholder (integre WinFsp/ProjFS aqui)."
>> }
>>
>> # Verificar arquivos de identidade e política
>> $identityPath = Join-Path $Root "dna_identity.json"
>> $policyPath = Join-Path $Root "dna_policy_autoadapt.json"
>>
>> # Verificar existência dos arquivos antes de leitura
>> if (Test-Path $identityPath) {
>>     Write-Host "[TEIA] Arquivo de identidade encontrado: $identityPath"
>> } else {
>>     Write-Host "[TEIA] Arquivo de identidade NÃO encontrado: $identityPath"
>> }
>>
>> if (Test-Path $policyPath) {
>>     Write-Host "[TEIA] Arquivo de política encontrado: $policyPath"
>> } else {
>>     Write-Host "[TEIA] Arquivo de política NÃO encontrado: $policyPath"
>> }
>>
>> # 3) Encadeamento dos seus scripts existentes com -Policy quando disponível
>> function Try-Run($name,$args){
>>     $p = Join-Path $Root $name
>>     if (Test-Path $p) {
>>         $cmd = @("pwsh","-NoProfile","-File",$p) + $args
>>         Write-Note "→ $name $($args -join ' ')"
>>         & pwsh -NoProfile -File $p @args
>>     } else {
>>         Write-Note "(!) $name não encontrado — pulando."
>>     }
>> }
>>
>> $policyArgs = @()
>> if ((Test-Path $policyPath)) {
>>     $policyArgs = @("-Policy",$policyPath)
>> }
>>
>> # Ordem curta: Restore → Preload → StreamPilot → Launch (todos tolerantes à ausência de -Policy)
>> Try-Run "TEIA-Fractal-Restore-OnDemand.ps1" $policyArgs
>> Try-Run "TEIA-Fractal-Preload.ps1"          $policyArgs
>> Try-Run "TEIA-Fractal-StreamPilot.ps1"      @($policyArgs + @("-LaunchAfterWarmup"))
>> Try-Run "TEIA-Fractal-Launch.ps1"           $policyArgs
>>
>> Write-Note "Fluxo Δ-elástico concluído."
>>
[TEIA] Gerando identidade e política Δ por host...

cmdlet Get-Content at command pipeline position 1
Supply values for the following parameters:
Path[0]:
PS C:\Users\felip> param(
>>     [string]$Root = ".",
>>     [string]$FsMode = "none"   # none|winfsp|projfs (placeholder para seu FS)
>> )
>>
>> $ErrorActionPreference = "Stop"
>> $Root = (Resolve-Path $Root).Path
>> Set-Location $Root
>>
>> function Write-Note($m){ Write-Host "[TEIA] $m" }
>>
>> # 1) AutoProfile → identidade + política Δ por host
>> $auto = Join-Path $Root "TEIA-Fractal-AutoProfile.ps1"
>> if (-not (Test-Path $auto)) {
>>     # Emite AutoProfile mínimo inline (caso ainda não exista)
>>     $autoBody = @'
>> param([string]$Root=".",[int]$ProbeBlockKB=256,[int]$ProbeRandOps=512)
>> $ErrorActionPreference="Stop"; $Root=(Resolve-Path $Root).Path; Set-Location $Root
>> function GR(){ [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,2) }
>> function GC(){ $w=Get-CimInstance Win32_Processor; [pscustomobject]@{Name=$w.Name;Cores=$w.NumberOfCores;Threads=$w.NumberOfLogicalProcessors;MaxClockGHz=[math]::Round($w.MaxClockSpeed/1000,2)} }
>> function GG(){ try{$g=Get-CimInstance Win32_VideoController|Select-Object -First 1;[pscustomobject]@{Name=$g.Name;VRAMGB=[math]::Round($g.AdapterRAM/1GB,2)}}catch{[pscustomobject]@{Name="Unknown";VRAMGB=0}} }
>> $ram=GR; $cpu=GC; $gpu=GG
>> $probe=Join-Path $Root "tmp_probe.bin"; $sizeMB=64; $sizeBytes=$sizeMB*1MB
>> $fs=[System.IO.File]::Open($probe,[System.IO.FileMode]::Create,[System.IO.FileAccess]::ReadWrite,[System.IO.FileShare]::None); $fs.SetLength($sizeBytes); $fs.Close()
>> $buf=New-Object byte[] ($ProbeBlockKB*1024)
>> $fs=[System.IO.File]::OpenRead($probe); $sw=[System.Diagnostics.Stopwatch]::StartNew(); $read=0
>> while(($r=$fs.Read($buf,0,$buf.Length)) -gt 0){ $read+=$r }; $sw.Stop(); $fs.Close()
>> $seqMB=[math]::Round($read/1MB,2); $seqSec=[math]::Round($sw.Elapsed.TotalSeconds,4)
>> $seqMBps=if($seqSec -gt 0){[math]::Round($seqMB/$seqSec,2)}else{0}
>> $fs=[System.IO.File]::OpenRead($probe); $rnd=[System.Random]::new(); $rsw=[System.Diagnostics.Stopwatch]::StartNew()
>> for($i=0;$i -lt 256;$i++){ $pos=$rnd.NextInt64(0,[math]::Max(0,$sizeBytes-$buf.Length)); $fs.Seek($pos,[System.IO.SeekOrigin]::Begin)|Out-Null; $fs.Read($buf,0,$buf.Length)|Out-Null }
>> $rsw.Stop(); $fs.Close(); Remove-Item $probe -Force
>> $rndMB=[math]::Round((256*$ProbeBlockKB)/1024,2); $rndSec=[math]::Round($rsw.Elapsed.TotalSeconds,4)
>> $rndMBps=if($rndSec -gt 0){[math]::Round($rndMB/$rndSec,2)}else{0}; $latMs=[math]::Round(($rsw.Elapsed.TotalMilliseconds/256),3)
>> $tier= if($ram -le 1){"NANO_1GB"} elseif($ram -le 4){"MICRO_4GB"} elseif($ram -le 16){"STD_16GB"} else{"POWER_32GB_PLUS"}
>> $ws = switch($tier){"NANO_1GB"{256};"MICRO_4GB"{1024};"STD_16GB"{4096};default{8192}}
>> $pref = switch($tier){"NANO_1GB"{64};"MICRO_4GB"{128};"STD_16GB"{256};default{512}}
>> $par = switch($tier){"NANO_1GB"{2};"MICRO_4GB"{3};"STD_16GB"{4};default{6}}
>> $margin= if($latMs -le 0.08){2.0} elseif($latMs -le 0.5){1.5} else{1.3}
>> $p99=[math]::Round([math]::Max(0.3,$latMs*$margin),3)
>> $identity=[ordered]@{timestamp=(Get-Date).ToString("o");ramGB=$ram;cpu=$cpu;gpu=$gpu;probe=@{seqMBps=$seqMBps;rndMBps=$rndMBps;latMs=$latMs};tier=$tier}
>> $policy=[ordered]@{version="Δ-autoadapt-v1";tier=$tier;budgets=@{p99_read_ms=$p99;working_set_mb=$ws;prefetch_mb=$pref;max_parallel=$par;block_kb=$ProbeBlockKB};
>> modes=@{restore=@{chunk_mb=8;verify_end=$true};preload=@{seq_prefetch_mb=$pref;hot_rand_ops=512};stream=@{seq_ahead_mb=[math]::Min($pref*2,512);hot_offsets="hot_offsets.json"};
>> moe=@{enabled=$true;experts_total=32;experts_active_per_token= if($tier -eq "NANO_1GB"){2}else{3};quant= if($tier -eq "NANO_1GB"){"INT4"}else{"INT8"};tile_kb=$ProbeBlockKB};
>> scheduler=@{ram_ws_mb=$ws;vram_ws_mb=0;backpressure=@{iops=8000;lat_ms=$p99}}}}
>> $identityPath=Join-Path $Root "dna_identity.json"; $policyPath=Join-Path $Root "dna_policy_autoadapt.json"
>> ($identity|ConvertTo-Json -Depth 8)|Set-Content $identityPath -Encoding UTF8
>> ($policy|ConvertTo-Json -Depth 8)|Set-Content $policyPath -Encoding UTF8
>> Write-Host "[OK] identity -> $identityPath"; Write-Host "[OK] policy -> $policyPath"
>> '@
>>     Set-Content $auto -Value $autoBody -Encoding UTF8
>> }
>>
>> Write-Note "Gerando identidade e política Δ por host..."
>> try {
>>     pwsh -NoProfile -File $auto -Root $Root | Out-Host
>> } catch {
>>     Write-Host "[Erro] Não foi possível gerar identidade e política: $_"
>> }
>>
>> # Verificando se os arquivos de identidade e política foram gerados corretamente
>> $identityPath = Join-Path $Root "dna_identity.json"
>> $policyPath = Join-Path $Root "dna_policy_autoadapt.json"
>>
>> if (Test-Path $identityPath) {
>>     Write-Host "[TEIA] Arquivo de identidade encontrado: $identityPath"
>> } else {
>>     Write-Host "[TEIA] Arquivo de identidade NÃO encontrado: $identityPath"
>> }
>>
>> if (Test-Path $policyPath) {
>>     Write-Host "[TEIA] Arquivo de política encontrado: $policyPath"
>> } else {
>>     Write-Host "[TEIA] Arquivo de política NÃO encontrado: $policyPath"
>> }
>>
>> # FS fractal - placeholder de montagem
>> if ($FsMode -ne "none") {
>>     Write-Note "Montando FS fractal ($FsMode) - placeholder (integre WinFsp/ProjFS aqui)."
>> }
>>
>> # Encadeamento de scripts
>> function Try-Run($name, $args) {
>>     $p = Join-Path $Root $name
>>     if (Test-Path $p) {
>>         $cmd = @("pwsh", "-NoProfile", "-File", $p) + $args
>>         Write-Note "→ $name $($args -join ' ')"
>>         & pwsh -NoProfile -File $p @args
>>     } else {
>>         Write-Note "(!) $name não encontrado - pulando."
>>     }
>> }
>>
>> $policyArgs = @()
>> if ((Test-Path $policyPath)) {
>>     $policyArgs = @("-Policy", $policyPath)
>> }
>>
>> # Ordem curta: Restore → Preload → StreamPilot → Launch (todos tolerantes à ausência de -Policy)
>> Try-Run "TEIA-Fractal-Restore-OnDemand.ps1" $policyArgs
>> Try-Run "TEIA-Fractal-Preload.ps1" $policyArgs
>> Try-Run "TEIA-Fractal-StreamPilot.ps1" @($policyArgs + @("-LaunchAfterWarmup"))
>> Try-Run "TEIA-Fractal-Launch.ps1" $policyArgs
>>
>> Write-Note "Fluxo Δ-elástico concluído."
>>
[TEIA] Gerando identidade e política Δ por host...

cmdlet Get-Content at command pipeline position 1
Supply values for the following parameters:
Path[0]:
PS C:\Users\felip> param(
>>   [string]$Root = ".",
>>   [string]$FsMode = "none"   # none|winfsp|projfs (placeholder para seu FS)
>> )
>>
>> $ErrorActionPreference = "Stop"
>> $Root = (Resolve-Path $Root).Path
>> Set-Location $Root
>>
>> function Write-Note($m){ Write-Host "[TEIA] $m" }
>>
>> # 1) AutoProfile → identidade + política Δ por host
>> $auto = Join-Path $Root "TEIA-Fractal-AutoProfile.ps1"
>> if (-not (Test-Path $auto)) {
>>     # Emite AutoProfile mínimo inline (caso ainda não exista)
>>     $autoBody = @'
>> param([string]$Root=".",[int]$ProbeBlockKB=256,[int]$ProbeRandOps=512)
>> $ErrorActionPreference="Stop"; $Root=(Resolve-Path $Root).Path; Set-Location $Root
>> function GR(){ [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,2) }
>> function GC(){ $w=Get-CimInstance Win32_Processor; [pscustomobject]@{Name=$w.Name;Cores=$w.NumberOfCores;Threads=$w.NumberOfLogicalProcessors;MaxClockGHz=[math]::Round($w.MaxClockSpeed/1000,2)} }
>> function GG(){ try{$g=Get-CimInstance Win32_VideoController|Select-Object -First 1;[pscustomobject]@{Name=$g.Name;VRAMGB=[math]::Round($g.AdapterRAM/1GB,2)}}catch{[pscustomobject]@{Name="Unknown";VRAMGB=0}} }
>> $ram=GR; $cpu=GC; $gpu=GG
>> $probe=Join-Path $Root "tmp_probe.bin"; $sizeMB=64; $sizeBytes=$sizeMB*1MB
>> $fs=[System.IO.File]::Open($probe,[System.IO.FileMode]::Create,[System.IO.FileAccess]::ReadWrite,[System.IO.FileShare]::None); $fs.SetLength($sizeBytes); $fs.Close()
>> $buf=New-Object byte[] ($ProbeBlockKB*1024)
>> $fs=[System.IO.File]::OpenRead($probe); $sw=[System.Diagnostics.Stopwatch]::StartNew(); $read=0
>> while(($r=$fs.Read($buf,0,$buf.Length)) -gt 0){ $read+=$r }; $sw.Stop(); $fs.Close()
>> $seqMB=[math]::Round($read/1MB,2); $seqSec=[math]::Round($sw.Elapsed.TotalSeconds,4)
>> $seqMBps=if($seqSec -gt 0){[math]::Round($seqMB/$seqSec,2)}else{0}
>> $fs=[System.IO.File]::OpenRead($probe); $rnd=[System.Random]::new(); $rsw=[System.Diagnostics.Stopwatch]::StartNew()
>> for($i=0;$i -lt 256;$i++){ $pos=$rnd.NextInt64(0,[math]::Max(0,$sizeBytes-$buf.Length)); $fs.Seek($pos,[System.IO.SeekOrigin]::Begin)|Out-Null; $fs.Read($buf,0,$buf.Length)|Out-Null }
>> $rsw.Stop(); $fs.Close(); Remove-Item $probe -Force
>> $rndMB=[math]::Round((256*$ProbeBlockKB)/1024,2); $rndSec=[math]::Round($rsw.Elapsed.TotalSeconds,4)
>> $rndMBps=if($rndSec -gt 0){[math]::Round($rndMB/$rndSec,2)}else{0}; $latMs=[math]::Round(($rsw.Elapsed.TotalMilliseconds/256),3)
>> $tier= if($ram -le 1){"NANO_1GB"} elseif($ram -le 4){"MICRO_4GB"} elseif($ram -le 16){"STD_16GB"} else{"POWER_32GB_PLUS"}
>> $ws = switch($tier){"NANO_1GB"{256};"MICRO_4GB"{1024};"STD_16GB"{4096};default{8192}}
>> $pref = switch($tier){"NANO_1GB"{64};"MICRO_4GB"{128};"STD_16GB"{256};default{512}}
>> $par = switch($tier){"NANO_1GB"{2};"MICRO_4GB"{3};"STD_16GB"{4};default{6}}
>> $margin= if($latMs -le 0.08){2.0} elseif($latMs -le 0.5){1.5} else{1.3}
>> $p99=[math]::Round([math]::Max(0.3,$latMs*$margin),3)
>> $identity=[ordered]@{timestamp=(Get-Date).ToString("o");ramGB=$ram;cpu=$cpu;gpu=$gpu;probe=@{seqMBps=$seqMBps;rndMBps=$rndMBps;latMs=$latMs};tier=$tier}
>> $policy=[ordered]@{version="Δ-autoadapt-v1";tier=$tier;budgets=@{p99_read_ms=$p99;working_set_mb=$ws;prefetch_mb=$pref;max_parallel=$par;block_kb=$ProbeBlockKB};
>> modes=@{restore=@{chunk_mb=8;verify_end=$true};preload=@{seq_prefetch_mb=$pref;hot_rand_ops=512};stream=@{seq_ahead_mb=[math]::Min($pref*2,512);hot_offsets="hot_offsets.json"};
>> moe=@{enabled=$true;experts_total=32;experts_active_per_token= if($tier -eq "NANO_1GB"){2}else{3};quant= if($tier -eq "NANO_1GB"){"INT4"}else{"INT8"};tile_kb=$ProbeBlockKB};
>> scheduler=@{ram_ws_mb=$ws;vram_ws_mb=0;backpressure=@{iops=8000;lat_ms=$p99}}}}
>> $identityPath=Join-Path $Root "dna_identity.json"; $policyPath=Join-Path $Root "dna_policy_autoadapt.json"
>> ($identity|ConvertTo-Json -Depth 8)|Set-Content $identityPath -Encoding UTF8
>> ($policy|ConvertTo-Json -Depth 8)|Set-Content $policyPath -Encoding UTF8
>> Write-Host "[OK] identity -> $identityPath"; Write-Host "[OK] policy -> $policyPath"
>> '@
>>     Set-Content $auto -Value $autoBody -Encoding UTF8
>> }
>>
>> Write-Note "Gerando identidade e política Δ por host..."
>> try {
>>     pwsh -NoProfile -File $auto -Root $Root | Out-Host
>> } catch {
>>     Write-Host "[Erro] Não foi possível gerar identidade e política: $_"
>> }
>>
>> # Verificação de existência de arquivos antes de tentar ler
>> $identityPath = Join-Path $Root "dna_identity.json"
>> $policyPath = Join-Path $Root "dna_policy_autoadapt.json"
>>
>> # Verificando se os arquivos existem antes de ler
>> if (Test-Path $identityPath) {
>>     Write-Host "[TEIA] Arquivo de identidade encontrado: $identityPath"
>>     try {
>>         $identityContent = Get-Content $identityPath -ErrorAction Stop
>>     } catch {
>>         Write-Host "[Erro] Não foi possível ler o arquivo de identidade: $_"
>>     }
>> } else {
>>     Write-Host "[TEIA] Arquivo de identidade NÃO encontrado: $identityPath"
>> }
>>
>> if (Test-Path $policyPath) {
>>     Write-Host "[TEIA] Arquivo de política encontrado: $policyPath"
>>     try {
>>         $policyContent = Get-Content $policyPath -ErrorAction Stop
>>     } catch {
>>         Write-Host "[Erro] Não foi possível ler o arquivo de política: $_"
>>     }
>> } else {
>>     Write-Host "[TEIA] Arquivo de política NÃO encontrado: $policyPath"
>> }
>>
>> # FS fractal - placeholder de montagem
>> if ($FsMode -ne "none") {
>>     Write-Note "Montando FS fractal ($FsMode) - placeholder (integre WinFsp/ProjFS aqui)."
>> }
>>
>> # Encadeamento de scripts
>> function Try-Run($name, $args) {
>>     $p = Join-Path $Root $name
>>     if (Test-Path $p) {
>>         $cmd = @("pwsh", "-NoProfile", "-File", $p) + $args
>>         Write-Note "→ $name $($args -join ' ')"
>>         & pwsh -NoProfile -File $p @args
>>     } else {
>>         Write-Note "(!) $name não encontrado - pulando."
>>     }
>> }
>>
>> $policyArgs = @()
>> if ((Test-Path $policyPath)) {
>>     $policyArgs = @("-Policy", $policyPath)
>> }
>>
>> # Ordem curta: Restore → Preload → StreamPilot → Launch (todos tolerantes à ausência de -Policy)
>> Try-Run "TEIA-Fractal-Restore-OnDemand.ps1" $policyArgs
>> Try-Run "TEIA-Fractal-Preload.ps1" $policyArgs
>> Try-Run "TEIA-Fractal-StreamPilot.ps1" @($policyArgs + @("-LaunchAfterWarmup"))
>> Try-Run "TEIA-Fractal-Launch.ps1" $policyArgs
>>
>> Write-Note "Fluxo Δ-elástico concluído."
>>
[TEIA] Gerando identidade e política Δ por host...

cmdlet Get-Content at command pipeline position 1
Supply values for the following parameters:
Path[0]:
O que estou errando e não estou vendo

---

### ASSISTENTE

Parece que o erro ocorre porque o script está tentando ler arquivos (por exemplo, `dna_identity.json` e `dna_policy_autoadapt.json`) que não foram gerados corretamente, ou o caminho para os arquivos está errado. O erro mais provável é que a execução do script `TEIA-Fractal-AutoProfile.ps1` não tenha sido bem-sucedida, fazendo com que os arquivos de identidade e política não sejam gerados.

Aqui estão alguns pontos para verificar e corrigir:

1. **Caminho de arquivo não encontrado**: Certifique-se de que os caminhos dos arquivos de saída estão corretos. O script está tentando acessar arquivos em um caminho absoluto, mas pode não estar gerando esses arquivos devido a permissões ou configurações erradas de caminho.

   Verifique se o caminho de `$Root` está correto e se você tem permissões para gravar nesse diretório.

2. **Execução do script `TEIA-Fractal-AutoProfile.ps1`**: O erro relacionado ao `Get-Content` sugere que o script `TEIA-Fractal-AutoProfile.ps1` não foi executado corretamente, ou não gerou os arquivos `dna_identity.json` e `dna_policy_autoadapt.json`.

   - A mensagem de erro relacionada ao `Get-Content` indica que o PowerShell não está encontrando o arquivo para ler, o que significa que o script que deveria criá-los não funcionou como esperado.

3. **Falha na criação do arquivo de identidade e política**: O código no `TEIA-Fractal-AutoProfile.ps1` está sendo executado, mas não está criando os arquivos de identidade e política. Verifique se o bloco que cria esses arquivos está funcionando corretamente e se não há erros em tempo de execução durante a criação desses arquivos.

   - Teste manualmente o script `TEIA-Fractal-AutoProfile.ps1` para ver se ele gera os arquivos esperados, verificando se há algum erro ou se ele está sendo interrompido antes de terminar a execução.

4. **Comando `Get-Content` não reconhecendo parâmetros**: O erro relacionado ao `cmdlet Get-Content at command pipeline position 1` sugere que o caminho do arquivo não está sendo passado corretamente para o `Get-Content`. Isso pode ocorrer devido ao uso do `param` no início do script.

   - Certifique-se de que os parâmetros do script estão sendo passados corretamente e de que não há conflito entre os parâmetros definidos no script e os arquivos de entrada.

Aqui está uma maneira de depurar:

1. **Verifique o caminho de `$Root`**:
   ```powershell
   Write-Host "Root Path: $Root"
   ```

2. **Verifique se o arquivo foi realmente criado**:
   Adicione um bloco de verificação logo após a execução do script `TEIA-Fractal-AutoProfile.ps1` para garantir que os arquivos foram criados:
   ```powershell
   if (Test-Path $identityPath) {
       Write-Host "Arquivo de identidade encontrado: $identityPath"
   } else {
       Write-Host "Arquivo de identidade NÃO encontrado: $identityPath"
   }

   if (Test-Path $policyPath) {
       Write-Host "Arquivo de política encontrado: $policyPath"
   } else {
       Write-Host "Arquivo de política NÃO encontrado: $policyPath"
   }
   ```

3. **Verifique a execução do script de perfil**:
   Certifique-se de que o script `TEIA-Fractal-AutoProfile.ps1` tenha sido executado com sucesso:
   ```powershell
   try {
       pwsh -NoProfile -File $auto -Root $Root
   } catch {
       Write-Host "Erro ao executar TEIA-Fractal-AutoProfile.ps1: $_"
   }
   ```

Ao seguir esses passos e depurar o caminho de execução, você poderá identificar onde está o problema e corrigi-lo.

---

