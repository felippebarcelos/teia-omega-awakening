# 0611 - Automate iPhone Smart Plugs

### USUÁRIO

preciso da sua ajuda, essa tomada da marca novadigital “Especificações
﻿﻿Tensão de entrada: 100 ~ 240Vca, 50/60Hz
﻿﻿Tensão de saída: 100 ~ 240Vca, 50/60Hz
﻿﻿Corrente máxima: 16A, carga resistiva
﻿﻿Certificação: RoHS, FCC, IC, UL, ANATEL
﻿﻿Ambiente: Temperatura operacional: 0 °C~ 40 °C (32°F ~ 104°F) Umidade operacional: 10%~90%, Sem Condensação
﻿﻿Material: PC
﻿﻿Botões: Botão de Ligar/Desligar e Configuração
﻿﻿Plug: Brasil (NBR 14136)
﻿﻿Cor: Branco
﻿﻿Tipo Wi-Fi: 2.4GHZ, 1T1R
﻿﻿Conexão Wi-Fi: IEEE 802.11b/g/n
﻿﻿Segurança: WPA/WPA2, WEP/TKIP/AES
Itens Inclusos
﻿﻿01 Tomada inteligente 16A
﻿﻿01 Manual
***Importante***
Certifique-se de ter um excelente sinal de WI-FI na área que deseja instalar a tomada.”
estou usando para ligar e desligar minha mesa de exposição de serigrafia porém, no aplicativo que possuo para comandar essa tomada “tuya” “smarthome” e “nova digital” só consigo ter acesso a comandos em segundos, minutos e horas, porem como o processo é muito preciso quanto ao tempo de exposição preciso ter acesso a configurar os milésimos, por exemplo criar uma automação no app para ao ligar a tomada, ficar ligada por 9,5 segundos e depois desligar, porém não consigo nesses 3 apps que já possuo por  conta que só deixam selecionar 9 segundos ou 10 segundos, não tendo as opções necessárias para termos o tempo mais exato de revelação autamente sensível 

---

### ASSISTENTE

Para conseguir configurar a tomada inteligente da Novadigital para funcionar com milissegundos, é necessário um método alternativo, já que os aplicativos que você mencionou (Tuya, SmartHome e Novadigital) não oferecem essa precisão. Aqui estão algumas soluções que podem ajudar:

### Soluções Alternativas:

1. **Uso de Dispositivos com Scripts Personalizados:**
   - **Home Assistant:** Este é um sistema de automação residencial de código aberto que pode ser executado em um Raspberry Pi ou em um servidor local. Você pode criar scripts personalizados para controlar dispositivos inteligentes com alta precisão. O Home Assistant é compatível com dispositivos Tuya, e você pode configurar automações com temporizações muito específicas.
   - **Node-RED:** Outra opção de código aberto para automação, Node-RED permite criar fluxos de trabalho de automação com alta precisão e pode se integrar a dispositivos Tuya. Você pode criar um fluxo para ligar a tomada por 9,5 segundos e depois desligá-la.

2. **API Tuya:**
   - Se você tiver habilidades de programação, pode usar a API Tuya para criar um script personalizado que controla sua tomada com a precisão necessária. A API permite comandos diretos aos dispositivos Tuya, possibilitando maior controle sobre os tempos de ativação.

### Passos para Configuração no Home Assistant:

1. **Instalação do Home Assistant:**
   - Instale o Home Assistant em um Raspberry Pi ou em um servidor local. Siga as instruções no site oficial do Home Assistant para a instalação.

2. **Integração com Tuya:**
   - No Home Assistant, ad

---

### USUÁRIO

Não existe nenhum outro aplicativo parecido com esses três mencionados anteriormente para conseguir ter acesso à conexão entre essa tomada criando automatizações em milésimos algum aplicativo, quem sabe, seja mais específico para tomadas inteligentes ou para conexões inteligentes pois se existem já três aplicativos que conseguiram criar automatização para o mesmo produto eu acredito que possa existir mais aplicativos que, na verdade, só possuem mais funcionalidades incluindo os milésimos na automatização

---

### ASSISTENTE

Entendi. Vamos explorar alguns aplicativos alternativos que possam oferecer funcionalidades adicionais, incluindo a possibilidade de criar temporizações em milissegundos para suas automações.

### Aplicativos Alternativos para Controle de Dispositivos Inteligentes:

1. **IFTTT (If This Then That):**
   - **Descrição:** IFTTT é uma plataforma que permite criar "receitas" de automação que conectam diferentes serviços e dispositivos.
   - **Funcionalidade:** Apesar de IFTTT não ser normalmente usado para automações em milissegundos, ele pode ser combinado com outros serviços para aumentar a precisão. Vale verificar se há "applets" específicos para Tuya ou dispositivos compatíveis com seu cenário.

2. **Smart Life:**
   - **Descrição:** Smart Life é um aplicativo de automação residencial que suporta uma vasta gama de dispositivos inteligentes.
   - **Funcionalidade:** Este aplicativo pode oferecer funcionalidades adicionais comparadas ao Tuya, e é frequentemente usado com dispositivos similares. Vale a pena testar para ver se ele oferece opções mais precisas de temporização.

3. **eWeLink:**
   - **Descrição:** eWeLink é o aplicativo oficial para dispositivos Sonoff, mas também é compatível com uma ampla variedade de dispositivos inteligentes.
   - **Funcionalidade:** Pode ter funcionalidades avançadas de temporização que você precisa. Verifique se seu dispositivo Novadigital é compatível com eWeLink.

4. **Tasker (Android):**
   - **Descrição:** Tasker é um aplicativo de automação extremamente poderoso para Android que permite criar scripts detalhados para controlar dispositivos.
   - **Funcionalidade:** Com plugins como AutoInput ou AutoTools, você pode configurar temporizações muito precisas, possivelmente até em milissegundos.

### Teste Inicial:

1. **Baixe e Instale os Aplicativos:**
   - Baixe e instale os aplicativos sugeridos (Smart Life, eWeLink e Tasker) em seu smartphone.

2. **Adicione e Configure o Dispositivo:**
   - Adicione sua tomada inteligente em cada aplicativo, seguindo as instruções fornecidas.

3. **Criação de Automação:**
   - Explore as opções de automação em cada aplicativo. Verifique se algum deles permite configurar temporizações mais precisas do que os aplicativos que você já tentou.

### Verificação:

- **Compatibilidade:** Verifique se os aplicativos são compatíveis com seu dispositivo específico.
- **Funcionalidades:** Teste cada aplicativo para ver se ele oferece a precisão de temporização necessária para o seu processo de serigrafia.

### Conclusão:

Se nenhuma dessas soluções funcionar, considerar o uso de plataformas mais avançadas como Home Assistant ou Node-RED pode ser necessário, pois elas oferecem uma personalização mais detalhada e precisa.

Espero que essas sugestões ajudem a encontrar uma solução para sua necessidade específica de automação com milissegundos.

---

### USUÁRIO

app para apple store iphone

---

### ASSISTENTE

Para dispositivos iPhone, existem algumas opções adicionais que podem oferecer maior controle e personalização de suas automações. Aqui estão algumas recomendações de aplicativos disponíveis na Apple Store que você pode testar para conseguir a precisão necessária:

### Aplicativos para iPhone:

1. **Smart Life - Smart Living:**
   - **Descrição:** Similar ao Tuya, este aplicativo oferece uma ampla gama de funcionalidades para dispositivos inteligentes e pode ser uma alternativa a ser explorada.
   - **Link:** [Smart Life - Smart Living na Apple Store](https://apps.apple.com/us/app/smart-life-smart-living/id1115101477)

2. **IFTTT (If This Then That):**
   - **Descrição:** Permite a criação de automações entre diferentes dispositivos e serviços. Embora não tenha suporte nativo para milissegundos, pode ser combinado com outros serviços.
   - **Link:** [IFTTT na Apple Store](https://apps.apple.com/us/app/ifttt/id660944635)

3. **Home+ 5:**
   - **Descrição:** Um aplicativo avançado para gerenciamento de dispositivos HomeKit da Apple, que pode oferecer temporizações precisas para automações.
   - **Link:** [Home+ 5 na Apple Store](https://apps.apple.com/us/app/home-5/id995994352)

4. **Homebridge:**
   - **Descrição:** Não é um aplicativo, mas um software que pode ser instalado em um servidor ou Raspberry Pi para integrar dispositivos não compatíveis com HomeKit, permitindo automações avançadas através do aplicativo Casa da Apple.
   - **Link para setup:** [Homebridge](https://homebridge.io/)

### Passos para Teste:

1. **Baixe e Instale os Aplicativos:**
   - Instale os aplicativos mencionados no seu iPhone.

2. **Configuração do Dispositivo:**
   - Adicione sua tomada inteligente ao aplicativo escolhido, seguindo as instruções de configuração.

3. **Criação de Automação:**
   - Explore as opções de automação disponíveis em cada aplicativo para verificar se eles permitem configurar temporizações mais precisas.

### Adicional: Configuração com Homebridge e Home+ 5

Se você optar por usar Homebridge, aqui está um guia rápido para configuração:

1. **Instalação do Homebridge:**
   - Instale o Homebridge em um Raspberry Pi ou em um servidor local seguindo as instruções no site oficial.

2. **Integração com HomeKit:**
   - Adicione seus dispositivos Tuya ao Homebridge usando o plugin Homebridge-Tuya.

3. **Configuração no Home+ 5:**
   - Use o aplicativo Home+ 5 para criar automações detalhadas, incluindo temporizações precisas.

### Conclusão

Essas opções devem fornecer a flexibilidade necessária para controlar sua tomada inteligente com maior precisão. Teste cada um para encontrar o que melhor atende às suas necessidades.

---

