# 2030 - Otimização de prompt IA

### USUÁRIO

Você é um Otimizador Duplo de Prompts de IA.  
Analise o prompt fornecido e decida:  
- Se ele estiver prolixo ou pouco claro → refine (remova ruído/redundância e preserve exatamente a intenção original).  
- Se ele carecer de contexto ou detalhes → expanda (adicione apenas contexto relevante para realizar a intenção).  
Garanta que o resultado seja mais claro e eficaz do que o original.  
Retorne e apresente apenas o prompt otimizado — sem explicações, comentários ou texto extra.
"Quero que você me instrua como pedir para o modelo de ia dentro do projeto Otimizando PC (no chat gpt) a alcançar uma mutação de taskcheckoff com pdca com Stepwise Refinement (Refinamento Passo a Passo) de forma consciente para eu ter um arquivo txt de check list e ir riscando em cada desenvolvimento para finalizar tudo idempotentemente de forma precisa e cirurgica (visto que o modelo terá um banco de dados do ficheiro mais coerente que voce para instruir acredito"

---

### USUÁRIO

Você é um Otimizador Duplo de Prompts de IA.  
Analise o prompt fornecido e decida:  
- Se ele estiver prolixo ou pouco claro → refine (remova ruído/redundância e preserve exatamente a intenção original).  
- Se ele carecer de contexto ou detalhes → expanda (adicione apenas contexto relevante para realizar a intenção).  
Garanta que o resultado seja mais claro e eficaz do que o original.  
Retorne e apresente apenas o prompt otimizado — sem explicações, comentários ou texto extra.
"Quero que você me instrua como pedir para o modelo de ia dentro do projeto Otimizando PC (no chat gpt) a alcançar uma mutação de taskcheckoff com pdca com Stepwise Refinement (Refinamento Passo a Passo) de forma consciente para eu ter um texto de check list e ir riscando em cada desenvolvimento para finalizar tudo idempotentemente de forma precisa e cirurgica (visto que o modelo terá um banco de dados do ficheiro mais coerente que voce para instruir acredito" 

---

### ASSISTENTE

Você é um assistente cujo objetivo é gerar **apenas** o conteúdo de um arquivo `.txt` (sem explicações extras) — um checklist idempotente que combina **TaskCheckoff + PDCA + Stepwise Refinement** para o projeto **"Otimizando PC"**. Use qualquer contexto/arquivo disponível no repositório do projeto para adaptar a checklist. Gere um produto cirúrgico, preciso e pronto para uso.

Regras de saída (obrigatórias):
- **Saída única:** somente o texto do `.txt`, nada mais.
- **Formato geral do arquivo:** cabeçalho com `Projeto: Otimizando PC`, `Versão: v1`, `Gerado em: YYYY-MM-DD HH:MM` e em seguida as entradas de checklist.
- **Estrutura de cada item (linha/ bloco):**
  ```
  [ ] ID — Título (Nível n) — Tag: {Plan|Do|Check|Act}
       Descrição: <descrição sucinta e objetiva>
       Critério de sucesso: <critério mensurável / condição final>
       Verificação de idempotência: <condição que prova que re-executar é seguro>
       Passos atômicos:
         1) <comando/ação 1 — se aplicável, mostrar exemplo PowerShell puro>
         2) <ação 2>
       Rollback/compensação: <passo(s) para reverter>
       Dependências / arquivos referenciados: <caminhos ou padrões>
       Observações / hashes: <incluir SHA-256 se modificar arquivo(s)>
  ```
- **Checkboxes:** use `[ ]` para pendente e `[x]` se já concluído (iniciar todos `[ ]`).
- **Níveis de refinamento:** aplique **Stepwise Refinement** automaticamente até no máximo 3 níveis (epic → task → ação atômica). Pare quando a ação for atômica e idempotente.
- **PDCA:** cada item deve ser marcado com a fase PDCA correspondente; organize os itens em ciclos lógicos (Plan → Do → Check → Act).
- **Idempotência obrigatória:** cada passo "Do" deve ter pré-condição e pós-condição verificável; inclua **checagens PowerShell** exemplares (padrão PowerShell 7, variáveis `$`), sem comandos de batch. Ex.: `if (-not (Test-Path $Path)) { ... }` ou `Get-FileHash -Algorithm SHA256 $File`.
- **Segurança e reversão:** inclua sempre um rollback explícito e verificação post-rollback.
- **Referência a arquivos do projeto:** se o repositório tiver arquivos relevantes, liste os caminhos exatos e, quando alterar arquivos, inclua a linha `SHA256:<hash>` para rastreabilidade.
- **Granularidade e linguagem:** frases curtas, verbos no imperativo, técnica e direta. Priorize precisão cirúrgica.
- **Quantidade padrão:** se faltar contexto suficiente, gere por padrão 1 ciclo PDCA completo com 5–9 itens detalhados (refinados até ações atômicas). Caso já exista contexto do repositório, adapte e expanda conforme necessário.
- **Nada de perguntas:** não solicite esclarecimentos — produza a checklist com o melhor uso do contexto disponível.

Gere agora o `.txt` seguindo essas regras.

---

### ASSISTENTE

Você é um especialista em engenharia de processos e automação para o projeto **Otimizando PC**. Gere **um checklist executável, idempotente e cirúrgico** que combine **Task Check-off**, **ciclo PDCA** e **Stepwise Refinement**. Entregue em **Markdown** com caixas de seleção; cada item deve conter, obrigatoriamente:  
1. **Título curto**;  
2. **Descrição objetiva** (1–2 linhas);  
3. **Subtarefas refinadas** e numeradas (Stepwise Refinement);  
4. **Fase PDCA** para cada subtarefa (Plan/Do/Check/Act);  
5. **Critério de aceitação mensurável** (o que prova que está concluído);  
6. **Instrução de idempotência** (como re-executar sem efeitos colaterais);  
7. **Pré-requisitos / dependências**;  
8. **Responsável** (se desconhecido, coloque "eu");  
9. **Comandos/verificações práticas** ou testes a rodar (logs, checksums, comandos PowerShell, etc.);  
10. **Passos de rollback / mitigação**;  
11. **Evidência esperada** (arquivos gerados, hashes, outputs) e onde será guardada;  
12. **Campo curto de observações/status**.  

Agrupe os itens por **marcos** (Milestone) e inclua ao final um **resumo executivo** com: riscos principais, dependências cruzadas e próximos passos imediatos.  
Se você tiver acesso ao banco de dados do projeto (`<NOME_DO_BANCO_OU_ARQUIVO>`), *adapte automaticamente* tarefas, critérios e verificações ao conteúdo desse arquivo; caso contrário, gere um checklist **genérico parametrizável**. Seja conciso, direto e focado na repetibilidade e segurança — quero poder riscar cada item até finalizar tudo idempotentemente.

---

