// teia-delta-panel.js — Painel JS de operações delta para AION-RISPA-NDC
// Incluir em index30.html ou AION-RISPA-NDC.html via <script src="teia-delta-panel.js"></script>
// Requer que window.AION (injetado por Patch-Index30-For-AION.ps1) esteja disponível
;(function (global) {
  'use strict'

  const PANEL_ID = 'teia-delta-panel'

  // Helpers
  function humanSize(b) {
    if (!b) return '0 B'
    const k = 1024, s = ['B','KB','MB','GB'], i = Math.floor(Math.log(b)/Math.log(k))
    return (b/Math.pow(k,i)).toFixed(2)+' '+s[i]
  }
  async function sha256(buf) {
    const h = await crypto.subtle.digest('SHA-256', buf)
    return Array.from(new Uint8Array(h)).map(b=>b.toString(16).padStart(2,'0')).join('')
  }

  // ---- Seed Generator (browser-side, sem backend) ----
  async function generateSeed(file) {
    const buf  = await file.arrayBuffer()
    const hash = await sha256(buf)
    return {
      version:      'teia.seed.v1',
      created_utc:  new Date().toISOString(),
      target_hash:  hash,
      target_size:  file.size,
      method:       'latent',
      source_hash:  null,
      payload:      null,   // payload não gerado no browser (requer backend xdelta3)
      payload_size: 0,
      dict_type:    'none',
      generator:    'teia-delta-panel.js',
      notes:        'browser-side seed; payload must be filled by watcher actor'
    }
  }

  // ---- Enqueue restore job via AION HTTP (/enqueue) ----
  async function enqueueRestore(seed, outPath, mode) {
    const job = { mode: mode||'scan', seed: seed, out: outPath, root: '.', maxscan: 1000000 }
    if (!global.AION) throw new Error('window.AION não disponível — execute Patch-Index30-For-AION.ps1')
    const r = await global.AION.fetch('/enqueue', {
      method: 'POST',
      body: JSON.stringify(job)
    })
    return await r.json()
  }

  // ---- Panel UI ----
  function buildPanel() {
    if (document.getElementById(PANEL_ID)) return
    const panel = document.createElement('div')
    panel.id    = PANEL_ID
    panel.style.cssText = [
      'position:fixed','top:12px','left:12px','z-index:9998',
      'background:rgba(13,13,43,.95)','border:1px solid rgba(96,165,250,.35)',
      'border-radius:14px','padding:14px 18px','font-family:monospace','font-size:12px',
      'color:#e5e7eb','min-width:260px','max-width:320px',
      'backdrop-filter:blur(12px)','box-shadow:0 4px 24px rgba(0,0,0,.5)'
    ].join(';')

    panel.innerHTML = `
      <div style="font-weight:800;color:#60a5fa;margin-bottom:10px;letter-spacing:.05em">
        TEIA DELTA PANEL
      </div>

      <div style="margin-bottom:8px">
        <label style="color:#9ca3af;font-size:11px">Gerar Seed (browser)</label>
        <input type="file" id="tdp-file-in"
          style="display:block;width:100%;margin-top:3px;background:#111827;
                 border:1px solid #374151;border-radius:4px;padding:4px;
                 color:#e5e7eb;font-size:11px"/>
      </div>
      <div id="tdp-seed-preview"
        style="background:#111827;border:1px solid #1f2937;border-radius:6px;
               padding:6px;font-size:10px;color:#6b7280;min-height:44px;
               max-height:120px;overflow:auto;margin-bottom:8px;word-break:break-all">
        Arraste um arquivo acima para gerar a seed.
      </div>
      <button id="tdp-download-seed"
        style="width:100%;background:linear-gradient(135deg,#34d399,#60a5fa);
               border:none;border-radius:6px;padding:6px;cursor:pointer;
               color:#0d0d2b;font-weight:700;font-size:11px;margin-bottom:10px"
        disabled>Baixar Seed (.seed.json)</button>

      <hr style="border-color:#1f2937;margin-bottom:10px"/>

      <div style="margin-bottom:6px">
        <label style="color:#9ca3af;font-size:11px">Enqueue Restore Job</label>
        <input id="tdp-seed-path" placeholder="Caminho da seed (absoluto)" type="text"
          style="display:block;width:100%;margin-top:3px;background:#111827;
                 border:1px solid #374151;border-radius:4px;padding:4px;
                 color:#e5e7eb;font-size:11px"/>
        <input id="tdp-out-path" placeholder="Destino do arquivo restaurado" type="text"
          style="display:block;width:100%;margin-top:3px;background:#111827;
                 border:1px solid #374151;border-radius:4px;padding:4px;
                 color:#e5e7eb;font-size:11px"/>
      </div>
      <button id="tdp-enqueue"
        style="width:100%;background:linear-gradient(135deg,#f59e0b,#ef4444);
               border:none;border-radius:6px;padding:6px;cursor:pointer;
               color:#fff;font-weight:700;font-size:11px;margin-bottom:8px">
        Enqueue Restore
      </button>

      <div id="tdp-status"
        style="font-size:10px;color:#6b7280;min-height:16px;word-break:break-all"></div>
    `
    document.body.appendChild(panel)

    // --- Drag/drop + file input ---
    let currentSeed = null
    const preview = document.getElementById('tdp-seed-preview')
    const dlBtn   = document.getElementById('tdp-download-seed')
    const status  = document.getElementById('tdp-status')

    document.getElementById('tdp-file-in').addEventListener('change', async (e) => {
      const f = e.target.files[0]; if (!f) return
      status.textContent = 'Gerando seed...'
      try {
        currentSeed = await generateSeed(f)
        preview.textContent = JSON.stringify(currentSeed, null, 2)
        preview.style.color = '#34d399'
        dlBtn.disabled = false
        status.textContent = `SHA-256: ${currentSeed.target_hash.substring(0,16)}...  Tamanho: ${humanSize(f.size)}`
      } catch(err) {
        status.textContent = 'Erro: ' + err.message
      }
    })

    dlBtn.addEventListener('click', () => {
      if (!currentSeed) return
      const blob = new Blob([JSON.stringify(currentSeed, null, 2)], {type:'application/json'})
      const url  = URL.createObjectURL(blob)
      const a    = Object.assign(document.createElement('a'), {href:url, download:`${currentSeed.target_hash.substring(0,12)}.seed.json`})
      a.click(); URL.revokeObjectURL(url)
    })

    document.getElementById('tdp-enqueue').addEventListener('click', async () => {
      const seedPath = document.getElementById('tdp-seed-path').value.trim()
      const outPath  = document.getElementById('tdp-out-path').value.trim()
      if (!seedPath || !outPath) { status.textContent = 'Preencha seed_path e out_path'; return }
      status.textContent = 'Enfileirando...'
      try {
        const r = await enqueueRestore(seedPath, outPath, 'scan')
        status.textContent = r.queued ? `Enfileirado OK (queue size: ${r.len}b)` : JSON.stringify(r)
      } catch(err) {
        status.textContent = 'Erro: ' + err.message
      }
    })
  }

  // Init
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', buildPanel)
  } else {
    buildPanel()
  }

  // Export
  global.TEIADeltaPanel = { generateSeed, enqueueRestore, buildPanel }

})(typeof window !== 'undefined' ? window : globalThis)
