# 1182 - Métodos de conexão Yoosee

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'file-service://file-oF9LyErQ7Rpv9DTAIMc9b4Op', 'size_bytes': 113458, 'width': 1009, 'height': 1537, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Na interface que você compartilhou, os métodos de conexão disponíveis, como "Cloud", "Domain", "IP address" e "Extra IP", podem ser compatíveis com dispositivos que oferecem transmissão de vídeo por protocolos padrão, como o protocolo RTSP, utilizado por câmeras Yoosee. O método mais direto seria utilizar o endereço IP e a porta TCP correta, configurando o usuário e senha que correspondem à câmera Yoosee.

Recomendo verificar se a câmera Yoosee está configurada para acesso remoto via IP ou domínio (DDNS), garantindo que a porta esteja aberta no roteador para transmissão, e se o modo de transmissão RTSP está habilitado. Essa configuração permitirá que você veja as imagens da câmera usando o IP público ou domínio dinâmico associado.

---

### USUÁRIO

Como descobrir a porta TCP correta que o aplicativo usa?

---

### ASSISTENTE

Para descobrir a porta TCP correta que o aplicativo da câmera Yoosee usa, você pode seguir alguns métodos:

1. **Verifique a Documentação da Câmera**: Muitas vezes, o manual ou a documentação online da câmera Yoosee menciona as portas padrão usadas para transmissão. Normalmente, as câmeras IP usam portas como 554 (RTSP), 80 (HTTP), ou outras específicas do fabricante.

2. **Ajustes do Aplicativo Yoosee**: Verifique se o aplicativo Yoosee possui configurações avançadas ou informações de rede. Em algumas versões, o aplicativo exibe a porta utilizada para transmissão ao configurar o acesso remoto.

3. **Acesso ao Roteador**: Se a câmera está conectada ao seu roteador, acesse as configurações do roteador e vá para a seção de "Dispositivos Conectados" ou "Port Forwarding". Alguns roteadores exibem as portas abertas pelos dispositivos conectados, o que pode indicar qual porta a câmera Yoosee está usando.

4. **Usar um Scanner de Portas**:
   - **No Computador**: Se você tiver o IP da câmera, use um scanner de portas (como o Nmap) para verificar as portas abertas. Por exemplo, com o Nmap, você pode executar o comando:
     ```
     nmap -p 1-65535 <IP_da_câmera>
     ```
     Esse comando escaneará todas as portas e indicará quais estão abertas.
   - **No Celular**: Existem aplicativos de escaneamento de portas que podem fazer o mesmo, como o "Fing" (disponível para iOS e Android). Conecte-se na mesma rede Wi-Fi da câmera e escaneie as portas abertas no IP correspondente.

5. **Verifique as Configurações de Rede da Câmera**: Algumas câmeras possuem uma interface de administração acessível via navegador (ex.: digitando o IP da câmera no navegador). Caso a Yoosee ofereça essa interface, as configurações de rede geralmente exibem a porta de serviço ativa.

6. **Entre em Contato com o Suporte Yoosee**: Se os métodos acima não funcionarem, o suporte técnico Yoosee pode informar qual porta padrão é usada por seu dispositivo ou ajudá-lo a identificá-la.

Essas portas são essenciais para configurar o acesso remoto e assegurar que a transmissão funcione corretamente.

---

