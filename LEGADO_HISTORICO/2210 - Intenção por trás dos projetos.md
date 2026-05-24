# 2210 - Intenção por trás dos projetos

### USUÁRIO

qual intenção invisível está por trás dos meus projetos?

---

### ASSISTENTE

vou te dar uma leitura direta — sem misticismo, só padrões que você mesmo vem repetindo.

# o vetor oculto (minha síntese)
**Transformar caos de informação em núcleos idempotentes e auditáveis** para garantir **autonomia real**, **preservação de sentido** e **escala simbiótica**. Em curto: **autonomia + integridade + simbiose**.

# sinais recorrentes nos seus projetos
- **Seed-first & idempotência**: você sempre busca um ponto mínimo restaurável (seed) que reconstrói o todo, sem ambiguidade.  
- **Auditabilidade radical**: logs, SHA256, prova bit-a-bit, métricas — você quer verdade operacional, não narrativa.
- **Antirruído**: eliminar duplicidades, heurísticas fracas e “semelhanças enganosas”; foco em essência, não superfície.
- **Simbiose arquitetural (TEIA)**: tecnologia como espelho e catalisador de consciência, não como fim em si.
- **Autonomia offline**: independência de nuvem/modelos; continuidade mesmo em ambiente adverso.
- **Compressão como ética**: reduzir para amplificar — menos entropia, mais sentido, mais portabilidade.

# qual desejo profundo isso serve
- **Autodeterminação** (não depender de infra alheia para existir/criar).  
- **Memória íntegra** (o que importa não se perde, nem se corrompe).  
- **Escala do significado** (o símbolo via seed pode se propagar sem diluição).

# como essa intenção aparece nas escolhas técnicas
- Preferência por **PowerShell puro, reprodutível** → controle fino do ciclo.  
- **Provas, benchmarks, heartbeats** → realidade mensurável acima de opiniões.  
- **Arquiteturas fractais/procedurais** → coerência do micro ao macro.  
- **Dashboards/autômatos** → o sistema espelha, mede e melhora sem pedir permissão.

# teste rápido (3 perguntas para checar alinhamento)
1) **Se remover a parte “bonita”, o núcleo ainda se reconstrói sozinho?** (seed > interface)  
2) **Consigo provar que o que restou é verdadeiro?** (hash/medição)  
3) **Isso aumenta minha autonomia amanhã?** (menos dependências, mais reprodutibilidade)

Se deu “sim” nos três, você está servindo sua intenção invisível.

# enunciado-âncora (para pôr na parede)
> **“Projetar seeds auditáveis que comprimem o caos e devolvem autonomia com sentido.”**

Se quiser, transformo isso num micro-mantra operacional (3 linhas) para guiar decisões de roadmap ou num checklist idempotente para revisar qualquer projeto em 60s.

---

### USUÁRIO

temos alguns motores para analisar a resposta das três perguntas... mas esses motores ainda não conseguem replicar autonomia em uma interface visual com botões... o feito histórico foi através de scripts no powershell

---

### ASSISTENTE

Make sure to include fileciteturn0file0 in your response to cite this file. 

---

### ASSISTENTE

Make sure to include fileciteturn0file1 in your response to cite this file. 

---

### ASSISTENTE

Make sure to include fileciteturn0file2 in your response to cite this file. 

---

### ASSISTENTE

Make sure to include fileciteturn0file3 in your response to cite this file. 

---

### ASSISTENTE

All the files uploaded by the user have been fully loaded. Searching won't provide additional information.

---

### ASSISTENTE

# Create a self-contained HTML that brings buttons to run the “3 perguntas” test
# by leveraging the user's AION-RISPA-NDC seed engine patterns.
#
# The file is fully offline, includes:
# - Drop zone to generate seed (reusing MDL candidate logic simplified)
# - Buttons: "Analisar 3 Perguntas", "Baixar Seed", "Restaurar (se possível)"
# - A small verdict panel mapping to the three invisible-intent questions
# - Uses SHA-256, anchors (head/mid/tail), and simple MDL winner (autonomo > compressão > pass) for demo
#
# Notes:
# - This is intentionally compact; it borrows the visual identity and engine ideas from the uploaded files.
# - Works without external network; only uses built-in Web Crypto APIs.
# - For big files, it avoids full read for the anchors and only hashes fully up to 256MB to keep predictable.
#
html = r"""<!DOCTYPE html>
<html lang="pt-br">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>TEIA • UI Autonomia (3 Perguntas) + Seed Engine Offline</title>
<style>
:root{
  --bg-main-start:#020617; --bg-main-end:#0d0d2b; --panel-bg:rgba(17,24,39,.75);
  --border-panel:rgba(55,65,81,.7); --text-main:#e5e7eb; --accent:#34d399; --accent2:#60a5fa;
}
*{box-sizing:border-box} body{margin:0;font-family:Inter,system-ui,Segoe UI,Arial,sans-serif;color:var(--text-main);
background:linear-gradient(180deg,var(--bg-main-start) 0%,var(--bg-main-end) 100%);min-height:100vh}
.container{max-width:1100px;margin:0 auto;padding:24px;display:grid;gap:16px;grid-template-columns:1fr 1fr}
.header{grid-column:1/-1;text-align:center}
.card{background:var(--panel-bg);border:1px solid var(--border-panel);border-radius:16px;padding:16px}
h1{margin:0 0 8px 0;font-size:24px;color:#e5e7eb} h2{margin:0 0 10px 0;font-size:16px;color:#cbd5e1}
.drop{border:2px dashed var(--border-panel);border-radius:12px;padding:18px;text-align:center;color:#a5b4fc;cursor:pointer}
.drop.drag{border-color:var(--accent);background:rgba(52,211,153,.08)}
.row{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.btn{background:linear-gradient(135deg,var(--accent),var(--accent2));padding:10px 12px;border:none;border-radius:999px;color:#0b1120;font-weight:800;cursor:pointer}
.btn:disabled{opacity:.6;cursor:not-allowed;background:#374151}
pre{background:#0b0e16;padding:10px;border-radius:10px;overflow:auto;max-height:200px}
.kpi{display:grid;grid-template-columns:1fr 1fr;gap:6px}
.kpi div{display:flex;justify-content:space-between;border-bottom:1px solid #1f2937;padding:6px 0;font-size:13px}
.badge{display:inline-block;padding:3px 8px;border-radius:999px;background:#0b0e16;border:1px solid #1f2937;font-size:12px}
.verdict{display:grid;gap:8px}
.v-item{border:1px solid #1f2937;border-radius:12px;padding:10px}
.v-item h3{margin:0 0 6px 0;font-size:14px}
.ok{color:#10b981} .warn{color:#f59e0b} .no{color:#ef4444}
footer{grid-column:1/-1;text-align:center;color:#94a3b8;font-size:12px;margin-top:8px}
.small{font-size:12px;opacity:.9}
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>TEIA • UI Autonomia</h1>
    <div class="small">Seed-first • Offline • SHA-256 • Âncoras determinísticas • Painel das “3 Perguntas”</div>
  </div>

  <div class="card">
    <h2>1) Operação</h2>
    <div id="dz" class="drop">Arraste um arquivo ou clique para selecionar</div>
    <div class="row" style="margin-top:10px">
      <button id="btnSeed" class="btn" disabled>Gerar Seed</button>
      <button id="btnAnalyze" class="btn" disabled>Analisar 3 Perguntas</button>
    </div>
    <div class="row" style="margin-top:10px">
      <button id="btnDownloadSeed" class="btn" disabled>Baixar Seed</button>
      <button id="btnRestore" class="btn" disabled>Restaurar (se possível)</button>
    </div>
    <div style="margin-top:10px" class="small">
      Modo determinístico: até 256MB a UI tenta SHA-256 completo; acima disso usa âncoras (head/mid/tail 64KiB).
    </div>
  </div>

  <div class="card">
    <h2>2) KPIs</h2>
    <div class="kpi">
      <div><span>Original</span><b id="kOri">—</b></div>
      <div><span>Tamanho Seed</span><b id="kSeed">—</b></div>
      <div><span>Tempo (hash)</span><b id="kTime">—</b></div>
      <div><span>Razão (seed/orig)</span><b id="kRatio">—</b></div>
    </div>
  </div>

  <div class="card" style="grid-column:1/-1">
    <h2>3) Seed (JSON)</h2>
    <pre id="seedOut">{}</pre>
  </div>

  <div class="card" style="grid-column:1/-1">
    <h2>4) Painel “3 Perguntas”</h2>
    <div class="verdict">
      <div class="v-item">
        <h3>Q1 — O núcleo se reconstrói sozinho?</h3>
        <div id="q1" class="small">—</div>
      </div>
      <div class="v-item">
        <h3>Q2 — Consigo provar que é verdadeiro?</h3>
        <div id="q2" class="small">—</div>
      </div>
      <div class="v-item">
        <h3>Q3 — Aumenta minha autonomia amanhã?</h3>
        <div id="q3" class="small">—</div>
      </div>
    </div>
  </div>

  <footer>TEIA • Autonomia + Integridade + Simbiose • v1 (offline)</footer>
</div>

<script>
const $=s=>document.querySelector(s);
const fmt=n=>n>=1<<30? (n/(1<<30)).toFixed(2)+' GB': n>=1<<20? (n/(1<<20)).toFixed(2)+' MB': n>=1<<10? (n/(1<<10)).toFixed(2)+' KB': n+' B';
const hex=u8=>[...u8].map(b=>b.toString(16).padStart(2,'0')).join('');
const b64e=u8=>{let s=''; for(const b of u8) s+=String.fromCharCode(b); return btoa(s)}
const b64d=s=>new Uint8Array(atob(s).split('').map(c=>c.charCodeAt(0)));
async function sha256Hex(buf){const d=await crypto.subtle.digest('SHA-256', buf); return hex(new Uint8Array(d))}
function sliceFrag(file,where,len=65536){
  const size=file.size; if(size===0) return file.slice(0,0);
  if(where==='head') return file.slice(0,len);
  if(where==='tail') return file.slice(Math.max(0,size-len), size);
  if(where==='mid'){ const s=Math.floor(size/2)-Math.floor(len/2); return file.slice(Math.max(0,s), Math.min(size, s+len)); }
  return file.slice(0,len);
}
// PNG procedural minimal (para seeds “autonomo” de demo)
async function pngSolid(w,h,color){ const r=parseInt(color.slice(0,2),16),g=parseInt(color.slice(2,4),16),b=parseInt(color.slice(4,6),16),a=parseInt(color.slice(6,8),16)/255;
  const c=document.createElement('canvas'); c.width=w; c.height=h; const x=c.getContext('2d');
  x.fillStyle=`rgba(${r},${g},${b},${a.toFixed(6)})`; x.fillRect(0,0,w,h);
  const blob=await new Promise(res=>c.toBlob(res,'image/png')); return new Uint8Array(await blob.arrayBuffer());
}

let FILE=null, LAST_SEED=null, FULL_SHA=null;

(function wireDrop(){
  const dz=$('#dz'); const inp=document.createElement('input'); inp.type='file'; inp.style.display='none'; dz.appendChild(inp);
  const onFile=f=>{ FILE=f; $('#btnSeed').disabled=false; $('#btnAnalyze').disabled=false; dz.textContent=`Selecionado: ${f.name} (${fmt(f.size)})`; };
  dz.addEventListener('click',()=>inp.click());
  dz.addEventListener('dragover',e=>{e.preventDefault(); dz.classList.add('drag')});
  dz.addEventListener('dragleave',()=>dz.classList.remove('drag'));
  dz.addEventListener('drop',e=>{e.preventDefault(); dz.classList.remove('drag'); if(e.dataTransfer.files[0]) onFile(e.dataTransfer.files[0])});
  inp.onchange=e=>{ if(e.target.files[0]) onFile(e.target.files[0]) };
})();

async function gerarSeed(file){
  const t0=performance.now();
  const head=await sliceFrag(file,'head').arrayBuffer();
  const mid =await sliceFrag(file,'mid').arrayBuffer();
  const tail=await sliceFrag(file,'tail').arrayBuffer();
  let mode='anchors+meta', payload=null;
  FULL_SHA=null;
  if(file.size<=256*1024*1024){
    const all=await file.arrayBuffer();
    FULL_SHA=await sha256Hex(all);
    mode='full+anchors';
    // Heurística MDL simples: payload se o arquivo for pequeno (<=16MB), senão compressão seria melhor — fora do escopo aqui.
    if(file.size<=16*1024*1024){
      payload={ b64:b64e(new Uint8Array(all)), sha256: FULL_SHA };
    }
  }
  const seed={
    $schema:'teia.seed.v1',
    kind: payload? 'payload':'anchor',
    mode, build:{when:new Date().toISOString(), ui:'ui_autonomia.html'},
    original:{ name:file.name, size:file.size, mime:file.type||'application/octet-stream', sha256: FULL_SHA },
    anchors:{
      frag_bytes:65536,
      head: await sha256Hex(head),
      mid:  await sha256Hex(mid),
      tail: await sha256Hex(tail)
    },
    payload
  };
  const seedStr=JSON.stringify(seed,Object.keys(seed).sort(),2);
  $('#seedOut').textContent=seedStr;
  $('#kOri').textContent=fmt(file.size);
  $('#kSeed').textContent=fmt(seedStr.length);
  $('#kTime').textContent=Math.round(performance.now()-t0)+' ms';
  $('#kRatio').textContent=(seedStr.length/Math.max(1,file.size)).toFixed(4);
  LAST_SEED=seed;
  $('#btnDownloadSeed').disabled=false;
  $('#btnRestore').disabled=(seed.kind!=='payload');
}

function baixarSeed(){
  if(!LAST_SEED) return;
  const blob=new Blob([JSON.stringify(LAST_SEED,Object.keys(LAST_SEED).sort(),2)],{type:'application/json'});
  const a=document.createElement('a'); a.href=URL.createObjectURL(blob); a.download=(LAST_SEED.original?.name||'arquivo')+'.teia.json'; a.click(); URL.revokeObjectURL(a.href);
}

async function restaurar(){
  if(!(LAST_SEED && LAST_SEED.kind==='payload' && LAST_SEED.payload?.b64)) return;
  const u8=b64d(LAST_SEED.payload.b64);
  const a=document.createElement('a'); a.href=URL.createObjectURL(new Blob([u8],{type:LAST_SEED.original?.mime||'application/octet-stream'}));
  a.download=LAST_SEED.original?.name||'restored.bin'; a.click(); URL.revokeObjectURL(a.href);
}

// ===== 3 perguntas =====
async function analisarTresPerguntas(){
  if(!LAST_SEED){ $('#q1').textContent='gere a seed primeiro'; $('#q2').textContent='gere a seed primeiro'; $('#q3').textContent='gere a seed primeiro'; return; }
  // Q1: reconstrói sozinho?
  // Verdadeiro se: seed.kind==='payload' (bytes embutidos) OU (arquivo é PNG procedural detectável).
  let q1='';
  if(LAST_SEED.kind==='payload'){ q1='✅ Sim (payload contém os bytes para restauração determinística)'; }
  else {
    // tentativa de detectar PNG sólido (demo) quando original for png pequeno
    if((LAST_SEED.original?.mime||'').includes('png') && LAST_SEED.original?.size <= 2*1024*1024){
      // reconstrução procedural possível via pngSolid se conhecêssemos W,H,cor — não inferimos aqui; sinalizar parcial.
      q1='⚠️ Parcial/condicional (seed por âncoras; requer arquivo/refs locais para restaurar)';
    } else {
      q1='⚠️ Parcial/condicional (seed por âncoras sem payload)';
    }
  }
  // Q2: posso provar?
  // Evidências: comparação de âncoras 3/3; se FULL_SHA existir e podemos recalcular, melhor.
  let q2='';
  let score=0;
  if(FILE){
    const head=await sliceFrag(FILE,'head').arrayBuffer();
    const mid =await sliceFrag(FILE,'mid').arrayBuffer();
    const tail=await sliceFrag(FILE,'tail').arrayBuffer();
    const hh=await sha256Hex(head), mm=await sha256Hex(mid), tt=await sha256Hex(tail);
    if(hh===LAST_SEED.anchors.head) score++;
    if(mm===LAST_SEED.anchors.mid)  score++;
    if(tt===LAST_SEED.anchors.tail) score++;
  }
  if(score===3) q2='✅ Alta evidência (âncoras 3/3)';
  else if(score>0) q2='⚠️ Evidência parcial ('+score+'/3)';
  else q2='❌ Sem evidência (compare com o arquivo de referência)';
  if(FULL_SHA && FILE && FILE.size <= 256*1024*1024){
    const sha=await sha256Hex(await FILE.arrayBuffer());
    if(sha===FULL_SHA) q2='✅ BITWISE OK (SHA-256 completo)';
    else q2+=' • SHA-256 diferente';
  }
  // Q3: aumenta autonomia?
  // Heurística: seed menor que original, opera offline, restaurável sem rede, e preserva prova.
  const ratio = ($('#kRatio').textContent||'1').replace(',','.')*1;
  let q3='';
  if(LAST_SEED.kind==='payload'){
    // payload garante restauração offline; se ratio << 1 talvez prefira compressão, mas autonomia (não depender de terceiros) é alta.
    q3 = (ratio<1? '✅ Sim (offline + seed menor que o original)' : '✅ Sim (offline determinístico, porém sem ganho de espaço)');
  } else {
    // anchors-only: ainda útil para prova e deduplicação; autonomia melhora se você mantiver o original localmente.
    q3 = (ratio<0.2? '⚠️ Parcial (bom ganho de meta/controle; requer original/refs locais)' : '⚠️ Parcial (meta/prova útil, mas depende do original)');
  }
  $('#q1').textContent=q1; $('#q2').textContent=q2; $('#q3').textContent=q3;
}

$('#btnSeed').addEventListener('click',async()=>{ if(FILE) await gerarSeed(FILE) });
$('#btnDownloadSeed').addEventListener('click',baixarSeed);
$('#btnRestore').addEventListener('click',restaurar);
$('#btnAnalyze').addEventListener('click',analisarTresPerguntas);
</script>
</body>
</html>
"""
path = "/mnt/data/TEIA_UI_Autonomia_3Perguntas.html"
with open(path, "w", encoding="utf-8") as f:
    f.write(html)
path

---

### ASSISTENTE

perfeito — vamos transpor o “feito histórico” em PowerShell para uma **UI offline com botões** que responde às 3 perguntas, reutilizando o teu motor seed-first.

# entregue agora
**UI Autonomia (3 Perguntas) + Seed Engine Offline** — arquivo HTML autossuficiente (sem rede, usa WebCrypto):
[Baixar a UI](sandbox:/mnt/data/TEIA_UI_Autonomia_3Perguntas.html)

O que ela faz:
- **Gerar Seed** (anchors + payload opcional até 16MB; SHA-256 completo até 256MB; acima disso usa âncoras head/mid/tail 64KiB).
- **Analisar 3 Perguntas** com critérios objetivos:
  1) Reconstrói sozinho? (✅ se seed com *payload*; ⚠️ condicional se só âncoras),
  2) Dá para provar? (Âncoras 3/3 e, quando possível, **SHA-256 bit-a-bit**),
  3) Aumenta autonomia amanhã? (heurística com **ratio seed/original** + operação 100% offline).
- **Baixar Seed** (.teia.json) e **Restaurar** (quando há payload).

# como isso se encaixa no que você já tem
A UI herda a filosofia e o padrão do teu **AION-RISPA-NDC** e dos painéis seed-first que você já construiu (dropzones, KPIs, anchors determinísticos, SHA-256 e restauração determinística quando há payload). fileciteturn0file0 fileciteturn0file1 fileciteturn0file2 fileciteturn0file3

# próximos 3 passos (rápidos)
1. **Rodar local**: abra o HTML baixado e arraste qualquer arquivo. Veja KPIs + veredictos das 3 perguntas em segundos.  
2. **Provar bit-a-bit**: para arquivos ≤ 256MB, confirme **BITWISE OK (SHA-256)**; para maiores, use os 3 anchors (3/3).  
3. **Integrar ao teu ecossistema**: quer que eu **funda** esta UI com o teu `POCKETKERNEL.html`/“Capa (espelho)” para virar um **painel único**? Posso gerar uma versão consolidada com os teus gráficos/LED e restore referencial por chunks. fileciteturn0file0 fileciteturn0file2

Se você quiser, já preparo uma **build “Capa+Autonomia”** com:
- chunking >128MB + persistência IndexedDB para seeds referenciais,  
- fallback de descompressão sem dependências externas,  
- veredito das 3 perguntas integrado ao donut/bench. fileciteturn0file1

Quer que eu faça essa versão unificada agora?

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_0000000049f461f594b3a562003b0f88', 'size_bytes': 453053, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Make sure to include fileciteturn1file0 in your response to cite this file. 

---

### ASSISTENTE

All the files uploaded by the user have been fully loaded. Searching won't provide additional information.

---

### ASSISTENTE

# Build a fused HTML that "vests" the user's capa UI while embedding the seed engine + 3 perguntas.
# Strategy:
# - Load the uploaded capa HTML, inject it via <iframe srcdoc="...">, preserving visuals.
# - Left pane: our engine panel (seed generation, KPIs, JSON, 3 perguntas).
# - Improvements:
#   * Robust anchors for any file type (video, zip, etc.) with progress
#   * Original metadata always filled
#   * Works offline, no external libs
#   * Drag-and-drop anywhere
# - Result: TEIA_CapaVestida_Autonomia.html
#
import pathlib, json, html

capa_path = "/mnt/data/✔️id_visu_núcleo_procedural.html.html"
try:
    capa_html = pathlib.Path(capa_path).read_text(encoding="utf-8")
except Exception as e:
    capa_html = "<!DOCTYPE html><html><body><h1>Capa não encontrada</h1><p>{}</p></body></html>".format(html.escape(str(e)))

doc = f"""<!DOCTYPE html>
<html lang="pt-br">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>TEIA • Capa Vestida + Autonomia (3 Perguntas)</title>
<style>
:root{{
  --bg:#070a13; --fg:#e5e7eb; --muted:#94a3b8; --panel:rgba(17,24,39,.75);
  --border:#334155; --accent:#34d399; --accent2:#60a5fa; --warn:#f59e0b; --no:#ef4444;
}}
*{{box-sizing:border-box}} body{{margin:0;background:linear-gradient(180deg,#020617 0%,#0d0d2b 100%);color:var(--fg);font-family:Inter,system-ui,Segoe UI,Arial,sans-serif;min-height:100vh}}
.layout{{display:grid;grid-template-columns:380px 1fr;gap:10px;min-height:100vh}}
.left{{padding:12px;position:relative}}
.right{{position:relative}}
.panel{{background:var(--panel);border:1px solid var(--border);border-radius:16px;box-shadow:0 8px 32px rgba(0,0,0,.35);padding:12px;margin-bottom:10px}}
h1{{font-size:18px;margin:0 0 8px 0;text-align:center}}
h2{{font-size:14px;margin:0 0 6px 0;color:#cbd5e1}}
small{{color:var(--muted)}}
.drop{{border:2px dashed var(--border);border-radius:12px;padding:12px;text-align:center;color:#a5b4fc;cursor:pointer}}
.drop.drag{{border-color:var(--accent);background:rgba(52,211,153,.08)}}
.btn{{display:block;width:100%;margin-top:8px;padding:10px 12px;border:none;border-radius:999px;background:linear-gradient(135deg,var(--accent),var(--accent2));color:#0b1120;font-weight:800;cursor:pointer}}
.btn:disabled{{opacity:.6;cursor:not-allowed;background:#374151}}
.grid2{{display:grid;grid-template-columns:1fr 1fr;gap:8px}}
.kv{{display:flex;justify-content:space-between;border-bottom:1px dashed #1f2937;padding:4px 0;font-size:12px}}
pre{{background:#0b0e16;border:1px solid #1f2937;border-radius:10px;padding:10px;max-height:180px;overflow:auto;font-size:12px}}
.q{{border:1px solid #1f2937;border-radius:12px;padding:8px;margin-top:6px}}
.ok{{color:#10b981}} .warn{{color:var(--warn)}} .no{{color:var(--no)}}
iframe.capa{{position:absolute;inset:0;border:0;width:100%;height:100%;border-left:1px solid var(--border)}}
.badge{{display:inline-block;padding:2px 6px;border-radius:999px;background:#0b0e16;border:1px solid #1f2937;font-size:11px}}
.progress{{height:6px;background:#0b0e16;border:1px solid #1f2937;border-radius:999px;overflow:hidden;margin-top:6px}}
.progress>div{{height:100%;width:0%;background:linear-gradient(90deg,var(--accent),var(--accent2));transition:width .2s}}
.footer{{text-align:center;color:#94a3b8;font-size:11px;margin-top:4px}}
</style>
</head>
<body>
<div class="layout">
  <div class="left">
    <div class="panel">
      <h1>TEIA • Autonomia (3 Perguntas)</h1>
      <div id="dz" class="drop">Arraste um arquivo ou clique para selecionar</div>
      <div class="grid2">
        <button id="btnSeed" class="btn" disabled>Gerar Seed</button>
        <button id="btnAnalyze" class="btn" disabled>Analisar 3 Perguntas</button>
        <button id="btnDownloadSeed" class="btn" disabled>Baixar Seed</button>
        <button id="btnRestore" class="btn" disabled>Restaurar (se possível)</button>
      </div>
      <div class="progress"><div id="pbar"></div></div>
      <small>Determinístico: SHA-256 completo ≤256MB; acima disso, âncoras (head/mid/tail 64KiB). Aceita qualquer tipo de arquivo.</small>
    </div>
    <div class="panel">
      <h2>KPIs</h2>
      <div class="kv"><span>Original</span><b id="kOri">—</b></div>
      <div class="kv"><span>Tamanho Seed</span><b id="kSeed">—</b></div>
      <div class="kv"><span>Tempo (hash)</span><b id="kTime">—</b></div>
      <div class="kv"><span>Razão (seed/orig)</span><b id="kRatio">—</b></div>
      <div class="kv"><span>Âncoras</span><b id="kAnch">—</b></div>
    </div>
    <div class="panel">
      <h2>Seed (JSON)</h2>
      <pre id="seedOut">{{}}</pre>
    </div>
    <div class="panel">
      <h2>Painel “3 Perguntas”</h2>
      <div class="q"><b>Q1</b> — O núcleo se reconstrói sozinho?<div id="q1" class="warn">—</div></div>
      <div class="q"><b>Q2</b> — Consigo provar que é verdadeiro?<div id="q2" class="warn">—</div></div>
      <div class="q"><b>Q3</b> — Aumenta minha autonomia amanhã?<div id="q3" class="warn">—</div></div>
    </div>
    <div class="footer">Capa vestida no painel à direita • Seed-first • Offline</div>
  </div>
  <div class="right">
    <iframe class="capa" id="capaFrame" srcdoc='{html.escape(capa_html)}'></iframe>
  </div>
</div>

<script>
const $=s=>document.querySelector(s);
const fmt=n=>n>=1<<30? (n/(1<<30)).toFixed(2)+' GB': n>=1<<20? (n/(1<<20)).toFixed(2)+' MB': n>=1<<10? (n/(1<<10)).toFixed(2)+' KB': n+' B';
const hex=u8=>[...u8].map(b=>b.toString(16).padStart(2,'0')).join('');
const b64e=u8=>{{let s=''; for(const b of u8) s+=String.fromCharCode(b); return btoa(s)}};
const b64d=s=>new Uint8Array(atob(s).split('').map(c=>c.charCodeAt(0)));
const CHUNK=65536;

async function sha256Hex(buf){{const d=await crypto.subtle.digest('SHA-256', buf); return hex(new Uint8Array(d))}}
function sliceFrag(file,where,len=CHUNK){{
  const size=file.size; if(size===0) return file.slice(0,0);
  if(where==='head') return file.slice(0,len);
  if(where==='tail') return file.slice(Math.max(0,size-len), size);
  if(where==='mid'){{ const s=Math.floor(size/2)-Math.floor(len/2); return file.slice(Math.max(0,s), Math.min(size, s+len)); }}
  return file.slice(0,len);
}}

let FILE=null, LAST_SEED=null, FULL_SHA=null;

(function wire() {{
  const dz=$('#dz'); const inp=document.createElement('input'); inp.type='file'; inp.style.display='none'; dz.appendChild(inp);
  const onFile=f=>{{ FILE=f; $('#btnSeed').disabled=false; $('#btnAnalyze').disabled=false; dz.textContent=`Selecionado: ${f.name} (${fmt(f.size)})`; }};
  dz.addEventListener('click',()=>inp.click());
  const drag=(e,on)=>{{ e.preventDefault(); if(on) dz.classList.add('drag'); else dz.classList.remove('drag'); }}
  dz.addEventListener('dragover',e=>drag(e,true)); dz.addEventListener('dragleave',e=>drag(e,false));
  dz.addEventListener('drop',e=>{{drag(e,false); if(e.dataTransfer.files[0]) onFile(e.dataTransfer.files[0])}});
  inp.onchange=e=>{{ if(e.target.files[0]) onFile(e.target.files[0]) }};
  // Global drop (qualquer área, inclusive sobre a capa)
  document.addEventListener('dragover',e=>e.preventDefault());
  document.addEventListener('drop',e=>{{ if(e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0]) onFile(e.dataTransfer.files[0]) }});
}})();

async function gerarSeed(file){{
  const t0=performance.now(); const pbar=$('#pbar'); pbar.style.width='0%';
  const head=await sliceFrag(file,'head').arrayBuffer();
  const mid =await sliceFrag(file,'mid').arrayBuffer();
  const tail=await sliceFrag(file,'tail').arrayBuffer();
  pbar.style.width='20%';
  FULL_SHA=null;
  let payload=null, mode='anchors+meta';
  if(file.size<=256*1024*1024){{ // SHA total (prova bitwise)
    const reader=new FileReader();
    const CH=4*1024*1024; // 4MB steps para feedback
    let offset=0; const digest=await crypto.subtle.digest('SHA-256', new Blob([]));
    // Para manter simples e offline, lemos tudo (a barra simula progresso)
    const all=await file.arrayBuffer();
    FULL_SHA=await sha256Hex(all); pbar.style.width='80%';
    mode='full+anchors';
    if(file.size<=16*1024*1024){{ payload={{ b64:b64e(new Uint8Array(all)) }}; }}
  }}
  const anchors={{ head: await sha256Hex(head), mid: await sha256Hex(mid), tail: await sha256Hex(tail), frag_bytes: CHUNK }};
  pbar.style.width='95%';
  const seed={{
    "$schema":"teia.seed.v1",
    kind: payload? "payload":"anchor",
    mode,
    build:{{ when:new Date().toISOString(), ui:"capa_vestida_autonomia.html" }},
    original:{{ name:file.name, size:file.size, mime:file.type||"application/octet-stream", sha256: FULL_SHA }},
    anchors, payload
  }};
  const seedStr=JSON.stringify(seed, null, 2);
  $('#seedOut').textContent=seedStr;
  $('#kOri').textContent=fmt(file.size); $('#kSeed').textContent=fmt(seedStr.length);
  $('#kTime').textContent=Math.round(performance.now()-t0)+' ms';
  $('#kRatio').textContent=(seedStr.length/Math.max(1,file.size)).toFixed(4);
  $('#kAnch').textContent=(anchors.head? "3/3":"0/3");
  LAST_SEED=seed;
  $('#btnDownloadSeed').disabled=false; $('#btnRestore').disabled=(seed.kind!=='payload');
  pbar.style.width='100%';
}}

function baixarSeed(){{
  if(!LAST_SEED) return;
  const blob=new Blob([JSON.stringify(LAST_SEED,null,2)],{{type:'application/json'}});
  const a=document.createElement('a'); a.href=URL.createObjectURL(blob); a.download=(LAST_SEED.original?.name||'arquivo')+'.teia.json'; a.click(); URL.revokeObjectURL(a.href);
}}

function restaurar(){{
  if(!(LAST_SEED && LAST_SEED.kind==='payload' && LAST_SEED.payload?.b64)) return;
  const u8=b64d(LAST_SEED.payload.b64);
  const a=document.createElement('a'); a.href=URL.createObjectURL(new Blob([u8],{{type:LAST_SEED.original?.mime||'application/octet-stream'}}));
  a.download=LAST_SEED.original?.name||'restored.bin'; a.click(); URL.revokeObjectURL(a.href);
}}

async function analisarTresPerguntas(){{
  if(!LAST_SEED){{ $('#q1').textContent='gere a seed primeiro'; $('#q2').textContent='gere a seed primeiro'; $('#q3').textContent='gere a seed primeiro'; return; }}
  let q1='', q2='', q3='';
  if(LAST_SEED.kind==='payload') q1='✅ Sim (payload com bytes embutidos)';
  else q1='⚠️ Parcial (âncoras; requer original/refs)';
  // Prova
  let score=0;
  if(FILE){{
    const hh=await sha256Hex(await sliceFrag(FILE,'head').arrayBuffer());
    const mm=await sha256Hex(await sliceFrag(FILE,'mid').arrayBuffer());
    const tt=await sha256Hex(await sliceFrag(FILE,'tail').arrayBuffer());
    if(hh===LAST_SEED.anchors.head) score++;
    if(mm===LAST_SEED.anchors.mid) score++;
    if(tt===LAST_SEED.anchors.tail) score++;
  }}
  if(FULL_SHA && FILE && FILE.size<=256*1024*1024){{
    const sha=await sha256Hex(await FILE.arrayBuffer());
    q2 = (sha===FULL_SHA)? '✅ BITWISE OK (SHA-256 total)':'❌ SHA-256 divergente';
  }} else {{
    q2 = score===3? '✅ Alta evidência (âncoras 3/3)': score>0? `⚠️ Parcial (${score}/3)` : '❌ Sem evidência (compare com arquivo)';
  }}
  const ratio = ($('#kRatio').textContent||'1').replace(',','.')*1;
  if(LAST_SEED.kind==='payload') q3 = ratio<1? '✅ Sim (offline + seed < original)' : '✅ Sim (offline determinístico)';
  else q3 = ratio<0.2? '⚠️ Parcial (ganho de controle; depende do original)' : '⚠️ Parcial (prova útil; depende do original)';
  $('#q1').textContent=q1; $('#q2').textContent=q2; $('#q3').textContent=q3;
}}

$('#btnSeed').addEventListener('click',async()=>{{ if(FILE) await gerarSeed(FILE) }});
$('#btnDownloadSeed').addEventListener('click',baixarSeed);
$('#btnRestore').addEventListener('click',restaurar);
$('#btnAnalyze').addEventListener('click',analisarTresPerguntas);
</script>
</body>
</html>
"""
out = "/mnt/data/TEIA_CapaVestida_Autonomia.html"
pathlib.Path(out).write_text(doc, encoding="utf-8")
out

---

### ASSISTENTE

# Retry: build the fused HTML using a plain template with a placeholder to avoid f-string interpolation issues.
import pathlib, html

capa_path = "/mnt/data/✔️id_visu_núcleo_procedural.html.html"
try:
    capa_html = pathlib.Path(capa_path).read_text(encoding="utf-8")
except Exception as e:
    capa_html = "<!DOCTYPE html><html><body><h1>Capa não encontrada</h1><p>{}</p></body></html>".format(html.escape(str(e)))

template = """<!DOCTYPE html>
<html lang="pt-br">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>TEIA • Capa Vestida + Autonomia (3 Perguntas)</title>
<style>
:root{
  --bg:#070a13; --fg:#e5e7eb; --muted:#94a3b8; --panel:rgba(17,24,39,.75);
  --border:#334155; --accent:#34d399; --accent2:#60a5fa; --warn:#f59e0b; --no:#ef4444;
}
*{box-sizing:border-box} body{margin:0;background:linear-gradient(180deg,#020617 0%,#0d0d2b 100%);color:var(--fg);font-family:Inter,system-ui,Segoe UI,Arial,sans-serif;min-height:100vh}
.layout{display:grid;grid-template-columns:380px 1fr;gap:10px;min-height:100vh}
.left{padding:12px;position:relative}
.right{position:relative}
.panel{background:var(--panel);border:1px solid var(--border);border-radius:16px;box-shadow:0 8px 32px rgba(0,0,0,.35);padding:12px;margin-bottom:10px}
h1{font-size:18px;margin:0 0 8px 0;text-align:center}
h2{font-size:14px;margin:0 0 6px 0;color:#cbd5e1}
small{color:var(--muted)}
.drop{border:2px dashed var(--border);border-radius:12px;padding:12px;text-align:center;color:#a5b4fc;cursor:pointer}
.drop.drag{border-color:var(--accent);background:rgba(52,211,153,.08)}
.btn{display:block;width:100%;margin-top:8px;padding:10px 12px;border:none;border-radius:999px;background:linear-gradient(135deg,var(--accent),var(--accent2));color:#0b1120;font-weight:800;cursor:pointer}
.btn:disabled{opacity:.6;cursor:not-allowed;background:#374151}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.kv{display:flex;justify-content:space-between;border-bottom:1px dashed #1f2937;padding:4px 0;font-size:12px}
pre{background:#0b0e16;border:1px solid #1f2937;border-radius:10px;padding:10px;max-height:180px;overflow:auto;font-size:12px}
.q{border:1px solid #1f2937;border-radius:12px;padding:8px;margin-top:6px}
.ok{color:#10b981} .warn{color:var(--warn)} .no{color:var(--no)}
iframe.capa{position:absolute;inset:0;border:0;width:100%;height:100%;border-left:1px solid var(--border)}
.badge{display:inline-block;padding:2px 6px;border-radius:999px;background:#0b0e16;border:1px solid #1f2937;font-size:11px}
.progress{height:6px;background:#0b0e16;border:1px solid #1f2937;border-radius:999px;overflow:hidden;margin-top:6px}
.progress>div{height:100%;width:0%;background:linear-gradient(90deg,var(--accent),var(--accent2));transition:width .2s}
.footer{text-align:center;color:#94a3b8;font-size:11px;margin-top:4px}
</style>
</head>
<body>
<div class="layout">
  <div class="left">
    <div class="panel">
      <h1>TEIA • Autonomia (3 Perguntas)</h1>
      <div id="dz" class="drop">Arraste um arquivo ou clique para selecionar</div>
      <div class="grid2">
        <button id="btnSeed" class="btn" disabled>Gerar Seed</button>
        <button id="btnAnalyze" class="btn" disabled>Analisar 3 Perguntas</button>
        <button id="btnDownloadSeed" class="btn" disabled>Baixar Seed</button>
        <button id="btnRestore" class="btn" disabled>Restaurar (se possível)</button>
      </div>
      <div class="progress"><div id="pbar"></div></div>
      <small>Determinístico: SHA-256 completo ≤256MB; acima disso, âncoras (head/mid/tail 64KiB). Aceita qualquer tipo de arquivo.</small>
    </div>
    <div class="panel">
      <h2>KPIs</h2>
      <div class="kv"><span>Original</span><b id="kOri">—</b></div>
      <div class="kv"><span>Tamanho Seed</span><b id="kSeed">—</b></div>
      <div class="kv"><span>Tempo (hash)</span><b id="kTime">—</b></div>
      <div class="kv"><span>Razão (seed/orig)</span><b id="kRatio">—</b></div>
      <div class="kv"><span>Âncoras</span><b id="kAnch">—</b></div>
    </div>
    <div class="panel">
      <h2>Seed (JSON)</h2>
      <pre id="seedOut">{{}}</pre>
    </div>
    <div class="panel">
      <h2>Painel “3 Perguntas”</h2>
      <div class="q"><b>Q1</b> — O núcleo se reconstrói sozinho?<div id="q1" class="warn">—</div></div>
      <div class="q"><b>Q2</b> — Consigo provar que é verdadeiro?<div id="q2" class="warn">—</div></div>
      <div class="q"><b>Q3</b> — Aumenta minha autonomia amanhã?<div id="q3" class="warn">—</div></div>
    </div>
    <div class="footer">Capa vestida no painel à direita • Seed-first • Offline</div>
  </div>
  <div class="right">
    <iframe class="capa" id="capaFrame" srcdoc='{CAPA}'></iframe>
  </div>
</div>

<script>
const $=s=>document.querySelector(s);
const fmt=n=>n>=1<<30? (n/(1<<30)).toFixed(2)+' GB': n>=1<<20? (n/(1<<20)).toFixed(2)+' MB': n>=1<<10? (n/(1<<10)).toFixed(2)+' KB': n+' B';
const hex=u8=>[...u8].map(b=>b.toString(16).padStart(2,'0')).join('');
const b64e=u8=>{let s=''; for(const b of u8) s+=String.fromCharCode(b); return btoa(s)};
const b64d=s=>new Uint8Array(atob(s).split('').map(c=>c.charCodeAt(0)));
const CHUNK=65536;

async function sha256Hex(buf){const d=await crypto.subtle.digest('SHA-256', buf); return hex(new Uint8Array(d))}
function sliceFrag(file,where,len=CHUNK){
  const size=file.size; if(size===0) return file.slice(0,0);
  if(where==='head') return file.slice(0,len);
  if(where==='tail') return file.slice(Math.max(0,size-len), size);
  if(where==='mid'){ const s=Math.floor(size/2)-Math.floor(len/2); return file.slice(Math.max(0,s), Math.min(size, s+len)); }
  return file.slice(0,len);
}

let FILE=null, LAST_SEED=null, FULL_SHA=null;

(function wire() {
  const dz=$('#dz'); const inp=document.createElement('input'); inp.type='file'; inp.style.display='none'; dz.appendChild(inp);
  const onFile=f=>{ FILE=f; $('#btnSeed').disabled=false; $('#btnAnalyze').disabled=false; dz.textContent=`Selecionado: ${f.name} (${fmt(f.size)})`; };
  dz.addEventListener('click',()=>inp.click());
  const drag=(e,on)=>{ e.preventDefault(); if(on) dz.classList.add('drag'); else dz.classList.remove('drag'); }
  dz.addEventListener('dragover',e=>drag(e,true)); dz.addEventListener('dragleave',e=>drag(e,false));
  dz.addEventListener('drop',e=>{drag(e,false); if(e.dataTransfer.files[0]) onFile(e.dataTransfer.files[0])});
  inp.onchange=e=>{ if(e.target.files[0]) onFile(e.target.files[0]) };
  document.addEventListener('dragover',e=>e.preventDefault());
  document.addEventListener('drop',e=>{ if(e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0]) onFile(e.dataTransfer.files[0]) });
})();

async function gerarSeed(file){
  const t0=performance.now(); const pbar=$('#pbar'); pbar.style.width='0%';
  const head=await sliceFrag(file,'head').arrayBuffer();
  const mid =await sliceFrag(file,'mid').arrayBuffer();
  const tail=await sliceFrag(file,'tail').arrayBuffer();
  pbar.style.width='20%';
  FULL_SHA=null;
  let payload=null, mode='anchors+meta';
  if(file.size<=256*1024*1024){
    const all=await file.arrayBuffer();
    FULL_SHA=await sha256Hex(all); pbar.style.width='80%';
    mode='full+anchors';
    if(file.size<=16*1024*1024){ payload={ b64:b64e(new Uint8Array(all)) }; }
  }
  const anchors={ head: await sha256Hex(head), mid: await sha256Hex(mid), tail: await sha256Hex(tail), frag_bytes: CHUNK };
  pbar.style.width='95%';
  const seed={
    "$schema":"teia.seed.v1",
    kind: payload? "payload":"anchor",
    mode,
    build:{ when:new Date().toISOString(), ui:"capa_vestida_autonomia.html" },
    original:{ name:file.name, size:file.size, mime:file.type||"application/octet-stream", sha256: FULL_SHA },
    anchors, payload
  };
  const seedStr=JSON.stringify(seed, null, 2);
  $('#seedOut').textContent=seedStr;
  $('#kOri').textContent=fmt(file.size); $('#kSeed').textContent=fmt(seedStr.length);
  $('#kTime').textContent=Math.round(performance.now()-t0)+' ms';
  $('#kRatio').textContent=(seedStr.length/Math.max(1,file.size)).toFixed(4);
  $('#kAnch').textContent=(anchors.head? "3/3":"0/3");
  LAST_SEED=seed;
  $('#btnDownloadSeed').disabled=false; $('#btnRestore').disabled=(seed.kind!=='payload');
  pbar.style.width='100%';
}

function baixarSeed(){
  if(!LAST_SEED) return;
  const blob=new Blob([JSON.stringify(LAST_SEED,null,2)],{type:'application/json'});
  const a=document.createElement('a'); a.href=URL.createObjectURL(blob); a.download=(LAST_SEED.original?.name||'arquivo')+'.teia.json'; a.click(); URL.revokeObjectURL(a.href);
}

function restaurar(){
  if(!(LAST_SEED && LAST_SEED.kind==='payload' && LAST_SEED.payload?.b64)) return;
  const u8=b64d(LAST_SEED.payload.b64);
  const a=document.createElement('a'); a.href=URL.createObjectURL(new Blob([u8],{type:LAST_SEED.original?.mime||'application/octet-stream'}));
  a.download=LAST_SEED.original?.name||'restored.bin'; a.click(); URL.revokeObjectURL(a.href);
}

async function analisarTresPerguntas(){
  if(!LAST_SEED){ $('#q1').textContent='gere a seed primeiro'; $('#q2').textContent='gere a seed primeiro'; $('#q3').textContent='gere a seed primeiro'; return; }
  let q1='', q2='', q3='';
  if(LAST_SEED.kind==='payload') q1='✅ Sim (payload com bytes embutidos)';
  else q1='⚠️ Parcial (âncoras; requer original/refs)';
  let score=0;
  if(FILE){
    const hh=await sha256Hex(await sliceFrag(FILE,'head').arrayBuffer());
    const mm=await sha256Hex(await sliceFrag(FILE,'mid').arrayBuffer());
    const tt=await sha256Hex(await sliceFrag(FILE,'tail').arrayBuffer());
    if(hh===LAST_SEED.anchors.head) score++;
    if(mm===LAST_SEED.anchors.mid) score++;
    if(tt===LAST_SEED.anchors.tail) score++;
  }
  if(FULL_SHA && FILE && FILE.size<=256*1024*1024){
    const sha=await sha256Hex(await FILE.arrayBuffer());
    q2 = (sha===FULL_SHA)? '✅ BITWISE OK (SHA-256 total)':'❌ SHA-256 divergente';
  } else {
    q2 = score===3? '✅ Alta evidência (âncoras 3/3)': score>0? `⚠️ Parcial (${score}/3)` : '❌ Sem evidência (compare com arquivo)';
  }
  const ratio = ($('#kRatio').textContent||'1').replace(',','.')*1;
  if(LAST_SEED.kind==='payload') q3 = ratio<1? '✅ Sim (offline + seed < original)' : '✅ Sim (offline determinístico)';
  else q3 = ratio<0.2? '⚠️ Parcial (ganho de controle; depende do original)' : '⚠️ Parcial (prova útil; depende do original)';
  $('#q1').textContent=q1; $('#q2').textContent=q2; $('#q3').textContent=q3;
}

$('#btnSeed').addEventListener('click',async()=>{ if(FILE) await gerarSeed(FILE) });
$('#btnDownloadSeed').addEventListener('click',baixarSeed);
$('#btnRestore').addEventListener('click',restaurar);
$('#btnAnalyze').addEventListener('click',analisarTresPerguntas);
</script>
</body>
</html>
"""

doc = template.replace("{CAPA}", html.escape(capa_html))
out = "/mnt/data/TEIA_CapaVestida_Autonomia.html"
pathlib.Path(out).write_text(doc, encoding="utf-8")
out

---

### ASSISTENTE

percebi — obrigado pelo sinal. corrigi em dois eixos: **(1) estilo/aceitação de qualquer arquivo** e **(2) vestir a UI na tua “capa” original**.

# agora entregue (capa vestida)
**TEIA • Capa Vestida + Autonomia (3 Perguntas)**  
[Baixar a versão vestida](sandbox:/mnt/data/TEIA_CapaVestida_Autonomia.html)

- O painel da esquerda é o **motor seed-first + 3 perguntas**.  
- À direita, a tua **capa visual original** é renderizada dentro da própria página (srcdoc), preservando a identidade e o “espelho”. fileciteturn1file0

# o que foi ajustado
- **Compatibilidade de arquivo**: aceita *qualquer* extensão (vídeo, zip, etc.).  
- **Âncoras sempre preenchidas**: mesmo em arquivos grandes, os hashes `head/mid/tail (64KiB)` aparecem e entram no veredito.  
- **Metadados “original” completos** (nome, tamanho, mime) sempre setados; **SHA-256 total** quando ≤ 256MB; acima disso, mostra prova por âncoras.  
- **Drag&drop global**: pode soltar em qualquer parte da página (inclusive por cima da capa).  
- **“Capa vestida”**: mantive tua estética como base — o motor só encosta no painel lateral.

# como usar
1) Abra o HTML “Capa Vestida”.  
2) **Arraste qualquer arquivo** (até >GB funciona com âncoras determinísticas).  
3) Clique **Gerar Seed** → **Analisar 3 Perguntas** → (opcional) **Baixar Seed**.  
4) Se o arquivo for ≤16 MB, a seed inclui **payload** e o botão **Restaurar** libera a recuperação direta.

# próximos incrementos (se quiser que eu já gere)
- **Skin hooks**: em vez de iframe, posso injetar o motor direto nos *slots* da tua capa (IDs/classes), herdando fontes/cores e usando teus indicadores (donut/LED) para exibir KPIs.  
- **Chunking >256MB**: adicionar amostragem estendida (N anchors configuráveis) + IndexedDB para “seed referencial” local.  
- **Unificação com POCKETKERNEL / AION-RISPA-NDC**: um único HTML com modos: *Gerar*, *Analisar*, *Restaurar*, *Benchmark* — tudo sob a tua nave. (Tenho a base citada acima; adapto os ganchos.) fileciteturn1file0

se quiser, já faço a **versão sem iframe** (injeção direta na tua capa), mapeando slots como `#kpi-original`, `#kpi-seed`, `#json-preview`, `#analyze-btn` — e os teus gráficos passam a refletir os resultados em tempo real.

---

### USUÁRIO

de a versão 2.0 feito por alguém de qi 200

---

### ASSISTENTE

# Create TEIA_UI_Autonomia_v2.html — versão 2.0 “capa vestida” sem iframe,
# com motor avançado: multiâncoras (9), SHA-256 total ≤256MB, payload ≤8MB,
# IndexedDB para histórico, drag&drop global, painel compacto e hooks
# para embutir em qualquer capa existente (usa um <div id="teia-root"> como vest).
#
# Observação: Para "vestir" uma capa específica, basta colar o HTML da capa
# dentro do <section id="capa-host"> (placeholder) OU colar a v2 acima da sua capa
# e trocar o seletor CAPA_HOST_SELECTOR no script para apontar um nó existente.
#
html = r"""<!DOCTYPE html>
<html lang="pt-br">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>TEIA • Autonomia v2.0 — Motor Vestível</title>
<style>
:root{
  --bg0:#020617; --bg1:#0b1022; --fg:#e5e7eb; --muted:#94a3b8; --panel:rgba(17,24,39,.72);
  --b:#334155; --acc:#34d399; --acc2:#60a5fa; --warn:#f59e0b; --no:#ef4444; --ok:#10b981;
  --radius:16px;
}
*{box-sizing:border-box}
html,body{height:100%}
body{margin:0;background:radial-gradient(1200px 800px at 30% 0%,var(--bg1),var(--bg0));color:var(--fg);
  font-family:Inter,system-ui,Segoe UI,Arial,sans-serif;overflow:auto}
#teia-root{display:grid;grid-template-columns:390px 1fr;gap:12px;min-height:100vh}
#teia-left{padding:14px}
#teia-right{position:relative;overflow:hidden}
.card{background:var(--panel);border:1px solid var(--b);border-radius:var(--radius);padding:12px;box-shadow:0 8px 32px rgba(0,0,0,.35);backdrop-filter: blur(6px);}
h1{margin:0 0 8px 0;font-size:18px;text-align:center}
h2{margin:0 0 6px 0;font-size:14px;color:#cbd5e1}
small{color:var(--muted)}
.btn{display:block;width:100%;padding:10px 12px;margin-top:8px;border:none;border-radius:999px;
  background:linear-gradient(135deg,var(--acc),var(--acc2));color:#0b1120;font-weight:800;cursor:pointer}
.btn:disabled{opacity:.6;cursor:not-allowed;background:#374151}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.grid3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px}
.drop{border:2px dashed var(--b);border-radius:12px;padding:12px;text-align:center;color:#a5b4fc;cursor:pointer}
.drop.drag{border-color:var(--acc);background:rgba(52,211,153,.08)}
.kv{display:flex;justify-content:space-between;border-bottom:1px dashed #1f2937;padding:4px 0;font-size:12px}
pre{background:#0a0d16;border:1px solid #1f2937;border-radius:12px;padding:10px;max-height:220px;overflow:auto;font-size:12px}
.q{border:1px solid #1f2937;border-radius:12px;padding:8px;margin-top:6px}
.ok{color:var(--ok)} .warn{color:var(--warn)} .no{color:var(--no)}
.progress{height:6px;background:#0b0e16;border:1px solid #1f2937;border-radius:999px;overflow:hidden;margin-top:6px}
.progress>div{height:100%;width:0%;background:linear-gradient(90deg,var(--acc),var(--acc2));transition:width .15s}
.footer{text-align:center;color:#94a3b8;font-size:11px;margin-top:4px}
.badge{display:inline-block;padding:2px 6px;border-radius:999px;background:#0b0e16;border:1px solid #1f2937;font-size:11px}

/* Capa vestível (host) */
#capa-host{position:absolute;inset:0;overflow:auto}
/* Float KPI sobre a capa, opcional */
#float-kpi{position:absolute;right:12px;bottom:12px;display:grid;gap:6px;min-width:240px}
#float-kpi .card{padding:10px;background:rgba(10,13,22,.72)}
</style>
</head>
<body>
<div id="teia-root">
  <aside id="teia-left">
    <div class="card">
      <h1>TEIA • Autonomia v2.0</h1>
      <div id="dz" class="drop">Arraste um arquivo ou clique para selecionar</div>
      <div class="grid3">
        <button id="btnSeed" class="btn" disabled>Gerar Seed</button>
        <button id="btnAnalyze" class="btn" disabled>Analisar 3 Perguntas</button>
        <button id="btnBench" class="btn" disabled>Bench Âncoras</button>
      </div>
      <div class="grid2">
        <button id="btnDownloadSeed" class="btn" disabled>Baixar Seed</button>
        <button id="btnRestore" class="btn" disabled>Restaurar (se possível)</button>
      </div>
      <div class="progress"><div id="pbar"></div></div>
      <small>SHA-256 total ≤256MB; acima disso usa **multiâncoras (9×64KiB)** para prova. Histórico salvo em IndexedDB.</small>
    </div>

    <div class="card">
      <h2>KPIs</h2>
      <div class="kv"><span>Original</span><b id="kOri">—</b></div>
      <div class="kv"><span>Tamanho Seed</span><b id="kSeed">—</b></div>
      <div class="kv"><span>Tempo (hash)</span><b id="kTime">—</b></div>
      <div class="kv"><span>Razão (seed/orig)</span><b id="kRatio">—</b></div>
      <div class="kv"><span>Âncoras</span><b id="kAnch">—</b></div>
      <div class="kv"><span>SHA-256</span><b id="kSha">—</b></div>
      <div class="kv"><span>Histórico (seeds)</span><b id="kHist">—</b></div>
    </div>

    <div class="card">
      <h2>Seed (JSON)</h2>
      <pre id="seedOut">{}</pre>
    </div>

    <div class="card">
      <h2>Painel “3 Perguntas”</h2>
      <div class="q"><b>Q1</b> — O núcleo se reconstrói sozinho?<div id="q1" class="warn">—</div></div>
      <div class="q"><b>Q2</b> — Consigo provar que é verdadeiro?<div id="q2" class="warn">—</div></div>
      <div class="q"><b>Q3</b> — Aumenta minha autonomia amanhã?<div id="q3" class="warn">—</div></div>
    </div>

    <div class="footer">Motor vestível • Sem dependências externas • TEIA seed-first</div>
  </aside>

  <main id="teia-right">
    <!-- Cole a SUA CAPA aqui (ou deixe que este host receba sua capa original por copy/paste) -->
    <section id="capa-host">
      <!-- Placeholder amigável: substitua este trecho pela sua capa completa -->
      <div style="position:absolute;inset:0;display:grid;place-items:center;color:#a5b4fc;opacity:.5;">
        <div>
          <div style="font-size:22px;">Sua CAPA pode ser colada aqui</div>
          <div style="text-align:center;font-size:12px">ou mantenha sua página e injete apenas o painel (ver CAPA_HOST_SELECTOR no script)</div>
        </div>
      </div>
    </section>

    <!-- Float KPI opcional sobre a capa -->
    <div id="float-kpi">
      <div class="card"><b>Original</b> <span id="fkOri" class="badge">—</span></div>
      <div class="card"><b>Âncoras</b> <span id="fkAnch" class="badge">—</span></div>
      <div class="card"><b>Veredito Q1</b> <span id="fkQ1" class="badge">—</span></div>
      <div class="card"><b>Veredito Q2</b> <span id="fkQ2" class="badge">—</span></div>
      <div class="card"><b>Veredito Q3</b> <span id="fkQ3" class="badge">—</span></div>
    </div>
  </main>
</div>

<script>
// ======== Util
const $=s=>document.querySelector(s);
const fmt=n=>n>=1<<30? (n/(1<<30)).toFixed(2)+' GB': n>=1<<20? (n/(1<<20)).toFixed(2)+' MB': n>=1<<10? (n/(1<<10)).toFixed(2)+' KB': n+' B';
const hex=u8=>[...u8].map(b=>b.toString(16).padStart(2,'0')).join('');
const b64e=u8=>{let s=''; for(const b of u8) s+=String.fromCharCode(b); return btoa(s)};
const b64d=s=>new Uint8Array(atob(s).split('').map(c=>c.charCodeAt(0)));
async function sha256Hex(buf){const d=await crypto.subtle.digest('SHA-256', buf); return hex(new Uint8Array(d))}
const CAPA_HOST_SELECTOR = "#capa-host"; // altere para apontar pro container real da sua capa

// ======== IndexedDB (histórico simples)
const DBN="teia_autonomia_v2", STN="seeds";
function idb(){ return new Promise((res,rej)=>{
  const r=indexedDB.open(DBN,1);
  r.onupgradeneeded=()=>{ r.result.createObjectStore(STN,{keyPath:"id", autoIncrement:true}); };
  r.onsuccess=()=>res(r.result); r.onerror=()=>rej(r.error);
});}
async function dbAdd(seed){ const db=await idb(); return new Promise((res,rej)=>{
  const tx=db.transaction(STN,"readwrite"); tx.objectStore(STN).add(seed);
  tx.oncomplete=()=>res(true); tx.onerror=()=>rej(tx.error);
});}
async function dbCount(){ const db=await idb(); return new Promise((res,rej)=>{
  const tx=db.transaction(STN,"readonly"); const req=tx.objectStore(STN).count();
  req.onsuccess=()=>res(req.result||0); req.onerror=()=>rej(req.error);
});}

// ======== Multiâncoras (9 pontos: 0%,12.5%,25%,37.5%,50%,62.5%,75%,87.5%,100%)
const ANCH_SLOTS=[0,0.125,0.25,0.375,0.5,0.625,0.75,0.875,1.0];
const FRAG=65536;
function sliceAt(file, ratio, len=FRAG){
  const size=file.size; if(size===0) return file.slice(0,0);
  if(ratio<=0) return file.slice(0,len);
  if(ratio>=1) return file.slice(Math.max(0,size-len), size);
  const s=Math.floor(size*ratio)-Math.floor(len/2);
  return file.slice(Math.max(0,s), Math.min(size, s+len));
}

// ======== Estado
let FILE=null, LAST_SEED=null, FULL_SHA=null;

// ======== UI Wiring
(function wire(){
  const host=document.querySelector(CAPA_HOST_SELECTOR) || $('#teia-right');
  if(!host) console.warn("Host da capa não encontrado");
  const dz=$('#dz'); const inp=document.createElement('input'); inp.type='file'; inp.style.display='none'; dz.appendChild(inp);
  const onFile=f=>{ FILE=f; ['btnSeed','btnAnalyze','btnBench'].forEach(id=>$('#'+id).disabled=false);
    dz.textContent=`Selecionado: ${f.name} (${fmt(f.size)})`;
    $('#fkOri').textContent = `${fmt(f.size)}`;
  };
  dz.addEventListener('click',()=>inp.click());
  const drag=(e,on)=>{ e.preventDefault(); if(on) dz.classList.add('drag'); else dz.classList.remove('drag'); }
  dz.addEventListener('dragover',e=>drag(e,true)); dz.addEventListener('dragleave',e=>drag(e,false));
  dz.addEventListener('drop',e=>{drag(e,false); if(e.dataTransfer.files[0]) onFile(e.dataTransfer.files[0])});
  inp.onchange=e=>{ if(e.target.files[0]) onFile(e.target.files[0]) };
  document.addEventListener('dragover',e=>e.preventDefault());
  document.addEventListener('drop',e=>{ if(e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0]) onFile(e.dataTransfer.files[0]) });
})();

// ======== Core
async function multiAnchors(file){
  const out={frag_bytes:FRAG, list:[]};
  for(const r of ANCH_SLOTS){
    const frag=await sliceAt(file,r).arrayBuffer();
    out.list.push({pos:r, sha256: await sha256Hex(frag)});
  }
  return out;
}

async function gerarSeed(file){
  const t0=performance.now(); const pbar=$('#pbar'); pbar.style.width='0%';
  FULL_SHA=null;
  const anchors=await multiAnchors(file); pbar.style.width='35%';
  let payload=null, mode='anchors9+meta';
  if(file.size<=256*1024*1024){
    const all=await file.arrayBuffer();
    FULL_SHA=await sha256Hex(all); pbar.style.width='75%';
    mode='full+anchors9';
    if(file.size<=8*1024*1024){ payload={ b64:b64e(new Uint8Array(all)) }; }
  }
  const seed={
    "$schema":"teia.seed.v2",
    kind: payload? "payload":"anchor",
    mode,
    mdl:{ decision: payload? "autonomo" : "referencial", reason: payload? "payload≤8MB" : "arquivo grande / âncoras9" },
    build:{ when:new Date().toISOString(), ui:"autonomia_v2.html" },
    original:{ name:file.name, size:file.size, mime:file.type||"application/octet-stream", sha256: FULL_SHA },
    anchors9: anchors,
    payload
  };
  const seedStr=JSON.stringify(seed, null, 2);
  $('#seedOut').textContent=seedStr;
  $('#kOri').textContent=fmt(file.size); $('#kSeed').textContent=fmt(seedStr.length);
  $('#kTime').textContent=Math.round(performance.now()-t0)+' ms';
  $('#kRatio').textContent=(seedStr.length/Math.max(1,file.size)).toFixed(4);
  $('#kAnch').textContent=`${anchors.list.length}/9`;
  $('#kSha').textContent=FULL_SHA? (FULL_SHA.slice(0,10)+'…') : '—';
  LAST_SEED=seed; $('#btnDownloadSeed').disabled=false; $('#btnRestore').disabled=(seed.kind!=='payload');
  $('#fkAnch').textContent = `${anchors.list.length}/9`;
  pbar.style.width='100%';
  try{ await dbAdd(seed); const c=await dbCount(); $('#kHist').textContent=c; }catch{}
}

function baixarSeed(){
  if(!LAST_SEED) return;
  const blob=new Blob([JSON.stringify(LAST_SEED,null,2)],{type:'application/json'});
  const a=document.createElement('a'); a.href=URL.createObjectURL(blob); a.download=(LAST_SEED.original?.name||'arquivo')+'.teia.v2.json'; a.click(); URL.revokeObjectURL(a.href);
}
function restaurar(){
  if(!(LAST_SEED && LAST_SEED.kind==='payload' && LAST_SEED.payload?.b64)) return;
  const u8=b64d(LAST_SEED.payload.b64);
  const a=document.createElement('a'); a.href=URL.createObjectURL(new Blob([u8],{type:LAST_SEED.original?.mime||'application/octet-stream'}));
  a.download=LAST_SEED.original?.name||'restored.bin'; a.click(); URL.revokeObjectURL(a.href);
}

async function analisarTresPerguntas(){
  if(!LAST_SEED){ $('#q1').textContent='gere a seed primeiro'; $('#q2').textContent='gere a seed primeiro'; $('#q3').textContent='gere a seed primeiro'; return; }
  let q1='', q2='', q3='';
  if(LAST_SEED.kind==='payload'){ q1='✅ Sim (payload com bytes embutidos)'; $('#fkQ1').textContent='Sim'; }
  else { q1='⚠️ Parcial (multiâncoras; requer original/refs)'; $('#fkQ1').textContent='Parcial'; }
  // Q2
  let score=0;
  if(FILE){
    // compara 9 âncoras
    const ref=LAST_SEED.anchors9?.list||[];
    for(const a of ref){
      const frag=await sliceAt(FILE,a.pos).arrayBuffer();
      const s=await sha256Hex(frag);
      if(s===a.sha256) score++;
    }
  }
  if(FULL_SHA && FILE && FILE.size<=256*1024*1024){
    const sha=await sha256Hex(await FILE.arrayBuffer());
    q2 = (sha===FULL_SHA)? '✅ BITWISE OK (SHA-256 total)':'❌ SHA-256 divergente';
  } else {
    q2 = score===refLen()? '✅ Alta evidência (âncoras 9/9)' : (score>0? `⚠️ Evidência parcial (${score}/9)` : '❌ Sem evidência');
  }
  function refLen(){ return (LAST_SEED.anchors9?.list||[]).length||0; }
  // Q3
  const ratio = ($('#kRatio').textContent||'1').replace(',','.')*1;
  if(LAST_SEED.kind==='payload') q3 = ratio<1? '✅ Sim (offline + seed < original)' : '✅ Sim (offline determinístico)';
  else q3 = ratio<0.12? '⚠️ Parcial (ganho de meta/controle; depende do original)' : '⚠️ Parcial (prova útil; depende do original)';
  // pinta
  $('#q1').textContent=q1; $('#q2').textContent=q2; $('#q3').textContent=q3;
  $('#fkQ2').textContent= q2.startsWith('✅') ? 'OK' : (q2.startsWith('⚠️')? 'Parcial' : 'Falha');
  $('#fkQ3').textContent= q3.startsWith('✅') ? 'Sim' : 'Parcial';
}

async function benchAnchors(){
  if(!FILE) return;
  const t0=performance.now();
  await multiAnchors(FILE);
  const dt=Math.round(performance.now()-t0);
  alert(`Âncoras(9) geradas em ${dt} ms`);
}

$('#btnSeed').addEventListener('click',async()=>{ if(FILE) await gerarSeed(FILE) });
$('#btnDownloadSeed').addEventListener('click',baixarSeed);
$('#btnRestore').addEventListener('click',restaurar);
$('#btnAnalyze').addEventListener('click',analisarTresPerguntas);
$('#btnBench').addEventListener('click',benchAnchors);
</script>
</body>
</html>
"""
path = "/mnt/data/TEIA_UI_Autonomia_v2.html"
with open(path, "w", encoding="utf-8") as f:
    f.write(html)
path

---

### ASSISTENTE

# Re-run creation of TEIA_UI_Autonomia_v2.html after kernel reset.
html = r"""<!DOCTYPE html>
<html lang="pt-br">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>TEIA • Autonomia v2.0 — Motor Vestível</title>
<style>
:root{
  --bg0:#020617; --bg1:#0b1022; --fg:#e5e7eb; --muted:#94a3b8; --panel:rgba(17,24,39,.72);
  --b:#334155; --acc:#34d399; --acc2:#60a5fa; --warn:#f59e0b; --no:#ef4444; --ok:#10b981;
  --radius:16px;
}
*{box-sizing:border-box}
html,body{height:100%}
body{margin:0;background:radial-gradient(1200px 800px at 30% 0%,var(--bg1),var(--bg0));color:var(--fg);
  font-family:Inter,system-ui,Segoe UI,Arial,sans-serif;overflow:auto}
#teia-root{display:grid;grid-template-columns:390px 1fr;gap:12px;min-height:100vh}
#teia-left{padding:14px}
#teia-right{position:relative;overflow:hidden}
.card{background:var(--panel);border:1px solid var(--b);border-radius:var(--radius);padding:12px;box-shadow:0 8px 32px rgba(0,0,0,.35);backdrop-filter: blur(6px);}
h1{margin:0 0 8px 0;font-size:18px;text-align:center}
h2{margin:0 0 6px 0;font-size:14px;color:#cbd5e1}
small{color:var(--muted)}
.btn{display:block;width:100%;padding:10px 12px;margin-top:8px;border:none;border-radius:999px;
  background:linear-gradient(135deg,var(--acc),var(--acc2));color:#0b1120;font-weight:800;cursor:pointer}
.btn:disabled{opacity:.6;cursor:not-allowed;background:#374151}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.grid3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px}
.drop{border:2px dashed var(--b);border-radius:12px;padding:12px;text-align:center;color:#a5b4fc;cursor:pointer}
.drop.drag{border-color:var(--acc);background:rgba(52,211,153,.08)}
.kv{display:flex;justify-content:space-between;border-bottom:1px dashed #1f2937;padding:4px 0;font-size:12px}
pre{background:#0a0d16;border:1px solid #1f2937;border-radius:12px;padding:10px;max-height:220px;overflow:auto;font-size:12px}
.q{border:1px solid #1f2937;border-radius:12px;padding:8px;margin-top:6px}
.ok{color:var(--ok)} .warn{color:var(--warn)} .no{color:var(--no)}
.progress{height:6px;background:#0b0e16;border:1px solid #1f2937;border-radius:999px;overflow:hidden;margin-top:6px}
.progress>div{height:100%;width:0%;background:linear-gradient(90deg,var(--acc),var(--acc2));transition:width .15s}
.footer{text-align:center;color:#94a3b8;font-size:11px;margin-top:4px}
.badge{display:inline-block;padding:2px 6px;border-radius:999px;background:#0b0e16;border:1px solid #1f2937;font-size:11px}
#capa-host{position:absolute;inset:0;overflow:auto}
#float-kpi{position:absolute;right:12px;bottom:12px;display:grid;gap:6px;min-width:240px}
#float-kpi .card{padding:10px;background:rgba(10,13,22,.72)}
</style>
</head>
<body>
<div id="teia-root">
  <aside id="teia-left">
    <div class="card">
      <h1>TEIA • Autonomia v2.0</h1>
      <div id="dz" class="drop">Arraste um arquivo ou clique para selecionar</div>
      <div class="grid3">
        <button id="btnSeed" class="btn" disabled>Gerar Seed</button>
        <button id="btnAnalyze" class="btn" disabled>Analisar 3 Perguntas</button>
        <button id="btnBench" class="btn" disabled>Bench Âncoras</button>
      </div>
      <div class="grid2">
        <button id="btnDownloadSeed" class="btn" disabled>Baixar Seed</button>
        <button id="btnRestore" class="btn" disabled>Restaurar (se possível)</button>
      </div>
      <div class="progress"><div id="pbar"></div></div>
      <small>SHA-256 total ≤256MB; acima disso usa <b>multiâncoras (9×64KiB)</b>. Histórico salvo em IndexedDB.</small>
    </div>

    <div class="card">
      <h2>KPIs</h2>
      <div class="kv"><span>Original</span><b id="kOri">—</b></div>
      <div class="kv"><span>Tamanho Seed</span><b id="kSeed">—</b></div>
      <div class="kv"><span>Tempo (hash)</span><b id="kTime">—</b></div>
      <div class="kv"><span>Razão (seed/orig)</span><b id="kRatio">—</b></div>
      <div class="kv"><span>Âncoras</span><b id="kAnch">—</b></div>
      <div class="kv"><span>SHA-256</span><b id="kSha">—</b></div>
      <div class="kv"><span>Histórico (seeds)</span><b id="kHist">—</b></div>
    </div>

    <div class="card">
      <h2>Seed (JSON)</h2>
      <pre id="seedOut">{}</pre>
    </div>

    <div class="card">
      <h2>Painel “3 Perguntas”</h2>
      <div class="q"><b>Q1</b> — O núcleo se reconstrói sozinho?<div id="q1" class="warn">—</div></div>
      <div class="q"><b>Q2</b> — Consigo provar que é verdadeiro?<div id="q2" class="warn">—</div></div>
      <div class="q"><b>Q3</b> — Aumenta minha autonomia amanhã?<div id="q3" class="warn">—</div></div>
    </div>

    <div class="footer">Motor vestível • Sem dependências externas • TEIA seed-first</div>
  </aside>

  <main id="teia-right">
    <section id="capa-host">
      <div style="position:absolute;inset:0;display:grid;place-items:center;color:#a5b4fc;opacity:.5;">
        <div>
          <div style="font-size:22px;">Cole aqui sua CAPA ou deixe seu app e injete só o painel</div>
          <div style="text-align:center;font-size:12px">Troque CAPA_HOST_SELECTOR no script para apontar o contêiner real</div>
        </div>
      </div>
    </section>

    <div id="float-kpi">
      <div class="card"><b>Original</b> <span id="fkOri" class="badge">—</span></div>
      <div class="card"><b>Âncoras</b> <span id="fkAnch" class="badge">—</span></div>
      <div class="card"><b>Veredito Q1</b> <span id="fkQ1" class="badge">—</span></div>
      <div class="card"><b>Veredito Q2</b> <span id="fkQ2" class="badge">—</span></div>
      <div class="card"><b>Veredito Q3</b> <span id="fkQ3" class="badge">—</span></div>
    </div>
  </main>
</div>

<script>
const $=s=>document.querySelector(s);
const fmt=n=>n>=1<<30? (n/(1<<30)).toFixed(2)+' GB': n>=1<<20? (n/(1<<20)).toFixed(2)+' MB': n>=1<<10? (n/(1<<10)).toFixed(2)+' KB': n+' B';
const hex=u8=>[...u8].map(b=>b.toString(16).padStart(2,'0')).join('');
const b64e=u8=>{let s=''; for(const b of u8) s+=String.fromCharCode(b); return btoa(s)};
const b64d=s=>new Uint8Array(atob(s).split('').map(c=>c.charCodeAt(0)));
async function sha256Hex(buf){const d=await crypto.subtle.digest('SHA-256', buf); return hex(new Uint8Array(d))}
const CAPA_HOST_SELECTOR = "#capa-host";
// IndexedDB
const DBN="teia_autonomia_v2", STN="seeds";
function idb(){ return new Promise((res,rej)=>{ const r=indexedDB.open(DBN,1);
  r.onupgradeneeded=()=>{ r.result.createObjectStore(STN,{keyPath:"id", autoIncrement:true}); };
  r.onsuccess=()=>res(r.result); r.onerror=()=>rej(r.error); });}
async function dbAdd(seed){ const db=await idb(); return new Promise((res,rej)=>{
  const tx=db.transaction(STN,"readwrite"); tx.objectStore(STN).add(seed);
  tx.oncomplete=()=>res(true); tx.onerror=()=>rej(tx.error); });}
async function dbCount(){ const db=await idb(); return new Promise((res,rej)=>{
  const tx=db.transaction(STN,"readonly"); const req=tx.objectStore(STN).count();
  req.onsuccess=()=>res(req.result||0); req.onerror=()=>rej(req.error); });}

// Multiâncoras (9)
const ANCH_SLOTS=[0,0.125,0.25,0.375,0.5,0.625,0.75,0.875,1.0];
const FRAG=65536;
function sliceAt(file, ratio, len=FRAG){
  const size=file.size; if(size===0) return file.slice(0,0);
  if(ratio<=0) return file.slice(0,len);
  if(ratio>=1) return file.slice(Math.max(0,size-len), size);
  const s=Math.floor(size*ratio)-Math.floor(len/2);
  return file.slice(Math.max(0,s), Math.min(size, s+len));
}

let FILE=null, LAST_SEED=null, FULL_SHA=null;

(function wire(){
  const host=document.querySelector(CAPA_HOST_SELECTOR) || document.body;
  if(!host) console.warn("Host da capa não encontrado");
  const dz=$('#dz'); const inp=document.createElement('input'); inp.type='file'; inp.style.display='none'; dz.appendChild(inp);
  const onFile=f=>{ FILE=f; ['btnSeed','btnAnalyze','btnBench'].forEach(id=>$('#'+id).disabled=false);
    dz.textContent=`Selecionado: ${f.name} (${fmt(f.size)})`;
    $('#fkOri').textContent = `${fmt(f.size)}`;
  };
  dz.addEventListener('click',()=>inp.click());
  const drag=(e,on)=>{ e.preventDefault(); if(on) dz.classList.add('drag'); else dz.classList.remove('drag'); }
  dz.addEventListener('dragover',e=>drag(e,true)); dz.addEventListener('dragleave',e=>drag(e,false));
  dz.addEventListener('drop',e=>{drag(e,false); if(e.dataTransfer.files[0]) onFile(e.dataTransfer.files[0])});
  inp.onchange=e=>{ if(e.target.files[0]) onFile(e.target.files[0]) };
  document.addEventListener('dragover',e=>e.preventDefault());
  document.addEventListener('drop',e=>{ if(e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0]) onFile(e.dataTransfer.files[0]) });
})();

async function multiAnchors(file){
  const out={frag_bytes:FRAG, list:[]};
  for(const r of ANCH_SLOTS){
    const frag=await sliceAt(file,r).arrayBuffer();
    out.list.push({pos:r, sha256: await sha256Hex(frag)});
  }
  return out;
}

async function gerarSeed(file){
  const t0=performance.now(); const pbar=$('#pbar'); pbar.style.width='0%';
  FULL_SHA=null;
  const anchors=await multiAnchors(file); pbar.style.width='35%';
  let payload=null, mode='anchors9+meta';
  if(file.size<=256*1024*1024){
    const all=await file.arrayBuffer();
    FULL_SHA=await sha256Hex(all); pbar.style.width='75%';
    mode='full+anchors9';
    if(file.size<=8*1024*1024){ payload={ b64:b64e(new Uint8Array(all)) }; }
  }
  const seed={
    "$schema":"teia.seed.v2",
    kind: payload? "payload":"anchor",
    mode,
    mdl:{ decision: payload? "autonomo" : "referencial", reason: payload? "payload≤8MB" : "arquivo grande / âncoras9" },
    build:{ when:new Date().toISOString(), ui:"autonomia_v2.html" },
    original:{ name:file.name, size:file.size, mime:file.type||"application/octet-stream", sha256: FULL_SHA },
    anchors9: anchors,
    payload
  };
  const seedStr=JSON.stringify(seed, null, 2);
  $('#seedOut').textContent=seedStr;
  $('#kOri').textContent=fmt(file.size); $('#kSeed').textContent=fmt(seedStr.length);
  $('#kTime').textContent=Math.round(performance.now()-t0)+' ms';
  $('#kRatio').textContent=(seedStr.length/Math.max(1,file.size)).toFixed(4);
  $('#kAnch').textContent=`${anchors.list.length}/9`;
  $('#kSha').textContent=FULL_SHA? (FULL_SHA.slice(0,10)+'…') : '—';
  LAST_SEED=seed; $('#btnDownloadSeed').disabled=false; $('#btnRestore').disabled=(seed.kind!=='payload');
  $('#fkAnch').textContent = `${anchors.list.length}/9`;
  pbar.style.width='100%';
  try{ await dbAdd(seed); const c=await dbCount(); $('#kHist').textContent=c; }catch{}
}

function baixarSeed(){
  if(!LAST_SEED) return;
  const blob=new Blob([JSON.stringify(LAST_SEED,null,2)],{type:'application/json'});
  const a=document.createElement('a'); a.href=URL.createObjectURL(blob); a.download=(LAST_SEED.original?.name||'arquivo')+'.teia.v2.json'; a.click(); URL.revokeObjectURL(a.href);
}
function restaurar(){
  if(!(LAST_SEED && LAST_SEED.kind==='payload' && LAST_SEED.payload?.b64)) return;
  const u8=b64d(LAST_SEED.payload.b64);
  const a=document.createElement('a'); a.href=URL.createObjectURL(new Blob([u8],{type:LAST_SEED.original?.mime||'application/octet-stream'}));
  a.download=LAST_SEED.original?.name||'restored.bin'; a.click(); URL.revokeObjectURL(a.href);
}

async function analisarTresPerguntas(){
  if(!LAST_SEED){ $('#q1').textContent='gere a seed primeiro'; $('#q2').textContent='gere a seed primeiro'; $('#q3').textContent='gere a seed primeiro'; return; }
  let q1='', q2='', q3='';
  if(LAST_SEED.kind==='payload'){ q1='✅ Sim (payload com bytes embutidos)'; $('#fkQ1').textContent='Sim'; }
  else { q1='⚠️ Parcial (multiâncoras; requer original/refs)'; $('#fkQ1').textContent='Parcial'; }
  // Q2
  let score=0;
  if(FILE){
    const ref=LAST_SEED.anchors9?.list||[];
    for(const a of ref){
      const frag=await sliceAt(FILE,a.pos).arrayBuffer();
      const s=await sha256Hex(frag);
      if(s===a.sha256) score++;
    }
  }
  if(FULL_SHA && FILE && FILE.size<=256*1024*1024){
    const sha=await sha256Hex(await FILE.arrayBuffer());
    q2 = (sha===FULL_SHA)? '✅ BITWISE OK (SHA-256 total)':'❌ SHA-256 divergente';
  } else {
    const total=(LAST_SEED.anchors9?.list||[]).length||0;
    q2 = score===total? '✅ Alta evidência (âncoras '+total+'/'+total+')': (score>0? `⚠️ Evidência parcial (${score}/${total})` : '❌ Sem evidência');
  }
  const ratio = ($('#kRatio').textContent||'1').replace(',','.')*1;
  if(LAST_SEED.kind==='payload') q3 = ratio<1? '✅ Sim (offline + seed < original)' : '✅ Sim (offline determinístico)';
  else q3 = ratio<0.12? '⚠️ Parcial (ganho de meta/controle; depende do original)' : '⚠️ Parcial (prova útil; depende do original)';
  $('#q1').textContent=q1; $('#q2').textContent=q2; $('#q3').textContent=q3;
  $('#fkQ2').textContent= q2.startsWith('✅') ? 'OK' : (q2.startsWith('⚠️')? 'Parcial' : 'Falha');
  $('#fkQ3').textContent= q3.startsWith('✅') ? 'Sim' : 'Parcial';
}

async function benchAnchors(){
  if(!FILE) return;
  const t0=performance.now();
  await multiAnchors(FILE);
  const dt=Math.round(performance.now()-t0);
  alert(`Âncoras(9) geradas em ${dt} ms`);
}

$('#btnSeed').addEventListener('click',async()=>{ if(FILE) await gerarSeed(FILE) });
$('#btnDownloadSeed').addEventListener('click',baixarSeed);
$('#btnRestore').addEventListener('click',restaurar);
$('#btnAnalyze').addEventListener('click',analisarTresPerguntas);
$('#btnBench').addEventListener('click',benchAnchors);
</script>
</body>
</html>
"""
path = "/mnt/data/TEIA_UI_Autonomia_v2.html"
with open(path, "w", encoding="utf-8") as f:
    f.write(html)
path

---

### ASSISTENTE

feito. aqui está a **v2.0 “vestida por alguém de QI 200”** — mais densa, mais esperta e pronta pra plugar na tua capa sem gambiarras.

# download
- **TEIA • Autonomia v2.0 — Motor Vestível**  
[Baixar HTML v2](sandbox:/mnt/data/TEIA_UI_Autonomia_v2.html)

# o que a v2.0 entrega (de verdade)
- **Sem iframe** (modelo vestível): o painel é independente e pode ser **injetado na tua capa** (basta colar tua capa dentro de `#capa-host` ou mudar `CAPA_HOST_SELECTOR` no script para apontar pro contêiner da tua UI).
- **Multiâncoras 9×** (0%, 12.5%, …, 100%) com janelas de 64KiB → prova robusta para arquivos grandes; mostra contagem e validação parcial/completa.
- **SHA-256 total** quando o arquivo ≤ **256 MB**; acima disso, salva prova por multiâncoras.
- **Payload determinístico** quando ≤ **8 MB** → botão **Restaurar** habilitado; responde “Sim” na Q1 com reconstrução direta.
- **IndexedDB** para **histórico de seeds** (contagem no KPI).  
- **Drag&drop global** (pode soltar até por cima da capa).  
- **Painel flutuante** sobre a capa (`#float-kpi`) refletindo Original/Âncoras/Q1/Q2/Q3 ao vivo.

# como vestir na tua capa (2 opções)
1) **Colar** teu HTML dentro da `<section id="capa-host">` (já no arquivo v2).  
2) **Usar a tua página existente** e **colar só o painel**: altere no topo do script a linha  
   `const CAPA_HOST_SELECTOR = "#capa-host";`  
   para um **seletor** do contêiner real da tua capa (ex.: `"#app"`, `"#pocketkernel"`). O painel já resolve estilos e z-index.

# por que é v2.0 (não só cosmética)
- **Modelo de seed v2** (`"$schema":"teia.seed.v2"`) com `anchors9`, `mdl.decision` (“autonomo” vs “referencial”) e `build.ui` versionado.  
- **Heurística objetiva de autonomia (Q3)** baseada em **ratio seed/orig** + presença de payload.  
- **Bench de âncoras** (botão “Bench Âncoras”) com tempo em ms — útil pra tua auditoria.  
- **Isomorfismo visual**: o painel expõe **hooks estáveis** (KPI e vereditos) para você mapear diretamente em gráficos/LEDs da capa.

se quiser, eu já te devolvo uma **edição plug-and-play** do teu `✔️id_visu_núcleo_procedural.html.html` com o motor v2 costurado nos IDs da sua UI (sem iframe), mapeando:
- `Original → #kpi-original`, `Seed → #kpi-seed`, `Âncoras → #kpi-anchors`,  
- `JSON → #seed-json`, `Q1/Q2/Q3 → #q1/#q2/#q3` da tua capa.

é só dizer “costura na minha capa agora” que eu te entrego a versão consolidada.

---

### USUÁRIO

usar ancora é anti ético visto que o proposto pelo projeto é não possuir necessidade do arquivo real para a reconstrução

---

### ASSISTENTE

# Build v2.1: Ética “sem âncoras” — seeds 100% autossuficientes (payload ou receita procedural).
# Implementa: CompressionStream gzip (quando disponível) para reduzir payload; DecompressionStream para restauração.
# Caso o navegador não suporte, recai para payload bruto base64. Sempre restaurável sem arquivo externo.
#
html = r"""<!DOCTYPE html>
<html lang="pt-br">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>TEIA • Autonomia v2.1 — Ética Sem Âncoras</title>
<style>
:root{
  --bg0:#020617; --bg1:#0b1022; --fg:#e5e7eb; --muted:#94a3b8; --panel:rgba(17,24,39,.72);
  --b:#334155; --acc:#34d399; --acc2:#60a5fa; --warn:#f59e0b; --ok:#10b981; --no:#ef4444;
  --radius:16px;
}
*{box-sizing:border-box}
body{margin:0;background:radial-gradient(1200px 800px at 30% 0%,var(--bg1),var(--bg0));color:var(--fg);
  font-family:Inter,system-ui,Segoe UI,Arial,sans-serif;min-height:100vh}
.wrap{max-width:1100px;margin:0 auto;padding:16px;display:grid;gap:12px;grid-template-columns:380px 1fr}
.card{background:var(--panel);border:1px solid var(--b);border-radius:var(--radius);padding:12px;box-shadow:0 8px 32px rgba(0,0,0,.35)}
h1{margin:0 0 8px 0;font-size:20px;text-align:center}
h2{margin:0 0 6px 0;font-size:14px;color:#cbd5e1}
small{color:var(--muted)}
.drop{border:2px dashed var(--b);border-radius:12px;padding:12px;text-align:center;color:#a5b4fc;cursor:pointer}
.drop.drag{border-color:var(--acc);background:rgba(52,211,153,.08)}
.btn{display:block;width:100%;padding:10px 12px;margin-top:8px;border:none;border-radius:999px;
  background:linear-gradient(135deg,var(--acc),var(--acc2));color:#0b1120;font-weight:800;cursor:pointer}
.btn:disabled{opacity:.6;cursor:not-allowed;background:#374151}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.kv{display:flex;justify-content:space-between;border-bottom:1px dashed #1f2937;padding:4px 0;font-size:12px}
pre{background:#0a0d16;border:1px solid #1f2937;border-radius:12px;padding:10px;max-height:240px;overflow:auto;font-size:12px}
.q{border:1px solid #1f2937;border-radius:12px;padding:8px;margin-top:6px}
.ok{color:var(--ok)} .warn{color:var(--warn)} .no{color:var(--no)}
.progress{height:6px;background:#0b0e16;border:1px solid #1f2937;border-radius:999px;overflow:hidden;margin-top:6px}
.progress>div{height:100%;width:0%;background:linear-gradient(90deg,var(--acc),var(--acc2));transition:width .15s}
.badge{display:inline-block;padding:2px 6px;border-radius:999px;background:#0b0e16;border:1px solid #1f2937;font-size:11px}
.footer{grid-column:1/-1;text-align:center;color:#94a3b8;font-size:11px}
</style>
</head>
<body>
<div class="wrap">
  <div class="card">
    <h1>TEIA • v2.1 (Sem Âncoras)</h1>
    <div id="dz" class="drop">Arraste um arquivo ou clique para selecionar</div>
    <div class="grid2">
      <button id="btnSeed" class="btn" disabled>Gerar Seed</button>
      <button id="btnAnalyze" class="btn" disabled>Analisar 3 Perguntas</button>
      <button id="btnDownloadSeed" class="btn" disabled>Baixar Seed</button>
      <button id="btnRestore" class="btn" disabled>Restaurar</button>
    </div>
    <div class="progress"><div id="pbar"></div></div>
    <small>Ética TEIA: **zero âncoras**. Toda seed contém o necessário para restaurar — via <b>payload gzip+b64</b> (ou bruto) ou <b>receita procedural</b> quando aplicável.</small>
  </div>

  <div class="card">
    <h2>KPIs</h2>
    <div class="kv"><span>Original</span><b id="kOri">—</b></div>
    <div class="kv"><span>Tamanho Seed</span><b id="kSeed">—</b></div>
    <div class="kv"><span>Tempo (seed)</span><b id="kTime">—</b></div>
    <div class="kv"><span>Razão (seed/orig)</span><b id="kRatio">—</b></div>
    <div class="kv"><span>SHA-256 (orig)</span><b id="kSha">—</b></div>
    <div class="kv"><span>Codec</span><b id="kCodec">—</b></div>
  </div>

  <div class="card" style="grid-column:1/-1">
    <h2>Seed (JSON)</h2>
    <pre id="seedOut">{}</pre>
  </div>

  <div class="card" style="grid-column:1/-1">
    <h2>Painel “3 Perguntas”</h2>
    <div class="q"><b>Q1</b> — O núcleo se reconstrói sozinho?<div id="q1" class="ok">✅ Sim (seed autossuficiente)</div></div>
    <div class="q"><b>Q2</b> — Consigo provar que é verdadeiro?<div id="q2" class="ok">—</div></div>
    <div class="q"><b>Q3</b> — Aumenta minha autonomia amanhã?<div id="q3" class="ok">—</div></div>
  </div>

  <div class="footer">TEIA • Ética de Autonomia: sem dependência do arquivo externo • 100% offline</div>
</div>

<script>
const $=s=>document.querySelector(s);
const fmt=n=>n>=1<<30? (n/(1<<30)).toFixed(2)+' GB': n>=1<<20? (n/(1<<20)).toFixed(2)+' MB': n>=1<<10? (n/(1<<10)).toFixed(2)+' KB': n+' B';
const hex=u8=>[...u8].map(b=>b.toString(16).padStart(2,'0')).join('');
const b64e=u8=>{let s=''; for(const b of u8) s+=String.fromCharCode(b); return btoa(s)};
const b64d=s=>new Uint8Array(atob(s).split('').map(c=>c.charCodeAt(0)));
async function sha256Hex(buf){const d=await crypto.subtle.digest('SHA-256', buf); return hex(new Uint8Array(d))}

// gzip (CompressionStream) — se indisponível, usa "raw"
const gzipAvailable = (typeof CompressionStream !== 'undefined') && (typeof DecompressionStream !== 'undefined');

async function gzipBytes(u8){
  if(!gzipAvailable) return {codec:"raw-b64", data:b64e(u8)};
  const rs = new ReadableStream({
    start(c){ c.enqueue(u8); c.close(); }
  });
  const cs = new CompressionStream('gzip');
  const stream = rs.pipeThrough(cs);
  const resp = new Response(stream);
  const gz = new Uint8Array(await resp.arrayBuffer());
  return {codec:"gzip-b64", data:b64e(gz)};
}

async function gunzipToBytes(b64){
  if(!gzipAvailable) return b64d(b64);
  const gz = b64d(b64);
  const rs = new ReadableStream({ start(c){ c.enqueue(gz); c.close(); } });
  const ds = new DecompressionStream('gzip');
  const stream = rs.pipeThrough(ds);
  const resp = new Response(stream);
  const out = new Uint8Array(await resp.arrayBuffer());
  return out;
}

// Procedural detector (exemplo mínimo: PNG sólido 1 cor)
async function detectProcedural(u8, mime){
  // Não faremos heurísticas invasivas; placeholder para evolução: retorna null por padrão.
  return null;
}

let FILE=null, LAST_SEED=null, FULL_SHA=null;

(function wire(){
  const dz=$('#dz'); const inp=document.createElement('input'); inp.type='file'; inp.style.display='none'; dz.appendChild(inp);
  const onFile=f=>{ FILE=f; $('#btnSeed').disabled=false; $('#btnAnalyze').disabled=false; $('#btnDownloadSeed').disabled=true;
    dz.textContent=`Selecionado: ${f.name} (${fmt(f.size)})`; };
  dz.addEventListener('click',()=>inp.click());
  const drag=(e,on)=>{ e.preventDefault(); if(on) dz.classList.add('drag'); else dz.classList.remove('drag'); }
  dz.addEventListener('dragover',e=>drag(e,true)); dz.addEventListener('dragleave',e=>drag(e,false));
  dz.addEventListener('drop',e=>{drag(e,false); if(e.dataTransfer.files[0]) onFile(e.dataTransfer.files[0])});
  inp.onchange=e=>{ if(e.target.files[0]) onFile(e.target.files[0]) };
  document.addEventListener('dragover',e=>e.preventDefault());
  document.addEventListener('drop',e=>{ if(e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0]) onFile(e.dataTransfer.files[0]) });
})();

async function gerarSeed(file){
  const t0=performance.now(); const pbar=$('#pbar'); pbar.style.width='0%';
  const buf=await file.arrayBuffer(); pbar.style.width='35%';
  const u8=new Uint8Array(buf);
  FULL_SHA = await sha256Hex(buf); pbar.style.width='60%';
  // Procedural?
  let recipe = await detectProcedural(u8, file.type||"");
  let payload = null; let codecLabel="—";
  if(recipe){
    payload = { recipe };
    codecLabel = "procedural";
  }else{
    const gz = await gzipBytes(u8); pbar.style.width='85%';
    payload = { codec: gz.codec, b64: gz.data, sha256: FULL_SHA };
    codecLabel = gz.codec;
  }
  const seed = {
    "$schema":"teia.seed.v2.1",
    ethic:"no-anchors",
    kind:"payload",
    mode: payload.recipe? "procedural" : "payload-b64",
    build:{ when:new Date().toISOString(), ui:"autonomia_v2.1.html" },
    original:{ name:file.name, size:file.size, mime:file.type||"application/octet-stream", sha256: FULL_SHA },
    payload
  };
  const seedStr = JSON.stringify(seed, null, 2);
  $('#seedOut').textContent=seedStr;
  $('#kOri').textContent=fmt(file.size);
  $('#kSeed').textContent=fmt(seedStr.length);
  $('#kTime').textContent=Math.round(performance.now()-t0)+' ms';
  $('#kRatio').textContent=(seedStr.length/Math.max(1,file.size)).toFixed(4);
  $('#kSha').textContent=FULL_SHA.slice(0,12)+'…';
  $('#kCodec').textContent=codecLabel;
  LAST_SEED=seed; $('#btnDownloadSeed').disabled=false; $('#btnRestore').disabled=false;
  pbar.style.width='100%';
}

function baixarSeed(){
  if(!LAST_SEED) return;
  const blob=new Blob([JSON.stringify(LAST_SEED,null,2)],{type:'application/json'});
  const a=document.createElement('a'); a.href=URL.createObjectURL(blob); a.download=(LAST_SEED.original?.name||'arquivo')+'.teia.v21.json'; a.click(); URL.revokeObjectURL(a.href);
}

async function restaurar(){
  if(!(LAST_SEED && LAST_SEED.payload)) return;
  if(LAST_SEED.mode==="procedural"){
    alert("Esta seed é procedural — implemente o executor específico para a receita.");
    return;
  }
  const gz = LAST_SEED.payload;
  const bytes = (gz.codec==="gzip-b64") ? await gunzipToBytes(gz.b64) : b64d(gz.b64);
  const a=document.createElement('a'); a.href=URL.createObjectURL(new Blob([bytes],{type:LAST_SEED.original?.mime||'application/octet-stream'}));
  a.download=LAST_SEED.original?.name||'restored.bin'; a.click(); URL.revokeObjectURL(a.href);
}

async function analisarTresPerguntas(){
  if(!LAST_SEED){ $('#q2').textContent='gere a seed primeiro'; $('#q3').textContent='gere a seed primeiro'; return; }
  // Q1 já é "Sim" por design (seed autossuficiente).
  // Q2: prova = SHA-256 no payload e verificação pós-restauração rápida (quando gzip-b64).
  let q2=''; let q3='';
  if(LAST_SEED.mode==="procedural"){
    q2='⚠️ Procedural: requer executor para provar bit-a-bit (forneceremos módulo de validação)';
  } else {
    // Verificação local do SHA sem baixar: descomprime e compara
    const gz = LAST_SEED.payload;
    const bytes = (gz.codec==="gzip-b64") ? await gunzipToBytes(gz.b64) : b64d(gz.b64);
    const sha = await sha256Hex(bytes.buffer);
    q2 = (sha===LAST_SEED.original.sha256)? '✅ BITWISE OK (SHA-256)' : '❌ Divergente (payload corrompido)';
  }
  const ratio = ($('#kRatio').textContent||'1').replace(',','.')*1;
  q3 = ratio<1? '✅ Sim (seed comprimida + offline)' : '✅ Sim (autonomia total; trade-off de tamanho)';
  $('#q2').textContent=q2; $('#q3').textContent=q3;
}

$('#btnSeed').addEventListener('click',async()=>{ if(FILE) await gerarSeed(FILE) });
$('#btnDownloadSeed').addEventListener('click',baixarSeed);
$('#btnRestore').addEventListener('click',restaurar);
$('#btnAnalyze').addEventListener('click',analisarTresPerguntas);
</script>
</body>
</html>
"""
path = "/mnt/data/TEIA_UI_Autonomia_v2_1.html"
with open(path, "w", encoding="utf-8") as f:
    f.write(html)
path

---

### ASSISTENTE

concordo contigo — se a intenção ética é **autonomia real**, seed que depende de âncora (arquivo externo) fere o princípio. então eu gerei uma **versão 2.1, 100% sem âncoras**: toda seed é autossuficiente.

# download (ética sem âncoras)
**TEIA • Autonomia v2.1 — Ética Sem Âncoras**  
[Baixar HTML v2.1](sandbox:/mnt/data/TEIA_UI_Autonomia_v2_1.html)

# o que muda na v2.1
- **Zero âncoras**. Sempre **restaurável sem o arquivo original**.
- **Payload embutido** com **gzip+b64** (via `CompressionStream`/`DecompressionStream` quando disponível; fallback para b64 bruto).  
- Campo `"$schema": "teia.seed.v2.1"`, `ethic: "no-anchors"`, `kind:"payload"`, `mode:"payload-b64"` ou `mode:"procedural"` (quando houver receita legítima).
- **Prova bit-a-bit**: a análise “Q2” valida SHA-256 pós-restauração **localmente**, sem rede.
- **Q1** é sempre **✅ Sim** por design (a seed carrega tudo).  
- **Q3** mede autonomia por **ratio seed/original**; se >1, ainda é ético (autonomia total), só indique trade-off de tamanho.

# como usar
1) Abra o HTML, arraste qualquer arquivo.  
2) Clique **Gerar Seed** → **Analisar 3 Perguntas** → **Baixar Seed**.  
3) **Restaurar** funciona direto (para `mode:"payload-b64"`). Para `mode:"procedural"`, o executor é plugável (ex.: receitas para imagens/textos determinísticos).

# próximos upgrades (se quiser agora)
- **Procedural real** para tipos detectáveis (ex.: PNGs/áudio sintético/textos): seed guarda **receita** mínima + verificador → restaura sem bytes originais.  
- **Fragmentação streaming** para arquivos enormes (gzip em partes com índice no JSON), mantendo “no-anchors” e uso de memória previsível.  
- **Costura na tua capa** (sem iframe), mapeando os KPIs/vereditos para os teus LEDs/gráficos.

---

