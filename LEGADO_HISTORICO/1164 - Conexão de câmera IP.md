# 1164 - Conexão de câmera IP

### USUÁRIO

Chat acredito que estou enfrentando limitações para encontrar a partir do app intelbras isic do meu computador windows conectado no modem via ethernet conectado então no wifi 5g, a camera ip jortan conectada ao modem pelo wifi 2.4g 

---

### ASSISTENTE

A dificuldade que você está enfrentando provavelmente se deve ao fato de o app Intelbras iSIC, no computador conectado via Ethernet, estar tentando acessar uma câmera IP Jortan que está em uma rede diferente (Wi-Fi 2.4 GHz) em relação ao computador (Wi-Fi 5 GHz). Isso pode impedir o alcance da câmera, já que muitos roteadores tratam redes de 2.4 GHz e 5 GHz como segmentos de rede diferentes.

Aqui estão algumas ações que podem ajudar a resolver essa limitação:

1. **Verifique o isolamento entre as redes Wi-Fi**: Alguns roteadores mantêm redes de 2.4 GHz e 5 GHz isoladas para segurança, o que impede que dispositivos em frequências diferentes se comuniquem. No painel de configurações do seu roteador, procure pela opção de “Isolamento entre redes” (ou “AP Isolation”) e desative-a se estiver ativada.

2. **Conecte-se à mesma rede Wi-Fi**: Para confirmar se o problema é de isolamento, conecte temporariamente o computador à mesma rede Wi-Fi 2.4 GHz à qual a câmera Jortan está conectada. Isso pode revelar se as redes estão realmente isoladas.

3. **Verifique as configurações de VLAN**: Alguns roteadores configuram automaticamente VLANs para as frequências 2.4 GHz e 5 GHz. Certifique-se de que ambos os segmentos de rede estejam na mesma VLAN.

4. **Endereço IP fixo para a câmera**: Configure um endereço IP fixo para a câmera Jortan no painel do roteador. Isso pode facilitar a localização da câmera pelo software Intelbras iSIC.

5. **Testes de Ping e Verificação de Conexão**: Para verificar a comunicação, você pode tentar um teste de ping do computador para o IP da câmera. Se o teste não responder, isso confirma um problema de comunicação entre as redes.

Essas ações podem ajudar a identificar ou resolver o problema de conexão entre seu computador e a câmera IP.

---

