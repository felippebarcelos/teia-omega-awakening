# 0050 - Problema com Atributos Somente Leitura

### USUÁRIO

Chat, me ajude. No disco C, dentro da pasta de usuários, o meu usuário, chamado Felipe, quando eu vou em propriedades, os atributos só estão como somente leitura. Ao desmarcar e tentar aplicar, ele carrega, eu clico ok. Quando abro a pasta novamente e clico nas propriedades do usuário Felipe, volta a aparecer como atributo somente leitura. Fora isso, já entrei em compartilhamento, compartilhamento avançado, permissões, onde as permissões para o meu usuário estar como controle total, alteração e leitura. Clico em ok, ok, fechar, mas quando entre nas propriedades novamente do arquivo, volta a estar como somente leitura. O que eu faço?

---

### ASSISTENTE

A situação que você descreve pode ser uma característica normal do Windows. Pastas do sistema, como a pasta do usuário, muitas vezes exibem o status de "Somente leitura" nas propried

---

### USUÁRIO

Chat, me ajude. No disco C, dentro da pasta de usuários, o meu usuário, chamado Felipe, quando eu vou em propriedades, os atributos só estão como somente leitura. Ao desmarcar e tentar aplicar, ele carrega, eu clico ok. Quando abro a pasta novamente e clico nas propriedades do usuário Felipe, volta a aparecer como atributo somente leitura. Fora isso, já entrei em compartilhamento, compartilhamento avançado, permissões, onde as permissões para o meu usuário estar como controle total, alteração e leitura. Clico em ok, ok, fechar, mas quando entre nas propriedades novamente do arquivo, volta a estar como somente leitura. O que eu faço?


---

### ASSISTENTE

A caixa de "Somente leitura" na pasta do usuário do Windows muitas vezes pode ser enganosa. Essa caixa de seleção não reflete o status real de somente leitura dos arquivos individuais, mas sim o status de permissão para aplicações e arquivos dentro dela. Se você tenta desmarcar a caixa e ela reverte ao estado anterior, é geralmente porque essa é a configuração padrão para o funcionamento do sistema operacional e não afeta a sua capacidade de modificar arquivos individuais dentro dessa pasta.

Se você está tendo problemas para modificar arquivos específicos dentro da pasta do usuário, isso pode indicar problemas de permissão individuais nos arquivos ou que um programa está acessando os arquivos, impedindo a mudança.

Aqui está o que você pode tentar:

1. **Verificar Propriedades Individuais**: Se o problema é com arquivos específicos, clique com o botão direito em cada arquivo e ajuste suas propriedades individualmente.
   
2. **Modo de Segurança**: Inicie o Windows no Modo de Segurança e tente alterar o atributo. Às vezes, programas em execução podem impedir a mudança de atributos.

3. **Prompt de Comando**: Abra o Prompt de Comando como administrador e use o comando `attrib -r +s "C:\Users\Felipe"` para tentar remover o atributo de somente leitura recursivamente na pasta e subpastas.

4. **Propriedade e Permissões**: Garanta que você é o proprietário da pasta e que tem todas as permissões necessárias. Para isso, clique com o botão direito na pasta > Propriedades > Segurança > Avançado > Proprietário.

5. **Políticas de Grupo**: Se você está em uma rede de trabalho, pode haver políticas de grupo aplicadas que redefinem essas configurações.

6. **Verificar com um Administrador de Sistemas**: Se nada disso funcionar, pode ser necessário consultar um profissional de TI, pois o problema pode ser mais complexo.

Lembre-se de que, embora a caixa de somente leitura reverta ao seu estado original, isso não necessariamente impede a modificação de arquivos dentro da pasta. Se não estiver enfrentando problemas ao modificar conteúdos dentro da pasta, então é provável que tudo esteja funcionando como deveria.

---

