# TEIA — Storage as Computation

**Transcendência Epistêmica Integrada Autossintetizante**  
**Versão atual:** v4.0.0-aion-gatekeeper

---

## O Que é a TEIA (Arquitetura AION RISPA NDC)

A TEIA é um **Seletor/Forjador Computacional Determinístico**. Na arquitetura **AION RISPA NDC v4.0.0**, ela opera de forma 100% offline e autônoma, sem dependência de nuvem, LLMs externos ou Python.

Ela armazena o **motor mínimo que sabe gerar esses bytes** — parâmetros procedurais (dicionários de categoria) e um blob comprimido com os dados de alta entropia irredutível via Brotli nativo do .NET.

```
Armazenamento tradicional:  csv_covid.csv   (5,51 MB)
AION NDC v4.0.0:             seed.json + seed.bin + Decode.ps1  = 635 KB
Reconstrução:                Decode(seed.json, seed.bin) → csv idêntico  (SHA-256 PASS)
Delta Real de Ganho:         +26.330 bytes sobre Brotli SmallestSize
```

**Oraculo Gatekeeper:** quando a fisica da entropia favorece o Brotli, a TEIA recua propositalmente. Resultado garantido: **0 Deltas negativos**.

---

## Demo em 1 Clique — v4.0.0 (Gatekeeper)

```powershell
# Pre-requisito: PowerShell 7+ no Windows.
# Conexao com internet necessaria apenas para download do dataset COVID (~5 MB).

# Extrair o pacote
Expand-Archive TEIA_AION_GATEKEEPER_v4.0.0.zip

# Executar a auditoria completa
pwsh -NoProfile -ExecutionPolicy Bypass -File .\aion_gatekeeper_v4\Run-Corpus10-Harness.ps1
```

O script faz tudo automaticamente em ~70 segundos:

1. Detecta se o Corpus30 esta presente; se nao, baixa 3 amostras representativas
2. Executa o Oraculo Gatekeeper em cada arquivo (analise de cardinalidade + estimativa de seed)
3. Recua propositalmente onde a entropia impede ganho real
4. Forja e verifica SHA-256 apenas no arquivo onde TEIA vence
5. Gera relatório `TEIA_GATEKEEPER_REPORT_P31.md` com matriz de evidencias

---

## Resultado Central — v4.0.0 Gatekeeper (Corpus10)

| Arquivo | Original | Brotli SmallestSize | TEIA v4.0.0 | Delta | SHA-256 | Veredito |
|---|---:|---:|---:|---:|:---:|---|
| csv_co2_global.csv | 7.0 KB | 1.8 KB | 1.8 KB | 0 (empate) | N/A | Recuo (Massa) |
| **csv_covid_countries_agg.csv** | **5.38 MB** | **661 KB** | **635 KB** | **+26.3 KB** | **PASS** | **TEIA VENCE** |
| csv_flights.csv | 2.3 KB | 0.5 KB | 0.5 KB | 0 (empate) | N/A | Recuo (Massa) |
| csv_gapminder_five_year.csv | 80.2 KB | 23.8 KB | 23.8 KB | 0 (empate) | N/A | Recuo (Massa) |
| csv_gdp.csv | 549.6 KB | 128.1 KB | 128.1 KB | 0 (empate) | N/A | Recuo (Entropia) |
| csv_iris.csv | 3.8 KB | 0.6 KB | 0.6 KB | 0 (empate) | N/A | Recuo (Massa) |
| csv_penguins.csv | 13.2 KB | 2.2 KB | 2.2 KB | 0 (empate) | N/A | Recuo (Massa) |
| csv_population.csv | 539.2 KB | 72.5 KB | 72.5 KB | 0 (empate) | N/A | Recuo (Entropia) |
| csv_seattle_weather.csv | 47.1 KB | 9.4 KB | 9.4 KB | 0 (empate) | N/A | Recuo (Massa) |
| csv_titanic.csv | 55.7 KB | 5.5 KB | 5.5 KB | 0 (empate) | N/A | Recuo (Massa) |

**Deltas negativos: 0/10 — meta atingida.**  
**SHA-256 PASS: 1/1 forjas executadas.**

---

## Evolução das Versões

| Versão | Destaques | Resultado |
|---|---|---|
| v1.2.0 | 10 datasets sintéticos, seeds P1 | 10/10 SHA-256 PASS, 99%+ Delta |
| v1.3.0 | P22 Real-World: COVID +58.7% vs Brotli Optimal | SHA-256 3/3 PASS |
| v2.0.1 | AION RISPA NDC offline, sem dependências externas | Motor offline estável |
| v4.0.0 | **Oraculo Gatekeeper: 0 Deltas negativos garantidos** | **9 Recuos + 1 TEIA VENCE** |

---

## O Oraculo Gatekeeper (v4.0.0)

O motor avalia cada arquivo em duas etapas antes de gastar CPU em forja:

**Regra 1 — Massa Critica:** se o arquivo for menor que 500 KB, o overhead do
decodificador (~1.9 KB) anula qualquer ganho estrutural. Recuo imediato.

**Regra 2 — Vantagem Estrutural:** para arquivos maiores, o motor constroi o residuo
em memoria, o comprime com Brotli, soma o meta JSON e o overhead do decoder, e compara
com Brotli(arquivo inteiro). Se a estimativa for maior ou igual, Recuo Seguro.
So prossegue para forja quando a estimativa confirma ganho real.

```
Antes (P29.1): 9 Deltas negativos em 10 arquivos
Depois (P31.0): 0 Deltas negativos — empate proposital ou TEIA VENCE
```

---

## Verificação de Integridade — v4.0.0

```powershell
(Get-FileHash .\TEIA_AION_GATEKEEPER_v4.0.0.zip -Algorithm SHA256).Hash.ToLower()
# Esperado: e5109bc8b6be1d3ac5e3d7c69004029520deea70fdc155f8fbbc08b20d5e7af3
```

---

## Verificação de Integridade — v1.3.0 (mantido)

```powershell
(Get-FileHash .\TEIA_P19_CLAIM_SAFE_DEMO.zip -Algorithm SHA256).Hash.ToLower()
# Esperado: 68f50d848f1a410e2f98f9533782f36a89a8ba0bb2915af3592152e25715f1b2
```

---

## Princípio Técnico

Dados **proceduralmente gerados** não precisam ser armazenados como bytes — podem ser armazenados como o **procedimento que os gerou**:

| Estrutura de dado | Armazenamento clássico | Armazenamento TEIA |
|---|:---:|:---:|
| Campo enum cíclico N vezes | O(N × chars) | dicionário + índice — O(log N) |
| Timestamps repetidos N vezes | O(N × 20 chars) | `{base, step}` — 50 B |
| 198 países × 816 datas | O(N × M × bytes) | dicionário + fórmula — O(log N) |

**Custo TEIA:** O(log N) — cresce com a complexidade do motor, não com N.  
**Custo clássico:** O(N × entropia residual) — cresce com o número de registros.

**Quando TEIA vence:** overhead estrutural > capacidade da janela LZ77 do Brotli.  
**Quando TEIA recua:** dados pequenos ou alta entropia residual dominante — Brotli já é ótimo.

---

## Limitações Explícitas

- Dados com **alta entropia real** (criptografia, imagens naturais, áudio): sem ganho.
- **Arquivos menores que 500 KB**: Recuo Seguro — overhead do decodificador domina.
- **JSONs de referência** ou com repetição de chaves já capturada por LZ77: Brotli vence.
- **Encoder automático**: motor forjado automaticamente por análise de cardinalidade (CSV);
  outros formatos (JSON profundo, logs arbitrários) requerem extensões futuras.
- v4.0.0 é uma **prova de conceito funcional e auditável**, não uma ferramenta de produção.

---

## Estrutura do Repositório

```
TEIA_CLAUDE_AWAKENING/
  release/
    aion_gatekeeper_v4/         — pacote demo v4.0.0 (Gatekeeper)
      TEIA-AION-Universal.ps1   — motor v4.0.0
      Run-Corpus10-Harness.ps1  — harness one-click com fallback de download
      TEIA_GATEKEEPER_REPORT_P31.md
      TEIA_ORACLE_CALIBRATION_P30.md
      README_DEMO.md
    TEIA_AION_GATEKEEPER_v4.0.0.zip  — artefato empacotado v4.0.0 (11.2 KB)
    teia_demo_p19/              — pacote demo v1.3.0 (mantido)
    TEIA_P19_CLAIM_SAFE_DEMO.zip    — artefato v1.3.0 (508.5 KB)

  tools/
    TEIA-AION-Universal.ps1    — motor AION NDC v4.0.0 (desenvolvimento)
    Run-Corpus10-Harness.ps1   — harness Corpus10 (desenvolvimento)
    Analyze-SemanticSchema.ps1 — lente semântica (JSON/CSV/SVG)
    Discover-Generators.ps1    — mapeador Law vs Noise

  docs/
    TEIA_GATEKEEPER_REPORT_P31.md       — resultados P31 (0 Deltas negativos)
    TEIA_ORACLE_CALIBRATION_P30.md      — calibração do Oraculo
    TEIA_RELEASE_NOTES_v4.0.0_GATEKEEPER.md — release notes v4.0.0
    TEIA_P22_REALWORLD_CRUCIBLE.md      — crucible P22 (mundo real)
    TEIA_RELEASE_NOTES_v1.3.0.md        — release notes v1.3.0
    TEIA_WHITEPAPER_v1.md               — whitepaper fundacional
```

---

## Documentos Técnicos

| Documento | Descrição |
|---|---|
| [TEIA_RELEASE_NOTES_v4.0.0_GATEKEEPER.md](docs/TEIA_RELEASE_NOTES_v4.0.0_GATEKEEPER.md) | Release notes v4.0.0 — Gatekeeper |
| [TEIA_GATEKEEPER_REPORT_P31.md](docs/TEIA_GATEKEEPER_REPORT_P31.md) | Resultados P31.0 — 0 Deltas negativos |
| [TEIA_ORACLE_CALIBRATION_P30.md](docs/TEIA_ORACLE_CALIBRATION_P30.md) | Calibração do Oraculo (derivação de limiares) |
| [TEIA_P22_REALWORLD_CRUCIBLE.md](docs/TEIA_P22_REALWORLD_CRUCIBLE.md) | Real-World Crucible — COVID +58.7% Delta |
| [TEIA_RELEASE_NOTES_v1.3.0.md](docs/TEIA_RELEASE_NOTES_v1.3.0.md) | Release notes v1.3.0 |
| [TEIA_WHITEPAPER_v1.md](docs/TEIA_WHITEPAPER_v1.md) | Whitepaper fundacional |

---

*TEIA v4.0.0-aion-gatekeeper | 2026-06-01*
