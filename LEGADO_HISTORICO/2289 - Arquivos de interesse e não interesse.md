# 2289 - Arquivos de interesse e não interesse

### USUÁRIO

A fim de serendipidade e síntese.
Forneça uma lista dos arquivos nos interessam e dos que não nos interessam;

---

### ASSISTENTE

Vou interpretar “arquivos” aqui como tipos/categorias, não como nomes concretos do seu disco.

### 1. Arquivos que nos interessam (para serendipidade + síntese)

Em geral: tudo que é difícil de recuperar, carrega decisão sua, processo, afeto ou estrutura TEIA.

1. Núcleo TEIA / computação simbiótica
   - Scripts TEIA (PowerShell, Python, etc.) estáveis e autorais.  
   - Manifests, índices e seeds:
     - `fractal_index.json`, `manifest_*.json`, `*.teia`, seeds, SIDs.
   - Prompts e contratos:
     - `prompt_*.txt`, `teia_codex_prompt.txt`, `agent.md`, contratos v0.x, docs de arquitetura.
   - Logs “epistêmicos”:
     - `dna_*.log`, `*_benchmark*.json`, `verification_report.json`, `audit_*.jsonl` que registram experimentos, falhas, correções e decisões.

2. Produção intelectual original
   - Textos, notas, cadernos de pesquisa:
     - `.md`, `.txt`, `.docx`, `.pdf` com reflexões, diários, projetos, frameworks, TEIA, etc.
   - Códigos e projetos autorais:
     - Repositórios, scripts, protótipos, dashboards, modelos, ontologias.
   - Mapas, esquemas, resumos e blueprints:
     - Diagramas, mapas mentais, desenhos de arquitetura, timelines.

3. Artefatos pessoais únicos
   - Fotos e vídeos pessoais (família, registros de processo, bastidores).  
   - Áudios de ideias, gravações de voz, sonomarca, experimentos sonoros.  
   - Artes, ilustrações, capas, identidades visuais.

4. Dados de experimentos e benchmarks
   - Resultados de testes, medições, comparações:
     - `.json`, `.csv`, `.xlsx` contendo métricas, relatórios, comparações antes/depois.
   - Dumps cuidadosamente produzidos (ex.: export de um sistema que você não consegue repetir igual depois).

5. Configurações de autoria
   - Presets, perfis, templates que condensam sua forma de trabalhar:
     - Preset de editor, pipeline, automação, templates de projeto, dashboards base.
   - Arquivos de identidade computacional (ex.: `pc_identity_master_dna_*.csv`).

6. Pacotes consolidados
   - Zips “de estado”:
     - `teia-nucleo-procedural_0.1.zip`, `teia_micro_knowledge_*.zip`, backups com SHA256 registrado.
   - Qualquer bundle que represente um “snapshot coerente” do sistema ou de um projeto.

---

### 2. Arquivos que não nos interessam (candidatos fortes a descarte/quarentena)

Em geral: tudo que é regenerável, replicável e não carrega decisão/afeto/processo.

1. Caches e lixo operacional
   - Pastas de cache:
     - `node_modules`, `__pycache__`, `.gradle`, `.m2/repository`, caches de navegador, cache de jogos.
   - Arquivos temporários:
     - `*.tmp`, `~$*.docx`, `*.log` gigantes sem curadoria (logs rotativos de sistema, de app, etc.).
   - Thumbnails, prévias geradas automaticamente.

2. Builds e artefatos recompiláveis
   - Pastas de build:
     - `dist`, `build`, `out`, `bin`, `obj`, `coverage`, `target`.
   - Arquivos compilados:
     - `.class`, `.o`, `.dll` gerados localmente, `.pyd`, pacotes intermediários.

3. Instaladores e imagens de instalação
   - `setup.exe`, `installer.msi`, `.iso`, `.dmg`, `.zip` de programas que você pode baixar de novo.  
   - Drivers antigos, versões antigas de instaladores já superados.

4. Mídia de baixo valor cognitivo
   - Filmes/séries/packs de música baixados que existem em streaming/serviços nuvem.  
   - Packs de imagens genéricas, wallpapers baixados ao acaso, etc., se não integrados a nenhum projeto.

5. Duplicatas brutas
   - Arquivos com nomes como:
     - `" - Cópia"`, `" (1)"`, `" (2)"`, `"backup antigo"`, etc., sem diferença de conteúdo real.  
   - Zips múltiplos do mesmo conteúdo sem metadado (sem SHA, sem doc de contexto).

---

### 3. Zona cinza (decisão caso a caso)

Aqui vale olhar densidade cognitiva e possibilidade de síntese futura:

1. Dumps e exports massivos
   - Export de WhatsApp, Telegram, redes sociais, históricos de e-mail:
     - Podem conter ouro afetivo e narrativo, mas também muito ruído.  
     - Ideal: manter o dump bruto + derivar uma versão sintetizada (curada) quando possível.

2. Bancos de dados e datasets grandes
   - `.sqlite`, `.db`, `.csv` enormes:  
     - Se forem base de experimentos seus, interessam.  
     - Se forem datasets públicos que você pode baixar de novo, interessam menos.

3. Projetos de terceiros baixados
   - Repositórios clonados, templates e exemplos:
     - Se forem base de algo que você construiu em cima, interessam.  
     - Se estão intactos como vieram da internet, são re-baixáveis.

---

### 4. Heurística rápida de decisão

Para qualquer arquivo/pasta, pergunte:

- “Interessa?”  
  - Sim, se:
    - Não posso reconstruir facilmente com download/rebuild.  
    - Carrega minha decisão, meu processo ou meu afeto.  
    - Faz parte do núcleo TEIA ou de uma prova/experimento que quero lembrar.  
    - Tem valor de referência futura (ex.: benchmark, contrato, blueprint).

- “Não interessa?”  
  - Sim, se:
    - É cache, build, instalador, duplicata óbvia ou mídia comoditizada.  
    - Não muda nada se eu perder e só me ocupa espaço.

Se quiser, no próximo passo posso transformar essa lógica em uma pequena “tabela de classificação” (ex.: em CSV) que você usa como base para scripts de varredura no PowerShell.

---

