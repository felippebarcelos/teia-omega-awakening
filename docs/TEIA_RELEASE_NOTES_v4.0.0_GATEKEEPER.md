# TEIA — Release Notes v4.0.0
## AION Gatekeeper: Recuo Autonomo e Triagem de Entropia

**Data:** 2026-06-01  
**Tag Git:** `v4.0.0-aion-gatekeeper`  
**Status:** RELEASE PUBLICA

---

## Posicionamento Oficial v4.0.0

> **O AION Gatekeeper elimina definitivamente os Deltas negativos.** O motor AION RISPA NDC v4.0.0
> avalia a massa e a vantagem estrutural de cada arquivo *antes* de gastar qualquer ciclo de CPU
> em uma forja. Quando a fisica da entropia favorece o Brotli, o motor recua propositalmente e
> entrega empate — nunca uma perda.

---

## A Inovacao Central: Oraculo Gatekeeper

O Gatekeeper integra duas regras preditivas ao cabecalho de `Invoke-AionUniversal`:

### Regra 1 — Massa Critica (500 KB)

```
SE tamanho_arquivo < 500 KB:
    retorna "Recuo Seguro (Massa Insuficiente)"
    TEIA reporta empate com Brotli
    nenhum arquivo e gravado
```

**Evidencia:** em 8 de 10 arquivos do Corpus10, o overhead fixo do decodificador
(~1.9 KB) supera o ganho estrutural maximo possivel para arquivos pequenos.

### Regra 2 — Vantagem Estrutural (Estimativa em Memoria)

```
SE tamanho_arquivo >= 500 KB:
    executa analise de cardinalidade
    constroi residuo em memoria
    estima seed total = Brotli(residuo) + meta JSON + overhead decoder
    SE estimativa >= Brotli(arquivo):
        retorna "Recuo Seguro (Entropia Dominante)"
        nenhum arquivo e gravado
    SENAO:
        executa forja completa e grava seed + decoder
```

**Evidencia:** 2 arquivos (gdp.csv 549 KB, population.csv 539 KB) passam pela Regra 1
mas sao bloqueados pela Regra 2 — os dicionarios extraidos nao compensam a alta entropia
dos valores numericos residuais.

---

## Resultados do Corpus10 P31.0

| Arquivo | Tam. Original | Brotli SmallestSize | TEIA v4.0.0 | Delta | SHA-256 | Veredito |
|---|---:|---:|---:|---:|:---:|---|
| csv_co2_global.csv | 7.0 KB | 1.8 KB | 1.8 KB (Brotli) | 0 (empate) | N/A | Recuo (Massa) |
| **csv_covid_countries_agg.csv** | **5.38 MB** | **661 KB** | **635 KB** | **+26.3 KB** | **PASS** | **TEIA VENCE** |
| csv_flights.csv | 2.3 KB | 0.5 KB | 0.5 KB (Brotli) | 0 (empate) | N/A | Recuo (Massa) |
| csv_gapminder_five_year.csv | 80.2 KB | 23.8 KB | 23.8 KB (Brotli) | 0 (empate) | N/A | Recuo (Massa) |
| csv_gdp.csv | 549.6 KB | 128.1 KB | 128.1 KB (Brotli) | 0 (empate) | N/A | Recuo (Entropia) |
| csv_iris.csv | 3.8 KB | 0.6 KB | 0.6 KB (Brotli) | 0 (empate) | N/A | Recuo (Massa) |
| csv_penguins.csv | 13.2 KB | 2.2 KB | 2.2 KB (Brotli) | 0 (empate) | N/A | Recuo (Massa) |
| csv_population.csv | 539.2 KB | 72.5 KB | 72.5 KB (Brotli) | 0 (empate) | N/A | Recuo (Entropia) |
| csv_seattle_weather.csv | 47.1 KB | 9.4 KB | 9.4 KB (Brotli) | 0 (empate) | N/A | Recuo (Massa) |
| csv_titanic.csv | 55.7 KB | 5.5 KB | 5.5 KB (Brotli) | 0 (empate) | N/A | Recuo (Massa) |

**Deltas negativos: 0 / 10 — meta atingida.**  
**SHA-256 PASS: 1/1 forjas executadas.**

### Antes (P29.1) vs Depois (P31.0)

| Metrica | P29.1 (sem Gatekeeper) | P31.0 (com Gatekeeper) |
|---|:---:|:---:|
| Deltas negativos | 9/10 | **0/10** |
| TEIA VENCE | 1/10 | **1/10** |
| CPU gasto em forjas perdedoras | Sim | **Nao** |
| SHA-256 PASS | 10/10 | **1/1 forjas** |

---

## Pacote de Auditoria

| Artefato | Arquivo | SHA-256 |
|---|---|---|
| Release ZIP | `TEIA_AION_GATEKEEPER_v4.0.0.zip` | `e5109bc8b6be1d3ac5e3d7c69004029520deea70fdc155f8fbbc08b20d5e7af3` |

**Verificacao:**
```powershell
(Get-FileHash .\TEIA_AION_GATEKEEPER_v4.0.0.zip -Algorithm SHA256).Hash.ToLower()
# Esperado: e5109bc8b6be1d3ac5e3d7c69004029520deea70fdc155f8fbbc08b20d5e7af3
```

**Execucao one-click (requer internet para download do dataset COVID):**
```powershell
Expand-Archive TEIA_AION_GATEKEEPER_v4.0.0.zip
pwsh -NoProfile -ExecutionPolicy Bypass -File .\aion_gatekeeper_v4\Run-Corpus10-Harness.ps1
```

---

## Conteudo do ZIP (11.2 KB)

| Arquivo | Descricao |
|---|---|
| `TEIA-AION-Universal.ps1` | Motor AION RISPA NDC v4.0.0 com Gatekeeper |
| `Run-Corpus10-Harness.ps1` | Orquestrador one-click com fallback de download |
| `TEIA_GATEKEEPER_REPORT_P31.md` | Resultados do Corpus10 (evidencia de referencia) |
| `TEIA_ORACLE_CALIBRATION_P30.md` | Calibracao do Oraculo (derivacao dos limiares) |
| `README_DEMO.md` | Guia de execucao para o auditor externo |

---

## Historico de Protocolos desta Release

| Protocolo | Descricao | Resultado |
|---|---|---|
| P29.0 | Motor Universal v3.0.0 — forja tabular generica | PASS (covid) |
| P29.1 | Corpus10 Harness — 10 datasets reais | 10/10 SHA-256 PASS; 9 Deltas negativos |
| P30.0 | Calibracao do Oraculo — derivacao de limiares | Limiares 500 KB + estimativa de seed |
| P31.0 | Gatekeeper Implementado — Corpus10 re-testado | 0 Deltas negativos; 1 TEIA VENCE |
| P32.0 | Release Publica v4.0.0 | ESTA VERSAO |

---

## O Que Esta Versao NAO Faz

- **Nao comprime entropia arbitraria**: dados sem overhead estrutural dominante recebem Recuo Seguro.
- **Nao e um compressor universal**: GZip e Brotli comprimem qualquer coisa. TEIA vence apenas onde o overhead estrutural (N x M) excede a capacidade da janela LZ77.
- **Nao processa JSON automaticamente**: o motor v4.0.0 opera apenas em CSV tabular. JSON e outros formatos serao adicionados em versoes futuras.
- **Nao e uma ferramenta de producao**: v4.0.0 e uma prova de conceito funcional, auditavel e reprodutivel.

---

*TEIA — Transcendencia Epistemica Integrada Autossintetizante*  
*Release v4.0.0-aion-gatekeeper | 2026-06-01*
