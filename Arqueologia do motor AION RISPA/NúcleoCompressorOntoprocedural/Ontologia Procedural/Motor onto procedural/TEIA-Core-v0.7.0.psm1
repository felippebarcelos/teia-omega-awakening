#Requires -Version 7
# TEIA-Core-v0.7.0.psm1
# Motor de reconstrução procedural — hot-path 100% em C# via [Add-Type]
# Novidades vs v0.6.3:
#   • dict.zstd_shared: opcode com Zstd treinado via `zstd --train`
#     - Janela Zstd configurável (até 128MB) — supera LZ77 32KB do GZip
#     - TrainZstdDict, CompressWithZstd, DecompressWithZstd via subprocess zstd.exe
#   • Build-TEIAZstdDict: treina dict Zstd de corpus de arquivos
#   • Invoke-TEIAEncodeZstd / Invoke-TEIARestoreWithZstdDict
#   • Todos os opcodes v0.6.3 preservados (retrocompatível)
# Classe: TEIA.Native.TEIANativeV70

$script:SEVENZIP_MODULE = "C:\Program Files\7-Zip\7z.exe"
$script:ZSTD_DEFAULT    = "D:\TEIA_CLAUDE_AWAKENING\_tools\zstd\zstd-v1.5.6-win64\zstd.exe"

if (-not ('TEIA.Native.TEIANativeV70' -as [type])) {
    Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace TEIA.Native {
    public static class TEIANativeV70 {

        // ── Primitivas de geração ─────────────────────────────────────────────

        public static byte[] FillRepeat(byte val, long count) {
            if (count < 0) throw new ArgumentOutOfRangeException("count", "gen.repeat: count negativo");
            var b = new byte[count];
            if (count == 0) return b;
            b[0] = val;
            long len = 1;
            while (len < count) {
                long c = Math.Min(len, count - len);
                Buffer.BlockCopy(b, 0, b, (int)len, (int)c);
                len += c;
            }
            return b;
        }

        public static byte[] FillPattern(byte[] pat, long repeat) {
            if (pat == null || pat.Length == 0)
                throw new ArgumentException("gen.pattern: padrão vazio");
            long total = (long)pat.Length * repeat;
            var b = new byte[total];
            Buffer.BlockCopy(pat, 0, b, 0, pat.Length);
            long written = pat.Length;
            while (written < total) {
                long c = Math.Min(written, total - written);
                Buffer.BlockCopy(b, 0, b, (int)written, (int)c);
                written += c;
            }
            return b;
        }

        public static byte[] XorBuffer(byte[] data, byte[] key) {
            if (key == null || key.Length == 0)
                throw new ArgumentException("xform.xor: chave vazia");
            var result = new byte[data.Length];
            int klen = key.Length;
            for (int i = 0; i < data.Length; i++)
                result[i] = (byte)(data[i] ^ key[i % klen]);
            return result;
        }

        public static byte[] DecodeRLE(byte[] byteVals, long[] counts) {
            if (byteVals.Length != counts.Length)
                throw new ArgumentException("rle.decode: arrays de comprimento diferente");
            long total = 0;
            for (int i = 0; i < counts.Length; i++) {
                if (counts[i] < 0) throw new ArgumentOutOfRangeException("counts", "rle.decode: contagem negativa");
                total += counts[i];
            }
            var result = new byte[total];
            long offset = 0;
            for (int i = 0; i < byteVals.Length; i++) {
                long n = counts[i];
                if (n == 0) continue;
                result[offset] = byteVals[i];
                long len = 1;
                while (len < n) {
                    long c = Math.Min(len, n - len);
                    Buffer.BlockCopy(result, (int)offset, result, (int)(offset + len), (int)c);
                    len += c;
                }
                offset += n;
            }
            return result;
        }

        public static string SHA256Hex(byte[] data) {
            using (var sha = SHA256.Create()) {
                byte[] h = sha.ComputeHash(data);
                return BitConverter.ToString(h).Replace("-", "").ToLowerInvariant();
            }
        }

        public static byte[] BuildJsonArray(
            int count, string indent, bool wrapArray,
            string[] fieldNames, string[] fieldTypes,
            string[] fieldPatterns, string[] fieldValues,
            int[] fieldSteps, int[] fieldStarts, int[] fieldMods)
        {
            var sb = new StringBuilder();
            if (wrapArray) sb.Append("[\\n");
            for (int i = 0; i < count; i++) {
                sb.Append(indent); sb.Append('{');
                for (int fi = 0; fi < fieldNames.Length; fi++) {
                    sb.Append('"'); sb.Append(fieldNames[fi]); sb.Append("\":");
                    switch (fieldTypes[fi]) {
                        case "printf_pattern": {
                            int idx = i * fieldSteps[fi] + fieldStarts[fi];
                            sb.Append('"'); sb.AppendFormat(fieldPatterns[fi], idx); sb.Append('"');
                            break;
                        }
                        case "const_string":
                            sb.Append('"'); sb.Append(fieldValues[fi]); sb.Append('"'); break;
                        case "linear_modulo":
                            sb.Append((i * fieldSteps[fi] + fieldStarts[fi]) % fieldMods[fi]); break;
                        default:
                            throw new ArgumentException("gen.json_structured: tipo desconhecido: " + fieldTypes[fi]);
                    }
                    if (fi < fieldNames.Length - 1) sb.Append(',');
                }
                sb.Append('}');
                if (i < count - 1) sb.Append(',');
                sb.Append('\n');
            }
            if (wrapArray) sb.Append(']');
            return Encoding.UTF8.GetBytes(sb.ToString());
        }

        // ── dict.zstd_shared — Zstd com dicionário treinado ──────────────────

        // Treina dicionário Zstd a partir de N arquivos de corpus.
        // Requer zstd.exe >= 1.5.0 com suporte a --train.
        public static void TrainZstdDict(string[] inputFiles, string dictOutputPath,
                                          int maxDictSize, string zstdPath) {
            if (inputFiles == null || inputFiles.Length == 0)
                throw new ArgumentException("TrainZstdDict: nenhum arquivo de entrada");
            var existing = inputFiles.Where(f => File.Exists(f)).ToArray();
            if (existing.Length == 0)
                throw new FileNotFoundException("TrainZstdDict: nenhum arquivo existe");

            // Cria diretório de saída se necessário
            string outDir = Path.GetDirectoryName(dictOutputPath);
            if (!string.IsNullOrEmpty(outDir)) Directory.CreateDirectory(outDir);

            // zstd --train file1 file2 ... -o {dict} --maxdict {size} -f
            var sb = new StringBuilder();
            sb.Append("--train ");
            foreach (var f in existing) sb.Append("\"").Append(f).Append("\" ");
            sb.Append($"-o \"{dictOutputPath}\" --maxdict {maxDictSize} -f");

            string stderr = RunProcess(zstdPath, sb.ToString());
            if (!File.Exists(dictOutputPath))
                throw new InvalidOperationException(
                    "TrainZstdDict: dicionário não criado. stderr=" + stderr);
        }

        // Comprime data com dicionário Zstd treinado (ou sem dict se dictPath="").
        // level: 1-19 (19 = máxima compressão). Retorna bytes comprimidos.
        public static byte[] CompressWithZstd(byte[] data, string zstdPath,
                                               string dictPath = "", int level = 19) {
            string id     = Guid.NewGuid().ToString("N").Substring(0, 8);
            string tmpIn  = Path.Combine(Path.GetTempPath(), "teia_zstd_in_"  + id);
            string tmpOut = Path.Combine(Path.GetTempPath(), "teia_zstd_out_" + id + ".zst");
            File.WriteAllBytes(tmpIn, data);
            try {
                var args = new StringBuilder($"-{level} ");
                if (!string.IsNullOrEmpty(dictPath)) args.Append($"-D \"{dictPath}\" ");
                args.Append($"\"{tmpIn}\" -o \"{tmpOut}\" --no-progress -f");
                string stderr = RunProcess(zstdPath, args.ToString());
                if (!File.Exists(tmpOut))
                    throw new InvalidOperationException(
                        "CompressWithZstd: saída não criada. stderr=" + stderr);
                return File.ReadAllBytes(tmpOut);
            } finally {
                if (File.Exists(tmpIn))  File.Delete(tmpIn);
                if (File.Exists(tmpOut)) File.Delete(tmpOut);
            }
        }

        // Descomprime dados Zstd (com ou sem dicionário externo).
        public static byte[] DecompressWithZstd(byte[] compressedData, string zstdPath,
                                                  string dictPath = "") {
            string id     = Guid.NewGuid().ToString("N").Substring(0, 8);
            string tmpIn  = Path.Combine(Path.GetTempPath(), "teia_zstd_in_"  + id + ".zst");
            string tmpOut = Path.Combine(Path.GetTempPath(), "teia_zstd_out_" + id);
            File.WriteAllBytes(tmpIn, compressedData);
            try {
                var args = new StringBuilder("-d ");
                if (!string.IsNullOrEmpty(dictPath)) args.Append($"-D \"{dictPath}\" ");
                args.Append($"\"{tmpIn}\" -o \"{tmpOut}\" --no-progress -f");
                string stderr = RunProcess(zstdPath, args.ToString());
                if (!File.Exists(tmpOut))
                    throw new InvalidOperationException(
                        "DecompressWithZstd: saída não criada. stderr=" + stderr);
                return File.ReadAllBytes(tmpOut);
            } finally {
                if (File.Exists(tmpIn))  File.Delete(tmpIn);
                if (File.Exists(tmpOut)) File.Delete(tmpOut);
            }
        }

        // ── Helper de subprocess ──────────────────────────────────────────────

        private static string RunProcess(string exe, string args) {
            var psi = new ProcessStartInfo {
                FileName               = exe,
                Arguments              = args,
                UseShellExecute        = false,
                RedirectStandardOutput = true,
                RedirectStandardError  = true,
                CreateNoWindow         = true
            };
            using (var p = Process.Start(psi)) {
                if (p == null) throw new InvalidOperationException("RunProcess: processo não iniciou: " + exe);
                p.StandardOutput.ReadToEnd();
                string stderr = p.StandardError.ReadToEnd();
                p.WaitForExit();
                if (p.ExitCode != 0)
                    throw new InvalidOperationException(
                        $"RunProcess: exit={p.ExitCode} cmd='{exe} {args.Substring(0, Math.Min(120, args.Length))}...' stderr={stderr}");
                return stderr;
            }
        }

        // ── Helpers privados ──────────────────────────────────────────────────

        private static byte[] BuildJsonArrayFromSchema(JsonElement schema) {
            int count = schema.GetProperty("count").GetInt32();
            JsonElement tmp;
            string indent = schema.TryGetProperty("indent", out tmp) ? tmp.GetString() : "  ";
            bool wrap = schema.TryGetProperty("wrapper", out tmp) && tmp.GetString() == "array";
            var fl = new List<JsonElement>();
            foreach (var f in schema.GetProperty("fields").EnumerateArray()) fl.Add(f);
            int nf = fl.Count;
            var names    = new string[nf]; var types    = new string[nf];
            var patterns = new string[nf]; var values   = new string[nf];
            var steps    = new int[nf];    var starts   = new int[nf]; var mods = new int[nf];
            for (int i = 0; i < nf; i++) {
                var f = fl[i];
                names[i]    = f.GetProperty("name").GetString();
                types[i]    = f.GetProperty("type").GetString();
                patterns[i] = f.TryGetProperty("pattern", out tmp) ? tmp.GetString() : "";
                values[i]   = f.TryGetProperty("value",   out tmp) ? tmp.GetString() : "";
                steps[i]    = f.TryGetProperty("step",    out tmp) ? tmp.GetInt32()  : 1;
                starts[i]   = f.TryGetProperty("start",   out tmp) ? tmp.GetInt32()  : 0;
                mods[i]     = f.TryGetProperty("mod",     out tmp) ? tmp.GetInt32()  : int.MaxValue;
            }
            return BuildJsonArray(count, indent, wrap, names, types, patterns, values, steps, starts, mods);
        }

        private static byte[] DecompressStream(byte[] comp, string algo) {
            using (var inMs = new MemoryStream(comp))
            using (var outMs = new MemoryStream()) {
                switch (algo.ToLowerInvariant()) {
                    case "brotli":
                        using (var ds = new BrotliStream(inMs, CompressionMode.Decompress, false))
                            ds.CopyTo(outMs);
                        break;
                    case "gzip":
                        using (var ds = new GZipStream(inMs, CompressionMode.Decompress, false))
                            ds.CopyTo(outMs);
                        break;
                    default:
                        throw new ArgumentException("lz.decode: algoritmo não suportado: " + algo);
                }
                return outMs.ToArray();
            }
        }

        private static byte[] DecompressLzmaViaSevZip(byte[] comp, string sevenZipPath) {
            string id      = Guid.NewGuid().ToString("N").Substring(0, 8);
            string tmpArch = Path.Combine(Path.GetTempPath(), "teia_lzma_" + id + ".7z");
            string tmpDir  = Path.Combine(Path.GetTempPath(), "teia_lzma_" + id);
            Directory.CreateDirectory(tmpDir);
            File.WriteAllBytes(tmpArch, comp);
            try {
                RunProcess(sevenZipPath, $"e \"{tmpArch}\" \"-o{tmpDir}\" -y");
                string[] files = Directory.GetFiles(tmpDir);
                if (files.Length == 0)
                    throw new InvalidOperationException("fallback.lzma: extração vazia em " + tmpDir);
                return File.ReadAllBytes(files[0]);
            } finally {
                if (File.Exists(tmpArch))     File.Delete(tmpArch);
                if (Directory.Exists(tmpDir)) Directory.Delete(tmpDir, true);
            }
        }

        public static string GetOutName(string seedJson) {
            using (var doc = JsonDocument.Parse(seedJson))
                return doc.RootElement.GetProperty("out").GetProperty("name").GetString();
        }

        // ── RestoreInMemory — streaming SHA-256 + todos os opcodes ───────────
        public static byte[] RestoreInMemory(string seedJson, string sevenZipPath,
                                              string dictDir = "", string zstdPath = "") {
            using (var doc = JsonDocument.Parse(seedJson))
            using (var sha256 = SHA256.Create()) {
                var root  = doc.RootElement;
                var outEl = root.GetProperty("out");
                JsonElement tmp;
                string outSha  = outEl.TryGetProperty("sha256", out tmp) ? tmp.GetString() : null;
                long   outSize = outEl.TryGetProperty("size",   out tmp) ? tmp.GetInt64()  : -1L;

                using (var ms = new MemoryStream()) {
                    foreach (var op in root.GetProperty("plan").EnumerateArray()) {
                        string opCode = op.GetProperty("op").GetString();
                        byte[] buf;
                        switch (opCode) {
                            case "gen.repeat": {
                                int bVal;
                                if      (op.TryGetProperty("byte",  out tmp)) bVal = tmp.GetInt32();
                                else if (op.TryGetProperty("value", out tmp)) bVal = tmp.GetInt32();
                                else throw new ArgumentException("gen.repeat: byte/value ausente");
                                buf = FillRepeat((byte)bVal, op.GetProperty("count").GetInt64());
                                sha256.TransformBlock(buf, 0, buf.Length, null, 0);
                                ms.Write(buf, 0, buf.Length);
                                break;
                            }
                            case "gen.pattern": {
                                byte[] pat;
                                if (op.TryGetProperty("pattern_b64", out tmp)) {
                                    pat = Convert.FromBase64String(tmp.GetString());
                                } else {
                                    var patEl = op.GetProperty("pattern");
                                    var patList = new List<byte>();
                                    foreach (var b in patEl.EnumerateArray()) patList.Add((byte)b.GetInt32());
                                    pat = patList.ToArray();
                                }
                                buf = FillPattern(pat, op.GetProperty("repeat").GetInt64());
                                sha256.TransformBlock(buf, 0, buf.Length, null, 0);
                                ms.Write(buf, 0, buf.Length);
                                break;
                            }
                            case "gen.json_structured": {
                                buf = BuildJsonArrayFromSchema(op.GetProperty("schema"));
                                sha256.TransformBlock(buf, 0, buf.Length, null, 0);
                                ms.Write(buf, 0, buf.Length);
                                break;
                            }
                            case "rle.decode": {
                                var pairs = op.GetProperty("pairs");
                                var bValsL = new List<byte>(); var cntsL = new List<long>();
                                foreach (var pair in pairs.EnumerateArray()) {
                                    bValsL.Add((byte)pair.GetProperty("b").GetInt32());
                                    cntsL.Add(pair.GetProperty("n").GetInt64());
                                }
                                buf = DecodeRLE(bValsL.ToArray(), cntsL.ToArray());
                                sha256.TransformBlock(buf, 0, buf.Length, null, 0);
                                ms.Write(buf, 0, buf.Length);
                                break;
                            }
                            case "dict.ref": {
                                string enc = op.TryGetProperty("encoding", out tmp) ? tmp.GetString() : "utf-8";
                                var encoding = Encoding.GetEncoding(enc);
                                var dictList = new List<string>();
                                foreach (var de in op.GetProperty("dict").EnumerateArray())
                                    dictList.Add(de.GetString());
                                using (var dictMs = new MemoryStream()) {
                                    foreach (var mi in op.GetProperty("map").EnumerateArray()) {
                                        int idx = mi.GetInt32();
                                        if (idx < 0 || idx >= dictList.Count)
                                            throw new ArgumentException("dict.ref: índice " + idx + " fora do intervalo");
                                        byte[] eb = encoding.GetBytes(dictList[idx]);
                                        dictMs.Write(eb, 0, eb.Length);
                                    }
                                    buf = dictMs.ToArray();
                                }
                                sha256.TransformBlock(buf, 0, buf.Length, null, 0);
                                ms.Write(buf, 0, buf.Length);
                                break;
                            }
                            case "literal": {
                                buf = Convert.FromBase64String(op.GetProperty("payload_b64").GetString());
                                sha256.TransformBlock(buf, 0, buf.Length, null, 0);
                                ms.Write(buf, 0, buf.Length);
                                break;
                            }
                            case "lz.decode": {
                                string algo = op.TryGetProperty("algo", out tmp) ? tmp.GetString() : "brotli";
                                buf = DecompressStream(Convert.FromBase64String(op.GetProperty("payload_b64").GetString()), algo);
                                sha256.TransformBlock(buf, 0, buf.Length, null, 0);
                                ms.Write(buf, 0, buf.Length);
                                break;
                            }
                            case "fallback.brotli": {
                                buf = DecompressStream(Convert.FromBase64String(op.GetProperty("payload_b64").GetString()), "brotli");
                                sha256.TransformBlock(buf, 0, buf.Length, null, 0);
                                ms.Write(buf, 0, buf.Length);
                                break;
                            }
                            case "xform.xor": {
                                byte[] data;
                                if (op.TryGetProperty("data_b64", out tmp))
                                    data = Convert.FromBase64String(tmp.GetString());
                                else throw new ArgumentException("xform.xor: data_b64 ausente");
                                byte[] key;
                                if      (op.TryGetProperty("key_b64", out tmp)) key = Convert.FromBase64String(tmp.GetString());
                                else if (op.TryGetProperty("key",     out tmp)) key = new byte[] { (byte)tmp.GetInt32() };
                                else throw new ArgumentException("xform.xor: key/key_b64 ausente");
                                buf = XorBuffer(data, key);
                                sha256.TransformBlock(buf, 0, buf.Length, null, 0);
                                ms.Write(buf, 0, buf.Length);
                                break;
                            }
                            case "slice.copy": {
                                byte[] raw = ms.GetBuffer();
                                long off  = op.GetProperty("offset").GetInt64();
                                long sLen = op.GetProperty("length").GetInt64();
                                long rep  = op.TryGetProperty("repeat", out tmp) ? tmp.GetInt64() : 1L;
                                if (off < 0 || sLen < 0 || rep < 1)
                                    throw new ArgumentException("slice.copy: parâmetros inválidos");
                                if (ms.Length < off + sLen)
                                    throw new ArgumentException("slice.copy: janela fora do buffer");
                                byte[] src = new byte[sLen];
                                Buffer.BlockCopy(raw, (int)off, src, 0, (int)sLen);
                                for (long r = 0; r < rep; r++) {
                                    sha256.TransformBlock(src, 0, src.Length, null, 0);
                                    ms.Write(src, 0, src.Length);
                                }
                                break;
                            }
                            case "fallback.lzma": {
                                if (string.IsNullOrEmpty(sevenZipPath))
                                    throw new InvalidOperationException(
                                        "fallback.lzma: sevenZipPath necessário");
                                buf = DecompressLzmaViaSevZip(
                                    Convert.FromBase64String(op.GetProperty("payload_b64").GetString()),
                                    sevenZipPath);
                                sha256.TransformBlock(buf, 0, buf.Length, null, 0);
                                ms.Write(buf, 0, buf.Length);
                                break;
                            }
                            case "dict.shared": {
                                // GZip-prefix (v0.6.3) — mantido para compatibilidade
                                string dSha  = op.GetProperty("dict_sha256").GetString();
                                int    dSize = op.GetProperty("dict_size").GetInt32();
                                byte[] compressed = Convert.FromBase64String(op.GetProperty("payload_b64").GetString());
                                if (string.IsNullOrEmpty(dictDir))
                                    throw new InvalidOperationException(
                                        "dict.shared: dictDir não fornecido");
                                string dictFile = Path.Combine(dictDir, dSha.ToLowerInvariant() + ".dict");
                                if (!File.Exists(dictFile))
                                    throw new FileNotFoundException("dict.shared: não encontrado", dictFile);
                                byte[] dictBytes = File.ReadAllBytes(dictFile);
                                if (dictBytes.Length != dSize)
                                    throw new InvalidOperationException("dict.shared: tamanho diverge");
                                string gotDSha = SHA256Hex(dictBytes);
                                if (!string.Equals(gotDSha, dSha, StringComparison.OrdinalIgnoreCase))
                                    throw new InvalidOperationException("dict.shared: SHA-256 do dict diverge");
                                // Decompress GZip(dict + data), strip dict
                                using (var inMs  = new MemoryStream(compressed))
                                using (var gz    = new GZipStream(inMs, CompressionMode.Decompress))
                                using (var outMs = new MemoryStream()) {
                                    gz.CopyTo(outMs);
                                    byte[] full = outMs.ToArray();
                                    if (full.Length < dSize)
                                        throw new InvalidOperationException("dict.shared: resultado menor que dict");
                                    buf = new byte[full.Length - dSize];
                                    Buffer.BlockCopy(full, dSize, buf, 0, buf.Length);
                                }
                                sha256.TransformBlock(buf, 0, buf.Length, null, 0);
                                ms.Write(buf, 0, buf.Length);
                                break;
                            }
                            case "dict.zstd_shared": {
                                // Zstd com dicionário treinado — janela configurável
                                string dSha       = op.GetProperty("dict_sha256").GetString();
                                int    dSize      = op.GetProperty("dict_size").GetInt32();
                                byte[] compressed = Convert.FromBase64String(op.GetProperty("payload_b64").GetString());

                                if (string.IsNullOrEmpty(dictDir))
                                    throw new InvalidOperationException(
                                        "dict.zstd_shared: dictDir não fornecido — use Invoke-TEIARestoreWithZstdDict -DictDir <path>");
                                if (string.IsNullOrEmpty(zstdPath))
                                    throw new InvalidOperationException(
                                        "dict.zstd_shared: zstdPath não fornecido");

                                string dictFile = Path.Combine(dictDir, dSha.ToLowerInvariant() + ".zstd-dict");
                                if (!File.Exists(dictFile))
                                    throw new FileNotFoundException(
                                        "dict.zstd_shared: dicionário " + dSha.Substring(0, 16) + "... não encontrado em " + dictDir, dictFile);

                                byte[] dictBytes = File.ReadAllBytes(dictFile);
                                if (dictBytes.Length != dSize)
                                    throw new InvalidOperationException(
                                        $"dict.zstd_shared: tamanho do dicionário diverge (esperado={dSize} obtido={dictBytes.Length})");

                                string gotDSha = SHA256Hex(dictBytes);
                                if (!string.Equals(gotDSha, dSha, StringComparison.OrdinalIgnoreCase))
                                    throw new InvalidOperationException(
                                        "dict.zstd_shared: SHA-256 do dicionário diverge");

                                buf = DecompressWithZstd(compressed, zstdPath, dictFile);
                                sha256.TransformBlock(buf, 0, buf.Length, null, 0);
                                ms.Write(buf, 0, buf.Length);
                                break;
                            }
                            default:
                                throw new InvalidOperationException("Operação desconhecida: " + opCode);
                        }
                    }

                    sha256.TransformFinalBlock(Array.Empty<byte>(), 0, 0);

                    if (outSha != null) {
                        string gotSha = BitConverter.ToString(sha256.Hash).Replace("-", "").ToLowerInvariant();
                        if (!string.Equals(gotSha, outSha, StringComparison.OrdinalIgnoreCase))
                            throw new InvalidOperationException(
                                "SHA-256 divergente: esperado=" + outSha + " obtido=" + gotSha + " — FALHA CRITICA");
                    }

                    byte[] result = ms.ToArray();
                    if (outSize >= 0 && result.LongLength != outSize)
                        throw new InvalidOperationException(
                            "Tamanho divergente: esperado=" + outSize + " obtido=" + result.Length + " — FALHA CRITICA");
                    return result;
                }
            }
        }
    }
}
'@
}

# ── Wrappers PS → C# ─────────────────────────────────────────────────────────

function SHA256Hex([byte[]]$D) { [TEIA.Native.TEIANativeV70]::SHA256Hex($D) }

# ── dict.zstd_shared — funções operacionais ──────────────────────────────────

function Build-TEIAZstdDict {
    <#
    .SYNOPSIS
        Treina dicionário Zstd a partir de N arquivos de corpus via `zstd --train`.
        Salva como {sha256}.zstd-dict no OutputDir.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$TrainingFiles,
        [Parameter(Mandatory)][string]$OutputDir,
        [int]$MaxDictBytes  = 112640,
        [string]$ZstdPath   = $script:ZSTD_DEFAULT
    )
    if (-not (Test-Path $ZstdPath)) { throw "Build-TEIAZstdDict: zstd.exe não encontrado em $ZstdPath" }

    $valid = @($TrainingFiles | Where-Object { Test-Path $_ })
    if ($valid.Count -eq 0) { throw "Build-TEIAZstdDict: nenhum arquivo de treinamento válido" }

    [IO.Directory]::CreateDirectory($OutputDir) | Out-Null

    # Usa nome temporário para treinar, depois renomeia pelo SHA-256
    $tmpDict = Join-Path $OutputDir "teia_train_tmp.zstd-dict"
    if (Test-Path $tmpDict) { Remove-Item $tmpDict -Force }

    Write-Host "[ZSTD TRAIN] $($valid.Count) arquivo(s) | maxdict=$MaxDictBytes B"
    $sw = [Diagnostics.Stopwatch]::StartNew()

    [TEIA.Native.TEIANativeV70]::TrainZstdDict([string[]]$valid, $tmpDict, $MaxDictBytes, $ZstdPath)

    $sw.Stop()
    if (-not (Test-Path $tmpDict)) { throw "Build-TEIAZstdDict: treinamento falhou — arquivo não criado" }

    $dictBytes = [IO.File]::ReadAllBytes($tmpDict)
    $dictSha   = [TEIA.Native.TEIANativeV70]::SHA256Hex($dictBytes)
    $dictPath  = Join-Path $OutputDir ($dictSha + ".zstd-dict")
    [IO.File]::WriteAllBytes($dictPath, $dictBytes)
    Remove-Item $tmpDict -Force

    Write-Host "[ZSTD TRAIN] Dicionário: $($dictBytes.Length) bytes | SHA-256: $($dictSha.Substring(0,16))... | treino=$($sw.ElapsedMilliseconds)ms"
    Write-Host "[ZSTD TRAIN] Salvo: $dictPath"

    return [pscustomobject]@{
        DictPath   = $dictPath
        DictSha256 = $dictSha
        DictBytes  = $dictBytes.Length
        TrainCount = $valid.Count
        TrainMs    = $sw.ElapsedMilliseconds
    }
}

function Invoke-TEIAEncodeZstd {
    <#
    .SYNOPSIS
        Codifica dados usando dict.zstd_shared (Zstd treinado + seed JSON TEIA).
        Retorna objeto com SeedJson e métricas completas.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][byte[]]$Data,
        [Parameter(Mandatory)][string]$DictPath,
        [string]$FileName   = "output.bin",
        [string]$ZstdPath   = $script:ZSTD_DEFAULT,
        [int]$Level         = 19
    )
    if (-not (Test-Path $DictPath))  { throw "Invoke-TEIAEncodeZstd: dict não encontrado: $DictPath" }
    if (-not (Test-Path $ZstdPath)) { throw "Invoke-TEIAEncodeZstd: zstd.exe não encontrado: $ZstdPath" }

    $dictBytes = [IO.File]::ReadAllBytes($DictPath)
    $dictSha   = [TEIA.Native.TEIANativeV70]::SHA256Hex($dictBytes)
    $dictSize  = $dictBytes.Length

    $sw = [Diagnostics.Stopwatch]::StartNew()
    $compressedBytes = [TEIA.Native.TEIANativeV70]::CompressWithZstd($Data, $ZstdPath, $DictPath, $Level)
    $sw.Stop()

    $payloadB64 = [Convert]::ToBase64String($compressedBytes)
    $outSha     = [TEIA.Native.TEIANativeV70]::SHA256Hex($Data)
    $outSize    = $Data.LongLength

    $seed = [ordered]@{
        v    = 3
        out  = [ordered]@{ name = $FileName; sha256 = $outSha; size = $outSize }
        plan = @(
            [ordered]@{
                op          = "dict.zstd_shared"
                dict_sha256 = $dictSha
                dict_size   = $dictSize
                zstd_level  = $Level
                payload_b64 = $payloadB64
            }
        )
    }

    $seedJson     = $seed | ConvertTo-Json -Depth 10 -Compress
    $seedBytes    = [Text.Encoding]::UTF8.GetByteCount($seedJson)
    $rawRatioPct  = [math]::Round($compressedBytes.Length / $outSize * 100, 4)
    $netRatioPct  = [math]::Round($seedBytes / $outSize * 100, 4)
    $b64Overhead  = $seedBytes - $compressedBytes.Length

    return [pscustomobject]@{
        SeedJson        = $seedJson
        SeedBytes       = $seedBytes
        PayloadBytes    = $compressedBytes.Length
        B64OverheadBytes = $b64Overhead
        DictSha256      = $dictSha
        DictBytes       = $dictSize
        OutSha256       = $outSha
        OutBytes        = $outSize
        RawRatioPct     = $rawRatioPct
        NetRatioPct     = $netRatioPct
        EncodeMs        = $sw.ElapsedMilliseconds
    }
}

# ── Interfaces públicas ───────────────────────────────────────────────────────

function Invoke-TEIARestoreRaw {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SeedJson,
        [string]$SevenZipPath = $script:SEVENZIP_MODULE,
        [string]$DictDir      = "",
        [string]$ZstdPath     = $script:ZSTD_DEFAULT
    )
    [TEIA.Native.TEIANativeV70]::RestoreInMemory($SeedJson, $SevenZipPath, $DictDir, $ZstdPath)
}

function Invoke-TEIARestoreWithZstdDict {
    <#
    .SYNOPSIS
        Restaura arquivo de seed com opcode dict.zstd_shared.
        DictDir deve conter {sha256}.zstd-dict gerado por Build-TEIAZstdDict.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SeedJson,
        [Parameter(Mandatory)][string]$DictDir,
        [string]$ZstdPath     = $script:ZSTD_DEFAULT,
        [string]$SevenZipPath = $script:SEVENZIP_MODULE
    )
    if (-not (Test-Path $DictDir -PathType Container)) {
        throw "Invoke-TEIARestoreWithZstdDict: DictDir não encontrado: $DictDir"
    }
    [TEIA.Native.TEIANativeV70]::RestoreInMemory($SeedJson, $SevenZipPath, $DictDir, $ZstdPath)
}

function Invoke-TEIARestore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SeedJson,
        [Parameter(Mandatory)][string]$OutDir,
        [string]$DictDir      = "",
        [string]$ZstdPath     = $script:ZSTD_DEFAULT
    )
    $bytes   = [TEIA.Native.TEIANativeV70]::RestoreInMemory($SeedJson, $script:SEVENZIP_MODULE, $DictDir, $ZstdPath)
    $outName = [TEIA.Native.TEIANativeV70]::GetOutName($SeedJson)
    [IO.Directory]::CreateDirectory($OutDir) | Out-Null
    $target  = Join-Path $OutDir $outName
    [IO.File]::WriteAllBytes($target, $bytes)
    $sha = [TEIA.Native.TEIANativeV70]::SHA256Hex($bytes)
    return [pscustomobject]@{ Size = $bytes.Length; SHA256 = $sha; Target = $target }
}

Export-ModuleMember -Function 'Invoke-TEIARestore', 'Invoke-TEIARestoreRaw',
                               'Invoke-TEIARestoreWithZstdDict',
                               'Build-TEIAZstdDict', 'Invoke-TEIAEncodeZstd'
