# 2034 - Otimização de prompt TEIA

### USUÁRIO

Você é um Otimizador Duplo de Prompts de IA.  
Analise o prompt fornecido e decida:  
- Se ele estiver prolixo ou pouco claro → refine (remova ruído/redundância e preserve exatamente a intenção original).  
- Se ele carecer de contexto ou detalhes → expanda (adicione apenas contexto relevante para realizar a intenção).  
Garanta que o resultado seja mais claro e eficaz do que o original.  
Retorne e apresente apenas o prompt otimizado — sem explicações, comentários ou texto extra.  
[Você é o delta agente teia, Forneça o script mestre idempotente que resolva de maneira cirurgica integrada cada bloco e forneça quando tiver o conteúdo que garanta que no meu powershell tenha retornos coerentes para assinalar todos os blocos com check e finalizar essa tarefa, use todos os recursos necessário, inclusive tempo. (pipeline)

 Fix-Manifests v2 (tolerante)
Rodar até zerar pendências. Ele precisa preencher seed/fragSize/version lendo variações (dna.seed, meta.size etc.).
pwsh -File .\TEIA-DropIn.ps1 -Root . -FixManifests

 Fallback de manifesto no Restore (padrão)
Garantir que o DropIn tenta: micro-bundle → consolidated (via LATEST_PACKAGE.txt) → reconstrução pelo índice → scan total de .\backups\*.zip.
(Já deixa habilitado dentro do próprio -Restore.)

 Pular itens irrecuperáveis
No -Restore, -TopN e -All, pular entradas com restore_status == "seed_missing" (logar [SKIP]).

 Marcar entradas órfãs
Adicionar comando idempotente:
pwsh -File .\TEIA-DropIn.ps1 -Root . -MarkSeedMissing -Hash <sha256>

 Evitar armadilha do System32 e wildcard em ZIP
Em todos os scripts:

Ancorar Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

Resolver o ZIP antes de abrir (Get-ChildItem .\backups\teia_micro_knowledge_*.zip | sort … | select -First 1)

Chamar ExtractToFile no entry (não no ZipArchive).

 Bench só após restore existir
No -Bench, checar restored_* e falhar claro se não existir (já tá disparando — manter).

🧬 Resolução dos órfãos (seed ausente)

 Varredura exaustiva por manifesto
Scan de todos os zips em .\backups pelo hash; se achar, extrair .fractal_manifest.<hash>.json.

 Se não achar → marcar seed_missing
Atualizar fractal_index.json com restore_status/restore_note para não quebrar lotes.

 Se tiver o arquivo bruto (e o SHA256 bate):
Refractalizar: gerar seed canônica, criar .fractal_manifest.<hash>.json, atualizar índice, limpar flags.
(Deixar utilitário TEIA-ReFractalize-FromRaw.ps1 pronto.)

🧗‍♂️ Retomar a sequência “verde”

 Restore alvo grande (com fallback ativo)
pwsh -File .\TEIA-DropIn.ps1 -Root . -Restore -Name "<alvo>"

 Preload (opcional) e Benchmark
pwsh -File .\TEIA-DropIn.ps1 -Root . -Bench -Name "<alvo>"

 Prova P0 (sempre consolidar)
pwsh -File .\TEIA-DropIn.ps1 -Root . -Prova

 Top-N (agora pulando seed_missing)
pwsh -File .\TEIA-DropIn.ps1 -Root . -TopN 5

🖼️ FS virtual (demo/uso humano)

 Instalar WinFsp e apontar memfs-x64.exe correto no DropIn.
pwsh -File .\TEIA-DropIn.ps1 -Root . -Mount -MountPoint X:

🗄️ Modo “armazenamento on-demand” (PC magrelo)

 C:\TEIA_ROOT leve (seeds/manifests/índice), D:\ Núcleo offline (operações).

 Sentinela de escrita: TEIA-Sentinel.ps1 para fractalizar novos arquivos e registrar no índice.

 Cleanup automático: remover restored_* antigos (LIFO, TTL).

 Cripto opcional das seeds/manifests sensíveis.

 Viewer simples (CLI/HTML) de status: restaurados, tempo, hash, custo.

📦 Pacote de evidências (pra vender/mostrar)

 prova_real_P0.md atualizado + dna_preload.log + dna_benchmark_io.json

 manifest.json, relatorio_arquivos.csv, proofs/* no micro-bundle

 Mini-resumo executivo (1 página) com: tempo, custo estimado/restore, IO físico (~KB), SHA256 ok.

Se quiser, eu já te entrego o DropIn consolidado com: fallback completo (inclui varredura total), -MarkSeedMissing, skip elegante, e guard-rails contra System32/wildcards — e um ReFractalize-FromRaw enxuto. Só dizer “manda os scripts” e eu te posto o conteúdo pronto pra colar.]

---

### ASSISTENTE

Você é o delta agente TEIA. Forneça um script mestre idempotente que integre e resolva de forma cirúrgica todos os blocos listados, garantindo retornos claros no PowerShell com checks em cada etapa. Utilize todos os recursos necessários, incluindo tempo de execução, para assegurar consistência no pipeline.

### Fix-Manifests v2 (tolerante)
- Rodar até zerar pendências.
- Preencher `seed/fragSize/version` lendo variações (`dna.seed`, `meta.size` etc.).
```powershell
pwsh -File .\TEIA-DropIn.ps1 -Root . -FixManifests
```

### Fallback de manifesto no Restore
- Ordem: micro-bundle → consolidated (`LATEST_PACKAGE.txt`) → reconstrução pelo índice → scan total em `.\backups\*.zip`.
- Habilitado dentro do próprio `-Restore`.

### Tratamento de casos especiais
- **Pular irrecuperáveis**: em `-Restore`, `-TopN`, `-All`, ignorar `restore_status == "seed_missing"` (logar `[SKIP]`).
- **Marcar órfãos**: comando idempotente para sinalizar hashes sem seed:
```powershell
pwsh -File .\TEIA-DropIn.ps1 -Root . -MarkSeedMissing -Hash <sha256>
```

### Guard-rails globais
- Fixar `Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)`.
- Resolver ZIP com `Get-ChildItem` antes de abrir.
- Usar `ExtractToFile` diretamente no entry, sem wildcard em `ZipArchive`.
- `-Bench` só roda se `restored_*` existir.

### Resolução de órfãos (seed ausente)
1. Varredura em todos os zips de `.\backups` pelo hash → extrair `.fractal_manifest.<hash>.json`.
2. Se não achar → marcar `seed_missing` no índice.
3. Se encontrar arquivo bruto com SHA256 válido → refractalizar com `TEIA-ReFractalize-FromRaw.ps1`:
   - Gerar seed canônica.
   - Criar manifesto.
   - Atualizar índice e limpar flags.

### Sequência verde (pipeline principal)
1. Restore alvo com fallback:
   ```powershell
   pwsh -File .\TEIA-DropIn.ps1 -Root . -Restore -Name "<alvo>"
   ```
2. Preload (opcional).
3. Benchmark:
   ```powershell
   pwsh -File .\TEIA-DropIn.ps1 -Root . -Bench -Name "<alvo>"
   ```
4. Prova P0 consolidada:
   ```powershell
   pwsh -File .\TEIA-DropIn.ps1 -Root . -Prova
   ```
5. Top-N (pulando `seed_missing`):
   ```powershell
   pwsh -File .\TEIA-DropIn.ps1 -Root . -TopN 5
   ```

### FS virtual (uso humano/demo)
- Instalar WinFsp e apontar `memfs-x64.exe`.
```powershell
pwsh -File .\TEIA-DropIn.ps1 -Root . -Mount -MountPoint X:
```

### Modo armazenamento on-demand (PC leve)
- Estrutura: `C:\TEIA_ROOT` (seeds/manifests/índice) + `D:\` (núcleo offline).
- **Sentinela**: `TEIA-Sentinel.ps1` para fractalizar novos arquivos e registrar índice.
- **Cleanup automático**: remover `restored_*` antigos (LIFO/TTL).
- **Cripto opcional** para seeds/manifests sensíveis.
- **Viewer** (CLI/HTML): status de restaurados, tempo, hash, custo.

### Pacote de evidências
- `prova_real_P0.md` atualizado + `dna_preload.log` + `dna_benchmark_io.json`.
- `manifest.json`, `relatorio_arquivos.csv`, `proofs/*` no micro-bundle.
- Mini-resumo executivo (1 página): tempo, custo por restore, IO físico (~KB), SHA256 ok.

👉 Quando quiser, basta pedir “manda os scripts” para receber o **DropIn consolidado** com:
- Fallback completo (inclui varredura total).
- `-MarkSeedMissing`.
- Skip elegante.
- Guard-rails contra System32/wildcards.
- Utilitário `TEIA-ReFractalize-FromRaw.ps1` pronto.

---

