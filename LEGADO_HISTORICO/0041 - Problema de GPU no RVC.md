# 0041 - Problema de GPU no RVC

### USUÁRIO

chat ao tentar criar um novo modelo de voz no rvc web ui, porem no etapa dois menciona: Unfortunately, there is no compatible GPU available to support your training.

sendo que ja instalei o rvc anteriormente e antes constava:
0	NVIDIA GeForce GTX 1050 Ti... O que faço para arrumar?

---

### ASSISTENTE

Parece que você está lidando com um problema de detecção de GPU ao tentar usar o RealVoiceControl (RVC) para treinamento de modelos de voz. Vamos analisar de forma pragmática e criativa como você pode resolver isso:

1. **Verifique o Driver da GPU**: Certifique-se de que o driver da NVIDIA está atualizado. Acesse o site da NVIDIA e procure pela versão mais recente compatível com a GeForce GTX 1050 Ti.

2. **Reinicialize o Sistema**: Às vezes, uma reinicialização simples do sistema pode reconectar o hardware e o software corretamente.

3. **Verificação do CUDA**: O RVC utiliza o CUDA para treinamento em GPU. Garanta que a versão do CUDA seja compatível com a versão do RVC que você está utilizando.

4. **Confirme o Reconhecimento do Sistema**: Abra o "Prompt de Comando" e digite `nvidia-smi` para verificar se o sistema está reconhecendo a GPU corretamente.

5. **Permissões de Software**: Verifique se o RVC tem permissão para acessar a GPU. Isso pode incluir executar o software como administrador.

6. **Conflitos de Software**: Outros programas podem estar usando a GPU, o que impede o RVC de acessá-la. Certifique-se de fechar quaisquer softwares desnecessários.

7. **Configurações de Energia**: Em laptops, as configurações de economia de energia podem desativar o uso da GPU para economizar bateria. Verifique as configurações de energia.

8. **Reinstalação do RVC**: Às vezes, uma nova instalação pode resolver conflitos desconhecidos. Desinstale e reinstale o RVC e todas as suas dependências.

9. **Suporte Técnico**: Considere entrar em contato com o suporte técnico do RVC para obter ajuda especializada.

Se após todas essas verificações o problema persistir, pode ser necessário olhar mais a fundo no hardware ou possíveis atualizações no software que possam ter introduzido incompatibilidades. Mantenha a calma e vá passo a passo – a ansiedade pode dificultar o processo de solução de problemas, então mantenha um ritmo constante e focado.

---

