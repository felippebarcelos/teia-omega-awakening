# TEIA Research Frontier — Motor de Tração AION-RISPA NDC
**Protocolo P38.0 | Data:** 2026-06-02
**Motor:** AION Transversal v2.0.0 + Adaptive Archive Router v1.0.0

> *"A fronteira da pesquisa é onde a física da informação encontra a ontologia do armazenamento."*

---

## §1 — Descobertas Confirmadas

### 1.1 Honestidade Entrópica (Pass-Through)

**Enunciado:** Para dados de alta entropia (UUID, timestamps únicos, dados aleatórios), a TEIA não força compressão.
O Roteador Adaptativo emite veredito correto: Concat+Brotli vence em tamanho para N pequeno.

**Prova empírica:** Corpus30 (N=30, EventID UUID, Timestamps únicos):
- Concat+Brotli = 649.2 KB (referência)
- TEIA = 660.7 KB (apenas +1.8%)
- N* = 10 — atingido para N=30; TEIA vence Brotli/arquivo mas não Concat

**Invariante derivada:** A pass-through é uma vitória do sistema de decisão, não uma falha da TEIA.

---

### 1.2 Massa Crítica N* — Fórmula Canônica

**Enunciado:** Existe um ponto N* onde a TEIA supera o Brotli/arquivo em tamanho total:

```
TEIA_total(N)   = overhead_fixo + N × seed_medio
Brotli_total(N) = N × brotli_medio

N* = ceil(overhead_fixo / (brotli_medio - seed_medio))
```

**Condição de existência:** `brotli_medio > seed_medio` — o dicionário compartilhado deve produzir seeds menores que Brotli individual.

**Valores medidos (P36.0):**

| Corpus | overhead_fixo | seed_medio | brotli_medio | delta_por_arquivo | N* |
|---|---:|---:|---:|---:|:---:|
| Corpus30 (Alta Entropia) | 5.928 B | 21.83 KB | 22.42 KB | 0.59 KB | 10 |
| Apache CLF Real | 4.039 B | 9.60 KB | 9.87 KB | 0.27 KB | 15 |

---

### 1.3 Roteador Triplo Adaptativo — Matriz de Vereditos

**Enunciado:** Para qualquer corpus homogêneo (schema único), três candidatos cobrem todas as combinações de objetivo:

| Objetivo | N < N* | N >= N* |
|---|---|---|
| Size | Concat+Brotli | Concat+Brotli (ainda vence LZ77 cross-file) |
| Latency | Brotli/arquivo ou TEIA | TEIA |
| Balanced | Brotli/arquivo | TEIA |

**Propriedade provada:** Concat+Brotli NUNCA vence em Latency (O(N) penalidade cresce com N).

---

### 1.4 Armazenamento como Computação — Redefinição Ontológica

**Enunciado:** Um arquivo TEIA não é um blob comprimido — é um programa determinístico:

```
arquivo_original = TeiaMasterDecoder.Decode(schema, dictCols, seed.bin)
```

O disco armazena código (Master Grammar + decoder C# JIT) e parâmetros (seed.bin).
A reconstrução é execução, não descompressão.

**Implicação:** O custo marginal por arquivo N+1 tende a zero bytes de overhead fixo.
Para N → infinito: overhead_fixo / N → 0; cada arquivo ocupa apenas seed_medio bytes.

---

## §2 — Hipóteses Ativas

### H-01: UVM Universal Limitless (Vocabulário Universal de Mapeamento)

**Hipótese:** Existe uma gramática mestre universal que, dado qualquer conjunto de arquivos com schema
idêntico, extrai um vocabulário suficientemente compacto para que o delta por arquivo seja sempre positivo
(brotli_medio - seed_medio > 0), independentemente da entropia do domínio.

**Estado atual:** Refutada parcialmente — Corpus30 mostra que colunas UUID/timestamp puro não dicionarizam.
Apenas colunas de cardinalidade finita (Action, ErrorCode, Region) produzem delta positivo.

**Experimento necessário:** Medir N* em função da razão `colunas_dict / colunas_total` para corpora
com diferentes perfis de cardinalidade. Hipótese refinada: N* é função da densidade de cardinalidade.

---

### H-02: Gatekeeper Autossintetizante (Aprendizado Contínuo)

**Hipótese:** Um Gatekeeper que aprende a distribuição de N* por domínio pode pre-rotear sem medir,
acelerando o tempo de decisão de ~2 minutos (compressão real) para <1 ms (inferência simbólica).

**Mecanismo proposto:**
1. Offline: medir N* para 100 corpora representativos por domínio
2. Construir mapa `(schema_fingerprint, entropia_estimada, N) → veredito`
3. Online: lookup O(1) no mapa sem compressão real

**Risco identificado:** Generalização incorreta para domínios não vistos.
Mitigação: fallback para compressão real quando confiança < threshold.

---

### H-03: Procedural-First Storage (Inversão do Paradigma)

**Hipótese:** Para N suficientemente grande (N > 1000), o SSD/RAM armazenam apenas algoritmos
(Master Grammar + decoder), enquanto o HDD armazena apenas seeds (payload puro).
Nenhum arquivo "bruto" existe em disco — apenas seeds + código.

**Estado:** Hipótese arquitetural — não testada empiricamente.

**Experimento necessário:** Simular repositório de 10.000 logs com TEIA e medir:
- Tamanho total em disco vs. Brotli/arquivo
- Tempo de acesso aleatório ao arquivo i (deve ser O(1) independente de N)
- Tempo de rebuild completo do corpus (deve ser O(N) mas com constante pequena)

---

## §3 — Paradoxos Abertos

### P-01: Limite da Representabilidade

**Paradoxo:** O Corpus30 tem "alta entropia" por definição (UUID, timestamps únicos).
Mas UUID v4 tem estrutura oculta: versão (bits 12-15), variante (bits 62-63), e fonte (gerador PRNG).
Se um modelo neuro-simbólico offline inferir essa estrutura, o seed poderia ser menor que o estimado.

**Questão aberta:** Existe ordem escondida em todo corpus "de alta entropia" que ferramentas
puramente estatísticas (Brotli/LZMA) não detectam mas raciocínio simbólico detecta?

**Implicação se verdadeiro:** N* para UUIDs poderia ser muito menor que o medido empiricamente.
A TEIA com módulo neuro-simbólico poderia vencer Brotli em corpora hoje considerados incompressíveis.

---

### P-02: Compressão vs. Simulação

**Paradoxo:** Quando o seed se torna suficientemente abstrato (ex: "este arquivo é uma simulação
de log Apache com distribuição X, entropia Y, padrão Z"), a TEIA deixa de ser um compressor
e passa a ser um simulador de dados.

**Questão aberta:** Existe um limiar onde o seed descreve uma *família* de arquivos plausíveis,
não um arquivo específico? Se sim, a reconstrução exata (Write==Read) é garantida?

**Invariante a preservar:** SHA-256(reconstituído) == SHA-256(original) em qualquer cenário.
O paradoxo é: como manter essa invariante quando o seed é abstrato demais?

---

### P-03: Custo Cognitivo vs. Custo Físico

**Paradoxo:** O decoder C# JIT tem custo de compilação ~200 ms por sessão (medido em P33.1).
Para N=1 arquivo, esse overhead torna a TEIA 200x mais lenta que Brotli/arquivo em acesso.
Para N=1000 arquivos na mesma sessão, o overhead é amortizado: 200 ms / 1000 acessos = 0.2 ms/acesso.

**Questão aberta:** Qual o modelo de custo correto — por sessão ou por arquivo?
Em data centers (processos de longa vida), o custo cognitivo se amortiza.
Em lambdas/serverless (cold start por invocação), a TEIA perde mesmo para N grande.

**Experimento necessário:** Medir latência em modo cold-start vs. warm-start para N variável.

---

## §4 — Experimentos Futuros

### E-01: Benchmark Multi-Domínio (PRIORIDADE MÁXIMA)

**Objetivo:** Medir N* e vereditos do Roteador em pelo menos 4 domínios radicalmente divergentes:

| Domínio | Tipo de Dados | Hipótese N* | Schema |
|---|---|:---:|---|
| Logs estruturados | Apache CLF, Nginx, Syslog | 10–20 | Repetitivo, baixa cardinalidade |
| Código-fonte iterativo | commits sucessivos de .py/.ps1 | 5–15 | Alta estrutura, baixa entropia |
| Binários pesados | DLLs, .exe portáteis | nunca | Alta entropia, sem schema |
| Métricas de série temporal | CPU%, RAM%, latência ms | 3–8 | Cardinalidade muito baixa |

**Script a criar:** `Benchmark-MultiDomain.ps1`
- Coleta corpora de 4 domínios (geração sintética determinística com seed de data)
- Executa Roteador Adaptativo em todos os objetivos para cada domínio
- Mede N* real para cada combinação domínio × objetivo
- Gera relatório comparativo `TEIA_MULTIDOMAIN_BENCHMARK_REPORT.md`
- **Invariante:** idempotente (Write==Read); re-execução produz resultado idêntico

**Delta sempre por extenso** (nunca símbolo matemático) em código, comentários e documentação.

---

### E-02: Integração Neuro-Simbólica Offline

**Objetivo:** Testar se um LLM local (Phi-3 mini ou Mistral 7B via llama.cpp) consegue inferir
estrutura oculta em colunas UUID/timestamp, reduzindo N* abaixo do valor estatístico.

**Protocolo:**
1. LLM analisa amostra de 100 valores de coluna UUID e descreve estrutura inferida
2. TEIA usa essa descrição como dicionário simbólico adicional
3. Medir N* com e sem inferência LLM — delta deve ser negativo (N* menor com LLM)

**Invariante crítica:** LLM age apenas como planejador heurístico.
O determinismo UVM (SHA-256 Write==Read) é isolado da inferência LLM.

---

### E-03: Idempotência de Autocorreção (Write==Read Sob Falha Induzida)

**Objetivo:** Validar que a Master Grammar canônica guia a própria reconstrução mesmo após
falhas induzidas em bits do seed.

**Protocolo:**
1. Forjar corpus com TEIA, obter `master_grammar` + `seed.bin`
2. Induzir N bits de erro aleatório no `seed.bin` (N = 1, 10, 100)
3. Tentar reconstrução — medir taxa de detecção vs. correção
4. Verificar: SHA-256(reconstituído) == SHA-256(original) para N=1?

**Hipótese:** Para N=1 bit de erro, a Master Grammar detecta a anomalia via validação de schema.
Para N>threshold, a reconstrução falha com erro explícito (não silencioso).

**Invariante a provar:** Falha deve ser barulhenta, não silenciosa.
Zero corrupção silenciosa de dados é um axioma não negociável da TEIA.

---

## Mapa de Dependências

```
E-01 (Benchmark Multi-Domínio)
  └── depende de: TEIA-Archive-Router.ps1 v1.0.0 [DISPONÍVEL]
  └── depende de: TEIA-AION-Transversal.ps1 v2.0.0 [DISPONÍVEL]
  └── produz: corpus sintético determinístico por domínio [A CRIAR]
  └── produz: TEIA_MULTIDOMAIN_BENCHMARK_REPORT.md [A CRIAR]

E-02 (Neuro-Simbólica Offline)
  └── depende de: E-01 [resultado de N* por domínio necessário]
  └── depende de: llama.cpp local [NÃO DISPONÍVEL — hardware constraint i3-10100F 8GB]
  └── status: bloqueado até hardware upgrade ou modelo quantizado 2-bit

E-03 (Autocorreção Write==Read)
  └── depende de: TEIA-AION-Transversal.ps1 v2.0.0 [DISPONÍVEL]
  └── independente de E-01 — pode executar em paralelo
  └── produz: prova formal de detecção de corrupção [A CRIAR]
```

---

## Próximo Passo Imediato

**E-01 — `Benchmark-MultiDomain.ps1`** é o experimento com maior retorno de informação:
- Usa infraestrutura já disponível (Router + AION)
- Produz dados para validar ou refutar H-01 (UVM Universal Limitless)
- Mapeia o espaço de vitórias da TEIA por domínio de dados
- Não requer hardware adicional

**Primeira iteração:** 3 domínios (logs, código-fonte, série temporal).
Binários pesados tratados como caso de controle (hipótese: TEIA nunca vence).

---

*TEIA Research Frontier v1.0 | Protocolo P38.0 | 2026-06-02*
