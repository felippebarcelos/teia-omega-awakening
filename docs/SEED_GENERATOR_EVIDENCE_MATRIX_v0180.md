# SEED_GENERATOR — EVIDENCE MATRIX v0.18.0
**Data:** 2026-05-27  
**Protocolo:** Arqueologia e Auditoria Read-Only v0.18.0  
**Propósito:** Inventário forense de todos os artefatos que compõem ou evidenciam o pipeline gerador de seeds, com análise do que cada um prova e por que o conjunto não constitui um "compressor universal".

---

## Formato das Colunas

| Coluna | Descrição |
|--------|-----------|
| **Evidência** | Nome descritivo do artefato |
| **Caminho** | Localização canônica no sistema de arquivos |
| **Tipo** | Código / Seed / Log / Config / Manifesto |
| **O que prova** | Afirmação verificável sustentada por este artefato |
| **Limitação** | Por que este artefato não demonstra compressão universal |

---

## MATRIZ DE EVIDÊNCIAS

### E01 — Motor CAS atual

| Campo | Valor |
|-------|-------|
| **Evidência** | Motor Ontoprocedural v2.0 — ingesta + gen_dummy_seed |
| **Caminho** | `D:\TEIA_CORE\tools\TEIA-Fractal-Gen-v2.ps1` |
| **Tipo** | Código |
| **O que prova** | Prova a existência de um pipeline CAS funcional: qualquer arquivo é ingerido com SHA-256 verificado, mapeado em `.teia_map.json`, e recebe uma seed de identidade atômica. Idempotência garantida por guarda `Test-Path` antes de cada operação. |
| **Limitação** | `gen_dummy_seed` (única função no `ValidateSet`) preserva o arquivo integral no CAS — a seed resultante é um registro de identidade (head/tail 32B + hash + caminho CAS), **não** uma recipe de reconstrução. Redução de espaço: zero. A seed aponta para o CAS; o conteúdo original permanece intacto. |

---

### E02 — Gerador de Seed Legacy com Detect-Procedural

| Campo | Valor |
|-------|-------|
| **Evidência** | Onto-SeedGen v1.x com detecção estrutural automática |
| **Caminho** | `D:\TEIA_CLAUDE_AWAKENING\Arqueologia do motor AION RISPA\NúcleoCompressorOntoprocedural\Ontologia Procedural\Ontology\TEIA-OntoSeed-Gen.ps1` |
| **Tipo** | Código |
| **O que prova** | Prova a existência de um Planner embrionário autônomo: `Detect-Procedural` classifica automaticamente arquivos como `repeat_byte` ou `repeat_sequence` sem intervenção humana. Para esses padrões, a seed é uma recipe genuína de regeneração — o arquivo não precisa estar no CAS para ser restaurado. |
| **Limitação** | `Detect-Procedural` detecta apenas 2 padrões (byte único constante; sequência periódica de até 64B). Qualquer arquivo fora dessas classes produz `name='none', procedural=false` e a nota explícita: *"restoration not possible without payload or external source."* O vocabulário do Planner embrionário cobre ≈0,01% dos tipos de arquivo do mundo real. |

---

### E03 — Executor de Restauração Legacy

| Campo | Valor |
|-------|-------|
| **Evidência** | Onto-Engine-Restore v1.x — execução determinística de seeds |
| **Caminho** | `D:\TEIA_CLAUDE_AWAKENING\Arqueologia do motor AION RISPA\NúcleoCompressorOntoprocedural\Ontologia Procedural\Ontology\TEIA-OntoEngine-Restore.ps1` |
| **Tipo** | Código |
| **O que prova** | Prova que a arquitetura Executor é correta: dado `generator.name` + `generator.params`, o Executor reconstrói o arquivo byte-a-byte e valida com SHA-256. Sem disk I/O de origem. Sem estado externo além da seed. |
| **Limitação** | Conhece apenas 3 generators: `empty`, `repeat_byte`, `repeat_sequence`. Para qualquer outro `name`, lança `"No procedural generator available"`. O Executor é correto e robusto — mas seu vocabulário é mínimo. A limitação não é o Executor; é o Planner que o alimenta. |

---

### E04 — Prova de Excalibur — SplitMix64 O(1)

| Campo | Valor |
|-------|-------|
| **Evidência** | Motor AION-RISPA com seek O(1) sobre RNG determinístico |
| **Caminho** | `D:\TEIA_CLAUDE_AWAKENING\LEGADO_HISTORICO\TEIA-Motor-Ontoprocedural.ps1` |
| **Tipo** | Código |
| **O que prova** | Prova a propriedade matemática fundamental: `state[n] = semente + n × 0x9E3779B97F4A7C15 (mod 2^64)`. Qualquer bloco de uma sequência SplitMix64 pode ser calculado em O(1) — sem iterar os n blocos anteriores. A prova é validada por comparação de SHA-256 entre blocos gerados via disco e via CPU pura. |
| **Limitação** | A propriedade O(1) se aplica **exclusivamente** a dados que foram gerados por esta função SplitMix64 com esta semente. Para um arquivo PNG, DOCX, ou log de produção, não existe método para descobrir a semente SplitMix64 que teria gerado aqueles bytes — porque esses arquivos não foram gerados por essa função. O motor demonstra a teoria do Executor; não resolve o problema do Planner para dados externos. |

---

### E05 — Prova E2E de Honestidade Entropica

| Campo | Valor |
|-------|-------|
| **Evidência** | SmokeTest E2E — ciclo completo geração→seed→restauração→SHA-256 |
| **Caminho** | `D:\TEIA_CLAUDE_AWAKENING\LEGADO_HISTORICO\TEIA-SmokeTest-E2E-Procedural.ps1` |
| **Tipo** | Código |
| **O que prova** | Prova que o ciclo completo funciona para dados de baixa entropia: cria arquivo com `"TEIA_NUCLEO_PROCEDURAL_VIVA_" × 5000` (padrão periódico), gera seed, restaura via TEIA-Core-v1.0.0.ps1, valida SHA-256 de ponta a ponta. |
| **Limitação** | O arquivo de teste é artificialmente de baixa entropia (string repetida × 5000). Este padrão é detectável por `Detect-Procedural` e restaurável. O teste **não** cobre arquivos reais de alta entropia (fotos, binários compilados, dados cifrados). Prova que o circuito funciona para o caso favorável; não prova que o circuito funciona para casos gerais. |

---

### E06 — Seeds de Prova Procedural (Benchmark D1–D3 class)

| Campo | Valor |
|-------|-------|
| **Evidência** | Seeds de teste para gen.pattern e rle.decode |
| **Caminho** | `D:\TEIA_CORE\procedural_tests\v0161\seeds\` (18 arquivos: `gp01_AB_500k.seed.json` ... `rle05_256bytes_bad.seed.json`) |
| **Tipo** | Seed |
| **O que prova** | Prova que seeds procedurais genuínas existem para domínios sintéticos. Exemplo: `gp01_AB_500k.seed.json` = `{"op":"gen.pattern","pattern_b64":"QUI=","repeat":500000}` → reconstrói 1MB a partir de uma seed de ~120 bytes. Razão de compressão real: 1.000.000 bytes → 120 bytes = 8333× para dados periódicos. |
| **Limitação** | Os dados que essas seeds representam foram **gerados** por `gen.pattern` — o algoritmo gerador era conhecido antes da compressão. Para dados externos com periodicidade similar, o Planner (v0.16.1 ou v0.17.0) precisa detectar o padrão. Fora da classe D1–D3, não há seeds procedurais equivalentes. |

---

### E07 — Seeds de Identidade CAS (Produção)

| Campo | Valor |
|-------|-------|
| **Evidência** | Seeds `gen_dummy_seed` de arquivos reais (piloto) |
| **Caminho** | `D:\TEIA_CORE\seeds\` (3 arquivos: `21c20b15...seed.json`, `a6dc9992...seed.json`, `e5954d06...seed.json`) |
| **Tipo** | Seed |
| **O que prova** | Prova que o pipeline CAS v2.0 está operacional em produção: arquivos reais foram ingeridos, hashados, e suas seeds de identidade gravadas com escrita atômica. O sistema é operacional e auditável. |
| **Limitação** | Seeds do tipo `gen_dummy_seed` são registros de identidade, não recipes de regeneração. O campo `fn: "gen_dummy_seed"` é autoexplicativo: é uma semente de prova de circuito. A restauração ocorre via CAS (`cas_path`), não via recipe. Não há compressão aqui — o CAS armazena o arquivo integral. |

---

### E08 — Fractal Index (Manifesto CAS)

| Campo | Valor |
|-------|-------|
| **Evidência** | Manifesto principal do CAS — 1.3 MB de metadados |
| **Caminho** | `D:\TEIA_CORE\manifests\fractal_index.json` |
| **Tipo** | Manifesto |
| **O que prova** | Prova a escala operacional do CAS: 1.296.950 bytes de manifesto indicam um número expressivo de objetos catalogados. O sistema está em uso real, não é demonstração de laboratório. |
| **Limitação** | Um manifesto grande é evidência de operação — não de compressão. Cada entrada do `fractal_index.json` aponta para um objeto no CAS que armazena o arquivo original. O manifesto catalogado não reduz o espaço de armazenamento; ele organiza e torna auditável o que já está armazenado. |

---

### E09 — Planner Estrutural v0.17.0

| Campo | Valor |
|-------|-------|
| **Evidência** | Analisador estrutural com seletor MDL e critério de honestidade |
| **Caminho** | `D:\TEIA_CLAUDE_AWAKENING\tools\TEIA-Procedural-Planner-v0170.ps1` |
| **Tipo** | Código |
| **O que prova** | Prova que o Planner como camada explícita de software existe (parcialmente): analisa 9 dimensões estruturais de um arquivo e seleciona a estratégia de menor description length. Inclui honestidade entropica: para cada estratégia, `beatsLzma` e `seedWorth` são declarados explicitamente — e em quase todos os casos de dados reais a resposta é `seedWorth="NÃO"`. |
| **Limitação** | O Planner está implementado como **analisador e seletor**, não como **sintetizador de recipe**. Ele recomenda a estratégia mas não gera a seed procedural automaticamente. As estratégias `dict.ref` e `slice.copy` são marcadas `confidence="HIPOTESE"` porque os encoders correspondentes não existem. O Planner completo (que sintetiza a recipe e a valida) ainda não foi implementado. |

---

### E10 — Documento Arquitetural Neuro-Simbólico

| Campo | Valor |
|-------|-------|
| **Evidência** | Consolidação teórica da arquitetura de duas camadas |
| **Caminho** | `D:\TEIA_CORE\docs\TEIA_NEUROSYMBOLIC_ARCHITECTURE_v0185.md` |
| **Tipo** | Documento |
| **O que prova** | Prova que o diagnóstico histórico foi formalizado: "O LLM era o Planner implícito histórico. O PowerShell sozinho não gera recipes semanticamente úteis." A separação Executor/Planner está documentada com definições rigorosas e fluxo causal. |
| **Limitação** | É teoria consolidada — não implementação. A formalização do Planner como componente de software autônomo é o próximo marco do roadmap. O documento não autoriza nem demonstra implementação. |

---

## SÍNTESE: POR QUE O CONJUNTO NÃO É UM "COMPRESSOR UNIVERSAL"

| Ingrediente necessário | Estado atual |
|-----------------------|-------------|
| Executor determinístico com SHA-256 | ✅ Implementado e provado (Fractal-Gen-v2, OntoEngine-Restore, Motor-Ontoprocedural) |
| CAS com ingesta idempotente | ✅ Operacional em produção |
| Planner para padrões sintéticos (D1–D3) | ✅ Funciona para repeat_byte, repeat_sequence, gen.pattern, rle.decode |
| Planner para dados arbitrários de baixa entropia | ⚠️ Parcial — Planner-v0170 analisa mas não sintetiza recipe automaticamente |
| Planner para dados de alta entropia | ❌ Não existe — Entropy Honesty redireciona corretamente para CAS bruto |
| Planner autônomo (sem LLM/humano na cadeia) | ❌ Não implementado — LLM era o Planner implícito histórico |
| Vocabulário de Macro-Opcodes para domínios reais | ❌ dict.ref e slice.copy são hipóteses sem encoder |
| Ciclo Planner→Recipe→Seed→Executor→SHA-256 end-to-end para arquivos externos | ❌ Falta a ponte Planner→Recipe para dados além de D1–D3 |

**Conclusão forense:** o sistema é um **cofre determinístico de altíssima fidelidade** com um **Planner parcial** que cobre dados sintéticos. A "magia" histórica era o LLM/humano preenchendo o gap do Planner para domínios conhecidos. O caminho para compressão semântica de dados arbitrários passa pela formalização e implementação do Planner como software autônomo — conforme documentado em `TEIA_NEUROSYMBOLIC_ARCHITECTURE_v0185.md`.

---

*Este documento é resultado de análise estática read-only. Nenhum arquivo foi executado, movido ou modificado durante sua produção.*
