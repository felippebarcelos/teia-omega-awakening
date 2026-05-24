# 2196 - Configuração repetidor TP-Link

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_000000002f18622fb7486bd590a790e1', 'size_bytes': 228079, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Perfeito, Felippe — vamos ajustar página-a-página. Começando pelo que aparece no seu print (“Configuração Rápida ▸ Tipo de Conexão de Internet”, Archer C60 v2):

## 1) Verdade dura (e importante) sobre o C60
Seu Archer C60 **só tem portas Fast-Ethernet (10/100)**. Na prática, **qualquer coisa via cabo vai ficar limitada a ~100 Mb/s** (≈94–96 Mb/s em teste). Isso é limitação **de hardware**, não de configuração. Para cabo a >100 Mb/s, só trocando por um modelo com **portas gigabit** (ex.: Archer C6/A6/C80/C1200 etc.). citeturn0search1turn0search0turn0search4turn0search11

> Dito isso, ainda dá pra otimizar MUITO o Wi-Fi e o funcionamento como AP/repetidor para tirar o máximo do que ele entrega. Vamos nas telas.

---

## 2) O que selecionar **nesta tela** (“Tipo de Conexão de Internet”)
Escolha a opção conforme o **papel** que o C60 terá na sua rede:

- **C60 como roteador principal** (ligado no modem/ONT do provedor):
  - Normalmente: **IP Dinâmico** (DHCP).  
  - Se seu provedor exige login: **PPPoE** (aí você digita usuário/senha do ISP).  
  (Se tiver dúvida, use **Auto Detectar**: costuma acertar.)

- **C60 como Access Point (AP) com cabo vindo do roteador principal**:
  - Aqui também pode deixar **IP Dinâmico** agora e, **depois**, nas telas avançadas, vamos **desligar o DHCP** e **fixar um IP LAN** no mesmo range da sua rede-mãe (evita conflitos e facilita acessar o painel).

- **C60 como repetidor Wi-Fi (WDS/bridge, sem cabo)**:
  - Essa etapa de “Tipo de Conexão” não é a crucial; o que manda é ativar **WDS Bridging** nas configurações wireless, selecionar a rede principal, inserir a senha e alinhar canal/segurança. (Te guio quando chegarmos nessa tela.) citeturn0search3turn0search10

Pode clicar **Próximo** com **IP Dinâmico** por enquanto — ajustamos o resto nas próximas telas.

---

## 3) Check rápido para não “capar” velocidade por engano
Mesmo com o limite físico do C60, vale garantir que nada além dele esteja reduzindo ainda mais:

- **Cabo**: use **Cat5e ou Cat6** em todos os trechos.  
- **Auto-negociação**: deixe NIC do PC e portas do outro roteador em **Auto**; se algo cair pra **100 Mb/s half-duplex**, troque o cabo/porta.  
- **Link upstream**: se você usar o C60 **como AP**, plugue o cabo **numa LAN** do C60 (não na WAN), e desligaremos o DHCP (próximas telas).

---

## 4) Otimizações que vamos aplicar nas telas seguintes
Quando você mandar as próximas imagens, te passo o “clique a clique”. Antecipando o plano:

- **Wireless**  
  - **2.4 GHz (IoT)**: SSID **separado** do 5 GHz; **20 MHz** de largura; **canal fixo** livre (1/6/11); **WPA2-PSK/AES**; **WPS desativado**.  
  - **5 GHz (PC/TV/celulares)**: **80 MHz** (se disponível) ou 40 MHz, canal fixo menos congestionado; **WPA2-PSK/AES**.  
  - **Desligar “Smart Connect”** (se existir) para manter SSIDs separados (estabilidade de IoT).

- **Modo AP (se for o caso)**  
  - **DHCP OFF** no C60.  
  - **IP LAN fixo** (ex.: se seu roteador principal é 192.168.1.1, dar ao C60 o 192.168.1.2).  
  - **Gateway/DNS** apontando para o roteador principal.

- **Repetidor (WDS)**  
  - Ativar **WDS** na banda que for repetir (ideal 5 GHz para backbone, se o principal permitir).  
  - Mesma **segurança/canal** da rede principal; senha idêntica. citeturn0search3turn0search10

- **Firmware**  
  - Seu build é antigo (20161206). Se o site da TP-Link tiver firmware mais novo para **C60 v2**, vale atualizar (alguns relatos de “arquivo inválido” existem; se aparecer, te mostro como contornar). citeturn0search2turn0search5turn0search9

---

## 5) Se você busca >100 Mb/s no PC via cabo
A limitação não é de “repetidor capando”, e sim das **portas 10/100 do C60**. A solução é usar um **roteador/AP gigabit** (ex.: Archer C6/A6/C80/C1200) **ou** um **switch gigabit** antes do C60 para os dispositivos que precisam de >100 Mb/s (o C60 continuaria só como AP Wi-Fi). citeturn0search1turn0search0

---

Manda a **próxima tela** (ou me diga se o C60 vai ficar como **AP com cabo** ou **repetidor WDS**). Eu já te retorno com os cliques exatos da página seguinte.

---

### USUÁRIO

mesmo ele tendo wifi 5ghz ele não suporta retransmissão ethernet acima de 100mb?

---

### ASSISTENTE

Exato: o **5 GHz é só a banda do Wi-Fi**. As **portas físicas** do Archer C60 (WAN/LAN) são **Fast-Ethernet 10/100**, então **tudo que passa pelo cabo** nele fica limitado a ~94–96 Mb/s. Isso vale tanto para:

- PC ligado por **Ethernet** no C60  
- Link **WAN ↔ C60** quando ele é o roteador principal  
- **Uplink com fio** quando ele é AP

O Wi-Fi 5 GHz pode até negociar taxas maiores com seus clientes, mas:
- Se o **caminho até a internet** (ou até outro switch/roteador) passa por uma **porta 100 Mb/s** do C60, o **gargalo será 100 Mb/s**.  
- Em **WDS/repetidor** (backhaul sem fio), clientes Wi-Fi podem ver >100 Mb/s em condições ideais, mas há **overhead de repetição** e **qualquer dispositivo no cabo do C60** continua preso a 100 Mb/s.

### Como ter >100 Mb/s no cabo
1. Trocar o equipamento por um **roteador/AP com portas gigabit** (ex.: Archer C6/A6/C80/C1200).  
2. Ou colocar um **switch gigabit** direto no seu roteador principal e ligar o **PC nesse switch**; deixe o C60 só como **AP Wi-Fi** (ele continuará limitado a 100 nas portas dele, mas o PC no switch terá >100).

Se quiser, me diga se seu C60 vai ficar como **AP com cabo** ou **repetidor WDS** que eu já te passo os passos finos de configuração na próxima tela.

---

