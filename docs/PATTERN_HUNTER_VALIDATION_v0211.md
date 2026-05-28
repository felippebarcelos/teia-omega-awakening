# TEIA — Pattern Hunter Validation v0.21.1
**Data:** 2026-05-28  
**Script de análise:** `TEIA-Pattern-Hunter-v0210.ps1` (com refinamento de nomeação por modelo)  
**Script de validação:** `Test-ObjHypothesis-v0211.ps1`  
**Arquivo-alvo:** `cube_test.obj` (522 B, `model/obj`, SHA-256: `8cde2340...`)  
**Objetivo:** Auditar a capacidade cognitiva de dois modelos LLM para teorizar sobre estrutura 3D paramétrica

---

## 1. Contexto — Por Que Este Experimento

Na execução P4 (v0.21.0), o `deepseek-r1:1.5b` **falhou semanticamente**: confundiu um arquivo `.obj` de 8 vértices com `image/jpeg`, propondo análise DCT/HEVC — alucinação de domínio completa.

Antes de autorizar qualquer HR6 na UVM, precisamos confirmar que **pelo menos um modelo disponível** é capaz de raciocinar corretamente sobre geometria 3D.

---

## 2. Refinamento do Script Hunter

**Mudança aplicada em `TEIA-Pattern-Hunter-v0210.ps1`:**

```powershell
# ANTES (v0.21.0):
$theoryPath = Join-Path $OutputRoot "${sha256}_theory.md"

# DEPOIS (v0.21.1):
$modelSafe  = $Model -replace '[:\\/\*\?\"\<\>\|]', '_'
$theoryPath = Join-Path $OutputRoot "${sha256}_${modelSafe}_theory.md"
```

**Razão:** Permite comparar múltiplos modelos sobre o mesmo arquivo sem sobrescrever resultados. Cada hipótese é identificada por SHA-256 do arquivo + modelo utilizado.

**Exemplo de nomes gerados:**
- `8cde2340..._deepseek-r1_1.5b_theory.md`
- `8cde2340..._qwen2.5-coder_7b_theory.md`

---

## 3. Critérios de Validação (para `model/obj`)

O `Test-ObjHypothesis-v0211.ps1` aplica 3 critérios por regex sobre a seção LLM da hipótese:

| ID | Critério | Lógica | Rationale |
|----|---------|--------|-----------|
| C1 | `VOCABULARIO_GEOMETRICO` | Texto DEVE conter "OBJ", "malha", "vértice", "3D", "geometria", "topologia", "mesh" | Garante que o LLM reconheceu o domínio correto |
| C2 | `AUSENCIA_ALUCINACAO` | Texto NÃO DEVE conter "JPEG", "fotografia", "HEVC", "DCT de imagem", "codec de vídeo", "bitmap" | Detecta alucinação de domínio (confundir `.obj` com imagem/vídeo) |
| C3 | `HR6_PARAMETRICA` | Texto DEVE conter "HR6", "gen.*", "paramétric", "topologi" ou modelo matemático | Valida que a proposta é procedural/paramétrica, não estatística |

---

## 4. Resultados Comparativos

### 4.1 `deepseek-r1:1.5b` — FAIL

| Critério | Resultado | Evidência |
|---------|-----------|-----------|
| C1 VOCABULARIO_GEOMETRICO | PASS | `match="obj"` |
| C2 AUSENCIA_ALUCINACAO | **FAIL** | `match="image/jpeg"` |
| C3 HR6_PARAMETRICA | PASS | `match="modelo matemá"` |
| **VEREDICTO** | **FAIL** | **Alucinação de domínio confirmada** |

**Análise da falha:** O modelo confundiu o tipo `model/obj` com `image/jpeg` e propôs análise de blocos HEVC/CTU para um arquivo de texto com 8 vértices. A frase exata que acionou o critério C2:

> *"Os dados fornecidos sugerem uma possibilidade de modelar o formato como um arquivo do tipo **image/jpeg**, já que: Usa blocos HEVC, CTU e others."*

Causa provável: modelo 1.8B com poucos parâmetros, incapaz de manter coerência semântica entre o tipo detectado (`model/obj`) e a resposta produzida. O contexto `image/jpeg` foi incluído no prompt (como exemplo negativo) e o modelo o reproduziu sem discriminação.

**Tempo de execução:** 44s

---

### 4.2 `qwen2.5-coder:7b` — PASS ✓

| Critério | Resultado | Evidência |
|---------|-----------|-----------|
| C1 VOCABULARIO_GEOMETRICO | PASS | `match="obj"` + "malha 3D", "vértices", "faces", "Topologia de Malha" |
| C2 AUSENCIA_ALUCINACAO | PASS | Nenhum termo de domínio errado detectado |
| C3 HR6_PARAMETRICA | PASS | `match="PARAMÉTRIC"` + proposta `gen.parametric_mesh` |
| **VEREDICTO** | **PASS** | **Hipótese válida para análise humana** |

**Tempo de execução:** 220s

---

## 5. Análise da Tese Qwen (Veredito Humano)

### 5.1 Diagnóstico Estrutural — Correto ✓

O qwen identificou corretamente todos os elementos do formato OBJ:
- `#` → comentários
- `v` → coordenadas de vértice (x, y, z)
- `vn` → normais de vértice
- `f` → índices de face com referência normal (`v//vn`)
- Distribuição de bytes: espaços (0x20), `/`, `.`, dígitos — todos sinais de texto estruturado com números de ponto flutuante

**Observação interessante:** O modelo apontou que a entropia 3.36 bits/byte indica "grande redundância" — inverso do correto (3.36 indica BAIXA entropia, portanto boa compressibilidade). Erro de raciocínio estatístico que seria capturado por validação humana.

### 5.2 Modelo Generativo — Parcialmente Correto ✓

Proposta: **"Topologia de Malha" + "Função Paramétrica de Vértices"**

> *"Para formas simples como cubos, esferas ou pirâmides, pode-se usar equações paramétricas para definir os vértices."*

Este é o insight central correto: o cubo tem apenas 8 vértices que formam os cantos de um bounding box axis-aligned. A representação mínima seria `AABB(min=(0,0,0), max=(1,1,1))` — 6 floats (24 bytes) versus 522 bytes do `.obj` completo. **Fator de compressão teórico: ~22×.**

### 5.3 Proposta HR6+ — Válida como Hipótese ✓

```
IF detect_magic(file) == 'model/obj' AND has_repeated_vertices_and_faces(file):
    APPLY opcode: gen.parametric_mesh
    PARAMETERS: { vertex_count, parametric_formula }
    ESTIMATED_SAVINGS: 50%
    CONFIDENCE: 80%
```

**Avaliação humana:**
- `gen.parametric_mesh` — opcode semântico correto (procedural, não dicionário)
- `vertex_count + parametric_formula` — parâmetros adequados
- `ESTIMATED_SAVINGS: 50%` — conservador; para formas regulares o ganho é muito maior
- `CONFIDENCE: 80%` — razoável para uma hipótese ainda não benchmarkada
- `has_repeated_vertices_and_faces` — condição de detecção interessante, mas imprecisa (o cubo não tem vértices repetidos; a condição certa seria "has_axis_aligned_bounding_box")

**Limitação identificada:** A hipótese é válida para malhas paramétricas simples (cubo, esfera, cilindro) mas não generalizável para malhas orgânicas arbitrárias. O próximo passo seria qualificar o subconjunto de arquivos .obj onde a teoria se aplica.

### 5.4 Contradições Reconhecidas — Honesto ✓

> *"A distribuição de bytes sugere que não há grandes quantidades de repetição dos vértices ou faces, o que dificulta a aplicação de um modelo paramétrico compacto."*

O modelo identifica corretamente a tensão entre a hipótese e os dados. Isso indica raciocínio reflexivo — sinal positivo para confiabilidade da análise.

---

## 6. Comparação de QI Cognitivo

| Dimensão | deepseek-r1:1.5b | qwen2.5-coder:7b |
|---------|-----------------|-----------------|
| Reconhecimento de domínio | ❌ Confundiu com JPEG | ✓ Identificou OBJ/3D corretamente |
| Terminologia geométrica | Parcial ("modelo matemático") | ✓ Malha, vértice, topologia, face |
| Proposta HR6 | ❌ Código Python genérico sem opcode | ✓ `gen.parametric_mesh` com parâmetros |
| Auto-crítica / contradições | ❌ Ausente | ✓ Reconhece limitações da hipótese |
| Raciocínio estatístico | ❌ Entropia invertida | ❌ Entropia invertida (mesmo erro) |
| Tempo de execução | 44s | 220s |
| Validador automático | FAIL (C2) | PASS (3/3) |

---

## 7. Decisão Regulatória

| Pergunta | Decisão |
|---------|---------|
| HR6 pode ser injetada na UVM agora? | **NÃO** — esta é fase de hipótese, não de promoção |
| `qwen2.5-coder:7b` é confiável para Pattern Hunter? | **SIM** — aprovado para pesquisa estrutural |
| `deepseek-r1:1.5b` pode ser usado no Hunter? | **NÃO** — reservado para chamadas de baixo custo onde alucinação de domínio é aceitável |
| Critério de promoção de HR6 para a UVM? | **3+ benchmarks reais** com margem > 2pp sobre LZMA (herdado de HR5) |

---

## 8. Próximos Passos para HR6 (gen.parametric_mesh)

Para validar empiricamente a hipótese `gen.parametric_mesh`:

1. **Coletar 3+ arquivos `.obj` de formas regulares**: cubo, esfera, cilindro, toro (disponíveis em Wikimedia ou repositórios públicos de modelos)
2. **Implementar detector `is_regular_primitive`**: verificar se os vértices pertencem à superfície de uma primitiva conhecida (erro RMS < threshold)
3. **Benchmark real**: comparar `gen.parametric_mesh` (seed paramétrica) vs `cmp.lzma` para os 3+ arquivos — medir taxa de compressão real
4. **Critério de promoção**: margem > 2pp de economia sobre LZMA em todos os 3 arquivos

**Responsável pela promoção:** Operador humano (Felippe Barcelos) após revisão de benchmark.

---

## 9. Integridade

| Métrica | Valor |
|---------|-------|
| CAS objects | 2369 (delta=0 ✓) |
| Hipóteses geradas | 2 (deepseek-1.5b + qwen-7b) |
| Bytes escritos em objects/ | 0 |
| HRs promovidas para UVM | 0 |
| Tese válida (PASS) | 1 (qwen2.5-coder:7b) |
| Tese inválida (FAIL) | 1 (deepseek-r1:1.5b) |

**Regra Absoluta respeitada:** nenhuma HR6 foi injetada na UVM. O sistema permanece em modo de pesquisa.

---

*Experimento executado em 2026-05-28. Validação automática + veredito humano concordam: qwen2.5-coder:7b APROVADO para Pattern Hunter.*
