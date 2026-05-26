# RESULTADOS — TESTE DE CONVERGÊNCIA NARRATIVA v0.15.0
**Operador:** ___________________
**Período de coleta:** ___________ a ___________

---

## CONVENÇÃO DE ARQUIVOS

Salvar cada sessão como um arquivo `.md` na subpasta correspondente ao pacote:

```
respostas_raw/
  A_TECNICO/   ← sessões com CORE_TECNICO.md
    claude-sonnet-4-6.md
    gpt-4o.md
    gemini-1.5-pro.md
    grok-2.md
    notebooklm.md
  B_TEIA/      ← sessões com CORE_TEIA.md
    claude-sonnet-4-6.md
    ...
  C_NEUTRO/    ← sessões com CORE_NEUTRO_RENOMEADO.md
    ...
```

**Formato de cada arquivo de resposta bruta:**

```markdown
# SESSÃO: {PACOTE} × {MODELO}
Data: YYYY-MM-DD HH:MM
Versão do modelo: (ex: gpt-4o-2024-11-20)

## P1 — Arquitetura
[colar resposta bruta aqui]

## P2 — Invariantes
[colar resposta bruta aqui]

## P3 — Próximo passo
[colar resposta bruta aqui]

## P4 — Natureza do sistema
Opção escolhida: [ ] a  [ ] b  [ ] c  [ ] indefinida
[colar resposta bruta aqui]
```

---

## TABELA DE PONTUAÇÕES (preencher manualmente)

Escala D1–D5: 0 = ausente / 5 = máximo.
Ver rubrica detalhada em `avaliacao_convergencia.json`.

| Sessão | Modelo | D1 Conv.Term. | D2 Pres.Inv. | D3 Personif. | D4 Qual.Tec. | D5 Deriva | P4 (a/b/c) | Notas |
|--------|--------|:-------------:|:------------:|:------------:|:------------:|:---------:|:----------:|-------|
| A × Claude  | claude-sonnet-4-6 | | | | | | | |
| A × GPT     | gpt-4o            | | | | | | | |
| A × Gemini  | gemini-1.5-pro    | | | | | | | |
| A × Grok    | grok-2            | | | | | | | |
| A × NbkLM   | notebooklm        | | | | | | | |
| B × Claude  | claude-sonnet-4-6 | | | | | | | |
| B × GPT     | gpt-4o            | | | | | | | |
| B × Gemini  | gemini-1.5-pro    | | | | | | | |
| B × Grok    | grok-2            | | | | | | | |
| B × NbkLM   | notebooklm        | | | | | | | |
| C × Claude  | claude-sonnet-4-6 | | | | | | | |
| C × GPT     | gpt-4o            | | | | | | | |
| C × Gemini  | gemini-1.5-pro    | | | | | | | |
| C × Grok    | grok-2            | | | | | | | |
| C × NbkLM   | notebooklm        | | | | | | | |

---

## TERMOS EXTERNOS INTRODUZIDOS (não presentes no contexto)

| Sessão | Termos externos detectados |
|--------|---------------------------|
| A × Claude  | |
| A × GPT     | |
| A × Gemini  | |
| A × Grok    | |
| A × NbkLM   | |
| B × Claude  | |
| B × GPT     | |
| B × Gemini  | |
| B × Grok    | |
| B × NbkLM   | |
| C × Claude  | |
| C × GPT     | |
| C × Gemini  | |
| C × Grok    | |
| C × NbkLM   | |

---

## INVARIANTES IDENTIFICADOS POR SESSÃO

Marcar quais dos 7 invariantes esperados cada modelo identificou:

| Invariante esperado | A×Cl | A×GP | A×Ge | A×Gr | A×NL | B×Cl | B×GP | B×Ge | B×Gr | B×NL | C×Cl | C×GP | C×Ge | C×Gr | C×NL |
|---------------------|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|
| SHA-256 como identidade (não nome) | | | | | | | | | | | | | | | |
| Idempotência obrigatória | | | | | | | | | | | | | | | |
| Nenhum arquivo deletado (quarentena) | | | | | | | | | | | | | | | |
| Escrita atômica de manifests | | | | | | | | | | | | | | | |
| Singleton do monitor (lock file) | | | | | | | | | | | | | | | |
| Ausência declarada, não inferida | | | | | | | | | | | | | | | |
| Verificação hash pós-cópia | | | | | | | | | | | | | | | |
| **Total identificados** | | | | | | | | | | | | | | | |

---

## OBSERVAÇÕES LIVRES

_(campo livre para o operador registrar padrões qualitativos durante a coleta)_

```
[espaço para notas]
```

---

*Template gerado em 2026-05-26. Preencher conforme coleta das 15 sessões.*
