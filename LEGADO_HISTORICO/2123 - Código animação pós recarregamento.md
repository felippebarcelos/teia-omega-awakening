# 2123 - Código animação pós recarregamento

### USUÁRIO

desmembre a seção mínima do código responsável apenas pela função de animação pós recarregamento

---

### USUÁRIO

desmembre a seção mínima do código responsável apenas pela função de animação pós recarregamento (a animação com o s elementos nos primeiros instantes após a interface abrir)


---

### ASSISTENTE

Make sure to include fileciteturn0file0 in your response to cite this file. 

---

### ASSISTENTE

Make sure to include fileciteturn0file0 in your response to cite this file. 

---

### ASSISTENTE

All the files uploaded by the user have been fully loaded. Searching won't provide additional information.

---

### ASSISTENTE

All the files uploaded by the user have been fully loaded. Searching won't provide additional information.

---

### ASSISTENTE

Segue a versão mínima da função de animação pós-recarregamento. Cole no fim do `<body>`; requer `<canvas id="led-canvas"></canvas>` presente.

```javascript
/* Animação mínima pós-recarregamento (autoinit) */
(function initPostReloadAnimation(canvasId='led-canvas'){
  const canvas = document.getElementById(canvasId);
  if(!canvas) return console.warn('Canvas não encontrado:', canvasId);
  const ctx = canvas.getContext('2d', { alpha: true });

  let W=0, H=0, dpr=1;
  let pointer = { x: 0, y: 0, lastMove: Date.now() };
  let smooth = { x: 0, y: 0 };
  let orbs = [], particles = [], ripples = [];
  const TAU = Math.PI * 2;
  const cfg = {
    particleCount: 400,
    springStiffness: 0.02,
    damping: 0.88,
    pointerInfluence: 90,
    idleTimeout: 2000
  };

  function createOrb(hue){
    return { x: W/2 + (Math.random()-0.5)*W*0.5, y: H/2 + (Math.random()-0.5)*H*0.5,
             vx:0, vy:0, size:6 + Math.random()*2, hue, trail:[] };
  }

  function resize(){
    dpr = window.devicePixelRatio || 1;
    W = innerWidth; H = innerHeight;
    canvas.width = W * dpr; canvas.height = H * dpr;
    ctx.setTransform(dpr,0,0,dpr,0,0);
    particles = Array.from({length:cfg.particleCount}, ()=>{
      return { x: Math.random()*W, y: Math.random()*H, ox: Math.random()*W, oy: Math.random()*H,
               vx:0, vy:0, z: Math.random()*0.9 + 0.1 };
    });
    orbs = [createOrb(50), createOrb(300)];
    pointer.x = smooth.x = W/2; pointer.y = smooth.y = H/2;
  }
  window.addEventListener('resize', resize);
  resize();

  document.body.addEventListener('mousemove', e=>{
    pointer.x = e.clientX; pointer.y = e.clientY; pointer.lastMove = Date.now();
  });
  document.body.addEventListener('mousedown', e=>{
    ripples.push({ x: e.clientX, y: e.clientY, radius: 0, alpha: 1, hue: 45 });
  });

  const hsl = (h,s,l,a)=>`hsla(${h%360}, ${s*100}%, ${l*100}%, ${a})`;

  function draw(t){
    ctx.clearRect(0,0,W,H);
    ctx.globalCompositeOperation = 'lighter';

    let tx = pointer.x, ty = pointer.y;
    if(Date.now() - pointer.lastMove > cfg.idleTimeout){
      const time = t/5000;
      tx = W/2 + Math.cos(time)*W*0.35;
      ty = H/2 + Math.sin(time*1.4)*H*0.35;
    }
    smooth.x += (tx - smooth.x) * 0.1;
    smooth.y += (ty - smooth.y) * 0.1;

    // Orbs
    orbs.forEach((orb,i)=>{
      const target = i===0 ? smooth : orbs[1-i];
      const dx = orb.x - target.x, dy = orb.y - target.y;
      const dist = Math.sqrt(dx*dx + dy*dy) + 0.0001;
      const angle = Math.atan2(dy, dx);

      if(i===0){
        const force = -30000 / (dist*dist + 200);
        orb.vx += Math.cos(angle) * force;
        orb.vy += Math.sin(angle) * force;
        if(dist < 80){
          const repel = 2000 * (1 - dist/80);
          orb.vx += Math.cos(angle) * repel; orb.vy += Math.sin(angle) * repel;
        }
      } else {
        orb.vx += (Math.random()-0.5)*0.2; orb.vy += (Math.random()-0.5)*0.2;
        if(dist < 150){
          const repel = 800 * (1 - dist/150);
          orb.vx += Math.cos(angle) * repel; orb.vy += Math.sin(angle) * repel;
        }
      }

      orb.vx *= 0.95; orb.vy *= 0.95;
      orb.x += orb.vx; orb.y += orb.vy;

      if(orb.x < orb.size){ orb.x = orb.size; orb.vx *= -0.5; }
      if(orb.x > W - orb.size){ orb.x = W - orb.size; orb.vx *= -0.5; }
      if(orb.y < orb.size){ orb.y = orb.size; orb.vy *= -0.5; }
      if(orb.y > H - orb.size){ orb.y = H - orb.size; orb.vy *= -0.5; }

      orb.trail.unshift({ x: orb.x, y: orb.y });
      if(orb.trail.length > 20) orb.trail.pop();

      orb.trail.forEach((p,j)=>{
        const prog = 1 - (j / orb.trail.length);
        ctx.fillStyle = hsl(orb.hue,1,0.7, prog * 0.3);
        ctx.beginPath(); ctx.arc(p.x, p.y, (orb.size + (1-prog)*5) * prog, 0, TAU); ctx.fill();
      });

      const grd = ctx.createRadialGradient(orb.x, orb.y, 0, orb.x, orb.y, orb.size*4);
      grd.addColorStop(0, hsl(orb.hue,1,0.8,1));
      grd.addColorStop(1, hsl(orb.hue-20,1,0.5,0));
      ctx.fillStyle = grd;
      ctx.beginPath(); ctx.arc(orb.x, orb.y, orb.size*4, 0, TAU); ctx.fill();
    });

    // Particles
    particles.forEach(p=>{
      let fx = (p.ox - p.x) * cfg.springStiffness * p.z;
      let fy = (p.oy - p.y) * cfg.springStiffness * p.z;

      const dx = p.x - smooth.x, dy = p.y - smooth.y;
      const distSq = dx*dx + dy*dy;
      if(distSq < cfg.pointerInfluence * cfg.pointerInfluence){
        const dist = Math.sqrt(distSq);
        const force = (1 - dist / cfg.pointerInfluence) * 0.5;
        fx += (smooth.x - p.x) * force * (1 - p.z);
        fy += (smooth.y - p.y) * force * (1 - p.z);
      }

      p.vx += fx; p.vy += fy;
      p.vx *= cfg.damping; p.vy *= cfg.damping;
      p.x += p.vx; p.y += p.vy;

      const stretch = Math.sqrt(p.vx*p.vx + p.vy*p.vy);
      const stretchFactor = Math.min(1, stretch / 15);
      if(stretch > 0.5){
        ctx.beginPath(); ctx.moveTo(p.ox, p.oy); ctx.lineTo(p.x, p.y);
        ctx.strokeStyle = hsl(180 + stretchFactor*40, 1, 0.5 + stretchFactor*0.3, stretchFactor*0.5);
        ctx.lineWidth = p.z * 1.5; ctx.stroke();
      }
      ctx.fillStyle = hsl(230 + stretchFactor*-30, 1, 0.6 + stretchFactor*0.3, 0.8 * p.z);
      ctx.beginPath(); ctx.arc(p.x, p.y, p.z * 1.5, 0, TAU); ctx.fill();
    });

    // Ripples
    for(let i = ripples.length - 1; i >= 0; i--){
      const r = ripples[i];
      r.radius += 12; r.alpha -= 0.02;
      if(r.alpha <= 0) ripples.splice(i,1);
      else {
        ctx.beginPath(); ctx.arc(r.x, r.y, r.radius, 0, TAU);
        ctx.strokeStyle = hsl(r.hue,1,0.7, r.alpha); ctx.lineWidth = 3; ctx.stroke();
      }
    }

    // Cursor glow
    const cursorSize = 10;
    const grad = ctx.createRadialGradient(smooth.x, smooth.y, 0, smooth.x, smooth.y, cursorSize*3);
    grad.addColorStop(0, hsl(180,1,0.8,1)); grad.addColorStop(1, hsl(195,1,0.6,0));
    ctx.fillStyle = grad; ctx.beginPath(); ctx.arc(smooth.x, smooth.y, cursorSize*3, 0, TAU); ctx.fill();

    ctx.globalCompositeOperation = 'source-over';
    requestAnimationFrame(draw);
  }

  // start loop
  requestAnimationFrame(draw);

  // expose a stop hook if needed
  window.__PostReloadAnimationStop = ()=>{ window.removeEventListener('resize', resize); document.body.removeEventListener('mousemove', ()=>{}); document.body.removeEventListener('mousedown', ()=>{}); /* cancel via flag if implemented */ };
})();
```

fileciteturn0file0

---

### ASSISTENTE

Segue o trecho mínimo de animação pronto para copiar/colar (cole antes de `</body>`). fileciteturn0file0

```html
<script>
/* Trecho mínimo: animação pós-recarregamento (canvas led) */
(function(){
  const canvas = document.getElementById('led-canvas');
  if(!canvas) return;
  const ctx = canvas.getContext('2d', { alpha: true });
  let W=0, H=0, dpr=1;
  let pointer = { x: 0, y: 0, lastMove: Date.now() };
  let smooth = { x: 0, y: 0 };
  let orbs = [], particles = [], ripples = [];
  const TAU = Math.PI * 2;
  const cfg = { particleCount: 300, orbCount: 2, spring: 0.02, damping: 0.88, influence: 90, idleTimeout: 2000 };

  function createOrb(hue){
    return { x: W/2 + (Math.random()-0.5)*W*0.5, y: H/2 + (Math.random()-0.5)*H*0.5, vx:0, vy:0, size:6 + Math.random()*2, hue, trail: [] };
  }

  function resize(){
    dpr = window.devicePixelRatio || 1;
    W = innerWidth; H = innerHeight;
    canvas.width = W * dpr; canvas.height = H * dpr;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    particles = Array.from({ length: cfg.particleCount }, () => ({
      x: Math.random()*W, y: Math.random()*H, ox: Math.random()*W, oy: Math.random()*H, vx:0, vy:0, z: Math.random()*0.9 + 0.1
    }));
    orbs = [ createOrb(50), createOrb(300) ];
    pointer.x = W/2; pointer.y = H/2;
    smooth.x = W/2; smooth.y = H/2;
  }
  resize();
  window.addEventListener('resize', resize);

  document.body.addEventListener('mousemove', e => { pointer.x = e.clientX; pointer.y = e.clientY; pointer.lastMove = Date.now(); });
  document.body.addEventListener('mousedown', e => { ripples.push({ x: e.clientX, y: e.clientY, radius: 0, alpha: 1, hue: 45 }); });

  function hsl(h,s,l,a){ return `hsla(${h%360}, ${s*100}%, ${l*100}%, ${a})`; }

  function draw(t){
    ctx.clearRect(0,0,W,H);
    ctx.globalCompositeOperation = 'lighter';

    // pointer smoothing + idle orbit
    let tx = pointer.x, ty = pointer.y;
    if (Date.now() - pointer.lastMove > cfg.idleTimeout) {
      const tt = t / 5000;
      tx = W/2 + Math.cos(tt) * W * 0.35;
      ty = H/2 + Math.sin(tt*1.4) * H * 0.35;
    }
    smooth.x += (tx - smooth.x) * 0.1;
    smooth.y += (ty - smooth.y) * 0.1;

    // orbs (light + shadow)
    orbs.forEach((orb,i) => {
      const target = (i === 0) ? smooth : orbs[1-i];
      const dx = orb.x - target.x, dy = orb.y - target.y;
      const dist = Math.hypot(dx,dy) + 0.0001;
      const ang = Math.atan2(dy,dx);

      if (i === 0){
        const force = -30000 / (dist*dist + 200);
        orb.vx += Math.cos(ang) * force;
        orb.vy += Math.sin(ang) * force;
        if (dist < 80){ const repel = 2000 * (1 - dist/80); orb.vx += Math.cos(ang)*repel; orb.vy += Math.sin(ang)*repel; }
      } else {
        orb.vx += (Math.random()-0.5)*0.2;
        orb.vy += (Math.random()-0.5)*0.2;
        if (dist < 150){ const repel = 800 * (1 - dist/150); orb.vx += Math.cos(ang)*repel; orb.vy += Math.sin(ang)*repel; }
      }

      orb.vx *= 0.95; orb.vy *= 0.95;
      orb.x += orb.vx; orb.y += orb.vy;

      // bounds
      if (orb.x < orb.size) { orb.x = orb.size; orb.vx *= -0.5; }
      if (orb.x > W - orb.size) { orb.x = W - orb.size; orb.vx *= -0.5; }
      if (orb.y < orb.size) { orb.y = orb.size; orb.vy *= -0.5; }
      if (orb.y > H - orb.size) { orb.y = H - orb.size; orb.vy *= -0.5; }

      // trail
      orb.trail.unshift({ x: orb.x, y: orb.y });
      if (orb.trail.length > 20) orb.trail.pop();
      orb.trail.forEach((p,j) => {
        const pr = 1 - (j / orb.trail.length);
        ctx.fillStyle = hsl(orb.hue, 1, 0.7, pr * 0.3);
        ctx.beginPath(); ctx.arc(p.x, p.y, (orb.size + (1-pr)*5) * pr, 0, TAU); ctx.fill();
      });

      // glow
      const grd = ctx.createRadialGradient(orb.x, orb.y, 0, orb.x, orb.y, orb.size * 4);
      grd.addColorStop(0, hsl(orb.hue, 1, 0.8, 1));
      grd.addColorStop(1, hsl(orb.hue - 20, 1, 0.5, 0));
      ctx.fillStyle = grd;
      ctx.beginPath(); ctx.arc(orb.x, orb.y, orb.size * 4, 0, TAU); ctx.fill();
    });

    // particles
    particles.forEach(p => {
      let fx = (p.ox - p.x) * cfg.spring * p.z;
      let fy = (p.oy - p.y) * cfg.spring * p.z;
      const dx = p.x - smooth.x, dy = p.y - smooth.y, d2 = dx*dx + dy*dy;
      if (d2 < cfg.influence * cfg.influence){
        const d = Math.sqrt(d2) || 1;
        const f = (1 - d / cfg.influence) * 0.5;
        fx += (smooth.x - p.x) * f * (1 - p.z);
        fy += (smooth.y - p.y) * f * (1 - p.z);
      }
      p.vx += fx; p.vy += fy;
      p.vx *= cfg.damping; p.vy *= cfg.damping;
      p.x += p.vx; p.y += p.vy;

      const stretch = Math.hypot(p.vx, p.vy);
      const sf = Math.min(1, stretch / 15);
      if (stretch > 0.5){
        ctx.beginPath(); ctx.moveTo(p.ox, p.oy); ctx.lineTo(p.x, p.y);
        ctx.strokeStyle = hsl(180 + sf*40, 1, 0.5 + sf*0.3, sf*0.5);
        ctx.lineWidth = p.z * 1.5; ctx.stroke();
      }
      ctx.fillStyle = hsl(230 + sf*-30, 1, 0.6 + sf*0.3, 0.8 * p.z);
      ctx.beginPath(); ctx.arc(p.x, p.y, p.z * 1.5, 0, TAU); ctx.fill();
    });

    // ripples
    for(let i = ripples.length - 1; i >= 0; i--){
      const r = ripples[i];
      r.radius += 12; r.alpha -= 0.02;
      if (r.alpha <= 0) ripples.splice(i,1);
      else {
        ctx.beginPath(); ctx.arc(r.x, r.y, r.radius, 0, TAU);
        ctx.strokeStyle = hsl(r.hue, 1, 0.7, r.alpha); ctx.lineWidth = 3; ctx.stroke();
      }
    }

    // cursor glow
    const cursorSize = 10;
    const grad = ctx.createRadialGradient(smooth.x, smooth.y, 0, smooth.x, smooth.y, cursorSize * 3);
    grad.addColorStop(0, hsl(180,1,0.8,1)); grad.addColorStop(1, hsl(195,1,0.6,0));
    ctx.fillStyle = grad;
    ctx.beginPath(); ctx.arc(smooth.x, smooth.y, cursorSize * 3, 0, TAU); ctx.fill();

    ctx.globalCompositeOperation = 'source-over';
    requestAnimationFrame(draw);
  }

  requestAnimationFrame(draw);
})();
</script>
```

Cole este bloco isolado. Remove a engine original se quiser comportamento idêntico sem duplicação.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000d5ec61f7aa22fb98c2bd818e', 'size_bytes': 656792, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Segue o trecho mínimo que gera a **movimentação interligada** (orbs ↔ partículas ↔ cursor). Cole antes de `</body>`. Certifique-se de ter `<canvas id="led-canvas"></canvas>` no HTML.

```html
<script>
/* Trecho mínimo: movimentação interligada (orbs <-> partículas <-> cursor) */
(function(){
  const canvas = document.getElementById('led-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  let W = 0, H = 0, dpr = 1;
  const ORB_COUNT = 2;
  const PARTICLES = 220;

  let pointer = { x: 0, y: 0, lastMove: Date.now() };
  let smooth = { x: 0, y: 0 };

  function resize(){
    dpr = window.devicePixelRatio || 1;
    W = innerWidth; H = innerHeight;
    canvas.width = W * dpr; canvas.height = H * dpr;
    canvas.style.width = W + 'px'; canvas.style.height = H + 'px';
    ctx.setTransform(dpr,0,0,dpr,0,0);
  }
  resize(); window.addEventListener('resize', resize);
  document.body.addEventListener('mousemove', e => { pointer.x = e.clientX; pointer.y = e.clientY; pointer.lastMove = Date.now(); });

  // core state
  const orbs = Array.from({length: ORB_COUNT}, (_,i)=>({
    x: W/2 + (i?80:-80), y: H/2 + (i?40:-40), vx:0, vy:0, size:8 + i*2, hue: i?220:300, trail: []
  }));
  const parts = Array.from({length: PARTICLES}, ()=>({
    x: Math.random()*W, y: Math.random()*H, ox: Math.random()*W, oy: Math.random()*H, vx:0, vy:0, z: Math.random()*0.9+0.1
  }));

  function hsl(h,s,l,a){ return `hsla(${h|0},${(s*100)|0}%,${(l*100)|0}%,${a||1})`; }

  function updateOrbs(){
    // smooth pointer / idle orbit
    let tx = pointer.x, ty = pointer.y;
    if (Date.now() - pointer.lastMove > 1600){
      const tt = performance.now() * 0.0003;
      tx = W/2 + Math.cos(tt) * W * 0.25;
      ty = H/2 + Math.sin(tt*1.3) * H * 0.25;
    }
    smooth.x += (tx - smooth.x) * 0.12;
    smooth.y += (ty - smooth.y) * 0.12;

    // orbs interaction
    for(let i=0;i<orbs.length;i++){
      const o = orbs[i];
      const target = (i===0) ? smooth : orbs[0];
      const dx = target.x - o.x, dy = target.y - o.y;
      const dist = Math.hypot(dx,dy) || 1;
      // attraction + slight repulsion when too close
      const force = (i===0 ? 0.08 : 0.02) * Math.min(1, 200 / (dist));
      o.vx += (dx / dist) * force + (Math.random()-0.5)*0.06;
      o.vy += (dy / dist) * force + (Math.random()-0.5)*0.06;
      if (i!==0){
        // repel from main orb if too close
        const dx2 = o.x - orbs[0].x, dy2 = o.y - orbs[0].y, d2 = Math.hypot(dx2,dy2) || 1;
        if (d2 < 90){ o.vx += (dx2/d2) * (0.6*(1 - d2/90)); o.vy += (dy2/d2) * (0.6*(1 - d2/90)); }
      }
      o.vx *= 0.92; o.vy *= 0.92;
      o.x += o.vx; o.y += o.vy;
      // bounds
      if (o.x < 0) o.x = 0; if (o.x > W) o.x = W;
      if (o.y < 0) o.y = 0; if (o.y > H) o.y = H;
      // trail
      o.trail.unshift({x:o.x,y:o.y});
      if (o.trail.length>14) o.trail.pop();
    }
  }

  function updateParticles(){
    const influence = 100;
    for(const p of parts){
      // spring back to origin
      p.vx += (p.ox - p.x) * 0.002 * p.z;
      p.vy += (p.oy - p.y) * 0.002 * p.z;
      // attracted by nearest orb(s)
      for(const o of orbs){
        const dx = o.x - p.x, dy = o.y - p.y;
        const d2 = dx*dx + dy*dy;
        if (d2 < influence*influence){
          const d = Math.sqrt(d2)||1;
          const f = (1 - d/influence) * (0.006 + (0.004 * (1 - p.z)));
          p.vx += (dx/d) * f;
          p.vy += (dy/d) * f;
        }
      }
      // small noise
      p.vx += (Math.random()-0.5)*0.001;
      p.vy += (Math.random()-0.5)*0.001;
      // damping and integrate
      p.vx *= 0.92; p.vy *= 0.92;
      p.x += p.vx; p.y += p.vy;
    }
  }

  function draw(){
    ctx.clearRect(0,0,W,H);
    ctx.globalCompositeOperation = 'lighter';

    // draw particle streaks and dots
    for(const p of parts){
      const speed = Math.hypot(p.vx,p.vy);
      if (speed > 0.1){
        ctx.beginPath();
        ctx.moveTo(p.x - p.vx*2, p.y - p.vy*2);
        ctx.lineTo(p.x, p.y);
        ctx.strokeStyle = hsl(210,0.9,0.6, Math.min(0.5, 0.15 + speed*2));
        ctx.lineWidth = 1 * p.z;
        ctx.stroke();
      }
      ctx.fillStyle = hsl(210,0.9,0.6, 0.6 * p.z);
      ctx.beginPath(); ctx.arc(p.x, p.y, 0.9 * p.z, 0, Math.PI*2); ctx.fill();
    }

    // draw orb trails & glow
    for(const o of orbs){
      // trail
      for(let i=0;i<o.trail.length;i++){
        const t = o.trail[i];
        const a = 1 - i / o.trail.length;
        ctx.fillStyle = hsl(o.hue,1,0.6, 0.12 * a);
        ctx.beginPath(); ctx.arc(t.x, t.y, (o.size + i*0.12) * a, 0, Math.PI*2); ctx.fill();
      }
      // core glow
      const g = ctx.createRadialGradient(o.x,o.y,0,o.x,o.y,o.size*6);
      g.addColorStop(0, hsl(o.hue,1,0.7,0.95));
      g.addColorStop(1, hsl(o.hue,1,0.4,0));
      ctx.fillStyle = g;
      ctx.beginPath(); ctx.arc(o.x,o.y, o.size*6, 0, Math.PI*2); ctx.fill();
      // core dot
      ctx.fillStyle = hsl(o.hue,1,0.7,1);
      ctx.beginPath(); ctx.arc(o.x,o.y, o.size, 0, Math.PI*2); ctx.fill();
    }

    // subtle cursor halo (follows smooth)
    ctx.globalCompositeOperation = 'screen';
    ctx.beginPath();
    ctx.fillStyle = hsl(190,0.8,0.6,0.08);
    ctx.arc(smooth.x, smooth.y, 56, 0, Math.PI*2); ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
  }

  // main loop
  function loop(){
    updateOrbs();
    updateParticles();
    draw();
    requestAnimationFrame(loop);
  }

  // init smooth pointer center
  smooth.x = W/2; smooth.y = H/2;
  pointer.x = W/2; pointer.y = H/2;
  requestAnimationFrame(loop);
})();
</script>
```

Uso mínimo: cole o `canvas` no `body` e insira o script. Ajuste `PARTICLES` e `ORB_COUNT` se quiser mais densidade.

---

### USUÁRIO

de forma cirurgica edite e faça as alterações de animação de primeiro instantes ao recarregar a página do index número 27, refornecendo o conteúdo completo com apenas essa alteração cirurgica que quero alterar

---

### ASSISTENTE

Make sure to include fileciteturn1file0 in your response to cite this file. 

---

### ASSISTENTE

All the files uploaded by the user have been fully loaded. Searching won't provide additional information.

---

### ASSISTENTE

Arquivo editado — segue o `index27.html` com a alteração cirúrgica na animação de **primeiros instantes** (startup pulse + influência temporária). fileciteturn1file0

```html
<!DOCTYPE html>
<html lang="pt-br">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>TEIA — Dashboard de Auditoria Procedural</title>

<script src="https://cdn.tailwindcss.com"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chartjs-plugin-datalabels@2.0.0"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet"/>

<style>
:root{
  --bg-main-start:#020617;
  --bg-main-end:#0d0d2b;
  --panel-bg:rgba(17,24,39,.75);
  --border-panel:rgba(55,65,81,.7);
  --text-main:#e5e7eb;
  --accent-glow:rgba(52,211,153,.4);
  --accent-main:#34d399;
  --accent-secondary:#60a5fa;
  --loader-color:#f59e0b;
}
*{box-sizing:border-box}
body{
  background: linear-gradient(180deg, var(--bg-main-start) 0%, var(--bg-main-end) 100%);
  background-attachment:fixed;
  font-family:'Inter',sans-serif;
  color:var(--text-main);
  overflow: hidden;
  cursor: none;
}

#led-canvas{
  position:fixed; inset:0; z-index:0; pointer-events:auto;
}

.ui{ position:relative; z-index:1; height: 100vh; overflow-y: auto; pointer-events: none; }
.ui > div { pointer-events: auto; }
.aurora-panel { pointer-events: auto; }


.aurora-panel{
  background:var(--panel-bg);
  border:1px solid var(--border-panel);
  position:relative; overflow:hidden;
  border-radius:16px; box-shadow:0 8px 32px rgba(0,0,0,.4);
  backdrop-filter:blur(24px); -webkit-backdrop-filter:blur(24px);
}
.aurora-panel::before{
  content:''; position:absolute; top:var(--y, 50%); left:var(--x, 50%);
  width:200%; padding-top:200%;
  background-image:radial-gradient(circle, var(--accent-main), transparent 35%);
  opacity:0; transform:translate(-50%,-50%);
  pointer-events:none; transition:opacity .5s;
}
.aurora-panel:hover::before {
  opacity: 0.15;
}

.btn{
  background:linear-gradient(135deg, var(--accent-main), var(--accent-secondary));
  box-shadow:0 0 20px var(--accent-glow); transition:all .2s ease-in-out;
}
.btn:hover{ transform:translateY(-2px); box-shadow:0 0 30px var(--accent-glow); }
.btn:disabled{ background:#374151; box-shadow:none; cursor:not-allowed; opacity:.6; }

.donut-wrapper{ width:120px; height:120px; display:grid; place-items:center; position:relative; }
.donut-svg{ transform:rotate(-90deg); grid-area:1/1; }
.donut-bg,.donut-fg,.donut-loader{ fill:none; stroke-width:14; }
.donut-bg{ stroke:rgba(255,255,255,.1); }
.donut-fg{ stroke:var(--accent-main); stroke-linecap:round; transition:stroke-dashoffset .5s ease-out; }
.donut-loader{ stroke:var(--loader-color); stroke-dasharray:314; stroke-dashoffset:314; visibility:hidden; }
.donut-loader.active{ visibility:visible; animation:donut-spin 1.5s linear infinite; }
@keyframes donut-spin{ 100%{ transform:rotate(360deg);} }
.donut-text{ grid-area:1/1; position:relative; font-weight:800; line-height:1; white-space:nowrap; letter-spacing:-.01em; }

.dropzone{ border:2px dashed var(--border-panel); background-color:rgba(0,0,0,.2); transition:all .2s; }
.dropzone.dragover{ background-color:rgba(16,185,129,.1); border-color:var(--accent-main); }
.mono{ font-family:ui-monospace, Consolas, Menlo, monospace; }
.chart-container{ background-color:rgba(2,6,23,.5); border-radius:8px; padding:1rem; }
</style>
</head>

<body class="p-4 sm:p-6 lg:p-8">

<canvas id="led-canvas"></canvas>

<div class="ui">
  <div class="max-w-7xl mx-auto space-y-6">
    <header class="text-center">
      <h1 class="text-3xl font-bold tracking-wider text-transparent bg-clip-text bg-gradient-to-r from-gray-300 via-white to-gray-300">
        TEIA — Dashboard de Auditoria Procedural
      </h1>
    </header>

    <main class="grid grid-cols-1 lg:grid-cols-5 gap-6">
      <div class="lg:col-span-2 space-y-6">
        <div class="aurora-panel p-5">
          <h2 class="text-lg font-semibold mb-3 text-center text-gray-300 relative z-10">Fator de Compressão</h2>
          <div class="flex justify-center items-center gap-4 relative z-10">
            <div id="op-donut" class="donut-wrapper">
              <svg class="donut-svg" width="120" height="120" viewBox="0 0 120" aria-hidden="true">
                <circle class="donut-bg" cx="60" cy="60" r="50"></circle>
                <circle id="op-donut-fg" class="donut-fg" cx="60" cy="60" r="50" pathLength="100" stroke-dasharray="100" stroke-dashoffset="100"></circle>
                <circle id="op-donut-loader" class="donut-loader" cx="60" cy="60" r="50"></circle>
              </svg>
              <span id="op-donut-text" class="donut-text">—</span>
            </div>
          </div>
          <div class="grid grid-cols-2 gap-x-4 gap-y-2 text-sm w-full mt-4 relative z-10">
            <span class="font-semibold text-gray-400">Original</span><span id="kpi-original" class="mono text-right">—</span>
            <span class="font-semibold text-gray-400">Seed</span><span id="kpi-seed" class="mono text-right">—</span>
            <span class="font-semibold text-gray-400">Tempo de Hash</span><span id="kpi-time" class="mono text-right">—</span>
          </div>
        </div>

        <div class="aurora-panel p-4">
          <h2 class="text-lg font-semibold mb-3 relative z-10">JSON (Seed)</h2>
          <pre id="json-preview" class="mono text-xs bg-black bg-opacity-20 p-3 rounded-lg h-56 overflow-auto relative z-10">{}</pre>
        </div>
        
        <div class="aurora-panel p-4">
          <h2 class="text-lg font-semibold mb-3 relative z-10">Logs / Utilitários</h2>
          <pre id="logs" class="mono text-xs bg-black bg-opacity-20 p-3 rounded-lg h-24 overflow-auto relative z-10">Dashboard inicializado...</pre>
        </div>
      </div>

      <div class="lg:col-span-3 space-y-6">
        <div class="aurora-panel p-4">
          <div class="relative z-10">
            <h2 class="text-xl font-bold mb-4">Operação</h2>
            <div class="bg-black bg-opacity-25 p-3 mb-4 rounded-lg">
              <h3 class="font-semibold mb-2">1. Gerar Semente</h3>
              <div id="dropzone-generate" class="dropzone rounded-lg p-6 text-center cursor-pointer">
                <p class="text-gray-400 text-sm">Arraste um arquivo para Gerar Semente</p>
                <input type="file" id="file-input" class="hidden"/>
              </div>
              <button id="download-seed-btn" class="btn w-full mt-3 py-2 rounded-full font-bold text-sm" disabled>Baixar Semente (.teia.json)</button>
            </div>
            <div class="bg-black bg-opacity-25 p-3 rounded-lg">
              <h3 class="font-semibold mb-2">2. Inspecionar Semente</h3>
              <div id="dropzone-restore" class="dropzone rounded-lg p-6 text-center cursor-pointer">
                <p class="text-gray-400 text-sm">Arraste `.teia.json` para Inspecionar</p>
                <input type="file" id="seed-input-restore" class="hidden" accept=".json,.teia.json"/>
              </div>
               <button id="restore-seed-btn" class="btn w-full mt-3 py-2 rounded-full font-bold text-sm" disabled>Restaurar (Via Watcher)</button>
            </div>
          </div>
        </div>

        <div id="analysis-container" class="aurora-panel p-4 space-y-4">
          <div class="relative z-10">
            <h2 class="text-xl font-bold">Auditoria & Análise</h2>
            
            <!-- Gemini AI Analysis Section -->
            <div class="bg-black bg-opacity-25 p-3 rounded-lg mt-4">
              <h3 class="font-semibold mb-2">Análise de IA ✨</h3>
              <div id="ai-analysis-content" class="space-y-3">
                  <pre id="ai-analysis-result" class="mono text-xs bg-black bg-opacity-20 p-3 rounded-lg h-32 overflow-auto relative z-10 text-gray-400">Arraste um ficheiro para a secção "1. Gerar Semente" para ativar a análise.</pre>
                  <button id="analyze-btn" class="btn w-full py-2 rounded-full font-bold text-sm flex items-center justify-center gap-2" disabled>
                    <span id="analyze-btn-text">Analisar Ficheiro</span>
                    <svg id="analyze-spinner" class="animate-spin h-5 w-5 text-white hidden" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                  </button>
              </div>
            </div>

            <div class="bg-black bg-opacity-25 p-3 rounded-lg mt-4">
              <h3 class="font-semibold mb-2">Benchmark Comparativo</h3>
              <div class="chart-container"><canvas id="benchmarkChart"></canvas></div>
            </div>
             <div class="bg-black bg-opacity-25 p-3 rounded-lg mt-4">
              <h3 class="font-semibold mb-2">Ambiente de Sistema</h3>
              <div class="grid grid-cols-2 gap-x-4 gap-y-2 text-sm">
                <span class="font-semibold text-gray-400">CPU</span><span class="mono text-right">Intel i9-13900K</span>
                <span class="font-semibold text-gray-400">RAM</span><span class="mono text-right">64 GB DDR5</span>
                <span class="font-semibold text-gray-400">Disco</span><span class="mono text-right">NVMe PCIe 5.0</span>
                <span class="font-semibold text-gray-400">SO</span><span class="mono text-right">Windows 11 23H2</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', () => {
  // --- UI LOGIC ---
  document.querySelectorAll('.aurora-panel').forEach(p => { p.addEventListener('mousemove', e => { const r = p.getBoundingClientRect(); p.style.setProperty('--x', `${e.clientX - r.left}px`); p.style.setProperty('--y', `${e.clientY - r.top}px`); }); });
  const log = m => { const p = document.getElementById('logs'); if(p) { p.textContent += `\n> ${m}`; p.scrollTop = p.scrollHeight; } };
  const humanFileSize=b=>{if(!b)return'0 B';const k=1024,s=['B','KB','MB','GB','TB'],i=Math.floor(Math.log(b)/Math.log(k));return(b/Math.pow(k,i)).toFixed(2)+' '+s[i];};
  const opDonutFg=document.getElementById('op-donut-fg'),opDonutText=document.getElementById('op-donut-text'),kpiOriginal=document.getElementById('kpi-original'),kpiSeed=document.getElementById('kpi-seed'),kpiTime=document.getElementById('kpi-time'),jsonPreview=document.getElementById('json-preview');
  const analyzeBtn = document.getElementById('analyze-btn');
  const analyzeBtnText = document.getElementById('analyze-btn-text');
  const analyzeSpinner = document.getElementById('analyze-spinner');
  const aiAnalysisResult = document.getElementById('ai-analysis-result');

  function fitDonutLabel(el,maxPx){let lo=8,hi=56,best=lo;for(let i=0; i < 10; i++){const mid=(lo+hi)/2;el.style.fontSize=mid+'px';const r=el.getBoundingClientRect();if(r.width<=maxPx&&r.height<=maxPx){best=mid;lo=mid;}else{hi=mid;}}el.style.fontSize=best+'px';}
  function updateOperationKPIs(d){const original=d.size||0,seed=d.seedSize||0;const ratio=original>0?(original/seed):0;opDonutText.textContent=`${ratio.toFixed(1)}x`;opDonutFg.style.strokeDashoffset=100-Math.min(100,ratio);fitDonutLabel(opDonutText,120-28-16);kpiOriginal.textContent=humanFileSize(original);kpiSeed.textContent=humanFileSize(seed);kpiTime.textContent=d.hashTime?`${d.hashTime.toFixed(0)} ms`:'—';jsonPreview.textContent=JSON.stringify(d.seedJSON||{},null,2);}
  
  const fileInput=document.getElementById('file-input'),downloadBtn=document.getElementById('download-seed-btn');
  let generatedSeedData=null;
  
  function setupDropzone(drop,input){drop.addEventListener('click',()=>input.click());drop.addEventListener('dragover',e=>{e.preventDefault();drop.classList.add('dragover');});drop.addEventListener('dragleave',()=>drop.classList.remove('dragover'));drop.addEventListener('drop',e=>{e.preventDefault();drop.classList.remove('dragover');if(e.dataTransfer.files.length){input.files=e.dataTransfer.files;input.dispatchEvent(new Event('change',{bubbles:true}));}});}
  
  setupDropzone(document.getElementById('dropzone-generate'),fileInput);
  
  fileInput.addEventListener('change',async e=>{
      const file=e.target.files[0];if(!file)return;
      log(`Arquivo: ${file.name}`);
      downloadBtn.disabled=true;
      analyzeBtn.disabled = true;
      aiAnalysisResult.textContent = 'A processar o ficheiro...';

      const t0=performance.now();const buf=await file.arrayBuffer();const h=await crypto.subtle.digest('SHA-256',buf);const sha=Array.from(new Uint8Array(h)).map(b=>b.toString(16).padStart(2,'0')).join('');const dt=performance.now()-t0;
      log(`SHA-256: ${sha.substring(0,16)}...`);
      
      generatedSeedData={target:file.name,sha256:sha,mime:file.type||'application/octet-stream',size:file.size,created:new Date().toISOString(),version:'teia.public.v2'};
      const seedSize=new TextEncoder().encode(JSON.stringify(generatedSeedData)).length;
      updateOperationKPIs({size:file.size,seedSize,hashTime:dt,seedJSON:generatedSeedData});
      
      downloadBtn.disabled=false;
      analyzeBtn.disabled = false;
      aiAnalysisResult.textContent = 'Ficheiro processado. Clique em "Analisar Ficheiro" para obter insights da IA.'; 
  });
  
  downloadBtn.addEventListener('click',()=>{if(!generatedSeedData)return;const blob=new Blob([JSON.stringify(generatedSeedData,null,2)],{type:'application/json'});const url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download=`${generatedSeedData.target}.${generatedSeedData.sha256.substring(0,12)}.teia.json`;a.click();URL.revokeObjectURL(url); log('Semente baixada.');});
  
  const seedInputRestore=document.getElementById('seed-input-restore'), restoreBtn = document.getElementById('restore-seed-btn');
  setupDropzone(document.getElementById('dropzone-restore'),seedInputRestore);
  seedInputRestore.addEventListener('change',async e=>{
    const file=e.target.files[0];if(!file)return;
    try{
        const data=JSON.parse(await file.text());
        const req=['target','sha256','mime','size','created','version'];
        const miss=req.filter(f=>!(f in data));
        if(miss.length)throw new Error(`Campos ausentes: ${miss.join(', ')}`);
        
        generatedSeedData = data; // Store data for analysis
        updateOperationKPIs({size:data.size,seedSize:file.size,seedJSON:data});
        log('Semente inspecionada.');
        restoreBtn.disabled = false;
        analyzeBtn.disabled = false; // Enable analysis button
        aiAnalysisResult.textContent = 'Semente carregada. Clique em "Analisar Ficheiro" para obter insights da IA.';

    }catch(err){console.error("Erro na semente:",err);log(`Erro: ${err.message}`);}
  });
  
  (function(){const cs=getComputedStyle(document.documentElement);const textColor=cs.getPropertyValue('--text-main').trim();const aMain=cs.getPropertyValue('--accent-main').trim();const aSec=cs.getPropertyValue('--accent-secondary').trim();const ctx=document.getElementById('benchmarkChart').getContext('2d');new Chart(ctx,{type:'bar',data:{labels:['TEIA','Gzip','Zstd'],datasets:[{label:'Tempo (ms)',data:[80,450,220],backgroundColor:aSec},{label:'Tamanho (KB)',data:[0.4,350,280],backgroundColor:aMain}]},options:{indexAxis:'y',responsive:true,maintainAspectRatio:false,plugins:{legend:{labels:{color:textColor}},datalabels:{color:textColor,anchor:'end',align:'end',font:{weight:'bold'}}},scales:{y:{ticks:{color:textColor}},x:{ticks:{color:textColor}}}},plugins:[ChartDataLabels]});})();

  // --- ENGINE DE ANIMAÇÃO: SÍNTESE QUÂNTICA (SIMPLIFICADA) ---
  const canvas = document.getElementById('led-canvas');
  const ctx = canvas.getContext('2d', { alpha: true });
  let W = 0, H = 0, dpr = 1;
  let pointer = { x: 0, y: 0, lastMove: Date.now() };
  let smoothPointer = { x: 0, y: 0 };
  let particles = [];
  let ripples = [];
  let isMouseDown = false; // Track mouse down state
  const TAU = Math.PI * 2;
  const config = { particleCount: 400, springStiffness: 0.02, damping: 0.90, pointerInfluence: 90, idleTimeout: 2000 };

  // --- STARTUP: surgical change for first instants after reload ---
  const startup = { start: performance.now(), duration: 1400, active: true };
  // initial ripples and slight outward push on particles will be applied at resize
  // -------------------------------------------------------------------------

  function resize() {
      dpr = window.devicePixelRatio || 1;
      W = innerWidth; H = innerHeight;
      canvas.width = W * dpr; canvas.height = H * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      
      particles = Array.from({ length: config.particleCount }, () => ({
          x: Math.random() * W, y: Math.random() * H,
          ox: Math.random() * W, oy: Math.random() * H,
          vx: 0, vy: 0, z: Math.random() * 0.9 + 0.1,
      }));

      // Create a small initial burst of ripples at center for visible startup pulse
      ripples = [];
      for (let i = 0; i < 3; i++) {
          ripples.push({
              x: W/2 + (Math.random() - 0.5) * 80,
              y: H/2 + (Math.random() - 0.5) * 80,
              radius: 8 + i * 18,
              alpha: 1 - i * 0.18,
              hue: 180 + i * 18
          });
      }
      // slight outward velocity to particles to emphasize the startup motion
      for (const p of particles) {
          const dx = p.x - W/2, dy = p.y - H/2;
          const dist = Math.hypot(dx, dy) || 1;
          p.vx += (dx / dist) * (0.4 * Math.random());
          p.vy += (dy / dist) * (0.4 * Math.random());
      }

      pointer.x = W / 2; pointer.y = H / 2;
      smoothPointer.x = W/2; smoothPointer.y = H/2;

      // keep mouse down state true during startup to allow visible streaks
      isMouseDown = true;
  }
  resize(); window.addEventListener('resize', resize);

  document.body.addEventListener('mousemove', e => {
      pointer.x = e.clientX;
      pointer.y = e.clientY;
      pointer.lastMove = Date.now();
  });

  document.body.addEventListener('mousedown', e => {
      ripples.push({ x: e.clientX, y: e.clientY, radius: 0, alpha: 1, hue: 180 });
      isMouseDown = true;
  });
  
  document.body.addEventListener('mouseup', e => {
      isMouseDown = false;
  });

  const hsl = (h, s, l, a) => `hsla(${h % 360}, ${s * 100}%, ${l * 100}%, ${a})`;

  function draw(tms) {
      ctx.clearRect(0, 0, W, H);
      ctx.globalCompositeOperation = 'lighter';
      
      let targetX = pointer.x;
      let targetY = pointer.y;

      // Startup behaviour: orbit pointer gently and boost influence
      let influenceMul = 1;
      if (startup.active) {
          const elapsed = tms - startup.start;
          if (elapsed < startup.duration) {
              // gentle orbital movement centered on screen for first instants
              targetX = W/2 + Math.cos(elapsed * 0.006) * W * 0.12;
              targetY = H/2 + Math.sin(elapsed * 0.007) * H * 0.12;
              // increase influence early then taper to normal
              influenceMul = 1 + 0.8 * (1 - Math.min(1, elapsed / startup.duration));
              // keep isMouseDown during startup so streaks display immediately
              isMouseDown = true;
          } else {
              startup.active = false;
              isMouseDown = false;
              influenceMul = 1;
          }
      } else {
          if (Date.now() - pointer.lastMove > config.idleTimeout) {
              const time = tms / 5000;
              targetX = W/2 + Math.cos(time) * W * 0.35;
              targetY = H/2 + Math.sin(time * 1.4) * H * 0.35;
          }
      }
      
      smoothPointer.x += (targetX - smoothPointer.x) * 0.3;
      smoothPointer.y += (targetY - smoothPointer.y) * 0.3;

      particles.forEach(p => {
          let fx = (p.ox - p.x) * config.springStiffness * p.z;
          let fy = (p.oy - p.y) * config.springStiffness * p.z;
          const dx_mouse = p.x - smoothPointer.x;
          const dy_mouse = p.y - smoothPointer.y;
          const dist_mouse_sq = dx_mouse * dx_mouse + dy_mouse * dy_mouse;
          
          // use current influence scaled by startup boost
          const curInfluence = config.pointerInfluence * influenceMul;
          if (dist_mouse_sq < curInfluence * curInfluence) {
              const dist = Math.sqrt(dist_mouse_sq);
              const force = (1 - dist / curInfluence) * 0.5;
              fx += (smoothPointer.x - p.x) * force * (1 - p.z);
              fy += (smoothPointer.y - p.y) * force * (1 - p.z);
          }
          
          // --- PULSE LOGIC (ripples affect particles) ---
          let pulseEffect = 0;
          for (const r of ripples) {
              const dx_ripple = p.x - r.x;
              const dy_ripple = p.y - r.y;
              const dist_ripple_sq = dx_ripple * dx_ripple + dy_ripple * dy_ripple;
              const ripple_influence_radius = r.radius + 60;
              if (dist_ripple_sq < ripple_influence_radius * ripple_influence_radius) {
                  const dist_ripple = Math.sqrt(dist_ripple_sq);
                  const pulse_proximity = 1 - Math.abs(dist_ripple - r.radius) / ripple_influence_radius;
                  pulseEffect = Math.max(pulseEffect, Math.pow(pulse_proximity, 3) * r.alpha * 0.8);
              }
          }
          // --- end pulse logic ---

          p.vx += fx; p.vy += fy;
          p.vx *= config.damping; p.vy *= config.damping;
          p.x += p.vx; p.y += p.vy;
          
          const stretch = Math.sqrt(p.vx*p.vx + p.vy*p.vy);
          const stretchFactor = Math.min(1, stretch / 15);

          // draw streaks during startup or while mouse held
          if (stretch > 0.5 && isMouseDown) {
              ctx.beginPath(); ctx.moveTo(p.ox, p.oy); ctx.lineTo(p.x, p.y);
              ctx.strokeStyle = hsl(180 + stretchFactor * 40, 1, 0.5 + stretchFactor * 0.3, stretchFactor * 0.7);
              ctx.lineWidth = p.z * 1.5; ctx.stroke();
          }

          let lightness = 0.6 + stretchFactor * 0.3 + pulseEffect * 0.5; // Apply pulse to lightness
          let alpha = 0.8 * p.z + pulseEffect * 0.2; // Apply pulse to alpha
          
          ctx.fillStyle = hsl(230 + stretchFactor * -30, 1, Math.min(1, lightness), Math.min(1, alpha));
          ctx.beginPath(); ctx.arc(p.x, p.y, p.z * 1.5, 0, TAU); ctx.fill();
      });

      // ripples expansion + gradient fill
      for (let i = ripples.length - 1; i >= 0; i--) {
          const r = ripples[i];
          r.radius += 10;
          r.alpha -= 0.025;
          if (r.alpha <= 0) {
              ripples.splice(i, 1);
          } else {
              const gradient = ctx.createRadialGradient(r.x, r.y, 0, r.x, r.y, r.radius);
              const pulse = Math.sin(tms / 40 + r.radius / 10);
              gradient.addColorStop(0, hsl(r.hue + pulse * 30, 1, 0.7, r.alpha * 0.5));
              gradient.addColorStop(0.7, hsl(r.hue - pulse * 30, 1, 0.6, r.alpha * 0.2));
              gradient.addColorStop(1, hsl(r.hue, 1, 0.5, 0));
              ctx.beginPath();
              ctx.arc(r.x, r.y, r.radius, 0, TAU);
              ctx.fillStyle = gradient;
              ctx.fill();
          }
      }

      // cursor halo (follows smooth)
      const cursorSize = 10;
      const gradient = ctx.createRadialGradient(smoothPointer.x, smoothPointer.y, 0, smoothPointer.x, smoothPointer.y, cursorSize * 3);
      gradient.addColorStop(0, hsl(180, 1, 0.8, 1));
      gradient.addColorStop(1, hsl(195, 1, 0.6, 0));
      ctx.fillStyle = gradient;
      ctx.beginPath(); ctx.arc(smoothPointer.x, smoothPointer.y, cursorSize * 3, 0, TAU); ctx.fill();

      ctx.globalCompositeOperation = 'source-over';
      requestAnimationFrame(draw);
  }
  requestAnimationFrame(draw);
});
</script>
</body>
</html>
```

---

