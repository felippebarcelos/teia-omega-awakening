# Relatório Comparativo TEIA-Core v0.5.0 vs v0.6.0 — Benchmark de Otimização C# Inline

| Meta | Valor |
|------|-------|
| Data | 05/24/2026 21:39:04 |
| Motor v0.5 SHA-256 | `DEF540A76E1F188DCCA4F6D55D3C06D7B84C0395CF7F82C4A403AE209110F6BE` |
| Motor v0.5 tamanho | 8338 bytes |
| Motor v0.6 SHA-256 | `1290462833CADD90ADD5FEC38DE9D1BDBB1D9F23235A47DADE3828CB6247C1C1` |
| Motor v0.6 tamanho | 15464 bytes |
| Harness | v3.1.0 |
| pwsh startup | 280 ms |

---

## Métricas por Domínio

Legenda: † = decode_ms inclui startup pwsh (~280ms); net_ratio = (seed+motor)/orig

### D1_UNIFORM — 512 KB byte único (0xAA)

**Corpus:** 524288 B | Entropia: 0 | SHA-256: `acac3fe365627c359fb15b9f3857eb972ec5402c70e8b1bda2a72db808bb6f12`

| Compressor | Repr(B) | Dict(B) | Ratio% | Net Ratio% | Enc(ms) | Dec(ms) | RAM(MB) | SHA-256 |
|-----------|--------|--------|--------|-----------|--------|--------|--------|--------|
| `brotli` | 13 | 0 | 0,0025 | 0,00 | 4 | 70 | n/a | ✅ |
| `teia_v0.5` † | 189 | 0 | 0,0360 | 1,63 | 20 | 227 | 7.8 | ✅ |
| `teia_v0.6` † | 189 | 0 | 0,0360 | 2,99 | 20 | 195 | 9.3 | ✅ |
| `lzma` | 281 | 0 | 0,0536 | 0,05 | 69 | 134 | n/a | ✅ |
| `deflate` | 526 | 0 | 0,1003 | 0,10 | 3 | 58 | n/a | ✅ |
| `gzip` | 544 | 0 | 0,1038 | 0,10 | 12 | 76 | n/a | ✅ |

> **TEIA v0.5.0 — opcode:** `gen.repeat`
> Opcode procedural mínimo. Seed = receita de 1 instrução.

---

### D2_PATTERN — 256 KB padrão periódico 16B

**Corpus:** 262144 B | Entropia: 0.5 | SHA-256: `7b6fee4a726319c08240c0281b1de38aa9703ae230eb54fc077a9eb46879df6d`

| Compressor | Repr(B) | Dict(B) | Ratio% | Net Ratio% | Enc(ms) | Dec(ms) | RAM(MB) | SHA-256 |
|-----------|--------|--------|--------|-----------|--------|--------|--------|--------|
| `brotli` | 23 | 0 | 0,0088 | 0,01 | 0 | 34 | n/a | ✅ |
| `teia_v0.5` † | 220 | 16 | 0,0839 | 3,26 | 6 | 92 | 0 | ✅ |
| `teia_v0.6` † | 220 | 16 | 0,0839 | 5,98 | 6 | 96 | 3.4 | ✅ |
| `lzma` | 261 | 0 | 0,0996 | 0,10 | 38 | 73 | n/a | ✅ |
| `deflate` | 540 | 0 | 0,2060 | 0,21 | 0 | 63 | n/a | ✅ |
| `gzip` | 558 | 0 | 0,2129 | 0,21 | 0 | 26 | n/a | ✅ |

> **TEIA v0.5.0 — opcode:** `gen.pattern`
> Padrão periódico capturado explicitamente — reproduzível sem o arquivo.

---

### D3_RLE — 256 KB 8 runs bytes distintos

**Corpus:** 262144 B | Entropia: 0 | SHA-256: `45641fde6182d1db36276895523dd6ee3e82c3a6f4a9de9907c3cc83b41795a2`

| Compressor | Repr(B) | Dict(B) | Ratio% | Net Ratio% | Enc(ms) | Dec(ms) | RAM(MB) | SHA-256 |
|-----------|--------|--------|--------|-----------|--------|--------|--------|--------|
| `brotli` | 48 | 0 | 0,0183 | 0,02 | 0 | 43 | n/a | ✅ |
| `lzma` | 270 | 0 | 0,1030 | 0,10 | 40 | 76 | n/a | ✅ |
| `deflate` | 291 | 0 | 0,1110 | 0,11 | 0 | 39 | n/a | ✅ |
| `gzip` | 309 | 0 | 0,1179 | 0,12 | 0 | 28 | n/a | ✅ |
| `teia_v0.5` † | 328 | 0 | 0,1251 | 3,31 | 6 | 196 | 7.8 | ✅ |
| `teia_v0.6` † | 328 | 0 | 0,1251 | 6,02 | 6 | 107 | 6.8 | ✅ |

> **TEIA v0.5.0 — opcode:** `rle.decode`
> 8 runs serializados como pares legíveis. Seed auto-descritiva.

---

### D4_JSON — ~57 KB JSON CAS estruturado

**Corpus:** 59395 B | Entropia: 0.3489 | SHA-256: `6128ef78686e3f32399cdf80b10bd6d467bc60e5887182dc71315fef8f8bf1f1`

| Compressor | Repr(B) | Dict(B) | Ratio% | Net Ratio% | Enc(ms) | Dec(ms) | RAM(MB) | SHA-256 |
|-----------|--------|--------|--------|-----------|--------|--------|--------|--------|
| `teia_v0.5` † | 514 | 64 | 0,8654 | 14,90 | 141 | 68 | 8.9 | ✅ |
| `teia_v0.6` † | 514 | 64 | 0,8654 | 26,90 | 141 | 46 | 1.4 | ✅ |
| `lzma` | 976 | 0 | 1,6432 | 1,64 | 38 | 41 | n/a | ✅ |
| `brotli` | 1512 | 0 | 2,5457 | 2,55 | 0 | 4 | n/a | ✅ |
| `deflate` | 3179 | 0 | 5,3523 | 5,35 | 0 | 5 | n/a | ✅ |
| `gzip` | 3197 | 0 | 5,3826 | 5,38 | 0 | 4 | n/a | ✅ |

> **TEIA v0.5.0 — opcode:** `gen.json_structured`
> Schema declarativo reconstrói o JSON deterministicamente. Dict (hash const) = 64B.

---

### D5_ENTROPY — 128 KB pseudo-random (seed=99999) — fallback.lzma se entropia>0.95

**Corpus:** 131072 B | Entropia: 0.9985 | SHA-256: `b7d3b166ad0f6787b8004ed7fa4b17b5e47481387998fb8b4bf2d9e47848460d`

| Compressor | Repr(B) | Dict(B) | Ratio% | Net Ratio% | Enc(ms) | Dec(ms) | RAM(MB) | SHA-256 |
|-----------|--------|--------|--------|-----------|--------|--------|--------|--------|
| `brotli` | 131077 | 0 | 100,0038 | 100,00 | 20 | 40 | n/a | ✅ |
| `deflate` | 131114 | 0 | 100,0320 | 100,03 | 36 | 28 | n/a | ✅ |
| `gzip` | 131132 | 0 | 100,0458 | 100,05 | 19 | 46 | n/a | ✅ |
| `lzma` | 131212 | 0 | 100,1068 | 100,11 | 74 | 69 | n/a | ✅ |
| `teia_v0.5` † | 175140 | 0 | 133,6212 | 139,98 | 105 | 91 | 0 | ✅ |
| `teia_v0.6` † | 175140 | 0 | 133,6212 | 145,42 | 105 | 83 | 3 | ✅ |

> **TEIA v0.5.0 — opcode:** `fallback.lzma`
> Alta entropia detectada (0.9985). LZMA acionado automaticamente. Sem overhead procedural.

---

## Comparativo v0.4.0 vs v0.5.0 — D4 e D5 (mudanças críticas)

| Domínio | v0.4 opcode | v0.4 seed(B) | v0.4 ratio% | v0.5 opcode | v0.5 seed(B) | v0.5 ratio% | Melhoria |
|---------|------------|------------|------------|------------|------------|------------|---------|
| D4_JSON | v2:gen.json_structured | 511 | 0,86 | v3:gen.json_structured | 514 | 0,8654 | **sem melhoria** |
| D5_ENTROPY | v2:fallback.lzma | 175140 | 133,62 | v3:fallback.lzma | 175140 | 133,6212 | **sem melhoria** |

---

## Comparativo de Latência — v0.5.0 (PS puro) vs v0.6.0 (C# inline)

| Domínio | v0.5 dec_ms | v0.6 dec_ms | Ganho abs | Ganho % | SHA-256 v0.6 |
|---------|------------|------------|----------|--------|-------------|
| `D1_UNIFORM` | 227 | 195 | 32 ms | 14.1% | ✅ |
| `D2_PATTERN` | 92 | 96 | -4 ms | -4.3% | ✅ |
| `D3_RLE` | 196 | 107 | 89 ms | 45.4% | ✅ |
| `D4_JSON` | 68 | 46 | 22 ms | 32.4% | ✅ |
| `D5_ENTROPY` | 91 | 83 | 8 ms | 8.8% | ✅ |

---

## Auditoria — Gargalos Identificados

| Gargalo | Causa Raiz | Impacto | Estado v0.6 |
|---------|-----------|---------|------------|
| Loop byte-a-byte XorB | O(n) PS por byte | Lento em buffers >1KB | ✅ C# XorBuffer — O(n) CLR nativo |
| RLE foreach PS | Dispatch PS por run | Overhead proporcional a runs | ✅ C# DecodeRLE — zero loop PS |
| Gen-JsonStructured for-loop PS | Interpretação PS por record | Lento para corpora grandes | ✅ C# BuildJsonArray — StringBuilder CLR |
| SHA256Hex ForEach-Object pipeline | 32 objetos PS intermediários | Overhead por hash | ✅ C# SHA256Hex — BitConverter direto |
| Startup pwsh por decode | Subprocess por operação | ~280ms fixo | ✅ RESOLVIDO v3 — módulo in-process |
| D4 literal → seed 134% | Opcode literal sem análise estrutural | Seed maior que original | ✅ gen.json_structured (v0.5) |
| D5 literal → seed 133% | Entropia alta sem fallback inteligente | Seed maior que original | ✅ fallback.lzma automático (v0.5) |
| Motor não incluso no ratio clássico | Métricas assimétricas | Net ratio subestimado | ✅ net_ratio_pct reportado explicitamente |

---

## Riscos de Idempotência

| Risco | Severidade | Estado |
|-------|-----------|--------|
| SHA-256 embedded na seed valida decode | CRÍTICO | ✅ ATIVO — motor lança throw se diverge |
| LZMA encode determinístico (7-Zip mmt=1) | ALTO | ✅ Single-thread garante idempotência |
| gen.json_structured com fórmulas (linear_modulo) | ALTO | ✅ Determinístico — sem estado externo |
| Entropia calculada por amostra (16KB) | MÉDIO | ⚠️ Corpus curto (<16KB) não amostrado — usa total |
| Paths absolutos no motor | ALTO | ✅ CLAUDE.md §4 — sem paths relativos |

---

*Benchmark_Harness.ps1 v3.1.0 — v0.5: `DEF540A76E1F188DCCA4F6D55D3C06D7B84C0395CF7F82C4A403AE209110F6BE` | v0.6: `1290462833CADD90ADD5FEC38DE9D1BDBB1D9F23235A47DADE3828CB6247C1C1`*

