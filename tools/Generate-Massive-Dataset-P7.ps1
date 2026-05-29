<#
.SYNOPSIS
    Generate-Massive-Dataset-P7.ps1 — Gerador de Dataset Sintético P7.0 (250 arquivos)

.DESCRIPTION
    Popula D:\TEIA_USER\ActiveDrive_ScaleTest\ com 250 arquivos distribuídos em
    três categorias, cada uma exercendo uma rota diferente do roteador hard-rule:

      50  model/obj  (25 cubos + 25 planos)  → HR6  gen.parametric_mesh
     100  texto estruturado (60 JSON + 40 log) → LLM_FALLBACK  cmp.lzma
     100  binário alta entropia               → HR3  cas.raw

    Geração determinística via System.Random(seed=42).
    Bytes aleatórios de alta entropia via RandomNumberGenerator (criptográfico).

.PARAMETER OutputDir
    Destino. Padrão: D:\TEIA_USER\ActiveDrive_ScaleTest
#>
[CmdletBinding()]
param(
    [string]$OutputDir = 'D:\TEIA_USER\ActiveDrive_ScaleTest'
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$enc = New-Object System.Text.UTF8Encoding($false)
$IC  = [System.Globalization.CultureInfo]::InvariantCulture
$sw  = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host ''
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host '  Generate-Massive-Dataset P7.0 — Sintropia em Escala (250 arquivos)' -ForegroundColor Cyan
Write-Host ('─' * 78)
Write-Host ("  Destino  : $OutputDir")
Write-Host ("  Semente  : System.Random(42) — geração determinística")
Write-Host ('=' * 78)
Write-Host ''

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$rnd = [System.Random]::new(42)
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()

$nOBJ   = 0
$nText  = 0
$nBin   = 0
$totalB = [long]0

function F4([double]$v) { $v.ToString('F4', $IC) }

# ── FASE A: 25 cubos OBJ (HR6 → gen.parametric_mesh) ─────────────────────────

Write-Host '  [A] Gerando 25 cubos OBJ...' -ForegroundColor Yellow

for ($i = 1; $i -le 25; $i++) {
    $W  = [math]::Round($rnd.NextDouble() * 4.0 + 0.5, 4)
    $H  = [math]::Round($rnd.NextDouble() * 4.0 + 0.5, 4)
    $D  = [math]::Round($rnd.NextDouble() * 4.0 + 0.5, 4)
    $hw = $W / 2; $hh = $H / 2; $hd = $D / 2
    $n  = '{0:D3}' -f $i

    $content = @"
# cube_$n.obj — TEIA P7.0 ScaleTest  W=$(F4 $W) H=$(F4 $H) D=$(F4 $D)
o cube_$n
v $(F4(-$hw)) $(F4(-$hh)) $(F4(-$hd))
v $(F4  $hw)  $(F4(-$hh)) $(F4(-$hd))
v $(F4  $hw)  $(F4  $hh)  $(F4(-$hd))
v $(F4(-$hw)) $(F4  $hh)  $(F4(-$hd))
v $(F4(-$hw)) $(F4(-$hh)) $(F4  $hd)
v $(F4  $hw)  $(F4(-$hh)) $(F4  $hd)
v $(F4  $hw)  $(F4  $hh)  $(F4  $hd)
v $(F4(-$hw)) $(F4  $hh)  $(F4  $hd)
f 1 2 3 4
f 5 6 7 8
f 1 2 6 5
f 2 3 7 6
f 3 4 8 7
f 4 1 5 8
"@
    $path = Join-Path $OutputDir "cube_$n.obj"
    [System.IO.File]::WriteAllText($path, $content, $enc)
    $totalB += (Get-Item -LiteralPath $path).Length
    $nOBJ++
}

# ── FASE B: 25 planos OBJ (HR6 → gen.parametric_mesh) ────────────────────────

Write-Host '  [B] Gerando 25 planos OBJ...' -ForegroundColor Yellow

for ($i = 1; $i -le 25; $i++) {
    $W  = [math]::Round($rnd.NextDouble() * 6.0 + 0.5, 4)
    $D  = [math]::Round($rnd.NextDouble() * 6.0 + 0.5, 4)
    $hw = $W / 2; $hd = $D / 2
    $n  = '{0:D3}' -f $i

    $content = @"
# plane_$n.obj — TEIA P7.0 ScaleTest  W=$(F4 $W) D=$(F4 $D)
o plane_$n
v $(F4(-$hw)) 0.0000 $(F4(-$hd))
v $(F4  $hw)  0.0000 $(F4(-$hd))
v $(F4  $hw)  0.0000 $(F4  $hd)
v $(F4(-$hw)) 0.0000 $(F4  $hd)
f 1 2 3 4
"@
    $path = Join-Path $OutputDir "plane_$n.obj"
    [System.IO.File]::WriteAllText($path, $content, $enc)
    $totalB += (Get-Item -LiteralPath $path).Length
    $nOBJ++
}

# ── FASE C: 60 JSON estruturado (LLM_FALLBACK → cmp.lzma) ────────────────────

Write-Host '  [C] Gerando 60 JSON estruturados (>8 KB → cmp.lzma)...' -ForegroundColor Yellow

for ($i = 1; $i -le 60; $i++) {
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('{')
    [void]$sb.AppendLine('  "dataset": "teia_p7_scaletest",')
    $fi = $i.ToString()
    [void]$sb.AppendLine("  `"file_index`": $fi,")
    [void]$sb.AppendLine('  "generated_by": "Generate-Massive-Dataset-P7.ps1",')
    [void]$sb.AppendLine('  "records": [')
    for ($r = 1; $r -le 300; $r++) {
        $score  = [math]::Round($rnd.NextDouble() * 100.0, 2).ToString($IC)
        $lat    = $rnd.Next(1, 999)
        $wn     = '{0:D3}' -f ($r % 16 + 1)
        $tn     = '{0:D3}' -f ($r % 20)
        $comma  = if ($r -lt 300) { ',' } else { '' }
        $rs     = $r.ToString()
        $lats   = $lat.ToString()
        $jline  = "    {`"id`":$rs,`"file`":$fi,`"worker`":`"worker_$wn`",`"score`":$score,`"latency_ms`":$lats,`"status`":`"ok`",`"tag`":`"tag_$tn`"}$comma"
        [void]$sb.AppendLine($jline)
    }
    [void]$sb.AppendLine('  ]')
    [void]$sb.AppendLine('}')

    $n    = '{0:D3}' -f $i
    $path = Join-Path $OutputDir "data_json_$n.json"
    [System.IO.File]::WriteAllText($path, $sb.ToString(), $enc)
    $totalB += (Get-Item -LiteralPath $path).Length
    $nText++
}

# ── FASE D: 40 logs de sistema (LLM_FALLBACK → cmp.lzma) ─────────────────────

Write-Host '  [D] Gerando 40 syslogs estruturados (>8 KB → cmp.lzma)...' -ForegroundColor Yellow

$levels  = @('INFO','INFO','INFO','WARN','ERROR','DEBUG')
$workers = @('api-01','api-02','worker-01','worker-02','db-01','cache-01')

for ($i = 1; $i -le 40; $i++) {
    $sb = [System.Text.StringBuilder]::new()
    $fi = $i.ToString()
    [void]$sb.AppendLine("# TEIA P7.0 ScaleTest syslog file $fi — gerado deterministicamente")
    for ($line = 1; $line -le 250; $line++) {
        $lvl    = $levels[$line % 6]
        $worker = $workers[$line % 6]
        $jn     = '{0:D6}' -f ($i * 1000 + $line)
        $lat    = $rnd.Next(1, 499)
        $seq    = $i * 10000 + $line
        $h      = '{0:D2}' -f ($line % 24)
        $m      = '{0:D2}' -f ($line % 60)
        $s      = '{0:D2}' -f (($line * 3) % 60)
        $ms     = '{0:D3}' -f (($seq * 7) % 1000)
        $lats   = $lat.ToString()
        $seqs   = $seq.ToString()
        $lline  = "2026-05-29T${h}:${m}:${s}.${ms}Z $lvl [$worker] job=$jn status=running latency=${lats}ms seq=$seqs retries=0"
        [void]$sb.AppendLine($lline)
    }

    $n    = '{0:D3}' -f $i
    $path = Join-Path $OutputDir "syslog_$n.log"
    [System.IO.File]::WriteAllText($path, $sb.ToString(), $enc)
    $totalB += (Get-Item -LiteralPath $path).Length
    $nText++
}

# ── FASE E: 100 binários alta entropia (HR3 → cas.raw) ───────────────────────

Write-Host '  [E] Gerando 100 blobs binários alta entropia (HR3 → cas.raw)...' -ForegroundColor Yellow

for ($i = 1; $i -le 100; $i++) {
    $size  = 16384 + $rnd.Next(0, 8193)
    $bytes = New-Object byte[] $size
    $rng.GetBytes($bytes)
    $n    = '{0:D3}' -f $i
    $path = Join-Path $OutputDir "blob_$n.bin"
    [System.IO.File]::WriteAllBytes($path, $bytes)
    $totalB += $size
    $nBin++
}

$rng.Dispose()
$sw.Stop()

# ── Relatório ─────────────────────────────────────────────────────────────────

$totalKB = [math]::Round($totalB / 1KB, 1)
$totalMB = [math]::Round($totalB / 1MB, 3)

Write-Host ''
Write-Host ('─' * 78)
Write-Host '  SUMARIO DE GERACAO' -ForegroundColor Cyan
Write-Host ("  OBJ parametricos : $nOBJ   arquivos  (HR6 → gen.parametric_mesh)")
Write-Host ("  Texto estruturado: $nText  arquivos  (LLM_FALLBACK → cmp.lzma)")
Write-Host ("  Binario entropia : $nBin  arquivos  (HR3 → cas.raw)")
Write-Host ("  TOTAL            : $($nOBJ + $nText + $nBin)  arquivos")
Write-Host ("  Volume total     : $totalKB KB  ($totalMB MB)")
Write-Host ("  Tempo            : $($sw.ElapsedMilliseconds) ms")
Write-Host ("  Destino          : $OutputDir")
Write-Host ('─' * 78)
Write-Host ''
Write-Host '  Estrategias esperadas no Ingestor:'
Write-Host ("    gen.parametric_mesh : $nOBJ  arquivos")
Write-Host ("    cmp.lzma            : $nText  arquivos")
Write-Host ("    cas.raw             : $nBin  arquivos")
Write-Host ('=' * 78)
