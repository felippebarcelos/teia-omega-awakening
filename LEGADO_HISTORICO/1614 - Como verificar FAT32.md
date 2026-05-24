# 1614 - Como verificar FAT32

### USUÁRIO

como ddescobrir rapido se o meu pendrive esta formatado em fat32?

---

### ASSISTENTE

Você pode descobrir rapidamente se o seu pendrive está formatado em **FAT32** de várias formas, dependendo do sistema operacional que você está utilizando. Aqui estão os métodos para Windows, macOS e Linux:

---

### 🪟 **No Windows**

1. **Explorador de Arquivos**:
   - Conecte o pendrive.
   - Abra o **Explorador de Arquivos** (`Windows + E`).
   - Clique com o botão direito na unidade do pendrive.
   - Selecione **Propriedades**.
   - Veja a informação ao lado de **Sistema de arquivos**.  
     → Se aparecer “FAT32”, está confirmado.

2. **Prompt de Comando (rápido)**:
   - Pressione `Win + R`, digite `cmd`, pressione Enter.
   - Digite:
     ```cmd
     chkdsk X:
     ```
     (Substitua `X` pela letra do seu pendrive.)
   - A primeira linha vai mostrar: `tipo do sistema de arquivos é FAT32` (ou NTFS/exFAT/etc).

---

### 🍎 **No macOS**

1. Abra o **Utilitário de Disco** (`Command + Espaço` → digite “Utilitário de Disco”).
2. Selecione o pendrive na barra lateral.
3. Na parte inferior da janela, observe o **Formato**.  
   → Se for `MS-DOS (FAT32)`, é FAT32.

---

### 🐧 **No Linux**

1. No terminal, use:
   ```bash
   lsblk -f
   ```
   ou
   ```bash
   df -Th
   ```
   - Localize o dispositivo USB (`/dev/sdX1`) e veja a coluna `FSTYPE`.
   - Se for `vfat`, isso indica FAT32 (ou FAT16, dependendo do tamanho).

---

### Dica Extra

Se quiser alterar ou confirmar com precisão técnica:
- Use ferramentas como **GParted** (Linux) ou **MiniTool Partition Wizard** (Windows) para uma leitura avançada da estrutura da partição.

Se quiser, posso te ajudar a criar um script simples para checagem automática e rápida. Deseja isso para Windows, Linux ou outro sistema?

---

