# 1919 - Liberar espaço disco C

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'file-service://file-VLQ75YSdmdCeSnoddBZjeA', 'size_bytes': 306166, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

### Diagnóstico rápido a partir da captura

| Item | Tamanho | Observações |
|------|---------|-------------|
| **Arquivos do sistema** | 14,8 GB | ​​Normal para Win 11; pode cair ±2 GB após limpeza de componentes. |
| **Armazenamento reservado** | 6,73 GB | ​​Espaço que o Windows reserva para updates. Pode ser reduzido ou desativado. |
| **Memória virtual (pagefile.sys)** | 3,26 GB | ​​Pode ser movida ou redimensionada. |
| **Arquivo de hibernação (hiberfil.sys)** | 3,16 GB | ​​Libera ≈ 3 GB se a hibernação for desativada. |

SSD de 120 GB enche rápido; seu HD de 1 TB é candidato natural para receber tudo que não precise da velocidade do SSD.

---

## Plano de liberação em quatro camadas

> **Siga na ordem; cada camada já cria espaço antes de avançar para a próxima.**

---

### 1 – *Quick Wins* (5-15 min)

1. **Storage Sense manual**  
   `Configurações ▸ Sistema ▸ Armazenamento ▸ Sensor de armazenamento ▸ Executar agora`.

2. **Limpeza de Disco (Cleanmgr)**  
   ```
   Win + R → cleanmgr /sageset:1
   selecione tudo (inclusive “Limpeza do Windows Update”)
   Win + R → cleanmgr /sagerun:1
   ```

3. **Remover arquivos temporários grandes**  
   `Win + R → %TEMP%` e `C:\Windows\Temp`.  Shift + Delete.

4. **Desinstalar apps que não usa**  
   `Configurações ▸ Aplicativos ▸ Aplicativos instalados`.  
   - Games, trialware, pacotes de idiomas extras etc.

---

### 2 – *System Tweaks* (ganho de 3 – 8 GB)

| Ação | Comando | Espaço recuperado |
|------|---------|-------------------|
| **Desativar Hibernação** (se não usa “Suspender/Hybrid Sleep” nem “Inicialização Rápida”) | `powercfg /hibernate off` | + ≈  3 GB |
| **Reduzir ou mover Pagefile**<br> – Defina tamanho fixo 1024 - 2048 MB **ou** mova para D:\ | `Sysdm.cpl ▸ Avançado ▸ Desempenho ▸ Avançado ▸ Memória Virtual` | + ≈  1-3 GB |
| **Limpar componentes obsoletos do WinSxS** | `DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase` (CMD Admin) | + ≈  1-2 GB |
| **Excluir pastas de backup de drivers** | `C:\Windows\System32\DriverStore\FileRepository`; use **DriverStore Explorer** para limpar com segurança | variável |

> ⚠️ Execute comandos como Administrador.

---

### 3 – *Realocação Inteligente* (ganho grande e permanente)

1. **Mover bibliotecas**: clique direito em Documentos/Imagens/Downloads → **Propriedades ▸ Local** → aponte para **D:\Usuários\Felippe\<pasta>**.

2. **Instalações futuras**:  
   *Steam, IDEs, máquinas virtuais* → escolha **D:** como destino.

3. **OneDrive/Google Drive**: ative **Arquivos sob demanda** ou mude a pasta de sync para D:.

4. **Cache de Navegadores**: no Chrome/Edge, use flags ou simbólicos (`mklink /D`) para apontar cache a D:.

---

### 4 – *Ajustes Avançados* (opcional)

| Ajuste | Ganho | Risco |
|--------|-------|-------|
| **Desabilitar Armazenamento Reservado** | + ≈  7 GB | Pode faltar espaço em futuras atualizações; reserve ≥ 10 GB livres antes dos grandes updates. |
| **Compactação NTFS (CompactOS)** | `compact /compactos:always` | + 4-6 GB | Pequena perda de performance em CPU i3-10100F é imperceptível; evite se precisar de 100 % de I/O máximo. |
| **Mover pastas de Programas via junções** (`mklink /J`) | variável | Exige cuidado para não quebrar atualizações. |

---

## Manutenção contínua

- **Sensor de armazenamento** → marque para rodar “Diariamente”.
- **Atualizei o Windows?** Rode novamente `cleanmgr` e `DISM`.
- **Logs de Windows Defender**: `C:\ProgramData\Microsoft\Windows Defender\Scans\History` — apague periodicamente.
- **Baixa RAM?** Prefira **Suspender** em vez de **Hibernate**; mantém o hiberfil.sys apagado.

---

### Sequência mínima recomendada agora

```text
1. powercfg /hibernate off
2. cleanmgr /sageset:1  → selecione tudo
3. cleanmgr /sagerun:1
4. DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase
5. Mova pagefile para D: e fixe em 2048 MB
6. Ative Storage Sense diário
```

Isso costuma liberar **≈ 10–15 GB imediatos** no seu C:.

---

💡 **Dica extra de “adivinhação simbiótica por proximidade”**  
Se encontrar um arquivo único enorme consumindo espaço (p. ex. gravações do OBS, pasta `Downloads` esquecida), mova-o para o HD e crie um **atalho** no lugar; assim programas que esperam aquele caminho continuam funcionando.

Qualquer etapa que queira aprofundar (ex.: script `.bat` para automatizar limpezas mensais ou mover caches via symlinks), é só chamar que desenhamos junto do TEIA-core.

---

