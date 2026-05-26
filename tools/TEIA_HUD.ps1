<#
.SYNOPSIS
    TEIA_HUD v0.14.0 — Dashboard de saúde em tempo real da TEIA-Omega.

.PARAMETER RefreshSeg
    Intervalo de atualização em segundos. Padrão: 10.

.PARAMETER UmaVez
    Exibe uma vez e sai (útil para scripts).

.EXAMPLE
    .\TEIA_HUD.ps1                 # atualiza a cada 10s
    .\TEIA_HUD.ps1 -RefreshSeg 5  # atualiza a cada 5s
    .\TEIA_HUD.ps1 -UmaVez        # snapshot único
#>
[CmdletBinding()]
param(
    [int]$RefreshSeg = 10,
    [switch]$UmaVez
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'SilentlyContinue'

# ── Paths ────────────────────────────────────────────────────────────────────
$CASRoot     = 'D:\TEIA_CORE\objects'
$IndexPath   = 'D:\TEIA_CORE\manifests\fractal_index.json'
$TeiaMapPath = 'D:\TEIA_CORE\manifests\.teia_map.json'
$EventLog    = 'D:\TEIA_CORE\dna_events.jsonl'
$StateFile   = 'D:\TEIA_CORE\memory\watchdog_state.json'

# ── Helpers ──────────────────────────────────────────────────────────────────
function Get-StatusIcon { param([bool]$Ok) if($Ok){'[OK]'}else{'[!!]'} }

function Get-CASIntegrity {
    $bins = Get-ChildItem $CASRoot -Filter "*.bin" -ErrorAction SilentlyContinue
    if (-not $bins) { return @{ Total=0; Ok=0; Fail=0; Percent='N/A' } }
    $ok = 0; $fail = 0
    foreach ($b in $bins) {
        $expected = [System.IO.Path]::GetFileNameWithoutExtension($b.Name).ToUpper()
        $actual   = (Get-FileHash $b.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        if ($actual -and $actual -eq $expected) { $ok++ } else { $fail++ }
    }
    $pct = if($bins.Count -gt 0){"$([math]::Round($ok/$bins.Count*100,1))%"}else{'N/A'}
    return @{ Total=$bins.Count; Ok=$ok; Fail=$fail; Percent=$pct }
}

function Get-IndexStats {
    if (-not (Test-Path $IndexPath)) { return @{ Count=0; SizeKB=0; LastIndexed='N/A' } }
    $item = Get-Item $IndexPath
    try {
        $idx = Get-Content $IndexPath -Raw | ConvertFrom-Json -ErrorAction Stop
        $last = ($idx | Sort-Object indexed_at | Select-Object -Last 1).indexed_at
        return @{ Count=$idx.Count; SizeKB=[math]::Round($item.Length/1KB,1); LastIndexed=$last }
    } catch {
        return @{ Count=0; SizeKB=[math]::Round($item.Length/1KB,1); LastIndexed='parse error' }
    }
}

function Get-LastEvents {
    param([int]$N = 5)
    if (-not (Test-Path $EventLog)) { return @() }
    $lines = Get-Content $EventLog -Tail $N -ErrorAction SilentlyContinue
    $events = $lines | ForEach-Object {
        try { $_ | ConvertFrom-Json -ErrorAction Stop } catch { $null }
    } | Where-Object { $_ }
    return $events
}

function Get-DriveSpace {
    $drive = Get-PSDrive D -ErrorAction SilentlyContinue
    if (-not $drive) { return @{ UsedGB=0; FreeGB=0; TotalGB=0; FreePct='N/A' } }
    $freeGB  = [math]::Round($drive.Free/1GB, 1)
    $usedGB  = [math]::Round($drive.Used/1GB, 1)
    $totalGB = [math]::Round(($drive.Free + $drive.Used)/1GB, 1)
    $freePct = "$([math]::Round($drive.Free/($drive.Free+$drive.Used)*100,1))%"
    return @{ UsedGB=$usedGB; FreeGB=$freeGB; TotalGB=$totalGB; FreePct=$freePct }
}

function Get-AgentStatus {
    $agents = [ordered]@{
        'Watchdog (TEIA)'   = 'TEIA-Sync-Watchdog'
        'Python (TEIA)'     = 'python'
        'Ollama'            = 'ollama'
        'Node (PaperclipAI)'= 'node'
    }
    $status = [ordered]@{}
    foreach ($name in $agents.Keys) {
        $proc = Get-Process -Name $agents[$name] -ErrorAction SilentlyContinue | Select-Object -First 1
        $status[$name] = if($proc){"ATIVO (PID $($proc.Id))"}else{"inativo"}
    }
    return $status
}

function Get-WatchdogState {
    if (-not (Test-Path $StateFile)) { return $null }
    try { return Get-Content $StateFile -Raw | ConvertFrom-Json } catch { return $null }
}

function Get-CASSize {
    $bins = Get-ChildItem $CASRoot -Filter "*.bin" -ErrorAction SilentlyContinue
    $sz = ($bins | Measure-Object Length -Sum).Sum
    return [math]::Round($sz/1MB, 1)
}

function Get-TeiaMapStats {
    if (-not (Test-Path $TeiaMapPath)) {
        return @{ Total=0; Ingested=0; Verified=0; MissingOriginal=0; TotalMB=0; ValidatedMB=0; SavingsMB=0 }
    }
    try {
        $map = Get-Content $TeiaMapPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if (-not $map) { return @{ Total=0; Ingested=0; Verified=0; MissingOriginal=0; TotalMB=0; ValidatedMB=0; SavingsMB=0 } }
        $ingested  = @($map | Where-Object { $_.status -eq 'INGESTED' })
        $verified  = @($map | Where-Object { $_.status -eq 'VERIFIED' })
        $missing   = @($map | Where-Object { $_.status -eq 'MISSING_ORIGINAL' })
        $totalMB   = [math]::Round(($map    | Measure-Object -Property size -Sum).Sum / 1MB, 2)
        $validMB   = [math]::Round((($ingested + $verified) | Measure-Object -Property size -Sum).Sum / 1MB, 2)
        $savings   = 0L
        $map | Group-Object hash | Where-Object { $_.Count -gt 1 } | ForEach-Object {
            $savings += ($_.Count - 1) * [long]$_.Group[0].size
        }
        return @{
            Total           = $map.Count
            Ingested        = $ingested.Count
            Verified        = $verified.Count
            MissingOriginal = $missing.Count
            TotalMB         = $totalMB
            ValidatedMB     = $validMB
            SavingsMB       = [math]::Round($savings / 1MB, 2)
        }
    } catch {
        return @{ Total=0; Ingested=0; Verified=0; MissingOriginal=0; TotalMB=0; ValidatedMB=0; SavingsMB=0 }
    }
}

# ── Render ───────────────────────────────────────────────────────────────────
function Show-HUD {
    $now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    # Coleta paralela (independente de ordem)
    $cas    = Get-CASIntegrity
    $idx    = Get-IndexStats
    $drive  = Get-DriveSpace
    $agents = Get-AgentStatus
    $events = Get-LastEvents -N 6
    $wdSt   = Get-WatchdogState
    $casMB  = Get-CASSize
    $tmap   = Get-TeiaMapStats

    $casOk  = ($cas.Fail -eq 0 -and $cas.Total -gt 0)
    $idxOk  = ($idx.Count -gt 0)

    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           TEIA-Ω HUD v0.14.0  |  $now          ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

    # ── CAS ──────────────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "  ┌─ CAS (Content-Addressable Storage)" -ForegroundColor Yellow
    $casColor = if($casOk){'Green'}else{'Red'}
    Write-Host "  │  $(Get-StatusIcon $casOk) Integridade SHA-256:  $($cas.Ok)/$($cas.Total) objetos ($($cas.Percent))" -ForegroundColor $casColor
    Write-Host "  │  $(Get-StatusIcon $true)  Volume no disco:      ${casMB} MB" -ForegroundColor White
    Write-Host "  │  Localização: $CASRoot" -ForegroundColor DarkGray

    # ── ÍNDICE ───────────────────────────────────────────────────────────────
    Write-Host "  ├─ Fractal Index" -ForegroundColor Yellow
    Write-Host "  │  $(Get-StatusIcon $idxOk) Entradas:            $($idx.Count)" -ForegroundColor $(if($idxOk){'Green'}else{'Red'})
    Write-Host "  │     Tamanho do índice:   $($idx.SizeKB)KB" -ForegroundColor White
    Write-Host "  │     Última indexação:    $($idx.LastIndexed)" -ForegroundColor White

    # ── WATCHDOG ─────────────────────────────────────────────────────────────
    Write-Host "  ├─ Watchdog" -ForegroundColor Yellow
    if ($wdSt) {
        Write-Host "  │  [OK] Último ciclo:       $($wdSt.ultimo_ciclo)" -ForegroundColor Green
        Write-Host "  │       CAS pós-ciclo:      $($wdSt.cas_total) objetos" -ForegroundColor White
        Write-Host "  │       Novos no ciclo:     $($wdSt.novos_ok)" -ForegroundColor White
    } else {
        Write-Host "  │  [--] Watchdog não executou nenhum ciclo ainda" -ForegroundColor DarkGray
        Write-Host "  │       Execute: .\TEIA-Sync-Watchdog.ps1" -ForegroundColor DarkGray
    }

    # ── TEIA_USER ─────────────────────────────────────────────────────────────
    Write-Host "  ├─ TEIA_USER Integridade" -ForegroundColor Yellow
    if ($tmap.Total -gt 0) {
        $mapOk = ($tmap.MissingOriginal -eq 0)
        Write-Host "  │  $(Get-StatusIcon $mapOk) Mapeados:            $($tmap.Total)" -ForegroundColor $(if($mapOk){'Green'}else{'Yellow'})
        Write-Host "  │     INGESTED:           $($tmap.Ingested)" -ForegroundColor White
        Write-Host "  │     VERIFIED:           $($tmap.Verified)" -ForegroundColor $(if($tmap.Verified -gt 0){'Green'}else{'DarkGray'})
        Write-Host "  │     MISSING_ORIGINAL:   $($tmap.MissingOriginal)" -ForegroundColor $(if($tmap.MissingOriginal -gt 0){'Red'}else{'DarkGray'})
        Write-Host "  │     Validado/Total:     $($tmap.ValidatedMB)MB / $($tmap.TotalMB)MB" -ForegroundColor White
        Write-Host "  │     Economia (dedup):   $($tmap.SavingsMB)MB" -ForegroundColor $(if($tmap.SavingsMB -gt 0){'Green'}else{'DarkGray'})
    } else {
        Write-Host "  │  [--] .teia_map.json vazio — execute TEIA-Ingerir.ps1" -ForegroundColor DarkGray
    }

    # ── DISCO ────────────────────────────────────────────────────────────────
    Write-Host "  ├─ Drive D:\" -ForegroundColor Yellow
    $spaceColor = if([double]($drive.FreePct -replace '%','') -gt 10){'Green'}else{'Red'}
    Write-Host "  │  $(Get-StatusIcon ($drive.FreeGB -gt 5))  Livre:               $($drive.FreeGB)GB / $($drive.TotalGB)GB ($($drive.FreePct))" -ForegroundColor $spaceColor
    Write-Host "  │     Usado:               $($drive.UsedGB)GB" -ForegroundColor White

    # ── AGENTES ──────────────────────────────────────────────────────────────
    Write-Host "  ├─ Agentes" -ForegroundColor Yellow
    foreach ($name in $agents.Keys) {
        $val = $agents[$name]
        $color = if($val -match 'ATIVO'){'Green'}else{'DarkGray'}
        $icon  = if($val -match 'ATIVO'){'[ON]'}else{'[--]'}
        Write-Host "  │  $icon $name`:  $val" -ForegroundColor $color
    }

    # ── EVENTOS RECENTES ─────────────────────────────────────────────────────
    Write-Host "  └─ Últimos eventos (dna_events.jsonl)" -ForegroundColor Yellow
    if ($events) {
        foreach ($ev in $events) {
            $tsRaw = if($ev.ts){"$($ev.ts)"}else{'?'}
            $ts    = if($tsRaw.Length -ge 19){$tsRaw.Substring(0,19)}else{$tsRaw}
            $act   = $ev.act
            $src   = if($ev.src){$ev.src}elseif($ev.run){$ev.run.Substring(0,[math]::Min(12,$ev.run.Length))}else{'teia'}
            $color = switch -Wildcard ($act) {
                '*FAIL*' { 'Red' }
                '*OK*'   { 'Green' }
                '*START' { 'Cyan' }
                '*END'   { 'Cyan' }
                default  { 'White' }
            }
            Write-Host "     $ts  [$src] $act" -ForegroundColor $color
        }
    } else {
        Write-Host "     (nenhum evento registrado)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  [Atualiza a cada ${RefreshSeg}s — Ctrl+C para sair]" -ForegroundColor DarkGray
}

# ── Entry point ──────────────────────────────────────────────────────────────
if ($UmaVez) {
    Show-HUD
} else {
    while ($true) {
        Show-HUD
        Start-Sleep -Seconds $RefreshSeg
    }
}
