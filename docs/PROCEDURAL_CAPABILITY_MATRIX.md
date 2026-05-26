# PROCEDURAL CAPABILITY MATRIX — TEIA-Core v0.4.0
**Data:** 2026-05-26
**Fonte:** análise estática de `TEIA-Core-v0.4.0.ps1` + `TEIA-Seed-Pack-v0.4.ps1`
**Motor auditado:** SHA-256 `489D3B4024930FB4B0E12D0D40393CB86D0430178E6E272DCE328FDEC16475F6`

---

## MAPA DE OPCODES

### gen.repeat
| Campo | Valor |
|-------|-------|
| **Assinatura** | `{ op, byte: 0–255, count: int64 }` |
| **Mecanismo** | Gera buffer de `count` bytes todos iguais a `byte` |
| **Tipo de dado atendido** | Dados constantes: zeros, fills, padding |
| **Compressão esperada** | **∞:1** — 1 MB de `\xAA` → 18 bytes de JSON |
| **Overhead** | ~50 bytes de JSON por opcode |
| **Velocidade encode** | O(n) — scan único para detectar padrão constante |
| **Velocidade decode** | O(n) — loop simples |
| **SHA-256 restore** | ✅ Verificado — prova em `PROVA_INTEGRIDADE_v0.4.md` |
| **Risco** | Nenhum — saída completamente determinística |
| **Domínio onde vence** | Todos os algoritmos para dados constantes |
| **Domínio onde perde** | Qualquer dado não-constante |
| **Status** | ✅ **VALIDADO** |

---

### gen.pattern
| Campo | Valor |
|-------|-------|
| **Assinatura** | `{ op, pattern_b64: string, repeat: int64 }` |
| **Mecanismo** | Repete sequência de bytes `repeat` vezes |
| **Tipo de dado atendido** | Dados periódicos: tiles, gradientes simples, fills por padrão |
| **Compressão esperada** | Alta: `pattern_len × overhead_json / total_size` — ex: 4-byte pattern × 250k = 1MB → ~60 bytes |
| **Overhead** | ~80 bytes + Base64(pattern) |
| **Velocidade encode** | O(n²) no pior caso — `Find-RepeatingPattern` testa p=1..MaxPattern |
| **Velocidade decode** | O(n) |
| **SHA-256 restore** | ✅ Design determinístico — não testado com prova independente |
| **Risco** | Encode lento para dados grandes (O(n²)); falso positivo improvável mas possível |
| **Limitação** | `MaxPattern=512` — padrões maiores não são detectados |
| **Domínio onde vence** | Dados periódicos com período ≤ 512 bytes |
| **Domínio onde perde** | Dados com período > 512 bytes; dados quasi-periódicos com ruído |
| **Status** | ⚠️ **PRECISA_PATCH** — falta prova de integridade independente; limite de 512 pode ser insuficiente |

---

### rle.decode
| Campo | Valor |
|-------|-------|
| **Assinatura** | `{ op, pairs: [{b: int, n: int64}, ...] }` |
| **Mecanismo** | Run-Length Encoding: expande lista de (byte, contagem) |
| **Tipo de dado atendido** | Dados esparsos com sequências longas do mesmo byte |
| **Compressão esperada** | Alta para dados com poucos runs distintos; ruim para dados granulares |
| **Overhead** | ~30 bytes JSON por run (objeto `{b, n}`) |
| **Velocidade encode** | O(n) |
| **Velocidade decode** | O(n) |
| **SHA-256 restore** | ✅ Design determinístico — não testado com prova independente |
| **Heurística de ativação** | `n_runs < size / 8` (Seed-Pack) — conservadora |
| **Risco** | Para dados granulares, JSON dos pairs pode ser maior que brotli do dado original |
| **Domínio onde vence** | Bitmaps monocromáticos, dados binários esparsos, logs com muitos zeros |
| **Domínio onde perde** | Texto, código, JSON, dados com alta entropia local |
| **Status** | ⚠️ **PRECISA_PATCH** — falta prova; heurística conservadora pode não ativar em casos vantajosos |

---

### dict.ref
| Campo | Valor |
|-------|-------|
| **Assinatura** | `{ op, dict: [string], map: [int], encoding: "utf8" }` |
| **Mecanismo** | Dicionário de strings + mapa de índices; concatena tokens |
| **Tipo de dado atendido** | Dados com vocabulário fixo: logs estruturados, JSON com chaves repetidas, CSV |
| **Compressão esperada** | Alta se tokens longos e repetidos; moderada para vocabulário pequeno |
| **Overhead** | dict embutido na seed; map é array de inteiros |
| **Velocidade encode** | Não implementado em Seed-Pack — sem seleção automática |
| **Velocidade decode** | O(n) — simples |
| **SHA-256 restore** | ✅ Design determinístico — encoding UTF-8 explícito |
| **Risco** | **Encoder não implementado** — opcode existe no Core mas Seed-Pack não o seleciona; requer encoder externo |
| **Domínio onde vence** | Streams de tokens repetidos com vocabulário conhecido a priori |
| **Domínio onde perde** | Dados sem vocabulário fixo; binários |
| **Status** | ⚠️ **PRECISA_PATCH** — decoder presente, encoder ausente; sem teste de integridade |

---

### lz.decode (brotli / gzip)
| Campo | Valor |
|-------|-------|
| **Assinatura** | `{ op, algo: "brotli"\|"gzip", payload_b64: string }` |
| **Mecanismo** | Descomprime payload Base64 com brotli ou gzip |
| **Tipo de dado atendido** | Texto, código, JSON, HTML — qualquer dado com redundância linguística |
| **Compressão esperada** | brotli: ~25–70% do original para texto; gzip: ~30–75% |
| **Overhead crítico** | Base64 adiciona **+33%** sobre o dado já comprimido — penalidade real |
| **Velocidade encode** | Moderada (brotli Optimal é lento) |
| **Velocidade decode** | Rápida |
| **SHA-256 restore** | ✅ Design determinístico |
| **Risco principal** | **Double-encoding**: compressão útil cancelada parcialmente pelo Base64 obrigatório do JSON |
| **Domínio onde vence** | Texto com alta redundância onde ratio_brotli × 1.33 < 1.0 (ou seja, brotli reduz a > 75%) |
| **Domínio onde perde** | Binários, dados já comprimidos, imagens |
| **Status** | ⚠️ **PRECISA_PATCH** — Base64 overhead é desnecessário para integração com CAS; payload deveria ser CAS object separado |

---

### slice.copy
| Campo | Valor |
|-------|-------|
| **Assinatura** | `{ op, offset: int64, length: int64, repeat: int64 }` |
| **Mecanismo** | Copia fatia do buffer acumulado e repete; referência backward-only |
| **Tipo de dado atendido** | Dados com blocos repetidos em posições diferentes (LZ77-like) |
| **Compressão esperada** | Alta para dados com blocos duplicados; requer plano multi-opcode |
| **Overhead** | ~60 bytes por opcode |
| **Velocidade encode** | Não há encoder automático — sem seleção em Seed-Pack |
| **Velocidade decode** | O(n × repeat) |
| **SHA-256 restore** | ✅ Design determinístico — ordem de execução é crítica |
| **Risco** | Offset/length fora do buffer → exceção no Core; dependência de ordem de opcodes (plano sequencial) |
| **Domínio onde vence** | Planos compostos onde regiões se repetem após geração inicial |
| **Domínio onde perde** | Uso isolado sem plano composto |
| **Status** | ⚠️ **PRECISA_PATCH** — potencial alto; encoder totalmente ausente; testar com dados sintéticos |

---

### xform.xor
| Campo | Valor |
|-------|-------|
| **Assinatura** | `{ op, data_b64: string, key_b64: string \| key: int }` |
| **Mecanismo** | XOR byte-a-byte de data com key (chave cíclica) |
| **Tipo de dado atendido** | N/A — não é compressão |
| **Compressão esperada** | **Negativa: +33%** (Base64 overhead; tamanho da data não muda) |
| **Velocidade encode** | O(n) |
| **Velocidade decode** | O(n) |
| **SHA-256 restore** | ✅ Design determinístico |
| **Risco** | Confusão de propósito: não comprime, apenas transforma; seed contém data completo em Base64 |
| **Utilidade real** | Nenhuma para compressão; pode ser útil como camada de obfuscação leve em plano composto |
| **Status** | ❌ **DESCARTAR** para propósito de compressão — não reduz tamanho; aumenta overhead |

---

### literal
| Campo | Valor |
|-------|-------|
| **Assinatura** | `{ op, payload_b64: string }` |
| **Mecanismo** | Fallback: dado bruto codificado em Base64 |
| **Tipo de dado atendido** | Qualquer — é o fallback final |
| **Compressão esperada** | **-33%** — Base64 sempre expande |
| **Overhead** | +33% de tamanho mais overhead JSON |
| **SHA-256 restore** | ✅ Trivialmente determinístico |
| **Risco** | Nenhum — mas sempre pior que CAS direto |
| **Comparação com CAS** | CAS armazena o `.bin` diretamente; `literal` armazena Base64 na seed; CAS é estritamente melhor |
| **Status** | ❌ **DESCARTAR** em integração CAS — substituir por `cas.raw` (apontar hash; recuperar do CAS) |

---

## RESUMO EXECUTIVO

| Opcode | Status | Encoder | Decoder | Prova SHA-256 | Domínio principal |
|--------|--------|:-------:|:-------:|:-------------:|-------------------|
| `gen.repeat`  | ✅ VALIDADO       | ✅ | ✅ | ✅ validada | Dados constantes |
| `gen.pattern` | ⚠️ PRECISA_PATCH  | ✅ | ✅ | ❌ ausente  | Dados periódicos ≤512 |
| `rle.decode`  | ⚠️ PRECISA_PATCH  | ✅ | ✅ | ❌ ausente  | Dados com runs longos |
| `dict.ref`    | ⚠️ PRECISA_PATCH  | ❌ | ✅ | ❌ ausente  | Streams tokenizados |
| `lz.decode`   | ⚠️ PRECISA_PATCH  | ✅ | ✅ | ❌ ausente  | Texto / código |
| `slice.copy`  | ⚠️ PRECISA_PATCH  | ❌ | ✅ | ❌ ausente  | Blocos duplicados |
| `xform.xor`   | ❌ DESCARTAR      | ✅ | ✅ | ✅ | Nenhum (não comprime) |
| `literal`     | ❌ DESCARTAR (CAS) | ✅ | ✅ | ✅ | Substituído por cas.raw |

**Seletor automático do Seed-Pack:** `repeat → pattern → rle → brotli → gzip → literal`
Nota: `dict.ref` e `slice.copy` não estão no seletor automático — requerem encoder manual.

---

## PROBLEMA ESTRUTURAL DO lz.decode

O opcode `lz.decode` embute dados comprimidos como Base64 dentro do JSON da seed.
Isso cria um duplo overhead:

```
Dado original: 1.000.000 bytes
Após brotli:     250.000 bytes  (ratio 0.25 — excelente)
Após Base64:     333.333 bytes  (ratio 0.333 — +33% sobre comprimido)
Seed JSON total: ~333.400 bytes (ratio 0.333 contra original)

vs. CAS direto com compressão externa:
Arquivo .zstd:   230.000 bytes  (ratio 0.23)
Seed JSON:            80 bytes  (apenas hash do .zstd no CAS)
Total efetivo:   230.080 bytes  (ratio 0.23)
```

**Conclusão:** para `lz.decode`, a integração correta com CAS seria armazenar o dado
comprimido como objeto CAS separado e referenciar apenas o hash na seed.
Isso é exatamente o que o design v0.16.0 deve fazer com `cmp.zstd` e `cmp.lzma`.
