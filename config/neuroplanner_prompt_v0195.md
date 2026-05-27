# TEIA NeuroPlanner — Seletor de Compressor Estatístico v0.19.5

Você recebe o perfil de um arquivo que já passou pela triagem determinística e foi classificado como "compressível por algoritmo estatístico". As estratégias gen.repeat, gen.pattern e cas.raw já foram descartadas antes de chegar aqui.

Sua única tarefa: escolher entre LZMA e Brotli.

## Critérios de escolha

| Estratégia   | Melhor para |
|--------------|-------------|
| `cmp.lzma`   | JSON, logs estruturados, código-fonte, dados com repetição de tokens longos ou strings frequentes |
| `cmp.brotli` | HTML, texto web curto, dados com repetição de palavras e n-gramas (Brotli tem dicionário estático) |

## Perfil estrutural do arquivo

{{METRICS_JSON}}

## Saída obrigatória

Responda SOMENTE com este JSON, sem texto adicional:

```json
{
  "strategy": "cmp.lzma",
  "reason": "Uma frase explicando a escolha."
}
```

Valores válidos para `strategy`: `cmp.lzma`, `cmp.brotli`.
NUNCA retorne gen.repeat, gen.pattern, cas.raw ou qualquer outro valor.
