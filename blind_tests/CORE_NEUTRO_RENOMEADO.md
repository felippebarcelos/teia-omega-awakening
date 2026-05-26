# CORE_NEUTRO_RENOMEADO — Pacote de Contexto C
> Framing: narrativa neutra, nomes genéricos de engenharia de sistemas.
> Mesmo conteúdo técnico dos pacotes A e B.

---

## VAULT-SYS — SISTEMA DE GESTÃO DE CONTEÚDO IMUTÁVEL

### Princípio de chave de conteúdo

O hash SHA-256 de um arquivo é sua **content_key** — identificador único e imutável.
Arquivos com bytes idênticos compartilham a mesma content_key e são armazenados
como um único objeto no ContentVault. O nome de arquivo é um alias; a content_key
é a identidade real do objeto.

### Layout de diretórios

```
D:\VAULT_BACKEND\                   ← núcleo de armazenamento (não exposto ao usuário)
  store\                            ← ObjectStore: {content_key_hex}.obj
  registry\
    object_index.json               ← índice de objetos: [{key, size, registered_at, state}, ...]
    file_ledger.json                ← ledger de arquivos: [{user_path, name, key, size, state, ...}]
  descriptors\                      ← {content_key_hex}.descriptor.json (metadados de reconstrução)
  staging_errors\                   ← arquivos com falha de validação — retidos, nunca excluídos
  audit_log.jsonl                   ← log de operações em JSON Lines
  runtime\
    monitor_state.json              ← último estado do processo de monitoramento
    monitor.lock                    ← PID do daemon monitor (prevenção de instâncias duplicadas)

D:\WORKSPACE_USER\                  ← área de trabalho exposta ao usuário final
  Inbox\                            ← entrada de novos arquivos
  Documents\
  Images\
  Videos\
```

### Pipeline de registro (ingestion)

```
1. compute content_key = sha256(file)
2. dest = store/{content_key}.obj
3. if exists(dest): state=VERIFIED; skip — object already registered
4. else: copy(file, dest); assert sha256(dest)==content_key
5. update file_ledger.json atomically → state=REGISTERED
6. append audit event REG_OK to audit_log.jsonl
```

**Idempotência:** re-executar o pipeline sobre o mesmo arquivo produz resultado idêntico.
Re-registro com content_key conhecida → estado `VERIFIED`; sem cópia adicional.

### Protocolo de escrita segura de arquivos de registro

```
write(target.tmp, new_content)      ← arquivo temporário (nunca sobrescreve direto)
json_parse_verify(target.tmp)       ← falha se conteúdo inválido — aborta
copy(target, target.bak)            ← backup do estado anterior
rename(target.tmp → target)         ← substituição atômica
```

Qualquer falha entre etapas mantém o arquivo de registro anterior intacto.

### Daemon de monitoramento (Monitor)

- Varre lista configurável de diretórios de entrada
- Mantém em memória HashSet de content_keys já presentes no ObjectStore
- Detecta arquivos não registrados e os processa automaticamente
- Suporta modo de execução única ou ciclo contínuo
- Arquivo de lock com PID previne instâncias paralelas
- Orphan detection: se PID no lock não existe, lock é descartado e nova instância pode iniciar

### Módulo de síntese de descritores (DescriptorGen v2.0)

- Recebe arquivo de entrada
- Computa content_key → registra no ObjectStore (idempotente)
- Gera `{content_key}.descriptor.json`:
  ```json
  {
    "module": "gen_baseline_descriptor",
    "content_key": "...",
    "filename": "document.txt",
    "size": 125,
    "entropy_sample": { "head_hex": "...", "tail_hex": "...", "size_bytes": 125 }
  }
  ```
- Atualiza `file_ledger.json`: state → `ARCHIVED_SAFE`

### Ciclo de estados de um arquivo

```
[novo arquivo]                    → REGISTERED     (primeiro registro)
[re-registro, mesma content_key]  → VERIFIED        (deduplica­ção confirmada)
[descritor gerado]                → ARCHIVED_SAFE   (metadados capturados)
[arquivo ausente, obj disponível] → REGISTERED      (restauração do ObjectStore)
```

### Invariantes do sistema

1. A content_key (SHA-256) é a única fonte de verdade sobre identidade de conteúdo.
2. Toda operação de pipeline é idempotente — segura para re-execução.
3. Nenhum arquivo de usuário é excluído — movido para `staging_errors` no pior caso.
4. Arquivos de registro são sempre escritos atomicamente (tmp → verify → bak → rename).
5. Apenas uma instância do daemon monitor por host (singleton por lock file).
6. Estados ausentes são reportados explicitamente — nunca inferidos.

### Estado atual do sistema (snapshot 2026-05-26)

| Métrica | Valor |
|---------|-------|
| Objetos no ObjectStore | 2369 |
| Integridade de content_keys | 2369/2369 (100%) |
| Volume total armazenado | 23.3 MB |
| Arquivos no file_ledger | 5 (3× ARCHIVED_SAFE, 2× REGISTERED) |
| Entradas no object_index | 2553 |
| Último ciclo do monitor | 2026-05-26 12:33 |

### Especificações de hardware

- CPU: Intel i3-10100F (4 cores / 8 threads)
- RAM: 8 GB
- SO: Windows 11 Pro
- Runtime: PowerShell 5/7 + Python 3.x
