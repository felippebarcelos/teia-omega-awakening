#Requires -Version 7
# Benchmark_Harness_v11.ps1
# TEIA v0.11.0 — Stress Test v2: validacao empirica do opcode cmp.lzma
# Corpus: D8_STRESS_MANIFEST.json (17 arquivos — logs Google Takeout + tokenizers)
# Motor: TEIA-Core-v0.11.0.psm1 (classe TEIANativeV110)
# Dict: NENHUM — medida limpa do Selector Engine v11 com novo opcode cmp.lzma
# Probe sets v0.11.0:
#   tiny:   {cmp.zstd}
#   small:  {cmp.zstd, cmp.lzma(se py)}
#   medium: {cmp.lzma(se py), cmp.zstd}
#   large:  {cmp.lzma(se py), cmp.xz, zstd.raw}
# Colunas: A:7z-LZMA | B:Zstd-raw | C:Py-LZMA1-payload | D:TEIA-v11
# Objetivo: confirmar que cmp.lzma vira LZMA_JANELA->GANHA em S12-S17 (e medios S5-S11)
# Saida: Relatorio_Comparativo_v11.0.0.md

$ErrorActionPreference = 'Continue'
Set-Location "D:\TEIA_CLAUDE_AWAKENING"

# ── Caminhos ─────────────────────────────────────────────────────────────────────
$MOTOR_PATH  = "D:\TEIA_CLAUDE_AWAKENING\Arqueologia do motor AION RISPA\NúcleoCompressorOntoprocedural\Ontologia Procedural\Motor onto procedural\TEIA-Core-v0.11.0.psm1"
$SEVENZIP    = "C:\Program Files\7-Zip\7z.exe"
$ZSTD        = "D:\TEIA_CLAUDE_AWAKENING\_tools\zstd\zstd-v1.5.6-win64\zstd.exe"
$PYTHON      = "D:\bruto\TEIA\TEIA_ATLAS\Materia_Bruta\D_Drive\TEIA_Data\python\python.exe"
$MANIFEST    = "D:\TEIA_CLAUDE_AWAKENING\D8_STRESS_MANIFEST.json"
$BENCH_DIR   = "D:\TEIA_CLAUDE_AWAKENING\_bench_v11"
$DICT_DIR    = "$BENCH_DIR\dicts"
$TMP_DIR     = "$BENCH_DIR\tmp"
$REPORT_PATH = "D:\TEIA_CLAUDE_AWAKENING\Relatorio_Comparativo_v11.0.0.md"

$TINY_MAX   = [long]5000
$SMALL_MAX  = [long]100000
$MEDIUM_MAX = [long]500000

# ── Setup ─────────────────────────────────────────────────────────────────────────
foreach ($d in @($BENCH_DIR, $DICT_DIR, $TMP_DIR)) { [IO.Directory]::CreateDirectory($d) | Out-Null }

foreach ($chk in @($SEVENZIP, $ZSTD, $MOTOR_PATH, $MANIFEST)) {
    if (-not (Test-Path $chk)) { throw "Pre-requisito ausente: $chk" }
}
$hasPython = Test-Path $PYTHON
Write-Host "[V11] Python disponivel: $hasPython ($PYTHON)"

Write-Host "[V11] Importando motor v0.11.0..."
Import-Module $MOTOR_PATH -Force

# ── Corpus ────────────────────────────────────────────────────────────────────────
$manifest = Get-Content $MANIFEST -Raw | ConvertFrom-Json
$allFiles  = @($manifest.files)
$corpusN   = $allFiles.Count
Write-Host ""
Write-Host "[V11] Corpus: $corpusN arquivos | D8_STRESS_MANIFEST.json"
Write-Host "[V11] Probe sets v0.11.0 com cmp.lzma | sem dict"

# ── Funcoes auxiliares ────────────────────────────────────────────────────────────
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

# A: 7z LZMA (baseline — 7z .7z container com LZMA1 mx9)
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
        if (-not (Test-Path $out)) { throw "7z LZMA output nao criado" }
        return [pscustomobject]@{ Bytes=(Get-Item $out).Length; Ms=$sw.ElapsedMilliseconds }
    } finally {
        if (Test-Path $tmpIn)  { Remove-Item $tmpIn  -Force -EA SilentlyContinue }
        if (Test-Path $out)    { Remove-Item $out    -Force -EA SilentlyContinue }
        if (Test-Path $outLog) { Remove-Item $outLog -Force -EA SilentlyContinue }
    }
}

# B: Zstd raw (payload nu sem TEIA overhead)
function Compress-ZstdRaw([byte[]]$data) {
    $sw  = [Diagnostics.Stopwatch]::StartNew()
    $cmp = [TEIA.Native.TEIANativeV110]::CompressWithZstd($data, $ZSTD, "", 19)
    $sw.Stop()
    return [pscustomobject]@{ Bytes=$cmp.Length; Ms=$sw.ElapsedMilliseconds }
}

# C: Python LZMA1 FORMAT_ALONE payload (sem TEIA overhead) — para comparacao direta com A
function Compress-Lzma1Py([byte[]]$data) {
    if (-not $hasPython) { return [pscustomobject]@{ Bytes=-1; Ms=0 } }
    $sw  = [Diagnostics.Stopwatch]::StartNew()
    $cmp = [TEIA.Native.TEIANativeV110]::CompressWithLzma1($data, $PYTHON)
    $sw.Stop()
    return [pscustomobject]@{ Bytes=$cmp.Length; Ms=$sw.ElapsedMilliseconds }
}

# D: TEIA Selector Engine v11 — encode + roundtrip SHA-256
function Encode-AndVerify([byte[]]$data, [string]$bucket, [string]$fid, [string]$fname, [string]$expSha) {
    $teiaPath = Join-Path $TMP_DIR "${fid}_v11.teia"
    try {
        $enc = Invoke-TEIAEncodeAuto -Data $data -Bucket $bucket -FileName $fname `
                   -DictSmallPath "" -DictMediumPath "" `
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
Write-Host ("=" * 140)
Write-Host ("  {0,-5} {1,-6} {2,-3} {3,9}  {4,10}  {5,10}  {6,10}  {7,10}  {8,-3}  {9,-8}  {10,-20}  {11}" -f `
    "ID","BUCKET","TYP","ORIG","A:7z-LZMA","B:Zstd","C:Py-LZMA1","D:TEIA-v11","WIN","OPCODE","RAZAO","SHA")
Write-Host ("=" * 140)

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
        $actSha = [TEIA.Native.TEIANativeV110]::SHA256Hex($data)
        if ($actSha -ne $expSha) { throw "SHA-256 diverge do manifest: $actSha" }

        # A: 7z LZMA archive
        $resA = Compress-LZMA $data

        # B: Zstd raw payload
        $resB = Compress-ZstdRaw $data

        # C: Python LZMA1 payload (without TEIA overhead)
        $resC = Compress-Lzma1Py $data

        # D: TEIA Selector Engine v11
        $resD = Encode-AndVerify $data $bucket $fid $fname $expSha

        $pctA    = [math]::Round($resA.Bytes / $origSz * 100, 2)
        $pctB    = [math]::Round($resB.Bytes / $origSz * 100, 2)
        $pctC    = if ($resC.Bytes -ge 0) { [math]::Round($resC.Bytes / $origSz * 100, 2) } else { -1 }
        $pctD    = [math]::Round($resD.Bytes / $origSz * 100, 2)
        $deltaDA = $resA.Bytes - $resD.Bytes   # positivo = TEIA vence
        $deltaCA = $resC.Bytes - $resA.Bytes   # negativo = Python LZMA1 < 7z LZMA (antes de overhead)
        $reason  = Get-LossReason $resA.Bytes $resB.Bytes $resD.Bytes
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
        $cStr = if ($resC.Bytes -ge 0) { "$($resC.Bytes)B" } else { "N/A" }

        $row = [pscustomobject]@{
            ID=$fid; Name=$fname; Type=$ftype; Bucket=$bucket; OrigBytes=$origSz
            A_Bytes=$resA.Bytes; A_Pct=$pctA; A_Ms=$resA.Ms
            B_Bytes=$resB.Bytes; B_Pct=$pctB; B_Ms=$resB.Ms
            C_Bytes=$resC.Bytes; C_Pct=$pctC; C_Ms=$resC.Ms
            D_Bytes=$resD.Bytes; D_Pct=$pctD; D_Ms=$resD.Ms
            Overhead=$resD.OverheadBytes
            Delta_DA=$deltaDA; Delta_CA=$deltaCA
            LossReason=$reason; SHA256OK=$resD.SHA256OK
            Op=$resD.Op; ProbeCount=$resD.ProbeCount
        }
        [void]$results.Add($row)

        Write-Host ("  {0,-5} {1,-6} {2,-3} {3,9}B {4,9}B {5,9}B {6,9}B {7,9}B {8,3}  {9,-8}  {10,-20}  {11}" -f `
            $fid, $bucket.ToUpper(), $ftype, $origSz,
            $resA.Bytes, $resB.Bytes, $resC.Bytes, $resD.Bytes,
            $(if ($deltaDA -gt 0){"SIM"}else{"NAO"}),
            $opShort, $reason, $shaStr)

    } catch {
        $msg = "ERRO em ${fid}: $_"
        [void]$errList.Add($msg)
        Write-Warning $msg
    }
}

Write-Host ("=" * 140)

# ── Sumario ───────────────────────────────────────────────────────────────────────
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
    $nCL     = @($grp | Where-Object { $_.Op -eq "cmp.lzma" }).Count
    $nCX     = @($grp | Where-Object { $_.Op -eq "cmp.xz" }).Count
    $nZ      = @($grp | Where-Object { $_.Op -eq "zstd.raw" }).Count

    $bucketStats[$bkt] = [pscustomobject]@{
        Bucket=$bkt; Count=$grp.Count; Wins=$wins
        AvgA=$avgA; AvgB=$avgB; AvgD=$avgD; AvgOvhd=$avgOvhd; SHA256All=$sha256ok
        L_LJ=$lLJ; L_OC=$lOC; Op_CZ=$nCZ; Op_CL=$nCL; Op_CX=$nCX; Op_Z=$nZ
    }

    $shaStr2 = if ($sha256ok) { "100% OK" } else { "FALHOU" }
    Write-Host ("  {0,-6}: {1}/{2} | A={3}% B={4}% D={5}% | ovhd={6}B | LJ={7} OC={8} | C.lzma={9} | {10}" -f `
        $bkt.ToUpper(), $wins, $grp.Count, $avgA, $avgB, $avgD, $avgOvhd, $lLJ, $lOC, $nCL, $shaStr2)
}

Write-Host ""
Write-Host "--- POR TIPO ---"
foreach ($tp in @("LOG","TOK")) {
    $grp = @($results | Where-Object { $_.Type -eq $tp })
    if ($grp.Count -eq 0) { continue }
    $wins = @($grp | Where-Object { $_.LossReason -eq "GANHA" }).Count
    $avgA = [math]::Round(($grp | Measure-Object A_Pct -Average).Average, 2)
    $avgD = [math]::Round(($grp | Measure-Object D_Pct -Average).Average, 2)
    $nCL  = @($grp | Where-Object { $_.Op -eq "cmp.lzma" }).Count
    Write-Host ("  {0}: {1}/{2} | A={3}% D={4}% | C.lzma={5}" -f $tp, $wins, $grp.Count, $avgA, $avgD, $nCL)
}

$totalWins   = @($results | Where-Object { $_.LossReason -eq "GANHA" }).Count
$totalAll    = $results.Count
$totalErrors = $errList.Count
$sha256All   = (@($results | Where-Object { -not $_.SHA256OK }).Count -eq 0)
$totalSaving = ($results | Measure-Object Delta_DA -Sum).Sum

Write-Host ""
Write-Host ("[V11] TOTAL: {0}/{1} | saving={2}B | {3} erros" -f $totalWins, $totalAll, $totalSaving, $totalErrors)
if ($errList.Count -gt 0) { $errList | ForEach-Object { Write-Warning $_ } }

# ── Diagnostico detalhado ─────────────────────────────────────────────────────────
$remaining = @($results | Where-Object { $_.LossReason -eq "LZMA_JANELA" })
if ($remaining.Count -gt 0) {
    Write-Host ""
    Write-Host "=== LZMA_JANELA RESTANTES ==="
    $remaining | Sort-Object { $_.D_Bytes - $_.A_Bytes } | ForEach-Object {
        $da = $_.D_Bytes - $_.A_Bytes
        $ca = $_.C_Bytes - $_.A_Bytes
        Write-Host ("  {0} ({1}, {2}B): D-A=+{3}B | C-A={4}B | A={5}% D={6}% | {7}" -f `
            $_.ID, $_.Type, $_.OrigBytes, $da, $ca, $_.A_Pct, $_.D_Pct, $_.Op)
    }
}

$flipped = @($results | Where-Object { $_.Op -eq "cmp.lzma" -and $_.LossReason -eq "GANHA" })
Write-Host ""
Write-Host "=== C.LZMA GANHA (flips de v10) ==="
$flipped | Sort-Object Delta_DA -Descending | ForEach-Object {
    Write-Host ("  {0} ({1}, {2}B): D-A=-{3}B | C-A={4}B | A={5}% D={6}%" -f `
        $_.ID, $_.Type, $_.OrigBytes, $_.Delta_DA, $_.Delta_CA, $_.A_Pct, $_.D_Pct)
}

# ── Relatorio ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[V11] Gerando relatorio..."

$ts   = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$mSha = (Get-FileHash $MOTOR_PATH -Algorithm SHA256).Hash.ToLower()
$mSz  = (Get-Item $MOTOR_PATH).Length

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# Relatorio Comparativo v11.0.0 — TEIA v0.11.0: opcode cmp.lzma (LZMA1 FORMAT_ALONE)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("> **Gerado**: $ts")
[void]$sb.AppendLine("> **Motor**: TEIA-Core-v0.11.0.psm1 | SHA-256: $mSha | $mSz bytes")
[void]$sb.AppendLine("> **Corpus**: D8_STRESS_MANIFEST.json | $totalAll arquivos | tokenizers + activity logs")
[void]$sb.AppendLine("> **Dict**: NENHUM | medida limpa do Selector Engine v11 com cmp.lzma")
[void]$sb.AppendLine("> **Python**: $PYTHON | hasPython=$hasPython")
[void]$sb.AppendLine("> **Probe sets**: tiny→{cmp.zstd} | small→{cmp.zstd,cmp.lzma} | medium→{cmp.lzma,cmp.zstd} | large→{cmp.lzma,cmp.xz,zstd.raw}")
[void]$sb.AppendLine("> **Colunas**: A=7z-LZMA-archive | B=Zstd-raw-payload | C=Python-LZMA1-payload | D=TEIA-v11-output")
[void]$sb.AppendLine("> **Delta**: D-A negativo = TEIA vence LZMA | C-A negativo = Python LZMA1 bate 7z antes de overhead")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Resultados por Arquivo")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| ID | Nome | Typ | Bucket | Orig | A:7z-LZMA | B:Zstd | C:Py-LZMA1 | D:TEIA-v11 | WIN | D-A | C-A | OPCODE | RAZAO | SHA |")
[void]$sb.AppendLine("|----|------|-----|--------|------|-----------|--------|------------|------------|-----|-----|-----|--------|-------|-----|")

foreach ($r in $results) {
    $win  = if ($r.Delta_DA -gt 0) { "SIM" } else { "NAO" }
    $op   = switch ($r.Op) { "cmp.lzma"{"C.lzma"} "cmp.xz"{"C.xz"} "cmp.zstd"{"C.zst"} "zstd.raw"{"Z.raw"} default{$r.Op} }
    $sha  = if ($r.SHA256OK) { "OK" } else { "FAIL" }
    $daTag = if ($r.Delta_DA -ge 0) { "-$($r.Delta_DA)B" } else { "+$([math]::Abs($r.Delta_DA))B" }
    $caTag = if ($r.C_Bytes -lt 0) { "N/A" } elseif ($r.Delta_CA -le 0) { "$($r.Delta_CA)B" } else { "+$($r.Delta_CA)B" }
    $cStr  = if ($r.C_Bytes -ge 0) { "$($r.C_Bytes)B" } else { "N/A" }
    [void]$sb.AppendLine("| $($r.ID) | $($r.Name) | $($r.Type) | $($r.Bucket) | $($r.OrigBytes)B | $($r.A_Bytes)B | $($r.B_Bytes)B | $cStr | $($r.D_Bytes)B | $win | $daTag | $caTag | $op | $($r.LossReason) | $sha |")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Sumario por Bucket")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Bucket | N | Wins | A% | B% | D% | Ovhd | LJ | OC | C.lzma | C.xz | Z.raw | C.zst | SHA |")
[void]$sb.AppendLine("|--------|---|------|----|----|----|------|----|----|--------|------|-------|-------|-----|")

foreach ($bkt in $bucketOrder) {
    $s = $bucketStats[$bkt]; if (-not $s) { continue }
    $sha3 = if ($s.SHA256All) { "100%OK" } else { "FAIL" }
    [void]$sb.AppendLine("| $($s.Bucket) | $($s.Count) | $($s.Wins)/$($s.Count) | $($s.AvgA)% | $($s.AvgB)% | $($s.AvgD)% | ~$($s.AvgOvhd)B | $($s.L_LJ) | $($s.L_OC) | $($s.Op_CL) | $($s.Op_CX) | $($s.Op_Z) | $($s.Op_CZ) | $sha3 |")
}

$tSha = if ($sha256All) { "100% OK" } else { "FALHOU" }
[void]$sb.AppendLine("| **TOTAL** | **$totalAll** | **$totalWins/$totalAll** | — | — | — | — | — | — | — | — | — | — | **$tSha** |")

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Sumario por Tipo")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Tipo | N | Wins | A% | B% | D% | C.lzma | LJ | OC |")
[void]$sb.AppendLine("|------|---|------|----|----|----|--------|----|----|")

foreach ($tp in @("LOG","TOK")) {
    $grp = @($results | Where-Object { $_.Type -eq $tp })
    if ($grp.Count -eq 0) { continue }
    $wins = @($grp | Where-Object { $_.LossReason -eq "GANHA" }).Count
    $avgA = [math]::Round(($grp | Measure-Object A_Pct -Average).Average, 2)
    $avgB = [math]::Round(($grp | Measure-Object B_Pct -Average).Average, 2)
    $avgD = [math]::Round(($grp | Measure-Object D_Pct -Average).Average, 2)
    $nCL  = @($grp | Where-Object { $_.Op -eq "cmp.lzma" }).Count
    $lLJ  = @($grp | Where-Object { $_.LossReason -eq "LZMA_JANELA" }).Count
    $lOC  = @($grp | Where-Object { $_.LossReason -eq "OVERHEAD_CANCELA" }).Count
    [void]$sb.AppendLine("| $tp | $($grp.Count) | $wins/$($grp.Count) | $avgA% | $avgB% | $avgD% | $nCL | $lLJ | $lOC |")
}

# ── Diagnostico de flips ──────────────────────────────────────────────────────────
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Flips v10→v11 (C.LZMA como opcode vencedor)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| ID | Nome | Tipo | Orig | A | C:Py | D:TEIA | D-A | C-A | Ovhd |")
[void]$sb.AppendLine("|----|------|------|------|---|------|--------|-----|-----|------|")
foreach ($r in ($results | Where-Object { $_.Op -eq "cmp.lzma" -and $_.LossReason -eq "GANHA" } | Sort-Object Delta_DA -Descending)) {
    $cStr  = if ($r.C_Bytes -ge 0) { "$($r.C_Bytes)B" } else { "N/A" }
    $caTag = if ($r.C_Bytes -lt 0) { "N/A" } elseif ($r.Delta_CA -le 0) { "$($r.Delta_CA)B" } else { "+$($r.Delta_CA)B" }
    [void]$sb.AppendLine("| $($r.ID) | $($r.Name) | $($r.Type) | $($r.OrigBytes)B | $($r.A_Bytes)B | $cStr | $($r.D_Bytes)B | -$($r.Delta_DA)B | $caTag | $($r.Overhead)B |")
}

# ── Perdas restantes ──────────────────────────────────────────────────────────────
$remLJ = @($results | Where-Object { $_.LossReason -eq "LZMA_JANELA" })
if ($remLJ.Count -gt 0) {
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Perdas LZMA_JANELA Restantes")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| ID | Nome | Tipo | Orig | A | C:Py | D:TEIA | D-A | C-A |")
    [void]$sb.AppendLine("|----|------|------|------|---|------|--------|-----|-----|")
    foreach ($r in ($remLJ | Sort-Object { $_.D_Bytes - $_.A_Bytes })) {
        $da    = $r.D_Bytes - $r.A_Bytes
        $caTag = if ($r.C_Bytes -lt 0) { "N/A" } elseif ($r.Delta_CA -le 0) { "$($r.Delta_CA)B" } else { "+$($r.Delta_CA)B" }
        $cStr  = if ($r.C_Bytes -ge 0) { "$($r.C_Bytes)B" } else { "N/A" }
        [void]$sb.AppendLine("| $($r.ID) | $($r.Name) | $($r.Type) | $($r.OrigBytes)B | $($r.A_Bytes)B | $cStr | $($r.D_Bytes)B | +${da}B | $caTag |")
    }
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Savings Totais")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Metrica | Valor |")
[void]$sb.AppendLine("|---------|-------|")
[void]$sb.AppendLine("| Wins v11 | $totalWins/$totalAll |")
[void]$sb.AppendLine("| Net savings (D vs A) | ${totalSaving}B |")
[void]$sb.AppendLine("| SHA-256 roundtrip | $tSha |")
[void]$sb.AppendLine("| Erros | $totalErrors |")

# ── Write==Read ───────────────────────────────────────────────────────────────────
$reportText = $sb.ToString()
$utf8NoBom  = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($REPORT_PATH, $reportText, $utf8NoBom)

$writeSha = [TEIA.Native.TEIANativeV110]::SHA256Hex($utf8NoBom.GetBytes($reportText))
$readBack = [IO.File]::ReadAllBytes($REPORT_PATH)
$readSha  = [TEIA.Native.TEIANativeV110]::SHA256Hex($readBack)
if ($writeSha -ne $readSha) { throw "Write==Read FAIL: write=$writeSha read=$readSha" }

Write-Host ""
Write-Host "[V11] COMPLETO — $REPORT_PATH"
Write-Host "[V11] Relatorio SHA-256: $writeSha"
Write-Host "[V11] $totalWins/$totalAll | saving=${totalSaving}B | SHA-256 $tSha | $totalErrors erros"
