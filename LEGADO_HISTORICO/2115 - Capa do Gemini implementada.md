# 2115 - Capa do Gemini implementada

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000c81c61f780b70b9cae3945c6', 'size_bytes': 367848, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Successfully created text document 'Deploy-teia-seed-dashboard' which will be referenced in all future messages with the unique identifier textdoc_id: '68d7d3c76a308191b74ae01163bdc931'

Important: This identifier is for tool calls only to reference or update this document. It is not an external ID and it is not possible to link the user to the textdoc.

---

### ASSISTENTE

Successfully created text document 'Codex Prompt Teia Cover Dashboard' which will be referenced in all future messages with the unique identifier textdoc_id: '68d7d40c4b0c8191a9993b5ea487dc57'

Important: This identifier is for tool calls only to reference or update this document. It is not an external ID and it is not possible to link the user to the textdoc.

---

### ASSISTENTE

Pronto: capa implantável e prompt do Codex prontos no canvas.

## Use agora
1) Baixe `Deploy-TEIA-Seed-Dashboard.ps1` (no canvas) e execute no PowerShell 7:
- Cria `./gemini_out, ./seeds, ./logs, ./restored`.
- Grava `index.html` com a capa do Gemini, marca ReadOnly e abre no navegador.
- Sobe `Watch-GeminiFolder.ps1`/`Watch-Downloads.ps1` se existirem.

2) Opcional Codex CLI: pegue `codex_prompt_teia_cover_dashboard.txt` (no canvas) e cole no seu Codex CLI. Ele executa os mesmos passos de forma autônoma e idempotente.

## Operação
- Para gerar: arraste arquivo no painel “Gerar Semente” → clique “Baixar Semente (.teia.json)” → mova para `./gemini_out/`.
- Para restaurar: arraste a seed no painel “Inspecionar Semente” para validar → mova para `./gemini_out/`.
- Acompanhe em `./logs/gemini_adapter.log`.

Observação: a capa usa Tailwind via CDN. Se quiser 100% offline, remova a `<script src="https://cdn.tailwindcss.com">` e mantenha o CSS embutido.

---

### USUÁRIO

Como prosseguimos, após esse retorno do codex cli referente a tarefa acima que deleguei a ele:
"
> I’m going to add a robust PowerShell deploy script and a validated index.html, fixing the malformed HTML/JS
  you pasted. I’ll create folders, enforce single-instance watchers, open the dashboard, tail the log, and write
  COVER_READY.

• Updated Plan
  └ □ Add Deploy-TEIA-Seed-Dashboard.ps1 script
    □ Write validated index.html UI
    □ Start watchers single-instance
    □ Open dashboard and tail log
    □ Finalize and confirm COVER_READY

• Explored
  └ List ls -la

• Ran pwsh -lc 'Get-ChildItem -Force | Format-List -Property Name,Length,Mode,LastWriteTime'
  └ The argument '-lc' is not recognized as the name of a script file. Check the spelling of the name, or if a path
  └ was included, verify that the path is correct and try again.

• Ran
  └ pwd && ls -la || echo Fallback && powershell -NoProfile -Command "Get-ChildItem -Force | Select-Object
        Name,Length,Mode,LastWriteTime | Format-Table -AutoSize"

> Next, I’ll add Deploy-TEIA-Seed-Dashboard.ps1 to the repo with a validated HTML dashboard, single-instance watcher
  start, log tail job, and COVER_READY logging.

• Proposed Change C:\Windows\System32\Deploy-TEIA-Seed-Dashboard.ps1 (+290 -0)
    1     +$ErrorActionPreference = 'Stop'
    2     +
    3     +# Idempotent working root
    4     +$root = (Get-Location).Path
    5     +
    6     +function Write-CoverLog {
    7     +    param([string]$Message)
    8     +    try {
    9     +        $logDir = Join-Path $root 'logs'
    10    +        if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    11    +        $logPath = Join-Path $logDir 'codex_cover.log'
    12    +        $stamp = (Get-Date).ToString('s')
    13    +        Add-Content -LiteralPath $logPath -Value "[$stamp] $Message"
    14    +    } catch {}
    15    +}
    16    +
    17    +function Ensure-Dir {
    18    +    param([Parameter(Mandatory)][string]$Path)
    19    +    if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
    20    +}
    21    +
    22    +# Required folders
    23    +Ensure-Dir (Join-Path $root 'gemini_out')
    24    +Ensure-Dir (Join-Path $root 'seeds')
    25    +Ensure-Dir (Join-Path $root 'logs')
    26    +Ensure-Dir (Join-Path $root 'restored')
    27    +
    28    +# Build validated index.html content
    29    +$index = @'
    30    +<!DOCTYPE html>
    31    +<html lang="pt-BR">
    32    +<head>
    33    +  <meta charset="utf-8" />
    34    +  <meta name="viewport" content="width=device-width,initial-scale=1" />
    35    +  <title>TEIA Seed Dashboard Local</title>
    36    +  <script src="https://cdn.tailwindcss.com"></script>
    37    +  <style>
    38    +    :root{--bg:#0b0f14;--panel-bg:#111827;--border:#374151;--text:#e6edf3;--muted:#9ca3af;--accent:#10b981
           ;--accent-hover:#059669;--drop:#4b5563}
    39    +    body{background:var(--bg);color:var(--text);font-family:system-ui,-apple-system,BlinkMacSystemFont,'Se
           goe UI',Roboto,'Helvetica Neue',Arial,'Noto Sans',sans-serif}
    40    +    .panel{background:var(--panel-bg);border:1px solid var(--border);border-radius:.75rem;padding:1.5rem;b
           ox-shadow:0 4px 6px -1px rgba(0,0,0,.1),0 2px 4px -2px rgba(0,0,0,.1)}
    41    +    .dropzone{border:2px dashed var(--drop);transition:background-color .2s ease-in-out}
    42    +    .dropzone.dragover{background-color:rgba(16,185,129,.08);border-color:var(--accent)}
    43    +    .btn{background:var(--accent);color:#fff;transition:background-color .2s}
    44    +    .btn:hover{background:var(--accent-hover)}
    45    +    .btn:disabled{opacity:.5;cursor:not-allowed}
    46    +    .mono{font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,'Liberation Mono','Courier New',mo
           nospace}
    47    +    .link{color:var(--accent);text-decoration:underline;cursor:pointer}
    48    +    .tooltip{position:relative;display:inline-block}
    49    +    .tooltip .tooltiptext{visibility:hidden;width:240px;background:#374151;color:#fff;text-align:center;bo
           rder-radius:6px;padding:6px;position:absolute;z-index:1;bottom:125%;left:50%;margin-left:-120px;opacity:0;
           transition:opacity .2s}
    50    +    .tooltip:hover .tooltiptext{visibility:visible;opacity:1}
    51    +  </style>
    52    +</head>
    53    +<body class="p-4 md:p-8">
    54    +  <div class="max-w-7xl mx-auto space-y-8">
    55    +    <header class="flex flex-col md:flex-row justify-between items-start md:items-center">
    56    +      <div>
    57    +        <h1 class="text-3xl font-bold text-white">TEIA Seed Dashboard Local</h1>
    58    +        <p class="text-gray-400">Interface para geração e inspeção de sementes procedurais.</p>
    59    +      </div>
    60    +      <div class="flex items-center space-x-4 mt-4 md:mt-0 text-sm">
    61    +        <div class="tooltip">
    62    +          <span class="link" onclick="showHelp()">Ajuda Rápida</span>
    63    +          <span class="tooltiptext">O watcher local (Watch-GeminiFolder.ps1) processa .teia.json salvos em
            "gemini_out".</span>
    64    +        </div>
    65    +        <a href="logs/gemini_adapter.log" target="_blank" class="link">Ver Log</a>
    66    +        <a href="gemini_out/" class="link">Abrir pasta gemini_out</a>
    67    +      </div>
    68    +    </header>
    69    +
    70    +    <main class="grid grid-cols-1 lg:grid-cols-2 gap-8">
    71    +      <section class="panel space-y-4">
    72    +        <h2 class="text-xl font-semibold border-b border-gray-700 pb-2">1. Gerar Semente</h2>
    73    +        <div id="dropzone-generate" class="dropzone p-8 text-center rounded-lg cursor-pointer">
    74    +          <p class="text-gray-400">Arraste um arquivo aqui ou clique para selecionar</p>
    75    +          <input type="file" id="file-input" class="hidden" />
    76    +        </div>
    77    +        <div id="file-info-generate" class="hidden space-y-2 text-sm">
    78    +          <p><strong>Arquivo:</strong> <span id="gen-file-name" class="mono"></span></p>
    79    +          <p><strong>Tamanho:</strong> <span id="gen-file-size" class="mono"></span></p>
    80    +          <p><strong>Tipo MIME:</strong> <span id="gen-file-mime" class="mono"></span></p>
    81    +          <div class="flex items-center">
    82    +            <p class="mr-2"><strong>SHA-256:</strong></p>
    83    +            <span id="gen-file-sha" class="mono text-gray-400 truncate">Calculando...</span>
    84    +          </div>
    85    +          <p class="text-xs text-gray-500" id="gen-hash-time"></p>
    86    +        </div>
    87    +        <button id="download-seed-btn" class="btn w-full font-bold py-2 px-4 rounded" disabled>Baixar Seme
           nte (.teia.json)</button>
    88    +      </section>
    89    +
    90    +      <section class="panel space-y-4">
    91    +        <h2 class="text-xl font-semibold border-b border-gray-700 pb-2">2. Inspecionar Semente</h2>
    92    +        <div id="dropzone-restore" class="dropzone p-8 text-center rounded-lg cursor-pointer">
    93    +          <p class="text-gray-400">Arraste um arquivo .teia.json aqui para validar</p>
    94    +          <input type="file" id="seed-input-restore" class="hidden" accept=".json,.teia.json" />
    95    +        </div>
    96    +        <div id="seed-info-restore" class="hidden space-y-3 text-sm">
    97    +          <p class="text-green-400 font-bold">Semente Válida. Siga as instruções abaixo.</p>
    98    +          <div class="bg-gray-900 p-3 rounded-md mono text-xs" id="restore-json-preview"></div>
    99    +          <div class="bg-yellow-900/50 border border-yellow-700 text-yellow-300 p-3 rounded-md">
    100   +            <strong>Próximo Passo:</strong> Mova ou salve este .teia.json em "gemini_out". O watcher fará
           a restauração.
    101   +          </div>
    102   +        </div>
    103   +        <div id="seed-error-restore" class="hidden text-sm text-red-400 bg-red-900/50 border border-red-70
           0 p-3 rounded-md">
    104   +          <p><strong>Semente Inválida.</strong> <span id="restore-error-message"></span></p>
    105   +        </div>
    106   +      </section>
    107   +    </main>
    108   +  </div>
    109   +
    110   +  <script>
    111   +  document.addEventListener('DOMContentLoaded', () => {
    112   +    const humanFileSize = (bytes, si = false, dp = 1) => {
    113   +      const thresh = si ? 1000 : 1024;
    114   +      if (Math.abs(bytes) < thresh) return bytes + ' B';
    115   +      const units = si ? ['kB','MB','GB','TB','PB','EB','ZB','YB'] : ['KiB','MiB','GiB','TiB','PiB','EiB',
           'ZiB','YiB'];
    116   +      let u = -1; const r = 10 ** dp;
    117   +      do { bytes /= thresh; ++u; } while (Math.round(Math.abs(bytes) * r) / r >= thresh && u < units.lengt
           h - 1);
    118   +      return bytes.toFixed(dp) + ' ' + units[u];
    119   +    };
    120   +
    121   +    const calculateSHA256 = async (file) => {
    122   +      const buffer = await file.arrayBuffer();
    123   +      const hashBuffer = await crypto.subtle.digest('SHA-256', buffer);
    124   +      const hashArray = Array.from(new Uint8Array(hashBuffer));
    125   +      return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    126   +    };
    127   +
    128   +    const setupDropzone = (dropzone, input) => {
    129   +      dropzone.addEventListener('click', () => input.click());
    130   +      dropzone.addEventListener('dragover', (e) => { e.preventDefault(); dropzone.classList.add('dragover'
           ); });
    131   +      dropzone.addEventListener('dragleave', () => dropzone.classList.remove('dragover'));
    132   +      dropzone.addEventListener('drop', (e) => {
    133   +        e.preventDefault(); dropzone.classList.remove('dragover');
    134   +        if (e.dataTransfer.files && e.dataTransfer.files.length) {
    135   +          input.files = e.dataTransfer.files; input.dispatchEvent(new Event('change', { bubbles: true }));
    136   +        }
    137   +      });
    138   +    };
    139   +
    140   +    // Generate
    141   +    const dropzoneGenerate = document.getElementById('dropzone-generate');
    142   +    const fileInput = document.getElementById('file-input');
    143   +    const fileInfoGenerate = document.getElementById('file-info-generate');
    144   +    const genFileName = document.getElementById('gen-file-name');
    145   +    const genFileSize = document.getElementById('gen-file-size');
    146   +    const genFileMime = document.getElementById('gen-file-mime');
    147   +    const genFileSha = document.getElementById('gen-file-sha');
    148   +    const genHashTime = document.getElementById('gen-hash-time');
    149   +    const downloadBtn = document.getElementById('download-seed-btn');
    150   +    let generatedSeedData = null;
    151   +    setupDropzone(dropzoneGenerate, fileInput);
    152   +
    153   +    fileInput.addEventListener('change', async (e) => {
    154   +      const file = e.target.files?.[0]; if (!file) return;
    155   +      fileInfoGenerate.classList.remove('hidden'); downloadBtn.disabled = true;
    156   +      genFileName.textContent = file.name;
    157   +      genFileSize.textContent = `${humanFileSize(file.size)} (${file.size.toLocaleString()} bytes)`;
    158   +      genFileMime.textContent = file.type || 'application/octet-stream';
    159   +      genFileSha.textContent = 'Calculando...'; genHashTime.textContent = '';
    160   +      const startTime = performance.now();
    161   +      const sha256 = await calculateSHA256(file);
    162   +      const endTime = performance.now();
    163   +      genFileSha.textContent = sha256; genFileSha.classList.remove('truncate');
    164   +      genHashTime.textContent = `Cálculo do hash levou ${(endTime - startTime).toFixed(2)} ms.`;
    165   +      generatedSeedData = { target: file.name, sha256: sha256, mime: file.type || 'application/octet-strea
           m', size: file.size, created: new Date().toISOString(), version: 'teia.public.v1' };
    166   +      downloadBtn.disabled = false;
    167   +    });
    168   +
    169   +    downloadBtn.addEventListener('click', () => {
    170   +      if (!generatedSeedData) return;
    171   +      const blob = new Blob([JSON.stringify(generatedSeedData, null, 2)], { type: 'application/json' });
    172   +      const url = URL.createObjectURL(blob);
    173   +      const a = document.createElement('a');
    174   +      const shaPart = generatedSeedData.sha256.substring(0, 12);
    175   +      a.href = url; a.download = `${generatedSeedData.target}.${shaPart}.teia.json`;
    176   +      document.body.appendChild(a); a.click(); document.body.removeChild(a);
    177   +      URL.revokeObjectURL(url);
    178   +    });
    179   +
    180   +    // Inspect
    181   +    const dropzoneRestore = document.getElementById('dropzone-restore');
    182   +    const seedInputRestore = document.getElementById('seed-input-restore');
    183   +    const seedInfoRestore = document.getElementById('seed-info-restore');
    184   +    const seedErrorRestore = document.getElementById('seed-error-restore');
    185   +    const restoreJsonPreview = document.getElementById('restore-json-preview');
    186   +    const restoreErrorMessage = document.getElementById('restore-error-message');
    187   +    setupDropzone(dropzoneRestore, seedInputRestore);
    188   +
    189   +    seedInputRestore.addEventListener('change', async (e) => {
    190   +      const file = e.target.files?.[0]; if (!file) return;
    191   +      seedInfoRestore.classList.add('hidden'); seedErrorRestore.classList.add('hidden');
    192   +      try {
    193   +        const text = await file.text();
    194   +        const data = JSON.parse(text);
    195   +        const required = ['target','sha256','mime','size','created','version'];
    196   +        const missing = required.filter(k => !(k in data));
    197   +        if (missing.length) throw new Error('Campos obrigatórios ausentes: ' + missing.join(', '));
    198   +        if (typeof data.size !== 'number') throw new Error('O campo "size" deve ser um número.');
    199   +        restoreJsonPreview.textContent = JSON.stringify(data, null, 2);
    200   +        seedInfoRestore.classList.remove('hidden');
    201   +      } catch (err) {
    202   +        restoreErrorMessage.textContent = err?.message || String(err);
    203   +        seedErrorRestore.classList.remove('hidden');
    204   +      }
    205   +    });
    206   +
    207   +    window.showHelp = () => {
    208   +      alert('Este dashboard gera e inspeciona "sementes" (.teia.json).\n\nPara restaurar um arquivo:\n1) G
           ere e baixe a semente.\n2) Salve ou mova o .teia.json para a pasta "gemini_out".\n3) O Watch-GeminiFolder.
           ps1 irá processar automaticamente.\n4) Acompanhe o progresso em logs/gemini_adapter.log.');
    209   +    };
    210   +  });
    211   +  </script>
    212   +</body>
    213   +</html>
    214   +'@
    215   +
    216   +# Write index.html atomically and mark as ReadOnly
    217   +$indexPath = Join-Path $root 'index.html'
    218   +try {
    219   +    Set-Content -Path $indexPath -Value $index -Encoding UTF8 -Force
    220   +} catch {
    221   +    Write-CoverLog "ERROR writing index.html: $($_.Exception.Message)"
    222   +    Start-Sleep -Milliseconds 200
    223   +    Set-Content -Path $indexPath -Value $index -Encoding UTF8 -Force
    224   +}
    225   +try {
    226   +    $fi = Get-Item -LiteralPath $indexPath
    227   +    $fi.Attributes = $fi.Attributes -bor [IO.FileAttributes]::ReadOnly
    228   +} catch {
    229   +    Write-CoverLog "WARN cannot set ReadOnly on index.html: $($_.Exception.Message)"
    230   +}
    231   +
    232   +# Helper: start watchers if present, ensure single instance by CommandLine scan
    233   +function Start-WatcherIfPresent {
    234   +    param([Parameter(Mandatory)][string]$FileName)
    235   +    $full = Join-Path $root $FileName
    236   +    if (-not (Test-Path $full)) { return }
    237   +    $resolved = (Resolve-Path $full).Path
    238   +    $escaped = [Regex]::Escape($resolved)
    239   +    $running = Get-CimInstance Win32_Process -Filter "Name='pwsh.exe' OR Name='powershell.exe'" |
    240   +      Where-Object { $_.CommandLine -match $escaped }
    242   +        try {
    243   +            $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue)?.Source
    244   +            if (-not $pwsh) { $pwsh = (Get-Command powershell).Source }
    245   +            Start-Process -FilePath $pwsh -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File'
           , $resolved) -WindowStyle Minimized | Out-Null
    246   +        } catch {
    247   +            Write-CoverLog "ERROR starting watcher $FileName: $($_.Exception.Message)"
    248   +        }
    249   +    }
    250   +}
    251   +
    252   +Start-WatcherIfPresent -FileName 'Watch-GeminiFolder.ps1'
    253   +Start-WatcherIfPresent -FileName 'Watch-Downloads.ps1'
    254   +
    255   +# Open dashboard silently
    256   +try { Start-Process -FilePath $indexPath | Out-Null } catch { Write-CoverLog "WARN opening index.html: $($
           _.Exception.Message)" }
    257   +
    258   +# Tail adapter log in background job (non-blocking, idempotent)
    259   +$adapterLog = Join-Path $root 'logs/gemini_adapter.log'
    260   +if (Test-Path $adapterLog) {
    261   +    $existing = Get-Job -Name 'tail-gemini-adapter' -ErrorAction SilentlyContinue
    262   +    if (-not $existing) {
    263   +        Start-Job -Name 'tail-gemini-adapter' -ScriptBlock { param($p) Get-Content -Path $p -Wait } -Argum
           entList $adapterLog | Out-Null
    264   +    }
    265   +}
    266   +
    267   +# Background supervisor to keep watchers alive (very light loop)
    268   +$supervisor = Get-Job -Name 'cover-supervisor' -ErrorAction SilentlyContinue
    269   +if (-not $supervisor) {
    270   +    Start-Job -Name 'cover-supervisor' -ScriptBlock {
    271   +        param($root)
    272   +        function Ensure-Watcher { param([string]$name)
    273   +            $path = Join-Path $root $name
    274   +            if (-not (Test-Path $path)) { return }
    275   +            $res = (Resolve-Path $path).Path
    276   +            $esc = [Regex]::Escape($res)
    277   +            $running = Get-CimInstance Win32_Process -Filter "Name='pwsh.exe' OR Name='powershell.exe'" |
           Where-Object { $_.CommandLine -match $esc }
    278   +            if (-not $running) {
    279   +                try {
    280   +                    $pw = (Get-Command pwsh -ErrorAction SilentlyContinue)?.Source; if (-not $pw) { $pw =
           (Get-Command powershell).Source }
    281   +                    Start-Process -FilePath $pw -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','
           -File', $res) -WindowStyle Minimized | Out-Null
    282   +                } catch {}
    283   +            }
    284   +        }
    285   +        while ($true) { Ensure-Watcher 'Watch-GeminiFolder.ps1'; Ensure-Watcher 'Watch-Downloads.ps1'; Sta
           rt-Sleep -Seconds 20 }
    286   +    } -ArgumentList $root | Out-Null
    287   +}
    288   +
    289   +Write-CoverLog 'COVER_READY'
    290   +

• Change Approved C:\Windows\System32\Deploy-TEIA-Seed-Dashboard.ps1 (+290 -0)

• Updated Plan
  └ Added the deploy script with validated HTML content, watcher management, log tail job, and COVER_READY logging.
    ✔ Add Deploy-TEIA-Seed-Dashboard.ps1 script
    □ Write validated index.html UI
    □ Start watchers single-instance
    □ Open dashboard and tail log
    □ Finalize and confirm COVER_READY

> Adicionei um deploy script corrigido e validado. Ele grava um index.html limpo, inicia watchers em instância única,
  abre o dashboard e registra COVER_READY.

  Arquivo

  - Deploy-TEIA-Seed-Dashboard.ps1: script idempotente que materializa o dashboard e integra com os watchers.

  O que faz

  - Pastas: cria .\gemini_out, .\seeds, .\logs, .\restored.
  - Dashboard: grava index.html válido (UTF-8), marca como ReadOnly e abre no navegador.
  - Watchers: inicia Watch-GeminiFolder.ps1 e Watch-Downloads.ps1 se existirem (uma única instância via CommandLine
  scan).
  - Log tail: inicia job tail-gemini-adapter para .\logs\gemini_adapter.log se existir.
  - Supervisor: job leve cover-supervisor que verifica watchers a cada 20s.
  - Sinalização: escreve COVER_READY em .\logs\codex_cover.log.

  HTML/JS corrigidos

  - Validação: <!DOCTYPE html>, tags e atributos fechados, links relativos logs/gemini_adapter.log e gemini_out/.
  - MIME/JSON: usa application/octet-stream e application/json.
  - Hash e UI: funções JS corrigidas, dropzones funcionais, preview e validações robustas.
  - Tailwind: CDN https://cdn.tailwindcss.com (se quiser 100% offline, posso embutir CSS).

  Como usar

  - PowerShell 7+: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Deploy-TEIA-Seed-Dashboard.ps1

  Quer que eu também gere um compressor_gemini.html separado, seguindo o mesmo tema, para ficar como rota opcional?"

---

### ASSISTENTE

Problemas detectados:
- Escreveu em `C:\Windows\System32` (proibido).
- Tentou `pwsh -lc` (flag de Linux). Use `-NoProfile -ExecutionPolicy Bypass -File`.

Proceda assim (cola tudo no PowerShell 7):

```powershell
# === Fix + Deploy TEIA Cover (idempotente) ===
$Root = 'D:\Teia\TEIA_NUCLEO\offline\nano'  # ajuste se necessário
$ErrorActionPreference = 'Stop'
$null = New-Item -ItemType Directory -Path $Root -Force

# 1) Criar pastas base
$dirs = 'gemini_out','seeds','logs','restored' | ForEach-Object { Join-Path $Root $_ }
$dirs | ForEach-Object { if(-not (Test-Path $_)){ New-Item -ItemType Directory -Path $_ | Out-Null } }

# 2) Escrever Deploy-TEIA-Seed-Dashboard.ps1 válido no $Root (não depende de System32)
$deployPath = Join-Path $Root 'Deploy-TEIA-Seed-Dashboard.ps1'
$deploy = @'
$ErrorActionPreference = "Stop"
param([string]$RootPath = (Get-Location).Path)
function New-Dir($p){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Path $p | Out-Null } }
$root = Resolve-Path $RootPath
Set-Location $root
'@ + @"
`$dirs = 'gemini_out','seeds','logs','restored'
`$dirs | ForEach-Object { New-Dir (Join-Path `$root `$_) }
"@ + @'
# --- index.html (capa) ---
$indexPath = Join-Path $root 'index.html'
$index = @"
<!DOCTYPE html>
<html lang="pt-br">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>TEIA Seed Dashboard Local</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    :root{--bg:#0b0f14;--panel-bg:#111827;--border:#374151;--text:#e6edf3;--accent:#10b981;--accent-hover:#059669;--drop:#4b5563}
    body{background:#0b0f14;color:#e6edf3;font-family:system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,'Noto Sans',sans-serif}
    .panel{background:#111827;border:1px solid #374151;border-radius:.75rem;padding:1.5rem;box-shadow:0 4px 6px -1px rgba(0,0,0,.1),0 2px 4px -2px rgba(0,0,0,.1)}
    .dropzone{border:2px dashed var(--drop);transition:background-color .2s}
    .dropzone.dragover{background-color:rgba(16,185,129,.1);border-color:var(--accent)}
    .btn{background:var(--accent);color:#fff;transition:background-color .2s}.btn:hover{background:var(--accent-hover)}.btn:disabled{opacity:.5;cursor:not-allowed}
    .mono{font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,'Liberation Mono','Courier New',monospace}
    .link{color:var(--accent);text-decoration:underline;cursor:pointer}
    .tooltip{position:relative;display:inline-block}.tooltip .tooltiptext{visibility:hidden;width:220px;background:#374151;color:#fff;text-align:center;border-radius:6px;padding:5px;position:absolute;z-index:1;bottom:125%;left:50%;margin-left:-110px;opacity:0;transition:opacity .3s}.tooltip:hover .tooltiptext{visibility:visible;opacity:1}
  </style>
</head>
<body class="p-4 md:p-8">
  <div class="max-w-7xl mx-auto space-y-8">
    <header class="flex flex-col md:flex-row justify-between items-start md:items-center">
      <div><h1 class="text-3xl font-bold text-white">TEIA Seed Dashboard Local</h1><p class="text-gray-400">Interface para geração e inspeção de sementes procedurais.</p></div>
      <div class="flex items-center space-x-4 mt-4 md:mt-0 text-sm">
        <div class="tooltip"><span class="link" onclick="showHelp()">Ajuda Rápida</span><span class="tooltiptext">O watcher (Watch-GeminiFolder.ps1) processa .teia.json em gemini_out.</span></div>
        <a href="./logs/gemini_adapter.log" target="_blank" class="link">Ver Log</a>
        <a href="./gemini_out" class="link">Abrir pasta gemini_out</a>
      </div>
    </header>
    <main class="grid grid-cols-1 lg:grid-cols-2 gap-8">
      <section class="panel space-y-4">
        <h2 class="text-xl font-semibold border-b border-gray-700 pb-2">1. Gerar Semente</h2>
        <div id="dropzone-generate" class="dropzone p-8 text-center rounded-lg cursor-pointer">
          <p class="text-gray-400">Arraste um arquivo aqui ou clique para selecionar</p>
          <input type="file" id="file-input" class="hidden">
        </div>
        <div id="file-info-generate" class="hidden space-y-2 text-sm">
          <p><strong>Arquivo:</strong> <span id="gen-file-name" class="mono"></span></p>
          <p><strong>Tamanho:</strong> <span id="gen-file-size" class="mono"></span></p>
          <p><strong>Tipo MIME:</strong> <span id="gen-file-mime" class="mono"></span></p>
          <div class="flex items-center"><p class="mr-2"><strong>SHA-256:</strong></p><span id="gen-file-sha" class="mono text-gray-400 truncate">Calculando...</span></div>
          <p class="text-xs text-gray-500" id="gen-hash-time"></p>
        </div>
        <button id="download-seed-btn" class="btn w-full font-bold py-2 px-4 rounded" disabled>Baixar Semente (.teia.json)</button>
      </section>
      <section class="panel space-y-4">
        <h2 class="text-xl font-semibold border-b border-gray-700 pb-2">2. Inspecionar Semente</h2>
        <div id="dropzone-restore" class="dropzone p-8 text-center rounded-lg cursor-pointer">
          <p class="text-gray-400">Arraste um arquivo `.teia.json` aqui para validar</p>
          <input type="file" id="seed-input-restore" class="hidden" accept=".json,.teia.json">
        </div>
        <div id="seed-info-restore" class="hidden space-y-3 text-sm">
          <p class="text-green-400 font-bold">Semente Válida. Siga as instruções abaixo.</p>
          <div class="bg-gray-900 p-3 rounded-md mono text-xs" id="restore-json-preview"></div>
          <div class="bg-yellow-900/50 border border-yellow-700 text-yellow-300 p-3 rounded-md"><strong>Próximo Passo:</strong> Mova o `.teia.json` para <strong>./gemini_out/</strong>. O watcher fará a restauração.</div>
        </div>
        <div id="seed-error-restore" class="hidden text-sm text-red-400 bg-red-900/50 border border-red-700 p-3 rounded-md"><p><strong>Semente Inválida.</strong> <span id="restore-error-message"></span></p></div>
      </section>
    </main>
  </div>
  <script>
  document.addEventListener('DOMContentLoaded',()=>{
    const human=(b,s=false,d=1)=>{const t=s?1e3:1024;if(Math.abs(b)<t)return b+' B';const u=s?['kB','MB','GB','TB','PB','EB','ZB','YB']:['KiB','MiB','GiB','TiB','PiB','EiB','ZiB','YiB'];let i=-1;const r=10**d;do{b/=t;++i;}while(Math.round(Math.abs(b)*r)/r>=t&&i<u.length-1);return b.toFixed(d)+' '+u[i]};
    const sha=async f=>{const buf=await f.arrayBuffer();const hb=await crypto.subtle.digest('SHA-256',buf);return Array.from(new Uint8Array(hb)).map(b=>b.toString(16).padStart(2,'0')).join('')};
    const dz=(z,i)=>{z.addEventListener('click',()=>i.click());z.addEventListener('dragover',e=>{e.preventDefault();z.classList.add('dragover')});z.addEventListener('dragleave',()=>z.classList.remove('dragover'));z.addEventListener('drop',e=>{e.preventDefault();z.classList.remove('dragover');if(e.dataTransfer.files?.length){i.files=e.dataTransfer.files;i.dispatchEvent(new Event('change',{bubbles:true}))}})};
    const dzg=document.getElementById('dropzone-generate'), fi=document.getElementById('file-input'), info=document.getElementById('file-info-generate'), n=document.getElementById('gen-file-name'), sz=document.getElementById('gen-file-size'), mm=document.getElementById('gen-file-mime'), sh=document.getElementById('gen-file-sha'), tm=document.getElementById('gen-hash-time'), btn=document.getElementById('download-seed-btn');
    let seed=null; dz(dzg,fi);
    fi.addEventListener('change',async e=>{const f=e.target.files?.[0]; if(!f) return; info.classList.remove('hidden'); btn.disabled=true; n.textContent=f.name; sz.textContent=`${human(f.size)} (${f.size.toLocaleString()} bytes)`; mm.textContent=f.type||'application/octet-stream'; sh.textContent='Calculando...'; tm.textContent=''; const t0=performance.now(); const s=await sha(f); const t1=performance.now(); sh.textContent=s; sh.classList.remove('truncate'); tm.textContent=`Cálculo do hash levou ${(t1-t0).toFixed(2)} ms.`; seed={target:f.name,sha256:s,mime:f.type||'application/octet-stream',size:f.size,created:new Date().toISOString(),version:'teia.public.v1'}; btn.disabled=false;});
    btn.addEventListener('click',()=>{ if(!seed) return; const blob=new Blob([JSON.stringify(seed,null,2)],{type:'application/json'}); const url=URL.createObjectURL(blob); const a=document.createElement('a'); const p=seed.sha256.substring(0,12); a.href=url; a.download=`${seed.target}.${p}.teia.json`; document.body.appendChild(a); a.click(); document.body.removeChild(a); URL.revokeObjectURL(url)});
    const dzr=document.getElementById('dropzone-restore'), si=document.getElementById('seed-input-restore'), ok=document.getElementById('seed-info-restore'), err=document.getElementById('seed-error-restore'), pre=document.getElementById('restore-json-preview'), em=document.getElementById('restore-error-message'); dz(dzr,si);
    si.addEventListener('change',async e=>{const f=e.target.files?.[0]; if(!f) return; ok.classList.add('hidden'); err.classList.add('hidden'); try{ const txt=await f.text(); const d=JSON.parse(txt); const req=['target','sha256','mime','size','created','version']; const miss=req.filter(k=>!(k in d)); if(miss.length) throw new Error('Campos obrigatórios ausentes: '+miss.join(', ')); if(typeof d.size!=='number') throw new Error('O campo \"size\" deve ser um número.'); pre.textContent=JSON.stringify(d,null,2); ok.classList.remove('hidden'); }catch(e2){ em.textContent=e2.message||String(e2); err.classList.remove('hidden'); }});
    window.showHelp=()=>alert('Gere/inspecione sementes (.teia.json). Para restaurar: mova o arquivo para ./gemini_out. O Watch-GeminiFolder.ps1 fará o resto. Log: ./logs/gemini_adapter.log.');
  });
  </script>
</body>
</html>
"@
Set-Content -Path $indexPath -Value $index -Encoding UTF8 -Force
try { (Get-Item $indexPath).Attributes = (Get-Item $indexPath).Attributes -bor [IO.FileAttributes]::ReadOnly } catch {}

# 3) Salvar o deploy no disco
Set-Content -Path $deployPath -Value $deploy -Encoding UTF8 -Force
Unblock-File -Path $deployPath -ErrorAction SilentlyContinue

# 4) Executar o deploy
& pwsh -NoProfile -ExecutionPolicy Bypass -File $deployPath -RootPath $Root

# 5) Verificações rápidas
Write-Host "`nVerificação:" -ForegroundColor Cyan
Get-Item (Join-Path $Root 'index.html') | Select-Object Name,Length,LastWriteTime
if(Test-Path (Join-Path $Root 'logs\codex_cover.log')){ Get-Content (Join-Path $Root 'logs\codex_cover.log') -Tail 5 }
```

Checks:
- Abra o dashboard: `Start-Process (Join-Path $Root 'index.html')`
- Watchers ativos: `Get-CimInstance Win32_Process | Where-Object CommandLine -match 'Watch-Gemini' | Select Name,CommandLine`
- Log: `Get-Content (Join-Path $Root 'logs\gemini_adapter.log') -Tail 50`

Prompt curto para o Codex CLI (corretivo):
```
Trabalhe SOMENTE em $Env:TEIA_ROOT (padrão D:\Teia\TEIA_NUCLEO\offline\nano). Nunca escreva em C:\Windows\System32.
Se existir Deploy-TEIA-Seed-Dashboard.ps1 em System32, ignore-o. Gere/atualize o script no $Env:TEIA_ROOT e execute:
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Deploy-TEIA-Seed-Dashboard.ps1
Confirme COVER_READY em .\logs\codex_cover.log e mantenha watchers single-instance rodando.
```

---

### USUÁRIO

retornou em branco no pws, há erro de síntaxe

---

