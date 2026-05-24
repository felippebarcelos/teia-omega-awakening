[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-Location 'D:\TEIA_CLAUDE_AWAKENING'

$DropzonePath   = 'D:\TEIA_DROPZONE'
$SeedsPath      = 'D:\TEIA_SEEDS'
$CofrePath      = 'D:\TEIA_COFRE'
$WatcherScript  = 'D:\TEIA_CLAUDE_AWAKENING\TEIA-Dropzone-Watcher.ps1'
$LogFile        = 'D:\TEIA_SEEDS\watcher.log'
$TestFileName   = 'teste_alta_entropia_1GB.bin'
$TestFilePath   = Join-Path $DropzonePath $TestFileName
$SeedFilePath   = Join-Path $SeedsPath ($TestFileName + '.srref.json')
$CofredFilePath = Join-Path $CofrePath $TestFileName
$TamanhoGB      = 1   # GB do arquivo de teste

# ── C# gerador rapido de binario alta-entropia (~System.Random, ~500 MB/s) ────
if (-not ('FastGen' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.IO;
public static class FastGen {
    public static void EscreverBinRandom(string path, long sizeBytes, int seed) {
        var rng = new Random(seed);
        byte[] buf = new byte[64 * 1024 * 1024];   // 64 MB por passagem
        using var fs = new FileStream(path, FileMode.Create, FileAccess.Write,
                                      FileShare.None, 64 * 1024);
        long written = 0;
        while (written < sizeBytes) {
            rng.NextBytes(buf);
            int toWrite = (int)Math.Min(buf.Length, sizeBytes - written);
            fs.Write(buf, 0, toWrite);
            written += toWrite;
        }
        fs.Flush();
    }
}
'@
}

# ── Banner ────────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '======================================================================' -ForegroundColor Cyan
Write-Host ' [TCT/IGNICAO_DROPZONE_UNIVERSAL] TEIA-Dropzone-TestRun.ps1'           -ForegroundColor Cyan
Write-Host ' Motor Mmap (alta entropia) + Watcher FileSystemWatcher'               -ForegroundColor Cyan
Write-Host ' Prova: 1 GB dropado → SR-REF via mmap → cofre frio (zero I/O extra)'  -ForegroundColor Cyan
Write-Host '======================================================================'

# ── [1/6] Preparar ambiente ───────────────────────────────────────────────────
Write-Host "`n[1/6] Preparando ambiente..." -ForegroundColor Yellow
foreach ($d in @($DropzonePath, $SeedsPath, $CofrePath)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    Write-Host "  OK: $d"
}
if (Test-Path -LiteralPath $TestFilePath)  { Remove-Item -LiteralPath $TestFilePath  -Force }
if (Test-Path -LiteralPath $SeedFilePath)  { Remove-Item -LiteralPath $SeedFilePath  -Force }
if (Test-Path -LiteralPath $LogFile)       { Set-Content -LiteralPath $LogFile -Value '' -Encoding UTF8 }

# ── [2/6] Iniciar Watcher como background job ─────────────────────────────────
Write-Host "`n[2/6] Iniciando TEIA-Dropzone-Watcher como job..." -ForegroundColor Yellow
$job = Start-Job -FilePath $WatcherScript `
    -ArgumentList $DropzonePath, $SeedsPath, $CofrePath, `
        'D:\TEIA_CLAUDE_AWAKENING\TEIA-Mmap-Engine.py', $LogFile

Write-Host "  Job ID   : $($job.Id) | Nome: $($job.Name)"
Start-Sleep -Seconds 3   # aguardar watcher inicializar

# Mostrar primeiras linhas do log (inicializacao)
$logInit = Get-Content -LiteralPath $LogFile -ErrorAction SilentlyContinue
$logInit | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkCyan }
$linhasVistas = if ($logInit) { $logInit.Count } else { 0 }
Write-Host "  Watcher inicializado."

# ── [3/6] Gerar arquivo binario de $TamanhoGB GB (alta entropia) ──────────────
Write-Host "`n[3/6] Gerando arquivo de teste ($TamanhoGB GB) na dropzone..." -ForegroundColor Yellow
$tamBytes = [long]$TamanhoGB * 1024 * 1024 * 1024
Write-Host ("  Alvo    : $TestFilePath")
Write-Host ("  Tamanho : {0:F3} GB ({1} bytes)" -f ($tamBytes/1GB), $tamBytes)
Write-Host "  Gerador : C# FastGen (System.Random, seed=0xBEEF)"

$swGen = [System.Diagnostics.Stopwatch]::StartNew()
[FastGen]::EscreverBinRandom($TestFilePath, $tamBytes, 0xBEEF)
$swGen.Stop()
$sizeReal = (Get-Item -LiteralPath $TestFilePath).Length
$genThroughput = [Math]::Round($sizeReal / 1MB / ($swGen.ElapsedMilliseconds / 1000.0), 1)
Write-Host ("  Gerado  : {0:F3} GB em {1} ms ({2:F0} MB/s)" -f `
    ($sizeReal/1GB), $swGen.ElapsedMilliseconds, $genThroughput) -ForegroundColor Green
Write-Host "  Arquivo liberado na dropzone — evento FileSystemWatcher sera disparado."

# ── [4/6] Aguardar watcher processar ──────────────────────────────────────────
Write-Host "`n[4/6] Aguardando processamento pelo Watcher (max 300s)..." -ForegroundColor Yellow
$swWait   = [System.Diagnostics.Stopwatch]::StartNew()
$timeoutS = 300
$concluido = $false

while ($swWait.Elapsed.TotalSeconds -lt $timeoutS) {
    Start-Sleep -Seconds 2

    # Ler novas linhas do log e exibir
    $todasLinhas = Get-Content -LiteralPath $LogFile -ErrorAction SilentlyContinue
    if ($todasLinhas -and $todasLinhas.Count -gt $linhasVistas) {
        $novas = $todasLinhas[$linhasVistas..($todasLinhas.Count - 1)]
        foreach ($ln in $novas) {
            $cor = if ($ln -match '\[ERROR\]') { 'Red' } `
                   elseif ($ln -match '\[MMAP\]') { 'Magenta' } `
                   elseif ($ln -match '\[WARN\]')  { 'Yellow' } `
                   else { 'DarkCyan' }
            Write-Host "  $ln" -ForegroundColor $cor
        }
        $linhasVistas = $todasLinhas.Count
    }

    # Verificar conclusao: semente criada + arquivo no cofre
    if ((Test-Path -LiteralPath $SeedFilePath) -and (Test-Path -LiteralPath $CofredFilePath)) {
        $concluido = $true
        break
    }

    # Verificar falha do job
    if ($job.State -eq 'Failed') {
        Write-Host "`n  [FALHA] Job watcher falhou." -ForegroundColor Red
        Receive-Job -Job $job | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        break
    }
}

$swWait.Stop()

# Flushar restante do log
$todasLinhas = Get-Content -LiteralPath $LogFile -ErrorAction SilentlyContinue
if ($todasLinhas -and $todasLinhas.Count -gt $linhasVistas) {
    $todasLinhas[$linhasVistas..($todasLinhas.Count - 1)] | ForEach-Object {
        Write-Host "  $_" -ForegroundColor DarkCyan
    }
}

# ── [5/6] Parar Watcher ───────────────────────────────────────────────────────
Write-Host "`n[5/6] Parando Watcher..." -ForegroundColor Yellow
Stop-Job  -Job $job -ErrorAction SilentlyContinue
Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
Write-Host "  Watcher parado."

# ── [6/6] Resultado final ─────────────────────────────────────────────────────
Write-Host "`n[6/6] Resultado final..." -ForegroundColor Yellow

if (-not $concluido) {
    Write-Host "`n  [TIMEOUT] Watcher nao concluiu em ${timeoutS}s." -ForegroundColor Red
    exit 1
}

$srref = Get-Content -LiteralPath $SeedFilePath -Raw | ConvertFrom-Json

$DeltaRamEconomia = [double]$srref.delta_ram_economia_mb
$DeltaTamVsSeed   = [Math]::Round($sizeReal / 1KB - 1, 0)   # tamanho do arquivo vs ~1KB de seed
$DeltaTempoTotal  = $swWait.ElapsedMilliseconds

Write-Host ''
Write-Host '======================================================================' -ForegroundColor Cyan
Write-Host ' RESULTADO — TEIA DROPZONE UNIVERSAL (Motor Mmap + Watcher)'          -ForegroundColor Cyan
Write-Host '======================================================================'
Write-Host ''
Write-Host ' [ARQUIVO DE TESTE]'
Write-Host ("  Nome              : $TestFileName")
Write-Host ("  Tamanho           : {0:F4} GB ({1} bytes)" -f ($sizeReal/1GB), $sizeReal)
Write-Host ("  Geracao           : {0} ms ({1:F0} MB/s)" -f $swGen.ElapsedMilliseconds, $genThroughput)
Write-Host ''
Write-Host ' [INGESTAO MMAP]'
Write-Host ("  SHA-256           : $($srref.sha256)")
Write-Host ("  Chunks processados: $($srref.chunks_processados) x $($srref.chunk_mb) MB")
Write-Host ("  Throughput mmap   : {0:F1} MB/s" -f $srref.throughput_mbs)
Write-Host ("  Elapsed mmap      : {0:F2}s" -f $srref.elapsed_s)
Write-Host ''
Write-Host ' [RAM — PROVA MMAP]'
Write-Host ("  RSS inicial       : {0:F1} MB" -f $srref.rss_inicial_mb)
Write-Host ("  Pico RSS (mmap)   : {0:F1} MB (para arquivo de {1:F0} MB)" -f `
    $srref.pico_rss_mb, ($sizeReal/1MB))
Write-Host ("  Delta RAM economizado : {0:F0} MB ({1:F1}x menor que carga total)" -f `
    $DeltaRamEconomia, ($sizeReal/1MB / $srref.pico_rss_mb))
Write-Host ''
Write-Host ' [PIPELINE]'
Write-Host ("  Semente SR-REF    : $SeedFilePath")
Write-Host ("  Original no cofre : $CofredFilePath")
Write-Host ("  Delta tempo total (deteccao + mmap + cofre): $DeltaTempoTotal ms")
Write-Host ''
Write-Host ' [AUDITORIA]'
Write-Host ("  SR-REF versao     : $($srref.v)")
Write-Host ("  Gerado em         : $($srref.gerado_em)")
Write-Host ("  Watcher atuou     : SIM — arquivo movido para cofre automaticamente")
Write-Host ''
Write-Host '======================================================================'

$sizeRSSOk = $srref.pico_rss_mb -lt ($sizeReal / 1MB * 0.5)   # pico < 50% do arquivo
$seedOk    = Test-Path -LiteralPath $SeedFilePath
$cofreOk   = Test-Path -LiteralPath $CofredFilePath

if ($seedOk -and $cofreOk -and $sizeRSSOk) {
    Write-Host ' [APROVADO] Pipeline Dropzone → Mmap → Seeds → Cofre validado.' -ForegroundColor Green
    Write-Host ' Delta RAM: pico RSS marginal vs tamanho do arquivo.'            -ForegroundColor Green
    Write-Host ' FileSystemWatcher detectou, roteou, processou e arquivou.'     -ForegroundColor Green
    Write-Host ' [VEREDICTO] MOTOR DE INGESTAO UNIVERSAL OPERACIONAL.'          -ForegroundColor Green
} else {
    if (-not $seedOk)  { Write-Host " [FALHA] SR-REF nao encontrada: $SeedFilePath"  -ForegroundColor Red }
    if (-not $cofreOk) { Write-Host " [FALHA] Original nao no cofre: $CofredFilePath" -ForegroundColor Red }
    if (-not $sizeRSSOk) { Write-Host (" [AVISO] Pico RSS ({0:F0}MB) alto para arquivo de {1:F0}MB" -f `
        $srref.pico_rss_mb, ($sizeReal/1MB)) -ForegroundColor Yellow }
    exit 1
}
Write-Host '======================================================================'
Write-Host ''
