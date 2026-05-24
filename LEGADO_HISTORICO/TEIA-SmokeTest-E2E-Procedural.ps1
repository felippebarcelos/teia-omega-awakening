# ==============================================================================
# TEIA-SmokeTest-E2E-Procedural.ps1 | A Prova da Honestidade Entropica
# ==============================================================================
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$BaseDir = "D:\TEIA_CLAUDE_AWAKENING"
$TestDir = "$BaseDir\NUCLEO_RESGATADO"
$TargetFile = "$TestDir\documento_prova.txt"
$SeedPath = "$TargetFile.seed.json"
$RestoredFile = "$TestDir\documento_prova_RESTORED.txt"

$Gerador = "$TestDir\AION-RISPA-NDC-UniProc-v05.ps1"
$Restaurador = "$TestDir\TEIA-Core-v1.0.0.ps1"

Write-Host "`n[Delta-TESTE] Preparando terreno de Baixa Entropia..." -ForegroundColor Cyan

# 0. Criar um arquivo procedural perfeito para teste (Texto repetitivo)
$conteudo = "TEIA_NUCLEO_PROCEDURAL_VIVA_" * 5000 
Set-Content -Path $TargetFile -Value $conteudo -Encoding UTF8

Write-Host "[1/4] Calculando SHA-256 do arquivo matriz..."
$OriginalHash = (Get-FileHash -Path $TargetFile -Algorithm SHA256).Hash

if (Test-Path $SeedPath) { Remove-Item $SeedPath -Force }
if (Test-Path $RestoredFile) { Remove-Item $RestoredFile -Force }

Write-Host "[2/4] Gerando Seed Procedural (Rapido e Limpo)..." -ForegroundColor Yellow
& $Gerador -Mode "seed" -InPath $TargetFile -SeedPath $SeedPath

if (-not (Test-Path $SeedPath)) { throw "Falha catastrofica: Seed nao gerada." }

Write-Host "[3/4] Reconstruindo arquivo a partir da Seed..." -ForegroundColor Yellow
& $Restaurador -SeedPath $SeedPath -OutDir $TestDir

$OutputGerado = "$TargetFile`_restored"
if (Test-Path $OutputGerado) {
    Rename-Item -Path $OutputGerado -NewName "documento_prova_RESTORED.txt" -Force
}

Write-Host "[4/4] Validando Idempotencia..." -ForegroundColor Yellow
$RestoredHash = (Get-FileHash -Path $RestoredFile -Algorithm SHA256).Hash

Write-Host "`n================ RESULTADO DA PROVA ================"
Write-Host "HASH ORIGINAL : $OriginalHash"
Write-Host "HASH RESTAURO : $RestoredHash"

if ($OriginalHash -eq $RestoredHash) {
    Write-Host "[SUCESSO ABSOLUTO] O Limiar de Kolmogorov foi superado na pratica procedural." -ForegroundColor Green
} else {
    Write-Host "[FALHA DE IDEMPOTENCIA] O arquivo restaurado diverge." -ForegroundColor Red
}
Write-Host "====================================================`n"
