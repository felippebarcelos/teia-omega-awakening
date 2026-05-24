# =================== TEIA – Coleta & Backup Procedural ===================
# Este script coleta os arquivos das seções 1..7, cria staging, compacta no iCloud,
# e gera SHA256 + manifest. Pode ser executado quantas vezes quiser (idempotente).

# ---- Config ----
$SearchRoot = 'D:\Teia\TEIA_NUCLEO\offline\nano'
$iCloudRoot = 'C:\Users\felip\iCloudDrive'     # caminho fixo do iCloud no seu PC
if (-not (Test-Path $iCloudRoot)) { throw "iCloud Drive não encontrado em '$iCloudRoot'." }

$DestZipPath = Join-Path $iCloudRoot 'backup_procedural.zip'
$ShaOutPath  = "$DestZipPath.sha256.txt"
$ManifestOut = 'C:\Users\felip\iCloudDrive\backup_procedural_manifest.txt'
$Stage       = Join-Path $env:TEMP ("backup_procedural_stage_{0}" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

# LongPaths (melhora robustez)
if ([Environment]::OSVersion.Version.Major -ge 10) {
  try { New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -PropertyType DWord -Value 1 -Force | Out-Null } catch {}
}

# ---- Seleciona a melhor base para o alias TEIA-Fractal-Report.ps1 ----
Write-Host "==> Selecionando TEIA-ProofReport mais recente..." -ForegroundColor Cyan
$proofCandidates = Get-ChildItem -Path $SearchRoot -Recurse -Filter 'TEIA-ProofReport*.ps1' -File -ErrorAction SilentlyContinue
if ($proofCandidates) {
  $BestProof = $proofCandidates | Sort-Object LastWriteTimeUtc, Length -Descending | Select-Object -First 1
  $FractalReportTarget = Join-Path $SearchRoot 'TEIA-Fractal-Report.ps1'
  Copy-Item -LiteralPath $BestProof.FullName -Destination $FractalReportTarget -Force
  Write-Host "   ✔ Base: $($BestProof.FullName)"
  Write-Host "   ✔ Alias criado: $FractalReportTarget"
} else {
  Write-Warning "Nenhuma versão de TEIA-ProofReport*.ps1 encontrada; seguirei sem o alias TEIA-Fractal-Report.ps1."
}

# ---- Alvos das seções 1→7 ----
$WantedPatterns = @(
  # 1) Núcleo
  'TEIA-Fractal-DeltaEncode-v2.ps1',
  'TEIA-Fractal-DeltaRestore-v2.ps1','TEIA-Fractal-DeltaRestore-V2.ps1',
  'TEIA-Fractal-Index.ps1','TEIA-Fractal-Query.ps1',
  'TEIA-Fractal-FS-v2.4.ps1',
  'TEIA-Fractal-RetrofitSize-v2.ps1',
  'TEIA-HotOffsets-Heuristic.ps1',

  # 2) Integridade / Provas / Relatórios
  'TEIA-HashVerify.ps1','TEIA-Sign-Proof.ps1',
  'TEIA-ProofReport.ps1','TEIA-Fractal-Report.ps1',

  # 3) Políticas / Autosíntese
  'TEIA-Policy-Tune.ps1','TEIA-Policy-Boost.ps1',
  'TEIA-AutoSynthetico-v2.ps1','TEIA-Delta-AutoSynthetico-Min.ps1',

  # 4) Orquestração / Autonomia
  'teia-master.ps1','TEIA-Fractal-Launch.ps1',
  'TEIA-Fractal-ProvaReal-Launcher-P0.ps1',
  'TEIA-Fractal-RestoreOnDemand.ps1','TEIA-Fractal-Restore-OnDemand.ps1',
  'TEIA-Fractal-RestaurarAuto.ps1',
  'TEIA-Checklist-Run.v2.2.ps1','TEIA-Resume-Step.ps1','TEIA-InvokePwshFile.ps1',

  # 5) Benchmark / Diagnóstico
  'TEIA-Fractal-Benchmark-IO.ps1','TEIA-Fractal-Analytics.v2.ps1',
  'TEIA-Fractal-View-Benchmark.ps1','TEIA-Fractal-ColdWarm.ps1',

  # 6) Manutenção / Patch
  'TEIA-Fractal-FixBrace.ps1','TEIA-ApplyPatch.ps1','TEIA-Scripts-Registry-Update.ps1',

  # 7) Metadados (text/json)
  'LATEST_PACKAGE.txt','dna_autosynthetico_policy.v2.json',
  'manifest.json','flows.json','.gen.json'
)

# ---- Staging ----
New-Item -ItemType Directory -Path $Stage -Force | Out-Null
$Found   = New-Object System.Collections.Generic.List[System.IO.FileInfo]
$Missing = New-Object System.Collections.Generic.List[string]

Write-Host "`n==> Coletando arquivos..." -ForegroundColor Cyan
foreach ($pattern in $WantedPatterns) {
  $hits = Get-ChildItem -LiteralPath $SearchRoot -Recurse -File -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -like $pattern }
  if ($hits -and $hits.Count -gt 0) {
    $pick = $hits | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    $Found.Add($pick)
    $dest = Join-Path $Stage $pick.Name
    if (Test-Path $dest) {
      $base = [IO.Path]::GetFileNameWithoutExtension($pick.Name)
      $ext  = [IO.Path]::GetExtension($pick.Name)
      $dest = Join-Path $Stage ("{0}__{1}{2}" -f $base, (Get-Date -Format 'yyyyMMddHHmmss'), $ext)
    }
    Copy-Item -LiteralPath $pick.FullName -Destination $dest -Force
    Write-Host ("   ✔ {0}" -f $pick.FullName)
  } else {
    $Missing.Add($pattern)
    Write-Warning ("   ⨯ Não encontrado: {0}" -f $pattern)
  }
}

# Registra manifest e ausentes
$Found | ForEach-Object { $_.FullName } | Set-Content -Encoding UTF8 $ManifestOut
$Missing | Set-Content -Encoding UTF8 ($ManifestOut -replace '\.txt$','_FALTANTES.txt')

# ---- Compactação ----
Write-Host "`n==> Compactando para iCloud..." -ForegroundColor Cyan
if (Test-Path $DestZipPath) { Remove-Item $DestZipPath -Force }
Compress-Archive -Path (Join-Path $Stage '*') -DestinationPath $DestZipPath -CompressionLevel Optimal -Force

# ---- SHA256 do ZIP ----
$zipHash = (Get-FileHash -Algorithm SHA256 $DestZipPath).Hash
"{0}  {1}" -f $zipHash, $DestZipPath | Set-Content -Encoding ASCII $ShaOutPath

# ---- Fim ----
Write-Host "`nBackup:" -ForegroundColor Green
Write-Host "  $DestZipPath"
Write-Host "SHA256:" -ForegroundColor Green
Write-Host "  $zipHash"
Write-Host "Manifest:" -ForegroundColor Green
Write-Host "  $ManifestOut"
Write-Host "Ausentes:" -ForegroundColor Yellow
Write-Host "  $($ManifestOut -replace '\.txt$','_FALTANTES.txt')"
Write-Host "`nConcluído."
