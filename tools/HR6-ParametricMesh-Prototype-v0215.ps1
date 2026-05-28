<#
.SYNOPSIS
    HR6-ParametricMesh-Prototype-v0215.ps1 — Protótipo isolado do encoder/decoder gen.parametric_mesh

.DESCRIPTION
    Sandbox experimental para HR6 (CANDIDATA_EXPERIMENTAL).
    Implementa Encode-ParametricMesh e Decode-ParametricMesh sobre os 4 primitivos OBJ do P4.2.
    Calcula original_sha256 e canonical_sha256; verifica determinismo em dois passes.

    REGRA DE CONTENÇÃO ABSOLUTA:
      - Nada é escrito no CAS (objects/).
      - Nenhuma alteração no NeuroPlanner ou Watchdog.
      - Saída exclusiva em SandboxDir.

.PARAMETER BenchmarkDir
    Diretório com os 4 primitivos OBJ. Padrão: D:\TEIA_CORE\benchmarks\obj_parametric

.PARAMETER SandboxDir
    Diretório de saída isolado. Padrão: D:\TEIA_CORE\sandbox\hr6_prototype
#>
[CmdletBinding()]
param(
    [string]$BenchmarkDir = 'D:\TEIA_CORE\benchmarks\obj_parametric',
    [string]$SandboxDir   = 'D:\TEIA_CORE\sandbox\hr6_prototype'
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ═══════════════════════════════════════════════════════════════════
#  SHA-256
# ═══════════════════════════════════════════════════════════════════

function Get-Sha256File([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLower()
}

function Get-Sha256Bytes([byte[]]$Bytes) {
    $sha   = [System.Security.Cryptography.SHA256]::Create()
    $raw   = $sha.ComputeHash($Bytes)
    $sha.Dispose()
    [BitConverter]::ToString($raw).Replace('-', '').ToLower()
}

# ═══════════════════════════════════════════════════════════════════
#  OBJ PARSER
#  Extrai vértices (v) e faces (f).
#  Face tokens suportados: "A", "A//NA", "A/UA/NA" → extrai apenas índice v.
# ═══════════════════════════════════════════════════════════════════

function Parse-ObjFile([string]$Path) {
    $vertices = [System.Collections.Generic.List[double[]]]::new()
    $faces    = [System.Collections.Generic.List[int[]]]::new()

    foreach ($raw in [System.IO.File]::ReadAllLines($Path)) {
        $line = $raw.Trim()

        if ($line -match '^v\s+(.+)') {
            $parts = ($Matches[1].Trim() -split '\s+')
            $vertices.Add([double[]]@(
                [double]$parts[0],
                [double]$parts[1],
                [double]$parts[2]
            ))
        }
        elseif ($line -match '^f\s+(.+)') {
            $tokens = ($Matches[1].Trim() -split '\s+')
            # Strip //vn and /vt/vn — keep only vertex index
            $vi = $tokens | ForEach-Object { [int](($_ -split '[/\\]')[0]) }

            if ($vi.Count -eq 3) {
                $faces.Add([int[]]@($vi[0], $vi[1], $vi[2]))
            }
            elseif ($vi.Count -eq 4) {
                # Quad → 2 triangles (fan triangulation)
                $faces.Add([int[]]@($vi[0], $vi[1], $vi[2]))
                $faces.Add([int[]]@($vi[0], $vi[2], $vi[3]))
            }
            # Polygons with >4 vertices are outside HR6 scope; silently skipped
        }
    }

    return @{
        Vertices = $vertices
        Faces    = $faces
    }
}

# ═══════════════════════════════════════════════════════════════════
#  PRIMITIVE DETECTOR
#  Heurística baseada em (vertex_count / face_count).
#  Válida para os 4 primitivos do benchmark P4.2.
# ═══════════════════════════════════════════════════════════════════

function Detect-PrimitiveType([int]$V, [int]$F) {
    switch ("$V/$F") {
        '8/12' { return 'cube'        }
        '4/2'  { return 'plane'       }
        '5/6'  { return 'pyramid'     }
        '6/8'  { return 'octahedron'  }
        default { return "unknown_v${V}_f${F}" }
    }
}

# ═══════════════════════════════════════════════════════════════════
#  CANONICAL OBJ BUILDER
#  Formato fixo, deterministico, LF, UTF-8:
#    v X.XXXXXX Y.YYYYYY Z.ZZZZZZ
#    f A B C
#  Sem vn, sem vt, sem mtllib, sem trailing whitespace.
# ═══════════════════════════════════════════════════════════════════

function Build-CanonicalObj([hashtable]$Seed) {
    $lines = [System.Collections.Generic.List[string]]::new()

    $ptype  = $Seed.primitive_type
    $vcount = $Seed.geometry.vertex_count
    $fcount = $Seed.geometry.face_count

    $lines.Add('# gen.parametric_mesh canonical output')
    $lines.Add("# primitive: $ptype | vertices: $vcount | faces: $fcount")
    $lines.Add('g primitive')
    $lines.Add('')

    $ic = [System.Globalization.CultureInfo]::InvariantCulture
    foreach ($v in $Seed.topology.vertices) {
        $x = ([double]$v[0]).ToString('0.000000', $ic)
        $y = ([double]$v[1]).ToString('0.000000', $ic)
        $z = ([double]$v[2]).ToString('0.000000', $ic)
        $lines.Add("v $x $y $z")
    }
    $lines.Add('')

    foreach ($f in $Seed.topology.faces) {
        $lines.Add("f $([int]$f[0]) $([int]$f[1]) $([int]$f[2])")
    }

    # LF line endings; no trailing newline
    return [string]::Join("`n", $lines)
}

# ═══════════════════════════════════════════════════════════════════
#  ENCODE-PARAMETRICMESH
#  OBJ → Semente JSON canônica
# ═══════════════════════════════════════════════════════════════════

function Encode-ParametricMesh([string]$ObjPath, [string]$OutDir) {

    $origSha256 = Get-Sha256File $ObjPath
    $origSize   = (Get-Item -LiteralPath $ObjPath).Length

    $parsed = Parse-ObjFile $ObjPath
    $vCount = $parsed.Vertices.Count
    $fCount = $parsed.Faces.Count
    $ptype  = Detect-PrimitiveType $vCount $fCount

    # Build nested arrays explicitly to ensure ConvertTo-Json produces [[x,y,z],...]
    $vArr = [object[]]::new($vCount)
    for ($i = 0; $i -lt $vCount; $i++) {
        $vArr[$i] = [double[]]@(
            $parsed.Vertices[$i][0],
            $parsed.Vertices[$i][1],
            $parsed.Vertices[$i][2]
        )
    }

    $fArr = [object[]]::new($fCount)
    for ($i = 0; $i -lt $fCount; $i++) {
        $fArr[$i] = [int[]]@(
            $parsed.Faces[$i][0],
            $parsed.Faces[$i][1],
            $parsed.Faces[$i][2]
        )
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
        topology            = [ordered]@{
            vertices = $vArr
            faces    = $fArr
        }
        meta                = [ordered]@{
            line_ending = 'LF'
            generated   = (Get-Date -Format 'yyyy-MM-dd')
            protocol    = 'P4.5'
        }
    }

    $basename  = [System.IO.Path]::GetFileNameWithoutExtension($ObjPath)
    $seedPath  = Join-Path $OutDir "${basename}_seed.json"
    $seed | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $seedPath -Encoding UTF8

    return @{
        Seed          = $seed
        SeedPath      = $seedPath
        OriginalSha256 = $origSha256
        OriginalSize  = [int]$origSize
        VertexCount   = $vCount
        FaceCount     = $fCount
        PrimitiveType = $ptype
    }
}

# ═══════════════════════════════════════════════════════════════════
#  DECODE-PARAMETRICMESH
#  Semente JSON → OBJ canônico (bytes em memória + arquivo temp no sandbox)
# ═══════════════════════════════════════════════════════════════════

function Decode-ParametricMesh([string]$SeedPath) {

    $json = Get-Content -LiteralPath $SeedPath -Raw | ConvertFrom-Json

    # Rebuild typed arrays from PSCustomObject deserialization
    $vArr = [System.Collections.Generic.List[double[]]]::new()
    foreach ($v in $json.topology.vertices) {
        # $v may be Object[], PSCustomObject or similar depending on PS version
        $coords = @($v | ForEach-Object { [double]$_ })
        $vArr.Add([double[]]@($coords[0], $coords[1], $coords[2]))
    }

    $fArr = [System.Collections.Generic.List[int[]]]::new()
    foreach ($f in $json.topology.faces) {
        $idxs = @($f | ForEach-Object { [int]$_ })
        $fArr.Add([int[]]@($idxs[0], $idxs[1], $idxs[2]))
    }

    $seedHt = @{
        primitive_type = $json.primitive_type
        geometry       = @{
            vertex_count = [int]$json.geometry.vertex_count
            face_count   = [int]$json.geometry.face_count
        }
        topology       = @{
            vertices = $vArr
            faces    = $fArr
        }
    }

    $objText  = Build-CanonicalObj $seedHt
    $bytes    = [System.Text.Encoding]::UTF8.GetBytes($objText)
    $canSha256 = Get-Sha256Bytes $bytes

    $dir      = [System.IO.Path]::GetDirectoryName($SeedPath)
    $base     = [System.IO.Path]::GetFileNameWithoutExtension($SeedPath) -replace '_seed$', ''
    $outPath  = Join-Path $dir "${base}_canonical.obj"
    [System.IO.File]::WriteAllBytes($outPath, $bytes)

    return @{
        CanonicalPath   = $outPath
        CanonicalSha256 = $canSha256
        CanonicalSize   = $bytes.Length
    }
}

# ═══════════════════════════════════════════════════════════════════
#  MAIN — Bateria de testes sobre os 4 primitivos
# ═══════════════════════════════════════════════════════════════════

if (-not (Test-Path $SandboxDir)) {
    New-Item -ItemType Directory -Path $SandboxDir -Force | Out-Null
}

# Contenção: garantir que SandboxDir não está dentro de objects/
$casDir = 'D:\TEIA_CORE\objects'
if ($SandboxDir.StartsWith($casDir)) {
    Write-Error "CONTENÇÃO: SandboxDir não pode ser subdiretório de $casDir"
    exit 1
}

$objFiles = @('cube.obj', 'plane.obj', 'pyramid.obj', 'diamond.obj')
$results  = [System.Collections.Generic.List[hashtable]]::new()

Write-Host ''
Write-Host ('═' * 72) -ForegroundColor Cyan
Write-Host '  HR6-ParametricMesh-Prototype v0.21.5 — Sandbox Isolado' -ForegroundColor Cyan
Write-Host "  Input : $BenchmarkDir"
Write-Host "  Output: $SandboxDir"
Write-Host ('═' * 72) -ForegroundColor Cyan

foreach ($objName in $objFiles) {
    $objPath = Join-Path $BenchmarkDir $objName
    if (-not (Test-Path -LiteralPath $objPath)) {
        Write-Host "[SKIP] $objName — arquivo não encontrado" -ForegroundColor DarkYellow
        continue
    }

    Write-Host ''
    Write-Host "── $objName ──────────────────────────────────────────────" -ForegroundColor Yellow

    try {
        # ── ENCODE ──────────────────────────────────────────────────
        $enc = Encode-ParametricMesh $objPath $SandboxDir
        Write-Host ("  Tipo detectado : {0}" -f $enc.PrimitiveType)
        Write-Host ("  Vértices/Faces : {0}v  {1}f" -f $enc.VertexCount, $enc.FaceCount)
        Write-Host ("  original_sha256: {0}" -f $enc.OriginalSha256)
        Write-Host ("  Seed escrita   : {0}" -f (Split-Path $enc.SeedPath -Leaf))

        # ── DECODE (passe 1) ─────────────────────────────────────────
        $dec1 = Decode-ParametricMesh $enc.SeedPath

        # ── DECODE (passe 2 — teste de determinismo) ─────────────────
        $dec2 = Decode-ParametricMesh $enc.SeedPath
        $deterministic = ($dec1.CanonicalSha256 -eq $dec2.CanonicalSha256)

        # Preenche canonical_sha256 na seed (substitui null)
        $seedRaw = Get-Content -LiteralPath $enc.SeedPath -Raw
        $seedRaw = $seedRaw -replace '"canonical_sha256":\s*null', (
            '"canonical_sha256": "{0}"' -f $dec1.CanonicalSha256
        )
        Set-Content -LiteralPath $enc.SeedPath -Value $seedRaw -Encoding UTF8

        # ── MÉTRICAS ─────────────────────────────────────────────────
        $seedSize = (Get-Item -LiteralPath $enc.SeedPath).Length
        $savings  = [math]::Round((1.0 - $seedSize / $enc.OriginalSize) * 100, 1)

        Write-Host ("  canonical_sha256: {0}" -f $dec1.CanonicalSha256)
        Write-Host ("  Tamanho orig  : {0,6} bytes" -f $enc.OriginalSize)
        Write-Host ("  Tamanho seed  : {0,6} bytes" -f $seedSize)
        Write-Host ("  Tamanho canon : {0,6} bytes" -f $dec1.CanonicalSize)
        Write-Host ("  Economia real : {0,6}%" -f $savings)

        if ($deterministic) {
            Write-Host '  Determinismo  : PASS (passe 1 == passe 2)' -ForegroundColor Green
        } else {
            Write-Host '  Determinismo  : FAIL — SHA-256 divergiu entre passes!' -ForegroundColor Red
        }

        $results.Add(@{
            File             = $objName
            PrimitiveType    = $enc.PrimitiveType
            OriginalSize     = $enc.OriginalSize
            SeedSize         = $seedSize
            CanonicalSize    = $dec1.CanonicalSize
            Savings          = $savings
            OriginalSha256   = $enc.OriginalSha256
            CanonicalSha256  = $dec1.CanonicalSha256
            Deterministic    = $deterministic
        })
    }
    catch {
        Write-Host ("  ERRO: {0}" -f $_) -ForegroundColor Red
        $results.Add(@{
            File          = $objName
            PrimitiveType = 'ERROR'
            Savings       = 'N/A'
            Deterministic = $false
            Error         = "$_"
        })
    }
}

# ═══════════════════════════════════════════════════════════════════
#  SUMÁRIO FINAL
# ═══════════════════════════════════════════════════════════════════

Write-Host ''
Write-Host ('═' * 72) -ForegroundColor Cyan
Write-Host '  SUMÁRIO' -ForegroundColor Cyan
Write-Host ('─' * 72)
Write-Host ('  {0,-15} {1,-13} {2,7}  {3,7}  {4,7}  {5}' -f `
    'Arquivo', 'Tipo', 'Orig', 'Seed', 'Econ.', 'Determ.')
Write-Host ('  {0,-15} {1,-13} {2,7}  {3,7}  {4,7}  {5}' -f `
    '───────────────', '─────────────', '─────B', '─────B', '──────', '───────')

$allPass = $true
foreach ($r in $results) {
    if ($r.ContainsKey('Error')) {
        Write-Host ("  {0,-15} {1,-13}   ERROR" -f $r.File, 'ERROR') -ForegroundColor Red
        $allPass = $false
        continue
    }
    $det = if ($r.Deterministic) { 'PASS' } else { 'FAIL' }
    $col = if ($r.Deterministic) { 'Green' } else { 'Red' }
    if (-not $r.Deterministic) { $allPass = $false }
    Write-Host ("  {0,-15} {1,-13} {2,7}  {3,7}  {4,6}%  {5}" -f `
        $r.File, $r.PrimitiveType, $r.OriginalSize, $r.SeedSize, $r.Savings, $det) `
        -ForegroundColor $col
}

Write-Host ('─' * 72)
$passCount = ($results | Where-Object { $_.Deterministic -eq $true }).Count
Write-Host ("  Determinismo: {0}/{1} PASS" -f $passCount, $results.Count)
Write-Host "  CAS: INTACTO (delta=0 — nenhum arquivo escrito em objects/)"
Write-Host "  Sandbox: $SandboxDir"
Write-Host ('═' * 72) -ForegroundColor Cyan
Write-Host ''

# Retorna resultados para pipeline externo se necessário
return $results
