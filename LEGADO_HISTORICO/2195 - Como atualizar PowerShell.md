# 2195 - Como atualizar PowerShell

### USUÁRIO

" A new PowerShell stable release is available: v7.5.4
   Upgrade now, or check out the release page at:
     https://aka.ms/PowerShell-Release?tag=v7.5.4"
Como atualizar

---

### ASSISTENTE

Successfully created text document 'Atualizar-power Shell-7.5.4' which will be referenced in all future messages with the unique identifier textdoc_id: '68f913485f9481919b1e3e1d2884eb7d'

Important: This identifier is for tool calls only to reference or update this document. It is not an external ID and it is not possible to link the user to the textdoc.

---

### ASSISTENTE

Segue o caminho mais simples 👇

1) **Windows (recomendado – WinGet)**
- Abra o **PowerShell como Administrador**.
- Rode:
```powershell
winget upgrade --id Microsoft.PowerShell -e --accept-source-agreements --accept-package-agreements --silent
```
- Feche e reabra o PowerShell 7 e confira:
```powershell
$PSVersionTable.PSVersion
```
(WinGet é o método recomendado pela Microsoft para instalar/atualizar o PowerShell 7.5. Em caso de ambiguidade, use `-e` para correspondência exata do pacote.) citeturn0search0turn0search4

2) **Sem WinGet / Ambiente restrito**
- Baixe o instalador **MSI** direto da página oficial do release **v7.5.4** e instale (x64, ARM64, etc., conforme seu sistema): citeturn0search0  
  https://aka.ms/PowerShell-Release?tag=v7.5.4

3) **(Opcional) Habilitar atualização via Microsoft Update**
- Você pode integrar o PowerShell 7 ao **Microsoft Update**, para receber updates pelo Windows Update/WSUS. Veja “Instalar o PowerShell no Windows” (seção MU) para habilitar. citeturn0search3

—

### Script pronto (PowerShell) — 1 clique no botão “Download”
Criei um script idempotente que:
- verifica Admin,
- tenta atualizar via WinGet,
- faz fallback abrindo a página oficial v7.5.4 se WinGet não estiver disponível.

Abra o arquivo no painel ao lado: **“Atualizar-PowerShell-7.5.4.ps1”**  
Passos:
1. Clique em **Download** no arquivo ao lado.
2. **Execute como Administrador**.
3. Ao terminar, feche/reabra o PowerShell e verifique com `$PSVersionTable.PSVersion`.

Se quiser, posso incluir uma variante que força **x64 MSI** específico do seu hardware.

---

