param(
  [string]$Root = (Get-Location).Path,
  [string[]]$Names = @("random","torch","secrets","glob","token","tokenize","tokenizer","tokens"),
  [switch]$VerboseOutput
)
$ts = Get-Date -Format yyyyMMdd_HHmmss
Write-Host "ROOT: $Root   TS: $ts"

foreach ($n in $Names) {
  $py = Join-Path $Root ($n + ".py")
  if (Test-Path $py) {
    $dst = "$py.teia_bak_$ts"
    Move-Item -LiteralPath $py -Destination $dst -Force
    if ($VerboseOutput) { Write-Host "➡️ Movido: $py -> $dst" } else { Write-Host "Moved $n.py" }
  }
  Get-ChildItem -Path $Root -Filter "$n*.pyc" -File -ErrorAction SilentlyContinue | ForEach-Object {
    $dst = "$($_.FullName).teia_bak_$ts"
    Move-Item -LiteralPath $_.FullName -Destination $dst -Force
    if ($VerboseOutput) { Write-Host "➡️ Movido: $($_.FullName) -> $dst" }
  }
}
# move __pycache__ se contiver ficheiros (opcional)
$pyc = Join-Path $Root "__pycache__"
if (Test-Path $pyc) {
  $items = Get-ChildItem $pyc -File -ErrorAction SilentlyContinue
  if ($items) {
    $dstpc = "$pyc.teia_bak_$ts"
    Move-Item -LiteralPath $pyc -Destination $dstpc -Force
    Write-Host "➡️ Movido __pycache__: $pyc -> $dstpc"
  }
}
Write-Host "Verificação de import resolution:"
$pyExe = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $pyExe) { $pyExe = "python" }
foreach ($n in $Names) {
  & $pyExe -c "import importlib.util; spec=importlib.util.find_spec('$n'); print('$n ->', getattr(spec,'origin',None))"
}
Write-Host "Fim. Verifique backups *.teia_bak_$ts"
