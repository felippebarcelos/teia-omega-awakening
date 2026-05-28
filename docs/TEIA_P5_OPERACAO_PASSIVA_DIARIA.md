# TEIA — Manual do Operador: Operação Passiva Diária
**Versão:** v0.22.3
**Protocolo:** P5.3
**Script de rotina:** `TEIA-Run-PassiveDaily.ps1`

---

## O Que Este Sistema Faz

Uma vez por dia — ou quando você quiser — você executa um único script. Ele varre sua pasta de entrada (`D:\TEIA_USER\Inbox`), analisa cada arquivo com o motor de regras da TEIA e imprime um relatório mostrando **quanto espaço você economizaria** se comprimisse ou recodificasse esse acervo.

Nenhum arquivo é movido, apagado ou alterado. Nenhum dado é enviado para fora da máquina. O resultado é um diagnóstico — não uma transformação.

---

## Como Executar

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
& 'D:\TEIA_CORE\tools\TEIA-Run-PassiveDaily.ps1'
```

Ou com diretório customizado:

```powershell
& 'D:\TEIA_CORE\tools\TEIA-Run-PassiveDaily.ps1' -InboxDir 'D:\SeuDiretorio'
```

---

## O Que Acontece Internamente

```
TEIA-Run-PassiveDaily.ps1
  │
  ├─ 1. TEIA-Watchdog-Passive-v0200.ps1 (silencioso)
  │      Para cada arquivo novo em D:\TEIA_USER\Inbox:
  │        ├─ Calcula SHA-256 (identidade)
  │        ├─ Perfil estrutural (entropia, magic type, tamanho)
  │        └─ TEIA-NeuroPlanner-v0218.ps1 decide a estratégia:
  │             HR1 → gen.repeat         (arquivo monocromo)
  │             HR2 → gen.pattern        (arquivo periódico)
  │             HR3 → cas.raw            (entropia ≥ 7.0)
  │             HR4 → cas.raw            (formato já comprimido)
  │             HR6 → gen.parametric_mesh (primitiva 3D OBJ)
  │             HR5 → cmp.brotli         (arquivo < 8 KB)
  │             LLM → cmp.lzma / brotli  (decisão semântica)
  │        Grava .candidate.json em D:\TEIA_CORE\neuroplanner\candidates\
  │
  ├─ 2. TEIA-Watchdog-Report.ps1 -ShowFiles (visível no console)
  │      Lê todos os .candidate.json acumulados
  │      Imprime tabela de distribuição de estratégias e economia estimada
  │
  └─ 3. Grava linha de log em D:\TEIA_CORE\logs\passive_daily.log
         Formato: data | novos | skip | fail | tempo | economia
```

---

## Como Ler o Relatório

```
 Estratégia        Arqs  Orig(MB)  Comp(MB)  Economia  Razão×
 ──────────────── ──── ──────── ──────── ──────── ───────
 cas.raw             8     45.2     45.2       0%      1×   ← já comprimidos
 cmp.lzma           22     12.1      3.4     ~72%    3.6×   ← texto/código
 cmp.brotli          5      0.03     0.01    ~65%    2.9×   ← arquivos pequenos
 gen.parametric_mesh 3     0.001    0.0002   ~79%    4.8×   ← primitivas 3D
 gen.pattern         1      0.25     0.001   ~99.5%  200×   ← arquivo periódico
 gen.repeat          1      0.25     0.0002  ~99.9%  1000×  ← arquivo monocromo
 TOTAL              40     57.8     48.6     15.9%   1.2×
```

| Campo | Significado |
|-------|-------------|
| **Estratégia** | Algoritmo que o motor escolheria para este grupo |
| **Arqs** | Quantidade de arquivos no grupo |
| **Orig (MB)** | Tamanho total original no disco |
| **Comp (MB)** | Tamanho estimado após compressão/recodificação |
| **Economia** | Percentual eliminado (heurística baseada em benchmarks reais) |
| **Razão×** | Fator de redução (3.6× = arquivo ocupa 1/3.6 do original) |

**`cas.raw` mostra 0%** porque os arquivos já são comprimidos internamente (JPEG, PDF, ZIP). Re-comprimir seria contra-produtivo — o motor reconhece isso e não tenta.

**A linha TOTAL** mostra a economia global do acervo. Arquivos `cas.raw` grandes (imagens, vídeos) arrastam a porcentagem para baixo — isso é correto.

---

## A Regra de Ouro: CAS Delta = 0

```
┌─────────────────────────────────────────────────────────┐
│  D:\TEIA_CORE\objects\   ←  JAMAIS TOCADO               │
│                                                         │
│  Este script é SOMENTE LEITURA sobre seus arquivos.     │
│  Nenhum byte é escrito no CAS durante a operação        │
│  passiva. O acervo original permanece intacto.          │
│                                                         │
│  Os únicos arquivos criados são:                        │
│    • .candidate.json  (metadados de roteamento)         │
│    • passive_daily.log (linha de log por execução)      │
└─────────────────────────────────────────────────────────┘
```

Os arquivos `.candidate.json` **não** são cópias do conteúdo — apenas registros da decisão de roteamento (estratégia, entropia, SHA-256). Eles ocupam ~2–4 KB cada independentemente do tamanho do arquivo original.

---

## Arquivos Já Vistos (Skip)

Se você rodar o script duas vezes no mesmo dia, os arquivos já analisados são ignorados via SHA-256. O motor não reprocessa um arquivo cujo hash já tem `.candidate.json`. Isso garante idempotência total — rodar N vezes produz o mesmo resultado que rodar uma vez.

---

## Log Diário

Cada execução acrescenta uma linha ao log em `D:\TEIA_CORE\logs\passive_daily.log`:

```
2026-05-28 17:15:32 | novos=5 skip=14 fail=0 tempo=45s | economia=4.95MB (35.3%) | inbox=D:\TEIA_USER\Inbox
2026-05-29 08:02:11 | novos=3 skip=17 fail=0 tempo=28s | economia=5.12MB (36.1%) | inbox=D:\TEIA_USER\Inbox
```

Use este log para acompanhar o crescimento do acervo e a evolução da economia estimada ao longo do tempo.

---

## Parâmetros Disponíveis

| Parâmetro | Padrão | Descrição |
|-----------|--------|-----------|
| `-InboxDir` | `D:\TEIA_USER\Inbox` | Diretório a analisar |
| `-PlannerScript` | `TEIA-NeuroPlanner-v0218.ps1` | Motor de roteamento |
| `-DailyLog` | `D:\TEIA_CORE\logs\passive_daily.log` | Arquivo de log acumulado |

---

## Arquitetura de Dependências

```
TEIA-Run-PassiveDaily.ps1
  └─ TEIA-Watchdog-Passive-v0200.ps1
       └─ TEIA-NeuroPlanner-v0218.ps1
            └─ Ollama (qwen2.5-coder:7b) — apenas para arquivos sem Hard Rule
  └─ TEIA-Watchdog-Report.ps1
       └─ D:\TEIA_CORE\neuroplanner\candidates\*.candidate.json
```

Se o Ollama não estiver rodando, arquivos que não acionam nenhuma Hard Rule serão marcados como `[FAIL]` no Watchdog. Isso não interrompe o script — os demais arquivos são processados normalmente.

---

*Documento criado em 2026-05-28. Versão do motor: TEIA-NeuroPlanner-v0218 (Golden Master v0.22.0).*
