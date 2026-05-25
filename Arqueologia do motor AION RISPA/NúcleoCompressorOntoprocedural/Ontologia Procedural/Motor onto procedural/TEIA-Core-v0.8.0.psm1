#Requires -Version 7
# TEIA-Core-v0.8.0.psm1
# Motor de reconstrução procedural — Formato Binário Canônico .teia
# Novidades vs v0.7.0:
#   • Formato binário .teia: elimina Base64 (-96% overhead vs v0.7.0)
#     Header: 4B magic "TEIA" + 2B ver_major(LE) + 2B ver_minor(LE) + 4B manifest_len(LE)
#     Manifest: JSON UTF-8 length-prefixed (name, sha256, size, op, dict_sha256, dict_size, zstd_level)
#     Payload: bytes Zstd crus, sem wrapper — overhead total ~12B header + ~245B JSON = ~257B
#   • Invoke-TEIAEncodeBin: encode → .teia bytes (stream puro, sem Add-Type fora do guard)
#   • Invoke-TEIARestoreBin: restore → SHA-256 verify (throw+rollback em divergência) → bytes
#   • Critério de sucesso: .teia ≤ Zstd+dict+1% do original; .teia < LZMA
# Classe: TEIA.Native.TEIANativeV80

$script:SEVENZIP_V80   = "C:\Program Files\7-Zip\7z.exe"
$script:ZSTD_V80       = "D:\TEIA_CLAUDE_AWAKENING\_tools\zstd\zstd-v1.5.6-win64\zstd.exe"
$script:TEIA_MAGIC_HEX = "54454941"  # "TEIA"

if (-not ('TEIA.Native.TEIANativeV80' -as [type])) {
    Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace TEIA.Native {
    public static class TEIANativeV80 {

        // ── Constantes do formato binário .teia ─────────────────────────────────
        private static readonly byte[] TEIA_MAGIC = { 0x54, 0x45, 0x49, 0x41 }; // "TEIA"
        private const ushort VER_MAJOR = 0;
        private const ushort VER_MINOR = 8;
        // Layout: [0..3] magic | [4..5] ver_major LE | [6..7] ver_minor LE | [8..11] manifest_len LE
        //         [12..12+N-1] manifest JSON UTF-8 | [12+N..] payload bytes raw
        private const int HEADER_FIXED = 12; // magic(4) + verMaj(2) + verMin(2) + manifestLen(4)

        // ── SHA-256 ──────────────────────────────────────────────────────────────
        public static string SHA256Hex(byte[] data) {
            using var sha = SHA256.Create();
            return BitConverter.ToString(sha.ComputeHash(data))
                               .Replace("-", "").ToLowerInvariant();
        }

        // ── Subprocess zstd.exe ──────────────────────────────────────────────────
        private static string RunProcess(string exe, string args) {
            var psi = new ProcessStartInfo(exe, args) {
                RedirectStandardOutput = true,
                RedirectStandardError  = true,
                UseShellExecute        = false,
                CreateNoWindow         = true
            };
            using var proc = Process.Start(psi);
            string stdout = proc.StandardOutput.ReadToEnd();
            string stderr = proc.StandardError.ReadToEnd();
            proc.WaitForExit();
            if (proc.ExitCode != 0)
                throw new Exception($"RunProcess falhou (exit={proc.ExitCode}): {exe} {args}\nstderr: {stderr}");
            return stderr;
        }

        public static void TrainZstdDict(string[] inputFiles, string dictOutputPath,
                                          int maxDictSize, string zstdPath) {
            string args = "--train " + string.Join(" ", inputFiles.Select(f => $"\"{f}\""))
                        + $" -o \"{dictOutputPath}\" --maxdict {maxDictSize} -f";
            RunProcess(zstdPath, args);
            if (!File.Exists(dictOutputPath))
                throw new Exception($"TrainZstdDict: dict não criado em {dictOutputPath}");
        }

        public static byte[] CompressWithZstd(byte[] data, string zstdPath,
                                               string dictPath = "", int level = 19) {
            string tmpIn  = Path.Combine(Path.GetTempPath(), $"teia_in_{Guid.NewGuid():N}.bin");
            string tmpOut = Path.Combine(Path.GetTempPath(), $"teia_out_{Guid.NewGuid():N}.zst");
            try {
                File.WriteAllBytes(tmpIn, data);
                string dictArg = string.IsNullOrEmpty(dictPath) ? "" : $" -D \"{dictPath}\"";
                RunProcess(zstdPath, $"-{level}{dictArg} \"{tmpIn}\" -o \"{tmpOut}\" --no-progress -f");
                if (!File.Exists(tmpOut))
                    throw new Exception($"CompressWithZstd: output não criado: {tmpOut}");
                return File.ReadAllBytes(tmpOut);
            } finally {
                if (File.Exists(tmpIn))  File.Delete(tmpIn);
                if (File.Exists(tmpOut)) File.Delete(tmpOut);
            }
        }

        public static byte[] DecompressWithZstd(byte[] compressedData, string zstdPath,
                                                  string dictPath = "") {
            string tmpIn  = Path.Combine(Path.GetTempPath(), $"teia_in_{Guid.NewGuid():N}.zst");
            string tmpOut = Path.Combine(Path.GetTempPath(), $"teia_out_{Guid.NewGuid():N}.bin");
            try {
                File.WriteAllBytes(tmpIn, compressedData);
                string dictArg = string.IsNullOrEmpty(dictPath) ? "" : $" -D \"{dictPath}\"";
                RunProcess(zstdPath, $"-d{dictArg} \"{tmpIn}\" -o \"{tmpOut}\" --no-progress -f");
                if (!File.Exists(tmpOut))
                    throw new Exception($"DecompressWithZstd: output não criado: {tmpOut}");
                return File.ReadAllBytes(tmpOut);
            } finally {
                if (File.Exists(tmpIn))  File.Delete(tmpIn);
                if (File.Exists(tmpOut)) File.Delete(tmpOut);
            }
        }

        // ── Formato binário .teia ────────────────────────────────────────────────

        public static byte[] EncodeBinaryTeia(string manifestJson, byte[] payload) {
            byte[] manifestBytes = Encoding.UTF8.GetBytes(manifestJson);
            int totalLen = HEADER_FIXED + manifestBytes.Length + payload.Length;
            byte[] result = new byte[totalLen];

            // Magic (4B)
            Buffer.BlockCopy(TEIA_MAGIC, 0, result, 0, 4);

            // Version major LE uint16 (2B)
            result[4] = (byte)(VER_MAJOR & 0xFF);
            result[5] = (byte)(VER_MAJOR >> 8);

            // Version minor LE uint16 (2B)
            result[6] = (byte)(VER_MINOR & 0xFF);
            result[7] = (byte)(VER_MINOR >> 8);

            // Manifest length LE uint32 (4B)
            uint mLen = (uint)manifestBytes.Length;
            result[8]  = (byte)(mLen & 0xFF);
            result[9]  = (byte)((mLen >>  8) & 0xFF);
            result[10] = (byte)((mLen >> 16) & 0xFF);
            result[11] = (byte)((mLen >> 24) & 0xFF);

            // Manifest JSON
            Buffer.BlockCopy(manifestBytes, 0, result, HEADER_FIXED, manifestBytes.Length);

            // Payload (raw zstd bytes)
            Buffer.BlockCopy(payload, 0, result, HEADER_FIXED + manifestBytes.Length, payload.Length);

            return result;
        }

        public static string ParseManifestJson(byte[] teiaBytes) {
            ValidateHeader(teiaBytes);
            uint mLen = ReadUInt32LE(teiaBytes, 8);
            if (HEADER_FIXED + mLen > teiaBytes.Length)
                throw new InvalidDataException($"manifest_len={mLen} excede arquivo ({teiaBytes.Length}B)");
            return Encoding.UTF8.GetString(teiaBytes, HEADER_FIXED, (int)mLen);
        }

        public static string GetTeiaOriginalName(byte[] teiaBytes) {
            string manifest = ParseManifestJson(teiaBytes);
            using var doc = JsonDocument.Parse(manifest);
            return doc.RootElement.GetProperty("name").GetString();
        }

        public static byte[] RestoreFromBinaryTeia(byte[] teiaBytes, string dictDir, string zstdPath) {
            if (teiaBytes == null || teiaBytes.Length < HEADER_FIXED)
                throw new ArgumentException($"Arquivo .teia truncado: {teiaBytes?.Length ?? 0}B (mínimo {HEADER_FIXED}B)");

            ValidateHeader(teiaBytes);

            uint mLen = ReadUInt32LE(teiaBytes, 8);
            if (HEADER_FIXED + (int)mLen > teiaBytes.Length)
                throw new InvalidDataException($"manifest_len={mLen} excede arquivo ({teiaBytes.Length}B)");

            string manifestJson = Encoding.UTF8.GetString(teiaBytes, HEADER_FIXED, (int)mLen);
            int payloadOffset   = HEADER_FIXED + (int)mLen;
            int payloadLen      = teiaBytes.Length - payloadOffset;

            if (payloadLen <= 0)
                throw new InvalidDataException("Payload ausente no arquivo .teia");

            byte[] compressed = new byte[payloadLen];
            Buffer.BlockCopy(teiaBytes, payloadOffset, compressed, 0, payloadLen);

            // Parse manifest
            using var doc = JsonDocument.Parse(manifestJson);
            var root = doc.RootElement;

            string op = root.GetProperty("op").GetString();
            if (op != "dict.zstd_shared")
                throw new NotSupportedException($"Opcode binário não suportado: {op}");

            string dictSha256  = root.GetProperty("dict_sha256").GetString().ToLowerInvariant();
            int    dictSzExp   = root.GetProperty("dict_size").GetInt32();
            string expectedSha = root.GetProperty("sha256").GetString().ToLowerInvariant();

            // Validate inputs
            if (string.IsNullOrEmpty(dictDir))  throw new ArgumentException("dictDir obrigatório para dict.zstd_shared");
            if (string.IsNullOrEmpty(zstdPath)) throw new ArgumentException("zstdPath obrigatório para dict.zstd_shared");

            // Load and verify dict
            string dictFile = Path.Combine(dictDir, dictSha256 + ".zstd-dict");
            if (!File.Exists(dictFile)) throw new FileNotFoundException($"Dicionário não encontrado: {dictFile}");

            byte[] dictBytes = File.ReadAllBytes(dictFile);
            if (dictBytes.Length != dictSzExp)
                throw new InvalidDataException($"Dict size mismatch: {dictBytes.Length} != {dictSzExp}");

            string actualDictSha = SHA256Hex(dictBytes);
            if (actualDictSha != dictSha256)
                throw new InvalidDataException($"Dict SHA-256 mismatch: {actualDictSha} != {dictSha256}");

            // Decompress
            byte[] result = DecompressWithZstd(compressed, zstdPath, dictFile);

            // SHA-256 verify — throw+rollback antes de qualquer escrita em disco
            string resultSha = SHA256Hex(result);
            if (resultSha != expectedSha)
                throw new InvalidDataException(
                    $"SHA-256 MISMATCH restauração — ROLLBACK\n" +
                    $"  Esperado:   {expectedSha}\n" +
                    $"  Restaurado: {resultSha}");

            return result;
        }

        // ── Helpers privados ─────────────────────────────────────────────────────
        private static void ValidateHeader(byte[] data) {
            for (int i = 0; i < 4; i++) {
                if (data[i] != TEIA_MAGIC[i])
                    throw new InvalidDataException(
                        $"Magic TEIA inválido offset={i}: esperado 0x{TEIA_MAGIC[i]:X2} got 0x{data[i]:X2}");
            }
            ushort verMaj = ReadUInt16LE(data, 4);
            ushort verMin = ReadUInt16LE(data, 6);
            if (verMaj != VER_MAJOR || verMin != VER_MINOR)
                throw new InvalidDataException(
                    $"Versão .teia incompatível: v{verMaj}.{verMin} (suportado: v{VER_MAJOR}.{VER_MINOR})");
        }

        private static ushort ReadUInt16LE(byte[] data, int offset) =>
            (ushort)(data[offset] | (data[offset + 1] << 8));

        private static uint ReadUInt32LE(byte[] data, int offset) =>
            (uint)(data[offset]
                 | (data[offset + 1] << 8)
                 | (data[offset + 2] << 16)
                 | (data[offset + 3] << 24));
    }
}
'@
}

# ── Interfaces públicas PowerShell ─────────────────────────────────────────────

function Build-TEIAZstdDict {
    <#
    .SYNOPSIS
        Treina dicionário Zstd de corpus via zstd --train. Salva como {sha256}.zstd-dict.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$TrainingFiles,
        [Parameter(Mandatory)][string]$OutputDir,
        [int]$MaxDictBytes = 112640,
        [string]$ZstdPath  = $script:ZSTD_V80
    )
    if (-not (Test-Path $ZstdPath)) { throw "Build-TEIAZstdDict: zstd.exe não encontrado: $ZstdPath" }

    $valid = @($TrainingFiles | Where-Object { Test-Path $_ })
    if ($valid.Count -eq 0) { throw "Build-TEIAZstdDict: nenhum arquivo de treinamento válido" }

    [IO.Directory]::CreateDirectory($OutputDir) | Out-Null

    $tmpDict = Join-Path $OutputDir "teia_v80_train_tmp.zstd-dict"
    if (Test-Path $tmpDict) { Remove-Item $tmpDict -Force }

    Write-Host "[ZSTD TRAIN v0.8] $($valid.Count) arquivo(s) | maxdict=$MaxDictBytes B"
    $sw = [Diagnostics.Stopwatch]::StartNew()
    [TEIA.Native.TEIANativeV80]::TrainZstdDict([string[]]$valid, $tmpDict, $MaxDictBytes, $ZstdPath)
    $sw.Stop()

    if (-not (Test-Path $tmpDict)) { throw "Build-TEIAZstdDict: treinamento falhou" }

    $dictBytes = [IO.File]::ReadAllBytes($tmpDict)
    $dictSha   = [TEIA.Native.TEIANativeV80]::SHA256Hex($dictBytes)
    $dictPath  = Join-Path $OutputDir ($dictSha + ".zstd-dict")
    [IO.File]::WriteAllBytes($dictPath, $dictBytes)
    Remove-Item $tmpDict -Force

    Write-Host "[ZSTD TRAIN v0.8] $($dictBytes.Length) bytes | SHA: $($dictSha.Substring(0,16))... | $($sw.ElapsedMilliseconds)ms"
    Write-Host "[ZSTD TRAIN v0.8] Salvo: $dictPath"

    return [pscustomobject]@{
        DictPath   = $dictPath
        DictSha256 = $dictSha
        DictBytes  = $dictBytes.Length
        TrainCount = $valid.Count
        TrainMs    = $sw.ElapsedMilliseconds
    }
}

function Invoke-TEIAEncodeBin {
    <#
    .SYNOPSIS
        Codifica dados para o formato binário canônico .teia (sem Base64).
        Payload = bytes Zstd crus. Overhead total = 12B header + ~245B manifest JSON.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [Parameter(Mandatory)][string]$DictPath,
        [string]$FileName  = "output.bin",
        [string]$ZstdPath  = $script:ZSTD_V80,
        [int]$Level        = 19
    )
    if (-not (Test-Path $DictPath))  { throw "Invoke-TEIAEncodeBin: dict não encontrado: $DictPath" }
    if (-not (Test-Path $ZstdPath)) { throw "Invoke-TEIAEncodeBin: zstd.exe não encontrado: $ZstdPath" }

    $dictBytes = [IO.File]::ReadAllBytes($DictPath)
    $dictSha   = [TEIA.Native.TEIANativeV80]::SHA256Hex($dictBytes)
    $dictSize  = $dictBytes.Length
    $origSha   = [TEIA.Native.TEIANativeV80]::SHA256Hex($Data)
    $origSize  = $Data.LongLength

    $sw = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV80]::CompressWithZstd($Data, $ZstdPath, $DictPath, $Level)
    $sw.Stop()

    # Manifest JSON — sem base64, apenas metadados para restauração
    $manifest = [ordered]@{
        v           = 1
        name        = $FileName
        sha256      = $origSha
        size        = $origSize
        op          = "dict.zstd_shared"
        dict_sha256 = $dictSha
        dict_size   = $dictSize
        zstd_level  = $Level
    }
    $manifestJson  = $manifest | ConvertTo-Json -Compress -Depth 3
    $manifestBytes = [Text.Encoding]::UTF8.GetByteCount($manifestJson)

    # Encode: header(12B) + manifest(NB) + payload(MB) — nenhum Base64
    $teiaBytes     = [TEIA.Native.TEIANativeV80]::EncodeBinaryTeia($manifestJson, $compressed)
    $teiaSize      = $teiaBytes.Length
    $headerSize    = 12
    $overheadBytes = $teiaSize - $compressed.Length  # = headerSize + manifestBytes

    $rawRatioPct = [math]::Round($compressed.Length / $origSize * 100, 4)
    $netRatioPct = [math]::Round($teiaSize / $origSize * 100, 4)

    return [pscustomobject]@{
        TeiaBytes       = $teiaBytes
        TeiaSize        = $teiaSize
        PayloadBytes    = $compressed.Length
        ManifestBytes   = $manifestBytes
        HeaderBytes     = $headerSize
        OverheadBytes   = $overheadBytes   # = 12 + manifestBytes
        DictSha256      = $dictSha
        DictSize        = $dictSize
        OutSha256       = $origSha
        OutBytes        = $origSize
        RawRatioPct     = $rawRatioPct     # compressed/orig — sem overhead TEIA
        NetRatioPct     = $netRatioPct     # teia_total/orig — custo real
        EncodeMs        = $sw.ElapsedMilliseconds
    }
}

function Invoke-TEIARestoreBin {
    <#
    .SYNOPSIS
        Restaura arquivo de seed binário .teia.
        SHA-256 verificado internamente — throw+rollback se divergir.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$TeiaBytes,
        [Parameter(Mandatory)][string]$DictDir,
        [string]$ZstdPath = $script:ZSTD_V80
    )
    if (-not (Test-Path $DictDir -PathType Container)) {
        throw "Invoke-TEIARestoreBin: DictDir não encontrado: $DictDir"
    }
    [TEIA.Native.TEIANativeV80]::RestoreFromBinaryTeia($TeiaBytes, $DictDir, $ZstdPath)
}

function Save-TEIABin {
    <#
    .SYNOPSIS
        Salva bytes .teia em disco e verifica Write==Read via SHA-256.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$TeiaBytes,
        [Parameter(Mandatory)][string]$OutPath
    )
    [IO.File]::WriteAllBytes($OutPath, $TeiaBytes)

    $readBack  = [IO.File]::ReadAllBytes($OutPath)
    $writeSha  = [TEIA.Native.TEIANativeV80]::SHA256Hex($TeiaBytes)
    $readSha   = [TEIA.Native.TEIANativeV80]::SHA256Hex($readBack)
    if ($writeSha -ne $readSha) {
        Remove-Item $OutPath -Force
        throw "Save-TEIABin: Write==Read FAIL — arquivo removido. write=$writeSha read=$readSha"
    }

    return [pscustomobject]@{
        Path    = $OutPath
        SHA256  = $writeSha
        Bytes   = $TeiaBytes.Length
        WriteOk = $true
    }
}

Export-ModuleMember -Function Build-TEIAZstdDict, Invoke-TEIAEncodeBin, Invoke-TEIARestoreBin, Save-TEIABin
