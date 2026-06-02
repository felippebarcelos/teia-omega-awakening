# TEIA AION Gatekeeper v4.0.0 — Pacote de Auditoria

**Motor:** AION RISPA NDC v4.0.0  
**Protocolo:** P32.0 — Release Gatekeeper  
**Claim:** 0 Deltas negativos — recuo autonomo garante que TEIA nunca perde para Brotli

---

## Pre-requisito

PowerShell 7+ (`pwsh`). Sem outras dependencias.

```
pwsh --version   # deve ser >= 7.0
```

Conexao com a internet necessaria apenas se o dataset COVID nao estiver presente
(o script baixa automaticamente 3 amostras representativas).

---

## Execucao em 1 comando

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Run-Corpus10-Harness.ps1
```

O script:
1. Verifica se o Corpus30 canônico existe em `D:\TEIA_USER\MyRealData\Corpus30`
2. Se nao existir, baixa 3 amostras representativas (COVID CSV 5 MB, Iris CSV 4 KB, GDP CSV 549 KB)
3. Executa o Motor AION v4.0.0 com Oraculo Gatekeeper em cada arquivo
4. Registra veredito, Delta e SHA-256 por arquivo
5. Escreve `TEIA_GATEKEEPER_REPORT_P31.md` com os resultados

**Tempo esperado:** 60-90 s (inclui download do COVID CSV ~5 MB e forja ~58 s).

---

## Resultado esperado

```
csv_co2_global.csv          -> Recuo Seguro (Massa Insuficiente)
csv_covid_countries_agg.csv -> Forja PASS | SHA-256 PASS | Delta 26330 bytes
csv_gdp.csv                 -> Recuo Seguro (Entropia Dominante)
csv_iris.csv                -> Recuo Seguro (Massa Insuficiente)

Deltas negativos: 0
SHA-256 PASS    : 1 forja(s)
```

---

## O que o Oraculo Gatekeeper faz

**Regra 1 — Massa Critica:** arquivo < 500 KB -> recuo imediato. O overhead fixo
do decodificador (~1.9 KB) anula qualquer ganho estrutural em arquivos pequenos.

**Regra 2 — Vantagem Estrutural:** antes de gravar qualquer arquivo, o motor comprime
o residuo em memoria e estima o tamanho total do seed. Se a estimativa >=
Brotli(arquivo completo), o motor recua sem desperdicar CPU em uma forja perdedora.

**Resultado:** TEIA atua apenas onde a fisica da entropia confirma vantagem procedural.

---

## Calibracao (P30.0)

Ver `TEIA_ORACLE_CALIBRATION_P30.md` para a analise que derivou os limiares de recuo.

## Resultados de referencia (P31.0)

Ver `TEIA_GATEKEEPER_REPORT_P31.md` para a matriz de evidencias completa do Corpus10.

---

*TEIA — Transcendencia Epistemica Integrada Autossintetizante*  
*v4.0.0-aion-gatekeeper | Protocolo P32.0*
