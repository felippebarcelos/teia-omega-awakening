# HR6 `gen.parametric_mesh` — Especificação Formal v0.21.4
**Data:** 2026-05-28  
**Protocolo:** P4.4 — Engenharia de Contratos  
**Status:** `CANDIDATA_EXPERIMENTAL` → aguardando implementação do encoder para promoção a `HR6_ATIVA`  
**Operador:** Felippe Barcelos  
**Dependências:** P4.2 (4/4 primitivas PASS), P4.3 (Honestidade Entrópica 4/4 confirmada)

---

## 1. Resumo Executivo

A HR6 é uma Hard Rule do NeuroPlanner da TEIA que detecta arquivos Wavefront OBJ de geometria primitiva regular e os substitui por uma Semente Canônica JSON de poucos bytes — redução teórica de **90–97%** sobre o arquivo de texto original.

Este documento é um **contrato arquitetural**. Ele especifica o que a HR6 pode e não pode processar, como a Semente é estruturada, e como o determinismo de SHA-256 é preservado no restore.

**O executor (`TEIA-Core`) permanece intacto.** Este documento é pré-requisito de implementação — não autorização de execução.

---

## 2. Contrato de Fronteira — Tabela de Escopo

### 2.1 PERMITIDO

| Condição | Critério | Evidência Empírica |
|----------|---------|-------------------|
| Tipo de arquivo | `detect_magic == 'model/obj'` (header ASCII, sem bytes BOM) | P4.1–P4.3 |
| Contagem de vértices | `vertex_count < 20` | P4.2: 4–8 v; P4.3: 530+ v → fora do escopo |
| Contagem de faces | `face_count < 30` | P4.2: 2–12 f; teapot tem 1024 f → fora |
| Normais de vértice | `vn` APENAS com valores em `{-1.0, 0.0, 1.0}` — normais axis-aligned | cube.obj: 6 `vn` axis-aligned ✓ |
| Coordenadas de vértice | Todos os valores `v` pertencentes a `ℤ × 10⁻¹` (ex: `0.0`, `1.0`, `0.5`) | cube: 8 vértices em {0.0, 1.0}³ |
| Topologia de faces | Face format `f v//vn` ou `f v` (sem coordenadas UV) | cube: `f v//vn` ✓ |
| Bounding box | AABB verificável: todos os vértices em posição axis-aligned sem rotação | Condição necessária para `gen.cube`/`gen.plane` |

### 2.2 PROIBIDO

| Condição | Critério | Razão |
|----------|---------|-------|
| Materiais externos | Presença de `mtllib` no arquivo | Dependência externa não paramétrica |
| Coordenadas UV | Presença de `vt` | Mapas UV são geometria não-euclídea adicional |
| Normais orgânicas | Qualquer `vn` com valor fora de `{-1.0, 0.0, 1.0}` (ex: `0.4472135954...`) | Indica geometria interpolada irredutível |
| Decimais extensos | Qualquer coordenada `v` com mais de 6 dígitos decimais (ex: `0.447213595499958`) | Sinal de malha orgânica (P4.3: spider/cessna) |
| Alta contagem | `vertex_count >= 20` ou `face_count >= 30` | Limiar empírico da zona de honestidade entrópica |
| Múltiplos objetos | Mais de um bloco `o` ou `g` com geometria distinta | Composição de primitivas requer tratamento separado por objeto |
| Bytes não-ASCII | Qualquer byte > 0x7E no arquivo | Indica encoding inválido ou arquivo binário disfarçado |

### 2.3 Pseudocódigo de Detecção

```
FUNCTION is_hr6_eligible(file_path) -> bool:

    # Critério 0: tipo
    IF detect_magic(file_path) != 'model/obj':
        RETURN false

    # Critério 1: escaneamento de proibições rápidas (O(n) linha a linha)
    FOR line IN read_lines(file_path):
        IF line STARTS_WITH 'mtllib':   RETURN false
        IF line STARTS_WITH 'vt ':      RETURN false
        IF line MATCHES /[^\x00-\x7E]/: RETURN false
        IF line STARTS_WITH 'vn ':
            components = parse_floats(line)
            FOR c IN components:
                IF c NOT IN {-1.0, 0.0, 1.0}: RETURN false
        IF line STARTS_WITH 'v ':
            components = parse_floats(line)
            FOR c IN components:
                IF abs(c) > 1e6:             RETURN false
                IF decimal_digits(c) > 6:    RETURN false

    # Critério 2: contagem
    vertex_count = count_lines_starting_with(file_path, 'v ')
    face_count   = count_lines_starting_with(file_path, 'f ')
    IF vertex_count >= 20: RETURN false
    IF face_count   >= 30: RETURN false

    RETURN true
```

---

## 3. Float Drift Shield — O Escudo de Ponto Flutuante

### 3.1 O Problema

O risco central de um sistema de reconstrução paramétrica é o **drift de ponto flutuante**: ao parsear `"0.0"` → IEEE-754 `float64` → re-formatar como `"0.0"`, o resultado pode diferir por epsilon em coordenadas não-exatas, quebrando o invariante de SHA-256.

**Exemplo de drift potencial:**
```
Original:       vn  0.4472135954999579
Parsed float64: 0.44721359549995787  (epsilon drift)
Re-formatted:   vn  0.4472135954999579  ← pode divergir em plataformas distintas
```

Este caso é **precisamente** o motivo pelo qual normais orgânicas são PROIBIDAS no escopo da HR6. Elas não são representáveis sem risco de drift.

### 3.2 A Solução: Dois Níveis de SHA-256

A HR6 opera com um sistema de **SHA-256 dual**:

| Campo | Definição | Garantia |
|-------|-----------|---------|
| `original_sha256` | SHA-256 do arquivo original byte-a-byte | Proveniência e auditoria |
| `canonical_sha256` | SHA-256 do arquivo reconstruído pelo encoder canônico | Determinismo de restore |

O restore da HR6 produz **sempre** o mesmo `canonical_sha256`, independentemente de plataforma ou runtime.

### 3.3 Regras do Encoder Canônico

Para que `canonical_sha256` seja estável, o encoder canônico da HR6 DEVE:

1. **Coordenadas de vértice:** Formatar como `printf("%.1f", v)` — sempre um decimal. `0.0` nunca `0` ou `0.00`.
2. **Normais axis-aligned:** Formatar como `printf("%.1f", n)` — mesmo padrão. `-1.0` nunca `-1`.
3. **Separadores:** Um único espaço entre token e valor (`v 0.0 0.0 0.0`), sem espaços duplos, sem espaços de trailing.
4. **Quebra de linha:** `\n` (LF Unix) em todos os arquivos reconstruídos — independente de OS.
5. **Comentários:** Preservados **verbatim** a partir do campo `header_lines` da Semente, na ordem definida.
6. **Linhas em branco:** Apenas onde explicitamente registradas na Semente (`blank_lines_after: ["header", "group"]`).
7. **Nome de grupo:** Preservado verbatim de `group_name`.
8. **Ordem de seções:** `header → g → v-block → vn-block → f-block`. Sem seções intercaladas.

### 3.4 Whitespace Divergence — Aviso Explícito

O `cube.obj` original (FSU Burkardt) contém:
- Linhas com espaços duplos: `v  0.0  0.0  0.0`
- Linhas em branco como espaço: ` ` (0x20 isolado)
- Trailing spaces em faces: `f  1//2  3//2  7//2 `

O encoder canônico **normaliza** esses artefatos. Portanto:

```
original_sha256  ≠  canonical_sha256   para cube.obj FSU Burkardt
```

Isso é **comportamento esperado e documentado**. O `original_sha256` é armazenado na Semente como prova de proveniência. O sistema restaura o conteúdo canônico — não o artefato de formatação histórico.

---

## 4. Schema da Semente Canônica (JSON Schema v1.0)

```json
{
  "$schema": "https://teia.local/schemas/parametric-seed-v1.0.json",
  "schema_version": "1.0",
  "opcode": "gen.parametric_mesh",
  "primitive_type": "<string: aabb_cube | plane | pyramid | octahedron | aabb_box>",
  "original_sha256": "<hex64: SHA-256 do arquivo original byte-a-byte>",
  "original_size_bytes": "<int: tamanho original em bytes>",
  "canonical_sha256": "<hex64: SHA-256 do arquivo reconstruído pelo encoder canônico | null se encoder não implementado>",
  "canonical_size_bytes": "<int: tamanho canônico estimado | null se não implementado>",
  "geometry": {
    "aabb": {
      "min": [x_min, y_min, z_min],
      "max": [x_max, y_max, z_max]
    },
    "vertex_count": "<int>",
    "face_count": "<int>",
    "has_normals": "<bool>",
    "normal_type": "<string: axis_aligned | none>",
    "face_format": "<string: v | v//vn | v/vt/vn>",
    "face_winding": "<string: ccw | cw>"
  },
  "topology": {
    "vertices": [[x,y,z], ...],
    "normals": [[nx,ny,nz], ...],
    "faces": [[v_idx, vn_idx], ...]
  },
  "meta": {
    "header_lines": ["<linha 1>", "<linha 2>"],
    "group_name": "<string>",
    "blank_lines_after": ["<seção>"],
    "line_ending": "LF"
  },
  "provenance": {
    "generated_by": "TEIA-Pattern-Hunter-v0210",
    "model_used": "<string: qwen2.5-coder:7b | manual>",
    "date": "YYYY-MM-DD",
    "benchmark_protocol": "P4.2"
  }
}
```

**Campos obrigatórios:** `schema_version`, `opcode`, `primitive_type`, `original_sha256`, `original_size_bytes`, `geometry`, `topology`, `meta`.

**Campo `canonical_sha256`:** `null` enquanto o encoder não estiver implementado. Preenchido após implementação do passo P4.5 (encoder real + benchmark vs LZMA).

---

## 5. Exemplo: Semente Canônica de `cube.obj`

Este é o registro formal da Semente para o arquivo `cube.obj` (FSU Burkardt) que serviu de base para o benchmark P4.2.

```json
{
  "schema_version": "1.0",
  "opcode": "gen.parametric_mesh",
  "primitive_type": "aabb_cube",
  "original_sha256": "8cde23403f5ff52285691128389d7956fe07e43b7f905a5756ec3ae45527bc7a",
  "original_size_bytes": 522,
  "canonical_sha256": null,
  "canonical_size_bytes": null,
  "geometry": {
    "aabb": {
      "min": [0.0, 0.0, 0.0],
      "max": [1.0, 1.0, 1.0]
    },
    "vertex_count": 8,
    "face_count": 12,
    "has_normals": true,
    "normal_type": "axis_aligned",
    "face_format": "v//vn",
    "face_winding": "ccw"
  },
  "topology": {
    "vertices": [
      [0.0, 0.0, 0.0],
      [0.0, 0.0, 1.0],
      [0.0, 1.0, 0.0],
      [0.0, 1.0, 1.0],
      [1.0, 0.0, 0.0],
      [1.0, 0.0, 1.0],
      [1.0, 1.0, 0.0],
      [1.0, 1.0, 1.0]
    ],
    "normals": [
      [ 0.0,  0.0,  1.0],
      [ 0.0,  0.0, -1.0],
      [ 0.0,  1.0,  0.0],
      [ 0.0, -1.0,  0.0],
      [ 1.0,  0.0,  0.0],
      [-1.0,  0.0,  0.0]
    ],
    "faces": [
      [[1,2],[7,2],[5,2]],
      [[1,2],[3,2],[7,2]],
      [[1,6],[4,6],[3,6]],
      [[1,6],[2,6],[4,6]],
      [[3,3],[8,3],[7,3]],
      [[3,3],[4,3],[8,3]],
      [[5,5],[7,5],[8,5]],
      [[5,5],[8,5],[6,5]],
      [[1,4],[5,4],[6,4]],
      [[1,4],[6,4],[2,4]],
      [[2,1],[6,1],[8,1]],
      [[2,1],[8,1],[4,1]]
    ]
  },
  "meta": {
    "header_lines": ["# cube.obj", "#"],
    "group_name": "cube",
    "blank_lines_after": ["header", "group", "vertices"],
    "line_ending": "LF"
  },
  "provenance": {
    "generated_by": "TEIA-Pattern-Hunter-v0210",
    "model_used": "qwen2.5-coder:7b",
    "date": "2026-05-28",
    "benchmark_protocol": "P4.2",
    "source_url": "https://people.sc.fsu.edu/~jburkardt/data/obj/cube.obj"
  }
}
```

**Análise de compressão (teórica):**

| Representação | Tamanho |
|---------------|---------|
| `cube.obj` original | 522 bytes |
| Semente JSON acima | ~1.1 KB (inclui topologia completa) |
| Semente compacta (apenas AABB + algoritmo `cube_v1_ccw`) | **~80 bytes** |
| Fator de compressão (semente compacta) | **~6.5×** |
| Fator teórico (apenas AABB float64 × 6) | **~22× (24 bytes)** |

A Semente completa com topologia explícita ocupa mais que o original — isso é intencional para garantir auditabilidade. A **Semente Compacta** (referência ao algoritmo de triangulação registrado) atinge o fator de compressão máximo.

---

## 6. Contrato de Reconstrução

O encoder/decoder canônico da HR6 implementa o seguinte contrato:

```
FUNÇÃO reconstruct(semente: SementeCanonica) -> bytes:

    linhas = []

    # 1. Header
    PARA linha EM semente.meta.header_lines:
        linhas.append(linha)
    SE "header" EM semente.meta.blank_lines_after:
        linhas.append("")

    # 2. Grupo
    linhas.append("g " + semente.meta.group_name)
    SE "group" EM semente.meta.blank_lines_after:
        linhas.append("")

    # 3. Vértices (formato canônico: "v x y z" — 1 decimal, espaço único)
    PARA [x, y, z] EM semente.topology.vertices:
        linhas.append(f"v {x:.1f} {y:.1f} {z:.1f}")
    SE "vertices" EM semente.meta.blank_lines_after:
        linhas.append("")

    # 4. Normais (apenas se has_normals e normal_type == "axis_aligned")
    SE semente.geometry.has_normals:
        PARA [nx, ny, nz] EM semente.topology.normals:
            linhas.append(f"vn {nx:.1f} {ny:.1f} {nz:.1f}")
        SE "normals" EM semente.meta.blank_lines_after:
            linhas.append("")

    # 5. Faces (formato v//vn com espaço único)
    PARA face EM semente.topology.faces:
        tokens = " ".join(f"{v}//{vn}" PARA [v, vn] EM face)
        linhas.append("f " + tokens)

    # 6. Serialização canônica (LF obrigatório)
    RETORNAR "\n".join(linhas).encode("utf-8")

    # 7. Verificação de integridade
    sha256_reconstruido = sha256(resultado)
    SE semente.canonical_sha256 NÃO É null:
        ASSERT sha256_reconstruido == semente.canonical_sha256,
               "Falha de determinismo: encoder divergiu da semente"
```

---

## 7. Invariantes de Integridade da HR6

| Invariante | Enunciado | Status |
|-----------|-----------|--------|
| I1 | `original_sha256` é imutável após geração da Semente | Obrigatório |
| I2 | `canonical_sha256` é determinístico para a mesma Semente | Obrigatório (pós-implementação) |
| I3 | `reconstruct(semente)` é pura (sem I/O, sem estado externo) | Obrigatório |
| I4 | Nenhuma Semente é gerada para arquivos fora do escopo PERMITIDO | Obrigatório |
| I5 | CAS `objects/` permanece intacto — Semente não substitui o CAS | Obrigatório |
| I6 | `original_sha256 ≠ canonical_sha256` é situação normal e documentada | Advertência documentada |
| I7 | A Semente não é injetada no Executor até `HR6_ATIVA` ser declarada pelo operador | Regra Absoluta |

---

## 8. Critérios de Promoção para `HR6_ATIVA`

Para que a HR6 saia de `CANDIDATA_EXPERIMENTAL` e seja injetada no NeuroPlanner como regra ativa, os seguintes critérios devem ser atendidos e aprovados pelo operador Felippe Barcelos:

| # | Critério | Métrica de Sucesso | Status |
|---|---------|-------------------|--------|
| C1 | Implementar encoder canônico | `reconstruct(semente_cube)` produz arquivo válido | ⏳ Pendente |
| C2 | Calcular `canonical_sha256` para os 4 primitivos do P4.2 | Todos os 4 hashes estáveis em 3 execuções distintas | ⏳ Pendente |
| C3 | Benchmark savings reais | `len(semente_compacta) < len(cmp.lzma(arquivo))` para todos os 4 | ⏳ Pendente |
| C4 | Margem sobre LZMA | Savings HR6 > savings LZMA em pelo menos 2pp para cada arquivo | ⏳ Pendente |
| C5 | Teste de restore em 10 arquivos | 10/10 arquivos reconstruídos com `canonical_sha256` estável | ⏳ Pendente |
| C6 | Implementar `is_hr6_eligible()` no NeuroPlanner | Função presente e testada | ⏳ Pendente |
| C7 | Aprovação do operador | Revisão humana dos dados de C3+C4 | ⏳ Pendente |

**Protocolo de implementação sugerido:** P4.5 (encoder + C1–C4) → P4.6 (testes de restore C5–C6) → Decisão de promoção C7.

---

## 9. O que está fora do escopo desta spec

| Item | Status |
|------|--------|
| Implementação do encoder (`gen.parametric_mesh` executável) | Fora — P4.5 |
| Integração com NeuroPlanner | Fora — pós-C7 |
| Suporte a `gen.sphere`, `gen.cylinder`, `gen.torus` | Fora — extensões futuras |
| Compressão de malhas OBJ com `mtllib` | Fora — fora do escopo PERMITIDO |
| Semente para formatos não-OBJ | Fora — HR7+ |

---

## 10. Linha do Tempo da Hipótese HR6

| Protocolo | Data | Marco |
|-----------|------|-------|
| P4.0 | 2026-05-28 | Pattern Hunter criado; deepseek-1.5b falha em cubo |
| P4.1 | 2026-05-28 | qwen2.5-coder:7b aprovado; validador C1/C2/C3 criado |
| P4.2 | 2026-05-28 | 4/4 primitivas PASS → `CANDIDATA_EXPERIMENTAL` declarada |
| P4.3 | 2026-05-28 | Honestidade Entrópica: 4/4 malhas orgânicas corretamente rejeitadas |
| **P4.4** | **2026-05-28** | **Contrato formal redigido; Float Drift Shield especificado; Semente canônica definida** |
| P4.5 | — | Encoder real + benchmark vs LZMA |
| P4.6 | — | Testes de restore em 10 arquivos |
| P5.0 | — | `HR6_ATIVA` no NeuroPlanner (se C1–C7 aprovados) |

---

## 11. Assinatura e Integridade

| Métrica | Valor |
|---------|-------|
| CAS objects | 2369 (delta=0 ✓) |
| HR6 injetada no Executor | **NÃO** |
| Bytes escritos em `objects/` | **0** |
| Status do sistema | **PESQUISA** |
| Operador responsável pela promoção | Felippe Barcelos |

---

*Especificação redigida em 2026-05-28. A inteligência precede a execução.*
