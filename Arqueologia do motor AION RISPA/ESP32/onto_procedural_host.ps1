# onto_procedural_host.ps1
# TEIA textdoc embed Codex — Orquestrador host para ESP32/MicroPython
# Requisitos no host: PowerShell 7+, Python 3 com mpremote instalado (pip install mpremote)
# Funções: detectar porta, enviar arquivos, executar manifesto local ou interativo JLines.

param(
    [string]$PortHint = "",
    [string]$MpRemote = "mpremote",
    [string]$BoardRoot = "/",
    [string]$ManifestFile = "manifest_seed.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info($m){ Write-Host "[INFO] $m" }
function Write-Err($m){ Write-Host "[ERRO] $m" }

# 1) Localiza porta serial (heurística simples)
function Find-SerialPort {
    param([string]$Hint)
    if($Hint){ return $Hint }
    $ports = [System.IO.Ports.SerialPort]::GetPortNames() | Sort-Object
    if(-not $ports){ throw "Nenhuma porta serial encontrada. Conecte o ESP32." }
    # Preferência por COM maiores (USB recentes)
    return $ports[-1]
}

# 2) Verifica mpremote
function Assert-MpRemote {
    param([string]$Cmd)
    try {
        $ver = & $Cmd version 2>$null
        if($LASTEXITCODE -ne 0){ throw "mpremote retornou código $LASTEXITCODE" }
        Write-Info "mpremote OK: $ver"
    } catch {
        throw "mpremote não encontrado. Instale com: pip install mpremote"
    }
}

# 3) Envia arquivos para o board
function Push-Files {
    param(
        [string]$Cmd,
        [string]$Port,
        [string]$LocalPy,
        [string]$LocalManifest
    )
    Write-Info "Enviando esp32_onto_procedural.py"
    & $Cmd connect $Port fs cp $LocalPy :/esp32_onto_procedural.py
    if($LASTEXITCODE -ne 0){ throw "Falha ao enviar esp32_onto_procedural.py" }

    Write-Info "Enviando manifest_seed.json"
    & $Cmd connect $Port fs cp $LocalManifest :/manifest_seed.json
    if($LASTEXITCODE -ne 0){ throw "Falha ao enviar manifest_seed.json" }
}

# 4) Executa o manifesto no board
function Run-Manifest {
    param(
        [string]$Cmd,
        [string]$Port,
        [string]$RemoteManifest
    )
    Write-Info "Executando manifesto: $RemoteManifest"
    & $Cmd connect $Port run :/esp32_onto_procedural.py $RemoteManifest
}

# 5) Modo interativo (linhas JSON)
function Run-Interactive {
    param([string]$Cmd,[string]$Port)
    Write-Info "Iniciando modo interativo (Ctrl+C para sair)"
    & $Cmd connect $Port run :/esp32_onto_procedural.py
}

# ---------- Fluxo principal ----------
try {
    $port = Find-SerialPort -Hint $PortHint
    Write-Info "Usando porta: $port"
    Assert-MpRemote -Cmd $MpRemote

    $LocalPy = Join-Path $PSScriptRoot "esp32_onto_procedural.py"
    $LocalManifest = Join-Path $PSScriptRoot $ManifestFile

    if(-not (Test-Path $LocalPy)){ throw "Arquivo não encontrado: $LocalPy" }
    if(-not (Test-Path $LocalManifest)){ throw "Arquivo não encontrado: $LocalManifest" }

    Push-Files -Cmd $MpRemote -Port $port -LocalPy $LocalPy -LocalManifest $LocalManifest

    Run-Manifest -Cmd $MpRemote -Port $port -RemoteManifest "/manifest_seed.json"

    Write-Info "Concluído. Para modo interativo, execute: `n  .\onto_procedural_host.ps1 ; Run-Interactive -Cmd $MpRemote -Port $port"
} catch {
    Write-Err $_.Exception.Message
    exit 1
}
# ---- 4 linhas de uso rápido ----
# 1) Instale mpremote:  pip install mpremote
# 2) Conecte o ESP32 (MicroPython gravado) via USB.
# 3) No PowerShell:  .\onto_procedural_host.ps1
# 4) Veja a saída JSON no console e o log em /log_onto.txt no dispositivo.
