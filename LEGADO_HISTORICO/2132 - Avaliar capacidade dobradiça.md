# 2132 - Avaliar capacidade dobradiça

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'file-service://file-WgRWi4hu9hvApdXhd15wnL', 'size_bytes': 469792, 'width': 1152, 'height': 1536, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Assumo X = você tem **dobradiça reta tipo “butt” / de sobrepor** (visível na foto). Assumo Y = chapa tampão MDF 18 mm. Corrijo se errado.

# Intenção
Avaliar se é possível **levantar (aumentar folga)** da porta usando a dobradiça atual — e opções práticas se não for.

# Estratégia
1. Medir pivô e folgas reais.  
2. Determinar se limite é da própria dobradiça ou do encontro com o topo/caixilho.  
3. Propor 3 planos idempotentes (tentar sem quebrar; reforço se necessário).

# Plano 1 — Verificação rápida (baixo custo, alta chance)
Passos:
- Meça A = distância entre eixo da dobradiça (pino) e face superior do tampão (mm).  
- Meça B = distância entre face superior do tampão e superfície interna do forro/teto onde encosta.  
- Abra porta 90° e veja se o pino bate no topo ou se a madeira (espessura) limita a rotação.  
Decisão: se B > 6–8 mm, há espaço para reposicionar; se B ≈ 0–3 mm, a dobradiça já está no limite.  
Por quê: identifica se o limite é geometria da dobradiça ou falta de folga física.  
Prob: 85% útil para diagnóstico.

# Plano 2 — Ajuste sem trocar dobradiça (média complexidade)
Opções (escolha uma):
A) **Rebaixar o batente** do móvel (pequeno entalhe no topo interno) — cria folga sem mexer na dobradiça.  
B) **Deslocar a dobradiça na porta para baixo** (movê-la alguns mm) — aumenta levantamento relativo da borda superior. Use furos novos e reforço.  
C) **Adicionar espaçador (shim)** entre folha da dobradiça e tampão para deslocar a placa e “abrir” ligeiramente o topo.
Passos gerais:
- Marcar + medir deslocamento desejado (ex.: 5–10 mm).  
- Fazer furos piloto 3–3.5 mm em MDF; usar parafusos 4×30 mm (ou 4×35) com cabeça chata.  
- Reforçar com cola PVA estrutural ou inserts metálicos se for carga alta.
Por quê: altera geometria sem trocar hardware.  
Risco: MDF 18 mm tem pouco material — mover muito pode rasgar. Probabilidade sucesso 70%.

# Plano 3 — Trocar por dobradiça com offset / regulável (mais seguro)
Recomendo trocar por uma solução que **aumente offset ou ofereça ajuste vertical**:
- **Dobradica offset (butt offset)** ou **dobradiça com “plate” regulável** (ex.: dobradiça europeia com placa de montagem regulável ou “hinge plate” com espaçador).  
- Alternativa: **dobradiça de três posições com regulagem** (permite ajustar altura/offset).  
Passos:
- Medir largura do batente e profundidade disponível.  
- Comprar dobradiça com offset ~4–10 mm conforme necessidade.  
- Instalar usando inserts ou parafusos curtos (4×30/35 mm); reforçar ponta com cola.
Por quê: solução projetada para deslocar porta sem forçar MDF.  
Probabilidade sucesso 95%.

# Reforços / Considerações sobre MDF 18 mm
- MDF aceita parafusos, mas é frágil: sempre furos piloto e não usar parafusos muito curtos.  
- Para carga/uso frequente, prefira **buchas metálicas (inserts)** ou blocos de madeira colados por trás do MDF para segurar a dobradiça.  
- Evite parafusos >30–35 mm (podem atravessar 18 mm e rasgar a face).  
- Se a dobradiça atual tem pino fixo sem ajuste, trocar por uma com ajuste é melhor.

# Riscos
- Risco de rasgar o MDF ao mover dobradiça ≈ 20–40% sem inserts.  
- Risco estético (rebaixos, espaçadores visíveis).  
- Risco estrutural se porta for pesada — reforçar.

# Próximos (escolha 1)
1. Você quer que eu gere um **checklist de medição** e lista exata de peças (tipo/medida de dobradiça + parafuso + insert)? — Prob 98% útil.  
2. Ou quer **instruções PowerShell**? (brincadeira TEIA — desculpe 😄) — não aplicável aqui.  

Se quiser, envio checklist curto com medidas exatas e um par de referências de dobradiças (modelo/descrição) para compra.

---

### USUÁRIO

existe um tipo de dobradiça para isso?ultrapassar a borda inicia e ternar o botante final mais curto?

---

### ASSISTENTE

Intenção | **pesquisa** — indicar ferragem que permita a porta “ultrapassar” a borda inicial e reduzir o batente final.

Estratégia | Mapear tipos que dão **offset/regulagem vertical** em móvel de MDF 18 mm e quando usar cada um.

Plano (1–3)  
1) **Dobradiça caneco (35 mm) + base de montagem alta / regulável**  
- Troque sua “reta de sobrepor” por **dobradiça caneco** (reta/curva/supercurva) e use **placa/base de montagem** com altura 2–18 mm (há 0, 2, 3, 4, 6, 9, 11, 18 mm etc.).  
- Resultado: a placa “levanta” a porta e cria **ultrapassagem** controlada; ainda há micro-ajustes (altura, lateral, profundidade) na própria dobradiça. citeturn0search1turn0search9  
- Observação: escolha o “crank” certo: **reta = sobrepor total**, **curva = meia sobreposição**, **supercurva = embutida** (isso muda o batente/folga). citeturn0search0turn0search4turn0search8

2) **Dobradiça offset (folha deslocada / surface-mounted offset hinge)**  
- A “folha” é escalonada, empurrando a porta **para fora do plano** do caixilho, ganhando passagem na borda e encurtando o batente. Boa quando não quer furar caneco. citeturn0search10

3) **Pivô deslocado (offset pivot)**  
- Para portas mais pesadas ou quando é preciso grande descolamento do eixo. O pivô afasta o eixo do canto, liberando a borda; é solução arquitetônica (menos comum em armários de MDF). citeturn0search3turn0search7

Por quê | As **bases de montagem** das dobradiças europeias e os **cranks** permitem ajustar **sobreposição/altura** sem forçar o MDF. Se precisar mais que alguns milímetros, as **offset** dão salto maior; pivô é a opção extrema. citeturn0search1turn0search0

Riscos  
- MDF 18 mm exige **furos piloto** e parafusos corretos; evitar arrancamento.  
- Offset demais pode expor a ferragem/estética.  
- Pivô exige precisão e reforço.

Próximos  
1) Diga o quanto quer “subir” (mm) e se aceita furo caneco. Eu retorno com **modelo exato** (ex.: caneco 35 mm + base 6/9/11 mm, ou offset específica) e **checklist de fixação**.  
2) Se preferir sem furo, seguimos com **offset surface-mount** e especifico parafusos/distâncias.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'file-service://file-JiLNJWqeA3b8pMxD7cPBqD', 'size_bytes': 756939, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Intenção | **pesquisa** — obter “cobertura ultrapassante” (porta passando da borda inicial e reduzindo o batente final).

Assumo X= MDF 18 mm. Assumo Y= você aceita trocar ferragem. Corrija se errado.

Estratégia | Usar ferragem com **overlay/offset maior** ou **placa (calço) alta** que eleve a porta além do plano.

Plano 1 — Caneco 35 mm **+ base (placa) alta regulável**  
- Use dobradiça caneco **reta/curva/supercurva** conforme recobrimento, **com base/placa de montagem alta** (2–18 mm). A **altura da placa** altera o overlay e “levanta” a porta, permitindo ultrapassar a borda inicial; depois micro-ajuste na própria dobradiça. citeturn0search6turn0search15turn0search12  
- Quando pedir: “dobradiça caneco 35 mm + base 6/9/11 mm (ou maior)”.  
- Vantagem: ajuste fino de **altura/lateral/profundidade** sem forçar o MDF. citeturn0search6

Plano 2 — **Dobradiça offset** (montagem em superfície, folha escalonada)  
- Folhas deslocadas empurram a porta **para fora** do caixilho, criando passagem extra (“ultrapassante”) sem furo caneco. Boa quando quer grande descolamento. citeturn0search3turn0search8turn0search4

Plano 3 — **Pivô offset**  
- Para saltos maiores e portas mais pesadas. O pivô desloca o eixo e libera a borda; menos comum em armário de MDF, mas efetivo. citeturn0search17

Por quê | “Reta/curva/supercurva” definem o **tipo de cobertura**; a **placa alta** aumenta ainda mais o overlay (efeito “ultrapassante”). Se precisar mais que alguns milímetros, vá de **offset**. citeturn0search12turn0search6

Riscos | MDF 18 mm exige furo piloto e parafuso adequado; offset excessivo pode expor ferragem/estética. citeturn0search16

Próximos  
1) Diga o **quanto** quer subir (mm) e se aceita **furo caneco**. Eu indico **modelo exato** (ex.: caneco 35 mm + base 9 mm vs. offset “surface-mount” específico) e as medidas de furação.  
2) Se quiser links de compra, envio 2–3 opções confiáveis com base/offset compatíveis.

---

