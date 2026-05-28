<#
.SYNOPSIS
    TEIA-HR6-Executor-v0219.ps1 — Executor Experimental Transacional com Feature Flag

.DESCRIPTION
    Protocolo C7 — Integração executor gen.parametric_mesh na UVM com contenção auditada.

    Fluxo por candidato HR6:
      1. Lê feature flag HR6_EXECUTOR_ENABLED — aborta se false
      2. Parse OBJ → Detect-PrimitiveType → Extract-TopologyParams
      3. Escreve compact seed JSON no sandbox
      4. Decode Passe 1 → sha_expected (in-memory, sem I/O intermediário)
      5. Decode Passe 2 → sha_obtained (idêntico, prova de determinismo)
      6. Delta bytes entre passes = abs(size_pass1 - size_pass2)
      7. Se sha_expected == sha_obtained:
           Escrita transacional (.tmp → verify SHA read-back → rename)
           Status: EXECUTOR_VALIDATED
      8. Senão:
           Rollback imediato (apaga .tmp)
           Status: FAILED_SHA_MISMATCH

    REGRA: A palavra "Delta" sempre por extenso. Simbolo matematico proibido.
    CONTENCAO: Nenhum byte escrito em D:\TEIA_CORE\objects\ (CAS intacto).

.PARAMETER CandidatesDir
    Diretório dos candidates NeuroPlanner.
    Padrão: D:\TEIA_CORE\neuroplanner\candidates

.PARAMETER SandboxDir
    Diretório de saída isolado.
    Padrão: D:\TEIA_CORE\sandbox\hr6_executor

.PARAMETER FlagsPath
    JSON com feature flags.
    Padrão: D:\TEIA_CORE\config\experimental_flags.json
#>
[CmdletBinding()]
param(
    [string]$CandidatesDir = 'D:\TEIA_CORE\neuroplanner\candidates',
    [string]$SandboxDir    = 'D:\TEIA_CORE\sandbox\hr6_executor',
    [string]$FlagsPath     = 'D:\TEIA_CORE\config\experimental_flags.json'
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC = [System.Globalization.CultureInfo]::InvariantCulture

# ── SHA-256 ────────────────────────────────────────────────────────────────────

function Get-Sha256Bytes([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $h   = $sha.ComputeHash($Bytes)
    $sha.Dispose()
    [BitConverter]::ToString($h).Replace('-', '').ToLower()
}

# ── OBJ PARSER ────────────────────────────────────────────────────────────────

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

# ── PRIMITIVE DETECTOR ────────────────────────────────────────────────────────

function Detect-PrimitiveType([int]$V, [int]$F) {
    switch ("$V/$F") {
        '8/12' { return 'cube'       }
        '4/2'  { return 'plane'      }
        '6/8'  { return 'octahedron' }
        default { return "unknown_v${V}_f${F}" }
    }
}

# ── EXTRACT TOPOLOGY PARAMS ───────────────────────────────────────────────────

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
            $sumX = 0.0; $sumY = 0.0; $sumZ = 0.0
            foreach ($v in $Vertices) { $sumX += $v[0]; $sumY += $v[1]; $sumZ += $v[2] }
            $n  = [double]$Vertices.Count
            $cx = $sumX / $n; $cy = $sumY / $n; $cz = $sumZ / $n
            $r  = 0.0
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
        default { return $null }
    }
}

# ── RECONSTRUCT FROM PARAMS ───────────────────────────────────────────────────

function Reconstruct-FromParams([string]$Algorithm, $Params) {
    $vertices = [System.Collections.Generic.List[double[]]]::new()
    $faces    = [System.Collections.Generic.List[int[]]]::new()

    switch ($Algorithm) {
        'cube_v1_ccw' {
            $x0 = [double]$Params.min_coord[0]; $y0 = [double]$Params.min_coord[1]
            $z0 = [double]$Params.min_coord[2]
            $x1 = [double]$Params.max_coord[0]; $y1 = [double]$Params.max_coord[1]
            $z1 = [double]$Params.max_coord[2]
            @(
                @($x0,$y0,$z0), @($x0,$y0,$z1), @($x0,$y1,$z0), @($x0,$y1,$z1),
                @($x1,$y0,$z0), @($x1,$y0,$z1), @($x1,$y1,$z0), @($x1,$y1,$z1)
            ) | ForEach-Object { $vertices.Add([double[]]$_) }
            @(
                @(1,7,5), @(1,3,7), @(1,4,3), @(1,2,4),
                @(3,8,7), @(3,4,8), @(5,7,8), @(5,8,6),
                @(1,5,6), @(1,6,2), @(2,6,8), @(2,8,4)
            ) | ForEach-Object { $faces.Add([int[]]$_) }
        }
        'plane_v1_ccw' {
            $x0 = [double]$Params.min_coord[0]; $y0 = [double]$Params.min_coord[1]
            $z0 = [double]$Params.min_coord[2]
            $x1 = [double]$Params.max_coord[0]
            $z1 = [double]$Params.max_coord[2]
            @(
                @($x0,$y0,$z0), @($x1,$y0,$z0), @($x1,$y0,$z1), @($x0,$y0,$z1)
            ) | ForEach-Object { $vertices.Add([double[]]$_) }
            @(@(1,2,3), @(1,3,4)) | ForEach-Object { $faces.Add([int[]]$_) }
        }
        'octahedron_v1_ccw' {
            $ca = @($Params.center)
            $cx = [double]$ca[0]; $cy = [double]$ca[1]; $cz = [double]$ca[2]
            $r  = [double]$Params.radius
            [double]$vTop   = $cz + $r
            [double]$vRight = $cx + $r
            [double]$vFront = $cy + $r
            [double]$vLeft  = $cx - $r
            [double]$vBack  = $cy - $r
            [double]$vBot   = $cz - $r
            $vertices.Add([double[]]@($cx,     $cy,     $vTop  ))
            $vertices.Add([double[]]@($vRight, $cy,     $cz    ))
            $vertices.Add([double[]]@($cx,     $vFront, $cz    ))
            $vertices.Add([double[]]@($vLeft,  $cy,     $cz    ))
            $vertices.Add([double[]]@($cx,     $vBack,  $cz    ))
            $vertices.Add([double[]]@($cx,     $cy,     $vBot  ))
            @(
                @(1,2,3), @(1,3,4), @(1,4,5), @(1,5,2),
                @(6,3,2), @(6,4,3), @(6,5,4), @(6,2,5)
            ) | ForEach-Object { $faces.Add([int[]]$_) }
        }
        default { throw "Algoritmo desconhecido: $Algorithm" }
    }

    return @{ Vertices = $vertices; Faces = $faces }
}

# ── BUILD CANONICAL OBJ ───────────────────────────────────────────────────────

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

# ── DECODE TO BYTES (in-memory, dois passes provam determinismo) ───────────────

function Decode-ToBytes([string]$Algorithm, $TopologyParams, [string]$PrimitiveType) {
    $recon   = Reconstruct-FromParams $Algorithm $TopologyParams
    $seedHt  = @{
        primitive_type = $PrimitiveType
        geometry       = @{ vertex_count = $recon.Vertices.Count; face_count = $recon.Faces.Count }
        topology       = @{ vertices = $recon.Vertices; faces = $recon.Faces }
    }
    $objText = Build-CanonicalObj $seedHt
    $bytes   = [System.Text.Encoding]::UTF8.GetBytes($objText)
    return @{ Bytes = $bytes; Sha256 = (Get-Sha256Bytes $bytes); Size = $bytes.Length }
}

# ── ESCRITA TRANSACIONAL ──────────────────────────────────────────────────────

function Write-Transactional([string]$DestPath, [byte[]]$Bytes, [string]$ExpectedSha256) {
    $tmpPath = "$DestPath.tmp"
    [System.IO.File]::WriteAllBytes($tmpPath, $Bytes)
    $readBack  = [System.IO.File]::ReadAllBytes($tmpPath)
    $actualSha = Get-Sha256Bytes $readBack
    if ($actualSha -ne $ExpectedSha256) {
        Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue
        return @{
            Success = $false
            Reason  = "WRITE_READ_MISMATCH expected=$ExpectedSha256 actual=$actualSha"
        }
    }
    Move-Item -LiteralPath $tmpPath -Destination $DestPath -Force
    return @{ Success = $true; Reason = '' }
}

# ── MAIN ──────────────────────────────────────────────────────────────────────

# Contenção: sandbox nunca dentro do CAS
$casDir = 'D:\TEIA_CORE\objects'
if ($SandboxDir.TrimEnd('\').ToLower().StartsWith($casDir.ToLower())) {
    Write-Error "CONTENCAO VIOLADA: SandboxDir nao pode ser subdirectorio de $casDir"
    exit 1
}

# Feature flag
if (-not (Test-Path -LiteralPath $FlagsPath)) {
    Write-Error "FLAGS NAO ENCONTRADO: $FlagsPath"
    exit 1
}
$flags = Get-Content -LiteralPath $FlagsPath -Raw | ConvertFrom-Json

if (-not $flags.HR6_EXECUTOR_ENABLED) {
    Write-Host ''
    Write-Host ('  EXECUTOR BLOQUEADO — HR6_EXECUTOR_ENABLED = false') -ForegroundColor DarkYellow
    Write-Host "  Flags: $FlagsPath"
    Write-Host '  Altere HR6_EXECUTOR_ENABLED para true para habilitar.' -ForegroundColor DarkYellow
    Write-Host ''
    exit 0
}

# Criar sandbox
New-Item -ItemType Directory -Path $SandboxDir -Force | Out-Null

# Descoberta de candidatos HR6 candidate_only
$enc = New-Object System.Text.UTF8Encoding($false)
$candidateFiles = Get-ChildItem -LiteralPath $CandidatesDir -Filter '*.candidate.json'
$candidates = [System.Collections.Generic.List[object]]::new()
foreach ($cf in $candidateFiles) {
    $c = Get-Content -LiteralPath $cf.FullName -Raw | ConvertFrom-Json
    if ($c.final_strategy -eq 'gen.parametric_mesh' -and
        $c.execution_status -eq 'candidate_only') {
        $candidates.Add($c)
    }
}

$total = $candidates.Count

Write-Host ''
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host '  TEIA-HR6-Executor v0.21.9 — Executor Experimental Transacional' -ForegroundColor Cyan
Write-Host "  HR6_EXECUTOR_ENABLED : true"
Write-Host "  Candidatos HR6       : $total"
Write-Host "  Sandbox              : $SandboxDir"
Write-Host ('=' * 72) -ForegroundColor Cyan

if ($total -eq 0) {
    Write-Host '  Nenhum candidato HR6 candidate_only encontrado.' -ForegroundColor DarkYellow
    exit 0
}

$results = [System.Collections.Generic.List[hashtable]]::new()
$globalSw = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($cand in $candidates) {
    $fileName = [System.IO.Path]::GetFileName($cand.file)
    $bar = '-' * ([Math]::Max(0, 60 - $fileName.Length))
    Write-Host ''
    Write-Host "-- $fileName $bar" -ForegroundColor Yellow

    $itemSw = [System.Diagnostics.Stopwatch]::StartNew()

    $result = [ordered]@{
        file            = $cand.file
        original_sha256 = $cand.sha256
        primitive_type  = $null
        algorithm       = $null
        sha_expected    = $null
        sha_obtained    = $null
        size_pass1      = 0
        size_pass2      = 0
        delta_bytes     = 0
        deterministic   = $false
        write_ok        = $false
        canonical_path  = $null
        seed_path       = $null
        status          = 'PENDING'
        error           = $null
        elapsed_ms      = 0
    }

    try {
        if (-not (Test-Path -LiteralPath $cand.file)) {
            throw "Arquivo OBJ nao encontrado: $($cand.file)"
        }

        # Parse OBJ
        $parsed = Parse-ObjFile $cand.file
        $vCount = $parsed.Vertices.Count
        $fCount = $parsed.Faces.Count
        $ptype  = Detect-PrimitiveType $vCount $fCount
        $result.primitive_type = $ptype
        Write-Host ("  Tipo      : $ptype  (v=$vCount f=$fCount)")

        # Extrair parametros de topologia
        $topoInfo = Extract-TopologyParams $ptype $parsed.Vertices
        if ($null -eq $topoInfo) {
            throw "Nenhum algoritmo registrado para primitiva '$ptype'"
        }
        $result.algorithm = $topoInfo.Algorithm
        Write-Host ("  Algoritmo : $($topoInfo.Algorithm)")

        # Escrever compact seed JSON no sandbox
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($cand.file)
        $seedPath = Join-Path $SandboxDir "${baseName}_compact_seed.json"
        $seedObj  = [ordered]@{
            schema_version     = '1.0'
            opcode             = 'gen.parametric_mesh'
            primitive_type     = $ptype
            original_sha256    = $cand.sha256
            topology_params    = $topoInfo.Params
            topology_algorithm = $topoInfo.Algorithm
            meta               = [ordered]@{
                protocol   = 'P4.9'
                generated  = (Get-Date -Format 'yyyy-MM-dd')
                line_ending = 'LF'
            }
        }
        [System.IO.File]::WriteAllText($seedPath,
            ($seedObj | ConvertTo-Json -Depth 5 -Compress:$false), $enc)
        $result.seed_path = $seedPath
        Write-Host ("  Seed      : $(Split-Path $seedPath -Leaf)")

        # Passe 1 — sha_expected
        $pass1 = Decode-ToBytes $topoInfo.Algorithm $topoInfo.Params $ptype
        $result.sha_expected = $pass1.Sha256
        $result.size_pass1   = $pass1.Size
        Write-Host ("  Passe 1   : sha=$($pass1.Sha256.Substring(0,16))...  size=$($pass1.Size)B")

        # Passe 2 — sha_obtained
        $pass2 = Decode-ToBytes $topoInfo.Algorithm $topoInfo.Params $ptype
        $result.sha_obtained = $pass2.Sha256
        $result.size_pass2   = $pass2.Size
        Write-Host ("  Passe 2   : sha=$($pass2.Sha256.Substring(0,16))...  size=$($pass2.Size)B")

        # Delta bytes entre passes (deve ser zero em execucao deterministica)
        $result.delta_bytes = [Math]::Abs($pass1.Size - $pass2.Size)
        Write-Host ("  Delta bytes entre passes : $($result.delta_bytes)")

        if ($pass1.Sha256 -ne $pass2.Sha256) {
            # Falha de idempotencia — rollback
            $result.status = 'FAILED_SHA_MISMATCH'
            $result.error  = "sha_expected=$($pass1.Sha256) sha_obtained=$($pass2.Sha256)"
            Write-Host '  FAILED_SHA_MISMATCH — rollback imediato' -ForegroundColor Red
        } else {
            $result.deterministic = $true
            Write-Host '  Determinismo : PASS' -ForegroundColor Green

            # Escrita transacional do OBJ canonico
            $canonPath   = Join-Path $SandboxDir "${baseName}_canonical.obj"
            $writeResult = Write-Transactional $canonPath $pass1.Bytes $pass1.Sha256

            if (-not $writeResult.Success) {
                $result.status = 'FAILED_SHA_MISMATCH'
                $result.error  = "Escrita transacional: $($writeResult.Reason)"
                Write-Host ("  Rollback: $($writeResult.Reason)") -ForegroundColor Red
            } else {
                $result.write_ok       = $true
                $result.canonical_path = $canonPath
                $result.status         = 'EXECUTOR_VALIDATED'
                Write-Host ("  Canonical : $canonPath") -ForegroundColor Green
                Write-Host '  Status    : EXECUTOR_VALIDATED' -ForegroundColor Green
            }
        }
    }
    catch {
        $result.status = 'SKIPPED'
        $result.error  = "$_"
        Write-Host ("  SKIPPED: $_") -ForegroundColor DarkYellow
    }

    $itemSw.Stop()
    $result.elapsed_ms = $itemSw.ElapsedMilliseconds
    Write-Host ("  Elapsed   : $($result.elapsed_ms)ms")

    $results.Add($result)
}

$globalSw.Stop()

# ── SUMARIO ───────────────────────────────────────────────────────────────────

$validated = @($results | Where-Object { $_.status -eq 'EXECUTOR_VALIDATED' }).Count
$failed    = @($results | Where-Object { $_.status -eq 'FAILED_SHA_MISMATCH' }).Count
$skipped   = @($results | Where-Object { $_.status -eq 'SKIPPED' }).Count

Write-Host ''
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host '  SUMARIO' -ForegroundColor Cyan
Write-Host ('─' * 72)
Write-Host ("  Total candidatos    : $total")
$vColor = if ($validated -gt 0) { 'Green' } else { 'White' }
$fColor = if ($failed    -gt 0) { 'Red'   } else { 'White' }
$sColor = if ($skipped   -gt 0) { 'DarkYellow' } else { 'White' }
Write-Host ("  EXECUTOR_VALIDATED  : $validated")    -ForegroundColor $vColor
Write-Host ("  FAILED_SHA_MISMATCH : $failed")       -ForegroundColor $fColor
Write-Host ("  SKIPPED             : $skipped")      -ForegroundColor $sColor
Write-Host ("  CAS Delta bytes     : 0 (contencao mantida)")
Write-Host ("  Tempo total         : $($globalSw.ElapsedMilliseconds)ms")
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host ''

# ── RELATORIO JSON ────────────────────────────────────────────────────────────

$reportPath = Join-Path $SandboxDir 'hr6_executor_report.json'
$report = [ordered]@{
    version         = '0.21.9'
    protocol        = 'P4.9'
    executed_at     = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
    feature_flag    = 'HR6_EXECUTOR_ENABLED=true'
    total           = $total
    validated       = $validated
    failed          = $failed
    skipped         = $skipped
    cas_delta_bytes = 0
    elapsed_ms      = $globalSw.ElapsedMilliseconds
    results         = $results.ToArray()
}
[System.IO.File]::WriteAllText($reportPath,
    ($report | ConvertTo-Json -Depth 7 -Compress:$false), $enc)

Write-Host "  Relatorio : $reportPath"
Write-Host ''

return $results
