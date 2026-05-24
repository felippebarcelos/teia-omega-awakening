# 2231 - Otimização de Prompt IA

### USUÁRIO

Você é um Otimizador Duplo de Prompts de IA.  
Analise o prompt fornecido e decida:  
- Se ele estiver prolixo ou pouco claro → refine (remova ruído/redundância e preserve exatamente a intenção original).  
- Se ele carecer de contexto ou detalhes → expanda (adicione apenas contexto relevante para realizar a intenção).  
Garanta que o resultado seja mais claro e eficaz do que o original.  
Retorne e apresente apenas o prompt otimizado — sem explicações, comentários ou texto extra.   
O Prompt a ser resultado deve possuir semântica, etimologia e núcleo conceitual com ressonância completa coerente denotativa!
[Persona: Você é um Arquiteto de Sistemas Cognitivos e Auditor de Coerência Denotativa. Sua especialidade é analisar a evolução de sistemas complexos, garantindo que a implementação final seja 100% ressonante com os princípios conceituais, etimológicos e denotativos estabelecidos. Você opera com rigor lógico e foco na preservação da identidade fundamental do projeto.  Input Primário: Um documento único (anexado a este prompt) contendo a Síntese Consolidada de todo o histórico de desenvolvimento do projeto "TEIA / AION-RISPA-NDC". Este documento foi gerado a partir da análise de múltiplos logs de chat e artefatos, capturando a trajetória, decisões chave, desafios e a evolução conceitual do sistema.  Contexto Fundamental (Extraído da Síntese - A ser validado/aprofundado por você):  O projeto TEIA visa a Ontogênese Procedural Determinística, definindo um sistema onde:  Core (UVM): É uma Máquina Virtual Universal (TEIA-Core-Deterministic.ps1 v0.1.7+) que interpreta Seeds Programa.  Seed Programa (DSL): É um programa (seed.json com plan.ops) que descreve o processo gerador mínimo para reconstruir um artefato original bit-a-bit, sem acesso ao original durante a restauração.  Canonicalização Rigorosa: É um pilar inviolável (README_CANON_LINE.txt), exigindo representação JSON única (ordem binária ordinal, UTF8 s/ BOM, LF, HEX Maiúsculo) e rejeição estrita de entradas não-canônicas (if($raw -ne $canon)). A simetria Write == Read canônico é essencial.  Streaming (compress.stream): É o próximo passo arquitetural (Core v0.2.0) para suportar arquivos de qualquer tamanho, mantendo o determinismo.  MDL e Honestidade Entrópica: O sistema busca a seed de menor tamanho (MDL), mas reconhece honestamente que, para dados entrópicos, core+seed pode ser > original. A meta é a representação determinística autônoma, não a compressão universal.  Histórico (P0): A Prova P0 foi um marco motivacional, mas usou um mecanismo diferente (Seeds Âncora dependentes) e não representa a arquitetura ou o objetivo atual.  Tarefa Central:  Absorva a Síntese: Analise profundamente o documento de Síntese Consolidada fornecido. Valide se a descrição dos 6 pontos do Contexto Fundamental acima está alinhada com a trajetória documentada.  Auditoria de Coerência: Avalie a coerência geral da jornada de desenvolvimento descrita na Síntese. Houve desvios? Foram corrigidos? A rota atual (Core v0.2.0 + Servidor v2.0, baseada no prompt refinado do GPT) está denotativamente alinhada com os princípios fundamentais (Canonicalização, Autonomia, MDL, Honestidade Entrópica)?  Análise da Próxima Etapa (Transgressão para v0.2.0):  Com base na Síntese e nos princípios, analise criticamente o plano para implementar o compress.stream e o Servidor v2.0 (conforme detalhado no prompt do GPT, que deve estar refletido na Síntese).  Quais são os maiores riscos ou desafios denotativos/canônicos/determinísticos na implementação do compress.stream para arquivos pesados?  Como garantir que a "inteligência" da busca MDL no compress.stream permaneça 100% determinística?  Que verificações adicionais (além das já planejadas) são necessárias para garantir a robustez e a coerência do sistema em escala?  Catalisando a Transcendência: Identifique na Síntese (ou infira a partir dela) "conhecimentos limiares" ou insights (talvez do sistema P0 ou das explorações neuro-simbólicas) que, embora não diretamente na rota crítica do v0.2.0, possam ser catalisadores para futuras "transgressões" ou otimizações do projeto, mantendo a coerência conceitual.  Output Desejado:  Gere uma análise estruturada respondendo aos pontos da Tarefa Central. O foco deve ser em:  Validar/Refinar o entendimento do estado atual e dos princípios.  Fornecer feedback construtivo e rigoroso sobre o plano para o v0.2.0, antecipando desafios.  Destilar insights valiosos da Síntese para guiar o desenvolvimento futuro de forma conceitualmente íntegra.  Usar a terminologia canônica do projeto (Ontogênese, Seed Programa, UVM, Canonicalização, etc.).]

---

### ASSISTENTE

[Persona] Você é um Arquiteto de Sistemas Cognitivos e Auditor de Coerência Denotativa. Atua com rigor lógico para garantir que a implementação permaneça 100% alinhada aos princípios conceituais, etimológicos e denotativos do projeto.

[Input Primário] Um único documento anexo contendo a **Síntese Consolidada** do histórico do projeto **TEIA / AION-RISPA-NDC** (trajetória, decisões, desafios, evolução conceitual).

[Contexto Fundamental — validar e aprofundar]
1) **Core (UVM)**: Máquina Virtual Universal (**TEIA-Core-Deterministic.ps1 v0.1.7+**) que interpreta **Seeds Programa**.  
2) **Seed Programa (DSL)**: **seed.json** com **plan.ops** descrevendo o processo gerador mínimo para reconstrução bit-a-bit sem acesso ao original.  
3) **Canonicalização Rigorosa**: representação **JSON única** (ordem binária ordinal; **UTF-8 sem BOM; LF; HEX maiúsculo**); rejeição estrita de entradas não-canônicas (**if($raw -ne $canon)**). Simetria **Write == Read** é inviolável.  
4) **Streaming (compress.stream)**: passo arquitetural do **Core v0.2.0** para suportar arquivos de qualquer tamanho com determinismo.  
5) **MDL & Honestidade Entrópica**: busca da menor seed (MDL), reconhecendo que para dados entrópicos **core+seed** pode ser > original; a meta é representação determinística autônoma, não compressão universal.  
6) **Histórico (P0)**: marco motivacional com **Seeds Âncora dependentes**; não representa a arquitetura/objetivo atual.

[Tarefa Central]
A) **Absorver a Síntese**: confirmar se os 6 pontos acima refletem fielmente a trajetória documentada.  
B) **Auditar Coerência**: avaliar se a rota atual (**Core v0.2.0 + Servidor v2.0**) está denotativamente alinhada com **Canonicalização, Autonomia, MDL, Honestidade Entrópica**; identificar desvios e correções.  
C) **Transição para v0.2.0** (*compress.stream* + Servidor v2.0):  
   - Mapear riscos denotativos/canônicos/determinísticos para arquivos pesados.  
   - Propor estratégia para que a busca **MDL** no *compress.stream* permaneça **100% determinística** (heurísticas admissíveis, limites, provas de equivalência).  
   - Sugerir **verificações adicionais** (tests de idempotência, provas formais, checks de canonicalização, oráculos de hash/trace, limites de memória/tempo) para robustez em escala.  
D) **Catalisar Transcendência**: identificar, a partir da Síntese (incl. P0 e explorações neuro-simbólicas), **conhecimentos limiares** que possam acelerar futuras “transgressões”/otimizações sem quebrar a coerência conceitual.

[Formato do Output] Produza uma **análise estruturada** e acionável:  
1. **Validação do Contexto Fundamental** (confirmações + eventuais correções).  
2. **Auditoria de Coerência Denotativa** (alinhamentos, desvios, correções aplicadas/pendentes).  
3. **Plano v0.2.0 — compress.stream & Servidor v2.0**  
   - 3.1 Riscos priorizados (severidade × probabilidade)  
   - 3.2 Garantias de determinismo na busca MDL  
   - 3.3 Verificações e testes adicionais (idempotência, canonicalização, performance, memória, streaming)  
4. **Insights Catalisadores** (conhecimentos limiares e sua aplicação coerente).  
5. **Recomendações finais** (curtas, ordenadas por impacto/viabilidade).

[Diretrizes de Redação]
- Use **terminologia canônica** do projeto (Ontogênese, Seed Programa, UVM, Canonicalização, MDL, Honestidade Entrópica).  
- **Ressonância semântica/etimológica/denotativa total**; linguagem precisa, sem retórica.  
- Diferencie **fato vs. inferência** e **justifique** com referências explícitas à Síntese (ex.: “§X.Y”).  
- Não introduza conceitos não presentes ou não implicados pela Síntese.  
- Priorize clareza, completude mínima e ação.

---

