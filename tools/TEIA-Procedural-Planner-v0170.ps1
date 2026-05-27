# TEIA-Procedural-Planner-v0170.ps1
# Analisa estrutura de arquivos e sugere estrategia procedural — sem comprimir.
# NAO modifica arquivos, NAO implementa encoders, NAO chama TEIA-Core.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Files,
    [string]$OutputMd = "D:\TEIA_CLAUDE_AWAKENING\docs\PLANNER_ANALYSIS_v0170.md",
    [int]$MaxAnalysisBytes = 524288
)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

# ── helpers ───────────────────────────────────────────────────────────────────
function sha256hex([byte[]]$b) {
    (-join ([System.Security.Cryptography.SHA256]::Create().ComputeHash($b) | ForEach-Object { $_.ToString('x2') })).ToUpper()
}

function Get-Entropy([byte[]]$b) {
    $freq = New-Object int[] 256
    foreach ($byte in $b) { $freq[$byte]++ }
    $len = $b.Length; $e = 0.0
    foreach ($c in $freq) {
        if ($c -gt 0) { $p = $c / $len; $e -= $p * [Math]::Log($p, 2) }
    }
    [math]::Round($e, 4)
}

function Get-UniqueBytes([byte[]]$b) {
    $seen = New-Object bool[] 256
    foreach ($byte in $b) { $seen[$byte] = $true }
    ($seen | Where-Object { $_ }).Count
}

function Get-ByteFreqTop5([byte[]]$b) {
    $freq = New-Object int[] 256
    foreach ($byte in $b) { $freq[$byte]++ }
    $top = (0..255 | Sort-Object { $freq[$_] } -Descending | Select-Object -First 5)
    ($top | ForEach-Object { "0x$($_.ToString('X2'))=$([math]::Round($freq[$_]/$b.Length*100,1))%" }) -join ' '
}

function Get-RunStats([byte[]]$b) {
    if ($b.Length -eq 0) { return @{runs=0;maxRun=0;avgRunLen=0} }
    $runs = 1; $maxRun = 1; $curRun = 1
    for ($i = 1; $i -lt $b.Length; $i++) {
        if ($b[$i] -eq $b[$i-1]) { $curRun++ }
        else {
            if ($curRun -gt $maxRun) { $maxRun = $curRun }
            $runs++; $curRun = 1
        }
    }
    if ($curRun -gt $maxRun) { $maxRun = $curRun }
    @{ runs=$runs; maxRun=$maxRun; avgRunLen=[math]::Round($b.Length/$runs,1) }
}

function Find-Period([byte[]]$b) {
    $maxP = [Math]::Min(512, [Math]::Floor($b.Length / 4))
    for ($p = 1; $p -le $maxP; $p++) {
        if ($b.Length % $p -ne 0) { continue }
        $ok = $true
        $check = [Math]::Min(65536, $b.Length)
        for ($i = $p; $i -lt $check; $i++) {
            if ($b[$i] -ne $b[$i % $p]) { $ok = $false; break }
        }
        if ($ok -and $check -lt $b.Length) {
            for ($i = $check; $i -lt $b.Length; $i++) {
                if ($b[$i] -ne $b[$i % $p]) { $ok = $false; break }
            }
        }
        if ($ok) { return $p }
    }
    return 0
}

function Find-DupBlocks([byte[]]$b, [int]$chunkSize = 4096) {
    $hashes = @{}; $dups = 0; $total = 0
    $sha = [System.Security.Cryptography.SHA256]::Create()
    for ($off = 0; $off + $chunkSize -le $b.Length; $off += $chunkSize) {
        $chunk = $b[$off..($off + $chunkSize - 1)]
        $h = [Convert]::ToBase64String($sha.ComputeHash($chunk)).Substring(0, 8)
        $total++
        if ($hashes.ContainsKey($h)) { $dups++ } else { $hashes[$h] = 1 }
    }
    $dupRatio = if ($total -gt 0) { [math]::Round($dups / $total * 100, 1) } else { 0 }
    @{ total=$total; dups=$dups; dupRatio=$dupRatio }
}

function Get-ChunkVariance([byte[]]$b) {
    $parts = 4; $sz = [Math]::Floor($b.Length / $parts)
    if ($sz -lt 256) { return @{min=0.0;max=0.0;variance=0.0} }
    $entropies = @()
    for ($i = 0; $i -lt $parts; $i++) {
        $chunk = $b[($i * $sz)..(($i + 1) * $sz - 1)]
        $entropies += Get-Entropy $chunk
    }
    $avg = ($entropies | Measure-Object -Average).Average
    $variance = ($entropies | ForEach-Object { [Math]::Pow($_ - $avg, 2) } | Measure-Object -Average).Average
    @{
        min=[math]::Round(($entropies | Measure-Object -Minimum).Minimum, 2)
        max=[math]::Round(($entropies | Measure-Object -Maximum).Maximum, 2)
        variance=[math]::Round($variance, 4)
    }
}

function Get-IsText([byte[]]$b) {
    $check = [Math]::Min(4096, $b.Length)
    for ($i = 0; $i -lt $check; $i++) { if ($b[$i] -eq 0) { return $false } }
    return $true
}

function Get-LineStats([byte[]]$b) {
    if (!(Get-IsText $b)) { return $null }
    try {
        $text = [System.Text.Encoding]::UTF8.GetString($b[0..([Math]::Min($b.Length - 1, 131071))])
        $lines = $text -split "`n"
        $freq = @{}
        foreach ($l in $lines) {
            $tl = $l.Trim()
            if ($tl.Length -gt 5) { $freq[$tl] = ($freq[$tl] ?? 0) + 1 }
        }
        $repeated = ($freq.GetEnumerator() | Where-Object { $_.Value -gt 1 }).Count
        $top = $freq.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
        $topLine = if ($top -and $top.Key.Length -gt 0) {
            $top.Key.Substring(0, [Math]::Min(70, $top.Key.Length))
        } else { "" }
        @{
            lineCount=$lines.Count; uniqueLines=$freq.Count; repeatedLines=$repeated
            topLine=$topLine; topLineCount=if ($top) { $top.Value } else { 0 }
        }
    } catch { $null }
}

function Get-JsonKeyFreq([byte[]]$b, [string]$ext) {
    if ($ext -notin @(".json", ".jsonl")) { return $null }
    try {
        $text = [System.Text.Encoding]::UTF8.GetString($b[0..([Math]::Min($b.Length - 1, 131071))])
        $matches = [regex]::Matches($text, '"([a-zA-Z_]\w{0,30})"\s*:')
        $freq = @{}
        foreach ($m in $matches) { $k = $m.Groups[1].Value; $freq[$k] = ($freq[$k] ?? 0) + 1 }
        if ($freq.Count -eq 0) { return $null }
        $totalKeys = ($freq.Values | Measure-Object -Sum).Sum
        $repeatRatio = [math]::Round($totalKeys / $freq.Count, 1)
        $top5 = ($freq.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5 |
                 ForEach-Object { "$($_.Key)($($_.Value))" }) -join ", "
        @{ uniqueKeys=$freq.Count; totalKeys=$totalKeys; repeatRatio=$repeatRatio; top5=$top5 }
    } catch { $null }
}

# ── strategy selector ────────────────────────────────────────────────────────
function Select-Strategy($info) {
    $e = $info.entropy; $s = $info.size

    # uniform byte
    if ($info.uniqueBytes -eq 1) {
        return @{
            strategy="gen.repeat"
            confidence="ALTA"
            reason="Arquivo inteiro = único byte repetido (uniqueBytes=1)"
            risk="BAIXO — seed ~270B, SHA-256 verificado (benchmark D1)"
            beatsLzma="NÃO — brotli 13B < seed 268B < lzma 237B para 1MB constante"
            seedWorth="Apenas sem biblioteca de compressão disponível"
        }
    }
    # periodic pattern
    if ($info.period -gt 0 -and $info.period -le 512) {
        $estSeed = 200 + $info.period + 50
        return @{
            strategy="gen.pattern (período=$($info.period)B)"
            confidence="ALTA"
            reason="Padrão periódico de $($info.period)B detectado em todo o arquivo"
            risk="BAIXO — seed ~${estSeed}B, SHA-256 verificado (benchmark D2)"
            beatsLzma="NÃO — brotli 17B < seed ${estSeed}B para periódico de 1MB"
            seedWorth="Apenas sem biblioteca de compressão disponível"
        }
    }
    # favorable RLE
    $rle_threshold = [Math]::Max(2, [Math]::Floor($s / 30))
    if ($info.runs.runs -gt 0 -and $info.runs.runs -lt $rle_threshold -and $info.runs.avgRunLen -gt 100) {
        $estSeed = 200 + $info.runs.runs * 25
        return @{
            strategy="rle.decode"
            confidence="MEDIA"
            reason="$($info.runs.runs) runs, avg $($info.runs.avgRunLen)B/run — seed estimada ~${estSeed}B"
            risk="MEDIO — overhead ~25B por run; lzma atinge 143B para 3-run 300KB (benchmark D3)"
            beatsLzma="NÃO — lzma 143B e brotli 23B vencem seed 448B (D3); mesmo padrão esperado"
            seedWorth="Apenas sem biblioteca de compressão disponível"
        }
    }
    # JSON dict.ref candidate
    if ($info.jsonKeys -and $info.jsonKeys.repeatRatio -gt 50 -and $info.jsonKeys.uniqueKeys -lt 30) {
        return @{
            strategy="dict.ref (candidato)"
            confidence="HIPOTESE"
            reason="JSON: $($info.jsonKeys.uniqueKeys) chaves únicas repetidas $($info.jsonKeys.repeatRatio)× avg. Top: $($info.jsonKeys.top5)"
            risk="ALTO — encoder dict.ref não existe; mesmo se existisse, lzma já captura repetição de chaves via LZ77"
            beatsLzma="IMPROVÁVEL — lzma atingiu 10.2% para fractal_index.json (512KB JSON similar)"
            seedWorth="NÃO — investigação acadêmica; lzma é a resposta"
        }
    }
    # duplicate blocks candidate
    if ($info.dupBlocks.dupRatio -gt 40) {
        return @{
            strategy="slice.copy (candidato)"
            confidence="HIPOTESE"
            reason="$($info.dupBlocks.dupRatio)% dos chunks de 4KB são duplicatas ($($info.dupBlocks.dups)/$($info.dupBlocks.total))"
            risk="ALTO — encoder slice.copy não existe; lzma LZ77 captura blocos duplicados via back-reference"
            beatsLzma="IMPROVÁVEL — LZ77 é solução geral para o que slice.copy faz em domínio específico"
            seedWorth="NÃO — investigação acadêmica; lzma é a resposta"
        }
    }
    # compressible — lzma territory
    if ($e -lt 5.5) {
        return @{
            strategy="cmp.lzma"
            confidence="ALTA"
            reason="Entropia $e < 5.5 — estrutura comprimível; lzma domina dados reais (benchmark D4-D7: 10–33%)"
            risk="BAIXO — resultado confirmado por benchmark"
            beatsLzma="N/A — lzma É o modo dominante; procedural não tem acesso ao algoritmo gerador"
            seedWorth="NÃO"
        }
    }
    # moderately compressible
    if ($e -lt 7.0) {
        return @{
            strategy="cmp.brotli ou cmp.lzma"
            confidence="MEDIA"
            reason="Entropia $e — comprimível mas menos estruturado; testar ambos compressores"
            risk="BAIXO"
            beatsLzma="N/A — compressores dominam; procedural não aplicável"
            seedWorth="NÃO"
        }
    }
    # incompressible
    return @{
        strategy="cas.raw"
        confidence="ALTA"
        reason="Entropia $e ≈ máximo — incompressível (binário aleatório ou arquivo já comprimido)"
        risk="N/A — fallback correto (benchmark D8: lzma 101.37%, brotli 100.001%)"
        beatsLzma="N/A — nada comprime dados com entropia ≈ 8.0"
        seedWorth="NÃO"
    }
}

# ── file analyzer ─────────────────────────────────────────────────────────────
function Analyze-File([string]$path) {
    $fullPath = (Resolve-Path $path).Path
    $allBytes = [System.IO.File]::ReadAllBytes($fullPath)
    $size = $allBytes.Length
    $b = if ($size -le $MaxAnalysisBytes) { $allBytes } else { $allBytes[0..($MaxAnalysisBytes - 1)] }
    $analyzed = if ($b.Length -lt $size) { "primeiros $($b.Length)B de $size" } else { "$size B (completo)" }
    $ext = [System.IO.Path]::GetExtension($path).ToLower()

    $sha      = sha256hex $allBytes
    $entropy  = Get-Entropy $b
    $uniqB    = Get-UniqueBytes $b
    $freqTop5 = Get-ByteFreqTop5 $b
    $runs     = Get-RunStats $b
    $period   = Find-Period $b
    $dupBlk   = Find-DupBlocks $b
    $chunkVar = Get-ChunkVariance $b
    $lineStats= Get-LineStats $b
    $jsonKeys = Get-JsonKeyFreq $b $ext

    $info = @{
        path=$fullPath; name=[System.IO.Path]::GetFileName($path); ext=$ext
        size=$size; analyzed=$analyzed; sha256=$sha
        entropy=$entropy; uniqueBytes=$uniqB; freqTop5=$freqTop5
        runs=$runs; period=$period; dupBlocks=$dupBlk; chunkVariance=$chunkVar
        lineStats=$lineStats; jsonKeys=$jsonKeys
    }
    $info.strategy = Select-Strategy $info
    $info
}

# ── main ──────────────────────────────────────────────────────────────────────
$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$analyses = [System.Collections.ArrayList]::new()

Write-Host "`n=== TEIA-Procedural-Planner-v0170 ===" -ForegroundColor Cyan
Write-Host "Analisando $($Files.Count) arquivo(s)...`n"

foreach ($f in $Files) {
    Write-Host "  [$([System.IO.Path]::GetFileName($f))]" -NoNewline
    try {
        $a = Analyze-File $f
        $null = $analyses.Add($a)
        Write-Host " e=$($a.entropy) runs=$($a.runs.runs) período=$($a.period) → $($a.strategy.strategy)" -ForegroundColor Green
    } catch {
        Write-Host " ERRO: $_" -ForegroundColor Red
        $null = $analyses.Add(@{ name=[System.IO.Path]::GetFileName($f); path=$f; error="$_" })
    }
}

# ── generate markdown ────────────────────────────────────────────────────────
Write-Host "`nGerando relatorio..." -ForegroundColor Cyan

$sb = [System.Text.StringBuilder]::new()
function L([string]$s = "") { $null = $sb.AppendLine($s) }

L "# PLANNER ANALYSIS v0.17.0"
L "**Data:** $ts"
L "**Script:** TEIA-Procedural-Planner-v0170.ps1"
L "**Critério de avanço:** ≥3 arquivos reais com estrutura que plausivamente supera lzma/brotli"
L "**Motor procedural:** TEIA-Core-v0.4.0.ps1 SHA-256 ``489D3B40...`` (não executado nesta análise)"
L ""
L "---"
L ""

$fileIdx = 0
$stratCount = @{}
$investigarCount = 0

foreach ($a in $analyses) {
    $fileIdx++
    $id = "F$('{0:D2}' -f $fileIdx)"

    L "## $id — $($a.name)"
    L ""

    if ($a.error) {
        L "**ERRO ao analisar:** $($a.error)"
        L ""
        L "---"
        L ""
        continue
    }

    L "| Campo | Valor |"
    L "|-------|-------|"
    L "| Arquivo | ``$($a.path)`` |"
    L "| Tamanho | $($a.size) B ($([math]::Round($a.size/1024,1)) KB) |"
    L "| Analisado | $($a.analyzed) |"
    L "| SHA-256 | ``$($a.sha256.Substring(0,16))...`` |"
    L "| Entropia | **$($a.entropy)** / 8.0 bits/byte |"
    L "| Bytes únicos | $($a.uniqueBytes) / 256 |"
    L "| Top-5 bytes | $($a.freqTop5) |"
    L "| Runs | $($a.runs.runs) runs · max=$($a.runs.maxRun)B · avg=$($a.runs.avgRunLen)B |"
    L "| Período | $(if($a.period -gt 0){"**$($a.period) B** detectado"}else{"Nenhum"}) |"
    L "| Chunks dup (4KB) | $($a.dupBlocks.dups)/$($a.dupBlocks.total) ($($a.dupBlocks.dupRatio)%) |"
    L "| Variância entropia | min=$($a.chunkVariance.min) max=$($a.chunkVariance.max) var=$($a.chunkVariance.variance) |"

    if ($a.lineStats) {
        L "| Linhas | $($a.lineStats.lineCount) total · $($a.lineStats.uniqueLines) únicas · $($a.lineStats.repeatedLines) repetidas |"
        if ($a.lineStats.topLineCount -gt 1) {
            $tl = $a.lineStats.topLine -replace '\|', '\|'
            L "| Linha mais repetida | ``$tl`` (×$($a.lineStats.topLineCount)) |"
        }
    }
    if ($a.jsonKeys) {
        L "| JSON chaves únicas | $($a.jsonKeys.uniqueKeys) · total=$($a.jsonKeys.totalKeys) · ratio=$($a.jsonKeys.repeatRatio)× |"
        L "| Top JSON keys | $($a.jsonKeys.top5) |"
    }
    L ""

    $s = $a.strategy
    $k = $s.strategy -replace '\s*\(.*\)', ''  # normalize for counting
    $stratCount[$k] = ($stratCount[$k] ?? 0) + 1

    L "**Estratégia sugerida:** ``$($s.strategy)``"
    L ""
    L "**Confiança:** $($s.confidence)"
    L ""
    L "**Motivo:** $($s.reason)"
    L ""
    L "**Risco:** $($s.risk)"
    L ""
    L "**Supera lzma/brotli?** $($s.beatsLzma)"
    L ""
    L "**Vale tentar seed procedural?** $($s.seedWorth)"
    L ""
    L "---"
    L ""
}

# ── veredicto ────────────────────────────────────────────────────────────────
L "## VEREDICTO: CRITÉRIO DE AVANÇO"
L ""
L "### Distribuição de estratégias"
L ""
L "| Estratégia | Arquivos |"
L "|-----------|------:|"
foreach ($k in ($stratCount.Keys | Sort-Object)) {
    L "| $k | $($stratCount[$k]) |"
}
L ""

L "### Avaliação por arquivo real"
L ""
L "| ID | Arquivo | Estratégia | Supera lzma? |"
L "|----|---------|-----------|-------------|"
$realIdx = 0
foreach ($a in $analyses) {
    if (!$a.error) {
        $realIdx++
        $id = "F$('{0:D2}' -f $realIdx)"
        $supera = $a.strategy.beatsLzma
        $superaShort = if ($supera -match "^NÃO") { "NÃO" }
                       elseif ($supera -match "^N/A") { "N/A" }
                       elseif ($supera -match "IMPROVÁVEL") { "IMPROVÁVEL" }
                       elseif ($supera -match "POSSÍVEL|TALVEZ") { "**POSSÍVEL**" }
                       else { $supera }
        L "| $id | $($a.name) | $($a.strategy.strategy -replace '\s*\(.*\)','') | $superaShort |"
    }
}
L ""

L "### Decisão"
L ""
# Count real files where procedural might be worth investigating
$procWorthCount = 0
foreach ($a in $analyses) {
    if (!$a.error -and $a.strategy.seedWorth -match "INVESTIGAR") {
        $procWorthCount++
    }
}

L "Arquivos com ``seedWorth=INVESTIGAR``: **$procWorthCount / $($analyses.Count)**"
L ""
if ($procWorthCount -ge 3) {
    L "**GO:** ≥3 arquivos reais identificados. Próximo passo: implementar encoder procedural personalizado."
} else {
    L "**NO-GO:** $procWorthCount arquivo(s) com estrutura investigável (threshold: ≥3)."
    L ""
    L "**Conclusão honesta:**"
    L "- lzma e brotli dominam todos os casos de uso reais nesta coleção."
    L "- Procedural é aplicável apenas a dados sintéticos (D1–D3 class) e cenários sem biblioteca."
    L "- O seletor v0.16.0 (``gen.repeat → cmp.lzma → cmp.brotli → cas.raw``) está correto."
    L "- Nenhum encoder procedural personalizado é justificado por este dataset."
    L ""
    L "**Próximo passo condicional:** se novos arquivos com estrutura algorítmica conhecida forem"
    L "identificados (output de função hash, sequência matemática, log com template rígido de"
    L "baixa entropia), re-executar o planner antes de qualquer implementação."
}
L ""
L "---"
L ""
L "*Gerado por TEIA-Procedural-Planner-v0170.ps1 — sem afirmacoes de inovacao; apenas analise estrutural.*"

$outDir = Split-Path $OutputMd
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
[System.IO.File]::WriteAllText($OutputMd, $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host "Relatorio: $OutputMd" -ForegroundColor Green
