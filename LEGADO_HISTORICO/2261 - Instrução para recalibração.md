# 2261 - Instrução para recalibração

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_0000000071f471f5aa345e6febab3c36', 'size_bytes': 381488, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Perfeito — vou te dar **(1)** um prompt/roteiro pronto para o Codex (o que ele deve *fazer* e *por quê*), **(2)** um arquivo PowerShell completo corrigido e robusto que resolve o erro que aparece na sua tela (o conflito com `$PID` / `PID is read-only`) e melhora a lógica de posicionamento/replicação do layout, e **(3)** o comando PowerShell idempotente exato para substituir o arquivo `D:\Scripts\Set-TEIA-Workspace.ps1` via `Set-Content` (ou para fazer backup antes de substituir). Tudo em português e no padrão “copy→paste” pronto para executar.

## Resumo do problema (curto)
- O erro na sua screenshot: **"Cannot overwrite variable PID because it is read-only or constant."** — acontece porque PowerShell tem variável automática `$PID` (case-insensitive). Se o script usa `$pid` para receber o `GetWindowThreadProcessId`, isso conflita e causa o erro.
- Solução: **usar um nome de variável que não conflite** (ex.: `$procId`, `$winPid`) e passar ele corretamente por referência (`[ref]$procId`). Além disso: adicionar tratamento de erros, retry/timeout, e funções robustas para obter `MainWindowHandle`, `GetWindowRect` e mover janelas (MoveWindow/SetWindowPos).

---

# 1) Prompt / instrução pronta para o Codex
Use isto como *task prompt* para o Codex (ou para o seu Codex CLI) — descreve o que deve ser alterado no arquivo e por quê:

> **Tarefa**: abrir `D:\Scripts\Set-TEIA-Workspace.ps1`, identificar e corrigir chamadas a `GetWindowThreadProcessId` ou uso de `$pid`/`$PID` e quaisquer variáveis que conflitem com variáveis automáticas do PowerShell.  
> **Objetivos técnicos**:
> 1. Substituir todos usos de `$pid` por `$procId` (ou `$winProcId`) — garantir que variáveis **não conflitam** com variáveis automáticas (case-insensitive).  
> 2. Garantir que `GetWindowThreadProcessId` receba um **[ref]** para um inteiro de saída (ex.: `$procId = 0; [void] [Win32Api.User32]::GetWindowThreadProcessId($h, [ref]$procId)`) — sem tentar atribuir diretamente ao nome `$PID`.  
> 3. Adicionar try/catch em torno das chamadas Win32 e logs de fallback.  
> 4. Melhorar a função de posicionamento (uso de `MoveWindow`/`SetWindowPos`) com verificações de tolerância e retries (já tem `Tolerance` e `MaxRetries` — manter/usar).  
> 5. Fazer backup do arquivo original automaticamente antes de sobrescrever.  
> **Entrega**: gravar o arquivo atualizado em `D:\Scripts\Set-TEIA-Workspace.ps1` (sobrescrever), e retornar um resumo das mudanças (linhas modificadas e motivo).  
> **Observações**: priorizar compatibilidade com PowerShell 7+, evitar nomes reservados, manter idempotência e logs claros.

---

# 2) Arquivo PowerShell corrigido (substitui o anterior)
Cole inteiro em um arquivo novo (ou use o comando que vem depois para substituir). Este script aplica as correções principais (usa `$procId` ao invés de `$pid`), wrappers Win32 robustos, retry logic e mensagens claras.

```powershell
# Set-TEIA-Workspace.ps1
param(
  [string]$LayoutFile = "D:\Scripts\Layouts\CurrentLayout.json",
  [int]$Tolerance = 1,
  [int]$MaxRetries = 10
)

# ----- Auto-elevação (preserva parâmetros) -----
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"")
  $PSBoundParameters.GetEnumerator() | ForEach-Object { $args += "-$($_.Key)"; $args += "`"$($_.Value)`"" }
  Start-Process -FilePath 'powershell.exe' -ArgumentList $args -Verb RunAs
  exit
}

# ----- Win32 interop (tipos e funções necessárias) -----
Add-Type -Namespace Win32Api -Name User32 -MemberDefinition @"
using System;
using System.Runtime.InteropServices;
public static class User32 {
  [DllImport("user32.dll", SetLastError=true)]
  public static extern bool IsWindowVisible(IntPtr hWnd);

  [DllImport("user32.dll", SetLastError=true)]
  public static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);

  [DllImport("user32.dll", SetLastError=true)]
  public static extern IntPtr GetAncestor(IntPtr hWnd, uint gaFlags);

  [DllImport("user32.dll", SetLastError=true)]
  public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

  [DllImport("user32.dll", SetLastError=true)]
  public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

  [DllImport("user32.dll", SetLastError=true)]
  public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

  [StructLayout(LayoutKind.Sequential)]
  public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
"@

# ----- Helpers (PowerShell wrappers) -----
function Get-ExtRect {
  param([IntPtr]$h)
  try{
    if ($h -eq [IntPtr]::Zero) { return $null }
    $rect = New-Object Win32Api.User32+RECT
    $ok = [Win32Api.User32]::GetWindowRect($h, [ref]$rect)
    if (-not $ok) { return $null }
    return @{ L = $rect.Left; T = $rect.Top; R = $rect.Right; B = $rect.Bottom }
  } catch {
    return $null
  }
}

function MoveRaw {
  param([IntPtr]$h, [Hashtables]$r)
  try{
    if ($h -eq [IntPtr]::Zero) { return $false }
    $w = [int]$r.W; $hgt = [int]$r.H
    $x = [int]$r.X; $y = [int]$r.Y
    [Win32Api.User32]::MoveWindow($h, $x, $y, $w, $hgt, $true) | Out-Null
    return $true
  } catch {
    return $false
  }
}

function Wait-Main {
  param([System.Diagnostics.Process]$p, [int]$timeoutMs = 5000)
  $end = (Get-Date).AddMilliseconds($timeoutMs)
  while ((Get-Date) -lt $end) {
    try {
      if (-not $p -or $p.HasExited) { return [IntPtr]::Zero }
      # prefer MainWindowHandle, otherwise search by process windows
      $h = $p.MainWindowHandle
      if ($h -and $h -ne [IntPtr]::Zero -and [Win32Api.User32]::IsWindowVisible($h)) { return $h }
    } catch {}
    Start-Sleep -Milliseconds 80
  }
  return [IntPtr]::Zero
}

# Robust process finder: by title or by process name
function Start-Or-Find {
  param([string]$title, [string]$dir)
  # try find process with matching MainWindowTitle
  $p = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -eq $title } | Select-Object -First 1
  if ($p) { return $p }
  # fallback: try to start a new pwsh window with title and folder
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) { $dir = 'C:\' }
  $cmd = "`$host.UI.RawUI.WindowTitle = '$title'; try{ Set-Location -LiteralPath '$dir' } catch {} ; cd"
  return Start-Process -FilePath 'pwsh.exe' -ArgumentList @('-NoExit','-NoProfile','-Command',$cmd) -PassThru
}

function Ensure-Chrome {
  $p = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
  if ($p) { return $p }
  $exe = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
  if (-not (Test-Path $exe)) { $exe = 'chrome.exe' }
  return Start-Process -FilePath $exe -ArgumentList @('--new-window','https://chat.openai.com/') -PassThru
}

# Magnetize-To: aligns a process main window to a target rect with retries
function Magnetize-To {
  param([System.Diagnostics.Process]$p, [hashtable]$t, [int]$tol, [int]$max)
  $h = Wait-Main $p 5000
  if ($h -eq [IntPtr]::Zero) { Write-Warning "Janela não encontrada para processo: $($p.ProcessName)"; return }
  # initial placement candidate
  $r = @{ X=[int]$t.X_Abs; Y=[int]$t.Y_Abs; W=[int]$t.W; H=[int]$t.H }
  MoveRaw $h $r; Start-Sleep -Milliseconds 120
  for ($i=0; $i -lt $max; $i++) {
    $m = Get-ExtRect $h
    if (-not $m) { break }
    $dL = $t.X_Abs - $m.L; $dT = $t.Y_Abs - $m.T
    $dR = ($t.X_Abs + $t.W) - $m.R; $dB = ($t.Y_Abs + $t.H) - $m.B
    $delta = [math]::Max([math]::Abs($dL), [math]::Abs($dT), [math]::Abs($dR), [math]::Abs($dB))
    if ($delta -le $tol) { break }
    $r.X += $dL; $r.Y += $dT
    # adjust width/height if needed
    $newW = $r.W + ($dR - $dL)
    $newH = $r.H + ($dB - $dT)
    if ($newW -lt 50) { $newW = 50 }
    if ($newH -lt 50) { $newH = 50 }
    $r.W = $newW; $r.H = $newH
    MoveRaw $h $r
    Start-Sleep -Milliseconds 80
  }
}

# ----- Carregamento do layout e cálculo de posições -----
if (-not (Test-Path $LayoutFile)) { Write-Error "Layout não encontrado: $LayoutFile"; exit 1 }
try {
  $layout = Get-Content -LiteralPath $LayoutFile -Raw | ConvertFrom-Json
} catch {
  Write-Error "Falha ao ler/parsear layout JSON: $($_.Exception.Message)"; exit 1
}

# Exemplo de estrutura esperada do JSON:
# { "work": { "Left": 0, "Top": 0 }, "nodes": { "chrome": { "Rect": { "X":0,"Y":0,"W":800,"H":600 } }, ... } }

$work = $layout.work
$chromeNode = $layout.nodes.chrome
$topoNode   = $layout.nodes.topo
$baseNode   = $layout.nodes.base

if (-not $chromeNode -or -not $topoNode -or -not $baseNode) {
  Write-Error "Nós (chrome, topo, base) não encontrados no layout JSON"; exit 1
}

$ChromeRect = @{ X_Abs = ($chromeNode.Rect.X + $work.Left); Y_Abs = ($chromeNode.Rect.Y + $work.Top); W = $chromeNode.Rect.W; H = $chromeNode.Rect.H }
$TopoRect   = @{ X_Abs = ($topoNode.Rect.X + $work.Left);   Y_Abs = ($topoNode.Rect.Y + $work.Top);   W = $topoNode.Rect.W;   H = $topoNode.Rect.H }
$BaseRect   = @{ X_Abs = ($baseNode.Rect.X + $work.Left);   Y_Abs = ($baseNode.Rect.Y + $work.Top);   W = $baseNode.Rect.W;   H = $baseNode.Rect.H }

# ----- Garantir processos / abrir janelas -----
$chrome = Ensure-Chrome
$pwTop  = Start-Or-Find 'PWS-Topo'  'C:\'
$pwBase = Start-Or-Find 'PWS-Base' 'D:\TEIA\TEIA_NUCLEO\offline\nano'

# ----- Aplicar layout -----
Magnetize-To $chrome $ChromeRect $Tolerance $MaxRetries
Magnetize-To $pwTop  $TopoRect   $Tolerance $MaxRetries
Magnetize-To $pwBase $BaseRect   $Tolerance $MaxRetries

Write-Host "Layout restaurado de: $LayoutFile"
```

---

# 3) Comando PowerShell (idempotente) para atualizar o arquivo no seu disco
**Atenção**: primeiro fazemos backup do arquivo atual; depois gravamos a nova versão. Cole e rode no PowerShell (com privilégios de admin).

```powershell
# backup do arquivo existente (cria D:\Scripts\backups se não existir)
$target = 'D:\Scripts\Set-TEIA-Workspace.ps1'
$backupDir = 'D:\Scripts\backups'
If (-not (Test-Path $backupDir)) { New-Item -Path $backupDir -ItemType Directory | Out-Null }
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
If (Test-Path $target) {
  Copy-Item -LiteralPath $target -Destination (Join-Path $backupDir ("Set-TEIA-Workspace_$ts.ps1"))
}

# sobrescreve o arquivo com o novo conteúdo (cole aqui o conteúdo do script acima entre @' ... '@)
$new = @'
# COLE AQUI O CONTEÚDO DO SCRIPT CORRIGIDO (tudo entre o bloco do exemplo anterior)
'@
Set-Content -LiteralPath $target -Value $new -Encoding UTF8
Write-Host "Arquivo atualizado: $target (backup em $backupDir)"
```

> Observação prática: substitua a linha `# COLE AQUI O CONTEÚDO DO SCRIPT CORRIGIDO ...` pelo conteúdo exato do script que forneci. Se preferir, eu gero o comando `Set-Content` já com o here-string completo pronto (posso fazer isso agora se você quiser que eu gere o `Set-Content` com o script embutido).

---

# 4) Instruções rápidas de execução (4 linhas)
1. Abra PowerShell como Administrador.  
2. Faça backup: `Copy-Item D:\Scripts\Set-TEIA-Workspace.ps1 D:\Scripts\backups\Set-TEIA-Workspace_PRE_replace.ps1`  
3. Substitua o arquivo com o comando `Set-Content` (ou cole o here-string do passo 3).  
4. Execute: `pwsh -NoProfile -File D:\Scripts\Set-TEIA-Workspace.ps1` e observe logs/erros no console.

---

## Notas técnicas e próximos passos que recomendo (rápido)
- Depois de rodar, se ainda houver diferenças visuais (o layout não replica perfeitamente), verifique:
  1. Se a janela alvo tem **barras laterais**/UI dinâmicas (Chrome/Edge ajustam tamanho interno conforme conteúdo). Pode ser necessário repetir MoveWindow após abrir páginas e aguardar `DOMContentLoaded`.  
  2. Se os processos que quer mover (ex.: terminais personalizados) não expõem `MainWindowHandle` imediatamente — ajustar `Wait-Main` timeout ou buscar janelas por título.  
  3. Se múltiplos monitores estiverem envolvidos: verifique coordenadas `work.Left`/`work.Top` e escala (DPI). Em telas com escala >100%, as rects podem ser diferentes; considere normalizar usando API que converte logical<>physical pixels.  
- Se quiser, eu já gero o comando `Set-Content` com o here-string contendo o script completo (automaticamente pronto para colar e executar). Quer que eu gere esse comando pronto para colar?  

---

Se preferir que eu **grave automaticamente** o arquivo (ou gere o `Set-Content` já preenchido com o script completo) eu faço isso agora — **cole para eu gerar** o `Set-Content` final com o script embutido, ou diga "grava" e eu mostro o comando final pronto.

---

### USUÁRIO

Como respondemos? • Ran
  └ pwsh -NoProfile -Command '$new = @'"'
    # Set-TEIA-Workspace.ps1
    param(
      [string]"'$LayoutFile = "D:'"\\Scripts\\Layouts\\CurrentLayout.json\",
      [int]"'$Tolerance = 1,
      [int]$MaxRetries = 10
    )

    # ----- Auto-elevação (preserva parâmetros) -----
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
      ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
      $elevArgs = @('"'-NoProfile','-ExecutionPolicy','Bypass','-File',\""'`"$PSCommandPath`"")
      $PSBoundParameters.GetEnumerator() | ForEach-Object { $elevArgs += "-$($_.Key)"; $elevArgs += "`"$($_.Value)`"" }
      Start-Process -FilePath '"'powershell.exe' -ArgumentList "'$elevArgs -Verb RunAs
      exit
    }

    # ----- DPI: Per-Monitor Aware V2 -----
    Add-Type -Name Dpi -Namespace W32 -MemberDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public static class DPI {
      [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);
    }
    "@
    [void][W32.DPI]::SetThreadDpiAwarenessContext([intptr](-4))

    # ----- Win32 interop (tipos e funções necessárias) -----
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    namespace W32 {
      [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
      public static class U32 {
        [DllImport("user32.dll", SetLastError=true)] public static extern bool MoveWindow(IntPtr hWnd,int X,int Y,int W,int H,bool repaint);
        [DllImport("user32.dll", SetLastError=true)] public static extern bool ShowWindow(IntPtr hWnd,int cmd);
        [DllImport("user32.dll", SetLastError=true)] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll", SetLastError=true)] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
        [DllImport("user32.dll", SetLastError=true)] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
      }
      public static class Dwm {
        [DllImport("dwmapi.dll", PreserveSig=true)] public static extern int DwmGetWindowAttribute(IntPtr hwnd,int attr,out RECT pv,int cb);
        public const int DWMWA_EXTENDED_FRAME_BOUNDS = 9;
      }
    }
    "@

    Add-Type -AssemblyName System.Windows.Forms
    $work = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

    # ----- Helpers (PowerShell wrappers) -----
    function Get-ExtRect {
      param([IntPtr]$h)
      try {
        if ($h -eq [IntPtr]::Zero) { return $null }
        $r = New-Object W32.RECT
        $hr = [W32.Dwm]::DwmGetWindowAttribute($h,[W32.Dwm]::DWMWA_EXTENDED_FRAME_BOUNDS,[ref]$r,[Runtime.InteropServices.Marshal]::SizeOf([type]'"'W32.RECT'))
        if ("'$hr -ne 0) {
          $ok = [W32.U32]::GetWindowRect($h,[ref]$r)
          if (-not $ok) { return $null }
        }
        return [pscustomobject]@{ L=$r.Left; T=$r.Top; R=$r.Right; B=$r.Bottom; W=$r.Right-$r.Left; H=$r.Bottom-$r.Top }
      } catch {
        Write-Warning ("Get-ExtRect falhou: {0}" -f $_.Exception.Message)
        return $null
      }
    }

    function MoveRaw {
      param([IntPtr]$h, [hashtable]$R)
      try {
        if ($h -eq [IntPtr]::Zero) { return $false }
        [void][W32.U32]::ShowWindow($h,9)
        [void][W32.U32]::SetForegroundWindow($h)
        [void][W32.U32]::MoveWindow($h,[int]$R.X,[int]$R.Y,[int]$R.W,[int]$R.H,$true)
        return $true
      } catch {
        Write-Warning ("MoveRaw falhou: {0}" -f $_.Exception.Message)
        return $false
      }
    }

    function Wait-Main {
      param([System.Diagnostics.Process]$p,[int]$ms=60000)
      if (-not $p) { return [IntPtr]::Zero }
      try {
        $sw=[Diagnostics.Stopwatch]::StartNew(); $p.Refresh()
        while($p.MainWindowHandle -eq [IntPtr]::Zero -and $sw.ElapsedMilliseconds -lt $ms){ Start-Sleep -Milliseconds 80; $p.Refresh() }
        return $p.MainWindowHandle
      } catch {
        Write-Warning ("Wait-Main falhou: {0}" -f $_.Exception.Message)
        return [IntPtr]::Zero
      }
    }

    # Wrapper seguro para obter o PID de uma janela (exemplo de uso do [ref])
    function Get-WindowProcessId {
      param([IntPtr]$h)
      try {
        if ($h -eq [IntPtr]::Zero) { return 0 }
        $procId = [uint32]0
        [void][W32.U32]::GetWindowThreadProcessId($h, [ref]$procId)
        return [int]$procId
      } catch {
        Write-Warning ("GetWindowThreadProcessId falhou: {0}" -f $_.Exception.Message)
        return 0
      }
    }

    # Robust process finder: por título ou processo
    function Start-Or-Find {
      param([string]$title, [string]$dir)
      $p = Get-Process pwsh,powershell -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq $title } | Select-Object -First 1
      if ($p) { return $p }
      if (-not (Test-Path -LiteralPath $dir -PathType Container)) { $dir = '"'C:\\' }
      "'$cmd = "`$host.UI.RawUI.WindowTitle = '"'"'$title'"'; try{ Set-Location -LiteralPath '"'$dir'"' } catch {} ; cd\"
      return Start-Process -FilePath 'pwsh.exe' -Verb RunAs -WindowStyle Normal -ArgumentList @('-NoExit','-NoProfile','-Command',"'$cmd) -PassThru
    }

    function Ensure-Chrome {
      try {
        $p = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle } | Select-Object -First 1
        if ($p) { return $p }
        $exe = "${env:ProgramFiles}'"\\Google\\Chrome\\Application\\chrome.exe\"; if (-not (Test-Path "'$exe)) { $exe = '"'chrome.exe' }
        return Start-Process -FilePath "'$exe -ArgumentList @('"'--new-window','https://gemini.google.com/app') -WindowStyle Normal -PassThru
      } catch {
        Write-Warning (\"Ensure-Chrome falhou: {0}\" -f "'$_.Exception.Message)
        return $null
      }
    }
      if ($h -eq [IntPtr]::Zero) { Write-Warning "Janela não encontrada: $($p.ProcessName)"; return }
      $r = @{ X=[int]$t.X_Abs; Y=[int]$t.Y_Abs; W=[int]$t.W; H=[int]$t.H }
      MoveRaw $h $r | Out-Null; Start-Sleep -Milliseconds 120
      for ($i=0; $i -lt $max; $i++) {
        $m = Get-ExtRect $h
        if (-not $m) { break }
        $dL = $t.X_Abs - $m.L; $dT = $t.Y_Abs - $m.T
        $dR = ($t.X_Abs + $t.W) - $m.R; $dB = ($t.Y_Abs + $t.H) - $m.B
        $delta = [math]::Max([math]::Abs($dL), [math]::Abs($dT), [math]::Abs($dR), [math]::Abs($dB))
        if ($delta -le $tol) { break }
        $r.X += $dL; $r.Y += $dT
        $r.W += ($dR - $dL); if ($r.W -lt 50) { $r.W = 50 }
        $r.H += ($dB - $dT); if ($r.H -lt 50) { $r.H = 50 }
        MoveRaw $h $r | Out-Null
        Start-Sleep -Milliseconds 70
      }
    }

    # ----- Carregamento do layout e cálculo de posições -----
    if (-not (Test-Path -LiteralPath $LayoutFile)) { Write-Error "Layout não encontrado: $LayoutFile"; exit 1 }
    try {
      $layout = Get-Content -LiteralPath $LayoutFile | ConvertFrom-Json
    } catch {
      Write-Error ("Falha ao ler/parsear layout JSON: {0}" -f $_.Exception.Message); exit 1
    }

    # Estes nós são procurados por ProcessName/WindowTitle no JSON atual
    $chromeNode = $layout | Where-Object { $_.ProcessName -eq '"'chrome' } | Select-Object -First 1
    "'$topoNode   = $layout | Where-Object { $_.WindowTitle -eq '"'PWS-Topo' } | Select-Object -First 1
    "'$baseNode   = $layout | Where-Object { $_.WindowTitle -eq '"'PWS-Base' } | Select-Object -First 1

    if (-not "'$chromeNode -or -not $topoNode -or -not $baseNode) {
      Write-Error "JSON deve conter chrome, PWS-Topo e PWS-Base."; exit 1
    }

    $ChromeRect = @{ X_Abs = ($chromeNode.Rect.X + $work.Left); Y_Abs = ($chromeNode.Rect.Y + $work.Top); W = $chromeNode.Rect.W; H = $chromeNode.Rect.H }
    $TopoRect   = @{ X_Abs = ($topoNode.Rect.X   + $work.Left); Y_Abs = ($topoNode.Rect.Y   + $work.Top); W = $topoNode.Rect.W;   H = $topoNode.Rect.H }
    $BaseRect   = @{ X_Abs = ($baseNode.Rect.X   + $work.Left); Y_Abs = ($baseNode.Rect.Y   + $work.Top); W = $baseNode.Rect.W;   H = $baseNode.Rect.H }

    # ----- Garantir processos / abrir janelas -----
    $chrome = Ensure-Chrome
    $pwTop  = Start-Or-Find '"'PWS-Topo'  'C:\\'
    "'$pwBase = Start-Or-Find '"'PWS-Base' 'D:\\TEIA\\TEIA_NUCLEO\\offline\\nano'

    # ----- Aplicar layout -----
    if ("'$chrome) { Magnetize-To $chrome $ChromeRect $Tolerance $MaxRetries }
    if ($pwTop)  { Magnetize-To $pwTop  $TopoRect   $Tolerance $MaxRetries }
    if ($pwBase) { Magnetize-To $pwBase $BaseRect   $Tolerance $MaxRetries }

    Write-Host "Layout restaurado de: $LayoutFile"
    '"'@; Set-Content -LiteralPath 'D:\\Scripts\\Set-TEIA-Workspace.ps1' -Value "'$new -Encoding UTF8; Write-Host "Arquivo atualizado em D:'"\\Scripts\\Set-TEIA-Workspace.ps1\""

• Ran
  └ pwsh -NoProfile -Command '$file = '"'D:\\Scripts\\Set-TEIA-Workspace.ps1'; "'$counts = @{ pid = 0; gwtpi = 0 }; if (Test-Path -LiteralPath $file) { $all = Get-Content -LiteralPath $file; $counts.pid = ($all | Select-String
        -Pattern '"'(?i)\\"'$pid'"\\b' -AllMatches | Measure-Object).Count; "'$counts.gwtpi = ($all | Select-String -Pattern '"'GetWindowThreadProcessId' -AllMatches | Measure-Object).Count; "'$counts | ConvertTo-Json -Compress } else
        { Write-Host "FILE_NOT_FOUND: $file" }'

• Updated Plan
  └ Read, analyzed and updated the script with safer Win32 wrappers, removed reserved variable conflicts, added backup, and produced a change summary.
    ✔ Read current script
    ✔ Detect risky usages
    ✔ Backup original file
    ✔ Write corrected script
    ✔ Summarize changes

> Below is the full deliverable: a clear task prompt for Codex, the corrected script, an idempotent PowerShell update command (with embedded here‑string), and quick run instructions. I also include a concise change summary.

  Task Prompt (for Codex)

  - Objective: Open D:\Scripts\Set-TEIA-Workspace.ps1 and fix any uses of $pid/$PID (PowerShell automatic variable, case‑insensitive) by replacing with $procId (or $winProcId) to avoid conflicts. Ensure all GetWindowThreadProcessId calls
  receive a [ref] out parameter (e.g., $procId = 0; [void][Win32Api.User32]::GetWindowThreadProcessId($h,[ref]$procId)) and do not assign to $PID. Wrap Win32 P/Invoke calls in try/catch with clear warnings and fallbacks. Improve the
  window placement function using MoveWindow/SetWindowPos with tolerance checks and retries (reuse Tolerance and MaxRetries). Automatically back up the original file before overwriting. Ensure compatibility with PowerShell 7+, idempotent
  behavior, and clear logging.
  - Deliverable: Overwrite D:\Scripts\Set-TEIA-Workspace.ps1 with the updated script and provide a summary of changed lines and rationale.

  Arquivo PowerShell Corrigido

  # Set-TEIA-Workspace.ps1

  param(
  [string]$LayoutFile = "D:\Scripts\Layouts\CurrentLayout.json",
  [int]$Tolerance = 1,
  [int]$MaxRetries = 10
  )

  # ----- Auto-elevação (preserva parâmetros) -----

  if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  $elevArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',""$PSCommandPath"")
  $PSBoundParameters.GetEnumerator() | ForEach-Object { $elevArgs += "-$($_.Key)"; $elevArgs += ""$($_.Value)"" }
  Start-Process -FilePath 'powershell.exe' -ArgumentList $elevArgs -Verb RunAs
  exit
  }

  # ----- DPI: Per-Monitor Aware V2 -----

  Add-Type -Name Dpi -Namespace W32 -MemberDefinition @"
  using System;
  using System.Runtime.InteropServices;
  public static class DPI {
  [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);
  }
  "@
  [void][W32.DPI]::SetThreadDpiAwarenessContext(intptr (-4))

  # ----- Win32 interop (tipos e funções necessárias) -----

  Add-Type -TypeDefinition @"
  using System;
  using System.Runtime.InteropServices;
  namespace W32 {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
  public static class U32 {
      [DllImport("user32.dll", SetLastError=true)] public static extern bool MoveWindow(IntPtr hWnd,int X,int Y,int W,int H,bool repaint);
      [DllImport("user32.dll", SetLastError=true)] public static extern bool ShowWindow(IntPtr hWnd,int cmd);
      [DllImport("user32.dll", SetLastError=true)] public static extern bool SetForegroundWindow(IntPtr hWnd);
      [DllImport("user32.dll", SetLastError=true)] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
      [DllImport("user32.dll", SetLastError=true)] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
  }
  public static class Dwm {
      [DllImport("dwmapi.dll", PreserveSig=true)] public static extern int DwmGetWindowAttribute(IntPtr hwnd,int attr,out RECT pv,int cb);
      public const int DWMWA_EXTENDED_FRAME_BOUNDS = 9;
  }
  }
  "@

  Add-Type -AssemblyName System.Windows.Forms
  $work = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

  # ----- Helpers (PowerShell wrappers) -----

  function Get-ExtRect {
  param([IntPtr]$h)
  try {
      if ($h -eq [IntPtr]::Zero) { return $null }
      $r = New-Object W32.RECT
      $hr = [W32.Dwm]::DwmGetWindowAttribute($h,[W32.Dwm]::DWMWA_EXTENDED_FRAME_BOUNDS,[ref]$r,[Runtime.InteropServices.Marshal]::SizeOf([type]'W32.RECT'))
      if ($hr -ne 0) {
        $ok = [W32.U32]::GetWindowRect($h,[ref]$r)
        if (-not $ok) { return $null }
      }
      return [pscustomobject]@{ L=$r.Left; T=$r.Top; R=$r.Right; B=$r.Bottom; W=$r.Right-$r.Left; H=$r.Bottom-$r.Top }
  } catch {
      Write-Warning ("Get-ExtRect falhou: {0}" -f $_.Exception.Message)
      return $null
  }
  }

  function MoveRaw {
  param([IntPtr]$h, [hashtable]$R)
  try {
      if ($h -eq [IntPtr]::Zero) { return $false }
      [void][W32.U32]::ShowWindow($h,9)
      [void][W32.U32]::SetForegroundWindow($h)
      [void][W32.U32]::MoveWindow($h,[int]$R.X,[int]$R.Y,[int]$R.W,[int]$R.H,$true)
      return $true
  } catch {
      Write-Warning ("MoveRaw falhou: {0}" -f $_.Exception.Message)
      return $false
  }
  }

  function Wait-Main {
  param([System.Diagnostics.Process]$p,[int]$ms=60000)
  if (-not $p) { return [IntPtr]::Zero }
  try {
      $sw=[Diagnostics.Stopwatch]::StartNew(); $p.Refresh()
      while($p.MainWindowHandle -eq [IntPtr]::Zero -and $sw.ElapsedMilliseconds -lt $ms){ Start-Sleep -Milliseconds 80; $p.Refresh() }
      return $p.MainWindowHandle
  } catch {
      Write-Warning ("Wait-Main falhou: {0}" -f $_.Exception.Message)
      return [IntPtr]::Zero
  }
  }

  # Wrapper seguro para obter o PID de uma janela (exemplo de uso do [ref])

  function Get-WindowProcessId {
  param([IntPtr]$h)
  try {
      if ($h -eq [IntPtr]::Zero) { return 0 }
      $procId = [uint32]0
      [void][W32.U32]::GetWindowThreadProcessId($h, [ref]$procId)
      return [int]$procId
  } catch {
      Write-Warning ("GetWindowThreadProcessId falhou: {0}" -f $_.Exception.Message)
      return 0
  }
  }

  # Robust process finder: por título ou processo

  function Start-Or-Find {
  param([string]$title, [string]$dir)
  $p = Get-Process pwsh,powershell -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq $title } | Select-Object -First 1
  if ($p) { return $p }
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) { $dir = 'C:' }
  $cmd = "`$host.UI.RawUI.WindowTitle = '$title'; try{ Set-Location -LiteralPath '$dir' } catch {} ; cd"
  return Start-Process -FilePath 'pwsh.exe' -Verb RunAs -WindowStyle Normal -ArgumentList @('-NoExit','-NoProfile','-Command',$cmd) -PassThru
  }

  function Ensure-Chrome {
  try {
      $p = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle } | Select-Object -First 1
      if ($p) { return $p }
      $exe = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"; if (-not (Test-Path $exe)) { $exe = 'chrome.exe' }
      return Start-Process -FilePath $exe -ArgumentList @('--new-window','https://gemini.google.com/app') -WindowStyle Normal -PassThru
  } catch {
      Write-Warning ("Ensure-Chrome falhou: {0}" -f $_.Exception.Message)
      return $null
  }
  }

  # Magnetize-To: alinha janela principal ao retângulo alvo com retries

  function Magnetize-To {
  param([System.Diagnostics.Process]$p, [hashtable]$t, [int]$tol, [int]$max)
  $h = Wait-Main $p
  if ($h -eq [IntPtr]::Zero) { Write-Warning "Janela não encontrada: $($p.ProcessName)"; return }
  $r = @{ X=[int]$t.X_Abs; Y=[int]$t.Y_Abs; W=[int]$t.W; H=[int]$t.H }
  MoveRaw $h $r | Out-Null; Start-Sleep -Milliseconds 120
  for ($i=0; $i -lt $max; $i++) {
      $m = Get-ExtRect $h
      if (-not $m) { break }
      $dL = $t.X_Abs - $m.L; $dT = $t.Y_Abs - $m.T
      $dR = ($t.X_Abs + $t.W) - $m.R; $dB = ($t.Y_Abs + $t.H) - $m.B
      $delta = [math]::Max([math]::Abs($dL), [math]::Abs($dT), [math]::Abs($dR), [math]::Abs($dB))
      if ($delta -le $tol) { break }
      $r.X += $dL; $r.Y += $dT
      $r.W += ($dR - $dL); if ($r.W -lt 50) { $r.W = 50 }
      $r.H += ($dB - $dT); if ($r.H -lt 50) { $r.H = 50 }
      MoveRaw $h $r | Out-Null
      Start-Sleep -Milliseconds 70
  }
  }

  # ----- Carregamento do layout e cálculo de posições -----

  if (-not (Test-Path -LiteralPath $LayoutFile)) { Write-Error "Layout não encontrado: $LayoutFile"; exit 1 }
  try {
  $layout = Get-Content -LiteralPath $LayoutFile | ConvertFrom-Json
  } catch {
  Write-Error ("Falha ao ler/parsear layout JSON: {0}" -f $_.Exception.Message); exit 1
  }

  # Estes nós são procurados por ProcessName/WindowTitle no JSON atual

  $chromeNode = $layout | Where-Object { $_.ProcessName -eq 'chrome' } | Select-Object -First 1
  $topoNode   = $layout | Where-Object { $.WindowTitle -eq 'PWS-Topo' } | Select-Object -First 1
  $baseNode   = $layout | Where-Object { $_.WindowTitle -eq 'PWS-Base' } | Select-Object -First 1

  if (-not $chromeNode -or -not $topoNode -or -not $baseNode) {
  Write-Error "JSON deve conter chrome, PWS-Topo e PWS-Base."; exit 1
  }

  $ChromeRect = @{ X_Abs = ($chromeNode.Rect.X + $work.Left); Y_Abs = ($chromeNode.Rect.Y + $work.Top); W = $chromeNode.Rect.W; H = $chromeNode.Rect.H }
  $TopoRect   = @{ X_Abs = ($topoNode.Rect.X   + $work.Left); Y_Abs = ($topoNode.Rect.Y   + $work.Top); W = $topoNode.Rect.W;   H = $topoNode.Rect.H }
  $BaseRect   = @{ X_Abs = ($baseNode.Rect.X   + $work.Left); Y_Abs = ($baseNode.Rect.Y   + $work.Top); W = $baseNode.Rect.W;   H = $baseNode.Rect.H }

  # ----- Garantir processos / abrir janelas -----

  $chrome = Ensure-Chrome
  $pwTop  = Start-Or-Find 'PWS-Topo'  'C:'
  $pwBase = Start-Or-Find 'PWS-Base' 'D:\TEIA\TEIA_NUCLEO\offline\nano'

  # ----- Aplicar layout -----

  if ($chrome) { Magnetize-To $chrome $ChromeRect $Tolerance $MaxRetries }
  if ($pwTop)  { Magnetize-To $pwTop  $TopoRect   $Tolerance $MaxRetries }
  if ($pwBase) { Magnetize-To $pwBase $BaseRect   $Tolerance $MaxRetries }

  Write-Host "Layout restaurado de: $LayoutFile"

  Comando PowerShell (idempotente) para atualizar o arquivo
  $target = 'D:\Scripts\Set-TEIA-Workspace.ps1'
  $backupDir = 'D:\Scripts\backups'
  If (-not (Test-Path $backupDir)) { New-Item -Path $backupDir -ItemType Directory | Out-Null }
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  If (Test-Path $target) {
  Copy-Item -LiteralPath $target -Destination (Join-Path $backupDir ("Set-TEIA-Workspace_$ts.ps1")) -Force
  }
  $new = @'
  PASTE THE FULL SCRIPT CONTENT FROM THE “Arquivo PowerShell Corrigido” SECTION ABOVE HERE
  '@
  Set-Content -LiteralPath $target -Value $new -Encoding UTF8
  Write-Host "Arquivo atualizado: $target (backup em $backupDir)"

  If you want, I can output the here-string already filled with the script body so you can paste once — just say the word.

  Instruções Rápidas

  - Abra PowerShell como Administrador.
  - Backup: Copy-Item D:\Scripts\Set-TEIA-Workspace.ps1 D:\Scripts\backups\Set-TEIA-Workspace_PRE_replace.ps1
  - Substitua o arquivo com o Set-Content usando o here-string acima.
  - Execute: pwsh -NoProfile -File D:\Scripts\Set-TEIA-Workspace.ps1 e observe mensagens no console.

  Resumo das Mudanças

  - Reserved var conflict: Renomeado $args → $elevArgs no bloco de auto-elevação (evita conflito com variável automática $args).
  - $pid/PID: Nenhum uso de $pid/$PID encontrado no original; garantido que o script atualizado não usa $pid (0 ocorrências).
  - Win32 GetWindowThreadProcessId: Adicionada assinatura P/Invoke correta (out uint) e wrapper Get-WindowProcessId que usa [ref] $procId. Não há atribuição a $PID.
  - Try/catch e logs: Envolvidas chamadas Win32 em Get-ExtRect, MoveRaw, Wait-Main e Ensure-Chrome com try/catch e Write-Warning de fallback.
  - Posicionamento robusto: Mantido Magnetize-To com tolerância e retries; ajustes incrementais de posição/tamanho e limites mínimos.
  - Compatibilidade: Mantido DPI per-monitor awareness e uso de DWM extended frame bounds; compatível com PowerShell 7+.
  - Backup: Backup automático criado em D:\Scripts\backups antes da sobrescrita (timestamp).

  Quer que eu gere o comando Set-Content com o here-string já preenchido com o script completo, pronto para colar?

---

### ASSISTENTE

Boa — vou te dar **duas coisas práticas** agora:

1. **Texto pronto** (em português) para você colar como resposta/commit/log/retorno ao Codex / CI — curto e objetivo.  
2. **Comando PowerShell seguro** (pronto para colar) que grava o script corrigido em `D:\Scripts\Set-TEIA-Workspace.ps1` usando um here-string + `Out-File -Encoding utf8 -Force` (evita todos os problemas de *escaping* que apareceram no seu `pwsh -Command '…'`). Também incluo comandos de verificação e execução.

---

# 1) Texto pronto para responder (copiar/colar)
> **Status:** Tentei atualizar `D:\Scripts\Set-TEIA-Workspace.ps1` com as correções de segurança/Win32 (remoção de conflito com `$PID`, wrappers Win32, retry/tolerance, backup automático).  
> **Observação:** o primeiro attempt apresentou problemas de *quoting* (o conteúdo foi passado via `pwsh -Command '...'` e o here-string foi corrompido por aspas/simbolos).  
> **Ação recomendada:** executar o bloco PowerShell seguro (anexo) para gravar a versão correta — ele cria backup, grava o arquivo em UTF-8 e confirma os counts de ocorrências de `$pid` e `GetWindowThreadProcessId`.  
> **Próximos passos:** após gravar, rodar o script como Administrador e verificar: (1) janelas abertas/posicionadas; (2) logs no console; (3) se persistirem desalinhamentos, iteraremos adicionando waits específicos para carregamento de UI, correção DPI e ajuste por escala de monitor.  
> **Se quiser que eu escreva o arquivo diretamente aqui** (Set-Content/Out-File com o script completo), diga “grava agora” e eu gero o bloco pronto.

---

# 2) Bloco PowerShell seguro (grava o script atualizado corretamente)
Cole **exatamente** isto num PowerShell aberto como Administrador e rode. Ele faz backup e grava o arquivo com o conteúdo corrigido.

> IMPORTANTE: o bloco abaixo já contém o script corrigido (substitui o arquivo atual). Se preferir revisar antes, me diga e eu mostro só o diff.

```powershell
# --- backup + gravação segura do Set-TEIA-Workspace.ps1 ---
$target = 'D:\Scripts\Set-TEIA-Workspace.ps1'
$backupDir = 'D:\Scripts\backups'
If (-not (Test-Path $backupDir)) { New-Item -Path $backupDir -ItemType Directory | Out-Null }
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
If (Test-Path $target) {
    Copy-Item -LiteralPath $target -Destination (Join-Path $backupDir ("Set-TEIA-Workspace_$ts.ps1")) -Force
    Write-Host "Backup criado em $backupDir\Set-TEIA-Workspace_$ts.ps1"
}

# here-string com o script corrigido
$body = @'
# Set-TEIA-Workspace.ps1
param(
  [string]$LayoutFile = "D:\Scripts\Layouts\CurrentLayout.json",
  [int]$Tolerance = 1,
  [int]$MaxRetries = 10
)

# ----- Auto-elevação (preserva parâmetros) -----
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  $elevArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSCommandPath")
  $PSBoundParameters.GetEnumerator() | ForEach-Object { $elevArgs += "-$($_.Key)"; $elevArgs += "$($_.Value)" }
  Start-Process -FilePath 'powershell.exe' -ArgumentList $elevArgs -Verb RunAs
  exit
}

# ----- DPI: Per-Monitor Aware V2 -----
Add-Type -Name Dpi -Namespace W32 -MemberDefinition @"
using System;
using System.Runtime.InteropServices;
public static class DPI {
  [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);
}
"@
try { [void][W32.DPI]::SetThreadDpiAwarenessContext([intptr](-4)) } catch {}

# ----- Win32 interop -----
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace W32 {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
  public static class U32 {
    [DllImport("user32.dll", SetLastError=true)] public static extern bool MoveWindow(IntPtr hWnd,int X,int Y,int W,int H,bool repaint);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool ShowWindow(IntPtr hWnd,int cmd);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
    [DllImport("user32.dll", SetLastError=true)] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
  }
  public static class Dwm {
    [DllImport("dwmapi.dll", PreserveSig=true)] public static extern int DwmGetWindowAttribute(IntPtr hwnd,int attr,out RECT pv,int cb);
    public const int DWMWA_EXTENDED_FRAME_BOUNDS = 9;
  }
}
"@

Add-Type -AssemblyName System.Windows.Forms
$work = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

# ----- Helpers -----
function Get-ExtRect {
  param([IntPtr]$h)
  try {
    if ($h -eq [IntPtr]::Zero) { return $null }
    $r = New-Object W32.RECT
    $hr = [W32.Dwm]::DwmGetWindowAttribute($h,[W32.Dwm]::DWMWA_EXTENDED_FRAME_BOUNDS,[ref]$r,[Runtime.InteropServices.Marshal]::SizeOf([type]W32.RECT))
    if ($hr -ne 0) {
      $ok = [W32.U32]::GetWindowRect($h,[ref]$r)
      if (-not $ok) { return $null }
    }
    return [pscustomobject]@{ L=$r.Left; T=$r.Top; R=$r.Right; B=$r.Bottom; W=$r.Right-$r.Left; H=$r.Bottom-$r.Top }
  } catch {
    Write-Warning ("Get-ExtRect falhou: {0}" -f $_.Exception.Message)
    return $null
  }
}

function MoveRaw {
  param([IntPtr]$h, [hashtable]$R)
  try {
    if ($h -eq [IntPtr]::Zero) { return $false }
    [void][W32.U32]::ShowWindow($h,9)
    [void][W32.U32]::SetForegroundWindow($h)
    [void][W32.U32]::MoveWindow($h,[int]$R.X,[int]$R.Y,[int]$R.W,[int]$R.H,$true)
    return $true
  } catch {
    Write-Warning ("MoveRaw falhou: {0}" -f $_.Exception.Message)
    return $false
  }
}

function Wait-Main {
  param([System.Diagnostics.Process]$p,[int]$ms=60000)
  if (-not $p) { return [IntPtr]::Zero }
  try {
    $sw=[Diagnostics.Stopwatch]::StartNew(); $p.Refresh()
    while($p.MainWindowHandle -eq [IntPtr]::Zero -and $sw.ElapsedMilliseconds -lt $ms){ Start-Sleep -Milliseconds 80; $p.Refresh() }
    return $p.MainWindowHandle
  } catch {
    Write-Warning ("Wait-Main falhou: {0}" -f $_.Exception.Message)
    return [IntPtr]::Zero
  }
}

function Get-WindowProcessId {
  param([IntPtr]$h)
  try {
    if ($h -eq [IntPtr]::Zero) { return 0 }
    $procId = [uint32]0
    [void][W32.U32]::GetWindowThreadProcessId($h, [ref]$procId)
    return [int]$procId
  } catch {
    Write-Warning ("GetWindowThreadProcessId falhou: {0}" -f $_.Exception.Message)
    return 0
  }
}

function Start-Or-Find {
  param([string]$title, [string]$dir)
  $p = Get-Process pwsh,powershell -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq $title } | Select-Object -First 1
  if ($p) { return $p }
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) { $dir = 'C:\' }
  $cmd = "`$host.UI.RawUI.WindowTitle = '$title'; try{ Set-Location -LiteralPath '$dir' } catch {} ; cd"
  return Start-Process -FilePath 'pwsh.exe' -ArgumentList @('-NoExit','-NoProfile','-Command',$cmd) -PassThru
}

function Ensure-Chrome {
  try {
    $p = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle } | Select-Object -First 1
    if ($p) { return $p }
    $exe = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"; if (-not (Test-Path $exe)) { $exe = 'chrome.exe' }
    return Start-Process -FilePath $exe -ArgumentList @('--new-window','https://chat.openai.com/') -WindowStyle Normal -PassThru
  } catch {
    Write-Warning ("Ensure-Chrome falhou: {0}" -f $_.Exception.Message)
    return $null
  }
}

function Magnetize-To {
  param([System.Diagnostics.Process]$p, [hashtable]$t, [int]$tol, [int]$max)
  $h = Wait-Main $p 5000
  if ($h -eq [IntPtr]::Zero) { Write-Warning "Janela não encontrada para processo: $($p.ProcessName)"; return }
  $r = @{ X=[int]$t.X_Abs; Y=[int]$t.Y_Abs; W=[int]$t.W; H=[int]$t.H }
  MoveRaw $h $r; Start-Sleep -Milliseconds 120
  for ($i=0; $i -lt $max; $i++) {
    $m = Get-ExtRect $h
    if (-not $m) { break }
    $dL = $t.X_Abs - $m.L; $dT = $t.Y_Abs - $m.T
    $dR = ($t.X_Abs + $t.W) - $m.R; $dB = ($t.Y_Abs + $t.H) - $m.B
    $delta = [math]::Max([math]::Abs($dL), [math]::Abs($dT), [math]::Abs($dR), [math]::Abs($dB))
    if ($delta -le $tol) { break }
    $r.X += $dL; $r.Y += $dT
    $newW = $r.W + ($dR - $dL); if ($newW -lt 50) { $newW = 50 }
    $newH = $r.H + ($dB - $dT); if ($newH -lt 50) { $newH = 50 }
    $r.W = $newW; $r.H = $newH
    MoveRaw $h $r
    Start-Sleep -Milliseconds 80
  }
}

# ----- Carregamento do layout -----
if (-not (Test-Path -LiteralPath $LayoutFile)) { Write-Error "Layout não encontrado: $LayoutFile"; exit 1 }
try {
  $layout = Get-Content -LiteralPath $LayoutFile -Raw | ConvertFrom-Json
} catch {
  Write-Error "Falha ao ler/parsear layout JSON: $($_.Exception.Message)"; exit 1
}

# Identifica nós (ex: chrome, PWS-Topo, PWS-Base)
$chromeNode = $layout.nodes.chrome
$topoNode   = $layout.nodes.'PWS-Topo'
$baseNode   = $layout.nodes.'PWS-Base'

if (-not $chromeNode -or -not $topoNode -or -not $baseNode) {
  Write-Error "Nós chrome, PWS-Topo e PWS-Base não encontrados no JSON"; exit 1
}

$ChromeRect = @{ X_Abs = ($chromeNode.Rect.X + $work.Left); Y_Abs = ($chromeNode.Rect.Y + $work.Top); W = $chromeNode.Rect.W; H = $chromeNode.Rect.H }
$TopoRect   = @{ X_Abs = ($topoNode.Rect.X + $work.Left); Y_Abs = ($topoNode.Rect.Y + $work.Top); W = $topoNode.Rect.W; H = $topoNode.Rect.H }
$BaseRect   = @{ X_Abs = ($baseNode.Rect.X + $work.Left); Y_Abs = ($baseNode.Rect.Y + $work.Top); W = $baseNode.Rect.W; H = $baseNode.Rect.H }

# ----- Abrir/processos e aplicar layout -----
$chrome = Ensure-Chrome
$pwTop  = Start-Or-Find 'PWS-Topo'  'C:\'
$pwBase = Start-Or-Find 'PWS-Base' 'D:\TEIA\TEIA_NUCLEO\offline\nano'

if ($chrome) { Magnetize-To $chrome $ChromeRect $Tolerance $MaxRetries }
if ($pwTop)  { Magnetize-To $pwTop  $TopoRect   $Tolerance $MaxRetries }
if ($pwBase) { Magnetize-To $pwBase $BaseRect   $Tolerance $MaxRetries }

Write-Host "Layout restaurado de: $LayoutFile"
'@

# grava em UTF8 (Out-File evita problemas de escaping)
$body | Out-File -FilePath $target -Encoding utf8 -Force
Write-Host "Arquivo gravado: $target"
```

---

# 3) Comandos de verificação (após gravação)
Cole e rode (não precisa ser Admin):

```powershell
# 1) confirmar backup:
Get-ChildItem 'D:\Scripts\backups' | Sort-Object LastWriteTime -Descending | Select-Object -First 5

# 2) checar ocorrências perigosas (case-insensitive)
(Get-Content -LiteralPath 'D:\Scripts\Set-TEIA-Workspace.ps1' -Raw) |
  Select-String -Pattern '(?i)\$pid\b|GetWindowThreadProcessId' -AllMatches |
  Group-Object Pattern | Format-Table Name,Count -AutoSize

# 3) testar leitura do JSON de layout (apenas para validar parse)
try { Get-Content 'D:\Scripts\Layouts\CurrentLayout.json' -Raw | ConvertFrom-Json | Select-Object -First 1; Write-Host "JSON ok" } catch { Write-Host "JSON inválido: $_" }

# 4) rodar o script como admin (vai pedir UAC)
Start-Process -FilePath pwsh -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','D:\Scripts\Set-TEIA-Workspace.ps1' -Verb RunAs -Wait
```

---

# 4) Se ainda houver desalinhamento visual — checklist rápido de causas e ações
- Windows com **escala de DPI** diferente de 100% → ajustar/normalizar ou usar conversão logical↔physical.  
- Chrome/Edge altera tamanho interno de conteúdo (barra de rolagem/Bookmark bar) → adicionar `Start-Sleep` e repetir `MoveWindow` após load.  
- Janelas sem `MainWindowHandle` imediato (terminais) → aumentar timeout no `Wait-Main`.  
- Múltiplos monitores → checar `work.Left`/`work.Top` e coordenadas absolutas; se necessário, use `Get-CimInstance Win32_DisplayConfiguration`.  
- Se necessário, eu adiciono waits por título de aba específica ou inject JS em Chrome para forçar tamanho (mais avançado).

---

Quer que eu:
- **(A)** gere o here-string pronto com o script (já fiz no bloco acima — é só colar e rodar), **ou**  
- **(B)** só gere um `diff` entre o arquivo que está no disco e a versão corrigida antes de sobrescrever, para você revisar?  

Diga qual prefere e eu te entrego no próximo passo.

---

### USUÁRIO

[> I prepared a safe, single‑paste PowerShell block that backs up, writes the corrected script (embedded), saves with UTF‑8, and prints validation counts. It avoids quoting pitfalls by using a single‑quoted here‑string.

  Bloco Seguro (backup + gravação + validação)
  $ErrorActionPreference = 'Stop'
  $target = 'D:\Scripts\Set-TEIA-Workspace.ps1'
  $backupDir = 'D:\Scripts\backups'

  # 1) Backup

  if (-not (Test-Path -LiteralPath $backupDir)) {
  New-Item -Path $backupDir -ItemType Directory | Out-Null
  }
  if (Test-Path -LiteralPath $target) {
  $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
  Copy-Item -LiteralPath $target -Destination (Join-Path $backupDir ("Set-TEIA-Workspace_$ts.ps1")) -Force
  Write-Host "Backup criado: $backupDir\Set-TEIA-Workspace_$ts.ps1"
  } else {
  Write-Host "Aviso: arquivo alvo ainda não existe ($target)"
  }

  # 2) Gravação do novo conteúdo (UTF-8, literal here-string)

  $new = @'

  # Set-TEIA-Workspace.ps1

  param(
  [string]$LayoutFile = "D:\Scripts\Layouts\CurrentLayout.json",
  [int]$Tolerance = 1,
  [int]$MaxRetries = 10
  )

  # ----- Auto-elevação (preserva parâmetros) -----

  if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  $elevArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',""$PSCommandPath"")
  $PSBoundParameters.GetEnumerator() | ForEach-Object { $elevArgs += "-$($_.Key)"; $elevArgs += ""$($_.Value)"" }
  Start-Process -FilePath 'powershell.exe' -ArgumentList $elevArgs -Verb RunAs
  exit
  }

  # ----- DPI: Per-Monitor Aware V2 -----

  Add-Type -Name Dpi -Namespace W32 -MemberDefinition @"
  using System;
  using System.Runtime.InteropServices;
  public static class DPI {
  [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);
  }
  "@
  [void][W32.DPI]::SetThreadDpiAwarenessContext(intptr (-4))

  # ----- Win32 interop (tipos e funções necessárias) -----

  Add-Type -TypeDefinition @"
  using System;
  using System.Runtime.InteropServices;
  namespace W32 {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
  public static class U32 {
      [DllImport("user32.dll", SetLastError=true)] public static extern bool MoveWindow(IntPtr hWnd,int X,int Y,int W,int H,bool repaint);
      [DllImport("user32.dll", SetLastError=true)] public static extern bool ShowWindow(IntPtr hWnd,int cmd);
      [DllImport("user32.dll", SetLastError=true)] public static extern bool SetForegroundWindow(IntPtr hWnd);
      [DllImport("user32.dll", SetLastError=true)] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
      [DllImport("user32.dll", SetLastError=true)] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
  }
  public static class Dwm {
      [DllImport("dwmapi.dll", PreserveSig=true)] public static extern int DwmGetWindowAttribute(IntPtr hwnd,int attr,out RECT pv,int cb);
      public const int DWMWA_EXTENDED_FRAME_BOUNDS = 9;
  }
  }
  "@

  Add-Type -AssemblyName System.Windows.Forms
  $work = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

  # ----- Helpers (PowerShell wrappers) -----

  function Get-ExtRect {
  param([IntPtr]$h)
  try {
      if ($h -eq [IntPtr]::Zero) { return $null }
      $r = New-Object W32.RECT
      $hr = [W32.Dwm]::DwmGetWindowAttribute($h,[W32.Dwm]::DWMWA_EXTENDED_FRAME_BOUNDS,[ref]$r,[Runtime.InteropServices.Marshal]::SizeOf([type]'W32.RECT'))
      if ($hr -ne 0) {
        $ok = [W32.U32]::GetWindowRect($h,[ref]$r)
        if (-not $ok) { return $null }
      }
      return [pscustomobject]@{ L=$r.Left; T=$r.Top; R=$r.Right; B=$r.Bottom; W=$r.Right-$r.Left; H=$r.Bottom-$r.Top }
  } catch {
      Write-Warning ("Get-ExtRect falhou: {0}" -f $_.Exception.Message)
      return $null
  }
  }

  function MoveRaw {
  param([IntPtr]$h, [hashtable]$R)
  try {
      if ($h -eq [IntPtr]::Zero) { return $false }
      [void][W32.U32]::ShowWindow($h,9)
      [void][W32.U32]::SetForegroundWindow($h)
      [void][W32.U32]::MoveWindow($h,[int]$R.X,[int]$R.Y,[int]$R.W,[int]$R.H,$true)
      return $true
  } catch {
      Write-Warning ("MoveRaw falhou: {0}" -f $_.Exception.Message)
      return $false
  }
  }

  function Wait-Main {
  param([System.Diagnostics.Process]$p,[int]$ms=60000)
  if (-not $p) { return [IntPtr]::Zero }
  try {
      $sw=[Diagnostics.Stopwatch]::StartNew(); $p.Refresh()
      while($p.MainWindowHandle -eq [IntPtr]::Zero -and $sw.ElapsedMilliseconds -lt $ms){ Start-Sleep -Milliseconds 80; $p.Refresh() }
      return $p.MainWindowHandle
  } catch {
      Write-Warning ("Wait-Main falhou: {0}" -f $_.Exception.Message)
      return [IntPtr]::Zero
  }
  }

  # Wrapper seguro para obter o PID de uma janela (exemplo de uso do [ref])

  function Get-WindowProcessId {
  param([IntPtr]$h)
  try {
      if ($h -eq [IntPtr]::Zero) { return 0 }
      $procId = [uint32]0
      [void][W32.U32]::GetWindowThreadProcessId($h, [ref]$procId)
      return [int]$procId
  } catch {
      Write-Warning ("GetWindowThreadProcessId falhou: {0}" -f $_.Exception.Message)
      return 0
  }
  }

  # Robust process finder: por título ou processo

  function Start-Or-Find {
  param([string]$title, [string]$dir)
  $p = Get-Process pwsh,powershell -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq $title } | Select-Object -First 1
  if ($p) { return $p }
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) { $dir = 'C:' }
  $cmd = "`$host.UI.RawUI.WindowTitle = '$title'; try{ Set-Location -LiteralPath '$dir' } catch {} ; cd"
  return Start-Process -FilePath 'pwsh.exe' -Verb RunAs -WindowStyle Normal -ArgumentList @('-NoExit','-NoProfile','-Command',$cmd) -PassThru
  }

  function Ensure-Chrome {
  try {
      $p = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle } | Select-Object -First 1
      if ($p) { return $p }
      $exe = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"; if (-not (Test-Path $exe)) { $exe = 'chrome.exe' }
      return Start-Process -FilePath $exe -ArgumentList @('--new-window','https://gemini.google.com/app') -WindowStyle Normal -PassThru
  } catch {
      Write-Warning ("Ensure-Chrome falhou: {0}" -f $_.Exception.Message)
      return $null
  }
  }

  # Magnetize-To: alinha janela principal ao retângulo alvo com retries

  function Magnetize-To {
  param([System.Diagnostics.Process]$p, [hashtable]$t, [int]$tol, [int]$max)
  $h = Wait-Main $p
  if ($h -eq [IntPtr]::Zero) { Write-Warning "Janela não encontrada: $($p.ProcessName)"; return }
  $r = @{ X=[int]$t.X_Abs; Y=[int]$t.Y_Abs; W=[int]$t.W; H=[int]$t.H }
  MoveRaw $h $r | Out-Null; Start-Sleep -Milliseconds 120
  for ($i=0; $i -lt $max; $i++) {
      $m = Get-ExtRect $h
      if (-not $m) { break }
      $dL = $t.X_Abs - $m.L; $dT = $t.Y_Abs - $m.T
      $dR = ($t.X_Abs + $t.W) - $m.R; $dB = ($t.Y_Abs + $t.H) - $m.B
      $delta = [math]::Max([math]::Abs($dL), [math]::Abs($dT), [math]::Abs($dR), [math]::Abs($dB))
      if ($delta -le $tol) { break }
      $r.X += $dL; $r.Y += $dT
      $r.W += ($dR - $dL); if ($r.W -lt 50) { $r.W = 50 }
      $r.H += ($dB - $dT); if ($r.H -lt 50) { $r.H = 50 }
      MoveRaw $h $r | Out-Null
      Start-Sleep -Milliseconds 70
  }
  }

  # ----- Carregamento do layout e cálculo de posições -----

  if (-not (Test-Path -LiteralPath $LayoutFile)) { Write-Error "Layout não encontrado: $LayoutFile"; exit 1 }
  try {
  $layout = Get-Content -LiteralPath $LayoutFile | ConvertFrom-Json
  } catch {
  Write-Error ("Falha ao ler/parsear layout JSON: {0}" -f $_.Exception.Message); exit 1
  }

  # Estes nós são procurados por ProcessName/WindowTitle no JSON atual

  $chromeNode = $layout | Where-Object { $_.ProcessName -eq 'chrome' } | Select-Object -First 1
  $topoNode   = $layout | Where-Object { $.WindowTitle -eq 'PWS-Topo' } | Select-Object -First 1
  $baseNode   = $layout | Where-Object { $_.WindowTitle -eq 'PWS-Base' } | Select-Object -First 1

  if (-not $chromeNode -or -not $topoNode -or -not $baseNode) {
  Write-Error "JSON deve conter chrome, PWS-Topo e PWS-Base."; exit 1
  }

  $ChromeRect = @{ X_Abs = ($chromeNode.Rect.X + $work.Left); Y_Abs = ($chromeNode.Rect.Y + $work.Top); W = $chromeNode.Rect.W; H = $chromeNode.Rect.H }
  $TopoRect   = @{ X_Abs = ($topoNode.Rect.X   + $work.Left); Y_Abs = ($topoNode.Rect.Y   + $work.Top); W = $topoNode.Rect.W;   H = $topoNode.Rect.H }
  $BaseRect   = @{ X_Abs = ($baseNode.Rect.X   + $work.Left); Y_Abs = ($baseNode.Rect.Y   + $work.Top); W = $baseNode.Rect.W;   H = $baseNode.Rect.H }

  # ----- Garantir processos / abrir janelas -----

  $chrome = Ensure-Chrome
  $pwTop  = Start-Or-Find 'PWS-Topo'  'C:'
  $pwBase = Start-Or-Find 'PWS-Base' 'D:\TEIA\TEIA_NUCLEO\offline\nano'

  # ----- Aplicar layout -----

  if ($chrome) { Magnetize-To $chrome $ChromeRect $Tolerance $MaxRetries }
  if ($pwTop)  { Magnetize-To $pwTop  $TopoRect   $Tolerance $MaxRetries }
  if ($pwBase) { Magnetize-To $pwBase $BaseRect   $Tolerance $MaxRetries }

  Write-Host "Layout restaurado de: $LayoutFile"
  '@

  Set-Content -LiteralPath $target -Value $new -Encoding UTF8
  Write-Host "Arquivo atualizado: $target"

  # 3) Validação de ocorrências

  $raw = Get-Content -LiteralPath $target -Raw
  $pidCount   = ([regex]::Matches($raw,'(?i)$pid\b')).Count
  $gwtpiCount = ([regex]::Matches($raw,'GetWindowThreadProcessId')).Count
  Write-Host ("Counts => $pid: {0}  GetWindowThreadProcessId: {1}" -f $pidCount, $gwtpiCount)

  # 4) (Opcional) Validação de JSON

  try {
  $null = (Get-Content 'D:\Scripts\Layouts\CurrentLayout.json' -Raw | ConvertFrom-Json)
  Write-Host "JSON ok"
  } catch {
  Write-Host "JSON inválido: $_"
  }

  Mudanças Principais

  - Variable safety: Evita conflito com automáticas ($pid/$PID, $args). Usa $elevArgs e nenhum uso de $pid.
  - Win32 wrappers: Get-WindowProcessId usa [ref] $procId com GetWindowThreadProcessId. MoveRaw/Get-ExtRect/Wait-Main envoltos em try/catch com logs.
  - Posicionamento: Magnetize-To com tolerância e retries; ajustes incrementais de X/Y/W/H e limites mínimos.
  - DPI/bordas: Usa DWM extended frame bounds e SetThreadDpiAwarenessContext para consistência em monitores com escala.
  - Backup/idempotência: Cria backup timestampado, grava UTF‑8, e valida ocorrências no final.

  Próximos Passos

  - Execute o bloco acima em PowerShell (Admin). Confirme counts: $pid deve ser 0.
  - Rode: pwsh -NoProfile -File D:\Scripts\Set-TEIA-Workspace.ps1 (como Admin).
  - Se houver desalinhamentos, diga e eu adiciono waits específicos (DOMContentLoaded/handles) e ajustes de DPI/escala.]

Após executar não abriu nenhuma página...

---

### ASSISTENTE

Beleza — vamos depurar rápido e prático. Você rodou o bloco que grava o script, mas nada abriu: pode ser problema de (1) o script não ter sido gravado corretamente / ter erro de parsing, (2) `Ensure-Chrome` ter caminho errado, (3) o script ter sido executado em contexto/elevação que impede abrir janelas interativas, ou (4) timeout/handles não detectados (janelas sem `MainWindowHandle` imediato). Vou te dar passos imediatos (copiar→colar) para checar o que aconteceu e um **teste mínimo** que abre Chrome + duas janelas PowerShell e verifica/mostra handles — assim isolamos a causa.

Siga os passos na ordem (cole e rode no PowerShell; não precisa ser Admin para as verificações):

---

## 1) Verificar que o arquivo foi gravado corretamente e ver counts
```powershell
# confirma arquivo e backup
Test-Path 'D:\Scripts\Set-TEIA-Workspace.ps1' ; Get-ChildItem 'D:\Scripts\backups' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 3

# mostrar últimas 60 linhas do script (ver se não ficou truncado)
Get-Content 'D:\Scripts\Set-TEIA-Workspace.ps1' -Tail 60

# counts (procura por $pid e GetWindowThreadProcessId)
$raw = Get-Content -LiteralPath 'D:\Scripts\Set-TEIA-Workspace.ps1' -Raw
[regex]::Matches($raw,'(?i)\$pid\b').Count, [regex]::Matches($raw,'GetWindowThreadProcessId').Count
```
Resultados esperados:
- `Test-Path` = `True`.  
- Backup listado.  
- `Get-Content -Tail` mostra final do arquivo (não vazio).  
- Counts: 0 para `$pid` e >=1 para `GetWindowThreadProcessId`.

Se o arquivo não existir ou estiver vazio → houve problema na gravação (volte e rode o bloco de gravação novamente).

---

## 2) Testar parse do script (detecta erros de sintaxe sem executar)
```powershell
$code = Get-Content -Raw 'D:\Scripts\Set-TEIA-Workspace.ps1'
try {
  [scriptblock]::Create($code) > $null
  Write-Host "Parse OK (sem erro de sintaxe)"
} catch {
  Write-Error "Erro de parsing: $($_.Exception.Message)"
}
```
Se der **erro de parsing**, o script tem algum problema de quoting/aspas que impede execução — cole o erro aqui que eu corrijo.

---

## 3) Teste mínimo isolado — abre Chrome + 2 PowerShell e reporta handles
Cole e rode este bloco. Ele não depende do seu script grande; serve para confirmar se *abrir* janelas funciona no seu ambiente.

```powershell
# Teste mínimo: abre Chrome e duas janelas pwsh com títulos e reporta handles
# Ajuste o caminho do chrome se necessário
$chromeExe = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromeExe)) { $chromeExe = "chrome.exe" }   # fallback para PATH

# 1) abre Chrome (nova janela)
$chromeProc = Start-Process -FilePath $chromeExe -ArgumentList '--new-window','https://chat.openai.com/' -PassThru
Start-Sleep -Milliseconds 500

# 2) abre duas janelas pwsh com títulos (PWS-Topo e PWS-Base)
$pwTop = Start-Process -FilePath pwsh -ArgumentList '-NoExit','-Command',"`$host.UI.RawUI.WindowTitle = 'PWS-Topo'; Start-Sleep -Seconds 600" -PassThru
$pwBase = Start-Process -FilePath pwsh -ArgumentList '-NoExit','-Command',"`$host.UI.RawUI.WindowTitle = 'PWS-Base'; Start-Sleep -Seconds 600" -PassThru

# aguarda até aparecer MainWindowHandle (max 8s)
$wait = { param($p, $ms) $end = (Get-Date).AddMilliseconds($ms); while((Get-Date) -lt $end) { $p.Refresh(); if ($p.MainWindowHandle -ne 0) { return $p.MainWindowHandle }; Start-Sleep -Milliseconds 150 }; return 0 }
$ch = & $wait $chromeProc 8000
$th = & $wait $pwTop 8000
$bh = & $wait $pwBase 8000

[pscustomobject]@{
  ChromePID = $chromeProc.Id; ChromeHandle = $ch
  PWTopPID  = $pwTop.Id;  PWTopHandle  = $th
  PWBasePID = $pwBase.Id; PWBaseHandle  = $bh
}
```

Interpretação:
- Se o bloco abrir Chrome e os dois pwsh e retornar handles não-zero → o ambiente consegue abrir janelas e detectá-las. Então o problema é **no script grande** (ex.: Ensure-Chrome falhou, timeout curto, path errado ou script terminou antes de abrir).
- Se **Chrome não abriu** ou handle = 0 → problema no caminho do executável ou políticas do sistema (ex.: bloqueio por política/antivírus) ou execução em sessão diferente.

Se o Chrome não abrir com `chrome.exe`, teste também:
```powershell
Start-Process -FilePath "C:\Program Files\Google\Chrome\Application\chrome.exe" -ArgumentList '--new-window','https://chat.openai.com/' -PassThru
```
ou simplesmente:
```powershell
Start-Process "https://chat.openai.com/"
```
(se isso abrir o navegador padrão, então o caminho do Chrome era o problema).

---

## 4) Se o teste mínimo funcionou — rodar o script principal com verbose e log
Rode o script grande manualmente num prompt elevado (Admin) para ver mensagens:
```powershell
# abrir um PowerShell como Administrador e rodar:
pwsh -NoProfile -ExecutionPolicy Bypass -File 'D:\Scripts\Set-TEIA-Workspace.ps1' -Verbose
```
Observe mensagens, warnings e qualquer Write-Warning/Write-Error que aparecer. Cole aqui o output se quiser que eu analise.

---

## 5) Possíveis causas comuns e correções rápidas (faça se o teste falhar)
1. **Caminho do Chrome incorreto** — Atualize `Ensure-Chrome` para forçar usar `Start-Process (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe')` com fallback `Start-Process 'start' 'https://...'` (ver exemplo abaixo).  
2. **Script rodado com elevação UAC** — se você executou o script como admin, alguns processos iniciados podem ficar em sessão diferente ou com comportamento diferente; tente rodar sem elevação apenas para abrir janelas (ou abra o navegador manualmente e rode só a parte de posicionamento).  
3. **Sintaxe/resíduos de quoting** no script — se `Parse OK` falhar, preciso do erro para corrigir.  
4. **Timeout curto para handles** — aumente `$MaxRetries` / `Wait-Main` timeout para 10-30s se janelas demoram a aparecer.  
5. **Escala/DPI** — se o Chrome abre mas fica fora da tela, ajuste `SetThreadDpiAwarenessContext` e aumente tolerância.

### Snippet atualizado `Ensure-Chrome` (substitua no script se quiser)
Cole no seu script no lugar da função Ensure-Chrome atual:
```powershell
function Ensure-Chrome {
  try {
    $p = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if ($p) { return $p }
    $exe = Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'
    if (-not (Test-Path $exe)) { $exe = Join-Path $env:ProgramFiles(x86) 'Google\Chrome\Application\chrome.exe' }
    if (-not (Test-Path $exe)) { Write-Warning "Chrome não encontrado em ProgramFiles; tentando abrir URL com Start-Process padrão."; return Start-Process 'https://chat.openai.com/' -PassThru }
    return Start-Process -FilePath $exe -ArgumentList '--new-window','https://chat.openai.com/' -PassThru
  } catch {
    Write-Warning ("Ensure-Chrome falhou: {0}" -f $_.Exception.Message)
    return $null
  }
}
```

---

## 6) Próximo passo sugerido (se quiser que eu aja)
Diga qual opção prefere:

- **(A)** Você roda os três blocos de verificação acima e cola os resultados (saídas do passo 1,2,3) — eu analiso e te digo a correção exata.  
- **(B)** Eu já gero um `Set-Content` final com o snippet `Ensure-Chrome` atualizado + aumentos de timeout e te entrego o here-string pronto para gravar (você só cola e roda).  
- **(C)** Quer que eu gere um `diff` entre o arquivo atual e a versão corrigida antes de sobrescrever (se você quiser revisão antes de substituir).

Se quiser, comece por **colar o resultado do passo 3 (o teste mínimo)** — isso já me diz se abrir janelas é possível no seu ambiente e qual é a causa mais provável.

---

### USUÁRIO

> # 1) Criação do arquivo idempotente via PowerShell (Set-Content com backup automático)
  if (Test-Path -LiteralPath .\TEIA-Window-Listener.ps1) {
    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    Copy-Item -LiteralPath .\TEIA-Window-Listener.ps1 -Destination ".\TEIA-Window-Listener.ps1.bak_$ts" -Force -ErrorAction SilentlyContinue
  }
  Set-Content -Path .\TEIA-Window-Listener.ps1 -Value @'
  # TEIA: Window Listener Mestre (v0.1)
  # 4 Passos Mestre:
  # 1) Correção de erro: try/catch global, logs rotacionados, backups automáticos.
  # 2) Integração núcleo fractal: hashes + manifests mínimos em .teia_core_out.
  # 3) Expansão otimização global: telemetria leve (durations, p95) e hook CV.
  # 4) Metas simbióticas futuras: teia_signature, agent, session_id para rastreio.

  param(
    [int]$PollMs = 200,
    [int]$ScreenshotLimit = 500
  )

  $ErrorActionPreference = 'Stop'

  # --- Configuração/Geral ---
  $AgentName   = 'TEIA-Window-Listener'
  $SessionId   = [guid]::NewGuid().ToString()
  $BaseDir     = (Get-Location).Path
  $ShotsDir    = Join-Path $BaseDir '.teia_screenshots'
  $CoreDir     = Join-Path $BaseDir '.teia_core_out'
  $LogFile     = Join-Path $BaseDir '.teia_window_events.log'
  $OutboxFile  = Join-Path $BaseDir '.teia_outboxlast_event.json'
  $Telemetry   = [System.Collections.Generic.List[double]]::new()

  # Diretórios
  foreach ($d in @($ShotsDir,$CoreDir)) {
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
  }

  # --- Utilitários de log/rotação ---
  function Write-TeiaLog([string]$message) {
    $line = "$(Get-Date -Format o) [$AgentName][$SessionId] $message"
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
  }
  function Rotate-Log {
    try {
      if (Test-Path -LiteralPath $LogFile) {
        $fi = Get-Item -LiteralPath $LogFile
        if ($fi.Length -gt 20MB) {
          $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
          $dest = "$LogFile.$ts"
          Move-Item -LiteralPath $LogFile -Destination $dest -Force
          Write-TeiaLog "Log rotacionado para: $dest"
        }
      }
    } catch {
      # Mantém robustez
    }
  }
  function Enforce-ScreenshotLimit([int]$keep=500) {
    try {
      $files = Get-ChildItem -LiteralPath $ShotsDir -Filter *.png | Sort-Object LastWriteTime -Descending
      if ($files.Count -gt $keep) {
        $toDelete = $files | Select-Object -Skip $keep
        foreach ($f in $toDelete) {
          Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue
        }
      }
    } catch {
      Write-TeiaLog "Falha ao aplicar limite de screenshots: $($_.Exception.Message)"
    }
  }

  # --- Interop Win32 ---
  Add-Type -AssemblyName System.Drawing
  Add-Type -Namespace Win32 -Name Native -MemberDefinition @"
  using System;
  using System.Runtime.InteropServices;
  using System.Text;

  public static class Native {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }

    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll", SetLastError=true)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll", SetLastError=true)] public static extern int GetWindowTextLength(IntPtr hWnd);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll", SetLastError=true)] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
    [DllImport("user32.dll", SetLastError=true)] public static extern short GetAsyncKeyState(int vKey);
  }
  "@

  function Get-ForegroundInfo {
    $h = [Win32.Native]::GetForegroundWindow()
    if ($h -eq [IntPtr]::Zero) { return $null }

    $len = [Win32.Native]::GetWindowTextLength($h)
    $sb = New-Object System.Text.StringBuilder ($len + 1)
    [void][Win32.Native]::GetWindowText($h, $sb, $sb.Capacity)

    $rect = New-Object Win32.Native+RECT
    if (-not [Win32.Native]::GetWindowRect($h, [ref]$rect)) { return $null }

    [uint32]$pid = 0
    [void][Win32.Native]::GetWindowThreadProcessId($h, [ref]$pid)
    $procName = $null
    try { $procName = (Get-Process -Id $pid -ErrorAction Stop).ProcessName } catch { $procName = $null }

    $width  = [math]::Max(0, $rect.Right - $rect.Left)
    $height = [math]::Max(0, $rect.Bottom - $rect.Top)
    [pscustomobject]@{
      Handle      = $h
      HandleHex   = ('0x{0:X}' -f $h.ToInt64())
      Title       = $sb.ToString()
      ProcessName = $procName
      Rect        = @{ left=$rect.Left; top=$rect.Top; right=$rect.Right; bottom=$rect.Bottom }
      Width       = $width
      Height      = $height
      Aspect      = if ($height -gt 0) { [math]::Round($width / $height, 4) } else { 0 }
    }
  }

  function Capture-WindowImage([IntPtr]$hWnd, [hashtable]$rect, [string]$destPng) {
    $w = [int]$rect.right - [int]$rect.left
    $h = [int]$rect.bottom - [int]$rect.top
    if ($w -le 0 -or $h -le 0) { return $false }

    $bmp = New-Object System.Drawing.Bitmap ($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc()
    $ok = $false
    try {
      $ok = [Win32.Native]::PrintWindow($hWnd, $hdc, 0)
    } catch {
      $ok = $false
    } finally {
      $g.ReleaseHdc($hdc)
    }
    if (-not $ok) {
      try {
        $g.CopyFromScreen([int]$rect.left, [int]$rect.top, 0, 0, $bmp.Size, [System.Drawing.CopyPixelOperation]::SourceCopy)
        $ok = $true
      } catch {
        $ok = $false
      }
    }
    try {
      if ($ok) {
        $bmp.Save($destPng, [System.Drawing.Imaging.ImageFormat]::Png)
      }
    } finally {
      $g.Dispose()
      $bmp.Dispose()
    }
    return $ok
  }

  function Get-FileSha256([string]$path) {
    try { (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant() } catch { $null }
  }

  function Get-AvgColorHex([string]$imagePath) {
    try {
      $bmp = [System.Drawing.Image]::FromFile($imagePath)
      try {
        $thumb = New-Object System.Drawing.Bitmap 1,1
        $g = [System.Drawing.Graphics]::FromImage($thumb)
        try {
          $g.DrawImage($bmp, 0, 0, 1, 1)
        } finally {
          $g.Dispose()
        }
        $px = $thumb.GetPixel(0,0)
        $rgb = @($px.R, $px.G, $px.B)
        $hex = ('#{0:X2}{1:X2}{2:X2}' -f $px.R, $px.G, $px.B)
        [pscustomobject]@{ rgb=$rgb; hex=$hex }
      } finally {
        $bmp.Dispose()
      }
    } catch {
      $null
    }
  }

  function Get-EdgeCount([string]$imagePath) {
    try {
      $src = [System.Drawing.Bitmap]::FromFile($imagePath)
      try {
        $maxW = 160
        $scale = if ($src.Width -gt $maxW) { $maxW / [double]$src.Width } else { 1.0 }
        $tw = [int]([math]::Max(1, [math]::Round($src.Width * $scale)))
        $th = [int]([math]::Max(1, [math]::Round($src.Height * $scale)))
        $small = New-Object System.Drawing.Bitmap $tw, $th
        $g = [System.Drawing.Graphics]::FromImage($small)
        try {
          $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
          $g.DrawImage($src, 0, 0, $tw, $th)
        } finally {
          $g.Dispose()
        }
        $gray = New-Object 'int[,]' $tw, $th
        for ($y=0; $y -lt $th; $y++) {
          for ($x=0; $x -lt $tw; $x++) {
            $p = $small.GetPixel($x,$y)
            $val = [int](0.299*$p.R + 0.587*$p.G + 0.114*$p.B)
            $gray[$x,$y] = $val
          }
        }
        $edges = 0
        $thresh = 60
        for ($y=1; $y -lt ($th-1); $y++) {
          for ($x=1; $x -lt ($tw-1); $x++) {
            $gx = -$gray[$x-1,$y-1] + $gray[$x+1,$y-1] +
                  -2*$gray[$x-1,$y]   + 2*$gray[$x+1,$y] +
                  -$gray[$x-1,$y+1] + $gray[$x+1,$y+1]
            $gy =  $gray[$x-1,$y-1] + 2*$gray[$x,$y-1] + $gray[$x+1,$y-1] -
                   $gray[$x-1,$y+1] - 2*$gray[$x,$y+1] - $gray[$x+1,$y+1]
            $mag = [math]::Abs($gx) + [math]::Abs($gy)
            if ($mag -gt $thresh) { $edges++ }
          }
        }
        $small.Dispose()
        return $edges
      } finally {
        $src.Dispose()
      }
    } catch {
      return $null
    }
  }

  function Invoke-OCR([string]$imagePath, [string]$outTxtPath) {
    $ocr = [pscustomobject]@{ available=$false; path=$null; engine='none'; chars=0; error=$null }
    try {
      $tess = $null
      $candidates = @(
        "$env:ProgramFiles\Tesseract-OCR\tesseract.exe",
        "C:\Program Files\Tesseract-OCR\tesseract.exe"
      )
      foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { $tess = $c; break }
      }
      if (-not $tess) {
        try {
          $cmd = (Get-Command tesseract.exe -ErrorAction Stop).Source
          if ($cmd) { $tess = $cmd }
        } catch { }
      }
      if ($tess) {
        $base = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($outTxtPath), [System.IO.Path]::GetFileNameWithoutExtension($outTxtPath))
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $tess
        $psi.Arguments = "`"$imagePath`" `"$base`" -l eng"
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.UseShellExecute = $false
        $p = [System.Diagnostics.Process]::Start($psi)
        $p.WaitForExit(20000) | Out-Null
        if (Test-Path ($base + '.txt')) {
          $txtPath = $base + '.txt'
          $text = Get-Content -LiteralPath $txtPath -Raw -ErrorAction SilentlyContinue
          $ocr.available = $true
          $ocr.path = $txtPath
          $ocr.engine = 'tesseract'
          $ocr.chars = ($text | ForEach-Object { $_ }).Length
          return $ocr
        }
      } else {
        # Tentativa Windows.Media.Ocr (pode falhar silenciosamente em alguns ambientes)
        try {
          $null = [Windows.Media.Ocr.OcrEngine] # força carga de tipo WinRT
          $ocr.available = $true
          $ocr.engine = 'winrt-ocr'
          # Implementação WinRT completa é complexa; sinaliza disponibilidade mas sem extração se indisponível
          $ocr.available = $false
          $ocr.engine = 'none'
        } catch {
          $ocr.available = $false
          $ocr.engine = 'none'
        }
      }
    } catch {
      $ocr.error = $_.Exception.Message
    }
    return $ocr
  }

  function Get-LoopP95 {
    try {
      if ($Telemetry.Count -lt 5) { return $null }
      $arr = $Telemetry.ToArray()
      [Array]::Sort($arr)
      $idx = [int][Math]::Ceiling($arr.Length * 0.95) - 1
      if ($idx -lt 0) { $idx = 0 }
      return [math]::Round($arr[$idx],2)
    } catch { return $null }
  }

  # --- Loop principal ---
  Write-Host "[$AgentName] Iniciando escuta ativa (PollMs=$PollMs). Session=$SessionId"
  Write-TeiaLog "Iniciado. Versão=0.1; Session=$SessionId"
  $prevHandle = [IntPtr]::Zero
  $prevLDown = $false
  $lastEventAt = Get-Date

  try {
    while ($true) {
      $loopStart = Get-Date
      Rotate-Log

      $fg = Get-ForegroundInfo
      $currHandle = if ($fg) { $fg.Handle } else { [IntPtr]::Zero }

      # Detecção de clique esquerdo (borda de subida)
      $lState = ([Win32.Native]::GetAsyncKeyState(0x01) -band 0x8000) -ne 0
      $clickEdge = ($lState -and -not $prevLDown)
      $prevLDown = $lState

      $focusChanged = ($currHandle -ne $prevHandle -and $currHandle -ne [IntPtr]::Zero)
      $shouldCapture = $false
      $eventType = $null

      if ($focusChanged) { $shouldCapture = $true; $eventType = 'focus_change' }
      elseif ($clickEdge -and $currHandle -ne [IntPtr]::Zero) { $shouldCapture = $true; $eventType = 'click' }

      if ($shouldCapture -and $fg -ne $null) {
        $prevHandle = $currHandle
        $ts = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
        $fileBase = "evt_${ts}_$($fg.HandleHex)"
        $pngPath = Join-Path $ShotsDir ($fileBase + '.png')

        $ok = $false
        try { $ok = Capture-WindowImage -hWnd $fg.Handle -rect $fg.Rect -destPng $pngPath } catch { $ok = $false }
        if (-not $ok) {
          Write-TeiaLog "Falha na captura da janela: $($fg.HandleHex)"
          Start-Sleep -Milliseconds $PollMs
          continue
        }

        $sha = Get-FileSha256 -path $pngPath
        $ocrTxt = Join-Path $ShotsDir ($fileBase + '_ocr.txt')
        $ocrRes = Invoke-OCR -imagePath $pngPath -outTxtPath $ocrTxt

        $avg = Get-AvgColorHex -imagePath $pngPath
        $edges = Get-EdgeCount -imagePath $pngPath

        $charCount = if ($ocrRes -and $ocrRes.available -and $ocrRes.path) {
          try { ((Get-Content -LiteralPath $ocrRes.path -Raw) | ForEach-Object { $_ }).Length } catch { 0 }
        } else { 0 }
        $area = [math]::Max(1, $fg.Width * $fg.Height)
        $textRatio = [math]::Min(1.0, [math]::Round(($charCount / ($area / 100.0)), 4))

        $evt = [pscustomobject]@{
          teia_version   = '0.1'
          teia_signature = 'teia.window.listener'
          agent          = $AgentName
          session_id     = $SessionId
          event_id       = ([guid]::NewGuid().ToString())
          event_type     = $eventType
          timestamp      = (Get-Date -Format o)
          window_id      = $fg.HandleHex
          title          = $fg.Title
          process_name   = $fg.ProcessName
          rect           = $fg.Rect
          width          = $fg.Width
          height         = $fg.Height
          aspect_ratio   = $fg.Aspect
          screenshot     = [IO.Path]::GetRelativePath($BaseDir, $pngPath)
          sha256         = $sha
          ocr_available  = [bool]($ocrRes -and $ocrRes.available)
          ocr_engine     = if ($ocrRes) { $ocrRes.engine } else { 'none' }
          ocr_text_path  = if ($ocrRes -and $ocrRes.path) { [IO.Path]::GetRelativePath($BaseDir, $ocrRes.path) } else { $null }
          cv_features    = @{
            edges_count       = $edges
            average_color_rgb = if ($avg) { $avg.rgb } else { $null }
            average_color_hex = if ($avg) { $avg.hex } else { $null }
            text_area_ratio   = $textRatio
          }
          timings_ms     = @{
            loop_last = $null
            loop_p95  = $null
          }
          environment    = @{
            os_version  = [System.Environment]::OSVersion.VersionString
            ps_version  = $PSVersionTable.PSVersion.ToString()
          }
        }

        # Telemetria
        $loopEnd = Get-Date
        $dur = ($loopEnd - $loopStart).TotalMilliseconds
        $Telemetry.Add([double]$dur)
        while ($Telemetry.Count -gt 100) { $Telemetry.RemoveAt(0) }
        $evt.timings_ms.loop_last = [math]::Round($dur,2)
        $evt.timings_ms.loop_p95  = Get-LoopP95

        # Persistência
        $json = $evt | ConvertTo-Json -Depth 8 -Compress
        Add-Content -LiteralPath $LogFile -Value $json -Encoding UTF8
        Set-Content -LiteralPath $OutboxFile -Value $json -Encoding UTF8

        # Núcleo fractal: manifest mínimo
        try {
          $man = [pscustomobject]@{
            event_id   = $evt.event_id
            ts         = $evt.timestamp
            screenshot = $evt.screenshot
            sha256     = $evt.sha256
            process    = $evt.process_name
            title      = $evt.title
          }
          $manPath = Join-Path $CoreDir ("manifest_${ts}_$($fg.HandleHex).json")
          Set-Content -LiteralPath $manPath -Value ($man | ConvertTo-Json -Depth 6 -Compress) -Encoding UTF8
        } catch {
          Write-TeiaLog "Falha ao salvar manifest: $($_.Exception.Message)"
        }

        # Console/stdout para integração em pipelines
        Write-Output $json

        # GC leve e housekeeping
        Enforce-ScreenshotLimit -keep $ScreenshotLimit
      }

      $prevHandle = $currHandle
      $lastEventAt = Get-Date
      Start-Sleep -Milliseconds $PollMs
    }
  } catch {
    Write-TeiaLog "Erro fatal: $($_.Exception.Message)"
    throw
  }
  '@ -Encoding UTF8

  # 2) Execução do script gerado
  PowerShell -NoProfile -ExecutionPolicy Bypass -File .\TEIA-Window-Listener.ps1

  # Executar: PowerShell -NoProfile -ExecutionPolicy Bypass -File .\TEIA-Window-Listener.ps1
  # Requisitos: PowerShell 7+, (opcional) Tesseract em C:\Program Files\Tesseract-OCR
  # Parar: Ctrl+C no terminal ou Stop-Process -Name pwsh -Force
  # Logs: .teia_window_events.log | Screenshots: .teia_screenshots

---

### USUÁRIO

• Ran
  └ pwsh -NoProfile -Command '$target = '"'D:\\Scripts\\Set-TEIA-Workspace.ps1';
    "'$new = @'"'
    # Set-TEIA-Workspace.ps1
    param(
      [string]"'$LayoutFile = "D:'"\\Scripts\\Layouts\\CurrentLayout.json\",
      [int]"'$Tolerance = 1,
      [int]$MaxRetries = 10
    )

    # ----- Auto-elevação (preserva parâmetros) -----
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
      ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
      $elevArgs = @('"'-NoProfile','-ExecutionPolicy','Bypass','-File',\""'`"$PSCommandPath`"")
      $PSBoundParameters.GetEnumerator() | ForEach-Object { $elevArgs += "-$($_.Key)"; $elevArgs += "`"$($_.Value)`"" }
      Start-Process -FilePath '"'powershell.exe' -ArgumentList "'$elevArgs -Verb RunAs
      exit
    }

    # ----- DPI: Per-Monitor Aware V2 -----
    Add-Type -Name Dpi -Namespace W32 -MemberDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public static class DPI {
      [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);
    }
    "@
    [void][W32.DPI]::SetThreadDpiAwarenessContext([intptr](-4))

    # ----- Win32 interop (tipos e funções necessárias) -----
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    namespace W32 {
      [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
      public static class U32 {
        [DllImport("user32.dll", SetLastError=true)] public static extern bool MoveWindow(IntPtr hWnd,int X,int Y,int W,int H,bool repaint);
        [DllImport("user32.dll", SetLastError=true)] public static extern bool ShowWindow(IntPtr hWnd,int cmd);
        [DllImport("user32.dll", SetLastError=true)] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll", SetLastError=true)] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
        [DllImport("user32.dll", SetLastError=true)] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
      }
      public static class Dwm {
        [DllImport("dwmapi.dll", PreserveSig=true)] public static extern int DwmGetWindowAttribute(IntPtr hwnd,int attr,out RECT pv,int cb);
        public const int DWMWA_EXTENDED_FRAME_BOUNDS = 9;
      }
    }
    "@

    Add-Type -AssemblyName System.Windows.Forms
    $work = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

    # ----- Helpers (PowerShell wrappers) -----
    function Get-ExtRect {
      param([IntPtr]$h)
      try {
        if ($h -eq [IntPtr]::Zero) { return $null }
        $r = New-Object W32.RECT
        $hr = [W32.Dwm]::DwmGetWindowAttribute($h,[W32.Dwm]::DWMWA_EXTENDED_FRAME_BOUNDS,[ref]$r,[Runtime.InteropServices.Marshal]::SizeOf([type]'"'W32.RECT'))
        if ("'$hr -ne 0) {
          $ok = [W32.U32]::GetWindowRect($h,[ref]$r)
          if (-not $ok) { return $null }
        }
        return [pscustomobject]@{ L=$r.Left; T=$r.Top; R=$r.Right; B=$r.Bottom; W=$r.Right-$r.Left; H=$r.Bottom-$r.Top }
      } catch {
        Write-Warning ("Get-ExtRect falhou: {0}" -f $_.Exception.Message)
        return $null
      }
    }

    function MoveRaw {
      param([IntPtr]$h, [hashtable]$R)
      try {
        if ($h -eq [IntPtr]::Zero) { return $false }
        [void][W32.U32]::ShowWindow($h,9)
        [void][W32.U32]::SetForegroundWindow($h)
        [void][W32.U32]::MoveWindow($h,[int]$R.X,[int]$R.Y,[int]$R.W,[int]$R.H,$true)
        return $true
      } catch {
        Write-Warning ("MoveRaw falhou: {0}" -f $_.Exception.Message)
        return $false
      }
    }

    function Wait-Main {
      param([System.Diagnostics.Process]$p,[int]$ms=60000)
      if (-not $p) { return [IntPtr]::Zero }
      try {
        $sw=[Diagnostics.Stopwatch]::StartNew(); $p.Refresh()
        while($p.MainWindowHandle -eq [IntPtr]::Zero -and $sw.ElapsedMilliseconds -lt $ms){ Start-Sleep -Milliseconds 80; $p.Refresh() }
        return $p.MainWindowHandle
      } catch {
        Write-Warning ("Wait-Main falhou: {0}" -f $_.Exception.Message)
        return [IntPtr]::Zero
      }
    }

    function Get-WindowProcessId {
      param([IntPtr]$h)
      try {
        if ($h -eq [IntPtr]::Zero) { return 0 }
        $procId = [uint32]0
        [void][W32.U32]::GetWindowThreadProcessId($h, [ref]$procId)
        return [int]$procId
      } catch {
        Write-Warning ("GetWindowThreadProcessId falhou: {0}" -f $_.Exception.Message)
        return 0
      }
    }

    function Start-Or-Find {
      param([string]$title, [string]$dir)
      $p = Get-Process pwsh,powershell -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq $title } | Select-Object -First 1
      if ($p) { return $p }
      if (-not (Test-Path -LiteralPath $dir -PathType Container)) { $dir = '"'C:\\' }
      "'$cmd = "`$host.UI.RawUI.WindowTitle = '"'"'$title'"'; try{ Set-Location -LiteralPath '"'$dir'"' } catch {} ; cd\"
      return Start-Process -FilePath 'pwsh.exe' -Verb RunAs -WindowStyle Normal -ArgumentList @('-NoExit','-NoProfile','-Command',"'$cmd) -PassThru
    }

    function Ensure-Chrome {
      try {
        $p = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle } | Select-Object -First 1
        if ($p) { return $p }
        $exe = "${env:ProgramFiles}'"\\Google\\Chrome\\Application\\chrome.exe\"; if (-not (Test-Path "'$exe)) { $exe = '"'chrome.exe' }
        return Start-Process -FilePath "'$exe -ArgumentList @('"'--new-window','https://chat.openai.com/') -WindowStyle Normal -PassThru
      } catch {
        Write-Warning (\"Ensure-Chrome falhou: {0}\" -f "'$_.Exception.Message)
        return $null
      }
    }

    function Magnetize-To {
      param([System.Diagnostics.Process]$p, [hashtable]$t, [int]$tol, [int]$max)
      for ($i=0; $i -lt $max; $i++) {
        $m = Get-ExtRect $h
        if (-not $m) { break }
        $dL = $t.X_Abs - $m.L; $dT = $t.Y_Abs - $m.T
        $dR = ($t.X_Abs + $t.W) - $m.R; $dB = ($t.Y_Abs + $t.H) - $m.B
      }
    }

    # ----- Carregamento do layout -----
    if (-not (Test-Path -LiteralPath $LayoutFile)) { Write-Error "Layout não encontrado: $LayoutFile"; exit 1 }
    } catch {
      Write-Error "Falha ao ler/parsear layout JSON: $($_.Exception.Message)"; exit 1
    }

    # Identifica nós (ex: chrome, PWS-Topo, PWS-Base)
    $chromeNode = $layout.nodes.chrome
    $topoNode   = $layout.nodes.'"'PWS-Topo'
    "'$baseNode   = $layout.nodes.'"'PWS-Base'

    if (-not "'$chromeNode -or -not $topoNode -or -not $baseNode) {
      Write-Error "Nós chrome, PWS-Topo e PWS-Base não encontrados no JSON"; exit 1
    }

    $ChromeRect = @{ X_Abs = ($chromeNode.Rect.X + $work.Left); Y_Abs = ($chromeNode.Rect.Y + $work.Top); W = $chromeNode.Rect.W; H = $chromeNode.Rect.H }
    $TopoRect   = @{ X_Abs = ($topoNode.Rect.X + $work.Left); Y_Abs = ($topoNode.Rect.Y + $work.Top); W = $topoNode.Rect.W; H = $topoNode.Rect.H }
    $BaseRect   = @{ X_Abs = ($baseNode.Rect.X + $work.Left); Y_Abs = ($baseNode.Rect.Y + $work.Top); W = $baseNode.Rect.W; H = $baseNode.Rect.H }

    # ----- Abrir/processos e aplicar layout -----
    $chrome = Ensure-Chrome
    $pwTop  = Start-Or-Find '"'PWS-Topo'  'C:\\'
    "'$pwBase = Start-Or-Find '"'PWS-Base' 'D:\\TEIA\\TEIA_NUCLEO\\offline\\nano'

    if ("'$chrome) { Magnetize-To $chrome $ChromeRect $Tolerance $MaxRetries }
    if ($pwTop)  { Magnetize-To $pwTop  $TopoRect   $Tolerance $MaxRetries }
    if ($pwBase) { Magnetize-To $pwBase $BaseRect   $Tolerance $MaxRetries }

    Write-Host "Layout restaurado de: $LayoutFile"
    '"'@;
    Set-Content -LiteralPath "'$target -Value $new -Encoding UTF8;
    # re-run parse test
    $code = Get-Content -LiteralPath $target -Raw; try { [scriptblock]::Create($code) > $null; Write-Host '"'Parse OK after fix' } catch { Write-Error \"Erro de parsing ap\\u00f3s fix: "'$($_.Exception.Message)" }'

• Ran
  └ pwsh -NoProfile -Command '$target = '"'D:\\Scripts\\Set-TEIA-Workspace.ps1'; "'$raw = Get-Content -LiteralPath $target -Raw;
    "Counts => $pid: " + ([regex]::Matches($raw,'"'(?i)\\"'$pid'"\\b').Count) + \", GetWindowThreadProcessId: \" + ([regex]::Matches("'$raw,'"'GetWindowThreadProcessId').Count)"
    ParserError:
    Line |
       2 |  "Counts => $pid: " + ([regex]::Matches($raw,'(?i)\$pid\b').Count) + " .
         |             ~~~~~
         | Variable reference is not valid. ':' was not followed by a valid variable name character. Consider using ${} to delimit the name.

• Ran
  └ pwsh -NoProfile -Command '$target = '"'D:\\Scripts\\Set-TEIA-Workspace.ps1'; "'$raw = Get-Content -LiteralPath $target -Raw; $pidCount = ([regex]::Matches($raw,'"'(?i)\\"'$pid'"\\b').Count); "'$gwtpiCount =
        ([regex]::Matches($raw,'"'GetWindowThreadProcessId').Count); Write-Host \"pidCount="'$pidCount gwtpiCount=$gwtpiCount"'

• Ran
  └ pwsh -NoProfile -Command '$target = '"'D:\\Scripts\\Set-TEIA-Workspace.ps1'; if (Test-Path -LiteralPath "'$target) { $raw = Get-Content -LiteralPath $target -Raw; $pidCount = ([regex]::Matches($raw,'"'(?i)\\"'$pid'"\\b').Count);
        "'$gwtpiCount = ([regex]::Matches($raw,'"'GetWindowThreadProcessId').Count); \"pidCount="'$pidCount gwtpiCount=$gwtpiCount" } else { '"'FILE_NOT_FOUND' }"
    ParserError:
    Line |
       1 |  . Id').Count); \"pidCount="'$pidCount gwtpiCount=$gwtpiCount" } else {  .
         |                                                                ~
         | Unexpected token '}' in expression or statement.

• Ran pwsh -NoProfile -Command '$raw = Get-Content -LiteralPath '"'D:\\Scripts\\Set-TEIA-Workspace.ps1' -Raw; ([regex]::Matches("'$raw,'"'(?i)\\"'$pid'"\\b').Count); ([regex]::Matches("'$raw,'"'GetWindowThreadProcessId').Count);"

> Here’s what I did and what I found.

  - Verified file and backups: File exists; two recent backups listed.
  - Tail/contents: Last 60 lines printed; file not truncated.
  - Counts: $pid = 0, GetWindowThreadProcessId = 3.
  - Parse check: Initially failed due to a quoting error in Get-ExtRect (SizeOf([type]W32.RECT) missing quotes and duplicated/misaligned lines). I rewrote the script safely with a single‑quoted here‑string and fixed the function. Parse
  OK after fix.
  - Minimal window test: Opened 1 Chrome and 2 pwsh windows. Handles result:
      - ChromeHandle = 0 (Chrome started but no main window detected within 8s)
      - PWTopHandle = non‑zero
      - PWBaseHandle = non‑zero

  What I changed just now

  - Fixed Get-ExtRect: Corrected SizeOf([type]'W32.RECT'), removed stray/duplicated lines, ensured balanced braces, and added try/catch logging.
  - Rewrote the file atomically in UTF‑8 using a single‑quoted here‑string to avoid quoting corruption.

  What to do next

  - Run the main script elevated to apply layout: pwsh -NoProfile -ExecutionPolicy Bypass -File 'D:\Scripts\Set-TEIA-Workspace.ps1' -Verbose
  - If Chrome still shows handle = 0, it may need a longer wait or a direct URL launch. I can update Ensure-Chrome to:
      - Try both ProgramFiles and ProgramFiles(x86)
      - Fallback to Start-Process 'https://chat.openai.com'
      - Increase initial wait before probing handles

  If you want, I’ll apply that Ensure-Chrome tweak and extend the Wait-Main timeout to 10–15s


---

### ASSISTENTE

Perfeito — já fiz a análise e vou **aplicar a correção prática** sugerida: aumentar o wait para detecção de janela do Chrome e melhorar `Ensure-Chrome` com tentativas em `ProgramFiles` / `ProgramFiles(x86)` e fallback para abrir a URL padrão. Vou entregar **um único bloco PowerShell seguro** (backup + gravação UTF-8 + verificação) que você cola e executa como Administrador. Depois de rodar, o bloco também executa um teste mínimo (abre Chrome + 2 pwsh) e retorna os handles — assim confirmamos se o Chrome passa a ter `MainWindowHandle` detectável.

Cole tudo abaixo em um PowerShell **executado como Administrador** e rode. Não edite — é um único paste.

```powershell
# --- Atualiza Set-TEIA-Workspace.ps1 com Ensure-Chrome melhorado + waits maiores ---
$ErrorActionPreference = 'Stop'
$target = 'D:\Scripts\Set-TEIA-Workspace.ps1'
$backupDir = 'D:\Scripts\backups'
If (-not (Test-Path -LiteralPath $backupDir)) { New-Item -Path $backupDir -ItemType Directory | Out-Null }
If (Test-Path -LiteralPath $target) {
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  Copy-Item -LiteralPath $target -Destination (Join-Path $backupDir ("Set-TEIA-Workspace_$ts.ps1")) -Force
  Write-Host "Backup criado em $backupDir\Set-TEIA-Workspace_$ts.ps1"
} else {
  Write-Host "Aviso: arquivo alvo não existia, será criado: $target"
}

$body = @'
# Set-TEIA-Workspace.ps1
param(
  [string]$LayoutFile = "D:\Scripts\Layouts\CurrentLayout.json",
  [int]$Tolerance = 1,
  [int]$MaxRetries = 10,
  [int]$WaitMainMs = 15000   # tempo de espera padrão para detectar MainWindow (ms) — aumentado para Chrome
)

# ----- Auto-elevação (preserva parâmetros) -----
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  $elevArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSCommandPath")
  $PSBoundParameters.GetEnumerator() | ForEach-Object { $elevArgs += "-$($_.Key)"; $elevArgs += "$($_.Value)" }
  Start-Process -FilePath 'powershell.exe' -ArgumentList $elevArgs -Verb RunAs
  exit
}

# ----- DPI: Per-Monitor Aware V2 (silently try) -----
Add-Type -Name Dpi -Namespace W32 -MemberDefinition @"
using System;
using System.Runtime.InteropServices;
public static class DPI {
  [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);
}
"@ -ErrorAction SilentlyContinue
try { [void][W32.DPI]::SetThreadDpiAwarenessContext([intptr](-4)) } catch {}

# ----- Win32 interop (tipos e funções necessárias) -----
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace W32 {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
  public static class U32 {
    [DllImport("user32.dll", SetLastError=true)] public static extern bool MoveWindow(IntPtr hWnd,int X,int Y,int W,int H,bool repaint);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool ShowWindow(IntPtr hWnd,int cmd);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
    [DllImport("user32.dll", SetLastError=true)] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
  }
  public static class Dwm {
    [DllImport("dwmapi.dll", PreserveSig=true)] public static extern int DwmGetWindowAttribute(IntPtr hwnd,int attr,out RECT pv,int cb);
    public const int DWMWA_EXTENDED_FRAME_BOUNDS = 9;
  }
}
"@ -ErrorAction Stop

Add-Type -AssemblyName System.Windows.Forms
$work = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

# ----- Helpers (PowerShell wrappers) -----
function Get-ExtRect {
  param([IntPtr]$h)
  try {
    if ($h -eq [IntPtr]::Zero) { return $null }
    $r = New-Object W32.RECT
    $hr = [W32.Dwm]::DwmGetWindowAttribute($h,[W32.Dwm]::DWMWA_EXTENDED_FRAME_BOUNDS,[ref]$r,[Runtime.InteropServices.Marshal]::SizeOf([type]W32.RECT))
    if ($hr -ne 0) {
      $ok = [W32.U32]::GetWindowRect($h,[ref]$r)
      if (-not $ok) { return $null }
    }
    return [pscustomobject]@{ L=$r.Left; T=$r.Top; R=$r.Right; B=$r.Bottom; W=$r.Right-$r.Left; H=$r.Bottom-$r.Top }
  } catch {
    Write-Warning ("Get-ExtRect falhou: {0}" -f $_.Exception.Message)
    return $null
  }
}

function MoveRaw {
  param([IntPtr]$h, [hashtable]$R)
  try {
    if ($h -eq [IntPtr]::Zero) { return $false }
    [void][W32.U32]::ShowWindow($h,9)
    [void][W32.U32]::SetForegroundWindow($h)
    [void][W32.U32]::MoveWindow($h,[int]$R.X,[int]$R.Y,[int]$R.W,[int]$R.H,$true)
    return $true
  } catch {
    Write-Warning ("MoveRaw falhou: {0}" -f $_.Exception.Message)
    return $false
  }
}

function Wait-Main {
  param([System.Diagnostics.Process]$p,[int]$ms = 60000)
  if (-not $p) { return [IntPtr]::Zero }
  try {
    $sw=[Diagnostics.Stopwatch]::StartNew(); $p.Refresh()
    while($p.MainWindowHandle -eq [IntPtr]::Zero -and $sw.ElapsedMilliseconds -lt $ms){ Start-Sleep -Milliseconds 120; $p.Refresh() }
    return $p.MainWindowHandle
  } catch {
    Write-Warning ("Wait-Main falhou: {0}" -f $_.Exception.Message)
    return [IntPtr]::Zero
  }
}

function Get-WindowProcessId {
  param([IntPtr]$h)
  try {
    if ($h -eq [IntPtr]::Zero) { return 0 }
    $procId = [uint32]0
    [void][W32.U32]::GetWindowThreadProcessId($h, [ref]$procId)
    return [int]$procId
  } catch {
    Write-Warning ("GetWindowThreadProcessId falhou: {0}" -f $_.Exception.Message)
    return 0
  }
}

function Start-Or-Find {
  param([string]$title, [string]$dir)
  $p = Get-Process pwsh,powershell -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq $title } | Select-Object -First 1
  if ($p) { return $p }
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) { $dir = 'C:\' }
  $cmd = "`$host.UI.RawUI.WindowTitle = '$title'; try{ Set-Location -LiteralPath '$dir' } catch {} ; Start-Sleep -Seconds 600"
  return Start-Process -FilePath 'pwsh.exe' -ArgumentList @('-NoExit','-NoProfile','-Command',$cmd) -PassThru
}

# Improved Ensure-Chrome: try ProgramFiles, ProgramFiles(x86), then fallback to default start
function Ensure-Chrome {
  param([int]$initialWaitMs = 1500, [int]$probeMs = 15000)
  try {
    $p = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if ($p) { return $p }
    $candidates = @(
      (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
      (Join-Path $env:ProgramFiles(x86) 'Google\Chrome\Application\chrome.exe')
    )
    foreach ($exe in $candidates) {
      if (Test-Path $exe) {
        $proc = Start-Process -FilePath $exe -ArgumentList '--new-window','https://chat.openai.com/' -PassThru
        Start-Sleep -Milliseconds $initialWaitMs
        # wait for a MainWindowHandle on any chrome process up to probeMs
        $end = (Get-Date).AddMilliseconds($probeMs)
        while ((Get-Date) -lt $end) {
          $procList = Get-Process chrome -ErrorAction SilentlyContinue
          $found = $procList | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
          if ($found) { return $found }
          Start-Sleep -Milliseconds 200
        }
        # if we reach here, attempt next candidate
      }
    }
    # fallback: try Start-Process with URL (uses default browser)
    $procFb = Start-Process -FilePath 'cmd' -ArgumentList '/c','start','https://chat.openai.com/' -PassThru
    Start-Sleep -Milliseconds 800
    # try to find any chrome process with a handle
    $end2 = (Get-Date).AddMilliseconds($probeMs)
    while ((Get-Date) -lt $end2) {
      $found2 = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
      if ($found2) { return $found2 }
      Start-Sleep -Milliseconds 200
    }
    Write-Warning "Ensure-Chrome: não conseguiu detectar Chrome com MainWindowHandle dentro do tempo."
    return $null
  } catch {
    Write-Warning ("Ensure-Chrome falhou: {0}" -f $_.Exception.Message)
    return $null
  }
}

function Magnetize-To {
  param([System.Diagnostics.Process]$p, [hashtable]$t, [int]$tol, [int]$max, [int]$waitMainMs)
  $h = Wait-Main $p $waitMainMs
  if ($h -eq [IntPtr]::Zero) { Write-Warning "Janela não encontrada para processo: $($p.ProcessName)"; return }
  $r = @{ X=[int]$t.X_Abs; Y=[int]$t.Y_Abs; W=[int]$t.W; H=[int]$t.H }
  MoveRaw $h $r; Start-Sleep -Milliseconds 120
  for ($i=0; $i -lt $max; $i++) {
    $m = Get-ExtRect $h
    if (-not $m) { break }
    $dL = $t.X_Abs - $m.L; $dT = $t.Y_Abs - $m.T
    $dR = ($t.X_Abs + $t.W) - $m.R; $dB = ($t.Y_Abs + $t.H) - $m.B
    $delta = [math]::Max([math]::Abs($dL), [math]::Abs($dT), [math]::Abs($dR), [math]::Abs($dB))
    if ($delta -le $tol) { break }
    $r.X += $dL; $r.Y += $dT
    $newW = $r.W + ($dR - $dL); if ($newW -lt 50) { $newW = 50 }
    $newH = $r.H + ($dB - $dT); if ($newH -lt 50) { $newH = 50 }
    $r.W = $newW; $r.H = $newH
    MoveRaw $h $r
    Start-Sleep -Milliseconds 80
  }
}

# ----- Carregamento do layout e cálculo de posições -----
if (-not (Test-Path -LiteralPath $LayoutFile)) { Write-Error "Layout não encontrado: $LayoutFile"; exit 1 }
try {
  $layout = Get-Content -LiteralPath $LayoutFile -Raw | ConvertFrom-Json
} catch {
  Write-Error "Falha ao ler/parsear layout JSON: $($_.Exception.Message)"; exit 1
}

# Nós esperados no JSON
$chromeNode = $layout.nodes.chrome
$topoNode   = $layout.nodes.'PWS-Topo'
$baseNode   = $layout.nodes.'PWS-Base'

if (-not $chromeNode -or -not $topoNode -or -not $baseNode) {
  Write-Error "Nós chrome, PWS-Topo e PWS-Base não encontrados no JSON"; exit 1
}

$ChromeRect = @{ X_Abs = ($chromeNode.Rect.X + $work.Left); Y_Abs = ($chromeNode.Rect.Y + $work.Top); W = $chromeNode.Rect.W; H = $chromeNode.Rect.H }
$TopoRect   = @{ X_Abs = ($topoNode.Rect.X + $work.Left);   Y_Abs = ($topoNode.Rect.Y + $work.Top);   W = $topoNode.Rect.W;   H = $topoNode.Rect.H }
$BaseRect   = @{ X_Abs = ($baseNode.Rect.X + $work.Left);   Y_Abs = ($baseNode.Rect.Y + $work.Top);   W = $baseNode.Rect.W;   H = $baseNode.Rect.H }

# ----- Abrir/processos e aplicar layout -----
$chrome = Ensure-Chrome -initialWaitMs 1000 -probeMs $WaitMainMs
$pwTop  = Start-Or-Find 'PWS-Topo'  'C:\'
$pwBase = Start-Or-Find 'PWS-Base' 'D:\TEIA\TEIA_NUCLEO\offline\nano'

if ($chrome) { Magnetize-To $chrome $ChromeRect $Tolerance $MaxRetries $WaitMainMs }
if ($pwTop)  { Magnetize-To $pwTop  $TopoRect   $Tolerance $MaxRetries $WaitMainMs }
if ($pwBase) { Magnetize-To $pwBase $BaseRect   $Tolerance $MaxRetries $WaitMainMs }

Write-Host "Layout restaurado de: $LayoutFile"
'@

# grava o arquivo em UTF8
$body | Out-File -FilePath $target -Encoding utf8 -Force
Write-Host "Arquivo gravado em: $target"

# --- Verificações pós-gravação ---
# parse test
$code = Get-Content -LiteralPath $target -Raw
try { [scriptblock]::Create($code) > $null; Write-Host "Parse OK após gravação." } catch { Write-Error "Erro de parsing após gravação: $($_.Exception.Message)" }

# counts
$raw = $code
$pidCount = ([regex]::Matches($raw,'(?i)\$pid\b')).Count
$gwtpiCount = ([regex]::Matches($raw,'GetWindowThreadProcessId')).Count
Write-Host ("Counts => $pid: {0}   GetWindowThreadProcessId: {1}" -f $pidCount, $gwtpiCount)

# --- Teste mínimo: abre Chrome + 2 pwsh e reporta handles (não precisa ser admin) ---
Write-Host "`nIniciando teste mínimo: abrir Chrome + PWS-Topo + PWS-Base ..."
$chromeExe = (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe')
if (-not (Test-Path $chromeExe)) { $chromeExe = (Join-Path $env:ProgramFiles(x86) 'Google\Chrome\Application\chrome.exe') }
if (-not (Test-Path $chromeExe)) { $chromeExe = 'chrome.exe' }

try {
  $chromeProc = Start-Process -FilePath $chromeExe -ArgumentList '--new-window','https://chat.openai.com/' -PassThru
} catch {
  Write-Warning "Falha ao Start-Process chrome.exe: $_.Exception.Message ; tentando start default URL"
  $chromeProc = Start-Process -FilePath 'cmd' -ArgumentList '/c','start','https://chat.openai.com/' -PassThru
}
Start-Sleep -Milliseconds 800

$pwTop = Start-Process -FilePath pwsh -ArgumentList '-NoExit','-Command',"`$host.UI.RawUI.WindowTitle = 'PWS-Topo'; Start-Sleep -Seconds 600" -PassThru
$pwBase = Start-Process -FilePath pwsh -ArgumentList '-NoExit','-Command',"`$host.UI.RawUI.WindowTitle = 'PWS-Base'; Start-Sleep -Seconds 600" -PassThru

# wait helper
$wait = { param($p, $ms) $end = (Get-Date).AddMilliseconds($ms); while((Get-Date) -lt $end) { $p.Refresh(); if ($p.MainWindowHandle -ne 0) { return $p.MainWindowHandle }; Start-Sleep -Milliseconds 120 }; return 0 }

$ch = & $wait $chromeProc $WaitMainMs
$th = & $wait $pwTop $WaitMainMs
$bh = & $wait $pwBase $WaitMainMs

[pscustomobject]@{
  ChromePID = $chromeProc.Id; ChromeHandle = $ch
  PWTopPID  = $pwTop.Id;  PWTopHandle  = $th
  PWBasePID = $pwBase.Id; PWBaseHandle  = $bh
}
```

### O que eu já corrigi / por que esse bloco
- Melhorei `Ensure-Chrome` para testar ambos `ProgramFiles` e `ProgramFiles(x86)` e tentar fallback com `start URL` (para abrir no navegador padrão).  
- Aumentei `WaitMainMs` (padrão 15000 ms) e usei esse valor para os `Wait-Main` no `Magnetize-To` (assim o Chrome tem mais tempo para criar a janela principal).  
- Mantive wrappers Win32, `GetWindowThreadProcessId` via `[ref]`, `MoveWindow`, e logs de fallback.  
- O bloco faz backup timestampado, grava em UTF-8 e executa um teste mínimo automático e imprime os handles.

---

### Próximos passos (após rodar)
1. Cole e rode o bloco acima (como Admin).  
2. Observe saída do teste mínimo (objeto com `ChromeHandle`, `PWTopHandle`, `PWBaseHandle`).  
   - Se `ChromeHandle` agora for **não-zero**, rode o script principal para aplicar o layout:  
     `pwsh -NoProfile -ExecutionPolicy Bypass -File 'D:\Scripts\Set-TEIA-Workspace.ps1' -Verbose`  
   - Se `ChromeHandle` continuar **zero**, cole o resultado aqui (a saída do objeto retornado) — eu analiso e aplico duas estratégias seguintes:  
     a) aumentar `WaitMainMs` para 30s e re-tentar, ou  
     b) passar a localizar a janela do Chrome por **título** (ex.: procurar `ChatGPT` / `Google Gemini` no `MainWindowTitle`) ou usar `UIAutomation` para forçar foco/restore (mais avançado).  

Se quiser, eu já gero outro bloco que **aumenta `WaitMainMs` para 30000** e adiciona uma tentativa extra para localizar janela por título — digo “gerar modo agressivo” e eu te entrego o bloco pronto.  

Quer que eu já rode a versão “agressiva” (30s + procura por título) ou prefere testar este primeiro?

---

### ASSISTENTE

Ótimo — você já criou o **TEIA-Window-Listener**. Primeiro ponto importante: **esse listener não abre janelas** — ele *escuta* mudanças de foco e cliques e **captura** quando o foco muda ou há clique (ele **não** é o Set-TEIA-Workspace que cria/posiciona Chrome + PWSh). Então, se você esperava que rodar o listener abrisse páginas/janelas, isso é por isso que “não abriu nada”.

Agora, vou te dar passos de diagnóstico rápidos, comandos copy→paste e explicações das causas mais prováveis para que ele não esteja capturando nada (ou pareça “inativo”).

---

## Verificações rápidas (cole e rode — não precisa ser Admin)

1) Confirmar que o listener está gravado e ver últimos arquivos de backup:
```powershell
Test-Path .\TEIA-Window-Listener.ps1
Get-ChildItem -Path .\TEIA-Window-Listener.ps1.bak_* -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 3
```

2) Verificar se o script está rodando (procure pwsh/powershell com a linha de comando apontando pro arquivo):
```powershell
Get-CimInstance Win32_Process -Filter "Name LIKE '%pwsh%' OR Name='powershell.exe'" |
  Where-Object { $_.CommandLine -and $_.CommandLine -match 'TEIA-Window-Listener.ps1' } |
  Select-Object ProcessId,CommandLine,CreationDate
```
Se não retornar nada, o script **não está em execução**.

3) Verificar logs / último evento / outbox / screenshots:
```powershell
# última linhas do log
if (Test-Path .\.teia_window_events.log) { Get-Content .\.teia_window_events.log -Tail 20 } else { Write-Host "Sem log (.teia_window_events.log)" }

# último outbox json
if (Test-Path .\.teia_outboxlast_event.json) { Get-Content .\.teia_outboxlast_event.json -Raw | ConvertFrom-Json | Format-List } else { Write-Host "Sem outbox (.teia_outboxlast_event.json)" }

# últimas screenshots (se houver)
if (Test-Path .\.teia_screenshots) { Get-ChildItem .\.teia_screenshots\*.png -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5 } else { Write-Host "Sem pasta .teia_screenshots" }
```

4) Teste rápido de captura manual (executa Get-ForegroundInfo e tenta capturar a janela em foco — cole e rode enquanto foca outras janelas):
```powershell
. .\TEIA-Window-Listener.ps1   # fonte do script na sessão atual (se houver funções exportadas)
# Caso não queira fonte, rode este snippet independente:
$fg = & { param() 
  Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
  Add-Type -Namespace Win32 -Name Native -MemberDefinition @"
  using System;
  using System.Runtime.InteropServices;
  using System.Text;
  public static class Native {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll", SetLastError=true)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll", SetLastError=true)] public static extern int GetWindowTextLength(IntPtr hWnd);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll", SetLastError=true)] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
  }
  "@
  function Get-FG {
    $h = [Win32.Native]::GetForegroundWindow(); if ($h -eq [IntPtr]::Zero) { return $null }
    $len = [Win32.Native]::GetWindowTextLength($h); $sb = New-Object System.Text.StringBuilder ($len+1)
    [void][Win32.Native]::GetWindowText($h,$sb,$sb.Capacity)
    $r = New-Object Win32.Native+RECT
    [void][Win32.Native]::GetWindowRect($h,[ref]$r)
    $pid=[uint32]0; [void][Win32.Native]::GetWindowThreadProcessId($h,[ref]$pid)
    [pscustomobject]@{ Handle=$h; Title=$sb.ToString(); PID=[int]$pid; Rect=$r }
  }
  Get-FG
}
$fg
```
Se o snippet mostrar um objeto com `Handle` e `Title`, a API Win32 está respondendo corretamente.

---

## Possíveis causas e como corrigi-las

1. **Você esperava que o listener abrisse janelas** — ele **não abre**. Use `Set-TEIA-Workspace.ps1` (ou Start-Process para chrome/pwsh) para criar/posicionar as janelas. O listener só *captura*.

2. **Script não está em execução** — verifique passo 2 acima. Para iniciar em uma janela separada e ver o console:
```powershell
Start-Process pwsh -ArgumentList '-NoExit','-ExecutionPolicy','Bypass','-File', (Resolve-Path .\TEIA-Window-Listener.ps1) -WindowStyle Normal -PassThru
```
Isso abre uma janela nova com o listener rodando visivelmente.

3. **Execução em sessão/elevação diferente (UAC)** — se você iniciou o listener elevado e as janelas alvo estão em outra integridade, PrintWindow/GetAsyncKeyState/CopyFromScreen podem falhar. Preferível rodar o listener **no mesmo nível de integridade** das janelas que você quer capturar (normalmente sem elevação).

4. **PrintWindow falha para algumas janelas (Chrome, apps GPU)** — seu script já tem fallback `CopyFromScreen`, o que ajuda; porém, se a janela estiver minimizada, offscreen, ou em outra workspace/desktop, não será capturada. Certifique-se de trazer a janela para frente (focus) e não minimizar.

5. **Permissões / Antivírus / Política de Grupo** — algumas corporações bloqueiam captura de tela programática. Se estiver em máquina corporativa, teste em máquina pessoal para isolar.

6. **Tesseract não instalado** — OCR simplesmente retorna indisponível; isso não impede captura de imagens. Verifique se precisa de OCR.

---

## O que fazer agora (recomendado)

1. Rode a verificação do item **(3) Teste rápido de captura manual** — foque uma janela (ex.: Chrome), clique nela e cole o snippet. Cole o objeto retornado aqui (Title, PID) se quiser que eu valide.  
2. Se quiser o listener exibindo o console para acompanhar em tempo real, execute:
```powershell
Start-Process pwsh -ArgumentList '-NoExit','-ExecutionPolicy','Bypass','-File', (Resolve-Path .\TEIA-Window-Listener.ps1) -WindowStyle Normal
```
3. Se o listener estiver rodando, mas não captura nada após você mudar foco/clicar, cole as últimas linhas do log:
```powershell
Get-Content .\.teia_window_events.log -Tail 40
```
4. Se quiser que o listener automaticamente inicie o `Set-TEIA-Workspace.ps1` para abrir as três janelas quando for iniciado, eu posso **adicionar** essa rotina (chamar Start-Process para abrir chrome + pwsh antes do loop) — digo como e já faço o patch.

---

Se você colar o resultado do **Teste mínimo** (o objeto retornado com Handle/Title/PID) ou o output das verificações (processos com CommandLine, últimos 20 linhas do log), eu analiso e dou a correção exata (por exemplo: ajustar Ensure-Chrome, aumentar timeouts, rodar sem elevação, ou integrar auto-start do Set-TEIA-Workspace). Quer que eu já faça a alteração para **iniciar automaticamente o Set-TEIA-Workspace** ao subir o listener?

---

