[CmdletBinding()]
param(
    [string]$PipeName    = 'TEIA-AION-RISPA-v1',
    [long]$ExpectedBytes = 4194304
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Conectar ao Named Pipe (aguarda ate 30s o servidor estar disponivel)
$pipe = [System.IO.Pipes.NamedPipeClientStream]::new(
    '.', $PipeName, [System.IO.Pipes.PipeDirection]::In)
$pipe.Connect(30000)

$sha      = [System.Security.Cryptography.SHA256]::Create()
$buffer   = New-Object byte[] 65536
$totalBytes = 0L
$sw = [System.Diagnostics.Stopwatch]::StartNew()

try {
    while ($true) {
        $n = $pipe.Read($buffer, 0, $buffer.Length)
        if ($n -le 0) { break }
        $sha.TransformBlock($buffer, 0, $n, $null, 0) | Out-Null
        $totalBytes += $n
    }
    $sha.TransformFinalBlock((New-Object byte[] 0), 0, 0) | Out-Null
} finally {
    $pipe.Dispose()
}

$sw.Stop()

$hash = -join ($sha.Hash | ForEach-Object { $_.ToString('x2') })
$sha.Dispose()

$throughputMBs = if ($sw.ElapsedMilliseconds -gt 0) {
    [Math]::Round($totalBytes / 1MB / ($sw.ElapsedMilliseconds / 1000.0), 2)
} else { 0.0 }

[PSCustomObject]@{
    BytesRecebidos = $totalBytes
    SHA256         = $hash
    ElapsedMs      = $sw.ElapsedMilliseconds
    ThroughputMBs  = $throughputMBs
}
