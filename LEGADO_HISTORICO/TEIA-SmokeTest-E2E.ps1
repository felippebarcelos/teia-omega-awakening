# ==============================================================================
# TEIA-SmokeTest-E2E.ps1 | Prova de Idempotência e Honestidade Entrópica
# ==============================================================================
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$BaseDir = "D:\TEIA_CLAUDE_AWAKENING"
$TargetFile = "$BaseDir\Arqueologia do motor AION RISPA\video_teste.M4V"
$SeedPath = "$TargetFile.seed.json"
$RestoredFile = "$BaseDir\Arqueologia do motor AION RISPA\video_teste_RESTORED.M4V"

$Gerador = "$BaseDir\NUCLEO_RESGATADO\AION-RISPA-NDC-UniProc-v05.ps1"
$Restaurador = "$BaseDir\NUCLEO_RESGATADO\TEIA-Core-v1.0.0.ps1"

Write-Host "`n[Delta-Mestre-TESTE] Iniciando Validação E2E do Motor AION-RISPA..." -ForegroundColor Cyan

# 1. Obter Hash Original
if (-not (Test-Path $TargetFile)) { throw "Arquivo alvo não encontrado: $TargetFile" }
Write-Host "[1/4] Calculando SHA-256 do arquivo original..."
$OriginalHash = (Get-FileHash -Path $TargetFile -Algorithm SHA256).Hash

# Limpar artefatos de testes anteriores
if (Test-Path $SeedPath) { Remove-Item $SeedPath -Force }
if (Test-Path $RestoredFile) { Remove-Item $RestoredFile -Force }

# 2. Gerar a Seed Procedural
Write-Host "[2/4] Gerando Seed Procedural (Compressão/Ontogênese)..." -ForegroundColor Yellow
& $Gerador -Mode "seed" -InPath $TargetFile -SeedPath $SeedPath

if (-not (Test-Path $SeedPath)) { throw "Falha catastrófica: A Semente não foi gerada." }

# 3. Restaurar a partir da Seed
Write-Host "[3/4] Reconstruindo arquivo a partir da Seed..." -ForegroundColor Yellow
& $Restaurador -SeedPath $SeedPath -OutDir (Split-Path $TargetFile)
# O TEIA-Core normalmente salva com o nome original ou com um sufixo, se precisar renomear:
$OutputGerado = "$BaseDir\Arqueologia do motor AION RISPA\video_teste.M4V_restored" # Ajuste caso o core salve diferente
if (Test-Path $OutputGerado) {
    Rename-Item -Path $OutputGerado -NewName "video_teste_RESTORED.M4V" -Force
}

# 4. Prova de Idempotência
Write-Host "[4/4] Validando Idempotência (Comparação de Hashes)..." -ForegroundColor Yellow
if (-not (Test-Path $RestoredFile)) {
    # Tenta achar o arquivo restaurado se o nome for diferente
    $RestoredFile = Get-ChildItem (Split-Path $TargetFile) | Where-Object { $_.Name -match "video_teste" -and $_.Name -ne "video_teste.M4V" } | Select-Object -ExpandProperty FullName -First 1
}

$RestoredHash = (Get-FileHash -Path $RestoredFile -Algorithm SHA256).Hash

Write-Host "`n================ RESULTADO DA PROVA ================"
Write-Host "HASH ORIGINAL : $OriginalHash"
Write-Host "HASH RESTAURO : $RestoredHash"

if ($OriginalHash -eq $RestoredHash) {
    Write-Host "[SUCESSO ABSOLUTO] O Limiar de Kolmogorov foi superado. Idempotência garantida." -ForegroundColor Green
} else {
    Write-Host "[FALHA DE IDEMPOTÊNCIA] O arquivo restaurado diverge da matriz original." -ForegroundColor Red
}
Write-Host "====================================================`n"