param(
  [string]$Root = 'D:\Teia\TEIA_NUCLEO\offline\nano'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

function Ensure-Dir{ param([string]$P) if(-not (Test-Path $P)){ New-Item -ItemType Directory -Path $P | Out-Null } }

$RefDir    = Join-Path $Root 'referential'
$ScriptsDir = Join-Path $RefDir 'scripts'
$DictPath  = Join-Path $RefDir 'teia_dict_fractal.jsonl'

Ensure-Dir $RefDir
Ensure-Dir $ScriptsDir

Write-Output ("TEIA referential initialized. Scripts in {0} and dict path {1}" -f $ScriptsDir, $DictPath)
