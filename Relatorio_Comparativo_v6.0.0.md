# Relatorio Comparativo v6.0.0 — TEIA Estrategia por Bucket

> **Gerado**: 2026-05-25T12:08:16Z
> **Motor**: TEIA-Core-v0.8.1.psm1 | SHA-256: a0c73c9f743fdbf3645b9eae53e220e5a5aacb3df8dbd1b3a427541fa2f82484 | 18191 bytes
> **Hardware**: i3-10100F, 16GB RAM, HDD
> **Corpus**: D4_REAL_MANIFEST.json R1-R46 (46 arquivos processados)

---

## Estrategia por Bucket

| Bucket | Limiar | Opcode TEIA | Dicionario |
|--------|--------|-------------|------------|
| tiny | < 5 KB | zstd.raw | nenhum |
| small | 5 KB - 100 KB | dict.zstd_shared | dict-small (64KB, 10 Google API docs) |
| medium | 100 KB - 500 KB | dict.zstd_shared | dict-medium (110KB, 8 botocore service-2) |
| large | >= 500 KB | zstd.raw | nenhum |

## Dicionarios

| Nome | SHA-256 | Bytes | Corpus de Treino |
|------|---------|-------|-----------------|
| dict-small | 4be54040b288207e7650274509c20cce66470f76499ef3ac372a046c5972cd5a | 63147 | 10 Google API discovery docs (agents_v2 env, nao presentes no D4) |
| dict-medium | 6c72ae7246b413b8b635078167da4d5786276435fea3cd140326197744562d8a | 80055 | 8 botocore service-2.json ~200KB (R21,R22,R25,R27,R28,R32,R34,R36) [T] |

**Separacao treino/teste:**
- dict-small: treino em dados externos (nao presentes no D4) -> R7-R20 sao clean test
- dict-medium: R21,R22,R25,R27,R28,R32,R34,R36 marcados [T] (dados de treino)

---

## Resultados por Arquivo

| ID | T | Bucket | Original | A:LZMA | B:Zstd | C:Best-raw | D:TEIA | Overhead D-C | D-A | SHA | W=R |
|----|---|--------|----------|--------|--------|------------|--------|-------------|-----|-----|-----|
| R1 |  | tiny | 2047B | 442B (21.59%) | 296B (14.46%) | 296B (14.46%) | 462B (22.57%) | 166B | +20B | OK | OK |
| R2 |  | tiny | 2045B | 1029B (50.32%) | 893B (43.67%) | 893B (43.67%) | 1055B (51.59%) | 162B | +26B | OK | OK |
| R3 |  | tiny | 2033B | 428B (21.05%) | 279B (13.72%) | 279B (13.72%) | 445B (21.89%) | 166B | +17B | OK | OK |
| R4 |  | tiny | 2032B | 435B (21.41%) | 284B (13.98%) | 284B (13.98%) | 450B (22.15%) | 166B | +15B | OK | OK |
| R5 |  | tiny | 2018B | 859B (42.57%) | 689B (34.14%) | 689B (34.14%) | 854B (42.32%) | 165B | -5B | OK | OK |
| R6 |  | tiny | 2016B | 1002B (49.7%) | 865B (42.91%) | 865B (42.91%) | 1027B (50.94%) | 162B | +25B | OK | OK |
| R7 |  | small | 20475B | 3807B (18.59%) | 3630B (17.73%) | 2705B (13.21%) | 2987B (14.59%) | 282B | -820B | OK | OK |
| R8 |  | small | 20454B | 4436B (21.69%) | 4312B (21.08%) | 4046B (19.78%) | 4351B (21.27%) | 305B | -85B | OK | OK |
| R9 |  | small | 20446B | 4434B (21.69%) | 4299B (21.03%) | 4046B (19.79%) | 4344B (21.25%) | 298B | -90B | OK | OK |
| R10 |  | small | 20429B | 4442B (21.74%) | 4313B (21.11%) | 4042B (19.79%) | 4339B (21.24%) | 297B | -103B | OK | OK |
| R11 |  | small | 20347B | 4030B (19.81%) | 3887B (19.1%) | 3687B (18.12%) | 3966B (19.49%) | 279B | -64B | OK | OK |
| R12 |  | small | 20344B | 1786B (8.78%) | 1557B (7.65%) | 1513B (7.44%) | 1783B (8.76%) | 270B | -3B | OK | OK |
| R13 |  | small | 20330B | 4369B (21.49%) | 4246B (20.89%) | 3978B (19.57%) | 4276B (21.03%) | 298B | -93B | OK | OK |
| R14 |  | small | 20210B | 3474B (17.19%) | 3317B (16.41%) | 2882B (14.26%) | 3153B (15.6%) | 271B | -321B | OK | OK |
| R15 |  | small | 20190B | 5351B (26.5%) | 5207B (25.79%) | 3949B (19.56%) | 4222B (20.91%) | 273B | -1129B | OK | OK |
| R16 |  | small | 20170B | 4535B (22.48%) | 4403B (21.83%) | 3037B (15.06%) | 3317B (16.45%) | 280B | -1218B | OK | OK |
| R17 |  | small | 20156B | 3495B (17.34%) | 3317B (16.46%) | 2938B (14.58%) | 3209B (15.92%) | 271B | -286B | OK | OK |
| R18 |  | small | 20116B | 3484B (17.32%) | 3338B (16.59%) | 3187B (15.84%) | 3456B (17.18%) | 269B | -28B | OK | OK |
| R19 |  | small | 20018B | 5040B (25.18%) | 4929B (24.62%) | 3719B (18.58%) | 3998B (19.97%) | 279B | -1042B | OK | OK |
| R20 |  | small | 19981B | 2468B (12.35%) | 2387B (11.95%) | 2344B (11.73%) | 2653B (13.28%) | 309B | +185B | OK | OK |
| R21 | T | medium | 202197B | 19191B (9.49%) | 18777B (9.29%) | 15676B (7.75%) | 15948B (7.89%) | 272B | -3243B | OK | OK |
| R22 | T | medium | 201124B | 24921B (12.39%) | 24858B (12.36%) | 21095B (10.49%) | 21367B (10.62%) | 272B | -3554B | OK | OK |
| R23 |  | medium | 201038B | 71821B (35.73%) | 72572B (36.1%) | 71868B (35.75%) | 72145B (35.89%) | 277B | +324B | OK | OK |
| R24 |  | medium | 201038B | 71821B (35.73%) | 72572B (36.1%) | 71868B (35.75%) | 72180B (35.9%) | 312B | +359B | OK | OK |
| R25 | T | medium | 200275B | 20967B (10.47%) | 20523B (10.25%) | 17370B (8.67%) | 17642B (8.81%) | 272B | -3325B | OK | OK |
| R26 |  | medium | 200207B | 26695B (13.33%) | 27035B (13.5%) | 26606B (13.29%) | 26910B (13.44%) | 304B | +215B | OK | OK |
| R27 | T | medium | 199319B | 21624B (10.85%) | 21301B (10.69%) | 19755B (9.91%) | 20027B (10.05%) | 272B | -1597B | OK | OK |
| R28 | T | medium | 198376B | 15062B (7.59%) | 14956B (7.54%) | 11681B (5.89%) | 11953B (6.03%) | 272B | -3109B | OK | OK |
| R29 |  | medium | 197970B | 21237B (10.73%) | 20880B (10.55%) | 19386B (9.79%) | 19658B (9.93%) | 272B | -1579B | OK | OK |
| R30 |  | medium | 196833B | 33512B (17.03%) | 34273B (17.41%) | 33791B (17.17%) | 34071B (17.31%) | 280B | +559B | OK | OK |
| R31 |  | medium | 196586B | 8656B (4.4%) | 7694B (3.91%) | 7583B (3.86%) | 7859B (4%) | 276B | -797B | OK | OK |
| R32 | T | medium | 195993B | 20651B (10.54%) | 20356B (10.39%) | 16826B (8.59%) | 17098B (8.72%) | 272B | -3553B | OK | OK |
| R33 |  | medium | 195500B | 4544B (2.32%) | 3686B (1.89%) | 3498B (1.79%) | 3780B (1.93%) | 282B | -764B | OK | OK |
| R34 | T | medium | 194813B | 23410B (12.02%) | 23073B (11.84%) | 19484B (10%) | 19756B (10.14%) | 272B | -3654B | OK | OK |
| R35 |  | medium | 194806B | 20939B (10.75%) | 20573B (10.56%) | 19104B (9.81%) | 19376B (9.95%) | 272B | -1563B | OK | OK |
| R36 | T | medium | 194634B | 19306B (9.92%) | 19005B (9.76%) | 17520B (9%) | 17792B (9.14%) | 272B | -1514B | OK | OK |
| R37 |  | large | 1912912B | 46278B (2.42%) | 46485B (2.43%) | 46485B (2.43%) | 46651B (2.44%) | 166B | +373B | OK | OK |
| R38 |  | large | 1894245B | 309476B (16.34%) | 311845B (16.46%) | 311845B (16.46%) | 312014B (16.47%) | 169B | +2538B | OK | OK |
| R39 |  | large | 1879221B | 58521B (3.11%) | 58459B (3.11%) | 58459B (3.11%) | 58632B (3.12%) | 173B | +111B | OK | OK |
| R40 |  | large | 1814869B | 234683B (12.93%) | 241154B (13.29%) | 241154B (13.29%) | 241325B (13.3%) | 171B | +6642B | OK | OK |
| R41 |  | large | 1803075B | 169299B (9.39%) | 166626B (9.24%) | 166626B (9.24%) | 166792B (9.25%) | 166B | -2507B | OK | OK |
| R42 |  | large | 1782936B | 158711B (8.9%) | 182923B (10.26%) | 182923B (10.26%) | 183094B (10.27%) | 171B | +24383B | OK | OK |
| R43 |  | large | 1774213B | 566971B (31.96%) | 625957B (35.28%) | 625957B (35.28%) | 626133B (35.29%) | 176B | +59162B | OK | OK |
| R44 |  | large | 1774213B | 566971B (31.96%) | 625957B (35.28%) | 625957B (35.28%) | 626123B (35.29%) | 166B | +59152B | OK | OK |
| R45 |  | large | 1271736B | 100498B (7.9%) | 97899B (7.7%) | 97899B (7.7%) | 98065B (7.71%) | 166B | -2433B | OK | OK |
| R46 |  | large | 1181423B | 133528B (11.3%) | 137227B (11.62%) | 137227B (11.62%) | 137394B (11.63%) | 167B | +3866B | OK | OK |

---

## Sumario por Bucket

| Bucket | Count | Wins | Losses | Avg A% | Avg D% | Avg Overhead | SHA-256 | Savings liquido |
|--------|-------|------|--------|--------|--------|--------------|---------|-----------------|
| tiny | 6 | 1 | 5 | 34.44% | 35.24% | 164B | 100% OK | -98B |
| small | 14 | 13 | 1 | 19.44% | 17.64% | 284B | 100% OK | 5097B |
| medium | 16 | 12 | 4 | 13.33% | 12.48% | 278B | 100% OK | 26795B |
| large | 10 | 2 | 8 | 13.62% | 14.48% | 169B | 100% OK | -151287B |

**Total**: 28/46 TEIA ganha | 0 erros

---

## Analise por Bucket

### Tiny (<5KB)

Container overhead (272B) representa ~13% do arquivo original.
TEIA nao e competitivo neste bucket — overhead estrutural domina.
Ganhos: 1/6 — esperado 0 (overhead > savings).

### Small (5KB-100KB)

dict-small treinado em 10 Google API docs (~20KB, dominio externo ao D4).
Todos os arquivos small (R7-R20) sao clean test — sem contaminacao de treino.
Ganhos: 13/14 | Avg LZMA=19.44% -> TEIA=17.64%

### Medium (100KB-500KB)

dict-medium reutilizado de v5.0.0 (6c72ae..., 80KB, botocore service-2).
R21,R22,R25,R27,R28,R32,R34,R36 marcados [T] (dados de treino).
Ganhos: 12/16 | Avg LZMA=13.33% -> TEIA=12.48%

### Large (>=500KB)

Zstd.raw: sem dicionario (dict treinado em ~200KB arquivos prejudica grandes arquivos).
Anti-pattern confirmado em v5-Full: dict-medium adicionava ~18KB em sagemaker (1.8MB).
Ganhos: 2/10 | Avg LZMA=13.62% -> TEIA=14.48%

---

## Comparativo v5-Full vs v6

| Aspecto | v5-Full (dict universal) | v6 (por bucket) |
|---------|--------------------------|-----------------|
| Dict estrategia | um dict-medium universal | dict-small / dict-medium / zstd.raw |
| Large files | dict-medium (PREJUDICA) | zstd.raw (sem dict) |
| Small files | dict-medium (cross-domain) | dict-small (dominio proximo) |
| Wins total (v5-Full) | 24/46 | 28/46 |

---

## Erros (0)

Nenhum erro.

---

*TEIA-Core v0.8.1 | Harness v6.0.0 | Felippe Barcelos | 2026-05-25T12:08:16Z*
