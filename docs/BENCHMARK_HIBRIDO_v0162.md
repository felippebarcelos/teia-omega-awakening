# BENCHMARK HÍBRIDO v0.16.2
**Data:** 2026-05-27 06:08:57
**Motor procedural:** TEIA-Core-v0.4.0.ps1 SHA-256 `489D3B40...`
**Regra:** sha256_match=false invalida a linha; ratio=-1 = N/A
**Overhead:** M7/M8/M9 adicionam ~80B de seed JSON para v0.16 CAS (incluso no 'reprB+overhead' abaixo)

---

## TABELA COMPLETA (ratio% = reprB / origB × 100)

| Dataset | Modo | Orig (B) | Repr (B) | Ratio% | SHA256 | enc ms | dec ms | Nota |
|---------|------|-------:|-------:|------:|:-----:|------:|------:|------|
| D1 uniform_1MB | M1 cas.raw | 1048576 | 1048576 | 100 | ✅ | 0 | 0 | baseline |
| D1 uniform_1MB | M2 gen.repeat | 1048576 | 268 | 0.0256 | ✅ | 122 | 2965 |  |
| D1 uniform_1MB | M3 gen.pattern | 1048576 | 280 | 0.0267 | ✅ | 158 | 8991 |  |
| D1 uniform_1MB | M4 rle.decode | 1048576 | 318 | 0.0303 | ✅ | 88 | 1677 |  |
| D1 uniform_1MB | M5 procedural.best | 1048576 | 268 | 0.0256 | ✅ | 64 | 1415 |  |
| D1 uniform_1MB | M6 cmp.zstd | 1048576 | N/A | N/A | ❌ | N/A | N/A | N/A: zstd indisponivel |
| D1 uniform_1MB | M7 cmp.lzma | 1048576 | 237 | 0.0226 | ✅ | 601 | 179 |  |
| D1 uniform_1MB | M8 v0.11-lzma | 1048576 | 237 | 0.0226 | ✅ | 169 | 145 | (mesmo algo que M7 — v0.11 Python lzma FORMAT_ALONE) |
| D1 uniform_1MB | M9 brotli | 1048576 | 13 | 0.0012 | ✅ | 17 | 157 |  |
| D2 periodic_ABCD_1MB | M1 cas.raw | 1048576 | 1048576 | 100 | ✅ | 0 | 0 | baseline |
| D2 periodic_ABCD_1MB | M2 gen.repeat | 1048576 | N/A | N/A | ❌ | 0 | N/A | N/A: nenhum opcode aplicavel |
| D2 periodic_ABCD_1MB | M3 gen.pattern | 1048576 | 283 | 0.027 | ✅ | 85 | 3239 |  |
| D2 periodic_ABCD_1MB | M4 rle.decode | 1048576 | N/A | N/A | ❌ | 293 | N/A | N/A: nenhum opcode aplicavel |
| D2 periodic_ABCD_1MB | M5 procedural.best | 1048576 | 283 | 0.027 | ✅ | 87 | 3236 |  |
| D2 periodic_ABCD_1MB | M6 cmp.zstd | 1048576 | N/A | N/A | ❌ | N/A | N/A | N/A: zstd indisponivel |
| D2 periodic_ABCD_1MB | M7 cmp.lzma | 1048576 | 242 | 0.0231 | ✅ | 119 | 225 |  |
| D2 periodic_ABCD_1MB | M8 v0.11-lzma | 1048576 | 242 | 0.0231 | ✅ | 104 | 162 | (mesmo algo que M7 — v0.11 Python lzma FORMAT_ALONE) |
| D2 periodic_ABCD_1MB | M9 brotli | 1048576 | 17 | 0.0016 | ✅ | 2 | 112 |  |
| D3 rle_3runs_300KB | M1 cas.raw | 307200 | 307200 | 100 | ✅ | 0 | 0 | baseline |
| D3 rle_3runs_300KB | M2 gen.repeat | 307200 | N/A | N/A | ❌ | 6 | N/A | N/A: nenhum opcode aplicavel |
| D3 rle_3runs_300KB | M3 gen.pattern | 307200 | N/A | N/A | ❌ | 319 | N/A | N/A: nenhum opcode aplicavel |
| D3 rle_3runs_300KB | M4 rle.decode | 307200 | 448 | 0.1458 | ✅ | 21 | 1262 |  |
| D3 rle_3runs_300KB | M5 procedural.best | 307200 | 448 | 0.1458 | ✅ | 387 | 1164 |  |
| D3 rle_3runs_300KB | M6 cmp.zstd | 307200 | N/A | N/A | ❌ | N/A | N/A | N/A: zstd indisponivel |
| D3 rle_3runs_300KB | M7 cmp.lzma | 307200 | 143 | 0.0465 | ✅ | 164 | 380 |  |
| D3 rle_3runs_300KB | M8 v0.11-lzma | 307200 | 143 | 0.0465 | ✅ | 70 | 77 | (mesmo algo que M7 — v0.11 Python lzma FORMAT_ALONE) |
| D3 rle_3runs_300KB | M9 brotli | 307200 | 23 | 0.0075 | ✅ | 2 | 21 |  |
| D4 json_real_512KB | M1 cas.raw | 524288 | 524288 | 100 | ✅ | 0 | 0 | baseline |
| D4 json_real_512KB | M2 gen.repeat | 524288 | N/A | N/A | ❌ | 0 | N/A | N/A: nenhum opcode aplicavel |
| D4 json_real_512KB | M3 gen.pattern | 524288 | N/A | N/A | ❌ | 0 | N/A | N/A: nenhum opcode aplicavel |
| D4 json_real_512KB | M4 rle.decode | 524288 | N/A | N/A | ❌ | 149 | N/A | N/A: nenhum opcode aplicavel |
| D4 json_real_512KB | M5 procedural.best | 524288 | N/A | N/A | ❌ | 145 | N/A | N/A: nenhum opcode aplicavel |
| D4 json_real_512KB | M6 cmp.zstd | 524288 | N/A | N/A | ❌ | N/A | N/A | N/A: zstd indisponivel |
| D4 json_real_512KB | M7 cmp.lzma | 524288 | 53467 | 10.198 | ✅ | 272 | 112 |  |
| D4 json_real_512KB | M8 v0.11-lzma | 524288 | 53467 | 10.198 | ✅ | 262 | 110 | (mesmo algo que M7 — v0.11 Python lzma FORMAT_ALONE) |
| D4 json_real_512KB | M9 brotli | 524288 | 60037 | 11.4511 | ✅ | 13 | 47 |  |
| D5 logs_real_512KB | M1 cas.raw | 524288 | 524288 | 100 | ✅ | 0 | 0 | baseline |
| D5 logs_real_512KB | M2 gen.repeat | 524288 | N/A | N/A | ❌ | 0 | N/A | N/A: nenhum opcode aplicavel |
| D5 logs_real_512KB | M3 gen.pattern | 524288 | N/A | N/A | ❌ | 0 | N/A | N/A: nenhum opcode aplicavel |
| D5 logs_real_512KB | M4 rle.decode | 524288 | N/A | N/A | ❌ | 156 | N/A | N/A: nenhum opcode aplicavel |
| D5 logs_real_512KB | M5 procedural.best | 524288 | N/A | N/A | ❌ | 147 | N/A | N/A: nenhum opcode aplicavel |
| D5 logs_real_512KB | M6 cmp.zstd | 524288 | N/A | N/A | ❌ | N/A | N/A | N/A: zstd indisponivel |
| D5 logs_real_512KB | M7 cmp.lzma | 524288 | 94473 | 18.0193 | ✅ | 264 | 113 |  |
| D5 logs_real_512KB | M8 v0.11-lzma | 524288 | 94473 | 18.0193 | ✅ | 211 | 124 | (mesmo algo que M7 — v0.11 Python lzma FORMAT_ALONE) |
| D5 logs_real_512KB | M9 brotli | 524288 | 118486 | 22.5994 | ✅ | 16 | 49 |  |
| D6 code_ps_20KB | M1 cas.raw | 19577 | 19577 | 100 | ✅ | 0 | 0 | baseline |
| D6 code_ps_20KB | M2 gen.repeat | 19577 | N/A | N/A | ❌ | 0 | N/A | N/A: nenhum opcode aplicavel |
| D6 code_ps_20KB | M3 gen.pattern | 19577 | N/A | N/A | ❌ | 2 | N/A | N/A: nenhum opcode aplicavel |
| D6 code_ps_20KB | M4 rle.decode | 19577 | N/A | N/A | ❌ | 6 | N/A | N/A: nenhum opcode aplicavel |
| D6 code_ps_20KB | M5 procedural.best | 19577 | N/A | N/A | ❌ | 4 | N/A | N/A: nenhum opcode aplicavel |
| D6 code_ps_20KB | M6 cmp.zstd | 19577 | N/A | N/A | ❌ | N/A | N/A | N/A: zstd indisponivel |
| D6 code_ps_20KB | M7 cmp.lzma | 19577 | 6113 | 31.2254 | ✅ | 99 | 68 |  |
| D6 code_ps_20KB | M8 v0.11-lzma | 19577 | 6113 | 31.2254 | ✅ | 78 | 69 | (mesmo algo que M7 — v0.11 Python lzma FORMAT_ALONE) |
| D6 code_ps_20KB | M9 brotli | 19577 | 6684 | 34.1421 | ✅ | 1 | 1 |  |
| D7 text_md_docs | M1 cas.raw | 41862 | 41862 | 100 | ✅ | 0 | 0 | baseline |
| D7 text_md_docs | M2 gen.repeat | 41862 | N/A | N/A | ❌ | 0 | N/A | N/A: nenhum opcode aplicavel |
| D7 text_md_docs | M3 gen.pattern | 41862 | N/A | N/A | ❌ | 0 | N/A | N/A: nenhum opcode aplicavel |
| D7 text_md_docs | M4 rle.decode | 41862 | N/A | N/A | ❌ | 10 | N/A | N/A: nenhum opcode aplicavel |
| D7 text_md_docs | M5 procedural.best | 41862 | N/A | N/A | ❌ | 10 | N/A | N/A: nenhum opcode aplicavel |
| D7 text_md_docs | M6 cmp.zstd | 41862 | N/A | N/A | ❌ | N/A | N/A | N/A: zstd indisponivel |
| D7 text_md_docs | M7 cmp.lzma | 41862 | 13698 | 32.7218 | ✅ | 86 | 120 |  |
| D7 text_md_docs | M8 v0.11-lzma | 41862 | 13698 | 32.7218 | ✅ | 85 | 68 | (mesmo algo que M7 — v0.11 Python lzma FORMAT_ALONE) |
| D7 text_md_docs | M9 brotli | 41862 | 15063 | 35.9825 | ✅ | 1 | 2 |  |
| D8 random_binary_512KB | M1 cas.raw | 524288 | 524288 | 100 | ✅ | 0 | 0 | baseline |
| D8 random_binary_512KB | M2 gen.repeat | 524288 | N/A | N/A | ❌ | 0 | N/A | N/A: nenhum opcode aplicavel |
| D8 random_binary_512KB | M3 gen.pattern | 524288 | N/A | N/A | ❌ | 0 | N/A | N/A: nenhum opcode aplicavel |
| D8 random_binary_512KB | M4 rle.decode | 524288 | N/A | N/A | ❌ | 147 | N/A | N/A: nenhum opcode aplicavel |
| D8 random_binary_512KB | M5 procedural.best | 524288 | N/A | N/A | ❌ | 146 | N/A | N/A: nenhum opcode aplicavel |
| D8 random_binary_512KB | M6 cmp.zstd | 524288 | N/A | N/A | ❌ | N/A | N/A | N/A: zstd indisponivel |
| D8 random_binary_512KB | M7 cmp.lzma | 524288 | 531471 | 101.37 | ✅ | 205 | 179 |  |
| D8 random_binary_512KB | M8 v0.11-lzma | 524288 | 531471 | 101.37 | ✅ | 216 | 514 | (mesmo algo que M7 — v0.11 Python lzma FORMAT_ALONE) |
| D8 random_binary_512KB | M9 brotli | 524288 | 524293 | 100.001 | ✅ | 47 | 113 |  |
| D9 real_file_teia | M1 cas.raw | 208581 | 208581 | 100 | ✅ | 0 | 0 | baseline |
| D9 real_file_teia | M2 gen.repeat | 208581 | N/A | N/A | ❌ | 0 | N/A | N/A: nenhum opcode aplicavel |
| D9 real_file_teia | M3 gen.pattern | 208581 | N/A | N/A | ❌ | 0 | N/A | N/A: nenhum opcode aplicavel |
| D9 real_file_teia | M4 rle.decode | 208581 | N/A | N/A | ❌ | 62 | N/A | N/A: nenhum opcode aplicavel |
| D9 real_file_teia | M5 procedural.best | 208581 | N/A | N/A | ❌ | 60 | N/A | N/A: nenhum opcode aplicavel |
| D9 real_file_teia | M6 cmp.zstd | 208581 | N/A | N/A | ❌ | N/A | N/A | N/A: zstd indisponivel |
| D9 real_file_teia | M7 cmp.lzma | 208581 | 200928 | 96.3309 | ✅ | 239 | 102 |  |
| D9 real_file_teia | M8 v0.11-lzma | 208581 | 200928 | 96.3309 | ✅ | 467 | 94 | (mesmo algo que M7 — v0.11 Python lzma FORMAT_ALONE) |
| D9 real_file_teia | M9 brotli | 208581 | 201681 | 96.6919 | ✅ | 19 | 25 |  |

---

## VENCEDOR POR DATASET

| Dataset | Nota | Vencedor | Ratio% | SHA256 |
|---------|------|---------|------:|:-----:|
| D1 uniform_1MB | 1MB 0xAA — repeticao uniforme constante | **M9 brotli** | 0.0012% | ✅ |
| D2 periodic_ABCD_1MB | 1MB ABCD (4B) x262144 — periodico sintetico | **M9 brotli** | 0.0016% | ✅ |
| D3 rle_3runs_300KB | 300KB: 3 runs de 100KB 0x00/0xFF/0xAA — RLE favoravel | **M9 brotli** | 0.0075% | ✅ |
| D4 json_real_512KB | fractal_index.json (real, primeiros 512KB) | **M7 cmp.lzma** | 10.198% | ✅ |
| D5 logs_real_512KB | dna_events.jsonl (real, primeiros 512KB) | **M7 cmp.lzma** | 18.0193% | ✅ |
| D6 code_ps_20KB | run_tests_v0161.ps1 (codigo PS real ~20KB) | **M7 cmp.lzma** | 31.2254% | ✅ |
| D7 text_md_docs | Documentacao .md concatenada (texto real) | **M7 cmp.lzma** | 32.7218% | ✅ |
| D8 random_binary_512KB | 512KB CSPRNG — binario pseudoaleatorio incompressivel | **M1 cas.raw** | 100% | ✅ |
| D9 real_file_teia | Arquivo real de D:\\bruto\\TEIA ou TEIA_USER | **M7 cmp.lzma** | 96.3309% | ✅ |

---

## RESUMO POR MODO

### M1 cas.raw
Baseline: armazenar original sem modificacao

- Datasets com resultado: 9/9 | N/A: 0/9 | ratio medio: 100%
- Vitórias (melhor ratio por dataset): 1/9

### M2 gen.repeat
Opcode procedural: detect byte constante -> seed JSON

- Datasets com resultado: 1/9 | N/A: 8/9 | ratio medio: 0.03%
- Vitórias (melhor ratio por dataset): 0/9

### M3 gen.pattern
Opcode procedural: detect padrao periodico <=512B -> seed JSON

- Datasets com resultado: 2/9 | N/A: 7/9 | ratio medio: 0.03%
- Vitórias (melhor ratio por dataset): 0/9

### M4 rle.decode
Opcode procedural: runs -> pairs JSON -> seed

- Datasets com resultado: 2/9 | N/A: 7/9 | ratio medio: 0.09%
- Vitórias (melhor ratio por dataset): 0/9

### M5 procedural.best
Melhor opcode procedural disponivel

- Datasets com resultado: 3/9 | N/A: 6/9 | ratio medio: 0.07%
- Vitórias (melhor ratio por dataset): 0/9

### M6 cmp.zstd
N/A: zstd nao disponivel neste ambiente

- Sem resultados validos (N/A em todos)
- Vitórias (melhor ratio por dataset): 0/9

### M7 cmp.lzma
Python lzma FORMAT_ALONE preset=9|EXTREME + 80B seed v0.16

- Datasets com resultado: 9/9 | N/A: 0/9 | ratio medio: 32.22%
- Vitórias (melhor ratio por dataset): 5/9

### M8 v0.11-lzma
Idem M7 (algoritmo identico ao motor historico v0.11)

- Datasets com resultado: 9/9 | N/A: 0/9 | ratio medio: 32.22%
- Vitórias (melhor ratio por dataset): 0/9

### M9 brotli
.NET BrotliStream Optimal + 80B seed v0.16

- Datasets com resultado: 9/9 | N/A: 0/9 | ratio medio: 33.43%
- Vitórias (melhor ratio por dataset): 3/9

---

## DIAGNÓSTICO FINAL

### Conclusões honestas

**Vitórias procedural (M2-M5): 0/9**
**Vitórias compressores (M7-M9): 8/9**

- `procedural.best` (M5): se venceu 0 datasets reais (D4-D9), registrar explicitamente.

**REGISTRO EXPLÍCITO:** `procedural.best` (M5) nao venceu nenhum dataset real (D4–D9).
Os opcodes procedurais sao eficazes apenas em dados sinteticos/altamente estruturados (D1-D3).

### Implicacao para v0.16.0

- Modo com melhor ratio em dados reais estruturados: **M7 cmp.lzma** (10.198% em D4)
- Seletor automático v0.16: usar gen.repeat apenas para D1-class; usar cmp.lzma/brotli para todo o resto.
- Confirmar: qualquer modo declarado 'vencedor' possui SHA-256 restaurado = True.

---

*Gerado por benchmark_hibrido_v0162.ps1 — sem afirmacoes de inovacao; apenas bytes, hashes e tempos.*
