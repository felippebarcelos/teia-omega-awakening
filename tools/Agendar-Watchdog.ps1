<#
.SYNOPSIS
    Agendar-Watchdog.ps1 — Registra ou remove a tarefa agendada "TEIA-Sync-Watchdog-v0131".

.DESCRIPTION
    Cria uma tarefa no Windows Task Scheduler que dispara o Watchdog v0.13.1
    a cada 10 minutos no contexto do usuário atual.
    Use -Remover para desfazer o registro.

.PARAMETER Remover
    Remove a tarefa agendada caso exista.

.EXAMPLE
    .\Agendar-Watchdog.ps1            # registra a tarefa
    .\Agendar-Watchdog.ps1 -Remover   # remove a tarefa
#>
[CmdletBinding()]
param([switch]$Remover)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$TaskName    = 'TEIA-Sync-Watchdog-v0131'
$PwshPath    = 'C:\Program Files\PowerShell\7\pwsh.exe'
$ScriptPath  = 'D:\TEIA_CORE\tools\TEIA-Sync-Watchdog.ps1'
$EventLog    = 'D:\TEIA_CORE\dna_events.jsonl'

function Write-AgEvent {
    param([string]$Act, [hashtable]$Data)
    $line = ([ordered]@{
        ts   = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
        src  = 'Agendar-Watchdog'
        act  = $Act
        data = $Data
    } | ConvertTo-Json -Compress -Depth 4)
    Add-Content -LiteralPath $EventLog -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

# ── Remoção ──────────────────────────────────────────────────────────────────
if ($Remover) {
    $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existing) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        Write-Host "[AG] Tarefa '$TaskName' removida com sucesso."
        Write-AgEvent 'TASK_UNREGISTERED' @{ task = $TaskName }
    } else {
        Write-Host "[AG] Tarefa '$TaskName' não encontrada — nada a remover."
    }
    exit 0
}

# ── Pré-validações ───────────────────────────────────────────────────────────
if (-not (Test-Path $PwshPath)) {
    Write-Error "pwsh.exe não encontrado em: $PwshPath"
    exit 1
}
if (-not (Test-Path $ScriptPath)) {
    Write-Error "Script do Watchdog não encontrado: $ScriptPath"
    exit 1
}

# ── Verificar se já existe ───────────────────────────────────────────────────
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "[AG] Tarefa '$TaskName' já existe (State: $($existing.State)). Use -Remover primeiro para recriar."
    exit 0
}

# ── Montar componentes da tarefa ─────────────────────────────────────────────
$action = New-ScheduledTaskAction `
    -Execute $PwshPath `
    -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`" -UmaVez"

# Trigger: dispara 1 min após registro e repete a cada 10 min por 10 anos (≈ infinito)
# RepetitionDuration não pode ser [TimeSpan]::MaxValue — usar 10 anos como proxy de infinito
$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval ([TimeSpan]::FromMinutes(10)) `
    -RepetitionDuration  ([TimeSpan]::FromDays(3650))

# Configurações: mata o processo após 5 minutos; não inicia nova instância se já roda
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit     (New-TimeSpan -Minutes 5) `
    -MultipleInstances      IgnoreNew `
    -StartWhenAvailable `
    -DisallowDemandStart:$false

# Principal: usuário atual, sessão interativa, privilégio normal
$principal = New-ScheduledTaskPrincipal `
    -UserId   "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel  Limited

# ── Registrar ────────────────────────────────────────────────────────────────
try {
    $task = Register-ScheduledTask `
        -TaskName   $TaskName `
        -Action     $action `
        -Trigger    $trigger `
        -Settings   $settings `
        -Principal  $principal `
        -Description "TEIA-Omega Watchdog v0.13.1 — sincronização CAS a cada 10 min" `
        -ErrorAction Stop

    Write-Host "[AG] Tarefa '$TaskName' registrada com sucesso."
    Write-Host "     Próxima execução: $((Get-ScheduledTaskInfo -TaskName $TaskName).NextRunTime)"
    Write-Host "     Ação: $PwshPath $($action.Arguments)"

    Write-AgEvent 'TASK_REGISTERED' @{
        task         = $TaskName
        interval_min = 10
        timeout_min  = 5
        usuario      = "$env:USERDOMAIN\$env:USERNAME"
        script       = $ScriptPath
    }
} catch {
    Write-Error "Falha ao registrar tarefa: $_"
    Write-AgEvent 'TASK_REGISTER_FAIL' @{ task = $TaskName; erro = $_.ToString() }
    exit 1
}
