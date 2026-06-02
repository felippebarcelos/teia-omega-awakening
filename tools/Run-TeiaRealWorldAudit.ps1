#Requires -Version 7
# Run-TeiaRealWorldAudit.ps1 — TEIA P38.1 Real-World Audit (Dry-Run)
# Escaneia um diretório real, classifica cada arquivo em Zona A/B/C,
# agrupa CSVs de schema uniforme, invoca o Roteador nos grupos validos e
# projeta o roteamento (TEIA / Brotli / PassThrough) sem modificar nenhum arquivo.
#
# Manifesto: teia_realworld_audit_state.json — JSON canonico, deterministico.
# Idempotencia: mesmo diretorio inalterado → mesmo SHA-256 do manifesto.
# Delta sempre por extenso (nunca simbolo matematico).

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$TargetDirectory,
    [string]$OutputManifest   = '',
    [string]$RouterPath       = (Join-Path $PSScriptRoot 'TEIA-Archive-Router.ps1'),
    [string]$MotorPath        = (Join-Path $PSScriptRoot 'TEIA-AION-Transversal.ps1'),
    [int]$MinGroupSize        = 5,
    [int]$MaxGroupFilesRouter = 30,
    [long]$MaxGroupSizeBytes  = 104857600,
    [switch]$SkipRouterInvocation
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'

# ─── Validar diretório alvo ───────────────────────────────────────────────────
$TargetDirectory = (Resolve-Path $TargetDirectory -ErrorAction Stop).Path
if (!(Test-Path $TargetDirectory -PathType Container)) {
    throw "Diretório alvo não encontrado: $TargetDirectory"
}
if ([string]::IsNullOrEmpty($OutputManifest)) {
    $OutputManifest = Join-Path $TargetDirectory 'teia_realworld_audit_state.json'
}

# ─── Inicializar Router em LibraryMode ───────────────────────────────────────
$routerAvailable = $false
if (!$SkipRouterInvocation -and (Test-Path $RouterPath) -and (Test-Path $MotorPath)) {
    Write-Host 'Inicializando Router + C# JIT...' -ForegroundColor DarkGray
    try {
        . $RouterPath -MotorPath $MotorPath -LibraryMode
        $routerAvailable = $true
        Write-Host '  Pronto.' -ForegroundColor DarkGray
    } catch {
        Write-Host "  Aviso: Router nao carregado ($($_.Exception.Message)). Usando heurísticas." -ForegroundColor Yellow
    }
}

# ─── Extensoes por zona ───────────────────────────────────────────────────────
$extZoneC = [System.Collections.Generic.HashSet[string]]@(
    '.exe','.dll','.so','.dylib','.sys','.bin','.dat','.iso','.img',
    '.zip','.gz','.br','.7z','.rar','.tar','.lz4','.zst','.xz','.bz2',
    '.jpg','.jpeg','.png','.gif','.bmp','.webp','.ico','.tiff','.heic',
    '.mp4','.avi','.mov','.mkv','.wmv','.flv','.webm','.m4v',
    '.mp3','.wav','.flac','.ogg','.aac','.m4a','.wma',
    '.psd','.ai','.psb','.xcf','.fig','.sketch',
    '.db','.sqlite','.sqlite3','.mdb','.accdb',
    '.class','.pyc','.pyd','.pyo','.wasm','.pak','.cache','.nupkg'
)
$extZoneA = [System.Collections.Generic.HashSet[string]]@(
    '.log','.json','.yaml','.yml','.toml','.ini','.conf','.cfg','.xml',
    '.csv','.tsv','.ps1','.psm1','.psd1','.ps1xml',
    '.py','.js','.ts','.jsx','.tsx','.mjs','.cjs',
    '.cs','.go','.rs','.java','.kt','.rb','.php','.swift','.vb',
    '.c','.cpp','.h','.hpp','.cc','.cxx',
    '.sh','.bash','.zsh','.bat','.cmd',
    '.txt','.md','.rst','.html','.htm','.css','.scss','.less',
    '.sql','.r','.m','.jl','.lua','.pl','.tcl','.awk',
    '.tf','.hcl','.env','.properties','.nfo','.lock'
)

# ─── Funcoes auxiliares ───────────────────────────────────────────────────────

function Get-FileFingerprint {
    param([System.IO.FileInfo]$File)
    try {
        $chunkLen = [math]::Min(65536, [long]$File.Length)
        $buf = [byte[]]::new($chunkLen)
        $fs  = [System.IO.File]::OpenRead($File.FullName)
        $n   = $fs.Read($buf, 0, $chunkLen)
        $fs.Dispose()
        $sizeTag = [System.Text.Encoding]::UTF8.GetBytes($File.Length.ToString())
        $ms = [System.IO.MemoryStream]::new()
        $ms.Write($sizeTag, 0, $sizeTag.Length)
        $ms.Write($buf, 0, $n)
        $ms.Position = 0
        $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($ms)
        $ms.Dispose()
        return [System.BitConverter]::ToString($hashBytes).Replace('-','').ToLower()
    } catch {
        return ('err_' + $File.Length)
    }
}

function Get-FileZone {
    param([System.IO.FileInfo]$File)
    $ext = $File.Extension.ToLower()
    if ($extZoneC.Contains($ext)) { return 'C' }
    if ($extZoneA.Contains($ext)) { return 'A' }
    # Amostragem de bytes para detectar binario
    if ($File.Length -gt 0) {
        try {
            $sampleLen = [math]::Min(512, [long]$File.Length)
            $buf = [byte[]]::new($sampleLen)
            $fs  = [System.IO.File]::OpenRead($File.FullName)
            $n   = $fs.Read($buf, 0, $sampleLen)
            $fs.Dispose()
            $nullCount = 0
            for ($i = 0; $i -lt $n; $i++) { if ($buf[$i] -eq 0) { $nullCount++ } }
            if ($nullCount -gt ($n * 0.08)) { return 'C' }
        } catch {}
    }
    return 'B'
}

function Get-CsvSchemaInfo {
    param([System.IO.FileInfo]$File)
    try {
        $header = (Get-Content $File.FullName -TotalCount 1 -Encoding UTF8 -ErrorAction Stop).Trim()
        if ([string]::IsNullOrEmpty($header) -or !$header.Contains(',')) { return $null }
        $bytes   = [System.Text.Encoding]::UTF8.GetBytes($header)
        $hash    = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
        $groupId = [System.BitConverter]::ToString($hash).Replace('-','').ToLower().Substring(0, 16)
        return [pscustomobject]@{ GroupId=$groupId; Header=$header; ColCount=$header.Split(',').Count }
    } catch { return $null }
}

function Get-HeuristicSavingsBytes {
    param([long]$FileSizeBytes, [string]$Zone, [string]$Ext)
    if ($Zone -eq 'C') { return [long]0 }
    $ratio = switch ($Zone) {
        'A' { 0.72 }
        'B' { 0.52 }
        default { 0.0 }
    }
    return [long]([double]$FileSizeBytes * $ratio)
}

function Get-RelativePath {
    param([string]$Base, [string]$Full)
    $rel = $Full.Substring($Base.Length).TrimStart('\','/').Replace('\','/')
    return $rel
}

# ─── Escanear diretorio ───────────────────────────────────────────────────────
Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  TEIA Real-World Audit — P38.1 Dry-Run'                      -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host "Alvo: $TargetDirectory" -ForegroundColor White

$manifestName = [System.IO.Path]::GetFileName($OutputManifest).ToLower()

Write-Host 'Escaneando arquivos...' -ForegroundColor DarkGray
$allFiles = @(Get-ChildItem $TargetDirectory -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name.ToLower() -ne $manifestName } |
    Sort-Object FullName)

Write-Host "  $($allFiles.Count) arquivo(s) encontrado(s)." -ForegroundColor DarkGray

# ─── Classificar e fazer fingerprint de cada arquivo ─────────────────────────
Write-Host 'Classificando zones e gerando fingerprints...' -ForegroundColor DarkGray

$fileRecords  = [System.Collections.Generic.List[pscustomobject]]::new()
$schemaMap    = [ordered]@{}  # groupId → list of files

foreach ($f in $allFiles) {
    $zone     = Get-FileZone -File $f
    $fp       = Get-FileFingerprint -File $f
    $relPath  = Get-RelativePath -Base $TargetDirectory -Full $f.FullName
    $schemaId = $null

    if ($zone -ne 'C' -and $f.Extension.ToLower() -eq '.csv') {
        $schemaInfo = Get-CsvSchemaInfo -File $f
        if ($schemaInfo) {
            $schemaId = $schemaInfo.GroupId
            if (!$schemaMap.Contains($schemaId)) {
                $schemaMap[$schemaId] = [pscustomobject]@{
                    GroupId   = $schemaInfo.GroupId
                    Header    = $schemaInfo.Header
                    ColCount  = $schemaInfo.ColCount
                    Files     = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
                    TotalBytes = [long]0
                }
            }
            $schemaMap[$schemaId].Files.Add($f)
            $schemaMap[$schemaId].TotalBytes += $f.Length
        }
    }

    $fileRecords.Add([pscustomobject]@{
        relative_path    = $relPath
        size_bytes       = $f.Length
        zone             = $zone
        extension        = $f.Extension.ToLower()
        file_fingerprint = $fp
        schema_group_id  = $schemaId
        routing_decision = $null
        routing_rationale = $null
        dict_cols_estimated = 0
        dict_density_pct    = 0
        projected_original_size_bytes = $f.Length
        projected_archive_size_bytes  = $f.Length
        projected_savings_bytes       = [long]0
        n_star                        = $null
    })
}

# ─── Processar grupos CSV: Router ou heuristica ───────────────────────────────
Write-Host "Processando $($schemaMap.Count) grupo(s) de schema CSV..." -ForegroundColor DarkGray

$groupResults = [ordered]@{}  # groupId → router result or heuristic

foreach ($gid in $schemaMap.Keys) {
    $grp = $schemaMap[$gid]
    $n   = $grp.Files.Count
    $useRouter = $routerAvailable -and !$SkipRouterInvocation `
                 -and $n -ge $MinGroupSize `
                 -and $grp.TotalBytes -le $MaxGroupSizeBytes

    if ($useRouter) {
        Write-Host ("  [Router] grupo {0} — N={1} arquivos..." -f $gid, $n) -ForegroundColor DarkGray -NoNewline
        try {
            $tmpDir = Join-Path $env:TEMP ('teia_audit_' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
            $sample = $grp.Files | Select-Object -First $MaxGroupFilesRouter
            foreach ($sf in $sample) {
                Copy-Item $sf.FullName (Join-Path $tmpDir $sf.Name) -Force
            }
            $r = Invoke-TeiaArchiveRouter -InputDir $tmpDir -Objective 'Balanced'
            Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

            $groupResults[$gid] = [pscustomobject]@{
                Method         = 'router_actual'
                Winner         = $r.Winner
                NStar          = $r.NCritSizeVsBrotli
                DictCols       = if ($r.TeiaDictCols) { $r.TeiaDictCols -join ',' } else { '' }
                DictColsCount  = if ($r.TeiaDictCols) { $r.TeiaDictCols.Count } else { 0 }
                DictDensityPct = if ($r.Schema) { [int][math]::Round(100.0 * (if ($r.TeiaDictCols) { $r.TeiaDictCols.Count } else { 0 }) / [math]::Max(1, $r.Schema.Split(',').Count)) } else { 0 }
                TeiaSizeBytes  = $r.SizeBytes['TEIA']
                BrotliSizeBytes = $r.SizeBytes['Brotli']
                ConcatSizeBytes = $r.SizeBytes['Concat']
                SampledN       = $sample.Count
            }
            Write-Host (" WINNER: $($r.Winner) N*=$($r.NCritSizeVsBrotli)") -ForegroundColor Cyan
        } catch {
            Write-Host (" ERRO: $($_.Exception.Message)") -ForegroundColor Red
            $groupResults[$gid] = [pscustomobject]@{ Method='error'; Winner='Brotli'; NStar='N/A'; DictCols=''; DictColsCount=0; DictDensityPct=0; TeiaSizeBytes=0; BrotliSizeBytes=0; ConcatSizeBytes=0; SampledN=0 }
        }
    } else {
        $reason = if (!$routerAvailable)             { 'router_indisponivel' }
                  elseif ($n -lt $MinGroupSize)       { "N=$n < min=$MinGroupSize" }
                  elseif ($grp.TotalBytes -gt $MaxGroupSizeBytes) { 'grupo_muito_grande' }
                  else                                { 'skip_solicitado' }

        $hDensity = if ($n -ge 2) {
            # Estimar densidade dict: ler amostra de 200 linhas do primeiro arquivo
            try {
                $sampleLines = Get-Content $grp.Files[0].FullName -TotalCount 201 -Encoding UTF8
                $hdr = $sampleLines[0].Split(',')
                $dataLines = $sampleLines[1..[math]::Min(200, $sampleLines.Count-1)]
                $dictCount = 0
                for ($ci = 0; $ci -lt $hdr.Count; $ci++) {
                    $vals = $dataLines | ForEach-Object { ($_ -split ',')[$ci] } | Sort-Object -Unique
                    if ($vals.Count -le 50) { $dictCount++ }
                }
                [int][math]::Round(100.0 * $dictCount / [math]::Max(1, $hdr.Count))
            } catch { 0 }
        } else { 0 }

        $hWinner = if ($n -ge $MinGroupSize -and $hDensity -ge 40) { 'TEIA' }
                   elseif ($hDensity -gt 0) { 'Brotli' }
                   else { 'Brotli' }

        $groupResults[$gid] = [pscustomobject]@{
            Method         = 'heuristica'
            Winner         = $hWinner
            NStar          = 'estimado'
            DictCols       = ''
            DictColsCount  = 0
            DictDensityPct = $hDensity
            TeiaSizeBytes  = 0
            BrotliSizeBytes = 0
            ConcatSizeBytes = 0
            SampledN       = 0
            HeuristicReason = $reason
        }
    }
}

# ─── Aplicar decisoes de roteamento a cada fileRecord ────────────────────────
foreach ($rec in $fileRecords) {
    $zone = $rec.zone
    $ext  = $rec.extension
    $sid  = $rec.schema_group_id

    if ($zone -eq 'C') {
        $rec.routing_decision  = 'PassThrough'
        $rec.routing_rationale = "Zona C: binario/comprimido/midia — pass-through obrigatorio"
        $rec.projected_savings_bytes = [long]0
        $rec.projected_archive_size_bytes = $rec.size_bytes
    } elseif ($sid -and $groupResults.Contains($sid)) {
        $gr  = $groupResults[$sid]
        $grp = $schemaMap[$sid]
        $n   = $grp.Files.Count
        $rec.routing_decision    = $gr.Winner
        $rec.dict_density_pct    = $gr.DictDensityPct
        $rec.dict_cols_estimated = $gr.DictColsCount
        $rec.n_star              = if ($gr.NStar -match '^\d+$') { [int]$gr.NStar } else { $null }

        if ($gr.Method -eq 'router_actual' -and $gr.SampledN -gt 0) {
            # Projetar tamanho individual proporcionalmente ao resultado do router
            $perFileTeia   = if ($gr.SampledN -gt 0) { $gr.TeiaSizeBytes   / $gr.SampledN } else { $rec.size_bytes }
            $perFileBrotli = if ($gr.SampledN -gt 0) { $gr.BrotliSizeBytes / $gr.SampledN } else { $rec.size_bytes }
            $archSize = switch ($gr.Winner) {
                'TEIA'   { [long]$perFileTeia   }
                'Brotli' { [long]$perFileBrotli }
                default  { $rec.size_bytes }
            }
            $rec.projected_archive_size_bytes = $archSize
            $rec.projected_savings_bytes = [long]($rec.size_bytes - $archSize)
            $rec.routing_rationale = "grupo_schema N=$n winner=$($gr.Winner) metodo=router_real"
        } else {
            $savings = Get-HeuristicSavingsBytes -FileSizeBytes $rec.size_bytes -Zone $zone -Ext $ext
            $rec.projected_savings_bytes = $savings
            $rec.projected_archive_size_bytes = $rec.size_bytes - $savings
            $rec.routing_rationale = "grupo_schema N=$n heuristica: $($gr.PSObject.Properties['HeuristicReason']?.Value)"
        }
    } else {
        # Arquivo nao-CSV ou CSV sem grupo
        $rec.routing_decision = if ($zone -eq 'A' -or $zone -eq 'B') { 'Brotli' } else { 'PassThrough' }
        $savings = Get-HeuristicSavingsBytes -FileSizeBytes $rec.size_bytes -Zone $zone -Ext $ext
        $rec.projected_savings_bytes = $savings
        $rec.projected_archive_size_bytes = $rec.size_bytes - $savings
        $rec.routing_rationale = "sem_grupo_csv zona=$zone heuristica"
    }
}

# ─── Construir manifesto canonico ─────────────────────────────────────────────
Write-Host 'Construindo manifesto canonico...' -ForegroundColor DarkGray

# Agregar por zona
$zoneStats = [ordered]@{}
foreach ($z in @('A','B','C')) {
    $zFiles = $fileRecords | Where-Object { $_.zone -eq $z }
    $zoneStats[$z] = [ordered]@{
        file_count  = ($zFiles | Measure-Object).Count
        total_bytes = ($zFiles | Measure-Object size_bytes -Sum).Sum
        description = switch ($z) {
            'A' { 'Baixa Entropia / Alta Estrutura' }
            'B' { 'Entropia Media' }
            'C' { 'Alta Entropia / Pass-through' }
        }
    }
}

# Agregar por routing decision
$routeStats = [ordered]@{}
foreach ($dec in @('Brotli','PassThrough','TEIA')) {
    $rFiles = $fileRecords | Where-Object { $_.routing_decision -eq $dec }
    $totBytes = ($rFiles | Measure-Object size_bytes -Sum).Sum
    $savBytes = ($rFiles | Measure-Object projected_savings_bytes -Sum).Sum
    $routeStats[$dec] = [ordered]@{
        file_count              = ($rFiles | Measure-Object).Count
        total_original_bytes    = if ($totBytes) { [long]$totBytes } else { [long]0 }
        projected_savings_bytes = if ($savBytes) { [long]$savBytes } else { [long]0 }
    }
}

# Schema groups para o manifesto (ordenados por group_id)
$schemaGroupsForManifest = $schemaMap.Keys | Sort-Object | ForEach-Object {
    $gid = $_
    $grp = $schemaMap[$gid]
    $gr  = if ($groupResults.Contains($gid)) { $groupResults[$gid] } else { $null }
    [ordered]@{
        group_id          = $gid
        header            = $grp.Header
        col_count         = $grp.ColCount
        file_count        = $grp.Files.Count
        total_bytes       = $grp.TotalBytes
        routing_method    = if ($gr) { $gr.Method } else { 'nenhum' }
        routing_decision  = if ($gr) { $gr.Winner } else { 'Brotli' }
        dict_density_pct  = if ($gr) { $gr.DictDensityPct } else { 0 }
        dict_cols         = if ($gr) { $gr.DictCols } else { '' }
        n_star            = if ($gr) { $gr.NStar } else { 'N/A' }
        sampled_n         = if ($gr) { $gr.SampledN } else { 0 }
    }
}

# File list — ordenada por relative_path (garantia de idempotencia)
$filesForManifest = $fileRecords | Sort-Object relative_path | ForEach-Object {
    [ordered]@{
        relative_path                 = $_.relative_path
        size_bytes                    = $_.size_bytes
        zone                          = $_.zone
        extension                     = $_.extension
        file_fingerprint              = $_.file_fingerprint
        schema_group_id               = if ($_.schema_group_id) { $_.schema_group_id } else { $null }
        routing_decision              = $_.routing_decision
        routing_rationale             = $_.routing_rationale
        dict_density_pct              = $_.dict_density_pct
        dict_cols_estimated           = $_.dict_cols_estimated
        n_star                        = $_.n_star
        projected_original_size_bytes = $_.projected_original_size_bytes
        projected_archive_size_bytes  = $_.projected_archive_size_bytes
        projected_savings_bytes       = $_.projected_savings_bytes
    }
}

$totalOriginalBytes = ($fileRecords | Measure-Object size_bytes -Sum).Sum
$totalSavingsBytes  = ($fileRecords | Measure-Object projected_savings_bytes -Sum).Sum

$manifest = [ordered]@{
    manifest_version           = '1.0'
    target_directory           = $TargetDirectory.Replace('\','/')
    file_count                 = $fileRecords.Count
    total_original_size_bytes  = if ($totalOriginalBytes) { [long]$totalOriginalBytes } else { [long]0 }
    total_projected_savings_bytes = if ($totalSavingsBytes) { [long]$totalSavingsBytes } else { [long]0 }
    zones                      = $zoneStats
    routing_projection         = $routeStats
    schema_groups              = @($schemaGroupsForManifest)
    files                      = @($filesForManifest)
}

# ─── Serializar e escrever ────────────────────────────────────────────────────
$jsonStr = $manifest | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($OutputManifest, $jsonStr, [System.Text.Encoding]::UTF8)

# SHA-256 do manifesto (prova de idempotencia)
$manifestHash = (Get-FileHash $OutputManifest -Algorithm SHA256).Hash.ToLower()

# ─── Exibir resumo ────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  RESUMO DO AUDIT — Real-World P38.1'                         -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''
Write-Host ('  Arquivos escaneados : {0}' -f $fileRecords.Count)                           -ForegroundColor White
Write-Host ('  Tamanho total       : {0:F1} MB' -f ($totalOriginalBytes / 1MB))             -ForegroundColor White
Write-Host ('  Economia projetada  : {0:F1} MB ({1:P0})' -f ($totalSavingsBytes / 1MB), ($totalSavingsBytes / [math]::Max(1, $totalOriginalBytes))) -ForegroundColor $(if ($totalSavingsBytes -gt 0) { 'Green' } else { 'Yellow' })
Write-Host ''
Write-Host '  Distribuicao por Zona:' -ForegroundColor DarkGray
foreach ($z in @('A','B','C')) {
    $zs = $zoneStats[$z]
    $zColor = switch ($z) { 'A' {'Cyan'} 'B' {'Yellow'} 'C' {'DarkGray'} }
    Write-Host ('    Zona {0}: {1,4} arqs  {2,8:F1} MB  ({3})' -f $z, $zs.file_count, ($zs.total_bytes / 1MB), $zs.description) -ForegroundColor $zColor
}
Write-Host ''
Write-Host '  Roteamento Projetado:' -ForegroundColor DarkGray
foreach ($dec in @('TEIA','Brotli','PassThrough')) {
    $rs     = $routeStats[$dec]
    $rColor = switch ($dec) { 'TEIA' {'Cyan'} 'Brotli' {'Green'} default {'DarkGray'} }
    $savMB  = $rs.projected_savings_bytes / 1MB
    Write-Host ('    {0,-12}: {1,4} arqs  economia={2:F1} MB' -f $dec, $rs.file_count, $savMB) -ForegroundColor $rColor
}
Write-Host ''
Write-Host "  Manifesto : $OutputManifest" -ForegroundColor White
Write-Host "  SHA-256   : $manifestHash"   -ForegroundColor Cyan
Write-Host ''
Write-Host '  Para verificar idempotencia: execute novamente e compare o SHA-256 acima.' -ForegroundColor DarkGray
Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '  Audit concluido — nenhum arquivo foi modificado.'            -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
