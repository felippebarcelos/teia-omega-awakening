# BENCHMARK PLAN v0.16.0 — MOTOR HÍBRIDO
**Data:** 2026-05-26
**Status:** PLANO — não executar antes de verificar pré-condições técnicas
**Objetivo:** medir ratio, velocidade e integridade por modo × dataset; sem afirmações de inovação

---

## 1. MÉTRICAS OBRIGATÓRIAS (por combinação modo × dataset)

| Métrica | Unidade | Como medir |
|---------|---------|-----------|
| `ratio` | float (0–1+) | `output_size / input_size` |
| `encode_ms` | inteiro | `Stopwatch.ElapsedMilliseconds` |
| `decode_ms` | inteiro | `Stopwatch.ElapsedMilliseconds` |
| `sha256_match` | bool | `hash(decoded) == hash(original)` |
| `overhead_bytes` | inteiro | `seed_json_size` (para procedural) ou `seed_json_size` (para cmp) |
| `compressed_size` | inteiro | tamanho do objeto CAS comprimido (para cmp.zstd/lzma) |
| `mode_selected` | string | qual modo o seletor automático escolheu |

**Regra:** `sha256_match = false` invalida a linha inteira. Não reportar ratio de dado não verificado.

---

## 2. DATASETS

### D1 — Texto Repetitivo
- **Geração:** `"ABCDEFGHIJ" × 100.000` → 1.000.000 bytes
- **Criar com:** `[byte[]]([System.Text.Encoding]::UTF8.GetBytes("ABCDEFGHIJ") * 100000)`
- **Expectativa:** `gen.pattern` deve vencer com ratio ≈ 0.000010 (10 bytes / 1MB)
- **Caso de teste para:** gen.repeat, gen.pattern

### D2 — JSON Estruturado
- **Arquivo:** `D:\TEIA_CORE\manifests\fractal_index.json` (1266 KB atual)
- **Expectativa:** cmp.zstd ou cmp.lzma vencem; ratio esperado 0.05–0.15
- **Caso de teste para:** lz.decode herdado, cmp.zstd, cmp.lzma

### D3 — Log de Eventos
- **Arquivo:** `D:\TEIA_CORE\dna_events.jsonl` (tamanho variável)
- **Expectativa:** alta compressibilidade por repetição de estrutura JSON; cmp.zstd/lzma excelentes
- **Caso de teste para:** cmp.zstd, cmp.lzma, rle.decode (se estrutura sparse)

### D4 — Código Fonte
- **Arquivo:** `D:\TEIA_CORE\tools\TEIA-Sync-Watchdog.ps1`
- **Expectativa:** cmp.zstd bom; procedural não se aplica; ratio esperado 0.30–0.50
- **Caso de teste para:** cmp.zstd, cmp.lzma vs. brotli/gzip herdados

### D5 — Binário Pseudoaleatório
- **Geração:** `[byte[]]` preenchido com `[System.Security.Cryptography.RandomNumberGenerator]`; 1 MB
- **Expectativa:** cas.raw vence — nenhum modo comprime dado aleatório; ratio ≈ 1.0 ou >1.0
- **Caso de teste para:** confirmar que o seletor escolhe cas.raw corretamente

### D6 — Imagem Simples (PNG sintético)
- **Arquivo:** `D:\TEIA_USER\Inbox\piloto_imagem.png` (69 bytes — muito pequeno)
- **Alternativa:** gerar PNG sintético 256×256 monocromático (~200 bytes antes de compressão interna)
- **Expectativa:** PNG já é comprimido internamente; cas.raw ou lzma com ganho marginal
- **Caso de teste para:** comportamento com dado já comprimido

### D7 — Arquivo Real do TEIA_USER
- **Arquivo:** `D:\TEIA_USER\Inbox\piloto_nota.txt` (125 bytes)
- **Alternativa:** usar arquivo maior de D:\bruto\TEIA\ para resultados significativos
- **Expectativa:** texto pequeno; cmp.zstd provavelmente overhead > ganho; testar threshold
- **Caso de teste para:** comportamento com arquivo pequeno (overhead relativo dominante)

### D8 — Dados com Runs Longos (RLE)
- **Geração:** concatenar blocos de zeros e uns alternados em runs de 10KB cada; 1 MB total
- **Exemplo:** `[byte[]]([byte]0x00 × 10240) + ([byte]0xFF × 10240) × 50`
- **Expectativa:** rle.decode vence sobre cmp para esta estrutura específica
- **Caso de teste para:** rle.decode vs. cmp.zstd

---

## 3. MODOS A COMPARAR

| ID | Modo | Implementação | Disponibilidade | Versão origem |
|----|------|--------------|----------------|--------------|
| M1 | `gen.repeat` | TEIA-Core v0.4.0 | ✅ pronto | v0.4 |
| M2 | `gen.pattern` | TEIA-Core v0.4.0 | ✅ pronto | v0.4 |
| M3 | `rle.decode` | TEIA-Core v0.4.0 | ✅ pronto | v0.4 |
| M4 | `lz.brotli` (v0.4) | TEIA-Seed-Pack v0.4.0 | ✅ pronto | v0.4 |
| M5 | `lz.gzip` (v0.4) | TEIA-Seed-Pack v0.4.0 | ✅ pronto | v0.4 |
| M6 | `cmp.zstd` | A implementar em v0.16 | ⚠️ verificar disponibilidade PS | v0.16 proposto |
| M7 | `cmp.lzma` (PS/7z) | A implementar em v0.16 | ⚠️ verificar wrapper | v0.16 proposto |
| **M8** | **`v0.11-lzma`** | **Python lzma FORMAT_ALONE preset=9\|EXTREME** | **✅ pronto** | **v0.11 — campeão atual** |
| M9 | `cas.raw` | TEIA-Ingerir v0.14 | ✅ pronto (baseline) | v0.14 |

**Linha de base (baseline):** M9 `cas.raw` com ratio = 1.0, encode = tempo de cópia.
Qualquer modo que não vença o baseline em ratio não justifica sua complexidade.

**Referência histórica obrigatória:** M8 `v0.11-lzma` é o campeão documentado:
- 17/17 D8 wins, 105/105 D7 wins
- overhead ~69–79 bytes
- savings D7: +121.812 bytes; D8: +24.709 bytes
Qualquer modo v0.16 deve ser comparado diretamente contra M8, não apenas contra o baseline.

**Distinguir M7 vs M8:**
- M7 (`cmp.lzma` proposto): PowerShell puro ou wrapper 7z — velocidade e disponibilidade a verificar
- M8 (`v0.11-lzma`): Python `lzma.compress(data, format=FORMAT_ALONE, preset=9|EXTREME)` — implementação validada com 100% win rate
Se M7 não igualar M8 em ratio, M8 deve ser incorporado ao seletor v0.16 via chamada Python externa.

---

## 4. PRÉ-CONDIÇÕES TÉCNICAS

### P1 — Verificar zstd no PowerShell
```powershell
# Testar se ZstdStream está disponível (.NET 7+)
[System.IO.Compression.ZstdStream] -ne $null
```
Se não disponível, avaliar alternativas:
- `zstd.exe` externo via `Start-Process`
- SharpCompress NuGet package
- Adiar M6 e usar apenas M7 (lzma)

### P2 — Verificar lzma no PowerShell
```powershell
# SevenZipExtractor ou similar
# Alternativa: usar System.IO.Compression com deflate como proxy
```

### P3 — Provar gen.pattern e rle.decode antes do benchmark
Executar provas independentes (idênticas a PROVA_INTEGRIDADE_v0.4.md) para:
- `gen.pattern`: criar arquivo periódico sintético, gerar seed, restaurar, verificar SHA-256
- `rle.decode`: criar arquivo com runs longos, gerar seed, restaurar, verificar SHA-256

### P4 — Confirmar tamanho dos datasets
Datasets D2 e D3 dependem do estado atual dos arquivos reais.
Antes do benchmark, registrar tamanho atual de `fractal_index.json` e `dna_events.jsonl`.

---

## 5. TABELA DE RESULTADOS (template a preencher)

```
Dataset × Modo → ratio | encode_ms | decode_ms | sha256_match | overhead_bytes | mode_selected
```

| Dataset | Modo | ratio | encode_ms | decode_ms | sha256 ✓ | overhead_B | notas |
|---------|------|------:|----------:|----------:|:--------:|----------:|-------|
| D1 texto_rep | M1 gen.repeat | | | | | | |
| D1 texto_rep | M2 gen.pattern | | | | | | |
| D1 texto_rep | M4 lz.brotli | | | | | | |
| D1 texto_rep | M6 cmp.zstd | | | | | | |
| D1 texto_rep | M8 v0.11-lzma | | | | | | referência histórica |
| D1 texto_rep | M9 cas.raw | 1.000 | | | ✅ | 0 | baseline |
| D2 json | M4 lz.brotli | | | | | | |
| D2 json | M5 lz.gzip | | | | | | |
| D2 json | M6 cmp.zstd | | | | | | |
| D2 json | M7 cmp.lzma | | | | | | |
| D2 json | M8 v0.11-lzma | | | | | | referência histórica |
| D2 json | M9 cas.raw | 1.000 | | | ✅ | 0 | baseline |
| D3 log | M4 lz.brotli | | | | | | |
| D3 log | M6 cmp.zstd | | | | | | |
| D3 log | M7 cmp.lzma | | | | | | |
| D3 log | M8 v0.11-lzma | | | | | | referência histórica |
| D3 log | M9 cas.raw | 1.000 | | | ✅ | 0 | baseline |
| D4 codigo | M4 lz.brotli | | | | | | |
| D4 codigo | M6 cmp.zstd | | | | | | |
| D4 codigo | M8 v0.11-lzma | | | | | | referência histórica |
| D4 codigo | M9 cas.raw | 1.000 | | | ✅ | 0 | baseline |
| D5 aleatorio | M4 lz.brotli | | | | | | |
| D5 aleatorio | M6 cmp.zstd | | | | | | |
| D5 aleatorio | M8 v0.11-lzma | | | | | | espera-se ratio ≥ 1.0 |
| D5 aleatorio | M9 cas.raw | 1.000 | | | ✅ | 0 | baseline |
| D6 png | M4 lz.brotli | | | | | | |
| D6 png | M6 cmp.zstd | | | | | | |
| D6 png | M8 v0.11-lzma | | | | | | |
| D6 png | M9 cas.raw | 1.000 | | | ✅ | 0 | baseline |
| D7 txt_pequeno | M4 lz.brotli | | | | | | overhead provavelmente domina |
| D7 txt_pequeno | M6 cmp.zstd | | | | | | overhead provavelmente domina |
| D7 txt_pequeno | M8 v0.11-lzma | | | | | | overhead ~77B vs arquivo 125B |
| D7 txt_pequeno | M9 cas.raw | 1.000 | | | ✅ | 0 | baseline |
| D8 rle_runs | M3 rle.decode | | | | | | |
| D8 rle_runs | M6 cmp.zstd | | | | | | |
| D8 rle_runs | M8 v0.11-lzma | | | | | | histórico: 17/17 wins em logs |
| D8 rle_runs | M9 cas.raw | 1.000 | | | ✅ | 0 | baseline |

---

## 6. CRITÉRIOS DE DECISÃO PÓS-BENCHMARK

Baseados apenas nos dados da tabela. **Referência primária: M8 v0.11-lzma** (não apenas baseline M9).

| Pergunta | Critério para SIM |
|----------|------------------|
| Implementar cmp.zstd no v0.16? | ratio(D2,M6) < ratio(D2,M8) OU encode_ms(M6) < encode_ms(M8) × 0.5 E sha256 ok |
| Implementar cmp.lzma via PS/7z? | ratio(D2,M7) ≤ ratio(D2,M8) + 0.01 E sha256 ok (confirma equivalência com v0.11) |
| Chamar Python lzma (M8) no v0.16? | ratio(M7) > ratio(M8) + 0.02 em maioria dos datasets (M7 PS pior que M8 Python) |
| Incluir gen.pattern no seletor v0.16? | ratio(D1,M2) < 0.001 E sha256 prova independente OK |
| Incluir rle.decode no seletor v0.16? | ratio(D8,M3) < ratio(D8,M8) E sha256 prova independente OK |
| Descartar lz.brotli/gzip herdados? | ratio(Dx,M6_ou_M8) ≤ ratio(Dx,M4) em ≥ 6/8 datasets |
| cas.raw como único fallback? | ratio(D5,qualquer_modo) ≥ 0.98 para dado aleatório |
| v0.16 superior a v0.11? | soma_savings(D2..D8, M6_ou_M7) > soma_savings(D2..D8, M8) |

---

## 7. O QUE O BENCHMARK NÃO MEDE

- Desempenho em arquivos > 100 MB (hardware limitado: 8 GB RAM)
- Paralelismo (PowerShell single-thread por padrão)
- Compressão de streams (todos os modos são block-based)
- Deduplicação entre arquivos (CAS já faz isso)
- Latência de restauração em rede ou armazenamento remoto

---

## 8. FORMATO DO RELATÓRIO FINAL

Após executar o benchmark, gerar `BENCHMARK_RESULTS_v0160.md` com:

```markdown
## Vencedor por domínio

| Domínio | Modo vencedor | ratio | Justificativa |
|---------|--------------|-------|--------------|
| Dados constantes | gen.repeat | ~0.00001 | ... |
| JSON/logs (>1MB) | cmp.zstd | 0.0x–0.1x | ... |
| Binário aleatório | cas.raw | 1.000 | incompressível |
| ...

## Threshold recomendado para seletor automático

threshold_ratio = X.XX  (baseado em dados reais)

## Domínios onde nenhum modo supera cas.raw

[lista]
```

---

*Benchmark a executar após verificar pré-condições P1–P4.*
*Nenhuma afirmação de resultado antes de medir.*
