# NEUROPLANNER — Auditoria da Zona Ambígua v0.19.6
**Data:** 2026-05-27  
**Script:** `TEIA-NeuroPlanner-v0195.ps1` (modo ATIVO, 6 chamadas LLM)  
**Modelo:** `qwen2.5-coder:7b`  
**Dataset:** 6 arquivos reais TEIA — todos na zona `entropy∈[2,7)`, sem período detectado  
**Objetivo:** Avaliar se o LLM supera heurísticas estáticas na escolha LZMA vs Brotli  
**Resultado:** 5/6 decisões corretas (83.3%) | Tempo total: 165s | CAS delta=0

---

## 1. Metodologia

```
Para cada arquivo:
  1. NeuroPlanner → Hard Rules (HR1-HR4) → nenhuma se aplica → LLM: "lzma ou brotli?"
  2. Benchmark: comprimir com 7z LZMA (-mx=9, lzma2) e Brotli (.NET, quality=Optimal)
  3. Comparar decisão LLM com vencedor real
  4. Verificar SHA-256 pré e pós para garantir integridade dos originais
```

**Ferramentas de compressão:**
- LZMA: `7z.exe` v24.x, `-t7z -mx=9 -m0=lzma2 -mmt=1`
- Brotli: `.NET 9 System.IO.Compression.BrotliStream`, `CompressionLevel.Optimal` (≈ quality 11)

---

## 2. Tabela Comparativa Principal

| # | Arquivo | Tamanho | Entropia | Decisão LLM | Ratio LZMA | Ratio Brotli | Vencedor Real | Δ (pp) | LLM Acertou? |
|---|---------|---------|----------|-------------|-----------|--------------|---------------|--------|--------------|
| 1 | `fractal_index.json` | 1266.6 KB | 5.2792 | `cmp.lzma` | **10.0%** | 10.6% | LZMA | +0.6pp | ✓ |
| 2 | `.teia_map.json` | 2.5 KB | 5.2867 | `cmp.lzma` | 28.1% | **23.1%** | Brotli | 5.0pp | ✗ |
| 3 | `dna_events.jsonl` | 1071.4 KB¹ | 5.4112 | `cmp.lzma` | **17.8%** | 21.6% | LZMA | +3.8pp | ✓ |
| 4 | `Benchmark-Chunked.log.json` | 22.1 KB | 4.1242 | `cmp.lzma` | **5.4%** | 5.7% | LZMA | +0.3pp | ✓ |
| 5 | `TEIA-Core-v0.4.0.ps1` | 6.3 KB | 5.2398 | `cmp.brotli` | 36.3% | **35.7%** | Brotli | 0.6pp | ✓ |
| 6 | `TEIA-NeuroPlanner-v0195.ps1` | 25.7 KB | 5.0547 | `cmp.lzma` | **27.1%** | 29.1% | LZMA | +2.0pp | ✓ |

**Acurácia LLM: 5/6 = 83.3%**

¹ *Arquivo em crescimento — ver seção 5 (anomalia SHA-256).*

**Notas sobre os ratios:** valores menores = melhor compressão (ex: 10.0% = arquivo comprimido ocupa 10% do original).

---

## 3. Análise Detalhada por Arquivo

### 3.1 fractal_index.json — `cmp.lzma` ✓

**Razão do LLM:**
> "O arquivo tem uma alta entropia (5.259) e um número de bytes únicos relativamente baixo (68), indicando que pode conter padrões repetitivos ou longos strings, o que torna o LZMA mais eficiente."

**Análise:** LZMA comprimiu 1.266 KB para **126 KB** (10.0%); Brotli para **134 KB** (10.6%). Diferença de 8 KB (0.6pp). Para JSON grande com estrutura repetitiva (chaves JSON, hashes, metadados), o algoritmo LZ77 com janela longa do LZMA captura back-references que se repetem ao longo do arquivo inteiro — vantagem real em arquivos > 1MB. Decisão correta.

---

### 3.2 .teia_map.json — `cmp.lzma` ✗

**Razão do LLM:**
> "O arquivo é um JSON e possui uma alta entropia (5.2867), o que sugere a presença de dados não estruturados ou menos repetitivos. Com compressão LZMA, podemos obter economias significativas em comparação com Brotli."

**Análise:** LZMA comprimiu 2.5 KB para **718 B** (28.1%); Brotli para **594 B** (23.1%). Brotli vence por 5pp. **Por que?** Para arquivos pequenos (< 4 KB), o dicionário estático do Brotli (construído sobre n-gramas comuns do corpus de texto web) compensa a falta de janela larga. O LZMA precisa de mais dados para amortizar seu overhead de cabeçalho e encontrar back-references úteis. O LLM argumentou corretamente sobre a estrutura JSON mas errou ao desconsiderar o tamanho: **a vantagem do LZMA manifesta-se em arquivos maiores**.

---

### 3.3 dna_events.jsonl — `cmp.lzma` ✓

**Razão do LLM:**
> "O arquivo tem uma alta entropia e um tamanho significativo, indicando que pode conter padrões de repetição de tokens longos ou strings frequentes. LZMA é melhor para esses tipos de dados."

**Análise:** LZMA 17.8% vs Brotli 21.6% — LZMA melhor por 3.8pp, comprimindo ~1MB de eventos JSON-lines para 191 KB vs 231 KB. O LLM raciocinou corretamente sobre repetição de tokens em logs JSONL (campos como `"op"`, `"sha256"`, timestamps). Acerto com boa margem.

---

### 3.4 Benchmark-Chunked.log.json — `cmp.lzma` ✓

**Razão do LLM:**
> "O arquivo é um JSON estruturado com alta entropia e poucos bytes únicos. Este perfil é ideal para compressão por algoritmo estatístico, sendo o LZMA uma excelente escolha."

**Análise:** Diferença mínima (5.4% vs 5.7% — apenas 0.3pp, ~66 bytes). Para este arquivo, a razão de compressão excepcional de ambos (~95% de redução) reflete a estrutura altamente repetitiva do benchmark JSON. A margem é tão pequena que ambas as escolhas seriam equivalentes na prática. Tecnicamente LZMA ganhou.

---

### 3.5 TEIA-Core-v0.4.0.ps1 — `cmp.brotli` ✓

**Razão do LLM:**
> "O arquivo possui um baixo nível de entropia e bytes únicos relativamente altos. Isso sugere que o conteúdo é texto curto com alta repetição de palavras, o que Brotli pode comprimir eficientemente."

**Análise:** Brotli 35.7% vs LZMA 36.3% — Brotli melhor por apenas 0.6pp. O LLM foi o único arquivo onde decidiu `cmp.brotli`. A razão ("texto curto com repetição de palavras") está parcialmente correta: código PowerShell tem keywords repetidas (`function`, `param`, `if`, `return`) que o dicionário estático do Brotli mapeia bem. Para scripts pequenos (< 10KB), Brotli e LZMA são praticamente equivalentes — acerto marginal.

---

### 3.6 TEIA-NeuroPlanner-v0195.ps1 — `cmp.lzma` ✓

**Razão do LLM:**
> "O arquivo tem uma alta entropia (5.0547), indicando que a informação é distribuída de forma uniforme e não há padrões repetitivos longos ou palavras comuns, o que torna a comparação LZMA mais eficaz."

**Análise:** LZMA 27.1% vs Brotli 29.1% — LZMA melhor por 2pp. Para o script maior (25.7KB vs 6.3KB do Core v0.4.0), a janela LZMA começa a ser mais eficaz capturando repetições de funções PowerShell completas (ex: o bloco `foreach` e padrões de `Write-Host` que se repetem múltiplas vezes no script).

---

## 4. Síntese: Padrões de Decisão do LLM

### 4.1 Bias observado

O LLM tem **forte viés por `cmp.lzma`** — 5 de 6 arquivos receberam essa recomendação. Este viés é parcialmente justificado:

| Condição | LZMA ganha? | Observado |
|----------|------------|-----------|
| Arquivo grande (> 100KB) | Geralmente sim | 3/3 correto |
| Arquivo médio (10-100KB) | Geralmente sim | 2/2 correto |
| Arquivo pequeno (< 10KB) | Depende | 1/2 (errou .teia_map.json) |

### 4.2 A única falha: tamanho importa

O LLM nunca usa o campo `size_bytes` do perfil para sua decisão — o prompt v0.19.5 envia `entropy`, `unique_bytes`, `size_bytes`, `structure_type`, `magic_type`. O modelo ignorou o `size_bytes = 2554` de `.teia_map.json` e aplicou o mesmo raciocínio de "LZMA para JSON" que funcionou para os arquivos grandes.

**Correção proposta (v0.19.7):** adicionar ao prompt uma regra explícita:
```
Se size_bytes < 8192 (8KB): Brotli geralmente vence para JSON/texto por dicionário estático.
Se size_bytes ≥ 8192: LZMA geralmente vence por janela deslizante longa.
```

### 4.3 Comparação: LLM vs Heurística Estática

Uma heurística determinística simples — "sempre cmp.lzma" — teria acertado 4/6 (66.7%), errando `.teia_map.json` e `TEIA-Core-v0.4.0.ps1`. O LLM acertou 5/6 (83.3%) — superou a heurística estática por 1 acerto, identificando corretamente o `cmp.brotli` para o script PS1 pequeno.

| Estratégia | Acertos | Observação |
|-----------|---------|------------|
| Sempre LZMA | 4/6 (66.7%) | Heurística estática |
| LLM qwen2.5-coder:7b | **5/6 (83.3%)** | Supera heurística estática |
| Oráculo ótimo | 6/6 (100%) | Requer execução real |

---

## 5. Anomalia de Integridade: `dna_events.jsonl` é um Log Ativo

| Momento | SHA-256 | Tamanho |
|---------|---------|---------|
| T₀ — Benchmark | `df334300c69f5eee...` | 1071.4 KB |
| T₁ — Pre-check | `df334300c69f5eee...` | 1071.4 KB |
| T₂ — NeuroPlanner | `34ec26becffa344a...` | 1071.9 KB |
| T₃ — Verificação final | `34ec26becffa344a...` | 1071.9 KB |

O arquivo cresceu ~512B entre T₁ e T₂ — um processo do ecossistema TEIA estava escrevendo nele durante o teste. Esta é a prova viva do princípio CAS: **dois snapshots do mesmo arquivo em momentos diferentes têm SHA-256 diferentes e são objetos distintos**. O candidate gravado (SHA `34ec26be...`) representa o arquivo no momento exato em que o NeuroPlanner o processou. A compressão reportada na tabela é para `df334300...` (versão T₀).

---

## 6. Verificação de Segurança

| Verificação | PRÉ | PÓS | Status |
|-------------|-----|-----|--------|
| CAS objects | 2369 | 2369 | **DELTA = 0 ✓** |
| `.teia_map.json` SHA-256 | `60C4F6188CA9DF36...` | `60C4F6188CA9DF36...` | **INALTERADO ✓** |
| Originais modificados | — | 0 | **ZERO ✓** |
| Candidates gravados | 0 | 6 | **ESPERADO ✓** |

---

## 7. Conclusão

O LLM `qwen2.5-coder:7b` como **roteador restrito** (lzma vs brotli apenas) supera a heurística estática mais simples (sempre lzma) em 83.3% vs 66.7% de acerto. A única falha documentada é estrutural: o modelo ignora `size_bytes` para calibrar a escolha, favorecendo LZMA mesmo para arquivos onde o dicionário estático do Brotli é mais eficiente.

A adição de uma regra de tamanho ao prompt ou como Hard Rule é o próximo refinamento natural (v0.19.7):

```
HR5 (proposta): size_bytes < 8192 AND structure_type == 'json' → cmp.brotli
```

Esta regra transformaria `.teia_map.json` de um erro LLM em uma decisão determinística correta — sem chamada de rede.

---

*Auditoria executada em 2026-05-27. Nenhum arquivo original modificado. CAS intacto.*
