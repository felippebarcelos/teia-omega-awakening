#Requires -Version 7
# Benchmark_Harness_v7.ps1
# TEIA v0.8.1 — Benchmark Robusto (100+ arquivos)
# Corpus: D7_REAL_MANIFEST.json (zero overlap D4, todos os buckets clean test)
# 4 cenarios: A:LZMA(7z-mx9) | B:Zstd-19-raw | C:Zstd-19+dict | D:TEIA-.teia
# Loss diagnosis: GANHA / LZMA_JANELA / DICT_PREJUDICA / OVERHEAD_CANCELA
# Saida: Relatorio_Comparativo_v7.0.0.md

$ErrorActionPreference = 'Continue'
Set-Location "D:\TEIA_CLAUDE_AWAKENING"

# ── Caminhos ────────────────────────────────────────────────────────────────────
$MOTOR_PATH  = "D:\TEIA_CLAUDE_AWAKENING\Arqueologia do motor AION RISPA\NúcleoCompressorOntoprocedural\Ontologia Procedural\Motor onto procedural\TEIA-Core-v0.8.1.psm1"
$SEVENZIP    = "C:\Program Files\7-Zip\7z.exe"
$ZSTD        = "D:\TEIA_CLAUDE_AWAKENING\_tools\zstd\zstd-v1.5.6-win64\zstd.exe"
$MANIFEST    = "D:\TEIA_CLAUDE_AWAKENING\D7_REAL_MANIFEST.json"
$BENCH_DIR   = "D:\TEIA_CLAUDE_AWAKENING\_bench_v7"
$DICT_DIR    = "$BENCH_DIR\dicts"
$TMP_DIR     = "$BENCH_DIR\tmp"
$REPORT_PATH = "D:\TEIA_CLAUDE_AWAKENING\Relatorio_Comparativo_v7.0.0.md"

# dict-medium: SHA canonico, reutilizado de _bench_v6
$DICT_MEDIUM_SHA = "6c72ae7246b413b8b635078167da4d5786276435fea3cd140326197744562d8a"
$DICT_MEDIUM_SRC = "D:\TEIA_CLAUDE_AWAKENING\_bench_v6\dicts\$DICT_MEDIUM_SHA.zstd-dict"

$TINY_MAX   = [long]5000
$SMALL_MAX  = [long]100000
$MEDIUM_MAX = [long]500000

# ── Setup ────────────────────────────────────────────────────────────────────────
foreach ($d in @($BENCH_DIR,$DICT_DIR,$TMP_DIR)) { [IO.Directory]::CreateDirectory($d) | Out-Null }

if (-not (Test-Path $SEVENZIP))       { throw "7z.exe nao encontrado: $SEVENZIP" }
if (-not (Test-Path $ZSTD))           { throw "zstd.exe nao encontrado: $ZSTD" }
if (-not (Test-Path $MOTOR_PATH))     { throw "Motor v0.8.1 nao encontrado" }
if (-not (Test-Path $MANIFEST))       { throw "D7 manifest nao encontrado — rode Build-D7-Manifest.ps1 primeiro" }
if (-not (Test-Path $DICT_MEDIUM_SRC)){ throw "dict-medium nao encontrado: $DICT_MEDIUM_SRC" }

# ── Importar motor ───────────────────────────────────────────────────────────────
Write-Host "[V7] Importando motor v0.8.1..."
Import-Module $MOTOR_PATH -Force

# ── dict-medium ──────────────────────────────────────────────────────────────────
$DICT_MEDIUM_PATH = "$DICT_DIR\$DICT_MEDIUM_SHA.zstd-dict"
if (-not (Test-Path $DICT_MEDIUM_PATH)) {
    Copy-Item $DICT_MEDIUM_SRC $DICT_MEDIUM_PATH
    Write-Host "[V7] dict-medium copiado: $($DICT_MEDIUM_SHA.Substring(0,16))..."
} else {
    Write-Host "[V7] dict-medium presente: $($DICT_MEDIUM_SHA.Substring(0,16))..."
}
$medBytes   = [IO.File]::ReadAllBytes($DICT_MEDIUM_PATH)
$medActSha  = [TEIA.Native.TEIANativeV81]::SHA256Hex($medBytes)
if ($medActSha -ne $DICT_MEDIUM_SHA) { throw "dict-medium SHA mismatch: $medActSha" }
Write-Host "[V7] dict-medium SHA OK: $($DICT_MEDIUM_SHA.Substring(0,16))... | $($medBytes.Length) bytes"

# ── dict-small (mesmo corpus de treino do v6) ────────────────────────────────────
Write-Host ""
Write-Host "[V7] === TREINANDO dict-small ==="
$SMALL_TRAIN_DIR   = "D:\bruto\TEIA\Miniconda\envs\agents_v2\Lib\site-packages\googleapiclient\discovery_cache\documents"
$SMALL_TRAIN_FILES = @(
    "advisorynotifications.v1.json","apikeys.v2.json","baremetalsolution.v1alpha1.json",
    "blogger.v2.json","businessprofileperformance.v1.json","chromeuxreport.v1.json",
    "cloudshell.v1.json","cloudtrace.v2.json","dfareporting.v3.5.json","discovery.v1.json"
) | ForEach-Object { Join-Path $SMALL_TRAIN_DIR $_ }

$dictSmall      = Build-TEIAZstdDict -TrainingFiles $SMALL_TRAIN_FILES -OutputDir $DICT_DIR -MaxDictBytes 65536 -ZstdPath $ZSTD
$DICT_SMALL_SHA  = $dictSmall.DictSha256
$DICT_SMALL_PATH = $dictSmall.DictPath
Write-Host "[V7] dict-small: $($DICT_SMALL_SHA.Substring(0,16))... | $($dictSmall.DictBytes) bytes | $($dictSmall.TrainMs)ms"

# ── Corpus ───────────────────────────────────────────────────────────────────────
$manifest = Get-Content $MANIFEST -Raw | ConvertFrom-Json
$allFiles = @($manifest.files)
$corpusN  = $allFiles.Count
$classif  = if ($corpusN -ge 100) { "Benchmark Robusto" } elseif ($corpusN -ge 10) { "Benchmark Preliminar" } else { "Smoke Test" }
Write-Host ""
Write-Host "[V7] Corpus: $corpusN arquivos — $classif"

# ── Funcoes auxiliares ───────────────────────────────────────────────────────────
function Get-Bucket([long]$sz) {
    if ($sz -lt $TINY_MAX)   { return "tiny" }
    if ($sz -lt $SMALL_MAX)  { return "small" }
    if ($sz -lt $MEDIUM_MAX) { return "medium" }
    return "large"
}

function Get-LossReason([long]$A, [long]$B, [long]$C, [long]$D) {
    # A=LZMA, B=Zstd-raw, C=Zstd+dict(ou B se no-dict), D=TEIA
    if ($D -le $A)                    { return "GANHA" }
    if ($B -ge $A -and $C -ge $A)    { return "LZMA_JANELA" }      # LZMA superior em janela de match
    if ($C -gt $B)                    { return "DICT_PREJUDICA" }   # dict piora compressao (dominio errado)
    return                              "OVERHEAD_CANCELA"           # compressao bate LZMA, overhead reverte
}

function Compress-LZMA([byte[]]$data) {
    $tmpIn  = Join-Path $TMP_DIR ("lzma_in_"  + [IO.Path]::GetRandomFileName() + ".bin")
    $out    = Join-Path $TMP_DIR ("lzma_out_" + [IO.Path]::GetRandomFileName() + ".7z")
    $outLog = Join-Path $TMP_DIR ("lzma_log_" + [IO.Path]::GetRandomFileName() + ".log")
    try {
        [IO.File]::WriteAllBytes($tmpIn, $data)
        $sw   = [Diagnostics.Stopwatch]::StartNew()
        $p    = Start-Process -FilePath $SEVENZIP `
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
    $cmp = [TEIA.Native.TEIANativeV81]::CompressWithZstd($data, $ZSTD, "", 19)
    $sw.Stop()
    return [pscustomobject]@{ Bytes=$cmp.Length; Ms=$sw.ElapsedMilliseconds }
}

function Compress-ZstdDict([byte[]]$data, [string]$dictPath) {
    $sw  = [Diagnostics.Stopwatch]::StartNew()
    $cmp = [TEIA.Native.TEIANativeV81]::CompressWithZstd($data, $ZSTD, $dictPath, 19)
    $sw.Stop()
    return [pscustomobject]@{ Bytes=$cmp.Length; Ms=$sw.ElapsedMilliseconds }
}

function Encode-AndVerify([byte[]]$data, [string]$bucket, [string]$fid, [string]$fname, [string]$expSha) {
    $teiaPath = Join-Path $TMP_DIR "${fid}.teia"
    try {
        switch ($bucket) {
            "tiny"   {
                $enc = Invoke-TEIAEncodeRaw -Data $data -FileName $fname -ZstdPath $ZSTD
                [void](Save-TEIABin -TeiaBytes $enc.TeiaBytes -OutPath $teiaPath)
                $restored = Invoke-TEIARestoreBin -TeiaBytes ([IO.File]::ReadAllBytes($teiaPath)) -DictDir "" -ZstdPath $ZSTD
                return [pscustomobject]@{ Bytes=$enc.TeiaSize; OverheadBytes=$enc.OverheadBytes; Ms=$enc.EncodeMs; SHA256OK=([TEIA.Native.TEIANativeV81]::SHA256Hex($restored) -eq $expSha) }
            }
            "small"  {
                $enc = Invoke-TEIAEncodeBin -Data $data -DictPath $DICT_SMALL_PATH -FileName $fname -ZstdPath $ZSTD
                [void](Save-TEIABin -TeiaBytes $enc.TeiaBytes -OutPath $teiaPath)
                $restored = Invoke-TEIARestoreBin -TeiaBytes ([IO.File]::ReadAllBytes($teiaPath)) -DictDir $DICT_DIR -ZstdPath $ZSTD
                return [pscustomobject]@{ Bytes=$enc.TeiaSize; OverheadBytes=$enc.OverheadBytes; Ms=$enc.EncodeMs; SHA256OK=([TEIA.Native.TEIANativeV81]::SHA256Hex($restored) -eq $expSha) }
            }
            "medium" {
                $enc = Invoke-TEIAEncodeBin -Data $data -DictPath $DICT_MEDIUM_PATH -FileName $fname -ZstdPath $ZSTD
                [void](Save-TEIABin -TeiaBytes $enc.TeiaBytes -OutPath $teiaPath)
                $restored = Invoke-TEIARestoreBin -TeiaBytes ([IO.File]::ReadAllBytes($teiaPath)) -DictDir $DICT_DIR -ZstdPath $ZSTD
                return [pscustomobject]@{ Bytes=$enc.TeiaSize; OverheadBytes=$enc.OverheadBytes; Ms=$enc.EncodeMs; SHA256OK=([TEIA.Native.TEIANativeV81]::SHA256Hex($restored) -eq $expSha) }
            }
            "large"  {
                $enc = Invoke-TEIAEncodeRaw -Data $data -FileName $fname -ZstdPath $ZSTD
                [void](Save-TEIABin -TeiaBytes $enc.TeiaBytes -OutPath $teiaPath)
                $restored = Invoke-TEIARestoreBin -TeiaBytes ([IO.File]::ReadAllBytes($teiaPath)) -DictDir "" -ZstdPath $ZSTD
                return [pscustomobject]@{ Bytes=$enc.TeiaSize; OverheadBytes=$enc.OverheadBytes; Ms=$enc.EncodeMs; SHA256OK=([TEIA.Native.TEIANativeV81]::SHA256Hex($restored) -eq $expSha) }
            }
        }
    } finally {
        if (Test-Path $teiaPath) { Remove-Item $teiaPath -Force -EA SilentlyContinue }
    }
}

# ── Loop principal ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host ("=" * 108)
Write-Host ("  {0,-5} {1,-6} {2,9}  {3,10}  {4,10}  {5,10}  {6,10}  {7,3}  {8,-20}  {9}" -f `
    "ID","BUCKET","ORIG","A:LZMA","B:Zstd","C:Best","D:TEIA","WIN","RAZAO","SHA")
Write-Host ("=" * 108)

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
            Write-Host ("  {0,-5} SKIP (arquivo ausente)" -f $fid)
            continue
        }

        $data   = [IO.File]::ReadAllBytes($fpath)
        $actSha = [TEIA.Native.TEIANativeV81]::SHA256Hex($data)
        if ($actSha -ne $expSha) { throw "SHA-256 diverge do manifest: $actSha" }

        # A: LZMA
        $resA = Compress-LZMA $data

        # B: Zstd raw
        $resB = Compress-ZstdRaw $data

        # C: Zstd+dict (ou B para tiny/large sem dict)
        $resC_Bytes = switch ($bucket) {
            "tiny"   { $resB.Bytes }
            "small"  { (Compress-ZstdDict $data $DICT_SMALL_PATH).Bytes }
            "medium" { (Compress-ZstdDict $data $DICT_MEDIUM_PATH).Bytes }
            "large"  { $resB.Bytes }
        }

        # D: TEIA + SHA-256 restore verify
        $resD = Encode-AndVerify $data $bucket $fid $fname $expSha

        $pctA = [math]::Round($resA.Bytes   / $origSz * 100, 2)
        $pctB = [math]::Round($resB.Bytes   / $origSz * 100, 2)
        $pctC = [math]::Round($resC_Bytes   / $origSz * 100, 2)
        $pctD = [math]::Round($resD.Bytes   / $origSz * 100, 2)
        $deltaDA = $resA.Bytes - $resD.Bytes     # >0 = TEIA ganha
        $deltaDC = $resD.Bytes - $resC_Bytes     # overhead container
        $reason  = Get-LossReason $resA.Bytes $resB.Bytes $resC_Bytes $resD.Bytes
        $shaStr  = if ($resD.SHA256OK) { "OK" } else { "FAIL" }

        $row = [pscustomobject]@{
            ID=$fid; Name=$fname; Bucket=$bucket
            OrigBytes=$origSz
            A_Bytes=$resA.Bytes; A_Pct=$pctA; A_Ms=$resA.Ms
            B_Bytes=$resB.Bytes; B_Pct=$pctB; B_Ms=$resB.Ms
            C_Bytes=$resC_Bytes; C_Pct=$pctC
            D_Bytes=$resD.Bytes; D_Pct=$pctD; D_Ms=$resD.Ms
            Overhead=$resD.OverheadBytes
            Delta_DA=$deltaDA; Delta_DC=$deltaDC
            LossReason=$reason; SHA256OK=$resD.SHA256OK
        }
        [void]$results.Add($row)

        Write-Host ("  {0,-5} {1,-6} {2,9}B {3,9}B({4}%) {5,9}B({6}%) {7,9}B({8}%) {9,9}B({10}%) {11,3}  {12,-20}  {13}" -f `
            $fid, $bucket.ToUpper(), $origSz, `
            $resA.Bytes, $pctA, $resB.Bytes, $pctB, $resC_Bytes, $pctC, $resD.Bytes, $pctD, `
            $(if ($deltaDA -gt 0){"SIM"}else{"NAO"}), $reason, $shaStr)

    } catch {
        $msg = "ERRO em ${fid}: $_"
        [void]$errList.Add($msg)
        Write-Warning $msg
    }
}

Write-Host ("=" * 108)

# ── Estatisticas por bucket ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== SUMARIO POR BUCKET ==="
$bucketOrder = @("tiny","small","medium","large")
$bucketStats = [ordered]@{}

foreach ($bkt in $bucketOrder) {
    $grp = @($results | Where-Object { $_.Bucket -eq $bkt })
    if ($grp.Count -eq 0) { continue }

    $wins       = @($grp | Where-Object { $_.LossReason -eq "GANHA" }).Count
    $avgA       = [math]::Round(($grp | Measure-Object A_Pct -Average).Average, 2)
    $avgB       = [math]::Round(($grp | Measure-Object B_Pct -Average).Average, 2)
    $avgD       = [math]::Round(($grp | Measure-Object D_Pct -Average).Average, 2)
    $avgOvhd    = [math]::Round(($grp | Measure-Object Overhead -Average).Average, 0)
    $bWinsVsA   = @($grp | Where-Object { $_.B_Bytes -lt $_.A_Bytes }).Count
    $sumSavings = ($grp | Measure-Object Delta_DA -Sum).Sum
    $sha256all  = (@($grp | Where-Object { -not $_.SHA256OK }).Count -eq 0)

    $lLJ = @($grp | Where-Object { $_.LossReason -eq "LZMA_JANELA" }).Count
    $lDP = @($grp | Where-Object { $_.LossReason -eq "DICT_PREJUDICA" }).Count
    $lOC = @($grp | Where-Object { $_.LossReason -eq "OVERHEAD_CANCELA" }).Count

    $bucketStats[$bkt] = [pscustomobject]@{
        Bucket=$bkt; Count=$grp.Count; Wins=$wins
        AvgA=$avgA; AvgB=$avgB; AvgD=$avgD; AvgOvhd=$avgOvhd
        B_WinsVsA=$bWinsVsA; SumSavings=$sumSavings; SHA256All=$sha256all
        L_LJ=$lLJ; L_DP=$lDP; L_OC=$lOC
    }

    $shaStr2 = if ($sha256all) { "100% OK" } else { "FALHOU" }
    Write-Host ("  {0,-6}: {1}/{2} TEIA ganha | A={3}% B={4}% D={5}% | ovhd={6}B | SHA={7}" -f `
        $bkt.ToUpper(), $wins, $grp.Count, $avgA, $avgB, $avgD, $avgOvhd, $shaStr2)
    Write-Host ("          Perdas: LZMA_JANELA={0} DICT_PREJUDICA={1} OVERHEAD_CANCELA={2} | B wins vs A: {3}/{2}" -f `
        $lLJ, $lDP, $grp.Count, $lOC, $bWinsVsA)
}

$totalWins    = @($results | Where-Object { $_.LossReason -eq "GANHA" }).Count
$totalAll     = $results.Count
$totalErrors  = $errList.Count
$totalSavings = ($results | Measure-Object Delta_DA -Sum).Sum
$sha256All    = (@($results | Where-Object { -not $_.SHA256OK }).Count -eq 0)
Write-Host ""
Write-Host ("[V7] TOTAL: {0}/{1} TEIA ganha | {2} erros | {3}" -f $totalWins, $totalAll, $totalErrors, $classif)
if ($errList.Count -gt 0) { $errList | ForEach-Object { Write-Warning $_ } }

# ── Gerar relatorio ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[V7] Gerando relatorio..."

$ts    = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$mSha  = (Get-FileHash $MOTOR_PATH -Algorithm SHA256).Hash.ToLower()
$mSz   = (Get-Item $MOTOR_PATH).Length

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# Relatorio Comparativo v7.0.0 — TEIA $classif ($totalAll arquivos)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("> **Gerado**: $ts")
[void]$sb.AppendLine("> **Motor**: TEIA-Core-v0.8.1.psm1 | SHA-256: $mSha | $mSz bytes")
[void]$sb.AppendLine("> **Hardware**: i3-10100F, 16GB RAM, HDD")
[void]$sb.AppendLine("> **Corpus**: D7_REAL_MANIFEST.json | $totalAll arquivos | zero overlap D4 | seed=42")
[void]$sb.AppendLine("> **Classificacao**: $classif")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Estrategia de Compressao por Bucket")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Bucket | Opcode | Dict | C baseline |")
[void]$sb.AppendLine("|--------|--------|------|-----------|")
[void]$sb.AppendLine("| tiny (<5KB) | zstd.raw | nenhum | B:Zstd-19 |")
[void]$sb.AppendLine("| small (5-100KB) | dict.zstd_shared | dict-small (64KB, 10 Google API) | Zstd+dict-small |")
[void]$sb.AppendLine("| medium (100-500KB) | dict.zstd_shared | dict-medium (80KB, 8 botocore) | Zstd+dict-medium |")
[void]$sb.AppendLine("| large (>=500KB) | zstd.raw | nenhum | B:Zstd-19 |")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Dict | SHA-256 | Bytes | Corpus de treino |")
[void]$sb.AppendLine("|------|---------|-------|-----------------|")
[void]$sb.AppendLine("| dict-small | $DICT_SMALL_SHA | $($dictSmall.DictBytes) | 10 Google API docs (externos ao D4 e D7) |")
[void]$sb.AppendLine("| dict-medium | $DICT_MEDIUM_SHA | $($medBytes.Length) | 8 botocore service-2.json (em D4, ausentes do D7) |")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Resultados por Arquivo")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| ID | Bucket | Orig | A:LZMA | B:Zstd | C:Best | D:TEIA | D-C | D-A | SHA | Razao |")
[void]$sb.AppendLine("|----|--------|------|--------|--------|--------|--------|-----|-----|-----|-------|")
foreach ($r in $results) {
    $shaStr3  = if ($r.SHA256OK) { "OK" } else { "FAIL" }
    $dMinusA  = if ($r.Delta_DA -ge 0) { "-$($r.Delta_DA)B" } else { "+$([math]::Abs($r.Delta_DA))B" }
    [void]$sb.AppendLine(("| {0} | {1} | {2}B | {3}B ({4}%) | {5}B ({6}%) | {7}B ({8}%) | {9}B ({10}%) | +{11}B | {12} | {13} | {14} |" -f `
        $r.ID, $r.Bucket, $r.OrigBytes,
        $r.A_Bytes, $r.A_Pct, $r.B_Bytes, $r.B_Pct,
        $r.C_Bytes, $r.C_Pct, $r.D_Bytes, $r.D_Pct,
        $r.Delta_DC, $dMinusA, $shaStr3, $r.LossReason))
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Sumario por Bucket")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Bucket | Arq | Wins | A% | B% | D% | Ovhd | B>A | SHA | Savings |")
[void]$sb.AppendLine("|--------|-----|------|----|----|----|----|-----|-----|---------|")
foreach ($bkt in $bucketOrder) {
    if (-not $bucketStats.Contains($bkt)) { continue }
    $s = $bucketStats[$bkt]
    $shaStr4 = if ($s.SHA256All) { "100%OK" } else { "FALHOU" }
    [void]$sb.AppendLine(("| {0} | {1} | {2}/{1} | {3}% | {4}% | {5}% | {6}B | {7}/{1} | {8} | {9}B |" -f `
        $s.Bucket, $s.Count, $s.Wins, $s.AvgA, $s.AvgB, $s.AvgD, $s.AvgOvhd,
        ($s.Count - $s.B_WinsVsA), $shaStr4, $s.SumSavings))
}
$totShaStr = if ($sha256All) { "100%OK" } else { "FALHOU" }
[void]$sb.AppendLine(("| **TOTAL** | **{0}** | **{1}/{0}** | - | - | - | - | - | **{2}** | **{3}B** |" -f `
    $totalAll, $totalWins, $totShaStr, $totalSavings))
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Diagnostico de Perdas")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("### Contagem Global")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Razao | Count | Mecanismo | Fix Candidato v0.9 |")
[void]$sb.AppendLine("|-------|-------|-----------|-------------------|")

$reasonDefs = [ordered]@{
    "LZMA_JANELA"      = @{ Mec="LZMA tem janela de match maior (B>=A e C>=A)"; Fix="Opcode lzma.raw no bucket large" }
    "DICT_PREJUDICA"   = @{ Mec="Dict piora Zstd vs raw (dominio errado, C>B)"; Fix="Dict especifico por subdomain ou zstd.raw" }
    "OVERHEAD_CANCELA" = @{ Mec="Ganho real de compressao (C<A) revertido pelo overhead TEIA (D>A)"; Fix="Tiny: nao usar TEIA; Small: manifesto mais compacto" }
}
foreach ($reason in $reasonDefs.Keys) {
    $cnt = @($results | Where-Object { $_.LossReason -eq $reason }).Count
    if ($cnt -gt 0) {
        [void]$sb.AppendLine(("| **{0}** | **{1}** | {2} | {3} |" -f `
            $reason, $cnt, $reasonDefs[$reason].Mec, $reasonDefs[$reason].Fix))
    }
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("### Por Bucket")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Bucket | Total | GANHA | LZMA_JANELA | DICT_PREJUDICA | OVERHEAD_CANCELA |")
[void]$sb.AppendLine("|--------|-------|-------|-------------|----------------|-----------------|")
foreach ($bkt in $bucketOrder) {
    if (-not $bucketStats.Contains($bkt)) { continue }
    $s = $bucketStats[$bkt]
    [void]$sb.AppendLine(("| {0} | {1} | {2} | {3} | {4} | {5} |" -f `
        $s.Bucket, $s.Count, $s.Wins, $s.L_LJ, $s.L_DP, $s.L_OC))
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## B vs A — Competitividade Zstd Puro vs LZMA")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("*(Independente de dict ou overhead TEIA — competitividade base do algoritmo Zstd)*")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Bucket | Total | B<A Zstd-ganha | B>=A LZMA-ganha | Avg delta(B-A) |")
[void]$sb.AppendLine("|--------|-------|---------------|----------------|---------------|")
foreach ($bkt in $bucketOrder) {
    $grp = @($results | Where-Object { $_.Bucket -eq $bkt })
    if ($grp.Count -eq 0) { continue }
    $bW  = @($grp | Where-Object { $_.B_Bytes -lt $_.A_Bytes }).Count
    $bL  = $grp.Count - $bW
    $avg = [math]::Round(($grp | ForEach-Object { $_.B_Bytes - $_.A_Bytes } | Measure-Object -Average).Average, 0)
    [void]$sb.AppendLine(("| {0} | {1} | {2} | {3} | {4}B |" -f $bkt, $grp.Count, $bW, $bL, $avg))
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Erros ($totalErrors)")
[void]$sb.AppendLine("")
if ($errList.Count -eq 0) {
    [void]$sb.AppendLine("Nenhum erro.")
} else {
    foreach ($e in $errList) { [void]$sb.AppendLine("- $e") }
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("*TEIA-Core v0.8.1 | Harness v7.0.0 | Felippe Barcelos | $ts*")

# Salvar relatorio (UTF-8 sem BOM, Write==Read verify)
$report    = $sb.ToString()
$utf8NoBom = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($REPORT_PATH, $report, $utf8NoBom)
$repBytes    = [IO.File]::ReadAllBytes($REPORT_PATH)
$repWriteSha = [TEIA.Native.TEIANativeV81]::SHA256Hex($utf8NoBom.GetBytes($report))
$repReadSha  = [TEIA.Native.TEIANativeV81]::SHA256Hex($repBytes)
if ($repWriteSha -ne $repReadSha) { throw "Relatorio Write==Read FAIL: write=$repWriteSha read=$repReadSha" }

Write-Host "[V7] Relatorio: $REPORT_PATH | SHA: $repWriteSha"
Write-Host "[V7] CONCLUIDO: $totalWins/$totalAll TEIA ganha | $totalErrors erros | SHA-256=$(if($sha256All){'100% OK'}else{'FALHOU'}) | $classif"
