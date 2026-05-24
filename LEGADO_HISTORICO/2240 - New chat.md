# 2240 - New chat

### USUÁRIO

Você é um Otimizador Duplo de Prompts de IA.  
Analise o prompt fornecido e decida:  
- Se ele estiver prolixo ou pouco claro → refine (remova ruído/redundância e preserve exatamente a intenção original).  
- Se ele carecer de contexto ou detalhes → expanda (adicione apenas contexto relevante para realizar a intenção).  
Garanta que o resultado seja mais claro e eficaz do que o original.  
Retorne e apresente apenas o prompt otimizado — sem explicações, comentários ou texto extra.   
O Prompt a ser resultado deve possuir semântica, etimologia e núcleo conceitual com ressonância completa coerente denotativa!
[# PROMPT DE GERAÇÃO DE TESTE (TEIA v0.3.1)

# ==============================================================================
# CONTEXTO & PERSONA
# ==============================================================================
# Você é o Codex CLI, operando como Arquiteto Procedural Determinístico.
# Foco: Gerar a suíte de testes (o "auditor") para o Core v0.3.1.
# Ambiente: PowerShell 7, Raiz 'D:\Teia\TEIA_NUCLEO\offline\nano'

# ==============================================================================
# ARTEFATO DE ENTRADA (O Núcleo a ser testado)
# ==============================================================================
# O código-fonte do TEIA-Core v0.3.1 (baseado no D:\TEIA-Core-v0.3.0.ps1 + patches)
# JÁ EXISTE em 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Core-v0.3.1.ps1'.
# Ele contém os ops: gen.repeat, write.hex, rle.det, lz.det, gen.fractal,
# apply.huffman_deterministic, gen.ml_pattern, gen.motion_vector.
# Ele contém os comandos: restore, restore.predictive, compress.stream.

# ==============================================================================
# CHECKLIST DE VALIDAÇÃO (O "Contrato" a ser verificado)
# ==============================================================================
# 1) Canonicidade do seed (re-serialização idêntica): `Read-Json` deve passar sem `throw`.
# 2) Core lock: `core_sha256` do seed == hash do core (`TEIA-Core-v0.3.1.ps1`) em execução.
# 3) Round-trip: `restore` -> `output_sha256` e `output_size` batem com os valores na seed.
# 4) Idempotência: Executar `restore` 3 vezes -> hashes SHA256 idênticos.
# 5) Região (`restore.predictive`): Restaurar 3 janelas distintas (`predict_factor=0`) -> SHA256 de CADA janela deve ser IDÊNTICO ao SHA256 do slice correspondente do arquivo original (ou do restaurado completo).
# 6) MDL (Heurística): Executar `compress.stream` -> Relatar `seed_bytes/orig_bytes`, `ops_count`, e a DECISÃO da heurística (skew/fractal/fallback). (Gate `gen.fractal` deve ser respeitado).
# 7) Vacina epistêmica (Igualdade Estrita): NUNCA aceitar "parecido". SÓ aceitar igualdade (SHA256 e `output_size`).

# ==============================================================================
# TAREFA ÚNICA E IMEDIATA (Sem Autoloop)
# ==============================================================================
# 1. Gere o script `Run-TEIA-Core-Tests-v0.3.1.ps1`.
# 2. O script DEVE ser escrito em PowerShell 7 puro, ser idempotente e seguro.
# 3. O script deve, por padrão, usar os arquivos de teste gerados pelo `Kickstart-First-Cycle.ps1`
#    (ex: 'D:\Teia\TEIA_NUCLEO\offline\nano\targets\sample_1mb.bin', '...sample_4mb_skew.bin').
# 4. O script deve executar TODOS os 7 itens do CHECKLIST acima.
# 5. O script deve gerar os relatórios `verification_report.json` (detalhes pass/fail) e `ops_summary.json` (decisões MDL).
# 6. O script deve imprimir "STATUS=OK" e ter Exit Code 0 se TUDO passar, ou "STATUS=FAIL" e Exit Code 1 se QUALQUER item falhar.
# 7. NÃO execute o script. Apenas GERE o conteúdo do script `Run-TEIA-Core-Tests-v0.3.1.ps1`.

# Responda APENAS com o conteúdo do script `Run-TEIA-Core-Tests-v0.3.1.ps1`.]

---

### ASSISTENTE

[# TEIA v0.3.1 — Prompt de Geração da Suíte de Testes (Codex CLI)

# PAPEL E AMBIENTE
# Você é o Codex CLI atuando como Arquiteto Procedural Determinístico.
# Objetivo: gerar o script de testes (auditor) do Core v0.3.1.
# Ambiente: PowerShell 7. Raiz: D:\Teia\TEIA_NUCLEO\offline\nano

# ARTEFATO SOB TESTE
# Core em: D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Core-v0.3.1.ps1
# Ops disponíveis: gen.repeat, write.hex, rle.det, lz.det, gen.fractal, apply.huffman_deterministic, gen.ml_pattern, gen.motion_vector
# Comandos: restore, restore.predictive, compress.stream

# ENTRADAS DE TESTE
# Usar por padrão os arquivos de: D:\Teia\TEIA_NUCLEO\offline\nano\targets\
# Exemplos: sample_1mb.bin, sample_4mb_skew.bin (se existirem).
# Seeds serão geradas on-the-fly via compress.stream (se ausentes) e salvas em D:\Teia\TEIA_NUCLEO\offline\nano\seeds\ com convenção {nome}.teia.json

# CHECKLIST (CONTRATO DE VALIDAÇÃO)
# 1) Canonicidade do seed: desserialização JSON (Read-Json) sem exceções.
# 2) Core lock: seed.core_sha256 == SHA256 do arquivo TEIA-Core-v0.3.1.ps1 efetivamente carregado.
# 3) Round-trip: restore -> SHA256 e tamanho do output idênticos aos valores registrados na seed.
# 4) Idempotência: executar restore 3 vezes e obter SHA256 idênticos nos 3 outputs.
# 5) Região (restore.predictive): restaurar três janelas (64 KiB) em início/meio/fim com predict_factor=0
#    e validar SHA256 de cada janela contra o slice correspondente do arquivo original (ou do restaurado completo).
# 6) MDL (Heurística): executar compress.stream e registrar seed_bytes/orig_bytes, ops_count e decisão (skew/fractal/fallback).
#    Falhar se gen.fractal for aplicado quando a decisão != 'fractal'. Caso contrário, apenas registrar.
# 7) Vacina epistêmica: apenas igualdade estrita (SHA256 e tamanho). Qualquer divergência => FAIL.

# REQUISITOS DO SCRIPT A GERAR (ÚNICA TAREFA, SEM AUTOLOOP)
# • Nome do script: Run-TEIA-Core-Tests-v0.3.1.ps1
# • PowerShell 7 puro, idempotente e seguro (sem módulos externos).
# • Paths fixos:
#   $Root = 'D:\Teia\TEIA_NUCLEO\offline\nano'
#   $Core = "$Root\TEIA-Core-v0.3.1.ps1"
#   $Targets = "$Root\targets"
#   $Seeds = "$Root\seeds"
# • Se não houver seeds para um alvo, gerar via compress.stream antes dos testes.
# • Restaurar outputs em $Root\restored\ e janelas preditivas em $Root\predictive\.
# • Relatórios em $Root\verification_report.json (pass/fail detalhado) e $Root\ops_summary.json (decisões MDL).
# • Console: imprimir "STATUS=OK" e sair com código 0 se tudo passar; caso contrário "STATUS=FAIL" e código 1.
# • Não executar o script agora: apenas GERAR seu conteúdo.

# RESPOSTA
# Responda APENAS com o conteúdo do arquivo Run-TEIA-Core-Tests-v0.3.1.ps1 (sem texto extra).]

---

