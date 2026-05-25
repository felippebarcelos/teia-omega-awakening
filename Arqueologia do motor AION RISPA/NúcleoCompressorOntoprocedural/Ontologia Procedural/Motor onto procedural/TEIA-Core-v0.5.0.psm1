#Requires -Version 7
# TEIA-Core-v0.5.0.psm1
# Motor de reconstrução procedural — módulo in-process, zero startup overhead por operação

$script:SEVENZIP_MODULE = "C:\Program Files\7-Zip\7z.exe"

function SHA256Hex([byte[]]$D) {
    -join ([Security.Cryptography.SHA256]::Create().ComputeHash($D) | ForEach-Object { $_.ToString('x2') })
}
function New-Repeat([int]$Val,[long]$Count) {
    if ($Val -lt 0 -or $Val -gt 255) { throw "gen.repeat: byte fora de 0..255 ($Val)" }
    if ($Count -lt 0) { throw "gen.repeat: count negativo" }
    $b = New-Object byte[] $Count; $b[0] = [byte]$Val; $len = [long]1
    while ($len -lt $Count) { $c=[Math]::Min($len,$Count-$len); [Buffer]::BlockCopy($b,0,$b,[int]$len,[int]$c); $len+=$c }
    return [byte[]]$b
}
function New-Pattern([byte[]]$Pat,[long]$Repeat) {
    if (!$Pat -or $Pat.Length -eq 0) { throw "gen.pattern: padrão vazio" }
    $total=$Pat.Length*$Repeat; $b=New-Object byte[] $total
    [Buffer]::BlockCopy($Pat,0,$b,0,$Pat.Length); $w=[long]$Pat.Length
    while ($w -lt $total) { $c=[Math]::Min($w,$total-$w); [Buffer]::BlockCopy($b,0,$b,[int]$w,[int]$c); $w+=$c }
    return [byte[]]$b
}
function DictRef([string[]]$Dict,[int[]]$Map,[string]$Enc='utf8') {
    $e=[Text.Encoding]::GetEncoding($Enc); $ms=[IO.MemoryStream]::new()
    foreach ($i in $Map) {
        if ($i -lt 0 -or $i -ge $Dict.Count) { throw "dict.ref: índice $i fora do intervalo" }
        $bytes=$e.GetBytes($Dict[$i]); $ms.Write($bytes,0,$bytes.Length)
    }
    return $ms.ToArray()
}
function Decomp([byte[]]$Comp,[string]$Algo='brotli') {
    $in=[IO.MemoryStream]::new($Comp)
    switch ($Algo.ToLower()) {
        'brotli' { $ds=[IO.Compression.BrotliStream]::new($in,[IO.Compression.CompressionMode]::Decompress,$false) }
        'gzip'   { $ds=[IO.Compression.GZipStream]::new($in,[IO.Compression.CompressionMode]::Decompress,$false) }
        default  { throw "lz.decode: algoritmo não suportado: $Algo" }
    }
    $out=[IO.MemoryStream]::new(); $ds.CopyTo($out); $ds.Dispose(); return $out.ToArray()
}
function RLE($Pairs) {
    $ms=[IO.MemoryStream]::new()
    foreach ($p in $Pairs) {
        $b=[byte]([int]$p.b); $n=[int64]$p.n
        if ($n -lt 0) { throw "rle.decode: contagem negativa" }
        if ($n -eq 0) { continue }
        $chunk=New-Repeat ([int]$b) $n; $ms.Write($chunk,0,$chunk.Length)
    }
    return $ms.ToArray()
}
function XorB([byte[]]$D,[byte[]]$K) {
    if (!$K -or $K.Length -eq 0) { throw "xform.xor: chave vazia" }
    $o=New-Object byte[] $D.Length
    for ($i=0;$i -lt $D.Length;$i++) { $o[$i]=($D[$i] -bxor $K[$i % $K.Length]) }
    return $o
}
function SliceCopy([byte[]]$SoFar,[int64]$Off,[int64]$Len,[int64]$Rep=1) {
    if ($Off -lt 0 -or $Len -lt 0 -or $Rep -lt 1) { throw "slice.copy: parâmetros inválidos" }
    if ($Off+$Len -gt $SoFar.Length) { throw "slice.copy: janela fora do buffer" }
    $src=New-Object byte[] $Len; [Array]::Copy($SoFar,$Off,$src,0,$Len)
    $ms=[IO.MemoryStream]::new()
    for ($r=0;$r -lt $Rep;$r++) { $ms.Write($src,0,$src.Length) }
    return $ms.ToArray()
}
function Gen-JsonStructured($Schema) {
    $count=[int]$Schema.count; $indent=if($Schema.indent){[string]$Schema.indent}else{"  "}
    $fields=@($Schema.fields); $sb=[Text.StringBuilder]::new()
    if ($Schema.wrapper -eq 'array') { [void]$sb.Append("[\n") }
    for ($i=0;$i -lt $count;$i++) {
        [void]$sb.Append($indent+"{")
        for ($fi=0;$fi -lt $fields.Count;$fi++) {
            $f=$fields[$fi]
            switch ($f.type) {
                'printf_pattern' { $idx=[int]$i*[int]$f.step+[int]$f.start; $v=$f.pattern -f $idx; [void]$sb.Append("`"$($f.name)`":`"$v`"") }
                'const_string'   { [void]$sb.Append("`"$($f.name)`":`"$($f.value)`"") }
                'linear_modulo'  { $v=([int]$i*[int]$f.step+[int]$f.start)%[int]$f.mod; [void]$sb.Append("`"$($f.name)`":$v") }
                default { throw "gen.json_structured: tipo desconhecido: $($f.type)" }
            }
            if ($fi -lt $fields.Count-1) { [void]$sb.Append(",") }
        }
        [void]$sb.Append("}"); $comma=if($i -lt $count-1){","}else{""}; [void]$sb.Append("$comma`n")
    }
    if ($Schema.wrapper -eq 'array') { [void]$sb.Append("]") }
    return [Text.Encoding]::UTF8.GetBytes($sb.ToString())
}
function Decomp-LZMA([byte[]]$CompData) {
    $sz=$script:SEVENZIP_MODULE
    if (-not (Test-Path $sz)) { throw "fallback.lzma: 7-Zip ausente em $sz" }
    $id=[Guid]::NewGuid().ToString("N").Substring(0,8)
    $tmpArch=Join-Path $env:TEMP "teia_lzma_$id.7z"; $tmpDir=Join-Path $env:TEMP "teia_lzma_$id"
    [IO.Directory]::CreateDirectory($tmpDir) | Out-Null
    [IO.File]::WriteAllBytes($tmpArch,$CompData)
    & $sz e $tmpArch "-o$tmpDir" -y 2>&1 | Out-Null
    $f=Get-ChildItem $tmpDir -File | Select-Object -First 1
    if (-not $f) { throw "fallback.lzma: extração vazia em $tmpDir" }
    $result=[IO.File]::ReadAllBytes($f.FullName)
    Remove-Item $tmpArch -Force -ErrorAction SilentlyContinue
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    return [byte[]]$result
}

function Invoke-TEIARestore {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$SeedJson, [Parameter(Mandatory)][string]$OutDir)
    $seed=$SeedJson | ConvertFrom-Json
    if (-not $seed.out -or -not $seed.out.name) { throw "Seed inválida: 'out.name' ausente" }
    $outStream=[IO.MemoryStream]::new()
    foreach ($op in @($seed.plan)) {
        switch ($op.op) {
            'gen.repeat' {
                $val=if($null -ne $op.byte){[int]$op.byte}elseif($null -ne $op.value){[int]$op.value}else{throw "gen.repeat: byte ausente"}
                $c=New-Repeat $val ([long]$op.count); $outStream.Write($c,0,$c.Length)
            }
            'gen.pattern' {
                $p=if($op.pattern_b64){[Convert]::FromBase64String($op.pattern_b64)}else{@($op.pattern|ForEach-Object{[byte]$_})}
                $c=New-Pattern $p ([long]$op.repeat); $outStream.Write($c,0,$c.Length)
            }
            'gen.json_structured' { $c=Gen-JsonStructured $op.schema; $outStream.Write($c,0,$c.Length) }
            'dict.ref' {
                $enc=if($op.encoding){$op.encoding}else{'utf8'}
                $c=DictRef @($op.dict) @($op.map) $enc; $outStream.Write($c,0,$c.Length)
            }
            'literal'       { $c=[Convert]::FromBase64String($op.payload_b64); $outStream.Write($c,0,$c.Length) }
            'lz.decode'     { $algo=if($op.algo){$op.algo}else{'brotli'}; $c=Decomp ([Convert]::FromBase64String($op.payload_b64)) $algo; $outStream.Write($c,0,$c.Length) }
            'rle.decode'    { $c=RLE $op.pairs; $outStream.Write($c,0,$c.Length) }
            'slice.copy'    { $sf=$outStream.ToArray(); $rep=if($op.repeat){[int64]$op.repeat}else{1}; $c=SliceCopy $sf ([int64]$op.offset) ([int64]$op.length) $rep; $outStream.Write($c,0,$c.Length) }
            'xform.xor'     {
                $d=if($op.data_b64){[Convert]::FromBase64String($op.data_b64)}else{throw "xform.xor: data_b64 ausente"}
                $k=if($op.key_b64){[Convert]::FromBase64String($op.key_b64)}elseif($null -ne $op.key){,([byte][int]$op.key)}else{throw "xform.xor: key ausente"}
                $c=XorB $d $k; $outStream.Write($c,0,$c.Length)
            }
            'fallback.lzma'  { $c=Decomp-LZMA ([Convert]::FromBase64String($op.payload_b64)); $outStream.Write($c,0,$c.Length) }
            'fallback.brotli'{ $c=Decomp ([Convert]::FromBase64String($op.payload_b64)) 'brotli'; $outStream.Write($c,0,$c.Length) }
            default { throw "Operação desconhecida: $($op.op)" }
        }
    }
    $bytes=$outStream.ToArray(); $size=$bytes.Length; $sha=SHA256Hex $bytes
    if ($seed.out.size -and $size -ne [int64]$seed.out.size) {
        throw "Tamanho divergente: esperado=$($seed.out.size) obtido=$size — FALHA CRÍTICA"
    }
    if ($seed.out.sha256 -and $sha.ToLower() -ne $seed.out.sha256.ToLower()) {
        throw "SHA-256 divergente: esperado=$($seed.out.sha256) obtido=$sha — FALHA CRÍTICA"
    }
    [IO.Directory]::CreateDirectory((Split-Path -Parent (Join-Path $OutDir $seed.out.name))) | Out-Null
    $target=Join-Path $OutDir $seed.out.name
    [IO.File]::WriteAllBytes($target,$bytes)
    return [pscustomobject]@{Size=$size; SHA256=$sha; Target=$target}
}

Export-ModuleMember -Function 'Invoke-TEIARestore'
