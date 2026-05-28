# TEIA P5.1 — Arqueologia Digital: Stress Test em Escala
**Data:** 2026-05-28
**Protocolo:** P5.1 — Coleta Autônoma + Watchdog Sentinela
**Script de Coleta:** `Fetch-DigitalArchaeology-P5.ps1`
**Planner Usado:** `TEIA-NeuroPlanner-v0218.ps1` (Rule-First + HR6)

---

## 1. Lote Coletado

| Categoria | Arquivos | Coletados | Falhas |
|-----------|:--------:|:---------:|:------:|
| Textos / Livros / HTML | 5 | 5 | 0 |
| Estruturados (JSON, CSV) | 5 | 5 | 0 |
| Imagens / Mídia | 5 | 4 | 1 (429 Wikimedia rate-limit) |
| Documentos / PDFs | 5 | 2 | 3 (404 rfc-editor) |
| Código-Fonte (download) | 5 | 5 | 0 |
| Modelos 3D OBJ (inline) | 3 | 3 | 0 |
| **TOTAL** | **28** | **24** | **4** |

**Total bytes coletados:** 5.81 MB em 24 arquivos.
**CAS Delta bytes:** 0 — contenção mantida em toda a fase de coleta.

---

## 2. Distribuição das Decisões de Roteamento — Lote P5.1

| Estratégia | Hard Rule | Arquivos | % Lote | Critério Disparado |
|:----------:|:---------:|:--------:|:------:|:-------------------|
| `cas.raw` | HR3 | 6 | 25.0% | `entropy >= 7.0` — binários comprimidos |
| `cmp.lzma` | LLM | 12 | 50.0% | Nenhuma HR → LLM escolhe LZMA para texto longo |
| `cmp.brotli` | HR5 | 3 | 12.5% | `size_bytes < 8192` — arquivos pequenos |
| `gen.parametric_mesh` | HR6 | 3 | 12.5% | `model/obj, size<4096, v<20` — primitivas 3D |

### Detalhamento por Estratégia

**`cas.raw` — HR3 (entropy ≥ 7.0) — 6 arquivos**

| Arquivo | Tamanho | Entropia |
|---------|:-------:|:--------:|
| `mandelbrot_zoom.jpg` | 1281.9 KB | 7.6354 |
| `ant_macro.jpg` | 740.8 KB | 7.9548 |
| `rfc2616_http11.pdf` | 537.7 KB | 7.9292 |
| `rfc3550_rtp.pdf` | 492.3 KB | 7.8875 |
| `stonehenge.jpg` | 189.7 KB | 7.9404 |
| `png_transparency.png` | 219.3 KB | 7.9869 |

> Observação crítica: PDFs e JPEGs têm entropy ≥ 7.0 porque já são internamente comprimidos (DEFLATE/DCT). O sistema detectou corretamente que re-comprimir seria inútil.

**`cmp.lzma` — LLM — 12 arquivos**

| Arquivo | Tamanho | Entropia |
|---------|:-------:|:--------:|
| `world_cities.csv` | 1286.4 KB | 5.3275 |
| `pride_prejudice.txt` | 720.7 KB | 4.5259 |
| `alice_wonderland.txt` | 147.6 KB | 4.6703 |
| `linux_makefile.mk` | 74.2 KB | 5.4613 |
| `cpython_os_module.py` | 41.9 KB | 4.4989 |
| `gpl3_license.txt` | 34.3 KB | 4.5733 |
| `threejs_vector3.js` | 27.6 KB | 4.8763 |
| `jsonplaceholder_todos.json` | 23.7 KB | 4.2233 |
| `nodejs_http_module.js` | 8.1 KB | 5.1525 |
| `iana_reserved_domains.html` | 10.5 KB | 4.9813 |
| `iana_tld_list.txt` | 9.3 KB | 4.6322 |
| `rfc791_ip_spec.txt` | 92.7 KB | 4.1583 |

> Nota de fronteira: `nodejs_http_module.js` tem 8294 bytes — apenas 102 bytes acima do limiar HR5 (8192). Roteou corretamente para LLM → cmp.lzma.

**`cmp.brotli` — HR5 (size < 8192B) — 3 arquivos**

| Arquivo | Tamanho | Entropia |
|---------|:-------:|:--------:|
| `github_linux_repo.json` | 4.9 KB | 4.8470 |
| `npm_react_latest.json` | 1.6 KB | 5.3758 |
| `react_index.js` | 1.7 KB | 5.0076 |

**`gen.parametric_mesh` — HR6 — 3 arquivos**

| Arquivo | Tamanho | v | f | Algoritmo |
|---------|:-------:|:-:|:-:|:---------:|
| `prim_cube.obj` | 440 B | 8 | 12 | `cube_v1_ccw` |
| `prim_octahedron.obj` | 362 B | 6 | 8 | `octahedron_v1_ccw` |
| `prim_plane.obj` | 251 B | 4 | 2 | `plane_v1_ccw` |

---

## 3. Taxa de Compressão Estimada — Lote P5.1

| Estratégia | Bytes Orig | Taxa | Bytes Comprimido |
|:----------:|:----------:|:----:|:----------------:|
| `cas.raw` | 3.46 MB | 0% | 3.46 MB |
| `cmp.lzma` | 2.35 MB | 72% | 0.66 MB |
| `cmp.brotli` | 8.2 KB | 65% | 2.9 KB |
| `gen.parametric_mesh` | 1.0 KB | ~79%* | 210 B |
| **TOTAL** | **5.81 MB** | **30.8%** | **4.12 MB** |

*Economia HR6 extrapolada do benchmark P4.7: pure payload ≈ 21% do tamanho original.

**Interpretação:** A economia de 30.8% é arrastada para baixo pelos 6 arquivos `cas.raw` (59.5% do volume total). Se excluirmos os binários já comprimidos, a economia sobre o conteúdo tratável é ~72.8%.

---

## 4. Relatório Global — Todos os 60 Candidates

Saída completa de `TEIA-Watchdog-Report.ps1 -ShowFiles` na base histórica acumulada:

| Estratégia | Arquivos | Orig (MB) | Comp (MB) | Economia |
|:----------:|:--------:|:---------:|:---------:|:--------:|
| `cas.raw` | 10 | 7.34 | 7.34 | 0% |
| `cmp.brotli` | 15 | 0.03 | 0.01 | ~65% |
| `cmp.lzma` | 25 | 6.15 | 1.72 | ~72% |
| `gen.parametric_mesh` | 6 | ~0.003 | — | ~79%* |
| `gen.pattern` | 1 | 0.25 | 0.001 | ~99.5% |
| `gen.repeat` | 1 | 0.25 | 0.0002 | ~99.9% |
| `unknown` | 2 | ~0.003 | — | — |
| **TOTAL** | **60** | **14.03** | **9.08** | **35.3%** |

*`gen.parametric_mesh` aparece como `?` no Report (taxa de economia não cadastrada no dicionário `$SAVINGS`). Ver seção 6.

---

## 5. Avaliação Crítica: O Sistema Engasgou?

### 5.1 Formatos imprevistos que rotearam corretamente

| Arquivo | Formato | Roteamento | Avaliação |
|---------|---------|:----------:|-----------|
| `rfc2616_http11.pdf` | PDF 1.5 (DEFLATE interno) | HR3 → `cas.raw` | ✓ Correto — PDF já comprimido |
| `world_cities.csv` | CSV 1.3 MB com geo-coords | LLM → `cmp.lzma` | ✓ Correto — texto repetitivo de alta compressibilidade |
| `nodejs_http_module.js` | JS 8294B (102B acima do limiar) | LLM → `cmp.lzma` | ✓ Correto — classificação de borda precisa |
| `iana_tld_list.txt` | TLD registry (9.3KB) | LLM → `cmp.lzma` | ✓ Correto — lista de strings, comprimível |
| `react_index.js` | JS 1.7KB (re-export minúsculo) | HR5 → `cmp.brotli` | ✓ Correto — arquivo pequeno |

### 5.2 Comportamento correto identificado

- **PDFs → cas.raw (HR3, não HR5):** Apesar de serem "documentos", PDFs têm entropy ~7.9 (internamente comprimidos). HR3 dispara antes de HR5. Correto.
- **HR6 acionado:** Os 3 primitivos OBJ inline foram detectados como `model/obj`, passaram na checagem `size < 4096B` e `v < 20`, e rotearam para `gen.parametric_mesh`. 100% de sucesso.
- **LLM não foi chamado para arquivos binários:** Nenhuma imagem ou PDF passou pelo LLM. As Hard Rules interceptaram tudo antes. Correto — o LLM só é invocado quando as regras matemáticas não resolvem.
- **Zero travamentos:** 24 arquivos processados em 263s (~11s/arquivo médio, dominado pelo tempo de consulta LLM para os 12 arquivos de texto).

### 5.3 Lacunas identificadas

| Lacuna | Descrição | Impacto |
|--------|-----------|---------|
| `gen.parametric_mesh` sem taxa no Report | `$SAVINGS` não contém HR6 — mostra `?` e 0% | Cosmético — subestima a economia total |
| SVG (w3c_logo.svg) — rate-limited | Wikimedia retornou 429 durante coleta | Sem impacto no roteador |
| RFC PDFs menores — 404 | `rfc2119`, `rfc7159`, `rfc4648` retornaram 404 no rfc-editor | Sem impacto — 2 PDFs coletados foram suficientes |
| Áudio/OGG — não testado | Nenhum arquivo de áudio no lote final | Hipótese: rota para cas.raw (alta entropy) |

---

## 6. Pendência: `gen.parametric_mesh` no Watchdog Report

O script `TEIA-Watchdog-Report.ps1` usa o dicionário `$SAVINGS` para estimar economia por estratégia. A entrada `gen.parametric_mesh` está ausente, resultando em:

```
gen.parametric_mesh  6   0   0   ?   1×   estratégia desconhecida
```

A taxa empírica do benchmark P4.7 é **~79% de economia** (pure payload 159–184B vs original 411–818B). Esta entrada deveria ser adicionada em P5.x:

```powershell
'gen.parametric_mesh' = [pscustomobject]@{
    rate  = 0.79
    label = '~79%'
    note  = 'P4.7: pure payload ~21% do original (algoritmos cube/plane/octahedron)'
}
```

---

## 7. Integridade

| Métrica | Valor |
|---------|-------|
| Arquivos coletados | 24 |
| Arquivos roteados | 24 / 24 (100%) |
| Falhas de roteamento | 0 |
| Travamentos (hang) | 0 |
| CAS Delta bytes | **0** (contenção total) |
| Hard Rules acionadas | HR3×6, HR5×3, HR6×3 |
| LLM invocado | 12 arquivos |
| Tempo total Watchdog | 263s |

---

*Protocolo P5.1 executado em 2026-05-28. Lote: `D:\TEIA_USER\Inbox\Archaeology\`. CAS Delta bytes=0.*
