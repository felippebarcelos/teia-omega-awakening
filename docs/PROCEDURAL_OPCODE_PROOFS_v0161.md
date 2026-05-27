# PROCEDURAL OPCODE PROOFS v0.16.1
**Data:** 2026-05-27 00:14:42
**Motor:** `TEIA-Core-v0.4.0.ps1` SHA-256 `489D3B4024930FB4B0E12D0D40393CB86D0430178E6E272DCE328FDEC16475F6`
**Nota timing:** ms inclui startup do processo pwsh (~200-500ms overhead fixo)
**Regra:** sha256_match=false invalida a linha

---

## TABELA DE RESULTADOS

| ID | Arquivo | Opcode | Orig (B) | Seed (B) | Ratio% | SHA256 | ms | Melhor classico | Cl. (B) | TEIA vence? |
|----|---------|--------|-------:|-------:|------:|:-----:|----:|---------|-------:|:-----------:|
| GP-01 | `gp01_AB_500k.bin` | `gen.pattern` | 1000000 | 293 | 0.0293 | ✅ | 4802 | brotli | 14 | ❌ NÃO |
| GP-02 | `gp02_ABCD_250k.bin` | `gen.pattern` | 1000000 | 299 | 0.0299 | ✅ | 2976 | brotli | 17 | ❌ NÃO |
| GP-03 | `gp03_00FF_500k.bin` | `gen.pattern` | 1000000 | 295 | 0.0295 | ✅ | 4729 | brotli | 14 | ❌ NÃO |
| GP-04 | `gp04_hello_76923.bin` | `gen.pattern` | 999999 | 311 | 0.0311 | ✅ | 1698 | brotli | 27 | ❌ NÃO |
| GP-05 | `gp05_512pat_2k.bin` | `gen.pattern` | 1024000 | 973 | 0.095 | ✅ | 1161 | brotli | 260 | ❌ NÃO |
| RLE-01 | `rle01_1024_AA.bin` | `rle.decode` | 1024 | 327 | 31.9336 | ✅ | 686 | brotli | 11 | ❌ NÃO |
| RLE-02 | `rle02_16runs_short.bin` | `rle.decode` | 256 | 1248 | 487.5 | ✅ | 669 | brotli | 26 | ❌ NÃO |
| RLE-03 | `rle03_5runs_100k.bin` | `rle.decode` | 512000 | 598 | 0.1168 | ✅ | 1322 | brotli | 35 | ❌ NÃO |
| RLE-04 | `rle04_26letters_1k.bin` | `rle.decode` | 26000 | 1932 | 7.4308 | ✅ | 710 | brotli | 62 | ❌ NÃO |
| RLE-05 | `rle05_256bytes_bad.bin` | `rle.decode` | 1024 | 16029 | 1565.332 | ✅ | 681 | lzma | 266 | ❌ NÃO |

---

## COMPARACAO COMPLETA (todos os algoritmos)

| ID | Orig (B) | Seed (B) | gzip (B) | brotli (B) | lzma (B) | zstd |
|----|-------:|-------:|-------:|--------:|------:|------|
| GP-01 | 1000000 | 293 | 1006 | 14 | 232 | N/A |
| GP-02 | 1000000 | 299 | 1008 | 17 | 234 | N/A |
| GP-03 | 1000000 | 295 | 1004 | 14 | 232 | N/A |
| GP-04 | 999999 | 311 | 1991 | 27 | 244 | N/A |
| GP-05 | 1024000 | 973 | 4316 | 260 | 465 | N/A |
| RLE-01 | 1024 | 327 | 30 | 11 | 31 | N/A |
| RLE-02 | 256 | 1248 | 53 | 26 | 52 | N/A |
| RLE-03 | 512000 | 598 | 540 | 35 | 181 | N/A |
| RLE-04 | 26000 | 1932 | 109 | 62 | 133 | N/A |
| RLE-05 | 1024 | 16029 | 1047 | 926 | 266 | N/A |

---

## DIAGNOSTICO POR OPCODE

### gen.pattern

**SHA-256: TODOS PASSARAM** ✅ — determinístico bit-a-bit confirmado.

**Vitórias sobre melhor clássico: 0/5**

| Teste | Seed (B) | Brotli (B) | Fator |
|-------|-------:|-------:|------:|
| GP-01 (AB, 1MB) | 293 | 14 | brotli 20x menor |
| GP-02 (ABCD, 1MB) | 299 | 17 | brotli 17x menor |
| GP-03 (00FF, 1MB) | 295 | 14 | brotli 21x menor |
| GP-04 (texto 13B, 1MB) | 311 | 27 | brotli 11x menor |
| GP-05 (512B pattern, 1MB) | 973 | 260 | brotli 3.7x menor |

**Por que brotli atinge 14 bytes em 1MB de dado periódico:**
Brotli usa back-references (cópia de janela deslizante). Para "AB" × 500k:
literal "AB" (2 bytes) + copy(offset=2, length=999998) ≈ 14 bytes.
Não é mágica — é LZ77 com Huffman. A mesma estrutura que torna `gen.pattern` eficiente
também é exatamente o que o brotli detecta e explora.

**Distinção real:** seed TEIA não embute dados — é apenas parâmetros (`pattern_b64`, `repeat`).
Brotli embute dados comprimidos. Ambos restauram o mesmo arquivo. Para ratio de armazenamento,
brotli vence. Para "receita sem dados embutidos", TEIA é o único formato disponível.

**Conclusão para v0.16.0:** `gen.pattern` NÃO deve estar no seletor automático.
`cmp.lzma` via CAS (~232B objeto + ~80B seed = ~312B total) é comparável ou superior.
Manter `gen.pattern` apenas para uso manual quando nenhuma biblioteca de compressão está disponível.

### rle.decode

**SHA-256: TODOS PASSARAM** ✅ — determinístico bit-a-bit confirmado.

**Vitórias sobre melhor clássico: 0/5**

| Teste | Seed (B) | Brotli (B) | Fator |
|-------|-------:|-------:|------:|
| RLE-01 (1024B, 1 run) | 327 | 11 | brotli 30x menor |
| RLE-02 (256B, 16 runs curtos) | 1248 | 26 | seed 5x MAIOR que original |
| RLE-03 (512KB, 5 runs longos) | 598 | 35 | brotli 17x menor |
| RLE-04 (26KB, 26 runs) | 1932 | 62 | brotli 31x menor |
| RLE-05 (1024B, 256 runs) | 16029 | 926 | seed 15x maior que original |

**Overhead JSON por pair:** ~25–30 bytes (`{"b":255,"n":102400}`).
Para n_runs alto, o overhead domina completamente. RLE-02 com 16 runs curtos
já produz seed 5x maior que o arquivo original (256 bytes).

**Caso RLE-05:** 256 runs × ~63B por pair em JSON = 16,029 bytes seed vs. 1,024 bytes originais.
Ratio de 1565% — piora o armazenamento 15x. lzma atinge 266 bytes para o mesmo arquivo.

**Heurística segura:** ativar `rle.decode` apenas quando `n_runs < orig_size / 30`.
Para RLE-03 (5 runs, 512KB): 5 < 512000/30=17,066 → ativaria. Seed=598B, brotli=35B.
Mas brotli ainda vence. O opcode só faria sentido sem biblioteca de compressão disponível.

**Conclusão para v0.16.0:** `rle.decode` NÃO deve estar no seletor automático.
`cmp.lzma` via CAS domina em todos os casos testados.

---

## STATUS FINAL

| Opcode | SHA-256 | Vitórias | Status v0.16.1 | Domínio |
|--------|:-------:|:--------:|----------------|---------|
| `gen.repeat`  | ✅ PROVA_INTEGRIDADE_v0.4 | 5/5 (constante) | **VALIDADO** | Dados constantes |
| `gen.pattern` | ✅ esta sessão | 0/5 | **VALIDADO_MAS_NICHO** | Periódicos fixos ≤ 512B |
| `rle.decode`  | ✅ esta sessão | 0/5 | **VALIDADO_MAS_NICHO** | Poucos runs longos homogêneos |
| `dict.ref`    | ❌ encoder ausente | — | **PRECISA_PATCH** | Streams tokenizados |
| `lz.decode`   | ❌ Base64 overhead | — | **PRECISA_PATCH** | Texto/JSON via CAS no v0.16 |
| `slice.copy`  | ❌ encoder ausente | — | **PRECISA_PATCH** | Blocos duplicados |
| `xform.xor`  | ✅ trivial | 0/5 | **DESCARTAR** | Sem compressão |
| `literal`     | ✅ trivial | 0/5 | **DESCARTAR** | CAS.raw superior |

---

*Gerado por run_tests_v0161.ps1 — sem afirmacoes de inovacao; apenas bytes, hashes e tempos.*
