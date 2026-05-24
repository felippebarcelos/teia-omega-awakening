# 1540 - Alexa Sensor Furto Investigação

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'file-service://file-H7yGMxxdZnnad9EW25miU7', 'size_bytes': 2508235, 'width': 1152, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

A imagem mostra a parte inferior de uma **Amazon Echo (4ª geração)** — que **possui sim sensor de movimento** embutido, especificamente um **sensor de presença por radar (ultrasônico)** integrado à tecnologia **Amazon Alexa Motion Detection**.

---

### **1. Como funciona o sensor de movimento da Echo (4ª Geração)?**

Essa Alexa utiliza um **sensor de radar de campo próximo** para detectar movimento **em um raio de até 3 metros** ao redor do dispositivo. Seu funcionamento é baseado em:

- **Micro-ondas de baixa potência** que medem o deslocamento de objetos (como uma pessoa entrando ou se movendo).
- **Não depende de câmeras ou imagens**, mas sim de **reflexões de sinal**.
- É capaz de detectar **movimentos sutis**, inclusive gestos como uma mão passando.

A funcionalidade é usada, por exemplo, para **acender luzes inteligentes**, **reproduzir música** ou **enviar notificações** quando alguém entra no ambiente.

---

### **2. Como uma notificação desse sensor pode ajudar a investigar um furto?**

Se a Alexa emitiu uma **notificação de detecção de movimento**, ela se torna uma **prova digital indireta** que:

- **Confirma presença humana** após a entrada pela janela.
- **Possivelmente indica o horário exato** em que o ladrão passou pela sala.
- Corrobora com a narrativa de que **a câmera foi desativada rapidamente**, já que a Alexa registrou movimento após o switch ter sido desligado.

Mesmo que o ladrão:

- **Tenha usado luvas** (eliminando digitais),
- **Dado presunto ao cachorro** (neutralizando o alarme canino),
- **Entrado pela janela da cozinha**,  
a **Alexa registrou atividade humana compatível com o horário do crime**, tornando-se um **marco cronológico preciso** da presença do invasor **na sala**.

---

### **3. Como acessar esses dados?**

Se o dispositivo estava com essa função ativada e atrelada a uma rotina ou notificação, você pode:

- **Verificar o histórico de atividades** no app Alexa (Android/iOS):
  - Acesse: *Mais > Atividade > Histórico de Movimento (ou Histórico de Routines)*.
- Buscar **logs de automações ou comandos executados** no horário estimado do crime.
- Se vinculado a dispositivos de automação (como luzes), você pode ver *logs de acionamento* por detecção de movimento.

---

### **4. Aplicações práticas como prova complementar**

Essas informações, quando cruzadas com:

- **Horário da câmera sendo desligada**,  
- **Relato de um cachorro não latindo**,  
- **Rota de entrada (janela da cozinha)**,  
podem indicar que o invasor passou exatamente **no raio de detecção da Echo**, possibilitando:

- Determinar **tempo mínimo de permanência**.
- Validar rotas do furto.
- **Conectar o evento a um horário específico**, inclusive para **confirmar ou contestar álibis**.

---

Deseja que eu te ajude a recuperar os logs específicos desse sensor ou montar um dossiê técnico com base nesses dados para eventual uso legal ou compartilhamento com autoridades?

---

### USUÁRIO

So foi disparada uma notificação de sensor de presença na alexa,da pra saber quantos metros estava da  alexa no momento de disparo de gatilho de sensor de presença? Ou qualquer outra informação atrelada a notificação que nos ajuda

---

### ASSISTENTE

Ótima pergunta, Felippe. A notificação de "sensor de presença" disparada pela Alexa **infelizmente não traz diretamente a distância exata do objeto detectado**. No entanto, podemos extrair algumas informações importantes com base **no funcionamento técnico do sensor** e no **tipo de dado gerado**. Abaixo, te explico em detalhes:

---

### **1. O que a notificação de sensor de presença da Alexa revela?**

A notificação, por padrão, indica que:

- **Foi detectado um movimento dentro do campo de alcance do sensor**.
- O sensor de radar embutido na Echo (4ª geração) tem **alcance efetivo de cerca de 3 metros (em campo aberto)**.
- A detecção ocorre **independentemente da luminosidade** ou presença de som.

**Porém, a Alexa não registra:**

- A **distância precisa** do objeto detectado;
- A **direção do movimento**;
- A **velocidade do deslocamento**;
- Nem uma imagem ou forma física do que foi detectado.

---

### **2. O que *pode* estar atrelado a essa notificação no app?**

No aplicativo **Amazon Alexa**, dependendo da configuração do dispositivo, a notificação pode estar associada a:

- **Horário exato** da detecção (útil para cruzar com outros eventos).
- **Nome da rotina associada** (ex: acionar luzes, tocar música, etc.).
- **Identificação do dispositivo que disparou** (no caso, a Echo na sala).
- **Logs de dispositivos acionados como consequência** (luzes, plugues, etc.).
- **Outros sensores conectados** (caso haja, como sensores Zigbee, no Hub interno da Echo).

**Exemplo de inferência possível**:
Se a detecção ocorreu **às 02:43 da madrugada**, logo após o switch da câmera ter sido removido, temos uma **evidência temporal concreta** de movimentação humana na casa **sem causa natural plausível** (ninguém mais em casa, sem correntes de ar grandes, etc.).

---

### **3. Considerações técnicas do sensor da Echo (radar de movimento):**

- Tecnologia: **Sensor de radar em onda milimétrica (sub-GHz ou GHz de baixa potência)**.
- Detecção baseada em **interferência de onda refletida**: qualquer massa em movimento altera o campo e aciona o gatilho.
- **Não distingue humanos de objetos**, mas a Alexa presume ser humano pela calibragem do radar (sensibilidade ajustada).
- Não há *log oficial* da distância, mas o **centro do campo de ação é na linha de frente e lateral até ~3 metros**.

---

### **4. Como essa notificação pode ajudar na investigação?**

Mesmo sem distância exata, ela pode:

- **Confirmar a passagem do invasor pela sala** após entrada pela cozinha.
- Ser cruzada com o horário do **desligamento da câmera** (que pode estar registrado no app da câmera ou roteador).
- Mostrar que o invasor passou por **uma zona que normalmente só seria acionada com presença humana real**.
- Provar que havia **atividade no local**, útil para refutar alegações de que ninguém invadiu fisicamente.

---

### **5. Próximos passos sugeridos:**

- **Acesse o app Alexa > Mais > Atividade > Dispositivos > [nome da Echo] > Histórico de Detecção de Movimento**.
- Faça uma **captura de tela** com horário e data da notificação.
- Se houver automações (rotinas associadas), registre também o histórico de execução.
- Cruce essa informação com:
  - Logs de roteador (corte ou anomalias de rede);
  - App da câmera (último frame, horário do desligamento);
  - Relato de comportamento do cachorro e qualquer outro sensor presente.

---

### **Conclusão**

Apesar da limitação de não fornecer distância, a notificação da Alexa pode servir como **marcador de presença humana em tempo real**, o que é valioso para criar uma linha do tempo **precisa e sincronizada** dos eventos durante o furto.

Deseja que eu te ajude a elaborar uma **linha temporal completa do furto**, usando esse dado da Alexa como base central e orientando como coletar os demais? Posso estruturar isso como um relatório investigativo ou pericial informal.

---

