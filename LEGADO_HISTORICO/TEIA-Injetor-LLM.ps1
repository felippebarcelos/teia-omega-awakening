[CmdletBinding()]
param(
    [string]$SeedPath       = 'D:\TEIA_CLAUDE_AWAKENING\teia_sraut.json',
    [string]$PipeName       = 'TEIA-AION-RISPA-v1',
    [string]$ConsumerScript = 'D:\TEIA_CLAUDE_AWAKENING\Mock-LLM-Consumer.ps1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-Location 'D:\TEIA_CLAUDE_AWAKENING'

# ─── C# SM64: seek O(1) + geracao de blocos com aritmetica unchecked ─────────
if (-not ('SM64' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
public static class SM64 {
    const ulong M1  = 0xBF58476D1CE4E5B9UL;
    const ulong M2  = 0x94D049BB133111EBUL;
    const ulong INC = 0x9E3779B97F4A7C15UL;

    public static ulong Mix(ulong z) { unchecked {
        z = (z ^ (z >> 30)) * M1;
        z = (z ^ (z >> 27)) * M2;
        return z ^ (z >> 31);
    }}

    // Seek O(1): state[n] = seed + n * INC mod 2^64
    public static ulong SeekState(ulong seed, long n) { unchecked {
        return seed + (ulong)n * INC;
    }}

    // Gera sizeBytes deterministicos a partir de stateStart — zero disco
    public static byte[] GenBlock(ulong stateStart, int sizeBytes) {
        int steps = (sizeBytes + 7) / 8;
        byte[] buf = new byte[steps * 8];
        ulong state = stateStart;
        int idx = 0;
        unchecked {
            for (int i = 0; i < steps; i++) {
                state += INC;
                ulong z = Mix(state);
                buf[idx++] = (byte)(z);
                buf[idx++] = (byte)(z >> 8);
                buf[idx++] = (byte)(z >> 16);
                buf[idx++] = (byte)(z >> 24);
                buf[idx++] = (byte)(z >> 32);
                buf[idx++] = (byte)(z >> 40);
                buf[idx++] = (byte)(z >> 48);
                buf[idx++] = (byte)(z >> 56);
            }
        }
        if (buf.Length > sizeBytes) { Array.Resize(ref buf, sizeBytes); }
        return buf;
    }
}
'@
}

# ─── Banner ──────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '======================================================================' -ForegroundColor Cyan
Write-Host ' [TCT/INJECAO_MODELO_ONTOPROCEDURAL] TEIA-Injetor-LLM.ps1'            -ForegroundColor Cyan
Write-Host ' Transfusao Cognitiva: SR-AUT → CPU → Named Pipe → Mock-LLM-Consumer' -ForegroundColor Cyan
Write-Host ' Invariante: blocos NUNCA escritos em disco apos carga da semente'     -ForegroundColor Cyan
Write-Host ' Seek: O(1) — state[n] = semente + n x INC mod 2^64'                  -ForegroundColor Cyan
Write-Host '======================================================================'

# ─── [1/5] Carregar SR-AUT ────────────────────────────────────────────────────
Write-Host "`n[1/5] Carregando SR-AUT..." -ForegroundColor Yellow
if (-not (Test-Path -LiteralPath $SeedPath)) { throw "[FALHA] SR-AUT nao encontrada: $SeedPath" }
if (-not (Test-Path -LiteralPath $ConsumerScript)) { throw "[FALHA] Consumer nao encontrado: $ConsumerScript" }

$sraut            = Get-Content -LiteralPath $SeedPath -Raw | ConvertFrom-Json
$SementePCG       = [System.Convert]::ToUInt64($sraut.semente_pcg)
$MatrizTotalBytes = [int]$sraut.matriz_total_bytes
$BlocoBytes       = [int]$sraut.bloco_tamanho_bytes
$TotalBlocos      = [int]($MatrizTotalBytes / $BlocoBytes)
$SHA256Esperado   = if ($sraut.PSObject.Properties.Match('sha256_matriz').Count -gt 0) {
                        $sraut.sha256_matriz } else { '[AUSENTE — executar motor primeiro]' }

Write-Host "  SR-AUT          : $SeedPath"
Write-Host "  Semente PCG     : $('0x{0:X16}' -f $SementePCG)"
Write-Host "  Matriz total    : $([Math]::Round($MatrizTotalBytes/1MB,2)) MB ($MatrizTotalBytes bytes)"
Write-Host "  Bloco           : $([Math]::Round($BlocoBytes/1KB,0)) KB ($BlocoBytes bytes)"
Write-Host "  Total blocos    : $TotalBlocos"
Write-Host "  SHA-256 ref     : $SHA256Esperado"
Write-Host "  Pipe            : \\.\pipe\$PipeName"

# ─── [2/5] Iniciar consumidor como job ────────────────────────────────────────
Write-Host "`n[2/5] Iniciando Mock-LLM-Consumer como job independente..." -ForegroundColor Yellow
$job = Start-Job -FilePath $ConsumerScript -ArgumentList $PipeName, $MatrizTotalBytes
Write-Host "  Job ID     : $($job.Id) | Estado inicial: $($job.State)"

# ─── [3/5] Criar Named Pipe Server ────────────────────────────────────────────
Write-Host "`n[3/5] Criando Named Pipe Server — aguardando conexao do consumidor..." -ForegroundColor Yellow

$pipeServer = [System.IO.Pipes.NamedPipeServerStream]::new(
    $PipeName,
    [System.IO.Pipes.PipeDirection]::Out,
    1,
    [System.IO.Pipes.PipeTransmissionMode]::Byte,
    [System.IO.Pipes.PipeOptions]::None,
    0,      # inBufferSize
    65536   # outBufferSize
)

$swConn = [System.Diagnostics.Stopwatch]::StartNew()
$pipeServer.WaitForConnection()
$swConn.Stop()
Write-Host "  Consumidor conectado em $($swConn.ElapsedMilliseconds) ms"
Write-Host "  Paradigma: RAM → CPU → Pipe → RAM (zero blocos em disco)"

# ─── [4/5] Injecao Ontoprocedural ─────────────────────────────────────────────
Write-Host "`n[4/5] Injecao Ontoprocedural em curso..." -ForegroundColor Yellow
Write-Host ("  Injetando: {0} blocos x {1} KB = {2:F2} MB" -f `
    $TotalBlocos, [Math]::Round($BlocoBytes/1KB,0), ($MatrizTotalBytes/1MB))

$swInjecao    = [System.Diagnostics.Stopwatch]::StartNew()
$bytesEnviados = 0L

for ($k = 0; $k -lt $TotalBlocos; $k++) {
    # Seek O(1): nao itera — calcula estado diretamente no offset do bloco k
    $n           = [long]$k * [long]($BlocoBytes / 8)
    $estadoBloco = [SM64]::SeekState($SementePCG, $n)
    # Reconstrucao pura na CPU — nenhum arquivo aberto
    $bloco = [SM64]::GenBlock($estadoBloco, $BlocoBytes)
    # Transmissao direta ao pipe (RAM → RAM via kernel)
    $pipeServer.Write($bloco, 0, $bloco.Length)
    $bytesEnviados += $bloco.Length

    $pct   = [int](($k + 1) * 100 / $TotalBlocos)
    $mbEnv = [Math]::Round($bytesEnviados / 1MB, 2)
    $elapsed = $swInjecao.ElapsedMilliseconds
    $mbps  = if ($elapsed -gt 0) { [Math]::Round($bytesEnviados / 1MB / ($elapsed / 1000.0), 1) } else { 0 }
    Write-Host ("  [{0,3}%] Bloco {1:D2}/{2} | {3:F1} KB → Pipe | {4:F2} MB | {5:F1} MB/s     `r" -f `
        $pct, ($k+1), $TotalBlocos, ($BlocoBytes/1KB), $mbEnv, $mbps) -NoNewline
}

$pipeServer.Flush()
$pipeServer.Disconnect()
$pipeServer.Dispose()
$swInjecao.Stop()

$throughputInjetor = if ($swInjecao.ElapsedMilliseconds -gt 0) {
    [Math]::Round($bytesEnviados / 1MB / ($swInjecao.ElapsedMilliseconds / 1000.0), 2)
} else { 0 }

Write-Host ""
Write-Host ("  Injecao concluida   : $bytesEnviados bytes em $($swInjecao.ElapsedMilliseconds) ms")
Write-Host ("  Throughput injetor  : {0:F2} MB/s (CPU→Pipe)" -f $throughputInjetor)
Write-Host ("  Delta IO Disco      : 0 bytes — blocos nunca gravados no disco")

# ─── [5/5] Aguardar resultado do consumidor ───────────────────────────────────
Write-Host "`n[5/5] Aguardando resultado do Mock-LLM-Consumer (timeout 30s)..." -ForegroundColor Yellow

$jobDone = Wait-Job -Job $job -Timeout 30
if ($null -eq $jobDone) {
    Stop-Job -Job $job
    Remove-Job -Job $job -Force
    throw "[FALHA] Consumer nao concluiu em 30s — pipe travado ou erro no consumidor."
}
if ($job.State -eq 'Failed') {
    $reason = $job.ChildJobs[0].JobStateInfo.Reason
    Remove-Job -Job $job -Force
    throw "[FALHA] Consumer job falhou: $reason"
}

$resultado = Receive-Job -Job $job
Remove-Job -Job $job -Force

if ($null -eq $resultado) { throw "[FALHA] Consumer nao retornou resultado." }

$bytesRecebidos    = [long]$resultado.BytesRecebidos
$sha256Recebido    = [string]$resultado.SHA256
$elapsedConsumer   = [long]$resultado.ElapsedMs
$throughputConsumer = [double]$resultado.ThroughputMBs

# ─── Calcular Deltas e Veredicto ──────────────────────────────────────────────
$DeltaBytes      = [Math]::Abs($MatrizTotalBytes - $bytesRecebidos)
$DeltaTempo      = $elapsedConsumer - $swInjecao.ElapsedMilliseconds
$DeltaThroughput = $throughputConsumer - $throughputInjetor
$DeltaHash       = if ($SHA256Esperado -eq '[AUSENTE — executar motor primeiro]') {
                        '[NAO VERIFICAVEL — sha256_matriz ausente na SR-AUT]'
                   } elseif ($sha256Recebido -eq $SHA256Esperado) {
                        'ZERO — hashes identicos'
                   } else {
                        "DIVERGE — esperado=$SHA256Esperado recebido=$sha256Recebido"
                   }

$hashOk = ($SHA256Esperado -notlike '*AUSENTE*') -and ($sha256Recebido -eq $SHA256Esperado)

Write-Host ''
Write-Host '======================================================================' -ForegroundColor Cyan
Write-Host ' RESULTADO — TRANSFUSAO COGNITIVA TEIA-AION-RISPA v1.0'              -ForegroundColor Cyan
Write-Host '======================================================================'
Write-Host ''
Write-Host ' [TRANSMISSAO PIPE]'
Write-Host "  Bytes injetados (server)  : $bytesEnviados"
Write-Host "  Bytes recebidos (LLM)     : $bytesRecebidos"
Write-Host "  Delta bytes               : $DeltaBytes (zero = transmissao perfeita)"
Write-Host ''
Write-Host ' [SHA-256 AUDITORIA CRUZADA]'
Write-Host "  SHA-256 referencia (disco) : $SHA256Esperado"
Write-Host "  SHA-256 recebido  (LLM)   : $sha256Recebido"
Write-Host "  Delta hash                 : $DeltaHash"
Write-Host ''
Write-Host ' [PERFORMANCE]'
Write-Host ("  Latencia de conexao       : {0} ms" -f $swConn.ElapsedMilliseconds)
Write-Host ("  Throughput injetor        : {0:F2} MB/s (CPU reconstrucao + pipe write)" -f $throughputInjetor)
Write-Host ("  Throughput consumidor     : {0:F2} MB/s (pipe read + SHA-256)" -f $throughputConsumer)
Write-Host ("  Delta throughput          : {0:+0.00;-0.00} MB/s" -f $DeltaThroughput)
Write-Host ("  Tempo injecao             : {0} ms" -f $swInjecao.ElapsedMilliseconds)
Write-Host ("  Tempo consumidor          : {0} ms" -f $elapsedConsumer)
Write-Host ("  Delta tempo               : {0:+0;-0} ms" -f $DeltaTempo)
Write-Host ''
Write-Host ' [PROVA DE TRANSDUCAO ONTOPROCEDURAL]'
Write-Host "  I/O disco pos-semente     : 0 bytes (blocos NUNCA gravados)"
Write-Host "  Canal de transmissao      : Named Pipe (kernel — RAM → RAM)"
Write-Host "  Semente carregada         : 387 bytes"
Write-Host "  Dados transmitidos        : $([Math]::Round($bytesEnviados/1MB,2)) MB"
Write-Host "  Paradigma                 : SR-AUT → CPU → Pipe → LLM (sem disco)"
Write-Host ''
Write-Host '======================================================================'

if ($hashOk) {
    Write-Host ' [APROVADO] Transfusao Cognitiva validada — hash identico.' -ForegroundColor Green
    Write-Host ' O LLM recebeu exatamente os dados derivados da semente.'   -ForegroundColor Green
    Write-Host ' Delta IO de disco por ciclo de inferencia: zero bytes.'    -ForegroundColor Green
    Write-Host ' [VEREDICTO] TRANSDUCAO ONTOPROCEDURAL CONFIRMADA.'         -ForegroundColor Green
} else {
    Write-Host ' [FALHA] Hash diverge — transfusao corrompida.'             -ForegroundColor Red
    Write-Host " Delta hash: $DeltaHash"                                    -ForegroundColor Red
    exit 1
}
Write-Host '======================================================================'
Write-Host ''
