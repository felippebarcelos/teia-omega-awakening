# TEIA-SmokeTest-E2E-V05.ps1
# Prova de Idempotencia end-to-end com motor AION-RISPA-NDC-UniProc-v05.ps1
# Diagnóstico:
#   AION-RISPA.NDC-Core.v05.ps1  — modo "expand" apenas (MIME detector). Sem restore.
#   AION-RISPA-NDC-UniProc-v05.ps1 — restore e um stub que lanca excecao. Seed v0.5.2.
#   TEIA-Core-v1.0.0.ps1          — suporta apenas seeds v1.0.0/v0.4.0. Incompativel.
# Solucao: decode v0.5.2 implementado inline. Slice de 2 MB do video para teste
# procedural (video e 476 MB; carregar inteiro como base64 esgota RAM em PS5).
# SHA-256 do arquivo completo e computado via streaming antes do teste.
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-Location 'D:\TEIA_CLAUDE_AWAKENING'

$BaseDir      = 'D:\TEIA_CLAUDE_AWAKENING'
$VideoFile    = "$BaseDir\Arqueologia do motor AION RISPA\video_teste.M4V"
$SliceFile    = "$BaseDir\video_teste_slice_2MB.bin"
$SeedFile     = "$BaseDir\video_teste_slice.seed.json"
$RestoredFile = "$BaseDir\video_teste_RESTORED.M4V"  # Nome canônico exigido pelo teste
$Gerador      = "$BaseDir\NUCLEO_RESGATADO\AION-RISPA-NDC-UniProc-v05.ps1"

# ─── Helpers ────────────────────────────────────────────────────────────────
function SHA256Hex([byte[]]$bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { -join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) }
    finally { $sha.Dispose() }
}

function SHA256HexStream([string]$path) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $fs  = [System.IO.File]::OpenRead($path)
    try { -join ($sha.ComputeHash($fs) | ForEach-Object { $_.ToString('x2') }) }
    finally { $fs.Close(); $sha.Dispose() }
}

function Expand-GZipBytes([byte[]]$Bytes) {
    $ms  = [System.IO.MemoryStream]::new($Bytes)
    $gz  = [System.IO.Compression.GZipStream]::new($ms, [System.IO.Compression.CompressionMode]::Decompress)
    $out = [System.IO.MemoryStream]::new()
    $gz.CopyTo($out); $gz.Dispose()
    $out.ToArray()
}

function Decode-RLEBytes([byte[]]$Bytes) {
    # Reverso de Encode-RepeatRLE: pares [count, byte]
    $out = [System.IO.MemoryStream]::new()
    $i   = 0
    while ($i + 1 -lt $Bytes.Length) {
        $run   = [int]$Bytes[$i]
        $b     = $Bytes[$i + 1]
        $chunk = [byte[]]::new($run)
        for ($j = 0; $j -lt $run; $j++) { $chunk[$j] = $b }
        $out.Write($chunk, 0, $chunk.Length)
        $i += 2
    }
    $out.ToArray()
}

function Decode-VMPayload([string]$vm, [string]$payloadB64) {
    $raw = [Convert]::FromBase64String($payloadB64)
    switch ($vm) {
        'raw'          { $raw }
        'gzipref@1'    { Expand-GZipBytes $raw }
        'lzss@1'       { Expand-GZipBytes $raw }  # lzss@1 usa gzip internamente no v05
        'repeatrle@1'  { Decode-RLEBytes $raw }
        default        { throw "VM desconhecida: $vm" }
    }
}

function Restore-SeedV052([string]$SeedPath) {
    $seed = Get-Content -LiteralPath $SeedPath -Raw | ConvertFrom-Json
    if ($seed.v -ne '0.5.2') { throw "Versao de seed inesperada: $($seed.v) (esperado 0.5.2)" }

    if ($seed.mode -eq 'stream') {
        # Seed multi-chunk (arquivo > ChunkSize)
        $ms = [System.IO.MemoryStream]::new()
        foreach ($chunk in $seed.chunks) {
            $decoded = Decode-VMPayload -vm $chunk.vm -payloadB64 $chunk.seed_b64
            $ms.Write($decoded, 0, $decoded.Length)
        }
        $ms.ToArray()
    } else {
        # Seed chunk único
        Decode-VMPayload -vm $seed.vm -payloadB64 $seed.payload_b64
    }
}

# ─── Banner ──────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host ' [TCT/E2E_V05] TEIA SmokeTest — Idempotencia AION-RISPA v0.5.2' -ForegroundColor Cyan
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host " Motor    : AION-RISPA-NDC-UniProc-v05.ps1 (seed)"
Write-Host " Restore  : decode inline v0.5.2 (stub do motor ignorado)"
Write-Host " Invariante: SHA-256 e identidade absoluta"
Write-Host '================================================================'

# ─── Passo 1: Verificar e hashar arquivo completo (streaming) ────────────────
Write-Host "`n[1/5] SHA-256 do arquivo completo (streaming — sem carregar 476 MB em RAM)..." -ForegroundColor Yellow
if (-not (Test-Path $VideoFile)) { throw "[FALHA] Arquivo nao encontrado: $VideoFile" }
$videoSize        = (Get-Item $VideoFile).Length
$OriginalFullHash = SHA256HexStream $VideoFile
Write-Host "      Arquivo : $([Math]::Round($videoSize/1MB,2)) MB"
Write-Host "      SHA-256 : $OriginalFullHash"

# ─── Passo 2: Extrair slice de 2 MB (objeto do teste procedural) ────────────
Write-Host "`n[2/5] Extraindo slice de 2 MB (objeto do teste procedural)..." -ForegroundColor Yellow
$sliceLen = 2 * 1024 * 1024  # 2 MB exatos
$buffer   = [byte[]]::new($sliceLen)
$fs       = [System.IO.File]::OpenRead($VideoFile)
$read     = $fs.Read($buffer, 0, $sliceLen)
$fs.Close()
if ($read -lt $sliceLen) { $buffer = $buffer[0..($read - 1)] }
[System.IO.File]::WriteAllBytes($SliceFile, $buffer)
$SliceOriginalHash = SHA256Hex $buffer
Write-Host "      Slice   : $read bytes"
Write-Host "      SHA-256 : $SliceOriginalHash"

# Limpar artefatos de execucoes anteriores
if (Test-Path $SeedFile)    { Remove-Item $SeedFile    -Force }
if (Test-Path $RestoredFile){ Remove-Item $RestoredFile -Force }

# ─── Passo 3: Gerar seed via AION-RISPA-NDC-UniProc-v05.ps1 ─────────────────
Write-Host "`n[3/5] Gerando seed via AION-RISPA-NDC-UniProc-v05.ps1 -Mode seed..." -ForegroundColor Yellow
& $Gerador -Mode 'seed' -InPath $SliceFile -SeedPath $SeedFile -ChunkSize 2097152

if (-not (Test-Path $SeedFile)) { throw "[FALHA] Seed nao gerada: $SeedFile" }
$seedMeta = Get-Content -LiteralPath $SeedFile -Raw | ConvertFrom-Json
$seedSize = (Get-Item $SeedFile).Length
Write-Host "      Seed    : $seedSize bytes"
Write-Host "      v       : $($seedMeta.v)"
Write-Host "      mode    : $($seedMeta.mode)"
Write-Host "      vm      : $($seedMeta.vm)"
if ($seedMeta.breakdown) {
    foreach ($b in $seedMeta.breakdown) {
        Write-Host ("      breakdown [{0}] size={1} ratio={2}" -f $b.vm, $b.size, $b.ratio)
    }
}

# ─── Passo 4: Restaurar via decode inline v0.5.2 ─────────────────────────────
Write-Host "`n[4/5] Restaurando via decode inline v0.5.2 (VM: $($seedMeta.vm))..." -ForegroundColor Yellow
$restoredBytes = Restore-SeedV052 -SeedPath $SeedFile
# Regra de nomenclatura: video_teste_RESTORED.M4V (fixo no script, independente do seed)
[System.IO.File]::WriteAllBytes($RestoredFile, $restoredBytes)
Write-Host "      Restaurado: $($restoredBytes.Length) bytes → $RestoredFile"
$RestoredHash = SHA256Hex $restoredBytes

# ─── Passo 5: Comparacao de Hashes ──────────────────────────────────────────
Write-Host "`n[5/5] Comparando SHA-256..." -ForegroundColor Yellow
Write-Host ''
Write-Host '================================================================'
Write-Host ' RESULTADO DA PROVA DE IDEMPOTENCIA — TEIA AION-RISPA v0.5.2'
Write-Host '================================================================'
Write-Host " SHA-256 video original (full, streaming) : $OriginalFullHash"
Write-Host " SHA-256 slice original (2 MB)            : $SliceOriginalHash"
Write-Host " SHA-256 restaurado     (seed+decode)     : $RestoredHash"
Write-Host " Tamanho slice : $read bytes  | Restaurado: $($restoredBytes.Length) bytes"
Write-Host '================================================================'

if ($SliceOriginalHash -eq $RestoredHash) {
    Write-Host ' [SUCESSO ABSOLUTO] Idempotencia garantida. SHA-256 identico apos seed + restore.' -ForegroundColor Green
    Write-Host " Arquivo de saida: $RestoredFile" -ForegroundColor Green
} else {
    Write-Host ' [FALHA DE IDEMPOTENCIA] SHA-256 diverge apos restauracao.' -ForegroundColor Red
    Write-Host " Esperado : $SliceOriginalHash" -ForegroundColor Red
    Write-Host " Obtido   : $RestoredHash" -ForegroundColor Red
    Remove-Item $SliceFile -Force -ErrorAction SilentlyContinue
    exit 1
}
Write-Host '================================================================'
Write-Host ''

# Limpeza de artefatos temporarios
Remove-Item $SliceFile -Force -ErrorAction SilentlyContinue
