# TEIA — Benchmark OBJ Paramétrico para HR6 v0.21.2
**Data:** 2026-05-28  
**Protocolo:** P4.2 — Validação de Hipótese HR6 (sem promoção)  
**Script:** `TEIA-Pattern-Hunter-v0210.ps1` + `Test-ObjHypothesis-v0211.ps1`  
**Modelo LLM:** `qwen2.5-coder:7b`  
**Dataset:** 4 arquivos `.obj` sintéticos de primitivas geométricas

---

## 1. Dataset

| Arquivo | Tamanho | Vértices | Faces | Entropia | SHA-256 (16 hex) |
|---------|---------|---------|-------|---------|------------------|
| `cube.obj`    | 522 B | 8 | 12 | 3.3577 | `8cde23403f5ff522...` |
| `pyramid.obj` | 367 B | 5 | 6  | 4.8774 | `b3bfab74b16da716...` |
| `plane.obj`   | 230 B | 4 | 2  | 4.7767 | `666ad2f00569be13...` |
| `diamond.obj` | 462 B | 6 | 8  | 4.7431 | `cb261c79a40b8273...` |

**Geometrias escolhidas intencionalmente** como primitivas com descrição paramétrica canônica conhecida, permitindo validação humana das propostas do LLM.

---

## 2. Tabela de Resultados

| Arquivo | Vértices | Faces | Entropia (bits) | Reconheceu OBJ? | Propôs HR6 Paramétrica? | Veredito Validador |
|---------|---------|-------|---------|:-:|:-:|:-:|
| `cube.obj`    | 8 | 12 | 3.3577 | ✓ "malha 3D", "vértices", "topologia" | ✓ `gen.parametric_mesh` | **PASS** |
| `plane.obj`   | 4 | 2  | 4.7767 | ✓ "malha 3D", "vértices", "faces", "OBJ" | ✓ `gen.parametric_mesh` | **PASS** |
| `pyramid.obj` | 5 | 6  | 4.8774 | ✓ "malha 3D", "pirâmide 3D", "vértices" | ✓ `gen.piramide_parametrica` | **PASS** |
| `diamond.obj` | 6 | 8  | 4.7431 | ✓ "modelo 3D", "octahedro", "vértices" | ✓ `gen.octahedron` | **PASS** |

**Taxa de aprovação: 4/4 (100%)**

---

## 3. Critérios do Validador — Detalhamento

| Arquivo | C1 VOCABULÁRIO_GEOMÉTRICO | C2 AUSÊNCIA_ALUCINAÇÃO | C3 HR6_PARAMÉTRICA |
|---------|:-:|:-:|:-:|
| `cube.obj`    | PASS (`"obj"`) | PASS (nenhum match) | PASS (`"PARAMÉTRIC"`) |
| `plane.obj`   | PASS (`"obj"`) | PASS (nenhum match) | PASS (`"PARAMÉTRIC"`) |
| `pyramid.obj` | PASS (`"obj"`) | PASS (nenhum match) | PASS (`"PARAMÉTRIC"`) |
| `diamond.obj` | PASS (`"modelo 3"`) | PASS (nenhum match) | PASS (`"PARAMÉTRIC"`) |

**C2 AUSÊNCIA_ALUCINAÇÃO: 4/4 sem falsos positivos.** Nenhum arquivo gerou menção a JPEG, fotografia, DCT de imagem, codec de vídeo ou qualquer domínio incorreto — contraste direto com o `deepseek-r1:1.5b` que falhou em C2 no mesmo arquivo.

---

## 4. Opcodes Propostos pelo LLM por Geometria

| Arquivo | Opcode Proposto | Parâmetros Indicados | Savings Estimado (LLM) | Savings Teórico Real |
|---------|----------------|---------------------|:--------------------:|:--------------------:|
| `cube.obj`    | `gen.parametric_mesh` | `vertex_count, parametric_formula` | 50% | **~95%** |
| `plane.obj`   | `gen.parametric_mesh` | `parametric_formula`               | 75% | **~90%** |
| `pyramid.obj` | `gen.piramide_parametrica` | `base_largura, altura`          | 50% | **~92%** |
| `diamond.obj` | `gen.octahedron`         | `center, radius`                  | 50% | **~97%** |

### Por que o "Savings Teórico Real" é tão maior que o estimado pelo LLM?

O qwen subestimou o ganho porque não calculou o custo real da representação paramétrica. Cálculo manual:

- **`cube.obj` (522 B)**: Representa `AABB(min=(0,0,0), max=(1,1,1))` — 6 floats = ~24 bytes. Fator real: **22×**, economia **~95%**
- **`plane.obj` (230 B)**: Representa `quad(min=(0,0,0), max=(1,0,1))` — 6 floats = ~24 bytes. Fator real: **~10×**, economia **~90%**
- **`pyramid.obj` (367 B)**: Representa `pyramid(base_AABB, height=1)` — 7 floats = ~28 bytes. Fator real: **~13×**, economia **~92%**
- **`diamond.obj` (462 B)**: Representa `octahedron(center=(0,0,0), radius=1)` — 4 floats = ~16 bytes. Fator real: **~29×**, economia **~97%**

**O LLM identificou o modelo correto mas foi conservador nas estimativas de economia.** Isso é preferível ao oposto (estimativas otimistas que falham em benchmark real).

---

## 5. Análise Qualitativa por Arquivo

### 5.1 `cube.obj` — Cubo unitário

**Diagnóstico LLM:** Identificou corretamente vértices (v), normais (vn), faces (f), e a dominância de bytes `0`, `1`, `.`, espaço — consistente com texto ASCII de coordenadas cartesianas.

**Insight geométrico:** Propôs "Topologia de Malha" + função paramétrica para formas simples. Reconheceu que um cubo pode ser descrito por seus parâmetros de bounding box.

**Limitação identificada pelo LLM:** "A distribuição de bytes sugere que não há grandes quantidades de repetição dos vértices ou faces" — auto-crítica correta para modelos arbitrários; para primitivas regulares, a hipótese permanece válida.

---

### 5.2 `plane.obj` — Plano horizontal

**Diagnóstico LLM:** Identificou "objeto plano", separação de seções por linhas vazias, dominância de `#` (comentários) e formatação ASCII.

**Insight geométrico:** Propôs função paramétrica específica para planos 2D: `f(u, v) = (u, 0, v)` com parâmetros de escala — geometricamente correto para um quad em XZ.

**Opcode mais conservador:** Qwen reutilizou `gen.parametric_mesh` em vez de criar `gen.plane` específico — razoável dado que um plano é um caso degenerado de malha.

---

### 5.3 `pyramid.obj` — Pirâmide de base quadrada

**Diagnóstico LLM:** Identificou "base quadrada" e "vértice apóstico" [sic — quis dizer apical], múltiplas faces triangulares.

**Insight geométrico:** Propôs `gen.piramide_parametrica` com parâmetros `{ base_largura, altura }` — **opcode específico para o tipo de primitiva**, não template genérico. Sinal de raciocínio geométrico discriminativo.

**Condição de detecção:**
```
IF detect_magic(file) == 'model/obj' AND file_size < 1024 bytes:
    APPLY opcode: gen.piramide_parametrica
    PARAMETERS: { base_largura, altura }
```

**Observação crítica humana:** `file_size < 1024 bytes` é uma condição de detecção fraca (qualquer .obj pequeno passaria, inclusive esferas ou toros). A condição robusta seria `detect_primitive_type(vertices) == 'pyramid'` — requer análise dos vértices.

---

### 5.4 `diamond.obj` — Octaedro regular

**Diagnóstico LLM:** Identificou "octahedro regular (diamante)", 6 vértices nos pontos cardinais dos 3 eixos, funções trigonométricas como modelo natural.

**Insight geométrico mais preciso do lote:** Propôs `gen.octahedron` com `{ center, radius }` — representação canônica exata para um octaedro regular. Um octaedro de raio 1 pode ser representado por apenas 4 floats: `(cx, cy, cz, r)` = 16 bytes vs 462 bytes do .obj. **Fator teórico: ~29×.**

**Opcode proposto:**
```
IF detect_magic(file) == 'model/obj' AND <condicao_detectavel>:
    APPLY opcode: gen.octahedron
    PARAMETERS: { center: (0,0,0), radius: 1 }
    ESTIMATED_SAVINGS: 50%
    CONFIDENCE: 75%
```

---

## 6. Convergência dos Opcodes

Uma observação importante: o qwen propôs opcodes **diferentes por geometria** (`gen.parametric_mesh`, `gen.piramide_parametrica`, `gen.octahedron`), em vez de reutilizar sempre o mesmo template. Isso indica que o modelo raciocina sobre a geometria específica do arquivo, não apenas sobre o tipo MIME.

Se tivéssemos um opcode unificado para a UVM, a hierarquia natural seria:

```
gen.obj_primitive
    ├── gen.cube          (AABB de 8 vértices alinhados aos eixos)
    ├── gen.plane         (quad em plano de coordenada)
    ├── gen.pyramid       (base AABB + altura + ápice)
    ├── gen.octahedron    (centro + raio)
    └── gen.parametric_mesh (fallback para primitivas não identificadas)
```

---

## 7. Decisão Explícita — HR6 Status

### Critério de Promoção

> **"Se >= 3/4 hipóteses passarem 100% no Validador → Declarar `HR6: gen.parametric_mesh` como `CANDIDATA_EXPERIMENTAL`"**

### Resultado

| Verificação | Resultado |
|-------------|:---------:|
| Arquivos testados | 4/4 |
| Hipóteses com PASS completo (C1+C2+C3) | **4/4 (100%)** |
| Threshold para CANDIDATA_EXPERIMENTAL (≥ 3/4) | ✓ Atingido |

---

## ⚡ DECISÃO: HR6 gen.parametric_mesh → `CANDIDATA_EXPERIMENTAL`

```
DECLARAÇÃO: HR6 gen.parametric_mesh
STATUS    : CANDIDATA_EXPERIMENTAL
DATA      : 2026-05-28
EVIDÊNCIA : 4/4 arquivos .obj com PASS nos critérios C1+C2+C3 (qwen2.5-coder:7b)
ESCOPO    : Primitivas geométricas regulares em formato Wavefront OBJ
LIMITAÇÕES:
  - Validado apenas em primitivas sintéticas simples (4–8 vértices)
  - Não testado em malhas orgânicas (> 100 vértices)
  - Condições de detecção propostas pelo LLM são heurísticas fracas (size < 1024B)
  - Savings reais não verificados — heurística LLM = 50-75%, estimativa manual = 90-97%
  - Nenhum compressor real implementado ou benchmarkado
PRÓXIMOS PASSOS PARA PROMOÇÃO PARA HR6_ATIVA:
  1. Implementar detect_primitive_type(vertices) baseado em análise geométrica
  2. Coletar 10+ arquivos .obj públicos de primitivas (Wikimedia, Sketchfab CC0)
  3. Implementar encoder gen.parametric_mesh e medir savings reais
  4. Benchmark: gen.parametric_mesh vs cmp.lzma em 10 arquivos → margem > 2pp
  5. Aprovação do operador (Felippe Barcelos) após revisão dos dados reais
```

---

## 8. Regra Absoluta Respeitada

| Verificação | Status |
|-------------|--------|
| HR6 injetada no Executor (TEIA-Core) | **NÃO** |
| HR6 injetada no NeuroPlanner | **NÃO** |
| CAS objects modificados | **NÃO** (delta=0) |
| Bytes escritos em `objects/` | **0** |
| Status do sistema | **PESQUISA** |

O sistema permanece em modo de pesquisa. `CANDIDATA_EXPERIMENTAL` significa que a hipótese tem suporte empírico suficiente para design de implementação — não autorização de execução.

---

## 9. Linha do Tempo da Hipótese HR6

| Fase | Data | Marco |
|------|------|-------|
| P4.0 | 2026-05-27 | Pattern Hunter criado; `deepseek-r1:1.5b` falha em cubo |
| P4.1 | 2026-05-28 | `qwen2.5-coder:7b` aprovado; 1/1 PASS; validador criado |
| **P4.2** | **2026-05-28** | **Benchmark 4/4 PASS → HR6 promovida para CANDIDATA_EXPERIMENTAL** |
| P4.3 (futura) | — | Implementar detector de primitiva + encoder real |
| P4.4 (futura) | — | Benchmark real vs LZMA em 10 arquivos públicos |
| P5.0 (futura) | — | HR6_ATIVA no NeuroPlanner (se margem > 2pp confirmada) |

---

*Benchmark executado em 2026-05-28. CAS=2369 (delta=0). HR6 status: CANDIDATA_EXPERIMENTAL.*
