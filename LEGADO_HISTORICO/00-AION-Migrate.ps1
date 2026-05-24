$ErrorActionPreference='Stop'

# Branding and config
$BRAND = 'AION-RISPA-NDC'
$PROTO = 'aion'
$PORT  = 8123
$BIN   = Join-Path $env:LOCALAPPDATA 'AION\bin'
$LOGS  = Join-Path $env:LOCALAPPDATA 'AION\logs'
$QUEUE = Join-Path $env:TEMP 'aion_restore_queue.jsonl'

if (-not $env:AION_HTTP_TOKEN -or [string]::IsNullOrWhiteSpace($env:AION_HTTP_TOKEN)) {
  $env:AION_HTTP_TOKEN = [Guid]::NewGuid().ToString('N')
}
$TOKEN = $env:AION_HTTP_TOKEN

New-Item -ItemType Directory -Force -Path $BIN,$LOGS | Out-Null
if(-not (Test-Path -LiteralPath $QUEUE)){ New-Item -ItemType File -Force -Path $QUEUE | Out-Null }

# Remove old TEIA tasks
foreach($t in @('TEIA Local HTTP','TEIA Restore Watcher')){
  try{ Stop-ScheduledTask -TaskName $t -ErrorAction SilentlyContinue }catch{}
  try{ Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction SilentlyContinue }catch{}
}

# Persist AION env vars
try { & cmd /c setx AION_BIN   "$BIN"   | Out-Null } catch {}
try { & cmd /c setx AION_LOGS  "$LOGS"  | Out-Null } catch {}
try { & cmd /c setx AION_QUEUE "$QUEUE" | Out-Null } catch {}
try { & cmd /c setx AION_HTTP_TOKEN "$TOKEN" | Out-Null } catch {}
$env:AION_BIN=$BIN; $env:AION_LOGS=$LOGS; $env:AION_QUEUE=$QUEUE

# HTTP v2 server with token
$http = @'
$ErrorActionPreference='Stop'

function Set-Cors($ctx){
  $ctx.Response.Headers['Access-Control-Allow-Origin']  = '*'
  $ctx.Response.Headers['Access-Control-Allow-Methods'] = 'GET,POST,OPTIONS'
  $ctx.Response.Headers['Access-Control-Allow-Headers'] = 'Content-Type,X-AION-TOKEN'
}
function SendJson($ctx, $obj, [int]$code=200){
  $json = ($obj | ConvertTo-Json -Depth 6)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  $ctx.Response.StatusCode = $code
  $ctx.Response.ContentType = 'application/json; charset=utf-8'
  Set-Cors $ctx
  $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
  $ctx.Response.Close()
}
function TailLog([string]$path,[int]$lines){ if (!(Test-Path $path)) { return @('<no-log>') }; Get-Content -LiteralPath $path -Tail $lines }
function Parse-Query([string]$query){ $r=@{}; if([string]::IsNullOrEmpty($query)){return $r}; $q=$query.TrimStart('?'); foreach($pair in $q -split '&'){ if([string]::IsNullOrWhiteSpace($pair)){continue}; $kv=$pair -split '=',2; $k=[Uri]::UnescapeDataString($kv[0]); $v= if($kv.Count -gt 1){ [Uri]::UnescapeDataString($kv[1]) } else { '' }; $r[$k]=$v }; return $r }

$logs   = if ($env:AION_LOGS) { $env:AION_LOGS } else { Join-Path $env:LOCALAPPDATA 'AION\logs' }
$wlog   = Join-Path $logs 'restore_watcher.log'
$queue  = if ($env:AION_QUEUE){ $env:AION_QUEUE } else { Join-Path $env:TEMP 'aion_restore_queue.jsonl' }
if (!(Test-Path $queue)) { New-Item -ItemType File -Force -Path $queue | Out-Null }
$token  = $env:AION_HTTP_TOKEN

$prefix = 'http://127.0.0.1:8123/'
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($prefix)
try { $listener.Start() } catch { throw }

while ($listener.IsListening) {
  $ctx = $null
  try {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    if ($req.HttpMethod -eq 'OPTIONS') { $ctx.Response.StatusCode=204; Set-Cors $ctx; $ctx.Response.Close(); continue }
    if ($req.HttpMethod -eq 'GET' -and ($req.RawUrl -eq '/' -or $req.RawUrl -like '/index*')) { SendJson $ctx @{ brand='AION-RISPA-NDC'; endpoints=@('/health','/metrics','/log/tail?lines=200','/enqueue (POST)') }; continue }
    if ($req.HttpMethod -eq 'GET' -and $req.RawUrl -like '/health*')   { $st=(Get-ScheduledTask -TaskName 'AION-RISPA-NDC Restore Watcher' -ErrorAction SilentlyContinue).State; SendJson $ctx @{ watcher_state=$st }; continue }
    if ($req.HttpMethod -eq 'GET' -and $req.RawUrl -like '/metrics*')  { $ls=TailLog $wlog 1000; SendJson $ctx @{ ok=($ls|Where-Object{ $_ -like '*[OK]*'}).Count; err=($ls|Where-Object{ $_ -like '*[ERR]*'}).Count }; continue }
    if ($req.HttpMethod -eq 'GET' -and $req.RawUrl -like '/log/tail*') { $qs=Parse-Query $req.Url.Query; $n=200; if($qs.ContainsKey('lines')){ [void][int]::TryParse($qs['lines'],[ref]$n) }; SendJson $ctx @{ lines=(TailLog $wlog $n) }; continue }
    if ($req.HttpMethod -eq 'POST' -and $req.RawUrl -like '/enqueue*') {
      if ($token -and $req.Headers['X-AION-TOKEN'] -ne $token) { SendJson $ctx @{ error='unauthorized' } 401; continue }
      $reader = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8)
      $body = $reader.ReadToEnd(); $reader.Dispose()
      try { $null = $body | ConvertFrom-Json -ErrorAction Stop } catch { SendJson $ctx @{ error='invalid_json' } 400; continue }
      Add-Content -LiteralPath $queue -Value ($body + "`n") -Encoding UTF8
      SendJson $ctx @{ queued=$true; len=(Get-Item $queue).Length }
      continue
    }
    SendJson $ctx @{ error='not_found' } 404
  } catch {
    try { SendJson $ctx @{ error=$_.Exception.Message } 500 } catch {}
  }
}
'@

$httpFile = Join-Path $BIN 'AION-Local-Http.ps1'
$http | Out-File -FilePath $httpFile -Encoding UTF8 -Force

# AION adapter (demo) and shims
$adapter = @'
param(
  [Parameter(Mandatory=$true)][ValidateSet(''restore-index'',''restore-scan'')] [string]$Command,
  [string]$seed,
  [string]$index,
  [string]$root,
  [string]$out,
  [int]$maxscan = 1000000
)
$ErrorActionPreference=''Stop''
function Info($m){ Write-Host "[AION-ADAPTER] $m" }

$real = $env:AION_REAL_CLI
if ($real -and (Test-Path $real)) {
  Info "Delegando para CLI real: $real"
  & $real $Command -seed $seed -index $index -root $root -out $out -maxscan $maxscan
  exit $LASTEXITCODE
}

if (-not (Test-Path $seed)) { throw "Seed não encontrada: $seed" }
$seedObj = Get-Content -LiteralPath $seed -Raw | ConvertFrom-Json
if (-not $seedObj.source_path) { throw "Seed sem 'source_path' (modo demo requer)." }
if (-not (Test-Path $seedObj.source_path)) { throw "source_path inválido: $($seedObj.source_path)" }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $out) | Out-Null
Copy-Item -LiteralPath $seedObj.source_path -Destination $out -Force
Info "Restaurado (demo) para: $out"
'@
$adapterPath = Join-Path $BIN 'AION-Restore-Adapter.ps1'
$adapter | Out-File -FilePath $adapterPath -Encoding UTF8 -Force
$cmdPath = Join-Path $BIN 'aion.cmd'
$cmdContent = (@(
  '@echo off'
  'powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""%~dp0AION-Restore-Adapter.ps1"" %*'
) -join "`r`n") + "`r`n"
$cmdContent | Out-File -FilePath $cmdPath -Encoding ASCII -Force

# AION watcher (uses aion.cmd)
$watcher = @"
$ErrorActionPreference='Stop'
param(
  [string]$Queue,
  [string]$Log
)
$Queue = if ($Queue) { $Queue } else { if ($env:AION_QUEUE){ $env:AION_QUEUE } else { Join-Path $env:TEMP 'aion_restore_queue.jsonl' } }
$Log   = if ($Log)   { $Log }   else { if ($env:AION_LOGS){ Join-Path $env:AION_LOGS 'restore_watcher.log' } else { Join-Path (Join-Path $env:LOCALAPPDATA 'AION\logs') 'restore_watcher.log' } }
New-Item -ItemType File -Force -Path $Queue | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Log) | Out-Null
$seen = New-Object System.Collections.Generic.HashSet[string]
function Write-Log($m){ ("$((Get-Date).ToString('s')) `t $m") | Add-Content -LiteralPath $Log -Encoding UTF8 }
Write-Log "[INIT] Watcher ON. Queue=$Queue"
$BinDir  = Split-Path -Parent $PSCommandPath
$AionCmd = Join-Path $BinDir 'aion.cmd'
while ($true) {
  try {
    $content = (Get-Content -LiteralPath $Queue -Raw -ErrorAction SilentlyContinue)
    foreach($ln in ($content -split "`n")) {
      if([string]::IsNullOrWhiteSpace($ln)){ continue }
      if(-not $seen.Add($ln)){ continue }
      $job = $ln | ConvertFrom-Json
      $mode = [string]$job.mode
      $seed = [string]$job.seed
      $out  = [string]$job.out
      $index= [string]$job.index
      $root = [string]$job.root
      $maxscan = 1000000; if ($job.PSObject.Properties.Name -contains ''maxscan'' -and $null -ne $job.maxscan -and [int]$job.maxscan -gt 0) { $maxscan = [int]$job.maxscan }
      Write-Log "[JOB] mode=$mode seed=$seed out=$out index=$index root=$root maxscan=$maxscan"
      if([string]::IsNullOrWhiteSpace($seed) -or [string]::IsNullOrWhiteSpace($out) -or (($mode -eq 'index') -and [string]::IsNullOrWhiteSpace($index))) {
        Write-Log "[ERR] Job inválido (campos obrigatórios vazios): $ln"
        try { $all = Get-Content -LiteralPath $Queue; $filtered = $all | Where-Object { $_ -ne $ln }; Set-Content -LiteralPath $Queue -Value $filtered } catch { Write-Log "[WARN] Falha ao limpar linha inválida da fila: $($_.Exception.Message)" }
        continue
      }
      if($mode -eq 'index'){
        & $AionCmd restore-index -seed $seed -index $index -out $out
      } else {
        & $AionCmd restore-scan  -seed $seed -root  $root  -out $out -maxscan $maxscan
      }
      try {
        $shaSeed = (Get-Content -LiteralPath $seed -Raw | ConvertFrom-Json).sha256.ToLower()
        $shaOut  = (Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash.ToLower()
        if($shaSeed -ne $shaOut){ throw "SHA mismatch: expected=$shaSeed got=$shaOut file=$out" }
        Write-Log "[OK] $mode out=$out sha=$shaOut"
      } catch { Write-Log "[ERR] $($_.Exception.Message)" }
    }
    Clear-Content -LiteralPath $Queue -ErrorAction SilentlyContinue
  } catch { Write-Log "[ERR] $($_.Exception.Message)" }
  Start-Sleep -Milliseconds 400
}
"@
$watcherFile = Join-Path $BIN 'AION-Restore-Watcher.ps1'
$watcher | Out-File -FilePath $watcherFile -Encoding UTF8 -Force

# Protocol aion:
$enqueuePs1 = Join-Path $BIN 'AION-Enqueue-Job.ps1'
@"
param([Parameter(Mandatory=$true)][string]$EncodedJson)
$ErrorActionPreference='Stop'
$queue = if ($env:AION_QUEUE){ $env:AION_QUEUE } else { Join-Path $env:TEMP 'aion_restore_queue.jsonl' }
$json  = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedJson))
try {
  $obj = $json | ConvertFrom-Json -ErrorAction Stop
  if ($obj.action -and [string]::Equals($obj.action,'openlog',[System.StringComparison]::OrdinalIgnoreCase)) {
    $log = if ($env:AION_LOGS){ Join-Path $env:AION_LOGS 'restore_watcher.log' } else { Join-Path (Join-Path $env:LOCALAPPDATA 'AION\logs') 'restore_watcher.log' }
    if (Test-Path $log) { Start-Process notepad.exe $log } else { Write-Warning "Log inexistente: $log" }
  } else {
    Add-Content -LiteralPath $queue -Value ($json + "`n") -Encoding UTF8
    Write-Host "[ENQUEUE] $json"
  }
} catch {
  Add-Content -LiteralPath $queue -Value ($json + "`n") -Encoding UTF8
  Write-Host "[ENQUEUE] $json"
}
"@ | Out-File -FilePath $enqueuePs1 -Encoding UTF8 -Force

$regBase = "HKCU:\Software\Classes\$PROTO"
New-Item -Path $regBase -Force | Out-Null
Set-ItemProperty -Path $regBase -Name '(Default)' -Value "URL:$PROTO Protocol" -Force
Set-ItemProperty -Path $regBase -Name 'URL Protocol' -Value '' -Force
New-Item -Path "$regBase\shell\open\command" -Force | Out-Null
$cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$enqueuePs1`" -EncodedJson `"%1`""
Set-ItemProperty -Path "$regBase\shell\open\command" -Name '(Default)' -Value $cmd -Force

# Install tasks
$principal= New-ScheduledTaskPrincipal -UserId "$env:UserName" -LogonType Interactive -RunLevel Highest
$trigger  = New-ScheduledTaskTrigger -AtLogOn

# URLACLs (best effort)
try { & netsh http add urlacl url=http://127.0.0.1:$PORT/ user=$env:UserName 2>$null | Out-Null } catch {}
try { & netsh http add urlacl url=http://localhost:$PORT/ user=$env:UserName 2>$null | Out-Null } catch {}

$taskHttp  = "$BRAND Local HTTP"
if (Get-ScheduledTask -TaskName $taskHttp -ErrorAction SilentlyContinue) { Unregister-ScheduledTask -TaskName $taskHttp -Confirm:$false }
$actHttp   = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$httpFile`""
Register-ScheduledTask -TaskName $taskHttp -Action $actHttp -Trigger $trigger -Principal $principal | Out-Null
Start-ScheduledTask -TaskName $taskHttp

$taskWatch = "$BRAND Restore Watcher"
if (Get-ScheduledTask -TaskName $taskWatch -ErrorAction SilentlyContinue) { Unregister-ScheduledTask -TaskName $taskWatch -Confirm:$false }
$actWatch  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$watcherFile`""
Register-ScheduledTask -TaskName $taskWatch -Action $actWatch -Trigger $trigger -Principal $principal | Out-Null
Start-ScheduledTask -TaskName $taskWatch

Write-Host " $BRAND instalado."
Write-Host " HTTP:  http://127.0.0.1:$PORT/"
Write-Host " Logs:  $LOGS"
Write-Host " Queue: $QUEUE"
Write-Host " Token: $TOKEN (use X-AION-TOKEN)"
