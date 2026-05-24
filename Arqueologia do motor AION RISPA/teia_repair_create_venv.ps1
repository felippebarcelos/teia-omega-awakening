# teia_repair_create_venv.ps1
$ts = (Get-Date).ToString('yyyyMMdd_HHmmss')
$py = (Get-Command python -ErrorAction Stop).Source
Write-Host "Python usado:" $py

# onde criar o novo venv
$base = (Get-Location).Path
$newenv = Join-Path $base "agent_env_py_fresh_$ts"
Write-Host "Criando virtualenv em:" $newenv

# criar venv
& $py -m venv $newenv
if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao criar venv"; exit 1 }

# caminho do python do novo venv
$pyNew = Join-Path $newenv 'Scripts\python.exe'
$pipNew = Join-Path $newenv 'Scripts\pip.exe'
Write-Host "novo python ->" $pyNew

# ativar não é estritamente necessário para comandos: usamos o executável diretamente
# atualizar pip
& $pyNew -m pip install --upgrade pip setuptools wheel
# instalar dependências essenciais (pode ajustar a lista)
& $pyNew -m pip install streamlit pandas plotly sympy watchdog starlette anyio

Write-Host ""
Write-Host "=== Pronto ==="
Write-Host "Para rodar com o novo venv faça:"
Write-Host "`t$pyNew -m streamlit run dashboard_teia_auditoria_total.py"
Write-Host "ou (CLI):"
Write-Host "`t$pyNew dashboard_teia_auditoria_total.py --inputs bench_inputs --reports bench_reports --restored bench_restored --seeds bench_seeds --watch"
