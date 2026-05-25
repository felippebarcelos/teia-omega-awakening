# D:\TEIA_CORE — Estrutura Centralizada TEIA-Ω
**Criado**: 2026-05-25 | **Motor**: v0.11.0 | **Repositório git**: D:\TEIA_CLAUDE_AWAKENING

---

## Layout de Diretórios

```
D:\TEIA_CORE\
├── benchmarks\      — resultados e harnesses de benchmark (D7, D8, canonical)
├── proofs\          — pacotes de prova SHA-256 (TEIA_PROVA_v12.zip, proof.json)
├── seeds\           — seeds canônicas por domínio (D1–D5, D7, D8)
├── manifests\       — manifests de corpus (D7_REAL_MANIFEST.json, D8_STRESS_MANIFEST.json)
├── docs\            — documentação técnica e relatórios
├── tools\           — ferramentas externas (zstd, 7z, Python)
├── agents\          — configurações de agentes (PaperclipAI, MCP)
├── memory\          — memória procedural e snapshots de sessão
└── QUARENTENA_DEBRIS\ — arquivos sem hash registrado, aguardando triagem
```

---

## Repositório Principal

| Campo | Valor |
|-------|-------|
| Caminho git | `D:\TEIA_CLAUDE_AWAKENING` |
| Remote | `https://github.com/felippebarcelos/teia-omega-awakening` |
| Branch | `master` |
| HEAD atual | ver `git log --oneline -1` |
| Motor canônico | `TEIA-Core-v0.11.0.psm1` |
| SHA-256 motor | `a56b18c0e17f4d1037340adf78f057f44e0fdbe21a5201fca6e1d17fb379ec39` |

---

## Raiz do Núcleo CAS

| Campo | Valor |
|-------|-------|
| Caminho | `D:\bruto\TEIA\TEIA_NUCLEO\offline\nano` |
| fractal_index.json | presente neste diretório |
| Nota | O CLAUDE.md referencia `D:\Teia\...` (path desatualizado) — raiz real é `D:\bruto\TEIA\...` |

---

## Benchmarks Certificados (v0.11.0)

| Corpus | Arquivos | Resultado | Savings | Commit |
|--------|----------|-----------|---------|--------|
| D7 (botocore + Google API JSON) | 105 | 105/105 | 121 812 B | `6dcc330` |
| D8 (logs + tokenizers) | 17 | 17/17 | 24 709 B | `afe367b` |
| **Combinado** | **122** | **122/122** | **146 521 B** | — |

---

## Migração de Espaço C: → D:

Ações executadas para liberar C::

| Ação | Espaço liberado | Método |
|------|----------------|--------|
| npm cache → D:\npm-cache | ~359 MB | `npm config set cache` |
| pip cache → D:\pip-cache | ~38 MB | `pip config set` |
| (pendente) Downloads → D:\Downloads | ~10.7 GB | junction mklink /j (requer admin) |
| (pendente) .platformio → D:\platformio | ~1.5 GB | junction mklink /j (requer admin) |
| (pendente) System Volume Information | ~40 GB | requer admin + vssadmin |

---

## Como Reproduzir a Prova

```powershell
cd D:\TEIA_CLAUDE_AWAKENING
python criar_prova_v12.py        # gera TEIA_PROVA_v12.zip (82 KB)
python criar_golden_master_v0110.py  # gera snapshot completo 560 MB
```

---

*Este arquivo é o ponto de entrada para qualquer engenheiro que precise entender o layout do ecossistema TEIA-Ω.*
