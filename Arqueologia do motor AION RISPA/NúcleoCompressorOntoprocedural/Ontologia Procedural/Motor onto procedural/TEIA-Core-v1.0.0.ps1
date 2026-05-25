# TEIA-Core-v1.0.0.ps1
param(
  [Parameter(Mandatory=$true)][string]$SeedPath,
  [string]$OutDir=".",
  [switch]$Silent
)
$ErrorActionPreference='Stop'

function Log { param([string]$m) if(-not $Silent){ Write-Host "[TEIA] $m" } }
function SHA256Hex { param([byte[]]$D) (-join ([Security.Cryptography.SHA256]::Create().ComputeHash($D) | ForEach-Object { $_.ToString('x2') })) }
function New-Repeat { param([int]$Val,[long]$Count) if($Val -lt 0 -or $Val -gt 255){throw "gen.repeat: byte fora"} if($Count -lt 0){throw "count<0"} $buf=New-Object byte[] $Count; [byte]$b=[byte]$Val; for($i=0;$i -lt $Count;$i++){ $buf[$i]=$b }; return $buf }
function New-Pattern { param([byte[]]$Pat,[long]$Repeat) if(!$Pat -or $Pat.Length -eq 0){throw "gen.pattern: vazio"} if($Repeat -lt 0){throw "repeat<0"} $out=New-Object byte[] ($Pat.Length*$Repeat); $ofs=0; for($r=0;$r -lt $Repeat;$r++){ [Array]::Copy($Pat,0,$out,$ofs,$Pat.Length); $ofs+=$Pat.Length }; return $out }
function DictRef { param([string[]]$Dict,[int[]]$Map,[string]$Enc='utf8') $e=[Text.Encoding]::GetEncoding($Enc); $ms=[IO.MemoryStream]::new(); foreach($i in $Map){ if($i -lt 0 -or $i -ge $Dict.Count){throw "dict.ref: index"} $b=$e.GetBytes($Dict[$i]); $ms.Write($b,0,$b.Length) }; return $ms.ToArray() }
function Decomp { param([byte[]]$Comp,[string]$Algo='brotli') $in=[IO.MemoryStream]::new($Comp); switch($Algo.ToLower()){ 'brotli' { $ds=[IO.Compression.BrotliStream]::new($in,[IO.Compression.CompressionMode]::Decompress,$false) } 'gzip' { $ds=[IO.Compression.GZipStream]::new($in,[IO.Compression.CompressionMode]::Decompress,$false) } default { throw "lz.decode: $Algo" } }; $out=[IO.MemoryStream]::new(); $ds.CopyTo($out); $ds.Dispose(); $out.ToArray() }
function RLE { param($Pairs) $ms=[IO.MemoryStream]::new(); foreach($p in $Pairs){ $b=[byte]([int]$p.b); $n=[int64]$p.n; if($n -lt 0){throw "rle n<0"} if($n -eq 0){continue} $chunk=New-Object byte[] $n; for($i=0;$i -lt $n;$i++){ $chunk[$i]=$b }; $ms.Write($chunk,0,$chunk.Length) }; $ms.ToArray() }
function XorB { param([byte[]]$D,[byte[]]$K) if(!$K -or $K.Length -eq 0){throw "xor: key vazia"} $o=New-Object byte[] $D.Length; for($i=0;$i -lt $D.Length;$i++){ $o[$i]=($D[$i] -bxor $K[$i % $K.Length]) }; $o }
function SliceCopy { param([byte[]]$SoFar,[int64]$Off,[int64]$Len,[int64]$Rep=1) if($Off -lt 0 -or $Len -lt 0 -or $Rep -lt 1){throw "slice: args"} if($Off+$Len -gt $SoFar.Length){throw "slice: janela"} $src=New-Object byte[] $Len; [Array]::Copy($SoFar,$Off,$src,0,$Len); $ms=[IO.MemoryStream]::new(); for($r=0;$r -lt $Rep;$r++){ $ms.Write($src,0,$src.Length) }; $ms.ToArray() }

$seed = (Get-Content -Path $SeedPath -Raw | ConvertFrom-Json)
$supported=@('1.0.0','0.4.0')
if(-not $supported.Contains($seed.v)){ Write-Warning "Bypass de versão ativo. Seed v=$($seed.v) não suportada (suportadas: $($supported -join ','))" }
if(-not $seed.out -or -not $seed.out.name){ throw "Seed inválida: 'out' ausente" }

$out=[IO.MemoryStream]::new()
foreach($op in @($seed.plan)){
  switch($op.op){
    'gen.repeat' { $v = $null; if($null -ne $op.byte){$v=[int]$op.byte} elseif($null -ne $op.value){$v=[int]$op.value} else {throw "gen.repeat: bytevalue ausente"}; $c=New-Repeat -Val $v -Count ([int64]$op.count); $out.Write($c,0,$c.Length) }
    'gen.pattern'{ $p = if($op.pattern_b64){ [Convert]::FromBase64String($op.pattern_b64) } else { @($op.pattern | ForEach-Object {[byte]$_}) }; $c=New-Pattern -Pat $p -Repeat ([int64]$op.repeat); $out.Write($c,0,$c.Length) }
    'dict.ref'  { $enc= if($op.encoding){$op.encoding}else{'utf8'}; $c=DictRef -Dict @($op.dict) -Map @($op.map) -Enc $enc; $out.Write($c,0,$c.Length) }
    'literal'   { $c=[Convert]::FromBase64String($op.payload_b64); $out.Write($c,0,$c.Length) }
    'lz.decode' { $algo= if($op.algo){$op.algo}else{'brotli'}; $c=Decomp -Comp ([Convert]::FromBase64String($op.payload_b64)) -Algo $algo; $out.Write($c,0,$c.Length) }
    'rle.decode'{ $c=RLE $op.pairs; $out.Write($c,0,$c.Length) }
    'slice.copy'{ $sofar=$out.ToArray(); $rep= if($op.repeat){[int64]$op.repeat}else{1}; $c=SliceCopy -SoFar $sofar -Off ([int64]$op.offset) -Len ([int64]$op.length) -Rep $rep; $out.Write($c,0,$c.Length) }
    'xform.xor' { $d= if($op.data_b64){ [Convert]::FromBase64String($op.data_b64) } else { throw "xform.xor: data_b64 ausente" }; $k= if($op.key_b64){ [Convert]::FromBase64String($op.key_b64) } elseif($null -ne $op.key){ ,([byte][int]$op.key) } else { throw "xform.xor: keykey_b64 ausente" }; $c=XorB -D $d -K $k; $out.Write($c,0,$c.Length) }
    default     { throw "Operação desconhecida: $($op.op)" }
  }
}
$bytes=$out.ToArray(); $size=$bytes.Length; $sha=SHA256Hex $bytes
if($seed.out.size -and $size -ne [int64]$seed.out.size){ throw "Tamanho divergente: $size <> $($seed.out.size)" }
if($seed.out.sha256 -and ($sha.ToLower() -ne $seed.out.sha256.ToLower())){ throw "SHA256 divergente: $sha <> $($seed.out.sha256)" }
$target = Join-Path $OutDir $seed.out.name
[IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
[IO.File]::WriteAllBytes($target,$bytes)
Log "restored:$target size:$size sha256:$sha"


