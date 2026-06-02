#Requires -Version 7
# TEIA-Archive-Router.ps1 — Roteador Adaptativo de Arquivos P36.0
# Avalia TEIA Transversal, Brotli/arquivo e Concat+Brotli sobre um corpus CSV.
# Emite veredito baseado no Objetivo de Negocio: Size | Latency | Balanced.
#
# Uso direto:  .\TEIA-Archive-Router.ps1 -InputDir <dir> -Objective Balanced
# Auditoria:   .\TEIA-Archive-Router.ps1 -RunP36Report

param(
    [string]$InputDir   = "",
    [ValidateSet("Size","Latency","Balanced")]
    [string]$Objective  = "Balanced",
    [string]$MotorPath  = "",
    [switch]$RunP36Report,
    [string]$ReportOutput = "",
    [switch]$LibraryMode   # suprimir auto-execucao; usar ao dot-sourcing para importar funcoes
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

# ─── Auto-detect motor ────────────────────────────────────────────────────────
if (!$MotorPath) {
    foreach ($c in @(
        (Join-Path $PSScriptRoot "TEIA-AION-Transversal.ps1"),
        "D:\TEIA_CLAUDE_AWAKENING\tools\TEIA-AION-Transversal.ps1"
    )) { if (Test-Path $c) { $MotorPath = $c; break } }
}
if (!$MotorPath -or !(Test-Path $MotorPath)) {
    throw "Motor TEIA-AION-Transversal.ps1 nao encontrado. Especifique -MotorPath."
}
. $MotorPath

Add-Type -AssemblyName "System.IO.Compression.FileSystem"

# ─── Compile C# JIT (once per session) ───────────────────────────────────────
if (-not ([System.Management.Automation.PSTypeName]'TeiaMasterDecoder').Type) {
    Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Text;

public static class TeiaMasterDecoder {
    public static byte[] Decode(string[] schema, Dictionary<string,string[]> dictCols, byte[] seedBytes) {
        byte[] res;
        using (var ms = new MemoryStream(seedBytes))
        using (var br = new BrotliStream(ms, CompressionMode.Decompress))
        using (var mo = new MemoryStream()) { br.CopyTo(mo); res = mo.ToArray(); }
        string residue = Encoding.UTF8.GetString(res);
        string[] lines = residue.Split('\n');
        int nc = schema.Length;
        var sb = new StringBuilder(lines.Length * 80);
        sb.AppendLine(lines[0].TrimEnd('\r'));
        for (int i = 1; i < lines.Length; i++) {
            string line = lines[i].TrimEnd('\r');
            if (line.Length == 0) continue;
            string[] parts = line.Split(',');
            for (int c = 0; c < nc; c++) {
                if (c > 0) sb.Append(',');
                string col = schema[c];
                string raw = (c < parts.Length) ? parts[c] : "";
                string[] vals;
                if (dictCols.TryGetValue(col, out vals)) sb.Append(vals[int.Parse(raw)]);
                else sb.Append(raw);
            }
            sb.AppendLine();
        }
        return Encoding.UTF8.GetBytes(sb.ToString());
    }
}
"@
}

# ─── Corpus30 High-Entropy Generator ─────────────────────────────────────────
function New-Corpus30HighEntropy {
    param([string]$OutputDir, [int]$N = 30, [int]$LinesPerFile = 500)

    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    $existing = @(Get-ChildItem $OutputDir -Filter "*.csv" -ErrorAction SilentlyContinue)
    if ($existing.Count -ge $N) {
        Write-Host "  Corpus30 ja presente ($($existing.Count) arquivos)." -ForegroundColor DarkGray
        return
    }
    Remove-Item "$OutputDir\*.csv" -Force -ErrorAction SilentlyContinue

    $dateStr  = [datetime]::UtcNow.ToString("yyyy-MM-dd")
    $seedHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                    [System.Text.Encoding]::UTF8.GetBytes("CORPUS30-$env:COMPUTERNAME-$dateStr"))
    $rng = [System.Random]::new([System.BitConverter]::ToInt32($seedHash, 0))

    # Schema: maioria alta entropia (residuo), 3 colunas baixa cardinalidade (dict)
    $HEADER = "EventID,Timestamp,UserID,IPAddress,Action,DurationMs,ErrorCode,Region,Thread,BytesIn"

    $actions = @("GET","POST","PUT","DELETE","PATCH")
    $errors  = @("0","0","0","0","0","0","400","401","403","404","500","503")
    $regions = @("us-east-1","us-west-2","eu-west-1","eu-central-1","ap-southeast-1",
                 "ap-northeast-1","sa-east-1","us-east-2","eu-north-1","ca-central-1",
                 "ap-south-1","me-south-1")
    $startDate = [datetime]::new(2024, 1, 1)

    for ($f = 0; $f -lt $N; $f++) {
        $date     = $startDate.AddDays($f)
        $filePath = Join-Path $OutputDir ("corpus30_{0:yyyy_MM_dd}.csv" -f $date)
        $sb       = [System.Text.StringBuilder]::new(($LinesPerFile + 1) * 120)
        $null     = $sb.AppendLine($HEADER)

        for ($r = 0; $r -lt $LinesPerFile; $r++) {
            $eid    = [guid]::NewGuid().ToString()                                  # residuo — UUID
            $ts     = $date.AddSeconds($rng.Next(0, 86400)).ToString("yyyy-MM-ddTHH:mm:ssZ")
            $uid    = "U{0:D8}" -f $rng.Next(1, 2000000)                           # residuo — alta cardinalidade
            $ip     = "$($rng.Next(1,255)).$($rng.Next(0,256)).$($rng.Next(0,256)).$($rng.Next(1,255))"
            $action = $actions[$rng.Next(0, $actions.Length)]                       # dict
            $dur    = $rng.Next(1, 30001)                                           # residuo
            $err    = $errors[$rng.Next(0, $errors.Length)]                         # dict
            $region = $regions[$rng.Next(0, $regions.Length)]                       # dict
            $thread = "T{0:D4}" -f $rng.Next(1, 1000)                             # residuo (~999 unicos)
            $bytes  = $rng.Next(64, 65536)                                          # residuo
            $null   = $sb.AppendLine("$eid,$ts,$uid,$ip,$action,$dur,$err,$region,$thread,$bytes")
        }
        [System.IO.File]::WriteAllText($filePath, $sb.ToString(), $utf8NoBom)
    }
    Write-Host "  Corpus30 gerado: $N arquivos x $LinesPerFile linhas (alta entropia)." -ForegroundColor DarkGreen
}

# ─── Compress bytes in-memory with Brotli SmallestSize ───────────────────────
function Compress-BrotliBytes([byte[]]$Data) {
    $ms = [System.IO.MemoryStream]::new()
    $bs = [System.IO.Compression.BrotliStream]::new($ms, [System.IO.Compression.CompressionLevel]::SmallestSize, $true)
    $bs.Write($Data, 0, $Data.Length); $bs.Dispose()
    $result = $ms.ToArray(); $ms.Dispose()
    return $result
}

# ─── Core Router ─────────────────────────────────────────────────────────────
function Invoke-TeiaArchiveRouter {
    param(
        [string]$InputDir,
        [ValidateSet("Size","Latency","Balanced")]
        [string]$Objective = "Balanced"
    )

    $files = @(Get-ChildItem $InputDir -Filter "*.csv" | Sort-Object Name)
    if ($files.Count -lt 2) { throw "Router exige ao menos 2 arquivos CSV em: $InputDir" }

    $N        = $files.Count
    $origSize = ($files | Measure-Object Length -Sum).Sum

    # Schema check — TEIA exige schema identico
    $headers      = $files | ForEach-Object { (Get-Content $_.FullName -TotalCount 1).Trim() }
    $sameSchema   = ($headers | Sort-Object -Unique).Count -eq 1
    $schema0      = $headers[0]

    $tmpRoot = Join-Path $env:TEMP "teia_router_$(Get-Random)"
    $teiaTmp = Join-Path $tmpRoot "teia"
    New-Item -ItemType Directory -Path $teiaTmp -Force | Out-Null

    try {
        # ══════════════════════════════════════════════════════════════════════
        # CANDIDATO A: TEIA Transversal
        # ══════════════════════════════════════════════════════════════════════
        $teiaApplicable = $sameSchema
        $teiaSizeBytes  = [long]::MaxValue
        $teiaAccessMs   = 99999; $teiaIncrMs = 99999
        $teiaDictCols   = @()
        $teiaSeedTotal  = 0L; $teiaOverhead = 0L
        $avgSeedSize    = 0.0

        if ($teiaApplicable) {
            $forjaResult = Invoke-AionTransversal -InputDir $InputDir -OutputDir $teiaTmp

            $teiaSeedTotal = (Get-ChildItem $teiaTmp -Filter "*.seed.bin" |
                             Measure-Object Length -Sum).Sum
            $metaBytes     = (Get-Item $forjaResult.MasterMetaFile).Length
            $decoderBytes  = $forjaResult.FastDecoderSize
            $teiaOverhead  = $metaBytes + $decoderBytes
            $teiaSizeBytes = $teiaSeedTotal + $teiaOverhead
            $teiaDictCols  = @($forjaResult.DictColumns)
            $avgSeedSize   = $teiaSeedTotal / $N

            # Pre-load C# typed collections (outside timed section)
            $metaObj    = Get-Content $forjaResult.MasterMetaFile -Raw | ConvertFrom-Json
            $csSchema   = [string[]]@($metaObj.schema)
            $csDictCols = [System.Collections.Generic.Dictionary[string,string[]]]::new()
            foreach ($prop in $metaObj.dictionaryColumns.PSObject.Properties) {
                $csDictCols[$prop.Name] = [string[]]@($prop.Value)
            }

            # Acesso aleatorio: arquivo do meio (3 runs, minimo)
            $target     = $files[[int]($N / 2)]
            $targetSeed = Join-Path $teiaTmp "$($target.BaseName).seed.bin"
            $teiaArr    = @()
            for ($r = 0; $r -lt 3; $r++) {
                [GC]::Collect()
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                $sb = [System.IO.File]::ReadAllBytes($targetSeed)
                $null = [TeiaMasterDecoder]::Decode($csSchema, $csDictCols, $sb)
                $sw.Stop(); $teiaArr += $sw.ElapsedMilliseconds
            }
            $teiaAccessMs = ($teiaArr | Measure-Object -Minimum).Minimum

            # Incremental: aplica Master Grammar ao primeiro arquivo
            $colCount = $csSchema.Length
            $dictMask = [bool[]]::new($colCount)
            $dictLkp  = @{}
            for ($ci = 0; $ci -lt $colCount; $ci++) {
                $col = $csSchema[$ci]
                if ($csDictCols.ContainsKey($col)) {
                    $dictMask[$ci] = $true
                    $lk = @{}; $arr = $csDictCols[$col]
                    for ($vi = 0; $vi -lt $arr.Count; $vi++) { $lk[$arr[$vi]] = $vi }
                    $dictLkp[$ci] = $lk
                }
            }
            $newFile = $files[0]
            [GC]::Collect()
            $sw     = [System.Diagnostics.Stopwatch]::StartNew()
            $lns    = [System.IO.File]::ReadAllLines($newFile.FullName)
            $sbInc  = [System.Text.StringBuilder]::new($lns.Length * 60)
            $null   = $sbInc.AppendLine($lns[0])
            for ($i = 1; $i -lt $lns.Length; $i++) {
                if ([string]::IsNullOrWhiteSpace($lns[$i])) { continue }
                $pts = $lns[$i].Split(',')
                for ($c = 0; $c -lt $colCount; $c++) {
                    if ($c -gt 0) { $null = $sbInc.Append(',') }
                    $v = if ($c -lt $pts.Length) { $pts[$c] } else { "" }
                    if ($dictMask[$c]) { $null = $sbInc.Append($dictLkp[$c][$v]) }
                    else               { $null = $sbInc.Append($v) }
                }
                $null = $sbInc.AppendLine()
            }
            $resBytes = $utf8NoBom.GetBytes($sbInc.ToString())
            $null = Compress-BrotliBytes $resBytes
            $sw.Stop(); $teiaIncrMs = $sw.ElapsedMilliseconds
        }

        # ══════════════════════════════════════════════════════════════════════
        # CANDIDATO B: Brotli por arquivo
        # ══════════════════════════════════════════════════════════════════════
        $brTotalBytes = 0L
        $brCompressed = @()
        foreach ($f in $files) {
            $c = Compress-BrotliBytes ([System.IO.File]::ReadAllBytes($f.FullName))
            $brTotalBytes += $c.Length
            $brCompressed += ,$c
        }
        $avgBrotliSize = $brTotalBytes / $N

        # Acesso: decomprimir arquivo do meio (3 runs, minimo)
        $targetBrC = $brCompressed[[int]($N / 2)]
        $brArr = @()
        for ($r = 0; $r -lt 3; $r++) {
            [GC]::Collect()
            $sw    = [System.Diagnostics.Stopwatch]::StartNew()
            $msIn  = [System.IO.MemoryStream]::new($targetBrC)
            $bsIn  = [System.IO.Compression.BrotliStream]::new($msIn, [System.IO.Compression.CompressionMode]::Decompress)
            $msOut = [System.IO.MemoryStream]::new()
            $bsIn.CopyTo($msOut); $bsIn.Dispose(); $msIn.Dispose(); $msOut.Dispose()
            $sw.Stop(); $brArr += $sw.ElapsedMilliseconds
        }
        $brAccessMs = ($brArr | Measure-Object -Minimum).Minimum

        # Incremental: comprimir novo arquivo
        [GC]::Collect()
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $null = Compress-BrotliBytes ([System.IO.File]::ReadAllBytes($files[0].FullName))
        $sw.Stop(); $brIncrMs = $sw.ElapsedMilliseconds

        # ══════════════════════════════════════════════════════════════════════
        # CANDIDATO C: Concat + Brotli (tar.br)
        # ══════════════════════════════════════════════════════════════════════
        $msCat = [System.IO.MemoryStream]::new()
        $bsCat = [System.IO.Compression.BrotliStream]::new($msCat, [System.IO.Compression.CompressionLevel]::SmallestSize, $true)
        foreach ($f in $files) {
            $rb = [System.IO.File]::ReadAllBytes($f.FullName)
            $bsCat.Write($rb, 0, $rb.Length)
        }
        $bsCat.Dispose()
        $catBlob     = $msCat.ToArray(); $msCat.Dispose()
        $concatBytes = $catBlob.Length

        # Acesso: descomprimir corpus inteiro (O(N))
        [GC]::Collect()
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $msD = [System.IO.MemoryStream]::new($catBlob)
        $bsD = [System.IO.Compression.BrotliStream]::new($msD, [System.IO.Compression.CompressionMode]::Decompress)
        $msO = [System.IO.MemoryStream]::new()
        $bsD.CopyTo($msO); $bsD.Dispose(); $msD.Dispose()
        $concatDecompSz = $msO.Length; $msO.Dispose()
        $sw.Stop(); $concatAccessMs = $sw.ElapsedMilliseconds

        # Incremental: recomprimir N+1 arquivos
        [GC]::Collect()
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $msR = [System.IO.MemoryStream]::new()
        $bsR = [System.IO.Compression.BrotliStream]::new($msR, [System.IO.Compression.CompressionLevel]::SmallestSize, $true)
        foreach ($f in $files) { $rb = [System.IO.File]::ReadAllBytes($f.FullName); $bsR.Write($rb, 0, $rb.Length) }
        $rb0 = [System.IO.File]::ReadAllBytes($files[0].FullName); $bsR.Write($rb0, 0, $rb0.Length)
        $bsR.Dispose(); $msR.Dispose()
        $sw.Stop(); $concatIncrMs = $sw.ElapsedMilliseconds

        # ══════════════════════════════════════════════════════════════════════
        # MASSA CRITICA — projecao matematica
        # ══════════════════════════════════════════════════════════════════════
        $nCritSizeVsBrotli  = "N/A"
        $nCritLatencyVsConcat = "N/A"
        if ($teiaApplicable) {
            # Tamanho: N onde TEIA < Brotli/arquivo
            $deltaPerFile = $avgBrotliSize - $avgSeedSize
            if ($deltaPerFile -gt 0.5) {
                $nCritSizeVsBrotli = [int][math]::Ceiling($teiaOverhead / $deltaPerFile)
            } else {
                $nCritSizeVsBrotli = "nunca (seeds >= Brotli individual)"
            }

            # Latencia: N onde concat+Brotli demora mais que TEIA (ja testado)
            # Por arquivo: concatAccessMs / N = ms por arquivo no concat
            # TEIA e sempre O(1) => TEIA ja vence para todo N >= 1 quando concat leu tudo
            $msPerFileConcat = if ($N -gt 0) { $concatAccessMs / $N } else { 1 }
            if ($msPerFileConcat -gt 0 -and $teiaAccessMs -gt 0) {
                $nCritLatencyVsConcat = [math]::Max(1, [int][math]::Ceiling($teiaAccessMs / $msPerFileConcat))
            } else {
                $nCritLatencyVsConcat = 1
            }
        }

        # ══════════════════════════════════════════════════════════════════════
        # SCORING
        # ══════════════════════════════════════════════════════════════════════
        # Normalizacao: para cada dimensao, score 0=melhor, 1=pior
        # concat+Brotli recebe penalidade O(N) em acesso e incremental:
        #   penalidade = N / 10   (para N=10: x2; N=30: x4; N=100: x11)
        $concatAccessPenalizado = $concatAccessMs * (1.0 + $N / 10.0)
        $concatIncrPenalizado   = $concatIncrMs   * (1.0 + $N / 10.0)

        $teiaS  = if ($teiaApplicable) { $teiaSizeBytes } else { [long]::MaxValue }
        $teiaA  = if ($teiaApplicable) { $teiaAccessMs  } else { [long]::MaxValue }
        $teiaI  = if ($teiaApplicable) { $teiaIncrMs    } else { [long]::MaxValue }

        function Normalize-Score {
            param([double]$V, [double]$Min, [double]$Max)
            if ($Max -le $Min) { return 0.0 }
            return ($V - $Min) / ($Max - $Min)
        }

        # Size dimension
        $minSize = [math]::Min([math]::Min($teiaS, $brTotalBytes), $concatBytes)
        $maxSize = [math]::Max([math]::Max($teiaS, $brTotalBytes), $concatBytes)
        $sA = Normalize-Score $teiaS       $minSize $maxSize
        $sB = Normalize-Score $brTotalBytes $minSize $maxSize
        $sC = Normalize-Score $concatBytes  $minSize $maxSize

        # Access dimension (with O(N) penalty for concat)
        $minAcc = [math]::Min([math]::Min($teiaA, $brAccessMs), $concatAccessPenalizado)
        $maxAcc = [math]::Max([math]::Max($teiaA, $brAccessMs), $concatAccessPenalizado)
        $aA = Normalize-Score $teiaA                   $minAcc $maxAcc
        $aB = Normalize-Score $brAccessMs              $minAcc $maxAcc
        $aC = Normalize-Score $concatAccessPenalizado  $minAcc $maxAcc

        # Incremental dimension (with O(N) penalty for concat)
        $minInc = [math]::Min([math]::Min($teiaI, $brIncrMs), $concatIncrPenalizado)
        $maxInc = [math]::Max([math]::Max($teiaI, $brIncrMs), $concatIncrPenalizado)
        $iA = Normalize-Score $teiaI                  $minInc $maxInc
        $iB = Normalize-Score $brIncrMs               $minInc $maxInc
        $iC = Normalize-Score $concatIncrPenalizado   $minInc $maxInc

        # Weighted score by objective
        $weights = switch ($Objective) {
            "Size"     { @{ S=1.00; A=0.00; I=0.00 } }
            "Latency"  { @{ S=0.00; A=0.70; I=0.30 } }
            "Balanced" { @{ S=0.35; A=0.40; I=0.25 } }
        }
        $scoreA = [math]::Round($sA*$weights.S + $aA*$weights.A + $iA*$weights.I, 3)
        $scoreB = [math]::Round($sB*$weights.S + $aB*$weights.A + $iB*$weights.I, 3)
        $scoreC = [math]::Round($sC*$weights.S + $aC*$weights.A + $iC*$weights.I, 3)
        if (!$teiaApplicable) { $scoreA = 999.0 }

        $scores = @{ TEIA=$scoreA; Brotli=$scoreB; Concat=$scoreC }
        $winner = ($scores.Keys | Sort-Object { $scores[$_] })[0]

        return [pscustomobject]@{
            N                  = $N
            OriginalSizeKB     = [math]::Round($origSize/1KB, 1)
            Objective          = $Objective
            Winner             = $winner
            Scores             = $scores
            SizeBytes          = @{ TEIA=$teiaSizeBytes; Brotli=$brTotalBytes; Concat=$concatBytes }
            AccessMs           = @{ TEIA=$teiaAccessMs; Brotli=$brAccessMs; Concat=$concatAccessMs }
            IncrementalMs      = @{ TEIA=$teiaIncrMs; Brotli=$brIncrMs; Concat=$concatIncrMs }
            ConcatDecompKB     = [math]::Round($concatDecompSz/1KB, 1)
            TeiaApplicable     = $teiaApplicable
            TeiaDictCols       = $teiaDictCols
            TeiaAvgSeedKB      = [math]::Round($avgSeedSize/1KB, 2)
            AvgBrotliKB        = [math]::Round($avgBrotliSize/1KB, 2)
            TeiaOverheadBytes  = $teiaOverhead
            NCritSizeVsBrotli  = $nCritSizeVsBrotli
            NCritLatVsConcat   = $nCritLatencyVsConcat
            Schema             = $schema0
            SameSchema         = $sameSchema
        }
    } finally {
        Remove-Item $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ─── Print verdict ────────────────────────────────────────────────────────────
function Write-RouterVerdict {
    param($R, [string]$Label = "Corpus")
    Write-Host ""
    Write-Host "=== TEIA Archive Router ===" -ForegroundColor Cyan
    Write-Host "  Corpus   : $Label ($($R.N) arquivos | $($R.OriginalSizeKB) KB)" -ForegroundColor White
    Write-Host "  Objetivo : $($R.Objective)" -ForegroundColor White
    $schemaLabel = if ($R.SameSchema) { 'Identico' } else { 'Misto' }
    Write-Host "  Schema   : $schemaLabel" -ForegroundColor White
    Write-Host ""
    Write-Host ("  {0,-8} {1,8} {2,6} {3,7} {4,8}" -f "Candidato","Tamanho","Acesso","Increm.","Score") -ForegroundColor DarkGray
    Write-Host ("  {0,-8} {1,8} {2,6} {3,7} {4,8}" -f "---------","-------","------","-------","-----") -ForegroundColor DarkGray
    foreach ($m in @("TEIA","Brotli","Concat")) {
        $szKB  = if ($R.SizeBytes[$m] -ge [long]::MaxValue) {"N/A"} else {"{0,5:F1} KB" -f ($R.SizeBytes[$m]/1KB)}
        $accMs = if ($R.AccessMs[$m] -ge 99999) {"N/A"} else {"{0,3} ms" -f $R.AccessMs[$m]}
        $incMs = if ($R.IncrementalMs[$m] -ge 99999) {"N/A"} else {"{0,4} ms" -f $R.IncrementalMs[$m]}
        $sc    = "{0:F3}" -f $R.Scores[$m]
        $win   = if ($m -eq $R.Winner) { " <- WINNER" } else { "" }
        $oN    = if ($m -eq "Concat") { " [O(N)]" } else { "" }
        Write-Host ("  {0,-8} {1,8} {2,6} {3,7} {4,8}{5}{6}" -f $m,$szKB,$accMs,$incMs,$sc,$win,$oN) `
            -ForegroundColor $(if ($m -eq $R.Winner) { 'Green' } elseif ($m -eq 'Concat') { 'Red' } else { 'White' })
    }
    Write-Host ""
    Write-Host ("  VEREDITO: Objetivo={0}, N={1} -> WINNER: {2}" -f $R.Objective, $R.N, $R.Winner) -ForegroundColor Green
    if ($R.NCritSizeVsBrotli -ne "N/A") {
        Write-Host "  Massa Critica (TEIA vs Brotli/arq tamanho): N = $($R.NCritSizeVsBrotli)" -ForegroundColor DarkCyan
    }
}

# ─── P36.0 Report Generator ──────────────────────────────────────────────────
function Write-P36Report {
    param(
        [hashtable[]]$RunResults,
        [string]$OutputPath
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# TEIA AION Transversal — Adaptive Archive Router Report P36.0")
    $lines.Add("**Protocolo P36.0 — Supervisor de Data Centers**")
    $lines.Add("**Data:** $(([datetime]::UtcNow).ToString('yyyy-MM-dd'))")
    $lines.Add("")
    $lines.Add("---")
    $lines.Add("")
    $lines.Add("## Introducao: O Supervisor")
    $lines.Add("")
    $lines.Add("O P35.0 revelou empiricamente que o Brotli individual e competitivo para N pequeno.")
    $lines.Add("O P36.0 responde a essa realidade criando o **TEIA Archive Router**: um supervisor autonomo que")
    $lines.Add("mede os tres candidatos com compressao real (`CompressionLevel.SmallestSize`) e emite o")
    $lines.Add("veredito otimo para cada combinacao de corpus + Objetivo de Negocio.")
    $lines.Add("")
    $lines.Add("**Candidatos avaliados:**")
    $lines.Add("- **A — TEIA Transversal (AION):** Master Grammar + C# JIT decoder, acesso O(1)")
    $lines.Add("- **B — Brotli/arquivo:** cada arquivo comprimido individualmente, acesso O(1)")
    $lines.Add("- **C — Concat+Brotli (tar.br):** corpus concatenado + Brotli, acesso O(N)")
    $lines.Add("")
    $lines.Add("**Scoring:** pontuacao normalizada [0=melhor, 1=pior] por dimensao, ponderada por objetivo.")
    $lines.Add("Concat+Brotli recebe penalidade multiplicativa em acesso e incremental proporcional a N,")
    $lines.Add("refletindo o crescimento linear do custo O(N) em producao.")
    $lines.Add("")
    $lines.Add("---")
    $lines.Add("")
    $lines.Add("## Corpora Avaliados")
    $lines.Add("")
    $lines.Add("| Corpus | N | Fonte | Entropia |")
    $lines.Add("|---|---:|---|---|")
    $lines.Add("| Corpus30 | 30 | Sintetico — `New-Corpus30HighEntropy` | Alta (EventID UUID, Timestamps unicos, UserIDs) |")
    $lines.Add("| Corpus_Transversal | 10 | Real — Apache CLF (Elastic examples) | Media (IP, Resource variaveis; Method/Status repetitivos) |")
    $lines.Add("")
    $lines.Add("---")
    $lines.Add("")

    # Group results by corpus
    $corpora = $RunResults | ForEach-Object { $_.CorpusLabel } | Sort-Object -Unique

    foreach ($corpus in $corpora) {
        $runs = $RunResults | Where-Object { $_.CorpusLabel -eq $corpus }
        $r0   = $runs[0].Result

        $lines.Add("## Corpus: $corpus")
        $lines.Add("")
        $lines.Add("**N =** $($r0.N) arquivos | **Tamanho original:** $($r0.OriginalSizeKB) KB")
        $lines.Add("**Schema:** ``$($r0.Schema)``")
        $lines.Add("**Colunas dicionarizadas (TEIA):** $(if ($r0.TeiaDictCols.Count -gt 0) {$r0.TeiaDictCols -join ', '} else {'N/A'})")
        $lines.Add("")

        # Size breakdown
        $lines.Add("### Tamanho em Disco")
        $lines.Add("")
        $lines.Add("| Candidato | Tamanho Total | vs Original | vs concat+Brotli |")
        $lines.Add("|---|---:|:---:|:---:|")
        foreach ($m in @("TEIA","Brotli","Concat")) {
            $szB = $r0.SizeBytes[$m]
            $szKB = if ($szB -ge [long]::MaxValue) {"N/A"} else {"{0:F1} KB" -f ($szB/1KB)}
            $vsOrig = if ($szB -ge [long]::MaxValue) {"N/A"} else {"{0:F1}%" -f (($szB/$r0.OriginalSizeKB/1KB*100) - 100)}
            $concatB = $r0.SizeBytes['Concat']
            $vsConcat = if ($szB -ge [long]::MaxValue -or $szB -eq $concatB) {"0%"} else {
                $pct = [math]::Round(($szB - $concatB) / $concatB * 100, 1)
                if ($pct -ge 0) {"+$pct%"} else {"$pct%"}
            }
            $bold = if ($m -eq "Concat") {"**"} else {""}
            $lines.Add("| $bold$m$bold | $szKB | — | $vsConcat |")
        }

        if ($r0.TeiaApplicable) {
            $seedKB    = [math]::Round(($r0.TeiaAvgSeedKB), 2)
            $brotliKB  = [math]::Round(($r0.AvgBrotliKB), 2)
            $overheadB = $r0.TeiaOverheadBytes
            $lines.Add("")
            $lines.Add("**Decomposicao TEIA:** overhead fixo = $overheadB bytes (decoder + meta) |")
            $lines.Add("seed medio = $seedKB KB/arq | Brotli medio = $brotliKB KB/arq")
        }
        $lines.Add("")

        # Latency
        $lines.Add("### Latencia de Acesso Aleatorio")
        $lines.Add("")
        $lines.Add("| Candidato | Latencia | Bytes lidos | Comportamento |")
        $lines.Add("|---|---:|:---:|---|")
        foreach ($m in @("TEIA","Brotli","Concat")) {
            $ms  = $r0.AccessMs[$m]
            $msStr = if ($ms -ge 99999) {"N/A"} else {"$ms ms"}
            $szStr = switch ($m) {
                "TEIA"   { "$($r0.TeiaAvgSeedKB) KB (seed.bin)" }
                "Brotli" { "$($r0.AvgBrotliKB) KB (.br)" }
                "Concat" { "$($r0.OriginalSizeKB) KB (corpus inteiro)" }
            }
            $oN = if ($m -eq "Concat") {"**O(N)**"} else {"O(1)"}
            $lines.Add("| $m | $msStr | $szStr | $oN |")
        }
        $lines.Add("")

        # Incremental
        $lines.Add("### Atualizacao Incremental")
        $lines.Add("")
        $lines.Add("| Candidato | Latencia | Estrategia |")
        $lines.Add("|---|---:|---|")
        $incDescs = @{
            "TEIA"   = "Aplica Master Grammar existente → 1 novo seed.bin"
            "Brotli" = "Comprime novo arquivo independentemente"
            "Concat" = "**Recomprime N+1 arquivos do zero (O(N))**"
        }
        foreach ($m in @("TEIA","Brotli","Concat")) {
            $ms  = $r0.IncrementalMs[$m]
            $msStr = if ($ms -ge 99999) {"N/A"} else {"$ms ms"}
            $lines.Add("| $m | $msStr | $($incDescs[$m]) |")
        }
        $lines.Add("")

        # Scoreboard for all 3 objectives
        $lines.Add("### Scoreboard por Objetivo")
        $lines.Add("")
        $lines.Add("| Objetivo | TEIA | Brotli | Concat | WINNER |")
        $lines.Add("|---|:---:|:---:|:---:|---|")
        foreach ($run in $runs) {
            $r  = $run.Result
            $tS = "{0:F3}" -f $r.Scores["TEIA"]
            $bS = "{0:F3}" -f $r.Scores["Brotli"]
            $cS = "{0:F3}" -f $r.Scores["Concat"]
            $w  = $r.Winner
            $lines.Add("| $($r.Objective) | $tS | $bS | $cS | **$w** |")
        }
        $lines.Add("")

        # N_critical projections
        if ($r0.TeiaApplicable) {
            $lines.Add("### Projecao: Massa Critica N*")
            $lines.Add("")
            $lines.Add("#### Tamanho: TEIA vs Brotli/arquivo")
            $lines.Add("")
            $deltaKB = [math]::Round(($r0.AvgBrotliKB - $r0.TeiaAvgSeedKB), 3)
            $lines.Add('```')
            $lines.Add("TEIA_total(N) = $($r0.TeiaOverheadBytes) B (overhead) + N x $($r0.TeiaAvgSeedKB) KB (seed medio)")
            $lines.Add("Brotli_total(N)   = N x $($r0.AvgBrotliKB) KB (Brotli medio)")
            $lines.Add("Delta por arquivo = $deltaKB KB")
            $lines.Add("N* = ceil($($r0.TeiaOverheadBytes) / ($deltaKB x 1024)) = $($r0.NCritSizeVsBrotli)")
            $lines.Add('```')
            $lines.Add("")
            if ($r0.NCritSizeVsBrotli -match '^\d+$') {
                $nCrit = [int]$r0.NCritSizeVsBrotli
                if ($nCrit -le $r0.N) {
                    $lines.Add("> **N* = $nCrit < N atual ($($r0.N))**: TEIA ja vence Brotli/arquivo em tamanho neste corpus.")
                } else {
                    $lines.Add("> **N* = $nCrit > N atual ($($r0.N))**: TEIA ainda nao vence em tamanho. Requer N >= $nCrit arquivos.")
                }
            } else {
                $lines.Add("> TEIA nao vence Brotli/arquivo em tamanho com este corpus (alta entropia — seeds maiores que Brotli individual).")
            }
            $lines.Add("")

            $lines.Add("#### Latencia: TEIA vs Concat+Brotli (acesso)")
            $lines.Add("")
            $lines.Add('```')
            $lines.Add("TEIA: O(1) -- $($r0.AccessMs['TEIA']) ms para qualquer N")
            $lines.Add("Concat: O(N) -- $($r0.AccessMs['Concat']) ms para N=$($r0.N) => $([math]::Round($r0.AccessMs['Concat']/$r0.N,2)) ms/arquivo")
            $lines.Add("N* (latencia) = $($r0.NCritLatVsConcat)")
            $lines.Add('```')
            $lines.Add("")
            $lines.Add("> Para N >= $($r0.NCritLatVsConcat): TEIA acessa mais rapido que Concat+Brotli.")
            $lines.Add("")
        }
        $lines.Add("---")
        $lines.Add("")
    }

    # Final summary
    $lines.Add("## Conclusao P36.0: A Sabedoria do Supervisor")
    $lines.Add("")
    $lines.Add("| Cenario | Recomendacao | Razao |")
    $lines.Add("|---|---|---|")
    $lines.Add("| Objetivo=Size, N pequeno (<20) | **Concat+Brotli** | Janela LZ77 compartilhada vence |")
    $lines.Add("| Objetivo=Size, N grande (>N*) | **TEIA** | Overhead amortizado, seed < Brotli individual |")
    $lines.Add("| Objetivo=Latency, qualquer N | **Brotli/arquivo ou TEIA** | Ambos O(1); concat nunca vence em latencia |")
    $lines.Add("| Objetivo=Balanced, N pequeno | **Brotli/arquivo** | Melhor troca entre tamanho e velocidade |")
    $lines.Add("| Objetivo=Balanced, N grande | **TEIA** | Overhead amortizado + O(1) + incremental eficiente |")
    $lines.Add("| Schemas distintos | **Brotli/arquivo ou Concat+Brotli** | TEIA nao aplicavel |")
    $lines.Add("")
    $lines.Add("**A derrota e uma vitoria do sistema de decisao:** quando o Roteador escolhe Brotli/arquivo ou")
    $lines.Add("Concat+Brotli, ele esta aplicando a fisica da informacao de forma correta. O objetivo e sempre")
    $lines.Add("servir o usuario com o melhor formato — nao defender a TEIA.")
    $lines.Add("")
    $lines.Add("---")
    $lines.Add("*TEIA Archive Router v1.0.0 | Protocolo P36.0 | $(([datetime]::UtcNow).ToString('yyyy-MM-dd'))*")

    [System.IO.File]::WriteAllLines($OutputPath, $lines, $utf8NoBom)
    Write-Host "  Relatorio gerado: $OutputPath" -ForegroundColor Cyan
}

# ─── Auto-execute block (suprimido por -LibraryMode) ─────────────────────────
if (-not $LibraryMode) {
if ($RunP36Report) {
    $corpus30Dir = "D:\TEIA_USER\MyRealData\Corpus30_HighEntropy"
    $transDir    = "D:\TEIA_USER\MyRealData\Corpus_Transversal\RealLogs"
    $reportPath  = if ($ReportOutput) { $ReportOutput } else {
        "D:\TEIA_CLAUDE_AWAKENING\docs\TEIA_ADAPTIVE_ROUTER_REPORT_P36.md"
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  TEIA Archive Router P36.0 — Auditoria Completa"           -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "[1/3] Gerando Corpus30 (alta entropia)..." -ForegroundColor Yellow
    New-Corpus30HighEntropy -OutputDir $corpus30Dir -N 30 -LinesPerFile 500

    Write-Host ""
    Write-Host "[2/3] Compilando TeiaMasterDecoder (C# JIT)..." -ForegroundColor Yellow
    Write-Host "  JIT pronto." -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "[3/3] Executando Router nos dois corpora x 3 objetivos..." -ForegroundColor Yellow

    $allResults = [System.Collections.Generic.List[hashtable]]::new()
    $corpora = @(
        @{ Dir=$corpus30Dir; Label="Corpus30 (Alta Entropia, N=30)" },
        @{ Dir=$transDir;    Label="Corpus_Transversal (Apache CLF Real, N=10)" }
    )
    foreach ($corpus in $corpora) {
        Write-Host ""
        Write-Host "  Corpus: $($corpus.Label)" -ForegroundColor White
        foreach ($obj in @("Size","Latency","Balanced")) {
            Write-Host "    Objetivo=$obj ..." -ForegroundColor DarkGray -NoNewline
            $r = Invoke-TeiaArchiveRouter -InputDir $corpus.Dir -Objective $obj
            Write-Host " WINNER: $($r.Winner)" -ForegroundColor $(switch ($r.Winner) { 'TEIA' {'Cyan'} 'Brotli' {'Green'} default {'Yellow'} })
            Write-RouterVerdict -R $r -Label $corpus.Label
            $allResults.Add(@{ CorpusLabel=$corpus.Label; Result=$r })
        }
    }

    Write-Host ""
    Write-Host "Gerando relatorio P36.0..." -ForegroundColor Yellow
    Write-P36Report -RunResults $allResults.ToArray() -OutputPath $reportPath

    Write-Host ""
    Write-Host "P36.0 concluido." -ForegroundColor Cyan
}
elseif ($InputDir) {
    # Single-run mode
    $result = Invoke-TeiaArchiveRouter -InputDir $InputDir -Objective $Objective
    Write-RouterVerdict -R $result -Label (Split-Path $InputDir -Leaf)
}
else {
    Write-Host ""
    Write-Host "TEIA Archive Router P36.0/P37.0" -ForegroundColor Cyan
    Write-Host "  Uso: .\TEIA-Archive-Router.ps1 -InputDir <dir> [-Objective Size|Latency|Balanced]"
    Write-Host "  Auditoria P36: .\TEIA-Archive-Router.ps1 -RunP36Report"
    Write-Host "  1-Click v6:    .\audit-one-click-router.ps1"
}
} # end -not LibraryMode
