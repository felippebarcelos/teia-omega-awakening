# TEIA Dogfooding Protocol — Protocolo de Teste com Entropia Real
**Protocolo P38.1 | Data:** 2026-06-02
**Motor:** TEIA Adaptive Archive Router v1.0.0 + AION Transversal v2.0.0
**Modo:** Dry-Run Isolado → Auditoria → Selagem de Resultado

> *"A física da informação não negocia com hipóteses. Ela mede."*

---

## Objetivo

Submeter o Roteador Adaptativo TEIA a dados reais do ambiente de produção do operador
para confirmar (ou refutar) empiricamente as projeções de N* obtidas em corpora sintéticos.
O teste é **não-destrutivo**: nenhum arquivo original é modificado ou movido.
O motor opera em modo Dry-Run, produzindo apenas projeções de roteamento e um manifesto
JSON canônico auditável.

---

## As Três Zonas de Captura

### Zona A — Baixa Entropia / Alta Estrutura

**Definição:** Arquivos com schema repetitivo, vocabulário finito de valores, alta redundância
entre arquivos do mesmo tipo.

**Exemplos de alvos:**
- Logs de sistema: arquivos `.log`, eventos do Windows, Nginx/Apache CLF
- Scripts locais: `.ps1`, `.py`, `.js`, `.ts`, `.sh` — código-fonte com padrões repetitivos
- Configurações: `.json`, `.yaml`, `.yml`, `.toml`, `.ini`, `.conf`, `.xml`
- Históricos de chat: arquivos de conversação exportados (CSV, JSON, TXT)
- Dados tabulares estruturados: `.csv`, `.tsv` com schema uniforme

**Hipótese de roteamento:** TEIA para grupos N >= N* (esperado N* baixo: 5–20);
Brotli individual para grupos menores.

**Métricas-alvo:**
- Economia de disco (bytes originais menos bytes TEIA) por extensão
- N* real medido vs. N* projetado pelo Roteador
- Percentual de grupos que atingem N* com o N disponível no diretório

---

### Zona B — Entropia Média

**Definição:** Arquivos com estrutura presente mas vocabulário mais amplo; maior variação
entre arquivos do mesmo tipo.

**Exemplos de alvos:**
- Repositórios de código ativos: projetos com múltiplos arquivos `.cs`, `.go`, `.rs`, `.java`
- Bases de dados textuais: arquivos SQLite exportados como CSV, dumps de tabelas
- Documentação técnica: Markdown, RST, HTML com templates repetitivos
- Dados de telemetria semi-estruturada: métricas de séries temporais com campos mistos

**Hipótese de roteamento:** Brotli individual para N < N*; TEIA para grupos grandes (N > 20).
Pass-through para arquivos isolados sem grupo homogêneo.

**Métricas-alvo:**
- Distribuição de N* por tipo de arquivo
- Razão entre colunas dicionarizáveis e colunas residuais por schema detectado

---

### Zona C — Alta Entropia / Pass-Through Obrigatório

**Definição:** Arquivos incompressíveis por natureza (já comprimidos, binários aleatórios)
ou onde a decodificação requereria overhead inaceitável sem ganho de disco.

**Exemplos de alvos:**
- Binários opacos: `.exe`, `.dll`, `.so`, `.wasm`, `.pyc`, `.class`
- Arquivos já comprimidos: `.zip`, `.gz`, `.br`, `.7z`, `.rar`, `.tar`
- Mídia pesada: `.jpg`, `.png`, `.mp4`, `.avi`, `.mov`, `.mp3`, `.flac`, `.psd`, `.ai`
- Projetos de edição audiovisual: camadas PSD, projetos Premiere/DaVinci, caches de render

**Invariante inviolável:** O Roteador NUNCA aplica TEIA ou Brotli sobre Zona C.
Pass-through é o veredito correto — comprimir já-comprimido desperdiça CPU e
frequentemente AUMENTA o tamanho. A integridade do dado original é preservada sem overhead.

**Métricas-alvo:**
- Percentual do diretório alvo ocupado por Zona C (indica o teto de economia possível)
- Confirmação de que zero arquivos Zona C receberam roteamento TEIA ou Brotli

---

## Critérios de Roteamento por Zona

| Zona | Tipo | N disponível | Decisão do Roteador |
|---|---|:---:|---|
| A | CSV/log schema uniforme | >= N* | **TEIA** |
| A | CSV/log schema uniforme | < N* | **Brotli** |
| A | Texto sem schema CSV | qualquer | **Brotli** |
| B | Código-fonte, doc | qualquer | **Brotli** |
| B | CSV schema uniforme | >= N* | **TEIA** |
| C | Binário / mídia / já comprimido | qualquer | **Pass-through** |

---

## Métricas Obrigatórias de Registro

Cada execução do `Run-TeiaRealWorldAudit.ps1` deve registrar no manifesto JSON:

| Métrica | Unidade | Fonte |
|---|---|---|
| `projected_savings_bytes` | bytes | SizeBytes['TEIA'] ou SizeBytes['Brotli'] vs original |
| `n_star` | inteiro | ceil(overhead / delta_por_arquivo) |
| `dict_density_pct` | inteiro 0–100 | colunas_dict / colunas_total x 100 |
| `dict_cols` | lista CSV | colunas com cardinalidade <= threshold |
| `routing_decision` | enum | TEIA / Brotli / PassThrough |
| `file_count_in_group` | inteiro | N do grupo de schema uniforme |
| `zone` | A / B / C | classificação entrópica do arquivo |

**Economia de disco:** `projected_savings_bytes = tamanho_original - tamanho_projetado`
Se positivo: motor economiza. Se negativo: motor é honesto (Pass-through vence).

**Latência de acesso real vs. JIT warmup:**
- TEIA: acesso O(1) por arquivo após JIT warmup (~200 ms por sessão, amortizado em N)
- Brotli: acesso O(1) por arquivo, sem warmup
- Latência efetiva TEIA = `warmup_ms / N + access_per_file_ms`
- Para N > 100: warmup amortizado torna TEIA competitivo mesmo com overhead inicial

---

## Período de Teste Isolado — Regras de Quarentena

1. **Sem modificações no alvo:** O operador não deve adicionar, remover ou modificar
   arquivos no diretório alvo entre a execução T1 e a execução T2 do audit.

2. **Re-execução de verificação:** Executar `Run-TeiaRealWorldAudit.ps1` duas vezes
   consecutivas sobre o mesmo diretório. O SHA-256 do `teia_realworld_audit_state.json`
   deve ser idêntico nas duas execuções.

3. **Registro de divergências:** Se o SHA-256 divergir entre execuções sobre o mesmo
   diretório inalterado, o comportamento é um bug reportável — não uma falha do corpus.

4. **Isolamento de Zona C:** Nunca misturar arquivos Zona C no mesmo diretório alvo
   de um teste TEIA/Brotli. Zonas C reduzem a densidade dict do corpus e inflariam N*.

5. **Tamanho mínimo do grupo:** Para invocar o Roteador real (não heurístico),
   o grupo deve ter >= 5 arquivos CSV com schema idêntico.

---

## Fluxo de Execução em 3 Passos

```
Passo 1 — Escaneamento
  Run-TeiaRealWorldAudit.ps1 -TargetDirectory "D:\meus_logs"
  → Classifica todos os arquivos em Zona A / B / C
  → Agrupa CSVs por schema (hash do header)
  → Gera projeções de roteamento

Passo 2 — Análise do Manifesto
  Abrir teia_realworld_audit_state.json
  → Verificar routing_projection.TEIA.projected_savings_bytes
  → Verificar grupos com n_star [ATINGIDO]
  → Confirmar que Zona C teve 0 roteamentos TEIA/Brotli

Passo 3 — Verificação de Idempotência
  Executar novamente sem modificar o diretório
  → Comparar SHA-256 do manifesto: deve ser idêntico
  → Se idêntico: teste de Caos Real pode prosseguir com confiança
```

---

## Invariantes do Motor Durante o Dogfooding

| Invariante | Verificação |
|---|---|
| SHA-256 Write==Read | `routing_decision == 'TEIA'` implica que `projected_teia_size_bytes` vem de medição real com Brotli SmallestSize, não estimativa |
| Honestidade Entrópica | Zona C nunca recebe roteamento TEIA ou Brotli |
| Idempotência do Manifesto | SHA-256 do JSON idêntico entre execuções sobre diretório inalterado |
| Delta por extenso | Toda referência a diferença de bytes usa a palavra "delta" — nunca o símbolo grego |
| Paths absolutos | Todos os caminhos no manifesto são absolutos e canônicos |

---

## Critério de Selamento

O teste de Dogfooding é selado quando:

1. Ao menos 3 diretórios reais foram auditados (um por zona)
2. Em pelo menos 1 diretório Zona A: N* foi atingido por um grupo CSV real
3. A idempotência do manifesto foi verificada em todos os diretórios
4. O relatório de economia projetada foi revisado pelo operador

Após o selamento, os resultados são registrados em `TEIA_RESEARCH_FRONTIER.md`
como validação empírica adicional de H-01 (Densidade Dict vs. N*).

---

*TEIA Dogfooding Protocol v1.0 | P38.1 | 2026-06-02*
