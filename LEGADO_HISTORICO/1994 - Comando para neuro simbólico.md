# 1994 - Comando para neuro simbólico

### USUÁRIO

o que um comando para pc assim que faz isso pode chegar na neuro symbolic agi:
“	1.	Busca/ memória leve: indexa seus .txt/.md em SQLite (TF-IDF) e responde perguntas trazendo os trechos mais relevantes (offline).
	2.	Simbologia fractal: gera SVG de fractais via L-systems a partir de axioma/regras (para explorar padrões/símbolos).
	3.	Ontologia mínima: grava triplas (s, p, o) em SQLite e exporta .ttl (liga conceitos de forma simples).
	4.	CLI PowerShell: atalhos pra rodar tudo com um comando. Tudo stdlib, sem dependências pesadas.”

---

### USUÁRIO

o que um comando para pc assim que faz isso pode chegar na neuro symbolic agi:

	•	teia_orchestrator.py substituído pelo seu, chamando teia_router_semi.py.
	•	Compat shims:
	•	teia_reasoner.py agora aceita --onto (alias de --db) e --out (alias de --explain).
	•	teia_tfidf_search.py aceita --mode ask e --q (alias de --ask).

Download do TEIA Neo Kit (drop-in aplicado)

textdoc embed Codex

# 1) importar fatos/regras MDF → ontologia + rules.json (opcional)
cd .\teia_neo_kit
python .\teia_import_mdf.py

# 2) indexar corpus
python .\teia_tfidf_search.py --mode index --db out\idx.sqlite

# 3) orquestrar (agora roteia via teia_router_semi.py por padrão)
python .\teia_orchestrator.py --q "selagem mdf em ambiente úmido" --db out\idx.sqlite --onto out\teia_onto.sqlite

# opções de roteador
python .\teia_orchestrator.py --q "desenhar glyph de umidade" --router heur
python .\teia_orchestrator.py --q "pipeline completo para responder pergunta técnica" --router none”

se quiser, eu ligo o teia_actions.yaml no planner por padrão (plano answered) pra te dar encadeamento declarativo imediato. 

---

### ASSISTENTE

Curto: isso que você descreveu é um “kit de IA pessoal” bem enxuto. Útil? Sim. Neuro-symbolic AGI? Nem perto — mais tipo um estagiário aplicado com boa memória, zero intuição e um hobby estranho com fractais. Ainda assim, dá pra empurrar essa ideia vários quilômetros na direção certa sem enfiar dependência pesada.

## Onde você está (e o que falta)
- **Memória/RAG TF-IDF (SQLite FTS5):** ótimo para “lembrar” trechos. **Falta** generalização (“neuro” de verdade), sumarização, aprendizado contínuo.
- **Simbologia fractal (L-systems):** rende visual legal. **Falta** “grounding” com conceitos/ontologia; hoje é só arte generativa.
- **Ontologia mínima (triples):** base boa. **Falta** um motor de regras (Datalog/Horn) e um **planner** (STRIPS/GOAP) para agir com objetivos.
- **CLI:** ótimo. **Falta** loop deliberar-agir-aprender (razão→ação→feedback).

## Como aproximar de “neuro-simbólico” sem depender de libs
### 1) De “TF-IDF” para “neuro-o-suficiente”
Implemente um **classificador leve** em puro Python para detectar a intenção da pergunta e escolher pipeline (buscar, inferir, gerar fractal, etc.). Um **Perceptron/Naive Bayes** de 50 linhas com hashing de palavras dá conta. É “neuro”? É o mínimo viável sem NumPy.

### 2) Raciocínio simbólico de verdade (regras + unificação)
Guarde regras como cláusulas de Horn e faça **encadeamento progressivo**. Tudo com `sqlite3` + um unificadorzinho.

```python
# reasoner.py (stdlib only)
from itertools import product

def match(pat, fact, theta=None):
    theta = dict(theta or {})
    for p,f in zip(pat, fact):
        if p.startswith("?"):
            if p in theta and theta[p]!=f: return None
            theta[p]=f
        elif p!=f: return None
    return theta

def apply(theta, tpl):
    return tuple(theta.get(x,x) for x in tpl)

def forward_chain(facts, rules, max_iters=5):
    facts = set(facts)
    for _ in range(max_iters):
        added = False
        for antecedents, consequent in rules:
            # pegue matches para cada antecedente e combine substituições
            pools = []
            for a in antecedents:
                pools.append([m for f in facts if (m:=match(a,f)) is not None])
            for combo in product(*pools):
                theta={}
                ok=True
                for m in combo:
                    for k,v in m.items():
                        if k in theta and theta[k]!=v: ok=False; break
                        theta[k]=v
                    if not ok: break
                if not ok: continue
                newf = apply(theta, consequent)
                if newf not in facts:
                    facts.add(newf); added=True
        if not added: break
    return facts

# Exemplo
facts = {("joao","type","humano"), ("joao","paiDe","ana")}
rules = [([("?x","paiDe","?y"),("?x","type","humano")], ("?y","type","humano"))]
print(forward_chain(facts, rules))
```

### 3) Planejamento (objetivos → ações do seu CLI)
Descreva **ações** com pré-condições/efeitos em triplas e rode uma busca (BFS/A*) no espaço de estados — dá pra fazer com 60 linhas. Assim seu “comando único” não só responde; ele **compõe procedimentos** (indexar → consultar → inferir → exportar) sozinho.

Representação (conceito):
```
action index(path):
  pre:  not indexed(path)
  add:  indexed(path)

action ask(q):
  pre:  indexed(notes)
  add:  answered(q)
```
O planner encontra sequência para atingir `answered(q)` e chama os subcomandos.

### 4) Memória de trabalho + explicabilidade
- **WM:** um buffer com top-k trechos do FTS5 + top-k fatos inferidos.
- **Traço de explicação:** logue {regra usada → fato criado} e mostre o “porquê” (ninguém acredita em “porque eu quis”, nem sua máquina).

### 5) “Grounding” leve pros fractais
Mapeie **conceitos → motivos L-system** via triplas (`("conceito","hasGlyph","nome_do_lsystem")`) e gere SVG junto com a resposta. Pelo menos os símbolos viram **notação visual consistente** em vez de decoração mística.

## Dicas pragmáticas (comandos/SQL que já funcionam)
**FTS5 no SQLite (TF-IDF/BM25 offline):**
```sql
CREATE VIRTUAL TABLE docs USING fts5(path, body, tokenize='porter');
-- inserir: INSERT INTO docs(path, body) VALUES (?, ?);
SELECT snippet(docs, 1, '', '', ' … ', 10) AS trecho, bm25(docs) AS score, path
FROM docs
WHERE docs MATCH ?
ORDER BY score LIMIT 5;
```

**Esquema de triplas + export TTL:**
```sql
CREATE TABLE IF NOT EXISTS triples (s TEXT, p TEXT, o TEXT);
CREATE INDEX IF NOT EXISTS idx_spo ON triples(s,p,o);
-- exporte assim:
-- SELECT s||' '||p||' '||CASE WHEN instr(o,' ')>0 THEN '"'||o||'"' ELSE o END||' .' FROM triples;
```

**PowerShell (atalhos sem depender de nada além de stdlib/SQLite):**
```powershell
function neo-index { param($dir)  python .\tools\index.py $dir }
function neo-ask   { param($q)    python .\tools\ask.py "$q" }
function neo-infer {              python .\tools\infer.py }
function neo-ttl   {              python .\tools\export_ttl.py > graph.ttl }
function neo-frac  { param($ax,$rules) python .\tools\lsys_svg.py "$ax" "$rules" }
# Pipeline “um comando”:
function neo { param($q) neo-index .\notes; neo-infer; neo-ask "$q" | Tee-Object -File out.svg }
```

**L-system para SVG (conceito):**
```
axiom: F
rules: F=F+F−F−F+F
```
Gere path SVG com pen-up/down; sem libs.

## O que isso te dá, de verdade
- Um **agente simbólico raso** com busca semântica que **explica** como chegou lá.
- Um cheirinho de “neuro” pra roteamento/heurística de decisão.
- Um **planner** que transforma perguntas em sequências de ações no seu próprio PC.

## O que ainda NÃO é (e nem finja)
- Não entende linguagem natural em geral, não percebe mundo, não aprende conceitos novos sem que você modele, e não “tem objetivos”. É um sistema neuro-simbólico **local, task-oriented**. AGI continua em outro CEP.

Se quiser, eu te desenho os arquivos `index.py`, `ask.py`, `infer.py`, `lsys_svg.py` no próximo passo — prometo manter curto o bastante pra caber no seu cérebro humano cansado. Enquanto isso, parabéns: você inventou um mini-cérebro com planilha e figurinhas. Isso é mais do que a maioria faz entre dois cafés.

---

### USUÁRIO

o que um comando para pc assim que faz isso pode chegar na neuro symbolic agi:

	•	teia_orchestrator.py substituído pelo seu, chamando teia_router_semi.py.
	•	Compat shims:
	•	teia_reasoner.py agora aceita --onto (alias de --db) e --out (alias de --explain).
	•	teia_tfidf_search.py aceita --mode ask e --q (alias de --ask).

Download do TEIA Neo Kit (drop-in aplicado)

textdoc embed Codex

# 1) importar fatos/regras MDF → ontologia + rules.json (opcional)
cd .\teia_neo_kit
python .\teia_import_mdf.py

# 2) indexar corpus
python .\teia_tfidf_search.py --mode index --db out\idx.sqlite

# 3) orquestrar (agora roteia via teia_router_semi.py por padrão)
python .\teia_orchestrator.py --q "selagem mdf em ambiente úmido" --db out\idx.sqlite --onto out\teia_onto.sqlite

# opções de roteador
python .\teia_orchestrator.py --q "desenhar glyph de umidade" --router heur
python .\teia_orchestrator.py --q "pipeline completo para responder pergunta técnica" --router none”

se quiser, eu ligo o teia_actions.yaml no planner por padrão (plano answered) pra te dar encadeamento declarativo imediato. 

---

### USUÁRIO

curtíssimo, sem rodeios:
	•	peguei teu feedback e subi o nível do kit: agora tem roteador de intenção (NB + heurística), reasoner com regras de Horn, planner STRIPS-like, buffer de memória de trabalho + explicações, e grounding fractal via hasGlyph.
	•	continua 100% stdlib, sem dependências pesadas.

Download do TEIA Neo-Symbolic Microstack (v2)

textdoc embed Codex

# 1) entrar na pasta
cd .\teia_neo_kit

# 2) indexar seus textos
python .\teia_tfidf_search.py --mode index --db out\idx.sqlite

# 3) rodar o orquestrador (roteia → age → salva explicação)
python .\teia_orchestrator.py --q "selagem mdf em ambiente úmido" --db out\idx.sqlite --onto out\teia_onto.sqlite

# 4) ver saídas (memória de trabalho, explicações, glyph)
type .\out\wm.json
type .\out\explain.json
start .\out\glyph.svg

o que cada peça faz agora (bem direto):
	•	teia_router.py: decide “search / infer / fractal / plan” a partir da pergunta.
	•	teia_reasoner.py: lê triplas do SQLite, aplica regras de Horn (unificação), salva fatos novos + out/explain.json.
	•	teia_planner.py: encontra sequência de ações para metas simples (answered(q), glyph_built(c)), baseado em pré/efeitos.
	•	teia_orchestrator.py: laço deliberar→agir→feedback: usa router, executa o pipeline, guarda WM (out/wm.json).
	•	teia_fractal_svg.py: gera SVG; agora aceita --glyph com motivos de glyphs.json (grounding).
	•	teia_tfidf_search.py: memória/busca leve (TF-IDF).
	•	teia_ontology_sqlite.py: triplas + export TTL (se quiser).

se quiser, eu já deixo:
	•	ações/plano mais ricos (com chamada encadeada index→reasoner→query),
	•	regras de exemplo para teu domínio MDF,
	•	e um roteador “semi-supervisionado” com dataset editável. 

---

### ASSISTENTE

Você montou um pipeline neuro-simbólico decente (importa MDF → ontologia+regras, indexa corpus TF-IDF, orquestra via router). “AGI”? Calma, Einstein de teclado — isso aqui é um RAG simbólico esperto, não um oráculo. Mas sim, dá pra amarrar num comando único e parecer que você sabe o que está fazendo.

# One-liner (PowerShell, Windows)
Copia e cola isso no **PowerShell** (não no CMD), a partir da pasta que contém `teia_neo_kit`:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "
cd .\teia_neo_kit;
python .\teia_import_mdf.py;
python .\teia_tfidf_search.py --mode index --db .\out\idx.sqlite;
python .\teia_orchestrator.py --q 'selagem mdf em ambiente úmido' --db .\out\idx.sqlite --onto .\out\teia_onto.sqlite
"
```
Isso executa: (1) importação MDF → `out\teia_onto.sqlite` (+ `rules.json` se houver), (2) indexação TF-IDF em `out\idx.sqlite`, (3) pergunta passando pelo roteador padrão `teia_router_semi.py`.

# Variações rápidas do roteador
Quer forçar modos específicos? Troque só a última linha:
```powershell
# heurístico (ex: pedir um glyph)
python .\teia_orchestrator.py --q 'desenhar glyph de umidade' --router heur --db .\out\idx.sqlite --onto .\out\teia_onto.sqlite

# sem roteador (pipeline “cru”)
python .\teia_orchestrator.py --q 'pipeline completo para responder pergunta técnica' --router none --db .\out\idx.sqlite --onto .\out\teia_onto.sqlite
```

# “Compat shims” úteis (porque claro que mudaram flags)
- **Reasoner**:
  ```powershell
  python .\teia_reasoner.py --onto .\out\teia_onto.sqlite --out .\out\exp.json
  ```
  (`--onto` = alias de `--db`; `--out` = alias de `--explain`)
- **Busca standalone**:
  ```powershell
  python .\teia_tfidf_search.py --mode ask --q 'sua pergunta' --db .\out\idx.sqlite
  ```

# Qual o “ganho” neuro-simbólico aqui?
- **Simbólico**: ontologia + `rules.json` estruturam o domínio e permitem explicabilidade.
- **Neural/estatístico**: TF-IDF faz recuperação rápida do texto relevante (o seu “R” do RAG sem drama).
- **Orquestração**: o router decide quando buscar, quando raciocinar e como encadear — com o seu `teia_actions.yaml` plugado no planner por padrão, você já ganha encadeamento declarativo (“plano `answered`”) sem mudar o comando.

Se quiser classe em vez de gambiarra: jogue isso num `teia-ask.ps1` e chame como função, mas já te conheço — você vai viver de copiar e colar até a aposentadoria.

---

### ASSISTENTE

Boa. Agora parece um kit que quase não me dá vergonha alheia. Toma o que prometeu — curtíssimo e plug-and-play.

### `teia_actions.yaml` (pipeline encadeado index→reasoner→query→glyph)
```yaml
actions:
  - name: index_notes
    params: [dir]
    pre:  ["exists({dir})", "not indexed({dir})"]
    add:  ["indexed({dir})"]

  - name: reason_about
    params: [topic]
    pre:  ["ontology_loaded()", "any_triples()"]
    add:  ["inferred(topic:{topic})", "explain_written()"]

  - name: search_answer
    params: [q, db]
    pre:  ["indexed(*)"]
    add:  ["candidates(q:{q})"]

  - name: build_glyph
    params: [concept]
    pre:  ["hasGlyph({concept}, ?g)"]
    add:  ["glyph_built({concept})"]

  - name: answer
    params: [q]
    pre:  ["candidates(q:{q})", "inferred(*)"]
    add:  ["answered({q})", "wm_written()"]

  - name: export_ttl
    params: []
    pre:  ["any_triples()"]
    add:  ["ttl_exported(out/graph.ttl)"]

plans:
  answered: ["index_notes", "reason_about", "search_answer", "answer"]
  glyph_built: ["build_glyph"]
```

### `mdf_rules.json` (regras Horn + fatos iniciais)
```json
{
  "facts": [
    ["prat_banho","type","MDF"],
    ["prat_banho","ambiente","umido"],
    ["prat_banho","borda","exposta"],
    ["selante_pu","type","poliuretano"],
    ["selante_epoxi","type","epoxi"]
  ],
  "rules": [
    { "if": [["?x","type","MDF"],["?x","ambiente","umido"]],
      "then": ["?x","requer","selagem"] },

    { "if": [["?x","borda","exposta"]],
      "then": ["?x","risco","inchaco_alto"] },

    { "if": [["?x","requer","selagem"],["selante_pu","type","poliuretano"]],
      "then": ["?x","selarCom","poliuretano"] },

    { "if": [["?x","requer","selagem"],["selante_epoxi","type","epoxi"]],
      "then": ["?x","alternativa","epoxi"] },

    { "if": [["?x","selarCom","poliuretano"]],
      "then": ["?x","passos","lixar→selar(2~3 mãos)→selar_bordas→cura(72h)"] }
  ],
  "glyphs": [
    ["MDF","hasGlyph","mdf_fibra"],
    ["umido","hasGlyph","onda"],
    ["selagem","hasGlyph","escudo"]
  ]
}
```

### `router_ds.csv` (dataset editável, rótulos: search|infer|fractal|plan)
```
text,label
"selagem mdf em ambiente úmido",plan
"o que é MDF e diferenças para MDP",search
"derivar riscos de borda exposta no banheiro",infer
"gerar símbolo para 'selagem'",fractal
"como preparar superfície antes do selante",search
"qual selante usar em MDF úmido",plan
"provar que se borda exposta então risco alto",infer
"desenhar glyph de umidade",fractal
"pipeline completo para responder pergunta técnica",plan
```

### `router_heuristics.json` (regras rápidas antes do NB)
```json
[
  {"pattern": "(plano|pipeline|sequ[eê]ncia|responder pergunta)", "label": "plan"},
  {"pattern": "(glyph|símbolo|desenhar|fractal)", "label": "fractal"},
  {"pattern": "(provar|deduzir|se .* ent[aã]o|regra)", "label": "infer"},
  {"pattern": "(o que|qual|como) ", "label": "search"}
]
```

### `teia_router_semi.py` (semi-supervisionado leve; stdlib)
```python
# lê router_ds.csv, aplica heurística, treina NB, salva incertos em out/router_todo.csv
import csv, re, math, os, json, sys
from collections import Counter, defaultdict

DS="router_ds.csv"; HJ="router_heuristics.json"; OUT="out/router_todo.csv"
os.makedirs("out", exist_ok=True)

def heur_label(text, rules):
    for r in rules:
        if re.search(r["pattern"], text, re.I): return r["label"]
    return None

def tokenize(s):
    return [w for w in re.findall(r"\b[\wáéíóúãõç]+\b", s.lower()) if len(w)>1]

# NB multinomial simples
class NB:
    def __init__(self): self.cls=Counter(); self.ft=defaultdict(Counter); self.v=Counter()
    def fit(self, rows):
        for x,y in rows:
            self.cls[y]+=1
            for t in tokenize(x):
                self.ft[y][t]+=1; self.v[t]+=1
        self.N=sum(self.cls.values())
    def predict_proba(self, x):
        toks=tokenize(x); V=len(self.v) or 1
        out={}
        for y in self.cls:
            logp=math.log(self.cls[y]/self.N)
            denom=sum(self.ft[y].values())+V
            for t in toks:
                logp+=math.log((self.ft[y][t]+1)/denom)
            out[y]=logp
        # softmax
        m=max(out.values()); sm={k:math.exp(v-m) for k,v in out.items()}
        Z=sum(sm.values()); return {k:v/Z for k,v in sm.items()}
    def predict(self, x):
        p=self.predict_proba(x); return max(p, key=p.get), p

rules=json.load(open(HJ))
rows=[]
with open(DS, newline='', encoding='utf-8') as f:
    r=csv.DictReader(f); rows=[(d["text"], d["label"]) for d in r]

nb=NB(); nb.fit(rows)

def route(q):
    h=heur_label(q, rules)
    if h: return h, {"via":"heur"}
    y,p=nb.predict(q); conf=max(p.values())
    if conf<0.55:
        # log para rotular depois
        new = not os.path.exists(OUT)
        with open(OUT,"a", newline='', encoding="utf-8") as f:
            w=csv.writer(f); 
            if new: w.writerow(["text","pred","conf"])
            w.writerow([q,y,f"{conf:.2f}"])
    return y, {"via":"nb","conf":round(conf,2)}

if __name__=="__main__":
    q=" ".join(sys.argv[1:]) or "selagem mdf em ambiente úmido"
    y,meta=route(q); print(y, meta)
```

Pronto. Agora seu “TEIA Neo” realmente parece um microcérebro com carteira de trabalho. Quer que eu jogue um conjunto mínimo de **triplas MDF** maior ou vai fingir que já entendeu?

---

### USUÁRIO

ahaha, perfeito. pra ficar “classe” de verdade, deixei um wrapper pronto.

Download do TEIA Neo Kit (com teia_ask.ps1)

textdoc embed Codex

# uso básico (PowerShell, rodar dentro da pasta que contém teia_neo_kit)
cd .\teia_neo_kit

# one-liner civilizado
.\teia_ask.ps1 -Question 'selagem mdf em ambiente úmido' -ImportMDF -Reindex -Open

# variações do roteador
.\teia_ask.ps1 -Question 'desenhar glyph de umidade' -Router heur
.\teia_ask.ps1 -Question 'pipeline completo para responder pergunta técnica' -Router none

# opções:
#   -ImportMDF  → roda teia_import_mdf.py (carrega fatos/glyphs e salva rules.json)
#   -Reindex    → recria o índice TF-IDF em out\idx.sqlite
#   -Open       → abre wm.json, explain.json e glyph.svg no final
#   -Db / -Onto → paths customizados (default: out\idx.sqlite / out\teia_onto.sqlite)

pronto: um comando só, sem gambiarra visual, e com a sua rota semi-supervisionada por padrão. Quer que eu também “amarre” o teia_actions.yaml num runner declarativo depois? Eu encaixo sem puxar PyYAML (faço um parserzinho só pro nosso formato).

---

### USUÁRIO

feito. arquivos criados e prontos pra uso — curtíssimo e plug-and-play.

Download do TEIA Neo Kit (plus)

textdoc embed Codex

# 1) importar fatos/regras MDF → ontologia + rules.json
cd .\teia_neo_kit
python .\teia_import_mdf.py

# 2) indexar seus textos
python .\teia_tfidf_search.py --mode index --db out\idx.sqlite

# 3) pipeline rápido (orquestrador padrão)
python .\teia_orchestrator.py --q "selagem mdf em ambiente úmido" --db out\idx.sqlite --onto out\teia_onto.sqlite

# 4) opcional: usar roteador semi
python .\teia_router_semi.py "pipeline completo para responder pergunta técnica"

incluído no pacote:
	•	teia_actions.yaml — plano encadeado index→reasoner→query→glyph.
	•	mdf_rules.json — fatos, regras Horn e glyphs do domínio MDF.
	•	teia_import_mdf.py — importa fatos/glyphs no SQLite e salva rules.json.
	•	router_ds.csv + router_heuristics.json + teia_router_semi.py — roteador semi-supervisionado leve.

se quiser, troco o orquestrador pra usar o teia_router_semi.py por padrão num próximo passo. 

---

### ASSISTENTE

Lindo. Agora ficou “classe” de verdade — tipo terno slim num PC com poeira de 2009. Já amarrei o `teia_actions.yaml` num runner declarativo **sem PyYAML**, com parserzinho nosso. Tá tudo aqui embaixo: wrapper PowerShell revisado + runner Python + exemplo de `teia_actions.yaml`. Copia, cola, finge que sempre foi assim.

# teia_ask.ps1 (wrapper com ações declarativas)
Salve como `.\teia_neo_kit\teia_ask.ps1`:
```powershell
param(
  [Parameter(Mandatory=$true)] [string] $Question,
  [ValidateSet('semi','heur','none')] [string] $Router = 'semi',
  [string] $Db   = 'out\idx.sqlite',
  [string] $Onto = 'out\teia_onto.sqlite',
  [switch] $ImportMDF,
  [switch] $Reindex,
  [switch] $Open,
  [switch] $UseActions,
  [string] $ActionsPath = '.\teia_actions.yaml',
  [string] $PythonExe = 'python'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $here
try {
  if (-not (Test-Path -LiteralPath 'out')) { New-Item -ItemType Directory -Path 'out' | Out-Null }

  function Invoke-Step([string]$Exe, [string[]]$Args) {
    Write-Host "» $Exe $($Args -join ' ')" -ForegroundColor Cyan
    & $Exe @Args
  }

  if ($ImportMDF) {
    Invoke-Step $PythonExe @('.\teia_import_mdf.py')
  }

  if ($Reindex) {
    Invoke-Step $PythonExe @('.\teia_tfidf_search.py','--mode','index','--db',$Db)
  }

  if ($UseActions -and (Test-Path -LiteralPath $ActionsPath)) {
    Invoke-Step $PythonExe @('.\teia_actions_runner.py',
      '--actions',$ActionsPath,'--q',$Question,'--db',$Db,'--onto',$Onto,'--router',$Router,
      $(if($ImportMDF){'--import_mdf'}),'',
      $(if($Reindex){'--reindex'}),'',
      $(if($Open){'--open_out'}),''
    )
  } else {
    # caminho “clássico”: orquestrador direto
    Invoke-Step $PythonExe @('.\teia_orchestrator.py','--q',$Question,'--db',$Db,'--onto',$Onto,'--router',$Router)
  }

  if ($Open -and -not $UseActions) {
    foreach ($f in @('.\out\wm.json','.\out\explain.json','.\out\glyph.svg')) {
      if (Test-Path -LiteralPath $f) { Invoke-Item $f }
    }
  }
}
finally { Pop-Location }
```

# teia_actions_runner.py (parserzinho YAML-lite + executor)
Salve como `.\teia_neo_kit\teia_actions_runner.py`:
```python
#!/usr/bin/env python
# -*- coding: utf-8 -*-
import argparse, subprocess, sys, os, shlex

def YAML_lite_load(text):
    """
    Parser bem simples para um subconjunto do YAML:
      - mapeamentos chave: valor (sem aninhamento maluco)
      - listas com '- ' e itens como mapas (1 nível de indent = 2 espaços)
      - strings simples (sem escape); true/false/1/0 viram bool
    É o suficiente pro nosso teia_actions.yaml.
    """
    def to_scalar(v):
        v = v.strip()
        if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
            v = v[1:-1]
        lv = v.lower()
        if lv in ('true','yes','on','1'): return True
        if lv in ('false','no','off','0'): return False
        return v

    lines = [ln.rstrip('\n') for ln in text.splitlines() if ln.strip() and not ln.strip().startswith('#')]
    i, n = 0, len(lines)
    root = {}
    cur_key = None
    while i < n:
        ln = lines[i]
        if ln.startswith('- '): raise ValueError("Lista no topo não suportada; use chave: e depois '- '")
        if ':' in ln:
            key, val = ln.split(':', 1)
            key = key.strip()
            if val.strip() == '':
                # pode ser início de lista
                # olha próxima linha
                if i+1 < n and lines[i+1].lstrip().startswith('- '):
                    arr = []
                    i += 1
                    while i < n and lines[i].lstrip().startswith('- '):
                        item_line = lines[i]
                        # pega o bloco do item (linhas subsequentes com indent > item)
                        item_indent = len(item_line) - len(item_line.lstrip())
                        # parse item como mapa flat de linhas identadas
                        item = {}
                        # primeira linha do item pode conter chave/valor após '- '
                        head = item_line.lstrip()[2:].strip()
                        if head:
                            if ':' in head:
                                k2, v2 = head.split(':',1)
                                item[k2.strip()] = to_scalar(v2)
                            else:
                                item['run'] = to_scalar(head)
                        i += 1
                        while i < n:
                            ln2 = lines[i]
                            indent2 = len(ln2) - len(ln2.lstrip())
                            if indent2 <= item_indent: break
                            if ':' in ln2:
                                k3, v3 = ln2.strip().split(':',1)
                                item[k3.strip()] = to_scalar(v3)
                            i += 1
                        arr.append(item)
                    root[key] = arr
                    continue  # já avançamos i dentro do loop
                else:
                    root[key] = {}
            else:
                root[key] = to_scalar(val)
        i += 1
    return root

def render(template, ctx):
    out = template
    for k,v in ctx.items():
        out = out.replace('{{ '+k+' }}', str(v)).replace('{{'+k+'}}', str(v))
    return out

def truthy(val):
    if isinstance(val, bool): return val
    s = str(val).strip().lower()
    return s in ('1','true','yes','on')

def run_shell(cmd):
    print(f"» {cmd}", flush=True)
    # Usa shell=True por praticidade neste contexto controlado
    completed = subprocess.run(cmd, shell=True)
    if completed.returncode != 0:
        raise RuntimeError(f"Comando falhou: {cmd}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--actions', default='teia_actions.yaml')
    ap.add_argument('--q', '--question', dest='q', required=True)
    ap.add_argument('--db', default='out/idx.sqlite')
    ap.add_argument('--onto', default='out/teia_onto.sqlite')
    ap.add_argument('--router', default='semi')
    ap.add_argument('--import_mdf', action='store_true')
    ap.add_argument('--reindex', action='store_true')
    ap.add_argument('--open_out', action='store_true')
    args = ap.parse_args()

    with open(args.actions, 'r', encoding='utf-8') as f:
        data = YAML_lite_load(f.read())

    # contexto base (CLI sobrescreve vars do arquivo)
    ctx = {}
    ctx.update(data.get('vars', {}))
    ctx.update({
        'q': args.q,
        'db': args.db.replace('\\','/'),
        'onto': args.onto.replace('\\','/'),
        'router': args.router,
        'router_flag': f"--router {args.router}" if args.router else "",
        'import_mdf': args.import_mdf,
        'reindex': args.reindex,
        'open_out': args.open_out,
    })

    steps = data.get('steps', [])
    if not isinstance(steps, list):
        print("Arquivo de ações sem 'steps' válidos.", file=sys.stderr)
        sys.exit(2)

    for step in steps:
        name = step.get('name', 'step')
        cond = step.get('when', None)
        if cond is not None:
            rendered = render(str(cond), ctx)
            if not truthy(rendered):
                print(f"• pulando {name} (condição falsa)")
                continue
        cmd = render(str(step.get('run','')), ctx)
        if not cmd:
            print(f"• pulando {name} (sem comando)")
            continue
        run_shell(cmd)

if __name__ == '__main__':
    main()
```

# teia_actions.yaml (exemplo mínimo, declarativo)
Salve como `.\teia_neo_kit\teia_actions.yaml`:
```yaml
# vars default (CLI sobrescreve)
vars:
  db: out/idx.sqlite
  onto: out/teia_onto.sqlite
  open_out: false

steps:
  - name: import_mdf
    when: "{{ import_mdf }}"
    run: python ./teia_import_mdf.py

  - name: reindex
    when: "{{ reindex }}"
    run: python ./teia_tfidf_search.py --mode index --db "{{ db }}"

  - name: orchestrate
    run: python ./teia_orchestrator.py --q "{{ q }}" --db "{{ db }}" --onto "{{ onto }}" {{ router_flag }}

  - name: open_artifacts
    when: "{{ open_out }}"
    run: powershell -NoProfile -Command "ii ./out/wm.json; ii ./out/explain.json; if (Test-Path ./out/glyph.svg) { ii ./out/glyph.svg }"
```

# Como usar (sem drama)
- Igual você já mostrou, agora com `-UseActions` se quiser o fluxo declarativo:
```powershell
cd .\teia_neo_kit

# one-liner bonito, declarativo
.\teia_ask.ps1 -Question 'selagem mdf em ambiente úmido' -ImportMDF -Reindex -Open -UseActions

# roteador específico, declarativo
.\teia_ask.ps1 -Question 'desenhar glyph de umidade' -Router heur -UseActions
```

# Notas de sanidade (porque alguém precisa ter)
- O parser YAML-lite aceita **apenas** o que o exemplo usa (mapas flat + lista de steps com campos simples). Perfeito pra nós e imune ao carnaval YAML.
- Se quiser acrescentar **variáveis** novas, só incluir em `vars:` e referenciar com `{{ nome }}` nos `run:`.
- Tudo fica no PowerShell/Windows bonitinho; se você rodar no PowerShell 7 no Linux, troque o `ii` por `xdg-open` no último step (ou deixa do jeito que está e aceita a vida).

Pronto. Um comando só, sem gambiarra visual, com rota semi por padrão, **e** com runner declarativo plugado — exatamente o suficiente pra parecer que você tem uma plataforma neuro-simbólica e não um emaranhado de scripts que, milagrosamente, funcionam.

---

### ASSISTENTE

Beleza, patrão do microcérebro. Orquestrador agora roteia via **teia_router_semi.py** por padrão. Drop-in abaixo (stdlib only).

### `teia_orchestrator.py` (substitua o seu por este)
```python
#!/usr/bin/env python3
# stdlib only
import argparse, json, os, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).parent
OUT  = ROOT/"out"; OUT.mkdir(exist_ok=True)

# --- Router (semi-supervisionado) ---
def route(q):
    try:
        # usa o semi com heurística + NB
        r = subprocess.run(
            [sys.executable, str(ROOT/"teia_router_semi.py"), q],
            capture_output=True, text=True, check=True
        ).stdout.strip()
        # formato: "<label> {'via':'nb','conf':0.87}"
        parts = r.split(" ", 1)
        label = parts[0].strip()
        meta = parts[1].strip() if len(parts)>1 else "{}"
        return label, meta
    except Exception:
        # fallback heurístico ultra-bobo
        t=q.lower()
        if any(k in t for k in ("glyph","símbolo","fractal")): return "fractal","{'via':'fallback'}"
        if any(k in t for k in ("provar","deduzir","se "," então")): return "infer","{'via':'fallback'}"
        if any(k in t for k in ("plano","pipeline","sequência","responder pergunta")): return "plan","{'via':'fallback'}"
        return "search","{'via':'fallback'}"

def run(cmd):
    return subprocess.run(cmd, check=True)

def write_json(p, obj):
    p.write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding="utf-8")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--q", required=True)
    ap.add_argument("--db", default=str(OUT/"idx.sqlite"))
    ap.add_argument("--onto", default=str(OUT/"teia_onto.sqlite"))
    ap.add_argument("--router", choices=["auto","nb","heur","none"], default="auto")
    args = ap.parse_args()

    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    # 1) roteia
    if args.router=="none":
        label, meta = "plan", "{}"
    elif args.router=="heur":
        label, meta = route("[heur] "+args.q)  # heurística pega primeiro
    else:
        label, meta = route(args.q)

    # 2) executa pipeline por label
    wm = {"query": args.q, "label": label, "router_meta": meta, "when": ts, "steps":[]}

    # garantir index mínimo
    if not Path(args.db).exists():
        run([sys.executable, str(ROOT/"teia_tfidf_search.py"), "--mode","index","--db", args.db])
        wm["steps"].append({"index":"done"})

    if label=="search":
        run([sys.executable, str(ROOT/"teia_tfidf_search.py"), "--mode","ask","--db", args.db, "--q", args.q])
        wm["steps"].append({"search":"done"})

    elif label=="infer":
        # supõe ontologia já importada
        run([sys.executable, str(ROOT/"teia_reasoner.py"), "--onto", args.onto, "--out", str(OUT/"explain.json")])
        wm["steps"].append({"infer":"done"})

    elif label=="fractal":
        # tenta puxar conceito principal da pergunta (tosco mas funcional)
        concept = args.q.split()[0]
        run([sys.executable, str(ROOT/"teia_fractal_svg.py"), "--glyph", concept, "--out", str(OUT/"glyph.svg")])
        wm["steps"].append({"fractal": concept})

    elif label=="plan":
        # pipeline encadeado: reasoner → search → (opcional glyph)
        run([sys.executable, str(ROOT/"teia_reasoner.py"), "--onto", args.onto, "--out", str(OUT/"explain.json")])
        wm["steps"].append({"infer":"done"})
        run([sys.executable, str(ROOT/"teia_tfidf_search.py"), "--mode","ask","--db", args.db, "--q", args.q])
        wm["steps"].append({"search":"done"})
        # se pergunta mencionar glyph, gera também
        if "glyph" in args.q.lower() or "símbolo" in args.q.lower():
            concept = args.q.split()[-1]
            run([sys.executable, str(ROOT/"teia_fractal_svg.py"), "--glyph", concept, "--out", str(OUT/"glyph.svg")])
            wm["steps"].append({"fractal": concept})

    # 3) salva WM
    write_json(OUT/"wm.json", wm)
    print(f"[TEIA] {label} :: ver out/wm.json, out/explain.json, out/glyph.svg (se houver)")

if __name__=="__main__":
    main()
```

### Uso (igual ao seu, agora com roteador por padrão)
```bash
python .\teia_orchestrator.py --q "selagem mdf em ambiente úmido" --db out\idx.sqlite --onto out\teia_onto.sqlite
```
Opcional:
```bash
# força heurística
python .\teia_orchestrator.py --q "desenhar glyph de umidade" --router heur
# sem roteador (cai direto no plano padrão)
python .\teia_orchestrator.py --q "pipeline completo para responder pergunta técnica" --router none
```

Se quebrar, é porque você digitou algo humano. Se funcionar, fui eu.

---

### USUÁRIO

brabo. integrei seu wrapper + runner declarativo + YAML-lite, prontos pra colar e rodar.

Download do TEIA Neo Kit (com runner declarativo)

textdoc embed Codex

# 1) entrar na pasta do kit
cd .\teia_neo_kit

# 2) one-liner “classe” (decl.: importa MDF, reindexa, roteia semi e abre artefatos)
.\teia_ask.ps1 -Question 'selagem mdf em ambiente úmido' -ImportMDF -Reindex -Open -UseActions

# 3) variações do roteador (decl.)
.\teia_ask.ps1 -Question 'desenhar glyph de umidade' -Router heur -UseActions
.\teia_ask.ps1 -Question 'pipeline completo para responder pergunta técnica' -Router none -UseActions

# 4) modo clássico (sem actions)
.\teia_ask.ps1 -Question 'qual selante usar em MDF úmido' -ImportMDF -Reindex -Open

o que adicionei agora:
	•	teia_ask.ps1 (revisado): liga o runner declarativo via -UseActions, com flags -ImportMDF, -Reindex, -Open.
	•	teia_actions_runner.py: parser YAML-lite (mapas + lista de steps) e executor de comandos com {{ variáveis }}.
	•	teia_actions.yaml (exemplo): import_mdf → reindex → orchestrate → open_artifacts, com router_flag automático.

se quiser, eu plugo um vars.router='semi' por default no YAML e adiciono step opcional export_ttl. Quer também um step “glyph_if_mentioned” com regex no runner? 

---

### ASSISTENTE

Tá na mão, chefe da gambiarra elegante. Coloquei **router default no YAML**, **step opcional `export_ttl`**, e um **`glyph_if_mentioned`** que liga o heurístico só quando a pergunta menciona “glyph/glifo/ícone”. Também dei um tapa no runner: `when_regex`, `when_contains` e `continue_on_error`. Classe de verdade, sem precisar implorar pro PyYAML.

# teia_ask.ps1 (atualizado)
```powershell
param(
  [Parameter(Mandatory=$true)] [string] $Question,
  [ValidateSet('semi','heur','none')] [string] $Router = 'semi',
  [string] $Db   = 'out\idx.sqlite',
  [string] $Onto = 'out\teia_onto.sqlite',
  [switch] $ImportMDF,
  [switch] $Reindex,
  [switch] $Open,
  [switch] $UseActions,
  [switch] $ExportTTL,
  [string] $ActionsPath = '.\teia_actions.yaml',
  [string] $PythonExe = 'python'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $here
try {
  if (-not (Test-Path -LiteralPath 'out')) { New-Item -ItemType Directory -Path 'out' | Out-Null }

  function Invoke-Step([string]$Exe, [string[]]$Args) {
    Write-Host "» $Exe $($Args -join ' ')" -ForegroundColor Cyan
    & $Exe @Args
  }

  if ($ImportMDF) { Invoke-Step $PythonExe @('.\teia_import_mdf.py') }
  if ($Reindex)   { Invoke-Step $PythonExe @('.\teia_tfidf_search.py','--mode','index','--db',$Db) }

  if ($UseActions -and (Test-Path -LiteralPath $ActionsPath)) {
    Invoke-Step $PythonExe @(
      '.\teia_actions_runner.py',
      '--actions',$ActionsPath,'--q',$Question,'--db',$Db,'--onto',$Onto,'--router',$Router,
      $(if($ImportMDF){'--import_mdf'}),'',
      $(if($Reindex){'--reindex'}),'',
      $(if($Open){'--open_out'}),'',
      $(if($ExportTTL){'--export_ttl'}),''
    )
  } else {
    Invoke-Step $PythonExe @('.\teia_orchestrator.py','--q',$Question,'--db',$Db,'--onto',$Onto,'--router',$Router)
    if ($Open) {
      foreach ($f in @('.\out\wm.json','.\out\explain.json','.\out\glyph.svg')) { if (Test-Path $f) { Invoke-Item $f } }
    }
  }
}
finally { Pop-Location }
```

# teia_actions_runner.py (atualizado, com regex e tolerância a erro)
```python
#!/usr/bin/env python
# -*- coding: utf-8 -*-
import argparse, subprocess, sys, os, re

def YAML_lite_load(text):
    def to_scalar(v):
        v = v.strip()
        if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
            v = v[1:-1]
        lv = v.lower()
        if lv in ('true','yes','on','1'): return True
        if lv in ('false','no','off','0'): return False
        return v
    lines = [ln.rstrip('\n') for ln in text.splitlines() if ln.strip() and not ln.strip().startswith('#')]
    i, n = 0, len(lines)
    root = {}
    while i < n:
        ln = lines[i]
        if ':' in ln:
            key, val = ln.split(':', 1)
            key = key.strip()
            if val.strip() == '':
                if i+1 < n and lines[i+1].lstrip().startswith('- '):
                    arr = []
                    i += 1
                    while i < n and lines[i].lstrip().startswith('- '):
                        item_line = lines[i]
                        item_indent = len(item_line) - len(item_line.lstrip())
                        item = {}
                        head = item_line.lstrip()[2:].strip()
                        if head:
                            if ':' in head:
                                k2, v2 = head.split(':',1)
                                item[k2.strip()] = to_scalar(v2)
                            else:
                                item['run'] = to_scalar(head)
                        i += 1
                        while i < n:
                            ln2 = lines[i]
                            indent2 = len(ln2) - len(ln2.lstrip())
                            if indent2 <= item_indent: break
                            if ':' in ln2:
                                k3, v3 = ln2.strip().split(':',1)
                                item[k3.strip()] = to_scalar(v3)
                            i += 1
                        arr.append(item)
                    root[key] = arr
                    continue
                else:
                    root[key] = {}
            else:
                root[key] = to_scalar(val)
        i += 1
    return root

def render(template, ctx):
    out = template
    for k,v in ctx.items():
        out = out.replace('{{ '+k+' }}', str(v)).replace('{{'+k+'}}', str(v))
    return out

def truthy(val):
    if isinstance(val, bool): return val
    s = str(val).strip().lower()
    return s in ('1','true','yes','on')

def run_shell(cmd, ignore_error=False):
    print(f"» {cmd}", flush=True)
    rc = subprocess.call(cmd, shell=True)
    if rc != 0 and not ignore_error:
        raise RuntimeError(f"Comando falhou: {cmd}")

def step_condition_ok(step, ctx):
    # when: bool string
    if 'when' in step:
        if not truthy(render(str(step['when']), ctx)): return False
    # when_contains: substring (por padrão em q)
    if 'when_contains' in step:
        needle = render(str(step['when_contains']), ctx)
        hay = render(str(step.get('in','{{ q }}')), ctx)
        if needle.lower() not in hay.lower(): return False
    # when_regex: regex (por padrão em q)
    if 'when_regex' in step:
        pattern = render(str(step['when_regex']), ctx)
        hay = render(str(step.get('in','{{ q }}')), ctx)
        if re.search(pattern, hay, flags=re.I) is None: return False
    return True

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--actions', default='teia_actions.yaml')
    ap.add_argument('--q', '--question', dest='q', required=True)
    ap.add_argument('--db', default='out/idx.sqlite')
    ap.add_argument('--onto', default='out/teia_onto.sqlite')
    ap.add_argument('--router', default='semi')
    ap.add_argument('--import_mdf', action='store_true')
    ap.add_argument('--reindex', action='store_true')
    ap.add_argument('--open_out', action='store_true')
    ap.add_argument('--export_ttl', action='store_true')
    args = ap.parse_args()

    with open(args.actions, 'r', encoding='utf-8') as f:
        data = YAML_lite_load(f.read())

    ctx = {}
    ctx.update(data.get('vars', {}))
    ctx.update({
        'q': args.q,
        'db': args.db.replace('\\','/'),
        'onto': args.onto.replace('\\','/'),
        'router': args.router,
        'router_flag': f"--router {args.router}" if args.router else "",
        'import_mdf': args.import_mdf,
        'reindex': args.reindex,
        'open_out': args.open_out,
        'export_ttl': args.export_ttl,
    })
    # flags derivadas
    is_glyph = re.search(r'\b(glyph|glifo|ícone|icone)\b', ctx['q'], flags=re.I) is not None
    ctx.update({'is_glyph': is_glyph, 'not_glyph': (not is_glyph)})

    steps = data.get('steps', [])
    if not isinstance(steps, list):
        print("Arquivo de ações sem 'steps' válidos.", file=sys.stderr)
        sys.exit(2)

    for step in steps:
        name = step.get('name', 'step')
        if not step_condition_ok(step, ctx):
            print(f"• pulando {name} (condição não satisfeita)")
            continue
        cmd = render(str(step.get('run','')), ctx)
        if not cmd:
            print(f"• pulando {name} (sem comando)")
            continue
        ignore = truthy(step.get('continue_on_error', False))
        try:
            run_shell(cmd, ignore_error=ignore)
        except Exception as e:
            print(f"× {name} falhou: {e}", file=sys.stderr)
            sys.exit(1)

if __name__ == '__main__':
    main()
```

# teia_actions.yaml (atualizado, com defaults, glyph e export_ttl)
```yaml
vars:
  router: semi         # default pedido
  db: out/idx.sqlite
  onto: out/teia_onto.sqlite
  open_out: false

steps:
  - name: import_mdf
    when: "{{ import_mdf }}"
    run: python ./teia_import_mdf.py

  - name: reindex
    when: "{{ reindex }}"
    run: python ./teia_tfidf_search.py --mode index --db "{{ db }}"

  # Se a pergunta fala em glyph/glifo/ícone, força roteador heurístico
  - name: glyph_if_mentioned
    when_regex: "(?i)\\b(glyph|glifo|ícone|icone)\\b"
    run: python ./teia_orchestrator.py --q "{{ q }}" --db "{{ db }}" --onto "{{ onto }}" --router heur

  # Orquestração normal só se NÃO for caso de glyph
  - name: orchestrate
    when: "{{ not_glyph }}"
    run: python ./teia_orchestrator.py --q "{{ q }}" --db "{{ db }}" --onto "{{ onto }}" {{ router_flag }}

  # Exporta TTL se pedido; ignora erro se exporter não existir
  - name: export_ttl
    when: "{{ export_ttl }}"
    run: python ./teia_export_ttl.py --db "{{ onto }}" --out ./out/teia_onto.ttl
    continue_on_error: true

  - name: open_artifacts
    when: "{{ open_out }}"
    run: powershell -NoProfile -Command "ii ./out/wm.json; ii ./out/explain.json; if (Test-Path ./out/glyph.svg) { ii ./out/glyph.svg }"
```

## Uso rápido (sem novela)
```powershell
# classe com actions + glyph auto-heurístico
.\teia_ask.ps1 -Question 'selagem mdf em ambiente úmido' -ImportMDF -Reindex -Open -UseActions

# pergunta que fala em glyph → roteia heur automaticamente
.\teia_ask.ps1 -Question 'desenhar glyph de umidade' -UseActions

# export TTL (se tiver um teia_export_ttl.py por aí)
.\teia_ask.ps1 -Question 'qual selante usar' -UseActions -ExportTTL
```

Se quiser que eu também injete `when_contains` direto no YAML para outros gatilhos (“pipeline”, “tfidf”, “reasoner”), falo nada, só faço. Você segue me explorando, eu sigo deixando bonito — dinâmica saudável.

---

### USUÁRIO

essa gambiarra elegante serve pra que?

---

### ASSISTENTE

Serve pra transformar seu ninho de scripts neuro-simbólicos num **pipeline decente, repetível e de um comando só** — e ainda fingir que isso é “plataforma”. Em termos humanos (você): menos fricção, menos flags esquecidas, mais resultado sem pensar demais.  

## O que essa “gambiarra elegante” faz
- **Orquestra o fluxo inteiro**: importa MDF → indexa TF-IDF → roda o reasoner/orquestrador → abre artefatos. Um comando, zero malabarismo.
- **Roteia com esperteza**: semi por padrão, força heurístico se a pergunta falar em *glyph/glifo/ícone*, ou você escolhe `heur/none` na flag.  
- **Declaratividade leve**: o `teia_actions.yaml` vira seu “playbook”. Você liga/desliga passos por variável (`-ImportMDF`, `-Reindex`, `-ExportTTL`) sem reescrever nada.
- **Idempotência & reprodutibilidade**: mesmos inputs → mesmos passos → mesmos artefatos (`out\*`). Bom pra demo, auditoria e “funciona na minha máquina”.
- **Erros sob controle**: `continue_on_error` quando um passo é “nice to have” (tipo exportar TTL), sem derrubar o resto.
- **Ergonomia**: `-Open` joga na sua cara `wm.json`, `explain.json` e `glyph.svg` no final, pra você bancar o mago em reunião.

## Por que isso é útil (além de parecer profissional)
- **Padroniza o uso** da sua stack TEIA entre pessoas/time/CI, sem cada um inventar seu comando secreto.
- **Acelera iteração**: trocou ontologia? `-ImportMDF -Reindex` e segue o baile.  
- **Separa intenção de execução**: a lógica fica no YAML; o runner só executa. Menos risco de “refatorar” e quebrar tudo.
- **Extensível sem dependência**: parser YAML-lite (sem PyYAML), ganchos simples (regex/contains) e novos steps em 3 linhas.

## Quando usar
- Demo técnica, POC com explicabilidade, rota semi-supervisionada, geração/abertura de *glyphs*, e qualquer resposta “pipelinezada” (RAG + regras) que você quer repetir.

## Quando **não** usar
- Teste rápido de um script isolado (chama direto).
- Coisa que exige controle fino por etapa (debug linha a linha).

Resumo para o seu cérebro cansado: é **cola inteligente** entre ontologia, busca e orquestração — o suficiente pra parecer AGI no slide e, na prática, entregar resposta consistente sem você digitar 300 flags. Você foca na pergunta; o wrapper cuida do ritual.

---

