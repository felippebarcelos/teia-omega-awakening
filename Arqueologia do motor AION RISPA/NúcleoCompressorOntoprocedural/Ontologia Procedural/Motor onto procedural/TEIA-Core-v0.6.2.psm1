#Requires -Version 7
# TEIA-Core-v0.6.2.psm1
# Motor de reconstrução procedural — hot-path 100% em C# via [Add-Type]
# Novidades vs v0.6.1:
#   • RestoreInMemory com SHA-256 streaming: hash calculado chunk-a-chunk durante geração
#   • Elimina passe final sobre buffer completo (~5-50ms dependendo do tamanho)
#   • slice.copy usa ms.GetBuffer() em vez de ms.ToArray() — zero cópia do buffer acumulado
#   • SHA-256 de validação aproveitado do estado incremental: BitConverter direto, zero alocação extra
# Classe: TEIA.Native.TEIANativeV62 (separada de V61 para coexistência no AppDomain)

$script:SEVENZIP_MODULE = "C:\Program Files\7-Zip\7z.exe"

if (-not ('TEIA.Native.TEIANativeV62' -as [type])) {
    Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace TEIA.Native {
    public static class TEIANativeV62 {

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

        // BuildJsonArray: idêntico ao v0.6.1 — "[\\n" = PS literal backslash+n
        public static byte[] BuildJsonArray(
            int count, string indent, bool wrapArray,
            string[] fieldNames, string[] fieldTypes,
            string[] fieldPatterns, string[] fieldValues,
            int[] fieldSteps, int[] fieldStarts, int[] fieldMods)
        {
            var sb = new StringBuilder();
            if (wrapArray) sb.Append("[\\n");
            for (int i = 0; i < count; i++) {
                sb.Append(indent);
                sb.Append('{');
                for (int fi = 0; fi < fieldNames.Length; fi++) {
                    sb.Append('"');
                    sb.Append(fieldNames[fi]);
                    sb.Append("\":");
                    switch (fieldTypes[fi]) {
                        case "printf_pattern": {
                            int idx = i * fieldSteps[fi] + fieldStarts[fi];
                            sb.Append('"');
                            sb.AppendFormat(fieldPatterns[fi], idx);
                            sb.Append('"');
                            break;
                        }
                        case "const_string": {
                            sb.Append('"');
                            sb.Append(fieldValues[fi]);
                            sb.Append('"');
                            break;
                        }
                        case "linear_modulo": {
                            int v = (i * fieldSteps[fi] + fieldStarts[fi]) % fieldMods[fi];
                            sb.Append(v);
                            break;
                        }
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
            var steps    = new int[nf];    var starts   = new int[nf];
            var mods     = new int[nf];
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
                var psi = new ProcessStartInfo {
                    FileName               = sevenZipPath,
                    Arguments              = "e \"" + tmpArch + "\" \"-o" + tmpDir + "\" -y",
                    UseShellExecute        = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError  = true,
                    CreateNoWindow         = true
                };
                using (var p = Process.Start(psi)) {
                    if (p == null) throw new InvalidOperationException("fallback.lzma: 7-Zip não iniciou");
                    p.StandardOutput.ReadToEnd();
                    p.WaitForExit();
                }
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

        // ── RestoreInMemory — streaming SHA-256 ──────────────────────────────
        // Hash calculado chunk-a-chunk: elimina passe final sobre buffer completo.
        // slice.copy: usa ms.GetBuffer() — zero cópia do buffer acumulado.
        public static byte[] RestoreInMemory(string seedJson, string sevenZipPath) {
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
                                // Usa GetBuffer() — zero cópia do buffer acumulado vs ToArray()
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
                                        "fallback.lzma: sevenZipPath necessário — use Invoke-TEIARestore (modo disco)");
                                buf = DecompressLzmaViaSevZip(
                                    Convert.FromBase64String(op.GetProperty("payload_b64").GetString()),
                                    sevenZipPath);
                                sha256.TransformBlock(buf, 0, buf.Length, null, 0);
                                ms.Write(buf, 0, buf.Length);
                                break;
                            }
                            case "dict.shared":
                                throw new NotImplementedException(
                                    "dict.shared: opcode reservado — infraestrutura de dicionário compartilhado não implementada");
                            default:
                                throw new InvalidOperationException("Operação desconhecida: " + opCode);
                        }
                    }

                    // Finaliza hash streaming — zero leitura adicional do buffer
                    sha256.TransformFinalBlock(Array.Empty<byte>(), 0, 0);

                    if (outSha != null) {
                        string gotSha = BitConverter.ToString(sha256.Hash).Replace("-", "").ToLowerInvariant();
                        if (!string.Equals(gotSha, outSha, StringComparison.OrdinalIgnoreCase))
                            throw new InvalidOperationException(
                                "SHA-256 divergente: esperado=" + outSha + " obtido=" + gotSha + " — FALHA CRÍTICA");
                    }

                    byte[] result = ms.ToArray();
                    if (outSize >= 0 && result.LongLength != outSize)
                        throw new InvalidOperationException(
                            "Tamanho divergente: esperado=" + outSize + " obtido=" + result.Length + " — FALHA CRÍTICA");
                    return result;
                }
            }
        }
    }
}
'@
}

# ── Wrappers PS → C# ─────────────────────────────────────────────────────────

function SHA256Hex([byte[]]$D) { [TEIA.Native.TEIANativeV62]::SHA256Hex($D) }

function New-Repeat([int]$Val, [long]$Count) {
    if ($Val -lt 0 -or $Val -gt 255) { throw "gen.repeat: byte fora de 0..255 ($Val)" }
    [TEIA.Native.TEIANativeV62]::FillRepeat([byte]$Val, $Count)
}

function New-Pattern([byte[]]$Pat, [long]$Repeat) {
    if (!$Pat -or $Pat.Length -eq 0) { throw "gen.pattern: padrão vazio" }
    [TEIA.Native.TEIANativeV62]::FillPattern($Pat, $Repeat)
}

function XorB([byte[]]$D, [byte[]]$K) {
    if (!$K -or $K.Length -eq 0) { throw "xform.xor: chave vazia" }
    [TEIA.Native.TEIANativeV62]::XorBuffer($D, $K)
}

function RLE($Pairs) {
    $arr    = @($Pairs)
    $bVals  = [byte[]]($arr | ForEach-Object { [byte]([int]$_.b) })
    $counts = [long[]]($arr | ForEach-Object {
        $n = [int64]$_.n; if ($n -lt 0) { throw "rle.decode: contagem negativa" }; $n
    })
    [TEIA.Native.TEIANativeV62]::DecodeRLE($bVals, $counts)
}

# ── Interfaces públicas ───────────────────────────────────────────────────────

function Invoke-TEIARestoreRaw {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SeedJson,
        [string]$SevenZipPath = ""
    )
    [TEIA.Native.TEIANativeV62]::RestoreInMemory($SeedJson, $SevenZipPath)
}

function Invoke-TEIARestore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SeedJson,
        [Parameter(Mandatory)][string]$OutDir
    )
    $bytes   = [TEIA.Native.TEIANativeV62]::RestoreInMemory($SeedJson, $script:SEVENZIP_MODULE)
    $outName = [TEIA.Native.TEIANativeV62]::GetOutName($SeedJson)
    [IO.Directory]::CreateDirectory($OutDir) | Out-Null
    $target  = Join-Path $OutDir $outName
    [IO.File]::WriteAllBytes($target, $bytes)
    $sha = [TEIA.Native.TEIANativeV62]::SHA256Hex($bytes)
    return [pscustomobject]@{ Size = $bytes.Length; SHA256 = $sha; Target = $target }
}

Export-ModuleMember -Function 'Invoke-TEIARestore', 'Invoke-TEIARestoreRaw'
