# TEIA P6.0 — Active Gestor: Ingestão Ativa e Restauro On-Demand
**Versão:** v0.30.0
**Protocolo:** P6.0 — Gestor de Armazenamento Ativo (Fase Ativa)
**Data:** 2026-05-29
**Scripts:** `TEIA-Ingestor-Active-v0300.ps1` | `TEIA-Stream-OnDemand-v0300.ps1`

---

## O Que Este Protocolo Faz

A TEIA deixou de ser um **classificador passivo** e tornou-se um **Gestor de Armazenamento Ativo**:

| Fase Anterior (P5.x) | Fase Atual (P6.0) |
|----------------------|-------------------|
| Observa e classifica | Ingere, comprime e gerencia |
| Arquivo original intacto | Arquivo substituído por stub |
| CAS Delta = 0 | CAS recebe artefatos comprimidos |
| Restore: não implementado | Restore: streaming on-demand |

**Invariante de identidade**: Todo arquivo restaurado tem SHA-256 idêntico ao original.

---

## Arquitetura P6.0

```
D:\TEIA_USER\ActiveDrive_Test\          D:\TEIA_CORE\objects\
  ┌─────────────────────────────┐           ┌──────────────────────────────────┐
  │  video.mp4.teia_stub  (~600B) │ ────────► │  a3a2...54.gz   (53.9 KB / 64%)  │
  │  doc.pdf.teia_stub    (~600B) │           │  16eb...20.br   (193  B  / 56%)  │
  │  mesh.obj.teia_stub   (~993B) │           │  seed JSON      (141  B  / 44%)  │
  └─────────────────────────────┘           └──────────────────────────────────┘
           ▲                                          │
           │                                          │
   TEIA-Ingestor-Active-v0300                TEIA-Stream-OnDemand-v0300
   (delete original + write stub)            (decompress/reconstruct ← CAS)
```

### Stub JSON (formato canônico)

```json
{
  "teia_version": "v0.30.0",
  "schema": "teia_stub",
  "original_name": "alice_wonderland.txt",
  "original_size_bytes": 151191,
  "original_sha256": "a3a27f8e...",
  "final_strategy": "cmp.lzma",
  "cas_encoding": "gz",
  "cas_path": "D:\\TEIA_CORE\\objects\\a3\\a2\\a3a27f8e...gz",
  "cas_sha256": "...",
  "cas_size_bytes": 53878,
  "savings_pct": 64.4,
  "ingest_timestamp": "2026-05-29T..."
}
```

Para `gen.parametric_mesh`, o stub inclui também `parametric_seed` com o algoritmo (`cube_v1_ccw` etc.) e topology_params para futura regeneração procedural.

---

## Estratégias de Codificação CAS

| Estratégia NeuroPlanner | Encoding CAS | Extensão | Restore |
|:-----------------------:|:------------:|:--------:|:-------:|
| `gen.repeat` | Seed JSON (35B) | `.teia_seed` | Geração procedural em chunks |
| `gen.pattern` | Seed JSON (<512B) | `.teia_seed` | Geração por padrão em chunks |
| `gen.parametric_mesh` | Brotli-compressed OBJ | `.br` | BrotliStream decompress |
| `cmp.lzma` | GZip-compressed | `.gz` | GZipStream decompress |
| `cmp.brotli` | Brotli-compressed | `.br` | BrotliStream decompress |
| `cas.raw` | Raw copy | `.raw` | Stream copy |

**Nota sobre `cmp.lzma`:** O .NET BCL não possui LZMA nativo. GZip (`System.IO.Compression.GZipStream`) com nível `Optimal` oferece compressão comparável para arquivos de texto e garante SHA-256 identity no restore.

---

## Ambiente de Teste — `D:\TEIA_USER\ActiveDrive_Test\`

### Arquivos Copiados

| Arquivo | Tamanho | Estratégia | Regra |
|---------|:-------:|:----------:|:-----:|
| `alice_wonderland.txt` | 147.6 KB | `cmp.lzma` | LLM → fallback |
| `jsonplaceholder_todos.json` | 23.7 KB | `cmp.lzma` | LLM → fallback |
| `prim_cube.obj` | 440 B | `gen.parametric_mesh` | HR6 |
| `prim_octahedron.obj` | 362 B | `gen.parametric_mesh` | HR6 |
| `prim_plane.obj` | 251 B | `gen.parametric_mesh` | HR6 |
| **TOTAL** | **172.4 KB** | | |

---

## Resultado da Ingestão Ativa

### Economia por Arquivo

| Estratégia | Arquivo | Orig (B) | CAS (B) | Economia |
|:----------:|---------|:--------:|:-------:|:--------:|
| `cmp.lzma` | alice_wonderland.txt | 151,191 | 53,878 | **-64.4%** |
| `cmp.lzma` | jsonplaceholder_todos.json | 24,311 | 3,975 | **-83.6%** |
| `gen.parametric_mesh` | prim_cube.obj | 440 | 193 | **-56.1%** |
| `gen.parametric_mesh` | prim_octahedron.obj | 362 | 180 | **-50.3%** |
| `gen.parametric_mesh` | prim_plane.obj | 251 | 141 | **-43.8%** |
| **TOTAL** | | **176,555** | **58,367** | **-67.0%** |

### Economia no ActiveDrive

```
Antes  (5 arquivos originais) : 176,555 bytes  (172.4 KB)
Depois (5 stubs .teia_stub)   :   4,150 bytes  (4.1 KB)
Redução ActiveDrive           :      97.6%

CAS novo (5 artefatos)        :  58,367 bytes  (57.0 KB)
Net total (stubs + CAS)       :  62,517 bytes  (61.1 KB)
Net savings                   :      64.6%
```

**O diretório de trabalho (ActiveDrive) ficou 97.6% menor.** Os artefatos comprimidos residem centralmente no CAS, acessados apenas quando necessário.

---

## Prova de Restauro On-Demand (SHA-256 Verificado)

### Teste 1 — `prim_cube.obj` (gen.parametric_mesh → Brotli-decompress)

```
Estratégia     : gen.parametric_mesh
CAS artefato   : 16eb...20.br  (193 B)
Seed embutido  : cube | cube_v1_ccw

Verificando SHA-256...
  Esperado : 16ebab87850a57bb753cae8cd5d5fc370225c179c9c60f89fe9b750baf594420
  Obtido   : 16ebab87850a57bb753cae8cd5d5fc370225c179c9c60f89fe9b750baf594420
  RESULTADO: SHA-256 OK — arquivo idêntico ao original

Tempo de restauro : 49 ms
```

### Teste 2 — `alice_wonderland.txt` (cmp.lzma → GZip-decompress)

```
Estratégia     : cmp.lzma (encoding: gz)
CAS artefato   : a3a2...54.gz  (52.6 KB)

Verificando SHA-256...
  Esperado : a3a27f8edbf7fcd9b8ba8435494440e24952deaa3e2f2d65192d4cb7ca403754
  Obtido   : a3a27f8edbf7fcd9b8ba8435494440e24952deaa3e2f2d65192d4cb7ca403754
  RESULTADO: SHA-256 OK — arquivo idêntico ao original

Tempo de restauro : 47 ms
Throughput stream : 3.1 MB/s
```

**Ambos os restores: SHA-256 PASS. Integridade total garantida.**

---

## OOM Guard — Análise de RAM

O design de streaming garante que nenhum arquivo é carregado integralmente na RAM:

| Operação | Implementação | RAM máxima |
|----------|:-------------:|:----------:|
| Compressão GZip | `$inStream.CopyTo($gz, 65536)` | ≤ 64 KB |
| Compressão Brotli | `$inStream.CopyTo($br, 65536)` | ≤ 64 KB |
| Cópia raw | `$inStream.CopyTo($out, 65536)` | ≤ 64 KB |
| Restore GZip | `$gzStream.CopyTo($out, 65536)` | ≤ 64 KB |
| Restore Brotli | `$brStream.CopyTo($out, 65536)` | ≤ 64 KB |
| gen.repeat (restore) | Loop chunks fixos de 65536B | ≤ 64 KB |
| gen.pattern (restore) | Loop chunks fixos de 65536B | ≤ 64 KB |

Sem `ReadAllBytes()`. Sem `Get-Content -Raw` para artefatos binários. O buffer de 64 KB é fixo e independente do tamanho do arquivo — um arquivo de 10 GB usa a mesma RAM que um de 100 B.

---

## Contenção P6.0

```
┌─────────────────────────────────────────────────────────────┐
│  REGRA DE CONTENÇÃO ATIVA P6.0                              │
│                                                             │
│  O Ingestor Ativo DELETA arquivos originais.               │
│  Portanto, TargetDir DEVE conter 'ActiveDrive_Test'.        │
│                                                             │
│  Guard implementado no início do script:                    │
│    if (-not $OverrideContainment -and                       │
│        $TargetDir -notmatch 'ActiveDrive_Test') { exit 1 } │
│                                                             │
│  Para expandir para produção: -OverrideContainment          │
│  (uso apenas após validação completa em staging)            │
└─────────────────────────────────────────────────────────────┘
```

---

## Idempotência

O Ingestor detecta stubs existentes antes de deletar o original:

```
Ingest-File:
  1. Calcula SHA-256 do original
  2. Verifica se .teia_stub JÁ EXISTE → SKIP silencioso
  3. Apenas se não existe stub: comprime → escreve stub → deleta original

Re-execução: 100% safe — zero bytes modificados se stubs já existem.
```

---

## Estrutura CAS Gerada (P6.0)

```
D:\TEIA_CORE\objects\
  a3\a2\a3a27f8e...gz   ← alice_wonderland.txt (GZip, 53.9 KB)
  [hash]\[hash].gz       ← jsonplaceholder_todos.json (GZip, 3.9 KB)
  16\eb\16ebab87...br   ← prim_cube.obj (Brotli, 193 B)
  [hash]\[hash].br       ← prim_octahedron.obj (Brotli, 180 B)
  [hash]\[hash].br       ← prim_plane.obj (Brotli, 141 B)
```

Cada arquivo é endereçado pelo SHA-256 do ORIGINAL — garantia de deduplicação por identidade de conteúdo.

---

## Dependências

```
TEIA-Ingestor-Active-v0300.ps1
  └─ D:\TEIA_CORE\neuroplanner\candidates\*.candidate.json
       (reusa análise existente do NeuroPlanner — zero chamadas LLM)
  └─ TEIA-NeuroPlanner-v0218.ps1
       (fallback para arquivos sem candidate existente)

TEIA-Stream-OnDemand-v0300.ps1
  └─ .teia_stub (JSON com cas_path + original_sha256)
  └─ D:\TEIA_CORE\objects\{...}  (artefato CAS)
```

---

## Próximos Passos (P6.1+)

| Item | Descrição |
|------|-----------|
| **gen.repeat restore** | Geração procedural verificada (implementada, não testada em P6.0 — requer arquivo de byte único na pasta de teste) |
| **gen.pattern restore** | Idem para padrão periódico |
| **cas.raw restore** | Stream copy implementada, não testada (requer imagem/PDF no teste) |
| **Primitiva OBJ regenerativa** | Quando `original_sha256 == canonical_sha256`, trocar `.br` por `.teia_seed` puro (zero artefato comprimido) |
| **Bulk restore** | `TEIA-Stream-OnDemand` em modo diretório (restaurar todos os stubs de uma pasta) |
| **FUSE / WinFsp shim** | Interceptar `Open()` no SO para restauro transparente ao usuário |

---

*Protocolo P6.0 executado em 2026-05-29. CAS Delta nesta sessão: +58.4 KB em 5 artefatos. ActiveDrive redução: 97.6%.*
