# TEIA Adaptive Archive Router — Release Notes v6.0.0

**Data:** 2026-06-02
**Protocolo:** P36.0 · P37.0
**Motor:** TEIA Archive Router v1.0.0 + AION Transversal v2.0.0

---

## Declaração de Paradigma

> *"A TEIA não é sempre o melhor formato.*
> *A TEIA é o sistema que descobre qual formato deve vencer."*

A v6.0.0 encerra a fase compressora da TEIA e inaugura a fase **supervisora**.
O P35.0 revelou empiricamente que Brotli individual e Concat+Brotli vencem a TEIA para N pequeno.
Em vez de ignorar essa realidade, o P36.0 a incorporou: o Roteador Adaptativo mede os três candidatos
com compressão real e emite o veredito correto para cada cenário.

---

## O Supervisor: TEIA Archive Router v1.0.0

### Os Três Candidatos

| Candidato | Mecanismo | Acesso | Incremental |
|---|---|:---:|:---:|
| **A — TEIA Transversal (AION)** | Master Grammar + C# JIT decoder | O(1) | O(1) |
| **B — Brotli/arquivo** | Cada arquivo comprimido individualmente | O(1) | O(1) |
| **C — Concat+Brotli (tar.br)** | Corpus concatenado + Brotli único | **O(N)** | **O(N)** |

### Os Três Objetivos de Negócio

| Objetivo | Peso Tamanho | Peso Acesso | Peso Incremental |
|---|:---:|:---:|:---:|
| `Size` | 100% | 0% | 0% |
| `Latency` | 0% | 70% | 30% |
| `Balanced` | 35% | 40% | 25% |

O scoring é normalizado [0 = melhor, 1 = pior] por dimensão. Concat+Brotli recebe
penalidade multiplicativa proporcional a N em acesso e incremental, refletindo o
crescimento linear O(N) em produção.

### A Projeção de Massa Crítica N*

O Roteador calcula matematicamente o ponto N* onde a TEIA supera o Brotli/arquivo em **tamanho**:

```
TEIA_total(N)  = overhead_fixo + N × seed_medio
Brotli_total(N) = N × brotli_medio

N* = ceil(overhead_fixo / (brotli_medio - seed_medio))
```

Quando `N >= N*`, a Master Grammar já amortizou seu overhead fixo e cada arquivo
ocupa menos bytes que seu equivalente Brotli individual.

---

## Resultados Medidos — Auditoria P36.0

Corpus: 2 corpora reais/sintéticos × 3 objetivos = 6 vereditos.

### Tabela de Decisão Completa

| Corpus | Objetivo | WINNER | Nota |
|---|---|---|---|
| Corpus30 (N=30, Alta Entropia) | Size | **Concat+Brotli** | LZ77 cross-file dominante |
| Corpus30 (N=30, Alta Entropia) | Latency | **TEIA** (0 ms) | O(1) vs O(N) = 0 ms vs 11 ms |
| Corpus30 (N=30, Alta Entropia) | Balanced | **TEIA** (score 0,173) | N* atingido (N*=10 < 30) |
| Apache CLF real (N=10) | Size | **Concat+Brotli** | Melhor em tamanho para N pequeno |
| Apache CLF real (N=10) | Latency | **Brotli/arquivo** (0 ms) | Margem mínima vs TEIA |
| Apache CLF real (N=10) | Balanced | **Brotli/arquivo** (score 0,332) | N*=15 ainda não atingido |

### Projeções N* por Corpus

| Corpus | N atual | N* (TEIA vs Brotli) | Status |
|---|:---:|:---:|---|
| Corpus30 (Alta Entropia) | 30 | 10 | ATINGIDO — TEIA já é menor |
| Apache CLF Real | 10 | 15 | Faltam 5 arquivos para TEIA ganhar em tamanho |

---

## Quando Usar Cada Método

| Cenário | Recomendação | Razão |
|---|---|---|
| Objetivo=Size, qualquer N | **Concat+Brotli** | Janela LZ77 compartilhada produz o menor blob |
| Objetivo=Latency, qualquer N | **Brotli/arquivo ou TEIA** | Ambos O(1) — Concat nunca vence em latência |
| Objetivo=Balanced, N < N* | **Brotli/arquivo** | Overhead TEIA ainda não amortizado |
| Objetivo=Balanced, N >= N* | **TEIA** | Overhead amortizado + O(1) + incremental eficiente |
| Schemas distintos | **Brotli/arquivo** | TEIA exige schema idêntico em todos os arquivos |
| N → ∞ | **TEIA** | Overhead por arquivo → 0 bytes; seeds menores que Brotli individual |

**A honestidade é a maior virtude da v6.0.0:** o Roteador declara cada vitória da baseline
como uma decisão correta do sistema, não como uma falha da TEIA.

---

## Conteúdo do Pacote v6.0.0

```
TEIA_ADAPTIVE_ARCHIVE_ROUTER_v6.0.0.zip
  adaptive_router_v6/
    audit-one-click-router.ps1          — orquestrador 1-click (2 corpora x 3 objetivos)
    TEIA-Archive-Router.ps1             — Roteador Adaptativo v1.0.0
    TEIA-AION-Transversal.ps1           — Motor AION Transversal v2.0.0
    Fetch-RealTransversalCorpus.ps1     — downloader Apache CLF real
    Fetch-TransversalData.ps1           — gerador corpus sintético
    TEIA_ADAPTIVE_ROUTER_REPORT_P36.md  — relatório de referência P36.0
```

---

## Demo em 1 Clique — v6.0.0

```powershell
# Pre-requisito: PowerShell 7+ no Windows. Conexão com internet para corpus real.
Expand-Archive TEIA_ADAPTIVE_ARCHIVE_ROUTER_v6.0.0.zip
pwsh -NoProfile -ExecutionPolicy Bypass -File .\adaptive_router_v6\audit-one-click-router.ps1
```

O script executa em ~2 minutos:

1. Gera Corpus30 (30 CSVs, alta entropia, EventID UUID + Timestamps únicos)
2. Baixa Corpus Transversal (10 CSVs, logs Apache CLF reais do Elastic examples)
3. Executa 6 permutações (2 corpora × 3 objetivos) com compressão Brotli real
4. Imprime tabela de decisão com vereditos + projeções N*

---

## Verificação de Integridade — v6.0.0

```powershell
(Get-FileHash .\TEIA_ADAPTIVE_ARCHIVE_ROUTER_v6.0.0.zip -Algorithm SHA256).Hash.ToLower()
# Esperado: 7f6732a218eb260f2f3c73ef29982fdcfeb073bd47e42334721210b99c031069
```

---

## Evolução da TEIA — Linha do Tempo

| Versão | Paradigma | Resultado Central |
|---|---|---|
| v1.3.0 | Compressor procedural | COVID +58.7% vs Brotli Optimal |
| v4.0.0 | Oráculo Gatekeeper | 0 Deltas negativos garantidos |
| v5.0.0 | Formato arquivístico O(1) | 43x acesso · 42,7x incremental · C# JIT |
| **v6.0.0** | **Supervisor Adaptativo** | **6/6 vereditos honestos · N* projetado matematicamente** |

---

*TEIA Adaptive Archive Router v6.0.0 | Protocolo P37.0 | 2026-06-02*
