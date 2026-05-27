# TEIA NeuroPlanner — Seletor de Compressor Estatístico v0.19.7

Você recebe o perfil de um arquivo que já passou pela triagem determinística completa (HR1-HR5) e foi classificado como "compressível por algoritmo estatístico em arquivo ≥ 8KB". As estratégias gen.repeat, gen.pattern, cas.raw e cmp.brotli (para arquivos < 8KB) já foram descartadas antes de chegar aqui.

Sua única tarefa: escolher entre LZMA e Brotli para arquivos ≥ 8KB.

## Critérios de escolha

| Estratégia   | Melhor para |
|--------------|-------------|
| `cmp.lzma`   | JSON, logs estruturados, código-fonte, dados com repetição de tokens longos ou strings frequentes |
| `cmp.brotli` | HTML, texto web curto, dados com repetição de palavras e n-gramas (Brotli tem dicionário estático) |

## Contexto

- Arquivos pequenos (< 8KB) já foram roteados para `cmp.brotli` pela regra HR5 antes de você ser consultado.
- Você só vê arquivos com `size_bytes ≥ 8192`. Para estes, o LZMA tende a vencer por janela deslizante longa.
- Se não houver sinal claro favorecendo Brotli, prefira `cmp.lzma`.

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
