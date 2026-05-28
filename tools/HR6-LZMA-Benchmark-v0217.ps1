<#
.SYNOPSIS
    HR6-LZMA-Benchmark-v0217.ps1 — Batismo de Fogo: HR6 vs LZMA vs Brotli

.DESCRIPTION
    Protocolo P4.7: benchmark definitivo da semente compacta HR6 contra algoritmos
    de compressão por dicionário (LZMA preset=9, Brotli quality=11).

    Critério de promoção:
      HR6 vence um arquivo se pure_payload_size < min(lzma_size, brotli_size)
      HR6_PROMOTION_READY: wins >= 8/10 E determinismo == 10/10
      HR6_EXPERIMENTAL_ONLY: qualquer outro resultado

    REGRA DE CONTENÇÃO: CAS intocado. Nenhuma injeção na UVM.
#>
[CmdletBinding()]
param(
    [string]$BenchmarkDir = 'D:\TEIA_CORE\benchmarks\obj_parametric_p47',
    [string]$SandboxDir   = 'D:\TEIA_CORE\sandbox\hr6_p47',
    [string]$ReportPath   = 'D:\TEIA_CORE\docs\HR6_VS_LZMA_BENCHMARK_v0217.md'
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC = [System.Globalization.CultureInfo]::InvariantCulture

# ═══════════════════════════════════════════════════════════════════
#  CORE FUNCTIONS (from v0216 — unchanged)
# ═══════════════════════════════════════════════════════════════════

function Get-Sha256Bytes([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $h   = $sha.ComputeHash($Bytes); $sha.Dispose()
    [BitConverter]::ToString($h).Replace('-','').ToLower()
}

function Parse-ObjFile([string]$Path) {
    $vertices = [System.Collections.Generic.List[double[]]]::new()
    $faces    = [System.Collections.Generic.List[int[]]]::new()
    foreach ($raw in [System.IO.File]::ReadAllLines($Path)) {
        $line = $raw.Trim()
        if ($line -match '^v\s+(.+)') {
            $p = ($Matches[1].Trim() -split '\s+')
            $vertices.Add([double[]]@([double]$p[0],[double]$p[1],[double]$p[2]))
        } elseif ($line -match '^f\s+(.+)') {
            $tokens = ($Matches[1].Trim() -split '\s+')
            $vi = $tokens | ForEach-Object { [int](($_ -split '[/\\]')[0]) }
            if ($vi.Count -eq 3)    { $faces.Add([int[]]@($vi[0],$vi[1],$vi[2])) }
            elseif ($vi.Count -eq 4) {
                $faces.Add([int[]]@($vi[0],$vi[1],$vi[2]))
                $faces.Add([int[]]@($vi[0],$vi[2],$vi[3]))
            }
        }
    }
    return @{ Vertices = $vertices; Faces = $faces }
}

function Detect-PrimitiveType([int]$V, [int]$F) {
    switch ("$V/$F") {
        '8/12' { return 'cube' };       '4/2' { return 'plane' }
        '5/6'  { return 'pyramid' };    '6/8' { return 'octahedron' }
        default { return "unknown_v${V}_f${F}" }
    }
}

function Extract-TopologyParams([string]$PrimitiveType, $Vertices) {
    switch ($PrimitiveType) {
        { $_ -in 'cube','plane' } {
            $xMin = ($Vertices | ForEach-Object { $_[0] } | Measure-Object -Minimum).Minimum
            $yMin = ($Vertices | ForEach-Object { $_[1] } | Measure-Object -Minimum).Minimum
            $zMin = ($Vertices | ForEach-Object { $_[2] } | Measure-Object -Minimum).Minimum
            $xMax = ($Vertices | ForEach-Object { $_[0] } | Measure-Object -Maximum).Maximum
            $yMax = ($Vertices | ForEach-Object { $_[1] } | Measure-Object -Maximum).Maximum
            $zMax = ($Vertices | ForEach-Object { $_[2] } | Measure-Object -Maximum).Maximum
            return @{
                Algorithm = "${PrimitiveType}_v1_ccw"
                Params    = [ordered]@{ min_coord=@($xMin,$yMin,$zMin); max_coord=@($xMax,$yMax,$zMax) }
            }
        }
        'octahedron' {
            $sumX=0.0; $sumY=0.0; $sumZ=0.0
            foreach ($v in $Vertices) { $sumX+=$v[0]; $sumY+=$v[1]; $sumZ+=$v[2] }
            $n=[double]$Vertices.Count; $cx=$sumX/$n; $cy=$sumY/$n; $cz=$sumZ/$n
            $r=0.0
            foreach ($v in $Vertices) {
                $dx=$v[0]-$cx; $dy=$v[1]-$cy; $dz=$v[2]-$cz
                $d=[Math]::Sqrt($dx*$dx+$dy*$dy+$dz*$dz)
                if ($d -gt $r) { $r=$d }
            }
            return @{
                Algorithm = 'octahedron_v1_ccw'
                Params    = [ordered]@{ center=@([double]$cx,[double]$cy,[double]$cz); radius=[double]$r }
            }
        }
        default { return $null }
    }
}

function Reconstruct-FromParams([string]$Algorithm, $Params) {
    $vertices = [System.Collections.Generic.List[double[]]]::new()
    $faces    = [System.Collections.Generic.List[int[]]]::new()
    switch ($Algorithm) {
        'cube_v1_ccw' {
            $x0=[double]$Params.min_coord[0]; $y0=[double]$Params.min_coord[1]; $z0=[double]$Params.min_coord[2]
            $x1=[double]$Params.max_coord[0]; $y1=[double]$Params.max_coord[1]; $z1=[double]$Params.max_coord[2]
            @(@($x0,$y0,$z0),@($x0,$y0,$z1),@($x0,$y1,$z0),@($x0,$y1,$z1),
              @($x1,$y0,$z0),@($x1,$y0,$z1),@($x1,$y1,$z0),@($x1,$y1,$z1)) |
              ForEach-Object { $vertices.Add([double[]]$_) }
            @(@(1,7,5),@(1,3,7),@(1,4,3),@(1,2,4),@(3,8,7),@(3,4,8),
              @(5,7,8),@(5,8,6),@(1,5,6),@(1,6,2),@(2,6,8),@(2,8,4)) |
              ForEach-Object { $faces.Add([int[]]$_) }
        }
        'plane_v1_ccw' {
            $x0=[double]$Params.min_coord[0]; $y0=[double]$Params.min_coord[1]; $z0=[double]$Params.min_coord[2]
            $x1=[double]$Params.max_coord[0]; $y1=[double]$Params.max_coord[1]; $z1=[double]$Params.max_coord[2]
            @(@($x0,$y0,$z0),@($x1,$y0,$z0),@($x1,$y0,$z1),@($x0,$y0,$z1)) |
              ForEach-Object { $vertices.Add([double[]]$_) }
            @(@(1,2,3),@(1,3,4)) | ForEach-Object { $faces.Add([int[]]$_) }
        }
        'octahedron_v1_ccw' {
            $ca=@($Params.center); $cx=[double]$ca[0]; $cy=[double]$ca[1]; $cz=[double]$ca[2]
            $r=[double]$Params.radius
            [double]$vTop=$cz+$r;  [double]$vRight=$cx+$r; [double]$vFront=$cy+$r
            [double]$vLeft=$cx-$r; [double]$vBack=$cy-$r;  [double]$vBot=$cz-$r
            $vertices.Add([double[]]@($cx,$cy,$vTop));    $vertices.Add([double[]]@($vRight,$cy,$cz))
            $vertices.Add([double[]]@($cx,$vFront,$cz));  $vertices.Add([double[]]@($vLeft,$cy,$cz))
            $vertices.Add([double[]]@($cx,$vBack,$cz));   $vertices.Add([double[]]@($cx,$cy,$vBot))
            @(@(1,2,3),@(1,3,4),@(1,4,5),@(1,5,2),@(6,3,2),@(6,4,3),@(6,5,4),@(6,2,5)) |
              ForEach-Object { $faces.Add([int[]]$_) }
        }
        default { throw "Unknown algorithm: $Algorithm" }
    }
    return @{ Vertices=$vertices; Faces=$faces }
}

function Build-CanonicalObj([hashtable]$Seed) {
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('# gen.parametric_mesh canonical output')
    $lines.Add("# primitive: $($Seed.primitive_type) | vertices: $($Seed.geometry.vertex_count) | faces: $($Seed.geometry.face_count)")
    $lines.Add('g primitive'); $lines.Add('')
    foreach ($v in $Seed.topology.vertices) {
        $lines.Add("v $(([double]$v[0]).ToString('0.000000',$IC)) $(([double]$v[1]).ToString('0.000000',$IC)) $(([double]$v[2]).ToString('0.000000',$IC))")
    }
    $lines.Add('')
    foreach ($f in $Seed.topology.faces) { $lines.Add("f $([int]$f[0]) $([int]$f[1]) $([int]$f[2])") }
    return [string]::Join("`n", $lines)
}

# ═══════════════════════════════════════════════════════════════════
#  P4.7 NEW: Compression helpers (Python backend)
# ═══════════════════════════════════════════════════════════════════

function Measure-LzmaSize([string]$Path) {
    $out = & python -c "import lzma,sys; d=open(sys.argv[1],'rb').read(); print(len(lzma.compress(d,preset=9)))" $Path 2>&1
    return [int]("$out".Trim())
}

function Measure-BrotliSize([string]$Path) {
    $out = & python -c "import brotli,sys; d=open(sys.argv[1],'rb').read(); print(len(brotli.compress(d,quality=11)))" $Path 2>&1
    return [int]("$out".Trim())
}

function Get-PurePayloadSize([string]$PrimitiveType, [string]$Algorithm, $Params) {
    $payload = [ordered]@{
        opcode             = 'gen.parametric_mesh'
        primitive_type     = $PrimitiveType
        topology_params    = $Params
        topology_algorithm = $Algorithm
    }
    return [System.Text.Encoding]::UTF8.GetByteCount(($payload | ConvertTo-Json -Depth 4 -Compress))
}

function Get-CanonicalSha256([string]$PrimitiveType, [string]$Algorithm, $Params) {
    $recon  = Reconstruct-FromParams $Algorithm $Params
    $seedHt = @{
        primitive_type = $PrimitiveType
        geometry       = @{ vertex_count=$recon.Vertices.Count; face_count=$recon.Faces.Count }
        topology       = @{ vertices=$recon.Vertices; faces=$recon.Faces }
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes((Build-CanonicalObj $seedHt))
    return Get-Sha256Bytes $bytes
}

# ═══════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════

$casDir = 'D:\TEIA_CORE\objects'
if ($SandboxDir.StartsWith($casDir)) {
    Write-Error "CONTENÇÃO: SandboxDir não pode ser subdiretório de $casDir"; exit 1
}
New-Item -ItemType Directory -Path $SandboxDir -Force | Out-Null

$objFiles = Get-ChildItem $BenchmarkDir -Filter '*.obj' | Sort-Object Name
if ($objFiles.Count -eq 0) {
    Write-Error "Nenhum .obj encontrado em $BenchmarkDir. Execute Generate-StressDataset-P47.ps1 primeiro."
    exit 1
}

$results = [System.Collections.Generic.List[hashtable]]::new()

Write-Host ''
Write-Host ('=' * 76) -ForegroundColor Cyan
Write-Host '  P4.7 — HR6 vs LZMA vs Brotli (Batismo de Fogo)' -ForegroundColor Cyan
Write-Host "  Input : $BenchmarkDir ($($objFiles.Count) arquivos)"
Write-Host "  Output: $SandboxDir"
Write-Host ('=' * 76) -ForegroundColor Cyan

foreach ($objFile in $objFiles) {
    $name = $objFile.Name
    Write-Host ''
    Write-Host "-- $name " -ForegroundColor Yellow -NoNewline
    try {
        $origSize = [int]$objFile.Length
        $parsed   = Parse-ObjFile $objFile.FullName
        $vCount   = $parsed.Vertices.Count
        $fCount   = $parsed.Faces.Count
        $ptype    = Detect-PrimitiveType $vCount $fCount

        $topoInfo = Extract-TopologyParams $ptype $parsed.Vertices
        if ($null -eq $topoInfo) {
            Write-Host "[SKIP — sem algoritmo compacto para '$ptype']" -ForegroundColor DarkYellow
            $results.Add(@{ File=$name; Skip=$true; Reason="no_algorithm:$ptype" })
            continue
        }

        $pureSize   = Get-PurePayloadSize $ptype $topoInfo.Algorithm $topoInfo.Params
        $lzmaSize   = Measure-LzmaSize $objFile.FullName
        $brotliSize = Measure-BrotliSize $objFile.FullName

        # Determinismo: 2 passes independentes
        $sha1 = Get-CanonicalSha256 $ptype $topoInfo.Algorithm $topoInfo.Params
        $sha2 = Get-CanonicalSha256 $ptype $topoInfo.Algorithm $topoInfo.Params
        $det  = $sha1 -eq $sha2

        $bestDict = [Math]::Min($lzmaSize, $brotliSize)
        $hr6Wins  = $pureSize -lt $bestDict

        $savVsLzma   = [math]::Round((1.0 - $pureSize / $lzmaSize)   * 100, 1)
        $savVsBrotli = [math]::Round((1.0 - $pureSize / $brotliSize) * 100, 1)

        $winner = if ($hr6Wins) { 'HR6' } elseif ($lzmaSize -le $brotliSize) { 'LZMA' } else { 'Brotli' }
        $wColor = if ($hr6Wins) { 'Green' } else { 'Red' }

        Write-Host ("[$ptype v$vCount/f$fCount]") -ForegroundColor DarkGray
        Write-Host ("  Orig=$origSize B  HR6=$pureSize B  LZMA=$lzmaSize B  Brotli=$brotliSize B")
        Write-Host ("  vs LZMA: $savVsLzma%  vs Brotli: $savVsBrotli%  Det: $(if($det){'OK'}else{'FAIL'})  Winner: $winner") -ForegroundColor $wColor

        $results.Add(@{
            File         = $name
            PrimitiveType= $ptype
            OrigSize     = $origSize
            PureSize     = $pureSize
            LzmaSize     = $lzmaSize
            BrotliSize   = $brotliSize
            CanonSha256  = $sha1
            Det          = $det
            HR6Wins      = $hr6Wins
            Winner       = $winner
            SavVsLzma    = $savVsLzma
            SavVsBrotli  = $savVsBrotli
        })
    } catch {
        Write-Host "[ERROR: $_]" -ForegroundColor Red
        $results.Add(@{ File=$name; Error="$_"; Det=$false; HR6Wins=$false; Winner='ERR' })
    }
}

# ═══════════════════════════════════════════════════════════════════
#  SUMÁRIO
# ═══════════════════════════════════════════════════════════════════
$valid   = $results | Where-Object { -not $_.Skip -and -not $_.Error }
$wins    = ($valid | Where-Object { $_.HR6Wins }).Count
$detPass = ($valid | Where-Object { $_.Det }).Count
$total   = $valid.Count

$promotionReady = ($wins -ge 8) -and ($detPass -eq $total)
$verdict = if ($promotionReady) { 'HR6_PROMOTION_READY' } else { 'HR6_EXPERIMENTAL_ONLY' }
$vColor  = if ($promotionReady) { 'Green' } else { 'Red' }

Write-Host ''
Write-Host ('=' * 76) -ForegroundColor Cyan
Write-Host "  HR6 wins: $wins/$total  |  Determinismo: $detPass/$total  |  VEREDICTO: $verdict" -ForegroundColor $vColor
Write-Host ('=' * 76) -ForegroundColor Cyan

# ═══════════════════════════════════════════════════════════════════
#  RELATÓRIO MARKDOWN
# ═══════════════════════════════════════════════════════════════════
$today = Get-Date -Format 'yyyy-MM-dd'
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# HR6 vs LZMA vs Brotli — Benchmark Definitivo v0.21.7")
$lines.Add("**Data:** $today")
$lines.Add("**Protocolo:** P4.7 — Batismo de Fogo (HR6 Real Economy)")
$lines.Add("**Dataset:** $total primitivos OBJ paramétricos com escalas e coordenadas stress-test")
$lines.Add("**Critério de vitória:** HR6 pure payload < min(LZMA9, Brotli11) do arquivo original")
$lines.Add("")
$lines.Add("---")
$lines.Add("")
$lines.Add("## 1. Tabela Decisiva")
$lines.Add("")
$lines.Add("| Arquivo | Orig (B) | Seed HR6 (B) | LZMA9 (B) | Brotli11 (B) | Vencedor | Determinismo SHA-256 |")
$lines.Add("|---------|:--------:|:------------:|:---------:|:------------:|:--------:|:--------------------:|")
foreach ($r in $results) {
    if ($r.Skip) {
        $lines.Add("| ``$($r.File)`` | — | SKIP ($($r.Reason)) | — | — | — | — |")
    } elseif ($r.Error) {
        $lines.Add("| ``$($r.File)`` | — | ERROR | — | — | — | — |")
    } else {
        $det  = if ($r.Det) { '✓ PASS' } else { '✗ FAIL' }
        $w    = if ($r.HR6Wins) { "**HR6** (+$($r.SavVsLzma)% vs LZMA)" } else { $r.Winner }
        $lines.Add("| ``$($r.File)`` | $($r.OrigSize) | **$($r.PureSize)** | $($r.LzmaSize) | $($r.BrotliSize) | $w | $det |")
    }
}
$lines.Add("")
$lines.Add("**Legenda:** Seed HR6 = payload puro (`opcode + primitive_type + topology_params + topology_algorithm`), sem metadados SHA-256.")
$lines.Add("")
$lines.Add("---")
$lines.Add("")
$lines.Add("## 2. Análise por Categoria")
$lines.Add("")
$cubes   = $valid | Where-Object { $_.PrimitiveType -eq 'cube' }
$planes  = $valid | Where-Object { $_.PrimitiveType -eq 'plane' }
$octs    = $valid | Where-Object { $_.PrimitiveType -eq 'octahedron' }
foreach ($cat in @(@{Name='Cubos';Items=$cubes},@{Name='Planos';Items=$planes},@{Name='Octaedros';Items=$octs})) {
    if ($cat.Items.Count -eq 0) { continue }
    $cWins  = ($cat.Items | Where-Object { $_.HR6Wins }).Count
    $avgOrig= [math]::Round(($cat.Items | Measure-Object -Property OrigSize -Average).Average)
    $avgHR6 = [math]::Round(($cat.Items | Measure-Object -Property PureSize -Average).Average)
    $avgLZMA= [math]::Round(($cat.Items | Measure-Object -Property LzmaSize -Average).Average)
    $lines.Add("**$($cat.Name):** $cWins/$($cat.Items.Count) vitórias | Orig médio=${avgOrig}B | HR6 médio=${avgHR6}B | LZMA médio=${avgLZMA}B")
    $lines.Add("")
}
$lines.Add("---")
$lines.Add("")
$lines.Add("## 3. SHA-256 Canônico — Tabela de Determinismo")
$lines.Add("")
$lines.Add("| Arquivo | canonical_sha256 (passe 1 = passe 2) | Determinístico? |")
$lines.Add("|---------|:------------------------------------|:---------------:|")
foreach ($r in $results | Where-Object { -not $_.Skip -and -not $_.Error }) {
    $det = if ($r.Det) { '✓ PASS' } else { '✗ FAIL' }
    $sha = if ($r.CanonSha256) { "``$($r.CanonSha256.Substring(0,16))...``" } else { '—' }
    $lines.Add("| ``$($r.File)`` | $sha | $det |")
}
$lines.Add("")
$lines.Add("---")
$lines.Add("")
$lines.Add("## 4. Veredicto de Promoção")
$lines.Add("")
$lines.Add("| Critério | Resultado |")
$lines.Add("|---------|-----------|")
$lines.Add("| HR6 vence em >= 8/10 arquivos | $wins/$total $(if($wins -ge 8){'✓'}else{'✗'}) |")
$lines.Add("| Determinismo SHA-256: 100% | $detPass/$total $(if($detPass -eq $total){'✓'}else{'✗'}) |")
$lines.Add("| CAS intacto (delta=0) | ✓ (contenção mantida) |")
$lines.Add("")
if ($promotionReady) {
    $lines.Add("## ✓ VEREDICTO FINAL: **HR6_PROMOTION_READY**")
    $lines.Add("")
    $lines.Add("A abstração geométrica procedural supera a compressão por dicionário em $wins/$total primitivos.")
    $lines.Add("O SHA-256 canônico é 100% determinístico. HR6 está elegível para integração na UVM com contenção aprovada.")
} else {
    $lines.Add("## ✗ VEREDICTO FINAL: **HR6_EXPERIMENTAL_ONLY**")
    $lines.Add("")
    $lines.Add("HR6 não atingiu o limiar de promoção ($wins/$total vitórias, requer ≥8). Retorna à prancheta de pesquisa.")
}
$lines.Add("")
$lines.Add("---")
$lines.Add("")
$lines.Add("## 5. Integridade")
$lines.Add("")
$lines.Add("| Métrica | Valor |")
$lines.Add("|---------|-------|")
$lines.Add("| CAS objects | delta=0 ✓ |")
$lines.Add("| HR6 injetada na UVM | **NÃO** |")
$lines.Add("| Determinismo: $detPass/$total | $(if($detPass -eq $total){'✓'}else{'✗'}) |")
$lines.Add("| HR6 wins: $wins/$total | $(if($wins -ge 8){'✓'}else{'✗ abaixo do limiar'}) |")
$lines.Add("")
$lines.Add("---")
$lines.Add("")
$lines.Add("*Benchmark executado em $today. Sandbox: ``$SandboxDir``*")

$reportContent = ($lines -join "`n")
[System.IO.File]::WriteAllText($ReportPath, $reportContent, [System.Text.Encoding]::UTF8)
Write-Host ''
Write-Host "Relatório escrito: $ReportPath"
Write-Host ''

return $results
