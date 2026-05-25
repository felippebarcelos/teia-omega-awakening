#Requires -Version 7
# Benchmark_Harness_v10.ps1
# TEIA v0.10.0 — Stress Test: Tokenizers + Activity Logs (tipos LZMA-dominados)
# Corpus: D8_STRESS_MANIFEST.json (17 arquivos — logs Google Takeout + tokenizers)
# Motor: TEIA-Core-v0.10.0.psm1 (mesmo de v9)
# Dict: NENHUM — todos os arquivos fora do domínio botocore/google-api-json.
#        Medida limpa: Selector Engine {cmp.zstd, cmp.xz, zstd.raw, xz.raw} sem dict.
#        Probe sets: tiny/small/medium→{cmp.zstd} | large→{cmp.xz, xz.raw, zstd.raw}
# Objetivo: mapear vantagem estrutural de LZMA em tipos adversariais.
# Saida: Relatorio_Comparativo_v10.0.0.md

$ErrorActionPreference = 'Continue'
Set-Location "D:\TEIA_CLAUDE_AWAKENING"

# ── Caminhos ─────────────────────────────────────────────────────────────────────
$MOTOR_PATH  = "D:\TEIA_CLAUDE_AWAKENING\Arqueologia do motor AION RISPA\NúcleoCompressorOntoprocedural\Ontologia Procedural\Motor onto procedural\TEIA-Core-v0.10.0.psm1"
$SEVENZIP    = "C:\Program Files\7-Zip\7z.exe"
$ZSTD        = "D:\TEIA_CLAUDE_AWAKENING\_tools\zstd\zstd-v1.5.6-win64\zstd.exe"
$MANIFEST    = "D:\TEIA_CLAUDE_AWAKENING\D8_STRESS_MANIFEST.json"
$BENCH_DIR   = "D:\TEIA_CLAUDE_AWAKENING\_bench_v10"
$DICT_DIR    = "$BENCH_DIR\dicts"
$TMP_DIR     = "$BENCH_DIR\tmp"
$REPORT_PATH = "D:\TEIA_CLAUDE_AWAKENING\Relatorio_Comparativo_v10.0.0.md"

$TINY_MAX   = [long]5000
$SMALL_MAX  = [long]100000
$MEDIUM_MAX = [long]500000

# ── Setup ─────────────────────────────────────────────────────────────────────────
foreach ($d in @($BENCH_DIR,$DICT_DIR,$TMP_DIR)) { [IO.Directory]::CreateDirectory($d) | Out-Null }

foreach ($chk in @($SEVENZIP,$ZSTD,$MOTOR_PATH,$MANIFEST)) {
    if (-not (Test-Path $chk)) { throw "Pré-requisito ausente: $chk" }
}

Write-Host "[V10] Importando motor v0.10.0..."
Import-Module $MOTOR_PATH -Force

# ── Corpus ────────────────────────────────────────────────────────────────────────
$manifest = Get-Content $MANIFEST -Raw | ConvertFrom-Json
$allFiles = @($manifest.files)
$corpusN  = $allFiles.Count
$classif  = "Stress Test — sem dict (tipos adversariais: tokenizers + activity logs)"
Write-Host ""
Write-Host "[V10] Corpus: $corpusN arquivos — $classif"
Write-Host "[V10] Sem dict — probe: tiny/small/medium→{cmp.zstd} | large→{cmp.xz, xz.raw, zstd.raw}"
Write-Host "[V10] DictSmallPath='' DictMediumPath='' — medida limpa de Selector Engine puro"

# ── Funções auxiliares ────────────────────────────────────────────────────────────
function Get-Bucket([long]$sz) {
    if ($sz -lt $TINY_MAX)   { return "tiny" }
    if ($sz -lt $SMALL_MAX)  { return "small" }
    if ($sz -lt $MEDIUM_MAX) { return "medium" }
    return "large"
}

function Get-LossReason([long]$A, [long]$B, [long]$D) {
    if ($D -le $A)  { return "GANHA" }
    if ($B -ge $A)  { return "LZMA_JANELA" }
    return            "OVERHEAD_CANCELA"
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
        $done = $p.WaitForExit(300000)
        $sw.Stop()
        if (-not $done) { $p.Kill(); throw "7z LZMA timeout >300s" }
        if ($p.ExitCode -ne 0) { throw "7z LZMA failed exit=$($p.ExitCode)" }
        if (-not (Test-Path $out)) { throw "7z LZMA output não criado" }
        return [pscustomobject]@{ Bytes=(Get-Item $out).Length; Ms=$sw.ElapsedMilliseconds }
    } finally {
        if (Test-Path $tmpIn)  { Remove-Item $tmpIn  -Force -EA SilentlyContinue }
        if (Test-Path $out)    { Remove-Item $out    -Force -EA SilentlyContinue }
        if (Test-Path $outLog) { Remove-Item $outLog -Force -EA SilentlyContinue }
    }
}

function Compress-ZstdRaw([byte[]]$data) {
    $sw  = [Diagnostics.Stopwatch]::StartNew()
    $cmp = [TEIA.Native.TEIANativeV100]::CompressWithZstd($data, $ZSTD, "", 19)
    $sw.Stop()
    return [pscustomobject]@{ Bytes=$cmp.Length; Ms=$sw.ElapsedMilliseconds }
}

function Encode-AndVerify([byte[]]$data, [string]$bucket, [string]$fid, [string]$fname, [string]$expSha) {
    $teiaPath = Join-Path $TMP_DIR "${fid}.teia"
    try {
        # DictSmallPath="" e DictMediumPath="" → sem dict → probe sets compactos sem dict
        $enc = Invoke-TEIAEncodeAuto -Data $data -Bucket $bucket -FileName $fname `
                   -DictSmallPath "" -DictMediumPath "" `
                   -ZstdPath $ZSTD -SevenZipPath $SEVENZIP

        [void](Save-TEIABin -TeiaBytes $enc.TeiaBytes -OutPath $teiaPath)
        $restored = Invoke-TEIARestoreBin -TeiaBytes ([IO.File]::ReadAllBytes($teiaPath)) `
                        -DictDir $DICT_DIR -ZstdPath $ZSTD -SevenZipPath $SEVENZIP
        $shaOK = ([TEIA.Native.TEIANativeV100]::SHA256Hex($restored) -eq $expSha)

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
Write-Host ("  {0,-5} {1,-6} {2,-5} {3,9}  {4,10}  {5,10}  {6,10}  {7,3}  {8,-8}  {9,-20}  {10}" -f `
    "ID","BUCKET","TYPE","ORIG","A:LZMA","B:Zstd","D:TEIA","WIN","OPCODE","RAZAO","SHA")
Write-Host ("=" * 125)

$results = [System.Collections.ArrayList]::new()
$errList = [System.Collections.ArrayList]::new()

foreach ($entry in $allFiles) {
    $fid    = $entry.id
    $fpath  = $entry.path
    $fname  = $entry.name
    $ftype  = $entry.type
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
        $actSha = [TEIA.Native.TEIANativeV100]::SHA256Hex($data)
        if ($actSha -ne $expSha) { throw "SHA-256 diverge do manifest: $actSha" }

        # A: LZMA (7z archive)
        $resA = Compress-LZMA $data

        # B: Zstd raw (baseline Zstd puro)
        $resB = Compress-ZstdRaw $data

        # D: TEIA Selector Engine (sem dict)
        $resD = Encode-AndVerify $data $bucket $fid $fname $expSha

        $pctA    = [math]::Round($resA.Bytes / $origSz * 100, 2)
        $pctB    = [math]::Round($resB.Bytes / $origSz * 100, 2)
        $pctD    = [math]::Round($resD.Bytes / $origSz * 100, 2)
        $deltaDA = $resA.Bytes - $resD.Bytes
        $deltaBA = $resB.Bytes - $resA.Bytes
        $reason  = Get-LossReason $resA.Bytes $resB.Bytes $resD.Bytes
        $shaStr  = if ($resD.SHA256OK) { "OK" } else { "FAIL" }
        $opShort = switch ($resD.Op) {
            "zstd.raw"         { "Z.raw" }
            "dict.zstd_shared" { "Dict"  }
            "xz.raw"           { "X.raw" }
            "cmp.zstd"         { "C.zst" }
            "cmp.xz"           { "C.xz"  }
            default            { $resD.Op }
        }

        $row = [pscustomobject]@{
            ID=$fid; Name=$fname; Type=$ftype; Bucket=$bucket; OrigBytes=$origSz
            A_Bytes=$resA.Bytes; A_Pct=$pctA; A_Ms=$resA.Ms
            B_Bytes=$resB.Bytes; B_Pct=$pctB; B_Ms=$resB.Ms
            D_Bytes=$resD.Bytes; D_Pct=$pctD; D_Ms=$resD.Ms
            Overhead=$resD.OverheadBytes; Delta_DA=$deltaDA; Delta_BA=$deltaBA
            LossReason=$reason; SHA256OK=$resD.SHA256OK
            Op=$resD.Op; ProbeCount=$resD.ProbeCount
        }
        [void]$results.Add($row)

        Write-Host ("  {0,-5} {1,-6} {2,-5} {3,9}B {4,9}B({5}%) {6,9}B({7}%) {8,9}B({9}%) {10,3}  {11,-8}  {12,-20}  {13}" -f `
            $fid, $bucket.ToUpper(), $ftype, $origSz,
            $resA.Bytes, $pctA, $resB.Bytes, $pctB, $resD.Bytes, $pctD,
            $(if ($deltaDA -gt 0){"SIM"}else{"NAO"}),
            $opShort, $reason, $shaStr)

    } catch {
        $msg = "ERRO em ${fid}: $_"
        [void]$errList.Add($msg)
        Write-Warning $msg
    }
}

Write-Host ("=" * 125)

# ── Sumário ───────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== SUMARIO ==="
$bucketOrder = @("tiny","small","medium","large")
$bucketStats = [ordered]@{}

foreach ($bkt in $bucketOrder) {
    $grp = @($results | Where-Object { $_.Bucket -eq $bkt })
    if ($grp.Count -eq 0) { continue }
    $wins    = @($grp | Where-Object { $_.LossReason -eq "GANHA" }).Count
    $avgA    = [math]::Round(($grp | Measure-Object A_Pct -Average).Average, 2)
    $avgB    = [math]::Round(($grp | Measure-Object B_Pct -Average).Average, 2)
    $avgD    = [math]::Round(($grp | Measure-Object D_Pct -Average).Average, 2)
    $avgOvhd = [math]::Round(($grp | Measure-Object Overhead -Average).Average, 0)
    $sha256ok= (@($grp | Where-Object { -not $_.SHA256OK }).Count -eq 0)
    $lLJ     = @($grp | Where-Object { $_.LossReason -eq "LZMA_JANELA" }).Count
    $lOC     = @($grp | Where-Object { $_.LossReason -eq "OVERHEAD_CANCELA" }).Count
    $nCZ     = @($grp | Where-Object { $_.Op -eq "cmp.zstd" }).Count
    $nCX     = @($grp | Where-Object { $_.Op -eq "cmp.xz" }).Count
    $nZ      = @($grp | Where-Object { $_.Op -eq "zstd.raw" }).Count

    $bucketStats[$bkt] = [pscustomobject]@{
        Bucket=$bkt; Count=$grp.Count; Wins=$wins
        AvgA=$avgA; AvgB=$avgB; AvgD=$avgD; AvgOvhd=$avgOvhd; SHA256All=$sha256ok
        L_LJ=$lLJ; L_OC=$lOC; Op_CZ=$nCZ; Op_CX=$nCX; Op_Z=$nZ
    }

    $shaStr2 = if ($sha256ok) { "100% OK" } else { "FALHOU" }
    Write-Host ("  {0,-6}: {1}/{2} | A={3}% B={4}% D={5}% | ovhd={6}B | LJ={7} OC={8} | {9}" -f `
        $bkt.ToUpper(), $wins, $grp.Count, $avgA, $avgB, $avgD, $avgOvhd, $lLJ, $lOC, $shaStr2)
}

Write-Host ""
Write-Host "--- POR TIPO ---"
foreach ($tp in @("LOG","TOK")) {
    $grp = @($results | Where-Object { $_.Type -eq $tp })
    if ($grp.Count -eq 0) { continue }
    $wins = @($grp | Where-Object { $_.LossReason -eq "GANHA" }).Count
    $avgA = [math]::Round(($grp | Measure-Object A_Pct -Average).Average, 2)
    $avgD = [math]::Round(($grp | Measure-Object D_Pct -Average).Average, 2)
    Write-Host ("  {0}: {1}/{2} | A={3}% D={4}%" -f $tp, $wins, $grp.Count, $avgA, $avgD)
}

$totalWins   = @($results | Where-Object { $_.LossReason -eq "GANHA" }).Count
$totalAll    = $results.Count
$totalErrors = $errList.Count
$sha256All   = (@($results | Where-Object { -not $_.SHA256OK }).Count -eq 0)

Write-Host ""
Write-Host ("[V10] TOTAL: {0}/{1} | {2} erros" -f $totalWins, $totalAll, $totalErrors)
if ($errList.Count -gt 0) { $errList | ForEach-Object { Write-Warning $_ } }

# ── Diagnóstico detalhado ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== LZMA_JANELA ==="
@($results | Where-Object { $_.LossReason -eq "LZMA_JANELA" } | Sort-Object Delta_DA) |
    ForEach-Object {
        $delta = $_.D_Bytes - $_.A_Bytes
        Write-Host ("  {0} ({1}, {2}B): D-A=+{3}B | B-A=+{4}B | A={5}% B={6}% D={7}% | {8}" -f `
            $_.ID, $_.Type, $_.OrigBytes, $delta, $_.Delta_BA, $_.A_Pct, $_.B_Pct, $_.D_Pct, $_.Op)
    }

# ── Relatório ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[V10] Gerando relatório..."

$ts   = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$mSha = (Get-FileHash $MOTOR_PATH -Algorithm SHA256).Hash.ToLower()
$mSz  = (Get-Item $MOTOR_PATH).Length

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# Relatorio Comparativo v10.0.0 — TEIA Stress Test: Tokenizers + Activity Logs")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("> **Gerado**: $ts")
[void]$sb.AppendLine("> **Motor**: TEIA-Core-v0.10.0.psm1 | SHA-256: $mSha | $mSz bytes")
[void]$sb.AppendLine("> **Corpus**: D8_STRESS_MANIFEST.json | $totalAll arquivos | tokenizers + activity logs")
[void]$sb.AppendLine("> **Dict**: NENHUM — DictSmallPath='' DictMediumPath='' | medida limpa Selector Engine puro")
[void]$sb.AppendLine("> **Probe sets**: tiny/small/medium→{cmp.zstd} | large→{cmp.xz, xz.raw, zstd.raw}")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Resultados por Arquivo")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| ID | Nome | Type | Bucket | Orig | A:LZMA | A% | B:Zstd | B% | D:TEIA | D% | WIN | B-A | OPCODE | RAZAO | SHA |")
[void]$sb.AppendLine("|----|------|------|--------|------|--------|-----|--------|-----|-------|-----|-----|-----|--------|------|-----|")

foreach ($r in $results) {
    $win = if ($r.Delta_DA -gt 0) { "SIM" } else { "NAO" }
    $op  = switch ($r.Op) { "xz.raw"{"X.raw"} "cmp.zstd"{"C.zst"} "cmp.xz"{"C.xz"} default{"Z.raw"} }
    $sha = if ($r.SHA256OK) { "OK" } else { "FAIL" }
    $baTag = if ($r.Delta_BA -gt 0) { "+$($r.Delta_BA)B" } else { "$($r.Delta_BA)B" }
    [void]$sb.AppendLine("| $($r.ID) | $($r.Name) | $($r.Type) | $($r.Bucket) | $($r.OrigBytes) | $($r.A_Bytes) | $($r.A_Pct)% | $($r.B_Bytes) | $($r.B_Pct)% | $($r.D_Bytes) | $($r.D_Pct)% | $win | $baTag | $op | $($r.LossReason) | $sha |")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Sumário por Bucket")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Bucket | N | Wins | A% | B% | D% | Ovhd | LJ | OC | C.zst | C.xz | Z.raw | SHA |")
[void]$sb.AppendLine("|--------|---|------|----|----|----|------|----|----|-------|------|-------|-----|")

foreach ($bkt in $bucketOrder) {
    $s = $bucketStats[$bkt]; if (-not $s) { continue }
    $sha3 = if ($s.SHA256All) { "100%OK" } else { "FAIL" }
    [void]$sb.AppendLine("| $($s.Bucket) | $($s.Count) | $($s.Wins)/$($s.Count) | $($s.AvgA)% | $($s.AvgB)% | $($s.AvgD)% | ~$($s.AvgOvhd)B | $($s.L_LJ) | $($s.L_OC) | $($s.Op_CZ) | $($s.Op_CX) | $($s.Op_Z) | $sha3 |")
}

$tSha = if ($sha256All) { "100% OK" } else { "FALHOU" }
[void]$sb.AppendLine("| **TOTAL** | **$totalAll** | **$totalWins/$totalAll** | — | — | — | — | — | — | — | — | — | **$tSha** |")

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Sumário por Tipo")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Tipo | N | Wins | A% | B% | D% | LJ | OC |")
[void]$sb.AppendLine("|------|---|------|----|----|----|----|----|")

foreach ($tp in @("LOG","TOK")) {
    $grp = @($results | Where-Object { $_.Type -eq $tp })
    if ($grp.Count -eq 0) { continue }
    $wins = @($grp | Where-Object { $_.LossReason -eq "GANHA" }).Count
    $avgA = [math]::Round(($grp | Measure-Object A_Pct -Average).Average, 2)
    $avgB = [math]::Round(($grp | Measure-Object B_Pct -Average).Average, 2)
    $avgD = [math]::Round(($grp | Measure-Object D_Pct -Average).Average, 2)
    $lLJ  = @($grp | Where-Object { $_.LossReason -eq "LZMA_JANELA" }).Count
    $lOC  = @($grp | Where-Object { $_.LossReason -eq "OVERHEAD_CANCELA" }).Count
    [void]$sb.AppendLine("| $tp | $($grp.Count) | $wins/$($grp.Count) | $avgA% | $avgB% | $avgD% | $lLJ | $lOC |")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Diagnóstico de Perdas LZMA_JANELA")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| ID | Nome | Type | Orig | A | B | D | D-A | B-A | A% | D% |")
[void]$sb.AppendLine("|----|------|------|------|---|---|---|-----|-----|-----|-----|")
foreach ($lf in ($results | Where-Object { $_.LossReason -eq "LZMA_JANELA" } | Sort-Object { $_.D_Bytes - $_.A_Bytes } -Descending)) {
    $da = $lf.D_Bytes - $lf.A_Bytes
    $ba = $lf.B_Bytes - $lf.A_Bytes
    [void]$sb.AppendLine("| $($lf.ID) | $($lf.Name) | $($lf.Type) | $($lf.OrigBytes)B | $($lf.A_Bytes)B | $($lf.B_Bytes)B | $($lf.D_Bytes)B | +${da}B | +${ba}B | $($lf.A_Pct)% | $($lf.D_Pct)% |")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Próximos Passos")
[void]$sb.AppendLine("")
$lossCount = $totalAll - $totalWins
[void]$sb.AppendLine("**$totalWins/$totalAll TEIA ganha** — $lossCount perdas.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Para LZMA_JANELA losses:")
[void]$sb.AppendLine("- **dict-log**: treinar em corpus externo de activity logs (precisa ~6.5MB, fora do test set)")
[void]$sb.AppendLine("- **dict-tok**: separar training/test de tokenizers — precisa corpus maior (GPT-2/LLaMA tokenizers)")
[void]$sb.AppendLine("- **cmp.xz** já é melhor que xz.raw. Margem restante é estrutural (LZMA1 window > LZMA2).")

# ── Write==Read ───────────────────────────────────────────────────────────────────
$reportText = $sb.ToString()
$utf8NoBom  = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($REPORT_PATH, $reportText, $utf8NoBom)

$writeSha = [TEIA.Native.TEIANativeV100]::SHA256Hex($utf8NoBom.GetBytes($reportText))
$readBack = [IO.File]::ReadAllBytes($REPORT_PATH)
$readSha  = [TEIA.Native.TEIANativeV100]::SHA256Hex($readBack)
if ($writeSha -ne $readSha) { throw "Write==Read FAIL: write=$writeSha read=$readSha" }

Write-Host ""
Write-Host "[V10] COMPLETO — $REPORT_PATH"
Write-Host "[V10] Relatorio SHA-256: $writeSha"
Write-Host "[V10] $totalWins/$totalAll | SHA-256 $tSha | $totalErrors erros"
