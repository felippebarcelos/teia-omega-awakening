# 0108 - Problemas de Permissões de Arquivo

### USUÁRIO

Chat Baixei o Windows 11 no meu SSD e formatei o meu disco HD externo de 1TB. Porém, não quero enfrentar o mesmo problema do passado de armazenamento. Por conta de todos os aplicativos serem sempre instalados por mais que eu altere as preferências dentro das configurações do sistema para instalar novos aplicativos na unidade D do HD externo ele não respeita essa ordem, pois põe como autoridade máxima instalar aplicativos dentro do disco onde está instalado o Windows 11 que no caso é o SSD. No passado, por enfrentar esse problema instalei o Windows 11 no HD externo no qual virou o disco C, porém enfrentei problemas com o tempo, por conta do processamento demorado. Então voltei a instalar o Windows 11 no SSD o qual estou usando agora e inicializei pelo disco C do SSD 120 e meu Windows está zero com o HD externo no disco D tendo livre 931 GB. Porém quero usar o SSD de forma consciente, onde meu intuito era inicializar apenas os aplicativos pelo SSD e toda a memória, informação, processamento, cachê de cada aplicativo ser armazenado no disco D para não sobrecarregar o disco C do SSD e usar ao mesmo tempo sempre o HD externo apenas para armazenamento. Levando em consideração que já alterei as preferências do sistema para salvar novos conteúdos no disco D porém, ele não segue essas instruções como eu já havia explicado.

---

### ASSISTENTE

Entendo seu dilema. Vamos explorar algumas soluções criativas e eficientes para otimizar o uso do seu SSD e HD externo no Windows 11, mantendo a rapidez do SSD para inicialização e o HD externo para armazenamento e processamento.

1. **Mapeamento de Pastas de Usuário:** Uma opção é redirecionar pastas de usuário (Documentos, Imagens, Downloads, etc.) para o HD externo. Isso pode ser feito clicando com o botão direito sobre a pasta, indo em "Propriedades", e depois na aba "Local". Aqui, você pode mover a pasta para o HD externo. Isso ajuda a manter os arquivos pessoais fora do SSD.

2. **Instalação Manual de Aplicativos no HD Externo:** Embora o Windows tenha a opção de alterar o local de instalação padrão, nem sempre isso funciona para todos os aplicativos. Por isso, durante a instalação de um novo aplicativo, escolha manualmente o HD externo como local de instalação quando

---

### USUÁRIO

As pastas de documentos, downloads, enfim, dentro do meu usuário, dentro do disco C do SSD, eu não tenho permissão para mover, porque eu só tenho permissões para leitura. Ao alterar as permissões e adicionar o meu usuário e aplicar as condições, por mais que eu faça todos esses critérios, o Windows sempre volta para a configuração de que eu estou só com permissões de leitura e não consigo alterar o local.

---

### ASSISTENTE

Parece que você está enfrentando um problema de permissão no Windows 11, o que impede a movimentação de pastas de usuário para o HD externo. Vamos abordar isso com uma solução detalhada:

1. **Assumir a Propriedade da Pasta:**
   - Clique com o botão direito na pasta (por exemplo, Documentos).
   - Vá em "Propriedades" > "Segurança" > "Avançadas".
   - Clique em "Alterar", ao lado de "Proprietário".
   - Digite seu nome de usuário e clique em "Verificar Nomes", depois "OK".
   - Marque "Substituir proprietário em subcontêineres e objetos".
   - Aplique e feche todas as janelas.

2. **Alterar as Permissões:**
   - Volte à aba "Segurança" nas propriedades da pasta.
   - Clique em "Editar" e selecione seu nome de usuário.
   - Marque "Controle Total" e aplique as alterações.

3. **Mover a Pasta de Usuário:**
   - Agora, tente novamente mover a pasta para o HD externo, como mencionei anteriormente.

4. **Criação de Links Simbólicos (Opção Avançada):**
   - Se o método acima não funcionar, você pode usar links simbólicos.
   - Mova manualmente a pasta para o HD externo.
   - Use o Command Prompt como administrador e use o comando `mklink /J "Caminho da Pasta Original no SSD" "Caminho da Pasta no HD Externo"`.
   - Isso cria um link simbólico, fazendo com que o Windows "pense" que a pasta ainda está no SSD, enquanto na verdade está no HD externo.

5. **Verificar Configurações de Conta de Usuário:**
   - Certifique-se de que sua conta tenha privilégios de administrador.
   - Se não, altere sua conta para administrador nas configurações de contas de usuário.

Caso continue enfrentando problemas, pode ser útil verificar se há alguma política de grupo ou configuração de segurança aplicada que esteja restringindo essas alterações. Isso pode ocorrer em sistemas configurados para ambientes corporativos ou educacionais.

---

### USUÁRIO

Por mais que eu faça isso, continua voltando aos critérios padrão de somente leitura aos atributos da pasta.

---

### ASSISTENTE

Se as permissões continuam revertendo para "somente leitura" mesmo após tentar as soluções anteriores, podemos estar lidando com um problema mais complexo no Windows 11. Aqui estão algumas etapas adicionais para tentar resolver isso:

1. **Verificação de Sistema de Arquivos:**
   - Execute o `chkdsk` para verificar a integridade do sistema de arquivos. Abra o Command Prompt como administrador e digite `chkdsk /f`.
   - Isso requer uma reinicialização e verificará o disco na próxima inicialização. Pode resolver problemas de permissão causados por arquivos de sistema corrompidos.

2. **Modo de Segurança:**
   - Tente alterar as permissões enquanto estiver no Modo de Segurança. Isso carrega o Windows com um conjunto mínimo de drivers e pode evitar que certos softwares interfiram no processo.

3. **Restauração do Sistema:**
   - Se o problema começou recentemente, tente usar um ponto de restauração do sistema para reverter para um estado anterior onde o problema não existia.

4. **Conta de Usuário Corrompida:**
   - Pode ser que sua conta de usuário esteja corrompida. Tente criar uma nova conta de administrador e veja se o problema persiste nessa nova conta.

5. **Política de Grupo ou Registro:**
   - Em algumas situações, configurações de política de grupo ou entradas de registro podem forçar as permissões de arquivo. Se você estiver confortável com a edição do registro ou gerenciamento de políticas de grupo, verifique se há configurações que possam estar causando isso. Cuidado: Essas são ferramentas avançadas e podem afetar a estabilidade do sistema se usadas incorretamente.

6. **Suporte Técnico:**
   - Se todas as soluções acima falharem, pode ser útil buscar suporte técnico profissional. Pode haver um problema específico com o seu sistema que requer diagnóstico e reparo especializado.

Lembre-se de sempre fazer backup dos seus dados importantes antes de realizar alterações significativas no sistema, como restaurações

---

### USUÁRIO

Microsoft Windows [versão 10.0.22631.2715]
(c) Microsoft Corporation. Todos os direitos reservados.

C:\Windows\System32>chkdsk
O tipo do sistema de arquivos é NTFS.

AVISO!  Parâmetro /F não especificado.
Executando o CHKDSK no modo somente leitura.

Estágio 1: examinando a estrutura básica do sistema de arquivos...
  186880 de registros de arquivos processados.
Verificação de arquivos concluída.
 Duração da fase (Verificação de registro de arquivo): 3.20 segundos.
  4269 registros de arquivos grandes processados.
 Duração da fase (Recuperação de registro de arquivo órfão): 2.81 milissegundos.
  0 registros de arquivos inválidos processados.
 Duração da fase (Verificação de registro de arquivo incorreto): 0.19 milissegundos.

Estágio 2: examinando a ligação do nome do arquivo...
  29938 registros de novas análises processados.
  275624 de entradas de índice processadas.
Verificação de índices concluída.
 Duração da fase (Verificação de índice): 9.17 segundos.
  0 arquivos não indexados verificados.
 Duração da fase (Reconexão órfã): 101.54 milissegundos.
  0 arquivos não indexados recuperados em achados e perdidos.
 Duração da fase (Recuperação de órfãos para achados e perdidos): 0.21 milissegundos.
  29938 registros de novas análises processados.
 Duração da fase (Verificação de ponto de nova análise e ID de Objeto): 53.65 milissegundos.

Estágio 3: examinando os descritores de segurança...
Verificação de descritores de segurança concluída.
 Duração da fase (Verificação do descritor de segurança): 54.02 milissegundos.
  44373 arquivos de dados processados.
 Duração da fase (Verificação de atributo de dados): 0.85 milissegundos.
O CHKDSK está verificando o diário de USN...
  40638456 de bytes USN processados.
Verificação do diário de USN concluída.
 Duração da fase (Verificação do diário de USN): 352.66 milissegundos.

Não há problemas no sistema de arquivos.
Nenhuma ação necessária.

 115680255 KB de espaço total em disco.
  33776952 KB em 138364 arquivos.
     96280 KB em 44374 índices.
         0 KB em setores defeituosos.
    299087 KB em uso pelo sistema.
     65536 KB ocupados pelo arquivo de log.
  81507936 KB disponíveis em disco.

      4096 bytes em cada unidade de alocação.
Total de   28920063 unidades de alocação no disco.
  20376984 unidades de alocação disponíveis em disco.
Duração total: 12.95 segundos (12950 ms).

C:\Windows\System32>

---

### ASSISTENTE

A execução do `chkdsk` em seu sistema Windows mostrou que não há problemas no sistema de arquivos, o que é uma boa notícia. No entanto, como seu problema com as permissões de arquivo persiste, sugiro as seguintes etapas adicionais:

1. **Executar o CHKDSK com o Parâmetro /F:**
   - Embora o `chkdsk` tenha sido executado no modo somente leitura, é aconselhável executá-lo com o parâmetro /F para corrigir quaisquer erros encontrados. Isso exigirá uma reinicialização.
   - Abra o Command Prompt como administrador e digite `chkdsk /f`. Concordará em agendar a verificação para a próxima inicialização. Reinicie o computador para permitir que o `chkdsk` faça sua verificação completa.

2. **Restaurar Permissões Padrão:**
   - Tente restaurar as permissões padrão da pasta do usuário. Para isso, clique com o botão direito do mouse na pasta, vá em "Propriedades", depois "Segurança", e clique em "Restaurar padrões".

3. **Desativar Herança de Permissão:**
   - Nas propriedades da pasta, na aba "Segurança", clique em "Avançadas" e depois em "Desabilitar Herança". Escolha "Converter permissões herdadas em permissões explícitas neste objeto".

4. **Uso do Editor de Política de Grupo Local (para versões Pro e Enterprise):**
   - Se estiver usando o Windows 11 Pro ou Enterprise, você pode verificar as configurações de política de grupo que podem estar afetando as permissões de arquivo. Digite `gpedit.msc` no menu Iniciar e verifique as configurações sob "Configuração do Computador" e "Configuração do Usuário".

5. **Executar o Comando SFC:**
   - Execute o Comando Verificador de Arquivos de Sistema (SFC) para reparar arquivos de sistema potencialmente corrompidos. Abra o Command Prompt como administrador e digite `sfc /scannow`.

6. **Consultar Suporte Técnico da Microsoft:**
   - Se as etapas acima não resolverem o problema, pode ser útil entrar em contato com o suporte técnico da Microsoft para obter assistência direta.

Essas etapas podem ajudar a identificar e resolver o problema de permissões que você está enfrentando. É importante seguir cada etapa com cuidado para evitar quaisquer problemas adicionais.

---

### USUÁRIO


Não é possível executar o CHKDSK porque o volume está sendo usado por outro
processo. Deseja agendar a verificação
deste volume para a próxima vez em que o sistema for reiniciado? (S/N)

---

### ASSISTENTE

O aviso que você recebeu ao tentar executar o `chkdsk /f` é normal quando o volume que está sendo verificado é o disco do sistema (ou seja, onde o Windows está instalado). O `chkdsk` não pode corrigir erros no disco do sistema enquanto o Windows está em execução, por isso pede para agendar a verificação na próxima reinicialização. Aqui está o que você deve fazer:

1. **Agendar Verificação de Disco:**
   - Quando solicitado "Deseja agendar a verificação deste volume para a próxima vez em que o sistema for reiniciado? (S/N)", digite `S` e pressione Enter. Isso agendará o `chkdsk` para ser executado na próxima vez que você reiniciar o seu computador.

2. **Reiniciar o Computador:**
   - Reinicie seu computador. Na inicialização, o `chkdsk` será executado antes de o Windows carregar. Pode demorar algum tempo, dependendo do tamanho do seu disco e dos problemas que encontrar.

3. **Monitorar o Processo de Verificação:**
   - O `chkdsk` exibirá o progresso na tela. É importante não desligar o computador durante este processo, pois isso pode causar danos ao sistema de arquivos.

4. **Depois da Verificação:**
   - Após a conclusão da verificação e correção de erros pelo `chkdsk`, o computador continuará a inicialização normalmente.
   - Verifique se o problema de permissões de arquivo foi resolvido após esta operação.

Se, após a execução do `chkdsk /f` e a reinicialização, você ainda enfrentar problemas com as permissões de arquivo, pode ser necessário explorar as outras soluções mencionadas anteriormente ou considerar o suporte técnico especializado.

---

