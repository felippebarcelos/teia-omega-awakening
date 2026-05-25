# Relatorio Comparativo v4.0.0 — TEIA dict.zstd_shared vs LZMA

> **Gerado**: 2026-05-25T10:54:17Z  
> **Motor**: TEIA-Core-v0.7.0.psm1 | SHA-256: 1883B447A7B75FE876FAFB1704EA06FF1695B244916925ADA77F8D37B7CC1206 | 37483 bytes  
> **Dicionario Zstd**: 6c72ae7246b413b8b635078167da4d5786276435fea3cd140326197744562d8a | 80055 bytes | treinado em 8 arquivos em 223ms  
> **Hardware**: i3-10100F, 16GB RAM, HDD  
> **Integridade**: Write==Read verificado | SHA-256 throw+rollback em divergencia

---

## Corpus

### Treinamento (8 arquivos service-2.json botocore — nao incluem cloudfront)

| # | Servico | Tamanho |
|---|---------|---------|
| 1 | kinesisanalyticsv2 | 202197 bytes |
| 2 | elastictranscoder | 201124 bytes |
| 3 | ds | 200275 bytes |
| 4 | elbv2 | 199319 bytes |
| 5 | application-autoscaling | 198376 bytes |
| 6 | stepfunctions | 195993 bytes |
| 7 | elasticbeanstalk | 194813 bytes |
| 8 | iotfleetwise | 194634 bytes |

### Teste (cloudfront service-2.json — nao visto no treinamento)

| ID | Label | Tamanho Original | SHA-256 (primeiros 16) |
|----|-------|-----------------|------------------------|
| T1 | cloudfront/2016-11-25 (R29) | 197970 bytes | 0bd66636938ddfbc... |
| T2 | cloudfront/2016-09-29 (R35) | 194806 bytes | eb98854f0ccbcc18... |

---

## Resultados — 4 Cenarios por Arquivo

| ID | Original | A: LZMA | B: Zstd | C: Zstd+Dict | D: TEIA |
|----|----------|---------|---------|--------------|---------|
| T1 | 197970 B | 21228 B (10.72%) | 20880 B (10.55%) | 19386 B (9.79%) | 26144 B (13.21%) |
| T2 | 194806 B | 20930 B (10.74%) | 20573 B (10.56%) | 19104 B (9.81%) | 25768 B (13.23%) |

| ID | Tempo A | Tempo B | Tempo C | Tempo D | SHA-256 TEIA | TEIA ganha vs LZMA |
|----|---------|---------|---------|---------|--------------|-------------------|
| T1 | 140ms | 114ms | 87ms | 99ms | OK | Nao |
| T2 | 48ms | 116ms | 102ms | 98ms | OK | Nao |

---

## Contribuicao e Overhead da Orquestracao TEIA

A diferenca D - C mede o custo exato da camada TEIA sobre o Zstd+dict puro:
Base64 encoding (+33% sobre payload comprimido) + envelope JSON (struct ~300 bytes).

| ID | Zstd+Dict puro (C) | Seed TEIA (D) | Overhead D-C | Overhead D-C (% orig) |
|----|-------------------|---------------|--------------|----------------------|
| T1 | 19386 B | 26144 B | 6758 B | 3.41% |
| T2 | 19104 B | 25768 B | 6664 B | 3.42% |

**Decomposicao do overhead**:

- **T1**: payload raw=19386 B | Base64 overhead (est)=+6463 B | JSON struct overhead (est)=+295 B
- **T2**: payload raw=19104 B | Base64 overhead (est)=+6369 B | JSON struct overhead (est)=+295 B

---

## Calculo Break-even N

Formula: N_break_even = teto( (motor_bytes + dict_bytes) / (A_bytes - D_bytes) )

Custo fixo amortizavel: motor TEIA-Core-v0.7.0 = 37483 bytes + dicionario Zstd = 80055 bytes = **117538 bytes total**.

| ID | Savings por arquivo (A-D) | N Break-even | Interpretacao |
|----|--------------------------|--------------|---------------|
| T1 | -4916 B | N/A | TEIA nao supera LZMA neste arquivo — break-even indefinido |
| T2 | -4838 B | N/A | TEIA nao supera LZMA neste arquivo — break-even indefinido |

---

## Diagnostico Tecnico

| Aspecto | Observacao |
|---------|-----------|
| Cenario B vs A | Zstd -19 standalone vs LZMA: compara algoritmos sem dict |
| Cenario C vs B | Ganho real do dicionario Zstd treinado sobre Zstd standalone |
| Cenario C vs A | Zstd+dict vs LZMA: compressao bruta, sem overhead TEIA |
| Cenario D vs C | Overhead puro da orquestracao TEIA (Base64 + JSON) |
| Cenario D vs A | Resultado liquido TEIA vs LZMA incluindo toda a camada |
| Write==Read | Cada restauracao TEIA verifica SHA-256 bit a bit; divergencia = throw+rollback |
| Retrocompatibilidade | Motor v0.7.0 preserva todos os opcodes v0.6.3 |

---

## Conclusao

TEIA dict.zstd_shared (Cenario D) nao supera LZMA standalone em nenhum dos 2 arquivo(s) testado(s).

O overhead da camada de orquestracao TEIA (Base64 +33% + JSON ~300 bytes) excede o ganho
do dicionario Zstd treinado sobre LZMA para este corpus.

**Valor da orquestracao TEIA (independente da taxa de compressao bruta)**:

- SHA-256 verificado bit a bit em cada restauracao (cenario D: Write==Read confirmado)
- Idempotencia absoluta: seed determinista producao o mesmo resultado em qualquer hardware
- Opcodes compostos: futuras combinacoes (dict.zstd_shared + xform.xor, etc.)
- Auditabilidade: seed JSON auditavel de forma independente do motor

**Caminho para igualar LZMA**: eliminar Base64 — armazenar payload como bytes binarios
em formato de seed binario (roadmap v0.8.0). Reducao estimada: -33% no tamanho do seed,
eliminando o overhead principal e tornando Cenario D competitivo com Cenario C.

---

*TEIA-Core v0.7.0 | Harness v4.0.0 | Felippe Barcelos | 2026-05-25T10:54:17Z*
