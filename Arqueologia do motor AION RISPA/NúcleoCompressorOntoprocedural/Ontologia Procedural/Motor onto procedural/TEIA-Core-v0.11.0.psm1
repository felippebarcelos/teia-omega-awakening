#Requires -Version 7
# TEIA-Core-v0.11.0.psm1
# Motor de reconstrução procedural — LZMA1 Raw opcode
# Delta vs v0.10.0:
#   • Novo opcode cmp.lzma (algo_byte=0x01): LZMA1 FORMAT_ALONE via Python lzma module
#   • Python preset=9|EXTREME: comprime melhor que LZMA2/XZ em logs e tokenizers
#   • Overhead igual a cmp.xz (~66-86B) mas payload LZMA1 < LZMA2 → ganha D8 losses
#   • RestoreFromBinaryTeia: VER_MINOR 9 (JSON), 10 cmp.zstd/cmp.xz/cmp.lzma
#   • Invoke-TEIAEncodeAuto: PythonPath param; cmp.lzma probe para small/medium/large
#   • Probe sets: tiny→{cmp.zstd} | small→{cmp.zstd,cmp.lzma,dict} |
#                 medium→{cmp.lzma,dict,cmp.zstd} | large→{cmp.lzma,cmp.xz,zstd.raw}
# Classe: TEIA.Native.TEIANativeV110
# Formato compacto: VER_MAJOR=0, VER_MINOR=10 (reusa — apenas novo algo_byte)

$script:SEVENZIP_V110 = "C:\Program Files\7-Zip\7z.exe"
$script:ZSTD_V110     = "D:\TEIA_CLAUDE_AWAKENING\_tools\zstd\zstd-v1.5.6-win64\zstd.exe"
$script:PYTHON_V110   = "D:\bruto\TEIA\TEIA_ATLAS\Materia_Bruta\D_Drive\TEIA_Data\python\python.exe"

# Layout binário manifest compacto (VER_MINOR=10):
#   byte[0]   format_byte = 0x01 (binary manifest v1)
#   byte[1]   algo_byte: 0x00=cmp.zstd | 0x01=cmp.lzma | 0x02=cmp.xz
#   byte[2-9] orig_size (uint64 LE)
#   byte[10-41] sha256 (32 raw bytes)
#   byte[42]  name_len (uint8)
#   byte[43..] name (UTF-8, name_len bytes)
# Overhead = 12B header + (43 + name_len) bytes manifest

if (-not ('TEIA.Native.TEIANativeV110' -as [type])) {
    Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace TEIA.Native {
    public static class TEIANativeV110 {

        private static readonly byte[] TEIA_MAGIC = { 0x54, 0x45, 0x49, 0x41 };
        private const ushort VER_MAJOR      = 0;
        private const ushort VER_MINOR_JSON = 9;
        private const ushort VER_MINOR_CMP  = 10;
        private const int    HEADER_FIXED   = 12;

        public const byte ALGO_CMP_ZSTD = 0x00;
        public const byte ALGO_CMP_LZMA = 0x01;
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

        private static string RunProcess(string exe, string args, int timeoutMs = 300000) {
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

        // ── LZMA1 (FORMAT_ALONE via Python) ───────────────────────────────────────

        public static byte[] CompressWithLzma1(byte[] data, string pythonPath) {
            string tmpIn     = Path.Combine(Path.GetTempPath(), $"teia_lzma_in_{Guid.NewGuid():N}.bin");
            string tmpOut    = Path.Combine(Path.GetTempPath(), $"teia_lzma_out_{Guid.NewGuid():N}.lzma");
            string tmpScript = Path.Combine(Path.GetTempPath(), $"teia_lzma_c_{Guid.NewGuid():N}.py");
            try {
                File.WriteAllBytes(tmpIn, data);
                // FORMAT_ALONE (2) = .lzma legacy. PRESET_EXTREME = 0x20000000
                string py = "import lzma,sys\n" +
                            "with open(sys.argv[1],'rb') as f: d=f.read()\n" +
                            "c=lzma.compress(d,format=lzma.FORMAT_ALONE,preset=9|lzma.PRESET_EXTREME)\n" +
                            "open(sys.argv[2],'wb').write(c)\n";
                File.WriteAllText(tmpScript, py, new UTF8Encoding(false));
                RunProcess(pythonPath, $"\"{tmpScript}\" \"{tmpIn}\" \"{tmpOut}\"");
                if (!File.Exists(tmpOut))
                    throw new Exception($"CompressWithLzma1: output não criado: {tmpOut}");
                return File.ReadAllBytes(tmpOut);
            } finally {
                if (File.Exists(tmpIn))     File.Delete(tmpIn);
                if (File.Exists(tmpOut))    File.Delete(tmpOut);
                if (File.Exists(tmpScript)) File.Delete(tmpScript);
            }
        }

        public static byte[] DecompressWithLzma1(byte[] lzmaData, string pythonPath) {
            string tmpIn     = Path.Combine(Path.GetTempPath(), $"teia_lzma_in_{Guid.NewGuid():N}.lzma");
            string tmpOut    = Path.Combine(Path.GetTempPath(), $"teia_lzma_out_{Guid.NewGuid():N}.bin");
            string tmpScript = Path.Combine(Path.GetTempPath(), $"teia_lzma_d_{Guid.NewGuid():N}.py");
            try {
                File.WriteAllBytes(tmpIn, lzmaData);
                string py = "import lzma,sys\n" +
                            "with open(sys.argv[1],'rb') as f: d=f.read()\n" +
                            "c=lzma.decompress(d,format=lzma.FORMAT_ALONE)\n" +
                            "open(sys.argv[2],'wb').write(c)\n";
                File.WriteAllText(tmpScript, py, new UTF8Encoding(false));
                RunProcess(pythonPath, $"\"{tmpScript}\" \"{tmpIn}\" \"{tmpOut}\"");
                if (!File.Exists(tmpOut))
                    throw new Exception($"DecompressWithLzma1: output não criado: {tmpOut}");
                return File.ReadAllBytes(tmpOut);
            } finally {
                if (File.Exists(tmpIn))     File.Delete(tmpIn);
                if (File.Exists(tmpOut))    File.Delete(tmpOut);
                if (File.Exists(tmpScript)) File.Delete(tmpScript);
            }
        }

        // ── Zstd ─────────────────────────────────────────────────────────────────

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

        // ── XZ/LZMA2 ─────────────────────────────────────────────────────────────

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
                if (File.Exists(tmpIn))        File.Delete(tmpIn);
                if (Directory.Exists(tmpDir))  Directory.Delete(tmpDir, true);
            }
        }

        // ── Encode helpers ────────────────────────────────────────────────────────

        public static byte[] EncodeCompactTeia(byte algoByte, long origSize,
                                                byte[] sha256Raw, string name, byte[] payload) {
            byte[] nameBytes = Encoding.UTF8.GetBytes(name);
            if (nameBytes.Length > 255) Array.Resize(ref nameBytes, 255);
            int manifestLen = 43 + nameBytes.Length;
            byte[] manifest = new byte[manifestLen];
            manifest[0] = 0x01;
            manifest[1] = algoByte;
            for (int i = 0; i < 8; i++)
                manifest[2 + i] = (byte)((origSize >> (i * 8)) & 0xFF);
            Buffer.BlockCopy(sha256Raw, 0, manifest, 10, 32);
            manifest[42] = (byte)nameBytes.Length;
            Buffer.BlockCopy(nameBytes, 0, manifest, 43, nameBytes.Length);
            int totalLen = HEADER_FIXED + manifestLen + payload.Length;
            byte[] result = new byte[totalLen];
            Buffer.BlockCopy(TEIA_MAGIC, 0, result, 0, 4);
            result[4] = (byte)(VER_MAJOR     & 0xFF); result[5] = (byte)(VER_MAJOR     >> 8);
            result[6] = (byte)(VER_MINOR_CMP & 0xFF); result[7] = (byte)(VER_MINOR_CMP >> 8);
            uint mLen = (uint)manifestLen;
            result[8]  = (byte)(mLen        & 0xFF); result[9]  = (byte)((mLen >>  8) & 0xFF);
            result[10] = (byte)((mLen >> 16) & 0xFF); result[11] = (byte)((mLen >> 24) & 0xFF);
            Buffer.BlockCopy(manifest, 0, result, HEADER_FIXED, manifestLen);
            Buffer.BlockCopy(payload,  0, result, HEADER_FIXED + manifestLen, payload.Length);
            return result;
        }

        public static byte[] EncodeBinaryTeia(string manifestJson, byte[] payload) {
            byte[] manifestBytes = Encoding.UTF8.GetBytes(manifestJson);
            int totalLen = HEADER_FIXED + manifestBytes.Length + payload.Length;
            byte[] result = new byte[totalLen];
            Buffer.BlockCopy(TEIA_MAGIC, 0, result, 0, 4);
            result[4] = (byte)(VER_MAJOR      & 0xFF); result[5] = (byte)(VER_MAJOR      >> 8);
            result[6] = (byte)(VER_MINOR_JSON & 0xFF); result[7] = (byte)(VER_MINOR_JSON >> 8);
            uint mLen = (uint)manifestBytes.Length;
            result[8]  = (byte)(mLen        & 0xFF); result[9]  = (byte)((mLen >>  8) & 0xFF);
            result[10] = (byte)((mLen >> 16) & 0xFF); result[11] = (byte)((mLen >> 24) & 0xFF);
            Buffer.BlockCopy(manifestBytes, 0, result, HEADER_FIXED, manifestBytes.Length);
            Buffer.BlockCopy(payload, 0, result, HEADER_FIXED + manifestBytes.Length, payload.Length);
            return result;
        }

        // ── Restore — VER_MINOR 9 (JSON), 10 (compact: zstd/lzma/xz) ─────────────

        public static byte[] RestoreFromBinaryTeia(byte[] teiaBytes, string dictDir,
                                                    string zstdPath, string sevenZipPath = "",
                                                    string pythonPath = "") {
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
                throw new InvalidDataException($"VER_MINOR não suportado: {verMin}");
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
                string manifestJson = Encoding.UTF8.GetString(teiaBytes, HEADER_FIXED, (int)mLen);
                using var doc = JsonDocument.Parse(manifestJson);
                var root = doc.RootElement;
                string op = root.GetProperty("op").GetString();
                expectedSha = root.GetProperty("sha256").GetString().ToLowerInvariant();
                if (op == "zstd.raw") {
                    result = DecompressWithZstd(compressed, zstdPath, "");
                } else if (op == "dict.zstd_shared") {
                    if (string.IsNullOrEmpty(dictDir)) throw new ArgumentException("dictDir obrigatório para dict.zstd_shared");
                    string dictSha256 = root.GetProperty("dict_sha256").GetString().ToLowerInvariant();
                    int    dictSzExp  = root.GetProperty("dict_size").GetInt32();
                    string dictFile   = Path.Combine(dictDir, dictSha256 + ".zstd-dict");
                    if (!File.Exists(dictFile)) throw new FileNotFoundException($"Dicionário não encontrado: {dictFile}");
                    byte[] dictBytes = File.ReadAllBytes(dictFile);
                    if (dictBytes.Length != dictSzExp) throw new InvalidDataException("Dict size mismatch");
                    if (SHA256Hex(dictBytes) != dictSha256) throw new InvalidDataException("Dict SHA-256 mismatch");
                    result = DecompressWithZstd(compressed, zstdPath, dictFile);
                } else if (op == "xz.raw") {
                    if (string.IsNullOrEmpty(sevenZipPath)) throw new ArgumentException("sevenZipPath obrigatório para xz.raw");
                    result = DecompressWithXZ(compressed, sevenZipPath);
                } else {
                    throw new NotSupportedException($"Opcode JSON não suportado: {op}");
                }
            } else {
                // VER_MINOR_CMP = 10
                if ((int)mLen < 43)
                    throw new InvalidDataException($"Compact manifest muito curto: {mLen}B");
                byte formatByte = teiaBytes[HEADER_FIXED];
                if (formatByte != 0x01) throw new InvalidDataException($"format_byte={formatByte:X2} != 0x01");
                byte algoByte = teiaBytes[HEADER_FIXED + 1];
                long origSize = 0;
                for (int i = 0; i < 8; i++)
                    origSize |= ((long)teiaBytes[HEADER_FIXED + 2 + i]) << (i * 8);
                byte[] sha256Raw = new byte[32];
                Buffer.BlockCopy(teiaBytes, HEADER_FIXED + 10, sha256Raw, 0, 32);
                expectedSha = BitConverter.ToString(sha256Raw).Replace("-", "").ToLowerInvariant();

                if (algoByte == ALGO_CMP_ZSTD) {
                    result = DecompressWithZstd(compressed, zstdPath, "");
                } else if (algoByte == ALGO_CMP_LZMA) {
                    if (string.IsNullOrEmpty(pythonPath)) throw new ArgumentException("pythonPath obrigatório para cmp.lzma");
                    result = DecompressWithLzma1(compressed, pythonPath);
                } else if (algoByte == ALGO_CMP_XZ) {
                    if (string.IsNullOrEmpty(sevenZipPath)) throw new ArgumentException("sevenZipPath obrigatório para cmp.xz");
                    result = DecompressWithXZ(compressed, sevenZipPath);
                } else {
                    throw new NotSupportedException($"Compact algo_byte=0x{algoByte:X2} não suportado");
                }
            }

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
            (uint)(data[offset] | (data[offset+1]<<8) | (data[offset+2]<<16) | (data[offset+3]<<24));
    }
}
'@
}

# ── Interfaces públicas PowerShell ─────────────────────────────────────────────────

function Build-TEIAZstdDict {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$TrainingFiles,
        [Parameter(Mandatory)][string]$OutputDir,
        [int]$MaxDictBytes = 112640,
        [string]$ZstdPath  = $script:ZSTD_V110
    )
    if (-not (Test-Path $ZstdPath)) { throw "Build-TEIAZstdDict: zstd.exe não encontrado: $ZstdPath" }
    $valid = @($TrainingFiles | Where-Object { Test-Path $_ })
    if ($valid.Count -eq 0) { throw "Build-TEIAZstdDict: nenhum arquivo de treinamento válido" }
    [IO.Directory]::CreateDirectory($OutputDir) | Out-Null
    $tmpDict = Join-Path $OutputDir "teia_v110_train_tmp.zstd-dict"
    if (Test-Path $tmpDict) { Remove-Item $tmpDict -Force }
    Write-Host "[ZSTD TRAIN v0.11.0] $($valid.Count) arquivo(s) | maxdict=$MaxDictBytes B"
    $sw = [Diagnostics.Stopwatch]::StartNew()
    [TEIA.Native.TEIANativeV110]::TrainZstdDict([string[]]$valid, $tmpDict, $MaxDictBytes, $ZstdPath)
    $sw.Stop()
    if (-not (Test-Path $tmpDict)) { throw "Build-TEIAZstdDict: treinamento falhou" }
    $dictBytes = [IO.File]::ReadAllBytes($tmpDict)
    $dictSha   = [TEIA.Native.TEIANativeV110]::SHA256Hex($dictBytes)
    $dictPath  = Join-Path $OutputDir ($dictSha + ".zstd-dict")
    [IO.File]::WriteAllBytes($dictPath, $dictBytes)
    Remove-Item $tmpDict -Force
    Write-Host "[ZSTD TRAIN v0.11.0] $($dictBytes.Length)B | SHA: $($dictSha.Substring(0,16))... | $($sw.ElapsedMilliseconds)ms"
    return [pscustomobject]@{ DictPath=$dictPath; DictSha256=$dictSha; DictBytes=$dictBytes.Length; TrainMs=$sw.ElapsedMilliseconds }
}

function Invoke-TEIAEncodeBin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [Parameter(Mandatory)][string]$DictPath,
        [string]$FileName = "output.bin",
        [string]$ZstdPath = $script:ZSTD_V110,
        [int]$Level = 19
    )
    $dictBytes = [IO.File]::ReadAllBytes($DictPath)
    $dictSha   = [TEIA.Native.TEIANativeV110]::SHA256Hex($dictBytes)
    $origSha   = [TEIA.Native.TEIANativeV110]::SHA256Hex($Data)
    $origSize  = $Data.LongLength
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV110]::CompressWithZstd($Data, $ZstdPath, $DictPath, $Level)
    $sw.Stop()
    $manifest = [ordered]@{ v=1; name=$FileName; sha256=$origSha; size=$origSize
                             op="dict.zstd_shared"; dict_sha256=$dictSha; dict_size=$dictBytes.Length; zstd_level=$Level }
    $mJson     = $manifest | ConvertTo-Json -Compress -Depth 3
    $teiaBytes = [TEIA.Native.TEIANativeV110]::EncodeBinaryTeia($mJson, $compressed)
    return [pscustomobject]@{
        TeiaBytes=$teiaBytes; TeiaSize=$teiaBytes.Length; PayloadBytes=$compressed.Length
        OverheadBytes=($teiaBytes.Length-$compressed.Length)
        OutSha256=$origSha; OutBytes=$origSize
        NetRatioPct=[math]::Round($teiaBytes.Length/$origSize*100,4)
        EncodeMs=$sw.ElapsedMilliseconds; Op="dict.zstd_shared"
    }
}

function Invoke-TEIAEncodeRaw {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [string]$FileName = "output.bin",
        [string]$ZstdPath = $script:ZSTD_V110,
        [int]$Level = 19
    )
    $origSha  = [TEIA.Native.TEIANativeV110]::SHA256Hex($Data)
    $origSize = $Data.LongLength
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV110]::CompressWithZstd($Data, $ZstdPath, "", $Level)
    $sw.Stop()
    $mJson     = ([ordered]@{ v=1; name=$FileName; sha256=$origSha; size=$origSize; op="zstd.raw"; zstd_level=$Level } | ConvertTo-Json -Compress)
    $teiaBytes = [TEIA.Native.TEIANativeV110]::EncodeBinaryTeia($mJson, $compressed)
    return [pscustomobject]@{
        TeiaBytes=$teiaBytes; TeiaSize=$teiaBytes.Length; PayloadBytes=$compressed.Length
        OverheadBytes=($teiaBytes.Length-$compressed.Length)
        OutSha256=$origSha; OutBytes=$origSize
        NetRatioPct=[math]::Round($teiaBytes.Length/$origSize*100,4)
        EncodeMs=$sw.ElapsedMilliseconds; Op="zstd.raw"
    }
}

function Invoke-TEIAEncodeCmpRaw {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [string]$FileName = "output.bin",
        [string]$ZstdPath = $script:ZSTD_V110,
        [int]$Level       = 19
    )
    $origShaRaw = [TEIA.Native.TEIANativeV110]::SHA256Raw($Data)
    $origShaHex = [TEIA.Native.TEIANativeV110]::SHA256Hex($Data)
    $origSize   = $Data.LongLength
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV110]::CompressWithZstd($Data, $ZstdPath, "", $Level)
    $sw.Stop()
    $teiaBytes = [TEIA.Native.TEIANativeV110]::EncodeCompactTeia(
        [TEIA.Native.TEIANativeV110]::ALGO_CMP_ZSTD, $origSize, $origShaRaw, $FileName, $compressed)
    return [pscustomobject]@{
        TeiaBytes=$teiaBytes; TeiaSize=$teiaBytes.Length; PayloadBytes=$compressed.Length
        OverheadBytes=($teiaBytes.Length-$compressed.Length)
        OutSha256=$origShaHex; OutBytes=$origSize
        NetRatioPct=[math]::Round($teiaBytes.Length/$origSize*100,4)
        EncodeMs=$sw.ElapsedMilliseconds; Op="cmp.zstd"
    }
}

function Invoke-TEIAEncodeCmpLzma {
    <#
    .SYNOPSIS
        Compact manifest + LZMA1 FORMAT_ALONE via Python (cmp.lzma). VER_MINOR=10, algo_byte=0x01.
        Python preset=9|EXTREME — melhor que LZMA2/XZ em logs e tokenizers.
        Ganha D8 losses estruturais: large logs (2-22B margin → -57 a -8130B), tokenizers (-548/-1070B).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [string]$FileName   = "output.bin",
        [string]$PythonPath = $script:PYTHON_V110
    )
    if (-not (Test-Path $PythonPath)) { throw "Invoke-TEIAEncodeCmpLzma: python não encontrado: $PythonPath" }
    $origShaRaw = [TEIA.Native.TEIANativeV110]::SHA256Raw($Data)
    $origShaHex = [TEIA.Native.TEIANativeV110]::SHA256Hex($Data)
    $origSize   = $Data.LongLength
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV110]::CompressWithLzma1($Data, $PythonPath)
    $sw.Stop()
    $teiaBytes = [TEIA.Native.TEIANativeV110]::EncodeCompactTeia(
        [TEIA.Native.TEIANativeV110]::ALGO_CMP_LZMA, $origSize, $origShaRaw, $FileName, $compressed)
    return [pscustomobject]@{
        TeiaBytes=$teiaBytes; TeiaSize=$teiaBytes.Length; PayloadBytes=$compressed.Length
        OverheadBytes=($teiaBytes.Length-$compressed.Length)
        OutSha256=$origShaHex; OutBytes=$origSize
        NetRatioPct=[math]::Round($teiaBytes.Length/$origSize*100,4)
        EncodeMs=$sw.ElapsedMilliseconds; Op="cmp.lzma"
    }
}

function Invoke-TEIAEncodeCmpXz {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [string]$FileName     = "output.bin",
        [string]$SevenZipPath = $script:SEVENZIP_V110
    )
    $origShaRaw = [TEIA.Native.TEIANativeV110]::SHA256Raw($Data)
    $origShaHex = [TEIA.Native.TEIANativeV110]::SHA256Hex($Data)
    $origSize   = $Data.LongLength
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $compressed = [TEIA.Native.TEIANativeV110]::CompressWithXZ($Data, $SevenZipPath)
    $sw.Stop()
    $teiaBytes = [TEIA.Native.TEIANativeV110]::EncodeCompactTeia(
        [TEIA.Native.TEIANativeV110]::ALGO_CMP_XZ, $origSize, $origShaRaw, $FileName, $compressed)
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
        Selector Engine v0.11: proba todos os candidatos e retorna menor D.
        Novidade vs v0.10: cmp.lzma (LZMA1 FORMAT_ALONE) via Python.
        tiny:   {cmp.zstd}
        small:  {cmp.zstd, cmp.lzma(se py), dict-small(se avail)}
        medium: {cmp.lzma(se py), dict-medium(se avail), cmp.zstd(sem dict)}
        large:  {cmp.lzma(se py), cmp.xz, zstd.raw}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [Parameter(Mandatory)][string]$Bucket,
        [string]$FileName       = "output.bin",
        [string]$DictSmallPath  = "",
        [string]$DictMediumPath = "",
        [string]$ZstdPath       = $script:ZSTD_V110,
        [string]$SevenZipPath   = $script:SEVENZIP_V110,
        [string]$PythonPath     = $script:PYTHON_V110
    )

    $hasPy = $PythonPath -and (Test-Path $PythonPath -EA SilentlyContinue)
    $origShaRaw = [TEIA.Native.TEIANativeV110]::SHA256Raw($Data)
    $origShaHex = [TEIA.Native.TEIANativeV110]::SHA256Hex($Data)
    $origSize   = $Data.LongLength
    $candidates = [System.Collections.ArrayList]::new()
    $swTotal    = [Diagnostics.Stopwatch]::StartNew()

    # ── cmp.zstd — tiny sempre; small sem dict; medium sem dict ──────────────────
    $probeCmpZstd = $Bucket -eq "tiny" -or $Bucket -eq "small" -or
                    ($Bucket -eq "medium" -and -not $DictMediumPath)
    if ($probeCmpZstd) {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $payZ = [TEIA.Native.TEIANativeV110]::CompressWithZstd($Data, $ZstdPath, "", 19)
        $sw.Stop()
        $tb = [TEIA.Native.TEIANativeV110]::EncodeCompactTeia(
            [TEIA.Native.TEIANativeV110]::ALGO_CMP_ZSTD, $origSize, $origShaRaw, $FileName, $payZ)
        [void]$candidates.Add([pscustomobject]@{
            Op="cmp.zstd"; TeiaBytes=$tb; TeiaSize=$tb.Length
            PayloadBytes=$payZ.Length; OverheadBytes=($tb.Length-$payZ.Length); EncodeMs=$sw.ElapsedMilliseconds
        })
    }

    # ── cmp.lzma — small, medium, large (não tiny: overhead excede margem <5KB) ──
    if ($hasPy -and $Bucket -ne "tiny") {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $payL = [TEIA.Native.TEIANativeV110]::CompressWithLzma1($Data, $PythonPath)
        $sw.Stop()
        $tb = [TEIA.Native.TEIANativeV110]::EncodeCompactTeia(
            [TEIA.Native.TEIANativeV110]::ALGO_CMP_LZMA, $origSize, $origShaRaw, $FileName, $payL)
        [void]$candidates.Add([pscustomobject]@{
            Op="cmp.lzma"; TeiaBytes=$tb; TeiaSize=$tb.Length
            PayloadBytes=$payL.Length; OverheadBytes=($tb.Length-$payL.Length); EncodeMs=$sw.ElapsedMilliseconds
        })
    }

    # ── dict.zstd_shared — small (dict-small) ou medium (dict-medium) ────────────
    if ($Bucket -eq "small" -and $DictSmallPath -and (Test-Path $DictSmallPath)) {
        $dictB = [IO.File]::ReadAllBytes($DictSmallPath)
        $dictBSha = [TEIA.Native.TEIANativeV110]::SHA256Hex($dictB)
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $payD = [TEIA.Native.TEIANativeV110]::CompressWithZstd($Data, $ZstdPath, $DictSmallPath, 19)
        $sw.Stop()
        $mfD = ([ordered]@{ v=1; name=$FileName; sha256=$origShaHex; size=$origSize
                             op="dict.zstd_shared"; dict_sha256=$dictBSha; dict_size=$dictB.Length; zstd_level=19 } | ConvertTo-Json -Compress)
        $tb = [TEIA.Native.TEIANativeV110]::EncodeBinaryTeia($mfD, $payD)
        [void]$candidates.Add([pscustomobject]@{
            Op="dict.zstd_shared"; TeiaBytes=$tb; TeiaSize=$tb.Length
            PayloadBytes=$payD.Length; OverheadBytes=($tb.Length-$payD.Length); EncodeMs=$sw.ElapsedMilliseconds
        })
    } elseif ($Bucket -eq "medium" -and $DictMediumPath -and (Test-Path $DictMediumPath)) {
        $dictB = [IO.File]::ReadAllBytes($DictMediumPath)
        $dictBSha = [TEIA.Native.TEIANativeV110]::SHA256Hex($dictB)
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $payD = [TEIA.Native.TEIANativeV110]::CompressWithZstd($Data, $ZstdPath, $DictMediumPath, 19)
        $sw.Stop()
        $mfD = ([ordered]@{ v=1; name=$FileName; sha256=$origShaHex; size=$origSize
                             op="dict.zstd_shared"; dict_sha256=$dictBSha; dict_size=$dictB.Length; zstd_level=19 } | ConvertTo-Json -Compress)
        $tb = [TEIA.Native.TEIANativeV110]::EncodeBinaryTeia($mfD, $payD)
        [void]$candidates.Add([pscustomobject]@{
            Op="dict.zstd_shared"; TeiaBytes=$tb; TeiaSize=$tb.Length
            PayloadBytes=$payD.Length; OverheadBytes=($tb.Length-$payD.Length); EncodeMs=$sw.ElapsedMilliseconds
        })
    }

    # ── large: zstd.raw + cmp.xz (ambos para cobertura completa) ─────────────────
    if ($Bucket -eq "large") {
        # zstd.raw
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $payZ2 = [TEIA.Native.TEIANativeV110]::CompressWithZstd($Data, $ZstdPath, "", 19)
        $sw.Stop()
        $mfZ = ([ordered]@{ v=1; name=$FileName; sha256=$origShaHex; size=$origSize; op="zstd.raw"; zstd_level=19 } | ConvertTo-Json -Compress)
        $tb = [TEIA.Native.TEIANativeV110]::EncodeBinaryTeia($mfZ, $payZ2)
        [void]$candidates.Add([pscustomobject]@{
            Op="zstd.raw"; TeiaBytes=$tb; TeiaSize=$tb.Length
            PayloadBytes=$payZ2.Length; OverheadBytes=($tb.Length-$payZ2.Length); EncodeMs=$sw.ElapsedMilliseconds
        })
        # cmp.xz — LZMA2 para comparação vs cmp.lzma LZMA1
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $payXZ = [TEIA.Native.TEIANativeV110]::CompressWithXZ($Data, $SevenZipPath)
        $sw.Stop()
        $msXZ = $sw.ElapsedMilliseconds
        $tbCX = [TEIA.Native.TEIANativeV110]::EncodeCompactTeia(
            [TEIA.Native.TEIANativeV110]::ALGO_CMP_XZ, $origSize, $origShaRaw, $FileName, $payXZ)
        [void]$candidates.Add([pscustomobject]@{
            Op="cmp.xz"; TeiaBytes=$tbCX; TeiaSize=$tbCX.Length
            PayloadBytes=$payXZ.Length; OverheadBytes=($tbCX.Length-$payXZ.Length); EncodeMs=$msXZ
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
        [string]$ZstdPath     = $script:ZSTD_V110,
        [string]$SevenZipPath = $script:SEVENZIP_V110,
        [string]$PythonPath   = $script:PYTHON_V110
    )
    [TEIA.Native.TEIANativeV110]::RestoreFromBinaryTeia($TeiaBytes, $DictDir, $ZstdPath, $SevenZipPath, $PythonPath)
}

function Save-TEIABin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$TeiaBytes,
        [Parameter(Mandatory)][string]$OutPath
    )
    [IO.File]::WriteAllBytes($OutPath, $TeiaBytes)
    $readBack = [IO.File]::ReadAllBytes($OutPath)
    $writeSha = [TEIA.Native.TEIANativeV110]::SHA256Hex($TeiaBytes)
    $readSha  = [TEIA.Native.TEIANativeV110]::SHA256Hex($readBack)
    if ($writeSha -ne $readSha) {
        Remove-Item $OutPath -Force
        throw "Save-TEIABin: Write==Read FAIL — arquivo removido. write=$writeSha read=$readSha"
    }
    return [pscustomobject]@{ Path=$OutPath; SHA256=$writeSha; Bytes=$TeiaBytes.Length; WriteOk=$true }
}

Export-ModuleMember -Function `
    Build-TEIAZstdDict, `
    Invoke-TEIAEncodeBin, Invoke-TEIAEncodeRaw, `
    Invoke-TEIAEncodeCmpRaw, Invoke-TEIAEncodeCmpLzma, Invoke-TEIAEncodeCmpXz, `
    Invoke-TEIAEncodeAuto, Invoke-TEIARestoreBin, Save-TEIABin
