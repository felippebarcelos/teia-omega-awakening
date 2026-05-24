# 2396 - Imprimir com Tailscale VPN

### USUÁRIO

como colocar a impressora hp deskjet ink 2700 no tailscale vpn para conseguir imprimir daonde quiser com o meu celular que já está na vpn?

---

### ASSISTENTE

【turn0calculator0】 1+1 = 2

---

### ASSISTENTE

Você não consegue instalar o Tailscale direto na HP 2700 (ela não roda apps), então o truque é colocar **a sua rede onde está a impressora** dentro da VPN, usando um **“subnet router” do Tailscale**. Aí o seu celular (que já está na VPN) enxerga a impressora como se estivesse em casa. citeturn1search2turn1search8turn1search18  

Vou montar o passo a passo mais direto possível.

---

## Visão geral

Você vai precisar de:

1. Sua impressora HP Deskjet Ink 2700 ligada e conectada ao Wi-Fi de casa.
2. Um dispositivo que fique **sempre ligado em casa** (PC/Notebook/mini-PC/Raspberry Pi ou um roteador compatível) com Tailscale instalado.
3. Seu celular com o app do Tailscale (que você já tem) + app de impressão (HP Smart / serviço de impressão).

Esse dispositivo “sempre ligado” vira o **gateway** (subnet router) que expõe a rede 192.168.x.x onde a impressora está, para dentro da VPN. citeturn1search0turn1search3turn1search19  

---

## 1. Descobrir o IP da impressora e fixar

1. Certifique-se de que a HP 2700 está conectada ao **Wi-Fi do seu roteador**, não em Wi-Fi Direct.
2. Pelo app **HP Smart** ou pelo painel do roteador, descubra o IP da impressora, tipo:
   - `192.168.0.50` ou `192.168.1.23` etc.
3. No roteador, se possível, crie uma **reserva de DHCP** para que a impressora fique sempre com o mesmo IP (opcional, mas muito recomendado).

Anote:
- IP da impressora: `192.168.X.Y`
- Faixa da rede: normalmente `192.168.0.0/24` ou `192.168.1.0/24`.

---

## 2. Escolher o “gateway” do Tailscale

Você tem duas opções principais:

### Opção A – PC/Notebook/mini-PC ou Raspberry Pi

Use um computador que fica em casa sempre ligado (ou pelo menos ligado quando você quer imprimir). Nele você vai:

1. Instalar o app do **Tailscale**.
2. Logar com sua conta (mesma tailnet do celular).
3. Configurar esse dispositivo como **subnet router**, anunciando a rede da impressora (por ex. `192.168.0.0/24`). citeturn1search0turn1search2turn1search12  

### Opção B – Roteador compatível

Se seu roteador for algo como **OpenWrt / pfSense / Mikrotik / Asuswrt-Merlin / GL.iNet**, muitos já suportam Tailscale. A configuração é parecida: instalar o cliente do Tailscale no roteador e anunciar a rede local como rota. citeturn1search12turn1search19  

Se você não tiver certeza, considere a Opção A (PC ou Raspberry Pi), que é mais simples.

---

## 3. Configurar o subnet router no Tailscale

### 3.1. Instalar e logar

No dispositivo escolhido (PC/Notebook/Pi/roteador compatível):

1. Instale o cliente Tailscale.
2. Faça login na mesma conta que você usa no celular.
3. Confirme que esse novo dispositivo aparece na lista de máquinas na sua conta Tailscale (painel web).

### 3.2. Anunciar a rede da impressora (subnet routes)

Resumo do que precisa acontecer (independente do sistema):

1. No dispositivo gateway, habilitar o modo **subnet router** e anunciar a rede local (ex.: `192.168.0.0/24`).
2. No painel web do Tailscale, aprovar essa rota. citeturn1search0turn1search3turn1search12  

Exemplos rápidos:

- **Windows / macOS**  
  Hoje dá para fazer muita coisa direto pela interface web:
  1. Vá em `https://login.tailscale.com` → Machines.
  2. Clique no dispositivo gateway.
  3. Em “Subnet router” (ou “Route settings”), coloque sua faixa local, por ex.:  
     `192.168.0.0/24`
  4. Clique em **Advertise routes / Save**.
  5. Se aparecer “pending”, aprove nas configurações da tailnet.

- **Linux / Raspberry Pi (linha de comando)** citeturn1search0turn1search17  
  Algo do tipo:
  ```bash
  sudo tailscale up --advertise-routes=192.168.0.0/24
  ```
  (A faixa precisa bater com a da sua rede.)

Depois disso, qualquer dispositivo na sua tailnet (incluindo o celular) passa a ter rota para a rede 192.168.x.x onde está a impressora.

---

## 4. Fazer o celular enxergar a impressora pela VPN

Com o celular já conectado ao Tailscale (tailnet ativa):

1. Teste se você consegue **abrir o painel web da impressora pelo IP**:
   - No celular, abra o navegador.
   - Acesse `http://192.168.X.Y` (o IP anotado).
   - Se abrir a página da HP, a rota está funcionando.

2. Agora, configure a impressão:

### Android

Você tem duas opções:

1. **HP Smart**  
   - Abra o app HP Smart.
   - Toque em “Adicionar impressora”.
   - Em vez de deixar ele procurar só por Wi-Fi local, veja se há opção “Adicionar por endereço IP” ou similar e use `192.168.X.Y`.

2. **Sistema de impressão do Android**  
   - Configurações → Dispositivos conectados / Conexão → Impressão (varia conforme o Android).
   - Ative o plugin **HP Print Service Plugin**.
   - Procure opção “Adicionar impressora por IP” e cadastre `192.168.X.Y`.

Enquanto o Tailscale estiver conectado, os apps que usam essa impressora devem conseguir mandar trabalhos pra ela.

### iPhone (iOS)

- O AirPrint depende de descoberta local (mDNS), que às vezes não atravessa VPN direito.  
- Use o app **HP Smart** e tente adicionar a impressora pelo IP (`192.168.X.Y`). Se o HP Smart conseguir falar com a impressora, você imprime por ele (ou via “Compartilhar” → HP Smart em outros apps).

Se, mesmo com ping funcionando, o sistema não achar a impressora, você ainda pode:

---

## 5. Plano B: usar um PC como “servidor de impressão”

Se o método IP direto der trabalho, há outro jeito:

1. No PC em casa:
   - Instale a impressora normalmente (USB ou Wi-Fi).
   - Confirme que você consegue imprimir localmente.

2. Instale Tailscale nesse PC (se ainda não estiver).

3. Do celular:
   - Conecte ao Tailscale.
   - Use **Remote Desktop** (por ex. Microsoft Remote Desktop) para entrar no PC via VPN.
   - Abra o documento no PC remoto e mande imprimir pela impressora local.

É menos elegante, mas funciona em praticamente qualquer cenário porque o PC vira o “cérebro” da impressão, e o Tailscale só conecta você ao PC. citeturn1search5turn1search16  

---

## 6. Pontos importantes

- Se o **gateway (PC/Pi/roteador)** estiver desligado, a impressora some da VPN.
- Verifique nas **ACLs** do Tailscale se não há regra bloqueando o acesso do celular ao subnet router ou à faixa 192.168.x.x. citeturn1search12turn1search20  
- Em casa, o padrão geralmente já é “todos falam com todos”, mas se você mexeu em permissões, vale revisar.

---

Se você quiser, posso montar um passo a passo ainda mais específico do tipo:

- “Tenho Windows 10 ligado em casa” → comando e cliques exatos.
- “Tenho Raspberry Pi” → linha de comando exata pra virar subnet router.

---

