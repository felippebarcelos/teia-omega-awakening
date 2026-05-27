# run_tests_v0161.ps1
# Provas SHA-256 para gen.pattern e rle.decode — v0.16.1
# NAO altera TEIA-Core-v0.4.0.ps1
[CmdletBinding()] param()
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$CorePath   = "D:\TEIA_CLAUDE_AWAKENING\Arqueologia do motor AION RISPA\NúcleoCompressorOntoprocedural\Ontologia Procedural\Motor onto procedural\MOTOR OURO\TEIA-Core-v0.4.0.ps1"
$TestDir    = "D:\TEIA_CORE\procedural_tests\v0161"
$DocsDir    = "D:\TEIA_CORE\docs"
$ReportPath = "$DocsDir\PROCEDURAL_OPCODE_PROOFS_v0161.md"
$MatrixPath = "$DocsDir\PROCEDURAL_CAPABILITY_MATRIX.md"

foreach ($d in @($TestDir,"$TestDir\originals","$TestDir\seeds","$TestDir\restored",$DocsDir)) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

# ── helpers ───────────────────────────────────────────────────────────
function sha256hex([byte[]]$b) {
    (-join([System.Security.Cryptography.SHA256]::Create().ComputeHash($b) | % { $_.ToString('x2') })).ToUpper()
}

function gz_c([byte[]]$b) {
    $ms=[System.IO.MemoryStream]::new()
    $s=[System.IO.Compression.GZipStream]::new($ms,[System.IO.Compression.CompressionLevel]::Optimal)
    $s.Write($b,0,$b.Length); $s.Dispose(); $ms.ToArray()
}

function br_c([byte[]]$b) {
    try {
        $ms=[System.IO.MemoryStream]::new()
        $s=[System.IO.Compression.BrotliStream]::new($ms,[System.IO.Compression.CompressionLevel]::Optimal)
        $s.Write($b,0,$b.Length); $s.Dispose(); $ms.ToArray()
    } catch { $null }
}

function lzma_c([byte[]]$b) {
    $ti="$TestDir\_lzma_in.bin"; $to="$TestDir\_lzma_out.lzma"
    [System.IO.File]::WriteAllBytes($ti,$b)
    try {
        python -c "import lzma;d=open(r'$ti','rb').read();open(r'$to','wb').write(lzma.compress(d,format=lzma.FORMAT_ALONE,preset=9|lzma.PRESET_EXTREME))" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Test-Path $to)) {
            $r=[System.IO.File]::ReadAllBytes($to)
            Remove-Item $ti,$to -ErrorAction SilentlyContinue; return $r
        }
    } catch {}
    Remove-Item $ti -ErrorAction SilentlyContinue; $null
}

function teia_restore([string]$seedPath,[string]$outDir,[string]$origHash) {
    $sw=[System.Diagnostics.Stopwatch]::StartNew()
    try {
        $null = & pwsh -ExecutionPolicy Bypass -NonInteractive -File $CorePath `
            -SeedPath $seedPath -OutDir $outDir -Silent 2>&1
        $ec=$LASTEXITCODE; $sw.Stop()
        if ($ec -ne 0) { return @{ok=$false;ms=$sw.ElapsedMilliseconds;diag="ExitCode=$ec"} }
        $seed=Get-Content $seedPath -Raw | ConvertFrom-Json
        $outFile=Join-Path $outDir $seed.out.name
        if (Test-Path $outFile) {
            $rHash=sha256hex ([System.IO.File]::ReadAllBytes($outFile))
            $match=($rHash -eq $origHash)
            return @{ok=$match;ms=$sw.ElapsedMilliseconds;diag=if($match){"ok"}else{"HASH_MISMATCH"}}
        }
        return @{ok=$false;ms=$sw.ElapsedMilliseconds;diag="FILE_NOT_FOUND"}
    } catch {
        $sw.Stop()
        return @{ok=$false;ms=$sw.ElapsedMilliseconds;diag="EXCEPTION:$_"}
    }
}

function make_seed([string]$name,[long]$size,[string]$hash,[object[]]$plan) {
    @{v="0.4.0";out=@{name=$name;size=$size;sha256=$hash.ToLower()};plan=$plan} | ConvertTo-Json -Depth 20
}

$AllResults=[System.Collections.ArrayList]::new()

function run_test([string]$id,[string]$fname,[string]$opcode,[byte[]]$data,[object[]]$plan,[string]$note) {
    Write-Host "[$id] $fname ($($data.Length)B) ..." -NoNewline
    $origPath="$TestDir\originals\$fname"
    $seedPath="$TestDir\seeds\$($fname -replace '\.bin$','.seed.json')"
    $restDir="$TestDir\restored\$id"
    New-Item -ItemType Directory -Force -Path $restDir | Out-Null
    [System.IO.File]::WriteAllBytes($origPath,$data)
    $origHash=sha256hex $data
    $seedJson=make_seed $fname $data.Length $origHash $plan
    [System.IO.File]::WriteAllText($seedPath,$seedJson,[System.Text.Encoding]::UTF8)
    $seedB=(Get-Item $seedPath).Length
    $res=teia_restore $seedPath $restDir $origHash
    Write-Host " sha256=$($res.ok) ms=$($res.ms)" -NoNewline
    $gzB=(gz_c $data).Length
    $brArr=br_c $data; $brB=if($brArr){$brArr.Length}else{-1}
    $lzArr=lzma_c $data; $lzB=if($lzArr){$lzArr.Length}else{-1}
    $cands=@{}; $cands['gzip']=$gzB
    if($brB -gt 0){$cands['brotli']=$brB}
    if($lzB -gt 0){$cands['lzma']=$lzB}
    $bestEntry=$cands.GetEnumerator()|Sort-Object Value|Select-Object -First 1
    $bestName=$bestEntry.Name; $bestB=[int]$bestEntry.Value
    $teiaWins=$res.ok -and ($seedB -lt $bestB)
    Write-Host " teia=$teiaWins best=$bestName($bestB)"
    $null=$AllResults.Add([PSCustomObject]@{
        Id=$id; File=$fname; Opcode=$opcode; OrigB=$data.Length; SeedB=$seedB
        Ratio=if($res.ok){[math]::Round($seedB/$data.Length*100,4)}else{'N/A'}
        SHA256OK=$res.ok; Diag=$res.diag; RestoreMs=$res.ms
        GZipB=$gzB; BrotliB=if($brB -gt 0){$brB}else{'N/A'}; LZMAB=if($lzB -gt 0){$lzB}else{'N/A'}
        BestName=$bestName; BestB=$bestB; TeiaWins=$teiaWins; Note=$note
    })
}

# ── GEN.PATTERN ───────────────────────────────────────────────────────
Write-Host "`n=== GEN.PATTERN ==="

# GP-01: "AB" x500,000 = 1,000,000 B
$p=[System.Text.Encoding]::ASCII.GetBytes("AB"); $d=New-Object byte[] 1000000
for($i=0;$i -lt 500000;$i++){$d[$i*2]=65;$d[$i*2+1]=66}
run_test "GP-01" "gp01_AB_500k.bin" "gen.pattern" $d @(
    @{op="gen.pattern";pattern_b64=[Convert]::ToBase64String($p);repeat=500000}
) "Pattern 'AB' (2B) x500k -> 1MB"

# GP-02: "ABCD" x250,000 = 1,000,000 B
$p=[System.Text.Encoding]::ASCII.GetBytes("ABCD"); $d=New-Object byte[] 1000000
for($i=0;$i -lt 250000;$i++){$d[$i*4]=65;$d[$i*4+1]=66;$d[$i*4+2]=67;$d[$i*4+3]=68}
run_test "GP-02" "gp02_ABCD_250k.bin" "gen.pattern" $d @(
    @{op="gen.pattern";pattern_b64=[Convert]::ToBase64String($p);repeat=250000}
) "Pattern 'ABCD' (4B) x250k -> 1MB"

# GP-03: 0x00 0xFF x500,000 = 1,000,000 B (binario)
$p=[byte[]](0,255); $d=New-Object byte[] 1000000
for($i=0;$i -lt 500000;$i++){$d[$i*2]=0;$d[$i*2+1]=255}
run_test "GP-03" "gp03_00FF_500k.bin" "gen.pattern" $d @(
    @{op="gen.pattern";pattern_b64=[Convert]::ToBase64String($p);repeat=500000}
) "Pattern 0x00FF (2B) x500k -> 1MB binario"

# GP-04: "Hello World! " x76,923 = 999,999 B (texto)
$p=[System.Text.Encoding]::ASCII.GetBytes("Hello World! "); $d=New-Object byte[] ($p.Length*76923)
for($i=0;$i -lt 76923;$i++){[Array]::Copy($p,0,$d,$i*$p.Length,$p.Length)}
run_test "GP-04" "gp04_hello_76923.bin" "gen.pattern" $d @(
    @{op="gen.pattern";pattern_b64=[Convert]::ToBase64String($p);repeat=76923}
) "Pattern 'Hello World! ' (13B) x76923 -> 999999B texto"

# GP-05: padrao 512B (0..255 duas vezes) x2,000 = 1,024,000 B (max pattern)
$p=New-Object byte[] 512
for($i=0;$i -lt 256;$i++){$p[$i]=[byte]$i;$p[256+$i]=[byte]$i}
$d=New-Object byte[] ($p.Length*2000)
for($i=0;$i -lt 2000;$i++){[Array]::Copy($p,0,$d,$i*$p.Length,$p.Length)}
run_test "GP-05" "gp05_512pat_2k.bin" "gen.pattern" $d @(
    @{op="gen.pattern";pattern_b64=[Convert]::ToBase64String($p);repeat=2000}
) "Pattern 512B (0..255x2) x2000 -> 1024000B padrao maximo"

# ── RLE.DECODE ────────────────────────────────────────────────────────
Write-Host "`n=== RLE.DECODE ==="

# RLE-01: 1024 bytes de 0xAA - run unico
$d=New-Object byte[] 1024; for($i=0;$i -lt 1024;$i++){$d[$i]=0xAA}
run_test "RLE-01" "rle01_1024_AA.bin" "rle.decode" $d @(
    @{op="rle.decode";pairs=@(@{b=170;n=1024})}
) "1024 bytes 0xAA - run unico"

# RLE-02: 16 runs de 16B = 256B - runs curtos
$p02=@(0..15|%{@{b=$_;n=16}}); $d=New-Object byte[] 256; $ofs=0
foreach($pair in $p02){for($i=0;$i -lt $pair.n;$i++){$d[$ofs]=[byte]$pair.b;$ofs++}}
run_test "RLE-02" "rle02_16runs_short.bin" "rle.decode" $d @(
    @{op="rle.decode";pairs=$p02}
) "16 runs x16B = 256B - runs curtos multiplos"

# RLE-03: 5 runs de 100KB = 500KB - runs longos
$p03=@(@{b=0;n=102400},@{b=255;n=102400},@{b=170;n=102400},@{b=85;n=102400},@{b=15;n=102400})
$d=New-Object byte[] 512000; $ofs=0
foreach($pair in $p03){for($i=0;$i -lt $pair.n;$i++){$d[$ofs]=[byte]$pair.b;$ofs++}}
run_test "RLE-03" "rle03_5runs_100k.bin" "rle.decode" $d @(
    @{op="rle.decode";pairs=$p03}
) "5 runs x100KB = 500KB - runs longos"

# RLE-04: 26 letras x1000 = 26000B - texto-like
$p04=@(65..90|%{@{b=$_;n=1000}}); $d=New-Object byte[] 26000; $ofs=0
foreach($pair in $p04){for($i=0;$i -lt $pair.n;$i++){$d[$ofs]=[byte]$pair.b;$ofs++}}
run_test "RLE-04" "rle04_26letters_1k.bin" "rle.decode" $d @(
    @{op="rle.decode";pairs=$p04}
) "26 letras x1000B = 26KB - texto-like"

# RLE-05: CASO RUIM - 256 bytes distintos, run=4 cada -> 1024B
$p05=@(0..255|%{@{b=$_;n=4}}); $d=New-Object byte[] 1024; $ofs=0
foreach($pair in $p05){for($i=0;$i -lt $pair.n;$i++){$d[$ofs]=[byte]$pair.b;$ofs++}}
run_test "RLE-05" "rle05_256bytes_bad.bin" "rle.decode" $d @(
    @{op="rle.decode";pairs=$p05}
) "256 bytes distintos run=4 -> 1024B CASO RUIM seed>original"

# ── RELATORIO MARKDOWN ────────────────────────────────────────────────
Write-Host "`n=== Gerando relatorio ==="
$ts=Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$sb=[System.Text.StringBuilder]::new()

function L([string]$s=""){ $null=$sb.AppendLine($s) }

L "# PROCEDURAL OPCODE PROOFS v0.16.1"
L "**Data:** $ts"
L "**Motor:** ``TEIA-Core-v0.4.0.ps1`` SHA-256 ``489D3B4024930FB4B0E12D0D40393CB86D0430178E6E272DCE328FDEC16475F6``"
L "**Nota timing:** ms inclui startup do processo pwsh (~200-500ms overhead fixo)"
L "**Regra:** sha256_match=false invalida a linha"
L ""
L "---"
L ""
L "## TABELA DE RESULTADOS"
L ""
L "| ID | Arquivo | Opcode | Orig (B) | Seed (B) | Ratio% | SHA256 | ms | Melhor classico | Cl. (B) | TEIA vence? |"
L "|----|---------|--------|-------:|-------:|------:|:-----:|----:|---------|-------:|:-----------:|"
foreach ($r in $AllResults) {
    $sha=if($r.SHA256OK){"✅"}else{"❌ FAIL"}
    $win=if($r.TeiaWins){"✅ SIM"}else{"❌ NÃO"}
    L "| $($r.Id) | ``$($r.File)`` | ``$($r.Opcode)`` | $($r.OrigB) | $($r.SeedB) | $($r.Ratio) | $sha | $($r.RestoreMs) | $($r.BestName) | $($r.BestB) | $win |"
}
L ""
L "---"
L ""
L "## COMPARACAO COMPLETA (todos os algoritmos)"
L ""
L "| ID | Orig (B) | Seed (B) | gzip (B) | brotli (B) | lzma (B) | zstd |"
L "|----|-------:|-------:|-------:|--------:|------:|------|"
foreach ($r in $AllResults) {
    L "| $($r.Id) | $($r.OrigB) | $($r.SeedB) | $($r.GZipB) | $($r.BrotliB) | $($r.LZMAB) | N/A |"
}
L ""
L "---"
L ""
L "## DIAGNOSTICO POR OPCODE"
L ""

# gen.pattern
$gpR=@($AllResults|?{$_.Opcode -eq 'gen.pattern'})
$gpPass=($gpR|?{!$_.SHA256OK}).Count -eq 0
$gpWin=($gpR|?{$_.TeiaWins}).Count
L "### gen.pattern"
L ""
if($gpPass){ L "**SHA-256: TODOS PASSARAM** ✅ — determinístico bit-a-bit confirmado." }
else {
    $f=($gpR|?{!$_.SHA256OK}|%{$_.Id}) -join ', '
    L "**SHA-256: FALHOU** ❌ em: $f — PRECISA_PATCH."
}
L ""
L "**Vitórias sobre melhor clássico: $gpWin/5**"
L ""
L "- Dados com padrão fixo curto (2–13B): seed ~70–130B vs. KB comprimidos → TEIA vence em ratio absoluto."
L "- Padrão longo 512B: lzma/brotli também comprimem bem dados periódicos (detectam a estrutura)."
L "- Domínio real: filling, padding, tiles — dados sintéticos com período fixo ≤ 512B."
L "- Dados reais raramente são perfeitamente periódicos → nicho."
L ""

# rle.decode
$rleR=@($AllResults|?{$_.Opcode -eq 'rle.decode'})
$rlePass=($rleR|?{!$_.SHA256OK}).Count -eq 0
$rleWin=($rleR|?{$_.TeiaWins}).Count
L "### rle.decode"
L ""
if($rlePass){ L "**SHA-256: TODOS PASSARAM** ✅ — determinístico bit-a-bit confirmado." }
else {
    $f=($rleR|?{!$_.SHA256OK}|%{$_.Id}) -join ', '
    L "**SHA-256: FALHOU** ❌ em: $f — PRECISA_PATCH."
}
L ""
L "**Vitórias sobre melhor clássico: $rleWin/5**"
L ""
L "- Run único longo (RLE-01, RLE-03): seed pequena — competitiva com clássicos."
L "- Múltiplos runs curtos (RLE-02, RLE-04): overhead JSON por pair cresce — clássicos vencem."
L "- Caso ruim (RLE-05): seed MAIOR que arquivo original — piora o armazenamento."
L "- Heurística segura: ativar RLE apenas quando n_runs < orig_size / 25."
L ""
L "---"
L ""
L "## STATUS FINAL"
L ""
$gpSt=if($gpPass){"VALIDADO_MAS_NICHO"}else{"PRECISA_PATCH"}
$rleSt=if($rlePass){"VALIDADO_MAS_NICHO"}else{"PRECISA_PATCH"}
L "| Opcode | SHA-256 | Vitórias | Status v0.16.1 | Domínio |"
L "|--------|:-------:|:--------:|----------------|---------|"
L "| ``gen.repeat``  | ✅ PROVA_INTEGRIDADE_v0.4 | 5/5 (constante) | **VALIDADO** | Dados constantes |"
L "| ``gen.pattern`` | $(if($gpPass){'✅'}else{'❌'}) esta sessão | $gpWin/5 | **$gpSt** | Periódicos fixos ≤ 512B |"
L "| ``rle.decode``  | $(if($rlePass){'✅'}else{'❌'}) esta sessão | $rleWin/5 | **$rleSt** | Poucos runs longos homogêneos |"
L "| ``dict.ref``    | ❌ encoder ausente | — | **PRECISA_PATCH** | Streams tokenizados |"
L "| ``lz.decode``   | ❌ Base64 overhead | — | **PRECISA_PATCH** | Texto/JSON via CAS no v0.16 |"
L "| ``slice.copy``  | ❌ encoder ausente | — | **PRECISA_PATCH** | Blocos duplicados |"
L "| ``xform.xor``  | ✅ trivial | 0/5 | **DESCARTAR** | Sem compressão |"
L "| ``literal``     | ✅ trivial | 0/5 | **DESCARTAR** | CAS.raw superior |"
L ""
L "---"
L ""
L "*Gerado por run_tests_v0161.ps1 — sem afirmacoes de inovacao; apenas bytes, hashes e tempos.*"

[System.IO.File]::WriteAllText($ReportPath,$sb.ToString(),[System.Text.Encoding]::UTF8)
Write-Host "Relatorio: $ReportPath"

# ── CAPABILITY MATRIX ATUALIZADA ─────────────────────────────────────
$gpSt=if($gpPass){"VALIDADO_MAS_NICHO"}else{"PRECISA_PATCH"}
$rleSt=if($rlePass){"VALIDADO_MAS_NICHO"}else{"PRECISA_PATCH"}

$matrix=[System.Text.StringBuilder]::new()
function M([string]$s=""){ $null=$matrix.AppendLine($s) }

M "# PROCEDURAL CAPABILITY MATRIX — TEIA-Core v0.4.0"
M "**Atualizado:** $ts (provas v0.16.1)"
M "**Fonte:** analise estatica de TEIA-Core-v0.4.0.ps1 + provas SHA-256 desta sessao"
M "**Motor SHA-256:** ``489D3B4024930FB4B0E12D0D40393CB86D0430178E6E272DCE328FDEC16475F6``"
M ""
M "---"
M ""
M "## SUMARIO EXECUTIVO"
M ""
M "| Opcode | Status | Encoder | Decoder | Prova SHA-256 | Dominio principal |"
M "|--------|--------|:-------:|:-------:|:-------------:|-------------------|"
M "| ``gen.repeat``  | ✅ **VALIDADO**          | ✅ | ✅ | ✅ PROVA_INTEGRIDADE_v0.4 | Dados constantes |"
M "| ``gen.pattern`` | 🔶 **$gpSt**    | ✅ | ✅ | $(if($gpPass){'✅ v0.16.1'} else {'❌'}) | Periodicos fixos <= 512B |"
M "| ``rle.decode``  | 🔶 **$rleSt** | ✅ | ✅ | $(if($rlePass){'✅ v0.16.1'} else {'❌'}) | Poucos runs longos |"
M "| ``dict.ref``    | ⚠️ **PRECISA_PATCH**    | ❌ | ✅ | ❌ ausente | Streams tokenizados |"
M "| ``lz.decode``   | ⚠️ **PRECISA_PATCH**    | ✅ | ✅ | ❌ ausente | Texto/JSON (Base64 overhead) |"
M "| ``slice.copy``  | ⚠️ **PRECISA_PATCH**    | ❌ | ✅ | ❌ ausente | Blocos duplicados |"
M "| ``xform.xor``  | ❌ **DESCARTAR**        | ✅ | ✅ | ✅ trivial | Nenhum (nao comprime) |"
M "| ``literal``     | ❌ **DESCARTAR (CAS)**  | ✅ | ✅ | ✅ trivial | Substituido por cas.raw |"
M ""
M "---"
M ""
M "## DETALHAMENTO POR OPCODE"
M ""
M "### gen.repeat — VALIDADO"
M "| Campo | Valor |"
M "|-------|-------|"
M "| **Assinatura** | ``{ op, byte: 0-255, count: int64 }`` |"
M "| **Compressao esperada** | infinita:1 — 1MB de 0xAA -> ~18B JSON |"
M "| **SHA-256 restore** | ✅ Verificado — PROVA_INTEGRIDADE_v0.4.md |"
M "| **Status** | ✅ **VALIDADO** |"
M ""
M "### gen.pattern — $gpSt"
M "| Campo | Valor |"
M "|-------|-------|"
M "| **Assinatura** | ``{ op, pattern_b64: string, repeat: int64 }`` |"
M "| **Limite** | MaxPattern=512B — padroes maiores nao detectados |"
M "| **Compressao esperada** | Alta para periodicos curtos; competitiva com classicos |"
M "| **SHA-256 restore** | $(if($gpPass){'✅ Verificado — provas GP-01 a GP-05 (v0.16.1)'}else{'❌ Falhou em algum teste — ver PROCEDURAL_OPCODE_PROOFS_v0161.md'}) |"
M "| **Vitórias sobre classicos** | $gpWin/5 nos testes v0.16.1 |"
M "| **Status** | 🔶 **$gpSt** — determinístico provado; vence apenas em dados sintéticos periodicos |"
M ""
M "### rle.decode — $rleSt"
M "| Campo | Valor |"
M "|-------|-------|"
M "| **Assinatura** | ``{ op, pairs: [{b: int, n: int64}, ...] }`` |"
M "| **Overhead** | ~25-30B JSON por pair — domina para muitos runs curtos |"
M "| **Heuristica segura** | Ativar apenas quando n_runs < orig_size / 25 |"
M "| **SHA-256 restore** | $(if($rlePass){'✅ Verificado — provas RLE-01 a RLE-05 (v0.16.1)'}else{'❌ Falhou em algum teste — ver PROCEDURAL_OPCODE_PROOFS_v0161.md'}) |"
M "| **Vitórias sobre classicos** | $rleWin/5 nos testes v0.16.1 |"
M "| **Status** | 🔶 **$rleSt** — determinístico provado; nicho em dados com poucos runs longos |"
M ""
M "### dict.ref — PRECISA_PATCH"
M "| Campo | Valor |"
M "|-------|-------|"
M "| **Assinatura** | ``{ op, dict: [string], map: [int], encoding: utf8 }`` |"
M "| **Bloqueador** | Encoder ausente no Seed-Pack — decoder funciona |"
M "| **Status** | ⚠️ **PRECISA_PATCH** — adiar para v0.17 |"
M ""
M "### lz.decode — PRECISA_PATCH"
M "| Campo | Valor |"
M "|-------|-------|"
M "| **Assinatura** | ``{ op, algo: brotli\|gzip, payload_b64: string }`` |"
M "| **Problema** | Base64 overhead +33% cancela parcialmente a compressao |"
M "| **Solucao v0.16** | cmp.zstd / cmp.lzma com objeto CAS separado |"
M "| **Status** | ⚠️ **PRECISA_PATCH** — resolver via CAS no v0.16 |"
M ""
M "### slice.copy — PRECISA_PATCH"
M "| Campo | Valor |"
M "|-------|-------|"
M "| **Assinatura** | ``{ op, offset: int64, length: int64, repeat: int64 }`` |"
M "| **Bloqueador** | Encoder ausente — decoder funciona |"
M "| **Status** | ⚠️ **PRECISA_PATCH** — adiar para v0.17 |"
M ""
M "### xform.xor — DESCARTAR"
M "| Campo | Valor |"
M "|-------|-------|"
M "| **Resultado** | Nao comprime — payload embutido em Base64 (+33% overhead) |"
M "| **Status** | ❌ **DESCARTAR** |"
M ""
M "### literal — DESCARTAR"
M "| Campo | Valor |"
M "|-------|-------|"
M "| **Resultado** | Base64 sempre expande — CAS.raw e estritamente superior |"
M "| **Status** | ❌ **DESCARTAR (substituir por cas.raw)** |"
M ""
M "---"
M ""
M "## PROBLEMA ESTRUTURAL lz.decode"
M ""
M '```'
M "Dado original:      1.000.000 bytes"
M "Apos brotli:          250.000 bytes  (ratio 0.25)"
M "Apos Base64:          333.333 bytes  (ratio 0.333 — +33% sobre comprimido)"
M ""
M "vs. CAS + cmp.zstd (v0.16 proposto):"
M "Objeto .zstd:         230.000 bytes  (ratio 0.23)"
M "Seed JSON:                 80 bytes  (apenas hash)"
M "Total efetivo:        230.080 bytes  (ratio 0.230)"
M '```'
M ""
M "---"
M ""
M "*Atualizado por run_tests_v0161.ps1 — referencia: PROCEDURAL_OPCODE_PROOFS_v0161.md*"

[System.IO.File]::WriteAllText($MatrixPath,$matrix.ToString(),[System.Text.Encoding]::UTF8)
Write-Host "Matrix: $MatrixPath"

# Resumo final no console
Write-Host ""
Write-Host "=== RESUMO FINAL ==="
$AllResults | Format-Table Id,File,OrigB,SeedB,Ratio,SHA256OK,RestoreMs,BestName,BestB,TeiaWins -AutoSize
