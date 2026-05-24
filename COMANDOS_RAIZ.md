# COMANDOS RAIZ — TEIA-Omega
> Folha de referência operacional | Operador: Felippe Barcelos
> Raiz do motor: `D:\Teia\Agents\PaperclipAI` | Raiz da memória: `D:\TEIA_CLAUDE_AWAKENING`

---

## 1. Painel de Controle (Dashboard + Bridge)

O painel visual requer o Bridge Server ativo para processar seeds.
Abrir os dois em terminais separados:

**Terminal A — Bridge Server (porta 8124):**
```powershell
cd "D:\Teia\Agents\PaperclipAI"
python bridge_server.py
```

**Terminal B — Dashboard (abrir no browser):**
```powershell
start "D:\TEIA_CLAUDE_AWAKENING\index30.aion.html"
```

> O painel chama `POST http://localhost:8124/restore` ao clicar em uma seed.
> Manter o Bridge rodando enquanto usar o dashboard.

---

## 2. Mineração de Novos Chats

Processa todos os arquivos de `D:\TEIA_CLAUDE_AWAKENING`, gera seeds Delta
e reclassifica com o Dicionário Universal ativo.

**Ciclo completo (recomendado após adicionar novos arquivos):**
```powershell
cd "D:\Teia\Agents\PaperclipAI"

# Passo 1 — Re-treinar o dicionário com o corpus atualizado
python minerador_teia.py --treinar

# Passo 2 — Resetar estado para forçar reclassificação total
Copy-Item mineracao_estado.json mineracao_estado.bak.json
$e = Get-Content mineracao_estado.json | ConvertFrom-Json
@{ versao=$e.versao; ultimo_bloco_concluido=-1; total_arquivos=0; total_blocos=0; blocos=@{}; erros=@(); iniciado_em=(Get-Date -Format o); atualizado_em=$null } | ConvertTo-Json | Set-Content mineracao_estado.json -Encoding UTF8

# Passo 3 — Minerar
python minerador_teia.py

# Passo 4 — Atualizar Síntese Evolutiva
python gerar_sintese_evolutiva.py

# Passo 5 — Benchmark (opcional, para medir ganho de predição)
python benchmark_ressonancia.py
```

**Mineração rápida (só extensões de alta ressonância: .md .json .txt):**
```powershell
python minerador_teia.py --modo-rapido
```

**Curadoria Ativa (auto-aprovação ≥70% Delta-Predicao; quarentena automática <10% DP+≥1 MB; pausa manual apenas zona inédita 20–60%):**
```powershell
python minerador_teia.py --curadoria
```

> Lógica autónoma (DIRETIVA_DELTA_006):
> - `auto_aprovado` — bloco minado sem interrupção, log apenas
> - `alta_entropia` — bloco movido para `quarentena/`, registo em `TEIA_Relatorio_Sessao.json`
> - `inedito` — pausa técnica, operador decide com [S/N]
> - Blocos sem mapa de intuição: processados normalmente (sem classificação)

**Tabela de modos de execução:**

| Modo | Comando | Uso recomendado |
|------|---------|-----------------|
| Completo | `python minerador_teia.py` | Após reset de estado |
| Rápido | `python minerador_teia.py --modo-rapido` | Corpus já estável, só .md/.json/.txt |
| Curadoria Ativa | `python minerador_teia.py --curadoria` | Novos ficheiros com revisão autónoma |
| Treino | `python minerador_teia.py --treinar` | Antes de qualquer ciclo completo |

---

## 3. Auditoria de Integridade (Prova Real)

Valida que uma seed pode restaurar o arquivo original com SHA-256 idêntico.
Seleciona automaticamente o maior arquivo acessível do corpus.

```powershell
cd "D:\Teia\Agents\PaperclipAI"
python prova_real_integridade.py
```

**Resultado esperado:**
```
[Delta] Veredito: Integridade Delta Confirmada
[Delta] exit_code: 0
```

O arquivo restaurado fica em `D:\TEIA_CLAUDE_AWAKENING\restored_test\`.
O log detalhado em `prova_real_integridade.log`.

---

## 4. Restaurar Qualquer Bloco da Biblioteca

**Via terminal (direto, sem dashboard):**
```powershell
cd "D:\Teia\Agents\PaperclipAI"
python restore_engine.py Delta_bloco_XXXX_YYYYYYYY.seed.json
```

Substitua `Delta_bloco_XXXX_YYYYYYYY.seed.json` pelo nome exato da seed.
Seeds ficam em `D:\Teia\Agents\PaperclipAI\seeds\`.
Arquivos restaurados vão para `D:\TEIA_CLAUDE_AWAKENING\restored\`.

**Listar seeds disponíveis:**
```powershell
Get-ChildItem "D:\Teia\Agents\PaperclipAI\seeds\Delta_bloco_*.seed.json" |
  Select-Object Name, LastWriteTime |
  Sort-Object LastWriteTime -Descending
```

**Via dashboard (com Bridge ativo):**
Inicie o Bridge (Comando 1) → abra o painel → clique na seed desejada.

---

## 5. Gerar Novo Backup Golden Master

Recria `TEIA_CORE_GOLDEN_MASTER_v1.zip` com ambos os repositórios completos.
Exclui automaticamente: `node_modules`, `__pycache__`, `restored/`, o próprio ZIP.

```powershell
cd "D:\TEIA_CLAUDE_AWAKENING"
python criar_golden_master.py
```

**Resultado esperado:**
```
[Delta] GOLDEN MASTER COMPLETO
[Delta] Total de arquivos : ~5330+
[Delta] Tamanho ZIP       : ~543 MB
[Delta] SHA-256 ZIP       : <hash>
```

O ZIP fica em `D:\TEIA_CLAUDE_AWAKENING\TEIA_CORE_GOLDEN_MASTER_v1.zip`.

---

## BÔNUS — Supra IA TEIA (Mente Ativa Local)

Loop conversacional com LLM local (Ollama). Cada resposta vira uma seed Delta.

```powershell
# Verificar pré-requisitos
cd "D:\Teia\Agents\PaperclipAI"
python teia_supra_cognition.py --check

# Iniciar conversa
python teia_supra_cognition.py
```

> Requer Ollama rodando: `ollama serve` (em terminal separado).
> Seeds geradas em `seeds\Delta_supra_*.seed.json`.
> Comandos no loop: `limpar` (reset histórico) | `sair` (encerrar).

---

## Ciclo Operacional Típico

```
1. Novos arquivos adicionados ao corpus
       ↓
2. python minerador_teia.py --treinar   ← atualiza o dicionário
       ↓
3. [reset estado] + python minerador_teia.py   ← reclassifica tudo
       ↓
4. python gerar_sintese_evolutiva.py   ← atualiza Merkles e diretivas
       ↓
5. python prova_real_integridade.py   ← valida integridade (deve ser exit 0)
       ↓
6. python criar_golden_master.py   ← salva backup local
       ↓
7. git add + git commit + git push   ← versiona no GitHub
```

---

## Referência Rápida de Paths

| Artefato | Caminho |
|----------|---------|
| Motor (scripts Python) | `D:\Teia\Agents\PaperclipAI\` |
| Seeds Delta | `D:\Teia\Agents\PaperclipAI\seeds\` |
| Dicionário Universal | `D:\Teia\Agents\PaperclipAI\TEIA_Dicionario_Universal.json` |
| Síntese Evolutiva | `D:\Teia\Agents\PaperclipAI\TEIA_Sintese_Evolutiva.json` |
| Estado da Mineração | `D:\Teia\Agents\PaperclipAI\mineracao_estado.json` |
| Dashboard | `D:\TEIA_CLAUDE_AWAKENING\index30.aion.html` |
| Corpus (base de conhecimento) | `D:\TEIA_CLAUDE_AWAKENING\` |
| Arquivos Restaurados | `D:\TEIA_CLAUDE_AWAKENING\restored\` |
| Golden Master ZIP | `D:\TEIA_CLAUDE_AWAKENING\TEIA_CORE_GOLDEN_MASTER_v1.zip` |
| Repo motor (GitHub) | `github.com/felippebarcelos/teia-omega-paperclip` |
| Repo memória (GitHub) | `github.com/felippebarcelos/teia-omega-awakening` |
