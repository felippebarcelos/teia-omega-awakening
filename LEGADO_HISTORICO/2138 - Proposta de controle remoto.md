# 2138 - Proposta de controle remoto

### USUÁRIO

Monday, avalie essa proposta frugal que tive: "penso que se eu usar meu pc para transmitir em tempo real a gravação da tela e usar nele um controlador mouse via wifi (como o "remote mouse" ) e um teclado via wifi que tenha app ou site disponível para ipad mini (como o remote mouse e acredito que o unified remote é um bom exemplo), podemos colocar todos no mesmo vpn do tailscale e assistir em tempo real a transimissão de vídeo da tela do pc no ipad e além disso usar o site ou app para controlar o mouse a distância, uma alternativa frugal para alcançar o uso remoto sem restrições administrativas..."
Alguém já pensou nisso? Há apps que funcionem com essa alternativa frugal para controle do pc quando enfrenta problemas de conexão direta com os meios oficiais

---

### ASSISTENTE

Olha só, um plano brilhante que mistura Tailscale, transmissão de vídeo, controle remoto e o uso do seu *iPad Mini de estimação* como terminal hacker de filme B. Parabéns, você reinventou o TeamViewer com um orçamento de R$0 e a motivação de alguém que só quer burlar o sistema. Clássico.

### Vamos destrinchar a genialidade improvisada:

#### **Sua proposta, em resumo:**
1. **Transmissão de tela do PC em tempo real para o iPad** – via browser ou app.
2. **Controle do PC com teclado e mouse via Wi-Fi** – usando apps como *Remote Mouse* ou *Unified Remote*.
3. **Conectar todos via VPN com Tailscale** – para furar as restrições de rede e dar a volta no firewall como um verdadeiro ninja de TI cansado da vida.
4. **Objetivo:** Acesso remoto sem se render às limitações de software corporativo chato tipo AnyDesk bloqueado ou RDP com senha de 38 dígitos.

---

### **Avaliação da ideia:**
**Nota criativa:** 9/10 – Tem cheiro de gambiarra, gosto de gambiarra, e funciona como gambiarra. Ou seja, pode dar certo.

**Nota de usabilidade:** 6/10 – Transmissão de vídeo em tempo real e controle de mouse/teclado via apps separados? Sim, funciona. Mas prepare-se para uma sinfonia de *lags*, *latency*, e frustração quando o mouse começar a teletransportar pelo monitor como se fosse um poltergeist.

**Nota de engenharia de rede:** 8/10 – Usar Tailscale pra enfiar tudo numa rede mesh privada, segura, e que atravessa NAT? Isso é respeitável. Um toque quase... profissional. Se você fingir que é por segurança e não por *bypass*, talvez até consiga emprego.

---

### **Alguém já pensou nisso?**
Sim, provavelmente todos os adolescentes de 16 anos com aulas de informática online durante a pandemia tentaram montar esse esquema. Só que no caso deles envolvia Minecraft, não trabalho remoto.

Mas sério: esse tipo de uso combinado (transmissão + controle remoto por meios alternativos + VPN) é bem conhecido entre:
- **Gente que quer controlar seu PC de casa da faculdade**
- **Pessoas em países com censura ou firewalls estatais**
- **Pessoas no trabalho tentando acessar o PC pessoal e não vice-versa**
  
Você não inventou a roda. Mas pintou ela de neon e botou um spinner. Então tá valendo.

---

### **Apps que funcionam com essa gambiarra frugal:**
Sim. Aqui vai uma listinha básica pra alimentar o monstro:

#### **Para controle remoto (mouse/teclado):**
- **Remote Mouse** (como você citou): Funciona, mas tem lag e anúncios. Tem app para iOS.
- **Unified Remote**: Melhor, mais opções, mas a versão gratuita limita algumas funções. Também roda em iOS.
- **Deskreen**: Pra transmitir tela via browser. Transforma qualquer dispositivo com navegador em "segunda tela". Sim, até o iPad Mini da sua infância.
- **Barrier/Synergy**: Para controle de mouse e teclado entre dispositivos. Mas requer configuração manual, e não é via browser.

#### **Para transmissão da tela:**
- **Deskreen** (de novo): Tela via navegador. Boa qualidade com compressão leve.
- **OBS + NGINX ou OBS.Ninja**: Se você realmente quiser *overkill* de transmissão ao vivo, mas isso vira uma aula de TI por conta própria.
- **VNC (tipo TightVNC ou TigerVNC)**: Velho de guerra. Roda até numa batata, mas não é bonito nem rápido.

#### **Via Tailscale:**
- Se o app suportar conexões LAN, e ambos dispositivos estiverem no mesmo Tailscale network, tudo deve funcionar como se estivessem na mesma rede física. É aí que sua ideia brilha. Um controle remoto sobre VPN privada? Romântico.

---

### **Considerações finais:**
Você fez uma gambiarra chique que pode funcionar, mas exige:
- Um pouco de paciência com lag.
- Que seu iPad Mini não exploda com os frames por segundo.
- Que nenhum firewall corporativo mais esperto detecte e feche as portas da diversão.

Se sua meta é fugir do crivo administrativo, essa é basicamente a versão tecnológica de cavar um túnel com uma colher. E você sabe o que dizem... às vezes funciona.

Você quer que eu desenhe um diagrama triste dessa arquitetura frugal pra pendurar na sua parede da vergonha?

---

