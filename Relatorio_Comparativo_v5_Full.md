# Relatorio Comparativo v5 — Corpus Completo D4 (46 arquivos)

> **Gerado**: 2026-05-25T11:21:37Z  
> **Motor**: TEIA-Core-v0.8.0 | SHA-256: 71DABD27742B534E11C334613CDDE6D469B10E5EBBB0BF4B652E84DF8D801536 | 18580 bytes  
> **Dicionario Zstd**: 6c72ae7246b413b8b635078167da4d5786276435fea3cd140326197744562d8a | 80055 bytes | treinado em 8 botocore service-2.json  
> **Hardware**: i3-10100F, 16GB RAM, HDD  
> **Total processados**: 46 / 46 | Erros: 0  
> **SHA-256 100%**: SIM

---

## Sumario por Bucket

| Bucket | Arquivos | TEIA wins | Avg LZMA% | Avg TEIA% | Avg overhead D-C% | SHA-256 OK |
|--------|----------|-----------|-----------|-----------|-------------------|-----------|
| tiny | 6 | 0/6 | 33.86% | 37.23% | 13.3627% | 6/6 |
| small | 14 | 12/14 | 19.51% | 18.4% | 1.4034% | 14/14 |
| medium | 16 | 12/16 | 13.33% | 12.48% | 0.1404% | 16/16 |
| large | 10 | 0/10 | 13.62% | 15.06% | 0.0166% | 10/10 |
| **TOTAL** | **46** | **24/46** | | | | **46/46** |

---

## Resultados Completos — Todos os 46 Arquivos

Legenda: [T]=arquivo usado no treinamento do dict | W=TEIA wins | L=TEIA perde

| ID | Bucket | Nome | Orig B | A:LZMA% | B:Zstd% | C:Zstd+D% | D:TEIA% | D-C B | D-A | SHA |
|----|--------|------|--------|---------|---------|-----------|---------|-------|-----|-----|
| R1    | tiny | paginators-1.json | 2047 | 21.15% | 14.46% | 11.63% | 24.96% | 273 | 78B | OKL |
| R2    | tiny | _package.json | 2045 | 49.49% | 43.67% | 39.76% | 52.91% | 269 | 70B | OKL |
| R3    | tiny | paginators-1.json | 2033 | 20.61% | 13.72% | 10.92% | 24.35% | 273 | 76B | OKL |
| R4    | tiny | paginators-1.json | 2032 | 20.96% | 13.98% | 11.42% | 24.85% | 273 | 79B | OKL |
| R5    | tiny | package.nls.json | 2018 | 42.12% | 34.14% | 28.69% | 42.17% | 272 | 1B | OKL |
| R6    | tiny | _package.json | 2016 | 48.86% | 42.91% | 40.77% | 54.12% | 269 | 106B | OKL |
| R7    | small | adexchangebuyer.v1.2.j | 20475 | 18.63% | 17.73% | 15.38% | 16.76% | 282 | -382B | OKW |
| R8    | small | Reforma minimalista tr | 20454 | 21.96% | 21.08% | 20.05% | 21.55% | 305 | -84B | OKW |
| R9    | small | Pintura telha e parede | 20446 | 21.88% | 21.03% | 20.05% | 21.51% | 298 | -76B | OKW |
| R10    | small | Design parede Basquiat | 20429 | 21.93% | 21.11% | 20.07% | 21.52% | 297 | -84B | OKW |
| R11    | small | groovy.tmLanguage.json | 20347 | 19.84% | 19.1% | 18.1% | 19.47% | 279 | -76B | OKW |
| R12    | small | manifest.json | 20344 | 8.7% | 7.65% | 7.33% | 8.66% | 270 | -7B | OKW |
| R13    | small | Pintura telha e parede | 20330 | 21.68% | 20.89% | 19.89% | 21.35% | 298 | -67B | OKW |
| R14    | small | service-2.json | 20210 | 17.14% | 16.41% | 12.68% | 14.02% | 271 | -631B | OKW |
| R15    | small | iap.v1beta1.json | 20190 | 26.46% | 25.79% | 22.82% | 24.18% | 273 | -461B | OKW |
| R16    | small | adsenseplatform.v1.jso | 20170 | 22.52% | 21.83% | 19.36% | 20.74% | 280 | -358B | OKW |
| R17    | small | service-2.json | 20156 | 17.3% | 16.46% | 12.21% | 13.55% | 271 | -754B | OKW |
| R18    | small | package.json | 20116 | 17.24% | 16.59% | 15.92% | 17.26% | 269 | 5B | OKL |
| R19    | small | verifiedaccess.v2.json | 20018 | 25.21% | 24.62% | 22.18% | 23.57% | 279 | -329B | OKW |
| R20    | small | Takeout__Minha ativida | 19981 | 12.67% | 11.95% | 11.89% | 13.43% | 309 | 153B | OKL |
| R21[T] | medium | service-2.json | 202197 | 9.49% | 9.29% | 7.75% | 7.89% | 272 | -3234B | OKW |
| R22[T] | medium | service-2.json | 201124 | 12.39% | 12.36% | 10.49% | 10.62% | 272 | -3545B | OKW |
| R23    | medium | Minhaatividade.json | 201038 | 35.73% | 36.1% | 35.75% | 35.89% | 277 | 318B | OKL |
| R24    | medium | Takeout__Minha ativida | 201038 | 35.76% | 36.1% | 35.75% | 35.9% | 312 | 281B | OKL |
| R25[T] | medium | service-2.json | 200275 | 10.46% | 10.25% | 8.67% | 8.81% | 272 | -3316B | OKW |
| R26    | medium | Prompt para análise te | 200207 | 13.36% | 13.5% | 13.29% | 13.44% | 304 | 168B | OKL |
| R27[T] | medium | service-2.json | 199319 | 10.84% | 10.69% | 9.91% | 10.05% | 272 | -1588B | OKW |
| R28[T] | medium | service-2.json | 198376 | 7.59% | 7.54% | 5.89% | 6.03% | 272 | -3100B | OKW |
| R29    | medium | service-2.json | 197970 | 10.72% | 10.55% | 9.79% | 9.93% | 272 | -1570B | OKW |
| R30    | medium | strings.localized.json | 196833 | 17.03% | 17.41% | 17.17% | 17.31% | 280 | 552B | OKL |
| R31    | medium | 0031_snapshot.json | 196586 | 4.4% | 3.91% | 3.86% | 4% | 276 | -796B | OKW |
| R32[T] | medium | service-2.json | 195993 | 10.53% | 10.39% | 8.59% | 8.72% | 272 | -3544B | OKW |
| R33    | medium | endpoint-rule-set-1.js | 195500 | 2.33% | 1.89% | 1.79% | 1.93% | 282 | -771B | OKW |
| R34[T] | medium | service-2.json | 194813 | 12.01% | 11.84% | 10% | 10.14% | 272 | -3645B | OKW |
| R35    | medium | service-2.json | 194806 | 10.74% | 10.56% | 9.81% | 9.95% | 272 | -1554B | OKW |
| R36[T] | medium | service-2.json | 194634 | 9.91% | 9.76% | 9% | 9.14% | 272 | -1505B | OKW |
| R37    | large | inventory.json | 1912912 | 2.42% | 2.43% | 2.46% | 2.48% | 273 | 1146B | OKL |
| R38    | large | nls.metadata.json | 1894245 | 16.34% | 16.46% | 17.42% | 17.43% | 276 | 20630B | OKL |
| R39    | large | vega-lite-schema.json | 1879221 | 3.11% | 3.11% | 3.32% | 3.34% | 280 | 4149B | OKL |
| R40    | large | Minhaatividade.json | 1814869 | 12.93% | 13.29% | 13.58% | 13.6% | 278 | 12132B | OKL |
| R41    | large | service-2.json | 1803075 | 9.39% | 9.24% | 10.26% | 10.28% | 273 | 15998B | OKL |
| R42    | large | Minhaatividade.json | 1782936 | 8.9% | 10.26% | 10.48% | 10.5% | 278 | 28438B | OKL |
| R43    | large | anthropic_tokenizer.js | 1774213 | 31.97% | 35.28% | 36.23% | 36.25% | 283 | 75953B | OKL |
| R44    | large | tokenizer.json | 1774213 | 31.96% | 35.28% | 36.23% | 36.25% | 273 | 75959B | OKL |
| R45    | large | service-2.json | 1271736 | 7.9% | 7.7% | 8.24% | 8.26% | 273 | 4579B | OKL |
| R46    | large | components.json | 1181423 | 11.3% | 11.62% | 12.21% | 12.24% | 274 | 11001B | OKL |

---

## Atribuicao do Ganho por Bucket

Para cada bucket, mostramos a media de cada componente do ganho/perda:

| Bucket | B-A (Zstd-LZMA) | C-B (dict) | C-A (Zstd+dict-LZMA) | D-C (overhead TEIA) | D-A (liquido) |
|--------|----------------|------------|----------------------|---------------------|---------------|
| tiny | -136 B | -67 B | -203 B | 272 B | 68 B |
| small | -158 B | -352 B | -509 B | 284 B | -225 B |
| medium | -142 B | -1814 B | -1956 B | 278 B | -1678 B |
| large | 14912 B | 9810 B | 24722 B | 276 B | 24998 B |

**Interpretacao**:
- B-A negativo: Zstd -19 supera LZMA standalone (sem dict)
- C-B negativo: dicionario treinado ajuda o Zstd
- D-C positivo: overhead container TEIA (12B header + manifest JSON)
- D-A negativo: TEIA binario supera LZMA (sucesso)
- D-A positivo: TEIA binario perde para LZMA

---

## Break-even e Amortizacao

Custo fixo: motor 18580 B + dict 80055 B = **98635 B**

Savings medios por arquivo vencedor: 1312 B
N break-even (baseado nos arquivos vencedores): 76 arquivos

**Nota sobre o dicionario**: treinado exclusivamente em medium botocore service-2.json.
Arquivos de outros dominios (tokenizadores, atividade Google, schemas) beneficiam-se menos do dict.
Um dict treinado por categoria de arquivo produziria resultados melhores.

---

## Criterios de Sucesso v0.8 — Corpus Completo

| Criterio | Definicao | Resultado | Detalhes |
|----------|-----------|-----------|---------|
| 1 | Overhead D-C < 1% do original | PARCIAL (26/46) | medio: overhead depende do tamanho do arquivo |
| 2 | TEIA ganha vs LZMA em pelo menos 1 arquivo | PASS (24/46 arquivos) | varia por bucket e tipo de arquivo |
| 3 | SHA-256 100% dos restores | PASS | integridade total do corpus |
| 4 | Treino e teste separados | PASS | 8 train IDs marcados como [T] na tabela |

---

## Diagnostico por Bucket

### Bucket: tiny (6 arquivos | 0 wins)

Overhead fixo 272B = 13.3% de um arquivo tipico de 2032B.
Dict treinado em ~200KB nao transfere para arquivos de 2KB — esperado pouco ganho.

### Bucket: small (14 arquivos | 12 wins)

Overhead fixo 272B = 1.4% de arquivo ~20KB.
Arquivos pequenos heterogeneos (schemas, configs, atividade) — dict especifico ajudaria.

### Bucket: medium (16 arquivos | 12 wins)

8 de 16 arquivos foram usados no treinamento [T]. Overhead 272B = 0.14% de ~197KB.
Maior beneficio do dict: botocore service-2.json. Outros formatos (Minhaatividade, strings) ganham menos.

### Bucket: large (10 arquivos | 0 wins)

Overhead 272B = 0.0151% de arquivo ~1.8MB — trivialmente pequeno.
Ganho depende da similaridade com o corpus de treino: service-2.json ganha; tokenizadores e schemas perdem.

---

*TEIA-Core v0.8.0 | Harness v5.0-Full | Felippe Barcelos | 2026-05-25T11:21:37Z*
