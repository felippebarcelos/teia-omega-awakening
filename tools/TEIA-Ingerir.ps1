<#
.SYNOPSIS
    TEIA-Ingerir.ps1 — Ingere um arquivo no CAS e registra no .teia_map.json.

.DESCRIPTION
    Calcula SHA-256, copia para D:\TEIA_CORE\objects\{hash}.bin (idempotente)
    e atualiza o .teia_map.json com escrita atômica.
    NÃO apaga o arquivo original. Aceita pipeline de Get-ChildItem.

.PARAMETER Arquivo
    Caminho completo do arquivo a ingerir.

.EXAMPLE
    .\TEIA-Ingerir.ps1 -Arquivo "D:\TEIA_USER\Documents\relatorio.pdf"
    Get-ChildItem D:\TEIA_USER\Inbox | .\TEIA-Ingerir.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string]$Arquivo
)

begin {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    $ErrorActionPreference = 'Continue'

    $CASRoot       = 'D:\TEIA_CORE\objects'
    $TeiaMapPath   = 'D:\TEIA_CORE\manifests\.teia_map.json'
    $EventLog      = 'D:\TEIA_CORE\dna_events.jsonl'
    $QuarantineDir = 'D:\TEIA_CORE\QUARENTENA_DEBRIS'

    foreach ($d in @($CASRoot, (Split-Path $TeiaMapPath), $QuarantineDir)) {
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }

    function Write-IGEvent {
        param([string]$Act, [hashtable]$Data)
        $line = ([ordered]@{
            ts   = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
            src  = 'TEIA-Ingerir'
            act  = $Act
            data = $Data
        } | ConvertTo-Json -Compress -Depth 4)
        Add-Content -LiteralPath $EventLog -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
    }

    # Quarentena: destino seguro para objetos corrompidos — nunca delete direto
    function Move-ToQuarantine {
        param([string]$Path, [string]$Reason = 'unspecified')
        if (-not (Test-Path $Path)) { return }
        $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $dest  = Join-Path $QuarantineDir "$stamp`_$(Split-Path $Path -Leaf)"
        Move-Item -LiteralPath $Path -Destination $dest -Force -ErrorAction SilentlyContinue
        Write-IGEvent 'IG_QUARANTINE' @{ origem = $Path; destino = $dest; razao = $Reason }
        Write-Host "[IG] Quarentena: $dest (razão: $Reason)"
    }

    # Escrita atômica: .tmp → validar parse → .bak → rename
    function Set-MapAtomic {
        param([object[]]$Map)
        $tmp = "$TeiaMapPath.tmp"
        $bak = "$TeiaMapPath.bak"
        $json = $Map | ConvertTo-Json -Depth 5
        Set-Content -LiteralPath $tmp -Value $json -Encoding UTF8 -ErrorAction Stop
        $verify = Get-Content $tmp -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $verify) { throw "Verificação JSON do .tmp falhou — original preservado" }
        if (Test-Path $TeiaMapPath) {
            Copy-Item -LiteralPath $TeiaMapPath -Destination $bak -Force -ErrorAction SilentlyContinue
        }
        Move-Item -LiteralPath $tmp -Destination $TeiaMapPath -Force -ErrorAction Stop
    }

    function Read-TeiaMap {
        if (-not (Test-Path $TeiaMapPath)) { return @() }
        $raw = Get-Content $TeiaMapPath -Raw -ErrorAction SilentlyContinue
        if (-not $raw -or $raw.Trim().Length -le 2) { return @() }
        $parsed = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($parsed) { return @($parsed) }
        return @()
    }

    $totalOk   = 0
    $totalFail = 0
}

process {
    $file = Get-Item -LiteralPath $Arquivo -Force -ErrorAction SilentlyContinue
    if (-not $file -or $file.PSIsContainer) {
        Write-Host "[IG] Ignorado (inexistente ou pasta): $Arquivo"
        return
    }

    # Calcular SHA-256
    $hash = (Get-FileHash $file.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
    if (-not $hash) {
        Write-Host "[IG] FALHA hash: $($file.Name)"
        Write-IGEvent 'IG_HASH_FAIL' @{ arquivo = $file.FullName }
        $totalFail++
        return
    }

    $dest = Join-Path $CASRoot "$($hash.ToLower()).bin"

    # Copiar para CAS — idempotente
    $casNovo = $false
    if (-not (Test-Path $dest)) {
        try {
            Copy-Item -LiteralPath $file.FullName -Destination $dest -Force -ErrorAction Stop
            $verifHash = (Get-FileHash $dest -Algorithm SHA256 -ErrorAction Stop).Hash
            if ($verifHash -ine $hash) {
                Move-ToQuarantine -Path $dest -Reason 'hash-pos-copia-diverge'
                throw "Hash pós-cópia diverge: esperado $hash, obtido $verifHash"
            }
            $casNovo = $true
        } catch {
            Write-Host "[IG] FALHA CAS: $($file.Name) — $_"
            Write-IGEvent 'IG_COPY_FAIL' @{ arquivo = $file.FullName; erro = $_.ToString() }
            $totalFail++
            return
        }
    }

    # Atualizar .teia_map.json — escrita atômica
    try {
        $map = Read-TeiaMap
        $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'

        # Busca por caminho exato
        $existing = $map | Where-Object { $_.path_user -ieq $file.FullName }
        $status = 'INGESTED'

        if ($existing) {
            $status = if ($existing[0].hash -ieq $hash) { 'VERIFIED' } else { 'INGESTED' }
            $existing[0].hash        = $hash.ToLower()
            $existing[0].size        = $file.Length
            $existing[0].status      = $status
            $existing[0].path_cas    = $dest
            $existing[0].ingested_at = if ($status -eq 'INGESTED') { $now } else { $existing[0].ingested_at }
            $existing[0].verified_at = if ($status -eq 'VERIFIED') { $now } else { $null }
        } else {
            $map += [PSCustomObject]@{
                path_user   = $file.FullName
                nome        = $file.Name
                hash        = $hash.ToLower()
                size        = $file.Length
                status      = $status
                ingested_at = $now
                verified_at = $null
                path_cas    = $dest
            }
        }

        Set-MapAtomic -Map $map

        $label = if ($casNovo) { 'CAS:NOVO' } else { 'CAS:JÁ EXISTIA' }
        Write-Host "[IG] $status ($label): $($file.Name)  [$($hash.Substring(0,16))...]"
        Write-IGEvent 'IG_OK' @{ arquivo = $file.FullName; hash = $hash; status = $status; cas_novo = $casNovo }
        $totalOk++
    } catch {
        Write-Host "[IG] FALHA mapa: $($file.Name) — $_"
        Write-IGEvent 'IG_MAP_FAIL' @{ arquivo = $file.FullName; erro = $_.ToString() }
        $totalFail++
    }
}

end {
    Write-Host "[IG] Concluído — OK: $totalOk | Falhas: $totalFail"
}
