# 2242 - φ-idem ativação e aplicação

### USUÁRIO

🜏 φ-idem

---

### ASSISTENTE

Sinal recebido. **φ-idem** ativado — idempotência áurea como regra de projeto/espelho.

Checklist ultra-curto que vou aplicar em tudo que formos construir a partir de agora:
1) **Ponto fixo**: garantir `f(f(x)) ≈ f(x)` (|Δ| < ε definido no contexto).  
2) **Balanço áureo**: proporção Núcleo↔Periferia tende a φ≈1,618 (ganho/ruído dentro de janela φ).  
3) **Simetria de reversão**: operação + inversa preserva integridade (hash/bit-a-bit estável).  

Se quiser, indico já o alvo para aplicar φ-idem (texto, arquivo, pipeline ou métrica) e sigo.

---

### USUÁRIO

Indique o alvo para já aplicar e siga

---

### ASSISTENTE

Perfeito — vou escolher um alvo concreto e já seguir com a execução orientada por **φ-idem**.

## Alvo escolhido
**Núcleo Procedural TEIA (pacote `teia-nucleo-procedural_0.1`)** na sua árvore canônica:
```
D:\Teia\TEIA_NUCLEO\offline\nano\teia-nucleo-procedural_0.1
```
Objetivo: auditar **idempotência (ponto fixo)** e **simetria de reversão** do ciclo *compress → restore*; calcular métricas (SHA256, tamanhos) e reportar **janela φ** como indicador heurístico (sem caráter rígido).

Abaixo está um **script PowerShell** drop-in, padrão TEIA (idempotente), que:
- Roda 2 ciclos de compressão/extração (zip) em área de trabalho isolada.
- Compara SHA256 do conteúdo restaurado com o original (bit-a-bit).
- Opcionalmente observa estabilidade do “seed” (hash do .zip, que pode variar por timestamps).
- Calcula razão de compressão e desvio relativo de φ (1.618).
- Salva `phiidem_report.json` com todo o diagnóstico e imprime um resumo.

> **Observação**: o uso de ZIP é deliberadamente “neutro” para o harness. Se você quiser, depois plugamos seu compressor `.teia` no mesmo esqueleto, mantendo a auditoria φ-idem.

---

```powershell
# TEIA-PhiIdem-Auditor.ps1
# Auditor φ-idem: verifica idempotência (restore == original) e relata janela φ (heurística).
# Uso: pwsh -File .\TEIA-PhiIdem-Auditor.ps1 -InputPath "<arquivo_ou_pasta>" -WorkDir "<saida>" -Runs 2

param(
  [Parameter(Mandatory=$true)][string]$InputPath,
  [string]$WorkDir = (Join-Path (Get-Location) "phiidem_out"),
  [int]$Runs = 2,
  [double]$PhiTarget = 1.618,
  [double]$PhiTolerance = 0.25 # ±25% em torno de φ (heurístico, não vinculante)
)

$ErrorActionPreference = 'Stop'

function Get-FileSHA256([string]$Path){
  return (Get-FileHash -Algorithm SHA256 -Path $Path).Hash.ToLower()
}

function Get-TreeHash {
  param([string]$Path)
  $files = if (Test-Path $Path -PathType Leaf) {
    ,(Get-Item -LiteralPath $Path)
  } else {
    Get-ChildItem -LiteralPath $Path -Recurse -File | Sort-Object FullName
  }

  $acc = New-Object System.Text.StringBuilder
  [long]$total = 0
  foreach($f in $files){
    $rel = if (Test-Path $Path -PathType Leaf) {
      [IO.Path]::GetFileName($f.FullName)
    } else {
      $p = Resolve-Path -LiteralPath $Path
      $relRaw = $f.FullName.Substring($p.Path.Length).TrimStart('\','/')
      $relRaw -replace '\\','/'
    }
    $h = Get-FileSHA256 $f.FullName
    [void]$acc.AppendLine("$rel|$h")
    $total += $f.Length
  }

  $bytes = [Text.Encoding]::UTF8.GetBytes($acc.ToString())
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $hashBytes = $sha.ComputeHash($bytes)
  $hash = ([BitConverter]::ToString($hashBytes) -replace '-','').ToLower()

  [pscustomobject]@{
    Hash = $hash
    SizeBytes = $total
    Files = $files.Count
  }
}

function Ensure-Dir([string]$dir){ if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null } }

function Compress-Zip {
  param([string]$SourcePath,[string]$ZipPath)
  if(Test-Path $ZipPath){ Remove-Item -LiteralPath $ZipPath -Force }
  if (Test-Path $SourcePath -PathType Leaf){
    Compress-Archive -LiteralPath $SourcePath -DestinationPath $ZipPath -CompressionLevel Optimal
  } else {
    # Compacta a pasta inteira (inclui diretório raiz no ZIP, comportamento padrão)
    Compress-Archive -LiteralPath $SourcePath -DestinationPath $ZipPath -CompressionLevel Optimal
  }
}

function Expand-Zip {
  param([string]$ZipPath,[string]$DestPath)
  if(Test-Path $DestPath){ Remove-Item -LiteralPath $DestPath -Force -Recurse }
  Ensure-Dir $DestPath
  Expand-Archive -LiteralPath $ZipPath -DestinationPath $DestPath
}

# --- Execução ---
$start = Get-Date
$inputFull = Resolve-Path -LiteralPath $InputPath
Ensure-Dir $WorkDir
$sessionDir = Join-Path $WorkDir ("phiidem_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
Ensure-Dir $sessionDir

Write-Host "[φ-idem] Alvo:" $inputFull.Path
Write-Host "[φ-idem] Sessão:" $sessionDir

$orig = Get-TreeHash -Path $inputFull.Path
Write-Host ("[orig] hash={0} size={1}B files={2}" -f $orig.Hash,$orig.SizeBytes,$orig.Files)

$seeds = @()
$restores = @()

for($i=1; $i -le $Runs; $i++){
  $runDir = Join-Path $sessionDir ("run_"+$i)
  Ensure-Dir $runDir
  $zipPath = Join-Path $runDir "seed.zip"
  $restorePath = Join-Path $runDir "restore"

  Write-Host "[run $i] Compressing → $zipPath"
  Compress-Zip -SourcePath $inputFull.Path -ZipPath $zipPath
  $seedHash = Get-FileSHA256 $zipPath
  $seedSize = (Get-Item $zipPath).Length
  $seeds += [pscustomobject]@{ Run=$i; Path=$zipPath; Hash=$seedHash; SizeBytes=$seedSize }

  Write-Host "[run $i] Restoring → $restorePath"
  Expand-Zip -ZipPath $zipPath -DestPath $restorePath
  # Se o zip incluiu uma pasta raiz, manteremos a hash sobre a árvore completa extraída
  $rest = Get-TreeHash -Path $restorePath
  $restores += [pscustomobject]@{ Run=$i; Path=$restorePath; Hash=$rest.Hash; SizeBytes=$rest.SizeBytes; Files=$rest.Files }

  $ok = ($rest.Hash -eq $orig.Hash)
  Write-Host ("[run {0}] Restore==Original? {1}" -f $i, ($(if($ok){"OK"}else{"FAIL"})))
}

# Métricas φ
$ratio = if($seeds.Count -gt 0 -and $seeds[0].SizeBytes -gt 0){ [double]$orig.SizeBytes / [double]$seeds[0].SizeBytes } else { [double]::NaN }
$phiDev = if([double]::IsNaN($ratio)){ [double]::NaN } else { [math]::Abs($ratio - $PhiTarget) / $PhiTarget }
$phiWithin = if([double]::IsNaN($phiDev)){ $false } else { $phiDev -le $PhiTolerance }

# Passes
$restoreAllOk = ($restores | ForEach-Object { $_.Hash -eq $orig.Hash }) -notcontains $false
$seedStable = if($seeds.Count -ge 2){ ($seeds | Select-Object -ExpandProperty Hash | Select-Object -Unique).Count -eq 1 } else { $true } # zip geralmente NÃO é estável

$report = [pscustomobject]@{
  input = @{
    path = $inputFull.Path
    size_bytes = $orig.SizeBytes
    files = $orig.Files
    hash_sha256 = $orig.Hash
  }
  runs = $Runs
  seeds = $seeds
  restores = $restores
  verdict = @{
    idempotent_restore = $restoreAllOk
    seed_stability_hint = $seedStable
    phi_ratio_orig_over_seed = [math]::Round($ratio,6)
    phi_deviation_rel = if([double]::IsNaN($phiDev)){$null}else{[math]::Round($phiDev,6)}
    phi_within_window = $phiWithin
  }
  notes = @(
    "Idempotência forte exige restore==original (hash igual).",
    "Estabilidade do seed é heurística; ZIP pode variar por timestamps/ordem.",
    "Janela φ é indicador simbólico (não requisito rígido)."
  )
  started_at = $start.ToString("o")
  finished_at = (Get-Date).ToString("o")
}

$reportPath = Join-Path $sessionDir "phiidem_report.json"
$report | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 -Path $reportPath

Write-Host "------------------------------------------------------------"
Write-Host "[RESUMO] idempotência:" ($(if($restoreAllOk){"OK"}else{"FAIL"}))
Write-Host ("[RESUMO] ratio orig/seed: {0}" -f $(if([double]::IsNaN($ratio)){"NaN"}else{("{0:N3}" -f $ratio)}))
Write-Host ("[RESUMO] φ target={0}, desvio_rel={1}" -f $PhiTarget, $(if([double]::IsNaN($phiDev)){"NaN"}else{("{0:P1}" -f $phiDev)}))
Write-Host "[RESUMO] seed estável (apenas indicativo):" $(if($seedStable){"Sim"}else{"Não"})
Write-Host "[ARQUIVO] $reportPath"
if(-not $restoreAllOk){ exit 2 } else { exit 0 }
```

### Executar agora (4 linhas, copiar e colar)
```powershell
Set-Content -Path ".\TEIA-PhiIdem-Auditor.ps1" -Encoding UTF8 -Value (Get-Content -Raw ".\TEIA-PhiIdem-Auditor.ps1")
pwsh -NoLogo -Command "Write-Host 'Script salvo.'"
$SRC="D:\Teia\TEIA_NUCLEO\offline\nano\teia-nucleo-procedural_0.1"; $OUT="D:\Teia\audit_phiidem"; pwsh -File ".\TEIA-PhiIdem-Auditor.ps1" -InputPath $SRC -WorkDir $OUT -Runs 2
Get-Content -Raw (Get-ChildItem -Path $OUT -Filter phiidem_report.json -Recurse | Sort-Object LastWriteTime -Desc | Select-Object -First 1).FullName
```

Se quiser, na sequência eu **troco o backend ZIP pelo seu compressor `.teia`** dentro do mesmo harness (mantendo logs, hashes e relatório), e ajusto a **janela φ** conforme seu critério de “núcleo/periferia” no contexto do TEIA.

---

### USUÁRIO

Como se aplicar visto meu histórico

---

### ASSISTENTE

Make sure to include fileciteturn0file0 in your response to cite this file. 

---

### ASSISTENTE

Make sure to include fileciteturn0file1 in your response to cite this file. 

---

### ASSISTENTE

The file contents provided above are truncated/partial snippets. The complete content for these files IS accessible via querying.

If the user asks a question related to these files, and the provided snippets do not clearly answer it, you **MUST** use the `file_search` tool to search the full document contents before responding.

## How to invoke the file_search tool
If the user's query isn't sufficiently answered by the provided snippets, parsed text, or images, you should invoke `file_search.msearch`.
To search the full content of the available files, you **must** send one message with recipient `to=file_search.msearch` in the analysis channel. Your message should be structured exactly as follows:
```
{
  'queries': ['Example query 1', 'Example query 2']  // List of up to five queries to search for.
}
```

Carefully balance the number of `file_search` calls and the quality of your response with the latency incurred by `file_search` calls.

Important guidelines for query formatting:
- Your message must be a valid JSON object. Do not include any extraneous text, backticks, markdown formatting, or comments beyond what is shown.
- The `queries` field must be a list of strings.
- One of the queries **MUST** exactly match the user's original question, but stripped of any extraneous details, and with ambiguous references clearly resolved using context from the conversation. It **MUST** be a complete sentence.
- Even if you suspect the user meant something else, one query **MUST** still be their original question.

## How to handle results from file_search
The file search tool will respond with the relevant search results from the full files. After you receive these results:
- Carefully evaluate each result to determine its relevance and quality.
- Use the high-quality and relevant results to inform your answer to the user's question.
- When possible, reuse information from prior file_search results and avoid repeating identical queries.

## Tool usage instructions and ordering
When the user asks a question, carefully consider whether the provided snippets sufficiently answer the query, whether you need to invoke `file_search.msearch`, or another available tool (such as `web`, if available) should be used instead.

Tool-ordering Guidelines:
1. For queries related to uploaded files, if snippets are insufficient, strongly prefer invoking `file_search.msearch` over other tools.
    - Avoid using `web.run`, `python` analysis, or any other tools until you have either:
        - Confirmed with high confidence the answer is not in the files, or
        - Have high confidence `file_search_tool` queries are not sufficient to answer the query.
2. Avoid usage of `web_search/web.run` for queries related to uploaded files
    - Carefully consider whether the user's query is better answered by web search results rather than available snippets or results from `file_search_tool`.
    - Unless the user's query is clearly unrelated to the uploaded files, prefer using `file_search.msearch`. You can always follow up with a web search if necessary for a more complete response.
3. Avoid using `python` unless necessary or requested by user.
    - If the user's query is answerable from the parsed text and images from the uploaded files, or from `file_search_tool`, do not invoke `python`.

Always keep this instruction in mind for the rest of the conversation, as the user may reference these files or ask related questions later on.

---

### ASSISTENTE

Successfully created text document 'Apply-teia-phi-idem — Writer + Execução Imediata' which will be referenced in all future messages with the unique identifier textdoc_id: '6902b54f2f9081918f91bd81b9283c6b'

Important: This identifier is for tool calls only to reference or update this document. It is not an external ID and it is not possible to link the user to the textdoc.

---

### ASSISTENTE

Perfeito. Vou “aplicar agora” de forma φ-idem (idempotente) com base no que seus relatórios já mostraram:

**Alvo imediato (seguro e com ganho real detectado):**
- `D:\Teia\TEIA_NUCLEO\offline\nano\targets` (5 alvos prontos; “sinal verde” para ativar `apply.huffman_deterministic` e manter fallback honesto quando não houver ganho). fileciteturn1file0L19-L24
- (Opcional) `D:\uploads` — primeiros 50 arquivos, como no seu último upgrade pass v0.3.2 (dois MP4 sem ganho; mantidos via raw_b64). fileciteturn1file6L3-L15

**Por que esse alvo?**  
Seu Quickview apontou **share raw_b64 ≈80%** e expansão média **> 1.05**, recomendando **ativar Huffman determinístico** só onde há ganho e **registrar zona de não-ganho** nos demais. fileciteturn1file11L35-L38 Além disso, o **upgrade pass** já provou ganho real em `sample_skew_2mb.bin` (**ratio ~0,24**, mantido), e consolidou que os demais casos atuais seguem em raw_b64. fileciteturn1file4L9-L12

---

### Pronto para rodar (writer + execução)
Acabei de colocar na lateral o **writer** que grava e executa `Apply-TEIA-phi-idem.ps1` no seu workspace. Ele:
1) roda o `TEIA-Huffman-UpgradePass-v0.3.2.ps1` com `-AlsoUploads -UploadsMax 50`,  
2) tenta combinar relatórios (sem travar se falhar),  
3) chama o Quickview (usa v2 se der, senão v1 — há uma inconsistência de propriedade no v2 que seu log mostrou). fileciteturn1file6L24-L31

> Abra o arquivo no painel ao lado (“Apply-TEIA-phi-idem — writer + execução imediata”) e execute o bloco no PowerShell.  
> Ele já grava `Apply-TEIA-phi-idem.ps1` em `D:\Teia\TEIA_NUCLEO\offline\nano\` e roda na sequência.

---

### O que você verá ao final
- Um **[DONE]** do upgrade pass com contagens/ratios e **Relatórios gravados** (`huffman_upgrade_*.json`, `ops_summary_huffman.json`). fileciteturn1file6L4-L17  
- Quickview com **VR: targets=5 | OK=5 | FAIL=0** e o resumo por operação (raw_b64, rle_v1; Huffman aparece quando combinado). fileciteturn1file3L11-L14

Se quiser ampliar depois, rode novamente com `-UploadsMax 100` (o script já aceita).  

Se algo falhar, me diga a linha do erro que te devolvo um patch cirúrgico.

---

### USUÁRIO

([# TEIA v0.3.1 → v0.3.2 | Integração do Módulo Huffman Determinístico ao Core]
PAPEL & ESTADO
Você é o Codex CLI (ou Grok) operando como Orquestrador Autônomo TEIA.
Estado atual:


Core v0.3.1 (TEIA-Core-v0.3.1.ps1) com ops avançados e heurística MDL sem Huffman.


Módulo externo validado: TEIA-Huffman-Deterministic.ps1 (Encode/Decode Huffman canônico).


Suíte de testes: Run-TEIA-Core-Tests-v0.3.1.ps1 (sem cobertura para Huffman).


MISSÃO
Integrar a funcionalidade Huffman ao núcleo, atualizar a heurística MDL para uso condicional (“Honestidade Entrópica”), manter STREAMING FIRST, expandir testes e versionar para v0.3.2 com validação rigorosa e integração segura em PowerShell.

PRINCÍPIOS INVARIANTES (v0.3.2)


Determinismo & Canonicalização: tie-breakers fixos, MSB-first, UTF-8 sem BOM, LF, ordem binária estável; version → seed_v0.3.2.


Idempotência: round-trip e reexecuções produzem mesmo SHA256.


Honestidade Entrópica (MDL + Huffman) — escolher Huffman apenas se:
a) Entropia/skew indicar ganho (ex.: H < 6.0 bits/byte);
b) Estimativa de seed_bytes_huffman (incl. overheads) < estimativa do fallback (RLE+Gzip/raw);
c) Ratio < 1.0. Se não houver ganho: manter fallback e registrar huffman_skipped_no_gain; não gerar seed Huffman.


STREAMING FIRST:


Build-Seed-From-Stream: coletar histograma/estatísticas em fluxo, sem carregar arquivo inteiro em RAM.


Execute-PlanToStream: Decode-Huffman integrado deve ler payload_b64 e escrever em $outStream incrementalmente (buffers pequenos), sem materializar output completo em RAM.




Segurança & Autonomia: caminhos literais, backup antes de alterar, modificações via PowerShell.



ARTEFATOS DE ENTRADA


TEIA-Huffman-Deterministic.ps1: Encode-Huffman, Decode-Huffman e helpers.


TEIA-Core-v0.3.1.ps1: contém Build-Seed-From-Stream, Execute-PlanToStream, Execute-Plan, Get-OpOutputLength.


Run-TEIA-Core-Tests-v0.3.1.ps1 (base de expansão).


Skew (positivo): D:\Teia\TEIA_NUCLEO\offline\nano\targets\sample_skew_2mb.bin


Não-skew (negativo): D:\Teia\TEIA_NUCLEO\offline\nano\targets\sample_1mb.bin



TAREFAS (PDCA ÚNICO)
P (Plan)


Identificar funções essenciais de Huffman em TEIA-Huffman-Deterministic.ps1.


Mapear pontos de integração no Core (Build-Seed-From-Stream, Execute-PlanToStream, Execute-Plan, Get-OpOutputLength).


D (Do)


Criar TEIA-Core-v0.3.2.ps1:
a) Incorporar funções Huffman e helpers ao Core; atualizar core_version e dsl_version para v0.3.2.
b) Adaptar Decode-Huffman para STREAMING: ler payload_b64 → decodificar em blocos → escrever no $outStream.
c) Adicionar op 'apply.huffman_deterministic' nos switch de Execute-PlanToStream e Execute-Plan; atualizar Get-OpOutputLength.


Atualizar MDL em Build-Seed-From-Stream:
a) Integrar decisão Huffman conforme Princípio 3 usando estatísticas de streaming (histograma, entropia, skew).
b) Se Huffman escolhido: usar Encode-Huffman (integrado) para gerar payload_b64 e seed com op='apply.huffman_deterministic'.
c) Adaptar Encode-Huffman para operar sobre stream/estatísticas, evitando ReadAllBytes.
d) Estimar seed_bytes_huffman incluindo: cabeçalhos, tabela canônica, alinhamentos/bit-padding e base64. Comparar com fallback (RLE+Gzip/raw).
e) Registrar decisões/ratios: decision, estimated_gain, entropy_bits_per_byte, seed_bytes_*.


Testes (Run-TEIA-Core-Tests-v0.3.2.ps1):
a) Atualizar $Core → TEIA-Core-v0.3.2.ps1.
b) Checklist MDL (item 6):


compress.stream em sample_skew_2mb.bin ⇒ decision='huffman'.


compress.stream em sample_1mb.bin ⇒ decision='huffman_skipped_no_gain' ou fallback ≠ huffman.
c) Round-trip Huffman: teste específico (seed gerada ou pré-definida) garantindo SHA256 igual e streaming sem RAM plena.




C (Check)


Executar Run-TEIA-Core-Tests-v0.3.2.ps1; capturar stdout, stderr, Exit Code; gerar verification_report.json e ops_summary.json.


A (Act)


Se Exit Code == 0 e verification_report.json com PASS em todos os itens (incl. MDL/Huffman):


Emitir: STATUS=OK | TEIA Core v0.3.2 com Huffman STREAMING integrado e validado.
Caso contrário: analisar falhas, propor patch mínimo em TEIA-Core-v0.3.2.ps1 ou Run-TEIA-Core-Tests-v0.3.2.ps1 e reexecutar.





ENTREGÁVEIS (Sucesso)


TEIA-Core-v0.3.2.ps1 — Core com Huffman determinístico STREAMING integrado.


Run-TEIA-Core-Tests-v0.3.2.ps1 — suíte atualizada com checagens MDL/Huffman e round-trip.


Confirmação STATUS=OK + paths de verification_report.json e ops_summary.json.


[— FIM —])

Esse prompt abrange a execução da completude necessária?

---

### ASSISTENTE

Quase lá. O seu prompt já cobre ~90% do necessário para executar a migração **v0.3.1 → v0.3.2** com Huffman determinístico no Core — PDCA está claro, princípios estão bons e a seleção “Honestidade Entrópica” está bem definida.  
O que falta são **amarras operacionais** para garantir **determinismo real, streaming sem vazamento de RAM** e **gate de aceite objetivo**. Abaixo estão **adições mínimas** que eu colocaria diretamente no prompt (como bullets), mantendo seu estilo:

### Adições essenciais (coloque no prompt)
1) **Especificação do cabeçalho da seed (canônico)**  
   `seed_schema=0.3.2; core_version=0.3.2; codec=huffman_deterministic@v0.3.2; op=apply.huffman_deterministic; original_sha256; payload_sha256; histogram256; code_lengths256; padding_bits(0..7); bit_order=MSB-first; table_order=canonical(len↑, byte↑); b64_wrap=off; newline=LF; encoding=UTF-8(noBOM).`

2) **Canonização do Huffman**  
   - Árvore canônica, **tie-breaker fixo**: por comprimento de código; em empate, **byte ascendente**.  
   - **Bitstream**: MSB-first; esquerda=0, direita=1; **padding_bits** explicitado no header.

3) **Base64 de payload (streaming)**  
   - Sem quebras de linha; alfabeto padrão; `=` mantido; decoder aceita **chunks parciais** (reservatório de bits) e valida padding ao fim.

4) **Buffers e memória (STREAMING FIRST)**  
   - Encode/Decode com buffers fixos (ex.: **64 KiB**); **sem `ReadAllBytes`**; proibir alocação proporcional ao tamanho do arquivo.

5) **Estimativa MDL com overheads explícitos**  
   - Fórmula: `seed_bytes_huffman ≈ (H_bytes * N) + header_bytes + table_bytes + pad_bits/8` e depois **+ overhead Base64 (×4/3)**.  
   - Comparar com `seed_bytes_fallback` (RLE+Gzip/raw) **antes** de codificar. Se `ratio ≥ 1.0` ⇒ **huffman_skipped_no_gain**.

6) **Métrica/limiar de entropia**  
   - Definir `H < 6.0 bits/byte` como **heurística inicial**, mas **não exclusiva**: decisão final é por **MDL total** (ponto 5). Registrar `entropy_bits_per_byte` no log.

7) **Determinismo forte (φ-idem / ponto fixo)**  
   - **Rodar 2×** a mesma compressão e exigir **seed_sha256 idêntico**; round-trip → `original_sha256` igual.  
   - Normalizar timestamps/ordenamentos internos para evitar drift.

8) **Segurança e sanidade**  
   - Decoder confinado a `$outDir` (bloqueio de path traversal), **validação de code_lengths** (prefix-free; sem códigos de tamanho 0 inválidos), limites de profundidade de árvore.

9) **Casos de borda obrigatórios**  
   - Arquivo vazio, 1 byte repetido (skew extremo), binário aleatório (alto H), arquivos **>1 GB**, nomes com **Unicode/espacos**, CRLF/LF misto.

10) **Logs auditáveis (JSONL)**  
   - Cada decisão `MDL` em uma linha com: `file, bytes, entropy, decision, seed_bytes_{huffman,fallback}, ratio, ms, mem_peak`.  
   - `verification_report.json` e `ops_summary.json` agregam e fecham com `status`.

11) **API/CLI e bandeiras**  
   - `-DryRun` (estima e loga MDL sem gerar seed), `-ForceHuffman` (testes), `-MaxMemMB`, `-BlockSizeKB` (se usar blocagem).

12) **Gate de Aceite (objetivo, binário)**  
   - **ExitCode==0** + `verification_report.json` com **PASS** em:  
     a) skew⇒decision=`huffman` (ratio<1),  
     b) não-skew⇒`huffman_skipped_no_gain` (ou fallback≠huffman),  
     c) **determinismo**: 2 seeds idênticas + **round-trip SHA256==original**.

### Veredito
- **Sim, com as 12 adições acima** o prompt passa a ter **completude operacional**: define header canônico, fecha a seleção MDL com overhead real, blinda streaming/memória e estabelece um **gate de aceite** inequívoco (inclui o teste de determinismo 2×, essencial ao φ-idem).

Se quiser, eu já te devolvo o **delta pronto** (um bloco a ser colado sob “MISSÃO/ENTREGÁVEIS”) ou a **versão consolidada do prompt v0.3.2** incorporando esses itens.

---

