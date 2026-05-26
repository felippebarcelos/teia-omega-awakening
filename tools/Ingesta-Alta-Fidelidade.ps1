<#
.SYNOPSIS
    Reingestão de alta fidelidade v0.12.0 — Sintropia Controlada.
    Ingere apenas arquivos com SHA-256 confirmado contra o índice CAS órfão.

.DESCRIPTION
    Operação idempotente e não-destrutiva:
    - Fontes NÃO são deletadas ou movidas.
    - Destino: D:\TEIA_CORE\objects\{sha256}.bin
    - Log: D:\TEIA_CORE\dna_events.jsonl (NDJSON, append-safe)
    - Índice: D:\TEIA_CORE\manifests\fractal_index.json
    - Relatório: D:\TEIA_CORE\docs\SINTROPIA_INGEST_REPORT.md

.PARAMETER Origens
    Array de pastas a escanear. Padrão: TEIA_Data + Analisados + raiz bruto.

.PARAMETER DryRun
    Simula sem copiar nada. Imprime o que seria feito.

.EXAMPLE
    .\Ingesta-Alta-Fidelidade.ps1
    .\Ingesta-Alta-Fidelidade.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [string[]]$Origens = @(
        'D:\bruto\TEIA\TEIA_Data',
        'D:\bruto\TEIA\TEIA_ATLAS',
        'D:\bruto\TEIA\Analisados'
    ),
    [switch]$DryRun
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'

# ── Paths canônicos ──────────────────────────────────────────────────────────
$CASRoot     = 'D:\TEIA_CORE\objects'
$IndexOrfao  = 'D:\bruto\TEIA\fractal_index.json'
$IndexNovo   = 'D:\TEIA_CORE\manifests\fractal_index.json'
$EventLog    = 'D:\TEIA_CORE\dna_events.jsonl'
$ReportPath  = 'D:\TEIA_CORE\docs\SINTROPIA_INGEST_REPORT.md'
$ProofDir    = 'D:\TEIA_CORE\proofs'
$RunId       = "v0.12.0_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$t0          = Get-Date

foreach ($d in @($CASRoot, (Split-Path $IndexNovo), $ProofDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# ── Logger NDJSON ────────────────────────────────────────────────────────────
function Write-Event {
    param([string]$Act, [hashtable]$Data)
    $line = ([ordered]@{
        ts    = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffzzz')
        run   = $RunId
        act   = $Act
        data  = $Data
    } | ConvertTo-Json -Compress -Depth 4)
    if (-not $DryRun) { Add-Content -LiteralPath $EventLog -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue }
    Write-Verbose "EVENT: $line"
}

function Write-Status { param([string]$Msg) Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Msg" }

# ════════════════════════════════════════════════════════════════════════════
# FASE 1 — Carregar índice órfão e construir lookup por hash
# ════════════════════════════════════════════════════════════════════════════
Write-Status "FASE 1 — Carregando índice órfão..."
Write-Event 'RUN_START' @{ run_id = $RunId; dry_run = $DryRun.IsPresent; origens = $Origens -join '|' }

$orphan = Get-Content $IndexOrfao -Raw | ConvertFrom-Json
Write-Status "  $($orphan.Count) entradas no índice órfão"

$hashLookup = [System.Collections.Generic.Dictionary[string,PSCustomObject]]::new([System.StringComparer]::OrdinalIgnoreCase)
$sizeLookup  = [System.Collections.Generic.Dictionary[long,bool]]::new()

foreach ($e in $orphan) {
    if (-not $e.hash) { continue }
    $hashLookup[$e.hash] = $e
    $sz = if($null -ne $e.size){[long]$e.size}else{-1L}
    $sizeLookup[$sz] = $true
}
Write-Status "  $($hashLookup.Count) hashes únicos | $($sizeLookup.Count) tamanhos únicos no lookup"

# ════════════════════════════════════════════════════════════════════════════
# FASE 2 — Scan seletivo das fontes + SHA-256 com pré-filtro de tamanho
# ════════════════════════════════════════════════════════════════════════════
Write-Status "FASE 2 — Escaneando fontes..."

$cachePattern = 'Miniconda|OllamaModels|__pycache__|\.git\\|Lixo_Entropico'
$confirmados  = [System.Collections.Generic.List[PSCustomObject]]::new()
$totalScanned = 0

foreach ($origem in $Origens) {
    if (-not (Test-Path $origem)) {
        Write-Status "  [SKIP] $origem — não existe"
        continue
    }
    $files = Get-ChildItem $origem -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch $cachePattern }
    Write-Status "  $origem — $($files.Count) arquivos"

    $i = 0
    foreach ($f in $files) {
        $i++; $totalScanned++
        if ($i % 1000 -eq 0) { Write-Status "    ... $i/$($files.Count)" }

        # Pré-filtro por tamanho — evita SHA256 desnecessário
        if (-not $sizeLookup.ContainsKey($f.Length)) { continue }

        try {
            $hash = (Get-FileHash $f.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
            if ($hashLookup.ContainsKey($hash)) {
                $entry = $hashLookup[$hash]
                $confirmados.Add([PSCustomObject]@{
                    Hash         = $hash
                    ArquivoLocal = $f.FullName
                    Tamanho      = $f.Length
                    NomeOriginal = $entry.file
                    CriadoOrig   = $entry.created
                    PathOrfao    = $entry.path
                    Seed         = $entry.seed
                })
            }
        } catch { Write-Verbose "Erro hash: $($f.FullName) — $_" }
    }
}

Write-Status "  Total escaneado: $totalScanned arquivos"
Write-Status "  CONFIRMADOS POR HASH: $($confirmados.Count)"
Write-Event 'SCAN_DONE' @{ total_scanned = $totalScanned; confirmados = $confirmados.Count }

# ════════════════════════════════════════════════════════════════════════════
# FASE 3 — Reingestão idempotente para D:\TEIA_CORE\objects\
# ════════════════════════════════════════════════════════════════════════════
Write-Status "FASE 3 — Reingestão$(if($DryRun){' [DRY-RUN]'}) para $CASRoot..."

$ok      = 0
$jaExist = 0
$falhas  = [System.Collections.Generic.List[PSCustomObject]]::new()
$loteHashes = [System.Text.StringBuilder]::new()  # para hash de lote

foreach ($c in $confirmados) {
    $dest = Join-Path $CASRoot "$($c.Hash.ToLower()).bin"

    # Idempotência: se já existe E hash bate, pular
    if (Test-Path $dest) {
        $existHash = (Get-FileHash $dest -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        if ($existHash -and $existHash -ieq $c.Hash) {
            $jaExist++
            [void]$loteHashes.Append($c.Hash)
            continue
        }
        # Existe mas hash difere — arquivo corrompido no CAS, recopiar
        Write-Warning "CAS corrompido detectado: $dest — recopiando"
    }

    if (-not $DryRun) {
        try {
            Copy-Item -LiteralPath $c.ArquivoLocal -Destination $dest -Force -ErrorAction Stop
            # Verificação pós-cópia
            $verifHash = (Get-FileHash $dest -Algorithm SHA256 -ErrorAction Stop).Hash
            if ($verifHash -ine $c.Hash) {
                throw "Hash pós-cópia diverge: esperado=$($c.Hash) obtido=$verifHash"
            }
            $ok++
            [void]$loteHashes.Append($c.Hash)
            Write-Event 'INGEST_OK' @{
                sha256   = $c.Hash
                origem   = $c.ArquivoLocal
                destino  = $dest
                tamanho  = $c.Tamanho
                nome_orig = $c.NomeOriginal
            }
        } catch {
            $falhas.Add([PSCustomObject]@{ Arquivo = $c.ArquivoLocal; Erro = $_.ToString() })
            Write-Event 'INGEST_FAIL' @{ sha256 = $c.Hash; origem = $c.ArquivoLocal; erro = $_.ToString() }
            Write-Warning "FALHA: $($c.ArquivoLocal) — $_"
        }
    } else {
        Write-Host "  [DRY] COPIARIA: $($c.ArquivoLocal -replace 'D:\\bruto\\TEIA\\','') → $($c.Hash.Substring(0,16)).bin"
        $ok++
    }
}

Write-Status "  Ingeridos com sucesso: $ok"
Write-Status "  Já existiam (idempotente): $jaExist"
Write-Status "  Falhas: $($falhas.Count)"

# ════════════════════════════════════════════════════════════════════════════
# FASE 4 — SHA-256 do lote (hash dos hashes — prova de integridade do batch)
# ════════════════════════════════════════════════════════════════════════════
$loteStr  = $loteHashes.ToString()
$loteBytes = [System.Text.Encoding]::UTF8.GetBytes($loteStr)
$sha256   = [System.Security.Cryptography.SHA256]::Create()
$loteHash = [BitConverter]::ToString($sha256.ComputeHash($loteBytes)).Replace('-','').ToLower()
$sha256.Dispose()
Write-Status "  SHA-256 do lote: $loteHash"

# ════════════════════════════════════════════════════════════════════════════
# FASE 5 — Validação pós-ingestão (Audit inline)
# ════════════════════════════════════════════════════════════════════════════
Write-Status "FASE 5 — Validação pós-ingestão..."
$binFiles = Get-ChildItem $CASRoot -Filter "*.bin" -ErrorAction SilentlyContinue
$auditOk = 0; $auditFail = 0
foreach ($b in $binFiles) {
    $expectedHash = [System.IO.Path]::GetFileNameWithoutExtension($b.Name).ToUpper()
    $actualHash   = (Get-FileHash $b.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
    if ($actualHash -and $actualHash -eq $expectedHash) { $auditOk++ } else { $auditFail++ }
}
Write-Status "  CAS audit: $auditOk OK | $auditFail CORROMPIDOS"
Write-Event 'AUDIT_DONE' @{ total_bin = $binFiles.Count; ok = $auditOk; corrompidos = $auditFail }

# ════════════════════════════════════════════════════════════════════════════
# FASE 6 — Novo fractal_index.json (apenas objetos fisicamente presentes)
# ════════════════════════════════════════════════════════════════════════════
Write-Status "FASE 6 — Gerando fractal_index.json canônico..."

$novoIndex = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($c in $confirmados) {
    $dest = Join-Path $CASRoot "$($c.Hash.ToLower()).bin"
    if (-not (Test-Path $dest)) { continue }
    $novoIndex.Add([PSCustomObject]@{
        hash          = $c.Hash.ToLower()
        size          = $c.Tamanho
        nome_original = $c.NomeOriginal
        path_cas      = $dest
        path_origem   = $c.ArquivoLocal
        created_orig  = $c.CriadoOrig
        seed          = $c.Seed
        indexed_at    = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
        version       = 'v0.12.0'
    })
}

if (-not $DryRun) {
    $novoIndex | ConvertTo-Json -Depth 4 | Set-Content $IndexNovo -Encoding UTF8
}
Write-Status "  fractal_index.json: $($novoIndex.Count) entradas → $IndexNovo"

# ════════════════════════════════════════════════════════════════════════════
# FASE 7 — SINTROPIA_INGEST_REPORT.md
# ════════════════════════════════════════════════════════════════════════════
Write-Status "FASE 7 — Gerando relatório de sintropia..."
$elapsed = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)
$totalBytes = ($confirmados | Measure-Object Tamanho -Sum).Sum
$byOrigem = $confirmados | Group-Object { ($_.ArquivoLocal -replace 'D:\\bruto\\TEIA\\','' -split '\\')[0] } | Sort-Object Count -Descending
$byExt    = $confirmados | Group-Object { [System.IO.Path]::GetExtension($_.NomeOriginal).ToLower() } | Sort-Object Count -Descending | Select-Object -First 12

$report = @"
# SINTROPIA_INGEST_REPORT.md — v0.12.0
> Run ID: ``$RunId`` | Modo: $(if($DryRun){'DRY-RUN'}else{'EXECUÇÃO REAL'})
> Gerado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Duração: ${elapsed}s

---

## RESULTADO DA REINGESTÃO

| Métrica | Valor |
|---------|-------|
| Arquivos confirmados por SHA-256 | $($confirmados.Count) |
| Ingeridos com sucesso (novos) | $ok |
| Já existiam no CAS (idempotente) | $jaExist |
| Falhas | $($falhas.Count) |
| Total no CAS após ingestão | $($binFiles.Count) objetos |
| Volume total ingerido | $([math]::Round($totalBytes/1MB,1)) MB |
| Duração total | ${elapsed}s |

### Integridade do Lote

| Item | Valor |
|------|-------|
| SHA-256 do lote (hash-dos-hashes) | ``$loteHash`` |
| Objetos CAS auditados | $($binFiles.Count) |
| Íntegros | $auditOk |
| Corrompidos | $auditFail |

> Método: SHA-256(concatenação de todos os hashes ingeridos em ordem de processamento)

---

## DISTRIBUIÇÃO POR ORIGEM

| Diretório de Origem | Arquivos |
|---------------------|---------|
"@
foreach ($g in $byOrigem) {
    $report += "`n| ``$($g.Name)`` | $($g.Count) |"
}

$report += @"


---

## DISTRIBUIÇÃO POR TIPO DE ARQUIVO

| Extensão | Quantidade |
|----------|-----------|
"@
foreach ($g in $byExt) {
    $ext = if($g.Name){"``$($g.Name)``"}else{'(sem extensão)'}
    $report += "`n| $ext | $($g.Count) |"
}

$report += @"


---

## FALHAS$(if($falhas.Count -eq 0){" — NENHUMA ✓"})

"@
if ($falhas.Count -gt 0) {
    $report += "| Arquivo | Erro |`n|---------|------|`n"
    foreach ($fl in $falhas) {
        $report += "| ``$($fl.Arquivo -replace 'D:\\bruto\\TEIA\\','')`` | $($fl.Erro.Substring(0, [Math]::Min(80,$fl.Erro.Length))) |`n"
    }
} else {
    $report += "_Sem falhas registradas._`n"
}

$report += @"

---

## NOVO ÍNDICE CAS

| Item | Valor |
|------|-------|
| Localização | ``$IndexNovo`` |
| Entradas | $($novoIndex.Count) |
| Formato | hash / size / nome_original / path_cas / path_origem / seed / version |
| Versão | v0.12.0 |

---

## PROVA DE INTEGRIDADE

| Artefato | SHA-256 (32 chars) |
|----------|-------------------|
"@
foreach ($p in @($IndexNovo, $EventLog)) {
    if (Test-Path $p) {
        $h = (Get-FileHash $p -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        $report += "`n| ``$(Split-Path $p -Leaf)`` | ``$($h.Substring(0,32))...`` |"
    }
}

$report += @"


---

## FONTES ORIGINAIS

**Mantidas intactas** em:
$(foreach ($o in $Origens) { "- ``$o```n" })

Não deletar até validação completa pelo operador.

---
*Nenhuma fonte foi modificada. O CAS em ``D:\TEIA_CORE\objects\`` é uma cópia aditiva.*
"@

if (-not $DryRun) { $report | Set-Content $ReportPath -Encoding UTF8 }
Write-Status "  Relatório salvo: $ReportPath"

Write-Event 'RUN_END' @{
    run_id     = $RunId
    ok         = $ok
    ja_existia = $jaExist
    falhas     = $falhas.Count
    cas_total  = $binFiles.Count
    lote_hash  = $loteHash
    elapsed_s  = $elapsed
}

Write-Host ""
Write-Host "══════════════════════════════════════════════════"
Write-Host " REINGESTÃO v0.12.0 CONCLUÍDA"
Write-Host "══════════════════════════════════════════════════"
Write-Host " Confirmados por hash: $($confirmados.Count)"
Write-Host " Ingeridos (novos):    $ok"
Write-Host " Idempotentes (skip):  $jaExist"
Write-Host " Falhas:               $($falhas.Count)"
Write-Host " CAS íntegros:         $auditOk / $($binFiles.Count)"
Write-Host " SHA-256 do lote:      $($loteHash.Substring(0,32))..."
Write-Host " Tempo:                ${elapsed}s"
Write-Host "══════════════════════════════════════════════════"
