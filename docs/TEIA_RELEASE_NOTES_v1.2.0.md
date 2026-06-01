# TEIA — Release Notes v1.2.0
## Storage as Computation: Public Demo Claim-Safe

**Data:** 2026-06-01  
**Tag Git:** `v1.2.0-claim-safe-demo`  
**Status:** RELEASE_PUBLICA

---

## Posicionamento Oficial

> **A TEIA é um sistema de Storage as Computation.** Ela não busca comprimir entropia arbitrária ou ruído aleatório. A TEIA atua descobrindo representações procedurais mínimas (motores específicos) para dados estruturados, validando a reconstrução byte a byte via SHA-256 e superando compressores genéricos na sua classe de domínio.

---

## Artefato de Auditoria

| Artefato | Arquivo | Tamanho | SHA-256 |
|----------|---------|:-------:|---------|
| Demo ZIP | `TEIA_P19_CLAIM_SAFE_DEMO.zip` | 28,9 KB | `ae8239382c2ccc5066082558ae80ee15664f78c28d7649d69180ac4a978ebbdd` |

**Verificação:**
```powershell
(Get-FileHash .\TEIA_P19_CLAIM_SAFE_DEMO.zip -Algorithm SHA256).Hash.ToLower()
# Esperado: ae8239382c2ccc5066082558ae80ee15664f78c28d7649d69180ac4a978ebbdd
```

O arquivo ZIP contém o pacote demo completo: 10 seeds, 10 decoders, script de auditoria e manifesto técnico. Nenhum dataset bruto incluído — apenas a inteligência que os regenera.

---

## 10 P1 Patches Conquistados

Cada motor abaixo armazena menos de 3,5 KB (seed + decoder) e reconstrói seu arquivo original com SHA-256 idêntico ao bit:

| P1 Patch | Arquivo Alvo | Original | Melhor Clássico | TEIA | Delta (Ganho) |
|----------|-------------|:--------:|:---------------:|:----:|:-------------:|
| P1-JSON-01 | json_api_events.json | 5,33 MB | 346,6 KB (GZip) | 3,14 KB | 99,1% ganhos |
| P1-JSON-02 | json_products.json | 2,79 MB | 215,8 KB (Brotli) | 3,30 KB | 98,5% ganhos |
| P1-JSON-03 | json_metrics.json | 4,35 MB | 195,5 KB (Brotli) | 3,14 KB | 98,4% ganhos |
| P1-CSV-04 | csv_sensor_data.csv | 4,13 MB | 403,5 KB (Brotli) | 3,16 KB | 99,2% ganhos |
| P1-CSV-05 | csv_transactions.csv | 2,38 MB | 352,9 KB (Brotli) | 2,62 KB | 99,3% ganhos |
| P1-CSV-06 | csv_server_logs.csv | 4,20 MB | 418,2 KB (Brotli) | 3,04 KB | 99,3% ganhos |
| P1-CSV-07 | csv_orders.csv | 2,92 MB | 205,4 KB (Brotli) | 3,05 KB | 98,5% ganhos |
| P1-SVG-08 | svg_scatter_20k.svg | 971,9 KB | 108,1 KB (GZip) | 2,22 KB | 97,9% ganhos |
| P1-SVG-09 | svg_network_10k.svg | 1,60 MB | 201,4 KB (Brotli) | 2,73 KB | 98,6% ganhos |
| P1-SVG-10 | svg_heatmap_20k.svg | 1,16 MB | 58,4 KB (Brotli) | 2,40 KB | 95,8% ganhos |

**Total:** Delta acumulado de 2,42 MB economizados vs. melhor compressor clássico. 10/10 SHA-256 PASS.

---

## O Que Esta Versão NÃO Faz

**Honestidade claim-safe — limites explícitos:**

- **Não comprime entropia arbitrária.** Dados verdadeiramente aleatórios (criptografia, imagens naturais, executáveis compilados) não têm estrutura procedural detectável. A TEIA não obtém ganhos sobre esses dados.
- **Não é um "zip universal".** GZip e Brotli comprimem qualquer coisa com ganhos modestos. A TEIA vence apenas em dados estruturados onde o motor procedural é detectável.
- **Não processa dados reais automaticamente.** Esta versão usa dados sintéticos perfeitamente estruturados. A aplicação a dados reais (P20+) exige engenharia de motor por domínio e pode revelar entropia residual irredutível.
- **Não é uma ferramenta acabada.** O encoder automático (que detecta a estrutura procedural de um arquivo desconhecido) ainda não existe nesta versão. O analista humano (ou agente LLM) ainda é necessário para forjar o motor.

---

## Histórico de Protocolos nesta Release

| Protocolo | Descrição | Resultado |
|-----------|-----------|-----------|
| P13.1 | Primeiro seed AutoSynth — 1.352 B | PASS |
| P14.0 | VFS via WinFsp — P90 de latência 2,8ms | PASS |
| P15.0 | Whitepaper fundacional | PUBLICADO |
| P16.0 | Lente Semântica — 2.143 B menor que Brotli | ONTOPROCEDURAL_VALIDATED |
| P17.0 | Domain Lens Benchmark — 10 domínios 10/10 | 24,3x a 140,8x de ganho |
| P18.0 | Auditoria de Reprodutibilidade P18 | 10/10 IDEMPOTENCIA_WRITE_READ_PROVADA |
| P19.0 | Pacote Demo Público Claim-Safe | 62 KB de inteligência, 3,2s de execução |
| P20.0 | Release Pública v1.2.0 | ESTA VERSÃO |

---

## Próximos Vetores

1. **P20+ — Dados Reais:** aplicar os P1 Patches a arquivos reais de `D:\TEIA_USER\MyRealData\`.
2. **Encoder Automático (P17.1):** script que detecta estrutura procedural em arquivo desconhecido e forja motor automaticamente.
3. **Compressão Híbrida:** P1 AutoSynth para campos estruturados + Brotli para entropia residual.

---

*TEIA — Transcendência Epistêmica Integrada Autossintetizante*  
*Release v1.2.0 | 2026-06-01 | tag: v1.2.0-claim-safe-demo*
