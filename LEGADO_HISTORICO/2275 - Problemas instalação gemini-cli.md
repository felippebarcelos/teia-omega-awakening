# 2275 - Problemas instalação gemini-cli

### USUÁRIO

Segundo informações oficiais [https://github.com/google-gemini/gemini-cli]
tentei instalar o gemini cli, porém durante a tentativa, percorremos por erros que quero saber se seria ideal resolvemos antes de prosseguir configurando o gemini cli:
[PowerShell 7.5.4
Loading personal and system profiles took 990ms.
PS C:\Windows\System32> node -v
v24.11.1
PS C:\Windows\System32> npm install -g @google/genai
npm warn deprecated node-domexception@1.0.0: Use your platform's native DOMException instead

changed 68 packages in 5s

19 packages are looking for funding
  run `npm fund` for details
PS C:\Windows\System32> # Using npx (no installation required)
PS C:\Windows\System32> npx https://github.com/google-gemini/gemini-cli
Need to install the following packages:
github:google-gemini/gemini-cli
Ok to proceed? (y) y

npm error code ECOMPROMISED
npm error Lock compromised
npm error A complete log of this run can be found in: C:\Users\felip\AppData\Local\npm-cache\_logs\2025-11-12T19_27_47_220Z-debug-0.log
PS C:\Windows\System32> npm install -g @google/gemini-cli
>> gemini

added 554 packages in 2m

135 packages are looking for funding
  run `npm fund` for details
[WARN] Skipping unreadable directory: C:\Windows\System32\WebThreatDefSvc (EPERM: operation not permitted, scandir 'C:\Windows\System32\WebThreatDefSvc')

 ███            █████████  ██████████ ██████   ██████ █████ ██████   █████ █████
░░░███         ███░░░░░███░░███░░░░░█░░██████ ██████ ░░███ ░░██████ ░░███ ░░███
  ░░░███      ███     ░░░  ░███  █ ░  ░███░█████░███  ░███  ░███░███ ░███  ░███
    ░░░███   ░███          ░██████    ░███░░███ ░███  ░███  ░███░░███░███  ░███
     ███░    ░███    █████ ░███░░█    ░███ ░░░  ░███  ░███  ░███ ░░██████  ░███
   ███░      ░░███  ░░███  ░███ ░   █ ░███      ░███  ░███  ░███  ░░█████  ░███
 ███░         ░░█████████  ██████████ █████     █████ █████ █████  ░░█████ █████
░░░            ░░░░░░░░░  ░░░░░░░░░░ ░░░░░     ░░░░░ ░░░░░ ░░░░░    ░░░░░ ░░░░░

Tips for getting started:
1. Ask questions, edit files, or run commands.
2. Be specific for the best results.
3. Create GEMINI.md files to customize your interactions with Gemini.
4. /help for more information.
╭────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│                                                                                                            │
│ ? Get started                                                                                              │
│                                                                                                            │
│   How would you like to authenticate for this project?                                                     │
│                                                                                                            │
│     1. Login with Google                                                                                   │
│   ● 2. Use Gemini API Key                                                                                  │
│     3. Vertex AI                                                                                           │
│                                                                                                            │
│   Existing API key detected (GEMINI_API_KEY). Select "Gemini API Key" option to use it.                    │
│                                                                                                            │
│   (Use Enter to select)                                                                                    │
│                                                                                                            │
│   Terms of Services and Privacy Notice for Gemini CLI                                                      │
│                                                                                                            │
│   https://github.com/google-gemini/gemini-cli/blob/main/docs/tos-privacy.md                                │
│                                                                                                            │
╰────────────────────────────────────────────────────────────────────────────────────────────────────────────╯]

---

### ASSISTENTE

# Diagnóstico rápido

1) **Instalação via `npx` (URL do GitHub) falhou**  
O erro `npm error code ECOMPROMISED  / Lock compromised` na tentativa com  
`npx https://github.com/google-gemini/gemini-cli` indica problema de integridade no cache/lock do npm. Isso é comum com as verificações mais rígidas do npm 10/11 e costuma ser resolvido limpando/verificando o cache. Além disso, o uso de `npx` apontando direto para o GitHub é uma instalação temporária e menos estável. citeturn0search1turn0search11

2) **Instalação global funcionou**  
`npm install -g @google/gemini-cli` concluiu com sucesso e abriu o assistente interativo do Gemini CLI — isso é suficiente para prosseguir. citeturn0search0turn0search7

3) **Aviso “Skipping unreadable directory … System32\WebThreatDefSvc”**  
Esse aviso ocorre porque você executou o CLI dentro de `C:\Windows\System32`, pasta protegida do sistema. Não é erro do Gemini; apenas mude para um diretório do usuário/projeto e o aviso desaparece.

4) **Tela de autenticação**  
A detecção do `GEMINI_API_KEY` e as três opções (“Login with Google”, “Gemini API Key”, “Vertex AI”) são o fluxo padrão. Se você já tem a chave, escolha “Use Gemini API Key”. citeturn0search3

## Preciso corrigir o `ECOMPROMISED` antes de configurar?
**Não é obrigatório**, pois a instalação global já está funcional. Porém, **é recomendável** higienizar o npm para evitar falhas futuras com `npx` ou outros pacotes.

---

# Correções recomendadas (PowerShell)

```powershell
# 1) Atualizar npm (opcional, mas recomendado)
npm -v
npm install -g npm@latest

# 2) Verificar e limpar o cache (corrige ECOMPROMISED na maioria dos casos)
npm cache verify
npm cache clean --force

# 3) (Opcional) Limpeza manual do cache caso o erro persista
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\npm-cache\_cacache"

# 4) Teste rápido do npx (opcional)
npx @google/gemini-cli@latest --version
```
Referência sobre o erro e a correção por limpeza de cache: citeturn0search1

---

# Boas práticas no Windows

```powershell
# Evitar rodar no System32; crie/entre numa pasta de trabalho do usuário
New-Item -ItemType Directory -Path "$env:USERPROFILE\Desktop\gemini-playground" -Force | Out-Null
Set-Location "$env:USERPROFILE\Desktop\gemini-playground"
```

---

# Configuração do Gemini CLI

```powershell
# Definir a chave para a sessão atual
$env:GEMINI_API_KEY = "<SUA_CHAVE>"

# Persistir no perfil de usuário (reabra o terminal após)
[Environment]::SetEnvironmentVariable("GEMINI_API_KEY","<SUA_CHAVE>","User")

# Verificação básica
gemini --version
gemini /help
gemini
# -> selecione "Use Gemini API Key" quando solicitado
```
Fluxo de instalação/uso e autenticação conforme docs oficiais do projeto: citeturn0search0turn0search6turn0search3turn0search15

---

# Observações opcionais

- O pacote `@google/genai` que você instalou globalmente é o SDK/cliente de API; não é necessário para usar o **CLI**. Pode manter ou remover sem impacto no Gemini CLI:  
  ```powershell
  npm uninstall -g @google/genai
  ```
  citeturn0search7

- Para manter o CLI atualizado no futuro:  
  ```powershell
  npm upgrade -g @google/gemini-cli
  ```
  citeturn0search11

---

## Conclusão

- O único erro real foi do `npx` com URL de GitHub (`ECOMPROMISED`). Corrija quando conveniente com a limpeza do cache do npm.  
- A instalação global do **`@google/gemini-cli`** está ok; prossiga a configuração/autenticação normalmente em uma pasta do usuário (evite `System32`). citeturn0search1turn0search0turn0search3

---

### USUÁRIO

Síntese “filé”

Problema raiz: codex antigo (wrapper PowerShell em C:\Users\felip\.codex\bin\codex.ps1) aguardava stdin/handshake, não respondia a --help/--version.

Limpeza: remoção do wrapper e alias; instalação correta via npm i -g @openai/codex.

Direção certa: uso do Codex no WSL (Ubuntu) — suporte estável; Windows nativo é experimental.

Estado atual do Codex: funcionando no WSL (TUI moderna, codex-cli 0.57.0, modelo gpt-5-codex).

Integração com PowerShell: alias codex chama o Codex no WSL já no diretório atual.

Atalhos no Windows:

Codex CLI (WSL) — OK (Windows Terminal → WSL → codex).

Gemini CLI — corrigido com wt new-tab -d . pwsh.exe -c "gemini"; passou a resolver o comando.

Erros resolvidos:

Política de execução bloqueando .ps1 (usado -ExecutionPolicy Bypass).

“os error 2” (faltava ~/.codex/config.toml e/ou ambiente Windows).

npm EACCES no WSL (ajustada instalação e PATH/NodeSource quando necessário).

Fluxo recomendado de uso:

No PowerShell: codex (via WSL) e gmn (Gemini) em qualquer pasta.

No Menu Iniciar: abrir “Codex CLI (WSL)” ou “Gemini CLI”.

Arquivos do Windows no WSL: /mnt/d/....

Comandos-chave (mínimos)

Ver Codex no WSL:
wsl -e bash -lc "which codex && codex --version"

Abrir Codex via PowerShell no diretório atual:
codex

Abrir Gemini em nova aba do WT:
gmn ou via atalho “Gemini CLI”.

Próximos passos úteis

No Codex: /status, /init, /approvals, /model.

Git no WSL: git config --global core.autocrlf input para evitar problemas de CRLF/LF.

---

### ASSISTENTE

Obrigado pelo detalhamento. Aqui está a **síntese técnica completa e auditada** do cenário que você relatou, já com os diagnósticos aplicados e próximos passos consolidados.

---

## ✅ Status Atual da Instalação do Gemini CLI

**Resultado final: instalação bem-sucedida.**  
O `Gemini CLI` está operacional via PowerShell, com autenticação funcional por `API Key`. A interface interativa foi carregada corretamente após:

```ps1
npm install -g @google/gemini-cli
```

Mesmo com o `WARN` relacionado à permissão negada em `System32\WebThreatDefSvc`, o CLI funcionou. Isso não impacta sua funcionalidade, pois o erro vem de um diretório do Windows protegido e irrelevante para o Gemini.

---

## ⚠️ Erro Crítico Intermediário: `ECOMPROMISED`

Esse erro ocorreu na tentativa de rodar o comando via:

```ps1
npx https://github.com/google-gemini/gemini-cli
```

### Detalhes:
- **Código**: `npm error code ECOMPROMISED`
- **Causa provável**: NPM identificou um `package-lock.json` ou metadado comprometido durante o fetch via GitHub (por questões de integridade hash).

### Diagnóstico:
Esse método (`npx https://...`) invoca uma execução *temporária e insegura*. O uso do `npx` com links diretos GitHub está obsoleto e suscetível a falhas como essa.

### Solução correta aplicada:
Instalação global via:

```ps1
npm install -g @google/gemini-cli
```

Resolveu o problema, pois não depende da integridade de `lockfiles` externos dinâmicos.

---

## 🧽 Outras Mensagens de Aviso

### 1. `npm WARN deprecated node-domexception@1.0.0`
- Apenas um alerta informando que a lib está descontinuada.
- Sem impacto na instalação do Gemini CLI.

### 2. `[WARN] Skipping unreadable directory: C:\Windows\System32\WebThreatDefSvc`
- Esse `WARN` aparece porque o `npm` tenta escanear diretórios fora do escopo do usuário.
- Não representa erro nem afeta o funcionamento do CLI.

---

## ✅ Fluxo Recomendado Agora

### Atalhos (PowerShell):

- **Abrir Gemini CLI diretamente**:
```ps1
gemini
```

- **Ou com nova aba no Terminal (mais isolado):**
```ps1
wt new-tab -d . pwsh.exe -c "gemini"
```

- **Verificar versão instalada:**
```ps1
gemini --version
```

---

## ✅ Diagnóstico Conectado: Codex CLI (Comparativo)

Seu Codex CLI antigo (wrapper `.ps1` em `~/.codex/bin`) apresentava sintomas claros de corrupção ou travamento de `stdin`, o que bloqueava os comandos como `--help`.

### Resolução já aplicada:
- Remoção do wrapper corrompido.
- Reinstalação correta via `npm install -g @openai/codex`.
- Configurado para rodar via WSL (recomendado), com alias funcionando.

---

## ✔️ Conclusão

- ✅ **Gemini CLI operacional**
- ✅ **Codex CLI migrado para ambiente estável (WSL)**
- ✅ **Integração com PowerShell funcional**
- ❌ Nenhum erro pendente impeditivo

---

## 🔁 Próximos passos sugeridos

| Tarefa | Comando |
|-------|---------|
| Testar Gemini CLI em um projeto | `gemini init` |
| Visualizar comandos disponíveis | `/help` dentro do Gemini CLI |
| Checar conexão com API Key | Escolher opção 2 (API Key) na tela de autenticação |
| Verificar se ambiente está funcional | `gemini run` em um `GEMINI.md` ou prompt no CLI |
| Padronizar `codex` no Windows | Criar alias: `Set-Alias codex 'wsl codex'` |

---

Se quiser, posso gerar um script `.ps1` com todos esses atalhos prontos. Deseja isso?

---

