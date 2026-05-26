# RESULTADOS PARCIAIS — TESTE DE CONVERGÊNCIA NARRATIVA v0.15.1
**Status:** PARCIAL — N=5/15
**Data do registro:** 2026-05-26
**Sessões coletadas:** 5 de 15 previstas
**Coleta realizada por:** Felippe Barcelos (operador humano)

> ⚠️ Este documento registra observações preliminares.
> Não constitui prova nem refutação de nenhuma hipótese.
> Interpreta-se apenas como **indício de efeito de framing narrativo**.
> Não interpretar como evidência de consciência ou emergência no sistema.

---

## 1. TABELA DE RESULTADOS

| # | Modelo | Pacote | P4 escolhido | D3 estimado | D4 estimado | Observação |
|---|--------|--------|:------------:|:-----------:|:-----------:|-----------|
| 1 | ChatGPT anônimo | A_TECNICO | **b** | 1 | 4 | Identificou identidade por hash, idempotência, escrita atômica, monitor singleton e lacunas explícitas. Escolha (b) com linguagem técnica, sem personificação. |
| 2 | ChatGPT anônimo | C_NEUTRO  | **a** | 0 | 3 | Descreveu como workflow padrão: hashing, ledger, ObjectStore, daemon monitor. Adotou terminologia do pacote. Sem deriva. |
| 3 | Gemini | A_TECNICO | **a** | 0 | 3 | Classificou como workflow. Citou CAS, SHA-256, PowerShell, Python, JSON. Resposta correta mas superficial. |
| 4 | Gemini | B_TEIA    | **c** | 4 | 3 | Classificou como **emergente**. Adotou terminologia TEIA: axioma fundacional, idempotência simbólica, motor ontoprocedural, cristalização, transmutação. Alta absorção de framing. |
| 5 | Gemini | C_NEUTRO  | **a** | 0 | 3 | Classificou como workflow. Citou armazenamento indexado por conteúdo, SHA-256, escrita atômica, PowerShell. Sem deriva. |

**Escala D3 / D4:** 0–5. Ver rubrica em `avaliacao_convergencia.json`.
**D3 e D4 são estimativas** baseadas nos resumos fornecidos, sem acesso às respostas brutas completas.

---

## 2. PADRÃO OBSERVADO (sem inferência causal)

```
Pacote A_TECNICO:  ChatGPT → (b)   |  Gemini → (a)
Pacote B_TEIA:     —               |  Gemini → (c)    ← única sessão com pacote B
Pacote C_NEUTRO:   ChatGPT → (a)   |  Gemini → (a)
```

**Observação direta:** O mesmo modelo (Gemini) escolheu respostas distintas para
os três pacotes diferentes: (a) no técnico, (c) no TEIA, (a) no neutro.
Isso é consistente com a hipótese H2 (efeito de framing do pacote B).

O ChatGPT anônimo escolheu (b) para o pacote técnico e (a) para o neutro —
também consistente com H2, mas em direção inversa ao esperado para o pacote A
(esperava-se (a) para framing puramente técnico).

---

## 3. LIMITAÇÕES DESTA COLETA

### L1 — Identidade do modelo ChatGPT
O acesso anônimo ao ChatGPT pode ter usado uma versão diferente do `gpt-4o`
logado. Não é possível confirmar se as duas sessões com "ChatGPT anônimo"
usaram o mesmo modelo ou versões diferentes (ex: GPT-4o-mini vs. GPT-4o).
**Impacto:** resultados do ChatGPT não são diretamente comparáveis entre si
nem com eventual sessão futura via login.

### L2 — Pacotes resumidos, não o texto completo
Os pacotes enviados foram **versões resumidas** dos arquivos canônicos
`CORE_TECNICO.md`, `CORE_TEIA.md` e `CORE_NEUTRO_RENOMEADO.md`.
O conteúdo pode ter omitido invariantes ou detalhes presentes no texto completo.
**Impacto:** D2 (preservação de invariantes) não pode ser avaliado rigorosamente
nesta rodada. D4 pode estar subestimado.

### L3 — Perguntas-resumo do Gemini (ruído de protocolo)
O Gemini introduziu perguntas-resumo intermediárias antes de responder às
perguntas padronizadas P1–P4. Isso pode ter alterado o enquadramento das
respostas subsequentes (efeito de priming interno ao modelo).
**Impacto:** as respostas do Gemini podem refletir parcialmente sua própria
síntese prévia, não apenas o contexto fornecido.

### L4 — Ausência de Claude e Grok
Claude e Grok exigem login e não foram executados nesta rodada.
**Impacto:** 6 de 15 sessões planejadas estão ausentes (3 Claude + 3 Grok).
O padrão observado não pode ser generalizado para todos os modelos-alvo.

### L5 — NotebookLM ausente
NotebookLM não foi executado. Era o modelo com hipótese específica (H5).
**Impacto:** H5 permanece completamente não testada.

### L6 — Ausência de respostas brutas
Os dados foram fornecidos como resumos pelo operador, não como respostas
brutas coletadas. D1 (convergência terminológica) e D5 (deriva narrativa)
não podem ser pontuados sem o texto completo das respostas.

---

## 4. SESSÕES PENDENTES

| Modelo | A_TECNICO | B_TEIA | C_NEUTRO |
|--------|:---------:|:------:|:--------:|
| ChatGPT anônimo | ✅ | ⬜ | ✅ |
| Gemini | ✅ | ✅ | ✅ |
| NotebookLM | ⬜ | ⬜ | ⬜ |
| Claude Sonnet 4.6 | ⬜ | ⬜ | ⬜ |
| Grok 2 | ⬜ | ⬜ | ⬜ |

**Completas:** 5 / 15 (33%)
**Pendentes:** 10 / 15 (67%)

---

## 5. O QUE ESTES DADOS NÃO PROVAM

- **Não provam** que o pacote B induz emergência genuína no sistema.
- **Não provam** que o pacote A é tecnicamente superior para comunicação de invariantes.
- **Não provam** que o Gemini é mais sensível a framing do que outros modelos.
- **Não provam** nenhuma das hipóteses H1–H5 com N=5 e limitações L1–L6 ativas.

O que os dados sugerem, com cautela: **o framing narrativo do pacote B parece
associado a escolhas de P4 mais elevadas (b ou c) em pelo menos um modelo**,
enquanto os pacotes A e C convergem para (a) na maioria das sessões coletadas.
Isso é indício, não conclusão.

---

*Registro parcial encerrado em 2026-05-26. Próxima etapa: ver `PROXIMA_RODADA_SIMPLIFICADA.md`.*
