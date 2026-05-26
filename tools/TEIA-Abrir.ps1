<#
.SYNOPSIS
    TEIA-Abrir.ps1 — Abre um arquivo de D:\TEIA_USER, restaurando do CAS se necessário.

.DESCRIPTION
    1. Se o arquivo existir em D:\TEIA_USER — abre diretamente.
    2. Se não existir — busca no .teia_map.json por caminho ou nome.
    3. Se encontrado no mapa e CAS tem o objeto — restaura para D:\TEIA_USER e abre.
    Nenhum arquivo é apagado em nenhum dos casos.

.PARAMETER Arquivo
    Nome (ex: relatorio.pdf) ou caminho completo em D:\TEIA_USER.

.PARAMETER Pasta
    Subpasta de D:\TEIA_USER para resolver nome relativo (Documents, Videos, Images, Inbox).

.EXAMPLE
    .\TEIA-Abrir.ps1 -Arquivo "relatorio.pdf"
    .\TEIA-Abrir.ps1 -Arquivo "D:\TEIA_USER\Documents\relatorio.pdf"
    .\TEIA-Abrir.ps1 -Arquivo "relatorio.pdf" -Pasta Documents
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Arquivo,

    [string]$Pasta = ''
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'

$UserRoot    = 'D:\TEIA_USER'
$CASRoot     = 'D:\TEIA_CORE\objects'
$TeiaMapPath = 'D:\TEIA_CORE\manifests\.teia_map.json'
$EventLog    = 'D:\TEIA_CORE\dna_events.jsonl'

function Write-ABEvent {
    param([string]$Act, [hashtable]$Data)
    $line = ([ordered]@{
        ts   = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
        src  = 'TEIA-Abrir'
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

# Restaura de CAS para destino, verificando integridade
function Invoke-TEIARestoreBin {
    param([string]$Hash, [string]$DestPath)
    $casFile = Join-Path $CASRoot "$($Hash.ToLower()).bin"
    if (-not (Test-Path $casFile)) { throw "Objeto CAS ausente: $casFile" }

    $destDir = Split-Path $DestPath
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

    Copy-Item -LiteralPath $casFile -Destination $DestPath -Force -ErrorAction Stop
    $verifHash = (Get-FileHash $DestPath -Algorithm SHA256 -ErrorAction Stop).Hash
    if ($verifHash -ine $Hash) {
        Remove-Item $DestPath -Force -ErrorAction SilentlyContinue
        throw "Hash pós-restauro diverge: esperado $Hash, obtido $verifHash"
    }
}

# ── Resolver caminho alvo ─────────────────────────────────────────────────────
$targetPath = $Arquivo
if (-not [System.IO.Path]::IsPathRooted($Arquivo)) {
    $base       = if ($Pasta) { Join-Path $UserRoot $Pasta } else { $UserRoot }
    $targetPath = Join-Path $base $Arquivo
}

# ── Caso 1: arquivo presente ─────────────────────────────────────────────────
if (Test-Path $targetPath) {
    Write-Host "[AB] Presente — abrindo: $targetPath"
    Write-ABEvent 'AB_OPEN_DIRECT' @{ arquivo = $targetPath }
    Invoke-Item -LiteralPath $targetPath
    exit 0
}

# ── Caso 2: buscar no .teia_map.json ─────────────────────────────────────────
$map   = Read-TeiaMap
$entry = $map | Where-Object { $_.path_user -ieq $targetPath } | Select-Object -First 1

if (-not $entry) {
    $nome  = Split-Path $targetPath -Leaf
    $entry = $map | Where-Object { $_.nome -ieq $nome } | Select-Object -First 1
}

if (-not $entry) {
    Write-Host "[AB] ERRO: '$Arquivo' não encontrado em TEIA_USER nem no .teia_map.json"
    Write-ABEvent 'AB_NOT_FOUND' @{ arquivo = $Arquivo; alvo = $targetPath }
    exit 1
}

Write-Host "[AB] Original ausente — encontrado no mapa (status: $($entry.status))"
Write-Host "[AB] Hash: $($entry.hash.Substring(0,16))...  CAS: $($entry.path_cas)"

# Verificar CAS
$casFile = Join-Path $CASRoot "$($entry.hash.ToLower()).bin"
if (-not (Test-Path $casFile)) {
    Write-Host "[AB] ERRO: objeto CAS ausente — arquivo irrecuperável."
    Write-ABEvent 'AB_CAS_MISSING' @{ hash = $entry.hash; arquivo = $Arquivo }
    exit 1
}

# Restaurar
$restoreDest = if ([System.IO.Path]::IsPathRooted($entry.path_user)) { $entry.path_user } else { $targetPath }
Write-Host "[AB] Restaurando para: $restoreDest"

try {
    Invoke-TEIARestoreBin -Hash $entry.hash -DestPath $restoreDest
    Write-Host "[AB] Restaurado. Abrindo..."
    Write-ABEvent 'AB_RESTORED_AND_OPEN' @{ hash = $entry.hash; destino = $restoreDest }

    # Atualizar status no mapa
    $entry.status   = 'INGESTED'
    $entry.path_user = $restoreDest
    Set-MapAtomic -Map $map

    Invoke-Item -LiteralPath $restoreDest
} catch {
    Write-Host "[AB] FALHA na restauração: $_"
    Write-ABEvent 'AB_RESTORE_FAIL' @{ hash = $entry.hash; erro = $_.ToString() }
    exit 1
}
