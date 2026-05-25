# TEIA-Core-v0.4.0.ps1
# Executor determinístico de seeds TEIA DSL v0.4 (idempotente)
param(
  [Parameter(Mandatory=$true)][string]$SeedPath,
  [string]$OutDir=".",
  [switch]$Silent
)
$ErrorActionPreference='Stop'

function Log { param([string]$msg) if(-not $Silent){ Write-Host "[TEIA] $msg" } }
function Get-SHA256Hex { param([byte[]]$Data)
  $h = [System.Security.Cryptography.SHA256]::Create().ComputeHash($Data)
  -join ($h | ForEach-Object { $_.ToString("x2") })
}
function New-RepeatBytes { param([int]$Value,[long]$Count)
  if($Value -lt 0 -or $Value -gt 255){ throw "gen.repeat: byte fora de 0..255 ($Value)" }
  if($Count -lt 0){ throw "gen.repeat: count negativo" }
  $buf = New-Object byte[] $Count
  [byte]$b = [byte]$Value
  for($i=0;$i -lt $Count;$i++){ $buf[$i]=$b }
  return $buf
}
function New-PatternBytes { param([byte[]]$Pattern,[long]$Repeat)
  if(!$Pattern -or $Pattern.Length -eq 0){ throw "gen.pattern: pattern vazio" }
  if($Repeat -lt 0){ throw "gen.pattern: repeat negativo" }
  $out = New-Object byte[] ($Pattern.Length * $Repeat)
  $ofs = 0
  for($r=0;$r -lt $Repeat;$r++){
    [Array]::Copy($Pattern,0,$out,$ofs,$Pattern.Length)
    $ofs += $Pattern.Length
  }
  return $out
}
function Get-DictRefBytes { param([string[]]$Dict,[int[]]$Map,[string]$Encoding="utf8")
  $enc = [System.Text.Encoding]::GetEncoding($Encoding)
  $ms = [System.IO.MemoryStream]::new()
  foreach($idx in $Map){
    if($idx -lt 0 -or $idx -ge $Dict.Count){ throw "dict.ref: índice $idx fora do intervalo" }
    $bytes = $enc.GetBytes($Dict[$idx])
    $ms.Write($bytes,0,$bytes.Length)
  }
  return $ms.ToArray()
}
function Decompress { param([byte[]]$Comp,[string]$Algo)
  if(-not $Algo){ $Algo = 'brotli' }
  $in = [System.IO.MemoryStream]::new($Comp)
  switch($Algo.ToLower()){
    'brotli' { $ds = [System.IO.Compression.BrotliStream]::new($in,[System.IO.Compression.CompressionMode]::Decompress,$false) }
    'gzip'   { $ds = [System.IO.Compression.GZipStream]::new($in,[System.IO.Compression.CompressionMode]::Decompress,$false) }
    default { throw "lz.decode: algoritmo não suportado: $Algo" }
  }
  $out = [System.IO.MemoryStream]::new(); $ds.CopyTo($out); $ds.Dispose()
  return $out.ToArray()
}
function Rle-Decode { param($Pairs)
  $ms=[System.IO.MemoryStream]::new()
  foreach($p in $Pairs){
    $b = [byte]([int]$p.b); $n=[int64]$p.n
    if($n -lt 0){ throw "rle.decode: contagem negativa" }
    if($n -eq 0){ continue }
    $chunk = New-Object byte[] $n
    for($i=0;$i -lt $n;$i++){ $chunk[$i]=$b }
    $ms.Write($chunk,0,$chunk.Length)
  }
  return $ms.ToArray()
}
function Xor-Bytes { param([byte[]]$Data,[byte[]]$Key)
  if(!$Key -or $Key.Length -eq 0){ throw "xform.xor: chave vazia" }
  $out = New-Object byte[] $Data.Length
  for($i=0;$i -lt $Data.Length;$i++){ $out[$i] = ($Data[$i] -bxor $Key[$i % $Key.Length]) }
  return $out
}
function Slice-Copy { param([byte[]]$SoFar,[int64]$Offset,[int64]$Length,[int64]$Repeat=1)
  if($Offset -lt 0 -or $Length -lt 0 -or $Repeat -lt 1){ throw "slice.copy: parâmetros inválidos" }
  if($Offset + $Length -gt $SoFar.Length){ throw "slice.copy: janela fora do buffer ($Offset..$($Offset+$Length-1) of $($SoFar.Length))" }
  $src = New-Object byte[] $Length
  [Array]::Copy($SoFar,$Offset,$src,0,$Length)
  $ms=[System.IO.MemoryStream]::new()
  for($r=0;$r -lt $Repeat;$r++){ $ms.Write($src,0,$src.Length) }
  return $ms.ToArray()
}

# Carrega seed
$seedRaw = Get-Content -Path $SeedPath -Raw
$seed = $seedRaw | ConvertFrom-Json
if($seed.v -ne "0.4.0"){ throw "Seed v=$($seed.v) não suportada por este core (esperado v0.4.0)" }
if(-not $seed.out -or -not $seed.out.name){ throw "Seed inválida: 'out' ausente" }

# Execução
$outStream = [System.IO.MemoryStream]::new()
$ops = @($seed.plan)
$opi = 0
foreach($op in $ops){
  $name = $op.op
  switch($name){
    'gen.repeat' {
      $val = if($null -ne $op.byte){ [int]$op.byte } elseif($null -ne $op.value){ [int]$op.value } else { throw "gen.repeat: byte/value ausente" }
      $chunk = New-RepeatBytes -Value $val -Count ([int64]$op.count)
      $outStream.Write($chunk,0,$chunk.Length)
    }
    'gen.pattern' {
      $pattern = if($op.pattern_b64){ [Convert]::FromBase64String($op.pattern_b64) } else { @($op.pattern | ForEach-Object {[byte]$_}) }
      $chunk = New-PatternBytes -Pattern $pattern -Repeat ([int64]$op.repeat)
      $outStream.Write($chunk,0,$chunk.Length)
    }
    'dict.ref' {
      $enc = if($op.encoding){ $op.encoding } else { 'utf8' }
      $chunk = Get-DictRefBytes -Dict @($op.dict) -Map @($op.map) -Encoding $enc
      $outStream.Write($chunk,0,$chunk.Length)
    }
    'literal' {
      $chunk = [Convert]::FromBase64String($op.payload_b64)
      $outStream.Write($chunk,0,$chunk.Length)
    }
    'lz.decode' {
      $algo = if($op.algo){ $op.algo } else { 'brotli' }
      $comp = [Convert]::FromBase64String($op.payload_b64)
      $chunk = Decompress -Comp $comp -Algo $algo
      $outStream.Write($chunk,0,$chunk.Length)
    }
    'rle.decode' {
      $chunk = Rle-Decode $op.pairs
      $outStream.Write($chunk,0,$chunk.Length)
    }
    'slice.copy' {
      $sofar = $outStream.ToArray()
      $rep = if($op.repeat){ [int64]$op.repeat } else { 1 }
      $chunk = Slice-Copy -SoFar $sofar -Offset ([int64]$op.offset) -Length ([int64]$op.length) -Repeat $rep
      $outStream.Write($chunk,0,$chunk.Length)
    }
    'xform.xor' {
      $data = if($op.data_b64){ [Convert]::FromBase64String($op.data_b64) } else { throw "xform.xor: data_b64 ausente" }
      $key  = if($op.key_b64){ [Convert]::FromBase64String($op.key_b64) } elseif($null -ne $op.key){ ,([byte][int]$op.key) } else { throw "xform.xor: key/key_b64 ausente" }
      $chunk = Xor-Bytes -Data $data -Key $key
      $outStream.Write($chunk,0,$chunk.Length)
    }
    default { throw "Operação desconhecida: $name" }
  }
  $opi++
}

$bytes = $outStream.ToArray()
$size = $bytes.Length
$sha = Get-SHA256Hex $bytes

if($seed.out.size -and $size -ne [int64]$seed.out.size){ throw "Tamanho divergente: esperado=$($seed.out.size) obtido=$size" }
if($seed.out.sha256 -and ($sha.ToLower() -ne $seed.out.sha256.ToLower())){ throw "SHA256 divergente: esperado=$($seed.out.sha256) obtido=$sha" }

$target = Join-Path $OutDir $seed.out.name
[System.IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
[System.IO.File]::WriteAllBytes($target,$bytes)
Log "restored:$target size:$size sha256:$sha"

