<#
.SYNOPSIS
    TEIA-Dogfooding-Dashboard.ps1 — Painel de Controle CLI v0.80.1

.DESCRIPTION
    Wrapper interativo para o motor TEIA-Omega v0.80.0.
    NAO contem logica de engenharia — orquestra chamadas ao P11.0.

    Opcoes:
      [1] Status do Sistema (WinFsp, porta 8767, drive Z:\)
      [2] Iniciar VFS Drive Z:\
      [3] Parar VFS Drive
      [4] Executar Ingestao Segura (requer confirmacao Y/N)
      [5] Relatorio de Economia Global
      [6] Sair

    Invariante P11.0: Delta por extenso em todos os logs.
    Contencao: invoca System Manager apenas sobre MyRealData.
#>
[CmdletBinding()]
param()

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'

# ── Paths canonicos P11.0 ────────────────────────────────────────────────────
$VFSScript    = 'D:\TEIA_CORE\tools\TEIA-VFS-WinFsp-v0800.ps1'
$SysMgrScript = 'D:\TEIA_CORE\tools\TEIA-System-Manager-v0800.ps1'
$WatchDir     = 'D:\TEIA_USER\MyRealData'
$VFSPort      = 8767
$VFSDrive     = 'Z'

$script:vfsProc = $null

# ── Helpers de display ────────────────────────────────────────────────────────

function Write-Header([string]$t) {
    Write-Host ''
    Write-Host ('=' * 62) -ForegroundColor DarkCyan
    Write-Host "  $t" -ForegroundColor Cyan
    Write-Host ('=' * 62) -ForegroundColor DarkCyan
}

function Write-Row([string]$label, [string]$value, [string]$color = 'White') {
    Write-Host ("  {0,-30} {1}" -f "${label}:", $value) -ForegroundColor $color
}

function Write-Sep { Write-Host ('─' * 62) -ForegroundColor DarkGray }

# ── Opcao 1 — Status do Sistema ──────────────────────────────────────────────

function Show-Status {
    Write-Header "STATUS DO SISTEMA — TEIA-Omega v0.80.0"

    # WinFsp
    $winfsp = Get-Service -Name 'WinFsp.Launcher' -EA SilentlyContinue
    if ($winfsp) {
        $col = if ($winfsp.Status -eq 'Running') { 'Green' } else { 'Red' }
        Write-Row "WinFsp.Launcher" $winfsp.Status $col
    } else {
        Write-Row "WinFsp.Launcher" "NAO INSTALADO" 'Red'
    }

    # WebClient (necessario para WebDAV)
    $wc = Get-Service -Name 'WebClient' -EA SilentlyContinue
    if ($wc) {
        $col = if ($wc.Status -eq 'Running') { 'Green' } else { 'Yellow' }
        Write-Row "WebClient (WebDAV)" $wc.Status $col
    } else {
        Write-Row "WebClient (WebDAV)" "NAO ENCONTRADO" 'Red'
    }

    # Porta 8767
    try {
        $props    = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
        $listeners = $props.GetActiveTcpListeners()
        $portAtivo = $listeners | Where-Object { $_.Port -eq $VFSPort }
        if ($portAtivo) {
            Write-Row "WebDAV Porta $VFSPort" "ATIVO" 'Green'
        } else {
            Write-Row "WebDAV Porta $VFSPort" "INATIVO" 'Red'
        }
    } catch {
        Write-Row "WebDAV Porta $VFSPort" "ERRO: $_" 'Red'
    }

    # Drive Z:\
    $zDrive = Get-PSDrive -Name $VFSDrive -EA SilentlyContinue
    if ($zDrive) {
        Write-Row "Drive ${VFSDrive}:\" "MONTADO -> $($zDrive.Root)" 'Green'
    } else {
        Write-Row "Drive ${VFSDrive}:\" "NAO MONTADO" 'Yellow'
    }

    # Processo VFS desta sessao
    if ($script:vfsProc -and -not $script:vfsProc.HasExited) {
        Write-Row "Processo VFS (sessao)" "RODANDO (PID $($script:vfsProc.Id))" 'Green'
    } else {
        Write-Row "Processo VFS (sessao)" "NAO INICIADO" 'DarkYellow'
    }

    # Contagem de stubs
    $stubCount = (Get-ChildItem -LiteralPath $WatchDir -Recurse -Filter '*.teia_stub' -File -EA SilentlyContinue).Count
    Write-Row "Stubs em MyRealData" "$stubCount arquivos" 'Cyan'

    Write-Host ''
}

# ── Opcao 2 — Iniciar VFS Drive Z:\ ─────────────────────────────────────────

function Start-VFSDrive {
    Write-Header "INICIAR VFS DRIVE ${VFSDrive}:\"

    if ($script:vfsProc -and -not $script:vfsProc.HasExited) {
        Write-Host "  VFS ja esta rodando nesta sessao (PID $($script:vfsProc.Id))." -ForegroundColor Yellow
        Write-Host ''
        return
    }

    if (-not (Test-Path $VFSScript)) {
        Write-Host "  ERRO: Script VFS nao encontrado: $VFSScript" -ForegroundColor Red
        Write-Host ''
        return
    }

    # Garantir WebClient ativo
    $wc = Get-Service -Name 'WebClient' -EA SilentlyContinue
    if ($wc -and $wc.Status -ne 'Running') {
        Write-Host "  Iniciando servico WebClient..." -ForegroundColor DarkCyan
        try { Start-Service WebClient -EA Stop } catch { Write-Host "  Aviso: $_ (pode exigir elevacao)" -ForegroundColor Yellow }
    }

    Write-Host "  Iniciando WebDAV daemon em background (porta $VFSPort)..." -ForegroundColor Cyan
    $script:vfsProc = Start-Process pwsh `
        -ArgumentList "-ExecutionPolicy Bypass -NonInteractive -File `"$VFSScript`"" `
        -PassThru -WindowStyle Hidden

    Write-Host "  PID do processo: $($script:vfsProc.Id)" -ForegroundColor DarkCyan
    Write-Host "  Aguardando servidor inicializar (3s)..." -ForegroundColor DarkCyan
    Start-Sleep -Seconds 3

    # Montar drive
    Write-Host "  Montando ${VFSDrive}:\ via net use..." -ForegroundColor Cyan
    $mountOut = & net use "${VFSDrive}:" "\\localhost@${VFSPort}\DavWWWRoot\" /persistent:no 2>&1
    $mountColor = if ($LASTEXITCODE -eq 0) { 'Green' } else { 'Yellow' }
    Write-Host "  $mountOut" -ForegroundColor $mountColor

    Write-Host ''
}

# ── Opcao 3 — Parar VFS Drive ────────────────────────────────────────────────

function Stop-VFSDrive {
    Write-Header "PARAR VFS DRIVE ${VFSDrive}:\"

    $deleteOut = & net use "${VFSDrive}:" /delete /yes 2>&1
    Write-Host "  net use /delete: $deleteOut" -ForegroundColor DarkYellow

    if ($script:vfsProc -and -not $script:vfsProc.HasExited) {
        $pid_ = $script:vfsProc.Id
        $script:vfsProc.Kill()
        $script:vfsProc = $null
        Write-Host "  Processo VFS (PID $pid_) encerrado." -ForegroundColor DarkYellow
    } else {
        Write-Host "  Nenhum processo VFS desta sessao para encerrar." -ForegroundColor Yellow
    }

    Write-Host ''
}

# ── Opcao 4 — Ingestao Segura ────────────────────────────────────────────────

function Invoke-SafeIngestion {
    Write-Header "INGESTAO SEGURA — MyRealData"

    Write-Host ''
    Write-Host '  Aviso: Isso ira transformar os arquivos da pasta MyRealData em stubs.' -ForegroundColor Yellow
    Write-Host '  Os arquivos originais serao removidos e substituidos por .teia_stub.' -ForegroundColor Yellow
    Write-Host '  O conteudo permanece integro e recuperavel via VFS (Z:\).' -ForegroundColor DarkYellow
    Write-Host ''

    $confirm = Read-Host '  Tem certeza? [Y/N]'
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Host '  Operacao cancelada pelo operador.' -ForegroundColor DarkYellow
        Write-Host ''
        return
    }

    if (-not (Test-Path $SysMgrScript)) {
        Write-Host "  ERRO: Script System Manager nao encontrado: $SysMgrScript" -ForegroundColor Red
        Write-Host ''
        return
    }

    Write-Host "  Invocando Omni-Gestor em modo -ProcessExisting..." -ForegroundColor Cyan
    Write-Host "  WatchDir : $WatchDir" -ForegroundColor DarkCyan
    Write-Host "  Aguardando conclusao (este processo bloqueia ate finalizar)..." -ForegroundColor DarkCyan
    Write-Host ''

    & pwsh -ExecutionPolicy Bypass -File $SysMgrScript `
        -WatchDir $WatchDir `
        -ProcessExisting

    Write-Host ''
    Write-Host "  Ingestao concluida." -ForegroundColor Green
    Write-Host "  Log: D:\TEIA_CORE\logs\system_manager_v0800.log" -ForegroundColor DarkCyan
    Write-Host ''
}

# ── Opcao 5 — Relatorio de Economia Global ───────────────────────────────────

function Show-EconomyReport {
    Write-Header "RELATORIO DE ECONOMIA GLOBAL"

    $stubs = @(Get-ChildItem -LiteralPath $WatchDir -Recurse -Filter '*.teia_stub' -File -EA SilentlyContinue)
    if ($stubs.Count -eq 0) {
        Write-Host "  Nenhum stub encontrado em $WatchDir" -ForegroundColor Yellow
        Write-Host '  Execute a Ingestao Segura (opcao 4) primeiro.' -ForegroundColor DarkYellow
        Write-Host ''
        return
    }

    $totalOriginal = [long]0
    $totalCAS      = [long]0
    $byStrategy    = [ordered]@{}

    foreach ($stub in $stubs) {
        try {
            $obj = Get-Content -LiteralPath $stub.FullName -Raw | ConvertFrom-Json
            $totalOriginal += [long]$obj.original_size_bytes
            $casSz = if ($null -ne $obj.cas_size_bytes) { [long]$obj.cas_size_bytes } else { [long]0 }
            $totalCAS += $casSz
            $strat = if ($obj.final_strategy) { $obj.final_strategy } else { 'unknown' }
            if (-not $byStrategy.Contains($strat)) { $byStrategy[$strat] = 0 }
            $byStrategy[$strat]++
        } catch { }
    }

    $savings    = $totalOriginal - $totalCAS
    $savingsPct = if ($totalOriginal -gt 0) { [Math]::Round(100.0 * $savings / $totalOriginal, 1) } else { 0.0 }

    Write-Sep
    Write-Row "Arquivos ingeridos" "$($stubs.Count) stubs"
    Write-Row "Volume original total" "$([Math]::Round($totalOriginal / 1KB, 2)) KB"
    Write-Row "Volume CAS total"      "$([Math]::Round($totalCAS / 1KB, 2)) KB"
    Write-Row "Delta economia total"  "$([Math]::Round($savings / 1KB, 2)) KB ($savingsPct%)" 'Green'
    Write-Sep
    Write-Host '  Por estrategia:' -ForegroundColor DarkCyan
    foreach ($kv in $byStrategy.GetEnumerator()) {
        $col = switch -Wildcard ($kv.Key) {
            'gen.*'  { 'Green' }
            'cmp.*'  { 'Cyan'  }
            default  { 'White' }
        }
        Write-Host ("    {0,-22} {1} arquivo(s)" -f $kv.Key, $kv.Value) -ForegroundColor $col
    }
    Write-Host ''
}

# ── Menu principal ────────────────────────────────────────────────────────────

function Show-Menu {
    Write-Host ''
    Write-Sep
    Write-Host '  TEIA-Omega  PAINEL DE CONTROLE  v0.80.1' -ForegroundColor Cyan
    Write-Sep
    Write-Host '  [1] Status do Sistema'                    -ForegroundColor White
    Write-Host '  [2] Iniciar VFS Drive Z:\'               -ForegroundColor White
    Write-Host '  [3] Parar VFS Drive'                     -ForegroundColor White
    Write-Host '  [4] Executar Ingestao Segura'             -ForegroundColor Yellow
    Write-Host '  [5] Relatorio de Economia Global'         -ForegroundColor Cyan
    Write-Host '  [6] Sair'                                 -ForegroundColor DarkGray
    Write-Sep
}

# ── Entry point ───────────────────────────────────────────────────────────────

Clear-Host
Write-Host ('=' * 62) -ForegroundColor Green
Write-Host '  TEIA-Omega  OMNI-GESTOR + VFS  PAINEL DE CONTROLE' -ForegroundColor Green
Write-Host "  P11.1 — Dogfooding Dashboard  |  $(Get-Date -Format 'yyyy-MM-dd')" -ForegroundColor DarkGreen
Write-Host "  WatchDir : $WatchDir" -ForegroundColor DarkGreen
Write-Host "  VFSScript: $VFSScript" -ForegroundColor DarkGreen
Write-Host ('=' * 62) -ForegroundColor Green

while ($true) {
    Show-Menu
    $choice = Read-Host '  Opcao'
    switch ($choice.Trim()) {
        '1' { Show-Status }
        '2' { Start-VFSDrive }
        '3' { Stop-VFSDrive }
        '4' { Invoke-SafeIngestion }
        '5' { Show-EconomyReport }
        '6' { Write-Host '  Encerrando painel. Ate logo.' -ForegroundColor DarkYellow; Write-Host ''; exit 0 }
        default { Write-Host "  Opcao invalida: '$($choice.Trim())'" -ForegroundColor Red }
    }
}
