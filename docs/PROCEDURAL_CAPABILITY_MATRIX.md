# PROCEDURAL CAPABILITY MATRIX — TEIA-Core v0.4.0
**Atualizado:** 2026-05-27 00:14:42 (provas v0.16.1)
**Fonte:** analise estatica de TEIA-Core-v0.4.0.ps1 + provas SHA-256 desta sessao
**Motor SHA-256:** `489D3B4024930FB4B0E12D0D40393CB86D0430178E6E272DCE328FDEC16475F6`

---

## SUMARIO EXECUTIVO

| Opcode | Status | Encoder | Decoder | Prova SHA-256 | Dominio principal |
|--------|--------|:-------:|:-------:|:-------------:|-------------------|
| `gen.repeat`  | ✅ **VALIDADO**          | ✅ | ✅ | ✅ PROVA_INTEGRIDADE_v0.4 | Dados constantes |
| `gen.pattern` | 🔶 **VALIDADO_MAS_NICHO**    | ✅ | ✅ | ✅ v0.16.1 | Periodicos fixos <= 512B |
| `rle.decode`  | 🔶 **VALIDADO_MAS_NICHO** | ✅ | ✅ | ✅ v0.16.1 | Poucos runs longos |
| `dict.ref`    | ⚠️ **PRECISA_PATCH**    | ❌ | ✅ | ❌ ausente | Streams tokenizados |
| `lz.decode`   | ⚠️ **PRECISA_PATCH**    | ✅ | ✅ | ❌ ausente | Texto/JSON (Base64 overhead) |
| `slice.copy`  | ⚠️ **PRECISA_PATCH**    | ❌ | ✅ | ❌ ausente | Blocos duplicados |
| `xform.xor`  | ❌ **DESCARTAR**        | ✅ | ✅ | ✅ trivial | Nenhum (nao comprime) |
| `literal`     | ❌ **DESCARTAR (CAS)**  | ✅ | ✅ | ✅ trivial | Substituido por cas.raw |

---

## DETALHAMENTO POR OPCODE

### gen.repeat — VALIDADO
| Campo | Valor |
|-------|-------|
| **Assinatura** | `{ op, byte: 0-255, count: int64 }` |
| **Compressao esperada** | infinita:1 — 1MB de 0xAA -> ~18B JSON |
| **SHA-256 restore** | ✅ Verificado — PROVA_INTEGRIDADE_v0.4.md |
| **Status** | ✅ **VALIDADO** |

### gen.pattern — VALIDADO_MAS_NICHO
| Campo | Valor |
|-------|-------|
| **Assinatura** | `{ op, pattern_b64: string, repeat: int64 }` |
| **Limite** | MaxPattern=512B — padroes maiores nao detectados |
| **Compressao esperada** | Alta para periodicos curtos; competitiva com classicos |
| **SHA-256 restore** | ✅ Verificado — provas GP-01 a GP-05 (v0.16.1) |
| **Vitórias sobre classicos** | 0/5 nos testes v0.16.1 |
| **Status** | 🔶 **VALIDADO_MAS_NICHO** — determinístico provado; vence apenas em dados sintéticos periodicos |

### rle.decode — VALIDADO_MAS_NICHO
| Campo | Valor |
|-------|-------|
| **Assinatura** | `{ op, pairs: [{b: int, n: int64}, ...] }` |
| **Overhead** | ~25-30B JSON por pair — domina para muitos runs curtos |
| **Heuristica segura** | Ativar apenas quando n_runs < orig_size / 25 |
| **SHA-256 restore** | ✅ Verificado — provas RLE-01 a RLE-05 (v0.16.1) |
| **Vitórias sobre classicos** | 0/5 nos testes v0.16.1 |
| **Status** | 🔶 **VALIDADO_MAS_NICHO** — determinístico provado; nicho em dados com poucos runs longos |

### dict.ref — PRECISA_PATCH
| Campo | Valor |
|-------|-------|
| **Assinatura** | `{ op, dict: [string], map: [int], encoding: utf8 }` |
| **Bloqueador** | Encoder ausente no Seed-Pack — decoder funciona |
| **Status** | ⚠️ **PRECISA_PATCH** — adiar para v0.17 |

### lz.decode — PRECISA_PATCH
| Campo | Valor |
|-------|-------|
| **Assinatura** | `{ op, algo: brotli\|gzip, payload_b64: string }` |
| **Problema** | Base64 overhead +33% cancela parcialmente a compressao |
| **Solucao v0.16** | cmp.zstd / cmp.lzma com objeto CAS separado |
| **Status** | ⚠️ **PRECISA_PATCH** — resolver via CAS no v0.16 |

### slice.copy — PRECISA_PATCH
| Campo | Valor |
|-------|-------|
| **Assinatura** | `{ op, offset: int64, length: int64, repeat: int64 }` |
| **Bloqueador** | Encoder ausente — decoder funciona |
| **Status** | ⚠️ **PRECISA_PATCH** — adiar para v0.17 |

### xform.xor — DESCARTAR
| Campo | Valor |
|-------|-------|
| **Resultado** | Nao comprime — payload embutido em Base64 (+33% overhead) |
| **Status** | ❌ **DESCARTAR** |

### literal — DESCARTAR
| Campo | Valor |
|-------|-------|
| **Resultado** | Base64 sempre expande — CAS.raw e estritamente superior |
| **Status** | ❌ **DESCARTAR (substituir por cas.raw)** |

---

## PROBLEMA ESTRUTURAL lz.decode

```
Dado original:      1.000.000 bytes
Apos brotli:          250.000 bytes  (ratio 0.25)
Apos Base64:          333.333 bytes  (ratio 0.333 — +33% sobre comprimido)

vs. CAS + cmp.zstd (v0.16 proposto):
Objeto .zstd:         230.000 bytes  (ratio 0.23)
Seed JSON:                 80 bytes  (apenas hash)
Total efetivo:        230.080 bytes  (ratio 0.230)
```

---

*Atualizado por run_tests_v0161.ps1 — referencia: PROCEDURAL_OPCODE_PROOFS_v0161.md*
