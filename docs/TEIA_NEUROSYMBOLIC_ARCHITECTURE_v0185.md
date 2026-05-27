# TEIA — Arquitetura Neuro-Simbólica Procedural
**Versão:** 0.18.5  
**Data:** 2026-05-27  
**Classificação:** Documento Arquitetural Formal — Teoria e Fundamentos  
**Status:** Consolidação Histórica (teoria; implementação futura)

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Camada Executor — O Músculo](#2-camada-executor--o-músculo)
3. [Camada Planner — O Cérebro Neuro-Simbólico](#3-camada-planner--o-cérebro-neuro-simbólico)
4. [Diagnóstico Histórico](#4-diagnóstico-histórico)
5. [Diagrama de Fluxo da Arquitetura](#5-diagrama-de-fluxo-da-arquitetura)
6. [Glossário Rigoroso](#6-glossário-rigoroso)
7. [Implicações Operacionais](#7-implicações-operacionais)

---

## 1. Visão Geral

A arquitetura neuro-simbólica da TEIA-Ω é um sistema de duas camadas com responsabilidades estritamente separadas:

- **Executor (UVM/PowerShell):** camada matemática determinística; transforma seeds + recipes em artefatos verificáveis por SHA-256.
- **Planner (LLM/Raciocínio Simbólico):** camada semântica probabilística; analisa estrutura, sintetiza recipes e escolhe opcodes com heurísticas de Minimum Description Length (MDL).

A separação entre estas camadas não é opcional — ela é a propriedade fundamental que torna o sistema auditável, reproducível e escalável para hardware modesto (i3-10100F, 8 GB RAM). Qualquer tentativa de mesclar as responsabilidades degrada ambas as camadas.

---

## 2. Camada Executor — O Músculo

### 2.1 Definição e Responsabilidade

O Executor é a camada de execução determinística. Dado um par `(seed, recipe)`, o Executor produz um único artefato de saída — e esse artefato é sempre o mesmo para entradas idênticas. O Executor não raciocina; ele obedece.

Implementações existentes: UVM (Universal Virtual Machine procedural) e os runners PowerShell que materializam `plan.ops`.

### 2.2 DSL `plan.ops`

`plan.ops` é a linguagem de descrição de procedimentos do Executor. Cada instrução (opcode) é:

- **Atômica:** produz um efeito único e bem definido.
- **Idempotente:** re-execução com os mesmos parâmetros produz resultado idêntico.
- **Verificável:** cada opcode gera ou consome hashes SHA-256 rastreáveis.

Exemplos de opcodes canônicos: `EMIT`, `TILE`, `RLE_DECODE`, `PATTERN_GEN`, `MERGE_BUNDLE`, `VALIDATE_SHA`.

### 2.3 Canonicalização Rígida

O Executor opera sobre representações canônicas para eliminar ambiguidade:

- **JSON canônico:** `sort_keys=True, ensure_ascii=False, separators=(',',':')` (Python); equivalente `To-CanonicalJson` (PowerShell).
- **Encoding:** UTF-8 sem BOM em todos os artefatos de texto.
- **Hashing:** SHA-256 em streaming com blocos ≥ 1 MiB; nenhuma outra função de hash é aceita como identidade de artefato.

### 2.4 Determinismo e Validação SHA-256

O Executor é **cego semanticamente**: não interpreta o conteúdo dos dados, apenas os transforma segundo a recipe. Essa cegueira é uma propriedade de design, não uma limitação. Ela garante que:

1. O resultado seja previsível e verificável por qualquer observador que possua `(seed, recipe)`.
2. A validação SHA-256 seja suficiente para atestar restauração fiel — sem inspeção de conteúdo.
3. O Executor possa rodar em hardware arbitrário sem dependência de modelos ou estado externo.

**Invariante absoluto:** se `SHA256(artefato_restaurado) == SHA256(artefato_original)`, a restauração é perfeita. Não há outro critério de verdade no Executor.

### 2.5 Estrutura CAS Subjacente

O Executor opera sobre Content-Addressable Storage (CAS):

```
mem\obj\<aa>\<bb>\<cc...>  ← objetos endereçados pelo SHA-256 completo
fractal_index.json          ← manifesto: hash + seed + tamanho + período
.fractal_delta*.json        ← delta manifests: hash/seed/tamanho mínimo
```

Bundles Merkle: concatenação canônica de hashes filhos → hash pai. A árvore de hashes é a única estrutura de verificação aceita.

---

## 3. Camada Planner — O Cérebro Neuro-Simbólico

### 3.1 Definição e Responsabilidade

O Planner é a camada de raciocínio semântico. Sua entrada é um arquivo bruto (ou conjunto de artefatos); sua saída é uma **Recipe** — uma sequência de opcodes com parâmetros que, quando executada pelo Executor, reconstrói o artefato de forma verificável.

O Planner não executa transformações sobre dados. Ele raciocina sobre estrutura, padrões e semântica para produzir a instrução mais compacta e fielmente reconstrutiva.

### 3.2 Percepção Estrutural

O Planner analisa o artefato bruto buscando regularidades exploráveis:

- **Repetição espacial:** blocos idênticos ou quasi-idênticos (candidatos a `TILE`, `RLE_DECODE`).
- **Padrões paramétricos:** sequências geráveis por função matemática com parâmetros compactos (candidatos a `PATTERN_GEN`).
- **Hierarquia de granularidade:** a que resolução o padrão é mais compacto — pixel, bloco 8×8, linha, frame?
- **Entropia local:** regiões de alta entropia resistem à compressão procedural; o Planner as reconhece e as delega ao CAS bruto (sem tentar forçar procedimentalização).

### 3.3 Abstração Semântica

Percepção estrutural é necessária, mas não suficiente. O Planner aplica **abstração semântica**: a capacidade de reconhecer que padrões estruturalmente distintos pertencem à mesma classe semântica.

Exemplos:
- Uma imagem de gradiente horizontal e uma de gradiente vertical são estruturalmente diferentes, mas semanticamente equivalentes sob a classe `linear_gradient(axis, start_color, end_color)`.
- Um texto repetido com variações de case é estruturalmente ruidoso, mas semanticamente é `template(base, variações)`.

Sem abstração semântica, o Planner produz recipes excessivamente literais — longas, frágeis e sem capacidade de generalização.

### 3.4 Recipe Synthesis — Criação de Receita

A síntese de recipe é o output central do Planner. Uma recipe bem formada:

1. **É mais curta que o artefato original** (caso contrário, o CAS bruto é preferível).
2. **É completamente especificada** — sem ambiguidade de interpretação para o Executor.
3. **É composta por opcodes do vocabulário canônico** — não por código ad-hoc.
4. **Inclui o hash de verificação** do artefato que deve resultar de sua execução.

A síntese envolve busca no espaço de recipes possíveis. O Planner usa heurísticas para tornar essa busca tratável.

### 3.5 Heurísticas MDL para Escolha de Opcodes

O Planner usa o princípio de **Minimum Description Length (MDL)** como critério de seleção de opcode:

> A melhor recipe é aquela que minimiza `len(recipe) + len(resíduo_não_representado)`.

Na prática:
- Opcodes de alta compressão (ex: `PATTERN_GEN` para fractais) são preferidos quando o ganho for ≥ threshold configurável.
- Opcodes literais (ex: `EMIT_RAW`) são usados quando a região tem alta entropia e não comprime proceduralmente.
- Opcodes compostos (macro-opcodes) são sintetizados quando um padrão se repete em múltiplos artefatos — amortizando o custo de descrição.

---

## 4. Diagnóstico Histórico

### 4.1 O Erro de Arquitetura que Não Era um Erro

Durante as fases v0.1–v0.17 da TEIA, o sistema operava com **apenas o Executor visível**. O PowerShell, os runners, a UVM — toda a engenharia estava na camada muscular. O Planner existia, mas era **implícito e externo**: era o LLM (o próprio Claude) ou o operador humano (Felippe) descobrindo manualmente a recipe a partir da análise do artefato.

Isso não era um bug; era uma **arquitetura de duas camadas com apenas uma camada formalizada**.

### 4.2 Registro Canônico do Diagnóstico

> **O LLM era o Planner implícito histórico.**
>
> O PowerShell sozinho não gera recipes semanticamente úteis. Dada uma imagem arbitrária, o runner PowerShell não sabe que ela é um fractal, um gradiente, uma foto, ou ruído puro — e portanto não sabe qual opcode minimiza a description length. Ele executa cegamente o que lhe é dado.
>
> As seeds minúsculas que demonstravam compressão procedural dependiam de **conhecimento prévio do domínio** — o operador (humano ou LLM) sabia que o artefato era gerado por `PATTERN_GEN` porque havia visto o processo de geração. Em produção, com artefatos arbitrários, esse conhecimento não está disponível sem um Planner explícito.

### 4.3 Consequências Operacionais do Diagnóstico

| Capacidade | Estado sem Planner explícito | Estado com Planner explícito |
|------------|------------------------------|------------------------------|
| Compressão de artefatos gerados proceduralmente | Funcional (domínio conhecido) | Funcional + auditável |
| Compressão de artefatos arbitrários (fotos, docs) | Inviável sem intervenção humana | Viável (análise estrutural automatizada) |
| Generalização para novos domínios | Requer reescrita manual de recipes | Requer calibração de heurísticas MDL |
| Auditabilidade do processo de compressão | Parcial (Executor auditável; Planner opaco) | Total (ambas as camadas formalizadas) |

### 4.4 O Que Permanece Válido

O diagnóstico não invalida o trabalho anterior. O Executor — a UVM, os opcodes canônicos, a validação SHA-256, a estrutura CAS, os manifests Merkle — é correto, robusto e permanece como base da arquitetura. O Planner implícito (LLM/humano) produziu recipes reais que geraram provas reais. O que muda é a **formalização** do Planner como camada explícita, auditável e eventualmente automatizável.

---

## 5. Diagrama de Fluxo da Arquitetura

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    ARQUITETURA NEURO-SIMBÓLICA TEIA-Ω                   │
└─────────────────────────────────────────────────────────────────────────┘

[Arquivo Bruto]
     │
     ▼
┌──────────────────────────────────┐
│   ANÁLISE ESTRUTURAL / PLANNER   │  ← Camada Neuro-Simbólica
│                                  │
│  · Percepção de padrões          │
│  · Abstração semântica           │
│  · Heurísticas MDL               │
│  · Classificação de entropia     │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│       MODELO SEMÂNTICO           │  ← Representação interna do Planner
│                                  │
│  · Classe do artefato            │
│  · Parâmetros dominantes         │
│  · Regiões de alta/baixa entropia│
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│   RECIPE PROCEDURAL / plan.ops   │  ← Output do Planner; Input do Executor
│                                  │
│  PATTERN_GEN(params)             │
│  TILE(block, n, m)               │
│  RLE_DECODE(runs)                │
│  EMIT_RAW(hash_ref)              │
│  VALIDATE_SHA(expected_hash)     │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│             SEED                 │  ← (recipe + hash_original) compactado
│                                  │
│  Mínima representação suficiente │
│  para restauração determinística │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│  EXECUTOR DETERMINÍSTICO / UVM   │  ← Camada Muscular
│                                  │
│  · Executa plan.ops opcode a op  │
│  · Sem estado externo            │
│  · Sem raciocínio semântico      │
│  · Produz artefato byte-a-byte   │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│   RESTORE SHA-256 VALIDADO       │  ← Prova de fidelidade
│                                  │
│  SHA256(saída) == SHA256(entrada) │
│  → Restauração perfeita          │
│                                  │
│  SHA256(saída) ≠ SHA256(entrada) │
│  → Falha auditável; recipe inválida│
└──────────────────────────────────┘
```

**Fluxo de compressão (esquerda→direita, resumido):**

```
[Arquivo Bruto] → [Análise Estrutural / Planner] → [Modelo Semântico]
    → [Recipe Procedural / plan.ops] → [Seed]
    → [Executor Determinístico / UVM] → [Restore SHA-256 Validado]
```

---

## 6. Glossário Rigoroso

### Procedural Seed

**Definição:** Representação mínima suficiente para a restauração determinística de um artefato. Uma Procedural Seed contém, no mínimo: (a) a recipe `plan.ops` que reconstrói o artefato, e (b) o hash SHA-256 do artefato original para validação pós-restauração. Opcionalmente, inclui metadados de proveniência (período, tamanho original, classe semântica).

**Propriedade central:** Uma Procedural Seed é útil se e somente se `len(seed) < len(artefato_original)`. Se a seed for maior ou igual ao artefato, o CAS bruto é preferível.

**Não confundir com:** random seed (entropia inicial para PRNG) — a Procedural Seed é determinística e não estocástica.

---

### Recipe

**Definição:** Sequência ordenada de macro-opcodes com parâmetros, escrita em `plan.ops`, que especifica completamente como o Executor deve reconstruir um artefato a partir de primitivas. Uma Recipe é o output do Planner e o input do Executor.

**Propriedades obrigatórias:** completude (nenhuma etapa implícita), idempotência (re-execução produz resultado idêntico), verificabilidade (inclui `VALIDATE_SHA` ao final).

**Analogia:** uma Recipe é para o Executor o que um programa é para uma CPU — uma sequência de instruções que produz um estado determinado a partir de um estado inicial.

---

### Macro-Opcode

**Definição:** Instrução de alto nível no vocabulário `plan.ops` que encapsula uma transformação semanticamente coesa. Um Macro-Opcode pode desdobrar-se internamente em múltas operações primitivas no Executor, mas é tratado como unidade atômica no nível da Recipe.

**Exemplos:** `PATTERN_GEN(type, params)` gera uma estrutura completa a partir de parâmetros; `TILE(source_hash, nx, ny)` replica um bloco sem armazenar N cópias; `RLE_DECODE(runs)` expande uma representação RLE compacta.

**Critério de criação:** um novo Macro-Opcode é justificado quando um padrão aparece em ≥ 3 artefatos distintos e sua descrição como primitivo seria mais longa que como macro.

---

### Planner

**Definição:** Componente responsável pela análise estrutural e semântica de artefatos e pela síntese de Recipes. O Planner opera no espaço simbólico (padrões, classes, heurísticas) e não manipula bytes diretamente. Sua saída é sempre uma Recipe; nunca um artefato transformado.

**Implementações históricas:** LLM (Claude) como Planner implícito; operador humano como Planner manual. **Estado atual:** Planner ainda não formalizado como componente de software autônomo.

**Restrição:** o Planner não deve ter acesso de escrita ao CAS. Ele apenas descreve como construir; o Executor constrói.

---

### Semantic Reconstruction

**Definição:** Processo de recuperação de um artefato a partir de sua Procedural Seed, no qual o artefato resultante é semanticamente fiel ao original — verificado por SHA-256 exato. O adjetivo "semântica" indica que a fidelidade é de conteúdo (bits idênticos), não meramente estrutural ou visual.

**Distinção:** "reconstrução aproximada" (lossy) não é Semantic Reconstruction no vocabulário TEIA. Qualquer divergência de hash é falha de restauração, independentemente da semelhança perceptual.

---

### Deterministic Restore

**Definição:** Execução do Executor sobre uma Procedural Seed que produz, invariavelmente, o mesmo artefato — em qualquer máquina, em qualquer momento, dado o mesmo ambiente de execução (versão dos opcodes, encoding). Deterministic Restore é a propriedade que torna o sistema auditável por terceiros.

**Dependência:** Deterministic Restore requer que (a) a Recipe seja completamente especificada, (b) os opcodes sejam implementados de forma canônica, e (c) o Executor não dependa de estado externo não declarado na Seed.

---

### Entropy Honesty

**Definição:** Princípio de design que proíbe o Planner de reivindicar compressão onde não há. Um artefato de alta entropia (dados aleatórios, dados cifrados, fotos naturais sem padrão dominante) deve ser armazenado como CAS bruto — sem tentar forçar uma Recipe que seria maior que o artefato.

**Formulação:** `se len(melhor_recipe_encontrada) ≥ len(artefato_original)`, então `artefato → CAS_bruto`; nenhuma Recipe é emitida.

**Motivação:** claims de compressão não verificáveis destroem a credibilidade do sistema. Entropy Honesty mantém o princípio `Prova antes de afirmação` do TEIA-Ω.

---

## 7. Implicações Operacionais

### 7.1 O Que Pode Ser Feito Hoje (sem Planner formalizado)

- Executor completo e funcional: recipes escritas manualmente ou pelo LLM são executáveis e verificáveis.
- Domínios procedurais conhecidos (fractais, gradientes, padrões geométricos): recipes são sintetizáveis com intervenção do operador.
- Validação SHA-256 pós-restauração: funcional e auditável.
- CAS bruto para artefatos de alta entropia: funcional.

### 7.2 O Que Requer Planner Formalizado

- Compressão de artefatos arbitrários sem conhecimento prévio do domínio.
- Síntese automatizada de recipes em lote (ex: Prova P1 — pasta grande de fotos/vídeos).
- Generalização de Macro-Opcodes a partir de artefatos observados.
- Métricas de compressão reproduzíveis sem intervenção manual.

### 7.3 Caminho de Implementação (Ordenado por Dependência)

1. Formalizar vocabulário completo de `plan.ops` com semântica precisa por opcode.
2. Implementar analisador estrutural básico (detecção de repetição, entropia local).
3. Implementar síntese de recipe para domínios procedurais canônicos (fractais, gradientes).
4. Integrar heurísticas MDL para seleção automática de opcode.
5. Expandir para artefatos arbitrários com fallback para CAS bruto (Entropy Honesty).

### 7.4 O Que Este Documento Não Autoriza

- Reescrita de `.ps1` existentes.
- Implementação de qualquer componente do Planner.
- Alteração de qualquer artefato do CAS ou dos manifests existentes.

Este documento é teoria consolidada. Implementação segue cronograma separado, a partir da Prioridade 1 das pendências críticas (CLAUDE.md §8).

---

*Documento gerado em 2026-05-27. Próxima revisão obrigatória: após implementação do Planner v0.1 ou publicação de benchmark P1.*
