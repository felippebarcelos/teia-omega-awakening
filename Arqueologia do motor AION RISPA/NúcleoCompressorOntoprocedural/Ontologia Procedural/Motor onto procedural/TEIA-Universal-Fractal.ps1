param([string]$Root='.',[string]$OutPath='universal_core/data/fractal_index_unified.json')
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[System.Text.Encoding]::UTF8
& "universal_core/scripts/TEIA-Integrate-Fractal.ps1" -Root $Root -OutPath $OutPath

