param(
  [Parameter(Mandatory=$true)] [string]$InputPath,
  [string]$Root = "$PSScriptRoot/..",
  [int]$AnchorKB = 64,
  [int]$BufferKB = 1024,
  [switch]$DeleteOriginal,
  [string]$LogPath = "$PSScriptRoot/../logs/dna_universal.log",
  [string]$VerificationPath = "$PSScriptRoot/../logs/verification_universal.json"
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Resolve script dir de forma robusta
$ScriptDir = if($PSCommandPath){ Split-Path -Parent $PSCommandPath } elseif($MyInvocation.MyCommand.Path){ Split-Path -Parent $MyInvocation.MyCommand.Path } elseif($PSScriptRoot){ $PSScriptRoot } else { (Resolve-Path ".").Path }

# Logger (com fallback)
$loggerPath = Join-Path $ScriptDir 'TEIA-Logger.ps1'
function Get-TEIAUtcNow { (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") }
if(Test-Path $loggerPath){ . $loggerPath -LogPath $LogPath -VerificationPath $VerificationPath } else {
  function Write-TEIALog { param([string]$Message,[string]$Level='INFO')
    $dir = Split-Path -Parent $LogPath; if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Add-Content -LiteralPath $LogPath -Encoding UTF8 -Value ("[{0}] {1} {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message)
  }
  function Update-Verification { param([hashtable]$Entry)
    $dir = Split-Path -Parent $VerificationPath; if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Add-Content -LiteralPath $VerificationPath -Encoding UTF8 -Value ($Entry | ConvertTo-Json -Depth 64)
  }
}

try {
  $in = (Resolve-Path $InputPath).Path
  if(-not (Test-Path $in)) { throw "Arquivo nao encontrado: $in" }
  $fi = Get-Item -LiteralPath $in
  $root = (Resolve-Path $Root).Path

  # >>> destino correto (dentro de universal_core): data\seeds
  $outDir = Join-Path $root 'data\seeds'
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null

  # hash por streaming
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $buf = New-Object byte[] ($BufferKB * 1024)
  $fsH = [System.IO.File]::Open($in, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
  try {
    while(($read = $fsH.Read($buf,0,$buf.Length)) -gt 0){ $null = $sha.TransformBlock($buf,0,$read,$buf,0) }
    $sha.TransformFinalBlock(@(),0,0) | Out-Null
  } finally { $fsH.Dispose() }
  $hash = -join ($sha.Hash | ForEach-Object { $_.ToString('x2') })
  $outPath = Join-Path $outDir (".fractal_delta.$hash.json")

  # idempotência
  if(Test-Path $outPath){
    Write-TEIALog -Message "Seed Low-RAM já existe (skip): $outPath" -Level 'INFO'
    Update-Verification -Entry @{ kind='seed-lowram-skip'; input=$in; seed=$outPath; sha256=$hash; time=Get-TEIAUtcNow; ok=$true }
    Write-Host "[SKIP] Seed já existente: $outPath"
    return
  }

  # ancora (só primeiros KB)
  $anchorBytes = New-Object byte[] ([Math]::Min($fi.Length, [int64]$AnchorKB * 1024))
  $fs1 = [System.IO.File]::Open($in,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::Read)
  try { [void]$fs1.Read($anchorBytes,0,$anchorBytes.Length) } finally { $fs1.Dispose() }
  $fragmentB64 = [Convert]::ToBase64String($anchorBytes)

  $manifest = [ordered]@{
    fn       = 'fractal_delta_restore_v2'
    file     = $fi.Name
    hash     = $hash
    size     = [int64]$fi.Length
    created  = Get-TEIAUtcNow
    seed     = (Get-Random)
    version  = 'Delta2.0'
    fragment = $fragmentB64
    fragSize = $anchorBytes.Length
  }

  $manifest | ConvertTo-Json -Depth 64 | Set-Content -LiteralPath $outPath -Encoding UTF8
  Write-TEIALog -Message "Seed Low-RAM gerada: '$in' -> '$outPath' (size=$($fi.Length), anchor=$($anchorBytes.Length)B)" -Level 'OK'
  Update-Verification -Entry @{ kind='seed-lowram'; input=$in; seed=$outPath; sha256=$hash; time=Get-TEIAUtcNow; ok=$true }

  if($DeleteOriginal){ Remove-Item -LiteralPath $in -Force; Write-TEIALog -Message "Original removido sob demanda: $in" -Level 'INFO' }
  Write-Host "[OK] Seed Low-RAM pronta: $outPath"
} catch {
  Write-TEIALog -Message "Erro Seed Low-RAM: $_" -Level 'ERROR'
  Update-Verification -Entry @{ kind='seed-lowram'; input=$InputPath; time=Get-TEIAUtcNow; ok=$false; error="$_" }
  throw
}
