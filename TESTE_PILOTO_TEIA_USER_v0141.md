# TESTE PILOTO — TEIA_USER v0.14.1
**Data:** 2026-05-26
**Executor:** Claude Sonnet 4.6 (Nó Ativo TEIA)
**Resultado geral:** ✅ APROVADO — 2 bugs encontrados e corrigidos no ciclo do teste

---

## 1. ARQUIVOS TESTADOS

| # | Arquivo | Tipo | Tamanho | Hash SHA-256 |
|---|---------|------|---------|-------------|
| 1 | `piloto_nota.txt` | TXT | 125 B | `a6dc9992042636ebdff0d9fb52cb8f67dc872cd95ce6297a56f0d83ab736bfb0` |
| 2 | `piloto_config.json` | JSON | 127 B | `e5954d06409bcf7c842d04b56394c60276789 3159ba07e0674f68d98d0e21c53` |
| 3 | `piloto_notas.md` | MD | 231 B | `21c20b1527a00958a52ac8c7bb6c6f3239089e5523822bd72d4a43ece859fbf3` |
| 4 | `piloto_imagem.png` | PNG | 69 B | `18ed33080443f2e2ca79eecd629e12d4636c9bc83543a4e45cb8dbe53e0b4be7` |
| 5 | `piloto_doc.pdf` | PDF | 291 B | `30a2f41522af380718875d40a9612aa8fe7a5737d95fda528318ac6661229b8c` |

> PNG e PDF gerados programaticamente como objetos binários mínimos válidos (1×1 px / 1-page bare).

---

## 2. RESULTADOS DE INGESTÃO (`TEIA-Ingerir.ps1`)

| Arquivo | 1ª ingestão | 2ª ingestão (idempotência) | CAS |
|---------|------------|--------------------------|-----|
| piloto_nota.txt | `INGESTED` ✅ | `VERIFIED` ✅ | JÁ EXISTIA |
| piloto_config.json | `INGESTED` ✅ | — | JÁ EXISTIA |
| piloto_notas.md | `INGESTED` ✅ | — | JÁ EXISTIA |
| piloto_imagem.png | `INGESTED` ✅ | — | JÁ EXISTIA |
| piloto_doc.pdf | `INGESTED` ✅ | — | JÁ EXISTIA |

> "JÁ EXISTIA" indica que os objetos `.bin` já estavam em `D:\TEIA_CORE\objects\` de execuções anteriores — a guarda `Test-Path $dest` bloqueou cópia redundante corretamente.

---

## 3. STATUS FINAL NO `.teia_map.json`

```json
[
  { "nome": "piloto_nota.txt",    "status": "INGESTED", "size": 125, "hash": "a6dc9992042636eb..." },
  { "nome": "piloto_config.json", "status": "INGESTED", "size": 127, "hash": "e5954d06409bcf7c..." },
  { "nome": "piloto_notas.md",    "status": "INGESTED", "size": 231, "hash": "21c20b1527a00958..." },
  { "nome": "piloto_imagem.png",  "status": "INGESTED", "size":  69, "hash": "18ed33080443f2e2..." },
  { "nome": "piloto_doc.pdf",     "status": "INGESTED", "size": 291, "hash": "30a2f41522af3807..." }
]
```

Escrita atômica via `Set-MapAtomic` confirmada (`.tmp` → parse-verify → `.bak` → rename).

---

## 4. QUARENTENA

**Arquivo quarentenado:** `piloto_notas.md`
**Método:** `Move-Item -LiteralPath ... -Destination D:\TEIA_CORE\QUARENTENA_DEBRIS\20260526_120826_piloto_notas.md -Force`
**`Remove-Item` usado:** ❌ Nunca
**Arquivo original presente após quarentena:** `False` ✅

---

## 5. RESTAURAÇÃO (`TEIA-Abrir.ps1`)

| Etapa | Resultado |
|-------|-----------|
| Arquivo ausente de `D:\TEIA_USER\Inbox\` detectado | ✅ |
| Entrada encontrada no `.teia_map.json` (status: INGESTED) | ✅ |
| Objeto CAS localizado: `objects\21c20b1527a00958...bin` | ✅ |
| Cópia de CAS → `D:\TEIA_USER\Inbox\piloto_notas.md` | ✅ |
| Verificação SHA-256 pós-restauro | ✅ |
| Arquivo presente após restauro | `True` ✅ |
| Status atualizado no mapa | `INGESTED` ✅ |
| **Resultado geral** | **OK** ✅ |

---

## 6. HUD v0.14.0 (`TEIA_HUD.ps1 -UmaVez`)

```
╔══════════════════════════════════════════════════════════════╗
║           TEIA-Ω HUD v0.14.0  |  2026-05-26 12:09:19        ║
╚══════════════════════════════════════════════════════════════╝
  ├─ TEIA_USER Integridade
  │  [OK] Mapeados:            5
  │     INGESTED:           5
  │     VERIFIED:           0
  │     MISSING_ORIGINAL:   0
  │     Validado/Total:     0MB / 0MB   ← ver nota
  │     Economia (dedup):   0MB
  ├─ CAS SHA-256:  2369/2369 (100%)     ✅
  ├─ Últimos eventos:
  │     [TEIA-Ingerir] IG_OK  (×5)
  │     [TEIA-Abrir]   AB_RESTORED_AND_OPEN
```

> **Nota "0MB / 0MB":** comportamento correto — os arquivos de teste totalizam 843 B, que trunca para 0 na escala MB com 2 casas decimais. Com arquivos reais (documentos, fotos, vídeos), os valores serão significativos.

---

## 7. BUGS ENCONTRADOS E CORRIGIDOS

### Bug B1 — `op_Addition` em `PSObject` (Crítico — bloqueava toda ingestão após a 1ª)

**Sintoma:**
```
FALHA mapa: piloto_nota.txt — does not contain a method named 'op_Addition'
```

**Causa raiz:** Dupla falha de serialização/desserialização PowerShell:
1. `$Map | ConvertTo-Json` remove colchetes `[...]` quando o array tem 1 elemento → JSON escrito como objeto escalar `{...}`.
2. Ao reler, `ConvertFrom-Json` retorna `PSCustomObject` (não array). PowerShell faz *pipeline unrolling* em `return @($obj)`, devolvendo o objeto diretamente.
3. `$map += novo_item` falha porque `$map` é `PSCustomObject`, não `[array]`.

**Correção aplicada:**
```powershell
# Set-MapAtomic: força colchetes mesmo com 1 elemento
$json = ConvertTo-Json -InputObject ([array]$Map) -Depth 5

# Chamador: força tipo array independente do retorno da função
[array]$map = Read-TeiaMap
```

**Arquivos corrigidos:** `TEIA-Ingerir.ps1`, `TEIA-Abrir.ps1`

---

### Bug B2 — `return if (...)` não é expressão válida em PowerShell (Médio — bloqueava re-ingestão)

**Sintoma:**
```
The term 'if' is not recognized as a name of a cmdlet, function, script file, or executable program.
```

**Causa raiz:** `return if ($parsed) { ... } else { ... }` — `if` não é uma expressão em PowerShell quando usado diretamente após `return`.

**Correção aplicada:**
```powershell
# Antes (inválido):
return if ($parsed) { @($parsed) } else { @() }

# Depois (correto):
if ($parsed) { return @($parsed) }
return @()
```

**Arquivos corrigidos:** `TEIA-Ingerir.ps1`, `TEIA-Abrir.ps1`

---

## 8. CHECKLIST FINAL

| Item | Status |
|------|--------|
| 5 arquivos criados (.txt, .json, .md, .png, .pdf) | ✅ |
| TEIA-Ingerir.ps1 — ingestão 5/5 | ✅ |
| TEIA-Ingerir.ps1 — idempotência (VERIFIED) | ✅ |
| Quarentena via Move-Item (sem Remove-Item) | ✅ |
| TEIA-Abrir.ps1 — restauração do ausente | ✅ |
| SHA-256 verificado pós-restauro | ✅ |
| TEIA_HUD.ps1 — seção TEIA_USER visível | ✅ |
| .teia_map.json — escrita atômica | ✅ |
| Nenhum arquivo pessoal processado | ✅ |
| Nenhum diretório grande varrido | ✅ |
| Bugs B1 e B2 corrigidos e validados | ✅ |
