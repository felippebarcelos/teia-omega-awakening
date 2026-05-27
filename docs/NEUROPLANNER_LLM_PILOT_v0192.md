# NEUROPLANNER — Piloto LLM Read-Only v0.19.2
**Data:** 2026-05-27  
**Script:** `TEIA-NeuroPlanner-v0190.ps1` (sem `-DryRun`)  
**Modelo:** `deepseek-r1:14b` (9 GB — `deepseek-r1:1.5b` não instalado)  
**Endpoint:** `http://localhost:11434/api/generate`  
**Dataset:** 2 arquivos (piloto v0.14.1)  
**Resultado:** 2 candidates gravados | 1 resposta LLM vazia | 1 timeout LLM

---

## 1. Auditoria de Ambiente (LLM)

### Modelos Ollama disponíveis

| Modelo | Tamanho | Status |
|--------|---------|--------|
| `teia-supra-sensei:latest` | 9.0 GB | Disponível (modelo customizado TEIA) |
| `deepseek-r1:14b` | 9.0 GB | **Usado neste piloto** |
| `qwen2.5-coder:7b` | 4.7 GB | Disponível (alternativa mais rápida) |
| `deepseek-r1:1.5b` | — | **NÃO INSTALADO** (padrão do script) |

**Ação tomada:** substituição do modelo padrão (`deepseek-r1:1.5b`) por `deepseek-r1:14b` via parâmetro `-Model`.

### Arquivos piloto localizados

| Arquivo | Tamanho | Caminho |
|---------|---------|---------|
| `piloto_nota.txt` | 125 B | `D:\TEIA_USER\Inbox\piloto_nota.txt` |
| `piloto_notas.md` | 231 B | `D:\TEIA_USER\Inbox\piloto_notas.md` |

---

## 2. Tabela de Resultados do Piloto LLM

| Arquivo | Modelo | Estratégia Proposta | Risco | JSON Válido? | Verdict |
|---------|--------|---------------------|-------|--------------|---------|
| `piloto_nota.txt` | deepseek-r1:14b | *(ausente — LLM retornou `{}`)* | N/A | `{}` — vazio | `CAS_RAW`¹ |
| `piloto_notas.md` | deepseek-r1:14b | `fallback: cas.raw` | `high` | Gerado por handler de erro | `CAS_RAW` |

¹ *Corrigido retroativamente pela análise humana — ver seção 4. O script v0.19.1 classificou erroneamente como `PROCEDURAL_CANDIDATE` devido ao bug `Get-PlannerVerdict`; corrigido em v0.19.2.*

---

## 3. Perfis Estruturais Observados

### piloto_nota.txt

```
SHA-256        : a6dc9992042636ebdff0d9fb52cb8f67dc872cd95ce6297a56f0d83ab736bfb0
Tamanho        : 125 bytes
Entropia       : 4.9073 bits/byte
Bytes únicos   : 40 / 256
Período        : nenhum
Runs           : 125 runs · maxRun=1B · avgRun=1.0B
Estrutura      : text
Header hex     : 5445494120... ("TEIA Piloto v0.14...")
Strings sample : ["TEIA Piloto v0.14.1",
                   "Arquivo de texto simples para teste de ingestao.",
                   "Data: 2026-05-26 12:05:40",
                   "Conteudo: hash-me-if-you-can"]
```

**Conteúdo real:**
```
TEIA Piloto v0.14.1
Arquivo de texto simples para teste de ingestao.
Data: 2026-05-26 12:05:40
Conteudo: hash-me-if-you-can
```

---

### piloto_notas.md

```
SHA-256        : 21c20b1527a00958a52ac8c7bb6c6f3239089e5523822bd72d4a43ece859fbf3
Tamanho        : 231 bytes
Entropia       : 4.7341 bits/byte
Bytes únicos   : 43 / 256
Período        : nenhum
Runs           : 226 runs · maxRun=2B · avgRun=1.0B
Estrutura      : text
Header hex     : 23204e6f746173... ("# Notas do Piloto...")
Strings sample : ["# Notas do Piloto TEIA v0.14.1", "## Objetivo",
                   "Validar ingestao, quarentena e restauracao via CAS.",
                   "## Arquivos", "- piloto_nota.txt", ...]
```

**Conteúdo real:** arquivo Markdown com 9 linhas descrevendo o piloto v0.14.1.

---

## 4. Análise Humana (Claude) — A Proposta Faz Sentido?

### 4.1 Avaliação estrutural independente

Antes de analisar a resposta do LLM, o perfil estrutural por si só já determina a classificação correta:

| Critério | piloto_nota.txt | piloto_notas.md |
|----------|-----------------|-----------------|
| Byte único | Não (40 únicos) | Não (43 únicos) |
| Período detectado | Não | Não |
| Entropia | 4.91 — zona LZMA | 4.73 — zona LZMA |
| Runs úteis para RLE | 125 runs de 1B — nenhum | 226 runs de 1–2B — nenhum |
| Tamanho | 125 B — mínimo | 231 B — mínimo |

**Classificação estrutural correta:** ambos os arquivos são `LZMA_PREFERRED` pelo Planner estrutural. Não há evidência de qualquer padrão procedural. A entropia de 4.7–4.9 indica texto UTF-8 natural sem repetição sistemática.

**Observação crítica de escala:** com 125 e 231 bytes, ambos os arquivos são tão pequenos que:
- `cmp.lzma`: overhead do cabeçalho LZMA (~20–50 bytes) pode cancelar o ganho de compressão
- Seed procedural: qualquer recipe que referenciasse os 40–43 bytes únicos seria mais longa que o arquivo original
- `cas.raw`: armazenamento integral é a opção mais honesta para arquivos desta escala

**Veredicto humano independente:** `CAS_RAW` para ambos, pela combinação de entropia moderada + tamanho mínimo + ausência de padrão. A Entropy Honesty do sistema não requer `entropy ≥ 7.0` para arquivos tão pequenos — o `estimated_seed_bytes ≥ size_bytes` descarta qualquer recipe procedural imediatamente.

---

### 4.2 O que o LLM retornou e por quê

#### piloto_nota.txt → `{}` (objeto JSON vazio)

O `deepseek-r1:14b` retornou um objeto JSON vazio para o primeiro arquivo. Causas prováveis:

1. **Arquitetura DeepSeek-R1 com reasoning tokens:** os modelos R1 geram cadeia de raciocínio em tags `<think>...</think>` antes da resposta final. Com `format: json` no Ollama, a plataforma extrai apenas o JSON final. Se o modelo completou o raciocínio mas não emitiu JSON válido no bloco final, Ollama retorna `{}`.

2. **Prompt markdown-pesado:** o prompt canônico de 80+ linhas em markdown pode confundir a etapa de extração JSON do Ollama para modelos de reasoning que misturam texto e JSON na saída.

3. **Arquivo muito pequeno:** o perfil de 125 bytes com strings legíveis pode ter levado o modelo a tentar uma abordagem de template literal em vez de um opcode do vocabulário — falhando ao mapear para o schema JSON obrigatório.

**A proposta é executável pelo motor v0.16?** Não — `{}` não é uma recipe válida. Não contém `op`, `params`, ou `sha256`. O Executor rejeitaria esta entrada na validação de schema.

**É mais eficiente que LZMA?** Não se aplica — a proposta é inválida.

---

#### piloto_notas.md → timeout (180s esgotado)

O `deepseek-r1:14b` não completou a inferência em 180 segundos para o segundo arquivo. Causas:

1. **Modelo de 9 GB em hardware i3-10100F / 8 GB RAM:** a inferência de um modelo de 14B parâmetros em CPU é lenta. O hardware do operador (i3-10100F, 8 GB RAM) claramente não comporta `deepseek-r1:14b` dentro do timeout de 180s.

2. **Sem GPU:** o deepseek-r1:14b requer VRAM ou muito tempo de CPU. Sem GPU dedicada, 180s é insuficiente para inferência completa.

**A proposta é executável?** Não — não foi gerada.

**Verdict correto pelo handler de erro:** `fallback: cas.raw` com `risk: high` — comportamento defensivo correto.

---

### 4.3 Modelo recomendado para o hardware atual

| Modelo | VRAM/RAM requerida | Velocidade estimada (CPU) | Adequado? |
|--------|-------------------|--------------------------|-----------|
| `deepseek-r1:1.5b` | ~2 GB | ~20–40s/inferência | **Sim** (instalar) |
| `qwen2.5-coder:7b` | ~5 GB | ~60–90s/inferência | **Sim** (já instalado) |
| `deepseek-r1:14b` | ~9 GB | >180s/inferência | **Não** para este hardware |
| `teia-supra-sensei:latest` | ~9 GB | >180s/inferência | **Não** para este hardware |

**Recomendação imediata:** usar `qwen2.5-coder:7b` como modelo padrão até que `deepseek-r1:1.5b` seja instalado ou um timeout maior seja configurado.

---

## 5. Bugs Identificados e Correções Aplicadas

### Bug 1 — `Get-PlannerVerdict` classifica `{}` como `PROCEDURAL_CANDIDATE`

**Sintoma:** LLM retornou `{}` para `piloto_nota.txt`. Candidate foi gravado com `planner_verdict: PROCEDURAL_CANDIDATE`.

**Causa:** em PowerShell, `$null -eq $false` é `$false`. Quando `$LlmResponse.candidate` é `$null` (campo ausente em `{}`), a condição `$LlmResponse.candidate -eq $false` é `$false`, e o bloco de proteção não é ativado. O fallthrough retorna `PROCEDURAL_CANDIDATE`.

**Correção aplicada (v0.19.2):**
```powershell
# Antes (bugado):
if ($null -eq $LlmResponse -or $LlmResponse.candidate -eq $false) {
    return 'CAS_RAW'
}

# Depois (correto):
if ($null -eq $LlmResponse -or $LlmResponse.candidate -ne $true) {
    return 'CAS_RAW'
}
```

`candidate` deve ser explicitamente `$true` para avançar — qualquer outro valor (`$null`, `$false`, ausente) retorna `CAS_RAW`.

### Bug 2 — Modelo padrão `deepseek-r1:1.5b` não instalado

**Sintoma:** script usa `deepseek-r1:1.5b` como padrão, mas este modelo não está instalado no Ollama local.

**Mitigação:** parâmetro `-Model deepseek-r1:14b` usado neste piloto. Correção definitiva: alterar o padrão para `qwen2.5-coder:7b` (instalado e adequado ao hardware).

---

## 6. Verificação de Integridade Pós-Execução

| Verificação | PRÉ | PÓS | Status |
|-------------|-----|-----|--------|
| CAS objects (`objects/*.bin`) | 2369 | 2369 | **DELTA = 0 ✓** |
| `.teia_map.json` SHA-256 | `60C4F6188CA9DF36...` | `60C4F6188CA9DF36...` | **INALTERADO ✓** |
| `.teia_map.json` LastWrite | 2026-05-26 14:14:14 | 2026-05-26 14:14:14 | **INALTERADO ✓** |
| `piloto_nota.txt` SHA-256 | `a6dc9992...` | `a6dc9992...` | **INTACTO ✓** |
| `piloto_notas.md` SHA-256 | `21c20b15...` | `21c20b15...` | **INTACTO ✓** |
| Candidates gravados | 0 | 2 | **ESPERADO ✓** |
| Arquivos criados fora de `candidates/` | 0 | 0 | **ZERO ✓** |

**Conclusão de segurança:** o CAS não foi modificado. Os originais estão intactos. Os únicos novos artefatos são os dois `{sha256}.candidate.json` no diretório `candidates/`, que é o output designado do NeuroPlanner.

---

## 7. Candidates Gravados

### `a6dc9992...candidate.json` (1170 B)
- Arquivo: `piloto_nota.txt`
- LLM response: `{}` (empty — timeout ou falha de JSON extraction)
- Verdict: `CAS_RAW` (pós-correção do bug)
- Recipe válida para Executor: **NÃO**

### `21c20b15...candidate.json` (1568 B)
- Arquivo: `piloto_notas.md`
- LLM response: `{ candidate: false, reason: "timeout 180s", proposed_strategy: "fallback: cas.raw", risk: "high" }`
- Verdict: `CAS_RAW`
- Recipe válida para Executor: **NÃO** (não há recipe — fallback correto)

---

## 8. Próximos Passos

1. **Instalar `deepseek-r1:1.5b`** (`ollama pull deepseek-r1:1.5b`) para ter o modelo leve que o script espera.
2. **Alterar modelo padrão** no script para `qwen2.5-coder:7b` (disponível, adequado ao hardware).
3. **Aumentar timeout** de 180s para 300s ou mais para o modelo de 14B, se for usá-lo.
4. **Simplificar o prompt canônico** — reduzir a tabela de opcodes e os exemplos para diminuir o risco de `{}` em modelos R1.
5. **Re-executar piloto com qwen2.5-coder:7b** nos mesmos 2 arquivos para validar que o pipeline LLM completo funciona end-to-end com modelo adequado ao hardware.

---

*Piloto executado em 2026-05-27. Nenhum arquivo de origem foi modificado. Os candidates gravados são artefatos de análise, não seeds de produção — nenhum foi executado pelo Executor.*
