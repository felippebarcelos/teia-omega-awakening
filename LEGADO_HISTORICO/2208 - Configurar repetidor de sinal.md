# 2208 - Configurar repetidor de sinal

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000039061f78eb7f3a86dc8c552', 'size_bytes': 380318, 'width': 1152, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Perfeito, Felippe — o dispositivo das imagens é um **Wireless-N Repeater** genérico, usado para ampliar o sinal Wi-Fi existente.  
Abaixo está o **guia completo e funcional para configurá-lo**, mesmo que seja a primeira vez.

---

## ⚙️ Passo a Passo de Configuração (Modo Repetidor)

### 🔹 1. Conecte o repetidor à tomada
- Espere cerca de **1 minuto** até os LEDs estabilizarem (Power e Wi-Fi devem ficar acesos).

---

### 🔹 2. Conecte-se à rede do repetidor
No seu celular ou notebook:
- Vá para as **Configurações de Wi-Fi**.  
- Procure e conecte-se à rede chamada algo como:
  ```
  WiFi-Repeater
  Wireless-N
  ```
- Essa rede **não tem senha** por padrão.

---

### 🔹 3. Acesse o painel de configuração
Abra o navegador e digite na barra de endereço:
```
http://192.168.10.1
```
Se não abrir, tente:
```
http://192.168.10.254
```

> ⚠️ Importante: o IP padrão informado na etiqueta é **192.168.10.1**.

Quando o painel abrir, aparecerá uma tela pedindo login.

---

### 🔹 4. Faça login
Use as credenciais padrão:
```
Usuário: admin
Senha: admin
```

---

### 🔹 5. Selecione o modo “Repeater”
Na tela inicial, escolha:
```
Repeater Mode (Range Extender)
```

---

### 🔹 6. Escolha sua rede Wi-Fi principal
- O repetidor vai procurar as redes próximas.  
- Selecione **a sua rede Wi-Fi original** (aquela do seu roteador principal).
- Insira **a senha correta dessa rede**.

Você pode definir um **novo nome (SSID)** para o repetidor ou deixar o mesmo — por exemplo:
```
MinhaRede_EXT
```

---

### 🔹 7. Salve e aguarde o reinício
- Clique em **Apply** ou **Save**.  
- O repetidor vai reiniciar (leva cerca de 1-2 minutos).  
- Depois disso, ele se conectará à sua rede Wi-Fi principal.

---

### 🔹 8. Reconecte-se à nova rede
Após o reinício:
- Desconecte do “WiFi-Repeater”.
- Conecte-se à rede configurada, por exemplo “MinhaRede_EXT”.
- A senha será **a mesma** da rede principal.

---

## 💡 Dicas Importantes
- Se o acesso ao painel não funcionar, **pressione o botão RESET** (buraco pequeno na lateral) por **10 s** com um clip e recomece.  
- Idealmente, coloque o repetidor **a meio caminho entre o roteador e a área com sinal fraco**.  
- LEDs:
  - **Power**: ligado fixo → energia OK  
  - **Wi-Fi**: piscando → conexão em andamento  
  - **LAN/WAN**: aceso → conectado à rede  

---

Quer que eu te mostre também como configurar **via cabo LAN** (modo Access Point ou Bridge, direto no notebook)?  
Posso gerar o passo-a-passo PowerShell/Windows para abrir e configurar automaticamente o painel.

---

