# PLANNER ANALYSIS v0.17.0
**Data:** 2026-05-27 09:47:02
**Script:** TEIA-Procedural-Planner-v0170.ps1
**Critério de avanço:** ≥3 arquivos reais com estrutura que plausivamente supera lzma/brotli
**Motor procedural:** TEIA-Core-v0.4.0.ps1 SHA-256 `489D3B40...` (não executado nesta análise)

---

## F01 — s01_uniform_10KB.bin

| Campo | Valor |
|-------|-------|
| Arquivo | `D:\TEIA_CORE\benchmarks\synth_planner\s01_uniform_10KB.bin` |
| Tamanho | 10240 B (10 KB) |
| Analisado | 10240 B (completo) |
| SHA-256 | `3FA2329841713F5C...` |
| Entropia | **0** / 8.0 bits/byte |
| Bytes únicos | 1 / 256 |
| Top-5 bytes | 0xAA=100% 0x00=0% 0xA2=0% 0xA3=0% 0xA4=0% |
| Runs | 1 runs · max=10240B · avg=10240B |
| Período | **1 B** detectado |
| Chunks dup (4KB) | 1/2 (50%) |
| Variância entropia | min=0 max=0 var=0 |
| Linhas | 1 total · 1 únicas · 0 repetidas |

**Estratégia sugerida:** `gen.repeat`

**Confiança:** ALTA

**Motivo:** Arquivo inteiro = único byte repetido (uniqueBytes=1)

**Risco:** BAIXO — seed ~270B, SHA-256 verificado (benchmark D1)

**Supera lzma/brotli?** NÃO — brotli 13B < seed 268B < lzma 237B para 1MB constante

**Vale tentar seed procedural?** Apenas sem biblioteca de compressão disponível

---

## F02 — s02_periodic_ABCDEFGH_10KB.bin

| Campo | Valor |
|-------|-------|
| Arquivo | `D:\TEIA_CORE\benchmarks\synth_planner\s02_periodic_ABCDEFGH_10KB.bin` |
| Tamanho | 10240 B (10 KB) |
| Analisado | 10240 B (completo) |
| SHA-256 | `BDAF86C9381B7467...` |
| Entropia | **3** / 8.0 bits/byte |
| Bytes únicos | 8 / 256 |
| Top-5 bytes | 0x41=12.5% 0x48=12.5% 0x47=12.5% 0x46=12.5% 0x42=12.5% |
| Runs | 10240 runs · max=1B · avg=1B |
| Período | **8 B** detectado |
| Chunks dup (4KB) | 1/2 (50%) |
| Variância entropia | min=3 max=3 var=0 |
| Linhas | 1 total · 1 únicas · 0 repetidas |

**Estratégia sugerida:** `gen.pattern (período=8B)`

**Confiança:** ALTA

**Motivo:** Padrão periódico de 8B detectado em todo o arquivo

**Risco:** BAIXO — seed ~258B, SHA-256 verificado (benchmark D2)

**Supera lzma/brotli?** NÃO — brotli 17B < seed 258B para periódico de 1MB

**Vale tentar seed procedural?** Apenas sem biblioteca de compressão disponível

---

## F03 — s03_rle_3runs_9KB.bin

| Campo | Valor |
|-------|-------|
| Arquivo | `D:\TEIA_CORE\benchmarks\synth_planner\s03_rle_3runs_9KB.bin` |
| Tamanho | 9000 B (8.8 KB) |
| Analisado | 9000 B (completo) |
| SHA-256 | `2AD59DA5FAA43930...` |
| Entropia | **1.585** / 8.0 bits/byte |
| Bytes únicos | 3 / 256 |
| Top-5 bytes | 0x00=33.3% 0xAA=33.3% 0xFF=33.3% 0x03=0% 0xA3=0% |
| Runs | 3 runs · max=3000B · avg=3000B |
| Período | Nenhum |
| Chunks dup (4KB) | 0/2 (0%) |
| Variância entropia | min=0 max=0.92 var=0.2108 |

**Estratégia sugerida:** `rle.decode`

**Confiança:** MEDIA

**Motivo:** 3 runs, avg 3000B/run — seed estimada ~275B

**Risco:** MEDIO — overhead ~25B por run; lzma atinge 143B para 3-run 300KB (benchmark D3)

**Supera lzma/brotli?** NÃO — lzma 143B e brotli 23B vencem seed 448B (D3); mesmo padrão esperado

**Vale tentar seed procedural?** Apenas sem biblioteca de compressão disponível

---

## F04 — fractal_index.json

| Campo | Valor |
|-------|-------|
| Arquivo | `D:\TEIA_CORE\manifests\fractal_index.json` |
| Tamanho | 1296950 B (1266.6 KB) |
| Analisado | primeiros 524288B de 1296950 |
| SHA-256 | `A6746D0DD0DECF5E...` |
| Entropia | **5.259** / 8.0 bits/byte |
| Bytes únicos | 68 / 256 |
| Top-5 bytes | 0x20=9.9% 0x22=6.4% 0x65=4.8% 0x5C=4.5% 0x61=4.1% |
| Runs | 469990 runs · max=4B · avg=1.1B |
| Período | Nenhum |
| Chunks dup (4KB) | 0/128 (0%) |
| Variância entropia | min=5.26 max=5.26 var=0 |
| Linhas | 2835 total · 1242 únicas · 45 repetidas |
| Linha mais repetida | `"version": "v0.12.0"` (×257) |
| JSON chaves únicas | 9 · total=2319 · ratio=257.7× |
| Top JSON keys | size(258), nome_original(258), created_orig(258), path_cas(258), path_origem(258) |

**Estratégia sugerida:** `dict.ref (candidato)`

**Confiança:** HIPOTESE

**Motivo:** JSON: 9 chaves únicas repetidas 257.7× avg. Top: size(258), nome_original(258), created_orig(258), path_cas(258), path_origem(258)

**Risco:** ALTO — encoder dict.ref não existe; mesmo se existisse, lzma já captura repetição de chaves via LZ77

**Supera lzma/brotli?** IMPROVÁVEL — lzma atingiu 10.2% para fractal_index.json (512KB JSON similar)

**Vale tentar seed procedural?** NÃO — investigação acadêmica; lzma é a resposta

---

## F05 — dna_events.jsonl

| Campo | Valor |
|-------|-------|
| Arquivo | `D:\TEIA_CORE\dna_events.jsonl` |
| Tamanho | 1080205 B (1054.9 KB) |
| Analisado | primeiros 524288B de 1080205 |
| SHA-256 | `132BAE149EE764B3...` |
| Entropia | **5.3974** / 8.0 bits/byte |
| Bytes únicos | 70 / 256 |
| Top-5 bytes | 0x22=7.6% 0x5C=5.4% 0x32=4.5% 0x30=4.4% 0x35=3.8% |
| Runs | 494383 runs · max=4B · avg=1.1B |
| Período | Nenhum |
| Chunks dup (4KB) | 0/128 (0%) |
| Variância entropia | min=5.39 max=5.4 var=0 |
| Linhas | 310 total · 310 únicas · 0 repetidas |
| JSON chaves únicas | 14 · total=2785 · ratio=198.9× |
| Top JSON keys | act(310), ts(310), run(310), data(310), sha256(308) |

**Estratégia sugerida:** `dict.ref (candidato)`

**Confiança:** HIPOTESE

**Motivo:** JSON: 14 chaves únicas repetidas 198.9× avg. Top: act(310), ts(310), run(310), data(310), sha256(308)

**Risco:** ALTO — encoder dict.ref não existe; mesmo se existisse, lzma já captura repetição de chaves via LZ77

**Supera lzma/brotli?** IMPROVÁVEL — lzma atingiu 10.2% para fractal_index.json (512KB JSON similar)

**Vale tentar seed procedural?** NÃO — investigação acadêmica; lzma é a resposta

---

## F06 — run_tests_v0161.ps1

| Campo | Valor |
|-------|-------|
| Arquivo | `D:\TEIA_CORE\procedural_tests\v0161\run_tests_v0161.ps1` |
| Tamanho | 19577 B (19.1 KB) |
| Analisado | 19577 B (completo) |
| SHA-256 | `A7D779500D8132A3...` |
| Entropia | **5.7766** / 8.0 bits/byte |
| Bytes únicos | 123 / 256 |
| Top-5 bytes | 0x20=11.9% 0x65=4.9% 0x74=3.8% 0x73=3.3% 0x72=3.2% |
| Runs | 18030 runs · max=19B · avg=1.1B |
| Período | Nenhum |
| Chunks dup (4KB) | 0/4 (0%) |
| Variância entropia | min=5.48 max=5.72 var=0.0128 |
| Linhas | 409 total · 285 únicas · 14 repetidas |
| Linha mais repetida | `M "\| Campo \| Valor \|"` (×8) |

**Estratégia sugerida:** `cmp.brotli ou cmp.lzma`

**Confiança:** MEDIA

**Motivo:** Entropia 5.7766 — comprimível mas menos estruturado; testar ambos compressores

**Risco:** BAIXO

**Supera lzma/brotli?** N/A — compressores dominam; procedural não aplicável

**Vale tentar seed procedural?** NÃO

---

## F07 — BENCHMARK_HIBRIDO_v0162.md

| Campo | Valor |
|-------|-------|
| Arquivo | `D:\TEIA_CORE\docs\BENCHMARK_HIBRIDO_v0162.md` |
| Tamanho | 12248 B (12 KB) |
| Analisado | 12248 B (completo) |
| SHA-256 | `5BEA9DD054C212A8...` |
| Entropia | **5.2279** / 8.0 bits/byte |
| Bytes únicos | 99 / 256 |
| Top-5 bytes | 0x20=19% 0x7C=7.5% 0x65=4.2% 0x61=3.4% 0x6F=3.1% |
| Runs | 11901 runs · max=9B · avg=1B |
| Período | Nenhum |
| Chunks dup (4KB) | 0/2 (0%) |
| Variância entropia | min=4.89 max=5.29 var=0.0203 |
| Linhas | 192 total · 144 únicas · 2 repetidas |
| Linha mais repetida | `- Vitórias (melhor ratio por dataset): 0/9` (×6) |

**Estratégia sugerida:** `cmp.lzma`

**Confiança:** ALTA

**Motivo:** Entropia 5.2279 < 5.5 — estrutura comprimível; lzma domina dados reais (benchmark D4-D7: 10–33%)

**Risco:** BAIXO — resultado confirmado por benchmark

**Supera lzma/brotli?** N/A — lzma É o modo dominante; procedural não tem acesso ao algoritmo gerador

**Vale tentar seed procedural?** NÃO

---

## F08 — $R4F7GHR.zip

| Campo | Valor |
|-------|-------|
| Arquivo | `D:\bruto\TEIA\$R4F7GHR.zip` |
| Tamanho | 208581 B (203.7 KB) |
| Analisado | 208581 B (completo) |
| SHA-256 | `E4D7494994D0AD16...` |
| Entropia | **7.9655** / 8.0 bits/byte |
| Bytes únicos | 256 / 256 |
| Top-5 bytes | 0x00=2.2% 0x01=0.5% 0x08=0.5% 0x04=0.5% 0x54=0.5% |
| Runs | 205264 runs · max=12B · avg=1B |
| Período | Nenhum |
| Chunks dup (4KB) | 0/50 (0%) |
| Variância entropia | min=7.87 max=7.99 var=0.0026 |

**Estratégia sugerida:** `cas.raw`

**Confiança:** ALTA

**Motivo:** Entropia 7.9655 ≈ máximo — incompressível (binário aleatório ou arquivo já comprimido)

**Risco:** N/A — fallback correto (benchmark D8: lzma 101.37%, brotli 100.001%)

**Supera lzma/brotli?** N/A — nada comprime dados com entropia ≈ 8.0

**Vale tentar seed procedural?** NÃO

---

## F09 — TEIA-Core-v0.4.0.ps1

| Campo | Valor |
|-------|-------|
| Arquivo | `D:\TEIA_CLAUDE_AWAKENING\Arqueologia do motor AION RISPA\NúcleoCompressorOntoprocedural\Ontologia Procedural\Motor onto procedural\MOTOR OURO\TEIA-Core-v0.4.0.ps1` |
| Tamanho | 6424 B (6.3 KB) |
| Analisado | 6424 B (completo) |
| SHA-256 | `489D3B4024930FB4...` |
| Entropia | **5.2398** / 8.0 bits/byte |
| Bytes únicos | 88 / 256 |
| Top-5 bytes | 0x20=13.3% 0x65=7.5% 0x74=6.4% 0x24=4.5% 0x6F=4.5% |
| Runs | 6029 runs · max=6B · avg=1.1B |
| Período | Nenhum |
| Chunks dup (4KB) | 0/1 (0%) |
| Variância entropia | min=5.09 max=5.25 var=0.0038 |
| Linhas | 154 total · 112 únicas · 4 repetidas |
| Linha mais repetida | `$outStream.Write($chunk,0,$chunk.Length)` (×8) |

**Estratégia sugerida:** `cmp.lzma`

**Confiança:** ALTA

**Motivo:** Entropia 5.2398 < 5.5 — estrutura comprimível; lzma domina dados reais (benchmark D4-D7: 10–33%)

**Risco:** BAIXO — resultado confirmado por benchmark

**Supera lzma/brotli?** N/A — lzma É o modo dominante; procedural não tem acesso ao algoritmo gerador

**Vale tentar seed procedural?** NÃO

---

## F10 — benchmark_hibrido_v0162.json

| Campo | Valor |
|-------|-------|
| Arquivo | `D:\TEIA_CORE\benchmarks\benchmark_hibrido_v0162.json` |
| Tamanho | 38561 B (37.7 KB) |
| Analisado | 38561 B (completo) |
| SHA-256 | `AC79D594E87225B0...` |
| Entropia | **4.6145** / 8.0 bits/byte |
| Bytes únicos | 82 / 256 |
| Top-5 bytes | 0x20=26.6% 0x22=9.4% 0x65=5% 0x0D=3.6% 0x0A=3.6% |
| Runs | 31654 runs · max=6B · avg=1.2B |
| Período | Nenhum |
| Chunks dup (4KB) | 0/9 (0%) |
| Variância entropia | min=4.54 max=4.63 var=0.0013 |
| Linhas | 1397 total · 262 únicas · 112 repetidas |
| Linha mais repetida | `"overhead": 0,` (×45) |
| JSON chaves únicas | 21 · total=1193 · ratio=56.8× |
| Top JSON keys | Note(99), origB(81), dnote(81), dname(81), overhead(81) |

**Estratégia sugerida:** `dict.ref (candidato)`

**Confiança:** HIPOTESE

**Motivo:** JSON: 21 chaves únicas repetidas 56.8× avg. Top: Note(99), origB(81), dnote(81), dname(81), overhead(81)

**Risco:** ALTO — encoder dict.ref não existe; mesmo se existisse, lzma já captura repetição de chaves via LZ77

**Supera lzma/brotli?** IMPROVÁVEL — lzma atingiu 10.2% para fractal_index.json (512KB JSON similar)

**Vale tentar seed procedural?** NÃO — investigação acadêmica; lzma é a resposta

---

## VEREDICTO: CRITÉRIO DE AVANÇO

### Distribuição de estratégias

| Estratégia | Arquivos |
|-----------|------:|
| cas.raw | 1 |
| cmp.brotli ou cmp.lzma | 1 |
| cmp.lzma | 2 |
| dict.ref | 3 |
| gen.pattern | 1 |
| gen.repeat | 1 |
| rle.decode | 1 |

### Avaliação por arquivo real

| ID | Arquivo | Estratégia | Supera lzma? |
|----|---------|-----------|-------------|
| F01 | s01_uniform_10KB.bin | gen.repeat | NÃO |
| F02 | s02_periodic_ABCDEFGH_10KB.bin | gen.pattern | NÃO |
| F03 | s03_rle_3runs_9KB.bin | rle.decode | NÃO |
| F04 | fractal_index.json | dict.ref | IMPROVÁVEL |
| F05 | dna_events.jsonl | dict.ref | IMPROVÁVEL |
| F06 | run_tests_v0161.ps1 | cmp.brotli ou cmp.lzma | N/A |
| F07 | BENCHMARK_HIBRIDO_v0162.md | cmp.lzma | N/A |
| F08 | $R4F7GHR.zip | cas.raw | N/A |
| F09 | TEIA-Core-v0.4.0.ps1 | cmp.lzma | N/A |
| F10 | benchmark_hibrido_v0162.json | dict.ref | IMPROVÁVEL |

### Decisão

Arquivos com `seedWorth=INVESTIGAR`: **0 / 10**

**NO-GO:** 0 arquivo(s) com estrutura investigável (threshold: ≥3).

**Conclusão honesta:**
- lzma e brotli dominam todos os casos de uso reais nesta coleção.
- Procedural é aplicável apenas a dados sintéticos (D1–D3 class) e cenários sem biblioteca.
- O seletor v0.16.0 (`gen.repeat → cmp.lzma → cmp.brotli → cas.raw`) está correto.
- Nenhum encoder procedural personalizado é justificado por este dataset.

**Próximo passo condicional:** se novos arquivos com estrutura algorítmica conhecida forem
identificados (output de função hash, sequência matemática, log com template rígido de
baixa entropia), re-executar o planner antes de qualquer implementação.

---

*Gerado por TEIA-Procedural-Planner-v0170.ps1 — sem afirmacoes de inovacao; apenas analise estrutural.*
