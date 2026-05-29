# TEIA P8.0 — Virtual Drive: Especificação de Integração OS
**Versão:** v0.50.0
**Protocolo:** P8.0 — TEIA Virtual File System (VFS)
**Data:** 2026-05-29
**Scripts:** `TEIA-VFS-Daemon-v0500.ps1`

---

## Problema

Após a ingestão ativa (P6.0+), o ActiveDrive contém apenas `.teia_stub` files de ~600B. O Windows Explorer e as aplicações (players de mídia, editores de texto, IDEs) enxergam esses stubs — não os arquivos originais. O objetivo do P8.0 é tornar a TEIA **invisível ao sistema operacional**: as aplicações pedem arquivos, e a TEIA serve os bytes reconstruídos em tempo real, sem restaurar o arquivo inteiro para disco.

---

## Requisito Central: Chunk-on-Demand

```
Aplicação Windows                TEIA VFS Daemon              CAS (objects/)
─────────────────                ────────────────             ──────────────
ReadFile(alice.txt,              Range(offset=0,       ┌─── a3a2...gz
  offset=0, length=64KB)  ──►   length=64KB)      ──► │    GZipStream
                           ◄──  64KB de bytes     ◄─── │    (decomprime
                                (sem disco extra)       │     só o necessário)
                                                   └─── │    Retorna buffer
```

**Invariante de RAM**: o pico de uso de memória nunca excede a janela de bytes solicitada, mais o overhead de decompressão (máximo um bloco de 64 KB por estágio).

**Exceção controlada**: Para estratégias comprimidas (`cmp.lzma`, `cmp.brotli`, `gen.parametric_mesh`), a implementação P8.0 usa um cache de descompressão full na primeira requisição. Estratégias procedurais (`gen.repeat`, `gen.pattern`) e `cas.raw` têm O(length) RAM garantido sem cache.

---

## Abordagens de Implementação

### Abordagem 1 — HTTP Daemon Local (P8.0 — Este Protocolo)

**Descrição:** Servidor HTTP puro em PowerShell via `System.Net.HttpListener`. Expõe uma API REST que responde metadados virtuais e serve ranges de bytes via CAS.

```
http://localhost:8765/
  GET /status            → JSON: daemon health + manifest count
  GET /api/list          → JSON: todos os arquivos virtuais com tamanhos originais
  GET /api/meta/{nome}   → JSON: metadados de um arquivo
  GET /api/read/{nome}   → Stream: conteúdo completo ou parcial (via Range: ou ?offset=&length=)
  HEAD /api/read/{nome}  → Headers: Content-Length = original_size_bytes
```

**Prós:** Zero dependências externas, implementação imediata, valida a lógica de streaming.

**Contras:** Não é um drive `T:\` real. Requer que a aplicação use HTTP. Não integra com Explorer nativamente.

**Quando usar:** Validação da lógica de chunk-on-demand. Testes de integração com ferramentas que suportam HTTP.

---

### Abordagem 2 — WebDAV + Mapeamento de Rede (P8.1)

**Descrição:** Estende o HTTP Daemon com o protocolo WebDAV completo. O Windows mapeia como drive `T:\` via WebClient service.

**WebDAV Methods necessários:**

| Method | Uso | Resposta TEIA |
|--------|-----|:-------------:|
| `OPTIONS` | Anunciar suporte DAV | `DAV: 1,2` header |
| `PROPFIND` | Listar propriedades | XML com `getcontentlength` = `original_size_bytes` |
| `GET` (+ Range) | Ler conteúdo | 200 ou 206 com bytes do CAS |
| `HEAD` | Tamanho do arquivo | `Content-Length` = `original_size_bytes` |
| `LOCK` | Write-lock (read-only ok) | 405 Method Not Allowed |

**PROPFIND Response (esquema):**
```xml
<?xml version="1.0" encoding="utf-8"?>
<D:multistatus xmlns:D="DAV:">
  <D:response>
    <D:href>/alice_wonderland.txt</D:href>
    <D:propstat>
      <D:prop>
        <D:displayname>alice_wonderland.txt</D:displayname>
        <D:getcontentlength>151191</D:getcontentlength>
        <D:getcontenttype>text/plain</D:getcontenttype>
        <D:resourcetype/>
        <D:getlastmodified>Thu, 29 May 2026 00:00:00 GMT</D:getlastmodified>
        <D:getetag>"a3a27f8e..."</D:getetag>
      </D:prop>
      <D:status>HTTP/1.1 200 OK</D:status>
    </D:propstat>
  </D:response>
</D:multistatus>
```

**Montagem no Windows:**
```powershell
# Pré-requisito: WebClient service ativo
Start-Service -Name WebClient

# Montar drive T:
net use T: \\localhost@8765\DavWWWRoot\ /persistent:no

# Ou via PowerShell
New-PSDrive -Name T -PSProvider FileSystem -Root "\\localhost@8765\DavWWWRoot"
```

**Limitações WebDAV:**
- Windows WebClient exige HTTPS para hosts não-localhost em produção
- Cache agressivo do WebClient pode ignorar mudanças no manifest
- Overhead de protocolo XML para cada `PROPFIND`

---

### Abordagem 3 — Windows Projected File System / ProjFS (P8.2)

**Descrição:** API nativa do Windows 10/11 que cria arquivos "fantasma" (placeholders) visíveis no Explorer sem necessidade de kernel drivers externos.

**Habilitação:**
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Client-ProjFS -NoRestart
```

**Arquitetura ProjFS:**
```
ProjFS Kernel Filter ←── OnGetFileData() callback
        │                  └─ invoca chunk-on-demand do CAS
        │                     quando app tenta Read no arquivo
        ▼
T:\alice_wonderland.txt  (placeholder — 0 bytes no disco)
        │
        ├── Explorer: exibe tamanho = original_size_bytes ✓
        ├── App Read: desencadeia OnGetFileData(offset, length) ✓
        └── SHA-256: igual ao original após reconstituição ✓
```

**Implementação (.NET):**
```csharp
// Biblioteca: Microsoft.Windows.ProjFS (NuGet)
var provider = new SimpleProjectedFileSystem(rootPath);
provider.StartVirtualizing();

// Callback de leitura
protected override NtStatus OnGetFileData(
    string relativePath, long offset, long length,
    PrjWriteFileData writeCallback) {
    
    var vEntry = manifest[relativePath];
    var chunk = ReadFromCAS(vEntry, offset, length);  // chunk-on-demand
    writeCallback(chunk, offset);
    return NtStatus.Success;
}
```

**Prós:** Integração nativa com Explorer, sem kernel driver, performance excelente, suporte a sparse/lazy materialization.

**Contras:** Requer habilitação de feature, binding .NET/C# (não PowerShell puro).

---

### Abordagem 4 — WinFsp User-Mode Filesystem (P8.3)

**Descrição:** FUSE-equivalente para Windows. Suporte completo a operações POSIX (open, read, write, seek, stat).

**Instalação:** `winget install WinFsp.WinFsp`

**Implementação via Python:**
```python
# pip install winfspy
from winfspy import FileSystem, FileSystemOperations

class TEIAFileSystem(FileSystemOperations):
    def read(self, file_context, offset, length):
        ventry = manifest[file_context.name]
        return read_from_cas(ventry, offset, length)  # chunk-on-demand
    
    def get_file_info(self, file_context):
        ventry = manifest[file_context.name]
        return FileInfo(file_size=ventry.original_size_bytes, ...)

fs = FileSystem("T:", TEIAFileSystem())
fs.start()
```

**Prós:** Full POSIX semantics, qualquer app funciona (incluindo game engines), suporte a write-through para re-ingestão.

**Contras:** Requer WinFsp instalado, dependência Python `winfspy`.

---

## Roadmap de Integração OS

```
P8.0 (atual)   HTTP Daemon → valida chunk-on-demand, sem drive real
P8.1           WebDAV → T:\ via net use (Explorer integrado)
P8.2           ProjFS → T:\ nativo, sem WinFsp, placeholders no Explorer
P8.3           WinFsp → T:\ completo, suporte a write-through
```

---

## Especificação: Chunk-on-Demand por Estratégia

| Estratégia | Seek? | RAM por chunk | Implementação |
|:----------:|:-----:|:-------------:|:-------------:|
| `cas.raw` | O(1) | ≤ `length` | `FileStream.Seek(offset)` |
| `gen.repeat` | N/A | ≤ `length` | Gerar bytes do valor fixo |
| `gen.pattern` | O(1) | ≤ `length` + `period` | `pattern[(offset+i) % period]` |
| `cmp.lzma` | N/A | full decompress | Cache temp + seek |
| `cmp.brotli` | N/A | full decompress | Cache temp + seek |
| `gen.parametric_mesh` | N/A | full decompress | Cache temp + seek |

**Evolução para comprimidos (P8.x):** Introduzir formato GZip chunkeado (blocos de 1 MB com índice de offsets no stub). Cada bloco descomprime independentemente, permitindo seek real em O(block_size) RAM.

---

## Arquitetura do Daemon P8.0

```
TEIA-VFS-Daemon-v0500.ps1
  ├─ Parâmetros
  │    -VFSRoot      : diretório com stubs (default: ActiveDrive_Test)
  │    -Port         : porta HTTP (default: 8765)
  │    -CacheDir     : cache de descompressão (default: TEIA_CORE/vfs_cache)
  │    -ClearCache   : limpa cache ao iniciar
  │
  ├─ Manifest (em memória)
  │    chave: original_name
  │    valor: { original_size_bytes, final_strategy, cas_path, ... }
  │
  ├─ HTTP Loop (System.Net.HttpListener — single-threaded)
  │    GET /status          → JSON daemon health
  │    GET /api/list        → JSON manifest completo
  │    GET /api/meta/{nome} → JSON metadados de um arquivo
  │    GET /api/read/{nome} → stream (Range header ou ?offset&length)
  │    HEAD /api/read/{nome} → headers com Content-Length = original_size_bytes
  │
  └─ Leitores por Estratégia
       cas.raw           → FileStream.Seek + Read (64KB chunks)
       gen.repeat        → gerar bytes do valor fixo para o range
       gen.pattern       → calcular bytes do padrão para o range
       cmp.lzma (GZip)   → descomprimir para CacheDir, depois seek
       cmp.brotli/mesh   → descomprimir para CacheDir, depois seek
```

---

## Invariantes P8.0

| Invariante | Garantia |
|------------|----------|
| **CAS Read-Only** | Nenhum byte escrito em `objects/` — operação pura de leitura |
| **Stub Read-Only** | Nenhum stub é modificado pelo daemon |
| **OOM Guard** | Leituras via `FileStream.Read` com buffer 64 KB fixo |
| **Cache isolado** | Arquivos descomprimidos ficam em `vfs_cache/` — nunca no ActiveDrive |
| **Idempotência** | Reiniciar o daemon produz resultado idêntico |

---

## Exemplo de Sessão de Teste

```powershell
# Terminal 1: iniciar daemon
pwsh -File D:\TEIA_CORE\tools\TEIA-VFS-Daemon-v0500.ps1 -VFSRoot D:\TEIA_USER\ActiveDrive_Test

# Terminal 2: verificar daemon
Invoke-RestMethod http://localhost:8765/status

# Listar arquivos virtuais (com tamanhos originais)
Invoke-RestMethod http://localhost:8765/api/list | Format-Table name, virtual_size_bytes, strategy

# Ler metadados
Invoke-RestMethod http://localhost:8765/api/meta/alice_wonderland.txt

# Ler primeiros 100 bytes via query params
Invoke-WebRequest 'http://localhost:8765/api/read/alice_wonderland.txt?offset=0&length=100'

# Ler com Range header (padrão HTTP)
Invoke-WebRequest 'http://localhost:8765/api/read/alice_wonderland.txt' `
    -Headers @{ Range = 'bytes=0-99' }

# Ler arquivo completo
Invoke-WebRequest 'http://localhost:8765/api/read/alice_wonderland.txt' `
    -OutFile D:\temp\alice_restored.txt
```

---

*Especificação P8.0 — 2026-05-29. Evolução: HTTP Daemon → WebDAV (P8.1) → ProjFS (P8.2) → WinFsp (P8.3).*
