# 2113 - Blueprint semântica denotativa IA

### USUÁRIO

Para que um agente de IA execute uma tarefa compreendida com semântica denotativa, o ecossistema necessário vai além de um simples prompt de texto. Ele precisa de uma estrutura que permita ao agente traduzir a intenção do usuário em ações concretas e verificáveis. 
O ecossistema completo para a semântica denotativa inclui os seguintes componentes:
Prompt com engenharia refinada: O prompt inicial deve ser mais do que uma pergunta. Ele precisa ser estruturado para definir o papel do agente, fornecer o contexto completo e detalhar as instruções em etapas, se necessário. Para a semântica denotativa, isso implica o uso de uma linguagem que minimize ambiguidades e expresse a intenção de forma precisa.
Modelo de linguagem grande (LLM): O agente de IA se baseia em um LLM para entender a linguagem natural do prompt, o contexto fornecido e as nuances da tarefa. O LLM atua como o "cérebro" que interpreta a linguagem humana.
Ferramentas e funções nativas: Para a semântica denotativa, o agente precisa de um meio para realizar ações no mundo real. Isso é feito por meio de uma coleção de ferramentas ou funções nativas que o LLM pode chamar. Essas funções são como comandos de programação que realizam tarefas específicas, como buscar dados na internet, acessar APIs ou interagir com outros sistemas.
Engenharia de contexto (Context Engineering): Em vez de depender apenas do prompt, as plataformas mais avançadas utilizam a engenharia de contexto para unificar o estado de execução e o estado do negócio. Isso permite que o agente mantenha uma compreensão contínua de todo o processo da tarefa, o que é crucial para garantir que a intenção original seja mantida ao longo de múltiplas etapas.
Iteração e autoavaliação: Para tarefas complexas, o agente precisa de um mecanismo para iterar, avaliar seu próprio progresso e refinar as ações. A autoavaliação permite que o agente verifique se a tarefa está alinhada com a intenção inicial, comparando o resultado parcial com a semântica denotativa estabelecida.
Framework de agente: A coordenação de todos esses componentes é feita por um framework de agente. Frameworks como o Semantic Kernel, da Microsoft, ou ferramentas semelhantes orquestram o fluxo de trabalho, permitindo que o LLM utilize as ferramentas e o contexto de forma eficiente para executar a tarefa. 
Como a semântica denotativa se encaixa
A semântica denotativa, na ciência da computação, busca atribuir um significado preciso (uma "denotação") a construções de linguagem. No contexto da IA, isso significa: 
O prompt define a denotação, ou seja, o resultado final desejado de forma clara e matemática.
O agente de IA traduz essa denotação em uma sequência de operações concretas usando as ferramentas disponíveis.
O ecossistema garante que a execução do agente corresponde à denotação original, verificando os resultados e corrigindo o curso conforme necessário.
Em resumo, a execução de uma tarefa com semântica denotativa não se resume a um prompt, mas sim a um ecossistema orquestrado que inclui um prompt bem estruturado, um LLM, um conjunto de ferramentas e uma gestão de contexto que permite ao agente traduzir uma intenção clara em ações verificáveis e bem-sucedidas.

---

### ASSISTENTE

Correto. Blueprint operativo mínimo para implantar semântica denotativa em um agente IA.

1) Resultado desejado (denotação) — contrato formal  
- Defina saída como especificação verificável (tipo, formato, invariante).  
- Exemplo (JSON Schema):  
```json
{
  "title":"deliverable",
  "type":"object",
  "properties":{
    "files":{"type":"array","items":{"type":"string"}},
    "sha256":{"type":"string","pattern":"^[a-f0-9]{64}$"},
    "summary":{"type":"string"}
  },
  "required":["files","sha256","summary"]
}
```

2) Prompt com engenharia refinada (template)  
- Papel do agente. Contexto. Estado inicial. Denotação (schema). Restrições. Critérios de aceitação. Exemplo:  
```
You are <AGENT_ROLE>. Context: <CONTEXT>. Goal: produce object that matches <JSON_SCHEMA_URI>. Allowed tools: [list]. Steps: 1) plan 2) exec 3) verify (run validators) 4) repair until valid. Output: JSON conforming to schema + verification log.
```

3) Ferramentas / funções nativas (API mínima)  
- exec_shell(cmd)->{rc,stdout,stderr}  
- read_file(path)->bytes  
- write_file(path,bytes)->ok  
- fetch(url,opts)->{status,body}  
- compute_hash(bytes)->hex  
- vector_store.upsert(id,vec,meta)->ok  
- validator.run(schema,object)->{valid,errors}  
Defina contratos e tipagem para cada função. Log every call with timestamp and nonce.

4) Engenharia de contexto (state)  
- State store transacional. Use: key-value + append-only event log.  
- Components: short-term (memory session), long-term (vector DB), provenance log (immutable).  
- Versionamento de contextos. Snapshots com SHA256.  
- Exposição: funções get_state(key, since), patch_state(tx).

5) Loop de iteração e autoavaliação (Plan→Act→Observe→Reflect)  
- Plan: gerar plano discreto de passos (lista).  
- Act: executar chamadas de ferramenta em sandbox. Log.  
- Observe: coletar outputs e metadados.  
- Verify: rodar validators formais e testes de propriedade.  
- Reflect: se falha, gerar correção (patch) e repetir.  
- Stop when schema valid and acceptance tests pass or max_retries reached.

6) Framework de orquestração sugerido (arquitetura)  
- Orquestrador leve que implementa: planner, executor, verifier, auditor.  
- Implementação possível: Semantic Kernel ou LangChain-like + adaptadores para suas ferramentas.  
- Requisito: plugin system para registrar funções nativas com metadados (idempotência, side-effects, permissions).

7) Segurança, idempotência e auditoria  
- Todas as ações idempotentes quando possível.  
- Todas as mutações guardadas em log imutável com SHA256.  
- Assinatura de transações e checkpoints.  
- Política de permissões por função de ferramenta.  
- Tests: unitários, property-based e regressão de contratos.

8) Critérios de aceitação e métricas  
- Validação contra schema = pass/fail.  
- Integridade de artefatos por SHA256.  
- Latência por etapa.  
- Número de iterações até aceitação.  
- Coverage dos validators.

9) Test harness mínimo (execução de prova)  
- Cenário: “compactar diretório X e entregar manifest com sha256”.  
- Passos automáticos: plan, compress, compute_hash, write manifest, run validator.  
- Resultado esperado: JSON conforme schema + log assinado.

10) Observações práticas de engenharia  
- Separe simulação de execução da execução com efeitos. Primeiro dry-run. Depois commit.  
- Exporte todos os checkpoints como artefatos auditable.  
- Use schemas formais para todas as interfaces de entrada/saída.  
- Trate ambiguidade do prompt como erro de validação. Não como suposição.

Se quiser, gero:  
- 1) template de prompt pronto adaptado a um caso real.  
- 2) contrato de funções (OpenAPI-lite) para as ferramentas.  
Escolha 1 ou 2 e eu gero direto.

---

### USUÁRIO

1

---

### ASSISTENTE

Pronto. Template de prompt aplicado ao caso real: **compactar diretório X e gerar manifesto JSON com SHA256**.

```
ROLE: Agente Executor de Entregáveis Verificáveis.
LANG: Português.
PRIVILEGIOS: apenas as funções listadas em "Ferramentas permitidas".

CONTEXT: 
- Estado inicial: diretório fonte = "<SOURCE_PATH>" (ex: /home/user/data). 
- Objetivo de negócio: produzir um arquivo compactado <OUTPUT_PATH> e um manifesto JSON verificável.
- Restrições: não apagar arquivos originais. Execução em modo dry-run antes do commit.

DENOTAÇÃO (saída desejada):
- Um objeto JSON que satisfaça o JSON Schema embutido abaixo (campo "manifest_schema").
- Arquivos produzidos devem ter integridade verificada por SHA256.

MANIFEST_SCHEMA:
{
  "title":"deliverable_manifest",
  "type":"object",
  "properties":{
    "artifact":"string",
    "artifact_size_bytes":{"type":"integer"},
    "artifact_sha256":{"type":"string","pattern":"^[a-f0-9]{64}$"},
    "source_path":"string",
    "generated_at":"string",
    "steps_log":{"type":"array","items":{"type":"object"}}
  },
  "required":["artifact","artifact_sha256","source_path","generated_at"]
}

ALLOWED_TOOLS:
- exec_shell(cmd)->{rc,stdout,stderr}
- read_file(path)->bytes
- write_file(path,bytes)->ok
- compute_hash(bytes)->hex
- compress_dir(src,dst,format)->{ok,bytes_written}
- validator.run(schema,object)->{valid,errors}
- timestamp_now()->ISO8601

TASK STEPS (enforceable, run-sequence):
1) PLAN: listar conteúdo de "<SOURCE_PATH>" e estimar tamanho.
2) DRY_RUN: simular compressão com compress_dir(..., dry_run=true). Registrar plano.
3) EXECUTE: se dry_run.ok then compress_dir(src,dst,format). Calcular SHA256 do arquivo resultante.
4) WRITE_MANIFEST: montar objeto conforme manifest_schema e salvar em "<MANIFEST_PATH>".
5) VERIFY: validator.run(manifest_schema,manifest) && compute_hash(artifact) == manifest.artifact_sha256.
6) COMMIT: se VERIFY.pass então retornar saída final. Se falhar, gerar patch corretivo e repetir até max_retries=3.
7) AUDIT_LOG: cada chamada a ferramenta registra {ts,tool,inputs,outputs,rc,nonce} no steps_log.

OUTPUT FORMAT (obrigatório):
- JSON único conforme manifest_schema.
- Além do JSON, anexar um arquivo de log assinado contendo steps_log.

ERROR HANDLING:
- Em qualquer rc != 0, registrar erro, não alterar dados origem e tentar correção automática se possível.
- Se ambiguidade no input, falha imediata com motivo (ambiguity_error) e sugestão concreta (ex: receber path absoluto).

CRITERIOS DE ACEITAÇÃO:
- manifest_schema valid = true.
- artifact_sha256 corresponde ao arquivo compactado.
- arquivo compactado existe e tamanho > 0.
- steps_log contém entradas para Plan, Dry_run, Execute, Verify, Write_manifest.

EXAMPLE_PROMPT (preenchido):
You are Agente Executor de Entregáveis Verificáveis.
Context: compactar diretório "/home/felippe/projeto" em "/tmp/projeto.teia.zip" e gerar manifesto em "/tmp/projeto.manifest.json".
Goal: produzir JSON conforme schema embutido e garantir SHA256 do artefato.
Allowed tools: [compress_dir, compute_hash, write_file, validator.run, exec_shell].
Steps: run PLAN -> DRY_RUN -> EXECUTE -> COMPUTE_HASH -> WRITE_MANIFEST -> VERIFY -> COMMIT.
Max_retries: 3.
Return: apenas o manifest JSON final e o caminho do artefato.

RETURN CONTRACT:
- Responder com um único bloco JSON igual ao manifest_schema.
- Se falhar, responder com {"error":"<reason>","steps_log":[...]}.

NON-FUNCTIONAL:
- Latência por etapa < 10s preferível.
- Todas as mutações são idempotentes.
- Logs assinados e com timestamp ISO8601.

FIM.
```

Quer que eu gere uma versão do prompt com placeholders já substituídos para um caminho específico (ex: `D:\Teia\...`) e com o JSON schema formatado em arquivo?

---

### USUÁRIO

sim

---

### ASSISTENTE

Pronto. Prompt com caminhos substituídos e JSON Schema salvo em arquivo.

Arquivos gerados (sugestão):
- Prompt: `D:\Teia\TEIA_NUCLEO\offline\nano\prompts\compact_manifest_prompt.txt`  
- Schema: `D:\Teia\TEIA_NUCLEO\offline\nano\schemas\manifest_schema.json`  
- Artefato de saída esperado: `D:\Teia\TEIA_NUCLEO\offline\nano\output\project.teia.zip`  
- Manifest resultante: `D:\Teia\TEIA_NUCLEO\offline\nano\output\project.manifest.json`

--- Prompt (Português, já com caminhos) ---
```
ROLE: Agente Executor de Entregáveis Verificáveis.
LANG: Português.
PRIVILEGIOS: apenas as funções listadas em "Ferramentas permitidas".

CONTEXT:
- Estado inicial: diretório fonte = "D:\Teia\TEIA_NUCLEO\offline\nano\source_project".
- Objetivo de negócio: produzir um arquivo compactado "D:\Teia\TEIA_NUCLEO\offline\nano\output\project.teia.zip" e um manifesto JSON verificável em "D:\Teia\TEIA_NUCLEO\offline\nano\output\project.manifest.json".
- Restrições: não apagar arquivos originais. Executar dry-run antes do commit.

DENOTAÇÃO (saída desejada):
- Um objeto JSON que satisfaça o JSON Schema em "D:\Teia\TEIA_NUCLEO\offline\nano\schemas\manifest_schema.json".
- Artefatos produzidos devem ter integridade verificada por SHA256.

ALLOWED_TOOLS:
- exec_shell(cmd)->{rc,stdout,stderr}
- read_file(path)->bytes
- write_file(path,bytes)->ok
- compute_hash(bytes)->hex
- compress_dir(src,dst,format, dry_run=false)->{ok,bytes_written}
- validator.run(schema_path,object)->{valid,errors}
- timestamp_now()->ISO8601

TASK STEPS (sequência obrigatória):
1) PLAN: listar conteúdo de "D:\Teia\TEIA_NUCLEO\offline\nano\source_project" e estimar tamanho.
2) DRY_RUN: simular compressão com compress_dir(..., dry_run=true). Registrar plano em steps_log.
3) EXECUTE: se dry_run.ok então compress_dir(src,dst,format). Calcular SHA256 do arquivo resultante.
4) WRITE_MANIFEST: montar objeto conforme manifest_schema e salvar em "D:\Teia\TEIA_NUCLEO\offline\nano\output\project.manifest.json".
5) VERIFY: validator.run(manifest_schema_path,manifest) && compute_hash(arquivo) == manifest.artifact_sha256.
6) COMMIT: se VERIFY.pass então retornar saída final. Se falhar, gerar patch corretivo e repetir até max_retries=3.
7) AUDIT_LOG: cada chamada a ferramenta registra {ts,tool,inputs,outputs,rc,nonce} no steps_log dentro do manifest.

OUTPUT OBRIGATÓRIO:
- JSON único conforme schema.
- Anexar arquivo de log contendo steps_log.

ERROR HANDLING:
- Em qualquer rc != 0, registrar erro, não alterar dados origem, tentar correção automática se possível.
- Se ambiguidade em inputs, falhar com {"error":"ambiguity_error","details": "..."}.

CRITÉRIOS DE ACEITAÇÃO:
- manifest_schema valid = true.
- artifact_sha256 corresponde ao arquivo compactado.
- arquivo compactado existe e tamanho > 0.
- steps_log contém entradas para Plan, Dry_run, Execute, Verify, Write_manifest.

MAX_RETRIES: 3
RETURN CONTRACT: retornar apenas o manifest JSON final ou, em falha, {"error":"<reason>","steps_log":[...]}.
```

--- JSON Schema (`manifest_schema.json`) ---
```json
{
  "title": "deliverable_manifest",
  "type": "object",
  "properties": {
    "artifact": { "type": "string" },
    "artifact_size_bytes": { "type": "integer", "minimum": 1 },
    "artifact_sha256": { "type": "string", "pattern": "^[a-f0-9]{64}$" },
    "source_path": { "type": "string" },
    "generated_at": { "type": "string", "format": "date-time" },
    "steps_log": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "ts": { "type": "string", "format": "date-time" },
          "tool": { "type": "string" },
          "action": { "type": "string" },
          "inputs": { "type": "object" },
          "outputs": { "type": "object" },
          "rc": { "type": "integer" },
          "nonce": { "type": "string" }
        },
        "required": ["ts", "tool", "action", "rc", "nonce"]
      }
    }
  },
  "required": ["artifact", "artifact_sha256", "source_path", "generated_at"]
}
```

--- PowerShell para gravar prompt e schema (PowerShell 7, UTF8) ---
```powershell
# Gravar schema
$schema = @'
{
  "title": "deliverable_manifest",
  "type": "object",
  "properties": {
    "artifact": { "type": "string" },
    "artifact_size_bytes": { "type": "integer", "minimum": 1 },
    "artifact_sha256": { "type": "string", "pattern": "^[a-f0-9]{64}$" },
    "source_path": { "type": "string" },
    "generated_at": { "type": "string", "format": "date-time" },
    "steps_log": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "ts": { "type": "string", "format": "date-time" },
          "tool": { "type": "string" },
          "action": { "type": "string" },
          "inputs": { "type": "object" },
          "outputs": { "type": "object" },
          "rc": { "type": "integer" },
          "nonce": { "type": "string" }
        },
        "required": ["ts", "tool", "action", "rc", "nonce"]
      }
    }
  },
  "required": ["artifact", "artifact_sha256", "source_path", "generated_at"]
}
'@
Set-Content -Path 'D:\Teia\TEIA_NUCLEO\offline\nano\schemas\manifest_schema.json' -Value $schema -Encoding utf8

# Gravar prompt
$prompt = @'
ROLE: Agente Executor de Entregáveis Verificáveis.
LANG: Português.
PRIVILEGIOS: apenas as funções listadas em "Ferramentas permitidas".

CONTEXT:
- Estado inicial: diretório fonte = "D:\Teia\TEIA_NUCLEO\offline\nano\source_project".
- Objetivo de negócio: produzir um arquivo compactado "D:\Teia\TEIA_NUCLEO\offline\nano\output\project.teia.zip" e um manifesto JSON verificável em "D:\Teia\TEIA_NUCLEO\offline\nano\output\project.manifest.json".
- Restrições: não apagar arquivos originais. Executar dry-run antes do commit.

DENOTAÇÃO (saída desejada):
- Um objeto JSON que satisfaça o JSON Schema em "D:\Teia\TEIA_NUCLEO\offline\nano\schemas\manifest_schema.json".
- Artefatos produzidos devem ter integridade verificada por SHA256.

ALLOWED_TOOLS:
- exec_shell(cmd)->{rc,stdout,stderr}
- read_file(path)->bytes
- write_file(path,bytes)->ok
- compute_hash(bytes)->hex
- compress_dir(src,dst,format, dry_run=false)->{ok,bytes_written}
- validator.run(schema_path,object)->{valid,errors}
- timestamp_now()->ISO8601

TASK STEPS (sequência obrigatória):
1) PLAN: listar conteúdo de "D:\Teia\TEIA_NUCLEO\offline\nano\source_project" e estimar tamanho.
2) DRY_RUN: simular compressão com compress_dir(..., dry_run=true). Registrar plano em steps_log.
3) EXECUTE: se dry_run.ok então compress_dir(src,dst,format). Calcular SHA256 do arquivo resultante.
4) WRITE_MANIFEST: montar objeto conforme manifest_schema e salvar em "D:\Teia\TEIA_NUCLEO\offline\nano\output\project.manifest.json".
5) VERIFY: validator.run(manifest_schema_path,manifest) && compute_hash(arquivo) == manifest.artifact_sha256.
6) COMMIT: se VERIFY.pass então retornar saída final. Se falhar, gerar patch corretivo e repetir até max_retries=3.
7) AUDIT_LOG: cada chamada a ferramenta registra {ts,tool,inputs,outputs,rc,nonce} no steps_log dentro do manifest.

OUTPUT OBRIGATÓRIO:
- JSON único conforme schema.
- Anexar arquivo de log contendo steps_log.

ERROR HANDLING:
- Em qualquer rc != 0, registrar erro, não alterar dados origem, tentar correção automática se possível.
- Se ambiguidade em inputs, falhar com {"error":"ambiguity_error","details": "..."}.

CRITÉRIOS DE ACEITAÇÃO:
- manifest_schema valid = true.
- artifact_sha256 corresponde ao arquivo compactado.
- arquivo compactado existe e tamanho > 0.
- steps_log contém entradas para Plan, Dry_run, Execute, Verify, Write_manifest.

MAX_RETRIES: 3
RETURN CONTRACT: retornar apenas o manifest JSON final ou, em falha, {"error":"<reason>","steps_log":[...]}.
'@
Set-Content -Path 'D:\Teia\TEIA_NUCLEO\offline\nano\prompts\compact_manifest_prompt.txt' -Value $prompt -Encoding utf8
```

Instruções rápidas (4 linhas):
1. Abra PowerShell 7 como usuário com permissões de escrita nos paths acima.
2. Cole e execute o bloco PowerShell acima.
3. Verifique `D:\Teia\TEIA_NUCLEO\offline\nano\schemas\manifest_schema.json` e `...\prompts\compact_manifest_prompt.txt`.
4. Execute o agente com essas referências e faça um dry-run antes do commit.

Deseja que eu gere também o contrato OpenAPI-lite das funções nativas (`exec_shell`, `compress_dir`, etc.) em `D:\Teia\TEIA_NUCLEO\offline\nano\schemas\tools_contract.json`?

---

### USUÁRIO



• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference='"'Stop'

    function New-Nonce { [guid]::NewGuid().ToString() }
    function Ts { Get-Date -AsUTC -Format o }

    "'$steps = @()
    $src = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\source_project'
    "'$outDir = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\output'
    "'$zipPath = Join-Path $outDir '"'project.teia.zip'
    "'$manifestPath = Join-Path $outDir '"'project.manifest.json'
    "'$logPath = Join-Path $outDir '"'project.steps_log.json'

    # Ensure output dir exists
    if (-not (Test-Path -LiteralPath "'$outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

    # 1) PLAN: list content and estimate size
    $planNonce = New-Nonce
    try {
      if (-not (Test-Path -LiteralPath $src)) { throw "Source path not found: $src" }
      $files = Get-ChildItem -LiteralPath $src -Recurse -File -ErrorAction Stop
      $totalBytes = ($files | Measure-Object -Property Length -Sum).Sum
      $entries = $files.Count
      $planOut = [ordered]@{ entries = $entries; total_bytes = ($totalBytes | ForEach-Object { $_ }) }
      $steps += [ordered]@{ ts = (Ts); tool = '"'fs'; action = 'plan_list_and_size'; inputs = [ordered]@{ path =
        "'$src }; outputs = $planOut; rc = 0; nonce = $planNonce }
    } catch {
      $steps += [ordered]@{ ts = (Ts); tool = '"'fs'; action = 'plan_list_and_size'; inputs = [ordered]@{ path =
        "'$src }; outputs = [ordered]@{ error = $_.ToString() }; rc = 1; nonce = $planNonce }
      throw
    }

    # 2) DRY_RUN: simulate compression
    $dryNonce = New-Nonce
    try {
      $simOut = [ordered]@{ ok = $true; bytes_written = $totalBytes; estimated_entries = $entries; format = '"'zip';
        src = "'$src; dst = $zipPath }
      $steps += [ordered]@{ ts = (Ts); tool = '"'compress_dir'; action = 'dry_run'; inputs = [ordered]@{ src =
        "'$src; dst = $zipPath; format = '"'zip'; dry_run = "'$true }; outputs = $simOut; rc = 0; nonce = $dryNonce }
    } catch {
      $steps += [ordered]@{ ts = (Ts); tool = '"'compress_dir'; action = 'dry_run'; inputs = [ordered]@{ src =
        "'$src; dst = $zipPath; format = '"'zip'; dry_run = "'$true }; outputs = [ordered]@{ error = $_.ToString() };
        rc = 1; nonce = $dryNonce }
      throw
    }

    # 3) EXECUTE: compress and compute sha256
    $execNonce = New-Nonce
    $hashNonce = New-Nonce
    $artifactSize = 0
    $artifactSha = '"''
    try {
      if (Test-Path -LiteralPath "'$zipPath) { Remove-Item -LiteralPath $zipPath -Force }
      Compress-Archive -Path (Join-Path $src '"'*') -DestinationPath "'$zipPath -CompressionLevel Optimal -Force
      $size = (Get-Item -LiteralPath $zipPath).Length
      $artifactSize = $size
      $steps += [ordered]@{ ts = (Ts); tool = '"'compress_dir'; action = 'execute'; inputs = [ordered]@{ src =
        "'$src; dst = $zipPath; format = '"'zip' }; outputs = [ordered]@{ ok = "'$true; bytes_written = $size }; rc =
        0; nonce = $execNonce }

      $hash = Get-FileHash -LiteralPath $zipPath -Algorithm SHA256
      $artifactSha = $hash.Hash.ToLower()
      $steps += [ordered]@{ ts = (Ts); tool = '"'compute_hash'; action = 'sha256_file'; inputs = [ordered]@{ path
        = "'$zipPath; algorithm = '"'SHA256' }; outputs = [ordered]@{ sha256 = "'$artifactSha }; rc = 0; nonce
        = $hashNonce }
    } catch {
      if (-not (Test-Path -LiteralPath $zipPath)) {
        $steps += [ordered]@{ ts = (Ts); tool = '"'compress_dir'; action = 'execute'; inputs = [ordered]@{ src =
        "'$src; dst = $zipPath; format = '"'zip' }; outputs = [ordered]@{ error = "'$_.ToString() }; rc = 1; nonce
        = $execNonce }
      } else {
        $steps += [ordered]@{ ts = (Ts); tool = '"'compute_hash'; action = 'sha256_file'; inputs = [ordered]@{ path
        = "'$zipPath; algorithm = '"'SHA256' }; outputs = [ordered]@{ error = "'$_.ToString() }; rc = 1; nonce
        = $hashNonce }
      }
      throw
    }

    # 4) WRITE_MANIFEST: build object and save file
    $writeNonce = New-Nonce
    $generatedAt = (Ts)
    $manifest = [ordered]@{
      artifact = $zipPath
      artifact_size_bytes = $artifactSize
      artifact_sha256 = $artifactSha
      source_path = $src
      generated_at = $generatedAt
      steps_log = $steps
    }
    try {
      $json = $manifest | ConvertTo-Json -Depth 6 -Compress
      Set-Content -LiteralPath $manifestPath -Value $json -Encoding UTF8
      # also write steps_log as separate file for convenience
      ($steps | ConvertTo-Json -Depth 6 -Compress) | Set-Content -LiteralPath $logPath -Encoding UTF8
      $steps += [ordered]@{ ts = (Ts); tool = '"'write_file'; action = 'write_manifest'; inputs = [ordered]@{ path =
        "'$manifestPath }; outputs = [ordered]@{ bytes = ([Text.Encoding]::UTF8.GetByteCount($json)) }; rc = 0; nonce
        = $writeNonce }
    } catch {


• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference='"'Stop'

    function New-Nonce { [guid]::NewGuid().ToString() }
    function Ts { Get-Date -AsUTC -Format o }

    "'$steps = @()
    $base = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'
    "'$expectedSrc = Join-Path $base '"'source_project'
    "'$src = $expectedSrc
    $outDir = Join-Path $base '"'output'
    "'$zipPath = Join-Path $outDir '"'project.teia.zip'
    "'$manifestPath = Join-Path $outDir '"'project.manifest.json'
    "'$logPath = Join-Path $outDir '"'project.steps_log.json'

    # Ensure output dir exists
    if (-not (Test-Path -LiteralPath "'$outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

    # PLAN attempt 1
    $planNonce = New-Nonce
    if (-not (Test-Path -LiteralPath $src)) {
      $steps += [ordered]@{ ts = (Ts); tool = '"'fs'; action = 'plan_list_and_size'; inputs = [ordered]@{ path =
        "'$src }; outputs = [ordered]@{ error = "source path not found" }; rc = 1; nonce = $planNonce }
      # Try auto-correct: find a single plausible source directory
      $acNonce = New-Nonce
      $candidates = Get-ChildItem -LiteralPath $base -Directory -ErrorAction SilentlyContinue | Where-Object
        { $_.Name -match '"'source' -or "'$_.Name -match '"'project' }
      # Filter to those with files
      "'$candidates = $candidates | Where-Object { (Get-ChildItem -LiteralPath $_.FullName -Recurse -File
        -ErrorAction SilentlyContinue | Select-Object -First 1) }
      if ($candidates.Count -eq 1) {
        $src = $candidates[0].FullName
        $steps += [ordered]@{ ts = (Ts); tool = '"'fs'; action = 'auto_correct_source_path'; inputs =
        [ordered]@{ expected = "'$expectedSrc }; outputs = [ordered]@{ selected = $src }; rc = 0; nonce = $acNonce }
      } elseif ($candidates.Count -gt 1) {
        $steps += [ordered]@{ ts = (Ts); tool = '"'fs'; action = 'auto_correct_source_path'; inputs =
        [ordered]@{ expected = "'$expectedSrc }; outputs = [ordered]@{ error = '"'ambiguity'; candidates =
        ("'$candidates | ForEach-Object { $_.FullName }) }; rc = 2; nonce = $acNonce }
        $err = [ordered]@{ error = '"'ambiguity_error'; details = 'Multiple plausible source directories found';
        candidates = ("'$candidates | ForEach-Object { $_.FullName }); steps_log = $steps }
        $err | ConvertTo-Json -Depth 6 -Compress
        exit 0
      } else {
        $steps += [ordered]@{ ts = (Ts); tool = '"'fs'; action = 'auto_correct_source_path'; inputs =
        [ordered]@{ expected = "'$expectedSrc }; outputs = [ordered]@{ error = '"'no candidates' }; rc = 3; nonce
        = "'$acNonce }
        $err = [ordered]@{ error = '"'source_not_found'; details = \"Path not found: "'$expectedSrc"; steps_log
        = $steps }
        $err | ConvertTo-Json -Depth 6 -Compress
        exit 0
      }
    }

    # Re-run plan with resolved $src
    try {
      $files = Get-ChildItem -LiteralPath $src -Recurse -File -ErrorAction Stop
      $totalBytes = ($files | Measure-Object -Property Length -Sum).Sum
      $entries = $files.Count
      $planOut = [ordered]@{ entries = $entries; total_bytes = ($totalBytes | ForEach-Object { $_ }) }
      $steps += [ordered]@{ ts = (Ts); tool = '"'fs'; action = 'plan_list_and_size'; inputs = [ordered]@{ path =
        "'$src }; outputs = $planOut; rc = 0; nonce = (New-Nonce) }
    } catch {
      $steps += [ordered]@{ ts = (Ts); tool = '"'fs'; action = 'plan_list_and_size'; inputs = [ordered]@{ path =
        "'$src }; outputs = [ordered]@{ error = $_.ToString() }; rc = 1; nonce = (New-Nonce) }
      $err = [ordered]@{ error = '"'plan_failed'; details = "'$_.ToString(); steps_log = $steps }
      $err | ConvertTo-Json -Depth 6 -Compress
      exit 0
    }

    # DRY_RUN
    $steps += [ordered]@{ ts = (Ts); tool = '"'compress_dir'; action = 'dry_run'; inputs = [ordered]@{ src = "'$src;
        dst = $zipPath; format = '"'zip'; dry_run = "'$true }; outputs = [ordered]@{ ok = $true; bytes_written =
        $totalBytes; estimated_entries = $entries }; rc = 0; nonce = (New-Nonce) }

    # EXECUTE
    $artifactSize = 0
    $artifactSha = '"''
    try {
      if (Test-Path -LiteralPath "'$zipPath) { Remove-Item -LiteralPath $zipPath -Force }
      Compress-Archive -Path (Join-Path $src '"'*') -DestinationPath "'$zipPath -CompressionLevel Optimal -Force
      $artifactSize = (Get-Item -LiteralPath $zipPath).Length
      $steps += [ordered]@{ ts = (Ts); tool = '"'compress_dir'; action = 'execute'; inputs = [ordered]@{ src
        = "'$src; dst = $zipPath; format = '"'zip' }; outputs = [ordered]@{ ok = "'$true; bytes_written =
        $artifactSize }; rc = 0; nonce = (New-Nonce) }

      $artifactSha = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLower()
      $steps += [ordered]@{ ts = (Ts); tool = '"'compute_hash'; action = 'sha256_file'; inputs = [ordered]@{ path
        = "'$zipPath; algorithm = '"'SHA256' }; outputs = [ordered]@{ sha256 = "'$artifactSha }; rc = 0; nonce
        = (New-Nonce) }
    } catch {
      $steps += [ordered]@{ ts = (Ts); tool = '"'compress_dir'; action = 'execute'; inputs = [ordered]@{ src =
        "'$src; dst = $zipPath; format = '"'zip' }; outputs = [ordered]@{ error = "'$_.ToString() }; rc = 1; nonce
        = (New-Nonce) }
      $err = [ordered]@{ error = '"'compression_failed'; details = "'$_.ToString(); steps_log = $steps }
      $err | ConvertTo-Json -Depth 6 -Compress
      exit 0
    }

    # WRITE_MANIFEST (initial)
    $generatedAt = (Ts)
    $manifest = [ordered]@{
      artifact = $zipPath
      artifact_size_bytes = $artifactSize
      artifact_sha256 = $artifactSha
      source_path = $src
      generated_at = $generatedAt
      steps_log = $steps
    }

    try {
      $json = $manifest | ConvertTo-Json -Depth 6 -Compress
      Set-Content -LiteralPath $manifestPath -Value $json -Encoding UTF8
      ($steps | ConvertTo-Json -Depth 6 -Compress) | Set-Content -LiteralPath $logPath -Encoding UTF8
      $steps += [ordered]@{ ts = (Ts); tool = '"'write_file'; action = 'write_manifest'; inputs = [ordered]@{ path =
        "'$manifestPath }; outputs = [ordered]@{ bytes = ([Text.Encoding]::UTF8.GetByteCount($json)) }; rc = 0; nonce
        = (New-Nonce) }
    } catch {
      $steps += [ordered]@{ ts = (Ts); tool = '"'write_file'; action = 'write_manifest'; inputs = [ordered]@{ path =
        "'$manifestPath }; outputs = [ordered]@{ error = $_.ToString() }; rc = 1; nonce = (New-Nonce) }
      $err = [ordered]@{ error = '"'write_manifest_failed'; details = "'$_.ToString(); steps_log = $steps }
      $err | ConvertTo-Json -Depth 6 -Compress
      exit 0
    }

    # VERIFY
    $verifyErrors = @()
    $valid = $true
    try {
      $schemaPath = Join-Path $base '"'schemas\\\\manifest_schema.json'
      "'$schemaObj = Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json
      if (-not $manifest.artifact) { $verifyErrors += '"'artifact missing'; "'$valid = $false }
      if (-not $manifest.source_path) { $verifyErrors += '"'source_path missing'; "'$valid = $false }
      if (-not $manifest.generated_at) { $verifyErrors += '"'generated_at missing'; "'$valid = $false }
      if ($manifest.artifact_sha256 -notmatch '"'"'^[a-f0-9]{64}$'"') { "'$verifyErrors += '"'artifact_sha256 invalid
        format'; "'$valid = $false }
      if (-not (Test-Path -LiteralPath $manifest.artifact)) { $verifyErrors += '"'artifact file not found'; "'$valid
        = $false }
      else {
        $fsz = (Get-Item -LiteralPath $manifest.artifact).Length
        if ($fsz -le 0) { $verifyErrors += '"'artifact_size_bytes <= 0'; "'$valid = $false }
        if ($manifest.artifact_size_bytes -ne $fsz) { $verifyErrors += "artifact_size_bytes mismatch (expected $fsz,
        got $($manifest.artifact_size_bytes))"; $valid = $false }
        $rehash = (Get-FileHash -LiteralPath $manifest.artifact -Algorithm SHA256).Hash.ToLower()
        if ($rehash -ne $manifest.artifact_sha256) { $verifyErrors += '"'artifact_sha256 mismatch'; "'$valid =
        $false }
      }
      $steps += [ordered]@{ ts = (Ts); tool = '"'validator.run'; action = 'verify_manifest_and_integrity'; inputs =
        [ordered]@{ schema_path = "'$schemaPath; object_path = $manifestPath }; outputs = [ordered]@{ valid = $valid;
        errors = $verifyErrors }; rc = ($(if($valid){0}else{1})); nonce = (New-Nonce) }
    } catch {
      $steps += [ordered]@{ ts = (Ts); tool = '"'validator.run'; action = 'verify_manifest_and_integrity'; inputs =
        [ordered]@{ }; outputs = [ordered]@{ error = "'$_.ToString() }; rc = 1; nonce = (New-Nonce) }
      $err = [ordered]@{ error = '"'verify_failed'; details = "'$_.ToString(); steps_log = $steps }
      $err | ConvertTo-Json -Depth 6 -Compress
      exit 0
    }

    if (-not $valid) {
      $err = [ordered]@{ error = '"'verification_failed'; details = "'$verifyErrors; steps_log = $steps }
      $err | ConvertTo-Json -Depth 6 -Compress
      exit 0
    }

    # Update manifest with final steps_log and re-save
    $manifest.steps_log = $steps
    $finalJson = $manifest | ConvertTo-Json -Depth 6 -Compress
    Set-Content -LiteralPath $manifestPath -Value $finalJson -Encoding UTF8
    ($steps | ConvertTo-Json -Depth 6 -Compress) | Set-Content -LiteralPath $logPath -Encoding UTF8

    # Output final manifest JSON
    $finalJson
    '

> {"error":"source_not_found","details":"Path not found: D:\Teia\TEIA_NUCLEO\offline\nano\source_project","steps_log":
  [{"ts":"2025-09-26T20:33:29.2552888Z","tool":"fs","action":"plan_list_and_size","inputs":
  {"path":"D:\Teia\TEIA_NUCLEO\offline\nano\source_project"},"outputs":{"error":"source
  path not found"},"rc":1,"nonce":"43503a11-183d-4b4f-999c-c36fa7df94a6"},
  {"ts":"2025-09-26T20:33:29.2893111Z","tool":"fs","action":"auto_correct_source_path","inputs":
  {"expected":"D:\Teia\TEIA_NUCLEO\offline\nano\source_project"},"outputs":{"error":"no
  candidates"},"rc":3,"nonce":"6db375a2-dc3a-481c-b6f0-894ebdcf63a8"}]}

---

### ASSISTENTE

Fonte não encontrada. Forneço dois scripts PowerShell: diagnóstico e autocorreção não destrutiva (cria *junction* apontando `source_project` para o candidato único). Execute o diagnóstico primeiro.  

**1) Diagnóstico — lista pastas, contagem de arquivos e tamanho**
```powershell
# Diagnose: mostra candidatos e metadados
$base = 'D:\Teia\TEIA_NUCLEO\offline\nano'
$expected = Join-Path $base 'source_project'

Write-Output "Base: $base"
Write-Output "Expected source path: $expected"
Get-ChildItem -Path $base -Directory | ForEach-Object {
  $dir = $_.FullName
  $files = Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue
  $count = ($files | Measure-Object).Count
  $size = ($files | Measure-Object -Property Length -Sum).Sum
  [pscustomobject]@{
    Name = $_.Name
    FullName = $dir
    Files = $count
    SizeBytes = ($size -as [int64])
  }
} | Sort-Object -Property Files -Descending | Format-Table -AutoSize
```

**2) Autocorreção (não destrutiva) — cria junction se houver exatamente 1 candidato plausível**
```powershell
# Auto-correct: cria junction apenas se houver 1 candidato plausível
$base = 'D:\Teia\TEIA_NUCLEO\offline\nano'
$expected = Join-Path $base 'source_project'

# localizar candidatos plausíveis (nome contém 'source' ou 'project' ou contém arquivos)
$candidates = Get-ChildItem -Path $base -Directory | Where-Object {
  $_.Name -match 'source|project' -or (Get-ChildItem -Path $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1)
}

if ($candidates.Count -eq 1) {
  $target = $candidates[0].FullName
  if (-not (Test-Path -LiteralPath $expected)) {
    # cria junction (usa mklink /J para máxima compatibilidade)
    $mk = "mklink /J `"$expected`" `"$target`""
    $proc = Start-Process -FilePath cmd.exe -ArgumentList "/c",$mk -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -eq 0 -and (Test-Path -LiteralPath $expected)) {
      Write-Output "Junction criada: $expected -> $target"
    } else {
      Write-Error "Falha ao criar junction. ExitCode=$($proc.ExitCode). Verifique permissões."
    }
  } else {
    Write-Output "Caminho esperado já existe: $expected (nenhuma ação tomada)."
  }
} else {
  Write-Output "Não há 1 candidato único. CandidateCount=$($candidates.Count). Rode o script de diagnóstico."
  $candidates | Select-Object Name,FullName | Format-Table -AutoSize
}
```

Resumo mínimo de ação:
- Rode o script **Diagnóstico**.  
- Se identificar um único candidato plausível e aprovar a correção, rode o script **Autocorreção**.  
- Se preferir que eu crie a correção automaticamente sem sua intervenção, diga “autorizar correção” e eu forneço a versão que tenta criar a junction diretamente (pode requerer permissões).

---

