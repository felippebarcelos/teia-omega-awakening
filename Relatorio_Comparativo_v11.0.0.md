# Relatorio Comparativo v11.0.0 — TEIA v0.11.0: opcode cmp.lzma (LZMA1 FORMAT_ALONE)

> **Gerado**: 2026-05-25T20:20:27Z
> **Motor**: TEIA-Core-v0.11.0.psm1 | SHA-256: a56b18c0e17f4d1037340adf78f057f44e0fdbe21a5201fca6e1d17fb379ec39 | 35864 bytes
> **Corpus**: D8_STRESS_MANIFEST.json | 17 arquivos | tokenizers + activity logs
> **Dict**: NENHUM | medida limpa do Selector Engine v11 com cmp.lzma
> **Python**: D:\bruto\TEIA\TEIA_ATLAS\Materia_Bruta\D_Drive\TEIA_Data\python\python.exe | hasPython=True
> **Probe sets**: tiny→{cmp.zstd} | small→{cmp.zstd,cmp.lzma} | medium→{cmp.lzma,cmp.zstd} | large→{cmp.lzma,cmp.xz,zstd.raw}
> **Colunas**: A=7z-LZMA-archive | B=Zstd-raw-payload | C=Python-LZMA1-payload | D=TEIA-v11-output
> **Delta**: D-A negativo = TEIA vence LZMA | C-A negativo = Python LZMA1 bate 7z antes de overhead

---

## Resultados por Arquivo

| ID | Nome | Typ | Bucket | Orig | A:7z-LZMA | B:Zstd | C:Py-LZMA1 | D:TEIA-v11 | WIN | D-A | C-A | OPCODE | RAZAO | SHA |
|----|------|-----|--------|------|-----------|--------|------------|------------|-----|-----|-----|--------|-------|-----|
| S1 | Flights-activity.json | LOG | small | 21784B | 2537B | 2493B | 2333B | 2409B | SIM | -128B | -204B | C.lzma | GANHA | OK |
| S2 | Assistant-activity.json | LOG | small | 24518B | 2502B | 2536B | 2247B | 2325B | SIM | -177B | -255B | C.lzma | GANHA | OK |
| S3 | Video Search-activity.json | LOG | small | 39421B | 6987B | 7081B | 6692B | 6773B | SIM | -214B | -295B | C.lzma | GANHA | OK |
| S4 | Shopping-activity.json | LOG | small | 53851B | 8079B | 8537B | 7751B | 7828B | SIM | -251B | -328B | C.lzma | GANHA | OK |
| S5 | Maps-activity.json | LOG | medium | 127138B | 15297B | 15944B | 14514B | 14587B | SIM | -710B | -783B | C.lzma | GANHA | OK |
| S6 | Chrome-activity.json | LOG | medium | 147252B | 30112B | 31103B | 29686B | 29761B | SIM | -351B | -426B | C.lzma | GANHA | OK |
| S7 | Help-activity.json | LOG | medium | 184547B | 15609B | 16166B | 14631B | 14704B | SIM | -905B | -978B | C.lzma | GANHA | OK |
| S8 | AI Mode-activity.json | LOG | medium | 201038B | 71821B | 72572B | 71427B | 71503B | SIM | -318B | -394B | C.lzma | GANHA | OK |
| S9 | Ads-activity.json | LOG | medium | 268586B | 35702B | 36828B | 34777B | 34849B | SIM | -853B | -925B | C.lzma | GANHA | OK |
| S10 | Android TV-activity.json | LOG | medium | 290116B | 12783B | 13224B | 10056B | 10135B | SIM | -2648B | -2727B | C.lzma | GANHA | OK |
| S11 | Google Play Store-activity.json | LOG | medium | 336170B | 11318B | 11427B | 10094B | 10180B | SIM | -1138B | -1224B | C.lzma | GANHA | OK |
| S12 | Google Analytics-activity.json | LOG | large | 889122B | 44594B | 49124B | 42208B | 42293B | SIM | -2301B | -2386B | C.lzma | GANHA | OK |
| S13 | AI Mode-activity.json | LOG | large | 977929B | 192760B | 195120B | 191058B | 191134B | SIM | -1626B | -1702B | C.lzma | GANHA | OK |
| S14 | Google Translate-activity.json | LOG | large | 1782936B | 158711B | 182923B | 155464B | 155549B | SIM | -3162B | -3247B | C.lzma | GANHA | OK |
| S15 | Image Search-activity.json | LOG | large | 1814869B | 234683B | 241154B | 226472B | 226553B | SIM | -8130B | -8211B | C.lzma | GANHA | OK |
| S16 | anthropic_tokenizer.json | TOK | large | 1774213B | 566971B | 625957B | 566180B | 566259B | SIM | -712B | -791B | C.lzma | GANHA | OK |
| S17 | tokenizer.json | TOK | large | 2203239B | 458926B | 515822B | 457772B | 457841B | SIM | -1085B | -1154B | C.lzma | GANHA | OK |

---

## Sumario por Bucket

| Bucket | N | Wins | A% | B% | D% | Ovhd | LJ | OC | C.lzma | C.xz | Z.raw | C.zst | SHA |
|--------|---|------|----|----|----|------|----|----|--------|------|-------|-------|-----|
| small | 4 | 4/4 | 13.64% | 13.9% | 13.06% | ~78B | 0 | 0 | 4 | 0 | 0 | 0 | 100%OK |
| medium | 7 | 7/7 | 13.96% | 14.31% | 13.53% | ~76B | 0 | 0 | 7 | 0 | 0 | 0 | 100%OK |
| large | 6 | 6/6 | 16.56% | 17.95% | 16.37% | ~79B | 0 | 0 | 6 | 0 | 0 | 0 | 100%OK |
| **TOTAL** | **17** | **17/17** | — | — | — | — | — | — | — | — | — | — | **100% OK** |

---

## Sumario por Tipo

| Tipo | N | Wins | A% | B% | D% | C.lzma | LJ | OC |
|------|---|------|----|----|----|--------|----|----|
| LOG | 15 | 15/15 | 13.26% | 13.65% | 12.83% | 15 | 0 | 0 |
| TOK | 2 | 2/2 | 26.4% | 29.34% | 26.35% | 2 | 0 | 0 |

---

## Flips v10→v11 (C.LZMA como opcode vencedor)

| ID | Nome | Tipo | Orig | A | C:Py | D:TEIA | D-A | C-A | Ovhd |
|----|------|------|------|---|------|--------|-----|-----|------|
| S15 | Image Search-activity.json | LOG | 1814869B | 234683B | 226472B | 226553B | -8130B | -8211B | 81B |
| S14 | Google Translate-activity.json | LOG | 1782936B | 158711B | 155464B | 155549B | -3162B | -3247B | 85B |
| S10 | Android TV-activity.json | LOG | 290116B | 12783B | 10056B | 10135B | -2648B | -2727B | 79B |
| S12 | Google Analytics-activity.json | LOG | 889122B | 44594B | 42208B | 42293B | -2301B | -2386B | 85B |
| S13 | AI Mode-activity.json | LOG | 977929B | 192760B | 191058B | 191134B | -1626B | -1702B | 76B |
| S11 | Google Play Store-activity.json | LOG | 336170B | 11318B | 10094B | 10180B | -1138B | -1224B | 86B |
| S17 | tokenizer.json | TOK | 2203239B | 458926B | 457772B | 457841B | -1085B | -1154B | 69B |
| S7 | Help-activity.json | LOG | 184547B | 15609B | 14631B | 14704B | -905B | -978B | 73B |
| S9 | Ads-activity.json | LOG | 268586B | 35702B | 34777B | 34849B | -853B | -925B | 72B |
| S16 | anthropic_tokenizer.json | TOK | 1774213B | 566971B | 566180B | 566259B | -712B | -791B | 79B |
| S5 | Maps-activity.json | LOG | 127138B | 15297B | 14514B | 14587B | -710B | -783B | 73B |
| S6 | Chrome-activity.json | LOG | 147252B | 30112B | 29686B | 29761B | -351B | -426B | 75B |
| S8 | AI Mode-activity.json | LOG | 201038B | 71821B | 71427B | 71503B | -318B | -394B | 76B |
| S4 | Shopping-activity.json | LOG | 53851B | 8079B | 7751B | 7828B | -251B | -328B | 77B |
| S3 | Video Search-activity.json | LOG | 39421B | 6987B | 6692B | 6773B | -214B | -295B | 81B |
| S2 | Assistant-activity.json | LOG | 24518B | 2502B | 2247B | 2325B | -177B | -255B | 78B |
| S1 | Flights-activity.json | LOG | 21784B | 2537B | 2333B | 2409B | -128B | -204B | 76B |

---

## Savings Totais

| Metrica | Valor |
|---------|-------|
| Wins v11 | 17/17 |
| Net savings (D vs A) | 24709B |
| SHA-256 roundtrip | 100% OK |
| Erros | 0 |
