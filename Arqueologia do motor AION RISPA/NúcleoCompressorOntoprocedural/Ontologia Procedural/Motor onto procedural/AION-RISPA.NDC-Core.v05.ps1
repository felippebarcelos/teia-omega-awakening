param(
  [string]$Mode = 'expand',
  [string]$Core
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-MimeFromHeader([byte[]]$Bytes){
  if($Bytes.Length -lt 12){ return 'bin' }
  $b = $Bytes
  if($b[0] -eq 0x89 -and $b[1] -eq 0x50 -and $b[2] -eq 0x4E -and $b[3] -eq 0x47){ return 'image/png' }
  if($b[0] -eq 0x50 -and $b[1] -eq 0x4B -and $b[2] -eq 0x03 -and $b[3] -eq 0x04){ return 'application/zip' }
  if($b[4] -eq 0x66 -and $b[5] -eq 0x74 -and $b[6] -eq 0x79 -and $b[7] -eq 0x70){ return 'video/mp4' }
  if($b[0] -eq 0x4D -and $b[1] -eq 0x5A){ return 'application/x-msdownload' } # MZ
  if($b[0] -eq 0x52 -and $b[1] -eq 0x49 -and $b[2] -eq 0x46 -and $b[3] -eq 0x46){ return 'audio/wav' }
  'bin'
}

function Expand-NDC([byte[]]$CoreBytes){
  $mime = Get-MimeFromHeader $CoreBytes
  $patterns = @(
    [pscustomobject]@{ name='PNG'; sig='89 50 4E 47'; mime='image/png' },
    [pscustomobject]@{ name='ZIP'; sig='50 4B 03 04'; mime='application/zip' },
    [pscustomobject]@{ name='MP4'; sig='.. .. 66 74 79 70'; mime='video/mp4' },
    [pscustomobject]@{ name='EXE'; sig='4D 5A'; mime='application/x-msdownload' },
    [pscustomobject]@{ name='WAV'; sig='52 49 46 46'; mime='audio/wav' }
  )
  [pscustomobject]@{
    v = '0.5.2'
    mime = $mime
    patterns = $patterns
  }
}

switch($Mode){
  'expand' {
    if(-not $Core){ $Core = (Join-Path $PWD 'core.bin') }
    if(Test-Path -LiteralPath $Core){
      $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Core))
    } else {
      $bytes = [byte[]]@(0)
    }
    $out = Expand-NDC -CoreBytes $bytes
    $json = $out | ConvertTo-Json -Depth 6 -Compress
    Write-Output $json
  }
  default { throw "Unknown -Mode: $Mode" }
}

