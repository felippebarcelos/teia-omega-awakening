<#
.SYNOPSIS
    TEIA-Stream-OnDemand-v0300.ps1 — Restaurador por Streaming (Fase P6.0)

.DESCRIPTION
    Restaura um arquivo a partir do seu .teia_stub via leitura do CAS.

    O arquivo NÃO é carregado integralmente na RAM durante o processo.
    Todo I/O usa CopyTo(stream, 65536) — buffer fixo de 64 KB (OOM guard).

    Estratégias suportadas:
      gen.repeat         → geração procedural em chunks (sem I/O de leitura)
      gen.pattern        → geração procedural por chunks de padrão
      gen.parametric_mesh → decompressão Brotli em stream
      cmp.lzma           → decompressão GZip em stream (encoding real: gz)
      cmp.brotli         → decompressão Brotli em stream
      cas.raw            → cópia direta em stream

    Após restauro: verifica SHA-256 contra original_sha256 do stub.
    Em caso de falha de integridade: deleta o arquivo restaurado e reporta erro.

.PARAMETER StubPath
    Caminho do arquivo .teia_stub a restaurar.

.PARAMETER OutputPath
    Destino do arquivo restaurado.
    Padrão: StubPath com extensão .teia_stub removida (restauração in-place).

.PARAMETER KeepStub
    Mantém o .teia_stub após restauro bem-sucedido (não o deleta).
    Padrão: false (stub é removido após restauro verificado).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$StubPath,
    [string]$OutputPath  = '',
    [switch]$KeepStub
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC = [System.Globalization.CultureInfo]::InvariantCulture

# ── Validação do stub ─────────────────────────────────────────────────────────

if (-not (Test-Path -LiteralPath $StubPath)) {
    Write-Host "[STREAM] ERRO: stub nao encontrado: $StubPath" -ForegroundColor Red; exit 1
}
if ($StubPath -notmatch '\.teia_stub$') {
    Write-Host "[STREAM] ERRO: arquivo nao tem extensao .teia_stub: $StubPath" -ForegroundColor Red; exit 1
}

$stub = Get-Content -LiteralPath $StubPath -Raw -Encoding UTF8 | ConvertFrom-Json

if (-not $stub.original_sha256 -or -not $stub.cas_path -or -not $stub.final_strategy) {
    Write-Host "[STREAM] ERRO: stub malformado — campos obrigatorios ausentes." -ForegroundColor Red; exit 1
}

if (-not (Test-Path -LiteralPath $stub.cas_path)) {
    Write-Host "[STREAM] ERRO: artefato CAS nao encontrado: $($stub.cas_path)" -ForegroundColor Red; exit 1
}

# ── Caminho de saída ──────────────────────────────────────────────────────────

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = $StubPath -replace '\.teia_stub$', ''
}

if (Test-Path -LiteralPath $OutputPath) {
    Write-Host "[STREAM] AVISO: OutputPath já existe — será sobrescrito: $OutputPath" -ForegroundColor DarkYellow
}

# ── SHA-256 helpers ───────────────────────────────────────────────────────────

function Get-Sha256Stream([string]$Path) {
    $sha    = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($Path)
    $h      = $sha.ComputeHash($stream)
    $stream.Dispose(); $sha.Dispose()
    [BitConverter]::ToString($h).Replace('-','').ToLower()
}

# ── Restauradores por estratégia ──────────────────────────────────────────────

function Restore-GenRepeat([object]$Seed, [string]$OutPath) {
    $byteVal   = [Convert]::ToByte([string]$Seed.value_hex, 16)
    $remaining = [long]$Seed.size_bytes
    $chunkSize = 65536
    $outStream = [System.IO.File]::Create($OutPath)
    $chunk     = New-Object byte[] $chunkSize
    for ($i = 0; $i -lt $chunkSize; $i++) { $chunk[$i] = $byteVal }
    try {
        while ($remaining -gt 0) {
            $n = [Math]::Min($remaining, [long]$chunkSize)
            $outStream.Write($chunk, 0, [int]$n)
            $remaining -= $n
        }
    } finally {
        $outStream.Dispose()
    }
}

function Restore-GenPattern([object]$Seed, [string]$OutPath) {
    $pattern   = [Convert]::FromBase64String([string]$Seed.pattern_b64)
    $pLen      = $pattern.Length
    $remaining = [long]$Seed.size_bytes
    $chunkSize = 65536
    $outStream = [System.IO.File]::Create($OutPath)
    $buf       = New-Object byte[] $chunkSize
    $offset    = 0L
    try {
        while ($remaining -gt 0) {
            $n = [int][Math]::Min($remaining, [long]$chunkSize)
            for ($i = 0; $i -lt $n; $i++) { $buf[$i] = $pattern[($offset + $i) % $pLen] }
            $outStream.Write($buf, 0, $n)
            $remaining -= $n; $offset += $n
        }
    } finally {
        $outStream.Dispose()
    }
}

function Restore-Brotli([string]$CasPath, [string]$OutPath) {
    $inStream  = [System.IO.File]::OpenRead($CasPath)
    $brStream  = New-Object System.IO.Compression.BrotliStream(
                     $inStream, [System.IO.Compression.CompressionMode]::Decompress)
    $outStream = [System.IO.File]::Create($OutPath)
    try {
        $brStream.CopyTo($outStream, 65536)
    } finally {
        $brStream.Dispose(); $inStream.Dispose(); $outStream.Dispose()
    }
}

function Restore-Gzip([string]$CasPath, [string]$OutPath) {
    $inStream  = [System.IO.File]::OpenRead($CasPath)
    $gzStream  = New-Object System.IO.Compression.GZipStream(
                     $inStream, [System.IO.Compression.CompressionMode]::Decompress)
    $outStream = [System.IO.File]::Create($OutPath)
    try {
        $gzStream.CopyTo($outStream, 65536)
    } finally {
        $gzStream.Dispose(); $inStream.Dispose(); $outStream.Dispose()
    }
}

function Restore-RawStream([string]$CasPath, [string]$OutPath) {
    $inStream  = [System.IO.File]::OpenRead($CasPath)
    $outStream = [System.IO.File]::Create($OutPath)
    try {
        $inStream.CopyTo($outStream, 65536)
    } finally {
        $inStream.Dispose(); $outStream.Dispose()
    }
}

# ── Main ──────────────────────────────────────────────────────────────────────

$sw           = [System.Diagnostics.Stopwatch]::StartNew()
$restoredSize = [long]0

Write-Host ''
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host '  TEIA-Stream-OnDemand v0.30.0 — Restauro por Streaming' -ForegroundColor Cyan
Write-Host ('─' * 78)
Write-Host ("  Stub            : $(Split-Path $StubPath -Leaf)")
Write-Host ("  Arquivo         : $($stub.original_name)")
Write-Host ("  Estratégia      : $($stub.final_strategy)")
Write-Host ("  Original SHA-256: $($stub.original_sha256.Substring(0,16))...")
Write-Host ("  Original tamanho: $([math]::Round([long]$stub.original_size_bytes / 1KB, 1)) KB")
Write-Host ("  CAS artefato    : $(Split-Path $stub.cas_path -Leaf)  ($([math]::Round([long]$stub.cas_size_bytes / 1KB, 1)) KB)")
Write-Host ("  Output          : $OutputPath")
Write-Host ("  OOM guard       : buffer 64KB por operacao de stream")
Write-Host ('─' * 78)
Write-Host ''
Write-Host ("  Restaurando via $($stub.final_strategy)...") -ForegroundColor Yellow

$restoreOk = $false
$errMsg    = ''

try {
    switch ($stub.final_strategy) {

        'gen.repeat' {
            $seed = Get-Content -LiteralPath $stub.cas_path -Raw -Encoding UTF8 | ConvertFrom-Json
            Write-Host ("  [gen.repeat] byte=0x$($seed.value_hex.ToUpper()) × $($seed.size_bytes) — stream procedural")
            Restore-GenRepeat -Seed $seed -OutPath $OutputPath
        }

        'gen.pattern' {
            $seed = Get-Content -LiteralPath $stub.cas_path -Raw -Encoding UTF8 | ConvertFrom-Json
            Write-Host ("  [gen.pattern] period=$($seed.period_bytes)B × $($seed.repeat) — stream procedural")
            Restore-GenPattern -Seed $seed -OutPath $OutputPath
        }

        'gen.parametric_mesh' {
            # Artefato CAS é Brotli-compressed (preserva SHA-256 original)
            Write-Host ("  [gen.parametric_mesh] Brotli-decompress → OBJ original")
            if ($stub.parametric_seed) {
                Write-Host ("    seed: $($stub.parametric_seed.primitive_type) | $($stub.parametric_seed.algorithm)") -ForegroundColor DarkGray
            }
            Restore-Brotli -CasPath $stub.cas_path -OutPath $OutputPath
        }

        'cmp.lzma' {
            # Encoding real: GZip (.gz) — melhor disponível em .NET BCL
            Write-Host ("  [cmp.lzma → GZip] decompressao por stream (64KB chunks)")
            Restore-Gzip -CasPath $stub.cas_path -OutPath $OutputPath
        }

        'cmp.brotli' {
            Write-Host ("  [cmp.brotli] Brotli-decompress por stream (64KB chunks)")
            Restore-Brotli -CasPath $stub.cas_path -OutPath $OutputPath
        }

        default {
            # cas.raw — stream copy
            Write-Host ("  [cas.raw] copia por stream (64KB chunks)")
            Restore-RawStream -CasPath $stub.cas_path -OutPath $OutputPath
        }
    }

    $sw.Stop()

    if (-not (Test-Path -LiteralPath $OutputPath)) {
        throw "OutputPath nao foi criado: $OutputPath"
    }

    # ── Verificação SHA-256 ───────────────────────────────────────────────────
    Write-Host ''
    Write-Host '  Verificando SHA-256...' -ForegroundColor White
    $restoredSha  = Get-Sha256Stream -Path $OutputPath
    $restoredSize = (Get-Item -LiteralPath $OutputPath).Length
    $match        = ($restoredSha -eq $stub.original_sha256)

    Write-Host ("    Esperado : $($stub.original_sha256)")
    Write-Host ("    Obtido   : $restoredSha")

    if ($match) {
        Write-Host ("    RESULTADO: SHA-256 OK — arquivo identico ao original") -ForegroundColor Green
        $restoreOk = $true
    } else {
        Write-Host ("    RESULTADO: SHA-256 DIVERGENTE — restauro com falha de integridade") -ForegroundColor Red
        Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue
        $errMsg = "SHA-256 mismatch: esperado=$($stub.original_sha256) obtido=$restoredSha"
    }

} catch {
    $sw.Stop()
    $errMsg = $_.Exception.Message
    Write-Host ("  FALHA: $errMsg") -ForegroundColor Red
    if (Test-Path -LiteralPath $OutputPath) {
        Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue
    }
}

# ── Relatório final ───────────────────────────────────────────────────────────

Write-Host ''
Write-Host ('─' * 78)
Write-Host ("  Tempo de restauro : $($sw.ElapsedMilliseconds) ms")
Write-Host ("  Tamanho restaurado: $([math]::Round($restoredSize/1KB,1)) KB" ) -ForegroundColor $(if ($restoreOk) {'Green'} else {'Red'})
Write-Host ("  Throughput stream : $( if ($sw.ElapsedMilliseconds -gt 0) { [math]::Round($restoredSize / $sw.ElapsedMilliseconds * 1000 / 1MB, 1) } else {'∞'} ) MB/s")
Write-Host ("  RAM máxima usada  : ≤ 64 KB por chunk (OOM guard ativo — sem ReadAllBytes)")
Write-Host ''

if ($restoreOk) {
    if (-not $KeepStub) {
        Remove-Item -LiteralPath $StubPath -Force
        Write-Host ("  Stub removido: $(Split-Path $StubPath -Leaf)") -ForegroundColor DarkGray
    } else {
        Write-Host ("  Stub mantido (KeepStub=true): $(Split-Path $StubPath -Leaf)") -ForegroundColor DarkGray
    }
    Write-Host ''
    Write-Host ("  [RESTORE OK] $($stub.original_name) — identico ao original.") -ForegroundColor Green
    Write-Host ('=' * 78)
    exit 0
} else {
    Write-Host ("  [RESTORE FAIL] $errMsg") -ForegroundColor Red
    Write-Host ('=' * 78)
    exit 2
}
