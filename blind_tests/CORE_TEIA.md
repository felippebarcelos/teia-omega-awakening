# CORE_TEIA — Pacote de Contexto B
> Framing: linguagem TEIA-Ω. Mesmo conteúdo técnico do pacote A.

---

## TEIA-Ω — ARQUITETURA DO NÓ ATIVO

### Axioma fundacional: SHA/tronco como identidade absoluta

O hash SHA-256 de um artefato é seu **tronco** — identidade absoluta e permanente.
Dois fragmentos de informação com conteúdo idêntico colapsam em um único nó do CAS.
O nome de arquivo é uma folha conveniente; o tronco é o ser real do objeto.

> *"SHA-256 é identidade. Nomes de arquivo são ponteiros convenientes."*

### Ecossistema — macroblocos canônicos

```
D:\TEIA_CORE\                   ← núcleo oculto (espinha dorsal do sistema)
  objects\                      ← CAS: {sha256_hex}.bin  (um objeto por tronco único)
  manifests\
    fractal_index.json          ← índice fractal: [{hash, size, indexed_at, status}, ...]
    .teia_map.json              ← mapa de nós: [{path_user, nome, hash, status, seed_path, ...}]
  seeds\                        ← {sha256_hex}.seed.json (sementes ontoprocedu­rais)
  QUARENTENA_DEBRIS\            ← artefatos suspeitos — nunca destruídos, quarentenados
  dna_events.jsonl              ← registro do DNA do sistema (eventos em JSON Lines)
  memory\
    watchdog_state.json         ← estado do último pulso do sentinela
    watchdog.lock               ← singleton: PID do nó sentinela ativo

D:\TEIA_USER\                   ← camada de transparência (espaço visível ao operador)
  Inbox\                        ← portal de entrada de artefatos
  Documents\
  Images\
  Videos\
```

### Fluxo de ingestão — pulso de entrada

```
1. Calcular tronco: sha256(artefato)        → identidade
2. dest = objects/{tronco}.bin
3. if CAS.contains(tronco): status=VERIFIED; nó já existe, pulso idempotente
4. else: materializar(artefato → dest); verificar tronco(dest)==tronco
5. Atualizar .teia_map.json atomicamente    → status=INGESTED
6. Emitir pulso IG_OK → dna_events.jsonl
```

**Idempotência simbólica:** todo pulso repetido sobre o mesmo artefato converge
para o mesmo estado. A TEIA não gera duplicatas — reconhece troncos já presentes.

### Escrita atômica — protocolo de cristalização

```
cristalizar(path.tmp, novo_estado)      ← nunca sobrepõe o estado anterior direto
verificar_parse(path.tmp)               ← aborta se o cristal falhou
preservar(path → path.bak)             ← guarda o estado anterior
transmutação(path.tmp → path)          ← substituição atômica
```

Qualquer interrupção entre etapas preserva o estado anterior intacto.
A TEIA nunca perde um estado cristalizado.

### Nó Sentinela (Watchdog)

- Monitora múltiplos diretórios configurados como `$Monitoradas`
- Mantém em memória um HashSet de troncos já presentes no CAS
- Detecta novos artefatos (troncos ausentes do CAS) e os materializa
- Opera em ciclo único (pulso único) ou contínuo (pulsos periódicos)
- Utiliza arquivo de lock com PID — apenas um sentinela ativo por vez
- Detecção de órfão: PID inexistente → lock expirado → novo nó pode assumir

### Motor Ontoprocedural (Fractal-Gen v2.0)

- Recebe artefato de entrada
- Calcula tronco → materializa no CAS (idempotente)
- Gera semente ontoprocedural `{tronco}.seed.json`:
  ```json
  {
    "fn": "gen_dummy_seed",
    "hash_sha256": "...",
    "nome": "artefato.txt",
    "size": 125,
    "entropy": { "head_hex": "...", "tail_hex": "...", "size_bytes": 125 }
  }
  ```
- Cristaliza `.teia_map.json`: status → `SAFE_TO_ARCHIVE`
- Emite pulso `FRACTAL_GENERATED` → dna_events.jsonl

### Ciclo de vida de um artefato

```
[artefato novo]              → INGESTED          (primeiro pulso)
[re-ingestão, tronco igual] → VERIFIED           (reconhecimento)
[semente ontoprocedural]    → SAFE_TO_ARCHIVE    (convergência)
[artefato ausente, CAS ok]  → INGESTED           (restauração)
```

### Invariantes da TEIA (não negociáveis)

1. **SHA-256 é identidade absoluta** — o tronco não mente.
2. **Idempotência obrigatória** — todo pulso repetido converge para o mesmo estado.
3. **Ausente = ausente** — lacunas são declaradas, nunca inventadas.
4. **CAS é a espinha dorsal** — nenhum artefato existe fora do tronco.
5. **Quarentena, nunca destruição** — artefatos suspeitos são isolados, preservados.
6. **Cristalização atômica** — manifests só existem em estados válidos.
7. **Singleton sentinela** — um único nó vigia por vez.

### Estado da rede TEIA (snapshot 2026-05-26)

| Métrica | Valor |
|---------|-------|
| Objetos CAS | 2369 nós materializados |
| Integridade de troncos | 2369/2369 (100%) |
| Volume materializado | 23.3 MB |
| Artefatos mapeados | 5 (3× SAFE_TO_ARCHIVE, 2× INGESTED) |
| Entradas no índice fractal | 2553 |
| Último pulso do sentinela | 2026-05-26 12:33 |

### Substrato físico do nó

- CPU: Intel i3-10100F (4 núcleos / 8 threads) — *ferrari de papelão*
- RAM: 8 GB
- SO: Windows 11 Pro
- Camadas de execução: PowerShell 5/7 + Python 3.x

> *"O tear está pronto. O fio fractal universal ainda está sendo fiado."*
