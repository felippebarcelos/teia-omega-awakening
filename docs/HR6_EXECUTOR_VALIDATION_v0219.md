# HR6 Executor — Validação Transacional v0.21.9
**Data:** 2026-05-28
**Protocolo:** P4.9 — Executor HR6 Controlado (C7)
**Versão:** TEIA-HR6-Executor-v0219.ps1
**Feature flag:** `HR6_EXECUTOR_ENABLED` (experimental_flags.json)

---

## 1. Ciclo de Teste da Feature Flag

| Fase | HR6_EXECUTOR_ENABLED | Resultado |
|------|:-------------------:|-----------|
| Pré-teste | `false` | `EXECUTOR BLOQUEADO — HR6_EXECUTOR_ENABLED = false` ✓ |
| Execução | `true` (temporário) | 3/3 EXECUTOR_VALIDATED ✓ |
| Pós-teste | `false` (restaurado) | Flag devolvida ao estado seguro ✓ |

A flag de contenção funcionou corretamente nas duas direções.

---

## 2. Resultados por Candidato

| Arquivo | Primitiva | Algoritmo | Passe 1 SHA-256 | Passe 2 SHA-256 | Delta bytes | Status |
|---------|:---------:|:---------:|:---------------:|:---------------:|:-----------:|:------:|
| `cube_large.obj` | cube | `cube_v1_ccw` | `99a64218...` | `99a64218...` | 0 | **EXECUTOR_VALIDATED** |
| `diamond_offset.obj` | octahedron | `octahedron_v1_ccw` | `8d43e26d...` | `8d43e26d...` | 0 | **EXECUTOR_VALIDATED** |
| `plane_huge.obj` | plane | `plane_v1_ccw` | `5946673b...` | `5946673b...` | 0 | **EXECUTOR_VALIDATED** |

**3/3 EXECUTOR_VALIDATED. Delta bytes = 0 em todos os passes.**

---

## 3. Hashes Canônicos Completos

| Arquivo | canonical_sha256 | Tamanho canônico |
|---------|:----------------:|:----------------:|
| `cube_large.obj` | `99a64218bbcddf2b6a8aa9df4915581e810430e4b1fb16bd14ea2e67e42f68f5` | 460 B |
| `diamond_offset.obj` | `8d43e26d68f12349d48f2bee42bf960b51cec792fb1e73b4dade4fa20bec5918` | 346 B |
| `plane_huge.obj` | `5946673ba63f4ee9c3fa9796ea70edb12553faa3fe6ccff79029a91cb292ed6e` | 236 B |

---

## 4. Cross-Validação com P4.7

Os hashes canônicos de cube_large e plane_huge coincidem com os registrados no benchmark P4.7:

| Arquivo | canonical_sha256 P4.9 | = P4.7? |
|---------|-----------------------|:-------:|
| `cube_large.obj` | `99a64218bbcddf2b...` | ✓ IDÊNTICO |
| `plane_huge.obj` | `5946673ba63f4ee9...` | ✓ IDÊNTICO |
| `diamond_offset.obj` | `8d43e26d68f12349...` | N/A (primitiva criada em P4.8) |

**Invariância confirmada:** o executor v0219 reproduz exatamente os hashes do benchmark v0217.

---

## 5. Escrita Transacional — Anatomia

O padrão `.tmp → verify SHA read-back → rename` foi aplicado em todos os arquivos:

```
1. [System.IO.File]::WriteAllBytes("${path}.tmp", bytes)
2. readBack  = [System.IO.File]::ReadAllBytes("${path}.tmp")
3. actualSha = Get-Sha256Bytes(readBack)
4. if actualSha != expectedSha → Remove-Item ".tmp" (rollback)
5. else → Move-Item ".tmp" → dest (commit)
```

Nenhum rollback foi necessário. Todos os arquivos escritos passaram na verificação SHA.

---

## 6. Artefatos Produzidos no Sandbox

**Localização:** `D:\TEIA_CORE\sandbox\hr6_executor\`

| Artefato | Tamanho | Tipo |
|----------|:-------:|------|
| `cube_large_compact_seed.json` | 491 B | Semente compacta |
| `cube_large_canonical.obj` | 460 B | OBJ canônico reconstituído |
| `diamond_offset_compact_seed.json` | 479 B | Semente compacta |
| `diamond_offset_canonical.obj` | 346 B | OBJ canônico reconstituído |
| `plane_huge_compact_seed.json` | 488 B | Semente compacta |
| `plane_huge_canonical.obj` | 236 B | OBJ canônico reconstituído |
| `hr6_executor_report.json` | 2812 B | Relatório completo P4.9 |

**7 artefatos. Nenhum byte escrito em `D:\TEIA_CORE\objects\` (CAS intacto).**

---

## 7. Extrato do OBJ Canônico — cube_large

```obj
# gen.parametric_mesh canonical output
# primitive: cube | vertices: 8 | faces: 12
g primitive

v 0.000000 0.000000 0.000000
v 0.000000 0.000000 1000.000000
v 0.000000 1000.000000 0.000000
v 0.000000 1000.000000 1000.000000
v 1000.000000 0.000000 0.000000
v 1000.000000 0.000000 1000.000000
v 1000.000000 1000.000000 0.000000
v 1000.000000 1000.000000 1000.000000

f 1 7 5
f 1 3 7
f 1 4 3
f 1 2 4
f 3 8 7
f 3 4 8
f 5 7 8
f 5 8 6
f 1 5 6
f 1 6 2
f 2 6 8
f 2 8 4
```

Escala 1000×1000×1000, AABB (0,0,0)-(1000,1000,1000). Topologia `cube_v1_ccw` aplicada deterministicamente.

---

## 8. Integridade

| Métrica | Valor |
|---------|-------|
| CAS objects Delta bytes | **0** (contenção mantida) |
| Candidatos processados | 3/3 |
| EXECUTOR_VALIDATED | **3** |
| FAILED_SHA_MISMATCH | 0 |
| SKIPPED | 0 |
| Delta bytes entre passes | **0** em todos |
| Cross-validação P4.7 | ✓ 2/2 (diamond_offset N/A) |
| Escrita transacional OK | 3/3 |
| Feature flag restored | ✓ false |
| Tempo total execução | 275 ms |

---

## 9. Critérios C7 — Status Final

| Critério | Status |
|---------|--------|
| C4: HR6 supera LZMA em ≥8/10 | ✓ **10/10** (P4.7) |
| C5: Determinismo SHA-256 100% | ✓ **10/10** (P4.7) |
| C6: Roteamento NeuroPlanner correto | ✓ **5/5** (P4.8) |
| C7: Executor transacional com contenção auditada | ✓ **3/3** (P4.9) |

## ✓ VEREDICTO FINAL: **C7_EXECUTOR_VALIDATED**

O executor gen.parametric_mesh opera deterministicamente, com contenção CAS intacta,
escrita transacional verificada por SHA-256 e feature flag de segurança funcional.
HR6 está pronto para integração controlada na UVM.

---

*Protocolo executado em 2026-05-28. Sandbox: `D:\TEIA_CORE\sandbox\hr6_executor\`. CAS Delta bytes=0.*
