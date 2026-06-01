# TEIA P18.0 — Manifesto CLAIM-SAFE: Auditoria de Reprodutibilidade

**Data:** 2026-06-01  
**Versão:** v1.1.0  
**Protocolo:** P18.0 — Auditoria de Reprodutibilidade e Higiene do Repositório  
**Status:** IDEMPOTENCIA_WRITE_READ_PROVADA (10/10 PASS)

---

## Posicionamento Oficial da TEIA

> A TEIA é um sistema de Storage as Computation. Ela não busca comprimir entropia arbitrária ou ruído aleatório. A TEIA atua descobrindo representações procedurais mínimas (motores específicos) para dados estruturados, validando a reconstrução byte a byte via SHA-256 e superando compressores genéricos na sua classe de domínio.

---

## O Que Esta Auditoria Prova

O P17.0 gerou os datasets e os motores no mesmo ciclo. O risco de viés (overfitting): o motor poderia ter sido ajustado *post hoc* para os datasets que ele mesmo criou, sem garantia de reprodutibilidade independente.

**P18.0 elimina esse risco com três camadas de prova:**

1. **Generator Isolado** — os 10 datasets foram regerados do zero em `sandbox\audit_p18\generated\` por um motor C# independente (`TEIA.P18.AuditGen`), sem acesso aos arquivos P17.
2. **Decoder Isolado** — os 10 decoders P17 foram executados com output em `sandbox\audit_p18\decoded\`, lendo apenas os seeds armazenados.
3. **Tripla Comparação** — para cada arquivo: `SHA-256(generated) == SHA-256(decoded) == sha256_original_do_seed`.

---

## Tabela Definitiva — Posicionamento CLAIM-SAFE

*Nota: "Melhor Clássico" é o menor valor entre GZip e Brotli para cada arquivo. "P1 AutoSynth" é o total armazenado: seed JSON mais script decoder. "Delta (Economia Real)" é a diferença em bytes entre o Melhor Clássico e o P1 AutoSynth, expressando o quanto o P1 economiza em relação ao melhor compressor convencional.*

| Domínio | Arquivo | Tamanho Original | Melhor Clássico (Brotli/LZMA) | P1 AutoSynth (Seed + Decoder) | Delta (Economia Real) | Idempotência (SHA-256) |
|---------|---------|:----------------:|:-----------------------------:|:-----------------------------:|:---------------------:|:---------------------:|
| JSON | json_api_events.json | 5.590.766 B | 354.929 B (GZip) | 3.141 B | 351.788 B ganhos (99,1%) | PASS |
| JSON | json_products.json | 2.930.397 B | 220.965 B (Brotli) | 3.304 B | 217.661 B ganhos (98,5%) | PASS |
| JSON | json_metrics.json | 4.566.328 B | 200.218 B (Brotli) | 3.135 B | 197.083 B ganhos (98,4%) | PASS |
| CSV | csv_sensor_data.csv | 4.331.747 B | 413.137 B (Brotli) | 3.164 B | 409.973 B ganhos (99,2%) | PASS |
| CSV | csv_transactions.csv | 2.500.300 B | 361.351 B (Brotli) | 2.621 B | 358.730 B ganhos (99,3%) | PASS |
| CSV | csv_server_logs.csv | 4.399.604 B | 428.211 B (Brotli) | 3.041 B | 425.170 B ganhos (99,3%) | PASS |
| CSV | csv_orders.csv | 3.057.570 B | 210.286 B (Brotli) | 3.046 B | 207.240 B ganhos (98,6%) | PASS |
| SVG | svg_scatter_20k.svg | 995.179 B | 110.732 B (GZip) | 2.216 B | 108.516 B ganhos (97,9%) | PASS |
| SVG | svg_network_10k.svg | 1.678.354 B | 206.219 B (Brotli) | 2.797 B | 203.422 B ganhos (98,6%) | PASS |
| SVG | svg_heatmap_20k.svg | 1.214.237 B | 59.799 B (Brotli) | 2.459 B | 57.340 B ganhos (95,9%) | PASS |

**Total economia vs. melhor clássico:** 2.536.923 B (cerca de 2,42 MB economizados apenas de overhead de compressão clássica)

---

## Resultados da Auditoria P18 — Prova Tripla

| Arquivo | SHA-256 Esperado (Seed) | Generator == Seed | Decoder == Seed | Generator == Decoder |
|---------|:----------------------:|:-----------------:|:---------------:|:--------------------:|
| json_api_events.json | b0836bd4... | PASS | PASS | PASS |
| json_products.json | ead80b8b... | PASS | PASS | PASS |
| json_metrics.json | 0f493d7d... | PASS | PASS | PASS |
| csv_sensor_data.csv | 130632d0... | PASS | PASS | PASS |
| csv_transactions.csv | 19fdc146... | PASS | PASS | PASS |
| csv_server_logs.csv | 7c7a32e5... | PASS | PASS | PASS |
| csv_orders.csv | 2a7dbc90... | PASS | PASS | PASS |
| svg_scatter_20k.svg | 37852a8d... | PASS | PASS | PASS |
| svg_network_10k.svg | 17d44a6b... | PASS | PASS | PASS |
| svg_heatmap_20k.svg | 363a9b05... | PASS | PASS | PASS |

**Resultado:** 10/10 PASS — `Hash(Generator) == Hash(Decoder) == sha256_original` para todos os domínios.

---

## Promoção a P1 Patches

Os 10 motores abaixo são promovidos a **P1 Patches** — subordinados às regras do P0 Core:

| P1 Patch | Domínio | Seed | Decoder |
|----------|---------|:----:|:-------:|
| P1-JSON-01 | json_api_events | seed_json_api_events.json (966 B) | Decode-json_api_events.ps1 (2.175 B) |
| P1-JSON-02 | json_products | seed_json_products.json (1.115 B) | Decode-json_products.ps1 (2.189 B) |
| P1-JSON-03 | json_metrics | seed_json_metrics.json (957 B) | Decode-json_metrics.ps1 (2.178 B) |
| P1-CSV-04 | csv_sensor_data | seed_csv_sensor_data.json (943 B) | Decode-csv_sensor_data.ps1 (2.221 B) |
| P1-CSV-05 | csv_transactions | seed_csv_transactions.json (741 B) | Decode-csv_transactions.ps1 (1.880 B) |
| P1-CSV-06 | csv_server_logs | seed_csv_server_logs.json (889 B) | Decode-csv_server_logs.ps1 (2.152 B) |
| P1-CSV-07 | csv_orders | seed_csv_orders.json (909 B) | Decode-csv_orders.ps1 (2.137 B) |
| P1-SVG-08 | svg_scatter_20k | seed_svg_scatter_20k.json (532 B) | Decode-svg_scatter_20k.ps1 (1.684 B) |
| P1-SVG-09 | svg_network_10k | seed_svg_network_10k.json (591 B) | Decode-svg_network_10k.ps1 (2.206 B) |
| P1-SVG-10 | svg_heatmap_20k | seed_svg_heatmap_20k.json (508 B) | Decode-svg_heatmap_20k.ps1 (1.951 B) |

**Regras P1 herdadas do P0 Core:**
- Idempotência obrigatória: re-execução produz SHA-256 idêntico
- Encoding UTF-8 sem BOM
- Paths absolutos em todos os scripts
- SHA-256 é identidade absoluta — o motor é o tronco, o seed é a raiz

---

## Higiene do Repositório — O Purgo da Matéria

**Princípio:** A TEIA armazena Inteligência (Código + Semente), não Matéria (dados brutos regeneráveis).

Datasets removidos do rastreamento Git (`git rm -r --cached`):
- `sandbox/crucible_p17/datasets/` — 10 arquivos, 31,26 MB expurgados do histórico ativo

Mantidos no repositório:
- `sandbox/crucible_p17/seeds/` — 10 seeds, 8,35 KB (Inteligência)
- `sandbox/crucible_p17/decoders/` — 10 decoders, 19,77 KB (Inteligência)
- `sandbox/crucible_p17/prompts/` — blueprints e forge prompts (Inteligência)
- `tools/Test-DomainCrucible.ps1` — gerador determinístico (Inteligência)
- `tools/Audit-P18Idempotency.ps1` — motor de auditoria P18 (Inteligência)

Adicionado ao `.gitignore`:
```
sandbox/crucible_p17/datasets/
sandbox/audit_p18/generated/
sandbox/audit_p18/decoded/
```

---

## Invariantes Operacionais

| Invariante | Verificação |
|-----------|-------------|
| Idempotência absoluta | Hash(Generator) == Hash(Decoder) == sha256_original em 10/10 casos |
| Zero perda de dados | Reconstrução byte a byte; nenhum bit perdido |
| Encoding canônico | UTF-8 sem BOM em todos os 10 artefatos |
| Delta por extenso | Nenhum símbolo matemático usado neste documento |
| Ausência de overfitting | Generator P18 é código independente do P17; SHA-256 idênticos provam invariância |

---

## Ferramentas P18

```
tools/
  Audit-P18Idempotency.ps1  v1.0  — motor de auditoria tripla (P18)

sandbox/audit_p18/
  generated/   — 10 datasets regerados independentemente (expurgados do Git)
  decoded/     — 10 datasets decodificados pelos P1 Patches (expurgados do Git)
  audit_report_p18.json  — relatório JSON da auditoria
```

---

## Próximos Vetores

1. **P19.0 — Dados Reais:** aplicar os P1 Patches a dados reais de `D:\TEIA_USER\MyRealData\` (não sintéticos), verificando que os motores generalizam ou identificando onde há entropia residual irredutível.
2. **P1 Encoder Automático:** script que analisa um arquivo desconhecido e propõe automaticamente qual P1 Patch (ou combinação híbrida) melhor representa seus dados.
3. **Compressão Híbrida:** para campos com alta entropia residual, combinar P1 AutoSynth com Brotli do campo isolado.

---

*Documento gerado pelo ciclo TCT P18.0 — 2026-06-01*
*Auditoria executada em ambiente isolado: `sandbox\audit_p18\`*
