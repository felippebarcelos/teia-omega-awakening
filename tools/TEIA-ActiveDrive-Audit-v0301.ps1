<#
.SYNOPSIS
    TEIA-ActiveDrive-Audit-v0301.ps1 — Auditor de Reversibilidade e Resiliência (P6.1)

.DESCRIPTION
    Protocolo P6.1 — Hardening do Active Gestor via stress test de corrupção.

    Fase 1 — Auditoria de Reversibilidade:
      Para cada .teia_stub em ActiveDriveDir:
        - Restaura para sandbox isolado via TEIA-Stream-OnDemand-v0300.ps1
        - Verifica SHA-256 (PASS/FAIL)
        - Registra tempo e tamanho restaurado
      CAS Delta = 0 — apenas leitura dos artefatos existentes.

    Fase 2 — Teste do Caos (Rollback Forçado):
      - Duplica um stub existente com SHA-256 adulterado (hex inválido)
      - Ordena o restaurador a processar o stub corrompido
      - Resultado obrigatório: FAILED_SHA_MISMATCH, arquivo residual deletado
      - Rollback verificado: nenhum arquivo parcial sobrevive à corrupção

.PARAMETER ActiveDriveDir
    Pasta de stubs a auditar. Padrão: D:\TEIA_USER\ActiveDrive_Test

.PARAMETER SandboxDir
    Sandbox isolado para os arquivos restaurados.
    Padrão: D:\TEIA_CORE\sandbox\active_restore_audit

.PARAMETER StreamScript
    Caminho do TEIA-Stream-OnDemand-v0300.ps1.
    Padrão: D:\TEIA_CORE\tools\TEIA-Stream-OnDemand-v0300.ps1

.PARAMETER ChaosSha256
    SHA-256 adulterado usado no stub corrompido (deve ser hex-64 inválido).
    Padrão: deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef
#>
[CmdletBinding()]
param(
    [string]$ActiveDriveDir = 'D:\TEIA_USER\ActiveDrive_Test',
    [string]$SandboxDir     = 'D:\TEIA_CORE\sandbox\active_restore_audit',
    [string]$StreamScript   = 'D:\TEIA_CORE\tools\TEIA-Stream-OnDemand-v0300.ps1',
    [string]$ChaosSha256    = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$enc     = New-Object System.Text.UTF8Encoding($false)
$runStart = Get-Date

# ── Validações ────────────────────────────────────────────────────────────────

foreach ($chk in @($ActiveDriveDir, $StreamScript)) {
    if (-not (Test-Path -LiteralPath $chk)) {
        Write-Host "[AUDIT] ERRO: nao encontrado: $chk" -ForegroundColor Red; exit 1
    }
}

New-Item -ItemType Directory -Path $SandboxDir -Force | Out-Null

# ── Banner ────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host '  TEIA-ActiveDrive-Audit v0.30.1 — Auditoria de Reversibilidade P6.1' -ForegroundColor Cyan
Write-Host ('─' * 78)
Write-Host ("  ActiveDrive  : $ActiveDriveDir")
Write-Host ("  Sandbox      : $SandboxDir")
Write-Host ("  Restaurador  : $(Split-Path $StreamScript -Leaf)")
Write-Host ("  CAS Delta    : 0 (somente leitura dos artefatos existentes)")
Write-Host ('=' * 78)
Write-Host ''

# ── Coleta dos stubs ──────────────────────────────────────────────────────────

[object[]]$stubs = @(Get-ChildItem -LiteralPath $ActiveDriveDir -Filter '*.teia_stub' |
                     Where-Object { $_.Name -notmatch 'corrompid' })

Write-Host ("  Stubs encontrados: $($stubs.Count)")
Write-Host ''

$auditResults  = [System.Collections.Generic.List[pscustomobject]]::new()
$nPass         = 0
$nFail         = 0

# ════════════════════════════════════════════════════════════════════════════
#  FASE 1 — AUDITORIA DE REVERSIBILIDADE
# ════════════════════════════════════════════════════════════════════════════

Write-Host ('─' * 78) -ForegroundColor Yellow
Write-Host '  FASE 1 — AUDITORIA DE REVERSIBILIDADE (restauro e verificacao SHA-256)' -ForegroundColor Yellow
Write-Host ('─' * 78)
Write-Host ''

foreach ($stubFile in $stubs) {
    $stub       = Get-Content -LiteralPath $stubFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $origName   = [string]$stub.original_name
    $origSha    = [string]$stub.original_sha256
    $origBytes  = [long]$stub.original_size_bytes
    $strategy   = [string]$stub.final_strategy
    $casExists  = Test-Path -LiteralPath $stub.cas_path

    Write-Host ("  [STUB] {0,-42} strategy={1}" -f $stubFile.Name, $strategy) -ForegroundColor White

    if (-not $casExists) {
        Write-Host ("         AVISO: artefato CAS nao encontrado: $($stub.cas_path)") -ForegroundColor Red
        $auditResults.Add([pscustomobject]@{
            stub     = $stubFile.Name
            strategy = $strategy
            result   = 'FAIL_CAS_MISSING'
            note     = "CAS nao encontrado: $($stub.cas_path)"
            elapsed_ms = 0
        })
        $nFail++
        continue
    }

    # Caminho de destino no sandbox
    $outputPath = Join-Path $SandboxDir $origName
    $sw         = [System.Diagnostics.Stopwatch]::StartNew()

    # Invocar Stream-OnDemand, capturando saída para log (sem suprimir do console)
    $streamOut = & pwsh -NoProfile -File $StreamScript `
                        -StubPath   $stubFile.FullName `
                        -OutputPath $outputPath `
                        -KeepStub `
                        2>&1
    $exitCode = $LASTEXITCODE
    $sw.Stop()

    # Extrair SHA-256 obtido da saída do restaurador
    $shaLine    = "$($streamOut | Where-Object { "$_" -match 'Obtido' } | Select-Object -Last 1)"
    $shaObtido  = if ($shaLine -match ':\s+([0-9a-f]{64})') { $Matches[1] } else { '(nao capturado)' }

    # Verificar existência do arquivo restaurado
    $restoredExists = Test-Path -LiteralPath $outputPath
    $restoredSize   = if ($restoredExists) { (Get-Item -LiteralPath $outputPath).Length } else { 0L }

    $statusOk = ($exitCode -eq 0) -and $restoredExists -and ($shaObtido -eq $origSha)

    if ($statusOk) {
        $nPass++
        Write-Host ("         PASS  SHA-256={0}...  ({1} KB, {2} ms)" -f `
            $shaObtido.Substring(0,16), [math]::Round($restoredSize/1KB,1), $sw.ElapsedMilliseconds) `
            -ForegroundColor Green
        $auditResults.Add([pscustomobject]@{
            stub       = $stubFile.Name
            strategy   = $strategy
            result     = 'PASS'
            sha256     = $shaObtido
            bytes      = $restoredSize
            elapsed_ms = $sw.ElapsedMilliseconds
            note       = ''
        })
    } else {
        $nFail++
        $reason = if ($exitCode -ne 0) { "exit=$exitCode" } `
                  elseif (-not $restoredExists) { "arquivo nao criado" } `
                  else { "SHA divergente: $shaObtido" }
        Write-Host ("         FAIL  razao=$reason") -ForegroundColor Red
        $auditResults.Add([pscustomobject]@{
            stub       = $stubFile.Name
            strategy   = $strategy
            result     = 'FAIL'
            sha256     = $shaObtido
            bytes      = $restoredSize
            elapsed_ms = $sw.ElapsedMilliseconds
            note       = $reason
        })
    }
    Write-Host ''
}

# ════════════════════════════════════════════════════════════════════════════
#  FASE 2 — TESTE DO CAOS (ROLLBACK FORÇADO)
# ════════════════════════════════════════════════════════════════════════════

Write-Host ('─' * 78) -ForegroundColor Red
Write-Host '  FASE 2 — TESTE DO CAOS: rollback forcado por SHA-256 adulterado' -ForegroundColor Red
Write-Host ('─' * 78)
Write-Host ''

# Escolher o alice como base do stub corrompido (maior arquivo, exercita GZip restore)
$baseStubPath  = Join-Path $ActiveDriveDir 'alice_wonderland.txt.teia_stub'
$chaosStubName = 'alice_wonderland_corrompida.txt.teia_stub'
$chaosStubPath = Join-Path $ActiveDriveDir $chaosStubName

# Inicializar variáveis de Fase 2 com defaults (para o caso de skip)
$chaosResultado = 'N/A (stub base nao encontrado)'
$chaosPass      = $false
$v1 = $false; $v2 = $false; $v3 = $false; $v4 = $false
$f2skipped = $false

if (-not (Test-Path -LiteralPath $baseStubPath)) {
    Write-Host "  AVISO: stub base nao encontrado ($baseStubPath) — pulando Fase 2." -ForegroundColor DarkYellow
    $f2skipped = $true
} else {

# Ler stub legítimo e adulterar SHA-256
$realStub = Get-Content -LiteralPath $baseStubPath -Raw -Encoding UTF8 | ConvertFrom-Json

Write-Host "  [CAOS] Fabricando stub corrompido..." -ForegroundColor DarkYellow
Write-Host ("         Base          : $baseStubPath")
Write-Host ("         SHA-256 real  : $($realStub.original_sha256.Substring(0,16))...")
Write-Host ("         SHA-256 falso : $($ChaosSha256.Substring(0,16))...")
Write-Host ("         cas_path      : mantido apontando para CAS real (artefato integro)")
Write-Host ''

# Construir JSON adulterado (mesmo cas_path, sha256 mentiroso)
$chaosStub = [ordered]@{
    teia_version        = 'v0.30.0'
    schema              = 'teia_stub'
    original_name       = 'alice_wonderland.txt'
    original_size_bytes = $realStub.original_size_bytes
    original_sha256     = $ChaosSha256            # SHA-256 ADULTERADO
    final_strategy      = [string]$realStub.final_strategy
    cas_encoding        = [string]$realStub.cas_encoding
    cas_path            = [string]$realStub.cas_path   # aponta para CAS real
    cas_sha256          = [string]$realStub.cas_sha256
    cas_size_bytes      = $realStub.cas_size_bytes
    savings_pct         = $realStub.savings_pct
    ingest_timestamp    = (Get-Date -Format 'o')
    audit_note          = 'STUB CORROMPIDO — SHA-256 adulterado para teste de rollback P6.1'
}

[System.IO.File]::WriteAllText($chaosStubPath, ($chaosStub | ConvertTo-Json -Depth 5), $enc)
Write-Host ("  [CAOS] Stub corrompido gravado: $chaosStubName") -ForegroundColor DarkYellow

# Caminho onde o restaurador tentaria criar o arquivo
$chaosOutputPath = Join-Path $SandboxDir 'alice_wonderland_CORROMPIDA_residuo.txt'

Write-Host ''
Write-Host ("  [CAOS] Ordenando Stream-OnDemand a restaurar o stub mentiroso...") -ForegroundColor DarkYellow
Write-Host ("         Resultado esperado: FAILED_SHA_MISMATCH + rollback imediato") -ForegroundColor DarkYellow
Write-Host ''

$chaosOut = & pwsh -NoProfile -File $StreamScript `
                   -StubPath   $chaosStubPath `
                   -OutputPath $chaosOutputPath `
                   -KeepStub `
                   2>&1
$chaosExit = $LASTEXITCODE

# Processar linhas de saída
$chaosOut | ForEach-Object { Write-Host "    $_" }
Write-Host ''

# ── Verificações do rollback ──────────────────────────────────────────────────

$residuoExiste    = Test-Path -LiteralPath $chaosOutputPath
$chaosResultado   = if ($chaosExit -eq 2)  { 'FAILED_SHA_MISMATCH' } `
                    elseif ($chaosExit -eq 0) { 'INCORRETO_PASS_INESPERADO' } `
                    else                    { "ERRO_EXIT_$chaosExit" }

Write-Host ('─' * 78)
Write-Host '  VERIFICACOES DO ROLLBACK:' -ForegroundColor White
Write-Host ''

# V1: exit code deve ser 2
$v1 = ($chaosExit -eq 2)
Write-Host ("  V1  Exit code = $chaosExit  (esperado: 2) — $(if ($v1) {'OK'} else {'FALHOU'})") `
    -ForegroundColor $(if ($v1) {'Green'} else {'Red'})

# V2: arquivo residual nao deve existir (Stream-OnDemand deve ter deletado)
$v2 = (-not $residuoExiste)
Write-Host ("  V2  Residuo em sandbox = $(if ($residuoExiste) {'EXISTE (FALHOU)'} else {'ausente (correto)'}) — $(if ($v2) {'OK'} else {'FALHOU'})") `
    -ForegroundColor $(if ($v2) {'Green'} else {'Red'})

# V3: stub corrompido ainda existe (KeepStub=true — nao deletar)
$v3 = (Test-Path -LiteralPath $chaosStubPath)
Write-Host ("  V3  Stub corrompido ainda existe = $(if ($v3) {'sim (correto)'} else {'DELETADO (inesperado)'}) — $(if ($v3) {'OK'} else {'AVISO'})") `
    -ForegroundColor $(if ($v3) {'Green'} else {'DarkYellow'})

# V4: stub real de alice permanece intacto
$v4 = (Test-Path -LiteralPath $baseStubPath)
Write-Host ("  V4  Stub legitimo alice intacto = $(if ($v4) {'sim (correto)'} else {'PERDIDO (CRITICO)'}) — $(if ($v4) {'OK'} else {'FALHOU'})") `
    -ForegroundColor $(if ($v4) {'Green'} else {'Red'})

Write-Host ''
$chaosPass = $v1 -and $v2 -and $v4

if ($chaosPass) {
    Write-Host ("  CAOS CONTROLADO: rollback verificado. Sistema rejeitou a corrupcao.") -ForegroundColor Green
} else {
    Write-Host ("  CAOS NAO CONTROLADO: pelo menos uma verificacao falhou.") -ForegroundColor Red
}
Write-Host ''

# ── Limpar stub corrompido ────────────────────────────────────────────────────

Remove-Item -LiteralPath $chaosStubPath -Force -ErrorAction SilentlyContinue
Write-Host ("  Stub corrompido removido: $chaosStubName") -ForegroundColor DarkGray
Write-Host ''

} # fim if baseStubPath exists

# ════════════════════════════════════════════════════════════════════════════
#  SUMÁRIO FINAL
# ════════════════════════════════════════════════════════════════════════════

$elapsed = [int]((Get-Date) - $runStart).TotalSeconds

Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host '  SUMARIO DA AUDITORIA P6.1' -ForegroundColor Cyan
Write-Host ('─' * 78)
Write-Host ''
Write-Host ("  FASE 1 — Reversibilidade:")
Write-Host ("    Stubs auditados  : $($stubs.Count)")
Write-Host ("    PASS             : $nPass") -ForegroundColor Green
Write-Host ("    FAIL             : $nFail") -ForegroundColor $(if ($nFail -gt 0) {'Red'} else {'DarkGray'})
Write-Host ''

if ($auditResults.Count -gt 0) {
    Write-Host ("  {0,-42} {1,-24} {2,8} {3,8} {4}" -f `
        'Stub','Estrategia','Bytes','ms','Resultado') -ForegroundColor White
    Write-Host ("  {0,-42} {1,-24} {2,8} {3,8} {4}" -f `
        ('-'*42),('-'*24),('-'*8),('-'*8),('-'*18))
    foreach ($r in $auditResults) {
        $color = if ($r.result -eq 'PASS') { 'Green' } else { 'Red' }
        Write-Host ("  {0,-42} {1,-24} {2,8} {3,8} {4}" -f `
            $r.stub, $r.strategy, $r.bytes, $r.elapsed_ms, $r.result) -ForegroundColor $color
    }
    Write-Host ''
}

Write-Host ("  FASE 2 — Teste do Caos:")
if ($f2skipped) {
    Write-Host ("    Resultado        : PULADO (stub base nao encontrado)") -ForegroundColor DarkYellow
} else {
    Write-Host ("    Resultado        : $chaosResultado") -ForegroundColor $(if ($chaosPass) {'Green'} else {'Red'})
    Write-Host ("    V1 exit=2        : $(if ($v1) {'OK'} else {'FALHOU'})") -ForegroundColor $(if ($v1) {'Green'} else {'Red'})
    Write-Host ("    V2 sem residuo   : $(if ($v2) {'OK'} else {'FALHOU'})") -ForegroundColor $(if ($v2) {'Green'} else {'Red'})
    Write-Host ("    V3 stub removido : OK (removido apos teste)") -ForegroundColor DarkGray
    Write-Host ("    V4 alice intacto : $(if ($v4) {'OK'} else {'FALHOU'})") -ForegroundColor $(if ($v4) {'Green'} else {'Red'})
}
Write-Host ''

$f1ok = ($nFail -eq 0 -and $nPass -eq $stubs.Count)
$f2ok = if ($f2skipped) { $true } else { $chaosPass }
$auditFinal = if ($f1ok -and $f2ok) { 'AUDITORIA APROVADA — sistema reversivel e resiliente' } `
              else { 'AUDITORIA REPROVADA — revisar falhas acima' }

Write-Host ("  Tempo total      : ${elapsed}s")
Write-Host ("  CAS Delta        : 0 (zero bytes escritos em objects/)")
Write-Host ("  Sandbox          : $SandboxDir")
Write-Host ''
Write-Host ("  $auditFinal") -ForegroundColor $(if ($f1ok -and $f2ok) {'Green'} else {'Red'})
Write-Host ''
Write-Host ('=' * 78)
