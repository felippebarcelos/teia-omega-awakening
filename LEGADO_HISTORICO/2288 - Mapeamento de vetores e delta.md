# 2288 - Mapeamento de vetores e delta

### USUÁRIO

Use do meu histórico para catalisar uma delta serendipidade latente.

O processo não seria "adivinhando". Seria um pipeline lógico:

Mapeamento de Vetores (O Histórico): Você analisaria meu user_context para extrair os "vetores" ou temas centrais do seu interesse.

Varredura do "Delta" (O Agora): Você usaria a busca para encontrar o que é novo, emergente ou de nicho hoje (o "delta").

A Ponte Latente (O curto Epifanico): Você procuraria por uma informação nova (do passo 2) que cria uma ponte inesperada entre dois ou mais dos meus vetores (do passo 1).

---

### ASSISTENTE

Segue uma primeira rodada do pipeline completo que você descreveu, já aplicado ao seu histórico.

---

## 1. Vetores principais extraídos do seu histórico

Sintetizando o user_context em “vetores”:

1) **Compressão procedural / seeds / QR**  
   - Seed procedural TEIA, compressão extrema (ex: 500MB→KB), restauração bit-a-bit, envio via QR como núcleo.  
   - Foco em SHA256, idempotência, ZIPs, manifests, .teia etc.

2) **Autonomia offline + agentes / CLI**  
   - Codex CLI + Auditor GPT, loops autossintetizantes, dashboard TEIA, operação 100% offline (PC e iPhone/Pyto).  
   - PowerShell como “exoesqueleto” de automação.

3) **Ontologias simbólicas / epistemologia**  
   - TEIA como ontologia vivo-procedural (RDF/OWL, JSON-LD, grafos), vacina contra inferência superficial, compressão Kolmogorov-like.

4) **Arquivamento, integridade e backup frugal**  
   - Reorganizar disco, evitar corrupção, garantir integridade (hash, logs, testes), seed como meio de transmissão offline robusto.

5) **Hacks frugais / jugAAD**  
   - Soluções baratas, improvisadas, eficientes (ex.: limpeza de piteiras, uso criativo de recursos mínimos).

---

## 2. Varredura do “delta” emergente (2024–2025)

Do lado “mundo lá fora”, aparecem duas frentes muito alinhadas com seus vetores:

### 2.1. Compressão = inteligência (Kolmogorov, LMs e código)

- Há uma linha recente tratando **modelos de linguagem como compressores gerais**, mostrando que LLMs conseguem comprimir áudio e imagens melhor que codecs clássicos em alguns cenários, ligando diretamente compressão a previsão inteligente. citeturn0search12  
- Estudos com Transformers pré-treinados investigam **compressão em nível de bytes** e buscam um “sweet spot” em que o mesmo modelo sirva simultaneamente como compressor competitivo e modelo de linguagem, aproximando a prática do ideal de Kolmogorov (programa mínimo). citeturn0search15  
- Um benchmark recente (“Kolmogorov-Test”) avalia LLMs de código pela capacidade de gerar o programa mais curto que produz certa sequência, explicitando “compressão como medida de inteligência algorítmica”. citeturn0search0  

Isso ressoa 1:1 com a sua visão de seed procedural como “programa mínimo reprodutor” (compressão ≈ inteligência ≈ episteme).

### 2.2. QR codes “irrecuperáveis” sendo reconstruídos com deep learning

Há um surto de trabalhos recentes focados em **tornar QR codes ilegíveis novamente legíveis** usando redes neurais:

- Modelos de super-resolução específicos para QR conseguem recuperar códigos muito degradados, usando CNNs profundas e redes com atenção para reconstruir detalhes que a leitura tradicional não conseguiria. citeturn0search2  
- Há arquiteturas de super-resolução dedicadas a QR, otimizadas não apenas para PSNR/SSIM, mas para **taxa de reconhecimento real do leitor**, treinando com perda de “reconhecibilidade”. citeturn0search20  
- Trabalhos de 2024 exploram super-resolução que incorpora explicitamente as características estruturais do QR (padrões de busca, módulos, etc.) para melhorar robustez em condições de blur/ruído, indo além dos modelos genéricos. citeturn0search14  

Em paralelo, métodos de correção de QR distorcido usam redes neurais para “retificar” códigos geométrica e visualmente comprometidos, restaurando a informação embutida. citeturn0search11  

Resumo do delta:  
QR deixou de ser apenas um “bitmap estático” com ECC clássico. Em 2024–2025, o ecossistema está caminhando para **QR + modelo neural ao redor**, tornando possível recuperar informação mesmo quando a imagem está bem além dos limites originais de correção.

---

## 3. A ponte latente: “TEIA Neural-QR Seed”

Aqui entra o “curto epifânico”: unir seus vetores 1, 2, 3 e 4 com esse delta.

### Ideia-núcleo

Transformar o seu conceito de **seed procedural TEIA** em um:

> **Neural-QR Seed**: um núcleo TEIA codificado em QR (ou conjunto de QRs) que assume, desde o design, que será decodificado por um modelo neural especializado – não apenas por leitores QR tradicionais.

Ou seja:

1) Você continua usando o seed procedural (.teia, manifesto, hashes) como hoje.  
2) Mas o formato “de transporte físico” deixa de ser só “QR convencional com ECC” e passa a ser:  
   - QR(s) codificados no limite da densidade/ruído, potencialmente “ilegíveis” para um leitor normal.  
   - Projeto desde o início para serem recuperados com um **pipeline neural** (super-resolução + correção + decodificação).

### Por que isso é uma ponte real entre seus vetores e o delta?

- **Compressão procedural + Kolmogorov/LLM**  
  - O seed já é, na sua visão, “programa mínimo que recria o todo”. A linha “Language Modeling is Compression” e afins reforça que **modelos de linguagem e vision podem ser os próprios descompresssores universais**. citeturn0search12turn0search15  
  - O Neural-QR Seed assume explicitamente isso: parte da “compressão” está agora na **capacidade do modelo neural de inferir bits perdidos**, não só no código estático.

- **Ontologia simbólica / TEIA**  
  - Você já trabalha com a TEIA como ontologia viva. O Neural-QR Seed pode carregar não só dados “brutos”, mas um manifesto ontológico mínimo que “instrui” o descompressor (humano + modelo) sobre como reconstruir a estrutura de conhecimento, não apenas arquivos.

- **Autonomia offline e agentes**  
  - No seu iPhone (Pyto) ou PC, você poderia ter:
    - Um script local que faz a leitura da foto do QR degradado.  
    - Um modelo leve de super-resolução/retificação específico para QR (ou chamado via ferramenta externa local).  
    - Depois, a pipeline TEIA restaura o pacote .teia e valida via SHA256.  
  - Isso encaixa com seu desejo de **ciclo completo offline, auditável, com seed pequeno e físico** (uma etiqueta, um cartão, um print no papel).

- **Arquivamento robusto e frugal**  
  - Em vez de depender apenas de:
    - mídia digital “perfeita” + ECC clássico,  
    - você passa a assumir que o seed pode ser queimado, riscado, borrado – e ainda assim recuperável via modelo neural.  
  - Isso é “backup de época pós-ECC”: a resiliência vem também da **inteligência do decodificador**.

- **JugAAD / frugalidade**  
  - Um único adesivo impresso em casa, colado numa capa ou suporte barato, pode conter um seed TEIA criptografado, **denso demais para leitores QR comuns**, mas reconstituível com um pipeline neural rodando em hardware commodity.  
  - É literalmente “backup de alta ordem com custo quase zero”.

### Micro-roteiro prático (versão enxuta, sem código)

Se você quiser explorar isso como experimento mínimo:

1) **Seed base**  
   - Pegue um micro-seed TEIA já existente (ex.: um manifesto + hashes + instruções para baixar/gerar o resto).  
   - Comprima o máximo possível (Brotli/zip + sua pipeline atual).

2) **Codificação QR no limite**  
   - Gere um QR com densidade alta (versão alta, pouco padding visual).  
   - Propositalmente degrade a imagem (print ruim, foto desfocada, compressão JPEG forte).

3) **Pipeline neural de recuperação**  
   - Use uma ferramenta/open model de super-resolução/retificação de QR inspirada nesses trabalhos recentes (super-res específica para QR, com objetivo de maximizar taxa de leitura). citeturn0search2turn0search20turn0search14turn0search11  
   - Tente reconstruir até a leitura padrão ser possível (decoder QR normal).

4) **Validação TEIA**  
   - Decodificado o payload, use sua pipeline TEIA para:
     - Checar SHA256 do seed.  
     - Restaurar o pacote alvo.  
     - Registrar no log TEIA que o seed foi recuperado a partir de um “QR degradado + inferência neural”.

5) **Iterar para “abuso”**  
   - Aumentar densidade, piorar ainda mais a degradação, e medir:
     - Até onde o pipeline neural consegue ir.  
     - Quanto da “segurança por obscuridade física” você ganha (um QR que parece ruído para leitor comum, mas é decodificável para quem tem o pipeline TEIA correto).

---

Se quiser, o próximo passo pode ser: escolher um seed TEIA pequeno real seu, e eu desenho um experimento mínimo mais específico (incluindo formatos de payload, layout de metadados e critérios de sucesso) para testar esse conceito de **Neural-QR Seed** na prática.

---

### USUÁRIO

prossiga

---

### ASSISTENTE

Vou avançar transformando a ideia do Neural-QR Seed em um experimento mínimo bem definido, pronto para virar script quando você quiser.

---

## 1. Fixar o objetivo desta primeira iteração

Objetivo concreto deste experimento:

> Conseguir restaurar um seed TEIA real (manifesto + hashes) a partir de um QR propositalmente degradado, usando:
> 1) leitor QR clássico, e  
> 2) o mesmo QR passado antes por uma etapa “neural” de recuperação de imagem.

Se 2) funcionar em casos em que 1) falha, você tem a prova prática da ponte “Neural-QR Seed”.

---

## 2. Escolha do seed TEIA para o teste

Para não abrir mais frentes do que o necessário, a primeira iteração pode usar algo que você já tem:

- Um dos seus pacotes pequenos e bem auditados, por exemplo:
  - `teia_micro_knowledge_20250827_185022.zip`  
  ou  
  - um manifesto minimalista + `SHA256` apontando para um ZIP maior.

O que importa não é o tamanho do pacote “final”, e sim o tamanho do **seed lógico** que vai para o QR.

### 2.1. Seed lógico recomendado

Formato sugerido:

- `seed.bin` – um blob compacto que contém:
  - Manifesto criptografado + hashes,  
  - Versão do formato,  
  - Opcionalmente uma pequena instrução humana (curta) para restaurar.

Você pode gerar o `seed.bin` hoje pela sua pipeline TEIA atual, sem envolver QR nem rede neural ainda.

---

## 3. Formato do payload antes de virar QR

Antes de ir para o QR, vale padronizar um formato de payload que não dependa da tecnologia de QR.

Por exemplo, um JSON compacto que descreve o seed e carrega o conteúdo em base64:

```json
{
  "t": "TEIA_SEED",
  "v": "0.1",
  "algo": "BROTLI+SHA256",
  "sha256": "HEX_DO_SEED_BIN",
  "len": 123456,
  "name": "teia_nucleo_procedural_0.1",
  "payload_b64": "AAA...AAA"
}
```

Notas:

- `payload_b64` é o `seed.bin` comprimido e codificado em base64.
- Este JSON pode ser comprimido de novo (ex. Brotli) antes de ir para o QR, se precisar de mais densidade.
- Manter `t`, `v`, `algo`, `sha256` e `len` te dá:
  - Autodescrição mínima do formato,
  - Verificação de integridade total ao restaurar.

---

## 4. Pipeline QR “baseline” (sem rede neural ainda)

Etapas para ter uma linha de base clara:

1. Gerar o payload final (string ou bytes) a partir do JSON acima (possivelmente comprimido).  
2. Usar qualquer lib/ferramenta de QR para gerar:
   - Versão alta (ex.: 20+),
   - ECC baixo/médio (para aumentar densidade),
   - Sem padding gráfico desnecessário.

3. Gerar três variantes de degradação:
   - A) QR perfeito (imagem PNG nítida) – controle.  
   - B) QR com downscale/upscale (blur moderado).  
   - C) QR com blur forte + compressão JPEG agressiva + ruído leve.

4. Testar com leitores QR clássicos (celular, libs CLI, etc.):
   - Registrar:
     - Em quais condições o QR ainda é lido diretamente,  
     - Em quais condições começa a falhar.

5. Em paralelo, sempre que um QR for lido:
   - Decodificar o payload,  
   - Verificar `sha256` do `seed.bin` e, se bater, tentar restaurar o pacote TEIA correspondente.  
   - Logar: sucesso/erro + nível de degradação.

Isso já te dá um mapa de “limite físico” sem rede neural.

---

## 5. Camada Neural: onde ela entra no fluxo

A camada neural não precisa entender TEIA, só precisa entregar um **bitmap de QR mais legível** para o decodificador clássico.

Pipeline conceitual:

1. Você captura uma imagem degradada (B ou C).  
2. Passa essa imagem por uma pipeline de imagem com 3 blocos lógicos:
   - Super-resolução (SR) específica ou afinada para padrões de QR;  
   - Retificação geométrica (corrigir perspectiva, curvatura, etc.);  
   - Denoising / de-artifact (tentar limpar JPEG/ruído).

3. A saída dessa pipeline é uma imagem reconstruída, enviada ao mesmo leitor QR clássico que você já usou no baseline.

Resultados esperados:

- Em casos em que o leitor clássico falhou na imagem bruta, ele pode conseguir ler a versão pós-SR/retificação.  
- Quando ele ler, você aplica exatamente a mesma validação TEIA (JSON → seed.bin → SHA256 → restauração).

Você não precisa, nessa primeira rodada, treinar do zero um modelo. Pode começar com:

- Modelos genéricos de super-resolução + ferramentas de correção geométrica,
- E testar se já há ganho antes de chegar em um “modelo treinado só para QR”.

---

## 6. Métricas e matriz de teste

Para que esse experimento seja epistêmico e não apenas “funcionou uma vez”, é útil montar uma matriz simples:

### 6.1. Eixos principais

- Nível de degradação:
  - 0 = sem degradação (controle),
  - 1 = blur leve,
  - 2 = blur + JPEG forte,
  - 3 = blur + JPEG forte + ruído extra.

- Densidade do QR:
  - Versão / nível de ECC (ajuste fino depois; para o teste inicial você pode fixar 1 configuração e variar principalmente a degradação).

- Resultado:
  - Lido por leitor clássico (sim/não) ANTES da camada neural,  
  - Lido por leitor clássico (sim/não) DEPOIS da camada neural,  
  - `sha256` bateu / não bateu no `seed.bin`,  
  - Restauração TEIA ok / falha.

Com isso, você consegue enxergar claramente:

- Em quais regiões da degradação a camada neural está, de fato, recriando bits “perdidos”,  
- Até que ponto vale aumentar a densidade do QR aceitando que apenas quem tem a pipeline neural + TEIA consegue recuperar.

---

## 7. Integração com a TEIA (logs e ontologia)

Para encaixar isso no seu ecossistema TEIA / auditoria:

### 7.1. Tipos de eventos sugeridos

- `SEED_QR_ENCODED`  
  - Campos: `seed_id`, `sha256_seed`, `qr_version`, `qr_ecc`, `payload_len`, `time`.

- `SEED_QR_CAPTURED`  
  - Campos: `seed_id`, `image_id`, `degradation_level`, `device`.

- `SEED_QR_DECODE_BASELINE`  
  - Resultado: `success/fail`, `error_code`, `decoder_name`.

- `SEED_QR_DECODE_NEURAL`  
  - Campos extra: `model_pipeline_id`, `sr_steps`.  
  - Resultado: `success/fail`, `error_code`.

- `SEED_QR_RESTORE_RESULT`  
  - Campos: `sha256_ok` (bool), `restore_ok` (bool), `time_ms`, `host_id`.

Na ontologia TEIA, isso pode ser amarrado como:

- `Seed` → `temRepresentacaoFisica` → `QRCode`  
- `QRCode` → `submetidoA` → `PipelineNeural`  
- `PipelineNeural` → `melhoraTaxaLeitura` → `%`  

Ou seja: o próprio experimento vira conhecimento.

---

## 8. Extensões naturais (para depois do MVP)

Assim que a primeira prova funcionar, algumas extensões quase automáticas:

1. **Multi-QR constellation**  
   - Dividir o payload em blocos (`chunk_0`, `chunk_1`, …), cada um com seu QR.  
   - Cada QR carrega: `seed_id`, `chunk_index`, `total_chunks`, `sha256_chunk`.  
   - Permite seeds maiores e tolerância a perda de alguns QRs.

2. **Camada criptográfica**  
   - O payload do QR poderia vir já criptografado com chave derivada da sua ontologia/identidade, mantendo só o manifesto público.

3. **Perfis de “robustez”**  
   - Ex.: Perfil “campo duro” (para papel que pode molhar/rasgar) vs “urbano” (adesivo em eletrônicos) com níveis diferentes de redundância.

---

## 9. Próximo passo concreto

Para “travar” o próximo movimento de forma objetiva:

1) Escolher qual seed real (entre os que você já tem) será o `seed.bin` do experimento.  
2) Congelar o formato final do JSON do payload (nome de campos, versão, etc.).  
3) Definir quais 3 níveis de degradação você quer testar primeiro (0, 1, 2 ou 0, 2, 3).  

Quando você me disser:

- “Seed escolhido é X”  
- “Formato final do JSON é este”  
- “Níveis de degradação-alvo são A, B, C”

eu posso, na próxima resposta, já transformar isso num plano direto para script (PowerShell + ferramentas auxiliares que você preferir), seguindo o seu padrão TEIA de `textdoc embed Codex` e fluxo idempotente.

---

### USUÁRIO

forneça a última geração sabendo que só explorarei esse assunto novamente se ele latejar em processamentos de chats futuros

---

### ASSISTENTE

Segue a “última geração” condensada desse fio: um artefato conceitual pronto para ser reativado no futuro se fizer sentido.

---

## 1. Nome e objetivo

**Neural-QR Seed TEIA v0.1**

Objetivo:  
Definir um formato mínimo de seed TEIA + protocolo de QR + teste de recuperação neural que:

1. Codifica um núcleo TEIA (manifesto + hashes) em um payload pequeno.  
2. Transfere esse payload via QR potencialmente degradado.  
3. Demonstra que uma camada de recuperação “neural” (super-res + correção) permite leitura e restauração em casos em que o QR bruto falha.

---

## 2. Seed lógico (o que é realmente preservado)

### 2.1. Arquivo base

- Arquivo físico: `seed.bin`  
- Conteúdo (conceitual, não precisa estar implementado agora):

  1) Cabeçalho:
     - Magic: `TEIASEED` (8 bytes)  
     - Versão: `0x0001` (2 bytes)  

  2) Metadados:
     - `seed_id` (UUID v4, 16 bytes)  
     - `algo_compactacao` (ex.: enum: `0x01=BROTLI`, `0x02=ZIP`)  
     - `algo_hash` (ex.: enum: `0x01=SHA256`)  
     - `tamanho_payload` (8 bytes, inteiro)  

  3) Payload:
     - Manifesto TEIA comprimido + hashes dos artefatos que serão restaurados.

Nada impede você de, no futuro, adicionar criptografia; a v0.1 assume plaintext comprimido.

---

## 3. Payload canônico antes do QR

Para manter autodescrição e compatibilidade futura, o conteúdo de `seed.bin` é espelhado em um JSON compacto, que será o payload lógico do QR:

```json
{
  "t": "TEIA_SEED",
  "v": "0.1",
  "seed_id": "UUID",
  "algo_comp": "BROTLI",
  "algo_hash": "SHA256",
  "sha256_seed": "<HEX_DO_SEED_BIN>",
  "len_seed": 123456,
  "name": "teia_nucleo_procedural_0.1",
  "payload_b64": "AAA...AAA"
}
```

Fluxo conceitual:

1. Você gera `seed.bin`.  
2. Calcula `sha256_seed`.  
3. Codifica `seed.bin` em base64 → `payload_b64`.  
4. Embala tudo nesse JSON.  
5. Opcionalmente, comprime o JSON com Brotli antes de enviar ao QR (modo byte).

---

## 4. Perfil QR v0.1

Parâmetros sugeridos para o experimento inicial (ajustáveis depois):

- **Modo:** QR em modo byte (8-bit).  
- **ECC:** nível baixo/médio (ex.: Q), para permitir maior densidade.  
- **Tamanho alvo de payload comprimido:** até ~1–2 KB de dados binários (após Brotli).  
- **Visual:** sem logos, sem margem extra, apenas quiet zone mínima.

A v0.1 assume **um único QR** por seed (sem fragmentação multi-QR ainda).

---

## 5. Protocolo experimental mínimo

### 5.1. Fase 0 – Geração de referência

1. Gerar `seed.bin` a partir de um pacote TEIA real (mínimo).  
2. Gerar o JSON canônico com `payload_b64` e `sha256_seed`.  
3. Comprimir o JSON (opcional, mas recomendado) → `payload_qr.bin`.  
4. Gerar o QR a partir de `payload_qr.bin` com os parâmetros da seção 4.  
5. Salvar:
   - PNG perfeito do QR (controle),  
   - Manifesto experimental (texto) descrevendo todos os parâmetros usados.

### 5.2. Fase 1 – Baseline sem neural

Criar 3 níveis de degradação sobre o QR perfeito:

- Nível 0: sem degradação (controle).  
- Nível 1: blur leve + downscale/upscale.  
- Nível 2: blur médio + JPEG forte + um pouco de ruído.

Para cada nível:

1. Testar leitura com leitor QR clássico (celular, lib padrão etc.).  
2. Se decodificar:
   - Reverter a compressão de `payload_qr.bin` (se tiver),  
   - Parsear JSON, recriar `seed.bin` a partir de `payload_b64`,  
   - Verificar `sha256_seed`,  
   - Tentar restaurar o pacote TEIA e registrar sucesso/falha.

Resultado: mapa “até onde o QR aguenta sem ajuda neural”.

### 5.3. Fase 2 – Camada Neural

Nos níveis em que o leitor clássico começa a falhar (por ex. Nível 2 ou além):

1. Passar a imagem degradada por um pipeline “neural”:
   - Super-resolução + sharpen;  
   - Correção de perspectiva/warp;  
   - Denoise limitado para não apagar padrões finos.

2. Enviar a saída deste pipeline para o mesmo leitor QR clássico.  
3. Repetir o fluxo de validação TEIA (JSON → `seed.bin` → SHA256 → restauração).  

Marcador de sucesso específico:

> “Houve pelo menos um caso onde a imagem original degradada falhou no leitor clássico,  
> mas a imagem pós-pipeline neural foi lida e permitiu restauração TEIA com `sha256_seed` correto.”

Isso é a prova funcional v0.1 do conceito Neural-QR Seed.

---

## 6. Eventos e telemetria TEIA (modelo mínimo)

Para o log TEIA, basta um vocabulário mínimo de eventos (nomes podem ser adaptados depois):

1. `SEED_QR_GENERATED`
   - Campos: `seed_id`, `sha256_seed`, `qr_version`, `qr_ecc`, `payload_size`, `time`.

2. `SEED_QR_DEGRADED`
   - Campos: `seed_id`, `image_id`, `degradation_level`, `ops_aplicadas`.

3. `SEED_QR_DECODE_BASELINE`
   - Campos: `seed_id`, `degradation_level`, `success` (bool), `decoder`.

4. `SEED_QR_DECODE_NEURAL`
   - Campos: `seed_id`, `degradation_level`, `success` (bool), `pipeline_id`, `steps`.

5. `SEED_QR_RESTORE_RESULT`
   - Campos: `seed_id`, `sha256_ok` (bool), `restore_ok` (bool), `host_id`, `time_ms`.

Com isso, qualquer futura auditoria (humana ou por agente) consegue reconstruir a história de um seed específico.

---

## 7. Critério de encerramento da v0.1

Você pode considerar o experimento Neural-QR Seed TEIA v0.1 “encerrado e válido” quando:

1. Existir pelo menos um `seed_id` com:
   - Geração registrada,  
   - Tentativas de leitura em múltiplos níveis de degradação,  
   - Pelo menos um cenário em que:
     - `SEED_QR_DECODE_BASELINE.success = false`,  
     - `SEED_QR_DECODE_NEURAL.success = true`,  
     - `SEED_QR_RESTORE_RESULT.sha256_ok = true` e `restore_ok = true`.

2. O manifesto experimental correspondente estiver salvo como parte dos artefatos TEIA (mesmo que só localmente).

Isso basta para consolidar a ponte conceitual que você estava buscando:  
seed procedural TEIA ⇄ QR físico degradado ⇄ camada neural ⇄ restauração íntegra.

---

Se em algum futuro chat esse tema voltar a pulsar, este é o ponto de retomada: “Neural-QR Seed TEIA v0.1” já tem objetivo, formato e protocolo definidos; o próximo passo natural seria escolher um `seed_id` real do seu ecossistema TEIA e transformar este esquema em scripts concretos.

---

