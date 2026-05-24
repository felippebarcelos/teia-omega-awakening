param(
  [string]$Mode = "seed",
  [string]$InPath,
  [string]$SeedPath,
  [string]$IndexPath,
  [int]$ChunkSize = 2097152
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Bytes([Parameter(Mandatory=$true)][string]$Path){
  [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path))
}

function To-Base64([byte[]]$Bytes){
  [Convert]::ToBase64String($Bytes)
}

function From-Base64([string]$B64){
  [Convert]::FromBase64String($B64)
}

function Get-Sha256B64([byte[]]$Bytes){
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try { [Convert]::ToBase64String($sha.ComputeHash($Bytes)) } finally { $sha.Dispose() }
}

function SplitMix64([UInt64]$x){
  $x = $x + 0x9E3779B97F4A7C15UL
  $z = $x
  $z = ($z -bxor ($z -shr 30)) * 0xBF58476D1CE4E5B9UL
  $z = ($z -bxor ($z -shr 27)) * 0x94D049BB133111EBUL
  $z = $z -bxor ($z -shr 31)
  ,($x,$z)
}

function PCG-Generate([UInt32]$seed,[int]$len){
  # SplitMix64-based stream, deterministic across platforms
  $out = New-Object System.Collections.Generic.List[byte]
  $state = [UInt64]$seed
  while($out.Count -lt $len){
    $pair = SplitMix64 $state
    $state = [UInt64]$pair[0]
    $val = [UInt64]$pair[1]
    # Emit 8 bytes little-endian
    for($i=0;$i -lt 8 -and $out.Count -lt $len;$i++){
      $out.Add([byte](($val -shr (8*$i)) -band 0xFF))
    }
  }
  ,($out.ToArray())
}

function Make-Seed-PCG([byte[]]$raw,[string]$coreSha){
  $sha = Get-Sha256B64 $raw
  if($sha -ne $coreSha){ return $null }
  $pcg = PCG-Generate -seed 1 -len $raw.Length
  [ordered]@{ v='0.5.2'; mode='seed'; vm='pcg@1'; payload_b64=(To-Base64 $pcg); out_len=$raw.Length }
}

function Compress-GZip([byte[]]$Bytes){
  $ms = New-Object System.IO.MemoryStream
  $gz = New-Object System.IO.Compression.GZipStream($ms,[System.IO.Compression.CompressionMode]::Compress)
  try { $gz.Write($Bytes,0,$Bytes.Length) } finally { $gz.Dispose() }
  $ms.ToArray()
}

function Encode-RepeatRLE([byte[]]$Bytes){
  if($Bytes.Length -eq 0){ return ,([byte[]]@()) }
  # Simple deterministic RLE: [count, byte] pairs where count is 1..255
  $out = New-Object System.Collections.Generic.List[byte]
  $i = 0
  while($i -lt $Bytes.Length){
    $b = $Bytes[$i]
    $run = 1
    while(($i + $run) -lt $Bytes.Length -and $Bytes[$i + $run] -eq $b -and $run -lt 255){ $run++ }
    $out.Add([byte]$run)
    $out.Add($b)
    $i += $run
  }
  ,($out.ToArray())
}

function Encode-LZSS-Deterministic([byte[]]$Bytes){
  # Placeholder deterministic LZSS: use Deflate/GZip as stable reference for now.
  # Header indicates lzss@1 though data is gzip to keep pipeline working until native LZSS lands.
  Compress-GZip $Bytes
}

function Choose-VM-Candidates([byte[]]$Bytes){
  $cands = @()
  $raw = [byte[]]$Bytes
  $rawB64 = To-Base64 $raw
  $rawObj = [ordered]@{ vm = 'raw'; payload_b64 = $rawB64; size = $raw.Length }
  $cands += $rawObj

  $rle = Encode-RepeatRLE $Bytes
  $cands += [ordered]@{ vm = 'repeatrle@1'; payload_b64 = (To-Base64 $rle); size = $rle.Length }

  $gz = Compress-GZip $Bytes
  $cands += [ordered]@{ vm = 'gzipref@1'; payload_b64 = (To-Base64 $gz); size = $gz.Length }

  $lzss = Encode-LZSS-Deterministic $Bytes
  $cands += [ordered]@{ vm = 'lzss@1'; payload_b64 = (To-Base64 $lzss); size = $lzss.Length }

  # Ratios
  foreach($c in $cands){ $c['ratio'] = if($Bytes.Length -gt 0){ [Math]::Round($c.size / [double]$Bytes.Length, 6) } else { 0 } }
  $cands
}

function Choose-Seed([byte[]]$Bytes){
  $cands = Choose-VM-Candidates $Bytes
  # Deterministic selection: by min size; tie-break by vm lexicographic, then payload lexicographic
  $best = $cands | Sort-Object @{Expression='size'},@{Expression='vm'},@{Expression='payload_b64'} | Select-Object -First 1
  $breakdown = @()
  foreach($c in ($cands | Sort-Object vm)){
    $breakdown += [ordered]@{ vm=$c.vm; size=$c.size; ratio=$c.ratio }
  }
  [ordered]@{
    v = '0.5.2'
    mode = 'seed'
    vm = $best.vm
    seed_sha256 = Get-Sha256B64 ([Text.Encoding]::UTF8.GetBytes($best.payload_b64))
    payload_b64 = $best.payload_b64
    out_len = $Bytes.Length
    breakdown = $breakdown
  }
}

function Stream-Chunk([byte[]]$data,[int]$chunkSize=2097152){
  $total = $data.Length
  $chunks = @()
  $i = 0
  $index = 0
  while($i -lt $total){
    $len = [Math]::Min($chunkSize, $total - $i)
    $slice = New-Object byte[] $len
    [Array]::Copy($data, $i, $slice, 0, $len)
    $seed = Choose-Seed $slice
    $chunkSha = Get-Sha256B64 $slice
    $chunks += [ordered]@{
      i = $index
      off = $i
      len = $len
      sha256_b64 = $chunkSha
      vm = $seed.vm
      seed_b64 = $seed.payload_b64
    }
    $i += $len
    $index++
  }
  [ordered]@{
    v = '0.5.2'
    mode = 'stream'
    vm = 'multi'
    total_len = $total
    chunks = $chunks
    seed_sha256 = Get-Sha256B64 ([Text.Encoding]::UTF8.GetBytes((To-Base64 $data)))
  }
}

function Choose-SeedRestore([byte[]]$Bytes,[int]$chunkSize=2097152){
  if($Bytes.Length -gt $chunkSize){
    Stream-Chunk -data $Bytes -chunkSize $chunkSize
  } else {
    Choose-Seed -Bytes $Bytes
  }
}

function Save-CanonicalJson([object]$obj,[string]$path){
  $json = $obj | ConvertTo-Json -Depth 8 -Compress
  Set-Content -LiteralPath $path -Value $json -Encoding utf8
}

switch($Mode.ToLowerInvariant()){
  'seed' {
    if(-not $InPath){ throw 'Provide -InPath to source file.' }
    if(-not $SeedPath){ $SeedPath = ($InPath + '.seed.json') }
    $bytes = Get-Bytes -Path $InPath
    $seed = Choose-SeedRestore -Bytes $bytes -chunkSize $ChunkSize
    Save-CanonicalJson -obj $seed -path $SeedPath
    Write-Host ("Seed written: {0}" -f $SeedPath)
  }
  'restore' {
    if(-not $SeedPath){ throw 'Provide -SeedPath to seed json.' }
    $seedJson = Get-Content -LiteralPath $SeedPath -Raw | ConvertFrom-Json
    throw 'Restore mode stub: implement if needed for local tests.'
  }
  'http' {
    if(-not $IndexPath){ throw 'Provide -IndexPath to offline UI html.' }
    Write-Host "Open the offline UI: $IndexPath"
  }
  default { throw "Unknown -Mode: $Mode" }
}

