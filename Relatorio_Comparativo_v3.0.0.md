# Relatório Comparativo TEIA-Core v0.5.0 vs v0.6.0 — Benchmark de Otimização C# Inline

> **Estado**: MEDIÇÕES REAIS — Harness v3.1.0 | 2026-05-24 | Hardware: i3-10100F, 8GB RAM

| Meta | Valor |
|------|-------|
| Data | 2026-05-24 |
| Motor v0.5 SHA-256 | `DEF540A76E1F188DCCA4F6D55D3C06D7B84C0395CF7F82C4A403AE209110F6BE` |
| Motor v0.5 tamanho | 8 338 bytes |
| Motor v0.6 SHA-256 | `1290462833CADD90ADD5FEC38DE9D1BDBB1D9F23235A47DADE3828CB6247C1C1` |
| Motor v0.6 tamanho | 15 464 bytes |
| Harness | v3.1.0 |
| pwsh startup (baseline) | 280 ms |

---

## Comparativo de Latência — v0.5.0 (PS puro) vs v0.6.0 (C# inline)

| Domínio | v0.5 dec_ms | v0.6 dec_ms | Ganho abs | Ganho % | SHA-256 v0.6 |
|---------|------------|------------|----------|--------|-------------|
| D1_UNIFORM (512 KB gen.repeat) | 227 | 195 | 32 ms | 14.1% | ✅ |
| D2_PATTERN (256 KB gen.pattern) | 92 | 96 | **-4 ms** | -4.3% | ✅ |
| D3_RLE (256 KB rle.decode) | 196 | 107 | **89 ms** | **45.4%** | ✅ |
| D4_JSON (59 KB gen.json) | 68 | 46 | 22 ms | 32.4% | ✅ |
| D5_ENTROPY (128 KB lzma) | 91 | 83 | 8 ms | 8.8% | ✅ |

**Determinismo preservado: 5/5 domínios com SHA-256 ✅.** Rollback: DESCARTADO.

---

## Análise por Domínio

### D1 — gen.repeat, 512 KB — ganho 14.1%

`FillRepeat` C# vs `New-Repeat` PS. Ambos usam doubling com `Buffer.BlockCopy` (já nativo). O ganho de 32ms vem da eliminação do overhead de chamada de função PS + provavelmente custo de JIT da primeira invocação v0.6 (C# compilado em D1, primeiro domínio).

**Gargalo real**: SHA-256 de 512KB (~50ms) + WriteAllBytes de 512KB (~50ms) + ConvertFrom-Json (~30ms). O código de fill leva ~5ms no total.

### D2 — gen.pattern, 256 KB — regressão -4ms ⚠️

**Causa da regressão**: `FillPattern` usa doubling O(log n) ≈ 18 iterações. Em PS, `Buffer.BlockCopy` já opera à velocidade nativa do CLR sem overhead interpretado. O custo de marshal de arrays PS→C# (passagem de `byte[]` para interop) supera marginalmente o ganho da eliminação das 18 iterações PS.

**Conclusão**: para operações já nativas (Buffer.BlockCopy), a fronteira PS→C# não compensa. Operações O(log n) com corpo já nativo devem permanecer em PS.

### D3 — rle.decode, 256 KB — **ganho 89ms (45.4%) — MAIOR GANHO**

`DecodeRLE` C# elimina o `foreach ($p in $Pairs)` PS sobre 8 runs. Cada run no PS gerava: resolução de `$_.b` e `$_.n`, chamada de função `New-Repeat`, alocação de chunk intermediário, `MemoryStream.Write`. Em C#: 8 runs processados in-place em array único pré-alocado, zero chunks intermediários.

**Este é o hot-loop que mais justifica a refatoração.**

### D4 — gen.json_structured, 59 KB — ganho 22ms (32.4%)

`BuildJsonArray` C# elimina `for ($i=0..511)` × `for ($fi=0..2)` = 1536 iterações PS + interpolação de string PS por campo. O StringBuilder C# acumula diretamente sem boxed objects intermediários.

**RAM peak**: v0.5 = 8.9 MB vs v0.6 = **1.4 MB** — redução de **84%**. O C# elimina as alocações de string PS (`"$($f.name)"`, `"$v"`) que PS cria como objetos separados no heap.

### D5 — fallback.lzma, 128 KB — ganho 8ms (8.8%)

Dominado por I/O externa (7-Zip subprocess). SHA256Hex C# é marginalmente mais rápido. Sem impacto significativo esperado neste domínio.

---

## Diagnóstico: Por que a meta <20ms não foi atingida

A meta de decode_ms < 20ms pressupunha que o hot-loop computacional era o gargalo dominante. O benchmark prova que **não é**. O custo real por invocação de `Invoke-TEIARestore`:

| Componente | Custo estimado | Otimizável com C# inline? |
|-----------|---------------|--------------------------|
| `ConvertFrom-Json` (parse do seed) | ~30-50 ms | Não — é PS puro, fora do hot-loop |
| SHA256 do buffer de saída | ~20-50 ms (proporcional ao tamanho) | Marginal — SHA256Hex C# já usado |
| `WriteAllBytes` (I/O disco) | ~30-100 ms (HDD) | Não — I/O bound |
| Código computacional (fill/decode) | ~5-20 ms | ✅ Já otimizado em C# |

**Para atingir <20ms**, as alavancas são:
1. **Modo in-memory**: desabilitar `WriteAllBytes` (retornar `byte[]` em vez de escrever em disco)
2. **Cache de seed**: evitar `ConvertFrom-Json` para seeds repetidas (hashmap seed_sha → plan)
3. **SHA256 streaming**: calcular hash durante geração, não sobre buffer final
4. **SSD**: `WriteAllBytes` de 512KB em HDD leva 50-100ms; em SSD NVMe < 5ms

---

## Resultado da Refatoração C# — Veredicto

| Hot-loop | Ganho real | Análise |
|----------|-----------|---------|
| `XorBuffer` (O(n) byte-a-byte) | não medido* | Eliminação garantida de N iterações PS |
| `DecodeRLE` (foreach PS) | **89ms / 45.4%** | IMPACTO ALTO — confirma hot-loop real |
| `BuildJsonArray` (for-loop PS) | 22ms / 32.4% + 84% RAM | IMPACTO SIGNIFICATIVO |
| `SHA256Hex` (pipeline PS) | ~8ms / difuso | IMPACTO MARGINAL |
| `FillRepeat`/`FillPattern` (doubling) | -4ms a 32ms | Neutro a marginal — já nativo em PS |

*`XorBuffer`: D1-D5 não exercem `xform.xor`. Ganho para buffers grandes (128KB+): ~10-20ms estimado.

---

## Bug Crítico Detectado e Corrigido

**Causa**: `"[\n"` em PowerShell = literal `[`, `\`, `n` (3 bytes). Em C#, `"[\n"` = `[` + LF (2 bytes).
**Detecção**: SHA-256 do D4 falhou imediatamente — `esperado=59395 obtido=59394`.
**Correção**: `sb.Append("[\\n")` em C# — produz `[`, `\`, `n` (matching PS).
**Protocolo SHA-256 funcionou como árbitro**: a divergência de 1 byte foi capturada antes de qualquer dado corrompido ser gravado.

---

## Artefatos Produzidos

| Arquivo | SHA-256 | Descrição |
|---------|---------|-----------|
| `TEIA-Core-v0.6.0.psm1` | `1290462833...C1C1` | Motor com C# hot-loops |
| `Benchmark_Harness.ps1` | v3.1.0 | Harness atualizado com v0.5 vs v0.6 |
| `_bench_canonical/benchmark_results_v4.json` | — | Resultados brutos completos |
| `_bench_canonical/TEIA_Relatorio_Auditoria.json` | — | Auditoria v2.0.0 |

---

## Próximos Passos para Meta <20ms

1. **`Invoke-TEIARestoreInMemory`** — variante sem `WriteAllBytes` + sem validação SHA (para pipelines internos onde a prova já foi feita)
2. **Seed parse cache** — `[hashtable]` `seed_hash → parsed_plan` para seeds repetidas
3. **`SliceCopy` em C#** — único hot-loop PS restante para seeds com alto `$Rep`
4. **Prova "Choque Real"** em X:\\ — validar `Invoke-V6TEIARestore` sobre seed real do volume WinFsp

---

*Benchmark_Harness.ps1 v3.1.0 — v0.5: `DEF540A7...F6BE` | v0.6: `12904628...C1C1`*
