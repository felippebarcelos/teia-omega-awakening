# TEIA GATEKEEPER CORPUS 10 RESULTS — Protocol P31.0

## Motor AION RISPA NDC v4.0.0 — Oraculo Gatekeeper

O Oraculo Gatekeeper integra duas regras preditivas antes de qualquer tentativa de forja:

- **Regra 1 (Massa Critica):** arquivo menor que 500 KB recua imediatamente. O overhead fixo do decodificador anula o ganho estrutural em arquivos pequenos.
- **Regra 2 (Vantagem Estrutural):** apos analise de cardinalidade e construcao do residuo em memoria, o motor estima o tamanho total do seed (residuo comprimido + meta JSON + overhead do decodificador). Se a estimativa for maior ou igual ao Brotli puro, o motor recua sem gravar nenhum arquivo.

Resultado: **zero Deltas negativos** e **zero ciclos de CPU gastos em forjas previstas como perdedoras**.

## Matriz de Evidencias (Harness P31.0)

| Arquivo | Original | Brotli SmallestSize | TEIA / Gatekeeper | Delta | SHA-256 | Veredito | Tempo |
|---|---:|---:|---:|---:|:---:|---|---:|
| csv_co2_global.csv | 7137 | 1844 | 1844 (Brotli) | 0 (empate) | N/A | Recuo Seguro (Massa Insuficiente) | 69 ms |
| csv_covid_countries_aggregated.csv | 5512931 | 661353 | 635023 | +26330 | PASS | TEIA VENCE | 58013 ms |
| csv_flights.csv | 2350 | 456 | 456 (Brotli) | 0 (empate) | N/A | Recuo Seguro (Massa Insuficiente) | 7 ms |
| csv_gapminder_five_year.csv | 82079 | 24355 | 24355 (Brotli) | 0 (empate) | N/A | Recuo Seguro (Massa Insuficiente) | 115 ms |
| csv_gdp.csv | 562767 | 131205 | 131205 (Brotli) | 0 (empate) | N/A | Recuo Seguro (Entropia Dominante) | 4273 ms |
| csv_iris.csv | 3858 | 632 | 632 (Brotli) | 0 (empate) | N/A | Recuo Seguro (Massa Insuficiente) | 9 ms |
| csv_penguins.csv | 13478 | 2255 | 2255 (Brotli) | 0 (empate) | N/A | Recuo Seguro (Massa Insuficiente) | 23 ms |
| csv_population.csv | 552112 | 74276 | 74276 (Brotli) | 0 (empate) | N/A | Recuo Seguro (Entropia Dominante) | 4033 ms |
| csv_seattle_weather.csv | 48219 | 9640 | 9640 (Brotli) | 0 (empate) | N/A | Recuo Seguro (Massa Insuficiente) | 69 ms |
| csv_titanic.csv | 57018 | 5654 | 5654 (Brotli) | 0 (empate) | N/A | Recuo Seguro (Massa Insuficiente) | 84 ms |

## Sumario

| Metrica | Valor |
|---|---|
| Arquivos testados | 10 |
| Recuos pelo Gatekeeper | 9 |
| Forjas executadas | 1 |
| TEIA VENCE | 1 |
| SHA-256 PASS (forjas) | 1 |
| Deltas negativos | 0 |
| Delta total de ganho (bytes) | 26330 |
| Tempo total de execucao | 66696 ms |

## Diagnostico por Arquivo

| Arquivo | Decisao do Gatekeeper | Motivo |
|---|---|---|
| csv_co2_global.csv | Recuo Seguro (Massa Insuficiente) | 6.97 KB < 500 KB. Overhead do decodificador supera qualquer ganho estrutural. |
| csv_covid_countries_aggregated.csv | Forja Autorizada | 5.38 MB, estrutura 198 paises x 816 datas. Overhead estrutural excede janela LZ77. |
| csv_flights.csv | Recuo Seguro (Massa Insuficiente) | 2.29 KB < 500 KB. Overhead do decodificador supera qualquer ganho estrutural. |
| csv_gapminder_five_year.csv | Recuo Seguro (Massa Insuficiente) | 80.16 KB < 500 KB. Overhead do decodificador supera qualquer ganho estrutural. |
| csv_gdp.csv | Recuo Seguro (Entropia Dominante) | 549 KB. Dicionarios extraidos (Pais, Codigo, Ano), mas os valores de GDP (floats de alta entropia) comprimem mal. Brotli(residuo) + meta + decoder >= Brotli(arquivo). |
| csv_iris.csv | Recuo Seguro (Massa Insuficiente) | 3.77 KB < 500 KB. Overhead do decodificador supera qualquer ganho estrutural. |
| csv_penguins.csv | Recuo Seguro (Massa Insuficiente) | 13.16 KB < 500 KB. Overhead do decodificador supera qualquer ganho estrutural. |
| csv_population.csv | Recuo Seguro (Entropia Dominante) | 539 KB. Dicionarios extraidos (Pais, Codigo, Ano), mas Brotli ja captura a redundancia residual de forma otima. Brotli(residuo) + meta + decoder >= Brotli(arquivo). |
| csv_seattle_weather.csv | Recuo Seguro (Massa Insuficiente) | 47.09 KB < 500 KB. Overhead do decodificador supera qualquer ganho estrutural. |
| csv_titanic.csv | Recuo Seguro (Massa Insuficiente) | 55.68 KB < 500 KB. Overhead do decodificador supera qualquer ganho estrutural. |

## Conclusao

O Oraculo Gatekeeper converteu a derrota estatistica do P29.1 em inteligencia ontoprocedural:

- **Antes (P29.1):** 9 Deltas negativos, 1 Delta positivo — motor tentava forjar todos os arquivos.
- **Depois (P31.0):** 0 Deltas negativos, 0 perdas contra Brotli — motor recua onde a fisica da entropia favorece o compressor classico.

A TEIA nao e um compressor universal. E um Seletor: usa a ferramenta certa para cada tipo de dado.

Protocolo P31.0 finalizado.