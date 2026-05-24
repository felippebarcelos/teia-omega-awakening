# Patch-Index30-For-AION.ps1 — Wiring AION-RISPA-NDC no index30.html original
# NÃO altera CSS, animações Canvas nem estrutura HTML.
# Injeta um único bloco <script> antes de </body> com toda a lógica de comunicação.
# Saída: index30.aion.html (cópia patched; original intocado)
param(
    [string]$IndexPath = (Join-Path $PSScriptRoot 'index30.html'),
    [string]$OutPath   = (Join-Path $PSScriptRoot 'index30.aion.html'),
    [int]$AionPort     = 8123
)
$ErrorActionPreference = 'Stop'
if (!(Test-Path $IndexPath)) { throw "index30.html não encontrado: $IndexPath" }

$html = [System.IO.File]::ReadAllText($IndexPath, [System.Text.Encoding]::UTF8)

# Bloco de wiring injetado — não interfere com CSS/Canvas/Chart existente
$wiring = @"
<script>
/* =====================================================================
   AION-RISPA WIRING — injetado por Patch-Index30-For-AION.ps1
   Conecta os botões/dropzones existentes ao backend HTTP :$AionPort
   Não toca em CSS, Canvas nem animações.
   ===================================================================== */
(function () {
  'use strict';
  const AION_BASE = 'http://127.0.0.1:$AionPort';

  /* ── Helpers ───────────────────────────────────────────────────── */
  function log(msg) {
    const el = document.getElementById('logs');
    if (!el) return;
    const line = new Date().toLocaleTimeString('pt-BR') + ' › ' + msg;
    el.textContent = (el.textContent + '\n' + line).split('\n').slice(-40).join('\n');
    el.scrollTop = el.scrollHeight;
  }

  function humanSize(b) {
    if (!b || b === 0) return '0 B';
    const k = 1024, s = ['B','KB','MB','GB','TB'];
    const i = Math.floor(Math.log(b) / Math.log(k));
    return (b / Math.pow(k, i)).toFixed(2) + ' ' + s[i];
  }

  function setEl(id, v) {
    const el = document.getElementById(id);
    if (el) el.textContent = v;
  }

  function fitDonutLabel(el, maxPx) {
    let lo = 8, hi = 56, best = lo;
    for (let i = 0; i < 10; i++) {
      const mid = (lo + hi) / 2;
      el.style.fontSize = mid + 'px';
      const r = el.getBoundingClientRect();
      if (r.width <= maxPx && r.height <= maxPx) { best = mid; lo = mid; } else { hi = mid; }
    }
    el.style.fontSize = best + 'px';
  }

  function aionToken() { return localStorage.getItem('aion_http_token') || ''; }

  async function aionFetch(path, opts) {
    const headers = Object.assign({ 'Content-Type': 'application/json', 'X-AION-TOKEN': aionToken() },
                                   (opts && opts.headers) || {});
    return fetch(AION_BASE + path, Object.assign({}, opts, { headers }));
  }

  async function sha256hex(buf) {
    const h = await crypto.subtle.digest('SHA-256', buf);
    return Array.from(new Uint8Array(h)).map(b => b.toString(16).padStart(2, '0')).join('');
  }

  /* ── KPI / Donut update ────────────────────────────────────────── */
  function updateKPIs(d) {
    const orig      = d.size || 0;
    const seedSz    = d.seedSize || 1;
    const ratio     = orig > 0 ? (orig / seedSz) : 0;
    const donutFg   = document.getElementById('op-donut-fg');
    const donutText = document.getElementById('op-donut-text');
    const loader    = document.getElementById('op-donut-loader');

    if (loader) loader.classList.remove('active');
    if (donutText) {
      donutText.textContent = ratio > 0 ? ratio.toFixed(1) + 'x' : '—';
      fitDonutLabel(donutText, 120 - 28 - 16);
    }
    if (donutFg) donutFg.style.strokeDashoffset = 100 - Math.min(100, ratio * 5);

    setEl('kpi-original', humanSize(orig));
    setEl('kpi-seed',     humanSize(seedSz));
    setEl('kpi-time',     d.hashTime != null ? d.hashTime.toFixed(0) + ' ms' : '—');

    const preview = document.getElementById('json-preview');
    if (preview && d.seedJSON) preview.textContent = JSON.stringify(d.seedJSON, null, 2);
  }

  /* ── Dropzone helper ───────────────────────────────────────────── */
  function wireDropzone(dropId, inputId) {
    const drop = document.getElementById(dropId);
    const inp  = document.getElementById(inputId);
    if (!drop || !inp) return;
    drop.addEventListener('click',     () => inp.click());
    drop.addEventListener('dragover',  e => { e.preventDefault(); drop.classList.add('dragover'); });
    drop.addEventListener('dragleave', () => drop.classList.remove('dragover'));
    drop.addEventListener('drop', e => {
      e.preventDefault(); drop.classList.remove('dragover');
      if (e.dataTransfer.files.length) {
        inp.files = e.dataTransfer.files;
        inp.dispatchEvent(new Event('change', { bubbles: true }));
      }
    });
  }

  /* ── State ─────────────────────────────────────────────────────── */
  let generatedSeed = null;
  let loadedSeed    = null;
  let loadedSeedFile = null;   // caminho — não disponível no browser, mas guardamos o nome

  /* ── Seção 1: Gerar Semente ────────────────────────────────────── */
  wireDropzone('dropzone-generate', 'file-input');

  const fileInput   = document.getElementById('file-input');
  const downloadBtn = document.getElementById('download-seed-btn');

  if (fileInput) {
    fileInput.addEventListener('change', async e => {
      const file = e.target.files[0]; if (!file) return;
      log('Arquivo: ' + file.name + ' (' + humanSize(file.size) + ')');

      const loader = document.getElementById('op-donut-loader');
      if (loader) loader.classList.add('active');
      if (downloadBtn) downloadBtn.disabled = true;
      const analyzeBtn = document.getElementById('analyze-btn');
      if (analyzeBtn) analyzeBtn.disabled = true;

      const t0  = performance.now();
      const buf  = await file.arrayBuffer();
      const hash = await sha256hex(buf);
      const dt   = performance.now() - t0;

      log('SHA-256: ' + hash.substring(0, 16) + '…');

      generatedSeed = {
        version:     'teia.seed.v1',
        created_utc: new Date().toISOString(),
        target_hash: hash,
        target_size: file.size,
        method:      'latent',
        source_hash: null,
        payload:     null,
        payload_size: 0,
        dict_type:   'none',
        generator:   'index30.html',
        notes:       file.name
      };
      loadedSeed = null;

      const seedSize = new TextEncoder().encode(JSON.stringify(generatedSeed)).length;
      updateKPIs({ size: file.size, seedSize, hashTime: dt, seedJSON: generatedSeed });

      if (downloadBtn) downloadBtn.disabled = false;
      if (analyzeBtn) analyzeBtn.disabled = false;

      const aiResult = document.getElementById('ai-analysis-result');
      if (aiResult) aiResult.textContent = 'Seed gerada. Clique em "Analisar Ficheiro" para análise AION.';
    });
  }

  if (downloadBtn) {
    downloadBtn.addEventListener('click', () => {
      if (!generatedSeed) return;
      const blob = new Blob([JSON.stringify(generatedSeed, null, 2)], { type: 'application/json' });
      const url  = URL.createObjectURL(blob);
      const a    = Object.assign(document.createElement('a'), {
        href: url,
        download: generatedSeed.target_hash.substring(0, 12) + '.teia.json'
      });
      a.click(); URL.revokeObjectURL(url);
      log('Semente salva: ' + a.download);
    });
  }

  /* ── Seção 2: Inspecionar + Restaurar Semente ──────────────────── */
  wireDropzone('dropzone-restore', 'seed-input-restore');

  const seedInputRestore = document.getElementById('seed-input-restore');
  const restoreBtn       = document.getElementById('restore-seed-btn');

  if (seedInputRestore) {
    seedInputRestore.addEventListener('change', async e => {
      const file = e.target.files[0]; if (!file) return;
      try {
        const data = JSON.parse(await file.text());
        if (!data.target_hash) throw new Error('Campo target_hash ausente');

        loadedSeed     = data;
        loadedSeedFile = file.name;
        generatedSeed  = null;

        updateKPIs({
          size:    data.target_size || 0,
          seedSize: file.size,
          hashTime: null,
          seedJSON: data
        });
        log('Seed inspecionada: ' + data.target_hash.substring(0, 16) + '…');
        if (restoreBtn) restoreBtn.disabled = false;

        const analyzeBtn = document.getElementById('analyze-btn');
        if (analyzeBtn) analyzeBtn.disabled = false;
        const aiResult = document.getElementById('ai-analysis-result');
        if (aiResult) aiResult.textContent = 'Seed carregada: ' + file.name + '\nPronta para restaurar via AION :$AionPort.';
      } catch (err) {
        log('Erro na seed: ' + err.message);
      }
    });
  }

  if (restoreBtn) {
    restoreBtn.addEventListener('click', async () => {
      if (!loadedSeed) return;
      restoreBtn.disabled = true;

      /* Escolhe o campo de hash mais adequado para nomear o arquivo de saida */
      const hashField = loadedSeed.target_hash || loadedSeed.seed_sha256 || 'unknown';
      const outName   = 'restored_' + hashField.substring(0, 12) + '.bin';
      log('Iniciando restore Delta procedural AION :$AionPort → ' + outName);

      try {
        const r = await aionFetch('/restore', {
          method: 'POST',
          body:   JSON.stringify({ seed: loadedSeed, out: outName })
        });
        const d = await r.json();
        if (d.restored) {
          log('Restore OK  vm=' + d.vm + '  size=' + humanSize(d.size));
          log('SHA-256: ' + d.sha256.substring(0, 16) + '…');
          const aiResult = document.getElementById('ai-analysis-result');
          if (aiResult) aiResult.textContent =
            'Restaurado com sucesso via motor Delta AION-RISPA v' + d.seed_v + '\n' +
            'VM       : ' + d.vm + '\n' +
            'SHA-256  : ' + d.sha256 + '\n' +
            'Tamanho  : ' + humanSize(d.size) + '\n' +
            'Arquivo  : ' + d.path;
        } else {
          log('Erro no restore: ' + (d.error || JSON.stringify(d)));
          if (d.detail) log('Detalhe: ' + d.detail);
        }
      } catch (err) {
        log('AION offline: ' + err.message);
        log('→ Execute AION-RISPA-PocketKernel.ps1 e recarregue');
      } finally {
        restoreBtn.disabled = false;
      }
    });
  }

  /* ── Analisar → Ollama (teia-delta) + fallback local ───────────── */
  const analyzeBtn     = document.getElementById('analyze-btn');
  const analyzeBtnText = document.getElementById('analyze-btn-text');
  const analyzeSpinner = document.getElementById('analyze-spinner');
  const aiResult       = document.getElementById('ai-analysis-result');

  if (analyzeBtn) {
    analyzeBtn.addEventListener('click', async () => {
      const seed = generatedSeed || loadedSeed;
      if (!seed) { if (aiResult) aiResult.textContent = 'Nenhuma seed disponível.'; return; }

      analyzeBtn.disabled = true;
      if (analyzeBtnText) analyzeBtnText.textContent = 'Analisando…';
      if (analyzeSpinner) analyzeSpinner.classList.remove('hidden');
      if (aiResult) aiResult.textContent = 'Consultando AION-RISPA…';

      let analysisText = '';

      try {
        const r = await fetch('http://localhost:11434/api/generate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            model:  'teia-delta',
            prompt: 'Analise esta seed TEIA em 3 frases técnicas:\n' + JSON.stringify(seed, null, 2),
            system: 'Você é um nó ativo da TEIA-Ω. SHA-256 é identidade absoluta. Responda em português, de forma determinística e concisa. Sem markdown.',
            stream: false,
            options: { temperature: 0.1, num_predict: 256 }
          }),
          signal: AbortSignal.timeout(15000)
        });
        if (r.ok) {
          const d = await r.json();
          analysisText = (d.response || '').trim();
          log('Análise: Ollama/teia-delta OK');
        }
      } catch (err) {
        log('Ollama offline (' + err.message + ') — análise local');
      }

      if (!analysisText) {
        const ratio = seed.target_size > 0
          ? (seed.target_size / JSON.stringify(seed).length).toFixed(1)
          : '—';
        analysisText = [
          'SHA-256 (target): ' + (seed.target_hash || '').substring(0, 32) + '…',
          'Método: ' + (seed.method || 'unknown') + '  |  Tamanho original: ' + humanSize(seed.target_size || 0),
          'Razão estimada: ' + ratio + 'x  |  Gerador: ' + (seed.generator || 'unknown')
        ].join('\n');
        log('Análise local (Ollama offline)');
      }

      if (aiResult) aiResult.textContent = analysisText;
      analyzeBtn.disabled = false;
      if (analyzeBtnText) analyzeBtnText.textContent = 'Analisar Novamente';
      if (analyzeSpinner) analyzeSpinner.classList.add('hidden');
    });
  }

  /* ── Sistema Info + AION Health ────────────────────────────────── */
  async function loadSystemInfo() {
    // Valores fixos do hardware (NUCLEO_ALMA.md: i3-10100F, 8GB RAM)
    setEl('sys-cpu', 'Intel i3-10100F');
    setEl('sys-ram', '8 GB DDR4');

    try {
      const r = await aionFetch('/health', { signal: AbortSignal.timeout(3000) });
      const d = await r.json();
      const ws = d.watcher_state || 'UP';
      setEl('sys-disk', 'Queue: ' + humanSize(d.queue_size || 0));
      setEl('sys-os',   'Windows 11  ·  AION:' + ws);
      log('AION :$AionPort  watcher=' + ws);
      refreshChart();
    } catch (err) {
      setEl('sys-disk', '—');
      setEl('sys-os',   'Windows 11  ·  AION:OFFLINE');
    }
  }

  /* ── Benchmark Chart update com métricas reais ─────────────────── */
  async function refreshChart() {
    try {
      const r = await aionFetch('/metrics', { signal: AbortSignal.timeout(3000) });
      const d = await r.json();
      // Chart.getChart() é a API Chart.js v3+
      const chart = typeof Chart !== 'undefined' && Chart.getChart
        ? Chart.getChart('benchmarkChart')
        : null;
      if (!chart) return;
      chart.data.labels                   = ['Restores OK', 'Erros'];
      chart.data.datasets[0].data         = [d.ok  || 0, 0];
      chart.data.datasets[1].data         = [0, d.err || 0];
      chart.update();
    } catch (e) { /* silencioso se AION offline */ }
  }

  /* ── Log tail auto-refresh ─────────────────────────────────────── */
  async function tailLogs() {
    try {
      const r = await aionFetch('/log/tail?lines=30', { signal: AbortSignal.timeout(3000) });
      const d = await r.json();
      const el = document.getElementById('logs');
      if (el && Array.isArray(d.lines) && d.lines.length) {
        el.textContent = d.lines.join('\n');
        el.scrollTop   = el.scrollHeight;
      }
    } catch (e) { /* AION offline — mantém log local */ }
  }

  /* ── Token via URL hash: index30.aion.html#token=xxxx ──────────── */
  if (location.hash && location.hash.startsWith('#token=')) {
    localStorage.setItem('aion_http_token', location.hash.substring(7));
    history.replaceState(null, '', location.pathname + location.search);
    log('Token carregado via URL hash');
  }

  /* ── Init ───────────────────────────────────────────────────────── */
  log('AION-RISPA wiring ativo → :$AionPort');
  loadSystemInfo();
  tailLogs();
  setInterval(tailLogs,       15000);
  setInterval(loadSystemInfo, 30000);

})();
</script>
"@

# Injetar imediatamente antes de </body>
if ($html -notmatch '</body>') {
    throw "index30.html não contém </body> — arquivo inesperado?"
}

$patched = $html -replace '(?i)</body>', "$wiring`n</body>"
[System.IO.File]::WriteAllText($OutPath, $patched, [System.Text.Encoding]::UTF8)

Write-Host "[PATCH] OK → $OutPath"
Write-Host "[PATCH] AION_BASE = http://127.0.0.1:$AionPort"
Write-Host "[PATCH] index30.html original intocado"
