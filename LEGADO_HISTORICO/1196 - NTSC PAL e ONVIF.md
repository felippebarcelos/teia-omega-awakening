# 1196 - NTSC PAL e ONVIF

### USUÁRIO

O padrão de vídeo NTSC pode afetar na configuração da integração da câmera Jordan. Wi-Fi IP via OnVIF, que já consegue reconhecer, porém não consegue transmitir a devida imagem, onde só aparece outros problemas de rede. Onde no padrão de vídeo está pré-definido como NTSC e precisa de ajuda relacionada se a opção PAL é uma alternativa. Ou isso não afeta ainda.

---

### ASSISTENTE

O padrão de vídeo NTSC ou PAL não deveria afetar diretamente a transmissão de imagens em câmeras Wi-Fi IP, especialmente quando você está utilizando o protocolo **ONVIF**, pois ele opera de forma independente do padrão de vídeo analógico. No entanto, em algumas situações, o padrão de vídeo pode interferir na visualização dependendo do software ou hardware utilizado. Vamos analisar:

### Possíveis influências do padrão NTSC/PAL:
1. **Incompatibilidade de padrões no DVR ou software receptor**:
   - Se o DVR ou software de monitoramento espera receber fluxos configurados como PAL, mas a câmera está transmitindo em NTSC, isso pode causar problemas de decodificação.
   - É raro, mas pode ocorrer em dispositivos antigos ou mal configurados.

2. **Configuração no DVR**:
   - Certifique-se de que o DVR esteja configurado para suportar o padrão que a câmera utiliza (NTSC ou PAL). Se o padrão da câmera for NTSC e o DVR estiver configurado para PAL, pode haver falhas na exibição.

3. **Modo de transmissão ONVIF**:
   - O protocolo ONVIF é baseado na transmissão digital (RTSP), e os padrões NTSC ou PAL são relevantes apenas se a câmera também estiver configurada para transmitir fluxos analógicos (como no modo híbrido). Em transmissões exclusivamente digitais, o padrão de vídeo não deve interferir.

### Alternativas e próximos passos:
1. **Verifique o protocolo ONVIF no DVR e na câmera**:
   - Certifique-se de que **ONVIF** está ativado tanto no DVR quanto na câmera.
   - Confira as portas RTSP da câmera e do DVR para garantir que estão na mesma configuração de rede.

2. **Testar com outro software ONVIF**:
   - Utilize ferramentas como **ONVIF Device Manager** (para Windows) ou apps como **ONVIF IP Camera Monitor** para verificar se a câmera transmite o fluxo de vídeo de forma independente do DVR.

3. **Alteração para PAL**:
   - Alterar para PAL dificilmente resolverá o problema, mas vale a pena tentar se o DVR estiver configurado como PAL ou se for o padrão local da região.

4. **Erro de outros problemas de rede**:
   - O problema pode estar relacionado à **faixa de IP** da câmera ou a credenciais incorretas. Certifique-se de que:
     - O IP da câmera está na mesma sub-rede que o DVR.
     - As credenciais de acesso (usuário e senha) estão corretas.
     - O firewall do roteador não está bloqueando a comunicação entre os dispositivos.

### Conclusão:
O padrão de vídeo NTSC ou PAL é secundário em transmissões digitais via ONVIF e RTSP. Seu foco deve ser na verificação de credenciais, compatibilidade ONVIF e configuração de rede. Alterar o padrão para PAL pode ser uma tentativa válida, mas dificilmente será a solução definitiva. Se precisar de mais detalhes sobre algum dos passos, posso ajudar a aprofundar o diagnóstico.

---

### USUÁRIO

De acordo com o modelo da minha câmera Jordan, verifique qual é o padrão de vídeo, NTSC ou PAL.

---

### ASSISTENTE

A marca Jordan oferece câmeras de segurança que geralmente suportam os padrões de vídeo NTSC e PAL, permitindo que o usuário selecione o mais adequado às suas necessidades. No entanto, a configuração padrão de fábrica costuma ser NTSC. Para determinar o padrão de vídeo atual da sua câmera Jordan, siga estes passos:

1. **Acesse as configurações da câmera**:
   - Conecte-se à interface web da câmera através do navegador, utilizando o endereço IP atribuído a ela.
   - Faça login com suas credenciais de administrador.

2. **Navegue até as configurações de vídeo**:
   - Procure por seções como "Configurações de Vídeo", "Parâmetros de Imagem" ou "Sistema".

3. **Verifique o padrão de vídeo**:
   - Dentro dessas opções, localize a configuração referente ao padrão de vídeo, que geralmente permite alternar entre NTSC e PAL.

4. **Altere o padrão, se necessário**:
   - Se a câmera estiver configurada para NTSC e você desejar mudar para PAL, selecione a opção correspondente e salve as alterações.
   - A câmera pode reiniciar para aplicar a nova configuração.

Se não conseguir acessar essas configurações ou se a interface não apresentar opções claras, consulte o manual do usuário específico do modelo da sua câmera Jordan. O manual fornecerá instruções detalhadas sobre como acessar e modificar as configurações de vídeo. Caso não possua o manual físico, verifique o site oficial da Jordan ou entre em contato com o suporte técnico da empresa para obter assistência.

Lembre-se de que a escolha entre NTSC e PAL deve considerar a compatibilidade com outros equipamentos do seu sistema de vigilância, como monitores e gravadores, para garantir uma integração adequada. 

---

