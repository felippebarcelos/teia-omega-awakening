# HR6 vs LZMA vs Brotli — Benchmark Definitivo v0.21.7
**Data:** 2026-05-28
**Protocolo:** P4.7 — Batismo de Fogo (HR6 Real Economy)
**Dataset:** 10 primitivos OBJ paramétricos com escalas e coordenadas stress-test
**Critério de vitória:** HR6 pure payload < min(LZMA9, Brotli11) do arquivo original

---

## 1. Tabela Decisiva

| Arquivo | Orig (B) | Seed HR6 (B) | LZMA9 (B) | Brotli11 (B) | Vencedor | Determinismo SHA-256 |
|---------|:--------:|:------------:|:---------:|:------------:|:--------:|:--------------------:|
| `cube_large.obj` | 818 | **172** | 296 | 227 | **HR6** (+41.9% vs LZMA) | ✓ PASS |
| `cube_offset.obj` | 780 | **184** | 304 | 239 | **HR6** (+39.5% vs LZMA) | ✓ PASS |
| `cube_small.obj` | 482 | **169** | 244 | 180 | **HR6** (+30.7% vs LZMA) | ✓ PASS |
| `cube_unit.obj` | 767 | **163** | 288 | 221 | **HR6** (+43.4% vs LZMA) | ✓ PASS |
| `diamond_negative.obj` | 436 | **161** | 268 | 197 | **HR6** (+39.9% vs LZMA) | ✓ PASS |
| `diamond_small.obj` | 419 | **164** | 256 | 198 | **HR6** (+35.9% vs LZMA) | ✓ PASS |
| `diamond_unit.obj` | 411 | **159** | 256 | 195 | **HR6** (+37.9% vs LZMA) | ✓ PASS |
| `plane_huge.obj` | 465 | **169** | 264 | 207 | **HR6** (+36% vs LZMA) | ✓ PASS |
| `plane_offset.obj` | 461 | **177** | 280 | 218 | **HR6** (+36.8% vs LZMA) | ✓ PASS |
| `plane_unit.obj` | 443 | **165** | 256 | 206 | **HR6** (+35.5% vs LZMA) | ✓ PASS |

**Legenda:** Seed HR6 = payload puro (opcode + primitive_type + topology_params + topology_algorithm), sem metadados SHA-256.

---

## 2. Análise por Categoria

**Cubos:** 4/4 vitórias | Orig médio=712B | HR6 médio=172B | LZMA médio=283B

**Planos:** 3/3 vitórias | Orig médio=456B | HR6 médio=170B | LZMA médio=267B

**Octaedros:** 3/3 vitórias | Orig médio=422B | HR6 médio=161B | LZMA médio=260B

---

## 3. Cross-Dataset Validation — Invariância Matemática

Três arquivos do dataset P4.7 têm AABB/center idênticos aos primitivos do P4.5/P4.6.
Os canonical SHA-256 são idênticos entre datasets completamente diferentes:

| Arquivo P4.7 | canonical_sha256 | = Hash P4.5/P4.6? |
|-------------|:----------------:|:-----------------:|
| `cube_unit.obj` (stress, Blender-style, vn+faces) | `4df640cbd857edca...` | ✓ = `cube.obj` P4.5 |
| `plane_unit.obj` (stress, scrambled verts, UV+vn) | `60dfe60faf0e9dae...` | ✓ = `plane.obj` P4.5 |
| `diamond_unit.obj` (stress, canonical vert order) | `aa93b202c8bfc317...` | ✓ = `diamond.obj` P4.5 |

**Arquivos com formato completamente diferente (headers, normals, UVs, scrambled vertex ordering) produzem o mesmo canonical SHA-256.** Os algoritmos `cube_v1_ccw`, `plane_v1_ccw` e `octahedron_v1_ccw` são matematicamente invariantes ao formato de entrada — só dependem dos parâmetros geométricos.

---

## 5. SHA-256 Canônico — Tabela de Determinismo

| Arquivo | canonical_sha256 (passe 1 = passe 2) | Determinístico? |
|---------|:------------------------------------|:---------------:|
| `cube_large.obj` | `99a64218bbcddf2b...` | ✓ PASS |
| `cube_offset.obj` | `bb42b02f18042755...` | ✓ PASS |
| `cube_small.obj` | `5c84b320de85af03...` | ✓ PASS |
| `cube_unit.obj` | `4df640cbd857edca...` | ✓ PASS |
| `diamond_negative.obj` | `45e1b15af693cf1c...` | ✓ PASS |
| `diamond_small.obj` | `0a9740f5bebe25dd...` | ✓ PASS |
| `diamond_unit.obj` | `aa93b202c8bfc317...` | ✓ PASS |
| `plane_huge.obj` | `5946673ba63f4ee9...` | ✓ PASS |
| `plane_offset.obj` | `af79fa1a8c0b7522...` | ✓ PASS |
| `plane_unit.obj` | `60dfe60faf0e9dae...` | ✓ PASS |

---

## 6. Veredicto de Promoção

| Critério | Resultado |
|---------|-----------|
| HR6 vence em >= 8/10 arquivos | 10/10 ✓ |
| Determinismo SHA-256: 100% | 10/10 ✓ |
| CAS intacto (delta=0) | ✓ (contenção mantida) |

## ✓ VEREDICTO FINAL: **HR6_PROMOTION_READY**

A abstração geométrica procedural supera a compressão por dicionário em 10/10 primitivos.
O SHA-256 canônico é 100% determinístico. HR6 está elegível para integração na UVM com contenção aprovada.

---

## 7. Integridade

| Métrica | Valor |
|---------|-------|
| CAS objects | delta=0 ✓ |
| HR6 injetada na UVM | **NÃO** |
| Determinismo: 10/10 | ✓ |
| HR6 wins: 10/10 | ✓ |

---

*Benchmark executado em 2026-05-28. Sandbox: `D:\TEIA_CORE\sandbox\hr6_p47`*