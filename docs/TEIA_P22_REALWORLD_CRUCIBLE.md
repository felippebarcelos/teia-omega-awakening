# TEIA P22.0 — Real-World Crucible

**Data:** 2026-06-01  
**Versão:** v1.3.0  
**Status:** EXECUTADO — RESULTADOS CLAIM-SAFE

---

## Objetivo

Aplicar o motor TEIA híbrido a 3 datasets **reais e orgânicos** baixados da internet, sem qualquer preparação prévia dos dados, e medir honestamente:

1. **SHA-256 identity** — o arquivo reconstruído é bit-a-bit idêntico ao original?
2. **Delta (Ganho)** — TEIA+Decoder é menor que Brotli do arquivo original?

---

## Datasets Testados

| Dataset | Fonte | Formato | Tamanho |
|---------|-------|---------|---------|
| `covid_countries_aggregated.csv` | [datasets/covid-19 on GitHub](https://github.com/datasets/covid-19) | CSV | 5,26 MB |
| `countries.json` | [mledoze/countries on GitHub](https://github.com/mledoze/countries) | JSON | 1,33 MB |
| `worldbank_gdp.json` | World Bank API (`NY.GDP.PCAP.CD`) | JSON | 1,41 MB |

SHA-256 dos originais (momento da ingestão):

| Arquivo | SHA-256 |
|---------|---------|
| covid_countries_aggregated.csv | `fbd1738729a2ebac655e08fcd9562b5cf71573a8b9c03f809c2cf2c53faf047f` |
| countries.json | `2e7584a7f48a13b35d4c4a98cd7d0bafcc6bda3322a9e6ff4c4edbbdad8ec1ec` |
| worldbank_gdp.json | `c9f06e0ad146aff1b6ff9e45297a5bb1d9078776c1c8757c830a91c7ea8a596a` |

---

## Metodologia — TEIA Híbrido

O motor TEIA P22 usa uma estratégia **híbrida** diferente da P17 (dados 100% sintéticos):

```
Dados orgânicos = Campos procedurais + Campos de alta entropia

TEIA Híbrido:
  seed = {
    params procedurais (fórmulas de data, dicionário de categorias)  ← O(log N)
    blob de dados = Brotli(colunas orgânicas de alta entropia)         ← Brotli optimal
  }
  decoder = script que combina params + blob → arquivo original exato
```

**Princípio**: TEIA elimina o overhead estrutural (strings de data repetidas ×816, nomes de países repetidos ×198) e aplica Brotli APENAS nas colunas de alta entropia. Brotli do arquivo completo carrega esse overhead estrutural no seu input.

---

## Resultados

```
Arquivo                              Original     Brotli  TEIA Hybrid   Delta (Ganho)  SHA-256
──────────────────────────────────────────────────────────────────────────────────────────────
covid_countries_aggregated.csv        5,26 MB   645,9 KB     479,1 KB           25,8%     PASS
countries.json                        1,33 MB   102,4 KB     145,6 KB          -42,2%     PASS
worldbank_gdp.json                    1,41 MB    63,5 KB      77,8 KB          -22,5%     PASS
```

**SHA-256: 3/3 PASS** — Os 3 arquivos foram reconstruídos byte-a-bit idênticos aos originais.  
**Delta positivo: 1/3 datasets** — TEIA vence Brotli no CSV; perde nos JSONs.

---

## Análise por Dataset

### Dataset 1: COVID-19 CSV — TEIA VENCE (+25,8%)

**Estrutura identificada:**
- 161.568 linhas = 198 países × 816 datas (matriz perfeita)
- Ordenação: Country (externo) × Date (interno)
- Colunas procedurais: `Date` (fórmula: base + step × i) + `Country` (dicionário de 198 nomes)
- Colunas orgânicas: `Confirmed`, `Recovered`, `Deaths` (inteiros de alta entropia)

**Por que TEIA vence:**
```
Overhead estrutural no CSV original:
  Coluna Date:    "2020-01-22," × 161.568 linhas ≈ 1,94 MB
  Coluna Country: média 12 chars × 161.568       ≈ 1,94 MB
  Total overhead: ≈ 3,88 MB (74% do arquivo)

TEIA extrai esse overhead e armazena apenas:
  seed meta JSON (params + 198 nomes):  2,4 KB
  Brotli(3 colunas numéricas):        475,7 KB (raw binary, sem Base64)
  Total seed+decoder:                  479,1 KB

Brotli do arquivo completo (inclui overhead estrutural no input): 645,9 KB

Delta (Ganho) = (645,9 - 479,1) / 645,9 = 25,8%
```

**Insight técnico:** Brotli usa LZ77 (janela de lookback limitada) para comprimir repetições. Quando 198 nomes de países se repetem ao longo de 5 MB de arquivo, muitas repetições ficam fora da janela LZ77. TEIA elimina essas repetições inteiramente via dicionário + fórmula.

### Dataset 2: Countries JSON — TEIA PERDE (-42,2%)

**Estrutura identificada:**
- 250 objetos, cada um com: nome, capital, moedas, idiomas, **traduções em 24 línguas**
- Campos de baixa cardinalidade: region (6 valores), subregion (25 valores), landlocked/unMember (bool)
- Dominância do tamanho: **traduções multilíngues** representam a maior parte dos bytes

**Por que TEIA perde:**
```
Brotli comprime 1,33 MB → 102,4 KB (razão 13,3x)
Brotli é muito eficiente aqui porque as strings de tradução
têm padrões repetitivos entre os 250 países.

TEIA não tem campo procedural dominante: cada país é único,
não há N × M estrutura explorável.
Seed JSON (Brotli blob + overhead estrutural): 145,6 KB > 102,4 KB Brotli
```

**Resultado honesto:** `countries.json` é principalmente uma base de dados de referência. TEIA não tem vantagem sobre Brotli neste domínio.

### Dataset 3: World Bank GDP JSON — TEIA PERDE (-22,5%)

**Estrutura identificada:**
- 6.650 registros de `{indicator, country, date, value, unit, obs_status, decimal}`
- Indicador: **constante** em todos os 6.650 registros (`NY.GDP.PCAP.CD`)
- `unit`, `obs_status`: sempre vazios → constantes
- `value`: float GDP per capita (alta entropia)

**Por que TEIA perde:**
```
Brotli comprime 1,41 MB → 63,5 KB (razão 22,3x!)
Razão extraordinária porque a string do indicador
{"id":"NY.GDP.PCAP.CD","value":"GDP per capita (current US$)"}
se repete literalmente 6.650 vezes — LZ77 ideal.

TEIA extrai o indicador constante + lookup de países,
mas o seed JSON resultante (76,3 KB) ainda supera Brotli (63,5 KB).
```

**Resultado honesto:** JSON com alta repetição de chaves/valores constantes é o caso ideal para Brotli/GZip. TEIA não tem vantagem aqui.

---

## Veredito Claim-Safe

```
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║   TEIA P22.0 — Real-World Crucible                                   ║
║                                                                      ║
║   SHA-256: 3/3 PASS (reconstrução byte-a-bit do mundo real)         ║
║                                                                      ║
║   TEIA VENCE Brotli em dados tabulares com overhead estrutural alto  ║
║     covid_countries_aggregated.csv: +25,8% Delta (Ganho)            ║
║                                                                      ║
║   TEIA PERDE para Brotli em bancos de dados de referência JSON       ║
║     countries.json:     -42,2% Delta (Brotli vence)                 ║
║     worldbank_gdp.json: -22,5% Delta (Brotli vence)                 ║
║                                                                      ║
║   DIAGNÓSTICO: TEIA híbrido supera Brotli quando o overhead         ║
║   estrutural (datas/categorias repetidas) excede a janela LZ77.     ║
║   Em JSONs com chaves constantes repetidas, Brotli já é ótimo.     ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

## Quando TEIA Bate Brotli no Mundo Real

Com base nos resultados P22, os critérios são:

| Condição | TEIA vs Brotli |
|----------|---------------|
| CSV com N × M estrutura (datas × categorias), N e M grandes | **TEIA vence** |
| Overhead estrutural > 50% do arquivo | **TEIA vence** |
| JSON com campos constantes repetidos em muitas linhas | Brotli vence |
| Banco de dados de referência (objetos únicos) | Brotli vence |
| Arquivo com alta entropia real (sem padrão) | Brotli vence (TEIA ≈ Brotli no blob) |

**Regra geral:** TEIA vence quando o arquivo tem estrutura `N × campos_procedurais + M × bytes_orgânicos` com N grande. Brotli vence quando a estrutura é complexa mas `N` é pequeno (250 países, 6.650 registros — LZ77 ainda alcança o lookback).

---

## Limitações (Honestidade P22)

1. **Encoder automático ausente**: a análise de estrutura e a separação campos-procedurais/orgânicos foi feita manualmente (pelo LLM Scientist). Sem encoder automático, o P22 exige análise por domínio.

2. **Formato binário vs JSON-em-B64**: o seed do COVID usa formato binário (meta JSON + .bin raw Brotli). Implementações que usam Base64 embutido em JSON têm overhead de 33%, reduzindo o Delta de 25,8% para apenas 1,3%.

3. **Tamanho do arquivo importa**: datasets menores têm janela LZ77 suficiente para Brotli capturar toda a repetição. TEIA se destaca à medida que N cresce além da janela Brotli (~64 MB).

4. **Dados reais têm entropia residual**: os números de COVID (Confirmed/Recovered/Deaths) têm entropia muito maior do que os dados sintéticos do P17. Por isso a razão de compressão é ~5x (real) vs ~140x (sintético).

---

## Artefatos Produzidos

```
sandbox/crucible_p22/
  seeds/
    seed_covid_meta.json     — parâmetros estruturais (2,4 KB)
    seed_covid_data.bin      — Brotli raw dos dados orgânicos (475,7 KB)
    seed_countries.json      — seed híbrido com Brotli blob B64 (145 KB)
    seed_worldbank.json      — seed híbrido World Bank (76 KB)
  decoders/
    Decode-covid.ps1         — decoder COVID (lê meta + bin)
    Decode-countries.ps1     — decoder Countries JSON
    Decode-worldbank.ps1     — decoder World Bank JSON
  rebuilt/
    covid_rebuilt.csv        — [purgado após verificação — dataset residual]
    countries_rebuilt.json   — [purgado após verificação — dataset residual]
    worldbank_rebuilt.json   — [purgado após verificação — dataset residual]
  p22_results.json           — resultados completos com hashes
```

**Scripts:**
- `tools/Fetch-RealWorldData.ps1` — ingestão dos 3 datasets
- `tools/Run-P22-RealWorldCrucible.ps1` — crucible completo (análise → seed → decode → verify)

---

## Próximos Vetores

1. **P22.1 — CSV Real de Grande Escala**: testar TEIA em CSV com N > 1M linhas (onde Brotli LZ77 definitivamente perde as repetições de início de arquivo).
2. **Encoder Automático (P17.1)**: script que detecta a estrutura N × M em CSV/JSON real e forja motor automaticamente.
3. **Compressão Híbrida Delta**: para World Bank JSON, usar TEIA para eliminar o indicador constante + lookup países e aplicar Brotli sobre o JSON "esqueleto" residual.

---

*TEIA — Transcendência Epistêmica Integrada Autossintetizante*  
*Protocolo P22.0 | Data: 2026-06-01 | SHA-256: 3/3 PASS*
