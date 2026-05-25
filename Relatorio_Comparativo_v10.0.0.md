# Relatorio Comparativo v10.0.0 — TEIA Stress Test: Tokenizers + Activity Logs

> **Gerado**: 2026-05-25T20:04:55Z
> **Motor**: TEIA-Core-v0.10.0.psm1 | SHA-256: 258a7ab8b5c053c40f93cbaaeeccfefb2bdb24d89974c47ecdc4793e68a37de5 | 32900 bytes
> **Corpus**: D8_STRESS_MANIFEST.json | 17 arquivos | tokenizers + activity logs
> **Dict**: NENHUM — DictSmallPath='' DictMediumPath='' | medida limpa Selector Engine puro
> **Probe sets**: tiny/small/medium→{cmp.zstd} | large→{cmp.xz, xz.raw, zstd.raw}

---

## Resultados por Arquivo

| ID | Nome | Type | Bucket | Orig | A:LZMA | A% | B:Zstd | B% | D:TEIA | D% | WIN | B-A | OPCODE | RAZAO | SHA |
|----|------|------|--------|------|--------|-----|--------|-----|-------|-----|-----|-----|--------|------|-----|
| S1 | Flights-activity.json | LOG | small | 21784 | 2537 | 11.65% | 2493 | 11.44% | 2569 | 11.79% | NAO | -44B | C.zst | OVERHEAD_CANCELA | OK |
| S2 | Assistant-activity.json | LOG | small | 24518 | 2502 | 10.2% | 2536 | 10.34% | 2614 | 10.66% | NAO | +34B | C.zst | LZMA_JANELA | OK |
| S3 | Video Search-activity.json | LOG | small | 39421 | 6987 | 17.72% | 7081 | 17.96% | 7162 | 18.17% | NAO | +94B | C.zst | LZMA_JANELA | OK |
| S4 | Shopping-activity.json | LOG | small | 53851 | 8079 | 15% | 8537 | 15.85% | 8614 | 16% | NAO | +458B | C.zst | LZMA_JANELA | OK |
| S5 | Maps-activity.json | LOG | medium | 127138 | 15297 | 12.03% | 15944 | 12.54% | 16017 | 12.6% | NAO | +647B | C.zst | LZMA_JANELA | OK |
| S6 | Chrome-activity.json | LOG | medium | 147252 | 30112 | 20.45% | 31103 | 21.12% | 31178 | 21.17% | NAO | +991B | C.zst | LZMA_JANELA | OK |
| S7 | Help-activity.json | LOG | medium | 184547 | 15609 | 8.46% | 16166 | 8.76% | 16239 | 8.8% | NAO | +557B | C.zst | LZMA_JANELA | OK |
| S8 | AI Mode-activity.json | LOG | medium | 201038 | 71821 | 35.73% | 72572 | 36.1% | 72648 | 36.14% | NAO | +751B | C.zst | LZMA_JANELA | OK |
| S9 | Ads-activity.json | LOG | medium | 268586 | 35702 | 13.29% | 36828 | 13.71% | 36900 | 13.74% | NAO | +1126B | C.zst | LZMA_JANELA | OK |
| S10 | Android TV-activity.json | LOG | medium | 290116 | 12783 | 4.41% | 13224 | 4.56% | 13303 | 4.59% | NAO | +441B | C.zst | LZMA_JANELA | OK |
| S11 | Google Play Store-activity.json | LOG | medium | 336170 | 11318 | 3.37% | 11427 | 3.4% | 11513 | 3.42% | NAO | +109B | C.zst | LZMA_JANELA | OK |
| S12 | Google Analytics-activity.json | LOG | large | 889122 | 44594 | 5.02% | 49124 | 5.53% | 44585 | 5.01% | SIM | +4530B | C.xz | GANHA | OK |
| S13 | AI Mode-activity.json | LOG | large | 977929 | 192760 | 19.71% | 195120 | 19.95% | 192776 | 19.71% | NAO | +2360B | C.xz | LZMA_JANELA | OK |
| S14 | Google Translate-activity.json | LOG | large | 1782936 | 158711 | 8.9% | 182923 | 10.26% | 158733 | 8.9% | NAO | +24212B | C.xz | LZMA_JANELA | OK |
| S15 | Image Search-activity.json | LOG | large | 1814869 | 234683 | 12.93% | 241154 | 13.29% | 234685 | 12.93% | NAO | +6471B | C.xz | LZMA_JANELA | OK |
| S16 | anthropic_tokenizer.json | TOK | large | 1774213 | 566971 | 31.96% | 625957 | 35.28% | 567107 | 31.96% | NAO | +58986B | C.xz | LZMA_JANELA | OK |
| S17 | tokenizer.json | TOK | large | 2203239 | 458926 | 20.83% | 515822 | 23.41% | 458965 | 20.83% | NAO | +56896B | C.xz | LZMA_JANELA | OK |

---

## Sumário por Bucket

| Bucket | N | Wins | A% | B% | D% | Ovhd | LJ | OC | C.zst | C.xz | Z.raw | SHA |
|--------|---|------|----|----|----|------|----|----|-------|------|-------|-----|
| small | 4 | 0/4 | 13.64% | 13.9% | 14.16% | ~78B | 3 | 1 | 4 | 0 | 0 | 100%OK |
| medium | 7 | 0/7 | 13.96% | 14.31% | 14.35% | ~76B | 7 | 0 | 7 | 0 | 0 | 100%OK |
| large | 6 | 1/6 | 16.56% | 17.95% | 16.56% | ~79B | 5 | 0 | 0 | 6 | 0 | 100%OK |
| **TOTAL** | **17** | **1/17** | — | — | — | — | — | — | — | — | — | **100% OK** |

---

## Sumário por Tipo

| Tipo | N | Wins | A% | B% | D% | LJ | OC |
|------|---|------|----|----|----|----|----|
| LOG | 15 | 1/15 | 13.26% | 13.65% | 13.58% | 13 | 1 |
| TOK | 2 | 0/2 | 26.4% | 29.34% | 26.4% | 2 | 0 |

---

## Diagnóstico de Perdas LZMA_JANELA

| ID | Nome | Type | Orig | A | B | D | D-A | B-A | A% | D% |
|----|------|------|------|---|---|---|-----|-----|-----|-----|
| S9 | Ads-activity.json | LOG | 268586B | 35702B | 36828B | 36900B | +1198B | +1126B | 13.29% | 13.74% |
| S6 | Chrome-activity.json | LOG | 147252B | 30112B | 31103B | 31178B | +1066B | +991B | 20.45% | 21.17% |
| S8 | AI Mode-activity.json | LOG | 201038B | 71821B | 72572B | 72648B | +827B | +751B | 35.73% | 36.14% |
| S5 | Maps-activity.json | LOG | 127138B | 15297B | 15944B | 16017B | +720B | +647B | 12.03% | 12.6% |
| S7 | Help-activity.json | LOG | 184547B | 15609B | 16166B | 16239B | +630B | +557B | 8.46% | 8.8% |
| S4 | Shopping-activity.json | LOG | 53851B | 8079B | 8537B | 8614B | +535B | +458B | 15% | 16% |
| S10 | Android TV-activity.json | LOG | 290116B | 12783B | 13224B | 13303B | +520B | +441B | 4.41% | 4.59% |
| S11 | Google Play Store-activity.json | LOG | 336170B | 11318B | 11427B | 11513B | +195B | +109B | 3.37% | 3.42% |
| S3 | Video Search-activity.json | LOG | 39421B | 6987B | 7081B | 7162B | +175B | +94B | 17.72% | 18.17% |
| S16 | anthropic_tokenizer.json | TOK | 1774213B | 566971B | 625957B | 567107B | +136B | +58986B | 31.96% | 31.96% |
| S2 | Assistant-activity.json | LOG | 24518B | 2502B | 2536B | 2614B | +112B | +34B | 10.2% | 10.66% |
| S17 | tokenizer.json | TOK | 2203239B | 458926B | 515822B | 458965B | +39B | +56896B | 20.83% | 20.83% |
| S14 | Google Translate-activity.json | LOG | 1782936B | 158711B | 182923B | 158733B | +22B | +24212B | 8.9% | 8.9% |
| S13 | AI Mode-activity.json | LOG | 977929B | 192760B | 195120B | 192776B | +16B | +2360B | 19.71% | 19.71% |
| S15 | Image Search-activity.json | LOG | 1814869B | 234683B | 241154B | 234685B | +2B | +6471B | 12.93% | 12.93% |

---

## Próximos Passos

**1/17 TEIA ganha** — 16 perdas.

Para LZMA_JANELA losses:
- **dict-log**: treinar em corpus externo de activity logs (precisa ~6.5MB, fora do test set)
- **dict-tok**: separar training/test de tokenizers — precisa corpus maior (GPT-2/LLaMA tokenizers)
- **cmp.xz** já é melhor que xz.raw. Margem restante é estrutural (LZMA1 window > LZMA2).
