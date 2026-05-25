# ===================== TEIA — InvokePwshFile (subprocesso limpo) =====================
param(
  [Parameter(Mandatory=$true)][string]$Script,
  [string[]]$Args = @(),
  [switch]$Bypass
)
$ErrorActionPreference="Stop"; [Console]::OutputEncoding=[Text.Encoding]::UTF8

$pwsh = (Get-Command pwsh).Source
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $pwsh

$argv = @()
if($Bypass){ $argv += @('-NoProfile','-ExecutionPolicy','Bypass') } else { $argv += @('-NoProfile') }
$argv += @('-File', ('"'+($Script -replace '"','\"')+'"'))
$argv += ($Args | ForEach-Object { '"' + ($_ -replace '"','\"') + '"' })

$psi.Arguments = [string]::Join(' ',$argv)
$psi.WorkingDirectory = (Get-Location).Path
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.CreateNoWindow = $true

$p = New-Object System.Diagnostics.Process; $p.StartInfo=$psi
[void]$p.Start()
$out=$p.StandardOutput.ReadToEnd()
$err=$p.StandardError.ReadToEnd()
$p.WaitForExit()

if($out){ Write-Host $out }
if($p.ExitCode -ne 0){ if($err){ Write-Error $err }; exit $p.ExitCode }