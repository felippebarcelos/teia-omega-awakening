param([string]$Root='.')
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[System.Text.Encoding]::UTF8
Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 100 | ForEach-Object {
  & "universal_core/scripts/TEIA-OntoSeed-Gen.ps1" -InputPath $_.FullName -Quiet -ErrorAction Continue | Out-Null
}

