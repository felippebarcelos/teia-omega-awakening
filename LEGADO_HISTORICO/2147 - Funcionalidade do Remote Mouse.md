# 2147 - Funcionalidade do Remote Mouse

### USUÁRIO

teoricamente o app remote mouse para ios tem a funcionalidade de ao usar um mouse via cabo usbc ou bluetooth ter a devida funcionalidade replicada ao dispositivo que está a reproduzir os comandos de mouse pelo app remote mouse?

---

### ASSISTENTE

Boa pergunta — acho que vale separar o que “teoricamente” permite e o que tecnicamente é viável (ou não) no ecossistema iOS.

---

### O que o Remote Mouse realmente faz (documentado)

Pelos recursos listados nas descrições oficiais:

- O Remote Mouse “imita as funções de um mouse sem fio, teclado e touchpad” entre o dispositivo iOS e um computador remoto. citeturn0search7turn0search1turn0search9  
- Ele funciona via Wi-Fi ou Bluetooth entre o iPhone/iPad e o computador servidor. citeturn0search1turn0search7turn0search6turn0search9  
- Ele trata os toques, gestos multitoque e teclas vindas do dispositivo como comandos que são retransmitidos ao computador remoto. citeturn0search9turn0search1turn0search7  

Até aí, tudo indica que o app trata o dispositivo iOS como uma “superfície de controle” para o computador remoto.

---

### O que você perguntou: “usar um mouse via cabo USB-C ou Bluetooth no iOS e replicar essa ação via Remote Mouse”

Você quer saber se, caso eu conecte um mouse *físico* ao meu iPhone (ou iPad) — via USB-C ou Bluetooth — o app Remote Mouse *captura* esse movimento do mouse físico e repassa esses comandos ao computador remoto.

Minha avaliação técnica:

- **Não parece que isso é suportado oficialmente**. Nas descrições do Remote Mouse não há menção de que ele pode interceptar eventos de mouse externos ao dispositivo iOS e transformá-los em comandos remotos.
- O app assume que o input vem da tela (toque/gesto) do dispositivo iOS, não necessariamente de periféricos externos.  
- iOS tem restrições quanto ao redirecionamento de eventos de hardware externo para dentro de apps de terceiros: apps “sandboxed” têm limitações de acesso a dispositivos externos, a menos que iOS permita explicitamente via APIs (por ex. suporte a dispositivos de acessibilidade ou APIs de entrada externa).  
- Mesmo que o mouse externo funcione no iOS como ponteiro (em modo de acessibilidade, por exemplo), isso não garante que o Remote Mouse consiga “monitorar” esses eventos e retransmiti-los — pois o app precisaria de permissão para ler esses eventos de sistema/entrada de hardware.

Portanto, teoricamente **poderia haver uma camada que “ouve” eventos de mouse no iOS e os converte para comandos do Remote Mouse**, mas **na prática e segundo documentação pública**, esse comportamento **não está listado** como funcionalidade do Remote Mouse.

---

Se você quiser, posso tentar investigar a fundo (via documentação técnica, fóruns de dev, ou engenharia reversa) se há alguma versão “hacky” ou não documentada que faça isso. Quer que eu investigue isso para você?

---

### USUÁRIO

há algum app com essa capacidade?

---

### ASSISTENTE

Sim — existe.  
Resumo rápido: clientes **de Remote Desktop / VNC** no iPad/iPhone conseguem usar um **mouse físico ligado ao iOS** (Bluetooth ou USB-C) e **encaminhar** os movimentos/cliques para o computador remoto — comportamento e qualidade variam por app e por iOS/iPadOS.  

Por onde começar (apps que já suportam isso):  
- **Jump Desktop** — suporte completo a mouse/trackpad em iPadOS; mapeia o ponteiro e envia para a sessão remota. citeturn0search0turn0search12  
- **Microsoft Remote Desktop (RDP)** — suporte a mouse/trackpad em iPadOS (iOS 13.4+); tem modos de ponteiro e mapeamento de gestos. citeturn0search17turn0search9  
- **Screens / VNC / RealVNC Viewer** — clientes VNC modernos aceitam pointing devices no iPad e usam o cursor nativo para controlar o host remoto. citeturn1search5turn0search2  
- **Splashtop / TeamViewer / AnyDesk** — também listados como opções viáveis; comportamento pode ser diferente entre apps (SomeDesk/AnyDesk têm limitações por plataforma). citeturn1search4turn0search11turn1search2

Observações importantes (práticas):  
1. **Melhor em iPadOS** — iPadOS tem suporte nativo a ponteiros (AssistiveTouch) desde iOS 13.4; experiência em iPhone pode ser limitada. citeturn1search14turn0search1  
2. **Nem todo mouse avançado funciona 100%** — alguns recursos do hardware (gestos do Magic Mouse, botões extras, software do fabricante) podem não ser transmitidos; prefira mouses/trackpads suportados documentados pelo app. citeturn0search12turn1search1  
3. **Modo do app** — alguns clientes mapeiam o toque para ponteiro (virtual), outros integram o ponteiro nativo do iPad — teste o app com seu mouse para validar clique/scroll/middle-click. citeturn0search2turn0search11

Se quiser, eu faço:  
- Recomendar 2–3 apps para testar com seu modelo de iPhone/iPad e mouse.  
- Buscar instruções rápidas de configuração para o app que você escolher (passo-a-passo: emparelhar mouse → ativar AssistiveTouch → ajustar nas configurações do app).  

Assumo que você usa iPadOS / iOS ≥13.4; corrija se errado. Prob ~90%: a melhor experiência será no iPad. Quer que eu traga o passo-a-passo para Jump Desktop / Microsoft RD / Screens? 🖱️📱

---

