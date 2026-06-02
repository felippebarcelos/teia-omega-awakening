# TEIA Cognitive Routing Theory
**A Ontogênese Ontoprocedural Aplicada à Inferência de IA**

**Protocolo:** P40.0
**Data:** 2026-06-02
**Versão:** 1.0

---

## Além do Armazenamento Físico

A TEIA nasceu como um motor de compressão de dados estruturados. Ela evoluiu para um
**Motor de Economia da Informação** que raciocina sobre o custo real da informação antes
de agir. A P40.0 aplica esse mesmo princípio ao plano cognitivo: o custo mais alto em
data centers modernos não é disco — é **GPU-tempo de inferência**.

> *"O mesmo Roteador que pergunta 'Vale a pena ativar o grammar TEIA para este corpus?'
> agora pergunta 'Vale a pena ativar o GPT-4 para este prompt?'"*

A transição é estrutural, não metafórica. O problema da inferência de IA é isomórfico
ao problema do arquivo TEIA:

| Dimensão | Arquivo TEIA | Inferência de IA |
|---|---|---|
| Recurso caro | Disco (bytes) | GPU-segundos |
| Overhead fixo | Grammar TEIA | Frontier LLM (GPT-4/Claude-Opus) |
| Overhead variável | Seeds por arquivo | Tokens de saída |
| Ponto de equilíbrio | N* arquivos | Entropia Semântica do prompt |
| Decisão honesta | Brotli se N < N* | SLM local se entropia < limiar |

---

## O Conceito Central: Entropia Semântica

A **Entropia Semântica** de um prompt é a medida de quanta capacidade cognitiva de
fronteira é necessária para respondê-lo com fidelidade. Ela é análoga à entropia de
coluna no modelo TEIA de armazenamento:

- Uma coluna com cardinalidade 3 (ex: `Status: OK/WARN/CRIT`) tem baixa entropia —
  o grammar TEIA a comprime de forma trivial.
- Um prompt com verbos de raciocínio denso (`analyze`, `reconcile`, `extrapolate`)
  tem alta entropia — requer capacidade de fronteira.

A diferença fundamental: **entropia de dado é mensurável por cardinalidade**; **entropia
semântica é mensurável por densidade de pistas cognitivas**.

### Os Seis Eixos da Entropia Semântica (P40.0)

```
token_score          (peso 0.20) — contexto longo demanda maior capacidade de atenção
vocab_diversity      (peso 0.15) — riqueza lexical indica sofisticação do domínio
reasoning_verb_score (peso 0.30) — principal discriminador: verbos que ativam raciocínio
data_op_score        (peso 0.15) — operações de dados puxam entropia para baixo (inverted)
structural_score     (peso 0.10) — estrutura rica indica tarefa operacionalmente complexa
constraint_score     (peso 0.10) — restrições lógicas densas indicam raciocínio condicional
```

O peso dominante (0.30) recai sobre `reasoning_verb_score` porque verbos de raciocínio
— `analyze`, `synthesize`, `reconcile`, `analisar`, `extrapolar` — são os mais confiáveis
indicadores de que um modelo de fronteira é economicamente justificado. Um script que
`lista`, `filtra` e `ordena` não justifica o overhead de um GPT-4.

---

## A Ontogênese Ontoprocedural na Inferência

### O que é Ontogênese Ontoprocedural?

No contexto TEIA de armazenamento, a Ontogênese Ontoprocedural é a geração emergente
de dados a partir de um programa (grammar + seed) em vez de bytes brutos. O dado não
é armazenado — ele **nasce** de um procedimento cada vez que é necessário.

Na inferência de IA, a analogia é direta:

- **Grammar TEIA ≡ SLM local (1-7B)**: um modelo compacto contém o "grammar" de
  domínios de baixa entropia. Respostas para extração, formatação e tradução são
  geradas localmente — sem GPU de fronteira, sem latência de rede.

- **Seed TEIA ≡ Contexto mínimo do prompt**: em vez de enviar todo o contexto ao
  Frontier LLM, o Roteador Cognitivo extrai apenas o que é necessário — o "seed"
  informacional que o modelo local não consegue resolver.

- **N* TEIA ≡ Limiar de Entropia Semântica**: assim como N* marca o ponto onde o
  overhead do grammar é amortizado, o limiar `Local=0.35` marca o ponto onde a
  capacidade de raciocínio do SLM local é suficiente.

### Três Modos de Geração Cognitiva

```
Entropia < 0.35 → LOCAL
  SLM 1-7B (CPU inference, zero GPU-seconds)
  O "grammar" local cobre o domínio.
  Exemplos: tradução simples, extração de campo, formatação de dados,
            sumarização de texto curto, busca por regex, conversão de formato.

0.35 ≤ Entropia < 0.65 → HYBRID
  Modelo quantizado 13-34B (footprint GPU reduzido, ~4-bit)
  O grammar precisava de contexto maior, mas não de capacidade de fronteira.
  Exemplos: análise de código simples, QA sobre documento, classificação
            multi-categoria, extração com raciocínio leve.

Entropia ≥ 0.65 → CLOUD
  Frontier LLM GPT-4/Claude-Opus (inferência GPU completa)
  Economicamente justificado: o raciocínio exige capacidade de fronteira.
  Exemplos: design de arquitetura, síntese multi-domínio, raciocínio legal,
            análise de código complexo, geração criativa sofisticada.
```

---

## A Economia do GPU-Tempo

O custo dominante de um data center de IA moderno é o GPU-segundo. Assim como a TEIA
demonstrou que o overhead do grammar TEIA custa `5000 bytes` fixos amortizados sobre N
arquivos, o Roteador Cognitivo demonstra que o overhead de um Frontier LLM custa
`∼USD 0.002 por GPU-segundo` amortizado sobre zero tarefas triviais que o justifiquem.

### Projeção de Economia (Honestidade Entrópica)

Para um prompt com `tokenEst` tokens de entrada:

```
output_tokens_estimate  = tokenEst × 0.5
cloud_gpu_seconds       = output_tokens / 50 tokens/s
delta_gpu_seconds_saved = cloud_gpu_seconds  (se rota != Cloud)
delta_usd_saved         = delta_gpu_seconds × USD 0.002/s
```

Este modelo é intencionalmente conservador (50 tokens/s para Cloud, 5 tokens/s para
Local) para garantir que a economia declarada seja **subestimada**, nunca inflada.
A Honestidade Entrópica exige que a projeção seja defensável — não publicitária.

### Exemplo Concreto

Um pipeline de ingestão de dados executa 10.000 prompts/hora para normalizar campos
em CSVs. Cada prompt tem ~200 tokens, verbos predominantemente operacionais (`list`,
`extract`, `convert`). Entropia Semântica típica: 0.18 → **LOCAL**.

```
delta_gpu_seconds_por_prompt = (200 × 0.5) / 50 = 2.0 s
delta_usd_por_prompt         = 2.0 × 0.002 = USD 0.004
economia_horária             = 10.000 × 0.004 = USD 40.00/hora
economia_mensal              = USD 28.800 (estimativa conservadora)
```

Este é o valor econômico concreto da Honestidade Entrópica aplicada à inferência.

---

## Invariantes do Roteador Cognitivo (P40.0)

| Invariante | Enunciado |
|---|---|
| **Sem chamadas de rede** | Toda análise é local e determinística — zero latência de API |
| **Write==Read** | Mesmo texto → mesmo JSON → mesmo SHA-256 (idempotência absoluta) |
| **Delta por extenso** | A palavra "delta" nunca é substituída pelo símbolo matemático |
| **Confiança declarada** | Proximidade aos limiares gera `low` confidence — nunca oculta |
| **Veredito conservador** | Em caso de dúvida entre Local e Hybrid, eleva para Hybrid |
| **Economia defensável** | Projeção subestimada por design — `output = input × 0.5` |

---

## Posicionamento na Arquitetura TEIA

```
┌─────────────────────────────────────────────────────────────────────┐
│  TEIA Cognitive Economics Engine (P40.0)                            │
│  Entropia Semântica → GPU-routing → Economy projection              │
│  No network · No LLM · Deterministic · Sub-millisecond              │
├─────────────────────────────────────────────────────────────────────┤
│  TEIA Information Economics Engine (P39.0)                          │
│  Heuristic N* Predictor — Data storage routing                      │
│  CSV corpus → N* → TEIA/Brotli/PassThrough                          │
├─────────────────────────────────────────────────────────────────────┤
│  TEIA Adaptive Archive Router (P36.0)                               │
│  Real compression measurement · 3 candidates × 3 objectives         │
├─────────────────────────────────────────────────────────────────────┤
│  TEIA AION Transversal Motor (P33.0)                                │
│  Master Grammar extraction + C# JIT · O(1) access                   │
└─────────────────────────────────────────────────────────────────────┘
```

A P40.0 não substitui as camadas inferiores — ela **generaliza o princípio** que as
anima. A Honestidade Entrópica é a mesma nos quatro níveis: medir o custo real,
declarar o veredito correto, nunca forçar o recurso caro quando o recurso barato
é suficiente.

---

## O Princípio Unificador

> *"Compressão de dados e inferência de IA são instâncias do mesmo problema:*
> *quanto recurso computacional é economicamente justificado para processar*
> *esta quantidade de informação?"*

A TEIA, em sua versão P40.0, responde essa pergunta tanto para bits no disco quanto
para tokens no contexto. O Roteador Cognitivo é a prova de que a arquitetura TEIA
não é uma ferramenta de compressão — é um **framework de economia da informação**
aplicável a qualquer camada onde o custo computacional pode ser racionalizado pela
medição de entropia.

O próximo passo natural (E-02, planejado): integrar um LLM local como planejador
heurístico para refinar o N* abaixo do limiar estatístico — o loop se fecha quando
a IA otimiza a otimização da IA.

---

*TEIA Cognitive Economics Engine P40.0 | 2026-06-02*
*"ferrari de papelão — eficiência de código supera limitações de silício."*
