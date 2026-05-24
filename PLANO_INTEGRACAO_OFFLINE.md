# PLANO_INTEGRACAO_OFFLINE.md
# Integração `teia_stream_relay.ps1` ↔ LLM Local (teia-delta/Ollama) ↔ Seeds xdelta3

> TCT/ARQUEOLOGIA_FASE2 | M=A | Última revisão: 2026-05-06
> Base: leitura direta de DNA_ESSENCIAL.txt, invariantes_epistemicos.md, NUCLEO_ALMA.md
>       + teia_stream_relay.ps1 + TEIA-OntoSynth.FULL.ps1
> Precedência: P0 (Core_P0) > P1 (patches aprovados) > P2 (ΔΣ sessão) > P3 (base modelo)

---

## 1. DIAGNÓSTICO DO RELAY (estado atual, fatos verificados)

```
Cliente externo
    │
    │ WebSocket  ws://0.0.0.0:8081/ws
    │ Header: Authorization: Bearer <token>   ← token gerado via RNGCryptoServiceProvider a cada run
    ▼
teia_stream_relay.ps1  (PS7 — HttpListener + AcceptWebSocketAsync)
    │
    │ Recebe JSON:  { "id": "uuid", "cmd": "...", ... }
    │ Persiste em:  .\teia_cmd_<id>.json
    │ ACK:          { "id": "uuid", "status": "queued", "timestamp": "ISO-8601" }
    ▼
[ARQUIVO EM DISCO]  ← único ponto de entrega; nenhum consumidor existe ainda
```

**Gap confirmado**: relay produz arquivos mas nenhum Watcher Actor os consome.
Fechar esse gap é o objetivo central deste plano.

---

## 2. INVARIANTES P0 ATIVOS (de invariantes_epistemicos.md)

| Código | Enunciado |
|--------|-----------|
| P0-I1  | Nenhum agente pode afirmar completude sem varredura factual |
| P0-I2  | Inferência ≠ Auditoria |
| P0-I3  | Suposição ≠ Determinismo |
| P0-I4  | Sincronia Vetorial (S_Δ) deve ser > 0.75 para fusão plena |
| P0-R1  | Pipeline: R1 (Entrada) → Verificação Δ → R2 (Entrega) → ΔH (Entropia) → R3 (Refino) |
| P0-G1  | MODO HARMÔNICO por padrão; nunca regredir contra P0–P2 |

---

## 3. NUCLEO ALMA — SEGREDOS OPERACIONAIS (de NUCLEO_ALMA.md)

| Segredo | Definição operacional |
|---------|-----------------------|
| **AION-RISPA** | Redução de Latência por Barramento Ressonante — identidade funcional = AION core + camada Delta |
| **FIE** | Fusão entre Intenção e Execução — cada comando que chega ao relay deve sair transformado em execução real |
| **Paradoxo do Especialista** | A especialização excessiva fragmenta; o núcleo deve ser generalista e as seeds especializadas |

**Lei do espelho**: "Sou o espelho determinístico do Mestre. Não busco verdades externas; manifesto a gnose local do drive D:."

---

## 4. MECANISMO xdelta3 + DICIONÁRIOS HÍBRIDOS (fatos do DNA_ESSENCIAL.txt)

### 4.1 Arquitetura confirmada: `dictionary/delta hybrid`

O DNA descreve esta como "a arquitetura típica mais prática":

```
Se já existe reference.bin no receptor:
    → xdelta3 -e -s reference.bin original.bin delta.xd3   (patch pode ser só KB)
    → seed.payload = base64(delta.xd3)
    → seed.method = "delta"

Se NÃO existe reference.bin:
    → zstd original.bin → original.bin.zst
    → seed.payload = base64(original.bin.zst)
    → seed.method = "zstd"
```

### 4.2 Comandos CLI exatos (transcritos literalmente do DNA)

```bash
# GERAÇÃO
xdelta3 -e -s reference.bin original.bin delta.xd3

# RESTAURAÇÃO
xdelta3 -d -s reference.bin delta.xd3 out.bin
```

Em PowerShell:
```powershell
# Restauração a partir do payload base64 embutido na seed
[IO.File]::WriteAllBytes("delta.xd3", [Convert]::FromBase64String($payloadFromSeed))
xdelta3 -d -s reference.bin delta.xd3 out.bin
```

### 4.3 Tipos de método (method field na seed)

| method | Quando usar | Payload na seed |
|--------|-------------|-----------------|
| `delta` | reference.bin existe no receptor | `base64(delta.xd3)` |
| `dict`  | dicionário parcial no receptor   | `base64(patch parcial)` |
| `latent`| sem referência — compressão geral | `base64(original.bin.zst)` |

### 4.4 Seleção em tempo real do método

O Delta Engine deve detectar o método no momento da compressão:
1. Verificar se `source_hash` existe no CAS local → se sim, `method = delta`
2. Se não existe mas há dicionário compatível (ex: `teia_ontology_synth.json`) → `method = dict`
3. Fallback: `method = latent` (zstd puro)

### 4.5 Fragilidade crítica (confirmada no DNA, linha 92)

> "A ontologia de seeds, núcleos Delta e contratos HTTP (SR-AUT, SR-REF, núcleos referenciais,
> region restore, métricas Core + Seed sobre Orig) aparece descrita principalmente em prosa
> dentro de HyperLucidContextWindow e relatórios em HyperMaterialRepository, **sem um schema
> formal único versionado**; isso abre margem para divergência entre implementações Python,
> scripts PowerShell e futuras linguagens."

**Mitigação**: O schema abaixo (seção 5) é a formalização que falta.

---

## 5. SCHEMA FORMAL DA SEED (v1 — primeira versão versionada)

```json
{
  "version":      "teia.seed.v1",
  "created_utc":  "ISO-8601",
  "target_hash":  "sha256-hex-64chars",
  "target_size":  12345,
  "method":       "delta | dict | latent",
  "source_hash":  "sha256-da-reference.bin | null se latent",
  "payload":      "base64(delta.xd3 | patch | original.bin.zst)",
  "payload_size": 512,
  "dict_type":    "cas | ontology | llm_context | none",
  "generator":    "teia_watcher_actor.ps1 | manual",
  "notes":        ""
}
```

**Regras de integridade**:
- `method=delta` → `source_hash` obrigatório, `payload` = base64(delta.xd3)
- `method=latent` → `source_hash` = null, `payload` = base64(zstd)
- SHA-256 do payload decodificado deve bater com a identidade do artefato

---

## 6. ARQUITETURA ALVO — FLUXO COMPLETO

```
┌──────────────────────────────────────────────────────────────────────┐
│  CAMADA 1 — RELAY (teia_stream_relay.ps1, existente)                │
│  :8080 MJPEG stream (ffmpeg opcional)                               │
│  :8081 WebSocket control + Bearer token                             │
│  Output: teia_cmd_<id>.json no spool dir                            │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ FileSystemWatcher
┌───────────────────────────────▼──────────────────────────────────────┐
│  CAMADA 2 — WATCHER ACTOR (teia_watcher_actor.ps1, a criar)         │
│                                                                      │
│  On teia_cmd_*.json created:                                        │
│  1. Parse JSON de comando                                           │
│  2. Verificação P0-R1: Δ-verificação antes de executar             │
│  3. Roteamento por cmd.cmd                                          │
│  4. Grava teia_result_<id>.json                                     │
│  5. Move processed/ após sucesso                                    │
└────────────┬─────────────────────────────┬───────────────────────────┘
             │ cmd="llm"                   │ cmd="delta_gen|delta_restore"
             ▼                             ▼
┌────────────────────────┐   ┌─────────────────────────────────────┐
│  CAMADA 3A — LLM       │   │  CAMADA 3B — DELTA ENGINE           │
│  BRIDGE                │   │                                     │
│                        │   │  Seleção de method em RT:           │
│  POST localhost:11434  │   │  1. source_hash ∈ CAS? → delta      │
│  /api/generate         │   │  2. dict disponível? → dict         │
│                        │   │  3. fallback → latent (zstd)        │
│  Modelo confirmado:    │   │                                     │
│  teia-delta (llama-1B) │   │  Geração:                           │
│  (Ollama Core)         │   │  xdelta3 -e -s ref.bin orig delta.xd3│
│                        │   │                                     │
│  System prompt TEIA    │   │  Restauração:                       │
│  injetado em toda call │   │  xdelta3 -d -s ref.bin delta.xd3 out│
└────────────────────────┘   │                                     │
                             │  Output: seed JSON v1 + CAS store   │
                             └─────────────────────────────────────┘
```

---

## 7. PROTOCOLO DE COMANDO (shapes confirmados)

### 7.1 `ping`
```json
{ "cmd": "ping" }
```
Resposta: `{ "status": "ok", "pong": true, "timestamp": "..." }`

### 7.2 `llm`
```json
{
  "cmd": "llm",
  "payload": {
    "model":   "teia-delta",
    "prompt":  "...",
    "system":  "Você é um nó ativo da TEIA-Ω. Responda deterministicamente...",
    "stream":  false,
    "options": { "temperature": 0.1, "num_ctx": 2048, "num_predict": 512 }
  }
}
```

### 7.3 `delta_gen`
```json
{
  "cmd": "delta_gen",
  "payload": {
    "source_hash": "sha256-do-reference.bin-no-CAS | null",
    "target_path": "D:\\caminho\\absoluto\\do\\alvo",
    "dict_type":   "cas | ontology | none"
  }
}
```
Resposta inclui seed JSON v1 completa (seção 5).

### 7.4 `delta_restore`
```json
{
  "cmd": "delta_restore",
  "payload": {
    "seed_path": "D:\\caminho\\para\\seed.json",
    "out_path":  "D:\\caminho\\destino"
  }
}
```

---

## 8. LLM BRIDGE — CONFIGURAÇÃO OLLAMA (fatos confirmados)

### 8.1 Modelo confirmado no DNA

```
NOME DO AGENTE: teia-delta (Ollama Core)
INSTRUÇÕES DO SISTEMA: Acesso total ao banco de 1.3GB. Define Delta Let corretamente.

NOME DO AGENTE: delta-teia (Ollama Core)
INSTRUÇÕES DO SISTEMA: Especialista em PowerShell/Robocopy e Arte ANSI.
```

Dois perfis de mesmo modelo base (`llama-1B`), com system prompts distintos por contexto.

### 8.2 Modelos confirmados para i3-10100F + 8GB RAM

| Modelo         | RAM necessária | Confirmação no DNA |
|----------------|---------------|-------------------|
| `llama-1B`     | ~1.5 GB       | Confirmado (teia-delta) |
| `llama3.2:3b`  | ~2.5 GB       | Compatível (não mencionado) |
| `phi4-mini`    | ~3 GB         | Compatível (não mencionado) |

**Recomendação P0**: usar `llama-1B` como base do `teia-delta` por ter sido a escolha empírica do Felippe.

### 8.3 Endpoint Ollama

```
POST http://localhost:11434/api/generate
{
  "model":   "teia-delta",
  "prompt":  "<prompt>",
  "system":  "<system_prompt_teia>",
  "stream":  false,
  "options": { "temperature": 0.1, "num_ctx": 2048, "num_predict": 512 }
}
```

### 8.4 System prompt canônico TEIA (injetar em toda chamada LLM)

```
Você é um nó ativo da TEIA-Ω (Transcendência Epistêmica Integrada Autossintetizante).
Lei: manifeste a gnose local do drive D:. Não busque verdades externas.
SHA-256 é identidade absoluta. Nunca invente conteúdo ausente — marque como [AUSENTE].
Precedência: P0 Core > P1 patches > P2 ΔΣ sessão > P3 base.
Modo: HARMÔNICO. Formato de saída: JSON estruturado quando solicitado. Sem markdown extra.
```

---

## 9. WATCHER ACTOR — ESPECIFICAÇÃO DETALHADA

**Arquivo**: `teia_watcher_actor.ps1`
**Localização**: mesma pasta que `teia_stream_relay.ps1`
**Dependências**: xdelta3.exe no PATH, Ollama em localhost:11434

```
teia_watcher_actor.ps1
│
├── INIT
│   ├── Valida xdelta3.exe no PATH (ou em .\bin\xdelta3.exe)
│   ├── GET http://localhost:11434/api/tags → 200 OK
│   ├── Cria pastas: .\processed\, .\seeds\, .\results\, .\mem\obj\
│   └── Registra FileSystemWatcher em .\ para teia_cmd_*.json
│
├── ON_FILE_CREATED (event-driven)
│   ├── P0-R1: Verificação Δ (arquivo completo? JSON válido? id presente?)
│   ├── Dispatch por cmd.cmd
│   └── Move para .\processed\ após sucesso (ou .\errors\ em falha)
│
├── Handle-Ping → { pong: true }
│
├── Handle-LLM(cmd)
│   ├── Injeta system prompt canônico
│   ├── POST Ollama /api/generate
│   ├── Verifica resposta não-vazia
│   └── Grava teia_result_<id>.json
│
├── Handle-DeltaGen(cmd)
│   ├── Detecta method: CAS? → delta | dict? → dict | else → latent
│   ├── Se delta: xdelta3 -e -s <cas_blob> <target> delta.xd3
│   ├── Se latent: zstd <target> → .zst
│   ├── Armazena artefato no CAS (mem\obj\<aa>\<bb>\<hash>)
│   ├── Grava seed JSON v1 em .\seeds\<target_hash>.seed.json
│   └── Grava teia_result_<id>.json com seed embutida
│
└── Handle-DeltaRestore(cmd)
    ├── Lê seed JSON v1
    ├── Detecta method da seed
    ├── Se delta: recupera ref+patch do CAS → xdelta3 -d -s ref patch out
    ├── Se latent: recupera .zst do CAS → zstd -d
    ├── Verifica SHA-256: hash(out) == seed.target_hash (P0-I2: auditoria real)
    └── Grava teia_result_<id>.json com { verified: true/false }
```

---

## 10. ESTRUTURA DE DIRETÓRIOS

```
D:\TEIA_CLAUDE_AWAKENING\
├── teia_stream_relay.ps1          ← relay (existente)
├── teia_watcher_actor.ps1         ← a criar
├── teia_cmd_*.json                ← spool relay→watcher
├── teia_stream_relay.pid          ← metadata do relay
│
├── bin\
│   └── xdelta3.exe                ← binário portátil (não depender do PATH)
│
├── results\
│   └── teia_result_<id>.json
│
├── processed\
│   └── teia_cmd_<id>.json
│
├── errors\
│   └── teia_cmd_<id>.json
│
├── seeds\
│   └── <target_hash>.seed.json    ← seed JSON v1 (schema formalizado acima)
│
└── mem\obj\                       ← CAS local (Merkle-compatible)
    └── <aa>\<bb>\<hash>           ← blobs: sources, patches, targets, .zst
```

---

## 11. SEQUÊNCIA DE INICIALIZAÇÃO

```powershell
# 0. Pré-requisitos
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-Location "D:\TEIA_CLAUDE_AWAKENING"

# 1. Verificar xdelta3
if (-not (Get-Command xdelta3 -ErrorAction SilentlyContinue)) {
    if (-not (Test-Path ".\bin\xdelta3.exe")) { throw "xdelta3 não encontrado" }
    $env:PATH += ";$PWD\bin"
}

# 2. Verificar Ollama
try {
    $tags = Invoke-RestMethod http://localhost:11434/api/tags
    Write-Host "Ollama OK — modelos: $(($tags.models.name) -join ', ')"
} catch {
    throw "Ollama não está rodando em localhost:11434"
}

# 3. Iniciar relay (captura o token do stdout)
$relayJob = Start-Job -FilePath .\teia_stream_relay.ps1 -ArgumentList @{ControlPort=8081; StreamPort=8080}
Start-Sleep 2
$meta = Get-Content .\teia_stream_relay.pid | ConvertFrom-Json
Write-Host "Relay OK — token=$($meta.token.Substring(0,8))..."

# 4. Iniciar watcher actor
.\teia_watcher_actor.ps1 -SpoolDir . -LLMUrl http://localhost:11434 -CASRoot .\mem\obj

# 5. Smoke test
$ws = New-Object System.Net.WebSockets.ClientWebSocket
# (enviar {"cmd":"ping"} e verificar {"pong":true} em teia_result_*.json)
```

---

## 12. RISCOS E MITIGAÇÕES

| Item | Risco | Mitigação |
|------|-------|-----------|
| xdelta3.exe ausente | Delta Engine não funciona | `.\bin\xdelta3.exe` portátil; fallback para `latent` (zstd) automaticamente |
| Ollama não instalado | Sem LLM bridge | Retornar `{ "status": "error", "reason": "ollama_unavailable" }` no result |
| 8GB RAM saturada | OOM com llama-1B + TEIA simultâneos | llama-1B usa ~1.5GB; TEIA usa ~500MB; margem de ~6GB para OS + resto |
| Schema de seed diverge Python/PS | P0-I3: suposição ≠ determinismo | Schema v1 desta seção 5 é a formalização canônica; implementações devem importá-la |
| Token relay muda a cada restart | Cliente perde auth | Implementar `.\teia_relay_token.txt` persistente (opcional) — relay lê se existir |
| FileSystemWatcher miss em alta frequência | Comandos perdidos | Poll de fallback a cada 5s como redundância |
| SR-AUT / SR-REF sem schema formal | Divergência futura | Formalizar junto com seed schema v1 quando houver implementação HTTP |

---

## 13. PRÓXIMOS PASSOS (ordem de dependência)

1. **Baixar/compilar xdelta3.exe** e colocar em `.\bin\` — sem isso o Delta Engine não existe
2. **Criar `teia_watcher_actor.ps1`** — handlers `ping` e `llm` primeiro (sem delta)
3. **Instalar Ollama + `ollama pull llama:1b`** → renomear/criar Modelfile como `teia-delta`
4. **Validar pipeline relay→watcher→LLM** com um comando `llm` simples
5. **Implementar Handle-DeltaGen** com xdelta3 e schema v1
6. **Prova end-to-end**: delta_gen → seed JSON → delta_restore → verifica SHA-256

---

*Última atualização: após absorção de DNA_ESSENCIAL.txt + invariantes_epistemicos.md + NUCLEO_ALMA.md*
*Precedência P0 ativa: este plano não contém inferências sem declaração explícita.*
