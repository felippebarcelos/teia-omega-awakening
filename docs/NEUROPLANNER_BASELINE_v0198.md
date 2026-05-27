# NEUROPLANNER — Baseline Operacional v0.19.8
**Data:** 2026-05-27  
**Status:** FROZEN — nenhuma funcionalidade nova autorizada sobre esta versão  
**Script canônico:** `TEIA-NeuroPlanner-v0197.ps1`  
**Modelo LLM:** `qwen2.5-coder:7b` (Ollama local)  
**Arquitetura:** Rule-First (HR1–HR5) → LLM opcional para arquivos ≥ 8 KB

---

## 1. Declaração de Fronteira (Inviolável)

> **O Planner analisa; o Watchdog executa. O Planner NUNCA apaga nem escreve no CAS.**

| Componente | Responsabilidade | Proibições |
|------------|-----------------|------------|
| **NeuroPlanner** | Produz `candidate.json` com estratégia e recipe | Nunca toca `objects/`, nunca executa compressão real |
| **UVM/Executor** | Lê `candidate.json`, executa a estratégia, grava no CAS | Não decide estratégia; apenas executa o que o Planner aprovou |
| **LLM (qwen2.5-coder)** | Escolhe entre `cmp.lzma` e `cmp.brotli` para arquivos ≥ 8 KB | Nunca sugere `value_hex`, `size`, `pattern_b64`, ou qualquer parâmetro numérico |

CAS permanece imutável enquanto o Planner opera. A prova é `CAS delta = 0` em toda execução do NeuroPlanner.

---

## 2. Diagrama Lógico Completo

```
┌─────────────────────────────────────────────────────┐
│                      ARQUIVO                        │
└──────────────────────────┬──────────────────────────┘
                           │
          ┌────────────────▼────────────────┐
          │    Get-FileStructuralProfile    │
          │  SHA-256 · tamanho · extensão   │
          └────────────────┬────────────────┘
                           │
          ┌────────────────▼────────────────┐
          │      Get-StructuralMetrics      │
          │  entropy · unique_bytes ·       │
          │  period_bytes · size_bytes ·    │
          │  magic_type · first_byte_hex ·  │
          │  period_hex · strings_sample    │
          └────────────────┬────────────────┘
                           │ métricas numéricas
          ┌────────────────▼────────────────┐
          │      Get-HardRuleDecision       │
          └────────────────┬────────────────┘
                           │
        ┌──────────────────┼──────────────────────┐
        │          │               │              │       │
   unique_bytes=1  period∈(0,512]  entropy≥7.0  magic=zip/gz  size<8192
        │          │               │              │       │
   [HR1]           [HR2]        [HR3]          [HR4]  [HR5]
   gen.repeat   gen.pattern    cas.raw        cas.raw  cmp.brotli
        │          │               │              │       │
        └──────────┴───────────────┴──────────────┴───────┘
                           │ nenhuma regra aplica
          ┌────────────────▼────────────────┐
          │      Invoke-OllamaPlanner       │
          │  "cmp.lzma ou cmp.brotli?"      │
          │  Escopo: entropy∈[2,7),         │
          │  sem período, size≥8192          │
          └────────────────┬────────────────┘
                           │ strategy ∈ {cmp.lzma, cmp.brotli}
          ┌────────────────▼────────────────┐
          │          Build-Recipe           │
          │  Parâmetros 100% de métricas    │
          │  PS — nunca do LLM              │
          └────────────────┬────────────────┘
                           │
          ┌────────────────▼────────────────┐
          │      Test-RecipeIntegrity       │
          │  SHA-256 em memória             │
          │  (gen.repeat / gen.pattern)     │
          └────────────────┬────────────────┘
                           │
          ┌────────────────▼────────────────┐
          │       candidate.json gravado    │
          │  {SHA}.candidate.json           │
          │  Idempotente: re-run = skip     │
          └─────────────────────────────────┘
```

---

## 3. Matriz de Opcodes Autorizados

Apenas os seguintes opcodes são válidos em um `candidate.json` produzido por esta versão:

| Opcode | Estratégia | Acionado Por | Parâmetros Obrigatórios | Parâmetros Proibidos |
|--------|-----------|--------------|------------------------|----------------------|
| `gen.repeat` | Arquivo de byte único | HR1: `unique_bytes == 1` | `value_hex` (de `first_byte_hex`), `size` | nenhum |
| `gen.pattern` | Arquivo periódico | HR2: `period_bytes ∈ (0, 512]` | `pattern_b64` (de `period_hex`), `pattern_hex`, `repeat`, `period_bytes` | nenhum |
| `cas.raw` | Binário incompressível | HR3: `entropy ≥ 7.0` ou HR4: magic comprimido | nenhum (armazena as-is) | nenhum |
| `cmp.brotli` | Texto/JSON pequeno | HR5: `size_bytes < 8192` ou LLM | nenhum | nenhum |
| `cmp.lzma` | Arquivo estatístico ≥ 8 KB | LLM (padrão para ≥ 8 KB) | nenhum | nenhum |

**Qualquer outro opcode retornado pelo LLM é descartado com fallback `cmp.lzma`.**  
O LLM não pode sugerir `gen.repeat`, `gen.pattern`, `cas.raw`, `value_hex`, `size`, `pattern_b64`, `repeat`.

---

## 4. Hard Rules — Tabela de Cobertura

| ID | Condição | Estratégia | Base Empírica | LLM chamado? |
|----|----------|------------|---------------|-------------|
| HR1 | `unique_bytes == 1` | `gen.repeat` | Benchmarks D1–D3 (17/17 wins); corpus_d1.bin SHA-256 PASS | **Não** |
| HR2 | `period_bytes ∈ (0, 512]` | `gen.pattern` | Benchmark D2; corpus_d2.bin SHA-256 PASS | **Não** |
| HR3 | `entropy ≥ 7.0` | `cas.raw` | Benchmark D8 (ZIP/PNG/XZ) | **Não** |
| HR4 | `magic_type ∈ {zip, gzip, xz, bzip2, 7z}` | `cas.raw` | Magic byte detection | **Não** |
| HR5 | `size_bytes < 8192` (após HR1–HR4) | `cmp.brotli` | Auditoria v0.19.6: `.teia_map.json` Brotli 23.1% vs LZMA 28.1% | **Não** |
| — | Nenhuma regra aplica | `cmp.lzma` \| `cmp.brotli` | LLM 4/4 = 100% nos arquivos ≥ 8 KB (v0.19.7) | **Sim** |

**Garantia de HR5:** só alcança HR5 se `entropy∈[2,7)`, sem período, `unique_bytes > 1`, magic não comprimido — ou seja, arquivo genuinamente compressível por algoritmo estatístico, apenas pequeno.

---

## 5. Prova de Auditoria — Rodada Limpa v0.19.8

**Data da rodada:** 2026-05-27  
**Script:** `TEIA-NeuroPlanner-v0197.ps1`  
**Arquivos testados:** corpus_d1.bin, fractal_index.json, .teia_map.json  
**Candidatos deletados antes da rodada** (para garantir re-run completo)

| # | Arquivo | KB | Regra | Estratégia | SHA candidato | Correto? |
|---|---------|-----|-------|-----------|--------------|---------|
| 1 | `corpus_d1.bin` | 256 | **HR1** unique_bytes=1 | `gen.repeat` (value_hex=aa) | `83496bcb...` | ✓ (integrity_proof PASS) |
| 2 | `fractal_index.json` | 1266.6 | **LLM** entropy=5.259 ≥8KB | `cmp.lzma` | `a6746d0d...` | ✓ |
| 3 | `.teia_map.json` | 2.5 | **HR5** size=2549 < 8192 | `cmp.brotli` | `60c4f618...` | ✓ |

### Verificação de Integridade

| Métrica | PRÉ | PÓS | Δ |
|---------|-----|-----|---|
| CAS objects (`objects/*.bin`) | 2369 | **2369** | **0 ✓** |
| Candidatos gravados | 7 | **10** | +3 (esperado) |
| Arquivos originais modificados | — | **0** | **0 ✓** |
| LLM calls | — | **1** (fractal_index.json) | HR1+HR5 sem rede |
| Candidate overflow (>512KB) | — | **0** | ✓ (strings_sample cap) |

**Resultado: 3/3 OK — CAS intacto — zero overflow.**

---

## 6. Métricas de Evolução Histórica

| Versão | Acertos | LLM Calls | Tempo | Inovação |
|--------|---------|-----------|-------|---------|
| v0.19.3 | ~50% | 2 | 107.9s | Piloto inicial — alucinação total de parâmetros |
| v0.19.4 | 2/2 D1+D2 | 2 | 107.9s | Separação LLM (strategy) vs PS (params) |
| v0.19.5 | 2/2 synth | 0 | 1.8s | HR1–HR4 Rule-First; Test-RecipeIntegrity |
| v0.19.6 | 5/6 reais | 6 | 165.0s | Auditoria zona ambígua; descoberta do gap HR5 |
| v0.19.7 | **6/6 (100%)** | **4 (−33%)** | **132.2s (−20%)** | HR5 size<8KB→brotli |
| v0.19.8 | — | — | — | **FREEZE** — baseline documental |

---

## 7. Bugs Conhecidos (Congelados — Não Corrigir nesta Versão)

| ID | Bug | Impacto | Localização |
|----|-----|---------|------------|
| BUG-01 | `Get-PlannerVerdict`: `cmp.brotli` mapeia para `'LZMA_PREFERRED'` (label errado) | Cosmético — apenas o campo `planner_verdict` no JSON é afetado; a `final_strategy` está correta | `TEIA-NeuroPlanner-v0197.ps1`, linha ~371 |
| BUG-02 | Relatório final agrupa arquivos HR5 sob "LZMA/BROTLI — LLM decide" em vez de "Hard Rule HR5" | Cosmético — contagem OK e SK corretos | `TEIA-NeuroPlanner-v0197.ps1`, linhas ~619–622 |

Estes bugs não afetam a correção das decisões nem a integridade do CAS. Serão corrigidos em v0.19.9 quando o freeze for levantado.

---

## 8. Invariantes de Execução (Contrato de Uso)

```powershell
# Pré-condições obrigatórias
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-Location "D:\TEIA_CORE"  # ou raiz absoluta

# Execução padrão
.\tools\TEIA-NeuroPlanner-v0197.ps1 -Files "path\ao\arquivo1", "path\ao\arquivo2"

# Modo dry-run (sem gravação de candidatos)
.\tools\TEIA-NeuroPlanner-v0197.ps1 -Files "path\ao\arquivo" -DryRun

# Verificação pós-run
# CAS deve permanecer inalterado — qualquer delta > 0 é anomalia
(Get-ChildItem "D:\TEIA_CORE\objects\*.bin").Count  # deve ser idêntico ao pré-run
```

**Idempotência garantida:** se `{sha256}.candidate.json` já existe, o arquivo é pulado silenciosamente. Re-run seguro em qualquer momento.

---

## 9. Arquivos do Ecossistema v0.19.7

| Artefato | Caminho Canônico | Função |
|----------|-----------------|--------|
| Script principal | `D:\TEIA_CORE\tools\TEIA-NeuroPlanner-v0197.ps1` | Motor Rule-First + LLM router |
| Prompt LLM | `D:\TEIA_CORE\config\neuroplanner_prompt_v0197.md` | Escopo restrito: lzma vs brotli para ≥8KB |
| Candidatos | `D:\TEIA_CORE\neuroplanner\candidates\{sha256}.candidate.json` | Output do Planner |
| Relatório HR5 | `D:\TEIA_CORE\docs\NEUROPLANNER_HR5_SMALLFILES_v0197.md` | Auditoria comparativa v0.19.6 vs v0.19.7 |
| Relatório zona ambígua | `D:\TEIA_CORE\docs\NEUROPLANNER_AMBIGUOUS_ZONE_v0196.md` | Benchmark LZMA vs Brotli 6 arquivos reais |
| Relatório rule-first | `D:\TEIA_CORE\docs\NEUROPLANNER_ROUTER_v0195.md` | Prova SHA-256 HR1+HR2 em memória |
| **Este documento** | `D:\TEIA_CORE\docs\NEUROPLANNER_BASELINE_v0198.md` | Estado da Arte congelado |

---

## 10. Conclusão

A arquitetura Rule-First v0.19.7 representa o ponto de maturidade operacional do NeuroPlanner:

1. **Alucinações estruturalmente impossíveis para HR1–HR5**: parâmetros críticos (`value_hex`, `size`, `pattern_b64`) são extraídos deterministicamente das métricas do arquivo — nunca do LLM.

2. **LLM confinado ao domínio de baixo risco**: escolha entre dois algoritmos de compressão estatística para arquivos ≥ 8 KB sem período. Erro máximo possível: ~2–5pp de taxa de compressão pior, não corrupção de dados.

3. **CAS inviolável**: zero writes no `objects/` durante qualquer execução do Planner. Prova auditada em todas as versões.

4. **100% de acurácia no dataset de validação**: 6/6 arquivos reais TEIA com decisão correta em v0.19.7.

> A "arquitetura mágica" foi substituída pela "engenharia confiável."  
> O LLM é um consultor, não o CEO — se o Manual de Regras resolve, o LLM nem abre a boca.

---

*Baseline congelado em 2026-05-27. CAS intacto (2369 objects). Próxima versão: v0.19.9 (levantamento do freeze).*
