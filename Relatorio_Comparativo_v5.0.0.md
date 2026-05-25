# Relatorio Comparativo v5.0.0 — TEIA Formato Binario .teia vs LZMA

> **Gerado**: 2026-05-25T11:14:40Z  
> **Motor**: TEIA-Core-v0.8.0.psm1 | SHA-256: 71DABD27742B534E11C334613CDDE6D469B10E5EBBB0BF4B652E84DF8D801536 | 18580 bytes  
> **Dicionario Zstd**: 6c72ae7246b413b8b635078167da4d5786276435fea3cd140326197744562d8a | 80055 bytes  
> **Hardware**: i3-10100F, 16GB RAM, HDD  
> **Integridade**: Write==Read verificado | SHA-256 throw+rollback em divergencia

---

## Formato Binario .teia

Estrutura do arquivo .teia (v0.8):

```
Offset  Tamanho  Campo
0       4B       Magic: 54 45 49 41 ('TEIA')
4       2B       ver_major LE uint16: 0x00 0x00
6       2B       ver_minor LE uint16: 0x08 0x00
8       4B       manifest_len LE uint32: N
12      N bytes  Manifest JSON UTF-8 (name,sha256,size,op,dict_sha256,dict_size,zstd_level)
12+N    M bytes  Payload: bytes Zstd comprimidos (RAW - sem Base64)
```

Overhead total = 12B header + N bytes manifest JSON (sem Base64).
vs v0.7.0 JSON+Base64: overhead era ~6700 bytes por arquivo.

---

## Corpus — Treinamento vs Teste (separados)

| # | Treinamento (botocore, exclui cloudfront) | Tamanho |
|---|------------------------------------------|---------|
| 1 | kinesisanalyticsv2 | 202197 bytes |
| 2 | elastictranscoder | 201124 bytes |
| 3 | ds | 200275 bytes |
| 4 | elbv2 | 199319 bytes |
| 5 | application-autoscaling | 198376 bytes |
| 6 | stepfunctions | 195993 bytes |
| 7 | elasticbeanstalk | 194813 bytes |
| 8 | iotfleetwise | 194634 bytes |

| ID | Teste (cloudfront — nao visto no treino) | Tamanho | SHA-256 (16 chars) |
|----|------------------------------------------|---------|-------------------|
| T1 | cloudfront/2016-11-25 (R29) | 197970 bytes | 0bd66636938ddfbc... |
| T2 | cloudfront/2016-09-29 (R35) | 194806 bytes | eb98854f0ccbcc18... |

---

## Resultados — 4 Cenarios por Arquivo

| ID | Original | A: LZMA | B: Zstd | C: Zstd+Dict raw | D: TEIA .teia |
|----|----------|---------|---------|------------------|---------------|
| T1 | 197970 B | 21228 B (10.72%) | 20880 B (10.55%) | 19386 B (9.79%) | 19658 B (9.93%) |
| T2 | 194806 B | 20930 B (10.74%) | 20573 B (10.56%) | 19104 B (9.81%) | 19376 B (9.95%) |

| ID | Tempo A | Tempo B | Tempo C | Encode D | Restore D | Write==Read | SHA-256 D | TEIA ganha |
|----|---------|---------|---------|----------|-----------|-------------|-----------|-----------|
| T1 | 53ms | 118ms | 88ms | 123ms | 74ms | OK | OK | **Sim** |
| T2 | 51ms | 121ms | 87ms | 108ms | 71ms | OK | OK | **Sim** |

---

## Atribuicao — De Onde Vem o Ganho

| ID | B-A (Zstd vs LZMA) | C-B (ganho dict) | C-A (Zstd+dict vs LZMA) | D-C (overhead TEIA) | D-A (liquido TEIA vs LZMA) |
|----|-------------------|-----------------|------------------------|---------------------|---------------------------|
| T1 | -348 B | -1494 B | -1842 B | 272 B (0.1374%) | -1570 B (-0.79%) |
| T2 | -357 B | -1469 B | -1826 B | 272 B (0.1396%) | -1554 B (-0.8%) |

**Leitura da atribuicao**:
- **B-A**: quanto Zstd -19 sozinho ganha (ou perde) sobre LZMA
- **C-B**: quanto o dicionario treinado acrescenta ao Zstd (isolado)
- **C-A**: ganho total de compressao bruta (Zstd+dict) sobre LZMA
- **D-C**: overhead container TEIA = 12B header + manifest JSON (sem Base64)
- **D-A**: resultado liquido TEIA vs LZMA, incluindo toda a camada de orquestracao

**Valor da orquestracao TEIA (alem da compressao bruta)**:
- SHA-256 verificado bit a bit em cada restauracao
- Idempotencia absoluta: seed determinista producao o mesmo resultado em qualquer hardware
- Auditabilidade: manifest JSON legivel sem o motor
- Ciclo completo Write==Read verificado: encode -> disco -> restaurar -> SHA-256

---

## Decomposicao do Overhead .teia

| ID | Payload raw (C) | Header .teia | Manifest JSON | Total overhead D-C | % do original |
|----|----------------|-------------|---------------|--------------------|---------------|
| T1 | 19386 B | 12 B | 260 B | 272 B | 0.1374% |
| T2 | 19104 B | 12 B | 260 B | 272 B | 0.1396% |

---

## Calculo Break-even N

Formula: N_break_even = teto( (motor_bytes + dict_bytes) / (A_bytes - D_bytes) )

Custo fixo: motor TEIA-Core-v0.8.0 = 18580 bytes + dict Zstd = 80055 bytes = **98635 bytes total**.

| ID | Savings por arquivo (A-D) | N Break-even | Interpretacao |
|----|--------------------------|--------------|---------------|
| T1 | 1570 B | 63 | A partir de 63 arquivos do mesmo corpus, motor+dict amortizam |
| T2 | 1554 B | 64 | A partir de 64 arquivos do mesmo corpus, motor+dict amortizam |

---

## Criterios de Sucesso v0.8

| Criterio | Definicao | Resultado |
|----------|-----------|-----------|
| 1 | TEIA .teia overhead < 1% do arquivo original | **PASS** |
| 2 | TEIA .teia vence LZMA standalone no corpus de teste | **PASS** |
| 3 | SHA-256 passa em 100% dos restores | **PASS** |
| 4 | Treino e teste permaneceram separados | **PASS** |

**T1 (cloudfront/2016-11-25 (R29))**: C1=OK (overhead=0.1374%) | C2=OK (delta=-0.79%) | C3=OK

**T2 (cloudfront/2016-09-29 (R35))**: C1=OK (overhead=0.1396%) | C2=OK (delta=-0.8%) | C3=OK

### SUCESSO TECNICO v0.8: todos os criterios satisfeitos

---

## Comparativo v0.7.0 (JSON+Base64) vs v0.8.0 (Binario)

| Aspecto | v0.7.0 (.teia JSON+Base64) | v0.8.0 (.teia binario) | Reducao |
|---------|--------------------------|------------------------|---------|
| Formato seed | JSON + payload Base64 | Binario: header+manifest+payload | - |
| Seed T1 | 26144 B (10.72% seria referencia) | 19658 B (9.93%) | -6486 B (-24.8%) |
| Seed T2 | 25768 B (10.74% seria referencia) | 19376 B (9.95%) | -6392 B (-24.8%) |
| Overhead vs Zstd+dict | ~6700 B (~3.4% orig) | ~257 B (~0.13% orig) | -96% |
| TEIA ganha vs LZMA | Nao (v4.0.0: 0/2) | Sim (2/2) | - |
| SHA-256 verificado | Sim | Sim | - |
| Idempotencia | Sim | Sim | - |

---

## Conclusao

O formato binario .teia (v0.8.0) satisfaz todos os criterios de sucesso tecnico.

A binarizacao do seed eliminou o overhead Base64 de ~6700 bytes para ~257 bytes (-96%),
tornando o container TEIA transparente do ponto de vista da compressao.

TEIA .teia binario agora supera LZMA standalone mantendo:
- SHA-256 verificado bit a bit em cada restauracao
- Idempotencia absoluta: seed determinista
- Auditabilidade: manifest legivel sem o motor
- Ciclo completo: encode -> armazenar em disco -> restaurar -> SHA-256

Proximos passos: expandir o corpus de teste; implementar opcodes adicionais no formato binario.

---

*TEIA-Core v0.8.0 | Harness v5.0.0 | Felippe Barcelos | 2026-05-25T11:14:40Z*
