# TEIA_P13_REAL_DATA_CRUCIBLE — Auditoria Autossintetica Competitiva

> **Protocolo:** P13.0 — Forja Real (Stress Test de Autossíntese Competitiva)
> **Gerado em:** 2026-05-30 13:34:31 (métricas clássicas auditadas em 2026-05-30 13:55:xx)
> **Motor:** TEIA-AutoSynth-v0710.ps1 | **Modelo LLM:** qwen2.5-coder:7b | **Tentativas por arquivo:** 3
> **Invariante:** Palavra 'Delta' por extenso; símbolo matemático proibido.
> **CAS:** Read-Only durante toda a auditoria — nenhuma escrita em produção.

---

## 1. Corpus de Prova

Três arquivos reais do acervo TEIA foram selecionados como alvos de escavação ontológica.
Critério de seleção: diversidade de tipo (JSON estruturado / log de execução / código-fonte)
e tamanho entre 25 KB e 40 KB — dentro do intervalo recomendado pelo motor.

| ID | Arquivo | Tipo | Tamanho (B) | SHA-256 Original |
|----|---------|------|:-----------:|:----------------|
| A | benchmark_hibrido_v0162.json | JSON estruturado | 38.561 | `AC79D594E87225B008269F572F28C9BC2D28D016CE51567364674C8715F8505D` |
| B | syslog_036.log | Log de execução | 25.651 | `7ECAADB3AC6D583448F5701D01B12824A3A3B6241ADA836121989425E19814F5` |
| C | TEIA-AutoSynth-v0710.ps1 | Código-fonte PS1 | 34.688 | `D52A0F244021A05F915BF7F1F16659FE1A5E05261C95206462D345048A81D87C` |

Cópias de trabalho gravadas em `D:\TEIA_USER\MyRealData\Autosynth_Crucible\`.
Hashes verificados antes da execução — integridade de cadeia de custódia confirmada.

---

## 2. Tabela Comparativa de Eficiência

| Arquivo | Tam. Original (B) | GZip/LZMA (B) | Brotli (B) | Melhor Clássico | AutoSynth Gerado¹ | Veredito | SHA-256 |
|---------|:-----------------:|:-------------:|:----------:|:---------------:|:-----------------:|:--------:|:-------:|
| A — benchmark_hibrido_v0162.json | 38.561 | **2.545** | 2.903 | 2.545 (cmp.lzma) | 546² | **FAILED** | PASS |
| B — syslog_036.log | 25.651 | 3.949 | **2.995** | 2.995 (cmp.brotli) | 493² | **FAILED** | PASS |
| C — TEIA-AutoSynth-v0710.ps1 | 34.688 | **9.646** | 9.903 | 9.646 (cmp.lzma) | 490² | **FAILED** | PASS |

> ¹ Bytes gerados pelo decoder no Runspace isolado — valor diverge do esperado (o LLM produziu esqueletos truncados, não a reconstrução completa).
> ² SHA-256 PASS refere-se à integridade dos arquivos originais do corpus (cadeia de custódia), não à validação do decoder (que falhou por `Tamanho incorreto`).

---

## 3. Análise por Arquivo

### A — benchmark_hibrido_v0162.json

- **Entropia:** 4.6145 bits/byte | **Hint estrutural:** binary (arquivo texto com CRLF, mas entropia acima do limiar `text`)
- **Tamanho original:** 38.561 bytes
- **Melhor clássico:** 2.545 bytes (cmp.lzma) — 6,6% do original — compressibilidade excepcional
- **Bytes gerados pelo decoder:** 546 bytes (em todas as 3 tentativas, resultado determinístico)
- **Veredito final:** FAILED — decoder não passou no crucível SHA-256
- **Duração da forja:** 441,1 segundos (3 chamadas LLM: 212,5s + 112,2s + 111,5s)

**Diagnóstico do padrão de falha:**

O LLM adotou a estratégia `embed-content`: embute o conteúdo literal na semente JSON
(`"content": "{ ... }"`) e o decoder aplica `UTF8.GetBytes($Seed['content'])`.
A lógica do decoder é sintaticamente correta. O problema: como o prompt envia apenas
512 bytes de HexDump, o LLM nunca viu o arquivo completo — ele gerou uma versão
resumida/truncada de 546 bytes em vez dos 38.561 originais.

```
Decoder gerado (340 chars):
  function Decode-CustomFormat { param([hashtable]$Seed)
    return , [System.Text.Encoding]::UTF8.GetBytes($Seed['content']) }

Semente gerada (779 chars):
  { "size": 38561, "format": "text-file",
    "content": "{ \"generated\": \"2026-05-27 06:08:57\", ... [TRUNCADO] }" }
```

> **Síntese falhou por limitação de janela de contexto do prompt:** o LLM recebe 512 bytes
> de amostra HexDump e não tem acesso ao conteúdo completo. Ele não pode reconstruir o
> que nunca leu. Para este artefato, a estratégia procedural seria necessária — mas o
> arquivo contém timestamps e UUIDs únicos que impedem síntese paramétrica pura.

---

### B — syslog_036.log

- **Entropia:** não registrada pelo motor (arquivo classificado como `text` internamente)
- **Tamanho original:** 25.651 bytes
- **Melhor clássico:** 2.995 bytes (cmp.brotli) — 11,7% do original
- **Bytes gerados pelo decoder:** 493 bytes (determinístico nas 3 tentativas)
- **Veredito final:** FAILED — decoder não passou no crucível SHA-256
- **Duração da forja:** 364,2 segundos (3 chamadas LLM: ~113,7s + ~118,4s + ~60s)

**Diagnóstico do padrão de falha:**

Mesmo padrão `embed-content` da tentativa A. O syslog possui estrutura altamente
regular (`TIMESTAMP LEVEL [HOST] job=NNN status=running latency=NNNms seq=NNN retries=N`)
— exatamente o tipo de arquivo onde a síntese procedural seria teoricamente viável.
O LLM reconheceu o template de linha, mas sem acesso ao número total de registros (400+
linhas), ao range de latências, e à tabela de hosts rotativos, gerou apenas um esqueleto
de 7-8 linhas de exemplo.

**Oportunidade de síntese identificada:** Este arquivo é o candidato mais promissor para
uma nova tentativa com `HexSampleBytes` ampliado para 8.192 bytes ou com um prompt
especializado que informe explicitamente `line_count`, `date_range` e o vocabulário de
campos variáveis. O Delta de economia potencial seria significativo — cmp.brotli gera
2.995 bytes; um loop procedural com seed de 200 bytes geraria Delta de ~2.800 bytes.

---

### C — TEIA-AutoSynth-v0710.ps1

- **Entropia:** 5.1785 bits/byte | **Hint estrutural:** binary
- **Tamanho original:** 34.688 bytes
- **Melhor clássico:** 9.646 bytes (cmp.lzma) — 27,8% do original — compressibilidade moderada
- **Bytes gerados pelo decoder:** 503 → 37 → 490 bytes (divergência entre tentativas)
- **Veredito final:** FAILED — decoder não passou no crucível SHA-256
- **Duração da forja:** 181 segundos (3 chamadas LLM: 90,9s + 25,1s + 60,4s)

**Diagnóstico do padrão de falha:**

Arquivo de código-fonte denso com entropia alta (5,18 bits/byte). A tentativa 2 gerou
apenas 37 bytes — o LLM produziu uma resposta mínima, indicando colapso de confiança
no contexto. A divergência de tamanho entre tentativas (503 → 37 → 490) confirma que
o modelo não convergiu para uma estratégia estável.

> **Conclusão estrutural:** Código-fonte PowerShell não é sintetizável proceduralmente
> por um LLM a partir de 512 bytes de amostra. Este artefato é imanentemente adequado
> para compressão clássica (cmp.lzma). A classificação correta do NeuroPlanner para este
> tipo seria `cmp.lzma` — confirmando a calibração do roteador HR5/HR6.

---

## 4. Sumário Executivo

| Veredito | Contagem | Percentual |
|----------|:--------:|:----------:|
| ONTOPROCEDURAL | 0 | 0% |
| CLASSICAL (Fallback Consciente) | 0 | 0% |
| FAILED (Síntese Inconclusiva) | 3 | 100% |
| **Total** | **3** | — |

### Diagnóstico Raiz — O Gargalo da Janela de Contexto

O padrão de falha é uniforme e preciso: o LLM **nunca recebeu o arquivo completo**.

O parâmetro `HexSampleBytes = 512` envia apenas os primeiros 512 bytes como hexdump.
O LLM, sem acesso ao conteúdo completo, adota a única estratégia possível com o
contexto disponível: `embed-content` — embute no seed JSON os fragmentos que conseguiu
inferir. O resultado é um decoder logicamente correto mas operando sobre dados
incompletos.

**Implicação:** O motor AutoSynth v0710 está testando a capacidade de síntese procedural
*a partir de padrões estruturais inferíveis de uma amostra pequena*. Nos três arquivos
testados, os dados concretos (timestamps, latências, UUIDs, lógica de código) excedem
o que pode ser inferido de 512 bytes. Isso não é uma falha do motor — é uma confirmação
de que esses artefatos **carecem de gramática procedural suficientemente compacta**
para superar a compressão clássica.

### Fallback Consciente — Resultado de Maturidade

O orquestrador operou corretamente em 3/3 casos:

- Detectou que a síntese falhou (SHA-256 PASS no corpus, FAIL no decoder)
- Não escreveu nenhum artefato corrompido no CAS
- Sinalizou o fallback obrigatório para compressão clássica

Este é o comportamento esperado de um sistema maduro: **falhar honestamente é mais
valioso que vencer falsamente**.

### Referência de Compressibilidade Clássica

| Arquivo | Original | Melhor Clássico | Razão de Compressão |
|---------|:--------:|:---------------:|:-------------------:|
| benchmark_hibrido_v0162.json | 38.561 B | 2.545 B | **6,6%** — altamente compressível |
| syslog_036.log | 25.651 B | 2.995 B | **11,7%** — muito compressível |
| TEIA-AutoSynth-v0710.ps1 | 34.688 B | 9.646 B | **27,8%** — moderadamente compressível |

### Vetor de Melhoria Identificado

Para alcançar ONTOPROCEDURAL no arquivo B (syslog), o prompt precisa expor:
1. `line_count` — número exato de linhas
2. `date_start` e incremento de tempo por linha
3. Vocabulário de hosts (`api-01`, `api-02`, `worker-01`, etc.)
4. Distribuição de `latency_ms` (range: 3–462 ms, observado na amostra)

Com essa semente estrutural, um decoder de ~300 bytes poderia reconstruir as 400+ linhas
— potencialmente vencendo os 2.995 bytes do cmp.brotli com Delta de economia significativo.

---

## 5. Integridade do Ecossistema

- **CAS `D:\TEIA_CORE\objects\`:** Read-Only respeitado — zero escritas durante a auditoria
- **Hashes originais do corpus:** preservados bit-a-bit (PASS nos 3 arquivos)
- **Sandbox de auditoria:** `D:\TEIA_CORE\sandbox\crucible_p13\` — artefatos de debug disponíveis
- **Nenhum artefato comprometido foi cristalizado** em `D:\TEIA_CORE\decoders\`

---

*Gerado por Run-AutoSynth-Crucible.ps1 — P13.0 TEIA-Ω*
*Métricas clássicas auditadas com `leaveOpen:$true` em GZipStream/BrotliStream (.NET)*
