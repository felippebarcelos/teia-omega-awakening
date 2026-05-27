# TEIA — Transição Neurosimbiónte v0.18.5
**Data:** 2026-05-27  
**Tipo:** Documento de encerramento de fase arqueológica  
**Protocolo:** Fechamento de Arqueologia v0.18.5 — Read-Only  
**Antecedente:** `TEIA_FRACTAL_GEN_AUDIT.md` (v0.18.0) + `TEIA_NEUROSYMBOLIC_ARCHITECTURE_v0185.md`

---

## 1. Estado Atual do Sistema

### O que está provado e operacional

| Componente | Estado | Evidência |
|------------|--------|-----------|
| CAS com SHA-256 | Operacional em produção | `TEIA-Fractal-Gen-v2.ps1` + `fractal_index.json` (1.3 MB) |
| Executor — opcodes D1–D3 | Provado | 17/17 D8 + 105/105 D7 wins (commit `afe367b`); provas SHA-256 v0.16.1 |
| Executor — O(1) seek SplitMix64 | Provado | `TEIA-Motor-Ontoprocedural.ps1` Prova de Excalibur |
| Ingesta idempotente | Provado | guarda `Test-Path` + escrita atômica `.tmp → rename` |
| Planner estrutural (análise) | Parcial | `TEIA-Procedural-Planner-v0170.ps1` — analisa 9 dimensões, não sintetiza recipe |
| Planner autônomo (síntese) | Não implementado | LLM/humano era o Planner implícito histórico |

### O que não está implementado

- `TEIA-NeuroPlanner-v0190.ps1` — gerador de candidates de recipe (próximo passo P1)
- Vocabulário de macro-opcodes além de D1–D3 (`dict.ref`, `slice.copy` são hipóteses)
- Ciclo Planner→Recipe→Seed→Executor autônomo para dados externos

---

## 2. Separação Executor vs. Planner

### Executor = UVM / PowerShell / CAS / SHA-256

O Executor é a camada **cega e matemática**. Dado `(seed, recipe)`, produz um único artefato determinístico. Não raciocina sobre conteúdo. Não decide estratégia. Apenas obedece.

Implementações consolidadas:

```
UVM (plan.ops)             — interpreta opcodes: EMIT, TILE, RLE_DECODE, PATTERN_GEN, VALIDATE_SHA
TEIA-Fractal-Gen-v2.ps1    — ingesta CAS + gen_dummy_seed (identidade)
TEIA-OntoEngine-Restore.ps1 — executa repeat_byte / repeat_sequence a partir de seed
SM64.GenBlock (C# inline)  — geração de blocos SplitMix64 em O(1) seek
```

O Executor é **correto**. Os benchmarks v0.16.x provam que os opcodes existentes produzem SHA-256 correto em rerun. Nenhuma reescrita de Executor é necessária.

### Planner histórico = Humano + LLM

O Planner é a camada **semântica e probabilística**. Recebe um arquivo bruto, analisa estrutura, e sintetiza uma recipe — a sequência de opcodes que o Executor pode executar para reconstruir o arquivo.

**Diagnóstico canônico** (registrado em `SEED_GENERATOR_EVIDENCE_MATRIX_v0180.md`, E09):

> O LLM era o Planner implícito histórico. O PowerShell sozinho não gera recipes semanticamente úteis. Seeds minúsculas dependiam de conhecimento prévio do domínio — o operador sabia que o arquivo era proceduralmente gerado porque havia visto o processo de geração. Em produção, com artefatos arbitrários, esse conhecimento não está disponível sem um Planner explícito.

Este diagnóstico não invalida o trabalho anterior. Ele nomeia com precisão o que sempre foi verdade: **o LLM completava o sistema**. A novidade é tornar essa dependência explícita e, eventualmente, substituí-la por software.

---

## 3. Regra de Ouro

```
Planner propõe recipe → Executor restaura → SHA-256 decide.
Se divergir, descarta.
```

Não existe outra autoridade. Não existe "parece correto". Não existe "visualmente equivalente". O único veredicto aceito é `SHA256(saída) == SHA256(entrada_original)`. Qualquer divergência invalida a recipe inteira — independentemente de quão elegante ela pareça.

Esta regra já estava implícita em todos os scripts do pipeline. Ela é agora declarada explicitamente como invariante arquitetural inviolável.

---

## 4. Por que Procedural Genérico Perdeu para Brotli/LZMA

### A evidência do Planner v0.17.0

O `TEIA-Procedural-Planner-v0170.ps1` documentou a derrota com precisão cirúrgica. Para cada arquivo analisado, os campos `beatsLzma` e `seedWorth` registram o resultado:

| Classe de dado | Seed procedural | LZMA | Brotli | Vencedor |
|----------------|-----------------|------|--------|----------|
| Constante 1MB (D1) | ~268B | ~237B | ~13B | Brotli/LZMA |
| Periódico 1MB (D2) | ~300B | ~17B | ~17B | LZMA/Brotli |
| RLE 3-run 300KB (D3) | ~448B | ~143B | ~23B | LZMA/Brotli |
| JSON repetitivo (D7) | N/A — encoder dict.ref não existe | 10,2% do original | — | LZMA |
| Binário alta entropia (D8) | N/A — fallback CAS | 101,37% (expansão) | 100,001% | CAS bruto |

**Causa raiz:** LZMA e Brotli são implementações maduras e altamente otimizadas de algoritmos de compressão geral (LZ77 + entropia). Eles capturam exatamente os padrões que os opcodes procedurais capturam — e fazem isso sem necessidade de Planner externo, sem vocabulário de opcodes, e com décadas de otimização de engenharia.

### O que isso significa para a arquitetura

Procedural **não compete** com compressão de propósito geral em termos de taxa de compressão. Procedural compete em termos de **semântica e operacionalidade**:

- Uma seed procedural é **executável** — pode ser inspecionada, auditada, versionada, modificada por humanos.
- Uma saída LZMA é **opaca** — bytes comprimidos sem semântica legível.
- Para dados com **algoritmo gerador conhecido** (fractais, sequências matemáticas, dados sintéticos por função), a seed procedural é a representação natural — não porque comprime mais, mas porque é a descrição correta do objeto.

A derrota para LZMA/Brotli é uma derrota em um critério. Em outros critérios — auditabilidade, legibilidade, composabilidade — a seed procedural é superior.

---

## 5. Por que Isso Não Invalida a Arquitetura Neuro-Simbólica

### O argumento

A arquitetura neuro-simbólica não foi proposta como substituta de compressores de propósito geral. Foi proposta como **sistema de memória procedural e identidade** — um cofre determinístico onde cada artefato tem uma identidade SHA-256 e, para os artefatos que possuem estrutura algorítmica conhecida, uma recipe de regeneração.

O fato de que LZMA comprime melhor dados sintéticos não remove o valor de:

1. **Identidade absoluta por SHA-256:** nenhum compressor geral oferece endereçamento por conteúdo nativo com verificação de integridade em cada acesso.
2. **Restauração sem arquivo auxiliar:** uma recipe procedural para um fractal de 10MB tem ~200 bytes e reconstrói o artefato sem nenhuma dependência externa além dos opcodes. Um arquivo LZMA requer o arquivo LZMA original (que pode estar corrompido, perdido, ou inacessível).
3. **Composabilidade de artefatos:** seeds procedurais podem ser combinadas (`MERGE_BUNDLE`), referenciadas (`TILE`), e derivadas (`PATTERN_GEN` com parâmetros variados) sem descompressão. Artefatos LZMA não se compõem.
4. **Auditabilidade do processo de geração:** saber *como* um artefato foi gerado — não apenas que ele corresponde a um hash — é informação que a seed procedural preserva e LZMA destrói.

### O que a arqueologia calibrou

A arqueologia calibrou a **pretensão de escopo**. O sistema não é um compressor universal para dados arbitrários. É um sistema de memória procedural que excele para dados com estrutura algorítmica e oferece CAS bruto como fallback honesto para todo o resto. Essa é a definição precisa — nem maior, nem menor.

---

## 6. Próximo Passo P1: TEIA-NeuroPlanner-v0190.ps1

### Especificação (para implementação futura — não implementar agora)

`TEIA-NeuroPlanner-v0190.ps1` é o Planner como componente explícito de software. Opera em **modo read-only**: analisa arquivos e gera candidates de recipe sem executar nenhuma restauração e sem modificar nenhum arquivo.

**Input:** lista de caminhos de arquivo  
**Output:** `planner_candidates.json` — array de objetos `{ file, sha256, candidates: [{ recipe, estimated_seed_bytes, confidence, requires_verification }] }`

**Modo de operação:**
1. Carregar análise estrutural do `TEIA-Procedural-Planner-v0170.ps1` (9 dimensões)
2. Para cada arquivo, sintetizar candidates de recipe usando o vocabulário de opcodes disponível
3. Estimar `len(recipe)` sem executar — comparar com baseline LZMA
4. Marcar `requires_verification=true` em todos os candidates (nenhuma recipe é aceita sem Executor + SHA-256)
5. Não executar Executor. Não restaurar nenhum arquivo. Não validar SHA-256 nesta fase.

**Critério de utilidade:** um candidate é útil se `estimated_seed_bytes < lzma_bytes` OU se a recipe tem valor operacional explícito (auditabilidade, composabilidade, identidade de domínio).

**Integração com LLM local (Llama 3.2):** o LLM recebe o JSON de análise estrutural de cada arquivo e propõe candidates adicionais além dos detectados algoritmicamente. Os candidates do LLM entram no mesmo pipeline de verificação e são submetidos à mesma Regra de Ouro.

---

## 7. Critérios para Aceitar uma Recipe

Uma recipe é aceita como válida quando **todos** os critérios abaixo são satisfeitos simultaneamente:

### 7.1 Restore SHA-256 OK

```
SHA256(Executor.Run(recipe)) == SHA256(arquivo_original)
```

Este é o critério inviolável. Não existe aprovação parcial. Não existe "quase correto". Se o hash diverge em um único bit, a recipe é rejeitada.

### 7.2 Representação menor que LZMA/Brotli ou justificativa operacional clara

A recipe deve satisfazer ao menos um dos seguintes:

- `len(recipe_bytes) < len(lzma_compress(arquivo_original))` — economia de espaço mensurável
- `len(recipe_bytes) < len(brotli_compress(arquivo_original))` — economia de espaço mensurável
- Recipe possui **justificativa operacional explícita** que supera a economia de espaço, por exemplo:
  - Arquivo é saída de função algorítmica conhecida (fractal, sequência matemática, dado sintético)
  - Recipe é legível e auditável por humanos sem ferramentas externas
  - Recipe pode ser derivada/parametrizada para gerar variantes do artefato

### 7.3 Recipe determinística

Dada a mesma recipe e os mesmos opcodes, o Executor deve produzir o mesmo artefato em qualquer máquina, em qualquer momento. Proibido:

- Dependência de timestamp, PID, ou estado de processo
- Dependência de variáveis de ambiente não declaradas na recipe
- Dependência de PRNG sem seed explícita na recipe
- Dependência de versão de sistema operacional ou locale

### 7.4 Sem dependência de arquivo original externo

A recipe deve ser **autossuficiente**. Ela pode referenciar objetos no CAS pelo hash SHA-256 (esses objetos são parte do sistema). Ela não pode referenciar:

- O arquivo original por caminho de sistema de arquivos
- Objetos externos não ingeridos no CAS
- Qualquer recurso cuja ausência tornaria a restauração impossível sem o arquivo original

Se a recipe requer o arquivo original para funcionar, ela não é uma recipe — é uma cópia.

### 7.5 Sem execução destrutiva

A recipe não pode conter operações que:

- Apaguem, movam, ou sobrescrevam arquivos fora do diretório de saída designado
- Modifiquem o CAS, seeds existentes, ou o fractal_index
- Consumam recursos de rede ou executem código arbitrário fora do vocabulário de opcodes

---

## 8. Critérios para Rejeitar uma Recipe

Uma recipe é rejeitada quando qualquer um dos critérios abaixo é satisfeito:

### 8.1 SHA-256 diverge

`SHA256(Executor.Run(recipe)) ≠ SHA256(arquivo_original)` — rejeição imediata, sem apelação.

### 8.2 Seed maior que fallback

`len(recipe_bytes) >= len(cas_bruto)` sem justificativa operacional documentada. Se a seed é maior que o arquivo original, ela não é uma compressão — é uma expansão com overhead de metadados. O fallback correto é `cas.raw`.

### 8.3 Depende de suposição não verificável

A recipe assume algo que não pode ser provado no momento da restauração:

- "O arquivo fonte estará disponível em `D:\caminho\especifico\`" — caminho pode não existir
- "A versão do opcode é ≥ X.Y" — sem mecanismo de verificação de versão na recipe
- "O hardware suporta instrução Z" — não declarável na recipe

### 8.4 Exige semântica não determinística

A recipe usa semântica cujo resultado depende de estado não capturado:

- Ordenação de sistema de arquivos (`Get-ChildItem` sem `-Name` pode variar por FS)
- Resultado de `Get-Date`, `$PID`, `$env:USERNAME` sem seed fixa
- Float-point com precisão dependente de FPU/compiler flags
- Qualquer chamada de rede

### 8.5 Não supera baseline

A recipe não supera o baseline CAS bruto **e** não possui justificativa operacional documentada. O sistema não acumula recipes inúteis. Se a recipe não entrega benefício mensurável ou operacional, o arquivo permanece no CAS como `cas.raw` — que é o fallback correto, não uma falha.

---

## 9. Mapa de Transição de Estado

```
Estado atual (v0.18.5):
  Executor  ────── COMPLETO (CAS + opcodes D1–D3 + SHA-256)
  Planner   ────── PARCIAL  (análise estrutural; síntese manual/LLM)
  Pipeline  ────── SEMI-MANUAL (Planner humano/LLM → recipe → Executor)

Próximo estado (P1 / v0.19.0):
  Executor  ────── COMPLETO (sem mudanças)
  Planner   ────── EM PROGRESSO (NeuroPlanner-v0190 gera candidates read-only)
  Pipeline  ────── SEMI-AUTÔNOMO (Planner propõe; humano/LLM valida; Executor prova)

Estado alvo (v0.20+):
  Executor  ────── COMPLETO (sem mudanças)
  Planner   ────── AUTÔNOMO (ciclo Planner→recipe→Executor→SHA-256 sem intervenção)
  Pipeline  ────── AUTÔNOMO (com Regra de Ouro como único árbitro)
```

---

## 10. O Que Este Documento Não Autoriza

- Reescrita de qualquer `.ps1` existente
- Implementação de `TEIA-NeuroPlanner-v0190.ps1`
- Movimentação ou reorganização de arquivos
- Novos opcodes além dos já provados (D1–D3)
- Qualquer execução de código

Este documento fecha a fase arqueológica e define as condições precisas para a próxima fase. A implementação começa quando o operador autorizar explicitamente P1.

---

*Documento gerado em 2026-05-27. Encerra o ciclo de arqueologia iniciado em v0.18.0.*  
*O próximo ciclo começa com `TEIA-NeuroPlanner-v0190.ps1` em modo read-only.*
