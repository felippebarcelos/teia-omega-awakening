# 1231 - Integração câmeras Intelbras Jortan

### USUÁRIO

já te levando em consideração que possuo no terreno da minha casa de praia dois modens que fornecem energia separadamente onde o modem número 1 possui dois repetidores de sinal sendo o primeiro repetidor para o salão de festa e o segundo repetidor para a casa da Suzana no modem número 2 possui apenas um repetidor de sinal para o quarto do Tiago onde no modem número 1 possui conectado via internet o DVR mhdx 1004 da Intelbras e conectado no DVR estão conectadas quatro câmeras da Intelbras via cabo coaxial Onde consigo visualizar as imagens em tempo real via o aplicativo da Intelbras seja por computador ou por celular conectado também é o primeiro modem está a câmera da marca Jordan porém conectada via wi-fi 2.4g no repetidor do primeiro modem sendo repetidor do salão de festas possui conectado uma câmera também da marca Jortan conectada e integrada via aplicativo yoosee (ou cms client no windows) a mesma conta e no repetidor de sinal número 2 do modem número 1 possui mais duas câmeras da marca Jortan também Integradas ao aplicativo yoosee (ou cms client no windows) no modem número dois possui conectado via wi-fi 2.4g uma Alexa Echo show na cozinha e também conectada via wi-fi 2.4g com uma câmera também da marca Jortan conectada a mesma conta do aplicativo. O meu intuito com é conseguir obter as imagens pelo dvr das 4 cameras da intelbras e das 5 cameras da Jortan vinculadas ao app yoosee e cms client a uma mesma interface que consiga visualizar todas as 9 cameras em um layout só, que seja acessível via celular em uma internet  4g ou externa dos modens 1 e 2 e pela alexa echo show do modem 2 para visualizar as imagens em tempo real das 9 cameras, mesmo possuindo apenas uma camera conectada ao mesmo modem da alexa echo show. Me instrua apartir de alternativas relatadas compatíveis para o projeto

---

### ASSISTENTE

Para integrar e monitorar todas as nove câmeras (quatro da Intelbras conectadas ao DVR MHDX 1004 e cinco da marca Jortan vinculadas ao aplicativo Yoosee) em uma única interface acessível remotamente via dispositivos móveis e pelo Alexa Echo Show, siga as orientações abaixo:

**1. Integração das Câmeras Jortan ao DVR Intelbras:**

O DVR MHDX 1004 da Intelbras suporta a adição de câmeras IP através do protocolo ONVIF. Verifique se as câmeras Jortan são compatíveis com ONVIF. Caso sejam, proceda da seguinte forma:

- **Configuração das Câmeras Jortan:**
  - Acesse as configurações de cada câmera Jortan e habilite o protocolo ONVIF.
  - Anote o endereço IP, porta, nome de usuário e senha de cada câmera.

- **Adição ao DVR MHDX 1004:**
  - No menu do DVR, vá em "Dispositivo Remoto".
  - Clique em "Adicionar Manualmente".
  - Insira as informações de IP, porta, usuário e senha de cada câmera Jortan.
  - Selecione o protocolo ONVIF e atribua um canal disponível para cada câmera.
  - Aguarde até que o status da câmera mude para verde, indicando conexão bem-sucedida.

Para mais detalhes, consulte o guia da Intelbras sobre como adicionar câmeras IP ONVIF ao DVR: citeturn0search6

**2. Monitoramento Unificado via Aplicativo Intelbras:**

Após integrar todas as câmeras ao DVR, utilize o aplicativo Intelbras iSIC 6 para visualizar as imagens em tempo real:

- **No Smartphone:**
  - Baixe e instale o aplicativo iSIC 6.
  - Adicione o DVR utilizando o endereço IP ou o serviço de nuvem da Intelbras.
  - Acesse todas as câmeras conectadas ao DVR em uma única interface.

- **No Computador:**
  - Utilize o software Intelbras S.I.M. Plus para monitoramento.
  - Adicione o DVR e visualize as câmeras conforme necessário.

**3. Acesso Remoto via Alexa Echo Show:**

Para visualizar as câmeras no Alexa Echo Show, siga estes passos:

- **Habilitação da Skill:**
  - No aplicativo Alexa, procure e habilite a skill "Intelbras iSIC".

- **Vinculação de Conta:**
  - Faça login com as credenciais do aplicativo iSIC para vincular as contas.

- **Comandos de Voz:**
  - Utilize comandos como "Alexa, mostre a câmera [nome da câmera]" para visualizar as imagens no Echo Show.

**Considerações Importantes:**

- **Compatibilidade ONVIF:** Certifique-se de que todas as câmeras Jortan sejam compatíveis com o protocolo ONVIF para integração ao DVR.

- **Configurações de Rede:** Garanta que todas as câmeras e o DVR estejam na mesma rede local ou que haja roteamento adequado entre as redes dos modems 1 e 2.

- **Acesso Remoto:** Configure o acesso remoto ao DVR através de redirecionamento de portas ou utilize o serviço de nuvem da Intelbras para acesso externo seguro.

Seguindo essas etapas, você poderá monitorar todas as nove câmeras em uma interface unificada, acessível remotamente via dispositivos móveis e pelo Alexa Echo Show. 

---

### ASSISTENTE

Para integrar as nove câmeras (quatro da Intelbras e cinco da Jortan) em uma única interface acessível remotamente via dispositivos móveis e pelo Amazon Echo Show, siga as orientações abaixo:

**1. Integração das Câmeras Jortan ao DVR Intelbras MHDX 1004:**

O DVR MHDX 1004 da Intelbras suporta a adição de câmeras IP através do protocolo ONVIF. As câmeras Jortan, que utilizam o aplicativo Yoosee, geralmente são compatíveis com ONVIF, permitindo sua integração ao DVR.

**Passos para adicionar câmeras IP ao DVR:**

1. **Verifique a compatibilidade ONVIF das câmeras Jortan:**
   - Acesse as configurações das câmeras via aplicativo Yoosee ou CMS Client e habilite o protocolo ONVIF, se disponível.

2. **Configure as câmeras na mesma rede do DVR:**
   - Certifique-se de que todas as câmeras e o DVR estejam na mesma sub-rede para facilitar a detecção.

3. **Adicione as câmeras ao DVR:**
   - No DVR, acesse o menu "Dispositivo Remoto".
   - Clique em "Buscar" para que o DVR localize as câmeras na rede.
   - Selecione a câmera desejada e clique em "Adicionar".
   - Verifique se o status da câmera está verde (Online), indicando conexão bem-sucedida.

Para um guia visual detalhado, consulte o vídeo:

videoComo configurar câmera Wi-Fi que usa app Yoosee no DVR da Intelbrasturn0search1

**2. Acesso Remoto às Imagens:**

Após integrar todas as câmeras ao DVR, utilize o aplicativo Intelbras iSIC 6 para acessar as imagens remotamente via dispositivos móveis.

**Passos para configuração:**

1. **Configure o acesso remoto no DVR:**
   - No menu do DVR, acesse "Configurações de Rede" e habilite o serviço Intelbras Cloud.
   - Anote o número de série do DVR para uso no aplicativo.

2. **Instale o aplicativo iSIC 6:**
   - Disponível para Android e iOS nas respectivas lojas de aplicativos.

3. **Adicione o DVR ao aplicativo:**
   - Abra o iSIC 6 e selecione "Adicionar Dispositivo".
   - Insira o número de série do DVR e as credenciais de acesso.
   - Após a conexão, todas as câmeras integradas ao DVR estarão disponíveis para visualização.

**3. Integração com Amazon Echo Show:**

Para visualizar as câmeras no Echo Show, é necessário que as câmeras sejam compatíveis com Alexa. As câmeras Jortan, via aplicativo Yoosee, geralmente não possuem integração direta com Alexa. No entanto, ao integrar as câmeras ao DVR e utilizar o aplicativo iSIC 6, é possível espelhar a tela do dispositivo móvel no Echo Show para visualizar as imagens.

**Passos para espelhar a tela:**

1. **Habilite o modo de exibição no Echo Show:**
   - No Echo Show, deslize para baixo a partir do topo da tela e selecione "Configurações".
   - Vá em "Bluetooth" e coloque o dispositivo em modo de emparelhamento.

2. **Conecte o dispositivo móvel ao Echo Show:**
   - No smartphone, acesse as configurações de Bluetooth e conecte-se ao Echo Show.
   - Após a conexão, abra o aplicativo iSIC 6 e visualize as câmeras.
   - A imagem será transmitida para o Echo Show.

**Considerações Finais:**

- **Limitações de Canais IP no DVR:** O modelo MHDX 1004 suporta até 5 canais, sendo 4 analógicos e 1 IP. Para integrar todas as câmeras IP, considere a aquisição de um DVR com maior capacidade de canais IP ou a utilização de um NVR dedicado.

- **Estabilidade da Rede:** Certifique-se de que a rede Wi-Fi possui cobertura e largura de banda adequadas para suportar a transmissão de vídeo de todas as câmeras sem interrupções.

- **Segurança:** Mantenha o firmware do DVR e das câmeras atualizado e utilize senhas fortes para evitar acessos não autorizados.

Seguindo essas orientações, você poderá visualizar todas as nove câmeras em uma única interface, acessível remotamente via dispositivos móveis e pelo Amazon Echo Show. 

---

### USUÁRIO

como mencionado as cinco câmeras da marca Jortan Integradas ao App Yoosee possuem conectividade Cada uma com modens diferentes ou repetidores de sinais diferentes segregando e dificultando o nosso projeto e sua Alternativa de usufruir do DVR de Intelbras para conectar todas as câmeras via protocolo ou VIP visto que as câmeras nem conseguiriam ser identificadas pois o IP está agregado a cada câmera em seu respectivo modem ou repetidor de sinal 

---

### ASSISTENTE

Entendo que você deseja visualizar simultaneamente as imagens de quatro câmeras analógicas conectadas ao DVR Intelbras MHDX 1004 e de cinco câmeras IP da marca Jortan, cada uma conectada a diferentes modems ou repetidores, utilizando o aplicativo Yoosee. A integração dessas câmeras em uma única interface acessível remotamente, inclusive via dispositivos móveis e Amazon Echo Show, pode ser desafiadora devido à segmentação das redes. Abaixo, apresento alternativas para alcançar esse objetivo:

**1. Utilização de um Software de Gerenciamento de Vídeo (VMS):**

Um VMS permite centralizar o monitoramento de múltiplas câmeras, independentemente de estarem conectadas a diferentes redes.

- **Exemplo:** O software **iSpy** é uma opção gratuita que suporta diversas marcas e modelos de câmeras IP, incluindo aquelas que utilizam o aplicativo Yoosee. Ele permite a integração de câmeras de diferentes redes em uma única interface.

  - **Passos:**
    1. **Instalação:** Baixe e instale o iSpy no seu computador.
    2. **Adição de Câmeras:** Adicione cada câmera Jortan utilizando o protocolo RTSP ou ONVIF, conforme compatibilidade.
    3. **Integração do DVR:** Adicione o DVR Intelbras ao iSpy, permitindo o monitoramento das câmeras analógicas.
    4. **Acesso Remoto:** Configure o acesso remoto no iSpy para visualizar todas as câmeras via dispositivos móveis.

  - **Observação:** Certifique-se de que cada câmera Jortan tenha o protocolo ONVIF habilitado e que as portas necessárias estejam encaminhadas nos respectivos modems para permitir o acesso remoto.

**2. Configuração de uma VPN (Rede Privada Virtual):**

Uma VPN permite interconectar diferentes redes locais, criando uma rede única e segura.

- **Passos:**
  1. **Configuração da VPN:** Configure uma VPN que interligue todas as redes onde as câmeras estão conectadas.
  2. **Acesso às Câmeras:** Com a VPN ativa, todas as câmeras estarão na mesma rede virtual, facilitando sua integração em um único software de monitoramento.

  - **Observação:** A configuração de uma VPN requer conhecimento técnico avançado e pode implicar em custos adicionais.

**3. Utilização de um NVR (Network Video Recorder) com Suporte a Múltiplos Protocolos:**

Um NVR compatível com diversos protocolos pode centralizar o monitoramento de câmeras IP de diferentes fabricantes.

- **Passos:**
  1. **Aquisição de um NVR Compatível:** Escolha um NVR que suporte o protocolo ONVIF e seja compatível com as câmeras Jortan e Intelbras.
  2. **Adição das Câmeras:** Conecte todas as câmeras IP ao NVR, configurando-as conforme necessário.
  3. **Acesso Remoto:** Utilize o aplicativo do NVR para acessar as imagens remotamente.

  - **Observação:** Verifique a compatibilidade das câmeras Jortan com o NVR escolhido antes da aquisição.

**4. Utilização de um Serviço de Nuvem Compatível:**

Alguns serviços de nuvem permitem a integração de câmeras de diferentes fabricantes em uma única interface.

- **Exemplo:** O serviço **Angelcam** suporta diversas marcas de câmeras IP e oferece uma interface unificada para monitoramento.

  - **Passos:**
    1. **Criação de Conta:** Crie uma conta no Angelcam.
    2. **Adição das Câmeras:** Adicione cada câmera Jortan e o DVR Intelbras ao serviço, seguindo as instruções fornecidas.
    3. **Acesso Remoto:** Utilize o aplicativo do Angelcam para acessar todas as câmeras remotamente.

  - **Observação:** Este serviço pode implicar em custos mensais e requer que as câmeras sejam compatíveis com o serviço de nuvem.

**Considerações Importantes:**

- **Compatibilidade:** Verifique se as câmeras Jortan suportam os protocolos necessários (RTSP, ONVIF) para integração com os sistemas mencionados.

- **Configuração de Rede:** Pode ser necessário configurar redirecionamento de portas nos modems e garantir que as câmeras tenham endereços IP estáticos para facilitar a integração.

- **Segurança:** Assegure-se de que todas as conexões sejam seguras, utilizando senhas fortes e mantendo os firmwares atualizados.

- **Assistência Técnica:** Dada a complexidade da integração, pode ser recomendável consultar um profissional especializado em sistemas de segurança e redes para auxiliar na implementação.

Ao seguir uma dessas alternativas, você poderá centralizar o monitoramento de todas as suas câmeras em uma única interface, acessível remotamente via dispositivos móveis e Amazon Echo Show. 

---

### USUÁRIO

exist algum app ou software que possuia funcionalidade de integração a conta da yoosee ou cms client para conseguir acessar todas as imagens em tempo real fornecidas e agregadas a minha conta dayosse/cms client sem necessitar estar no mesmo wifi (sem ser o próprio cms client)

---

### ASSISTENTE

Sim, é possível acessar remotamente as câmeras vinculadas à sua conta Yoosee ou CMS Client sem estar na mesma rede Wi-Fi, utilizando aplicativos móveis ou softwares compatíveis.

**Aplicativo Yoosee para Dispositivos Móveis:**

O aplicativo Yoosee está disponível para smartphones e tablets, permitindo o monitoramento remoto das câmeras associadas à sua conta.

- **Download e Instalação:**
  - **Android:** Disponível na [Google Play Store](https://play.google.com/store/apps/details?id=com.yoosee).
  - **iOS:** Disponível na [App Store](https://apps.apple.com/app/yoosee/id1039638432).

- **Funcionalidades:**
  - Visualização em tempo real das câmeras.
  - Recebimento de notificações de eventos.
  - Controle de configurações das câmeras.

**Acesso via Navegador Web:**

Algumas câmeras compatíveis com o Yoosee oferecem acesso através de navegadores web, permitindo monitoramento remoto sem a necessidade de software adicional.

- **Passos:**
  1. Obtenha o endereço IP público ou utilize um serviço de DNS dinâmico para acessar a câmera remotamente.
  2. Certifique-se de que as portas necessárias estejam encaminhadas no roteador para permitir o acesso externo.
  3. Acesse o endereço IP ou domínio configurado no navegador e insira as credenciais de login da câmera.

**Considerações de Segurança:**

- Utilize senhas fortes e únicas para cada câmera.
- Mantenha o firmware das câmeras atualizado para corrigir vulnerabilidades.
- Considere utilizar uma VPN para acesso remoto seguro às câmeras.

Ao utilizar essas opções, você poderá monitorar suas câmeras remotamente, sem a necessidade de estar na mesma rede Wi-Fi, garantindo flexibilidade e segurança no acesso às imagens. 

---

### ASSISTENTE

Para acessar em tempo real todas as imagens das câmeras integradas à sua conta Yoosee ou CMS Client sem estar na mesma rede Wi-Fi, você pode utilizar o aplicativo **Yoosee** em dispositivos móveis ou o software **CMS Client** em computadores. Ambos permitem o monitoramento remoto das câmeras conectadas à sua conta, independentemente da rede em que você se encontra.

**Aplicativo Yoosee:**

- **Disponibilidade:** Disponível para dispositivos Android e iOS.
- **Funcionalidades:** Permite visualizar as imagens das câmeras em tempo real, reproduzir gravações e configurar alertas.
- **Acesso Remoto:** Após configurar as câmeras no aplicativo, você pode acessá-las de qualquer lugar com conexão à internet.

**Software CMS Client:**

- **Disponibilidade:** Compatível com sistemas Windows.
- **Funcionalidades:** Oferece recursos avançados de monitoramento, incluindo visualização em tempo real, reprodução de gravações e controle de configurações das câmeras.
- **Acesso Remoto:** Permite o acesso às câmeras de qualquer local, desde que o computador esteja conectado à internet.

Para utilizar o CMS Client, é necessário instalá-lo no seu computador e adicionar as câmeras utilizando as credenciais da sua conta Yoosee. O processo de instalação e configuração pode ser encontrado no vídeo a seguir:

videoCOMO BAIXAR E INSTALAR CORRETAMENTE O CMS CLIENTE PARA CÂMERA IP WIFI YOOSEEturn0search8

Além disso, o site oficial da Yoosee oferece informações sobre o monitoramento remoto das câmeras:

citeturn0search6

Essas ferramentas permitem que você monitore suas câmeras de segurança de forma eficiente e segura, sem a necessidade de estar conectado à mesma rede Wi-Fi. 

---

