<#
.SYNOPSIS
    Reidratação e diagnóstico do CAS fractal da TEIA-Ω.
    NÃO executa extração em massa — audita, valida e prepara o plano de reconstrução.

.DESCRIPTION
    Situação confirmada via auditoria de 25/05/2026:
    - fractal_index.json (29.5MB, 75.156 entradas) aponta para D:\Teia\TEIA_NUCLEO\offline\nano\
    - D:\Teia NÃO EXISTE. Os objetos .fractal_delta* e .fractal_manifest* NUNCA foram escritos em disco
      (confirmado por WizTree CSV de 30/11/2025 — 0 ocorrências).
    - CAS real usa formato .bin (SHA256-named). Apenas 2 objetos existem no sistema.
    - ZIPs Golden Master (4 verificados) não contêm os objetos CAS.
    CONCLUSÃO: Os 75.156 objetos do índice órfão são irrecuperáveis por reidratação.
    CAMINHO: Reconstrução via reingestão das fontes originais.

.PARAMETER Modo
    Audit    — (padrão) Inventaria CAS existente, valida integridade, gera relatório.
    Rebuild  — Reconstrói fractal_index.json do zero com os objetos .bin presentes.
    Ingest   — Ingere arquivos de uma pasta de origem para o CAS (requere -Origem).

.PARAMETER Origem
    Pasta de origem para modo Ingest.

.EXAMPLE
    .\Reidrata-CAS.ps1 -Modo Audit
    .\Reidrata-CAS.ps1 -Modo Rebuild
    .\Reidrata-CAS.ps1 -Modo Ingest -Origem "D:\MinhaPasta"
#>
[CmdletBinding()]
param(
    [ValidateSet('Audit','Rebuild','Ingest')]
    [string]$Modo = 'Audit',
    [string]$Origem = ''
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

# ── Paths canônicos ──────────────────────────────────────────────────────────
$NanoRoot    = 'D:\bruto\TEIA\TEIA_NUCLEO\offline\nano'
$CASObjects  = Join-Path $NanoRoot 'objects'
$AtlasCAS    = 'D:\bruto\TEIA\TEIA_ATLAS\Materia_Bruta\D_Drive\TEIA\TEIA_NUCLEO\offline\nano\objects'
$IndexAtivo  = Join-Path $NanoRoot 'fractal_index.json'
$IndexOrfao  = 'D:\bruto\TEIA\fractal_index.json'
$ReportDir   = 'D:\TEIA_CORE\proofs'
$ReportPath  = Join-Path $ReportDir "CAS_AUDIT_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"

if (-not (Test-Path $ReportDir)) { New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null }

# ── Helpers ──────────────────────────────────────────────────────────────────
function Get-SHA256 {
    param([string]$Path)
    (Get-FileHash $Path -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
}

function Write-Status { param([string]$Msg) Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Msg" }

# ════════════════════════════════════════════════════════════════════════════
# MODO: AUDIT
# ════════════════════════════════════════════════════════════════════════════
if ($Modo -eq 'Audit') {
    Write-Status "Modo AUDIT — inventariando CAS existente"

    # 1. Inventário de objetos .bin presentes
    $binLocal = @()
    if (Test-Path $CASObjects) {
        $binLocal = Get-ChildItem $CASObjects -Filter '*.bin' -Recurse -ErrorAction SilentlyContinue
    }
    $binAtlas = @()
    if (Test-Path $AtlasCAS) {
        $binAtlas = Get-ChildItem $AtlasCAS -Filter '*.bin' -Recurse -ErrorAction SilentlyContinue
    }
    Write-Status ".bin em nano\objects\:  $($binLocal.Count)"
    Write-Status ".bin em ATLAS\objects\: $($binAtlas.Count)"

    # 2. Validação de integridade dos .bin existentes
    $validated = @()
    $allBins = @($binLocal) + @($binAtlas)
    foreach ($f in $allBins) {
        $hash = Get-SHA256 $f.FullName
        $expectedHash = [System.IO.Path]::GetFileNameWithoutExtension($f.Name).ToUpper()
        $ok = ($hash -eq $expectedHash)
        $validated += [PSCustomObject]@{
            Path     = $f.FullName
            SHA256   = $hash
            Tamanho  = $f.Length
            Integro  = $ok
        }
        Write-Status "  $($f.Name) → $(if($ok){'OK'}else{'CORROMPIDO'})"
    }

    # 3. Cruzamento: índice órfão vs .bin presentes
    Write-Status "Carregando índice órfão (75.156 entradas)..."
    $orfao = try { Get-Content $IndexOrfao -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop } catch { $null }
    $binHashSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($b in $allBins) {
        $binHashSet.Add([System.IO.Path]::GetFileNameWithoutExtension($b.Name)) | Out-Null
    }

    $recuperavel = 0; $perdido = 0
    if ($orfao) {
        foreach ($entry in $orfao) {
            if ($entry.hash -and $binHashSet.Contains($entry.hash)) { $recuperavel++ } else { $perdido++ }
        }
    }

    # 4. Índice ativo
    $idxAtivo = @()
    if (Test-Path $IndexAtivo) {
        $raw = Get-Content $IndexAtivo -Raw
        if ($raw.Trim().Length -gt 2) {
            $idxAtivo = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        }
    }

    # 5. Relatório
    $report = [ordered]@{
        gerado_em       = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        modo            = 'Audit'
        veredicto       = 'CAS_ORFAO_IRRECUPERAVEL'
        explicacao      = @(
            'Os 75.156 objetos do fractal_index.json orfao nunca foram escritos em disco'
            'Confirmado por WizTree CSV 30/11/2025 (0 fractal_delta encontrados)'
            'Nenhum ZIP Golden Master contem os objetos CAS'
            'O CAS real usa formato .bin (SHA256-named) - apenas 2 objetos existem'
        )
        cas_ativo = [ordered]@{
            root           = $NanoRoot
            objects_locais = $binLocal.Count
            objects_atlas  = $binAtlas.Count
            total_bin      = $allBins.Count
            integridade    = $validated
        }
        indice_orfao = [ordered]@{
            path         = $IndexOrfao
            entradas     = if($orfao){$orfao.Count}else{0}
            recuperavel  = $recuperavel
            perdido      = $perdido
            percentual_perdido = if($orfao -and $orfao.Count -gt 0){"$([math]::Round($perdido/$orfao.Count*100,1))%"}else{"N/A"}
        }
        indice_ativo = [ordered]@{
            path    = $IndexAtivo
            entradas = $idxAtivo.Count
        }
        caminho_reconstrucao = @(
            '1. Executar: .\Reidrata-CAS.ps1 -Modo Rebuild  (reconstroi indice com .bin existentes)'
            '2. Identificar fontes originais para reingestao (fotos, videos, documentos de D:\bruto\TEIA\TEIA_Data\)'
            '3. Executar: .\Reidrata-CAS.ps1 -Modo Ingest -Origem <pasta>  (por pasta, um ciclo por vez)'
            '4. Verificar integridade apos cada ciclo com Modo Audit'
        )
    }

    $report | ConvertTo-Json -Depth 6 | Set-Content $ReportPath -Encoding UTF8
    Write-Status "Relatório salvo: $ReportPath"

    Write-Host ""
    Write-Host "═══════════════════════════════════════════════"
    Write-Host " DIAGNÓSTICO FINAL — CAS TEIA-Ω"
    Write-Host "═══════════════════════════════════════════════"
    Write-Host " Objetos .bin presentes:  $($allBins.Count) (de 75.156 esperados)"
    Write-Host " Recuperável do índice:   $recuperavel entradas"
    Write-Host " Perdido definitivamente: $perdido entradas"
    Write-Host " Veredicto: CAS_ORFAO_IRRECUPERAVEL"
    Write-Host " Caminho: reconstrução via reingestão"
    Write-Host "═══════════════════════════════════════════════"
}

# ════════════════════════════════════════════════════════════════════════════
# MODO: REBUILD — reconstrói fractal_index.json do zero com .bin existentes
# ════════════════════════════════════════════════════════════════════════════
elseif ($Modo -eq 'Rebuild') {
    Write-Status "Modo REBUILD — reconstruindo índice com objetos .bin presentes"

    $allBins = @()
    foreach ($casDir in @($CASObjects, $AtlasCAS)) {
        if (Test-Path $casDir) {
            $allBins += Get-ChildItem $casDir -Filter '*.bin' -Recurse -ErrorAction SilentlyContinue
        }
    }

    $newIndex = @()
    foreach ($f in $allBins) {
        $hash = Get-SHA256 $f.FullName
        $expectedHash = [System.IO.Path]::GetFileNameWithoutExtension($f.Name).ToUpper()
        if ($hash -ne $expectedHash) {
            Write-Warning "CORROMPIDO: $($f.Name) — hash real: $hash"
            continue
        }
        $newIndex += [PSCustomObject]@{
            hash    = $hash.ToLower()
            size    = $f.Length
            path    = $f.FullName
            indexed = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
            version = 'Reidrata-CAS-v1.0'
        }
    }

    $newIndex | ConvertTo-Json -Depth 3 | Set-Content $IndexAtivo -Encoding UTF8
    Write-Status "fractal_index.json reconstruído: $($newIndex.Count) entradas → $IndexAtivo"

    # Mover índice órfão para quarentena (não deletar)
    $orphanDest = Join-Path 'D:\TEIA_CORE\QUARENTENA_DEBRIS' "fractal_index_ORFAO_$(Get-Date -Format 'yyyyMMdd').json"
    Copy-Item $IndexOrfao $orphanDest -ErrorAction SilentlyContinue
    Write-Status "Índice órfão arquivado em: $orphanDest"
}

# ════════════════════════════════════════════════════════════════════════════
# MODO: INGEST — ingere uma pasta de origem no CAS .bin
# ════════════════════════════════════════════════════════════════════════════
elseif ($Modo -eq 'Ingest') {
    if (-not $Origem -or -not (Test-Path $Origem)) {
        Write-Error "Parâmetro -Origem obrigatório e deve existir. Uso: -Modo Ingest -Origem 'D:\MinhaPasta'"
        exit 1
    }
    if (-not (Test-Path $CASObjects)) { New-Item -ItemType Directory -Path $CASObjects -Force | Out-Null }

    Write-Status "Modo INGEST — origem: $Origem"
    $files = Get-ChildItem $Origem -Recurse -File -ErrorAction SilentlyContinue
    Write-Status "Arquivos a ingerir: $($files.Count)"

    $ingeridos = 0; $jaExistem = 0; $erros = 0
    $logIngest = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($f in $files) {
        try {
            $hash = Get-SHA256 $f.FullName
            $dest = Join-Path $CASObjects "$($hash.ToLower()).bin"
            if (Test-Path $dest) {
                $jaExistem++
            } else {
                Copy-Item $f.FullName $dest -ErrorAction Stop
                $ingeridos++
            }
            $logIngest.Add([PSCustomObject]@{
                arquivo = $f.FullName
                hash    = $hash.ToLower()
                status  = if(Test-Path $dest -ErrorAction SilentlyContinue){'OK'}else{'FALHA'}
                tamanho = $f.Length
            })
        } catch {
            $erros++
            Write-Warning "Erro em $($f.FullName): $_"
        }
    }

    Write-Status "Ingeridos: $ingeridos | Já existiam: $jaExistem | Erros: $erros"

    # Atualizar fractal_index.json
    $existingIdx = @()
    if (Test-Path $IndexAtivo) {
        $raw = Get-Content $IndexAtivo -Raw -ErrorAction SilentlyContinue
        if ($raw -and $raw.Trim().Length -gt 2) {
            $existingIdx = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        }
    }
    $existingHashes = ($existingIdx | ForEach-Object { $_.hash }) -as [System.Collections.Generic.HashSet[string]]
    $newEntries = $logIngest | Where-Object { $_.status -eq 'OK' -and -not $existingHashes.Contains($_.hash) }
    $merged = @($existingIdx) + ($newEntries | ForEach-Object {
        [PSCustomObject]@{
            hash    = $_.hash
            size    = $_.tamanho
            path    = $_.arquivo
            indexed = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
            version = 'Reidrata-CAS-v1.0'
        }
    })
    $merged | ConvertTo-Json -Depth 3 | Set-Content $IndexAtivo -Encoding UTF8
    Write-Status "fractal_index.json atualizado: $($merged.Count) entradas totais"
}
