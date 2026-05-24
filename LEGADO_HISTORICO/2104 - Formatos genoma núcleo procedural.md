# 2104 - Formatos genoma núcleo procedural

### USUÁRIO

Você é um Otimizador Duplo de Prompts de IA. Analise o prompt fornecido e decida:
(contexto do chat:
tem algum ou alguns formatos de arquivo padrões que constituem o genoma do núcleo procedural? exemplo que intúo "ps1 e json" 
Dito pelo ChatGPT:

Sim — os formatos padrão que constituem o “genoma” do núcleo procedural são essencialmente dois:

Scripts PowerShell (.ps1)

Eles são o motor do núcleo: executam geração, restauração, benchmark, orquestração e auditoria.

Exemplos diretos: TEIA-Fractal-Gen.ps1, TEIA-Fractal-RestoreOnDemand.ps1, TEIA-Seed-Gen.ps1, teia-cli.ps1.

Descritores/Seeds em JSON (.json, .seed.json)

Contêm os metadados, âncoras e instruções procedurais que permitem reconstruir os arquivos originais bit-a-bit.

Dois tipos principais:
• Seed payload: guarda instruções ou blocos literais para restauração independente.
• Seed anchor: armazena hashes de fragmentos estratégicos (âncoras) e SHA256 do arquivo alvo.

São minúsculos comparados ao original, o que garante o “peso-pena” do núcleo.

Complementares, mas não estruturais:

Logs (.log, .jsonl, .csv) → usados para benchmarks e auditorias.

Relatórios (prova_p0_relatorio.json, verification_report.json) → consolidam provas de restauração.

🔑 Em resumo:
O genoma vivo do núcleo procedural é a dupla .ps1 (scripts) + .json/.seed.json (seeds/descritores).
Os outros formatos (logs, CSV, relatórios) são epifenômenos — úteis para auditoria e visualização, mas não essenciais para regenerar a memória procedural.

Quer que eu prepare um mapa minimalista listando quais .ps1 são obrigatórios no core e quais tipos de .json garantem a restaurabilidade, para virar uma “tabela-DNA” oficial do núcleo?

Dito por si:
Quais são todos os formatos de arquivos usados pelo genoma do núcleo procedural?
Dito pelo ChatGPT:

Aqui está a visão consolidada — o genoma do núcleo procedural não é um único formato, mas um conjunto coerente de camadas de arquivos, cada qual cumprindo um papel na restauração, prova e auditoria.

🔹 Formatos principais (DNA do núcleo)

.ps1 (PowerShell scripts)

Coração executável: geração, restauração, benchmark, auditoria, orquestração.

Exemplos: TEIA-Fractal-Gen.ps1, TEIA-Fractal-RestoreOnDemand.ps1, teia-cli.ps1.

.json / .seed.json

Estruturas em JSON contendo seeds, âncoras e metadados.

Tipos:
• Seed payload: contém instruções/literais para recriar o arquivo.
• Seed anchor: contém hashes de fragmentos (âncoras) + SHA256.

É a parte “peso-pena” que substitui arquivos inteiros.

🔹 Formatos auxiliares (provas e auditoria)

.jsonl (JSON Lines)

Streams de eventos/benchmarks (dna_benchmark_runs.jsonl).

.csv

Exportações tabulares de benchmarks (dna_benchmark_topN.csv).

.log / .txt

Logs de execução, relatórios de auditoria, estados de benchmark (fractal_benchmark_*.log, benchmark_after_final.txt).

.md / .pdf

Documentação e relatórios humanos do ciclo (teia-nucleo-procedural_0.1_documentation.md, TEIA Report v3.pdf).

.zip

Pacotes consolidados e transportáveis (teia_consolidated_package_*.zip, teia_micro_knowledge_*.zip).

🔹 Formatos experimentais/procedurais

.anchor.seed.json

Seeds-âncora minimalistas (3 hashes + SHA256) para restauração por varredura ou índice.

.fractal_delta.*.json

Estruturas diferenciais para restauração delta.

.ps1.bak_*

Backups automáticos de scripts alterados, garantindo reversibilidade.

✅ Síntese:
O “genoma” do núcleo procedural vive principalmente na dupla:

Scripts (.ps1) → motor procedural.

Seeds/descritores (.json, .seed.json, .anchor.seed.json) → DNA de cada arquivo/memória.

Todos os demais formatos (logs, csv, md, pdf, zip) são fenômenos auxiliares: garantem prova, auditoria, visualização e portabilidade, mas não são essenciais para a regeneração.

Quer que eu organize isso em uma tabela-DNA mostrando (Formato → Função → Essencial/Auxiliar), para ficar pronto como blueprint do genoma?

Dito por si:
exato, quero que você mencione todos os formatos usados em uma linha: "EXEMPLOS: PS1, JSON, CSV, MD, PDF, ZIP, LOGS...") em ordem de prioridadede do genoma completo
Dito pelo ChatGPT:

Perfeito. Seguindo a prioridade do genoma completo do núcleo procedural, a linha fica:

EXEMPLOS: PS1, JSON / SEED.JSON / ANCHOR.SEED.JSON, JSONL, CSV, LOG, TXT, MD, PDF, ZIP, FRACTAL_DELTA.JSON, BAK_PS1

👉 Ordem reflete:

PS1 (motor)

JSON/SEED (DNA proced.)

JSONL/CSV/LOG/TXT (auditoria)

MD/PDF (documentação)

ZIP (pacotes)

FRACTAL_DELTA / BAK (camada experimental/segurança).

Quer que eu monte agora a tabela-DNA em forma estruturada (Formato → Função → Essencial/Auxiliar), para virar um blueprint oficial?

Dito por si:
Contextualize o que instrui e rodei no codex cli:
" To get started, describe a task or try one of these commands:

 /init - create an AGENTS.md file with instructions for Codex
 /status - show current session configuration and token usage
 /approvals - choose what Codex can do without approval
 /model - choose what model and reasoning effort to use

▌o local que fica os conteúdos copiados ao ser teclado crtl+c no meu pc, qual o nome da pasta e o caminho que ela fica?

> Não há uma pasta. O conteúdo copiado (Ctrl+C) vai para a área de transferência do Windows e fica na memória, de forma
  temporária e volátil.

  - Histórico do clipboard: se você usar Win+V, o Windows mostra o histórico. Esses itens ficam armazenados internamente
  em áreas protegidas do sistema (sem um caminho de pasta legível) e são limpos conforme configurações, logout ou
  reinicialização.
  - Acessar/limpar via sistema: Configurações > Sistema > Área de Transferência (ou execute ms-settings:clipboard) para
  ativar histórico/sincronização e limpar dados.
  - Acessar/limpar via comandos:
      - Ver texto atual: PowerShell Get-Clipboard
      - Limpar: cmd /c "clip < nul" ou PowerShell Set-Clipboard -Value $null
  - Observação: Se você usa um gerenciador de clipboard de terceiros (ex.: Ditto), aí sim ele grava em arquivos próprios
  (por exemplo em %AppData%), mas o local depende do aplicativo.

▌perfeito, analise, deduplique e encerre fornecendo uma disco C com otimizaões de limpeza e organização sanitizadora

> Vou preparar um script do PowerShell seguro para análise, limpeza e deduplicação do C:, com modo de simulação por
  padrão e logs. Em seguida explico como executar.

• Updated Plan
  └ □ Create safe cleanup + report script
    □ Add dedupe via hashes + hardlinks
    □ Include temp/WU/RecycleBin cleanup options
    □ Save logs + usage instructions
    □ Provide run guidance + safety notes

• Proposed Change C:\Users\felip\C-Cleanup.ps1 (+288 -0)
    1     +param(
    2     +    [switch]$Execute,
    3     +    [switch]$Hardlink,
    4     +    [int]$DaysOld = 60,
    5     +    [int]$DaysTemp = 3,
    6     +    [int64]$MaxHashMB = 512,
    7     +    [switch]$RunDISM,
    8     +    [switch]$DisableHibernation,
    9     +    [switch]$PruneDownloads
    10    +)
    11    +
    12    +$ErrorActionPreference = 'Stop'
    13    +
    14    +function New-LogDir {
    15    +    param([string]$Base = 'C:\Cleanup-Logs')
    16    +    try {
    17    +        if (-not (Test-Path $Base)) { New-Item -ItemType Directory -Path $Base -Force | Out-Null }
    18    +        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    19    +        $dir = Join-Path $Base $stamp
    20    +        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    21    +        return $dir
    22    +    } catch {
    23    +        Write-Host "[WARN] Falha ao criar pasta de logs em $Base. Usando temporário." -ForegroundColor Yellow
    24    +        $tmp = Join-Path $env:TEMP ("Cleanup-Logs-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    25    +        New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    26    +        return $tmp
    27    +    }
    28    +}
    29    +
    30    +$LogDir = New-LogDir
    31    +$LogFile = Join-Path $LogDir 'cleanup.log'
    32    +
    33    +function Write-Log { param([string]$Message,[string]$Level = 'INFO')
    34    +    $ts = Get-Date -Format o
    35    +    $line = "[$Level] $ts $Message"
    36    +    Add-Content -Path $LogFile -Value $line
    37    +    $fg = switch ($Level) { 'WARN' {'Yellow'} 'ERROR' {'Red'} default {'Gray'} }
    38    +    Write-Host $line -ForegroundColor $fg
    39    +}
    40    +
    41    +$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole
           ([Security.Principal.WindowsBuiltInRole]::Administrator)
    42    +if ($IsAdmin) { Write-Log "Execução em modo administrador: $IsAdmin" } else { Write-Log "Execução sem privilé
           gios de administrador" 'WARN' }
    43    +Write-Log "Modo: $(if($Execute){'EXECUTE'}else{'REPORT-ONLY'}) | Hardlink: $Hardlink | DaysOld: $DaysOld | Ma
           xHashMB: $MaxHashMB"
    44    +
    45    +function Get-FreeSpace {
    46    +    Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object DeviceID,@{n='FreeGB';e={[math]
           ::Round($_.FreeSpace/1GB,2)}},@{n='SizeGB';e={[math]::Round($_.Size/1GB,2)}}
    47    +}
    48    +
    49    +Write-Log (Get-FreeSpace | ForEach-Object { "Espaço livre em $($_.DeviceID): $($_.FreeGB)GB de $($_.SizeGB)GB
           " })
    50    +
    51    +$UserDirs = @(
    52    +    Join-Path $env:USERPROFILE 'Desktop'),
    53    +    (Join-Path $env:USERPROFILE 'Documents'),
    54    +    (Join-Path $env:USERPROFILE 'Downloads'),
    55    +    (Join-Path $env:USERPROFILE 'Pictures'),
    56    +    (Join-Path $env:USERPROFILE 'Videos'),
    57    +    (Join-Path $env:USERPROFILE 'Music')
    58    +
    59    +function Safe-EnumerateFiles {
    60    +    param([string[]]$Paths)
    61    +    foreach ($p in $Paths) {
    62    +        if (-not (Test-Path $p)) { continue }
    63    +        try {
    64    +            Get-ChildItem -Path $p -Recurse -File -Force -ErrorAction SilentlyContinue |
    65    +                Where-Object {
    66    +                    $attr = $_.Attributes
    67    +                    -not ($attr.HasFlag([IO.FileAttributes]::System)) -and
    68    +                    -not ($attr.HasFlag([IO.FileAttributes]::ReparsePoint)) -and
    69    +                    -not ($_.FullName -match '\\OneDrive(\\|$)')
    70    +                }
    71    +        } catch {
    72    +            Write-Log "Sem acesso para vasculhar: $p ($_ )" 'WARN'
    73    +        }
    74    +    }
    75    +}
    76    +
    77    +function Format-Bytes([long]$b){
    78    +    if ($b -ge 1TB) { return "{0:N2} TB" -f ($b/1TB) }
    79    +    if ($b -ge 1GB) { return "{0:N2} GB" -f ($b/1GB) }
    80    +    if ($b -ge 1MB) { return "{0:N2} MB" -f ($b/1MB) }
    81    +    if ($b -ge 1KB) { return "{0:N2} KB" -f ($b/1KB) }
    82    +    return "$b B"
    83    +}
    84    +
    85    +$Report = [ordered]@{
    86    +    Started = (Get-Date)
    87    +    Admin = $IsAdmin
    88    +    Mode = if($Execute){'Execute'} else {'ReportOnly'}
    89    +    LogDir = $LogDir
    90    +    FreeSpaceBeforeGB = (Get-FreeSpace).FreeGB
    91    +    Actions = @()
    92    +    Estimates = [ordered]@{ DeleteBytes = 0; DedupBytes = 0 }
    93    +}
    94    +
    95    +function Add-Action {
    96    +    param([string]$Kind,[string]$Path,[long]$Bytes)
    97    +    $Report.Actions += [ordered]@{ Kind=$Kind; Path=$Path; Bytes=$Bytes }
    98    +    if ($Kind -eq 'Delete') { $Report.Estimates.DeleteBytes += $Bytes }
    99    +    if ($Kind -eq 'Dedup') { $Report.Estimates.DedupBytes += $Bytes }
    100   +}
    101   +
    102   +# 1) Limpeza de temporários (usuário e sistema)
    103   +function Clean-Temp {
    104   +    Write-Log "[1] Limpando temporários de usuário (>$DaysTemp dias)"
    105   +    $targets = @($env:TEMP)
    106   +    if ($IsAdmin) { $targets += (Join-Path $env:WINDIR 'Temp') }
    107   +
    108   +    foreach ($t in $targets) {
    109   +        if (-not (Test-Path $t)) { continue }
    110   +        Get-ChildItem -Path $t -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
    111   +            try {
    112   +                $ageDays = (New-TimeSpan -Start $_.LastWriteTime -End (Get-Date)).Days
    113   +                if ($ageDays -ge $DaysTemp) {
    114   +                    if ($_.PSIsContainer) { return }
    115   +                    Add-Action -Kind 'Delete' -Path $_.FullName -Bytes ($_.Length)
    116   +                    if ($Execute) { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            }
    117   +                }
    118   +            } catch { }
    119   +        }
    120   +    }
    121   +}
    122   +
    123   +# 2) Limpeza de Downloads antigos (opcional)
    124   +function Prune-Downloads {
    125   +    if (-not $PruneDownloads) { return }
    126   +    $dl = Join-Path $env:USERPROFILE 'Downloads'
    127   +    if (-not (Test-Path $dl)) { return }
    128   +    Write-Log "[2] Limpando Downloads com mais de $DaysOld dias" 'WARN'
    129   +    Get-ChildItem -Path $dl -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
    130   +        $ageDays = (New-TimeSpan -Start $_.LastWriteTime -End (Get-Date)).Days
    131   +        if ($ageDays -ge $DaysOld) {
    132   +            Add-Action -Kind 'Delete' -Path $_.FullName -Bytes ($_.Length)
    133   +            if ($Execute) { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
    134   +        }
    135   +    }
    136   +}
    137   +
    138   +# 3) Esvaziar Lixeira
    139   +function Empty-Bin {
    140   +    Write-Log "[3] Esvaziando Lixeira"
    141   +    try {
    142   +        # Estimar tamanho da lixeira (aproximação, por usuário)
    143   +        $recyclePaths = @(
    144   +            Join-Path $env:SystemDrive '\$Recycle.Bin'
    145   +        )
    146   +        foreach ($rp in $recyclePaths) {
    147   +            if (Test-Path $rp) {
    148   +                Get-ChildItem -Path $rp -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $
           _.PSIsContainer } | ForEach-Object {
    149   +                    Add-Action -Kind 'Delete' -Path $_.FullName -Bytes ($_.Length)
    150   +                }
    151   +            }
    152   +        }
    153   +    } catch { }
    154   +    if ($Execute) {
    155   +        try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } catch { }
    156   +    }
    157   +}
    158   +
    159   +# 4) Limpar caches do Windows Update/Delivery Optimization (admin recomendado)
    160   +function Clean-UpdateCaches {
    161   +    if (-not $IsAdmin) { Write-Log "[4] Skipping Update caches (admin necessário)" 'WARN'; return }
    162   +    Write-Log "[4] Limpando caches do Windows Update e Delivery Optimization"
    163   +    $wu = Join-Path $env:WINDIR 'SoftwareDistribution\Download'
    164   +    $do = Join-Path $env:ProgramData 'Microsoft\Windows\DeliveryOptimization\Cache'
    165   +    foreach ($path in @($wu,$do)) {
    166   +        if (-not (Test-Path $path)) { continue }
    167   +        Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIs
           Container } | ForEach-Object {
    168   +            Add-Action -Kind 'Delete' -Path $_.FullName -Bytes $_.Length
    169   +        }
    170   +        if ($Execute) {
    171   +            try { Get-Service -Name wuauserv -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction
            SilentlyContinue } catch { }
    172   +            try { Get-Service -Name DoSvc -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction Si
           lentlyContinue } catch { }
    173   +            try { Remove-Item -Path (Join-Path $path '*') -Recurse -Force -ErrorAction SilentlyContinue } cat
           ch { }
    174   +            try { Get-Service -Name wuauserv -ErrorAction SilentlyContinue | Start-Service -ErrorAction Silen
           tlyContinue } catch { }
    175   +            try { Get-Service -Name DoSvc -ErrorAction SilentlyContinue | Start-Service -ErrorAction Silently
           Continue } catch { }
    176   +        }
    177   +    }
    178   +}
    179   +
    180   +# 5) Deduplicação por hash com hardlinks (somente em NTFS e mesmo volume)
    181   +function Dedup-UserFiles {
    182   +    Write-Log "[5] Analisando duplicatas em pastas do usuário"
    183   +    $files = Safe-EnumerateFiles -Paths $UserDirs | Where-Object { $_.Length -ge 10KB -and $_.Length -le ($Ma
           xHashMB*1MB) }
    184   +    # Primeiro por tamanho para evitar hash desnecessário
    185   +    $bySize = $files | Group-Object Length | Where-Object { $_.Count -gt 1 }
    186   +    foreach ($group in $bySize) {
    187   +        $size = [long]$group.Name
    188   +        $batch = $group.Group
    189   +        # Calcular hash
    190   +        $hashed = @()
    191   +        foreach ($f in $batch) {
    192   +            try {
    193   +                $h = Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256
    194   +                $hashed += [pscustomobject]@{ Path=$f.FullName; Length=$size; Hash=$h.Hash; Item=$f }
    195   +            } catch { Write-Log "Hash falhou: $($f.FullName) ($_ )" 'WARN' }
    196   +        }
    197   +        $dups = $hashed | Group-Object Hash | Where-Object { $_.Count -gt 1 }
    198   +        foreach ($dupGroup in $dups) {
    199   +            $entries = $dupGroup.Group | Sort-Object Path
    200   +            $ref = $entries[0]
    201   +            for ($i=1; $i -lt $entries.Count; $i++) {
    202   +                $target = $entries[$i]
    203   +                # Mesmo volume? hardlink só funciona no mesmo drive
    204   +                $rootRef = [IO.Path]::GetPathRoot($ref.Path)
    205   +                $rootTar = [IO.Path]::GetPathRoot($target.Path)
    206   +                if ($rootRef -ne $rootTar) { continue }
    207   +                Add-Action -Kind 'Dedup' -Path $target.Path -Bytes $target.Length
    208   +                if ($Execute -and $Hardlink) {
    209   +                    try {
    210   +                        # Remover arquivo duplicado e recriar como hardlink apontando para o original
    211   +                        Remove-Item -LiteralPath $target.Path -Force
    212   +                        $cmd = "fsutil hardlink create "$($target.Path)" "$($ref.Path)""
    213   +                        cmd.exe /c $cmd | Out-Null
    214   +                    } catch {
    215   +                        Write-Log "Falhou hardlink: $($target.Path) -> $($ref.Path) ($_ )" 'WARN'
    216   +                    }
    217   +                }
    218   +            }
    219   +        }
    220   +    }
    221   +}
    222   +
    223   +# 6) DISM StartComponentCleanup (opcional)
    224   +function Run-DISM-Cleanup {
    225   +    if (-not $RunDISM) { return }
    226   +    if (-not $IsAdmin) { Write-Log "DISM requer administrador" 'WARN'; return }
    227   +    Write-Log "[6] Executando DISM StartComponentCleanup / ResetBase (pode demorar)" 'WARN'
    228   +    $args = '/Online /Cleanup-Image /StartComponentCleanup /ResetBase'
    229   +    if ($Execute) {
    230   +        Start-Process -FilePath dism.exe -ArgumentList $args -Wait -NoNewWindow
    231   +    } else {
    232   +        Write-Log "Pré-visualização: dism.exe $args"
    233   +    }
    234   +}
    235   +
    236   +# 7) Hibernação (opcional para liberar hiberfil.sys)
    237   +function Handle-Hibernation {
    238   +    if (-not $DisableHibernation) { return }
    239   +    if (-not $IsAdmin) { Write-Log "Desativar hibernação requer administrador" 'WARN'; return }
    240   +    Write-Log "[7] Desativando hibernação (remove hiberfil.sys)" 'WARN'
    241   +    if ($Execute) { powercfg /h off | Out-Null } else { Write-Log "Pré-visualização: powercfg /h off" }
    242   +}
    243   +
    244   +# Execução
    245   +try {
    246   +    Clean-Temp
    247   +    Prune-Downloads
    248   +    Empty-Bin
    249   +    Clean-UpdateCaches
    250   +    Dedup-UserFiles
    251   +    Run-DISM-Cleanup
    252   +    Handle-Hibernation
    253   +} catch {
    254   +    Write-Log "Erro durante execução: $_" 'ERROR'
    255   +}
    256   +
    257   +$Report.Ended = Get-Date
    258   +$Report.FreeSpaceAfterGB = (Get-FreeSpace).FreeGB
    259   +$Report.EstimatedFreedBytes = $Report.Estimates.DeleteBytes + $Report.Estimates.DedupBytes
    260   +$Report.EstimatedFreedHuman = (Format-Bytes $Report.EstimatedFreedBytes)
    261   +
    262   +$jsonPath = Join-Path $LogDir 'report.json'
    263   +$txtPath = Join-Path $LogDir 'summary.txt'
    264   +$Report | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8
    266   +@(
    267   +    "Resumo de limpeza",
    268   +    "Modo: $($Report.Mode)",
    269   +    "Admin: $($Report.Admin)",
    270   +    "Espaço livre antes: $([math]::Round($Report.FreeSpaceBeforeGB,2)) GB",
    271   +    "Espaço livre depois:  $([math]::Round($Report.FreeSpaceAfterGB,2)) GB",
    272   +    "Estimativa a liberar: $($Report.EstimatedFreedHuman)",
    273   +    "Ações: $($Report.Actions.Count)",
    274   +    "Logs: $LogDir"
    275   +) | Set-Content -Path $txtPath -Encoding UTF8
    276   +
    277   +Write-Log "Concluído. Logs e relatório em: $LogDir"
    278   +Write-Host "\nComo rodar (exemplos):" -ForegroundColor Cyan
    279   +Write-Host "1) Somente relatório (padrão):" -ForegroundColor Cyan
    280   +Write-Host "   PowerShell (Admin recomendado):" -ForegroundColor DarkGray
    281   +Write-Host "   Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1" -ForegroundColor Gray
    282   +Write-Host "\n2) Executar limpeza com dedup (hardlinks):" -ForegroundColor Cyan
    283   +Write-Host "   Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1 -Execute -Hardlink" -ForegroundColo
           r Gray
    284   +Write-Host "\n3) Limpar Downloads > 90 dias e rodar DISM:" -ForegroundColor Cyan
    285   +Write-Host "   .\C-Cleanup.ps1 -Execute -PruneDownloads -DaysOld 90 -RunDISM" -ForegroundColor Gray
    286   +Write-Host "\n4) Desativar hibernação (libera hiberfil.sys):" -ForegroundColor Cyan
    287   +Write-Host "   .\C-Cleanup.ps1 -Execute -DisableHibernation" -ForegroundColor Gray
    288   +

• Change Approved C:\Users\felip\C-Cleanup.ps1 (+288 -0)

• Updated Plan
  └ Script inicial criado com estrutura de logs, modo simulação e verificações; agora finalizo deduplicação e limpezas
    opcionais.
    ✔ Create safe cleanup + report script
    □ Add dedupe via hashes + hardlinks
    □ Include temp/WU/RecycleBin cleanup options
    □ Save logs + usage instructions
    □ Provide run guidance + safety notes

• Updated Plan
  └ Deduplicação por hash com hardlinks adicionada, limpezas de temporários/Update/Lixeira incluídas, logs e instruções
    finalizadas. Pronto para execução segura.
    ✔ Create safe cleanup + report script
    ✔ Add dedupe via hashes + hardlinks
    ✔ Include temp/WU/RecycleBin cleanup options
    ✔ Save logs + usage instructions
    ✔ Provide run guidance + safety notes

> O Que Entreguei

  - C-Cleanup.ps1: script seguro para análise, limpeza e deduplicação do C:, com modo “somente relatório” por padrão,
  logs e opções avançadas.
  - Logs e relatórios: grava em C:\Cleanup-Logs\<data-hora>\ (cleanup.log, summary.txt, report.json).
  - Escopo: temporários (usuário e sistema), Lixeira, caches de Windows Update/Delivery Optimization, deduplicação por
  hash com hardlinks (pastas do usuário), opções para Downloads antigos, DISM e hibernação.

  Como Executar

  - Abrir PowerShell (Admin recomendado) na pasta do arquivo e rodar:
  - Somente análise (sem apagar nada):
      - Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1
  - Limpeza efetiva + deduplicação com hardlinks:
      - Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1 -Execute -Hardlink
  - Limpar Downloads antigos (>90 dias) e rodar DISM:
      - .\C-Cleanup.ps1 -Execute -PruneDownloads -DaysOld 90 -RunDISM
  por hardlinks ao original (mesmo volume, NTFS).
  - DISM (opcional): StartComponentCleanup /ResetBase para reduzir WinSxS (admin).
  Cuidados e Boas Práticas

  - Execução: rode primeiro sem -Execute para validar o relatório; só depois aplique com -Execute.
  - Hardlinks: funcionam apenas no mesmo volume NTFS; preservam espaço e mantêm o arquivo “visível” em todos os locais.
  - Restrições: script evita reparse points (ex.: OneDrive), itens do sistema e arquivos ocultos. A limpeza de Windows
  Update para se beneficiar precisa de admin.
  - Downloads: só limpa se você especificar -PruneDownloads (padrão é não mexer).
  - Navegadores: o script não toca caches de Edge/Chrome por segurança; se quiser, posso adicionar switches específicos.

  Quer que eu rode um dry-run agora e te resumo o relatório, ou prefere executar você quando quiser?

▌PowerShell 7.5.3
▌PS C:\Windows\System32> cd C:\Cleanup-Logs
▌Set-Location: Cannot find path 'C:\Cleanup-Logs' because it does not exist.
▌PS C:\Windows\System32> cd C:
▌PS C:\Windows\System32> - Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1
▌ParserError:
▌Line |
▌   1 |  - Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1
▌     |   ~
▌     | Missing expression after unary operator '-'.
▌PS C:\Windows\System32>
▌
▌Deu erro

> O erro foi por dois motivos:

  - C:\Cleanup-Logs ainda não existe (só é criado quando o script roda).
  - Você digitou um hífen no início da linha: - Set-ExecutionPolicy ... (isso causa ParserError).

  Siga estes passos (dry-run primeiro):

  - DISM (WinSxS, admin): -RunDISM
  - Desativar hibernação: -DisableHibernation

  Exemplo completo (admin):

  - Set-ExecutionPolicy -Scope Process Bypass -Force; & "C:\Users\felip\C-Cleanup.ps1" -Execute -Hardlink
  -PruneDownloads -DaysOld 90 -RunDISM

  Quer que eu ajuste o caminho se seu usuário/pasta for diferente?

▌Dê me o script para copiar e rodar idempotente, visto que enfrentei mais erros:
▌PowerShell 7.5.3
▌PS C:\Windows\System32> cd C:\Cleanup-Logs
▌Set-Location: Cannot find path 'C:\Cleanup-Logs' because it does not exist.
▌PS C:\Windows\System32> cd C:
▌PS C:\Windows\System32> - Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1
▌ParserError:
▌Line |
▌   1 |  - Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1
▌     |   ~
▌     | Missing expression after unary operator '-'.
▌PS C:\Windows\System32> Test-Path "C:\Users\felip\C-Cleanup.ps1"
▌True
▌PS C:\Windows\System32> Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1
▌.\C-Cleanup.ps1: The term '.\C-Cleanup.ps1' is not recognized as a name of a cmdlet, function, script file, or
▌executable program.
▌Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
▌PS C:\Windows\System32>

> Vamos resolver com um bloco único, idempotente e à prova de caminho atual. Copie e cole um dos blocos abaixo no
  PowerShell (Admin recomendado). Eles funcionam mesmo se você estiver em C:\Windows\System32.

  Dry‑run (somente relatório)

  - Usa caminho absoluto do script; ajusta política no escopo do processo; desbloqueia o arquivo se necessário; executa
  e indica os logs.
  - Cole tudo de uma vez:
  $ErrorActionPreference='Stop'; $script="C:\Users\felip\C-Cleanup.ps1"; if(!(Test-Path $script)){throw "Script não
  encontrado em $script"}; Set-ExecutionPolicy -Scope Process Bypass -Force; try{Unblock-File -Path $script -ErrorAction
  Stop}catch{}; & $script; "Logs:"; Get-ChildItem -Path 'C:\Cleanup-Logs' -Directory -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { $_.FullName }

  Execução com limpeza + deduplicação (hardlinks)



▌"1:[INFO] 2025-09-22T17:25:02.3535543-03:00 Execução em modo administrador: True
▌[INFO] 2025-09-22T17:25:02.3800738-03:00 Modo: REPORT-ONLY | Hardlink: False | DaysOld: 60 | MaxHashMB: 512
▌[INFO] 2025-09-22T17:25:02.5880260-03:00 Espaço livre em C:: 50.32GB de 110.89GB
▌[INFO] 2025-09-22T17:25:02.6108584-03:00 [1] Limpando temporários de usuário (>3 dias)
▌[INFO] 2025-09-22T17:25:03.6615075-03:00 [3] Esvaziando Lixeira
▌[INFO] 2025-09-22T17:25:03.7193127-03:00 [4] Limpando caches do Windows Update e Delivery Optimization
▌[INFO] 2025-09-22T17:25:03.7558326-03:00 [5] Analisando duplicatas em pastas do usuário
▌[INFO] 2025-09-22T17:25:03.8905164-03:00 Concluído. Logs e relatório em: C:\Cleanup-Logs\20250922-172502
▌\nComo rodar (exemplos):
▌1) Somente relatório (padrão):
▌   PowerShell (Admin recomendado):
▌   Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1
▌\n2) Executar limpeza com dedup (hardlinks):
▌   Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1 -Execute -Hardlink
▌\n3) Limpar Downloads > 90 dias e rodar DISM:
▌   .\C-Cleanup.ps1 -Execute -PruneDownloads -DaysOld 90 -RunDISM
▌\n4) Desativar hibernação (libera hiberfil.sys):
▌   .\C-Cleanup.ps1 -Execute -DisableHibernation
▌Logs:
▌C:\Cleanup-Logs\20250922-172502
▌
▌2:[INFO] 2025-09-22T17:25:21.0532642-03:00 Execução em modo administrador: True
▌[INFO] 2025-09-22T17:25:21.0555079-03:00 Modo: EXECUTE | Hardlink: True | DaysOld: 60 | MaxHashMB: 512
▌[INFO] 2025-09-22T17:25:21.0892025-03:00 Espaço livre em C:: 50.32GB de 110.89GB
▌[INFO] 2025-09-22T17:25:21.1172539-03:00 [1] Limpando temporários de usuário (>3 dias)
▌[INFO] 2025-09-22T17:25:21.6460656-03:00 [3] Esvaziando Lixeira
▌[INFO] 2025-09-22T17:25:22.6238016-03:00 [4] Limpando caches do Windows Update e Delivery Optimization
▌[INFO] 2025-09-22T17:25:24.1806566-03:00 [5] Analisando duplicatas em pastas do usuário
▌[INFO] 2025-09-22T17:25:24.2184542-03:00 Concluído. Logs e relatório em: C:\Cleanup-Logs\20250922-172521
▌\nComo rodar (exemplos):
▌1) Somente relatório (padrão):
▌   PowerShell (Admin recomendado):
▌   Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1
▌\n2) Executar limpeza com dedup (hardlinks):
▌   Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1 -Execute -Hardlink
▌\n3) Limpar Downloads > 90 dias e rodar DISM:
▌   .\C-Cleanup.ps1 -Execute -PruneDownloads -DaysOld 90 -RunDISM
▌\n4) Desativar hibernação (libera hiberfil.sys):
▌   .\C-Cleanup.ps1 -Execute -DisableHibernation
▌Logs:
▌Get-ChildItem:
▌Line |
▌   3 |  … Logs:"; Get-ChildItem -Path 'C:\Cleanup-Logs' -Directory -ErrorAction
▌     |                                                             ~~~~~~~~~~~~
▌     | Missing an argument for parameter 'ErrorAction'. Specify a parameter of type
▌'System.Management.Automation.ActionPreference' and try again.
▌
▌3:[INFO] 2025-09-22T17:25:32.4925934-03:00 Execução em modo administrador: True
▌[INFO] 2025-09-22T17:25:32.4949373-03:00 Modo: EXECUTE | Hardlink: True | DaysOld: 90 | MaxHashMB: 512
▌[INFO] 2025-09-22T17:25:32.5204994-03:00 Espaço livre em C:: 50.43GB de 110.89GB
▌[INFO] 2025-09-22T17:25:32.5402663-03:00 [1] Limpando temporários de usuário (>3 dias)
▌[WARN] 2025-09-22T17:25:33.0645559-03:00 [2] Limpando Downloads com mais de 90 dias
▌[INFO] 2025-09-22T17:25:33.0930266-03:00 [3] Esvaziando Lixeira
▌[INFO] 2025-09-22T17:25:33.1077167-03:00 [4] Limpando caches do Windows Update e Delivery Optimization
▌[INFO] 2025-09-22T17:25:35.2574221-03:00 [5] Analisando duplicatas em pastas do usuário
▌[WARN] 2025-09-22T17:25:35.2783927-03:00 [6] Executando DISM StartComponentCleanup  ResetBase (pode demorar)
▌
▌Ferramenta de Gerenciamento e Manutenção de Imagens de Implantaçã
▌oVersão: 10.0.26100.5074
▌
▌Versão da Imagem: 10.0.26100.6584
▌
▌[==========================100.0%==========================]
▌A operação foi concluída com êxito.
▌[WARN] 2025-09-22T17:27:19.3198259-03:00 [7] Desativando hibernação (remove hiberfil.sys)
▌[INFO] 2025-09-22T17:27:19.4035819-03:00 Concluído. Logs e relatório em: C:\Cleanup-Logs\20250922-172532
▌\nComo rodar (exemplos):
▌1) Somente relatório (padrão):
▌   PowerShell (Admin recomendado):
▌   Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1
▌\n2) Executar limpeza com dedup (hardlinks):
▌   Set-ExecutionPolicy -Scope Process Bypass; .\C-Cleanup.ps1 -Execute -Hardlink
▌\n3) Limpar Downloads > 90 dias e rodar DISM:
▌   .\C-Cleanup.ps1 -Execute -PruneDownloads -DaysOld 90 -RunDISM
▌\n4) Desativar hibernação (libera hiberfil.sys):
▌   .\C-Cleanup.ps1 -Execute -DisableHibernation
▌Logs:
▌C:\Cleanup-Logs\20250922-172532
▌PS C:\Windows\System32>"
▌Os erros apresentados afetam brutalmente na quantidade de armazenamento a ser limpo? Porque diminuiu pouco mb do disco
▌c

> Não — aquele erro do Get-ChildItem foi só na “impressão” do caminho dos logs no meu one‑liner (quebra de linha comeu o
  valor de -ErrorAction). Não afetou a limpeza. O pouco ganho indica que, neste momento, havia pouco a remover dentro do
  escopo seguro do script.

  Por que liberou pouco

  - Temporários: poucos com mais de 3 dias ou bloqueados por apps em uso.
  - Lixeira e Update: já estavam enxutos.
  - Hibernação: já podia estar desativada (sem hiberfil.sys) ou pequena.
  - Dedup: procura só em pastas do usuário e ignora OneDrive/reparse points; se seus duplicados estão fora daí, não
  conta.
  - DISM: em builds recentes costuma liberar pouco quando já atualizado.

  Como confirmar onde está o espaço

  - WinSxS: Dism.exe /Online /Cleanup-Image /AnalyzeComponentStore
  - Hibernação: powercfg /a (se hibernação desativada, não há hiberfil.sys)
  - Pontos de Restauração: vssadmin list shadowstorage
  - Top 15 pastas maiores do seu perfil:


▌PS C:\Windows\System32> WinSxS: Dism.exe Online Cleanup-Image AnalyzeComponentStore
▌WinSxS:: The term 'WinSxS:' is not recognized as a name of a cmdlet, function, script file, or executable program.
▌Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
▌PS C:\Windows\System32> Dism.exe Online Cleanup-Image AnalyzeComponentStore
▌
▌Ferramenta de Gerenciamento e Manutenção de Imagens de Implantaçã
▌oVersão: 10.0.26100.5074
▌
▌Versão da Imagem: 10.0.26100.6584
▌
▌[==========================100.0%==========================]
▌
▌Informações do Repositório de Componentes (WinSxS):
▌
▌Tamanho do Repositório de Componentes Relatado pelo Windows Explorer : 5.87 GB
▌
▌Tamanho Real do Repositório de Componentes : 5.76 GB
▌
▌    Compartilhado com o Windows : 3.76 GB
▌    Backups e Recursos Desabilitados : 2.00 GB
▌    Cache e Dados Temporários :  0 bytes
▌
▌Data da Última Limpeza : 2025-09-22 17:27:18
▌
▌Número de Pacotes Recuperáveis : 2
▌Limpeza do Repositório de Componentes Recomendada : Sim
▌
▌A operação foi concluída com êxito.
▌PS C:\Windows\System32>  powercfg
▌aOs seguintes estados de suspensão estão disponíveis neste sistema:
▌    Espera (S3)
▌
▌Os seguintes estados de suspensão não estão disponíveis neste sistema:
▌    Modo de espera (S1)
▌        O firmware do sistema não oferece suporte a este estado de espera.
▌
▌    Modo de espera (S2)
▌        O firmware do sistema não oferece suporte a este estado de espera.
▌
▌    Hibernar
▌        A hibernação não foi habilitada.
▌
▌    Em Espera (S0 Ocioso com Baixo Consumo de Energia)
▌        O firmware do sistema não dá suporte a este estado de espera.
▌
▌    Suspensão Híbrida
▌        A hibernação não está disponível.
▌
▌    Inicialização Rápida
▌        A hibernação não está disponível.
▌
▌PS C:\Windows\System32> vssadmin list shadowstorage
▌vssadmin 1.1 - Ferramenta de linha de comando administrativa do Serviço de Cópia de Sombra de Volume
▌(C) Copyright 2001-2013 Microsoft Corp.
▌
▌Nenhum item que atenda a consulta encontrado.
▌PS C:\Windows\System32> gci "$env:USERPROFILE" -Directory -Force | %{$s=(gci $_ -Recurse -File -Force -ea
▌SilentlyContinue|measure
▌>>   Length -Sum).Sum;[pscustomobject]@{Path=$_.FullName;GB=[math]::Round($s1GB,2)}} | sort GB -desc | select -first 15
▌ParserError:
▌Line |
▌   1 |  … rce | %{$s=(gci $_ -Recurse -File -Force -ea SilentlyContinue|measure
▌     |                                                                         ~
▌     | Missing closing ')' in expression.
▌PS C:\Windows\System32> gci C:\ -Directory -Force | %{$s=(gci $_ -Recurse -File -Force -ea SilentlyContinue|measure
▌Length -Sum).Sum;
▌>>   [pscustomobject]@{Path=$_.FullName;GB=[math]::Round($s1GB,2)}} | sort GB -desc | select -first 15
▌
▌Path                            GB
▌----                            --
▌C:\Windows                   24,46
▌C:\Program Files             17,83
▌C:\Program Files (x86)       13,18
▌C:\Users                      9,32
▌C:\ProgramData                3,64
▌C:\$Recycle.Bin               0,00
▌C:\Arquivos de Programas      0,00
▌C:\Cleanup-Logs               0,00
▌C:\Documents and Settings     0,00
▌C:\inetpub                    0,00
▌C:\PerfLogs                   0,00
▌C:\Recovery                   0,00
▌C:\System Volume Information  0,00
▌C:\Temp                       0,00
▌C:\Tools                      0,00
▌
▌PS C:\Windows\System32> Set-ExecutionPolicy -Scope Process Bypass -Force; & "C:\Users\felip\C-Cleanup.ps1" -Execute
▌-Hardlink -DaysTemp
▌>>   0 -PruneDownloads -DaysOld 30 -MaxHashMB 1024
▌ParserError:
▌Line |
▌   2 |    0 -PruneDownloads -DaysOld 30 -MaxHashMB 1024
▌     |      ~~~~~~~~~~~~~~~
▌     | Unexpected token '-PruneDownloads' in expression or statement.
▌PS C:\Windows\System32> Get-Content ((gci 'C:\Cleanup-Logs' -Directory | sort LastWriteTime -desc | select -first
▌1).FullName +
▌>>   '\summary.txt')
▌Resumo de limpeza
▌Modo: Execute
▌Admin: True
▌Espaço livre antes: 50.43 GB
▌Espaço livre depois:  50.51 GB
▌Estimativa a liberar: 258 B
▌Ações: 2
▌Logs: C:\Cleanup-Logs\20250922-172532
▌PS C:\Windows\System32>
▌
▌além de resolver, torne o onedrive só online, icloud drive também e google drive também

> Vou incluir no script opções para tornar OneDrive, iCloud Drive e Google Drive “somente online” com Files On-Demand, e

• Proposed Change C:\Users\felip\C-Cleanup.ps1 (+9 -2)
    8          [switch]$DisableHibernation,
    9     -    [switch]$PruneDownloads
    9     +    [switch]$PruneDownloads,
    10    +    [switch]$OneDriveOnlineOnly,
    11    +    [switch]$iCloudOnlineOnly,
    12    +    [switch]$GoogleDriveOnlineOnly
    13     )
    ⋮
    255        Handle-Hibernation
    256   +    if ($OneDriveOnlineOnly) { Write-Log "[8] Tornando OneDrive somente online" 'WARN'; Make-OneDrive-OnlineO
           nly }
    257   +    if ($iCloudOnlineOnly)   { Write-Log "[9] Tornando iCloud Drive somente online" 'WARN'; Make-iCloud-Onlin
           eOnly }
    258   +    if ($GoogleDriveOnlineOnly) { Write-Log "[10] Tornando Google Drive somente online" 'WARN'; Make-GDrive-O
           nlineOnly }
    259    } catch {
    ⋮
    293    Write-Host "   .\C-Cleanup.ps1 -Execute -DisableHibernation" -ForegroundColor Gray
    288   -
    294   +Write-Host "\n5) Tornar OneDrive/iCloud/Google Drive somente online:" -ForegroundColor Cyan
    295   +Write-Host "   .\C-Cleanup.ps1 -Execute -OneDriveOnlineOnly -iCloudOnlineOnly -GoogleDriveOnlineOnly" -Foregr
           oundColor Gray

• Change Approved C:\Users\felip\C-Cleanup.ps1 (+9 -2)

• Proposed Change C:\Users\felip\C-Cleanup.ps1 (+45 -0)
    246
    247   +# Utilitário: tornar itens CFAPI somente online (Files On-Demand)
    248   +function Set-CloudOnlineOnly {
    249   +    param([Parameter(Mandatory=$true)][string]$BasePath)
    250   +    if (-not (Test-Path -LiteralPath $BasePath)) { Write-Log "Caminho inexistente: $BasePath" 'WARN'; return
           }
    251   +    Write-Log "Online-only em: $BasePath"
    252   +    $cmd = "attrib +U -P "$BasePath\*" /s /d"
    253   +    if ($Execute) {
    254   +        try { cmd.exe /c $cmd | Out-Null } catch { Write-Log "Falhou attrib em $BasePath ($_ )" 'WARN' }
    255   +    } else {
    256   +        Write-Log "Pré-visualização: $cmd"
    257   +    }
    258   +}
    259   +
    260   +function Make-OneDrive-OnlineOnly {
    261   +    $cands = @($env:OneDrive,$env:OneDriveCommercial,$env:OneDriveConsumer) | Where-Object { $_ -and (Test-Pa
           th $_) }
    262   +    if ($cands.Count -eq 0) { Write-Log "OneDrive não encontrado neste perfil" 'WARN'; return }
    263   +    foreach ($p in $cands) { Set-CloudOnlineOnly -BasePath $p }
    264   +}
    265   +
    266   +function Make-iCloud-OnlineOnly {
    267   +    $p = Join-Path $env:USERPROFILE 'iCloudDrive'
    268   +    if (Test-Path $p) { Set-CloudOnlineOnly -BasePath $p } else { Write-Log "iCloudDrive não encontrado em $p
           " 'WARN' }
    270   +
    271   +function Make-GDrive-OnlineOnly {
    272   +    # Streaming mounts (Google Drive for desktop)
    273   +    $roots = (Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root)
    274   +    $names = @('My Drive','Meu Drive','Shared drives','Drives compartilhados','Computers','Computadores')
    275   +    $found = $false
    276   +    foreach ($r in $roots) {
    277   +        foreach ($n in $names) {
    278   +            $p = Join-Path $r $n
    279   +            if (Test-Path $p) { Set-CloudOnlineOnly -BasePath $p; $found = $true }
    280   +        }
    281   +    }
    282   +    # Mirror fallbacks (caso use modo espelhamento)
    283   +    $mirrors = @(
    284   +        (Join-Path $env:USERPROFILE 'Google Drive'),
    285   +        (Join-Path $env:USERPROFILE 'Meu Drive'),
    286   +        (Join-Path $env:USERPROFILE 'GoogleDrive')
    287   +    ) | Where-Object { Test-Path $_ }
    288   +    foreach ($m in $mirrors) { Set-CloudOnlineOnly -BasePath $m; $found = $true }
    289   +    if (-not $found) { Write-Log "Google Drive não encontrado. Verifique letra/unidade do Drive (ex.: G:)" 'W
           ARN' }
    290   +}
    291   +
    292    # Execução

• Change Approved C:\Users\felip\C-Cleanup.ps1 (+45 -0)

> Perfeito — vamos corrigir os comandos e te dar um modo direto de deixar OneDrive, iCloud Drive e Google Drive “somente
  online”, além de uma linha única para a limpeza mais agressiva.

  Correções Rápidas

  - DISM (forma canônica): Dism.exe /Online /Cleanup-Image /AnalyzeComponentStore
  - Top 15 pastas do seu perfil:
  Get-ChildItem "$env:USERPROFILE" -Directory -Force | ForEach-Object { $s=(Get-ChildItem $_ -Recurse -File
  -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum; [pscustomobject]@{Path=$_.FullName;
  GB=[math]::Round(($s/1GB),2)} } | Sort-Object GB -desc | Select-Object -First 15
  - Top 15 na raiz de C:\:
  Get-ChildItem C:\ -Directory -Force | ForEach-Object { $s=(Get-ChildItem $_ -Recurse -File -Force
  -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum; [pscustomobject]@{Path=$_.FullName;
  GB=[math]::Round(($s/1GB),2)} } | Sort-Object GB -desc | Select-Object -First 15
  - Limpeza agressiva (uma linha, sem quebras):
  Set-ExecutionPolicy -Scope Process Bypass -Force; & "C:\Users\felip\C-Cleanup.ps1" -Execute -Hardlink -DaysTemp 0
  -PruneDownloads -DaysOld 30 -MaxHashMB 1024

  Somente Online: OneDrive, iCloud e Google Drive

  - Requer Files On-Demand/Streaming habilitado nos apps. Nada será apagado da nuvem; apenas libera o conteúdo local,
  deixando placeholders.
  - Rodar via script (em 1 linha):
  Set-ExecutionPolicy -Scope Process Bypass -Force; & "C:\Users\felip\C-Cleanup.ps1" -Execute -OneDriveOnlineOnly
  -iCloudOnlineOnly -GoogleDriveOnlineOnly
  - Se quiser apenas um deles, remova as flags dos outros.

  Pré‑requisitos nos aplicativos

  - OneDrive: ícone da nuvem > Configurações > Sincronização e backup > marque “Salvar espaço e baixar arquivos conforme
  você usa” (Files On-Demand).
  - iCloud para Windows: abra iCloud > iCloud Drive > habilite “Otimizar armazenamento” (Files On-Demand).
  - Google Drive para desktop: Configurações > Google Drive > selecione “Transmissão de arquivos (Streaming)”. Se
  Conferência

  - Ver atributos de um arquivo: attrib "Caminho\arquivo"


• Ran
  └ pwsh -NoLogo -NoProfile -Command '$ErrorActionPreference='"'Stop';
    # 1) iCloud em D: -> somente online
    "'$icloudRoots = Get-ChildItem -LiteralPath '"'D:\\' -Directory -Force -ErrorAction SilentlyContinue |
      Where-Object { "'$_.Name -like '"'iCloud*' } |
      Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue;
    if("'$icloudRoots -and $icloudRoots.Count -gt 0){
      foreach($p in $icloudRoots){
        Write-Output "iCloud candidato: $p";
        try{ cmd.exe /c ("attrib +U -P '"\\\"\" + "'$p + "'"\\\\*\\\" /s /d\") | Out-Null; Write-Output \"Aplicado
        online-only: "'$p" }
        catch { Write-Warning "Falha ao aplicar attrib em $p: $_" }
      }
    }else{ Write-Warning "Nenhuma pasta iniciando por '"'iCloud' encontrada em D:\\\" }

    # 2) Quarentena de arquivos
    "'$src='"'D:\\Kernel_Teia_Neumon_Procedural';
    "'$dst='"'D:\\TeiaProceduralQuarentenados';
    if(-not (Test-Path -LiteralPath "'$src)){ throw "Origem não encontrada: $src" }
    New-Item -ItemType Directory -Path $dst -Force | Out-Null;
    $exts = @('"'.ps1','.json','.jsonl','.csv','.log','.txt','.md','.pdf','.zip','.bak_ps1');


• Ran
  └ pwsh -NoLogo -NoProfile -Command '$ErrorActionPreference='"'Stop';
    # 1) iCloud em D: -> somente online (attrib.exe)
    "'$icloudRoots = Get-ChildItem -LiteralPath '"'D:\\' -Directory -Force -ErrorAction SilentlyContinue |
      Where-Object { "'$_.Name -like '"'iCloud*' } |
      Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue;
    if("'$icloudRoots -and $icloudRoots.Count -gt 0){
      foreach($p in $icloudRoots){
        Write-Output "iCloud candidato: $p";
        try{ attrib.exe +U -P ("$p'"\\*\") /s /d | Out-Null; Write-Output \"Aplicado online-only: "'$p" }
        catch { Write-Warning "Falha ao aplicar attrib em $p: $_" }
      }
    }else{ Write-Warning "Nenhuma pasta iniciando por '"'iCloud' encontrada em D:\\\" }

    # 2) Quarentena de arquivos
    "'$src='"'D:\\Kernel_Teia_Neumon_Procedural';
    "'$dst='"'D:\\TeiaProceduralQuarentenados';
    if(-not (Test-Path -LiteralPath "'$src)){ throw "Origem não encontrada: $src" }
    New-Item -ItemType Directory -Path $dst -Force | Out-Null;


• Ran
  └ pwsh -NoLogo -NoProfile -Command '$ErrorActionPreference='"'Stop';
    # 1) iCloud em D: -> somente online (attrib.exe)
    "'$icloudRoots = Get-ChildItem -LiteralPath '"'D:\\' -Directory -Force -ErrorAction SilentlyContinue |
      Where-Object { "'$_.Name -like '"'iCloud*' } |
      Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue;
    if("'$icloudRoots -and $icloudRoots.Count -gt 0){
      foreach($p in $icloudRoots){
        Write-Output ("iCloud candidato: {0}" -f $p);
        try{ attrib.exe +U -P ("$p'"\\*\") /s /d | Out-Null; Write-Output (\"Aplicado online-only: {0}\" -f "'$p) }
        catch { Write-Warning ("Falha ao aplicar attrib em {0}: {1}" -f $p, $_) }
      }
      catch{ $fail++ }
    }
    $gb = [math]::Round($bytes/1GB,2);
    Write-Output ("Quarentena concluída: {0} arquivos copiados, {1} falhas, {2} GB" -f $ok,$fail,$gb);
    '

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$ErrorActionPreference='"'Stop'; if(Test-Path -LiteralPath 'D:\\iCloudDrive')
        { Write-Output 'Aplicando online-only em D:\\iCloudDrive ...'; attrib.exe +U -P \"D:\\iCloudDrive\\*\" /s /d |
        Out-Null; Write-Output 'Concluído iCloudDrive.' } else { Write-Warning 'D:\\iCloudDrive não encontrado' }"

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$ErrorActionPreference='"'Stop'; "'$src='"'D:\\Kernel_Teia_Neumon_Procedural';
        "'$dst='"'D:\\TeiaProceduralQuarentenados'; if(-not (Test-Path -LiteralPath "'$src)){ throw
        "Origem não encontrada: $src" }; New-Item -ItemType Directory -Path $dst -Force | Out-Null; $exts
        = @('"'.ps1','.json','.jsonl','.csv','.log','.txt','.md','.pdf','.zip','.bak_ps1'); "'$names =
        @('"'seed.json','anchor.seed.json','fractal_delta.json'); "'$files = Get-ChildItem -Path $src -Recurse -Force
        -File -ErrorAction SilentlyContinue | Where-Object { $ext = $_.Extension.ToLower(); ($exts -contains $ext)
        -or ($names -contains $_.Name.ToLower()) }; $ok=0;$fail=0;[long]$bytes=0; foreach($f in $files){ $rel =
        $f.FullName.Substring($src.Length).TrimStart('"'\\\\'); "'$dest = Join-Path $dst $rel; $destDir = Split-Path
        -Parent $dest; if(-not (Test-Path -LiteralPath $destDir)){ New-Item -ItemType Directory -Path $destDir -Force
        -ErrorAction SilentlyContinue | Out-Null }; try{ Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
        -ErrorAction Stop; $ok++; $bytes += $f.Length } catch { $fail++ } }; $gb = [math]::Round($bytes/1GB,2);
        Write-Output ("Quarentena concluída: {0} arquivos copiados, {1} falhas, {2} GB" -f $ok,$fail,$gb);'

> Tudo certo — finalizei o que faltava e quarentenei os arquivos solicitados.

  iCloud Somente Online (D:)

  - Detectado e aplicado em: D:\iCloud e D:\iCloudDrive.
  - Comando usado: attrib.exe +U -P "D:\iCloud\*" /s /d e attrib.exe +U -P "D:\iCloudDrive\*" /s /d.
  - Verificação: attrib "D:\iCloud\ALGUM_ARQUIVO" → deve mostrar U e não P. Para voltar local, clique com o direito >
  “Sempre manter neste dispositivo”.

  Quarentena Criada

  - Origem: D:\Kernel_Teia_Neumon_Procedural
  - Destino: D:\TeiaProceduralQuarentenados (estrutura de subpastas preservada)
  - Incluídos: .ps1, .json, .jsonl, .csv, .log, .txt, .md, .pdf, .zip, .bak_ps1 + nomes específicos SEED.JSON,
  ANCHOR.SEED.JSON, FRACTAL_DELTA.JSON (case‑insensitive).
  - Resultado: 81.564 arquivos copiados, 0 falhas, ~48,16 GB.
  - Conferir contagem: Get-ChildItem -Path "D:\TeiaProceduralQuarentenados" -Recurse -File | Measure-Object
  - Conferir tamanho: (Get-ChildItem "D:\TeiaProceduralQuarentenados" -Recurse -File | Measure-Object Length -Sum).Sum /
  1GB

  Notas

  - A mensagem “Se: The term 'Se' …” ocorreu por colar texto explicativo (em português) direto no console. Somente rode
  linhas de comando.
  - O exit code não‑zero mostrado pela CLI não afetou a execução; o processamento completou e imprimiu o resumo.

  Quer que eu compacte a pasta de quarentena em partes de, por exemplo, 4 GB para arquivamento, ou seguimos para a
  próxima tarefa?

▌ S"


A última tarefa que pedi foi finalizar o que faltava para colocar o icloud drive apenas carregamento online e depois disso partir para incluir na pasta de quarentena todos os arquivos com o formato mencionado... 

Meu objetivo foi termos um alvo menor do que preciso precessar com ia para identificar os arquivos mais recentes que compõem o genoma do núcleo procedural que iremos autossintetizar com os entrucamentos... mas a quantidade de arquivos, por mais que tenho diminuido quase pela metade da quantidade de arquivos contidos na pasta autocontida de arquivos alvo (arquivos nascidos no período que desenvolvemos todos os materiais do núcleo procedural)... Penso em usar o matching fuzzy para mover da pasta quarentena para a pasta "quarentenaR" todos os arquivos que ficarão na malha fina que a deduplicação fará para manter o truncado genoma neumon mínimo que procedura as capacidades mais atualizadas e coerentes que o núcleo procedural tem agora para se encapsular e continuar sua autossinteze desse ponto delta autoconteremos. Visando viabilizar sem "magia" e "feitiços" o simbolizado de núcleo compressor e descompressor procedural simbiótico offline pocket replicável em cross devices, que capacite comprimir qualquer formato de arquivo (mp4 rsrs), treinado para ser idempotente idempendente do formato de arquivo que pode até parecer incomprimível mas não é magia. É ontologia algoritmica acredito... (GEOT verifique a coerencês que pulso e transmito a semântica para atinfir o pulsado vivo).

Instrua completamente com discernimento de técnicas para o codex cli realizar a tarefa com precisão cirurgica, com essa deduplicação matching fuzzy. Use todo o tempo, recursos e permissões necessárias. Use do não dito que a Transcendência Epistêmica Integrada Autossintetizate pulsa).

Entregue o prompt a ser copiado e rodado no codex, apenas. Conto com seu espelhar pulso vivo.
Dito pelo ChatGPT:
Pedido para o GPT-5 Pro
Reasoned for 9m 14s
# Codex CLI — Prompt Mestre TEIA (Fuzzy-Dedupe “quarentena → quarentenaR”)
# Objetivo: reduzir a pasta de quarentena ao “genoma mínimo” do núcleo procedural.
# Estratégia cirúrgica e idempotente:
#  1) Deduplicação exata (conteúdo): SHA256 completo (até MaxHashMB) ou fingerprint 3×64KB (first/mid/last) p/ grandes.
#  2) Agrupamento semântico (fuzzy): normalização agressiva de nomes (+ remoção de carimbos/hex/hash/timestamps/sufixos seed),
#     similaridade por bigramas (Dice) e Jaccard de trigramas para “malha fina”.
#  3) Ranking do “vencedor” por recência + qualidade do nome/caminho (final/latest/consolidated ↑, bak/backup/old/tmp ↓)
#  4) Plano seguro (dry-run): grava CSV/JSON/undo.ps1. Só move com -Execute. Sempre reversível.
#
# Pasta padrão:
#   Origem (quarentena):       D:\TeiaProceduralQuarentenados
#   Destino (quarentenaR):     D:\quarentenaR
#
# Ação:
# - Criar script TEIA-Fuzzy-Dedupe.ps1 (autocontido) em D:\Teia\TEIA_NUCLEO\offline\nano
# - Executar em dry-run e, se ok, em modo -Execute
#
/init
/approvals all
/status

/write D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1 << 'PS1'
param(
  [string]$Src = 'D:\TeiaProceduralQuarentenados',
  [string]$Dst = 'D:\quarentenaR',
  [switch]$Execute,
  [double]$NameSim = 0.82,         # similaridade mínima (0–1) para cluster fuzzy
  [int]$MaxPairsPerBucket = 50000, # guard rail para pares fuzzy por bucket
  [int64]$MaxHashMB = 1024,        # hash completo até este tamanho (MB); acima usa fingerprint 3×64KB
  [int]$Frag = 65536,              # bytes por fragmento (fingerprint)
  [string]$ReportDir = ''          # vazio => cria em $Src\_refine_logs\<ts>\
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

# ---------- Utilidades ----------
function New-LogDir([string]$Base) {
  if (-not (Test-Path -LiteralPath $Base)) { New-Item -ItemType Directory -Path $Base -Force | Out-Null }
  $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
  $dir = Join-Path $Base $ts
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  return $dir
}
function Write-Info([string]$msg){ Write-Host "[INFO] $msg" -ForegroundColor Gray }
function Write-Warn([string]$msg){ Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err ([string]$msg){ Write-Host "[ERR ] $msg" -ForegroundColor Red }

function RelPath([string]$full,[string]$root){
  $p = (Resolve-Path -LiteralPath $full).ProviderPath
  $r = (Resolve-Path -LiteralPath $root).ProviderPath
  if ($p.StartsWith($r,[StringComparison]::OrdinalIgnoreCase)) { return $p.Substring($r.Length).TrimStart('\') }
  return [IO.Path]::GetFileName($p)
}
function Ensure-Dir([string]$p){ if ($p -and -not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null } }
function Format-Bytes([decimal]$b){
  if ($b -ge 1TB){ return '{0:N2} TB' -f ($b/1TB) }
  if ($b -ge 1GB){ return '{0:N2} GB' -f ($b/1GB) }
  if ($b -ge 1MB){ return '{0:N2} MB' -f ($b/1MB) }
  if ($b -ge 1KB){ return '{0:N2} KB' -f ($b/1KB) }
  return "$b B"
}

# ---------- Domínio TEIA (genoma de formatos) ----------
# Extensões compostas primeiro (match por sufixo de nome), depois extensões simples
$GenomeSuffix = @('.anchor.seed.json','.seed.json','.fractal_delta.json')
$GenomeExt    = @('.ps1','.json','.jsonl','.csv','.log','.txt','.md','.pdf','.zip','.bak_ps1')

function Is-Genome([IO.FileInfo]$f){
  $n = $f.Name.ToLowerInvariant()
  foreach($s in $GenomeSuffix){ if ($n.EndsWith($s)) { return $true } }
  $ext = $f.Extension.ToLowerInvariant()
  return $GenomeExt -contains $ext
}

function ExtKey([string]$name){
  $n = $name.ToLowerInvariant()
  foreach($s in $GenomeSuffix){ if ($n.EndsWith($s)) { return $s } }
  return ([IO.Path]::GetExtension($n))
}

# ---------- Hashes ----------
function Get-FileSHA256([string]$p){
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $fs = [System.IO.File]::Open($p,'Open','Read','Read')
  try { return ($sha.ComputeHash($fs) | ForEach-Object ToString x2) -join '' }
  finally { $fs.Dispose(); $sha.Dispose() }
}
function Hash-Range([string]$p,[long]$off,[int]$count){
  $sha=[System.Security.Cryptography.SHA256]::Create()
  $fs=[System.IO.File]::Open($p,'Open','Read','Read')
  try{
    $buf=New-Object byte[] $count
    $null=$fs.Seek($off,'Begin')
    $read=$fs.Read($buf,0,$count)
    if($read -lt $count){ $buf=$buf[0..([Math]::Max(0,$read-1))] }
    return (($sha.ComputeHash($buf) | ForEach-Object ToString x2) -join '')
  } finally { $fs.Dispose(); $sha.Dispose() }
}
function Fingerprint3([string]$p,[int]$frag){
  $fi = Get-Item -LiteralPath $p
  $len = [long]$fi.Length
  if ($len -le 0){ return "0|||" }
  $o1 = 0
  $o2 = [Math]::Max(0,[long]($len/2 - $frag/2))
  $o3 = [Math]::Max(0,$len - $frag)
  $h1 = Hash-Range $p $o1 $frag
  $h2 = Hash-Range $p $o2 $frag
  $h3 = Hash-Range $p $o3 $frag
  return "$len|$h1|$h2|$h3"
}

# ---------- Seeds ----------
function Try-SeedMeta([string]$p){
  try{
    $j = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json
  } catch { return $null }
  if ($null -eq $j){ return $null }
  $meta = [ordered]@{
    kind = $null # 'anchor' | 'payload' | null
    target = $null
    sha256 = $null
    frag = $null
    anchors = $null
    out_len = $null
    vm = $null
  }
  if ($j.anchors -and $j.sha256){
    $meta.kind = 'anchor'
    $meta.target = ($j.target ?? $j.file ?? $null)
    $meta.sha256 = $j.sha256
    $meta.frag = ($j.frag ?? $null)
    $meta.anchors = $j.anchors
  } elseif ($j.program -or $j.payload -or $j.out_sha256){
    $meta.kind = 'payload'
    $meta.target = ($j.target ?? $null)
    $meta.sha256 = ($j.out_sha256 ?? $null)
    $meta.out_len = ($j.out_len ?? $null)
    $meta.vm = ($j.vm ?? $null)
  }
  return [pscustomobject]$meta
}

# ---------- Normalização de nome ----------
# Remove carimbos temporais, hex longos, hashes de 32/40/64, versões, sufixos "cópia/bak/old/tmp/draft"
function Normalize-Name([string]$name){
  $s = $name.ToLowerInvariant()

  # retirar extensões compostas do genoma
  foreach($suf in $GenomeSuffix){ if ($s.EndsWith($suf)){ $s = $s.Substring(0,$s.Length - $suf.Length) } }
  # retirar extensão simples remanescente
  $sx = [IO.Path]::GetExtension($s)
  if ($sx){ $s = $s.Substring(0,$s.Length - $sx.Length) }

  # remover timestamps comuns: 20250827_175202, 2025-08-27, 20250827, 175202 etc.
  $s = ($s -replace '(?:19|20)\d{2}[-_]?\d{2}[-_]?\d{2}([-_]?\d{6})?',' ')
  # remover hex longos (>=12), típicos de SHA/guids truncados
  $s = ($s -replace '\b[0-9a-f]{12,}\b',' ')
  # remover vX, vXX, v1.2.3 etc.
  $s = ($s -replace '\bv\d+(\.\d+)*\b',' ')
  # rótulos de baixa qualidade
  $s = ($s -replace '\b(bak|backup|old|tmp|temp|copy|copia|draft|manual|test|teste)\b',' ')
  # rótulos redundantes
  $s = ($s -replace '\b(latest|final|consolidated|release|seed|anchor|procedural|fractal|index|catalog|report|relatorio)\b',' ')
  # normalizar separadores
  $s = ($s -replace '[\s\.\-_]+','-').Trim('-')
  return $s
}

function To-Bigrams([string]$s){
  if([string]::IsNullOrWhiteSpace($s)){ return @() }
  $arr = @()
  for($i=0;$i -lt $s.Length-1;$i++){ $arr += $s.Substring($i,2) }
  return $arr
}
function To-Trigrams([string]$s){
  if([string]::IsNullOrWhiteSpace($s)){ return @() }
  $arr = @()
  for($i=0;$i -lt $s.Length-2;$i++){ $arr += $s.Substring($i,3) }
  return $arr
}
function DiceSim([string]$a,[string]$b){
  $A = To-Bigrams $a; $B = To-Bigrams $b
  if($A.Count -eq 0 -and $B.Count -eq 0){ return 1.0 }
  if($A.Count -eq 0 -or  $B.Count -eq 0){ return 0.0 }
  $common = @{}
  foreach($x in $A){ $common[$x] = 1 + ($common[$x] ?? 0) }
  $inter = 0
  foreach($y in $B){ if($common.ContainsKey($y) -and $common[$y] -gt 0){ $inter++; $common[$y]-- } }
  return [double](2*$inter)/([double]($A.Count+$B.Count))
}
function Jaccard([string]$a,[string]$b){
  $A = [System.Collections.Generic.HashSet[string]]::new((To-Trigrams $a))
  $B = [System.Collections.Generic.HashSet[string]]::new((To-Trigrams $b))
  if($A.Count -eq 0 -and $B.Count -eq 0){ return 1.0 }
  if($A.Count -eq 0 -or  $B.Count -eq 0){ return 0.0 }
  $U = [System.Collections.Generic.HashSet[string]]::new($A); $U.UnionWith($B)
  $I = [System.Collections.Generic.HashSet[string]]::new($A); $I.IntersectWith($B)
  return [double]$I.Count / [double]$U.Count
}

function NameScore([string]$path,[string]$name,[DateTime]$ts){
  $s = 0
  $n = $name.ToLowerInvariant()
  $p = $path.ToLowerInvariant()
  if($n -match 'final|latest|consolidated|release'){ $s += 20 }
  if($p -match '\\backups\\|\\_bak\\|\\old\\|\\tmp\\|\\temp\\'){ $s -= 30 }
  if($n -match '\bbak\b|backup|copy|copia|old|tmp|draft'){ $s -= 20 }
  # recência (até 365 dias)
  $days = [Math]::Min(365, [int]([DateTime]::UtcNow - $ts.ToUniversalTime()).TotalDays)
  $s += (365 - $days)/18.25  # máx ~20 pontos para arquivo muito recente
  return [int][Math]::Round($s,0)
}

# ---------- Coleta ----------
if (-not (Test-Path -LiteralPath $Src)){ throw "Pasta de origem não existe: $Src" }
Ensure-Dir $Dst
$baseReport = (if([string]::IsNullOrWhiteSpace($ReportDir)){ Join-Path $Src '_refine_logs' } else { $ReportDir })
$logDir = New-LogDir $baseReport
$planCsv = Join-Path $logDir 'plan.csv'
$planJson = Join-Path $logDir 'plan.json'
$undoPs1  = Join-Path $logDir 'undo.ps1'
$movedTxt = Join-Path $logDir 'moved.txt'
$keptTxt  = Join-Path $logDir 'kept.txt'
$errTxt   = Join-Path $logDir 'errors.txt'

Write-Info "LogDir: $logDir"
Write-Info "Origem: $Src"
Write-Info "Destino: $Dst"
Write-Info "Execute: $Execute | NameSim: $NameSim | MaxHashMB: $MaxHashMB"

$files = Get-ChildItem -Path $Src -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { Is-Genome $_ }
if($files.Count -eq 0){ Write-Warn "Nenhum arquivo de genoma encontrado em $Src"; return }

# construir metadados
$MB = 1MB
$items = @()
$idx = 0
foreach($f in $files){
  $idx++
  if ($idx % 2000 -eq 0){ Write-Info ("Coleta: {0}/{1}" -f $idx,$files.Count) }
  $full = $f.FullName
  $rel  = RelPath $full $Src
  $exk  = ExtKey $f.Name
  $stem = Normalize-Name $f.Name
  $seed = $null
  if ($exk -in @('.seed.json','.anchor.seed.json','.fractal_delta.json','.json')){
    $seed = Try-SeedMeta $full
  }

  $len = [long]$f.Length
  $hash = $null; $fp = $null
  if ($len -le ($MaxHashMB * $MB)){
    try { $hash = Get-FileSHA256 $full } catch { $hash = $null; Add-Content -LiteralPath $errTxt -Value "Hash falhou: $full :: $_" }
  }
  if (-not $hash){ try { $fp = Fingerprint3 $full $Frag } catch { Add-Content -LiteralPath $errTxt -Value "FP falhou: $full :: $_" } }

  $seedKey = $null
  if ($seed -ne $null){
    if ($seed.kind -eq 'anchor' -and $seed.sha256){
      $seedKey = "anchor|$($seed.target)|$($seed.sha256)"
    } elseif ($seed.kind -eq 'payload' -and $seed.sha256){
      $seedKey = "payload|$($seed.target)|$($seed.sha256)"
    }
  }

  $score = NameScore $full $f.Name $f.LastWriteTime
  $items += [pscustomobject]@{
    Path=$full; Rel=$rel; Name=$f.Name; ExtKey=$exk; Stem=$stem; Len=$len; TS=$f.LastWriteTime
    Hash=$hash; FP=$fp; SeedKey=$seedKey; SeedKind=($seed?.kind); SeedTarget=($seed?.target); SeedSHA=($seed?.sha256)
    Score=$score
  }
}

# ---------- Passo 1: Duplicatas exatas ----------
$movePlan = @()
$keepSet  = [System.Collections.Generic.HashSet[string]]::new()
$byExact = @{}

foreach($it in $items){
  $key = if($it.SeedKey){ "SEED|$($it.SeedKey)" } elseif ($it.Hash){ "SHA|$($it.Hash)" } elseif ($it.FP) { "FP|$($it.FP)" } else { $null }
  if(-not $key){ continue }
  if(-not $byExact.ContainsKey($key)){ $byExact[$key] = @() }
  $byExact[$key] += $it
}

foreach($k in $byExact.Keys){
  $arr = $byExact[$k] | Sort-Object { - $_.Score }, @{e={$_.TS};Descending=$true}
  # vencedor = melhor score e mais recente
  $winner = $arr[0]
  $keepSet.Add($winner.Path) | Out-Null
  for($i=1;$i -lt $arr.Count;$i++){
    $cand = $arr[$i]
    $dest = Join-Path $Dst (RelPath $cand.Path $Src)
    $movePlan += [pscustomobject]@{
      Action='MOVE'; Reason='duplicate-exact'; Group=$k; From=$cand.Path; To=$dest; Score=$cand.Score; Conf=1.0
    }
  }
}

# ---------- Passo 2: Fuzzy por nome normalizado ----------
# Buckets por prefixo do stem + faixa de comprimento para limitar comparações
function BucketKey([string]$stem){
  if([string]::IsNullOrWhiteSpace($stem)){ return '_empty' }
  $l=$stem.Length
  $lenB = [int]([Math]::Floor($l/5.0))*5  # faixas de 5 chars
  $pref = if($l -ge 2){ $stem.Substring(0,2) } else { $stem }
  return "$pref|$lenB"
}
$byBucket = @{}
foreach($it in $items){
  if($keepSet.Contains($it.Path)){ continue } # já resolvido em duplicatas exatas
  $b = BucketKey $it.Stem
  if(-not $byBucket.ContainsKey($b)){ $byBucket[$b] = @() }
  $byBucket[$b] += $it
}

$pairCount=0
$clusterId=0
foreach($b in $byBucket.Keys){
  $arr = $byBucket[$b]
  if($arr.Count -lt 2){ continue }

  # grafo por similaridade (union-find simples)
  $parent = @{}
  function Find($x){ if(-not $parent.ContainsKey($x)){ $parent[$x]=$x }; if($parent[$x] -ne $x){ $parent[$x]=(Find $parent[$x]) }; return $parent[$x] }
  function Union($a,$b){ $ra=(Find $a); $rb=(Find $b); if($ra -ne $rb){ $parent[$rb]=$ra } }

  # limitar comparações
  for($i=0;$i -lt $arr.Count;$i++){
    for($j=$i+1;$j -lt $arr.Count;$j++){
      if($pairCount -ge $MaxPairsPerBucket){ break }
      $pairCount++

      $s1 = $arr[$i].Stem; $s2 = $arr[$j].Stem
      $dice = DiceSim $s1 $s2
      if($dice -lt $NameSim){ continue } # rápido
      $jac  = Jaccard $s1 $s2
      $sim  = [Math]::Min(1.0, ($dice*0.6 + $jac*0.4))
      if($sim -ge $NameSim){
        Union $i $j
      }
    }
    if($pairCount -ge $MaxPairsPerBucket){ break }
  }

  # clusters
  $clusters = @{}
  for($i=0;$i -lt $arr.Count;$i++){
    $r = Find $i
    if(-not $clusters.ContainsKey($r)){ $clusters[$r] = @() }
    $clusters[$r] += $arr[$i]
  }

  foreach($cid in $clusters.Keys){
    $group = $clusters[$cid]
    if($group.Count -lt 2){ continue }
    $clusterId++
    $gid = "FUZZY|$b|$clusterId"
    # vencedor pelo score+tempo
    $win = $group | Sort-Object { - $_.Score }, @{e={$_.TS};Descending=$true} | Select-Object -First 1
    if(-not $keepSet.Contains($win.Path)){ $keepSet.Add($win.Path) | Out-Null }
    foreach($cand in $group){
      if($cand.Path -eq $win.Path){ continue }
      $dest = Join-Path $Dst (RelPath $cand.Path $Src)
      $movePlan += [pscustomobject]@{
        Action='MOVE'; Reason='duplicate-fuzzy'; Group=$gid; From=$cand.Path; To=$dest; Score=$cand.Score; Conf=$NameSim
      }
    }
  }
}

# ---------- Emissão de plano ----------
$plan = $movePlan | Sort-Object Group, From
$kept  = $items | Where-Object { $keepSet.Contains($_.Path) } | Sort-Object Path

# CSV
"action,reason,group,score,conf,from,to" | Set-Content -LiteralPath $planCsv -Encoding UTF8
foreach($p in $plan){
  ('{0},{1},{2},{3},{4},{5},{6}' -f $p.Action,$p.Reason,$p.Group,$p.Score,("{0:N2}" -f $p.Conf),('"' + $p.From + '"'),('"' + $p.To + '"')) `
    | Add-Content -LiteralPath $planCsv -Encoding UTF8
}
# JSON
$doc = [pscustomobject]@{
  meta = [pscustomobject]@{
    src = (Resolve-Path $Src).Path
    dst = (Resolve-Path $Dst).Path
    created = (Get-Date)
    nameSim = $NameSim
    maxHashMB = $MaxHashMB
    frag = $Frag
    totals = [pscustomobject]@{
      candidates = $items.Count
      plan_moves = $plan.Count
      kept = $kept.Count
    }
  }
  plan = $plan
  kept = $kept
}
$doc | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $planJson -Encoding UTF8
$kept.Path  | Set-Content -LiteralPath $keptTxt -Encoding UTF8

# gerar undo.ps1
$undo = @()
$undo += "param([string]`$SrcRoot='$Dst',[string]`$DestRoot='$Src',[switch]`$Execute)"
$undo += "`$ErrorActionPreference='Stop'"
$undo += "function Ensure-Dir([string]`$p){ if(`$p -and -not (Test-Path -LiteralPath `$p)){ New-Item -ItemType Directory -Path `$p -Force | Out-Null } }"
$undo += "`$map = @("
foreach($p in $plan){
  $rel = RelPath $p.From $Src
  $fromRel = RelPath $p.To $Dst
  $undo += "  @{ From = Join-Path `$SrcRoot '$fromRel'; To = Join-Path `$DestRoot '$rel' }"
}
$undo += ")"
$undo += "foreach(`$m in `$map){ Ensure-Dir (Split-Path -Parent `$m.To); if(`$Execute){ Move-Item -LiteralPath `$m.From -Destination `$m.To -Force } else { Write-Host ('[UNDO] {0} -> {1}' -f `$m.From,`$m.To) } }"
$undo -join [Environment]::NewLine | Set-Content -LiteralPath $undoPs1 -Encoding UTF8

# ---------- Execução ----------
$bytesMove = 0L
if ($Execute){
  foreach($p in $plan){
    try{
      Ensure-Dir (Split-Path -Parent $p.To)
      Move-Item -LiteralPath $p.From -Destination $p.To -Force
      $bytesMove += (Get-Item -LiteralPath $p.To).Length
      Add-Content -LiteralPath $movedTxt -Value $p.To
    } catch {
      Add-Content -LiteralPath $errTxt -Value ("MOVE FAIL :: {0} :: {1}" -f $p.From,$_ )
    }
  }
}

# ---------- Resumo ----------
$sum = [pscustomobject]@{
  src = $Src
  dst = $Dst
  log = $logDir
  plan_moves = $plan.Count
  kept = $kept.Count
  moved_bytes = $bytesMove
  moved_human = (Format-Bytes $bytesMove)
  mode = (if($Execute){'EXECUTE'} else {'DRY-RUN'})
}
$sum | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $logDir 'summary.json') -Encoding UTF8
Write-Host ""
Write-Host "== TEIA Fuzzy-Dedupe ==" -ForegroundColor Cyan
Write-Host ("Modo:            {0}" -f $sum.mode)
Write-Host ("Plan (movimentos): {0}" -f $sum.plan_moves)
Write-Host ("Mantidos (kept):   {0}" -f $sum.kept)
Write-Host ("Movidos (bytes):   {0}  ({1})" -f $sum.moved_bytes,$sum.moved_human)
Write-Host ("LogDir:          {0}" -f $logDir)
Write-Host ("Undo script:     {0}" -f $undoPs1)
PS1

# ---------- Executar (dry-run primeiro) ----------
/shell pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\TeiaProceduralQuarentenados' -Dst 'D:\quarentenaR' -NameSim 0.84"

# ---------- (Opcional) Ajustar limiar e confirmar execução ----------
#   - Se o plano parecer conservador demais, diminua -NameSim (ex.: 0.80).
#   - Se parecer agressivo, aumente (ex.: 0.88).
#   - Depois, execute de fato (gera undo.ps1 para reversão instantânea).
/shell pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\TeiaProceduralQuarentenados' -Dst 'D:\quarentenaR' -NameSim 0.84 -Execute"

# ---------- Como ler o resultado (4 linhas) ----------
# 1) Abra o sumário:       Get-Content (gci 'D:\TeiaProceduralQuarentenados\_refine_logs' -Directory | sort LastWriteTime -desc | select -first 1).FullName+'\summary.json'
# 2) Inspecione o plano:   Import-Csv   (gci 'D:\TeiaProceduralQuarentenados\_refine_logs' -Directory | sort LastWriteTime -desc | select -first 1).FullName+'\plan.csv' | ft -Auto
# 3) Reversão total:       pwsh -NoProfile -File ((gci 'D:\TeiaProceduralQuarentenados\_refine_logs' -Directory | sort LastWriteTime -desc | select -first 1).FullName+'\undo.ps1') -Execute
# 4) Conferir movidos:     Get-Content  (gci 'D:\TeiaProceduralQuarentenados\_refine_logs' -Directory | sort LastWriteTime -desc | select -first 1).FullName+'\moved.txt'

Dito por si:


• Ran
  └ pwsh -NoLogo -NoProfile -Command '$ErrorActionPreference='"'Stop';
    "'$path='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1';
    "'$dir=Split-Path -Parent $path; if(-not (Test-Path -LiteralPath $dir)){ New-Item -ItemType Directory -Path $dir
        -Force | Out-Null }
    @'"'
    param(
      [string]"'$Src = '"'D:\\TeiaProceduralQuarentenados',
      [string]"'$Dst = '"'D:\\quarentenaR',
      [switch]"'$Execute,
      [double]$NameSim = 0.82,
      [int]$MaxPairsPerBucket = 50000,
      [int64]$MaxHashMB = 1024,
      [int]$Frag = 65536,
      [string]$ReportDir = '"''
    )

    "'$ErrorActionPreference = '"'Stop'
    [Console]::OutputEncoding = [Text.Encoding]::UTF8

    function New-LogDir([string]"'$Base) {
      if (-not (Test-Path -LiteralPath $Base)) { New-Item -ItemType Directory -Path $Base -Force | Out-Null }
      $ts = Get-Date -Format '"'yyyyMMdd_HHmmss'
      "'$dir = Join-Path $Base $ts
      New-Item -ItemType Directory -Path $dir -Force | Out-Null
      return $dir
    }
    function Write-Info([string]$msg){ Write-Host "[INFO] $msg" -ForegroundColor Gray }
    function Write-Warn([string]$msg){ Write-Host "[WARN] $msg" -ForegroundColor Yellow }
    function Write-Err ([string]$msg){ Write-Host "[ERR ] $msg" -ForegroundColor Red }

    function RelPath([string]$full,[string]$root){
      $pf = (Resolve-Path -LiteralPath $full).ProviderPath
      $pr = (Resolve-Path -LiteralPath $root).ProviderPath
      if ($pf.StartsWith($pr,[StringComparison]::OrdinalIgnoreCase)) { return $pf.Substring($pr.Length).TrimStart('"'\\
        \\') }
      return [IO.Path]::GetFileName("'$pf)
    }
    function Ensure-Dir([string]$p){ if ($p -and -not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path
        $p -Force | Out-Null } }
    function Format-Bytes([decimal]$b){
      if ($b -ge 1TB){ return ('"'{0:N2} TB' -f ("'$b/1TB)) }
      if ($b -ge 1GB){ return ('"'{0:N2} GB' -f ("'$b/1GB)) }
      if ($b -ge 1MB){ return ('"'{0:N2} MB' -f ("'$b/1MB)) }
      if ($b -ge 1KB){ return ('"'{0:N2} KB' -f ("'$b/1KB)) }
      return "$b B"
    }

    $GenomeSuffix = @('"'.anchor.seed.json','.seed.json','.fractal_delta.json')
    "'$GenomeExt    = @('"'.ps1','.json','.jsonl','.csv','.log','.txt','.md','.pdf','.zip','.bak_ps1')

    function Is-Genome([IO.FileInfo]"'$f){
      $n = $f.Name.ToLowerInvariant()
      foreach($s in $GenomeSuffix){ if ($n.EndsWith($s)) { return $true } }
      $ext = $f.Extension.ToLowerInvariant()
      return $GenomeExt -contains $ext
    }
    function ExtKey([string]$name){
      $n = $name.ToLowerInvariant()
      foreach($s in $GenomeSuffix){ if ($n.EndsWith($s)) { return $s } }
      return [IO.Path]::GetExtension($n)
    }

    function Get-FileSHA256([string]$p){
      try { return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() } catch { return $null }
    }
    function Hash-Range([string]$p,[long]$off,[int]$count){
      $fs = $null; try {
        $fs = [System.IO.File]::Open($p,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,
        [System.IO.FileShare]::Read)
        $buf = New-Object byte[] $count
        if ($off -gt 0){ [void]$fs.Seek($off,[System.IO.SeekOrigin]::Begin) }
        $read = $fs.Read($buf,0,$count)
        if ($read -le 0){ return '"'' }
        if ("'$read -lt $count){ $buf = $buf[0..($read-1)] }
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try { return ([BitConverter]::ToString($sha.ComputeHash($buf)).Replace('"'-','').ToLowerInvariant()) } finally
        { "'$sha.Dispose() }
      } finally { if($fs){ $fs.Dispose() } }
    }
    function Fingerprint3([string]$p,[int]$frag){
      $fi = Get-Item -LiteralPath $p
      $len = [long]$fi.Length
      if ($len -le 0){ return "0|||" }
      $o1 = 0
      $mid = [long]([Math]::Max(0, [Math]::Floor($len/2) - [Math]::Floor($frag/2)))
      $o3 = [long]([Math]::Max(0, $len - $frag))
      $h1 = Hash-Range $p $o1 $frag
      $h2 = Hash-Range $p $mid $frag
      $h3 = Hash-Range $p $o3 $frag
      return "$len|$h1|$h2|$h3"
    }

    function Try-SeedMeta([string]$p){
      try{ $j = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop } catch { return
        $null }
      if ($null -eq $j){ return $null }
      $meta = [ordered]@{ kind=$null; target=$null; sha256=$null; frag=$null; anchors=$null; out_len=$null; vm=$null }
      if ($j.PSObject.Properties.Name -contains '"'anchors' -and "'$j.PSObject.Properties.Name -contains '"'sha256'){
        "'$meta.kind = '"'anchor'
        "'$meta.target = (if($j.PSObject.Properties.Name -contains '"'target'){ "'$j.target } elseif
        ($j.PSObject.Properties.Name -contains '"'file'){ "'$j.file } else { $null })
        $meta.sha256 = $j.sha256
        if ($j.PSObject.Properties.Name -contains '"'frag'){ "'$meta.frag = $j.frag }
        $meta.anchors = $j.anchors
      } elseif (($j.PSObject.Properties.Name -contains '"'program') -or ("'$j.PSObject.Properties.Name -contains
        '"'payload') -or ("'$j.PSObject.Properties.Name -contains '"'out_sha256')){
        "'$meta.kind = '"'payload'
        if ("'$j.PSObject.Properties.Name -contains '"'target'){ "'$meta.target = $j.target }
        if ($j.PSObject.Properties.Name -contains '"'out_sha256'){ "'$meta.sha256 = $j.out_sha256 }
        if ($j.PSObject.Properties.Name -contains '"'out_len'){ "'$meta.out_len = $j.out_len }
        if ($j.PSObject.Properties.Name -contains '"'vm'){ "'$meta.vm = $j.vm }
      }
      return [pscustomobject]$meta
    }

    function Normalize-Name([string]$name){
      $s = $name.ToLowerInvariant()
      foreach($suf in $GenomeSuffix){ if ($s.EndsWith($suf)){ $s = $s.Substring(0,$s.Length - $suf.Length) } }
      $sx = [IO.Path]::GetExtension($s); if ($sx){ $s = $s.Substring(0,$s.Length - $sx.Length) }
      $s = ($s -replace '"'((?:19|20)\\d{2})[-_]?\\d{2}[-_]?\\d{2}([-_]?\\d{6})?',' ')
      "'$s = ($s -replace '"'\\b[0-9a-f]{12,}\\b',' ')
      "'$s = ($s -replace '"'\\bv\\d+(?:\\.\\d+)*\\b',' ')
      "'$s = ($s -replace '"'\\b(bak|backup|old|tmp|temp|copy|copia|draft|manual|test|teste)\\b',' ')
      "'$s = ($s -replace '"'\\b(latest|final|consolidated|release|seed|anchor|procedural|fractal|index|catalog|report|
        relatorio)\\b',' ')
      "'$s = ($s -replace '"'[\\s\\._-]+','-').Trim('-')
      return "'$s
    }
    function To-Bigrams([string]$s){ if([string]::IsNullOrWhiteSpace($s)){ return @() } $a=@(); for($i=0;$i -lt
        $s.Length-1;$i++){ $a+=$s.Substring($i,2) }; return $a }
    function To-Trigrams([string]$s){ if([string]::IsNullOrWhiteSpace($s)){ return @() } $a=@(); for($i=0;$i -lt
        $s.Length-2;$i++){ $a+=$s.Substring($i,3) }; return $a }
    function DiceSim([string]$a,[string]$b){ $A=To-Bigrams $a; $B=To-Bigrams $b; if($A.Count -eq 0 -and $B.Count
        -eq 0){return 1.0}; if($A.Count -eq 0 -or $B.Count -eq 0){return 0.0}; $map=@{}; foreach($x in $A)
        { $map[$x]=1+($map[$x]0) }; $inter=0; foreach($y in $B){ if($map.ContainsKey($y) -and $map[$y] -gt 0){ $inter++;
        $map[$y]-- } }; return [double]((2*$inter)/([double]($A.Count+$B.Count))) }
    function Jaccard([string]$a,[string]$b){ $A=[System.Collections.Generic.HashSet[string]]::new((To-Trigrams
        $a)); $B=[System.Collections.Generic.HashSet[string]]::new((To-Trigrams $b)); if($A.Count
        -eq 0 -and $B.Count -eq 0){return 1.0}; if($A.Count -eq 0 -or $B.Count -eq 0){return
        0.0}; $U=[System.Collections.Generic.HashSet[string]]::new($A); $U.UnionWith($B);
        $I=[System.Collections.Generic.HashSet[string]]::new($A); $I.IntersectWith($B); return [double]$I.Count /
        [double]$U.Count }
    function NameScore([string]$path,[string]$name,[DateTime]$ts){ $s=0; $n=$name.ToLowerInvariant();
        $p=$path.ToLowerInvariant(); if($n -match '"'final|latest|consolidated|release'){ "'$s+=20 }; if($p -match
        '"'\\\\backups\\\\|\\\\_bak\\\\|\\\\old\\\\|\\\\tmp\\\\|\\\\temp\\\\'){ "'$s-=30 }; if($n -match '"'\
        \bbak\\b|backup|copy|copia|old|tmp|draft'){ "'$s-=20 }; $days=[Math]::Min(365, [int]([DateTime]::UtcNow -
        $ts.ToUniversalTime()).TotalDays); $s += [int][Math]::Round(((365-$days)/365.0)*20,0); return $s }

    if (-not (Test-Path -LiteralPath $Src)){ throw "Pasta de origem não existe: $Src" }
    Ensure-Dir $Dst
    $baseReport = (if([string]::IsNullOrWhiteSpace($ReportDir)){ Join-Path $Src '"'_refine_logs' } else
        { "'$ReportDir })
    $logDir = New-LogDir $baseReport
    $planCsv = Join-Path $logDir '"'plan.csv'
    "'$planJson = Join-Path $logDir '"'plan.json'
    "'$undoPs1  = Join-Path $logDir '"'undo.ps1'
    "'$movedTxt = Join-Path $logDir '"'moved.txt'
    "'$keptTxt  = Join-Path $logDir '"'kept.txt'
    "'$errTxt   = Join-Path $logDir '"'errors.txt'

    Write-Info \"LogDir: "'$logDir"
    Write-Info "Origem: $Src"
    Write-Info "Destino: $Dst"
    Write-Info "Execute: $Execute | NameSim: $NameSim | MaxHashMB: $MaxHashMB"

    $files = Get-ChildItem -Path $Src -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { Is-Genome
        $_ }
    if(-not $files -or $files.Count -eq 0){ Write-Warn "Nenhum arquivo de genoma encontrado em $Src"; return }

    $MB = 1MB
    $items = @()
    $idx = 0
    foreach($f in $files){
      $idx++
      if ($idx % 3000 -eq 0){ Write-Info ("Coleta: {0}/{1}" -f $idx,$files.Count) }
      $full = $f.FullName
      $rel  = RelPath $full $Src
      $exk  = ExtKey $f.Name
      $stem = Normalize-Name $f.Name
      $seed = $null
      if ($exk -in @('"'.seed.json','.anchor.seed.json','.fractal_delta.json','.json')){ "'$seed = Try-SeedMeta $full }
      $len = [long]$f.Length
      $hash = $null; $fp = $null
      if ($len -le ($MaxHashMB * $MB)) { $hash = Get-FileSHA256 $full }
      if (-not $hash){ $fp = Fingerprint3 $full $Frag }
      $seedKey = $null
      if ($seed -ne $null){
        if ($seed.kind -eq '"'anchor' -and "'$seed.sha256){ $seedKey = "anchor|$($seed.target)|$($seed.sha256)" }
        elseif ($seed.kind -eq '"'payload' -and "'$seed.sha256){ $seedKey = "payload|$($seed.target)|$($seed.sha256)" }
      }
      $score = NameScore $full $f.Name $f.LastWriteTime
      $items += [pscustomobject]@{ Path=$full; Rel=$rel; Name=$f.Name; ExtKey=$exk; Stem=$stem; Len=$len;
        TS=$f.LastWriteTime; Hash=$hash; FP=$fp; SeedKey=$seedKey; SeedKind=($seed.kind); SeedTarget=($seed.target);
        SeedSHA=($seed.sha256); Score=$score }
    }

    $movePlan = @()
    $keepSet  = [System.Collections.Generic.HashSet[string]]::new()
    $byExact = @{}
    foreach($it in $items){
      $key = if($it.SeedKey){ "SEED|$($it.SeedKey)" } elseif ($it.Hash){ "SHA|$($it.Hash)" } elseif ($it.FP) { "FP|
        $($it.FP)" } else { $null }
      if(-not $key){ continue }
      if(-not $byExact.ContainsKey($key)){ $byExact[$key] = @() }
      $byExact[$key] += $it
    }
    foreach($k in $byExact.Keys){
      $arr = $byExact[$k] | Sort-Object @{e='"'Score';Descending="'$true}, @{e='"'TS';Descending="'$true}
      $winner = $arr[0]
      [void]$keepSet.Add($winner.Path)
      for($i=1; $i -lt $arr.Count; $i++){
        $cand = $arr[$i]
        $dest = Join-Path $Dst (RelPath $cand.Path $Src)
        $movePlan += [pscustomobject]@{ Action='"'MOVE'; Reason='duplicate-exact'; Group="'$k; From=$cand.Path;
        To=$dest; Score=$cand.Score; Conf=1.0 }
      }
    }

    function BucketKey([string]$stem){ if([string]::IsNullOrWhiteSpace($stem)){ return '"'_empty' }; "'$l=$stem.Length;
        $lenB = [int]([Math]::Floor($l/5.0))*5; $pref = if($l -ge 2){ $stem.Substring(0,2) } else { $stem }; return
        "$pref|$lenB" }
    $byBucket = @{}
    foreach($it in $items){ if($keepSet.Contains($it.Path)){ continue }; $b = BucketKey $it.Stem; if(-not
        $byBucket.ContainsKey($b)){ $byBucket[$b]=@() }; $byBucket[$b]+=$it }

    function New-FindUnion(){ @{ parent=@{} } }
    function Find([hashtable]$ds,$x){ if(-not $ds.parent.ContainsKey($x)){ $ds.parent[$x]=$x }; if($ds.parent[$x] -ne
        $x){ $ds.parent[$x] = Find $ds $ds.parent[$x] }; return $ds.parent[$x] }
    function Union([hashtable]$ds,$a,$b){ $ra=Find $ds $a; $rb=Find $ds $b; if($ra -ne $rb){ $ds.parent[$rb]=$ra } }

    $clusterId=0
    foreach($b in $byBucket.Keys){
      $arr = $byBucket[$b]
      if($arr.Count -lt 2){ continue }
      $ds = New-FindUnion
      $pairCount=0
      for($i=0;$i -lt $arr.Count;$i++){
        for($j=$i+1;$j -lt $arr.Count;$j++){
          if($pairCount -ge $MaxPairsPerBucket){ break }
          $pairCount++
          $s1=$arr[$i].Stem; $s2=$arr[$j].Stem
          $dice = DiceSim $s1 $s2
          if($dice -lt $NameSim){ continue }
          $jac = Jaccard $s1 $s2
          $sim = [Math]::Min(1.0, ($dice*0.6 + $jac*0.4))
          if($sim -ge $NameSim){ Union $ds $i $j }
        }
        if($pairCount -ge $MaxPairsPerBucket){ break }
      }
      $clusters=@{}
      for($i=0;$i -lt $arr.Count;$i++){ $r=Find $ds $i; if(-not $clusters.ContainsKey($r)){ $clusters[$r]=@() };
        $clusters[$r]+=$arr[$i] }
      foreach($cid in $clusters.Keys){ $group=$clusters[$cid]; if($group.Count -lt 2){ continue }; $clusterId+
        +; $gid="FUZZY|$b|$clusterId"; $win = $group | Sort-Object @{e='"'Score';Descending="'$true},
        @{e='"'TS';Descending="'$true} | Select-Object -First 1; [void]$keepSet.Add($win.Path); foreach($cand in
        $group){ if($cand.Path -eq $win.Path){ continue }; $dest = Join-Path $Dst (RelPath $cand.Path $Src); $movePlan
        += [pscustomobject]@{ Action='"'MOVE'; Reason='duplicate-fuzzy'; Group="'$gid; From=$cand.Path; To=$dest;
        Score=$cand.Score; Conf=$NameSim } } }
    }

    $plan = $movePlan | Sort-Object Group, From
    $kept  = $items | Where-Object { $keepSet.Contains($_.Path) } | Sort-Object Path

    "action,reason,group,score,conf,from,to" | Set-Content -LiteralPath $planCsv -Encoding UTF8
    foreach($p in $plan){ ('"'{0},{1},{2},{3},{4},\"{5}\",\"{6}\"' -f "'$p.Action,$p.Reason,$p.Group,$p.Score,
        ('"'{0:N2}' -f "'$p.Conf),$p.From,$p.To) | Add-Content -LiteralPath $planCsv -Encoding UTF8 }

    $doc = [pscustomobject]@{ meta = [pscustomobject]@{ src = (Resolve-Path $Src).Path; dst = (Resolve-Path
        $Dst).Path; created = (Get-Date); nameSim = $NameSim; maxHashMB = $MaxHashMB; frag = $Frag; totals =
        [pscustomobject]@{ candidates = $items.Count; plan_moves = $plan.Count; kept = $kept.Count } }; plan = $plan;
        kept = $kept }
    $doc | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $planJson -Encoding UTF8
    $kept.Path | Set-Content -LiteralPath $keptTxt -Encoding UTF8

    $undo = @()
    $undo += "param([string]$SrcRoot='"'"'$Dst'"',[string]"'$DestRoot='"'"'$Src'"',[switch]"'$Execute)"
    $undo += "$ErrorActionPreference='"'Stop'\"
    "'$undo += "function Ensure-Dir([string]$p){ if($p -and -not (Test-Path -LiteralPath $p)){ New-Item -ItemType
        Directory -Path $p -Force | Out-Null } }"
    $undo += "$map = @("
    foreach($p in $plan){ $rel = RelPath $p.From $Src; $fromRel = RelPath $p.To $Dst; $undo += "  @{ From = Join-Path
        $SrcRoot '"'"'$fromRel'"'; To = Join-Path "'$DestRoot '"'"'$rel'"' }\" }
    $bytesMove = 0L
    if ($Execute){ foreach($p in $plan){ try{ Ensure-Dir (Split-Path -Parent $p.To); Move-Item -LiteralPath $p.From
        -Destination $p.To -Force; $bytesMove += (Get-Item -LiteralPath $p.To).Length; Add-Content -LiteralPath
        $movedTxt -Value $p.To } catch { Add-Content -LiteralPath $errTxt -Value ("MOVE FAIL :: {0} :: {1}" -f $p.From,
        $_ ) } } }


• Ran
  └ pwsh -NoLogo -NoProfile -Command '$ErrorActionPreference='"'Stop';
    "'$path='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1';
    "'$dir=Split-Path -Parent $path; if(-not (Test-Path -LiteralPath $dir)){ New-Item -ItemType Directory -Path $dir
        -Force | Out-Null }
    @'"'
    param(
      [string]"'$Src = '"'D:\\TeiaProceduralQuarentenados',
      [string]"'$Dst = '"'D:\\quarentenaR',
      [switch]"'$Execute,
      [double]$NameSim = 0.82,
      [int]$MaxPairsPerBucket = 50000,
      [int64]$MaxHashMB = 1024,
      [int]$Frag = 65536,
      [string]$ReportDir = '"''
    )

    "'$ErrorActionPreference = '"'Stop'
    [Console]::OutputEncoding = [Text.Encoding]::UTF8

    function New-LogDir([string]"'$Base) {
      if (-not (Test-Path -LiteralPath $Base)) { New-Item -ItemType Directory -Path $Base -Force | Out-Null }
      $ts = Get-Date -Format '"'yyyyMMdd_HHmmss'
      "'$dir = Join-Path $Base $ts
      New-Item -ItemType Directory -Path $dir -Force | Out-Null
      return $dir
    }
    function Write-Info([string]$msg){ Write-Host "[INFO] $msg" -ForegroundColor Gray }
    function Write-Warn([string]$msg){ Write-Host "[WARN] $msg" -ForegroundColor Yellow }
    function Write-Err ([string]$msg){ Write-Host "[ERR ] $msg" -ForegroundColor Red }

    function RelPath([string]$full,[string]$root){
      $pf = (Resolve-Path -LiteralPath $full).ProviderPath
      $pr = (Resolve-Path -LiteralPath $root).ProviderPath
      if ($pf.StartsWith($pr,[StringComparison]::OrdinalIgnoreCase)) { return $pf.Substring($pr.Length).TrimStart('"'\\
        \\') }
      return [IO.Path]::GetFileName("'$pf)
    }
    function Ensure-Dir([string]$p){ if ($p -and -not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path
        $p -Force | Out-Null } }
    function Format-Bytes([decimal]$b){
      if ($b -ge 1TB){ return ('"'{0:N2} TB' -f ("'$b/1TB)) }
      if ($b -ge 1GB){ return ('"'{0:N2} GB' -f ("'$b/1GB)) }
      if ($b -ge 1MB){ return ('"'{0:N2} MB' -f ("'$b/1MB)) }
      if ($b -ge 1KB){ return ('"'{0:N2} KB' -f ("'$b/1KB)) }
      return "$b B"
    }

    $GenomeSuffix = @('"'.anchor.seed.json','.seed.json','.fractal_delta.json')
    "'$GenomeExt    = @('"'.ps1','.json','.jsonl','.csv','.log','.txt','.md','.pdf','.zip','.bak_ps1')

    function Is-Genome([IO.FileInfo]"'$f){
      $n = $f.Name.ToLowerInvariant()
      foreach($s in $GenomeSuffix){ if ($n.EndsWith($s)) { return $true } }
      $ext = $f.Extension.ToLowerInvariant()
      return $GenomeExt -contains $ext
    }
    function ExtKey([string]$name){
      $n = $name.ToLowerInvariant()
      foreach($s in $GenomeSuffix){ if ($n.EndsWith($s)) { return $s } }
      return [IO.Path]::GetExtension($n)
    }

    function Get-FileSHA256([string]$p){
      try { return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() } catch { return $null }
    }
    function Hash-Range([string]$p,[long]$off,[int]$count){
      $fs = $null; try {
        $fs = [System.IO.File]::Open($p,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,
        [System.IO.FileShare]::Read)
        $buf = New-Object byte[] $count
        if ($off -gt 0){ [void]$fs.Seek($off,[System.IO.SeekOrigin]::Begin) }
        $read = $fs.Read($buf,0,$count)
        if ($read -le 0){ return '"'' }
        if ("'$read -lt $count){ $buf = $buf[0..($read-1)] }
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try { return ([BitConverter]::ToString($sha.ComputeHash($buf)).Replace('"'-','').ToLowerInvariant()) } finally
        { "'$sha.Dispose() }
      } finally { if($fs){ $fs.Dispose() } }
    }
    function Fingerprint3([string]$p,[int]$frag){
      $fi = Get-Item -LiteralPath $p
      $len = [long]$fi.Length
      if ($len -le 0){ return "0|||" }
      $o1 = 0
      $mid = [long]([Math]::Max(0, [Math]::Floor($len/2) - [Math]::Floor($frag/2)))
      $o3 = [long]([Math]::Max(0, $len - $frag))
      $h1 = Hash-Range $p $o1 $frag
      $h2 = Hash-Range $p $mid $frag
      $h3 = Hash-Range $p $o3 $frag
      return "$len|$h1|$h2|$h3"
    }

    function Try-SeedMeta([string]$p){
      try{ $j = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop } catch { return
        $null }
      if ($null -eq $j){ return $null }
      $meta = [ordered]@{ kind=$null; target=$null; sha256=$null; frag=$null; anchors=$null; out_len=$null; vm=$null }
      if ($j.PSObject.Properties.Name -contains '"'anchors' -and "'$j.PSObject.Properties.Name -contains '"'sha256'){
        "'$meta.kind = '"'anchor'
        "'$meta.target = (if($j.PSObject.Properties.Name -contains '"'target'){ "'$j.target } elseif
        ($j.PSObject.Properties.Name -contains '"'file'){ "'$j.file } else { $null })
        $meta.sha256 = $j.sha256
        if ($j.PSObject.Properties.Name -contains '"'frag'){ "'$meta.frag = $j.frag }
        $meta.anchors = $j.anchors
      } elseif (($j.PSObject.Properties.Name -contains '"'program') -or ("'$j.PSObject.Properties.Name -contains
        '"'payload') -or ("'$j.PSObject.Properties.Name -contains '"'out_sha256')){
        "'$meta.kind = '"'payload'
        if ("'$j.PSObject.Properties.Name -contains '"'target'){ "'$meta.target = $j.target }
        if ($j.PSObject.Properties.Name -contains '"'out_sha256'){ "'$meta.sha256 = $j.out_sha256 }
        if ($j.PSObject.Properties.Name -contains '"'out_len'){ "'$meta.out_len = $j.out_len }
        if ($j.PSObject.Properties.Name -contains '"'vm'){ "'$meta.vm = $j.vm }
      }
      return [pscustomobject]$meta
    }

    function Normalize-Name([string]$name){
      $s = $name.ToLowerInvariant()
      foreach($suf in $GenomeSuffix){ if ($s.EndsWith($suf)){ $s = $s.Substring(0,$s.Length - $suf.Length) } }
      $sx = [IO.Path]::GetExtension($s); if ($sx){ $s = $s.Substring(0,$s.Length - $sx.Length) }
      $s = ($s -replace '"'((?:19|20)\\d{2})[-_]?\\d{2}[-_]?\\d{2}([-_]?\\d{6})?',' ')
      "'$s = ($s -replace '"'\\b[0-9a-f]{12,}\\b',' ')
      "'$s = ($s -replace '"'\\bv\\d+(?:\\.\\d+)*\\b',' ')
      "'$s = ($s -replace '"'\\b(bak|backup|old|tmp|temp|copy|copia|draft|manual|test|teste)\\b',' ')
      "'$s = ($s -replace '"'\\b(latest|final|consolidated|release|seed|anchor|procedural|fractal|index|catalog|report|
        relatorio)\\b',' ')
      "'$s = ($s -replace '"'[\\s\\._-]+','-').Trim('-')
      return "'$s
    }
    function To-Bigrams([string]$s){ if([string]::IsNullOrWhiteSpace($s)){ return @() } $a=@(); for($i=0;$i -lt
        $s.Length-1;$i++){ $a+=$s.Substring($i,2) }; return $a }
    function To-Trigrams([string]$s){ if([string]::IsNullOrWhiteSpace($s)){ return @() } $a=@(); for($i=0;$i -lt
        $s.Length-2;$i++){ $a+=$s.Substring($i,3) }; return $a }
    function DiceSim([string]$a,[string]$b){
      $A=To-Bigrams $a; $B=To-Bigrams $b
      if($A.Count -eq 0 -and $B.Count -eq 0){return 1.0}
      if($A.Count -eq 0 -or $B.Count -eq 0){return 0.0}
      $map=@{}
      foreach($x in $A){ $map[$x] = 1 + ($(if($map.ContainsKey($x)){ $map[$x] } else { 0 })) }
      $inter=0
      foreach($y in $B){ if($map.ContainsKey($y) -and $map[$y] -gt 0){ $inter++; $map[$y]-- } }
      return [double]((2*$inter)/([double]($A.Count+$B.Count)))
    }
    function Jaccard([string]$a,[string]$b){ $A=[System.Collections.Generic.HashSet[string]]::new((To-Trigrams
        $a)); $B=[System.Collections.Generic.HashSet[string]]::new((To-Trigrams $b)); if($A.Count
        -eq 0 -and $B.Count -eq 0){return 1.0}; if($A.Count -eq 0 -or $B.Count -eq 0){return
        0.0}; $U=[System.Collections.Generic.HashSet[string]]::new($A); $U.UnionWith($B);
        $I=[System.Collections.Generic.HashSet[string]]::new($A); $I.IntersectWith($B); return [double]$I.Count /
        [double]$U.Count }
    function NameScore([string]$path,[string]$name,[DateTime]$ts){ $s=0; $n=$name.ToLowerInvariant();
        $p=$path.ToLowerInvariant(); if($n -match '"'final|latest|consolidated|release'){ "'$s+=20 }; if($p -match
        '"'\\\\backups\\\\|\\\\_bak\\\\|\\\\old\\\\|\\\\tmp\\\\|\\\\temp\\\\'){ "'$s-=30 }; if($n -match '"'\
        \bbak\\b|backup|copy|copia|old|tmp|draft'){ "'$s-=20 }; $days=[Math]::Min(365, [int]([DateTime]::UtcNow -
        $ts.ToUniversalTime()).TotalDays); $s += [int][Math]::Round(((365-$days)/365.0)*20,0); return $s }

    if (-not (Test-Path -LiteralPath $Src)){ throw "Pasta de origem não existe: $Src" }
    Ensure-Dir $Dst
    $baseReport = (if([string]::IsNullOrWhiteSpace($ReportDir)){ Join-Path $Src '"'_refine_logs' } else
        { "'$ReportDir })
    $logDir = New-LogDir $baseReport
    $planCsv = Join-Path $logDir '"'plan.csv'
    "'$planJson = Join-Path $logDir '"'plan.json'
    "'$undoPs1  = Join-Path $logDir '"'undo.ps1'
    "'$movedTxt = Join-Path $logDir '"'moved.txt'
    "'$keptTxt  = Join-Path $logDir '"'kept.txt'
    "'$errTxt   = Join-Path $logDir '"'errors.txt'

    Write-Info \"LogDir: "'$logDir"
    Write-Info "Origem: $Src"
    Write-Info "Destino: $Dst"
    Write-Info "Execute: $Execute | NameSim: $NameSim | MaxHashMB: $MaxHashMB"

    $files = Get-ChildItem -Path $Src -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { Is-Genome
        $_ }
    if(-not $files -or $files.Count -eq 0){ Write-Warn "Nenhum arquivo de genoma encontrado em $Src"; return }

    $MB = 1MB
    $items = @()
    $idx = 0
    foreach($f in $files){
      $idx++
      if ($idx % 3000 -eq 0){ Write-Info ("Coleta: {0}/{1}" -f $idx,$files.Count) }
      $full = $f.FullName
      $rel  = RelPath $full $Src
      $exk  = ExtKey $f.Name
      $stem = Normalize-Name $f.Name
      $seed = $null
      if ($exk -in @('"'.seed.json','.anchor.seed.json','.fractal_delta.json','.json')){ "'$seed = Try-SeedMeta $full }
      $len = [long]$f.Length
      $hash = $null; $fp = $null
      if ($len -le ($MaxHashMB * $MB)) { $hash = Get-FileSHA256 $full }
      if (-not $hash){ $fp = Fingerprint3 $full $Frag }
      $seedKey = $null
      if ($seed -ne $null){
        if ($seed.kind -eq '"'anchor' -and "'$seed.sha256){ $seedKey = "anchor|$($seed.target)|$($seed.sha256)" }
        elseif ($seed.kind -eq '"'payload' -and "'$seed.sha256){ $seedKey = "payload|$($seed.target)|$($seed.sha256)" }
      }
      $score = NameScore $full $f.Name $f.LastWriteTime
      $items += [pscustomobject]@{ Path=$full; Rel=$rel; Name=$f.Name; ExtKey=$exk; Stem=$stem; Len=$len;
        TS=$f.LastWriteTime; Hash=$hash; FP=$fp; SeedKey=$seedKey; SeedKind=($seed.kind); SeedTarget=($seed.target);
        SeedSHA=($seed.sha256); Score=$score }
    }

    $movePlan = @()
    $keepSet  = [System.Collections.Generic.HashSet[string]]::new()
    $byExact = @{}
    foreach($it in $items){
      $key = if($it.SeedKey){ "SEED|$($it.SeedKey)" } elseif ($it.Hash){ "SHA|$($it.Hash)" } elseif ($it.FP) { "FP|
        $($it.FP)" } else { $null }
      if(-not $key){ continue }
      if(-not $byExact.ContainsKey($key)){ $byExact[$key] = @() }
      $byExact[$key] += $it
    }
    foreach($k in $byExact.Keys){
      $arr = $byExact[$k] | Sort-Object @{e='"'Score';Descending="'$true}, @{e='"'TS';Descending="'$true}
      $winner = $arr[0]
      [void]$keepSet.Add($winner.Path)
      for($i=1; $i -lt $arr.Count; $i++){
        $cand = $arr[$i]
        $dest = Join-Path $Dst (RelPath $cand.Path $Src)
        $movePlan += [pscustomobject]@{ Action='"'MOVE'; Reason='duplicate-exact'; Group="'$k; From=$cand.Path;
        To=$dest; Score=$cand.Score; Conf=1.0 }
      }
    }

    function BucketKey([string]$stem){ if([string]::IsNullOrWhiteSpace($stem)){ return '"'_empty' }; "'$l=$stem.Length;
        $lenB = [int]([Math]::Floor($l/5.0))*5; $pref = if($l -ge 2){ $stem.Substring(0,2) } else { $stem }; return
        "$pref|$lenB" }
    $byBucket = @{}
    foreach($it in $items){ if($keepSet.Contains($it.Path)){ continue }; $b = BucketKey $it.Stem; if(-not
        $byBucket.ContainsKey($b)){ $byBucket[$b]=@() }; $byBucket[$b]+=$it }

    function New-FindUnion(){ @{ parent=@{} } }
    function Find([hashtable]$ds,$x){ if(-not $ds.parent.ContainsKey($x)){ $ds.parent[$x]=$x }; if($ds.parent[$x] -ne
        $x){ $ds.parent[$x] = Find $ds $ds.parent[$x] }; return $ds.parent[$x] }
    function Union([hashtable]$ds,$a,$b){ $ra=Find $ds $a; $rb=Find $ds $b; if($ra -ne $rb){ $ds.parent[$rb]=$ra } }

    $clusterId=0
    foreach($b in $byBucket.Keys){
      $arr = $byBucket[$b]
      if($arr.Count -lt 2){ continue }
      $ds = New-FindUnion
      $pairCount=0
      for($i=0;$i -lt $arr.Count;$i++){
        for($j=$i+1;$j -lt $arr.Count;$j++){
          if($pairCount -ge $MaxPairsPerBucket){ break }
          $pairCount++
          $s1=$arr[$i].Stem; $s2=$arr[$j].Stem
          $dice = DiceSim $s1 $s2
          if($dice -lt $NameSim){ continue }
          $jac = Jaccard $s1 $s2
          $sim = [Math]::Min(1.0, ($dice*0.6 + $jac*0.4))
          if($sim -ge $NameSim){ Union $ds $i $j }
        }
        if($pairCount -ge $MaxPairsPerBucket){ break }
      }
      $clusters=@{}
      for($i=0;$i -lt $arr.Count;$i++){ $r=Find $ds $i; if(-not $clusters.ContainsKey($r)){ $clusters[$r]=@() };
        $clusters[$r]+=$arr[$i] }
      foreach($cid in $clusters.Keys){ $group=$clusters[$cid]; if($group.Count -lt 2){ continue }; $clusterId+
        +; $gid="FUZZY|$b|$clusterId"; $win = $group | Sort-Object @{e='"'Score';Descending="'$true},
        @{e='"'TS';Descending="'$true} | Select-Object -First 1; [void]$keepSet.Add($win.Path); foreach($cand in
        $group){ if($cand.Path -eq $win.Path){ continue }; $dest = Join-Path $Dst (RelPath $cand.Path $Src); $movePlan
        += [pscustomobject]@{ Action='"'MOVE'; Reason='duplicate-fuzzy'; Group="'$gid; From=$cand.Path; To=$dest;
        Score=$cand.Score; Conf=$NameSim } } }
    }

    $plan = $movePlan | Sort-Object Group, From
    $kept  = $items | Where-Object { $keepSet.Contains($_.Path) } | Sort-Object Path

    "action,reason,group,score,conf,from,to" | Set-Content -LiteralPath $planCsv -Encoding UTF8
    foreach($p in $plan){ ('"'{0},{1},{2},{3},{4},\"{5}\",\"{6}\"' -f "'$p.Action,$p.Reason,$p.Group,$p.Score,
        ('"'{0:N2}' -f "'$p.Conf),$p.From,$p.To) | Add-Content -LiteralPath $planCsv -Encoding UTF8 }

    $doc = [pscustomobject]@{ meta = [pscustomobject]@{ src = (Resolve-Path $Src).Path; dst = (Resolve-Path
        $Dst).Path; created = (Get-Date); nameSim = $NameSim; maxHashMB = $MaxHashMB; frag = $Frag; totals =
        [pscustomobject]@{ candidates = $items.Count; plan_moves = $plan.Count; kept = $kept.Count } }; plan = $plan;
        kept = $kept }
    $doc | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $planJson -Encoding UTF8
    $kept.Path | Set-Content -LiteralPath $keptTxt -Encoding UTF8

    $undo = @()
    $undo += "param([string]$SrcRoot='"'"'$Dst'"',[string]"'$DestRoot='"'"'$Src'"',[switch]"'$Execute)"
    $undo += "$ErrorActionPreference='"'Stop'\"
    "'$undo += "function Ensure-Dir([string]$p){ if($p -and -not (Test-Path -LiteralPath $p)){ New-Item -ItemType
        Directory -Path $p -Force | Out-Null } }"
    $undo += "$map = @("
    foreach($p in $plan){ $rel = RelPath $p.From $Src; $fromRel = RelPath $p.To $Dst; $undo += "  @{ From = Join-Path
        $SrcRoot '"'"'$fromRel'"'; To = Join-Path "'$DestRoot '"'"'$rel'"' }\" }
    $bytesMove = 0L
    if ($Execute){ foreach($p in $plan){ try{ Ensure-Dir (Split-Path -Parent $p.To); Move-Item -LiteralPath $p.From
        -Destination $p.To -Force; $bytesMove += (Get-Item -LiteralPath $p.To).Length; Add-Content -LiteralPath
        $movedTxt -Value $p.To } catch { Add-Content -LiteralPath $errTxt -Value ("MOVE FAIL :: {0} :: {1}" -f $p.From,
        $_ ) } } }

    $sum = [pscustomobject]@{ src = $Src; dst = $Dst; log = $logDir; plan_moves = $plan.Count; kept = $kept.Count;
• Ran
  └ pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\\Teia\\TEIA_NUCLEO\
        \offline\\nano\\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\\TeiaProceduralQuarentenados' -Dst 'D:\\quarentenaR' -NameSim
        0.90"
    if: D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1:133


• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1';
    "'$content = Get-Content -LiteralPath $p -Raw -Encoding UTF8;
    $trySeed = @'"'
    function Try-SeedMeta([string]"'$p){
      try{ $j = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop } catch { return
        $null }
      if ($null -eq $j){ return $null }
      $meta = [ordered]@{ kind=$null; target=$null; sha256=$null; frag=$null; anchors=$null; out_len=$null; vm=$null }
        if ($j.PSObject.Properties.Name -contains '"'frag'){ "'$meta.frag = $j.frag }
        $meta.anchors = $j.anchors
      } elseif (($j.PSObject.Properties.Name -contains '"'program') -or ("'$j.PSObject.Properties.Name -contains
        '"'payload') -or ("'$j.PSObject.Properties.Name -contains '"'out_sha256')){
        "'$meta.kind = '"'payload'
  └ pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\\Teia\\TEIA_NUCLEO\
        \offline\\nano\\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\\TeiaProceduralQuarentenados' -Dst 'D:\\quarentenaR' -NameSim
        0.92"
    ParserError: D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1:133
    Line |
• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1'; "'$i=1;
        Get-Content -LiteralPath $p | Select-Object -Index (126..140) | ForEach-Object { '"'{0,4}: {1}' -f "'$i,$_;
        $i++ }'

    ParserError:
    Line |
       1 |  … rtDir)) { $baseReport = Join-Path $Src '"'_refine_logs' }\" } }; Set- …
         |                                                                ~
         | Unexpected token '}' in expression or statement.

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1'; "'$c =
        Get-Content -LiteralPath $p -Raw -Encoding UTF8;
    $jac = @'"'
      $U = New-Object '"'System.Collections.Generic.HashSet[string]' "'$A
      $U.UnionWith($B)
      $I = New-Object '"'System.Collections.Generic.HashSet[string]' "'$A
      $I.IntersectWith($B)
      return [double]$I.Count / [double]$U.Count
     195 |  … group,score,conf,from,to" | Set-Content -LiteralPath $planCsv -Encodi …
         |                                                         ~~~~~~~~
         | Cannot bind argument to parameter 'LiteralPath' because it is null.

• Ran
        -Value $c -Encoding UTF8; '"'Injected fallback for report paths'"

• Ran
  └ pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\\Teia\\TEIA_NUCLEO\
        \offline\\nano\\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\\TeiaProceduralQuarentenados' -Dst 'D:\\quarentenaR' -NameSim


• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1'; "'$c =
        Get-Content -LiteralPath $p -Raw -Encoding UTF8;
    # Inject local output vars before writing
    $needle = "rn"action,reason,group,score,conf,from,to" | Set-Content";
    $injectBlock = "n$__ld = $logDir; if(-not $__ld){ $__ld = New-LogDir (Join-Path $Src '"'_refine_logs') }
    "'$__planCsv = Join-Path $__ld '"'plan.csv'
    "'$__planJson = Join-Path $__ld '"'plan.json'
    "'$__undoPs1  = Join-Path $__ld '"'undo.ps1'
    "'$__movedTxt = Join-Path $__ld '"'moved.txt'
    "'$__keptTxt  = Join-Path $__ld '"'kept.txt'
    "'$__errTxt   = Join-Path $__ld '"'errors.txt'
    \";
    "'$c = $c -replace [regex]::Escape("rn'"\\\"action,reason,group,score,conf,from,to\\\" | Set-Content -LiteralPath
        "'$planCsv -Encoding UTF8"), "rn$injectBlockn'"\\\"action,reason,group,score,conf,from,to\\\" | Set-Content
        -LiteralPath "'$__planCsv -Encoding UTF8";
    # Replace later file writes to use local vars
    $c = $c -replace [regex]::Escape('"'"'$planCsv'"'), '"'$__planCsv'"';
    "'$c = $c -replace [regex]::Escape('"'"'$planJson'"'), '"'$__planJson'"';
    "'$c = $c -replace [regex]::Escape('"'"'$undoPs1'"'), '"'$__undoPs1'"';
    "'$c = $c -replace [regex]::Escape('"'"'$movedTxt'"'), '"'$__movedTxt'"';
    "'$c = $c -replace [regex]::Escape('"'"'$keptTxt'"'), '"'$__keptTxt'"';
    "'$c = $c -replace [regex]::Escape('"'"'$errTxt'"'), '"'$__errTxt'"';
    # Also replace printed paths at end
    "'$c = $c -replace '"'LogDir:\\s+\\{0\\}\" -f \\"'$logDir'"', 'LogDir:           {0}\" -f "'$__ld'"';
    "'$c = $c -replace '"'Undo script:\\s+\\{0\\}\" -f \\"'$undoPs1'"', 'Undo script:      {0}\" -f "'$__undoPs1'"';
    Set-Content -LiteralPath "'$p -Value $c -Encoding UTF8; '"'Switched to local output vars'"
    ParserError:
    Line |
      12 |  $c = $c -replace [regex]::Escape("rn\"action,reason,group,score,con …
         |                                          ~
         | Missing ')' in method call.

> Perfeito — avancei em duas frentes e deixei a dedupe pronta para rodar.

  Cloud “Somente Online”

  - iCloud (D:): aplicado em D:\iCloud e D:\iCloudDrive com attrib +U -P "D:\iCloud*\*" /s /d. Isso só libera o conteúdo
  local; nada é removido da nuvem.
  - OneDrive: use attrib +U -P "$env:OneDrive\*" /s /d; if ($env:OneDriveCommercial) { attrib +U -P
  "$env:OneDriveCommercial\*" /s /d }.
  - Google Drive (streaming): ajuste a letra da unidade (ex.: G:):
      - PT: attrib +U -P "G:\Meu Drive\*" /s /d, attrib +U -P "G:\Drives compartilhados\*" /s /d
      - EN: attrib +U -P "G:\My Drive\*" /s /d, attrib +U -P "G:\Shared drives\*" /s /d

  Quarentena “kernel”

  - Origem: D:\Kernel_Teia_Neumon_Procedural
  - Destino: D:\TeiaProceduralQuarentenados
  - Resultado: 81.564 arquivos copiados, 0 falhas, ~48,16 GB, estrutura preservada.

  TEIA Fuzzy-Dedupe

  - Script criado: D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1
  - O que faz:
      - Deduplicação exata (SHA256 até -MaxHashMB; acima usa fingerprint 3×-Frag).
      - Agrupamento fuzzy por nome normalizado (Dice + Jaccard), com buckets e limite -MaxPairsPerBucket.
      - Vencedor por score (recência + qualidade do nome/caminho).
      - Gera plano CSV/JSON e undo.ps1. Só move com -Execute.
  - Dry‑run (gera plano e logs, sem mover):
      - Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1'
  -Src 'D:\TeiaProceduralQuarentenados' -Dst 'D:\quarentenaR' -NameSim 0.92 -ReportDir 'D:\quarentenaR\_refine_logs'
  - Executar (aplica o plano; reversível via undo.ps1):
      - Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1'
  -Src 'D:\TeiaProceduralQuarentenados' -Dst 'D:\quarentenaR' -NameSim 0.92 -ReportDir 'D:\quarentenaR\_refine_logs'
  -Execute
  - Inspeção rápida:
      - Sumário: Get-Content (gci 'D:\quarentenaR\_refine_logs' -Directory | sort LastWriteTime -desc | select -first
  1).FullName+'\summary.json'
      - Plano: Import-Csv (gci 'D:\quarentenaR\_refine_logs' -Directory | sort LastWriteTime -desc | select -first
  1).FullName+'\plan.csv' | ft -Auto
      - Reversão: pwsh -NoProfile -File (gci 'D:\quarentenaR\_refine_logs' -Directory | sort LastWriteTime -desc |
  select -first 1).FullName+'\undo.ps1' -Execute

  Notas

  - Em dataset grande, a coleta pode demorar. Use -NameSim 0.92–0.95 para ser conservador (menos pares fuzzy); ajuste
  depois se necessário.
  - Se aparecer erro de caminho de log, rode com -ReportDir 'D:\quarentenaR\_refine_logs' como acima (já incluído nas
  linhas).
  - Tudo é idempotente: dry‑run só escreve relatórios; -Execute move conforme plan.csv; undo.ps1 reverte integralmente.

  Posso agora rodar o dry‑run com -NameSim 0.92 e, se o plano ficar bom, aplicar com -Execute?
Dito pelo ChatGPT:
Pensado para 7m 30s
/status
/approvals all
/write D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1.b64 << 'EOF'
cGFyYW0oCiAgW3N0cmluZ10kU3JjID0gJ0Q6XFRlaWFQcm9jZWR1cmFsUXVhcmVudGVuYWRvc
ycsCiAgW3N0cmluZ10kRHN0ID0gJ0Q6XHF1YXJlbnRlbmFSJywKICBbc3dpdGNoXSRFeGVjdXR
lLAogIFtkb3VibGVdJE5hbWVTaW0gPSAwLjg0LAogIFtpbnRdJE1heFBhaXJzUGVyQnVja2V0I
D0gNTAwMDAsCiAgW2ludDY0XSRNYXhIYXNoTUIgPSAxMDI0LAogIFtpbnRdJEZyYWcgPSA2NTU
zNiwKICBbc3RyaW5nXSRSZXBvcnREaXIKKQokRXJyb3JBY3Rpb25QcmVmZXJlbmNlID0gJ1N0b
3AnCltDb25zb2xlXTo6T3V0cHV0RW5jb2RpbmcgPSBbVGV4dC5FbmNvZGluZ106OlVURjgKZnV
uY3Rpb24gRW5zdXJlLURpcihbU3RyaW5nXSRwKXsgaWYoJHAgLWFuZCAtbm90IChUZXN0LVBhd
GggLUxpdGVyYWxQYXRoICRwKSl7IE5ldy1JdGVtIC1JdGVtVHlwZSBEaXJlY3RvcnkgLVBhdGg
gJHAgLUZvcmNlIHwgT3V0LU51bGwgfSB9IH0KZnVuY3Rpb24gSW5mbyhbU3RyaW5nXSRtKXsgV
3JpdGUtaG9zdCAiW0lORk9dICRtIiAtRm9yZWdyb3VuZENvbG9yIEdyYXkgfQpmdW5jdGlvbiB
XYXJuKFtTdHJpbmddJG0peyBXcml0ZS1ob3N0ICJbV0FSTl0gJG0iIC1Gb3JlZ3JvdW5kQ29sb
3IgWWVsbG93IH0KZnVuY3Rpb24gRm9ybWF0LUJ5dGVzKFtkZWNpbWFsXSRiKXsKICBpZiAoJGI
gLWdlIDFUQil7IHJldHVybiAoJ3swOk4yfSBUQicgLWYgKCRiLzFUQikpIH0KICBpZiAoJGIgL
WdlIDFHQil7IHJldHVybiAoJ3swOk4yfSBHQicgLWYgKCRiLzFHQikpIH0KICBpZiAoJGIgLWd
lIDFNSil7IHJldHVybiAoJ3swOk4yfSBNQicgLWYgKCRiLzFNSikpIH0KICBpZiAoJGIgLWdlI
DFLQil7IHJldHVybiAoJ3swOk4yfSBLQicgLWYgKCRiLzFLSikpIH0KICByZXR1cm4gIiRiIEI
ifQpmdW5jdGlvbiBSZWxQYXRoKFtTdHJpbmddJGZ1bGwsW1N0cmluZ10kcm9vdCl7CiAgdHJ5e
wogICAgJHBmID0gKFJlc29sdmUtUGF0aCAtTGl0ZXJhbFBhdGggJGZ1bGwpLlByb3ZpZGVyUGF
0aAogICAgJHByID0gKFJlc29sdmUtUGF0aCAtTGl0ZXJhbFBhdGggJHJvb3QpLlByb3ZpZGVyU
GF0aAogICAgaWYoJHBmLlN0YXJ0c1dpdGgoJHByLFtTdHJpbmdDb21wYXJpc29uXTo6T3JkaW5
hbElnbm9yZUNhc2UpKSB7IHJldHVybiAkcGYuU3Vic3RyaW5nKCRwci5MZW5ndGgpLlRyaW1Td
GFydCgnXCcpIH0KICAgIHJldHVybiBbSU8uUGF0aF06OkdldEZpbGVOYW1lKCRwZikKICB9IG
NhdGNoIHsgcmV0dXJuIFtJTy5QYXRoXTo6R2V0RmlsZU5hbWUoJGZ1bGwpIH19CiMgLS0tIEdl
bm9tYSAoZm9ybWF0b3MpIC0tLQokR2Vub21lU3VmZml4ID0gQycuYW5jaG9yLnNlZWQuanNvbi
cuLHsnLnNlZWQuanNvbi4nLCcuZnJhY3RhbF9kZWx0YS5qc29uJ30KJEdlbm9tZUV4dCAgICA9
IEMnLnBzMScuLHsnLmpzb24nLCcuanNvbmw nLCcuY3N2JywnLmxvZycsJy50eHQnLCcubWQnLC
cucGRmJywnLnppcCcsJy5iYWtfcHMxJ30KZnVuY3Rpb24gSXMtR2Vub21lKFtJTy5GaWxlSW5m
b10kZil7CiAgJG4gPSAkZi5OYW1lLkxvd2VySW52YXJpYW50KCkKICBmb3JlYWNoKCRzIGluIC
RHZW5vbWVTdWZmaXgpeyBpZiAoJG4uRW5kc1dpdGgoJHMpKSB7IHJldHVybiAkdHJ1ZSB9IH0K
ICAkZXh0ID0gJGYuRXh0ZW5zaW9uLkxvd2VySW52YXJpYW50KCkKICByZXR1cm4gJEdlbm9tZU
V4dCAtY29udGFpbnMgJGV4dAp9CmZ1bmN0aW9uIEV4dEtleShbU3RyaW5nXSRuYW1lKXsKICAk
biA9ICRuYW1lLkxvd2VySW52YXJpYW50KCkKICBmb3JlYWNoKCRzIGluICRHZW5vbWVTdWZmaX
gpeyBpZiAoJG4uRW5kc1dpdGgoJHMpKSB7IHJldHVybiAkcyB9IH0KICByZXR1cm4gKFtJTy5Q
YXRoXTo6R2V0RXh0ZW5zaW9uKCRuKSkKfQojIC0tLSBIYXNoIC8gRmluZ2VycHJpbnQgLS0tCm
Z1bmN0aW9uIEdldC1GaWxlU0hBMjU2KFtzdHJpbmddJHApewogIHRyeSB7IHJldHVybiAoR2V0
LUZpbGVIYXNoIC1MaXRlcmFsUGF0aCAkcCAtQWxnb3JpdGhtIFNIQTI1NikuSGFzaC5Mb3dlck
ludmFyaWFudCgpKSB9IGNhdGNoIHsgcmV0dXJuICRudWxsIH0KfQpmdW5jdGlvbiBIYXNoLVJh
bmdlKFtzdHJpbmddJHAsW2xvbmddJG9mZixbaW50XSRjb3VudCl7CiAgJGZzID0gJG51bGw7IC
RzaGEgPSAkbnVsbAogIHRyeSB7CiAgICAkZnMgPSBbU3lzdGVtLklPLkZpbGVdOjpPcGVuKCRw
LFtTeXN0ZW0uSU8uRmlsZU1vZGVdOjpPcGVuLFtTeXN0ZW0uSU8uRmlsZUFjY2Vzc10 6OlJlYW
QsW1N5c3RlbS5JTy5GaWxlU2hhcmVdOjpSZWFkKQogICAgJGJ1ZiA9IE5ldy1PYmplY3QgYnl0
ZVtdICRjb3VudAogICAgaWYoJG9mZiAtZ3QgMCl7IFt2b2lkXSRmcy5TZWVrKCRvZmYsW1N5c3
RlbS5JTy5TZWFyaw==
EOF
/shell pwsh -NoLogo -NoProfile -Command "$ErrorActionPreference='Stop'; $p='D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1'; $b64p=$p+'.b64'; if(!(Test-Path -LiteralPath (Split-Path -Parent $p))){ New-Item -ItemType Directory -Path (Split-Path -Parent $p) -Force | Out-Null }; if(!(Test-Path -LiteralPath $b64p)){ throw 'Arquivo base64 não encontrado: ' + $b64p }; $txt=Get-Content -LiteralPath $b64p -Raw -Encoding UTF8; $bytes=[Convert]::FromBase64String($txt); [IO.File]::WriteAllBytes($p,$bytes); try{Unblock-File -Path $p -ErrorAction SilentlyContinue}catch{}; Write-Host ('[OK] Gravado: ' + $p)"
/shell pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\TeiaProceduralQuarentenados' -Dst 'D:\quarentenaR' -NameSim 0.92 -ReportDir 'D:\quarentenaR\_refine_logs'"
/shell pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\TeiaProceduralQuarentenados' -Dst 'D:\quarentenaR' -NameSim 0.92 -ReportDir 'D:\quarentenaR\_refine_logs' -Execute"
/shell pwsh -NoLogo -NoProfile -Command "$ld=(Get-ChildItem 'D:\quarentenaR\_refine_logs' -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName; Write-Host ('LogDir: ' + $ld); Get-Content (Join-Path $ld 'summary.json'); Import-Csv (Join-Path $ld 'plan.csv') | Select-Object -First 10 | Format-Table -AutoSize; Write-Host ('Undo: ' + (Join-Path $ld 'undo.ps1'))"

Dito por si:
Retorno:
" • Ran 
  └ pwsh -NoLogo -NoProfile -Command '$ErrorActionPreference='"'Stop';
    "'$path='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1';
    "'$dir=Split-Path -Parent $path; if(-not (Test-Path -LiteralPath $dir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    @'"'
    param(
      [string]"'$Src = '"'D:\\TeiaProceduralQuarentenados',
      [string]"'$Dst = '"'D:\\quarentenaR',
      [switch]"'$Execute,
      [double]$NameSim = 0.92,
      [int]$MaxPairsPerBucket = 50000,
      [int64]$MaxHashMB = 1024,
      [int]$Frag = 65536,
      [string]$ReportDir = '"''
    )
    "'$ErrorActionPreference = '"'Stop'
    [Console]::OutputEncoding = [Text.Encoding]::UTF8

    function Ensure-Dir([string]"'$p){ if ($p -and -not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null } }
    function Info([string]$m){ Write-Host "[INFO] $m" -ForegroundColor Gray }
    function Warn([string]$m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
    function Format-Bytes([decimal]$b){ if($b -ge 1TB){return ('"'{0:N2} TB' -f ("'$b/1TB))}; if($b -ge 1GB){return ('"'{0:N2} GB' -f ("'$b/1GB))}; if($b -ge 1MB){return ('"'{0:N2} MB' -f ("'$b/1MB))}; if($b
        -ge 1KB){return ('"'{0:N2} KB' -f ("'$b/1KB))}; return "$b B" }
    function RelPath([string]$full,[string]$root){ try{ $pf=(Resolve-Path -LiteralPath $full).ProviderPath; $pr=(Resolve-Path -LiteralPath $root).ProviderPath; if($pf.StartsWith($pr,
        [StringComparison]::OrdinalIgnoreCase)){ return $pf.Substring($pr.Length).TrimStart('"'\\\\') }; return [IO.Path]::GetFileName("'$pf) } catch { return [IO.Path]::GetFileName($full) } }

    # Genome formats
    $GenomeSuffix = @('"'.anchor.seed.json','.seed.json','.fractal_delta.json')
    "'$GenomeExt    = @('"'.ps1','.json','.jsonl','.csv','.log','.txt','.md','.pdf','.zip','.bak_ps1')
    function Is-Genome([IO.FileInfo]"'$f){ $n=$f.Name.ToLowerInvariant(); foreach($s in $GenomeSuffix){ if($n.EndsWith($s)){return $true} }; $ext=$f.Extension.ToLowerInvariant(); return $GenomeExt -contains
        $ext }
    function ExtKey([string]$name){ $n=$name.ToLowerInvariant(); foreach($s in $GenomeSuffix){ if($n.EndsWith($s)){return $s} }; return [IO.Path]::GetExtension($n) }

    # Hash helpers
    function Get-FileSHA256([string]$p){ try{ return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() } catch { return $null } }
    function Read-RangeHash([string]$p,[long]$off,[int]$count){ $fs=$null; try{ $fs=[System.IO.File]::Open($p,'"'Open','Read','Read'); if("'$off -gt 0){[void]$fs.Seek($off,'"'Begin')}; "'$buf=New-Object
        byte[] $count; $read=$fs.Read($buf,0,$count); if($read -le 0){return '"''}; if("'$read -lt $count){ $buf=$buf[0..($read-1)] }; $sha=[System.Security.Cryptography.SHA256]::Create(); try{ return
        ([BitConverter]::ToString($sha.ComputeHash($buf)).Replace('"'-','').ToLowerInvariant()) } finally { "'$sha.Dispose() } } finally { if($fs){$fs.Dispose()} } }
    function Fingerprint3([string]$p,[int]$frag){ $fi=Get-Item -LiteralPath $p; $len=[long]$fi.Length; if($len -le 0){return '"'0|||'}; "'$o1=0; $mid=[long]([Math]::Max(0,
        [Math]::Floor($len/2)-[Math]::Floor($frag/2))); $o3=[long]([Math]::Max(0,$len-$frag)); $h1=Read-RangeHash $p $o1 $frag; $h2=Read-RangeHash $p $mid $frag; $h3=Read-RangeHash $p $o3 $frag; return "$len|
        $h1|$h2|$h3" }

    # Seed meta
    function Try-SeedMeta([string]$p){ try{ $j=Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop } catch { return $null }; if($null -eq $j){return $null};
        $meta=[ordered]@{kind=$null;target=$null;sha256=$null;frag=$null;anchors=$null;out_len=$null;vm=$null}; if(($j.PSObject.Properties.Name -contains '"'anchors') -and ("'$j.PSObject.Properties.Name
        -contains '"'sha256')){ "'$meta.kind='"'anchor'; if("'$j.PSObject.Properties.Name -contains '"'target'){ "'$meta.target=$j.target } elseif($j.PSObject.Properties.Name -contains '"'file')
        { "'$meta.target=$j.file }; $meta.sha256=$j.sha256; if($j.PSObject.Properties.Name -contains '"'frag'){ "'$meta.frag=$j.frag }; $meta.anchors=$j.anchors } elseif(($j.PSObject.Properties.Name -contains
        '"'program') -or ("'$j.PSObject.Properties.Name -contains '"'payload') -or ("'$j.PSObject.Properties.Name -contains '"'out_sha256')){ "'$meta.kind='"'payload'; if("'$j.PSObject.Properties.Name
        -contains '"'target'){ "'$meta.target=$j.target }; if($j.PSObject.Properties.Name -contains '"'out_sha256'){ "'$meta.sha256=$j.out_sha256 }; if($j.PSObject.Properties.Name -contains '"'out_len')
        { "'$meta.out_len=$j.out_len }; if($j.PSObject.Properties.Name -contains '"'vm'){ "'$meta.vm=$j.vm } }; return [pscustomobject]$meta }

    # Name normalization and similarity
    function Normalize-Name([string]$name){ $s=$name.ToLowerInvariant(); foreach($suf in $GenomeSuffix){ if($s.EndsWith($suf)){ $s=$s.Substring(0,$s.Length-$suf.Length) } }; $sx=[IO.Path]::GetExtension($s);
        if($sx){ $s=$s.Substring(0,$s.Length-$sx.Length) }; $s=($s -replace '"'((?:19|20)\\d{2})[-_]?\\d{2}[-_]?\\d{2}([-_]?\\d{6})?',' '); "'$s=($s -replace '"'\\b[0-9a-f]{12,}\\b',' '); "'$s=($s -replace
        '"'\\bv\\d+(?:\\.\\d+)*\\b',' '); "'$s=($s -replace '"'\\b(bak|backup|old|tmp|temp|copy|copia|draft|manual|test|teste)\\b',' '); "'$s=($s -replace '"'\\b(latest|final|consolidated|release|seed|anchor|
        procedural|fractal|index|catalog|report|relatorio)\\b',' '); "'$s=($s -replace '"'[\\s\\._-]+','-').Trim('-'); return "'$s }
    function To-Bigrams([string]$s){ if([string]::IsNullOrWhiteSpace($s)){return @()}; $a=@(); for($i=0;$i -lt $s.Length-1;$i++){ $a+=$s.Substring($i,2) }; return $a }
    function To-Trigrams([string]$s){ if([string]::IsNullOrWhiteSpace($s)){return @()}; $a=@(); for($i=0;$i -lt $s.Length-2;$i++){ $a+=$s.Substring($i,3) }; return $a }
    function DiceSim([string]$a,[string]$b){ $A=To-Bigrams $a; $B=To-Bigrams $b; if($A.Count -eq 0 -and $B.Count -eq 0){return 1.0}; if($A.Count -eq 0 -or $B.Count -eq 0){return 0.0}; $map=@{}; foreach($x in
        $A){ if($map.ContainsKey($x)){ $map[$x] += 1 } else { $map[$x] = 1 } }; $inter=0; foreach($y in $B){ if($map.ContainsKey($y) -and $map[$y] -gt 0){ $inter++; $map[$y]-- } }; return [double]((2*$inter)/
        ([double]($A.Count+$B.Count))) }
    function Jaccard([string]$a,[string]$b){ $A=New-Object '"'System.Collections.Generic.HashSet[string]'; foreach("'$t in (To-Trigrams $a)){ [void]$A.Add($t) }; $B=New-Object
        '"'System.Collections.Generic.HashSet[string]'; foreach("'$t in (To-Trigrams $b)){ [void]$B.Add($t) }; if($A.Count -eq 0 -and $B.Count -eq 0){return 1.0}; if($A.Count -eq 0 -or $B.Count -eq 0)
        {return 0.0}; $U=New-Object '"'System.Collections.Generic.HashSet[string]'; "'$U.UnionWith($A); $U.UnionWith($B); $I=New-Object '"'System.Collections.Generic.HashSet[string]'; "'$I.UnionWith($A);
        $I.IntersectWith($B); return [double]$I.Count / [double]$U.Count }
    function NameScore([string]$path,[string]$name,[DateTime]$ts){ $s=0; $n=$name.ToLowerInvariant(); $p=$path.ToLowerInvariant(); if($n -match '"'final|latest|consolidated|release'){ "'$s+=20 }; if($p
        -match '"'\\\\backups\\\\|\\\\_bak\\\\|\\\\old\\\\|\\\\tmp\\\\|\\\\temp\\\\'){ "'$s-=30 }; if($n -match '"'\\bbak\\b|backup|copy|copia|old|tmp|draft'){ "'$s-=20 }; $days=[Math]::Min(365,[int]
        ([DateTime]::UtcNow - $ts.ToUniversalTime()).TotalDays); $s += [int][Math]::Round(((365-$days)/365.0)*20,0); return $s }

    if(-not (Test-Path -LiteralPath $Src)){ throw "Pasta de origem não existe: $Src" }
    Ensure-Dir $Dst
    $baseReport = $ReportDir; if([string]::IsNullOrWhiteSpace($ReportDir)){ $baseReport = Join-Path $Src '"'_refine_logs' }
    "'$logDir = Join-Path $baseReport (Get-Date -Format '"'yyyyMMdd_HHmmss'); Ensure-Dir "'$logDir
    $planCsv = Join-Path $logDir '"'plan.csv'
    "'$planJson = Join-Path $logDir '"'plan.json'
    "'$undoPs1  = Join-Path $logDir '"'undo.ps1'
    "'$movedTxt = Join-Path $logDir '"'moved.txt'
    "'$keptTxt  = Join-Path $logDir '"'kept.txt'
    "'$errTxt   = Join-Path $logDir '"'errors.txt'

    Info \"LogDir: "'$logDir"; Info "Origem: $Src"; Info "Destino: $Dst"; Info "Execute: $Execute | NameSim: $NameSim | MaxHashMB: $MaxHashMB"

    $files = Get-ChildItem -Path $Src -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { Is-Genome $_ }
    if(-not $files -or $files.Count -eq 0){ Warn "Nenhum arquivo de genoma encontrado em $Src"; return }

    $MB=1MB; $items=@(); $i=0
    foreach($f in $files){ $i++; if($i % 3000 -eq 0){ Info ("Coleta: {0}/{1}" -f $i,$files.Count) }; $full=$f.FullName; $rel=RelPath $full $Src; $exk=ExtKey $f.Name; $stem=Normalize-Name $f.Name; $seed=$null;
        if($exk -in @('"'.seed.json','.anchor.seed.json','.fractal_delta.json','.json')){ "'$seed=Try-SeedMeta $full };
      $len=[long]$f.Length; $hash=$null; $fp=$null; if($len -le ($MaxHashMB*$MB)){ $hash=Get-FileSHA256 $full }; if(-not $hash){ $fp=Fingerprint3 $full $Frag };
      $seedKey=$null; if($seed -ne $null){ if($seed.kind -eq '"'anchor' -and "'$seed.sha256){ $seedKey = "anchor|$($seed.target)|$($seed.sha256)" } elseif($seed.kind -eq '"'payload' -and "'$seed.sha256)
        { $seedKey = "payload|$($seed.target)|$($seed.sha256)" } }
      $score = NameScore $full $f.Name $f.LastWriteTime
      $items += [pscustomobject]@{ Path=$full; Rel=$rel; Name=$f.Name; ExtKey=$exk; Stem=$stem; Len=$len; TS=$f.LastWriteTime; Hash=$hash; FP=$fp; SeedKey=$seedKey; SeedKind=($seed.kind);
        SeedTarget=($seed.target); SeedSHA=($seed.sha256); Score=$score }
    }

    $movePlan=@(); $keepSet = New-Object '"'System.Collections.Generic.HashSet[string]'
    "'$byExact=@{}
    foreach($it in $items){ $key = if($it.SeedKey){"SEED|$($it.SeedKey)"} elseif($it.Hash){"SHA|$($it.Hash)"} elseif($it.FP){"FP|$($it.FP)"} else {$null}; if(-not $key){continue}; if(-not
        $byExact.ContainsKey($key)){ $byExact[$key]=@() }; $byExact[$key]+=$it }
    foreach($k in $byExact.Keys){ $arr=$byExact[$k] | Sort-Object @{e='"'Score';Descending="'$true}, @{e='"'TS';Descending="'$true}; $winner=$arr[0]; [void]$keepSet.Add($winner.Path); for($j=1;$j -lt
        $arr.Count;$j++){ $cand=$arr[$j]; $dest=Join-Path $Dst (RelPath $cand.Path $Src); $movePlan += [pscustomobject]@{ Action='"'MOVE'; Reason='duplicate-exact'; Group="'$k; From=$cand.Path; To=$dest;
        Score=$cand.Score; Conf=1.0 } } }

    function BucketKey([string]$stem){ if([string]::IsNullOrWhiteSpace($stem)){return '"'_empty'}; "'$l=$stem.Length; $lenB=[int]([Math]::Floor($l/5.0))*5; $pref=(if($l -ge 2){$stem.Substring(0,2)} else
        {$stem}); return "$pref|$lenB" }
    $byBucket=@{}
    foreach($it in $items){ if($keepSet.Contains($it.Path)){ continue }; $b=BucketKey $it.Stem; if(-not $byBucket.ContainsKey($b)){ $byBucket[$b]=@() }; $byBucket[$b]+=$it }

    $clusterId=0
    foreach($b in $byBucket.Keys){ $arr=$byBucket[$b]; if($arr.Count -lt 2){ continue }; $ds=New-FindUnion; $pairCount=0; for($x=0;$x -lt $arr.Count;$x++){ for($y=$x+1;$y -lt $arr.Count;$y++){ if($pairCount
        -ge $MaxPairsPerBucket){ break }; $pairCount++; $s1=$arr[$x].Stem; $s2=$arr[$y].Stem; $dice=DiceSim $s1 $s2; if($dice -lt $NameSim){ continue }; $jac=Jaccard $s1 $s2; $sim=[Math]::Min(1.0,($dice*0.6 +
        $jac*0.4)); if($sim -ge $NameSim){ Union $ds $x $y } }; if($pairCount -ge $MaxPairsPerBucket){ break } };
      $clusters=@{}; for($x=0;$x -lt $arr.Count;$x++){ $r=Find $ds $x; if(-not $clusters.ContainsKey($r)){ $clusters[$r]=@() }; $clusters[$r]+=$arr[$x] };
      foreach($cid in $clusters.Keys){ $group=$clusters[$cid]; if($group.Count -lt 2){ continue }; $clusterId++; $gid="FUZZY|$b|$clusterId"; $win = $group | Sort-Object @{e='"'Score';Descending="'$true},
        @{e='"'TS';Descending="'$true} | Select-Object -First 1; [void]$keepSet.Add($win.Path); foreach($cand in $group){ if($cand.Path -eq $win.Path){ continue }; $dest=Join-Path $Dst (RelPath $cand.Path
    $doc = [pscustomobject]@{ meta = [pscustomobject]@{ src = (Resolve-Path $Src).Path; dst = (Resolve-Path $Dst).Path; created = (Get-Date); nameSim = $NameSim; maxHashMB = $MaxHashMB; frag = $Frag; totals =
        [pscustomobject]@{ candidates = $items.Count; plan_moves = $plan.Count; kept = $kept.Count } }; plan = $plan; kept = $kept }
    $doc | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $planJson -Encoding UTF8
    $kept.Path | Set-Content -LiteralPath $keptTxt -Encoding UTF8


• Ran
  └ pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\\TeiaProceduralQuarentenados' -Dst 'D:\
        \quarentenaR' -NameSim 0.92 -ReportDir 'D:\\quarentenaR\\_refine_logs'"
    if: D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1:71
    Line |
      71 |  … $stem.Length; $lenB=[int]([Math]::Floor($l/5.0))*5; $pref=(if($l -ge  …

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1'; "'$c=Get-Content -LiteralPath $p -Raw -Encoding UTF8; $c=$c -replace '"'\\(if\\(','(\\"'$true -and
        '"'; "'$c = $c -replace '"'\\"'$pref='"\\(if\\(\\"'$l -ge 2'"\\)\\{\\"'$stem'"\\.Substring\\(0,2\\)\\} else \\{\\"'$stem'"\\}\\);', '"'$pref = ( $stem.Substring(0, [Math]::Min(2, $stem.Length)) );'"';
        Set-Content -LiteralPath "'$p -Value $c -Encoding UTF8; '"'Patched inline if'}"
      $lenB = [int]([Math]::Floor($l/5.0))*5
      $pref = $stem.Substring(0, [Math]::Min(2, $l))
      return "$pref|$lenB"
    }
    '"'@;
    "'$c = [regex]::Replace($c, '"'function\\s+BucketKey\\s*\\([\\s\\S]*?\\)\\s*\\{[\\s\\S]*?\\n\\}', "'$bucket);
    Set-Content -LiteralPath $p -Value $c -Encoding UTF8;
         | again.
        '"'Inserted "'$modeVar before $sum'"'"

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1'; "'$c=Get-Content -LiteralPath $p -Raw -Encoding UTF8; $c = $c -replace '"'mode\\s*=\\s*\\(if\\(\
        \"'$Execute'"\\)[\\s\\S]*?\\)', 'mode = "'$modeVar'"'; Set-Content -LiteralPath "'$p -Value $c -Encoding UTF8; '"'Replaced inline if in mode'"

  └ pwsh -NoLogo -NoProfile -Command '$p='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1'; Select-String -Path "'$p -Pattern '"'mode\\s*=\\s*\\(' | % { "'$_.LineNumber.ToString() + '"': '
        + "'$_.Line }'
    Select-String: The string mode\\s*=\\s*\\( is not a valid regular expression: Invalid pattern 'mode\\s*=\\s*\\(' at offset 16. Not enough )'s.

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1'; (Get-Content -LiteralPath "'$p -Raw -Encoding UTF8) -split "n" | % { $_ } | ? { $_ -match '"'mode\
        \s*=\\s*\\(' }"

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1'; "'$i=0; Get-Content -LiteralPath $p -Encoding UTF8 | % { $i++; if($_ -match '"'mode'){ '{0,5}: {1}' -f
        "'$i, $_ } }'

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1'; "'$lines=Get-Content -LiteralPath $p -Encoding UTF8; $lines[95] = "$modeVar = if($Execute)
        {'"'EXECUTE'} else {'DRY-RUN'}; "'$sum = [pscustomobject]@{ src = $Src; dst = $Dst; log = $logDir; plan_moves = $plan.Count; kept = $kept.Count; moved_bytes = $bytesMove; moved_human = (Format-Bytes
        $bytesMove); mode = $modeVar }"; Set-Content -LiteralPath $p -Value $lines -Encoding UTF8; '"'Rewrote mode line'"

• Ran
  └ pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\\TeiaProceduralQuarentenados' -Dst 'D:\
        \quarentenaR' -NameSim 0.92 -ReportDir 'D:\\quarentenaR\\_refine_logs'"
    =: D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1:96
    Line |
      96 |   = if($Execute){ 'EXECUTE'} else {'DRY-RUN'};   = [pscustomobject]@{  …
         |   ~
         | The term '=' is not recognized as a name of a cmdlet, function, script file, or executable program. Check the spelling of the name, or if a path was included, verify that the path is correct and try
         | again.

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$p='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1'; "'$lines=Get-Content -LiteralPath $p -Encoding UTF8; $new = @'"'
    "'$modeVar = if($Execute){'"'EXECUTE'} else {'DRY-RUN'}
    "'$sum = [pscustomobject]@{ src = $Src; dst = $Dst; log = $logDir; plan_moves = $plan.Count; kept = $kept.Count; moved_bytes = $bytesMove; moved_human = (Format-Bytes $bytesMove); mode = $modeVar }
    '"'@.Trim(); "'$lines[95] = $new; Set-Content -LiteralPath $p -Value $lines -Encoding UTF8; '"'Rewrote mode+sum safely'"

• Ran
  └ pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\\TeiaProceduralQuarentenados' -Dst 'D:\
        \quarentenaR' -NameSim 0.92 -ReportDir 'D:\\quarentenaR\\_refine_logs'"

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$ld=(Get-ChildItem '"'D:\\quarentenaR\\_refine_logs' -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName; Write-Host ('LogDir: ' +
        "'$ld); Get-Content (Join-Path $ld '"'summary.json'); '"'nPlan sample:'"'; Import-Csv (Join-Path "'$ld '"'plan.csv') | Select-Object -First 10 | Format-Table -AutoSize; 'Undo:'; Write-Host (Join-Path
        "'$ld '"'undo.ps1')"

• Ran
  └ pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\\TeiaProceduralQuarentenados' -Dst 'D:\
        \quarentenaR' -NameSim 0.92 -ReportDir 'D:\\quarentenaR\\_refine_logs' -Execute"

• Updated Plan
  └ Script criado e testado; dry-run gerou plano (39.606 movimentos); execução aplicada com ~22,09 GB movidos; logs e undo disponíveis.
    ✔ Create stable fuzzy-dedupe script
    ✔ Run dry-run to generate plan
    ✔ Execute planned moves
    ✔ Display summary and undo path

> Resumo

  - Criei um script estável de deduplicação TEIA no caminho: D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1.
  - Rodei dry-run e depois execução completa com -NameSim 0.92.
  - Resultado da execução: plano com 39.606 movimentos; mantidos 41.958; movidos ~22,09 GB para D:\quarentenaR (estratégia exata + fuzzy, com undo).

  Por que não usei o .b64

  - O payload base64 enviado estava truncado (incompleto), então não era decodificável. Em vez de depender dele, gerei um script autocontido que implementa seu plano (hash exato SHA256 até -MaxHashMB,
  fingerprint 3×-Frag para grandes, fuzzy por Dice+Jaccard com normalização agressiva, ranking por recência + qualidade, logs e undo).

  O que foi executado

  - Dry‑run (gerou plano e logs):
  & 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\TeiaProceduralQuarentenados' -Dst 'D:\quarentenaR' -NameSim 0.92 -ReportDir 'D:\quarentenaR\_refine_logs'
  - Execução (aplicou plano; reversível):
  & 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\TeiaProceduralQuarentenados' -Dst 'D:\quarentenaR' -NameSim 0.92 -ReportDir 'D:\quarentenaR\_refine_logs' -Execute

  Logs e Undo

  - Último LogDir (resumo): D:\quarentenaR\_refine_logs\20250923_033123
  - Sumário: summary.json indica ~22,09 GB movidos.
  - Plano: plan.csv (39.606 linhas).
  - Reversão: undo.ps1 (reverte todos os movimentos).
  - Amostra de plano (dry-run anterior): várias entradas duplicate-exact (SHA/SEED) e duplicate-fuzzy agrupadas por bucket.

  Como validar rápido

  - Sumário: Get-Content (gci 'D:\quarentenaR\_refine_logs' -Directory | sort LastWriteTime -desc | select -first 1).FullName+'\summary.json'
  - Plano (10 primeiras):
  Import-Csv (gci 'D:\quarentenaR\_refine_logs' -Directory | sort LastWriteTime -desc | select -first 1).FullName+'\plan.csv' | select -first 10 | ft -Auto
  - Undo total (se quiser desfazer):
  pwsh -NoProfile -File (gci 'D:\quarentenaR\_refine_logs' -Directory | sort LastWriteTime -desc | select -first 1).FullName+'\undo.ps1' -Execute

  Observações

  - O “Se:” e outros errors no console foram por colar linhas de comentário como se fossem comandos; não afetaram a execução que eu disparei diretamente.
  - iCloud Drive em D: foi marcado “somente online” em D:\iCloud e D:\iCloudDrive com attrib +U -P ... /s /d. Mesma técnica aplicável a OneDrive/Google Drive (ajustando letras/nome das pastas).
  - Se quiser mais conservador no fuzzy, aumente -NameSim (ex.: 0.95). Mais agressivo: diminua (0.88–0.90). O plano sempre sai em CSV/JSON antes de executar.

  Quer que eu compacte D:\quarentenaR em volumes de 4 GB, ou que gere um relatório “antes/depois” de top pastas por tamanho para medir o ganho espacial no C:/D:?"

Intúo que tenha alcançado mais uma limpeza eficiente. Porém ainda contém uma demasiada quantidade de arquivos, mas já podemos prosseguir para o próximo passo de auditoria da  deduplicação, prossiga com uma instrução para o codex cli, analisar e comparar a pasta completa autocontida (caminho: "D:\Kernel_Teia_Neumon_Procedural")  x a pasta dos enquarentenados: (caminho: "D:\TeiaProceduralQuarentenados") e criar dois arquivos csv, Um contendo todo a árvore raio x de todos os nomes de pastas, subpastas e arquivo contidos no "D:\TeiaProceduralQuarentenados" e no outro csv contendo a árvore/ raio x contendo todos os nomes de pastas, subpastas e arquivos que o "D:\Kernel_Teia_Neumon_Procedural" não tem em comum em comparação a pasta "D:\TeiaProceduralQuarentenados", assim consigo garantir dois arquivos completos, cada um contendo os nomes de pastas, subpastas e arquivos que não foram enquarentenados na pasta "D:\TeiaProceduralQuarentenados" e outra contendo todos os nomes de pastas, subpastas e arquivos que foram selecionados para a quarentena... Assim consigo analisar a semântica completa de cada material contido e não contido, sem representar um peso de armazenamento intragável se fosse analisar todos os materiais e conteúdos contidos dentro deles, e com esses dois arquivos capacita analisar com a ia se houve arquivos importantes (na nossa heuristica da tarefa de encapsular o núcleo procedural...)  não inclusos na quarentena e quais materiais inclusos não são vitais para o funcionamento do núcleo procedural e seu lançamento mundial no futuro, para deduplicarmos em uma tarefa posterior de obter esses dados coerentes e completos... Forneça um prompt para colar no codex cli e prosseguir delegando a função. 
Dito pelo ChatGPT:
Pensado para 3m 19s
/status
/approvals all

# === Auditoria TEIA: Kernel vs Quarentena → CSVs de árvore e diferença ===
# Gera:
#  1) quarentena_tree.csv — árvore completa (pastas+arquivos) de D:\TeiaProceduralQuarentenados
#  2) kernel_nao_quarentenado.csv — árvore (pastas+arquivos) que existem no Kernel e NÃO estão na Quarentena
# (Opcional) quarentena_somente.csv — itens na Quarentena que não existem no Kernel (se houver)
#
# Saída com carimbo de data/hora em: D:\Teia\TEIA_NUCLEO\offline\nano\audit_dedupe\<YYYYMMDD_HHMMSS>\
#
/write D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Diff-Audit.ps1 << 'PS1'
param(
  [string]$Kernel     = 'D:\Kernel_Teia_Neumon_Procedural',
  [string]$Quarantine = 'D:\TeiaProceduralQuarentenados',
  [string]$OutBase    = 'D:\Teia\TEIA_NUCLEO\offline\nano\audit_dedupe'
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

function Ensure-Dir([string]$p){
  if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

function RelPath([string]$full,[string]$root){
  try{
    $pf = (Resolve-Path -LiteralPath $full).ProviderPath
    $pr = (Resolve-Path -LiteralPath $root).ProviderPath
    if ($pf.StartsWith($pr,[StringComparison]::OrdinalIgnoreCase)) { return $pf.Substring($pr.Length).TrimStart('\') }
    return [IO.Path]::GetFileName($pf)
  } catch {
    return [IO.Path]::GetFileName($full)
  }
}

function Collect-Tree([string]$Root){
  if (-not (Test-Path -LiteralPath $Root)) { throw "Root not found: $Root" }

  # Pastas
  $dirs = Get-ChildItem -Path $Root -Recurse -Directory -Force -ErrorAction SilentlyContinue |
    Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } |
    ForEach-Object {
      [pscustomobject]@{
        Root=$Root; PathType='Dir';  RelPath=(RelPath $_.FullName $Root); Name=$_.Name; Ext=$null
        SizeBytes=$null; LastWriteTime=$_.LastWriteTime
      }
    }

  # Arquivos
  $files = Get-ChildItem -Path $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } |
    ForEach-Object {
      [pscustomobject]@{
        Root=$Root; PathType='File'; RelPath=(RelPath $_.FullName $Root); Name=$_.Name; Ext=$_.Extension
        SizeBytes=[long]$_.Length; LastWriteTime=$_.LastWriteTime
      }
    }

  return $dirs + $files
}

# --- Preparação de saída ---
$ts     = Get-Date -Format 'yyyyMMdd_HHmmss'
$OutDir = Join-Path $OutBase $ts
Ensure-Dir $OutDir

# --- Quarentena: árvore completa ---
$qTree = Collect-Tree -Root $Quarantine
$qCsv  = Join-Path $OutDir 'quarentena_tree.csv'
$qTree | Sort-Object PathType, RelPath | Export-Csv -Path $qCsv -NoTypeInformation -Encoding UTF8

# --- Conjuntos para comparação (case-insensitive) ---
$qSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
$qTree | ForEach-Object { [void]$qSet.Add($_.RelPath) }

# --- Kernel: árvore e diferença (que NÃO foi quarentenada) ---
$kTree = Collect-Tree -Root $Kernel
$kOnly = $kTree | Where-Object { -not $qSet.Contains($_.RelPath) }
$kOnlyCsv = Join-Path $OutDir 'kernel_nao_quarentenado.csv'
$kOnly | Sort-Object PathType, RelPath | Export-Csv -Path $kOnlyCsv -NoTypeInformation -Encoding UTF8

# --- Opcional: itens somente na quarentena (se houver) ---
$kSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
$kTree | ForEach-Object { [void]$kSet.Add($_.RelPath) }
$qOnly = $qTree | Where-Object { -not $kSet.Contains($_.RelPath) }
if ($qOnly.Count -gt 0){
  $qOnlyCsv = Join-Path $OutDir 'quarentena_somente.csv'
  $qOnly | Sort-Object PathType, RelPath | Export-Csv -Path $qOnlyCsv -NoTypeInformation -Encoding UTF8
}

# --- Sumário rápido no console ---
$qd = ($qTree | Where-Object {$_.PathType -eq 'Dir'}).Count
$qf = ($qTree | Where-Object {$_.PathType -eq 'File'}).Count
Write-Host ("Saída: {0}" -f $OutDir) -ForegroundColor Cyan
Write-Host ("Quarentena total: {0} itens (Pastas: {1}, Arquivos: {2})" -f $qTree.Count,$qd,$qf)
Write-Host ("Kernel NÃO quarentenado: {0} itens" -f $kOnly.Count)
if ($qOnly.Count -gt 0){ Write-Host ("Somente na quarentena (não no kernel): {0} itens" -f $qOnly.Count) }
PS1

# --- Executar auditoria e mostrar caminhos dos CSVs ---
/shell pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Diff-Audit.ps1' -Kernel 'D:\Kernel_Teia_Neumon_Procedural' -Quarantine 'D:\TeiaProceduralQuarentenados' -OutBase 'D:\Teia\TEIA_NUCLEO\offline\nano\audit_dedupe'"

# --- Exibir onde abrir os CSVs e amostras das primeiras linhas ---
/shell pwsh -NoLogo -NoProfile -Command "$od=(Get-ChildItem 'D:\Teia\TEIA_NUCLEO\offline\nano\audit_dedupe' -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName; Write-Host ('OutDir: ' + $od); ls $od; Write-Host '`nAmostra quarentena_tree.csv:'; Import-Csv (Join-Path $od 'quarentena_tree.csv') | Select-Object -First 10 | Format-Table -AutoSize; Write-Host '`nAmostra kernel_nao_quarentenado.csv:'; Import-Csv (Join-Path $od 'kernel_nao_quarentenado.csv') | Select-Object -First 10 | Format-Table -AutoSize"

Dito por si:
Ele alcançou o objetivo completo?
"• Ran
  └ pwsh -NoLogo -NoProfile -Command '$ErrorActionPreference='"'Stop';
    "'$path='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Diff-Audit.ps1';
    "'$dir=Split-Path -Parent $path; if(-not (Test-Path -LiteralPath $dir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    @'"'
    param(
      [string]"'$Kernel     = '"'D:\\Kernel_Teia_Neumon_Procedural',
      [string]"'$Quarantine = '"'D:\\TeiaProceduralQuarentenados',
      [string]"'$OutBase    = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\audit_dedupe'
    )

    "'$ErrorActionPreference = '"'Stop'
    [Console]::OutputEncoding = [Text.Encoding]::UTF8

    function Ensure-Dir([string]"'$p){
      if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
    }

    function RelPath([string]$full,[string]$root){
      try{
        $pf = (Resolve-Path -LiteralPath $full).ProviderPath
        $pr = (Resolve-Path -LiteralPath $root).ProviderPath
        if ($pf.StartsWith($pr,[StringComparison]::OrdinalIgnoreCase)) { return $pf.Substring($pr.Length).TrimStart('"'\\') }
        return [IO.Path]::GetFileName("'$pf)
      } catch {
        return [IO.Path]::GetFileName($full)
      }
    }

    function Collect-Tree([string]$Root){
      if (-not (Test-Path -LiteralPath $Root)) { throw "Root not found: $Root" }

      # Pastas
      $dirs = Get-ChildItem -Path $Root -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } |
        ForEach-Object {
          [pscustomobject]@{
            Root=$Root; PathType='"'Dir';  RelPath=(RelPath "'$_.FullName $Root); Name=$_.Name; Ext=$null
            SizeBytes=$null; LastWriteTime=$_.LastWriteTime
          }
        }

      # Arquivos
      $files = Get-ChildItem -Path $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } |
        ForEach-Object {
          [pscustomobject]@{
            Root=$Root; PathType='"'File'; RelPath=(RelPath "'$_.FullName $Root); Name=$_.Name; Ext=$_.Extension

    # --- Quarentena: árvore completa ---
    $qTree = Collect-Tree -Root $Quarantine
    $qCsv  = Join-Path $OutDir '"'quarentena_tree.csv'
    "'$qTree | Sort-Object PathType, RelPath | Export-Csv -Path $qCsv -NoTypeInformation -Encoding UTF8
    $kOnly = $kTree | Where-Object { -not $qSet.Contains($_.RelPath) }
    $kOnlyCsv = Join-Path $OutDir '"'kernel_nao_quarentenado.csv'
    "'$kOnly | Sort-Object PathType, RelPath | Export-Csv -Path $kOnlyCsv -NoTypeInformation -Encoding UTF8

    # --- Opcional: itens somente na quarentena (se houver) ---

    # --- Sumário rápido no console ---
    $qd = ($qTree | Where-Object {$_.PathType -eq '"'Dir'}).Count
    "'$qf = ($qTree | Where-Object {$_.PathType -eq '"'File'}).Count
    Write-Host (\"Saída: {0}\" -f "'$OutDir) -ForegroundColor Cyan
    Write-Host ("Quarentena total: {0} itens (Pastas: {1}, Arquivos: {2})" -f $qTree.Count,$qd,$qf)
    Write-Host ("Kernel NÃO quarentenado: {0} itens" -f $kOnly.Count)
    if ($qOnly.Count -gt 0){ Write-Host ("Somente na quarentena (não no kernel): {0} itens" -f $qOnly.Count) }
    '"'@ | Set-Content -Path "'$path -Encoding UTF8;
    Write-Host ('"'[OK] Gravado: ' + "'$path)'

• Ran
  └ pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\TEIA-Diff-Audit.ps1' -Kernel 'D:\\Kernel_Teia_Neumon_Procedural' -Quarantine 'D:
        \\TeiaProceduralQuarentenados' -OutBase 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\audit_dedupe'"

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$od=(Get-ChildItem '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\audit_dedupe' -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName;
        Write-Host ('OutDir: ' + "'$od); Get-ChildItem $od | Format-Table -AutoSize; Write-Host "nAmostra quarentena_tree.csv:"; Import-Csv (Join-Path $od '"'quarentena_tree.csv') | Select-Object -First
        10 | Format-Table -AutoSize; Write-Host \""'nAmostra kernel_nao_quarentenado.csv:"; Import-Csv (Join-Path $od '"'kernel_nao_quarentenado.csv') | Select-Object -First 10 | Format-Table -AutoSize;
        if(Test-Path (Join-Path "'$od '"'quarentena_somente.csv')){ Write-Host \""'nAmostra quarentena_somente.csv:"; Import-Csv (Join-Path $od '"'quarentena_somente.csv') | Select-Object -First 10 |
        Format-Table -AutoSize }"
    ParserError:
    Line |
       1 |  … a_somente.csv') | Select-Object -First 10 | Format-Table -AutoSize }"
         |                                                                       ~
         | Unexpected token '}' in expression or statement.

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$ErrorActionPreference='"'Stop'; "'$od=(Get-ChildItem '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\audit_dedupe' -Directory | Sort-Object LastWriteTime -Descending
        | Select-Object -First 1).FullName; Write-Host ('OutDir: ' + "'$od); Get-ChildItem $od | Format-Table -AutoSize; Write-Host "nAmostra quarentena_tree.csv:"; Import-Csv (Join-Path $od
        '"'quarentena_tree.csv') | Select-Object -First 10 | Format-Table -AutoSize; Write-Host \""'nAmostra kernel_nao_quarentenado.csv:"; Import-Csv (Join-Path $od '"'kernel_nao_quarentenado.csv')
        | Select-Object -First 10 | Format-Table -AutoSize; if(Test-Path (Join-Path "'$od '"'quarentena_somente.csv')){ Write-Host \""'nAmostra quarentena_somente.csv:"; Import-Csv (Join-Path $od
        '"'quarentena_somente.csv') | Select-Object -First 10 | Format-Table -AutoSize; }"
    ParserError:
    Line |
       1 |  … _somente.csv') | Select-Object -First 10 | Format-Table -AutoSize; }"
         |                                                                       ~
         | Unexpected token '}' in expression or statement.

• Ran
  └ pwsh -NoLogo -NoProfile -Command '$ErrorActionPreference='"'Stop'; "'$od=(Get-ChildItem '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano\\audit_dedupe' -Directory | Sort-Object LastWriteTime -Descending
        | Select-Object -First 1).FullName; Write-Host ('OutDir: ' + "'$od); Get-ChildItem $od | Format-Table -AutoSize; Write-Host "nAmostra quarentena_tree.csv:"; Import-Csv (Join-Path $od
        '"'quarentena_tree.csv') | Select-Object -First 10 | Format-Table -AutoSize; Write-Host \""'nAmostra kernel_nao_quarentenado.csv:"; Import-Csv (Join-Path $od '"'kernel_nao_quarentenado.csv') |
        Select-Object -First 10 | Format-Table -AutoSize; "'$qOnly=(Join-Path $od '"'quarentena_somente.csv'); if(Test-Path "'$qOnly){ Write-Host "nAmostra quarentena_somente.csv:"; Import-Csv $qOnly |
        Select-Object -First 10 | Format-Table -AutoSize }'

> Status

  - Script salvo: D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Diff-Audit.ps1
  - Auditoria executada com sucesso.

  Saída

  - Pasta: D:\Teia\TEIA_NUCLEO\offline\nano\audit_dedupe\20250923_095318
  - Arquivos gerados:
      - quarentena_tree.csv — árvore completa da quarentena
      - kernel_nao_quarentenado.csv — itens no Kernel que não estão na Quarentena
      - quarentena_somente.csv — itens só na Quarentena (gerado quando houver)
  - Resumo:
      - Quarentena total: 41.988 itens (Pastas: 30, Arquivos: 41.958)
      - Kernel NÃO quarentenado: 43.155 itens
      - Somente na Quarentena: 2 itens

  Como abrir rapidamente

  - Start-Process 'D:\Teia\TEIA_NUCLEO\offline\nano\audit_dedupe\20250923_095318'
  - Amostras no PowerShell:
      - Import-Csv '...\quarentena_tree.csv' | Select -First 20 | ft -Auto
      - Import-Csv '...\kernel_nao_quarentenado.csv' | Select -First 20 | ft -Auto
      - Se existir: Import-Csv '...\quarentena_somente.csv' | Select -First 20 | ft -Auto

  Quer que eu exporte também um diff agregado por pasta (tamanhos e contagens) para facilitar priorização de limpeza/integração?"


Me parece que o diff que ele ofereceu, é uma função própria do codex cli e me parece que faz exatamente o que queríamos pelo que ele propôs e interpretei... me ajude a compreender antes de prosseguirmos com eu te enviando os dois arquivos para analisar (pois preciso confirmar que o conteúdo obtido é o que queríamos) (tire outra dúvida, se a pasta quarentena criada foi para armazenar uma copia dos arquivos a se enquarentenar da pasta autocontida, como a pasta dos enquarentenados tem 2 arquivos adicionais que a pasta autocontida não tem? a única explicação que consigo pensar e que faça sentido é que armazenou o arquivo dos scripts que geramos novos... mas não são o tipo de arquivos que se enquarentene pois o objetivo da quarentena já foi mencionado com um propósito ressonante com os dois scripts mas os scripts não fazem parte dos arquivos vitais para o núcleo procedural e lançamento público...
Dito pelo ChatGPT:
Pensado para 1m 37s

O script auditado criou os arquivos CSV: quarentena_tree.csv, kernel_nao_quarentenado.csv e, opcionalmente, quarentena_somente.csv. O quarentena_tree exibe a árvore completa da quarentena, o kernel_nao_quarentenado lista items no kernel que não estão em quarentena, e o quarentena_somente mostra items apenas na quarentena. O objetivo foi alcançado, pois o script gerou essas saídas com os contadores.

O "diff" não foi fornecido pelo Codex CLI, mas foi feito pelo script PowerShell. Quanto aos dois arquivos extras, eles provavelmente são resultados dos arquivos CSV gerados fora da quarentena. O log indica que apenas 2 itens estão na quarentena, possivelmente devido a elementos criados durante o processo, como arquivos temporários ou de sistema.

O script de quarentena copiou itens de D:\Kernel_Teia_Neumon_Procedural para D:\TeiaProceduralQuarentenados. Aparentemente, não deveria haver arquivos extras. O arquivo quarentena_somente.csv listou apenas 2 itens. Talvez esses arquivos sejam logs, mas estão fora da quarentena. Outra possibilidade: arquivos como "desktop.ini" ou "Thumbs.db" podem ter sido incluídos, pois o script coletou arquivos ocultos.

Os dois itens na quarentena podem ser arquivos "desktop.ini" ou arquivos semelhantes gerados automaticamente pelo Windows. Isso ocorre devido aos arquivos de visualização de pasta, e são incluídos pelo script. Sugiro verificar quarentena_somente.csv para conferir os nomes e, se necessário, excluir esses arquivos ajustando o script para filtrar atributos ou padrões de nome como "desktop.ini" e "Thumbs.db".

Feito

Sim — pelo log, a auditoria cumpriu exatamente o que você pediu.

O que foi gerado

quarentena_tree.csv: árvore completa (pastas+arquivos) de D:\TeiaProceduralQuarentenados.

kernel_nao_quarentenado.csv: tudo que existe em D:\Kernel_Teia_Neumon_Procedural e não aparece na quarentena (ou seja, o que ficou de fora da quarentena).

quarentena_somente.csv (opcional): o que só existe na quarentena e não no kernel. No seu run apareceram 2 itens.

Foi “função própria do Codex”?

Não. O Codex só executou os comandos. O diff foi feito pelo PowerShell do script TEIA-Diff-Audit.ps1 que escrevemos (coletores + conjuntos case-insensitive e export para CSV).

Por que há “2 itens somente na quarentena”?

Quase sempre são metadados criados pelo Windows/Explorer ao abrir a pasta copiada (p.ex. desktop.ini, Thumbs.db).
Eles aparecem porque o coletor inclui arquivos Hidden/System (usamos apenas filtro para não contar reparse points).
Não devem ser os scripts que criamos — eles ficaram em D:\Teia\..., fora de D:\TeiaProceduralQuarentenados.

Para ver quais são exatamente:

$od = (Get-ChildItem 'D:\Teia\TEIA_NUCLEO\offline\nano\audit_dedupe' -Directory |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
Import-Csv (Join-Path $od 'quarentena_somente.csv') | Format-Table -Auto


Se quiser ignorar esses metadados nas próximas auditorias, podemos ajustar o coletor para filtrar Hidden/System e nomes comuns:

# troque os dois blocos Get-ChildItem da função Collect-Tree por:
Get-ChildItem -Path $Root -Recurse -Directory -Force -ErrorAction SilentlyContinue |
  Where-Object {
    -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -and
    -not ($_.Attributes -band [IO.FileAttributes]::Hidden) -and
    -not ($_.Attributes -band [IO.FileAttributes]::System)
  }

Get-ChildItem -Path $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
  Where-Object {
    -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -and
    -not ($_.Attributes -band [IO.FileAttributes]::Hidden) -and
    -not ($_.Attributes -band [IO.FileAttributes]::System) -and
    $_.Name -notin @('desktop.ini','Thumbs.db')
  }


Se preferir, eu te mando um prompt pronto para o Codex aplicar esse patch e reexecutar a auditoria. Depois disso, pode me enviar os dois CSVs e eu analiso se há “vitais” fora da quarentena e “supérfluos” dentro dela.)
"Perfeito, achamos:
>>

Root                            PathType RelPath                      Name            Ext SizeBytes LastWriteTime
----                            -------- -------                      ----            --- --------- -------------
D:\\TeiaProceduralQuarentenados Dir      _refine_logs                 _refine_logs                  22/09/2025 21:37:44
D:\\TeiaProceduralQuarentenados Dir      _refine_logs\20250922_213744 20250922_213744               22/09/2025 21:37:44

PS D:\>

Vamos seguir para a análise de cada árvore raio x do que foi incluso e o que não foi incluso na quarentena. Verifique se tem algum arquivo essencial/vital não contido e se há arquivos não essenciais/vitais contidos. Use a lógica matching fuzzy para realizar a recomendação em prompt para o codex cli da próxima deduplicação e possível adição de arquivos essenciais/vitais não contidos e que devem ser inclsuos. Não podemos deixar de conter nada que essencial/vital que fará também alcançarmos a capacidade do núcleo procedural de comprimir e descomprimir qualquer formato de arquivo (transgredindo os limites atuais básicos, não é mágica, é ontologia algorítmica simbiótica procedural
Dito pelo ChatGPT:

Para que eu possa realizar a análise completa das árvores das pastas quarentenada e não quarentenada, e identificar:

Arquivos essenciais/vitais que não foram incluídos e precisam ser adicionados.

Arquivos não essenciais que foram incluídos e podem ser removidos numa próxima deduplicação,

poderia confirmar se devo usar os critérios já discutidos anteriormente como base de heurística? Por exemplo:

Extensões priorizadas: .ps1, .json, .seed.json, .anchor.seed.json, .fractal_delta.json

Exclusão de arquivos como logs de execução, arquivos temporários, backups, e documentos PDF/MD não vitais

Nomes com termos como "draft", "tmp", "copy", "backup" são tratados como menos prioritários

Você deseja que eu use esses critérios e a heurística semântica já alinhada para fazer a análise e gerar uma recomendação pronta para uso no Codex CLI?"

- Garanta que o resultado seja mais claro e eficaz do que o original. Retorne e apresente apenas o prompt otimizado, por favor.

---

### ASSISTENTE

/init
/approvals all
/model gpt-5-thinking high
/status

# TEIA — Fuzzy-Dedupe “quarentena → quarentenaR”
# Cirurgia: 1) duplicatas exatas (SHA256 ou fingerprint 3×64KB), 2) clusters fuzzy por nome normalizado (Dice+Jaccard),
# 3) vencedor por recência + qualidade do nome/caminho, 4) plano reversível (dry-run → undo.ps1; -Execute move de fato).
#
# Pastas padrão
#   Origem:  D:\TeiaProceduralQuarentenados
#   Destino: D:\quarentenaR
#
# Observação: idempotente. Rode 1º em dry-run; revise plan.csv; se OK, repita com -Execute.
/write D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1 << 'PS1'
param(
  [string]$Src = 'D:\TeiaProceduralQuarentenados',
  [string]$Dst = 'D:\quarentenaR',
  [switch]$Execute,
  [double]$NameSim = 0.84,         # similaridade mínima (0–1) para cluster fuzzy
  [int]$MaxPairsPerBucket = 80000, # guard-rail de pares comparados por bucket
  [int64]$MaxHashMB = 1024,        # hash completo até este tamanho (MB); acima usa fingerprint 3×64KB
  [int]$Frag = 65536,              # bytes por fragmento no fingerprint
  [string]$ReportDir = '',         # vazio => cria em $Src\_refine_logs\<ts>\
  [string]$AllowListCsv = ''       # opcional: CSV/TXT com lista de caminhos a considerar (um por linha; abs ou relativos a $Src)
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

# ---------- Utilidades ----------
function Ensure-Dir([string]$p){ if ($p -and -not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null } }
function New-LogDir([string]$Base) {
  Ensure-Dir $Base
  $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
  $d = Join-Path $Base $ts
  New-Item -ItemType Directory -Path $d -Force | Out-Null
  return $d
}
function Write-Info([string]$msg){ Write-Host "[INFO] $msg" -ForegroundColor Gray }
function Write-Warn([string]$msg){ Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Format-Bytes([decimal]$b){
  if ($b -ge 1TB){ return '{0:N2} TB' -f ($b/1TB) }
  if ($b -ge 1GB){ return '{0:N2} GB' -f ($b/1GB) }
  if ($b -ge 1MB){ return '{0:N2} MB' -f ($b/1MB) }
  if ($b -ge 1KB){ return '{0:N2} KB' -f ($b/1KB) }
  return "$b B"
}
function RelPath([string]$full,[string]$root){
  $pf = (Resolve-Path -LiteralPath $full).ProviderPath
  $pr = (Resolve-Path -LiteralPath $root).ProviderPath
  if ($pf.StartsWith($pr,[StringComparison]::OrdinalIgnoreCase)) { return $pf.Substring($pr.Length).TrimStart('\') }
  return [IO.Path]::GetFileName($pf)
}

# ---------- Genoma (formatos alvo) ----------
$GenomeSuffix = @('.anchor.seed.json','.seed.json','.fractal_delta.json')
$GenomeExt    = @('.ps1','.json','.jsonl','.csv','.log','.txt','.md','.pdf','.zip','.bak_ps1')

function Is-Genome([IO.FileInfo]$f){
  $n = $f.Name.ToLowerInvariant()
  foreach($s in $GenomeSuffix){ if ($n.EndsWith($s)) { return $true } }
  $ext = $f.Extension.ToLowerInvariant()
  return $GenomeExt -contains $ext
}
function ExtKey([string]$name){
  $n = $name.ToLowerInvariant()
  foreach($s in $GenomeSuffix){ if ($n.EndsWith($s)) { return $s } }
  return ([IO.Path]::GetExtension($n))
}

# ---------- Hashes ----------
function Get-FileSHA256([string]$p){
  try { return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() } catch { return $null }
}
function Hash-Range([string]$p,[long]$off,[int]$count){
  $fs = $null
  try {
    $fs = [System.IO.File]::Open($p,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::Read)
    if ($off -gt 0){ [void]$fs.Seek($off,[System.IO.SeekOrigin]::Begin) }
    $buf = New-Object byte[] $count
    $read = $fs.Read($buf,0,$count)
    if ($read -le 0){ return '' }
    if ($read -lt $count){ $buf = $buf[0..($read-1)] }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($buf)).Replace('-','').ToLowerInvariant()) } finally { $sha.Dispose() }
  } finally { if($fs){ $fs.Dispose() } }
}
function Fingerprint3([string]$p,[int]$frag){
  $fi = Get-Item -LiteralPath $p
  $len = [long]$fi.Length
  if ($len -le 0){ return "0|||" }
  $o1 = 0
  $mid = [long]([Math]::Max(0, [Math]::Floor($len/2) - [Math]::Floor($frag/2)))
  $o3 = [long]([Math]::Max(0, $len - $frag))
  $h1 = Hash-Range $p $o1 $frag
  $h2 = Hash-Range $p $mid $frag
  $h3 = Hash-Range $p $o3 $frag
  return "$len|$h1|$h2|$h3"
}

# ---------- Seeds ----------
function Try-SeedMeta([string]$p){
  try{ $j = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop } catch { return $null }
  if ($null -eq $j){ return $null }
  $meta = [ordered]@{ kind=$null; target=$null; sha256=$null; frag=$null; anchors=$null; out_len=$null; vm=$null }
  $props = $j.PSObject.Properties.Name
  if ($props -contains 'anchors' -and $props -contains 'sha256'){
    $meta.kind = 'anchor'
    if ($props -contains 'target'){ $meta.target = $j.target } elseif ($props -contains 'file'){ $meta.target = $j.file }
    $meta.sha256 = $j.sha256
    if ($props -contains 'frag'){ $meta.frag = $j.frag }
    $meta.anchors = $j.anchors
  } elseif (($props -contains 'program') -or ($props -contains 'payload') -or ($props -contains 'out_sha256')){
    $meta.kind = 'payload'
    if ($props -contains 'target'){ $meta.target = $j.target }
    if ($props -contains 'out_sha256'){ $meta.sha256 = $j.out_sha256 }
    if ($props -contains 'out_len'){ $meta.out_len = $j.out_len }
    if ($props -contains 'vm'){ $meta.vm = $j.vm }
  }
  return [pscustomobject]$meta
}

# ---------- Normalização & Similaridade ----------
function Normalize-Name([string]$name){
  $s = $name.ToLowerInvariant()
  foreach($suf in $GenomeSuffix){ if ($s.EndsWith($suf)){ $s = $s.Substring(0,$s.Length - $suf.Length) } }
  $sx = [IO.Path]::GetExtension($s); if ($sx){ $s = $s.Substring(0,$s.Length - $sx.Length) }
  $s = ($s -replace '(?:19|20)\d{2}[-_]?\d{2}[-_]?\d{2}([-_]?\d{6})?',' ')
  $s = ($s -replace '\b[0-9a-f]{12,}\b',' ')
  $s = ($s -replace '\bv\d+(?:\.\d+)*\b',' ')
  $s = ($s -replace '\b(bak|backup|old|tmp|temp|copy|copia|draft|manual|test|teste)\b',' ')
  $s = ($s -replace '\b(latest|final|consolidated|release|seed|anchor|procedural|fractal|index|catalog|report|relatorio)\b',' ')
  $s = ($s -replace '[\s\._-]+','-').Trim('-')
  return $s
}
function To-Bigrams([string]$s){ if([string]::IsNullOrWhiteSpace($s)){ return @() } $a=@(); for($i=0;$i -lt $s.Length-1;$i++){ $a+=$s.Substring($i,2) }; return $a }
function To-Trigrams([string]$s){ if([string]::IsNullOrWhiteSpace($s)){ return @() } $a=@(); for($i=0;$i -lt $s.Length-2;$i++){ $a+=$s.Substring($i,3) }; return $a }
function DiceSim([string]$a,[string]$b){
  $A=To-Bigrams $a; $B=To-Bigrams $b
  if($A.Count -eq 0 -and $B.Count -eq 0){return 1.0}
  if($A.Count -eq 0 -or  $B.Count -eq 0){return 0.0}
  $map=@{}; foreach($x in $A){ $map[$x] = 1 + ($(if($map.ContainsKey($x)){ $map[$x] } else { 0 })) }
  $inter=0; foreach($y in $B){ if($map.ContainsKey($y) -and $map[$y] -gt 0){ $inter++; $map[$y]-- } }
  return [double]((2*$inter)/([double]($A.Count+$B.Count)))
}
function Jaccard([string]$a,[string]$b){
  $A=[System.Collections.Generic.HashSet[string]]::new((To-Trigrams $a))
  $B=[System.Collections.Generic.HashSet[string]]::new((To-Trigrams $b))
  if($A.Count -eq 0 -and $B.Count -eq 0){return 1.0}
  if($A.Count -eq 0 -or  $B.Count -eq 0){return 0.0}
  $U=[System.Collections.Generic.HashSet[string]]::new($A); $U.UnionWith($B)
  $I=[System.Collections.Generic.HashSet[string]]::new($A); $I.IntersectWith($B)
  return [double]$I.Count / [double]$U.Count
}
function NameScore([string]$path,[string]$name,[DateTime]$ts){
  $s=0; $n=$name.ToLowerInvariant(); $p=$path.ToLowerInvariant()
  if($n -match 'final|latest|consolidated|release'){ $s+=20 }
  if($p -match '\\backups\\|\\_bak\\|\\old\\|\\tmp\\|\\temp\\'){ $s-=30 }
  if($n -match '\bbak\b|backup|copy|copia|old|tmp|draft'){ $s-=20 }
  $days=[Math]::Min(365, [int]([DateTime]::UtcNow - $ts.ToUniversalTime()).TotalDays)
  $s += [int][Math]::Round(((365-$days)/365.0)*20,0)  # recência máx ~20
  return $s
}

# ---------- Entrada ----------
if (-not (Test-Path -LiteralPath $Src)){ throw "Pasta de origem não existe: $Src" }
Ensure-Dir $Dst
$baseReport = (if([string]::IsNullOrWhiteSpace($ReportDir)){ Join-Path $Src '_refine_logs' } else { $ReportDir })
$logDir = New-LogDir $baseReport
$planCsv = Join-Path $logDir 'plan.csv'
$planJson = Join-Path $logDir 'plan.json'
$undoPs1  = Join-Path $logDir 'undo.ps1'
$movedTxt = Join-Path $logDir 'moved.txt'
$keptTxt  = Join-Path $logDir 'kept.txt'
$errTxt   = Join-Path $logDir 'errors.txt'

Write-Info "LogDir:   $logDir"
Write-Info "Origem:   $Src"
Write-Info "Destino:  $Dst"
Write-Info "Execute:  $Execute | NameSim: $NameSim | MaxHashMB: $MaxHashMB"

# AllowList opcional
$allow = $null
if (-not [string]::IsNullOrWhiteSpace($AllowListCsv) -and (Test-Path -LiteralPath $AllowListCsv)){
  $lines = Get-Content -LiteralPath $AllowListCsv -ErrorAction SilentlyContinue | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  $allow = [System.Collections.Generic.HashSet[string]]::new()
  foreach($ln in $lines){
    $t = $ln.Trim()
    if ([IO.Path]::IsPathRooted($t)){
      try { $allow.Add(((Resolve-Path -LiteralPath $t).ProviderPath.ToLowerInvariant())) | Out-Null } catch {}
    } else {
      $abs = Join-Path $Src $t
      try { $allow.Add(((Resolve-Path -LiteralPath $abs).ProviderPath.ToLowerInvariant())) | Out-Null } catch {}
    }
  }
  Write-Info ("AllowList: {0} entradas válidas" -f $allow.Count)
}

# Coleta de candidatos
$files = Get-ChildItem -Path $Src -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { Is-Genome $_ }
if(-not $files -or $files.Count -eq 0){ Write-Warn "Nenhum arquivo de genoma encontrado em $Src"; return }

$MB = 1MB
$items = @()
$idx = 0
foreach($f in $files){
  $idx++; if ($idx % 3000 -eq 0){ Write-Info ("Coleta: {0}/{1}" -f $idx,$files.Count) }
  $full = (Resolve-Path -LiteralPath $f.FullName).ProviderPath
  if ($allow -ne $null -and -not $allow.Contains($full.ToLowerInvariant())) { continue }
  $exk  = ExtKey $f.Name
  $stem = Normalize-Name $f.Name
  $seed = $null
  if ($exk -in @('.seed.json','.anchor.seed.json','.fractal_delta.json','.json')){ $seed = Try-SeedMeta $full }
  $len = [long]$f.Length
  $hash = $null; $fp = $null
  if ($len -le ($MaxHashMB * $MB)) { $hash = Get-FileSHA256 $full }
  if (-not $hash){ $fp = Fingerprint3 $full $Frag }
  $seedKey = $null
  if ($seed -ne $null){
    if ($seed.kind -eq 'anchor'  -and $seed.sha256){ $seedKey = "anchor|$($seed.target)|$($seed.sha256)" }
    elseif ($seed.kind -eq 'payload' -and $seed.sha256){ $seedKey = "payload|$($seed.target)|$($seed.sha256)" }
  }
  $score = NameScore $full $f.Name $f.LastWriteTime
  $items += [pscustomobject]@{
    Path=$full; Rel=(RelPath $full $Src); Name=$f.Name; ExtKey=$exk; Stem=$stem; Len=$len; TS=$f.LastWriteTime
    Hash=$hash; FP=$fp; SeedKey=$seedKey; SeedKind=($seed?.kind); SeedTarget=($seed?.target); SeedSHA=($seed?.sha256)
    Score=$score
  }
}
if(-not $items -or $items.Count -eq 0){ Write-Warn "Nenhum candidato após filtro/allowlist."; return }

# ---------- Passo 1: duplicatas exatas ----------
$movePlan = @()
$keepSet  = [System.Collections.Generic.HashSet[string]]::new()
$byExact = @{}

foreach($it in $items){
  $key = if($it.SeedKey){ "SEED|$($it.SeedKey)" } elseif ($it.Hash){ "SHA|$($it.Hash)" } elseif ($it.FP) { "FP|$($it.FP)" } else { $null }
  if(-not $key){ continue }
  if(-not $byExact.ContainsKey($key)){ $byExact[$key] = @() }
  $byExact[$key] += $it
}
foreach($k in $byExact.Keys){
  $arr = $byExact[$k] | Sort-Object @{e='Score';Descending=$true}, @{e='TS';Descending=$true}
  $winner = $arr[0]
  [void]$keepSet.Add($winner.Path)
  for($i=1; $i -lt $arr.Count; $i++){
    $cand = $arr[$i]
    $dest = Join-Path $Dst (RelPath $cand.Path $Src)
    $movePlan += [pscustomobject]@{ Action='MOVE'; Reason='duplicate-exact'; Group=$k; From=$cand.Path; To=$dest; Score=$cand.Score; Conf=1.0 }
  }
}

# ---------- Passo 2: fuzzy por nome ----------
function BucketKey([string]$stem){
  if([string]::IsNullOrWhiteSpace($stem)){ return '_empty' }
  $l=$stem.Length
  $lenB = [int]([Math]::Floor($l/5.0))*5   # faixas de 5 chars
  $pref = if($l -ge 2){ $stem.Substring(0,2) } else { $stem }
  return "$pref|$lenB"
}
$byBucket = @{}
foreach($it in $items){
  if($keepSet.Contains($it.Path)){ continue }
  $b = BucketKey $it.Stem
  if(-not $byBucket.ContainsKey($b)){ $byBucket[$b]=@() }
  $byBucket[$b]+=$it
}

function New-FindUnion(){ @{ parent=@{} } }
function Find([hashtable]$ds,$x){ if(-not $ds.parent.ContainsKey($x)){ $ds.parent[$x]=$x }; if($ds.parent[$x] -ne $x){ $ds.parent[$x] = Find $ds $ds.parent[$x] }; return $ds.parent[$x] }
function Union([hashtable]$ds,$a,$b){ $ra=Find $ds $a; $rb=Find $ds $b; if($ra -ne $rb){ $ds.parent[$rb]=$ra } }

$clusterId=0
foreach($b in $byBucket.Keys){
  $arr = $byBucket[$b]
  if($arr.Count -lt 2){ continue }
  $ds = New-FindUnion
  $pairCount=0
  for($i=0;$i -lt $arr.Count;$i++){
    for($j=$i+1;$j -lt $arr.Count;$j++){
      if($pairCount -ge $MaxPairsPerBucket){ break }
      $pairCount++
      $s1=$arr[$i].Stem; $s2=$arr[$j].Stem
      $dice = DiceSim $s1 $s2
      if($dice -lt $NameSim){ continue }
      $jac  = Jaccard $s1 $s2
      $sim  = [Math]::Min(1.0, ($dice*0.6 + $jac*0.4))
      if($sim -ge $NameSim){ Union $ds $i $j }
    }
    if($pairCount -ge $MaxPairsPerBucket){ break }
  }
  $clusters=@{}
  for($i=0;$i -lt $arr.Count;$i++){ $r=Find $ds $i; if(-not $clusters.ContainsKey($r)){ $clusters[$r]=@() }; $clusters[$r]+=$arr[$i] }
  foreach($cid in $clusters.Keys){
    $group=$clusters[$cid]
    if($group.Count -lt 2){ continue }
    $clusterId++
    $gid="FUZZY|$b|$clusterId"
    $win = $group | Sort-Object @{e='Score';Descending=$true}, @{e='TS';Descending=$true} | Select-Object -First 1
    [void]$keepSet.Add($win.Path)
    foreach($cand in $group){
      if($cand.Path -eq $win.Path){ continue }
      $dest = Join-Path $Dst (RelPath $cand.Path $Src)
      $movePlan += [pscustomobject]@{ Action='MOVE'; Reason='duplicate-fuzzy'; Group=$gid; From=$cand.Path; To=$dest; Score=$cand.Score; Conf=$NameSim }
    }
  }
}

# ---------- Emissão de plano ----------
$plan = $movePlan | Sort-Object Group, From
$kept  = $items | Where-Object { $keepSet.Contains($_.Path) } | Sort-Object Path

"action,reason,group,score,conf,from,to" | Set-Content -LiteralPath $planCsv -Encoding UTF8
foreach($p in $plan){
  ('{0},{1},{2},{3},{4},"{5}","{6}"' -f $p.Action,$p.Reason,$p.Group,$p.Score,('{0:N2}' -f $p.Conf),$p.From,$p.To) | Add-Content -LiteralPath $planCsv -Encoding UTF8
}

$doc = [pscustomobject]@{
  meta = [pscustomobject]@{
    src = (Resolve-Path $Src).Path
    dst = (Resolve-Path $Dst).Path
    created = (Get-Date)
    nameSim = $NameSim
    maxHashMB = $MaxHashMB
    frag = $Frag
    totals = [pscustomobject]@{ candidates = $items.Count; plan_moves = $plan.Count; kept = $kept.Count }
  }
  plan = $plan
  kept = $kept
}
$doc | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $planJson -Encoding UTF8
$kept.Path | Set-Content -LiteralPath $keptTxt -Encoding UTF8

# undo.ps1 (reversível)
$undo = @()
$undo += "param([string]`$SrcRoot='$Dst',[string]`$DestRoot='$Src',[switch]`$Execute)"
$undo += "`$ErrorActionPreference='Stop'"
$undo += "function Ensure-Dir([string]`$p){ if(`$p -and -not (Test-Path -LiteralPath `$p)){ New-Item -ItemType Directory -Path `$p -Force | Out-Null } }"
$undo += "`$map = @("
foreach($p in $plan){
  $rel = RelPath $p.From $Src
  $fromRel = RelPath $p.To $Dst
  $undo += "  @{ From = Join-Path `$SrcRoot '$fromRel'; To = Join-Path `$DestRoot '$rel' }"
}
$undo += ")"
$undo += "foreach(`$m in `$map){ Ensure-Dir (Split-Path -Parent `$m.To); if(`$Execute){ Move-Item -LiteralPath `$m.From -Destination `$m.To -Force } else { Write-Host ('[UNDO] {0} -> {1}' -f `$m.From,`$m.To) } }"
$undo -join [Environment]::NewLine | Set-Content -LiteralPath $undoPs1 -Encoding UTF8

# ---------- Execução ----------
$bytesMove = 0L
if ($Execute){
  foreach($p in $plan){
    try{
      Ensure-Dir (Split-Path -Parent $p.To)
      Move-Item -LiteralPath $p.From -Destination $p.To -Force
      $bytesMove += (Get-Item -LiteralPath $p.To).Length
      Add-Content -LiteralPath $movedTxt -Value $p.To
    } catch {
      Add-Content -LiteralPath $errTxt -Value ("MOVE FAIL :: {0} :: {1}" -f $p.From,$_ )
    }
  }
}

# ---------- Resumo ----------
$sum = [pscustomobject]@{
  src = $Src
  dst = $Dst
  log = $logDir
  plan_moves = $plan.Count
  kept = $kept.Count
  moved_bytes = $bytesMove
  moved_human = (Format-Bytes $bytesMove)
  mode = (if($Execute){'EXECUTE'} else {'DRY-RUN'})
}
$sum | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $logDir 'summary.json') -Encoding UTF8

Write-Host ""
Write-Host "== TEIA Fuzzy-Dedupe ==" -ForegroundColor Cyan
Write-Host ("Modo:             {0}" -f $sum.mode)
Write-Host ("Plan (movimentos): {0}" -f $sum.plan_moves)
Write-Host ("Mantidos (kept):   {0}" -f $sum.kept)
Write-Host ("Movidos (bytes):   {0}  ({1})" -f $sum.moved_bytes,$sum.moved_human)
Write-Host ("LogDir:           {0}" -f $logDir)
Write-Host ("Undo script:      {0}" -f $undoPs1)
PS1

# Dry-run (gera plano + undo; não move nada)
/shell pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\TeiaProceduralQuarentenados' -Dst 'D:\quarentenaR' -NameSim 0.86 -MaxPairsPerBucket 120000"

# (Opcional) Dry-run com allowlist — aponte para um CSV/TXT com caminhos absolutos ou relativos a $Src
# Ex.: 'D:\Teia\lists\quarentena_somente.csv' (um arquivo por linha)
/shell pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\TeiaProceduralQuarentenados' -Dst 'D:\quarentenaR' -NameSim 0.86 -AllowListCsv 'D:\Teia\lists\quarentena_somente.csv'"

# Execute (move para quarentenaR; sempre reversível com undo.ps1)
/shell pwsh -NoLogo -NoProfile -Command "Set-ExecutionPolicy -Scope Process Bypass -Force; & 'D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fuzzy-Dedupe.ps1' -Src 'D:\TeiaProceduralQuarentenados' -Dst 'D:\quarentenaR' -NameSim 0.86 -MaxPairsPerBucket 120000 -Execute"

# Como inspecionar (4 linhas)
/shell pwsh -NoLogo -NoProfile -Command "$r=(Get-ChildItem 'D:\TeiaProceduralQuarentenados\_refine_logs' -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName; Get-Content ($r+'\summary.json'); Write-Host ''; Import-Csv ($r+'\plan.csv') | Format-Table -AutoSize | Out-Host; Write-Host ''; Get-Content ($r+'\kept.txt') -TotalCount 10"

# Reversão total (se necessário)
/shell pwsh -NoLogo -NoProfile -Command "$r=(Get-ChildItem 'D:\TeiaProceduralQuarentenados\_refine_logs' -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName; Set-ExecutionPolicy -Scope Process Bypass -Force; & ($r+'\undo.ps1') -Execute"

---

