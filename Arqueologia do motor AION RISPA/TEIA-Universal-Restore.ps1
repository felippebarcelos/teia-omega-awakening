param([string]$SeedsDir='universal_core/data/seeds')
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[System.Text.Encoding]::UTF8
Get-ChildItem -Path $SeedsDir -Filter *.seed.json -ErrorAction SilentlyContinue | ForEach-Object {
  & "universal_core/scripts/TEIA-OntoEngine-Restore.ps1" -SeedPath $_.FullName -Quiet -ErrorAction Continue | Out-Null
}

