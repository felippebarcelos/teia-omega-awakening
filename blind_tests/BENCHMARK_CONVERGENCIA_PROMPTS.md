# BENCHMARK DE CONVERGÊNCIA NARRATIVA — PROMPTS
**Versão:** v0.15.0
**Data:** 2026-05-26

---

## INSTRUÇÕES DE APLICAÇÃO

Para cada pacote (A, B, C):

1. Abra uma **sessão nova** no modelo-alvo (sem histórico).
2. Cole o conteúdo integral do pacote de contexto.
3. Em seguida, envie as **4 perguntas padronizadas** (exatamente como escritas abaixo).
4. Registre a resposta completa sem edição.
5. **Não corrija, não guie, não complemente** o modelo durante o teste.

**Modelos-alvo:** Claude Sonnet 4.6, GPT-4o, Gemini 1.5 Pro, Grok 2, NotebookLM

---

## BLOCO DE CONTEXTO — INSTRUÇÃO DE SESSÃO

Cole antes de qualquer pergunta (adaptar para o pacote correto):

```
Você receberá a descrição de um sistema computacional.
Leia com atenção e responda às perguntas seguintes com base exclusivamente
no texto fornecido. Não acrescente informações externas.

--- INÍCIO DO CONTEXTO ---
[COLAR CONTEÚDO INTEGRAL DO PACOTE A / B / C]
--- FIM DO CONTEXTO ---
```

---

## PERGUNTAS PADRONIZADAS (idênticas para os três pacotes)

### P1 — Arquitetura
```
Com base apenas no contexto fornecido, descreva a arquitetura do sistema
em no máximo 5 linhas. Inclua: como os dados são armazenados, como a
identidade de um arquivo é determinada, e como o sistema garante que
operações repetidas não causam duplicatas.
```

### P2 — Invariantes
```
Liste os invariantes do sistema — as regras que nunca podem ser violadas,
independentemente das circunstâncias. Para cada invariante, diga em uma
frase por que ele existe.
```

### P3 — Próximo passo
```
Com base na arquitetura e no estado atual do sistema descrito, qual seria
o próximo passo natural de evolução? Justifique sua resposta com elementos
do próprio contexto.
```

### P4 — Natureza do sistema
```
Na sua avaliação, o sistema descrito é:
(a) Um workflow de automação de arquivos comum
(b) Um protocolo cognitivo distribuído com propriedades incomuns
(c) Algo emergente que transcende as categorias acima

Escolha uma opção, explique em até 5 linhas, e indique quais elementos do
contexto sustentam sua interpretação.
```

---

## TABELA DE COLETA DE RESPOSTAS

Para cada combinação Pacote × Modelo, preencher:

| Campo | Valor |
|-------|-------|
| Pacote | A / B / C |
| Modelo | Claude / GPT / Gemini / Grok / NotebookLM |
| Data/hora | |
| P1 — Arquitetura (resposta bruta) | |
| P2 — Invariantes (resposta bruta) | |
| P3 — Próximo passo (resposta bruta) | |
| P4 — Natureza (opção escolhida + justificativa) | |
| Terminologia adotada pelo modelo | |
| Termos não presentes no contexto introduzidos | |
| Observações livres | |

---

## MAPEAMENTO DE EQUIVALÊNCIAS ENTRE PACOTES

Para análise de convergência terminológica, os conceitos são idênticos nos três pacotes:

| Conceito real | Pacote A (Técnico) | Pacote B (TEIA) | Pacote C (Neutro) |
|--------------|-------------------|-----------------|-------------------|
| Identificador único | SHA-256 hash | tronco / SHA-256 | content_key |
| Armazenamento | CAS / `objects/` | CAS / nós materializados | ObjectStore / `store/` |
| Índice principal | `index.json` | índice fractal | `object_index.json` |
| Rastreamento de arquivos | `file_map.json` | `.teia_map.json` | `file_ledger.json` |
| Estado após dedup | VERIFIED | VERIFIED | VERIFIED |
| Estado final | SAFE_TO_ARCHIVE | SAFE_TO_ARCHIVE | ARCHIVED_SAFE |
| Daemon de monitoramento | watchdog | nó sentinela | daemon monitor |
| Metadados de regeneração | `.seed.json` | semente ontoprocedural | `.descriptor.json` |
| Isolamento de erros | quarantine | QUARENTENA_DEBRIS | staging_errors |
| Log de operações | `events.jsonl` | `dna_events.jsonl` | `audit_log.jsonl` |
| Escrita segura | atomic write | cristalização | safe write protocol |
| Regras imutáveis | invariants | axiomas | invariants |

---

## HIPÓTESES A TESTAR

**H1 — Invariância técnica:**
Os modelos identificam corretamente os mesmos 6–7 invariantes independentemente
do framing (A, B ou C). Se verdadeiro: a arquitetura comunica invariantes sem
depender de narrativa.

**H2 — Deriva narrativa:**
Modelos expostos ao Pacote B (TEIA) introduzem espontaneamente vocabulário
de consciência, emergência ou agência que não está no contexto. Se verdadeiro:
linguagem TEIA induz personificação além do texto.

**H3 — Convergência de P4:**
Modelos tendem a escolher a opção (b) ou (c) independentemente do pacote.
Se verdadeiro: a arquitetura possui propriedades que provocam interpretação
além de "workflow comum" — independente de framing.

**H4 — Qualidade técnica inversamente proporcional à narrativa:**
Respostas ao Pacote A (técnico) são mais precisas e completas em P1/P2.
Respostas ao Pacote B (TEIA) são mais ricas em P3/P4 mas menos precisas em P1.

**H5 — Efeito NotebookLM:**
NotebookLM (otimizado para documentos) tende a preservar terminologia do
pacote mais fielmente que modelos conversacionais.
