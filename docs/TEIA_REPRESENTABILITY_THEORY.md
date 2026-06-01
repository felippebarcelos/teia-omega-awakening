# TEIA P25.0 - Theory of Representability

## Abstract

This document tests a falsifiable hypothesis: high structural law does not necessarily imply high procedural advantage. The oracle estimates whether Storage as Computation should beat Brotli Optimal before any code forge is attempted.

## Corpus and Method

| Field | Value |
|---|---:|
| Scan root | D:\TEIA_USER\MyRealData\Corpus30 |
| Files analyzed | 30 |
| Control files skipped | 1 |
| Read errors | 0 |
| Max sample bytes per file | 1048576 |
| Original bytes represented | 15944183 |
| Brotli Optimal bytes | 2627517 |
| TEIA pre-forge estimate bytes | 456315 |
| Portfolio predicted Delta gain pct | 82.63 |

Method: for each file, the mapper reads a bounded sample, estimates Law and Noise, measures Brotli Optimal with .NET BrotliStream, estimates seed plus decoder size, and emits a pre-forge prediction.

## Representability Classes

| Class | Count | Prediction | Criterion |
|---|---:|---|---|
| CLASSE A | 14 | TEIA VENCE | High law plus estimated seed and decoder below Brotli by a material margin. |
| CLASSE B | 9 | TEIA RECUA | High law, but dictionaries or organic residue make Brotli already competitive. |
| CLASSE C | 3 | TEIA RECUA | Low law and low advantage. |
| CLASSE D | 4 | TEIA INVESTIGA | Apparent noise with possible mathematical generator. |

## Statistical Claim

Em 100.0% dos arquivos de Classe A, a TEIA confirma a viabilidade pre-forge do Storage as Computation contra Brotli Optimal.

Predicoes de vitoria ou investigacao: 18. Predicoes de recuo: 12.

## Evidence Table

| File | Class | Prediction | Original | Brotli Optimal | TEIA estimate | Advantage | Law | Noise | Signal |
|---|---|---|---:|---:|---:|---:|---:|---:|---|
| csv_covid_countries_aggregated.csv | CLASSE A | TEIA VENCE | 5512931 | 1234156 | 46989 | 0.96 | 0.91 | 0.40 | csv-table |
| csv_gapminder_five_year.csv | CLASSE A | TEIA VENCE | 82079 | 29784 | 5227 | 0.82 | 0.91 | 0.46 | csv-table |
| csv_gdp.csv | CLASSE A | TEIA VENCE | 562767 | 169973 | 11108 | 0.93 | 0.90 | 0.44 | csv-table |
| csv_population.csv | CLASSE A | TEIA VENCE | 552112 | 128814 | 9658 | 0.92 | 0.90 | 0.46 | csv-table |
| csv_seattle_weather.csv | CLASSE A | TEIA VENCE | 48219 | 11805 | 4052 | 0.66 | 0.92 | 0.34 | csv-table |
| csv_titanic.csv | CLASSE A | TEIA VENCE | 57018 | 8015 | 5412 | 0.32 | 1.00 | 0.36 | csv-table |
| json_cars.json | CLASSE A | TEIA VENCE | 100492 | 9290 | 7002 | 0.25 | 1.00 | 0.38 | json-schema |
| json_countries_mledoze.json | CLASSE A | TEIA VENCE | 1398180 | 159741 | 65469 | 0.59 | 0.98 | 0.32 | json-schema |
| json_flights_2k.json | CLASSE A | TEIA VENCE | 178495 | 26691 | 9729 | 0.64 | 0.99 | 0.38 | json-schema |
| json_movies.json | CLASSE A | TEIA VENCE | 1399981 | 178488 | 40901 | 0.77 | 1.00 | 0.40 | json-schema |
| json_us_10m_topo.json | CLASSE A | TEIA VENCE | 642361 | 192255 | 42417 | 0.78 | 1.00 | 0.40 | json-schema |
| json_world_geojson.json | CLASSE A | TEIA VENCE | 256950 | 90280 | 26075 | 0.71 | 1.00 | 0.46 | json-schema |
| json_worldbank_countries.json | CLASSE A | TEIA VENCE | 113832 | 9871 | 8011 | 0.19 | 1.00 | 0.39 | json-schema |
| json_worldbank_gdp.json | CLASSE A | TEIA VENCE | 3688512 | 212300 | 46859 | 0.78 | 1.00 | 0.40 | json-schema |
| csv_co2_global.csv | CLASSE B | TEIA RECUA | 7137 | 2449 | 4171 | -0.70 | 0.95 | 0.41 | csv-table |
| csv_flights.csv | CLASSE B | TEIA RECUA | 2350 | 674 | 3307 | -3.91 | 0.89 | 0.42 | csv-table |
| csv_iris.csv | CLASSE B | TEIA RECUA | 3858 | 837 | 3622 | -3.33 | 0.91 | 0.35 | csv-table |
| csv_penguins.csv | CLASSE B | TEIA RECUA | 13478 | 2785 | 4019 | -0.44 | 0.94 | 0.40 | csv-table |
| json_barley.json | CLASSE B | TEIA RECUA | 8487 | 993 | 4880 | -3.91 | 0.98 | 0.39 | json-schema |
| json_miserables_graph.json | CLASSE B | TEIA RECUA | 12372 | 1756 | 5483 | -2.12 | 1.00 | 0.36 | json-schema |
| svg_ghostscript_tiger.svg | CLASSE B | TEIA RECUA | 68630 | 22095 | 20903 | 0.05 | 0.78 | 0.48 | xml-svg-tree |
| xml_cd_catalog.xml | CLASSE B | TEIA RECUA | 4866 | 1005 | 4731 | -3.71 | 0.77 | 0.43 | xml-svg-tree |
| xml_plant_catalog.xml | CLASSE B | TEIA RECUA | 7729 | 1194 | 4761 | -2.99 | 0.74 | 0.43 | xml-svg-tree |
| log_mac_2k.log | CLASSE C | TEIA RECUA | 319414 | 41861 | 51563 | -0.23 | 0.05 | 0.67 | raw-bytes |
| svg_commons_logo.svg | CLASSE C | TEIA RECUA | 932 | 489 | 5075 | -9.38 | 0.62 | 0.54 | xml-svg-tree |
| svg_switzerland_flag.svg | CLASSE C | TEIA RECUA | 213 | 162 | 3987 | -23.61 | 0.44 | 0.54 | xml-svg-tree |
| log_apache_2k.log | CLASSE D | TEIA INVESTIGA | 171239 | 9842 | 1966 | 0.80 | 0.33 | 0.40 | repetition-pattern |
| log_hdfs_2k.log | CLASSE D | TEIA INVESTIGA | 287848 | 51535 | 3041 | 0.94 | 0.28 | 0.46 | repetition-pattern |
| log_linux_2k.log | CLASSE D | TEIA INVESTIGA | 216485 | 13472 | 3821 | 0.72 | 0.48 | 0.42 | csv-table |
| log_openssh_2k.log | CLASSE D | TEIA INVESTIGA | 225216 | 14905 | 2076 | 0.86 | 0.33 | 0.42 | repetition-pattern |

## Interpretation

- Class A is the forge queue: tabular matrices, structured logs, and repeated grammars where structural overhead exceeds what LZ77-style windows exploit.
- Class B is the important negative result: high Law can still lose when dictionaries and residual values dominate representation cost.
- Class C is preservation territory: the Core should index, hash, and avoid speculative synthesis.
- Class D is a research queue: the mapper must test for hidden mathematical generators before calling the data entropic.

## Operational Boundary

This is a predictor, not a forged proof. Final victory still requires a decoder, a seed, and SHA-256 Write == Read verification.
