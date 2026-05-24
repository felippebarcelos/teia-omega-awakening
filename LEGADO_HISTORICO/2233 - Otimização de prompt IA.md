# 2233 - Otimização de prompt IA

### USUÁRIO

Você é um Otimizador Duplo de Prompts de IA.  
Analise o prompt fornecido e decida:  
- Se ele estiver prolixo ou pouco claro → refine (remova ruído/redundância e preserve exatamente a intenção original).  
- Se ele carecer de contexto ou detalhes → expanda (adicione apenas contexto relevante para realizar a intenção).  
Garanta que o resultado seja mais claro e eficaz do que o original.  
Retorne e apresente apenas o prompt otimizado — sem explicações, comentários ou texto extra.   
O Prompt a ser resultado deve possuir semântica, etimologia e núcleo conceitual com ressonância completa coerente denotativa![# Ordem de Serviço Única — Geração Direta TEIA v0.2.1 / Server v2.1 

Tarefa: Gerar 2 scripts PowerShell finais e funcionais:

1) D:\TEIA-Core-v0.2.1.ps1
   - Baseado na funcionalidade do TEIA-Core-v0.2.0 (streaming, canonicalização Write==Read rigorosa, UVM+DSL com plan.ops).
   - Versões internas: core_version = "v0.2.1", dsl_version = "v0.2.1".
   - Primitivas na UVM (Execute-PlanToStream): Manter 'gen.repeat', 'write.hex' (para compatibilidade de restauração). Adicionar 'gen.modseq' (gera i % m). Adicionar 'write.b64' (recebe base64, escreve bytes).
   - Função Compress-File-Stream (Lógica de Geração de Plan):
     1. Calcular SHA256 incremental e Length total.
     2. Detectar se o arquivo inteiro é uniforme (bytes iguais). Se sim: plan.ops = [ {op:'gen.repeat', args:{value, count}} ].
     3. Senão, detectar se o arquivo segue padrão 'i % m' (com m entre 2-256). Se sim: plan.ops = [ {op:'gen.modseq', args:{mod, count}} ].
     4. Senão (Fallback): Ler em chunks; para cada chunk, gerar op = {op:'write.b64', args:{data:<BASE64_DO_CHUNK>}}.
   - Geração da Seed: Incluir campos core_version, dsl_version, output_size, output_sha256, chunk_size, ops_count, trace_sha256 (SHA256 do JSON canônico de plan.ops), e plan: { ops: [...] }. NÃO incluir payload_b64 na raiz. Usar Write-CanonicalJson.
   - Limite: ops_count_max = 100000; abortar deterministicamente se excedido.
   - Funções Restore/Verify: Devem suportar streaming (sem byte[] gigante), usar Execute-PlanToStream, validar SHA/Length/TraceSHA. Manter compatibilidade para restaurar/verificar seeds legadas (v0.2.0 com payload_b64).
   - Logs: Manter logs mínimos e determinísticos (metadata apenas).

2) D:\Start-TEIA-Server-v2.1.ps1
   - Baseado na funcionalidade do Start-TEIA-Server-v2.0 (parâmetros, Run-Core, handlers, infra robusta).
   - Atualizar parâmetro -CorePath para default 'D:\TEIA-Core-v0.2.1.ps1'.
   - Handler GET /health: Retornar corpo "OK v0.2.1" (text/plain; charset=utf-8).
   - Handler POST /compress: Ao receber resposta 200 do Core, ler a seed gerada, extrair output_sha256, output_size, ops_count e adicionar os headers X-Seed-Output-Sha256, X-Seed-Output-Size, X-Seed-Ops-Count à resposta HTTP antes de enviar o corpo JSON da seed.

Entrega: Gerar os dois scripts .ps1 finais. Incluir um breve roteiro de teste manual para validar:
   - GET /health retorna "OK v0.2.1".
   - POST /compress para arquivo 8MB (0xAB) retorna seed com ops_count=1 (gen.repeat) e os headers X-Seed-*.
   - POST /compress para arquivo 50MB (i % 251) retorna seed com ops_count=1 (gen.modseq) e os headers X-Seed-*.
   - O fluxo compress -> restore -> verify funciona para ambos os casos.]

---

### ASSISTENTE

# ORDEM DE SERVIÇO ÚNICA — TEIA v0.2.1 / SERVER v2.1 (GERAÇÃO DIRETA)

**Papel do modelo:** gerar **dois scripts PowerShell finais e funcionais**, idempotentes e determinísticos, **sem dependências externas**, compatíveis com **PowerShell 7+** e execução local no Windows.

**Entrega (formato obrigatório):**
1) Um bloco único de código **PowerShell puro** com o arquivo: `D:\TEIA-Core-v0.2.1.ps1`
2) Um bloco único de código **PowerShell puro** com o arquivo: `D:\Start-TEIA-Server-v2.1.ps1`
3) **Roteiro de teste manual** curto (comandos/etapas) após os dois blocos.
> Não inclua comentários fora dos blocos e do roteiro. Sem emojis, sem conteúdo extra.

---

## 1) `D:\TEIA-Core-v0.2.1.ps1`

**Base funcional (reimplemente, não assuma acesso ao v0.2.0):**
- Streaming rigoroso com **Write==Read** (restauração bit-a-bit).
- UVM + DSL com `plan.ops` executado por `Execute-PlanToStream`.

**Versões internas:**
- `core_version = "v0.2.1"`
- `dsl_version  = "v0.2.1"`

**Primitivas UVM (em `Execute-PlanToStream`):**
- **Preservar**: `gen.repeat` (repete 1 byte `value` por `count`), `write.hex` (hex string → bytes) para compatibilidade legada.
- **Adicionar**:
  - `gen.modseq` → gera sequência onde o byte iésimo = `i % mod`, para `i = 0 .. count-1` (2 ≤ `mod` ≤ 256).
  - `write.b64`  → recebe `data` (Base64) e escreve bytes decodificados.

**Compress-File-Stream (geração do plano):**
1. Calcular **SHA256 incremental** (streaming) e **Length total** do arquivo.
2. Se o arquivo for **uniforme** (todos os bytes iguais):  
   `plan.ops = [ { op:'gen.repeat', args:{ value:<byte>, count:<length> } } ]`
3. Senão, se seguir **padrão `i % m`** (para algum `m` em [2..256]) **ao longo de todo o arquivo**:  
   `plan.ops = [ { op:'gen.modseq', args:{ mod:<m>, count:<length> } } ]`
4. Senão (**fallback**): ler em **chunks fixos e determinísticos** e, para cada chunk, gerar  
   `{ op:'write.b64', args:{ data:<BASE64_DO_CHUNK> } }`  
   - **chunk_size padrão**: **1 MiB** (1048576 bytes).
   - `ops_count_max = 100000` → **abortar deterministicamente** se excedido.

**Seed (formato JSON canônico):**
- Campos obrigatórios na raiz:  
  `core_version`, `dsl_version`, `output_size`, `output_sha256`, `chunk_size`, `ops_count`, `trace_sha256`, `plan:{ ops:[...] }`
- **Não** incluir `payload_b64` na raiz.
- `trace_sha256` = SHA256 do **JSON canônico** de `plan.ops`.
- **Write-CanonicalJson**: UTF-8 (sem BOM), chaves ordenadas lexicograficamente, sem espaços supérfluos, finais de linha consistentes.

**Restore / Verify (streaming, sem `byte[]` gigante):**
- `Restore`: executar `plan.ops` via `Execute-PlanToStream`.
- `Verify`: validar `output_sha256`, `output_size` e `trace_sha256` (congruência `Write==Read`).
- **Compatibilidade legada v0.2.0**: suportar seeds antigas que possuam `payload_b64` e/ou usem `write.hex`.

**Logs:**
- **Mínimos e determinísticos** (apenas metadados essenciais; sem timestamps variáveis no conteúdo do seed).

---

## 2) `D:\Start-TEIA-Server-v2.1.ps1`

**Base funcional (reimplemente, não assuma acesso ao v2.0):**
- Infra robusta de servidor HTTP local (sem libs externas).
- Parâmetros de inicialização; tratar exceções com códigos estáveis.

**Parâmetros:**
- `-CorePath` (default: `'D:\TEIA-Core-v0.2.1.ps1'`).

**Handlers:**
- `GET /health` → corpo **`OK v0.2.1`** com `Content-Type: text/plain; charset=utf-8`.
- `POST /compress` → ao obter **200** do Core:
  - Ler a seed JSON gerada.
  - Extrair `output_sha256`, `output_size`, `ops_count`.
  - Adicionar headers na resposta:
    - `X-Seed-Output-Sha256: <output_sha256>`
    - `X-Seed-Output-Size: <output_size>`
    - `X-Seed-Ops-Count: <ops_count>`
  - Enviar o **corpo JSON da seed** (sem alterações), preservando canonicidade.

---

## ROTEIRO DE TESTE MANUAL (curto)

1. **Healthcheck**  
   - `GET /health` → resposta 200 com corpo **`OK v0.2.1`**.

2. **Caso uniforme (8 MiB de 0xAB)**  
   - Comprimir arquivo 8 MiB (preenchido com `0xAB`).  
   - `POST /compress` → seed com `ops_count = 1` (`gen.repeat`) e headers `X-Seed-*` presentes.

3. **Caso modseq (50 MiB com `i % 251`)**  
   - Comprimir arquivo 50 MiB cujo byte iésimo = `i % 251`.  
   - `POST /compress` → seed com `ops_count = 1` (`gen.modseq`) e headers `X-Seed-*` presentes.

4. **Ciclo completo**  
   - Para ambos os casos, executar sequência **compress → restore → verify** usando o Core:  
     a) gerar seed,  
     b) restaurar arquivo a partir da seed,  
     c) verificar `output_sha256`, `output_size` e `trace_sha256` com sucesso.

> **Critérios de aceitação:** todas as respostas, headers e verificações conforme especificado; execução estritamente por streaming; determinismo preservado.

---

