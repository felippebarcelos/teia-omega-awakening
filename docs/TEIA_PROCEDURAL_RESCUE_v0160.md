# TEIA-Core v0.16.0 — PROPOSTA TÉCNICA: MOTOR HÍBRIDO
**Data:** 2026-05-26
**Status:** PROPOSTA — não implementar antes de executar benchmark
**Baseado em:** auditoria v0.4.0 + CAS v0.14.1

---

## 1. PROBLEMA QUE MOTIVA O v0.16.0

O v0.4.0 provou que geração procedural funciona para dados sintéticos (`gen.repeat`
validado, SHA-256 verificado). Mas tem três limitações estruturais:

**L1 — Seletor single-opcode:** Seed-Pack escolhe *uma* estratégia por arquivo.
Arquivos reais são heterogêneos — um `.log` pode ter header constante + corpo
comprimível + trailer periódico. Um plano multi-opcode capturaria mais ganho.

**L2 — Base64 overhead em lz.decode:** Compressão brotli/gzip útil é parcialmente
cancelada pelo Base64 obrigatório do JSON (−33% recuperado de volta). Para dados
comprimíveis, o overhead da serialização come o ganho.

**L3 — Sem integração CAS:** O v0.4 é um sistema isolado. Seeds ficam em arquivos
soltos. O CAS v0.14.1 oferece integridade, rastreamento e restauração automática
— mas não sabe da existência de seeds procedurais.

**O v0.16.0 resolve L1 parcialmente, L2 completamente, e L3 completamente.**

---

## 2. ARQUITETURA DO SELETOR HÍBRIDO v0.16.0

```
                    ┌─────────────────────────────────────────┐
                    │         TEIA-Core-v0.16.0               │
                    │         Seletor Híbrido                 │
                    └─────────────────┬───────────────────────┘
                                      │
                    ┌─────────────────▼───────────────────────┐
                    │          Análise do arquivo              │
                    │   SHA-256 → tamanho → entropia parcial  │
                    └─────────────────┬───────────────────────┘
                                      │
         ┌────────────────────────────▼────────────────────────────────┐
         │                    Tentativas em ordem                       │
         │                                                              │
         │  1. procedural.plan  ──→  gen.repeat / gen.pattern / rle?  │
         │     (sem overhead, sem dependência externa)                  │
         │                                                              │
         │  2. cmp.zstd         ──→  comprimir + armazenar no CAS     │
         │     (ratio estimado < 0.95?)                                │
         │                                                              │
         │  3. cmp.lzma         ──→  comprimir + armazenar no CAS     │
         │     (ratio estimado < cmp.zstd?)                            │
         │                                                              │
         │  4. cas.raw          ──→  arquivo original no CAS          │
         │     (fallback sempre disponível)                             │
         └─────────────────────────────────────────────────────────────┘
                                      │
                    ┌─────────────────▼───────────────────────┐
                    │         Saída: seed.json v0.16          │
                    │   { v, out.sha256, mode, plan/ref }     │
                    └─────────────────┬───────────────────────┘
                                      │
                    ┌─────────────────▼───────────────────────┐
                    │    Verificação SHA-256 obrigatória       │
                    │    (restore → hash == out.sha256?)       │
                    └─────────────────────────────────────────┘
```

---

## 3. MODOS E SEED FORMAT

### Modo 1: procedural.plan

Usado quando `gen.repeat`, `gen.pattern` ou `rle.decode` cobrem o arquivo
com ratio superior a qualquer compressor.

```json
{
  "v": "0.16.0",
  "mode": "procedural.plan",
  "out": { "name": "arquivo.bin", "size": 1048576, "sha256": "..." },
  "plan": [
    { "op": "gen.repeat", "byte": 0, "count": 1048576 }
  ]
}
```

**Restore:** executar plan → verificar SHA-256. Sem acesso ao CAS.
**Overhead:** ~80–200 bytes de JSON. Sem objeto CAS criado.

---

### Modo 2: cmp.zstd

Usado quando zstd comprime o arquivo com ratio < threshold (padrão 0.90).
O dado comprimido é armazenado como objeto CAS separado.

```json
{
  "v": "0.16.0",
  "mode": "cmp.zstd",
  "out": { "name": "arquivo.log", "size": 4194304, "sha256": "abc123..." },
  "compressed": {
    "sha256": "def456...",
    "size": 512000,
    "ratio": 0.122,
    "algo": "zstd",
    "level": 3
  }
}
```

**Restore:** buscar `compressed.sha256` no CAS → descomprimir zstd → verificar SHA-256.
**CAS objects criados:** 1 (`{compressed.sha256}.bin`)
**Overhead da seed:** ~150 bytes de JSON.

---

### Modo 3: cmp.lzma

Idêntico ao cmp.zstd, com algoritmo lzma (maior compressão, menor velocidade).
Usado quando `cmp.lzma.ratio < cmp.zstd.ratio - 0.05` (vale a penalidade de velocidade).

```json
{
  "v": "0.16.0",
  "mode": "cmp.lzma",
  "out": { "name": "arquivo.txt", "size": 2097152, "sha256": "ghi789..." },
  "compressed": {
    "sha256": "jkl012...",
    "size": 280000,
    "ratio": 0.133,
    "algo": "lzma"
  }
}
```

---

### Modo 4: cas.raw

Fallback. O arquivo original é armazenado no CAS sem compressão.
Usado quando nenhum modo anterior atinge threshold mínimo de utilidade.

```json
{
  "v": "0.16.0",
  "mode": "cas.raw",
  "out": { "name": "arquivo.bin", "size": 8388608, "sha256": "mno345..." }
}
```

**Restore:** buscar `out.sha256` no CAS → copiar → verificar SHA-256.
**CAS objects criados:** 1 (o próprio arquivo original).
**Overhead da seed:** ~100 bytes de JSON.

**Nota:** `cas.raw` é equivalente ao comportamento atual do TEIA_USER (INGESTED).
A integração v0.16.0 não duplica — se o arquivo já está no CAS, reutiliza.

---

## 4. LÓGICA DO SELETOR AUTOMÁTICO

```powershell
function Select-HybridMode {
    param([byte[]]$Bytes, [float]$ThresholdRatio = 0.90)

    # Tenta procedural (sem CAS, sem compressão externa)
    if (Is-ConstByte $Bytes)          { return 'procedural.plan'; # gen.repeat }
    if (Find-RepeatingPattern $Bytes) { return 'procedural.plan'; # gen.pattern }
    if (Try-RLE $Bytes)               { return 'procedural.plan'; # rle.decode }

    # Tenta compressores (em paralelo se PowerShell 7+)
    $zstd = Compress-Zstd $Bytes -Level 3
    $lzma = Compress-Lzma $Bytes

    $ratioZstd = $zstd.Length / $Bytes.Length
    $ratioLzma = $lzma.Length / $Bytes.Length

    if ($ratioLzma -lt $ratioZstd -and ($ratioZstd - $ratioLzma) -gt 0.05) {
        if ($ratioLzma -lt $ThresholdRatio) { return 'cmp.lzma' }
    }
    if ($ratioZstd -lt $ThresholdRatio) { return 'cmp.zstd' }

    # Fallback
    return 'cas.raw'
}
```

**Threshold padrão 0.90:** só comprime se economizar ao menos 10%.
Abaixo disso, o overhead de decompressão não justifica o ganho.

---

## 5. INTEGRAÇÃO COM CAS v0.14.1

### Invariantes preservados

| Invariante CAS | Como v0.16.0 respeita |
|---------------|----------------------|
| SHA-256 como identidade | `out.sha256` na seed é o hash do arquivo original; `compressed.sha256` é hash do comprimido |
| Idempotência | Seed gerada é determinística; re-run detecta objeto CAS existente via `Test-Path` |
| Nenhum arquivo original apagado | Seed é artefato adicional; original permanece |
| Escrita atômica | Seeds escritas com `.tmp → verify → rename` |
| Status no mapa | Novo status proposto: `PROCEDURAL_ENCODED` |

### Novo campo no .teia_map.json

```json
{
  "path_user": "D:\\TEIA_USER\\Documents\\relatorio.pdf",
  "nome": "relatorio.pdf",
  "hash": "abc123...",
  "size": 4194304,
  "status": "PROCEDURAL_ENCODED",
  "ingested_at": "2026-05-26T...",
  "path_cas": "D:\\TEIA_CORE\\objects\\abc123....bin",
  "seed_path": "D:\\TEIA_CORE\\seeds\\abc123....seed.json",
  "seed_at": "2026-05-26T...",
  "encode_mode": "cmp.zstd",
  "encode_ratio": 0.122
}
```

### Ciclo de status completo v0.16.0

```
[novo arquivo]          →  INGESTED
[re-ingestão]           →  VERIFIED
[seed gen.dummy]        →  SAFE_TO_ARCHIVE
[encode híbrido]        →  PROCEDURAL_ENCODED
[arquivo ausente, CAS]  →  INGESTED  (restauração)
```

---

## 6. O QUE NÃO SERÁ IMPLEMENTADO NO v0.16.0

| Feature descartada | Razão |
|-------------------|-------|
| `xform.xor` | Não comprime; adiciona overhead; sem caso de uso claro |
| `literal` opcode | CAS.raw é equivalente e sem overhead de Base64 |
| `dict.ref` encoder | Complexidade alta, encoder não existe; adiar para v0.17 |
| `slice.copy` encoder | Requer análise de blocos duplicados; adiar para v0.17 |
| Multi-opcode planner | Complexidade alta; adiar após benchmark validar ganho |
| Compressão de CAS objects existentes | Fora do escopo; CAS é imutável por hash |

---

## 7. PRÉ-CONDIÇÕES PARA IMPLEMENTAR

Antes de escrever uma linha do v0.16.0:

1. **Executar `BENCHMARK_PLAN_v0160.md`** — confirmar que zstd/lzma são viáveis nas condições reais de hardware (i3-10100F, PowerShell); comparar contra M8 v0.11-lzma (Python) como referência histórica
2. **Verificar disponibilidade de zstd no PS** — `[System.IO.Compression.ZstdStream]` requer .NET 7+; pode precisar de wrapper externo (`zstd.exe` ou SharpCompress)
3. **Confirmar equivalência lzma PS vs Python** — medir se `cmp.lzma` em PS/7z atinge ratio igual ao `v0.11-lzma` (Python `lzma.compress` FORMAT_ALONE preset=9|EXTREME); se divergir > 0.02, incorporar chamada Python no seletor em vez de reimplementar
4. **Provar gen.pattern e rle.decode** — executar provas independentes (SHA-256) para esses dois opcodes antes de incluí-los no seletor v0.16
5. **Registrar SHA-256 do motor v0.11** — localizar arquivo Python do motor v0.11 e registrar seu hash antes de qualquer modificação; serve como âncora para comparação de ratio

---

## 8. REGRA DE OURO

> Nenhuma versão do v0.16.0 será declarada "melhor" sem uma tabela de benchmark
> com: ratio, tempo encode, tempo decode, SHA-256 restore confirmado, bytes de
> overhead, e domínio específico onde o modo vence ou perde.

Afirmação válida: "cmp.zstd atingiu ratio 0.12 em dna_events.jsonl em 340ms."
Afirmação inválida: "o motor híbrido supera a compressão convencional."
