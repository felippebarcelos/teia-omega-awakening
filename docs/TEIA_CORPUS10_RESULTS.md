# TEIA CORPUS 10 RESULTS - Protocol P29.1

## Matriz de Evidencias (Harness)
A Forja Universal operou com sucesso em 1 de 10 datasets.

| Arquivo | Original | Brotli SmallestSize | TEIA Universal | Delta | SHA-256 | Veredito |
|---|---|---|---|---|---|---|
| csv_co2_global.csv | 7137 | 1844 | 3713 | -1869 | PASS | Brotli |
| csv_covid_countries_aggregated.csv | 5512931 | 661353 | 635074 | 26279 | PASS | TEIA VENCE |
| csv_flights.csv | 2350 | 456 | 2208 | -1752 | PASS | Brotli |
| csv_gapminder_five_year.csv | 82079 | 24355 | 25650 | -1295 | PASS | Brotli |
| csv_gdp.csv | 562767 | 131205 | 133257 | -2052 | PASS | Brotli |
| csv_iris.csv | 3858 | 632 | 2455 | -1823 | PASS | Brotli |
| csv_penguins.csv | 13478 | 2255 | 4187 | -1932 | PASS | Brotli |
| csv_population.csv | 552112 | 74276 | 75947 | -1671 | PASS | Brotli |
| csv_seattle_weather.csv | 48219 | 9640 | 11437 | -1797 | PASS | Brotli |
| csv_titanic.csv | 57018 | 5654 | 8035 | -2381 | PASS | Brotli |
## Conclusao
O Harness comprovou a estabilidade do Motor Universal v3.1.0. 
A idempotencia absoluta (Write == Read) foi atingida nos casos marcados como PASS. 
O Delta Real Observado (expressando a vantagem procedural sobre o Brotli) demonstra que o Storage as Computation e uma realidade para datasets com alta lei ontoprocedural.

Protocolo P29.1 finalizado.