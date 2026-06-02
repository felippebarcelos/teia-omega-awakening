# TEIA AION Transversal — Adaptive Archive Router Report P36.0
**Protocolo P36.0 — Supervisor de Data Centers**
**Data:** 2026-06-02

---

## Introducao: O Supervisor

O P35.0 revelou empiricamente que o Brotli individual e competitivo para N pequeno.
O P36.0 responde a essa realidade criando o **TEIA Archive Router**: um supervisor autonomo que
mede os tres candidatos com compressao real (CompressionLevel.SmallestSize) e emite o
veredito otimo para cada combinacao de corpus + Objetivo de Negocio.

**Candidatos avaliados:**
- **A — TEIA Transversal (AION):** Master Grammar + C# JIT decoder, acesso O(1)
- **B — Brotli/arquivo:** cada arquivo comprimido individualmente, acesso O(1)
- **C — Concat+Brotli (tar.br):** corpus concatenado + Brotli, acesso O(N)

**Scoring:** pontuacao normalizada [0=melhor, 1=pior] por dimensao, ponderada por objetivo.
Concat+Brotli recebe penalidade multiplicativa em acesso e incremental proporcional a N,
refletindo o crescimento linear do custo O(N) em producao.

---

## Corpora Avaliados

| Corpus | N | Fonte | Entropia |
|---|---:|---|---|
| Corpus30 | 30 | Sintetico — New-Corpus30HighEntropy | Alta (EventID UUID, Timestamps unicos, UserIDs) |
| Corpus_Transversal | 10 | Real — Apache CLF (Elastic examples) | Media (IP, Resource variaveis; Method/Status repetitivos) |

---

## Corpus: Corpus_Transversal (Apache CLF Real, N=10)

**N =** 10 arquivos | **Tamanho original:** 934.4 KB
**Schema:** `IP,Ident,User,Date,Time,Method,Resource,Protocol,Status,Bytes`
**Colunas dicionarizadas (TEIA):** Ident, User, Date, Method, Protocol, Status

### Tamanho em Disco

| Candidato | Tamanho Total | vs Original | vs concat+Brotli |
|---|---:|:---:|:---:|
| TEIA | 100,0 KB | — | +35.4% |
| Brotli | 98,7 KB | — | +33.7% |
| **Concat** | 73,8 KB | — | 0% |

**Decomposicao TEIA:** overhead fixo = 4039 bytes (decoder + meta) |
seed medio = 9.6 KB/arq | Brotli medio = 9.87 KB/arq

### Latencia de Acesso Aleatorio

| Candidato | Latencia | Bytes lidos | Comportamento |
|---|---:|:---:|---|
| TEIA | 1 ms | 9.6 KB (seed.bin) | O(1) |
| Brotli | 0 ms | 9.87 KB (.br) | O(1) |
| Concat | 1 ms | 934.4 KB (corpus inteiro) | **O(N)** |

### Atualizacao Incremental

| Candidato | Latencia | Estrategia |
|---|---:|---|
| TEIA | 195 ms | Aplica Master Grammar existente → 1 novo seed.bin |
| Brotli | 124 ms | Comprime novo arquivo independentemente |
| Concat | 1560 ms | **Recomprime N+1 arquivos do zero (O(N))** |

### Scoreboard por Objetivo

| Objetivo | TEIA | Brotli | Concat | WINNER |
|---|:---:|:---:|:---:|---|
| Size | 1,000 | 0,950 | 0,000 | **Concat** |
| Latency | 0,006 | 0,000 | 1,000 | **Brotli** |
| Balanced | 0,357 | 0,332 | 0,650 | **Brotli** |

### Projecao: Massa Critica N*

#### Tamanho: TEIA vs Brotli/arquivo

```
TEIA_total(N) = 4039 B (overhead) + N x 9.6 KB (seed medio)
Brotli_total(N)   = N x 9.87 KB (Brotli medio)
Delta por arquivo = 0.27 KB
N* = ceil(4039 / (0.27 x 1024)) = 15
```

> **N* = 15 > N atual (10)**: TEIA ainda nao vence em tamanho. Requer N >= 15 arquivos.

#### Latencia: TEIA vs Concat+Brotli (acesso)

```
TEIA: O(1) -- 1 ms para qualquer N
Concat: O(N) -- 1 ms para N=10 => 0.1 ms/arquivo
N* (latencia) = 10
```

> Para N >= 10: TEIA acessa mais rapido que Concat+Brotli.

---

## Corpus: Corpus30 (Alta Entropia, N=30)

**N =** 30 arquivos | **Tamanho original:** 1768.3 KB
**Schema:** `EventID,Timestamp,UserID,IPAddress,Action,DurationMs,ErrorCode,Region,Thread,BytesIn`
**Colunas dicionarizadas (TEIA):** Action, ErrorCode, Region

### Tamanho em Disco

| Candidato | Tamanho Total | vs Original | vs concat+Brotli |
|---|---:|:---:|:---:|
| TEIA | 660,7 KB | — | +1.8% |
| Brotli | 672,5 KB | — | +3.6% |
| **Concat** | 649,2 KB | — | 0% |

**Decomposicao TEIA:** overhead fixo = 5928 bytes (decoder + meta) |
seed medio = 21.83 KB/arq | Brotli medio = 22.42 KB/arq

### Latencia de Acesso Aleatorio

| Candidato | Latencia | Bytes lidos | Comportamento |
|---|---:|:---:|---|
| TEIA | 0 ms | 21.83 KB (seed.bin) | O(1) |
| Brotli | 2 ms | 22.42 KB (.br) | O(1) |
| Concat | 11 ms | 1768.3 KB (corpus inteiro) | **O(N)** |

### Atualizacao Incremental

| Candidato | Latencia | Estrategia |
|---|---:|---|
| TEIA | 136 ms | Aplica Master Grammar existente → 1 novo seed.bin |
| Brotli | 79 ms | Comprime novo arquivo independentemente |
| Concat | 3023 ms | **Recomprime N+1 arquivos do zero (O(N))** |

### Scoreboard por Objetivo

| Objetivo | TEIA | Brotli | Concat | WINNER |
|---|:---:|:---:|:---:|---|
| Size | 0,493 | 1,000 | 0,000 | **Concat** |
| Latency | 0,001 | 0,018 | 1,000 | **TEIA** |
| Balanced | 0,173 | 0,375 | 0,650 | **TEIA** |

### Projecao: Massa Critica N*

#### Tamanho: TEIA vs Brotli/arquivo

```
TEIA_total(N) = 5928 B (overhead) + N x 21.83 KB (seed medio)
Brotli_total(N)   = N x 22.42 KB (Brotli medio)
Delta por arquivo = 0.59 KB
N* = ceil(5928 / (0.59 x 1024)) = 10
```

> **N* = 10 < N atual (30)**: TEIA ja vence Brotli/arquivo em tamanho neste corpus.

#### Latencia: TEIA vs Concat+Brotli (acesso)

```
TEIA: O(1) -- 0 ms para qualquer N
Concat: O(N) -- 11 ms para N=30 => 0.37 ms/arquivo
N* (latencia) = 1
```

> Para N >= 1: TEIA acessa mais rapido que Concat+Brotli.

---

## Conclusao P36.0: A Sabedoria do Supervisor

| Cenario | Recomendacao | Razao |
|---|---|---|
| Objetivo=Size, N pequeno (<20) | **Concat+Brotli** | Janela LZ77 compartilhada vence |
| Objetivo=Size, N grande (>N*) | **TEIA** | Overhead amortizado, seed < Brotli individual |
| Objetivo=Latency, qualquer N | **Brotli/arquivo ou TEIA** | Ambos O(1); concat nunca vence em latencia |
| Objetivo=Balanced, N pequeno | **Brotli/arquivo** | Melhor troca entre tamanho e velocidade |
| Objetivo=Balanced, N grande | **TEIA** | Overhead amortizado + O(1) + incremental eficiente |
| Schemas distintos | **Brotli/arquivo ou Concat+Brotli** | TEIA nao aplicavel |

**A derrota e uma vitoria do sistema de decisao:** quando o Roteador escolhe Brotli/arquivo ou
Concat+Brotli, ele esta aplicando a fisica da informacao de forma correta. O objetivo e sempre
servir o usuario com o melhor formato — nao defender a TEIA.

---
*TEIA Archive Router v1.0.0 | Protocolo P36.0 | 2026-06-02*
