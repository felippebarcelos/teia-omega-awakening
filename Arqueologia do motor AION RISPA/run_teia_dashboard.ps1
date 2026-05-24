# run_teia_dashboard.ps1
# TEIA — inicia Streamlit de maneira idempotente e não bloqueante.
# Salve em: D:\Teia\TEIA_NUCLEO\offline\nano\run_teia_dashboard.ps1

$scriptPath = 'D:\Teia\TEIA_NUCLEO\offline\nano\teia_dashboard_streamlit.py'
$logDir = Join-Path -Path $env:TEMP -ChildPath 'teia_streamlit_logs'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$stdout = Join-Path $logDir "streamlit_stdout_$(Get-Date -Format yyyyMMdd_HHmmss).log"
$stderr = Join-Path $logDir "streamlit_stderr_$(Get-Date -Format yyyyMMdd_HHmmss).log"

# 1) valida existencia do arquivo do app
if (-not (Test-Path -LiteralPath $scriptPath)) {
  Write-Error "Arquivo do app não encontrado: $scriptPath`nColoque teia_dashboard_streamlit.py neste caminho e tente novamente."
  exit 1
}

# 2) localizar Python (prioriza python, depois py)
$pythonCmd = $null
$cmd = Get-Command python -ErrorAction SilentlyContinue
if ($cmd) { $pythonCmd = $cmd.Source } else {
  $cmd2 = Get-Command py -ErrorAction SilentlyContinue
  if ($cmd2) { $pythonCmd = $cmd2.Source }
}
if (-not $pythonCmd) {
  Write-Error "Python não encontrado no PATH. Instale Python 3.8+ e adicione ao PATH."
  exit 2
}
Write-Host "Usando Python em: $pythonCmd"

# 3) checar streamlit instalado (fallback: instalar)
& $pythonCmd -c "import importlib,sys; sys.exit(0) if importlib.util.find_spec('streamlit') else sys.exit(3)" 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Streamlit não encontrado — instalando (streamlit, pandas, plotly)…"
  & $pythonCmd -m pip install --upgrade pip | Out-Null
  & $pythonCmd -m pip install streamlit pandas plotly | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha ao instalar dependências. Verifique permissão/conexão."
    exit 3
  }
  Write-Host "Dependências instaladas."
} else {
  Write-Host "Streamlit detectado."
}

# 4) montar comando e iniciar em background (Start-Process)
$arg = "-m streamlit run `"$scriptPath`" --server.port 8501 --server.headless true"
Write-Host "Iniciando Streamlit em background..."
# Start-Process com redirecionamento de stdout/stderr
$si = New-Object System.Diagnostics.ProcessStartInfo
$si.FileName = $pythonCmd
$si.Arguments = $arg
$si.WorkingDirectory = Split-Path $scriptPath
$si.CreateNoWindow = $true
$si.RedirectStandardOutput = $true
$si.RedirectStandardError = $true
$si.UseShellExecute = $false

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $si
$started = $proc.Start()
if ($started) {
  # assíncrono: grava logs em background
  $outWriter = [System.IO.StreamWriter]::new($stdout, $false, [System.Text.Encoding]::UTF8)
  $errWriter = [System.IO.StreamWriter]::new($stderr, $false, [System.Text.Encoding]::UTF8)
  Start-Job -ScriptBlock {
    param($p,$o,$e)
    $sr = $p.StandardOutput; $se = $p.StandardError
    while (-not $p.HasExited) {
      try { 
        if (-not $sr.EndOfStream) { $l = $sr.ReadLine(); if ($l -ne $null) { $o.WriteLine($l); $o.Flush() } }
        if (-not $se.EndOfStream) { $l2 = $se.ReadLine(); if ($l2 -ne $null) { $e.WriteLine($l2); $e.Flush() } }
      } catch { Start-Sleep -Milliseconds 100 }
      Start-Sleep -Milliseconds 200
    }
    # flush remaining
    while (-not $sr.EndOfStream) { $o.WriteLine($sr.ReadLine()); $o.Flush() }
    while (-not $se.EndOfStream) { $e.WriteLine($se.ReadLine()); $e.Flush() }
    $o.Close(); $e.Close()
  } -ArgumentList $proc,$outWriter,$errWriter | Out-Null

  Start-Sleep -Seconds 1
  Write-Host "Streamlit iniciado (PID: $($proc.Id)). Logs: $stdout  $stderr"
  Write-Host "Abra: http://localhost:8501"
} else {
  Write-Error "Falha ao iniciar o processo Streamlit."
  exit 4
}

# 5) mensagem final
Write-Host "Se quiser parar o app depois, use: Stop-Process -Id $($proc.Id) -Force"
