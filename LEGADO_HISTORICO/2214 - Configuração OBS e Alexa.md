# 2214 - Configuração OBS e Alexa

### USUÁRIO

para usar o pc lg antigo como um monitor base para stream da captura de tela pelo obs studios e usarei o link rtsp para integrar a skill oracule ou outra skill da alexa para visualizar em tempo real uma transmissão de todas as câmeras em um layout só, quero saber como prossigo após ter instalado o obs studio no pc e ter configurar um layout de transmissão de tela que já aparece todas as câmeras, como iniciar a transmissão e obter o link rtsp e como baixar o oracule ou outra skill na alexa e configurar passo a pssso para obter o idealizsdo

---

### ASSISTENTE



**Analisando opções**

Estou pensando em formas de transmitir a captura de tela via OBS Studio e integrar com a skill Oracule na Alexa, considerando RTSP, WebRTC e WebRTC.

**Analisando integração**

Estou procurando formas de integrar a transmissão de todos os dispositivos usando a skill Oracule na Alexa, considerando HLS e WebRTC, e verificando as habilidades de vídeo do Alexa.

**Buscando alternativas**

Estou verificando o servidor OBS RTSP e o GitHub do MediaMTX, além das doc. do Alexa CameraStreamController e serviços de ponte.

**Analisa e se conecta**

Estou mapeando a compatibilidade do Alexa CameraStreamController com RTSP e RTP. Interessante que a Alexa Skill Scrypted facilita a conexão.

**Pesquisando URL**  
Está claro que agora estou buscando informações mais técnicas. Precisamos verificar a configuração do RTSP e o URL padrão olhando o README do plugin no GitHub.

**Consultando README.md**

Estou verificando o README.md para entender como usar o plugin e o caminho da URL padrão.

**Reunindo informações**

O conteúdo README está oculto devido a restrições dinâmicas, então estou clicando em `README.md`.

**Buscando URL padrão**

Estou procurando a URL padrão do OBS RTSP Server, pois a Readme não está exibindo o conteúdo devido às restrições dinâmicas.

**Procurando uma skill**

Estou investigando a skill 'Oracule' para RTSP. Considerando Scrypted, Monocle e habilidades de câmeras de segurança IP.

**Reunindo informações**

Estou organizando um jogo de caça ao tesouro, focando nas habilidades necessárias.

**Considerando alternativas**

Estou pensando em alternativas para a integração RTSP com Echo Show, levando em conta segurança, redes e habilidades do Alexa, como Scrypted e AWS API Gateway.

**Fornecendo e explicando**

Estou pensando em fornecer instações detalhadas do Scrypted em português brasileiro, destacando segurança em redes e confiabilidade 24/7, além de opções alternativas como o Fire TV para exibição ao vivo com Alexa.

**Consultando o plugin RTSP**

Estou verificando o ocorreu com o plugin RTSP no OBS e como o Scrypted entra em cena para integração com a Alexa.

**Escolhendo o caminho certo**

Estou mapeando ações para configurar o Scrypted Rebroadcast plugin com o OBS, link RTSP, e vários métodos para incorporar a stream no Alexa, como skills e configurações de endpoint.

**Mapeando a arquitetura**

Estou pensando na arquitetura: Câmeras > OBS > RTSP > Scrypted > Alexa. Detalhes são ainda temporários, baseados em informações gerais e pesquisa inicial.

**Ajustando a configuração**

Estou configurando a transmissão do OBS para Alexa. Verificando alternativas como MediaMTX para RTMP e WebRTC, além de garantir a presença de áudio silencioso.

**Montando a solução**

Estou desenvolvendo a resposta final, abordando o uso de um PC antigo LG como base de monitor, incluindo comandos e rotas para transmitir no Echo Show, e adicionando uma seção de resolução de problemas.

---

### ASSISTENTE

Perfeito — você já montou no OBS Studio uma cena que mostra **todas as câmeras num único layout**. Agora o objetivo é:

1) **Gerar um link RTSP** dessa “program” (saída principal) do OBS.  
2) **Entregar esse RTSP para a Alexa** por meio de uma skill compatível (a “Oracule” não aparece no catálogo, então abaixo mostro alternativas estáveis que funcionam hoje).

Abaixo vai um passo‑a‑passo enxuto com duas rotas para o RTSP e duas rotas para a Alexa. Escolha o par que preferir.

---

## PARTE A — Como obter um **RTSP** do seu OBS

### Opção A1) Plugin direto no OBS (mais simples)
Use o plugin **OBS‑RTSPServer**. Ele adiciona ao menu *Ferramentas* a opção “RTSP Server” e publica a saída do OBS como um stream RTSP local. citeturn4view0turn11search2

**Passos:**
1) Instale o plugin: baixe da página oficial e rode o instalador (Windows/macOS/Linux). Em Windows, também há `winget install iamscottxu.obs-rtspserver`. citeturn4view0  
2) No OBS: **Ferramentas ▸ RTSP Server**.  
   - Porta: `8554` (exemplo).  
   - Caminho/Mount: `live` (exemplo).  
   - Vídeo: H.264.  
   - **Áudio:** habilite uma trilha (AAC). *OBS 30+ não inicia sem áudio selecionado.* citeturn11search12  
3) Clique **Start** (iniciar). O seu link será parecido com:  
   ```
   rtsp://SEU_IP_LOCAL:8554/live
   ```  
   Essa sintaxe (“/live”) é a mais usada nos exemplos do plugin. Teste no VLC: **Mídia ▸ Abrir transmissão de rede**. citeturn7search5

> Observação: se o plugin não aparecer no menu, verifique os pré‑requisitos (runtime do VC++ em Windows) conforme FAQ do projeto. citeturn6view0

---

### Opção A2) Servidor **MediaMTX** (mais robusto e flexível)
O **MediaMTX** (ex‑rtsp-simple-server) aceita **RTMP/WHIP/RTSP** do OBS e reexpõe como **RTSP** (e também HLS/WebRTC, se quiser). É um único executável para Windows/macOS/Linux. citeturn13view0turn14view0

**Passos:**
1) Baixe e execute o **MediaMTX** (sem dependências). citeturn14view0  
2) No OBS: **Configurações ▸ Transmissão**  
   - Serviço: **Personalizado**  
   - **Servidor**: `rtmp://SEU_IP_LOCAL/obs`  
   - **Chave**: qualquer texto  
   - Clique **Iniciar Transmissão**.  
   O MediaMTX cria a *path* automaticamente; o RTSP correspondente fica:  
   ```
   rtsp://SEU_IP_LOCAL:8554/obs
   ```  
   (MediaMTX converte protocolos e publica o mesmo *path* em RTSP). citeturn15view0

> Vantagens: estabilidade, multi‑protocolo e fácil escalar ou proteger com usuário/senha no `mediamtx.yml` quando/quiser. citeturn14view0

---

## PARTE B — Como **ver esse RTSP na Alexa** (Echo Show/Fire TV)

> Importante: a Alexa **não aceita** um RTSP colado “direto”. Para “aparecer na Alexa”, o vídeo precisa vir por uma **skill Smart Home** compatível com câmera. A Amazon disponibiliza as interfaces **CameraStreamController (RTSP)** e **RTCSessionController (WebRTC)** para skills de câmera. citeturn1search2turn3search3

Duas rotas que funcionam bem no dia a dia:

### Opção B1) **Scrypted** (recomendado, tudo‑em‑um)
O **Scrypted** é um hub/NVR que recebe seu RTSP e expõe para Alexa via a skill “**Scrypted Home Automation**” (pela nuvem oficial do Scrypted). É simples e costuma ser o caminho mais estável hoje. citeturn10view0

**Passo a passo (no seu PC LG):**
1) Instale o Scrypted (Windows tem script PowerShell que instala como serviço). A interface sobe em `https://localhost:10443/`. citeturn12view0  
2) No Scrypted, instale o **plugin RTSP** e **adicione uma câmera** apontando para o seu link do OBS (ex.: `rtsp://SEU_IP_LOCAL:8554/live` ou `/obs`). citeturn3search15  
3) Ative os plugins **Alexa** e **Scrypted Cloud** (clique *Login* para registrar). A documentação ressalta que a Alexa usa a nuvem do Scrypted para sinalização. citeturn10view0  
4) No app **Alexa**: *Mais ▸ Skills e Jogos ▸ Buscar* “**Scrypted Home Automation**” ▸ **Ativar** ▸ **Vincular conta** ▸ **Detectar dispositivos**. citeturn10view0  
5) Use: “**Alexa, mostrar *[nome que você deu]* no Echo Show**”.

> Dica de compatibilidade do próprio Scrypted: ajuste o stream (resolução/codec) para maximizar a compatibilidade com Alexa/HomeKit/Google. citeturn3search5

---

### Opção B2) **Monocle** (gateway RTSP ↔ Alexa)
O **Monocle** publica seu RTSP como “câmera” Smart Home para a Alexa e usa um **Gateway local** (precisa rodar na sua rede, porta **443/TLS**) — exigência da Amazon para vários dispositivos. Ele é muito popular para “tornar RTSP visível” no Echo Show/Fire TV. citeturn8view0

**Passo a passo:**
1) Crie a conta e **defina um “camera feed”** no portal Monocle com o seu RTSP (do OBS). Siga o “Getting Started”:  
   *Criar conta → Definir câmera → Adicionar a skill Monocle → Descobrir dispositivos → Pedir para mostrar.* citeturn9view0  
2) Instale o **Monocle Gateway** no seu PC LG antigo (ou um Raspberry Pi). Ele precisa **escutar na porta 443** e a Alexa deve alcançá‑lo nessa porta. citeturn8view0  
3) Ao cadastrar a câmera, use o **TAG `@tunnel`** (primeira tentativa recomendada). Se não funcionar, teste `@proxy` ou `@proxy-tcp` (casos específicos). citeturn16view0  
4) No app **Alexa**: habilite a **skill Monocle**, faça a detecção de dispositivos e chame: “**Alexa, mostrar *[nome da câmera]* no Echo Show**”. citeturn9view0

> Observação: dispositivos Echo/Fire têm **limite de 1080p** (1920×1080) em muitos modelos. Ajuste o OBS para 1080p ou menos para evitar falhas. citeturn0search2

---

### Outras alternativas
- **Skill “IP RTSP/RTP Security Cameras” (Penniman’s Apps)** — foca em **Fire TV** (pareado com a Alexa). Útil se você quer ver no Fire TV/Stick sem gateway. citeturn3search4  
- **Construir sua própria skill** usando as interfaces **CameraStreamController/RTCSessionController** (é caminho de desenvolvedor; cito só por completude). citeturn1search2turn3search3

---

## Configurações sugeridas no OBS (para Alexa)
- **Resolução**: 1920×1080 (ou 1280×720). *Muitos Echo/Fire aceitam até 1080p.* citeturn0search2  
- **FPS**: 30.  
- **Codec de vídeo**: **H.264** (x264/NVENC/AMD VCE/Intel QSV).  
- **Intervalo de keyframe**: 2 s.  
- **Bitrate**: 3–6 Mb/s (teste sua rede).  
- **Áudio**: **AAC** 96–128 kb/s, 48 kHz, **mantenha uma trilha ativa** (mesmo “mutada” no mixer). (Alexa/skills de câmera requerem formatos compatíveis; Monocle lista **H.264 + AAC/G711** como combinação suportada). citeturn1search15

---

## Checklist rápido (sanidade)
- O **VLC** abre o seu `rtsp://SEU_IP:8554/...`? (se não, corrija plugin/MediaMTX/firewall). citeturn7search5  
- O **Scrypted** mostra vídeo ao vivo da câmera RTSP? (antes de ir para Alexa). citeturn10view0  
- A skill (Scrypted/Monocle) está **habilitada e vinculada** na Alexa? Fez a **descoberta** de dispositivos? citeturn10view0turn9view0  
- **Resolução ≤1080p**. citeturn0search2

---

## Solução de problemas (os mais comuns)
- **“A câmera não está respondendo” na Alexa**  
  – Garanta áudio AAC presente (OBS 30+ e Alexa são mais exigentes com áudio). citeturn11search12  
  – Reduza para **1080p/720p**. citeturn0search2  
  – No Monocle, teste os **tags `@tunnel` → `@proxy` → `@proxy-tcp`** e, em casos raros, `@noaudio`. citeturn16view0  
  – Com Scrypted, confirme que o **plugin Alexa** e o **Scrypted Cloud** estão ativos/logados (a Alexa usa a nuvem do Scrypted para a sessão). citeturn10view0  
- **Latência**: RTSP na Alexa normalmente tem alguns segundos. Se precisar *quase* tempo real em outros cenários, o OBS já suporta **WHIP/WebRTC** (mas a Alexa exige skill Smart Home para RTC). citeturn0search6turn3search3

---

## Sobre a “skill Oracule”
Não encontrei, hoje, no ecossistema Alexa uma skill chamada **“Oracule”** voltada a exibir streams RTSP customizados. Para o seu caso, as **skills que efetivamente fazem a ponte** são **Scrypted** (recomendado) e **Monocle** (gateway RTSP↔Alexa). citeturn10view0turn8view0

---

### Resumo do caminho mais direto (recomendação)
1) **OBS → MediaMTX** (ou plugin RTSP do OBS) para ter `rtsp://…/obs` (ou `/live`). citeturn15view0turn4view0  
2) **Scrypted** importa esse RTSP e expõe para **Alexa** via “Scrypted Home Automation”. citeturn10view0  
3) Na Alexa: habilite a skill, descubra o dispositivo e diga “Alexa, mostrar **Layout OBS** no Echo Show”.

Se quiser, descrevo seu hardware e rede e já te devolvo um **roteiro sob medida** (com valores de bitrate, encoder e portas) para esse PC LG antigo e seus dispositivos Alexa.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_0000000092e461f588be95c595c472a6', 'size_bytes': 409620, 'width': 1536, 'height': 1152, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_000000001814620eb45aa23a45539ba4', 'size_bytes': 3838933, 'width': 1152, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Perfeito — boa descoberta! Agora que a janela **RTSP Server** apareceu, vou te passar um passo-a-passo direto, em português, para configurar corretamente o plugin, iniciar a transmissão do OBS e testar o link RTSP dentro da sua rede local. Vou também listar checagens de firewall e como expor o link para o Scrypted / Monocle (Alexa) depois.

# 1) Ajustes rápidos no plugin (janela **RTSP Server** que você mostrou)
1. **Audio Tracks**: marque a(s) track(s) que você usa no OBS (ex.: 1).  
2. **URL**: por padrão aparece `rtsp://localhost:554/live`.  
   - `localhost` funciona só no próprio PC. Para outros dispositivos use o IP local do PC (ex.: `rtsp://192.168.1.45:554/live`).  
3. **Enabled Multicast**: deixe desmarcado a menos que você saiba usar multicast.  
4. **Authentication (opcional)**: marque **Enabled** se quiser exigir usuário/senha (boa prática quando abrir pra fora).  
5. **Auto Start**: marque se quiser que o servidor inicie automaticamente junto com o OBS.  
6. Clique em **Start** (ou equivalente) na janela do plugin para ligar o servidor RTSP. Verifique em **Status** se aparece Bitrate > 0 e Total Data Output aumentando depois de iniciar o streaming no OBS.

# 2) Configurar saída do OBS (o plugin usa o canal de *Streaming*)
1. Abra **Arquivo ▸ Configurações ▸ Saída**.  
2. Em **Modo de Saída**, selecione **Simples** ou **Avançado** (Avançado dá mais controle).  
3. Em **Transmissão (Streaming)** defina:
   - **Encoder**: x264 (CPU) ou NVENC/Intel/AMDGPU (se a máquina tiver GPU).  
   - **Taxa de bits (bitrate)**: 3000–6000 Kbps para 720–1080p; ajuste conforme a rede.  
   - **Intervalo de keyframe**: 2 s.  
   - **Perfil**: `main` (ou `baseline` se precisar máxima compatibilidade).  
4. Em **Áudio**: escolha **AAC** e bitrate 96–128 kb/s (se disponível).  
5. Em **Vídeo ▸ Saída (avançado)** confirme que a *Track de áudio* selecionada corresponde à que você escolheu no plugin (se marcou Audio Track 1, garanta que o streaming use track 1).

# 3) Iniciar transmissão (ordem correta)
1. Na janela **RTSP Server**: *Start server* (ou deixe auto start marcado).  
2. No OBS: clique **Iniciar Transmissão**.  
   - OBS vai enviar o stream para o “streaming output” (o plugin pegará esse stream e o servirá por RTSP).  
3. Volte ao plugin: em **Status** deve aparecer Bitrate > 0 e Total Data Output crescendo. Se estiver 0 kb/s, verifique se realmente clicou em **Iniciar Transmissão** no OBS.

# 4) Teste local (VLC)
1. No mesmo PC abra o VLC: **Mídia ▸ Abrir fluxo de rede**.  
2. Cole: `rtsp://localhost:554/live` → **Reproduzir**.  
3. Para testar em outro dispositivo da rede (celular/PC): substitua `localhost` pelo IP do PC que roda o OBS:  
   ```
   rtsp://SEU_IP_LOCAL:554/live
   ```
   Ex.: `rtsp://192.168.1.45:554/live`

# 5) Firewall e IP (se o stream não abrir de outros dispositivos)
1. No PC com Windows execute `ipconfig` no CMD para descobrir seu IP local (IPv4).  
2. Abra o **Windows Defender Firewall ▸ Regras de Entrada** e crie uma regra para liberar a porta **554 TCP** (ou a porta que você configurou) para o programa `obs-rtspserver` ou para o executável do OBS/plugin.  
3. Se for acessar pela internet (fora da sua rede), **NÃO** exponha diretamente sem proxy/NVR: prefira Scrypted/Monocle com autenticação e túnel seguro.

# 6) Tornando o RTSP disponível para a Alexa (um resumo objetivo)
- **Scrypted**: a melhor rota. Depois do stream ativo, no Scrypted adicione uma câmera apontando para `rtsp://SEU_IP:554/live`. Ative a skill **Scrypted** na Alexa e vincule a conta.  
- **Monocle**: registre feed RTSP no portal Monocle e rode o Monocle Gateway (requer porta 443 / TLS).  
(Se quiser eu já escrevo o passo-a-passo pra instalar/configurar o Scrypted no seu PC LG.)

# 7) Recomendações de parâmetros (para estabilidade / compatibilidade Alexa)
- Resolução: 1280×720 ou 1920×1080 (recomendo 720p se a máquina/rede for fraca).  
- FPS: 25–30  
- Bitrate: 3000 Kbps (720p) / 4500–6000 Kbps (1080p)  
- Audio: AAC 48 kHz, 96–128 kb/s  
- Keyframe: 2s  
- Se tiver GPU: use NVENC para reduzir carga da CPU.

# 8) Resolução de problemas rápidos
- **Tela preta no VLC**: verifique se iniciou *Iniciar Transmissão* no OBS; cheque firewall; teste `localhost` no próprio PC.  
- **VLC conecta mas Alexa não mostra**: confirme Scrypted/Monocle conseguem abrir o RTSP (teste dentro da aplicação), e que a Alexa já detectou o dispositivo (habilitar skill + descoberta).  
- **Áudio ausente**: selecione a track de áudio correta no plugin e confirme que o OBS está enviando áudio (mixer não mudo).

---

Quer que eu gere agora os comandos exatos (passo a passo) para:
- liberar a porta 554 no Windows Firewall (com `netsh`),  
- descobrir seu IP (`ipconfig`) e formatar o link final (`rtsp://192.168.x.x:554/live`),  
e/ou já preparo o roteiro para **instalar e configurar o Scrypted** nesse PC LG?

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000c250620ebc7967774a01c6f6', 'size_bytes': 3572288, 'width': 1152, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Perfeito — vou te dar **3 formas rápidas** (linha de comando PowerShell, CMD e via GUI/roteador) para descobrir o **IP local** do PC que está servindo o RTSP, além de como montar o `rtsp://...` e um teste com VLC. Também deixei um comando PowerShell pronto para liberar a porta 554 no firewall, caso precise.

---

# 1) Método PowerShell (recomendado — copy & paste)
Bloco PowerShell pronto para colar no terminal PowerShell (sem símbolos cmd): ele lista os endereços IPv4 válidos (ignora loopback e APIPA 169.*).

```powershell
# textdoc embed Codex - comandos PowerShell puros
# Mostra IPs IPv4 não-loopback e não-APIPA
Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -notlike '169.*' } |
  Select-Object InterfaceAlias, IPAddress, PrefixLength

# Exemplo: se quiser só o primeiro IP útil (apenas leitura)
(Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -notlike '169.*' } |
  Select-Object -First 1 -ExpandProperty IPAddress)
```

Interpretação: a coluna `InterfaceAlias` mostra qual adaptador (Wi-Fi / Ethernet). Use o `IPAddress` que corresponder ao adaptador conectado à mesma rede da sua Alexa.

---

# 2) Método CMD (rápido)
Abra **Prompt de Comando** e rode:
```
ipconfig
```
Procure o adaptador ativo (por exemplo “Adaptador de Ethernet Ethernet” ou “Adaptador de Rede Sem Fio Wi-Fi”) e verifique a linha **Endereço IPv4 . . . . . . . . . : 192.168.x.x** — esse é o IP que você usa no RTSP.

---

# 3) Pelo roteador (se preferir confirmar)
1. Acesse o painel do roteador (ex.: `http://192.168.0.1` ou `http://192.168.1.1`).  
2. Entre (usuário/senha do roteador) → seção **DHCP / Attached Devices / Client List**.  
3. Encontre o nome do PC (hostname) ou MAC; ali aparece o IP atribuído.

---

# Montando o URL RTSP final
- Ex.: se o PowerShell retornou `192.168.1.45` → URL:
```
rtsp://192.168.1.45:554/live
```
(use a porta e o path exibidos no plugin OBS RTSP — no seu caso `:554` e `live`).

Se você habilitou authentication no plugin e definiu usuário/senha, o formato (menos recomendado por segurança) pode ser:
```
rtsp://usuario:senha@192.168.1.45:554/live
```
Melhor: mantenha autenticação no plugin e use Scrypted/Monocle com túnel seguro em exposição externa.

---

# Teste rápido com VLC (já no PC ou em outro dispositivo da mesma rede)
1. Abra VLC → **Mídia ▸ Abrir fluxo de rede**.  
2. Cole `rtsp://192.168.1.45:554/live` → **Reproduzir**.  
Se funcionar, verá o vídeo (se não, verifique firewall e se você iniciou *Iniciar Transmissão* no OBS).

---

# (Opcional) Comando PowerShell para liberar a porta 554 no Firewall do Windows
Cole no PowerShell com privilégios de Administrador para criar regra de entrada TCP na porta 554:
```powershell
# Abre a porta TCP 554 no firewall para permitir RTSP
New-NetFirewallRule -DisplayName "OBS RTSP Inbound" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 554 -Profile Any
```
(Se você quiser remover depois: `Remove-NetFirewallRule -DisplayName "OBS RTSP Inbound"`)

---

# Dicas práticas / erros comuns
- Use **IPv4** (não cole um endereço IPv6).  
- Se tiver **Wi-Fi + Ethernet**, escolha o IP do adaptador que está conectado à mesma rede local que a Alexa.  
- Se o RTSP funcionar no mesmo PC (localhost) mas não em outro dispositivo → firewall/porta ou IP errado.  
- Para exposição para Alexa via **Scrypted**/**Monocle**, use o IP IPv4 interno acima quando configurar a câmera no Scrypted (ele vai puxar esse RTSP).

---

Quer que eu já gere os comandos exatos para:
1. abrir a porta no firewall (já te dei o PowerShell acima),  
2. configurar um IP estático no Windows (se preferir reservar/forçar um IP),  
ou 3. preparar o passo-a-passo para adicionar essa URL no Scrypted e vincular à Alexa?  
Me diz qual desses quer agora que eu já escrevo pronto para copiar.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000b84861f5b92127b9ac3512f9', 'size_bytes': 3360747, 'width': 1152, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Beleza — com base no `ipconfig` da foto (IPv4 = **192.168.0.54**) e no path do plugin (`/live`), o **URL RTSP final** é:

`rtsp://192.168.0.54:554/live`

Abaixo deixei 3 ações úteis prontas pra você (copiar o link, liberar a porta no firewall e testar no VLC).

### 1) Copiar o link para o clipboard (PowerShell)
Cole e rode no PowerShell:
```powershell
# textdoc embed Codex - PowerShell puro
Set-Clipboard 'rtsp://192.168.0.54:554/live'
```

### 2) Abrir a porta 554 no Firewall do Windows (PowerShell - admin)
Execute este comando em PowerShell com privilégios de administrador:
```powershell
# textdoc embed Codex - cria regra de entrada para permitir RTSP TCP 554
New-NetFirewallRule -DisplayName "OBS RTSP Inbound" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 554 -Profile Any
```
(Remova depois com `Remove-NetFirewallRule -DisplayName "OBS RTSP Inbound"` se quiser.)

### 3) Teste rápido no VLC (outro PC / celular na mesma rede)
- No VLC: **Mídia ▸ Abrir fluxo de rede** → cole `rtsp://192.168.0.54:554/live` → **Reproduzir**.  
- Se funcionar, verá o layout ao vivo. Se não abrir: verifique se o RTSP Server está **Start** no OBS, firewall e se o dispositivo está na mesma rede (Wi-Fi/Ethernet).

### Observações/next steps
- Se você habilitou autenticação no plugin, use Scrypted/Monocle apontando para esse URL e configure usuário/senha lá (ou no próprio plugin).  
- Para expor à Alexa, adicione essa URL como câmera no **Scrypted** (recomendado) ou no **Monocle** e então habilite/vincule a skill Alexa.  
- Se quiser, já te entrego o passo-a-passo pronto para instalar/configurar o Scrypted no PC (com comandos) e ligar a skill na Alexa. Quer que eu gere isso agora?

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000a01861f58af48ac08b270273', 'size_bytes': 558102, 'width': 1536, 'height': 1152, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Boa — explica rapidinho o que aconteceu e o que **realmente** precisa fazer agora.

**Por que deu esse erro**
A mensagem `Set-Clipboard não é reconhecido` apareceu porque você executou um comando PowerShell dentro do **Prompt de Comando (cmd.exe)**. `Set-Clipboard` é um cmdlet do **PowerShell**, não do cmd.  
Nem todos os três comandos são obrigatórios — eu te dei 3 opções (copiar link, abrir firewall, testar no VLC). Só **precisa** executar o que for útil pra você: copiar o link é só conveniência; abrir a porta é necessário **apenas** se outro dispositivo não conseguir acessar o RTSP; testar no VLC é altamente recomendado.

Abaixo deixo **alternativas seguras** — escolha a que preferir e cole no terminal correto.

---

## A — Copiar o link para o clipboard
Se quer só colocar o `rtsp://192.168.0.54:554/live` na área de transferência.

### Opção PowerShell (abra o PowerShell normal — não o cmd)
```powershell
# PowerShell (cole em PowerShell)
Set-Clipboard 'rtsp://192.168.0.54:554/live'
```

### Ou, se estiver no cmd, use o utilitário `clip` (funciona no cmd)
```cmd
echo rtsp://192.168.0.54:554/live | clip
```
(cole no campo de rede do VLC depois com Ctrl+V)

### Ou chamar PowerShell a partir do cmd (uma linha só)
```cmd
powershell -NoProfile -Command "Set-Clipboard 'rtsp://192.168.0.54:554/live'"
```

---

## B — Teste rápido no VLC (faça antes de mexer no firewall)
No outro PC ou celular da mesma rede:
1. Abra VLC → **Mídia ▸ Abrir fluxo de rede**  
2. Cole `rtsp://192.168.0.54:554/live` → **Reproduzir**

Se abrir, perfeito — não precisa abrir porta no firewall.

---

## C — Abrir a porta 554 no Firewall (somente se o VLC em outro dispositivo **não** conseguir conectar)
**Opção via cmd (funciona no Prompt de Comando com privilégios de Administrador):**
1. Abra o menu iniciar → digite `cmd` → clique com botão direito → **Executar como administrador**  
2. Cole:
```cmd
netsh advfirewall firewall add rule name="OBS RTSP Inbound" dir=in action=allow protocol=TCP localport=554
```

Para **remover** depois:
```cmd
netsh advfirewall firewall delete rule name="OBS RTSP Inbound" protocol=TCP localport=554
```

**Opção PowerShell (executar como Administrador):**
```powershell
New-NetFirewallRule -DisplayName "OBS RTSP Inbound" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 554 -Profile Any
# Remover:
# Remove-NetFirewallRule -DisplayName "OBS RTSP Inbound"
```

---

## Resumo / O que você precisa fazer agora (minha recomendação)
1. Tente o **Teste no VLC** (Seção B).  
2. Se **funcionar** — acabou, tudo pronto.  
3. Se **não funcionar**: abra um terminal como Administrador e rode o comando netsh (Seção C) ou rode o PowerShell `New-NetFirewallRule`. Depois repita o teste no VLC.  
4. Copiar o link (Seção A) é só conveniência — não obrigatório.

Se você quiser, eu já te passo **exatamente** o passo-a-passo para abrir o PowerShell como Administrador no Windows e colar os comandos — ou eu gero um único script PowerShell (no padrão TEIA: pronto para colar) que faz: copia o link, cria a regra de firewall e testa a porta. Quer que eu te gere esse script?

---

### USUÁRIO

com o que temos já posso entrar no meu pc conectado no mesmo wi-fi e ter acesso a transmissão do obs? sem precisar rodar os scripts propostos acima?

---

### ASSISTENTE

Sim — **na teoria** você já pode entrar do outro PC (mesma rede Wi-Fi) e abrir `rtsp://192.168.0.54:554/live` sem rodar os scripts que eu mandei — **contanto que** três condições estejam verdadeiras:

- O **RTSP Server** no OBS está **rodando** (na janela do plugin aparece Bitrate > 0 / Total Data Output crescendo).  
- O OBS está **enviando** (você clicou em **Iniciar Transmissão**).  
- **Nada** na rede (isolamento de Wi-Fi) ou no Windows (firewall) esteja bloqueando a porta **554**.

Abaixo o passo a passo mínimo, e um checklist rápido de solução caso não funcione — tudo sem script, só GUI e testes simples.

---

### 1) Teste simples (no outro PC)
1. Abra o **VLC** nesse outro PC.  
2. Vá em **Mídia ▸ Abrir fluxo de rede**.  
3. Cole:  
```
rtsp://192.168.0.54:554/live
```  
4. Clique **Reproduzir**.  
Se aparecer vídeo, pronto — não precisa de mais nada.

---

### 2) Se não abrir — checagens rápidas sem scripts

A) **Verifique se o RTSP realmente está ativo (no PC que roda o OBS)**  
- Olhe na janela **RTSP Server**: `Bitrate` > 0 e `Total Data Output` aumentando.  
- Olhe no OBS: o botão **Iniciar Transmissão** deve estar em modo *parado* (ou seja, você já clicou e está transmitindo).

B) **Ping básico** (no outro PC — só pra saber se os dois se enxergam)  
- Abra o **Prompt de Comando** no outro PC e rode:  
```
ping 192.168.0.54
```  
- Se receber respostas (tempo em ms), a rede está OK.  
- Se der *Request timed out* → provavelmente estão em redes diferentes (guest vs main) ou o roteador tem *AP isolation* ativado.

C) **Verificar se o firewall está bloqueando (GUI, sem script) — no PC do OBS**
1. Abra **Configurações → Privacidade e Segurança → Segurança do Windows → Firewall e proteção de rede**.  
2. Clique **Permitir um app pelo firewall**.  
3. Procure **OBS Studio** (ou `obs-rtspserver` se aparecer) e marque para **Rede Privada**.  
4. Salve e teste o VLC novamente.

D) **Verifique o Wi-Fi**  
- Confirme que ambos os dispositivos estão conectados ao **mesmo SSID** e **mesma faixa de IP** (ex.: ambos 192.168.0.x).  
- Se algum estiver em “Guest” ou “isolated”, mova para a rede principal.

---

### 3) Se tudo falhar e você quiser o caminho rápido (uma única ação)
- A solução mais comum é **permitir o OBS/porta 554 no Firewall**. Se preferir que eu gere o comando exato para executar (uma linha `netsh` ou `PowerShell`) eu já te passo — mas não é obrigatório se você seguir o passo GUI acima.

---

### Resumo final (o que fazer agora)
1. Tente o teste no VLC do outro PC.  
2. Se funcionar — acabou.  
3. Se não, faça o **ping**; se o ping falhar, arrume rede (mesmo SSID / desative AP isolation).  
4. Se o ping funcionar, vá em **Permitir um app pelo firewall** e autorize o OBS/rtsp.  
5. Repita o teste no VLC.

Quer que eu **gere uma única linha** (cmd ou PowerShell) para abrir a porta 554 agora, ou prefere tentar os passos GUI primeiro? Eu já te mando o comando pronto se quiser — só me diga se prefere `cmd` (netsh) ou `PowerShell`.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000d3e4620eac00b907d6df51c6', 'size_bytes': 646819, 'width': 1536, 'height': 1152, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Ótimo — vamos resolver isso passo a passo. Quando o OBS diz que o **quadro está em branco** ao tentar iniciar a transmissão, geralmente é **uma de duas coisas** (ou ambas ao mesmo tempo):

1. O **OBS não está enviando nada** porque a cena/ fontes estão ocultas ou a pré-visualização está vazia.  
2. O **streaming output** não está configurado corretamente (OBS não está realmente “mandando” para o servidor RTMP local que o plugin RTSP usa como entrada) — ou a máquina está sobrecarregada e o encoder não gera frames.

Vou listar um procedimento curto e ordenado para você executar agora (faça na ordem). Se quiser, cole aqui o que acontecer em cada passo e eu ajusto.

---

# Passo a passo rápido (faça na ordem)

## 1) Confirme que a sua **Cena** está ativa e com fontes visíveis
- Na janela principal do OBS, em **Cenas**, selecione a cena que contém o layout das câmeras.  
- Em **Fontes**, garanta que o ícone do olho esteja ativo (visível) para cada fonte (nenhum está oculto).  
- Se estiver usando *Display Capture* ou *Window Capture*, verifique se a opção está apontando para a tela/janela correta.  
- Verifique se a **pré-visualização** (área de vídeo do OBS) mostra o layout antes de iniciar a transmissão.  
Se a pré-visualização estiver preta → corrija as fontes primeiro.

---

## 2) Configure a **Transmissão** (Settings → Transmissão)
- Abra **Arquivo ▸ Configurações ▸ Transmissão**.  
- **Serviço**: escolha **Personalizado...**.  
- **Servidor** (cole exatamente):  
  ```
  rtmp://127.0.0.1:1935/live
  ```
  (ou `rtmp://localhost:1935/live` — é a mesma coisa)  
- **Chave de transmissão**: use `live` (ou qualquer texto simples).  
- Clique **OK / Aplicar**.

> Observação: esse servidor RTMP é apenas local — o plugin OBS-RTSPServer pega o stream que o OBS envia para o RTMP local e reexpõe em RTSP.

---

## 3) Certifique-se das configurações de Saída (Output → Streaming)
- Vá em **Arquivo ▸ Configurações ▸ Saída**.  
- Em **Modo de saída** escolha **Simples** (para testar mais fácil).  
- Em **Transmissão (Streaming)**:
  - **Encoder**: se o PC tiver GPU, prefira `NVENC` (NVIDIA) / `AMF` (AMD) / `QSV` (Intel). Se não, `x264`.  
  - **Taxa de bits**: comece com `3000 Kbps`.  
  - **Intervalo de keyframe**: `2` segundos.  
  - **Perfil**: `main`.  
- Em **Áudio**: garanta **AAC** 128 kb/s (se disponível) e track de áudio correta.

---

## 4) Inicie na ordem correta: RTSP server → Iniciar Transmissão
1. Na janela **RTSP Server** (plugin) clique **Start** (ou marque Auto Start se quiser). Observe `Bitrate` e `Total Data Output`.  
2. Só depois clique em **Iniciar Transmissão** no OBS (botão principal).  
3. Volte ao plugin RTSP: se aparecer Bitrate > 0 e Total Data Output crescendo, o OBS está enviando e o plugin está convertendo para RTSP com sucesso.  
4. Teste no VLC (em outro PC/celular na mesma rede): `rtsp://192.168.0.54:554/live` → deve reproduzir.

---

## 5) Se o OBS mostrar **quadro em branco** ao clicar em Iniciar Transmissão
Execute estas checagens rápidas:

A. **Pré-visualização**: A pré-visualização está mostrando as câmeras?  
B. **Fontes**: Tem alguma fonte com “warning” (ponto de exclamação) ou com texto “dispositivo ocupado”? Reabra o capture device.  
C. **Estúdio Mode**: Se estiver em *Modo Estúdio*, clique em **Saída de Transmissão** (ou faça *Program* ficar ativo).  
D. **Encoder / CPU**: Olhe no canto inferior direito o uso da CPU; se estiver muito alto (> 85–90%) pode não conseguir processar. Se estiver alto:
   - Baixe a resolução para 1280×720 (Configurações → Vídeo).  
   - Reduza o FPS para 25 ou 30.  
   - Use NVENC (se disponível) para aliviar a CPU.  

E. **Logs do OBS**: vá em **Ajuda ▸ Logs** e abra o log recente; procure mensagens de erro sobre “encoding” ou “device busy”.

---

## 6) Se continuar em branco — alternativa simples com MediaMTX (fallback)
Se o plugin continuar dando problema, use o MediaMTX como “conversor”:
1. Baixe e execute MediaMTX no PC (é um exe único).  
2. Em OBS config de Transmissão, coloque:
   ```
   rtmp://127.0.0.1:1935/obs
   ```
   e stream key `stream` (por exemplo).  
3. Inicie Stream no OBS; MediaMTX expõe RTSP em `rtsp://127.0.0.1:8554/obs`.  
4. Teste no VLC `rtsp://192.168.0.54:8554/obs`.

---

# Resumo (o que fazer agora — ação imediata)
1. Verifique pré-visualização e fontes no OBS — corrija se estiverem ocultas.  
2. Em **Transmissão** coloque `rtmp://127.0.0.1:1935/live` e chave `live`.  
3. Configure Saída (encoder, bitrate) como indicado.  
4. Start no RTSP plugin → Start Transmissão no OBS.  
5. Teste no VLC com `rtsp://192.168.0.54:554/live`.

Se você fizer esses passos e ainda aparecer **quadro em branco**, me diga **qual passo falhou** (por exemplo: pré-visualização está preta, plugin mostra Bitrate=0, erro no OBS ao iniciar transmissão, etc.). Me mande uma foto do que aparece no log / status do plugin se puder — eu te guio no ajuste fino (reduzir bitrate, trocar encoder, etc.).

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000b38061f5b86fce89f5deef99', 'size_bytes': 4048967, 'width': 1152, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000c1ec61f59dd1a185c9171e17', 'size_bytes': 3999613, 'width': 1152, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000da5461f5a5bd66796d903ba4', 'size_bytes': 509670, 'width': 1152, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Curto e direto: **não — a skill / gateway (Scrypted, Monocle, Alexa) não “liga” o OBS por você**. Essas skills só **consomem** um stream já disponível no endereço RTSP. Se o OBS não estiver realmente enviando frames, a skill não terá nada para mostrar.

Explicando rápido o porquê e as soluções práticas:

### Por que não funciona automaticamente
- O plugin **OBS-RTSPServer** só **expõe** o que o OBS estiver enviando. Se o OBS não estiver em *streaming* (ou se o plugin não estiver recebendo frames), o RTSP estará vazio.  
- A Alexa/Scrypted/Monocle apenas requisita o `rtsp://...` — ela não tem controle para mandar o OBS começar a transmitir.

### Opções para ter o stream disponível sem ficar clicando manualmente

1. **Iniciar o OBS já em modo streaming (mais simples)**  
   Crie um atalho que abra o OBS e já inicie a transmissão automaticamente. Exemplo (cole no destino do atalho):  
   ```
   "C:\Program Files\obs-studio\bin\64bit\obs64.exe" --startstreaming
   ```
   - Configure antes em **Configurações → Transmissão** para apontar a `rtmp://127.0.0.1:1935/live` (ou o que você usou).  
   - Deixe **RTSP Server** com **Auto Start** marcado. Assim, ao abrir o atalho o OBS já começa a enviar e o plugin já expõe o RTSP.

2. **Controlar o início do streaming por script/automação (mais flexível)**  
   - Instale o plugin **obs-websocket** (permite controlar o OBS por rede).  
   - Use um pequeno script (PowerShell / Node / Python) que chame a API `StartStreaming` do obs-websocket no boot do PC ou quando quiser.  
   - Útil se você quiser ligar/desligar remotamente ou integrar a um agendador.

3. **Deixar OBS sempre rodando e o plugin servindo, mas garantir que haja frames**  
   - Marque **Auto Start** no RTSP plugin.  
   - Use a **Virtual Camera** ou fonte fixa se você precisa de imagem mesmo sem “stream” tradicional — mas para Alexa o RTSP real é o caminho padrão.

### Antes de automatizar — corrija o problema de *dropped frames*
Vi na sua última foto muitos *Dropped Frames*. Se automatizar sem consertar, a Alexa vai mostrar travamento/pulso. Faça isso antes:
- Use **NVENC / QSV** se tiver GPU (Configurações → Saída → Encoder).  
- Reduza resolução para **1280×720** e FPS para **25–30**.  
- Reduza bitrate para **~3000 kbps** (720p) / 4500–6000 kbps (1080p) se a rede suportar.  
- Keyframe = **2 s**.  
- Verifique CPU (se estiver >85%, mude para hardware encoder ou abaixe parâmetros).  
- Se possível, use **cabo Ethernet** para maior estabilidade.

### Checagem final para funcionar com Alexa (Scrypted / Monocle)
1. OBS enviando (via `--startstreaming` ou manual).  
2. RTSP plugin ativo e mostrando bitrate > 0.  
3. Teste local no VLC: `rtsp://192.168.0.54:554/live` (se abrir, Scrypted/Monocle também devem conseguir).  
4. Configure Scrypted/Monocle apontando para esse RTSP; depois habilite e vincule a skill na Alexa.

---

Quer que eu gere **o atalho pronto** (linha exata para criar na Área de Trabalho) ou **um script PowerShell** que: 1) inicia o OBS com `--startstreaming`, 2) espera 10s e checa o RTSP no localhost, e 3) registra no log se estiver OK? Se preferir o caminho do obs-websocket eu já deixo os passos e um pequeno script de exemplo. Qual deles você prefere que eu gere agora?

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000fa9c61f5a1e1ac07ed94f154', 'size_bytes': 3872647, 'width': 1536, 'height': 1152, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Perfeito — vamos fechar isso agora com um checklist prático **do que executar antes de se afastar** e **como verificar depois, a partir do outro PC na mesma rede**, sem enrolação. Vou indicar exatamente quais janelas/menus abrir e colar comandos prontos (diga qual terminal você tem aberto — CMD ou PowerShell — pois alguns comandos vão em um e outros no outro).

---

## Resumo do problema (curto)
O erro *“servidor não existe / não está ativo”* aparece porque **o OBS tenta enviar para um servidor RTMP (localhost:1935)** que não está escutando. Para o RTSP existir (o plugin OBS-RTSPServer vai expor RTSP) é preciso:

1. ter um servidor RTMP para o OBS enviar (o plugin ou um conversor como MediaMTX), **e**
2. ter o plugin RTSP **Start** e o OBS realmente em *streaming* (botão Iniciar Transmissão vira Parar Transmissão).

---

## Antes de se afastar — passos obrigatórios (faça-os agora)

1. **No OBS → Ferramentas → RTSP Server**  
   - Marque **Auto Start** se quiser.  
   - Clique **Start** (ou se já estiver em Start, deixe).  
   - Verifique em *Status* que o `Bitrate` sobe quando houver streaming (por enquanto pode estar 0).

2. **Configurações → Transmissão** (OBS)  
   - **Serviço**: *Personalizado*  
   - **Servidor**: `rtmp://127.0.0.1:1935/live`  
   - **Chave**: `live`  
   - Clique **Aplicar**.

3. **Configurações → Saída**  
   - Modo: **Simples**  
   - Encoder: `NVENC` (se tiver GPU) ou `x264`  
   - Bitrate: `3000` (comece aí)  
   - Keyframe: `2`  
   - Áudio: AAC 128 kb/s (se disponível)  
   - Clique **Aplicar**.

4. **Inicie a transmissão no OBS**  
   - Clique **Iniciar Transmissão** (botão principal).  
   - Observe se o botão muda para **Parar Transmissão**.

5. **Verifique status no RTSP Server (plugin)**  
   - No plugin: `Total Data Output` e `Bitrate` devem começar a aumentar.  
   - Se `Bitrate` continuar 0 e OBS reportar “servidor não existe”, siga abaixo (checagens).

---

## Se o OBS ainda reclama “servidor não existe” — checagens rápidas (execute no PC do OBS)

Abra **Prompt de Comando (cmd)** (não PowerShell) e cole:
```cmd
netstat -an | findstr ":1935"
```
- Se não retornar linha `LISTENING` significa *nenhum processo* escutando em 1935 → precisa rodar o RTMP listener (o plugin normalmente cria/expõe, ou você instala MediaMTX/nginx-rtmp).

Teste se a porta RTSP (554) está aberta localmente (PowerShell como Admin):
```powershell
Test-NetConnection -ComputerName 127.0.0.1 -Port 554
```
- `TcpTestSucceeded : True` → RTSP server está escutando.

Se 1935 não estiver escutando e você não quer instalar nada, use **MediaMTX** (eu recomendo): é um único executável que cria RTMP<->RTSP automaticamente. Resumo rápido para instalar/rodar MediaMTX:
- Baixe `mediamtx.exe` (site oficial).  
- Rode `mediamtx.exe` na pasta (duplo clique). Ele escutará RTMP em 1935 e RTSP em 8554 por padrão.  
- No OBS em Transmissão use `rtmp://127.0.0.1:1935/obs` e chave `stream`.  
- MediaMTX expõe depois `rtsp://127.0.0.1:8554/obs` e também `rtsp://{seuIP}:8554/obs` para outros dispositivos.

(Se quiser, eu escrevo o passo-a-passo do MediaMTX já com links e comandos).

---

## Testes rápidos — verificar localmente antes de ir embora

1. **Testar RTSP no próprio PC (VLC)**  
   - Abra VLC → Mídia → Abrir fluxo de rede → cole:
     ```
     rtsp://127.0.0.1:554/live
     ```
     (ou `rtsp://127.0.0.1:8554/obs` se usar MediaMTX)
   - Reproduzir → se aparecer vídeo, servidor e OBS estão OK localmente.

2. **Checar se OBS está realmente em streaming**  
   - No OBS: botão `Iniciar Transmissão` ficará `Parar Transmissão` quando ativo.  
   - No canto inferior direito do OBS você verá FPS / uso CPU; e na janela RTSP plugin `Bitrate > 0`.

3. **Copie o URL final para usar no outro PC**  
   - Se plugin OBS-RTSPServer usa porta 554 e path `live` → `rtsp://192.168.0.54:554/live` (exemplo do seu IP).  
   - Se usar MediaMTX com path `obs` e porta 8554 → `rtsp://192.168.0.54:8554/obs`.

---

## O que fazer no outro PC (quando você estiver longe) — verificação remota

No outro PC (mesma rede):

A) Teste de conectividade:
```cmd
ping 192.168.0.54
```
(se não responder → problema de rede / AP isolation / dispositivos em SSID Guest)

B) Teste de porta (PowerShell):
```powershell
Test-NetConnection -ComputerName 192.168.0.54 -Port 554
```
ou se MediaMTX estiver em 8554:
```powershell
Test-NetConnection -ComputerName 192.168.0.54 -Port 8554
```
- Se `TcpTestSucceeded : True` → porta alcançável.

C) Abrir o stream no VLC do outro PC:
```
rtsp://192.168.0.54:554/live
```
ou `rtsp://192.168.0.54:8554/obs` conforme configurado.

---

## Comandos prontos para você copiar (rápidos)

- **Verificar processo escutando em 1935 (cmd):**
```cmd
netstat -an | findstr ":1935"
```

- **Testar porta RTSP 554 localmente (PowerShell):**
```powershell
Test-NetConnection -ComputerName 127.0.0.1 -Port 554
```

- **Testar porta RTSP remotamente a partir do outro PC (PowerShell):**
```powershell
Test-NetConnection -ComputerName 192.168.0.54 -Port 554
```

- **Se quiser adicionar regra no firewall (já mostrou que deu OK antes):**
```cmd
netsh advfirewall firewall add rule name="OBS RTSP Inbound" dir=in action=allow protocol=TCP localport=554
```
(rodar como Administrador)

---

## Dicas finais antes de sair (prático)
- *Faça o teste no VLC local* (passo obrigatório). Se abrir, pare e tente do outro PC; se o do outro PC falhar, faça ping e Test-NetConnection como acima.  
- Se planeja deixar a transmissão ativa por longos períodos: reduza resolução p/ 720p e bitrate p/3000 para evitar *dropped frames*.  
- Se quiser que o OBS inicie automaticamente já em streaming ao ligar o PC, eu posso gerar um atalho com `--startstreaming` agora (diga se quer esse atalho).

---

Quer que eu gere **um único checklist imprimível** (3 passos: iniciar plugin, iniciar transmissão, testar no VLC local e remoto) ou prefere que eu escreva agora o **mini-tutorial do MediaMTX** para rodar como fallback (rapidinho — download & comando de execução)? Qual prefere — *checklist* ou *MediaMTX*?

---

