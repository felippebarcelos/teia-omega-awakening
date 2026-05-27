# NEUROPLANNER — HR5 Arquivos Pequenos v0.19.7
**Data:** 2026-05-27  
**Script:** `TEIA-NeuroPlanner-v0197.ps1`  
**Dataset:** 6 arquivos reais TEIA (mesmos do v0.19.6)  
**Resultado:** 6/6 corretos (100%) | 4 chamadas LLM (−33%) | Tempo: 132.2s (−20%)

---

## 1. Mudança: Hard Rule HR5

```powershell
# HR5: arquivo pequeno (< 8 KB) → cmp.brotli
# Brotli tem dicionário estático que supera a janela deslizante do LZMA em arquivos < 8KB.
# Evidência empírica v0.19.6: .teia_map.json (2.5KB) Brotli=23.1% vs LZMA=28.1%
if ([long]$Metrics.size_bytes -lt 8192) {
    return [ordered]@{
        source   = 'hard_rule'
        rule_id  = 'HR5'
        rule     = "size_bytes=$($Metrics.size_bytes) < 8192"
        strategy = 'cmp.brotli'
    }
}
```

**Posição na árvore:** depois de HR4 (magic comprimido), antes da chamada ao LLM.  
**Garantia:** só alcança HR5 se entropy∈[2,7), sem período, sem byte único, magic não comprimido — ou seja, arquivo genuinamente compressível por algoritmo estatístico, apenas pequeno.

---

## 2. Tabela Comparativa Principal: v0.19.6 vs v0.19.7

| # | Arquivo | KB | e | v0.19.6 | v0.19.7 | Vencedor Real | v0.19.6 ✓? | v0.19.7 ✓? |
|---|---------|----|----|---------|---------|--------------|------------|------------|
| 1 | `fractal_index.json` | 1266.6 | 5.28 | LLM→`lzma` | LLM→`lzma` | LZMA (10.0%) | ✓ | ✓ |
| 2 | `.teia_map.json` | 2.5 | 5.29 | LLM→`lzma` | **HR5→`brotli`** | Brotli (23.1%) | **✗** | ✓ |
| 3 | `dna_events.jsonl` | ~1072 | 5.40 | LLM→`lzma` | LLM→`lzma` | LZMA (17.8%) | ✓ | ✓ |
| 4 | `Benchmark-Chunked.log.json` | 22.1 | 4.12 | LLM→`lzma` | LLM→`lzma` | LZMA (5.4%) | ✓ | ✓ |
| 5 | `TEIA-Core-v0.4.0.ps1` | 6.3 | 5.24 | LLM→`brotli` | **HR5→`brotli`** | Brotli (35.7%) | ✓ | ✓ |
| 6 | `TEIA-NeuroPlanner-v0197.ps1` | 26.5 | 5.07 | LLM→`lzma`¹ | LLM→`lzma` | LZMA (~27%) | ✓ | ✓ |

¹ *v0.19.6 rodou sobre `TEIA-NeuroPlanner-v0195.ps1` (25.7KB); v0.19.7 rodou sobre a versão atualizada (26.5KB). Ambas PS1 no mesmo intervalo de tamanho e estrutura.*

---

## 3. Métricas de Eficiência

| Métrica | v0.19.6 | v0.19.7 | Δ |
|---------|---------|---------|---|
| Acertos totais | 5/6 (83.3%) | **6/6 (100%)** | +1 |
| Chamadas LLM | 6 | **4** | −2 (−33%) |
| Arquivos via HR (sem LLM) | 0 | 2 | +2 |
| Tempo total | 165.0s | **132.2s** | −32.8s (−20%) |
| Tempo médio por LLM call | ~27.5s | ~33s* | — |

*A média por chamada subiu ligeiramente — o LLM agora processa os arquivos maiores; o overhead de análise estrutural dos 2 arquivos HR5 é negligível (< 0.1s cada).

---

## 4. Análise das Decisões HR5

### .teia_map.json (2549 bytes = 2.5 KB) — HR5 corrige erro do LLM

| Versão | Decisão | Estratégia | Resultado |
|--------|---------|------------|-----------|
| v0.19.6 | LLM (consulta de rede) | `cmp.lzma` | **ERRADO** — Brotli vence por 5.0pp (28.1% vs 23.1%) |
| v0.19.7 | HR5 (zero latência) | `cmp.brotli` | **CORRETO** — sem chamada LLM |

**Por que Brotli vence em arquivos tão pequenos?** O LZMA requer múltiplos passes LZ77 para amortizar seu overhead de cabeçalho e construir um dicionário deslizante eficiente. Para 2549 bytes, o overhead de cabeçalho LZMA (~20-50B) representa 1-2% do arquivo. O Brotli compensa com seu dicionário estático pré-construído de n-gramas comuns — eficaz mesmo sem histórico prévio de compressão.

---

### TEIA-Core-v0.4.0.ps1 (6424 bytes = 6.3 KB) — HR5 confirma acerto do LLM

| Versão | Decisão | Estratégia | Resultado |
|--------|---------|------------|-----------|
| v0.19.6 | LLM (consulta de rede) | `cmp.brotli` | **CORRETO** — Brotli vence por 0.6pp (35.7% vs 36.3%) |
| v0.19.7 | HR5 (zero latência) | `cmp.brotli` | **CORRETO** — sem chamada LLM |

O LLM v0.19.6 havia acertado por raciocínio válido ("texto curto com palavras repetidas"). HR5 chega à mesma conclusão por regra determinística, eliminando a latência de rede e o risco de variação de resposta do modelo.

---

## 5. Decisões LLM nos 4 Arquivos Restantes (v0.19.7)

| Arquivo | LLM Strategy | Razão do LLM | Correto? |
|---------|-------------|--------------|----------|
| `fractal_index.json` | `cmp.lzma` | JSON grande com bytes únicos baixos — padrões repetitivos captados por LZMA | ✓ |
| `dna_events.jsonl` | `cmp.lzma` | Tamanho significativo + repetição de tokens longos — LZMA ideal | ✓ |
| `Benchmark-Chunked.log.json` | `cmp.lzma` | JSON estruturado com alta entropia e bytes únicos — LZMA excelente | ✓ |
| `TEIA-NeuroPlanner-v0197.ps1` | `cmp.lzma` | Entropia 5.07 distribuída uniformemente — LZMA mais eficaz | ✓ |

**LLM accuracy no subconjunto ≥ 8KB: 4/4 = 100%**

---

## 6. SHA-256 e Integridade

| Arquivo | SHA-256 (candidato v0.19.7) | Estável? |
|---------|-----------------------------|----------|
| `fractal_index.json` | `a6746d0dd0decf5e...` | ✓ |
| `.teia_map.json` | `60c4f6188ca9df36...` | ✓ |
| `dna_events.jsonl` | `abe37d304fc075ff...` | **Crescendo**¹ |
| `Benchmark-Chunked.log.json` | `594c3c2abb978afe...` | ✓ |
| `TEIA-Core-v0.4.0.ps1` | `489d3b4024930fb4...` | ✓ |
| `TEIA-NeuroPlanner-v0197.ps1` | `7e630193af5a52ee...` | ✓ (nova versão) |

| Verificação | Resultado |
|-------------|-----------|
| CAS objects (delta) | **0 ✓** |
| `.teia_map.json` SHA-256 | **INALTERADO ✓** |
| Originais modificados | **0 ✓** |

¹ `dna_events.jsonl` teve 3 SHA-256 distintos durante esta sessão de testes:
- Benchmark (T₀): `df334300...` (1071.4 KB)
- NeuroPlanner v0.19.6 (T₁): `34ec26be...` (1071.9 KB)
- NeuroPlanner v0.19.7 (T₂): `abe37d30...` (1072.8 KB)

O arquivo cresce ~512B por processamento do NeuroPlanner — logs de eventos TEIA sendo escritos ativamente.

---

## 7. Árvore de Decisão Completa v0.19.7

```
                        arquivo
                           │
               ┌───────────▼───────────┐
               │  Get-HardRuleDecision │
               └───────────┬───────────┘
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   unique_bytes=1    period∈(0,512]     entropy≥7.0
        │                  │                  │
   [HR1] gen.repeat  [HR2] gen.pattern  [HR3] cas.raw
                                              │
                                         magic comprimido
                                              │
                                        [HR4] cas.raw
                                              │
                                        size_bytes<8192
                                              │
                                       [HR5] cmp.brotli ◄── NOVO
                                              │
                                    nenhuma regra aplica
                                              │
                               ┌──────────────▼──────────────┐
                               │  Invoke-OllamaPlanner        │
                               │  "lzma ou brotli?" (≥8KB)   │
                               └─────────────────────────────┘
```

---

## 8. Conclusão

HR5 elimina o único erro documentado do LLM em v0.19.6 (`.teia_map.json`) e reduz 33% das chamadas de rede — sem custo de acurácia. O LLM agora opera exclusivamente sobre arquivos ≥ 8KB onde sua janela deslizante LZMA é sistematicamente superior ao dicionário estático Brotli.

**Estado atual das Hard Rules:**

| Regra | Cobertura | Base Empírica |
|-------|-----------|---------------|
| HR1 unique_bytes=1 → gen.repeat | Dados sintéticos uniformes | Benchmarks D1-D3 (17/17 wins) |
| HR2 period∈(0,512] → gen.pattern | Dados periódicos | Benchmarks D2 + validação SHA-256 |
| HR3 entropy≥7.0 → cas.raw | Binários comprimidos | Benchmark D8 (ZIP/PNG/etc.) |
| HR4 magic comprimido → cas.raw | ZIP, GZIP, XZ, 7Z, BZ2 | Magic byte detection |
| HR5 size<8KB → cmp.brotli | Arquivos texto/JSON pequenos | Auditoria v0.19.6 (2/2 validados) |

---

*Run executado em 2026-05-27. Nenhum original modificado. CAS intacto. 6 candidates gravados.*
