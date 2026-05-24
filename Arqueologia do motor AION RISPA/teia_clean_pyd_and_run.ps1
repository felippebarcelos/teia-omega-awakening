# teia_clean_pyd_and_run.ps1
# Uso: abra PowerShell em D:\Teia\TEIA_NUCLEO\offline\nano e rode: .\teia_clean_pyd_and_run.ps1

$TS = (Get-Date).ToString('yyyyMMdd_HHmmss')
$ROOT = (Get-Location).Path
Write-Host "ROOT:" $ROOT "TS:" $TS

# lista de nomes nativos conhecidos que costumam causar conflito
$nativeNames = @('_lzma.pyd','_socket.pyd','_decimal.pyd','_pydecimal.pyd','_bz2.pyd','_ssl.pyd','_tkinter.pyd','_hashlib.pyd','_ctypes.pyd')

# encontra e move para backup
$found = @()
foreach ($name in $nativeNames) {
    $files = Get-ChildItem -Path $ROOT -Filter $name -File -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        $dst = "$($f.FullName).teia_bak_$TS"
        Move-Item -LiteralPath $f.FullName -Destination $dst -Force
        Write-Host "➡️ Movido: $($f.Name) -> $dst"
        $found += $dst
    }
}

# também mover qualquer *.pyd ou *.dll suspeito no root (apenas root, não recursivo)
$extra = Get-ChildItem -Path $ROOT -Include '*.pyd','*.dll' -File -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch '\.teia_bak_' } 
if ($extra) {
    foreach ($e in $extra) {
        $dst = "$($e.FullName).teia_bak_$TS"
        Move-Item -LiteralPath $e.FullName -Destination $dst -Force
        Write-Host "➡️ Movido extra: $($e.Name) -> $dst"
        $found += $dst
    }
}

if (-not $found) {
    Write-Host "Nenhum ficheiro nativo conflitante encontrado no diretório root."
} else {
    Write-Host "`nArquivos movidos. Verifique os backups antes de apagar permanentemente."
}

# Caminho do python do venv fresco (ajuste se diferente)
$pyNew = Join-Path $ROOT "agent_env_py_fresh_20250908_003848\Scripts\python.exe"
if (-not (Test-Path $pyNew)) {
    Write-Host "AVISO: python do venv fresco não encontrado em $pyNew. Ajuste a variável \$pyNew no script."
} else {
    Write-Host "`nVerificando imports nativos com o novo python:"
    & $pyNew -c "import importlib.util, sys; print('python ->', sys.executable); print('python version ->', sys.version.split()[0]); 
spec=importlib.util.find_spec('_lzma'); print('_lzma spec ->', getattr(spec,'origin',None))"
    Write-Host "`nTestando import _lzma no novo venv:"
    & $pyNew -c "import sys; import importlib; import importlib.util; importlib.util.find_spec('_lzma'); import _lzma; import lzma; print('lzma ok with', sys.executable)"
    Write-Host "`nSe tudo OK, iniciando Streamlit com o novo venv (pressione Ctrl+C para parar)..."
    & $pyNew -m streamlit run .\dashboard_teia_auditoria_total.py
}
