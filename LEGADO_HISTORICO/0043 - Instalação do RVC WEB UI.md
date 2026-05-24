# 0043 - Instalação do RVC WEB UI

### USUÁRIO

chat quero instalar o RVC WEB UI para meu imac, segundo os dados do site oficial, me instrua a fazer cada passo:
底模使用接近50小时的开源高质量VCTK训练集训练，无版权方面的顾虑，请大家放心使用

请期待RVCv3的底模，参数更大，数据更大，效果更好，基本持平的推理速度，需要训练数据量更少。

简介
本仓库具有以下特点

使用top1检索替换输入源特征为训练集特征来杜绝音色泄漏
即便在相对较差的显卡上也能快速训练
使用少量数据进行训练也能得到较好结果(推荐至少收集10分钟低底噪语音数据)
可以通过模型融合来改变音色(借助ckpt处理选项卡中的ckpt-merge)
简单易用的网页界面
可调用UVR5模型来快速分离人声和伴奏
使用最先进的人声音高提取算法InterSpeech2023-RMVPE根绝哑音问题。效果最好（显著地）但比crepe_full更快、资源占用更小
A卡I卡加速支持
环境配置
以下指令需在 Python 版本大于3.8的环境中执行。

(Windows/Linux)
首先通过 pip 安装主要依赖:

# 安装Pytorch及其核心依赖，若已安装则跳过
# 参考自: https://pytorch.org/get-started/locally/
pip install torch torchvision torchaudio

#如果是win系统+Nvidia Ampere架构(RTX30xx)，根据 #21 的经验，需要指定pytorch对应的cuda版本
#pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117
可以使用 poetry 来安装依赖：

# 安装 Poetry 依赖管理工具, 若已安装则跳过
# 参考自: https://python-poetry.org/docs/#installation
curl -sSL https://install.python-poetry.org | python3 -

# 通过poetry安装依赖
poetry install
你也可以通过 pip 来安装依赖：

N卡：
  pip install -r requirements.txt

A卡/I卡：
  pip install -r requirements-dml.txt

A卡Rocm（Linux）：
  pip install -r requirements-amd.txt

I卡IPEX（Linux）：
  pip install -r requirements-ipex.txt
Mac 用户可以通过 run.sh 来安装依赖：

sh ./run.sh
其他预模型准备
RVC需要其他一些预模型来推理和训练。

你可以从我们的Hugging Face space下载到这些模型。

以下是一份清单，包括了所有RVC所需的预模型和其他文件的名称:

./assets/hubert/hubert_base.pt

./assets/pretrained 

./assets/uvr5_weights

想测试v2版本模型的话，需要额外下载

./assets/pretrained_v2

如果你正在使用Windows，则你可能需要这个文件，若ffmpeg和ffprobe已安装则跳过; ubuntu/debian 用户可以通过apt install ffmpeg来安装这2个库, Mac 用户则可以通过brew install ffmpeg来安装 (需要预先安装brew)

./ffmpeg

https://huggingface.co/lj1995/VoiceConversionWebUI/blob/main/ffmpeg.exe

./ffprobe

https://huggingface.co/lj1995/VoiceConversionWebUI/blob/main/ffprobe.exe

如果你想使用最新的RMVPE人声音高提取算法，则你需要下载音高提取模型参数并放置于RVC根目录

https://huggingface.co/lj1995/VoiceConversionWebUI/blob/main/rmvpe.pt

    A卡I卡用户需要的dml环境要请下载

    https://huggingface.co/lj1995/VoiceConversionWebUI/blob/main/rmvpe.onnx
之后使用以下指令来启动WebUI:

python infer-web.py
如果你正在使用Windows 或 macOS，你可以直接下载并解压RVC-beta.7z，前者可以运行go-web.bat以启动WebUI，后者则运行命令sh ./run.sh以启动WebUI。

对于需要使用IPEX技术的I卡用户，请先在终端执行source /opt/intel/oneapi/setvars.sh（仅Linux）。

仓库内还有一份小白简易教程.doc以供参考。

AMD显卡Rocm相关（仅Linux）
如果你想基于AMD的Rocm技术在Linux系统上运行RVC，请先在这里安装所需的驱动。

若你使用的是Arch Linux，可以使用pacman来安装所需驱动：

pacman -S rocm-hip-sdk rocm-opencl-sdk
对于某些型号的显卡，你可能需要额外配置如下的环境变量（如：RX6700XT）：

export ROCM_PATH=/opt/rocm
export HSA_OVERRIDE_GFX_VERSION=10.3.0
同时确保你的当前用户处于render与video用户组内：

sudo usermod -aG render $USERNAME
sudo usermod -aG video $USERNAME
之后运行WebUI：

python infer-web.py
参考项目
ContentVec
VITS
HIFIGAN
Gradio
FFmpeg
Ultimate Vocal Remover
audio-slicer
Vocal pitch extraction:RMVPE
The pretrained model is trained and tested by yxlllc and RVC-Boss.


---

### USUÁRIO

chat eu instalei o rvc web ui e todos os arquivos necessarios, porem começou a dar erro e gostaria de apagar todos os dados relacionados a esse programa do meu computador para futuramente reinstalar e nao dar nenhum conflito como esta acontecendo agora, saiba que baizei o visual studio c++ e até a anaconda, agora me ajude, segundo os dados do site oficial, me instrua a fazer cada passo para removelos do meu sistema:
底模使用接近50小时的开源高质量VCTK训练集训练，无版权方面的顾虑，请大家放心使用

请期待RVCv3的底模，参数更大，数据更大，效果更好，基本持平的推理速度，需要训练数据量更少。

简介
本仓库具有以下特点

使用top1检索替换输入源特征为训练集特征来杜绝音色泄漏
即便在相对较差的显卡上也能快速训练
使用少量数据进行训练也能得到较好结果(推荐至少收集10分钟低底噪语音数据)
可以通过模型融合来改变音色(借助ckpt处理选项卡中的ckpt-merge)
简单易用的网页界面
可调用UVR5模型来快速分离人声和伴奏
使用最先进的人声音高提取算法InterSpeech2023-RMVPE根绝哑音问题。效果最好（显著地）但比crepe_full更快、资源占用更小
A卡I卡加速支持
环境配置
以下指令需在 Python 版本大于3.8的环境中执行。

(Windows/Linux)
首先通过 pip 安装主要依赖:

# 安装Pytorch及其核心依赖，若已安装则跳过
# 参考自: https://pytorch.org/get-started/locally/
pip install torch torchvision torchaudio

#如果是win系统+Nvidia Ampere架构(RTX30xx)，根据 #21 的经验，需要指定pytorch对应的cuda版本
#pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117
可以使用 poetry 来安装依赖：

# 安装 Poetry 依赖管理工具, 若已安装则跳过
# 参考自: https://python-poetry.org/docs/#installation
curl -sSL https://install.python-poetry.org | python3 -

# 通过poetry安装依赖
poetry install
你也可以通过 pip 来安装依赖：

N卡：
  pip install -r requirements.txt

A卡/I卡：
  pip install -r requirements-dml.txt

A卡Rocm（Linux）：
  pip install -r requirements-amd.txt

I卡IPEX（Linux）：
  pip install -r requirements-ipex.txt
Mac 用户可以通过 run.sh 来安装依赖：

sh ./run.sh
其他预模型准备
RVC需要其他一些预模型来推理和训练。

你可以从我们的Hugging Face space下载到这些模型。

以下是一份清单，包括了所有RVC所需的预模型和其他文件的名称:

./assets/hubert/hubert_base.pt

./assets/pretrained 

./assets/uvr5_weights

想测试v2版本模型的话，需要额外下载

./assets/pretrained_v2

如果你正在使用Windows，则你可能需要这个文件，若ffmpeg和ffprobe已安装则跳过; ubuntu/debian 用户可以通过apt install ffmpeg来安装这2个库, Mac 用户则可以通过brew install ffmpeg来安装 (需要预先安装brew)

./ffmpeg

https://huggingface.co/lj1995/VoiceConversionWebUI/blob/main/ffmpeg.exe

./ffprobe

https://huggingface.co/lj1995/VoiceConversionWebUI/blob/main/ffprobe.exe

如果你想使用最新的RMVPE人声音高提取算法，则你需要下载音高提取模型参数并放置于RVC根目录

https://huggingface.co/lj1995/VoiceConversionWebUI/blob/main/rmvpe.pt

    A卡I卡用户需要的dml环境要请下载

    https://huggingface.co/lj1995/VoiceConversionWebUI/blob/main/rmvpe.onnx
之后使用以下指令来启动WebUI:

python infer-web.py
如果你正在使用Windows 或 macOS，你可以直接下载并解压RVC-beta.7z，前者可以运行go-web.bat以启动WebUI，后者则运行命令sh ./run.sh以启动WebUI。

对于需要使用IPEX技术的I卡用户，请先在终端执行source /opt/intel/oneapi/setvars.sh（仅Linux）。

仓库内还有一份小白简易教程.doc以供参考。

AMD显卡Rocm相关（仅Linux）
如果你想基于AMD的Rocm技术在Linux系统上运行RVC，请先在这里安装所需的驱动。

若你使用的是Arch Linux，可以使用pacman来安装所需驱动：

pacman -S rocm-hip-sdk rocm-opencl-sdk
对于某些型号的显卡，你可能需要额外配置如下的环境变量（如：RX6700XT）：

export ROCM_PATH=/opt/rocm
export HSA_OVERRIDE_GFX_VERSION=10.3.0
同时确保你的当前用户处于render与video用户组内：

sudo usermod -aG render $USERNAME
sudo usermod -aG video $USERNAME
之后运行WebUI：

python infer-web.py
参考项目
ContentVec
VITS
HIFIGAN
Gradio
FFmpeg
Ultimate Vocal Remover
audio-slicer
Vocal pitch extraction:RMVPE
The pretrained model is trained and tested by yxlllc and RVC-Boss.


---

### ASSISTENTE

Instalar e configurar o RVC WEB UI no seu iMac envolve uma série de passos que incluem instalar dependências, baixar pré-modelos e executar o servidor web. Aqui está um guia passo a passo:

### Passo 1: Configuração do Ambiente

**Nota**: O RVC WEB UI é otimizado para GPUs NVIDIA e AMD, e pode não ser totalmente suportado em um iMac, a menos que você tenha um ambiente com uma GPU externa suportada ou use CPUs para inferência (o que pode ser menos eficiente). As instruções de instalação fornecidas são para Linux e Windows principalmente.

1. Verifique a versão do Python:
   - No terminal do seu iMac, verifique se tem o Python 3.8 ou superior instalado com o comando `python3 --version`.

2. Instalar o PyTorch e suas dependências:
   - O PyTorch é uma dependência principal do RVC WEB UI. Você pode instalar utilizando o pip:
     ```shell
     pip3 install torch torchvision torchaudio
     ```

3. Instalar o Poetry:
   - O Poetry é um gerenciador de dependências para Python, você pode instalá-lo seguindo as instruções em [https://python-poetry.org/docs/#installation](https://python-poetry.org/docs/#installation).

4. Clonar o repositório RVC WEB UI:
   - No terminal, navegue até o diretório onde deseja instalar o RVC e clone o repositório:
     ```shell
     git clone [URL do repositório]
     cd [nome do diretório clonado]
     ```

5. Instalar dependências adicionais:
   - Com o Poetry:
     ```shell
     poetry install
     ```
   - Ou com o pip, se for fornecido um arquivo `requirements.txt`.

### Passo 2: Baixar os Pré-Modelos

1. Baixar os pré-modelos e outros arquivos necessários do espaço Hugging Face mencionado. Coloque esses arquivos nos diretórios apropriados dentro do diretório clonado.

### Passo 3: Configurar o FFmpeg

1. Se não tiver o FFmpeg instalado no seu iMac, você pode instalá-lo via Homebrew com o comando:
   ```shell
   brew install ffmpeg
   ```

### Passo 4: Executar o Servidor WebUI

1. Inicie o WebUI utilizando o Python:
   ```shell
   python3 infer-web.py
   ```
   Isso deve iniciar o servidor web e o RVC WEB UI deverá estar acessível através do navegador.

**Nota Importante**: Este guia foi simplificado para caber na sua solicitação de brevidade. As instruções específicas do Mac não estão diretamente fornecidas no trecho que você enviou, mas você pode tentar adaptar os passos para o macOS.

**Dicas adicionais**:
- Se você encontrar problemas, verifique a documentação específica para o macOS ou considere a possibilidade de usar um ambiente de máquina virtual ou Docker que simule um ambiente Linux.
- A instalação de pré-modelos e bibliotecas de aceleração de GPU (AMD/NVIDIA) pode não ser aplicável diretamente ao seu iMac, a menos que você tenha um setup compatível.
- Certifique-se de que o `python3` e o `pip3` estão apontando para as versões corretas do Python e pip no seu iMac.
- Se você encontrar dificuldades ou erros durante a instalação, a comunidade de desenvolvimento geralmente fornece suporte através de fóruns e issues no GitHub.

Espero que este guia ajude a começar. Boa sorte com a sua configuração!

---

### ASSISTENTE

Para remover completamente o RVC Web UI e suas dependências relacionadas do seu sistema e evitar conflitos em futuras reinstalações, você precisará seguir vários passos para desinstalar o software e excluir os arquivos relevantes. Aqui está um guia passo a passo:

### Desinstalar o RVC e Dependências via PIP

Se você instalou dependências usando `pip`, pode desinstalá-las com o comando `pip uninstall`. Abra o terminal ou prompt de comando e execute os seguintes comandos:

```shell
pip uninstall torch torchvision torchaudio
# Repita o comando para qualquer outra dependência que tenha instalado via pip.
```

### Remover Pacotes do Poetry

Se você usou `poetry` para gerenciar dependências:

1. Navegue até o diretório onde você tem o projeto RVC.
2. Execute o seguinte comando:

```shell
poetry env remove python
```

Isso removerá o ambiente virtual associado ao seu projeto.

### Remover Arquivos de Configuração e Pré-modelos

Exclua manualmente a pasta do projeto RVC e quaisquer pré-modelos baixados do Hugging Face ou outros locais. Isso geralmente envolve simplesmente mover a pasta para a lixeira ou usar o comando `rm` em sistemas Unix-like.

### Desinstalar o Anaconda

Se você instalou o Anaconda, pode desinstalá-lo através do painel de controle no Windows ou usando o script de desinstalação no macOS ou Linux:

```shell
# Para macOS e Linux
bash ~/anaconda3/bin/anaconda-clean
rm -rf ~/anaconda3
```

### Desinstalar Visual Studio C++

Para o Visual Studio C++ Redistributable, você pode desinstalá-lo através do "Programas e Recursos" no Painel de Controle do Windows, selecionando-o na lista e clicando em "Desinstalar".

### Limpeza Final

Após a desinstalação, é uma boa prática verificar se sobraram pastas ou arquivos relacionados ao RVC Web UI e removê-los manualmente, se necessário. Também verifique as variáveis de ambiente para referências a qualquer software que você desinstalou e remova essas entradas.

### Reconfiguração do Sistema

Reinicie o seu computador para garantir que todas as mudanças entrem em efeito e que qualquer arquivo bloqueado seja removido.

### Nota Importante

Os comandos específicos podem variar dependendo do seu sistema operacional. O processo acima assumiu uma mistura de ambientes Windows e Unix-like; ajuste conforme necessário para o seu caso.

**Atenção:** A manipulação de arquivos de sistema e a desinstalação de softwares podem afetar a estabilidade do seu sistema se feitas incorretamente. Sempre faça backups antes de proceder com operações desse tipo.

Se você precisar de instruções mais detalhadas para algum dos passos, me avise para que eu possa fornecer comandos e passos mais específicos.

---

### USUÁRIO

PS C:\Users\felip> cd C:\Windows\System32\RVC1006Nvidia\RVC1006Nvidia\
PS C:\Windows\System32\RVC1006Nvidia\RVC1006Nvidia> poetry env remove python
poetry : O termo 'poetry' não é reconhecido como nome de cmdlet, função, arquivo de script ou programa operável.
Verifique a grafia do nome ou, se um caminho tiver sido incluído, veja se o caminho está correto e tente novamente.
No linha:1 caractere:1
+ poetry env remove python
+ ~~~~~~
    + CategoryInfo          : ObjectNotFound: (poetry:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException

PS C:\Windows\System32\RVC1006Nvidia\RVC1006Nvidia>

---

### ASSISTENTE

Parece que você está tendo problemas com o comando `poetry`, o qual não está sendo reconhecido pelo PowerShell. Isso geralmente significa que o Poetry não está instalado corretamente ou o seu caminho de sistema não inclui o diretório onde o Poetry foi instalado. Aqui estão algumas etapas para solucionar esse problema e limpar o seu ambiente:

1. **Desinstalar Poetry**:
   - Se você lembra como o Poetry foi instalado (por exemplo, via `pip` ou pelo script de instalação), você pode tentar desinstalá-lo com o mesmo método. Se foi via pip, tente o seguinte comando:
     ```shell
     pip uninstall poetry
     ```
   - Se foi instalado por um script de instalação, você pode tentar reinstalar e depois desinstalar para assegurar que seja removido corretamente.

2. **Remover manualmente o ambiente do Poetry**:
   - Se o Poetry foi instalado, mas não está sendo reconhecido, talvez seja necessário adicioná-lo ao PATH manualmente ou iniciar uma nova sessão do PowerShell.
   - Se você deseja apenas remover o ambiente associado ao projeto RVC, você pode encontrar o caminho do ambiente e excluí-lo manualmente. Para isso, verifique a localização dos ambientes do Poetry com:
     ```shell
     poetry env list --full-path
     ```
     Em seguida, remova a pasta do ambiente correspondente.

3. **Limpar o projeto**:
   - Apague todos os arquivos baixados relacionados ao RVC, incluindo modelos e dependências.

4. **Desinstalar Anaconda (opcional)**:
   - Se você não precisa mais da Anaconda, pode desinstalá-la através do Painel de Controle ou com o seguinte comando no Anaconda Prompt:
     ```shell
     conda remove --all
     ```
   - Isso removerá o Anaconda e todos os ambientes e pacotes associados.

5. **Desinstalar o Visual Studio C++**:
   - Se foi instalado especificamente para o RVC e não é mais necessário, desinstale-o através do Painel de Controle ou do instalador do Visual Studio.

6. **Remover manualmente as pastas do RVC**:
   - Após desinstalar tudo o que foi instalado para o RVC, você pode remover a pasta `C:\Windows\System32\RVC1006Nvidia\RVC1006Nvidia\` manualmente no Explorador de Arquivos ou com o comando:
     ```shell
     Remove-Item -Recurse -Force 'C:\Windows\System32\RVC1006Nvidia\RVC1006Nvidia\'
     ```
     **Atenção**: Tenha muito cuidado ao usar comandos que excluem arquivos, especialmente dentro de `System32`. Você deve ter certeza absoluta do caminho que está deletando para evitar danificar seu sistema operacional.

7. **Limpeza do sistema**:
   - Por último, você pode usar ferramentas como CCleaner ou a Limpeza de Disco do próprio Windows para remover arquivos temporários e entradas de registro que podem ter sido deixadas para trás.

Depois de seguir estas etapas, seu sistema deve estar limpo dos componentes do RVC, e você poderá começar do zero se quiser tentar reinstalá-lo futuramente.

---

