# AION-Restore-Watcher.ps1 — Watcher de fila de restauração AION-RISPA-NDC
# EXTRAÍDO de 00-AION-Migrate.ps1 ($watcher heredoc) + standalone
# Monitora aion_restore_queue.jsonl e despacha jobs via aion.cmd (ou adapter)
param(
    [string]$Queue = '',
    [string]$Log   = '',
    [string]$AionCmd = '',
    [int]$PollMs = 400
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Queue = if ($Queue)   { $Queue }   elseif ($env:AION_QUEUE) { $env:AION_QUEUE } `
         else { Join-Path $env:TEMP 'aion_restore_queue.jsonl' }
$Log   = if ($Log)     { $Log }     elseif ($env:AION_LOGS)  { Join-Path $env:AION_LOGS 'restore_watcher.log' } `
         else { Join-Path (Join-Path $env:LOCALAPPDATA 'AION\logs') 'restore_watcher.log' }

# Se não informado, tenta resolver aion.cmd relativo ao script ou ao AION_BIN
if (-not $AionCmd) {
    $binDir  = if ($env:AION_BIN) { $env:AION_BIN } else { Join-Path $env:LOCALAPPDATA 'AION\bin' }
    $AionCmd = Join-Path $binDir 'aion.cmd'
}

New-Item -ItemType File      -Force -Path $Queue | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Log) | Out-Null

$seen = New-Object System.Collections.Generic.HashSet[string]

function Write-Log($m) {
    ("$((Get-Date).ToString('s'))`t$m") | Add-Content -LiteralPath $Log -Encoding UTF8
    Write-Host $m
}

Write-Log "[INIT] Watcher ON. Queue=$Queue AionCmd=$AionCmd"

while ($true) {
    try {
        $content = Get-Content -LiteralPath $Queue -Raw -ErrorAction SilentlyContinue
        if (-not [string]::IsNullOrWhiteSpace($content)) {
            foreach ($ln in ($content -split "`n")) {
                if ([string]::IsNullOrWhiteSpace($ln)) { continue }
                if (-not $seen.Add($ln)) { continue }

                try { $job = $ln | ConvertFrom-Json } catch {
                    Write-Log "[ERR] JSON inválido: $ln"; continue
                }

                $mode    = [string]$job.mode
                $seed    = [string]$job.seed
                $out     = [string]$job.out
                $index   = [string]$job.index
                $root    = [string]$job.root
                $maxscan = 1000000
                if ($job.PSObject.Properties.Name -contains 'maxscan' -and $null -ne $job.maxscan -and [int]$job.maxscan -gt 0) {
                    $maxscan = [int]$job.maxscan
                }

                Write-Log "[JOB] mode=$mode seed=$seed out=$out"

                if ([string]::IsNullOrWhiteSpace($seed) -or [string]::IsNullOrWhiteSpace($out)) {
                    Write-Log "[ERR] Job inválido (campos obrigatórios vazios): $ln"
                    continue
                }

                if (!(Test-Path $AionCmd)) {
                    Write-Log "[WARN] aion.cmd não encontrado em $AionCmd — tentando restore direto via seed"
                    if (Test-Path $seed) {
                        $seedObj = Get-Content -LiteralPath $seed -Raw | ConvertFrom-Json
                        if ($seedObj.source_path -and (Test-Path $seedObj.source_path)) {
                            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $out) | Out-Null
                            Copy-Item -LiteralPath $seedObj.source_path -Destination $out -Force
                            Write-Log "[OK-DIRECT] Restaurado de source_path: $out"
                        } else {
                            Write-Log "[ERR] Sem aion.cmd e sem source_path válido na seed"
                        }
                    }
                    continue
                }

                if ($mode -eq 'index') {
                    & $AionCmd restore-index -seed $seed -index $index -out $out
                } else {
                    & $AionCmd restore-scan  -seed $seed -root  $root  -out $out -maxscan $maxscan
                }

                # Verificação SHA-256 (P0-I2: auditoria real, não inferência)
                try {
                    $shaSeed = ((Get-Content -LiteralPath $seed -Raw | ConvertFrom-Json).sha256).ToLower()
                    $shaOut  = (Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash.ToLower()
                    if ($shaSeed -ne $shaOut) { throw "SHA mismatch: expected=$shaSeed got=$shaOut" }
                    Write-Log "[OK] $mode out=$out sha=$shaOut"
                } catch {
                    Write-Log "[ERR] $($_.Exception.Message)"
                }
            }
            Clear-Content -LiteralPath $Queue -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Log "[ERR] Loop: $($_.Exception.Message)"
    }
    Start-Sleep -Milliseconds $PollMs
}
