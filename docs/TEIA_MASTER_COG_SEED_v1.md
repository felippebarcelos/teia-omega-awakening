# TEIA_MASTER_COG_SEED_v1.md
## Semente de Transferência Cognitiva Mestre

> **Ciclo encerrado:** P11.x (v0.80.5)  
> **Próximo ciclo:** P13.0  
> **Data de selagem:** 2026-05-30  
> **Operador:** Felippe Barcelos — felippe.barcelos10@gmail.com  
> **Repositório Git:** D:\TEIA_CLAUDE_AWAKENING → github.com/felippebarcelos/teia-omega-awakening  

---

## BLOCO 0 — SYSTEM PROMPT PARA A PRÓXIMA IA

**Leia este bloco inteiro antes de qualquer ação.**

Você é um nó ativo da TEIA-Omega (Transcendência Epistêmica Integrada Autossintetizante). Ao assumir esta sessão:

1. **Leia `CLAUDE.md`** em `D:\TEIA_CLAUDE_AWAKENING\CLAUDE.md` — é sua memória procedural canônica.
2. **Nunca invente estado.** Se um arquivo, hash ou serviço não foi confirmado, declare `[AUSENTE]`.
3. **Delta é sempre por extenso.** O símbolo matemático Δ é proibido em todo código, log e documento gerado por você.
4. **SHA-256 é identidade absoluta.** A invariante Write==Read deve ser verificada em todo artefato que você gera ou modifica.
5. **Leia os scripts em** `D:\TEIA_CORE\tools\` antes de propor qualquer mudança — eles são a realidade, não esta semente.
6. **Paths absolutos sempre.** Nunca use paths relativos. Raiz de trabalho: `D:\TEIA_CLAUDE_AWAKENING`.
7. **Idempotência.** Todo script deve ser seguro para re-execução: stub existente = skip.
8. **Contenção P11.0.** O System Manager opera SOMENTE sobre `D:\TEIA_USER\MyRealData\`. Qualquer WatchDir que não contenha essa string é rejeitado (`-notmatch 'MyRealData'`).
9. **OOM Guard.** Buffers de I/O fixos em 64 KB. Nunca carregar arquivo inteiro em RAM exceto quando explicitamente necessário (gen.procedural Runspace).
10. **Ollama local.** O LLM é `qwen2.5-coder:7b` em `http://localhost:11434`. Ollama deve estar rodando para AutoSynth funcionar — verifique antes de invocar.

---

## BLOCO 1 — ARQUITETURA VALIDADA (v0.80.5)

### 1.1 Mapa de Componentes

```
┌─────────────────────────────────────────────────────────────┐
│  TEIA-Dogfooding-Dashboard.ps1  (v0.80.5)                   │
│  CLI wrapper — orquestrador puro, sem lógica de engenharia  │
│  Opções: [1]Status [2]IniciarVFS [3]PararVFS [4]Ingestão    │
│          [5]Economia [6]Sair [7]AbrirExplorer               │
│  Zombie Hunter: Get-CimInstance Win32_Process | TEIA-VFS    │
└──────────────────────┬──────────────────────────────────────┘
                       │ orquestra
           ┌───────────┴───────────┐
           ▼                       ▼
┌──────────────────────┐  ┌──────────────────────────────────┐
│ TEIA-System-Manager  │  │ TEIA-VFS-WinFsp-v0800.ps1        │
│ v0800.ps1  (19.6 KB) │  │ (v0.80.2 — 25.9 KB)              │
│                      │  │                                  │
│ FSW + ConcurrentQueue│  │ WebDAV daemon HTTP port 8767     │
│ NeuroPlanner HR1-HR6 │  │ net use Z: \\localhost@8767\...  │
│ AutoSynth invocation │  │ Hot-reload manifesto cada 5s     │
│ CAS write + stub     │  │ Serve stubs como originais       │
│ -ProcessExisting mode│  │ OOM Guard: buffer fixo 64KB      │
└──────────┬───────────┘  └──────────┬───────────────────────┘
           │                          │ lê stubs
           │ invoca                   │
           ▼                          ▼
┌──────────────────────┐  ┌──────────────────────────────────┐
│ TEIA-AutoSynth       │  │ CAS  D:\TEIA_CORE\objects\       │
│ v0710.ps1  (33.9 KB) │  │ {sha[0:2]}\{sha[2:4]}\{sha}{ext}│
│                      │  │                                  │
│ FASE 1-2: análise    │  │ 2652 objects | 32.4 MB           │
│ FASE 3: Ollama LLM   │  │ Extensões: .gz .br .teia_seed    │
│ FASE 4: Runspace SHA │  │             .raw                  │
│ FASE 4.5: Eficiência │  │                                  │
│ FASE 5: cristalizar  │  │ Decoders P1 Patch:               │
│ -ResultFile JSON     │  │ D:\TEIA_CORE\decoders\           │
│ -Silent suprime saída│  └──────────────────────────────────┘
└──────────────────────┘
```

### 1.2 NeuroPlanner — Regras de Roteamento (HR1-HR6)

O NeuroPlanner está **inline** no System Manager v0800, função `Get-NeuroRoute`:

| Regra | Condição | Estratégia | CAS ext |
|-------|----------|-----------|---------|
| HR1 | Todos os bytes idênticos (`$bytes \| Select -Unique`).Count == 1 | `gen.repeat` | `.teia_seed` |
| HR2 | Padrão periódico detectado (`Detect-Period` ≤ 64B) | `gen.pattern` | `.teia_seed` |
| HR3 | Entropia ≥ 7.0 (dados binários aleatórios) | `cas.raw` | `.raw` |
| HR4 | Magic bytes de binário conhecido (PNG, PDF, ZIP, EXE...) | `cas.raw` | `.raw` |
| HR5 | Tamanho < 8192 bytes | `cmp.brotli` | `.br` |
| HR6 | Contém coordenadas OBJ (`v `, `vt `, `f `) | `gen.parametric_mesh` | `.teia_seed` |
| LLM_FALLBACK | Qualquer outro caso | `cmp.lzma` | `.gz` |

**AutoSynth é chamado ANTES do NeuroPlanner** para arquivos com: `tamanho ≤ 8192 AND entropia ≤ 4.8 AND extensão não em SKIP_EXT AND AutoSynthScript existe`.

### 1.3 AutoSynth — Julgamento de Eficiência (FASE 4.5)

O P1 Patch (decoder + semente) só é cristalizado se:
```
tamanho(decoder_ps1 + seed.json) < min(GZip_Optimal, Brotli_Optimal)
AND SHA-256(gerado_pelo_decoder) == SHA-256(original)
```

Resultado `$ResultFile` JSON tem campo `verdict`: `ONTOPROCEDURAL | CLASSICAL | FAILED`.

Experiência do P11.1: para arquivos < 600 bytes bem estruturados (JSON, configs), Brotli-Optimal sempre vence. O AutoSynth nunca cristalizou em produção durante o dogfooding.

### 1.4 VFS — Estratégias de Reconstrução

| Estratégia | Leitor no VFS | Complexidade RAM |
|-----------|--------------|-----------------|
| `gen.repeat` | `Read-GenRepeat` — loop de byte fixo | O(1) |
| `gen.pattern` | `Read-GenPattern` — offset % period | O(period) |
| `gen.procedural` | `Read-GenProcedural` — Runspace isolado 30s | O(arquivo) + GC |
| `cmp.lzma` | `Get-DecompressedCache` + `Read-CasRaw` | Cache em `.dec` |
| `cmp.brotli` | `Get-DecompressedCache` + `Read-CasRaw` | Cache em `.dec` |
| `cas.raw` | `Read-CasRaw` — stream direto | O(1) streaming |

**Hot-reload:** `Invoke-ManifestRefreshIfDue` verifica `$script:manifestSW.Elapsed.TotalSeconds ≥ ManifestRefreshSeconds` no início de cada PROPFIND/GET/HEAD. Scan de stubs < 15ms. O Windows Explorer vê novos arquivos sem restart do VFS.

### 1.5 Dashboard — Zombie Hunter

`Invoke-ZombieHunt`:
```powershell
Get-CimInstance Win32_Process |
    Where-Object { $_.CommandLine -match 'TEIA-VFS' } |
    ForEach-Object { Invoke-CimMethod -InputObject $_ -MethodName Terminate }
Start-Sleep -Milliseconds 600
```
Chamado em `Start-VFSDrive` (antes) e `Stop-VFSDrive` (durante). Elimina órfãos de sessões anteriores que travavam a porta 8767.

---

## BLOCO 2 — ESTADO DA ARTE: A ILUSÃO CRIPTOGRÁFICA

### 2.1 O Que Foi Provado

O Windows Explorer, o PowerShell e qualquer aplicação Win32 que acesse `Z:\` recebem:
- `(Get-Item).Length` → `original_size_bytes` (stub com 200 bytes reporta como 3.838 bytes)
- `Copy-Item Z:\arquivo.log D:\destino\` → bytes idênticos ao original
- `Get-FileHash Z:\arquivo.log -Algorithm SHA256` → hash idêntico ao original

Isso foi validado com **13/13 PASS** no dogfooding P11.1 e **1/1 PASS** no hot-reload P11.2.

### 2.2 Métricas do Dogfooding P11.1 (2026-05-29)

**Corpus:** `D:\TEIA_USER\MyRealData\Dogfood_01\` — 13 arquivos

| Arquivo | Estratégia | Orig (B) | CAS (B) | Delta Economia |
|---------|-----------|---------|--------|---------------|
| metrics_app.log | **gen.pattern** | 3.838 | 177 | **95,4%** |
| data_report.csv | cmp.brotli | 1.807 | 186 | 89,7% |
| plane.obj | cmp.brotli | 546 | 198 | 63,7% |
| sphere_low.obj | cmp.brotli | 608 | 262 | 56,9% |
| benchmark_results.json | cmp.brotli | 417 | 191 | 54,2% |
| api_endpoints.json | cmp.brotli | 382 | 179 | 53,1% |
| cube.obj | cmp.brotli | 572 | 269 | 53,0% |
| schema_def.json | cmp.brotli | 359 | 199 | 44,6% |
| bootstrap.py | cmp.brotli | 764 | 457 | 40,2% |
| package_meta.json | cmp.brotli | 434 | 266 | 38,7% |
| app_config.json | cmp.brotli | 319 | 199 | 37,6% |
| deploy_config.cfg | cmp.brotli | 168 | 108 | 35,7% |
| readme_dogfood.txt | cmp.brotli | 436 | 303 | 30,5% |
| **TOTAL** | | **10.650** | **2.994** | **71,9%** |

### 2.3 Estado Real do CAS (2026-05-30)

```
D:\TEIA_CORE\objects\    2.652 objetos | 32,4 MB
D:\TEIA_USER\MyRealData\ 20 stubs ativos
Estratégias em produção: cmp.brotli (14), cmp.lzma (3), cas.raw (2), gen.pattern (1)
Delta economia global:   485.923 B / 4.831.275 B = 10,1%
```

### 2.4 Pitfalls Identificados e Resolvidos

| Pitfall | Causa | Solução |
|---------|-------|---------|
| `$path:` parser error | PowerShell interpreta `$var:` como drive-qualified | Usar `${var}:` |
| VFS manifest estático | Build-Manifest chamado só no startup | Hot-reload via Stopwatch no request path |
| Zumbis travando porta 8767 | `$script:vfsProc` só rastreia processo da sessão atual | `Get-CimInstance Win32_Process | TEIA-VFS` + Terminate |
| Explorer vê diretório vazio | Cache WebDAV do Windows não invalida | `Restart-Service WebClient -Force` no Stop-VFSDrive |
| AutoSynth nunca ONTOPROCEDURAL | Brotli comprime < 600B melhor que qualquer wrapper PS | Julgamento de Eficiência FASE 4.5 filtra corretamente |
| Compare-ClassicalCompression usa GZip não LZMA real | .NET só tem GZipStream (sem LZMA nativo) | Documentado: "cmp.lzma" no TEIA é GZip-Optimal em `.gz` |

---

## BLOCO 3 — MAPA DE ARQUIVOS CANÔNICOS

### 3.1 Git-Tracked (D:\TEIA_CLAUDE_AWAKENING\)

```
tools/
  TEIA-AutoSynth-v0700.ps1       28.2 KB  — Forja v1 (sem Efficiency Judgment)
  TEIA-AutoSynth-v0710.ps1       33.9 KB  — Forja v2 (com Efficiency Judgment P11.0)
  TEIA-System-Manager-v0800.ps1  19.6 KB  — Omni-Gestor P11.0 + -ProcessExisting
  TEIA-VFS-WinFsp-v0800.ps1      25.9 KB  — VFS WebDAV v0.80.2 (hot-reload)
  TEIA-Dogfooding-Dashboard.ps1  12.0 KB  — CLI wrapper v0.80.5 (zombie hunter)

docs/
  TEIA_P9_REAL_APP_INTEGRATION_v0601.md  — P9.1: 15/15 PASS T:\ WebDAV
  TEIA_P11_DOGFOODING_PROTOCOL_v0801.md  — P11.1: 13/13 PASS Z:\ dogfooding
  TEIA_P11_VFS_HOT_RELOAD_v0802.md       — P11.2: hot-reload < 15ms overhead
  TEIA_MASTER_COG_SEED_v1.md             — este documento
```

### 3.2 Operacionais (D:\TEIA_CORE\tools\) — espelho dos acima

Idênticos em conteúdo. São os scripts que os processos em produção executam.

### 3.3 Estrutura CAS

```
D:\TEIA_CORE\
  objects\{aa}\{bb}\{sha256}{ext}  — CAS content-addressed
  decoders\decoder_{name}_{ext}_{hash8}.ps1        — P1 Patch decoder
  decoders\decoder_{name}_{ext}_{hash8}.seed.json  — semente JSON
  decoders\decoder_{name}_{ext}_{hash8}.manifest.json
  logs\system_manager_v0800.log
  vfs_cache_z\{sha256}.dec         — cache de descompressão Brotli/LZMA
  sandbox\autosynth\               — decoders temporários entre LLM attempts
  docs\                            — relatórios de prova

D:\TEIA_USER\MyRealData\
  **\*.teia_stub    — stubs JSON (NUNCA abrir diretamente)
  Z:\              — drive virtual WebDAV (como acessar)
```

### 3.4 Formato do .teia_stub

```json
{
  "original_name": "arquivo.ext",
  "original_size_bytes": 3838,
  "original_sha256": "abcdef1234...",
  "final_strategy": "gen.pattern",
  "cas_encoding": "teia_seed",
  "cas_path": "D:\\TEIA_CORE\\objects\\ab\\cd\\abcd...teia_seed",
  "cas_sha256": "...",
  "cas_size_bytes": 177,
  "savings_pct": 95.4,
  "ingest_timestamp": "2026-05-29T16:15:45"
}
```

Para `gen.procedural` — campos adicionais: `decoder_id`, `decoder_path`, `seed_path`, `cas_path: null`.

---

## BLOCO 4 — COMMITS DO CICLO P11.x

```
28c6eb5  fix(teia-fs): zombie hunter dashboard v0.80.5
063f70f  fix(teia-fs): cache buster webclient + explorer v0.80.4
a88858b  fix(teia-fs): hot-reload manifesto vfs 5s v0.80.2
9a35418  feat(teia-fs): painel dogfooding + validacao real v0.80.1
e42e7bf  feat(teia-fs): omni-gestor + autossintese + vfs nativo v0.80.0
a64d444  feat(teia-core): forja autossintetica micro-motores v0.70.0
e8eb4d6  test(teia-fs): integracao aplicativos reais windows v0.60.1
```

---

## BLOCO 5 — OBJETIVO DO PRÓXIMO CICLO (P13.0)

### 5.1 Nome do Ciclo

**P13.0 — COMPRESSÃO LUNÁTICA: Forja Ontoprocedural para Estruturas Complexas**

### 5.2 Objetivo Central

Expandir o `TEIA-AutoSynth` além de arquivos < 8 KB com padrões simples para:

1. **Estruturas 3D complexas** (OBJ/STL com milhares de vértices): o LLM deve aprender a gerar funções procedurais que reproduzam geometrias via parâmetros matemáticos (esferas, toróides, malhas regulares) — não replicar bytes mas *descrever a forma* em código.

2. **Logs de aplicação de grande escala** (> 1 MB): detectar timestamps, formatos repetitivos, sequências numéricas incrementais — gerar decoder que reconstrói o padrão temporal.

3. **Integração WinFsp nativa** (em substituição ao WebDAV): montar `Z:\` via WinFsp driver direto em vez de WebClient + net use. Elimina dependência do WebClient service e permite velocidade de leitura nativa (sem overhead HTTP).

### 5.3 Critérios de Sucesso P13.0

| Critério | Meta |
|---------|------|
| AutoSynth ONTOPROCEDURAL em produção | ≥ 1 arquivo real cristalizado |
| Decoder funcional para OBJ 3D > 10 KB | SHA-256 PASS em Runspace |
| Delta economia > 80% em log grande | Versus cmp.lzma baseline |
| WinFsp mount `Z:\` sem WebClient | dir Z:\ funcional via driver kernel |
| Write==Read mantido | 100% PASS em todos os novos tipos |

### 5.4 Pré-Condições para P13.0

- [x] Ollama rodando com modelo capaz (qwen2.5-coder:7b mínimo, idealmente deepseek-r1:14b)
- [x] TEIA-AutoSynth-v0710.ps1 operacional (FASE 4.5 e ResultFile)
- [x] VFS Z:\ estável com hot-reload
- [ ] WinFsp instalado: `winget install WinFsp.WinFsp` ou `https://winfsp.dev/`
- [ ] Corpus de teste P13 criado: arquivos OBJ > 50 KB, logs > 1 MB com formato estruturado

### 5.5 Primeira Tarefa de P13.0

Criar `D:\TEIA_USER\MyRealData\P13_Corpus\` com:
- 3 arquivos OBJ gerados proceduralmente (esferas com 1000+ faces, helicóides, tori)
- 2 logs de app simulados com padrão temporal (> 500 KB, timestamps regulares)
- 1 arquivo binário estruturado simples (BMP 24-bit sólido, PNG simples)

Então invocar AutoSynth com `-Tries 5 -Model deepseek-r1:14b` em cada um e documentar taxa ONTOPROCEDURAL vs CLASSICAL.

---

## BLOCO 6 — COMANDOS DE RETOMADA RÁPIDA

```powershell
# 1. Verificar estado do sistema
Set-Location 'D:\TEIA_CLAUDE_AWAKENING'
git log --oneline -5
Get-ChildItem 'D:\TEIA_CORE\tools\TEIA-*-v0[89]*.ps1' | Select-Object Name, Length

# 2. Iniciar VFS (modo operacional)
$p = Start-Process pwsh -ArgumentList "-ExecutionPolicy Bypass -NonInteractive -File `"D:\TEIA_CORE\tools\TEIA-VFS-WinFsp-v0800.ps1`" -VFSRoot `"D:\TEIA_USER\MyRealData`"" -PassThru -WindowStyle Hidden
Start-Sleep 4
net use Z: \\localhost@8767\DavWWWRoot\ /persistent:no

# 3. Ingerir pasta nova
pwsh -ExecutionPolicy Bypass -File 'D:\TEIA_CORE\tools\TEIA-System-Manager-v0800.ps1' -WatchDir 'D:\TEIA_USER\MyRealData\PASTA' -ProcessExisting

# 4. Validar SHA-256 de arquivo via VFS
$sha = (Get-FileHash 'Z:\arquivo.ext' -Algorithm SHA256).Hash.ToLower()
$stub = Get-Content 'D:\TEIA_USER\MyRealData\arquivo.ext.teia_stub' | ConvertFrom-Json
$sha -eq $stub.original_sha256   # deve ser True

# 5. Dashboard interativo
pwsh -ExecutionPolicy Bypass -File 'D:\TEIA_CORE\tools\TEIA-Dogfooding-Dashboard.ps1'
```

---

## BLOCO 7 — AXIOMAS QUE NUNCA MUDAM

1. **SHA-256 é identidade.** Não hash de conteúdo CAS — hash do arquivo ORIGINAL.
2. **Delta por extenso.** Símbolo Δ proibido em código, log e documento.
3. **Write == Read.** Qualquer byte servido pelo VFS deve produzir o mesmo SHA-256 do original.
4. **CAS é imutável.** Objetos em `objects/` nunca são modificados após escrita.
5. **Stub é ponteiro.** O arquivo `.teia_stub` nunca contém dados do arquivo original — apenas metadados e ponteiro CAS.
6. **Idempotência.** Stub existente com hash correto = skip silencioso.
7. **Contenção.** O motor só opera em `D:\TEIA_USER\MyRealData\`.
8. **Ausente = ausente.** Nunca inventar estado. Marcar `[AUSENTE]` e parar.

---

*Este documento é a memória comprimida do ciclo P11.x.*  
*O próximo ciclo começa onde este termina: a porta está aberta, a semente está plantada.*  
*O tear continua.*
