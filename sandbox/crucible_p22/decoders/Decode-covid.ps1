#Requires -Version 7
[CmdletBinding()]
param([string]$SeedMetaFile, [string]$SeedBinFile, [string]$OutputFile)
$utf8 = [System.Text.UTF8Encoding]::new($false)
$s = Get-Content $SeedMetaFile -Raw | ConvertFrom-Json
$dates = @(); $base = [datetime]::Parse($s.date_start)
for ($i=0;$i -lt $s.date_count;$i++) { $dates += $base.AddDays($i).ToString('yyyy-MM-dd') }
$bin = [System.IO.File]::ReadAllBytes($SeedBinFile)
$ms  = New-Object System.IO.MemoryStream($bin,0,$bin.Length)
$bs  = New-Object System.IO.Compression.BrotliStream($ms,[System.IO.Compression.CompressionMode]::Decompress)
$o   = New-Object System.IO.MemoryStream; $bs.CopyTo($o); $bs.Dispose()
$orgArr = $utf8.GetString($o.ToArray()) -split '
'
$nl = if ($s.newline -eq 'crlf') { "
" } else { "
" }
$sw = [System.IO.StreamWriter]::new($OutputFile, $false, $utf8)
$sw.Write($s.header + $nl)
$idx = 0
foreach ($country in $s.countries) { foreach ($date in $dates) { $sw.Write("$date,$country,$($orgArr[$idx])$nl"); $idx++ } }
$sw.Close()