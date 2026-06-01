# TEIA P25.0 - Law vs Noise and Representability Matrix

Status: deterministic discovery report for Storage as Computation.

## Invariantes

- P0 Core remains read-only: no file is compressed, stubbed, deleted, or moved.
- Write == Read is preserved: the mapper reads samples and writes only this matrix.
- The report contains no wall-clock timestamp, so identical input produces identical output.
- TEIA control files and corpus manifests are skipped by default because they are pointers or inventory, not organic samples.

## Scan Scope

| Field | Value |
|---|---:|
| Scan root | D:\TEIA_USER\MyRealData\Corpus30 |
| Files analyzed | 30 |
| Control files skipped | 1 |
| Read errors | 0 |
| Total bytes represented | 15944183 |
| Max sample bytes per file | 1048576 |
| Average law index | 0.80 |
| Average noise index | 0.42 |

## Ontological Classes

| Class | Count | Meaning |
|---|---:|---|
| DOMINIO ENTROPICO | 4 | Low law, high noise. Preserve by hash/CAS and avoid speculative synthesis. |
| DOMINIO HIBRIDO | 3 | Law and residue coexist. Split grammar into code and residual content into classic storage. |
| DOMINIO PROCEDURAL | 23 | High law, low noise. Best target for a generator. |

## Scientific Representability Classes

| Class | Count | Prediction | Meaning |
|---|---:|---|---|
| CLASSE A | 14 | TEIA VENCE | Alta lei e alta vantagem procedural. Estruturas N x M ou logs com gramatica forte. |
| CLASSE B | 9 | TEIA RECUA | Alta lei e baixa vantagem procedural. Brotli ja captura quase todo o ganho disponivel. |
| CLASSE C | 3 | TEIA RECUA | Baixa lei e baixa vantagem. Entropia organica domina. |
| CLASSE D | 4 | TEIA INVESTIGA | Falsa entropia. Parece ruido, mas ha indicio de gerador matematico. |

## Candidate Matrix

| Path | Domain | Rep Class | Prediction | Signal | Bytes | Brotli | TEIA estimate | Law | Noise | Advantage | Evidence | Next action |
|---|---|---|---|---|---:|---:|---:|---:|---:|---:|---|---|
| log_apache_2k.log | DOMINIO ENTROPICO | CLASSE D | TEIA INVESTIGA | repetition-pattern | 171239 | 9842 | 1966 | 0.33 | 0.40 | 0.80 | period_score=0.00; line_repeat=0.01; token_repeat=0.94; entropy=4.9697; printable=1.00; sample_bytes=171239 | Investigacao: testar gerador matematico antes de classificar como ruido |
| log_hdfs_2k.log | DOMINIO ENTROPICO | CLASSE D | TEIA INVESTIGA | repetition-pattern | 287848 | 51535 | 3041 | 0.28 | 0.46 | 0.94 | period_score=0.00; line_repeat=0.00; token_repeat=0.79; entropy=5.2168; printable=1.00; sample_bytes=287848 | Investigacao: testar gerador matematico antes de classificar como ruido |
| log_mac_2k.log | DOMINIO ENTROPICO | CLASSE C | TEIA RECUA | raw-bytes | 319414 | 41861 | 51563 | 0.05 | 0.67 | -0.23 | magic=unknown; entropy=5.4339; printable=1.00; sample_bytes=319414 | Indexacao: preservar por CAS/hash e evitar forja especulativa |
| log_openssh_2k.log | DOMINIO ENTROPICO | CLASSE D | TEIA INVESTIGA | repetition-pattern | 225216 | 14905 | 2076 | 0.33 | 0.42 | 0.86 | period_score=0.00; line_repeat=0.00; token_repeat=0.95; entropy=5.2112; printable=1.00; sample_bytes=225216 | Investigacao: testar gerador matematico antes de classificar como ruido |
| log_linux_2k.log | DOMINIO HIBRIDO | CLASSE D | TEIA INVESTIGA | csv-table | 216485 | 13472 | 3821 | 0.48 | 0.42 | 0.72 | csv_delim=;; columns=2; row_consistency=0.51; entropy=5.1701; printable=1.00; sample_bytes=216485 | Investigacao: testar gerador matematico antes de classificar como ruido |
| svg_commons_logo.svg | DOMINIO HIBRIDO | CLASSE C | TEIA RECUA | xml-svg-tree | 932 | 489 | 5075 | 0.62 | 0.54 | -9.38 | tags=24; unique_tags=8; attrs=34; entropy=5.3422; printable=1.00; sample_bytes=932 | Indexacao: preservar por CAS/hash e evitar forja especulativa |
| svg_switzerland_flag.svg | DOMINIO HIBRIDO | CLASSE C | TEIA RECUA | xml-svg-tree | 213 | 162 | 3987 | 0.44 | 0.54 | -23.61 | tags=4; unique_tags=2; attrs=9; entropy=4.9851; printable=1.00; sample_bytes=213 | Indexacao: preservar por CAS/hash e evitar forja especulativa |
| csv_co2_global.csv | DOMINIO PROCEDURAL | CLASSE B | TEIA RECUA | csv-table | 7137 | 2449 | 4171 | 0.95 | 0.41 | -0.70 | csv_delim=,; columns=8; row_consistency=1.00; entropy=3.4416; printable=1.00; sample_bytes=7137 | Recuo: manter Brotli/CAS; lei estrutural sem vantagem suficiente |
| csv_covid_countries_aggregated.csv | DOMINIO PROCEDURAL | CLASSE A | TEIA VENCE | csv-table | 5512931 | 1234156 | 46989 | 0.91 | 0.40 | 0.96 | csv_delim=,; columns=5; row_consistency=1.00; entropy=4.4624; printable=1.00; sample_bytes=1048576 | Forja: sintetizar gerador csv-table e provar Delta real por SHA-256 |
| csv_flights.csv | DOMINIO PROCEDURAL | CLASSE B | TEIA RECUA | csv-table | 2350 | 674 | 3307 | 0.89 | 0.42 | -3.91 | csv_delim=,; columns=3; row_consistency=1.00; entropy=4.6218; printable=1.00; sample_bytes=2350 | Recuo: manter Brotli/CAS; lei estrutural sem vantagem suficiente |
| csv_gapminder_five_year.csv | DOMINIO PROCEDURAL | CLASSE A | TEIA VENCE | csv-table | 82079 | 29784 | 5227 | 0.91 | 0.46 | 0.82 | csv_delim=,; columns=6; row_consistency=0.95; entropy=4.7797; printable=1.00; sample_bytes=82079 | Forja: sintetizar gerador csv-table e provar Delta real por SHA-256 |
| csv_gdp.csv | DOMINIO PROCEDURAL | CLASSE A | TEIA VENCE | csv-table | 562767 | 169973 | 11108 | 0.90 | 0.44 | 0.93 | csv_delim=,; columns=4; row_consistency=1.00; entropy=5.1858; printable=1.00; sample_bytes=562767 | Forja: sintetizar gerador csv-table e provar Delta real por SHA-256 |
| csv_iris.csv | DOMINIO PROCEDURAL | CLASSE B | TEIA RECUA | csv-table | 3858 | 837 | 3622 | 0.91 | 0.35 | -3.33 | csv_delim=,; columns=5; row_consistency=1.00; entropy=4.2591; printable=1.00; sample_bytes=3858 | Recuo: manter Brotli/CAS; lei estrutural sem vantagem suficiente |
| csv_penguins.csv | DOMINIO PROCEDURAL | CLASSE B | TEIA RECUA | csv-table | 13478 | 2785 | 4019 | 0.94 | 0.40 | -0.44 | csv_delim=,; columns=7; row_consistency=1.00; entropy=4.7925; printable=1.00; sample_bytes=13478 | Recuo: manter Brotli/CAS; lei estrutural sem vantagem suficiente |
| csv_population.csv | DOMINIO PROCEDURAL | CLASSE A | TEIA VENCE | csv-table | 552112 | 128814 | 9658 | 0.90 | 0.46 | 0.92 | csv_delim=,; columns=4; row_consistency=1.00; entropy=5.3768; printable=1.00; sample_bytes=552112 | Forja: sintetizar gerador csv-table e provar Delta real por SHA-256 |
| csv_seattle_weather.csv | DOMINIO PROCEDURAL | CLASSE A | TEIA VENCE | csv-table | 48219 | 11805 | 4052 | 0.92 | 0.34 | 0.66 | csv_delim=,; columns=6; row_consistency=1.00; entropy=3.9220; printable=1.00; sample_bytes=48219 | Forja: sintetizar gerador csv-table e provar Delta real por SHA-256 |
| csv_titanic.csv | DOMINIO PROCEDURAL | CLASSE A | TEIA VENCE | csv-table | 57018 | 8015 | 5412 | 1.00 | 0.36 | 0.32 | csv_delim=,; columns=15; row_consistency=1.00; entropy=4.5239; printable=1.00; sample_bytes=57018 | Forja: sintetizar gerador csv-table e provar Delta real por SHA-256 |
| json_barley.json | DOMINIO PROCEDURAL | CLASSE B | TEIA RECUA | json-schema | 8487 | 993 | 4880 | 0.98 | 0.39 | -3.91 | json_keys=480; unique_keys=4; grammar_density=0.14; entropy=4.7130; printable=1.00; sample_bytes=8487 | Recuo: manter Brotli/CAS; lei estrutural sem vantagem suficiente |
| json_cars.json | DOMINIO PROCEDURAL | CLASSE A | TEIA VENCE | json-schema | 100492 | 9290 | 7002 | 1.00 | 0.38 | 0.25 | json_keys=3654; unique_keys=9; grammar_density=0.08; entropy=4.5811; printable=1.00; sample_bytes=100492 | Forja: sintetizar gerador json-schema e provar Delta real por SHA-256 |
| json_countries_mledoze.json | DOMINIO PROCEDURAL | CLASSE A | TEIA VENCE | json-schema | 1398180 | 159741 | 65469 | 0.98 | 0.32 | 0.59 | json_keys=22213; unique_keys=282; grammar_density=0.05; entropy=3.9341; printable=1.00; sample_bytes=1048576 | Forja: sintetizar gerador json-schema e provar Delta real por SHA-256 |
| json_flights_2k.json | DOMINIO PROCEDURAL | CLASSE A | TEIA VENCE | json-schema | 178495 | 26691 | 9729 | 0.99 | 0.38 | 0.64 | json_keys=10000; unique_keys=5; grammar_density=0.15; entropy=4.7168; printable=1.00; sample_bytes=178495 | Forja: sintetizar gerador json-schema e provar Delta real por SHA-256 |
| json_miserables_graph.json | DOMINIO PROCEDURAL | CLASSE B | TEIA RECUA | json-schema | 12372 | 1756 | 5483 | 1.00 | 0.36 | -2.12 | json_keys=995; unique_keys=8; grammar_density=0.21; entropy=4.4800; printable=1.00; sample_bytes=12372 | Recuo: manter Brotli/CAS; lei estrutural sem vantagem suficiente |
| json_movies.json | DOMINIO PROCEDURAL | CLASSE A | TEIA VENCE | json-schema | 1399981 | 178488 | 40901 | 1.00 | 0.40 | 0.77 | json_keys=38498; unique_keys=16; grammar_density=0.08; entropy=4.9934; printable=1.00; sample_bytes=1048576 | Forja: sintetizar gerador json-schema e provar Delta real por SHA-256 |
| json_us_10m_topo.json | DOMINIO PROCEDURAL | CLASSE A | TEIA VENCE | json-schema | 642361 | 192255 | 42417 | 1.00 | 0.40 | 0.78 | json_keys=10687; unique_keys=11; grammar_density=0.33; entropy=4.3648; printable=1.00; sample_bytes=642361 | Forja: sintetizar gerador json-schema e provar Delta real por SHA-256 |
| json_world_geojson.json | DOMINIO PROCEDURAL | CLASSE A | TEIA VENCE | json-schema | 256950 | 90280 | 26075 | 1.00 | 0.46 | 0.71 | json_keys=1262; unique_keys=7; grammar_density=0.18; entropy=4.2761; printable=1.00; sample_bytes=256950 | Forja: sintetizar gerador json-schema e provar Delta real por SHA-256 |
| json_worldbank_countries.json | DOMINIO PROCEDURAL | CLASSE A | TEIA VENCE | json-schema | 113832 | 9871 | 8011 | 1.00 | 0.39 | 0.19 | json_keys=6516; unique_keys=16; grammar_density=0.13; entropy=4.7404; printable=1.00; sample_bytes=113832 | Forja: sintetizar gerador json-schema e provar Delta real por SHA-256 |
| json_worldbank_gdp.json | DOMINIO PROCEDURAL | CLASSE A | TEIA VENCE | json-schema | 3688512 | 212300 | 46859 | 1.00 | 0.40 | 0.78 | json_keys=57714; unique_keys=15; grammar_density=0.13; entropy=5.0341; printable=1.00; sample_bytes=1048576 | Forja: sintetizar gerador json-schema e provar Delta real por SHA-256 |
| svg_ghostscript_tiger.svg | DOMINIO PROCEDURAL | CLASSE B | TEIA RECUA | xml-svg-tree | 68630 | 22095 | 20903 | 0.78 | 0.48 | 0.05 | tags=724; unique_tags=3; attrs=1106; entropy=4.5503; printable=1.00; sample_bytes=68630 | Recuo: manter Brotli/CAS; lei estrutural sem vantagem suficiente |
| xml_cd_catalog.xml | DOMINIO PROCEDURAL | CLASSE B | TEIA RECUA | xml-svg-tree | 4866 | 1005 | 4731 | 0.77 | 0.43 | -3.71 | tags=366; unique_tags=8; attrs=2; entropy=4.8134; printable=1.00; sample_bytes=4866 | Recuo: manter Brotli/CAS; lei estrutural sem vantagem suficiente |
| xml_plant_catalog.xml | DOMINIO PROCEDURAL | CLASSE B | TEIA RECUA | xml-svg-tree | 7729 | 1194 | 4761 | 0.74 | 0.43 | -2.99 | tags=506; unique_tags=8; attrs=2; entropy=4.9943; printable=1.00; sample_bytes=7729 | Recuo: manter Brotli/CAS; lei estrutural sem vantagem suficiente |

## Routing Rule

- Procedural: synthesize a domain generator and prove byte identity by SHA-256.
- Hybrid: encode stable grammar as code, then preserve residual entropy with classical storage.
- Entropic: index and preserve; do not spend synthesis cycles where noise dominates.
- Class A predicts real Delta gain before forging; Class B and Class C predict retreat; Class D requires a mathematical generator probe.
