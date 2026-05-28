<#
.SYNOPSIS
    TEIA-Watchdog-Report.ps1 — Relatório de Candidates e Estimativa de Economia

.DESCRIPTION
    Lê todos os .candidate.json em CandidatesRoot, agrupa por estratégia e
    estima a economia de bytes com heurísticas baseadas nos benchmarks v0.19.x.
    Apenas leitura — zero escrita em qualquer arquivo.

.PARAMETER CandidatesRoot
    Pasta de candidates. Padrão: D:\TEIA_CORE\neuroplanner\candidates

.PARAMETER ShowFiles
    Lista os arquivos individuais em cada grupo.

.EXAMPLE
    .\TEIA-Watchdog-Report.ps1
    .\TEIA-Watchdog-Report.ps1 -ShowFiles
    .\TEIA-Watchdog-Report.ps1 -CandidatesRoot "D:\outro\caminho"
#>
[CmdletBinding()]
param(
    [string]$CandidatesRoot = "D:\TEIA_CORE\neuroplanner\candidates",
    [switch]$ShowFiles
)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ── heurísticas de economia por estratégia ────────────────────────────────────
# Baseadas em benchmarks empíricos v0.19.x (NEUROPLANNER_AMBIGUOUS_ZONE_v0196.md)
# savings_rate: fração do tamanho original que seria eliminada pela compressão
# (ex: 0.72 = arquivo comprimido ocupa ~28% do original)

$SAVINGS = [ordered]@{
    'gen.repeat'  = [pscustomobject]@{ rate=0.999; label='~99.9%'; note='seed+size (~35B) para qualquer tamanho' }
    'gen.pattern' = [pscustomobject]@{ rate=0.995; label='~99.5%'; note='padrão+count (<512B) para qualquer tamanho' }
    'cmp.lzma'    = [pscustomobject]@{ rate=0.72;  label='~72%';   note='benchmarks: arquivos ocupam 10–28% do original' }
    'cmp.brotli'  = [pscustomobject]@{ rate=0.65;  label='~65%';   note='benchmarks: arquivos ocupam 23–36% do original (pequenos)' }
    'cas.raw'     = [pscustomobject]@{ rate=0.00;  label='0%';     note='incompressível — sem economia' }
}

# ── validação ────────────────────────────────────────────────────────────────

if (-not (Test-Path $CandidatesRoot)) {
    Write-Host "[RPT] ERRO: pasta de candidates não encontrada: $CandidatesRoot" -ForegroundColor Red; exit 1
}

[object[]]$candidateFiles = @(Get-ChildItem -Path $CandidatesRoot -Filter '*.candidate.json' `
                                            -File -ErrorAction SilentlyContinue)

if ($candidateFiles.Count -eq 0) {
    Write-Host "[RPT] Nenhum candidate encontrado em: $CandidatesRoot" -ForegroundColor Yellow; exit 0
}

# ── leitura e parse ──────────────────────────────────────────────────────────

$records  = [System.Collections.Generic.List[object]]::new()
$parseErr = 0

foreach ($f in $candidateFiles) {
    try {
        $c    = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $name = if ($c.structural_profile -and $c.structural_profile.name) {
                    [string]$c.structural_profile.name
                } elseif ($c.file) {
                    [System.IO.Path]::GetFileName([string]$c.file)
                } else { $f.Name }

        # Compatibilidade com v0.19.0 (usa 'strategy') e v0.19.4+ (usa 'final_strategy')
        $strat = if ($c.final_strategy) { [string]$c.final_strategy }
                 elseif ($c.strategy)   { [string]$c.strategy }
                 else                   { 'unknown' }

        $null = $records.Add([pscustomobject]@{
            name           = $name
            size_bytes     = [long]$c.size_bytes
            final_strategy = $strat
            rule_source    = if ($c.hard_rule_decision) { [string]$c.hard_rule_decision.source } else { 'legacy' }
            rule_id        = if ($c.hard_rule_decision) { [string]$c.hard_rule_decision.rule_id } else { '' }
            entropy        = if ($c.metrics) { [double]$c.metrics.entropy }
                             elseif ($c.structural_profile) { [double]$c.structural_profile.entropy }
                             else { 0.0 }
            version        = [string]$c.version
            sha256         = [string]$c.sha256
        })
    } catch {
        $parseErr++
        Write-Host "[RPT] Aviso — não foi possível ler: $($f.Name)" -ForegroundColor DarkYellow
    }
}

# ── cálculo por grupo ─────────────────────────────────────────────────────────

$groups       = $records | Group-Object -Property final_strategy | Sort-Object -Property Name
$totalBytes   = [long]($records | Measure-Object -Property size_bytes -Sum).Sum
$totalSaved   = [long]0
$totalCompact = [long]0

# ── saída ────────────────────────────────────────────────────────────────────

$line78 = '=' * 78
Write-Host ''
Write-Host $line78 -ForegroundColor Cyan
Write-Host ' TEIA-Watchdog-Report — Candidates e Estimativa de Economia' -ForegroundColor Cyan
Write-Host $line78
Write-Host (" Candidates : {0,-6} | Total original : {1,8} MB | Pasta: {2}" -f `
    $records.Count, [math]::Round($totalBytes/1MB, 2), $CandidatesRoot)
if ($parseErr -gt 0) {
    Write-Host " Avisos de leitura : $parseErr" -ForegroundColor DarkYellow
}
Write-Host $line78
Write-Host ''
Write-Host (' {0,-14} {1,5} {2,10} {3,11} {4,9} {5,8} {6}' -f `
    'Estratégia', 'Arqs', 'Orig (MB)', 'Comp (MB)', 'Economia', 'Razão×', 'Base Empírica') -ForegroundColor White
Write-Host (' {0,-14} {1,5} {2,10} {3,11} {4,9} {5,8} {6}' -f `
    ('-'*14), ('-'*5), ('-'*10), ('-'*11), ('-'*9), ('-'*8), ('-'*30))

foreach ($g in $groups) {
    $strat     = $g.Name
    $count     = $g.Count
    $origBytes = [long]($g.Group | Measure-Object -Property size_bytes -Sum).Sum

    $sav       = if ($SAVINGS.Contains($strat)) { $SAVINGS[$strat] } else {
                     [pscustomobject]@{ rate=0.0; label='?'; note='estratégia desconhecida' }
                 }
    $savedB    = [long]([double]$origBytes * $sav.rate)
    $compB     = $origBytes - $savedB
    $razao     = if ($compB -gt 0) { [math]::Round($origBytes / $compB, 1) } else { 9999.0 }
    $origMB    = [math]::Round($origBytes / 1MB, 2)
    $compMB    = [math]::Round($compB / 1MB, 2)

    $totalSaved   += $savedB
    $totalCompact += $compB

    $color = switch ($strat) {
        'gen.repeat'  { 'Green'  }
        'gen.pattern' { 'Green'  }
        'cmp.lzma'    { 'Yellow' }
        'cmp.brotli'  { 'Cyan'   }
        'cas.raw'     { 'Gray'   }
        default       { 'White'  }
    }

    Write-Host (' {0,-14} {1,5} {2,10} {3,11} {4,8}  {5,7}× {6}' -f `
        $strat, $count, $origMB, $compMB, $sav.label, $razao, $sav.note) -ForegroundColor $color

    if ($ShowFiles) {
        foreach ($r in ($g.Group | Sort-Object size_bytes -Descending)) {
            $kb = [math]::Round($r.size_bytes / 1KB, 1)
            Write-Host ('   {0,-50} {1,8} KB  e={2}' -f $r.name, $kb, $r.entropy) -ForegroundColor DarkGray
        }
    }
}

# Linha de total
$totalOrigMB  = [math]::Round($totalBytes / 1MB, 2)
$totalCompMB  = [math]::Round($totalCompact / 1MB, 2)
$totalEconPct = if ($totalBytes -gt 0) { [math]::Round(($totalSaved / $totalBytes) * 100, 1) } else { 0.0 }
$totalRazao   = if ($totalCompact -gt 0) { [math]::Round($totalBytes / $totalCompact, 1) } else { 9999.0 }
$totalEconMB  = [math]::Round($totalSaved / 1MB, 2)

Write-Host (' {0,-14} {1,5} {2,10} {3,11} {4,8}  {5,7}×' -f `
    'TOTAL', $records.Count, $totalOrigMB, $totalCompMB, "$totalEconPct%", $totalRazao) -ForegroundColor White

Write-Host ''
Write-Host (" Economia estimada : {0} MB de {1} MB → economizaria {2} MB ({3}%)" -f `
    $totalEconMB, $totalOrigMB, $totalEconMB, $totalEconPct) -ForegroundColor Green

Write-Host ''
Write-Host ' Notas:' -ForegroundColor DarkGray
Write-Host '   gen.repeat/pattern : compressão procedural — seed+algoritmo, sem compressor externo' -ForegroundColor DarkGray
Write-Host '   cmp.lzma           : estimativa conservadora (72%) — casos reais: 72–90%' -ForegroundColor DarkGray
Write-Host '   cmp.brotli         : estimativa para arquivos < 8 KB (65%) — casos reais: 64–77%' -ForegroundColor DarkGray
Write-Host '   cas.raw            : arquivo já comprimido — armazenado sem recompressão' -ForegroundColor DarkGray
Write-Host $line78
