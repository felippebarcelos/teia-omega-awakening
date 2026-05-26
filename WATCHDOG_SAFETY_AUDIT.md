# WATCHDOG_SAFETY_AUDIT.md
## Auditoria de Segurança e Idempotência — TEIA-Sync-Watchdog v0.13.0

**Auditor:** Claude Sonnet 4.6 (Nó Ativo TEIA)
**Data:** 2026-05-25
**Arquivo auditado:** `D:\TEIA_CORE\tools\TEIA-Sync-Watchdog.ps1`
**Modo:** READ-ONLY (nenhuma alteração realizada no script)
**Resultado geral:** ✅ APROVADO PARA CICLO ÚNICO — ⚠️ DOIS RISCOS MÉDIOS PARA CICLO CONTÍNUO

---

## 1. ANÁLISE DE SEGURANÇA

### 1.1 Comandos de Destruição (`Remove-Item`, `del`, `Move-Item`)

**Único `Remove-Item` encontrado: linha 106.**

```powershell
# linha 103-108
Copy-Item -LiteralPath $File.FullName -Destination $dest -Force -ErrorAction Stop
$verifHash = (Get-FileHash $dest -Algorithm SHA256 -ErrorAction Stop).Hash
if ($verifHash -ine $Hash) {
    Remove-Item $dest -ErrorAction SilentlyContinue   # ← ÚNICO Remove-Item
    throw "Hash pós-cópia diverge"
}
```

**Análise:** SEGURO.
- `$dest` é sempre construído como `Join-Path $CASRoot "$($Hash.ToLower()).bin"`
- `$CASRoot = 'D:\TEIA_CORE\objects'` — caminho hardcoded, não parametrizável pelo usuário
- A remoção ocorre apenas sobre o arquivo que acabou de ser copiado pelo próprio script, quando a verificação de integridade falha
- Não há interpolação de variável externa em `$dest` que permita path traversal
- Nenhum `Move-Item`, `del`, `rmdir`, `rd` ou `rm` em qualquer outra parte do script

**Veredicto: ✅ Sem risco de deleção acidental fora do CAS**

---

### 1.2 Acesso a Arquivos Fora das `source_roots` Autorizadas

Mapeamento completo de I/O do script:

| Operação | Caminho | Modo |
|----------|---------|------|
| Leitura de arquivos fonte | `$Monitoradas` (4 pastas em `D:\bruto\TEIA\`) | Read |
| Escrita de objeto CAS | `D:\TEIA_CORE\objects\{hash}.bin` | Write |
| Leitura/escrita de índice | `D:\TEIA_CORE\manifests\fractal_index.json` | Read+Write |
| Append de eventos | `D:\TEIA_CORE\dna_events.jsonl` | Append |
| Escrita de estado | `D:\TEIA_CORE\memory\watchdog_state.json` | Write |
| Leitura de índice órfão | `D:\bruto\TEIA\fractal_index.json` | Read |
| Criação de diretórios ausentes | Subpastas dos paths acima | Write |

**Veredicto: ✅ Nenhum acesso fora dos limites mapeados**

---

### 1.3 Proteção Contra Loop Infinito / Saturação de CPU

**Ciclo contínuo (linha 205-209):**
```powershell
while ($true) {
    Invoke-WatchdogCycle
    Start-Sleep -Seconds $IntervalSeg   # padrão 300s
}
```

- `Start-Sleep` garante pausa mínima de 300 segundos entre ciclos
- Nenhuma função recursiva detectada (`Invoke-WatchdogCycle` não se auto-chama)
- `Get-ChildItem -Recurse` sobre diretórios físicos NTFS não pode criar loop infinito (o SO detecta ciclos em junctions/symlinks)
- `Get-FileHash` pode bloquear em arquivos travados por outros processos, mas está com `-ErrorAction SilentlyContinue`, retornando null e prosseguindo

**Único risco residual:** se `$IntervalSeg = 0` for passado explicitamente, o loop vira busy-wait. O padrão (300) é seguro.

**Veredicto: ✅ Sem risco de loop infinito em uso padrão**

---

### 1.4 Tratamento de Erros

**Estratégia global:** `$ErrorActionPreference = 'Continue'` (linha 32)

| Ponto de falha | Mecanismo |
|---------------|-----------|
| `Get-ChildItem` (permissão negada a pasta) | `-ErrorAction SilentlyContinue` → pasta ignorada silenciosamente |
| `Get-FileHash` (arquivo travado) | `-ErrorAction SilentlyContinue` → `$hash` fica `$null`, arquivo ignorado |
| `Copy-Item` (disco cheio, permissão) | `-ErrorAction Stop` + try/catch → loga `WD_INGEST_FAIL` e continua próximo arquivo |
| `Get-FileHash` pós-cópia (CAS) | `-ErrorAction Stop` + try/catch → loga `WD_INGEST_FAIL` |
| `Add-Content` no EventLog | `-ErrorAction SilentlyContinue` → falha silenciosa no log (não crítico) |
| `ConvertFrom-Json` no índice | `-ErrorAction SilentlyContinue` → índice tratado como vazio (detalhe: ver seção 3.2) |

**Veredicto: ✅ O script registra erros e continua — não para em falhas parciais**

---

## 2. VALIDAÇÃO DE IDEMPOTÊNCIA

### 2.1 Guarda de CAS — Prevenção de Sobrescrita

**Linha 100:**
```powershell
$dest = Join-Path $CASRoot "$($Hash.ToLower()).bin"
if (Test-Path $dest) { return 'SKIP' }  # idempotente
```

- Verificação `Test-Path` antes de qualquer operação de cópia
- Retorno imediato `'SKIP'` sem tocar no arquivo existente
- A função chamadora não incrementa `$novoOk` em caso de SKIP, apenas `$ignorados`
- O hash é adicionado ao `$casHashes` em memória apenas em caso de `'OK'`, não de `'SKIP'` — mas o `Get-CASHashes` carrega do índice ao início do ciclo, então hashes já presentes no índice são filtrados antes mesmo de chegar ao `Invoke-IngestFile`

**Veredicto: ✅ Idempotência de CAS confirmada — objeto existente nunca é sobrescrito**

### 2.2 EventLog em Modo Append

**Linha 62:**
```powershell
Add-Content -LiteralPath $EventLog -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
```

- `Add-Content` abre em modo append — nunca trunca o arquivo existente
- Histórico de eventos acumulativo garantido

**Veredicto: ✅ `dna_events.jsonl` é append-only**

---

## 3. MATRIZ DE RISCOS

> **Status v0.13.1:** R4 e R5 foram mitigados pelo patch. Matriz atualizada.

| # | Risco | Severidade v0.13.0 | Severidade v0.13.1 | Mitigação v0.13.1 |
|---|-------|-------------------|-------------------|-------------------|
| R1 | Deleção acidental de dados | Baixa | **Baixa** | Inalterado — `Remove-Item` restrito a `$CASRoot\{hash}.bin` recém-criado |
| R2 | Loop infinito / saturação CPU | Baixa | **Baixa** | Inalterado — `Start-Sleep 300s`; `$IntervalSeg = 0` ainda sem guarda mínima (residual) |
| R3 | Sobrescrita de objeto CAS | Baixa | **Baixa** | Inalterado — `Test-Path $dest` → `return 'SKIP'` |
| R4 | Corrupção do `fractal_index.json` | **Média** | **✅ Eliminada** | `Set-IndexAtomic`: grava em `.tmp` → verifica parse → `.bak` do original → `Move-Item -Force` |
| R5 | Condição de corrida / múltiplas instâncias | **Média** | **✅ Eliminada** | Lock por PID em `watchdog.lock`; detecção de lock órfão; liberação em bloco `finally` |
| R6 | Filtro excessivo de CachePattern | Baixa | **Baixa** | Inalterado — regex no path completo pode excluir pastas com substring na lista |
| R7 | Bloqueio em `Get-FileHash` | Muito Baixa | **Muito Baixa** | Inalterado — `-ErrorAction SilentlyContinue` retorna null; arquivo ignorado |
| R8 | Índice órfão ausente | Muito Baixa | **Muito Baixa** | Inalterado — `Test-Path $OrfaoIndex` antes de carregar |
| R9 | Divergência CAS físico vs. índice | Muito Baixa | **✅ Endereçada** | `-ReconcileOnly` detecta e registra `.bin` sem entrada no índice; verifica integridade |

### Detalhe dos Patches v0.13.1

**R4 → `Set-IndexAtomic` (função nova):**
```powershell
function Set-IndexAtomic {
    param([object[]]$Index)
    $tmp = "$IndexPath.tmp"
    $bak = "$IndexPath.bak"
    $json = $Index | ConvertTo-Json -Depth 4
    Set-Content -LiteralPath $tmp -Value $json -Encoding UTF8 -ErrorAction Stop
    $verify = Get-Content $tmp -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $verify) { throw "Verificação JSON do .tmp falhou — original preservado" }
    if (Test-Path $IndexPath) { Copy-Item -LiteralPath $IndexPath -Destination $bak -Force }
    Move-Item -LiteralPath $tmp -Destination $IndexPath -Force -ErrorAction Stop
}
```

**R5 → `Invoke-AcquireLock` / `Invoke-ReleaseLock` + try/finally:**
```powershell
# Adquire lock com PID; aborta se PID ativo; limpa se PID morto (lock órfão)
Invoke-AcquireLock
try { ... ciclo principal ... }
finally { Invoke-ReleaseLock }
```

---

## 4. RESULTADO DO TESTE `-UmaVez`

**Comando:** `D:\TEIA_CORE\tools\TEIA-Sync-Watchdog.ps1 -UmaVez`
**Horário:** 21:57:20 → 21:57:35
**Duração:** 15.2 segundos

```
[WD 21:57:20] TEIA-Sync-Watchdog v0.13.0 iniciado
[WD 21:57:20] Pastas monitoradas: D:\bruto\TEIA\TEIA_Data | D:\bruto\TEIA\TEIA_ATLAS | ...
[WD 21:57:20] Ciclo iniciado
[WD 21:57:23] Novo objeto detectado: LICENSE.txt (E502C6B880FF58D6...)
[WD 21:57:23] Novo objeto detectado: __main__.py (5B36E11D74DB484E...)
[... dezenas de detecções ...]
[WD 21:57:35] Ciclo concluído — Novos ingeridos: 0 | Falhas: 0 | Ignorados: 4626 | 15.2s
```

**Resultado: ✅ SEM FALHAS**

**Análise do comportamento observado:**

O script detectou muitos "Novos objetos" mas não ingeriu nenhum (`Novos ingeridos: 0`). Isso confirma que a guarda de idempotência `Test-Path $dest` (linha 100) funcionou corretamente: os arquivos `.bin` correspondentes já existiam em `D:\TEIA_CORE\objects\`.

**Achado adicional — Divergência de estado CAS vs. Índice:**

Os objetos detectados como "novos" chegaram até `Invoke-IngestFile` porque seus hashes **não estavam em `fractal_index.json`** (o filtro `$casHashes.Contains($hash)` não os interceptou), mas os arquivos `.bin` **já existiam em disco**. Isso indica que o CAS contém objetos físicos cujos hashes não foram registrados no índice — provavelmente de ingestões anteriores que falharam após a cópia mas antes da atualização do JSON.

O watchdog tratou esse estado de forma **correta e segura**: detectou, tentou ingerir, encontrou o arquivo existente e retornou SKIP sem sobrescrever nem lançar erro.

**Impacto:** Baixo. Funcionalidade de recuperação de estado é válida.
**Recomendação:** Executar um ciclo de reconciliação que adicione ao `fractal_index.json` todos os hashes de `.bin` existentes em `objects\` que ainda não constam no índice.

---

## 5. VEREDICTO FINAL

| Contexto | Resultado |
|----------|-----------|
| **Ciclo único (`-UmaVez`)** | ✅ APROVADO — seguro para execução imediata |
| **Ciclo contínuo sem carga concorrente** | ✅ APROVADO — R4 existe mas probabilidade baixa em uso mono-instância |
| **Ciclo contínuo com múltiplas instâncias** | ⚠️ REPROVADO — R4+R5 combinados podem corromper `fractal_index.json` |
| **Produção de longo prazo** | ⚠️ REQUER PATCH — implementar escrita atômica (R4) e lock de instância (R5) |

O script é **funcionalmente correto e seguro para uso imediato em ciclo único**. Os dois riscos médios (R4, R5) são relevantes apenas para cenários de alta disponibilidade ou múltiplas instâncias simultâneas.
