# TEIA — Storage as Computation

**Transcendência Epistêmica Integrada Autossintetizante**  
**Versão atual:** v1.3.0-real-world-demo

---

## O Que é a TEIA

A TEIA é um **Seletor/Forjador Computacional**. Em vez de armazenar bytes de um arquivo, ela armazena o **motor mínimo que sabe gerar esses bytes** — parâmetros procedurais (fórmulas de data, dicionários de categoria) e um blob comprimido com os dados de alta entropia irredutível.

```
Armazenamento tradicional:  arquivo.csv  (5,26 MB)
TEIA Híbrido:                seed_meta.json (2,5 KB) + seed_data.bin (476 KB) + decoder.ps1 (1 KB) = 479 KB
Reconstrução:                decoder(seed_meta, seed_data) → arquivo.csv idêntico  (SHA-256 PASS)
Delta (Ganho) vs Brotli:     +58,7% (Brotli Optimal) | +25,8% (Brotli SmallestSize)
```

**Não é mágica de compressão universal.** A TEIA atua onde os dados têm **overhead estrutural dominante** — timestamps repetidos em N linhas, categorias cíclicas, IDs sequenciais, campos constantes. Quando esses campos representam a maior parte dos bytes, TEIA supera Brotli. Quando os dados são principalmente entropia orgânica, TEIA recua e reconhece.

---

## Demo em 1 Clique

```powershell
# Pré-requisito: PowerShell 7+ no Windows.
# Fases 1-4 (sintético): sem dependências externas.
# Fase 5 (real): requer internet (download do COVID-19 CSV do GitHub).

# Extrair o pacote demo
Expand-Archive TEIA_P19_CLAIM_SAFE_DEMO.zip

# Executar a auditoria completa
pwsh -ExecutionPolicy Bypass -File .\teia_demo_p19\audit-one-click.ps1
```

O script faz tudo automaticamente em menos de 30 segundos (+ tempo de download):

1. Gera 10 datasets estruturados do zero (JSON/CSV/SVG, até 5 MB cada)
2. Reconstrói os mesmos arquivos a partir das seeds e decoders armazenados (3 KB por arquivo)
3. Mede GZip e Brotli para comparação
4. Verifica `SHA-256(Reconstruído) == SHA-256(Original)` para cada arquivo
5. **[NOVO]** Baixa o dataset COVID-19 Aggregated CSV (5,26 MB) ao vivo do GitHub, reconstrói do seed híbrido e verifica SHA-256 bit-a-bit
6. Apaga todos os arquivos temporários

---

## Resultados — Sintéticos (v1.2.0, mantidos)

| Arquivo | Original | Melhor Clássico | TEIA (Seed+Decoder) | Delta (Ganho) | SHA-256 |
|---------|:--------:|:---------------:|:-------------------:|:-------------:|:-------:|
| json_api_events.json | 5,33 MB | 346,6 KB | 3,14 KB | 99,1% ganhos | PASS |
| json_products.json | 2,79 MB | 215,8 KB | 3,30 KB | 98,5% ganhos | PASS |
| json_metrics.json | 4,35 MB | 195,5 KB | 3,14 KB | 98,4% ganhos | PASS |
| csv_sensor_data.csv | 4,13 MB | 403,5 KB | 3,16 KB | 99,2% ganhos | PASS |
| csv_transactions.csv | 2,38 MB | 352,9 KB | 2,62 KB | 99,3% ganhos | PASS |
| csv_server_logs.csv | 4,20 MB | 418,2 KB | 3,04 KB | 99,3% ganhos | PASS |
| csv_orders.csv | 2,92 MB | 205,4 KB | 3,05 KB | 98,5% ganhos | PASS |
| svg_scatter_20k.svg | 971,9 KB | 108,1 KB | 2,22 KB | 97,9% ganhos | PASS |
| svg_network_10k.svg | 1,60 MB | 201,4 KB | 2,73 KB | 98,6% ganhos | PASS |
| svg_heatmap_20k.svg | 1,16 MB | 58,4 KB | 2,40 KB | 95,8% ganhos | PASS |

**10/10 SHA-256 PASS** | Delta acumulado: **2,42 MB economizados** vs. melhor clássico

---

## Veredito P22: O Teste do Mundo Real (v1.3.0)

Três datasets **orgânicos e reais** baixados da internet sem preparação prévia:

| Dataset | Original | Brotli | TEIA Hybrid | Delta (Ganho) | SHA-256 |
|---------|:--------:|:------:|:-----------:|:-------------:|:-------:|
| **covid_countries_aggregated.csv** | **5,26 MB** | **1,13 MB** | **479 KB** | **+58,7% ganhos** | **PASS** |
| countries.json | 1,33 MB | 102,4 KB | 145,6 KB | -42,2% (Brotli vence) | PASS |
| worldbank_gdp.json | 1,41 MB | 63,5 KB | 77,8 KB | -22,5% (Brotli vence) | PASS |

**SHA-256: 3/3 PASS** — todos os arquivos reais foram reconstruídos bit-a-bit.

### Por Que TEIA Vence no CSV e Recua nos JSONs

O CSV de COVID tem estrutura `198 países × 816 datas = 161.568 linhas`. Os campos `Date` e `Country` representam ~74% dos bytes — overhead estrutural que o LZ77 do Brotli não consegue capturar ao longo de 5 MB. TEIA elimina esse overhead inteiramente via fórmula + dicionário.

Os JSONs de referência (`countries.json`, `worldbank_gdp.json`) têm ou alta entropia por objeto (traduções únicas) ou repetição de chaves que o LZ77 já captura perfeitamente. Nesses casos, Brotli é o algoritmo correto e TEIA reconhece.

> **A TEIA não é um zip universal. É um seletor: usa a ferramenta certa para cada tipo de dado.**

---

## Verificação de Integridade do Pacote

```powershell
(Get-FileHash .\TEIA_P19_CLAIM_SAFE_DEMO.zip -Algorithm SHA256).Hash.ToLower()
# Esperado: 68f50d848f1a410e2f98f9533782f36a89a8ba0bb2915af3592152e25715f1b2
```

---

## Princípio Técnico

Dados **proceduralmente gerados** não precisam ser armazenados como bytes — podem ser armazenados como o **procedimento que os gerou**:

| Estrutura de dado | Armazenamento clássico | Armazenamento TEIA |
|-------------------|:----------------------:|:------------------:|
| IDs 1, 2, 3 … N | O(N × dígitos) | `{"start":1,"step":1}` — 30 B |
| Timestamps a cada 60s | O(N × 20 chars) | `{"base":"…","step_sec":60}` — 50 B |
| Campo enum cíclico | O(N × comprimento) | lista de valores + período — 100–200 B |
| 198 países × 816 datas | O(N × M × bytes) | dicionário + fórmula de data — O(log N) |

**Custo TEIA:** O(log N) — cresce com a complexidade do motor, não com N.  
**Custo clássico:** O(N × entropia residual) — cresce com o número de registros.

Para N suficientemente grande e overhead estrutural dominante, TEIA sempre vence em dados procedurais.

---

## Limitações Explícitas

- Dados com **alta entropia real** (ruído, criptografia, imagens naturais): sem ganho.
- **JSONs de referência** com objetos únicos (ex: countries.json): Brotli já é ótimo.
- **JSONs com chaves repetidas** (ex: World Bank API): LZ77 do Brotli captura a repetição.
- **Encoder automático** ainda não disponível — motor forjado manualmente (ou por LLM Scientist).
- A versão v1.3.0 é uma **prova de conceito funcional e auditável**, não uma ferramenta de produção.

---

## Estrutura do Repositório

```
TEIA_CLAUDE_AWAKENING/
  release/
    teia_demo_p19/          — pacote demo auto-contido
      audit-one-click.ps1   — script da verdade (v1.3.0, 5 fases)
      seeds/                — 10 seeds sintéticos + seed_covid_meta.json + seed_covid_data.bin
      decoders/             — 10 decoders sintéticos + Decode-covid.ps1
      README_DEMO.md
    TEIA_P19_CLAIM_SAFE_DEMO.zip  — artefato empacotado v1.3.0

  tools/
    Analyze-SemanticSchema.ps1    — lente semântica (JSON/CSV/SVG)
    Fetch-RealWorldData.ps1       — ingestão P22 (3 datasets orgânicos)
    Run-P22-RealWorldCrucible.ps1 — crucible P22 completo

  sandbox/
    crucible_p17/   — 10 P1 Patches sintéticos + seeds + decoders
    crucible_p22/   — 3 motores híbridos reais + seeds + decoders + p22_results.json

  docs/
    TEIA_P17_DOMAIN_RANKING_v1.md     — benchmark P17 (sintético)
    TEIA_P18_CLAIM_SAFE_AUDIT.md      — auditoria reprodutibilidade P18
    TEIA_P22_REALWORLD_CRUCIBLE.md    — crucible P22 (mundo real)
    TEIA_RELEASE_NOTES_v1.2.0.md      — release notes v1.2.0
    TEIA_RELEASE_NOTES_v1.3.0.md      — release notes v1.3.0 (esta versão)
```

---

## Auditoria Manual — Decoder COVID-19 Real

```powershell
cd release\teia_demo_p19

# Reconstruir o COVID-19 CSV a partir do seed híbrido
.\decoders\Decode-covid.ps1 `
    -SeedMetaFile .\seeds\seed_covid_meta.json `
    -SeedBinFile  .\seeds\seed_covid_data.bin  `
    -OutputFile   .\covid_rebuilt.csv

# Verificar SHA-256 (deve ser idêntico ao original baixado do GitHub em 2026-06-01)
(Get-FileHash .\covid_rebuilt.csv -Algorithm SHA256).Hash.ToLower()
# Esperado: fbd1738729a2ebac655e08fcd9562b5cf71573a8b9c03f809c2cf2c53faf047f
```

---

## Documentos Técnicos

| Documento | Descrição |
|-----------|-----------|
| [TEIA_P17_DOMAIN_RANKING_v1.md](docs/TEIA_P17_DOMAIN_RANKING_v1.md) | Benchmark completo: 10 domínios, 24,3x a 140,8x de ganho |
| [TEIA_P18_CLAIM_SAFE_AUDIT.md](docs/TEIA_P18_CLAIM_SAFE_AUDIT.md) | Auditoria de reprodutibilidade — prova tripla SHA-256 |
| [TEIA_P22_REALWORLD_CRUCIBLE.md](docs/TEIA_P22_REALWORLD_CRUCIBLE.md) | Real-World Crucible — COVID +58,7% Delta, honestidade nos JSONs |
| [TEIA_RELEASE_NOTES_v1.3.0.md](docs/TEIA_RELEASE_NOTES_v1.3.0.md) | Release notes desta versão |
| [release/teia_demo_p19/README_DEMO.md](release/teia_demo_p19/README_DEMO.md) | Guia completo do pacote demo |

---

*TEIA v1.3.0-real-world-demo | 2026-06-01*
