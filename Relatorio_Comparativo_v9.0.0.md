# Relatorio Comparativo v9.0.0 — TEIA Compact Manifest (105 arquivos)

> **Gerado**: 2026-05-25T19:51:32Z
> **Motor**: TEIA-Core-v0.10.0.psm1 | SHA-256: 258a7ab8b5c053c40f93cbaaeeccfefb2bdb24d89974c47ecdc4793e68a37de5 | 32900 bytes
> **Hardware**: i3-10100F, 16GB RAM, HDD
> **Corpus**: D7_REAL_MANIFEST.json | 105 arquivos | zero overlap D4 | seed=42 (mesmo que v7/v8)
> **Classificacao**: Benchmark Robusto

---

## Compact Manifest v0.10 — Estrategia de Probe por Bucket

| Bucket | Opcodes Probados | Selecao |
|--------|-----------------|---------|
| tiny (<5KB) | cmp.zstd | cmp.zstd (overhead 72B vs 166B JSON) |
| small (5-100KB) | cmp.zstd + dict.zstd_shared(dict-small) | min(D) |
| medium (100-500KB) | dict.zstd_shared(dict-medium) + zstd.raw | min(D) |
| large (>=500KB) | cmp.xz + xz.raw + zstd.raw | min(D) |

**Compact manifest (VER_MINOR=10)**: ormat_byte(1) + algo_byte(1) + orig_size(8) + sha256_raw(32) + name_len(1) + name(N) = 43+N bytes.
Overhead tiny: ~72B (vs 166B JSON → -94B). Overhead large xz: ~66B (vs 160B JSON → -94B).

**Predicao matematica**: 20 tiny flip (A-B >= 139B >> 72B limiar), R96/R100 flip (cmp.xz overhead -94B resolve margem 73B/70B).

---

## Resultados por Arquivo

| ID | Nome | Bucket | Orig | A:LZMA | A% | B:Zstd | B% | C:Best | C% | D:TEIA | D% | WIN | OPCODE | RAZAO | SHA |
|----|----|------|------|-------|-----|------|-----|------|-----|-------|-----|-----|--------|------|-----|
| R1 | paginators-1.json | tiny | 3064 | 460 | 15.01% | 312 | 10.18% | 312 | 10.18% | 384 | 12.53% | SIM | C.zst | GANHA | OK |
| R2 | paginators-1.json | tiny | 2913 | 485 | 16.65% | 346 | 11.88% | 346 | 11.88% | 418 | 14.35% | SIM | C.zst | GANHA | OK |
| R3 | paginators-1.json | tiny | 1313 | 377 | 28.71% | 231 | 17.59% | 231 | 17.59% | 303 | 23.08% | SIM | C.zst | GANHA | OK |
| R4 | paginators-1.json | tiny | 1778 | 394 | 22.16% | 250 | 14.06% | 250 | 14.06% | 322 | 18.11% | SIM | C.zst | GANHA | OK |
| R5 | paginators-1.json | tiny | 1591 | 391 | 24.58% | 247 | 15.52% | 247 | 15.52% | 319 | 20.05% | SIM | C.zst | GANHA | OK |
| R6 | paginators-1.json | tiny | 1149 | 355 | 30.9% | 215 | 18.71% | 215 | 18.71% | 287 | 24.98% | SIM | C.zst | GANHA | OK |
| R7 | paginators-1.json | tiny | 3466 | 485 | 13.99% | 343 | 9.9% | 343 | 9.9% | 415 | 11.97% | SIM | C.zst | GANHA | OK |
| R8 | paginators-1.json | tiny | 1373 | 376 | 27.39% | 234 | 17.04% | 234 | 17.04% | 306 | 22.29% | SIM | C.zst | GANHA | OK |
| R9 | paginators-1.json | tiny | 1126 | 389 | 34.55% | 242 | 21.49% | 242 | 21.49% | 314 | 27.89% | SIM | C.zst | GANHA | OK |
| R10 | paginators-1.json | tiny | 1549 | 386 | 24.92% | 242 | 15.62% | 242 | 15.62% | 314 | 20.27% | SIM | C.zst | GANHA | OK |
| R11 | paginators-1.json | tiny | 1603 | 382 | 23.83% | 240 | 14.97% | 240 | 14.97% | 312 | 19.46% | SIM | C.zst | GANHA | OK |
| R12 | paginators-1.json | tiny | 3043 | 613 | 20.14% | 467 | 15.35% | 467 | 15.35% | 539 | 17.71% | SIM | C.zst | GANHA | OK |
| R13 | paginators-1.json | tiny | 1007 | 334 | 33.17% | 194 | 19.27% | 194 | 19.27% | 266 | 26.42% | SIM | C.zst | GANHA | OK |
| R14 | paginators-1.json | tiny | 1126 | 389 | 34.55% | 242 | 21.49% | 242 | 21.49% | 314 | 27.89% | SIM | C.zst | GANHA | OK |
| R15 | paginators-1.json | tiny | 1699 | 418 | 24.6% | 276 | 16.24% | 276 | 16.24% | 348 | 20.48% | SIM | C.zst | GANHA | OK |
| R16 | paginators-1.json | tiny | 1259 | 385 | 30.58% | 234 | 18.59% | 234 | 18.59% | 306 | 24.31% | SIM | C.zst | GANHA | OK |
| R17 | paginators-1.json | tiny | 1076 | 368 | 34.2% | 218 | 20.26% | 218 | 20.26% | 290 | 26.95% | SIM | C.zst | GANHA | OK |
| R18 | paginators-1.json | tiny | 1472 | 474 | 32.2% | 322 | 21.88% | 322 | 21.88% | 394 | 26.77% | SIM | C.zst | GANHA | OK |
| R19 | paginators-1.json | tiny | 1221 | 361 | 29.57% | 218 | 17.85% | 218 | 17.85% | 290 | 23.75% | SIM | C.zst | GANHA | OK |
| R20 | paginators-1.json | tiny | 2870 | 542 | 18.89% | 395 | 13.76% | 395 | 13.76% | 467 | 16.27% | SIM | C.zst | GANHA | OK |
| R21 | service-2.json | small | 10858 | 2857 | 26.31% | 2740 | 25.23% | 2364 | 21.77% | 2635 | 24.27% | SIM | Dict | GANHA | OK |
| R22 | service-2.json | small | 89237 | 6508 | 7.29% | 6160 | 6.9% | 5806 | 6.51% | 6077 | 6.81% | SIM | Dict | GANHA | OK |
| R23 | service-2.json | small | 76981 | 9805 | 12.74% | 9660 | 12.55% | 8911 | 11.58% | 9182 | 11.93% | SIM | Dict | GANHA | OK |
| R24 | service-2.json | small | 31373 | 4244 | 13.53% | 4073 | 12.98% | 3634 | 11.58% | 3905 | 12.45% | SIM | Dict | GANHA | OK |
| R25 | service-2.json | small | 77014 | 8747 | 11.36% | 8520 | 11.06% | 7991 | 10.38% | 8262 | 10.73% | SIM | Dict | GANHA | OK |
| R26 | service-2.json | small | 97831 | 9371 | 9.58% | 9069 | 9.27% | 8478 | 8.67% | 8749 | 8.94% | SIM | Dict | GANHA | OK |
| R27 | service-2.json | small | 90468 | 9652 | 10.67% | 9453 | 10.45% | 8829 | 9.76% | 9100 | 10.06% | SIM | Dict | GANHA | OK |
| R28 | service-2.json | small | 91340 | 11568 | 12.66% | 11370 | 12.45% | 10647 | 11.66% | 10918 | 11.95% | SIM | Dict | GANHA | OK |
| R29 | waiters-2.json | small | 5118 | 619 | 12.09% | 468 | 9.14% | 391 | 7.64% | 537 | 10.49% | SIM | C.zst | GANHA | OK |
| R30 | service-2.json | small | 53660 | 6564 | 12.23% | 6394 | 11.92% | 5858 | 10.92% | 6129 | 11.42% | SIM | Dict | GANHA | OK |
| R31 | service-2.json | small | 86587 | 10699 | 12.36% | 10494 | 12.12% | 9840 | 11.36% | 10111 | 11.68% | SIM | Dict | GANHA | OK |
| R32 | service-2.json | small | 26723 | 3320 | 12.42% | 3092 | 11.57% | 2695 | 10.08% | 2966 | 11.1% | SIM | Dict | GANHA | OK |
| R33 | service-2.json | small | 65098 | 5854 | 8.99% | 5560 | 8.54% | 5089 | 7.82% | 5360 | 8.23% | SIM | Dict | GANHA | OK |
| R34 | service-2.json | small | 77657 | 9237 | 11.89% | 9114 | 11.74% | 8613 | 11.09% | 8884 | 11.44% | SIM | Dict | GANHA | OK |
| R35 | service-2.json | small | 16920 | 3303 | 19.52% | 3134 | 18.52% | 2751 | 16.26% | 3022 | 17.86% | SIM | Dict | GANHA | OK |
| R36 | service-2.json | small | 26736 | 4229 | 15.82% | 4062 | 15.19% | 3593 | 13.44% | 3864 | 14.45% | SIM | Dict | GANHA | OK |
| R37 | service-2.json | small | 47634 | 7806 | 16.39% | 7692 | 16.15% | 7053 | 14.81% | 7324 | 15.38% | SIM | Dict | GANHA | OK |
| R38 | service-2.json | small | 85586 | 9506 | 11.11% | 9256 | 10.81% | 8584 | 10.03% | 8855 | 10.35% | SIM | Dict | GANHA | OK |
| R39 | service-2.json | small | 99536 | 5106 | 5.13% | 4705 | 4.73% | 4385 | 4.41% | 4656 | 4.68% | SIM | Dict | GANHA | OK |
| R40 | service-2.json | small | 53601 | 6884 | 12.84% | 6702 | 12.5% | 6075 | 11.33% | 6346 | 11.84% | SIM | Dict | GANHA | OK |
| R41 | service-2.json | small | 84666 | 10476 | 12.37% | 10374 | 12.25% | 9778 | 11.55% | 10049 | 11.87% | SIM | Dict | GANHA | OK |
| R42 | service-2.json | small | 71488 | 6457 | 9.03% | 6213 | 8.69% | 5629 | 7.87% | 5900 | 8.25% | SIM | Dict | GANHA | OK |
| R43 | service-2.json | small | 66318 | 7945 | 11.98% | 7774 | 11.72% | 7223 | 10.89% | 7494 | 11.3% | SIM | Dict | GANHA | OK |
| R44 | service-2.json | small | 5796 | 1560 | 26.92% | 1415 | 24.41% | 1207 | 20.82% | 1477 | 25.48% | SIM | Dict | GANHA | OK |
| R45 | service-2.json | small | 87478 | 7194 | 8.22% | 6891 | 7.88% | 6420 | 7.34% | 6691 | 7.65% | SIM | Dict | GANHA | OK |
| R46 | webfonts.v1.json | small | 6937 | 2228 | 32.12% | 2067 | 29.8% | 1219 | 17.57% | 1491 | 21.49% | SIM | Dict | GANHA | OK |
| R47 | gameservices.v1beta.json | small | 54813 | 11392 | 20.78% | 11359 | 20.72% | 9024 | 16.46% | 9305 | 16.98% | SIM | Dict | GANHA | OK |
| R48 | assuredworkloads.v1.json | small | 74805 | 13414 | 17.93% | 13415 | 17.93% | 10927 | 14.61% | 11208 | 14.98% | SIM | Dict | GANHA | OK |
| R49 | genomics.v2alpha1.json | small | 63816 | 13384 | 20.97% | 13393 | 20.99% | 11183 | 17.52% | 11462 | 17.96% | SIM | Dict | GANHA | OK |
| R50 | parallelstore.v1.json | small | 37496 | 7505 | 20.02% | 7384 | 19.69% | 4869 | 12.99% | 5147 | 13.73% | SIM | Dict | GANHA | OK |
| R51 | merchantapi.ordertracking_v1beta.json | small | 19026 | 5132 | 26.97% | 5052 | 26.55% | 3888 | 20.44% | 4182 | 21.98% | SIM | Dict | GANHA | OK |
| R52 | securityposture.v1.json | small | 72170 | 11833 | 16.4% | 11744 | 16.27% | 9126 | 12.65% | 9406 | 13.03% | SIM | Dict | GANHA | OK |
| R53 | bigqueryreservation.v1.json | small | 97702 | 15908 | 16.28% | 15820 | 16.19% | 13774 | 14.1% | 14058 | 14.39% | SIM | Dict | GANHA | OK |
| R54 | translate.v3beta1.json | small | 69036 | 11783 | 17.07% | 11617 | 16.83% | 9205 | 13.33% | 9484 | 13.74% | SIM | Dict | GANHA | OK |
| R55 | osconfig.v1beta.json | small | 87545 | 16008 | 18.29% | 16025 | 18.3% | 14176 | 16.19% | 14453 | 16.51% | SIM | Dict | GANHA | OK |
| R56 | safebrowsing.v4.json | small | 38346 | 6478 | 16.89% | 6357 | 16.58% | 4979 | 12.98% | 5256 | 13.71% | SIM | Dict | GANHA | OK |
| R57 | workflowexecutions.v1.json | small | 39175 | 7967 | 20.34% | 7847 | 20.03% | 6105 | 15.58% | 6388 | 16.31% | SIM | Dict | GANHA | OK |
| R58 | datafusion.v1beta1.json | small | 76748 | 15044 | 19.6% | 15020 | 19.57% | 12261 | 15.98% | 12541 | 16.34% | SIM | Dict | GANHA | OK |
| R59 | servicecontrol.v2.json | small | 56220 | 13643 | 24.27% | 13655 | 24.29% | 11495 | 20.45% | 11774 | 20.94% | SIM | Dict | GANHA | OK |
| R60 | transcoder.v1beta1.json | small | 60514 | 9644 | 15.94% | 9483 | 15.67% | 8022 | 13.26% | 8302 | 13.72% | SIM | Dict | GANHA | OK |
| R61 | genomics.v1.json | small | 44128 | 10325 | 23.4% | 10293 | 23.33% | 8783 | 19.9% | 9056 | 20.52% | SIM | Dict | GANHA | OK |
| R62 | iamcredentials.v1.json | small | 16110 | 3519 | 21.84% | 3352 | 20.81% | 2233 | 13.86% | 2512 | 15.59% | SIM | Dict | GANHA | OK |
| R63 | addressvalidation.v1.json | small | 50336 | 12636 | 25.1% | 12639 | 25.11% | 11100 | 22.05% | 11382 | 22.61% | SIM | Dict | GANHA | OK |
| R64 | cloudcommerceprocurement.v1.json | small | 41004 | 7767 | 18.94% | 7602 | 18.54% | 6014 | 14.67% | 6303 | 15.37% | SIM | Dict | GANHA | OK |
| R65 | datamigration.v1beta1.json | small | 84149 | 15395 | 18.29% | 15405 | 18.31% | 12725 | 15.12% | 13008 | 15.46% | SIM | Dict | GANHA | OK |
| R66 | service-2.json | medium | 188709 | 23110 | 12.25% | 22757 | 12.06% | 20925 | 11.09% | 21197 | 11.23% | SIM | Dict | GANHA | OK |
| R67 | service-2.json | medium | 108134 | 11250 | 10.4% | 10913 | 10.09% | 9758 | 9.02% | 10030 | 9.28% | SIM | Dict | GANHA | OK |
| R68 | service-2.json | medium | 148384 | 14712 | 9.91% | 14421 | 9.72% | 13136 | 8.85% | 13408 | 9.04% | SIM | Dict | GANHA | OK |
| R69 | service-2.json | medium | 154636 | 13451 | 8.7% | 13094 | 8.47% | 12004 | 7.76% | 12276 | 7.94% | SIM | Dict | GANHA | OK |
| R70 | service-2.json | medium | 158099 | 20127 | 12.73% | 19957 | 12.62% | 18190 | 11.51% | 18462 | 11.68% | SIM | Dict | GANHA | OK |
| R71 | service-2.json | medium | 229514 | 23546 | 10.26% | 23159 | 10.09% | 21485 | 9.36% | 21757 | 9.48% | SIM | Dict | GANHA | OK |
| R72 | service-2.json | medium | 215016 | 23609 | 10.98% | 23552 | 10.95% | 21627 | 10.06% | 21899 | 10.18% | SIM | Dict | GANHA | OK |
| R73 | service-2.json | medium | 234659 | 23935 | 10.2% | 23714 | 10.11% | 22007 | 9.38% | 22279 | 9.49% | SIM | Dict | GANHA | OK |
| R74 | service-2.json | medium | 297127 | 21511 | 7.24% | 20877 | 7.03% | 19739 | 6.64% | 20011 | 6.73% | SIM | Dict | GANHA | OK |
| R75 | service-2.json | medium | 281575 | 28888 | 10.26% | 28344 | 10.07% | 26643 | 9.46% | 26915 | 9.56% | SIM | Dict | GANHA | OK |
| R76 | service-2.json | medium | 143746 | 16732 | 11.64% | 16562 | 11.52% | 14955 | 10.4% | 15227 | 10.59% | SIM | Dict | GANHA | OK |
| R77 | service-2.json | medium | 136133 | 16772 | 12.32% | 16700 | 12.27% | 14781 | 10.86% | 15053 | 11.06% | SIM | Dict | GANHA | OK |
| R78 | service-2.json | medium | 282414 | 22291 | 7.89% | 21952 | 7.77% | 20701 | 7.33% | 20973 | 7.43% | SIM | Dict | GANHA | OK |
| R79 | service-2.json | medium | 151766 | 15136 | 9.97% | 14868 | 9.8% | 13525 | 8.91% | 13797 | 9.09% | SIM | Dict | GANHA | OK |
| R80 | service-2.json | medium | 244492 | 27712 | 11.33% | 27396 | 11.21% | 25765 | 10.54% | 26037 | 10.65% | SIM | Dict | GANHA | OK |
| R81 | service-2.json | medium | 208213 | 19450 | 9.34% | 19279 | 9.26% | 17716 | 8.51% | 17988 | 8.64% | SIM | Dict | GANHA | OK |
| R82 | service-2.json | medium | 247155 | 18611 | 7.53% | 18077 | 7.31% | 16883 | 6.83% | 17155 | 6.94% | SIM | Dict | GANHA | OK |
| R83 | service-2.json | medium | 144570 | 17608 | 12.18% | 17460 | 12.08% | 15716 | 10.87% | 15988 | 11.06% | SIM | Dict | GANHA | OK |
| R84 | service-2.json | medium | 122553 | 10927 | 8.92% | 10579 | 8.63% | 9498 | 7.75% | 9770 | 7.97% | SIM | Dict | GANHA | OK |
| R85 | service-2.json | medium | 227505 | 25046 | 11.01% | 24813 | 10.91% | 23185 | 10.19% | 23457 | 10.31% | SIM | Dict | GANHA | OK |
| R86 | service-2.json | medium | 264286 | 28932 | 10.95% | 28785 | 10.89% | 27275 | 10.32% | 27547 | 10.42% | SIM | Dict | GANHA | OK |
| R87 | service-2.json | medium | 238101 | 22103 | 9.28% | 21823 | 9.17% | 20221 | 8.49% | 20493 | 8.61% | SIM | Dict | GANHA | OK |
| R88 | service-2.json | medium | 305595 | 26013 | 8.51% | 25393 | 8.31% | 24288 | 7.95% | 24560 | 8.04% | SIM | Dict | GANHA | OK |
| R89 | service-2.json | medium | 148607 | 13623 | 9.17% | 13223 | 8.9% | 11759 | 7.91% | 12031 | 8.1% | SIM | Dict | GANHA | OK |
| R90 | service-2.json | medium | 222076 | 29523 | 13.29% | 29397 | 13.24% | 27406 | 12.34% | 27678 | 12.46% | SIM | Dict | GANHA | OK |
| R91 | service-2.json | large | 556492 | 46164 | 8.3% | 45498 | 8.18% | 45498 | 8.18% | 45663 | 8.21% | SIM | Z.raw | GANHA | OK |
| R92 | service-2.json | large | 847080 | 76733 | 9.06% | 75084 | 8.86% | 75084 | 8.86% | 75249 | 8.88% | SIM | Z.raw | GANHA | OK |
| R93 | service-2.json | large | 891280 | 80806 | 9.07% | 78951 | 8.86% | 78951 | 8.86% | 79116 | 8.88% | SIM | Z.raw | GANHA | OK |
| R94 | service-2.json | large | 812261 | 81214 | 10% | 79911 | 9.84% | 79911 | 9.84% | 80076 | 9.86% | SIM | Z.raw | GANHA | OK |
| R95 | service-2.json | large | 588390 | 57551 | 9.78% | 56489 | 9.6% | 56489 | 9.6% | 56654 | 9.63% | SIM | Z.raw | GANHA | OK |
| R96 | service-2.json | large | 926847 | 82931 | 8.95% | 83409 | 9% | 83409 | 9% | 82913 | 8.95% | SIM | C.xz | GANHA | OK |
| R97 | service-2.json | large | 588264 | 48165 | 8.19% | 46630 | 7.93% | 46630 | 7.93% | 46795 | 7.95% | SIM | Z.raw | GANHA | OK |
| R98 | service-2.json | large | 3018739 | 230206 | 7.63% | 222692 | 7.38% | 222692 | 7.38% | 222858 | 7.38% | SIM | Z.raw | GANHA | OK |
| R99 | service-2.json | large | 540601 | 50296 | 9.3% | 48945 | 9.05% | 48945 | 9.05% | 49110 | 9.08% | SIM | Z.raw | GANHA | OK |
| R100 | service-2.json | large | 673116 | 65466 | 9.73% | 65597 | 9.75% | 65597 | 9.75% | 65445 | 9.72% | SIM | C.xz | GANHA | OK |
| R101 | service-2.json | large | 562255 | 38496 | 6.85% | 37159 | 6.61% | 37159 | 6.61% | 37324 | 6.64% | SIM | Z.raw | GANHA | OK |
| R102 | service-2.json | large | 763800 | 42353 | 5.55% | 41330 | 5.41% | 41330 | 5.41% | 41495 | 5.43% | SIM | Z.raw | GANHA | OK |
| R103 | service-2.json | large | 661619 | 59931 | 9.06% | 59040 | 8.92% | 59040 | 8.92% | 59205 | 8.95% | SIM | Z.raw | GANHA | OK |
| R104 | service-2.json | large | 539923 | 53264 | 9.87% | 52276 | 9.68% | 52276 | 9.68% | 52441 | 9.71% | SIM | Z.raw | GANHA | OK |
| R105 | service-2.json | large | 629302 | 47555 | 7.56% | 46439 | 7.38% | 46439 | 7.38% | 46604 | 7.41% | SIM | Z.raw | GANHA | OK |

---

## Sumário por Bucket

| Bucket | N | Wins | A% | B% | D% | Ovhd | LJ | DP | OC | C.zst | C.xz | Dict | Z.raw | X.raw | SHA |
|--------|---|------|----|----|----|------|----|----|-----|-------|------|------|-------|-------|-----|
| tiny | 20 | 20/20 | 26.03% | 16.58% | 21.28% | ~72B | 0 | 0 | 0 | 20 | 0 | 0 | 0 | 0 | 100%OK |
| small | 45 | 45/45 | 16.33% | 15.87% | 14.13% | ~271B | 0 | 0 | 0 | 1 | 0 | 44 | 0 | 0 | 100%OK |
| medium | 25 | 25/25 | 10.25% | 10.1% | 9.44% | ~272B | 0 | 0 | 0 | 0 | 0 | 25 | 0 | 0 | 100%OK |
| large | 15 | 15/15 | 8.59% | 8.43% | 8.45% | ~152B | 0 | 0 | 0 | 0 | 2 | 0 | 13 | 0 | 100%OK |
| **TOTAL** | **105** | **105/105** | — | — | — | — | — | — | — | — | — | — | — | — | **100% OK** |

---

## Diagnóstico de Perdas (v8 vs v9)

| Categoria | v8 (82/105) | v9 |
|-----------|------------|-----|
| GANHA | 82 | 105 |
| LZMA_JANELA | 2 | 0 |
| DICT_PREJUDICA | 0 | 0 |
| OVERHEAD_CANCELA | 21 | 0 |

### Perdas restantes:
**Nenhuma perda. 105/105 TEIA ganha.**

---

## Distribuição de Opcodes (Selector Engine v0.10)

| Opcode | Manifest | Total selecionado | % arquivos |
|--------|----------|------------------|-----------|
| cmp.zstd | VER_MINOR=10 (compact) | 21 | 20% |
| cmp.xz | VER_MINOR=10 (compact) | 2 | 1.9% |
| dict.zstd_shared | VER_MINOR=9 (JSON) | 69 | 65.7% |
| zstd.raw | VER_MINOR=9 (JSON) | 13 | 12.4% |
| xz.raw | VER_MINOR=9 (JSON) | 0 | 0% |

---

## B vs A — Zstd Puro vs LZMA

Zstd vence LZMA em **97/105** arquivos.

| ID | Nome | Orig | A:LZMA | B:Zstd | B-A |
|----|------|------|--------|--------|-----|
| R96 | service-2.json | 926847B | 82931B | 83409B | +478B (LZMA ganha) |
| R100 | service-2.json | 673116B | 65466B | 65597B | +131B (LZMA ganha) |
| R55 | osconfig.v1beta.json | 87545B | 16008B | 16025B | +17B (LZMA ganha) |
| R59 | servicecontrol.v2.json | 56220B | 13643B | 13655B | +12B (LZMA ganha) |
| R65 | datamigration.v1beta1.json | 84149B | 15395B | 15405B | +10B (LZMA ganha) |
| R49 | genomics.v2alpha1.json | 63816B | 13384B | 13393B | +9B (LZMA ganha) |
| R63 | addressvalidation.v1.json | 50336B | 12636B | 12639B | +3B (LZMA ganha) |
| R48 | assuredworkloads.v1.json | 74805B | 13414B | 13415B | +1B (LZMA ganha) |

---

## Economia Total vs LZMA (apenas wins)

**105 arquivos ganhos** | Economia total: **105574B** vs LZMA standalone

Top 10 maiores ganhos:

| ID | Nome | Bucket | Orig | A:LZMA | D:TEIA | Ganho | Opcode |
|----|------|--------|------|--------|--------|-------|--------|
| R98 | service-2.json | large | 3018739B | 230206B | 222858B | -7348B | Z.raw |
| R58 | datafusion.v1beta1.json | small | 76748B | 15044B | 12541B | -2503B | Dict |
| R52 | securityposture.v1.json | small | 72170B | 11833B | 9406B | -2427B | Dict |
| R65 | datamigration.v1beta1.json | small | 84149B | 15395B | 13008B | -2387B | Dict |
| R50 | parallelstore.v1.json | small | 37496B | 7505B | 5147B | -2358B | Dict |
| R54 | translate.v3beta1.json | small | 69036B | 11783B | 9484B | -2299B | Dict |
| R48 | assuredworkloads.v1.json | small | 74805B | 13414B | 11208B | -2206B | Dict |
| R47 | gameservices.v1beta.json | small | 54813B | 11392B | 9305B | -2087B | Dict |
| R75 | service-2.json | medium | 281575B | 28888B | 26915B | -1973B | Dict |
| R49 | genomics.v2alpha1.json | small | 63816B | 13384B | 11462B | -1922B | Dict |

---

*v8→v9 delta: TEIA 105/105 (antes 82/105). Economia: 105574B (antes 103,418B).*
