# HR6 `gen.parametric_mesh` — Semente Compacta: Ponto de Inflexão v0.21.6
**Data:** 2026-05-28  
**Protocolo:** P4.6 — Semente Compacta (HR6 Real Economy)  
**Script:** `HR6-ParametricMesh-Prototype-v0216.ps1`  
**Dataset:** 3 primitivos OBJ com algoritmo compacto registrado  
**Regra de contenção:** CAS `objects/` intacto (delta=0); NeuroPlanner e Watchdog inalterados

---

## 1. Tabela Comparativa — O Ponto de Inflexão

| Arquivo | Orig (B) | Semente P4.5 (B) | Semente P4.6 (B) | Payload Puro (B) | Econ. Seed (%) | Econ. Puro (%) | Cross-P4.5 | Determ. |
|---------|:--------:|:----------------:|:----------------:|:----------------:|:--------------:|:--------------:|:----------:|:-------:|
| `cube.obj`    | 522 | 1681 | **502** | **163** | +3.8% | **+68.8%** | ✓ | ✓ |
| `plane.obj`   | 230 |  901 | **503** | **165** | -118.7% | **+28.3%** | ✓ | ✓ |
| `diamond.obj` | 462 | 1353 | **497** | **159** | -7.6% | **+65.6%** | ✓ | ✓ |

**Legenda:**
- **Semente P4.5**: JSON com topologia explícita (vertex/face arrays completos)
- **Semente P4.6**: JSON com parâmetros compactos (`min_coord/max_coord` ou `center/radius`) — comprimido sem indentação
- **Payload Puro**: apenas `opcode + primitive_type + topology_params + topology_algorithm` (sem SHA-256, sem metadados)
- **Cross-P4.5**: `canonical_sha256` de P4.6 é idêntico ao de P4.5 — equivalência matemática provada

---

## 2. Análise do Ponto de Inflexão

### 2.1 Redução da Semente em Relação à P4.5

| Arquivo | Semente P4.5 | Semente P4.6 | Redução |
|---------|:-----------:|:-----------:|:-------:|
| `cube.obj`    | 1681 B | 502 B | **-70.1%** |
| `plane.obj`   | 901 B  | 503 B | **-44.2%** |
| `diamond.obj` | 1353 B | 497 B | **-63.3%** |

A semente despencou de ~1100–1700B para ~500B — redução de **44–70%** eliminando as arrays de topologia explícita.

### 2.2 Por que a Semente P4.6 ainda tem ~500B?

A semente comprimida (sem indentação) ainda contém:
- `"original_sha256"` + `"canonical_sha256"`: 2 × 64 hex + chaves = **~180B** só de hashes
- `"schema_version"`, `"opcode"`, `"primitive_type"`, `"geometry"`, `"meta"`: **~150B** de metadados
- `"topology_params"` (os dados geométricos reais): **~60–80B**
- `"topology_algorithm"`: **~30B**

Os hashes SHA-256 dominam. São essenciais para auditoria de proveniência mas não necessários para restore.

### 2.3 Payload Puro — O Mínimo para Restore

| Arquivo | Payload Puro | Economia vs Original |
|---------|:-----------:|:-------------------:|
| `cube.obj`    | 163 B | **+68.8%** |
| `plane.obj`   | 165 B | **+28.3%** |
| `diamond.obj` | 159 B | **+65.6%** |

O payload puro contém apenas:
```json
{"opcode":"gen.parametric_mesh","primitive_type":"cube",
 "topology_params":{"min_coord":[0.0,0.0,0.0],"max_coord":[1.0,1.0,1.0]},
 "topology_algorithm":"cube_v1_ccw"}
```

**163 bytes** vs 522 bytes original = **68.8% de economia real**.

---

## 3. Cross-Validation P4.5 ↔ P4.6 — Equivalência Matemática

A validação cruzada é a prova mais importante do protocolo P4.6:

| Arquivo | canonical_sha256 (P4.5 explícito) | canonical_sha256 (P4.6 compacto) | Idênticos? |
|---------|:---------------------------------:|:---------------------------------:|:----------:|
| `cube.obj`    | `4df640cbd857edca...` | `4df640cbd857edca...` | ✓ **PASS** |
| `plane.obj`   | `60dfe60faf0e9dae...` | `60dfe60faf0e9dae...` | ✓ **PASS** |
| `diamond.obj` | `aa93b202c8bfc317...` | `aa93b202c8bfc317...` | ✓ **PASS** |

**A semente compacta gera exatamente o mesmo OBJ canônico que a semente explícita.** Os algoritmos `cube_v1_ccw`, `plane_v1_ccw` e `octahedron_v1_ccw` são matematicamente equivalentes à topologia explícita armazenada em P4.5.

---

## 4. Determinismo — Dois Passes Independentes

| Arquivo | Passe 1 SHA-256 | Passe 2 SHA-256 | Idênticos? |
|---------|:---------------:|:---------------:|:----------:|
| `cube.obj`    | `4df640cb...` | `4df640cb...` | ✓ **PASS** |
| `plane.obj`   | `60dfe60f...` | `60dfe60f...` | ✓ **PASS** |
| `diamond.obj` | `aa93b202...` | `aa93b202...` | ✓ **PASS** |

**3/3 determinísticos.** A função `reconstruct(semente_compacta)` é pura.

---

## 5. Seeds Compactas Geradas

**`cube_compact_seed.json`** (502 bytes, minificado):
```json
{"schema_version":"1.0","opcode":"gen.parametric_mesh","primitive_type":"cube",
"original_sha256":"8cde23403f5ff52285691128389d7956fe07e43b7f905a5756ec3ae45527bc7a",
"original_size_bytes":522,"canonical_sha256":"4df640cbd857edca7af093886a3ffa7c74d5fb19091e3e13365124ec53a50fa3",
"geometry":{"vertex_count":8,"face_count":12},
"topology_params":{"min_coord":[0.0,0.0,0.0],"max_coord":[1.0,1.0,1.0]},
"topology_algorithm":"cube_v1_ccw","meta":{"line_ending":"LF","generated":"2026-05-28","protocol":"P4.6"}}
```

**`diamond_compact_seed.json`** (497 bytes, minificado):
```json
{"schema_version":"1.0","opcode":"gen.parametric_mesh","primitive_type":"octahedron",
"original_sha256":"cb261c79a40b8273d537523d45b918364b146e0b0b9c23f356a3017d011b9c04",
"original_size_bytes":462,"canonical_sha256":"aa93b202c8bfc31765c9e1a667dce25ae6907cccd77ecea8b1b4655f9c7437bc",
"geometry":{"vertex_count":6,"face_count":8},
"topology_params":{"center":[0.0,0.0,0.0],"radius":1.0},
"topology_algorithm":"octahedron_v1_ccw","meta":{"line_ending":"LF","generated":"2026-05-28","protocol":"P4.6"}}
```

---

## 6. Bug Identificado e Corrigido — PowerShell Arithmetic in @()

### O Bug

Aritmética inline dentro de `@()` em context de `switch`/função:

```powershell
# FALHOU com: op_Addition on [System.Object[]]
@(
    @($cx, $cy, $cz + $r),    # $cz + $r avaliado como array?
    @($cx + $r, $cy, $cz)
) | ForEach-Object { $vertices.Add([double[]]$_) }
```

Escalares funcionavam (`$cz + $r = 1.0` ✓) mas o mesmo cálculo dentro de `@()` falhava com `op_Addition on Object[]`.

### Fix Aplicado

```powershell
# Pre-computa as somas como variáveis tipadas [double]
[double]$vTop   = $cz + $r    # +Z
[double]$vRight = $cx + $r    # +X
# ... etc.

# Usa as variáveis pré-computadas — sem aritmética inline
$vertices.Add([double[]]@($cx,    $cy,    $vTop  ))
$vertices.Add([double[]]@($vRight,$cy,    $cz    ))
```

**Lição para o registro:** Em PowerShell, aritmética com variáveis `[double]` dentro de um `@()` multi-linha em um bloco `switch` pode ser parsada como array concatenation (`$arr + scalar`) em vez de adição escalar. Solução: sempre pre-computar resultados aritméticos em variáveis tipadas antes de usar em construtores de array.

---

## 7. Conclusão — A HR6 Paramétrica é Viável?

### Resposta: **SIM, para primitivos geométricos regulares**

| Critério | Resultado |
|---------|-----------|
| Economia vs semente explícita (P4.5) | -44% a -70% de tamanho |
| Economia via payload puro vs original | **+28% a +68.8%** |
| Equivalência matemática com P4.5 | ✓ 3/3 canonical SHA-256 idênticos |
| Determinismo (2 passes) | ✓ 3/3 PASS |
| CAS intacto | ✓ delta=0 |

### Perspectiva de Viabilidade

**Para a coleção de assets geométricos da TEIA:**

Um sistema com 10.000 arquivos OBJ onde 1% (100 arquivos) são primitivos simples (cubo, plano, octaedro) com tamanho médio de 400B:
- Armazenamento atual: 100 × 400B = **40 KB**
- Com payload puro HR6: 100 × 163B = **16.3 KB**
- Economia: **~59% por primitivo identificado**

A viabilidade real depende da **taxa de primitivos identificados** no corpus total — hoje validada apenas para os 4 arquivos sintéticos do P4.2.

### Limitação Importante: plane.obj

A economia do `plane.obj` (230B original → 165B payload puro = 28.3%) é menor porque o arquivo original já é muito pequeno. Para planos mais complexos (ou múltiplos planos), a representação paramétrica escala melhor.

### Próximo Passo Crítico (P4.7):

Comparar semente compacta contra LZMA em **10 arquivos públicos** para confirmar que a HR6 supera o algoritmo de propósito geral em margem > 2pp (critério C4 para promoção a `HR6_ATIVA`).

---

## 8. Integridade

| Métrica | Valor |
|---------|-------|
| CAS objects | 2369 (delta=0 ✓) |
| Bytes escritos em `objects/` | **0** |
| HR6 injetada no Executor | **NÃO** |
| Determinismo: 3/3 PASS | ✓ |
| Cross-validation P4.5 ↔ P4.6: 3/3 | ✓ |

---

*Protótipo executado em 2026-05-28. CAS=2369 (delta=0). Sandbox: `D:\TEIA_CORE\sandbox\hr6_compact\`.*
