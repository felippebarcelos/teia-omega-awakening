# TEIA P24.0 - Law vs Noise Matrix

Status: deterministic discovery report for Storage as Computation.

## Invariantes

- P0 Core remains read-only: no file is compressed, stubbed, deleted, or moved.
- Write == Read is preserved: the mapper reads samples and writes only this matrix.
- The report contains no wall-clock timestamp, so identical input produces identical output.
- TEIA control files are skipped by default because stubs are pointers, not organic samples.

## Scan Scope

| Field | Value |
|---|---:|
| Scan root | D:\TEIA_USER\MyRealData |
| Files analyzed | 8 |
| TEIA control files skipped | 70 |
| Read errors | 0 |
| Total bytes represented | 9508304 |
| Max sample bytes per file | 1048576 |
| Average law index | 0.78 |
| Average noise index | 0.47 |

## Ontological Classes

| Class | Count | Meaning |
|---|---:|---|
| DOMINIO ENTROPICO | 1 | Low law, high noise. Preserve by hash/CAS and avoid speculative synthesis. |
| DOMINIO HIBRIDO | 3 | Law and residue coexist. Split grammar into code and residual content into classic storage. |
| DOMINIO PROCEDURAL | 4 | High law, low noise. Best target for a generator. |

## Candidate Matrix

| Path | Class | Signal | Bytes | Law | Noise | Ratio | Evidence | Next action |
|---|---|---|---:|---:|---:|---:|---|---|
| Autosynth_Crucible\C_autosynth_ps1.ps1 | DOMINIO ENTROPICO | repetition-pattern | 34688 | 0.24 | 0.48 | 0.50 | period_score=0.00; line_repeat=0.04; token_repeat=0.68; entropy=5.1785; printable=1.00; sample_bytes=34688 | Indexacao: preservar por CAS/hash e evitar forja especulativa |
| Autosynth_Crucible\A_benchmark_json.json | DOMINIO HIBRIDO | json-schema | 38561 | 1.00 | 0.61 | 1.64 | json_keys=1193; unique_keys=22; grammar_density=0.07; entropy=4.6145; printable=1.00; sample_bytes=38561 | Roteador: extrair gramatica para codigo e isolar residuo |
| RealWorld_Crucible\ingestion_manifest.json | DOMINIO HIBRIDO | json-schema | 780 | 0.64 | 0.66 | 0.97 | json_keys=15; unique_keys=5; grammar_density=0.05; entropy=5.3428; printable=1.00; sample_bytes=780 | Roteador: extrair gramatica para codigo e isolar residuo |
| Syslog_Lunatic.log | DOMINIO HIBRIDO | structured-log | 1013804 | 0.60 | 0.44 | 1.34 | timestamp_ratio=0.63; level_ratio=0.63; shape_repeat=0.25; kv_density=0.78; entropy=5.1125; printable=1.00; sample_by... | Roteador: extrair gramatica para codigo e isolar residuo |
| Autosynth_Crucible\B_syslog_log.log | DOMINIO PROCEDURAL | structured-log | 25651 | 0.87 | 0.46 | 1.89 | timestamp_ratio=1.00; level_ratio=1.00; shape_repeat=0.50; kv_density=1.00; entropy=5.1479; printable=1.00; sample_by... | Forja: sintetizar gerador structured-log e provar Write == Read |
| RealWorld_Crucible\countries.json | DOMINIO PROCEDURAL | json-schema | 1398180 | 0.98 | 0.32 | 3.03 | json_keys=22213; unique_keys=282; grammar_density=0.05; entropy=3.9341; printable=1.00; sample_bytes=1048576 | Forja: sintetizar gerador json-schema e provar Write == Read |
| RealWorld_Crucible\covid_countries_aggregated.csv | DOMINIO PROCEDURAL | csv-table | 5512931 | 0.91 | 0.40 | 2.30 | csv_delim=,; columns=5; row_consistency=1.00; entropy=4.4624; printable=1.00; sample_bytes=1048576 | Forja: sintetizar gerador csv-table e provar Write == Read |
| RealWorld_Crucible\worldbank_gdp.json | DOMINIO PROCEDURAL | json-schema | 1483709 | 1.00 | 0.40 | 2.51 | json_keys=56228; unique_keys=15; grammar_density=0.13; entropy=5.0163; printable=1.00; sample_bytes=1048576 | Forja: sintetizar gerador json-schema e provar Write == Read |

## Routing Rule

- Procedural: synthesize a domain generator and prove byte identity by SHA-256.
- Hybrid: encode stable grammar as code, then preserve residual entropy with classical storage.
- Entropic: index and preserve; do not spend synthesis cycles where noise dominates.
