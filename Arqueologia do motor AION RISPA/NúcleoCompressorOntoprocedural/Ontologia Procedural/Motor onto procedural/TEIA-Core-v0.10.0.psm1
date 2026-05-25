#Requires -Version 7
# TEIA-Core-v0.10.0.psm1
# Motor de reconstrução procedural — Compact Manifest
# Delta vs v0.9.0:
#   • VER_MINOR=10: formato de manifest binário compacto (43+N bytes vs ~150B JSON)
#   • Overhead tiny: 166B→72B (-94B) | large xz.raw: 160B→66B (-94B)
#   • Novos opcodes no manifest compacto: cmp.zstd (0x00), cmp.xz (0x02)
#   • RestoreFromBinaryTeia aceita VER_MINOR 9 (JSON) e 10 (compact)
#   • Invoke-TEIAEncodeCmpRaw, Invoke-TEIAEncodeCmpXz
#   • Invoke-TEIAEncodeAuto: probe cmp.zstd para tiny/small; cmp.xz para large
# Classe: TEIA.Native.TEIANativeV100
# Formato compacto: VER_MAJOR=0, VER_MINOR=10

$script:SEVENZIP_V100 = "C:\Program Files\7-Zip\7z.exe"
$script:ZSTD_V100     = "D:\TEIA_CLAUDE_AWAKENING\_tools\zstd\zstd-v1.5.6-win64\zstd.exe"

# Layout binário manifest compacto (VER_MINOR=10):
#   byte[0]   format_byte = 0x01 (binary manifest v1)
#   byte[1]   algo_byte: 0x00=cmp.zstd | 0x02=cmp.xz
#   byte[2-9] orig_size (uint64 LE)
#   byte[10-41] sha256 (32 raw bytes)
#   byte[42]  name_len (uint8)
#   byte[43..] name (UTF-8, name_len bytes)
# Overhead total = 12B header + (43 + name_len) bytes manifest

if (-not ('TEIA.Native.TEIANativeV100' -as [type])) {
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
    public static class TEIANativeV100 {

        private static readonly byte[] TEIA_MAGIC = { 0x54, 0x45, 0x49, 0x41 };
        private const ushort VER_MAJOR      = 0;
        private const ushort VER_MINOR_JSON = 9;
        private const ushort VER_MINOR_CMP  = 10;
        private const int HEADER_FIXED = 12;

        // algo_byte constants
        public const byte ALGO_CMP_ZSTD = 0x00;
        public const byte ALGO_CMP_XZ   = 0x02;

        public static string SHA256Hex(byte[] data) {
            using var sha = SHA256.Create();
            return BitConverter.ToString(sha.ComputeHash(data))
                               .Replace("-", "").ToLowerInvariant();
        }

        public static byte[] SHA256Raw(byte[] data) {
            using var sha = SHA256.Create();
            return sha.ComputeHash(data);
        }

        private static string RunProcess(string exe, string args, int timeoutMs = 180000) {
            var psi = new ProcessStartInfo(exe, args) {
                RedirectStandardOutput = true,
                RedirectStandardError  = true,
                UseShellExecute        = false,
                CreateNoWindow         = true
            };
            using var proc = Process.Start(psi);
            string stdout = proc.StandardOutput.ReadToEnd();
            string stderr = proc.StandardError.ReadToEnd();
            bool done = proc.WaitForExit(timeoutMs);
            if (!done) { proc.Kill(); throw new Exception($"RunProcess timeout >{timeoutMs}ms: {exe}"); }
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

        public static byte[] CompressWithXZ(byte[] data, string sevenZipPath) {
            string tmpIn  = Path.Combine(Path.GetTempPath(), $"teia_xz_in_{Guid.NewGuid():N}.bin");
            string tmpOut = Path.Combine(Path.GetTempPath(), $"teia_xz_out_{Guid.NewGuid():N}.xz");
            try {
                File.WriteAllBytes(tmpIn, data);
                RunProcess(sevenZipPath, $"a -txz -mx9 -bso0 -bsp0 -bse0 \"{tmpOut}\" \"{tmpIn}\"");
                if (!File.Exists(tmpOut))
                    throw new Exception($"CompressWithXZ: output não criado: {tmpOut}");
                return File.ReadAllBytes(tmpOut);
            } finally {
                if (File.Exists(tmpIn))  File.Delete(tmpIn);
                if (File.Exists(tmpOut)) File.Delete(tmpOut);
            }
        }

        public static byte[] DecompressWithXZ(byte[] xzPayload, string sevenZipPath) {
            string tmpIn  = Path.Combine(Path.GetTempPath(), $"teia_xz_in_{Guid.NewGuid():N}.xz");
            string tmpDir = Path.Combine(Path.GetTempPath(), $"teia_xz_out_{Guid.NewGuid():N}");
            try {
                File.WriteAllBytes(tmpIn, xzPayload);
                Directory.CreateDirectory(tmpDir);
                RunProcess(sevenZipPath, $"e -y \"{tmpIn}\" \"-o{tmpDir}\" -bso0 -bsp0 -bse0");
                var outFiles = Directory.GetFiles(tmpDir);
                if (outFiles.Length == 0)
                    throw new Exception($"DecompressWithXZ: nenhum arquivo em {tmpDir}");
                return File.ReadAllBytes(outFiles[0]);
            } finally {
                if (File.Exists(tmpIn))          File.Delete(tmpIn);
                if (Directory.Exists(tmpDir))    Directory.Delete(tmpDir, true);
            }
        }

        // ── Compact manifest encode (VER_MINOR=10) ────────────────────────────────

        public static byte[] EncodeCompactTeia(byte algoByte, long origSize,
                                                byte[] sha256Raw, string name, byte[] payload) {
            byte[] nameBytes = Encoding.UTF8.GetBytes(name);
            if (nameBytes.Length > 255) Array.Resize(ref nameBytes, 255);

            int manifestLen = 43 + nameBytes.Length;
            byte[] manifest = new byte[manifestLen];

            manifest[0] = 0x01;     // format_byte = binary manifest v1
            manifest[1] = algoByte; // algo: 0x00=cmp.zstd | 0x02=cmp.xz

            for (int i = 0; i < 8; i++)
                manifest[2 + i] = (byte)((origSize >> (i * 8)) & 0xFF);

            Buffer.BlockCopy(sha256Raw, 0, manifest, 10, 32);

            manifest[42] = (byte)nameBytes.Length;
            Buffer.BlockCopy(nameBytes, 0, manifest, 43, nameBytes.Length);

            int totalLen = HEADER_FIXED + manifestLen + payload.Length;
            byte[] result = new byte[totalLen];

            Buffer.BlockCopy(TEIA_MAGIC, 0, result, 0, 4);
            result[4] = (byte)(VER_MAJOR    & 0xFF);
            result[5] = (byte)(VER_MAJOR    >> 8);
            result[6] = (byte)(VER_MINOR_CMP & 0xFF);
            result[7] = (byte)(VER_MINOR_CMP >> 8);
            uint mLen = (uint)manifestLen;
            result[8]  = (byte)(mLen & 0xFF);
            result[9]  = (byte)((mLen >>  8) & 0xFF);
            result[10] = (byte)((mLen >> 16) & 0xFF);
            result[11] = (byte)((mLen >> 24) & 0xFF);
            Buffer.BlockCopy(manifest, 0, result, HEADER_FIXED, manifestLen);
            Buffer.BlockCopy(payload,  0, result, HEADER_FIXED + manifestLen, payload.Length);
            return result;
        }

        // ── JSON manifest encode (VER_MINOR=9, backward compat) ──────────────────

        public static byte[] EncodeBinaryTeia(string manifestJson, byte[] payload) {
            byte[] manifestBytes = Encoding.UTF8.GetBytes(manifestJson);
            int totalLen = HEADER_FIXED + manifestBytes.Length + payload.Length;
            byte[] result = new byte[totalLen];
            Buffer.BlockCopy(TEIA_MAGIC, 0, result, 0, 4);
            result[4] = (byte)(VER_MAJOR      & 0xFF);
            result[5] = (byte)(VER_MAJOR      >> 8);
            result[6] = (byte)(VER_MINOR_JSON & 0xFF);
            result[7] = (byte)(VER_MINOR_JSON >> 8);
            uint mLen = (uint)manifestBytes.Length;
            result[8]  = (byte)(mLen & 0xFF);
            result[9]  = (byte)((mLen >>  8) & 0xFF);
            result[10] = (byte)((mLen >> 16) & 0xFF);
            result[11] = (byte)((mLen >> 24) & 0xFF);
            Buffer.BlockCopy(manifestBytes, 0, result, HEADER_FIXED, manifestBytes.Length);
            Buffer.BlockCopy(payload, 0, result, HEADER_FIXED + manifestBytes.Length, payload.Length);
            return result;
        }

        // ── Restore — aceita VER_MINOR 9 (JSON) e 10 (compact) ──────────────────

        public static byte[] RestoreFromBinaryTeia(byte[] teiaBytes, string dictDir,
                                                    string zstdPath, string sevenZipPath = "") {
            if (teiaBytes == null || teiaBytes.Length < HEADER_FIXED)
                throw new ArgumentException($"Arquivo .teia truncado: {teiaBytes?.Length ?? 0}B");

            for (int i = 0; i < 4; i++)
                if (teiaBytes[i] != TEIA_MAGIC[i])
                    throw new InvalidDataException($"Magic TEIA inválido offset={i}");

            ushort verMaj = ReadUInt16LE(teiaBytes, 4);
            ushort verMin = ReadUInt16LE(teiaBytes, 6);
            if (verMaj != VER_MAJOR)
                throw new InvalidDataException($"VER_MAJOR incompatível: {verMaj}");
            if (verMin != VER_MINOR_JSON && verMin != VER_MINOR_CMP)
                throw new InvalidDataException($"VER_MINOR não suportado: {verMin} (suportado: 9, 10)");

            uint mLen = ReadUInt32LE(teiaBytes, 8);
            if (HEADER_FIXED + (int)mLen > teiaBytes.Length)
                throw new InvalidDataException($"manifest_len={mLen} excede arquivo ({teiaBytes.Length}B)");

            int payloadOffset = HEADER_FIXED + (int)mLen;
            int payloadLen    = teiaBytes.Length - payloadOffset;
            if (payloadLen <= 0)
                throw new InvalidDataException("Payload ausente no arquivo .teia");

            byte[] compressed = new byte[payloadLen];
            Buffer.BlockCopy(teiaBytes, payloadOffset, compressed, 0, payloadLen);

            string expectedSha;
            byte[] result;

            if (verMin == VER_MINOR_JSON) {
                // ── JSON manifest path (VER_MINOR=9) ────────────────────────────
                string manifestJson = Encoding.UTF8.GetString(teiaBytes, HEADER_FIXED, (int)mLen);
                using var doc = JsonDocument.Parse(manifestJson);
                var root = doc.RootElement;

                string op = root.GetProperty("op").GetString();
                expectedSha = root.GetProperty("sha256").GetString().ToLowerInvariant();

                if (op == "zstd.raw") {
                    result = DecompressWithZstd(compressed, zstdPath, "");
                } else if (op == "dict.zstd_shared") {
                    if (string.IsNullOrEmpty(dictDir))  throw new ArgumentException("dictDir obrigatório para dict.zstd_shared");
                    string dictSha256 = root.GetProperty("dict_sha256").GetString().ToLowerInvariant();
                    int    dictSzExp  = root.GetProperty("dict_size").GetInt32();
                    string dictFile   = Path.Combine(dictDir, dictSha256 + ".zstd-dict");
                    if (!File.Exists(dictFile)) throw new FileNotFoundException($"Dicionário não encontrado: {dictFile}");
                    byte[] dictBytes = File.ReadAllBytes(dictFile);
                    if (dictBytes.Length != dictSzExp) throw new InvalidDataException($"Dict size mismatch");
                    if (SHA256Hex(dictBytes) != dictSha256) throw new InvalidDataException($"Dict SHA-256 mismatch");
                    result = DecompressWithZstd(compressed, zstdPath, dictFile);
                } else if (op == "xz.raw") {
                    if (string.IsNullOrEmpty(sevenZipPath)) throw new ArgumentException("sevenZipPath obrigatório para xz.raw");
                    result = DecompressWithXZ(compressed, sevenZipPath);
                } else {
                    throw new NotSupportedException($"Opcode JSON não suportado: {op}");
                }

            } else {
                // ── Compact binary manifest path (VER_MINOR=10) ─────────────────
                if ((int)mLen < 43)
                    throw new InvalidDataException($"Compact manifest muito curto: {mLen}B (mínimo 43B)");

                byte formatByte = teiaBytes[HEADER_FIXED];
                if (formatByte != 0x01)
                    throw new InvalidDataException($"format_byte={formatByte:X2} != 0x01");

                byte algoByte = teiaBytes[HEADER_FIXED + 1];

                long origSize = 0;
                for (int i = 0; i < 8; i++)
                    origSize |= ((long)teiaBytes[HEADER_FIXED + 2 + i]) << (i * 8);

                byte[] sha256Raw = new byte[32];
                Buffer.BlockCopy(teiaBytes, HEADER_FIXED + 10, sha256Raw, 0, 32);
                expectedSha = BitConverter.ToString(sha256Raw).Replace("-", "").ToLowerInvariant();

                if (algoByte == ALGO_CMP_ZSTD) {
                    result = DecompressWithZstd(compressed, zstdPath, "");
                } else if (algoByte == ALGO_CMP_XZ) {
                    if (string.IsNullOrEmpty(sevenZipPath)) throw new ArgumentException("sevenZipPath obrigatório para cmp.xz");
                    result = DecompressWithXZ(compressed, sevenZipPath);
                } else {
                    throw new NotSupportedException($"Compact algo_byte=0x{algoByte:X2} não suportado");
                }
            }

            // SHA-256 verify — throw antes de qualquer escrita em disco
            string resultSha = SHA256Hex(result);
            if (resultSha != expectedSha)
                throw new InvalidDataException(
                    $"SHA-256 MISMATCH restauração — ROLLBACK\n" +
                    $"  Esperado:   {expectedSha}\n" +
                    $"  Restaurado: {resultSha}");

            return result;
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$TrainingFiles,
        [Parameter(Mandatory)][string]$OutputDir,
        [int]$MaxDictBytes = 112640,
        [string]$ZstdPath  = $script:ZSTD_V100
    )
    if (-not (Test-Path $ZstdPath)) { throw "Build-TEIAZstdDict: zstd.exe não encontrado: $ZstdPath" }
    $valid = @($TrainingFiles | Where-Object { Test-Path $_ })
    if ($valid.Count -eq 0) { throw "Build-TEIAZstdDict: nenhum arquivo de treinamento válido" }
    [IO.Directory]::CreateDirectory($OutputDir) | Out-Null
    $tmpDict = Join-Path $OutputDir "teia_v100_train_tmp.zstd-dict"
    if (Test-Path $tmpDict) { Remove-Item $tmpDict -Force }
    Write-Host "[ZSTD TRAIN v0.10.0] $($valid.Count) arquivo(s) | maxdict=$MaxDictBytes B"
    $sw = [Diagnostics.Stopwatch]::StartNew()
    [TEIA.Native.TEIANativeV100]::TrainZstdDict([string[]]$valid, $tmpDict, $MaxDictBytes, $ZstdPath)
    $sw.Stop()
    if (-not (Test-Path $tmpDict)) { throw "Build-TEIAZstdDict: treinamento falhou" }
    $dictBytes = [IO.File]::ReadAllBytes($tmpDict)
    $dictSha   = [TEIA.Native.TEIANativeV100]::SHA256Hex($dictBytes)
    $dictPath  = Join-Path $OutputDir ($dictSha + ".zstd-dict")
    [IO.File]::WriteAllBytes($dictPath, $dictBytes)
    Remove-Item $tmpDict -Force
    Write-Host "[ZSTD TRAIN v0.10.0] $($dictBytes.Length)B | SHA: $($dictSha.Substring(0,16))... | $($sw.ElapsedMilliseconds)ms"
    return [pscustomobject]@{ DictPath=$dictPath; DictSha256=$dictSha; DictBytes=$dictBytes.Length; TrainMs=$sw.ElapsedMilliseconds }
}

function Invoke-TEIAEncodeBin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [Parameter(Mandatory)][string]$DictPath,
        [string]$FileName = "output.bin",
        [string]$ZstdPath = $script:ZSTD_V100,
        [int]$Level = 19
    )
    if (-not (Test-Path $DictPath))  { throw "Invoke-TEIAEncodeBin: dict não encontrado: $DictPath" }
    $dictBytes = [IO.File]::ReadAllBytes($DictPath)
    $dictSha   = [TEIA.Native.TEIANativeV100]::SHA256Hex($dictBytes)
    $origSha   = [TEIA.Native.TEIANativeV100]::SHA256Hex($Data)
    $origSize  = $Data.LongLength
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV100]::CompressWithZstd($Data, $ZstdPath, $DictPath, $Level)
    $sw.Stop()
    $manifest = [ordered]@{ v=1; name=$FileName; sha256=$origSha; size=$origSize
                             op="dict.zstd_shared"; dict_sha256=$dictSha; dict_size=$dictBytes.Length; zstd_level=$Level }
    $mJson     = $manifest | ConvertTo-Json -Compress -Depth 3
    $teiaBytes = [TEIA.Native.TEIANativeV100]::EncodeBinaryTeia($mJson, $compressed)
    return [pscustomobject]@{
        TeiaBytes=$teiaBytes; TeiaSize=$teiaBytes.Length; PayloadBytes=$compressed.Length
        OverheadBytes=($teiaBytes.Length-$compressed.Length)
        DictSha256=$dictSha; OutSha256=$origSha; OutBytes=$origSize
        NetRatioPct=[math]::Round($teiaBytes.Length/$origSize*100,4)
        EncodeMs=$sw.ElapsedMilliseconds; Op="dict.zstd_shared"
    }
}

function Invoke-TEIAEncodeRaw {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [string]$FileName = "output.bin",
        [string]$ZstdPath = $script:ZSTD_V100,
        [int]$Level = 19
    )
    $origSha  = [TEIA.Native.TEIANativeV100]::SHA256Hex($Data)
    $origSize = $Data.LongLength
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV100]::CompressWithZstd($Data, $ZstdPath, "", $Level)
    $sw.Stop()
    $mJson     = ([ordered]@{ v=1; name=$FileName; sha256=$origSha; size=$origSize; op="zstd.raw"; zstd_level=$Level } | ConvertTo-Json -Compress)
    $teiaBytes = [TEIA.Native.TEIANativeV100]::EncodeBinaryTeia($mJson, $compressed)
    return [pscustomobject]@{
        TeiaBytes=$teiaBytes; TeiaSize=$teiaBytes.Length; PayloadBytes=$compressed.Length
        OverheadBytes=($teiaBytes.Length-$compressed.Length)
        OutSha256=$origSha; OutBytes=$origSize
        NetRatioPct=[math]::Round($teiaBytes.Length/$origSize*100,4)
        EncodeMs=$sw.ElapsedMilliseconds; Op="zstd.raw"
    }
}

function Invoke-TEIAEncodeXzRaw {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [string]$FileName     = "output.bin",
        [string]$SevenZipPath = $script:SEVENZIP_V100
    )
    $origSha  = [TEIA.Native.TEIANativeV100]::SHA256Hex($Data)
    $origSize = $Data.LongLength
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV100]::CompressWithXZ($Data, $SevenZipPath)
    $sw.Stop()
    $mJson     = ([ordered]@{ v=1; name=$FileName; sha256=$origSha; size=$origSize; op="xz.raw"; xz_level=9 } | ConvertTo-Json -Compress)
    $teiaBytes = [TEIA.Native.TEIANativeV100]::EncodeBinaryTeia($mJson, $compressed)
    return [pscustomobject]@{
        TeiaBytes=$teiaBytes; TeiaSize=$teiaBytes.Length; PayloadBytes=$compressed.Length
        OverheadBytes=($teiaBytes.Length-$compressed.Length)
        OutSha256=$origSha; OutBytes=$origSize
        NetRatioPct=[math]::Round($teiaBytes.Length/$origSize*100,4)
        EncodeMs=$sw.ElapsedMilliseconds; Op="xz.raw"
    }
}

function Invoke-TEIAEncodeCmpRaw {
    <#
    .SYNOPSIS
        Compact manifest + Zstd raw (cmp.zstd). VER_MINOR=10.
        Overhead = 12B header + (43 + name_len) bytes manifest.
        Para "paginators-1.json" (17 chars): 72B total. vs 166B JSON → -94B.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [string]$FileName = "output.bin",
        [string]$ZstdPath = $script:ZSTD_V100,
        [int]$Level       = 19
    )
    $origShaRaw = [TEIA.Native.TEIANativeV100]::SHA256Raw($Data)
    $origShaHex = [TEIA.Native.TEIANativeV100]::SHA256Hex($Data)
    $origSize   = $Data.LongLength
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV100]::CompressWithZstd($Data, $ZstdPath, "", $Level)
    $sw.Stop()
    $teiaBytes = [TEIA.Native.TEIANativeV100]::EncodeCompactTeia(
        [TEIA.Native.TEIANativeV100]::ALGO_CMP_ZSTD, $origSize, $origShaRaw, $FileName, $compressed)
    return [pscustomobject]@{
        TeiaBytes=$teiaBytes; TeiaSize=$teiaBytes.Length; PayloadBytes=$compressed.Length
        OverheadBytes=($teiaBytes.Length-$compressed.Length)
        OutSha256=$origShaHex; OutBytes=$origSize
        NetRatioPct=[math]::Round($teiaBytes.Length/$origSize*100,4)
        EncodeMs=$sw.ElapsedMilliseconds; Op="cmp.zstd"
    }
}

function Invoke-TEIAEncodeCmpXz {
    <#
    .SYNOPSIS
        Compact manifest + XZ/LZMA2 (cmp.xz). VER_MINOR=10.
        Overhead = 12B header + (43 + name_len) bytes manifest.
        Para "service-2.json" (11 chars): 66B total. vs 160B JSON → -94B.
        Flips LZMA_JANELA losses R96/R100 por margem de 21-24B.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [string]$FileName     = "output.bin",
        [string]$SevenZipPath = $script:SEVENZIP_V100
    )
    $origShaRaw = [TEIA.Native.TEIANativeV100]::SHA256Raw($Data)
    $origShaHex = [TEIA.Native.TEIANativeV100]::SHA256Hex($Data)
    $origSize   = $Data.LongLength
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV100]::CompressWithXZ($Data, $SevenZipPath)
    $sw.Stop()
    $teiaBytes = [TEIA.Native.TEIANativeV100]::EncodeCompactTeia(
        [TEIA.Native.TEIANativeV100]::ALGO_CMP_XZ, $origSize, $origShaRaw, $FileName, $compressed)
    return [pscustomobject]@{
        TeiaBytes=$teiaBytes; TeiaSize=$teiaBytes.Length; PayloadBytes=$compressed.Length
        OverheadBytes=($teiaBytes.Length-$compressed.Length)
        OutSha256=$origShaHex; OutBytes=$origSize
        NetRatioPct=[math]::Round($teiaBytes.Length/$origSize*100,4)
        EncodeMs=$sw.ElapsedMilliseconds; Op="cmp.xz"
    }
}

function Invoke-TEIAEncodeAuto {
    <#
    .SYNOPSIS
        Selector Engine v0.10: proba todos os candidatos e retorna menor D.
        Novidade vs v0.9: cmp.zstd e cmp.xz como candidatos (compact manifest).
        tiny/small:  {cmp.zstd, dict(se disponível), zstd.raw}
        medium:      {dict.zstd_shared, zstd.raw}
        large:       {cmp.xz, xz.raw, zstd.raw}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [Parameter(Mandatory)][string]$Bucket,
        [string]$FileName       = "output.bin",
        [string]$DictSmallPath  = "",
        [string]$DictMediumPath = "",
        [string]$ZstdPath       = $script:ZSTD_V100,
        [string]$SevenZipPath   = $script:SEVENZIP_V100
    )

    $origShaRaw = [TEIA.Native.TEIANativeV100]::SHA256Raw($Data)
    $origShaHex = [TEIA.Native.TEIANativeV100]::SHA256Hex($Data)
    $origSize   = $Data.LongLength
    $candidates = [System.Collections.ArrayList]::new()
    $swTotal    = [Diagnostics.Stopwatch]::StartNew()

    function Add-Candidate([string]$op, [byte[]]$tb, [long]$ms) {
        [void]$candidates.Add([pscustomobject]@{
            Op=$op; TeiaBytes=$tb; TeiaSize=$tb.Length
            PayloadBytes=($tb.Length - ($tb.Length - [System.Runtime.InteropServices.Marshal]::SizeOf([byte])))
            OverheadBytes=0  # computed below
            EncodeMs=$ms
        })
    }

    # ── Probe: cmp.zstd (compact Zstd) — tiny, small, medium se não tem dict ──
    $shouldProbeCmpZstd = $Bucket -in @("tiny","small") -or
                          ($Bucket -eq "medium" -and -not $DictMediumPath)
    if ($shouldProbeCmpZstd) {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $payZ = [TEIA.Native.TEIANativeV100]::CompressWithZstd($Data, $ZstdPath, "", 19)
        $sw.Stop()
        $tb = [TEIA.Native.TEIANativeV100]::EncodeCompactTeia(
            [TEIA.Native.TEIANativeV100]::ALGO_CMP_ZSTD, $origSize, $origShaRaw, $FileName, $payZ)
        [void]$candidates.Add([pscustomobject]@{
            Op="cmp.zstd"; TeiaBytes=$tb; TeiaSize=$tb.Length
            PayloadBytes=$payZ.Length; OverheadBytes=($tb.Length-$payZ.Length); EncodeMs=$sw.ElapsedMilliseconds
        })
    }

    # ── Probe: dict.zstd_shared (JSON manifest) ─────────────────────────────
    if ($Bucket -eq "small" -and $DictSmallPath -and (Test-Path $DictSmallPath)) {
        $dictB = [IO.File]::ReadAllBytes($DictSmallPath)
        $dictBSha = [TEIA.Native.TEIANativeV100]::SHA256Hex($dictB)
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $payD = [TEIA.Native.TEIANativeV100]::CompressWithZstd($Data, $ZstdPath, $DictSmallPath, 19)
        $sw.Stop()
        $mfD = ([ordered]@{ v=1; name=$FileName; sha256=$origShaHex; size=$origSize
                             op="dict.zstd_shared"; dict_sha256=$dictBSha; dict_size=$dictB.Length; zstd_level=19 } | ConvertTo-Json -Compress)
        $tb = [TEIA.Native.TEIANativeV100]::EncodeBinaryTeia($mfD, $payD)
        [void]$candidates.Add([pscustomobject]@{
            Op="dict.zstd_shared"; TeiaBytes=$tb; TeiaSize=$tb.Length
            PayloadBytes=$payD.Length; OverheadBytes=($tb.Length-$payD.Length); EncodeMs=$sw.ElapsedMilliseconds
        })
    } elseif ($Bucket -eq "medium" -and $DictMediumPath -and (Test-Path $DictMediumPath)) {
        $dictB = [IO.File]::ReadAllBytes($DictMediumPath)
        $dictBSha = [TEIA.Native.TEIANativeV100]::SHA256Hex($dictB)
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $payD = [TEIA.Native.TEIANativeV100]::CompressWithZstd($Data, $ZstdPath, $DictMediumPath, 19)
        $sw.Stop()
        $mfD = ([ordered]@{ v=1; name=$FileName; sha256=$origShaHex; size=$origSize
                             op="dict.zstd_shared"; dict_sha256=$dictBSha; dict_size=$dictB.Length; zstd_level=19 } | ConvertTo-Json -Compress)
        $tb = [TEIA.Native.TEIANativeV100]::EncodeBinaryTeia($mfD, $payD)
        [void]$candidates.Add([pscustomobject]@{
            Op="dict.zstd_shared"; TeiaBytes=$tb; TeiaSize=$tb.Length
            PayloadBytes=$payD.Length; OverheadBytes=($tb.Length-$payD.Length); EncodeMs=$sw.ElapsedMilliseconds
        })
    }

    # ── Probe: zstd.raw (JSON manifest) — fallback sempre disponível ─────────
    if (-not $shouldProbeCmpZstd) {
        # tiny/small já probaram cmp.zstd (que inclui o mesmo payload Zstd)
        # medium/large: probar zstd.raw separadamente
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $payZ2 = [TEIA.Native.TEIANativeV100]::CompressWithZstd($Data, $ZstdPath, "", 19)
        $sw.Stop()
        $mfZ = ([ordered]@{ v=1; name=$FileName; sha256=$origShaHex; size=$origSize; op="zstd.raw"; zstd_level=19 } | ConvertTo-Json -Compress)
        $tb = [TEIA.Native.TEIANativeV100]::EncodeBinaryTeia($mfZ, $payZ2)
        [void]$candidates.Add([pscustomobject]@{
            Op="zstd.raw"; TeiaBytes=$tb; TeiaSize=$tb.Length
            PayloadBytes=$payZ2.Length; OverheadBytes=($tb.Length-$payZ2.Length); EncodeMs=$sw.ElapsedMilliseconds
        })
    }

    # ── Probe: cmp.xz (compact XZ) e xz.raw (JSON XZ) — large ──────────────
    if ($Bucket -eq "large") {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $payXZ = [TEIA.Native.TEIANativeV100]::CompressWithXZ($Data, $SevenZipPath)
        $sw.Stop()
        $msXZ = $sw.ElapsedMilliseconds

        # cmp.xz: compact manifest
        $tbCX = [TEIA.Native.TEIANativeV100]::EncodeCompactTeia(
            [TEIA.Native.TEIANativeV100]::ALGO_CMP_XZ, $origSize, $origShaRaw, $FileName, $payXZ)
        [void]$candidates.Add([pscustomobject]@{
            Op="cmp.xz"; TeiaBytes=$tbCX; TeiaSize=$tbCX.Length
            PayloadBytes=$payXZ.Length; OverheadBytes=($tbCX.Length-$payXZ.Length); EncodeMs=$msXZ
        })

        # xz.raw: JSON manifest (backward compat)
        $mfX = ([ordered]@{ v=1; name=$FileName; sha256=$origShaHex; size=$origSize; op="xz.raw"; xz_level=9 } | ConvertTo-Json -Compress)
        $tbX = [TEIA.Native.TEIANativeV100]::EncodeBinaryTeia($mfX, $payXZ)
        [void]$candidates.Add([pscustomobject]@{
            Op="xz.raw"; TeiaBytes=$tbX; TeiaSize=$tbX.Length
            PayloadBytes=$payXZ.Length; OverheadBytes=($tbX.Length-$payXZ.Length); EncodeMs=$msXZ
        })
    }

    $swTotal.Stop()
    $best = $candidates | Sort-Object TeiaSize | Select-Object -First 1

    return [pscustomobject]@{
        TeiaBytes    = $best.TeiaBytes
        TeiaSize     = $best.TeiaSize
        PayloadBytes = $best.PayloadBytes
        OverheadBytes= $best.OverheadBytes
        Op           = $best.Op
        OutSha256    = $origShaHex
        OutBytes     = $origSize
        NetRatioPct  = [math]::Round($best.TeiaSize/$origSize*100,4)
        EncodeMs     = $swTotal.ElapsedMilliseconds
        ProbeCount   = $candidates.Count
        Probes       = @($candidates | Select-Object Op,TeiaSize,OverheadBytes,EncodeMs)
    }
}

function Invoke-TEIARestoreBin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$TeiaBytes,
        [string]$DictDir      = "",
        [string]$ZstdPath     = $script:ZSTD_V100,
        [string]$SevenZipPath = $script:SEVENZIP_V100
    )
    [TEIA.Native.TEIANativeV100]::RestoreFromBinaryTeia($TeiaBytes, $DictDir, $ZstdPath, $SevenZipPath)
}

function Save-TEIABin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$TeiaBytes,
        [Parameter(Mandatory)][string]$OutPath
    )
    [IO.File]::WriteAllBytes($OutPath, $TeiaBytes)
    $readBack = [IO.File]::ReadAllBytes($OutPath)
    $writeSha = [TEIA.Native.TEIANativeV100]::SHA256Hex($TeiaBytes)
    $readSha  = [TEIA.Native.TEIANativeV100]::SHA256Hex($readBack)
    if ($writeSha -ne $readSha) {
        Remove-Item $OutPath -Force
        throw "Save-TEIABin: Write==Read FAIL — arquivo removido. write=$writeSha read=$readSha"
    }
    return [pscustomobject]@{ Path=$OutPath; SHA256=$writeSha; Bytes=$TeiaBytes.Length; WriteOk=$true }
}

Export-ModuleMember -Function `
    Build-TEIAZstdDict, `
    Invoke-TEIAEncodeBin, Invoke-TEIAEncodeRaw, Invoke-TEIAEncodeXzRaw, `
    Invoke-TEIAEncodeCmpRaw, Invoke-TEIAEncodeCmpXz, Invoke-TEIAEncodeAuto, `
    Invoke-TEIARestoreBin, Save-TEIABin
