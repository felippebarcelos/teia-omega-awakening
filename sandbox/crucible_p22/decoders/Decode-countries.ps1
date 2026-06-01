#Requires -Version 7
[CmdletBinding()]
param([string]$SeedFile, [string]$OutputFile)
function Decomp([string]$b64) {
    $c=([Convert]::FromBase64String($b64))
    $ms=New-Object System.IO.MemoryStream($c,0,$c.Length)
    $bs=New-Object System.IO.Compression.BrotliStream($ms,[System.IO.Compression.CompressionMode]::Decompress)
    $o=New-Object System.IO.MemoryStream;$bs.CopyTo($o);$bs.Dispose();$o.ToArray()
}
$s = Get-Content $SeedFile -Raw | ConvertFrom-Json
[System.IO.File]::WriteAllBytes($OutputFile, (Decomp $s.full_brotli))