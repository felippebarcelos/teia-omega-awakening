param(
  [Parameter(Mandatory=$true)][string]$InputPath,
  [string]$OutDir = "$PSScriptRoot/../data/seeds",
  [string]$OntologyPath = "$PSScriptRoot/../ontology/teia_format_ontology.json",
  [string]$LogPath = "$PSScriptRoot/../logs/dna_universal.log",
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

. "$PSScriptRoot/TEIA-Logger.ps1" -LogPath $LogPath -VerificationPath "$PSScriptRoot/../logs/verification_universal.json"

function Read-Bytes {
  param([string]$Path)
  [IO.File]::ReadAllBytes((Resolve-Path $Path))
}

function Parse-HexPattern {
  param([string]$Hex)
  # Returns tuple: byte[] pattern, bool[] wildcards
  $hexClean = $Hex -replace '\s',''
  $list = New-Object System.Collections.Generic.List[byte]
  $wild = New-Object System.Collections.Generic.List[bool]
  for ($i=0; $i -lt $hexClean.Length; $i+=2) {
    $pair = $hexClean.Substring($i, [Math]::Min(2, $hexClean.Length-$i))
    if ($pair -like "??") {
      $list.Add(0)
      $wild.Add($true)
    } else {
      $list.Add([Convert]::ToByte($pair,16))
      $wild.Add($false)
    }
  }
  ,@($list.ToArray(), $wild.ToArray())
}

function Match-Magic {
  param([byte[]]$Bytes, [int]$Offset, [string]$Hex)
  $parsed = Parse-HexPattern $Hex
  $pat = $parsed[0]
  $wild = $parsed[1]
  if ($Bytes.Length -lt $Offset + $pat.Length) { return $false }
  for ($i=0; $i -lt $pat.Length; $i++) {
    if (-not $wild[$i]) {
      if ($Bytes[$Offset + $i] -ne $pat[$i]) { return $false }
    }
  }
  return $true
}

function Detect-Format {
  param([byte[]]$Bytes, [string]$Path, $Ontology)
  $ext = [IO.Path]::GetExtension($Path).ToLowerInvariant()
  $magic = $Ontology.magic_signatures
  foreach ($m in $magic) {
    if (Match-Magic -Bytes $Bytes -Offset ([int]$m.offset) -Hex ([string]$m.hex)) {
      return @{ mime = $m.mime; ext = $ext; by = 'magic'; sig = $m.name }
    }
  }
  # Fallback by extension categories
  foreach ($kv in $Ontology.categories.PSObject.Properties) {
    $cat = $kv.Value
    if ($cat.extensions -and ($cat.extensions | ForEach-Object { $_.ToLower() }) -contains $ext) {
      $mime = if ($cat.mime) { $cat.mime[0] } else { 'application/octet-stream' }
      return @{ mime = $mime; ext = $ext; by = 'extension'; category = $kv.Name }
    }
  }
  return @{ mime = 'application/octet-stream'; ext = $ext; by = 'unknown' }
}

function Detect-Procedural {
  param([byte[]]$Bytes)
  $n = $Bytes.Length
  if ($n -eq 0) { return @{ name='empty'; params=@{}; procedural=$true } }
  # Single byte repeated
  $b0 = $Bytes[0]
  $allSame = $true
  for ($i=1; $i -lt $n; $i++) { if ($Bytes[$i] -ne $b0) { $allSame = $false; break } }
  if ($allSame) { return @{ name='repeat_byte'; params=@{ value = $b0; size=$n }; procedural=$true } }
  # Small repeating sequence up to 64 bytes
  $maxPeriod = [Math]::Min(64, $n)
  for ($p=2; $p -le $maxPeriod; $p++) {
    $ok = $true
    for ($i=0; $i -lt $n; $i++) {
      if ($Bytes[$i] -ne $Bytes[$i % $p]) { $ok = $false; break }
    }
    if ($ok) {
      $seq = $Bytes[0..($p-1)]
      $hex = -join ($seq | ForEach-Object { $_.ToString('x2') })
      return @{ name='repeat_sequence'; params=@{ hex=$hex; period=$p; size=$n }; procedural=$true }
    }
  }
  return @{ name='none'; params=@{}; procedural=$false }
}

try {
  $full = (Resolve-Path $InputPath).Path
  if (-not (Test-Path $full)) { throw "Input not found: $InputPath" }
  $bytes = Read-Bytes $full
  $ontology = Get-Content $OntologyPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 64
  $fmt = Detect-Format -Bytes $bytes -Path $full -Ontology $ontology
  $sha = Get-TEIASha256 $bytes
  $proc = Detect-Procedural -Bytes $bytes
  $info = Get-Item $full
  $seed = [ordered]@{
    version = '1.0'
    created_utc = Get-TEIAUtcNow
    file = $full
    size = [int64]$bytes.Length
    sha256 = $sha
    mtime_utc = $info.LastWriteTimeUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
    format = $fmt
    generator = @{ name = $proc.name; params = $proc.params }
    procedural = [bool]$proc.procedural
    notes = if (-not $proc.procedural) { 'No procedural generator identified; restoration not possible without payload or external source.' } else { '' }
  }
  if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }
  $base = [IO.Path]::GetFileNameWithoutExtension($full)
  $seedName = "${base}_$($sha.Substring(0,12)).seed.json"
  $outPath = Join-Path $OutDir $seedName
  $seed | ConvertTo-Json -Depth 64 | Out-File -FilePath $outPath -Encoding UTF8
  if (-not $Quiet) { Write-Host "[OK] Seed gerado: $outPath" }
  Write-TEIALog -Message "Seed generated for '$full' sha=$sha fmt=$($fmt.mime) procedural=$($proc.procedural) -> $outPath" -Level 'OK'
  Update-Verification -Entry @{ kind='seed'; input=$full; seed=$outPath; sha256=$sha; time=Get-TEIAUtcNow; procedural=$proc.procedural }
} catch {
  Write-TEIALog -Message "Erro Seed-Gen: $_" -Level 'ERROR'
  if (-not $Quiet) { Write-Error $_ }
  exit 1
}

