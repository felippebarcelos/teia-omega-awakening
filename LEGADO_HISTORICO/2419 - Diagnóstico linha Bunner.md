# 2419 - Diagnóstico linha Bunner

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_000000006bb471f5b5a5f8ead0d28cd9', 'size_bytes': 219083, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

from PIL import Image, ImageOps, ImageFilter, ImageEnhance, ImageStat, ImageChops, ImageFilter
img1 = Image.open('/mnt/data/71b3fcbc-549e-4744-b6cd-7b777f905e8f.png')
display(img1.resize((1024,576)))


---

### ASSISTENTE

# crop region where left line is, roughly
w,h = img1.size
crop = img1.crop((0,h//3, w//2, h*2//3))
display(crop.resize((512,256)))


---

### ASSISTENTE

crop2 = img1.crop((0,h//2-100, w//2, h//2+50))
display(crop2.resize((512,256)))


---

### ASSISTENTE

crop3 = img1.crop((w//4-200,h//2-50, w//4+100,h//2+50))
display(crop3.resize((512,256)))


---

### ASSISTENTE

# find approximate coordinates of that text by scanning for bright cyan near middle-left
import numpy as np

small = img1.resize((512,288))
arr = np.array(small)
# find bright cyan-like pixels (high G,B, low R)
mask = (arr[:,:,1] > 200) & (arr[:,:,2] > 200) & (arr[:,:,0] < 80)
ys,xs = np.where(mask)
ys.mean(), xs.mean()


---

### ASSISTENTE

cx,cy = 252,118
crop4 = small.crop((150,cy-40,260,cy+40))
display(crop4.resize((512,256)))


---

### ASSISTENTE

crop5 = small.crop((100,cy-40,210,cy+40))
display(crop5.resize((512,256)))


---

### ASSISTENTE

crop6 = small.crop((70,cy-40,180,cy+40))
display(crop6.resize((512,256)))


---

### ASSISTENTE

banner = [
"████████╗███████╗██╗ █████╗      ██████╗ ███████╗",
"╚══██╔══╝██╔════╝██║██╔══██╗    ██╔═══██╗██╔════╝",
"   ██║   █████╗  ██║███████║    ██║   ██║███████╗",
"   ██║   ██╔══╝  ██║██╔══██║    ██║   ██║╚════██║",
"   ██║   ███████╗██║██║  ██║    ╚██████╔╝███████║",
"   ╚═╝   ╚══════╝╚═╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝"
]
len(banner[0])


---

### ASSISTENTE

1) Por que a linha “reta” da esquerda vai de o20 até o14 e não até o12  

O trecho que desenha esses “oXX” é a implosão do núcleo:

```powershell
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
```

Para o raio da esquerda (ângulo 180°), a coordenada horizontal fica:

- `X_r = CX - 2*r`

O banner é desenhado depois, começando em:

```powershell
$BannerWidth = $banner[0].Length   # 49
$PadLeft = [math]::Max(0, [int](($W - $BannerWidth) / 2))
...
Write-Host "$E[$Row;${PadLeft}H$Color$CorruptLine$R"
```

Ou seja, a primeira coluna do banner é `PadLeft`.

Se você fizer as contas:

- `CX ≈ W/2`
- `PadLeft ≈ CX - 25`
- Ponto do raio r=12 na esquerda: `X_12 = CX - 24`

Resultado:

- `X_20, X_18, X_16, X_14` ficam **à esquerda** de `PadLeft` → não são tocados.
- `X_12 = CX - 24` cai **dentro da faixa do banner** (`PadLeft` até `PadLeft + 48`).

Então o “o12” até existe, mas é desenhado antes e depois é sobrescrito pelo próprio banner TEIA OS. Visualmente parece que a linha só vai de o20 até o14 porque o elemento correspondente ao raio 12 fica exatamente na área ocupada pelo “T”.

Resumo: não é um erro de geometria do círculo; é *overdraw*: o banner cobre o ponto do raio 12.

---

2) Por que a sequência linear some depois da animação do “decodificado”

Na fase `Invoke-DecodeBanner` você faz isto:

```powershell
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
```

Aqui acontecem duas coisas:

1. `Set-Pos $Row 0` posiciona o cursor na coluna 0.
2. `"$Spaces ..."` escreve **$PadLeft espaços** antes da linha do banner.

Esses espaços são literalmente caracteres `' '` desenhados da coluna 0 até `PadLeft-1`. Qualquer coisa que estava ali (incluindo aquela linha reta de “oXX” à esquerda) é apagada.

Por isso, após a animação de decodificação:

- Toda a região à esquerda do banner nas mesmas linhas de Y do logo é sobrescrita por espaços.
- A sua “linha linear” desaparece nessas linhas, mesmo os pontos que tinham sobrevivido ao `Invoke-GlitchBanner`.

Se quiser manter a linha viva mesmo depois do decodificado, o ajuste conceitual é:

- Em `Invoke-DecodeBanner`, escrever o banner a partir de `PadLeft` sem despejar espaços antes, como você já faz em `Invoke-GlitchBanner`.

Em termos de lógica, seria algo como trocar:

```powershell
Set-Pos $Row 0
Write-Host "$Spaces$C_Glitch ..."

Set-Pos $Row 0
Write-Host "$Spaces$C_Brand$Line$R"
```

por algo equivalente a:

```powershell
Set-Pos $Row $PadLeft
Write-Host "$C_Glitch ..."

Set-Pos $Row $PadLeft
Write-Host "$C_Brand$Line$R"
```

Assim o decodificado não limpa a área da esquerda, e a linha de raios permanece visível.

---

### USUÁRIO

Porque esse sugestão de correção completa chega proóximo mais ainda não alcança a sobreposição da região T e mantém o elemento "o12" como background? para uma sensação de maior imersão com cada linha transfredindo em back ground

---

### USUÁRIO

Porque esse sugestão de correção completa chega proóximo mais ainda não alcança a sobreposição da região T e mantém o elemento "o12" como background? para uma sensação de maior imersão com cada linha transfredindo em back ground?

"""# ============================================================
# TEIA OS – Hyper-Fluid Boot + HYPER-FLUX IDENTITY ENGINE (v4.1 – Stable)
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
    "████████╗███████╗██╗ █████╗       ██████╗ ███████╗",
    "╚══██╔══╝██╔════╝██║██╔══██╗     ██╔═══██╗██╔════╝",
    "   ██║   █████╗  ██║███████║     ██║   ██║███████╗",
    "   ██║   ██╔══╝  ██║██╔══██║     ██║   ██║╚════██║",
    "   ██║   ███████╗██║██║  ██║     ╚██████╔╝███████║",
    "   ╚═╝   ╚══════╝╚═╝╚═╝  ╚═╝      ╚═════╝ ╚══════╝"
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
                $color = if ($r -gt 12) { $C_Deep } elseif ($r -gt 6) { $C_BrandSoft } else { $C_Brand }
                Write-Host "$E[$Y;${X}H${color}o$R" -NoNewline
            }
        }
        Start-Sleep -Milliseconds 40
    }
    Write-Host "$E[$([int]$CY);$([int]$CX-2)H${C_AccentWarm}█████$R" -NoNewline
    Start-Sleep -Milliseconds 120
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

function Draw-BackgroundWeb {
    $w = [Console]::WindowWidth
    $h = [Console]::WindowHeight
    $Density = 60
    for ($i = 0; $i -lt $Density; $i++) {
        $x = Get-Random -Min 1 -Max $w
        $y = Get-Random -Min 1 -Max $h
        $Sym    = Get-Random -InputObject @("·", ".", "`"", "*")
        $Color = Get-Random -InputObject @($C_Grey, $C_GreySoft, $C_Deep)
        Set-Pos $y $x
        Write-Host "$Color$Sym$R" -NoNewline
    }
}

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
            $color = if ($r -le 3) { $C_Deep } elseif ($r -le 7) { $C_Brand } elseif ($r -lt 11) { $C_BrandSoft } else { $C_AccentWarm }
            if ($r -eq 11) { Write-Host "${C_Grey}░$R" -NoNewline }
            else           { Write-Host "${color}•$R" -NoNewline }
        }
        Start-Sleep -Milliseconds 40
    }
}

# [CORREÇÃO 1: LINHA ESQUERDA PRESERVADA]
# O cursor pula direto para o texto, não apagando a esquerda.
function Invoke-DecodeBanner {
    $StartRow  = [int]([Console]::WindowHeight / 2) - 4
    $CenterCol = [int]([Console]::WindowWidth / 2)
    $MaxLen  = ($banner | Measure-Object -Property Length -Maximum).Maximum
    $PadLeft = $CenterCol - [int]($MaxLen / 2)
    if ($PadLeft -lt 0) { $PadLeft = 0 }

    for ($i = 0; $i -lt $banner.Count; $i++) {
        $Line = $banner[$i]
        $Row  = $StartRow + $i

        # Glitch Pass - Pulo não destrutivo
        Set-Pos $Row $PadLeft
        Write-Host "$C_Glitch$($Line -replace '.', '▒')$R" -NoNewline
        Start-Sleep -Milliseconds 45

        # Final Pass - Pulo não destrutivo
        Set-Pos $Row $PadLeft
        Write-Host "$C_Brand$Line$R" -NoNewline
        Start-Sleep -Milliseconds 45
    }
}

# [CORREÇÃO 2: HUD PERFEITAMENTE ALINHADO]
# A largura da caixa agora é calculada matematicamente baseada no texto.
function Draw-HUD {
    $Row = [Console]::WindowHeight - 4
    $W   = [Console]::WindowWidth

    # 1. Definir conteúdo exato
    # "║ " (2) + "SYSTEM READY..." (36) + " ║" (2) = 40 chars
    # "SYSTEM READY  ·  " = 17 chars
    # "PRESS ENTER" = 11 chars
    # " TO LINK" = 8 chars
    # Total texto = 36 chars.
    
    # 2. Construir linha do meio para medir comprimento real visível
    $InnerContent = "SYSTEM READY  ·  PRESS ENTER TO LINK"
    $TotalWidth   = 2 + $InnerContent.Length + 2 # Bordas "║ " e " ║"
    
    # 3. Construir bordas baseadas nessa largura
    # Subtraímos 2 para os cantos (╔ e ╗)
    $HorizontalBar = "═" * ($TotalWidth - 2)
    $TopBorder     = "${C_Grey}╔${HorizontalBar}╗${R}"
    $BottomBorder  = "${C_Grey}╚${HorizontalBar}╝${R}"

    # 4. Calcular centralização
    $Pad = [int](($W - $TotalWidth) / 2)

    # 5. Renderizar
    Set-Pos $Row $Pad
    Write-Host $TopBorder
    
    Set-Pos ($Row + 1) $Pad
    # Montagem cuidadosa da string colorida
    Write-Host (
        "${C_Grey}║ " +
        "${C_TextSoft}SYSTEM READY  ·  " +
        "${C_AccentWarm}PRESS ENTER${C_TextSoft} TO LINK" +
        " ${C_Grey}║$R"
    )

    Set-Pos ($Row + 2) $Pad
    Write-Host $BottomBorder
}

# ============================================================
# SEQUÊNCIA DE EXECUÇÃO
# ============================================================
try {
    Hide-Cursor
    Clear-Screen
    Invoke-FractalWeb
    Invoke-CoreImplosion
    Invoke-GlitchBanner
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
}"""



---

### ASSISTENTE

Porque, do jeito que está, a correção só resolveu **“quem apaga a esquerda”**, mas não mexeu em **“quem desenha por cima do o12”**.

Vou separar:

---

### 1. O que a correção realmente mudou

Na `Invoke-DecodeBanner` antiga você fazia:

```powershell
Set-Pos $Row 0
Write-Host "$Spaces$C_Glitch ..."

Set-Pos $Row 0
Write-Host "$Spaces$C_Brand$Line$R"
```

Ou seja:

- Cursor na coluna 0,
- Escreve **$PadLeft espaços** + texto,
- Esses espaços apagam tudo à esquerda da logo nas mesmas linhas de Y.

A correção que você aplicou virou:

```powershell
Set-Pos $Row $PadLeft
Write-Host "$C_Glitch ..."

Set-Pos $Row $PadLeft
Write-Host "$C_Brand$Line$R"
```

Agora:

- Você **não limpa mais a coluna 0..PadLeft-1**,  
- Só escreve em cima da área do banner.

Resultado: a linha linear da esquerda (o20, o18, o16, o14) não é mais apagada pela fase de “decode”.  
Mas isso **não altera** o que já tinha sido sobrescrito antes pela `Invoke-GlitchBanner`.

---

### 2. Por que o “o12” continua sumido na região do “T”

A ordem de desenho continua:

1. `Invoke-CoreImplosion`  
   → desenha os círculos, incluindo o ponto do raio 12 na esquerda (`o12`).

2. `Invoke-GlitchBanner` + logo estável  
   → escreve as linhas do banner com `█` exatamente em cima de onde estava o `o12`.

3. `Invoke-DecodeBanner` (corrigida)  
   → agora **não apaga o que está fora do banner**,  
     mas continua escrevendo **dentro** da área do banner (onde já tem `█`).

Terminal é **buffer 2D de 1 caractere por célula**:

- Cada posição (x, y) guarda **um único** caractere + cor.
- Não existe “camada de fundo” sob o `█`.
- O último `Write-Host` naquela célula vence.

Então:

- O `o12` é desenhado primeiro,
- Depois o “T” (com `█`) entra exatamente naquela célula,
- O `o12` deixa de existir; não tem como “ver por trás”.

A correção que você aplicou só impediu que a fase de decode **apagasse ainda mais coisas** na esquerda.  
Ela **não tem como** “ressuscitar” o `o12` que já foi substituído pelo `█`.

---

### 3. Como chegar mais perto da sensação de “background”

Para ter a sensação de cada linha “transferindo para o background”, você tem três caminhos possíveis dentro das limitações do console:

#### A) Ajustar a geometria para o raio 12 não passar dentro do T

Ideia: manter o círculo completo antes da logo, mas, quando a logo aparece, ela “corta” o círculo.

- Garantir que o raio que você quer ver (ex.: r=12) tenha X fora do retângulo do banner.
- Ou deslocar ligeiramente o centro X (`$CX`) ou o tamanho do banner até que o X do `o12` fique **logo encostado** no T, mas não por baixo.

É puramente ajuste geométrico (trocar fator `* 2`, mudar `$CX`, ou redesenhar o banner com 1–2 colunas a menos no início).

#### B) Re-desenhar o círculo depois do banner, mas só onde ainda é “fundo”

Aqui você simula “camada” com lógica:

1. Depois de `Invoke-DecodeBanner`, roda uma função tipo `Redraw-CoreRingsAsBackground`.
2. Para cada ponto (X, Y) do raio:
   - Lê o conteúdo atual do buffer,
   - Só desenha `o` se o conteúdo atual for espaço (ou um dos símbolos de fundo que você aceite).

Pseudo-código:

```powershell
function Redraw-CoreRingsAsBackground {
    $raw = $Host.UI.RawUI
    $size = $raw.WindowSize
    $rect = New-Object System.Management.Automation.Host.Rectangle 0,0,($size.Width-1),($size.Height-1)
    $buffer = $raw.GetBufferContents($rect)

    $CX = $size.Width / 2
    $CY = $size.Height / 2

    for ($r = 12; $r -ge 12; $r -= 2) {  # só o raio 12 se quiser
        $Steps = 18
        for ($i = 0; $i -lt $Steps; $i++) {
            $Angle = ($i / $Steps) * 2 * [math]::PI
            $X = [int]($CX + [math]::Cos($Angle) * $r * 2)
            $Y = [int]($CY + [math]::Sin($Angle) * $r)

            if ($X -gt 0 -and $X -lt $size.Width -and $Y -gt 0 -and $Y -lt $size.Height) {
                $cell = $buffer[$Y, $X]
                if ($cell.Character -eq ' ') {
                    Set-Pos $Y $X
                    Write-Host "$C_Deepo$R" -NoNewline
                }
            }
        }
    }
}
```

Isso cria um “pseudo-background”: você redesenha depois, mas **só em células que não têm o T**.

#### C) Integrar o círculo diretamente no desenho da fonte

Mais artístico:

- Em vez de tentar colocar o `o12` por trás do `T`, você altera o próprio banner para incluir esse “anel” como parte da arte:
  - Onde o círculo cruzaria o T, você usa outro caractere (`Ø`, `¤`, `◌` etc.) já na string do banner.
- A sensação visual vira: “o T foi esculpido dentro do campo de força”, não “o círculo está por trás”.

---

Em resumo:

- A correção atual está certa para **não apagar a linha da esquerda**.
- Ela não consegue, por definição do terminal, “manter o o12 como background sob o T”.
- Para chegar na sensação que você descreveu, você precisa ou:
  - ajustar a geometria (A), ou
  - usar leitura do buffer para redesenhar só fundo (B), ou
  - embutir o motivo do círculo na própria arte do banner (C).

---

### USUÁRIO

forneça o script completo corrigido

---

### ASSISTENTE

```powershell
# ============================================================
# TEIA OS – Hyper-Fluid Boot + HYPER-FLUX IDENTITY ENGINE (v4.1 – Stable)
# ============================================================

$E = [char]27

# Ambiente
[Console]::OutputEncoding          = [System.Text.Encoding]::UTF8
$Global:ErrorActionPreference      = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle         = "TEIA OS | KERNEL BOOT SEQUENCE"

# Paleta – alinhada com psicologia das cores
$C_Brand      = "$E[38;5;51m"    # Ciano – principal (tecnologia, confiança)
$C_BrandSoft  = "$E[38;5;45m"    # Ciano suave – transições suaves
$C_Deep       = "$E[38;5;23m"    # Azul profundo – base / profundidade
$C_Purple     = "$E[38;5;135m"   # Roxo – futurismo/inovação
$C_AccentWarm = "$E[38;5;214m"   # Laranja suave – foco/ação/atenção
$C_TextSoft   = "$E[38;5;250m"   # Texto suave – legibilidade
$C_White      = "$E[38;5;255m"   # Branco – flashes/realce máximo
$C_Glitch     = "$E[38;5;160m"   # Vermelho magenta – glitch curto (não dominante)
$C_Grey       = "$E[38;5;236m"   # Fundo quase preto / linhas discretas
$C_GreySoft   = "$E[38;5;238m"
$R            = "$E[0m"

# Banner TEIA OS (identidade)
$banner = @(
    "████████╗███████╗██╗ █████╗       ██████╗ ███████╗",
    "╚══██╔══╝██╔════╝██║██╔══██╗     ██╔═══██╗██╔════╝",
    "   ██║   █████╗  ██║███████║     ██║   ██║███████╗",
    "   ██║   ██╔══╝  ██║██╔══██║     ██║   ██║╚════██║",
    "   ██║   ███████╗██║██║  ██║     ╚██████╔╝███████║",
    "   ╚═╝   ╚══════╝╚═╝╚═╝  ╚═╝      ╚═════╝ ╚══════╝"
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
    $W        = [Console]::WindowWidth
    $H        = [Console]::WindowHeight
    $CenterX  = [math]::Round($W / 2)
    $CenterY  = [math]::Round($H / 2)
    
    $Nodes = @()
    0..40 | ForEach-Object {
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
    $W  = [Console]::WindowWidth
    $H  = [Console]::WindowHeight
    $CX = $W / 2
    $CY = $H / 2

    for ($r = 20; $r -ge 2; $r -= 2) {
        $Steps = 18
        for ($i = 0; $i -lt $Steps; $i++) {
            $Angle = ($i / $Steps) * 2 * [math]::PI
            $X = [int]($CX + [math]::Cos($Angle) * $r * 2)
            $Y = [int]($CY + [math]::Sin($Angle) * $r)

            if ($X -gt 0 -and $X -lt $W -and $Y -gt 0 -and $Y -lt $H) {
                $color = if ($r -gt 12) { $C_Deep }
                         elseif ($r -gt 6) { $C_BrandSoft }
                         else { $C_Brand }
                Write-Host "$E[$Y;${X}H${color}o$R" -NoNewline
            }
        }
        Start-Sleep -Milliseconds 40
    }

    # Flash central
    Write-Host "$E[$([int]$CY);$([int]$CX-2)H${C_AccentWarm}█████$R" -NoNewline
    Start-Sleep -Milliseconds 120
}

# ============================================================
# FASE 3: BANNER GLITCH (Revelação da Marca)
# ============================================================
function Invoke-GlitchBanner {
    $W           = [Console]::WindowWidth
    $BannerWidth = $banner[0].Length
    $PadLeft     = [math]::Max(0, [int](($W - $BannerWidth) / 2))
    $StartRow    = [int]([Console]::WindowHeight / 2) - 4
    $Chars       = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%"

    # Glitch inicial
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

    # Banner estabilizado em ciano
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
function Draw-BackgroundWeb {
    $w       = [Console]::WindowWidth
    $h       = [Console]::WindowHeight
    $Density = 60

    for ($i = 0; $i -lt $Density; $i++) {
        $x    = Get-Random -Min 1 -Max $w
        $y    = Get-Random -Min 1 -Max $h
        $Sym  = Get-Random -InputObject @("·", ".", "`"", "*")
        $Color = Get-Random -InputObject @($C_Grey, $C_GreySoft, $C_Deep)
        Set-Pos $y $x
        Write-Host "$Color$Sym$R" -NoNewline
    }
}

function Draw-Pulse {
    $cx = [int]([Console]::WindowWidth / 2)
    $cy = [int]([Console]::WindowHeight / 2)

    for ($r = 1; $r -lt 12; $r++) {
        $Steps = 12 + ($r * 2)
        for ($theta = 0; $theta -lt 360; $theta += (360 / $Steps)) {
            $rad = $theta * [Math]::PI / 180
            $x   = [int]($cx + ([Math]::Cos($rad) * $r * 2))
            $y   = [int]($cy + ([Math]::Sin($rad) * $r))

            Set-Pos $y $x
            $color = if ($r -le 3) { $C_Deep }
                     elseif ($r -le 7) { $C_Brand }
                     elseif ($r -lt 11) { $C_BrandSoft }
                     else { $C_AccentWarm }

            if ($r -eq 11) { Write-Host "${C_Grey}░$R" -NoNewline }
            else           { Write-Host "${color}•$R" -NoNewline }
        }
        Start-Sleep -Milliseconds 40
    }
}

# [CORREÇÃO 1: LINHA ESQUERDA PRESERVADA]
# Decode escreve apenas na área do banner, sem apagar a esquerda.
function Invoke-DecodeBanner {
    $StartRow  = [int]([Console]::WindowHeight / 2) - 4
    $CenterCol = [int]([Console]::WindowWidth / 2)
    $MaxLen    = ($banner | Measure-Object -Property Length -Maximum).Maximum
    $PadLeft   = $CenterCol - [int]($MaxLen / 2)
    if ($PadLeft -lt 0) { $PadLeft = 0 }

    for ($i = 0; $i -lt $banner.Count; $i++) {
        $Line = $banner[$i]
        $Row  = $StartRow + $i

        # Glitch pass – não destrutivo nas colunas à esquerda
        Set-Pos $Row $PadLeft
        Write-Host "$C_Glitch$($Line -replace '.', '▒')$R" -NoNewline
        Start-Sleep -Milliseconds 45

        # Pass final – logo firme
        Set-Pos $Row $PadLeft
        Write-Host "$C_Brand$Line$R" -NoNewline
        Start-Sleep -Milliseconds 45
    }
}

# [CORREÇÃO 2: HUD ALINHADO POR LARGURA REAL]
function Draw-HUD {
    $Row = [Console]::WindowHeight - 4
    $W   = [Console]::WindowWidth

    # Conteúdo interno
    $InnerContent = "SYSTEM READY  ·  PRESS ENTER TO LINK"
    $TotalWidth   = 2 + $InnerContent.Length + 2   # "║ " + conteúdo + " ║"

    # Bordas
    $HorizontalBar = "═" * ($TotalWidth - 2)       # sem cantos
    $TopBorder     = "${C_Grey}╔${HorizontalBar}╗${R}"
    $BottomBorder  = "${C_Grey}╚${HorizontalBar}╝${R}"

    # Centralização
    $Pad = [int](($W - $TotalWidth) / 2)

    # Render
    Set-Pos $Row $Pad
    Write-Host $TopBorder

    Set-Pos ($Row + 1) $Pad
    Write-Host (
        "${C_Grey}║ " +
        "${C_TextSoft}SYSTEM READY  ·  " +
        "${C_AccentWarm}PRESS ENTER${C_TextSoft} TO LINK" +
        " ${C_Grey}║$R"
    )

    Set-Pos ($Row + 2) $Pad
    Write-Host $BottomBorder
}

# ============================================================
# SEQUÊNCIA DE EXECUÇÃO
# ============================================================
try {
    Hide-Cursor
    Clear-Screen

    Invoke-FractalWeb
    Invoke-CoreImplosion
    Invoke-GlitchBanner
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

Uso sugerido:

1. Salve o conteúdo em um arquivo, por exemplo: `TEIA-OS-Boot-v4.1.ps1`.
2. Abra um PowerShell 7 em tela cheia.
3. Execute: `Set-Location` até a pasta do script e depois `./TEIA-OS-Boot-v4.1.ps1`.
4. Ajuste apenas a fonte/tamanho do terminal se quiser otimizar a proporção visual do banner e dos anéis.

---

