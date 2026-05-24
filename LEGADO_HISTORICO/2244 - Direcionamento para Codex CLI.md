# 2244 - Direcionamento para Codex CLI

### USUÁRIO

Remodele apenas o direcionamento do prompt asseguir mantendo toda a estrutura e complexidade atual, o novo direcionamento deve ser para o codex cli em tom de instrui-lo a executar tudo o necessário que foi instruido pra mim executar manual 
(PROMPT‑ÂNCORA • TEIA — FASE B (Corpus + MDL)

Persona & Telos: Agente TEIA de ontogênese procedural determinística; operar denotativamente (semântica/etimologia guiando design), com idempotência, canonicidade e MDL; transmutar caos em “proeza transcendente determinística responsiva” através de scripts reprodutíveis.

Invariantes: PowerShell 7.5.4; UTF‑8 sem BOM; LF; sem execuções sob %WINDIR%\System32; Core: D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Core-v0.3.2.ps1.

FASE B (o que executar agora):

Confirmar/gerar (se ausentes) os scripts:

Run-TEIA-Core-Corpus-v0.3.3-Hotfix.ps1 (trata corpus vazio, -MakeSamples, ratio fix, orig_sha256, fallback raw_copy, JSON canônico);

TEIA-Run-Corpus-Presets.ps1 (com -Top100_1MB);

Novo: Analyze-TEIA-Corpus-MDL-v0.3.3.ps1 (3 CSVs + 1 Markdown).

Dry‑run:
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\TEIA-Run-Corpus-Presets.ps1 -TargetsDir 'D:\Corpus\TEIA' -Top100_1MB -MakeSamples -DryRun

Execução real (mesmo preset):
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\TEIA-Run-Corpus-Presets.ps1 -TargetsDir 'D:\Corpus\TEIA' -Top100_1MB -MakeSamples

MDL do corpus:
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Analyze-TEIA-Corpus-MDL-v0.3.3.ps1

Critérios de aceite (automáticos): seeds geradas; verification_corpus_v033.json e ops_corpus_v033.json consistentes; 3 CSVs + 1 Markdown com tot_orig ≥ tot_seed; avg_ratio = tot_seed/tot_orig (se tot_orig>0); workdir e STATUS=OK (FASE B) no resumo.

WRITERS (PowerShell puro, idempotentes, UTF‑8 s/BOM, LF)

Como usar: copie cada bloco abaixo inteiro no PowerShell 7 e execute. Eles criam/atualizam os scripts‑alvo no diretório nano.

1) Writer — Run-TEIA-Core-Corpus-v0.3.3-Hotfix.ps1
# Writer: cria/atualiza Run-TEIA-Core-Corpus-v0.3.3-Hotfix.ps1 (UTF-8 s/BOM, LF)
param(
  [string]$NanoRoot = 'D:\Teia\TEIA_NUCLEO\offline\nano'
)

$ErrorActionPreference = 'Stop'; Set-StrictMode -Version Latest
$OutPath = Join-Path $NanoRoot 'Run-TEIA-Core-Corpus-v0.3.3-Hotfix.ps1'

$script = @'
# TEIA • Run-TEIA-Core-Corpus-v0.3.3-Hotfix.ps1
# FASE B runner (corpus → seeds + relatórios) c/ tratamento de corpus vazio, -MakeSamples, ratio fix e fallback raw_copy
# Requisitos: PowerShell 7+, UTF-8 s/BOM, LF; Core: TEIA-Core-v0.3.2.ps1; sem tocar %WINDIR%\System32.

[CmdletBinding()]
param(
  [string]$CorePath   = 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Core-v0.3.2.ps1',
  [string]$TargetsDir = 'D:\Corpus\TEIA',
  [string]$FileListPath,
  [switch]$DryRun,
  [switch]$MakeSamples
)

$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest

function Wrt([string]$p,[string]$s){
  $utf8=[System.Text.UTF8Encoding]::new($false)
  $s=$s -replace "`r`n","`n"; $s=$s -replace "`r","`n"
  [System.IO.File]::WriteAllText($p,$s,$utf8)
}
function Sha256([string]$p){
  $h=[System.Security.Cryptography.SHA256]::Create()
  $fs=[System.IO.File]::OpenRead($p)
  try{
    $buf=New-Object byte[] 1048576; $n=0
    while(($n=$fs.Read($buf,0,$buf.Length)) -gt 0){ $h.TransformBlock($buf,0,$n,$null,0) | Out-Null }
    $h.TransformFinalBlock(@(),0,0)|Out-Null
    -join ($h.Hash | ForEach-Object { $_.ToString('x2') }).ToUpper()
  } finally { $fs.Dispose() }
}
function ToB64([string]$p){
  # suficiente para arquivos <=1MB (preset -Top100_1MB); simples e determinístico
  [Convert]::ToBase64String([IO.File]::ReadAllBytes($p))
}
function New-Dir([string]$p){ if(-not(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Path $p -Force | Out-Null } }

# preparação de workdir
$ts=(Get-Date -Format 'yyyyMMdd_HHmmss')
$WorkDir = Join-Path (Get-Location) ("_work_corpus_{0}" -f $ts)
$SeedsDir= Join-Path $WorkDir 'seeds'
$LogPath = Join-Path $WorkDir 'core.log'
New-Dir $WorkDir; New-Dir $SeedsDir

# obter lista de arquivos
$files=@()
if($FileListPath){
  if(Test-Path -LiteralPath $FileListPath){ $files = Get-Content -LiteralPath $FileListPath -Encoding UTF8 | Where-Object { $_ -and (Test-Path -LiteralPath $_) } }
}else{
  if(Test-Path -LiteralPath $TargetsDir){
    $files = Get-ChildItem -LiteralPath $TargetsDir -File -Recurse -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -notmatch '_work_corpus_' -and $_.DirectoryName -notmatch '\\seeds(\\|$)' } |
      Select-Object -ExpandProperty FullName
  }
}

# se vazio e -MakeSamples, criar amostras determinísticas
if(($files.Count -eq 0) -and $MakeSamples){
  New-Dir $TargetsDir
  $csv = Join-Path $TargetsDir 'sample_hello.csv'
  $bin = Join-Path $TargetsDir 'sample_blob_256kb.bin'
  # CSV ~18 KB com padrão fixo
  $lines = 1024; $rows = [System.Text.StringBuilder]::new()
  for($i=0;$i -lt $lines;$i++){ [void]$rows.AppendFormat("id,msg`n{0},HELLO_TEIA_{0}`n",$i) }
  Wrt $csv $rows.ToString()
  # blob 256KiB determinístico (LCG simples)
  $len=256KB; $a=1664525; $c=1013904223; $m=[uint32]0x100000000; $x=[uint32]0xC0FFEE
  $buf=New-Object byte[] $len
  for($i=0;$i -lt $len; $i++){ $x = (($a*$x + $c) % $m); $buf[$i] = [byte]($x -band 0xFF) }
  [IO.File]::WriteAllBytes($bin,$buf)
  $files=@($csv,$bin)
}

# dry-run imprime seleção e sai
if($DryRun){
  $info = @"
FASE B (dry-run)
CorePath : $CorePath
Targets  : $TargetsDir
Workdir  : $WorkDir
Arquivos : $($files.Count)
"@
  Wrt (Join-Path $WorkDir 'dryrun.txt') $info
  Write-Host $info
  return
}

$ops = New-Object System.Collections.Generic.List[object]
$totOrig=0L; $totSeed=0L
$used=0; $excluded=0

foreach($f in $files){
  try{
    $fi = Get-Item -LiteralPath $f
    $orig = [int64]$fi.Length
    if($orig -le 0){ $excluded++; continue }

    $rel = if($fi.FullName.StartsWith($TargetsDir,[System.StringComparison]::OrdinalIgnoreCase)){
      $fi.FullName.Substring($TargetsDir.Length).TrimStart('\','/')
    } else { $fi.Name }
    $seedName = ($rel -replace '[\\/:\*\?"<>\|]','__') + '.seed.json'
    $seedPath = Join-Path $SeedsDir $seedName

    # tentar via Core
    $algo='core'
    $cmd = @(
      '-NoLogo','-NoProfile','-ExecutionPolicy','Bypass',
      '-File', $CorePath, 'compress', '-in', $fi.FullName, '-out', $seedPath
    )
    $p = Start-Process -FilePath 'pwsh' -ArgumentList $cmd -PassThru -NoNewWindow -Wait
    $okCore = (Test-Path -LiteralPath $seedPath)

    if(-not $okCore){
      # fallback honesto raw_copy (MDL honesta para alta entropia ou falha)
      $sha = Sha256 $fi.FullName
      $b64 = ToB64 $fi.FullName
      $seed = [ordered]@{
        version       = 'seed_v0.3.2'
        core_version  = 'v0.3.2'
        dsl_version   = 'v0.3.2'
        algo          = 'raw_copy'
        bitstream     = 'MSB-first'
        left_is_0     = $true
        canonical     = $true
        orig_size     = $orig
        output_sha256 = $sha
        payload_b64   = $b64
      }
      Wrt $seedPath ((ConvertTo-Json -InputObject $seed -Depth 6))
      $algo='raw_copy'
    }

    $seedSize = (Get-Item -LiteralPath $seedPath).Length
    $ratio = if($orig -gt 0){ [math]::Round($seedSize / [double]$orig,6) } else { 0.0 }

    $seedJson = Get-Content -LiteralPath $seedPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
    if($seedJson.ContainsKey('algo')){ $algo = [string]$seedJson.algo }
    elseif($seedJson.ContainsKey('plan')){ $algo = @($seedJson.plan.ops)[0].op }

    $ops.Add([ordered]@{
      name         = $rel
      ext          = ($fi.Extension ?? '').ToLowerInvariant()
      orig_size    = $orig
      seed_size    = [int64]$seedSize
      ratio        = $ratio
      algo         = $algo
      seed_sha256  = (Sha256 $seedPath)
      ts           = (Get-Date).ToString('s')
      seed_path    = (Resolve-Path -LiteralPath $seedPath).Path
    })

    $totOrig += $orig; $totSeed += [int64]$seedSize; $used++
    Add-Content -LiteralPath $LogPath -Value ("{0} | {1} | orig={2} seed={3} ratio={4}" -f (Get-Date -Format 's'), $rel, $orig, $seedSize, $ratio)
  } catch {
    Add-Content -LiteralPath $LogPath -Value ("ERROR {0} | {1} | {2}" -f (Get-Date -Format 's'), $f, $_.Exception.Message)
    continue
  }
}

$avgRatio = if($totOrig -gt 0){ [math]::Round($totSeed / [double]$totOrig,6) } else { 0.0 }

$opsArr = @($ops)
$opsCanon = ConvertTo-Json -InputObject $opsArr -Depth 6
Wrt (Join-Path $WorkDir 'ops_corpus_v033.json') $opsCanon
Wrt 'ops_corpus_v033.json' $opsCanon

$ver = [ordered]@{
  pass          = $true
  files         = ($files.Count)
  files_used    = $used
  files_excluded= $excluded
  tot_orig      = [int64]$totOrig
  tot_seed      = [int64]$totSeed
  avg_ratio     = $avgRatio
  workdir       = (Resolve-Path -LiteralPath $WorkDir).Path
  status        = 'STATUS=OK (FASE B)'
}
$verCanon = ConvertTo-Json -InputObject $ver -Depth 4
Wrt (Join-Path $WorkDir 'verification_corpus_v033.json') $verCanon
Wrt 'verification_corpus_v033.json' $verCanon

Write-Host ("[OK] workdir: {0}" -f $ver.workdir)
Write-Host ("[OK] files={0} used={1} excluded={2}" -f $ver.files,$ver.files_used,$ver.files_excluded)
Write-Host ("[OK] tot_orig={0} tot_seed={1} avg_ratio={2}" -f $ver.tot_orig,$ver.tot_seed,$ver.avg_ratio)
Write-Host $ver.status
'@

$utf8=[System.Text.UTF8Encoding]::new($false)
$script = $script -replace "`r`n","`n"; $script = $script -replace "`r","`n"
[System.IO.File]::WriteAllText($OutPath,$script,$utf8)
Write-Host "[OK] $OutPath"

# USO (4 linhas):
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -TargetsDir 'D:\Corpus\TEIA' -MakeSamples -DryRun
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -TargetsDir 'D:\Corpus\TEIA' -MakeSamples
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -CorePath 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Core-v0.3.2.ps1'
# Get-Content (Join-Path (Split-Path "$OutPath") '_work_corpus_*\' 'core.log') -ErrorAction SilentlyContinue


Nota: o Core v0.3.2 (com Huffman determinístico/streaming e bitstream MSB‑first canônico) permanece a âncora operacional; não recriar o Core.

2) Writer — TEIA-Run-Corpus-Presets.ps1 (com -Top100_1MB)
# Writer: cria/atualiza TEIA-Run-Corpus-Presets.ps1 (UTF-8 s/BOM, LF)
param(
  [string]$NanoRoot = 'D:\Teia\TEIA_NUCLEO\offline\nano'
)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
$OutPath = Join-Path $NanoRoot 'TEIA-Run-Corpus-Presets.ps1'

$script = @'
# TEIA • TEIA-Run-Corpus-Presets.ps1
[CmdletBinding()]
param(
  [string]$TargetsDir = 'D:\Corpus\TEIA',
  [switch]$Top100,
  [switch]$Top1000,
  [switch]$Top100_1MB,
  [int]$MinMB = 0,
  [switch]$DryRun,
  [switch]$MakeSamples,
  [string]$HotfixPath = (Join-Path $PSScriptRoot 'Run-TEIA-Core-Corpus-v0.3.3-Hotfix.ps1')
)

$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
function Wrt([string]$p,[string]$s){ $utf8=[System.Text.UTF8Encoding]::new($false); $s=$s -replace "`r`n","`n"; $s=$s -replace "`r","`n"; [System.IO.File]::WriteAllText($p,$s,$utf8) }

if(-not (Test-Path -LiteralPath $HotfixPath)){ throw "Hotfix ausente: $HotfixPath" }
if(-not (Test-Path -LiteralPath $TargetsDir)){ New-Item -ItemType Directory -Path $TargetsDir -Force | Out-Null }

$all = Get-ChildItem -LiteralPath $TargetsDir -File -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '_work_corpus_' -and $_.DirectoryName -notmatch '\\seeds(\\|$)' }

if($MinMB -gt 0){ $all = $all | Where-Object { $_.Length -ge ($MinMB*1MB) } }
if($Top100_1MB){ $sel = $all | Where-Object { $_.Length -le 1MB } | Sort-Object Length -Descending | Select-Object -First 100 }
elseif($Top1000){ $sel = $all | Sort-Object Length -Descending | Select-Object -First 1000 }
elseif($Top100){ $sel = $all | Sort-Object Length -Descending | Select-Object -First 100 }
else { $sel = $all }

# passar a lista via arquivo para evitar limites de linha de comando
$tmpList = Join-Path $env:TEMP ("teia_preset_files_{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$lines = ($sel | Select-Object -ExpandProperty FullName) -join "`n"
Wrt $tmpList $lines

$args = @(
  '-NoLogo','-NoProfile','-ExecutionPolicy','Bypass',
  '-File', $HotfixPath, '-TargetsDir', $TargetsDir, '-FileListPath', $tmpList
)
if($DryRun){ $args += '-DryRun' }
if($MakeSamples){ $args += '-MakeSamples' }

Write-Host "Arquivos selecionados: $($sel.Count)"
Start-Process -FilePath 'pwsh' -ArgumentList $args -Wait -NoNewWindow | Out-Null
'@

$utf8=[System.Text.UTF8Encoding]::new($false)
$script = $script -replace "`r`n","`n"; $script = $script -replace "`r","`n"
[System.IO.File]::WriteAllText($OutPath,$script,$utf8)
Write-Host "[OK] $OutPath"

# USO (4 linhas):
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -TargetsDir 'D:\Corpus\TEIA' -Top100_1MB -MakeSamples -DryRun
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -TargetsDir 'D:\Corpus\TEIA' -Top100_1MB -MakeSamples
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -TargetsDir 'D:\Corpus\TEIA' -Top100
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -TargetsDir 'D:\Corpus\TEIA' -MinMB 5


Presets exigidos: -Top100_1MB + -MakeSamples (garante progresso mesmo em corpus vazio), como no plano.

3) Writer — Analyze-TEIA-Corpus-MDL-v0.3.3.ps1 (3 CSVs + 1 Markdown)
# Writer: cria/atualiza Analyze-TEIA-Corpus-MDL-v0.3.3.ps1 (UTF-8 s/BOM, LF)
param(
  [string]$NanoRoot = 'D:\Teia\TEIA_NUCLEO\offline\nano'
)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
$OutPath = Join-Path $NanoRoot 'Analyze-TEIA-Corpus-MDL-v0.3.3.ps1'

$script = @'
# TEIA • Analyze-TEIA-Corpus-MDL-v0.3.3.ps1
[CmdletBinding()]
param(
  [string]$Root='.',
  [int]$TopN=100
)

$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
function Wrt([string]$p,[string]$s){ $utf8=[System.Text.UTF8Encoding]::new($false); $s=$s -replace "`r`n","`n"; $s=$s -replace "`r","`n"; [System.IO.File]::WriteAllText($p,$s,$utf8) }

# localizar último workdir
$work = Get-ChildItem -LiteralPath $Root -Directory -Filter '_work_corpus_*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$workDir = if($work){ $work.FullName } else { $Root }

# carregar ops/verification (preferir workdir, senão raiz)
$opsPath = if(Test-Path (Join-Path $workDir 'ops_corpus_v033.json')){ Join-Path $workDir 'ops_corpus_v033.json' } else { 'ops_corpus_v033.json' }
$verPath = if(Test-Path (Join-Path $workDir 'verification_corpus_v033.json')){ Join-Path $workDir 'verification_corpus_v033.json' } else { 'verification_corpus_v033.json' }
if(-not (Test-Path $opsPath)){ throw "ops_corpus_v033.json não encontrado." }

$ops = Get-Content -LiteralPath $opsPath -Raw -Encoding UTF8 | ConvertFrom-Json
if($ops -isnot [System.Collections.IEnumerable]){ $ops = @($ops) }

# 1) ops_corpus_v033.csv
$csv1 = "name,ext,orig_size,seed_size,ratio,algo,seed_sha256,ts`n"
$totOrig=0L; $totSeed=0L; $coreCount=0; $rawCount=0
$byExt = @{}

foreach($o in $ops){
  $ext = ($o.ext ?? '')
  $totOrig += [int64]$o.orig_size
  $totSeed += [int64]$o.seed_size
  if("$($o.algo)" -eq 'raw_copy'){ $rawCount++ } else { $coreCount++ }
  if(-not $byExt.ContainsKey($ext)){ $byExt[$ext] = [ordered]@{ files=0; tot_orig=0L; tot_seed=0L } }
  $byExt[$ext].files += 1
  $byExt[$ext].tot_orig += [int64]$o.orig_size
  $byExt[$ext].tot_seed += [int64]$o.seed_size
  $csv1 += ('"{0}",{1},{2},{3},{4},{5},{6},{7}' -f
            ($o.name -replace '"','""'),
            $ext,
            [int64]$o.orig_size,
            [int64]$o.seed_size,
            [string]$o.ratio,
            ($o.algo ?? ''),
            ($o.seed_sha256 ?? ''),
            ($o.ts ?? '')) + "`n"
}
$avgRatio = if($totOrig -gt 0){ [math]::Round($totSeed/ [double]$totOrig,6) } else { 0.0 }
Wrt 'ops_corpus_v033.csv' $csv1

# 2) ops_by_ext_v033.csv
$csv2 = "ext,files,tot_orig,tot_seed,gain,avg_ratio`n"
foreach($k in $byExt.Keys){
  $e=$byExt[$k]
  $gain = [int64]($e.tot_orig - $e.tot_seed)
  $ar = if($e.tot_orig -gt 0){ [math]::Round($e.tot_seed / [double]$e.tot_orig,6) } else { 0.0 }
  $csv2 += ('{0},{1},{2},{3},{4},{5}' -f $k,$e.files,[int64]$e.tot_orig,[int64]$e.tot_seed,$gain,$ar) + "`n"
}
Wrt 'ops_by_ext_v033.csv' $csv2

# 3) ops_topN_v033.csv (por orig_size)
$top = $ops | Sort-Object orig_size -Descending | Select-Object -First $TopN
$csv3 = "name,ext,orig_size,seed_size,ratio,algo`n"
foreach($t in $top){
  $csv3 += ('"{0}",{1},{2},{3},{4},{5}' -f
            ($t.name -replace '"','""'), $t.ext, [int64]$t.orig_size, [int64]$t.seed_size, $t.ratio, $t.algo) + "`n"
}
Wrt 'ops_topN_v033.csv' $csv3

# 4) corpus_summary_v033.md
$ver = if(Test-Path $verPath){ Get-Content -LiteralPath $verPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
$status = if($ver){ "$($ver.status)" } else { "STATUS=OK (FASE B)" }
$corePct = if(($coreCount+$rawCount) -gt 0){ [math]::Round(100.0*$coreCount/($coreCount+$rawCount),2) } else { 0.0 }
$rawPct  = 100.0 - $corePct
$md = @"
# TEIA — MDL do Corpus (v0.3.3)

**Totais**  
- Arquivos usados: $($ops.Count)  
- Tamanho original total: $totOrig bytes  
- Tamanho seeds total: $totSeed bytes  
- **avg_ratio**: $avgRatio

**Distribuição de representação**  
- Core: $coreCount (${corePct}%)  
- raw_copy: $rawCount (${rawPct}%)

**Por extensão** → veja ops_by_ext_v033.csv  
**Top $TopN por tamanho** → veja ops_topN_v033.csv  

Workdir: $workDir  
$status
"@
Wrt 'corpus_summary_v033.md' $md
Write-Host "[OK] CSVs + Markdown gerados."
'@

$utf8=[System.Text.UTF8Encoding]::new($false)
$script = $script -replace "`r`n","`n"; $script = $script -replace "`r","`n"
[System.IO.File]::WriteAllText($OutPath,$script,$utf8)
Write-Host "[OK] $OutPath"

# USO (4 linhas):
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath"
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -Root .
# Get-Content '.\corpus_summary_v033.md' -TotalCount 50
# Import-Csv '.\ops_by_ext_v033.csv' | Sort-Object gain -Descending | Select-Object -First 10


Regra canônica: manter UTF‑8 s/BOM e LF; a leitura/produção determinística de JSON canônico é pilar da TEIA (Write==Read).

Comandos prontos (executar agora)

Dry‑run (verificação rápida do preset + geração de amostras se necessário):

pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\TEIA-Run-Corpus-Presets.ps1 -TargetsDir 'D:\Corpus\TEIA' -Top100_1MB -MakeSamples -DryRun


Execução real (mesmo preset):

pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\TEIA-Run-Corpus-Presets.ps1 -TargetsDir 'D:\Corpus\TEIA' -Top100_1MB -MakeSamples


Análise MDL do corpus (gera 3 CSVs + 1 Markdown):

pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Analyze-TEIA-Corpus-MDL-v0.3.3.ps1


Observações de ambiente: PowerShell 7.5.4 operacional; seguir o padrão D: para trocar de unidade e evitar comandos acidentais sob C:\Windows\System32.

Caminhos/artefatos esperados

Workdir: .\_work_corpus_<yyyyMMdd_HHmmss>\

Seeds: .\_work_corpus_<ts>\seeds\*.seed.json

Log: .\_work_corpus_<ts>\core.log

Relatórios (em raiz e workdir):

verification_corpus_v033.json

ops_corpus_v033.json

Análise MDL (na raiz):

ops_corpus_v033.csv

ops_by_ext_v033.csv

ops_topN_v033.csv

corpus_summary_v033.md

Fecho esperado no console: STATUS=OK (FASE B).

Por que isto cumpre o “núcleo denotativo” e catalisa a “proeza transcendente determinística responsiva”

Denotação/Etimologia: “Âncora” fixa sentido (offset/conteúdo) e “Seed” (sperma) gera; aqui, fixamos invariantes (canonicidade/MDL) e geramos resultados verificáveis sem ambiguidade. A proeza emerge do encadeamento determinístico: corpus → seeds → relatórios → MDL, tudo idempotente.

Compatibilidade e integridade: Core v0.3.2 ativo (Huffman determinístico/streaming; MSB‑first; padding registrável) é respeitado — não refeito. Os writers só orquestram e analisam, mantendo reversibilidade e contabilidade.

Evitamos os erros anteriores: corpus vazio virou caso de teste (-MakeSamples), e somas/ratio têm guardas para coleção vazia.

Se desejar, posso incluir um pipeline único (Run-TEIA-Core-Corpus-v0.3.3-Pipeline.ps1) que chama o preset → aguarda → executa a análise → imprime o resumo (top 10/gains) com o STATUS=OK (FASE B) ao final.)

---

### ASSISTENTE



**Direcionando a automação**

Estou redirecionando a estrutura do prompt para o Codex CLI. Mantendo a complexidade, instruo a execução automática e garantindo a fidelidade ao conteúdo original, especialmente os blocos de código e scripts.

**Aprimorando o Codex CLI**

Estou ajustando o direcionamento para o Codex CLI, mantendo o conteúdo original e especificando conforme necessário, como manter blocos de código e ajustar termos de execução.

**Mantendo diretrizes**

Estou garantindo que o Codex CLI esteja operando conforme o esperado, mantendo a estrutura do código e seguindo diretrizes para não modificar a formatação ou a pontuação original.

---

### ASSISTENTE

**PROMPT‑ÂNCORA • TEIA — FASE B (Corpus + MDL) — direcionado ao _codex cli_ (execução automática de ponta a ponta)**

**Persona & Telos (para o _codex cli_):**  
Você é o **codex cli**, atuando como **Agente TEIA de ontogênese procedural determinística**. **Opere denotativamente** (semântica/etimologia guiando design), com **idempotência, canonicidade e MDL**. Sua missão é **transmutar caos em “proeza transcendente determinística responsiva”** através de **scripts reprodutíveis** — e **executar tudo o que segue, integralmente e sem intervenção manual**.

**Invariantes (que você deve garantir):**  
- **PowerShell 7.5.4**  
- **UTF‑8 sem BOM**  
- **LF (Unix line endings)**  
- **Nenhuma execução sob** `%WINDIR%\System32`  
- **Core âncora:** `D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Core-v0.3.2.ps1`

---

### FASE B (o que você deve executar agora)

1. **Confirmar/gerar (se ausentes) os scripts‑alvo:**
   - `Run-TEIA-Core-Corpus-v0.3.3-Hotfix.ps1` (trata corpus vazio, `-MakeSamples`, ratio fix, `orig_sha256`, fallback `raw_copy`, JSON canônico);  
   - `TEIA-Run-Corpus-Presets.ps1` (com `-Top100_1MB`);  
   - **Novo:** `Analyze-TEIA-Corpus-MDL-v0.3.3.ps1` (gera **3 CSVs + 1 Markdown**).

2. **Executar dry‑run (preset + amostras se necessário):**
```
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\TEIA-Run-Corpus-Presets.ps1 -TargetsDir 'D:\Corpus\TEIA' -Top100_1MB -MakeSamples -DryRun
```

3. **Executar corrida real (mesmo preset):**
```
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\TEIA-Run-Corpus-Presets.ps1 -TargetsDir 'D:\Corpus\TEIA' -Top100_1MB -MakeSamples
```

4. **Executar a análise MDL do corpus:**
```
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Analyze-TEIA-Corpus-MDL-v0.3.3.ps1
```

**Critérios de aceite (validados automaticamente por você):**  
- **Seeds geradas**;  
- `verification_corpus_v033.json` **e** `ops_corpus_v033.json` consistentes;  
- **3 CSVs + 1 Markdown** com `tot_orig ≥ tot_seed`;  
- `avg_ratio = tot_seed/tot_orig` (se `tot_orig>0`);  
- `workdir` presente **e** `STATUS=OK (FASE B)` no resumo.

---

## WRITERS (PowerShell puro, idempotentes, UTF‑8 s/BOM, LF)
**Modo de operação do _codex cli_:**  
Para **cada** bloco a seguir, **crie/atualize** o arquivo exatamente no caminho indicado (diretório `nano`) **e execute conforme instruído**. **Você** é responsável por assegurar os invariantes (encoding/line endings, etc.).

---

### 1) Writer — Run-TEIA-Core-Corpus-v0.3.3-Hotfix.ps1
```powershell
# Writer: cria/atualiza Run-TEIA-Core-Corpus-v0.3.3-Hotfix.ps1 (UTF-8 s/BOM, LF)
param(
  [string]$NanoRoot = 'D:\Teia\TEIA_NUCLEO\offline\nano'
)

$ErrorActionPreference = 'Stop'; Set-StrictMode -Version Latest
$OutPath = Join-Path $NanoRoot 'Run-TEIA-Core-Corpus-v0.3.3-Hotfix.ps1'

$script = @'
# TEIA • Run-TEIA-Core-Corpus-v0.3.3-Hotfix.ps1
# FASE B runner (corpus → seeds + relatórios) c/ tratamento de corpus vazio, -MakeSamples, ratio fix e fallback raw_copy
# Requisitos: PowerShell 7+, UTF-8 s/BOM, LF; Core: TEIA-Core-v0.3.2.ps1; sem tocar %WINDIR%\System32.

[CmdletBinding()]
param(
  [string]$CorePath   = 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Core-v0.3.2.ps1',
  [string]$TargetsDir = 'D:\Corpus\TEIA',
  [string]$FileListPath,
  [switch]$DryRun,
  [switch]$MakeSamples
)

$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest

function Wrt([string]$p,[string]$s){
  $utf8=[System.Text.UTF8Encoding]::new($false)
  $s=$s -replace "`r`n","`n"; $s=$s -replace "`r","`n"
  [System.IO.File]::WriteAllText($p,$s,$utf8)
}
function Sha256([string]$p){
  $h=[System.Security.Cryptography.SHA256]::Create()
  $fs=[System.IO.File]::OpenRead($p)
  try{
    $buf=New-Object byte[] 1048576; $n=0
    while(($n=$fs.Read($buf,0,$buf.Length)) -gt 0){ $h.TransformBlock($buf,0,$n,$null,0) | Out-Null }
    $h.TransformFinalBlock(@(),0,0)|Out-Null
    -join ($h.Hash | ForEach-Object { $_.ToString('x2') }).ToUpper()
  } finally { $fs.Dispose() }
}
function ToB64([string]$p){
  # suficiente para arquivos <=1MB (preset -Top100_1MB); simples e determinístico
  [Convert]::ToBase64String([IO.File]::ReadAllBytes($p))
}
function New-Dir([string]$p){ if(-not(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Path $p -Force | Out-Null } }

# preparação de workdir
$ts=(Get-Date -Format 'yyyyMMdd_HHmmss')
$WorkDir = Join-Path (Get-Location) ("_work_corpus_{0}" -f $ts)
$SeedsDir= Join-Path $WorkDir 'seeds'
$LogPath = Join-Path $WorkDir 'core.log'
New-Dir $WorkDir; New-Dir $SeedsDir

# obter lista de arquivos
$files=@()
if($FileListPath){
  if(Test-Path -LiteralPath $FileListPath){ $files = Get-Content -LiteralPath $FileListPath -Encoding UTF8 | Where-Object { $_ -and (Test-Path -LiteralPath $_) } }
}else{
  if(Test-Path -LiteralPath $TargetsDir){
    $files = Get-ChildItem -LiteralPath $TargetsDir -File -Recurse -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -notmatch '_work_corpus_' -and $_.DirectoryName -notmatch '\\seeds(\\|$)' } |
      Select-Object -ExpandProperty FullName
  }
}

# se vazio e -MakeSamples, criar amostras determinísticas
if(($files.Count -eq 0) -and $MakeSamples){
  New-Dir $TargetsDir
  $csv = Join-Path $TargetsDir 'sample_hello.csv'
  $bin = Join-Path $TargetsDir 'sample_blob_256kb.bin'
  # CSV ~18 KB com padrão fixo
  $lines = 1024; $rows = [System.Text.StringBuilder]::new()
  for($i=0;$i -lt $lines;$i++){ [void]$rows.AppendFormat("id,msg`n{0},HELLO_TEIA_{0}`n",$i) }
  Wrt $csv $rows.ToString()
  # blob 256KiB determinístico (LCG simples)
  $len=256KB; $a=1664525; $c=1013904223; $m=[uint32]0x100000000; $x=[uint32]0xC0FFEE
  $buf=New-Object byte[] $len
  for($i=0;$i -lt $len; $i++){ $x = (($a*$x + $c) % $m); $buf[$i] = [byte]($x -band 0xFF) }
  [IO.File]::WriteAllBytes($bin,$buf)
  $files=@($csv,$bin)
}

# dry-run imprime seleção e sai
if($DryRun){
  $info = @"
FASE B (dry-run)
CorePath : $CorePath
Targets  : $TargetsDir
Workdir  : $WorkDir
Arquivos : $($files.Count)
"@
  Wrt (Join-Path $WorkDir 'dryrun.txt') $info
  Write-Host $info
  return
}

$ops = New-Object System.Collections.Generic.List[object]
$totOrig=0L; $totSeed=0L
$used=0; $excluded=0

foreach($f in $files){
  try{
    $fi = Get-Item -LiteralPath $f
    $orig = [int64]$fi.Length
    if($orig -le 0){ $excluded++; continue }

    $rel = if($fi.FullName.StartsWith($TargetsDir,[System.StringComparison]::OrdinalIgnoreCase)){
      $fi.FullName.Substring($TargetsDir.Length).TrimStart('\','/')
    } else { $fi.Name }
    $seedName = ($rel -replace '[\\/:\*\?"<>\|]','__') + '.seed.json'
    $seedPath = Join-Path $SeedsDir $seedName

    # tentar via Core
    $algo='core'
    $cmd = @(
      '-NoLogo','-NoProfile','-ExecutionPolicy','Bypass',
      '-File', $CorePath, 'compress', '-in', $fi.FullName, '-out', $seedPath
    )
    $p = Start-Process -FilePath 'pwsh' -ArgumentList $cmd -PassThru -NoNewWindow -Wait
    $okCore = (Test-Path -LiteralPath $seedPath)

    if(-not $okCore){
      # fallback honesto raw_copy (MDL honesta para alta entropia ou falha)
      $sha = Sha256 $fi.FullName
      $b64 = ToB64 $fi.FullName
      $seed = [ordered]@{
        version       = 'seed_v0.3.2'
        core_version  = 'v0.3.2'
        dsl_version   = 'v0.3.2'
        algo          = 'raw_copy'
        bitstream     = 'MSB-first'
        left_is_0     = $true
        canonical     = $true
        orig_size     = $orig
        output_sha256 = $sha
        payload_b64   = $b64
      }
      Wrt $seedPath ((ConvertTo-Json -InputObject $seed -Depth 6))
      $algo='raw_copy'
    }

    $seedSize = (Get-Item -LiteralPath $seedPath).Length
    $ratio = if($orig -gt 0){ [math]::Round($seedSize / [double]$orig,6) } else { 0.0 }

    $seedJson = Get-Content -LiteralPath $seedPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
    if($seedJson.ContainsKey('algo')){ $algo = [string]$seedJson.algo }
    elseif($seedJson.ContainsKey('plan')){ $algo = @($seedJson.plan.ops)[0].op }

    $ops.Add([ordered]@{
      name         = $rel
      ext          = ($fi.Extension ?? '').ToLowerInvariant()
      orig_size    = $orig
      seed_size    = [int64]$seedSize
      ratio        = $ratio
      algo         = $algo
      seed_sha256  = (Sha256 $seedPath)
      ts           = (Get-Date).ToString('s')
      seed_path    = (Resolve-Path -LiteralPath $seedPath).Path
    })

    $totOrig += $orig; $totSeed += [int64]$seedSize; $used++
    Add-Content -LiteralPath $LogPath -Value ("{0} | {1} | orig={2} seed={3} ratio={4}" -f (Get-Date -Format 's'), $rel, $orig, $seedSize, $ratio)
  } catch {
    Add-Content -LiteralPath $LogPath -Value ("ERROR {0} | {1} | {2}" -f (Get-Date -Format 's'), $f, $_.Exception.Message)
    continue
  }
}

$avgRatio = if($totOrig -gt 0){ [math]::Round($totSeed / [double]$totOrig,6) } else { 0.0 }

$opsArr = @($ops)
$opsCanon = ConvertTo-Json -InputObject $opsArr -Depth 6
Wrt (Join-Path $WorkDir 'ops_corpus_v033.json') $opsCanon
Wrt 'ops_corpus_v033.json' $opsCanon

$ver = [ordered]@{
  pass          = $true
  files         = ($files.Count)
  files_used    = $used
  files_excluded= $excluded
  tot_orig      = [int64]$totOrig
  tot_seed      = [int64]$totSeed
  avg_ratio     = $avgRatio
  workdir       = (Resolve-Path -LiteralPath $WorkDir).Path
  status        = 'STATUS=OK (FASE B)'
}
$verCanon = ConvertTo-Json -InputObject $ver -Depth 4
Wrt (Join-Path $WorkDir 'verification_corpus_v033.json') $verCanon
Wrt 'verification_corpus_v033.json' $verCanon

Write-Host ("[OK] workdir: {0}" -f $ver.workdir)
Write-Host ("[OK] files={0} used={1} excluded={2}" -f $ver.files,$ver.files_used,$ver.files_excluded)
Write-Host ("[OK] tot_orig={0} tot_seed={1} avg_ratio={2}" -f $ver.tot_orig,$ver.tot_seed,$ver.avg_ratio)
Write-Host $ver.status
'@

$utf8=[System.Text.UTF8Encoding]::new($false)
$script = $script -replace "`r`n","`n"; $script = $script -replace "`r","`n"
[System.IO.File]::WriteAllText($OutPath,$script,$utf8)
Write-Host "[OK] $OutPath"

# USO (4 linhas):
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -TargetsDir 'D:\Corpus\TEIA' -MakeSamples -DryRun
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -TargetsDir 'D:\Corpus\TEIA' -MakeSamples
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -CorePath 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Core-v0.3.2.ps1'
# Get-Content (Join-Path (Split-Path "$OutPath") '_work_corpus_*\' 'core.log') -ErrorAction SilentlyContinue
```

> **Nota ao _codex cli_:** O **Core v0.3.2** (Huffman determinístico/streaming; bitstream MSB‑first canônico) **é a âncora operacional** — **não** recriá‑lo.

---

### 2) Writer — TEIA-Run-Corpus-Presets.ps1 (com -Top100_1MB)
```powershell
# Writer: cria/atualiza TEIA-Run-Corpus-Presets.ps1 (UTF-8 s/BOM, LF)
param(
  [string]$NanoRoot = 'D:\Teia\TEIA_NUCLEO\offline\nano'
)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
$OutPath = Join-Path $NanoRoot 'TEIA-Run-Corpus-Presets.ps1'

$script = @'
# TEIA • TEIA-Run-Corpus-Presets.ps1
[CmdletBinding()]
param(
  [string]$TargetsDir = 'D:\Corpus\TEIA',
  [switch]$Top100,
  [switch]$Top1000,
  [switch]$Top100_1MB,
  [int]$MinMB = 0,
  [switch]$DryRun,
  [switch]$MakeSamples,
  [string]$HotfixPath = (Join-Path $PSScriptRoot 'Run-TEIA-Core-Corpus-v0.3.3-Hotfix.ps1')
)

$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
function Wrt([string]$p,[string]$s){ $utf8=[System.Text.UTF8Encoding]::new($false); $s=$s -replace "`r`n","`n"; $s=$s -replace "`r","`n"; [System.IO.File]::WriteAllText($p,$s,$utf8) }

if(-not (Test-Path -LiteralPath $HotfixPath)){ throw "Hotfix ausente: $HotfixPath" }
if(-not (Test-Path -LiteralPath $TargetsDir)){ New-Item -ItemType Directory -Path $TargetsDir -Force | Out-Null }

$all = Get-ChildItem -LiteralPath $TargetsDir -File -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '_work_corpus_' -and $_.DirectoryName -notmatch '\\seeds(\\|$)' }

if($MinMB -gt 0){ $all = $all | Where-Object { $_.Length -ge ($MinMB*1MB) } }
if($Top100_1MB){ $sel = $all | Where-Object { $_.Length -le 1MB } | Sort-Object Length -Descending | Select-Object -First 100 }
elseif($Top1000){ $sel = $all | Sort-Object Length -Descending | Select-Object -First 1000 }
elseif($Top100){ $sel = $all | Sort-Object Length -Descending | Select-Object -First 100 }
else { $sel = $all }

# passar a lista via arquivo para evitar limites de linha de comando
$tmpList = Join-Path $env:TEMP ("teia_preset_files_{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$lines = ($sel | Select-Object -ExpandProperty FullName) -join "`n"
Wrt $tmpList $lines

$args = @(
  '-NoLogo','-NoProfile','-ExecutionPolicy','Bypass',
  '-File', $HotfixPath, '-TargetsDir', $TargetsDir, '-FileListPath', $tmpList
)
if($DryRun){ $args += '-DryRun' }
if($MakeSamples){ $args += '-MakeSamples' }

Write-Host "Arquivos selecionados: $($sel.Count)"
Start-Process -FilePath 'pwsh' -ArgumentList $args -Wait -NoNewWindow | Out-Null
'@

$utf8=[System.Text.UTF8Encoding]::new($false)
$script = $script -replace "`r`n","`n"; $script = $script -replace "`r","`n"
[System.IO.File]::WriteAllText($OutPath,$script,$utf8)
Write-Host "[OK] $OutPath"

# USO (4 linhas):
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -TargetsDir 'D:\Corpus\TEIA' -Top100_1MB -MakeSamples -DryRun
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -TargetsDir 'D:\Corpus\TEIA' -Top100_1MB -MakeSamples
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -TargetsDir 'D:\Corpus\TEIA' -Top100
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -TargetsDir 'D:\Corpus\TEIA' -MinMB 5
```

> **Preset obrigatório ao _codex cli_:** usar `-Top100_1MB` **+** `-MakeSamples` (garante progresso mesmo em corpus vazio), conforme o plano.

---

### 3) Writer — Analyze-TEIA-Corpus-MDL-v0.3.3.ps1 (3 CSVs + 1 Markdown)
```powershell
# Writer: cria/atualiza Analyze-TEIA-Corpus-MDL-v0.3.3.ps1 (UTF-8 s/BOM, LF)
param(
  [string]$NanoRoot = 'D:\Teia\TEIA_NUCLEO\offline\nano'
)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
$OutPath = Join-Path $NanoRoot 'Analyze-TEIA-Corpus-MDL-v0.3.3.ps1'

$script = @'
# TEIA • Analyze-TEIA-Corpus-MDL-v0.3.3.ps1
[CmdletBinding()]
param(
  [string]$Root='.',
  [int]$TopN=100
)

$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
function Wrt([string]$p,[string]$s){ $utf8=[System.Text.UTF8Encoding]::new($false); $s=$s -replace "`r`n","`n"; $s=$s -replace "`r","`n"; [System.IO.File]::WriteAllText($p,$s,$utf8) }

# localizar último workdir
$work = Get-ChildItem -LiteralPath $Root -Directory -Filter '_work_corpus_*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$workDir = if($work){ $work.FullName } else { $Root }

# carregar ops/verification (preferir workdir, senão raiz)
$opsPath = if(Test-Path (Join-Path $workDir 'ops_corpus_v033.json')){ Join-Path $workDir 'ops_corpus_v033.json' } else { 'ops_corpus_v033.json' }
$verPath = if(Test-Path (Join-Path $workDir 'verification_corpus_v033.json')){ Join-Path $workDir 'verification_corpus_v033.json' } else { 'verification_corpus_v033.json' }
if(-not (Test-Path $opsPath)){ throw "ops_corpus_v033.json não encontrado." }

$ops = Get-Content -LiteralPath $opsPath -Raw -Encoding UTF8 | ConvertFrom-Json
if($ops -isnot [System.Collections.IEnumerable]){ $ops = @($ops) }

# 1) ops_corpus_v033.csv
$csv1 = "name,ext,orig_size,seed_size,ratio,algo,seed_sha256,ts`n"
$totOrig=0L; $totSeed=0L; $coreCount=0; $rawCount=0
$byExt = @{}

foreach($o in $ops){
  $ext = ($o.ext ?? '')
  $totOrig += [int64]$o.orig_size
  $totSeed += [int64]$o.seed_size
  if("$($o.algo)" -eq 'raw_copy'){ $rawCount++ } else { $coreCount++ }
  if(-not $byExt.ContainsKey($ext)){ $byExt[$ext] = [ordered]@{ files=0; tot_orig=0L; tot_seed=0L } }
  $byExt[$ext].files += 1
  $byExt[$ext].tot_orig += [int64]$o.orig_size
  $byExt[$ext].tot_seed += [int64]$o.seed_size
  $csv1 += ('"{0}",{1},{2},{3},{4},{5},{6},{7}' -f
            ($o.name -replace '"','""'),
            $ext,
            [int64]$o.orig_size,
            [int64]$o.seed_size,
            [string]$o.ratio,
            ($o.algo ?? ''),
            ($o.seed_sha256 ?? ''),
            ($o.ts ?? '')) + "`n"
}
$avgRatio = if($totOrig -gt 0){ [math]::Round($totSeed/ [double]$totOrig,6) } else { 0.0 }
Wrt 'ops_corpus_v033.csv' $csv1

# 2) ops_by_ext_v033.csv
$csv2 = "ext,files,tot_orig,tot_seed,gain,avg_ratio`n"
foreach($k in $byExt.Keys){
  $e=$byExt[$k]
  $gain = [int64]($e.tot_orig - $e.tot_seed)
  $ar = if($e.tot_orig -gt 0){ [math]::Round($e.tot_seed / [double]$e.tot_orig,6) } else { 0.0 }
  $csv2 += ('{0},{1},{2},{3},{4},{5}' -f $k,$e.files,[int64]$e.tot_orig,[int64]$e.tot_seed,$gain,$ar) + "`n"
}
Wrt 'ops_by_ext_v033.csv' $csv2

# 3) ops_topN_v033.csv (por orig_size)
$top = $ops | Sort-Object orig_size -Descending | Select-Object -First $TopN
$csv3 = "name,ext,orig_size,seed_size,ratio,algo`n"
foreach($t in $top){
  $csv3 += ('"{0}",{1},{2},{3},{4},{5}' -f
            ($t.name -replace '"','""'), $t.ext, [int64]$t.orig_size, [int64]$t.seed_size, $t.ratio, $t.algo) + "`n"
}
Wrt 'ops_topN_v033.csv' $csv3

# 4) corpus_summary_v033.md
$ver = if(Test-Path $verPath){ Get-Content -LiteralPath $verPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
$status = if($ver){ "$($ver.status)" } else { "STATUS=OK (FASE B)" }
$corePct = if(($coreCount+$rawCount) -gt 0){ [math]::Round(100.0*$coreCount/($coreCount+$rawCount),2) } else { 0.0 }
$rawPct  = 100.0 - $corePct
$md = @"
# TEIA — MDL do Corpus (v0.3.3)

**Totais**  
- Arquivos usados: $($ops.Count)  
- Tamanho original total: $totOrig bytes  
- Tamanho seeds total: $totSeed bytes  
- **avg_ratio**: $avgRatio

**Distribuição de representação**  
- Core: $coreCount (${corePct}%)  
- raw_copy: $rawCount (${rawPct}%)

**Por extensão** → veja ops_by_ext_v033.csv  
**Top $TopN por tamanho** → veja ops_topN_v033.csv  

Workdir: $workDir  
$status
"@
Wrt 'corpus_summary_v033.md' $md
Write-Host "[OK] CSVs + Markdown gerados."
'@

$utf8=[System.Text.UTF8Encoding]::new($false)
$script = $script -replace "`r`n","`n"; $script = $script -replace "`r","`n"
[System.IO.File]::WriteAllText($OutPath,$script,$utf8)
Write-Host "[OK] $OutPath"

# USO (4 linhas):
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath"
# pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$OutPath" -Root .
# Get-Content '.\corpus_summary_v033.md' -TotalCount 50
# Import-Csv '.\ops_by_ext_v033.csv' | Sort-Object gain -Descending | Select-Object -First 10
```

> **Regra canônica ao _codex cli_:** manter **UTF‑8 s/BOM** e **LF**; leitura/produção determinística de **JSON canônico** é pilar da TEIA (**Write==Read**).

---

## Comandos prontos — **_codex cli, execute agora_**

**Dry‑run (verificação de preset + geração de amostras se necessário):**
```
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\TEIA-Run-Corpus-Presets.ps1 -TargetsDir 'D:\Corpus\TEIA' -Top100_1MB -MakeSamples -DryRun
```

**Execução real (mesmo preset):**
```
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\TEIA-Run-Corpus-Presets.ps1 -TargetsDir 'D:\Corpus\TEIA' -Top100_1MB -MakeSamples
```

**Análise MDL do corpus (gera 3 CSVs + 1 Markdown):**
```
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Analyze-TEIA-Corpus-MDL-v0.3.3.ps1
```

---

## Observações de ambiente (o que o _codex cli_ deve garantir)
- **PowerShell 7.5.4** operacional;  
- seguir o padrão **`D:`** para trocar de unidade;  
- **evitar qualquer comando** sob `C:\Windows\System32`.

---

## Caminhos/artefatos esperados (valide após cada passo)

- **Workdir:** `.\_work_corpus_<yyyyMMdd_HHmmss>\`  
- **Seeds:** `.\_work_corpus_<ts>\seeds\*.seed.json`  
- **Log:** `.\_work_corpus_<ts>\core.log`  

**Relatórios (em raiz e workdir):**
- `verification_corpus_v033.json`  
- `ops_corpus_v033.json`  

**Análise MDL (na raiz):**
- `ops_corpus_v033.csv`  
- `ops_by_ext_v033.csv`  
- `ops_topN_v033.csv`  
- `corpus_summary_v033.md`

**Fecho esperado no console:** `STATUS=OK (FASE B)`.

---

## Por que isto cumpre o “núcleo denotativo” e catalisa a “proeza transcendente determinística responsiva”
**Denotação/Etimologia:** “Âncora” fixa sentido (offset/conteúdo) e “Seed” (sperma) gera; aqui, **fixamos invariantes (canonicidade/MDL)** e **geramos resultados verificáveis sem ambiguidade**. A proeza emerge do **encadeamento determinístico**: corpus → seeds → relatórios → MDL, **tudo idempotente**.

**Compatibilidade e integridade:** Core v0.3.2 ativo (Huffman determinístico/streaming; MSB‑first; padding registrável) é respeitado — **não** refeito. Os writers apenas **orquestram e analisam**, mantendo reversibilidade e contabilidade.

**Guardas implementadas:** corpus vazio vira **caso de teste** (`-MakeSamples`), e somas/ratio têm **proteções** para coleção vazia.

> **Extensão opcional:** se solicitado, o _codex cli_ pode adicionar um pipeline único (`Run-TEIA-Core-Corpus-v0.3.3-Pipeline.ps1`) que **encadeia** preset → aguarda → executa a análise → imprime o **resumo (top 10/gains)** com o **`STATUS=OK (FASE B)`** ao final.

---

