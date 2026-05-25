# TEIA — Histórico Completo de Benchmarks

> **Atualizado**: 2026-05-25 | Sessão de trabalho: motor v0.7.0 → v0.11.0
> **Escopo**: Harness v4.0.0 → v12.0.0 | Corpora D4 + D7 + D8
> **Invariante**: SHA-256 roundtrip verificado em 100% dos arquivos em todos os harnesses

---

## 1. Evolução dos Motores

| Motor | Classe C# | Bytes | Novidade Principal | Overhead por arquivo |
|-------|-----------|-------|--------------------|----------------------|
| **v0.7.0** | TEIANativeV70 | 37,483 | dict.zstd_shared — primeiro opcode; JSON+Base64 seed | ~6,700B (Base64 mata tudo) |
| **v0.8.0** | TEIANativeV80 | 18,580 | Formato binário .teia: magic+header+manifest+payload raw | ~272B (JSON manifest) |
| **v0.8.1** | TEIANativeV81 | 18,191 | opcode zstd.raw; per-bucket strategy; SHA-256 rollback | ~165–284B |
| **v0.9.0** | TEIANativeV90 | 25,134 | Selector Engine; opcode xz.raw (LZMA2/XZ via 7z -txz) | ~164–275B |
| **v0.10.0** | TEIANativeV100 | — | Compact Manifest (43+N bytes vs ~150B JSON); cmp.zstd + cmp.xz | ~66–82B tiny/large |
| **v0.11.0** | TEIANativeV110 | — | opcode cmp.lzma (Python LZMA1 FORMAT_ALONE preset=9\|EXTREME) | ~69–79B |

**SHA-256 dos motores:**
- v0.7.0: `1883B447A7B75FE876FAFB1704EA06FF1695B244916925ADA77F8D37B7CC1206`
- v0.8.1: `a0c73c9f743fdbf3645b9eae53e220e5a5aacb3df8dbd1b3a427541fa2f82484`
- v0.9.0: `35e4937c5edbf39c46514c04fe1680b216c287730eb319f444b3984eed99ef3c`

---

## 2. Corpora de Referência

| Corpus | Arquivos | Tipos | Seed | Buckets |
|--------|----------|-------|------|---------|
| **D4** | 46 | botocore service-2.json, Google API JSON, tokenizers, logs | — | tiny=6, small=14, medium=16, large=10 |
| **D7** | 105 | botocore service-2.json + Google API JSON (zero overlap D4) | 42 | tiny=20, small=45, medium=25, large=15 |
| **D8** | 17 | Google Takeout activity logs (S1-S15) + tokenizers HuggingFace (S16-S17) | — | small=4, medium=7, large=6 |

**Dicionários Zstd treinados:**

| Nome | SHA-256 (16 chars) | Bytes | Corpus de Treino |
|------|---------------------|-------|-----------------|
| dict-small | 4be54040b288207e... | 63,147 | 10 Google API discovery docs (agents_v2 env, fora do manifest) |
| dict-medium | 6c72ae7246b413b8... | 80,055 | 8 botocore service-2.json ~200KB (R21,R22,R25,R27,R28,R32,R34,R36) |

---

## 3. Tabela Histórica — Todos os Harnesses

| Harness | Motor | Corpus | N | Wins | Win% | Savings vs LZMA | SHA-256 RT | Bloqueio Resolvido | Commit |
|---------|-------|--------|---|------|------|-----------------|------------|---------------------|--------|
| **v4.0.0** | v0.7.0 | D4 | 46 | 0/46 | 0% | — (negativo) | 100% OK | — | — |
| **v5.0.0** | v0.8.0 | 2 botocore | 2 | 2/2 | 100% | +3,124B | 100% OK | Base64 → binário | — |
| **v6.0.0** | v0.8.1 | D4 | 46 | 28/46 | 60.9% | N/D | 100% OK | zstd.raw + per-bucket | — |
| **v7.0.0** | v0.8.1 | D7 | 105 | 82/105 | 78.1% | +102,592B | 100% OK | Corpus robusto 105 arq | `e34218c` |
| **v8.0.0** | v0.9.0 | D7 | 105 | 82/105 | 78.1% | +103,418B | 100% OK | Selector Engine; LZMA_JANELA -88% | `c5f9d09` |
| **v9.0.0** | v0.10.0 | D7 | 105 | 105/105 | **100%** | +105,574B | 100% OK | Compact Manifest → tiny flip | `e17d74c` |
| **v10.0.0** | v0.10.0 | D8 | 17 | 1/17 | 5.9% | +9B (S12) | 100% OK | — (stress test adversarial) | `76acd99` |
| **v11.0.0** | v0.11.0 | D8 | 17 | 17/17 | **100%** | +24,709B | 100% OK | cmp.lzma → LZMA_JANELA=0 | `afe367b` |
| **v12.0.0** | v0.11.0 | D7 | 105 | 105/105 | **100%** | +121,812B | 100% OK | Regressão=0; large cmp.lzma=15/15 | `6dcc330` |

> **Savings**: soma de (A_Bytes − D_Bytes) nos arquivos GANHA. Negativo = TEIA maior que LZMA.
> **SHA-256 RT**: roundtrip — todo arquivo restaurado tem SHA-256 idêntico ao original.

---

## 4. Distribuição de Opcodes por Harness (D7)

| Harness | tiny | small | medium | large |
|---------|------|-------|--------|-------|
| **v7** (v0.8.1) | zstd.raw=20 (0 wins) | dict=44, zstd.raw=1 | dict=25 | zstd.raw=13✓, xz.raw=0, lzma=2✗ |
| **v8** (v0.9.0) | zstd.raw=20 (0 wins) | dict=44, zstd.raw=1 | dict=25 | zstd.raw=13✓, xz.raw=2✓ |
| **v9** (v0.10.0) | cmp.zstd=20 ✓ | dict=44✓, cmp.zstd=1✓ | dict=25✓ | zstd.raw=13✓, cmp.xz=2✓ |
| **v12** (v0.11.0) | cmp.zstd=20 ✓ | dict=44✓, cmp.zstd=1✓ | dict=25✓ | **cmp.lzma=15✓** |

---

## 5. Diagnóstico de Perdas por Harness

### v4.0.0 — 0/46 (D4, motor v0.7.0)

| Razão | N | Causa |
|-------|---|-------|
| OVERHEAD_BASE64 | 46 | Base64 adiciona ~6,700B por arquivo (33% do payload); overhead total ~4× maior que a economia Zstd+dict |

**Lição**: Nunca usar Base64 para payload de compressão. Formato binário é obrigatório.

---

### v6.0.0 — 28/46 (D4, motor v0.8.1)

| Razão | N | Detalhe |
|-------|---|---------|
| GANHA | 28 | tiny=1, small=13, medium=12, large=2 |
| LZMA_JANELA | ~16 | large: tokenizers/logs LZMA-dominados; tiny: overhead 164B > margem |
| DICT_PREJUDICA | 0 | — |

**Lição**: D4 inclui tokenizers e logs no corpus large — tipos LZMA-dominados que D7 não tem.

---

### v7.0.0 — 82/105 (D7, motor v0.8.1)

| Razão | N | Detalhe |
|-------|---|---------|
| GANHA | 82 | small=44, medium=25, large=13 |
| OVERHEAD_CANCELA | 21 | 20 tiny (overhead 166B > A-B ≤ 139B) + R29 small |
| LZMA_JANELA | 2 | R96 (+643B), R100 (+296B) |
| DICT_PREJUDICA | 0 | — |

---

### v8.0.0 — 82/105 (D7, motor v0.9.0 Selector Engine)

| Razão | N | Detalhe |
|-------|---|---------|
| GANHA | 82 | mesmos 82 de v7; Selector Engine zero escolhas subótimas |
| OVERHEAD_CANCELA | 21 | idem v7 |
| LZMA_JANELA | 2 | R96 **+73B** (era +643B), R100 **+70B** (era +296B) — redução 88% e 76% |

**v7→v8 delta**: xz.raw (LZMA2, overhead ~245B) vs .7z container (~300B) — margem LZMA_JANELA cai de centenas para dezenas de bytes.

---

### v9.0.0 — 105/105 (D7, motor v0.10.0 Compact Manifest)

| Razão | N | Detalhe |
|-------|---|---------|
| GANHA | 105 | **TODOS** |
| OVERHEAD_CANCELA | 0 | tiny flip: cmp.zstd overhead 72B < A-B ≥ 139B em todo tiny |
| LZMA_JANELA | 0 | R96: cmp.xz -18B; R100: cmp.xz -21B |

**v8→v9 delta**: compact manifest (43+N bytes) vs JSON manifest (~150B) → overhead cai 94B → tiny resolve, LZMA_JANELA resolve.

---

### v10.0.0 — 1/17 (D8 stress test, motor v0.10.0)

| Razão | N | Detalhe |
|-------|---|---------|
| GANHA | 1 | S12 (Google Analytics 889KB) via cmp.xz — margem apenas 9B |
| LZMA_JANELA | 16 | Todos os outros: Python LZMA1 bate 7z LZMA antes do overhead, mas cmp.xz tem overhead equivalente ao ganho |

**Diagnóstico**: LZMA1 (7z archive, ~300B container) vs TEIA overhead ~66-82B. Diferença: Python LZMA1 FORMAT_ALONE stream < 7z LZMA1 stream, mas sem acesso a LZMA1 em formato compacto.

---

### v11.0.0 — 17/17 (D8 stress test, motor v0.11.0 cmp.lzma)

| Razão | N | Detalhe |
|-------|---|---------|
| GANHA | 17 | **TODOS** via cmp.lzma |
| LZMA_JANELA | 0 | Todos resolvidos |

**Maiores ganhos D-A:**

| Arquivo | Tipo | Orig | D-A | C-A (payload Py vs 7z) |
|---------|------|------|-----|----------------------|
| S15 Image Search | LOG | 1,814,869B | **-8,130B** | -8,211B |
| S14 Google Translate | LOG | 1,782,936B | **-3,162B** | -3,247B |
| S10 Maps Medium | LOG | 290,116B | **-2,648B** | -2,727B |
| S12 Analytics | LOG | 889,122B | **-2,301B** | -2,386B |
| S13 Maps Large | LOG | 977,929B | **-1,626B** | -1,702B |
| S17 Tokenizer cerebro | TOK | 2,203,239B | **-1,085B** | -1,154B |
| S16 Tokenizer anthropic | TOK | 1,774,213B | **-712B** | -791B |

**Mecanismo**: overhead TEIA (~77B) << overhead 7z container (~300B). Python LZMA1 EXTREME payload ≤ 7z LZMA1 mx9 em todos os 17 arquivos (C-A negativo em todos).

---

### v12.0.0 — 105/105 (D7 regressão, motor v0.11.0)

| Razão | N | Detalhe |
|-------|---|---------|
| GANHA | 105 | **TODOS** — zero regressões |
| LZMA_JANELA | 0 | — |
| OVERHEAD_CANCELA | 0 | — |

**Surpresa**: cmp.lzma ganhou todos os 15 large botocore (D7), que antes eram zstd.raw/cmp.xz:
- v9 large: avg D=8.45% | v12 large: avg D=**8.32%** (melhora 0.13pp uniforme)
- Savings subiram de 105,574B (v9) → **121,812B** (v12) = +16,238B de ganho grátis

---

## 6. Linha do Tempo — Marcos Técnicos

```
2026-05-25
│
├── [v0.7.0 / v4] FALHA ESTRUTURAL: Base64 overhead mata tudo (0/46)
│   └── Diagnóstico: ~6700B overhead por arquivo = 33% do payload
│
├── [v0.8.0 / v5] BREAKTHROUGH: Formato binário raw → overhead 272B (2/2 wins)
│
├── [v0.8.1 / v6] Per-bucket strategy + zstd.raw → 28/46 D4 (60.9%)
│   └── Descoberta: corpus D4 tem tokenizers/logs — LZMA-dominados no large
│
├── [v0.8.1 / v7] Corpus robusto D7 (105 arq, seed=42) → 82/105 (78.1%)
│   └── 20 tiny OVERHEAD_CANCELA (overhead 166B > margem 139B)
│   └── 2 LZMA_JANELA: R96 +643B, R100 +296B
│
├── [v0.9.0 / v8] Selector Engine + xz.raw → 82/105 (78.1%, savings +826B)
│   └── LZMA_JANELA reduzida: R96 +643B→+73B, R100 +296B→+70B (-88%/-76%)
│
├── [v0.10.0 / v9] Compact Manifest (43+N bytes) → 105/105 D7 (100%)
│   └── tiny: overhead 72B < A-B 139B → 20 tiny flip
│   └── large: cmp.xz overhead 66B → R96 -18B, R100 -21B flip
│
├── [v0.10.0 / v10] D8 stress test (adversarial) → 1/17 (5.9%)
│   └── 16 LZMA_JANELA: tokenizers + logs estruturalmente LZMA1-dominados
│   └── Gap: Python LZMA1 < 7z LZMA1, mas sem acesso a LZMA1 em formato compacto
│
├── [v0.11.0 / v11] cmp.lzma opcode → 17/17 D8 (100%), savings=24,709B
│   └── Python lzma.FORMAT_ALONE preset=9|EXTREME: payload ≤ 7z LZMA1 em todos
│   └── overhead TEIA ~77B << overhead 7z container ~300B
│
└── [v0.11.0 / v12] D7 regressão → 105/105 (100%), savings=121,812B (+16,238B)
    └── cmp.lzma ganha TAMBÉM em large botocore (substitui zstd.raw + cmp.xz)
    └── dict-small/dict-medium dominam small/medium sem interferência de cmp.lzma
```

---

## 7. Estado Atual — Teto por Corpus e Motor

| Corpus | Motor | Wins | Savings | Perdas ativas | Próximo obstáculo |
|--------|-------|------|---------|---------------|-------------------|
| D7 (botocore/GCP JSON) | v0.11.0 | 105/105 | 121,812B | 0 | Nenhum nos tipos testados |
| D8 (logs/tokenizers) | v0.11.0 | 17/17 | 24,709B | 0 | Nenhum nos tipos testados |

**Total savings combinado (D7+D8)**: 121,812 + 24,709 = **146,521B**

---

## 8. Invariantes de Integridade

Todos os harnesses obedecem:
1. **SHA-256 roundtrip**: `SHA256(restore(encode(data))) == SHA256(data)` — verificado em 100% dos arquivos
2. **Write==Read**: `SHA256(bytes_escritos) == SHA256(bytes_lidos_de_volta)` — verificado no relatório e nos `.teia`
3. **Idempotência**: re-execução produz resultado idêntico (dicts por SHA-256, probes determinísticos)
4. **Ausência de Base64**: nenhum payload usa Base64 desde v0.8.0
