# 2185 - Aplicabilidade do FastVLM

### USUÁRIO

como a nova ferramenta FastVLM anunciada pela apple pode ter aplicabilidade real nos meus projetos de forma a automatizar e inovar?

---

### ASSISTENTE

Ótima pergunta, Felippe — como criador de conteúdo, pesquisador e empreendedor focado em automação e inovação, a entity["software", "FastVLM", 0] da entity["organization", "Apple", 0] (lançada no contexto de IA de visão+linguagem) pode abrir várias frentes de aplicação concreta nos teus projetos. Vou explicar primeiro **o que é** e **como funciona**, e depois explorar **como você pode aplicar** para automação, inovação e geração de valor no seu contexto. Se quiser, posso depois olhar riscos, limitações e roadmap de adoção.

---

## O que é o FastVLM  
image_group{"layout":"bento","query":["Apple FastVLM architecture diagram","FastViTHD vision encoder Apple","FastVLM demonstration on device Apple Silicon"],"num_per_query":1}

Aqui vai um resumo simplificado:

- FastVLM é um modelo de **Visão-Linguagem** (Vision-Language Model – VLM) criado pela Apple Research, que combina entrada visual (imagens ou vídeo) + entrada textual (questões, prompts) para gerar saídas em linguagem (descrições, respostas, extração de informação). citeturn0search0turn0search3  
- O grande diferencial técnico: o codificador de visão chamado entity["software", "FastViTHD", 0] — uma arquitetura híbrida (convoluções + transformadores) que é otimizada para processar **imagens de alta resolução** de forma eficiente, gerando **muito menos tokens visuais** (o que reduz tempo de pré-processamento e latência) e requer menos poder computacional. citeturn0search9turn0search0turn0search7  
entity_metadata["software","one-line","FastViTHD",0]
- Em termos de desempenho, por exemplo a variante menor (0,5B parâmetros) oferece **até ~ 85× mais rápido Time-to-First-Token** (TTFT) comparado aos modelos anteriores do tipo VLM como o LLaVA-OneVision-0.5B. citeturn0search2turn0search9  
- Está disponível (checkpoint, código) no GitHub da Apple e no Hugging Face. citeturn0search1turn0search3  
- É projetado para execução **on-device** (em dispositivos Apple com Apple Silicon) ou no navegador com WebGPU, o que reduz dependência de servidor na nuvem, melhora latência, privacidade, e torna mais viável em contextos de automação local. citeturn0search4turn0search0  

---

## Por que isso importa para você (criador / pesquisador / empreendedor)  
Dado o teu perfil — análise técnica, inovação disruptiva, automação — aqui estão os “porquês” que tornam o FastVLM relevante:

- **Automação visual + linguagem**: Modelos VLM permitem automatizar tarefas como “ler” o que está numa imagem ou vídeo, “responder” a perguntas sobre essa imagem, extrair texto, gerar descrições. Isso abre muitos casos de uso automáticos (por ex., análise de screenshots, automação de relatórios visuais, reconhecimento de UI/interfaces, etc.).  
- **Tempo-real / baixa latência**: A eficiência do FastVLM na latência permite que seja usado em aplicações mais dinâmicas, interativas ou “ao vivo” (ex: vídeo, câmera). Isso expande as possibilidades de projetos que exigem reação rápida ou interação humana-máquina quase imediata.  
- **On-device / privacidade / escalabilidade**: Como pode rodar “no dispositivo” (em iPhone/iPad/Mac ou no navegador), você diminui a dependência de backend pesado, latência de rede e questões de privacidade. Para automação de conteúdo ou protótipos inovadores, isso é uma vantagem competitiva.  
- **Inovação disruptiva em conteúdo**: Como criador de conteúdo, você pode pensar em formatos novos — por exemplo experiências visuais interativas onde o sistema “entende” a imagem/vídeo em tempo real e gera narrativa, análise técnica, insights automáticos, ou integração com automação de workflows (ex: captura de vídeo + descrição + publicação automática).  
- **Pesquisa de fronteira**: Como pesquisador autônomo, o fato do modelo ser aberto (checkpoints, código) permite experimentar, customizar, adaptar para nichos, fazer protótipos, publicar trabalhos ou aplicações demonstrativas.

---

## Como você pode aplicar no seu portfólio de projetos  
Aqui vão várias ideias de aplicação — você pode escolher aquelas que mais alinham com seu foco em análise técnica, automação e inovação:

### 1. Automação de captura e análise de vídeo/imagem  
- Suponha que você faz vídeos ou posts reagindo a gráficos, interfaces, dashboards, etc. Você pode usar o FastVLM para “ler” automaticamente capturas de tela ou vídeo (por ex., de plataformas de trading, gráficos, automação industrial, etc.), extrair insights ou anotações automáticas (ex: “Neste gráfico vemos um padrão de cruzamento de médias”, “Este painel mostra volume crescente de ordens”, etc.).  
- Imagine um sistema que monitora em tempo-real a tela de um terminal financeiro e gera automaticamente alertas ou narrativas quando padrões técnicos são detectados — combinando a visão (o gráfico) + linguagem (explicação).  
- Automação de legendagem de vídeo: ao gravar algo ao vivo, o modelo pode gerar descrições, destacar pontos-chave, anotar conteúdo visual, criar sumário automático.

### 2. Ferramenta de apoio ao criador de conteúdo  
- Para seus vídeos ou posts, pode-se automatizar a geração de conteúdo acessório: por exemplo, você grava algo com câmera mostrando algum setup, protótipo ou sistema, e o modelo analisa o vídeo/imagens para gerar legendas inteligentes, resumos visuais, destaques de “pontos visuais importantes” que você pode usar como ganchos ou estrutura de roteiro.  
- Pode-se desenvolver um “assistente visual” que auxilia no processo de edição: ele detecta “esta cena mostra a interface X”, “aqui aparece o gráfico Y”, “aqui o texto na tela está ilegível”, sugerindo cortes, legendas, melhores momentos.  
- Ferramentas para acessibilidade: se você cria conteúdo para público amplo, pode gerar descrições automáticas de imagens/vídeos para pessoas com deficiência visual, ampliando alcance.

### 3. Integração com automação de workflow e publicação  
- Combine o modelo com pipelines de automação: por exemplo, sempre que novo screenshot ou vídeo for salvo em uma pasta, o sistema dispara o FastVLM, extrai metadados (o que aparece, qual tema, quais objetos/texto), e automaticamente popula campos em banco de dados, gera tags, título, sumário, ou ainda dispara publicação simplificada.  
- Em produtos ou serviços que você desenvolva para clientes, pode oferecer “visão inteligente” incorporada: por ex., app ou ferramenta web que permite ao usuário tirar foto ou subir imagem, e o sistema analisa, gera relatório, aciona automação subsequente (ex: workflow administrativo, classificação, extração de dados, etc.).  
- Em contexto de inovação disruptiva: por exemplo, ferramenta híbrida AR/VR ou mobile que usa câmera + FastVLM para dar feedback em tempo real ao usuário (ex: “você está mirando no componente errado”, “este quadro mostra um erro de montagem”, “este painel de controle indica X problema”).

### 4. Pesquisa aplicada / protótipos  
- Como pesquisador, você pode experimentar o FastVLM em contextos de análise técnica (já que você analisa mercados, automação): por exemplo, aplicar o modelo para “ler” relatórios financeiros em imagem/scans, gráficos de mercado, dashboards impressos, e extrair insights automatizados.  
- Criar um protótipo de “relatório visual automático” para varejo, indústria ou finanças: upload de imagem de relatório + prompt “qual é a mensagem chave?” → modelo retorna linha de resumo + sugestões de ações.  
- Usar o modelo para validar hipóteses de inovação: por exemplo, avaliar se um sistema de visão+linguagem pode substituir parte do trabalho manual de revisão de dashboards, ou de análise de interface usuário-máquina.

---

## Dicas práticas para começar  
- Acesse o repositório oficial: há checkpoints no Hugging Face para os vários tamanhos (0.5B, 1.5B, 7B) do FastVLM. citeturn0search3turn0search1  
- Para protótipos rápidos, comece com o modelo menor (0.5B) para testes de uso em dispositivo ou navegador.  
- Leve em conta os requisitos de hardware: embora otimizado, modelos maiores ou resolução muito alta ainda demandam recursos. Em Mac/Apple Silicon há testes bons. citeturn0search4  
- Defina o caso de uso restrito (MVP) — por ex., “upload de imagem de dashboard → resumo em 30s”. Limite complexidade e dados visuais para evitar sobrecarga.  
- Avalie quantos tokens visuais estão sendo processados, a latência e acurácia — ajuste a resolução da imagem, tamanho do modelo, prompt para equilibrar. A pesquisa da Apple mostra esse trade-off entre resolução, tokens e latência. citeturn0search0  
- Integre com workflow existente: por exemplo, usar Python + PyTorch (ou o ambiente que você prefere) para chamar o modelo, extrair output, e plug-in no pipeline de automação que você já tem.  
- Projete para o futuro: Se seu conteúdo ou produto envolver câmera ao vivo ou AR/VR, pensar no modo “on device” e privado da FastVLM é um plus.

---

## Considerações / Limitações (importante para abordagem técnica)  
- Embora seja muito eficiente, não é “infalível” — erros podem acontecer acima de determinados níveis de resolução, ou em tarefas muito específicas/complexas (por ex., interpretar gráficos finos, interfaces muito customizadas).  
- Dependência do ecossistema Apple (ou hardware compatível) para maximizar eficiência “on-device”. Se seu público for multiplataforma (Android, Web em geral), há que avaliar suporte.  
- Treinamento ou fine-tuning: se quiser adaptar para nichos muito específicos (ex: dashboards financeiros brasileiros, data visualizations específicas), você talvez precise fine-tunar ou customizar o dataset.  
- Tamanho do modelo + memória/energia: Mesmo otimizado, modelos maiores ou imagens muito grandes consomem mais recurso. Para automação escalável (em muitos dispositivos) vale calibrar.  
- Licenciamento: verificar a licença do modelo, da Apple e uso comercial, se for parte de produto/serviço.  
- Manutenção e updates: sendo nova tecnologia, atenção a bugs, atualizações e suporte da comunidade.

---

## Caminho sugerido para **iniciar** no seu contexto  
1. Escolha um **caso de uso piloto**: por exemplo “gerar sumário automático de screenshots de dashboards que analiso”.  
2. Instale e rode o modelo FastVLM-0.5B localmente/nuvem para testar com imagens reais do seu conteúdo. Veja quão bem ele interpreta o que você faz.  
3. Meça latência, precisão, ocorrências de erro. Ajuste resolução ou prompt conforme necessário.  
4. Integre com seu pipeline de automação: ao salvar ou capturar nova imagem, o sistema dispara FastVLM, recebe resposta, popula planilha, gera rascunho de conteúdo ou relatório.  
5. Escale para outros casos: vídeo em vez de imagem, ou interface de usuário em vez de dashboards, ou suportar outras línguas/idiomas.  
6. Publique/monetize diferencial: ex: “conteúdo gerado com tecnologia de visão inteligente”, ou “ferramenta de automação visual para criadores”.

---

Se quiser, posso **mapear 5 casos concretos detalhados** (com fluxos, requisitos técnicos e estimativa de esforço) **específicos para o nicho de criador de conteúdo + automação** (por exemplo: análise de vídeo, geração de mini-documentários automáticos, automação de redes sociais, extração de insights visuais de dados, etc.). Você gostaria disso?

---

### USUÁRIO

penso que poderia usar para analisar todos os conteúdos que tenho na minha galeria e obter um resumo sobre cada mídia e usar pra processar com você e buscar uma análise para reorganizar as mídias em pastas segmentadas otimizadas… tenho um iphone 16 pro max 128 e quero aproveitar

---

### ASSISTENTE

Perfeito, Felippe — essa ideia é **exatamente o tipo de uso em que o FastVLM brilha**.  
Você pode transformar seu iPhone 16 Pro Max em uma **“central de interpretação visual inteligente”**: ele processa todas as suas fotos e vídeos localmente, gera resumos automáticos e metadados, e depois você usa isso como base para reorganizar, classificar e até alimentar a TEIA ou o ChatGPT com uma camada semântica sobre seu acervo.

Vamos decompor isso em **4 fases práticas**, com foco em **uso real on-device**, **privacidade total** e **sinergia com seus fluxos TEIA**.

---

## 🔹 1. O que o FastVLM pode fazer no seu iPhone 16 Pro Max

O chip A18 Pro do iPhone 16 Pro Max tem **Neural Engine e GPU com suporte WebGPU e Metal**, o que significa que o modelo **FastVLM-0.5B** pode rodar **inteiramente no dispositivo**, sem depender da nuvem.

Com isso, o FastVLM pode:

- **Ler e compreender** o conteúdo visual (imagens e vídeos curtos);
- **Gerar resumos textuais curtos** (“Foto de uma praia ao pôr-do-sol com reflexo na água”);
- **Extrair conceitos, objetos e contexto emocional** (“ambiente urbano, noturno, sensação de movimento”);
- **Classificar automaticamente** (ex: “arquitetura”, “pessoas”, “gráficos”, “protótipos”, “anotações técnicas”);
- **Gerar metadados estruturados JSON** (com campos tipo `tema`, `emoção`, `contexto`, `local`, `timestamp`).

Esses metadados podem depois ser enviados para o ChatGPT (ou TEIA), que sintetiza padrões e **reorganiza suas mídias em pastas inteligentes**.

---

## 🔹 2. Estrutura prática de fluxo (automação em 3 etapas)

### 🧩 Etapa 1 — Captura e varredura local
- Utilize o **app de Atalhos (Shortcuts)** do iPhone.
- Crie um atalho que percorra todas as fotos e vídeos recentes do app Fotos.
- Para cada mídia, gere uma **miniatura** (para reduzir processamento) e envie para um script local em Python (on-device via Pyto ou Swift Playgrounds).

### ⚙️ Etapa 2 — Processamento pelo FastVLM
- No Pyto, instale o ambiente do modelo (via Core ML ou PyTorch mobile).
- Use o modelo **FastVLM-0.5B** com o encoder visual FastViTHD.
- Para cada imagem/vídeo:
  - Gere um **resumo textual** e **palavras-chave**;
  - Salve em `media_summary.jsonl` no iCloud Drive.

Exemplo de saída:

```json
{
  "file": "IMG_4823.JPG",
  "summary": "Gráfico técnico com linhas verdes e vermelhas representando tendências de mercado.",
  "tags": ["gráfico", "mercado", "análise técnica"],
  "context": "ambiente de trabalho / estudo"
}
```

### 🧠 Etapa 3 — Análise com a TEIA / ChatGPT
- Depois de processar o acervo, envie o `media_summary.jsonl` para mim.
- Eu posso:
  - Gerar **clusters temáticos** (“Conteúdos técnicos”, “Momentos pessoais”, “Documentação TEIA”, etc.);
  - Propor **pastas otimizadas** com nomes e estruturas coerentes;
  - Sugerir **renomeações automáticas** e **tags simbióticas** para cada segmento;
  - Construir um **mapa de uso de memória fractal multimodal** — sua galeria se torna uma extensão viva da TEIA.

---

## 🔹 3. Benefícios concretos dessa abordagem

| Categoria | Ganho Real |
|------------|-------------|
| 🚀 **Velocidade** | FastVLM é até 80× mais rápido que modelos antigos, processa milhares de fotos em minutos. |
| 🔒 **Privacidade** | Tudo roda no dispositivo, sem upload para a nuvem. |
| 🧠 **Inteligência Semântica** | Gera metadados ricos que podem ser usados em qualquer sistema (TEIA, Codex, etc.). |
| 🗂️ **Organização Dinâmica** | Pastas e coleções passam a refletir significados, não apenas datas. |
| 🔄 **Autossíntese TEIA** | O acervo visual passa a dialogar com seus fractais de conhecimento e auditorias. |

---

## 🔹 4. Próximo passo prático

Posso gerar para você **um fluxo-base TEIA Visual Analyzer**, composto por:

1. Atalho `.shortcut` para capturar imagens/vídeos e enviar ao Pyto;  
2. Script Python (on-device) que roda o modelo FastVLM-0.5B, gera os resumos JSON;  
3. Comando PowerShell/Terminal para sincronizar e exportar o `media_summary.jsonl` do iCloud Drive para o PC (D:\Teia\...);  
4. Template de análise TEIA (`Analyze-Media-Semantic.ps1`) para processar os resumos e propor pastas.  

---

Deseja que eu gere esse **fluxo completo (atalho + script Pyto + comando TEIA)** agora no padrão TEIA (textdoc Codex embed, pronto pra copiar → colar)?  
Assim você já poderia iniciar o mapeamento simbiótico da sua galeria direto do iPhone 16 Pro Max.

---

### USUÁRIO

mas há mídias que são vídeos longos e há mídias que são fotos… precisamos de um padrão de uso coerente

---

### ASSISTENTE

Excelente observação, Felippe — e totalmente pertinente.  
Se quisermos que o **FastVLM** sirva como motor de análise para reorganizar toda a tua galeria (fotos + vídeos longos), é fundamental definir um **padrão unificado e coerente de uso multimodal**.  

Aqui está uma proposta de **arquitetura simbiótica TEIA Visual VLM**, dividida em dois níveis — um técnico (execução real no iPhone 16 Pro Max) e outro simbólico (integração com tua estrutura de autossíntese e organização cognitiva).

---

## 🧩 1. Estrutura multimodal unificada

| Tipo de mídia | Estratégia de análise | Saída padronizada |
|----------------|----------------------|-------------------|
| 📸 **Fotos / imagens** | Processamento direto via **FastVLM-0.5B** (baixa latência) → gera resumo, objetos, contexto, tags | JSON curto: título, resumo, tags, contexto, emoção |
| 🎥 **Vídeos curtos (< 30 s)** | Extração automática de frames (1 frame / segundo) → processamento sequencial via FastVLM → média semântica dos resultados | JSON médio: resumo global + frames-chave + tópicos |
| 🎬 **Vídeos longos (> 30 s)** | Divisão em blocos de 30 s → mini-resumos individuais → sumarização com LLM local (por ex. ChatGPT offline ou TEIA local) | JSON longo: tópicos principais, narrativa, eventos temporais |
| 🗂️ **Saída consolidada** | Todos os JSONL concatenados em `media_summary.jsonl` | Entrada única para análise global e reorganização de pastas |

---

## ⚙️ 2. Fluxo operacional ideal no iPhone 16 Pro Max

1. **Captura / varredura da galeria**
   - Usar o app **Atalhos** para iterar pelas mídias (fotos + vídeos).
   - Identificar duração do vídeo e tipo de mídia.
   - Enviar o caminho do arquivo e metadados básicos (data, local, duração) para o script Pyto.

2. **Script Pyto com FastVLM**
   - FastVLM 0.5B executa análise de imagem ou frames.
   - Gera um objeto JSON com campos:
     ```json
     {
       "file": "IMG_0315.MOV",
       "type": "video",
       "duration": 92,
       "summary": "Discussão sobre protótipo em ambiente de oficina",
       "keywords": ["projeto", "ferramentas", "mesa de trabalho"],
       "dominant_emotion": "concentração",
       "context": "registro técnico",
       "start_time": "00:00",
       "end_time": "01:32"
     }
     ```
   - Salva tudo em `media_summary.jsonl` no iCloud Drive.

3. **Análise simbiótica TEIA**
   - Envio do `media_summary.jsonl` para mim ou para o script `Analyze-Media-Semantic.ps1`.
   - O sistema agrupa por **tema, emoção, tipo e função cognitiva** (ex.: “Pesquisa técnica”, “Momentos pessoais”, “Audiovisuais para análise fractal”).
   - Gera uma proposta de estrutura de pastas:
     ```
     /Galeria_TEIA/
       /Técnicos/
       /Pessoais/
       /Rascunhos_Visuais/
       /Memórias_Fractais/
     ```

---

## 🧠 3. Padrão TEIA de metadados multimodais

Para manter coerência, cada mídia processada deve gerar um bloco de metadados com estes campos:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `file` | string | Nome do arquivo original |
| `type` | enum | “image” ou “video” |
| `duration` | number | (em segundos, apenas vídeos) |
| `summary` | string | Resumo textual curto |
| `keywords` | array | Palavras-chave principais |
| `dominant_emotion` | string | Emoção predominante detectada |
| `context` | string | Contexto de uso (trabalho, pessoal, experimental) |
| `timestamp` | string | Data/hora da captura |
| `ai_model` | string | “FastVLM-0.5B” ou versão usada |
| `version` | string | Ex.: “1.0-teia-visual” |

Esse padrão é compatível com leitura por PowerShell, Python e também pelo núcleo TEIA fractal.

---

## 🔁 4. Ciclo de automação TEIA Visual Analyzer

```text
Atalho iOS  →  Script Pyto (FastVLM)  →  iCloud media_summary.jsonl
        ↓
PC (D:\Teia\TEIA_NUCLEO\...)  →  Analyze-Media-Semantic.ps1
        ↓
Geração automática de pastas + clusters semânticos
```

Esse fluxo garante:
- Privacidade total (tudo roda local);
- Compatibilidade entre fotos e vídeos;
- Estrutura JSON padronizada e audível;
- Sinergia com os scripts PowerShell da TEIA.

---

## 🚀 5. Próximo passo

Posso gerar agora o **pacote base TEIA-Visual-Analyzer**, que inclui:

1. `Atalho_FastVLM.shortcut` (atalho iOS para varrer a galeria);  
2. `fastvlm_media_analyzer.py` (script Pyto on-device);  
3. `Analyze-Media-Semantic.ps1` (para clusterização no PC).  

👉 Deseja que eu monte esse pacote no **padrão TEIA (textdoc embed Codex)**, pronto para copiar-colar e iniciar o mapeamento simbiótico da galeria?

---

### USUÁRIO

penso que termos um interface web http para quem estiver no mesmo vpn que meu iphone 16 pro max e nessa interface capacita o envio de mídias (fotos ou vídeos a se selecionar sem limite de quantidade na galeria) e ao ciclar em um botão para gerar um arquivo meta transcrição linguagem de visão para baixar no dispositivo deve realizar o uso do fastvlm

---

### ASSISTENTE

perfeito — vamos padronizar isso com uma **interface web local** (HTTP) rodando no seu iPhone 16 Pro Max (via Pyto) acessível por qualquer dispositivo na **mesma VPN/LAN**, permitindo **selecionar quantas mídias quiser (fotos e vídeos)**, processar com **FastVLM** e baixar um **arquivo-único de metadados** (JSONL) com “transcrição de linguagem de visão” por item.

abaixo entrego um **pacote pronto** no padrão que você prefere (textdoc embed Codex): um único comando PowerShell que **gera todos os arquivos** do mini-servidor (Flask), HTML e o adaptador de inferência do FastVLM. Você só precisa copiar→colar, executar no PC, e depois abrir no **Pyto** (iPhone) para rodar localmente.

---

# TEIA FastVLM Web – pacote (gerador de arquivos)

```powershell
# TEIA FastVLM Web — Gerador de Projeto (PowerShell puro)
# Gera um servidor Flask + página web para upload em massa (fotos/vídeos),
# processa com FastVLM e devolve um JSONL com metadados por mídia.

# 1) Ajuste a raiz do projeto local (espelho do iCloud Drive se desejar)
$Root = "D:\Teia\TEIA_NUCLEO\teia_fastvlm_web"
$App  = Join-Path $Root "app"
$Tpl  = Join-Path $App "templates"
$Sta  = Join-Path $App "static"
$Mod  = Join-Path $App "models"
$Inf  = Join-Path $App "fastvlm_infer.py"
$Main = Join-Path $App "teia_fastvlm_web.py"
$Idx  = Join-Path $Tpl "index.html"
$Css  = Join-Path $Sta "style.css"
$Req  = Join-Path $Root "requirements.txt"
$Read = Join-Path $Root "README_TEIA.txt"

New-Item -ItemType Directory -Force -Path $Root,$App,$Tpl,$Sta,$Mod | Out-Null

# 2) Flask app — servidor HTTP com upload múltiplo, processamento e download do JSONL
Set-Content -LiteralPath $Main -Encoding UTF8 -Value @'
import os, io, time, json, tempfile
from datetime import datetime
from flask import Flask, render_template, request, send_file, redirect, url_for, flash
from werkzeug.utils import secure_filename
from fastvlm_infer import FastVLMAdapter

# Config
UPLOAD_DIR = os.environ.get("TEIA_UPLOAD_DIR", os.path.join(tempfile.gettempdir(), "teia_fastvlm_uploads"))
os.makedirs(UPLOAD_DIR, exist_ok=True)

app = Flask(__name__, template_folder="templates", static_folder="static")
app.secret_key = "teia-fastvlm-web"

# Inicializa adaptador FastVLM (CoreML/PyTorch se disponível; fallback seguro)
vlm = FastVLMAdapter(
    models_dir=os.environ.get("TEIA_MODELS_DIR", os.path.join(os.path.dirname(__file__), "models")),
    prefer_coreml=True
)

ALLOWED_EXT = {".jpg",".jpeg",".png",".bmp",".webp",".gif",".tif",".tiff",".mp4",".mov",".m4v",".avi",".mkv"}

def is_allowed(filename:str)->bool:
    ext = os.path.splitext(filename.lower())[1]
    return ext in ALLOWED_EXT

@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")

@app.route("/analyze", methods=["POST"])
def analyze():
    if "media" not in request.files:
        flash("Nenhum arquivo enviado.")
        return redirect(url_for("index"))

    files = request.files.getlist("media")
    if not files:
        flash("Selecione ao menos um arquivo.")
        return redirect(url_for("index"))

    items = []
    batch_ts = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    out_name = f"teia_fastvlm_{batch_ts}.jsonl"

    # Processamento
    for f in files:
        if not f or f.filename.strip() == "":
            continue
        if not is_allowed(f.filename):
            continue

        fname = secure_filename(f.filename)
        fpath = os.path.join(UPLOAD_DIR, f"{time.time_ns()}_{fname}")
        f.save(fpath)

        try:
            meta = vlm.describe_media(fpath)
            # meta padrão TEIA
            record = {
                "file": fname,
                "path": fname,
                "type": meta.get("type","unknown"),
                "duration": meta.get("duration", 0),
                "summary": meta.get("summary",""),
                "keywords": meta.get("keywords", []),
                "dominant_emotion": meta.get("dominant_emotion",""),
                "context": meta.get("context",""),
                "timestamp": meta.get("timestamp", ""),
                "ai_model": meta.get("ai_model","FastVLM"),
                "version": "1.0-teia-visual"
            }
            items.append(record)
        except Exception as e:
            items.append({
                "file": fname,
                "type": "error",
                "summary": f"Falha ao processar: {e}",
                "ai_model": "FastVLM",
                "version": "1.0-teia-visual"
            })
        finally:
            try:
                os.remove(fpath)
            except:
                pass

    # Monta JSONL em memória
    buf = io.BytesIO()
    for it in items:
        line = json.dumps(it, ensure_ascii=False)
        buf.write((line + "\n").encode("utf-8"))
    buf.seek(0)

    return send_file(buf,
        mimetype="application/jsonl",
        as_attachment=True,
        download_name=out_name
    )

if __name__ == "__main__":
    # Descobre host/porta via env, padrão 0.0.0.0:8080 (acessível na VPN/LAN)
    host = os.environ.get("TEIA_HOST","0.0.0.0")
    port = int(os.environ.get("TEIA_PORT","8080"))
    app.run(host=host, port=port, debug=False)
'@

# 3) Adaptador FastVLM — tenta CoreML; senão tenta PyTorch; senão fallback “dummy seguro”
Set-Content -LiteralPath $Inf -Encoding UTF8 -Value @'
import os, json, subprocess, platform
from datetime import datetime

class FastVLMAdapter:
    def __init__(self, models_dir:str, prefer_coreml:bool=True):
        self.models_dir = models_dir
        self.prefer_coreml = prefer_coreml
        self.backend = None
        self._load_backend()

    def _load_backend(self):
        # Heurística simples: prioriza CoreML em iOS; cai para PyTorch se possível; senão dummy.
        try:
            if self.prefer_coreml and platform.system() == "Darwin":
                import coremltools  # type: ignore
                self.backend = "coreml"
                return
        except Exception:
            pass
        try:
            import torch  # type: ignore
            self.backend = "pytorch"
            return
        except Exception:
            pass
        self.backend = "dummy"

    def _analyze_image(self, path:str)->dict:
        # PONTO DE INTEGRAÇÃO:
        # Aqui você integra a chamada real ao FastVLM (CoreML ou PyTorch) com o encoder FastViTHD.
        # O retorno deve ser um dicionário com summary/keywords/context/etc.
        if self.backend == "coreml":
            # TODO: carregar modelo CoreML do diretório self.models_dir e inferir
            pass
        elif self.backend == "pytorch":
            # TODO: carregar checkpoint PyTorch do FastVLM (ex.: 0.5B) e inferir
            pass

        # Fallback seguro (dummy) — útil para validar fluxo antes de instalar o modelo
        return {
            "type": "image",
            "summary": "Conteúdo visual detectado (modo dummy). Instale o modelo para resultado real.",
            "keywords": ["imagem","preview"],
            "dominant_emotion": "",
            "context": "desconhecido",
            "timestamp": datetime.utcnow().isoformat()+"Z",
            "ai_model": f"FastVLM-{self.backend}"
        }

    def _probe_video_duration(self, path:str)->float:
        # Duração via ffprobe se existir (opcional no Pyto)
        try:
            out = subprocess.check_output([
                "ffprobe","-v","error","-show_entries","format=duration",
                "-of","default=nk=1:nw=1", path
            ], stderr=subprocess.STDOUT).decode().strip()
            return float(out)
        except Exception:
            return 0.0

    def _analyze_video(self, path:str)->dict:
        # Estratégia: vídeo longo → amostragem de frames; vídeo curto → 1-3 frames.
        # Aqui você integraria a extração de frames + chamada FastVLM por frame e sumarização.
        dur = self._probe_video_duration(path)
        if self.backend in ("coreml","pytorch"):
            # TODO: extrair N frames e inferir com FastVLM, depois sumarizar
            pass

        # Fallback seguro (dummy)
        return {
            "type": "video",
            "duration": dur,
            "summary": "Vídeo analisado em modo dummy. Instale o modelo para resultado real.",
            "keywords": ["video","preview"],
            "dominant_emotion": "",
            "context": "desconhecido",
            "timestamp": datetime.utcnow().isoformat()+"Z",
            "ai_model": f"FastVLM-{self.backend}"
        }

    def describe_media(self, path:str)->dict:
        lower = path.lower()
        if any(lower.endswith(ext) for ext in [".jpg",".jpeg",".png",".bmp",".webp",".gif",".tif",".tiff"]):
            return self._analyze_image(path)
        return self._analyze_video(path)
'@

# 4) Página HTML (upload múltiplo + botão gerar JSONL)
Set-Content -LiteralPath $Idx -Encoding UTF8 -Value @'
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>TEIA FastVLM Web</title>
  <link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}" />
</head>
<body>
  <main class="wrap">
    <h1>TEIA FastVLM Web</h1>
    <p>Selecione fotos e/ou vídeos (sem limite) e clique em <strong>Gerar Metadados (JSONL)</strong>.</p>
    <form method="POST" action="/analyze" enctype="multipart/form-data">
      <input type="file" name="media" accept="image/*,video/*" multiple />
      <button type="submit">Gerar Metadados (JSONL)</button>
    </form>
    <div class="help">
      <p>Após o processamento, um arquivo <code>.jsonl</code> será baixado neste dispositivo.</p>
      <p>Abra esta página a partir de qualquer dispositivo na mesma VPN/LAN do iPhone.</p>
    </div>
  </main>
</body>
</html>
'@

# 5) CSS simples
Set-Content -LiteralPath $Css -Encoding UTF8 -Value @'
*{box-sizing:border-box}body{font-family:system-ui,Arial,sans-serif;margin:0;padding:0;background:#0b0f14;color:#e6eef7}
.wrap{max-width:840px;margin:40px auto;padding:24px;background:#0f1520;border:1px solid #1e293b;border-radius:12px}
h1{margin:0 0 16px 0}
form{display:flex;gap:12px;align-items:center;margin:20px 0}
input[type=file]{flex:1}
button{padding:10px 16px;border:0;border-radius:8px;cursor:pointer}
button:hover{filter:brightness(1.1)}
.help{opacity:.9}
code{background:#0b1220;padding:2px 6px;border-radius:6px}
'@

# 6) Requisitos (para ambiente Python local/pyto)
Set-Content -LiteralPath $Req -Encoding UTF8 -Value @'
flask==3.0.3
# Se disponível no seu ambiente:
# coremltools
# torch
'@

# 7) README rápido (uso no Pyto e rede)
Set-Content -LiteralPath $Read -Encoding UTF8 -Value @'
TEIA FastVLM Web — Guia Rápido

1) Copie a pasta "app" para o Pyto (no iPhone), ex.: iCloud Drive/Pyto/teia_fastvlm_web/app
2) No Pyto, abra "teia_fastvlm_web.py" e execute.
3) Verifique o IP local do iPhone (Ajustes › Wi-Fi/VPN). Acesse: http://SEU_IP:8080
4) Faça upload de fotos e vídeos. Baixe o JSONL resultante.

Instalação do modelo:
- Coloque os arquivos do modelo FastVLM na pasta "app/models".
- Ajuste o adaptador em fastvlm_infer.py para carregar seu modelo (CoreML/PyTorch).
- Variáveis de ambiente opcionais no Pyto:
  TEIA_MODELS_DIR=/var/mobile/Containers/…/Documents/teia_fastvlm_web/app/models
  TEIA_HOST=0.0.0.0
  TEIA_PORT=8080
'@

Write-Host "Projeto gerado em: $Root"
Write-Host "Abra no Pyto: app/teia_fastvlm_web.py"
```

---

## como usar (4 linhas, direto ao ponto)

1) **Executar** o bloco PowerShell acima (gera o projeto em `D:\Teia\TEIA_NUCLEO\teia_fastvlm_web`).  
2) **Copiar** a pasta `app` para o **Pyto** no iPhone (iCloud Drive › Pyto › `teia_fastvlm_web/app`).  
3) **Rodar** `teia_fastvlm_web.py` no Pyto; no navegador (mesma VPN/LAN) abrir `http://IP_DO_IPHONE:8080`.  
4) **Enviar** fotos/vídeos, clicar “Gerar Metadados (JSONL)” e **baixar** o arquivo.

---

## notas técnicas e próximos passos

- **FastVLM real**: o adaptador (`fastvlm_infer.py`) já está organizado para 3 modos: `coreml` → `pytorch` → `dummy`.  
  - Para **Core ML**, coloque o(s) modelo(s) convertidos em `app/models` e preencha o bloco `TODO` com o carregamento/inferência (encoder FastViTHD → cabeçote linguagem).  
  - Para **PyTorch**, idem (checkpoint + tokenizer + pipeline).  
  - Em ambos os casos, mantenha o **formato de saída** padronizado (summary, keywords, emotion, context, etc.) para seguir o **padrão TEIA**.  
- **Vídeos longos**: o servidor já diferencia imagem/vídeo; para vídeos você pode implementar a amostragem de frames (ffmpeg/ffprobe). No Pyto, se não houver `ffprobe`, substitua por um leitor de metadados nativo do iOS ou use uma lib pura-py.  
- **Segurança/Privacidade**: o app roda **local no iPhone**. Recomendado manter em VPN/LAN controlada. Se quiser, restrinja a origem (simple auth, token na query, etc.).  
- **Escalabilidade**: para *muitas* mídias, o fluxo HTTP com múltiplos arquivos funciona bem, pois processa e empacota o **JSONL único** para download.  
- **Integração TEIA**: depois de baixar o JSONL, me envie que eu **clusterizo** e proponho a **árvore de pastas** otimizada (ou rode um script TEIA no PC para aplicar automaticamente).

se quiser, eu já **preencho** os blocos de inferência (CoreML ou PyTorch) conforme **o formato exato do checkpoint que você tiver** (nome dos arquivos/pasta do modelo). basta me dizer qual você vai usar primeiro.

---

### USUÁRIO

e se não tiver pc agora 

---

### ASSISTENTE

# Create a self-contained "TEIA FastVLM Web (Mobile-only)" project
# Packaging everything into a ZIP the user can download and move to iPhone (Pyto / Files app).

import os, io, zipfile, textwrap, json, datetime, pathlib

root_dir = "/mnt/data/teia_fastvlm_web_mobile"
app_dir  = os.path.join(root_dir, "app")
tpl_dir  = os.path.join(app_dir, "templates")
sta_dir  = os.path.join(app_dir, "static")
os.makedirs(tpl_dir, exist_ok=True)
os.makedirs(sta_dir, exist_ok=True)

# teia_fastvlm_web.py (Flask app)
main_py = r'''import os, io, time, json, tempfile
from datetime import datetime
from flask import Flask, render_template, request, send_file, redirect, url_for, flash
from werkzeug.utils import secure_filename
from fastvlm_infer import FastVLMAdapter

# === Config ===
UPLOAD_DIR = os.environ.get("TEIA_UPLOAD_DIR", os.path.join(tempfile.gettempdir(), "teia_fastvlm_uploads"))
os.makedirs(UPLOAD_DIR, exist_ok=True)

app = Flask(__name__, template_folder="templates", static_folder="static")
app.secret_key = "teia-fastvlm-web-mobile"

# Inicializa adaptador FastVLM (CoreML > PyTorch > Dummy)
vlm = FastVLMAdapter(
    models_dir=os.environ.get("TEIA_MODELS_DIR", os.path.join(os.path.dirname(__file__), "models")),
    prefer_coreml=True
)

ALLOWED_EXT = {".jpg",".jpeg",".png",".bmp",".webp",".gif",".tif",".tiff",".mp4",".mov",".m4v",".avi",".mkv"}

def is_allowed(filename:str)->bool:
    ext = os.path.splitext(filename.lower())[1]
    return ext in ALLOWED_EXT

@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")

@app.route("/analyze", methods=["POST"])
def analyze():
    if "media" not in request.files:
        flash("Nenhum arquivo enviado.")
        return redirect(url_for("index"))

    files = request.files.getlist("media")
    if not files:
        flash("Selecione ao menos um arquivo.")
        return redirect(url_for("index"))

    items = []
    batch_ts = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    out_name = f"teia_fastvlm_{batch_ts}.jsonl"

    for f in files:
        if not f or f.filename.strip() == "":
            continue
        if not is_allowed(f.filename):
            continue

        fname = secure_filename(f.filename)
        fpath = os.path.join(UPLOAD_DIR, f"{time.time_ns()}_{fname}")
        f.save(fpath)

        try:
            meta = vlm.describe_media(fpath)
            record = {
                "file": fname,
                "path": fname,
                "type": meta.get("type","unknown"),
                "duration": meta.get("duration", 0),
                "summary": meta.get("summary",""),
                "keywords": meta.get("keywords", []),
                "dominant_emotion": meta.get("dominant_emotion",""),
                "context": meta.get("context",""),
                "timestamp": meta.get("timestamp", ""),
                "ai_model": meta.get("ai_model","FastVLM"),
                "version": "1.0-teia-visual"
            }
            items.append(record)
        except Exception as e:
            items.append({
                "file": fname,
                "type": "error",
                "summary": f"Falha ao processar: {e}",
                "ai_model": "FastVLM",
                "version": "1.0-teia-visual"
            })
        finally:
            try:
                os.remove(fpath)
            except:
                pass

    buf = io.BytesIO()
    for it in items:
        line = json.dumps(it, ensure_ascii=False)
        buf.write((line + "\n").encode("utf-8"))
    buf.seek(0)

    return send_file(buf,
        mimetype="application/jsonl",
        as_attachment=True,
        download_name=out_name
    )

if __name__ == "__main__":
    host = os.environ.get("TEIA_HOST","0.0.0.0")
    port = int(os.environ.get("TEIA_PORT","8080"))
    app.run(host=host, port=port, debug=False)
'''

# fastvlm_infer.py (Adapter with CoreML/PyTorch/Dummy modes)
infer_py = r'''import os, subprocess, platform
from datetime import datetime

class FastVLMAdapter:
    def __init__(self, models_dir:str, prefer_coreml:bool=True):
        self.models_dir = models_dir
        self.prefer_coreml = prefer_coreml
        self.backend = None
        self._load_backend()

    def _load_backend(self):
        # Prioriza CoreML em iOS (Pyto), depois PyTorch; senão "dummy"
        try:
            if self.prefer_coreml and platform.system() == "Darwin":
                import coremltools  # type: ignore
                self.backend = "coreml"
                return
        except Exception:
            pass
        try:
            import torch  # type: ignore
            self.backend = "pytorch"
            return
        except Exception:
            pass
        self.backend = "dummy"

    def _analyze_image(self, path:str)->dict:
        # TODO: integrar carregamento/inferência reais do FastVLM (CoreML/PyTorch)
        if self.backend == "coreml":
            # Exemplo de espaço para pipeline CoreML
            pass
        elif self.backend == "pytorch":
            # Exemplo de espaço para pipeline PyTorch
            pass

        # Dummy seguro para validar fluxo sem modelo instalado
        return {
            "type": "image",
            "summary": "Pré-visualização (modo dummy). Instale o modelo para resultado real.",
            "keywords": ["imagem","preview"],
            "dominant_emotion": "",
            "context": "desconhecido",
            "timestamp": datetime.utcnow().isoformat()+"Z",
            "ai_model": f"FastVLM-{self.backend}"
        }

    def _probe_video_duration(self, path:str)->float:
        try:
            out = subprocess.check_output([
                "ffprobe","-v","error","-show_entries","format=duration",
                "-of","default=nk=1:nw=1", path
            ], stderr=subprocess.STDOUT).decode().strip()
            return float(out)
        except Exception:
            return 0.0

    def _analyze_video(self, path:str)->dict:
        dur = self._probe_video_duration(path)
        if self.backend in ("coreml","pytorch"):
            # TODO: amostrar frames + pipeline FastVLM e sumarizar
            pass

        return {
            "type": "video",
            "duration": dur,
            "summary": "Pré-visualização de vídeo (modo dummy). Instale o modelo para resultado real.",
            "keywords": ["video","preview"],
            "dominant_emotion": "",
            "context": "desconhecido",
            "timestamp": datetime.utcnow().isoformat()+"Z",
            "ai_model": f"FastVLM-{self.backend}"
        }

    def describe_media(self, path:str)->dict:
        lower = path.lower()
        if any(lower.endswith(ext) for ext in [".jpg",".jpeg",".png",".bmp",".webp",".gif",".tif",".tiff"]):
            return self._analyze_image(path)
        return self._analyze_video(path)
'''

# index.html
index_html = r'''<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>TEIA FastVLM Web (Mobile)</title>
  <link rel="stylesheet" href="{{ url_for('static', filename='style.css') }}" />
</head>
<body>
  <main class="wrap">
    <h1>TEIA FastVLM Web (Mobile)</h1>
    <p>Selecione quantas fotos e/ou vídeos quiser e clique em <strong>Gerar Metadados (JSONL)</strong>.</p>
    <form method="POST" action="/analyze" enctype="multipart/form-data">
      <input type="file" name="media" accept="image/*,video/*" multiple />
      <button type="submit">Gerar Metadados (JSONL)</button>
    </form>
    <div class="help">
      <p>Após o processamento, o arquivo <code>.jsonl</code> será baixado neste dispositivo.</p>
      <p>Acesse esta página de outro aparelho na mesma VPN/LAN via <code>http://IP_DO_IPHONE:8080</code>.</p>
    </div>
  </main>
</body>
</html>
'''

# style.css
style_css = r'''*{box-sizing:border-box}body{font-family:system-ui,Arial,sans-serif;margin:0;padding:0;background:#0b0f14;color:#e6eef7}
.wrap{max-width:840px;margin:40px auto;padding:24px;background:#0f1520;border:1px solid #1e293b;border-radius:12px}
h1{margin:0 0 16px 0}
form{display:flex;gap:12px;align-items:center;margin:20px 0;flex-wrap:wrap}
input[type=file]{flex:1;min-width:260px}
button{padding:10px 16px;border:0;border-radius:8px;cursor:pointer}
button:hover{filter:brightness(1.1)}
.help{opacity:.9}
code{background:#0b1220;padding:2px 6px;border-radius:6px}
'''

# requirements.txt
requirements = r'''flask==3.0.3
# opcionais (se disponíveis em Pyto / iOS):
# coremltools
# torch
# ffmpeg / ffprobe (via a-Shell / Pyto bin)'''
# README
readme = r'''TEIA FastVLM Web (Mobile-only)
================================

Objetivo
- Rodar um servidor HTTP local no iPhone (via Pyto), aceitar uploads em massa
  (fotos e vídeos), processar com FastVLM e baixar um JSONL com metadados.

Passos (sem PC):
1) No iPhone, abra o app "Arquivos" e mova a pasta "app" para iCloud Drive › Pyto › teia_fastvlm_web › app
   (ou crie a pasta e cole os arquivos).
2) Abra o app "Pyto" e navegue até a pasta "teia_fastvlm_web/app".
3) Abra e execute "teia_fastvlm_web.py".
4) No Safari de outro dispositivo na mesma VPN/LAN, acesse: http://IP_DO_IPHONE:8080
   (No próprio iPhone, acesse http://127.0.0.1:8080)
5) Selecione fotos/vídeos (sem limite) e clique em "Gerar Metadados (JSONL)".

Observações:
- O adaptador fastvlm_infer.py inicia em modo "dummy" (gera pré-visualização).
- Para usar FastVLM real, coloque os modelos em app/models e implemente os blocos TODO (CoreML ou PyTorch).
- Caso não tenha ffprobe, a duração do vídeo pode retornar 0 (sem impacto no JSONL).

Variáveis de ambiente opcionais (em Pyto > Script Settings > Environment):
- TEIA_HOST=0.0.0.0
- TEIA_PORT=8080
- TEIA_MODELS_DIR=/var/mobile/Containers/Data/Application/.../Documents/teia_fastvlm_web/app/models
- TEIA_UPLOAD_DIR=/var/mobile/Containers/Data/Application/.../tmp/teia_fastvlm_uploads
'''

# Write files
with open(os.path.join(app_dir, "teia_fastvlm_web.py"), "w", encoding="utf-8") as f:
    f.write(main_py)

with open(os.path.join(app_dir, "fastvlm_infer.py"), "w", encoding="utf-8") as f:
    f.write(infer_py)

with open(os.path.join(tpl_dir, "index.html"), "w", encoding="utf-8") as f:
    f.write(index_html)

with open(os.path.join(sta_dir, "style.css"), "w", encoding="utf-8") as f:
    f.write(style_css)

with open(os.path.join(root_dir, "requirements.txt"), "w", encoding="utf-8") as f:
    f.write(requirements)

with open(os.path.join(root_dir, "README_TEIA_MOBILE.txt"), "w", encoding="utf-8") as f:
    f.write(readme)

# Zip everything
zip_path = "/mnt/data/teia_fastvlm_web_mobile.zip"
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
    for base, _, files in os.walk(root_dir):
        for name in files:
            full = os.path.join(base, name)
            rel  = os.path.relpath(full, root_dir)
            z.write(full, arcname=rel)

zip_path

---

### ASSISTENTE

sem PC? tranquilo — deixei tudo pronto num pacote “mobile-only” pra você rodar **só no iPhone 16 Pro Max** (via Pyto), criando a **interface web HTTP** acessível por qualquer dispositivo na mesma VPN/LAN e gerando o **JSONL** com a “meta-transcrição de linguagem de visão”.

[Baixar o pacote TEIA FastVLM Web (Mobile)](sandbox:/mnt/data/teia_fastvlm_web_mobile.zip)

# como usar agora (4 passos rápidos no iPhone)
1) abra o app **Arquivos** → **iCloud Drive** → mova/descompacte a pasta do ZIP em `Pyto/teia_fastvlm_web/` (a subpasta **app** precisa ficar em `iCloud Drive › Pyto › teia_fastvlm_web › app`).  
2) abra o **Pyto**, navegue até `iCloud Drive › Pyto › teia_fastvlm_web › app` e execute **`teia_fastvlm_web.py`**.  
3) no próprio iPhone abra **http://127.0.0.1:8080** (ou, de outro aparelho na mesma VPN/LAN, **http://IP_DO_IPHONE:8080**).  
4) selecione quantas **fotos e/ou vídeos** quiser e clique **Gerar Metadados (JSONL)** para baixar o arquivo único.

# o que vem no pacote
- `app/teia_fastvlm_web.py` → servidor **Flask** (HTTP) com upload múltiplo e geração do **JSONL**.  
- `app/fastvlm_infer.py` → adaptador do **FastVLM** com 3 modos: **CoreML → PyTorch → Dummy** (funciona mesmo sem modelo; já gera JSONL de pré-visualização).  
- `app/templates/index.html` + `app/static/style.css` → UI simples de upload em massa.  
- `README_TEIA_MOBILE.txt` + `requirements.txt`.

# observações importantes
- Já roda **sem PC** e **sem modelo instalado** (modo *dummy*), útil para validar o fluxo e baixar JSONL.  
- Para sair do *dummy* e usar o **FastVLM real** on-device:
  - coloque os arquivos do modelo em `app/models/` e complete os blocos `TODO` do `fastvlm_infer.py` (CoreML ou PyTorch).  
  - no Pyto, em **Script Settings → Environment**, você pode definir:
    - `TEIA_HOST=0.0.0.0`  
    - `TEIA_PORT=8080`  
    - `TEIA_MODELS_DIR=<caminho da pasta models>`  
- Para **vídeos longos**, o adaptador já diferencia imagem/vídeo; se não houver `ffprobe` no iPhone, a duração pode sair 0 — não impacta o JSONL; quando você quiser, eu te passo uma alternativa de leitura de metadados 100% em Python puro.  

se quiser, prossigo agora preenchendo o **bloco de inferência real** (CoreML ou PyTorch) no `fastvlm_infer.py` — me diga qual formato de **checkpoint** você pretende usar primeiro que eu te entrego o patch pronto.

---

