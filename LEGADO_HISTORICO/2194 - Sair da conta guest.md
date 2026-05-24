# 2194 - Sair da conta guest

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000397061f694cf0091928adee9', 'size_bytes': 4037506, 'width': 1152, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Perfeito, Felippe — dá pra resolver isso rapidamente.  
Pela foto, você está no **Windows 11** e logado como **GUEST (Conta Local – Administrador)**.  
Aqui está o passo a passo para **voltar à sua conta original** e remover ou sair da conta Guest.

---

### 🧭 ETAPA 1 — Verificar se sua conta original ainda existe
1. Pressione **`Win + R`** → digite:
   ```
   control userpasswords2
   ```
2. Na lista, veja se sua conta antiga aparece (por exemplo, “Felippe” ou o nome que você usava antes).
   - Se aparecer → ela ainda existe, e você só precisa **fazer logoff e entrar nela**.  
   - Se **não aparecer**, ela pode estar **oculta ou desabilitada** (te explico como reativar abaixo).

---

### 🧍‍♂️ ETAPA 2 — Fazer logoff da conta Guest
1. Clique no **menu Iniciar** (ícone do Windows).  
2. Clique no **ícone do seu usuário (GUEST)** no canto inferior esquerdo.  
3. Escolha **“Sair”** ou **“Trocar de usuário”**.  
4. Na tela de login, escolha sua **conta original** e digite a senha.

---

### ⚙️ ETAPA 3 — Caso sua conta não apareça (reativar via PowerShell)
Abra o **PowerShell como administrador** (botão direito no menu Iniciar → “Windows PowerShell (Admin)”)  
e execute o comando abaixo:

```powershell
# Mostrar todas as contas locais do PC
Get-LocalUser

# (Anote o nome da sua conta antiga)
# Ativar a conta se estiver desabilitada
Enable-LocalUser -Name "Felippe"
```

Depois disso, feche a sessão e tente entrar novamente.

---

### 🧹 ETAPA 4 — (Opcional) Remover a conta Guest criada pelo seu primo
> Só faça isso depois que estiver de volta à sua conta original.

1. Entre com sua conta principal (não Guest).  
2. Abra o **PowerShell como administrador** e rode:

```powershell
# Apagar conta Guest completamente
Remove-LocalUser -Name "Guest"
```

---

### ✅ Resultado esperado
Após esses passos, você deve conseguir:
- Sair da conta Guest com segurança.  
- Voltar à sua conta original (com seus arquivos e configurações).  
- Apagar a conta criada por terceiros, mantendo o sistema limpo e protegido.

---

Se quiser, posso gerar um **script PowerShell pronto (padrão TEIA)** para automatizar a verificação, logoff e restauração da sua conta original.  
Quer que eu gere isso pra você?

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000f33c61f6ba57952d2f12df0b', 'size_bytes': 642416, 'width': 1536, 'height': 1152, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Perfeito, Felippe — você está exatamente no ponto certo da transição.  
Na imagem, você está em **Painel de Controle → Contas de Usuário**, dentro da conta **GUEST (Administrador)**.  
A partir daqui, o objetivo é **voltar para sua conta original** e remover essa “Guest” criada pelo seu primo.  

---

## 🧭 CAMINHO SEGURO A PARTIR DAQUI

### 1️⃣ Clique em:
👉 **“Gerenciar outra conta”**

Isso abrirá uma tela listando **todas as contas existentes no computador**.

---

### 2️⃣ Identifique sua conta original
Procure pelo nome que você usava antes (ex: **Felippe**, **Administrador**, **User**, etc).  
Se ela aparecer na lista:

- Clique nela.  
- Se estiver desativada ou sem senha, continue para o passo 3.

Se **não aparecer**, vá direto para o passo 4 (reativar via PowerShell).

---

### 3️⃣ Fazer logoff e voltar à sua conta
1. Feche essa janela.  
2. Pressione **Ctrl + Alt + Del** → escolha **“Sair”**.  
3. Na tela de login, veja se sua conta antiga aparece.  
   - Se sim → entre nela.  
   - Se não → siga o passo 4.

---

### 4️⃣ Reativar sua conta original (caso oculta)
Abra o **PowerShell como administrador** e execute o comando abaixo:

```powershell
# Listar todas as contas do computador
Get-LocalUser

# (Veja se aparece algo como Felippe, Admin etc)
# Se aparecer com "Desabilitado: True", reative:
Enable-LocalUser -Name "Felippe"
```

Depois:
```powershell
# Feche sessão da conta Guest
shutdown /l
```

E então, **na tela de login**, você verá novamente sua conta original.

---

### 5️⃣ (Opcional) Remover a conta Guest
Quando já estiver de volta à sua conta principal, remova a conta Guest com:

```powershell
Remove-LocalUser -Name "Guest"
```

---

Quer que eu te gere um **script PowerShell completo no padrão TEIA**, que automatiza toda essa sequência (verificação, reativação e logoff da conta Guest)?  
Assim você só copia e cola — o sistema faz tudo sozinho.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000225c61f6b38cf36c78145e9a', 'size_bytes': 627927, 'width': 1536, 'height': 1152, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Perfeito, Felippe — ótima notícia: ✅  
Na imagem dá pra ver claramente que **sua conta original “Felippe Barcelos” ainda está ativa**, protegida por senha e com status de **Administrador**.  
Isso significa que **você não perdeu nada** — só está logado na conta errada (“Guest”).  

Aqui vai o passo a passo direto para **voltar à sua conta original**:

---

## 🧭 PASSOS EXATOS PARA VOLTAR À SUA CONTA

### 1️⃣ Sair da conta Guest
1. Feche todas as janelas abertas.  
2. Pressione as teclas **Ctrl + Alt + Del**.  
3. Clique em **“Sair”** (ou “Logoff”).  
   → Isso encerra a sessão atual da conta Guest.

---

### 2️⃣ Fazer login na sua conta “Felippe Barcelos”
1. Quando voltar para a tela de login do Windows, clique em  
   👉 **Felippe Barcelos**.  
2. Digite sua senha normalmente.  
3. Aguarde o carregamento — pronto, você estará de volta à sua conta original.

---

### 3️⃣ (Opcional) Remover a conta Guest depois
Depois que confirmar que está tudo funcionando, você pode apagar a conta Guest com segurança:

#### Método gráfico:
1. Volte à mesma tela que aparece na sua foto.  
2. Clique em **Guest**.  
3. Escolha **Excluir a conta**.  
4. Quando o sistema perguntar se deseja manter os arquivos → selecione **Excluir arquivos** (para limpar tudo).

#### Método PowerShell (se preferir rodar direto):
```powershell
Remove-LocalUser -Name "Guest"
```

---

### ✅ Resultado esperado
- Você voltará a usar normalmente sua conta principal (**Felippe Barcelos**).  
- Todos os seus arquivos e configurações permanecerão intactos.  
- A conta Guest deixará de aparecer e o PC voltará ao estado original.

---

Quer que eu te gere um script PowerShell no **padrão TEIA (textdoc embed Codex)** que automatize a remoção da conta Guest assim que você voltar para a sua conta principal?  
Ele faz toda a checagem e garante que nada do sistema seja afetado.

---

