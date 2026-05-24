# 2082 - Otimização de prompt TEIA

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'file-service://file-KBEBat2tmXmG2zeMaMtka4', 'size_bytes': 360931, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Make sure to include `【message_idx†source】` markers to provide citations based on this file, where [message_idx] is provided at the beginning of this message

---

### ASSISTENTE

All the files uploaded by the user have been fully loaded. Searching won't provide additional information.

---

### ASSISTENTE

Prompt Otimizado:

---

Quero transformar o **Dashboard TEIA** em uma interface procedural interativa, que vá além de exibir métricas estáticas e se torne um ambiente de compressão/descompressão vivo, com blocos funcionais e feedback visual.

### Funcionalidades principais

**1. Blocos de compressão/descompressão**
- **Comprimir**: botão *Inserir arquivo* abre o seletor; após seleção, animação de seta simboliza a transformação do arquivo em *seed procedural*. Ao final, aparece o botão para *baixar/copiar seed* e métricas detalhadas (tamanho original, bytes seed, tempo, razão core+seed/orig).
- **Descomprimir**: recebe arquivo `.seed.json`; seta animada no sentido inverso mostra o processo; entrega o arquivo restaurado e exibe métricas (tempo de restauração, throughput, pico de memória, ratios).

**2. Layout em grid**
- **Linha 1**: Resumo (original, seed, núcleo, economia), Prova única (PO), Catálogo de seeds, Status Dry-Run.
- **Linha 2**: Métricas visuais (donut core+seed/orig, velocímetros para tempo/throughput, barras horizontais para I/O), catálogo de seeds (topo + meta), benchmarks (gráfico de throughput e IOPS).
- **Linha 3**: JSON cru colapsável, logs/sistema (CPU, RAM, SO), parâmetros/versões do núcleo procedural.

**3. Métricas completas**
- Tempo de compressão e restauração (total e por MB).  
- Pico de memória (total e por MB).  
- Throughput e IOPS (sequencial e randômico).  
- Razões seed/original, core/original e total/original.  
- Entropia antes/depois (quando disponível).  
- Dados do sistema (CPU, núcleos, RAM, disco, SO) e versionamento TEIA.  

**4. Interatividade**
- JavaScript lê arquivos locais (FileReader) e mostra progresso na seta animada (% dentro da seta).  
- Chamadas a scripts locais TEIA (PowerShell/WSL) ou API remota para processar.  
- Atualização dinâmica do dashboard com cada execução.  

**5. Exportação e auditoria**
- Botões para *Exportar JSON, CSV, PDF*.  
- Relatórios completos contendo métricas, benchmarks e logs.  
- Modo *comparar runs* lado a lado.  

**6. Visual e design**
- Paleta TEIA (azul/verde), fontes consistentes, margens equilibradas.  
- Cada bloco espaçado, sem sobreposição de texto.  
- Gráficos atraentes (donuts, gauges, barras).  
- Dashboard multilíngue (PT/EN).  

**7. Integração com taxonomia**【9†source】
- Validar entradas: nome, extensão, tipo de mídia, codecs, resolução, entropia, metadata.  
- Validar método: tipo de compressão, base algorítmica, requisitos de restauração.  
- Validar execução: benchmarks, logs, validação byte-a-byte.  
- Comparabilidade: testes contra gzip, ffmpeg, zstd.  
- Reprodutibilidade: hashes, links, reuso.  

---

Este dashboard deve se tornar uma **interface procedural viva**, onde cada operação gera métricas auditáveis e visualmente representadas, consolidando a inovação da TEIA como ambiente físico-intuitivo de uso cotidiano.

---

