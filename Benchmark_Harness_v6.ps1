#Requires -Version 7
# Benchmark_Harness_v6.ps1
# TEIA v0.8.1 — Estrategia por Bucket: dict-small / dict-medium / zstd.raw
# Buckets: tiny(<5KB)=zstd.raw | small(5-100KB)=dict-small | medium(100-500KB)=dict-medium | large(>=500KB)=zstd.raw
# Corpus: D4_REAL_MANIFEST.json R1-R46 (skip R47-R50 xlarge)
# dict-small: treino em 10 Google API docs do agents_v2 env (nao presentes no D4)
# dict-medium: reutiliza 6c72ae... de _bench_v4/dicts (treino em R21,R22,R25,R27,R28,R32,R34,R36)
# Saida: Relatorio_Comparativo_v6.0.0.md

$ErrorActionPreference = 'Continue'
Set-Location "D:\TEIA_CLAUDE_AWAKENING"

# ── Caminhos e configuracao ────────────────────────────────────────────────────
$MOTOR_PATH  = "D:\TEIA_CLAUDE_AWAKENING\Arqueologia do motor AION RISPA\NúcleoCompressorOntoprocedural\Ontologia Procedural\Motor onto procedural\TEIA-Core-v0.8.1.psm1"
$SEVENZIP    = "C:\Program Files\7-Zip\7z.exe"
$ZSTD        = "D:\TEIA_CLAUDE_AWAKENING\_tools\zstd\zstd-v1.5.6-win64\zstd.exe"
$MANIFEST    = "D:\TEIA_CLAUDE_AWAKENING\D4_REAL_MANIFEST.json"
$BENCH_DIR   = "D:\TEIA_CLAUDE_AWAKENING\_bench_v6"
$DICT_DIR    = "$BENCH_DIR\dicts"
$TMP_DIR     = "$BENCH_DIR\tmp"
$REPORT_PATH = "D:\TEIA_CLAUDE_AWAKENING\Relatorio_Comparativo_v6.0.0.md"

# dict-medium: ja treinado na v4 — reutilizar
$DICT_MEDIUM_SHA  = "6c72ae7246b413b8b635078167da4d5786276435fea3cd140326197744562d8a"
$DICT_MEDIUM_SRC  = "D:\TEIA_CLAUDE_AWAKENING\_bench_v4\dicts\$DICT_MEDIUM_SHA.zstd-dict"

# Limiares de bucket
$TINY_MAX   = 5000
$SMALL_MAX  = 100000
$MEDIUM_MAX = 500000

# IDs de treino (dict-medium treinado em subconjunto de medium)
$TRAIN_IDS_MEDIUM = @("R21","R22","R25","R27","R28","R32","R34","R36")
# dict-small: treino externo — TODOS R7-R20 sao clean test

# ── Setup diretorios ───────────────────────────────────────────────────────────
foreach ($d in @($BENCH_DIR,$DICT_DIR,$TMP_DIR)) {
    [IO.Directory]::CreateDirectory($d) | Out-Null
}

# Verificacoes pre-voo
if (-not (Test-Path $SEVENZIP)) { throw "7z.exe nao encontrado: $SEVENZIP" }
if (-not (Test-Path $ZSTD))     { throw "zstd.exe nao encontrado: $ZSTD" }
if (-not (Test-Path $MANIFEST)) { throw "Manifest nao encontrado: $MANIFEST" }
if (-not (Test-Path $MOTOR_PATH)) { throw "Motor v0.8.1 nao encontrado: $MOTOR_PATH" }
if (-not (Test-Path $DICT_MEDIUM_SRC)) { throw "dict-medium nao encontrado: $DICT_MEDIUM_SRC" }

# ── Importar motor ─────────────────────────────────────────────────────────────
Write-Host "[V6] Importando motor v0.8.1..."
Import-Module $MOTOR_PATH -Force

# ── Copiar dict-medium para bench_v6/dicts ────────────────────────────────────
$DICT_MEDIUM_PATH = "$DICT_DIR\$DICT_MEDIUM_SHA.zstd-dict"
if (-not (Test-Path $DICT_MEDIUM_PATH)) {
    Copy-Item $DICT_MEDIUM_SRC $DICT_MEDIUM_PATH
    Write-Host "[V6] dict-medium copiado: $($DICT_MEDIUM_SHA.Substring(0,16))..."
} else {
    Write-Host "[V6] dict-medium ja presente: $($DICT_MEDIUM_SHA.Substring(0,16))..."
}

# ── Treinar dict-small ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[V6] === TREINANDO dict-small ==="
$SMALL_TRAIN_DIR  = "D:\bruto\TEIA\Miniconda\envs\agents_v2\Lib\site-packages\googleapiclient\discovery_cache\documents"
$SMALL_TRAIN_FILES = @(
    "advisorynotifications.v1.json",
    "apikeys.v2.json",
    "baremetalsolution.v1alpha1.json",
    "blogger.v2.json",
    "businessprofileperformance.v1.json",
    "chromeuxreport.v1.json",
    "cloudshell.v1.json",
    "cloudtrace.v2.json",
    "dfareporting.v3.5.json",
    "discovery.v1.json"
) | ForEach-Object { Join-Path $SMALL_TRAIN_DIR $_ }

$dictSmallResult   = Build-TEIAZstdDict -TrainingFiles $SMALL_TRAIN_FILES -OutputDir $DICT_DIR -MaxDictBytes 65536 -ZstdPath $ZSTD
$DICT_SMALL_SHA    = $dictSmallResult.DictSha256
$DICT_SMALL_PATH   = $dictSmallResult.DictPath
$DICT_SMALL_BYTES  = $dictSmallResult.DictBytes
Write-Host "[V6] dict-small SHA: $($DICT_SMALL_SHA.Substring(0,16))... | $DICT_SMALL_BYTES bytes | $($dictSmallResult.TrainMs)ms"

# Verify dict-medium integrity
$medBytes   = [IO.File]::ReadAllBytes($DICT_MEDIUM_PATH)
$medActSha  = [TEIA.Native.TEIANativeV81]::SHA256Hex($medBytes)
if ($medActSha -ne $DICT_MEDIUM_SHA) { throw "dict-medium SHA-256 mismatch: $medActSha" }
Write-Host "[V6] dict-medium SHA verificado: $($DICT_MEDIUM_SHA.Substring(0,16))... | $($medBytes.Length) bytes"

# ── Carregar manifest ──────────────────────────────────────────────────────────
$manifest = Get-Content $MANIFEST -Raw | ConvertFrom-Json
$allFiles = $manifest.files | Where-Object { $_.id -match '^R([0-9]+)$' -and [int]($_.id -replace 'R','') -le 46 }
Write-Host ""
Write-Host "[V6] Corpus: $($allFiles.Count) arquivos (R1-R46)"

# ── Funcoes auxiliares ─────────────────────────────────────────────────────────
function Get-Bucket([long]$sz) {
    if ($sz -lt $TINY_MAX)   { return "tiny" }
    if ($sz -lt $SMALL_MAX)  { return "small" }
    if ($sz -lt $MEDIUM_MAX) { return "medium" }
    return "large"
}

function Compress-LZMA([byte[]]$data, [string]$tmpDir) {
    # Write data to local temp (bypasses WOFWIM/WIM mounts that block 7z directly)
    $tmpIn  = Join-Path $tmpDir ("lzma_in_"  + [IO.Path]::GetRandomFileName() + ".bin")
    $out    = Join-Path $tmpDir ("lzma_out_" + [IO.Path]::GetRandomFileName() + ".7z")
    $outLog = Join-Path $tmpDir ("lzma_log_" + [IO.Path]::GetRandomFileName() + ".log")
    try {
        [IO.File]::WriteAllBytes($tmpIn, $data)
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $p  = Start-Process -FilePath $SEVENZIP `
                -ArgumentList @("a","-t7z","-mx9","-mmt1","-m0=LZMA","-mf=off","-bso0","-bsp0","-bse0",$out,$tmpIn) `
                -PassThru -NoNewWindow -RedirectStandardError $outLog
        $done = $p.WaitForExit(90000)   # 90s timeout
        $sw.Stop()
        if (-not $done) { $p.Kill(); throw "7z LZMA timeout >90s" }
        if ($p.ExitCode -ne 0) { throw "7z LZMA failed exit=$($p.ExitCode)" }
        if (-not (Test-Path $out)) { throw "7z LZMA: output nao criado" }
        $sz = (Get-Item $out).Length
        return [pscustomobject]@{ Bytes=$sz; Ms=$sw.ElapsedMilliseconds }
    } finally {
        if (Test-Path $tmpIn)  { Remove-Item $tmpIn  -Force -ErrorAction SilentlyContinue }
        if (Test-Path $out)    { Remove-Item $out    -Force -ErrorAction SilentlyContinue }
        if (Test-Path $outLog) { Remove-Item $outLog -Force -ErrorAction SilentlyContinue }
    }
}

function Compress-ZstdRaw([byte[]]$data, [string]$tmpPath) {
    $sw  = [Diagnostics.Stopwatch]::StartNew()
    $cmp = [TEIA.Native.TEIANativeV81]::CompressWithZstd($data, $ZSTD, "", 19)
    $sw.Stop()
    return [pscustomobject]@{ Bytes=$cmp.Length; Ms=$sw.ElapsedMilliseconds; Data=$cmp }
}

function Compress-ZstdDict([byte[]]$data, [string]$dictPath) {
    $sw  = [Diagnostics.Stopwatch]::StartNew()
    $cmp = [TEIA.Native.TEIANativeV81]::CompressWithZstd($data, $ZSTD, $dictPath, 19)
    $sw.Stop()
    return [pscustomobject]@{ Bytes=$cmp.Length; Ms=$sw.ElapsedMilliseconds; Data=$cmp }
}

# ── Loop principal ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host ("=" * 90)
Write-Host "  ID    BUCKET    ORIG     A:LZMA    B:Zstd    C:Best    D:TEIA    Ganha  SHA"
Write-Host ("=" * 90)

$results = [System.Collections.ArrayList]::new()
$errList = [System.Collections.ArrayList]::new()

foreach ($entry in $allFiles) {
    $fid    = $entry.id
    $fpath  = $entry.path
    $fname  = $entry.name
    $expSha = $entry.sha256
    $origSz = $entry.size_bytes

    $isMediumTrain = $fid -in $TRAIN_IDS_MEDIUM
    $bucket        = Get-Bucket $origSz
    $trainMark     = if ($isMediumTrain) { "[T]" } else { "   " }

    try {
        if (-not (Test-Path $fpath -ErrorAction SilentlyContinue)) {
            [void]$errList.Add("$fid SKIP (arquivo ausente): $fpath")
            Write-Host "  ${fid}  SKIP  (arquivo ausente)"
            continue
        }
        # Verifica SHA-256 original
        $fileSha = (Get-FileHash $fpath -Algorithm SHA256).Hash.ToLower()
        if ($fileSha -ne $expSha) {
            throw "SHA-256 diverge do manifest: $fileSha != $expSha"
        }

        $data = [IO.File]::ReadAllBytes($fpath)

        # ── A: LZMA ───────────────────────────────────────────────────────────
        $resA = Compress-LZMA $data $TMP_DIR

        # ── B: Zstd raw ───────────────────────────────────────────────────────
        $resB = Compress-ZstdRaw $data $TMP_DIR

        # ── C e D: depende do bucket ──────────────────────────────────────────
        $resC_Bytes = 0
        $resC_Ms    = 0
        $resD_Bytes = 0
        $resD_Ms    = 0
        $overheadD  = 0
        $sha256OK   = $false
        $writeReadOK = $false
        $opUsed     = ""
        $dictUsed   = ""

        switch ($bucket) {
            "tiny" {
                # tiny: sem dict, zstd.raw
                $resC_Bytes = $resB.Bytes
                $resC_Ms    = 0
                $opUsed     = "zstd.raw"
                $dictUsed   = "-"

                $encD = Invoke-TEIAEncodeRaw -Data $data -FileName $fname -ZstdPath $ZSTD
                $savePath = Join-Path $TMP_DIR ("${fid}_tiny.teia")
                $saveR    = Save-TEIABin -TeiaBytes $encD.TeiaBytes -OutPath $savePath
                $writeReadOK = $saveR.WriteOk

                $teiaRaw   = [IO.File]::ReadAllBytes($savePath)
                $restoredD = Invoke-TEIARestoreBin -TeiaBytes $teiaRaw -DictDir "" -ZstdPath $ZSTD
                $sha256OK  = ([TEIA.Native.TEIANativeV81]::SHA256Hex($restoredD) -eq $expSha)
                Remove-Item $savePath -Force

                $resD_Bytes = $encD.TeiaSize
                $resD_Ms    = $encD.EncodeMs
                $overheadD  = $encD.OverheadBytes
            }
            "small" {
                # small: dict-small
                $resC_raw   = Compress-ZstdDict $data $DICT_SMALL_PATH
                $resC_Bytes = $resC_raw.Bytes
                $resC_Ms    = $resC_raw.Ms
                $opUsed     = "dict.zstd_shared"
                $dictUsed   = "small"

                $encD = Invoke-TEIAEncodeBin -Data $data -DictPath $DICT_SMALL_PATH -FileName $fname -ZstdPath $ZSTD
                $savePath = Join-Path $TMP_DIR ("${fid}_small.teia")
                $saveR    = Save-TEIABin -TeiaBytes $encD.TeiaBytes -OutPath $savePath
                $writeReadOK = $saveR.WriteOk

                $teiaRaw   = [IO.File]::ReadAllBytes($savePath)
                $restoredD = Invoke-TEIARestoreBin -TeiaBytes $teiaRaw -DictDir $DICT_DIR -ZstdPath $ZSTD
                $sha256OK  = ([TEIA.Native.TEIANativeV81]::SHA256Hex($restoredD) -eq $expSha)
                Remove-Item $savePath -Force

                $resD_Bytes = $encD.TeiaSize
                $resD_Ms    = $encD.EncodeMs
                $overheadD  = $encD.OverheadBytes
            }
            "medium" {
                # medium: dict-medium
                $resC_raw   = Compress-ZstdDict $data $DICT_MEDIUM_PATH
                $resC_Bytes = $resC_raw.Bytes
                $resC_Ms    = $resC_raw.Ms
                $opUsed     = "dict.zstd_shared"
                $dictUsed   = "medium"

                $encD = Invoke-TEIAEncodeBin -Data $data -DictPath $DICT_MEDIUM_PATH -FileName $fname -ZstdPath $ZSTD
                $savePath = Join-Path $TMP_DIR ("${fid}_med.teia")
                $saveR    = Save-TEIABin -TeiaBytes $encD.TeiaBytes -OutPath $savePath
                $writeReadOK = $saveR.WriteOk

                $teiaRaw   = [IO.File]::ReadAllBytes($savePath)
                $restoredD = Invoke-TEIARestoreBin -TeiaBytes $teiaRaw -DictDir $DICT_DIR -ZstdPath $ZSTD
                $sha256OK  = ([TEIA.Native.TEIANativeV81]::SHA256Hex($restoredD) -eq $expSha)
                Remove-Item $savePath -Force

                $resD_Bytes = $encD.TeiaSize
                $resD_Ms    = $encD.EncodeMs
                $overheadD  = $encD.OverheadBytes
            }
            "large" {
                # large: sem dict, zstd.raw
                $resC_Bytes = $resB.Bytes
                $resC_Ms    = 0
                $opUsed     = "zstd.raw"
                $dictUsed   = "-"

                $encD = Invoke-TEIAEncodeRaw -Data $data -FileName $fname -ZstdPath $ZSTD
                $savePath = Join-Path $TMP_DIR ("${fid}_large.teia")
                $saveR    = Save-TEIABin -TeiaBytes $encD.TeiaBytes -OutPath $savePath
                $writeReadOK = $saveR.WriteOk

                $teiaRaw   = [IO.File]::ReadAllBytes($savePath)
                $restoredD = Invoke-TEIARestoreBin -TeiaBytes $teiaRaw -DictDir "" -ZstdPath $ZSTD
                $sha256OK  = ([TEIA.Native.TEIANativeV81]::SHA256Hex($restoredD) -eq $expSha)
                Remove-Item $savePath -Force

                $resD_Bytes = $encD.TeiaSize
                $resD_Ms    = $encD.EncodeMs
                $overheadD  = $encD.OverheadBytes
            }
        }

        $deltaDA = $resA.Bytes - $resD_Bytes      # >0 = TEIA ganha
        $deltaDC = $resD_Bytes - $resC_Bytes      # overhead TEIA vs raw
        $pctA    = [math]::Round($resA.Bytes    / $origSz * 100, 2)
        $pctB    = [math]::Round($resB.Bytes    / $origSz * 100, 2)
        $pctC    = [math]::Round($resC_Bytes    / $origSz * 100, 2)
        $pctD    = [math]::Round($resD_Bytes    / $origSz * 100, 2)
        $ganhou  = if ($deltaDA -gt 0) { "SIM" } else { "NAO" }
        $shaStr  = if ($sha256OK) { "OK" } else { "FAIL" }
        $wrStr   = if ($writeReadOK) { "OK" } else { "FAIL" }

        $row = [pscustomobject]@{
            ID          = $fid
            Name        = $fname
            Bucket      = $bucket
            Op          = $opUsed
            Dict        = $dictUsed
            IsTrain     = $isMediumTrain
            OrigBytes   = $origSz
            A_Bytes     = $resA.Bytes
            A_Pct       = $pctA
            B_Bytes     = $resB.Bytes
            B_Pct       = $pctB
            C_Bytes     = $resC_Bytes
            C_Pct       = $pctC
            D_Bytes     = $resD_Bytes
            D_Pct       = $pctD
            Overhead    = $overheadD
            Delta_DA    = $deltaDA
            Delta_DC    = $deltaDC
            Ganha       = $ganhou
            SHA256_OK   = $sha256OK
            WriteRead   = $wrStr
            A_Ms        = $resA.Ms
            B_Ms        = $resB.Ms
            D_Ms        = $resD_Ms
        }
        [void]$results.Add($row)

        $trainStr = if ($isMediumTrain) { "T" } else { " " }
        Write-Host ("  {0,-5} {1} {2,-6} {3,8}B  {4,7}B({5}%)  {6,7}B({7}%)  {8,7}B({9}%)  {10,7}B({11}%)  {12,3}  {13}" -f `
            $fid, $trainStr, $bucket.ToUpper(), $origSz, `
            $resA.Bytes, $pctA, $resB.Bytes, $pctB, `
            $resC_Bytes, $pctC, $resD_Bytes, $pctD, `
            $ganhou, $shaStr)

    } catch {
        $msg = "ERRO em ${fid}: $_"
        [void]$errList.Add($msg)
        Write-Warning $msg
    }
}

Write-Host ("=" * 90)

# ── Estatisticas por bucket ────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== SUMARIO POR BUCKET ==="

$bucketOrder = @("tiny","small","medium","large")
$bucketStats = @{}

foreach ($bkt in $bucketOrder) {
    $grp = @($results | Where-Object { $_.Bucket -eq $bkt })
    if ($grp.Count -eq 0) { continue }

    $wins      = @($grp | Where-Object { $_.Ganha -eq "SIM" }).Count
    $total     = $grp.Count
    $sha256all = ($grp | Where-Object { $_.SHA256_OK -eq $false }).Count -eq 0
    $avgA      = [math]::Round(($grp | Measure-Object -Property A_Pct -Average).Average, 2)
    $avgD      = [math]::Round(($grp | Measure-Object -Property D_Pct -Average).Average, 2)
    $avgOvhd   = [math]::Round(($grp | Measure-Object -Property Overhead -Average).Average, 0)
    $sumSavings = ($grp | Measure-Object -Property Delta_DA -Sum).Sum

    $bucketStats[$bkt] = [pscustomobject]@{
        Bucket     = $bkt
        Count      = $total
        Wins       = $wins
        LossOrDraw = ($total - $wins)
        AvgA_Pct   = $avgA
        AvgD_Pct   = $avgD
        AvgOvhd    = $avgOvhd
        SHA256All  = $sha256all
        SumSavings = $sumSavings
    }

    $shaStr2 = if ($sha256all) { "100% OK" } else { "FALHOU" }
    Write-Host ("  {0,-6}: {1}/{2} TEIA ganha | A={3}% D={4}% avg | overhead={5}B avg | SHA-256={6}" -f `
        $bkt.ToUpper(), $wins, $total, $avgA, $avgD, $avgOvhd, $shaStr2)
}

$totalWins   = ($results | Where-Object { $_.Ganha -eq "SIM" }).Count
$totalAll    = $results.Count
$totalErrors = $errList.Count
Write-Host ""
Write-Host "[V6] Total: ${totalWins}/${totalAll} TEIA ganha | $totalErrors erros"

if ($errList.Count -gt 0) {
    Write-Host "[V6] Erros:"
    $errList | ForEach-Object { Write-Host "  $_" }
}

# ── Gerar relatorio markdown ───────────────────────────────────────────────────
Write-Host ""
Write-Host "[V6] Gerando relatorio..."

$timestamp = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$motorSha  = (Get-FileHash $MOTOR_PATH -Algorithm SHA256).Hash.ToLower()
$motorSz   = (Get-Item $MOTOR_PATH).Length

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# Relatorio Comparativo v6.0.0 — TEIA Estrategia por Bucket")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("> **Gerado**: $timestamp")
[void]$sb.AppendLine("> **Motor**: TEIA-Core-v0.8.1.psm1 | SHA-256: $motorSha | $motorSz bytes")
[void]$sb.AppendLine("> **Hardware**: i3-10100F, 16GB RAM, HDD")
[void]$sb.AppendLine("> **Corpus**: D4_REAL_MANIFEST.json R1-R46 ($totalAll arquivos processados)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Estrategia por Bucket")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Bucket | Limiar | Opcode TEIA | Dicionario |")
[void]$sb.AppendLine("|--------|--------|-------------|------------|")
[void]$sb.AppendLine("| tiny | < 5 KB | zstd.raw | nenhum |")
[void]$sb.AppendLine("| small | 5 KB - 100 KB | dict.zstd_shared | dict-small (64KB, 10 Google API docs) |")
[void]$sb.AppendLine("| medium | 100 KB - 500 KB | dict.zstd_shared | dict-medium (110KB, 8 botocore service-2) |")
[void]$sb.AppendLine("| large | >= 500 KB | zstd.raw | nenhum |")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Dicionarios")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Nome | SHA-256 | Bytes | Corpus de Treino |")
[void]$sb.AppendLine("|------|---------|-------|-----------------|")
[void]$sb.AppendLine("| dict-small | $DICT_SMALL_SHA | $DICT_SMALL_BYTES | 10 Google API discovery docs (agents_v2 env, nao presentes no D4) |")
[void]$sb.AppendLine("| dict-medium | $DICT_MEDIUM_SHA | $($medBytes.Length) | 8 botocore service-2.json ~200KB (R21,R22,R25,R27,R28,R32,R34,R36) [T] |")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("**Separacao treino/teste:**")
[void]$sb.AppendLine("- dict-small: treino em dados externos (nao presentes no D4) -> R7-R20 sao clean test")
[void]$sb.AppendLine("- dict-medium: R21,R22,R25,R27,R28,R32,R34,R36 marcados [T] (dados de treino)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Resultados por Arquivo")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| ID | T | Bucket | Original | A:LZMA | B:Zstd | C:Best-raw | D:TEIA | Overhead D-C | D-A | SHA | W=R |")
[void]$sb.AppendLine("|----|---|--------|----------|--------|--------|------------|--------|-------------|-----|-----|-----|")

foreach ($r in $results) {
    $tMark  = if ($r.IsTrain) { "T" } else { "" }
    $dAStr  = if ($r.Delta_DA -gt 0) { "-$($r.Delta_DA)B" } else { "+$([math]::Abs($r.Delta_DA))B" }
    $shaOK  = if ($r.SHA256_OK)  { "OK" } else { "FAIL" }
    $wrStr2 = $r.WriteRead
    [void]$sb.AppendLine("| $($r.ID) | $tMark | $($r.Bucket) | $($r.OrigBytes)B | $($r.A_Bytes)B ($($r.A_Pct)%) | $($r.B_Bytes)B ($($r.B_Pct)%) | $($r.C_Bytes)B ($($r.C_Pct)%) | $($r.D_Bytes)B ($($r.D_Pct)%) | $($r.Overhead)B | $dAStr | $shaOK | $wrStr2 |")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Sumario por Bucket")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Bucket | Count | Wins | Losses | Avg A% | Avg D% | Avg Overhead | SHA-256 | Savings liquido |")
[void]$sb.AppendLine("|--------|-------|------|--------|--------|--------|--------------|---------|-----------------|")

foreach ($bkt in $bucketOrder) {
    if (-not $bucketStats.ContainsKey($bkt)) { continue }
    $bs     = $bucketStats[$bkt]
    $shaAll = if ($bs.SHA256All) { "100% OK" } else { "FALHOU" }
    [void]$sb.AppendLine("| $($bs.Bucket) | $($bs.Count) | $($bs.Wins) | $($bs.LossOrDraw) | $($bs.AvgA_Pct)% | $($bs.AvgD_Pct)% | $($bs.AvgOvhd)B | $shaAll | $($bs.SumSavings)B |")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("**Total**: ${totalWins}/${totalAll} TEIA ganha | $totalErrors erros")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")

# Analise por bucket
[void]$sb.AppendLine("## Analise por Bucket")
[void]$sb.AppendLine("")

if ($bucketStats.ContainsKey("tiny")) {
    $bs = $bucketStats["tiny"]
    [void]$sb.AppendLine("### Tiny (<5KB)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Container overhead (272B) representa ~13% do arquivo original.")
    [void]$sb.AppendLine("TEIA nao e competitivo neste bucket — overhead estrutural domina.")
    [void]$sb.AppendLine("Ganhos: $($bs.Wins)/$($bs.Count) — esperado 0 (overhead > savings).")
    [void]$sb.AppendLine("")
}

if ($bucketStats.ContainsKey("small")) {
    $bs = $bucketStats["small"]
    [void]$sb.AppendLine("### Small (5KB-100KB)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("dict-small treinado em 10 Google API docs (~20KB, dominio externo ao D4).")
    [void]$sb.AppendLine("Todos os arquivos small (R7-R20) sao clean test — sem contaminacao de treino.")
    [void]$sb.AppendLine("Ganhos: $($bs.Wins)/$($bs.Count) | Avg LZMA=$($bs.AvgA_Pct)% -> TEIA=$($bs.AvgD_Pct)%")
    [void]$sb.AppendLine("")
}

if ($bucketStats.ContainsKey("medium")) {
    $bs = $bucketStats["medium"]
    [void]$sb.AppendLine("### Medium (100KB-500KB)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("dict-medium reutilizado de v5.0.0 (6c72ae..., 80KB, botocore service-2).")
    [void]$sb.AppendLine("R21,R22,R25,R27,R28,R32,R34,R36 marcados [T] (dados de treino).")
    [void]$sb.AppendLine("Ganhos: $($bs.Wins)/$($bs.Count) | Avg LZMA=$($bs.AvgA_Pct)% -> TEIA=$($bs.AvgD_Pct)%")
    [void]$sb.AppendLine("")
}

if ($bucketStats.ContainsKey("large")) {
    $bs = $bucketStats["large"]
    [void]$sb.AppendLine("### Large (>=500KB)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Zstd.raw: sem dicionario (dict treinado em ~200KB arquivos prejudica grandes arquivos).")
    [void]$sb.AppendLine("Anti-pattern confirmado em v5-Full: dict-medium adicionava ~18KB em sagemaker (1.8MB).")
    [void]$sb.AppendLine("Ganhos: $($bs.Wins)/$($bs.Count) | Avg LZMA=$($bs.AvgA_Pct)% -> TEIA=$($bs.AvgD_Pct)%")
    [void]$sb.AppendLine("")
}

[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Comparativo v5-Full vs v6")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Aspecto | v5-Full (dict universal) | v6 (por bucket) |")
[void]$sb.AppendLine("|---------|--------------------------|-----------------|")
[void]$sb.AppendLine("| Dict estrategia | um dict-medium universal | dict-small / dict-medium / zstd.raw |")
[void]$sb.AppendLine("| Large files | dict-medium (PREJUDICA) | zstd.raw (sem dict) |")
[void]$sb.AppendLine("| Small files | dict-medium (cross-domain) | dict-small (dominio proximo) |")
[void]$sb.AppendLine("| Wins total (v5-Full) | 24/46 | ${totalWins}/${totalAll} |")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Erros ($totalErrors)")
[void]$sb.AppendLine("")

if ($errList.Count -gt 0) {
    foreach ($e in $errList) { [void]$sb.AppendLine("- $e") }
} else {
    [void]$sb.AppendLine("Nenhum erro.")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("*TEIA-Core v0.8.1 | Harness v6.0.0 | Felippe Barcelos | $timestamp*")

$report = $sb.ToString()
# UTF-8 sem BOM para que GetBytes() e ReadAllBytes() produzam os mesmos bytes
$utf8NoBom = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($REPORT_PATH, $report, $utf8NoBom)

# Write==Read relatorio
$repBytes    = [IO.File]::ReadAllBytes($REPORT_PATH)
$repWriteSha = [TEIA.Native.TEIANativeV81]::SHA256Hex($utf8NoBom.GetBytes($report))
$repReadSha  = [TEIA.Native.TEIANativeV81]::SHA256Hex($repBytes)
if ($repWriteSha -ne $repReadSha) { throw "Relatorio Write==Read FAIL" }

$repSha = (Get-FileHash $REPORT_PATH -Algorithm SHA256).Hash.ToLower()
Write-Host "[V6] Relatorio gerado: $REPORT_PATH"
Write-Host "[V6] SHA-256 relatorio: $repSha"
Write-Host "[V6] Tamanho relatorio: $($repBytes.Length) bytes"

# SHA motor
Write-Host ""
Write-Host "[V6] Motor SHA-256: $motorSha"
Write-Host "[V6] Motor tamanho: $motorSz bytes"
Write-Host "[V6] dict-small SHA: $DICT_SMALL_SHA"
Write-Host "[V6] dict-medium SHA: $DICT_MEDIUM_SHA"
Write-Host ""
Write-Host "[V6] === HARNESS v6.0.0 CONCLUIDO ==="
