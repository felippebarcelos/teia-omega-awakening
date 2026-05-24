# teia_fix_shadowing.ps1
# Move arquivos/pastas que podem "shadow" stdlib/pip modules inside the project folder
# Backup suffix: .teia_bak_YYYYMMDD_HHMMSS

$root = 'D:\Teia\TEIA_NUCLEO\offline\nano'
$timestamp = Get-Date -Format yyyyMMdd_HHmmss
$names = @(
  'watchdog','packaging','sysconfig','importlib','types','copy','functools','inspect',
  'logging','re','enum','runpy','typing','operator','pytest','requests','json','pathlib',
  '__future__','operator','logging_handlers','requests','xml','asyncio'
)

Write-Host "Procurando arquivos potencialmente conflituosos em: $root" -ForegroundColor Cyan

$foundAny = $false

foreach ($n in $names) {
  # patterns to check: exact, wildcard, .pyc, directory
  $patterns = @("$n.py", "$n*.py", "$n.pyc", "$n*.*c", $n)
  foreach ($pat in $patterns) {
    $items = Get-ChildItem -Path $root -Filter $pat -Force -ErrorAction SilentlyContinue
    foreach ($it in $items) {
      $foundAny = $true
      $src = $it.FullName
      $dst = "$src.teia_bak_$timestamp"
      try {
        Move-Item -LiteralPath $src -Destination $dst -Force
        Write-Host "➡️ Movido: $src -> $dst"
      } catch {
        Write-Warning "Falha ao mover $src : $_"
      }
    }
  }
}

# também mover __pycache__ se existir (backup)
$pyc = Join-Path $root "__pycache__"
if (Test-Path $pyc) {
  $dstpc = "$pyc.teia_bak_$timestamp"
  Move-Item -LiteralPath $pyc -Destination $dstpc -Force
  Write-Host "➡️ Movido __pycache__: $pyc -> $dstpc"
  $foundAny = $true
}

if (-not $foundAny) {
  Write-Host "Nenhum arquivo de conflito listado foi encontrado (checados: $($names -join ', '))." -ForegroundColor Yellow
} else {
  Write-Host "Operação concluída. Arquivos movidos com sufixo .teia_bak_$timestamp" -ForegroundColor Green
  Write-Host "Verifique o conteúdo dos backups antes de apagar permanentemente."
}
