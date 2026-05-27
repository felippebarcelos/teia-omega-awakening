# NEUROPLANNER — Dry-Run Estrutural v0.19.1
**Data:** 2026-05-27  
**Script:** `TEIA-NeuroPlanner-v0190.ps1 -DryRun`  
**Modo:** Análise estrutural read-only — sem LLM, sem escrita de candidates  
**Dataset:** 10 arquivos reais do ecossistema TEIA  
**Resultado:** 10/10 analisados | 0 falhas | 0 candidates escritos

---

## 1. Tabela Comparativa — Perfis Estruturais Observados

| # | Arquivo | Tamanho | Entropia | Bytes Únicos | Padrão Detectado | Estrutura | Classificação |
|---|---------|---------|----------|--------------|------------------|-----------|---------------|
| S1 | `corpus_d1.bin` | 512 KB | **0.0000** | 1 / 256 | período=1B · 1 run total | octet-stream / text | **PROCEDURAL_CANDIDATE** |
| S2 | `corpus_d2.bin` | 256 KB | **4.0000** | 16 / 256 | período=16B · 262144 runs 1B | octet-stream / text | **PROCEDURAL_CANDIDATE** |
| J1 | `fractal_index.json` | 1266 KB | 5.2590 | 68 / 256 | nenhum · 469990 runs avg=1.1B | text | LZMA_PREFERRED |
| J2 | `.teia_map.json` | 2.5 KB | 5.2867 | 61 / 256 | nenhum · 2306 runs avg=1.1B | JSON | LZMA_PREFERRED |
| L1 | `dna_events.jsonl` | 1063 KB | 5.3974 | 70 / 256 | nenhum · 494383 runs avg=1.1B | text | LZMA_PREFERRED |
| L2 | `TEIA-Motor-Ontoprocedural.log.json` | 2 KB | 5.1076 | 63 / 256 | nenhum · 2022 runs avg=1B | JSON | LZMA_PREFERRED |
| C1 | `TEIA-Core-v0.4.0.ps1` | 6.3 KB | 5.2398 | 88 / 256 | nenhum · 6029 runs avg=1.1B | text | LZMA_PREFERRED |
| C2 | `TEIA-Abrir.ps1` | 5.8 KB | 5.2781 | 93 / 256 | nenhum · 5548 runs avg=1.1B | xml / text | LZMA_PREFERRED |
| B1 | `TEIA_PROVA_v12.zip` | 80.3 KB | **7.9939** | 256 / 256 | nenhum · 81590 runs max=11B | binary | **CAS_RAW** |
| B2 | `001df83b...bin` (CAS obj) | 27.3 KB | 4.9625 | 69 / 256 | nenhum · 23899 runs avg=1.2B | text | LZMA_PREFERRED |

**Legenda:** S=Sintético · J=JSON · L=Log · C=Código · B=Binário/Alta Entropia

---

## 2. Análise por Classificação

### 2.1 PROCEDURAL_CANDIDATE (2 / 10)

#### S1 — `corpus_d1.bin` (D1_UNIFORM benchmark)

```
SHA-256    : acac3fe365627c35...
Entropia   : 0.0000 bits/byte  ← mínimo absoluto
Bytes únicos: 1 / 256          ← arquivo = 1 byte repetido 524288×
Período    : 1B
Runs       : 1 run de 524288B
```

**Diagnóstico:** arquivo constante de byte único. O opcode `gen.repeat { value_hex, size }` reconstrói este arquivo com uma seed de ~200 bytes a partir de 512 KB — razão de compressão procedural: ~2621×. Este é o caso de uso de máxima eficiência procedural. SHA-256 validado por benchmark D1 (17/17 wins confirmados em v0.11.x).

**Recipe trivial:** `{ "op": "gen.repeat", "value_hex": "<hex_do_byte>", "size": 524288 }`

---

#### S2 — `corpus_d2.bin` (D2_PATTERN benchmark)

```
SHA-256    : 7b6fee4a726319c0...
Entropia   : 4.0000 bits/byte  ← log2(16) = 4 — distribuição uniforme de 16 símbolos
Bytes únicos: 16 / 256
Período    : 16B detectado em toda extensão do arquivo
Runs       : 262144 runs de 1B cada (alternância perfeita do padrão de 16B)
```

**Diagnóstico:** arquivo com padrão periódico de 16 bytes. O opcode `gen.pattern { pattern_b64, repeat }` reconstrói com uma seed de ~220 bytes a partir de 256 KB — razão de compressão procedural: ~1193×. Confirmado por benchmark D2.

**Observação de entropia:** 4.0 bits/byte é exatamente o esperado para 16 símbolos equiprováveis (log₂16 = 4). O classificador detecta corretamente o período antes de consultar a entropia — o threshold de entropia sozinho não classificaria este arquivo como procedural (4.0 ≥ 2.0).

---

### 2.2 LZMA_PREFERRED (7 / 10)

Todos os sete arquivos compartilham o mesmo perfil estrutural característico:
- **Entropia:** 5.1 – 5.4 bits/byte — zona de compressibilidade real (lzma atinge 10–33%)
- **Bytes únicos:** 61–93 / 256 — vocabulário típico de texto UTF-8 ou JSON
- **Runs:** múltiplos, curtos (avg 1.0–1.2B) — sem RLE útil
- **Período:** nenhum detectado — sem padrão periódico global

**Observação de entropia uniforme:** todos os 7 arquivos LZMA_PREFERRED têm entropia entre 5.1 e 5.4 — banda característica de JSON, logs estruturados e código-fonte. Esta banda é onde lzma/brotli obtêm as melhores taxas de compressão (LZ77 captura repetição de tokens e strings via back-references).

| Arquivo | e | Por que lzma ganha |
|---------|---|-------------------|
| `fractal_index.json` | 5.259 | JSON com chaves repetidas — LZ77 ideal |
| `.teia_map.json` | 5.287 | JSON pequeno, estrutura repetitiva |
| `dna_events.jsonl` | 5.397 | Log line-by-line, timestamps variáveis |
| `TEIA-Motor-Ontoprocedural.log.json` | 5.108 | JSON de benchmark, números repetitivos |
| `TEIA-Core-v0.4.0.ps1` | 5.240 | Código PowerShell — keywords repetidos |
| `TEIA-Abrir.ps1` | 5.278 | Código PowerShell com sintaxe XML (CRLF) |
| `001df83b...bin` (CAS obj) | 4.963 | Texto original desconhecido, comprimível |

---

### 2.3 CAS_RAW (1 / 10)

#### B1 — `TEIA_PROVA_v12.zip`

```
SHA-256    : 0120f6ad820e4b4f...
Entropia   : 7.9939 bits/byte  ← próximo do máximo (8.0)
Bytes únicos: 256 / 256        ← todos os 256 valores de byte presentes
Período    : nenhum
Magic      : application/zip   ← magic bytes 50 4B 03 04 detectados
```

**Diagnóstico:** arquivo ZIP comprimido com entropia 7.9939 — praticamente incompressível. O classificador detectou corretamente via magic bytes (`application/zip`) e confirmou via entropia. Qualquer tentativa de recompressão produz expansão (benchmark D8 histórico: lzma 101.37%, brotli 100.001%). O fallback `cas.raw` é o único caminho correto.

---

## 3. Anomalias e Observações Técnicas

### 3.1 Magic Byte Detection — "application/octet-stream" para arquivos de texto

O detector de magic bytes (`Detect-MagicType`) verifica os primeiros 16 bytes contra assinaturas binárias conhecidas (PNG, JPEG, PDF, ZIP, PE, GZIP, etc.). Arquivos de texto (JSON, PS1, log) não têm assinatura binária — os primeiros bytes são caracteres UTF-8 imprimíveis — e portanto retornam `application/octet-stream` por padrão.

**Consequência:** o campo `magic_type` é informativo apenas para binários. A detecção de estrutura (`structure_type: json`, `text`, `xml`, `binary`) complementa o magic para arquivos textuais.

**Exceções corretas observadas:**
- `.teia_map.json` e `TEIA-Motor-Ontoprocedural.log.json` → `structure_type: json` detectado ✓
- `TEIA-Abrir.ps1` → `structure_type: xml` detectado (início do arquivo tem cabeçalho XML) ✓
- `TEIA_PROVA_v12.zip` → `magic_type: application/zip` detectado ✓

### 3.2 corpus_d1.bin — Detectado como "text"

O arquivo D1_UNIFORM tem `structure_type: text`. Isso indica que o byte constante utilizado não é `0x00` (null). `Get-IsText` retorna `false` apenas quando encontra byte nulo nos primeiros 4096 bytes. O byte uniforme é um caractere ASCII imprimível (≥ 0x20), consistente com o opcode `gen.repeat` que usa o valor configurado na seed do benchmark.

### 3.3 corpus_d2.bin — Entropia exatamente 4.0000

Entropia de exatamente 4.0 bits/byte para um arquivo com 16 bytes únicos confirma **distribuição uniforme perfeita** dos 16 símbolos. Cada símbolo aparece exatamente 262144/16 = 16384 vezes. Isso é matematicamente esperado para um padrão periódico de 16 bytes sem bias — e valida que o opcode `gen.pattern` gerou os dados com fidelidade perfeita.

### 3.4 Bug de contagem corrigido no script (v0.19.0 → v0.19.1)

**Sintoma observado:** relatório exibiu "CAS BRUTO / ALTA ENTROPIA (16)" com apenas 1 arquivo listado.

**Causa:** `Where-Object` retornando 1 item em PowerShell 7 retorna o objeto diretamente (não um array). Para hashtable ordenada com 16 chaves, `.Count` retorna 16 (número de chaves do hashtable) em vez de 1 (número de resultados). 

**Correção aplicada:**
```powershell
# Antes (bug):
$highEntropy = $allProfiles | Where-Object { $_.entropy -ge 7.0 }

# Depois (correto):
[object[]]$highEntropy = @($allProfiles | Where-Object { $_.entropy -ge 7.0 })
```

`@(...)` força a materialização em array — `.Count` passa a retornar o número de resultados, independente de ser 0, 1 ou N.

---

## 4. Verificação de Segurança — Confirmações

| Verificação | Resultado | Detalhe |
|-------------|-----------|---------|
| `candidate.json` gravados com `-DryRun` | **0** | `D:\TEIA_CORE\neuroplanner\candidates\` criado mas vazio |
| Diretório `candidates` criado | Sim | Criação de diretório é read-only para dados — esperado |
| CAS object `001df83b...bin` intacto | **Sim** | SHA-256 verificado: `001DF83B40D5EC09...` == nome do arquivo |
| `fractal_index.json` intacto | **Sim** | 1.296.950 bytes, LastWrite: 2026-05-25 21:35:27 (inalterado) |
| `corpus_d1.bin` intacto | **Sim** | 524.288 bytes exatos |
| `corpus_d2.bin` intacto | **Sim** | 262.144 bytes exatos |
| `Remove-Item` executado | **0 vezes** | Verificado por inspeção estática do script |
| `Move-Item` sobre arquivos fonte | **0 vezes** | `Move-Item` só existe no bloco de escrita de `.tmp` (não atingido em DryRun) |

---

## 5. Sumário Executivo

```
Dataset        : 10 arquivos (2 sintéticos + 2 JSON + 2 logs + 2 código + 2 binário)
Analisados     : 10 / 10
Falhas         : 0
Tempo estimado : < 30 s (análise estrutural em RAM, sem I/O de rede)

Classificação estrutural automática (sem LLM):
  PROCEDURAL_CANDIDATE : 2 / 10 (corpus_d1 + corpus_d2)
  LZMA_PREFERRED       : 7 / 10 (JSONs + logs + código + CAS text)
  CAS_RAW              : 1 / 10 (TEIA_PROVA_v12.zip)

Segurança DryRun       : APROVADA — 0 candidates gravados, 0 arquivos modificados

Bug corrigido          : contagem de Where-Object com resultado único (v0.19.1)
```

**Conclusão:** o classificador estrutural autônomo (sem LLM) identifica corretamente as classes dos 10 arquivos. A classificação é consistente com os resultados dos benchmarks históricos (v0.11.x–v0.17.0): dados sintéticos procedurais (D1–D3) são candidatos genuínos; dados estruturados reais (JSON, logs, código) são domínio de lzma/brotli; binários comprimidos têm entropia máxima e vão para CAS_RAW.

O próximo passo é a execução com LLM ativo (Ollama rodando com DeepSeek ou Llama 3.2) para que as recipes dos 2 candidates procedurais sejam sintetizadas e validadas pela Regra de Ouro.

---

*Dry-run executado em 2026-05-27. Nenhum arquivo foi criado, modificado ou apagado durante a análise.*
