<#
.SYNOPSIS
    TEIA-Sync-Watchdog v0.13.1 — Monitoramento de drift e ingestão automática.
    Detecta novos arquivos nas pastas monitoradas e os ingere no CAS de forma idempotente.

.DESCRIPTION
    Estratégia: scan periódico com comparação contra o fractal_index.json canônico.
    Não usa FileSystemWatcher (instável em volumes NTFS sob alta carga).
    Loop polling com intervalo configurável — compatível com Task Scheduler.

    v0.13.1: escrita atômica de índice (tmp+bak+rename), singleton lock por PID,
    parâmetro -ReconcileOnly para reconciliar objetos CAS órfãos do índice.

.PARAMETER IntervalSeg
    Intervalo entre scans em segundos. Padrão: 300 (5 min).

.PARAMETER UmaVez
    Executa um ciclo único e sai (útil para Task Scheduler).

.PARAMETER ReconcileOnly
    Varre D:\TEIA_CORE\objects\*.bin, cruza com o índice e registra órfãos.
    Não copia nem apaga arquivos.

.EXAMPLE
    .\TEIA-Sync-Watchdog.ps1                    # loop contínuo a cada 5 min
    .\TEIA-Sync-Watchdog.ps1 -UmaVez            # ciclo único (Task Scheduler)
    .\TEIA-Sync-Watchdog.ps1 -IntervalSeg 60    # ciclo a cada 1 min
    .\TEIA-Sync-Watchdog.ps1 -ReconcileOnly     # reconcilia índice com CAS físico
#>
[CmdletBinding()]
param(
    [int]$IntervalSeg   = 300,
    [switch]$UmaVez,
    [switch]$ReconcileOnly
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'

# ── Paths canônicos ──────────────────────────────────────────────────────────
$CASRoot       = 'D:\TEIA_CORE\objects'
$IndexPath     = 'D:\TEIA_CORE\manifests\fractal_index.json'
$TeiaMapPath   = 'D:\TEIA_CORE\manifests\.teia_map.json'
$EventLog      = 'D:\TEIA_CORE\dna_events.jsonl'
$StateFile     = 'D:\TEIA_CORE\memory\watchdog_state.json'
$LockFile      = 'D:\TEIA_CORE\memory\watchdog.lock'
$QuarantineDir = 'D:\TEIA_CORE\QUARENTENA_DEBRIS'
$OrfaoIndex    = 'D:\bruto\TEIA\fractal_index.json'

$Monitoradas = @(
    'D:\bruto\TEIA\TEIA_Data',
    'D:\bruto\TEIA\TEIA_ATLAS',
    'D:\bruto\TEIA\Analisados',
    'D:\bruto\TEIA\TEIA_NUCLEO',
    'D:\TEIA_USER'
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

# ── Escrita atômica do fractal_index.json ────────────────────────────────────
# Padrão: serializa → grava em .tmp → verifica parse → .bak do original → rename
function Set-IndexAtomic {
    param([object[]]$Index)
    $tmp = "$IndexPath.tmp"
    $bak = "$IndexPath.bak"

    $json = $Index | ConvertTo-Json -Depth 4
    Set-Content -LiteralPath $tmp -Value $json -Encoding UTF8 -ErrorAction Stop

    # Verificação estrutural antes de substituir o original
    $verify = Get-Content $tmp -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $verify) { throw "Verificação JSON do .tmp falhou — original preservado" }

    if (Test-Path $IndexPath) {
        Copy-Item -LiteralPath $IndexPath -Destination $bak -Force -ErrorAction SilentlyContinue
    }

    Move-Item -LiteralPath $tmp -Destination $IndexPath -Force -ErrorAction Stop
}

# ── Singleton lock por PID ───────────────────────────────────────────────────
function Invoke-AcquireLock {
    if (Test-Path $LockFile) {
        $lockData = Get-Content $LockFile -Raw -ErrorAction SilentlyContinue |
            ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($lockData -and $lockData.pid) {
            $proc = Get-Process -Id ([int]$lockData.pid) -ErrorAction SilentlyContinue
            if ($proc) {
                Write-WDEvent 'WD_LOCK_ACTIVE' @{ pid = $lockData.pid; started = $lockData.started }
                Write-WD "LOCK ATIVO: PID $($lockData.pid) iniciado em $($lockData.started). Abortando."
                exit 1
            }
            Write-WD "Lock órfão detectado (PID $($lockData.pid) não existe). Limpando."
            Write-WDEvent 'WD_LOCK_ORPHAN' @{ pid = $lockData.pid; started = $lockData.started }
        }
    }
    @{ pid = $PID; started = (Get-Date -Format 'o'); host = $env:COMPUTERNAME } |
        ConvertTo-Json -Compress | Set-Content $LockFile -Encoding UTF8
}

function Invoke-ReleaseLock {
    Remove-Item $LockFile -ErrorAction SilentlyContinue
}

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
    $dict  = [System.Collections.Generic.Dictionary[long,bool]]::new()
    $hdict = [System.Collections.Generic.Dictionary[string,PSCustomObject]]::new([System.StringComparer]::OrdinalIgnoreCase)
    if (Test-Path $OrfaoIndex) {
        $orfao = Get-Content $OrfaoIndex -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($orfao) {
            foreach ($e in $orfao) {
                if (-not $e.hash) { continue }
                $hdict[$e.hash] = $e
                $sz = if ($null -ne $e.size) { [long]$e.size } else { -1L }
                $dict[$sz] = $true
            }
        }
    }
    return $hdict, $dict
}

# ── Quarentena: mover arquivo problemático sem deletar ───────────────────────
function Move-ToQuarantine {
    param([string]$Path, [string]$Reason = 'unspecified')
    if (-not (Test-Path $Path)) { return }
    if (-not (Test-Path $QuarantineDir)) {
        New-Item -ItemType Directory -Path $QuarantineDir -Force | Out-Null
    }
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $dest  = Join-Path $QuarantineDir "$stamp`_$(Split-Path $Path -Leaf)"
    Move-Item -LiteralPath $Path -Destination $dest -Force -ErrorAction SilentlyContinue
    Write-WDEvent 'WD_QUARANTINE' @{ origem = $Path; destino = $dest; razao = $Reason }
}

# ── Caminhos VERIFIED no .teia_map.json — evita re-hash no scan ──────────────
function Get-VerifiedPaths {
    $set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    if (-not (Test-Path $TeiaMapPath)) { return $set }
    $raw = Get-Content $TeiaMapPath -Raw -ErrorAction SilentlyContinue
    if (-not $raw -or $raw.Trim().Length -le 2) { return $set }
    $map = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($map) {
        foreach ($e in $map) {
            if ($e.status -eq 'VERIFIED' -and $e.path_user) { [void]$set.Add($e.path_user) }
        }
    }
    return $set
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
            Move-ToQuarantine -Path $dest -Reason 'hash-post-copy-mismatch'
            throw "Hash pós-cópia diverge"
        }

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
            nome_original = if ($OrfaoEntry.file) { $OrfaoEntry.file } else { $File.Name }
            path_cas      = $dest
            path_origem   = $File.FullName
            created_orig  = if ($OrfaoEntry.created) { $OrfaoEntry.created } else { $null }
            seed          = if ($OrfaoEntry.seed) { $OrfaoEntry.seed } else { $null }
            indexed_at    = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
            version       = 'watchdog-v0.13.1'
        }
        Set-IndexAtomic -Index $idx

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

# ── Reconciliação: registra no índice objetos .bin sem entrada ───────────────
function Invoke-ReconcileIndex {
    Write-WD "Reconciliação iniciada — varrendo $CASRoot"
    Write-WDEvent 'WD_RECONCILE_START' @{ cas_root = $CASRoot }

    $knownHashes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $idx = @()
    if (Test-Path $IndexPath) {
        $raw = Get-Content $IndexPath -Raw -ErrorAction SilentlyContinue
        if ($raw -and $raw.Trim().Length -gt 2) {
            $parsed = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($parsed) {
                $idx = $parsed
                foreach ($e in $idx) { if ($e.hash) { [void]$knownHashes.Add($e.hash) } }
            }
        }
    }

    $binFiles = Get-ChildItem $CASRoot -Filter '*.bin' -File -ErrorAction SilentlyContinue
    $added = 0; $skipped = 0; $mismatches = 0

    foreach ($bin in $binFiles) {
        $hashFromName = [System.IO.Path]::GetFileNameWithoutExtension($bin.Name)
        if ($knownHashes.Contains($hashFromName)) { $skipped++; continue }

        $actualHash = (Get-FileHash $bin.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        if (-not $actualHash) { continue }
        if ($actualHash -ine $hashFromName) {
            Write-WD "AVISO hash divergente: $($bin.Name)"
            Write-WDEvent 'WD_RECONCILE_HASH_MISMATCH' @{
                file     = $bin.Name
                expected = $hashFromName
                actual   = $actualHash
            }
            $mismatches++
            continue
        }

        $idx += [PSCustomObject]@{
            hash          = $hashFromName.ToLower()
            size          = $bin.Length
            nome_original = $null
            path_cas      = $bin.FullName
            path_origem   = $null
            created_orig  = $null
            seed          = $null
            indexed_at    = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
            version       = 'reconcile-v0.13.1'
        }
        [void]$knownHashes.Add($hashFromName)
        $added++
    }

    if ($added -gt 0) {
        Set-IndexAtomic -Index $idx
    }

    Write-WD "Reconciliação concluída — Adicionados: $added | Já no índice: $skipped | Divergências: $mismatches"
    Write-WDEvent 'WD_RECONCILE_END' @{ added = $added; skipped = $skipped; mismatches = $mismatches }
}

# ── Ciclo principal ──────────────────────────────────────────────────────────
function Invoke-WatchdogCycle {
    $cycleStart = Get-Date
    Write-WD "Ciclo iniciado"
    Write-WDEvent 'WD_CYCLE_START' @{ ts = $cycleStart.ToString('o') }

    $casHashes = Get-CASHashes
    if ($null -eq $casHashes) {
        $casHashes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }
    $orfaoHashLookup, $orfaoSizeLookup = Get-OrfaoLookup
    $verifiedPaths = Get-VerifiedPaths
    if ($null -eq $verifiedPaths) {
        $verifiedPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    $novoOk = 0; $novoFail = 0; $ignorados = 0

    foreach ($pasta in $Monitoradas) {
        if (-not (Test-Path $pasta)) { continue }
        $files = Get-ChildItem $pasta -Recurse -File -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch $CachePattern }

        foreach ($f in $files) {
            if ($verifiedPaths.Contains($f.FullName)) { $ignorados++; continue }
            if (-not $orfaoSizeLookup.ContainsKey($f.Length)) { $ignorados++; continue }

            $hash = (Get-FileHash $f.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
            if (-not $hash) { continue }

            if ($casHashes.Contains($hash)) { $ignorados++; continue }
            if (-not $orfaoHashLookup.ContainsKey($hash)) { $ignorados++; continue }

            Write-WD "Novo objeto detectado: $($f.Name) ($($hash.Substring(0,16))...)"
            $result = Invoke-IngestFile -File $f -Hash $hash -OrfaoEntry $orfaoHashLookup[$hash]
            if ($result -eq 'OK')   { $novoOk++;   [void]$casHashes.Add($hash) }
            elseif ($result -eq 'FAIL') { $novoFail++ }
        }
    }

    $elapsed = [math]::Round(((Get-Date) - $cycleStart).TotalSeconds, 1)
    Write-WD "Ciclo concluído — Novos ingeridos: $novoOk | Falhas: $novoFail | Ignorados: $ignorados | ${elapsed}s"
    Write-WDEvent 'WD_CYCLE_END' @{
        novos_ok  = $novoOk
        falhas    = $novoFail
        ignorados = $ignorados
        elapsed_s = $elapsed
        cas_total = $casHashes.Count
    }

    @{ ultimo_ciclo = (Get-Date -Format 'o'); cas_total = $casHashes.Count; novos_ok = $novoOk } |
        ConvertTo-Json | Set-Content $StateFile -Encoding UTF8
}

# ── Entry point ──────────────────────────────────────────────────────────────
Write-WD "TEIA-Sync-Watchdog v0.13.1 iniciado (PID $PID)"
Write-WDEvent 'WD_START' @{ version = 'v0.13.1'; interval_seg = $IntervalSeg; uma_vez = $UmaVez.IsPresent; reconcile_only = $ReconcileOnly.IsPresent; pid = $PID }

# ReconcileOnly ignora o lock — operação somente-leitura de índice
if ($ReconcileOnly) {
    Invoke-ReconcileIndex
    exit 0
}

Invoke-AcquireLock

try {
    Write-WD "Pastas monitoradas: $($Monitoradas -join ' | ')"

    if ($UmaVez) {
        Invoke-WatchdogCycle
    } else {
        while ($true) {
            Invoke-WatchdogCycle
            Write-WD "Aguardando ${IntervalSeg}s até o próximo ciclo... (Ctrl+C para parar)"
            Start-Sleep -Seconds $IntervalSeg
        }
    }
} finally {
    Invoke-ReleaseLock
    Write-WDEvent 'WD_STOP' @{ pid = $PID }
    Write-WD "Lock liberado. Watchdog encerrado."
}
