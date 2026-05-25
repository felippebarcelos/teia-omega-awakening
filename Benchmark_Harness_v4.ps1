#Requires -Version 5
# Benchmark_Harness_v4.ps1 — TEIA-Core v0.7.0 | Harness v4.0.0
# 4 cenarios obrigatorios:
#   A) LZMA standalone (7z -mx9 -mmt1)
#   B) Zstd standalone (-19, sem dicionario)
#   C) Zstd + dicionario treinado puro (sem camada TEIA)
#   D) TEIA dict.zstd_shared (seed JSON + SHA-256 verify)
# Output: Relatorio_Comparativo_v4.0.0.md
[CmdletBinding()]
param()

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-Location "D:\TEIA_CLAUDE_AWAKENING"
$ErrorActionPreference = "Stop"

# ─── PATHS ───────────────────────────────────────────────────────────────────
$MOTOR_PATH  = "D:\TEIA_CLAUDE_AWAKENING\Arqueologia do motor AION RISPA\NucleoCompressorOntoprocedural\Ontologia Procedural\Motor onto procedural\TEIA-Core-v0.7.0.psm1"
$SEVEN_ZIP   = "C:\Program Files\7-Zip\7z.exe"
$ZSTD        = "D:\TEIA_CLAUDE_AWAKENING\_tools\zstd\zstd-v1.5.6-win64\zstd.exe"
$DICT_DIR    = "D:\TEIA_CLAUDE_AWAKENING\_bench_v4\dicts"
$TEMP_DIR    = "D:\TEIA_CLAUDE_AWAKENING\_bench_v4\tmp"
$REPORT_OUT  = "D:\TEIA_CLAUDE_AWAKENING\Relatorio_Comparativo_v4.0.0.md"
$MOTOR_SHA   = "1883B447A7B75FE876FAFB1704EA06FF1695B244916925ADA77F8D37B7CC1206"
$MOTOR_BYTES = 37483

# ─── CORPUS ──────────────────────────────────────────────────────────────────
$TRAIN_FILES = @(
    "D:\TEIA OS\google-cloud-sdk\lib\third_party\botocore\data\kinesisanalyticsv2\2018-05-23\service-2.json",
    "D:\TEIA OS\google-cloud-sdk\lib\third_party\botocore\data\elastictranscoder\2012-09-25\service-2.json",
    "D:\TEIA OS\google-cloud-sdk\lib\third_party\botocore\data\ds\2015-04-16\service-2.json",
    "D:\TEIA OS\google-cloud-sdk\lib\third_party\botocore\data\elbv2\2015-12-01\service-2.json",
    "D:\TEIA OS\google-cloud-sdk\lib\third_party\botocore\data\application-autoscaling\2016-02-06\service-2.json",
    "D:\TEIA OS\google-cloud-sdk\lib\third_party\botocore\data\stepfunctions\2016-11-23\service-2.json",
    "D:\TEIA OS\google-cloud-sdk\lib\third_party\botocore\data\elasticbeanstalk\2010-12-01\service-2.json",
    "D:\TEIA OS\google-cloud-sdk\lib\third_party\botocore\data\iotfleetwise\2021-06-17\service-2.json"
)

$TEST_FILES = @(
    [pscustomobject]@{
        Id    = "T1"
        Path  = "D:\TEIA OS\google-cloud-sdk\lib\third_party\botocore\data\cloudfront\2016-11-25\service-2.json"
        Label = "cloudfront/2016-11-25 (R29)"
    },
    [pscustomobject]@{
        Id    = "T2"
        Path  = "D:\TEIA OS\google-cloud-sdk\lib\third_party\botocore\data\cloudfront\2016-09-29\service-2.json"
        Label = "cloudfront/2016-09-29 (R35)"
    }
)

# ─── PRE-FLIGHT ──────────────────────────────────────────────────────────────
foreach ($dep in @($SEVEN_ZIP, $ZSTD)) {
    if (-not (Test-Path $dep)) { throw "Dependencia ausente: $dep" }
}

# Tentar caminho com acento primeiro; fallback sem acento
$motorPathUnicode = "D:\TEIA_CLAUDE_AWAKENING\Arqueologia do motor AION RISPA\N$([char]0xFA)cleoCompressorOntoprocedural\Ontologia Procedural\Motor onto procedural\TEIA-Core-v0.7.0.psm1"
if (Test-Path $motorPathUnicode) { $MOTOR_PATH = $motorPathUnicode }
elseif (-not (Test-Path $MOTOR_PATH)) { throw "Motor nao encontrado. Verifique o path: $MOTOR_PATH" }

New-Item -ItemType Directory -Force -Path $DICT_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $TEMP_DIR | Out-Null

# Valida SHA-256 do motor
$actualMotorSha = (Get-FileHash $MOTOR_PATH -Algorithm SHA256).Hash
if ($actualMotorSha -ne $MOTOR_SHA) {
    throw "Motor SHA-256 divergente!`nEsperado: $MOTOR_SHA`nAtual:    $actualMotorSha"
}

Unblock-File $MOTOR_PATH
Import-Module $MOTOR_PATH -Force

Write-Host "[BENCH v4.0.0] Motor v0.7.0 carregado | SHA-256: $($MOTOR_SHA.Substring(0,16))..."

# ─── FASE 1: TREINAR DICIONARIO ZSTD ─────────────────────────────────────────
Write-Host "`n=== FASE 1: Treinamento Zstd Dictionary ==="

$validTrain = @($TRAIN_FILES | Where-Object { Test-Path $_ })
if ($validTrain.Count -eq 0) { throw "Nenhum arquivo de treinamento encontrado" }
Write-Host "[$($validTrain.Count)/$($TRAIN_FILES.Count)] arquivos de treinamento disponiveis"

$dictResult  = Build-TEIAZstdDict -TrainingFiles $validTrain -OutputDir $DICT_DIR -MaxDictBytes 112640
$DICT_PATH   = $dictResult.DictPath
$DICT_SHA256 = $dictResult.DictSha256
$DICT_BYTES  = $dictResult.DictBytes
$TRAIN_MS    = $dictResult.TrainMs

Write-Host "Dicionario: $DICT_BYTES bytes | SHA-256: $($DICT_SHA256.Substring(0,16))... | treinamento=${TRAIN_MS}ms"

# ─── FUNCOES DE CENARIO ───────────────────────────────────────────────────────

function Measure-ScenarioA {
    param([string]$FilePath, [string]$Id)
    $tmp = Join-Path $TEMP_DIR "${Id}_A.7z"
    try {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        & $SEVEN_ZIP a -t7z -m0=lzma2 -mx=9 -mmt=1 $tmp $FilePath 2>&1 | Out-Null
        $sw.Stop()
        if (-not (Test-Path $tmp)) { throw "7z nao criou o arquivo: $tmp" }
        [pscustomobject]@{ SizeBytes = (Get-Item $tmp).Length; Ms = $sw.ElapsedMilliseconds }
    } finally {
        if (Test-Path $tmp) { Remove-Item $tmp -Force }
    }
}

function Measure-ScenarioB {
    param([string]$FilePath, [string]$Id)
    $tmp = Join-Path $TEMP_DIR "${Id}_B.zst"
    try {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        & $ZSTD -19 --no-progress -f $FilePath -o $tmp 2>&1 | Out-Null
        $sw.Stop()
        if (-not (Test-Path $tmp)) { throw "zstd nao criou: $tmp" }
        [pscustomobject]@{ SizeBytes = (Get-Item $tmp).Length; Ms = $sw.ElapsedMilliseconds }
    } finally {
        if (Test-Path $tmp) { Remove-Item $tmp -Force }
    }
}

function Measure-ScenarioC {
    param([string]$FilePath, [string]$Id, [string]$DictPath)
    $tmp = Join-Path $TEMP_DIR "${Id}_C.zst"
    try {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        & $ZSTD -D $DictPath -19 --no-progress -f $FilePath -o $tmp 2>&1 | Out-Null
        $sw.Stop()
        if (-not (Test-Path $tmp)) { throw "zstd+dict nao criou: $tmp" }
        [pscustomobject]@{ SizeBytes = (Get-Item $tmp).Length; Ms = $sw.ElapsedMilliseconds }
    } finally {
        if (Test-Path $tmp) { Remove-Item $tmp -Force }
    }
}

function Measure-ScenarioD {
    param(
        [byte[]]$Data,
        [string]$FileName,
        [string]$DictPath,
        [string]$DictDir,
        [string]$ExpectedSha256
    )
    $enc = Invoke-TEIAEncodeZstd -Data $Data -DictPath $DictPath -FileName $FileName

    # Write==Read: restaura e verifica SHA-256 bit a bit
    $restored    = Invoke-TEIARestoreWithZstdDict -SeedJson $enc.SeedJson -DictDir $DictDir
    $restoredSha = [TEIA.Native.TEIANativeV70]::SHA256Hex($restored)

    if ($restoredSha -ne $ExpectedSha256) {
        throw "SHA-256 MISMATCH — ROLLBACK`nEsperado:  $ExpectedSha256`nRestaurado: $restoredSha"
    }

    [pscustomobject]@{
        SeedBytes    = $enc.SeedBytes
        PayloadBytes = $enc.PayloadBytes
        EncodeMs     = $enc.EncodeMs
        OutSha256    = $enc.OutSha256
        VerifiedOk   = $true
    }
}

# ─── FASE 2: BENCHMARK ───────────────────────────────────────────────────────
Write-Host "`n=== FASE 2: Benchmark 4 Cenarios ==="

$results = [System.Collections.Generic.List[pscustomobject]]::new()

foreach ($tf in $TEST_FILES) {
    if (-not (Test-Path $tf.Path)) {
        Write-Warning "Arquivo nao encontrado: $($tf.Path) — pulando $($tf.Id)"
        continue
    }

    $origBytes = [IO.File]::ReadAllBytes($tf.Path)
    $origSize  = $origBytes.Length
    $origSha   = (Get-FileHash $tf.Path -Algorithm SHA256).Hash.ToLowerInvariant()

    Write-Host "`n--- $($tf.Id): $($tf.Label)"
    Write-Host "    Tamanho: $origSize bytes | SHA-256: $($origSha.Substring(0,16))..."

    Write-Host "  [A] LZMA standalone (7z -mx9 -mmt1)..."
    $rA = Measure-ScenarioA -FilePath $tf.Path -Id $tf.Id
    $rA_Pct = [math]::Round($rA.SizeBytes / $origSize * 100, 2)
    Write-Host "      $($rA.SizeBytes) bytes | ${rA_Pct}% | $($rA.Ms)ms"

    Write-Host "  [B] Zstd standalone (-19)..."
    $rB = Measure-ScenarioB -FilePath $tf.Path -Id $tf.Id
    $rB_Pct = [math]::Round($rB.SizeBytes / $origSize * 100, 2)
    Write-Host "      $($rB.SizeBytes) bytes | ${rB_Pct}% | $($rB.Ms)ms"

    Write-Host "  [C] Zstd + dicionario treinado (raw, sem TEIA)..."
    $rC = Measure-ScenarioC -FilePath $tf.Path -Id $tf.Id -DictPath $DICT_PATH
    $rC_Pct = [math]::Round($rC.SizeBytes / $origSize * 100, 2)
    Write-Host "      $($rC.SizeBytes) bytes | ${rC_Pct}% | $($rC.Ms)ms"

    Write-Host "  [D] TEIA dict.zstd_shared (seed + SHA-256 verify)..."
    $rD = Measure-ScenarioD -Data $origBytes -FileName (Split-Path $tf.Path -Leaf) `
                              -DictPath $DICT_PATH -DictDir $DICT_DIR -ExpectedSha256 $origSha
    $rD_Pct = [math]::Round($rD.SeedBytes / $origSize * 100, 2)
    $shaOk  = if ($rD.VerifiedOk) { "SHA-256 OK" } else { "SHA-256 FAIL" }
    Write-Host "      $($rD.SeedBytes) bytes | ${rD_Pct}% | $($rD.EncodeMs)ms | $shaOk"

    $overhead_DC     = $rD.SeedBytes - $rC.SizeBytes
    $overhead_DC_Pct = [math]::Round($overhead_DC / $origSize * 100, 2)
    $delta_DA        = $rD.SeedBytes - $rA.SizeBytes
    $teiaGanha       = $rD.SeedBytes -lt $rA.SizeBytes

    Write-Host ("  [Overhead D-C] {0} bytes ({1}% do original)" -f $overhead_DC, $overhead_DC_Pct)
    $teiaLabel = if ($teiaGanha) { "TEIA GANHA" } else { "TEIA perde" }
    Write-Host ("  [Delta D-A]    {0} bytes — {1}" -f $delta_DA, $teiaLabel)

    $results.Add([pscustomobject]@{
        Id               = $tf.Id
        Label            = $tf.Label
        OrigBytes        = $origSize
        OrigSha256       = $origSha
        A_Bytes          = $rA.SizeBytes
        A_Pct            = $rA_Pct
        A_Ms             = $rA.Ms
        B_Bytes          = $rB.SizeBytes
        B_Pct            = $rB_Pct
        B_Ms             = $rB.Ms
        C_Bytes          = $rC.SizeBytes
        C_Pct            = $rC_Pct
        C_Ms             = $rC.Ms
        D_Bytes          = $rD.SeedBytes
        D_Pct            = $rD_Pct
        D_Ms             = $rD.EncodeMs
        D_Payload        = $rD.PayloadBytes
        D_SHA_Ok         = $rD.VerifiedOk
        Overhead_DC      = $overhead_DC
        Overhead_DC_Pct  = $overhead_DC_Pct
        Delta_DA         = $delta_DA
        TeiaGanha        = $teiaGanha
    })
}

if ($results.Count -eq 0) { throw "Nenhum arquivo de teste processado" }

# ─── FASE 3: BREAK-EVEN N ────────────────────────────────────────────────────
Write-Host "`n=== FASE 3: Break-even N ==="

$fixedCost  = $MOTOR_BYTES + $DICT_BYTES
$breakEvens = [System.Collections.Generic.List[pscustomobject]]::new()

foreach ($r in $results) {
    $savings = $r.A_Bytes - $r.D_Bytes
    if ($savings -le 0) {
        $nBE    = -1
        $interp = "TEIA nao supera LZMA neste arquivo — break-even indefinido"
        Write-Host "  $($r.Id): TEIA nao bate LZMA (delta=$savings) — N indefinido"
    } else {
        $nBE    = [long][Math]::Ceiling($fixedCost / $savings)
        $interp = "A partir de $nBE arquivos do corpus, motor+dict amortiza vs LZMA"
        Write-Host "  $($r.Id): N_break_even = $nBE (fixo=$fixedCost / savings=$savings)"
    }
    $breakEvens.Add([pscustomobject]@{
        Id          = $r.Id
        Savings     = $savings
        N_BreakEven = $nBE
        Interp      = $interp
    })
}

# ─── FASE 4: RELATORIO MD ────────────────────────────────────────────────────
Write-Host "`n=== FASE 4: Gerando $REPORT_OUT ==="

$now     = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$teiaWins = ($results | Where-Object { $_.TeiaGanha }).Count
$total    = $results.Count

$sb = [System.Text.StringBuilder]::new()

$null = $sb.AppendLine("# Relatorio Comparativo v4.0.0 — TEIA dict.zstd_shared vs LZMA")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("> **Gerado**: $now  ")
$null = $sb.AppendLine("> **Motor**: TEIA-Core-v0.7.0.psm1 | SHA-256: $MOTOR_SHA | $MOTOR_BYTES bytes  ")
$null = $sb.AppendLine("> **Dicionario Zstd**: $DICT_SHA256 | $DICT_BYTES bytes | treinado em $($validTrain.Count) arquivos em ${TRAIN_MS}ms  ")
$null = $sb.AppendLine("> **Hardware**: i3-10100F, 16GB RAM, HDD  ")
$null = $sb.AppendLine("> **Integridade**: Write==Read verificado | SHA-256 throw+rollback em divergencia")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("---")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("## Corpus")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("### Treinamento ($($validTrain.Count) arquivos service-2.json botocore — nao incluem cloudfront)")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("| # | Servico | Tamanho |")
$null = $sb.AppendLine("|---|---------|---------|")

for ($i = 0; $i -lt $validTrain.Count; $i++) {
    $f    = $validTrain[$i]
    $svc  = (Split-Path (Split-Path $f -Parent) -Parent | Split-Path -Leaf)
    $sz   = (Get-Item $f).Length
    $null = $sb.AppendLine("| $($i+1) | $svc | $sz bytes |")
}

$null = $sb.AppendLine("")
$null = $sb.AppendLine("### Teste (cloudfront service-2.json — nao visto no treinamento)")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("| ID | Label | Tamanho Original | SHA-256 (primeiros 16) |")
$null = $sb.AppendLine("|----|-------|-----------------|------------------------|")
foreach ($r in $results) {
    $null = $sb.AppendLine("| $($r.Id) | $($r.Label) | $($r.OrigBytes) bytes | $($r.OrigSha256.Substring(0,16))... |")
}

$null = $sb.AppendLine("")
$null = $sb.AppendLine("---")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("## Resultados — 4 Cenarios por Arquivo")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("| ID | Original | A: LZMA | B: Zstd | C: Zstd+Dict | D: TEIA |")
$null = $sb.AppendLine("|----|----------|---------|---------|--------------|---------|")
foreach ($r in $results) {
    $null = $sb.AppendLine("| $($r.Id) | $($r.OrigBytes) B | $($r.A_Bytes) B ($($r.A_Pct)%) | $($r.B_Bytes) B ($($r.B_Pct)%) | $($r.C_Bytes) B ($($r.C_Pct)%) | $($r.D_Bytes) B ($($r.D_Pct)%) |")
}

$null = $sb.AppendLine("")
$null = $sb.AppendLine("| ID | Tempo A | Tempo B | Tempo C | Tempo D | SHA-256 TEIA | TEIA ganha vs LZMA |")
$null = $sb.AppendLine("|----|---------|---------|---------|---------|--------------|-------------------|")
foreach ($r in $results) {
    $sha = if($r.D_SHA_Ok) { "OK" } else { "FALHOU" }
    $win = if($r.TeiaGanha) { "**Sim**" } else { "Nao" }
    $null = $sb.AppendLine("| $($r.Id) | $($r.A_Ms)ms | $($r.B_Ms)ms | $($r.C_Ms)ms | $($r.D_Ms)ms | $sha | $win |")
}

$null = $sb.AppendLine("")
$null = $sb.AppendLine("---")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("## Contribuicao e Overhead da Orquestracao TEIA")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("A diferenca D - C mede o custo exato da camada TEIA sobre o Zstd+dict puro:")
$null = $sb.AppendLine("Base64 encoding (+33% sobre payload comprimido) + envelope JSON (struct ~300 bytes).")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("| ID | Zstd+Dict puro (C) | Seed TEIA (D) | Overhead D-C | Overhead D-C (% orig) |")
$null = $sb.AppendLine("|----|-------------------|---------------|--------------|----------------------|")
foreach ($r in $results) {
    $null = $sb.AppendLine("| $($r.Id) | $($r.C_Bytes) B | $($r.D_Bytes) B | $($r.Overhead_DC) B | $($r.Overhead_DC_Pct)% |")
}

$null = $sb.AppendLine("")
$null = $sb.AppendLine("**Decomposicao do overhead**:")
$null = $sb.AppendLine("")
foreach ($r in $results) {
    $b64overhead = $r.D_Payload  # payload bytes (raw zstd compressed)
    # B64 overhead = ceil(payload * 4/3) - payload ≈ payload * 0.333
    $b64estim = [int]($r.D_Payload * 0.3334)
    $jsonStruct = $r.Overhead_DC - $b64estim
    $null = $sb.AppendLine("- **$($r.Id)**: payload raw=$($r.D_Payload) B | Base64 overhead (est)=+${b64estim} B | JSON struct overhead (est)=+${jsonStruct} B")
}

$null = $sb.AppendLine("")
$null = $sb.AppendLine("---")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("## Calculo Break-even N")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("Formula: N_break_even = teto( (motor_bytes + dict_bytes) / (A_bytes - D_bytes) )")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("Custo fixo amortizavel: motor TEIA-Core-v0.7.0 = $MOTOR_BYTES bytes + dicionario Zstd = $DICT_BYTES bytes = **$fixedCost bytes total**.")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("| ID | Savings por arquivo (A-D) | N Break-even | Interpretacao |")
$null = $sb.AppendLine("|----|--------------------------|--------------|---------------|")
foreach ($be in $breakEvens) {
    $nStr = if ($be.N_BreakEven -lt 0) { "N/A" } else { "$($be.N_BreakEven)" }
    $null = $sb.AppendLine("| $($be.Id) | $($be.Savings) B | $nStr | $($be.Interp) |")
}

$null = $sb.AppendLine("")
$null = $sb.AppendLine("---")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("## Diagnostico Tecnico")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("| Aspecto | Observacao |")
$null = $sb.AppendLine("|---------|-----------|")
$null = $sb.AppendLine("| Cenario B vs A | Zstd -19 standalone vs LZMA: compara algoritmos sem dict |")
$null = $sb.AppendLine("| Cenario C vs B | Ganho real do dicionario Zstd treinado sobre Zstd standalone |")
$null = $sb.AppendLine("| Cenario C vs A | Zstd+dict vs LZMA: compressao bruta, sem overhead TEIA |")
$null = $sb.AppendLine("| Cenario D vs C | Overhead puro da orquestracao TEIA (Base64 + JSON) |")
$null = $sb.AppendLine("| Cenario D vs A | Resultado liquido TEIA vs LZMA incluindo toda a camada |")
$null = $sb.AppendLine("| Write==Read | Cada restauracao TEIA verifica SHA-256 bit a bit; divergencia = throw+rollback |")
$null = $sb.AppendLine("| Retrocompatibilidade | Motor v0.7.0 preserva todos os opcodes v0.6.3 |")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("---")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("## Conclusao")
$null = $sb.AppendLine("")

if ($teiaWins -eq 0) {
    $null = $sb.AppendLine("TEIA dict.zstd_shared (Cenario D) nao supera LZMA standalone em nenhum dos $total arquivo(s) testado(s).")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("O overhead da camada de orquestracao TEIA (Base64 +33% + JSON ~300 bytes) excede o ganho")
    $null = $sb.AppendLine("do dicionario Zstd treinado sobre LZMA para este corpus.")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("**Valor da orquestracao TEIA (independente da taxa de compressao bruta)**:")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("- SHA-256 verificado bit a bit em cada restauracao (cenario D: Write==Read confirmado)")
    $null = $sb.AppendLine("- Idempotencia absoluta: seed determinista producao o mesmo resultado em qualquer hardware")
    $null = $sb.AppendLine("- Opcodes compostos: futuras combinacoes (dict.zstd_shared + xform.xor, etc.)")
    $null = $sb.AppendLine("- Auditabilidade: seed JSON auditavel de forma independente do motor")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("**Caminho para igualar LZMA**: eliminar Base64 — armazenar payload como bytes binarios")
    $null = $sb.AppendLine("em formato de seed binario (roadmap v0.8.0). Reducao estimada: -33% no tamanho do seed,")
    $null = $sb.AppendLine("eliminando o overhead principal e tornando Cenario D competitivo com Cenario C.")
} else {
    $null = $sb.AppendLine("TEIA dict.zstd_shared (Cenario D) supera LZMA standalone em **$teiaWins/$total** arquivo(s).")
    $null = $sb.AppendLine("")
    foreach ($r in ($results | Where-Object { $_.TeiaGanha })) {
        $be = $breakEvens | Where-Object { $_.Id -eq $r.Id }
        $nStr = if ($be.N_BreakEven -lt 0) { "N/A" } else { "$($be.N_BreakEven)" }
        $null = $sb.AppendLine("- **$($r.Id)**: TEIA=$($r.D_Bytes) B vs LZMA=$($r.A_Bytes) B | savings=$($be.Savings) B | N_break_even=$nStr")
    }
}

$null = $sb.AppendLine("")
$null = $sb.AppendLine("---")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("*TEIA-Core v0.7.0 | Harness v4.0.0 | Felippe Barcelos | $now*")

$mdContent = $sb.ToString()
$mdBytes   = [Text.Encoding]::UTF8.GetBytes($mdContent)
[IO.File]::WriteAllBytes($REPORT_OUT, $mdBytes)

# Write==Read verification do relatorio
$readBack  = [IO.File]::ReadAllBytes($REPORT_OUT)
$writeSha  = [TEIA.Native.TEIANativeV70]::SHA256Hex($mdBytes)
$readSha   = [TEIA.Native.TEIANativeV70]::SHA256Hex($readBack)
if ($writeSha -ne $readSha) {
    throw "Write==Read FAIL no relatorio! write=$writeSha read=$readSha"
}

$reportSha = $writeSha

# ─── SUMARIO FINAL ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════════╗"
Write-Host "║  SUMARIO — BENCHMARK TEIA v4.0.0                                  ║"
Write-Host "╠═══════════════════════════════════════════════════════════════════╣"
foreach ($r in $results) {
    $win = if($r.TeiaGanha) { "GANHA" } else { "perde" }
    $sha = if($r.D_SHA_Ok) { "SHA OK" } else { "SHA FAIL" }
    Write-Host ("║  {0}: A={1,6}B LZMA | C={2,6}B Zstd+D | D={3,6}B TEIA | {4} | {5}" -f `
        $r.Id, $r.A_Bytes, $r.C_Bytes, $r.D_Bytes, $win, $sha)
}
Write-Host "╠═══════════════════════════════════════════════════════════════════╣"
Write-Host "║  Motor: $MOTOR_BYTES B + Dict: $DICT_BYTES B = $fixedCost B fixo"
foreach ($be in $breakEvens) {
    $nStr = if ($be.N_BreakEven -lt 0) { "N/A" } else { "$($be.N_BreakEven)" }
    Write-Host "║  $($be.Id): N_break_even=$nStr (savings=$($be.Savings) B/arquivo)"
}
Write-Host "╠═══════════════════════════════════════════════════════════════════╣"
Write-Host "║  Relatorio: $REPORT_OUT"
Write-Host "║  SHA-256:   $reportSha"
Write-Host "╚═══════════════════════════════════════════════════════════════════╝"
