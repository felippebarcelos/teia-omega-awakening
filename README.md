# TEIA — Storage as Computation

**Transcendência Epistêmica Integrada Autossintetizante**  
**Versão atual:** v1.2.0-claim-safe-demo

---

## O Que é a TEIA

A TEIA é um sistema de **Storage as Computation**. Em vez de armazenar bytes de um arquivo, ela armazena o **motor mínimo que sabe gerar esses bytes** — um seed JSON de parâmetros e um decoder script.

```
Armazenamento tradicional:  arquivo.csv  (4 MB)
TEIA:                        seed.json (900 B) + decoder.ps1 (2,2 KB) = 3,1 KB
Reconstrução:                decoder(seed) → arquivo.csv idêntico  (SHA-256 PASS)
```

**Não é mágica de compressão universal.** A TEIA atua onde os dados têm estrutura procedural detectável — IDs sequenciais, timestamps aritméticos, campos cíclicos, coordenadas por fórmula. Para esses dados, a TEIA supera GZip e Brotli por uma ou duas ordens de grandeza.

---

## Demo em 1 Clique

```powershell
# Pré-requisito: PowerShell 7+ no Windows. Sem dependências externas.

# Baixar e extrair o pacote demo
Expand-Archive TEIA_P19_CLAIM_SAFE_DEMO.zip

# Executar a auditoria
pwsh -ExecutionPolicy Bypass -File .\teia_demo_p19\audit-one-click.ps1
```

O script faz tudo automaticamente em menos de 30 segundos:

1. Gera 10 datasets estruturados do zero (JSON/CSV/SVG, até 5 MB cada)
2. Reconstrói os mesmos arquivos a partir das seeds e decoders armazenados (3 KB por arquivo)
3. Mede GZip e Brotli para comparação
4. Verifica `SHA-256(Reconstruído) == SHA-256(Original)` para cada arquivo
5. Imprime a tabela de resultados colorida
6. Apaga todos os arquivos temporários

---

## Resultados (v1.2.0)

| Arquivo | Original | Melhor Clássico | TEIA (Seed+Decoder) | Delta (Ganho) | SHA-256 |
|---------|:--------:|:---------------:|:-------------------:|:-------------:|:-------:|
| json_api_events.json | 5,33 MB | 346,6 KB | 3,14 KB | 99,1% ganhos | PASS |
| json_products.json | 2,79 MB | 215,8 KB | 3,30 KB | 98,5% ganhos | PASS |
| json_metrics.json | 4,35 MB | 195,5 KB | 3,14 KB | 98,4% ganhos | PASS |
| csv_sensor_data.csv | 4,13 MB | 403,5 KB | 3,16 KB | 99,2% ganhos | PASS |
| csv_transactions.csv | 2,38 MB | 352,9 KB | 2,62 KB | 99,3% ganhos | PASS |
| csv_server_logs.csv | 4,20 MB | 418,2 KB | 3,04 KB | 99,3% ganhos | PASS |
| csv_orders.csv | 2,92 MB | 205,4 KB | 3,05 KB | 98,5% ganhos | PASS |
| svg_scatter_20k.svg | 971,9 KB | 108,1 KB | 2,22 KB | 97,9% ganhos | PASS |
| svg_network_10k.svg | 1,60 MB | 201,4 KB | 2,73 KB | 98,6% ganhos | PASS |
| svg_heatmap_20k.svg | 1,16 MB | 58,4 KB | 2,40 KB | 95,8% ganhos | PASS |

**10/10 SHA-256 PASS** | Delta acumulado: **2,42 MB economizados** vs. melhor clássico

---

## Verificação de Integridade do Pacote

```powershell
(Get-FileHash .\TEIA_P19_CLAIM_SAFE_DEMO.zip -Algorithm SHA256).Hash.ToLower()
# Esperado: ae8239382c2ccc5066082558ae80ee15664f78c28d7649d69180ac4a978ebbdd
```

---

## Princípio Técnico

Dados **proceduralmente gerados** não precisam ser armazenados como bytes — podem ser armazenados como o **procedimento que os gerou**:

| Estrutura de dado | Armazenamento clássico | Armazenamento TEIA |
|-------------------|:----------------------:|:------------------:|
| IDs 1, 2, 3 … N | O(N × dígitos) | `{"start":1,"step":1}` — 30 B |
| Timestamps a cada 60s | O(N × 20 chars) | `{"base":"…","step_sec":60}` — 50 B |
| Campo enum cíclico | O(N × comprimento) | lista de valores + período — 100–200 B |
| Coordenadas MC | O(N × 2 floats) | `{m,a,mod,min}` × 2 — 80 B |

**Custo TEIA:** O(log N) — cresce com a complexidade do motor, não com N.  
**Custo clássico:** O(N × entropia residual) — cresce com o número de registros.

Para N suficientemente grande, TEIA sempre vence em dados procedurais.

---

## Limitações Explícitas

- Dados com **alta entropia real** (ruído, criptografia, imagens naturais): sem ganho.
- Dados **parcialmente estruturados** (logs reais mistos): podem exigir compressão híbrida.
- **Encoder automático** ainda não disponível — motor forjado manualmente (ou por LLM Scientist).
- Testado em **dados sintéticos** perfeitamente estruturados; aplicação a dados reais é o próximo vetor.

---

## Estrutura do Repositório

```
TEIA_CLAUDE_AWAKENING/
  release/
    teia_demo_p19/          — pacote demo auto-contido (62 KB)
      audit-one-click.ps1   — script da verdade
      seeds/                — 10 seeds (508–1.115 B cada)
      decoders/             — 10 decoders PowerShell/C#
      README_DEMO.md
    TEIA_P19_CLAIM_SAFE_DEMO.zip  — artefato empacotado (28,9 KB)

  tools/
    Analyze-SemanticSchema.ps1    — lente semântica (JSON/CSV/SVG)
    Test-DomainCrucible.ps1       — gerador benchmark P17
    Audit-P18Idempotency.ps1      — auditoria de reprodutibilidade P18

  sandbox/crucible_p17/
    seeds/      — 10 seeds canônicos
    decoders/   — 10 decoders P1 Patches
    prompts/    — blueprints e forge prompts

  docs/
    TEIA_P17_DOMAIN_RANKING_v1.md     — placar benchmark P17
    TEIA_P18_CLAIM_SAFE_AUDIT.md      — manifesto auditoria P18
    TEIA_RELEASE_NOTES_v1.2.0.md      — release notes desta versão
```

---

## Auditoria Manual de um Decoder

```powershell
cd release\teia_demo_p19

# Reconstruir um arquivo individualmente
.\decoders\Decode-json_api_events.ps1 `
    -SeedFile   .\seeds\seed_json_api_events.json `
    -OutputFile .\json_api_events_REBUILT.json

# Verificar SHA-256
(Get-FileHash .\json_api_events_REBUILT.json -Algorithm SHA256).Hash.ToLower()
# Esperado: b0836bd4c35f74b4b7ab576c7d26990dba762d16f9d6a26fcba0403130e0d3af
```

---

## Documentos Técnicos

| Documento | Descrição |
|-----------|-----------|
| [TEIA_P17_DOMAIN_RANKING_v1.md](docs/TEIA_P17_DOMAIN_RANKING_v1.md) | Benchmark completo: 10 domínios, 24,3x a 140,8x de ganho |
| [TEIA_P18_CLAIM_SAFE_AUDIT.md](docs/TEIA_P18_CLAIM_SAFE_AUDIT.md) | Auditoria de reprodutibilidade — prova tripla SHA-256 |
| [TEIA_RELEASE_NOTES_v1.2.0.md](docs/TEIA_RELEASE_NOTES_v1.2.0.md) | Release notes desta versão |
| [release/teia_demo_p19/README_DEMO.md](release/teia_demo_p19/README_DEMO.md) | Guia completo do pacote demo |

---

*TEIA v1.2.0-claim-safe-demo | 2026-06-01*
