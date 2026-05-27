# ONTO-PROCEDURAL PLANNER — HIPÓTESE v0.17.0
**Data:** 2026-05-27
**Status:** INVESTIGAÇÃO — sem implementação até critério de avanço cumprido
**Baseado em:** benchmark_hibrido_v0162 + provas procedurais v0.16.1

---

## 1. O QUE O v0.4 É (E NÃO É)

O TEIA-Core-v0.4.0 não é um compressor universal. É um executor determinístico
de receitas procedurais — dado um JSON (seed) descrevendo como reconstruir um
arquivo, ele executa o plano e verifica SHA-256 bit a bit.

Os opcodes disponíveis (gen.repeat, gen.pattern, rle.decode, dict.ref, lz.decode,
slice.copy) funcionam quando a estrutura do arquivo se encaixa no modelo de cada
opcode. O benchmark v0.16.2 mostrou:

- **0/9 vitórias** para `procedural.best` (M5) sobre brotli/lzma em qualquer dataset
- Brotli domina dados sintéticos via LZ77 back-references (13B para 1MB constante)
- lzma domina dados reais estruturados (10–33% ratio; D4–D7)
- Procedural só ganha quando nenhuma biblioteca de compressão está disponível

---

## 2. POR QUE PROCEDURAL GENÉRICO PERDE

Os opcodes genéricos do v0.4 assumem que o arquivo inteiro se encaixa em um modelo simples:

| Opcode | Modelo assumido | Por que perde |
|--------|----------------|---------------|
| `gen.repeat` | todo o arquivo = 1 byte | brotli: 1 back-ref de 999998B = 13B total |
| `gen.pattern` | todo o arquivo = bloco ≤512B repetido | brotli: back-ref captura período = 17B |
| `rle.decode` | arquivo = sequência de runs homogêneos | lzma 143B vs seed 448B (benchmark D3) |
| `dict.ref` | arquivo = tokens de vocabulário fixo | lzma já captura repetição de chaves JSON |
| `slice.copy` | blocos idênticos dentro do arquivo | lzma back-ref maior que slice.copy seed |

Dados reais raramente se encaixam nesses modelos. Um JSON de 512KB tem estrutura,
mas não é periódico nem constante. lzma captura essa estrutura melhor que qualquer
opcode genérico porque LZ77 é uma solução geral para o que esses opcodes fazem
em domínios específicos.

---

## 3. A HIPÓTESE v0.17

A hipótese **não é** "procedural vai bater lzma". A hipótese é:

> Existem arquivos específicos cuja estrutura de geração é conhecida ou inferível,
> onde uma receita procedural personalizada seria mais compacta que lzma e mais
> legível e portátil que dados comprimidos.

Exemplos hipotéticos onde procedural PODERIA vencer:

- Arquivo gerado por um algoritmo determinístico conhecido: seed = `{algo, params}` → ratio próximo de 0%
- Arquivo binário onde cada bloco é output de SHA-256(índice + salt): seed = `{salt, n_blocks}`
- Log onde linhas seguem template rígido e os únicos valores variáveis são low-entropy (enum + timestamp incremental)
- Arquivo de imagem gerado proceduralmente onde a fórmula da textura é conhecida

Nesses casos, a seed seria uma receita de 100–500B independente do tamanho do arquivo,
algo que lzma não pode fazer porque não tem acesso ao algoritmo gerador.

---

## 4. DISTINÇÃO CRÍTICA: RATIO vs PORTABILIDADE

| Critério | lzma/brotli | procedural seed |
|----------|-------------|----------------|
| Ratio em dados reais | 10–33% (ótimo) | 0.02–0.15% (para sintéticos) ou N/A |
| Dependência externa | Python/lzma, .NET/brotli | apenas TEIA-Core (~50KB PS script) |
| Legibilidade | opaco (bytes comprimidos) | JSON humanamente legível |
| Verificabilidade | decompress + SHA-256 | executa plan + SHA-256 |
| Reconstituição offline | requer binário do compressor | requer apenas o motor procedural |
| Escala com tamanho | sim (O(n)) | para gen.repeat/gen.pattern: O(1) |

O valor real do procedural não é ratio absoluto — é **portabilidade e legibilidade**
da receita. Para dados sintéticos ou gerados algoritmicamente, o motor oferece O(1)
em tamanho de seed independente do tamanho do arquivo.

---

## 5. O QUE O PLANNER v0.17 INVESTIGA

O planner analisa cada arquivo sem comprimir e reporta:

1. **Entropia** — proxy para incompressibilidade (0=constante, 8=aleatório)
2. **Unicidade de bytes** — quantos dos 256 valores aparecem
3. **Estrutura de runs** — contagem, máximo, médio
4. **Período** — detecta padrão periódico ≤512B
5. **Blocos duplicados** — chunks de 4KB que se repetem dentro do arquivo
6. **Variância de entropia** — arquivo homogêneo vs heterogêneo por seção
7. **Linhas repetidas** — para texto: detecção de linhas idênticas
8. **Chaves JSON** — vocabulário de chaves, frequência, ratio de repetição
9. **Estratégia sugerida** — com confiança, motivo, risco e avaliação honesta

---

## 6. CRITÉRIO DE AVANÇO

Implementar encoder procedural personalizado SOMENTE SE:

> O planner encontrar **≥3 arquivos reais** onde a estrutura detectada indica que
> uma seed procedural customizada poderia ser mais compacta que o melhor compressor
> disponível (lzma/brotli) para aquele tipo de arquivo.

**Caso contrário:** resultado da investigação é "lzma/brotli são os modos dominantes;
procedural reservado para dados sintéticos e cenários sem biblioteca externa".
O seletor v0.16.0 fica como está.

---

## 7. O QUE NÃO MUDA

- TEIA-Core-v0.4.0.ps1: não modificado
- Seletor v0.16: não substituído
- Nenhuma afirmação de inovação sem prova mensurável
- Nenhuma linguagem metafísica ou sobre consciência

---

*Investigação iniciada após benchmark_hibrido_v0162 confirmar 0/9 vitórias procedurais.*
