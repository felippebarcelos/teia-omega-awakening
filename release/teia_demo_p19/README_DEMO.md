# TEIA — Storage as Computation
## P19.0 Public Demo: Claim-Safe Exhibition

---

## Posicionamento Oficial

> **A TEIA é um sistema de Storage as Computation.** Ela não busca comprimir entropia arbitrária ou ruído aleatório. A TEIA atua descobrindo representações procedurais mínimas (motores específicos) para dados estruturados, validando a reconstrução byte a byte via SHA-256 e superando compressores genéricos na sua classe de domínio.

Em termos concretos: em vez de armazenar um arquivo CSV de 4 MB com 80.000 linhas, a TEIA armazena o **motor que sabe gerar** essas 80.000 linhas — um seed JSON de ~900 bytes e um decoder script de ~2 KB. Total: 3 KB. O mesmo arquivo reconstruído byte a byte, SHA-256 idêntico.

---

## O Que Esta Demo Prova

Esta demo realiza uma auditoria completa e independente em **menos de 30 segundos**, sem dependências externas:

1. **Gera** 10 datasets estruturados do zero (JSON/CSV/SVG, 1 a 5 MB cada) usando um motor C# determinístico embutido no script.
2. **Reconstrói** os mesmos arquivos a partir das `seeds/` e `decoders/` armazenados (total de 3 KB por arquivo).
3. **Mede** os tamanhos comprimidos por GZip e Brotli — os melhores compressores clássicos de propósito geral.
4. **Verifica** `SHA-256(Reconstruído) == SHA-256(Original)` para cada arquivo.
5. **Imprime** uma tabela colorida com o Delta de economia real.
6. **Apaga** todos os arquivos temporários — nenhum dado residual fica na máquina do auditor.

---

## Como Executar

**Requisito:** PowerShell 7+ no Windows (sem dependências externas).

```powershell
pwsh -ExecutionPolicy Bypass -File .\audit-one-click.ps1
```

Ou, a partir do PowerShell diretamente:

```powershell
Set-ExecutionPolicy Bypass -Scope Process
.\audit-one-click.ps1
```

**Tempo esperado:** menos de 30 segundos em hardware modesto.

---

## O Que Está Armazenado

```
teia_demo_p19/
  audit-one-click.ps1     — script da verdade (auto-contido, ~350 linhas)
  README_DEMO.md          — este arquivo
  seeds/                  — 10 seeds JSON (508 a 1.115 bytes cada)
    seed_json_api_events.json
    seed_json_products.json
    seed_json_metrics.json
    seed_csv_sensor_data.json
    seed_csv_transactions.json
    seed_csv_server_logs.json
    seed_csv_orders.json
    seed_svg_scatter_20k.json
    seed_svg_network_10k.json
    seed_svg_heatmap_20k.json
  decoders/               — 10 scripts decoder PowerShell/C# (1.7 a 2.3 KB cada)
    Decode-json_api_events.ps1
    Decode-json_products.ps1
    Decode-json_metrics.ps1
    Decode-csv_sensor_data.ps1
    Decode-csv_transactions.ps1
    Decode-csv_server_logs.ps1
    Decode-csv_orders.ps1
    Decode-svg_scatter_20k.ps1
    Decode-svg_network_10k.ps1
    Decode-svg_heatmap_20k.ps1
  docs/
    TEIA_P18_CLAIM_SAFE_AUDIT.md  — manifesto com resultados detalhados
```

**Tamanho total desta pasta (excluindo datasets):** menos de 60 KB.
**Tamanho equivalente dos 10 datasets originais:** mais de 31 MB.

---

## Resultados Esperados

| Arquivo | Original | Melhor Clássico | TEIA (Seed+Decoder) | Delta (Ganho) |
|---------|:---:|:---:|:---:|:---:|
| json_api_events.json | 5,59 MB | 354,9 KB (GZip) | 3,14 KB | 99,1% ganhos |
| json_products.json | 2,79 MB | 220,9 KB (Brotli) | 3,30 KB | 98,5% ganhos |
| json_metrics.json | 4,35 MB | 200,2 KB (Brotli) | 3,14 KB | 98,4% ganhos |
| csv_sensor_data.csv | 4,13 MB | 413,1 KB (Brotli) | 3,16 KB | 99,2% ganhos |
| csv_transactions.csv | 2,38 MB | 361,4 KB (Brotli) | 2,62 KB | 99,3% ganhos |
| csv_server_logs.csv | 4,20 MB | 428,2 KB (Brotli) | 3,04 KB | 99,3% ganhos |
| csv_orders.csv | 2,92 MB | 210,3 KB (Brotli) | 3,05 KB | 98,6% ganhos |
| svg_scatter_20k.svg | 970 KB | 110,7 KB (GZip) | 2,16 KB | 97,9% ganhos |
| svg_network_10k.svg | 1,60 MB | 206,2 KB (Brotli) | 2,73 KB | 98,7% ganhos |
| svg_heatmap_20k.svg | 1,16 MB | 59,8 KB (Brotli) | 2,40 KB | 96,0% ganhos |

*Os valores exatos variam minimamente por versão do .NET, mas o veredicto SHA-256 é absoluto e invariante.*

---

## Por Que Funciona

O princípio é simples: dados **estruturados e gerados por procedimentos** não precisam ser armazenados como bytes — eles podem ser armazenados como **o procedimento que os gerou**.

- Um CSV com 80.000 linhas onde `id` vai de 1 a 80.000 → armazene `{"start":1,"step":1}`, não 80.000 valores.
- Um timestamp que avança 30 segundos a cada linha → armazene `{"base":"2024-01-01","step_sec":30}`, não 80.000 strings de data.
- Coordenadas SVG geradas por uma função congruencial → armazene os 4 parâmetros da função, não 20.000 pares de floats.

A TEIA chama isso de **armazenamento ontoprocedural**: o código IS o dado.

---

## Limitações (Honestidade Claim-Safe)

A TEIA **não** é uma solução universal de compressão:

- **Dados verdadeiramente aleatórios** (ruído, criptografia, imagens naturais) não têm estrutura procedural detectável — a TEIA não obtém ganhos sobre esses dados.
- **Dados parcialmente estruturados** (logs reais com IPs variáveis, CSVs com campos mistos) podem exigir compressão híbrida: P1 AutoSynth para campos estruturados + Brotli para entropia residual.
- Os resultados desta demo usam dados **sintéticos e perfeitamente estruturados** como prova de conceito. A próxima fase (P19/P20) aplica os motores a dados reais.

---

## Auditoria Independente

O manifesto técnico completo com hashes SHA-256, tamanhos de seed/decoder e análise da prova de reprodutibilidade P18 está em `docs/TEIA_P18_CLAIM_SAFE_AUDIT.md`.

Para verificar manualmente um único decoder:

```powershell
# Exemplo: reconstruir json_api_events.json manualmente
.\decoders\Decode-json_api_events.ps1 `
    -SeedFile   .\seeds\seed_json_api_events.json `
    -OutputFile .\json_api_events_REBUILT.json

# Verificar SHA-256
(Get-FileHash .\json_api_events_REBUILT.json -Algorithm SHA256).Hash
# Deve ser: b0836bd4c35f74b4b7ab576c7d26990dba762d16f9d6a26fcba0403130e0d3af
```

---

*TEIA — Transcendência Epistêmica Integrada Autossintetizante*  
*Protocolo P19.0 | 2026-06-01*
