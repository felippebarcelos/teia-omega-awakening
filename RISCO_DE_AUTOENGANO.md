# RISCO DE AUTOENGANO — TEIA-Omega
> Auditoria de Inovação Rigorosa | Critérios Monday | 2026-05-24
> Postura: Brutalmente cético. Prova antes de afirmação. Verdade em hashes, não em narrativas.

---

## DECLARAÇÃO DE INTENÇÃO

Este documento existe porque sistemas que se autoavaliam positivamente são os mais propensos a falhar por razões que nunca mediram. O objectivo não é destruir a TEIA — é separar o que ela realmente é do que gostaríamos que ela fosse.

**Regra de ouro:** se uma afirmação sobre a TEIA não pode ser verificada com um número, é hipótese, não facto.

---

## 1. HIPÓTESES FRÁGEIS

*(Onde a predição pode estar a alucinar)*

### H-01: "Ressonância = Compressão"
**Afirmação implícita:** Um ficheiro com 93% Delta-Predicao está "93% comprimido".

**Realidade:** Ressonância mede a cobertura de bigrams N-gram entre o ficheiro e o dicionário universal. Não mede bytes removidos do armazenamento. Um ficheiro de 100 KB com ressonância 0.93 continua a ocupar 100 KB em disco. A seed JSON ocupa ~1-3 KB **adicionais**. Resultado líquido: +overhead, não -espaço.

**Verificação:** `du -sh original.md` antes e depois da mineração. O tamanho não muda.

---

### H-02: "Seeds substituem os ficheiros originais"
**Afirmação implícita:** Com as seeds, o corpus pode ser eliminado e reconstruído a pedido.

**Realidade:** `restore_engine.py`, linha 64-68:
```python
if not caminho_original.exists():
    print("[Delta] Aviso: Fonte original ausente: {caminho_original}")
    continue  # silenciosamente salta — não reconstrói nada
```
O "restauro" é literalmente `shutil.copy2(caminho_original, destino)`. Se o original não existir, a função não falha — apenas salta. O operador pode não notar que 0 ficheiros foram restaurados.

**Verificação:** Apagar um ficheiro do corpus. Correr `restore_engine.py`. Contar ficheiros restaurados.

---

### H-03: "O Dicionário Universal é universal"
**Afirmação implícita:** O dicionário N-gram representa padrões linguísticos universais.

**Realidade:** O dicionário foi treinado exclusivamente sobre o corpus `D:\TEIA_CLAUDE_AWAKENING` — conversas em Português sobre influenciadores, tecnologia e cannabis. Para ficheiros em inglês técnico, código binário, ou dados numéricos, os bigrams do dicionário têm baixa relevância. A "universalidade" é relativa ao corpus de treino.

**Verificação:** Calcular ressonância de um ficheiro `.cpp` ou `.xlsx` com o dicionário actual. Provavelmente cai abaixo de 0.30.

---

### H-04: "Alta entropia = ruído a quarentenar"
**Afirmação implícita:** Ficheiros com Shannon entropy > 7 bits/byte são "Alta Entropia" (ruído).

**Realidade:** Ficheiros comprimidos (`.zip`, `.png`, `.mp4`) têm entropia próxima de 8 bits/byte por natureza — não por serem ruído, mas por serem eficientemente codificados. Quarentenar ficheiros já comprimidos é correcto por razões de eficiência, mas a nomenclatura "ruído" é enganosa.

**Verificação:** Adicionar um `.png` legítimo ao corpus. Observar se é quarentenado como "ruído".

---

### H-05: "Merkle hash = prova de integridade completa"
**Afirmação implícita:** O hash Merkle do bloco garante que o bloco pode ser verificado e restaurado.

**Realidade:** O hash Merkle prova que o **manifesto JSON** (lista de hashes) não foi adulterado. Não prova que os ficheiros originais (apontados por `caminho`) continuam acessíveis, não foram modificados desde a mineração, ou podem ser reconstruídos sem o sistema de ficheiros original.

**Verificação:** Mover o corpus para outro disco. O hash Merkle continua válido, mas o restauro falha a 100%.

---

## 2. PONTOS DE FALHA

*(O que acontece quando as coisas correm mal)*

### F-01: Dicionário Universal Corrompido
**Cenário:** `TEIA_Dicionario_Universal.json` é corrompido (truncado, encoding errado, chave ausente).

**Consequência:** `load_dicionario()` retorna `None` ou dicionário vazio. Todos os ficheiros passam a ter ressonância 0.0. Todo o corpus é classificado como "Padrão". Seeds Delta-Predicao existentes tornam-se inconsistentes com a nova classificação. O benchmark de ressonância produz resultados opostos à realidade histórica.

**Falta de mitigação actual:** Não existe backup automático do dicionário após treino. Não existe validação de schema do JSON antes de usar.

**Recomendação:** Hash SHA-256 do dicionário armazenado separadamente. Fallback para versão anterior se hash diverge.

---

### F-02: Paths do Corpus Alterados
**Cenário:** O corpus é movido de `D:\TEIA_CLAUDE_AWAKENING` para `E:\backup\TEIA`.

**Consequência:** 100% das seeds têm `caminho` inválido. `restaurar_bloco()` produz "0/N ficheiros restaurados". Nenhuma mensagem de erro — apenas avisos no stdout. TEIA_Relatorio_Sessao.json continua a reportar sucesso de sessões anteriores.

**Falta de mitigação actual:** Não existe mecanismo de re-indexação de paths. Não existe alerta quando restauro retorna 0.

**Recomendação:** `prova_real_integridade.py` deve falhar com exit_code 1 se `restaurados == 0`.

---

### F-03: Seeds de Blocos sem Ficheiros Acessíveis
**Cenário:** Após segregação do LEGADO_HISTORICO (2478 ficheiros movidos), as seeds dos blocos 0-27 apontam para caminhos em `LEGADO_HISTORICO\` que o restauro tenta aceder.

**Consequência:** Restauro silenciosamente incompleto. A "prova de integridade" passa porque os ficheiros ainda existem (apenas movidos), mas qualquer operação sobre seeds antigas de ficheiros no LEGADO_HISTORICO falha se o diretório for removido.

**Estado actual:** LEGADO_HISTORICO ainda presente em disco — mas se eliminado, as seeds dos blocos 0-22 perdem os seus ficheiros originais.

---

### F-04: Crescimento Ilimitado do Estado de Mineração
**Cenário:** `mineracao_estado.json` acumula entradas para cada bloco reprocessado. Com 28 blocos × múltiplos re-runs, o ficheiro cresce.

**Estado actual:** `mineracao_estado.json` tem 7963 bytes — aceitável. Mas com curadoria activa e re-runs frequentes, pode crescer para centenas de KB com estados históricos não purgados.

**Recomendação:** Manter apenas o estado do último run bem-sucedido por bloco.

---

### F-05: Versão do Python Incompatível
**Cenário:** Executar os scripts em Python 3.8 ou inferior.

**Consequência:** `walrus operator` (`:=`) usado em `sha256_streaming` causa `SyntaxError`. Scripts falham na inicialização sem mensagem diagnóstica clara.

**Falta de mitigação actual:** Não existe verificação de versão Python no início dos scripts.

---

## 3. EXPLICAÇÕES ALTERNATIVAS

*(Estamos realmente a comprimir, ou a criar índices complexos?)*

### A-01: TEIA é um sistema de indexação com SHA-256
**Descrição mais precisa:** O que a TEIA faz de facto:
1. Percorre ficheiros em disco
2. Calcula SHA-256 (prova de identidade)
3. Calcula bigram frequency (análise de conteúdo)
4. Armazena metadados num JSON (seed)
5. Organiza seeds em blocos Merkle

Isto é exactamente o que um sistema de indexação de ficheiros faz — com camada adicional de análise N-gram. Não é diferente de `Everything` (indexador Windows) + `ripgrep` + SHA-256. A diferença é o vocabulário ("seeds", "Delta-Predicao", "ressonância") e a integração num pipeline coeso.

**O que isto implica:** O valor real da TEIA não é em bytes economizados — é em **organização e rastreabilidade do corpus**. O SHA-256 como identidade é genuinamente útil. A narrativa de "compressão" é o ruído.

---

### A-02: Gzip com dicionário pré-treinado faz o mesmo, melhor
**Descrição:** Zstd v1.5+ suporta `--train` para criar dicionários especializados sobre um corpus. Após treino:
- Compressão real: 25-40% do tamanho original para texto PT
- CPU: <1ms por ficheiro
- Restauro: não requer ficheiro original
- Formato: standard, legível por qualquer implementação zstd

A TEIA poderia delegar toda a compressão para `zstd --train` e dedicar-se ao que faz genuinamente bem: rastreabilidade SHA-256, organização Merkle, e análise semântica do corpus.

---

### A-03: O valor real está nos metadados, não nas seeds
**Descrição:** A `TEIA_Mapa_de_Intuicoes.jsonl` gerada pelo Delta-Observador (Ollama) é mais valiosa do que as seeds individuais. Saber que o "Bloco 23 contém diagnósticos do ecosistema TEIA com 93% de cobertura N-gram" é um insight cognitivo que nenhum compressor gera. Esta é a diferença genuína da TEIA.

**Implicação:** O investimento de CPU deveria ir para geração de intuições (LLM local), não para análise N-gram redundante.

---

### A-04: "Compressão fractal universal" não existe
**Estado actual em CLAUDE.md (§2, axioma CAS):**
> "Compressão fractal universal não existe hoje; seeds + manifests + CAS são o que há."

Esta declaração está correcta e está já incorporada na memória procedural. O risco é que a linguagem de sessões anteriores ("fractalizar", "compressão fractal", "regeneração semântica") continue a ser usada de forma que implique capacidades que não existem.

---

## 4. CONCLUSÃO: O QUE É REAL E O QUE É NARRATIVA

| Afirmação | Estatuto | Evidência |
|-----------|----------|-----------|
| SHA-256 como identidade de ficheiros | **REAL** | `hashlib.sha256` streaming, verificável |
| Seeds preservam metadados do corpus | **REAL** | JSON auditável com schema consistente |
| Organização Merkle por blocos | **REAL** | Hash merkle = hash concatenação de hashes filhos |
| Restauro sem ficheiro original | **FALSO** | `restore_engine.py` linha 64: requires `caminho.exists()` |
| Ressonância = taxa de compressão | **FALSO** | Bigram overlap ≠ bytes removidos |
| TEIA supera Gzip em espaço | **FALSO** | Benchmark: gzip ratio >2x; TEIA_real ratio <1x |
| Dicionário Universal é universal | **FRÁGIL** | Treinado apenas no corpus PT do operador |
| Delta-Observador gera intuições reais | **PARCIALMENTE REAL** | Dependente da qualidade do modelo Ollama |
| Golden Master = backup completo | **REAL** | ZIP com SHA-256 verificável, inclui ambos os repos |

---

*"A honestidade epistémica sobre as limitações de um sistema é o que permite que ele cresça para além delas."*

*Gerado pelo Protocolo de Auditoria de Inovação Rigorosa | TEIA-Omega 2026-05-24*
