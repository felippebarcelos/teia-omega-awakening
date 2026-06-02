# TEIA AION Transversal — Relatório Técnico P33.0→P33.2

**Data:** 2026-06-02  
**Protocolo:** P33.0 · P33.1 · P33.2  
**Motor:** TEIA-AION-Transversal.ps1 v2.0.0  
**Corpus:** 60 arquivos CSV diários — schema idêntico (8 colunas)  

---

## Configuração do Experimento

### Corpus
- **N:** 60 arquivos CSV com schema idêntico
- **Linhas por arquivo:** 3.000
- **Tamanho total original:** ~10,9 MB
- **Gerador:** `Fetch-TransversalData.ps1` — seed determinístico por data (`SHA-256("TEIA-$hostname-YYYY-MM-DD")`)
- **Schema:** `Date,Time,Action,StatusCode,Region,UserAgent,SessionDuration,BytesTransferred`
- **Colunas dicionarizadas (cardinalidade ≤ 50):** `Action`, `StatusCode`, `Region`, `DeviceType`

### Baseline Clássica
Todos os 60 arquivos concatenados em sequência e comprimidos com Brotli nível SmallestSize (nível 11).  
Resultado: um único blob opaco — acesso a qualquer arquivo individual requer descompressão de **todo** o corpus.

### Hardware
- CPU: Intel Core i3-10100F (4C/8T, 3.6 GHz base)
- RAM: 8 GB DDR4
- SO: Windows 11 Pro (PowerShell 7)

---

## P33.0 — Master Grammar: Forja e Integridade

**Objetivo:** extrair Master Grammar global e forjar 60 `.seed.bin` com verificação SHA-256.

### Resultado

| Métrica | Valor |
|---|---|
| Arquivos forjados | 60/60 |
| SHA-256 PASS | **60/60** |
| Baseline concat+Brotli | 2.247.476 bytes |
| TEIA total (60 seeds + meta + decoder) | 2.258.719 bytes |
| **Delta (Baseline − TEIA)** | **−11.243 bytes (TEIA usa 0,5% mais)** |
| Overhead/arquivo amortizado | ~141 bytes |

**Nota sobre o Delta:** a TEIA Transversal usa marginalmente mais espaço de armazenamento total que o concat+Brotli para N=60. Este custo é o **Índice Fractal** — o preço estrutural do acesso O(1) e da atualização incremental. Para N→∞, o overhead por arquivo converge a 0 bytes.

---

## P33.1 — Benchmark: O(1) vs O(N) na Atualização Incremental

**Objetivo:** medir custo real de adicionar 1 novo arquivo ao corpus.

| Operação | TEIA Incremental O(1) | Baseline O(N) recompressão | Speedup |
|---|---:|---:|:---:|
| Adicionar 1 arquivo | **497 ms** | **21.240 ms** | **42,7x** |
| Arquivos processados | 1 (novo seed.bin) | 61 (corpus inteiro) | — |

**Mecanismo TEIA O(1):** aplicar Master Grammar existente ao novo arquivo → gerar 1 seed.bin → pronto.  
**Mecanismo Baseline O(N):** descompressão + concatenação de 61 arquivos + recompressão Brotli SmallestSize.

---

## P33.2 — Master Decoder FastPath: C# JIT vs PowerShell vs Baseline

**Objetivo:** eliminar gargalo de CPU no acesso aleatório — substituir loop PowerShell por decoder C# nativo compilado JIT.

### Evolução do Gargalo de CPU

O gargalo identificado em P33.1: loop PowerShell puro iterando 3.000 linhas × 8 colunas = 24.000 iterações de dicionário por arquivo. Latência: ~350 ms.

**Solução P33.2:** classe estática `TeiaMasterDecoder` compilada JIT via `Add-Type -TypeDefinition`. A classe executa Brotli decompress + reconstituição CSV em CIL nativo.

```
Overhead de compilação JIT: 718 ms (pago 1× por sessão PowerShell)
Latência por decode subsequente: 2 ms
```

### Benchmark de Acesso Aleatório — Arquivo #50 de 60

| Cenário | Implementação | Latência (min 3 runs) | Bytes lidos | SHA-256 |
|---|---|---:|---:|:---:|
| A — PS cold | PowerShell puro, 1ª execução | 326 ms | 37.325 bytes | PASS |
| A-mem — PS warm | PowerShell puro, JIT PS aquecido | 356 ms | 37.325 bytes | PASS |
| **A-Fast — C# JIT** | **TeiaMasterDecoder nativo** | **2 ms** | **37.325 bytes** | **PASS** |
| B — Baseline O(N) | concat+Brotli, decompress inteiro | 86 ms | 2.236.233 bytes | — |

### Resultados Principais

| Comparação | Speedup | Interpretação |
|---|:---:|---|
| A-Fast vs Baseline | **43x mais rápido** | 2 ms vs 86 ms, lendo 60x menos bytes |
| A-Fast vs A-PS | **178x mais rápido** | Gargalo era o interpretador PS, não o algoritmo |
| TEIA incremental vs Baseline recompressão | **42,7x mais rápido** | O(1) vs O(N=61) |

### SHA-256 — Integridade Total

- P33.0 forja: **60/60 PASS**
- P33.2 A-Fast decode: **PASS** (hash idêntico ao original)

---

## Análise: O(1) vs O(N) — A Diferença Estrutural

| Propriedade | Baseline concat+Brotli | TEIA Transversal v2.0.0 |
|---|---|---|
| Reconstituir arquivo individual | O(N) — descomprime corpus inteiro | **O(1) — 1 seed.bin + master_meta** |
| Adicionar novo arquivo | O(N) — recriar corpus inteiro | **O(1) — 1 novo seed.bin** |
| Bytes lidos para acesso | O(N) — corpus inteiro | **O(1) — apenas seed do arquivo** |
| Overhead/arquivo (N→∞) | Constante por arquivo | **→ 0 bytes** |
| Paralelismo de decode | Impossível sem seek | **Trivial — seeds independentes** |

---

## Conclusões

1. **O acesso O(1) é real e verificável:** lê 37 KB em vez de 2,2 MB — 60x menos bytes.
2. **O C# JIT é decisivo:** a diferença 2ms vs 356ms não é algoritmo, é interpretador. CIL nativo elimina o gargalo.
3. **O custo do Índice Fractal é honesto:** TEIA usa 0,5% mais bytes que concat+Brotli para N=60. Este não é um artefato oculto — é declarado explicitamente.
4. **A atualização incremental escala:** O(1) para TEIA significa que o speedup cresce com N. Para N=1000, a baseline levaria ~21 s × (1000/60) ≈ 350 s. A TEIA: ~500 ms.

---

## Limitações Explícitas

- Delta de armazenamento: TEIA usa 0,5% mais espaço para N=60. O break-even cresce com N (N→∞ converge a zero).
- Schema idêntico obrigatório: todos os arquivos do corpus devem ter o mesmo cabeçalho CSV.
- Colunas com cardinalidade >50 não são dicionarizadas — tratadas como resíduo de alta entropia.
- Overhead de compilação JIT: 718 ms por sessão PowerShell (amortizado em produção).

---

*TEIA AION Transversal v2.0.0 | Protocolo P33.2 | 2026-06-02*
