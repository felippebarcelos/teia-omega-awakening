#Requires -Version 7
# TEIA-Core-v0.6.0.psm1
# Motor de reconstrução procedural — primitivas hot-loop em C# inline via [Add-Type]
# Interface idêntica ao v0.5.0: seeds DSL v0.4/v0.5 são intercambiáveis bit-a-bit.
# Determinismo preservado: resultados SHA-256 idênticos ao v0.5.0 em todos os opcodes.

$script:SEVENZIP_MODULE = "C:\Program Files\7-Zip\7z.exe"

# ── C# inline: hot-loops CLR nativos ─────────────────────────────────────────
# Guard: Add-Type falha se o tipo já existe no AppDomain (re-import com -Force).
if (-not ('TEIA.Native.TEIANative' -as [type])) {
    Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Text;
using System.Security.Cryptography;

namespace TEIA.Native {
    public static class TEIANative {

        // FillRepeat: preenche count bytes com val usando doubling (idêntico ao PS New-Repeat).
        public static byte[] FillRepeat(byte val, long count) {
            if (count < 0) throw new ArgumentOutOfRangeException("count", "gen.repeat: count negativo");
            byte[] b = new byte[count];
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

        // FillPattern: repete pat repeat vezes usando doubling (idêntico ao PS New-Pattern).
        public static byte[] FillPattern(byte[] pat, long repeat) {
            if (pat == null || pat.Length == 0)
                throw new ArgumentException("gen.pattern: padrão vazio", "pat");
            if (repeat < 0) throw new ArgumentOutOfRangeException("repeat", "gen.pattern: repeat negativo");
            long total = (long)pat.Length * repeat;
            byte[] b = new byte[total];
            Buffer.BlockCopy(pat, 0, b, 0, pat.Length);
            long written = pat.Length;
            while (written < total) {
                long c = Math.Min(written, total - written);
                Buffer.BlockCopy(b, 0, b, (int)written, (int)c);
                written += c;
            }
            return b;
        }

        // XorBuffer: XOR byte-a-byte com chave cíclica — elimina o loop PS O(n).
        public static byte[] XorBuffer(byte[] data, byte[] key) {
            if (key == null || key.Length == 0)
                throw new ArgumentException("xform.xor: chave vazia", "key");
            byte[] result = new byte[data.Length];
            int klen = key.Length;
            for (int i = 0; i < data.Length; i++)
                result[i] = (byte)(data[i] ^ key[i % klen]);
            return result;
        }

        // DecodeRLE: expande runs usando doubling por run (zero overhead PS de foreach).
        // byteVals[i] e counts[i] correspondem ao i-ésimo par {b, n}.
        public static byte[] DecodeRLE(byte[] byteVals, long[] counts) {
            if (byteVals.Length != counts.Length)
                throw new ArgumentException("rle.decode: arrays de comprimento diferente");
            long total = 0;
            for (int i = 0; i < counts.Length; i++) {
                if (counts[i] < 0) throw new ArgumentOutOfRangeException("counts", "rle.decode: contagem negativa");
                total += counts[i];
            }
            byte[] result = new byte[total];
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

        // SHA256Hex: hash + hex em C# puro — elimina ForEach-Object pipeline.
        public static string SHA256Hex(byte[] data) {
            using (var sha = SHA256.Create()) {
                byte[] hash = sha.ComputeHash(data);
                return BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
            }
        }

        // BuildJsonArray: reconstrói JSON declarativo idêntico ao Gen-JsonStructured PS.
        // Tipos de campo suportados: "printf_pattern", "const_string", "linear_modulo".
        // Usa .NET composite format strings ({0:D6}) — semanticamente idêntico ao PS -f operator.
        public static byte[] BuildJsonArray(
            int count, string indent, bool wrapArray,
            string[] fieldNames, string[] fieldTypes,
            string[] fieldPatterns, string[] fieldValues,
            int[] fieldSteps, int[] fieldStarts, int[] fieldMods)
        {
            var sb = new StringBuilder();
            if (wrapArray) sb.Append("[\\n");  // PS "[\n" = literal backslash+n, não LF
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
                            throw new ArgumentException(
                                "gen.json_structured: tipo de campo desconhecido: " + fieldTypes[fi]);
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
    }
}
'@
}

# ── Wrappers PS → C# ──────────────────────────────────────────────────────────
function SHA256Hex([byte[]]$D) {
    [TEIA.Native.TEIANative]::SHA256Hex($D)
}

function New-Repeat([int]$Val, [long]$Count) {
    if ($Val -lt 0 -or $Val -gt 255) { throw "gen.repeat: byte fora de 0..255 ($Val)" }
    [TEIA.Native.TEIANative]::FillRepeat([byte]$Val, $Count)
}

function New-Pattern([byte[]]$Pat, [long]$Repeat) {
    if (!$Pat -or $Pat.Length -eq 0) { throw "gen.pattern: padrão vazio" }
    [TEIA.Native.TEIANative]::FillPattern($Pat, $Repeat)
}

function XorB([byte[]]$D, [byte[]]$K) {
    if (!$K -or $K.Length -eq 0) { throw "xform.xor: chave vazia" }
    [TEIA.Native.TEIANative]::XorBuffer($D, $K)
}

function RLE($Pairs) {
    $arr = @($Pairs)
    $bVals  = [byte[]]($arr | ForEach-Object { [byte]([int]$_.b) })
    $counts = [long[]]($arr | ForEach-Object {
        $n = [int64]$_.n
        if ($n -lt 0) { throw "rle.decode: contagem negativa" }
        $n
    })
    [TEIA.Native.TEIANative]::DecodeRLE($bVals, $counts)
}

function Gen-JsonStructured($Schema) {
    $count  = [int]$Schema.count
    $indent = if ($Schema.indent) { [string]$Schema.indent } else { "  " }
    $wrap   = ($Schema.wrapper -eq 'array')
    $fields = @($Schema.fields)

    $names    = [string[]]($fields | ForEach-Object { [string]$_.name })
    $types    = [string[]]($fields | ForEach-Object { [string]$_.type })
    $patterns = [string[]]($fields | ForEach-Object {
        if ($null -ne $_.pattern) { [string]$_.pattern } else { "" }
    })
    $values = [string[]]($fields | ForEach-Object {
        if ($null -ne $_.value) { [string]$_.value } else { "" }
    })
    $steps  = [int[]]($fields | ForEach-Object {
        if ($null -ne $_.step)  { [int]$_.step  } else { 1 }
    })
    $starts = [int[]]($fields | ForEach-Object {
        if ($null -ne $_.start) { [int]$_.start } else { 0 }
    })
    $mods = [int[]]($fields | ForEach-Object {
        if ($null -ne $_.mod)   { [int]$_.mod   } else { [int]::MaxValue }
    })

    [TEIA.Native.TEIANative]::BuildJsonArray(
        $count, $indent, $wrap,
        $names, $types, $patterns, $values,
        $steps, $starts, $mods
    )
}

function DictRef([string[]]$Dict, [int[]]$Map, [string]$Enc = 'utf8') {
    $e  = [Text.Encoding]::GetEncoding($Enc)
    $ms = [IO.MemoryStream]::new()
    foreach ($i in $Map) {
        if ($i -lt 0 -or $i -ge $Dict.Count) { throw "dict.ref: índice $i fora do intervalo" }
        $bytes = $e.GetBytes($Dict[$i]); $ms.Write($bytes, 0, $bytes.Length)
    }
    $ms.ToArray()
}

function Decomp([byte[]]$Comp, [string]$Algo = 'brotli') {
    $in = [IO.MemoryStream]::new($Comp)
    switch ($Algo.ToLower()) {
        'brotli' { $ds = [IO.Compression.BrotliStream]::new($in, [IO.Compression.CompressionMode]::Decompress, $false) }
        'gzip'   { $ds = [IO.Compression.GZipStream]::new($in,  [IO.Compression.CompressionMode]::Decompress, $false) }
        default  { throw "lz.decode: algoritmo não suportado: $Algo" }
    }
    $out = [IO.MemoryStream]::new(); $ds.CopyTo($out); $ds.Dispose(); $out.ToArray()
}

function SliceCopy([byte[]]$SoFar, [int64]$Off, [int64]$Len, [int64]$Rep = 1) {
    if ($Off -lt 0 -or $Len -lt 0 -or $Rep -lt 1) { throw "slice.copy: parâmetros inválidos" }
    if ($Off + $Len -gt $SoFar.Length) { throw "slice.copy: janela fora do buffer" }
    $src = New-Object byte[] $Len; [Array]::Copy($SoFar, $Off, $src, 0, $Len)
    $ms  = [IO.MemoryStream]::new()
    for ($r = 0; $r -lt $Rep; $r++) { $ms.Write($src, 0, $src.Length) }
    $ms.ToArray()
}

function Decomp-LZMA([byte[]]$CompData) {
    $sz = $script:SEVENZIP_MODULE
    if (-not (Test-Path $sz)) { throw "fallback.lzma: 7-Zip ausente em $sz" }
    $id      = [Guid]::NewGuid().ToString("N").Substring(0, 8)
    $tmpArch = Join-Path $env:TEMP "teia_lzma_$id.7z"
    $tmpDir  = Join-Path $env:TEMP "teia_lzma_$id"
    [IO.Directory]::CreateDirectory($tmpDir) | Out-Null
    [IO.File]::WriteAllBytes($tmpArch, $CompData)
    & $sz e $tmpArch "-o$tmpDir" -y 2>&1 | Out-Null
    $f = Get-ChildItem $tmpDir -File | Select-Object -First 1
    if (-not $f) { throw "fallback.lzma: extração vazia em $tmpDir" }
    $result = [IO.File]::ReadAllBytes($f.FullName)
    Remove-Item $tmpArch -Force -ErrorAction SilentlyContinue
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    [byte[]]$result
}

# ── Interface pública — idêntica ao v0.5.0 ───────────────────────────────────
function Invoke-TEIARestore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SeedJson,
        [Parameter(Mandatory)][string]$OutDir
    )
    $seed = $SeedJson | ConvertFrom-Json
    if (-not $seed.out -or -not $seed.out.name) { throw "Seed inválida: 'out.name' ausente" }

    $outStream = [IO.MemoryStream]::new()
    foreach ($op in @($seed.plan)) {
        switch ($op.op) {
            'gen.repeat' {
                $val = if ($null -ne $op.byte) { [int]$op.byte } `
                       elseif ($null -ne $op.value) { [int]$op.value } `
                       else { throw "gen.repeat: byte/value ausente" }
                $c = New-Repeat $val ([long]$op.count)
                $outStream.Write($c, 0, $c.Length)
            }
            'gen.pattern' {
                $p = if ($op.pattern_b64) { [Convert]::FromBase64String($op.pattern_b64) } `
                     else { @($op.pattern | ForEach-Object { [byte]$_ }) }
                $c = New-Pattern $p ([long]$op.repeat)
                $outStream.Write($c, 0, $c.Length)
            }
            'gen.json_structured' {
                $c = Gen-JsonStructured $op.schema
                $outStream.Write($c, 0, $c.Length)
            }
            'dict.ref' {
                $enc = if ($op.encoding) { $op.encoding } else { 'utf8' }
                $c = DictRef @($op.dict) @($op.map) $enc
                $outStream.Write($c, 0, $c.Length)
            }
            'literal' {
                $c = [Convert]::FromBase64String($op.payload_b64)
                $outStream.Write($c, 0, $c.Length)
            }
            'lz.decode' {
                $algo = if ($op.algo) { $op.algo } else { 'brotli' }
                $c = Decomp ([Convert]::FromBase64String($op.payload_b64)) $algo
                $outStream.Write($c, 0, $c.Length)
            }
            'rle.decode' {
                $c = RLE $op.pairs
                $outStream.Write($c, 0, $c.Length)
            }
            'slice.copy' {
                $sf  = $outStream.ToArray()
                $rep = if ($op.repeat) { [int64]$op.repeat } else { 1 }
                $c   = SliceCopy $sf ([int64]$op.offset) ([int64]$op.length) $rep
                $outStream.Write($c, 0, $c.Length)
            }
            'xform.xor' {
                $d = if ($op.data_b64) { [Convert]::FromBase64String($op.data_b64) } `
                     else { throw "xform.xor: data_b64 ausente" }
                $k = if ($op.key_b64)  { [Convert]::FromBase64String($op.key_b64) } `
                     elseif ($null -ne $op.key) { , ([byte][int]$op.key) } `
                     else { throw "xform.xor: key/key_b64 ausente" }
                $c = XorB $d $k
                $outStream.Write($c, 0, $c.Length)
            }
            'fallback.lzma'   {
                $c = Decomp-LZMA ([Convert]::FromBase64String($op.payload_b64))
                $outStream.Write($c, 0, $c.Length)
            }
            'fallback.brotli' {
                $c = Decomp ([Convert]::FromBase64String($op.payload_b64)) 'brotli'
                $outStream.Write($c, 0, $c.Length)
            }
            default { throw "Operação desconhecida: $($op.op)" }
        }
    }

    $bytes = $outStream.ToArray()
    $size  = $bytes.Length
    $sha   = SHA256Hex $bytes

    if ($seed.out.size -and $size -ne [int64]$seed.out.size) {
        throw "Tamanho divergente: esperado=$($seed.out.size) obtido=$size — FALHA CRÍTICA"
    }
    if ($seed.out.sha256 -and $sha.ToLower() -ne $seed.out.sha256.ToLower()) {
        throw "SHA-256 divergente: esperado=$($seed.out.sha256) obtido=$sha — FALHA CRÍTICA"
    }

    [IO.Directory]::CreateDirectory((Split-Path -Parent (Join-Path $OutDir $seed.out.name))) | Out-Null
    $target = Join-Path $OutDir $seed.out.name
    [IO.File]::WriteAllBytes($target, $bytes)
    return [pscustomobject]@{ Size = $size; SHA256 = $sha; Target = $target }
}

Export-ModuleMember -Function 'Invoke-TEIARestore'
