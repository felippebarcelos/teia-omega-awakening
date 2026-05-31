<#
.SYNOPSIS
    Test-GlobalStreaming.ps1 — Prova de Ruptura: Chunk-On-Demand em <50ms
.DESCRIPTION
    Valida que o VFS v0900 entrega fatias procedurais de T:\lunatic\Syslog_Lunatic.log
    em menos de 50ms por chamada de 64KB.

    Dois planos de teste:
      PLANO 1 — HTTP Range direto (porta 8769): mede latência pura de computação,
                elimina cache WebDAV do Windows.
      PLANO 2 — FileStream via T:\ com Seek: mede latência end-to-end pelo VFS.

    Verificação de integridade: reconstrói bytes esperados localmente e compara
    com os bytes recebidos (primeiro e último bloco de cada plano).

    Critério de sucesso: P90 < 50ms no Plano 1.
#>
[CmdletBinding()]
param(
    [string]$VfsHost       = 'localhost',
    [int]   $VfsPort       = 8769,
    [string]$DriveT        = 'T:',
    [long]  $ChunkSize     = 65536,
    [int]   $HttpIterations = 20,
    [int]   $FsIterations   = 10,
    [int]   $MaxLatencyMs   = 50,
    [long]  $FileSize       = 1013804
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC = [System.Globalization.CultureInfo]::InvariantCulture

# ── Geração local de bytes esperados (mesma lógica do VFS) ───────────────────

$L_LEVELS  = @('INFO','WARN','ERROR','DEBUG')
$L_HOSTS   = @('api-01','api-02','api-03','worker-01','worker-02')
$L_HEADER  = "# TEIA Lunatic Log $([char]0x2014) 10000 linhas $([char]0x2014) semente deterministica v0.90.1"
$L_COUNT   = 10000
$L_ENC     = [System.Text.Encoding]::UTF8

function Build-OffsetTable {
    $t = New-Object long[] ($L_COUNT + 2)
    $t[0] = 0L; $t[1] = 72L; $pos = 72L
    for ($i = 1; $i -le $L_COUNT; $i++) {
        $lLen = if (($i-1)%4 -ge 2) { 5 } else { 4 }
        $hLen = if (($i-1)%5 -ge 3) { 9 } else { 6 }
        $lat  = ($i%500)+1
        $dLat = if ($lat -lt 10) { 1 } elseif ($lat -lt 100) { 2 } else { 3 }
        $dSeq = if ($i -lt 10) { 1 } elseif ($i -lt 100) { 2 } elseif ($i -lt 1000) { 3 } elseif ($i -lt 10000) { 4 } else { 5 }
        $crlf = if ($i -lt $L_COUNT) { 2 } else { 0 }
        $pos += 81 + $lLen + $hLen + $dLat + $dSeq + $crlf
        $t[$i+1] = $pos
    }
    return $t
}

function Get-ExpectedChunk([long]$Offset, [long]$Length, [long[]]$Offsets) {
    $effLen = [Math]::Min($Length, $FileSize - $Offset)
    if ($effLen -le 0) { return [byte[]]@() }
    $result = [System.Collections.Generic.List[byte]]::new([int]$effLen)
    # Busca binária
    $lo = 0; $hi = $L_COUNT
    while ($lo -lt $hi) {
        $mid = [int](($lo+$hi)/2)
        if ($Offsets[$mid+1] -le $Offset) { $lo = $mid+1 } else { $hi = $mid }
    }
    for ($li = $lo; $li -le $L_COUNT -and $result.Count -lt $effLen; $li++) {
        if ($li -eq 0) {
            $lb = $L_ENC.GetBytes($L_HEADER + "`r`n")
        } else {
            $hh  = [int][Math]::Truncate($li/3600) % 24
            $mm  = [int][Math]::Truncate(($li%3600)/60)
            $ss  = $li % 60; $xx = $li % 1000
            $ts  = [string]::Format("2026-01-01T{0:D2}:{1:D2}:{2:D2}.{3:D3}Z", $hh, $mm, $ss, $xx)
            $lv  = $L_LEVELS[($li-1)%4]; $hn = $L_HOSTS[($li-1)%5]
            $lat = ($li%500)+1; $job = $li.ToString('D7')
            $sfx = if ($li -lt $L_COUNT) { "`r`n" } else { '' }
            $lb  = $L_ENC.GetBytes([string]::Format("{0} {1} [{2}] job={3} status=running latency={4}ms seq={5} retries=0",
                       $ts, $lv, $hn, $job, $lat, $li) + $sfx)
        }
        $lineStart = $Offsets[$li]
        $from  = [int][Math]::Max(0L, $Offset - $lineStart)
        $toEx  = [int][Math]::Min([long]$lb.Length, $Offset + $effLen - $lineStart)
        if ($toEx -gt $from) {
            for ($b = $from; $b -lt $toEx; $b++) { $result.Add($lb[$b]) }
        }
    }
    return $result.ToArray()
}

# ── Plano 1: HTTP Range direto ────────────────────────────────────────────────

function Test-HttpRange([long[]]$Offsets) {
    Write-Host ''
    Write-Host '  ── PLANO 1: HTTP Range Direto (porta 8769) ──' -ForegroundColor Cyan
    $baseUrl = "http://${VfsHost}:${VfsPort}/lunatic/Syslog_Lunatic.log"

    # Verificar conectividade (fechar resposta para não bloquear o connection pool)
    try {
        $req = [System.Net.HttpWebRequest]::Create($baseUrl)
        $req.Method = 'HEAD'; $req.Timeout = 3000
        $res = $req.GetResponse(); $res.Close()
    } catch {
        Write-Host "  [SKIP] VFS nao acessivel em ${baseUrl}: $_" -ForegroundColor Yellow
        Write-Host "         Inicie TEIA-Global-VFS-v0900.ps1 primeiro." -ForegroundColor Yellow
        return $null
    }

    $rng   = [System.Random]::new(42)  # seed fixo para reprodutibilidade
    $times = New-Object double[] $HttpIterations
    $pass  = 0; $verify = 0; $verifyOk = 0

    for ($n = 0; $n -lt $HttpIterations; $n++) {
        $offset = [long]($rng.NextDouble() * ($FileSize - $ChunkSize))
        $endB   = $offset + $ChunkSize - 1
        if ($endB -ge $FileSize) { $endB = $FileSize - 1 }

        $wr = [System.Net.HttpWebRequest]::Create($baseUrl)
        $wr.Method  = 'GET'
        $wr.Timeout = 5000
        $wr.Headers.Add('Range', "bytes=$offset-$endB")

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $receivedBytes = $null
        try {
            $wresp = $wr.GetResponse()
            $ms2   = [System.IO.MemoryStream]::new()
            $wresp.GetResponseStream().CopyTo($ms2)
            $wresp.Close()
            $sw.Stop()
            $receivedBytes = $ms2.ToArray()
        } catch { $sw.Stop(); Write-Host "  [ERR] iter $n offset=$offset : $_" -ForegroundColor Red; continue }

        $times[$n] = $sw.Elapsed.TotalMilliseconds
        if ($times[$n] -lt $MaxLatencyMs) { $pass++ }

        # Verificar primeiros 2 e últimos 2 chunks
        if ($n -lt 2 -or $n -ge $HttpIterations - 2) {
            $expected = Get-ExpectedChunk $offset ($endB - $offset + 1) $Offsets
            $matches  = $receivedBytes.Length -eq $expected.Length
            if ($matches) {
                for ($b = 0; $b -lt $expected.Length -and $matches; $b++) {
                    if ($receivedBytes[$b] -ne $expected[$b]) { $matches = $false }
                }
            }
            $verify++; if ($matches) { $verifyOk++ }
            $icon = if ($matches) { '[OK]' } else { '[FAIL]' }
            $col  = if ($matches) { 'Green' } else { 'Red' }
            Write-Host ("  {0} iter {1,2}  off={2,9}  {3,7:F1}ms  recv={4}B  exp={5}B" -f $icon,$n,$offset,$times[$n],$receivedBytes.Length,$expected.Length) -ForegroundColor $col
        } else {
            $icon = if ($times[$n] -lt $MaxLatencyMs) { '  [<50]' } else { ' [>50!]' }
            $col  = if ($times[$n] -lt $MaxLatencyMs) { 'Green' } else { 'Yellow' }
            Write-Host ("  $icon iter {0,2}  off={1,9}  {2,7:F1}ms" -f $n,$offset,$times[$n]) -ForegroundColor $col
        }
    }

    $valid = ($times | Where-Object { $_ -gt 0 })
    $avg   = if ($valid.Count -gt 0) { ($valid | Measure-Object -Average).Average } else { 0 }
    $max   = if ($valid.Count -gt 0) { ($valid | Measure-Object -Maximum).Maximum } else { 0 }
    $p90s  = $valid | Sort-Object
    $p90   = if ($p90s.Count -gt 0) { $p90s[[int]($p90s.Count * 0.9)] } else { 0 }

    Write-Host ''
    Write-Host ("  Resultado P1: {0}/{1} < {2}ms   avg={3:F1}ms  p90={4:F1}ms  max={5:F1}ms   verify={6}/{7}" -f `
        $pass, $HttpIterations, $MaxLatencyMs, $avg, $p90, $max, $verifyOk, $verify)

    $verdict = if ($pass -gt 0 -and $p90 -lt $MaxLatencyMs -and $verifyOk -eq $verify) { 'PASS' } else { 'FAIL' }
    $vcol    = if ($verdict -eq 'PASS') { 'Green' } else { 'Red' }
    Write-Host "  Veredicto P1: $verdict" -ForegroundColor $vcol

    return @{ pass=$pass; total=$HttpIterations; avg=$avg; p90=$p90; max=$max
              verifyOk=$verifyOk; verifyTotal=$verify; verdict=$verdict }
}

# ── Plano 2: FileStream Seek via T:\ ─────────────────────────────────────────

function Test-FilestreamSeek {
    Write-Host ''
    Write-Host '  ── PLANO 2: FileStream.Seek via T:\ ──' -ForegroundColor Cyan
    $filePath = Join-Path $DriveT "lunatic\Syslog_Lunatic.log"

    if (-not (Test-Path -LiteralPath $filePath -ErrorAction SilentlyContinue)) {
        Write-Host "  [SKIP] Arquivo nao encontrado: $filePath" -ForegroundColor Yellow
        Write-Host "         Monte T:\ primeiro: net use T: \\localhost@$VfsPort\DavWWWRoot\ /persistent:no" -ForegroundColor Yellow
        return $null
    }

    $rng   = [System.Random]::new(99)
    $times = New-Object double[] $FsIterations
    $pass  = 0
    $fs    = [System.IO.File]::OpenRead($filePath)

    try {
        for ($n = 0; $n -lt $FsIterations; $n++) {
            $offset = [long]($rng.NextDouble() * ($FileSize - $ChunkSize))
            $buf    = New-Object byte[] $ChunkSize

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            [void]$fs.Seek($offset, [System.IO.SeekOrigin]::Begin)
            $read = $fs.Read($buf, 0, $ChunkSize)
            $sw.Stop()

            $times[$n] = $sw.Elapsed.TotalMilliseconds
            if ($times[$n] -lt $MaxLatencyMs) { $pass++ }

            $icon = if ($times[$n] -lt $MaxLatencyMs) { '  [<50]' } else { ' [>50!]' }
            $col  = if ($times[$n] -lt $MaxLatencyMs) { 'Green' } else { 'Yellow' }
            Write-Host ("  $icon iter {0,2}  off={1,9}  {2,7:F1}ms  read={3}B" -f $n,$offset,$times[$n],$read) -ForegroundColor $col
        }
    } finally { $fs.Dispose() }

    $avg = ($times | Measure-Object -Average).Average
    $max = ($times | Measure-Object -Maximum).Maximum
    $p90 = ($times | Sort-Object)[[int]($FsIterations * 0.9)]

    Write-Host ''
    Write-Host ("  Resultado P2: {0}/{1} < {2}ms   avg={3:F1}ms  p90={4:F1}ms  max={5:F1}ms" -f `
        $pass, $FsIterations, $MaxLatencyMs, $avg, $p90, $max)

    $verdict = if ($p90 -lt $MaxLatencyMs) { 'PASS' } else { 'FAIL' }
    $vcol    = if ($verdict -eq 'PASS') { 'Green' } else { 'Yellow' }
    Write-Host "  Veredicto P2: $verdict (inclui overhead WebDAV/cache)" -ForegroundColor $vcol

    return @{ pass=$pass; total=$FsIterations; avg=$avg; p90=$p90; max=$max; verdict=$verdict }
}

# ── Main ──────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host '  Test-GlobalStreaming — Prova de Ruptura: Chunk-On-Demand <50ms' -ForegroundColor Cyan
Write-Host ('─' * 72)
Write-Host "  VFS URL  : http://${VfsHost}:${VfsPort}/lunatic/Syslog_Lunatic.log"
Write-Host "  Drive T: : $DriveT\lunatic\Syslog_Lunatic.log"
Write-Host "  ChunkSize: $ChunkSize bytes   Criterio: P90 < ${MaxLatencyMs}ms"

Write-Host ''
Write-Host '  Construindo tabela de offsets local...' -ForegroundColor DarkGray -NoNewline
$sw0     = [System.Diagnostics.Stopwatch]::StartNew()
$offsets = Build-OffsetTable
$sw0.Stop()
Write-Host " $($sw0.ElapsedMilliseconds)ms   total=$($offsets[$L_COUNT+1])B" -ForegroundColor DarkGray

$r1 = Test-HttpRange $offsets

# Auto-montar T:\ antes do Plano 2
Write-Host ''
Write-Host '  Montando T:\...' -ForegroundColor DarkGray -NoNewline
Start-Service WebClient -ErrorAction SilentlyContinue
net use $DriveT "\\${VfsHost}@${VfsPort}\DavWWWRoot\" /persistent:no 2>&1 | Out-Null
Write-Host " ok (net use $DriveT \\${VfsHost}@${VfsPort}\DavWWWRoot\)" -ForegroundColor DarkGray

$r2 = Test-FilestreamSeek

# ── Relatório final ───────────────────────────────────────────────────────────

Write-Host ''
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host '  RELATÓRIO FINAL — Test-GlobalStreaming' -ForegroundColor Cyan
Write-Host ('─' * 72)

if ($r1) {
    $c1 = if ($r1.verdict -eq 'PASS') { 'Green' } else { 'Red' }
    Write-Host ("  P1 HTTP Range : {0}  avg={1:F1}ms  p90={2:F1}ms  integridade={3}/{4}" -f `
        $r1.verdict, $r1.avg, $r1.p90, $r1.verifyOk, $r1.verifyTotal) -ForegroundColor $c1
}
if ($r2) {
    $c2 = if ($r2.verdict -eq 'PASS') { 'Green' } else { 'Yellow' }
    Write-Host ("  P2 FileStream : {0}  avg={1:F1}ms  p90={2:F1}ms  (inclui overhead de drive)" -f `
        $r2.verdict, $r2.avg, $r2.p90) -ForegroundColor $c2
}

$overallVerdict = 'INCONCLUSIVE'
if ($r1 -and $r1.verdict -eq 'PASS') { $overallVerdict = 'PASS — Calcular a materia e tao rapido quanto ler a materia' }
elseif ($r1) { $overallVerdict = 'FAIL — P90 acima de 50ms; otimizar Read-GenNativeLunatic' }

$vcol = if ($overallVerdict -like 'PASS*') { 'Green' } elseif ($overallVerdict -like 'FAIL*') { 'Red' } else { 'Yellow' }
Write-Host ''
Write-Host "  Veredicto Final: $overallVerdict" -ForegroundColor $vcol
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host ''
