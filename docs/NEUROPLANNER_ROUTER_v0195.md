# NEUROPLANNER — Motor Seletor Determinístico v0.19.5
**Data:** 2026-05-27  
**Script:** `TEIA-NeuroPlanner-v0195.ps1`  
**Modelo:** `qwen2.5-coder:7b` (em standby — não consultado neste dataset)  
**Dataset:** 2 arquivos sintéticos procedurais (`corpus_d1.bin`, `corpus_d2.bin`)  
**Resultado:** 2/2 decididos por Hard Rules | 0 chamadas LLM | 2/2 provas SHA-256 PASS  
**Tempo total:** 1.8s (vs 107.9s em v0.19.4)

---

## 1. Arquitetura Rule-First v0.19.5

```
                  ┌─────────────────────────────┐
   arquivo ──────►│  Get-FileStructuralProfile  │
                  └──────────────┬──────────────┘
                                 │ perfil
                  ┌──────────────▼──────────────┐
                  │    Get-StructuralMetrics     │ ← extrai first_byte_hex, period_hex
                  └──────────────┬──────────────┘
                                 │ métricas
                  ┌──────────────▼──────────────┐
                  │    Get-HardRuleDecision      │
                  │  ┌────────────────────────┐ │
                  │  │ HR1: unique_bytes==1   │─┼──► gen.repeat  (sem LLM)
                  │  │ HR2: period_bytes∈(0,512]│─┼──► gen.pattern (sem LLM)
                  │  │ HR3: entropy >= 7.0    │─┼──► cas.raw     (sem LLM)
                  │  │ HR4: magic comprimido  │─┼──► cas.raw     (sem LLM)
                  │  │ else: LLM_NEEDED       │─┼──► Invoke-OllamaPlanner
                  │  └────────────────────────┘ │       "lzma ou brotli?"
                  └──────────────┬──────────────┘
                                 │ estratégia final
                  ┌──────────────▼──────────────┐
                  │       Build-Recipe           │ ← parâmetros REAIS do perfil
                  └──────────────┬──────────────┘
                                 │ recipe
                  ┌──────────────▼──────────────┐
                  │    Test-RecipeIntegrity      │ ← SHA-256 em memória
                  └─────────────────────────────┘   (sem execução destrutiva)
```

---

## 2. Tabela de Hard Rules

| ID | Condição | Estratégia | Justificativa |
|----|----------|------------|---------------|
| HR1 | `unique_bytes == 1` | `gen.repeat` | Arquivo de byte único: compressão procedural máxima (razão ~2621× para 256KB). Parâmetro `value_hex` extraído de `header_hex[0:2]` — determinístico. |
| HR2 | `period_bytes ∈ (0, 512]` | `gen.pattern` | Padrão periódico detectado: `gen.pattern` reconstrói com seed de ~220B a partir de 256KB. `pattern_b64` extraído de `header_hex[0:period_bytes*2]`. |
| HR3 | `entropy >= 7.0` | `cas.raw` | Entropia máxima = arquivo incompressível ou já comprimido. Recompressão causaria expansão. |
| HR4 | `magic_type ∈ {zip,gzip,xz,bzip2,7z}` | `cas.raw` | Magic bytes indicam container comprimido. Confirma HR3 para estes formatos mesmo que amostragem de entropia seja incompleta. |
| — | nenhuma regra se aplica | `cmp.lzma\|cmp.brotli` | LLM consultado **apenas** para esta escolha. |

---

## 3. Resultados por Arquivo

### corpus_d1.bin — HR1 → gen.repeat

| Campo | Valor |
|-------|-------|
| SHA-256 | `83496bcb7c50d8deefa2538a3cb9733057ceabf925a4a7cd4e8a2e97695d7102` |
| Tamanho | 262144 bytes (256 KB) |
| Perfil | e=0.0000 · unique_bytes=1 · period=1B · header_hex=`aaaa...` |
| Regra aplicada | **HR1** — `unique_bytes == 1` |
| LLM consultado | **Não** |
| `first_byte_hex` extraído | `aa` (byte 0xAA — leitura direta de `header_hex[0:2]`) |

**Recipe gerada (parâmetros 100% do perfil estrutural):**
```json
{
  "op": "gen.repeat",
  "value_hex": "aa",
  "size": 262144
}
```

**Prova de integridade (sem execução destrutiva):**
```
Método   : gen.repeat(0xAA, 262144) — executado em memória PowerShell
Computado: 83496bcb7c50d8deefa2538a3cb9733057ceabf925a4a7cd4e8a2e97695d7102
Esperado : 83496bcb7c50d8deefa2538a3cb9733057ceabf925a4a7cd4e8a2e97695d7102
Resultado: PASS ✓
```

**Justificativa do Planner:** o arquivo é um bloco homogêneo de byte `0xAA` repetido 262144 vezes. A regra HR1 (`unique_bytes == 1`) dispara sem ambiguidade. O `value_hex` não pode ser inventado pelo LLM — é extraído diretamente de `header_hex[0:2]` pelo `Get-StructuralMetrics`. A recipe de ~35 bytes reconstrói um arquivo de 256KB: razão de compressão procedural de 2621×.

---

### corpus_d2.bin — HR2 → gen.pattern

| Campo | Valor |
|-------|-------|
| SHA-256 | `d4b9f61285c5d13cfad6d3c3a455597efd4ae2d50b011fdb8b58f6f7be4d455e` |
| Tamanho | 262144 bytes (256 KB) |
| Perfil | e=4.0000 · unique_bytes=16 · period=16B · header_hex=`4142...4f50...` |
| Regra aplicada | **HR2** — `period_bytes=16 ∈ (0, 512]` |
| LLM consultado | **Não** |
| `period_hex` extraído | `4142434445464748494a4b4c4d4e4f50` → `ABCDEFGHIJKLMNOP` |

**Recipe gerada (parâmetros 100% do perfil estrutural):**
```json
{
  "op": "gen.pattern",
  "pattern_b64": "QUJDREVGR0hJSktMTU5PUA==",
  "pattern_hex": "4142434445464748494a4b4c4d4e4f50",
  "repeat": 16384,
  "period_bytes": 16
}
```

**Decodificação do pattern_b64:**
```
QUJDREVGR0hJSktMTU5PUA== → 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F 50
                          →  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P
```

**Prova de integridade (sem execução destrutiva):**
```
Método   : gen.pattern(period=16B, repeat=16384) — executado em memória PowerShell
Computado: d4b9f61285c5d13cfad6d3c3a455597efd4ae2d50b011fdb8b58f6f7be4d455e
Esperado : d4b9f61285c5d13cfad6d3c3a455597efd4ae2d50b011fdb8b58f6f7be4d455e
Resultado: PASS ✓
```

**Justificativa do Planner:** o arquivo é o padrão `ABCDEFGHIJKLMNOP` repetido 16384 vezes. A regra HR2 dispara porque `Find-Period` detecta período de 16 bytes em todo o arquivo. O `pattern_b64` é extraído de `header_hex[0:32]` (16B × 2 hex chars). O LLM não é chamado — esta é exatamente a patologia que causou falha tripla em v0.19.3 (LLM escolheu `gen.repeat` com `value_hex:00` e `size:1048576`). Com HR2, o erro é estruturalmente impossível.

---

## 4. Comparativo entre Versões

| Dimensão | v0.19.3 (LLM full) | v0.19.4 (LLM roteador) | v0.19.5 (Rule-First) |
|----------|-------------------|------------------------|----------------------|
| D1 value_hex | `00` (errado) | `aa` (correto) | `aa` (correto) |
| D2 strategy | `gen.repeat` (errado) | `cmp.lzma` (sub-ótimo) | `gen.pattern` (correto) |
| D1 Regra de Ouro | **FAIL** | **PASS** | **PASS** |
| D2 Regra de Ouro | **FAIL** | *(não verificável — lzma)* | **PASS** |
| Tempo de execução | ~107.9s | ~107.9s | **1.8s** |
| Chamadas LLM (D1+D2) | 2 | 2 | **0** |
| Alucinação possível | sim | mitigada | **impossível (HR1/HR2)** |

---

## 5. Escopo do LLM em v0.19.5

O LLM é consultado **apenas** quando nenhuma das 4 hard rules se aplica:

```
entropy ∈ [2.0, 7.0) AND period_bytes == 0 AND unique_bytes > 1
                     AND magic_type NOT IN compressed_types
```

Neste caso, o arquivo é "compressível por algoritmo estatístico" e a pergunta ao LLM é restrita a:

> "Dado este perfil (entropy, structure_type, magic_type), LZMA ou Brotli?"

O LLM não pode inventar `value_hex`, `size`, `pattern_b64` ou `repeat` — esses campos nunca aparecem no contexto que o LLM recebe. Qualquer estratégia fora de `cmp.lzma` / `cmp.brotli` é descartada com fallback `cmp.lzma`.

**Exemplos de arquivos que ativariam o LLM:**

| Arquivo | e | period | Estrutura | LLM chamado? |
|---------|---|--------|-----------|--------------|
| `.teia_map.json` | 5.29 | 0 | json | **Sim** — lzma vs brotli |
| `TEIA-Core-v0.4.0.ps1` | 5.24 | 0 | text | **Sim** — lzma vs brotli |
| `dna_events.jsonl` | 5.40 | 0 | text | **Sim** — lzma vs brotli |
| `corpus_d1.bin` | 0.00 | 1 | text | **Não** — HR1 |
| `corpus_d2.bin` | 4.00 | 16 | text | **Não** — HR2 |
| `TEIA_PROVA_v12.zip` | 7.99 | 0 | binary | **Não** — HR3+HR4 |

---

## 6. Verificação de Integridade Pós-Execução

| Verificação | PRÉ | PÓS | Status |
|-------------|-----|-----|--------|
| CAS objects (`objects/*.bin`) | 2369 | 2369 | **DELTA = 0 ✓** |
| `.teia_map.json` SHA-256 | `60C4F6188CA9DF36...` | `60C4F6188CA9DF36...` | **INALTERADO ✓** |
| `corpus_d1.bin` SHA-256 | `83496bcb...` | `83496bcb...` | **INTACTO ✓** |
| `corpus_d2.bin` SHA-256 | `d4b9f612...` | `d4b9f612...` | **INTACTO ✓** |
| Candidates gravados | 0 (pré-limpeza) | 2 | **ESPERADO ✓** |

---

## 7. Próximos Passos

1. **Exercitar o branch LLM** — rodar v0.19.5 sobre `fractal_index.json`, `TEIA-Core-v0.4.0.ps1`, `dna_events.jsonl` para validar o caminho lzma vs brotli com o modelo restrito.
2. **Integrar ao Executor** — candidates com `integrity_proof.pass == true` estão prontos para ser executados pelo UVM v0.4 sem re-validação.
3. **Estender HR2 para períodos > 512B** — arquivos com padrão periódico longo (até 4KB) podem se beneficiar de `gen.pattern`; o limite atual de 512B é conservador.

---

*Run executado em 2026-05-27. 0 chamadas LLM. 0 arquivos modificados. 2 provas SHA-256 PASS.*
