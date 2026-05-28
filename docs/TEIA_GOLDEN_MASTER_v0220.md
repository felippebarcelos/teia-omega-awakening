# TEIA Architecture — Golden Master v0.22.0
**Data:** 2026-05-28
**Protocolo:** P4.10 — Checkpoint Golden Master (Fim da Fase P4)
**Selagem:** Fase experimental NeuroPlanner + Motor Ontoprocedural concluída

---

## 1. Declaração de Estado

A Fase P4 do projeto TEIA-Ω está **oficialmente concluída e selada**.

Todos os critérios de validação da Hard Rule 6 foram cumpridos:

| Critério | Protocolo | Resultado |
|:--------:|:---------:|:---------:|
| C4: HR6 supera LZMA em ≥8/10 primitivos | P4.7 | ✓ **10/10** |
| C5: Determinismo SHA-256 100% | P4.7 | ✓ **10/10** |
| C6: Roteamento NeuroPlanner correto | P4.8 | ✓ **5/5** |
| C7: Executor transacional com contenção auditada | P4.9 | ✓ **3/3** |

**CAS Delta Permanente = 0.** Nenhum byte foi escrito em `D:\TEIA_CORE\objects\` durante toda a Fase P4.

---

## 2. Topologia do Motor — Arquitetura Final

```
┌───────────────────────────────────────────────────────────────────────┐
│                          TEIA-Ω MOTOR v0.22.0                         │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  CAMADA 1 — WATCHDOG PASSIVO                                    │  │
│  │  TEIA-Watchdog-Passive-v0200.ps1                                │  │
│  │                                                                 │  │
│  │  Ingestão não intrusiva via telemetria JSONL.                   │  │
│  │  Observa o filesystem sem alterar arquivos.                     │  │
│  │  Alimenta o NeuroPlanner com eventos de arquivo.                │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                              │                                        │
│                              ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  CAMADA 2 — NEUROPLANNER RULE-FIRST v0.21.8                     │  │
│  │  TEIA-NeuroPlanner-v0218.ps1                                    │  │
│  │                                                                 │  │
│  │  Árvore de decisão determinística (matemática antes da IA):     │  │
│  │                                                                 │  │
│  │  HR1: unique_bytes == 1           → gen.repeat                  │  │
│  │  HR2: period_bytes ∈ (0,512]      → gen.pattern                 │  │
│  │  HR3: entropy >= 7.0              → cas.raw                     │  │
│  │  HR4: magic em comprimidos        → cas.raw                     │  │
│  │  HR6: model/obj, size<4096, v<20  → gen.parametric_mesh ★       │  │
│  │  HR5: size_bytes < 8192           → cmp.brotli                  │  │
│  │  LLM: nenhuma regra               → cmp.lzma / cmp.brotli       │  │
│  │                                                                 │  │
│  │  ★ HR6 é candidate_only até HR6_EXECUTOR_ENABLED=true           │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                              │                                        │
│                              ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  CAMADA 3 — MOTOR ONTOPROCEDURAL (UVM)                          │  │
│  │  HR6-ParametricMesh-Prototype-v0216.ps1                         │  │
│  │  TEIA-HR6-Executor-v0219.ps1                                    │  │
│  │                                                                 │  │
│  │  Estratégias com algoritmos registrados e validados:            │  │
│  │                                                                 │  │
│  │  gen.repeat          — arquivo monocromo (1 byte único)         │  │
│  │  gen.pattern         — arquivo periódico (period ≤ 512B)        │  │
│  │  gen.parametric_mesh — primitiva 3D (cube/plane/octahedron)     │  │
│  │    ├─ cube_v1_ccw       : AABB(min,max) → 8v 12f               │  │
│  │    ├─ plane_v1_ccw      : AABB(min,max) → 4v  2f               │  │
│  │    └─ octahedron_v1_ccw : (center,r)    → 6v  8f               │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                              │                                        │
│                              ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  CAMADA 4 — COMPRESSÃO ESTATÍSTICA & FALLBACK                   │  │
│  │                                                                 │  │
│  │  cmp.lzma   — LZMA preset=9 (orgânicos complexos, LLM-default) │  │
│  │  cmp.brotli — Brotli quality=11 (arquivos pequenos, HR5)        │  │
│  │  cas.raw    — Armazenamento direto (alta entropia / binários)   │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                              │                                        │
│                              ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  CONTENÇÃO — FEATURE FLAG DE SEGURANÇA                          │  │
│  │  D:\TEIA_CORE\config\experimental_flags.json                    │  │
│  │                                                                 │  │
│  │  { "HR6_EXECUTOR_ENABLED": false }  ← estado selado            │  │
│  │                                                                 │  │
│  │  Bloqueio explícito: executor não corre sem aprovação manual.   │  │
│  │  Auditável, reversível, versionado no git.                      │  │
│  └─────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘
```

---

## 3. Registro de Versões — Fase P4

| Versão | Protocolo | Marco |
|--------|:---------:|-------|
| v0.21.4 | — | Especificação formal HR6 `gen.parametric_mesh` |
| v0.21.5 | P4.5 | Protótipo isolado HR6, semente explícita, cross-dataset P4.5 |
| v0.21.6 | P4.6 | Semente compacta paramétrica (AABB + center/radius) |
| v0.21.7 | P4.7 | Benchmark HR6 vs LZMA9/Brotli11 — **10/10 HR6 wins** |
| v0.21.8 | P4.8 | HR6 integrada no NeuroPlanner como `candidate_only` |
| v0.21.9 | P4.9 | Executor transacional + feature flag — **C7 validado** |
| **v0.22.0** | **P4.10** | **Golden Master selado — Fase P4 concluída** |

---

## 4. Hashes Canônicos — Tabela Permanente

Estes hashes são invariantes matemáticos dos algoritmos `*_v1_ccw`.
Qualquer futura implementação que divergir destes valores indica regressão.

| Primitiva | Parâmetros | canonical_sha256 | Validado |
|-----------|-----------|:----------------:|:--------:|
| cube unit | AABB (0,0,0)-(1,1,1) | `4df640cbd857edca7af093886a3ffa7c74d5fb19091e3e13365124ec53a50fa3` | P4.5 + P4.7 |
| plane unit | AABB (0,0,0)-(1,0,1) | `60dfe60faf0e9daec18eaf6c2187daea8c1f69f8fcdbcdc22822c701384ef8fa` | P4.5 + P4.7 |
| diamond unit | center (0,0,0) r=1 | `aa93b202c8bfc31765c9e1a667dce25ae6907cccd77ecea8b1b4655f9c7437bc` | P4.5 + P4.7 |
| cube large | AABB (0,0,0)-(1000,1000,1000) | `99a64218bbcddf2b6a8aa9df4915581e810430e4b1fb16bd14ea2e67e42f68f5` | P4.7 + P4.9 |
| plane huge | AABB (0,0,0)-(100,0,100) | `5946673ba63f4ee9c3fa9796ea70edb12553faa3fe6ccff79029a91cb292ed6e` | P4.7 + P4.9 |
| diamond offset | center (2.5,-1,0.333) r=0.75 | `8d43e26d68f12349d48f2bee42bf960b51cec792fb1e73b4dade4fa20bec5918` | P4.9 |

**Axioma de invariância:** O canonical_sha256 depende exclusivamente dos parâmetros geométricos e do algoritmo `*_v1_ccw`. Formato de entrada (normals, UVs, vertex order, BOM) é irrelevante.

---

## 5. Economia de Bytes — HR6 vs Compressão Clássica

| Primitiva | Original | HR6 Pure Payload | LZMA9 | Economia vs LZMA |
|-----------|:--------:|:----------------:|:-----:|:----------------:|
| cube (média 4 arquivos) | 712 B | **172 B** | 283 B | +39.3% |
| plane (média 3 arquivos) | 456 B | **170 B** | 267 B | +36.3% |
| octahedron (média 3 arquivos) | 422 B | **161 B** | 260 B | +38.0% |

**Princípio:** Identidade geométrica (seed paramétrica) supera compressão por dicionário em primitivas determinísticas.

---

## 6. CAS — Auditoria de Contenção

| Protocolo | Bytes escritos em `objects/` | Status |
|:---------:|:----------------------------:|:------:|
| P4.5 | 0 | ✓ INTACTO |
| P4.6 | 0 | ✓ INTACTO |
| P4.7 | 0 | ✓ INTACTO |
| P4.8 | 0 | ✓ INTACTO |
| P4.9 | 0 | ✓ INTACTO |
| **P4.10** | **0** | **✓ INTACTO** |

**CAS Delta Permanente = 0.** A contenção foi mantida em todos os protocolos da Fase P4.
O Motor Ontoprocedural opera exclusivamente no sandbox. O CAS permanece inalterado.

---

## 7. Artefatos Ativos — Inventário Final

### Scripts de Produção
| Artefato | Localização | Função |
|----------|-------------|--------|
| `TEIA-NeuroPlanner-v0218.ps1` | `tools/` | Roteador Rule-First com HR6 candidate_only |
| `HR6-ParametricMesh-Prototype-v0216.ps1` | `tools/` | Encoder/Decoder core (funções canônicas) |
| `TEIA-HR6-Executor-v0219.ps1` | `tools/` | Executor transacional com feature flag |
| `Generate-StressDataset-P47.ps1` | `tools/` | Gerador de primitivos stress-test |

### Configuração
| Artefato | Localização | Estado |
|----------|-------------|--------|
| `experimental_flags.json` | `config/` | `HR6_EXECUTOR_ENABLED: false` (selado) |
| `neuroplanner_prompt_v0197.md` | `config/` | Prompt canônico LLM v0.19.7 |

### Documentação
| Artefato | Localização | Conteúdo |
|----------|-------------|----------|
| `HR6_VS_LZMA_BENCHMARK_v0217.md` | `docs/` | Benchmark P4.7 — 10/10 HR6 wins |
| `HR6_NEUROPLANNER_INTEGRATION_v0218.md` | `docs/` | Integração HR6 no NeuroPlanner P4.8 |
| `HR6_EXECUTOR_VALIDATION_v0219.md` | `docs/` | Validação executor C7 P4.9 |
| `TEIA_GOLDEN_MASTER_v0220.md` | `docs/` | Este documento — Golden Master P4.10 |

### Sandbox P4.9 (executor validado)
| Artefato | SHA-256 canônico |
|----------|:----------------:|
| `cube_large_canonical.obj` | `99a64218...` |
| `diamond_offset_canonical.obj` | `8d43e26d...` |
| `plane_huge_canonical.obj` | `5946673b...` |

---

## 8. O Que Não É

| Ilusão | Realidade confirmada nesta fase |
|--------|----------------------------------|
| "HR6 codifica qualquer malha 3D" | HR6 codifica apenas primitivas com algoritmo registrado (cube/plane/octahedron) |
| "O CAS está integrado ao executor" | O executor opera exclusivamente no sandbox — CAS permanece read-only |
| "A feature flag é provisória" | A feature flag é um componente permanente de segurança — não um andaime |
| "LZMA/Brotli são obsoletos" | LZMA/Brotli são o fallback correto para orgânicos (cessna, teapot, magnolia) |

---

## 9. Diretivas para P5

A Fase P4 prova que o Motor Ontoprocedural é viável e seguro. A Fase P5 deve endereçar:

1. **Integração UVM completa** — promover `HR6_EXECUTOR_ENABLED=true` em ambiente controlado com auditoria end-to-end
2. **Novos primitivos** — registrar algoritmos para `pyramid`, `sphere_uv`, `torus` quando necessário
3. **Prova P1 (pasta grande)** — fractalizar → apagar → restaurar on-demand com métricas em `PROVAS_E_METRICAS`
4. **Fechar ciclo TCT autônomo** — cada pergunta TCT gera símbolo + plano + bundle + prova no ProofKit
5. **Analytics v2 com dados reais** — validar `TEIA-Fractal-Analytics.v2.ps1` sobre logs P0 existentes

---

*Golden Master selado em 2026-05-28. Sandbox: `D:\TEIA_CORE\sandbox\hr6_executor\`. CAS Delta Permanente = 0.*
