#Requires -Version 7
[CmdletBinding()]
param([string]$SeedFile, [string]$OutputFile)
$utf8 = [System.Text.UTF8Encoding]::new($false)
function Decomp([string]$b64) {
    $c=([Convert]::FromBase64String($b64))
    $ms=New-Object System.IO.MemoryStream($c,0,$c.Length)
    $bs=New-Object System.IO.Compression.BrotliStream($ms,[System.IO.Compression.CompressionMode]::Decompress)
    $o=New-Object System.IO.MemoryStream;$bs.CopyTo($o);$bs.Dispose();$o.ToArray()
}
$s = Get-Content $SeedFile -Raw | ConvertFrom-Json
$ctryIdx = ($utf8.GetString((Decomp $s.country_idx)) -split '
') | % { [int]$_ }
$dates   = $utf8.GetString((Decomp $s.dates))   -split '
'
$decs    = $utf8.GetString((Decomp $s.decimals)) -split '
'
$vals    = $utf8.GetString((Decomp $s.values))   -split '
'
$ctries  = $s.countries
$sb = [System.Text.StringBuilder]::new()
$sb.Append('[{"page":'+$s.metadata.page+',"pages":'+$s.metadata.pages+',"per_page":'+$s.metadata.per_page+',"total":'+$s.metadata.total+',"sourceid":"'+$s.metadata.sourceid+'","lastupdated":"'+$s.metadata.lastupdated+'"},[') | Out-Null
for ($i=0;$i -lt $s.total_records;$i++) {
    if ($i -gt 0) { $sb.Append(',') | Out-Null }
    $ci=$ctryIdx[$i]; $ct=$ctries[$ci]
    $sb.Append('{"indicator":{"id":"'+$s.indicator_id+'","value":"'+$s.indicator_value+'"},"country":{"id":"'+$ct.id+'","value":"'+$ct.value+'"},"countryiso3code":"'+$ct.iso3+'","date":"'+$dates[$i]+'","value":'+$vals[$i]+',"unit":"","obs_status":"","decimal":'+$decs[$i]+'}') | Out-Null
}
$sb.Append(']]') | Out-Null
[System.IO.File]::WriteAllBytes($OutputFile, $utf8.GetBytes($sb.ToString()))