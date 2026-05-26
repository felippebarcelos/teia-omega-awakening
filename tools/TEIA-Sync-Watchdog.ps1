<#
.SYNOPSIS
    TEIA-Sync-Watchdog v0.13.0 — Monitoramento de drift e ingestão automática.
    Detecta novos arquivos nas pastas monitoradas e os ingere no CAS de forma idempotente.

.DESCRIPTION
    Estratégia: scan periódico com comparação contra o fractal_index.json canônico.
    Não usa FileSystemWatcher (instável em volumes NTFS sob alta carga).
    Loop polling com intervalo configurável — compatível com Task Scheduler.

.PARAMETER IntervalSeg
    Intervalo entre scans em segundos. Padrão: 300 (5 min).

.PARAMETER UmaVez
    Executa um ciclo único e sai (útil para Task Scheduler).

.PARAMETER Verbose
    Log detalhado de cada arquivo verificado.

.EXAMPLE
    .\TEIA-Sync-Watchdog.ps1                    # loop contínuo a cada 5 min
    .\TEIA-Sync-Watchdog.ps1 -UmaVez            # ciclo único (Task Scheduler)
    .\TEIA-Sync-Watchdog.ps1 -IntervalSeg 60    # ciclo a cada 1 min
#>
[CmdletBinding()]
param(
    [int]$IntervalSeg = 300,
    [switch]$UmaVez
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'

# ── Paths canônicos ──────────────────────────────────────────────────────────
$CASRoot    = 'D:\TEIA_CORE\objects'
$IndexPath  = 'D:\TEIA_CORE\manifests\fractal_index.json'
$EventLog   = 'D:\TEIA_CORE\dna_events.jsonl'
$StateFile  = 'D:\TEIA_CORE\memory\watchdog_state.json'
$OrfaoIndex = 'D:\bruto\TEIA\fractal_index.json'

$Monitoradas = @(
    'D:\bruto\TEIA\TEIA_Data',
    'D:\bruto\TEIA\TEIA_ATLAS',
    'D:\bruto\TEIA\Analisados',
    'D:\bruto\TEIA\TEIA_NUCLEO'
)
$CachePattern = 'Miniconda|OllamaModels|__pycache__|\.git\\|Lixo_Entropico'

foreach ($d in @((Split-Path $StateFile), $CASRoot, (Split-Path $IndexPath))) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# ── Logger ───────────────────────────────────────────────────────────────────
function Write-WDEvent {
    param([string]$Act, [hashtable]$Data)
    $line = ([ordered]@{
        ts   = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
        src  = 'Watchdog'
        act  = $Act
        data = $Data
    } | ConvertTo-Json -Compress -Depth 4)
    Add-Content -LiteralPath $EventLog -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

function Write-WD { param([string]$Msg) Write-Host "[WD $(Get-Date -Format 'HH:mm:ss')] $Msg" }

# ── Carregar hashes conhecidos no CAS ────────────────────────────────────────
function Get-CASHashes {
    $set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    if (Test-Path $IndexPath) {
        $idx = Get-Content $IndexPath -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($idx) { foreach ($e in $idx) { if ($e.hash) { [void]$set.Add($e.hash) } } }
    }
    return $set
}

# ── Carregar lookup do índice órfão (para confirmar novos arquivos) ───────────
function Get-OrfaoLookup {
    $dict = [System.Collections.Generic.Dictionary[long,bool]]::new()
    $hdict = [System.Collections.Generic.Dictionary[string,PSCustomObject]]::new([System.StringComparer]::OrdinalIgnoreCase)
    if (Test-Path $OrfaoIndex) {
        $orfao = Get-Content $OrfaoIndex -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($orfao) {
            foreach ($e in $orfao) {
                if (-not $e.hash) { continue }
                $hdict[$e.hash] = $e
                $sz = if($null -ne $e.size){[long]$e.size}else{-1L}
                $dict[$sz] = $true
            }
        }
    }
    return $hdict, $dict
}

# ── Ingestão de um único arquivo confirmado ──────────────────────────────────
function Invoke-IngestFile {
    param([System.IO.FileInfo]$File, [string]$Hash, [PSCustomObject]$OrfaoEntry)

    $dest = Join-Path $CASRoot "$($Hash.ToLower()).bin"
    if (Test-Path $dest) { return 'SKIP' }  # idempotente

    try {
        Copy-Item -LiteralPath $File.FullName -Destination $dest -Force -ErrorAction Stop
        $verifHash = (Get-FileHash $dest -Algorithm SHA256 -ErrorAction Stop).Hash
        if ($verifHash -ine $Hash) {
            Remove-Item $dest -ErrorAction SilentlyContinue
            throw "Hash pós-cópia diverge"
        }

        # Atualizar fractal_index.json
        $idx = @()
        if (Test-Path $IndexPath) {
            $raw = Get-Content $IndexPath -Raw -ErrorAction SilentlyContinue
            if ($raw -and $raw.Trim().Length -gt 2) {
                $idx = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue
            }
        }
        $idx += [PSCustomObject]@{
            hash          = $Hash.ToLower()
            size          = $File.Length
            nome_original = if($OrfaoEntry.file){$OrfaoEntry.file}else{$File.Name}
            path_cas      = $dest
            path_origem   = $File.FullName
            created_orig  = if($OrfaoEntry.created){$OrfaoEntry.created}else{$null}
            seed          = if($OrfaoEntry.seed){$OrfaoEntry.seed}else{$null}
            indexed_at    = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
            version       = 'watchdog-v0.13.0'
        }
        $idx | ConvertTo-Json -Depth 4 | Set-Content $IndexPath -Encoding UTF8

        Write-WDEvent 'WD_INGEST_OK' @{
            sha256    = $Hash
            origem    = $File.FullName
            destino   = $dest
            tamanho   = $File.Length
            nome_orig = $OrfaoEntry.file
        }
        return 'OK'
    } catch {
        Write-WDEvent 'WD_INGEST_FAIL' @{ sha256 = $Hash; origem = $File.FullName; erro = $_.ToString() }
        return 'FAIL'
    }
}

# ── Ciclo principal ──────────────────────────────────────────────────────────
function Invoke-WatchdogCycle {
    $cycleStart = Get-Date
    Write-WD "Ciclo iniciado"
    Write-WDEvent 'WD_CYCLE_START' @{ ts = $cycleStart.ToString('o') }

    $casHashes          = Get-CASHashes
    $orfaoHashLookup, $orfaoSizeLookup = Get-OrfaoLookup

    $novoOk = 0; $novoFail = 0; $ignorados = 0

    foreach ($pasta in $Monitoradas) {
        if (-not (Test-Path $pasta)) { continue }
        $files = Get-ChildItem $pasta -Recurse -File -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch $CachePattern }

        foreach ($f in $files) {
            # Pré-filtro: tamanho não está no lookup → não é candidato CAS
            if (-not $orfaoSizeLookup.ContainsKey($f.Length)) { $ignorados++; continue }

            $hash = (Get-FileHash $f.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
            if (-not $hash) { continue }

            # Já está no CAS → ignorar
            if ($casHashes.Contains($hash)) { $ignorados++; continue }

            # Não está no índice órfão → não é um objeto CAS conhecido
            if (-not $orfaoHashLookup.ContainsKey($hash)) { $ignorados++; continue }

            # Novo arquivo confirmado → ingerir
            Write-WD "Novo objeto detectado: $($f.Name) ($($hash.Substring(0,16))...)"
            $result = Invoke-IngestFile -File $f -Hash $hash -OrfaoEntry $orfaoHashLookup[$hash]
            if ($result -eq 'OK') { $novoOk++; [void]$casHashes.Add($hash) }
            elseif ($result -eq 'FAIL') { $novoFail++ }
        }
    }

    $elapsed = [math]::Round(((Get-Date) - $cycleStart).TotalSeconds, 1)
    Write-WD "Ciclo concluído — Novos ingeridos: $novoOk | Falhas: $novoFail | Ignorados: $ignorados | ${elapsed}s"
    Write-WDEvent 'WD_CYCLE_END' @{
        novos_ok   = $novoOk
        falhas     = $novoFail
        ignorados  = $ignorados
        elapsed_s  = $elapsed
        cas_total  = $casHashes.Count
    }

    # Salvar estado
    @{ ultimo_ciclo = (Get-Date -Format 'o'); cas_total = $casHashes.Count; novos_ok = $novoOk } |
        ConvertTo-Json | Set-Content $StateFile -Encoding UTF8
}

# ── Entry point ──────────────────────────────────────────────────────────────
Write-WD "TEIA-Sync-Watchdog v0.13.0 iniciado"
Write-WD "Pastas monitoradas: $($Monitoradas -join ' | ')"
Write-WDEvent 'WD_START' @{ interval_seg = $IntervalSeg; uma_vez = $UmaVez.IsPresent }

if ($UmaVez) {
    Invoke-WatchdogCycle
} else {
    while ($true) {
        Invoke-WatchdogCycle
        Write-WD "Aguardando ${IntervalSeg}s até o próximo ciclo... (Ctrl+C para parar)"
        Start-Sleep -Seconds $IntervalSeg
    }
}
