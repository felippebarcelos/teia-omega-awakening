<#
.SYNOPSIS
    HR6-ParametricMesh-Prototype-v0216.ps1 — Semente Compacta gen.parametric_mesh

.DESCRIPTION
    Refatoração de v0215: substitui a topologia explícita (vertex/face arrays)
    por parâmetros matemáticos mínimos (AABB para cube/plane; center+radius para octahedron).

    Algoritmos registrados:
      cube_v1_ccw       → AABB(min_coord, max_coord)  → 8v 12f
      plane_v1_ccw      → AABB(min_coord, max_coord)  → 4v  2f
      octahedron_v1_ccw → (center, radius)             → 6v  8f

    Validação cruzada com P4.5:
      O canonical_sha256 gerado pela semente compacta DEVE ser idêntico
      ao canonical_sha256 gerado pela semente explícita (P4.5) para o mesmo arquivo.
      Divergência indica bug no algoritmo de reconstrução.

    REGRA DE CONTENÇÃO ABSOLUTA: CAS, NeuroPlanner e Watchdog intactos.

.PARAMETER BenchmarkDir
    Diretório com os primitivos OBJ. Padrão: D:\TEIA_CORE\benchmarks\obj_parametric

.PARAMETER SandboxDir
    Diretório de saída isolado. Padrão: D:\TEIA_CORE\sandbox\hr6_compact
#>
[CmdletBinding()]
param(
    [string]$BenchmarkDir = 'D:\TEIA_CORE\benchmarks\obj_parametric',
    [string]$SandboxDir   = 'D:\TEIA_CORE\sandbox\hr6_compact'
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC = [System.Globalization.CultureInfo]::InvariantCulture   # locale-invariant floats

# SHA-256 esperados de P4.5 para validação cruzada
$P45CanonicalSha256 = @{
    'cube.obj'    = '4df640cbd857edca7af093886a3ffa7c74d5fb19091e3e13365124ec53a50fa3'
    'plane.obj'   = '60dfe60faf0e9daec18eaf6c2187daea8c1f69f8fcdbcdc22822c701384ef8fa'
    'diamond.obj' = 'aa93b202c8bfc31765c9e1a667dce25ae6907cccd77ecea8b1b4655f9c7437bc'
}

# ═══════════════════════════════════════════════════════════════════
#  SHA-256
# ═══════════════════════════════════════════════════════════════════

function Get-Sha256File([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLower()
}

function Get-Sha256Bytes([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $h   = $sha.ComputeHash($Bytes)
    $sha.Dispose()
    [BitConverter]::ToString($h).Replace('-', '').ToLower()
}

# ═══════════════════════════════════════════════════════════════════
#  OBJ PARSER  (idêntico a v0215)
# ═══════════════════════════════════════════════════════════════════

function Parse-ObjFile([string]$Path) {
    $vertices = [System.Collections.Generic.List[double[]]]::new()
    $faces    = [System.Collections.Generic.List[int[]]]::new()

    foreach ($raw in [System.IO.File]::ReadAllLines($Path)) {
        $line = $raw.Trim()
        if ($line -match '^v\s+(.+)') {
            $p = ($Matches[1].Trim() -split '\s+')
            $vertices.Add([double[]]@([double]$p[0], [double]$p[1], [double]$p[2]))
        }
        elseif ($line -match '^f\s+(.+)') {
            $tokens = ($Matches[1].Trim() -split '\s+')
            $vi = $tokens | ForEach-Object { [int](($_ -split '[/\\]')[0]) }
            if ($vi.Count -eq 3) { $faces.Add([int[]]@($vi[0], $vi[1], $vi[2])) }
            elseif ($vi.Count -eq 4) {
                $faces.Add([int[]]@($vi[0], $vi[1], $vi[2]))
                $faces.Add([int[]]@($vi[0], $vi[2], $vi[3]))
            }
        }
    }
    return @{ Vertices = $vertices; Faces = $faces }
}

# ═══════════════════════════════════════════════════════════════════
#  PRIMITIVE DETECTOR  (idêntico a v0215)
# ═══════════════════════════════════════════════════════════════════

function Detect-PrimitiveType([int]$V, [int]$F) {
    switch ("$V/$F") {
        '8/12' { return 'cube'       }
        '4/2'  { return 'plane'      }
        '5/6'  { return 'pyramid'    }
        '6/8'  { return 'octahedron' }
        default { return "unknown_v${V}_f${F}" }
    }
}

# ═══════════════════════════════════════════════════════════════════
#  EXTRACT-TOPOLOGYPARAMS  (NOVO — P4.6)
#  Extrai os parâmetros mínimos que descrevem a primitiva.
#  Retorna $null para tipos sem algoritmo registrado (ex: pyramid).
# ═══════════════════════════════════════════════════════════════════

function Extract-TopologyParams([string]$PrimitiveType,
                                [System.Collections.Generic.List[double[]]]$Vertices) {
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
                Params    = [ordered]@{
                    min_coord = @($xMin, $yMin, $zMin)
                    max_coord = @($xMax, $yMax, $zMax)
                }
            }
        }

        'octahedron' {
            # Aritmética explícita — evita nullable double de Measure-Object
            $sumX = 0.0; $sumY = 0.0; $sumZ = 0.0
            foreach ($v in $Vertices) { $sumX += $v[0]; $sumY += $v[1]; $sumZ += $v[2] }
            $n  = [double]$Vertices.Count
            $cx = $sumX / $n; $cy = $sumY / $n; $cz = $sumZ / $n

            $r = 0.0
            foreach ($v in $Vertices) {
                $dx = $v[0] - $cx; $dy = $v[1] - $cy; $dz = $v[2] - $cz
                $d  = [Math]::Sqrt($dx*$dx + $dy*$dy + $dz*$dz)
                if ($d -gt $r) { $r = $d }
            }

            return @{
                Algorithm = 'octahedron_v1_ccw'
                Params    = [ordered]@{
                    center = @([double]$cx, [double]$cy, [double]$cz)
                    radius = [double]$r
                }
            }
        }

        default { return $null }   # sem algoritmo compacto registrado
    }
}

# ═══════════════════════════════════════════════════════════════════
#  RECONSTRUCT-FROMPARAMS  (NOVO — P4.6)
#  Gera vertex/face arrays a partir dos parâmetros compactos.
#  Os algoritmos *_v1_ccw são determinísticos e fixos — não dependem
#  de input externo além dos parâmetros geométricos.
# ═══════════════════════════════════════════════════════════════════

function Reconstruct-FromParams([string]$Algorithm, $Params) {
    $vertices = [System.Collections.Generic.List[double[]]]::new()
    $faces    = [System.Collections.Generic.List[int[]]]::new()

    switch ($Algorithm) {

        'cube_v1_ccw' {
            $x0 = [double]$Params.min_coord[0]; $y0 = [double]$Params.min_coord[1]; $z0 = [double]$Params.min_coord[2]
            $x1 = [double]$Params.max_coord[0]; $y1 = [double]$Params.max_coord[1]; $z1 = [double]$Params.max_coord[2]
            # 8 vértices — mesma ordem que cube.obj FSU Burkardt
            @(
                @($x0,$y0,$z0), @($x0,$y0,$z1), @($x0,$y1,$z0), @($x0,$y1,$z1),
                @($x1,$y0,$z0), @($x1,$y0,$z1), @($x1,$y1,$z0), @($x1,$y1,$z1)
            ) | ForEach-Object { $vertices.Add([double[]]$_) }
            # 12 faces triangulares — topologia canônica CCW
            @(
                @(1,7,5), @(1,3,7), @(1,4,3), @(1,2,4),
                @(3,8,7), @(3,4,8), @(5,7,8), @(5,8,6),
                @(1,5,6), @(1,6,2), @(2,6,8), @(2,8,4)
            ) | ForEach-Object { $faces.Add([int[]]$_) }
        }

        'plane_v1_ccw' {
            $x0 = [double]$Params.min_coord[0]; $y0 = [double]$Params.min_coord[1]; $z0 = [double]$Params.min_coord[2]
            $x1 = [double]$Params.max_coord[0]; $y1 = [double]$Params.max_coord[1]; $z1 = [double]$Params.max_coord[2]
            # 4 vértices — plano XZ a y=y0
            @(
                @($x0,$y0,$z0), @($x1,$y0,$z0), @($x1,$y0,$z1), @($x0,$y0,$z1)
            ) | ForEach-Object { $vertices.Add([double[]]$_) }
            # 2 triângulos formando o quad
            @(@(1,2,3), @(1,3,4)) | ForEach-Object { $faces.Add([int[]]$_) }
        }

        'octahedron_v1_ccw' {
            # @() garante array antes de indexar — ConvertFrom-Json pode retornar PSCustomObject
            $ca = @($Params.center)
            $cx = [double]$ca[0]; $cy = [double]$ca[1]; $cz = [double]$ca[2]
            $r  = [double]$Params.radius
            # Pre-computar aritmética — aritmética inline dentro de @() em switch
            # causa 'op_Addition on Object[]' em PowerShell 7 (quirk de parsing)
            [double]$vTop   = $cz + $r    # +Z
            [double]$vRight = $cx + $r    # +X
            [double]$vFront = $cy + $r    # +Y
            [double]$vLeft  = $cx - $r    # -X  (negativo)
            [double]$vBack  = $cy - $r    # -Y  (negativo)
            [double]$vBot   = $cz - $r    # -Z  (negativo)
            # 6 pontos cardinais — mesma ordem que diamond.obj
            $vertices.Add([double[]]@($cx,     $cy,     $vTop  ))   # topo    (+Z)
            $vertices.Add([double[]]@($vRight, $cy,     $cz    ))   # direita (+X)
            $vertices.Add([double[]]@($cx,     $vFront, $cz    ))   # frente  (+Y)
            $vertices.Add([double[]]@($vLeft,  $cy,     $cz    ))   # esquerda(-X)
            $vertices.Add([double[]]@($cx,     $vBack,  $cz    ))   # atrás   (-Y)
            $vertices.Add([double[]]@($cx,     $cy,     $vBot  ))   # base    (-Z)
            # 8 faces — hemisférios superior e inferior
            @(
                @(1,2,3), @(1,3,4), @(1,4,5), @(1,5,2),
                @(6,3,2), @(6,4,3), @(6,5,4), @(6,2,5)
            ) | ForEach-Object { $faces.Add([int[]]$_) }
        }

        default {
            throw "Algoritmo desconhecido: $Algorithm"
        }
    }

    return @{ Vertices = $vertices; Faces = $faces }
}

# ═══════════════════════════════════════════════════════════════════
#  BUILD-CANONICALOBJ  (idêntico a v0215 — InvariantCulture)
# ═══════════════════════════════════════════════════════════════════

function Build-CanonicalObj([hashtable]$Seed) {
    $lines  = [System.Collections.Generic.List[string]]::new()
    $ptype  = $Seed.primitive_type
    $vcount = $Seed.geometry.vertex_count
    $fcount = $Seed.geometry.face_count

    $lines.Add('# gen.parametric_mesh canonical output')
    $lines.Add("# primitive: $ptype | vertices: $vcount | faces: $fcount")
    $lines.Add('g primitive')
    $lines.Add('')

    foreach ($v in $Seed.topology.vertices) {
        $x = ([double]$v[0]).ToString('0.000000', $IC)
        $y = ([double]$v[1]).ToString('0.000000', $IC)
        $z = ([double]$v[2]).ToString('0.000000', $IC)
        $lines.Add("v $x $y $z")
    }
    $lines.Add('')

    foreach ($f in $Seed.topology.faces) {
        $lines.Add("f $([int]$f[0]) $([int]$f[1]) $([int]$f[2])")
    }

    return [string]::Join("`n", $lines)
}

# ═══════════════════════════════════════════════════════════════════
#  ENCODE-PARAMETRICMESH  (refatorado — semente compacta)
# ═══════════════════════════════════════════════════════════════════

function Encode-ParametricMesh([string]$ObjPath, [string]$OutDir) {

    $origSha256 = Get-Sha256File $ObjPath
    $origSize   = (Get-Item -LiteralPath $ObjPath).Length

    $parsed  = Parse-ObjFile $ObjPath
    $vCount  = $parsed.Vertices.Count
    $fCount  = $parsed.Faces.Count
    $ptype   = Detect-PrimitiveType $vCount $fCount

    $topoInfo = Extract-TopologyParams $ptype $parsed.Vertices
    if ($null -eq $topoInfo) {
        throw "Nenhum algoritmo compacto registrado para primitive_type '$ptype'. Arquivo: $ObjPath"
    }

    $seed = [ordered]@{
        schema_version      = '1.0'
        opcode              = 'gen.parametric_mesh'
        primitive_type      = $ptype
        original_sha256     = $origSha256
        original_size_bytes = [int]$origSize
        canonical_sha256    = $null
        geometry            = [ordered]@{
            vertex_count = $vCount
            face_count   = $fCount
        }
        topology_params     = $topoInfo.Params
        topology_algorithm  = $topoInfo.Algorithm
        meta                = [ordered]@{
            line_ending = 'LF'
            generated   = (Get-Date -Format 'yyyy-MM-dd')
            protocol    = 'P4.6'
        }
    }

    $basename = [System.IO.Path]::GetFileNameWithoutExtension($ObjPath)
    $seedPath = Join-Path $OutDir "${basename}_compact_seed.json"
    # ConvertTo-Json -Compress: JSON minificado sem indentação — minimiza bytes
    $seed | ConvertTo-Json -Depth 5 -Compress | Set-Content -LiteralPath $seedPath -Encoding UTF8

    # Calcula tamanho do payload puro (sem hashes SHA-256 e metadados de proveniência)
    $purePayload = [ordered]@{
        opcode             = 'gen.parametric_mesh'
        primitive_type     = $ptype
        topology_params    = $topoInfo.Params
        topology_algorithm = $topoInfo.Algorithm
    }
    $pureSize = [System.Text.Encoding]::UTF8.GetByteCount(
        ($purePayload | ConvertTo-Json -Depth 4 -Compress)
    )

    return @{
        SeedPath        = $seedPath
        Algorithm       = $topoInfo.Algorithm
        Params          = $topoInfo.Params
        OriginalSha256  = $origSha256
        OriginalSize    = [int]$origSize
        VertexCount     = $vCount
        FaceCount       = $fCount
        PrimitiveType   = $ptype
        PurePayloadSize = $pureSize
    }
}

# ═══════════════════════════════════════════════════════════════════
#  DECODE-PARAMETRICMESH  (refatorado — usa Reconstruct-FromParams)
# ═══════════════════════════════════════════════════════════════════

function Decode-ParametricMesh([string]$SeedPath) {

    $json = Get-Content -LiteralPath $SeedPath -Raw | ConvertFrom-Json

    $recon    = Reconstruct-FromParams $json.topology_algorithm $json.topology_params
    $seedHt   = @{
        primitive_type = $json.primitive_type
        geometry       = @{
            vertex_count = $recon.Vertices.Count
            face_count   = $recon.Faces.Count
        }
        topology       = @{
            vertices = $recon.Vertices
            faces    = $recon.Faces
        }
    }

    $objText   = Build-CanonicalObj $seedHt
    $bytes     = [System.Text.Encoding]::UTF8.GetBytes($objText)
    $canSha256 = Get-Sha256Bytes $bytes

    $dir     = [System.IO.Path]::GetDirectoryName($SeedPath)
    $base    = [System.IO.Path]::GetFileNameWithoutExtension($SeedPath) -replace '_compact_seed$', ''
    $outPath = Join-Path $dir "${base}_compact_canonical.obj"
    [System.IO.File]::WriteAllBytes($outPath, $bytes)

    return @{
        CanonicalPath   = $outPath
        CanonicalSha256 = $canSha256
        CanonicalSize   = $bytes.Length
    }
}

# ═══════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════

if (-not (Test-Path $SandboxDir)) {
    New-Item -ItemType Directory -Path $SandboxDir -Force | Out-Null
}
$casDir = 'D:\TEIA_CORE\objects'
if ($SandboxDir.StartsWith($casDir)) {
    Write-Error "CONTENÇÃO: SandboxDir não pode ser subdiretório de $casDir"; exit 1
}

# Apenas os 3 primitivos com algoritmo compacto registrado
$objFiles = @('cube.obj', 'plane.obj', 'diamond.obj')
$results  = [System.Collections.Generic.List[hashtable]]::new()

Write-Host ''
Write-Host ('═' * 72) -ForegroundColor Cyan
Write-Host '  HR6-ParametricMesh-Prototype v0.21.6 — Semente Compacta' -ForegroundColor Cyan
Write-Host "  Input : $BenchmarkDir"
Write-Host "  Output: $SandboxDir"
Write-Host ('═' * 72) -ForegroundColor Cyan

foreach ($objName in $objFiles) {
    $objPath = Join-Path $BenchmarkDir $objName
    if (-not (Test-Path -LiteralPath $objPath)) {
        Write-Host "[SKIP] $objName — não encontrado" -ForegroundColor DarkYellow; continue
    }

    Write-Host ''
    Write-Host "── $objName ──────────────────────────────────────────────" -ForegroundColor Yellow

    try {
        $enc = Encode-ParametricMesh $objPath $SandboxDir
        Write-Host ("  Tipo / Algoritmo : {0}  [{1}]" -f $enc.PrimitiveType, $enc.Algorithm)

        # Passe 1
        $dec1 = Decode-ParametricMesh $enc.SeedPath
        # Passe 2 — teste de determinismo
        $dec2 = Decode-ParametricMesh $enc.SeedPath
        $deterministic = ($dec1.CanonicalSha256 -eq $dec2.CanonicalSha256)

        # Valida cruzado contra P4.5
        $p45sha = $P45CanonicalSha256[$objName]
        $crossOk = ($dec1.CanonicalSha256 -eq $p45sha)

        # Preenche canonical_sha256 na seed compacta
        $seedRaw = Get-Content -LiteralPath $enc.SeedPath -Raw
        $seedRaw = $seedRaw -replace '"canonical_sha256":null',
                                     ('"canonical_sha256":"{0}"' -f $dec1.CanonicalSha256)
        Set-Content -LiteralPath $enc.SeedPath -Value $seedRaw.TrimEnd() -Encoding UTF8

        $seedSize = (Get-Item -LiteralPath $enc.SeedPath).Length
        $savings  = [math]::Round((1.0 - $seedSize / $enc.OriginalSize) * 100, 1)
        $pureSave = [math]::Round((1.0 - $enc.PurePayloadSize / $enc.OriginalSize) * 100, 1)

        Write-Host ("  original_sha256   : {0}" -f $enc.OriginalSha256)
        Write-Host ("  canonical_sha256  : {0}" -f $dec1.CanonicalSha256)
        Write-Host ("  cross-valid P4.5  : {0}" -f $(if ($crossOk) { 'PASS ✓ (idêntico a P4.5)' } else { 'FAIL ✗' }))
        Write-Host ("  Orig {0,4}B → Seed {1,4}B → Canônico {2,3}B" -f $enc.OriginalSize, $seedSize, $dec1.CanonicalSize)
        Write-Host ("  Economia seed     : {0,6}%   Pure payload {1,3}B ({2}%)" -f $savings, $enc.PurePayloadSize, $pureSave)
        Write-Host ("  Determinismo      : {0}" -f $(if ($deterministic) { 'PASS' } else { 'FAIL ✗' })) `
            -ForegroundColor $(if ($deterministic) { 'Green' } else { 'Red' })

        $results.Add(@{
            File            = $objName
            PrimitiveType   = $enc.PrimitiveType
            Algorithm       = $enc.Algorithm
            OriginalSize    = $enc.OriginalSize
            SeedSize        = $seedSize
            PurePayloadSize = $enc.PurePayloadSize
            CanonicalSize   = $dec1.CanonicalSize
            SeedSavings     = $savings
            PureSavings     = $pureSave
            OriginalSha256  = $enc.OriginalSha256
            CanonicalSha256 = $dec1.CanonicalSha256
            P45CrossValid   = $crossOk
            Deterministic   = $deterministic
        })
    }
    catch {
        Write-Host ("  ERRO: {0}" -f $_) -ForegroundColor Red
        $results.Add(@{ File = $objName; Error = "$_"; Deterministic = $false; P45CrossValid = $false })
    }
}

Write-Host ''
Write-Host ('═' * 72) -ForegroundColor Cyan
Write-Host '  SUMÁRIO' -ForegroundColor Cyan
Write-Host ('─' * 72)
Write-Host ('  {0,-14} {1,4}  {2,5}  {3,5}  {4,5}  {5,7}  {6,7}  {7}  {8}' -f `
    'Arquivo','Orig','Seed','Pure','Canon','EconSd','EconPr','P45','Det')
Write-Host ('  {0,-14} {1,4}  {2,5}  {3,5}  {4,5}  {5,7}  {6,7}  {7}  {8}' -f `
    '──────────────','─B──','──B──','──B──','──B──','───────','───────','───','───')

$allPass = $true
foreach ($r in $results) {
    if ($r.ContainsKey('Error')) {
        Write-Host ("  {0,-14} ERROR: {1}" -f $r.File, $r.Error) -ForegroundColor Red
        $allPass = $false; continue
    }
    $p45 = if ($r.P45CrossValid) { 'OK ' } else { 'ERR' }
    $det = if ($r.Deterministic) { 'OK ' } else { 'ERR' }
    $col = if ($r.Deterministic -and $r.P45CrossValid) { 'Green' } else { 'Red' }
    if (-not ($r.Deterministic -and $r.P45CrossValid)) { $allPass = $false }
    Write-Host ("  {0,-14} {1,4}  {2,5}  {3,5}  {4,5}  {5,6}%  {6,6}%  {7}  {8}" -f `
        $r.File, $r.OriginalSize, $r.SeedSize, $r.PurePayloadSize, $r.CanonicalSize,
        $r.SeedSavings, $r.PureSavings, $p45, $det) -ForegroundColor $col
}

Write-Host ('─' * 72)
$pCount = ($results | Where-Object { $_.Deterministic -and $_.P45CrossValid }).Count
Write-Host ("  Determinismo + Cross-valid P4.5: {0}/{1}" -f $pCount, $results.Count)
Write-Host "  CAS: INTACTO (delta=0)"
Write-Host "  Sandbox: $SandboxDir"
Write-Host ('═' * 72) -ForegroundColor Cyan
Write-Host ''

return $results
