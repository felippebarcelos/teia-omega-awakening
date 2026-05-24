# 1972 - Análise de extensão elétrica

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'file-service://file-6TfixBvJW1xbormh3kTE7p', 'size_bytes': 461844, 'width': 1152, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Felippe, analisando tanto sua descrição detalhada quanto as imagens, consigo apontar alguns pontos críticos e a provável causa do problema, além de sugerir como prosseguir de forma segura.

---

## 🔍 Análise da Situação

1. **Ausência de Terra Funcional**
   - Apesar do plugue ter três pinos, o pino de terra não está conectado internamente.
   - Isso compromete a segurança, principalmente para equipamentos metálicos ou de alta potência, pois não há caminho seguro para descarga de falhas.

2. **Interruptor Queimado / Derretido**
   - Pelas fotos (principalmente 2ª e 3ª), o ponto de solda próximo ao interruptor derreteu parte da carcaça plástica.
   - Isso indica **superaquecimento local**, provavelmente por mau contato, excesso de corrente ou solda mal fixada, causando aumento da resistência e consequente calor.

3. **LED e Resistores**
   - O LED é alimentado por um pequeno circuito em ponte com o neutro/fase.
   - Qualquer inversão ou solda mal feita pode deixá-lo apagado mesmo com energia presente.

4. **Sensação de “Tensão” ao Tocar**
   - Isso pode indicar **fuga de corrente** devido à ausência de terra e à possível indução do neutro/fase para a carcaça metálica interna (as lâminas das tomadas).
   - É comum em filtros de linha baratos, mas aqui é agravado porque houve modificação e perda do isolamento original.

5. **Derretimento do Pino da Tomada**
   - Isso é sintoma de **mau contato** entre pino e tomada ou excesso de corrente.
   - Pode ter ocorrido pelo breve arco elétrico ao conectar/desconectar, agravado por conexões internas instáveis.

---

## ⚠️ Possível Causa

A soma de:
- **Remoção do interruptor** (mudança no caminho da corrente),
- **Soldas refeitas** próximas ao plástico (sem dissipação de calor e sem isolamento adequado),
- **Ausência de aterramento**,
- **Possível inversão de fase/neutro** durante a remontagem,

…resultou em uma situação onde há fuga de tensão e risco de arco elétrico nos pinos.

---

## 🛠️ Como Prosseguir com Segurança

1. **Parar de Testar Direto na Rede**
   - Não conecte novamente na tomada até garantir isolamento e continuidade corretos.

2. **Refazer a Conexão**
   - Substituir completamente o interruptor por um **conector ou borne isolado** em vez de solda direta em plástico.
   - Usar solda estanho-estanho com ferro limpo, e **isolar com termo-retrátil**.
   - Garantir que fase e neutro passem direto para as lâminas das tomadas internas e para a placa USB, mantendo a polaridade original.

3. **Verificar Continuidade e Isolamento**
   - Usar multímetro para:
     - Testar continuidade **somente** entre fase-fase e neutro-neutro.
     - Garantir que não há continuidade entre fase/neutro e terra.
     - Testar resistência infinita (modo ohmímetro) entre fase e neutro antes de energizar.

4. **Aterramento**
   - Se quiser manter o pino de terra funcional, é preciso **ligá-lo mecanicamente às chapas metálicas** das tomadas internas, usando fio verde 2,5mm².

5. **Testar com Lâmpada Série**
   - Antes de ligar direto na rede, teste com uma lâmpada incandescente em série (100W). Se houver curto, a lâmpada acende forte e evita explosão ou derretimento.

---

## 📌 Observação Importante
Pela extensão já ter sinais de queima e modificações, **o ideal é substituir por uma nova**, principalmente se for usada para eletrônicos caros.  
Essa adaptação pode funcionar, mas continuará **sem a segurança do aterramento original** e com risco de fuga de corrente perceptível ao toque.

---

Se quiser, posso te desenhar um **esquema de ligação segura** para:
- Bypass do interruptor,
- Preservar polaridade,
- Ativar o terra de forma funcional.  

Isso minimiza o risco e mantém a extensão usável. Quer que eu faça esse diagrama?

---

