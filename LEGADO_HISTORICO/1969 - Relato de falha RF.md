# 1969 - Relato de falha RF

### USUÁRIO

há algum vídeo ou relato de usuários mencionando que o dispositivo controle inteligente Ir/Rf Nova digital apresenta desconhecer os comandos a serem copiados RF os mesmos que já haviam desmontado capacidade para identificar copiar antes de apresentar o devido erro? 

---

### ASSISTENTE

Parece que **não há registros amplamente disponíveis** — seja em vídeos, fóruns ou avaliações de usuários — de casos relatando especificamente que o dispositivo inteligente Nova Digital (como o RM6 PRO IR+RF) “desconhece os comandos a serem copiados RF que já haviam sido detectados antes de apresentar erro”. Pelo que foi possível verificar, não existem relatos acerca de uma tentativa bem-sucedida de reconhecer um comando RF, seguida de falha posterior neste mesmo comando.

###  O que encontrei:

- **Manuais oficiais e descrições de produto** deixam claro que o controle suporta apenas **códigos RF de frequência fixa** (315 MHz / 433 MHz) — especificamente PT2260, PT2262, PT2264 e EV1527 — e **não suporta códigos rolling code ou criptografados** citeturn0search0turn1search0turn0search1.
- Também são apontados requisitos como estar conectado a **Wi-Fi 2,4 GHz** (e não 5 GHz), pois interferências ou falhas de rede podem comprometer o funcionamento citeturn0search1turn0search0.
- Um comentário de usuário no Mercado Livre mencionou que “sofredo um pouco pra copiar os comandos do controle em relação ao infravermelho”, mas foi bem-sucedido ao final e não mencionou falha interrompendo uma cópia iniciada citeturn1search7.
- Um usuário de fórum relatou dificuldades ao emparelhar RF com um módulo relé da Nova Digital, mas não há indicação de que um comando foi reconhecido inicialmente e depois passou a falhar citeturn1search1.

###  Conclusão técnica

Não encontrei **documentação ou relato de problema específico** onde o dispositivo tenha reconhecido previamente um comando RF, mas depois falhado ao repetir o processo. Os relatos comuns envolvem:

- Falha em reconhecer desde o início, especialmente com controles RF criptografados ou rolling code — destes o dispositivo não é compatível.
- Problemas relacionados à rede Wi-Fi ou emparelhamento inicial, mas não sobre uma falha após reconhecimento bem sucedido.

---

Se você tiver um caso concreto que segue esse padrão (foi reconhecido antes e agora falha), o ideal é verificar alguns pontos:

1. Se o controle RF utiliza _código fixo_ compatível.
2. Se o **sinal RF original ainda emite** corretamente.
3. Se a rede Wi-Fi está estável e na frequência correta.
4. Se houve atualização do firmware ou alteração de ambiente que pode impactar o procedimento. 

Se você quiser, posso ajudar a montar um protocolo de diagnóstico mais técnico para investigar isso a fundo.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'file-service://file-QZUa2VHcT6oPdTtJyaJ6ZY', 'size_bytes': 300684, 'width': 1320, 'height': 1389, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Vejo que você deseja encontrar relatos de usuários onde o **controle inteligente Nova Digital (como o RM6 PRO)** teria reconhecido um comando RF (código fixo) **com sucesso**, mas depois passou a **falhar ao repetir a cópia desse mesmo comando**.

###  O que encontrei até o momento

- Não identifiquei nenhum relato específico — nem em vídeos, fóruns ou seções de avaliação de produto — que descreva exatamente esse comportamento: *reconhecimento bem-sucedido seguido de falha subsequente*.
- Há relatos gerais de dificuldades para emparelhar controles RF desde o início, especialmente quando são utilizados controles com **código criptografado ou rolling code**, que não são compatíveis com o dispositivo citeturn0search3turn0search5turn0search0.
- Vídeos demonstram procedimentos de unboxing e configuração para controle IR e RF, mas não mostram esse tipo de falha gradual citeturn0search1turn0search8.
- Os manuais enfatizam a necessidade de usar apenas **códigos fixos PT2260, PT2262, PT2264 e EV1527**, e encorajam o uso da função “DIY” quando o modelo não estiver listado, mas não mencionam falhas após o reconhecimento bem-sucedido citeturn0search0turn0search2.

###  Resumo

- **Não há relatos iguais ao que você descreveu** (ou seja, onde o dispositivo reconhece um comando RF e posteriormente falha ao copiar novamente).
- As questões comuns relatadas envolvem incompatibilidade com códigos criptografados ou falhas desde a primeira tentativa de aprendizado.

###  Sugestões Estratégicas de Diagnóstico

Para avançar na sua investigação, podemos estruturar um diagnóstico técnico mais robusto:

| Etapa        | Ação                                                                                |
|--------------|--------------------------------------------------------------------------------------|
| **1. Verificar tipo do controle original** | Confirme que o controle original utiliza um dos códigos fixos compatíveis (PT2260, PT2262, PT2264, EV1527). |
| **2. Testes de consistência** | Se possível, grave o comando RF várias vezes seguidas e observe se falha em alguma tentativa, especialmente após sucesso inicial. Isso pode indicar instabilidade no sinal, interferência ou falha de hardware. |
| **3. Ambiente e rede** | Verifique se há interferência RF, distância e obstáculos entre o controle original e o Nova Digital; além disso, avalie a estabilidade da rede Wi-Fi 2,4 GHz (interferência, carga, nome duplicado com 5 GHz, etc.). |
| **4. Firmware do dispositivo** | Verifique se houve atualização recente que possa ter alterado o comportamento do módulo RF — o manual detalha métodos de troubleshooting em caso de falha durante a configuração citeturn0search0. |

Se o comportamento persistir mesmo com controles de código fixo e ambiente controlado, podemos considerar a hipótese de instabilidade interna ou falha na memória de aprendizado do módulo RF — algo que talvez valha reportar ao suporte técnico da marca.

Se quiser, posso ajudar a montar um protocolo de testes ainda mais detalhado ou planejar uma coleta de dados empíricos (como logs ou gravações de tela) para documentar o problema com clareza.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'file-service://file-DMd8DViLMaLTeyEm6eP5cH', 'size_bytes': 3436189, 'width': 1152, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Pelo seu relato e pela imagem do modelo (RM6 PRO IR+RF 315/433 MHz), o comportamento realmente indica **um possível problema interno no módulo de recepção RF** ou **algum bloqueio lógico no firmware**.

### 🔍 Análise Técnica da Situação

1. **Primeira fase normal**  
   - Dispositivo reconheceu e aprendeu múltiplos botões RF de código fixo (fita LED).
   - Tudo indica que o receptor RF estava funcionando corretamente nesse momento.

2. **Evento de reset e reconfiguração**  
   - Você apagou o dispositivo da conta Smart Life e removeu os dados.
   - Após reconectar, o dispositivo entrou novamente em modo pareamento sem apresentar erro aparente.

3. **Falha total no RF**  
   - Nenhum botão RF é reconhecido, nem o controle anterior, nem outros modelos.
   - O problema se mantém mesmo com tentativas de aprendizado DIY para diferentes códigos fixos compatíveis.

---

### Possíveis Causas

| Categoria | Hipótese | Observação |
|-----------|----------|------------|
| **Firmware/Software** | Bug após reset que impede o modo de recepção RF | Pode ser resolvido com *factory reset* profundo ou atualização OTA. |
| **Memória interna** | Bloqueio ou corrupção na memória que armazena parâmetros do módulo RF | Menos comum, mas pode ocorrer se houve erro no ciclo de gravação/apagamento. |
| **Hardware** | Falha no módulo RF (receptor ou circuito de filtragem) | Pode ser causado por sobrecarga eletromagnética, descarga estática ou defeito de fabricação. |
| **Energia** | Alimentação insuficiente na porta USB | Alguns adaptadores de baixa corrente podem causar comportamento errático, mas normalmente o sintoma é intermitente, não um “travamento” total. |

---

### 🛠️ Passos Recomendados para Teste

1. **Reset de fábrica profundo**  
   - Pressione e segure o botão físico do dispositivo por **15–20 segundos** até ver o LED piscar em modo rápido e depois lento (reset total, não apenas reconfiguração Wi-Fi).  
   - Refaça a configuração do zero, evitando restaurar backups do app.

2. **Testar com fonte de energia diferente**  
   - Use um adaptador USB com **5V / 1A ou mais** e cabo de boa qualidade, para descartar problema de alimentação.

3. **Testar com outro app compatível Tuya**  
   - Ex.: *Tuya Smart* (às vezes há diferenças sutis na função DIY).

4. **Verificar atualização de firmware**  
   - No Smart Life, vá em Configurações → Atualização de firmware e verifique se há versão nova.

5. **Teste de recepção RF “aberto”**  
   - Em ambiente livre de interferência, segure o controle RF bem próximo do dispositivo para testar sensibilidade.

---

### 📌 Conclusão
O padrão do seu caso **não é um bug comum relatado por outros usuários**, e a coincidência de o RF parar de funcionar após um ciclo de aprendizado/reset sugere **bug de firmware ou falha física do módulo RF**.  
Se o reset profundo e a atualização não restaurarem a função, o mais provável é que seja um defeito crônico no hardware — e neste caso, o ideal é acionar a garantia ou o suporte da Nova Digital informando exatamente o histórico.

---

Se quiser, posso te preparar um **protocolo de teste documentado** com checklist e gravação de resultados para que você envie ao suporte como prova técnica. Isso aumenta muito a chance de conseguirem aprovar troca ou reparo sem questionamentos.

---

### USUÁRIO

há casos similares com controladores inteligentes de modelos similares e marcas diferentes?

---

### ASSISTENTE

Sim — há relatos bastante semelhantes com outros modelos e marcas de **controladores inteligentes IR/RF**, especialmente envolvendo falhas no reconhecimento contínuo de sinais RF após reset ou uso inicial.

---

###  Casos semelhantes identificados

####  Broadlink RM Pro
Um relato clássico do fórum AVForums descreve bem sua situação:  
> “I accidentally deleted one of my remotes in the e-Control Android app, and now I am unable to re-learn any RF remote control codes... I was able to program RF codes into it without any problems – this problem has only arisen today.”  
Ou seja, após remover a configuração, o dispositivo deixou de aprender RF, mesmo que antes funcionasse normalmente citeturn0search4.

####  Broadlink RM4 Pro (via Home Assistant)
Em contextos de integração com o Home Assistant, usuários reportaram falhas ao tentar aprender comandos RF após mudanças ou atualizações:
- Um problema comum foi que ao usar `command_type: rf` para aprender comandos RF, o dispositivo simplesmente **não reconhecia sinal algum** — mesmo que funcionasse normalmente via app oficial citeturn0search16.
- Outro relato no GitHub aponta erro semelhante ao aprender comandos RF via `service remote.learn_command`:  
  > “When I tried to make a service for RF devices the control didn't recognize the signal from my controller.”  
  O IR funcionava normalmente, mas o RF não era detectado de forma alguma citeturn0search0.

####  Broadlink RM4 Pro com “Failed to learn: No signal received”
Também na integração com Home Assistant, outro usuário enfrentou erro de aprendizado de RF:  
> “I always get the notification message No signal was received (log error message Failed to learn: No signal received)”  
Isso indica uma falha repetida ao tentar aprender sinais RF, mesmo com diferentes controles e múltiplas tentativas citeturn0search20.

---

###  Síntese e comparação

| Marca/Modelo           | Comportamento Reportado                                                                 |
|------------------------|-----------------------------------------------------------------------------------------|
| **Broadlink RM Pro**   | Aprendia RF normalmente, mas após reset ou exclusão no app, parou de aprender RF      |
| **Broadlink RM4 Pro**  | Não reconhece comando RF via Home Assistant (`command_type: rf`), mas IR funciona     |
| **Broadlink RM4 Pro**  | Erro “No signal received” durante tentativa de aprender RF (Home Assistant integration) |
| **Outros (Tuya etc.)** | Situações semelhantes de falha em aprender RF após resets ou configurações via app     |

---

###  Conclusão

Sim, seu caso não é isolado. Muitos usuários relatam comportamento similar: após resets, alterações, ou simplesmente ao reiniciar a configuração, os módulos de RF deixam de responder, enquanto o IR continua funcionando bem.

Isso reforça uma potencial hipótese de que **firwares ou lógicas internas tratam o RF de forma mais frágil**, talvez mantendo estados "travados" após eventos como reset ou falha no re-aprendizado. Também pode evidenciar que a memória de RF ou um subsistema físico/lógico está **sensível à inconsistência de estados**, especialmente após apagar dados e reconfigurar via app.

Se quiser, posso montar uma **comparação técnica com base nesses relatos** ou sugerir uma estratégia de testes paralelos para verificar se o seu módulo RF ainda responde antes de presumir uma falha de hardware.

Qual abordagem prefere explorar a seguir?

---

