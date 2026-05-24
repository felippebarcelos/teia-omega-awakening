# 1982 - Como ligar sem queimar

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'file-service://file-6zu3gcQBSd2tFQogwkhWD7', 'size_bytes': 3772114, 'width': 1152, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

A imagem mostra uma **placa de distribuição USB com relé**, frequentemente usada para **carregamento múltiplo** ou controle remoto de portas USB via relé. Essa placa é popular em projetos de automação com microcontroladores como Arduino ou ESP8266/ESP32.

---

### ⚠️ **Atenção: risco de queima**
Antes de ligar a placa, é crucial identificar:

- **Tensão de entrada correta** (geralmente 5V ou 12V DC, depende do modelo)
- **Polaridade dos fios**
- **Função de cada terminal (alimentação, saída, controle do relé)**

---

### 🧩 Componentes identificados:

- **Portas USB**: 4 portas (provavelmente 5V de saída).
- **Relé azul**: usado para chavear a energia das USBs.
- **Capacitores eletrolíticos**: indicam necessidade de alimentação estabilizada.
- **Conector terminal (à esquerda)**: com marcações “N” e “L”, pode ser para entrada AC **(atenção: perigo de choque elétrico)**.
- **Módulo buck ou regulador linear**: parece reduzir a tensão de entrada.
- **Fio verde**: conectado próximo a “L” ou “N”, pode estar entrando tensão inadequada se não for bem definido.
- **Conector USB-C e micro USB**: podem ser entradas alternativas de energia (ex: 5V DC via powerbank).

---

### ✅ **Como ligar com segurança (modo seguro via USB)**

**Se sua intenção é alimentar por USB e não usar energia AC**, siga esta abordagem:

1. **Ignore a entrada AC (marcada com "N" e "L")** – não conecte nada nesses pontos, especialmente se não tiver certeza se é 127/220V.
2. **Conecte um cabo USB-C ou micro-USB** em uma fonte de 5V confiável (ex: carregador de celular ou powerbank).
3. Observe se o LED acende (indicando que o relé ou a placa estão operacionais).
4. **Teste a saída de tensão nas portas USB** com multímetro (devem fornecer 5V).
5. **Somente após isso**, conecte dispositivos consumidores de energia.

---

### ⚙️ **Se for alimentar com fonte externa (modo relé AC)**

Se quiser usar **entrada AC** (linha e neutro):

1. **Verifique na placa ou manual** a tensão de entrada (geralmente 220V ou 110V).
2. **Conecte os fios verde/azul conforme especificado**:  
   - “N” = Neutro  
   - “L” = Fase  
   Use apenas com conhecimento elétrico ou auxílio técnico.
3. **Certifique-se de que o relé está dimensionado para essa tensão**.
4. O relé pode estar controlando a distribuição da energia para as portas USB, ligando ou desligando via controle digital ou botão físico.

---

### 📌 Recomendações finais

- **Use multímetro antes de qualquer conexão.**
- **Evite ligar diretamente em tomada AC sem saber a tensão e o projeto da placa.**
- **Evite alimentar pela entrada “N/L” se a fonte principal for um carregador USB** — isso pode causar curto.
- Se não tiver certeza, **alimente pelo conector USB-C (mais seguro)** e use apenas as portas USB como saídas.

---

Se quiser, posso fazer uma **análise elétrica detalhada com esquema de ligação**, caso envie:

- Foto do **verso da placa**
- Modelo ou código serigrafado
- Objetivo exato (carregar celulares, controlar com microcontrolador, etc.)

Deseja que eu monte um diagrama de ligação simplificado ou script de controle para microcontrolador (ESP32/Arduino)?

---

