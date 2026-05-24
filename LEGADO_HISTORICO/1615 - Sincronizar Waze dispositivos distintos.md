# 1615 - Sincronizar Waze dispositivos distintos

### USUÁRIO

Há alguma forma do aplicativo Waze instalado no tablet multimídia que não possui conexão Apple CarPlay sintonizar com as configurações em tempo real do Waze com a mesma conta porém do meu celular onde ao abrir o aplicativo Waze pelo multimídia se o multimídia estiver conectado ao Wi-Fi carrega a página iniciada de rota pelo smartphone conectado à minha conta?

---

### ASSISTENTE

Atualmente, o **Waze não oferece sincronização em tempo real entre dispositivos diferentes** (como um smartphone e um tablet multimídia) apenas com base no login na mesma conta. Ou seja, **a rota iniciada no seu celular não aparece automaticamente no app Waze do tablet**, mesmo se ambos estiverem conectados à mesma conta e à internet via Wi-Fi.

No entanto, há algumas alternativas e possibilidades que podem **aproximar-se dessa experiência**:

---

### 1. **Sincronização via histórico de navegação e favoritos**
Se os dois dispositivos estiverem conectados à **mesma conta Waze**, o **histórico de navegação, locais favoritos e destinos salvos** são compartilhados. Isso **não inclui rotas ativas**, mas permite que você selecione o mesmo destino no segundo dispositivo com mais agilidade.

**Limitações**:
- Não sincroniza automaticamente a rota em andamento.
- Você precisa iniciar manualmente a navegação no tablet.

---

### 2. **Envio manual de locais do smartphone para o tablet**
Não é possível “enviar” rotas diretamente de um smartphone para um tablet dentro do Waze. Mas existem soluções alternativas:

#### a) **Usar links de localização**
- No smartphone, toque no destino e compartilhe via link.
- Envie esse link via e-mail ou mensageiro (como WhatsApp Web ou Telegram) acessível no tablet.
- Abra o link no navegador do tablet e selecione abrir com o Waze.

#### b) **Aplicativos de automação**
Se você for avançado em automação, pode usar plataformas como **IFTTT** ou **Tasker (Android)** para tentar sincronizar eventos de navegação, mas isso exige configuração técnica elevada e não há garantia de integração com o Waze.

---

### 3. **Usar espelhamento ou screen cast**
Se seu tablet multimídia permite:
- **Espelhar a tela do celular via Wi-Fi ou Bluetooth** (com apps como **Screen Stream**, **Scrcpy**, ou **Android Auto Wireless** com adaptações), você poderia apenas controlar o Waze no celular e visualizar no tablet.
- Isso **não é nativo do Waze**, mas funciona como solução de contorno visual e funcional.

---

### 4. **Waze no Android Auto (sem CarPlay)**
Se o tablet multimídia for Android e **suporta Android Auto**, pode haver alguma forma de emparelhar o Waze do celular com o sistema do carro por essa via, mesmo que não tenha CarPlay. Mas é um cenário específico e requer suporte nativo ao Android Auto.

---

### Considerações Finais
- **O Waze prioriza a navegação local ao dispositivo**, por isso não transmite rotas entre dispositivos.
- Para sincronização profunda e fluída, seria necessário um recurso nativo ainda inexistente no app.
- Para sua necessidade de mobilidade e continuidade, talvez uma arquitetura personalizada com base em **roteadores Wi-Fi embarcados**, **distribuição de internet entre dispositivos via tethering**, e automações com **Deep Links Waze** possa ser uma solução híbrida a considerar.

Se quiser, posso esboçar um fluxo arquitetônico personalizado ou um módulo para sua TEIA com essa integração. Deseja seguir por esse caminho?

---

