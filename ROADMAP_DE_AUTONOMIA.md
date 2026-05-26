# ROADMAP DE AUTONOMIA — TEIA-Ω
**Última atualização:** 2026-05-26
**Versão do ecossistema:** v0.13.1

---

## STATUS GERAL: WATCHDOG ATIVADO (Sincronização Agendada)

---

## CAMADAS DE AUTONOMIA

| Camada | Componente | Status | Versão |
|--------|-----------|--------|--------|
| **L0 — Identidade** | SHA-256 como tronco canônico | ✅ Estável | — |
| **L1 — Armazenamento** | CAS (`D:\TEIA_CORE\objects\`) | ✅ Hidratado | 2363 objetos |
| **L2 — Índice** | `fractal_index.json` | ✅ Canônico | 2363 entradas |
| **L3 — Ingestão** | `TEIA-Sync-Watchdog.ps1` | ✅ **Agendado** | v0.13.1 |
| **L4 — Agendamento** | Task Scheduler `TEIA-Sync-Watchdog-v0131` | ✅ Ativo | 10 min/ciclo |
| **L5 — Observabilidade** | `TEIA_HUD.ps1` + `dna_events.jsonl` | ✅ Operacional | v0.13.0 |
| **L6 — Resiliência** | Singleton lock + escrita atômica | ✅ Implementado | v0.13.1 |
| **L7 — Autolimpeza** | `Limpar-Temporarios.ps1` | ✅ Disponível | limiar 10 GB |
| **L8 — Volume X:\\** | WinFsp driver (Prova "Choque Real") | 🔲 Pendente | — |
| **L9 — Ciclo TCT Autônomo** | símbolo+plano+bundle+prova | 🔲 Pendente | — |

---

## MARCOS CONCLUÍDOS

### v0.13.1 — Blindagem de I/O do Watchdog ✅
- **Escrita atômica:** `Set-IndexAtomic` (tmp → verificação → bak → rename)
- **Singleton lock:** `watchdog.lock` com PID, detecção de órfão, `finally` garantido
- **Reconciliação:** `-ReconcileOnly` para sync CAS físico ↔ índice JSON
- **Resultado de validação:** `Novos ingeridos: 0 | Falhas: 0 | Ignorados: 4626 | 14.8s`
- **Commit:** `76d7e17`

### v0.13.0 — Estabilização CAS + Watchdog + HUD ✅
- CAS hidratado com 2363 objetos verificados
- Watchdog polling (sem FileSystemWatcher instável)
- HUD com leitura em tempo real do `dna_events.jsonl`
- Commit: `3844007`

### v0.11.0 — Dossiê técnico + guia de validação ✅
- Pacote de prova consolidado
- Golden Master `v0.11.0` gerado e assinado
- Commit: `541315f`

---

## PENDÊNCIAS ATIVAS (ordem de prioridade)

### P1 — Reparar `TEIA-Fractal-Gen.ps1` 🔴 Alta
**O quê:** Reescrita cirúrgica limpa do gerador fractal.
**Critério de done:** Ciclo completo Manifesto → Geração → Hash → Recuperação sem erros.
**Bloqueado por:** Nada — pode iniciar.

### P2 — Prova "Choque Real" em X:\\ 🔴 Alta
**O quê:** Executar binário portátil leve a partir do volume WinFsp.
**Ciclo:** Leitura → Interceptação → Restauro → Execução.
**Bloqueado por:** WinFsp `Running` + Guardião do driver estável.

### P3 — Fechar ciclo TCT autônomo 🟡 Média
**O quê:** Cada pergunta TCT gera símbolo + plano + bundle + prova no ProofKit.
**Critério de done:** `WD_TCT_CYCLE_OK` no `dna_events.jsonl`.
**Bloqueado por:** P1 (geração fractal).

### P4 — Consolidar SHA-256 cross-layer 🟡 Média
**O quê:** Eliminar duplicação `utils.py` / `integrity.py`; alinhar com PowerShell.
**Critério de done:** Uma única fonte canônica por camada, testes cross-layer passando.
**Bloqueado por:** Nada.

### P5 — Prova P1 (pasta grande: fotos/vídeos/software) 🟡 Média
**O quê:** Fractalizar → apagar → restaurar on-demand → métricas em PROVAS_E_METRICAS.
**Bloqueado por:** P1.

### P6 — Analytics v2 com dados reais 🟢 Baixa
**O quê:** `TEIA-Fractal-Analytics.v2.ps1` sobre logs P0 existentes.
**Critério de done:** `summary.json` + HTML com pontos reais congelados.
**Bloqueado por:** Nada (dados P0 já existem).

### P7 — Porta Fortnite 🔵 Diferida
**Condição de abertura:** StableLine + Guardião do driver WinFsp prontos (P2 done).

---

## INFRAESTRUTURA DE AUTONOMIA — DETALHE

### Ciclo de Sincronização (L3-L4)

```
Task Scheduler (a cada 10 min)
    └─► pwsh.exe -WindowStyle Hidden
            └─► TEIA-Sync-Watchdog.ps1 -UmaVez
                    ├─ Acquire Lock (watchdog.lock + PID)
                    ├─ Get-CASHashes ← fractal_index.json
                    ├─ Get-OrfaoLookup ← D:\bruto\TEIA\fractal_index.json
                    ├─ Scan $Monitoradas (4 pastas)
                    ├─ Per file: size-filter → hash → CAS-check → Ingest
                    │       └─ Invoke-IngestFile → Set-IndexAtomic (atômico)
                    ├─ Write dna_events.jsonl (append)
                    └─ Release Lock (finally)
```

### Pipeline de Observabilidade (L5)

```
dna_events.jsonl (append-only JSONL)
    └─► TEIA_HUD.ps1 (Get-Content -Tail N)
            └─► Exibe últimos 6 eventos + métricas CAS + espaço em disco
```

### Autolimpeza (L7)

```
Limpar-Temporarios.ps1
    ├─ Gatilho: D: livre < 10 GB  (ou -Forcar)
    ├─ Alvos: _bench_v*/tmp/ (178 MB em _bench_v6/tmp identificados)
    └─ Logs: *.log/*.tmp/*.bak com > 30 dias em logs/
```

---

## MÉTRICAS DE SAÚDE ATUAIS

| Métrica | Valor | Status |
|---------|-------|--------|
| Objetos CAS | 2363 | ✅ |
| Entradas no índice | 2363 | ✅ (0 órfãos) |
| Divergências SHA-256 | 0 | ✅ |
| Espaço livre D: | ~158 GB | ✅ |
| Último ciclo Watchdog | 2026-05-25 22:05:00 | ✅ |
| Lock após execução | Removido | ✅ |
| Tamanho `_bench_v6/tmp` | 178 MB | ⚠️ Candidato à limpeza |

---

*Este roadmap é atualizado a cada ciclo de cristalização. Próxima revisão após P1 ou P2.*
