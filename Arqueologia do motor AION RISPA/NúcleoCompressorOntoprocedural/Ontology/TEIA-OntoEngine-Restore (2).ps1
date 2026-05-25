param(
  [Parameter(Mandatory=$true)][string]$SeedPath,
  [string]$OutputPath,
  [string]$LogPath = "$PSScriptRoot/../logs/dna_universal.log",
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

. "$PSScriptRoot/TEIA-Logger.ps1" -LogPath $LogPath -VerificationPath "$PSScriptRoot/../logs/verification_universal.json"

function Bytes-From-Hex {
  param([string]$Hex)
  $hexClean = $Hex -replace '\s',''
  $len = $hexClean.Length
  $out = New-Object byte[] ($len/2)
  for ($i=0; $i -lt $len; $i+=2) {
    $out[$i/2] = [Convert]::ToByte($hexClean.Substring($i,2),16)
  }
  return $out
}

try {
  $seedObj = Get-Content $SeedPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 64
  $gen = $seedObj.generator
  $size = [int64]$seedObj.size
  $sha = [string]$seedObj.sha256

  if (-not $OutputPath) {
    $base = [IO.Path]::GetFileNameWithoutExtension([IO.Path]::GetFileName($seedObj.file))
    $OutputPath = Join-Path "$PSScriptRoot/../data" ("restore_" + $base + "_" + $sha.Substring(0,12))
  }
  $outDir = Split-Path -Parent $OutputPath
  if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

  $bytes = $null
  switch ($gen.name) {
    'empty' { $bytes = New-Object byte[] 0 }
    'repeat_byte' {
      $val = [byte]$gen.params.value
      $bytes = New-Object byte[] $size
      [System.Array]::Fill($bytes, $val) | Out-Null
    }
    'repeat_sequence' {
      $hex = [string]$gen.params.hex
      $period = [int]$gen.params.period
      $seq = Bytes-From-Hex $hex
      if ($seq.Length -ne $period) { throw "Seed mismatch: period vs hex length" }
      $bytes = New-Object byte[] $size
      for ($i=0; $i -lt $size; $i++) { $bytes[$i] = $seq[$i % $period] }
    }
    default { throw "No procedural generator available: $($gen.name)" }
  }

  $outFile = $OutputPath
  [IO.File]::WriteAllBytes($outFile, $bytes)
  $rehash = Get-TEIASha256 $bytes
  if ($rehash -ne $sha) { throw "Hash mismatch after restore: expected=$sha got=$rehash" }
  if (-not $Quiet) { Write-Host "[OK] Restored: $outFile" }
  Write-TEIALog -Message "Restore OK '$outFile' sha=$rehash from seed '$SeedPath'" -Level 'OK'
  Update-Verification -Entry @{ kind='restore'; output=$outFile; seed=$SeedPath; sha256=$rehash; time=Get-TEIAUtcNow; ok=$true }
} catch {
  Write-TEIALog -Message "Erro Restore: $_" -Level 'ERROR'
  if (-not $Quiet) { Write-Error $_ }
  Update-Verification -Entry @{ kind='restore'; output=$OutputPath; seed=$SeedPath; sha256=$sha; time=Get-TEIAUtcNow; ok=$false; error="$_" }
  exit 1
}

