# CORE_TECNICO — Pacote de Contexto A
> Framing: técnico puro. Sem terminologia de projeto, narrativa ou metáforas.

---

## SISTEMA DE ARMAZENAMENTO ENDEREÇÁVEL POR CONTEÚDO

### Princípio de identidade

O hash SHA-256 de um arquivo é seu identificador canônico e permanente.
Dois arquivos com conteúdo idêntico produzem o mesmo hash — portanto ocupam
um único objeto no armazenamento. O nome de arquivo é apenas um ponteiro
conveniente; o hash é a identidade real.

### Estrutura de armazenamento

```
D:\STORAGE_BACKEND\
  objects\            ← {sha256_hex}.bin  (um arquivo por conteúdo único)
  manifests\
    index.json        ← array JSON: [{hash, size, ingested_at, status}, ...]
    file_map.json     ← array JSON: [{path_user, name, hash, size, status, ...}]
  seeds\              ← {sha256_hex}.seed.json (metadados de regeneração)
  quarantine\         ← arquivos suspeitos movidos aqui, nunca deletados
  logs\
    events.jsonl      ← log de eventos em JSON Lines
    watchdog.json     ← estado do processo monitor
  locks\
    watchdog.lock     ← PID do processo monitor (prevenção de instâncias paralelas)

D:\STORAGE_USER\
  Inbox\              ← entrada de arquivos do usuário
  Documents\
  Images\
  Videos\
```

### Pipeline de ingestão

```
1. get_sha256(file)                 → hash (string hex de 64 chars)
2. dest = objects/{hash}.bin
3. if exists(dest): status=VERIFIED; skip copy
4. else: copy(file, dest); verify get_sha256(dest)==hash
5. update file_map.json atomically  → status=INGESTED
6. log event IG_OK to events.jsonl
```

**Idempotência:** toda re-execução sobre o mesmo arquivo produz resultado idêntico.
Re-ingestão detecta hash igual → status `VERIFIED`; não copia novamente.

### Escrita atômica de manifests JSON

```
write(path.tmp, new_content)        ← nunca sobrescreve direto
parse_verify(path.tmp)              ← aborta se JSON inválido
copy(path, path.bak)                ← backup do arquivo anterior
rename(path.tmp → path)             ← troca atômica
```

Garante que qualquer crash entre passos deixa o arquivo anterior intacto.

### Processo monitor (watchdog)

- Varre múltiplos diretórios configurados em lista fixa
- Compara hashes encontrados contra índice em memória (HashSet[string])
- Detecta arquivos novos (não indexados) e os ingere automaticamente
- Executa em ciclo único (`-Once`) ou contínuo
- Utiliza arquivo de lock (PID) para prevenir execuções paralelas
- Orphan detection: se o PID no lock não existe mais, o lock é considerado expirado

### Motor de síntese (gerador de sementes)

- Recebe arquivo de entrada
- Calcula SHA-256 → ingere no CAS (se necessário)
- Gera `{hash}.seed.json`:
  ```json
  {
    "fn": "gen_dummy_seed",
    "hash_sha256": "...",
    "nome": "arquivo.txt",
    "size": 125,
    "entropy": { "head_hex": "...", "tail_hex": "...", "size_bytes": 125 }
  }
  ```
- Atualiza `file_map.json`: status → `SAFE_TO_ARCHIVE`

### Ciclo de status de um arquivo

```
[novo arquivo] → INGESTED
[re-ingestão, mesmo hash] → VERIFIED
[semente gerada] → SAFE_TO_ARCHIVE
[arquivo ausente, restaurado do objeto] → INGESTED
```

### Invariantes do sistema

1. O hash SHA-256 nunca mente — é a única fonte de verdade sobre identidade.
2. Toda operação é segura para re-execução (idempotência obrigatória).
3. Nenhum arquivo de usuário é apagado — movido para quarentena no pior caso.
4. Manifestos JSON são sempre escritos atomicamente.
5. Um único processo monitor por máquina (singleton por lock file).
6. Ausência confirmada não é inventada — lacunas são declaradas explicitamente.

### Estado atual do sistema

| Métrica | Valor |
|---------|-------|
| Objetos no storage | 2369 |
| Integridade SHA-256 | 2369/2369 (100%) |
| Volume total | 23.3 MB |
| Arquivos no file_map | 5 (3× SAFE_TO_ARCHIVE, 2× INGESTED) |
| Entradas no índice | 2553 |
| Último ciclo do monitor | 2026-05-26 12:33 |

### Hardware de execução

- CPU: Intel i3-10100F (4 cores / 8 threads)
- RAM: 8 GB
- SO: Windows 11 Pro
- Runtime: PowerShell 5/7 + Python 3.x
