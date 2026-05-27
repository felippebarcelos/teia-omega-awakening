# NEUROPLANNER — Piloto LLM Candidatos Procedurais v0.19.3
**Data:** 2026-05-27  
**Script:** `TEIA-NeuroPlanner-v0190.ps1` (sem `-DryRun`)  
**Modelo:** `qwen2.5-coder:7b` (4.7 GB)  
**Endpoint:** `http://localhost:11434/api/generate`  
**Dataset:** 2 arquivos sintéticos procedurais (`corpus_d1.bin`, `corpus_d2.bin`)  
**Resultado:** 2/2 classificados `PROCEDURAL_CANDIDATE` | 2 recipes geradas | **0 recipes válidas pela Regra de Ouro**

---

## 1. Dataset — Candidatos Procedurais Sintéticos

| Arquivo | SHA-256 | Tamanho | Conteúdo | Entropia | Período | Classificação Estrutural |
|---------|---------|---------|----------|----------|---------|--------------------------|
| `corpus_d1.bin` | `83496bcb...` | 256 KB | `0xAA` × 262144 | 0.0000 | 1B | PROCEDURAL_CANDIDATE |
| `corpus_d2.bin` | `d4b9f612...` | 256 KB | `ABCDEFGHIJKLMNOP` × 16384 | 4.0000 | 16B | PROCEDURAL_CANDIDATE |

---

## 2. Tabela de Resultados

| Arquivo | Modelo | Estratégia Proposta | Recipe Executável pela UVM? | Regra de Ouro | Verdict |
|---------|--------|---------------------|----------------------------|---------------|---------|
| `corpus_d1.bin` | qwen2.5-coder:7b | `gen.repeat` | JSON bem-formado, **valor errado** | **FAIL** | `PROCEDURAL_CANDIDATE` |
| `corpus_d2.bin` | qwen2.5-coder:7b | `gen.repeat` | **Estratégia, valor e tamanho errados** | **FAIL** | `PROCEDURAL_CANDIDATE` |

---

## 3. Timing

| Evento | Horário | Δ |
|--------|---------|---|
| Início do run | ~16:36:35 | — |
| D1 candidate gravado | 16:38:05 | ~90s |
| D2 candidate gravado | 16:39:10 | +65s |
| **Total** | | **~155s** |

Ambas as inferências completaram dentro do timeout de 180s. `qwen2.5-coder:7b` (4.7GB) é viável no hardware i3-10100F / 8GB RAM.

---

## 4. Análise Detalhada por Arquivo

### 4.1 corpus_d1.bin — `gen.repeat` com byte errado

#### Perfil estrutural (entrado no prompt LLM):
```json
{
  "entropy": 0.0,
  "unique_bytes": 1,
  "period_bytes": 1,
  "header_hex": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "runs": { "runs": 1, "avgRunLen": 262144.0, "maxRun": 262144 },
  "strings_sample": null
}
```

#### LLM response (raw):
```json
{
  "candidate": true,
  "reason": "Arquivo é composto por um único byte repetido (0x00). O opcode gen.repeat é apropriado e verificável por SHA-256.",
  "proposed_strategy": "gen.repeat",
  "recipe": {
    "op": "gen.repeat",
    "value_hex": "00",
    "size": 262144
  },
  "risk": "low"
}
```

#### Avaliação de executabilidade (UVM v0.4):

| Dimensão | Proposto | Correto | OK? |
|----------|----------|---------|-----|
| `op` | `gen.repeat` | `gen.repeat` | ✓ |
| `size` | 262144 | 262144 | ✓ |
| `value_hex` | `"00"` | `"aa"` | **✗** |

**Diagnóstico:**  
O LLM identificou corretamente a estratégia (`gen.repeat`) e o tamanho (262144). Porém declarou o byte como `0x00` na `reason` ("0x00") e na recipe. O `header_hex` fornecido no perfil contém `"aaaa..."` — cada par `aa` representa o byte `0xAA` (170 decimal). O modelo ignorou esta evidência direta e assumiu `0x00` como byte "neutro".

**Regra de Ouro:**  
`gen.repeat(0x00, 262144)` produz SHA-256 = `076a27c79e5ace2a3d47f9dd2e83e4ff6ea8872b3d2218fde054f33bd69fbfb0` (arquivo de zeros).  
SHA-256 esperado = `83496bcb7c50d8deefa2538a3cb9733057ceabf925a4a7cd4e8a2e97695d7102` (arquivo de `0xAA`).  
**Divergência → recipe DESCARTADA.**

---

### 4.2 corpus_d2.bin — Recipe completamente inválida

#### Perfil estrutural (entrado no prompt LLM):
```json
{
  "entropy": 4.0,
  "unique_bytes": 16,
  "period_bytes": 16,
  "header_hex": "4142434445464748494a4b4c4d4e4f504142434445464748494a4b4c4d4e4f50",
  "runs": { "runs": 262144, "avgRunLen": 1.0, "maxRun": 1 },
  "strings_sample": "<ABCDEFGHIJKLMNOP × 16384 — string de 262144 chars>"
}
```

⚠️ **`strings_sample` continha o arquivo inteiro** (262144 bytes printáveis como ASCII) → candidate JSON com 67101 bytes.

#### LLM response (raw):
```json
{
  "candidate": true,
  "reason": "O arquivo tem um único byte repetido, que é considerado seguro devido à baixa entropia. O padrão de compressão LZMA é adequado e verificável por SHA-256, garantindo integridade dos dados. A ausência de chaves duplicadas também adiciona segurança ao arquivo. Portanto, o perfil está estritamente correto.",
  "proposed_strategy": "gen.repeat",
  "recipe": {
    "op": "gen.repeat",
    "value_hex": "00",
    "size": 1048576
  },
  "risk": "low"
}
```

#### Avaliação de executabilidade (UVM v0.4):

| Dimensão | Proposto | Correto | OK? |
|----------|----------|---------|-----|
| `op` | `gen.repeat` | `gen.pattern` | **✗** |
| `value_hex` | `"00"` | *(padrão 16B)* | **✗** |
| `size` | 1048576 | 262144 | **✗ (4×)** |

**Diagnóstico:**  
Falha tripla. O LLM:
1. Escolheu `gen.repeat` em vez de `gen.pattern` — o arquivo tem 16 bytes únicos em período de 16B, não um único byte.
2. Declarou `"O arquivo tem um único byte repetido"` — propriedade do D1, não do D2. Confusão de arquivos ou alucinação.
3. Reportou `size: 1048576` (1MB) em vez de 262144 (256KB) — 4× acima do real.

**Causa provável — context flooding:**  
O campo `strings_sample` injetou 262144 caracteres de `ABCDEFGHIJKLMNOP` repetido no prompt LLM. Este volume de texto repetitivo (equivalente a ~500 linhas de token de 500 chars) provavelmente:
- Consumiu a janela de atenção do modelo antes dos campos estruturais críticos (`period_bytes`, `unique_bytes`)
- Levou o modelo a "ver" apenas a repetição e inferir erroneamente `gen.repeat`
- Confundiu o raciocínio sobre tamanho (1048576 = 262144 × 4 — talvez contagem de repetições? intera de caracteres por período?)

**Regra de Ouro:**  
`gen.repeat(0x00, 1048576)` produz um arquivo 4× maior e de byte zero.  
SHA-256 esperado = `d4b9f61285c5d13cfad6d3c3a455597efd4ae2d50b011fdb8b58f6f7be4d455e`.  
**Divergência absoluta → recipe DESCARTADA.**

---

## 5. Bugs Identificados

### Bug 5 — `strings_sample` não limitada para binários printáveis

**Sintoma:** `corpus_d2.bin` é composto por bytes 0x41–0x50 (ASCII printável). `Get-IsText` retorna `$true`. `Get-StringsSample` extrai o arquivo inteiro como uma string de 262144 caracteres. O candidate JSON resultante tem 67101 bytes.

**Consequência:** o campo `strings_sample` injeta o arquivo inteiro no prompt LLM, causando context flooding e alucinação das properties estruturais.

**Correção proposta (v0.19.4):**
```powershell
# Em Get-StringsSample, após extrair as strings:
$joined = ($strings | Select-Object -First 5) -join ' | '
if ($joined.Length -gt 512) { $joined = $joined.Substring(0, 512) + '...[truncado]' }
return $joined
```
Ou, alternativamente, limitar o campo `sample_bytes` a 4096 bytes antes de qualquer extração de strings.

---

### Bug 6 — LLM não lê `header_hex` para extrair `value_hex`

**Sintoma:** Para D1, `header_hex = "aaaa..."` (byte `0xAA`). LLM retornou `value_hex: "00"`.

**Causa:** O prompt canônico não instrui explicitamente o LLM sobre como extrair o byte de repetição do `header_hex`.

**Correção proposta no prompt (v0.19.4):**

```markdown
## Extração de parâmetros

- Para `gen.repeat`: o byte repetido é os DOIS PRIMEIROS CARACTERES de `header_hex`.
  Exemplo: `header_hex = "aaaaaa..."` → `value_hex = "aa"` (byte 0xAA).
  NUNCA assuma 0x00 como padrão.

- Para `gen.pattern`: o padrão é os primeiros `period_bytes × 2` caracteres de `header_hex`.
  Exemplo: `period_bytes = 16, header_hex = "4142...4f50..."` → `pattern_b64 = base64(bytes 0x41..0x50)`.
```

---

### Bug 7 — LLM usa `gen.repeat` quando `period_bytes > 1`

**Sintoma:** D2 tem `unique_bytes=16`, `period_bytes=16` — deveria usar `gen.pattern`. LLM usou `gen.repeat`.

**Correção proposta no prompt (v0.19.4):**

```markdown
## Regra de escolha de opcode

| Condição | Opcode |
|----------|--------|
| unique_bytes == 1 AND period_bytes == 1 | gen.repeat |
| unique_bytes > 1 AND period_bytes > 1 AND period_bytes <= 64 | gen.pattern |
| period_bytes == 0 AND entropy < 7.0 | cmp.lzma |
| entropy >= 7.0 | cas.raw |
```

---

## 6. Verificação de Integridade Pós-Execução

| Verificação | PRÉ | PÓS | Status |
|-------------|-----|-----|--------|
| CAS objects (`objects/*.bin`) | 2369 | 2369 | **DELTA = 0 ✓** |
| `.teia_map.json` SHA-256 | `60C4F6188CA9DF36...` | `60C4F6188CA9DF36...` | **INALTERADO ✓** |
| `.teia_map.json` LastWrite | 2026-05-26 14:14:14 | 2026-05-26 14:14:14 | **INALTERADO ✓** |
| `corpus_d1.bin` SHA-256 | `83496BCB7C50D8DE...` | `83496BCB7C50D8DE...` | **INTACTO ✓** |
| `corpus_d2.bin` SHA-256 | `D4B9F61285C5D13C...` | `D4B9F61285C5D13C...` | **INTACTO ✓** |
| Candidates gravados | 2 (pré-existentes v0.19.2) | +2 (v0.19.3) | **ESPERADO ✓** |
| Arquivos criados fora de `candidates/` | 0 | 0 | **ZERO ✓** |

**Conclusão de segurança:** CAS não modificado. Originais intactos. Únicos novos artefatos são os dois `.candidate.json` em `neuroplanner/candidates/`.

---

## 7. Candidates Gravados

### `83496bcb...candidate.json` (1374 B)
- Arquivo: `corpus_d1.bin`
- LLM response: `{ candidate: true, op: gen.repeat, value_hex: "00", size: 262144 }`
- Verdict: `PROCEDURAL_CANDIDATE`
- Recipe válida para Executor: **NÃO** — `value_hex` errado (`aa` esperado, `00` fornecido)

### `d4b9f612...candidate.json` (67101 B — anomalia de tamanho)
- Arquivo: `corpus_d2.bin`
- LLM response: `{ candidate: true, op: gen.repeat, value_hex: "00", size: 1048576 }`
- Verdict: `PROCEDURAL_CANDIDATE`
- Recipe válida para Executor: **NÃO** — estratégia, valor e tamanho todos errados
- Causa do tamanho: `strings_sample` com 262144 chars (arquivo inteiro como texto ASCII)

---

## 8. Avaliação Arquitetural

### O Planner funciona? Análise honesta

| Aspecto | Resultado | Interpretação |
|---------|-----------|---------------|
| Classificação estrutural (sem LLM) | PROCEDURAL_CANDIDATE ✓ | Classificador estrutural **perfeito** |
| LLM identifica estratégia correta | D1: ✓ / D2: ✗ | 50% de acerto de estratégia |
| LLM lê parâmetros do perfil | ✗ / ✗ | **0%** — não extrai `value_hex` de `header_hex` |
| Recipe passa Regra de Ouro | ✗ / ✗ | **0%** — nenhuma recipe restaura o SHA-256 original |
| Timeout (180s com qwen2.5-coder:7b) | Não | Hardware é adequado para este modelo |

**Conclusão:** a arquitetura Planner/Executor está correta. O gap está na camada de prompt engineering: o LLM sabe que a estratégia existe, mas não consegue extrair os parâmetros corretos do perfil estrutural sem instrução explícita.

---

## 9. Próximos Passos (v0.19.4)

1. **Limitar `strings_sample`** a máx. 512 chars ou 5 primeiras strings extraídas — eliminar context flooding.
2. **Atualizar prompt canônico** com:
   - Tabela de escolha de opcode (`unique_bytes == 1 → gen.repeat`, `period_bytes > 1 → gen.pattern`)
   - Instrução explícita de extração de `value_hex` de `header_hex[0:2]`
   - Instrução explícita de `pattern_b64` de `header_hex[0 : period_bytes*2]`
3. **Alterar modelo padrão** do script para `qwen2.5-coder:7b` (instalado, adequado ao hardware, 7B parâmetros; `deepseek-r1:1.5b` agora também instalado como alternativa mais leve).
4. **Re-executar piloto v0.19.4** nos mesmos dois arquivos para validar que as correções de prompt permitem extração correta de parâmetros.

---

*Piloto executado em 2026-05-27. Nenhum arquivo de origem foi modificado. Nenhuma recipe foi executada pelo Executor.*
