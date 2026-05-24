[CmdletBinding()]
param(
    [string]$DropzonePath = 'D:\TEIA_DROPZONE',
    [string]$SeedsPath    = 'D:\TEIA_SEEDS',
    [string]$CofrePath    = 'D:\TEIA_COFRE',
    [string]$MmapEngine   = 'D:\TEIA_CLAUDE_AWAKENING\TEIA-Mmap-Engine.py',
    [string]$LogFile      = 'D:\TEIA_SEEDS\watcher.log'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Extensoes de baixa entropia → rota procedural SR-AUT
$ExtProcedural = @('.txt','.json','.ps1','.py','.md','.csv','.xml','.log','.ini','.toml','.yaml','.yml')
# Extensoes de alta entropia → rota mmap SR-REF (qualquer outra extensao tambem cai aqui)
$ExtEntropico  = @('.mp4','.mkv','.gguf','.bin','.iso','.zip','.tar','.avi','.mov','.rar','.7z','.gz','.bz2','.wav','.flac')

# ── Auto-detecta executavel Python ────────────────────────────────────────────
$PythonExe = 'python'
try {
    $v = & python --version 2>&1
    if ($LASTEXITCODE -ne 0) { $PythonExe = 'python3' }
} catch { $PythonExe = 'python3' }

# ── Logging ────────────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Msg, [string]$Level = 'INFO')
    $ts   = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
    $line = "[$ts][$Level] $Msg"
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 } catch {}
    Write-Output $line   # capturado por Receive-Job no test runner
}

# ── Aguarda arquivo estavel (gravacao completa) ───────────────────────────────
function Wait-FileComplete {
    param([string]$Path, [int]$StableMs = 3000, [int]$TimeoutSec = 300)
    $lastSize  = -1L
    $stableAt  = [DateTime]::MaxValue
    $deadline  = [DateTime]::Now.AddSeconds($TimeoutSec)
    while ([DateTime]::Now -lt $deadline) {
        if (-not (Test-Path -LiteralPath $Path)) { Start-Sleep -Milliseconds 400; continue }
        try {
            $sz = (Get-Item -LiteralPath $Path -ErrorAction Stop).Length
            if ($sz -eq $lastSize) {
                if ([DateTime]::Now -ge $stableAt) { return $true }
            } else {
                $lastSize = $sz
                $stableAt = [DateTime]::Now.AddMilliseconds($StableMs)
            }
        } catch { }
        Start-Sleep -Milliseconds 400
    }
    return $false
}

# ── Rota procedural: SHA-256 direto → SR-AUT simples ─────────────────────────
function Invoke-RotaProcedural {
    param([string]$FilePath)
    $name = [System.IO.Path]::GetFileName($FilePath)
    Write-Log "Rota SR-AUT (procedural/baixa entropia): $name"
    $sha  = (Get-FileHash -LiteralPath $FilePath -Algorithm SHA256).Hash.ToLower()
    $size = (Get-Item -LiteralPath $FilePath).Length
    $seed = [ordered]@{
        v                = 'SR-AUT-PROC-1.0'
        tipo             = 'procedural'
        motor            = 'sha256-catalog'
        arquivo_original = $name
        sha256           = $sha
        tamanho_bytes    = $size
        gerado_em        = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
    }
    $seedFile = Join-Path $SeedsPath ($name + '.sraut.json')
    $seed | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $seedFile -Encoding UTF8
    Write-Log "SR-AUT salva: $seedFile"
    return $seedFile
}

# ── Rota mmap: delega ao motor Python ─────────────────────────────────────────
function Invoke-RotaMmap {
    param([string]$FilePath)
    $name = [System.IO.Path]::GetFileName($FilePath)
    Write-Log "Rota SR-REF (mmap/alta entropia): $name"
    Write-Log "Invocando TEIA-Mmap-Engine.py..."

    $pyOutput = & $PythonExe $MmapEngine `
        --input $FilePath `
        --seeds-dir $SeedsPath `
        --chunk-mb 256 2>&1

    foreach ($line in $pyOutput) {
        $lineStr = [string]$line
        if ($lineStr.StartsWith('SRREF_JSON:')) { continue }  # nao polui o log com JSON
        Write-Log $lineStr 'MMAP'
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Log "MmapEngine falhou com exit $LASTEXITCODE" 'ERROR'
        return $null
    }

    $seedFile = Join-Path $SeedsPath ($name + '.srref.json')
    if (-not (Test-Path -LiteralPath $seedFile)) {
        Write-Log "SR-REF nao encontrada pos-engine: $seedFile" 'ERROR'
        return $null
    }

    # Extrair metricas para log final
    $srref = Get-Content -LiteralPath $seedFile -Raw | ConvertFrom-Json
    $deltaRamEcon = [Math]::Round([double]$srref.delta_ram_economia_mb, 0)
    Write-Log ("SR-REF gerada | SHA-256: {0}..." -f $srref.sha256.Substring(0, 16))
    Write-Log ("Pico RSS mmap    : {0:F1} MB | Delta RAM economizado: {1} MB vs carga total" -f `
        $srref.pico_rss_mb, $deltaRamEcon)
    Write-Log ("Throughput mmap  : {0:F1} MB/s | Elapsed: {1}s" -f $srref.throughput_mbs, $srref.elapsed_s)
    return $seedFile
}

# ── Processa um arquivo detectado na dropzone ─────────────────────────────────
function Invoke-ProcessarArquivo {
    param([string]$FilePath)
    $name = [System.IO.Path]::GetFileName($FilePath)
    $ext  = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $sizeMB = 0.0

    Write-Log "=================================================="
    Write-Log "ARQUIVO DETECTADO: $name"

    # Aguardar estabilidade (gravacao completa)
    Write-Log "Aguardando estabilidade do arquivo..."
    $stable = Wait-FileComplete -Path $FilePath -StableMs 3000 -TimeoutSec 600
    if (-not $stable) {
        Write-Log "Timeout aguardando estabilidade: $name" 'WARN'
        return
    }

    $item = Get-Item -LiteralPath $FilePath
    $sizeMB = [Math]::Round($item.Length / 1MB, 2)
    Write-Log ("Arquivo estavel: $name | {0:F2} MB | ext: {1}" -f $sizeMB, $ext)

    $swProc = [System.Diagnostics.Stopwatch]::StartNew()
    $seedFile = $null

    if ($ext -in $ExtProcedural) {
        $seedFile = Invoke-RotaProcedural -FilePath $FilePath
    } else {
        # Default: mmap para alta entropia e extensoes desconhecidas
        $seedFile = Invoke-RotaMmap -FilePath $FilePath
    }

    $swProc.Stop()

    if ($null -eq $seedFile) {
        Write-Log "Processamento falhou para: $name" 'ERROR'
        return
    }

    # Mover original para o cofre (armazenamento frio)
    $destPath = Join-Path $CofrePath $name
    try {
        Move-Item -LiteralPath $FilePath -Destination $destPath -Force
        Write-Log "Original movido para cofre: $destPath"
    } catch {
        Write-Log "Erro ao mover para cofre: $_" 'ERROR'
    }

    Write-Log ("Processamento total : {0} ms | Semente : {1}" -f `
        $swProc.ElapsedMilliseconds, [System.IO.Path]::GetFileName($seedFile))
    Write-Log "Delta IO disco pos-semente: 0 bytes (semente e referencial, nao restaura)"
    Write-Log "=================================================="
}

# ── Inicializacao ─────────────────────────────────────────────────────────────
foreach ($d in @($DropzonePath, $SeedsPath, $CofrePath)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# Iniciar log da sessao
Set-Content -LiteralPath $LogFile -Value '' -Encoding UTF8
Write-Log "TEIA-Dropzone-Watcher iniciado"
Write-Log "Dropzone : $DropzonePath"
Write-Log "Seeds    : $SeedsPath"
Write-Log "Cofre    : $CofrePath"
Write-Log "Python   : $PythonExe | MmapEngine: $MmapEngine"
Write-Log "--------------------------------------------------"

# Drena arquivos ja existentes na dropzone
$existentes = @(Get-ChildItem -LiteralPath $DropzonePath -File -ErrorAction SilentlyContinue)
if ($existentes.Count -gt 0) {
    Write-Log "Drenando $($existentes.Count) arquivo(s) pre-existentes..."
    foreach ($f in $existentes) { Invoke-ProcessarArquivo -FilePath $f.FullName }
}

# ── Loop principal: FileSystemWatcher ────────────────────────────────────────
$watcher = New-Object System.IO.FileSystemWatcher $DropzonePath
$watcher.IncludeSubdirectories = $false
$watcher.NotifyFilter          = [System.IO.NotifyFilters]::FileName
$watcher.EnableRaisingEvents   = $true

Write-Log "Watcher ativo. Aguardando eventos em: $DropzonePath"

while ($true) {
    try {
        $evt = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::Created, 4000)
        if ($evt.TimedOut) { continue }

        $filePath = Join-Path $DropzonePath $evt.Name
        if (-not (Test-Path -LiteralPath $filePath)) {
            Write-Log "Evento recebido mas arquivo nao encontrado: $($evt.Name)" 'WARN'
            continue
        }
        Invoke-ProcessarArquivo -FilePath $filePath

    } catch [System.Exception] {
        Write-Log "Excecao no loop watcher: $_" 'ERROR'
        Start-Sleep -Seconds 2
    }
}
