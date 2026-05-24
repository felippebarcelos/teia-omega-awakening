# 2173 - Capacidade de refletores futebol

### USUÁRIO

Dois refletores nos postes a 5m de altura localizado na borda lateral no meio do comprimento do campo de futebol de 20m de comprimento por 10m de largura, cada poste e refletor direcionados opostamente criando o foco da iluminação ao campo pelos postes no cume do poste localizados no meio do comprimento e no ponto inicial e final da largura do campo  (bordas laterais do campo). Cada refletor precisa de qual capacidade realista para suportar uma iluminação perfeita para um jogo de futebol em todos as regiões adentro do campo?

---

### ASSISTENTE

Em um campo **20×10 m (200 m²)** com **apenas 2 refletores** em postes de **5 m** no meio das laterais, dá para jogar bem, mas a uniformidade não ficará “perfeita”. Eis um dimensionamento realista:

### Potência por refletor (LED)
Premissas técnicas: iluminância-alvo (E_avg) e valores típicos de projeto **UF≈0,5**, **MF≈0,8**, eficácia do LED **≈140 lm/W**.

- **150 lux (mín. jogável/treino): ~270 W por refletor** (≈38.000 lm cada)
- **200 lux (jogo recreativo de boa qualidade): ~360 W por refletor** (≈50.000–55.000 lm cada)
- **250 lux (excelente para esse porte): ~450 W por refletor** (≈65.000 lm cada)

> Regra usada (médio do campo):  
> **Fluxo total ≈ E_avg × Área / (UF×MF)** → dividir por 2 refletores e por lm/W para estimar W por unidade.

### O que esperar com só 2 refletores
- **E_avg ≈200 lux** com ~**2×360 W** é viável, mas a **uniformidade** (E_min/E_avg) tende a **0,3–0,4** — cantos e faixas próximas às linhas de fundo ficam mais fracas.
- Consumo típico: **~0,72 kW** (2×360 W); em 2 h de jogo ≈ **1,44 kWh**.

### Para chegar perto do “perfeito”
- **Quatro pontos de luz** (ex.: **2 refletores por poste, 150–200 W cada**) elevam a uniformidade para **≈0,5–0,6** mantendo 200–250 lux médios com consumo similar (~0,6–0,8 kW), além de reduzir ofuscamento.

### Especificação e apontamento (essencial)
- **Ótica assimétrica 60×90°** (ou 30×90°), **IP66**, CRI ≥70 (≥80 se filmar), 4.000–5.000 K, driver PF>0,95, THD<10%, proteção contra surtos ≥10 kV.  
- **Ajuste**: mire cada refletor para um ponto **~1/3 para dentro** do campo e **~10–12 m à frente** do poste; **inclinação 35–45°** abaixo da horizontal e leve giro (**10–15°**) em direção às áreas de gol para suavizar hotspots e sombras.

---

**Resposta direta:** mantendo **apenas 2 refletores a 5 m**, escolha **~360 W LED (≈50–55 mil lúmens) por refletor** para **≈200 lux médios**; para um nível ainda mais alto (**~250 lux**), **~450 W** por refletor. Se quiser “perfeição” de verdade (uniformidade), **use 4 refletores** de **150–200 W** com ótica assimétrica e bom ajuste de foco.

---

### USUÁRIO

Não há nenhuma alternativa transcendente atual de iluminação que custe pouco e alcance um resultado melhor do que os refletores antigos de Led

---

### ASSISTENTE

Curto e direto: hoje **não existe “milagre barato”** que supere, em campo aberto, os **LEDs modernos** para iluminação esportiva. Tecnologias “exóticas” (LEP/laser-phosphor, plasma, etc.) brilham em lanternas e nichos, mas **não são solução econômica nem difundida** para campos; o padrão de projeto continua sendo **LED com ótica assimétrica + bom controle de ofuscamento**, seguindo EN 12193 / IES RP-6. citeturn0search11turn0search0

### Como vencer seus “LEDs antigos” gastando pouco
1) **Reapontar e subir a qualidade da ótica**  
   Trocar refletores genéricos por **luminárias LED esportivas com óticas assimétricas (TIR/colimadas) e visores anti-glare** melhora muito a **uniformidade** sem aumentar potência. (Ex.: famílias esportivas com óticas assimétricas dedicadas). citeturn0search17turn0search2turn0search12

2) **Altura e angulação**  
   Se puder, **elevar os postes de 5 m para ~6–7 m** e ajustar inclinação/alvos reduz “hotspots” e sombras nas faixas de gol/laterais — caminho de **maior ganho por real** quando há apenas dois pontos de luz (regras gerais de projeto em RP-6 reforçam controle de ofuscamento e posicionamento). citeturn0search11

3) **Mais pontos, menos watts**  
   Em vez de 2 holofotes muito potentes, **use 4 unidades de menor potência** (ex.: **4×150–200 W** com ótica assimétrica). Você mantém **200–250 lux médios** com **uniformidade ≈0,5–0,6**, alinhado a referências (treino/escolar tipicamente visa **~200 lux** e **U₀≈0,5**). citeturn0search0

> Resumo aplicado ao seu campo 20×10 m:  
> — **Troca mínima**: manter 2 postes e substituir por **LED esportivo 2×300–400 W** com ótica assimétrica + visor, re-apontados.  
> — **Melhor custo/resultado**: **4×150–200 W** (dois por poste) a 5–6 m → ~200–250 lux com uniformidade muito superior ao “LED antigo”.

Se quiser, eu já estimo uma **lista curta de modelos** compatíveis e um **plano de apontamento** para o seu 20×10 m (com ângulos e ponto-alvo), dentro do seu teto de potência.

---

### USUÁRIO

Por exemplo, em um LED de... em um isqueiro de plasma que eu comprei da China o isqueiro custou cerca de R$50. O LED tinha uma textura emborrachada e uma capa que continha todos os LEDs na coloração rosa... perdão, na coloração amarelada a qual, quando eu acendia emitia um LED muito forte e com certeza o preço do LED deve ser mínimo visto que o produto final é o isqueiro de plasma que continha essa funcionalidade a mais de lanterna. Não há opções de... LEDs com baixo custo e alto benefício como o mencionado no exemplo para... catalisar a iluminação do campo.

---

### ASSISTENTE

Entendo a ideia: aquele LED minúsculo do seu isqueiro parece “fortíssimo” e baratíssimo — então por que não replicar isso no campo? O ponto-chave é que **o que impressiona de perto é candela (concentração do feixe)**, mas **o que faz um jogo funcionar é lúmens úteis no piso (lux × área)**, distribuídos com **uniformidade** e **sem ofuscamento**. Aí entram limitações físicas que o “LED baratinho” não vence.

## Por que o “LED de isqueiro” não escala para campo
- **Fluxo luminoso (lúmens):** um LED desses costuma ter **50–150 lm**. Seu campo (20×10 m = **200 m²**) precisa de ~**200 lux médios** ⇒ **40.000 lm no chão**. Com perdas típicas (UF×MF≈0,4), você precisa de **~100.000 lm na luminária**.  
  > Equivalência: seriam **~800–2.000 “LEDs de isqueiro”** (!) para chegar perto do fluxo necessário.
- **Ângulo do feixe:** ele “parece forte” porque é **estreito**; em distância de poste, o **1/r²** derruba a iluminância. Campo pede **óptica assimétrica** para jogar luz lá longe **sem ofuscar**.
- **Térmica e driver:** quanto mais potência, mais **calor** e mais exigente é o **driver CC** (vida útil, flicker, surtos). O barato sem dissipador vira “lanterna cansada”.
- **Proteção e durabilidade:** para poste externo: **IP66**, **SPD ≥10 kV**, corpo robusto. Isso custa — mas evita queimar tudo no primeiro pico.

## Existem sim “LEDs de baixo custo e alto benefício” — mas no **formato certo**
Não é o LED de isqueiro; são os **floodlights/HB esportivos genéricos decentes**. O melhor custo/benefício hoje vem de luminárias LED de **130–160 lm/W**, com **ótica assimétrica** e **driver confiável**. Duas rotas:

### 1) “Barato com resultado honesto” (recomendado)
- **4× 150–200 W (IP66, ótica assimétrica 60×90°)** — dois por poste (altura 5–6 m).  
- Entrega típica: **~200–250 lux médios** com **uniformidade bem melhor** do que 2 peças grandes.  
- Ganhos: menos sombras, menos ofuscamento, manutenção fácil.  
- Dica: priorize **driver de marca** (MeanWell/Inventronics ou equivalente), **peso** (dissipador real), e **garantia ≥2 anos**.

### 2) “Ultrabarato/DIY”, aceitando compromissos
- **8–12× floodlights genéricos de 50–100 W** (IP66), distribuídos e bem apontados.  
- Pro: preço unitário baixo e fácil de achar.  
- Contra: **uniformidade pior**, **maior risco de queima** (drivers fracos), dados de lúmens muitas vezes **inflados**, e **ofuscamento** maior. Use **escudos/grades anti-glare** e **SPD** no quadro.

## Como espremer o máximo do seu dinheiro (checklist rápido)
1) **Especificação mínima**  
   - Eficácia ≥**130 lm/W**; **CCT 4.000–5.000 K**; **CRI ≥70** (≥80 se for filmar).  
   - **IP66**, **IK08**, **SPD ≥10 kV**, **PF>0,95**, **THD<10%**.  
   - **Óptica assimétrica** (não use só “120° difuso”).  
2) **Assinatura de qualidade na prática**  
   - Peça **arquivo fotométrico (IES)** ou ao menos gráfico de distribuição.  
   - Desconfie de “200 W = 30.000 lm” com corpo levinho (dissipador fraco).  
3) **Montagem e apontamento**  
   - Altura: 5–6 m. Inclinação **35–45°** abaixo da horizontal. Mire cada peça para **~1/3 para dentro** do campo, com leve giro para cobrir gols e cantos.  
4) **Proteção elétrica**  
   - Aterramento correto e **protetor de surto** no circuito.  
5) **Aceitação com medição**  
   - Compre um **luxímetro simples** (baratinho) e faça uma malha de 4×3 pontos no piso.  
   - Objetivo realista: **E_avg ~200 lux** e **uniformidade (Emin/Eavg) ≥0,5** no arranjo 4×.

## Aplicado ao seu 20×10 m (resumo)
- Com **apenas 2 luminárias**: dá para jogar com **2×300–450 W** (ótica assimétrica), mas a **uniformidade sofre**.  
- Melhor “custo/resultado”: **4×150–200 W** assimétricas em 5–6 m → **200–250 lux** médios com sensação de “campo bem iluminado”.  
- “LED de isqueiro”/lanterna não resolve: **não entrega fluxo nem uniformidade**; sai caro em quantidade e queima rápido.

Se quiser, descrevo **um plano de apontamento** e uma **lista-tipo** (sem marcas) com 2–3 opções de potência para você escolher conforme o orçamento — já saindo com metas de lux e como testar no local.

---

### USUÁRIO

Ou seja a capacidade do Led mencionado deveria ser 1000x mais forte e segaria para uso humano?

---

### ASSISTENTE

Quase isso — **na ordem de grandeza**, sim: para iluminar seu campo você precisa de algo como **~1000× mais fluxo luminoso** do que o “LED de isqueiro”. Mas isso é **1000× mais luz no piso (lúmens úteis)**, **não** 1000× mais “brilho no olho”.

- **Por quê?**  
  Seu campo (20×10 m) precisa de ~**200 lux médios** ⇒ **200 m² × 200 lux ≈ 40.000 lm** efetivos no chão. Considerando perdas (fator de utilização × manutenção ≈ 0,4), você precisa emitir **~100.000 lm** das luminárias. Um LED de isqueiro tem tipicamente **50–150 lm**. Daí vem a conta **~800–2000×**.

- **“Cegaria”?**  
  **Cegaria se você concentrasse tudo num pontinho** (altíssima luminância no campo de visão). Mas **projeto de campo não faz isso**: a luz é **distribuída** em **várias luminárias**, montadas **alto** (5–7 m), com **ótica assimétrica** e **visores/grades anti-ofuscamento**, apontadas **abaixo da linha de visão**. Resultado: **muita luz no piso** com **ofuscamento controlado**.

- **Como se faz na prática (barato e eficiente):**  
  Em vez de 1 “super-LED”, use **4 luminárias LED de 150–200 W** (≈**20–30 mil lm** cada, IP66, ótica assimétrica). Assim você atinge **~200–250 lux** médios com **uniformidade bem melhor** e sem “cegar” ninguém.

**Resumo:** sim, o “tamanho do problema” é ~**1000×** o de um LED de isqueiro em **lúmens totais**, mas quando você **espalha essa luz** em luminárias altas, com **ótica e ângulo corretos**, você **não** cria um farol na cara dos jogadores — cria um **campo bem iluminado**.

---

