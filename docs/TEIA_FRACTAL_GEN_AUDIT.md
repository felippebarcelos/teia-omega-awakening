# TEIA_FRACTAL_GEN — AUDITORIA ARQUEOLÓGICA v0.18.0
**Data:** 2026-05-27  
**Auditor:** Claude Sonnet 4.6 (Nó Ativo TEIA)  
**Modo:** Análise estática read-only — nenhum script executado  
**Escopo:** Pipeline gerador completo: v1.x (legacy Onto) → v2.0 (CAS atual) → Motor-Ontoprocedural → Planner-v0170  
**Protocolo:** Arqueologia e Auditoria v0.18.0

---

## 1. INVENTÁRIO DE SCRIPTS LOCALIZADOS

| Script | Caminho | Papel | Geração |
|--------|---------|-------|---------|
| `TEIA-Fractal-Gen-v2.ps1` | `D:\TEIA_CLAUDE_AWAKENING\tools\` | Motor CAS atual — ingesta + gen_dummy_seed | v2.0 (atual) |
| `TEIA-Fractal-Gen-v2.ps1` | `D:\TEIA_CORE\tools\` | Cópia idêntica (9,876 bytes) | v2.0 (atual) |
| `TEIA-OntoSeed-Gen.ps1` | `...Arqueologia\...\Ontology\` | Gerador de seed com Detect-Procedural | v1.x (legacy) |
| `TEIA-OntoEngine-Restore.ps1` | `...Arqueologia\...\Ontology\` | Executor de restauração por generator.name | v1.x (legacy) |
| `TEIA-Motor-Ontoprocedural.ps1` | `LEGADO_HISTORICO\` | Prova de Excalibur — SplitMix64 O(1) seek | v1.5 (legado) |
| `TEIA-SmokeTest-E2E-Procedural.ps1` | `LEGADO_HISTORICO\` | Prova de honestidade entropica E2E | v1.x (legado) |
| `TEIA-Procedural-Planner-v0170.ps1` | `tools\` | Planner estrutural — análise + seletor de estratégia | v0.17.0 (atual) |
| `TEIA-Logger.ps1` | `...Arqueologia\...\Ontology\` | Logger compartilhado via dot-source | v1.x (legacy) |
| `GenFunctions.ps1` | **NÃO ENCONTRADO** em todo `D:\` | — | ausente |

> **Nota:** cópias deduplicadas com sufixo `(1)`, `(2)`, `dedup` existem em `...Arqueologia\...\Ontology\` — são variantes com ajustes menores, não versões distintas do pipeline.

---

## 2. CADEIA DE DOT-SOURCE (DEPENDÊNCIAS)

```
TEIA-OntoSeed-Gen.ps1
  └─ . "$PSScriptRoot/TEIA-Logger.ps1" -LogPath ... -VerificationPath ...
       └─ expõe: Write-TEIALog, Get-TEIASha256, Get-TEIAUtcNow, Update-Verification

TEIA-OntoEngine-Restore.ps1
  └─ . "$PSScriptRoot/TEIA-Logger.ps1" -LogPath ... -VerificationPath ...
       └─ (mesmas funções)

TEIA-Fractal-Gen-v2.ps1
  └─ [sem dot-source] — funções internas: Write-FGEvent, Read-TeiaMap, Set-MapAtomic,
       Invoke-IngestToCAS, Write-SeedAtomic, gen_dummy_seed

TEIA-Motor-Ontoprocedural.ps1
  └─ [sem dot-source] — Add-Type inline: SM64 (C# unchecked UInt64)

TEIA-Procedural-Planner-v0170.ps1
  └─ [sem dot-source] — autocontido
```

---

## 3. CADEIA CAUSAL — LINHA DO TEMPO TÉCNICA

### 3.1 Fase Legacy (v1.x): Onto-Pipeline com Detect-Procedural

**Como a seed era gerada (TEIA-OntoSeed-Gen.ps1):**

```
[Arquivo de entrada]
    │
    ├─ Read-Bytes → $bytes (ReadAllBytes completo em RAM)
    ├─ Detect-Format → mime/tipo via magic signatures + ontologia JSON
    ├─ Get-TEIASha256 → hash canônico
    └─ Detect-Procedural → classificação estrutural:
          ┌─ uniqueBytes == 1          → repeat_byte { value, size }
          ├─ padrão periódico ≤64B     → repeat_sequence { hex, period, size }
          └─ nenhum padrão encontrado  → none { procedural=false }
                │
                └─ nota explícita: "No procedural generator identified;
                   restoration not possible without payload or external source."
```

A seed resultante contém `generator.name` + `generator.params` — a receita que o Executor entende.

**Como o Executor decide entre procedural e fallback (TEIA-OntoEngine-Restore.ps1):**

```powershell
switch ($gen.name) {
    'empty'           { ... }
    'repeat_byte'     { [Array]::Fill($bytes, $val) }
    'repeat_sequence' { for ($i=0; ...) { $bytes[$i] = $seq[$i % $period] } }
    default           { throw "No procedural generator available: $($gen.name)" }
}
```

**Diagnóstico:** não há fallback para CAS. Se `generator.name = 'none'`, o script lança exceção e a restauração falha. O design pressupõe que `Detect-Procedural` terá êxito — uma premissa que só se sustenta para dados sintéticos de baixa entropia.

### 3.2 Fase Motor (v1.5 legacy): SplitMix64 / Prova de Excalibur

**Como a seed é gerada (TEIA-Motor-Ontoprocedural.ps1):**

```
[Semente uint64 canônica: 0xFE1A7E1A00C0FFEE]
    │
    ├─ SHA-256 da semente → identificador SR-AUT
    └─ Para cada bloco k:
           estado_k = semente + k × 0x9E3779B97F4A7C15 (mod 2^64) — O(1) seek
           bloco_k  = SM64.GenBlock(estado_k, tamanhoBloco)          — C# unchecked
```

A "seed" aqui é a SR-AUT (Semente-Registro Autônoma Transcendente) — um objeto JSON de ≈300 bytes que representa uma matriz de N MB. O O(1) seek é real e provado: `state[n] = semente + n × INC (mod 2^64)`.

**Limitação arqueológica crítica:** este sistema gera dados deterministicos a partir de uma seed SplitMix64. Funciona **apenas quando o arquivo original foi gerado por esta mesma semente** — ou seja, o arquivo é uma saída do motor, não um arquivo externo arbitrário. Para arquivos do usuário (fotos, documentos), não existe método para "descobrir" a semente SplitMix64 que os teria gerado.

### 3.3 Fase Planner (v0.17.0 atual): Análise Estrutural + Seletor MDL

**Como o Planner analisa um arquivo (TEIA-Procedural-Planner-v0170.ps1):**

```
[Arquivo de entrada]
    │
    ├─ sha256hex          → identidade
    ├─ Get-Entropy        → entropia Shannon (bits/byte)
    ├─ Get-UniqueBytes    → cardinalidade do alfabeto
    ├─ Get-RunStats       → runs RLE, run máximo, avg run length
    ├─ Find-Period        → período mínimo de repetição (até 512B)
    ├─ Find-DupBlocks     → % de chunks 4KB duplicados
    ├─ Get-ChunkVariance  → variância de entropia entre quartos do arquivo
    ├─ Get-LineStats      → (texto) linhas repetidas
    └─ Get-JsonKeyFreq    → (JSON) frequência de chaves

    → Select-Strategy: MDL implícito — menor seed possível que reconstrói o dado
          ┌─ uniqueBytes==1            → gen.repeat
          ├─ period ≤512B detectado    → gen.pattern
          ├─ runs favoráveis           → rle.decode
          ├─ JSON com chaves repetidas → dict.ref (HIPÓTESE — encoder não existe)
          ├─ dupRatio >40%             → slice.copy (HIPÓTESE — encoder não existe)
          ├─ entropia <5.5             → cmp.lzma (lzma domina)
          ├─ entropia <7.0             → cmp.brotli ou cmp.lzma
          └─ entropia ≥7.0             → cas.raw (fallback correto)
```

**Critério de honestidade entropica no Planner:** cada estratégia informa explicitamente `beatsLzma` e `seedWorth`. Em todos os casos de dados reais, o Planner conclui `seedWorth="NÃO"` — lzma/brotli dominam. Apenas dados sintéticos classe D1–D3 (constante, periódico, RLE curto) recebem tratamento procedural.

---

## 4. AUDITORIA DE SEGURANÇA — COMANDOS POTENCIALMENTE DESTRUTIVOS

| Script | Linha | Comando | Contexto | Risco Real |
|--------|-------|---------|----------|------------|
| `TEIA-Fractal-Gen-v2.ps1` | 86 | `Remove-Item $dest` | Após hash pós-cópia divergir — remove cópia corrompida | **MÍNIMO** — só executa em falha de integridade; arquivo original intacto |
| `TEIA-Motor-Ontoprocedural.ps1` | 419 | `Remove-Item $ArquivoBaselineDisco` | **Comentado** — limpeza opcional pós-prova | **ZERO** — linha comentada (`#`) |
| `TEIA-SmokeTest-E2E-Procedural.ps1` | 25–26 | `Remove-Item $SeedPath -Force`, `Remove-Item $RestoredFile -Force` | Limpeza de artefatos de teste anteriores antes de re-executar | **BAIXO** — afeta apenas arquivos de teste temporários, não dados originais |
| `TEIA-OntoEngine-Restore.ps1` | — | nenhum `Remove-Item` | — | **ZERO** |
| `TEIA-OntoSeed-Gen.ps1` | — | nenhum `Remove-Item` | — | **ZERO** |
| `TEIA-Procedural-Planner-v0170.ps1` | — | nenhum `Remove-Item` | Read-only por design | **ZERO** |

**Conclusão de segurança:** nenhum script do pipeline principal apaga arquivos de origem. O único `Remove-Item` ativo (`Fractal-Gen-v2.ps1:86`) é um mecanismo de rollback de integridade, não de compressão destrutiva.

---

## 5. AUDITORIA DE VALIDAÇÃO SHA-256

| Script | Onde valida | Mecanismo | Falha como |
|--------|-------------|-----------|------------|
| `TEIA-Fractal-Gen-v2.ps1` | Pós-cópia para CAS | `Get-FileHash $dest` == `$Hash` | `throw` + `Remove-Item $dest` |
| `TEIA-OntoEngine-Restore.ps1` | Pós-restauração | `Get-TEIASha256 $bytes` == `$sha` (da seed) | `throw "Hash mismatch after restore"` |
| `TEIA-Motor-Ontoprocedural.ps1` | Por bloco (disco vs onto) | SHA-256 do bloco disco == SHA-256 do bloco onto | Exibe `[DIVERGE!]` em vermelho; `$todasHashesIguais = $false` |
| `TEIA-Motor-Ontoprocedural.ps1` | Matriz completa | SHA-256 streaming da baseline no disco | Armazenado em `sraut.json` |
| `TEIA-SmokeTest-E2E-Procedural.ps1` | Final do ciclo E2E | `$OriginalHash -eq $RestoredHash` | `[FALHA DE IDEMPOTENCIA]` |
| `TEIA-Procedural-Planner-v0170.ps1` | Por arquivo analisado | SHA-256 completo para identidade | N/A — análise estática |

**Conclusão:** todos os pontos de restauração do pipeline verificam SHA-256. A cadeia de prova é consistente desde a ingesta (v2) até a restauração (legacy Onto + Motor).

---

## 6. MAPA DE FUNÇÕES DE GERAÇÃO PROCEDURAL

### `gen_dummy_seed` (TEIA-Fractal-Gen-v2.ps1, função única disponível)

```
Entrada : FileInfo + SHA-256 hash
Saída   : seed.json com {
    teia_version: '2.0'
    fn: 'gen_dummy_seed'
    hash_sha256: <hash>
    entropy: { head_hex (32B), tail_hex (32B), size_bytes }
    cas_path: <caminho no CAS>
    note: 'Conteúdo preservado integralmente no CAS. Semente não substitui o original.'
}
```

**Diagnóstico:** `gen_dummy_seed` é uma semente de **identidade**, não de **regeneração**. Ela registra o contexto do arquivo, mas não contém receita para reconstrução. A restauração é sempre via CAS (arquivo completo armazenado). O `ValidateSet('gen_dummy_seed')` sinaliza que funções procedurais reais (que eliminassem o CAS) ainda não foram implementadas nesta versão.

### `Detect-Procedural` (TEIA-OntoSeed-Gen.ps1 legacy)

```
Entrada : byte[] do arquivo completo (ReadAllBytes)
Saída   : { name, params, procedural: bool }

Capacidade real:
  ✓ repeat_byte     : arquivo = único byte repetido
  ✓ repeat_sequence : padrão periódico de até 64 bytes
  ✗ todo o resto     : name='none', procedural=false
```

**Diagnóstico:** `Detect-Procedural` é o embrião do Planner. Detecta apenas os dois padrões mais simples — aqueles que ocorrem em dados sintéticos de laboratório. Para arquivos reais (fotos, documentos, logs), o campo `notes` da seed explicita: "restoration not possible without payload or external source."

### `SplitMix64 / SM64.GenBlock` (TEIA-Motor-Ontoprocedural.ps1 legacy)

```
Entrada : uint64 semente + offset_bytes
Saída   : byte[] de tamanho arbitrário, determinístico

Seek O(1): state[n] = semente + n × 0x9E3779B97F4A7C15 (mod 2^64)
           qualquer bloco a qualquer offset sem iterar
```

**Diagnóstico:** a propriedade O(1) seek é real e provada. A limitação não é a matemática — é a aplicabilidade: funciona apenas para dados gerados por esta função, não para arquivos arbitrários do mundo real.

---

## 7. DIAGNÓSTICO FINAL — O QUE ESTE CÓDIGO PROVA E O QUE NÃO PROVA

### O que é provado (evidência em código executável)

1. **CAS com SHA-256 funciona:** `TEIA-Fractal-Gen-v2.ps1` ingesta e verifica corretamente.
2. **Execução determinística para dados sintéticos:** `TEIA-OntoEngine-Restore.ps1` restaura `repeat_byte` e `repeat_sequence` com SHA-256 validado.
3. **O(1) seek em RNG:** `TEIA-Motor-Ontoprocedural.ps1` prova que `state[n]` é calculável diretamente — sem I/O de disco.
4. **Planner estrutural funciona:** `TEIA-Procedural-Planner-v0170.ps1` analisa entropia, período, runs e seleciona estratégia com honestidade entropica.

### O que NÃO é provado (limitações explícitas no código)

1. **Compressão de arquivos arbitrários:** `gen_dummy_seed` preserva o arquivo integralmente no CAS — não há redução de espaço para arquivos arbitrários.
2. **Detect-Procedural para dados reais:** detecta apenas `repeat_byte` e `repeat_sequence` — ambos padrões sintéticos. Arquivo real → `name='none'`, restauração impossível sem CAS.
3. **Planner implícito era o LLM:** as seeds compactas que demonstravam compressão dependiam de o operador (humano/LLM) já saber que o arquivo era proceduralmente gerado. O Planner como software autônomo não existe ainda.

---

*Este documento é análise arqueológica estática. Nenhum arquivo foi modificado, executado ou movido durante sua produção.*
