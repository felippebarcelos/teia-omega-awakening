#Requires -Version 7
# TEIA-Core-v0.8.1.psm1
# Motor de reconstrução procedural — Formato Binário Canônico .teia
# Delta vs v0.8.0:
#   • Adiciona opcode "zstd.raw" — Zstd sem dicionário, container .teia intacto
#   • Invoke-TEIAEncodeRaw — codifica sem dict (tiny e large bucket)
#   • RestoreFromBinaryTeia aceita op="zstd.raw" e op="dict.zstd_shared"
#   • dictDir pode ser vazio quando op="zstd.raw"
# Classe: TEIA.Native.TEIANativeV81
# Formato .teia: VER_MAJOR=0, VER_MINOR=8 (mesmo formato v0.8.0; apenas opcode novo)

$script:SEVENZIP_V81   = "C:\Program Files\7-Zip\7z.exe"
$script:ZSTD_V81       = "D:\TEIA_CLAUDE_AWAKENING\_tools\zstd\zstd-v1.5.6-win64\zstd.exe"

if (-not ('TEIA.Native.TEIANativeV81' -as [type])) {
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
    public static class TEIANativeV81 {

        private static readonly byte[] TEIA_MAGIC = { 0x54, 0x45, 0x49, 0x41 };
        private const ushort VER_MAJOR = 0;
        private const ushort VER_MINOR = 8;
        private const int HEADER_FIXED = 12;

        public static string SHA256Hex(byte[] data) {
            using var sha = SHA256.Create();
            return BitConverter.ToString(sha.ComputeHash(data))
                               .Replace("-", "").ToLowerInvariant();
        }

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

            using var doc = JsonDocument.Parse(manifestJson);
            var root = doc.RootElement;

            string op          = root.GetProperty("op").GetString();
            string expectedSha = root.GetProperty("sha256").GetString().ToLowerInvariant();

            byte[] result;

            if (op == "zstd.raw") {
                // Zstd sem dicionário — decompress direto
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

            } else {
                throw new NotSupportedException($"Opcode não suportado: {op}");
            }

            // SHA-256 verify — throw+rollback antes de qualquer escrita em disco
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
        [string]$ZstdPath  = $script:ZSTD_V81
    )
    if (-not (Test-Path $ZstdPath)) { throw "Build-TEIAZstdDict: zstd.exe não encontrado: $ZstdPath" }

    $valid = @($TrainingFiles | Where-Object { Test-Path $_ })
    if ($valid.Count -eq 0) { throw "Build-TEIAZstdDict: nenhum arquivo de treinamento válido" }

    [IO.Directory]::CreateDirectory($OutputDir) | Out-Null

    $tmpDict = Join-Path $OutputDir "teia_v81_train_tmp.zstd-dict"
    if (Test-Path $tmpDict) { Remove-Item $tmpDict -Force }

    Write-Host "[ZSTD TRAIN v0.8.1] $($valid.Count) arquivo(s) | maxdict=$MaxDictBytes B"
    $sw = [Diagnostics.Stopwatch]::StartNew()
    [TEIA.Native.TEIANativeV81]::TrainZstdDict([string[]]$valid, $tmpDict, $MaxDictBytes, $ZstdPath)
    $sw.Stop()

    if (-not (Test-Path $tmpDict)) { throw "Build-TEIAZstdDict: treinamento falhou" }

    $dictBytes = [IO.File]::ReadAllBytes($tmpDict)
    $dictSha   = [TEIA.Native.TEIANativeV81]::SHA256Hex($dictBytes)
    $dictPath  = Join-Path $OutputDir ($dictSha + ".zstd-dict")
    [IO.File]::WriteAllBytes($dictPath, $dictBytes)
    Remove-Item $tmpDict -Force

    Write-Host "[ZSTD TRAIN v0.8.1] $($dictBytes.Length) bytes | SHA: $($dictSha.Substring(0,16))... | $($sw.ElapsedMilliseconds)ms"
    Write-Host "[ZSTD TRAIN v0.8.1] Salvo: $dictPath"

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
        Codifica dados com dicionário Zstd → formato binário .teia (op: dict.zstd_shared).
        Overhead = 12B header + ~245B manifest JSON. Sem Base64.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [Parameter(Mandatory)][string]$DictPath,
        [string]$FileName  = "output.bin",
        [string]$ZstdPath  = $script:ZSTD_V81,
        [int]$Level        = 19
    )
    if (-not (Test-Path $DictPath))  { throw "Invoke-TEIAEncodeBin: dict não encontrado: $DictPath" }
    if (-not (Test-Path $ZstdPath)) { throw "Invoke-TEIAEncodeBin: zstd.exe não encontrado: $ZstdPath" }

    $dictBytes = [IO.File]::ReadAllBytes($DictPath)
    $dictSha   = [TEIA.Native.TEIANativeV81]::SHA256Hex($dictBytes)
    $dictSize  = $dictBytes.Length
    $origSha   = [TEIA.Native.TEIANativeV81]::SHA256Hex($Data)
    $origSize  = $Data.LongLength

    $sw = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV81]::CompressWithZstd($Data, $ZstdPath, $DictPath, $Level)
    $sw.Stop()

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

    $teiaBytes     = [TEIA.Native.TEIANativeV81]::EncodeBinaryTeia($manifestJson, $compressed)
    $teiaSize      = $teiaBytes.Length
    $overheadBytes = $teiaSize - $compressed.Length

    return [pscustomobject]@{
        TeiaBytes       = $teiaBytes
        TeiaSize        = $teiaSize
        PayloadBytes    = $compressed.Length
        ManifestBytes   = $manifestBytes
        HeaderBytes     = 12
        OverheadBytes   = $overheadBytes
        DictSha256      = $dictSha
        DictSize        = $dictSize
        OutSha256       = $origSha
        OutBytes        = $origSize
        RawRatioPct     = [math]::Round($compressed.Length / $origSize * 100, 4)
        NetRatioPct     = [math]::Round($teiaSize / $origSize * 100, 4)
        EncodeMs        = $sw.ElapsedMilliseconds
        Op              = "dict.zstd_shared"
    }
}

function Invoke-TEIAEncodeRaw {
    <#
    .SYNOPSIS
        Codifica dados sem dicionário → formato binário .teia (op: zstd.raw).
        Para buckets tiny (<5KB) e large (>500KB) onde dict é contraproducente.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [string]$FileName  = "output.bin",
        [string]$ZstdPath  = $script:ZSTD_V81,
        [int]$Level        = 19
    )
    if (-not (Test-Path $ZstdPath)) { throw "Invoke-TEIAEncodeRaw: zstd.exe não encontrado: $ZstdPath" }

    $origSha  = [TEIA.Native.TEIANativeV81]::SHA256Hex($Data)
    $origSize = $Data.LongLength

    $sw = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV81]::CompressWithZstd($Data, $ZstdPath, "", $Level)
    $sw.Stop()

    $manifest = [ordered]@{
        v          = 1
        name       = $FileName
        sha256     = $origSha
        size       = $origSize
        op         = "zstd.raw"
        zstd_level = $Level
    }
    $manifestJson  = $manifest | ConvertTo-Json -Compress -Depth 3
    $manifestBytes = [Text.Encoding]::UTF8.GetByteCount($manifestJson)

    $teiaBytes     = [TEIA.Native.TEIANativeV81]::EncodeBinaryTeia($manifestJson, $compressed)
    $teiaSize      = $teiaBytes.Length
    $overheadBytes = $teiaSize - $compressed.Length

    return [pscustomobject]@{
        TeiaBytes       = $teiaBytes
        TeiaSize        = $teiaSize
        PayloadBytes    = $compressed.Length
        ManifestBytes   = $manifestBytes
        HeaderBytes     = 12
        OverheadBytes   = $overheadBytes
        DictSha256      = ""
        DictSize        = 0
        OutSha256       = $origSha
        OutBytes        = $origSize
        RawRatioPct     = [math]::Round($compressed.Length / $origSize * 100, 4)
        NetRatioPct     = [math]::Round($teiaSize / $origSize * 100, 4)
        EncodeMs        = $sw.ElapsedMilliseconds
        Op              = "zstd.raw"
    }
}

function Invoke-TEIARestoreBin {
    <#
    .SYNOPSIS
        Restaura arquivo .teia (qualquer opcode suportado: dict.zstd_shared, zstd.raw).
        SHA-256 verificado — throw+rollback em divergência.
        DictDir pode ser vazio para op=zstd.raw.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$TeiaBytes,
        [string]$DictDir  = "",
        [string]$ZstdPath = $script:ZSTD_V81
    )
    [TEIA.Native.TEIANativeV81]::RestoreFromBinaryTeia($TeiaBytes, $DictDir, $ZstdPath)
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

    $readBack = [IO.File]::ReadAllBytes($OutPath)
    $writeSha = [TEIA.Native.TEIANativeV81]::SHA256Hex($TeiaBytes)
    $readSha  = [TEIA.Native.TEIANativeV81]::SHA256Hex($readBack)
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

Export-ModuleMember -Function Build-TEIAZstdDict, Invoke-TEIAEncodeBin, Invoke-TEIAEncodeRaw, Invoke-TEIARestoreBin, Save-TEIABin
