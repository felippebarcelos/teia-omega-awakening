<#
.SYNOPSIS
    TEIA-Ingestor-Active-v0300.ps1 — Ingestor Ativo (Fase P6.0)

.DESCRIPTION
    Eleva a TEIA de classificador passivo a Gestor de Armazenamento Ativo.

    Para cada arquivo no TargetDir:
      1. Determina a estratégia (candidate existente ou análise inline)
      2. Codifica/comprime para D:\TEIA_CORE\objects\ (CAS)
      3. Cria arquivo stub (.teia_stub) com JSON de metadados
      4. Deleta o arquivo original

    CONTENÇÃO P6.0: TargetDir DEVE conter 'ActiveDrive_Test'.
    Fora do ambiente de teste, use -OverrideContainment explicitamente.

    ESTRATÉGIAS:
      gen.repeat         → seed JSON (~35B) em CAS (.teia_seed)
      gen.pattern        → seed JSON (<512B) em CAS (.teia_seed)
      gen.parametric_mesh → Brotli-compressed OBJ + seed no stub (.br)
      cmp.lzma           → GZip-compressed (.gz) — melhor disponível em .NET BCL
      cmp.brotli         → Brotli-compressed (.br)
      cas.raw            → cópia raw content-addressed (.raw)

.PARAMETER TargetDir
    Diretório a ingerir. Deve conter 'ActiveDrive_Test' (contenção P6.0).

.PARAMETER CasRoot
    Raiz do CAS. Padrão: D:\TEIA_CORE\objects

.PARAMETER CandidatesRoot
    Pasta de candidates do NeuroPlanner. Padrão: D:\TEIA_CORE\neuroplanner\candidates

.PARAMETER PlannerScript
    NeuroPlanner para arquivos sem candidate existente.
    Padrão: D:\TEIA_CORE\tools\TEIA-NeuroPlanner-v0218.ps1

.PARAMETER OverrideContainment
    Desabilita o guard de contenção ActiveDrive_Test. USO APENAS EM TESTES CONTROLADOS.

.PARAMETER DryRun
    Analisa sem criar CAS, stubs ou deletar arquivos.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TargetDir,
    [string]$CasRoot        = 'D:\TEIA_CORE\objects',
    [string]$CandidatesRoot = 'D:\TEIA_CORE\neuroplanner\candidates',
    [string]$PlannerScript  = 'D:\TEIA_CORE\tools\TEIA-NeuroPlanner-v0218.ps1',
    [switch]$OverrideContainment,
    [switch]$DryRun
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC  = [System.Globalization.CultureInfo]::InvariantCulture
$enc = New-Object System.Text.UTF8Encoding($false)

# ── Contenção P6.0 ────────────────────────────────────────────────────────────
if (-not $OverrideContainment -and $TargetDir -notmatch 'ActiveDrive_Test') {
    Write-Host '' -ForegroundColor Red
    Write-Host '  [INGESTOR] CONTENCAO P6.0 VIOLADA' -ForegroundColor Red
    Write-Host "  TargetDir nao contem 'ActiveDrive_Test': $TargetDir" -ForegroundColor Red
    Write-Host '  Use -OverrideContainment para operar fora do ambiente de teste.' -ForegroundColor Red
    Write-Host ''
    exit 1
}

if (-not (Test-Path -LiteralPath $TargetDir)) {
    Write-Host "[INGESTOR] ERRO: TargetDir nao encontrado: $TargetDir" -ForegroundColor Red; exit 1
}

# ── SHA-256 helpers ───────────────────────────────────────────────────────────

function Get-Sha256File([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLower()
}

function Get-Sha256Bytes([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $h   = $sha.ComputeHash($Bytes)
    $sha.Dispose()
    [BitConverter]::ToString($h).Replace('-','').ToLower()
}

function Get-Sha256Stream([string]$Path) {
    $sha    = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($Path)
    $h      = $sha.ComputeHash($stream)
    $stream.Dispose(); $sha.Dispose()
    [BitConverter]::ToString($h).Replace('-','').ToLower()
}

# ── CAS path builder ──────────────────────────────────────────────────────────

function Get-CasPath([string]$Sha256, [string]$Extension) {
    $a = $Sha256.Substring(0,2); $b = $Sha256.Substring(2,2)
    $dir = Join-Path $CasRoot "$a\$b"
    if (-not $DryRun) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Join-Path $dir "${Sha256}${Extension}"
}

# ── Structural profiler (inline, subset de NeuroPlanner) ──────────────────────

function Get-Entropy([byte[]]$b) {
    if ($b.Length -eq 0) { return 0.0 }
    $freq = New-Object int[] 256
    foreach ($byte in $b) { $freq[$byte]++ }
    $len = $b.Length; $e = 0.0
    foreach ($c in $freq) {
        if ($c -gt 0) { $p = $c/$len; $e -= $p*[Math]::Log($p,2) }
    }
    [math]::Round($e, 4)
}

function Get-UniqueBytes([byte[]]$b) {
    $seen = New-Object bool[] 256
    foreach ($byte in $b) { $seen[$byte] = $true }
    ($seen | Where-Object { $_ }).Count
}

function Find-Period([byte[]]$b) {
    $maxP = [Math]::Min(512, [Math]::Floor($b.Length / 4))
    for ($p = 1; $p -le $maxP; $p++) {
        if ($b.Length % $p -ne 0) { continue }
        $ok    = $true; $check = [Math]::Min(65536, $b.Length)
        for ($i = $p; $i -lt $check; $i++) {
            if ($b[$i] -ne $b[$i % $p]) { $ok = $false; break }
        }
        if ($ok) {
            for ($i = $check; $i -lt $b.Length; $i++) {
                if ($b[$i] -ne $b[$i % $p]) { $ok = $false; break }
            }
        }
        if ($ok) { return $p }
    }
    return 0
}

function Detect-MagicType([byte[]]$b) {
    if ($b.Length -lt 4) { return 'unknown' }
    $h = $b[0..([Math]::Min(15, $b.Length-1))]
    if ($h[0] -eq 0x89 -and $h[1] -eq 0x50 -and $h[2] -eq 0x4E -and $h[3] -eq 0x47) { return 'image/png' }
    if ($h[0] -eq 0xFF -and $h[1] -eq 0xD8 -and $h[2] -eq 0xFF)                      { return 'image/jpeg' }
    if ($h[0] -eq 0x25 -and $h[1] -eq 0x50 -and $h[2] -eq 0x44 -and $h[3] -eq 0x46) { return 'application/pdf' }
    if ($h[0] -eq 0x50 -and $h[1] -eq 0x4B -and $h[2] -eq 0x03 -and $h[3] -eq 0x04) { return 'application/zip' }
    if ($h[0] -eq 0x4D -and $h[1] -eq 0x5A)                                           { return 'application/pe' }
    if ($h[0] -eq 0x1F -and $h[1] -eq 0x8B)                                           { return 'application/gzip' }
    if ($h[0] -eq 0x42 -and $h[1] -eq 0x5A -and $h[2] -eq 0x68)                      { return 'application/bzip2' }
    if ($h[0] -eq 0xFD -and $h[1] -eq 0x37 -and $h[2] -eq 0x7A -and $h[3] -eq 0x58) { return 'application/xz' }
    if ($h[0] -eq 0x37 -and $h[1] -eq 0x7A -and $h[2] -eq 0xBC -and $h[3] -eq 0xAF) { return 'application/7z' }
    if ($h[0] -eq 0xEF -and $h[1] -eq 0xBB -and $h[2] -eq 0xBF)                      { return 'text/utf8bom' }
    return 'application/octet-stream'
}

function Get-ObjVertexFaceCount([byte[]]$Bytes) {
    $text = [System.Text.Encoding]::UTF8.GetString($Bytes)
    $v = 0; $f = 0
    foreach ($raw in ($text -split '\n')) {
        if ($v -ge 20) { break }
        $line = $raw.Trim()
        if     ($line -match '^v\s+')  { $v++ }
        elseif ($line -match '^f\s+(.+)') {
            $tokens = ($Matches[1].Trim() -split '\s+').Count
            $f += if ($tokens -eq 4) { 2 } else { 1 }
        }
    }
    return @{ V = $v; F = $f }
}

function Get-HardRuleStrategy([System.IO.FileInfo]$File) {
    $bytes   = [System.IO.File]::ReadAllBytes($File.FullName)
    $magic   = Detect-MagicType $bytes
    $isText  = $true
    $checkLen = [Math]::Min(4096, $bytes.Length)
    for ($i = 0; $i -lt $checkLen; $i++) { if ($bytes[$i] -eq 0) { $isText = $false; break } }

    # HR6 OBJ override
    if ($magic -in @('application/octet-stream','text/utf8bom') -and $isText `
        -and $File.Extension.ToLower() -eq '.obj') { $magic = 'model/obj' }

    $sampleLen = [Math]::Min(524288, $bytes.Length)
    $sample    = if ($sampleLen -lt $bytes.Length) { $bytes[0..($sampleLen-1)] } else { $bytes }

    $uniqueB = Get-UniqueBytes $sample
    $period  = Find-Period $sample
    $entropy = Get-Entropy $sample

    $compressedMagics = @('application/zip','application/gzip','application/bzip2','application/xz','application/7z')

    if ($uniqueB -eq 1)                   { return @{ Strategy='gen.repeat';  Rule='HR1' } }
    if ($period -gt 0 -and $period -le 512) { return @{ Strategy='gen.pattern'; Rule='HR2' } }
    if ($entropy -ge 7.0)                 { return @{ Strategy='cas.raw';     Rule='HR3' } }
    if ($magic -in $compressedMagics)     { return @{ Strategy='cas.raw';     Rule='HR4' } }

    if ($magic -eq 'model/obj' -and $File.Length -lt 4096) {
        $oqs = Get-ObjVertexFaceCount $bytes
        if ($oqs.V -gt 0 -and $oqs.V -lt 20) {
            return @{ Strategy='gen.parametric_mesh'; Rule='HR6'; VCount=$oqs.V; FCount=$oqs.F }
        }
    }

    if ($File.Length -lt 8192) { return @{ Strategy='cmp.brotli'; Rule='HR5' } }

    # LLM path → fallback determinístico para cmp.lzma
    return @{ Strategy='cmp.lzma'; Rule='LLM_FALLBACK' }
}

# ── Determinação de estratégia (candidate existente OU análise inline) ────────

function Get-Strategy([System.IO.FileInfo]$File, [string]$Sha256) {
    $candidatePath = Join-Path $CandidatesRoot "$Sha256.candidate.json"
    if (Test-Path -LiteralPath $candidatePath) {
        $c = Get-Content -LiteralPath $candidatePath -Raw | ConvertFrom-Json
        return @{
            Strategy = [string]$c.final_strategy
            Rule     = if ($c.hard_rule_decision.rule_id) { [string]$c.hard_rule_decision.rule_id } else { 'LLM' }
            Source   = 'candidate'
        }
    }
    # Sem candidate: análise inline (hard rules)
    $hr = Get-HardRuleStrategy -File $File
    return @{ Strategy=$hr.Strategy; Rule=$hr.Rule; Source='inline' }
}

# ── Compressores (streaming, OOM guard: CopyTo 64KB buffer) ──────────────────

function Compress-Gzip([string]$Source, [string]$Dest) {
    $inStream  = [System.IO.File]::OpenRead($Source)
    $outStream = [System.IO.File]::Create($Dest)
    $gz = New-Object System.IO.Compression.GZipStream($outStream,
              [System.IO.Compression.CompressionLevel]::Optimal)
    $inStream.CopyTo($gz, 65536)
    $gz.Dispose(); $inStream.Dispose(); $outStream.Dispose()
}

function Compress-Brotli([string]$Source, [string]$Dest) {
    $inStream  = [System.IO.File]::OpenRead($Source)
    $outStream = [System.IO.File]::Create($Dest)
    $br = New-Object System.IO.Compression.BrotliStream($outStream,
              [System.IO.Compression.CompressionLevel]::Optimal)
    $inStream.CopyTo($br, 65536)
    $br.Dispose(); $inStream.Dispose(); $outStream.Dispose()
}

function Stream-RawCopy([string]$Source, [string]$Dest) {
    $inStream  = [System.IO.File]::OpenRead($Source)
    $outStream = [System.IO.File]::Create($Dest)
    $inStream.CopyTo($outStream, 65536)
    $inStream.Dispose(); $outStream.Dispose()
}

# ── gen.repeat: seed builder + verifier ──────────────────────────────────────

function Build-RepeatSeed([System.IO.FileInfo]$File, [string]$OrigSha256) {
    $bytes   = [System.IO.File]::ReadAllBytes($File.FullName)
    $byteVal = $bytes[0]
    $hex     = $byteVal.ToString('x2')

    # Verificação: reconstituir → sha256 deve bater
    $rebuilt = New-Object byte[] $bytes.Length
    for ($i = 0; $i -lt $bytes.Length; $i++) { $rebuilt[$i] = $byteVal }
    $rebuiltSha = Get-Sha256Bytes $rebuilt

    if ($rebuiltSha -ne $OrigSha256) {
        return $null   # Segurança: seed não verifica — não deletar o original
    }
    return [ordered]@{
        opcode          = 'gen.repeat'
        value_hex       = $hex
        size_bytes      = [long]$File.Length
        original_sha256 = $OrigSha256
    }
}

# ── gen.pattern: seed builder + verifier ─────────────────────────────────────

function Build-PatternSeed([System.IO.FileInfo]$File, [string]$OrigSha256, [int]$Period) {
    $bytes   = [System.IO.File]::ReadAllBytes($File.FullName)
    $pattern = $bytes[0..($Period-1)]
    $repeat  = [long]$File.Length / $Period
    $patB64  = [Convert]::ToBase64String($pattern)
    $patHex  = -join ($pattern | ForEach-Object { $_.ToString('x2') })

    # Verificação: reconstituir → sha256 deve bater
    $rebuilt = New-Object byte[] $bytes.Length
    for ($r = 0; $r -lt $repeat; $r++) {
        [Array]::Copy($pattern, 0, $rebuilt, $r * $Period, $Period)
    }
    $rebuiltSha = Get-Sha256Bytes $rebuilt

    if ($rebuiltSha -ne $OrigSha256) { return $null }
    return [ordered]@{
        opcode          = 'gen.pattern'
        pattern_b64     = $patB64
        pattern_hex     = $patHex
        period_bytes    = $Period
        repeat          = [long]$repeat
        size_bytes      = [long]$File.Length
        original_sha256 = $OrigSha256
    }
}

# ── gen.parametric_mesh: OBJ parser + seed builder ───────────────────────────

function Build-ObjSeed([System.IO.FileInfo]$File) {
    $vertices = [System.Collections.Generic.List[double[]]]::new()
    $faces    = [System.Collections.Generic.List[int[]]]::new()
    foreach ($raw in [System.IO.File]::ReadAllLines($File.FullName)) {
        $line = $raw.Trim()
        if ($line -match '^v\s+(.+)') {
            $p = ($Matches[1].Trim() -split '\s+')
            $vertices.Add([double[]]@([double]$p[0], [double]$p[1], [double]$p[2]))
        }
        elseif ($line -match '^f\s+(.+)') {
            $tokens = ($Matches[1].Trim() -split '\s+')
            $vi = $tokens | ForEach-Object { [int](($_ -split '[/\\]')[0]) }
            if ($vi.Count -eq 3) { $faces.Add([int[]]@($vi[0],$vi[1],$vi[2])) }
            elseif ($vi.Count -eq 4) {
                $faces.Add([int[]]@($vi[0],$vi[1],$vi[2]))
                $faces.Add([int[]]@($vi[0],$vi[2],$vi[3]))
            }
        }
    }
    $vCount = $vertices.Count; $fCount = $faces.Count
    $ptype  = switch ("$vCount/$fCount") { '8/12' {'cube'} '4/2' {'plane'} '6/8' {'octahedron'} default {"unknown_v${vCount}_f${fCount}"} }

    # Topology params
    $topoParams = if ($ptype -in @('cube','plane')) {
        $xMin = ($vertices | ForEach-Object { $_[0] } | Measure-Object -Minimum).Minimum
        $yMin = ($vertices | ForEach-Object { $_[1] } | Measure-Object -Minimum).Minimum
        $zMin = ($vertices | ForEach-Object { $_[2] } | Measure-Object -Minimum).Minimum
        $xMax = ($vertices | ForEach-Object { $_[0] } | Measure-Object -Maximum).Maximum
        $yMax = ($vertices | ForEach-Object { $_[1] } | Measure-Object -Maximum).Maximum
        $zMax = ($vertices | ForEach-Object { $_[2] } | Measure-Object -Maximum).Maximum
        [ordered]@{ min_coord=@($xMin,$yMin,$zMin); max_coord=@($xMax,$yMax,$zMax) }
    } elseif ($ptype -eq 'octahedron') {
        $cx = ($vertices | ForEach-Object { $_[0] } | Measure-Object -Average).Average
        $cy = ($vertices | ForEach-Object { $_[1] } | Measure-Object -Average).Average
        $cz = ($vertices | ForEach-Object { $_[2] } | Measure-Object -Average).Average
        $r  = ($vertices | ForEach-Object {
            $dx=$_[0]-$cx; $dy=$_[1]-$cy; $dz=$_[2]-$cz
            [Math]::Sqrt($dx*$dx+$dy*$dy+$dz*$dz) } | Measure-Object -Maximum).Maximum
        [ordered]@{ center=@($cx,$cy,$cz); radius=$r }
    } else {
        [ordered]@{ vertex_count=$vCount; face_count=$fCount }
    }

    return [ordered]@{
        schema           = 'teia_param_seed_v1'
        opcode           = 'gen.parametric_mesh'
        primitive_type   = $ptype
        algorithm        = "${ptype}_v1_ccw"
        vertex_count     = $vCount
        face_count       = $fCount
        topology_params  = $topoParams
    }
}

# ── Ingestão de um único arquivo ──────────────────────────────────────────────

function Ingest-File([System.IO.FileInfo]$File) {
    $origSha = Get-Sha256File $File.FullName
    $dec     = Get-Strategy -File $File -Sha256 $origSha
    $strat   = $dec.Strategy

    Write-Host ("  [IN]  {0,-40}  {1,7} KB  [{2}] {3}" -f `
        $File.Name, [math]::Round($File.Length/1KB,1), $dec.Rule, $strat) -ForegroundColor Yellow

    $casExt = switch ($strat) {
        'gen.repeat'          { '.teia_seed' }
        'gen.pattern'         { '.teia_seed' }
        'gen.parametric_mesh' { '.br'        }   # Brotli para SHA-256 verificável
        'cmp.lzma'            { '.gz'        }   # GZip (melhor disponível em .NET BCL)
        'cmp.brotli'          { '.br'        }
        default               { '.raw'       }   # cas.raw
    }

    # CAS path usa SHA-256 do ORIGINAL como chave de endereço
    $casPath      = Get-CasPath -Sha256 $origSha -Extension $casExt
    $parametricSeed = $null

    if ($DryRun) {
        Write-Host ("        → DRY-RUN: CAS seria {0} | strat={1}" -f (Split-Path $casPath -Leaf), $strat) -ForegroundColor DarkGray
        return [ordered]@{ name=$File.Name; size_bytes=$File.Length; strategy=$strat; rule=$dec.Rule; status='DRY-RUN' }
    }

    # Evitar re-ingestão (idempotência)
    if (Test-Path -LiteralPath "$($File.FullName).teia_stub") {
        Write-Host "        → SKIP (stub já existe)" -ForegroundColor DarkGray
        return [ordered]@{ name=$File.Name; size_bytes=$File.Length; strategy=$strat; rule=$dec.Rule; status='SKIP_ALREADY_INGESTED' }
    }

    try {
        switch ($strat) {
            'gen.repeat' {
                $seed = Build-RepeatSeed -File $File -OrigSha256 $origSha
                if ($null -eq $seed) { throw "gen.repeat seed nao verificou SHA-256" }
                $seedJson = $seed | ConvertTo-Json -Compress
                [System.IO.File]::WriteAllText($casPath, $seedJson, $enc)
            }
            'gen.pattern' {
                $bytes  = [System.IO.File]::ReadAllBytes($File.FullName)
                $period = Find-Period $bytes
                $seed   = Build-PatternSeed -File $File -OrigSha256 $origSha -Period $period
                if ($null -eq $seed) { throw "gen.pattern seed nao verificou SHA-256" }
                $seedJson = $seed | ConvertTo-Json -Compress
                [System.IO.File]::WriteAllText($casPath, $seedJson, $enc)
            }
            'gen.parametric_mesh' {
                # Brotli-comprime os bytes originais (SHA-256 verificável no restore)
                Compress-Brotli -Source $File.FullName -Dest $casPath
                # Gera seed paramétrico (metadado para regeneração futura — não o artefato de restore)
                $parametricSeed = Build-ObjSeed -File $File
            }
            'cmp.lzma' {
                Compress-Gzip -Source $File.FullName -Dest $casPath
            }
            'cmp.brotli' {
                Compress-Brotli -Source $File.FullName -Dest $casPath
            }
            default {   # cas.raw
                Stream-RawCopy -Source $File.FullName -Dest $casPath
            }
        }

        $casSha  = Get-Sha256Stream -Path $casPath
        $casSize = (Get-Item -LiteralPath $casPath).Length
        $savings = [math]::Round((1.0 - ($casSize / [double]$File.Length)) * 100, 1)

        # Stub JSON
        $stub = [ordered]@{
            teia_version        = 'v0.30.0'
            schema              = 'teia_stub'
            original_name       = $File.Name
            original_size_bytes = $File.Length
            original_sha256     = $origSha
            final_strategy      = $strat
            cas_encoding        = $casExt.TrimStart('.')
            cas_path            = $casPath
            cas_sha256          = $casSha
            cas_size_bytes      = $casSize
            savings_pct         = $savings
            ingest_timestamp    = (Get-Date -Format 'o')
        }
        if ($null -ne $parametricSeed) { $stub['parametric_seed'] = $parametricSeed }

        # Escrita atômica do stub (.tmp → rename) ANTES de deletar o original
        $stubPath = "$($File.FullName).teia_stub"
        $stubTmp  = "$stubPath.tmp"
        $stubJson = $stub | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText($stubTmp, $stubJson, $enc)
        Move-Item -LiteralPath $stubTmp -Destination $stubPath -Force

        # Apenas após stub escrito com sucesso: deletar original
        Remove-Item -LiteralPath $File.FullName -Force

        Write-Host ("        → stub: {0}  |  CAS: {1} KB  |  -{2}%" -f `
            (Split-Path $stubPath -Leaf), [math]::Round($casSize/1KB,1), $savings) -ForegroundColor Green

        return [ordered]@{
            name            = $File.Name
            original_bytes  = $File.Length
            cas_bytes       = $casSize
            savings_pct     = $savings
            strategy        = $strat
            rule            = $dec.Rule
            cas_sha256      = $casSha
            status          = 'INGESTED'
        }

    } catch {
        # Rollback: remove CAS artifact parcial se existir
        if (Test-Path -LiteralPath $casPath) { Remove-Item -LiteralPath $casPath -Force -ErrorAction SilentlyContinue }
        Write-Host ("        FALHA: $_") -ForegroundColor Red
        return [ordered]@{ name=$File.Name; original_bytes=$File.Length; strategy=$strat; rule=$dec.Rule; status='FAILED'; error="$_" }
    }
}

# ── Main ──────────────────────────────────────────────────────────────────────

$runStart = Get-Date

Write-Host ''
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host '  TEIA-Ingestor-Active v0.30.0 — Gestor de Armazenamento Ativo P6.0' -ForegroundColor Cyan
Write-Host ("  TargetDir : $TargetDir")
Write-Host ("  CAS       : $CasRoot")
Write-Host ("  Modo      : $(if ($DryRun) { 'DRY-RUN — zero modificacoes' } else { 'ATIVO — arquivos serao substituidos por stubs' })")
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host ''

New-Item -ItemType Directory -Path $CasRoot -Force | Out-Null

[object[]]$files = @(Get-ChildItem -LiteralPath $TargetDir -File |
    Where-Object { $_.Extension -ne '.teia_stub' })

Write-Host "  Arquivos a ingerir: $($files.Count)"
Write-Host ''

# Contadores acumulados durante o loop (evita pipeline em collections heterogêneas)
$nIngested   = 0; $nSkipped = 0; $nFailed = 0; $nDryRun = 0
$origTotal   = [long]0; $casTotal = [long]0
$ingestedRows = [System.Collections.Generic.List[pscustomobject]]::new()

foreach ($f in $files) {
    $r = Ingest-File -File $f
    switch ([string]$r['status']) {
        'INGESTED' {
            $nIngested++
            $origTotal += [long]$r['original_bytes']
            $casTotal  += [long]$r['cas_bytes']
            $ingestedRows.Add([pscustomobject]@{
                name        = [string]$r['name']
                orig_bytes  = [long]$r['original_bytes']
                cas_bytes   = [long]$r['cas_bytes']
                savings_pct = [double]$r['savings_pct']
                strategy    = [string]$r['strategy']
                rule        = [string]$r['rule']
            })
        }
        { $_ -like 'SKIP*' } { $nSkipped++ }
        'FAILED'             { $nFailed++  }
        'DRY-RUN'            { $nDryRun++  }
    }
}

# ── Sumário ───────────────────────────────────────────────────────────────────

$elapsed = [int]((Get-Date) - $runStart).TotalSeconds

Write-Host ''
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host '  SUMARIO DE INGESTAO' -ForegroundColor Cyan
Write-Host ('─' * 78)
Write-Host ("  Total arquivos   : $($files.Count)")
Write-Host ("  Ingeridos        : $nIngested") -ForegroundColor Green
Write-Host ("  Skip             : $nSkipped") -ForegroundColor DarkGray
if ($nFailed  -gt 0) { Write-Host ("  Falhas           : $nFailed")  -ForegroundColor Red }
if ($nDryRun  -gt 0) { Write-Host ("  Dry-run          : $nDryRun")  -ForegroundColor DarkYellow }
Write-Host ("  Tempo            : ${elapsed}s")
Write-Host ''

if ($nIngested -gt 0) {
    $origMB   = [math]::Round($origTotal / 1MB, 3)
    $casMB    = [math]::Round($casTotal  / 1MB, 3)
    $savedPct = if ($origTotal -gt 0) { [math]::Round((1.0 - ($casTotal / [double]$origTotal)) * 100, 1) } else { 0.0 }

    Write-Host ("  Volume original  : {0,8} MB  (em arquivos no ActiveDrive antes)" -f $origMB)
    Write-Host ("  Volume CAS       : {0,8} MB  (artefatos comprimidos no objects/)" -f $casMB)
    Write-Host ("  Stubs gerados    : $nIngested × ~600B  <- o que ficou no ActiveDrive")
    Write-Host ("  Economia CAS     : $savedPct%  (original vs artefato comprimido)") -ForegroundColor Green
    Write-Host ''

    Write-Host ("  {0,-24} {1,-38} {2,8} {3,8} {4,6}" -f `
        'Estrategia','Arquivo','Orig KB','CAS KB','-%') -ForegroundColor White
    Write-Host ("  {0,-24} {1,-38} {2,8} {3,8} {4,6}" -f `
        ('-'*24),('-'*38),('-'*8),('-'*8),('-'*6))
    foreach ($row in ($ingestedRows | Sort-Object strategy)) {
        $oKB = [math]::Round($row.orig_bytes / 1KB, 1)
        $cKB = [math]::Round($row.cas_bytes  / 1KB, 1)
        Write-Host ("  {0,-24} {1,-38} {2,8} {3,8} {4,6}" -f `
            $row.strategy, $row.name, $oKB, $cKB, "-$($row.savings_pct)%") -ForegroundColor Cyan
    }
}

Write-Host ''
Write-Host ("  CAS Delta esta sessao: +$([math]::Round($casTotal / 1024, 1)) KB em $CasRoot") -ForegroundColor Magenta
Write-Host ('=' * 78)
