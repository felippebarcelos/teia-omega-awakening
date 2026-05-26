<#
.SYNOPSIS
    TEIA-Fractal-Gen-v2.ps1 — Motor Ontoprocedural v2.0

.DESCRIPTION
    Ingere um arquivo no CAS (idempotente) e gera uma Semente Ontoprocedural
    ({hash}.seed.json) com metadados de identidade e contexto de regeneração.
    Atualiza o .teia_map.json para status SAFE_TO_ARCHIVE.
    Nunca apaga o arquivo original.

.PARAMETER Arquivo
    Caminho completo do arquivo. Aceita pipeline de Get-ChildItem.

.PARAMETER Fn
    Função de semente a aplicar. Padrão: gen_dummy_seed.

.EXAMPLE
    .\TEIA-Fractal-Gen-v2.ps1 -Arquivo "D:\TEIA_USER\Inbox\relatorio.pdf"
    Get-ChildItem D:\TEIA_USER\Inbox -File | .\TEIA-Fractal-Gen-v2.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string]$Arquivo,

    [ValidateSet('gen_dummy_seed')]
    [string]$Fn = 'gen_dummy_seed'
)

begin {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    $ErrorActionPreference = 'Continue'

    $CASRoot     = 'D:\TEIA_CORE\objects'
    $SeedRoot    = 'D:\TEIA_CORE\seeds'
    $TeiaMapPath = 'D:\TEIA_CORE\manifests\.teia_map.json'
    $EventLog    = 'D:\TEIA_CORE\dna_events.jsonl'

    foreach ($d in @($CASRoot, $SeedRoot, (Split-Path $TeiaMapPath))) {
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }

    function Write-FGEvent {
        param([string]$Act, [hashtable]$Data)
        $line = ([ordered]@{
            ts   = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
            src  = 'TEIA-Fractal-Gen-v2'
            act  = $Act
            data = $Data
        } | ConvertTo-Json -Compress -Depth 4)
        Add-Content -LiteralPath $EventLog -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
    }

    function Read-TeiaMap {
        if (-not (Test-Path $TeiaMapPath)) { return @() }
        $raw = Get-Content $TeiaMapPath -Raw -ErrorAction SilentlyContinue
        if (-not $raw -or $raw.Trim().Length -le 2) { return @() }
        $parsed = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($parsed) { return @($parsed) }
        return @()
    }

    function Set-MapAtomic {
        param([object[]]$Map)
        $tmp = "$TeiaMapPath.tmp"
        $bak = "$TeiaMapPath.bak"
        $json = ConvertTo-Json -InputObject ([array]$Map) -Depth 5
        Set-Content -LiteralPath $tmp -Value $json -Encoding UTF8 -ErrorAction Stop
        $verify = Get-Content $tmp -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $verify) { throw "Verificação JSON do .tmp falhou — original preservado" }
        if (Test-Path $TeiaMapPath) {
            Copy-Item -LiteralPath $TeiaMapPath -Destination $bak -Force -ErrorAction SilentlyContinue
        }
        Move-Item -LiteralPath $tmp -Destination $TeiaMapPath -Force -ErrorAction Stop
    }

    # Copia arquivo para CAS como {hash}.bin — idempotente por guarda Test-Path.
    function Invoke-IngestToCAS {
        param([System.IO.FileInfo]$File, [string]$Hash)
        $dest = Join-Path $CASRoot "$($Hash.ToLower()).bin"
        if (Test-Path $dest) { return 'EXISTED' }
        Copy-Item -LiteralPath $File.FullName -Destination $dest -Force -ErrorAction Stop
        $verifHash = (Get-FileHash $dest -Algorithm SHA256 -ErrorAction Stop).Hash
        if ($verifHash -ine $Hash) {
            Remove-Item $dest -Force -ErrorAction SilentlyContinue
            throw "Hash pós-cópia diverge: esperado $Hash, obtido $verifHash"
        }
        return 'NEW'
    }

    # Grava semente em {hash}.seed.json com escrita atômica (.tmp → rename).
    function Write-SeedAtomic {
        param([string]$SeedPath, [object]$SeedData)
        $tmp = "$SeedPath.tmp"
        $json = ConvertTo-Json -InputObject $SeedData -Depth 6
        Set-Content -LiteralPath $tmp -Value $json -Encoding UTF8 -ErrorAction Stop
        $verify = Get-Content $tmp -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $verify) { throw "Verificação JSON da seed falhou" }
        Move-Item -LiteralPath $tmp -Destination $SeedPath -Force -ErrorAction Stop
    }

    # gen_dummy_seed: semente ontoprocedural mínima para prova de circuito.
    # Captura entropia superficial (head/tail 32 bytes) + metadados de identidade.
    # O conteúdo completo é preservado integralmente no CAS — a semente não
    # substitui o original, apenas registra o contexto de regeneração futura.
    function gen_dummy_seed {
        param([System.IO.FileInfo]$File, [string]$Hash)
        $bytes   = [System.IO.File]::ReadAllBytes($File.FullName)
        $headLen = [math]::Min(32, $bytes.Length)
        $tailLen = [math]::Min(32, $bytes.Length)
        $headHex = -join ($bytes[0..($headLen - 1)] | ForEach-Object { $_.ToString('x2') })
        $tailIdx = [math]::Max(0, $bytes.Length - $tailLen)
        $tailHex = -join ($bytes[$tailIdx..($bytes.Length - 1)] | ForEach-Object { $_.ToString('x2') })
        $ext     = $File.Extension.ToLower()
        $mimeHint = switch ($ext) {
            '.txt'  { 'text/plain' }
            '.md'   { 'text/markdown' }
            '.json' { 'application/json' }
            '.png'  { 'image/png' }
            '.pdf'  { 'application/pdf' }
            default { 'application/octet-stream' }
        }
        return [ordered]@{
            teia_version = '2.0'
            fn           = 'gen_dummy_seed'
            hash_sha256  = $Hash.ToLower()
            nome         = $File.Name
            ext          = $ext
            mime_hint    = $mimeHint
            size         = $File.Length
            generated_at = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
            cas_path     = (Join-Path $CASRoot "$($Hash.ToLower()).bin")
            entropy      = [ordered]@{
                head_hex   = $headHex
                tail_hex   = $tailHex
                size_bytes = $File.Length
            }
            note = 'Prova de circuito — conteudo preservado integralmente no CAS. Semente nao substitui o original.'
        }
    }

    $totalOk   = 0
    $totalFail = 0
}

process {
    $file = Get-Item -LiteralPath $Arquivo -Force -ErrorAction SilentlyContinue
    if (-not $file -or $file.PSIsContainer) {
        Write-Host "[FG] Ignorado (inexistente ou pasta): $Arquivo"
        return
    }

    # 1 — Calcular SHA-256
    $hash = (Get-FileHash $file.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
    if (-not $hash) {
        Write-Host "[FG] FALHA hash: $($file.Name)"
        Write-FGEvent 'FG_HASH_FAIL' @{ arquivo = $file.FullName }
        $totalFail++
        return
    }
    $hashLow = $hash.ToLower()

    # 2 — Ingerir no CAS (idempotente)
    $casStatus = $null
    try {
        $casStatus = Invoke-IngestToCAS -File $file -Hash $hash
    } catch {
        Write-Host "[FG] FALHA CAS: $($file.Name) — $_"
        Write-FGEvent 'FG_CAS_FAIL' @{ arquivo = $file.FullName; erro = $_.ToString() }
        $totalFail++
        return
    }

    # 3 — Gerar semente ontoprocedural (idempotente por hash)
    $seedPath   = Join-Path $SeedRoot "$hashLow.seed.json"
    $seedStatus = 'EXISTED'
    if (-not (Test-Path $seedPath)) {
        try {
            $seedData = switch ($Fn) {
                'gen_dummy_seed' { gen_dummy_seed -File $file -Hash $hash }
                default          { throw "Função desconhecida: $Fn" }
            }
            Write-SeedAtomic -SeedPath $seedPath -SeedData $seedData
            $seedStatus = 'NEW'
        } catch {
            Write-Host "[FG] FALHA seed: $($file.Name) — $_"
            Write-FGEvent 'FG_SEED_FAIL' @{ arquivo = $file.FullName; erro = $_.ToString() }
            $totalFail++
            return
        }
    }

    # 4 — Atualizar .teia_map.json: status SAFE_TO_ARCHIVE + seed_path
    try {
        [array]$map = Read-TeiaMap
        $now     = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
        $existing = $map | Where-Object { $_.path_user -ieq $file.FullName } | Select-Object -First 1

        if ($existing) {
            $existing.status    = 'SAFE_TO_ARCHIVE'
            $existing.hash      = $hashLow
            $existing.path_cas  = (Join-Path $CASRoot "$hashLow.bin")
            # Adiciona campos de semente ao objeto existente
            $existing | Add-Member -NotePropertyName 'seed_path' -NotePropertyValue $seedPath -Force
            $existing | Add-Member -NotePropertyName 'seed_at'   -NotePropertyValue $now       -Force
        } else {
            $map += [PSCustomObject]@{
                path_user   = $file.FullName
                nome        = $file.Name
                hash        = $hashLow
                size        = $file.Length
                status      = 'SAFE_TO_ARCHIVE'
                ingested_at = $now
                verified_at = $null
                path_cas    = (Join-Path $CASRoot "$hashLow.bin")
                seed_path   = $seedPath
                seed_at     = $now
            }
        }
        Set-MapAtomic -Map $map
    } catch {
        Write-Host "[FG] FALHA mapa: $($file.Name) — $_"
        Write-FGEvent 'FG_MAP_FAIL' @{ arquivo = $file.FullName; erro = $_.ToString() }
        $totalFail++
        return
    }

    # 5 — Registrar evento
    Write-FGEvent 'FRACTAL_GENERATED' @{
        arquivo    = $file.FullName
        hash       = $hashLow
        cas_status = $casStatus
        seed_path  = $seedPath
        seed_status = $seedStatus
        fn         = $Fn
    }

    $casLabel  = if ($casStatus  -eq 'NEW') { 'CAS:NOVO' } else { 'CAS:JÁ EXISTIA' }
    $seedLabel = if ($seedStatus -eq 'NEW') { 'SEED:NOVA' } else { 'SEED:JÁ EXISTIA' }
    Write-Host "[FG] SAFE_TO_ARCHIVE ($casLabel | $seedLabel): $($file.Name)  [$($hashLow.Substring(0,16))...]"
    $totalOk++
}

end {
    Write-Host "[FG] Concluído — OK: $totalOk | Falhas: $totalFail"
}
