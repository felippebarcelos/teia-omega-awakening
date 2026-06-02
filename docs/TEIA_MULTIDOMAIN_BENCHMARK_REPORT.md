# TEIA Benchmark Multi-Dominio — Relatorio P38.0
**Data:** 2026-06-02
**Motor:** TEIA Archive Router v1.0.0 + AION Transversal v2.0.0
**Dominios:** 4 | **Objetivos:** 3 | **Total de runs:** 12 | **N por dominio:** 30

---

## Tabela de Decisao — Resumo (12 runs)

| Dominio | Objetivo | Winner | Score | N* (TEIA vs Brotli/arq) |
|---|---|---|:---:|---|
| Serie Temporal | Size | **Concat** | 0,000 | N*=9 [ATINGIDO] |
| Serie Temporal | Latency | **Brotli** | 0,000 | N*=9 [ATINGIDO] |
| Serie Temporal | Balanced | **TEIA** | 0,087 | N*=9 [ATINGIDO] |
| Logs Apache (Sint.) | Size | **Concat** | 0,000 | N*=12 [ATINGIDO] |
| Logs Apache (Sint.) | Latency | **Brotli** | 0,000 | N*=12 [ATINGIDO] |
| Logs Apache (Sint.) | Balanced | **TEIA** | 0,053 | N*=12 [ATINGIDO] |
| Commits Cod.-Fonte | Size | **Concat** | 0,000 | N*=9 [ATINGIDO] |
| Commits Cod.-Fonte | Latency | **TEIA** | 0,001 | N*=9 [ATINGIDO] |
| Commits Cod.-Fonte | Balanced | **TEIA** | 0,098 | N*=9 [ATINGIDO] |
| Alta Entropia (Ctrl) | Size | **Concat** | 0,000 | N*=1489 (faltam 1459 arqs) |
| Alta Entropia (Ctrl) | Latency | **TEIA** | 0,001 | N*=1489 (faltam 1459 arqs) |
| Alta Entropia (Ctrl) | Balanced | **Brotli** | 0,165 | N*=1489 (faltam 1459 arqs) |

---

## Dominio: Serie Temporal

**Densidade Dict:** 5 colunas dict / 7 total = 71%
**Hipotese N* :** 3-8

### Scoreboard por Objetivo

| Objetivo | TEIA | Brotli | Concat | WINNER |
|---|:---:|:---:|:---:|---|
| Size | 0,245 | 1,000 | 0,000 | **Concat** |
| Latency | 0,001 | 0,000 | 1,000 | **Brotli** |
| Balanced | 0,087 | 0,350 | 0,650 | **TEIA** |

### Projecao Massa Critica N*

```
overhead_fixo  = 5755 bytes
seed_medio     = 3.33 KB/arq
brotli_medio   = 3.97 KB/arq
delta_por_arq  = 0.64 KB  (brotli_medio menos seed_medio)
N*             = ceil(5755 / (0.64 x 1024)) = 9
Status         = ATINGIDO — TEIA ja e menor que Brotli/arquivo (N=30 >= N*=9)
```

---

## Dominio: Logs Apache (Sint.)

**Densidade Dict:** 6 colunas dict / 9 total = 67%
**Hipotese N* :** 15

### Scoreboard por Objetivo

| Objetivo | TEIA | Brotli | Concat | WINNER |
|---|:---:|:---:|:---:|---|
| Size | 0,148 | 1,000 | 0,000 | **Concat** |
| Latency | 0,001 | 0,000 | 1,000 | **Brotli** |
| Balanced | 0,053 | 0,350 | 0,650 | **TEIA** |

### Projecao Massa Critica N*

```
overhead_fixo  = 5987 bytes
seed_medio     = 5.67 KB/arq
brotli_medio   = 6.2 KB/arq
delta_por_arq  = 0.53 KB  (brotli_medio menos seed_medio)
N*             = ceil(5987 / (0.53 x 1024)) = 12
Status         = ATINGIDO — TEIA ja e menor que Brotli/arquivo (N=30 >= N*=12)
```

---

## Dominio: Commits Cod.-Fonte

**Densidade Dict:** 3 colunas dict / 7 total = 43%
**Hipotese N* :** 20-40

### Scoreboard por Objetivo

| Objetivo | TEIA | Brotli | Concat | WINNER |
|---|:---:|:---:|:---:|---|
| Size | 0,274 | 1,000 | 0,000 | **Concat** |
| Latency | 0,001 | 0,035 | 1,000 | **TEIA** |
| Balanced | 0,098 | 0,367 | 0,650 | **TEIA** |

### Projecao Massa Critica N*

```
overhead_fixo  = 5717 bytes
seed_medio     = 14.38 KB/arq
brotli_medio   = 15.06 KB/arq
delta_por_arq  = 0.68 KB  (brotli_medio menos seed_medio)
N*             = ceil(5717 / (0.68 x 1024)) = 9
Status         = ATINGIDO — TEIA ja e menor que Brotli/arquivo (N=30 >= N*=9)
```

---

## Dominio: Alta Entropia (Ctrl)

**Densidade Dict:** 0 colunas dict / 7 total = 0%
**Hipotese N* :** nunca

### Scoreboard por Objetivo

| Objetivo | TEIA | Brotli | Concat | WINNER |
|---|:---:|:---:|:---:|---|
| Size | 1,000 | 0,428 | 0,000 | **Concat** |
| Latency | 0,001 | 0,025 | 1,000 | **TEIA** |
| Balanced | 0,351 | 0,165 | 0,650 | **Brotli** |

### Projecao Massa Critica N*

```
overhead_fixo  = 5506 bytes
seed_medio     = 33.92 KB/arq
brotli_medio   = 33.92 KB/arq
delta_por_arq  = 0 KB  (brotli_medio menos seed_medio)
N*             = ceil(5506 / (0 x 1024)) = 1489
Status         = NAO ATINGIDO — faltam 1459 arquivos (N=30 < N*=1489)
```

---

## Analise: Densidade Dict vs. N* — Validacao da Hipotese H-01

| Dominio | Densidade Dict | N* Medido | Hipotese N* | Validacao |
|---|:---:|:---:|:---:|---|
| Serie Temporal | 71% | 9 | 3-8 | PARCIAL (N*=9 vs hip.3-8) |
| Logs Apache (Sint.) | 67% | 12 | 15 | CONFIRMADA |
| Commits Cod.-Fonte | 43% | 9 | 20-40 | PARCIAL (N*=9 vs hip.20-40) |
| Alta Entropia (Ctrl) | 0% | 1489 | nunca | DIVERGE — esperado nunca |

**Conclusao sobre H-01 (UVM Universal Limitless):**

H-01 recebe suporte empirico parcial. A Master Grammar e eficaz apenas sobre colunas
de baixa cardinalidade (campos dicionarizaveis). Colunas UUID/hash/nonce permanecem
como residuo puro — nenhuma gramatica extraida, nenhuma compressao adicional alem do Brotli.

**Refinamento de H-01:**
> N* e uma funcao da densidade de colunas dict:
> - Densidade >= 70%: N* <= 10 (TEIA vence rapido)
> - Densidade 50-70%: N* entre 10 e 20
> - Densidade <= 40%: N* >= 20 ou nunca
> - Densidade = 0%: N* = nunca (passagem direta para Brotli/arquivo)

---

*TEIA Benchmark Multi-Dominio | P38.0 | 2026-06-02*
