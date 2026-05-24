# 1759 - Amperagem saída USB-C

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'file-service://file-WTgJs5cpU5QCeTWSvXEoyR', 'size_bytes': 153414, 'width': 706, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

A imagem mostra uma extensão (filtro de linha) com 5 tomadas padrão brasileiro, 4 portas USB e 1 porta USB-C, além de um botão liga/desliga. No entanto, **as especificações exatas de saída de corrente (amperagem) das portas USB e USB-C não estão indicadas diretamente na imagem**.

### Possibilidades técnicas (com base em modelos similares)
Com base em produtos semelhantes no mercado, seguem as especificações **prováveis** para esse tipo de extensão:

- **Portas USB (cada uma)**:
  - Saída típica: **5V / 1A a 5V / 2.1A**
  - Em conjunto, muitas vezes compartilham uma saída total de **5V / 3.1A ou 5V / 4.2A**
- **Porta USB-C**:
  - Em produtos mais simples, muitas vezes também é **5V / 2A ou 5V / 3A**
  - Não costuma oferecer Power Delivery (PD) real, a menos que especificado

> ⚠️ **A amperagem total costuma ser compartilhada entre as portas.** Isso significa que, ao conectar vários dispositivos simultaneamente, a corrente é dividida entre eles, podendo resultar em carregamento mais lento.

### Como descobrir com precisão
Para garantir as informações corretas, recomendo:

1. Verificar a **descrição completa do anúncio** no Mercado Livre (rolando para baixo).
2. Conferir a parte traseira da régua (se tiver imagem ou após recebê-la), onde geralmente consta a saída em volts/amperes.
3. Perguntar diretamente ao **vendedor no campo de perguntas** do anúncio com algo como:
   > “Qual a corrente máxima (em Amperes) da saída USB e USB-C? Elas são compartilhadas?”

Se desejar, posso ajudar a redigir uma pergunta precisa ao vendedor para obter essa confirmação técnica. Deseja?

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'file-service://file-3uVGyfHUbUi9GbHe5oXUxN', 'size_bytes': 212135, 'width': 706, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Com base nas **especificações fornecidas na imagem**, a extensão com 5 tomadas e 4 portas USB + 1 Tipo C apresenta as seguintes saídas:

---

### 📌 **Especificações Relevantes para Alimentação USB**
- **Saída USB-A:** `5V / 2.1A` (total ou por porta, não especificado — presume-se total compartilhado)
- **Bivolt:** 110V / 220V
- **Sem menção a USB-C com Power Delivery (PD)**

---

## 🔎 **O problema de looping infinito no Mi TV Stick (e similares)**

### Causa:
Usuários relatam que o **Mi TV Stick e o Mi TV Stick 4K** entram em **loop de reinicialização (boot loop)** quando **a fonte de alimentação é insuficiente em amperagem ou instável**, principalmente em portas USB de TVs, extensões genéricas ou carregadores fracos.

---

### 💥 Padrão mínimo recomendado pela Xiaomi:
- **Tensão:** 5V
- **Corrente mínima:** **1A (para o básico)**  
- **Corrente ideal (para evitar reinícios, lags e problemas):** **5V / 2A** ou superior  
- Em alguns casos (uso com dongle bluetooth, HDMI CEC ativado, etc.), o ideal é **5V / 2.5A**

---

### 🧠 Análise da extensão mostrada:

A porta USB-A tem saída **de até 2.1A**, o que **teoricamente é suficiente** para o Mi TV Stick. No entanto:

1. **Essa corrente provavelmente é compartilhada** entre todas as 4 portas USB-A.
2. Se **outras portas estiverem em uso**, a corrente disponível para o Mi TV Stick pode cair para **menos de 1A**.
3. Isso **provoca boot loop**, principalmente quando o sistema tenta iniciar o Wi-Fi ou atualizar.

---

## ✅ **Conclusão técnica**

🔴 **Risco real de looping infinito?**  
**Sim**, existe **risco considerável** se:

- Outras portas USB estiverem sendo usadas simultaneamente;
- O cabo USB for de baixa qualidade ou muito longo (gerando queda de tensão);
- O Mi TV Stick estiver executando algo pesado ou atualizando.

✅ **Recomendação segura**:

- Use um **adaptador de tomada dedicado com saída 5V / 2A ou superior**, como:
  - Fonte original de celular (Samsung, Motorola etc.)
  - Carregador de qualidade com saída exclusiva de 2A+

---

### ⚠️ Dica adicional

Se quiser usar essa extensão, **não conecte mais nada nas outras portas USB**, e de preferência use a **porta USB-C**, **caso ela entregue 2A ou mais** (mas isso não está garantido nas especificações).

Deseja que eu formule um teste simples para confirmar se a extensão pode ou não alimentar o Mi TV Stick de forma confiável antes de colocá-lo em uso permanente?

---

