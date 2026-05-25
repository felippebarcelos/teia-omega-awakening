# TEIA-Fractal-Referential-Run.ps1
# Executa: teia_dict_gen -> seed_ref -> expand_ref -> métricas (%ref vs %inline) -> registro dna_events.jsonl
param(
  [string]$Root = 'D:\Teia\TEIA_NUCLEO\offline\nano',
  [string[]]$Targets = @('D:\Teia\TEIA_NUCLEO\offline\nano\restored_cublasLt64_11.dll'),
  [int]$BlockKB = 256
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

$RefDir    = Join-Path $Root 'referential'
$ScriptsDir = Join-Path $RefDir 'scripts'
$DictPath  = Join-Path $RefDir 'teia_dict_fractal.jsonl'
$LogPath   = Join-Path $RefDir 'referential_run.log'
$Events    = Join-Path $Root 'dna_events.jsonl'

function Write-Log { param($m,$l='INFO') "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) [$l] $m" | Tee-Object -FilePath $LogPath -Append }

# valida pré-condições
if(-not (Test-Path $ScriptsDir)){ throw "Scripts não encontrados em: $ScriptsDir" }
foreach($s in @('teia_dict_gen.ps1','teia_seed_ref.ps1','teia_expand_ref.ps1')){
  $p = Join-Path $ScriptsDir $s
  if(-not (Test-Path $p)){ throw "Arquivo ausente: $p" }
}

Write-Log "Iniciando run referencial. Root: $Root"

# 1) Gerar/atualizar dicionário (com dados - pode demorar)
try{
  Write-Log "Executando teia_dict_gen.ps1 -IncludeData (pode demorar...)"
  & (Join-Path $ScriptsDir 'teia_dict_gen.ps1') -IncludeData -Root $Root -BlockKB $BlockKB | Tee-Object -FilePath $LogPath -Append
  Write-Log "teia_dict_gen finalizado"
}catch{
  Write-Log "ERRO em teia_dict_gen: $($_.Exception.Message)" 'ERROR'
  throw
}

# Carrega dicionário em memória (sha -> entry)
$dictMap = [System.Collections.Generic.Dictionary[string,psobject]]::new()
if(Test-Path $DictPath){
  Get-Content $DictPath | ForEach-Object {
    try{
      $o = $_ | ConvertFrom-Json
      $dictMap[$o.sha256] = $o
    }catch{ Write-Log "WARN: erro ao parsear linha do dict: $($_.Exception.Message)" 'WARN' }
  }
  Write-Log "Dicionário carregado: $($dictMap.Count) entradas"
} else {
  Write-Log "Dicionário não encontrado em $DictPath" 'WARN'
}

# Função utilitária para processar um alvo
function Process-Target {
  param($FilePath)
  if(-not (Test-Path $FilePath)){ Write-Log "Arquivo alvo não existe: $FilePath" 'WARN'; return $null }

  Write-Log "Gerando seed para: $FilePath"
  $seedPath = "$FilePath.seed.json"
  & (Join-Path $ScriptsDir 'teia_seed_ref.ps1') -InputPath $FilePath -DictPath $DictPath -BlockKB $BlockKB | Tee-Object -FilePath $LogPath -Append

  if(-not (Test-Path $seedPath)){ Write-Log "Seed nao gerada: $seedPath" 'ERROR'; return $null }

  Write-Log "Expandindo seed (reconstruindo): $seedPath"
  $expandOut = "$FilePath.reconstructed"
  try{
    $res = & (Join-Path $ScriptsDir 'teia_expand_ref.ps1') -SeedPath $seedPath -DictPath $DictPath -OutFile $expandOut 2>&1
    $jsonRes = $res | ConvertFrom-Json
    Write-Log ("Expand report: " + ($jsonRes | ConvertTo-Json -Compress))
  }catch{
    Write-Log "ERRO na expansão: $($_.Exception.Message)" 'ERROR'
    throw
  }

  # Carrega seed para métricas
  $seed = Get-Content $seedPath -Raw | ConvertFrom-Json
  $totalSegments = $seed.segments.Count
  $refSegments = ($seed.segments | Where-Object { $_.t -eq 'ref' }).Count
  $inlineSegments = ($seed.segments | Where-Object { $_.t -eq 'inline' }).Count

  # bytes
  $refBytes = 0
  foreach($seg in $seed.segments | Where-Object { $_.t -eq 'ref' }){
    $sha = $seg.sha
    if($dictMap.ContainsKey($sha) -and $dictMap[$sha].bytes){ $refBytes += [int]$dictMap[$sha].bytes } else { Write-Log "REF sem bytes no dict: $sha" 'WARN' }
  }
  $inlineBytes = 0
  foreach($seg in $seed.segments | Where-Object { $_.t -eq 'inline' }){
    try{
      $b = [Convert]::FromBase64String($seg.b64); $inlineBytes += $b.Length
    }catch{ Write-Log "WARN: inline base64 decode fail" 'WARN' }
  }
  $totalBytes = $refBytes + $inlineBytes
  if($totalBytes -eq 0){ $pctRefBytes = 0 } else { $pctRefBytes = [math]::Round(($refBytes / $totalBytes) * 100,2) }
  if($totalSegments -eq 0){ $pctRefSegments = 0 } else { $pctRefSegments = [math]::Round(($refSegments / $totalSegments) * 100,2) }

  $evt = @{
    ts = (Get-Date).ToString('o')
    file = $FilePath
    seed = (Split-Path $seedPath -Leaf)
    reconstructed = $expandOut
    segments_total = $totalSegments
    segments_ref = $refSegments
    segments_inline = $inlineSegments
    bytes_total = $totalBytes
    bytes_ref = $refBytes
    bytes_inline = $inlineBytes
    pct_ref_bytes = $pctRefBytes
    pct_ref_segments = $pctRefSegments
    dict_entries = $dictMap.Count
  }
  $evtJson = $evt | ConvertTo-Json -Compress
  $evtJson | Out-File -FilePath $Events -Append -Encoding utf8
  Write-Log "Evento registrado: $Events"
  return $evt
}

# Processa todos os targets e imprime resumo
$results = @()
foreach($t in $Targets){ 
  try{
    $r = Process-Target -FilePath $t
    if($r){ $results += $r }
  }catch{ Write-Log "ERRO processando $t : $($_.Exception.Message)" 'ERROR' }
}

# Resumo final
Write-Host "==== Resumo TEIA Referencial ===="
foreach($x in $results){ 
  Write-Host ("File: {0} | segs: {1} (ref {2} | inline {3}) | bytes_ref%: {4} | bytes_total: {5}" -f $x.file,$x.segments_total,$x.segments_ref,$x.segments_inline,$x.pct_ref_bytes,$x.bytes_total)
}
Write-Host "Eventos gravados em: $Events"
Write-Log "Run completo"
