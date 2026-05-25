#Requires -Version 7
# Benchmark_Harness_v12.ps1
# TEIA v0.11.0 — Regressao D7: confirmar 105/105 com motor que adicionou cmp.lzma
# Corpus: D7_REAL_MANIFEST.json (105 arquivos — mesmo de v7/v8/v9, apples-to-apples)
# Motor: TEIA-Core-v0.11.0.psm1 (classe TEIANativeV110)
# Dicts: dict-small (Google API JSON) + dict-medium (botocore) — mesmos do v9
# Probe sets v0.11.0:
#   tiny:   {cmp.zstd}
#   small:  {cmp.zstd, cmp.lzma, dict-small}
#   medium: {cmp.lzma, dict-medium, cmp.zstd}
#   large:  {cmp.lzma, cmp.xz, zstd.raw}
# Esperado: 105/105 — dict domina small/medium (botocore/Google API), cmp.lzma nao deve vencer
# Saida: Relatorio_Comparativo_v12.0.0.md

$ErrorActionPreference = 'Continue'
Set-Location "D:\TEIA_CLAUDE_AWAKENING"

# ── Caminhos ─────────────────────────────────────────────────────────────────────
$MOTOR_PATH  = "D:\TEIA_CLAUDE_AWAKENING\Arqueologia do motor AION RISPA\NúcleoCompressorOntoprocedural\Ontologia Procedural\Motor onto procedural\TEIA-Core-v0.11.0.psm1"
$SEVENZIP    = "C:\Program Files\7-Zip\7z.exe"
$ZSTD        = "D:\TEIA_CLAUDE_AWAKENING\_tools\zstd\zstd-v1.5.6-win64\zstd.exe"
$PYTHON      = "D:\bruto\TEIA\TEIA_ATLAS\Materia_Bruta\D_Drive\TEIA_Data\python\python.exe"
$MANIFEST    = "D:\TEIA_CLAUDE_AWAKENING\D7_REAL_MANIFEST.json"
$BENCH_DIR   = "D:\TEIA_CLAUDE_AWAKENING\_bench_v12"
$DICT_DIR    = "$BENCH_DIR\dicts"
$TMP_DIR     = "$BENCH_DIR\tmp"
$REPORT_PATH = "D:\TEIA_CLAUDE_AWAKENING\Relatorio_Comparativo_v12.0.0.md"

$DICT_MEDIUM_SHA = "6c72ae7246b413b8b635078167da4d5786276435fea3cd140326197744562d8a"
$DICT_MEDIUM_SRC = "D:\TEIA_CLAUDE_AWAKENING\_bench_v6\dicts\$DICT_MEDIUM_SHA.zstd-dict"

$TINY_MAX   = [long]5000
$SMALL_MAX  = [long]100000
$MEDIUM_MAX = [long]500000

# ── Setup ─────────────────────────────────────────────────────────────────────────
foreach ($d in @($BENCH_DIR, $DICT_DIR, $TMP_DIR)) { [IO.Directory]::CreateDirectory($d) | Out-Null }

foreach ($chk in @($SEVENZIP, $ZSTD, $MOTOR_PATH, $MANIFEST, $DICT_MEDIUM_SRC)) {
    if (-not (Test-Path $chk)) { throw "Pre-requisito ausente: $chk" }
}
$hasPython = Test-Path $PYTHON
Write-Host "[V12] Python disponivel: $hasPython ($PYTHON)"

Write-Host "[V12] Importando motor v0.11.0..."
Import-Module $MOTOR_PATH -Force

# ── dict-medium ───────────────────────────────────────────────────────────────────
$DICT_MEDIUM_PATH = "$DICT_DIR\$DICT_MEDIUM_SHA.zstd-dict"
if (-not (Test-Path $DICT_MEDIUM_PATH)) {
    Copy-Item $DICT_MEDIUM_SRC $DICT_MEDIUM_PATH
    Write-Host "[V12] dict-medium copiado: $($DICT_MEDIUM_SHA.Substring(0,16))..."
} else {
    Write-Host "[V12] dict-medium presente: $($DICT_MEDIUM_SHA.Substring(0,16))..."
}
$medBytes  = [IO.File]::ReadAllBytes($DICT_MEDIUM_PATH)
$medActSha = [TEIA.Native.TEIANativeV110]::SHA256Hex($medBytes)
if ($medActSha -ne $DICT_MEDIUM_SHA) { throw "dict-medium SHA mismatch: $medActSha" }
Write-Host "[V12] dict-medium SHA OK: $($DICT_MEDIUM_SHA.Substring(0,16))... | $($medBytes.Length)B"

# ── dict-small ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[V12] === TREINANDO dict-small ==="
$SMALL_TRAIN_DIR   = "D:\bruto\TEIA\Miniconda\envs\agents_v2\Lib\site-packages\googleapiclient\discovery_cache\documents"
$SMALL_TRAIN_FILES = @(
    "advisorynotifications.v1.json","apikeys.v2.json","baremetalsolution.v1alpha1.json",
    "blogger.v2.json","businessprofileperformance.v1.json","chromeuxreport.v1.json",
    "cloudshell.v1.json","cloudtrace.v2.json","dfareporting.v3.5.json","discovery.v1.json"
) | ForEach-Object { Join-Path $SMALL_TRAIN_DIR $_ }

$dictSmall       = Build-TEIAZstdDict -TrainingFiles $SMALL_TRAIN_FILES -OutputDir $DICT_DIR -MaxDictBytes 65536 -ZstdPath $ZSTD
$DICT_SMALL_SHA  = $dictSmall.DictSha256
$DICT_SMALL_PATH = $dictSmall.DictPath
Write-Host "[V12] dict-small: $($DICT_SMALL_SHA.Substring(0,16))... | $($dictSmall.DictBytes)B | $($dictSmall.TrainMs)ms"

# ── Corpus ────────────────────────────────────────────────────────────────────────
$manifest = Get-Content $MANIFEST -Raw | ConvertFrom-Json
$allFiles = @($manifest.files)
$corpusN  = $allFiles.Count
$classif  = if ($corpusN -ge 100) { "Benchmark Robusto" } elseif ($corpusN -ge 10) { "Benchmark Preliminar" } else { "Smoke Test" }
Write-Host ""
Write-Host "[V12] Corpus: $corpusN arquivos — $classif"
Write-Host "[V12] Motor v0.11.0: tiny→{cmp.zstd} | small→{cmp.zstd,cmp.lzma,dict} | medium→{cmp.lzma,dict,cmp.zstd} | large→{cmp.lzma,cmp.xz,zstd.raw}"

# ── Funcoes auxiliares ────────────────────────────────────────────────────────────
function Get-Bucket([long]$sz) {
    if ($sz -lt $TINY_MAX)   { return "tiny" }
    if ($sz -lt $SMALL_MAX)  { return "small" }
    if ($sz -lt $MEDIUM_MAX) { return "medium" }
    return "large"
}

function Get-LossReason([long]$A, [long]$B, [long]$C, [long]$D) {
    if ($D -le $A)                 { return "GANHA" }
    if ($B -ge $A -and $C -ge $A) { return "LZMA_JANELA" }
    if ($C -gt $B)                 { return "DICT_PREJUDICA" }
    return                           "OVERHEAD_CANCELA"
}

function Compress-LZMA([byte[]]$data) {
    $tmpIn  = Join-Path $TMP_DIR ("lzma_in_"  + [IO.Path]::GetRandomFileName() + ".bin")
    $out    = Join-Path $TMP_DIR ("lzma_out_" + [IO.Path]::GetRandomFileName() + ".7z")
    $outLog = Join-Path $TMP_DIR ("lzma_log_" + [IO.Path]::GetRandomFileName() + ".log")
    try {
        [IO.File]::WriteAllBytes($tmpIn, $data)
        $sw  = [Diagnostics.Stopwatch]::StartNew()
        $p   = Start-Process -FilePath $SEVENZIP `
                 -ArgumentList @("a","-t7z","-mx9","-mmt1","-m0=LZMA","-mf=off","-bso0","-bsp0","-bse0",$out,$tmpIn) `
                 -PassThru -NoNewWindow -RedirectStandardError $outLog
        $done = $p.WaitForExit(180000)
        $sw.Stop()
        if (-not $done) { $p.Kill(); throw "7z LZMA timeout >180s" }
        if ($p.ExitCode -ne 0) { throw "7z LZMA failed exit=$($p.ExitCode)" }
        if (-not (Test-Path $out)) { throw "7z LZMA output nao criado" }
        return [pscustomobject]@{ Bytes=(Get-Item $out).Length; Ms=$sw.ElapsedMilliseconds }
    } finally {
        if (Test-Path $tmpIn)  { Remove-Item $tmpIn  -Force -EA SilentlyContinue }
        if (Test-Path $out)    { Remove-Item $out    -Force -EA SilentlyContinue }
        if (Test-Path $outLog) { Remove-Item $outLog -Force -EA SilentlyContinue }
    }
}

function Compress-ZstdRaw([byte[]]$data) {
    $sw  = [Diagnostics.Stopwatch]::StartNew()
    $cmp = [TEIA.Native.TEIANativeV110]::CompressWithZstd($data, $ZSTD, "", 19)
    $sw.Stop()
    return [pscustomobject]@{ Bytes=$cmp.Length; Ms=$sw.ElapsedMilliseconds }
}

function Compress-ZstdDict([byte[]]$data, [string]$dictPath) {
    $sw  = [Diagnostics.Stopwatch]::StartNew()
    $cmp = [TEIA.Native.TEIANativeV110]::CompressWithZstd($data, $ZSTD, $dictPath, 19)
    $sw.Stop()
    return [pscustomobject]@{ Bytes=$cmp.Length; Ms=$sw.ElapsedMilliseconds }
}

function Encode-AndVerify([byte[]]$data, [string]$bucket, [string]$fid, [string]$fname, [string]$expSha) {
    $teiaPath = Join-Path $TMP_DIR "${fid}_v12.teia"
    try {
        $enc = Invoke-TEIAEncodeAuto -Data $data -Bucket $bucket -FileName $fname `
                   -DictSmallPath $DICT_SMALL_PATH -DictMediumPath $DICT_MEDIUM_PATH `
                   -ZstdPath $ZSTD -SevenZipPath $SEVENZIP -PythonPath $PYTHON

        [void](Save-TEIABin -TeiaBytes $enc.TeiaBytes -OutPath $teiaPath)
        $restored = Invoke-TEIARestoreBin -TeiaBytes ([IO.File]::ReadAllBytes($teiaPath)) `
                        -DictDir $DICT_DIR -ZstdPath $ZSTD -SevenZipPath $SEVENZIP -PythonPath $PYTHON
        $shaOK = ([TEIA.Native.TEIANativeV110]::SHA256Hex($restored) -eq $expSha)

        return [pscustomobject]@{
            Bytes=$enc.TeiaSize; OverheadBytes=$enc.OverheadBytes
            Ms=$enc.EncodeMs; SHA256OK=$shaOK
            Op=$enc.Op; ProbeCount=$enc.ProbeCount
            Probes=$enc.Probes
        }
    } finally {
        if (Test-Path $teiaPath) { Remove-Item $teiaPath -Force -EA SilentlyContinue }
    }
}

# ── Loop principal ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host ("=" * 125)
Write-Host ("  {0,-5} {1,-6} {2,9}  {3,10}  {4,10}  {5,10}  {6,10}  {7,3}  {8,-8}  {9,-20}  {10}" -f `
    "ID","BUCKET","ORIG","A:LZMA","B:Zstd","C:Best","D:TEIA","WIN","OPCODE","RAZAO","SHA")
Write-Host ("=" * 125)

$results = [System.Collections.ArrayList]::new()
$errList = [System.Collections.ArrayList]::new()

foreach ($entry in $allFiles) {
    $fid    = $entry.id
    $fpath  = $entry.path
    $fname  = $entry.name
    $expSha = $entry.sha256
    $origSz = [long]$entry.size_bytes
    $bucket = Get-Bucket $origSz

    try {
        if (-not (Test-Path $fpath -EA SilentlyContinue)) {
            [void]$errList.Add("$fid SKIP (ausente): $fpath")
            Write-Host ("  {0,-5} SKIP" -f $fid)
            continue
        }

        $data   = [IO.File]::ReadAllBytes($fpath)
        $actSha = [TEIA.Native.TEIANativeV110]::SHA256Hex($data)
        if ($actSha -ne $expSha) { throw "SHA-256 diverge do manifest: $actSha" }

        # A: LZMA (7z archive, coluna de referencia historica)
        $resA = Compress-LZMA $data

        # B: Zstd raw (baseline Zstd puro)
        $resB = Compress-ZstdRaw $data

        # C: melhor alternativa por bucket para diagnostico
        $resC_Bytes = switch ($bucket) {
            "tiny"   { $resB.Bytes }
            "small"  { (Compress-ZstdDict $data $DICT_SMALL_PATH).Bytes }
            "medium" { (Compress-ZstdDict $data $DICT_MEDIUM_PATH).Bytes }
            "large"  { $resB.Bytes }
        }

        # D: TEIA Selector Engine v0.11.0 — multi-probe, melhor opcode
        $resD = Encode-AndVerify $data $bucket $fid $fname $expSha

        $pctA    = [math]::Round($resA.Bytes / $origSz * 100, 2)
        $pctB    = [math]::Round($resB.Bytes / $origSz * 100, 2)
        $pctC    = [math]::Round($resC_Bytes / $origSz * 100, 2)
        $pctD    = [math]::Round($resD.Bytes / $origSz * 100, 2)
        $deltaDA = $resA.Bytes - $resD.Bytes
        $deltaDC = $resD.Bytes - $resC_Bytes
        $reason  = Get-LossReason $resA.Bytes $resB.Bytes $resC_Bytes $resD.Bytes
        $shaStr  = if ($resD.SHA256OK) { "OK" } else { "FAIL" }
        $opShort = switch ($resD.Op) {
            "zstd.raw"         { "Z.raw"  }
            "dict.zstd_shared" { "Dict"   }
            "xz.raw"           { "X.raw"  }
            "cmp.zstd"         { "C.zst"  }
            "cmp.xz"           { "C.xz"   }
            "cmp.lzma"         { "C.lzma" }
            default            { $resD.Op }
        }

        $row = [pscustomobject]@{
            ID=$fid; Name=$fname; Bucket=$bucket; OrigBytes=$origSz
            A_Bytes=$resA.Bytes; A_Pct=$pctA; A_Ms=$resA.Ms
            B_Bytes=$resB.Bytes; B_Pct=$pctB; B_Ms=$resB.Ms
            C_Bytes=$resC_Bytes; C_Pct=$pctC
            D_Bytes=$resD.Bytes; D_Pct=$pctD; D_Ms=$resD.Ms
            Overhead=$resD.OverheadBytes; Delta_DA=$deltaDA; Delta_DC=$deltaDC
            LossReason=$reason; SHA256OK=$resD.SHA256OK
            Op=$resD.Op; ProbeCount=$resD.ProbeCount
        }
        [void]$results.Add($row)

        Write-Host ("  {0,-5} {1,-6} {2,9}B {3,9}B({4}%) {5,9}B({6}%) {7,9}B({8}%) {9,9}B({10}%) {11,3}  {12,-8}  {13,-20}  {14}" -f `
            $fid, $bucket.ToUpper(), $origSz,
            $resA.Bytes, $pctA, $resB.Bytes, $pctB, $resC_Bytes, $pctC, $resD.Bytes, $pctD,
            $(if ($deltaDA -gt 0){"SIM"}else{"NAO"}),
            $opShort, $reason, $shaStr)

    } catch {
        $msg = "ERRO em ${fid}: $_"
        [void]$errList.Add($msg)
        Write-Warning $msg
    }
}

Write-Host ("=" * 125)

# ── Sumario ───────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== SUMARIO POR BUCKET ==="
$bucketOrder = @("tiny","small","medium","large")
$bucketStats = [ordered]@{}

foreach ($bkt in $bucketOrder) {
    $grp = @($results | Where-Object { $_.Bucket -eq $bkt })
    if ($grp.Count -eq 0) { continue }

    $wins     = @($grp | Where-Object { $_.LossReason -eq "GANHA" }).Count
    $avgA     = [math]::Round(($grp | Measure-Object A_Pct -Average).Average, 2)
    $avgB     = [math]::Round(($grp | Measure-Object B_Pct -Average).Average, 2)
    $avgD     = [math]::Round(($grp | Measure-Object D_Pct -Average).Average, 2)
    $avgOvhd  = [math]::Round(($grp | Measure-Object Overhead -Average).Average, 0)
    $sha256ok = (@($grp | Where-Object { -not $_.SHA256OK }).Count -eq 0)
    $lLJ  = @($grp | Where-Object { $_.LossReason -eq "LZMA_JANELA" }).Count
    $lDP  = @($grp | Where-Object { $_.LossReason -eq "DICT_PREJUDICA" }).Count
    $lOC  = @($grp | Where-Object { $_.LossReason -eq "OVERHEAD_CANCELA" }).Count
    $nZ   = @($grp | Where-Object { $_.Op -eq "zstd.raw" }).Count
    $nD   = @($grp | Where-Object { $_.Op -eq "dict.zstd_shared" }).Count
    $nXR  = @($grp | Where-Object { $_.Op -eq "xz.raw" }).Count
    $nCZ  = @($grp | Where-Object { $_.Op -eq "cmp.zstd" }).Count
    $nCX  = @($grp | Where-Object { $_.Op -eq "cmp.xz" }).Count
    $nCL  = @($grp | Where-Object { $_.Op -eq "cmp.lzma" }).Count

    $bucketStats[$bkt] = [pscustomobject]@{
        Bucket=$bkt; Count=$grp.Count; Wins=$wins
        AvgA=$avgA; AvgB=$avgB; AvgD=$avgD; AvgOvhd=$avgOvhd; SHA256All=$sha256ok
        L_LJ=$lLJ; L_DP=$lDP; L_OC=$lOC
        Op_ZstdRaw=$nZ; Op_Dict=$nD; Op_XzRaw=$nXR; Op_CmpZstd=$nCZ; Op_CmpXz=$nCX; Op_CmpLzma=$nCL
    }

    $shaStr2 = if ($sha256ok) { "100% OK" } else { "FALHOU" }
    Write-Host ("  {0,-6}: {1}/{2} TEIA ganha | A={3}% B={4}% D={5}% | ovhd={6}B | SHA={7}" -f `
        $bkt.ToUpper(), $wins, $grp.Count, $avgA, $avgB, $avgD, $avgOvhd, $shaStr2)
    Write-Host ("          Perdas: LJ={0} DP={1} OC={2} | Opcodes: C.zst={3} C.lzma={4} C.xz={5} Dict={6} Z.raw={7} X.raw={8}" -f `
        $lLJ, $lDP, $lOC, $nCZ, $nCL, $nCX, $nD, $nZ, $nXR)
}

$totalWins    = @($results | Where-Object { $_.LossReason -eq "GANHA" }).Count
$totalAll     = $results.Count
$totalErrors  = $errList.Count
$totalSavings = ($results | Measure-Object Delta_DA -Sum).Sum
$sha256All    = (@($results | Where-Object { -not $_.SHA256OK }).Count -eq 0)

Write-Host ""
Write-Host ("[V12] TOTAL: {0}/{1} TEIA ganha | savings={2}B | {3} erros | {4}" -f `
    $totalWins, $totalAll, $totalSavings, $totalErrors, $classif)
if ($errList.Count -gt 0) { $errList | ForEach-Object { Write-Warning $_ } }

# ── Regressao vs v9 ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== ANALISE DE REGRESSAO (vs v9: 105/105) ==="
$lossCount = $totalAll - $totalWins
if ($lossCount -eq 0) {
    Write-Host "  ZERO REGRESSOES — 105/105 mantido com motor v0.11.0 + cmp.lzma probe"
} else {
    Write-Host "  REGRESSAO DETECTADA: $lossCount perdas"
    @($results | Where-Object { $_.LossReason -ne "GANHA" }) | ForEach-Object {
        Write-Host ("  PERDA: {0} ({1}, {2}B): D-A=+{3}B | razao={4} | op={5}" -f `
            $_.ID, $_.Bucket, $_.OrigBytes, ($_.D_Bytes-$_.A_Bytes), $_.LossReason, $_.Op)
    }
}

$lzmaWins = @($results | Where-Object { $_.Op -eq "cmp.lzma" -and $_.LossReason -eq "GANHA" }).Count
Write-Host "  cmp.lzma selecionado como vencedor: $lzmaWins arquivo(s)"

# ── Relatorio ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[V12] Gerando relatorio..."

$ts   = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$mSha = (Get-FileHash $MOTOR_PATH -Algorithm SHA256).Hash.ToLower()
$mSz  = (Get-Item $MOTOR_PATH).Length

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# Relatorio Comparativo v12.0.0 — Regressao D7 com Motor v0.11.0 ($totalAll arquivos)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("> **Gerado**: $ts")
[void]$sb.AppendLine("> **Motor**: TEIA-Core-v0.11.0.psm1 | SHA-256: $mSha | $mSz bytes")
[void]$sb.AppendLine("> **Corpus**: D7_REAL_MANIFEST.json | $totalAll arquivos | zero overlap D4 | seed=42 (mesmo que v7/v8/v9)")
[void]$sb.AppendLine("> **Classificacao**: $classif")
[void]$sb.AppendLine("> **Python**: $PYTHON | hasPython=$hasPython")
[void]$sb.AppendLine("> **Objetivo**: Confirmar 105/105 sem regressao apos adicao do probe cmp.lzma em small/medium/large")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Motor v0.11.0 — Probe Sets")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Bucket | Opcodes Probados | Selecao |")
[void]$sb.AppendLine("|--------|-----------------|---------|")
[void]$sb.AppendLine("| tiny (<5KB) | cmp.zstd | cmp.zstd (overhead 72B) |")
[void]$sb.AppendLine("| small (5-100KB) | cmp.zstd + cmp.lzma + dict.zstd_shared(dict-small) | min(D) |")
[void]$sb.AppendLine("| medium (100-500KB) | cmp.lzma + dict.zstd_shared(dict-medium) + cmp.zstd | min(D) |")
[void]$sb.AppendLine("| large (>=500KB) | cmp.lzma + cmp.xz + zstd.raw | min(D) |")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("**Expectativa**: dict domina small/medium (botocore/Google API JSON — domain-matched). cmp.lzma adicionado como probe nao deve vencer em corpus D7 (Zstd-dominant files). Regressao = 0.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Resultado de Regressao")
[void]$sb.AppendLine("")
if ($lossCount -eq 0) {
    [void]$sb.AppendLine("**ZERO REGRESSOES — $totalWins/$totalAll TEIA ganha. Motor v0.11.0 compativel com D7.**")
} else {
    [void]$sb.AppendLine("**REGRESSAO: $lossCount perdas detectadas.**")
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Metrica | v9 (v0.10) | v12 (v0.11) | Delta |")
[void]$sb.AppendLine("|---------|-----------|------------|-------|")
[void]$sb.AppendLine("| Wins | 105/105 | $totalWins/$totalAll | $(if($lossCount -eq 0){'0 (OK)'}else{"-$lossCount (REGRESSAO)"}) |")
[void]$sb.AppendLine("| Net savings vs LZMA | 105574B | ${totalSavings}B | $([int]$totalSavings - 105574)B |")
[void]$sb.AppendLine("| SHA-256 | 100% OK | $(if($sha256All){'100% OK'}else{'FALHOU'}) | — |")
[void]$sb.AppendLine("| cmp.lzma selecionado | 0 | $lzmaWins | +$lzmaWins |")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Resultados por Arquivo")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| ID | Nome | Bucket | Orig | A:LZMA | A% | B:Zstd | B% | C:Best | C% | D:TEIA | D% | WIN | OPCODE | RAZAO | SHA |")
[void]$sb.AppendLine("|----|------|--------|------|--------|-----|--------|-----|--------|-----|--------|-----|-----|--------|-------|-----|")

foreach ($r in $results) {
    $win = if ($r.Delta_DA -gt 0) { "SIM" } else { "NAO" }
    $op  = switch ($r.Op) {
        "dict.zstd_shared" { "Dict"   }
        "xz.raw"           { "X.raw"  }
        "cmp.zstd"         { "C.zst"  }
        "cmp.xz"           { "C.xz"   }
        "cmp.lzma"         { "C.lzma" }
        default            { "Z.raw"  }
    }
    $sha = if ($r.SHA256OK) { "OK" } else { "FAIL" }
    [void]$sb.AppendLine("| $($r.ID) | $($r.Name) | $($r.Bucket) | $($r.OrigBytes) | $($r.A_Bytes) | $($r.A_Pct)% | $($r.B_Bytes) | $($r.B_Pct)% | $($r.C_Bytes) | $($r.C_Pct)% | $($r.D_Bytes) | $($r.D_Pct)% | $win | $op | $($r.LossReason) | $sha |")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Sumario por Bucket")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Bucket | N | Wins | A% | B% | D% | Ovhd | LJ | DP | OC | C.zst | C.lzma | C.xz | Dict | Z.raw | X.raw | SHA |")
[void]$sb.AppendLine("|--------|---|------|----|----|----|------|----|----|-----|-------|--------|------|------|-------|-------|-----|")

foreach ($bkt in $bucketOrder) {
    $s = $bucketStats[$bkt]
    if (-not $s) { continue }
    $shaStr3 = if ($s.SHA256All) { "100%OK" } else { "FAIL" }
    [void]$sb.AppendLine("| $($s.Bucket) | $($s.Count) | $($s.Wins)/$($s.Count) | $($s.AvgA)% | $($s.AvgB)% | $($s.AvgD)% | ~$($s.AvgOvhd)B | $($s.L_LJ) | $($s.L_DP) | $($s.L_OC) | $($s.Op_CmpZstd) | $($s.Op_CmpLzma) | $($s.Op_CmpXz) | $($s.Op_Dict) | $($s.Op_ZstdRaw) | $($s.Op_XzRaw) | $shaStr3 |")
}

$totalSha = if ($sha256All) { "100% OK" } else { "FALHOU" }
[void]$sb.AppendLine("| **TOTAL** | **$totalAll** | **$totalWins/$totalAll** | — | — | — | — | — | — | — | — | — | — | — | — | — | **$totalSha** |")

# ── Write==Read ───────────────────────────────────────────────────────────────────
$reportText = $sb.ToString()
$utf8NoBom  = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($REPORT_PATH, $reportText, $utf8NoBom)

$writeSha = [TEIA.Native.TEIANativeV110]::SHA256Hex($utf8NoBom.GetBytes($reportText))
$readBack = [IO.File]::ReadAllBytes($REPORT_PATH)
$readSha  = [TEIA.Native.TEIANativeV110]::SHA256Hex($readBack)
if ($writeSha -ne $readSha) { throw "Write==Read FAIL: write=$writeSha read=$readSha" }

Write-Host ""
Write-Host "[V12] COMPLETO — $REPORT_PATH"
Write-Host "[V12] Relatorio SHA-256: $writeSha"
Write-Host "[V12] $totalWins/$totalAll | savings=${totalSavings}B | SHA-256 $totalSha | $totalErrors erros"
