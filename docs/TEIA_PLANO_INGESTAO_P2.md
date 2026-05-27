# TEIA — Plano de Ingestão Real P2
**Data:** 2026-05-27  
**Fase:** P2 — Validação com dados reais do operador  
**Pré-requisito:** NeuroPlanner v0.19.9 operacional (baseline v0.19.8 congelado)  
**Inbox canônico:** `D:\TEIA_USER\Inbox\`

---

## Contexto

A fase P1 (dados sintéticos e arquivos do ecossistema TEIA) provou a arquitetura Rule-First:

| Fase | Dataset | Acertos | Hard Rules | LLM calls |
|------|---------|---------|-----------|-----------|
| P1 — Sintéticos | corpus_d1.bin, corpus_d2.bin | 2/2 | HR1 + HR2 | 0 |
| P1 — Reais TEIA | 6 arquivos do ecossistema | 6/6 | HR3, HR5 + 4×LLM | 4 |

A fase P2 expõe o sistema a dados da vida real do operador: documentos pessoais, imagens, logs, vídeos. O objetivo não é armazenar — é verificar que o NeuroPlanner classifica corretamente cada tipo e que o CAS permanece intacto.

**Regra de ouro da P2:** `CAS delta = 0` em todos os runs. O NeuroPlanner só produz `candidate.json`; nenhum arquivo é comprimido ou movido nesta fase.

---

## Estado Atual do Inbox

```
D:\TEIA_USER\Inbox\
  piloto_config.json    ← já analisado (v0.19.x)
  piloto_doc.pdf        ← já analisado (v0.19.x)
  piloto_imagem.png     ← já analisado (v0.19.x)
  piloto_nota.txt       ← já analisado (v0.19.x)
  piloto_notas.md       ← já analisado (v0.19.x)
  teste_ingestao.txt    ← já analisado (v0.19.x)
```

Os candidatos existentes serão pulados (idempotência). Para re-analisar com v0.19.9, delete os `.candidate.json` correspondentes em `D:\TEIA_CORE\neuroplanner\candidates\` antes do run.

---

## Estrutura de Subpastas do Inbox

```
D:\TEIA_USER\
  Inbox\          ← ponto de entrada principal (qualquer arquivo)
  Documents\      ← sugerido para PDFs, DOCX, TXT, MD
  Images\         ← sugerido para JPG, PNG, WEBP
  Videos\         ← sugerido para MP4, MKV, AVI
```

O script aceita qualquer caminho via `-Files`. Use `Get-ChildItem -Recurse` para varrer subpastas.

---

## Lotes de Validação

### LOTE 1 — Baixa Entropia (Alvo: HR1 e HR2)

**Objetivo:** confirmar que arquivos de conteúdo homogêneo ou periódico disparam as Hard Rules determinísticas sem consultar o LLM.

| Tipo de arquivo | Entropia esperada | Hard Rule esperada | Estratégia |
|----------------|------------------|--------------------|-----------|
| Arquivo de zeros ou byte único (`\x00` × N) | ~0.0 | HR1 `unique_bytes == 1` | `gen.repeat` |
| Log com linha idêntica repetida (ex: `INFO: OK\n` × 1000) | 2–4 | HR2 `period_bytes ∈ (0, 512]` | `gen.pattern` |
| CSV simples com poucos campos distintos | 2–4 | HR2 ou LLM (depende do período) | `gen.pattern` ou `cmp.lzma` |
| Arquivo `.txt` com uma palavra repetida N vezes | ~0–2 | HR1 ou HR2 | `gen.repeat` ou `gen.pattern` |

**Exemplos concretos para colocar no Inbox:**
- Um `.log` legado com mensagens repetitivas
- Um `.csv` de dados tabulares simples (ex: exportação de planilha)
- Um `.txt` de notas com conteúdo repetitivo

**Sinal de sucesso:** console mostra `[HR1]` ou `[HR2]` — sem linha `LLM (qwen2.5-coder:7b): lzma vs brotli...`.

---

### LOTE 2 — Entropia Média (Alvo: Decisão LLM)

**Objetivo:** confirmar que o LLM opera corretamente na zona ambígua `entropy ∈ [2, 7)` para arquivos ≥ 8 KB — escolhendo entre `cmp.lzma` e `cmp.brotli`.

| Tipo de arquivo | Entropia esperada | Decisão esperada | Observação |
|----------------|------------------|-----------------|-----------|
| PDF (documento texto) | 5–7 | LLM → `cmp.lzma` | PDF já tem compressão interna; entropia pode ser alta |
| DOCX / ODT | 5–7 | LLM → `cmp.lzma` | Container ZIP interno — pode acionar HR3/HR4 |
| Transcrição de voz (`.txt`) > 8 KB | 4–6 | LLM → `cmp.lzma` ou `cmp.brotli` | Depende de repetição de palavras |
| Código-fonte (`.py`, `.js`, `.ps1`) ≥ 8 KB | 4–6 | LLM → `cmp.lzma` | Tokens longos repetidos favorece LZMA |
| JSON de dados > 8 KB | 4–6 | LLM → `cmp.lzma` | Chaves repetidas → LZMA vence |

**Atenção — PDFs e DOCX:** esses formatos têm magic bytes de container comprimido (ZIP para DOCX, flate interno para PDF). É provável que caiam em **HR4** (`cas.raw`) em vez de atingir o LLM. Isso é comportamento correto — documente o resultado.

**Sinal de sucesso:** console mostra `[LLM]` e `LLM (qwen2.5-coder:7b): lzma vs brotli... → cmp.lzma` (ou brotli). Relatório final mostra arquivo em `LZMA/BROTLI (N) — LLM decide (size ≥ 8 KB)`.

---

### LOTE 3 — Alta Entropia (Alvo: HR3 `cas.raw`)

**Objetivo:** confirmar que arquivos incompressíveis ou já comprimidos são identificados imediatamente pela entropia ou magic bytes, sem consulta ao LLM.

| Tipo de arquivo | Entropia esperada | Hard Rule esperada | Estratégia |
|----------------|------------------|--------------------|-----------|
| JPG / JPEG (foto) | 7.5–8.0 | HR3 `entropy ≥ 7.0` | `cas.raw` |
| MP4 / MKV (vídeo) | 7.8–8.0 | HR3 `entropy ≥ 7.0` | `cas.raw` |
| ZIP / 7z / RAR | 7.5–8.0 | HR4 magic comprimido | `cas.raw` |
| PNG (foto real, não sintética) | 7.0–7.8 | HR3 | `cas.raw` |
| PNG sintético (gradiente simples) | 2–5 | LLM ou HR5 | `cmp.brotli` ou `cmp.lzma` |

**Sinal de sucesso:** console mostra `[HR3]` ou `[HR4]` — sem chamada LLM. Relatório final mostra arquivo em `CAS_RAW (N) — HR3/HR4`. Nenhum byte desperdiçado em recompressão.

---

## Instrução de Execução para o Operador

```powershell
# ── PASSO 1: Colocar arquivos no Inbox ────────────────────────────────────────
# Copie os arquivos dos lotes para:
#   D:\TEIA_USER\Inbox\          (ponto de entrada geral)
# Opcionalmente organize em subpastas:
#   D:\TEIA_USER\Documents\      (PDFs, DOCX, TXT)
#   D:\TEIA_USER\Images\         (JPG, PNG)
#   D:\TEIA_USER\Videos\         (MP4, MKV)

# ── PASSO 2: Rodar NeuroPlanner em modo DRY-RUN (sem gravar candidates) ───────
pwsh -File D:\TEIA_CORE\tools\TEIA-NeuroPlanner-v0199.ps1 `
     -Files (Get-ChildItem D:\TEIA_USER\Inbox -File).FullName `
     -DryRun

# ── PASSO 3: Rodar em modo ATIVO (grava candidates, zero CAS write) ───────────
pwsh -File D:\TEIA_CORE\tools\TEIA-NeuroPlanner-v0199.ps1 `
     -Files (Get-ChildItem D:\TEIA_USER\Inbox -File).FullName

# ── PASSO 4: Para varrer subpastas também (Documents, Images, Videos) ─────────
pwsh -File D:\TEIA_CORE\tools\TEIA-NeuroPlanner-v0199.ps1 `
     -Files (Get-ChildItem D:\TEIA_USER -File -Recurse).FullName

# ── PASSO 5: Verificar CAS intacto (deve ser 2369 ou mais — nunca menos) ──────
(Get-ChildItem "D:\TEIA_CORE\objects\*.bin" -ErrorAction SilentlyContinue).Count
# Resultado esperado: mesmo número do início da sessão

# ── PASSO 6: Inspecionar um candidate gerado ──────────────────────────────────
# Substitua {SHA256} pelo hash exibido no console
Get-Content "D:\TEIA_CORE\neuroplanner\candidates\{SHA256}.candidate.json" | ConvertFrom-Json | Select-Object version, final_strategy, planner_verdict
```

---

## Critérios de Validação P2

| Critério | Verificação | Aceitável |
|----------|------------|-----------|
| CAS delta = 0 | `(Get-ChildItem D:\TEIA_CORE\objects\*.bin).Count` igual antes/depois | Obrigatório |
| Arquivos originais intocados | SHA-256 dos originais inalterado | Obrigatório |
| HR1/HR2 acionadas no Lote 1 | Console mostra `[HR1]` ou `[HR2]` | Pelo menos 1 arquivo |
| LLM acionado no Lote 2 | Console mostra linha `LLM (...)` | Pelo menos 1 arquivo ≥ 8 KB sem período |
| HR3/HR4 acionadas no Lote 3 | Console mostra `[HR3]` ou `[HR4]` | Pelo menos 1 arquivo JPG/ZIP |
| Zero overflow de candidate | Candidate JSON < 512 KB | Todos os arquivos |
| Zero alucinação de parâmetros | `recipe.value_hex` ausente em `cmp.lzma`/`cmp.brotli` | Todos os arquivos |

---

## O Que Fazer Com os Resultados

Após a rodada P2:

1. **Documente anomalias**: se um arquivo esperado para HR1/HR2 foi para LLM, o período pode não ter sido detectado. Aumentar a amostragem (`-EntropySampleBytes 1048576`) pode ajudar.
2. **PDFs na LLM zone**: se PDFs com magic ZIP (DOCX, XLSX) forem para `cas.raw` por HR4, isso é correto — o container já está comprimido.
3. **Gere relatório P2**: copie o output do console para `D:\TEIA_CORE\docs\NEUROPLANNER_INGESTAO_P2_RESULTS.md` com a tabela de resultados reais.

---

## Próxima Fase (P3 — Executor)

Quando P2 confirmar que todos os `candidate.json` têm `final_strategy` correto:

- **P3** conecta o Executor (UVM) ao NeuroPlanner: lê os candidates com `integrity_proof.pass == true` ou `verifiable == false` (compressores externos) e executa a compressão real, gravando o resultado no CAS.
- Apenas neste ponto o CAS crescerá com objetos reais comprimidos.

---

*Documento gerado em 2026-05-27. Inbox verificado: D:\TEIA_USER\Inbox existe com 6 arquivos piloto.*
