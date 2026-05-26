# TEIA_FRACTAL_GEN — AUDITORIA READ-ONLY
**Data:** 2026-05-26
**Auditor:** Claude Sonnet 4.6 (Nó Ativo TEIA)
**Modo:** Análise estática — nenhum script foi executado
**Motor de referência:** TEIA v0.11.0 / CAS v0.14.1

---

## 1. SCRIPTS LOCALIZADOS

| Script | Localização | Versão | Data Modificação |
|--------|------------|--------|-----------------|
| `TEIA-Fractal-Gen.ps1` | `D:\bruto\TEIA\` | v1.7c | 2025-08-22 |
| `TEIA-Fractal-Gen.fixed.ps1` | `D:\bruto\TEIA\` | v1.4 | 2025-08-21 |
| `TEIA-Fractal-RestoreOnDemand.ps1` | `D:\bruto\TEIA\` | v1.1 | — |
| `TEIA-Fractal-AutoProfile.ps1` | `D:\bruto\TEIA\` | v1 | — |
| `TEIA-Fractal-ProvaReal.ps1` | `D:\bruto\TEIA\canon\legacy_resgatado\` | — | — |
| `GenFunctions.ps1` | **NÃO ENCONTRADO** | — | — |
| `GenFunctions.fixed.ps1` | **NÃO ENCONTRADO** | — | — |

> Cópias idênticas existem em `D:\bruto\TEIA\Analisados\` (mesmos timestamps).
> `GenFunctions*.ps1` ausente em todo `D:\` — busca recursiva confirmou.

---

## 2. INPUTS E OUTPUTS

### 2.1 TEIA-Fractal-Gen.ps1 / TEIA-Fractal-Gen.fixed.ps1

| # | Input | Tipo | Descrição |
|---|-------|------|-----------|
| 1 | `-Manifest` | `PSCustomObject` / `string` / `string[]` | JSON inline, caminho para .json, ou objeto PS |
| 2 | `-Out` | `string` (path) | Caminho do arquivo a gerar |
| 3 | `-Verify` | `switch` | Se presente, relê e verifica o SHA-256 do output |

| # | Output | Tipo | Descrição |
|---|--------|------|-----------|
| 1 | Arquivo gerado | binário | Resultado da função `fn` do manifesto |
| 2 | `[Gen] <path> (SHA=<hash>)` | stdout | Hash SHA-256 do arquivo gerado |
| 3 | `[Verify] SHA256=<hash>` | stdout | (apenas com `-Verify`) |

**Funções implementadas no `switch ($fn)`:**

| `fn` | Parâmetros esperados | Output |
|------|---------------------|--------|
| `gen_checkered_png` | `seed`, `params.width`, `params.height`, `params.color1`, `params.color2` | PNG xadrez |
| *(qualquer outro)* | — | `throw "Função desconhecida"` |

> Escopo funcional extremamente estreito: apenas geração de PNG xadrez.

### 2.2 TEIA-Fractal-RestoreOnDemand.ps1

| # | Input | Tipo | Descrição |
|---|-------|------|-----------|
| 1 | `-Root` | `string` (path) | Diretório com manifestos `.fractal_manifest*.json` |
| 2 | `-OutDir` | `string` (path) | Destino dos arquivos restaurados |
| 3 | `-Interval` | `int` | Segundos entre ciclos do loop infinito |

| # | Output | Tipo | Descrição |
|---|--------|------|-----------|
| 1 | Arquivo restaurado | binário | Decodificado de Base64 do manifesto |
| 2 | `dna_restore_ondemand_log.txt` | log | Registro de restaurações |

---

## 3. DEPENDÊNCIAS EXTERNAS

| Dependência | Tipo | Status | Impacto se ausente |
|------------|------|--------|--------------------|
| `GenFunctions.ps1` (dot-source) | Script PS | **AUSENTE — não existe em D:\\** | Script aborta com `throw` na linha 62 |
| `GenFunctions.fixed.ps1` (dot-source) | Script PS | **AUSENTE — não existe em D:\\** | Script aborta com `throw` na linha 21 |
| `PowerShell 7+` (pwsh) | Runtime | Presente | `throw "Requer PowerShell 7+"` |
| `.fractal_manifest*.json` | Dados | **AUSENTE — formato abandonado** | RestoreOnDemand carrega 0 manifestos |
| `TEIA-Fractal-Preload.ps1` | Script PS | **AUSENTE** | ProvaReal pula etapa silenciosamente |
| `TEIA-Fractal-Launch.ps1` | Script PS | **AUSENTE** | ProvaReal pula etapa silenciosamente |
| `FortniteClient-Win64-Shipping.exe` | Binário | Não presente | ProvaReal — P7 (deferido) |

---

## 4. COMANDOS POTENCIALMENTE DESTRUTIVOS

| Script | Linha | Comando | Contexto | Risco |
|--------|-------|---------|----------|-------|
| `RestoreOnDemand.ps1` | 60 | `Remove-Item $targetPath -Force` | Apaga arquivo restaurado se hash diverge | MÉDIO — opera em `$OutDir` (path configurável), não em originais |
| `AutoProfile.ps1` | 16 | `Remove-Item $probe -Force` | Apaga `tmp_probe.bin` de 64 MB criado pelo próprio script | BAIXO — temp file, sem risco |
| `ProvaReal.ps1` | 15 | `Remove-Item $metrics,$cacheLog -Force` | Apaga logs de run anterior | BAIXO — apenas logs de telemetria |
| `AutoProfile.ps1` | 31-32 | `Set-Content $identityPath` / `Set-Content $policyPath` | Sobrescreve `dna_identity.json` e `dna_policy_autoadapt.json` | BAIXO — arquivos de perfil, não dados de usuário |

> **Veredicto destrutivo:** Nenhum script toca em arquivos de usuário originais nem no CAS.
> O único `Remove-Item` relevante (RestoreOnDemand, linha 60) opera sobre um arquivo
> recém-restaurado com hash inválido — comportamento defensivo aceitável em princípio,
> mas **o caminho $OutDir aponta para diretório inexistente** (ver seção 5).

---

## 5. AUDITORIA DE CAMINHOS

### Caminhos hardcoded obsoletos (infra `D:\Teia\` — não existe mais)

| Script | Caminho obsoleto | Caminho atual equivalente |
|--------|-----------------|--------------------------|
| `RestoreOnDemand.ps1` | `D:\Teia\TEIA_NUCLEO\offline\nano` | `D:\TEIA_CORE\` |
| `RestoreOnDemand.ps1` | `D:\Teia\TEIA_NUCLEO\offline\restaurados_auto` | `D:\TEIA_USER\` (ou subpasta) |
| `ProvaReal.ps1` | `D:\Teia\TEIA_NUCLEO\offline\nano` | `D:\TEIA_CORE\` |

### Caminhos relativos perigosos

| Script | Código | Problema |
|--------|--------|---------|
| `AutoProfile.ps1` | `$Root="."` como default | Escreve `dna_identity.json` no diretório atual de execução — comportamento imprevisível |
| `Fractal-Gen*.ps1` | `Join-Path $PSScriptRoot 'GenFunctions.ps1'` | Correto em princípio, mas o arquivo alvo não existe |

---

## 6. ANÁLISE DE INTEGRIDADE ESTRUTURAL DO CÓDIGO

### TEIA-Fractal-Gen.ps1 v1.7 — BROKEN (colagem manual mal-sucedida)

O script contém **dois blocos de código órfão** que executam no escopo global antes da lógica principal:

**Bloco Órfão 1 (linhas 41–55):** Duplicata do corpo interno da função `Invoke-JsonCascade`, colada fora da função. Referencia `$Text` e `$MaxPasses` indefinidos no escopo global.

```powershell
# Linha 41 — $Text é $null no escopo global
$t = $Text
# Linha 43 — NullReferenceException aqui com ErrorActionPreference='Stop'
$t = $t.Trim()
```

Com `$ErrorActionPreference='Stop'` (linha 8), o script **lança exceção na linha 43** e aborta antes de executar qualquer lógica útil. Linha 55 tem o comentário `# [TEIA] removed stray }` — evidência de tentativa de reparo anterior que não resolveu o problema raiz.

**Bloco Órfão 2 (linhas 78–84):** `else { ... }` não conectado a nenhum `if`. PowerShell aceita sintaticamente mas é código morto / estruturalmente sem sentido.

### TEIA-Fractal-Gen.fixed.ps1 v1.4 — Estrutura limpa

Sem código órfão. Fluxo linear e legível. Seria executável se `GenFunctions.fixed.ps1` existisse.

---

## 7. COMPATIBILIDADE COM O MOTOR v0.11.0

### Modelo de dados: incompatibilidade fundamental

| Dimensão | Motor v0.11.0 (atual) | Suite Fractal-Gen (legado) |
|----------|----------------------|---------------------------|
| Armazenamento | `D:\TEIA_CORE\objects\{sha256}.bin` | Base64 embutido em `.fractal_manifest*.json` |
| Índice | `fractal_index.json` (array: hash, seed, tamanho) | `.fractal_manifest*.json` (um arquivo por objeto) |
| Restore | `Invoke-TEIARestoreBin` (CAS→path, SHA-256 verify) | `[Convert]::FromBase64String($obj.data)` → `WriteAllBytes` |
| Seed | Campo em `fractal_index.json` | Campo em manifesto individual |
| Mapa usuário | `.teia_map.json` (INGESTED/VERIFIED/MISSING) | Não existe |
| Paths | `D:\TEIA_CORE\`, `D:\TEIA_USER\` | `D:\Teia\TEIA_NUCLEO\offline\nano` |

### Tabela de compatibilidade por função

| Função / Script | Compatível com v0.11.0? | Razão |
|----------------|------------------------|-------|
| `gen_checkered_png` (GenFunctions) | Desconhecido | Arquivo ausente — não auditável |
| Leitura de `fractal_index.json` | ❌ Não | Scripts não referenciam este arquivo |
| Escrita em CAS (`objects/{hash}.bin`) | ❌ Não | Não gera `.bin`, não conhece CAS |
| Leitura de `.teia_map.json` | ❌ Não | Arquivo criado em v0.14.0, desconhecido pela suite |
| Restauração via CAS | ❌ Não | Usa Base64 em manifesto, não CAS |
| Idempotência de re-run | ⚠️ Parcial | `gen_checkered_png` é determinístico se seed fixo; mas sem guarda `Test-Path` |
| Paths atuais (`D:\TEIA_CORE\`) | ❌ Não | Hardcoded para `D:\Teia\` (inexistente) |

---

## 8. VIOLAÇÕES DOS AXIOMAS TEIA

| Axioma | Script | Violação |
|--------|--------|---------|
| Paths absolutos | `AutoProfile.ps1` | `$Root="."` como default — path relativo |
| SHA-256 como identidade | `RestoreOnDemand.ps1` | Restaura por nome de arquivo, não por hash CAS |
| Idempotência obrigatória | `RestoreOnDemand.ps1` | Loop infinito sem guarda de estado |
| CAS é a espinha dorsal | Toda a suite | Ignora `D:\TEIA_CORE\objects\` completamente |
| Sem `System.Random` sem seed em provas | `AutoProfile.ps1` | `[System.Random]::new()` sem seed (linha 14) |

---

## 9. VEREDITO FINAL

### Por script

| Script | Veredito | Motivo |
|--------|---------|--------|
| `TEIA-Fractal-Gen.ps1` v1.7 | **[INSEGURO]** | Código órfão causa crash na linha 43; `GenFunctions.ps1` ausente |
| `TEIA-Fractal-Gen.fixed.ps1` v1.4 | **[PRECISA_PATCH]** | Estrutura limpa; bloqueado apenas pela ausência de `GenFunctions.fixed.ps1` |
| `TEIA-Fractal-RestoreOnDemand.ps1` | **[INSEGURO]** | Paths inexistentes; modelo Base64 incompatível com CAS v0.11.0 |
| `TEIA-Fractal-AutoProfile.ps1` | **[PRECISA_PATCH]** | Útil como utilitário de profiling; requer path absoluto e seed no Random |
| `TEIA-Fractal-ProvaReal.ps1` | **[INSEGURO]** | 5 dependências ausentes; todos os paths obsoletos; escopo Fortnite (P7 deferido) |

### Veredito da suite

> ## `[INSEGURO]`
>
> A suite fractal como um todo **não pode ser executada** no estado atual:
> - O script principal (v1.7) crasha antes de executar qualquer lógica útil.
> - A dependência crítica (`GenFunctions.ps1`) não existe em disco.
> - O modelo de dados (Base64 em manifesto) é arquiteturalmente incompatível com o CAS v0.11.0.
> - Todos os paths hardcoded apontam para `D:\Teia\` — diretório removido na consolidação de infra.

---

## 10. ROADMAP DE REESCRITA (pré-condições para próxima fase)

Para atingir `[SEGURO_PARA_TESTE]`, a reescrita deve cobrir:

| # | Tarefa | Prioridade |
|---|--------|-----------|
| 1 | Criar `GenFunctions.ps1` do zero — implementar `gen_checkered_png` + funções futuras | CRÍTICA |
| 2 | Reescrever `TEIA-Fractal-Gen.ps1` limpo — sem código órfão, sem bloco `else` solto | CRÍTICA |
| 3 | Integrar com `fractal_index.json`: ler seed/hash da entrada CAS, gerar para `objects/{hash}.bin` | CRÍTICA |
| 4 | Substituir `RestoreOnDemand` por wrapper sobre `TEIA-Abrir.ps1` existente | ALTA |
| 5 | Fixar `AutoProfile.ps1`: path absoluto + seed explícito no Random | MÉDIA |
| 6 | `ProvaReal.ps1`: defer completo até P7 (Fortnite) — não reescrever agora | BAIXA |

> **Regra do freeze:** nenhuma dessas tarefas deve ser iniciada nesta sessão.
> Esta auditoria é o insumo para a próxima fase de reescrita, a ser autorizada separadamente.

---

*Auditoria concluída em 2026-05-26. Nenhum arquivo foi modificado ou executado.*
