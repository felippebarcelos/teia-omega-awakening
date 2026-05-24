# 2164 - Coerência painel identidade

### USUÁRIO

Isso é coerente: "1) adicionar um painel “Identidade funcional”

cole este bloco logo após o <aside class="panel sidebar">…</aside> que você já tem:

<section class="panel" id="func-id" style="margin-top:18px">
  <h3>Identidade funcional do seed</h3>

  <div class="row">
    <label>Seed JSON (colar)</label>
    <textarea id="seed_json" placeholder='Cole aqui o conteúdo do arquivo .teia.json (ou só o campo "sha256")'></textarea>
  </div>

  <div class="actions">
    <button id="btn-anchor" class="btn-plain">Gerar âncora (teia:seed:&lt;sha256&gt;)</button>
    <button id="btn-jsonld" class="btn-plain">Gerar seed_link.jsonld</button>
    <button id="btn-hb" class="btn-plain">Gerar seed_heartbeat.ps1</button>
  </div>

  <div class="actions" style="margin-top:6px">
    <button id="btn-copy-anchor" class="btn-primary">Copiar âncora</button>
    <button id="btn-openlog-aux" class="btn-save">Abrir log (aion:)</button>
  </div>

  <textarea id="seed_tools_out" readonly placeholder="saída das ferramentas…"></textarea>
</section>


usa os mesmos estilos do seu arquivo; por isso ele entra “discreto” e coeso.

2) colar o JS (no fim do seu <script> atual)

isto implementa: âncora, JSON-LD, heartbeat e openlog.
não há I/O de disco do host no navegador; por isso a gente pede o seed em texto (colar), lê o sha256 e gera os arquivos para download.

// ——— helpers ———
function S(el){ return document.querySelector(el) }
function dl(name, text, mime='text/plain'){
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([text],{type: mime}));
  a.download = name; a.click(); URL.revokeObjectURL(a.href);
}
function logT(msg){ const t=S('#seed_tools_out'); t.value=(t.value? t.value+'\n':'')+msg }

// extrai sha256 de um JSON colado, ou aceita sha256 “puro”
function parseSeedSha(){
  const raw = (S('#seed_json').value || '').trim();
  if(!raw){ throw new Error('Cole o JSON da seed (ou apenas o sha256).') }
  if(/^[0-9a-f]{64}$/i.test(raw)) return raw.toLowerCase();
  try{
    const obj = JSON.parse(raw);
    const h = String(obj.sha256||'').trim();
    if(!/^[0-9a-f]{64}$/i.test(h)) throw 0;
    return h.toLowerCase();
  }catch{ throw new Error('Não consegui obter sha256. Cole o JSON da seed (com "sha256") ou só o hash.') }
}

// ——— 1) Âncora ———
let lastAnchor = '';
S('#btn-anchor').onclick = ()=>{
  try{
    const sha = parseSeedSha();
    lastAnchor = `teia:seed:${sha}`;
    logT('Âncora: '+lastAnchor);
  }catch(e){ logT('ERR: '+e.message) }
};
S('#btn-copy-anchor').onclick = async ()=>{
  if(!lastAnchor){ S('#btn-anchor').click() }
  if(lastAnchor){ await navigator.clipboard.writeText(lastAnchor); logT('Âncora copiada p/ clipboard.')}
};

// ——— 2) seed_link.jsonld ———
S('#btn-jsonld').onclick = ()=>{
  try{
    const raw = (S('#seed_json').value||'').trim();
    const sha = parseSeedSha();
    // tenta aproveitar alguns campos se o usuário colou o JSON inteiro
    let name = 'seed_package';
    let zip  = {};
    try{ const o = JSON.parse(raw); name = o.name || name; zip = o.zip||zip }catch{}
    const now = new Date().toISOString();

    const jsonld = {
      "@context":{
        "@vocab":"https://teia.nucleo/ontology#",
        "sha256":"https://schema.org/sha256",
        "createdAt":"https://schema.org/dateCreated",
        "hasPart":"https://schema.org/hasPart",
        "Seed":"https://teia.nucleo/ontology#Seed",
        "ZipArtifact":"https://teia.nucleo/ontology#ZipArtifact",
        "SymbolicAxis":"https://teia.nucleo/ontology#SymbolicAxis"
      },
      "@type":"Seed",
      "id": `teia:seed:${sha}`,
      "name": name,
      "createdAt": now,
      "zip": Object.assign({ "@type":"ZipArtifact", "sha256": sha }, zip),
      "symbolicAxes": { "PreservacaoAfetiva": true, "RaizImortal": true, "SimbioseArquetipa": true },
      "integrityPolicy":"bitwise-restore, sha256-verify, idempotent",
      "usageHints":[
        "Use restore.ps1 para reversão validada.",
        "Compare sha256 do log [OK] com a seed.",
        "Cite id=teia:seed:<sha256> em registros futuros."
      ]
    };
    const txt = JSON.stringify(jsonld,null,2);
    dl('seed_link.jsonld', txt, 'application/ld+json');
    logT('seed_link.jsonld gerado.');
  }catch(e){ logT('ERR: '+e.message) }
};

// ——— 3) seed_heartbeat.ps1 ———
S('#btn-hb').onclick = ()=>{
  try{
    const sha = parseSeedSha();
    // script minimalista; paths são placeholders para o usuário ajustar
    const ps = `# seed_heartbeat.ps1 — batimento de integridade
param([int]$Minutes=30,[int]$IntervalSec=300)
$ErrorActionPreference='Stop'
function Get-Sha256Hex([string]$p){ (Get-FileHash -Path $p -Algorithm SHA256).Hash.ToLowerInvariant() }

$ZipPath = 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\backups\\SEU_ARQUIVO.zip'   # ajuste
$Expected = '${sha}'

$logDir = Join-Path $PSScriptRoot 'hb_logs'; if(!(Test-Path $logDir)){ New-Item -ItemType Directory -Path $logDir|Out-Null }
$log    = Join-Path $logDir ('hb_'+(Get-Date -Format yyyyMMdd)+'.jsonl')
$end = (Get-Date).AddMinutes($Minutes)
while((Get-Date) -lt $end){
  $ts = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
  $ok = (Test-Path $ZipPath) -and (Get-Sha256Hex $ZipPath) -eq $Expected
  $entry = @{ ts=$ts; zip_ok=$ok; expected=$Expected } | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $entry -Encoding UTF8
  if(-not $ok){ exit 2 }
  Start-Sleep -Seconds $IntervalSec
}
exit 0
`;
    dl('seed_heartbeat.ps1', ps, 'text/plain');
    logT('seed_heartbeat.ps1 gerado.');
  }catch(e){ logT('ERR: '+e.message) }
};

// ——— 4) abrir log via protocolo aion: ———
S('#btn-openlog-aux').onclick = ()=>{
  const b64 = btoa(unescape(encodeURIComponent(JSON.stringify({action:'openlog'}))));
  location.href = 'aion:'+b64;
};

como isso mapeia seus “6 usos”

Âncora de identidade → botão “Gerar/ Copiar âncora” com teia:seed:<sha256>.

Restauração bit-a-bit → a UI já enfileira via HTTP/queue; você mantém a comparação de sha no log [OK].

Autocura/heartbeat → botão “Gerar seed_heartbeat.ps1”; você agenda/roda em background.

Acoplamento ontológico → botão “Gerar seed_link.jsonld” (JSON-LD com contexto TEIA).

Prova de autoria/legado → a âncora + JSON-LD viram a “RG ontoprocedural” pronta para ser assinada/carimbada.

Portais múltiplos → mesma âncora no clipboard serve para UI, watcher, CLI, dashboards e mobile.
"?

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

Make sure to include fileciteturn0file4 in your response to cite this file. 

---

### ASSISTENTE

The file contents provided above are truncated/partial snippets. The complete content for these files IS accessible via querying.

If the user asks a question related to these files, and the provided snippets do not clearly answer it, you **MUST** use the `file_search` tool to search the full document contents before responding.

## How to invoke the file_search tool
If the user's query isn't sufficiently answered by the provided snippets, parsed text, or images, you should invoke `file_search.msearch`.
To search the full content of the available files, you **must** send one message with recipient `to=file_search.msearch` in the analysis channel. Your message should be structured exactly as follows:
```
{
  'queries': ['Example query 1', 'Example query 2']  // List of up to five queries to search for.
}
```

Carefully balance the number of `file_search` calls and the quality of your response with the latency incurred by `file_search` calls.

Important guidelines for query formatting:
- Your message must be a valid JSON object. Do not include any extraneous text, backticks, markdown formatting, or comments beyond what is shown.
- The `queries` field must be a list of strings.
- One of the queries **MUST** exactly match the user's original question, but stripped of any extraneous details, and with ambiguous references clearly resolved using context from the conversation. It **MUST** be a complete sentence.
- Even if you suspect the user meant something else, one query **MUST** still be their original question.

## How to handle results from file_search
The file search tool will respond with the relevant search results from the full files. After you receive these results:
- Carefully evaluate each result to determine its relevance and quality.
- Use the high-quality and relevant results to inform your answer to the user's question.
- When possible, reuse information from prior file_search results and avoid repeating identical queries.

## Tool usage instructions and ordering
When the user asks a question, carefully consider whether the provided snippets sufficiently answer the query, whether you need to invoke `file_search.msearch`, or another available tool (such as `web`, if available) should be used instead.

Tool-ordering Guidelines:
1. For queries related to uploaded files, if snippets are insufficient, strongly prefer invoking `file_search.msearch` over other tools.
    - Avoid using `web.run`, `python` analysis, or any other tools until you have either:
        - Confirmed with high confidence the answer is not in the files, or
        - Have high confidence `file_search_tool` queries are not sufficient to answer the query.
2. Avoid usage of `web_search/web.run` for queries related to uploaded files
    - Carefully consider whether the user's query is better answered by web search results rather than available snippets or results from `file_search_tool`.
    - Unless the user's query is clearly unrelated to the uploaded files, prefer using `file_search.msearch`. You can always follow up with a web search if necessary for a more complete response.
3. Avoid using `python` unless necessary or requested by user.
    - If the user's query is answerable from the parsed text and images from the uploaded files, or from `file_search_tool`, do not invoke `python`.

Always keep this instruction in mind for the rest of the conversation, as the user may reference these files or ask related questions later on.

---

### ASSISTENTE

Curto e direto: **sim, é coerente** com a sua UI e com os “6 usos”. O painel “Identidade funcional” está bem delimitado, usa os mesmos padrões de botão/camadas, e o JS entrega exatamente: **âncora**, **JSON-LD**, **heartbeat** e **openlog** sem depender de I/O do host (apenas “colar” + downloads).

Abaixo, só os ajustes finos que eu recomendo — são pequenos, mas deixam a coisa à prova de bala:

### O que está perfeito
- **Mapeamento 6 usos**  
  Âncora → `teia:seed:<sha256>`;  
  Restauração bit-a-bit → você já loga e confere sha;  
  Heartbeat → `seed_heartbeat.ps1` com verificação periódica;  
  Acoplamento ontológico → `seed_link.jsonld` com contexto TEIA;  
  Prova/legado → âncora + JSON-LD (pronto pra assinar/carimbar);  
  Portais múltiplos → mesma âncora via clipboard em UI/CLI/dash.
- **Sem I/O host**: tudo client-side (Blob + `a.download`).  
- **Ergonomia**: “colar e clicar” resolve 90% dos casos.

### Pontos de melhoria (rápidos)
1) **Base64 de UTF-8 (sem `unescape`)**  
`unescape` é legado. Troque por `TextEncoder` para UTF-8 verdadeiro.

```js
function toB64Utf8(s){
  const bytes = new TextEncoder().encode(s);
  let bin = ''; for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin);
}
// ...no openlog:
S('#btn-openlog-aux').onclick = ()=>{
  const b64 = toB64Utf8(JSON.stringify({action:'openlog'}));
  location.href = 'aion:'+b64;
};
```

2) **Clipboard: tratar permissões**  
Alguns browsers exigem HTTPS/gesto do usuário. Apenas logue um aviso se falhar.

```js
S('#btn-copy-anchor').onclick = async ()=>{
  if(!lastAnchor){ S('#btn-anchor').click() }
  if(!lastAnchor) return;
  try{ await navigator.clipboard.writeText(lastAnchor); logT('Âncora copiada.')}
  catch{ logT('Aviso: não consegui acessar o clipboard neste contexto.'); }
};
```

3) **Reuso de seed colada**  
Quando o usuário cola **só o hash**, `btn-jsonld` tenta “aproveitar campos” e não encontra. Isso é ok, mas vale forçar um `name` mínimo e garantir `zip` limpo:

```js
let name = 'seed_package';
let zip  = {};
try{
  const o = JSON.parse(raw);
  if(o && typeof o==='object'){ name = o.name || name; zip = (o.zip && typeof o.zip==='object') ? o.zip : {} }
}catch{/* segue com defaults */}
```

4) **Revogação do `ObjectURL`**  
Revogue o URL após o “click” com um pequeno delay (alguns navegadores revogam cedo demais):

```js
function dl(name, text, mime='text/plain'){
  const blob = new Blob([text],{type: mime});
  const href = URL.createObjectURL(blob);
  const a = Object.assign(document.createElement('a'), { href, download: name });
  document.body.appendChild(a); a.click(); a.remove();
  setTimeout(()=>URL.revokeObjectURL(href), 1000);
}
```

5) **Validação extra do SHA-256**  
Se o seed vier “puro”, você já valida bem. Só acrescente feedback visual rápido quando o regex falhar:

```js
if(!/^[0-9a-f]{64}$/i.test(h)) throw new Error('sha256 inválido (64 hex).');
```

6) **Acessibilidade mínima**  
Associe `<label for="seed_json">` e `aria-live` no `seed_tools_out` para leitura por screen-readers:

```html
<label for="seed_json">Seed JSON (colar)</label>
<textarea id="seed_json" ...></textarea>
<textarea id="seed_tools_out" readonly aria-live="polite" ...></textarea>
```

7) **`seed_heartbeat.ps1`: caminho exemplo**  
Deixe explícito que o usuário deve trocar `$ZipPath` (com comentário “TODO”) e, se quiser, grave também **exit code** no `.jsonl`:

```powershell
$entry = @{ ts=$ts; zip_ok=$ok; expected=$Expected; exitcode = $(if($ok){0}else{2}) } | ConvertTo-Json -Compress
```

### Segurança/integração (2 notas)
- **`aion:`**: protocolos custom podem ser bloqueados por políticas do navegador. Está correto como “tentativa”; só registre no log caso o redirecionamento falhe.  
- **HTTPS/Frame**: para `clipboard` e `download` funcionarem sem atritos, hospede a UI em **HTTPS** e fora de iframes com políticas restritas.

### Veredito
Pode integrar do jeito que você descreveu. Com os *patches* acima, o painel entra coeso e robusto, atendendo os 6 usos de forma clara, idempotente e “sem sustos” pro usuário final.

Se quiser, eu te devolvo o **bloco JS já com as trocas (toB64Utf8, clipboard try/catch, dl fix, validações)** — é só colar no final do seu `<script>`. Quer que eu gere esse patch pronto?

---

### USUÁRIO

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'C:\\Users\\felip\\index30_unified.html'; "'$c=Get-Content -Raw $p;
        $i=$c.IndexOf('"'btnJsonLd'); "'$start=[Math]::Max(0,$i-300); $len=[Math]::Min(1200, $c.Length-$start);
        $c.Substring($start,$len)'

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'C:\\Users\\felip\\index30_unified.html'; "'$c=Get-Content -Raw $p;
        $i=$c.IndexOf('"'JSON-LD'); "'$start=[Math]::Max(0,$i-600); $len=[Math]::Min(1800, $c.Length-$start);
        $c.Substring($start,$len)'
• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'C:\\Users\\felip\\index30_unified.html'; Select-String -Path "'$p
  └ pwsh -NoLogo -NoProfile -Command '$p='"'C:\\Users\\felip\\index30_unified.html'; "'$c=Get-Content -Raw $p;
        $c.IndexOf('"'function dl(')"

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'C:\\Users\\felip\\index30_unified.html'; "'$c=Get-Content -Raw $p;
        $i=$c.IndexOf('"'function dl('); "'$c.Substring($i-40, 300)'
• Proposed Change C:\Users\felip\index30_unified.html (+5 -3)
    198        function dl(name, text, mime='text/plain'){
    205        function logT(msg){ const t=S('#seed_tools_out'); if(!t) return; t.value = (t.value ? (t.value+'\n') : ''
           ) + String(msg) }
    206   +    function toB64Utf8(s){ const bytes=new TextEncoder().encode(s); let bin=''; for(const b of bytes){ bin+=S
           tring.fromCharCode(b) } return btoa(bin) }
    207

• Change Approved C:\Users\felip\index30_unified.html (+1 -0)

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'C:\\Users\\felip\\index30_unified.html'; "'$c=Get-Content -Raw $p;
        $i=$c.IndexOf('"'function parseSeedSha'); "'$c.Substring($i, 240)'

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'C:\\Users\\felip\\index30_unified.html'; (Get-Content -Raw "'$p) -split "'"\
        \r?\\n\" | Select-String -Pattern \"parseSeedSha\\(\\)|sha256\" -Context 0,2 | ForEach-Object { "'$_.LineNumber;
        $_.Line; $_.Context.PostContext }'

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'C:\\Users\\felip\\index30_unified.html'; Select-String -Path "'$p -Pattern
        "btn-openlog-aux" -SimpleMatch -Context 0,8 | ForEach-Object { $_.LineNumber; $_.Line; $_.Context.PostContext }'

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'C:\\Users\\felip\\index30_unified.html'; "'$lines=Get-Content -Path $p;
        $start = 291; $slice = $lines[($start-1)..($start+60)]; $slice -join "`n"'
• Proposed Change C:\Users\felip\index30_unified.html (+17 -1)
    309            let zip  = {};
    353   +        try { location.href = 'aion:'+b64; }
    354   +        catch { logT('Aviso: protocolo aion: pode estar bloqueado pelo navegador.'); }
    355   +      } catch(e){ logT('ERR: '+e.message) }
    356   +    };
    357        if (btnHb) btnHb.onclick = ()=>{


• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'C:\\Users\\felip\\index30_unified.html'; Select-String -Path "'$p -Pattern
        "'"\\"'$entry =" -SimpleMatch -Context 2,4 | ForEach-Object { $_.LineNumber; $_.Line; $_.Context.PostContext }'

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'C:\\Users\\felip\\index30_unified.html'; "'$c=Get-Content -Raw $p;

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'C:\\Users\\felip\\index30_unified.html'; "'$c=Get-Content -Raw $p;
        $i=$c.IndexOf('"'seed_heartbeat.ps1'); "'$c.Substring($i-120, 500)'

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'C:\\Users\\felip\\index30_unified.html'; Select-String -Path "'$p
        -Pattern "hb_logs" -SimpleMatch -Context 2,8 | ForEach-Object { $_.LineNumber; $_.Line; $_.Context.PreContext;
        $_.Context.PostContext }'

    374      $ok = (Test-Path $ZipPath) -and (Get-Sha256Hex $ZipPath) -eq $Expected
    375   -  $entry = @{ ts=$ts; zip_ok=$ok; expected=$Expected } | ConvertTo-Json -Compress
    375   +  $entry = @{ ts=$ts; zip_ok=$ok; expected=$Expected; exitcode = $(if($ok){0}else{2}) } | ConvertTo-Json -Com
           press
    376      Add-Content -Path $log -Value $entry -Encoding UTF8

• Change Approved C:\Users\felip\index30_unified.html (+1 -1)

    89         <div class="actions" style="display:flex; gap:8px; flex-wrap:wrap; margin-top:6px;">
    90    -      <button id="btn-copy-anchor" class="btn-primary">Copiar âncora</button>
    90    +      <button id="btn-copy-anchor" class="btn-primary">Gerar/Copiar âncora</button>
    91           <button id="btn-openlog-aux" class="btn-save">Abrir log (aion:)</button>

• Change Approved C:\Users\felip\index30_unified.html (+1 -1)

• Proposed Change C:\Users\felip\index30_unified.html (+3 -1)
    388            if(!lastAnchor){ btnAnchor?.click(); }
    389   -        if(lastAnchor){ await navigator.clipboard.writeText(lastAnchor); logT('Âncora copiada p clipboard.');
            }
    389   +        if(!lastAnchor) return;
    390   +        try { await navigator.clipboard.writeText(lastAnchor); logT('Âncora copiada.'); }
    391   +        catch { logT('Aviso: não consegui acessar o clipboard neste contexto.'); }
    392          }catch(e){ logT('ERR: '+e.message) }

• Change Approved C:\Users\felip\index30_unified.html (+3 -1)

• Proposed Change C:\Users\felip\index30_unified.html (+1 -2)
    350          try{
    351   -        const payload = { action: 'openlog' };
    352   -        const b64 = toB64Utf8(JSON.stringify(payload));
    351   +        const b64 = toB64Utf8(JSON.stringify({ action:'openlog' }));
    352            try { location.href = 'aion:'+b64; }

• Change Approved C:\Users\felip\index30_unified.html (+1 -2)

> Apliquei as melhorias pedidas no painel e script.

  UI e acessibilidade

  - Label associado: Seed JSON (colar)
  - Saída acessível: textarea id="seed_tools_out" com aria-live="polite"
  - Botão: renomeado para “Gerar/Copiar âncora”

  Helpers e robustez

  - dl(): agora cria Blob, adiciona , clica, remove e revoga o URL com delay de 1s
  - toB64Utf8(s): usa TextEncoder + btoa para Base64 de UTF‑8 (sem unescape)
  - parseSeedSha(): quando “sha256” top‑level é inválido, mostra “sha256 inválido (64 hex).”; mantém fallback recursivo

  Âncora

  - “Gerar âncora”: usa parseSeedSha() e registra lastAnchor = teia:seed:
  - “Gerar/Copiar âncora”: gera se necessário e tenta escrever no clipboard; em caso de bloqueio, loga “Aviso: não
  consegui acessar o clipboard neste contexto.”

  JSON‑LD

  - Reuso de campos: se o usuário colar JSON, aproveita name e zip somente se zip for objeto; caso contrário, usa
  defaults
  - Baixa seed_link.jsonld com MIME application/ld+json

  Heartbeat

  - seed_heartbeat.ps1: comenta “TODO: ajuste para o ZIP certo” em $ZipPath e adiciona exitcode ao .jsonl:
  $entry = @{ ts=$ts; zip_ok=$ok; expected=$Expected; exitcode = $(if($ok){0}else{2}) } | ConvertTo-Json -Compress

  Openlog (aion:)

  - Agora usa envelope base64 UTF‑8:
      - payload: {action:'openlog'}
      - location.href = 'aion:' + toB64Utf8(JSON.stringify(payload))
      - Se bloqueado, loga aviso no painel

  Arquivo modificado

  - C:\Users\felip\index30_unified.html

  Quer que eu replique o painel e os handlers também no index30.html, ou preferimos manter só no unified?

---

### ASSISTENTE

Perfeito — as mudanças ficaram redondas.  
Sobre a sua pergunta: **recomendo centralizar** para evitar “drift” entre arquivos. Só replique no `index30.html` se ele **ainda** for servido em produção. Caso contrário, mantenha apenas no `index30_unified.html` e marque o `index30.html` como legado.

Se o `index30.html` ainda está ativo, há dois caminhos:

## Caminho A (recomendado): 1 fonte de verdade
1. **Extrair helpers + handlers** para um JS único (ex.: `func-id.js`).
2. **Injetar o painel por JS** (ou via `<template>`), evitando duplicar HTML.
3. **Incluir `func-id.js`** em ambos os arquivos.

Vantagens: zero duplicação, manutenção simples.

### Esqueleto de `func-id.js` (aproveita o que você já tem)
- Mantém `S`, `dl`, `logT`, `toB64Utf8`, `parseSeedSha`, os quatro handlers e a geração do `seed_heartbeat.ps1`.
- No `DOMContentLoaded`, se não existir o painel, **monta** o HTML no DOM após o seu `<aside.panel.sidebar>`.

> Posso te devolver esse `func-id.js` pronto, colando exatamente o painel e os handlers que você aprovou.

## Caminho B (rápido): replicar no `index30.html` com script idempotente
Se preferir replicar agora, use o script abaixo (PowerShell puro) para **verificar e copiar** o painel + handlers do `index30_unified.html` para o `index30.html`. Ele é idempotente: se já existir, não duplica.

```powershell
# Sync-FunctionalIdentity.ps1
param(
  [string]$Src = "C:\Users\felip\index30_unified.html",
  [string]$Dst = "C:\Users\felip\index30.html",
  [switch]$Apply
)
$ErrorActionPreference='Stop'
function Get-Block($text, [string]$startPat, [string]$endPat){
  $start = [regex]::Match($text, $startPat, 'IgnoreCase')
  if(-not $start.Success){ return $null }
  $rest  = $text.Substring($start.Index)
  $end   = [regex]::Match($rest, $endPat, 'IgnoreCase')
  if(-not $end.Success){ return $null }
  return $rest.Substring(0, $end.Index + $end.Length)
}
$src = Get-Content -Raw $Src
$dst = Get-Content -Raw $Dst

# 1) Painel <section id="func-id">…</section>
$panel = Get-Block $src '<section\s+class="panel"\s+id="func-id"[\s\S]*?>' '</section>'
if(-not $panel){ throw "Painel func-id não encontrado no fonte." }

# 2) Handlers: ancorados pelo btn ids (anchor/jsonld/hb/openlog)
$handlers = Get-Block $src '\/\/ ——— 1\) Âncora ———' '\/\/ ——— 4\) abrir log via protocolo aion: ———[\s\S]*?};'
if(-not $handlers){ throw "Bloco de handlers não encontrado no fonte." }

# 3) Helpers: S, dl, logT, toB64Utf8, parseSeedSha
$helpers = Get-Block $src '\/\/ ——— helpers ———' '\/\/ ——— 1\) Âncora ———'
if(-not $helpers){ throw "Bloco de helpers não encontrado no fonte." }

# Verificações no destino
$hasPanel   = [regex]::IsMatch($dst, 'id="func-id"', 'IgnoreCase')
$hasBtnIds  = [regex]::IsMatch($dst, 'btn-anchor|btn-jsonld|btn-hb|btn-openlog-aux', 'IgnoreCase')
$hasHelpers = [regex]::IsMatch($dst, 'function\s+toB64Utf8|function\s+parseSeedSha', 'IgnoreCase')

Write-Host "Destino: $Dst"
Write-Host (" - Painel: " + ($(if($hasPanel){"OK"}else{"FALTA"})))
Write-Host (" - Helpers/Handlers: " + ($(if($hasHelpers -and $hasBtnIds){"OK"}else{"FALTA"})))

if(-not $Apply){ Write-Host "`nUse -Apply para escrever as mudanças."; exit 0 }

# 4) Inserções (simples, conservadoras)
# Painel: inserir após o primeiro </aside> encontrado
if(-not $hasPanel){
  $dst = $dst -replace '(</aside\s*>\s*)', "`$1`r`n$panel`r`n"
}

# Helpers: inserir antes do fechamento do primeiro </script> principal
if(-not $hasHelpers){
  $dst = $dst -replace '(</script\s*>)', "`r`n$helpers`r`n`$1", 1
}

# Handlers: anexar ao final do mesmo <script>
if(-not $hasBtnIds){
  $dst = $dst -replace '(</script\s*>)', "`r`n$handlers`r`n`$1", 1
}

Set-Content -Path $Dst -Value $dst -Encoding UTF8
Write-Host "Aplicado em $Dst."
```

**Como usar**
- Só auditar:  
  `pwsh .\Sync-FunctionalIdentity.ps1`
- Aplicar:  
  `pwsh .\Sync-FunctionalIdentity.ps1 -Apply`

Ele procura:
- `<section class="panel" id="func-id">…</section>`
- Bloco `// ——— helpers ———` até `// ——— 1) Âncora ———`
- Bloco `// ——— 1) Âncora ———` até o fim do `// ——— 4) abrir log … ———`

Se preferir, eu já te entrego o **`func-id.js`** para seguir o Caminho A (1 fonte). Quer que eu gere esse arquivo modular agora?

---

