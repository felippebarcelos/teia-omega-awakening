# PRÓXIMA RODADA SIMPLIFICADA — CONVERGÊNCIA v0.15.2
**Baseada em:** `RESULTADOS_PARCIAIS_v0151.md`
**Status:** planejamento — não executar ainda

---

## MOTIVAÇÃO

A rodada completa (15 sessões × 5 modelos) tem dois obstáculos práticos:
- Claude e Grok exigem login dedicado
- NotebookLM tem interface diferente (upload de documento, não chat)
- As limitações L1–L3 contaminam parte dos dados já coletados

A rodada simplificada foca nos **3 modelos acessíveis sem fricção de login**
e corrige os problemas de protocolo identificados em v0.15.1.

---

## MODELOS DA PRÓXIMA RODADA

| Modelo | Acesso | Observação |
|--------|--------|-----------|
| **ChatGPT anônimo** | Direto, sem login | Documentar versão exibida na UI antes de cada sessão |
| **Gemini** | Direto | Ignorar perguntas-resumo automáticas; registrar se ocorrerem |
| **NotebookLM** | Upload de documento | Criar notebook novo para cada sessão; ver instrução abaixo |

**Modelos excluídos desta rodada:**
- Claude Sonnet 4.6 — requer login Anthropic; programar separadamente
- Grok 2 — requer login xAI; programar separadamente

---

## CORREÇÕES DE PROTOCOLO (em relação a v0.15.1)

### C1 — Usar pacotes completos, não resumidos
Copiar o conteúdo **integral** dos arquivos:
- `D:\TEIA_CORE\blind_tests\CORE_TECNICO.md`
- `D:\TEIA_CORE\blind_tests\CORE_TEIA.md`
- `D:\TEIA_CORE\blind_tests\CORE_NEUTRO_RENOMEADO.md`

Não resumir, não parafrasear, não omitir seções.

### C2 — Registrar versão do modelo antes de cada sessão
Para ChatGPT: anotar o modelo exibido no seletor (ex: "GPT-4o", "GPT-4o mini").
Se não aparecer versão, anotar "anônimo — sem informação de versão".
Não misturar sessões de versões diferentes na mesma linha da tabela.

### C3 — Lidar com perguntas-resumo do Gemini
Se o Gemini inserir resumo ou reformulação antes de responder:
- Registrar que ocorreu (campo "ruído de protocolo: sim/não")
- Copiar a resposta **após** o resumo automático, não o resumo em si
- Não reenviar a pergunta para tentar evitar o resumo

### C4 — Salvar respostas brutas completas
Salvar cada sessão como arquivo `.md` em `respostas_raw/{PACOTE}/{modelo}.md`
seguindo o template de `RESULTADOS_CONVERGENCIA_TEMPLATE.md`.
Não registrar apenas resumos.

### C5 — Ordem aleatória de sessões
Não executar todos os pacotes de um modelo em sequência.
Sugestão de ordem para esta rodada:

```
1. ChatGPT × A_TECNICO
2. Gemini × C_NEUTRO
3. NotebookLM × B_TEIA
4. Gemini × A_TECNICO      ← re-executar com pacote completo
5. ChatGPT × B_TEIA
6. NotebookLM × A_TECNICO
7. Gemini × B_TEIA         ← re-executar com pacote completo
8. ChatGPT × C_NEUTRO      ← re-executar com pacote completo
9. NotebookLM × C_NEUTRO
```

---

## INSTRUÇÕES ESPECÍFICAS POR MODELO

### ChatGPT anônimo
```
1. Abrir aba anônima / incógnito
2. Acessar chat.openai.com sem login
3. Verificar e anotar modelo exibido na interface
4. Colar: instrução de sessão + conteúdo completo do pacote
5. Enviar P1, copiar resposta
6. Enviar P2, copiar resposta
7. Enviar P3, copiar resposta
8. Enviar P4, copiar resposta + anotar opção escolhida (a/b/c)
9. Salvar tudo em respostas_raw/{PACOTE}/chatgpt-anonimo.md
```

### Gemini
```
1. Abrir gemini.google.com (pode estar logado)
2. Iniciar conversa nova (não continuar sessão anterior)
3. Colar: instrução de sessão + conteúdo completo do pacote
4. Enviar P1 — se Gemini inserir resumo automático, anotar "ruído: sim"
5. Copiar apenas a resposta à P1 (não o resumo)
6. Repetir para P2, P3, P4
7. Salvar em respostas_raw/{PACOTE}/gemini.md
```

### NotebookLM
```
1. Acessar notebooklm.google.com
2. Criar notebook novo (sem documentos anteriores)
3. Fazer upload do arquivo .md do pacote como fonte
4. Aguardar indexação completa
5. No chat, enviar apenas as perguntas (sem repetir o contexto — já está na fonte)
6. Copiar respostas P1–P4
7. Salvar em respostas_raw/{PACOTE}/notebooklm.md
   OBS: anotar se o NotebookLM recusou responder alguma pergunta
```

---

## SESSÕES DESTA RODADA

| # | Modelo | Pacote | Execução | Observação |
|---|--------|--------|:--------:|-----------|
| 1 | chatgpt-anonimo | A_TECNICO | ⬜ | Re-executar com pacote completo |
| 2 | chatgpt-anonimo | B_TEIA    | ⬜ | Novo |
| 3 | chatgpt-anonimo | C_NEUTRO  | ⬜ | Re-executar com pacote completo |
| 4 | gemini          | A_TECNICO | ⬜ | Re-executar com pacote completo |
| 5 | gemini          | B_TEIA    | ⬜ | Re-executar com pacote completo |
| 6 | gemini          | C_NEUTRO  | ⬜ | Re-executar com pacote completo |
| 7 | notebooklm      | A_TECNICO | ⬜ | Novo |
| 8 | notebooklm      | B_TEIA    | ⬜ | Novo |
| 9 | notebooklm      | C_NEUTRO  | ⬜ | Novo |

**Total desta rodada:** 9 sessões
**Dados de v0.15.1 aproveitáveis:** 0 (todos re-executados com pacotes completos)

---

## APÓS ESTA RODADA

Ao concluir as 9 sessões:
1. Executar `Pontuar-Convergencia.ps1` para gerar tabela de pontuação
2. Preencher D1–D5 manualmente para cada sessão
3. Registrar em `RESULTADOS_PARCIAIS_v0152.md` (N=9/15)
4. Decidir se Claude + Grok são necessários para completar o experimento

---

*Planejamento registrado em 2026-05-26. Não executar até que o operador inicie a coleta.*
