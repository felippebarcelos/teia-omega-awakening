# 2420 - Diagnóstico do Bunner

### USUÁRIO

Prompt (contexto): """Diagnostique porque a linha linear plana da esquerda da bunner vai dos elemento o20 a o14 e não de o20 até o12? (nas duas imagens anexadas mostra na região de onde está o mouse a região que está faltando o elemento o12)

Script do Bunner a ser analisado:

'
# ============================================================
# TEIA OS – Hyper-Fluid Boot + HYPER-FLUX IDENTITY ENGINE (v4 – NeuroTuned)
# ============================================================

$E = [char]27

# Ambiente
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Global:ErrorActionPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "TEIA OS | KERNEL BOOT SEQUENCE"

# Paleta – alinhada com psicologia das cores
$C_Brand       = "$E[38;5;51m"   # Ciano – principal (tecnologia, confiança)
$C_BrandSoft   = "$E[38;5;45m"   # Ciano suave – transições suaves
$C_Deep        = "$E[38;5;23m"   # Azul profundo – base / profundidade
$C_Purple      = "$E[38;5;135m"  # Roxo – futurismo/inovação
$C_AccentWarm  = "$E[38;5;214m"  # Laranja suave – foco/ação/atenção
$C_TextSoft    = "$E[38;5;250m"  # Texto suave – legibilidade
$C_White       = "$E[38;5;255m"  # Branco – flashes/realce máximo
$C_Glitch      = "$E[38;5;160m"  # Vermelho magenta – glitch curto (não dominante)
$C_Grey        = "$E[38;5;236m"  # Fundo quase preto / linhas discretas
$C_GreySoft    = "$E[38;5;238m"
$R             = "$E[0m"

# Banner TEIA OS (identidade)
$banner = @(
    "████████╗███████╗██╗ █████╗      ██████╗ ███████╗",
    "╚══██╔══╝██╔════╝██║██╔══██╗    ██╔═══██╗██╔════╝",
    "   ██║   █████╗  ██║███████║    ██║   ██║███████╗",
    "   ██║   ██╔══╝  ██║██╔══██║    ██║   ██║╚════██║",
    "   ██║   ███████╗██║██║  ██║    ╚██████╔╝███████║",
    "   ╚═╝   ╚══════╝╚═╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝"
)

# ==========================
# FUNÇÕES GERAIS
# ==========================
function Hide-Cursor { Write-Host "$E[?25l" -NoNewline }
function Show-Cursor { Write-Host "$E[?25h" -NoNewline }
function Clear-Screen { Write-Host "$E[2J" -NoNewline }

function Set-Pos {
    param([int]$y, [int]$x)
    if ($x -ge 0 -and $y -ge 0 -and
        $x -lt [Console]::WindowWidth -and
        $y -lt [Console]::WindowHeight) {
        Write-Host "$E[${y};${x}H" -NoNewline
    }
}

# ============================================================
# FASE 1: TEIA FRACTAL (Exploração / Curiosidade)
# ============================================================
function Invoke-FractalWeb {
    Clear-Screen
    $W = [Console]::WindowWidth
    $H = [Console]::WindowHeight
    $CenterX = [math]::Round($W / 2)
    $CenterY = [math]::Round($H / 2)
    
    $Nodes = @()
    0..40 | ForEach-Object {
        # Mix de cores frias → sensação de profundidade e calma
        $colorPool = @($C_Deep, $C_BrandSoft, $C_GreySoft)
        $Nodes += [PSCustomObject]@{
            X     = $CenterX
            Y     = $CenterY
            DX    = (Get-Random -Min -2 -Max 3)
            DY    = (Get-Random -Min -1 -Max 2)
            Char  = (Get-Random ".", "·", "+", "x")
            Color = (Get-Random -InputObject $colorPool)
        }
    }

    for ($frame = 0; $frame -lt 30; $frame++) {
        foreach ($n in $Nodes) {
            if ($n.X -gt 0 -and $n.X -lt $W -and $n.Y -gt 0 -and $n.Y -lt $H) {
                Write-Host "$E[$([int]$n.Y);$([int]$n.X)H " -NoNewline
            }

            $n.X += $n.DX * (1 + ($frame / 20))
            $n.Y += $n.DY

            if ($n.X -gt 1 -and $n.X -lt $W -and $n.Y -gt 1 -and $n.Y -lt $H) {
                Write-Host "$E[$([int]$n.Y);$([int]$n.X)H$($n.Color)$($n.Char)$R" -NoNewline
            }
        }
        Start-Sleep -Milliseconds 30
    }
}

# ============================================================
# FASE 2: NÚCLEO (Foco / Energia concentrada)
# ============================================================
function Invoke-CoreImplosion {
    $W = [Console]::WindowWidth
    $H = [Console]::WindowHeight
    $CX = $W / 2
    $CY = $H / 2

    for ($r = 20; $r -ge 2; $r -= 2) {
        $Steps = 18
        for ($i = 0; $i -lt $Steps; $i++) {
            $Angle = ($i / $Steps) * 2 * [math]::PI
            $X = [int]($CX + [math]::Cos($Angle) * $r * 2)
            $Y = [int]($CY + [math]::Sin($Angle) * $r)

            if ($X -gt 0 -and $X -lt $W -and $Y -gt 0 -and $Y -lt $H) {
                # Gradiente simbólico: periferia mais profunda, centro mais brilhante
                $color = if ($r -gt 12) {
                    $C_Deep
                } elseif ($r -gt 6) {
                    $C_BrandSoft
                } else {
                    $C_Brand
                }
                Write-Host "$E[$Y;${X}H${color}o$R" -NoNewline
            }
        }
        Start-Sleep -Milliseconds 40
    }

    # Flash Central – energia / nascimento da identidade
    Write-Host "$E[$([int]$CY);$([int]$CX-2)H${C_AccentWarm}█████$R" -NoNewline
    Start-Sleep -Milliseconds 120
    # Não limpamos a tela aqui → zero frame preto
}

# ============================================================
# FASE 3: BANNER GLITCH (Revelação da Marca)
# ============================================================
function Invoke-GlitchBanner {
    $W = [Console]::WindowWidth
    $BannerWidth = $banner[0].Length
    $PadLeft = [math]::Max(0, [int](($W - $BannerWidth) / 2))
    $StartRow = [int]([Console]::WindowHeight / 2) - 4
    
    $Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%"

    # Glitch curto em vermelho/magenta → atenção rápida, não ameaçadora
    for ($i = 0; $i -lt 3; $i++) {
        $Row = $StartRow
        foreach ($line in $banner) {
            $CorruptLine = ""
            0..($line.Length - 1) | ForEach-Object {
                if ((Get-Random) % 10 -gt 7) {
                    $CorruptLine += $Chars[(Get-Random) % $Chars.Length]
                } else {
                    $CorruptLine += $line[$_]
                }
            }
            $Color = if ($i % 2 -eq 0) { $C_Glitch } else { $C_BrandSoft }
            Write-Host "$E[$Row;${PadLeft}H$Color$CorruptLine$R" -NoNewline
            $Row++
        }
        Start-Sleep -Milliseconds 55
    }

    # Estabilização Final – logo 100% firme em ciano (confiança)
    $Row = $StartRow
    foreach ($line in $banner) {
        Write-Host "$E[$Row;${PadLeft}H$C_Brand$line$R" -NoNewline
        Start-Sleep -Milliseconds 45
        $Row++
    }
}

# ============================================================
# FASE 4: HYPER-FLUX IDENTITY ENGINE (Confirmação + CTA)
# ============================================================

# Fundo sutil – mantém contexto, não apaga tudo
function Draw-BackgroundWeb {
    $w = [Console]::WindowWidth
    $h = [Console]::WindowHeight
    $Density = 60

    for ($i = 0; $i -lt $Density; $i++) {
        $x = Get-Random -Min 1 -Max $w
        $y = Get-Random -Min 1 -Max $h
        $Sym   = Get-Random -InputObject @("·", ".", "`"", "*")
        $Color = Get-Random -InputObject @($C_Grey, $C_GreySoft, $C_Deep)
        Set-Pos $y $x
        Write-Host "$Color$Sym$R" -NoNewline
    }
}

# Pulso Central – “coração” da TEIA OS
function Draw-Pulse {
    $cx = [int]([Console]::WindowWidth / 2)
    $cy = [int]([Console]::WindowHeight / 2)
    
    for ($r = 1; $r -lt 12; $r++) {
        $Steps = 12 + ($r * 2)
        for ($theta = 0; $theta -lt 360; $theta += (360 / $Steps)) {
            $rad = $theta * [Math]::PI / 180
            $x = [int]($cx + ([Math]::Cos($rad) * $r * 2))
            $y = [int]($cy + ([Math]::Sin($rad) * $r))

            Set-Pos $y $x

            # Gradiente emocional:
            # perto do centro: azul profundo → controle
            # meio: ciano → inteligência ativa
            # borda: laranja suave → convite à ação
            $color = if ($r -le 3) {
                $C_Deep
            } elseif ($r -le 7) {
                $C_Brand
            } elseif ($r -lt 11) {
                $C_BrandSoft
            } else {
                $C_AccentWarm
            }

            if ($r -eq 11) { Write-Host "${C_Grey}░$R" -NoNewline }
            else           { Write-Host "${color}•$R" -NoNewline }
        }
        Start-Sleep -Milliseconds 40
    }
}

# Decodificação do Banner – reforça identidade e “inteligência”
function Invoke-DecodeBanner {
    $StartRow  = [int]([Console]::WindowHeight / 2) - 4
    $CenterCol = [int]([Console]::WindowWidth / 2)
    
    $MaxLen  = ($banner | Measure-Object -Property Length -Maximum).Maximum
    $PadLeft = $CenterCol - [int]($MaxLen / 2)
    $Chars   = "█▓▒░@#&+="
    
    for ($i = 0; $i -lt $banner.Count; $i++) {
        $Line = $banner[$i]
        $Row  = $StartRow + $i
        $Spaces = " " * $PadLeft

        # Glitch como “codificação” – curto e controlado
        Set-Pos $Row 0
        Write-Host "$Spaces$C_Glitch$($Line -replace '.', '▒')$R" -NoNewline
        Start-Sleep -Milliseconds 45

        # Identidade firme em ciano
        Set-Pos $Row 0
        Write-Host "$Spaces$C_Brand$Line$R" -NoNewline
        Start-Sleep -Milliseconds 45
    }
}

# HUD – copy e cor pensadas para CTA amigável
function Draw-HUD {
    $Row = [Console]::WindowHeight - 4
    $W   = [Console]::WindowWidth

    $MsgWidth = 42
    $Pad = [int](($W - $MsgWidth) / 2)

    Set-Pos $Row $Pad
    Write-Host "${C_Grey}╔══════════════════════════════════════════╗$R"
    Set-Pos ($Row + 1) $Pad

    # Mensagem:
    # SYSTEM READY  → status confiável
    # PRESS ENTER TO LINK  → CTA claro, com laranja no verbo
    Write-Host (
        "${C_Grey}║ " +
        "${C_TextSoft}SYSTEM READY  ·  " +
        "${C_AccentWarm}PRESS ENTER${C_TextSoft} TO LINK" +
        " ${C_Grey}║$R"
    )

    Set-Pos ($Row + 2) $Pad
    Write-Host "${C_Grey}╚══════════════════════════════════════════╝$R"
}

# ============================================================
# SEQUÊNCIA DE EXECUÇÃO
# ============================================================
try {
    Hide-Cursor
    Clear-Screen

    # 1. Exploração (teia fractal)
    Invoke-FractalWeb

    # 2. Foco no núcleo (implosão)
    Invoke-CoreImplosion

    # 3. Identidade emergindo (glitch → estabilização)
    Invoke-GlitchBanner

    # 4. Engine + estado final (confirmação + CTA visual)
    Draw-BackgroundWeb
    Start-Sleep -Milliseconds 200
    Draw-Pulse
    Invoke-DecodeBanner
    Draw-HUD

    Set-Pos ([Console]::WindowHeight - 2) 2
}
catch {
    Write-Host "$E[0m$E[?25h"
}
finally {
    Show-Cursor
    Write-Host ""
}

'

E porque depois da animação do decodificado, aquela sequência linar some?"""

Exame de cada agente ia:

Grok: """<DELTA-AUDIT>
  <P0-CORE>Verificação Imutável: Análise baseada no código fornecido, sem assunções externas. Δ detectado na renderização console (arredondamento int, aspect ratio, overwrite posicional).</P0-CORE>
  <R1-RAW-REASONING>
    <ISSUE-1>Linha linear esquerda (ray horizontal left, angle=π): Posições calculadas como X = CX - 2*r, Y=CY para r=20..2 step -2. Todas desenhadas inicialmente em Invoke-CoreImplosion.</ISSUE-1>
    <COLOR-SHIFT>Para r&gt;12 (r=14,16,18,20): C_Deep (azul profundo). Para r=12: C_BrandSoft (ciano suave). Mudança de cor cria ilusão de "parada" em o14 (r=14), pois o12 (r=12) difere visualmente, parecendo "faltante" na sequência uniforme.</COLOR-SHIFT>
    <OVERWRITE-PULSE>Invoke-Draw-Pulse sobrepõe •/░ em posições pares (distâncias 4,8,12,16,20,...) com novas cores, preservando apenas "o" em distâncias 24(r=12),28(14),32(16),36(18),40(20). Mas cor de o12 permanece distinta.</OVERWRITE-PULSE>
    <ISSUE-2>Desaparecimento pós-decode: Invoke-DecodeBanner posiciona em coluna 0, escreve " " * PadLeft (tipicamente ~39 para W=120), sobrescrevendo X=0..38 com espaços nas rows do banner (incluindo Y=CY). Como posições o20(X~20)..o12(X~36) estão em X&lt;PadLeft, são apagadas. Sequência linear some por overwrite espacial.</ISSUE-2>
  </R1-RAW-REASONING>
  <VERIFICACAO-DELTA>
    <DETERMINISMO>Incerteza: Largura console (W) varia; teste com W real do screenshot para exato PadLeft. Sem semente fixa, random em Draw-BackgroundWeb pode sobrepor aleatoriamente, injetando Δ.</DETERMINISMO>
    <MAP-FRONTEIRAS>Controle: Cálculos exatos (cos/sin). Criação: Overwrites posicionais (não limpa tela, acumula até sobrescrita).</MAP-FRONTEIRAS>
  </VERIFICACAO-DELTA>
  <R2-CANDIDATE>
    <DIAGNOSE-STRUCT>
      <TABLE>
        <ROW><HEADER>Componente</HEADER><HEADER>Causa</HEADER><HEADER>Impacto</HEADER></ROW>
        <ROW><CELL>Cor Shift em r=12</CELL><CELL>Condição if ($r -gt 12) seleciona C_Deep vs C_BrandSoft</CELL><CELL>Linha "uniforme" visual para em o14; o12 presente mas contrastante</CELL></ROW>
        <ROW><CELL>Overwrite em Decode</CELL><CELL>Write-Host de espaços desde coluna 0 apaga esquerda até PadLeft</CELL><CELL>Sequência linear removida pós-animação decode</CELL></ROW>
      </TABLE>
    </DIAGNOSE-STRUCT>
    <PATCH-PROPOSAL>PATCH[P1]: Remova assimetria X/Y multiplicando Sin por 2 para círculo simétrico; Use cor consistente para r inteiro; Em Decode, Set-Pos $Row $PadLeft em vez de 0, evitando clear esquerda desnecessário. [HASH: a1b2c3d4]</PATCH-PROPOSAL>
  </R2-CANDIDATE>
  <REFINAMENTO-HARMONICO>Módulo harmônico: Explicação fluida mas ancorada em lógica. Evita alucinação; valida com pipeline.</REFINAMENTO-HARMONICO>
</DELTA-AUDIT>
<R3-ENTREGA-FINAL>
  <AXIOMA-CRISTALIZADO>A linha para em o14 por shift de cor em r=12 (C_Deep → C_BrandSoft), criando quebra visual. Sequência some pós-decode por overwrite de espaços em Invoke-DecodeBanner, limpando esquerda do banner. Confie na arquitetura: ajuste PadLeft ou posicionamento para preservar.</AXIOMA-CRISTALIZADO>
  <METADATA><MODEL-VERSION>Grok4</MODEL-VERSION><DELTA-HASH>ef123abc</DELTA-HASH></METADATA>
</R3-ENTREGA-FINAL>"""

Gemini: """# Correção aplicada: Remove a sobrescrita de espaços em branco à esquerda
function Invoke-DecodeBanner {
    $StartRow  = [int]([Console]::WindowHeight / 2) - 4
    $CenterCol = [int]([Console]::WindowWidth / 2)
    
    $MaxLen  = ($banner | Measure-Object -Property Length -Maximum).Maximum
    $PadLeft = $CenterCol - [int]($MaxLen / 2)
    # Ajuste fino de segurança para não quebrar em janelas pequenas
    if ($PadLeft -lt 0) { $PadLeft = 0 } 

    for ($i = 0; $i -lt $banner.Count; $i++) {
        $Line = $banner[$i]
        $Row  = $StartRow + $i
        
        # [CORREÇÃO] Não criamos uma string de espaços. 
        # Movemos o cursor direto para o alvo.

        # 1. Glitch Pass
        Set-Pos $Row $PadLeft  # <--- Pulo direto para a posição do texto
        Write-Host "$C_Glitch$($Line -replace '.', '▒')$R" -NoNewline
        Start-Sleep -Milliseconds 45

        # 2. Final Pass (Identidade)
        Set-Pos $Row $PadLeft  # <--- Pulo direto para a posição do texto
        Write-Host "$C_Brand$Line$R" -NoNewline
        Start-Sleep -Milliseconds 45
    }
}"""

Gpt: """Atividade
·
10m 37s

A pensar
Analisando linha linear em TEIA OS
Parece que a linha linear à esquerda no TEIA OS deveria ir de o20 a o12, mas vai até o14, e o usuário questiona isso. Pelas imagens, a ausência do o12 na linha linear à esquerda é mostrada. A dúvida também menciona a perda dessa sequência após a animação do decodificado.

Analisando linha linear na arte ASCII e animação
Imagem de saída
Identificando origem de 'o12' no script
Parece que os números radiais ‘o12 o14 o16 o18 o20’ estão ausentes no script, e 'o12' pode ser uma sobreposição de uma versão anterior. Aparentemente, o script não contém ‘o12’. Talvez o que aparece seja uma representação indireta dos números, como '•'. Eu ainda estou tentando entender de onde surge 'o12'.

Analisando a linha linear no script Bunner
A imagem pode ter sido capturada de um script anterior, possível script 'Pulse' do TEIA OS, que usava rótulos como 'o12'. No entanto, o script atual não utiliza esses rótulos, apenas caracteres como '•' e '░'. O problema pode ser uma omissão no desenho de um determinado raio.

Analisando omissões na linha linear do script Draw-Pulse
No script, cada raio é desenhado em passos discretos de 360°/Steps, mas devido ao arredondamento, o ângulo de 180° pode não ser incluído para alguns valores de raio. Isso resulta em pontos faltando exatamente na linha horizontal esquerda, gerando a ausência de alguns elementos junto ao eixo.

Explicando a falha ao desenhar linha reta no script Draw-Pulse
No script, os pontos desenhados variam com base no ângulo de passo, mas devido ao arredondamento, o ângulo de 180° raramente é atingido exatamente. Isso significa que não há pontos exatos na linha reta esquerda. Alguns raios podem estar próximos, mas não chegam a alinhar exatamente com o valor esperado no eixo Y central.

Analisando o erro de falta de ponto no lado esquerdo
Parece que o problema ocorre quando o cálculo de coordenadas para valores grandes de 
r
r resulta em um 
x
x negativo ou zero, especialmente quando a tela é muito estreita ou o centro está perto da borda esquerda. Isso ocorre porque o código verifica se as coordenadas estão dentro das limitações da tela antes de desenhar o ponto.

Investigando o sumiço da sequência linear após animação
O problema parece estar relacionado ao fato de a animação do banner sobrepor a linha radial desenhada inicialmente. A função 'Invoke-DecodeBanner' imprime texto ASCII em uma área próxima ao centro, possivelmente sobrescrevendo o ponto que deveria aparecer na linha esquerda, especialmente quando uma tela de 'glitch' é usada.

Investigando sobreposição de sequências no banner
A sequência linear aparente do lado esquerdo, com números como o20 a o14, pode estar relacionada ao comportamento do código. O banner da animação pode estar substituindo as "bolas" ou números no gráfico radial ao desenhar espaços, o que explicaria a diferença entre o esperado e o capturado na tela.

Diagnosticando falha no desenho radial e sobreposição
Imagem de saída
Recortando e redimensionando a imagem
Imagem de saída
Investigando a diferença na sequência de números
Agora, ao olhar para a parte esquerda das letras "TEIA", vejo a sequência "o20 o18 o16 o14", mas estou me perguntando se isso é realmente o que aparece ou se há outra interpretação. Vou dar um zoom na área para confirmar e entender melhor a situação.

Ajustando zoom e exibindo imagem ampliada
Imagem de saída
Ajustando o foco na área correta
Parece que cometi um erro ao cortar a área. Vou ajustar o foco para selecionar a região ao redor do texto, para que a área de interesse seja capturada corretamente agora. Vamos focar justamente no que precisamos.

Localizando coordenadas do texto no imagem
# find approximate coordinates of that text by scanning for bright cyan near middle-left
import numpy as np

small = img1.resize((512,288))
arr = np.array(small)
# find bright cyan-like pixels (high G,B, low R)
mask = (arr[:,:,1] > 200) & (arr[:,:,2] > 200) & (arr[:,:,0] < 80)
ys,xs = np.where(mask)
ys.mean(), xs.mean()

(118.78267477203647, 252.46732522796353)
Ajustando a área de recorte
Estamos próximos ao centro, mas precisamos focar à esquerda de “TEIA OS”. A ideia agora é inspecionar manualmente o recorte, visando cerca de 60% da largura. O centro está em 256, e queremos capturar a área entre 150 e 250, em uma largura de 512. Vamos ajustar conforme isso.

Cortando imagem à esquerda do centro
Imagem de saída
Ajustando o recorte à esquerda
Ainda não estamos no ponto mais à esquerda. Preciso ajustar o recorte ainda mais para garantir que fique corretamente posicionado. Vamos mover um pouco mais para a esquerda para ter certeza de que estamos capturando a área que desejamos.

Cortando imagem mais à esquerda
Imagem de saída
Ajustando mais à esquerda
Agora vou mover o recorte um pouco mais para a esquerda, com o objetivo de garantir que estamos pegando a área certa. Tento ajustar novamente até ficarmos com a posição exata que precisamos.

Cortando imagem para ajustar posição
Imagem de saída
Refinando a localização dos números no diagnóstico
Vejo que os números "o20 o18 o16 o14" aparecem ao redor das várias circunferências no código. Eles representam os rótulos das camadas, como 'o20' para a mais externa, 'o18' e assim por diante. Vou refinar o diagnóstico para identificar como essas marcas se distribuem nas circunferências.

Analisando a geometria do "CoreImplosion"
A descrição diz que a linha plana esquerda vem da geometria do núcleo/pulso. Para verificar, vou fazer os cálculos: usando o "CoreImplosion" com 18 passos por círculo, cada raio terá um ponto à 180°. Preciso garantir que os valores dos raios de 2 a 20 estão distribuídos corretamente, a cada 20°.

Analisando a linha central e os pontos visíveis
A imagem mostra apenas alguns pontos, provavelmente devido à sobreposição do texto 'TEIA OS', que cobre os pontos mais centrais dos anéis. Os pontos visíveis, como os de 20, 18, 16, 14, estão fora da área coberta, enquanto os de 12 e abaixo permanecem escondidos sob as letras. Vamos focar no que é visível perto desse limite.

Analisando a sobreposição e visibilidade dos anéis
Parece que o problema com a invisibilidade de ‘o12’ pode ser resultado da sobreposição do texto “TEIA OS”. O usuário mencionou que a falta do ‘o12’ está em uma área próxima ao lado esquerdo do 'T'. Isso pode ser devido à combinação das animações e a maneira como os valores dos anéis são desenhados.

Analisando a sobreposição de ASCII e pontos de anéis
Parece que o problema com a sobreposição de 'o12' pode ser causado pelo texto ASCII "TEIA OS", que começa a partir de uma posição x=96. A partir das coordenadas calculadas, a linha horizontal deixa pontos de anéis à esquerda dessa posição intactos, embora o 'o12' tenha sido sobrescrito pela ASCII devido ao uso do 'T' nas proximidades.

Verificando o sobreposição entre ASCII e pontos
Na verdade, o texto ASCII começa na coluna PadLeft, que é igual a centreX - B/2, então "o12", estando na coluna 96, não deveria ser sobreposto pelo "T", pois está à esquerda dele. A diferença pode vir de um arredondamento. Vou calcular mais exato assumindo largura da janela como 190 e ajustar conforme necessário.

Analisando sobreposição de texto com coordenadas radiais
banner = [
"████████╗███████╗██╗ █████╗      ██████╗ ███████╗",
"╚══██╔══╝██╔════╝██║██╔══██╗    ██╔═══██╗██╔════╝",
"   ██║   █████╗  ██║███████║    ██║   ██║███████╗",
"   ██║   ██╔══╝  ██║██╔══██║    ██║   ██║╚════██║",
"   ██║   ███████╗██║██║  ██║    ╚██████╔╝███████║",
"   ╚═╝   ╚══════╝╚═╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝"
]
len(banner[0])

49
Ajustando cálculos de alinhamento de texto ASCII
O cálculo de padLeft depende da largura da janela e da largura do banner, mas ao calcular, notei um erro. A fórmula centreX - 24 = padLeft resulta em uma diferença de 1, o que parece não bater. Preciso revisar o arredondamento final para corrigir essa diferença e garantir o alinhamento correto.

Entendendo sobreposição do texto ASCII
Com a largura par, o valor de "o12" está logo à direita da primeira coluna do ASCII. No entanto, a string ASCII começa no padLeft, o que significa que "o12" é sobrescrito pelo texto executado a partir desse ponto. Já "o14", estando fora da área do texto ASCII, não é afetado.

Explicação sobre sobreposição no banner ASCII
Quando o raio é 12, o ponto horizontal no centro do ASCII é sobrescrito, mas os outros pontos maiores que 12 não são impactados. O ponto de raio 12 sendo parte do banner ASCII desaparece, o que pode explicar a falta desse ponto na linha, mesmo após a decodificação do banner no estado final.

Explicando a linha que some no banner
A linha plana da esquerda vai de o20 a o14, não até o12, porque o banner Glitch sobrepõe o ponto o12. Isso acontece após o desenho dos círculos, pois o valor de padLeft e o centro do banner causam uma sobreposição exata no ponto o12. Esse efeito ocorre devido à geometria e arredondamento de inteiros.

Explicando a animação do banner e a linha desaparecendo
Após a animação do banner, a linha desaparece porque a execução do comando "Invoke-DecodeBanner" limpa a área à esquerda antes de desenhar o efeito Glitch. Isso ocorre quando o código escreve um número definido de espaços, apagando a arte anterior naquela região. O código ajusta a simetria, causando esse desaparecimento.

Explicando o cálculo de coordenadas e arredondamento
Na FASE 2, calculamos as coordenadas do banner, com a referência no meio da tela, usando coordenadas duplas e arredondando para inteiros. Isso pode gerar pequenas diferenças devido ao arredondamento, mas o efeito na linha horizontal não é claro porque, mesmo com diferenças, as coordenadas permanecem bem alinhadas.

Explicando o motivo de 'o12' desaparecer
Quando desenhamos círculos na função Invoke-CoreImplosion, a coordenada do 'o12' se sobrepõe à área inicial do banner ASCII (devido ao valor de padLeft), o que faz com que o caractere 'o12' seja sobrescrito pelo primeiro desenho de glitch. As outras coordenadas das rings externas, como 'o14' e 'o20', permanecem visíveis.

Explicando o desaparecimento da linha após decodificação
O comportamento de 'o12' desaparecendo ocorre após a execução do ‘Invoke-DecodeBanner’. Isso acontece porque a função desenha um fundo em branco, apagando os 'o's radiais que estavam anteriormente desenhados. Para corrigir, pode-se modificar o código para não imprimir espaços em branco antes da linha desejada, garantindo que a linha radial permaneça intacta.

Explicando o comportamento das linhas após cada fase
A linha inicial contém todos os radiais de 20 a 2. Após a fase ‘GlitchBanner’, os valores menores de "o" são sobrepostos, mas o valor de "o20..o14" permanece. Durante a fase ‘DecodeBanner’, os espaços em branco restauram a área à esquerda, removendo toda a linha, embora alguns valores ainda pareçam.

Analisando alinhamento vertical e sequência
O alinhamento vertical é sutil no caso da linha horizontal radial, que está em Y=27, enquanto o ASCII vai de Y=23 a Y=28, passando por 27. Além disso, o efeito de "glitch" pode sobrepor a linha radial momentaneamente, mas o fato da linha reaparecer sugere que há uma interação delicada entre as fases de animação e os cálculos.

Explicação sobre a sequência e comportamento do código
A razão pela qual o

Pensado para 10m 37s
Chain-of-thoughtFeito

Por que a linha “reta” da esquerda vai de o20 até o14 e não até o12


O trecho que desenha esses “oXX” é a implosão do núcleo:
function Invoke-CoreImplosion {
    ...
    for ($r = 20; $r -ge 2; $r -= 2) {
        $Steps = 18
        for ($i = 0; $i -lt $Steps; $i++) {
            $Angle = ($i / $Steps) * 2 * [math]::PI
            $X = [int]($CX + [math]::Cos($Angle) * $r * 2)
            $Y = [int]($CY + [math]::Sin($Angle) * $r)
            ...
            Write-Host "$E[$Y;${X}H${color}o$R" -NoNewline
        }
    }
}

Para o raio da esquerda (ângulo 180°), a coordenada horizontal fica:


X_r = CX - 2*r


O banner é desenhado depois, começando em:
$BannerWidth = $banner[0].Length   # 49
$PadLeft = [math]::Max(0, [int](($W - $BannerWidth) / 2))
...
Write-Host "$E[$Row;${PadLeft}H$Color$CorruptLine$R"

Ou seja, a primeira coluna do banner é PadLeft.
Se você fizer as contas:


CX ≈ W/2


PadLeft ≈ CX - 25


Ponto do raio r=12 na esquerda: X_12 = CX - 24


Resultado:


X_20, X_18, X_16, X_14 ficam à esquerda de PadLeft → não são tocados.


X_12 = CX - 24 cai dentro da faixa do banner (PadLeft até PadLeft + 48).


Então o “o12” até existe, mas é desenhado antes e depois é sobrescrito pelo próprio banner TEIA OS. Visualmente parece que a linha só vai de o20 até o14 porque o elemento correspondente ao raio 12 fica exatamente na área ocupada pelo “T”.
Resumo: não é um erro de geometria do círculo; é overdraw: o banner cobre o ponto do raio 12.



Por que a sequência linear some depois da animação do “decodificado”


Na fase Invoke-DecodeBanner você faz isto:
$Spaces = " " * $PadLeft

for ($i = 0; $i -lt $banner.Count; $i++) {
    $Line = $banner[$i]
    $Row  = $StartRow + $i

    Set-Pos $Row 0
    Write-Host "$Spaces$C_Glitch$($Line -replace '.', '▒')$R" -NoNewline
    ...
    Set-Pos $Row 0
    Write-Host "$Spaces$C_Brand$Line$R" -NoNewline
}

Aqui acontecem duas coisas:


Set-Pos $Row 0 posiciona o cursor na coluna 0.


"$Spaces ..." escreve $PadLeft espaços antes da linha do banner.


Esses espaços são literalmente caracteres ' ' desenhados da coluna 0 até PadLeft-1. Qualquer coisa que estava ali (incluindo aquela linha reta de “oXX” à esquerda) é apagada.
Por isso, após a animação de decodificação:


Toda a região à esquerda do banner nas mesmas linhas de Y do logo é sobrescrita por espaços.


A sua “linha linear” desaparece nessas linhas, mesmo os pontos que tinham sobrevivido ao Invoke-GlitchBanner.


Se quiser manter a linha viva mesmo depois do decodificado, o ajuste conceitual é:


Em Invoke-DecodeBanner, escrever o banner a partir de PadLeft sem despejar espaços antes, como você já faz em Invoke-GlitchBanner.


Em termos de lógica, seria algo como trocar:
Set-Pos $Row 0
Write-Host "$Spaces$C_Glitch ..."

Set-Pos $Row 0
Write-Host "$Spaces$C_Brand$Line$R"

por algo equivalente a:
Set-Pos $Row $PadLeft
Write-Host "$C_Glitch ..."

Set-Pos $Row $PadLeft
Write-Host "$C_Brand$Line$R"

Assim o decodificado não limpa a área da esquerda, e a linha de raios permanece visível."""


A partir da avaliação que todas as sugestões nos permitem síntetizar...  Catalise e entregue o bloco do script completo corrigido definitivamente.

---

### ASSISTENTE

def padleft(W, B=49):
    CX = W/2
    pad0 = int((W-B)/2)
    x12 = CX - 24
    return CX, pad0, x12, (pad0 <= x12 <= pad0+B-1)

for W in range(80, 141, 2):   # even widths typical
    CX, pad0, x12, overlap = padleft(W)
    print(W, CX, pad0, x12, overlap)


---

### ASSISTENTE

def padleft2(W, B=49):
    CX = W/2
    pad0 = int((W-B)/2)
    pad = pad0 + 2
    x12 = CX-24
    return W, CX, pad, x12, pad <= x12 <= pad+B-1

for W in range(80, 141, 2):
    print(padleft2(W))


---

### ASSISTENTE

for W in range(79, 141, 2):
    CX = W/2
    B=49
    pad0 = int((W-B)/2)
    x12 = CX-24
    overlap0 = pad0 <= x12 <= pad0+B-1

    pad = pad0+2
    overlap = pad <= x12 <= pad+B-1
    print("W",W,"CX",CX,"pad0",pad0,"x12",x12,"overlap0",overlap0,"pad2",pad,"overlap2",overlap)


---

### ASSISTENTE

Aqui vai o script inteiro já **corrigido e consolidado** com as sugestões:

- **`o12` não é mais coberto** pelo banner (desloquei o logo ligeiramente 2 colunas para a direita, tanto no glitch quanto no decode).
- **`Invoke-DecodeBanner` não apaga mais a área à esquerda** com espaços — ele só escreve a partir de `PadLeft`, preservando a linha linear.

```powershell
# ============================================================
# TEIA OS – Hyper-Fluid Boot + HYPER-FLUX IDENTITY ENGINE (v4 – NeuroTuned)
# ============================================================

$E = [char]27

# Ambiente
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Global:ErrorActionPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "TEIA OS | KERNEL BOOT SEQUENCE"

# Paleta – alinhada com psicologia das cores
$C_Brand       = "$E[38;5;51m"   # Ciano – principal (tecnologia, confiança)
$C_BrandSoft   = "$E[38;5;45m"   # Ciano suave – transições suaves
$C_Deep        = "$E[38;5;23m"   # Azul profundo – base / profundidade
$C_Purple      = "$E[38;5;135m"  # Roxo – futurismo/inovação
$C_AccentWarm  = "$E[38;5;214m"  # Laranja suave – foco/ação/atenção
$C_TextSoft    = "$E[38;5;250m"  # Texto suave – legibilidade
$C_White       = "$E[38;5;255m"  # Branco – flashes/realce máximo
$C_Glitch      = "$E[38;5;160m"  # Vermelho magenta – glitch curto (não dominante)
$C_Grey        = "$E[38;5;236m"  # Fundo quase preto / linhas discretas
$C_GreySoft    = "$E[38;5;238m"
$R             = "$E[0m"

# Banner TEIA OS (identidade)
$banner = @(
    "████████╗███████╗██╗ █████╗      ██████╗ ███████╗",
    "╚══██╔══╝██╔════╝██║██╔══██╗    ██╔═══██╗██╔════╝",
    "   ██║   █████╗  ██║███████║    ██║   ██║███████╗",
    "   ██║   ██╔══╝  ██║██╔══██║    ██║   ██║╚════██║",
    "   ██║   ███████╗██║██║  ██║    ╚██████╔╝███████║",
    "   ╚═╝   ╚══════╝╚═╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝"
)

# ==========================
# FUNÇÕES GERAIS
# ==========================
function Hide-Cursor { Write-Host "$E[?25l" -NoNewline }
function Show-Cursor { Write-Host "$E[?25h" -NoNewline }
function Clear-Screen { Write-Host "$E[2J" -NoNewline }

function Set-Pos {
    param([int]$y, [int]$x)
    if ($x -ge 0 -and $y -ge 0 -and
        $x -lt [Console]::WindowWidth -and
        $y -lt [Console]::WindowHeight) {
        Write-Host "$E[${y};${x}H" -NoNewline
    }
}

# ============================================================
# FASE 1: TEIA FRACTAL (Exploração / Curiosidade)
# ============================================================
function Invoke-FractalWeb {
    Clear-Screen
    $W = [Console]::WindowWidth
    $H = [Console]::WindowHeight
    $CenterX = [math]::Round($W / 2)
    $CenterY = [math]::Round($H / 2)
    
    $Nodes = @()
    0..40 | ForEach-Object {
        # Mix de cores frias → sensação de profundidade e calma
        $colorPool = @($C_Deep, $C_BrandSoft, $C_GreySoft)
        $Nodes += [PSCustomObject]@{
            X     = $CenterX
            Y     = $CenterY
            DX    = (Get-Random -Min -2 -Max 3)
            DY    = (Get-Random -Min -1 -Max 2)
            Char  = (Get-Random ".", "·", "+", "x")
            Color = (Get-Random -InputObject $colorPool)
        }
    }

    for ($frame = 0; $frame -lt 30; $frame++) {
        foreach ($n in $Nodes) {
            if ($n.X -gt 0 -and $n.X -lt $W -and $n.Y -gt 0 -and $n.Y -lt $H) {
                Write-Host "$E[$([int]$n.Y);$([int]$n.X)H " -NoNewline
            }

            $n.X += $n.DX * (1 + ($frame / 20))
            $n.Y += $n.DY

            if ($n.X -gt 1 -and $n.X -lt $W -and $n.Y -gt 1 -and $n.Y -lt $H) {
                Write-Host "$E[$([int]$n.Y);$([int]$n.X)H$($n.Color)$($n.Char)$R" -NoNewline
            }
        }
        Start-Sleep -Milliseconds 30
    }
}

# ============================================================
# FASE 2: NÚCLEO (Foco / Energia concentrada)
# ============================================================
function Invoke-CoreImplosion {
    $W = [Console]::WindowWidth
    $H = [Console]::WindowHeight
    $CX = $W / 2
    $CY = $H / 2

    for ($r = 20; $r -ge 2; $r -= 2) {
        $Steps = 18
        for ($i = 0; $i -lt $Steps; $i++) {
            $Angle = ($i / $Steps) * 2 * [math]::PI
            $X = [int]($CX + [math]::Cos($Angle) * $r * 2)
            $Y = [int]($CY + [math]::Sin($Angle) * $r)

            if ($X -gt 0 -and $X -lt $W -and $Y -gt 0 -and $Y -lt $H) {
                # Gradiente simbólico: periferia mais profunda, centro mais brilhante
                $color = if ($r -gt 12) {
                    $C_Deep
                } elseif ($r -gt 6) {
                    $C_BrandSoft
                } else {
                    $C_Brand
                }
                Write-Host "$E[$Y;${X}H${color}o$R" -NoNewline
            }
        }
        Start-Sleep -Milliseconds 40
    }

    # Flash Central – energia / nascimento da identidade
    Write-Host "$E[$([int]$CY);$([int]$CX-2)H${C_AccentWarm}█████$R" -NoNewline
    Start-Sleep -Milliseconds 120
    # Não limpamos a tela aqui → zero frame preto
}

# ============================================================
# FASE 3: BANNER GLITCH (Revelação da Marca)
# ============================================================
function Invoke-GlitchBanner {
    $W = [Console]::WindowWidth
    $BannerWidth = $banner[0].Length

    # Base centrada + leve offset à direita para não cobrir o raio 12
    $PadLeftBase = [int](($W - $BannerWidth) / 2)
    $PadLeft     = [math]::Max(0, $PadLeftBase + 2)

    $StartRow = [int]([Console]::WindowHeight / 2) - 4
    
    $Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%"

    # Glitch curto em vermelho/magenta → atenção rápida, não ameaçadora
    for ($i = 0; $i -lt 3; $i++) {
        $Row = $StartRow
        foreach ($line in $banner) {
            $CorruptLine = ""
            0..($line.Length - 1) | ForEach-Object {
                if ((Get-Random) % 10 -gt 7) {
                    $CorruptLine += $Chars[(Get-Random) % $Chars.Length]
                } else {
                    $CorruptLine += $line[$_]
                }
            }
            $Color = if ($i % 2 -eq 0) { $C_Glitch } else { $C_BrandSoft }
            Write-Host "$E[$Row;${PadLeft}H$Color$CorruptLine$R" -NoNewline
            $Row++
        }
        Start-Sleep -Milliseconds 55
    }

    # Estabilização Final – logo 100% firme em ciano (confiança)
    $Row = $StartRow
    foreach ($line in $banner) {
        Write-Host "$E[$Row;${PadLeft}H$C_Brand$line$R" -NoNewline
        Start-Sleep -Milliseconds 45
        $Row++
    }
}

# ============================================================
# FASE 4: HYPER-FLUX IDENTITY ENGINE (Confirmação + CTA)
# ============================================================

# Fundo sutil – mantém contexto, não apaga tudo
function Draw-BackgroundWeb {
    $w = [Console]::WindowWidth
    $h = [Console]::WindowHeight
    $Density = 60

    for ($i = 0; $i -lt $Density; $i++) {
        $x = Get-Random -Min 1 -Max $w
        $y = Get-Random -Min 1 -Max $h
        $Sym   = Get-Random -InputObject @("·", ".", "`"", "*")
        $Color = Get-Random -InputObject @($C_Grey, $C_GreySoft, $C_Deep)
        Set-Pos $y $x
        Write-Host "$Color$Sym$R" -NoNewline
    }
}

# Pulso Central – “coração” da TEIA OS
function Draw-Pulse {
    $cx = [int]([Console]::WindowWidth / 2)
    $cy = [int]([Console]::WindowHeight / 2)
    
    for ($r = 1; $r -lt 12; $r++) {
        $Steps = 12 + ($r * 2)
        for ($theta = 0; $theta -lt 360; $theta += (360 / $Steps)) {
            $rad = $theta * [Math]::PI / 180
            $x = [int]($cx + ([Math]::Cos($rad) * $r * 2))
            $y = [int]($cy + ([Math]::Sin($rad) * $r))

            Set-Pos $y $x

            # Gradiente emocional:
            # perto do centro: azul profundo → controle
            # meio: ciano → inteligência ativa
            # borda: laranja suave → convite à ação
            $color = if ($r -le 3) {
                $C_Deep
            } elseif ($r -le 7) {
                $C_Brand
            } elseif ($r -lt 11) {
                $C_BrandSoft
            } else {
                $C_AccentWarm
            }

            if ($r -eq 11) { Write-Host "${C_Grey}░$R" -NoNewline }
            else           { Write-Host "${color}•$R" -NoNewline }
        }
        Start-Sleep -Milliseconds 40
    }
}

# Decodificação do Banner – reforça identidade e “inteligência”
function Invoke-DecodeBanner {
    $W        = [Console]::WindowWidth
    $StartRow = [int]([Console]::WindowHeight / 2) - 4
    
    $MaxLen       = ($banner | Measure-Object -Property Length -Maximum).Maximum
    $PadLeftBase  = [int](($W - $MaxLen) / 2)
    # Mesmo offset do GlitchBanner para manter alinhamento e liberar o raio 12
    $PadLeft      = [math]::Max(0, $PadLeftBase + 2)

    $Chars   = "█▓▒░@#&+="
    
    for ($i = 0; $i -lt $banner.Count; $i++) {
        $Line = $banner[$i]
        $Row  = $StartRow + $i

        # Glitch como “codificação” – curto e controlado
        Set-Pos $Row $PadLeft
        Write-Host "$C_Glitch$($Line -replace '.', '▒')$R" -NoNewline
        Start-Sleep -Milliseconds 45

        # Identidade firme em ciano
        Set-Pos $Row $PadLeft
        Write-Host "$C_Brand$Line$R" -NoNewline
        Start-Sleep -Milliseconds 45
    }
}

# HUD – copy e cor pensadas para CTA amigável
function Draw-HUD {
    $Row = [Console]::WindowHeight - 4
    $W   = [Console]::WindowWidth

    $MsgWidth = 42
    $Pad = [int](($W - $MsgWidth) / 2)

    Set-Pos $Row $Pad
    Write-Host "${C_Grey}╔══════════════════════════════════════════╗$R"
    Set-Pos ($Row + 1) $Pad

    # Mensagem:
    # SYSTEM READY  → status confiável
    # PRESS ENTER TO LINK  → CTA claro, com laranja no verbo
    Write-Host (
        "${C_Grey}║ " +
        "${C_TextSoft}SYSTEM READY  ·  " +
        "${C_AccentWarm}PRESS ENTER${C_TextSoft} TO LINK" +
        " ${C_Grey}║$R"
    )

    Set-Pos ($Row + 2) $Pad
    Write-Host "${C_Grey}╚══════════════════════════════════════════╝$R"
}

# ============================================================
# SEQUÊNCIA DE EXECUÇÃO
# ============================================================
try {
    Hide-Cursor
    Clear-Screen

    # 1. Exploração (teia fractal)
    Invoke-FractalWeb

    # 2. Foco no núcleo (implosão)
    Invoke-CoreImplosion

    # 3. Identidade emergindo (glitch → estabilização)
    Invoke-GlitchBanner

    # 4. Engine + estado final (confirmação + CTA visual)
    Draw-BackgroundWeb
    Start-Sleep -Milliseconds 200
    Draw-Pulse
    Invoke-DecodeBanner
    Draw-HUD

    Set-Pos ([Console]::WindowHeight - 2) 2
}
catch {
    Write-Host "$E[0m$E[?25h"
}
finally {
    Show-Cursor
    Write-Host ""
}
```

Se quiser, no próximo passo posso só te passar um **diff minimalista** das mudanças que importam (GlitchBanner + DecodeBanner), pra ficar mais fácil de comparar com tua versão atual.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000cb4471f5bbf210ebea5937aa', 'size_bytes': 211807, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

from PIL import Image, ImageOps
img = Image.open('/mnt/data/cc196d09-7e6c-48d7-8bfd-2f7ddec2e071.png')
display(img.resize((1024,576)))


---

### ASSISTENTE

from PIL import Image
img = Image.open('/mnt/data/cc196d09-7e6c-48d7-8bfd-2f7ddec2e071.png')
display(img.resize((1024,576)))


---

### ASSISTENTE

# crop approximate area of left circle
w,h = img.size
crop = img.crop((int(w*0.28), int(h*0.35), int(w*0.52), int(h*0.65)))
display(crop.resize((512,512)))


---

### ASSISTENTE

display(crop.crop((200,80,350,260)).resize((512,512)))


---

### ASSISTENTE

display(crop.crop((150,60,300,200)).resize((512,512)))


---

### ASSISTENTE

# crop bottom region where HUD is
crop2 = img.crop((int(w*0.36), int(h*0.7), int(w*0.7), int(h*0.98)))
display(crop2.resize((512,512)))


---

### ASSISTENTE

display(crop2.crop((260,130,380,250)).resize((512,512)))


---

### ASSISTENTE

display(crop2.crop((230,80,420,270)).resize((512,512)))


---

### ASSISTENTE

display(crop2.crop((230,60,350,200)).resize((512,512)))


---

### ASSISTENTE

display(crop2.crop((260,60,430,200)).resize((512,512)))


---

### ASSISTENTE

top = "╔══════════════════════════════════════════╗"
mid = "║ " + "SYSTEM READY  ·  " + "PRESS ENTER" + " TO LINK" + " ║"
bot = "╚══════════════════════════════════════════╝"
len(top), len(mid), len(bot)


---

### ASSISTENTE

msg = "SYSTEM READY  ·  PRESS ENTER TO LINK"
len(msg)


---

### ASSISTENTE

part1 = "SYSTEM READY  ·  "
part2 = "PRESS ENTER"
part3 = " TO LINK"
msg2 = part1 + part2 + part3
len(part1), len(part2), len(part3), len(msg2)


---

### ASSISTENTE

Beleza, vamos ajustar tudo:

- Centralizar melhor o `TEIA OS`
- Acabar com o `o1` (que é na verdade o `o12` com o `2` encoberto)
- Tirar o caractere “sobrando” lá embaixo, na HUD

Abaixo está o script **inteiro** já com essas correções incorporadas.

### O que eu fiz (resumo rápido)

1. **Centralização do “TEIA OS” + `o12` completo**

   Nos banners `Invoke-GlitchBanner` e `Invoke-DecodeBanner` eu passo a calcular o `PadLeft` assim:

   - Primeiro calculo o centro ideal (`PadLeftIdeal`) como antes.
   - Calculo também a posição do raio 12 na esquerda:

     ```powershell
     $CX  = $W / 2
     $X12 = [int]($CX - 24)       # mesmo cálculo da implosão
     ```

   - E defino um “limite de segurança” para não cobrir o texto `o12` (3 caracteres):

     ```powershell
     $LabelWidth = 3              # "o12" tem 3 chars
     $MinPadLeft = $X12 + $LabelWidth
     ```

   - O `PadLeft` final é:

     ```powershell
     $PadLeft = $PadLeftIdeal
     if ($PadLeft -le $MinPadLeft) {
         $PadLeft = $MinPadLeft
     }
     if ($PadLeft -lt 0) { $PadLeft = 0 }
     ```

   Isso garante que **nenhuma parte do `o12` (nem o “2”) é sobrescrita** pelo logo.  
   O logo fica bem perto do centro, mas um pouquinho para a direita para respeitar esse espaço.

2. **Decode não apaga mais a esquerda**

   Em `Invoke-DecodeBanner` eu **não uso mais string de espaços** começando da coluna 0.  
   Eu simplesmente movo o cursor direto para `$PadLeft` (como já tínhamos feito) – preserva a linha linear inteira.

3. **Caractere “solto” na HUD**

   A HUD agora calcula a **largura com base no próprio texto**, e monta borda e linha do meio todas com o mesmo tamanho.  
   Antes a borda tinha 44 caracteres e a linha do meio 40, o que deixava sobra de lixo à direita.  
   Agora:

   ```powershell
   $msgCore      = "SYSTEM READY  ·  PRESS ENTER TO LINK"
   $innerWidth   = $msgCore.Length + 2 # espaços internos
   $boxWidth     = $innerWidth + 2     # bordas
   $topLine      = "╔" + ("═" * $innerWidth) + "╗"
   $middleLine   = "║ " + $msgCore + " ║"
   $bottomLine   = "╚" + ("═" * $innerWidth) + "╝"
   ```

   Topo, meio e base ficam exatamente com o mesmo comprimento → nada “sobrando” do lado direito.

---

## Script completo corrigido

```powershell
# ============================================================
# TEIA OS – Hyper-Fluid Boot + HYPER-FLUX IDENTITY ENGINE (v4 – NeuroTuned)
# ============================================================

$E = [char]27

# Ambiente
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Global:ErrorActionPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "TEIA OS | KERNEL BOOT SEQUENCE"

# Paleta – alinhada com psicologia das cores
$C_Brand       = "$E[38;5;51m"   # Ciano – principal (tecnologia, confiança)
$C_BrandSoft   = "$E[38;5;45m"   # Ciano suave – transições suaves
$C_Deep        = "$E[38;5;23m"   # Azul profundo – base / profundidade
$C_Purple      = "$E[38;5;135m"  # Roxo – futurismo/inovação
$C_AccentWarm  = "$E[38;5;214m"  # Laranja suave – foco/ação/atenção
$C_TextSoft    = "$E[38;5;250m"  # Texto suave – legibilidade
$C_White       = "$E[38;5;255m"  # Branco – flashes/realce máximo
$C_Glitch      = "$E[38;5;160m"  # Vermelho magenta – glitch curto (não dominante)
$C_Grey        = "$E[38;5;236m"  # Fundo quase preto / linhas discretas
$C_GreySoft    = "$E[38;5;238m"
$R             = "$E[0m"

# Banner TEIA OS (identidade)
$banner = @(
    "████████╗███████╗██╗ █████╗      ██████╗ ███████╗",
    "╚══██╔══╝██╔════╝██║██╔══██╗    ██╔═══██╗██╔════╝",
    "   ██║   █████╗  ██║███████║    ██║   ██║███████╗",
    "   ██║   ██╔══╝  ██║██╔══██║    ██║   ██║╚════██║",
    "   ██║   ███████╗██║██║  ██║    ╚██████╔╝███████║",
    "   ╚═╝   ╚══════╝╚═╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝"
)

# ==========================
# FUNÇÕES GERAIS
# ==========================
function Hide-Cursor { Write-Host "$E[?25l" -NoNewline }
function Show-Cursor { Write-Host "$E[?25h" -NoNewline }
function Clear-Screen { Write-Host "$E[2J" -NoNewline }

function Set-Pos {
    param([int]$y, [int]$x)
    if ($x -ge 0 -and $y -ge 0 -and
        $x -lt [Console]::WindowWidth -and
        $y -lt [Console]::WindowHeight) {
        Write-Host "$E[${y};${x}H" -NoNewline
    }
}

# ============================================================
# FASE 1: TEIA FRACTAL (Exploração / Curiosidade)
# ============================================================
function Invoke-FractalWeb {
    Clear-Screen
    $W = [Console]::WindowWidth
    $H = [Console]::WindowHeight
    $CenterX = [math]::Round($W / 2)
    $CenterY = [math]::Round($H / 2)
    
    $Nodes = @()
    0..40 | ForEach-Object {
        # Mix de cores frias → sensação de profundidade e calma
        $colorPool = @($C_Deep, $C_BrandSoft, $C_GreySoft)
        $Nodes += [PSCustomObject]@{
            X     = $CenterX
            Y     = $CenterY
            DX    = (Get-Random -Min -2 -Max 3)
            DY    = (Get-Random -Min -1 -Max 2)
            Char  = (Get-Random ".", "·", "+", "x")
            Color = (Get-Random -InputObject $colorPool)
        }
    }

    for ($frame = 0; $frame -lt 30; $frame++) {
        foreach ($n in $Nodes) {
            if ($n.X -gt 0 -and $n.X -lt $W -and $n.Y -gt 0 -and $n.Y -lt $H) {
                Write-Host "$E[$([int]$n.Y);$([int]$n.X)H " -NoNewline
            }

            $n.X += $n.DX * (1 + ($frame / 20))
            $n.Y += $n.DY

            if ($n.X -gt 1 -and $n.X -lt $W -and $n.Y -gt 1 -and $n.Y -lt $H) {
                Write-Host "$E[$([int]$n.Y);$([int]$n.X)H$($n.Color)$($n.Char)$R" -NoNewline
            }
        }
        Start-Sleep -Milliseconds 30
    }
}

# ============================================================
# FASE 2: NÚCLEO (Foco / Energia concentrada)
# ============================================================
function Invoke-CoreImplosion {
    $W = [Console]::WindowWidth
    $H = [Console]::WindowHeight
    $CX = $W / 2
    $CY = $H / 2

    for ($r = 20; $r -ge 2; $r -= 2) {
        $Steps = 18
        for ($i = 0; $i -lt $Steps; $i++) {
            $Angle = ($i / $Steps) * 2 * [math]::PI
            $X = [int]($CX + [math]::Cos($Angle) * $r * 2)
            $Y = [int]($CY + [math]::Sin($Angle) * $r)

            if ($X -gt 0 -and $X -lt $W -and $Y -gt 0 -and $Y -lt $H) {
                # Gradiente simbólico: periferia mais profunda, centro mais brilhante
                $color = if ($r -gt 12) {
                    $C_Deep
                } elseif ($r -gt 6) {
                    $C_BrandSoft
                } else {
                    $C_Brand
                }
                # Aqui você pode trocar "o" por "o$r" se quiser os rótulos numéricos
                Write-Host "$E[$Y;${X}H${color}o$R" -NoNewline
            }
        }
        Start-Sleep -Milliseconds 40
    }

    # Flash Central – energia / nascimento da identidade
    Write-Host "$E[$([int]$CY);$([int]$CX-2)H${C_AccentWarm}█████$R" -NoNewline
    Start-Sleep -Milliseconds 120
}

# ============================================================
# FASE 3: BANNER GLITCH (Revelação da Marca)
# ============================================================
function Invoke-GlitchBanner {
    $W = [Console]::WindowWidth
    $BannerWidth = $banner[0].Length

    # Centro ideal do banner
    $PadLeftIdeal = [int](($W - $BannerWidth) / 2)

    # Coordenada do raio 12 na esquerda (mesma da implosão)
    $CX  = $W / 2
    $X12 = [int]($CX - 24)

    # Largura máxima de um rótulo tipo "o12"
    $LabelWidth = 3
    $MinPadLeft = $X12 + $LabelWidth

    # Pad final: o mais central possível sem encobrir o12
    $PadLeft = $PadLeftIdeal
    if ($PadLeft -le $MinPadLeft) {
        $PadLeft = $MinPadLeft
    }
    if ($PadLeft -lt 0) { $PadLeft = 0 }

    $StartRow = [int]([Console]::WindowHeight / 2) - 4
    
    $Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%"

    # Glitch curto
    for ($i = 0; $i -lt 3; $i++) {
        $Row = $StartRow
        foreach ($line in $banner) {
            $CorruptLine = ""
            0..($line.Length - 1) | ForEach-Object {
                if ((Get-Random) % 10 -gt 7) {
                    $CorruptLine += $Chars[(Get-Random) % $Chars.Length]
                } else {
                    $CorruptLine += $line[$_]
                }
            }
            $Color = if ($i % 2 -eq 0) { $C_Glitch } else { $C_BrandSoft }
            Write-Host "$E[$Row;${PadLeft}H$Color$CorruptLine$R" -NoNewline
            $Row++
        }
        Start-Sleep -Milliseconds 55
    }

    # Estabilização Final
    $Row = $StartRow
    foreach ($line in $banner) {
        Write-Host "$E[$Row;${PadLeft}H$C_Brand$line$R" -NoNewline
        Start-Sleep -Milliseconds 45
        $Row++
    }
}

# ============================================================
# FASE 4: HYPER-FLUX IDENTITY ENGINE (Confirmação + CTA)
# ============================================================

# Fundo sutil – mantém contexto, não apaga tudo
function Draw-BackgroundWeb {
    $w = [Console]::WindowWidth
    $h = [Console]::WindowHeight
    $Density = 60

    for ($i = 0; $i -lt $Density; $i++) {
        $x = Get-Random -Min 1 -Max $w
        $y = Get-Random -Min 1 -Max $h
        $Sym   = Get-Random -InputObject @("·", ".", "`"", "*")
        $Color = Get-Random -InputObject @($C_Grey, $C_GreySoft, $C_Deep)
        Set-Pos $y $x
        Write-Host "$Color$Sym$R" -NoNewline
    }
}

# Pulso Central – “coração” da TEIA OS
function Draw-Pulse {
    $cx = [int]([Console]::WindowWidth / 2)
    $cy = [int]([Console]::WindowHeight / 2)
    
    for ($r = 1; $r -lt 12; $r++) {
        $Steps = 12 + ($r * 2)
        for ($theta = 0; $theta -lt 360; $theta += (360 / $Steps)) {
            $rad = $theta * [Math]::PI / 180
            $x = [int]($cx + ([Math]::Cos($rad) * $r * 2))
            $y = [int]($cy + ([Math]::Sin($rad) * $r))

            Set-Pos $y $x

            $color = if ($r -le 3) {
                $C_Deep
            } elseif ($r -le 7) {
                $C_Brand
            } elseif ($r -lt 11) {
                $C_BrandSoft
            } else {
                $C_AccentWarm
            }

            if ($r -eq 11) { Write-Host "${C_Grey}░$R" -NoNewline }
            else           { Write-Host "${color}•$R" -NoNewline }
        }
        Start-Sleep -Milliseconds 40
    }
}

# Decodificação do Banner – reforça identidade e “inteligência”
function Invoke-DecodeBanner {
    $W        = [Console]::WindowWidth
    $StartRow = [int]([Console]::WindowHeight / 2) - 4
    
    $MaxLen      = ($banner | Measure-Object -Property Length -Maximum).Maximum
    $PadLeftIdeal = [int](($W - $MaxLen) / 2)

    # Mesmo cálculo de proteção do o12 usado no GlitchBanner
    $CX  = $W / 2
    $X12 = [int]($CX - 24)
    $LabelWidth = 3
    $MinPadLeft = $X12 + $LabelWidth

    $PadLeft = $PadLeftIdeal
    if ($PadLeft -le $MinPadLeft) {
        $PadLeft = $MinPadLeft
    }
    if ($PadLeft -lt 0) { $PadLeft = 0 }

    $Chars   = "█▓▒░@#&+="
    
    for ($i = 0; $i -lt $banner.Count; $i++) {
        $Line = $banner[$i]
        $Row  = $StartRow + $i

        # Glitch controlado
        Set-Pos $Row $PadLeft
        Write-Host "$C_Glitch$($Line -replace '.', '▒')$R" -NoNewline
        Start-Sleep -Milliseconds 45

        # Identidade firme
        Set-Pos $Row $PadLeft
        Write-Host "$C_Brand$Line$R" -NoNewline
        Start-Sleep -Milliseconds 45
    }
}

# HUD – copy e cor pensadas para CTA amigável
function Draw-HUD {
    $Row = [Console]::WindowHeight - 4
    $W   = [Console]::WindowWidth

    $msgCore    = "SYSTEM READY  ·  PRESS ENTER TO LINK"
    $innerWidth = $msgCore.Length + 2    # espaços internos
    $boxWidth   = $innerWidth + 2        # bordas

    $topLine    = "╔" + ("═" * $innerWidth) + "╗"
    $middleLine = "║ " + $msgCore + " ║"
    $bottomLine = "╚" + ("═" * $innerWidth) + "╝"

    $Pad = [int](($W - $boxWidth) / 2)
    if ($Pad -lt 0) { $Pad = 0 }

    Set-Pos $Row $Pad
    Write-Host "${C_Grey}$topLine$R"

    Set-Pos ($Row + 1) $Pad
    Write-Host "${C_Grey}$middleLine$R"

    Set-Pos ($Row + 2) $Pad
    Write-Host "${C_Grey}$bottomLine$R"
}

# ============================================================
# SEQUÊNCIA DE EXECUÇÃO
# ============================================================
try {
    Hide-Cursor
    Clear-Screen

    # 1. Exploração (teia fractal)
    Invoke-FractalWeb

    # 2. Foco no núcleo (implosão)
    Invoke-CoreImplosion

    # 3. Identidade emergindo (glitch → estabilização)
    Invoke-GlitchBanner

    # 4. Engine + estado final (confirmação + CTA visual)
    Draw-BackgroundWeb
    Start-Sleep -Milliseconds 200
    Draw-Pulse
    Invoke-DecodeBanner
    Draw-HUD

    # reposiciona o cursor longe da HUD
    Set-Pos ([Console]::WindowHeight - 2) 2
}
catch {
    Write-Host "$E[0m$E[?25h"
}
finally {
    Show-Cursor
    Write-Host ""
}
```

Se depois disso o “TEIA OS” ainda parecer ligeiramente à direita pra você, o próximo passo seria escolher:  
- ou deixamos tudo 100% centrado e aceitamos o `o12` um pouco mais “colado”,  
- ou mantemos essa folguinha pra que o rótulo numérico fique perfeito.

Mas com esse ajuste, o `o1` vira `o12` completo e aquele caractere perdido na parte de baixo deixa de aparecer.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_000000004b7071f5b32492368bb6fa35', 'size_bytes': 76323, 'width': 1025, 'height': 871, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

from PIL import Image, ImageOps, ImageFilter, ImageEnhance, ImageStat, ImageChops, ImageFont, ImageDraw

img = Image.open('/mnt/data/8d8b8c11-f812-443f-8b36-ec614ee81fb6.png')
display(img.resize((903,768)))


---

### ASSISTENTE

# crop middle region to see left horizontal line
w,h = img.size
crop = img.crop((0, h//2-150, w, h//2+100))
display(crop.resize((903, 250)))


---

### ASSISTENTE

crop2 = img.crop((0, h//2-40, w//2+100, h//2+40))
display(crop2.resize((903, 250)))


---

### ASSISTENTE

Perfeito, vamos deixar o “TEIA OS” **exatamente alinhado** com o centro da estrutura circular.

A única coisa que precisamos mexer “cirurgicamente” é o cálculo de `PadLeft` nas funções
`Invoke-GlitchBanner` e `Invoke-DecodeBanner`, para que:

- o centro visual do banner fique exatamente em cima do **mesmo centro** usado na implosão (`$CX = $W / 2`).

Abaixo vão apenas as **duas funções já corrigidas** – é só substituir essas versões no seu script atual.

---

### `Invoke-GlitchBanner` (versão centralizada)

```powershell
function Invoke-GlitchBanner {
    $W = [Console]::WindowWidth

    # Largura real do banner (maior linha)
    $BannerWidth = ($banner | Measure-Object -Property Length -Maximum).Maximum

    # Mesmo centro da estrutura circular (Invoke-CoreImplosion)
    $CenterCol  = [int]($W / 2)

    # Para largura ímpar, o “centro” está em: PadLeft + (BannerWidth - 1) / 2
    $HalfBanner = [int](($BannerWidth - 1) / 2)
    $PadLeft    = $CenterCol - $HalfBanner
    if ($PadLeft -lt 0) { $PadLeft = 0 }

    $StartRow = [int]([Console]::WindowHeight / 2) - 4
    
    $Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%"

    # Glitch curto em vermelho/magenta → atenção rápida
    for ($i = 0; $i -lt 3; $i++) {
        $Row = $StartRow
        foreach ($line in $banner) {
            $CorruptLine = ""
            0..($line.Length - 1) | ForEach-Object {
                if ((Get-Random) % 10 -gt 7) {
                    $CorruptLine += $Chars[(Get-Random) % $Chars.Length]
                } else {
                    $CorruptLine += $line[$_]
                }
            }
            $Color = if ($i % 2 -eq 0) { $C_Glitch } else { $C_BrandSoft }
            Write-Host "$E[$Row;${PadLeft}H$Color$CorruptLine$R" -NoNewline
            $Row++
        }
        Start-Sleep -Milliseconds 55
    }

    # Estabilização Final – logo 100% firme em ciano
    $Row = $StartRow
    foreach ($line in $banner) {
        Write-Host "$E[$Row;${PadLeft}H$C_Brand$line$R" -NoNewline
        Start-Sleep -Milliseconds 45
        $Row++
    }
}
```

---

### `Invoke-DecodeBanner` (mesmo alinhamento do Glitch)

```powershell
function Invoke-DecodeBanner {
    $W        = [Console]::WindowWidth
    $StartRow = [int]([Console]::WindowHeight / 2) - 4
    
    $MaxLen     = ($banner | Measure-Object -Property Length -Maximum).Maximum
    $BannerWidth = $MaxLen

    # Mesmo centro da estrutura circular
    $CenterCol  = [int]($W / 2)
    $HalfBanner = [int](($BannerWidth - 1) / 2)
    $PadLeft    = $CenterCol - $HalfBanner
    if ($PadLeft -lt 0) { $PadLeft = 0 }

    $Chars   = "█▓▒░@#&+="
    
    for ($i = 0; $i -lt $banner.Count; $i++) {
        $Line = $banner[$i]
        $Row  = $StartRow + $i

        # 1) Passo “glitch” (codificação)
        Set-Pos $Row $PadLeft
        Write-Host "$C_Glitch$($Line -replace '.', '▒')$R" -NoNewline
        Start-Sleep -Milliseconds 45

        # 2) Passo final – identidade firme em ciano
        Set-Pos $Row $PadLeft
        Write-Host "$C_Brand$Line$R" -NoNewline
        Start-Sleep -Milliseconds 45
    }
}
```

---

Com essas duas funções:

- o centro do texto **TEIA OS** fica alinhado com o mesmo `$CX` usado na implosão;
- `Glitch` e `Decode` usam exatamente o mesmo `PadLeft`, então o logo não “pula”.

Cole essas duas versões no lugar das suas atuais e execute de novo: o TEIA OS deve encaixar certinho no miolo da estrutura circular.

---

### USUÁRIO

Forneça o bloco script corrigido completo corrigido

---

### ASSISTENTE

Segue o script completo, já com o **“TEIA OS” centralizado** na estrutura circular (ajuste em `Invoke-GlitchBanner` e `Invoke-DecodeBanner`) e mantendo as demais correções:

```powershell
# ============================================================
# TEIA OS – Hyper-Fluid Boot + HYPER-FLUX IDENTITY ENGINE (v4 – NeuroTuned)
# ============================================================

$E = [char]27

# Ambiente
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Global:ErrorActionPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "TEIA OS | KERNEL BOOT SEQUENCE"

# Paleta – alinhada com psicologia das cores
$C_Brand       = "$E[38;5;51m"   # Ciano – principal (tecnologia, confiança)
$C_BrandSoft   = "$E[38;5;45m"   # Ciano suave – transições suaves
$C_Deep        = "$E[38;5;23m"   # Azul profundo – base / profundidade
$C_Purple      = "$E[38;5;135m"  # Roxo – futurismo/inovação
$C_AccentWarm  = "$E[38;5;214m"  # Laranja suave – foco/ação/atenção
$C_TextSoft    = "$E[38;5;250m"  # Texto suave – legibilidade
$C_White       = "$E[38;5;255m"  # Branco – flashes/realce máximo
$C_Glitch      = "$E[38;5;160m"  # Vermelho magenta – glitch curto (não dominante)
$C_Grey        = "$E[38;5;236m"  # Fundo quase preto / linhas discretas
$C_GreySoft    = "$E[38;5;238m"
$R             = "$E[0m"

# Banner TEIA OS (identidade)
$banner = @(
    "████████╗███████╗██╗ █████╗      ██████╗ ███████╗",
    "╚══██╔══╝██╔════╝██║██╔══██╗    ██╔═══██╗██╔════╝",
    "   ██║   █████╗  ██║███████║    ██║   ██║███████╗",
    "   ██║   ██╔══╝  ██║██╔══██║    ██║   ██║╚════██║",
    "   ██║   ███████╗██║██║  ██║    ╚██████╔╝███████║",
    "   ╚═╝   ╚══════╝╚═╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝"
)

# ==========================
# FUNÇÕES GERAIS
# ==========================
function Hide-Cursor { Write-Host "$E[?25l" -NoNewline }
function Show-Cursor { Write-Host "$E[?25h" -NoNewline }
function Clear-Screen { Write-Host "$E[2J" -NoNewline }

function Set-Pos {
    param([int]$y, [int]$x)
    if ($x -ge 0 -and $y -ge 0 -and
        $x -lt [Console]::WindowWidth -and
        $y -lt [Console]::WindowHeight) {
        Write-Host "$E[${y};${x}H" -NoNewline
    }
}

# ============================================================
# FASE 1: TEIA FRACTAL (Exploração / Curiosidade)
# ============================================================
function Invoke-FractalWeb {
    Clear-Screen
    $W = [Console]::WindowWidth
    $H = [Console]::WindowHeight
    $CenterX = [math]::Round($W / 2)
    $CenterY = [math]::Round($H / 2)
    
    $Nodes = @()
    0..40 | ForEach-Object {
        # Mix de cores frias → sensação de profundidade e calma
        $colorPool = @($C_Deep, $C_BrandSoft, $C_GreySoft)
        $Nodes += [PSCustomObject]@{
            X     = $CenterX
            Y     = $CenterY
            DX    = (Get-Random -Min -2 -Max 3)
            DY    = (Get-Random -Min -1 -Max 2)
            Char  = (Get-Random ".", "·", "+", "x")
            Color = (Get-Random -InputObject $colorPool)
        }
    }

    for ($frame = 0; $frame -lt 30; $frame++) {
        foreach ($n in $Nodes) {
            if ($n.X -gt 0 -and $n.X -lt $W -and $n.Y -gt 0 -and $n.Y -lt $H) {
                Write-Host "$E[$([int]$n.Y);$([int]$n.X)H " -NoNewline
            }

            $n.X += $n.DX * (1 + ($frame / 20))
            $n.Y += $n.DY

            if ($n.X -gt 1 -and $n.X -lt $W -and $n.Y -gt 1 -and $n.Y -lt $H) {
                Write-Host "$E[$([int]$n.Y);$([int]$n.X)H$($n.Color)$($n.Char)$R" -NoNewline
            }
        }
        Start-Sleep -Milliseconds 30
    }
}

# ============================================================
# FASE 2: NÚCLEO (Foco / Energia concentrada)
# ============================================================
function Invoke-CoreImplosion {
    $W = [Console]::WindowWidth
    $H = [Console]::WindowHeight
    $CX = $W / 2
    $CY = $H / 2

    for ($r = 20; $r -ge 2; $r -= 2) {
        $Steps = 18
        for ($i = 0; $i -lt $Steps; $i++) {
            $Angle = ($i / $Steps) * 2 * [math]::PI
            $X = [int]($CX + [math]::Cos($Angle) * $r * 2)
            $Y = [int]($CY + [math]::Sin($Angle) * $r)

            if ($X -gt 0 -and $X -lt $W -and $Y -gt 0 -and $Y -lt $H) {
                # Gradiente simbólico: periferia mais profunda, centro mais brilhante
                $color = if ($r -gt 12) {
                    $C_Deep
                } elseif ($r -gt 6) {
                    $C_BrandSoft
                } else {
                    $C_Brand
                }
                # Se quiser rótulos numéricos: troque "o" por "o$r"
                Write-Host "$E[$Y;${X}H${color}o$R" -NoNewline
            }
        }
        Start-Sleep -Milliseconds 40
    }

    # Flash Central – energia / nascimento da identidade
    Write-Host "$E[$([int]$CY);$([int]$CX-2)H${C_AccentWarm}█████$R" -NoNewline
    Start-Sleep -Milliseconds 120
}

# ============================================================
# FASE 3: BANNER GLITCH (Revelação da Marca)
# ============================================================
function Invoke-GlitchBanner {
    $W = [Console]::WindowWidth

    # Largura real do banner (maior linha)
    $BannerWidth = ($banner | Measure-Object -Property Length -Maximum).Maximum

    # Mesmo centro da estrutura circular (Invoke-CoreImplosion)
    $CenterCol  = [int]($W / 2)

    # Para largura ímpar, o “centro” está em: PadLeft + (BannerWidth - 1) / 2
    $HalfBanner = [int](($BannerWidth - 1) / 2)
    $PadLeft    = $CenterCol - $HalfBanner
    if ($PadLeft -lt 0) { $PadLeft = 0 }

    $StartRow = [int]([Console]::WindowHeight / 2) - 4
    $Chars    = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%"

    # Glitch curto em vermelho/magenta → atenção rápida
    for ($i = 0; $i -lt 3; $i++) {
        $Row = $StartRow
        foreach ($line in $banner) {
            $CorruptLine = ""
            0..($line.Length - 1) | ForEach-Object {
                if ((Get-Random) % 10 -gt 7) {
                    $CorruptLine += $Chars[(Get-Random) % $Chars.Length]
                } else {
                    $CorruptLine += $line[$_]
                }
            }
            $Color = if ($i % 2 -eq 0) { $C_Glitch } else { $C_BrandSoft }
            Write-Host "$E[$Row;${PadLeft}H$Color$CorruptLine$R" -NoNewline
            $Row++
        }
        Start-Sleep -Milliseconds 55
    }

    # Estabilização Final – logo 100% firme em ciano
    $Row = $StartRow
    foreach ($line in $banner) {
        Write-Host "$E[$Row;${PadLeft}H$C_Brand$line$R" -NoNewline
        Start-Sleep -Milliseconds 45
        $Row++
    }
}

# ============================================================
# FASE 4: HYPER-FLUX IDENTITY ENGINE (Confirmação + CTA)
# ============================================================

# Fundo sutil – mantém contexto, não apaga tudo
function Draw-BackgroundWeb {
    $w = [Console]::WindowWidth
    $h = [Console]::WindowHeight
    $Density = 60

    for ($i = 0; $i -lt $Density; $i++) {
        $x = Get-Random -Min 1 -Max $w
        $y = Get-Random -Min 1 -Max $h
        $Sym   = Get-Random -InputObject @("·", ".", "`"", "*")
        $Color = Get-Random -InputObject @($C_Grey, $C_GreySoft, $C_Deep)
        Set-Pos $y $x
        Write-Host "$Color$Sym$R" -NoNewline
    }
}

# Pulso Central – “coração” da TEIA OS
function Draw-Pulse {
    $cx = [int]([Console]::WindowWidth / 2)
    $cy = [int]([Console]::WindowHeight / 2)
    
    for ($r = 1; $r -lt 12; $r++) {
        $Steps = 12 + ($r * 2)
        for ($theta = 0; $theta -lt 360; $theta += (360 / $Steps)) {
            $rad = $theta * [Math]::PI / 180
            $x = [int]($cx + ([Math]::Cos($rad) * $r * 2))
            $y = [int]($cy + ([Math]::Sin($rad) * $r))

            Set-Pos $y $x

            # Gradiente emocional
            $color = if ($r -le 3) {
                $C_Deep
            } elseif ($r -le 7) {
                $C_Brand
            } elseif ($r -lt 11) {
                $C_BrandSoft
            } else {
                $C_AccentWarm
            }

            if ($r -eq 11) { Write-Host "${C_Grey}░$R" -NoNewline }
            else           { Write-Host "${color}•$R" -NoNewline }
        }
        Start-Sleep -Milliseconds 40
    }
}

# Decodificação do Banner – reforça identidade e “inteligência”
function Invoke-DecodeBanner {
    $W        = [Console]::WindowWidth
    $StartRow = [int]([Console]::WindowHeight / 2) - 4
    
    $BannerWidth = ($banner | Measure-Object -Property Length -Maximum).Maximum

    # Mesmo centro da estrutura circular
    $CenterCol  = [int]($W / 2)
    $HalfBanner = [int](($BannerWidth - 1) / 2)
    $PadLeft    = $CenterCol - $HalfBanner
    if ($PadLeft -lt 0) { $PadLeft = 0 }

    $Chars   = "█▓▒░@#&+="
    
    for ($i = 0; $i -lt $banner.Count; $i++) {
        $Line = $banner[$i]
        $Row  = $StartRow + $i

        # Glitch como “codificação” – curto e controlado
        Set-Pos $Row $PadLeft
        Write-Host "$C_Glitch$($Line -replace '.', '▒')$R" -NoNewline
        Start-Sleep -Milliseconds 45

        # Identidade firme em ciano
        Set-Pos $Row $PadLeft
        Write-Host "$C_Brand$Line$R" -NoNewline
        Start-Sleep -Milliseconds 45
    }
}

# HUD – copy e cor pensadas para CTA amigável
function Draw-HUD {
    $Row = [Console]::WindowHeight - 4
    $W   = [Console]::WindowWidth

    $msgCore    = "SYSTEM READY  ·  PRESS ENTER TO LINK"
    $innerWidth = $msgCore.Length + 2    # espaços internos
    $boxWidth   = $innerWidth + 2        # bordas

    $topLine    = "╔" + ("═" * $innerWidth) + "╗"
    $middleLine = "║ " + $msgCore + " ║"
    $bottomLine = "╚" + ("═" * $innerWidth) + "╝"

    $Pad = [int](($W - $boxWidth) / 2)
    if ($Pad -lt 0) { $Pad = 0 }

    Set-Pos $Row $Pad
    Write-Host "${C_Grey}$topLine$R"

    Set-Pos ($Row + 1) $Pad
    Write-Host "${C_Grey}$middleLine$R"

    Set-Pos ($Row + 2) $Pad
    Write-Host "${C_Grey}$bottomLine$R"
}

# ============================================================
# SEQUÊNCIA DE EXECUÇÃO
# ============================================================
try {
    Hide-Cursor
    Clear-Screen

    # 1. Exploração (teia fractal)
    Invoke-FractalWeb

    # 2. Foco no núcleo (implosão)
    Invoke-CoreImplosion

    # 3. Identidade emergindo (glitch → estabilização)
    Invoke-GlitchBanner

    # 4. Engine + estado final (confirmação + CTA visual)
    Draw-BackgroundWeb
    Start-Sleep -Milliseconds 200
    Draw-Pulse
    Invoke-DecodeBanner
    Draw-HUD

    # reposiciona o cursor longe da HUD
    Set-Pos ([Console]::WindowHeight - 2) 2
}
catch {
    Write-Host "$E[0m$E[?25h"
}
finally {
    Show-Cursor
    Write-Host ""
}
```

Se depois de rodar você achar que o centro visual ainda pode ser ajustado um ou dois caracteres, dá pra fazer um “micro-trim” mudando só `PadLeft = $CenterCol - $HalfBanner ± 1`, mas estruturalmente ele já está alinhado ao mesmo centro usado na animação circular.

---

