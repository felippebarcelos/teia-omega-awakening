# 2243 - Otimização de prompt TEIA

### USUÁRIO

Você é um Otimizador Duplo de Prompts de IA.  
Analise o prompt fornecido e decida:  
- Se ele estiver prolixo ou pouco claro → refine (remova ruído/redundância e preserve exatamente a intenção original).  
- Se ele carecer de contexto ou detalhes → expanda (adicione apenas contexto relevante para realizar a intenção).  
Garanta que o resultado seja mais claro e eficaz do que o original.  
Retorne e apresente apenas o prompt otimizado — sem explicações, comentários ou texto extra.   
O Prompt a ser resultado deve possuir semântica, etimologia e núcleo conceitual com ressonância completa coerente denotativa!

Contexto:
[Retorno da execução do codex cli:
[• Ran 
  └ pwsh -NoLogo -NoProfile -Command '$ErrorActionPreference='"'Stop'
    "'$path = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\Audit-TEIA-v0.3.2-Reports.ps1'
    "'$dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $script = @'"'
    "'$ErrorActionPreference = "Stop"

      $ops = Get-Content -LiteralPath $opsPath -Raw | ConvertFrom-Json
      Write-Host "`n=== MDL DECISIONS (ops_summary.json) ===" -ForegroundColor Green
      $ops | Format-List *
      if ($ops.PSObject.Properties.Name -contains "huffman_det") {
        $hd = $ops.huffman_det
        Write-Host ("Huffman seeds: {0} | avg_ratio: {1}" -f $hd.count, $hd.avg_ratio) -ForegroundColor DarkGray
      }
    } else {
      Write-Warning "ops_summary.json não encontrado em $ReportDir"
    }

    # --- VERIFICATION REPORT (alvos e MDL por alvo)
    if (Test-Path -LiteralPath $verPath) {
      $jr = Get-Content -LiteralPath $verPath -Raw | ConvertFrom-Json
      Write-Host "`n=== HEADER (verification_report.json) ===" -ForegroundColor Green
      $jr | Select-Object core_sha256, pass, core_version | Format-List

      if ($jr.PSObject.Properties.Name -contains "targets" -and $jr.targets) {
        Write-Host "`n=== TARGETS ===" -ForegroundColor Green
        $rows = @()
        foreach ($t in $jr.targets) {
          $rows += [pscustomobject]@{
            name      = $t.name
            algo      = $t.algo
            entropy   = ('"'{0:n3}' -f "'$t.mdl.entropy_bits_per_byte)
            decision  = $t.mdl.decision
            est_gain  = $t.mdl.estimated_gain
            seed_size = $t.seed_size
            orig_size = $t.orig_size
            real_gain = $(if ($t.PSObject.Properties.Name -contains '"'real_gain') { "'$t.real_gain } else { $null })
          }
        }
        if ($rows.Count -gt 0) { $rows | Format-Table -AutoSize }
      } else {
        Write-Warning "Não há '"'targets' no relatório.\"
      }
    } else {
      Write-Warning \"verification_report.json não encontrado em "'$ReportDir"
    }
    '"'@
    [System.IO.File]::WriteAllText("'$path, $script, [System.Text.UTF8Encoding]::new($false))
    "Wrote: $path"'

• Ran pwsh -NoLogo -NoProfile -Command '$ErrorActionPreference='"'Stop'; & 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\Audit-TEIA-v0.3.2-Reports.ps1'"

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$ErrorActionPreference='"'Stop'
    "'$NanoReport  = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Core-v0.3.2-tests'
    "'$TempReport  = Join-Path $env:TEMP '"'TEIA-Core-v0.3.2-tests'
    if (Test-Path "'$TempReport) {
      if (-not (Test-Path $NanoReport)) { New-Item -ItemType Directory -Path $NanoReport -Force | Out-Null }
      Copy-Item -LiteralPath (Join-Path $TempReport '"'ops_summary.json') -Destination (Join-Path "'$NanoReport '"'ops_summary.json') -Force -ErrorAction SilentlyContinue
      Copy-Item -LiteralPath (Join-Path "'$TempReport '"'verification_report.json') -Destination (Join-Path "'$NanoReport '"'verification_report.json') -Force -ErrorAction SilentlyContinue
      'Synced TEMP reports to NANO.'
    } else { 'TEMP report dir not found.' }"

• Ran pwsh -NoLogo -NoProfile -Command "& 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\Audit-TEIA-v0.3.2-Reports.ps1'"

> All set. I installed and ran the enriched audit in NANO, then synced the TEMP reports so the new fields appear there too.

  What I Did

  - Wrote D:\Teia\TEIA_NUCLEO\offline\nano\Audit-TEIA-v0.3.2-Reports.ps1 with:
      - Fixed “empty pipe element” pattern by accumulating rows before Format-Table.
      - Enriched header output: core_sha256, pass, core_version.
      - Targets table: name, algo, entropy, decision, est_gain, seed_size, orig_size, real_gain.
  - Synced the latest TEMP test reports into NANO to display targets immediately.

  Run Output

  - Command: pwsh -NoProfile -File D:\Teia\TEIA_NUCLEO\offline\nano\Audit-TEIA-v0.3.2-Reports.ps1
  - Report dir: D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Core-v0.3.2-tests
  - MDL decisions: Huffman seeds=2, avg_ratio≈0.2702
  - Header: core_sha256=a58f2a7d4a189bd4f2c0881a6efcd9b7973ec8f2b03c694ce6b3f4cc06852e8f, pass=True, core_version=v0.3.2
  - Targets table shows entropy, MDL decisions, and gains for each sample, including skewed positive and random negative.

  Next Steps

  - Freeze the NANO harness; run official releases from NANO.
  - I can patch v0.3.2.1 next to add:
      - -ReportDir param for tests writing into .\_work\<timestamp>.
      - Big Test: generate 1.2 GiB one-symbol; record PeakWorkingSet64 and throughput; enforce peak_ws_mb <= 64.
      - Audit integration to read from _work instead of TEMP.
  - v0.3.3 plan: corpus batch (JPEG/H.264/PDF/CSV/ZIP), MDL metrics, teia_core.config.json with entropy_cutoff, min_gain_bytes, chunk_kb.

  Want me to proceed with v0.3.2.1 now (ReportDir + Big Test + audit integration)?]

Auditoria do gemini sobre o obtido com o codex:
[Felippe, a execução da auditoria do GPT foi **perfeita**. Ela não só validou o sucesso do Core v0.3.2, como também:

1.  **Resolveu o "Ruído de Telemetria":** Corrigiu o `ParserError` no script de auditoria.
2.  **Consolidou os Relatórios:** Sincronizou os relatórios do `TEMP` (onde o Codex os criou) para o `nano` (onde queremos que eles fiquem).
3.  **Apresentou a Telemetria Canônica:** Finalmente exibiu os dados cruciais:
      * `pass=True`
      * `core_sha256=a58f...` (o carimbo de reprodutibilidade)
      * `Huffman seeds=2`, `avg_ratio≈0.2702` (MDL Honesta em ação: 2 arquivos foram comprimidos com Huffman, ganhando \~73%).
      * A tabela de `TARGETS` (que agora incluiria as decisões `huffman` e `huffman_skipped_no_gain`).

Você **alcançou o limiar v0.3.2**. O Core está estável, validado em testes sintéticos, e a telemetria está funcional.

-----

### Análise Crítica e Próximo Passo

O GPT está correto em sua análise: o ciclo "plano" de correção de bugs terminou, e a "espiral ascendente" (v0.3.3) deve começar.

**A Dissonância Atual (Onde Estamos):**

  * **Temos:** Um Core v0.3.2 validado contra *dados sintéticos fáceis* (`sample_skew`, `random`).
  * **Precisamos:** Provar que ele funciona contra *desafios reais*:
    1.  **Escala:** O teste de RAM `< 64MB` em arquivos `>1GB` (o "Big Test").
    2.  **Complexidade:** Testar contra um corpus real (JPEG, H.264, PDF).
    3.  **Robustez:** Tornar o *harness* de teste (os scripts) mais robusto (paths, configs).

**A Proposta do GPT (v0.3.2.1):**
O GPT sugeriu um passo intermediário (v0.3.2.1) para "endurecer" o harness de teste *antes* de atacar o corpus real. Isso é uma excelente prática de engenharia (PDCA/Kaizen).

**O Caminho Coerente (Sua Pergunta):**
Você quer "manter a denotativa real funcional determinística" e "alcançar a denotativa real funcional determinística universal (atomizada)". Para isso, precisamos **aceitar a sugestão do GPT** e **combiná-la com o rigor do prompt autopropulsivo**.

Não precisamos mais do *autoloop completo* (pois o v0.3.2 já está funcional), mas precisamos de um prompt que instrua o Codex/Grok a executar a **próxima evolução específica (v0.3.2.1)**.

-----

### 🚀 Prompt de Instrução Autopropulsivo (v0.3.2 -\> v0.3.2.1: Hardening e Big Test)

Este é o prompt que você deve usar para iniciar a próxima sessão. Ele é autopropulsivo para *esta tarefa específica* (implementar v0.3.2.1) e assume que o v0.3.2 já está validado.

```markdown
# TEIA v0.3.2 -> v0.3.2.1: Hardening do Harness de Teste (Big Test RAM & Paths)

# ==============================================================================
# META-CONTEXTO & AUTORIDADE
# ==============================================================================
# Você é o Codex CLI (ou Grok), operando como Orquestrador Autônomo TEIA.
# Estado Atual (Limiar v0.3.2 Validado):
# - Core v0.3.2 (TEIA-Core-v0.3.2.ps1) @ SHA 'a58f2a7d...' está ESTÁVEL e VALIDADO localmente (STATUS=OK).
# - Ops Huffman streaming e Heurística MDL (Honestidade Entrópica) estão FUNCIONAIS.
# - Suíte de testes (Run-TEIA-Core-Tests-v0.3.2.ps1) validou testes sintéticos.
# - Telemetria (verification_report.json, ops_summary.json) é gerada.
#
# Dissonância Atual (Gargalo):
# O harness de teste v0.3.2 atual:
# 1. Salva relatórios em diretórios hardcoded (seja TEMP ou PSScriptRoot).
# 2. NÃO valida o requisito "STREAMING FIRST (RAM < 64MB)" em arquivos >1GB ("Big Test").
#
# Missão (A Próxima Espiral Ascendente):
# Evoluir a Suíte de Testes para v0.3.2.1 para ENDURECER (Harden) o processo de validação,
# tornando-o robusto em paths e provando a eficiência de memória em larga escala.
# Foco: Atomizar a prova de streaming (RAM < 64MB).

# ==============================================================================
# PRINCÍPIOS INVARIANTES (Reforço v0.3.2.1)
# ==============================================================================
# 1. Determinismo, Canonicalização, Idempotência, Honestidade Entrópica: Mantidos.
# 2. Foco no Harness: O *Core* (TEIA-Core-v0.3.2.ps1) NÃO deve ser modificado neste ciclo,
#    a menos que seja estritamente necessário para a telemetria do Big Test.
# 3. Telemetria Canônica: Relatórios devem ser consistentes.

# ==============================================================================
# TAREFAS (Ciclo PDCA v0.3.2.1)
# ==============================================================================

# --- P (Plan) ---
# 1. Analise o `Run-TEIA-Core-Tests-v0.3.2.ps1` (versão já corrigida por Gemini/GPT).

# --- D (Do) ---
# 2. CRIE `Run-TEIA-Core-Tests-v0.3.2.1.ps1` (backup do v0.3.2):
#    a) Hardening de Paths: Adicione um parâmetro `-ReportDir` (string).
#       - Se `-ReportDir` NÃO for fornecido, `$ReportDir` DEVE ser `$PSScriptRoot\_work_$(Get-Date -Format 'yyyyMMddHHmmss')`.
#       - Garanta que TODOS os relatórios (`verification_report.json`, `ops_summary.json`) e
#         subdiretórios (`targets`, `seeds`, `restored`, `predictive`) sejam criados dentro deste `$ReportDir`.
#    b) Implementar "Big Test" (RAM < 64MB):
#       - Adicione um parâmetro `-RunBigTest` (switch).
#       - Se `-RunBigTest` for usado:
#         i.   Gere um arquivo sintético grande (ex: `one_symbol_1.2GiB.bin`) em `$ReportDir\targets`. Use `[System.IO.File]::Open` e escrita em chunks (NÃO `New-Object byte[]`), mantendo a RAM baixa.
#         ii.  Execute `Build-Seed-From-Stream` (Compressão) neste arquivo, medindo `($PicoRAM_Compress = (Measure-Command { ... } | Select-Object PeakWorkingSet64).PeakWorkingSet64)`.
#         iii. Execute `Execute-Plan` (Restauração) neste arquivo, medindo `($PicoRAM_Restore = (Measure-Command { ... } | Select-Object PeakWorkingSet64).PeakWorkingSet64)`.
#         iv.  Registre `PicoRAM_Compress` e `PicoRAM_Restore` no `ops_summary.json`.
#         v.   O teste DEVE FALHAR (Exit 1) se `PicoRAM_Restore` ou `PicoRAM_Compress` excederem 100MB (limite seguro, acima dos 64MB teóricos).

# --- C (Check) ---
# 3. EXECUTE A NOVA SUÍTE DE TESTES:
#    a) Rode `Run-TEIA-Core-Tests-v0.3.2.1.ps1` (Modo Padrão, sem -RunBigTest).
#    b) Capture `verification_report.json` e `ops_summary.json` do novo diretório `_work_*`.
#    c) Verifique se STATUS=OK.
# 4. EXECUTE O BIG TEST:
#    a) Rode `Run-TEIA-Core-Tests-v0.3.2.1.ps1 -RunBigTest`.
#    b) Verifique se STATUS=OK (ou seja, não estourou a RAM).

# --- A (Act) ---
# 5. ANALISE E FINALIZE:
#    - Se ambos os testes (Padrão e Big Test) passarem (Exit Code 0):
#        Emita: `STATUS=OK | TEIA Harness v0.3.2.1 validado. Paths corrigidos e Pico de RAM < 100MB confirmado.`
#    - Se falhar: Analise o erro, proponha PATCH MÍNIMO, instrua REEXECUTAR.

# ==============================================================================
# TAREFA IMEDIATA (Seu primeiro passo neste prompt)
# ==============================================================================
# 1. Gere o conteúdo do NOVO script `Run-TEIA-Core-Tests-v0.3.2.1.ps1`
#    (baseado no v0.3.2, mas com Hardening de Paths (P1/P3/P4) e o Big Test (C2) implementados).
# 2. Gere o comando para EXECUTAR o teste padrão (Passo 6).
# 3. Gere o comando para EXECUTAR o Big Test (Passo 7).
#
# Após gerar esses 3 artefatos, pare e aguarde minha aprovação para aplicá-los e executar os testes.
```

Este prompt direciona a IA para a próxima etapa lógica: **endurecer os testes e provar a escalabilidade (baixo uso de RAM)**, que é a promessa central do "streaming first".]]

Prompt a ser reformulado para a complexidade contextual:
[Como devemos prosseguimos? não temos muito tempo, porém temos recursos que você pode interligar e transduzir em delegação de tarefa para o codex em prompt autocontido que catalisa o alcance da versão mais elevada e estávelmente denotativamente deterministicamente idempotente em coerência universal que poderíamos catalisar junto em nossa simbiose. Penso na versão 1.0 mas para isso precisamos interligar o que a versão 1.0 precisaria atingir para ter coerência madura ressonante para representar esse estágio... ]

---

### ASSISTENTE

# TEIA v1.0 — Prompt Autocontido para Consolidação Denotativa (de v0.3.2 validado → v1.0)

## Papel & Contexto
Você é o **Orquestrador Autônomo TEIA (Codex/Grok)**. O **Core v0.3.2** está **estável e validado** (pass=True; core_sha256 conhecido; telemetria funcional; MDL/Huffman operantes). Agora, devemos **endurecer o harness**, **provar escala real** e **congelar uma release v1.0** com reprodutibilidade e idempotência.

## Objetivo Denotativo v1.0
Entregar **TEIA v1.0** com **determinismo, idempotência e coerência universal**: *streaming-first*, reprodutível, eficiente em RAM, telemetria canônica e testes em corpus real, prontos para auditoria.

## Princípios Invariantes
1. **Determinismo & Canonicalização** (hash estável, ordens definidas, sem fontes de aleatoriedade).
2. **Idempotência** (repetições não alteram o estado final).
3. **Streaming-First** (processamento em chunks; sem buffers monolíticos).
4. **Honestidade Entrópica (MDL)**: nunca “forçar” compressão sem ganho real.
5. **Falha Segura & Logs Claros** (exit codes consistentes; mensagens auditáveis).

## Critérios de Aceitação v1.0
- **Reprodutibilidade**: `verification_report.json.pass=True` e `core_sha256` constante entre runs.
- **RAM (Big Test)**: `PeakWorkingSet64 ≤ 64MB` alvo e **hard-cap ≤ 96MB** em **arquivo ≥ 1.2 GiB** (compressão e restauração).
- **Corpus Real**: bater **JPEG/H.264/PDF/CSV/ZIP** com métricas MDL (entropy_bits_per_byte, estimated_gain, real_gain, decisões “huffman”/“skipped_no_gain”).
- **Configuração**: `teia_core.config.json` com `entropy_cutoff`, `min_gain_bytes`, `chunk_kb` e defaults canônicos.
- **Paths & Relatórios**: **sem TEMP hardcoded**; `-ReportDir` obrigatório (ou default `_work_<timestamp>`). Produzir **ops_summary.json**, **verification_report.json** e subpastas `targets/`, `seeds/`, `restored/`, `predictive/`.
- **Não-regressão**: suíte de testes unitários + integração; **exit 1** se violar RAM hard-cap, telemetria ausente ou ganho negativo mascarado.

## Entregáveis Obrigatórios
1. **Run-TEIA-Core-Tests-v0.3.2.1.ps1** (hardening de paths + Big Test RAM).
2. **Run-TEIA-Core-Corpus-v0.3.3.ps1** (execução em corpus real + MDL/telemetria).
3. **Release-TEIA-Core-v1.0.ps1** (freeze/tag: copia artefatos, grava SHA256, verifica idempotência).
4. **teia_core.config.json** (defaults canônicos).
5. **Documentação mínima** (README_v1.0.md com comandos, critérios, layout de relatórios).

> **Formato dos scripts**: gerar **blocos PowerShell puros prontos para colar** (padrão “textdoc embed Codex”), usando **Set-Content** (UTF-8 BOM-less), sem `@echo off`, `::`, `%VAR%`. Variáveis com `$`, comentários `#`. Idempotentes e com tratamento de erro `try/catch`.

## Faseamento (PDCA)
**Fase A — v0.3.2.1 (Hardening + Big Test)**
- Implementar `-ReportDir` (default: `$PSScriptRoot\_work_$(Get-Date -Format 'yyyyMMddHHmmss')`).
- Gerar `one_symbol_1.2GiB.bin` via stream (chunks fixos) e medir `PeakWorkingSet64` em **compress** e **restore**.
- Registrar picos de RAM em `ops_summary.json`; **falhar** se > 96MB.

**Fase B — v0.3.3 (Corpus Real + MDL)**
- Rodar corpus (JPEG/H.264/PDF/CSV/ZIP) em streaming; registrar **entropy_bits_per_byte**, **estimated_gain**, **real_gain**, **decision**.
- Aplicar `teia_core.config.json` (cutoffs; chunking; limites de ganho).
- Produzir tabelas canônicas (targets e seeds) nos relatórios.

**Fase C — v0.9 (Freeze Técnico)**
- Consolidar scripts, configs e relatórios; fixar caminhos relativos; repetir testes (A+B) para idempotência.

**Fase D — v1.0 (Release)**
- Executar `Release-TEIA-Core-v1.0.ps1`: congelar artefatos, recalcular e registrar **core_sha256**, validar tudo; emitir `STATUS=OK | v1.0`.

## O que você deve produzir AGORA (nesta resposta)
1. **Conteúdo completo** de:
   - `Run-TEIA-Core-Tests-v0.3.2.1.ps1`
   - `Run-TEIA-Core-Corpus-v0.3.3.ps1`
   - `Release-TEIA-Core-v1.0.ps1`
   - `teia_core.config.json` (defaults recomendados)
2. **Comandos prontos para rodar** (PowerShell):
   - Teste padrão (Fase A, sem `-RunBigTest`).
   - Big Test (Fase A, com `-RunBigTest`).
   - Corpus (Fase B).
   - Freeze/Release (Fases C e D).
3. **Linhas de verificação** esperadas no console (mini checklist): `pass=True`, `core_sha256=<hash>`, `PeakWorkingSet64<=96MB`, resumo MDL do corpus.

> **Pare após imprimir os artefatos acima.** Aguarde aprovação para aplicar e executar.

---

### USUÁRIO

A auditoria do gemini sobre a resultante provável do retorno ao prompt que você me forneceu está correta e tornaria impossível alcançar um prompt que faça atravessar da versão 0.3.2.1 para o v1.0 de forma idempotente que o caminho a que seria trilhado manualmente para alcançar linearmente da versão v0.3.2.1... até v1?
Auditoria Gemini:
[Felippe, sua intuição está absolutamente correta.

Sim, enviar este prompt "TEIA v1.0" de uma só vez é **muito irrealista** com as capacidades atuais dos LLMs (seja GPT, Grok ou eu mesmo), e eu o desaconselho.

Permita-me dissecar o "porquê" usando a própria lógica da T.E.I.A. que estamos estabelecendo:

### 1\. A Dissonância Cognitiva (Por que é Irrealista)

O seu prompt v1.0 é, em si, uma obra-prima de "engenharia de destino" — ele define perfeitamente o estado final almejado. No entanto, ele falha como um *prompt de execução* por três razões fundamentais:

1.  **Violação da Evolução Espiralar (Ciclo PDCA):**
    O "retorno" que você acabou de receber do GPT enfatiza a importância de um "movimento espiralar (não linear, mas ascendente)" e critica o "ciclo plano". Seu prompt v1.0, ao tentar saltar de `v0.3.2` para `v1.0` (cobrindo Fases A, B, C e D), viola esse mesmo princípio. Ele tenta construir 4 "degraus" da espiral de uma só vez, o que é um "salto" (não-linear), e não um "passo" (cumulativo).
2.  **Sobrecarga de Carga Cognitiva (Contexto):**
    Você está pedindo à IA que:
      * Gere `Run-TEIA-Core-Tests-v0.3.2.1.ps1` (com lógica complexa de medição de RAM para o Big Test).
      * Gere `Run-TEIA-Core-Corpus-v0.3.3.ps1` (com lógica de streaming para múltiplos formatos reais).
      * Gere `Release-TEIA-Core-v1.0.ps1` (script de freeze).
      * Gere `teia_core.config.json`.
      * ...tudo isso *em uma única resposta*, mantendo todos os "Princípios Invariantes" na memória.
        A probabilidade de erros lógicos, esquecimento de restrições (como o `streaming-first`) ou bugs de sintaxe é astronomicamente alta.
3.  **Risco de Truncamento (Limite de Saída):**
    A IA (Codex, Grok, ou eu) quase certamente atingirá o limite máximo de tokens de saída antes de conseguir gerar os 4 scripts e o config. Você receberá uma resposta incompleta e quebrada.

### 2\. A "Alquimia" Correta (A Próxima Ação Coerente)

A "evolução em time-lapse" que você almeja é alcançada não por um *único prompt gigante*, mas por uma *sequência rápida de prompts autopropulsivos* (o ciclo PDCA da "espiral ascendente").

O "retorno" do GPT e a minha análise anterior já convergiram para o próximo passo lógico e alcançável: **Fase A (v0.3.2.1)**.

O prompt que eu forneci na **minha resposta anterior** (`Prompt de Instrução Autopropulsivo (v0.3.2 -> v0.3.2.1: Hardening e Big Test)`) é *exatamente* a implementação da **Fase A** do seu prompt v1.0.

### 3\. Como Prosseguir (O Caminho Denotativamente Coerente)

**Não** envie o prompt v1.0. Em vez disso, prossiga com a **Fase A** (o prompt v0.3.2.1 que eu já lhe dei).

Para recapitular, o próximo passo é enviar este prompt (que já está alinhado e pronto) ao Codex/Grok:

```markdown
# TEIA v0.3.2 -> v0.3.2.1: Hardening do Harness de Teste (Big Test RAM & Paths)

# ==============================================================================
# META-CONTEXTO & AUTORIDADE
# ==============================================================================
# Você é o Codex CLI (ou Grok), operando como Orquestrador Autônomo TEIA.
# Estado Atual (Limiar v0.3.2 Validado):
# - Core v0.3.2 (TEIA-Core-v0.3.2.ps1) @ SHA 'a58f2a7d...' está ESTÁVEL e VALIDADO localmente (STATUS=OK).
# - Ops Huffman streaming e Heurística MDL (Honestidade Entrópica) estão FUNCIONAIS.
# - Suíte de testes (Run-TEIA-Core-Tests-v0.3.2.ps1) validou testes sintéticos.
# - Telemetria (verification_report.json, ops_summary.json) é gerada.
#
# Dissonância Atual (Gargalo):
# O harness de teste v0.3.2 atual:
# 1. Salva relatórios em diretórios hardcoded (seja TEMP ou PSScriptRoot).
# 2. NÃO valida o requisito "STREAMING FIRST (RAM < 64MB)" em arquivos >1GB ("Big Test").
#
# Missão (A Próxima Espiral Ascendente):
# Evoluir a Suíte de Testes para v0.3.2.1 para ENDURECER (Harden) o processo de validação,
# tornando-o robusto em paths e provando a eficiência de memória em larga escala.
# Foco: Atomizar a prova de streaming (RAM < 64MB).

# ==============================================================================
# PRINCÍPIOS INVARIANTES (Reforço v0.3.2.1)
# ==============================================================================
# 1. Determinismo, Canonicalização, Idempotência, Honestidade Entrópica: Mantidos.
# 2. Foco no Harness: O *Core* (TEIA-Core-v0.3.2.ps1) NÃO deve ser modificado neste ciclo,
#    a menos que seja estritamente necessário para a telemetria do Big Test.
# 3. Telemetria Canônica: Relatórios devem ser consistentes.

# ==============================================================================
# TAREFAS (Ciclo PDCA v0.3.2.1)
# ==============================================================================

# --- P (Plan) ---
# 1. Analise o `Run-TEIA-Core-Tests-v0.3.2.ps1` (versão já corrigida por Gemini/GPT).

# --- D (Do) ---
# 2. CRIE `Run-TEIA-Core-Tests-v0.3.2.1.ps1` (backup do v0.3.2):
#    a) Hardening de Paths: Adicione um parâmetro `-ReportDir` (string).
#       - Se `-ReportDir` NÃO for fornecido, `$ReportDir` DEVE ser `$PSScriptRoot\_work_$(Get-Date -Format 'yyyyMMddHHmmss')`.
#       - Garanta que TODOS os relatórios (`verification_report.json`, `ops_summary.json`) e
#         subdiretórios (`targets`, `seeds`, `restored`, `predictive`) sejam criados dentro deste `$ReportDir`.
#    b) Implementar "Big Test" (RAM < 64MB):
#       - Adicione um parâmetro `-RunBigTest` (switch).
#       - Se `-RunBigTest` for usado:
#         i.   Gere um arquivo sintético grande (ex: `one_symbol_1.2GiB.bin`) em `$ReportDir\targets`. Use `[System.IO.File]::Open` e escrita em chunks (NÃO `New-Object byte[]`), mantendo a RAM baixa.
#         ii.  Execute `Build-Seed-From-Stream` (Compressão) neste arquivo, medindo `($PicoRAM_Compress = (Measure-Command { ... } | Select-Object PeakWorkingSet64).PeakWorkingSet64)`.
#         iii. Execute `Execute-Plan` (Restauração) neste arquivo, medindo `($PicoRAM_Restore = (Measure-Command { ... } | Select-Object PeakWorkingSet64).PeakWorkingSet64)`.
#         iv.  Registre `PicoRAM_Compress` e `PicoRAM_Restore` no `ops_summary.json`.
#         v.   O teste DEVE FALHAR (Exit 1) se `PicoRAM_Restore` ou `PicoRAM_Compress` excederem 100MB (limite seguro, acima dos 64MB teóricos).

# --- C (Check) ---
# 3. EXECUTE A NOVA SUÍTE DE TESTES:
#    a) Rode `Run-TEIA-Core-Tests-v0.3.2.1.ps1` (Modo Padrão, sem -RunBigTest).
#    b) Capture `verification_report.json` e `ops_summary.json` do novo diretório `_work_*`.
#    c) Verifique se STATUS=OK.
# 4. EXECUTE O BIG TEST:
#    a) Rode `Run-TEIA-Core-Tests-v0.3.2.1.ps1 -RunBigTest`.
#    b) Verifique se STATUS=OK (ou seja, não estourou a RAM).

# --- A (Act) ---
# 5. ANALISE E CORRIJA:
#    - Se qualquer teste (Padrão ou Big Test) falhar, identifique a causa,
#      proponha patch (para o Core v0.3.2 ou Testes v0.3.2.1) e instrua REEXECUTAR este prompt.

# ==============================================================================
# TAREFA IMEDIATA (Seu primeiro passo neste prompt)
# ==============================================================================
# 1. Gere o conteúdo do NOVO script `Run-TEIA-Core-Tests-v0.3.2.1.ps1`
#    (baseado no v0.3.2, mas com Hardening de Paths (P1/P3/P4) e o Big Test (C2) implementados).
# 2. Gere o comando para EXECUTAR o teste padrão (Passo 3).
# 3. Gere o comando para EXECUTAR o Big Test (Passo 4).
#
# Após gerar esses 3 artefatos, pare e aguarde minha aprovação para aplicá-los e executar os testes.
```]
Transgrida a geração de prompt determinístico catalisável na idempotente v1.

---

### ASSISTENTE

# TEIA v1.0 — Protocolo Determinístico de Escalada (v0.3.2 → v1.0), Idempotente e Denotativo

## Papel & Ambiente
Você é o **Orquestrador Autônomo TEIA** (Codex/Grok). Execute em **PowerShell 7**. Toda saída de script deve seguir o padrão **“textdoc embed Codex”**: bloco único `Set-Content` (UTF-8 sem BOM) que cria o arquivo alvo + **botão de download** + **4 linhas de instruções de execução**. Sem `@echo off`, `::` ou `%VAR%`. Variáveis com `$` e comentários `#`.

## Estado Canônico (premissas)
- Core **v0.3.2** validado localmente (`pass=True`), `core_sha256=a58f2a7d...`.
- Telemetria ativa: `verification_report.json`, `ops_summary.json`.
- MDL/Huffman “streaming-first” operantes.

## Invariantes (não negociar)
**Determinismo, Canonicalização, Idempotência, Streaming-First, Honestidade Entrópica (MDL), Falha Segura com logs claros.**

## Contrato de Saída (gating)
Produza **apenas o artefato da FASE ATUAL**, seguido dos **comandos para rodar** e um **checklist de verificação**. **Pare** e aguarde a palavra-chave **PROSSIGA** para avançar. Se algum critério de aceitação falhar, **emita patch mínimo** e **reentregue** a mesma Fase.

---

## FASE A — v0.3.2.1 (Hardening do Harness + Big Test RAM)
**Meta denotativa:** paths canônicos, telemetria no `_work_*`, prova de RAM baixa em arquivo ≥ **1.2 GiB**.

**Entregável A1:** `Run-TEIA-Core-Tests-v0.3.2.1.ps1` com:
1) `-ReportDir` (default: `$PSScriptRoot\_work_$(Get-Date -Format 'yyyyMMddHHmmss')`); criar subpastas `targets/`, `seeds/`, `restored/`, `predictive/`.
2) `-RunBigTest` (switch) que:
   - gera `targets\one_symbol_1.2GiB.bin` via stream (escrita em chunks; sem colocar o arquivo em memória),
   - mede `PeakWorkingSet64` em **compress** e **restore**,
   - adiciona `PicoRAM_Compress` e `PicoRAM_Restore` ao `ops_summary.json`,
   - **falha (exit 1)** se qualquer pico > **96 MB** (alvo ≤ **64 MB**).

**Critérios de Aceitação A:**  
`verification_report.json.pass=True` • `core_sha256` presente • `ops_summary.json` inclui os dois picos de RAM • diretório `_work_*` criado sem uso de `TEMP` hardcoded • Big Test passa dentro do hard-cap.

**SAÍDA EXIGIDA NESTA FASE:**  
1) **Conteúdo completo** de `Run-TEIA-Core-Tests-v0.3.2.1.ps1` (padrão textdoc embed Codex).  
2) **Dois comandos** prontos para rodar: (i) teste padrão; (ii) Big Test.  
3) **Checklist** mínimo esperado no console: `pass=True`, `core_sha256=<hash>`, `PeakWorkingSet64<=96MB`.

> **PARE após entregar A1 + comandos + checklist.**

---

## FASE B — v0.3.3 (Corpus Real + MDL) — **somente após “PROSSIGA”**
**Entregável B1:** `Run-TEIA-Core-Corpus-v0.3.3.ps1` (streaming em **JPEG/H.264/PDF/CSV/ZIP**; reporta `entropy_bits_per_byte`, `estimated_gain`, `real_gain`, `decision`= `huffman`|`skipped_no_gain`).  
**Entregável B2:** `teia_core.config.json` (defaults canônicos: `chunk_kb`, `entropy_cutoff`, `min_gain_bytes`).  
**Critérios B:** sem regressão; negativo não mascarado; reports no `_work_*`.

**Saída B (quando acionado):** scripts (textdoc embed Codex) + comandos + checklist MDL.

---

## FASE C — v0.9 (Freeze Técnico) — **somente após “PROSSIGA”**
**Entregável C1:** consolidação reprodutível; reruns A+B; idempotência confirmada.

---

## FASE D — v1.0 (Release) — **somente após “PROSSIGA”**
**Entregável D1:** `Release-TEIA-Core-v1.0.ps1` (freeze/tag, SHA256 dos artefatos, verificação final, `STATUS=OK | v1.0`).  
**Critérios D:** reprodutibilidade integral; telemetria canônica; limites de RAM respeitados.

---

## TAREFA IMEDIATA (execute agora)
**Gerar e devolver apenas:**  
**(A1)** `Run-TEIA-Core-Tests-v0.3.2.1.ps1` (padrão textdoc embed Codex) **+**  
**comando teste padrão** **+** **comando Big Test** **+** **checklist esperado**.  
**Depois, PARE e aguarde “PROSSIGA”.**

---

