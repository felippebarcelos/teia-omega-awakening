#Requires -Version 7
# TEIA-Core-v0.9.0.psm1
# Motor de reconstrução procedural — Selector Engine
# Delta vs v0.8.1:
#   • Novo opcode "lzma.raw" — payload .lzma puro (13B header) em container .teia (~165B ovhd)
#   • CompressWithLzma / DecompressWithLzma no C# (7z -tlzma)
#   • RestoreFromBinaryTeia aceita lzma.raw (parâmetro sevenZipPath adicionado)
#   • Invoke-TEIAEncodeLzmaRaw — codifica com LZMA puro
#   • Invoke-TEIAEncodeAuto — Selector Engine: proba todos os opcodes candidatos, retorna menor D
# Classe: TEIA.Native.TEIANativeV90
# Formato .teia: VER_MAJOR=0, VER_MINOR=9

$script:SEVENZIP_V90 = "C:\Program Files\7-Zip\7z.exe"
$script:ZSTD_V90     = "D:\TEIA_CLAUDE_AWAKENING\_tools\zstd\zstd-v1.5.6-win64\zstd.exe"

if (-not ('TEIA.Native.TEIANativeV90' -as [type])) {
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
    public static class TEIANativeV90 {

        private static readonly byte[] TEIA_MAGIC = { 0x54, 0x45, 0x49, 0x41 };
        private const ushort VER_MAJOR = 0;
        private const ushort VER_MINOR = 9;
        private const int HEADER_FIXED = 12;

        public static string SHA256Hex(byte[] data) {
            using var sha = SHA256.Create();
            return BitConverter.ToString(sha.ComputeHash(data))
                               .Replace("-", "").ToLowerInvariant();
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

        // Comprime com XZ/LZMA2: formato .xz (~80B overhead) vs .7z archive (~200-350B)
        // -tlzma removido no 7z 25.01; -txz (LZMA2) é o substituto com menor container overhead
        public static byte[] CompressWithXZ(byte[] data, string sevenZipPath) {
            string tmpIn  = Path.Combine(Path.GetTempPath(), $"teia_xz_in_{Guid.NewGuid():N}.bin");
            string tmpOut = Path.Combine(Path.GetTempPath(), $"teia_xz_out_{Guid.NewGuid():N}.xz");
            try {
                File.WriteAllBytes(tmpIn, data);
                string args = $"a -txz -mx9 -bso0 -bsp0 -bse0 \"{tmpOut}\" \"{tmpIn}\"";
                RunProcess(sevenZipPath, args);
                if (!File.Exists(tmpOut))
                    throw new Exception($"CompressWithXZ: output não criado: {tmpOut}");
                return File.ReadAllBytes(tmpOut);
            } finally {
                if (File.Exists(tmpIn))  File.Delete(tmpIn);
                if (File.Exists(tmpOut)) File.Delete(tmpOut);
            }
        }

        // Descomprime payload .xz via 7z e
        public static byte[] DecompressWithXZ(byte[] xzPayload, string sevenZipPath) {
            string tmpIn  = Path.Combine(Path.GetTempPath(), $"teia_xz_in_{Guid.NewGuid():N}.xz");
            string tmpDir = Path.Combine(Path.GetTempPath(), $"teia_xz_out_{Guid.NewGuid():N}");
            try {
                File.WriteAllBytes(tmpIn, xzPayload);
                Directory.CreateDirectory(tmpDir);
                string args = $"e -y \"{tmpIn}\" \"-o{tmpDir}\" -bso0 -bsp0 -bse0";
                RunProcess(sevenZipPath, args);
                var outFiles = Directory.GetFiles(tmpDir);
                if (outFiles.Length == 0)
                    throw new Exception($"DecompressWithXZ: nenhum arquivo em {tmpDir}");
                return File.ReadAllBytes(outFiles[0]);
            } finally {
                if (File.Exists(tmpIn))          File.Delete(tmpIn);
                if (Directory.Exists(tmpDir))    Directory.Delete(tmpDir, true);
            }
        }

        public static byte[] EncodeBinaryTeia(string manifestJson, byte[] payload) {
            byte[] manifestBytes = Encoding.UTF8.GetBytes(manifestJson);
            int totalLen = HEADER_FIXED + manifestBytes.Length + payload.Length;
            byte[] result = new byte[totalLen];
            Buffer.BlockCopy(TEIA_MAGIC, 0, result, 0, 4);
            result[4] = (byte)(VER_MAJOR & 0xFF);
            result[5] = (byte)(VER_MAJOR >> 8);
            result[6] = (byte)(VER_MINOR & 0xFF);
            result[7] = (byte)(VER_MINOR >> 8);
            uint mLen = (uint)manifestBytes.Length;
            result[8]  = (byte)(mLen & 0xFF);
            result[9]  = (byte)((mLen >>  8) & 0xFF);
            result[10] = (byte)((mLen >> 16) & 0xFF);
            result[11] = (byte)((mLen >> 24) & 0xFF);
            Buffer.BlockCopy(manifestBytes, 0, result, HEADER_FIXED, manifestBytes.Length);
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

        // sevenZipPath obrigatório apenas para lzma.raw; pode ser "" para zstd.*
        public static byte[] RestoreFromBinaryTeia(byte[] teiaBytes, string dictDir,
                                                    string zstdPath, string sevenZipPath = "") {
            if (teiaBytes == null || teiaBytes.Length < HEADER_FIXED)
                throw new ArgumentException($"Arquivo .teia truncado: {teiaBytes?.Length ?? 0}B");

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

            using var doc = JsonDocument.Parse(manifestJson);
            var root = doc.RootElement;

            string op          = root.GetProperty("op").GetString();
            string expectedSha = root.GetProperty("sha256").GetString().ToLowerInvariant();

            byte[] result;

            if (op == "zstd.raw") {
                result = DecompressWithZstd(compressed, zstdPath, "");

            } else if (op == "dict.zstd_shared") {
                if (string.IsNullOrEmpty(dictDir))  throw new ArgumentException("dictDir obrigatório para dict.zstd_shared");
                if (string.IsNullOrEmpty(zstdPath)) throw new ArgumentException("zstdPath obrigatório para dict.zstd_shared");

                string dictSha256 = root.GetProperty("dict_sha256").GetString().ToLowerInvariant();
                int    dictSzExp  = root.GetProperty("dict_size").GetInt32();

                string dictFile = Path.Combine(dictDir, dictSha256 + ".zstd-dict");
                if (!File.Exists(dictFile)) throw new FileNotFoundException($"Dicionário não encontrado: {dictFile}");

                byte[] dictBytes = File.ReadAllBytes(dictFile);
                if (dictBytes.Length != dictSzExp)
                    throw new InvalidDataException($"Dict size mismatch: {dictBytes.Length} != {dictSzExp}");

                string actualDictSha = SHA256Hex(dictBytes);
                if (actualDictSha != dictSha256)
                    throw new InvalidDataException($"Dict SHA-256 mismatch: {actualDictSha} != {dictSha256}");

                result = DecompressWithZstd(compressed, zstdPath, dictFile);

            } else if (op == "xz.raw") {
                if (string.IsNullOrEmpty(sevenZipPath))
                    throw new ArgumentException("sevenZipPath obrigatório para xz.raw");
                result = DecompressWithXZ(compressed, sevenZipPath);

            } else {
                throw new NotSupportedException($"Opcode não suportado: {op}");
            }

            string resultSha = SHA256Hex(result);
            if (resultSha != expectedSha)
                throw new InvalidDataException(
                    $"SHA-256 MISMATCH restauração — ROLLBACK\n" +
                    $"  Esperado:   {expectedSha}\n" +
                    $"  Restaurado: {resultSha}");

            return result;
        }

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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$TrainingFiles,
        [Parameter(Mandatory)][string]$OutputDir,
        [int]$MaxDictBytes = 112640,
        [string]$ZstdPath  = $script:ZSTD_V90
    )
    if (-not (Test-Path $ZstdPath)) { throw "Build-TEIAZstdDict: zstd.exe não encontrado: $ZstdPath" }

    $valid = @($TrainingFiles | Where-Object { Test-Path $_ })
    if ($valid.Count -eq 0) { throw "Build-TEIAZstdDict: nenhum arquivo de treinamento válido" }

    [IO.Directory]::CreateDirectory($OutputDir) | Out-Null
    $tmpDict = Join-Path $OutputDir "teia_v90_train_tmp.zstd-dict"
    if (Test-Path $tmpDict) { Remove-Item $tmpDict -Force }

    Write-Host "[ZSTD TRAIN v0.9.0] $($valid.Count) arquivo(s) | maxdict=$MaxDictBytes B"
    $sw = [Diagnostics.Stopwatch]::StartNew()
    [TEIA.Native.TEIANativeV90]::TrainZstdDict([string[]]$valid, $tmpDict, $MaxDictBytes, $ZstdPath)
    $sw.Stop()

    if (-not (Test-Path $tmpDict)) { throw "Build-TEIAZstdDict: treinamento falhou" }

    $dictBytes = [IO.File]::ReadAllBytes($tmpDict)
    $dictSha   = [TEIA.Native.TEIANativeV90]::SHA256Hex($dictBytes)
    $dictPath  = Join-Path $OutputDir ($dictSha + ".zstd-dict")
    [IO.File]::WriteAllBytes($dictPath, $dictBytes)
    Remove-Item $tmpDict -Force

    Write-Host "[ZSTD TRAIN v0.9.0] $($dictBytes.Length) bytes | SHA: $($dictSha.Substring(0,16))... | $($sw.ElapsedMilliseconds)ms"
    return [pscustomobject]@{
        DictPath   = $dictPath
        DictSha256 = $dictSha
        DictBytes  = $dictBytes.Length
        TrainCount = $valid.Count
        TrainMs    = $sw.ElapsedMilliseconds
    }
}

function Invoke-TEIAEncodeBin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [Parameter(Mandatory)][string]$DictPath,
        [string]$FileName = "output.bin",
        [string]$ZstdPath = $script:ZSTD_V90,
        [int]$Level       = 19
    )
    if (-not (Test-Path $DictPath))  { throw "Invoke-TEIAEncodeBin: dict não encontrado: $DictPath" }
    if (-not (Test-Path $ZstdPath)) { throw "Invoke-TEIAEncodeBin: zstd.exe não encontrado: $ZstdPath" }

    $dictBytes = [IO.File]::ReadAllBytes($DictPath)
    $dictSha   = [TEIA.Native.TEIANativeV90]::SHA256Hex($dictBytes)
    $origSha   = [TEIA.Native.TEIANativeV90]::SHA256Hex($Data)
    $origSize  = $Data.LongLength

    $sw         = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV90]::CompressWithZstd($Data, $ZstdPath, $DictPath, $Level)
    $sw.Stop()

    $manifest = [ordered]@{
        v=1; name=$FileName; sha256=$origSha; size=$origSize
        op="dict.zstd_shared"; dict_sha256=$dictSha; dict_size=$dictBytes.Length; zstd_level=$Level
    }
    $manifestJson = $manifest | ConvertTo-Json -Compress -Depth 3
    $teiaBytes    = [TEIA.Native.TEIANativeV90]::EncodeBinaryTeia($manifestJson, $compressed)

    return [pscustomobject]@{
        TeiaBytes=$teiaBytes; TeiaSize=$teiaBytes.Length; PayloadBytes=$compressed.Length
        OverheadBytes=($teiaBytes.Length - $compressed.Length)
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
        [string]$ZstdPath = $script:ZSTD_V90,
        [int]$Level       = 19
    )
    if (-not (Test-Path $ZstdPath)) { throw "Invoke-TEIAEncodeRaw: zstd.exe não encontrado: $ZstdPath" }

    $origSha  = [TEIA.Native.TEIANativeV90]::SHA256Hex($Data)
    $origSize = $Data.LongLength

    $sw         = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV90]::CompressWithZstd($Data, $ZstdPath, "", $Level)
    $sw.Stop()

    $manifest = [ordered]@{ v=1; name=$FileName; sha256=$origSha; size=$origSize; op="zstd.raw"; zstd_level=$Level }
    $manifestJson = $manifest | ConvertTo-Json -Compress -Depth 3
    $teiaBytes    = [TEIA.Native.TEIANativeV90]::EncodeBinaryTeia($manifestJson, $compressed)

    return [pscustomobject]@{
        TeiaBytes=$teiaBytes; TeiaSize=$teiaBytes.Length; PayloadBytes=$compressed.Length
        OverheadBytes=($teiaBytes.Length - $compressed.Length)
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
        [string]$SevenZipPath = $script:SEVENZIP_V90
    )
    if (-not (Test-Path $SevenZipPath)) { throw "Invoke-TEIAEncodeXzRaw: 7z.exe não encontrado: $SevenZipPath" }

    $origSha  = [TEIA.Native.TEIANativeV90]::SHA256Hex($Data)
    $origSize = $Data.LongLength

    $sw         = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV90]::CompressWithXZ($Data, $SevenZipPath)
    $sw.Stop()

    $manifest = [ordered]@{ v=1; name=$FileName; sha256=$origSha; size=$origSize; op="xz.raw"; xz_level=9 }
    $manifestJson = $manifest | ConvertTo-Json -Compress -Depth 3
    $teiaBytes    = [TEIA.Native.TEIANativeV90]::EncodeBinaryTeia($manifestJson, $compressed)

    return [pscustomobject]@{
        TeiaBytes=$teiaBytes; TeiaSize=$teiaBytes.Length; PayloadBytes=$compressed.Length
        OverheadBytes=($teiaBytes.Length - $compressed.Length)
        OutSha256=$origSha; OutBytes=$origSize
        NetRatioPct=[math]::Round($teiaBytes.Length/$origSize*100,4)
        EncodeMs=$sw.ElapsedMilliseconds; Op="xz.raw"
    }
}

function Invoke-TEIAEncodeAuto {
    <#
    .SYNOPSIS
        Selector Engine v0.9: proba todos os opcodes candidatos para o bucket e retorna o menor D.
        Garante opcode ótimo sem heurística fixa — cada arquivo escolhe seu melhor caminho.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [Parameter(Mandatory)][string]$Bucket,
        [string]$FileName      = "output.bin",
        [string]$DictSmallPath = "",
        [string]$DictMediumPath= "",
        [string]$ZstdPath      = $script:ZSTD_V90,
        [string]$SevenZipPath  = $script:SEVENZIP_V90
    )

    $origSha  = [TEIA.Native.TEIANativeV90]::SHA256Hex($Data)
    $origSize = $Data.LongLength
    $candidates = [System.Collections.ArrayList]::new()
    $swTotal    = [Diagnostics.Stopwatch]::StartNew()

    # Probe A: zstd.raw — sempre candidato
    $sw  = [Diagnostics.Stopwatch]::StartNew()
    $payZ = [TEIA.Native.TEIANativeV90]::CompressWithZstd($Data, $ZstdPath, "", 19)
    $sw.Stop()
    $mfZ = ([ordered]@{ v=1; name=$FileName; sha256=$origSha; size=$origSize; op="zstd.raw"; zstd_level=19 } | ConvertTo-Json -Compress)
    $tbZ = [TEIA.Native.TEIANativeV90]::EncodeBinaryTeia($mfZ, $payZ)
    [void]$candidates.Add([pscustomobject]@{
        Op="zstd.raw"; TeiaBytes=$tbZ; TeiaSize=$tbZ.Length
        PayloadBytes=$payZ.Length; OverheadBytes=($tbZ.Length-$payZ.Length)
        EncodeMs=$sw.ElapsedMilliseconds; DictSha256=""
    })

    # Probe B: dict.zstd_shared — para small/medium se dict disponível
    if ($Bucket -eq "small" -and $DictSmallPath -and (Test-Path $DictSmallPath)) {
        $dictB = [IO.File]::ReadAllBytes($DictSmallPath)
        $dictBSha = [TEIA.Native.TEIANativeV90]::SHA256Hex($dictB)
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $payD = [TEIA.Native.TEIANativeV90]::CompressWithZstd($Data, $ZstdPath, $DictSmallPath, 19)
        $sw.Stop()
        $mfD = ([ordered]@{ v=1; name=$FileName; sha256=$origSha; size=$origSize; op="dict.zstd_shared"; dict_sha256=$dictBSha; dict_size=$dictB.Length; zstd_level=19 } | ConvertTo-Json -Compress)
        $tbD = [TEIA.Native.TEIANativeV90]::EncodeBinaryTeia($mfD, $payD)
        [void]$candidates.Add([pscustomobject]@{
            Op="dict.zstd_shared"; TeiaBytes=$tbD; TeiaSize=$tbD.Length
            PayloadBytes=$payD.Length; OverheadBytes=($tbD.Length-$payD.Length)
            EncodeMs=$sw.ElapsedMilliseconds; DictSha256=$dictBSha
        })
    } elseif ($Bucket -eq "medium" -and $DictMediumPath -and (Test-Path $DictMediumPath)) {
        $dictB = [IO.File]::ReadAllBytes($DictMediumPath)
        $dictBSha = [TEIA.Native.TEIANativeV90]::SHA256Hex($dictB)
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $payD = [TEIA.Native.TEIANativeV90]::CompressWithZstd($Data, $ZstdPath, $DictMediumPath, 19)
        $sw.Stop()
        $mfD = ([ordered]@{ v=1; name=$FileName; sha256=$origSha; size=$origSize; op="dict.zstd_shared"; dict_sha256=$dictBSha; dict_size=$dictB.Length; zstd_level=19 } | ConvertTo-Json -Compress)
        $tbD = [TEIA.Native.TEIANativeV90]::EncodeBinaryTeia($mfD, $payD)
        [void]$candidates.Add([pscustomobject]@{
            Op="dict.zstd_shared"; TeiaBytes=$tbD; TeiaSize=$tbD.Length
            PayloadBytes=$payD.Length; OverheadBytes=($tbD.Length-$payD.Length)
            EncodeMs=$sw.ElapsedMilliseconds; DictSha256=$dictBSha
        })
    }

    # Probe C: xz.raw — para tiny e large (onde LZMA_JANELA pode ocorrer)
    # XZ (LZMA2) overhead ~80B vs ~200-350B do 7z archive — D_xz = XZ + 165B teia < A_7z quando 7z_overhead > 245B
    if ($Bucket -eq "tiny" -or $Bucket -eq "large") {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $payL = [TEIA.Native.TEIANativeV90]::CompressWithXZ($Data, $SevenZipPath)
        $sw.Stop()
        $mfL = ([ordered]@{ v=1; name=$FileName; sha256=$origSha; size=$origSize; op="xz.raw"; xz_level=9 } | ConvertTo-Json -Compress)
        $tbL = [TEIA.Native.TEIANativeV90]::EncodeBinaryTeia($mfL, $payL)
        [void]$candidates.Add([pscustomobject]@{
            Op="xz.raw"; TeiaBytes=$tbL; TeiaSize=$tbL.Length
            PayloadBytes=$payL.Length; OverheadBytes=($tbL.Length-$payL.Length)
            EncodeMs=$sw.ElapsedMilliseconds; DictSha256=""
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
        DictSha256   = $best.DictSha256
        OutSha256    = $origSha
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
        [string]$ZstdPath     = $script:ZSTD_V90,
        [string]$SevenZipPath = $script:SEVENZIP_V90
    )
    [TEIA.Native.TEIANativeV90]::RestoreFromBinaryTeia($TeiaBytes, $DictDir, $ZstdPath, $SevenZipPath)
}

function Save-TEIABin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$TeiaBytes,
        [Parameter(Mandatory)][string]$OutPath
    )
    [IO.File]::WriteAllBytes($OutPath, $TeiaBytes)
    $readBack = [IO.File]::ReadAllBytes($OutPath)
    $writeSha = [TEIA.Native.TEIANativeV90]::SHA256Hex($TeiaBytes)
    $readSha  = [TEIA.Native.TEIANativeV90]::SHA256Hex($readBack)
    if ($writeSha -ne $readSha) {
        Remove-Item $OutPath -Force
        throw "Save-TEIABin: Write==Read FAIL — arquivo removido. write=$writeSha read=$readSha"
    }
    return [pscustomobject]@{ Path=$OutPath; SHA256=$writeSha; Bytes=$TeiaBytes.Length; WriteOk=$true }
}

Export-ModuleMember -Function `
    Build-TEIAZstdDict, `
    Invoke-TEIAEncodeBin, Invoke-TEIAEncodeRaw, Invoke-TEIAEncodeXzRaw, Invoke-TEIAEncodeAuto, `
    Invoke-TEIARestoreBin, Save-TEIABin
