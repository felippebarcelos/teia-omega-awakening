# 0903 - Instalando Home Assistant

### USUÁRIO

como instalar o home assistant no meu computador para conseguirmos programar meu esp32-wroom-32 + sensor bme280 para fornecer as devidas atualizações de informações de temperatura, humidade e pressão remotamente para o app do meu celular



---

### ASSISTENTE

Para instalar o Home Assistant no seu computador e programar o ESP32-WROOM-32 com o sensor BME280 para enviar atualizações de temperatura, umidade e pressão ao aplicativo do seu celular, você pode seguir estas etapas:

### 1. Instalação do Home Assistant
**Requisitos:**
- Um computador com sistema operacional Windows, macOS ou Linux.
- Python 3.9 ou superior instalado.

#### Passo a Passo:
1. **Instalar o Home Assistant:**
   - **Windows:**
     - Baixe o instalador oficial do Home Assistant [Home Assistant for Windows](https://www.home-assistant.io/installation/windows).
     - Execute o instalador e siga as instruções na tela.
   - **macOS/Linux:**
     - Abra o terminal e execute o seguinte comando:
       ```bash
       python3 -m pip install homeassistant
       ```
     - Após a instalação, inicie o Home Assistant com o comando:
       ```bash
       hass
       ```

2. **Configurar o Home Assistant:**
   - Acesse a interface web do Home Assistant em `http://localhost:8123`.
   - Complete o processo de configuração inicial, criando uma conta e definindo algumas configurações básicas.

### 2. Programar o ESP32-WROOM-32 + Sensor BME280

**Requisitos:**
- Arduino IDE ou VS Code com a extensão PlatformIO.
- Biblioteca do Home Assistant e MQTT instalada.

#### Passo a Passo:
1. **Conectar o ESP32:**
   - Instale o driver do ESP32 para seu sistema operacional.
   - Conecte o ESP32 ao computador usando um cabo USB.

2. **Configurar o Arduino IDE:**
   - Abra o Arduino IDE.
   - Vá em `File > Preferences`, e adicione o URL para o ESP32 no campo "Additional Board Manager URLs":
     ```
     https://dl.espressif.com/dl/package_esp32_index.json
     ```
   - Vá em `Tools > Board > Board Manager` e procure por "esp32". Instale o pacote de placas ESP32.

3. **Instalar Bibliotecas:**
   - No Arduino IDE, vá em `Sketch > Include Library > Manage Libraries`.
   - Instale as bibliotecas `Adafruit BME280` e `PubSubClient`.

4. **Carregar o Código para o ESP32:**
   - Use o seguinte código para configurar o ESP32 para enviar dados para o Home Assistant via MQTT:

   ```cpp
   #include <Wire.h>
   #include <Adafruit_Sensor.h>
   #include <Adafruit_BME280.h>
   #include <WiFi.h>
   #include <PubSubClient.h>

   // Defina suas credenciais de WiFi e MQTT
   const char* ssid = "SEU_SSID";
   const char* password = "SUA_SENHA";
   const char* mqtt_server = "SEU_ENDEREÇO_IP_DO_HOME_ASSISTANT";

   WiFiClient espClient;
   PubSubClient client(espClient);
   Adafruit_BME280 bme;

   void setup_wifi() {
     delay(10);
     WiFi.begin(ssid, password);
     while (WiFi.status() != WL_CONNECTED) {
       delay(500);
     }
   }

   void reconnect() {
     while (!client.connected()) {
       if (client.connect("ESP32Client")) {
         client.subscribe("home/assistant");
       } else {
         delay(5000);
       }
     }
   }

   void setup() {
     Serial.begin(115200);
     setup_wifi();
     client.setServer(mqtt_server, 1883);
     bme.begin(0x76);
   }

   void loop() {
     if (!client.connected()) {
       reconnect();
     }
     client.loop();
     float temp = bme.readTemperature();
     float hum = bme.readHumidity();
     float pres = bme.readPressure() / 100.0F;

     char tempStr[8];
     dtostrf(temp, 1, 2, tempStr);
     client.publish("home/temperature", tempStr);

     char humStr[8];
     dtostrf(hum, 1, 2, humStr);
     client.publish("home/humidity", humStr);

     char presStr[8];
     dtostrf(pres, 1, 2, presStr);
     client.publish("home/pressure", presStr);

     delay(2000);
   }
   ```

5. **Carregar o Código no ESP32:**
   - Conecte o ESP32 ao computador.
   - No Arduino IDE, selecione `Tools > Board > ESP32 Dev Module`.
   - Selecione a porta serial em `Tools > Port`.
   - Clique em `Upload` para carregar o código.

### 3. Configurar o MQTT no Home Assistant

1. **Instalar o Add-on MQTT Broker:**
   - Vá em `Supervisor > Add-on Store`.
   - Instale o `Mosquitto broker`.

2. **Configurar o MQTT:**
   - No `configuration.yaml` do Home Assistant, adicione:
   ```yaml
   mqtt:
     broker: localhost
   sensor:
     - platform: mqtt
       name: "Temperatura"
       state_topic: "home/temperature"
     - platform: mqtt
       name: "Umidade"
       state_topic: "home/humidity"
     - platform: mqtt
       name: "Pressão"
       state_topic: "home/pressure"
   ```

3. **Reiniciar o Home Assistant:**
   - Vá em `Configuration > Server Controls > Restart` para reiniciar o Home Assistant.

### 4. Monitorar no Aplicativo do Celular

1. **Baixar o App do Home Assistant:**
   - Instale o aplicativo Home Assistant em seu celular (disponível para Android e iOS).

2. **Conectar ao Servidor:**
   - Abra o aplicativo e insira o endereço do seu Home Assistant (`http://[SEU_ENDEREÇO_IP]:8123`).

3. **Visualizar Sensores:**
   - Após a configuração, você deve conseguir ver as leituras de temperatura, umidade e pressão atualizadas no aplicativo do Home Assistant.

Essa configuração permitirá que o ESP32 envie dados do sensor BME280 para o Home Assistant, que poderá ser acessado remotamente no seu celular.

---

### USUÁRIO

Qual é a imagem apropriado no windows?

---

### USUÁRIO

Qual é a imagem apropriado no windows?
Caixa Virtual(.vdi)

Estação de trabalho VMware(.vmdk)

Hyper-V(.vhdx)


---

### ASSISTENTE

Para instalar o Home Assistant no Windows, você deve usar o método que utiliza uma máquina virtual (VM) ou o método que usa o Docker. O método mais comum e recomendado é o uso do Docker, pois garante uma instalação mais estável e facilita atualizações e manutenções.

### Opção 1: Usar Docker (Recomendado)
**Requisitos:**
- Instale o Docker Desktop para Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop).
- Certifique-se de que seu sistema suporta virtualização e que esta opção esteja ativada na BIOS.

#### Passo

---

### ASSISTENTE

A escolha da imagem apropriada para instalar o Home Assistant no Windows depende do software de virtualização que você pretende usar. Aqui estão as opções e suas respectivas descrições:

1. **VirtualBox (.vdi)**:
   - **Imagem apropriada**: Caixa Virtual (.vdi)
   - **Descrição**: Use esta opção se você estiver utilizando o **Oracle VirtualBox** como software de virtualização. O VirtualBox é um software gratuito e de código aberto que permite executar máquinas virtuais no Windows. 
   - **Como usar**: Baixe a imagem `.vdi` e, no VirtualBox, crie uma nova máquina virtual, selecionando o arquivo `.vdi` como o disco rígido.

2. **VMware Workstation (.vmdk)**:
   - **Imagem apropriada**: Estação de trabalho VMware (.vmdk)
   - **Descrição**: Esta opção é ideal se você estiver utilizando o **VMware Workstation** ou **VMware Player**. VMware é um software de virtualização proprietário que também permite a execução de máquinas virtuais no Windows. 
   - **Como usar**: Baixe a imagem `.vmdk` e, no VMware Workstation, crie uma nova máquina virtual e selecione o arquivo `.vmdk` como o disco rígido.

3. **Hyper-V (.vhdx)**:
   - **Imagem apropriada**: Hyper-V (.vhdx)
   - **Descrição**: Use esta opção se você estiver utilizando o **Hyper-V**, o software de virtualização nativo do Windows (disponível no Windows 10 Pro, Enterprise e Windows Server). 
   - **Como usar**: Ative o Hyper-V em seu Windows, crie uma nova máquina virtual no Hyper-V Manager e selecione o arquivo `.vhdx` como o disco rígido.

### Qual Escolher?

- **VirtualBox (.vdi)**: Se você preferir um software de virtualização gratuito e de código aberto.
- **VMware Workstation (.vmdk)**: Se você já utiliza ou prefere o VMware Workstation/Player.
- **Hyper-V (.vhdx)**: Se você deseja utilizar o software de virtualização nativo do Windows (disponível apenas no Windows 10 Pro, Enterprise e Windows Server).

Se você já tem um desses softwares instalados ou prefere uma solução específica, escolha a imagem correspondente para instalar o Home Assistant.

---

### USUÁRIO

pra seguir com a primeira opção como baixar as necessidades

---

### USUÁRIO

pra seguir com a primeira opção como baixar as necessidades (windows)

---

### ASSISTENTE

Para seguir com a primeira opção (VirtualBox), você precisará instalar o Oracle VirtualBox e também baixar a imagem `.vdi` do Home Assistant. Aqui estão as instruções detalhadas:

### Passo a Passo para Instalar o VirtualBox e Baixar a Imagem `.vdi` do Home Assistant

#### 1. Instalar o Oracle VirtualBox

1. **Baixar o VirtualBox:**
   - Acesse o site oficial do VirtualBox: [Oracle VirtualBox](https://www.virtualbox.org/).
   - Clique em **Download VirtualBox**.
   - Escolha a versão para **Windows hosts** e baixe o instalador.

2. **Instalar o VirtualBox:**
   - Abra o instalador que você baixou e siga as instruções na tela.
   - Aceite os termos de licença e escolha as opções padrão de instalação.
   - Quando solicitado, clique em **Install** para iniciar a instalação.

3. **Instalar o VirtualBox Extension Pack (opcional, mas recomendado):**
   - Acesse novamente o site do VirtualBox e baixe o **VirtualBox Extension Pack** (compatível com sua versão do VirtualBox).
   - Depois de baixar, clique duas vezes no arquivo para instalar o pacote de extensão. Este pacote adiciona funcionalidades extras, como suporte a dispositivos USB 2.0 e 3.0, suporte a RDP, etc.

#### 2. Baixar a Imagem `.vdi` do Home Assistant

1. **Baixar a Imagem Virtual:**
   - Acesse a página de download do Home Assistant: [Home Assistant OS](https://www.home-assistant.io/installation/).
   - Na seção "Home Assistant OS", escolha a opção **VirtualBox (.vdi)** para baixar a imagem.

2. **Configuração da Máquina Virtual no VirtualBox:**

- **Abra o VirtualBox**:
  - Clique em **Novo** para criar uma nova máquina virtual.
  
- **Configurar a Máquina Virtual**:
  - **Nome**: "Home Assistant".
  - **Tipo**: Linux.
  - **Versão**: Linux 64-bit.
  - Clique em **Next**.

- **Configurar Memória (RAM)**:
  - Alocar pelo menos **2 GB (2048 MB)** de RAM para o Home Assistant (ou mais, dependendo dos recursos disponíveis no seu computador).
  - Clique em **Next**.

- **Adicionar Disco Rígido Virtual**:
  - Selecione a opção **Use an existing virtual hard disk file**.
  - Clique no ícone da pasta ao lado e selecione a imagem `.vdi` do Home Assistant que você baixou.
  - Clique em **Create**.

3. **Configurar a Máquina Virtual:**
   - Selecione a máquina virtual "Home Assistant" recém-criada na lista.
   - Clique em **Configurações**.
   - Vá até a aba **Rede** e selecione o **Adaptador 1** como "Conectado a: Rede NAT". (Isso permitirá que a máquina virtual tenha acesso à internet.)
   - Clique em **OK** para salvar as configurações.

#### 3. Iniciar o Home Assistant no VirtualBox

1. **Iniciar a Máquina Virtual:**
   - Selecione a máquina virtual "Home Assistant" e clique em **Iniciar**.
   - O Home Assistant começará a inicializar. O processo de configuração inicial pode levar alguns minutos.

2. **Acessar o Home Assistant:**
   - Depois que o Home Assistant for iniciado, você poderá acessá-lo através de um navegador da web no endereço:
   ```
   http://localhost:8123
   ```
   - Complete o processo de configuração inicial, criando uma conta e definindo algumas configurações básicas.

#### 4. Configurar a Integração com o ESP32-WROOM-32 + Sensor BME280

Após configurar o Home Assistant, você poderá seguir os passos mencionados anteriormente para integrar o seu ESP32-WROOM-32 com o sensor BME280 usando MQTT.

Caso tenha mais dúvidas ou precise de assistência adicional durante o processo, estou aqui para ajudar!

---

### ASSISTENTE

Para seguir com a primeira opção usando o **VirtualBox** no Windows, você precisará instalar o **Oracle VirtualBox** e o **Home Assistant OS (VDI)**. Aqui estão os passos detalhados para baixar e instalar tudo o que você precisa:

### Passo 1: Baixar e Instalar o VirtualBox

1. **Baixar o Oracle VirtualBox:**
   - Acesse o site oficial do VirtualBox: [VirtualBox Download](https://www.virtualbox.org/wiki/Downloads).
   - Clique em **"Windows hosts"** para baixar o instalador do VirtualBox para Windows.

2. **Instalar o VirtualBox:**
   - Execute o arquivo de instalação que você baixou (`VirtualBox-x.x.x-Win.exe`).
   - Siga as instruções na tela para instalar o VirtualBox no seu computador.
   - Durante a instalação, mantenha as configurações padrão, a menos que tenha um motivo específico para alterá-las.
   - Clique em **"Install"** e depois em **"Finish"** para concluir a instalação.

3. **Instalar o VirtualBox Extension Pack (Opcional, mas recomendado):**
   - Ainda na página de downloads do VirtualBox, baixe o **VirtualBox Extension Pack** clicando em **"All supported platforms"**.
   - Após o download, abra o VirtualBox, vá em **"File" > "Preferences" > "Extensions"**, clique no ícone de adicionar e selecione o arquivo `.vbox-extpack` que você baixou.
   - Siga as instruções para instalar a extensão.

### Passo 2: Baixar a Imagem do Home Assistant (VDI)

1. **Baixar a Imagem do Home Assistant para VirtualBox:**
   - Acesse o site oficial do Home Assistant: [Home Assistant OS (VirtualBox VDI)](https://www.home-assistant.io/installation/virtualbox).
   - Clique no link para baixar a imagem **VirtualBox (.vdi)**.
   - Aguarde o download ser concluído.

### Passo 3: Configurar a Máquina Virtual no VirtualBox

1. **Criar uma Nova Máquina Virtual:**
   - Abra o VirtualBox.
   - Clique em **"New"** para criar uma nova máquina virtual.
   - Dê um nome para a máquina virtual, como "Home Assistant".
   - **Tipo:** Selecione **Linux**.
   - **Versão:** Selecione **Other Linux (64-bit)**.

2. **Ajustar a Memória:**
   - Defina a quantidade de memória RAM para a máquina virtual. Recomendo pelo menos **2 GB (2048 MB)** ou mais, dependendo da quantidade de RAM disponível em seu computador.

3. **Selecionar o Disco Rígido:**
   - Escolha a opção **"Use an existing virtual hard disk file"** e clique no ícone de pasta.
   - Selecione o arquivo `.vdi` do Home Assistant que você baixou.

4. **Configurar a Rede (Opcional):**
   - Na tela principal do VirtualBox, selecione a máquina virtual que você criou e clique em **"Settings"**.
   - Vá para a aba **Network** e certifique-se de que a opção "Attached to" está definida como **Bridged Adapter** para que a máquina virtual possa acessar a rede local como se fosse um dispositivo separado.

5. **Iniciar a Máquina Virtual:**
   - Clique em **"Start"** para iniciar a máquina virtual.
   - O Home Assistant OS deve iniciar e você verá a interface de instalação/configuração.

### Passo 4: Acessar o Home Assistant pelo Navegador

1. **Acessar a Interface Web do Home Assistant:**
   - Após alguns minutos de inicialização, abra um navegador no seu computador.
   - Digite o endereço: `http://homeassistant.local:8123` ou `http://[IP-DA-MÁQUINA-VIRTUAL]:8123`.
   - Complete o processo de configuração inicial do Home Assistant.

### Passo 5: Instalar e Configurar o MQTT e Adicionar o ESP32

Para permitir que o ESP32 envie dados para o Home Assistant, você precisará configurar o **Mosquitto MQTT Broker** conforme mencionado na resposta anterior e seguir os passos para programar o ESP32 para enviar os dados usando MQTT.

### Resumo

- **Instalar o VirtualBox** e o **VirtualBox Extension Pack**.
- **Baixar a imagem do Home Assistant (.vdi)**.
- **Criar uma máquina virtual** no VirtualBox e selecionar a imagem baixada.
- **Iniciar a máquina virtual** e acessar o Home Assistant pela interface web.

Depois de completar esses passos, você estará pronto para usar o Home Assistant no seu computador e conectar seu ESP32 para monitoramento remoto!

---

### USUÁRIO

muito dificil, nao tem como partir do terminal para baixar o home assistant 

---

### ASSISTENTE

Sim, é possível instalar o Home Assistant diretamente no Windows usando o terminal do PowerShell, o que pode simplificar o processo. Você pode instalar o Home Assistant usando o **Windows Subsystem for Linux (WSL)**, que permite rodar uma distribuição Linux no Windows. Aqui estão os passos para realizar essa instalação:

### Passo 1: Instalar o Windows Subsystem for Linux (WSL)

1. **Abrir o PowerShell como Administrador:**
   - Clique com o botão direito no menu **Iniciar** e selecione **Windows PowerShell (Admin)**.

2. **Instalar o WSL:**
   - No terminal do PowerShell, execute o seguinte comando para instalar o WSL e definir o WSL 2 como padrão:
   ```bash
   wsl --install
   ```

   - Isso instalará a versão padrão do Ubuntu. O processo de instalação pode levar alguns minutos, e o sistema pode solicitar que você reinicie o computador.

### Passo 2: Instalar o Home Assistant usando o WSL

1. **Abrir o Ubuntu no WSL:**
   - Após reiniciar, abra o **Ubuntu** (ou sua distribuição de escolha) no WSL pelo menu Iniciar.

2. **Atualizar Pacotes e Instalar Dependências:**
   - No terminal do Ubuntu, execute os seguintes comandos para atualizar os pacotes e instalar as dependências necessárias:
   ```bash
   sudo apt update
   sudo apt upgrade -y
   sudo apt install python3 python3-venv python3-pip -y
   ```

3. **Criar um Ambiente Virtual para o Home Assistant:**
   - Crie um diretório para o Home Assistant:
   ```bash
   mkdir homeassistant
   cd homeassistant
   ```
   - Crie um ambiente virtual Python:
   ```bash
   python3 -m venv .
   ```
   - Ative o ambiente virtual:
   ```bash
   source bin/activate
   ```

4. **Instalar o Home Assistant:**
   - Instale o Home Assistant usando `pip`:
   ```bash
   pip install homeassistant
   ```

5. **Iniciar o Home Assistant:**
   - Para iniciar o Home Assistant, execute:
   ```bash
   hass
   ```
   - O Home Assistant começará a iniciar e estará disponível em `http://localhost:8123`.

### Passo 3: Acessar o Home Assistant

1. **Acessar a Interface Web:**
   - Abra o seu navegador e digite `http://localhost:8123`.
   - Siga as instruções na tela para completar a configuração inicial.

### Resumo dos Passos

1. Instale o WSL com Ubuntu (ou outra distribuição Linux).
2. Use o terminal do Ubuntu para instalar o Home Assistant.
3. Inicie o Home Assistant e acesse-o no navegador.

Essa abordagem elimina a necessidade de máquinas virtuais complexas e utiliza o WSL para fornecer um ambiente Linux diretamente no Windows, simplificando o processo de instalação e execução do Home Assistant.

---

### USUÁRIO

Instalando: Plataforma de Máquina Virtual
Plataforma de Máquina Virtual foi instalado.
Instalando: Subsistema do Windows para Linux
Subsistema do Windows para Linux foi instalado.
Instalando: Ubuntu
Ubuntu foi instalado.
Êxito na operação requisitada. As alterações só terão efeito depois que o sistema for reiniciado.
PS C:\Users\felip>

---

### ASSISTENTE

Ótimo! Agora que você instalou o Subsistema do Windows para Linux (WSL) e o Ubuntu, você precisa reiniciar o seu sistema para aplicar as alterações.

### Passos a Seguir

1. **Reinicie o Seu Computador:**
   - Feche todos os programas abertos e reinicie o computador.

2. **Abrir o Ubuntu:**
   - Após a reinicialização, clique no menu **Iniciar** e procure por **Ubuntu**. Clique para abrir o terminal do Ubuntu.

3. **Configuração Inicial do Ubuntu:**
   - Ao abrir o Ubuntu pela primeira vez, ele pedirá para você configurar um nome de usuário e uma senha para o ambiente Linux. Siga as instruções na tela e anote o nome de usuário e senha que você escolher.

4. **Atualizar Pacotes do Ubuntu:**
   - No terminal do Ubuntu, execute os seguintes comandos para atualizar o sistema e instalar as dependências necessárias:
   ```bash
   sudo apt update
   sudo apt upgrade -y
   sudo apt install python3 python3-venv python3-pip -y
   ```

5. **Criar um Ambiente Virtual para o Home Assistant:**
   - No terminal do Ubuntu, crie um diretório para o Home Assistant e um ambiente virtual Python:
   ```bash
   mkdir homeassistant
   cd homeassistant
   python3 -m venv .
   source bin/activate
   ```

6. **Instalar o Home Assistant:**
   - Com o ambiente virtual ativado, instale o Home Assistant usando o comando:
   ```bash
   pip install homeassistant
   ```

7. **Iniciar o Home Assistant:**
   - Para iniciar o Home Assistant, digite:
   ```bash
   hass
   ```
   - O Home Assistant começará a iniciar e estará disponível em `http://localhost:8123`.

8. **Acessar o Home Assistant:**
   - Abra o navegador da web e digite `http://localhost:8123` para acessar a interface do Home Assistant.

Após seguir esses passos, você terá o Home Assistant instalado e rodando em seu computador através do Ubuntu no WSL. Se precisar de mais ajuda durante o processo, é só avisar!

---

### USUÁRIO

Installing, this may take a few minutes...
WslRegisterDistribution failed with error: 0x8004032d
Error: 0x8004032d (null)
Press any key to continue...



---

### ASSISTENTE

O erro `0x8004032d` ao tentar registrar a distribuição Ubuntu no WSL pode ocorrer por alguns motivos, como permissões insuficientes, configurações do sistema ou problemas com a instalação do WSL. Vamos tentar alguns passos para resolver isso:

### Passo 1: Verificar se o WSL Está Instalado Corretamente

1. **Abrir o PowerShell como Administrador:**
   - Clique com o botão direito no menu **Iniciar** e selecione **Windows PowerShell (Admin)**.

2. **Verificar a Versão do WSL:**
   - No terminal do PowerShell, execute o comando abaixo para verificar a versão do WSL:
   ```bash
   wsl --list --verbose
   ```
   - Isso deve mostrar as distribuições instaladas e suas versões. Se não aparecer nada ou houver erros, significa que há um problema com a instalação.

3. **Definir o WSL 2 Como Padrão (Se Ainda Não Foi Feito):**
   - Defina o WSL 2 como padrão com o comando:
   ```bash
   wsl --set-default-version 2
   ```

### Passo 2: Reinstalar ou Corrigir a Instalação do WSL

1. **Desinstalar e Reinstalar o WSL:**
   - Tente desinstalar o WSL e reinstalá-lo:
   ```bash
   dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart
   dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
   ```

   - Após desinstalar, reinstale usando:
   ```bash
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

   - Reinicie o seu computador.

2. **Baixar e Instalar o Pacote de Atualização Manualmente:**
   - Acesse a página de instalação manual do WSL 2 no site da Microsoft: [Atualização do Kernel do WSL 2](https://aka.ms/wsl2kernel).
   - Baixe e instale o pacote de atualização do kernel do WSL 2.

### Passo 3: Instalar a Distribuição Ubuntu Novamente

1. **Reinstalar o Ubuntu pelo PowerShell:**
   - No PowerShell, execute o seguinte comando para reinstalar o Ubuntu:
   ```bash
   wsl --install -d Ubuntu
   ```
   - Isso baixará e instalará a distribuição Ubuntu mais recente no WSL.

2. **Verificar se o Ubuntu foi Instalado Corretamente:**
   - Após a instalação, abra o Ubuntu pelo menu Iniciar e verifique se ele inicia corretamente.

### Passo 4: Configurações Adicionais

Se o erro persistir:

- **Verifique as Configurações de Virtualização no BIOS:**
  - Certifique-se de que a virtualização (VT-x ou AMD-V) esteja ativada no BIOS do seu computador.
  
- **Verifique Atualizações do Windows:**
  - Certifique-se de que o seu Windows esteja atualizado. Algumas versões do WSL 2 exigem atualizações específicas.

### Passo 5: Reinicie e Tente Novamente

Depois de seguir esses passos, reinicie o computador e tente instalar e abrir o Ubuntu novamente.

Caso o problema persista, há outras soluções mais avançadas que podemos tentar.

---

### USUÁRIO

O Windows PowerShell
Copyright (C) Microsoft Corporation. Todos os direitos reservados.

Instale o PowerShell mais recente para obter novos recursos e aprimoramentos! https://aka.ms/PSWindows

PS C:\Users\felip> wsl --list --verbose
O Subsistema do Windows para Linux não tem distribuições instaladas.

Use 'wsl.exe --list --online' para listar as distribuições disponíveis.
e 'wsl.exe --install <Distro>' para instalar.

As distribuições também podem ser instaladas visitando a Microsoft Store:
https://aka.ms/wslstore
Error code: Wsl/WSL_E_DEFAULT_DISTRO_NOT_FOUND
PS C:\Users\felip> wsl --set-default-version 2
Para informações sobre as principais diferenças com o WSL 2, visite https://aka.ms/wsl2

A operação foi concluída com êxito.
PS C:\Users\felip> dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart

Erro: 740

Permissões elevadas obrigatórias para execução do DISM.
Use um prompt de comandos com privilégios elevados para concluir estas tarefas.
PS C:\Users\felip> dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart

Erro: 740

Permissões elevadas obrigatórias para execução do DISM.
Use um prompt de comandos com privilégios elevados para concluir estas tarefas.
PS C:\Users\felip>

---

### ASSISTENTE

Os erros que você está recebendo indicam que o comando `DISM` requer privilégios administrativos para ser executado. Para corrigir isso, você precisa abrir o PowerShell como Administrador. Vamos repetir os passos com as permissões corretas.

### Passo 1: Abrir o PowerShell como Administrador

1. **Fechar o PowerShell atual:**
   - Feche a janela atual do PowerShell.

2. **Abrir o PowerShell com Permissões Administrativas:**
   - Clique com o botão direito no menu **Iniciar** e selecione **Windows PowerShell (Admin)**.
   - Isso abrirá o PowerShell com permissões administrativas.

### Passo 2: Desinstalar e Reinstalar o WSL

Agora que você tem permissões administrativas, execute os seguintes comandos:

1. **Desativar o WSL e a Plataforma de Máquina Virtual:**
   ```bash
   dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart
   dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
   ```

2. **Reinstalar o WSL e a Plataforma de Máquina Virtual:**
   ```bash
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

3. **Reiniciar o Computador:**
   - Após executar os comandos, reinicie o seu computador.

### Passo 3: Baixar e Instalar o Ubuntu Novamente

1. **Instalar o Ubuntu pelo PowerShell:**
   - Após reiniciar, abra novamente o **Windows PowerShell (Admin)**.
   - Instale o Ubuntu executando:
   ```bash
   wsl --install -d Ubuntu
   ```

2. **Aguardar a Instalação e Abrir o Ubuntu:**
   - Aguarde a instalação ser concluída e depois abra o Ubuntu pelo menu **Iniciar**.

### Passo 4: Seguir com a Instalação do Home Assistant

Após a instalação do Ubuntu, siga os passos mencionados anteriormente para instalar e configurar o Home Assistant.

Se houver mais alguma dúvida ou se aparecerem outros erros, estou aqui para ajudar!

---

### USUÁRIO

O Windows PowerShell
Copyright (C) Microsoft Corporation. Todos os direitos reservados.

Instale o PowerShell mais recente para obter novos recursos e aprimoramentos! https://aka.ms/PSWindows

PS C:\Users\felip> dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart

Ferramenta de Gerenciamento e Manutenção de Imagens de Implantação
Versão: 10.0.22621.2792

Versão da Imagem: 10.0.22631.4112

Desabilitando recurso(s)
[==========================100.0%==========================]
A operação foi concluída com êxito.
PS C:\Users\felip> dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart

Ferramenta de Gerenciamento e Manutenção de Imagens de Implantação
Versão: 10.0.22621.2792

Versão da Imagem: 10.0.22631.4112

Desabilitando recurso(s)
[==========================100.0%==========================]
A operação foi concluída com êxito.
PS C:\Users\felip> dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

Ferramenta de Gerenciamento e Manutenção de Imagens de Implantação
Versão: 10.0.22621.2792

Versão da Imagem: 10.0.22631.4112

Habilitando recurso(s)
[==========================100.0%==========================]
A operação foi concluída com êxito.
PS C:\Users\felip> dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Ferramenta de Gerenciamento e Manutenção de Imagens de Implantação
Versão: 10.0.22621.2792

Versão da Imagem: 10.0.22631.4112

Habilitando recurso(s)
[==========================100.0%==========================]
A operação foi concluída com êxito.
PS C:\Users\felip> wsl --install -d Ubuntu
Instalando o componente opcional do Windows: VirtualMachinePlatform

Ferramenta de Gerenciamento e Manutenção de Imagens de Implantação
Versão: 10.0.22621.2792

Versão da Imagem: 10.0.22631.4112

Habilitando recurso(s)
[==========================100.0%==========================]
A operação foi concluída com êxito.
Ubuntu já está instalado.
Êxito na operação requisitada. As alterações só terão efeito depois que o sistema for reiniciado.
PS C:\Users\felip>

---

### ASSISTENTE

Perfeito! Os comandos foram executados com sucesso, e o subsistema do Windows para Linux (WSL) foi configurado corretamente, assim como a plataforma de máquina virtual necessária. O próximo passo é reiniciar o computador para que as alterações sejam aplicadas.

### Passo a Passo Após Reiniciar

1. **Reinicie o Computador:**
   - Feche todos os programas e reinicie o seu computador.

2. **Abrir o Ubuntu:**
   - Após reiniciar, vá para o menu **Iniciar** e procure por **Ubuntu**. Clique para abrir o terminal do Ubuntu.

3. **Configuração Inicial do Ubuntu:**
   - O Ubuntu pedirá que você configure um nome de usuário e uma senha. Siga as instruções na tela e defina essas informações.

4. **Atualizar Pacotes e Instalar Dependências:**
   - No terminal do Ubuntu, digite os seguintes comandos para atualizar os pacotes do sistema e instalar as dependências necessárias:
   ```bash
   sudo apt update
   sudo apt upgrade -y
   sudo apt install python3 python3-venv python3-pip -y
   ```

5. **Criar um Ambiente Virtual e Instalar o Home Assistant:**
   - Crie um diretório para o Home Assistant:
   ```bash
   mkdir homeassistant
   cd homeassistant
   ```
   - Crie um ambiente virtual Python e ative-o:
   ```bash
   python3 -m venv .
   source bin/activate
   ```
   - Instale o Home Assistant:
   ```bash
   pip install homeassistant
   ```

6. **Iniciar o Home Assistant:**
   - Inicie o Home Assistant executando:
   ```bash
   hass
   ```
   - O Home Assistant começará a iniciar e estará disponível em `http://localhost:8123` no seu navegador.

### Conclusão

Depois de seguir esses passos, você terá o Home Assistant rodando no Ubuntu, dentro do WSL, no seu Windows. Se encontrar qualquer dificuldade, estou aqui para ajudar!

---

### USUÁRIO

ao abrir o ubuntu apos reiniciar o sistema apareceu:
Installing, this may take a few minutes...
WslRegisterDistribution failed with error: 0x80370102
Please enable the Virtual Machine Platform Windows feature and ensure virtualization is enabled in the BIOS.
For information please visit https://aka.ms/enablevirtualization
Press any key to continue...

---

### ASSISTENTE

O erro `0x80370102` indica que o recurso de virtualização do sistema operacional ou do hardware não está habilitado corretamente. Para solucionar esse problema, você precisa:

1. **Ativar a Virtualização no BIOS do Computador:**
2. **Certificar-se de que a Plataforma de Máquina Virtual (Virtual Machine Platform) esteja habilitada no Windows.**

### Passo 1: Ativar a Virtualização no BIOS

A virtualização precisa estar ativada no BIOS do seu computador para que o WSL 2 funcione corretamente. Siga estas instruções:

1. **Reinicie o Computador:**
   - Durante a inicialização, pressione a tecla designada para acessar o BIOS/UEFI (geralmente `Esc`, `Del`, `F2`, `F10`, ou `F12`, dependendo do fabricante).

2. **Acessar a Configuração de Virtualização:**
   - Procure a configuração de **Virtualização** no BIOS/UEFI. Esta configuração pode ter nomes como:
     - **Intel Virtualization Technology (VT-x)**
     - **AMD-V**
     - **SVM Mode** (para processadores AMD)
     - **Virtualization Extensions**
   - Ative esta opção.

3. **Salvar e Sair:**
   - Salve as alterações (geralmente pressionando `F10`) e saia do BIOS/UEFI.

### Passo 2: Habilitar a Plataforma de Máquina Virtual no Windows

1. **Abrir o PowerShell como Administrador:**
   - Clique com o botão direito no menu **Iniciar** e selecione **Windows PowerShell (Admin)**.

2. **Certificar-se de que a Plataforma de Máquina Virtual esteja Habilitada:**
   - Execute o seguinte comando no PowerShell:
   ```bash
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

3. **Reiniciar o Computador:**
   - Reinicie o computador novamente para garantir que todas as configurações foram aplicadas.

### Passo 3: Verificar a Instalação do WSL

1. **Abra o Ubuntu novamente:**
   - Após reiniciar, vá novamente ao menu **Iniciar** e abra o **Ubuntu**.

2. **Concluir a Instalação:**
   - A instalação do Ubuntu deve prosseguir sem erros. Siga as instruções na tela para configurar o ambiente.

### Resumo

1. **Ative a virtualização no BIOS.**
2. **Habilite a Plataforma de Máquina Virtual usando o PowerShell.**
3. **Reinicie o computador e tente novamente.**

Se, após seguir estes passos, o erro ainda persistir, é possível que haja uma configuração adicional específica do sistema ou hardware que necessite de ajustes.

---

### USUÁRIO

Após a ativação da virtualização na bios e reiniciar o computador, como habilitar a plataforma de maquina virtual usando o powershell?

---

### ASSISTENTE

Após ativar a virtualização no BIOS, você precisará habilitar a Plataforma de Máquina Virtual (Virtual Machine Platform) no Windows usando o PowerShell com permissões administrativas. Siga os passos abaixo para fazer isso:

### Passo a Passo para Habilitar a Plataforma de Máquina Virtual no Windows

1. **Abrir o PowerShell como Administrador:**
   - Clique com o botão direito do mouse no menu **Iniciar** e selecione **Windows PowerShell (Admin)**.
   - Isso abrirá o PowerShell com privilégios administrativos.

2. **Habilitar a Plataforma de Máquina Virtual:**
   - No PowerShell, execute o seguinte comando para habilitar a Plataforma de Máquina Virtual:
   ```bash
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```
   - Aguarde a execução do comando. O PowerShell deve mostrar uma mensagem indicando que a operação foi concluída com êxito.

3. **Reiniciar o Computador:**
   - Após habilitar a Plataforma de Máquina Virtual, você precisará reiniciar o computador para que as alterações entrem em vigor.

### Passo 3: Verificar a Instalação do WSL e do Ubuntu

1. **Abra o Ubuntu novamente:**
   - Após reiniciar, vá para o menu **Iniciar** e abra o **Ubuntu**.

2. **Concluir a Instalação do Ubuntu:**
   - O Ubuntu deve iniciar normalmente. Siga as instruções na tela para completar a configuração inicial.

### Resumo dos Passos

- Ative a virtualização no BIOS e reinicie o computador.
- Abra o PowerShell como administrador e execute o comando para habilitar a Plataforma de Máquina Virtual.
- Reinicie o computador novamente e abra o Ubuntu.

Se tudo estiver configurado corretamente, o Ubuntu deve iniciar sem problemas no WSL. Se você encontrar qualquer outro erro, me avise e eu ajudarei!

---

### USUÁRIO

após o passo no powershell, reiniciei meu computador e quero saber como prossigo após abrir o ubuntu:
root@FelippeBarcelos:~#

---

### ASSISTENTE

Ótimo! Agora que você abriu o Ubuntu no WSL e está no terminal como o usuário root (`root@FelippeBarcelos:~#`), podemos prosseguir com a configuração do ambiente e a instalação do Home Assistant.

### Passo a Passo para Configurar o Ubuntu e Instalar o Home Assistant

1. **Atualizar os Pacotes do Sistema:**
   - Primeiro, atualize o sistema e os pacotes disponíveis executando os seguintes comandos:
   ```bash
   sudo apt update
   sudo apt upgrade -y
   ```
   - Isso garantirá que todos os pacotes estejam atualizados.

2. **Instalar Dependências Necessárias:**
   - Em seguida, instale o Python 3, o ambiente virtual do Python e o gerenciador de pacotes `pip` com o comando:
   ```bash
   sudo apt install python3 python3-venv python3-pip -y
   ```

3. **Criar um Ambiente Virtual para o Home Assistant:**
   - Crie um diretório para o Home Assistant e navegue até ele:
   ```bash
   mkdir homeassistant
   cd homeassistant
   ```
   - Crie um ambiente virtual Python dentro desse diretório:
   ```bash
   python3 -m venv .
   ```
   - Ative o ambiente virtual:
   ```bash
   source bin/activate
   ```

4. **Instalar o Home Assistant:**
   - Com o ambiente virtual ativado, instale o Home Assistant utilizando `pip`:
   ```bash
   pip install homeassistant
   ```

5. **Iniciar o Home Assistant:**
   - Para iniciar o Home Assistant, execute o seguinte comando:
   ```bash
   hass
   ```
   - O Home Assistant começará a ser iniciado e você verá algumas mensagens no terminal indicando o progresso. O processo de inicialização pode levar alguns minutos na primeira vez.

6. **Acessar a Interface Web do Home Assistant:**
   - Após o Home Assistant estar em execução, abra um navegador de internet no seu computador e digite:
   ```
   http://localhost:8123
   ```
   - Isso abrirá a interface web do Home Assistant, onde você poderá completar a configuração inicial, como criar uma conta de usuário e definir algumas configurações básicas.

### O Que Fazer em Seguida?

- **Configurar Sensores e Integrações:** Siga as instruções na interface do Home Assistant para adicionar sensores, dispositivos e integrações.
- **Configurar MQTT (se necessário):** Se você planeja integrar dispositivos como o ESP32, você pode configurar um servidor MQTT no Home Assistant.

### Resumo

- Atualize o sistema e instale as dependências necessárias.
- Crie e ative um ambiente virtual Python.
- Instale e inicie o Home Assistant.
- Acesse a interface web para continuar a configuração.

Se você encontrar algum problema durante esses passos ou tiver mais perguntas, estou aqui para ajudar!

---

### USUÁRIO

"sudo apt update
sudo apt upgrade -y" concluiu a instalação
sudo apt install python3 python3-venv python3-pip -y concluiu a instalação
mkdir homeassistant
cd homeassistant concluido 
python3 -m venv . concluido
source bin/activate concluido
pip install homeassistant concluido
hass resultou em:
"(homeassistant) root@FelippeBarcelos:~/homeassistant# hass
Unable to find configuration. Creating default one in /root/.homeassistant"
Como prossigo?

---

### USUÁRIO

"sudo apt update
sudo apt upgrade -y" concluiu a instalação
sudo apt install python3 python3-venv python3-pip -y concluiu a instalação
mkdir homeassistant
cd homeassistant concluido 
python3 -m venv . concluido
source bin/activate concluido
pip install homeassistant concluido
hass resultou em:
"(homeassistant) root@FelippeBarcelos:~/homeassistant# hass
Unable to find configuration. Creating default one in /root/.homeassistant
2024-09-03 08:14:24.707 WARNING (MainThread) [homeassistant.bootstrap] Waiting on integrations to complete setup: default_config
2024-09-03 08:14:25.582 WARNING (MainThread) [homeassistant.bootstrap] Support for the running Python version 3.10.12 is deprecated and will be removed in Home Assistant 2023.8; Please upgrade Python to 3.11"
Como prossigo?

---

### ASSISTENTE

A mensagem `Unable to find configuration. Creating default one in /root/.homeassistant` é normal e indica que o Home Assistant não encontrou um arquivo de configuração existente, então ele está criando um arquivo de configuração padrão para você. Isso significa que o Home Assistant está se preparando para ser executado pela primeira vez.

### Próximos Passos

1. **Aguarde a Inicialização Completa:**
   - Continue esperando enquanto o Home Assistant cria o arquivo de configuração e completa a inicialização. Este processo pode levar alguns minutos.
   - Você verá várias mensagens no terminal enquanto o Home Assistant carrega seus componentes e configurações.

2. **Verifique se o Home Assistant Está em Execução:**
   - Quando o processo de inicialização estiver concluído, o terminal deverá mostrar uma mensagem indicando que o servidor do Home Assistant está em execução e ouvindo na porta `8123`.

3. **Acesse a Interface Web do Home Assistant:**
   - Abra um navegador no seu computador e digite:
   ```
   http://localhost:8123
   ```
   - Isso deve abrir a interface do Home Assistant.
   - Se você estiver usando o WSL 2 e o endereço `http://localhost:8123` não funcionar, você pode tentar encontrar o endereço IP da sua máquina Ubuntu usando o comando `ip addr` no terminal e substituí-lo no navegador.

### Alternativa: Executar o Home Assistant em Segundo Plano

Se você deseja executar o Home Assistant em segundo plano para poder usar o terminal para outras tarefas, você pode usar o comando `nohup` (no hang up) ou `&` para isso:

1. **Executar o Home Assistant em Segundo Plano:**
   - Pare a execução atual do Home Assistant (pressione `Ctrl + C`).
   - Execute o Home Assistant em segundo plano com o comando:
   ```bash
   nohup hass &
   ```
   - Isso executará o Home Assistant em segundo plano e permitirá que você continue usando o terminal.

2. **Verificar o Status do Home Assistant:**
   - Para verificar se o Home Assistant ainda está em execução, você pode usar o comando:
   ```bash
   ps aux | grep hass
   ```

3. **Acessar o Home Assistant:**
   - Acesse a interface web do Home Assistant novamente em `http://localhost:8123`.

### Conclusão

O Home Assistant deve agora estar em execução e acessível via navegador. Se houver qualquer problema ou se precisar de mais ajuda para configurar sensores e integrações, me avise!

---

### ASSISTENTE

Parece que o Home Assistant foi instalado com sucesso, mas há dois avisos importantes:

1. **Aviso sobre a configuração padrão:** O Home Assistant não encontrou uma configuração existente e criou uma configuração padrão em `/root/.homeassistant`. Isso é normal para uma primeira execução e não requer ação adicional.

2. **Aviso sobre a versão do Python:** O Home Assistant está informando que a versão do Python instalada (3.10.12) será deprecada em breve e recomenda a atualização para o Python 3.11.

### Passo a Passo para Resolver o Aviso de Versão do Python

Para garantir que você tenha uma versão do Python compatível no futuro, é uma boa ideia atualizar para o Python 3.11. Aqui estão os passos para instalar a versão mais recente do Python no Ubuntu:

#### Passo 1: Instalar o Python 3.11

1. **Adicionar o repositório do Python 3.11:**
   ```bash
   sudo apt update
   sudo apt install software-properties-common -y
   sudo add-apt-repository ppa:deadsnakes/ppa
   ```

2. **Instalar o Python 3.11:**
   ```bash
   sudo apt update
   sudo apt install python3.11 python3.11-venv python3.11-dev -y
   ```

#### Passo 2: Criar um Novo Ambiente Virtual com Python 3.11

Agora que o Python 3.11 está instalado, você precisará criar um novo ambiente virtual usando essa versão.

1. **Desativar o Ambiente Virtual Atual:**
   - No terminal, digite:
   ```bash
   deactivate
   ```

2. **Criar um Novo Ambiente Virtual com Python 3.11:**
   - No diretório `homeassistant` que você já criou, execute:
   ```bash
   python3.11 -m venv .
   ```
   - Ative o novo ambiente virtual:
   ```bash
   source bin/activate
   ```

3. **Reinstalar o Home Assistant no Novo Ambiente Virtual:**
   - Com o novo ambiente virtual ativado, instale o Home Assistant novamente:
   ```bash
   pip install homeassistant
   ```

#### Passo 3: Iniciar o Home Assistant com o Python Atualizado

1. **Iniciar o Home Assistant:**
   - Execute o comando novamente:
   ```bash
   hass
   ```

2. **Aguardar a Inicialização:**
   - O Home Assistant deve iniciar normalmente sem o aviso sobre a versão do Python.

### Próximos Passos

- **Acessar a Interface Web:** Abra o navegador e vá para `http://localhost:8123` para completar a configuração inicial.
- **Configurar Integrações e Sensores:** Siga as instruções da interface web para adicionar dispositivos e sensores ao Home Assistant.

Se você seguir esses passos, o Home Assistant deve funcionar corretamente com o Python 3.11, garantindo compatibilidade com as futuras atualizações. Se houver mais dúvidas ou algum outro problema, estou aqui para ajudar!

---

### USUÁRIO

nao esta acontecendo nada quando envio os comandos:
 Running setup.py install for python-slugify ... done
Successfully installed Jinja2-3.1.2 MarkupSafe-2.1.5 PyJWT-2.7.0 PyYAML-6.0.1 aiohttp-3.8.5 aiosignal-1.3.1 anyio-4.4.0 astral-2.2 async-timeout-4.0.2 atomicwrites-homeassistant-1.4.1 attrs-22.2.0 awesomeversion-22.9.0 bcrypt-4.0.1 certifi-2024.8.30 cffi-1.17.0 charset-normalizer-3.3.2 ciso8601-2.3.0 cryptography-41.0.1 exceptiongroup-1.2.2 frozenlist-1.4.1 h11-0.14.0 home-assistant-bluetooth-1.10.0 homeassistant-2023.7.3 httpcore-0.17.3 httpx-0.24.1 idna-3.8 ifaddr-0.2.0 lru-dict-1.2.0 multidict-6.0.5 orjson-3.9.1 pyOpenSSL-23.2.0 pycparser-2.22 python-slugify-4.0.1 pytz-2024.1 requests-2.31.0 sniffio-1.3.1 text-unidecode-1.3 typing-extensions-4.12.2 ulid-transform-0.7.2 urllib3-2.2.2 voluptuous-0.13.1 voluptuous-serialize-2.6.0 yarl-1.9.2
(homeassistant) root@FelippeBarcelos:~/homeassistant# hass
Unable to find configuration. Creating default one in /root/.homeassistant
2024-09-03 08:14:24.707 WARNING (MainThread) [homeassistant.bootstrap] Waiting on integrations to complete setup: default_config
2024-09-03 08:14:25.582 WARNING (MainThread) [homeassistant.bootstrap] Support for the running Python version 3.10.12 is deprecated and will be removed in Home Assistant 2023.8; Please upgrade Python to 3.11
sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa

sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.11 python3.11-venv python3.11-dev -y


---

### ASSISTENTE

Parece que você tentou repetir os comandos várias vezes, mas ainda não viu nenhum efeito. Vamos verificar passo a passo para garantir que você consiga instalar e usar o Python 3.11 corretamente.

### Passo a Passo para Instalar o Python 3.11 e Reconfigurar o Ambiente Virtual

#### Passo 1: Verificar se o Repositório do Python 3.11 Está Adicionado

Vamos garantir que o repositório foi adicionado corretamente e que o Python 3.11 está disponível para instalação.

1. **Adicionar o Repositório e Atualizar os Pacotes:**

   Execute os comandos abaixo um de cada vez para adicionar o repositório do Python e atualizar os pacotes:

   ```bash
   sudo apt update
   sudo apt install software-properties-common -y
   sudo add-apt-repository ppa:deadsnakes/ppa -y
   sudo apt update
   ```

   Se o repositório já estiver adicionado, você verá uma mensagem informando isso.

#### Passo 2: Instalar o Python 3.11

2. **Instalar o Python 3.11:**

   Execute o comando para instalar o Python 3.11 e as bibliotecas necessárias:

   ```bash
   sudo apt install python3.11 python3.11-venv python3.11-dev -y
   ```

   Verifique se o Python 3.11 foi instalado com sucesso usando:

   ```bash
   python3.11 --version
   ```

   Isso deve exibir a versão do Python 3.11 instalada.

#### Passo 3: Criar um Novo Ambiente Virtual Usando o Python 3.11

3. **Criar um Novo Ambiente Virtual com Python 3.11:**

   No diretório `homeassistant` onde você criou o ambiente virtual anterior, execute:

   - Desative o ambiente virtual atual:
     ```bash
     deactivate
     ```

   - Crie um novo ambiente virtual usando o Python 3.11:
     ```bash
     python3.11 -m venv .
     ```

   - Ative o novo ambiente virtual:
     ```bash
     source bin/activate
     ```

4. **Reinstalar o Home Assistant:**

   - Com o novo ambiente virtual ativado, instale o Home Assistant novamente:

   ```bash
   pip install homeassistant
   ```

#### Passo 4: Iniciar o Home Assistant com o Python Atualizado

5. **Iniciar o Home Assistant:**

   - Execute o comando novamente:

   ```bash
   hass
   ```

### Verifique se o Home Assistant Inicia Corretamente

Após seguir esses passos, o Home Assistant deve iniciar corretamente e o aviso sobre a versão do Python não deve mais aparecer.

Se ainda houver problemas ou mensagens de erro, me avise e vamos solucionar juntos!

---

### USUÁRIO

root@FelippeBarcelos:~# sudo apt update
Hit:1 http://security.ubuntu.com/ubuntu jammy-security InRelease
Hit:2 http://archive.ubuntu.com/ubuntu jammy InRelease
Hit:3 http://archive.ubuntu.com/ubuntu jammy-updates InRelease
Hit:4 http://archive.ubuntu.com/ubuntu jammy-backports InRelease
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
2 packages can be upgraded. Run 'apt list --upgradable' to see them.
root@FelippeBarcelos:~# sudo apt install software-properties-common -y
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
software-properties-common is already the newest version (0.99.22.9).
software-properties-common set to manually installed.
0 upgraded, 0 newly installed, 0 to remove and 2 not upgraded.
root@FelippeBarcelos:~#

---

### ASSISTENTE

Parece que o pacote `software-properties-common` já está instalado e atualizado. Vamos prosseguir adicionando o repositório do Python 3.11 e instalando a nova versão do Python.

### Passo a Passo para Instalar o Python 3.11

#### Passo 1: Adicionar o Repositório para o Python 3.11

Execute o comando para adicionar o repositório do Python 3.11:

```bash
sudo add-apt-repository ppa:deadsnakes/ppa -y
```

Após adicionar o repositório, atualize a lista de pacotes:

```bash
sudo apt update
```

#### Passo 2: Instalar o Python 3.11

Agora, instale o Python 3.11 e as bibliotecas necessárias:

```bash
sudo apt install python3.11 python3.11-venv python3.11-dev -y
```

#### Passo 3: Verificar a Instalação do Python 3.11

Verifique se o Python 3.11 foi instalado com sucesso:

```bash
python3.11 --version
```

#### Passo 4: Criar e Configurar um Novo Ambiente Virtual com Python 3.11

1. **Desativar o Ambiente Virtual Atual:**

   ```bash
   deactivate
   ```

2. **Criar um Novo Ambiente Virtual Usando o Python 3.11:**

   No diretório `homeassistant` que você já criou:

   ```bash
   python3.11 -m venv .
   ```

3. **Ativar o Novo Ambiente Virtual:**

   ```bash
   source bin/activate
   ```

4. **Reinstalar o Home Assistant:**

   ```bash
   pip install homeassistant
   ```

#### Passo 5: Iniciar o Home Assistant

Inicie o Home Assistant novamente:

```bash
hass
```

### Verifique o Funcionamento

Após esses passos, o Home Assistant deve iniciar sem problemas. Caso ainda tenha algum problema, me avise e continuaremos a solucionar juntos!

---

### USUÁRIO

For nightly builds, see ppa:deadsnakes/nightly https://launchpad.net/~deadsnakes/+archive/ubuntu/nightly
More info: https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa
Adding repository.
Adding deb entry to /etc/apt/sources.list.d/deadsnakes-ubuntu-ppa-jammy.list
Adding disabled deb-src entry to /etc/apt/sources.list.d/deadsnakes-ubuntu-ppa-jammy.list
Adding key to /etc/apt/trusted.gpg.d/deadsnakes-ubuntu-ppa.gpg with fingerprint F23C5A6CF475977595C89F51BA6932366A755776
Hit:1 http://security.ubuntu.com/ubuntu jammy-security InRelease
Hit:2 http://archive.ubuntu.com/ubuntu jammy InRelease
Hit:3 http://archive.ubuntu.com/ubuntu jammy-updates InRelease
Hit:4 http://archive.ubuntu.com/ubuntu jammy-backports InRelease
Get:5 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy InRelease [18.1 kB]
Get:6 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 Packages [23.6 kB]
Get:7 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main Translation-en [4800 B]
Fetched 46.4 kB in 2s (25.0 kB/s)
Reading package lists... Done
root@FelippeBarcelos:~#

---

### ASSISTENTE

Ótimo! O repositório do Python 3.11 foi adicionado com sucesso. Agora, vamos continuar com a instalação do Python 3.11.

### Passo 1: Instalar o Python 3.11

Execute o seguinte comando para instalar o Python 3.11 e as bibliotecas necessárias:

```bash
sudo apt install python3.11 python3.11-venv python3.11-dev -y
```

### Passo 2: Verificar a Instalação do Python 3.11

Após a instalação, verifique se o Python 3.11 foi instalado corretamente:

```bash
python3.11 --version
```

Isso deve mostrar a versão do Python 3.11 instalada no seu sistema.

### Passo 3: Criar e Configurar um Novo Ambiente Virtual com Python 3.11

1. **Desativar o Ambiente Virtual Atual:**

   No terminal, execute:

   ```bash
   deactivate
   ```

2. **Criar um Novo Ambiente Virtual com Python 3.11:**

   No diretório `homeassistant` que você criou anteriormente, execute:

   ```bash
   python3.11 -m venv .
   ```

3. **Ativar o Novo Ambiente Virtual:**

   Ative o novo ambiente virtual:

   ```bash
   source bin/activate
   ```

4. **Reinstalar o Home Assistant:**

   Com o novo ambiente virtual ativado, instale novamente o Home Assistant:

   ```bash
   pip install homeassistant
   ```

### Passo 4: Iniciar o Home Assistant

Inicie o Home Assistant novamente:

```bash
hass
```

### Próximos Passos

Depois de seguir todos esses passos, o Home Assistant deve funcionar corretamente usando o Python 3.11. Se houver mais dúvidas ou problemas, sinta-se à vontade para me informar!

---

### USUÁRIO

Estou no ubuntu:
Python modules in the official Ubuntu repositories are packaged to work with the Python interpreters from the official repositories. Accordingly, they generally won't work with the Python interpreters from this PPA. As an exception, pure-Python modules for Python 3 will work, but any compiled extension modules won't.

To install 3rd-party Python modules, you should use the common Python packaging tools.  For an introduction into the Python packaging ecosystem and its tools, refer to the Python Packaging User Guide:
https://packaging.python.org/installing/

Sources
=======
The package sources are available at:
https://github.com/deadsnakes/

Nightly Builds
==============

For nightly builds, see ppa:deadsnakes/nightly https://launchpad.net/~deadsnakes/+archive/ubuntu/nightly
More info: https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa
Adding repository.
Adding deb entry to /etc/apt/sources.list.d/deadsnakes-ubuntu-ppa-jammy.list
Adding disabled deb-src entry to /etc/apt/sources.list.d/deadsnakes-ubuntu-ppa-jammy.list
Adding key to /etc/apt/trusted.gpg.d/deadsnakes-ubuntu-ppa.gpg with fingerprint F23C5A6CF475977595C89F51BA6932366A755776
Hit:1 http://security.ubuntu.com/ubuntu jammy-security InRelease
Hit:2 http://archive.ubuntu.com/ubuntu jammy InRelease
Hit:3 http://archive.ubuntu.com/ubuntu jammy-updates InRelease
Hit:4 http://archive.ubuntu.com/ubuntu jammy-backports InRelease
Get:5 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy InRelease [18.1 kB]
Get:6 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 Packages [23.6 kB]
Get:7 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main Translation-en [4800 B]
Fetched 46.4 kB in 2s (25.0 kB/s)
Reading package lists... Done
root@FelippeBarcelos:~# sudo apt install python3.11 python3.11-venv python3.11-dev -y
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  libpython3.11 libpython3.11-dev libpython3.11-minimal libpython3.11-stdlib mailcap mime-support
  python3.11-minimal
Suggested packages:
  binfmt-support
The following NEW packages will be installed:
  libpython3.11 libpython3.11-dev libpython3.11-minimal libpython3.11-stdlib mailcap mime-support
  python3.11 python3.11-dev python3.11-minimal python3.11-venv
0 upgraded, 10 newly installed, 0 to remove and 2 not upgraded.
Need to get 16.9 MB of archives.
After this operation, 58.9 MB of additional disk space will be used.
Get:1 http://archive.ubuntu.com/ubuntu jammy/main amd64 mailcap all 3.70+nmu1ubuntu1 [23.8 kB]
Get:2 http://archive.ubuntu.com/ubuntu jammy/main amd64 mime-support all 3.66 [3696 B]
Get:3 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 libpython3.11-minimal amd64 3.11.9-1+jammy1 [884 kB]
Get:4 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 python3.11-minimal amd64 3.11.9-1+jammy1 [2355 kB]
Get:5 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 libpython3.11-stdlib amd64 3.11.9-1+jammy1 [1925 kB]
Get:6 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 libpython3.11 amd64 3.11.9-1+jammy1 [2217 kB]
Get:7 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 libpython3.11-dev amd64 3.11.9-1+jammy1 [5313 kB]
Get:8 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 python3.11 amd64 3.11.9-1+jammy1 [640 kB]
Get:9 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 python3.11-dev amd64 3.11.9-1+jammy1 [500 kB]
Get:10 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 python3.11-venv amd64 3.11.9-1+jammy1 [3017 kB]
Fetched 16.9 MB in 55s (308 kB/s)
Selecting previously unselected package libpython3.11-minimal:amd64.
(Reading database ... 31464 files and directories currently installed.)
Preparing to unpack .../0-libpython3.11-minimal_3.11.9-1+jammy1_amd64.deb ...
Unpacking libpython3.11-minimal:amd64 (3.11.9-1+jammy1) ...
Selecting previously unselected package python3.11-minimal.
Preparing to unpack .../1-python3.11-minimal_3.11.9-1+jammy1_amd64.deb ...
Unpacking python3.11-minimal (3.11.9-1+jammy1) ...
Selecting previously unselected package mailcap.
Preparing to unpack .../2-mailcap_3.70+nmu1ubuntu1_all.deb ...
Unpacking mailcap (3.70+nmu1ubuntu1) ...
Selecting previously unselected package mime-support.
Preparing to unpack .../3-mime-support_3.66_all.deb ...
Unpacking mime-support (3.66) ...
Selecting previously unselected package libpython3.11-stdlib:amd64.
Preparing to unpack .../4-libpython3.11-stdlib_3.11.9-1+jammy1_amd64.deb ...
Unpacking libpython3.11-stdlib:amd64 (3.11.9-1+jammy1) ...
Selecting previously unselected package libpython3.11:amd64.
Preparing to unpack .../5-libpython3.11_3.11.9-1+jammy1_amd64.deb ...
Unpacking libpython3.11:amd64 (3.11.9-1+jammy1) ...
Selecting previously unselected package libpython3.11-dev:amd64.
Preparing to unpack .../6-libpython3.11-dev_3.11.9-1+jammy1_amd64.deb ...
Unpacking libpython3.11-dev:amd64 (3.11.9-1+jammy1) ...
Selecting previously unselected package python3.11.
Preparing to unpack .../7-python3.11_3.11.9-1+jammy1_amd64.deb ...
Unpacking python3.11 (3.11.9-1+jammy1) ...
Selecting previously unselected package python3.11-dev.
Preparing to unpack .../8-python3.11-dev_3.11.9-1+jammy1_amd64.deb ...
Unpacking python3.11-dev (3.11.9-1+jammy1) ...
Selecting previously unselected package python3.11-venv.
Preparing to unpack .../9-python3.11-venv_3.11.9-1+jammy1_amd64.deb ...
Unpacking python3.11-venv (3.11.9-1+jammy1) ...
Setting up libpython3.11-minimal:amd64 (3.11.9-1+jammy1) ...
Setting up mailcap (3.70+nmu1ubuntu1) ...
Setting up python3.11-minimal (3.11.9-1+jammy1) ...
Setting up mime-support (3.66) ...
Setting up libpython3.11-stdlib:amd64 (3.11.9-1+jammy1) ...
Setting up python3.11 (3.11.9-1+jammy1) ...
Setting up libpython3.11:amd64 (3.11.9-1+jammy1) ...
Setting up python3.11-venv (3.11.9-1+jammy1) ...
Setting up libpython3.11-dev:amd64 (3.11.9-1+jammy1) ...
Setting up python3.11-dev (3.11.9-1+jammy1) ...
Processing triggers for man-db (2.10.2-1) ...
root@FelippeBarcelos:~# python3.11 --version
Python 3.11.9
root@FelippeBarcelos:~#
Como prossigo?

---

### ASSISTENTE

Ótimo! O Python 3.11 foi instalado com sucesso. Agora, vamos criar um novo ambiente virtual usando o Python 3.11, configurar o Home Assistant e garantir que ele funcione corretamente.

### Passo a Passo para Criar e Configurar o Ambiente Virtual com Python 3.11

#### Passo 1: Desativar o Ambiente Virtual Atual (se estiver ativado)

Se você ainda estiver em um ambiente virtual anterior, desative-o executando:

```bash
deactivate
```

#### Passo 2: Criar um Novo Ambiente Virtual Usando o Python 3.11

1. **Navegar para o Diretório do Home Assistant:**

   Certifique-se de que você está no diretório `homeassistant` que você criou anteriormente:

   ```bash
   cd ~/homeassistant
   ```

2. **Criar o Novo Ambiente Virtual:**

   Use o Python 3.11 para criar um novo ambiente virtual:

   ```bash
   python3.11 -m venv .
   ```

3. **Ativar o Novo Ambiente Virtual:**

   Ative o novo ambiente virtual:

   ```bash
   source bin/activate
   ```

#### Passo 3: Reinstalar o Home Assistant

1. **Instalar o Home Assistant no Novo Ambiente Virtual:**

   Com o ambiente virtual ativado, instale o Home Assistant novamente:

   ```bash
   pip install homeassistant
   ```

#### Passo 4: Iniciar o Home Assistant

1. **Iniciar o Home Assistant:**

   Após a instalação, inicie o Home Assistant executando:

   ```bash
   hass
   ```

### O Que Esperar?

- O Home Assistant deve iniciar sem os avisos de versão do Python, pois agora está rodando com o Python 3.11.
- Você verá mensagens de log no terminal indicando que o Home Assistant está inicializando. Pode levar alguns minutos na primeira vez.
- Quando estiver pronto, você poderá acessar a interface web do Home Assistant através de `http://localhost:8123` em seu navegador.

### Próximos Passos

1. **Configuração Inicial do Home Assistant:**
   - Siga as instruções na interface web para configurar a sua conta e as preferências iniciais.

2. **Adicionar Dispositivos e Integrações:**
   - Explore as opções do Home Assistant para adicionar dispositivos, sensores, automações e integrações.

Se você tiver alguma dúvida ou precisar de mais ajuda, é só me avisar!

---

### USUÁRIO

Python modules in the official Ubuntu repositories are packaged to work with the Python interpreters from the official repositories. Accordingly, they generally won't work with the Python interpreters from this PPA. As an exception, pure-Python modules for Python 3 will work, but any compiled extension modules won't.

To install 3rd-party Python modules, you should use the common Python packaging tools.  For an introduction into the Python packaging ecosystem and its tools, refer to the Python Packaging User Guide:
https://packaging.python.org/installing/

Sources
=======
The package sources are available at:
https://github.com/deadsnakes/

Nightly Builds
==============

For nightly builds, see ppa:deadsnakes/nightly https://launchpad.net/~deadsnakes/+archive/ubuntu/nightly
More info: https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa
Adding repository.
Adding deb entry to /etc/apt/sources.list.d/deadsnakes-ubuntu-ppa-jammy.list
Adding disabled deb-src entry to /etc/apt/sources.list.d/deadsnakes-ubuntu-ppa-jammy.list
Adding key to /etc/apt/trusted.gpg.d/deadsnakes-ubuntu-ppa.gpg with fingerprint F23C5A6CF475977595C89F51BA6932366A755776
Hit:1 http://security.ubuntu.com/ubuntu jammy-security InRelease
Hit:2 http://archive.ubuntu.com/ubuntu jammy InRelease
Hit:3 http://archive.ubuntu.com/ubuntu jammy-updates InRelease
Hit:4 http://archive.ubuntu.com/ubuntu jammy-backports InRelease
Get:5 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy InRelease [18.1 kB]
Get:6 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 Packages [23.6 kB]
Get:7 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main Translation-en [4800 B]
Fetched 46.4 kB in 2s (25.0 kB/s)
Reading package lists... Done
root@FelippeBarcelos:~# sudo apt install python3.11 python3.11-venv python3.11-dev -y
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  libpython3.11 libpython3.11-dev libpython3.11-minimal libpython3.11-stdlib mailcap mime-support
  python3.11-minimal
Suggested packages:
  binfmt-support
The following NEW packages will be installed:
  libpython3.11 libpython3.11-dev libpython3.11-minimal libpython3.11-stdlib mailcap mime-support
  python3.11 python3.11-dev python3.11-minimal python3.11-venv
0 upgraded, 10 newly installed, 0 to remove and 2 not upgraded.
Need to get 16.9 MB of archives.
After this operation, 58.9 MB of additional disk space will be used.
Get:1 http://archive.ubuntu.com/ubuntu jammy/main amd64 mailcap all 3.70+nmu1ubuntu1 [23.8 kB]
Get:2 http://archive.ubuntu.com/ubuntu jammy/main amd64 mime-support all 3.66 [3696 B]
Get:3 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 libpython3.11-minimal amd64 3.11.9-1+jammy1 [884 kB]
Get:4 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 python3.11-minimal amd64 3.11.9-1+jammy1 [2355 kB]
Get:5 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 libpython3.11-stdlib amd64 3.11.9-1+jammy1 [1925 kB]
Get:6 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 libpython3.11 amd64 3.11.9-1+jammy1 [2217 kB]
Get:7 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 libpython3.11-dev amd64 3.11.9-1+jammy1 [5313 kB]
Get:8 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 python3.11 amd64 3.11.9-1+jammy1 [640 kB]
Get:9 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 python3.11-dev amd64 3.11.9-1+jammy1 [500 kB]
Get:10 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 python3.11-venv amd64 3.11.9-1+jammy1 [3017 kB]
Fetched 16.9 MB in 55s (308 kB/s)
Selecting previously unselected package libpython3.11-minimal:amd64.
(Reading database ... 31464 files and directories currently installed.)
Preparing to unpack .../0-libpython3.11-minimal_3.11.9-1+jammy1_amd64.deb ...
Unpacking libpython3.11-minimal:amd64 (3.11.9-1+jammy1) ...
Selecting previously unselected package python3.11-minimal.
Preparing to unpack .../1-python3.11-minimal_3.11.9-1+jammy1_amd64.deb ...
Unpacking python3.11-minimal (3.11.9-1+jammy1) ...
Selecting previously unselected package mailcap.
Preparing to unpack .../2-mailcap_3.70+nmu1ubuntu1_all.deb ...
Unpacking mailcap (3.70+nmu1ubuntu1) ...
Selecting previously unselected package mime-support.
Preparing to unpack .../3-mime-support_3.66_all.deb ...
Unpacking mime-support (3.66) ...
Selecting previously unselected package libpython3.11-stdlib:amd64.
Preparing to unpack .../4-libpython3.11-stdlib_3.11.9-1+jammy1_amd64.deb ...
Unpacking libpython3.11-stdlib:amd64 (3.11.9-1+jammy1) ...
Selecting previously unselected package libpython3.11:amd64.
Preparing to unpack .../5-libpython3.11_3.11.9-1+jammy1_amd64.deb ...
Unpacking libpython3.11:amd64 (3.11.9-1+jammy1) ...
Selecting previously unselected package libpython3.11-dev:amd64.
Preparing to unpack .../6-libpython3.11-dev_3.11.9-1+jammy1_amd64.deb ...
Unpacking libpython3.11-dev:amd64 (3.11.9-1+jammy1) ...
Selecting previously unselected package python3.11.
Preparing to unpack .../7-python3.11_3.11.9-1+jammy1_amd64.deb ...
Unpacking python3.11 (3.11.9-1+jammy1) ...
Selecting previously unselected package python3.11-dev.
Preparing to unpack .../8-python3.11-dev_3.11.9-1+jammy1_amd64.deb ...
Unpacking python3.11-dev (3.11.9-1+jammy1) ...
Selecting previously unselected package python3.11-venv.
Preparing to unpack .../9-python3.11-venv_3.11.9-1+jammy1_amd64.deb ...
Unpacking python3.11-venv (3.11.9-1+jammy1) ...
Setting up libpython3.11-minimal:amd64 (3.11.9-1+jammy1) ...
Setting up mailcap (3.70+nmu1ubuntu1) ...
Setting up python3.11-minimal (3.11.9-1+jammy1) ...
Setting up mime-support (3.66) ...
Setting up libpython3.11-stdlib:amd64 (3.11.9-1+jammy1) ...
Setting up python3.11 (3.11.9-1+jammy1) ...
Setting up libpython3.11:amd64 (3.11.9-1+jammy1) ...
Setting up python3.11-venv (3.11.9-1+jammy1) ...
Setting up libpython3.11-dev:amd64 (3.11.9-1+jammy1) ...
Setting up python3.11-dev (3.11.9-1+jammy1) ...
Processing triggers for man-db (2.10.2-1) ...
root@FelippeBarcelos:~# python3.11 --version
Python 3.11.9
root@FelippeBarcelos:~# deactivate
deactivate: command not found
root@FelippeBarcelos:~#

---

### ASSISTENTE

Parece que você não está mais em um ambiente virtual ativo, por isso o comando `deactivate` não foi reconhecido. Agora que o Python 3.11 está instalado, podemos continuar criando um novo ambiente virtual e reinstalando o Home Assistant.

### Passo a Passo para Criar e Configurar o Ambiente Virtual com Python 3.11

#### Passo 1: Navegar para o Diretório do Home Assistant

Certifique-se de que você está no diretório `homeassistant` que você criou anteriormente:

```bash
cd ~/homeassistant
```

Se você não criou esse diretório, pode criá-lo novamente:

```bash
mkdir homeassistant
cd homeassistant
```

#### Passo 2: Criar um Novo Ambiente Virtual Usando o Python 3.11

Agora, crie o ambiente virtual usando o Python 3.11:

```bash
python3.11 -m venv .
```

#### Passo 3: Ativar o Novo Ambiente Virtual

Ative o novo ambiente virtual:

```bash
source bin/activate
```

Após ativar o ambiente virtual, você deve ver o nome do ambiente (`(homeassistant)`) no início do prompt do terminal.

#### Passo 4: Reinstalar o Home Assistant

Com o novo ambiente virtual ativado, instale o Home Assistant novamente:

```bash
pip install homeassistant
```

#### Passo 5: Iniciar o Home Assistant

Inicie o Home Assistant:

```bash
hass
```

### Próximos Passos

Após esses passos, o Home Assistant deve funcionar corretamente usando o Python 3.11. Se você encontrar algum problema ou precisar de mais assistência, por favor, me avise!

---

### USUÁRIO

Python modules in the official Ubuntu repositories are packaged to work with the Python interpreters from the official repositories. Accordingly, they generally won't work with the Python interpreters from this PPA. As an exception, pure-Python modules for Python 3 will work, but any compiled extension modules won't.

To install 3rd-party Python modules, you should use the common Python packaging tools.  For an introduction into the Python packaging ecosystem and its tools, refer to the Python Packaging User Guide:
https://packaging.python.org/installing/

Sources
=======
The package sources are available at:
https://github.com/deadsnakes/

Nightly Builds
==============

For nightly builds, see ppa:deadsnakes/nightly https://launchpad.net/~deadsnakes/+archive/ubuntu/nightly
More info: https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa
Adding repository.
Adding deb entry to /etc/apt/sources.list.d/deadsnakes-ubuntu-ppa-jammy.list
Adding disabled deb-src entry to /etc/apt/sources.list.d/deadsnakes-ubuntu-ppa-jammy.list
Adding key to /etc/apt/trusted.gpg.d/deadsnakes-ubuntu-ppa.gpg with fingerprint F23C5A6CF475977595C89F51BA6932366A755776
Hit:1 http://security.ubuntu.com/ubuntu jammy-security InRelease
Hit:2 http://archive.ubuntu.com/ubuntu jammy InRelease
Hit:3 http://archive.ubuntu.com/ubuntu jammy-updates InRelease
Hit:4 http://archive.ubuntu.com/ubuntu jammy-backports InRelease
Get:5 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy InRelease [18.1 kB]
Get:6 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 Packages [23.6 kB]
Get:7 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main Translation-en [4800 B]
Fetched 46.4 kB in 2s (25.0 kB/s)
Reading package lists... Done
root@FelippeBarcelos:~# sudo apt install python3.11 python3.11-venv python3.11-dev -y
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  libpython3.11 libpython3.11-dev libpython3.11-minimal libpython3.11-stdlib mailcap mime-support
  python3.11-minimal
Suggested packages:
  binfmt-support
The following NEW packages will be installed:
  libpython3.11 libpython3.11-dev libpython3.11-minimal libpython3.11-stdlib mailcap mime-support
  python3.11 python3.11-dev python3.11-minimal python3.11-venv
0 upgraded, 10 newly installed, 0 to remove and 2 not upgraded.
Need to get 16.9 MB of archives.
After this operation, 58.9 MB of additional disk space will be used.
Get:1 http://archive.ubuntu.com/ubuntu jammy/main amd64 mailcap all 3.70+nmu1ubuntu1 [23.8 kB]
Get:2 http://archive.ubuntu.com/ubuntu jammy/main amd64 mime-support all 3.66 [3696 B]
Get:3 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 libpython3.11-minimal amd64 3.11.9-1+jammy1 [884 kB]
Get:4 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 python3.11-minimal amd64 3.11.9-1+jammy1 [2355 kB]
Get:5 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 libpython3.11-stdlib amd64 3.11.9-1+jammy1 [1925 kB]
Get:6 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 libpython3.11 amd64 3.11.9-1+jammy1 [2217 kB]
Get:7 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 libpython3.11-dev amd64 3.11.9-1+jammy1 [5313 kB]
Get:8 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 python3.11 amd64 3.11.9-1+jammy1 [640 kB]
Get:9 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 python3.11-dev amd64 3.11.9-1+jammy1 [500 kB]
Get:10 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy/main amd64 python3.11-venv amd64 3.11.9-1+jammy1 [3017 kB]
Fetched 16.9 MB in 55s (308 kB/s)
Selecting previously unselected package libpython3.11-minimal:amd64.
(Reading database ... 31464 files and directories currently installed.)
Preparing to unpack .../0-libpython3.11-minimal_3.11.9-1+jammy1_amd64.deb ...
Unpacking libpython3.11-minimal:amd64 (3.11.9-1+jammy1) ...
Selecting previously unselected package python3.11-minimal.
Preparing to unpack .../1-python3.11-minimal_3.11.9-1+jammy1_amd64.deb ...
Unpacking python3.11-minimal (3.11.9-1+jammy1) ...
Selecting previously unselected package mailcap.
Preparing to unpack .../2-mailcap_3.70+nmu1ubuntu1_all.deb ...
Unpacking mailcap (3.70+nmu1ubuntu1) ...
Selecting previously unselected package mime-support.
Preparing to unpack .../3-mime-support_3.66_all.deb ...
Unpacking mime-support (3.66) ...
Selecting previously unselected package libpython3.11-stdlib:amd64.
Preparing to unpack .../4-libpython3.11-stdlib_3.11.9-1+jammy1_amd64.deb ...
Unpacking libpython3.11-stdlib:amd64 (3.11.9-1+jammy1) ...
Selecting previously unselected package libpython3.11:amd64.
Preparing to unpack .../5-libpython3.11_3.11.9-1+jammy1_amd64.deb ...
Unpacking libpython3.11:amd64 (3.11.9-1+jammy1) ...
Selecting previously unselected package libpython3.11-dev:amd64.
Preparing to unpack .../6-libpython3.11-dev_3.11.9-1+jammy1_amd64.deb ...
Unpacking libpython3.11-dev:amd64 (3.11.9-1+jammy1) ...
Selecting previously unselected package python3.11.
Preparing to unpack .../7-python3.11_3.11.9-1+jammy1_amd64.deb ...
Unpacking python3.11 (3.11.9-1+jammy1) ...
Selecting previously unselected package python3.11-dev.
Preparing to unpack .../8-python3.11-dev_3.11.9-1+jammy1_amd64.deb ...
Unpacking python3.11-dev (3.11.9-1+jammy1) ...
Selecting previously unselected package python3.11-venv.
Preparing to unpack .../9-python3.11-venv_3.11.9-1+jammy1_amd64.deb ...
Unpacking python3.11-venv (3.11.9-1+jammy1) ...
Setting up libpython3.11-minimal:amd64 (3.11.9-1+jammy1) ...
Setting up mailcap (3.70+nmu1ubuntu1) ...
Setting up python3.11-minimal (3.11.9-1+jammy1) ...
Setting up mime-support (3.66) ...
Setting up libpython3.11-stdlib:amd64 (3.11.9-1+jammy1) ...
Setting up python3.11 (3.11.9-1+jammy1) ...
Setting up libpython3.11:amd64 (3.11.9-1+jammy1) ...
Setting up python3.11-venv (3.11.9-1+jammy1) ...
Setting up libpython3.11-dev:amd64 (3.11.9-1+jammy1) ...
Setting up python3.11-dev (3.11.9-1+jammy1) ...
Processing triggers for man-db (2.10.2-1) ...
root@FelippeBarcelos:~# python3.11 --version
Python 3.11.9
root@FelippeBarcelos:~# deactivate
deactivate: command not found
root@FelippeBarcelos:~# cd ~/homeassistant
root@FelippeBarcelos:~/homeassistant# mkdir homeassistant
cd homeassistant
root@FelippeBarcelos:~/homeassistant/homeassistant# python3.11 -m venv .
root@FelippeBarcelos:~/homeassistant/homeassistant# source bin/activate
(homeassistant) root@FelippeBarcelos:~/homeassistant/homeassistant# pip install homeassistant
Collecting homeassistant
  Downloading homeassistant-2024.3.3-py3-none-any.whl.metadata (4.1 kB)
Collecting aiohttp==3.9.3 (from homeassistant)
  Downloading aiohttp-3.9.3-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (7.4 kB)
Collecting aiohttp-cors==0.7.0 (from homeassistant)
  Downloading aiohttp_cors-0.7.0-py3-none-any.whl.metadata (20 kB)
Collecting aiohttp-fast-url-dispatcher==0.3.0 (from homeassistant)
  Downloading aiohttp_fast_url_dispatcher-0.3.0-py3-none-any.whl.metadata (6.4 kB)
Collecting aiohttp-zlib-ng==0.3.1 (from homeassistant)
  Downloading aiohttp_zlib_ng-0.3.1-py3-none-any.whl.metadata (5.5 kB)
Collecting astral==2.2 (from homeassistant)
  Downloading astral-2.2-py2.py3-none-any.whl.metadata (1.5 kB)
Collecting async-interrupt==1.1.1 (from homeassistant)
  Downloading async_interrupt-1.1.1-py3-none-any.whl.metadata (4.8 kB)
Collecting attrs==23.2.0 (from homeassistant)
  Downloading attrs-23.2.0-py3-none-any.whl.metadata (9.5 kB)
Collecting atomicwrites-homeassistant==1.4.1 (from homeassistant)
  Downloading atomicwrites_homeassistant-1.4.1-py2.py3-none-any.whl.metadata (6.0 kB)
Collecting awesomeversion==24.2.0 (from homeassistant)
  Downloading awesomeversion-24.2.0-py3-none-any.whl.metadata (9.0 kB)
Collecting bcrypt==4.1.2 (from homeassistant)
  Downloading bcrypt-4.1.2-cp39-abi3-manylinux_2_28_x86_64.whl.metadata (9.5 kB)
Collecting certifi>=2021.5.30 (from homeassistant)
  Downloading certifi-2024.8.30-py3-none-any.whl.metadata (2.2 kB)
Collecting ciso8601==2.3.1 (from homeassistant)
  Downloading ciso8601-2.3.1-cp311-cp311-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (25 kB)
Collecting hass-nabucasa==0.78.0 (from homeassistant)
  Downloading hass_nabucasa-0.78.0-py3-none-any.whl.metadata (1.2 kB)
Collecting httpx==0.27.0 (from homeassistant)
  Downloading httpx-0.27.0-py3-none-any.whl.metadata (7.2 kB)
Collecting home-assistant-bluetooth==1.12.0 (from homeassistant)
  Downloading home_assistant_bluetooth-1.12.0-py3-none-any.whl.metadata (5.4 kB)
Collecting ifaddr==0.2.0 (from homeassistant)
  Downloading ifaddr-0.2.0-py3-none-any.whl.metadata (4.9 kB)
Collecting Jinja2==3.1.3 (from homeassistant)
  Downloading Jinja2-3.1.3-py3-none-any.whl.metadata (3.3 kB)
Collecting lru-dict==1.3.0 (from homeassistant)
  Downloading lru_dict-1.3.0-cp311-cp311-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (4.5 kB)
Collecting PyJWT==2.8.0 (from homeassistant)
  Downloading PyJWT-2.8.0-py3-none-any.whl.metadata (4.2 kB)
Collecting cryptography==42.0.5 (from homeassistant)
  Downloading cryptography-42.0.5-cp39-abi3-manylinux_2_28_x86_64.whl.metadata (5.3 kB)
Collecting pyOpenSSL==24.0.0 (from homeassistant)
  Downloading pyOpenSSL-24.0.0-py3-none-any.whl.metadata (12 kB)
Collecting orjson==3.9.15 (from homeassistant)
  Downloading orjson-3.9.15-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (49 kB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 49.5/49.5 kB 2.4 MB/s eta 0:00:00
Collecting packaging>=23.1 (from homeassistant)
  Downloading packaging-24.1-py3-none-any.whl.metadata (3.2 kB)
Requirement already satisfied: pip>=21.3.1 in ./lib/python3.11/site-packages (from homeassistant) (24.0)
Collecting python-slugify==8.0.4 (from homeassistant)
  Downloading python_slugify-8.0.4-py2.py3-none-any.whl.metadata (8.5 kB)
Collecting PyYAML==6.0.1 (from homeassistant)
  Downloading PyYAML-6.0.1-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (2.1 kB)
Collecting requests==2.31.0 (from homeassistant)
  Downloading requests-2.31.0-py3-none-any.whl.metadata (4.6 kB)
Collecting typing-extensions<5.0,>=4.10.0 (from homeassistant)
  Downloading typing_extensions-4.12.2-py3-none-any.whl.metadata (3.0 kB)
Collecting ulid-transform==0.9.0 (from homeassistant)
  Downloading ulid_transform-0.9.0-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (5.0 kB)
Collecting urllib3<2,>=1.26.5 (from homeassistant)
  Downloading urllib3-1.26.20-py2.py3-none-any.whl.metadata (50 kB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 50.1/50.1 kB 3.7 MB/s eta 0:00:00
Collecting voluptuous==0.13.1 (from homeassistant)
  Downloading voluptuous-0.13.1-py3-none-any.whl.metadata (20 kB)
Collecting voluptuous-serialize==2.6.0 (from homeassistant)
  Downloading voluptuous_serialize-2.6.0-py3-none-any.whl.metadata (316 bytes)
Collecting yarl==1.9.4 (from homeassistant)
  Downloading yarl-1.9.4-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (31 kB)
Collecting aiosignal>=1.1.2 (from aiohttp==3.9.3->homeassistant)
  Downloading aiosignal-1.3.1-py3-none-any.whl.metadata (4.0 kB)
Collecting frozenlist>=1.1.1 (from aiohttp==3.9.3->homeassistant)
  Downloading frozenlist-1.4.1-cp311-cp311-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (12 kB)
Collecting multidict<7.0,>=4.5 (from aiohttp==3.9.3->homeassistant)
  Downloading multidict-6.0.5-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (4.2 kB)
Collecting zlib-ng>=0.3.0 (from aiohttp-zlib-ng==0.3.1->homeassistant)
  Downloading zlib_ng-0.5.0-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (6.7 kB)
Collecting pytz (from astral==2.2->homeassistant)
  Downloading pytz-2024.1-py2.py3-none-any.whl.metadata (22 kB)
Collecting cffi>=1.12 (from cryptography==42.0.5->homeassistant)
  Downloading cffi-1.17.0-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (1.5 kB)
Collecting pycognito==2023.5.0 (from hass-nabucasa==0.78.0->homeassistant)
  Downloading pycognito-2023.5.0-py3-none-any.whl.metadata (21 kB)
Collecting snitun==0.36.2 (from hass-nabucasa==0.78.0->homeassistant)
  Downloading snitun-0.36.2-py3-none-any.whl.metadata (989 bytes)
Collecting acme==2.8.0 (from hass-nabucasa==0.78.0->homeassistant)
  Downloading acme-2.8.0-py3-none-any.whl.metadata (1.4 kB)
Collecting habluetooth>=0.11.0 (from home-assistant-bluetooth==1.12.0->homeassistant)
  Downloading habluetooth-3.4.0-cp311-cp311-manylinux_2_31_x86_64.whl.metadata (5.1 kB)
Collecting anyio (from httpx==0.27.0->homeassistant)
  Downloading anyio-4.4.0-py3-none-any.whl.metadata (4.6 kB)
Collecting httpcore==1.* (from httpx==0.27.0->homeassistant)
  Downloading httpcore-1.0.5-py3-none-any.whl.metadata (20 kB)
Collecting idna (from httpx==0.27.0->homeassistant)
  Downloading idna-3.8-py3-none-any.whl.metadata (9.9 kB)
Collecting sniffio (from httpx==0.27.0->homeassistant)
  Downloading sniffio-1.3.1-py3-none-any.whl.metadata (3.9 kB)
Collecting MarkupSafe>=2.0 (from Jinja2==3.1.3->homeassistant)
  Downloading MarkupSafe-2.1.5-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (3.0 kB)
Collecting text-unidecode>=1.3 (from python-slugify==8.0.4->homeassistant)
  Downloading text_unidecode-1.3-py2.py3-none-any.whl.metadata (2.4 kB)
Collecting charset-normalizer<4,>=2 (from requests==2.31.0->homeassistant)
  Downloading charset_normalizer-3.3.2-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (33 kB)
Collecting josepy>=1.13.0 (from acme==2.8.0->hass-nabucasa==0.78.0->homeassistant)
  Downloading josepy-1.14.0-py3-none-any.whl.metadata (1.8 kB)
Collecting pyrfc3339 (from acme==2.8.0->hass-nabucasa==0.78.0->homeassistant)
  Downloading pyRFC3339-1.1-py2.py3-none-any.whl.metadata (2.0 kB)
Requirement already satisfied: setuptools>=41.6.0 in ./lib/python3.11/site-packages (from acme==2.8.0->hass-nabucasa==0.78.0->homeassistant) (65.5.0)
Collecting h11<0.15,>=0.13 (from httpcore==1.*->httpx==0.27.0->homeassistant)
  Downloading h11-0.14.0-py3-none-any.whl.metadata (8.2 kB)
Collecting boto3>=1.10.49 (from pycognito==2023.5.0->hass-nabucasa==0.78.0->homeassistant)
  Downloading boto3-1.35.10-py3-none-any.whl.metadata (6.6 kB)
Collecting envs>=1.3 (from pycognito==2023.5.0->hass-nabucasa==0.78.0->homeassistant)
  Downloading envs-1.4-py3-none-any.whl.metadata (842 bytes)
Collecting python-jose>=3.2.0 (from python-jose[cryptography]>=3.2.0->pycognito==2023.5.0->hass-nabucasa==0.78.0->homeassistant)
  Downloading python_jose-3.3.0-py2.py3-none-any.whl.metadata (5.4 kB)
Collecting async-timeout>=3.0.1 (from snitun==0.36.2->hass-nabucasa==0.78.0->homeassistant)
  Downloading async_timeout-4.0.3-py3-none-any.whl.metadata (4.2 kB)
Collecting pycparser (from cffi>=1.12->cryptography==42.0.5->homeassistant)
  Downloading pycparser-2.22-py3-none-any.whl.metadata (943 bytes)
Collecting bleak>=0.21.1 (from habluetooth>=0.11.0->home-assistant-bluetooth==1.12.0->homeassistant)
  Downloading bleak-0.22.2-py3-none-any.whl.metadata (5.4 kB)
Collecting bleak-retry-connector>=3.3.0 (from habluetooth>=0.11.0->home-assistant-bluetooth==1.12.0->homeassistant)
  Downloading bleak_retry_connector-3.5.0-py3-none-any.whl.metadata (5.1 kB)
Collecting bluetooth-adapters>=0.16.1 (from habluetooth>=0.11.0->home-assistant-bluetooth==1.12.0->homeassistant)
  Downloading bluetooth_adapters-0.19.4-py3-none-any.whl.metadata (5.2 kB)
Collecting bluetooth-auto-recovery>=1.2.3 (from habluetooth>=0.11.0->home-assistant-bluetooth==1.12.0->homeassistant)
  Downloading bluetooth_auto_recovery-1.4.2-py3-none-any.whl.metadata (5.5 kB)
Collecting bluetooth-data-tools>=1.16.0 (from habluetooth>=0.11.0->home-assistant-bluetooth==1.12.0->homeassistant)
  Downloading bluetooth_data_tools-1.20.0-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (5.0 kB)
Collecting dbus-fast<3,>=1.83.0 (from bleak>=0.21.1->habluetooth>=0.11.0->home-assistant-bluetooth==1.12.0->homeassistant)
  Downloading dbus_fast-2.24.0-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (10 kB)
Collecting aiooui>=0.1.1 (from bluetooth-adapters>=0.16.1->habluetooth>=0.11.0->home-assistant-bluetooth==1.12.0->homeassistant)
  Downloading aiooui-0.1.6-py3-none-any.whl.metadata (3.8 kB)
Collecting uart-devices>=0.1.0 (from bluetooth-adapters>=0.16.1->habluetooth>=0.11.0->home-assistant-bluetooth==1.12.0->homeassistant)
  Downloading uart_devices-0.1.0-py3-none-any.whl.metadata (4.9 kB)
Collecting usb-devices>=0.4.5 (from bluetooth-adapters>=0.16.1->habluetooth>=0.11.0->home-assistant-bluetooth==1.12.0->homeassistant)
  Downloading usb_devices-0.4.5-py3-none-any.whl.metadata (5.3 kB)
Collecting PyRIC>=0.1.6.3 (from bluetooth-auto-recovery>=1.2.3->habluetooth>=0.11.0->home-assistant-bluetooth==1.12.0->homeassistant)
  Downloading PyRIC-0.1.6.3.tar.gz (870 kB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 870.4/870.4 kB 6.5 MB/s eta 0:00:00
  Installing build dependencies ... done
  Getting requirements to build wheel ... done
  Preparing metadata (pyproject.toml) ... done
Collecting btsocket>=0.2.0 (from bluetooth-auto-recovery>=1.2.3->habluetooth>=0.11.0->home-assistant-bluetooth==1.12.0->homeassistant)
  Downloading btsocket-0.3.0-py2.py3-none-any.whl.metadata (7.0 kB)
Collecting botocore<1.36.0,>=1.35.10 (from boto3>=1.10.49->pycognito==2023.5.0->hass-nabucasa==0.78.0->homeassistant)
  Downloading botocore-1.35.10-py3-none-any.whl.metadata (5.7 kB)
Collecting jmespath<2.0.0,>=0.7.1 (from boto3>=1.10.49->pycognito==2023.5.0->hass-nabucasa==0.78.0->homeassistant)
  Downloading jmespath-1.0.1-py3-none-any.whl.metadata (7.6 kB)
Collecting s3transfer<0.11.0,>=0.10.0 (from boto3>=1.10.49->pycognito==2023.5.0->hass-nabucasa==0.78.0->homeassistant)
  Downloading s3transfer-0.10.2-py3-none-any.whl.metadata (1.7 kB)
Collecting ecdsa!=0.15 (from python-jose>=3.2.0->python-jose[cryptography]>=3.2.0->pycognito==2023.5.0->hass-nabucasa==0.78.0->homeassistant)
  Downloading ecdsa-0.19.0-py2.py3-none-any.whl.metadata (29 kB)
Collecting rsa (from python-jose>=3.2.0->python-jose[cryptography]>=3.2.0->pycognito==2023.5.0->hass-nabucasa==0.78.0->homeassistant)
  Downloading rsa-4.9-py3-none-any.whl.metadata (4.2 kB)
Collecting pyasn1 (from python-jose>=3.2.0->python-jose[cryptography]>=3.2.0->pycognito==2023.5.0->hass-nabucasa==0.78.0->homeassistant)
  Downloading pyasn1-0.6.0-py2.py3-none-any.whl.metadata (8.3 kB)
Collecting python-dateutil<3.0.0,>=2.1 (from botocore<1.36.0,>=1.35.10->boto3>=1.10.49->pycognito==2023.5.0->hass-nabucasa==0.78.0->homeassistant)
  Downloading python_dateutil-2.9.0.post0-py2.py3-none-any.whl.metadata (8.4 kB)
Collecting six>=1.9.0 (from ecdsa!=0.15->python-jose>=3.2.0->python-jose[cryptography]>=3.2.0->pycognito==2023.5.0->hass-nabucasa==0.78.0->homeassistant)
  Downloading six-1.16.0-py2.py3-none-any.whl.metadata (1.8 kB)
Downloading homeassistant-2024.3.3-py3-none-any.whl (35.4 MB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 35.4/35.4 MB 12.8 MB/s eta 0:00:00
Downloading aiohttp-3.9.3-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (1.3 MB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 1.3/1.3 MB 22.7 MB/s eta 0:00:00
Downloading aiohttp_cors-0.7.0-py3-none-any.whl (27 kB)
Downloading aiohttp_fast_url_dispatcher-0.3.0-py3-none-any.whl (8.9 kB)
Downloading aiohttp_zlib_ng-0.3.1-py3-none-any.whl (8.1 kB)
Downloading astral-2.2-py2.py3-none-any.whl (30 kB)
Downloading async_interrupt-1.1.1-py3-none-any.whl (8.9 kB)
Downloading atomicwrites_homeassistant-1.4.1-py2.py3-none-any.whl (7.1 kB)
Downloading attrs-23.2.0-py3-none-any.whl (60 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 60.8/60.8 kB 6.9 MB/s eta 0:00:00
Downloading awesomeversion-24.2.0-py3-none-any.whl (13 kB)
Downloading bcrypt-4.1.2-cp39-abi3-manylinux_2_28_x86_64.whl (698 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 698.9/698.9 kB 14.3 MB/s eta 0:00:00
Downloading ciso8601-2.3.1-cp311-cp311-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl (39 kB)
Downloading cryptography-42.0.5-cp39-abi3-manylinux_2_28_x86_64.whl (4.6 MB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 4.6/4.6 MB 36.7 MB/s eta 0:00:00
Downloading hass_nabucasa-0.78.0-py3-none-any.whl (52 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 52.5/52.5 kB 2.8 MB/s eta 0:00:00
Downloading home_assistant_bluetooth-1.12.0-py3-none-any.whl (7.9 kB)
Downloading httpx-0.27.0-py3-none-any.whl (75 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 75.6/75.6 kB 7.3 MB/s eta 0:00:00
Downloading ifaddr-0.2.0-py3-none-any.whl (12 kB)
Downloading Jinja2-3.1.3-py3-none-any.whl (133 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 133.2/133.2 kB 13.8 MB/s eta 0:00:00
Downloading lru_dict-1.3.0-cp311-cp311-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl (31 kB)
Downloading orjson-3.9.15-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (138 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 138.5/138.5 kB 13.7 MB/s eta 0:00:00
Downloading PyJWT-2.8.0-py3-none-any.whl (22 kB)
Downloading pyOpenSSL-24.0.0-py3-none-any.whl (58 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 58.6/58.6 kB 5.3 MB/s eta 0:00:00
Downloading python_slugify-8.0.4-py2.py3-none-any.whl (10 kB)
Downloading PyYAML-6.0.1-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (757 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 757.7/757.7 kB 16.8 MB/s eta 0:00:00
Downloading requests-2.31.0-py3-none-any.whl (62 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 62.6/62.6 kB 4.0 MB/s eta 0:00:00
Downloading ulid_transform-0.9.0-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (225 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 225.4/225.4 kB 20.6 MB/s eta 0:00:00
Downloading voluptuous-0.13.1-py3-none-any.whl (29 kB)
Downloading voluptuous_serialize-2.6.0-py3-none-any.whl (6.8 kB)
Downloading yarl-1.9.4-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (328 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 328.1/328.1 kB 16.0 MB/s eta 0:00:00
Downloading acme-2.8.0-py3-none-any.whl (95 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 95.7/95.7 kB 9.8 MB/s eta 0:00:00
Downloading httpcore-1.0.5-py3-none-any.whl (77 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 77.9/77.9 kB 8.0 MB/s eta 0:00:00
Downloading pycognito-2023.5.0-py3-none-any.whl (24 kB)
Downloading snitun-0.36.2-py3-none-any.whl (36 kB)
Downloading certifi-2024.8.30-py3-none-any.whl (167 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 167.3/167.3 kB 10.5 MB/s eta 0:00:00
Downloading packaging-24.1-py3-none-any.whl (53 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 54.0/54.0 kB 5.5 MB/s eta 0:00:00
Downloading typing_extensions-4.12.2-py3-none-any.whl (37 kB)
Downloading urllib3-1.26.20-py2.py3-none-any.whl (144 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 144.2/144.2 kB 4.3 MB/s eta 0:00:00
Downloading aiosignal-1.3.1-py3-none-any.whl (7.6 kB)
Downloading cffi-1.17.0-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (466 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 466.9/466.9 kB 16.7 MB/s eta 0:00:00
Downloading charset_normalizer-3.3.2-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (140 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 140.3/140.3 kB 12.9 MB/s eta 0:00:00
Downloading frozenlist-1.4.1-cp311-cp311-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl (272 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 272.3/272.3 kB 11.5 MB/s eta 0:00:00
Downloading habluetooth-3.4.0-cp311-cp311-manylinux_2_31_x86_64.whl (2.8 MB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 2.8/2.8 MB 7.7 MB/s eta 0:00:00
Downloading idna-3.8-py3-none-any.whl (66 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 66.9/66.9 kB 3.9 MB/s eta 0:00:00
Downloading MarkupSafe-2.1.5-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (28 kB)
Downloading multidict-6.0.5-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (128 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 128.7/128.7 kB 12.9 MB/s eta 0:00:00
Downloading pytz-2024.1-py2.py3-none-any.whl (505 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 505.5/505.5 kB 21.4 MB/s eta 0:00:00
Downloading text_unidecode-1.3-py2.py3-none-any.whl (78 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 78.2/78.2 kB 5.9 MB/s eta 0:00:00
Downloading zlib_ng-0.5.0-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (108 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 108.2/108.2 kB 10.6 MB/s eta 0:00:00
Downloading anyio-4.4.0-py3-none-any.whl (86 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 86.8/86.8 kB 9.3 MB/s eta 0:00:00
Downloading sniffio-1.3.1-py3-none-any.whl (10 kB)
Downloading async_timeout-4.0.3-py3-none-any.whl (5.7 kB)
Downloading bleak-0.22.2-py3-none-any.whl (142 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 142.6/142.6 kB 9.4 MB/s eta 0:00:00
Downloading bleak_retry_connector-3.5.0-py3-none-any.whl (15 kB)
Downloading bluetooth_adapters-0.19.4-py3-none-any.whl (19 kB)
Downloading bluetooth_auto_recovery-1.4.2-py3-none-any.whl (10 kB)
Downloading bluetooth_data_tools-1.20.0-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (846 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 846.9/846.9 kB 21.3 MB/s eta 0:00:00
Downloading boto3-1.35.10-py3-none-any.whl (139 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 139.2/139.2 kB 13.4 MB/s eta 0:00:00
Downloading envs-1.4-py3-none-any.whl (10 kB)
Downloading h11-0.14.0-py3-none-any.whl (58 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 58.3/58.3 kB 4.6 MB/s eta 0:00:00
Downloading josepy-1.14.0-py3-none-any.whl (32 kB)
Downloading python_jose-3.3.0-py2.py3-none-any.whl (33 kB)
Downloading pycparser-2.22-py3-none-any.whl (117 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 117.6/117.6 kB 10.7 MB/s eta 0:00:00
Downloading pyRFC3339-1.1-py2.py3-none-any.whl (5.7 kB)
Downloading aiooui-0.1.6-py3-none-any.whl (379 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 380.0/380.0 kB 23.0 MB/s eta 0:00:00
Downloading botocore-1.35.10-py3-none-any.whl (12.5 MB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 12.5/12.5 MB 32.0 MB/s eta 0:00:00
Downloading btsocket-0.3.0-py2.py3-none-any.whl (14 kB)
Downloading dbus_fast-2.24.0-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (5.4 MB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 5.4/5.4 MB 38.8 MB/s eta 0:00:00
Downloading ecdsa-0.19.0-py2.py3-none-any.whl (149 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 149.3/149.3 kB 10.9 MB/s eta 0:00:00
Downloading jmespath-1.0.1-py3-none-any.whl (20 kB)
Downloading s3transfer-0.10.2-py3-none-any.whl (82 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 82.7/82.7 kB 8.7 MB/s eta 0:00:00
Downloading uart_devices-0.1.0-py3-none-any.whl (4.8 kB)
Downloading usb_devices-0.4.5-py3-none-any.whl (5.3 kB)
Downloading pyasn1-0.6.0-py2.py3-none-any.whl (85 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 85.3/85.3 kB 2.6 MB/s eta 0:00:00
Downloading rsa-4.9-py3-none-any.whl (34 kB)
Downloading python_dateutil-2.9.0.post0-py2.py3-none-any.whl (229 kB)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 229.9/229.9 kB 18.9 MB/s eta 0:00:00
Downloading six-1.16.0-py2.py3-none-any.whl (11 kB)
Building wheels for collected packages: PyRIC
  Building wheel for PyRIC (pyproject.toml) ... done
  Created wheel for PyRIC: filename=PyRIC-0.1.6.3-py2.py3-none-any.whl size=407895 sha256=54b9c0ea6e5ef5737488f6562f8fc2e99e1f0b84c45265d9473b1ccd14e3d48b
  Stored in directory: /root/.cache/pip/wheels/af/00/62/c07ed94fe5b5b313f7825f3d039bae9bab002cdb7c198d980a
Successfully built PyRIC
Installing collected packages: voluptuous, text-unidecode, pytz, PyRIC, ifaddr, ciso8601, btsocket, zlib-ng, voluptuous-serialize, usb-devices, urllib3, ulid-transform, uart-devices, typing-extensions, sniffio, six, PyYAML, python-slugify, pyrfc3339, PyJWT, pycparser, pyasn1, packaging, orjson, multidict, MarkupSafe, lru-dict, jmespath, idna, h11, frozenlist, envs, dbus-fast, charset-normalizer, certifi, bcrypt, awesomeversion, attrs, atomicwrites-homeassistant, async-timeout, async-interrupt, astral, aiooui, yarl, rsa, requests, python-dateutil, Jinja2, httpcore, ecdsa, cffi, bleak, anyio, aiosignal, python-jose, httpx, cryptography, botocore, bluetooth-adapters, aiohttp, snitun, s3transfer, pyOpenSSL, bluetooth-data-tools, bluetooth-auto-recovery, bleak-retry-connector, aiohttp-zlib-ng, aiohttp-fast-url-dispatcher, aiohttp-cors, josepy, habluetooth, boto3, pycognito, home-assistant-bluetooth, acme, hass-nabucasa, homeassistant
Successfully installed Jinja2-3.1.3 MarkupSafe-2.1.5 PyJWT-2.8.0 PyRIC-0.1.6.3 PyYAML-6.0.1 acme-2.8.0 aiohttp-3.9.3 aiohttp-cors-0.7.0 aiohttp-fast-url-dispatcher-0.3.0 aiohttp-zlib-ng-0.3.1 aiooui-0.1.6 aiosignal-1.3.1 anyio-4.4.0 astral-2.2 async-interrupt-1.1.1 async-timeout-4.0.3 atomicwrites-homeassistant-1.4.1 attrs-23.2.0 awesomeversion-24.2.0 bcrypt-4.1.2 bleak-0.22.2 bleak-retry-connector-3.5.0 bluetooth-adapters-0.19.4 bluetooth-auto-recovery-1.4.2 bluetooth-data-tools-1.20.0 boto3-1.35.10 botocore-1.35.10 btsocket-0.3.0 certifi-2024.8.30 cffi-1.17.0 charset-normalizer-3.3.2 ciso8601-2.3.1 cryptography-42.0.5 dbus-fast-2.24.0 ecdsa-0.19.0 envs-1.4 frozenlist-1.4.1 h11-0.14.0 habluetooth-3.4.0 hass-nabucasa-0.78.0 home-assistant-bluetooth-1.12.0 homeassistant-2024.3.3 httpcore-1.0.5 httpx-0.27.0 idna-3.8 ifaddr-0.2.0 jmespath-1.0.1 josepy-1.14.0 lru-dict-1.3.0 multidict-6.0.5 orjson-3.9.15 packaging-24.1 pyOpenSSL-24.0.0 pyasn1-0.6.0 pycognito-2023.5.0 pycparser-2.22 pyrfc3339-1.1 python-dateutil-2.9.0.post0 python-jose-3.3.0 python-slugify-8.0.4 pytz-2024.1 requests-2.31.0 rsa-4.9 s3transfer-0.10.2 six-1.16.0 sniffio-1.3.1 snitun-0.36.2 text-unidecode-1.3 typing-extensions-4.12.2 uart-devices-0.1.0 ulid-transform-0.9.0 urllib3-1.26.20 usb-devices-0.4.5 voluptuous-0.13.1 voluptuous-serialize-2.6.0 yarl-1.9.4 zlib-ng-0.5.0

[notice] A new release of pip is available: 24.0 -> 24.2
[notice] To update, run: pip install --upgrade pip
(homeassistant) root@FelippeBarcelos:~/homeassistant/homeassistant#
Como prosseguimos?

---

### ASSISTENTE

Ótimo! O Home Assistant foi instalado com sucesso no ambiente virtual usando o Python 3.11. Agora você pode prosseguir para iniciar o Home Assistant.

### Passo 1: Iniciar o Home Assistant

Com o ambiente virtual ativado, execute o seguinte comando para iniciar o Home Assistant:

```bash
hass
```

### Passo 2: Aguardar a Inicialização

- O Home Assistant começará a iniciar. O processo pode demorar alguns minutos, especialmente na primeira vez.
- Durante a inicialização, você verá várias mensagens de log indicando o progresso da configuração.

### Passo 3: Acessar a Interface Web do Home Assistant

- Após a inicialização, abra um navegador de internet no seu computador e digite o seguinte endereço:

```
http://localhost:8123
```

- Isso abrirá a interface web do Home Assistant, onde você poderá criar uma conta de usuário e configurar as preferências iniciais.

### Passo 4: Configurar o Home Assistant

- Siga as instruções na interface web para configurar sua conta de usuário e as configurações básicas do Home Assistant.
- Após a configuração inicial, você pode começar a adicionar dispositivos, integrações e criar automações de acordo com suas necessidades.

### Observação Adicional

Se o comando `hass` não for reconhecido, verifique se você ainda está no ambiente virtual do Python 3.11. Você deve ver algo como `(homeassistant)` no início do seu prompt. Caso contrário, ative o ambiente virtual novamente usando:

```bash
source bin/activate
```

Se houver mais alguma dúvida ou se precisar de ajuda adicional, é só me avisar!

---

### USUÁRIO

Downloading six-1.16.0-py2.py3-none-any.whl (11 kB)
Building wheels for collected packages: PyRIC
  Building wheel for PyRIC (pyproject.toml) ... done
  Created wheel for PyRIC: filename=PyRIC-0.1.6.3-py2.py3-none-any.whl size=407895 sha256=54b9c0ea6e5ef5737488f6562f8fc2e99e1f0b84c45265d9473b1ccd14e3d48b
  Stored in directory: /root/.cache/pip/wheels/af/00/62/c07ed94fe5b5b313f7825f3d039bae9bab002cdb7c198d980a
Successfully built PyRIC
Installing collected packages: voluptuous, text-unidecode, pytz, PyRIC, ifaddr, ciso8601, btsocket, zlib-ng, voluptuous-serialize, usb-devices, urllib3, ulid-transform, uart-devices, typing-extensions, sniffio, six, PyYAML, python-slugify, pyrfc3339, PyJWT, pycparser, pyasn1, packaging, orjson, multidict, MarkupSafe, lru-dict, jmespath, idna, h11, frozenlist, envs, dbus-fast, charset-normalizer, certifi, bcrypt, awesomeversion, attrs, atomicwrites-homeassistant, async-timeout, async-interrupt, astral, aiooui, yarl, rsa, requests, python-dateutil, Jinja2, httpcore, ecdsa, cffi, bleak, anyio, aiosignal, python-jose, httpx, cryptography, botocore, bluetooth-adapters, aiohttp, snitun, s3transfer, pyOpenSSL, bluetooth-data-tools, bluetooth-auto-recovery, bleak-retry-connector, aiohttp-zlib-ng, aiohttp-fast-url-dispatcher, aiohttp-cors, josepy, habluetooth, boto3, pycognito, home-assistant-bluetooth, acme, hass-nabucasa, homeassistant
Successfully installed Jinja2-3.1.3 MarkupSafe-2.1.5 PyJWT-2.8.0 PyRIC-0.1.6.3 PyYAML-6.0.1 acme-2.8.0 aiohttp-3.9.3 aiohttp-cors-0.7.0 aiohttp-fast-url-dispatcher-0.3.0 aiohttp-zlib-ng-0.3.1 aiooui-0.1.6 aiosignal-1.3.1 anyio-4.4.0 astral-2.2 async-interrupt-1.1.1 async-timeout-4.0.3 atomicwrites-homeassistant-1.4.1 attrs-23.2.0 awesomeversion-24.2.0 bcrypt-4.1.2 bleak-0.22.2 bleak-retry-connector-3.5.0 bluetooth-adapters-0.19.4 bluetooth-auto-recovery-1.4.2 bluetooth-data-tools-1.20.0 boto3-1.35.10 botocore-1.35.10 btsocket-0.3.0 certifi-2024.8.30 cffi-1.17.0 charset-normalizer-3.3.2 ciso8601-2.3.1 cryptography-42.0.5 dbus-fast-2.24.0 ecdsa-0.19.0 envs-1.4 frozenlist-1.4.1 h11-0.14.0 habluetooth-3.4.0 hass-nabucasa-0.78.0 home-assistant-bluetooth-1.12.0 homeassistant-2024.3.3 httpcore-1.0.5 httpx-0.27.0 idna-3.8 ifaddr-0.2.0 jmespath-1.0.1 josepy-1.14.0 lru-dict-1.3.0 multidict-6.0.5 orjson-3.9.15 packaging-24.1 pyOpenSSL-24.0.0 pyasn1-0.6.0 pycognito-2023.5.0 pycparser-2.22 pyrfc3339-1.1 python-dateutil-2.9.0.post0 python-jose-3.3.0 python-slugify-8.0.4 pytz-2024.1 requests-2.31.0 rsa-4.9 s3transfer-0.10.2 six-1.16.0 sniffio-1.3.1 snitun-0.36.2 text-unidecode-1.3 typing-extensions-4.12.2 uart-devices-0.1.0 ulid-transform-0.9.0 urllib3-1.26.20 usb-devices-0.4.5 voluptuous-0.13.1 voluptuous-serialize-2.6.0 yarl-1.9.4 zlib-ng-0.5.0

[notice] A new release of pip is available: 24.0 -> 24.2
[notice] To update, run: pip install --upgrade pip
(homeassistant) root@FelippeBarcelos:~/homeassistant/homeassistant# hass
2024-09-03 08:27:02.583 ERROR (MainThread) [haffmpeg.core] FFmpeg fails [Errno 2] No such file or directory: 'ffmpeg'
Traceback (most recent call last):
  File "/root/homeassistant/homeassistant/lib/python3.11/site-packages/haffmpeg/core.py", line 137, in open
    self._proc = await self._loop.run_in_executor(None, proc_func)
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.11/concurrent/futures/thread.py", line 58, in run
    result = self.fn(*self.args, **self.kwargs)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.11/subprocess.py", line 1026, in __init__
    self._execute_child(args, executable, preexec_fn, close_fds,
  File "/usr/lib/python3.11/subprocess.py", line 1955, in _execute_child
    raise child_exception_type(errno_num, err_msg, err_filename)
FileNotFoundError: [Errno 2] No such file or directory: 'ffmpeg'
2024-09-03 08:27:02.587 WARNING (MainThread) [haffmpeg.tools] Error starting FFmpeg.
2024-09-03 08:27:23.407 WARNING (MainThread) [homeassistant.bootstrap] Support for the running Python version 3.11.9 is deprecated and will be removed in Home Assistant 2024.4; Please upgrade Python to 3.12
2024-09-03 08:27:23.413 WARNING (Recorder) [homeassistant.components.recorder.migration] Database is about to upgrade from schema version: 41 to: 42
2024-09-03 08:27:23.437 WARNING (Recorder) [homeassistant.components.recorder.migration] Upgrade to version 42 done


---

### ASSISTENTE

O Home Assistant foi iniciado, mas você encontrou alguns avisos e erros que precisam ser resolvidos:

### 1. Erro do FFmpeg

O erro relacionado ao FFmpeg indica que o Home Assistant está tentando usar o FFmpeg, um software necessário para manipulação de áudio e vídeo, mas ele não está instalado no seu sistema.

#### Como Resolver

Para resolver esse problema, você deve instalar o FFmpeg:

```bash
sudo apt install ffmpeg -y
```

Depois de instalar o FFmpeg, reinicie o Home Assistant com:

```bash
hass
```

### 2. Aviso Sobre a Versão do Python

O Home Assistant está avisando que o suporte para a versão do Python que você está usando (3.11.9) será removido em uma versão futura do Home Assistant (2024.4). 

#### Como Resolver

Se quiser garantir que o Home Assistant continue funcionando sem problemas, você pode considerar atualizar para o Python 3.12 quando ele estiver disponível para o seu sistema. No momento, como o aviso ainda não é crítico (apenas um aviso para uma atualização futura), você pode continuar usando o Python 3.11.9.

### 3. Aviso Sobre a Atualização do Banco de Dados

Este é apenas um aviso indicando que o banco de dados do Home Assistant foi atualizado para uma nova versão de esquema. Não há ação necessária da sua parte para esse aviso.

### Próximos Passos

1. **Instalar o FFmpeg:**
   Instale o FFmpeg usando o comando fornecido acima.

2. **Reiniciar o Home Assistant:**
   Após instalar o FFmpeg, execute novamente o comando `hass` para iniciar o Home Assistant e verificar se o erro do FFmpeg foi resolvido.

3. **Verificar o Funcionamento:**
   Acesse a interface web do Home Assistant em `http://localhost:8123` para garantir que tudo esteja funcionando corretamente.

Se precisar de mais alguma ajuda, é só me avisar!

---

### USUÁRIO

root@FelippeBarcelos:~# sudo apt install ffmpeg -y
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  alsa-topology-conf alsa-ucm-conf fontconfig i965-va-driver intel-media-va-driver libaacs0 libaom3
  libasound2 libasound2-data libass9 libasyncns0 libavc1394-0 libavcodec58 libavdevice58 libavfilter7
  libavformat58 libavutil56 libbdplus0 libblas3 libbluray2 libbs2b0 libcaca0 libcairo-gobject2 libcairo2
  libcdio-cdda2 libcdio-paranoia2 libcdio19 libchromaprint1 libcodec2-1.0 libdatrie1 libdav1d5
  libdc1394-25 libdecor-0-0 libdecor-0-plugin-1-cairo libdrm-amdgpu1 libdrm-intel1 libdrm-nouveau2
  libdrm-radeon1 libflac8 libflite1 libgbm1 libgdk-pixbuf-2.0-0 libgdk-pixbuf2.0-bin
  libgdk-pixbuf2.0-common libgfortran5 libgl1 libgl1-amber-dri libgl1-mesa-dri libglapi-mesa libglvnd0
  libglx-mesa0 libglx0 libgme0 libgraphite2-3 libgsm1 libharfbuzz0b libiec61883-0 libigdgmm12
  libjack-jackd2-0 liblapack3 liblilv-0-0 libllvm15 libmfx1 libmp3lame0 libmpg123-0 libmysofa1 libnorm1
  libogg0 libopenal-data libopenal1 libopenjp2-7 libopenmpt0 libopus0 libpango-1.0-0 libpangocairo-1.0-0
  libpangoft2-1.0-0 libpciaccess0 libpgm-5.3-0 libpixman-1-0 libpocketsphinx3 libpostproc55 libpulse0
  librabbitmq4 libraw1394-11 librsvg2-2 librsvg2-common librubberband2 libsamplerate0 libsdl2-2.0-0
  libsensors-config libsensors5 libserd-0-0 libshine3 libsnappy1v5 libsndfile1 libsndio7.0 libsord-0-0
  libsoxr0 libspeex1 libsphinxbase3 libsratom-0-0 libsrt1.4-gnutls libssh-gcrypt-4 libswresample3
  libswscale5 libthai-data libthai0 libtheora0 libtwolame0 libudfread0 libva-drm2 libva-x11-2 libva2
  libvdpau1 libvidstab1.1 libvorbis0a libvorbisenc2 libvorbisfile3 libvpx7 libwayland-client0
  libwayland-cursor0 libwayland-egl1 libwayland-server0 libwebpmux3 libx11-xcb1 libx264-163 libx265-199
  libxcb-dri2-0 libxcb-dri3-0 libxcb-glx0 libxcb-present0 libxcb-randr0 libxcb-render0 libxcb-shape0
  libxcb-shm0 libxcb-sync1 libxcb-xfixes0 libxcursor1 libxfixes3 libxi6 libxinerama1 libxkbcommon0
  libxrandr2 libxrender1 libxshmfence1 libxss1 libxv1 libxvidcore4 libxxf86vm1 libzimg2 libzmq5
  libzvbi-common libzvbi0 mesa-va-drivers mesa-vdpau-drivers ocl-icd-libopencl1 pocketsphinx-en-us
  va-driver-all vdpau-driver-all x11-common
Suggested packages:
  ffmpeg-doc i965-va-driver-shaders libasound2-plugins alsa-utils libcuda1 libnvcuvid1 libnvidia-encode1
  libbluray-bdj jackd2 libportaudio2 opus-tools pulseaudio libraw1394-doc librsvg2-bin xdg-utils
  lm-sensors serdi sndiod sordi speex opencl-icd libvdpau-va-gl1
The following NEW packages will be installed:
  alsa-topology-conf alsa-ucm-conf ffmpeg fontconfig i965-va-driver intel-media-va-driver libaacs0 libaom3
  libasound2 libasound2-data libass9 libasyncns0 libavc1394-0 libavcodec58 libavdevice58 libavfilter7
  libavformat58 libavutil56 libbdplus0 libblas3 libbluray2 libbs2b0 libcaca0 libcairo-gobject2 libcairo2
  libcdio-cdda2 libcdio-paranoia2 libcdio19 libchromaprint1 libcodec2-1.0 libdatrie1 libdav1d5
  libdc1394-25 libdecor-0-0 libdecor-0-plugin-1-cairo libdrm-amdgpu1 libdrm-intel1 libdrm-nouveau2
  libdrm-radeon1 libflac8 libflite1 libgbm1 libgdk-pixbuf-2.0-0 libgdk-pixbuf2.0-bin
  libgdk-pixbuf2.0-common libgfortran5 libgl1 libgl1-amber-dri libgl1-mesa-dri libglapi-mesa libglvnd0
  libglx-mesa0 libglx0 libgme0 libgraphite2-3 libgsm1 libharfbuzz0b libiec61883-0 libigdgmm12
  libjack-jackd2-0 liblapack3 liblilv-0-0 libllvm15 libmfx1 libmp3lame0 libmpg123-0 libmysofa1 libnorm1
  libogg0 libopenal-data libopenal1 libopenjp2-7 libopenmpt0 libopus0 libpango-1.0-0 libpangocairo-1.0-0
  libpangoft2-1.0-0 libpciaccess0 libpgm-5.3-0 libpixman-1-0 libpocketsphinx3 libpostproc55 libpulse0
  librabbitmq4 libraw1394-11 librsvg2-2 librsvg2-common librubberband2 libsamplerate0 libsdl2-2.0-0
  libsensors-config libsensors5 libserd-0-0 libshine3 libsnappy1v5 libsndfile1 libsndio7.0 libsord-0-0
  libsoxr0 libspeex1 libsphinxbase3 libsratom-0-0 libsrt1.4-gnutls libssh-gcrypt-4 libswresample3
  libswscale5 libthai-data libthai0 libtheora0 libtwolame0 libudfread0 libva-drm2 libva-x11-2 libva2
  libvdpau1 libvidstab1.1 libvorbis0a libvorbisenc2 libvorbisfile3 libvpx7 libwayland-client0
  libwayland-cursor0 libwayland-egl1 libwayland-server0 libwebpmux3 libx11-xcb1 libx264-163 libx265-199
  libxcb-dri2-0 libxcb-dri3-0 libxcb-glx0 libxcb-present0 libxcb-randr0 libxcb-render0 libxcb-shape0
  libxcb-shm0 libxcb-sync1 libxcb-xfixes0 libxcursor1 libxfixes3 libxi6 libxinerama1 libxkbcommon0
  libxrandr2 libxrender1 libxshmfence1 libxss1 libxv1 libxvidcore4 libxxf86vm1 libzimg2 libzmq5
  libzvbi-common libzvbi0 mesa-va-drivers mesa-vdpau-drivers ocl-icd-libopencl1 pocketsphinx-en-us
  va-driver-all vdpau-driver-all x11-common
0 upgraded, 161 newly installed, 0 to remove and 2 not upgraded.
Need to get 138 MB of archives.
After this operation, 429 MB of additional disk space will be used.
Get:1 http://archive.ubuntu.com/ubuntu jammy/main amd64 alsa-topology-conf all 1.2.5.1-2 [15.5 kB]
Get:2 http://archive.ubuntu.com/ubuntu jammy/main amd64 libasound2-data all 1.2.6.1-1ubuntu1 [19.1 kB]
Get:3 http://archive.ubuntu.com/ubuntu jammy/main amd64 libasound2 amd64 1.2.6.1-1ubuntu1 [390 kB]
Get:4 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 alsa-ucm-conf all 1.2.6.3-1ubuntu1.11 [43.6 kB]
Get:5 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libaom3 amd64 3.3.0-1 [1748 kB]
Get:6 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libva2 amd64 2.14.0-1 [65.0 kB]
Get:7 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libmfx1 amd64 22.3.0-1 [3105 kB]
Get:8 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libva-drm2 amd64 2.14.0-1 [7502 B]
Get:9 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxfixes3 amd64 1:6.0.0-1 [11.7 kB]
Get:10 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libva-x11-2 amd64 2.14.0-1 [12.6 kB]
Get:11 http://archive.ubuntu.com/ubuntu jammy/main amd64 libvdpau1 amd64 1.4-3build2 [27.0 kB]
Get:12 http://archive.ubuntu.com/ubuntu jammy/universe amd64 ocl-icd-libopencl1 amd64 2.2.14-3 [39.1 kB]
Get:13 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libavutil56 amd64 7:4.4.2-0ubuntu0.22.04.1 [290 kB]
Get:14 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libpixman-1-0 amd64 0.40.0-1ubuntu0.22.04.1 [264 kB]
Get:15 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-render0 amd64 1.14-3ubuntu3 [16.4 kB]
Get:16 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-shm0 amd64 1.14-3ubuntu3 [5780 B]
Get:17 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxrender1 amd64 1:0.9.10-1build4 [19.7 kB]
Get:18 http://archive.ubuntu.com/ubuntu jammy/main amd64 libcairo2 amd64 1.16.0-5ubuntu2 [628 kB]
Get:19 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libcodec2-1.0 amd64 1.0.1-3 [8435 kB]
Get:20 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libdav1d5 amd64 0.9.2-1 [463 kB]
Get:21 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libgsm1 amd64 1.0.19-1 [27.7 kB]
Get:22 http://archive.ubuntu.com/ubuntu jammy/main amd64 libmp3lame0 amd64 3.100-3build2 [141 kB]
Get:23 http://archive.ubuntu.com/ubuntu jammy/main amd64 libopenjp2-7 amd64 2.4.0-6 [158 kB]
Get:24 http://archive.ubuntu.com/ubuntu jammy/main amd64 libopus0 amd64 1.3.1-0.1build2 [203 kB]
Get:25 http://archive.ubuntu.com/ubuntu jammy/main amd64 libcairo-gobject2 amd64 1.16.0-5ubuntu2 [19.4 kB]
Get:26 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgdk-pixbuf2.0-common all 2.42.8+dfsg-1ubuntu0.3 [5630 B]
Get:27 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgdk-pixbuf-2.0-0 amd64 2.42.8+dfsg-1ubuntu0.3 [148 kB]
Get:28 http://archive.ubuntu.com/ubuntu jammy/main amd64 fontconfig amd64 2.13.1-4.2ubuntu5 [177 kB]
Get:29 http://archive.ubuntu.com/ubuntu jammy/main amd64 libgraphite2-3 amd64 1.3.14-1build2 [71.3 kB]
Get:30 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libharfbuzz0b amd64 2.7.4-1ubuntu3.1 [352 kB]
Get:31 http://archive.ubuntu.com/ubuntu jammy/main amd64 libthai-data all 0.1.29-1build1 [162 kB]
Get:32 http://archive.ubuntu.com/ubuntu jammy/main amd64 libdatrie1 amd64 0.2.13-2 [19.9 kB]
Get:33 http://archive.ubuntu.com/ubuntu jammy/main amd64 libthai0 amd64 0.1.29-1build1 [19.2 kB]
Get:34 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libpango-1.0-0 amd64 1.50.6+ds-2ubuntu1 [230 kB]
Get:35 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libpangoft2-1.0-0 amd64 1.50.6+ds-2ubuntu1 [54.0 kB]
Get:36 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libpangocairo-1.0-0 amd64 1.50.6+ds-2ubuntu1 [39.8 kB]
Get:37 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 librsvg2-2 amd64 2.52.5+dfsg-3ubuntu0.2 [2974 kB]
Get:38 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libshine3 amd64 3.1.1-2 [23.2 kB]
Get:39 http://archive.ubuntu.com/ubuntu jammy/main amd64 libsnappy1v5 amd64 1.1.8-1build3 [17.5 kB]
Get:40 http://archive.ubuntu.com/ubuntu jammy/main amd64 libspeex1 amd64 1.2~rc1.2-1.1ubuntu3 [57.9 kB]
Get:41 http://archive.ubuntu.com/ubuntu jammy/main amd64 libsoxr0 amd64 0.1.3-4build2 [79.8 kB]
Get:42 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libswresample3 amd64 7:4.4.2-0ubuntu0.22.04.1 [62.2 kB]
Get:43 http://archive.ubuntu.com/ubuntu jammy/main amd64 libogg0 amd64 1.3.5-0ubuntu3 [22.9 kB]
Get:44 http://archive.ubuntu.com/ubuntu jammy/main amd64 libtheora0 amd64 1.1.1+dfsg.1-15ubuntu4 [209 kB]
Get:45 http://archive.ubuntu.com/ubuntu jammy/main amd64 libtwolame0 amd64 0.4.0-2build2 [52.5 kB]
Get:46 http://archive.ubuntu.com/ubuntu jammy/main amd64 libvorbis0a amd64 1.3.7-1build2 [99.2 kB]
Get:47 http://archive.ubuntu.com/ubuntu jammy/main amd64 libvorbisenc2 amd64 1.3.7-1build2 [82.6 kB]
Get:48 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libvpx7 amd64 1.11.0-2ubuntu2.3 [1078 kB]
Get:49 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libwebpmux3 amd64 1.2.2-2ubuntu0.22.04.2 [20.5 kB]
Get:50 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libx264-163 amd64 2:0.163.3060+git5db6aa6-2build1 [591 kB]
Get:51 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libx265-199 amd64 3.5-2 [1170 kB]
Get:52 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libxvidcore4 amd64 2:1.3.7-1 [201 kB]
Get:53 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libzvbi-common all 0.2.35-19 [35.5 kB]
Get:54 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libzvbi0 amd64 0.2.35-19 [262 kB]
Get:55 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libavcodec58 amd64 7:4.4.2-0ubuntu0.22.04.1 [5567 kB]
Get:56 http://archive.ubuntu.com/ubuntu jammy/main amd64 libraw1394-11 amd64 2.1.2-2build2 [27.0 kB]
Get:57 http://archive.ubuntu.com/ubuntu jammy/main amd64 libavc1394-0 amd64 0.5.4-5build2 [17.0 kB]
Get:58 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libass9 amd64 1:0.15.2-1 [97.5 kB]
Get:59 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libudfread0 amd64 1.1.2-1 [16.2 kB]
Get:60 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libbluray2 amd64 1:1.3.1-1 [159 kB]
Get:61 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libchromaprint1 amd64 1.5.1-2 [28.4 kB]
Get:62 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libgme0 amd64 0.6.3-2 [127 kB]
Get:63 http://archive.ubuntu.com/ubuntu jammy/main amd64 libmpg123-0 amd64 1.29.3-1build1 [172 kB]
Get:64 http://archive.ubuntu.com/ubuntu jammy/main amd64 libvorbisfile3 amd64 1.3.7-1build2 [17.1 kB]
Get:65 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libopenmpt0 amd64 0.6.1-1 [592 kB]
Get:66 http://archive.ubuntu.com/ubuntu jammy/main amd64 librabbitmq4 amd64 0.10.0-1ubuntu2 [39.3 kB]
Get:67 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libsrt1.4-gnutls amd64 1.4.4-4 [309 kB]
Get:68 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libssh-gcrypt-4 amd64 0.9.6-2ubuntu0.22.04.3 [223 kB]
Get:69 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libnorm1 amd64 1.5.9+dfsg-2 [221 kB]
Get:70 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libpgm-5.3-0 amd64 5.3.128~dfsg-2 [161 kB]
Get:71 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libzmq5 amd64 4.3.4-2 [256 kB]
Get:72 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libavformat58 amd64 7:4.4.2-0ubuntu0.22.04.1 [1103 kB]
Get:73 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libbs2b0 amd64 3.1.0+dfsg-2.2build1 [10.2 kB]
Get:74 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libflite1 amd64 2.2-3 [13.7 MB]
Get:75 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libserd-0-0 amd64 0.30.10-2 [40.8 kB]
Get:76 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libsord-0-0 amd64 0.16.8-2 [21.2 kB]
Get:77 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libsratom-0-0 amd64 0.6.8-1 [17.0 kB]
Get:78 http://archive.ubuntu.com/ubuntu jammy/universe amd64 liblilv-0-0 amd64 0.24.12-2 [42.8 kB]
Get:79 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libmysofa1 amd64 1.2.1~dfsg0-1 [1157 kB]
Get:80 http://archive.ubuntu.com/ubuntu jammy/main amd64 libblas3 amd64 3.10.0-2ubuntu1 [228 kB]
Get:81 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgfortran5 amd64 12.3.0-1ubuntu1~22.04 [879 kB]
Get:82 http://archive.ubuntu.com/ubuntu jammy/main amd64 liblapack3 amd64 3.10.0-2ubuntu1 [2504 kB]
Get:83 http://archive.ubuntu.com/ubuntu jammy/main amd64 libasyncns0 amd64 0.8-6build2 [12.8 kB]
Get:84 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libflac8 amd64 1.3.3-2ubuntu0.2 [111 kB]
Get:85 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libsndfile1 amd64 1.0.31-2ubuntu0.1 [197 kB]
Get:86 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libx11-xcb1 amd64 2:1.7.5-1ubuntu0.3 [7802 B]
Get:87 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libpulse0 amd64 1:15.99.1+dfsg1-1ubuntu2.2 [298 kB]
Get:88 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libsphinxbase3 amd64 0.8+5prealpha+1-13build1 [126 kB]
Get:89 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libpocketsphinx3 amd64 0.8.0+real5prealpha+1-14ubuntu1 [132 kB]
Get:90 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libpostproc55 amd64 7:4.4.2-0ubuntu0.22.04.1 [60.1 kB]
Get:91 http://archive.ubuntu.com/ubuntu jammy/main amd64 libsamplerate0 amd64 0.2.2-1build1 [1359 kB]
Get:92 http://archive.ubuntu.com/ubuntu jammy/universe amd64 librubberband2 amd64 2.0.0-2 [90.0 kB]
Get:93 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libswscale5 amd64 7:4.4.2-0ubuntu0.22.04.1 [180 kB]
Get:94 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libvidstab1.1 amd64 1.1.0-2 [35.0 kB]
Get:95 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libzimg2 amd64 3.0.3+ds1-1 [241 kB]
Get:96 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libavfilter7 amd64 7:4.4.2-0ubuntu0.22.04.1 [1496 kB]
Get:97 http://archive.ubuntu.com/ubuntu jammy/main amd64 libcaca0 amd64 0.99.beta19-2.2ubuntu4 [224 kB]
Get:98 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libcdio19 amd64 2.1.0-3ubuntu0.2 [63.6 kB]
Get:99 http://archive.ubuntu.com/ubuntu jammy/main amd64 libcdio-cdda2 amd64 10.2+2.0.0-1build3 [16.7 kB]
Get:100 http://archive.ubuntu.com/ubuntu jammy/main amd64 libcdio-paranoia2 amd64 10.2+2.0.0-1build3 [15.9 kB]
Get:101 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libdc1394-25 amd64 2.2.6-4 [88.8 kB]
Get:102 http://archive.ubuntu.com/ubuntu jammy/main amd64 libglvnd0 amd64 1.4.0-1 [73.6 kB]
Get:103 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libglapi-mesa amd64 23.2.1-1ubuntu3.1~22.04.2 [37.1 kB]
Get:104 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-dri2-0 amd64 1.14-3ubuntu3 [7206 B]
Get:105 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-dri3-0 amd64 1.14-3ubuntu3 [6968 B]
Get:106 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-glx0 amd64 1.14-3ubuntu3 [25.9 kB]
Get:107 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-present0 amd64 1.14-3ubuntu3 [5734 B]
Get:108 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-randr0 amd64 1.14-3ubuntu3 [18.3 kB]
Get:109 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-sync1 amd64 1.14-3ubuntu3 [9416 B]
Get:110 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-xfixes0 amd64 1.14-3ubuntu3 [9996 B]
Get:111 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxshmfence1 amd64 1.3-1build4 [5394 B]
Get:112 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxxf86vm1 amd64 1:1.1.4-1build3 [10.4 kB]
Get:113 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libdrm-amdgpu1 amd64 2.4.113-2~ubuntu0.22.04.1 [19.9 kB]
Get:114 http://archive.ubuntu.com/ubuntu jammy/main amd64 libpciaccess0 amd64 0.16-3 [19.1 kB]
Get:115 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libdrm-intel1 amd64 2.4.113-2~ubuntu0.22.04.1 [66.7 kB]
Get:116 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libdrm-nouveau2 amd64 2.4.113-2~ubuntu0.22.04.1 [17.5 kB]
Get:117 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libdrm-radeon1 amd64 2.4.113-2~ubuntu0.22.04.1 [21.6 kB]
Get:118 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libllvm15 amd64 1:15.0.7-0ubuntu0.22.04.3 [25.4 MB]
Get:119 http://archive.ubuntu.com/ubuntu jammy/main amd64 libsensors-config all 1:3.6.0-7ubuntu1 [5274 B]
Get:120 http://archive.ubuntu.com/ubuntu jammy/main amd64 libsensors5 amd64 1:3.6.0-7ubuntu1 [26.3 kB]
Get:121 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgl1-mesa-dri amd64 23.2.1-1ubuntu3.1~22.04.2 [8860 kB]
Get:122 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libglx-mesa0 amd64 23.2.1-1ubuntu3.1~22.04.2 [158 kB]
Get:123 http://archive.ubuntu.com/ubuntu jammy/main amd64 libglx0 amd64 1.4.0-1 [41.0 kB]
Get:124 http://archive.ubuntu.com/ubuntu jammy/main amd64 libgl1 amd64 1.4.0-1 [110 kB]
Get:125 http://archive.ubuntu.com/ubuntu jammy/main amd64 libiec61883-0 amd64 1.2.0-4build3 [25.9 kB]
Get:126 http://archive.ubuntu.com/ubuntu jammy/main amd64 libjack-jackd2-0 amd64 1.9.20~dfsg-1 [293 kB]
Get:127 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libopenal-data all 1:1.19.1-2build3 [164 kB]
Get:128 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libsndio7.0 amd64 1.8.1-1.1 [29.3 kB]
Get:129 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libopenal1 amd64 1:1.19.1-2build3 [535 kB]
Get:130 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libwayland-client0 amd64 1.20.0-1ubuntu0.1 [25.9 kB]
Get:131 http://archive.ubuntu.com/ubuntu jammy/main amd64 libdecor-0-0 amd64 0.1.0-3build1 [15.1 kB]
Get:132 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libwayland-server0 amd64 1.20.0-1ubuntu0.1 [34.3 kB]
Get:133 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgbm1 amd64 23.2.1-1ubuntu3.1~22.04.2 [33.5 kB]
Get:134 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libwayland-cursor0 amd64 1.20.0-1ubuntu0.1 [10.7 kB]
Get:135 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libwayland-egl1 amd64 1.20.0-1ubuntu0.1 [5582 B]
Get:136 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcursor1 amd64 1:1.2.0-2build4 [20.9 kB]
Get:137 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxi6 amd64 2:1.8-1build1 [32.6 kB]
Get:138 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxinerama1 amd64 2:1.1.4-3 [7382 B]
Get:139 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxkbcommon0 amd64 1.4.0-1 [125 kB]
Get:140 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxrandr2 amd64 2:1.5.2-1build1 [20.4 kB]
Get:141 http://archive.ubuntu.com/ubuntu jammy/main amd64 x11-common all 1:7.7+23ubuntu2 [23.4 kB]
Get:142 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxss1 amd64 1:1.2.3-1build2 [8476 B]
Get:143 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libsdl2-2.0-0 amd64 2.0.20+dfsg-2ubuntu1.22.04.1 [582 kB]
Get:144 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-shape0 amd64 1.14-3ubuntu3 [6158 B]
Get:145 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxv1 amd64 2:1.0.11-1build2 [11.2 kB]
Get:146 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libavdevice58 amd64 7:4.4.2-0ubuntu0.22.04.1 [87.5 kB]
Get:147 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 ffmpeg amd64 7:4.4.2-0ubuntu0.22.04.1 [1696 kB]
Get:148 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libigdgmm12 amd64 22.1.2+ds1-1 [139 kB]
Get:149 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 intel-media-va-driver amd64 22.3.1+dfsg1-1ubuntu2 [2283 kB]
Get:150 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libaacs0 amd64 0.11.1-1 [64.1 kB]
Get:151 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libbdplus0 amd64 0.2.0-1 [52.2 kB]
Get:152 http://archive.ubuntu.com/ubuntu jammy/main amd64 libdecor-0-plugin-1-cairo amd64 0.1.0-3build1 [20.4 kB]
Get:153 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgdk-pixbuf2.0-bin amd64 2.42.8+dfsg-1ubuntu0.3 [14.2 kB]
Get:154 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgl1-amber-dri amd64 21.3.9-0ubuntu1~22.04.1 [4218 kB]
Get:155 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 librsvg2-common amd64 2.52.5+dfsg-3ubuntu0.2 [17.7 kB]
Get:156 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 mesa-va-drivers amd64 23.2.1-1ubuntu3.1~22.04.2 [4100 kB]
Get:157 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 mesa-vdpau-drivers amd64 23.2.1-1ubuntu3.1~22.04.2 [3820 kB]
Get:158 http://archive.ubuntu.com/ubuntu jammy/universe amd64 i965-va-driver amd64 2.4.1+dfsg1-1 [302 kB]
Get:159 http://archive.ubuntu.com/ubuntu jammy/universe amd64 va-driver-all amd64 2.14.0-1 [3984 B]
Get:160 http://archive.ubuntu.com/ubuntu jammy/main amd64 vdpau-driver-all amd64 1.4-3build2 [4510 B]
Get:161 http://archive.ubuntu.com/ubuntu jammy/universe amd64 pocketsphinx-en-us all 0.8.0+real5prealpha+1-14ubuntu1 [27.6 MB]
Fetched 138 MB in 18s (7561 kB/s)
Extracting templates from packages: 100%
Selecting previously unselected package alsa-topology-conf.
(Reading database ... 32407 files and directories currently installed.)
Preparing to unpack .../000-alsa-topology-conf_1.2.5.1-2_all.deb ...
Unpacking alsa-topology-conf (1.2.5.1-2) ...
Selecting previously unselected package libasound2-data.
Preparing to unpack .../001-libasound2-data_1.2.6.1-1ubuntu1_all.deb ...
Unpacking libasound2-data (1.2.6.1-1ubuntu1) ...
Selecting previously unselected package libasound2:amd64.
Preparing to unpack .../002-libasound2_1.2.6.1-1ubuntu1_amd64.deb ...
Unpacking libasound2:amd64 (1.2.6.1-1ubuntu1) ...
Selecting previously unselected package alsa-ucm-conf.
Preparing to unpack .../003-alsa-ucm-conf_1.2.6.3-1ubuntu1.11_all.deb ...
Unpacking alsa-ucm-conf (1.2.6.3-1ubuntu1.11) ...
Selecting previously unselected package libaom3:amd64.
Preparing to unpack .../004-libaom3_3.3.0-1_amd64.deb ...
Unpacking libaom3:amd64 (3.3.0-1) ...
Selecting previously unselected package libva2:amd64.
Preparing to unpack .../005-libva2_2.14.0-1_amd64.deb ...
Unpacking libva2:amd64 (2.14.0-1) ...
Selecting previously unselected package libmfx1:amd64.
Preparing to unpack .../006-libmfx1_22.3.0-1_amd64.deb ...
Unpacking libmfx1:amd64 (22.3.0-1) ...
Selecting previously unselected package libva-drm2:amd64.
Preparing to unpack .../007-libva-drm2_2.14.0-1_amd64.deb ...
Unpacking libva-drm2:amd64 (2.14.0-1) ...
Selecting previously unselected package libxfixes3:amd64.
Preparing to unpack .../008-libxfixes3_1%3a6.0.0-1_amd64.deb ...
Unpacking libxfixes3:amd64 (1:6.0.0-1) ...
Selecting previously unselected package libva-x11-2:amd64.
Preparing to unpack .../009-libva-x11-2_2.14.0-1_amd64.deb ...
Unpacking libva-x11-2:amd64 (2.14.0-1) ...
Selecting previously unselected package libvdpau1:amd64.
Preparing to unpack .../010-libvdpau1_1.4-3build2_amd64.deb ...
Unpacking libvdpau1:amd64 (1.4-3build2) ...
Selecting previously unselected package ocl-icd-libopencl1:amd64.
Preparing to unpack .../011-ocl-icd-libopencl1_2.2.14-3_amd64.deb ...
Unpacking ocl-icd-libopencl1:amd64 (2.2.14-3) ...
Selecting previously unselected package libavutil56:amd64.
Preparing to unpack .../012-libavutil56_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libavutil56:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libpixman-1-0:amd64.
Preparing to unpack .../013-libpixman-1-0_0.40.0-1ubuntu0.22.04.1_amd64.deb ...
Unpacking libpixman-1-0:amd64 (0.40.0-1ubuntu0.22.04.1) ...
Selecting previously unselected package libxcb-render0:amd64.
Preparing to unpack .../014-libxcb-render0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-render0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxcb-shm0:amd64.
Preparing to unpack .../015-libxcb-shm0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-shm0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxrender1:amd64.
Preparing to unpack .../016-libxrender1_1%3a0.9.10-1build4_amd64.deb ...
Unpacking libxrender1:amd64 (1:0.9.10-1build4) ...
Selecting previously unselected package libcairo2:amd64.
Preparing to unpack .../017-libcairo2_1.16.0-5ubuntu2_amd64.deb ...
Unpacking libcairo2:amd64 (1.16.0-5ubuntu2) ...
Selecting previously unselected package libcodec2-1.0:amd64.
Preparing to unpack .../018-libcodec2-1.0_1.0.1-3_amd64.deb ...
Unpacking libcodec2-1.0:amd64 (1.0.1-3) ...
Selecting previously unselected package libdav1d5:amd64.
Preparing to unpack .../019-libdav1d5_0.9.2-1_amd64.deb ...
Unpacking libdav1d5:amd64 (0.9.2-1) ...
Selecting previously unselected package libgsm1:amd64.
Preparing to unpack .../020-libgsm1_1.0.19-1_amd64.deb ...
Unpacking libgsm1:amd64 (1.0.19-1) ...
Selecting previously unselected package libmp3lame0:amd64.
Preparing to unpack .../021-libmp3lame0_3.100-3build2_amd64.deb ...
Unpacking libmp3lame0:amd64 (3.100-3build2) ...
Selecting previously unselected package libopenjp2-7:amd64.
Preparing to unpack .../022-libopenjp2-7_2.4.0-6_amd64.deb ...
Unpacking libopenjp2-7:amd64 (2.4.0-6) ...
Selecting previously unselected package libopus0:amd64.
Preparing to unpack .../023-libopus0_1.3.1-0.1build2_amd64.deb ...
Unpacking libopus0:amd64 (1.3.1-0.1build2) ...
Selecting previously unselected package libcairo-gobject2:amd64.
Preparing to unpack .../024-libcairo-gobject2_1.16.0-5ubuntu2_amd64.deb ...
Unpacking libcairo-gobject2:amd64 (1.16.0-5ubuntu2) ...
Selecting previously unselected package libgdk-pixbuf2.0-common.
Preparing to unpack .../025-libgdk-pixbuf2.0-common_2.42.8+dfsg-1ubuntu0.3_all.deb ...
Unpacking libgdk-pixbuf2.0-common (2.42.8+dfsg-1ubuntu0.3) ...
Selecting previously unselected package libgdk-pixbuf-2.0-0:amd64.
Preparing to unpack .../026-libgdk-pixbuf-2.0-0_2.42.8+dfsg-1ubuntu0.3_amd64.deb ...
Unpacking libgdk-pixbuf-2.0-0:amd64 (2.42.8+dfsg-1ubuntu0.3) ...
Selecting previously unselected package fontconfig.
Preparing to unpack .../027-fontconfig_2.13.1-4.2ubuntu5_amd64.deb ...
Unpacking fontconfig (2.13.1-4.2ubuntu5) ...
Selecting previously unselected package libgraphite2-3:amd64.
Preparing to unpack .../028-libgraphite2-3_1.3.14-1build2_amd64.deb ...
Unpacking libgraphite2-3:amd64 (1.3.14-1build2) ...
Selecting previously unselected package libharfbuzz0b:amd64.
Preparing to unpack .../029-libharfbuzz0b_2.7.4-1ubuntu3.1_amd64.deb ...
Unpacking libharfbuzz0b:amd64 (2.7.4-1ubuntu3.1) ...
Selecting previously unselected package libthai-data.
Preparing to unpack .../030-libthai-data_0.1.29-1build1_all.deb ...
Unpacking libthai-data (0.1.29-1build1) ...
Selecting previously unselected package libdatrie1:amd64.
Preparing to unpack .../031-libdatrie1_0.2.13-2_amd64.deb ...
Unpacking libdatrie1:amd64 (0.2.13-2) ...
Selecting previously unselected package libthai0:amd64.
Preparing to unpack .../032-libthai0_0.1.29-1build1_amd64.deb ...
Unpacking libthai0:amd64 (0.1.29-1build1) ...
Selecting previously unselected package libpango-1.0-0:amd64.
Preparing to unpack .../033-libpango-1.0-0_1.50.6+ds-2ubuntu1_amd64.deb ...
Unpacking libpango-1.0-0:amd64 (1.50.6+ds-2ubuntu1) ...
Selecting previously unselected package libpangoft2-1.0-0:amd64.
Preparing to unpack .../034-libpangoft2-1.0-0_1.50.6+ds-2ubuntu1_amd64.deb ...
Unpacking libpangoft2-1.0-0:amd64 (1.50.6+ds-2ubuntu1) ...
Selecting previously unselected package libpangocairo-1.0-0:amd64.
Preparing to unpack .../035-libpangocairo-1.0-0_1.50.6+ds-2ubuntu1_amd64.deb ...
Unpacking libpangocairo-1.0-0:amd64 (1.50.6+ds-2ubuntu1) ...
Selecting previously unselected package librsvg2-2:amd64.
Preparing to unpack .../036-librsvg2-2_2.52.5+dfsg-3ubuntu0.2_amd64.deb ...
Unpacking librsvg2-2:amd64 (2.52.5+dfsg-3ubuntu0.2) ...
Selecting previously unselected package libshine3:amd64.
Preparing to unpack .../037-libshine3_3.1.1-2_amd64.deb ...
Unpacking libshine3:amd64 (3.1.1-2) ...
Selecting previously unselected package libsnappy1v5:amd64.
Preparing to unpack .../038-libsnappy1v5_1.1.8-1build3_amd64.deb ...
Unpacking libsnappy1v5:amd64 (1.1.8-1build3) ...
Selecting previously unselected package libspeex1:amd64.
Preparing to unpack .../039-libspeex1_1.2~rc1.2-1.1ubuntu3_amd64.deb ...
Unpacking libspeex1:amd64 (1.2~rc1.2-1.1ubuntu3) ...
Selecting previously unselected package libsoxr0:amd64.
Preparing to unpack .../040-libsoxr0_0.1.3-4build2_amd64.deb ...
Unpacking libsoxr0:amd64 (0.1.3-4build2) ...
Selecting previously unselected package libswresample3:amd64.
Preparing to unpack .../041-libswresample3_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libswresample3:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libogg0:amd64.
Preparing to unpack .../042-libogg0_1.3.5-0ubuntu3_amd64.deb ...
Unpacking libogg0:amd64 (1.3.5-0ubuntu3) ...
Selecting previously unselected package libtheora0:amd64.
Preparing to unpack .../043-libtheora0_1.1.1+dfsg.1-15ubuntu4_amd64.deb ...
Unpacking libtheora0:amd64 (1.1.1+dfsg.1-15ubuntu4) ...
Selecting previously unselected package libtwolame0:amd64.
Preparing to unpack .../044-libtwolame0_0.4.0-2build2_amd64.deb ...
Unpacking libtwolame0:amd64 (0.4.0-2build2) ...
Selecting previously unselected package libvorbis0a:amd64.
Preparing to unpack .../045-libvorbis0a_1.3.7-1build2_amd64.deb ...
Unpacking libvorbis0a:amd64 (1.3.7-1build2) ...
Selecting previously unselected package libvorbisenc2:amd64.
Preparing to unpack .../046-libvorbisenc2_1.3.7-1build2_amd64.deb ...
Unpacking libvorbisenc2:amd64 (1.3.7-1build2) ...
Selecting previously unselected package libvpx7:amd64.
Preparing to unpack .../047-libvpx7_1.11.0-2ubuntu2.3_amd64.deb ...
Unpacking libvpx7:amd64 (1.11.0-2ubuntu2.3) ...
Selecting previously unselected package libwebpmux3:amd64.
Preparing to unpack .../048-libwebpmux3_1.2.2-2ubuntu0.22.04.2_amd64.deb ...
Unpacking libwebpmux3:amd64 (1.2.2-2ubuntu0.22.04.2) ...
Selecting previously unselected package libx264-163:amd64.
Preparing to unpack .../049-libx264-163_2%3a0.163.3060+git5db6aa6-2build1_amd64.deb ...
Unpacking libx264-163:amd64 (2:0.163.3060+git5db6aa6-2build1) ...
Selecting previously unselected package libx265-199:amd64.
Preparing to unpack .../050-libx265-199_3.5-2_amd64.deb ...
Unpacking libx265-199:amd64 (3.5-2) ...
Selecting previously unselected package libxvidcore4:amd64.
Preparing to unpack .../051-libxvidcore4_2%3a1.3.7-1_amd64.deb ...
Unpacking libxvidcore4:amd64 (2:1.3.7-1) ...
Selecting previously unselected package libzvbi-common.
Preparing to unpack .../052-libzvbi-common_0.2.35-19_all.deb ...
Unpacking libzvbi-common (0.2.35-19) ...
Selecting previously unselected package libzvbi0:amd64.
Preparing to unpack .../053-libzvbi0_0.2.35-19_amd64.deb ...
Unpacking libzvbi0:amd64 (0.2.35-19) ...
Selecting previously unselected package libavcodec58:amd64.
Preparing to unpack .../054-libavcodec58_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libavcodec58:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libraw1394-11:amd64.
Preparing to unpack .../055-libraw1394-11_2.1.2-2build2_amd64.deb ...
Unpacking libraw1394-11:amd64 (2.1.2-2build2) ...
Selecting previously unselected package libavc1394-0:amd64.
Preparing to unpack .../056-libavc1394-0_0.5.4-5build2_amd64.deb ...
Unpacking libavc1394-0:amd64 (0.5.4-5build2) ...
Selecting previously unselected package libass9:amd64.
Preparing to unpack .../057-libass9_1%3a0.15.2-1_amd64.deb ...
Unpacking libass9:amd64 (1:0.15.2-1) ...
Selecting previously unselected package libudfread0:amd64.
Preparing to unpack .../058-libudfread0_1.1.2-1_amd64.deb ...
Unpacking libudfread0:amd64 (1.1.2-1) ...
Selecting previously unselected package libbluray2:amd64.
Preparing to unpack .../059-libbluray2_1%3a1.3.1-1_amd64.deb ...
Unpacking libbluray2:amd64 (1:1.3.1-1) ...
Selecting previously unselected package libchromaprint1:amd64.
Preparing to unpack .../060-libchromaprint1_1.5.1-2_amd64.deb ...
Unpacking libchromaprint1:amd64 (1.5.1-2) ...
Selecting previously unselected package libgme0:amd64.
Preparing to unpack .../061-libgme0_0.6.3-2_amd64.deb ...
Unpacking libgme0:amd64 (0.6.3-2) ...
Selecting previously unselected package libmpg123-0:amd64.
Preparing to unpack .../062-libmpg123-0_1.29.3-1build1_amd64.deb ...
Unpacking libmpg123-0:amd64 (1.29.3-1build1) ...
Selecting previously unselected package libvorbisfile3:amd64.
Preparing to unpack .../063-libvorbisfile3_1.3.7-1build2_amd64.deb ...
Unpacking libvorbisfile3:amd64 (1.3.7-1build2) ...
Selecting previously unselected package libopenmpt0:amd64.
Preparing to unpack .../064-libopenmpt0_0.6.1-1_amd64.deb ...
Unpacking libopenmpt0:amd64 (0.6.1-1) ...
Selecting previously unselected package librabbitmq4:amd64.
Preparing to unpack .../065-librabbitmq4_0.10.0-1ubuntu2_amd64.deb ...
Unpacking librabbitmq4:amd64 (0.10.0-1ubuntu2) ...
Selecting previously unselected package libsrt1.4-gnutls:amd64.
Preparing to unpack .../066-libsrt1.4-gnutls_1.4.4-4_amd64.deb ...
Unpacking libsrt1.4-gnutls:amd64 (1.4.4-4) ...
Selecting previously unselected package libssh-gcrypt-4:amd64.
Preparing to unpack .../067-libssh-gcrypt-4_0.9.6-2ubuntu0.22.04.3_amd64.deb ...
Unpacking libssh-gcrypt-4:amd64 (0.9.6-2ubuntu0.22.04.3) ...
Selecting previously unselected package libnorm1:amd64.
Preparing to unpack .../068-libnorm1_1.5.9+dfsg-2_amd64.deb ...
Unpacking libnorm1:amd64 (1.5.9+dfsg-2) ...
Selecting previously unselected package libpgm-5.3-0:amd64.
Preparing to unpack .../069-libpgm-5.3-0_5.3.128~dfsg-2_amd64.deb ...
Unpacking libpgm-5.3-0:amd64 (5.3.128~dfsg-2) ...
Selecting previously unselected package libzmq5:amd64.
Preparing to unpack .../070-libzmq5_4.3.4-2_amd64.deb ...
Unpacking libzmq5:amd64 (4.3.4-2) ...
Selecting previously unselected package libavformat58:amd64.
Preparing to unpack .../071-libavformat58_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libavformat58:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libbs2b0:amd64.
Preparing to unpack .../072-libbs2b0_3.1.0+dfsg-2.2build1_amd64.deb ...
Unpacking libbs2b0:amd64 (3.1.0+dfsg-2.2build1) ...
Selecting previously unselected package libflite1:amd64.
Preparing to unpack .../073-libflite1_2.2-3_amd64.deb ...
Unpacking libflite1:amd64 (2.2-3) ...
Selecting previously unselected package libserd-0-0:amd64.
Preparing to unpack .../074-libserd-0-0_0.30.10-2_amd64.deb ...
Unpacking libserd-0-0:amd64 (0.30.10-2) ...
Selecting previously unselected package libsord-0-0:amd64.
Preparing to unpack .../075-libsord-0-0_0.16.8-2_amd64.deb ...
Unpacking libsord-0-0:amd64 (0.16.8-2) ...
Selecting previously unselected package libsratom-0-0:amd64.
Preparing to unpack .../076-libsratom-0-0_0.6.8-1_amd64.deb ...
Unpacking libsratom-0-0:amd64 (0.6.8-1) ...
Selecting previously unselected package liblilv-0-0:amd64.
Preparing to unpack .../077-liblilv-0-0_0.24.12-2_amd64.deb ...
Unpacking liblilv-0-0:amd64 (0.24.12-2) ...
Selecting previously unselected package libmysofa1:amd64.
Preparing to unpack .../078-libmysofa1_1.2.1~dfsg0-1_amd64.deb ...
Unpacking libmysofa1:amd64 (1.2.1~dfsg0-1) ...
Selecting previously unselected package libblas3:amd64.
Preparing to unpack .../079-libblas3_3.10.0-2ubuntu1_amd64.deb ...
Unpacking libblas3:amd64 (3.10.0-2ubuntu1) ...
Selecting previously unselected package libgfortran5:amd64.
Preparing to unpack .../080-libgfortran5_12.3.0-1ubuntu1~22.04_amd64.deb ...
Unpacking libgfortran5:amd64 (12.3.0-1ubuntu1~22.04) ...
Selecting previously unselected package liblapack3:amd64.
Preparing to unpack .../081-liblapack3_3.10.0-2ubuntu1_amd64.deb ...
Unpacking liblapack3:amd64 (3.10.0-2ubuntu1) ...
Selecting previously unselected package libasyncns0:amd64.
Preparing to unpack .../082-libasyncns0_0.8-6build2_amd64.deb ...
Unpacking libasyncns0:amd64 (0.8-6build2) ...
Selecting previously unselected package libflac8:amd64.
Preparing to unpack .../083-libflac8_1.3.3-2ubuntu0.2_amd64.deb ...
Unpacking libflac8:amd64 (1.3.3-2ubuntu0.2) ...
Selecting previously unselected package libsndfile1:amd64.
Preparing to unpack .../084-libsndfile1_1.0.31-2ubuntu0.1_amd64.deb ...
Unpacking libsndfile1:amd64 (1.0.31-2ubuntu0.1) ...
Selecting previously unselected package libx11-xcb1:amd64.
Preparing to unpack .../085-libx11-xcb1_2%3a1.7.5-1ubuntu0.3_amd64.deb ...
Unpacking libx11-xcb1:amd64 (2:1.7.5-1ubuntu0.3) ...
Selecting previously unselected package libpulse0:amd64.
Preparing to unpack .../086-libpulse0_1%3a15.99.1+dfsg1-1ubuntu2.2_amd64.deb ...
Unpacking libpulse0:amd64 (1:15.99.1+dfsg1-1ubuntu2.2) ...
Selecting previously unselected package libsphinxbase3:amd64.
Preparing to unpack .../087-libsphinxbase3_0.8+5prealpha+1-13build1_amd64.deb ...
Unpacking libsphinxbase3:amd64 (0.8+5prealpha+1-13build1) ...
Selecting previously unselected package libpocketsphinx3:amd64.
Preparing to unpack .../088-libpocketsphinx3_0.8.0+real5prealpha+1-14ubuntu1_amd64.deb ...
Unpacking libpocketsphinx3:amd64 (0.8.0+real5prealpha+1-14ubuntu1) ...
Selecting previously unselected package libpostproc55:amd64.
Preparing to unpack .../089-libpostproc55_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libpostproc55:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libsamplerate0:amd64.
Preparing to unpack .../090-libsamplerate0_0.2.2-1build1_amd64.deb ...
Unpacking libsamplerate0:amd64 (0.2.2-1build1) ...
Selecting previously unselected package librubberband2:amd64.
Preparing to unpack .../091-librubberband2_2.0.0-2_amd64.deb ...
Unpacking librubberband2:amd64 (2.0.0-2) ...
Selecting previously unselected package libswscale5:amd64.
Preparing to unpack .../092-libswscale5_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libswscale5:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libvidstab1.1:amd64.
Preparing to unpack .../093-libvidstab1.1_1.1.0-2_amd64.deb ...
Unpacking libvidstab1.1:amd64 (1.1.0-2) ...
Selecting previously unselected package libzimg2:amd64.
Preparing to unpack .../094-libzimg2_3.0.3+ds1-1_amd64.deb ...
Unpacking libzimg2:amd64 (3.0.3+ds1-1) ...
Selecting previously unselected package libavfilter7:amd64.
Preparing to unpack .../095-libavfilter7_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libavfilter7:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libcaca0:amd64.
Preparing to unpack .../096-libcaca0_0.99.beta19-2.2ubuntu4_amd64.deb ...
Unpacking libcaca0:amd64 (0.99.beta19-2.2ubuntu4) ...
Selecting previously unselected package libcdio19:amd64.
Preparing to unpack .../097-libcdio19_2.1.0-3ubuntu0.2_amd64.deb ...
Unpacking libcdio19:amd64 (2.1.0-3ubuntu0.2) ...
Selecting previously unselected package libcdio-cdda2:amd64.
Preparing to unpack .../098-libcdio-cdda2_10.2+2.0.0-1build3_amd64.deb ...
Unpacking libcdio-cdda2:amd64 (10.2+2.0.0-1build3) ...
Selecting previously unselected package libcdio-paranoia2:amd64.
Preparing to unpack .../099-libcdio-paranoia2_10.2+2.0.0-1build3_amd64.deb ...
Unpacking libcdio-paranoia2:amd64 (10.2+2.0.0-1build3) ...
Selecting previously unselected package libdc1394-25:amd64.
Preparing to unpack .../100-libdc1394-25_2.2.6-4_amd64.deb ...
Unpacking libdc1394-25:amd64 (2.2.6-4) ...
Selecting previously unselected package libglvnd0:amd64.
Preparing to unpack .../101-libglvnd0_1.4.0-1_amd64.deb ...
Unpacking libglvnd0:amd64 (1.4.0-1) ...
Selecting previously unselected package libglapi-mesa:amd64.
Preparing to unpack .../102-libglapi-mesa_23.2.1-1ubuntu3.1~22.04.2_amd64.deb ...
Unpacking libglapi-mesa:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Selecting previously unselected package libxcb-dri2-0:amd64.
Preparing to unpack .../103-libxcb-dri2-0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-dri2-0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxcb-dri3-0:amd64.
Preparing to unpack .../104-libxcb-dri3-0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-dri3-0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxcb-glx0:amd64.
Preparing to unpack .../105-libxcb-glx0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-glx0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxcb-present0:amd64.
Preparing to unpack .../106-libxcb-present0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-present0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxcb-randr0:amd64.
Preparing to unpack .../107-libxcb-randr0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-randr0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxcb-sync1:amd64.
Preparing to unpack .../108-libxcb-sync1_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-sync1:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxcb-xfixes0:amd64.
Preparing to unpack .../109-libxcb-xfixes0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-xfixes0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxshmfence1:amd64.
Preparing to unpack .../110-libxshmfence1_1.3-1build4_amd64.deb ...
Unpacking libxshmfence1:amd64 (1.3-1build4) ...
Selecting previously unselected package libxxf86vm1:amd64.
Preparing to unpack .../111-libxxf86vm1_1%3a1.1.4-1build3_amd64.deb ...
Unpacking libxxf86vm1:amd64 (1:1.1.4-1build3) ...
Selecting previously unselected package libdrm-amdgpu1:amd64.
Preparing to unpack .../112-libdrm-amdgpu1_2.4.113-2~ubuntu0.22.04.1_amd64.deb ...
Unpacking libdrm-amdgpu1:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Selecting previously unselected package libpciaccess0:amd64.
Preparing to unpack .../113-libpciaccess0_0.16-3_amd64.deb ...
Unpacking libpciaccess0:amd64 (0.16-3) ...
Selecting previously unselected package libdrm-intel1:amd64.
Preparing to unpack .../114-libdrm-intel1_2.4.113-2~ubuntu0.22.04.1_amd64.deb ...
Unpacking libdrm-intel1:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Selecting previously unselected package libdrm-nouveau2:amd64.
Preparing to unpack .../115-libdrm-nouveau2_2.4.113-2~ubuntu0.22.04.1_amd64.deb ...
Unpacking libdrm-nouveau2:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Selecting previously unselected package libdrm-radeon1:amd64.
Preparing to unpack .../116-libdrm-radeon1_2.4.113-2~ubuntu0.22.04.1_amd64.deb ...
Unpacking libdrm-radeon1:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Selecting previously unselected package libllvm15:amd64.
Preparing to unpack .../117-libllvm15_1%3a15.0.7-0ubuntu0.22.04.3_amd64.deb ...
Unpacking libllvm15:amd64 (1:15.0.7-0ubuntu0.22.04.3) ...
Selecting previously unselected package libsensors-config.
Preparing to unpack .../118-libsensors-config_1%3a3.6.0-7ubuntu1_all.deb ...
Unpacking libsensors-config (1:3.6.0-7ubuntu1) ...
Selecting previously unselected package libsensors5:amd64.
Preparing to unpack .../119-libsensors5_1%3a3.6.0-7ubuntu1_amd64.deb ...
Unpacking libsensors5:amd64 (1:3.6.0-7ubuntu1) ...
Selecting previously unselected package libgl1-mesa-dri:amd64.
Preparing to unpack .../120-libgl1-mesa-dri_23.2.1-1ubuntu3.1~22.04.2_amd64.deb ...
Unpacking libgl1-mesa-dri:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Selecting previously unselected package libglx-mesa0:amd64.
Preparing to unpack .../121-libglx-mesa0_23.2.1-1ubuntu3.1~22.04.2_amd64.deb ...
Unpacking libglx-mesa0:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Selecting previously unselected package libglx0:amd64.
Preparing to unpack .../122-libglx0_1.4.0-1_amd64.deb ...
Unpacking libglx0:amd64 (1.4.0-1) ...
Selecting previously unselected package libgl1:amd64.
Preparing to unpack .../123-libgl1_1.4.0-1_amd64.deb ...
Unpacking libgl1:amd64 (1.4.0-1) ...
Selecting previously unselected package libiec61883-0:amd64.
Preparing to unpack .../124-libiec61883-0_1.2.0-4build3_amd64.deb ...
Unpacking libiec61883-0:amd64 (1.2.0-4build3) ...
Selecting previously unselected package libjack-jackd2-0:amd64.
Preparing to unpack .../125-libjack-jackd2-0_1.9.20~dfsg-1_amd64.deb ...
Unpacking libjack-jackd2-0:amd64 (1.9.20~dfsg-1) ...
Selecting previously unselected package libopenal-data.
Preparing to unpack .../126-libopenal-data_1%3a1.19.1-2build3_all.deb ...
Unpacking libopenal-data (1:1.19.1-2build3) ...
Selecting previously unselected package libsndio7.0:amd64.
Preparing to unpack .../127-libsndio7.0_1.8.1-1.1_amd64.deb ...
Unpacking libsndio7.0:amd64 (1.8.1-1.1) ...
Selecting previously unselected package libopenal1:amd64.
Preparing to unpack .../128-libopenal1_1%3a1.19.1-2build3_amd64.deb ...
Unpacking libopenal1:amd64 (1:1.19.1-2build3) ...
Selecting previously unselected package libwayland-client0:amd64.
Preparing to unpack .../129-libwayland-client0_1.20.0-1ubuntu0.1_amd64.deb ...
Unpacking libwayland-client0:amd64 (1.20.0-1ubuntu0.1) ...
Selecting previously unselected package libdecor-0-0:amd64.
Preparing to unpack .../130-libdecor-0-0_0.1.0-3build1_amd64.deb ...
Unpacking libdecor-0-0:amd64 (0.1.0-3build1) ...
Selecting previously unselected package libwayland-server0:amd64.
Preparing to unpack .../131-libwayland-server0_1.20.0-1ubuntu0.1_amd64.deb ...
Unpacking libwayland-server0:amd64 (1.20.0-1ubuntu0.1) ...
Selecting previously unselected package libgbm1:amd64.
Preparing to unpack .../132-libgbm1_23.2.1-1ubuntu3.1~22.04.2_amd64.deb ...
Unpacking libgbm1:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Selecting previously unselected package libwayland-cursor0:amd64.
Preparing to unpack .../133-libwayland-cursor0_1.20.0-1ubuntu0.1_amd64.deb ...
Unpacking libwayland-cursor0:amd64 (1.20.0-1ubuntu0.1) ...
Selecting previously unselected package libwayland-egl1:amd64.
Preparing to unpack .../134-libwayland-egl1_1.20.0-1ubuntu0.1_amd64.deb ...
Unpacking libwayland-egl1:amd64 (1.20.0-1ubuntu0.1) ...
Selecting previously unselected package libxcursor1:amd64.
Preparing to unpack .../135-libxcursor1_1%3a1.2.0-2build4_amd64.deb ...
Unpacking libxcursor1:amd64 (1:1.2.0-2build4) ...
Selecting previously unselected package libxi6:amd64.
Preparing to unpack .../136-libxi6_2%3a1.8-1build1_amd64.deb ...
Unpacking libxi6:amd64 (2:1.8-1build1) ...
Selecting previously unselected package libxinerama1:amd64.
Preparing to unpack .../137-libxinerama1_2%3a1.1.4-3_amd64.deb ...
Unpacking libxinerama1:amd64 (2:1.1.4-3) ...
Selecting previously unselected package libxkbcommon0:amd64.
Preparing to unpack .../138-libxkbcommon0_1.4.0-1_amd64.deb ...
Unpacking libxkbcommon0:amd64 (1.4.0-1) ...
Selecting previously unselected package libxrandr2:amd64.
Preparing to unpack .../139-libxrandr2_2%3a1.5.2-1build1_amd64.deb ...
Unpacking libxrandr2:amd64 (2:1.5.2-1build1) ...
Selecting previously unselected package x11-common.
Preparing to unpack .../140-x11-common_1%3a7.7+23ubuntu2_all.deb ...
Unpacking x11-common (1:7.7+23ubuntu2) ...
Selecting previously unselected package libxss1:amd64.
Preparing to unpack .../141-libxss1_1%3a1.2.3-1build2_amd64.deb ...
Unpacking libxss1:amd64 (1:1.2.3-1build2) ...
Selecting previously unselected package libsdl2-2.0-0:amd64.
Preparing to unpack .../142-libsdl2-2.0-0_2.0.20+dfsg-2ubuntu1.22.04.1_amd64.deb ...
Unpacking libsdl2-2.0-0:amd64 (2.0.20+dfsg-2ubuntu1.22.04.1) ...
Selecting previously unselected package libxcb-shape0:amd64.
Preparing to unpack .../143-libxcb-shape0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-shape0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxv1:amd64.
Preparing to unpack .../144-libxv1_2%3a1.0.11-1build2_amd64.deb ...
Unpacking libxv1:amd64 (2:1.0.11-1build2) ...
Selecting previously unselected package libavdevice58:amd64.
Preparing to unpack .../145-libavdevice58_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libavdevice58:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package ffmpeg.
Preparing to unpack .../146-ffmpeg_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking ffmpeg (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libigdgmm12:amd64.
Preparing to unpack .../147-libigdgmm12_22.1.2+ds1-1_amd64.deb ...
Unpacking libigdgmm12:amd64 (22.1.2+ds1-1) ...
Selecting previously unselected package intel-media-va-driver:amd64.
Preparing to unpack .../148-intel-media-va-driver_22.3.1+dfsg1-1ubuntu2_amd64.deb ...
Unpacking intel-media-va-driver:amd64 (22.3.1+dfsg1-1ubuntu2) ...
Selecting previously unselected package libaacs0:amd64.
Preparing to unpack .../149-libaacs0_0.11.1-1_amd64.deb ...
Unpacking libaacs0:amd64 (0.11.1-1) ...
Selecting previously unselected package libbdplus0:amd64.
Preparing to unpack .../150-libbdplus0_0.2.0-1_amd64.deb ...
Unpacking libbdplus0:amd64 (0.2.0-1) ...
Selecting previously unselected package libdecor-0-plugin-1-cairo:amd64.
Preparing to unpack .../151-libdecor-0-plugin-1-cairo_0.1.0-3build1_amd64.deb ...
Unpacking libdecor-0-plugin-1-cairo:amd64 (0.1.0-3build1) ...
Selecting previously unselected package libgdk-pixbuf2.0-bin.
Preparing to unpack .../152-libgdk-pixbuf2.0-bin_2.42.8+dfsg-1ubuntu0.3_amd64.deb ...
Unpacking libgdk-pixbuf2.0-bin (2.42.8+dfsg-1ubuntu0.3) ...
Selecting previously unselected package libgl1-amber-dri:amd64.
Preparing to unpack .../153-libgl1-amber-dri_21.3.9-0ubuntu1~22.04.1_amd64.deb ...
Unpacking libgl1-amber-dri:amd64 (21.3.9-0ubuntu1~22.04.1) ...
Selecting previously unselected package librsvg2-common:amd64.
Preparing to unpack .../154-librsvg2-common_2.52.5+dfsg-3ubuntu0.2_amd64.deb ...
Unpacking librsvg2-common:amd64 (2.52.5+dfsg-3ubuntu0.2) ...
Selecting previously unselected package mesa-va-drivers:amd64.
Preparing to unpack .../155-mesa-va-drivers_23.2.1-1ubuntu3.1~22.04.2_amd64.deb ...
Unpacking mesa-va-drivers:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Selecting previously unselected package mesa-vdpau-drivers:amd64.
Preparing to unpack .../156-mesa-vdpau-drivers_23.2.1-1ubuntu3.1~22.04.2_amd64.deb ...
Unpacking mesa-vdpau-drivers:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Selecting previously unselected package i965-va-driver:amd64.
Preparing to unpack .../157-i965-va-driver_2.4.1+dfsg1-1_amd64.deb ...
Unpacking i965-va-driver:amd64 (2.4.1+dfsg1-1) ...
Selecting previously unselected package va-driver-all:amd64.
Preparing to unpack .../158-va-driver-all_2.14.0-1_amd64.deb ...
Unpacking va-driver-all:amd64 (2.14.0-1) ...
Selecting previously unselected package vdpau-driver-all:amd64.
Preparing to unpack .../159-vdpau-driver-all_1.4-3build2_amd64.deb ...
Unpacking vdpau-driver-all:amd64 (1.4-3build2) ...
Selecting previously unselected package pocketsphinx-en-us.
Preparing to unpack .../160-pocketsphinx-en-us_0.8.0+real5prealpha+1-14ubuntu1_all.deb ...
Unpacking pocketsphinx-en-us (0.8.0+real5prealpha+1-14ubuntu1) ...
Setting up libgme0:amd64 (0.6.3-2) ...
Setting up libssh-gcrypt-4:amd64 (0.9.6-2ubuntu0.22.04.3) ...
Setting up libgraphite2-3:amd64 (1.3.14-1build2) ...
Setting up libsrt1.4-gnutls:amd64 (1.4.4-4) ...
Setting up libxcb-dri3-0:amd64 (1.14-3ubuntu3) ...
Setting up libpixman-1-0:amd64 (0.40.0-1ubuntu0.22.04.1) ...
Setting up libudfread0:amd64 (1.1.2-1) ...
Setting up libwayland-server0:amd64 (1.20.0-1ubuntu0.1) ...
Setting up libaom3:amd64 (3.3.0-1) ...
Setting up libx11-xcb1:amd64 (2:1.7.5-1ubuntu0.3) ...
Setting up libpciaccess0:amd64 (0.16-3) ...
Setting up fontconfig (2.13.1-4.2ubuntu5) ...
Regenerating fonts cache... done.
Setting up librabbitmq4:amd64 (0.10.0-1ubuntu2) ...
Setting up libraw1394-11:amd64 (2.1.2-2build2) ...
Setting up libdrm-nouveau2:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Setting up libcodec2-1.0:amd64 (1.0.1-3) ...
Setting up libmpg123-0:amd64 (1.29.3-1build1) ...
Setting up libxcb-xfixes0:amd64 (1.14-3ubuntu3) ...
Setting up libogg0:amd64 (1.3.5-0ubuntu3) ...
Setting up libspeex1:amd64 (1.2~rc1.2-1.1ubuntu3) ...
Setting up libshine3:amd64 (3.1.1-2) ...
Setting up libcaca0:amd64 (0.99.beta19-2.2ubuntu4) ...
Setting up libxi6:amd64 (2:1.8-1build1) ...
Setting up libtwolame0:amd64 (0.4.0-2build2) ...
Setting up libxrender1:amd64 (1:0.9.10-1build4) ...
Setting up libdatrie1:amd64 (0.2.13-2) ...
Setting up libgsm1:amd64 (1.0.19-1) ...
Setting up libxcb-render0:amd64 (1.14-3ubuntu3) ...
Setting up libsoxr0:amd64 (0.1.3-4build2) ...
Setting up libdrm-radeon1:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Setting up libglvnd0:amd64 (1.4.0-1) ...
Setting up libpgm-5.3-0:amd64 (5.3.128~dfsg-2) ...
Setting up libxcb-glx0:amd64 (1.14-3ubuntu3) ...
Setting up libdrm-intel1:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Setting up libgdk-pixbuf2.0-common (2.42.8+dfsg-1ubuntu0.3) ...
Setting up libnorm1:amd64 (1.5.9+dfsg-2) ...
Setting up libmysofa1:amd64 (1.2.1~dfsg0-1) ...
Setting up libxcb-shape0:amd64 (1.14-3ubuntu3) ...
Setting up x11-common (1:7.7+23ubuntu2) ...
Setting up libsensors-config (1:3.6.0-7ubuntu1) ...
Setting up libxcb-shm0:amd64 (1.14-3ubuntu3) ...
Setting up libigdgmm12:amd64 (22.1.2+ds1-1) ...
Setting up libcdio19:amd64 (2.1.0-3ubuntu0.2) ...
Setting up libxvidcore4:amd64 (2:1.3.7-1) ...
Setting up libcairo2:amd64 (1.16.0-5ubuntu2) ...
Setting up libxxf86vm1:amd64 (1:1.1.4-1build3) ...
Setting up libsnappy1v5:amd64 (1.1.8-1build3) ...
Setting up libflac8:amd64 (1.3.3-2ubuntu0.2) ...
Setting up libxcb-present0:amd64 (1.14-3ubuntu3) ...
Setting up libasound2-data (1.2.6.1-1ubuntu1) ...
Setting up libblas3:amd64 (3.10.0-2ubuntu1) ...
update-alternatives: using /usr/lib/x86_64-linux-gnu/blas/libblas.so.3 to provide /usr/lib/x86_64-linux-gnu/libblas.so.3 (libblas.so.3-x86_64-linux-gnu) in auto mode
Setting up libva2:amd64 (2.14.0-1) ...
Setting up libxfixes3:amd64 (1:6.0.0-1) ...
Setting up libxcb-sync1:amd64 (1.14-3ubuntu3) ...
Setting up libx264-163:amd64 (2:0.163.3060+git5db6aa6-2build1) ...
Setting up libopus0:amd64 (1.3.1-0.1build2) ...
Setting up libxinerama1:amd64 (2:1.1.4-3) ...
Setting up libdc1394-25:amd64 (2.2.6-4) ...
Setting up intel-media-va-driver:amd64 (22.3.1+dfsg1-1ubuntu2) ...
Setting up libxv1:amd64 (2:1.0.11-1build2) ...
Setting up libvorbis0a:amd64 (1.3.7-1build2) ...
Setting up libxrandr2:amd64 (2:1.5.2-1build1) ...
Setting up libsensors5:amd64 (1:3.6.0-7ubuntu1) ...
Setting up libaacs0:amd64 (0.11.1-1) ...
Setting up pocketsphinx-en-us (0.8.0+real5prealpha+1-14ubuntu1) ...
Setting up libglapi-mesa:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Setting up libgfortran5:amd64 (12.3.0-1ubuntu1~22.04) ...
Setting up libx265-199:amd64 (3.5-2) ...
Setting up libxcb-dri2-0:amd64 (1.14-3ubuntu3) ...
Setting up libbdplus0:amd64 (0.2.0-1) ...
Setting up libvidstab1.1:amd64 (1.1.0-2) ...
Setting up alsa-topology-conf (1.2.5.1-2) ...
Setting up libva-drm2:amd64 (2.14.0-1) ...
Setting up ocl-icd-libopencl1:amd64 (2.2.14-3) ...
Setting up libasyncns0:amd64 (0.8-6build2) ...
Setting up libxshmfence1:amd64 (1.3-1build4) ...
Setting up libvdpau1:amd64 (1.4-3build2) ...
Setting up libbs2b0:amd64 (3.1.0+dfsg-2.2build1) ...
Setting up libxcb-randr0:amd64 (1.14-3ubuntu3) ...
Setting up libllvm15:amd64 (1:15.0.7-0ubuntu0.22.04.3) ...
Setting up libtheora0:amd64 (1.1.1+dfsg.1-15ubuntu4) ...
Setting up libasound2:amd64 (1.2.6.1-1ubuntu1) ...
Setting up libzimg2:amd64 (3.0.3+ds1-1) ...
Setting up libopenjp2-7:amd64 (2.4.0-6) ...
Setting up libharfbuzz0b:amd64 (2.7.4-1ubuntu3.1) ...
Setting up libopenal-data (1:1.19.1-2build3) ...
Setting up libthai-data (0.1.29-1build1) ...
Setting up libgdk-pixbuf-2.0-0:amd64 (2.42.8+dfsg-1ubuntu0.3) ...
Setting up libvpx7:amd64 (1.11.0-2ubuntu2.3) ...
Setting up libcairo-gobject2:amd64 (1.16.0-5ubuntu2) ...
Setting up libwayland-egl1:amd64 (1.20.0-1ubuntu0.1) ...
Setting up libxss1:amd64 (1:1.2.3-1build2) ...
Setting up libdav1d5:amd64 (0.9.2-1) ...
Setting up libmfx1:amd64 (22.3.0-1) ...
Setting up libbluray2:amd64 (1:1.3.1-1) ...
Setting up libsamplerate0:amd64 (0.2.2-1build1) ...
Setting up libva-x11-2:amd64 (2.14.0-1) ...
Setting up libwebpmux3:amd64 (1.2.2-2ubuntu0.22.04.2) ...
Setting up libzvbi-common (0.2.35-19) ...
Setting up libmp3lame0:amd64 (3.100-3build2) ...
Setting up i965-va-driver:amd64 (2.4.1+dfsg1-1) ...
Setting up libvorbisenc2:amd64 (1.3.7-1build2) ...
Setting up libiec61883-0:amd64 (1.2.0-4build3) ...
Setting up libserd-0-0:amd64 (0.30.10-2) ...
Setting up libdrm-amdgpu1:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Setting up libxkbcommon0:amd64 (1.4.0-1) ...
Setting up libwayland-client0:amd64 (1.20.0-1ubuntu0.1) ...
Setting up libavc1394-0:amd64 (0.5.4-5build2) ...
Setting up libgl1-amber-dri:amd64 (21.3.9-0ubuntu1~22.04.1) ...
Setting up mesa-vdpau-drivers:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Setting up libzvbi0:amd64 (0.2.35-19) ...
Setting up liblapack3:amd64 (3.10.0-2ubuntu1) ...
update-alternatives: using /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3 to provide /usr/lib/x86_64-linux-gnu/liblapack.so.3 (liblapack.so.3-x86_64-linux-gnu) in auto mode
Setting up libzmq5:amd64 (4.3.4-2) ...
Setting up libgbm1:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Setting up alsa-ucm-conf (1.2.6.3-1ubuntu1.11) ...
Setting up libcdio-cdda2:amd64 (10.2+2.0.0-1build3) ...
Setting up libcdio-paranoia2:amd64 (10.2+2.0.0-1build3) ...
Setting up libxcursor1:amd64 (1:1.2.0-2build4) ...
Setting up libgl1-mesa-dri:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Setting up libavutil56:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up libthai0:amd64 (0.1.29-1build1) ...
Setting up libvorbisfile3:amd64 (1.3.7-1build2) ...
Setting up libass9:amd64 (1:0.15.2-1) ...
Setting up libpostproc55:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up librubberband2:amd64 (2.0.0-2) ...
Setting up libsndio7.0:amd64 (1.8.1-1.1) ...
Setting up libjack-jackd2-0:amd64 (1.9.20~dfsg-1) ...
Setting up vdpau-driver-all:amd64 (1.4-3build2) ...
Setting up libflite1:amd64 (2.2-3) ...
Setting up libgdk-pixbuf2.0-bin (2.42.8+dfsg-1ubuntu0.3) ...
Setting up libsord-0-0:amd64 (0.16.8-2) ...
Setting up libwayland-cursor0:amd64 (1.20.0-1ubuntu0.1) ...
Setting up libsratom-0-0:amd64 (0.6.8-1) ...
Setting up libdecor-0-0:amd64 (0.1.0-3build1) ...
Setting up libswscale5:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up libsndfile1:amd64 (1.0.31-2ubuntu0.1) ...
Setting up mesa-va-drivers:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Setting up liblilv-0-0:amd64 (0.24.12-2) ...
Setting up libopenmpt0:amd64 (0.6.1-1) ...
Setting up libglx-mesa0:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Setting up libglx0:amd64 (1.4.0-1) ...
Setting up libpulse0:amd64 (1:15.99.1+dfsg1-1ubuntu2.2) ...
Setting up libpango-1.0-0:amd64 (1.50.6+ds-2ubuntu1) ...
Setting up libopenal1:amd64 (1:1.19.1-2build3) ...
Setting up libswresample3:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up libgl1:amd64 (1.4.0-1) ...
Setting up va-driver-all:amd64 (2.14.0-1) ...
Setting up libpangoft2-1.0-0:amd64 (1.50.6+ds-2ubuntu1) ...
Setting up libsdl2-2.0-0:amd64 (2.0.20+dfsg-2ubuntu1.22.04.1) ...
Setting up libpangocairo-1.0-0:amd64 (1.50.6+ds-2ubuntu1) ...
Setting up libsphinxbase3:amd64 (0.8+5prealpha+1-13build1) ...
Setting up librsvg2-2:amd64 (2.52.5+dfsg-3ubuntu0.2) ...
Setting up libpocketsphinx3:amd64 (0.8.0+real5prealpha+1-14ubuntu1) ...
Setting up libdecor-0-plugin-1-cairo:amd64 (0.1.0-3build1) ...
Setting up librsvg2-common:amd64 (2.52.5+dfsg-3ubuntu0.2) ...
Setting up libavcodec58:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up libchromaprint1:amd64 (1.5.1-2) ...
Setting up libavformat58:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up libavfilter7:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up libavdevice58:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up ffmpeg (7:4.4.2-0ubuntu0.22.04.1) ...
Processing triggers for man-db (2.10.2-1) ...
Processing triggers for libc-bin (2.35-0ubuntu3.8) ...
Processing triggers for libgdk-pixbuf-2.0-0:amd64 (2.42.8+dfsg-1ubuntu0.3) ...
root@FelippeBarcelos:~# hass
Command 'hass' not found, did you mean:
  command 'cass' from snap cass (0.17.2)
  command 'sass' from deb ruby-sass (3.7.4-5)
  command 'ass' from deb irpas (0.10-9)
  command 'pass' from deb pass (1.7.4-5)
See 'snap info <snapname>' for additional versions.
root@FelippeBarcelos:~#

---

### ASSISTENTE

Parece que você tentou executar o comando `hass`, mas ele não foi encontrado no seu sistema. O comando `hass` geralmente se refere ao Home Assistant, uma plataforma de automação residencial de código aberto.

Para instalar o Home Assistant, você pode seguir estas etapas:

1. **Instalação usando o Docker (recomendado para a maioria dos usuários):**
   - Primeiro, certifique-se de que o Docker esteja instalado em seu sistema:
     ```bash
     sudo apt install docker.io -y
     ```
   - Depois, execute o seguinte comando para baixar e executar o Home Assistant:
     ```bash
     docker run -d --name="home-assistant" -v /PATH/TO/YOUR/CONFIG:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
     ```
     Substitua `/PATH/TO/YOUR/CONFIG` pelo caminho do seu diretório de configuração e `YOUR_TIMEZONE` pelo seu fuso horário (por exemplo, `America/Sao_Paulo`).

2. **Instalação no ambiente Python:**
   - Instale o Python e o pip, se ainda não estiverem instalados:
     ```bash
     sudo apt install python3 python3-pip -y
     ```
   - Instale o Home Assistant usando o pip:
     ```bash
     pip3 install homeassistant
     ```
   - Depois de instalado, você pode iniciar o Home Assistant com:
     ```bash
     hass
     ```

Certifique-se de substituir os comandos conforme necessário para o seu ambiente e preferências. Se precisar de mais alguma ajuda com o processo, estou aqui para ajudar!

---

### USUÁRIO

Acabei não substituindo /PATH/TO/YOUR/CONFIG pelo caminho do seu diretório de configuração e YOUR_TIMEZONE pelo seu fuso horário (por exemplo, America/Sao_Paulo), e apenas enviei o comando, como prossigo se cometi esse erro e agora terminou de completar:
"root@FelippeBarcelos:~# sudo apt install ffmpeg -y
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  alsa-topology-conf alsa-ucm-conf fontconfig i965-va-driver intel-media-va-driver libaacs0 libaom3
  libasound2 libasound2-data libass9 libasyncns0 libavc1394-0 libavcodec58 libavdevice58 libavfilter7
  libavformat58 libavutil56 libbdplus0 libblas3 libbluray2 libbs2b0 libcaca0 libcairo-gobject2 libcairo2
  libcdio-cdda2 libcdio-paranoia2 libcdio19 libchromaprint1 libcodec2-1.0 libdatrie1 libdav1d5
  libdc1394-25 libdecor-0-0 libdecor-0-plugin-1-cairo libdrm-amdgpu1 libdrm-intel1 libdrm-nouveau2
  libdrm-radeon1 libflac8 libflite1 libgbm1 libgdk-pixbuf-2.0-0 libgdk-pixbuf2.0-bin
  libgdk-pixbuf2.0-common libgfortran5 libgl1 libgl1-amber-dri libgl1-mesa-dri libglapi-mesa libglvnd0
  libglx-mesa0 libglx0 libgme0 libgraphite2-3 libgsm1 libharfbuzz0b libiec61883-0 libigdgmm12
  libjack-jackd2-0 liblapack3 liblilv-0-0 libllvm15 libmfx1 libmp3lame0 libmpg123-0 libmysofa1 libnorm1
  libogg0 libopenal-data libopenal1 libopenjp2-7 libopenmpt0 libopus0 libpango-1.0-0 libpangocairo-1.0-0
  libpangoft2-1.0-0 libpciaccess0 libpgm-5.3-0 libpixman-1-0 libpocketsphinx3 libpostproc55 libpulse0
  librabbitmq4 libraw1394-11 librsvg2-2 librsvg2-common librubberband2 libsamplerate0 libsdl2-2.0-0
  libsensors-config libsensors5 libserd-0-0 libshine3 libsnappy1v5 libsndfile1 libsndio7.0 libsord-0-0
  libsoxr0 libspeex1 libsphinxbase3 libsratom-0-0 libsrt1.4-gnutls libssh-gcrypt-4 libswresample3
  libswscale5 libthai-data libthai0 libtheora0 libtwolame0 libudfread0 libva-drm2 libva-x11-2 libva2
  libvdpau1 libvidstab1.1 libvorbis0a libvorbisenc2 libvorbisfile3 libvpx7 libwayland-client0
  libwayland-cursor0 libwayland-egl1 libwayland-server0 libwebpmux3 libx11-xcb1 libx264-163 libx265-199
  libxcb-dri2-0 libxcb-dri3-0 libxcb-glx0 libxcb-present0 libxcb-randr0 libxcb-render0 libxcb-shape0
  libxcb-shm0 libxcb-sync1 libxcb-xfixes0 libxcursor1 libxfixes3 libxi6 libxinerama1 libxkbcommon0
  libxrandr2 libxrender1 libxshmfence1 libxss1 libxv1 libxvidcore4 libxxf86vm1 libzimg2 libzmq5
  libzvbi-common libzvbi0 mesa-va-drivers mesa-vdpau-drivers ocl-icd-libopencl1 pocketsphinx-en-us
  va-driver-all vdpau-driver-all x11-common
Suggested packages:
  ffmpeg-doc i965-va-driver-shaders libasound2-plugins alsa-utils libcuda1 libnvcuvid1 libnvidia-encode1
  libbluray-bdj jackd2 libportaudio2 opus-tools pulseaudio libraw1394-doc librsvg2-bin xdg-utils
  lm-sensors serdi sndiod sordi speex opencl-icd libvdpau-va-gl1
The following NEW packages will be installed:
  alsa-topology-conf alsa-ucm-conf ffmpeg fontconfig i965-va-driver intel-media-va-driver libaacs0 libaom3
  libasound2 libasound2-data libass9 libasyncns0 libavc1394-0 libavcodec58 libavdevice58 libavfilter7
  libavformat58 libavutil56 libbdplus0 libblas3 libbluray2 libbs2b0 libcaca0 libcairo-gobject2 libcairo2
  libcdio-cdda2 libcdio-paranoia2 libcdio19 libchromaprint1 libcodec2-1.0 libdatrie1 libdav1d5
  libdc1394-25 libdecor-0-0 libdecor-0-plugin-1-cairo libdrm-amdgpu1 libdrm-intel1 libdrm-nouveau2
  libdrm-radeon1 libflac8 libflite1 libgbm1 libgdk-pixbuf-2.0-0 libgdk-pixbuf2.0-bin
  libgdk-pixbuf2.0-common libgfortran5 libgl1 libgl1-amber-dri libgl1-mesa-dri libglapi-mesa libglvnd0
  libglx-mesa0 libglx0 libgme0 libgraphite2-3 libgsm1 libharfbuzz0b libiec61883-0 libigdgmm12
  libjack-jackd2-0 liblapack3 liblilv-0-0 libllvm15 libmfx1 libmp3lame0 libmpg123-0 libmysofa1 libnorm1
  libogg0 libopenal-data libopenal1 libopenjp2-7 libopenmpt0 libopus0 libpango-1.0-0 libpangocairo-1.0-0
  libpangoft2-1.0-0 libpciaccess0 libpgm-5.3-0 libpixman-1-0 libpocketsphinx3 libpostproc55 libpulse0
  librabbitmq4 libraw1394-11 librsvg2-2 librsvg2-common librubberband2 libsamplerate0 libsdl2-2.0-0
  libsensors-config libsensors5 libserd-0-0 libshine3 libsnappy1v5 libsndfile1 libsndio7.0 libsord-0-0
  libsoxr0 libspeex1 libsphinxbase3 libsratom-0-0 libsrt1.4-gnutls libssh-gcrypt-4 libswresample3
  libswscale5 libthai-data libthai0 libtheora0 libtwolame0 libudfread0 libva-drm2 libva-x11-2 libva2
  libvdpau1 libvidstab1.1 libvorbis0a libvorbisenc2 libvorbisfile3 libvpx7 libwayland-client0
  libwayland-cursor0 libwayland-egl1 libwayland-server0 libwebpmux3 libx11-xcb1 libx264-163 libx265-199
  libxcb-dri2-0 libxcb-dri3-0 libxcb-glx0 libxcb-present0 libxcb-randr0 libxcb-render0 libxcb-shape0
  libxcb-shm0 libxcb-sync1 libxcb-xfixes0 libxcursor1 libxfixes3 libxi6 libxinerama1 libxkbcommon0
  libxrandr2 libxrender1 libxshmfence1 libxss1 libxv1 libxvidcore4 libxxf86vm1 libzimg2 libzmq5
  libzvbi-common libzvbi0 mesa-va-drivers mesa-vdpau-drivers ocl-icd-libopencl1 pocketsphinx-en-us
  va-driver-all vdpau-driver-all x11-common
0 upgraded, 161 newly installed, 0 to remove and 2 not upgraded.
Need to get 138 MB of archives.
After this operation, 429 MB of additional disk space will be used.
Get:1 http://archive.ubuntu.com/ubuntu jammy/main amd64 alsa-topology-conf all 1.2.5.1-2 [15.5 kB]
Get:2 http://archive.ubuntu.com/ubuntu jammy/main amd64 libasound2-data all 1.2.6.1-1ubuntu1 [19.1 kB]
Get:3 http://archive.ubuntu.com/ubuntu jammy/main amd64 libasound2 amd64 1.2.6.1-1ubuntu1 [390 kB]
Get:4 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 alsa-ucm-conf all 1.2.6.3-1ubuntu1.11 [43.6 kB]
Get:5 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libaom3 amd64 3.3.0-1 [1748 kB]
Get:6 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libva2 amd64 2.14.0-1 [65.0 kB]
Get:7 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libmfx1 amd64 22.3.0-1 [3105 kB]
Get:8 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libva-drm2 amd64 2.14.0-1 [7502 B]
Get:9 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxfixes3 amd64 1:6.0.0-1 [11.7 kB]
Get:10 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libva-x11-2 amd64 2.14.0-1 [12.6 kB]
Get:11 http://archive.ubuntu.com/ubuntu jammy/main amd64 libvdpau1 amd64 1.4-3build2 [27.0 kB]
Get:12 http://archive.ubuntu.com/ubuntu jammy/universe amd64 ocl-icd-libopencl1 amd64 2.2.14-3 [39.1 kB]
Get:13 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libavutil56 amd64 7:4.4.2-0ubuntu0.22.04.1 [290 kB]
Get:14 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libpixman-1-0 amd64 0.40.0-1ubuntu0.22.04.1 [264 kB]
Get:15 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-render0 amd64 1.14-3ubuntu3 [16.4 kB]
Get:16 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-shm0 amd64 1.14-3ubuntu3 [5780 B]
Get:17 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxrender1 amd64 1:0.9.10-1build4 [19.7 kB]
Get:18 http://archive.ubuntu.com/ubuntu jammy/main amd64 libcairo2 amd64 1.16.0-5ubuntu2 [628 kB]
Get:19 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libcodec2-1.0 amd64 1.0.1-3 [8435 kB]
Get:20 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libdav1d5 amd64 0.9.2-1 [463 kB]
Get:21 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libgsm1 amd64 1.0.19-1 [27.7 kB]
Get:22 http://archive.ubuntu.com/ubuntu jammy/main amd64 libmp3lame0 amd64 3.100-3build2 [141 kB]
Get:23 http://archive.ubuntu.com/ubuntu jammy/main amd64 libopenjp2-7 amd64 2.4.0-6 [158 kB]
Get:24 http://archive.ubuntu.com/ubuntu jammy/main amd64 libopus0 amd64 1.3.1-0.1build2 [203 kB]
Get:25 http://archive.ubuntu.com/ubuntu jammy/main amd64 libcairo-gobject2 amd64 1.16.0-5ubuntu2 [19.4 kB]
Get:26 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgdk-pixbuf2.0-common all 2.42.8+dfsg-1ubuntu0.3 [5630 B]
Get:27 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgdk-pixbuf-2.0-0 amd64 2.42.8+dfsg-1ubuntu0.3 [148 kB]
Get:28 http://archive.ubuntu.com/ubuntu jammy/main amd64 fontconfig amd64 2.13.1-4.2ubuntu5 [177 kB]
Get:29 http://archive.ubuntu.com/ubuntu jammy/main amd64 libgraphite2-3 amd64 1.3.14-1build2 [71.3 kB]
Get:30 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libharfbuzz0b amd64 2.7.4-1ubuntu3.1 [352 kB]
Get:31 http://archive.ubuntu.com/ubuntu jammy/main amd64 libthai-data all 0.1.29-1build1 [162 kB]
Get:32 http://archive.ubuntu.com/ubuntu jammy/main amd64 libdatrie1 amd64 0.2.13-2 [19.9 kB]
Get:33 http://archive.ubuntu.com/ubuntu jammy/main amd64 libthai0 amd64 0.1.29-1build1 [19.2 kB]
Get:34 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libpango-1.0-0 amd64 1.50.6+ds-2ubuntu1 [230 kB]
Get:35 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libpangoft2-1.0-0 amd64 1.50.6+ds-2ubuntu1 [54.0 kB]
Get:36 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libpangocairo-1.0-0 amd64 1.50.6+ds-2ubuntu1 [39.8 kB]
Get:37 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 librsvg2-2 amd64 2.52.5+dfsg-3ubuntu0.2 [2974 kB]
Get:38 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libshine3 amd64 3.1.1-2 [23.2 kB]
Get:39 http://archive.ubuntu.com/ubuntu jammy/main amd64 libsnappy1v5 amd64 1.1.8-1build3 [17.5 kB]
Get:40 http://archive.ubuntu.com/ubuntu jammy/main amd64 libspeex1 amd64 1.2~rc1.2-1.1ubuntu3 [57.9 kB]
Get:41 http://archive.ubuntu.com/ubuntu jammy/main amd64 libsoxr0 amd64 0.1.3-4build2 [79.8 kB]
Get:42 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libswresample3 amd64 7:4.4.2-0ubuntu0.22.04.1 [62.2 kB]
Get:43 http://archive.ubuntu.com/ubuntu jammy/main amd64 libogg0 amd64 1.3.5-0ubuntu3 [22.9 kB]
Get:44 http://archive.ubuntu.com/ubuntu jammy/main amd64 libtheora0 amd64 1.1.1+dfsg.1-15ubuntu4 [209 kB]
Get:45 http://archive.ubuntu.com/ubuntu jammy/main amd64 libtwolame0 amd64 0.4.0-2build2 [52.5 kB]
Get:46 http://archive.ubuntu.com/ubuntu jammy/main amd64 libvorbis0a amd64 1.3.7-1build2 [99.2 kB]
Get:47 http://archive.ubuntu.com/ubuntu jammy/main amd64 libvorbisenc2 amd64 1.3.7-1build2 [82.6 kB]
Get:48 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libvpx7 amd64 1.11.0-2ubuntu2.3 [1078 kB]
Get:49 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libwebpmux3 amd64 1.2.2-2ubuntu0.22.04.2 [20.5 kB]
Get:50 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libx264-163 amd64 2:0.163.3060+git5db6aa6-2build1 [591 kB]
Get:51 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libx265-199 amd64 3.5-2 [1170 kB]
Get:52 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libxvidcore4 amd64 2:1.3.7-1 [201 kB]
Get:53 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libzvbi-common all 0.2.35-19 [35.5 kB]
Get:54 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libzvbi0 amd64 0.2.35-19 [262 kB]
Get:55 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libavcodec58 amd64 7:4.4.2-0ubuntu0.22.04.1 [5567 kB]
Get:56 http://archive.ubuntu.com/ubuntu jammy/main amd64 libraw1394-11 amd64 2.1.2-2build2 [27.0 kB]
Get:57 http://archive.ubuntu.com/ubuntu jammy/main amd64 libavc1394-0 amd64 0.5.4-5build2 [17.0 kB]
Get:58 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libass9 amd64 1:0.15.2-1 [97.5 kB]
Get:59 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libudfread0 amd64 1.1.2-1 [16.2 kB]
Get:60 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libbluray2 amd64 1:1.3.1-1 [159 kB]
Get:61 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libchromaprint1 amd64 1.5.1-2 [28.4 kB]
Get:62 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libgme0 amd64 0.6.3-2 [127 kB]
Get:63 http://archive.ubuntu.com/ubuntu jammy/main amd64 libmpg123-0 amd64 1.29.3-1build1 [172 kB]
Get:64 http://archive.ubuntu.com/ubuntu jammy/main amd64 libvorbisfile3 amd64 1.3.7-1build2 [17.1 kB]
Get:65 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libopenmpt0 amd64 0.6.1-1 [592 kB]
Get:66 http://archive.ubuntu.com/ubuntu jammy/main amd64 librabbitmq4 amd64 0.10.0-1ubuntu2 [39.3 kB]
Get:67 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libsrt1.4-gnutls amd64 1.4.4-4 [309 kB]
Get:68 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libssh-gcrypt-4 amd64 0.9.6-2ubuntu0.22.04.3 [223 kB]
Get:69 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libnorm1 amd64 1.5.9+dfsg-2 [221 kB]
Get:70 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libpgm-5.3-0 amd64 5.3.128~dfsg-2 [161 kB]
Get:71 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libzmq5 amd64 4.3.4-2 [256 kB]
Get:72 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libavformat58 amd64 7:4.4.2-0ubuntu0.22.04.1 [1103 kB]
Get:73 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libbs2b0 amd64 3.1.0+dfsg-2.2build1 [10.2 kB]
Get:74 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libflite1 amd64 2.2-3 [13.7 MB]
Get:75 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libserd-0-0 amd64 0.30.10-2 [40.8 kB]
Get:76 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libsord-0-0 amd64 0.16.8-2 [21.2 kB]
Get:77 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libsratom-0-0 amd64 0.6.8-1 [17.0 kB]
Get:78 http://archive.ubuntu.com/ubuntu jammy/universe amd64 liblilv-0-0 amd64 0.24.12-2 [42.8 kB]
Get:79 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libmysofa1 amd64 1.2.1~dfsg0-1 [1157 kB]
Get:80 http://archive.ubuntu.com/ubuntu jammy/main amd64 libblas3 amd64 3.10.0-2ubuntu1 [228 kB]
Get:81 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgfortran5 amd64 12.3.0-1ubuntu1~22.04 [879 kB]
Get:82 http://archive.ubuntu.com/ubuntu jammy/main amd64 liblapack3 amd64 3.10.0-2ubuntu1 [2504 kB]
Get:83 http://archive.ubuntu.com/ubuntu jammy/main amd64 libasyncns0 amd64 0.8-6build2 [12.8 kB]
Get:84 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libflac8 amd64 1.3.3-2ubuntu0.2 [111 kB]
Get:85 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libsndfile1 amd64 1.0.31-2ubuntu0.1 [197 kB]
Get:86 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libx11-xcb1 amd64 2:1.7.5-1ubuntu0.3 [7802 B]
Get:87 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libpulse0 amd64 1:15.99.1+dfsg1-1ubuntu2.2 [298 kB]
Get:88 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libsphinxbase3 amd64 0.8+5prealpha+1-13build1 [126 kB]
Get:89 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libpocketsphinx3 amd64 0.8.0+real5prealpha+1-14ubuntu1 [132 kB]
Get:90 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libpostproc55 amd64 7:4.4.2-0ubuntu0.22.04.1 [60.1 kB]
Get:91 http://archive.ubuntu.com/ubuntu jammy/main amd64 libsamplerate0 amd64 0.2.2-1build1 [1359 kB]
Get:92 http://archive.ubuntu.com/ubuntu jammy/universe amd64 librubberband2 amd64 2.0.0-2 [90.0 kB]
Get:93 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libswscale5 amd64 7:4.4.2-0ubuntu0.22.04.1 [180 kB]
Get:94 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libvidstab1.1 amd64 1.1.0-2 [35.0 kB]
Get:95 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libzimg2 amd64 3.0.3+ds1-1 [241 kB]
Get:96 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libavfilter7 amd64 7:4.4.2-0ubuntu0.22.04.1 [1496 kB]
Get:97 http://archive.ubuntu.com/ubuntu jammy/main amd64 libcaca0 amd64 0.99.beta19-2.2ubuntu4 [224 kB]
Get:98 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libcdio19 amd64 2.1.0-3ubuntu0.2 [63.6 kB]
Get:99 http://archive.ubuntu.com/ubuntu jammy/main amd64 libcdio-cdda2 amd64 10.2+2.0.0-1build3 [16.7 kB]
Get:100 http://archive.ubuntu.com/ubuntu jammy/main amd64 libcdio-paranoia2 amd64 10.2+2.0.0-1build3 [15.9 kB]
Get:101 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libdc1394-25 amd64 2.2.6-4 [88.8 kB]
Get:102 http://archive.ubuntu.com/ubuntu jammy/main amd64 libglvnd0 amd64 1.4.0-1 [73.6 kB]
Get:103 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libglapi-mesa amd64 23.2.1-1ubuntu3.1~22.04.2 [37.1 kB]
Get:104 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-dri2-0 amd64 1.14-3ubuntu3 [7206 B]
Get:105 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-dri3-0 amd64 1.14-3ubuntu3 [6968 B]
Get:106 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-glx0 amd64 1.14-3ubuntu3 [25.9 kB]
Get:107 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-present0 amd64 1.14-3ubuntu3 [5734 B]
Get:108 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-randr0 amd64 1.14-3ubuntu3 [18.3 kB]
Get:109 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-sync1 amd64 1.14-3ubuntu3 [9416 B]
Get:110 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-xfixes0 amd64 1.14-3ubuntu3 [9996 B]
Get:111 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxshmfence1 amd64 1.3-1build4 [5394 B]
Get:112 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxxf86vm1 amd64 1:1.1.4-1build3 [10.4 kB]
Get:113 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libdrm-amdgpu1 amd64 2.4.113-2~ubuntu0.22.04.1 [19.9 kB]
Get:114 http://archive.ubuntu.com/ubuntu jammy/main amd64 libpciaccess0 amd64 0.16-3 [19.1 kB]
Get:115 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libdrm-intel1 amd64 2.4.113-2~ubuntu0.22.04.1 [66.7 kB]
Get:116 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libdrm-nouveau2 amd64 2.4.113-2~ubuntu0.22.04.1 [17.5 kB]
Get:117 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libdrm-radeon1 amd64 2.4.113-2~ubuntu0.22.04.1 [21.6 kB]
Get:118 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libllvm15 amd64 1:15.0.7-0ubuntu0.22.04.3 [25.4 MB]
Get:119 http://archive.ubuntu.com/ubuntu jammy/main amd64 libsensors-config all 1:3.6.0-7ubuntu1 [5274 B]
Get:120 http://archive.ubuntu.com/ubuntu jammy/main amd64 libsensors5 amd64 1:3.6.0-7ubuntu1 [26.3 kB]
Get:121 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgl1-mesa-dri amd64 23.2.1-1ubuntu3.1~22.04.2 [8860 kB]
Get:122 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libglx-mesa0 amd64 23.2.1-1ubuntu3.1~22.04.2 [158 kB]
Get:123 http://archive.ubuntu.com/ubuntu jammy/main amd64 libglx0 amd64 1.4.0-1 [41.0 kB]
Get:124 http://archive.ubuntu.com/ubuntu jammy/main amd64 libgl1 amd64 1.4.0-1 [110 kB]
Get:125 http://archive.ubuntu.com/ubuntu jammy/main amd64 libiec61883-0 amd64 1.2.0-4build3 [25.9 kB]
Get:126 http://archive.ubuntu.com/ubuntu jammy/main amd64 libjack-jackd2-0 amd64 1.9.20~dfsg-1 [293 kB]
Get:127 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libopenal-data all 1:1.19.1-2build3 [164 kB]
Get:128 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libsndio7.0 amd64 1.8.1-1.1 [29.3 kB]
Get:129 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libopenal1 amd64 1:1.19.1-2build3 [535 kB]
Get:130 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libwayland-client0 amd64 1.20.0-1ubuntu0.1 [25.9 kB]
Get:131 http://archive.ubuntu.com/ubuntu jammy/main amd64 libdecor-0-0 amd64 0.1.0-3build1 [15.1 kB]
Get:132 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libwayland-server0 amd64 1.20.0-1ubuntu0.1 [34.3 kB]
Get:133 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgbm1 amd64 23.2.1-1ubuntu3.1~22.04.2 [33.5 kB]
Get:134 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libwayland-cursor0 amd64 1.20.0-1ubuntu0.1 [10.7 kB]
Get:135 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libwayland-egl1 amd64 1.20.0-1ubuntu0.1 [5582 B]
Get:136 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcursor1 amd64 1:1.2.0-2build4 [20.9 kB]
Get:137 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxi6 amd64 2:1.8-1build1 [32.6 kB]
Get:138 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxinerama1 amd64 2:1.1.4-3 [7382 B]
Get:139 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxkbcommon0 amd64 1.4.0-1 [125 kB]
Get:140 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxrandr2 amd64 2:1.5.2-1build1 [20.4 kB]
Get:141 http://archive.ubuntu.com/ubuntu jammy/main amd64 x11-common all 1:7.7+23ubuntu2 [23.4 kB]
Get:142 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxss1 amd64 1:1.2.3-1build2 [8476 B]
Get:143 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libsdl2-2.0-0 amd64 2.0.20+dfsg-2ubuntu1.22.04.1 [582 kB]
Get:144 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxcb-shape0 amd64 1.14-3ubuntu3 [6158 B]
Get:145 http://archive.ubuntu.com/ubuntu jammy/main amd64 libxv1 amd64 2:1.0.11-1build2 [11.2 kB]
Get:146 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 libavdevice58 amd64 7:4.4.2-0ubuntu0.22.04.1 [87.5 kB]
Get:147 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 ffmpeg amd64 7:4.4.2-0ubuntu0.22.04.1 [1696 kB]
Get:148 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libigdgmm12 amd64 22.1.2+ds1-1 [139 kB]
Get:149 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 intel-media-va-driver amd64 22.3.1+dfsg1-1ubuntu2 [2283 kB]
Get:150 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libaacs0 amd64 0.11.1-1 [64.1 kB]
Get:151 http://archive.ubuntu.com/ubuntu jammy/universe amd64 libbdplus0 amd64 0.2.0-1 [52.2 kB]
Get:152 http://archive.ubuntu.com/ubuntu jammy/main amd64 libdecor-0-plugin-1-cairo amd64 0.1.0-3build1 [20.4 kB]
Get:153 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgdk-pixbuf2.0-bin amd64 2.42.8+dfsg-1ubuntu0.3 [14.2 kB]
Get:154 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 libgl1-amber-dri amd64 21.3.9-0ubuntu1~22.04.1 [4218 kB]
Get:155 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 librsvg2-common amd64 2.52.5+dfsg-3ubuntu0.2 [17.7 kB]
Get:156 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 mesa-va-drivers amd64 23.2.1-1ubuntu3.1~22.04.2 [4100 kB]
Get:157 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 mesa-vdpau-drivers amd64 23.2.1-1ubuntu3.1~22.04.2 [3820 kB]
Get:158 http://archive.ubuntu.com/ubuntu jammy/universe amd64 i965-va-driver amd64 2.4.1+dfsg1-1 [302 kB]
Get:159 http://archive.ubuntu.com/ubuntu jammy/universe amd64 va-driver-all amd64 2.14.0-1 [3984 B]
Get:160 http://archive.ubuntu.com/ubuntu jammy/main amd64 vdpau-driver-all amd64 1.4-3build2 [4510 B]
Get:161 http://archive.ubuntu.com/ubuntu jammy/universe amd64 pocketsphinx-en-us all 0.8.0+real5prealpha+1-14ubuntu1 [27.6 MB]
Fetched 138 MB in 18s (7561 kB/s)
Extracting templates from packages: 100%
Selecting previously unselected package alsa-topology-conf.
(Reading database ... 32407 files and directories currently installed.)
Preparing to unpack .../000-alsa-topology-conf_1.2.5.1-2_all.deb ...
Unpacking alsa-topology-conf (1.2.5.1-2) ...
Selecting previously unselected package libasound2-data.
Preparing to unpack .../001-libasound2-data_1.2.6.1-1ubuntu1_all.deb ...
Unpacking libasound2-data (1.2.6.1-1ubuntu1) ...
Selecting previously unselected package libasound2:amd64.
Preparing to unpack .../002-libasound2_1.2.6.1-1ubuntu1_amd64.deb ...
Unpacking libasound2:amd64 (1.2.6.1-1ubuntu1) ...
Selecting previously unselected package alsa-ucm-conf.
Preparing to unpack .../003-alsa-ucm-conf_1.2.6.3-1ubuntu1.11_all.deb ...
Unpacking alsa-ucm-conf (1.2.6.3-1ubuntu1.11) ...
Selecting previously unselected package libaom3:amd64.
Preparing to unpack .../004-libaom3_3.3.0-1_amd64.deb ...
Unpacking libaom3:amd64 (3.3.0-1) ...
Selecting previously unselected package libva2:amd64.
Preparing to unpack .../005-libva2_2.14.0-1_amd64.deb ...
Unpacking libva2:amd64 (2.14.0-1) ...
Selecting previously unselected package libmfx1:amd64.
Preparing to unpack .../006-libmfx1_22.3.0-1_amd64.deb ...
Unpacking libmfx1:amd64 (22.3.0-1) ...
Selecting previously unselected package libva-drm2:amd64.
Preparing to unpack .../007-libva-drm2_2.14.0-1_amd64.deb ...
Unpacking libva-drm2:amd64 (2.14.0-1) ...
Selecting previously unselected package libxfixes3:amd64.
Preparing to unpack .../008-libxfixes3_1%3a6.0.0-1_amd64.deb ...
Unpacking libxfixes3:amd64 (1:6.0.0-1) ...
Selecting previously unselected package libva-x11-2:amd64.
Preparing to unpack .../009-libva-x11-2_2.14.0-1_amd64.deb ...
Unpacking libva-x11-2:amd64 (2.14.0-1) ...
Selecting previously unselected package libvdpau1:amd64.
Preparing to unpack .../010-libvdpau1_1.4-3build2_amd64.deb ...
Unpacking libvdpau1:amd64 (1.4-3build2) ...
Selecting previously unselected package ocl-icd-libopencl1:amd64.
Preparing to unpack .../011-ocl-icd-libopencl1_2.2.14-3_amd64.deb ...
Unpacking ocl-icd-libopencl1:amd64 (2.2.14-3) ...
Selecting previously unselected package libavutil56:amd64.
Preparing to unpack .../012-libavutil56_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libavutil56:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libpixman-1-0:amd64.
Preparing to unpack .../013-libpixman-1-0_0.40.0-1ubuntu0.22.04.1_amd64.deb ...
Unpacking libpixman-1-0:amd64 (0.40.0-1ubuntu0.22.04.1) ...
Selecting previously unselected package libxcb-render0:amd64.
Preparing to unpack .../014-libxcb-render0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-render0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxcb-shm0:amd64.
Preparing to unpack .../015-libxcb-shm0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-shm0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxrender1:amd64.
Preparing to unpack .../016-libxrender1_1%3a0.9.10-1build4_amd64.deb ...
Unpacking libxrender1:amd64 (1:0.9.10-1build4) ...
Selecting previously unselected package libcairo2:amd64.
Preparing to unpack .../017-libcairo2_1.16.0-5ubuntu2_amd64.deb ...
Unpacking libcairo2:amd64 (1.16.0-5ubuntu2) ...
Selecting previously unselected package libcodec2-1.0:amd64.
Preparing to unpack .../018-libcodec2-1.0_1.0.1-3_amd64.deb ...
Unpacking libcodec2-1.0:amd64 (1.0.1-3) ...
Selecting previously unselected package libdav1d5:amd64.
Preparing to unpack .../019-libdav1d5_0.9.2-1_amd64.deb ...
Unpacking libdav1d5:amd64 (0.9.2-1) ...
Selecting previously unselected package libgsm1:amd64.
Preparing to unpack .../020-libgsm1_1.0.19-1_amd64.deb ...
Unpacking libgsm1:amd64 (1.0.19-1) ...
Selecting previously unselected package libmp3lame0:amd64.
Preparing to unpack .../021-libmp3lame0_3.100-3build2_amd64.deb ...
Unpacking libmp3lame0:amd64 (3.100-3build2) ...
Selecting previously unselected package libopenjp2-7:amd64.
Preparing to unpack .../022-libopenjp2-7_2.4.0-6_amd64.deb ...
Unpacking libopenjp2-7:amd64 (2.4.0-6) ...
Selecting previously unselected package libopus0:amd64.
Preparing to unpack .../023-libopus0_1.3.1-0.1build2_amd64.deb ...
Unpacking libopus0:amd64 (1.3.1-0.1build2) ...
Selecting previously unselected package libcairo-gobject2:amd64.
Preparing to unpack .../024-libcairo-gobject2_1.16.0-5ubuntu2_amd64.deb ...
Unpacking libcairo-gobject2:amd64 (1.16.0-5ubuntu2) ...
Selecting previously unselected package libgdk-pixbuf2.0-common.
Preparing to unpack .../025-libgdk-pixbuf2.0-common_2.42.8+dfsg-1ubuntu0.3_all.deb ...
Unpacking libgdk-pixbuf2.0-common (2.42.8+dfsg-1ubuntu0.3) ...
Selecting previously unselected package libgdk-pixbuf-2.0-0:amd64.
Preparing to unpack .../026-libgdk-pixbuf-2.0-0_2.42.8+dfsg-1ubuntu0.3_amd64.deb ...
Unpacking libgdk-pixbuf-2.0-0:amd64 (2.42.8+dfsg-1ubuntu0.3) ...
Selecting previously unselected package fontconfig.
Preparing to unpack .../027-fontconfig_2.13.1-4.2ubuntu5_amd64.deb ...
Unpacking fontconfig (2.13.1-4.2ubuntu5) ...
Selecting previously unselected package libgraphite2-3:amd64.
Preparing to unpack .../028-libgraphite2-3_1.3.14-1build2_amd64.deb ...
Unpacking libgraphite2-3:amd64 (1.3.14-1build2) ...
Selecting previously unselected package libharfbuzz0b:amd64.
Preparing to unpack .../029-libharfbuzz0b_2.7.4-1ubuntu3.1_amd64.deb ...
Unpacking libharfbuzz0b:amd64 (2.7.4-1ubuntu3.1) ...
Selecting previously unselected package libthai-data.
Preparing to unpack .../030-libthai-data_0.1.29-1build1_all.deb ...
Unpacking libthai-data (0.1.29-1build1) ...
Selecting previously unselected package libdatrie1:amd64.
Preparing to unpack .../031-libdatrie1_0.2.13-2_amd64.deb ...
Unpacking libdatrie1:amd64 (0.2.13-2) ...
Selecting previously unselected package libthai0:amd64.
Preparing to unpack .../032-libthai0_0.1.29-1build1_amd64.deb ...
Unpacking libthai0:amd64 (0.1.29-1build1) ...
Selecting previously unselected package libpango-1.0-0:amd64.
Preparing to unpack .../033-libpango-1.0-0_1.50.6+ds-2ubuntu1_amd64.deb ...
Unpacking libpango-1.0-0:amd64 (1.50.6+ds-2ubuntu1) ...
Selecting previously unselected package libpangoft2-1.0-0:amd64.
Preparing to unpack .../034-libpangoft2-1.0-0_1.50.6+ds-2ubuntu1_amd64.deb ...
Unpacking libpangoft2-1.0-0:amd64 (1.50.6+ds-2ubuntu1) ...
Selecting previously unselected package libpangocairo-1.0-0:amd64.
Preparing to unpack .../035-libpangocairo-1.0-0_1.50.6+ds-2ubuntu1_amd64.deb ...
Unpacking libpangocairo-1.0-0:amd64 (1.50.6+ds-2ubuntu1) ...
Selecting previously unselected package librsvg2-2:amd64.
Preparing to unpack .../036-librsvg2-2_2.52.5+dfsg-3ubuntu0.2_amd64.deb ...
Unpacking librsvg2-2:amd64 (2.52.5+dfsg-3ubuntu0.2) ...
Selecting previously unselected package libshine3:amd64.
Preparing to unpack .../037-libshine3_3.1.1-2_amd64.deb ...
Unpacking libshine3:amd64 (3.1.1-2) ...
Selecting previously unselected package libsnappy1v5:amd64.
Preparing to unpack .../038-libsnappy1v5_1.1.8-1build3_amd64.deb ...
Unpacking libsnappy1v5:amd64 (1.1.8-1build3) ...
Selecting previously unselected package libspeex1:amd64.
Preparing to unpack .../039-libspeex1_1.2~rc1.2-1.1ubuntu3_amd64.deb ...
Unpacking libspeex1:amd64 (1.2~rc1.2-1.1ubuntu3) ...
Selecting previously unselected package libsoxr0:amd64.
Preparing to unpack .../040-libsoxr0_0.1.3-4build2_amd64.deb ...
Unpacking libsoxr0:amd64 (0.1.3-4build2) ...
Selecting previously unselected package libswresample3:amd64.
Preparing to unpack .../041-libswresample3_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libswresample3:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libogg0:amd64.
Preparing to unpack .../042-libogg0_1.3.5-0ubuntu3_amd64.deb ...
Unpacking libogg0:amd64 (1.3.5-0ubuntu3) ...
Selecting previously unselected package libtheora0:amd64.
Preparing to unpack .../043-libtheora0_1.1.1+dfsg.1-15ubuntu4_amd64.deb ...
Unpacking libtheora0:amd64 (1.1.1+dfsg.1-15ubuntu4) ...
Selecting previously unselected package libtwolame0:amd64.
Preparing to unpack .../044-libtwolame0_0.4.0-2build2_amd64.deb ...
Unpacking libtwolame0:amd64 (0.4.0-2build2) ...
Selecting previously unselected package libvorbis0a:amd64.
Preparing to unpack .../045-libvorbis0a_1.3.7-1build2_amd64.deb ...
Unpacking libvorbis0a:amd64 (1.3.7-1build2) ...
Selecting previously unselected package libvorbisenc2:amd64.
Preparing to unpack .../046-libvorbisenc2_1.3.7-1build2_amd64.deb ...
Unpacking libvorbisenc2:amd64 (1.3.7-1build2) ...
Selecting previously unselected package libvpx7:amd64.
Preparing to unpack .../047-libvpx7_1.11.0-2ubuntu2.3_amd64.deb ...
Unpacking libvpx7:amd64 (1.11.0-2ubuntu2.3) ...
Selecting previously unselected package libwebpmux3:amd64.
Preparing to unpack .../048-libwebpmux3_1.2.2-2ubuntu0.22.04.2_amd64.deb ...
Unpacking libwebpmux3:amd64 (1.2.2-2ubuntu0.22.04.2) ...
Selecting previously unselected package libx264-163:amd64.
Preparing to unpack .../049-libx264-163_2%3a0.163.3060+git5db6aa6-2build1_amd64.deb ...
Unpacking libx264-163:amd64 (2:0.163.3060+git5db6aa6-2build1) ...
Selecting previously unselected package libx265-199:amd64.
Preparing to unpack .../050-libx265-199_3.5-2_amd64.deb ...
Unpacking libx265-199:amd64 (3.5-2) ...
Selecting previously unselected package libxvidcore4:amd64.
Preparing to unpack .../051-libxvidcore4_2%3a1.3.7-1_amd64.deb ...
Unpacking libxvidcore4:amd64 (2:1.3.7-1) ...
Selecting previously unselected package libzvbi-common.
Preparing to unpack .../052-libzvbi-common_0.2.35-19_all.deb ...
Unpacking libzvbi-common (0.2.35-19) ...
Selecting previously unselected package libzvbi0:amd64.
Preparing to unpack .../053-libzvbi0_0.2.35-19_amd64.deb ...
Unpacking libzvbi0:amd64 (0.2.35-19) ...
Selecting previously unselected package libavcodec58:amd64.
Preparing to unpack .../054-libavcodec58_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libavcodec58:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libraw1394-11:amd64.
Preparing to unpack .../055-libraw1394-11_2.1.2-2build2_amd64.deb ...
Unpacking libraw1394-11:amd64 (2.1.2-2build2) ...
Selecting previously unselected package libavc1394-0:amd64.
Preparing to unpack .../056-libavc1394-0_0.5.4-5build2_amd64.deb ...
Unpacking libavc1394-0:amd64 (0.5.4-5build2) ...
Selecting previously unselected package libass9:amd64.
Preparing to unpack .../057-libass9_1%3a0.15.2-1_amd64.deb ...
Unpacking libass9:amd64 (1:0.15.2-1) ...
Selecting previously unselected package libudfread0:amd64.
Preparing to unpack .../058-libudfread0_1.1.2-1_amd64.deb ...
Unpacking libudfread0:amd64 (1.1.2-1) ...
Selecting previously unselected package libbluray2:amd64.
Preparing to unpack .../059-libbluray2_1%3a1.3.1-1_amd64.deb ...
Unpacking libbluray2:amd64 (1:1.3.1-1) ...
Selecting previously unselected package libchromaprint1:amd64.
Preparing to unpack .../060-libchromaprint1_1.5.1-2_amd64.deb ...
Unpacking libchromaprint1:amd64 (1.5.1-2) ...
Selecting previously unselected package libgme0:amd64.
Preparing to unpack .../061-libgme0_0.6.3-2_amd64.deb ...
Unpacking libgme0:amd64 (0.6.3-2) ...
Selecting previously unselected package libmpg123-0:amd64.
Preparing to unpack .../062-libmpg123-0_1.29.3-1build1_amd64.deb ...
Unpacking libmpg123-0:amd64 (1.29.3-1build1) ...
Selecting previously unselected package libvorbisfile3:amd64.
Preparing to unpack .../063-libvorbisfile3_1.3.7-1build2_amd64.deb ...
Unpacking libvorbisfile3:amd64 (1.3.7-1build2) ...
Selecting previously unselected package libopenmpt0:amd64.
Preparing to unpack .../064-libopenmpt0_0.6.1-1_amd64.deb ...
Unpacking libopenmpt0:amd64 (0.6.1-1) ...
Selecting previously unselected package librabbitmq4:amd64.
Preparing to unpack .../065-librabbitmq4_0.10.0-1ubuntu2_amd64.deb ...
Unpacking librabbitmq4:amd64 (0.10.0-1ubuntu2) ...
Selecting previously unselected package libsrt1.4-gnutls:amd64.
Preparing to unpack .../066-libsrt1.4-gnutls_1.4.4-4_amd64.deb ...
Unpacking libsrt1.4-gnutls:amd64 (1.4.4-4) ...
Selecting previously unselected package libssh-gcrypt-4:amd64.
Preparing to unpack .../067-libssh-gcrypt-4_0.9.6-2ubuntu0.22.04.3_amd64.deb ...
Unpacking libssh-gcrypt-4:amd64 (0.9.6-2ubuntu0.22.04.3) ...
Selecting previously unselected package libnorm1:amd64.
Preparing to unpack .../068-libnorm1_1.5.9+dfsg-2_amd64.deb ...
Unpacking libnorm1:amd64 (1.5.9+dfsg-2) ...
Selecting previously unselected package libpgm-5.3-0:amd64.
Preparing to unpack .../069-libpgm-5.3-0_5.3.128~dfsg-2_amd64.deb ...
Unpacking libpgm-5.3-0:amd64 (5.3.128~dfsg-2) ...
Selecting previously unselected package libzmq5:amd64.
Preparing to unpack .../070-libzmq5_4.3.4-2_amd64.deb ...
Unpacking libzmq5:amd64 (4.3.4-2) ...
Selecting previously unselected package libavformat58:amd64.
Preparing to unpack .../071-libavformat58_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libavformat58:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libbs2b0:amd64.
Preparing to unpack .../072-libbs2b0_3.1.0+dfsg-2.2build1_amd64.deb ...
Unpacking libbs2b0:amd64 (3.1.0+dfsg-2.2build1) ...
Selecting previously unselected package libflite1:amd64.
Preparing to unpack .../073-libflite1_2.2-3_amd64.deb ...
Unpacking libflite1:amd64 (2.2-3) ...
Selecting previously unselected package libserd-0-0:amd64.
Preparing to unpack .../074-libserd-0-0_0.30.10-2_amd64.deb ...
Unpacking libserd-0-0:amd64 (0.30.10-2) ...
Selecting previously unselected package libsord-0-0:amd64.
Preparing to unpack .../075-libsord-0-0_0.16.8-2_amd64.deb ...
Unpacking libsord-0-0:amd64 (0.16.8-2) ...
Selecting previously unselected package libsratom-0-0:amd64.
Preparing to unpack .../076-libsratom-0-0_0.6.8-1_amd64.deb ...
Unpacking libsratom-0-0:amd64 (0.6.8-1) ...
Selecting previously unselected package liblilv-0-0:amd64.
Preparing to unpack .../077-liblilv-0-0_0.24.12-2_amd64.deb ...
Unpacking liblilv-0-0:amd64 (0.24.12-2) ...
Selecting previously unselected package libmysofa1:amd64.
Preparing to unpack .../078-libmysofa1_1.2.1~dfsg0-1_amd64.deb ...
Unpacking libmysofa1:amd64 (1.2.1~dfsg0-1) ...
Selecting previously unselected package libblas3:amd64.
Preparing to unpack .../079-libblas3_3.10.0-2ubuntu1_amd64.deb ...
Unpacking libblas3:amd64 (3.10.0-2ubuntu1) ...
Selecting previously unselected package libgfortran5:amd64.
Preparing to unpack .../080-libgfortran5_12.3.0-1ubuntu1~22.04_amd64.deb ...
Unpacking libgfortran5:amd64 (12.3.0-1ubuntu1~22.04) ...
Selecting previously unselected package liblapack3:amd64.
Preparing to unpack .../081-liblapack3_3.10.0-2ubuntu1_amd64.deb ...
Unpacking liblapack3:amd64 (3.10.0-2ubuntu1) ...
Selecting previously unselected package libasyncns0:amd64.
Preparing to unpack .../082-libasyncns0_0.8-6build2_amd64.deb ...
Unpacking libasyncns0:amd64 (0.8-6build2) ...
Selecting previously unselected package libflac8:amd64.
Preparing to unpack .../083-libflac8_1.3.3-2ubuntu0.2_amd64.deb ...
Unpacking libflac8:amd64 (1.3.3-2ubuntu0.2) ...
Selecting previously unselected package libsndfile1:amd64.
Preparing to unpack .../084-libsndfile1_1.0.31-2ubuntu0.1_amd64.deb ...
Unpacking libsndfile1:amd64 (1.0.31-2ubuntu0.1) ...
Selecting previously unselected package libx11-xcb1:amd64.
Preparing to unpack .../085-libx11-xcb1_2%3a1.7.5-1ubuntu0.3_amd64.deb ...
Unpacking libx11-xcb1:amd64 (2:1.7.5-1ubuntu0.3) ...
Selecting previously unselected package libpulse0:amd64.
Preparing to unpack .../086-libpulse0_1%3a15.99.1+dfsg1-1ubuntu2.2_amd64.deb ...
Unpacking libpulse0:amd64 (1:15.99.1+dfsg1-1ubuntu2.2) ...
Selecting previously unselected package libsphinxbase3:amd64.
Preparing to unpack .../087-libsphinxbase3_0.8+5prealpha+1-13build1_amd64.deb ...
Unpacking libsphinxbase3:amd64 (0.8+5prealpha+1-13build1) ...
Selecting previously unselected package libpocketsphinx3:amd64.
Preparing to unpack .../088-libpocketsphinx3_0.8.0+real5prealpha+1-14ubuntu1_amd64.deb ...
Unpacking libpocketsphinx3:amd64 (0.8.0+real5prealpha+1-14ubuntu1) ...
Selecting previously unselected package libpostproc55:amd64.
Preparing to unpack .../089-libpostproc55_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libpostproc55:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libsamplerate0:amd64.
Preparing to unpack .../090-libsamplerate0_0.2.2-1build1_amd64.deb ...
Unpacking libsamplerate0:amd64 (0.2.2-1build1) ...
Selecting previously unselected package librubberband2:amd64.
Preparing to unpack .../091-librubberband2_2.0.0-2_amd64.deb ...
Unpacking librubberband2:amd64 (2.0.0-2) ...
Selecting previously unselected package libswscale5:amd64.
Preparing to unpack .../092-libswscale5_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libswscale5:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libvidstab1.1:amd64.
Preparing to unpack .../093-libvidstab1.1_1.1.0-2_amd64.deb ...
Unpacking libvidstab1.1:amd64 (1.1.0-2) ...
Selecting previously unselected package libzimg2:amd64.
Preparing to unpack .../094-libzimg2_3.0.3+ds1-1_amd64.deb ...
Unpacking libzimg2:amd64 (3.0.3+ds1-1) ...
Selecting previously unselected package libavfilter7:amd64.
Preparing to unpack .../095-libavfilter7_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libavfilter7:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libcaca0:amd64.
Preparing to unpack .../096-libcaca0_0.99.beta19-2.2ubuntu4_amd64.deb ...
Unpacking libcaca0:amd64 (0.99.beta19-2.2ubuntu4) ...
Selecting previously unselected package libcdio19:amd64.
Preparing to unpack .../097-libcdio19_2.1.0-3ubuntu0.2_amd64.deb ...
Unpacking libcdio19:amd64 (2.1.0-3ubuntu0.2) ...
Selecting previously unselected package libcdio-cdda2:amd64.
Preparing to unpack .../098-libcdio-cdda2_10.2+2.0.0-1build3_amd64.deb ...
Unpacking libcdio-cdda2:amd64 (10.2+2.0.0-1build3) ...
Selecting previously unselected package libcdio-paranoia2:amd64.
Preparing to unpack .../099-libcdio-paranoia2_10.2+2.0.0-1build3_amd64.deb ...
Unpacking libcdio-paranoia2:amd64 (10.2+2.0.0-1build3) ...
Selecting previously unselected package libdc1394-25:amd64.
Preparing to unpack .../100-libdc1394-25_2.2.6-4_amd64.deb ...
Unpacking libdc1394-25:amd64 (2.2.6-4) ...
Selecting previously unselected package libglvnd0:amd64.
Preparing to unpack .../101-libglvnd0_1.4.0-1_amd64.deb ...
Unpacking libglvnd0:amd64 (1.4.0-1) ...
Selecting previously unselected package libglapi-mesa:amd64.
Preparing to unpack .../102-libglapi-mesa_23.2.1-1ubuntu3.1~22.04.2_amd64.deb ...
Unpacking libglapi-mesa:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Selecting previously unselected package libxcb-dri2-0:amd64.
Preparing to unpack .../103-libxcb-dri2-0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-dri2-0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxcb-dri3-0:amd64.
Preparing to unpack .../104-libxcb-dri3-0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-dri3-0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxcb-glx0:amd64.
Preparing to unpack .../105-libxcb-glx0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-glx0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxcb-present0:amd64.
Preparing to unpack .../106-libxcb-present0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-present0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxcb-randr0:amd64.
Preparing to unpack .../107-libxcb-randr0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-randr0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxcb-sync1:amd64.
Preparing to unpack .../108-libxcb-sync1_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-sync1:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxcb-xfixes0:amd64.
Preparing to unpack .../109-libxcb-xfixes0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-xfixes0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxshmfence1:amd64.
Preparing to unpack .../110-libxshmfence1_1.3-1build4_amd64.deb ...
Unpacking libxshmfence1:amd64 (1.3-1build4) ...
Selecting previously unselected package libxxf86vm1:amd64.
Preparing to unpack .../111-libxxf86vm1_1%3a1.1.4-1build3_amd64.deb ...
Unpacking libxxf86vm1:amd64 (1:1.1.4-1build3) ...
Selecting previously unselected package libdrm-amdgpu1:amd64.
Preparing to unpack .../112-libdrm-amdgpu1_2.4.113-2~ubuntu0.22.04.1_amd64.deb ...
Unpacking libdrm-amdgpu1:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Selecting previously unselected package libpciaccess0:amd64.
Preparing to unpack .../113-libpciaccess0_0.16-3_amd64.deb ...
Unpacking libpciaccess0:amd64 (0.16-3) ...
Selecting previously unselected package libdrm-intel1:amd64.
Preparing to unpack .../114-libdrm-intel1_2.4.113-2~ubuntu0.22.04.1_amd64.deb ...
Unpacking libdrm-intel1:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Selecting previously unselected package libdrm-nouveau2:amd64.
Preparing to unpack .../115-libdrm-nouveau2_2.4.113-2~ubuntu0.22.04.1_amd64.deb ...
Unpacking libdrm-nouveau2:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Selecting previously unselected package libdrm-radeon1:amd64.
Preparing to unpack .../116-libdrm-radeon1_2.4.113-2~ubuntu0.22.04.1_amd64.deb ...
Unpacking libdrm-radeon1:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Selecting previously unselected package libllvm15:amd64.
Preparing to unpack .../117-libllvm15_1%3a15.0.7-0ubuntu0.22.04.3_amd64.deb ...
Unpacking libllvm15:amd64 (1:15.0.7-0ubuntu0.22.04.3) ...
Selecting previously unselected package libsensors-config.
Preparing to unpack .../118-libsensors-config_1%3a3.6.0-7ubuntu1_all.deb ...
Unpacking libsensors-config (1:3.6.0-7ubuntu1) ...
Selecting previously unselected package libsensors5:amd64.
Preparing to unpack .../119-libsensors5_1%3a3.6.0-7ubuntu1_amd64.deb ...
Unpacking libsensors5:amd64 (1:3.6.0-7ubuntu1) ...
Selecting previously unselected package libgl1-mesa-dri:amd64.
Preparing to unpack .../120-libgl1-mesa-dri_23.2.1-1ubuntu3.1~22.04.2_amd64.deb ...
Unpacking libgl1-mesa-dri:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Selecting previously unselected package libglx-mesa0:amd64.
Preparing to unpack .../121-libglx-mesa0_23.2.1-1ubuntu3.1~22.04.2_amd64.deb ...
Unpacking libglx-mesa0:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Selecting previously unselected package libglx0:amd64.
Preparing to unpack .../122-libglx0_1.4.0-1_amd64.deb ...
Unpacking libglx0:amd64 (1.4.0-1) ...
Selecting previously unselected package libgl1:amd64.
Preparing to unpack .../123-libgl1_1.4.0-1_amd64.deb ...
Unpacking libgl1:amd64 (1.4.0-1) ...
Selecting previously unselected package libiec61883-0:amd64.
Preparing to unpack .../124-libiec61883-0_1.2.0-4build3_amd64.deb ...
Unpacking libiec61883-0:amd64 (1.2.0-4build3) ...
Selecting previously unselected package libjack-jackd2-0:amd64.
Preparing to unpack .../125-libjack-jackd2-0_1.9.20~dfsg-1_amd64.deb ...
Unpacking libjack-jackd2-0:amd64 (1.9.20~dfsg-1) ...
Selecting previously unselected package libopenal-data.
Preparing to unpack .../126-libopenal-data_1%3a1.19.1-2build3_all.deb ...
Unpacking libopenal-data (1:1.19.1-2build3) ...
Selecting previously unselected package libsndio7.0:amd64.
Preparing to unpack .../127-libsndio7.0_1.8.1-1.1_amd64.deb ...
Unpacking libsndio7.0:amd64 (1.8.1-1.1) ...
Selecting previously unselected package libopenal1:amd64.
Preparing to unpack .../128-libopenal1_1%3a1.19.1-2build3_amd64.deb ...
Unpacking libopenal1:amd64 (1:1.19.1-2build3) ...
Selecting previously unselected package libwayland-client0:amd64.
Preparing to unpack .../129-libwayland-client0_1.20.0-1ubuntu0.1_amd64.deb ...
Unpacking libwayland-client0:amd64 (1.20.0-1ubuntu0.1) ...
Selecting previously unselected package libdecor-0-0:amd64.
Preparing to unpack .../130-libdecor-0-0_0.1.0-3build1_amd64.deb ...
Unpacking libdecor-0-0:amd64 (0.1.0-3build1) ...
Selecting previously unselected package libwayland-server0:amd64.
Preparing to unpack .../131-libwayland-server0_1.20.0-1ubuntu0.1_amd64.deb ...
Unpacking libwayland-server0:amd64 (1.20.0-1ubuntu0.1) ...
Selecting previously unselected package libgbm1:amd64.
Preparing to unpack .../132-libgbm1_23.2.1-1ubuntu3.1~22.04.2_amd64.deb ...
Unpacking libgbm1:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Selecting previously unselected package libwayland-cursor0:amd64.
Preparing to unpack .../133-libwayland-cursor0_1.20.0-1ubuntu0.1_amd64.deb ...
Unpacking libwayland-cursor0:amd64 (1.20.0-1ubuntu0.1) ...
Selecting previously unselected package libwayland-egl1:amd64.
Preparing to unpack .../134-libwayland-egl1_1.20.0-1ubuntu0.1_amd64.deb ...
Unpacking libwayland-egl1:amd64 (1.20.0-1ubuntu0.1) ...
Selecting previously unselected package libxcursor1:amd64.
Preparing to unpack .../135-libxcursor1_1%3a1.2.0-2build4_amd64.deb ...
Unpacking libxcursor1:amd64 (1:1.2.0-2build4) ...
Selecting previously unselected package libxi6:amd64.
Preparing to unpack .../136-libxi6_2%3a1.8-1build1_amd64.deb ...
Unpacking libxi6:amd64 (2:1.8-1build1) ...
Selecting previously unselected package libxinerama1:amd64.
Preparing to unpack .../137-libxinerama1_2%3a1.1.4-3_amd64.deb ...
Unpacking libxinerama1:amd64 (2:1.1.4-3) ...
Selecting previously unselected package libxkbcommon0:amd64.
Preparing to unpack .../138-libxkbcommon0_1.4.0-1_amd64.deb ...
Unpacking libxkbcommon0:amd64 (1.4.0-1) ...
Selecting previously unselected package libxrandr2:amd64.
Preparing to unpack .../139-libxrandr2_2%3a1.5.2-1build1_amd64.deb ...
Unpacking libxrandr2:amd64 (2:1.5.2-1build1) ...
Selecting previously unselected package x11-common.
Preparing to unpack .../140-x11-common_1%3a7.7+23ubuntu2_all.deb ...
Unpacking x11-common (1:7.7+23ubuntu2) ...
Selecting previously unselected package libxss1:amd64.
Preparing to unpack .../141-libxss1_1%3a1.2.3-1build2_amd64.deb ...
Unpacking libxss1:amd64 (1:1.2.3-1build2) ...
Selecting previously unselected package libsdl2-2.0-0:amd64.
Preparing to unpack .../142-libsdl2-2.0-0_2.0.20+dfsg-2ubuntu1.22.04.1_amd64.deb ...
Unpacking libsdl2-2.0-0:amd64 (2.0.20+dfsg-2ubuntu1.22.04.1) ...
Selecting previously unselected package libxcb-shape0:amd64.
Preparing to unpack .../143-libxcb-shape0_1.14-3ubuntu3_amd64.deb ...
Unpacking libxcb-shape0:amd64 (1.14-3ubuntu3) ...
Selecting previously unselected package libxv1:amd64.
Preparing to unpack .../144-libxv1_2%3a1.0.11-1build2_amd64.deb ...
Unpacking libxv1:amd64 (2:1.0.11-1build2) ...
Selecting previously unselected package libavdevice58:amd64.
Preparing to unpack .../145-libavdevice58_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking libavdevice58:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package ffmpeg.
Preparing to unpack .../146-ffmpeg_7%3a4.4.2-0ubuntu0.22.04.1_amd64.deb ...
Unpacking ffmpeg (7:4.4.2-0ubuntu0.22.04.1) ...
Selecting previously unselected package libigdgmm12:amd64.
Preparing to unpack .../147-libigdgmm12_22.1.2+ds1-1_amd64.deb ...
Unpacking libigdgmm12:amd64 (22.1.2+ds1-1) ...
Selecting previously unselected package intel-media-va-driver:amd64.
Preparing to unpack .../148-intel-media-va-driver_22.3.1+dfsg1-1ubuntu2_amd64.deb ...
Unpacking intel-media-va-driver:amd64 (22.3.1+dfsg1-1ubuntu2) ...
Selecting previously unselected package libaacs0:amd64.
Preparing to unpack .../149-libaacs0_0.11.1-1_amd64.deb ...
Unpacking libaacs0:amd64 (0.11.1-1) ...
Selecting previously unselected package libbdplus0:amd64.
Preparing to unpack .../150-libbdplus0_0.2.0-1_amd64.deb ...
Unpacking libbdplus0:amd64 (0.2.0-1) ...
Selecting previously unselected package libdecor-0-plugin-1-cairo:amd64.
Preparing to unpack .../151-libdecor-0-plugin-1-cairo_0.1.0-3build1_amd64.deb ...
Unpacking libdecor-0-plugin-1-cairo:amd64 (0.1.0-3build1) ...
Selecting previously unselected package libgdk-pixbuf2.0-bin.
Preparing to unpack .../152-libgdk-pixbuf2.0-bin_2.42.8+dfsg-1ubuntu0.3_amd64.deb ...
Unpacking libgdk-pixbuf2.0-bin (2.42.8+dfsg-1ubuntu0.3) ...
Selecting previously unselected package libgl1-amber-dri:amd64.
Preparing to unpack .../153-libgl1-amber-dri_21.3.9-0ubuntu1~22.04.1_amd64.deb ...
Unpacking libgl1-amber-dri:amd64 (21.3.9-0ubuntu1~22.04.1) ...
Selecting previously unselected package librsvg2-common:amd64.
Preparing to unpack .../154-librsvg2-common_2.52.5+dfsg-3ubuntu0.2_amd64.deb ...
Unpacking librsvg2-common:amd64 (2.52.5+dfsg-3ubuntu0.2) ...
Selecting previously unselected package mesa-va-drivers:amd64.
Preparing to unpack .../155-mesa-va-drivers_23.2.1-1ubuntu3.1~22.04.2_amd64.deb ...
Unpacking mesa-va-drivers:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Selecting previously unselected package mesa-vdpau-drivers:amd64.
Preparing to unpack .../156-mesa-vdpau-drivers_23.2.1-1ubuntu3.1~22.04.2_amd64.deb ...
Unpacking mesa-vdpau-drivers:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Selecting previously unselected package i965-va-driver:amd64.
Preparing to unpack .../157-i965-va-driver_2.4.1+dfsg1-1_amd64.deb ...
Unpacking i965-va-driver:amd64 (2.4.1+dfsg1-1) ...
Selecting previously unselected package va-driver-all:amd64.
Preparing to unpack .../158-va-driver-all_2.14.0-1_amd64.deb ...
Unpacking va-driver-all:amd64 (2.14.0-1) ...
Selecting previously unselected package vdpau-driver-all:amd64.
Preparing to unpack .../159-vdpau-driver-all_1.4-3build2_amd64.deb ...
Unpacking vdpau-driver-all:amd64 (1.4-3build2) ...
Selecting previously unselected package pocketsphinx-en-us.
Preparing to unpack .../160-pocketsphinx-en-us_0.8.0+real5prealpha+1-14ubuntu1_all.deb ...
Unpacking pocketsphinx-en-us (0.8.0+real5prealpha+1-14ubuntu1) ...
Setting up libgme0:amd64 (0.6.3-2) ...
Setting up libssh-gcrypt-4:amd64 (0.9.6-2ubuntu0.22.04.3) ...
Setting up libgraphite2-3:amd64 (1.3.14-1build2) ...
Setting up libsrt1.4-gnutls:amd64 (1.4.4-4) ...
Setting up libxcb-dri3-0:amd64 (1.14-3ubuntu3) ...
Setting up libpixman-1-0:amd64 (0.40.0-1ubuntu0.22.04.1) ...
Setting up libudfread0:amd64 (1.1.2-1) ...
Setting up libwayland-server0:amd64 (1.20.0-1ubuntu0.1) ...
Setting up libaom3:amd64 (3.3.0-1) ...
Setting up libx11-xcb1:amd64 (2:1.7.5-1ubuntu0.3) ...
Setting up libpciaccess0:amd64 (0.16-3) ...
Setting up fontconfig (2.13.1-4.2ubuntu5) ...
Regenerating fonts cache... done.
Setting up librabbitmq4:amd64 (0.10.0-1ubuntu2) ...
Setting up libraw1394-11:amd64 (2.1.2-2build2) ...
Setting up libdrm-nouveau2:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Setting up libcodec2-1.0:amd64 (1.0.1-3) ...
Setting up libmpg123-0:amd64 (1.29.3-1build1) ...
Setting up libxcb-xfixes0:amd64 (1.14-3ubuntu3) ...
Setting up libogg0:amd64 (1.3.5-0ubuntu3) ...
Setting up libspeex1:amd64 (1.2~rc1.2-1.1ubuntu3) ...
Setting up libshine3:amd64 (3.1.1-2) ...
Setting up libcaca0:amd64 (0.99.beta19-2.2ubuntu4) ...
Setting up libxi6:amd64 (2:1.8-1build1) ...
Setting up libtwolame0:amd64 (0.4.0-2build2) ...
Setting up libxrender1:amd64 (1:0.9.10-1build4) ...
Setting up libdatrie1:amd64 (0.2.13-2) ...
Setting up libgsm1:amd64 (1.0.19-1) ...
Setting up libxcb-render0:amd64 (1.14-3ubuntu3) ...
Setting up libsoxr0:amd64 (0.1.3-4build2) ...
Setting up libdrm-radeon1:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Setting up libglvnd0:amd64 (1.4.0-1) ...
Setting up libpgm-5.3-0:amd64 (5.3.128~dfsg-2) ...
Setting up libxcb-glx0:amd64 (1.14-3ubuntu3) ...
Setting up libdrm-intel1:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Setting up libgdk-pixbuf2.0-common (2.42.8+dfsg-1ubuntu0.3) ...
Setting up libnorm1:amd64 (1.5.9+dfsg-2) ...
Setting up libmysofa1:amd64 (1.2.1~dfsg0-1) ...
Setting up libxcb-shape0:amd64 (1.14-3ubuntu3) ...
Setting up x11-common (1:7.7+23ubuntu2) ...
Setting up libsensors-config (1:3.6.0-7ubuntu1) ...
Setting up libxcb-shm0:amd64 (1.14-3ubuntu3) ...
Setting up libigdgmm12:amd64 (22.1.2+ds1-1) ...
Setting up libcdio19:amd64 (2.1.0-3ubuntu0.2) ...
Setting up libxvidcore4:amd64 (2:1.3.7-1) ...
Setting up libcairo2:amd64 (1.16.0-5ubuntu2) ...
Setting up libxxf86vm1:amd64 (1:1.1.4-1build3) ...
Setting up libsnappy1v5:amd64 (1.1.8-1build3) ...
Setting up libflac8:amd64 (1.3.3-2ubuntu0.2) ...
Setting up libxcb-present0:amd64 (1.14-3ubuntu3) ...
Setting up libasound2-data (1.2.6.1-1ubuntu1) ...
Setting up libblas3:amd64 (3.10.0-2ubuntu1) ...
update-alternatives: using /usr/lib/x86_64-linux-gnu/blas/libblas.so.3 to provide /usr/lib/x86_64-linux-gnu/libblas.so.3 (libblas.so.3-x86_64-linux-gnu) in auto mode
Setting up libva2:amd64 (2.14.0-1) ...
Setting up libxfixes3:amd64 (1:6.0.0-1) ...
Setting up libxcb-sync1:amd64 (1.14-3ubuntu3) ...
Setting up libx264-163:amd64 (2:0.163.3060+git5db6aa6-2build1) ...
Setting up libopus0:amd64 (1.3.1-0.1build2) ...
Setting up libxinerama1:amd64 (2:1.1.4-3) ...
Setting up libdc1394-25:amd64 (2.2.6-4) ...
Setting up intel-media-va-driver:amd64 (22.3.1+dfsg1-1ubuntu2) ...
Setting up libxv1:amd64 (2:1.0.11-1build2) ...
Setting up libvorbis0a:amd64 (1.3.7-1build2) ...
Setting up libxrandr2:amd64 (2:1.5.2-1build1) ...
Setting up libsensors5:amd64 (1:3.6.0-7ubuntu1) ...
Setting up libaacs0:amd64 (0.11.1-1) ...
Setting up pocketsphinx-en-us (0.8.0+real5prealpha+1-14ubuntu1) ...
Setting up libglapi-mesa:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Setting up libgfortran5:amd64 (12.3.0-1ubuntu1~22.04) ...
Setting up libx265-199:amd64 (3.5-2) ...
Setting up libxcb-dri2-0:amd64 (1.14-3ubuntu3) ...
Setting up libbdplus0:amd64 (0.2.0-1) ...
Setting up libvidstab1.1:amd64 (1.1.0-2) ...
Setting up alsa-topology-conf (1.2.5.1-2) ...
Setting up libva-drm2:amd64 (2.14.0-1) ...
Setting up ocl-icd-libopencl1:amd64 (2.2.14-3) ...
Setting up libasyncns0:amd64 (0.8-6build2) ...
Setting up libxshmfence1:amd64 (1.3-1build4) ...
Setting up libvdpau1:amd64 (1.4-3build2) ...
Setting up libbs2b0:amd64 (3.1.0+dfsg-2.2build1) ...
Setting up libxcb-randr0:amd64 (1.14-3ubuntu3) ...
Setting up libllvm15:amd64 (1:15.0.7-0ubuntu0.22.04.3) ...
Setting up libtheora0:amd64 (1.1.1+dfsg.1-15ubuntu4) ...
Setting up libasound2:amd64 (1.2.6.1-1ubuntu1) ...
Setting up libzimg2:amd64 (3.0.3+ds1-1) ...
Setting up libopenjp2-7:amd64 (2.4.0-6) ...
Setting up libharfbuzz0b:amd64 (2.7.4-1ubuntu3.1) ...
Setting up libopenal-data (1:1.19.1-2build3) ...
Setting up libthai-data (0.1.29-1build1) ...
Setting up libgdk-pixbuf-2.0-0:amd64 (2.42.8+dfsg-1ubuntu0.3) ...
Setting up libvpx7:amd64 (1.11.0-2ubuntu2.3) ...
Setting up libcairo-gobject2:amd64 (1.16.0-5ubuntu2) ...
Setting up libwayland-egl1:amd64 (1.20.0-1ubuntu0.1) ...
Setting up libxss1:amd64 (1:1.2.3-1build2) ...
Setting up libdav1d5:amd64 (0.9.2-1) ...
Setting up libmfx1:amd64 (22.3.0-1) ...
Setting up libbluray2:amd64 (1:1.3.1-1) ...
Setting up libsamplerate0:amd64 (0.2.2-1build1) ...
Setting up libva-x11-2:amd64 (2.14.0-1) ...
Setting up libwebpmux3:amd64 (1.2.2-2ubuntu0.22.04.2) ...
Setting up libzvbi-common (0.2.35-19) ...
Setting up libmp3lame0:amd64 (3.100-3build2) ...
Setting up i965-va-driver:amd64 (2.4.1+dfsg1-1) ...
Setting up libvorbisenc2:amd64 (1.3.7-1build2) ...
Setting up libiec61883-0:amd64 (1.2.0-4build3) ...
Setting up libserd-0-0:amd64 (0.30.10-2) ...
Setting up libdrm-amdgpu1:amd64 (2.4.113-2~ubuntu0.22.04.1) ...
Setting up libxkbcommon0:amd64 (1.4.0-1) ...
Setting up libwayland-client0:amd64 (1.20.0-1ubuntu0.1) ...
Setting up libavc1394-0:amd64 (0.5.4-5build2) ...
Setting up libgl1-amber-dri:amd64 (21.3.9-0ubuntu1~22.04.1) ...
Setting up mesa-vdpau-drivers:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Setting up libzvbi0:amd64 (0.2.35-19) ...
Setting up liblapack3:amd64 (3.10.0-2ubuntu1) ...
update-alternatives: using /usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3 to provide /usr/lib/x86_64-linux-gnu/liblapack.so.3 (liblapack.so.3-x86_64-linux-gnu) in auto mode
Setting up libzmq5:amd64 (4.3.4-2) ...
Setting up libgbm1:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Setting up alsa-ucm-conf (1.2.6.3-1ubuntu1.11) ...
Setting up libcdio-cdda2:amd64 (10.2+2.0.0-1build3) ...
Setting up libcdio-paranoia2:amd64 (10.2+2.0.0-1build3) ...
Setting up libxcursor1:amd64 (1:1.2.0-2build4) ...
Setting up libgl1-mesa-dri:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Setting up libavutil56:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up libthai0:amd64 (0.1.29-1build1) ...
Setting up libvorbisfile3:amd64 (1.3.7-1build2) ...
Setting up libass9:amd64 (1:0.15.2-1) ...
Setting up libpostproc55:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up librubberband2:amd64 (2.0.0-2) ...
Setting up libsndio7.0:amd64 (1.8.1-1.1) ...
Setting up libjack-jackd2-0:amd64 (1.9.20~dfsg-1) ...
Setting up vdpau-driver-all:amd64 (1.4-3build2) ...
Setting up libflite1:amd64 (2.2-3) ...
Setting up libgdk-pixbuf2.0-bin (2.42.8+dfsg-1ubuntu0.3) ...
Setting up libsord-0-0:amd64 (0.16.8-2) ...
Setting up libwayland-cursor0:amd64 (1.20.0-1ubuntu0.1) ...
Setting up libsratom-0-0:amd64 (0.6.8-1) ...
Setting up libdecor-0-0:amd64 (0.1.0-3build1) ...
Setting up libswscale5:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up libsndfile1:amd64 (1.0.31-2ubuntu0.1) ...
Setting up mesa-va-drivers:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Setting up liblilv-0-0:amd64 (0.24.12-2) ...
Setting up libopenmpt0:amd64 (0.6.1-1) ...
Setting up libglx-mesa0:amd64 (23.2.1-1ubuntu3.1~22.04.2) ...
Setting up libglx0:amd64 (1.4.0-1) ...
Setting up libpulse0:amd64 (1:15.99.1+dfsg1-1ubuntu2.2) ...
Setting up libpango-1.0-0:amd64 (1.50.6+ds-2ubuntu1) ...
Setting up libopenal1:amd64 (1:1.19.1-2build3) ...
Setting up libswresample3:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up libgl1:amd64 (1.4.0-1) ...
Setting up va-driver-all:amd64 (2.14.0-1) ...
Setting up libpangoft2-1.0-0:amd64 (1.50.6+ds-2ubuntu1) ...
Setting up libsdl2-2.0-0:amd64 (2.0.20+dfsg-2ubuntu1.22.04.1) ...
Setting up libpangocairo-1.0-0:amd64 (1.50.6+ds-2ubuntu1) ...
Setting up libsphinxbase3:amd64 (0.8+5prealpha+1-13build1) ...
Setting up librsvg2-2:amd64 (2.52.5+dfsg-3ubuntu0.2) ...
Setting up libpocketsphinx3:amd64 (0.8.0+real5prealpha+1-14ubuntu1) ...
Setting up libdecor-0-plugin-1-cairo:amd64 (0.1.0-3build1) ...
Setting up librsvg2-common:amd64 (2.52.5+dfsg-3ubuntu0.2) ...
Setting up libavcodec58:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up libchromaprint1:amd64 (1.5.1-2) ...
Setting up libavformat58:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up libavfilter7:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up libavdevice58:amd64 (7:4.4.2-0ubuntu0.22.04.1) ...
Setting up ffmpeg (7:4.4.2-0ubuntu0.22.04.1) ...
Processing triggers for man-db (2.10.2-1) ...
Processing triggers for libc-bin (2.35-0ubuntu3.8) ...
Processing triggers for libgdk-pixbuf-2.0-0:amd64 (2.42.8+dfsg-1ubuntu0.3) ...
root@FelippeBarcelos:~# hass
Command 'hass' not found, did you mean:
  command 'cass' from snap cass (0.17.2)
  command 'sass' from deb ruby-sass (3.7.4-5)
  command 'ass' from deb irpas (0.10-9)
  command 'pass' from deb pass (1.7.4-5)
See 'snap info <snapname>' for additional versions.
root@FelippeBarcelos:~# sudo apt install docker.io -y
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  bridge-utils containerd dns-root-data dnsmasq-base pigz runc ubuntu-fan
Suggested packages:
  ifupdown aufs-tools btrfs-progs cgroupfs-mount | cgroup-lite debootstrap docker-doc rinse zfs-fuse
  | zfsutils
The following NEW packages will be installed:
  bridge-utils containerd dns-root-data dnsmasq-base docker.io pigz runc ubuntu-fan
0 upgraded, 8 newly installed, 0 to remove and 2 not upgraded.
Need to get 75.5 MB of archives.
After this operation, 284 MB of additional disk space will be used.
Get:1 http://archive.ubuntu.com/ubuntu jammy/universe amd64 pigz amd64 2.6-1 [63.6 kB]
Get:2 http://archive.ubuntu.com/ubuntu jammy/main amd64 bridge-utils amd64 1.7-1ubuntu3 [34.4 kB]
Get:3 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 runc amd64 1.1.12-0ubuntu2~22.04.1 [8405 kB]
Get:4 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 containerd amd64 1.7.12-0ubuntu2~22.04.1 [37.8 MB]
Get:5 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 dns-root-data all 2023112702~ubuntu0.22.04.1 [5136 B]
Get:6 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 dnsmasq-base amd64 2.90-0ubuntu0.22.04.1 [374 kB]
Get:7 http://archive.ubuntu.com/ubuntu jammy-updates/universe amd64 docker.io amd64 24.0.7-0ubuntu2~22.04.1 [28.8 MB]
Get:8 http://archive.ubuntu.com/ubuntu jammy/universe amd64 ubuntu-fan all 0.12.16 [35.2 kB]
Fetched 75.5 MB in 9s (8657 kB/s)
Preconfiguring packages ...
Selecting previously unselected package pigz.
(Reading database ... 34111 files and directories currently installed.)
Preparing to unpack .../0-pigz_2.6-1_amd64.deb ...
Unpacking pigz (2.6-1) ...
Selecting previously unselected package bridge-utils.
Preparing to unpack .../1-bridge-utils_1.7-1ubuntu3_amd64.deb ...
Unpacking bridge-utils (1.7-1ubuntu3) ...
Selecting previously unselected package runc.
Preparing to unpack .../2-runc_1.1.12-0ubuntu2~22.04.1_amd64.deb ...
Unpacking runc (1.1.12-0ubuntu2~22.04.1) ...
Selecting previously unselected package containerd.
Preparing to unpack .../3-containerd_1.7.12-0ubuntu2~22.04.1_amd64.deb ...
Unpacking containerd (1.7.12-0ubuntu2~22.04.1) ...
Selecting previously unselected package dns-root-data.
Preparing to unpack .../4-dns-root-data_2023112702~ubuntu0.22.04.1_all.deb ...
Unpacking dns-root-data (2023112702~ubuntu0.22.04.1) ...
Selecting previously unselected package dnsmasq-base.
Preparing to unpack .../5-dnsmasq-base_2.90-0ubuntu0.22.04.1_amd64.deb ...
Unpacking dnsmasq-base (2.90-0ubuntu0.22.04.1) ...
Selecting previously unselected package docker.io.
Preparing to unpack .../6-docker.io_24.0.7-0ubuntu2~22.04.1_amd64.deb ...
Unpacking docker.io (24.0.7-0ubuntu2~22.04.1) ...
Selecting previously unselected package ubuntu-fan.
Preparing to unpack .../7-ubuntu-fan_0.12.16_all.deb ...
Unpacking ubuntu-fan (0.12.16) ...
Setting up dnsmasq-base (2.90-0ubuntu0.22.04.1) ...
Setting up runc (1.1.12-0ubuntu2~22.04.1) ...
Setting up dns-root-data (2023112702~ubuntu0.22.04.1) ...
Setting up bridge-utils (1.7-1ubuntu3) ...
Setting up pigz (2.6-1) ...
Setting up containerd (1.7.12-0ubuntu2~22.04.1) ...
Created symlink /etc/systemd/system/multi-user.target.wants/containerd.service → /lib/systemd/system/containerd.service.
Setting up ubuntu-fan (0.12.16) ...
Created symlink /etc/systemd/system/multi-user.target.wants/ubuntu-fan.service → /lib/systemd/system/ubuntu-fan.service.
Setting up docker.io (24.0.7-0ubuntu2~22.04.1) ...
Adding group `docker' (GID 117) ...
Done.
Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /lib/systemd/system/docker.service.
Created symlink /etc/systemd/system/sockets.target.wants/docker.socket → /lib/systemd/system/docker.socket.
Processing triggers for dbus (1.12.20-2ubuntu4.1) ...
Processing triggers for man-db (2.10.2-1) ...
root@FelippeBarcelos:~# docker run -d --name="home-assistant" -v /PATH/TO/YOUR/CONFIG:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
Unable to find image 'ghcr.io/home-assistant/home-assistant:stable' locally
stable: Pulling from home-assistant/home-assistant
ec99f8b99825: Pulling fs layer
646e6dcaa5b7: Pulling fs layer
73e1eb350c1a: Pulling fs layer
97d3806ade9e: Pull complete                                                                                 34ebc1ea44b1: Pull complete                                                                                 ed4e8a19ee2c: Pull complete                                                                                 336ca7becc6d: Pull complete                                                                                 653d69934b4c: Pull complete                                                                                 5ba3b532f81d: Pull complete
02bde6288692: Pull complete
3a1babaa696b: Pull complete
4f4fb700ef54: Pull complete
e70acd9eaa1f: Pull complete
ae8fefb95e53: Pull complete
576319a08591: Pull complete
af28b2de3924: Pull complete
ba70ad012f9d: Pull complete
2b0132918317: Pull complete
f8f60cab2146: Pull complete
3ea74062b1b4: Pull complete
f4034d54319d: Pull complete                                                                                 ad9dce0ec540: Pull complete
b67be43e7ce5: Pull complete
261ab9d0e501: Pull complete
85c61a3e215c: Pull complete
ebdeb52d6084: Pull complete
72f78db726bc: Pull complete
bf760d3a182b: Pull complete
7a0d0623d03a: Pull complete
6e35f8b6f805: Pull complete
Digest: sha256:49501c175b6108e94d20a723e6a991a14389454374eba06b2c6833b1315e34b5
Status: Downloaded newer image for ghcr.io/home-assistant/home-assistant:stable
d0a3b9d7ae300c01726746af8a0b7ebe3b3f8ad5c943194e00bf32bc35f038ed
root@FelippeBarcelos:~#"

---

### ASSISTENTE

Parece que você esqueceu de substituir `/PATH/TO/YOUR/CONFIG` pelo caminho do seu diretório de configuração e `YOUR_TIMEZONE` pelo seu fuso horário. Para corrigir isso, siga os seguintes passos:

1. **Identifique o Diretório de Configuração e o Fuso Horário**:
   - Determine qual é o caminho correto para o seu diretório de configuração (geralmente algo como `/home/seu_usuario/.config` ou `/etc/seu_programa`).
   - Verifique o fuso horário que você deve usar (por exemplo, `America/Sao_Paulo`).

2. **Execute o Comando Corrigido**:
   - Utilize o comando novamente, desta vez substituindo as variáveis pelos valores corretos. Por exemplo:
   ```bash
   export CONFIG_PATH="/caminho/do/seu/diretorio/de/configuracao"
   export TIMEZONE="America/Sao_Paulo"
   ```

3. **Corrija Qualquer Erro**:
   - Caso tenha executado algum comando sem as substituições corretas, não há necessidade de preocupação imediata, apenas execute o comando novamente com as substituições corrigidas.
   
4. **Verifique a Instalação do `hass`**:
   - Se o comando `hass` não foi encontrado, é possível que o Home Assistant ainda não esteja instalado ou configurado corretamente. Para instalar o Home Assistant usando Docker (como parece estar configurado), execute:
   ```bash
   sudo docker run --init -d --name="homeassistant" -e "TZ=America/Sao_Paulo" -v /PATH/TO/YOUR/CONFIG:/config --net=host ghcr.io/home-assistant/home-assistant:stable
   ```

Substitua `/PATH/TO/YOUR/CONFIG` pelo caminho correto do diretório de configuração e `"TZ=America/Sao_Paulo"` pelo seu fuso horário.

Se precisar de mais ajuda para configurar o Home Assistant ou corrigir os comandos, é só me avisar!

---

### USUÁRIO

como encontrar esse caminho correto para o diretorio de configuração

---

### ASSISTENTE

Para encontrar o caminho correto do diretório de configuração do Home Assistant (ou outro aplicativo similar que você está instalando), siga estes passos:

### 1. **Verifique o Local Padrão do Diretório de Configuração:**

Se você está instalando o Home Assistant, o diretório de configuração geralmente está localizado em:

- **Linux**: `/home/username/.homeassistant` ou `/root/.homeassistant`
- **Docker**: Pode ser especificado no comando `docker run` usando a flag `-v` (volume). Normalmente, é algo como `/home/username/homeassistant/config`.

### 2. **Use o Comando `find`:**

Execute o comando abaixo para procurar o diretório de configuração no sistema:

```bash
sudo find / -name "homeassistant" -type d 2>/dev/null
```

Este comando irá procurar por todos os diretórios com o nome "homeassistant". Pode demorar um pouco, dependendo do tamanho do seu sistema de arquivos.

### 3. **Verifique a Documentação ou Configuração do Seu Ambiente:**

- **Docker:** Se você instalou o Home Assistant usando Docker, o caminho do diretório de configuração é definido no comando de execução do Docker com a opção `-v`. Revise o comando que você usou para executar o contêiner Docker.
  
  Por exemplo:
  ```bash
  docker run -d --name="home-assistant" -v /caminho/do/config:/config -v /etc/localtime:/etc/localtime:ro --net=host homeassistant/home-assistant
  ```

  Aqui, `/caminho/do/config` é onde o diretório de configuração está localizado.

- **Virtualenv ou Instalação Nativa:** Se você instalou o Home Assistant diretamente no sistema operacional (não via Docker), o diretório geralmente está em `~/.homeassistant`.

### 4. **Verifique Variáveis de Ambiente:**

Se você está usando Docker ou outra forma de implantação, pode haver variáveis de ambiente configuradas que definem o diretório de configuração. Verifique com o comando:

```bash
echo $HOME
```

Este comando exibirá o caminho do seu diretório pessoal, e o diretório de configuração normalmente estará em algum subdiretório dentro dele.

### 5. **Instalação Padrão do Home Assistant:**

Caso o Home Assistant tenha sido instalado de maneira padrão em Linux, o diretório de configuração padrão será geralmente em `/home/SEU_USUARIO/.homeassistant`. Para visualizar este diretório, você pode usar:

```bash
ls -la /home/SEU_USUARIO/.homeassistant
```

Substitua `SEU_USUARIO` pelo nome de usuário apropriado.

### 6. **Verifique o Arquivo de Configuração Existente:**

Uma vez encontrado o diretório de configuração, você pode usar comandos como `ls` ou `cd` para navegar até ele e garantir que o arquivo `configuration.yaml` (ou equivalente) esteja presente.

### Resumo

Use os métodos acima para encontrar o caminho correto para o diretório de configuração. Assim que o encontrar, substitua `/PATH/TO/YOUR/CONFIG` pelo caminho exato no seu comando original.

---

### USUÁRIO

root@FelippeBarcelos:~# docker run -d --name="home-assistant" -v /PATH/TO/YOUR/CONFIG:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
Unable to find image 'ghcr.io/home-assistant/home-assistant:stable' locally
stable: Pulling from home-assistant/home-assistant
ec99f8b99825: Pulling fs layer
646e6dcaa5b7: Pulling fs layer
73e1eb350c1a: Pulling fs layer
97d3806ade9e: Pull complete                                                                                 34ebc1ea44b1: Pull complete                                                                                 ed4e8a19ee2c: Pull complete                                                                                 336ca7becc6d: Pull complete                                                                                 653d69934b4c: Pull complete                                                                                 5ba3b532f81d: Pull complete
02bde6288692: Pull complete
3a1babaa696b: Pull complete
4f4fb700ef54: Pull complete
e70acd9eaa1f: Pull complete
ae8fefb95e53: Pull complete
576319a08591: Pull complete
af28b2de3924: Pull complete
ba70ad012f9d: Pull complete
2b0132918317: Pull complete
f8f60cab2146: Pull complete
3ea74062b1b4: Pull complete
f4034d54319d: Pull complete                                                                                 ad9dce0ec540: Pull complete
b67be43e7ce5: Pull complete
261ab9d0e501: Pull complete
85c61a3e215c: Pull complete
ebdeb52d6084: Pull complete
72f78db726bc: Pull complete
bf760d3a182b: Pull complete
7a0d0623d03a: Pull complete
6e35f8b6f805: Pull complete
Digest: sha256:49501c175b6108e94d20a723e6a991a14389454374eba06b2c6833b1315e34b5
Status: Downloaded newer image for ghcr.io/home-assistant/home-assistant:stable
d0a3b9d7ae300c01726746af8a0b7ebe3b3f8ad5c943194e00bf32bc35f038ed
root@FelippeBarcelos:~# sudo find / -name "homeassistant" -type d 2>/dev/null
/root/.homeassistant/blueprints/script/homeassistant
/root/.homeassistant/blueprints/automation/homeassistant
/root/homeassistant
/root/homeassistant/homeassistant
/root/homeassistant/homeassistant/lib/python3.11/site-packages/homeassistant
/root/homeassistant/homeassistant/lib/python3.11/site-packages/homeassistant/components/homeassistant
/root/homeassistant/lib/python3.10/site-packages/homeassistant
/root/homeassistant/lib/python3.10/site-packages/homeassistant/components/homeassistant
/root/homeassistant/lib/python3.10/site-packages/home_assistant_intents/data/homeassistant
/var/lib/docker/overlay2/477c4ef3c5866883f2035c887047b4973072a7024959fdf457da727ab6374117/diff/usr/src/homeassistant
/var/lib/docker/overlay2/477c4ef3c5866883f2035c887047b4973072a7024959fdf457da727ab6374117/diff/usr/src/homeassistant/homeassistant
/var/lib/docker/overlay2/477c4ef3c5866883f2035c887047b4973072a7024959fdf457da727ab6374117/diff/usr/src/homeassistant/homeassistant/components/homeassistant
/var/lib/docker/overlay2/4fcc10e530ccb120e4615ae56aad6f2196590e2dc92587c52fd5d73bb77c34c3/diff/usr/src/homeassistant
/var/lib/docker/overlay2/c5d9bc4c89a0f19676f3b110f423fcfdc4fc521e7354bee40a4ed7f7ceb2559c/diff/root/.cache/uv/archive-v0/0W4l0CeGvBkyaWZdhPaY-/zigpy/quirks/v2/homeassistant
/var/lib/docker/overlay2/c5d9bc4c89a0f19676f3b110f423fcfdc4fc521e7354bee40a4ed7f7ceb2559c/diff/usr/local/lib/python3.12/site-packages/zigpy/quirks/v2/homeassistant
/var/lib/docker/overlay2/be3acb63dded4150314d83ba538c8aa3bd22b8babf9e37548021a0161ed87176/merged/root/.cache/uv/archive-v0/0W4l0CeGvBkyaWZdhPaY-/zigpy/quirks/v2/homeassistant
/var/lib/docker/overlay2/be3acb63dded4150314d83ba538c8aa3bd22b8babf9e37548021a0161ed87176/merged/usr/local/lib/python3.12/site-packages/zigpy/quirks/v2/homeassistant
/var/lib/docker/overlay2/be3acb63dded4150314d83ba538c8aa3bd22b8babf9e37548021a0161ed87176/merged/usr/src/homeassistant
/var/lib/docker/overlay2/be3acb63dded4150314d83ba538c8aa3bd22b8babf9e37548021a0161ed87176/merged/usr/src/homeassistant/homeassistant
/var/lib/docker/overlay2/be3acb63dded4150314d83ba538c8aa3bd22b8babf9e37548021a0161ed87176/merged/usr/src/homeassistant/homeassistant/components/homeassistant
/var/lib/docker/overlay2/322fadc78268573e8ed84ffb39655a55c66ccf9233fb1c3f90a59a5f1658d1ad/diff/usr/src/homeassistant
/var/lib/docker/overlay2/322fadc78268573e8ed84ffb39655a55c66ccf9233fb1c3f90a59a5f1658d1ad/diff/usr/src/homeassistant/homeassistant
/var/lib/docker/overlay2/8d4e81fb89b769071ff90b4aff2cd1e0c2a2f4a8727360e935f4a9fe2822bea3/diff/usr/src/homeassistant
/var/lib/docker/overlay2/7c97761259f512550a03af9059a14e7b6b1d159c17b3981a545e4160d34db1bb/diff/usr/src/homeassistant
/var/lib/docker/overlay2/7c97761259f512550a03af9059a14e7b6b1d159c17b3981a545e4160d34db1bb/diff/usr/src/homeassistant/homeassistant
/var/lib/docker/overlay2/7c97761259f512550a03af9059a14e7b6b1d159c17b3981a545e4160d34db1bb/diff/usr/src/homeassistant/homeassistant/components/homeassistant


---

### ASSISTENTE

Com base nos resultados do comando `find`, o diretório de configuração do Home Assistant que você deve usar provavelmente é um dos seguintes:

1. **/root/.homeassistant**: Este é o diretório padrão usado para configurações locais do Home Assistant quando instalado diretamente no ambiente de usuário "root". 

2. **/root/homeassistant**: Este também é um possível diretório de configuração, mas parece ser mais um diretório de instalação do Python.

Para usar o diretório de configuração correto ao executar o contêiner Docker, você deve especificar o caminho onde deseja armazenar suas configurações.

### Modifique o Comando Docker

Você pode alterar o comando Docker para usar o diretório correto:

```bash
docker run -d --name="home-assistant" -v /root/.homeassistant:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
```

### Explicação:

- **`-v /root/.homeassistant:/config`**: Isto monta o diretório `/root/.homeassistant` no contêiner Docker como `/config`, onde o Home Assistant espera encontrar seu diretório de configuração.
- **`-e "TZ=YOUR_TIMEZONE"`**: Substitua `"YOUR_TIMEZONE"` pelo seu fuso horário (ex.: "America/Sao_Paulo").

### Verifique o Resultado

Depois de executar o comando, você pode verificar se o Home Assistant está funcionando corretamente e acessando o diretório de configuração:

1. **Acesse os Logs do Contêiner:**
   ```bash
   docker logs home-assistant
   ```
2. **Verifique a Pasta de Configuração:**
   Acesse o diretório `/root/.homeassistant` e veja se arquivos como `configuration.yaml` foram criados ou atualizados.

Essas etapas devem garantir que o Home Assistant use o diretório de configuração correto no seu ambiente.

---

### USUÁRIO

root@FelippeBarcelos:~# docker run -d --name="home-assistant" -v /root/.homeassistant:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
docker: Error response from daemon: Conflict. The container name "/home-assistant" is already in use by container "d0a3b9d7ae300c01726746af8a0b7ebe3b3f8ad5c943194e00bf32bc35f038ed". You have to remove (or rename) that container to be able to reuse that name.
See 'docker run --help'.
root@FelippeBarcelos:~#

---

### ASSISTENTE

O erro que você recebeu indica que já existe um contêiner com o nome `"home-assistant"`. Para resolver isso, você tem duas opções:

### Opção 1: Remover o Contêiner Existente

Se você não precisa do contêiner antigo, pode removê-lo com o seguinte comando:

```bash
docker rm -f home-assistant
```

Em seguida, execute novamente o comando `docker run`:

```bash
docker run -d --name="home-assistant" -v /root/.homeassistant:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
```

### Opção 2: Renomear o Novo Contêiner

Se você deseja manter o contêiner existente, pode simplesmente renomear o novo contêiner para um nome diferente:

```bash
docker run -d --name="home-assistant-new" -v /root/.homeassistant:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
```

Substitua `"home-assistant-new"` pelo nome que preferir.

### Verificar Contêineres em Execução

Você também pode verificar quais contêineres estão em execução com:

```bash
docker ps -a
```

Isso mostrará todos os contêineres, incluindo aqueles que não estão em execução, para ajudar a decidir se você deseja parar, remover ou renomear algum contêiner.

---

### USUÁRIO

root@FelippeBarcelos:~# docker run -d --name="home-assistant" -v /root/.homeassistant:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
docker: Error response from daemon: Conflict. The container name "/home-assistant" is already in use by container "d0a3b9d7ae300c01726746af8a0b7ebe3b3f8ad5c943194e00bf32bc35f038ed". You have to remove (or rename) that container to be able to reuse that name.
See 'docker run --help'.
root@FelippeBarcelos:~# docker rm -f home-assistant
home-assistant
root@FelippeBarcelos:~# docker run -d --name="home-assistant" -v /root/.homeassistant:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
9600ac1c1ea3c83a5b67d756aad51b7d85a5fa22c3f0eaf9fa7fb8bc0e176e83
root@FelippeBarcelos:~# docker run -d --name="home-assistant-new" -v /root/.homeassistant:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
b0e54117e0d6ab4a70dd75c663c579aa22dfe695500fa6e26834d9d0df61f221
root@FelippeBarcelos:~# docker ps -a
CONTAINER ID   IMAGE                                          COMMAND   CREATED          STATUS          PORTS     NAMES
b0e54117e0d6   ghcr.io/home-assistant/home-assistant:stable   "/init"   13 seconds ago   Up 12 seconds             home-assistant-new
9600ac1c1ea3   ghcr.io/home-assistant/home-assistant:stable   "/init"   22 seconds ago   Up 21 seconds             home-assistant
root@FelippeBarcelos:~#

---

### ASSISTENTE

Parece que agora você tem dois contêineres do Home Assistant em execução: um chamado `home-assistant` e outro chamado `home-assistant-new`. Ambos estão rodando simultaneamente. Se isso é intencional, você pode mantê-los assim. No entanto, se você pretende usar apenas um, pode parar e remover o que não for necessário.

### Se Desejar Remover um dos Contêineres

Para parar e remover um dos contêineres, por exemplo, `home-assistant-new`, use os comandos abaixo:

```bash
docker stop home-assistant-new
docker rm home-assistant-new
```

Ou, se desejar remover o outro contêiner (`home-assistant`):

```bash
docker stop home-assistant
docker rm home-assistant
```

### Continuar com a Configuração

Se ambos os contêineres estão configurados corretamente e você deseja mantê-los, não há mais nada que precise ser feito. No entanto, certifique-se de que o diretório de configuração (`/root/.homeassistant`) esteja configurado corretamente e que o fuso horário (`TZ=YOUR_TIMEZONE`) esteja definido para o valor apropriado, como `America/Sao_Paulo` para o horário de Brasília, por exemplo:

```bash
-e "TZ=America/Sao_Paulo"
```

---

### USUÁRIO

root@FelippeBarcelos:~# docker run -d --name="home-assistant" -v /root/.homeassistant:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
docker: Error response from daemon: Conflict. The container name "/home-assistant" is already in use by container "d0a3b9d7ae300c01726746af8a0b7ebe3b3f8ad5c943194e00bf32bc35f038ed". You have to remove (or rename) that container to be able to reuse that name.
See 'docker run --help'.
root@FelippeBarcelos:~# docker rm -f home-assistant
home-assistant
root@FelippeBarcelos:~# docker run -d --name="home-assistant" -v /root/.homeassistant:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
9600ac1c1ea3c83a5b67d756aad51b7d85a5fa22c3f0eaf9fa7fb8bc0e176e83
root@FelippeBarcelos:~# docker run -d --name="home-assistant-new" -v /root/.homeassistant:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
b0e54117e0d6ab4a70dd75c663c579aa22dfe695500fa6e26834d9d0df61f221
root@FelippeBarcelos:~# docker ps -a
CONTAINER ID   IMAGE                                          COMMAND   CREATED          STATUS          PORTS     NAMES
b0e54117e0d6   ghcr.io/home-assistant/home-assistant:stable   "/init"   13 seconds ago   Up 12 seconds             home-assistant-new
9600ac1c1ea3   ghcr.io/home-assistant/home-assistant:stable   "/init"   22 seconds ago   Up 21 seconds             home-assistant
root@FelippeBarcelos:~# docker stop home-assistant-new
docker rm home-assistant-new
home-assistant-new
home-assistant-new
root@FelippeBarcelos:~#

---

### ASSISTENTE

Agora que você parou e removeu o contêiner `home-assistant-new`, apenas o contêiner `home-assistant` está em execução. Se este é o resultado desejado, você está no caminho certo!

### Verificar Status do Contêiner

Para garantir que o contêiner `home-assistant` esteja funcionando corretamente, execute o comando abaixo:

```bash
docker ps
```

Isso mostrará uma lista de contêineres em execução. Certifique-se de que `home-assistant` esteja listado como "Up" e sem erros.

### Ajustar o Timezone

Se ainda não tiver ajustado o fuso horário para o seu contêiner do Home Assistant, você pode parar o contêiner atual e iniciá-lo novamente com o fuso horário correto:

1. Pare e remova o contêiner atual:

```bash
docker stop home-assistant
docker rm home-assistant
```

2. Execute o contêiner novamente com o fuso horário correto (substitua `"America/Sao_Paulo"` pelo seu fuso horário, se necessário):

```bash
docker run -d --name="home-assistant" -v /root/.homeassistant:/config -e "TZ=America/Sao_Paulo" --net=host ghcr.io/home-assistant/home-assistant:stable
```

### Verificar Logs do Contêiner

Para verificar os logs e garantir que o Home Assistant esteja funcionando corretamente, você pode usar:

```bash
docker logs home-assistant
```

Isso mostrará a saída do contêiner e ajudará a identificar se há algum erro durante a execução. 

Se precisar de mais alguma ajuda ou tiver outra dúvida, estou à disposição!

---

### USUÁRIO

root@FelippeBarcelos:~# docker run -d --name="home-assistant" -v /root/.homeassistant:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
docker: Error response from daemon: Conflict. The container name "/home-assistant" is already in use by container "d0a3b9d7ae300c01726746af8a0b7ebe3b3f8ad5c943194e00bf32bc35f038ed". You have to remove (or rename) that container to be able to reuse that name.
See 'docker run --help'.
root@FelippeBarcelos:~# docker rm -f home-assistant
home-assistant
root@FelippeBarcelos:~# docker run -d --name="home-assistant" -v /root/.homeassistant:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
9600ac1c1ea3c83a5b67d756aad51b7d85a5fa22c3f0eaf9fa7fb8bc0e176e83
root@FelippeBarcelos:~# docker run -d --name="home-assistant-new" -v /root/.homeassistant:/config -e "TZ=YOUR_TIMEZONE" --net=host ghcr.io/home-assistant/home-assistant:stable
b0e54117e0d6ab4a70dd75c663c579aa22dfe695500fa6e26834d9d0df61f221
root@FelippeBarcelos:~# docker ps -a
CONTAINER ID   IMAGE                                          COMMAND   CREATED          STATUS          PORTS     NAMES
b0e54117e0d6   ghcr.io/home-assistant/home-assistant:stable   "/init"   13 seconds ago   Up 12 seconds             home-assistant-new
9600ac1c1ea3   ghcr.io/home-assistant/home-assistant:stable   "/init"   22 seconds ago   Up 21 seconds             home-assistant
root@FelippeBarcelos:~# docker stop home-assistant-new
docker rm home-assistant-new
home-assistant-new
home-assistant-new
root@FelippeBarcelos:~# docker ps
CONTAINER ID   IMAGE                                          COMMAND   CREATED              STATUS              PORTS     NAMES
9600ac1c1ea3   ghcr.io/home-assistant/home-assistant:stable   "/init"   About a minute ago   Up About a minute             home-assistant
root@FelippeBarcelos:~# docker stop home-assistant
docker rm home-assistant
home-assistant
home-assistant
root@FelippeBarcelos:~# docker run -d --name="home-assistant" -v /root/.homeassistant:/config -e "TZ=America/Sao_Paulo" --net=host ghcr.io/home-assistant/home-assistant:stable
0884d3956a307748070a8c0df5efb33257f3cb35b96a8295ff7a17b3f36e87bc
root@FelippeBarcelos:~# docker logs home-assistant
s6-rc: info: service s6rc-oneshot-runner: starting
s6-rc: info: service s6rc-oneshot-runner successfully started
s6-rc: info: service fix-attrs: starting
s6-rc: info: service fix-attrs successfully started
s6-rc: info: service legacy-cont-init: starting
s6-rc: info: service legacy-cont-init successfully started
s6-rc: info: service legacy-services: starting
services-up: info: copying legacy longrun home-assistant (no readiness notification)
s6-rc: info: service legacy-services successfully started
root@FelippeBarcelos:~#

---

### ASSISTENTE

Parece que agora o contêiner `home-assistant` está em execução corretamente! Aqui está o que você fez até agora:

1. **Parou e removeu o contêiner existente** para evitar o conflito de nomes.
2. **Executou um novo contêiner** do Home Assistant com o nome "home-assistant", montando o volume de configuração correto e definindo o fuso horário como "America/Sao_Paulo".
3. Verificou os logs do contêiner, que indicam que o Home Assistant está iniciando sem erros aparentes.

### Verificar se o Home Assistant está Funcionando

Para garantir que o Home Assistant está totalmente funcional:

1. **Acesse o Home Assistant** no navegador da web.
   - Se estiver rodando localmente, você deve conseguir acessar a interface web do Home Assistant no endereço: `http://localhost:8123` ou `http://<IP_DO_SEU_SERVIDOR>:8123`.

2. **Verifique os Logs de Execução**:
   - Continue monitorando os logs com o comando:
     ```bash
     docker logs -f home-assistant
     ```
   - Isso permitirá que você veja as mensagens de inicialização em tempo real.

3. **Configuração e Inicialização**:
   - A primeira vez que o Home Assistant é iniciado pode levar alguns minutos, especialmente se houver componentes adicionais para baixar ou configurar.

### O Próximo Passo

Se tudo estiver funcionando corretamente, você deve ser capaz de continuar configurando o Home Assistant conforme necessário através da interface web. Caso encontre problemas adicionais ou tenha mais perguntas, sinta-se à vontade para perguntar!

---

### USUÁRIO

Após buscar no chrome: "http://localhost:8123" abriu uma página do home assistant.
Quando executei no ubuntu "docker logs -f home-assistant"
resultou em:
root@FelippeBarcelos:~# docker run -d --name="home-assistant" -v /root/.homeassistant:/config -e "TZ=America/Sao_Paulo" --net=host ghcr.io/home-assistant/home-assistant:stable
0884d3956a307748070a8c0df5efb33257f3cb35b96a8295ff7a17b3f36e87bc
root@FelippeBarcelos:~# docker logs home-assistant
s6-rc: info: service s6rc-oneshot-runner: starting
s6-rc: info: service s6rc-oneshot-runner successfully started
s6-rc: info: service fix-attrs: starting
s6-rc: info: service fix-attrs successfully started
s6-rc: info: service legacy-cont-init: starting
s6-rc: info: service legacy-cont-init successfully started
s6-rc: info: service legacy-services: starting
services-up: info: copying legacy longrun home-assistant (no readiness notification)
s6-rc: info: service legacy-services successfully started
root@FelippeBarcelos:~# docker logs -f home-assistant
s6-rc: info: service s6rc-oneshot-runner: starting
s6-rc: info: service s6rc-oneshot-runner successfully started
s6-rc: info: service fix-attrs: starting
s6-rc: info: service fix-attrs successfully started
s6-rc: info: service legacy-cont-init: starting
s6-rc: info: service legacy-cont-init successfully started
s6-rc: info: service legacy-services: starting
services-up: info: copying legacy longrun home-assistant (no readiness notification)
s6-rc: info: service legacy-services successfully started

---

### ASSISTENTE

Ótimo! A página do Home Assistant abriu no seu navegador, o que significa que o contêiner está em execução e o Home Assistant foi iniciado com sucesso.

Os logs que você forneceu indicam que todos os serviços internos do Home Assistant foram iniciados corretamente:

- **s6-rc: info**: Mensagens relacionadas ao sistema de inicialização interno (s6) do contêiner indicam que todos os serviços necessários foram iniciados com sucesso.
- **No readiness notification**: É uma mensagem padrão e não indica um erro. O Home Assistant pode levar alguns minutos para carregar completamente na primeira execução.

### Próximos Passos

1. **Configuração Inicial**:
   - Complete a configuração inicial do Home Assistant através da interface web. Isso incluirá a criação de uma conta de usuário e a configuração de dispositivos ou integrações.

2. **Monitoramento de Logs**:
   - Continue monitorando os logs do Docker com o comando `docker logs -f home-assistant` para identificar se há mensagens de erro ou advertências que precisem de atenção.

3. **Explorar Integrations**:
   - Acesse a seção "Configurações" e depois "Dispositivos e Serviços" para adicionar integrações com dispositivos ou serviços adicionais que você deseja controlar com o Home Assistant.

4. **Manter o Contêiner Atualizado**:
   - Sempre verifique se há atualizações para o Home Assistant e atualize o contêiner quando necessário.

Se tiver outras dúvidas ou precisar de mais ajuda, sinta-se à vontade para perguntar!

---

### USUÁRIO

para configurar e cadastrar nossa placa esp32-wroom-32 conectada ao sensor bme280 no Home Assistant como prossigo? necessitaremos mais do ubuntu?

---

### ASSISTENTE

Para configurar e cadastrar sua placa ESP32-WROOM-32 conectada ao sensor BME280 no Home Assistant, você precisará seguir alguns passos específicos para integrar o dispositivo com o Home Assistant. Vamos fazer isso usando o **ESPHome**, uma plataforma que facilita a configuração de dispositivos baseados em ESP (como o ESP32) para trabalharem com o Home Assistant.

### Passos para Configurar o ESP32 com o Sensor BME280 no Home Assistant

#### 1. Instalar o ESPHome no Home Assistant

1. **Abra o Home Assistant**: No navegador, acesse `http://localhost:8123` (ou o endereço IP correspondente do seu servidor Home Assistant).
   
2. **Vá para o Supervisor**:
   - Acesse a seção **"Supervisor"** na barra lateral.
   - Clique em **"Add-on Store"**.

3. **Instale o Add-on ESPHome**:
   - Procure por **ESPHome** na loja de add-ons e clique em **"Install"**.
   - Depois de instalado, clique em **"Start"** para iniciar o add-on.

#### 2. Conectar o ESP32 ao Computador

1. **Conecte a Placa ESP32 ao Computador**:
   - Conecte sua placa ESP32-WROOM-32 ao seu computador usando um cabo USB. Certifique-se de que o cabo suporte dados, não apenas carregamento.

2. **Acesse o ESPHome**:
   - No Home Assistant, vá para o ESPHome na seção "Supervisor".
   - Clique em **"Open Web UI"**.

#### 3. Configurar o ESP32 para Usar o Sensor BME280

1. **Adicionar um Novo Dispositivo no ESPHome**:
   - Clique em **"New Device"**.
   - Siga o assistente de configuração e escolha um nome para o seu dispositivo (por exemplo, "esp32-sensor").
   - Selecione **"ESP32"** como a plataforma do dispositivo.
   - Escolha o método de conexão inicial (conexão serial).

2. **Configurar o Sensor BME280 no ESPHome**:
   - Depois de criar o dispositivo, você será levado para o editor de configuração YAML. Adicione a configuração para o sensor BME280:

```yaml
esphome:
  name: esp32-sensor
  platform: ESP32
  board: esp32dev

wifi:
  ssid: "SEU_SSID"
  password: "SUA_SENHA"

# Enable logging
logger:

# Enable Home Assistant API
api:
  password: "SUA_SENHA_API"

ota:
  password: "SUA_SENHA_OTA"

i2c:
  sda: 21
  scl: 22
  scan: True

sensor:
  - platform: bme280
    temperature:
      name: "Temperatura BME280"
      oversampling: 16x
    pressure:
      name: "Pressão BME280"
    humidity:
      name: "Umidade BME280"
    address: 0x76
    update_interval: 60s
```

- **`i2c`**: Ajuste os pinos SDA e SCL de acordo com a sua conexão (os pinos 21 e 22 são comuns para o ESP32).
- **`sensor`**: Configuração do sensor BME280, incluindo a leitura de temperatura, pressão e umidade.

#### 4. Compilar e Flashear o ESP32

1. **Compilar o Código**:
   - Clique em **"Install"** para compilar o código.
   
2. **Selecionar o Método de Instalação**:
   - Escolha **"Plug into this computer"** e siga as instruções para instalar o firmware na sua placa ESP32 conectada via USB.

#### 5. Conectar o ESP32 ao Home Assistant

1. **Após o Flash Completo**:
   - O dispositivo ESP32 começará a se comunicar com o Home Assistant via Wi-Fi.
   - Você deve ver o novo dispositivo "esp32-sensor" na seção de dispositivos do Home Assistant.

#### 6. Monitorar e Testar o Sensor

1. **Monitore os Dados do Sensor**:
   - Acesse o painel do Home Assistant e veja os dados em tempo real do sensor BME280.

### Ubuntu é Necessário?

O Ubuntu (ou qualquer outro sistema operacional) é necessário apenas para:

- Configurar o Home Assistant e o ESPHome.
- Conectar fisicamente o ESP32 ao computador para o primeiro flash de firmware.

Uma vez configurado, o dispositivo ESP32 funcionará de forma autônoma e se comunicará diretamente com o Home Assistant via Wi-Fi. Portanto, o Ubuntu não será mais necessário depois que o ESP32 estiver configurado e em execução.

Se precisar de mais ajuda ou detalhes em qualquer etapa, é só avisar!

---

### USUÁRIO

Antes de prosseguir, qual ficou o caminho do diretorio do home assistant?

---

### ASSISTENTE

Pelo comando que você utilizou para iniciar o Home Assistant no Docker, o diretório de configuração do Home Assistant foi mapeado para o diretório local `/root/.homeassistant` do seu Ubuntu.

Portanto, o caminho do diretório de configuração do Home Assistant é:

```
/root/.homeassistant
```

Este é o local onde todos os arquivos de configuração, logs, e outros dados do Home Assistant serão armazenados. Você pode acessar esse diretório diretamente no seu Ubuntu para editar arquivos de configuração, como o `configuration.yaml`.

---

### USUÁRIO

Perfeito, agora me resuma o nosso progresso obtido até agora para saber todas as config e especificações do nosso projeto

---

### ASSISTENTE

**Resumo do Progresso Obtido até Agora no Projeto:**

1. **Instalação do Home Assistant via Docker:**
   - Utilizamos o Docker para rodar o Home Assistant em um contêiner.
   - O comando usado para iniciar o contêiner foi:
     ```bash
     docker run -d --name="home-assistant" -v /root/.homeassistant:/config -e "TZ=America/Sao_Paulo" --net=host ghcr.io/home-assistant/home-assistant:stable
     ```
   - O diretório de configuração do Home Assistant foi definido como `/root/.homeassistant`.
   - Confirmamos que o Home Assistant está em execução ao acessar a página "http://localhost:8123" no navegador.

2. **Configuração do Ambiente de Execução:**
   - Verificamos os logs do contêiner do Home Assistant para garantir que o serviço foi iniciado corretamente.
   - O ambiente de execução está no Ubuntu, com o Docker instalado e em funcionamento.

3. **Configuração da Placa ESP32 com Sensor BME280:**
   - Planejamos conectar uma placa ESP32-WROOM-32 ao sensor BME280 para monitorar temperatura, umidade e pressão atmosférica.
   - A integração será feita utilizando o Home Assistant para monitoramento em tempo real.
   - Identificamos que o próximo passo é configurar o Home Assistant para se comunicar com a placa ESP32 utilizando o ESPHome ou MQTT.

4. **Próximos Passos para o Projeto:**
   - Configurar o **ESPHome** no Home Assistant para adicionar e integrar o ESP32-WROOM-32.
   - Configurar a comunicação entre o sensor BME280 e o ESP32, com suporte do Home Assistant.
   - Realizar o **flash** do firmware na placa ESP32 para que ela possa enviar dados ao Home Assistant.

**Especificações e Configurações Atuais:**

- **Servidor Home Assistant:**
  - Rodando em Docker no Ubuntu.
  - Diretório de configuração: `/root/.homeassistant`.
  - Fuso horário configurado: `America/Sao_Paulo`.

- **Hardware:**
  - Placa microcontroladora: **ESP32-WROOM-32**.
  - Sensor de ambiente: **BME280** (monitoramento de temperatura, umidade e pressão).

- **Ferramentas de Integração:**
  - Home Assistant para monitoramento centralizado.
  - Planejado uso de **ESPHome** para facilitar a integração e configuração do ESP32.
  - Alternativamente, o uso de **MQTT** pode ser considerado para comunicação de dados em tempo real.

---

**O que Precisamos Fazer a Seguir:**

1. **Configurar o ESPHome**:
   - Acessar o Home Assistant e instalar o addon do ESPHome.
   - Criar uma nova configuração de dispositivo para o ESP32-WROOM-32 no ESPHome.
   - Configurar os parâmetros de Wi-Fi e o código necessário para o BME280 no ESPHome.

2. **Preparar o ESP32:**
   - Conectar o ESP32 ao computador e flashar o firmware gerado pelo ESPHome.
   - Testar a conectividade do ESP32 com o Home Assistant.

3. **Monitoramento e Testes:**
   - Verificar se os dados do sensor BME280 estão sendo enviados corretamente ao Home Assistant.
   - Ajustar as configurações de notificação e automação conforme necessário no Home Assistant.

Com esses próximos passos, estaremos prontos para monitorar as leituras do sensor BME280 diretamente no Home Assistant, permitindo um acompanhamento em tempo real das condições ambientais monitoradas pelo ESP32.

---

