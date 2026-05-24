# 2137 - Controle remoto via Tailscale

### USUÁRIO

penso que se eu usar meu pc para transmitir em tempo real a gravação da tela e usar nele um controlador mouse via wifi (como o "remote mouse" ) e um teclado via wifi que tenha app ou site disponível para ipad mini (como o remote mouse e acredito que o unified remote é um bom exemplo), podemos colocar todos no mesmo vpn do tailscale e assistir em tempo real a transimissão de vídeo da tela do pc no ipad e além disso usar o site ou app para controlar o mouse a distância, uma alternativa frugal para alcançar o uso remoto sem restrições administrativas...

---

### ASSISTENTE

Intenção | **performance**

Estratégia | Rede privada via **Tailscale** + streaming de tela com **Sunshine→Moonlight** + controle por **input do Moonlight** (fallback: Remote Mouse/Unified Remote). DNS estável com **MagicDNS**. citeturn0search9turn0search2 citeturn0search7turn0search14 citeturn0search8

Plano (idempotente, 1–3) |
1) **Rede (Tailscale)**: Instale em PC e iPad. Entre no mesmo tailnet. Ative **MagicDNS** para usar nomes em vez de IP. Teste ping/latência. citeturn0search9turn0search2turn0search16  
2) **Vídeo (Sunshine→Moonlight)**:  
   • PC: instale **Sunshine**, habilite o app “Desktop”, HEVC/H.264 por hardware.  
   • iPad: **Moonlight**. Conecte usando o hostname Tailscale. Ajuste 1080p60/bitrate conforme rede. citeturn0search7turn0search14  
3) **Input (mouse/teclado)** – escolha A ou B:  
   A) **Moonlight** já envia mouse/teclado/controladores ao host (geralmente suficiente). citeturn0search8  
   B) **Separar o input**: instale **Remote Mouse** ou **Unified Remote** no PC + app no iPad e conecte via endereço Tailscale. Abra portas (Remote Mouse usa TCP/UDP **1978**). citeturn0search3turn0search11turn0search4

Por quê | Tailscale cria caminhos estáveis ponta-a-ponta e nomes consistentes (**MagicDNS**). Sunshine+Moonlight entrega **baixa latência** com codificação por hardware. Separar o input é útil caso políticas locais bloqueiem injeção de entrada via cliente de streaming. citeturn0search9turn0search2 citeturn0search7

Assumos | PC com Windows e GPU compatível; iPad mini com iPadOS recente; permissão para instalar apps; intenção **não** é burlar políticas corporativas. Corrija se errado. citeturn0search7

Riscos |
- **Políticas/ética**: se for ambiente gerenciado, isso pode violar normas. Use só com autorização.  
- **Latência/Jitter**: Wi-Fi/4G podem degradar o stream; RTSP/VLC tende a maior latência (não recomendado para controle fino). citeturn0search6turn0search13  
- **Firewall**: portas do input alternativo (ex.: 1978) podem ser bloqueadas. citeturn0search3  
- **iOS**: algumas apps de controle têm limitações por sandbox; preferir input nativo do Moonlight. citeturn0search8

Prob 80%: você terá experiência fluida (≤60–90 ms LAN bem configurada) com Moonlight+Sunshine; fallback via apps de mouse/teclado funciona pela VPN.

Próximos |
1) **Prova rápida** (10 min): instalar Tailscale nos dois, ativar MagicDNS, abrir Moonlight e descobrir o host pelo nome. citeturn0search9turn0search2  
2) **Ajustes de stream**: testar 1080p60 HEVC; se travar, reduzir bitrate; conferir input nativo do Moonlight. citeturn0search7turn0search8  
3) **Fallback input**: se quiser app dedicado, configurar **Remote Mouse** (1978/TCP+UDP) ou **Unified Remote** e apontar para o hostname Tailscale. citeturn0search3turn0search11turn0search4

Por quê (δ-meta) | “Vídeo por **Sunshine→Moonlight** + rede **Tailscale** + input **nativo**” minimiza camadas, portas e latência, preservando qualidade e simplicidade. O input separado fica como opção “frugal-flex”, útil se o cliente de streaming estiver restrito.

---

