# HR6 × NeuroPlanner — Integração como Hard Rule v0.21.8
**Data:** 2026-05-28
**Protocolo:** P4.8 — Promoção Candidate-Only (Read-Only)
**Versão do Planner:** TEIA-NeuroPlanner-v0218.ps1
**Regra:** `HR6 — gen.parametric_mesh` inserida ANTES de HR5 na árvore de decisão

---

## 1. Arquitetura da Decisão — Rule-First v0218

A árvore de Hard Rules agora segue a seguinte ordem de prioridade:

| Prioridade | Rule ID | Condição | Estratégia |
|:----------:|:-------:|----------|:----------:|
| 1 | HR1 | `unique_bytes == 1` | `gen.repeat` |
| 2 | HR2 | `period_bytes ∈ (0, 512]` | `gen.pattern` |
| 3 | HR3 | `entropy >= 7.0` | `cas.raw` |
| 4 | HR4 | `magic_type` em comprimidos | `cas.raw` |
| **5** | **HR6** | `model/obj AND size<4096 AND 0<v<20` | **`gen.parametric_mesh`** |
| 6 | HR5 | `size_bytes < 8192` | `cmp.brotli` |
| 7 | LLM | Nenhuma regra se aplica | `cmp.lzma` ou `cmp.brotli` |

**Princípio de inserção:** HR6 precede HR5 porque conhecimento geométrico (identidade paramétrica) supera a heurística de tamanho. Um cubo de 800B não é "arquivo pequeno" — é uma primitiva geométrica determinística.

### Detecção de `model/obj`

O profiler estrutural detecta OBJ via:
1. `magic_type ∈ {application/octet-stream, text/utf8bom}` (sem magic binário)
2. `Get-IsText()` retorna `true` (sem bytes nulos nos primeiros 4096B)
3. Extensão `.obj`

O quick scan `Get-ObjQuickScan` conta linhas `v ` e `f ` com early-exit em `vertex_count >= 20`.

---

## 2. Bateria de Testes de Roteamento — 5 Arquivos

| Arquivo | Tamanho | Tipo Detectado | v / f | Regra Disparada | Estratégia | Execution Status |
|---------|:-------:|:--------------:|:-----:|:---------------:|:----------:|:----------------:|
| `cube_large.obj` | 815 B | `model/obj` | v=8 / f=12 | **HR6** | `gen.parametric_mesh` | `candidate_only` |
| `plane_huge.obj` | 462 B | `model/obj` | v=4 / f=2 | **HR6** | `gen.parametric_mesh` | `candidate_only` |
| `diamond_offset.obj` | 422 B | `model/obj` | v=6 / f=8 | **HR6** | `gen.parametric_mesh` | `candidate_only` |
| `cessna.obj` | 195.9 KB | `model/obj` | — | LLM *(size > 4096B)* | `cmp.lzma` | `active` |
| `teapot.obj` | 50.3 KB | `model/obj` | — | LLM *(size > 4096B)* | `cmp.lzma` | `active` |

**5/5 roteamentos corretos.** Primitivos pequenos → HR6 candidate_only. Malhas orgânicas → bypass automático da HR6 pela condição `size < 4096B`.

---

## 3. Anatomia do Candidate JSON — HR6

```json
{
  "version": "0.21.8",
  "execution_status": "candidate_only",
  "final_strategy": "gen.parametric_mesh",
  "planner_verdict": "PARAMETRIC_CANDIDATE",
  "hard_rule_decision": {
    "source": "hard_rule",
    "rule_id": "HR6",
    "rule": "model/obj v=8 f=12 size=815 < 4096",
    "strategy": "gen.parametric_mesh"
  },
  "recipe": {
    "op": "gen.parametric_mesh",
    "execution_status": "candidate_only",
    "note": "HR6: Encode-ParametricMesh pendente aprovação C7 — roteamento declarado, execução bloqueada"
  },
  "integrity_proof": {
    "verifiable": false,
    "method": "gen.parametric_mesh: requer Encode-ParametricMesh (candidate_only — C7 pendente)",
    "pass": null
  }
}
```

A flag `execution_status = "candidate_only"` garante que nenhuma toolchain downstream execute o encoder antes da aprovação C7.

---

## 4. Separação de Responsabilidades — A Regra de Ouro

```
┌──────────────────────────────────────────────────────────────────┐
│                    NEUROPLANNER v0218                            │
│                                                                  │
│  INPUT: arquivo .obj                                             │
│     │                                                            │
│     ├── magic_type = model/obj?  ──NO──→  outras regras         │
│     │                                                            │
│     ├── size < 4096B?            ──NO──→  HR5/LLM (orgânicos)   │
│     │                                                            │
│     └── vertex_count < 20?       ──NO──→  HR5/LLM               │
│              │                                                    │
│              YES                                                  │
│              ↓                                                    │
│     strategy = gen.parametric_mesh                               │
│     execution_status = candidate_only                            │
│     [PLANNER PARA AQUI]                                          │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│  O ENCODER (HR6-ParametricMesh-Prototype-v0216.ps1) NÃO         │
│  está integrado na UVM. Apenas o roteamento está ativo.          │
└──────────────────────────────────────────────────────────────────┘
```

**A IA nunca delibera sobre primitivas geométricas.** O NeuroPlanner v0218 garante:
- **Matemática decide os primitivos:** HR6 dispara deterministicamente por `v_count` e `size`
- **IA decide os orgânicos:** cessna, teapot, magnolia passam direto para o LLM
- **Zero bytes no CAS:** contenção mantida, nenhum OBJ foi codificado nesta etapa

---

## 5. Bug Identificado e Corrigido — UTF-8 BOM

### O Bug

Na primeira execução do teste de roteamento:
```
cube_large.obj  → [text/utf8bom] → HR5 → cmp.brotli  ← INCORRETO
```

**Causa:** `[System.IO.File]::WriteAllText(path, content, [System.Text.Encoding]::UTF8)` em .NET escreve BOM (`EF BB BF`) automaticamente. `Detect-MagicType` retorna `text/utf8bom`. A condição original no v0218 só verificava `application/octet-stream`.

### Fix Duplo

1. **Gerador** (`Generate-StressDataset-P47.ps1`): usar `New-Object System.Text.UTF8Encoding($false)` — BOM-less explícito.
2. **Detector** (`TEIA-NeuroPlanner-v0218.ps1`): ampliar condição:
```powershell
# Antes (incompleto):
if ($magicType -eq 'application/octet-stream' -and $isText -and $ext -eq '.obj')

# Depois (robusto):
if ($magicType -in @('application/octet-stream','text/utf8bom') -and $isText -and $ext -eq '.obj')
```

**Lição:** Codificação de arquivos nunca é neutra. Qualquer pipeline que gera OBJ deve especificar BOM-less explicitamente; qualquer detector de OBJ deve ser resiliente ao BOM.

---

## 6. Integridade

| Métrica | Valor |
|---------|-------|
| CAS objects | delta=0 ✓ (contenção mantida) |
| Encode-ParametricMesh integrado na UVM | **NÃO** |
| Bytes escritos em `objects/` | **0** |
| Candidates HR6 gravados | 3 (`execution_status=candidate_only`) |
| Roteamentos corretos | **5/5** |
| Bugs detectados e corrigidos | 1 (UTF-8 BOM) |

---

## 7. Próximos Passos (C7)

A integração `candidate_only` está aprovada. A promoção completa requer:

| Critério | Status |
|---------|--------|
| C4: HR6 supera LZMA em ≥8/10 | ✓ **10/10** (P4.7) |
| C5: Determinismo SHA-256 100% | ✓ **10/10** (P4.7) |
| C6: Roteamento NeuroPlanner correto | ✓ **5/5** (P4.8) |
| C7: Integração executor na UVM com contenção auditada | ⏳ próximo protocolo |

---

*Protocolo executado em 2026-05-28. Sandbox: `D:\TEIA_CORE\neuroplanner\candidates\`. CAS delta=0.*
