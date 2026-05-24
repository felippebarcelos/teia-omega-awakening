param(
  [Parameter(Mandatory=$true)][ValidateSet('all','seed','restore','index')][string]$cmd,
  [string]$name = 'universal_autosynth',
  [string]$root = '.',
  [string]$hash = '',
  [switch]$infinite
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$uc = Join-Path $PSScriptRoot 'universal_core'
$scripts = Join-Path $uc 'scripts'
$logger = Join-Path $scripts 'TEIA-Logger.ps1'

. $logger -LogPath (Join-Path $uc 'logs/dna_universal.log') -VerificationPath (Join-Path $uc 'logs/verification_universal.json')

Write-TEIALog -Message "CodexCLI start cmd=$cmd name=$name root=$root hash=$hash infinite=$($infinite.IsPresent)" -Level 'INFO'

switch ($cmd) {
  'seed' {
    $files = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 100
    foreach ($f in $files) {
      & (Join-Path $scripts 'TEIA-OntoSeed-Gen.ps1') -InputPath $f.FullName -Quiet -ErrorAction Continue | Out-Null
    }
  }
  'restore' {
    $seeds = Get-ChildItem -Path (Join-Path $uc 'data/seeds') -Filter *.seed.json -ErrorAction SilentlyContinue
    foreach ($s in $seeds) {
      & (Join-Path $scripts 'TEIA-OntoEngine-Restore.ps1') -SeedPath $s.FullName -Quiet -ErrorAction Continue | Out-Null
    }
  }
  'index' {
    & (Join-Path $scripts 'TEIA-Integrate-Fractal.ps1') -Root $root -OutPath (Join-Path $uc 'data/fractal_index_unified.json') -ErrorAction Continue | Out-Null
  }
  'all' {
    $loop = Join-Path $scripts 'TEIA-AutoSynth-Loop.ps1'
    if ($infinite) {
      while ($true) {
        & $loop -ScanRoot $root -MaxPasses 1 -ErrorAction Continue | Out-Null
        if (Test-Path (Join-Path $uc 'STOP')) { Write-TEIALog -Message 'STOP sentinel found. Exiting infinite loop.' -Level 'WARN'; break }
        Start-Sleep -Seconds 5
      }
    } else {
      & $loop -ScanRoot $root -MaxPasses 1 -ErrorAction Continue | Out-Null
    }
  }
}

Write-TEIALog -Message "CodexCLI end cmd=$cmd" -Level 'OK'

