# NEUROPLANNER — Patch Cosmético v0.19.9
**Data:** 2026-05-27  
**Base:** `TEIA-NeuroPlanner-v0197.ps1`  
**Patch:** `TEIA-NeuroPlanner-v0199.ps1`  
**Escopo:** Bugfix puro — zero funcionalidade nova  
**Bugs corrigidos:** BUG-01, BUG-02 (mapeados no baseline v0.19.8)

---

## 1. Linhas Alteradas

### BUG-01 — `Get-PlannerVerdict` retornava `LZMA_PREFERRED` para `cmp.brotli`

**Arquivo:** `TEIA-NeuroPlanner-v0199.ps1`

| Linha | Antes | Depois |
|-------|-------|--------|
| 372 | `'cmp.brotli'  { 'LZMA_PREFERRED' }` | `'cmp.brotli'  { 'BROTLI_PREFERRED' }` |
| 562 | `elseif ($verdict -eq 'LZMA_PREFERRED') { 'Yellow' }` | adicionado: `elseif ($verdict -eq 'BROTLI_PREFERRED') { 'Cyan' }` antes do LZMA_PREFERRED |

**Impacto:** o campo `planner_verdict` nos `candidate.json` agora reflete corretamente `BROTLI_PREFERRED` para arquivos roteados para `cmp.brotli` (via HR5 ou LLM). A `final_strategy` nunca foi afetada — apenas o label era errado.

---

### BUG-02 — Relatório final agrupava arquivos HR5 como "LLM decide"

**Arquivo:** `TEIA-NeuroPlanner-v0199.ps1` — bloco do relatório final (linhas ~605–627)

**Antes** — dois grupos (sem distinção HR5):
```
$medium = arquivos com entropy∈[2,7), sem período → "LZMA/BROTLI — LLM decide"
```
`.teia_map.json` (2.5KB, HR5→brotli) aparecia incorretamente em "LLM decide".

**Depois** — três grupos separados:
```powershell
# Grupo novo: HR5 (size < 8192, entropy∈[2,7), sem período)
[object[]]$hrSmall = @($allProfiles | Where-Object {
    $_.entropy -ge 2.0 -and $_.entropy -lt 7.0 -and
    $_.period_bytes -eq 0 -and $_.unique_bytes -gt 1 -and
    [long]$_.size_bytes -lt 8192
})

# Grupo LLM: agora restrito a size ≥ 8192
[object[]]$medium  = @($allProfiles | Where-Object {
    $_.entropy -ge 2.0 -and $_.entropy -lt 7.0 -and
    $_.period_bytes -eq 0 -and $_.unique_bytes -gt 1 -and
    [long]$_.size_bytes -ge 8192
})
```

Label novo: `HR5_BROTLI (N) — Hard Rule HR5 (size < 8 KB → cmp.brotli):`  
Label ajustado: `LZMA/BROTLI (N) — LLM decide (size ≥ 8 KB):`

---

### Metadados de versão atualizados

| Campo | v0.19.7 | v0.19.9 |
|-------|---------|---------|
| `.SYNOPSIS` | `TEIA-NeuroPlanner-v0197.ps1` | `TEIA-NeuroPlanner-v0199.ps1` |
| Arquitetura | `v0.19.7` | `v0.19.9` |
| Banner TCT | `[TCT/NEUROPLANNER_v0197]` | `[TCT/NEUROPLANNER_v0199]` |
| `version` no candidate JSON | `'0.19.7'` | `'0.19.9'` |
| Título do relatório final | `NEUROPLANNER-v0197` | `NEUROPLANNER-v0199` |

---

## 2. Output Console — Prova de Correção

Rodada com `corpus_d1.bin` (256KB), `fractal_index.json` (1266.6KB), `.teia_map.json` (2.5KB):

```
======================================================================
 [TCT/NEUROPLANNER_v0199] TEIA-NeuroPlanner-v0199.ps1
 Modo    : Rule-First (HR1-HR5) → LLM apenas para arquivos ≥8KB sem período
 Modelo  : qwen2.5-coder:7b  |  Modo: ATIVO
 Output  : D:\TEIA_CORE\neuroplanner\candidates
======================================================================

[NP] corpus_d1.bin (256 KB)
     e=0  u=1  p=1  [text]
     [HR1] unique_bytes == 1 → gen.repeat
     Prova SHA-256: PASS — gen.repeat(0xAA, 262144)
     Verdict: PROCEDURAL_CANDIDATE
     Gravado: 83496bcb7c50d8de...

[NP] fractal_index.json (1266.6 KB)
     e=5.259  u=68  p=0  [text]
     [LLM] entropy∈[2,7) sem período, size≥8KB — LLM decide lzma vs brotli
     LLM (qwen2.5-coder:7b): lzma vs brotli... → cmp.lzma
     Verdict: LZMA_PREFERRED
     Gravado: a6746d0dd0decf5e...

[NP] .teia_map.json (2.5 KB)
     e=5.2867  u=61  p=0  [json]
     [HR5] size_bytes=2549 < 8192 (arquivo pequeno — Brotli supera LZMA por dicionário estático) → cmp.brotli
     Verdict: BROTLI_PREFERRED
     Gravado: 60c4f6188ca9df36...

======================================================================
 RELATÓRIO FINAL — TEIA-NeuroPlanner-v0199
======================================================================

 Analisados: 3  OK: 3  Skip: 0  Fail: 0

  PROCEDURAIS (1) — Hard Rules HR1/HR2:
    ✓ corpus_d1.bin [HR1 byte-único e=0]
  HR5_BROTLI (1) — Hard Rule HR5 (size < 8 KB → cmp.brotli):
    ✓ .teia_map.json [HR5 size=2549B e=5.2867 → cmp.brotli]
  LZMA/BROTLI (1) — LLM decide (size ≥ 8 KB):
    ~ fractal_index.json [e=5.259 text]

 Candidates em: D:\TEIA_CORE\neuroplanner\candidates
======================================================================
```

**BUG-01 encerrado:** `.teia_map.json` agora exibe `Verdict: BROTLI_PREFERRED` (antes: `LZMA_PREFERRED`).  
**BUG-02 encerrado:** `.teia_map.json` agora aparece em `HR5_BROTLI` (antes: estava em `LZMA/BROTLI — LLM decide`).

---

## 3. Verificação de Integridade

| Métrica | PRÉ | PÓS | Δ |
|---------|-----|-----|---|
| CAS objects (`objects/*.bin`) | 2369 | **2369** | **0 ✓** |
| Candidatos gravados | 7 | 10 | +3 (esperado) |
| Arquivos originais modificados | — | **0** | **0 ✓** |
| `planner_verdict` correto para brotli | ✗ | **✓** | — |
| Agrupamento HR5 separado no relatório | ✗ | **✓** | — |

---

## 4. Arquivos Produzidos

| Arquivo | Caminho | Ação |
|---------|---------|------|
| Script | `D:\TEIA_CORE\tools\TEIA-NeuroPlanner-v0199.ps1` | Criado (patch sobre v0197) |
| Este relatório | `D:\TEIA_CORE\docs\NEUROPLANNER_PATCH_v0199.md` | Criado |

---

*Patch aplicado em 2026-05-27. CAS intacto. BUG-01 e BUG-02 encerrados.*
