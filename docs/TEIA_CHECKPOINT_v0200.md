# TEIA — Checkpoint v0.20.0
**Data:** 2026-05-27  
**Commit canônico:** `93932b6`  
**Branch:** `master` — sincronizado com `origin/master`

---

## Estado do Sistema

| Componente | Status | Versão |
|-----------|--------|--------|
| NeuroPlanner (Motor Seletor) | **Operacional** | v0.19.9 |
| Watchdog Passivo (Sentinela) | **Operacional** | v0.20.0 |
| Watchdog Report (Telemetria) | **Operacional** | v0.20.0 |
| CAS (Content-Addressable Storage) | **Imutável** | 2369 objects |
| Candidates gerados | 21 | — |
| Log de sessões Watchdog | 17 entradas JSONL | — |

---

## CAS — Delta Zero Garantido

O CAS permanece imutável e seguro desde o início do projeto.

```
D:\TEIA_CORE\objects\  →  2369 objetos  |  Delta acumulado = 0
```

Nenhum byte foi escrito no CAS durante todas as execuções do NeuroPlanner ou do Watchdog. O princípio é estrutural: o Planner **analisa e propõe**; o Executor (UVM, ainda não conectado) **decide e grava**. Sem o Executor ativo, o CAS não cresce.

---

## Arquitetura Rule-First — Linha do Tempo

| Marco | Versão | Inovação |
|-------|--------|---------|
| Piloto LLM puro | v0.19.0–v0.19.3 | Prova de conceito; alucinação de parâmetros |
| Separação de agência | v0.19.4 | LLM → strategy; PS → parâmetros reais |
| Motor Seletor Determinístico | v0.19.5 | HR1–HR4 antes do LLM; prova SHA-256 em memória |
| Auditoria zona ambígua | v0.19.6 | Benchmark real LZMA vs Brotli; descoberta do gap HR5 |
| Hard Rule HR5 | v0.19.7 | size < 8 KB → cmp.brotli; 6/6 corretos (100%) |
| Baseline congelado | v0.19.8 | Freeze; documentação do estado da arte |
| Patch cosmético | v0.19.9 | BUG-01 (label BROTLI_PREFERRED) + BUG-02 (agrupamento HR5) |
| **Watchdog Passivo** | **v0.20.0** | **Sentinela autônomo + relatório de economia** |

---

## Watchdog Passivo — Arquitetura

```
D:\TEIA_USER\Inbox\  (ou qualquer WatchDir)
         │
         ▼
 TEIA-Watchdog-Passive-v0200.ps1
         │
         ├─ SHA-256 pre-check ─► candidate existe? ─► SKIP (log: skipped)
         │
         └─ arquivo novo ─► NeuroPlanner v0199 ──► HR1-HR5 ──► candidate.json
                                                 └──► LLM    └──► log: candidate_generated
                                                              └──► watchdog_passive.jsonl
```

**Contrato absoluto:** nenhuma escrita em `objects/`. O Watchdog é um observador que gera receitas — não um executor.

---

## Métricas de Economia (21 Candidates — Heurísticas)

| Estratégia | Arquivos | Original | Comprimido (est.) | Economia |
|-----------|---------|---------|------------------|---------|
| `cas.raw` | 2 | 3.90 MB | 3.90 MB | 0% |
| `cmp.lzma` | 8 | 3.03 MB | 0.85 MB | ~72% |
| `cmp.brotli` | 7 | 0.02 MB | 0.01 MB | ~65% |
| `gen.pattern` | 1 | 0.25 MB | ~0.0005 MB | ~99.5% |
| `gen.repeat` | 1 | 0.25 MB | ~0.00003 MB | ~99.9% |
| **TOTAL** | **21** | **7.44 MB** | **~4.76 MB** | **~36%** |

Economia estimada de **~2.69 MB** (36.1%) caso o Executor fosse ativado hoje.

---

## Extensibilidade — Hard Rules Futuras (HR6+)

O Motor Ontoprocedural está pronto para receber novas Hard Rules sem modificar a lógica de LLM ou o Executor. O ponto de inserção é `Get-HardRuleDecision` em `TEIA-NeuroPlanner-v0199.ps1`, antes do bloco `llm_needed`.

Candidatos naturais para HR6+ a serem descobertos via análise semântica de IA:

| ID | Hipótese | Sinal | Estratégia candidata |
|----|---------|-------|---------------------|
| HR6 | Arquivos XML/HTML pequenos | `structure_type == 'xml' AND size < 16KB` | `cmp.brotli` (dicionário HTML) |
| HR7 | Binários PE/EXE | `magic_type == 'application/pe'` | `cas.raw` (código já linkado) |
| HR8 | Áudio WAV PCM não comprimido | `magic_type == 'audio/wav' AND entropy < 6.0` | `cmp.lzma` (PCM tem padrões) |
| HR9 | Padrão periódico longo (> 512B) | `period_bytes ∈ (512, 4096]` | `gen.pattern` (extensão de HR2) |

**Critério de promoção para Hard Rule:** evidência empírica em ≥ 3 arquivos reais com margem > 2pp sobre a alternativa. O LLM permanece como fallback enquanto a evidência é insuficiente.

---

## Arquivos do Ecossistema v0.20.0

| Artefato | Caminho Canônico |
|----------|-----------------|
| NeuroPlanner | `D:\TEIA_CORE\tools\TEIA-NeuroPlanner-v0199.ps1` |
| Watchdog Passivo | `D:\TEIA_CORE\tools\TEIA-Watchdog-Passive-v0200.ps1` |
| Watchdog Report | `D:\TEIA_CORE\tools\TEIA-Watchdog-Report.ps1` |
| Prompt LLM | `D:\TEIA_CORE\config\neuroplanner_prompt_v0197.md` |
| Baseline v0.19.8 | `D:\TEIA_CORE\docs\NEUROPLANNER_BASELINE_v0198.md` |
| Log Watchdog | `D:\TEIA_CORE\logs\watchdog_passive.jsonl` |
| Candidates | `D:\TEIA_CORE\neuroplanner\candidates\{sha256}.candidate.json` |

---

## Próxima Fase — P3 (Executor)

Quando o operador confirmar que os 21 candidates têm `final_strategy` correto:

1. Conectar o **Executor UVM** ao Watchdog: ler candidates com `integrity_proof.pass == true` ou `verifiable == false`
2. Executar a compressão real (`cmp.lzma`, `cmp.brotli`, `cas.raw`, `gen.*`)
3. Gravar o resultado no CAS (`D:\TEIA_CORE\objects\{sha256_comprimido}.bin`)
4. Apenas neste ponto o CAS crescerá com objetos reais comprimidos

---

*Checkpoint registrado em 2026-05-27. CAS=2369. Candidates=21. Remote: `origin/master` @ `93932b6`.*
