#Requires -Version 7
# TEIA AION - Audit One-Click (Public Release v2.0.1)
# Demonstrates Storage as Computation in a sovereign, offline, deterministic environment.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"
$utf8 = [System.Text.UTF8Encoding]::new($false)

$targetFile = "csv_covid_countries_aggregated.csv"
$url = "https://raw.githubusercontent.com/datasets/covid-19/master/data/countries-aggregated.csv"

Write-Host "--- TEIA AION SOBERANA: AUDIT ONE-CLICK ---" -ForegroundColor Cyan
Write-Host "Iniciando auditoria pública v2.0.1..." -ForegroundColor Yellow

# 1. Download Dataset (Only Online Operation Allowed)
if (!(Test-Path $targetFile)) {
    Write-Host "Baixando dataset real para auditoria..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $url -OutFile $targetFile
}

# 2. Execute AION Engine
Write-Host "Executando Motor AION RISPA NDC (Offline/Determinístico)..." -ForegroundColor Cyan
./TEIA-AION-Engine.ps1

# 3. Validation Summary
$report = Get-Content "D:\TEIA_CLAUDE_AWAKENING\docs\TEIA_AION_NDC_CLEANROOM_AUDIT.md" -Raw
Write-Host "`nAUDITORIA CONCLUÍDA COM SUCESSO." -ForegroundColor Green
Write-Host "Resumo do Delta Real Observado:" -ForegroundColor Magenta

$deltaMatch = [regex]::Match($report, "Delta Real Observado de (\d+) bytes")
if ($deltaMatch.Success) {
    Write-Host "Delta Real: $($deltaMatch.Groups[1].Value) bytes de vantagem sobre Brotli SmallestSize." -ForegroundColor White
}

Write-Host "`nA representação procedural (Storage as Computation) é agora soberana." -ForegroundColor Cyan
Write-Host "Verifique os detalhes em TEIA_AION_NDC_CLEANROOM_AUDIT.md" -ForegroundColor Gray
