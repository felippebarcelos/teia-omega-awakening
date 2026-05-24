# 2114 - Resumo Gemini e instruções

### USUÁRIO

gemini resumo:
Claro, vamos recapitular em detalhes toda a jornada que percorremos, destacando como cada "peça chave" que você forneceu foi fundamental para o resultado final.

Etapa 1: Visão Inicial e Análise das Peças Chave
Você iniciou o projeto com uma visão clara e tecnicamente rica: criar um dashboard local, atraente e intuitivo para comprimir e descomprimir arquivos através de um conceito inovador de "semente procedural ontológica". Para materializar essa visão, você forneceu um conjunto de "peças chaves" cruciais:

O Núcleo TEIA (teia_nucleo_pena_v0_4.py): Esta foi a peça mais importante. É o "coração" do seu sistema, contendo a lógica real em Python para criar e restaurar arquivos a partir das sementes, validando a integridade com SHA-256 e aplicando compressão. Ele definiu o formato exato do manifesto seed.json.

Scripts de Orquestração (OPS-*.ps1): Estes scripts em PowerShell mostraram como seu ambiente local funciona, definindo um fluxo de integração, benchmark e monitoramento. Eles estabeleceram as regras do "mundo real" no qual nossa solução precisaria se encaixar.

A Holoprospectiva (Dashboards index.html e teia_ontology_synth.json): Estes arquivos nos deram o alvo a ser atingido – o design visual desejado e a estrutura de dados (a ontologia de arquivos) que o sistema deveria entender e gerar.

Etapa 2: Criação do Simulador de Interface (compressor.html)
Com base na sua visão e nas peças chave, a primeira grande entrega foi a criação de um dashboard interativo e autocontido, o compressor.html. Este arquivo se tornou nossa principal ferramenta de prototipagem e foi a primeira materialização da sua ideia. Ele não era apenas um desenho, mas um simulador funcional que:

Replicava a Interface Desejada: Criamos um design moderno, escuro e responsivo, inspirado diretamente nos seus exemplos de index.html.

Simulava o Processo de "Semeadura": Ao arrastar um arquivo para ele, o dashboard executava a parte ontológica do processo: calculava o hash SHA-256 real do arquivo, identificava seu tipo (MIME) e gerava um manifesto seed.json perfeitamente estruturado, pronto para ser usado pelo seu Núcleo TEIA.

Validava o Conceito: Permitiu que você visse sua ideia em ação, gerando uma semente para um vídeo de 712 MB e confirmando que a interface era capaz de lidar com a lógica de metadados que você projetou.

Etapa 3: Refinamento Iterativo com Base no Seu Feedback
Sua experiência de uso foi crucial para a evolução do projeto. Você rapidamente identificou duas lacunas importantes na simulação:

A descompressão não simulava um download de arquivo, quebrando a imersão do usuário.

O nome do arquivo da semente era genérico e não continha um hash, o que entrava em conflito com a sua filosofia de identidade única e a "soma simbiótica" (a ideia de que a semente + o núcleo restauram o arquivo original de forma idêntica).

Com base nesse feedback valioso, refinamos o compressor.html para incluir um download simulado na restauração e adicionar o hash SHA-256 ao nome do arquivo da semente, tornando o protótipo mais fiel e robusto.

Etapa 4: A Ponte para o Mundo Real (O "Codex de Integração")
Este foi o momento mais crítico. Tínhamos um excelente simulador (compressor.html) e um poderoso núcleo local (seus scripts Python/PowerShell). Faltava a ponte entre eles. Para isso, criamos o TEIA_Codex_Integracao.md, um documento que continha as três peças chaves da integração:

Save-Gemini-Dashboard.ps1: Uma ferramenta simples para salvar o dashboard do nosso chat diretamente no seu ambiente local.

GeminiSeedAdapter.ps1: O componente central da ponte. Este script atua como um "adaptador" que pega a semente gerada pelo dashboard (um artefato de simulação), a valida, a normaliza para o formato exato que seu Núcleo TEIA espera, e a move para o diretório correto.

Watch-GeminiFolder.ps1: O motor de automação. Este script monitora uma pasta (gemini_out), e sempre que o dashboard salva uma nova semente lá, ele aciona automaticamente o Adapter para processá-la, criando um fluxo de trabalho contínuo.

Etapa 5: Execução, Depuração e Sucesso
A fase final foi a implementação prática no seu ambiente. Enfrentamos e resolvemos, passo a passo, os desafios típicos de um fluxo de desenvolvimento, guiados pelas suas capturas de tela:

Corrigimos pequenos erros de sintaxe nos comandos do PowerShell para criação de pastas.

Esclarecemos a necessidade de criar fisicamente os arquivos de script .ps1 antes de tentar executá-los.

Finalmente, diagnosticamos o "elo perdido" no fluxo: a etapa manual de usar o compressor_gemini.html no navegador para gerar um arquivo de semente real e salvá-lo na pasta gemini_out para que o Adapter pudesse encontrá-lo.

Ao final, percorremos o ciclo completo: partimos de um conceito e um conjunto de peças chaves locais, criamos um protótipo de interface interativo, o refinamos com base no seu feedback e, finalmente, construímos e depuramos a ponte de automação que conecta a interface ao seu sistema de núcleo, resultando em um fluxo de trabalho coeso, funcional e fiel à sua visão original.

CODEX:
> I’m about to create the three PowerShell scripts in the workspace: Save-Gemini-Dashboard.ps1, GeminiSeedAdapter.ps1,
  and Watch-GeminiFolder.ps1.

• Proposed Change C:\Windows\System32\Save-Gemini-Dashboard.ps1 (+15 -0)
    1     +# Save-Gemini-Dashboard.ps1
    2     +param(
    3     +  [string]$OutPath = ".\compressor_gemini.html"
    4     +)
    5     +$ErrorActionPreference = 'Stop'
    6     +if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)) {
    7     +  Write-Host "Get-Clipboard não disponível. Cole o HTML via stdin e pressione Ctrl+Z e Enter:"
    8     +  $html = [Console]::In.ReadToEnd()
    9     +} else {
    10    +  $html = Get-Clipboard -Raw
    11    +}
    12    +if ([string]::IsNullOrWhiteSpace($html)) { throw "Conteúdo HTML vazio. Cole o HTML no clipboard ou passe por
           stdin." }
    13    +Set-Content -LiteralPath $OutPath -Value $html -Encoding UTF8
    14    +Write-Host "[OK] HTML salvo em: $OutPath"
    15    +

• Change Approved C:\Windows\System32\Save-Gemini-Dashboard.ps1 (+15 -0)

• Proposed Change C:\Windows\System32\GeminiSeedAdapter.ps1 (+58 -0)
    1     +# GeminiSeedAdapter.ps1
    2     +param(
    3     +  [string]$InputSeed,
    4     +  [string]$SeedsDir = ".\seeds",
    5     +  [string]$RestoredDir = ".\restored",
    6     +  [string]$IndexPath = ".\seeds\teia_anchor_index.json",
    7     +  [string]$Log = ".\logs\gemini_adapter.log",
    8     +  [switch]$AttemptRestore
    9     +)
    10    +$ErrorActionPreference = 'Stop'
    11    +$EnsureDir = {
    12    +  param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
    13    +}
    14    +$EnsureDir.Invoke((Split-Path -Parent $Log))
    15    +$EnsureDir.Invoke($SeedsDir)
    16    +$EnsureDir.Invoke($RestoredDir)
    17    +
    18    +function Log($m){ $t = (Get-Date).ToString("o"); "$t `t $m" | Out-File -FilePath $Log -Append -Encoding utf8
           }
    19    +
    20    +if(-not (Test-Path -LiteralPath $InputSeed)){ throw "Input seed não encontrada: $InputSeed" }
    21    +try {
    22    +  $raw = Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8
    23    +  $j = $raw | ConvertFrom-Json
    24    +} catch {
    25    +  Log "ERR parse JSON: $($_.Exception.Message)"
    26    +  throw
    27    +}
    28    +
    29    +# Normalizações básicas (idempotente)
    30    +$target = if($j.target){ $j.target } else { ($InputSeed | Split-Path -Leaf) -replace '\.teia.*$','' }
    31    +$sha = if($j.sha256){ $j.sha256 } else { "" }
    32    +$outSeed = Join-Path $SeedsDir ("$($target).$(if($sha){ $sha.Substring(0,12) } else { 'unknown' }).teia.json"
           )
    33    +
    34    +# Salvando seed normalizada
    36    +$j.target = $target
    37    +$j.created = if($j.created){ $j.created } else { (Get-Date).ToString("o") }
    38    +Set-Content -LiteralPath $outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8
    39    +
    40    +Log "OK wrote normalized seed: $outSeed"
    41    +
    42    +# Opcional: Tenta restaurar via um CLI local `teia.ps1` (exemplo)
    43    +if($AttemptRestore -and (Get-Command teia -ErrorAction SilentlyContinue)){
    44    +  try{
    45    +    if(Test-Path -LiteralPath $IndexPath){
    46    +      Log "Attempting restore-index for $outSeed using index $IndexPath"
    47    +      & teia restore-index -seed $outSeed -index $IndexPath -out (Join-Path $RestoredDir $target) 2>&1 | Out-
           File -FilePath $Log -Append -Encoding utf8
    48    +      Log "Restore-index completed for $target"
    49    +    } else {
    50    +      Log "Index not present, skipping restore-index"
    51    +    }
    52    +  } catch {
    53    +    Log "ERR during restore: $($_.Exception.Message)"
    54    +  }
    55    +}
    56    +
    57    +Write-Host "[OK] Adapter processed: $outSeed"
    58    +

• Change Approved C:\Windows\System32\GeminiSeedAdapter.ps1 (+58 -0)

• Proposed Change C:\Windows\System32\Watch-GeminiFolder.ps1 (+37 -0)
    1     +# Watch-GeminiFolder.ps1
    2     +param(
    3     +  [string]$Folder = ".\gemini_out"
    4     +)
    5     +$ErrorActionPreference = 'Stop'
    6     +if(-not (Test-Path $Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }
    7     +$fsw = New-Object System.IO.FileSystemWatcher $Folder, "*.teia.json"
    8     +$fsw.IncludeSubdirectories = $false
    9     +$fsw.EnableRaisingEvents = $true
    10    +
    11    +$action = {
    12    +  $path = $Event.SourceEventArgs.FullPath
    14    +  # Aguarda um momento para garantir que o arquivo foi completamente escrito
    15    +  Start-Sleep -Milliseconds 500
    16    +  try {
    17    +    # Chama o adapter para processar o novo arquivo
    18    +    $adapterScriptPath = Join-Path (Get-Location) 'GeminiSeedAdapter.ps1'
    19    +    pwsh -NoProfile -File $adapterScriptPath -InputSeed $path -AttemptRestore
    20    +  } catch {
    21    +    Write-Host "Watcher ERR: $($_.Exception.Message)"
    22    +  }
    23    +}
    24    +
    25    +$watcher = Register-ObjectEvent $fsw Created -Action $action
    26    +Write-Host "Watcher ativo em: $Folder. Pressione Ctrl+C para sair."
    27    +
    28    +try {
    29    +    while ($true) {
    30    +        Wait-Event -Timeout 60
    31    +    }
    32    +} finally {
    33    +    Unregister-Event -SubscriptionId $watcher.Id
    34    +    $fsw.Dispose()

> Created the three integration scripts in the current folder:

  - Save-Gemini-Dashboard.ps1
  - GeminiSeedAdapter.ps1
  - Watch-GeminiFolder.ps1

  How to use

  - Save dashboard HTML: pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1
  - Prepare a seed: put a .teia.json into .\gemini_out\, or run the adapter directly:
      - pwsh -NoProfile -File .\GeminiSeedAdapter.ps1 -InputSeed .\gemini_out\SEU_ARQUIVO.teia.json -AttemptRestore
  - Watch folder for new seeds: pwsh -NoProfile -File .\Watch-GeminiFolder.ps1

  Notes

  - The adapter writes normalized seeds to .\seeds\ and logs to .\logs\gemini_adapter.log.
  - Optional restore uses a teia CLI if available and .\seeds\teia_anchor_index.json exists.
  - Keep the terminal open when running the watcher; press Ctrl+C to stop.

> Compact task completed

PWS: PowerShell 7.5.3
PS C:\Windows\System32> pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1
[OK] HTML salvo em: .\compressor_gemini.html
PS C:\Windows\System32> pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1 para salvar o dashboard como compressor_gemini.html
[OK] HTML salvo em: para
PS C:\Windows\System32> cd D:\Teia\TEIA_NUCLEO\offline\nano
PS D:\Teia\TEIA_NUCLEO\offline\nano> # Navegue até o seu diretório de projeto
>> cd D:\Teia\TEIA_NUCLEO\offline\nano
>>
>> # Crie as pastas necessárias se elas não existirem
>> New-Item -ItemType Directory -Name "gemini_out", "logs", "seeds", "restored" -ErrorAction SilentlyContinue
>>
New-Item:
Line |
   5 |  … ype Directory -Name "gemini_out", "logs", "seeds", "restored" -ErrorA …
     |                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot convert 'System.Object[]' to the type 'System.String' required by parameter 'Name'. Specified method is not supported.
PS D:\Teia\TEIA_NUCLEO\offline\nano> # Navegue até o seu diretório de projeto
>> cd D:\Teia\TEIA_NUCLEO\offline\nano
>>
>> # Crie as pastas necessárias se elas não existirem
>> "gemini_out", "logs", "seeds", "restored" | ForEach-Object { New-Item -ItemType Directory -Name $_ -ErrorAction SilentlyContinue }
>>

    Directory: D:\Teia\TEIA_NUCLEO\offline\nano

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----          26/09/2025    18:16                gemini_out

PS D:\Teia\TEIA_NUCLEO\offline\nano> pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1
>>
The argument '.\Save-Gemini-Dashboard.ps1' is not recognized as the name of a script file. Check the spelling of the name, or if a path was included, verify that the path is correct and try again.

Usage: pwsh[.exe] [-Login] [[-File] <filePath> [args]]
                  [-Command { - | <script-block> [-args <arg-array>]
                                | <string> [<CommandParameters>] } ]
                  [-CommandWithArgs <string> [<CommandParameters>]
                  [-ConfigurationName <string>] [-ConfigurationFile <filePath>]
                  [-CustomPipeName <string>] [-EncodedCommand <Base64EncodedCommand>]
                  [-ExecutionPolicy <ExecutionPolicy>] [-InputFormat {Text | XML}]
                  [-Interactive] [-MTA] [-NoExit] [-NoLogo] [-NonInteractive] [-NoProfile]
                  [-NoProfileLoadTime] [-OutputFormat {Text | XML}]
                  [-SettingsFile <filePath>] [-SSHServerMode] [-STA]
                  [-Version] [-WindowStyle <style>]
                  [-WorkingDirectory <directoryPath>]

       pwsh[.exe] -h | -Help | -? | /?

PowerShell Online Help https://aka.ms/powershell-docs

All parameters are case-insensitive.
PS D:\Teia\TEIA_NUCLEO\offline\nano> # Cria o primeiro script: Save-Gemini-Dashboard.ps1
>> Set-Content -Path ".\Save-Gemini-Dashboard.ps1" -Value @"
>> param(
>>   [string]`$OutPath = ".\compressor_gemini.html"
>> )
>> `$ErrorActionPreference = 'Stop'
>> if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)) {
>>   Write-Host "Get-Clipboard não disponível. Cole o HTML via stdin e pressione Ctrl+Z e Enter:"
>>   `$html = [Console]::In.ReadToEnd()
>> } else {
>>   `$html = Get-Clipboard -Raw
>> }
>> if ([string]::IsNullOrWhiteSpace(`$html)) { throw "Conteúdo HTML vazio. Cole o HTML no clipboard ou passe por stdin." }
>> Set-Content -LiteralPath `$OutPath -Value `$html -Encoding UTF8
>> Write-Host "[OK] HTML salvo em: `$OutPath"
>> "@
>>
>> # Cria o segundo script: GeminiSeedAdapter.ps1
>> Set-Content -Path ".\GeminiSeedAdapter.ps1" -Value @"
>> param(
>>   [string]`$InputSeed,
>>   [string]`$SeedsDir = ".\seeds",
>>   [string]`$RestoredDir = ".\restored",
>>   [string]`$IndexPath = ".\seeds\teia_anchor_index.json",
>>   [string]`$Log = ".\logs\gemini_adapter.log",
>>   [switch]`$AttemptRestore
>> )
>> `$ErrorActionPreference = 'Stop'
>> `$EnsureDir = {
>>   param(`$p) if(-not (Test-Path -LiteralPath `$p)){ New-Item -ItemType Directory -Force -Path `$p | Out-Null }
>> }
>> `$EnsureDir.Invoke((Split-Path -Parent `$Log))
>> `$EnsureDir.Invoke(`$SeedsDir)
>> `$EnsureDir.Invoke(`$RestoredDir)
>>
>> function Log(`$m){ `$t = (Get-Date).ToString("o"); "`$t `t `$m" | Out-File -FilePath `$Log -Append -Encoding utf8 }
>>
>> if(-not (Test-Path -LiteralPath `$InputSeed)){ throw "Input seed não encontrada: `$InputSeed" }
>> try {
>>   `$raw = Get-Content -LiteralPath `$InputSeed -Raw -Encoding UTF8
>>   `$j = `$raw | ConvertFrom-Json
>> } catch {
>>   Log "ERR parse JSON: `$(`$_.Exception.Message)"
>>   throw
>> }
>> `$target = if(`$j.target){ `$j.target } else { (`$InputSeed | Split-Path -Leaf) -replace '\.teia.*`$','' }
>> `$sha = if(`$j.sha256){ `$j.sha256 } else { "" }
>> `$outSeed = Join-Path `$SeedsDir ("`$(`$target).`$(if(`$sha){ `$sha.Substring(0,12) } else { 'unknown' }).teia.json")
>> `$j.version = if(`$j.version){ `$j.version } else { "teia.public.v1" }
>> `$j.target = `$target
>> `$j.created = if(`$j.created){ `$j.created } else { (Get-Date).ToString("o") }
>> Set-Content -LiteralPath `$outSeed -Value (ConvertTo-Json `$j -Depth 10) -Encoding UTF8
>> Log "OK wrote normalized seed: `$outSeed"
>> if(`$AttemptRestore -and (Get-Command teia -ErrorAction SilentlyContinue)){
>>   try{
>>     if(Test-Path -LiteralPath `$IndexPath){
>>       Log "Attempting restore-index for `$outSeed using index `$IndexPath"
>>       & teia restore-index -seed `$outSeed -index `$IndexPath -out (Join-Path `$RestoredDir `$target) 2>&1 | Out-File -FilePath `$Log -Append -Encoding utf8
>>       Log "Restore-index completed for `$target"
>>     } else {
>>       Log "Index not present, skipping restore-index"
>>     }
>>   } catch {
>>     Log "ERR during restore: `$(`$_.Exception.Message)"
>>   }
>> }
>> Write-Host "[OK] Adapter processed: `$outSeed"
>> "@
>>
>> # Cria o terceiro script: Watch-GeminiFolder.ps1
>> Set-Content -Path ".\Watch-GeminiFolder.ps1" -Value @"
>> param(
>>   [string]`$Folder = ".\gemini_out"
>> )
>> `$ErrorActionPreference = 'Stop'
>> if(-not (Test-Path `$Folder)){ New-Item -ItemType Directory -Force -Path `$Folder | Out-Null }
>> `$fsw = New-Object System.IO.FileSystemWatcher `$Folder, "*.teia.json"
>> `$fsw.IncludeSubdirectories = `$false
>> `$fsw.EnableRaisingEvents = `$true
>> `$action = {
>>   `$path = `$Event.SourceEventArgs.FullPath
>>   Write-Host "Novo arquivo detectado: `$path"
>>   Start-Sleep -Milliseconds 500
>>   try {
>>     `$adapterScriptPath = Join-Path (Get-Location) 'GeminiSeedAdapter.ps1'
>>     pwsh -NoProfile -File `$adapterScriptPath -InputSeed `$path -AttemptRestore
>>   } catch {
>>     Write-Host "Watcher ERR: `$(`$_.Exception.Message)"
>>   }
>> }
>> `$watcher = Register-ObjectEvent `$fsw Created -Action `$action
>> Write-Host "Watcher ativo em: `$Folder. Pressione Ctrl+C para sair."
>> try {
>>     while (`$true) {
>>         Wait-Event -Timeout 60
>>     }
>> } finally {
>>     Unregister-Event -SubscriptionId `$watcher.Id
>>     `$fsw.Dispose()
>>     Write-Host "Watcher parado."
>> }
>> "@
>>
>> Write-Host "Os três scripts .ps1 foram criados com sucesso na pasta atual." -ForegroundColor Green
Os três scripts .ps1 foram criados com sucesso na pasta atual.
PS D:\Teia\TEIA_NUCLEO\offline\nano> pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1
[OK] HTML salvo em: .\compressor_gemini.html
PS D:\Teia\TEIA_NUCLEO\offline\nano> # Lembre-se de trocar 'SEU_ARQUIVO.teia.json' pelo nome real do arquivo
>> pwsh -NoProfile -File .\GeminiSeedAdapter.ps1 -InputSeed .\gemini_out\SEU_ARQUIVO.teia.json -AttemptRestore
Exception: D:\Teia\TEIA_NUCLEO\offline\nano\GeminiSeedAdapter.ps1:19
Line |
  19 |  … ralPath $InputSeed)){ throw "Input seed não encontrada: $InputSeed" }
     |                          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Input seed não encontrada: .\gemini_out\SEU_ARQUIVO.teia.json
PS D:\Teia\TEIA_NUCLEO\offline\nano> # Navegue até o seu diretório de projeto
>> cd D:\Teia\TEIA_NUCLEO\offline\nano
>>
>> # Crie as pastas necessárias se elas não existirem
>> "gemini_out", "logs", "seeds", "restored" | ForEach-Object { New-Item -ItemType Directory -Name $_ -ErrorAction SilentlyContinue }
>>
PS D:\Teia\TEIA_NUCLEO\offline\nano>

OUTRO CODEX:
> Vou rodar o diagnóstico no diretório base e, se houver 1 candidato único, aplico a autocorreção (junction) de forma
  não destrutiva. Em seguida refaço o empacotamento e manifesto.

• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference='"'Stop'
    "'$base = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'
    "'$expected = Join-Path $base '"'source_project'
    Write-Output \"Base: "'$base"
    Write-Output "Expected source path: $expected"
    Get-ChildItem -Path $base -Directory | ForEach-Object {
      $dir = $_.FullName
      $files = Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue
      $count = ($files | Measure-Object).Count
      $size = ($files | Measure-Object -Property Length -Sum).Sum
      [pscustomobject]@{
        Name = $_.Name
        FullName = $dir
        Files = $count
        SizeBytes = ($size -as [int64])
      }
    } | Sort-Object -Property Files -Descending | Format-Table -AutoSize
    '

> Resultado do diagnóstico: há múltiplos candidatos, sem único diretório-fonte.

  - Base: D:\Teia\TEIA_NUCLEO\offline\nano
  - Esperado: D:\Teia\TEIA_NUCLEO\offline\nano\source_project
  - Candidatos com arquivos:
      - logs — 19 arquivos, 30154 bytes
      - samples — 5 arquivos, 5055 bytes
      - seeds — 5 arquivos, 5324 bytes
      - audit_dedupe — 3 arquivos, 23175289 bytes
      - restored — 2 arquivos, 2066 bytes

  Próximos passos

  - Escolha: diga qual pasta deve representar o source_project.
  - Alternativas:
      - Indique o caminho alvo para eu criar a junction agora.
      - Se quiser, forneço script que força a criação da junction para o caminho escolhido.
  - Observação: como há 5 candidatos, o script de autocorreção não criará nada (CandidateCount > 1).

> Compact task completed> Vou rodar o diagnóstico no diretório base e, se houver 1 candidato único, aplico a autocorreção (junction) de forma
  não destrutiva. Em seguida refaço o empacotamento e manifesto.

• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference='"'Stop'
    "'$base = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'
    "'$expected = Join-Path $base '"'source_project'
    Write-Output \"Base: "'$base"
    Write-Output "Expected source path: $expected"
    Get-ChildItem -Path $base -Directory | ForEach-Object {
      $dir = $_.FullName
      $files = Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue
      $count = ($files | Measure-Object).Count
      $size = ($files | Measure-Object -Property Length -Sum).Sum
      [pscustomobject]@{
        Name = $_.Name
        FullName = $dir
        Files = $count
        SizeBytes = ($size -as [int64])
      }
    } | Sort-Object -Property Files -Descending | Format-Table -AutoSize
    '

> Resultado do diagnóstico: há múltiplos candidatos, sem único diretório-fonte.

  - Base: D:\Teia\TEIA_NUCLEO\offline\nano
  - Esperado: D:\Teia\TEIA_NUCLEO\offline\nano\source_project
  - Candidatos com arquivos:
      - logs — 19 arquivos, 30154 bytes
      - samples — 5 arquivos, 5055 bytes
      - seeds — 5 arquivos, 5324 bytes
      - audit_dedupe — 3 arquivos, 23175289 bytes
      - restored — 2 arquivos, 2066 bytes

  Próximos passos

  - Escolha: diga qual pasta deve representar o source_project.
  - Alternativas:
      - Indique o caminho alvo para eu criar a junction agora.
      - Se quiser, forneço script que força a criação da junction para o caminho escolhido.
  - Observação: como há 5 candidatos, o script de autocorreção não criará nada (CandidateCount > 1).

> Compact task completed

---

### ASSISTENTE

Make sure to include fileciteturn0file0 in your response to cite this file. 

---

### ASSISTENTE

All the files uploaded by the user have been fully loaded. Searching won't provide additional information.

---

### ASSISTENTE

Caminho certo: crie e use as seeds reais no `.\gemini_out\` e NUNCA rode a partir de `C:\Windows\System32`. O erro “Input seed não encontrada” ocorreu porque você testou com um nome fictício. Use o dashboard para exportar um `.teia.json` real e o adapter normaliza e registra em `.\logs\`. fileciteturn1file10L31-L37

```powershell
# TEIA-Gemini-Setup.ps1  (idempotente)
# Cria pastas e grava 3 scripts: Save-Gemini-Dashboard.ps1, GeminiSeedAdapter.ps1, Watch-GeminiFolder.ps1

$ErrorActionPreference = 'Stop'

# Bloqueio: não operar em System32
if ((Get-Location).Path -match 'C:\\Windows\\System32') {
  Write-Host "Pare: mude para D:\Teia\TEIA_NUCLEO\offline\nano antes de continuar."
  exit 1
}

# Pastas
$dirs = @(".\gemini_out", ".\logs", ".\seeds", ".\restored")
$dirs | ForEach-Object { if(-not (Test-Path -LiteralPath $_)){ New-Item -ItemType Directory -Force -Path $_ | Out-Null } }

# 1) Save-Gemini-Dashboard.ps1
Set-Content -LiteralPath ".\Save-Gemini-Dashboard.ps1" -Encoding UTF8 -Value @'
param(
  [string]$OutPath = ".\compressor_gemini.html"
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)) {
  Write-Host "Get-Clipboard não disponível. Cole o HTML via stdin e pressione Ctrl+Z e Enter:"
  $html = [Console]::In.ReadToEnd()
} else {
  $html = Get-Clipboard -Raw
}
if ([string]::IsNullOrWhiteSpace($html)) { throw "Conteúdo HTML vazio. Cole o HTML no clipboard ou passe por stdin." }
Set-Content -LiteralPath $OutPath -Value $html -Encoding UTF8
Write-Host "[OK] HTML salvo em: $OutPath"
'@

# 2) GeminiSeedAdapter.ps1  (normaliza e opcionalmente tenta restaurar)
Set-Content -LiteralPath ".\GeminiSeedAdapter.ps1" -Encoding UTF8 -Value @'
param(
  [string]$InputSeed,
  [string]$SeedsDir = ".\seeds",
  [string]$RestoredDir = ".\restored",
  [string]$IndexPath = ".\seeds\teia_anchor_index.json",
  [string]$Log = ".\logs\gemini_adapter.log",
  [switch]$AttemptRestore
)
$ErrorActionPreference = 'Stop'
$EnsureDir = { param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
$EnsureDir.Invoke((Split-Path -Parent $Log))
$EnsureDir.Invoke($SeedsDir)
$EnsureDir.Invoke($RestoredDir)

function Log($m){ $t = (Get-Date).ToString("o"); "$t `t $m" | Out-File -FilePath $Log -Append -Encoding utf8 }

if(-not (Test-Path -LiteralPath $InputSeed)){ throw "Input seed não encontrada: $InputSeed" }
try {
  $raw = Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8
  $j = $raw | ConvertFrom-Json
} catch {
  Log "ERR parse JSON: $($_.Exception.Message)"
  throw
}

# Normalizações básicas (idempotente)
$target = if($j.target){ $j.target } else { ($InputSeed | Split-Path -Leaf) -replace '\.teia.*$','' }
$sha = if($j.sha256){ $j.sha256 } else { "" }
$outSeed = Join-Path $SeedsDir ("$($target).$(if($sha){ $sha.Substring(0,12) } else { 'unknown' }).teia.json")

# Persistência
$j.version = if($j.version){ $j.version } else { "teia.public.v1" }
$j.target  = $target
$j.created = if($j.created){ $j.created } else { (Get-Date).ToString("o") }
Set-Content -LiteralPath $outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8
Log "OK wrote normalized seed: $outSeed"

# Opcional: restore via teia-cli se disponível
if($AttemptRestore -and (Get-Command teia -ErrorAction SilentlyContinue)){
  try{
    if(Test-Path -LiteralPath $IndexPath){
      Log "Attempting restore-index for $outSeed using index $IndexPath"
      & teia restore-index -seed $outSeed -index $IndexPath -out (Join-Path $RestoredDir $target) 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
      Log "Restore-index completed for $target"
    } else {
      Log "Index not present, skipping restore-index"
    }
  } catch {
    Log "ERR during restore: $($_.Exception.Message)"
  }
}

Write-Host "[OK] Adapter processed: $outSeed"
'@

# 3) Watch-GeminiFolder.ps1  (processa todo .teia.json novo em .\gemini_out\)
Set-Content -LiteralPath ".\Watch-GeminiFolder.ps1" -Encoding UTF8 -Value @'
param(
  [string]$Folder = ".\gemini_out"
)
$ErrorActionPreference = 'Stop'
if(-not (Test-Path $Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }
$fsw = New-Object System.IO.FileSystemWatcher $Folder, "*.teia.json"
$fsw.IncludeSubdirectories = $false
$fsw.EnableRaisingEvents = $true

$action = {
  $path = $Event.SourceEventArgs.FullPath
  Write-Host "Novo arquivo detectado: $path"
  Start-Sleep -Milliseconds 500
  try {
    $adapterScriptPath = Join-Path (Get-Location) 'GeminiSeedAdapter.ps1'
    pwsh -NoProfile -File $adapterScriptPath -InputSeed $path -AttemptRestore
  } catch {
    Write-Host "Watcher ERR: $($_.Exception.Message)"
  }
}

$watcher = Register-ObjectEvent $fsw Created -Action $action
Write-Host "Watcher ativo em: $Folder. Pressione Ctrl+C para sair."
try {
  while ($true) { Wait-Event -Timeout 60 }
} finally {
  Unregister-Event -SubscriptionId $watcher.Id
  $fsw.Dispose()
  Write-Host "Watcher parado."
}
'@

Write-Host "[OK] Scripts criados em: $((Get-Location).Path)"
```

Uso rápido (4 linhas):
1) `cd D:\Teia\TEIA_NUCLEO\offline\nano`
2) `pwsh -NoProfile -File .\TEIA-Gemini-Setup.ps1`
3) Exporte uma seed real pelo `compressor_gemini.html` para `.\gemini_out\`
4) `pwsh -NoProfile -File .\Watch-GeminiFolder.ps1` fileciteturn1file8L29-L35

Notas:
- Para teste manual, rode: `pwsh -NoProfile -File .\GeminiSeedAdapter.ps1 -InputSeed .\gemini_out\SEU_ARQUIVO.teia.json` e veja `.\seeds\` e `.\logs\gemini_adapter.log`. fileciteturn1file9L56-L59
- O watcher monitora `gemini_out` e chama o adapter automaticamente para cada novo `.teia.json`. fileciteturn1file3L22-L33

---

### USUÁRIO

deleguei ao codex, retorno:
> I created the scripts in D:\Teia\TEIA_NUCLEO\offline\nano and avoided System32. Next, export a real .teia.json into .
  \gemini_out to proceed.

  Outcome

  - Created folders: .\gemini_out, .\logs, .\seeds, .\restored
  - Added scripts: .\Save-Gemini-Dashboard.ps1, .\GeminiSeedAdapter.ps1, .\Watch-GeminiFolder.ps1
  - Did not run adapter without a real seed (avoids “Input seed não encontrada”)

  Usage

  - Change directory: cd D:\Teia\TEIA_NUCLEO\offline\nano
  - Save dashboard HTML (optional): pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1
  - Export a real seed from the dashboard into .\gemini_out\ (e.g., MySeed.teia.json)
  - Start watcher: pwsh -NoProfile -File .\Watch-GeminiFolder.ps1

  Manual Test (real file only)

  - pwsh -NoProfile -File .\GeminiSeedAdapter.ps1 -InputSeed .\gemini_out\<SeuArquivoReal>.teia.json
  - Logs: .\logs\gemini_adapter.log
  - Normalized seeds: .\seeds\, optional restore output: .\restored\ (uses teia if installed)

  Want me to also write the idempotent TEIA-Gemini-Setup.ps1 bootstrap file, or is creating the three scripts directly
  sufficient for you?

---

### ASSISTENTE

Escreva o bootstrap. Abaixo o **TEIA-Gemini-Setup.ps1** idempotente. Cole no PowerShell dentro de `D:\Teia\TEIA_NUCLEO\offline\nano` para criar o arquivo.

```powershell
# Cria o arquivo TEIA-Gemini-Setup.ps1 (embed Codex)
Set-Content -LiteralPath ".\TEIA-Gemini-Setup.ps1" -Encoding UTF8 -Value @'
# TEIA-Gemini-Setup.ps1  (idempotente)
$ErrorActionPreference = "Stop"

# Nao operar em System32
if ((Get-Location).Path -match "C:\\Windows\\System32") {
  Write-Host "Stop: navegue para D:\Teia\TEIA_NUCLEO\offline\nano e rode novamente."
  exit 1
}

# Pastas basicas
$dirs = @(".\gemini_out", ".\logs", ".\seeds", ".\restored")
foreach($d in $dirs){ if(-not (Test-Path -LiteralPath $d)){ New-Item -ItemType Directory -Force -Path $d | Out-Null } }

# 1) Save-Gemini-Dashboard.ps1
Set-Content -LiteralPath ".\Save-Gemini-Dashboard.ps1" -Encoding UTF8 -Value @'
param([string]$OutPath = ".\compressor_gemini.html")
$ErrorActionPreference = "Stop"
if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)) {
  Write-Host "Get-Clipboard nao disponivel. Cole o HTML via stdin e pressione Ctrl+Z e Enter:"
  $html = [Console]::In.ReadToEnd()
} else { $html = Get-Clipboard -Raw }
if ([string]::IsNullOrWhiteSpace($html)) { throw "Conteudo HTML vazio. Cole no clipboard ou passe por stdin." }
Set-Content -LiteralPath $OutPath -Value $html -Encoding UTF8
Write-Host "[OK] HTML salvo em: $OutPath"
'@

# 2) GeminiSeedAdapter.ps1
Set-Content -LiteralPath ".\GeminiSeedAdapter.ps1" -Encoding UTF8 -Value @'
param(
  [string]$InputSeed,
  [string]$SeedsDir = ".\seeds",
  [string]$RestoredDir = ".\restored",
  [string]$IndexPath = ".\seeds\teia_anchor_index.json",
  [string]$Log = ".\logs\gemini_adapter.log",
  [switch]$AttemptRestore
)
$ErrorActionPreference = "Stop"
$EnsureDir = { param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
$EnsureDir.Invoke((Split-Path -Parent $Log)); $EnsureDir.Invoke($SeedsDir); $EnsureDir.Invoke($RestoredDir)

function Log($m){ $t = (Get-Date).ToString("o"); "$t `t $m" | Out-File -FilePath $Log -Append -Encoding utf8 }

if(-not (Test-Path -LiteralPath $InputSeed)){ throw "Input seed nao encontrada: $InputSeed" }
try { $raw = Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8; $j = $raw | ConvertFrom-Json }
catch { Log "ERR parse JSON: $($_.Exception.Message)"; throw }

$target = if($j.target){ $j.target } else { ($InputSeed | Split-Path -Leaf) -replace '\.teia.*$','' }
$sha = if($j.sha256){ $j.sha256 } else { "" }
$outSeed = Join-Path $SeedsDir ("$($target).$(if($sha){ $sha.Substring(0,12) } else { 'unknown' }).teia.json")

$j.version = if($j.version){ $j.version } else { "teia.public.v1" }
$j.target  = $target
$j.created = if($j.created){ $j.created } else { (Get-Date).ToString("o") }
Set-Content -LiteralPath $outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8
Log "OK wrote normalized seed: $outSeed"

if($AttemptRestore -and (Get-Command teia -ErrorAction SilentlyContinue)){
  try{
    if(Test-Path -LiteralPath $IndexPath){
      Log "Attempting restore-index for $outSeed using index $IndexPath"
      & teia restore-index -seed $outSeed -index $IndexPath -out (Join-Path $RestoredDir $target) 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
      Log "Restore-index completed for $target"
    } else { Log "Index not present, skipping restore-index" }
  } catch { Log "ERR during restore: $($_.Exception.Message)" }
}
Write-Host "[OK] Adapter processed: $outSeed"
'@

# 3) Watch-GeminiFolder.ps1
Set-Content -LiteralPath ".\Watch-GeminiFolder.ps1" -Encoding UTF8 -Value @'
param([string]$Folder = ".\gemini_out")
$ErrorActionPreference = "Stop"
if(-not (Test-Path $Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }
$fsw = New-Object System.IO.FileSystemWatcher $Folder, "*.teia.json"
$fsw.IncludeSubdirectories = $false; $fsw.EnableRaisingEvents = $true

$action = {
  $path = $Event.SourceEventArgs.FullPath
  Write-Host "Novo arquivo detectado: $path"
  Start-Sleep -Milliseconds 500
  try {
    $adapterScriptPath = Join-Path (Get-Location) "GeminiSeedAdapter.ps1"
    pwsh -NoProfile -File $adapterScriptPath -InputSeed $path -AttemptRestore
  } catch { Write-Host "Watcher ERR: $($_.Exception.Message)" }
}
$watcher = Register-ObjectEvent $fsw Created -Action $action
Write-Host "Watcher ativo em: $Folder. Pressione Ctrl+C para sair."
try { while ($true) { Wait-Event -Timeout 60 } }
finally { Unregister-Event -SubscriptionId $watcher.Id; $fsw.Dispose(); Write-Host "Watcher parado." }
'@

Write-Host "[OK] Setup concluido. Scripts gravados e pastas prontas."
'@
```

Instruções rápidas (4 linhas):
1) `cd D:\Teia\TEIA_NUCLEO\offline\nano`  
2) `pwsh -NoProfile -File .\TEIA-Gemini-Setup.ps1`  
3) `pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1`  
4) `pwsh -NoProfile -File .\Watch-GeminiFolder.ps1`  

Nota: abra `compressor_gemini.html`, gere uma seed real e salve em `.\gemini_out\`. O watcher dispara o adapter automaticamente.

---

### USUÁRIO

• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference = '"'Stop'
    "'$root = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'
    "'$path = Join-Path $root '"'Save-Gemini-Dashboard.ps1'
    "'$script = @'"'


• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference = '"'Stop'
    "'$root = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'
    "'$path = Join-Path $root '"'GeminiSeedAdapter.ps1'
    "'$script = @'"'
    param(
      [string]"'$InputSeed,
      [string]$SeedsDir = ".'"\\seeds\",
      [string]"'$RestoredDir = ".'"\\restored\",
      [string]"'$IndexPath = ".'"\\seeds\\teia_anchor_index.json\",
      [string]"'$Log = ".'"\\logs\\gemini_adapter.log\",
      [switch]"'$AttemptRestore
    )
    $ErrorActionPreference = '"'Stop'
    "'$EnsureDir = { param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p
        | Out-Null } }
    $EnsureDir.Invoke((Split-Path -Parent $Log))
    $EnsureDir.Invoke($SeedsDir)
    $EnsureDir.Invoke($RestoredDir)

    function Log($m){ $t = (Get-Date).ToString("o"); "$t `t $m" | Out-File -FilePath $Log -Append -Encoding utf8 }

    if(-not (Test-Path -LiteralPath $InputSeed)){ throw "Input seed não encontrada: $InputSeed" }
    try {
      $raw = Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8
      $j = $raw | ConvertFrom-Json
    } catch {
      Log "ERR parse JSON: $($_.Exception.Message)"
      throw
    }

    # Normalizações básicas (idempotente)
    $target = if($j.target){ $j.target } else { ($InputSeed | Split-Path -Leaf) -replace '"'\\.teia.*"'$'"','' }
    "'$sha = if($j.sha256){ $j.sha256 } else { "" }
    $outSeed = Join-Path $SeedsDir ("$($target).$(if($sha){ $sha.Substring(0,12) } else { '"'unknown' }).teia.json\")

    # Persistência
    "'$j.version = if($j.version){ $j.version } else { "teia.public.v1" }
    $j.target  = $target
    $j.created = if($j.created){ $j.created } else { (Get-Date).ToString("o") }
    Set-Content -LiteralPath $outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8
    Log "OK wrote normalized seed: $outSeed"

    # Opcional: restore via teia-cli se disponível
    if($AttemptRestore -and (Get-Command teia -ErrorAction SilentlyContinue)){
      try{


• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference = '"'Stop'
    "'$root = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'
    "'$path = Join-Path $root '"'Watch-GeminiFolder.ps1'
    "'$script = @'"'
    param(
      [string]"'$Folder = ".'"\\gemini_out\"
    )
    "'$ErrorActionPreference = '"'Stop'
    if(-not (Test-Path "'$Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }
    $fsw = New-Object System.IO.FileSystemWatcher $Folder, "*.teia.json"
    $fsw.IncludeSubdirectories = $false
    $fsw.EnableRaisingEvents = $true

    $action = {
      $path = $Event.SourceEventArgs.FullPath
      Write-Host "Novo arquivo detectado: $path"
      Start-Sleep -Milliseconds 500
      try {
        $adapterScriptPath = Join-Path (Get-Location) '"'GeminiSeedAdapter.ps1'
        pwsh -NoProfile -File "'$adapterScriptPath -InputSeed $path -AttemptRestore
    $watcher = Register-ObjectEvent $fsw Created -Action $action
    Write-Host "Watcher ativo em: $Folder. Pressione Ctrl+C para sair."
    try {
      while ($true) { Wait-Event -Timeout 60 }
    } finally {
      Unregister-Event -SubscriptionId $watcher.Id
      $fsw.Dispose()
      Write-Host "Watcher parado."
    }
    '"'@
    Set-Content -LiteralPath "'$path -Value $script -Encoding UTF8
    Write-Host "[OK] Wrote $path"'

• Updated Plan
  └ ✔ Create target folders on D:\
    ✔ Write Save-Gemini-Dashboard.ps1
    ✔ Write GeminiSeedAdapter.ps1
    ✔ Write Watch-GeminiFolder.ps1
    □ List files and share usage

• Ran
  └ pwsh -NoProfile -Command '$root = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'
    Get-ChildItem -LiteralPath "'$root | Select-Object Name, Length, Mode | Format-Table -AutoSize | Out-String -Width
        200 | Write-Host'

  - Did not run adapter without a real seed (avoids “Input seed não encontrada”)

  - Change directory: cd D:\Teia\TEIA_NUCLEO\offline\nano
  - Save dashboard HTML (optional): pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1
  - Export a real seed from the dashboard into .\gemini_out\ (e.g., MySeed.teia.json)
  - Start watcher: pwsh -NoProfile -File .\Watch-GeminiFolder.ps1

  Manual Test (real file only)

  - pwsh -NoProfile -File .\GeminiSeedAdapter.ps1 -InputSeed .\gemini_out\<SeuArquivoReal>.teia.json
  - Logs: .\logs\gemini_adapter.log
  - Normalized seeds: .\seeds\, optional restore output: .\restored\ (uses teia if installed)



• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference = '"'Stop'
    "'$root = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'
    "'$path = Join-Path $root '"'TEIA-Gemini-Setup.ps1'
    "'$script = @'"'
    # TEIA-Gemini-Setup.ps1  (idempotente)
    # Cria pastas e grava 3 scripts: Save-Gemini-Dashboard.ps1, GeminiSeedAdapter.ps1, Watch-GeminiFolder.ps1

    "'$ErrorActionPreference = '"'Stop'

    # Bloqueio: não operar em System32
    if ((Get-Location).Path -match 'C:\\\\Windows\\\\System32') {
      Write-Host \"Pare: mude para D:\\Teia\\TEIA_NUCLEO\\offline\\nano antes de continuar.\"
      exit 1
    }

    # Pastas
    "'$dirs = @(".'"\\gemini_out\", \".\\logs\", \".\\seeds\", \".\\restored\")
    "'$dirs | ForEach-Object { if(-not (Test-Path -LiteralPath $_)){ New-Item -ItemType Directory -Force -Path $_
        | Out-Null } }

    # 1) Save-Gemini-Dashboard.ps1
    Set-Content -LiteralPath ".'"\\Save-Gemini-Dashboard.ps1\" -Encoding UTF8 -Value @'
    param(
      [string]"'$OutPath = ".'"\\compressor_gemini.html\"
    )
    "'$ErrorActionPreference = '"'Stop'
    if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)) {
      Write-Host \"Get-Clipboard não disponível. Cole o HTML via stdin e pressione Ctrl+Z e Enter:\"
      "'$html = [Console]::In.ReadToEnd()
    } else {
      $html = Get-Clipboard -Raw
    }
    if ([string]::IsNullOrWhiteSpace($html)) { throw "Conteúdo HTML vazio. Cole o HTML no clipboard ou passe por
        stdin." }
    Set-Content -LiteralPath $OutPath -Value $html -Encoding UTF8
    Write-Host "[OK] HTML salvo em: $OutPath"
    '"'@

    # 2) GeminiSeedAdapter.ps1  (normaliza e opcionalmente tenta restaurar)
    Set-Content -LiteralPath \".\\GeminiSeedAdapter.ps1\" -Encoding UTF8 -Value @'
    param(
      [string]"'$InputSeed,
      [string]$SeedsDir = ".'"\\seeds\",
      [string]"'$RestoredDir = ".'"\\restored\",
      [string]"'$IndexPath = ".'"\\seeds\\teia_anchor_index.json\",
      [string]"'$Log = ".'"\\logs\\gemini_adapter.log\",
      [switch]"'$AttemptRestore
    )
    $ErrorActionPreference = '"'Stop'
    "'$EnsureDir = { param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p
        | Out-Null } }
    $EnsureDir.Invoke((Split-Path -Parent $Log))
    $EnsureDir.Invoke($SeedsDir)
    $EnsureDir.Invoke($RestoredDir)

    function Log($m){ $t = (Get-Date).ToString("o"); "$t `t $m" | Out-File -FilePath $Log -Append -Encoding utf8 }

    if(-not (Test-Path -LiteralPath $InputSeed)){ throw "Input seed não encontrada: $InputSeed" }
    try {
      $raw = Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8
      $j = $raw | ConvertFrom-Json
    } catch {
      Log "ERR parse JSON: $($_.Exception.Message)"
      throw
    }

    # Normalizações básicas (idempotente)
    $target = if($j.target){ $j.target } else { ($InputSeed | Split-Path -Leaf) -replace '"'\\\\.teia.*"'$'"','' }
    "'$sha = if($j.sha256){ $j.sha256 } else { "" }
    $outSeed = Join-Path $SeedsDir ("$($target).$(if($sha){ $sha.Substring(0,12) } else { '"'unknown' }).teia.json\")

    # Persistência
    "'$j.version = if($j.version){ $j.version } else { "teia.public.v1" }
    $j.target  = $target
    $j.created = if($j.created){ $j.created } else { (Get-Date).ToString("o") }
    Set-Content -LiteralPath $outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8
    Log "OK wrote normalized seed: $outSeed"

    # Opcional: restore via teia-cli se disponível
    if($AttemptRestore -and (Get-Command teia -ErrorAction SilentlyContinue)){
      try{
        if(Test-Path -LiteralPath $IndexPath){
          Log "Attempting restore-index for $outSeed using index $IndexPath"
          & teia restore-index -seed $outSeed -index $IndexPath -out (Join-Path $RestoredDir $target) 2>&1 | Out-File
        -FilePath $Log -Append -Encoding utf8
          Log "Restore-index completed for $target"
        } else {
          Log "Index not present, skipping restore-index"
        }
      } catch {
        Log "ERR during restore: $($_.Exception.Message)"
      }
    }

    Write-Host "[OK] Adapter processed: $outSeed"
    '"'@

    # 3) Watch-GeminiFolder.ps1  (processa todo .teia.json novo em .\\gemini_out\\)
    Set-Content -LiteralPath \".\\Watch-GeminiFolder.ps1\" -Encoding UTF8 -Value @'
    param(
      [string]"'$Folder = ".'"\\gemini_out\"
    )
    "'$ErrorActionPreference = '"'Stop'
    if(-not (Test-Path "'$Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }
    $fsw = New-Object System.IO.FileSystemWatcher $Folder, "*.teia.json"
    $fsw.IncludeSubdirectories = $false
    $fsw.EnableRaisingEvents = $true

    $action = {
      $path = $Event.SourceEventArgs.FullPath
      Write-Host "Novo arquivo detectado: $path"


• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference = '"'Stop'
    "'$root = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'
    "'$path = Join-Path $root '"'TEIA-Gemini-Setup.ps1'
    "'$script = @"
    # TEIA-Gemini-Setup.ps1  (idempotente)
    # Cria pastas e grava 3 scripts: Save-Gemini-Dashboard.ps1, GeminiSeedAdapter.ps1, Watch-GeminiFolder.ps1

    `$ErrorActionPreference = '"'Stop'

    # Bloqueio: não operar em System32
    if ((Get-Location).Path -match 'C:\\\\Windows\\\\System32') {
      Write-Host \"Pare: mude para D:\\Teia\\TEIA_NUCLEO\\offline\\nano antes de continuar.\"
      exit 1
    }

    # Pastas
    "'`$dirs = @(".'"\\gemini_out\", \".\\logs\", \".\\seeds\", \".\\restored\")
    "'`$dirs | ForEach-Object { if(-not (Test-Path -LiteralPath `$_)){ New-Item -ItemType Directory -Force -Path `$_
        | Out-Null } }

    # 1) Save-Gemini-Dashboard.ps1
    Set-Content -LiteralPath ".'"\\Save-Gemini-Dashboard.ps1\" -Encoding UTF8 -Value @'
    param(
      [string]"'$OutPath = ".'"\\compressor_gemini.html\"
    )
    "'$ErrorActionPreference = '"'Stop'
    if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)) {
      Write-Host \"Get-Clipboard não disponível. Cole o HTML via stdin e pressione Ctrl+Z e Enter:\"
      "'$html = [Console]::In.ReadToEnd()
    } else {
      $html = Get-Clipboard -Raw
    }
    if ([string]::IsNullOrWhiteSpace($html)) { throw "Conteúdo HTML vazio. Cole o HTML no clipboard ou passe por
        stdin." }
    Set-Content -LiteralPath $OutPath -Value $html -Encoding UTF8
    Write-Host "[OK] HTML salvo em: $OutPath"
    '"'@

    # 2) GeminiSeedAdapter.ps1  (normaliza e opcionalmente tenta restaurar)
    Set-Content -LiteralPath \".\\GeminiSeedAdapter.ps1\" -Encoding UTF8 -Value @'
    param(
      [string]"'$InputSeed,
      [string]$SeedsDir = ".'"\\seeds\",
      [string]"'$RestoredDir = ".'"\\restored\",
      [string]"'$IndexPath = ".'"\\seeds\\teia_anchor_index.json\",
      [string]"'$Log = ".'"\\logs\\gemini_adapter.log\",
      [switch]"'$AttemptRestore
    )
    $ErrorActionPreference = '"'Stop'
    "'$EnsureDir = { param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p
        | Out-Null } }
    $EnsureDir.Invoke((Split-Path -Parent $Log))
    $EnsureDir.Invoke($SeedsDir)
    $EnsureDir.Invoke($RestoredDir)

    function Log($m){ $t = (Get-Date).ToString("o"); "$t `t $m" | Out-File -FilePath $Log -Append -Encoding utf8 }

    if(-not (Test-Path -LiteralPath $InputSeed)){ throw "Input seed não encontrada: $InputSeed" }
    try {
      $raw = Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8
      $j = $raw | ConvertFrom-Json
    } catch {
      Log "ERR parse JSON: $($_.Exception.Message)"
      throw
    }

    # Normalizações básicas (idempotente)
    $target = if($j.target){ $j.target } else { ($InputSeed | Split-Path -Leaf) -replace '"'\\.teia.*"'$'"','' }
    "'$sha = if($j.sha256){ $j.sha256 } else { "" }
    $outSeed = Join-Path $SeedsDir ("$($target).$(if($sha){ $sha.Substring(0,12) } else { '"'unknown' }).teia.json\")

    # Persistência
    "'$j.version = if($j.version){ $j.version } else { "teia.public.v1" }
    $j.target  = $target
    $j.created = if($j.created){ $j.created } else { (Get-Date).ToString("o") }
    Set-Content -LiteralPath $outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8
    Log "OK wrote normalized seed: $outSeed"

    # Opcional: restore via teia-cli se disponível
    if($AttemptRestore -and (Get-Command teia -ErrorAction SilentlyContinue)){
      try{
        if(Test-Path -LiteralPath $IndexPath){
          Log "Attempting restore-index for $outSeed using index $IndexPath"
          & teia restore-index -seed $outSeed -index $IndexPath -out (Join-Path $RestoredDir $target) 2>&1 | Out-File
        -FilePath $Log -Append -Encoding utf8
          Log "Restore-index completed for $target"
        } else {
          Log "Index not present, skipping restore-index"
        }
      } catch {
        Log "ERR during restore: $($_.Exception.Message)"
      }
    }

    Write-Host "[OK] Adapter processed: $outSeed"
    '"'@

    # 3) Watch-GeminiFolder.ps1  (processa todo .teia.json novo em .\\gemini_out\\)
    Set-Content -LiteralPath \".\\Watch-GeminiFolder.ps1\" -Encoding UTF8 -Value @'
    param(
      [string]"'$Folder = ".'"\\gemini_out\"
    )
    "'$ErrorActionPreference = '"'Stop'
    if(-not (Test-Path "'$Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }
    $fsw = New-Object System.IO.FileSystemWatcher $Folder, "*.teia.json"
    $fsw.IncludeSubdirectories = $false
    $fsw.EnableRaisingEvents = $true

    $action = {
      $path = $Event.SourceEventArgs.FullPath
      Write-Host "Novo arquivo detectado: $path"
      Start-Sleep -Milliseconds 500
      try {
        $adapterScriptPath = Join-Path (Get-Location) '"'GeminiSeedAdapter.ps1'
        pwsh -NoProfile -File "'$adapterScriptPath -InputSeed $path -AttemptRestore
      } catch {
        Write-Host "Watcher ERR: $($_.Exception.Message)"
      }
    }
    } finally {
      Unregister-Event -SubscriptionId $watcher.Id
    "@
    Set-Content -LiteralPath $path -Value $script -Encoding UTF8
    Write-Host "[OK] Wrote $path"'

• Updated Plan
  └ ✔ Create target folders on D:\
    ✔ Write Save-Gemini-Dashboard.ps1
    ✔ Write GeminiSeedAdapter.ps1
    ✔ Write Watch-GeminiFolder.ps1
    ✔ Write TEIA-Gemini-Setup.ps1
    □ List files and share usage

• Ran
  └ pwsh -NoProfile -Command '$root = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'; Get-ChildItem -LiteralPath "'$root
        -Filter '"'*Gemini*Setup*.ps1','*Gemini*.ps1' | Select-Object Name, Length | Format-Table -AutoSize | Out-String
        -Width 200 | Write-Host"
    Get-ChildItem: Cannot convert 'System.Object[]' to the type 'System.String' required by parameter 'Filter'.
    Specified method is not supported.

• Ran
  └ pwsh -NoProfile -Command '$root = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano';
    "'$files = '"'TEIA-Gemini-Setup.ps1','Save-Gemini-Dashboard.ps1','GeminiSeedAdapter.ps1','Watch-GeminiFolder.ps1';
    Get-ChildItem -LiteralPath "'$root | Where-Object { $files -contains $_.Name } | Select-Object Name,Length |
        Format-Table -AutoSize | Out-String -Width 200 | Write-Host'

> All set. The bootstrap is in place alongside the three scripts. You can run your exact commands now.

  What I did

  - Added D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Gemini-Setup.ps1 (idempotent)
  - Confirmed scripts present: Save-Gemini-Dashboard.ps1, GeminiSeedAdapter.ps1, Watch-GeminiFolder.ps1
  - Ensured nothing runs from C:\Windows\System32

  Run

  - cd D:\Teia\TEIA_NUCLEO\offline\nano
  - pwsh -NoProfile -File .\TEIA-Gemini-Setup.ps1
  - pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1
  - Open .\compressor_gemini.html, export a real .teia.json into .\gemini_out\
  - pwsh -NoProfile -File .\Watch-GeminiFolder.ps1

  Notes

  - Adapter logs: .\logs\gemini_adapter.log
  - Normalized seeds: .\seeds\
  - Restore output (if teia CLI present): .\restored\
  - The watcher triggers automatically for each real .teia.json in .\gemini_out\

---

### ASSISTENTE

Scripts criados com aspas corrompidas. Regrave tudo limpo e valide a sintaxe.

```powershell
# Fix-Gemini-Scripts.ps1  (idempotente)
$ErrorActionPreference = 'Stop'

# Não rode em System32
if ((Get-Location).Path -match 'C:\\Windows\\System32') { Write-Host 'Mude para D:\Teia\TEIA_NUCLEO\offline\nano'; exit 1 }

# Pastas base
foreach($d in @('.\gemini_out','.\logs','.\seeds','.\restored')){ if(-not(Test-Path $d)){ New-Item -ItemType Directory -Force -Path $d | Out-Null } }

# 1) Save-Gemini-Dashboard.ps1
Set-Content -LiteralPath '.\Save-Gemini-Dashboard.ps1' -Encoding UTF8 -Value @'
param(
  [string]$OutPath = ".\compressor_gemini.html"
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)) {
  Write-Host "Get-Clipboard não disponível. Cole o HTML via stdin e pressione Ctrl+Z e Enter:"
  $html = [Console]::In.ReadToEnd()
} else {
  $html = Get-Clipboard -Raw
}
if ([string]::IsNullOrWhiteSpace($html)) { throw "Conteúdo HTML vazio. Cole o HTML no clipboard ou passe por stdin." }
Set-Content -LiteralPath $OutPath -Value $html -Encoding UTF8
Write-Host "[OK] HTML salvo em: $OutPath"
'@

# 2) GeminiSeedAdapter.ps1
Set-Content -LiteralPath '.\GeminiSeedAdapter.ps1' -Encoding UTF8 -Value @'
param(
  [string]$InputSeed,
  [string]$SeedsDir = ".\seeds",
  [string]$RestoredDir = ".\restored",
  [string]$IndexPath = ".\seeds\teia_anchor_index.json",
  [string]$Log = ".\logs\gemini_adapter.log",
  [switch]$AttemptRestore
)
$ErrorActionPreference = 'Stop'
$EnsureDir = { param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
$EnsureDir.Invoke((Split-Path -Parent $Log))
$EnsureDir.Invoke($SeedsDir)
$EnsureDir.Invoke($RestoredDir)

function Log($m){ $t = (Get-Date).ToString("o"); "$t `t $m" | Out-File -FilePath $Log -Append -Encoding utf8 }

if(-not (Test-Path -LiteralPath $InputSeed)){ throw "Input seed não encontrada: $InputSeed" }
try {
  $raw = Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8
  $j = $raw | ConvertFrom-Json
} catch {
  Log "ERR parse JSON: $($_.Exception.Message)"
  throw
}

# Normalizações
$target = if($j.target){ $j.target } else { ($InputSeed | Split-Path -Leaf) -replace '\.teia.*$','' }
$sha = if($j.sha256){ $j.sha256 } else { "" }
$outSeed = Join-Path $SeedsDir ("$($target).$(if($sha){ $sha.Substring(0,12) } else { 'unknown' }).teia.json")

# Persistência
$j.version = if($j.version){ $j.version } else { "teia.public.v1" }
$j.target  = $target
$j.created = if($j.created){ $j.created } else { (Get-Date).ToString("o") }
Set-Content -LiteralPath $outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8
Log "OK wrote normalized seed: $outSeed"

# Opcional: restore via teia-cli se disponível
if($AttemptRestore -and (Get-Command teia -ErrorAction SilentlyContinue)){
  try{
    if(Test-Path -LiteralPath $IndexPath){
      Log "Attempting restore-index for $outSeed using index $IndexPath"
      & teia restore-index -seed $outSeed -index $IndexPath -out (Join-Path $RestoredDir $target) 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
      Log "Restore-index completed for $target"
    } else {
      Log "Index not present, skipping restore-index"
    }
  } catch {
    Log "ERR during restore: $($_.Exception.Message)"
  }
}

Write-Host "[OK] Adapter processed: $outSeed"
'@

# 3) Watch-GeminiFolder.ps1
Set-Content -LiteralPath '.\Watch-GeminiFolder.ps1' -Encoding UTF8 -Value @'
param(
  [string]$Folder = ".\gemini_out"
)
$ErrorActionPreference = 'Stop'
if(-not (Test-Path $Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }
$fsw = New-Object System.IO.FileSystemWatcher $Folder, "*.teia.json"
$fsw.IncludeSubdirectories = $false
$fsw.EnableRaisingEvents = $true

$action = {
  $path = $Event.SourceEventArgs.FullPath
  Write-Host "Novo arquivo detectado: $path"
  Start-Sleep -Milliseconds 500
  try {
    $adapterScriptPath = Join-Path (Get-Location) 'GeminiSeedAdapter.ps1'
    pwsh -NoProfile -File $adapterScriptPath -InputSeed $path -AttemptRestore
  } catch {
    Write-Host "Watcher ERR: $($_.Exception.Message)"
  }
}

$watcher = Register-ObjectEvent $fsw Created -Action $action
Write-Host "Watcher ativo em: $Folder. Pressione Ctrl+C para sair."
try {
  while ($true) { Wait-Event -Timeout 60 }
} finally {
  Unregister-Event -SubscriptionId $watcher.Id
  $fsw.Dispose()
  Write-Host "Watcher parado."
}
'@

# 4) (opcional) TEIA-Gemini-Setup.ps1 que recria os três acima
Set-Content -LiteralPath '.\TEIA-Gemini-Setup.ps1' -Encoding UTF8 -Value @'
$ErrorActionPreference = "Stop"
if ((Get-Location).Path -match "C:\\Windows\\System32") { Write-Host "Stop: rode fora do System32."; exit 1 }
foreach($d in @(".\gemini_out",".\logs",".\seeds",".\restored")){ if(-not(Test-Path $d)){ New-Item -ItemType Directory -Force -Path $d | Out-Null } }
Copy-Item -LiteralPath ".\Save-Gemini-Dashboard.ps1" -Destination ".\Save-Gemini-Dashboard.ps1" -Force
Copy-Item -LiteralPath ".\GeminiSeedAdapter.ps1"   -Destination ".\GeminiSeedAdapter.ps1"   -Force
Copy-Item -LiteralPath ".\Watch-GeminiFolder.ps1"  -Destination ".\Watch-GeminiFolder.ps1"  -Force
Write-Host "[OK] Setup pronto."
'@

# Lint rápido dos .ps1
Add-Type -AssemblyName System.Management.Automation
$files = @('.\Save-Gemini-Dashboard.ps1','.\GeminiSeedAdapter.ps1','.\Watch-GeminiFolder.ps1','.\TEIA-Gemini-Setup.ps1')
foreach($f in $files){
  $null = $tokens = $errors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $f), [ref]$tokens, [ref]$errors)
  if($errors -and $errors.Count -gt 0){ throw "Sintaxe inválida em $f: $($errors[0].Message)" } else { Write-Host "[OK] Lint: $f" }
}
Write-Host "[OK] Scripts regravados e validados."
```

Instruções:
1) `cd D:\Teia\TEIA_NUCLEO\offline\nano`  
2) `pwsh -NoProfile -File .\Fix-Gemini-Scripts.ps1`  
3) Abra `.\compressor_gemini.html` e exporte uma seed real para `.\gemini_out\`  
4) `pwsh -NoProfile -File .\Watch-GeminiFolder.ps1`

---

### USUÁRIO

...• Updated Plan
  └ ✔ Rewrite four scripts cleanly
    ✔ Validate syntax (lint)
    □ Confirm files present and sizes

• Ran
  └ pwsh -NoProfile -Command '$root='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'; Set-Location "'$root; Get-ChildItem -Name
        *.ps1 | Sort-Object | % { '"'{0,-28} {1,7}' -f "'$_, (Get-Item $_).Length } | Write-Host'

> Regravei os 4 scripts com aspas limpas e validei a sintaxe. Também corrigi o TEIA-Gemini-Setup.ps1 (o here-string
  estava sem terminador).

  Feito

  - Reescritos: .\Save-Gemini-Dashboard.ps1, .\GeminiSeedAdapter.ps1, .\Watch-GeminiFolder.ps1, .\TEIA-Gemini-Setup.ps1
  - Lint OK (Parser): todos sem erros
  - Pastas já garantidas: .\gemini_out, .\logs, .\seeds, .\restored

  Como usar

  - cd D:\Teia\TEIA_NUCLEO\offline\nano
  - pwsh -NoProfile -File .\TEIA-Gemini-Setup.ps1
  - pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1
  - Abra .\compressor_gemini.html, exporte uma seed real .teia.json para .\gemini_out\
  - pwsh -NoProfile -File .\Watch-GeminiFolder.ps1

  Validações

  - Logs do adapter: .\logs\gemini_adapter.log
  - Seeds normalizadas: .\seeds\
  - Restore opcional (se teia instalado): .\restored\

  Quer que eu também gere o Fix-Gemini-Scripts.ps1 exatamente como no seu esboço para manter como utilitário de reparo?
  Posso adicionar já e rodar um lint nele também.

---

### ASSISTENTE

Sim. Segue o utilitário de reparo.

```powershell
# Cria Fix-Gemini-Scripts.ps1 (embed Codex)
Set-Content -LiteralPath '.\Fix-Gemini-Scripts.ps1' -Encoding UTF8 -Value @'
# Fix-Gemini-Scripts.ps1  (idempotente)
$ErrorActionPreference = 'Stop'

# Bloqueio System32
if ((Get-Location).Path -match 'C:\\Windows\\System32') { Write-Host 'Mude para D:\Teia\TEIA_NUCLEO\offline\nano'; exit 1 }

# Pastas base
foreach($d in @('.\gemini_out','.\logs','.\seeds','.\restored')){
  if(-not(Test-Path -LiteralPath $d)){ New-Item -ItemType Directory -Force -Path $d | Out-Null }
}

# 1) Save-Gemini-Dashboard.ps1
Set-Content -LiteralPath '.\Save-Gemini-Dashboard.ps1' -Encoding UTF8 -Value @'
param(
  [string]$OutPath = ".\compressor_gemini.html"
)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)) {
  Write-Host "Get-Clipboard não disponível. Cole o HTML via stdin e pressione Ctrl+Z e Enter:"
  $html = [Console]::In.ReadToEnd()
} else {
  $html = Get-Clipboard -Raw
}
if ([string]::IsNullOrWhiteSpace($html)) { throw "Conteúdo HTML vazio. Cole o HTML no clipboard ou passe por stdin." }
Set-Content -LiteralPath $OutPath -Value $html -Encoding UTF8
Write-Host "[OK] HTML salvo em: $OutPath"
'@

# 2) GeminiSeedAdapter.ps1
Set-Content -LiteralPath '.\GeminiSeedAdapter.ps1' -Encoding UTF8 -Value @'
param(
  [string]$InputSeed,
  [string]$SeedsDir = ".\seeds",
  [string]$RestoredDir = ".\restored",
  [string]$IndexPath = ".\seeds\teia_anchor_index.json",
  [string]$Log = ".\logs\gemini_adapter.log",
  [switch]$AttemptRestore
)
$ErrorActionPreference = 'Stop'
$EnsureDir = { param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
$EnsureDir.Invoke((Split-Path -Parent $Log))
$EnsureDir.Invoke($SeedsDir)
$EnsureDir.Invoke($RestoredDir)

function Log($m){ $t = (Get-Date).ToString("o"); "$t `t $m" | Out-File -FilePath $Log -Append -Encoding utf8 }

if(-not (Test-Path -LiteralPath $InputSeed)){ throw "Input seed não encontrada: $InputSeed" }
try {
  $raw = Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8
  $j = $raw | ConvertFrom-Json
} catch {
  Log "ERR parse JSON: $($_.Exception.Message)"
  throw
}

# Normalizações
$target = if($j.target){ $j.target } else { ($InputSeed | Split-Path -Leaf) -replace '\.teia.*$','' }
$sha = if($j.sha256){ $j.sha256 } else { "" }
$outSeed = Join-Path $SeedsDir ("$($target).$(if($sha){ $sha.Substring(0,12) } else { 'unknown' }).teia.json")

# Persistência
$j.version = if($j.version){ $j.version } else { "teia.public.v1" }
$j.target  = $target
$j.created = if($j.created){ $j.created } else { (Get-Date).ToString("o") }
Set-Content -LiteralPath $outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8
Log "OK wrote normalized seed: $outSeed"

# Opcional: restore via teia-cli se disponível
if($AttemptRestore -and (Get-Command teia -ErrorAction SilentlyContinue)){
  try{
    if(Test-Path -LiteralPath $IndexPath){
      Log "Attempting restore-index for $outSeed using index $IndexPath"
      & teia restore-index -seed $outSeed -index $IndexPath -out (Join-Path $RestoredDir $target) 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
      Log "Restore-index completed for $target"
    } else {
      Log "Index not present, skipping restore-index"
    }
  } catch {
    Log "ERR during restore: $($_.Exception.Message)"
  }
}

Write-Host "[OK] Adapter processed: $outSeed"
'@

# 3) Watch-GeminiFolder.ps1
Set-Content -LiteralPath '.\Watch-GeminiFolder.ps1' -Encoding UTF8 -Value @'
param(
  [string]$Folder = ".\gemini_out"
)
$ErrorActionPreference = 'Stop'
if(-not (Test-Path $Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }
$fsw = New-Object System.IO.FileSystemWatcher $Folder, "*.teia.json"
$fsw.IncludeSubdirectories = $false
$fsw.EnableRaisingEvents = $true

$action = {
  $path = $Event.SourceEventArgs.FullPath
  Write-Host "Novo arquivo detectado: $path"
  Start-Sleep -Milliseconds 500
  try {
    $adapterScriptPath = Join-Path (Get-Location) 'GeminiSeedAdapter.ps1'
    pwsh -NoProfile -File $adapterScriptPath -InputSeed $path -AttemptRestore
  } catch {
    Write-Host "Watcher ERR: $($_.Exception.Message)"
  }
}

$watcher = Register-ObjectEvent $fsw Created -Action $action
Write-Host "Watcher ativo em: $Folder. Pressione Ctrl+C para sair."
try {
  while ($true) { Wait-Event -Timeout 60 }
} finally {
  Unregister-Event -SubscriptionId $watcher.Id
  $fsw.Dispose()
  Write-Host "Watcher parado."
}
'@

# 4) TEIA-Gemini-Setup.ps1
Set-Content -LiteralPath '.\TEIA-Gemini-Setup.ps1' -Encoding UTF8 -Value @'
$ErrorActionPreference = "Stop"
if ((Get-Location).Path -match "C:\\Windows\\System32") { Write-Host "Stop: rode fora do System32."; exit 1 }
foreach($d in @(".\gemini_out",".\logs",".\seeds",".\restored")){
  if(-not(Test-Path -LiteralPath $d)){ New-Item -ItemType Directory -Force -Path $d | Out-Null }
}
Write-Host "[OK] Setup pronto."
'@

# Lint
Add-Type -AssemblyName System.Management.Automation
$files = @('.\Save-Gemini-Dashboard.ps1','.\GeminiSeedAdapter.ps1','.\Watch-GeminiFolder.ps1','.\TEIA-Gemini-Setup.ps1')
foreach($f in $files){
  $null = $tokens = $errors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $f), [ref]$tokens, [ref]$errors)
  if($errors -and $errors.Count -gt 0){
    throw "Sintaxe inválida em $f: $($errors[0].Message)"
  } else {
    Write-Host "[OK] Lint: $f"
  }
}
Write-Host "[OK] Reparos concluídos."
'@
```

Uso rápido:
1) `cd D:\Teia\TEIA_NUCLEO\offline\nano`  
2) `pwsh -NoProfile -File .\Fix-Gemini-Scripts.ps1`  
3) Abra `.\compressor_gemini.html` e exporte uma seed real para `.\gemini_out\`  
4) `pwsh -NoProfile -File .\Watch-GeminiFolder.ps1`

---

### USUÁRIO

"• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference = '"'Stop'
    Set-Location 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'
    "'$fp = '"'.\\Fix-Gemini-Scripts.ps1'
    if(Test-Path "'$fp){ Remove-Item -LiteralPath $fp -Force }
    function AL([string]$s){ Add-Content -LiteralPath $fp -Value $s -Encoding UTF8 }
    AL "# Fix-Gemini-Scripts.ps1  (idempotente)"
    AL "$ErrorActionPreference = '"'Stop'\"
    AL \"\"
    AL \"# Bloqueio System32\"
    AL \"if ((Get-Location).Path -match 'C:\\\\Windows\\\\System32') { Write-Host 'Mude para D:\\Teia\\TEIA_NUCLEO\
        \offline\\nano'; exit 1 }\"
    AL \"\"
    AL \"# Pastas base\"
    AL \"foreach("'$d in @('"'.\\\\gemini_out','.\\\\logs','.\\\\seeds','.\\\\restored')){\"
    AL \"  if(-not(Test-Path -LiteralPath "'$d)){ New-Item -ItemType Directory -Force -Path $d | Out-Null }"
    AL "}"
    AL ""
    AL "# 1) Save-Gemini-Dashboard.ps1"
    AL "Set-Content -LiteralPath '"'.\\\\Save-Gemini-Dashboard.ps1' -Encoding UTF8 -Value @'\"
    AL \"param(\"
    AL \"  [string]"'$OutPath = '"'.\\\\compressor_gemini.html'\"
    AL \")\"
    AL \""'$ErrorActionPreference = '"'Stop'\"
    AL \"if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)) {\"
    AL \"  Write-Host \\\"Get-Clipboard não disponível. Cole o HTML via stdin e pressione Ctrl+Z e Enter:\\\"\"
    AL \"  "'$html = [Console]::In.ReadToEnd()"
    AL "} else {"
    AL "  $html = Get-Clipboard -Raw"
    AL "}"
    AL "if ([string]::IsNullOrWhiteSpace($html)) { throw '"\\\"Conteúdo HTML vazio. Cole o HTML no clipboard ou passe
        por stdin.\\\" }\"
    AL \"Set-Content -LiteralPath "'$OutPath -Value $html -Encoding UTF8"
    AL "Write-Host '"\\\"[OK] HTML salvo em: "'$OutPath'"\\\"\"
    AL \"'@\"
    AL \"\"
    AL \"# 2) GeminiSeedAdapter.ps1\"
    AL \"Set-Content -LiteralPath '.\\\\GeminiSeedAdapter.ps1' -Encoding UTF8 -Value @'\"
    AL \"param(\"
    AL \"  [string]"'$InputSeed,"
    AL "  [string]$SeedsDir = '"'.\\\\seeds',\"
    AL \"  [string]"'$RestoredDir = '"'.\\\\restored',\"
    AL \"  [string]"'$IndexPath = '"'.\\\\seeds\\\\teia_anchor_index.json',\"
    AL \"  [string]"'$Log = '"'.\\\\logs\\\\gemini_adapter.log',\"
    AL \"  [switch]"'$AttemptRestore"
    AL ")"
    AL "$ErrorActionPreference = '"'Stop'\"
    AL \""'$EnsureDir = { param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p
        | Out-Null } }"
    AL "$EnsureDir.Invoke((Split-Path -Parent $Log))"
    AL "$EnsureDir.Invoke($SeedsDir)"
    AL "$EnsureDir.Invoke($RestoredDir)"
    AL ""
    AL "function Log($m){ $t = (Get-Date).ToString('"\\\"o\\\"); \\\""'$t `t $m'"\\\" | Out-File -FilePath "'$Log
        -Append -Encoding utf8 }"
    AL ""
    AL "if(-not (Test-Path -LiteralPath $InputSeed)){ throw '"\\\"Input seed não encontrada: "'$InputSeed'"\\\" }\"
    AL \"try {\"
    AL \"  "'$raw = Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8"
    AL "  $j = $raw | ConvertFrom-Json"
    AL "} catch {"
    AL "  Log '"\\\"ERR parse JSON: "'$($_.Exception.Message)'"\\\"\"
    AL \"  throw\"
    AL \"}\"
    AL \"\"
    AL \"# Normalizações\"
    AL \""'$target = if($j.target){ $j.target } else { ($InputSeed | Split-Path -Leaf) -replace '"'\\\\.teia.*"'$'"',
        '' }\"
    AL \""'$sha = if($j.sha256){ $j.sha256 } else { '"\\\"\\\" }\"
    AL \""'$outSeed = Join-Path $SeedsDir ('"\\\""'$($target).$(if($sha){ $sha.Substring(0,12) } else
        { '"'unknown' }).teia.json\\\")\"
    AL \"\"
    AL \"# Persistência\"
    AL \""'$j.version = if($j.version){ $j.version } else { '"\\\"teia.public.v1\\\" }\"
    AL \""'$j.target  = $target"
    AL "$j.created = if($j.created){ $j.created } else { (Get-Date).ToString('"\\\"o\\\") }\"
    AL \"Set-Content -LiteralPath "'$outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8"
    AL "Log '"\\\"OK wrote normalized seed: "'$outSeed'"\\\"\"
    AL \"\"
    AL \"# Opcional: restore via teia-cli se disponível\"
    AL \"if("'$AttemptRestore -and (Get-Command teia -ErrorAction SilentlyContinue)){"
    AL "  try{"
    AL "    if(Test-Path -LiteralPath $IndexPath){"
    AL "      Log '"\\\"Attempting restore-index for "'$outSeed using index $IndexPath'"\\\"\"
    AL \"      & teia restore-index -seed "'$outSeed -index $IndexPath -out (Join-Path $RestoredDir $target) 2>&1 |
        Out-File -FilePath $Log -Append -Encoding utf8"
    AL "      Log '"\\\"Restore-index completed for "'$target'"\\\"\"
    AL \"    } else {\"
    AL \"      Log \\\"Index not present, skipping restore-index\\\"\"
    AL \"    }\"
    AL \"  } catch {\"
    AL \"    Log \\\"ERR during restore: "'$($_.Exception.Message)'"\\\"\"
    AL \"  }\"
    AL \"}\"
    AL \"\"
    AL \"Write-Host \\\"[OK] Adapter processed: "'$outSeed'"\\\"\"
    AL \"'@\"
    AL \"\"
    AL \"# 3) Watch-GeminiFolder.ps1\"
    AL \"Set-Content -LiteralPath '.\\\\Watch-GeminiFolder.ps1' -Encoding UTF8 -Value @'\"
    AL \"param(\"
    AL \"  [string]"'$Folder = '"'.\\\\gemini_out'\"
    AL \")\"
    AL \""'$ErrorActionPreference = '"'Stop'\"
    AL \"if(-not (Test-Path "'$Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }"
    AL "$fsw = New-Object System.IO.FileSystemWatcher $Folder, '"\\\"*.teia.json\\\"\"
    AL \""'$fsw.IncludeSubdirectories = $false"
    AL "$fsw.EnableRaisingEvents = $true"
    AL ""
    AL "$action = {"
    AL "  $path = $Event.SourceEventArgs.FullPath"
    AL "  Write-Host '"\\\"Novo arquivo detectado: "'$path'"\\\"\"
    AL \"  Start-Sleep -Milliseconds 500\"
    AL \"  try {\"
    AL \"    "'$adapterScriptPath = Join-Path (Get-Location) '"'GeminiSeedAdapter.ps1'\"
    AL \"    pwsh -NoProfile -File "'$adapterScriptPath -InputSeed $path -AttemptRestore"
    AL "  } catch {"
    AL "    Write-Host '"\\\"Watcher ERR: "'$($_.Exception.Message)'"\\\"\"
    AL \"  }\"
    AL \"}\"
    AL \"\"
    AL \""'$watcher = Register-ObjectEvent $fsw Created -Action $action"
    AL "Write-Host '"\\\"Watcher ativo em: "'$Folder. Pressione Ctrl+C para sair.'"\\\"\"
    AL \"try {\"
    AL \"  while ("'$true) { Wait-Event -Timeout 60 }"
    AL "} finally {"
    AL "  Unregister-Event -SubscriptionId $watcher.Id"
    AL "  $fsw.Dispose()"
    AL "  Write-Host '"\\\"Watcher parado.\\\"\"
    AL \"}\"
    AL \"'@\"
    AL \"\"
    AL \"# 4) TEIA-Gemini-Setup.ps1\"
    AL \"Set-Content -LiteralPath '.\\\\TEIA-Gemini-Setup.ps1' -Encoding UTF8 -Value @'\"
    AL \""'$ErrorActionPreference = '"\\\"Stop\\\"\"
    AL \"if ((Get-Location).Path -match \\\"C:\\\\Windows\\\\System32\\\") { Write-Host \\\"Stop: rode fora do System32.
        \\\"; exit 1 }\"
    AL \"foreach("'$d in @('"'.\\\\gemini_out','.\\\\logs','.\\\\seeds','.\\\\restored')){\"
    AL \"  if(-not(Test-Path -LiteralPath "'$d)){ New-Item -ItemType Directory -Force -Path $d | Out-Null }"
    AL "}"


• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference = '"'Stop'
    Set-Location 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'
    "'$fp = '"'.\\Fix-Gemini-Scripts.ps1'
    if(Test-Path "'$fp){ Remove-Item -LiteralPath $fp -Force }
    function AL([string]$s){ Add-Content -LiteralPath $fp -Value $s -Encoding UTF8 }
    AL '"'# Fix-Gemini-Scripts.ps1  (idempotente)'
    AL '"'$ErrorActionPreference = '"''Stop'''
    AL ''
    AL '# Bloqueio System32'
    AL 'if ((Get-Location).Path -match ''C:\\Windows\\System32'') { Write-Host ''Mude para D:\\Teia\\TEIA_NUCLEO\
        \offline\\nano''; exit 1 }'
    AL ''
    AL '# Pastas base'
    AL 'foreach("'$d in @('"''.\\gemini_out'',''.\\logs'',''.\\seeds'',''.\\restored'')) {'
    AL '  if(-not(Test-Path -LiteralPath "'$d)){ New-Item -ItemType Directory -Force -Path $d | Out-Null }'"'
    AL '}'
    AL ''
    AL '# 1) Save-Gemini-Dashboard.ps1'
    AL 'Set-Content -LiteralPath ''.\\Save-Gemini-Dashboard.ps1'' -Encoding UTF8 -Value @'''
    AL 'param('
    AL '  [string]"'$OutPath = '"''.\\compressor_gemini.html'''
    AL ')'
    AL '"'$ErrorActionPreference = '"''Stop'''
    AL 'if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)) {'
    AL '  Write-Host \"Get-Clipboard não disponível. Cole o HTML via stdin e pressione Ctrl+Z e Enter:\"'
    AL '  "'$html = [Console]::In.ReadToEnd()'"'
    AL '} else {'
    AL '  "'$html = Get-Clipboard -Raw'"'
    AL '}'
    AL 'if ([string]::IsNullOrWhiteSpace("'$html)) { throw "Conteúdo HTML vazio. Cole o HTML no clipboard ou passe por
        stdin." }'"'
    AL 'Set-Content -LiteralPath "'$OutPath -Value $html -Encoding UTF8'"'
    AL 'Write-Host \"[OK] HTML salvo em: "'$OutPath"'"'
    AL '''@'
    AL ''
    AL '# 2) GeminiSeedAdapter.ps1'
    AL 'Set-Content -LiteralPath ''.\\GeminiSeedAdapter.ps1'' -Encoding UTF8 -Value @'''
    AL 'param('
    AL '  [string]"'$InputSeed,'"'
    AL '  [string]"'$SeedsDir = '"''.\\seeds'','
    AL '  [string]"'$RestoredDir = '"''.\\restored'','
    AL '  [string]"'$IndexPath = '"''.\\seeds\\teia_anchor_index.json'','
    AL '  [string]"'$Log = '"''.\\logs\\gemini_adapter.log'','
    AL '  [switch]"'$AttemptRestore'"'
    AL ')'
    AL '"'$ErrorActionPreference = '"''Stop'''
    AL '"'$EnsureDir = { param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p
        | Out-Null } }'"'
    AL '"'$EnsureDir.Invoke((Split-Path -Parent $Log))'"'
    AL '"'$EnsureDir.Invoke($SeedsDir)'"'
    AL '"'$EnsureDir.Invoke($RestoredDir)'"'
    AL ''
    AL 'function Log("'$m){ $t = (Get-Date).ToString("o"); "$t `t $m" | Out-File -FilePath $Log -Append -Encoding
        utf8 }'"'
    AL ''
    AL 'if(-not (Test-Path -LiteralPath "'$InputSeed)){ throw "Input seed não encontrada: $InputSeed" }'"'
    AL 'try {'
    AL '  "'$raw = Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8'"'
    AL '  "'$j = $raw | ConvertFrom-Json'"'
    AL '} catch {'
    AL '  Log \"ERR parse JSON: "'$($_.Exception.Message)"'"'
    AL '  throw'
    AL '}'
    AL ''
    AL '# Normalizações'
    AL '"'$target = if($j.target){ $j.target } else { ($InputSeed | Split-Path -Leaf) -replace '"''\
        \.teia.*"'$'"'','''' }'
    AL '"'$sha = if($j.sha256){ $j.sha256 } else { "" }'"'
    AL '"'$outSeed = Join-Path $SeedsDir ("$($target).$(if($sha){ $sha.Substring(0,12) } else
        { '"''unknown'' }).teia.json\")'
    AL ''
    AL '# Persistência'
    AL '"'$j.version = if($j.version){ $j.version } else { "teia.public.v1" }'"'
    AL '"'$j.target  = $target'"'
    AL '"'$j.created = if($j.created){ $j.created } else { (Get-Date).ToString("o") }'"'
    AL 'Set-Content -LiteralPath "'$outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8'"'
    AL 'Log \"OK wrote normalized seed: "'$outSeed"'"'
    AL ''
    AL '# Opcional: restore via teia-cli se disponível'
    AL 'if("'$AttemptRestore -and (Get-Command teia -ErrorAction SilentlyContinue)){'"'
    AL '  try{'
    AL '    if(Test-Path -LiteralPath "'$IndexPath){'"'
    AL '      Log \"Attempting restore-index for "'$outSeed using index $IndexPath"'"'
    AL '      & teia restore-index -seed "'$outSeed -index $IndexPath -out (Join-Path $RestoredDir $target) 2>&1 |
        Out-File -FilePath $Log -Append -Encoding utf8'"'
    AL '      Log \"Restore-index completed for "'$target"'"'
    AL '    } else {'
    AL '      Log \"Index not present, skipping restore-index\"'
    AL '    }'
    AL '  } catch {'
    AL '    Log \"ERR during restore: "'$($_.Exception.Message)"'"'
    AL '  }'
    AL '}'
    AL ''
    AL 'Write-Host \"[OK] Adapter processed: "'$outSeed"'"'
    AL '''@'
    AL ''
    AL '# 3) Watch-GeminiFolder.ps1'
    AL 'Set-Content -LiteralPath ''.\\Watch-GeminiFolder.ps1'' -Encoding UTF8 -Value @'''
    AL 'param('
    AL '  [string]"'$Folder = '"''.\\gemini_out'''
    AL ')'
    AL '"'$ErrorActionPreference = '"''Stop'''
    AL 'if(-not (Test-Path "'$Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }'"'
    AL '"'$fsw = New-Object System.IO.FileSystemWatcher $Folder, "*.teia.json"'"'
    AL '"'$fsw.IncludeSubdirectories = $false'"'
    AL '"'$fsw.EnableRaisingEvents = $true'"'
    AL ''
    AL '"'$action = {'"'
    AL '  "'$path = $Event.SourceEventArgs.FullPath'"'
    AL '  Write-Host \"Novo arquivo detectado: "'$path"'"'
    AL '  Start-Sleep -Milliseconds 500'
    AL '  try {'
    AL '    "'$adapterScriptPath = Join-Path (Get-Location) '"''GeminiSeedAdapter.ps1'''
    AL '    pwsh -NoProfile -File "'$adapterScriptPath -InputSeed $path -AttemptRestore'"'
    AL '  } catch {'
    AL '    Write-Host \"Watcher ERR: "'$($_.Exception.Message)"'"'
    AL '  }'
    AL '}'
    AL ''
    AL '"'$watcher = Register-ObjectEvent $fsw Created -Action $action'"'
    AL 'Write-Host \"Watcher ativo em: "'$Folder. Pressione Ctrl+C para sair."'"'
    AL 'try {'
    AL '  while ("'$true) { Wait-Event -Timeout 60 }'"'
    AL '} finally {'
    AL '  Unregister-Event -SubscriptionId "'$watcher.Id'"'
    AL '  "'$fsw.Dispose()'"'
    AL '  Write-Host \"Watcher parado.\"'
    AL '}'
    AL '''@'
    AL ''
    AL '# 4) TEIA-Gemini-Setup.ps1'
    AL 'Set-Content -LiteralPath ''.\\TEIA-Gemini-Setup.ps1'' -Encoding UTF8 -Value @'''
    AL '"'$ErrorActionPreference = "Stop"'"'
    AL 'if ((Get-Location).Path -match \"C:\\\\Windows\\\\System32\") { Write-Host \"Stop: rode fora do System32.\";
        exit 1 }'
    AL 'foreach("'$d in @(".'"\\gemini_out\",\".\\logs\",\".\\seeds\",\".\\restored\")){'
    AL '  if(-not(Test-Path -LiteralPath "'$d)){ New-Item -ItemType Directory -Force -Path $d | Out-Null }'"'
    AL '}'
    AL 'Add-Type -AssemblyName System.Management.Automation'
    AL '"'$files = @('"''.\\Save-Gemini-Dashboard.ps1'',''.\\GeminiSeedAdapter.ps1'',''.\\Watch-GeminiFolder.ps1'',''.
        \\TEIA-Gemini-Setup.ps1'')'
    AL 'foreach("'$f in $files){'"'
    AL '  "'$null = $tokens = $errors = $null'"'
    AL '  [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path "'$f), [ref]$tokens,
        [ref]$errors)'"'
    □ Lint rewritten scripts

• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference='"'Stop'; Set-Location 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'; pwsh
        -NoProfile -File .\\Fix-Gemini-Scripts.ps1"
    ParserError: D:\Teia\TEIA_NUCLEO\offline\nano\Fix-Gemini-Scripts.ps1:137
    Line |
     137 |      throw "Sintaxe inv�lida em $f: $($errors[0].Message)"
         |                                 ~~~
         | Variable reference is not valid. ':' was not followed by a valid variable name character. Consider using
    ${} to
         | delimit the name.

• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference='"'Stop'; Set-Location 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano';
    "'$path = '"'.\\Fix-Gemini-Scripts.ps1';
    "'$txt = Get-Content -LiteralPath $path -Raw -Encoding UTF8;
    $txt = $txt -replace '"'\\"'$f:'"', '"'${f}:'"';
    Set-Content -LiteralPath "'$path -Value $txt -Encoding UTF8;
    Write-Host '"'[OK] Patched "'${f}: disambiguation'"'"

• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference='"'Stop'; Set-Location 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'; pwsh
        -NoProfile -File .\\Fix-Gemini-Scripts.ps1"

> Pronto. Criei o utilitário de reparo, rodei e validei a sintaxe.

  O que fiz

  - Adicionei .\Fix-Gemini-Scripts.ps1 conforme seu conteúdo.
  - Ajuste mínimo para robustez: troquei $f: por ${f}: na mensagem de erro do lint para evitar ambiguidade de variável.
  - Rodei Fix-Gemini-Scripts.ps1: regravou os três scripts e executou lint com sucesso.

  Arquivos prontos

  - .\Fix-Gemini-Scripts.ps1
  - .\Save-Gemini-Dashboard.ps1
  - .\GeminiSeedAdapter.ps1
  - .\Watch-GeminiFolder.ps1
  - .\TEIA-Gemini-Setup.ps1

  Como usar

  - cd D:\Teia\TEIA_NUCLEO\offline\nano
  - pwsh -NoProfile -File .\Fix-Gemini-Scripts.ps1
  - Abra .\compressor_gemini.html e exporte uma seed real para .\gemini_out\
  - pwsh -NoProfile -File .\Watch-GeminiFolder.ps1"
O que falta para o codex rodar e eu ver

---

### ASSISTENTE

Falta só gerar uma seed real e acionar o adapter. O resto está pronto.

Teste imediato (4 linhas, manual):
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
if(-not (Test-Path .\compressor_gemini.html)){ pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1 }
$h=(Get-FileHash .\compressor_gemini.html -Algorithm SHA256).Hash.ToLower(); $sz=(Get-Item .\compressor_gemini.html).Length; @{target="compressor_gemini.html"; sha256=$h; mime="text/html"; size=$sz; created=(Get-Date).ToString("o"); version="teia.public.v1"} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath .\gemini_out\demo_seed.teia.json -Encoding UTF8
pwsh -NoProfile -File .\GeminiSeedAdapter.ps1 -InputSeed .\gemini_out\demo_seed.teia.json
Get-Content .\logs\gemini_adapter.log -Tail 10; Get-ChildItem .\seeds\ | Select Name,Length
```

Se quer ver “ao vivo”:
1) Terminal A: `cd D:\Teia\TEIA_NUCLEO\offline\nano; pwsh -NoProfile -File .\Watch-GeminiFolder.ps1`  
2) Terminal B: gerar a seed com a 3ª linha do bloco acima.  

Resultado esperado: log “OK wrote normalized seed …” e arquivo novo em `.\seeds\`.

---

### USUÁRIO

PS D:\Teia\TEIA_NUCLEO\offline\nano> Nota: abra compressor_gemini.html, gere uma seed real e salve em .\gemini_out\. O watcher dispara o adapter automaticamente.
>>
>> pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
>>
>> pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1
>>
>> pwsh -NoProfile -File .\TEIA-Gemini-Setup.ps1
>>
>> cd D:\Teia\TEIA_NUCLEO\offline\nano
Nota:: The term 'Nota:' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
Watcher ativo em: .\gemini_out. Pressione Ctrl+C para sair.
Watcher parado.
PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> if(-not (Test-Path .\compressor_gemini.html)){ pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1 }
>> $h=(Get-FileHash .\compressor_gemini.html -Algorithm SHA256).Hash.ToLower(); $sz=(Get-Item .\compressor_gemini.html).Length; @{target="compressor_gemini.html"; sha256=$h; mime="text/html"; size=$sz; created=(Get-Date).ToString("o"); version="teia.public.v1"} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath .\gemini_out\demo_seed.teia.json -Encoding UTF8
>> pwsh -NoProfile -File .\GeminiSeedAdapter.ps1 -InputSeed .\gemini_out\demo_seed.teia.json
>> Get-Content .\logs\gemini_adapter.log -Tail 10; Get-ChildItem .\seeds\ | Select Name,Length
>>
[OK] Adapter processed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:17:15.4134206-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json

Name                                          Length
----                                          ------
compressor_gemini.html.9cb1be26606d.teia.json    247
sample_bin.bin.anchor.seed.json                  394
sample_bin.bin.anchor.seed.payload.seed.json    3151
sample_text.txt.anchor.seed.json                 393
sample_text.txt.anchor.seed.payload.seed.json    442
seed_catalog.json                                944

PS D:\Teia\TEIA_NUCLEO\offline\nano>

---

### ASSISTENTE

Funcionou. A seed foi normalizada. Para “ver” o fluxo rodando:

# Disparar o watcher agora (sem navegador)
```powershell
# Terminal A
cd D:\Teia\TEIA_NUCLEO\offline\nano
pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
```
```powershell
# Terminal B
cd D:\Teia\TEIA_NUCLEO\offline\nano
Copy-Item .\gemini_out\demo_seed.teia.json .\gemini_out\demo_seed_2.teia.json
Get-Content .\logs\gemini_adapter.log -Tail 20
```

# Rodar com restauração opcional
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
pwsh -NoProfile -File .\GeminiSeedAdapter.ps1 -InputSeed .\gemini_out\demo_seed.teia.json -AttemptRestore
```
Sem `teia` CLI + `.\\seeds\\teia_anchor_index.json`, o log mostra “Index not present, skipping restore-index”.

# Usar o dashboard de fato
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
Start-Process .\compressor_gemini.html
# Gere a seed no navegador, depois mova para gemini_out:
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force -ErrorAction SilentlyContinue
Get-Content .\logs\gemini_adapter.log -Tail 20
```

Observação: em PowerShell, use `#` para comentários. Não digite linhas começando com `Nota:`.

---

### USUÁRIO

terminal a: >>
[OK] Adapter processed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:17:15.4134206-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json

Name                                          Length
----                                          ------
compressor_gemini.html.9cb1be26606d.teia.json    247
sample_bin.bin.anchor.seed.json                  394
sample_bin.bin.anchor.seed.payload.seed.json    3151
sample_text.txt.anchor.seed.json                 393
sample_text.txt.anchor.seed.payload.seed.json    442
seed_catalog.json                                944

PS D:\Teia\TEIA_NUCLEO\offline\nano> # Terminal A
>> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
>>
Watcher ativo em: .\gemini_out. Pressione Ctrl+C para sair.
Novo arquivo detectado: .\gemini_out\demo_seed_2.teia.json
_(Underline piscando)
Terminal b:
PowerShell 7.5.3
PS C:\Windows\System32> cd D:\Teia\TEIA_NUCLEO\offline\nano
PS D:\Teia\TEIA_NUCLEO\offline\nano> # Terminal B
>> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> Copy-Item .\gemini_out\demo_seed.teia.json .\gemini_out\demo_seed_2.teia.json
>> Get-Content .\logs\gemini_adapter.log -Tail 20
>>
2025-09-26T20:17:15.4134206-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> pwsh -NoProfile -File .\GeminiSeedAdapter.ps1 -InputSeed .\gemini_out\demo_seed.teia.json -AttemptRestore
>>
[OK] Adapter processed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> Start-Process .\compressor_gemini.html
>> # Gere a seed no navegador, depois mova para gemini_out:
>> Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force -ErrorAction SilentlyContinue
>> Get-Content .\logs\gemini_adapter.log -Tail 20
>>
2025-09-26T20:17:15.4134206-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:19:52.2668667-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:20:00.2811203-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
PS D:\Teia\TEIA_NUCLEO\offline\nano>

---

### ASSISTENTE

Está rodando. Os logs repetidos indicam overwrite idempotente do mesmo seed name (mesmo SHA → mesmo arquivo). Para “ver” no Terminal A o resultado do adapter, atualize o watcher para repassar o stdout.

```powershell
# Patch: Watch-GeminiFolder com passthrough do stdout do adapter
Set-Content -LiteralPath '.\Watch-GeminiFolder.ps1' -Encoding UTF8 -Value @'
param([string]$Folder=".\gemini_out")
$ErrorActionPreference='Stop'
if(-not (Test-Path $Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }
$fsw = New-Object System.IO.FileSystemWatcher $Folder, "*.teia.json"
$fsw.IncludeSubdirectories=$false; $fsw.EnableRaisingEvents=$true
$action={
  $path=$Event.SourceEventArgs.FullPath
  Write-Host "Novo arquivo detectado: $path"
  Start-Sleep -Milliseconds 500
  try{
    $adapterScriptPath = Join-Path (Get-Location) 'GeminiSeedAdapter.ps1'
    $out = & pwsh -NoProfile -File $adapterScriptPath -InputSeed $path -AttemptRestore 2>&1
    $out | ForEach-Object { Write-Host $_ }
  } catch {
    Write-Host "Watcher ERR: $($_.Exception.Message)"
  }
}
$watcher = Register-ObjectEvent $fsw Created -Action $action
Write-Host "Watcher ativo em: $Folder. Pressione Ctrl+C para sair."
try{ while($true){ Wait-Event -Timeout 60 } }
finally{ Unregister-Event -SubscriptionId $watcher.Id; $fsw.Dispose(); Write-Host "Watcher parado." }
'@
```

Reinicie o watcher no Terminal A:
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
```

Dispare no Terminal B e veja a linha do adapter no Terminal A:
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
Copy-Item .\gemini_out\demo_seed.teia.json .\gemini_out\demo_seed_3.teia.json
```

Gerar seed diferente para ver nome distinto:
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
Set-Content .\tmp2.txt ("x "+(Get-Random))
$h=(Get-FileHash .\tmp2.txt -Algorithm SHA256).Hash.ToLower()
@{target="tmp2.txt"; sha256=$h; mime="text/plain"; size=(Get-Item .\tmp2.txt).Length; created=(Get-Date).ToString("o"); version="teia.public.v1"} |
 ConvertTo-Json -Depth 5 | Set-Content .\gemini_out\tmp2.teia.json -Encoding UTF8
```

Conferir saídas:
```powershell
Get-Content .\logs\gemini_adapter.log -Tail 20
Get-ChildItem .\seeds\ | Sort-Object Name | Format-Table Name,Length -Auto
```

Próximo passo real: gerar seed pelo dashboard de um arquivo novo grande. O watcher normaliza e registra.

---

### USUÁRIO

codex:
• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference='"'Stop'; Set-Location 'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'
    Set-Content -LiteralPath '.\\Watch-GeminiFolder.ps1' -Encoding UTF8 -Value @'
    param([string]"'$Folder=".'"\\gemini_out\")
    "'$ErrorActionPreference='"'Stop'
    if(-not (Test-Path "'$Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }
    $fsw = New-Object System.IO.FileSystemWatcher $Folder, "*.teia.json"
    $fsw.IncludeSubdirectories=$false; $fsw.EnableRaisingEvents=$true
    $action={
      $path=$Event.SourceEventArgs.FullPath
      Write-Host "Novo arquivo detectado: $path"
      Start-Sleep -Milliseconds 500
      try{
        $adapterScriptPath = Join-Path (Get-Location) '"'GeminiSeedAdapter.ps1'
        "'$out = & pwsh -NoProfile -File $adapterScriptPath -InputSeed $path -AttemptRestore 2>&1
        $out | ForEach-Object { Write-Host $_ }
      } catch {
        Write-Host "Watcher ERR: $($_.Exception.Message)"
      }
    }
    $watcher = Register-ObjectEvent $fsw Created -Action $action
    Write-Host "Watcher ativo em: $Folder. Pressione Ctrl+C para sair."
    try{ while($true){ Wait-Event -Timeout 60 } }
    finally{ Unregister-Event -SubscriptionId $watcher.Id; $fsw.Dispose(); Write-Host "Watcher parado." }
    '"'@
    Add-Type -AssemblyName System.Management.Automation; "'$tokens=$null;$errors=$null; [void]
        [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path '"'.\\Watch-GeminiFolder.ps1'),
        [ref]"'$tokens, [ref]$errors); if($errors -and $errors.Count -gt 0){ throw "Sintaxe inválida:
        $($errors[0].Message)" } else { Write-Host '"'[OK] Lint watcher' }"

> Feito. O watcher agora repassa o stdout do adapter e a sintaxe foi validada.

  Mudança

  - .\Watch-GeminiFolder.ps1: captura a saída do adapter ($out = & pwsh ... 2>&1) e faz passthrough no Terminal A ($out
  | ForEach-Object { Write-Host $_ }).
  - Lint OK do watcher.

  Reinicie e teste

  - Terminal A:
      - cd D:\Teia\TEIA_NUCLEO\offline\nano
      - pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
  - Terminal B (disparar eventos):
      - cd D:\Teia\TEIA_NUCLEO\offline\nano
      - Copy-Item .\gemini_out\demo_seed.teia.json .\gemini_out\demo_seed_3.teia.json
      - Gerar seed diferente:
      - `Set-Content .\tmp2.txt ("x "+(Get-Random))`
      - `$h=(Get-FileHash .\tmp2.txt -Algorithm SHA256).Hash.ToLower()`
      - `@{target="tmp2.txt"; sha256=$h; mime="textplain"; size=(Get-Item .\tmp2.txt).Length;
  created=(Get-Date).ToString("o"); version="teia.public.v1"} | ConvertTo-Json -Depth 5 | Set-Content .
  \gemini_out\tmp2.teia.json -Encoding UTF8`

  Conferir

  - Get-Content .\logs\gemini_adapter.log -Tail 20
  - Get-ChildItem .\seeds\ | Sort-Object Name | Format-Table Name,Length -Auto

  Próximo passo: exportar seed real grande pelo dashboard; o watcher normaliza e registra, agora ecoando o stdout no
  Terminal A

Pws A:
PowerShell 7.5.3
PS C:\Windows\System32> cd D:\Teia\TEIA_NUCLEO\offline\nano
PS D:\Teia\TEIA_NUCLEO\offline\nano> # Cria o arquivo TEIA-Gemini-Setup.ps1 (embed Codex)
>> Set-Content -LiteralPath ".\TEIA-Gemini-Setup.ps1" -Encoding UTF8 -Value @'
>> # TEIA-Gemini-Setup.ps1  (idempotente)
>> $ErrorActionPreference = "Stop"
>>
>> # Nao operar em System32
>> if ((Get-Location).Path -match "C:\\Windows\\System32") {
>>   Write-Host "Stop: navegue para D:\Teia\TEIA_NUCLEO\offline\nano e rode novamente."
>>   exit 1
>> }
>>
>> # Pastas basicas
>> $dirs = @(".\gemini_out", ".\logs", ".\seeds", ".\restored")
>> foreach($d in $dirs){ if(-not (Test-Path -LiteralPath $d)){ New-Item -ItemType Directory -Force -Path $d | Out-Null } }
>>
>> # 1) Save-Gemini-Dashboard.ps1
>> Set-Content -LiteralPath ".\Save-Gemini-Dashboard.ps1" -Encoding UTF8 -Value @'
>> param([string]$OutPath = ".\compressor_gemini.html")
>> $ErrorActionPreference = "Stop"
>> if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)) {
>>   Write-Host "Get-Clipboard nao disponivel. Cole o HTML via stdin e pressione Ctrl+Z e Enter:"
>>   $html = [Console]::In.ReadToEnd()
>> } else { $html = Get-Clipboard -Raw }
>> if ([string]::IsNullOrWhiteSpace($html)) { throw "Conteudo HTML vazio. Cole no clipboard ou passe por stdin." }
>> Set-Content -LiteralPath $OutPath -Value $html -Encoding UTF8
>> Write-Host "[OK] HTML salvo em: $OutPath"
>> '@
>>
>> # 2) GeminiSeedAdapter.ps1
>> Set-Content -LiteralPath ".\GeminiSeedAdapter.ps1" -Encoding UTF8 -Value @'
>> param(
>>   [string]$InputSeed,
>>   [string]$SeedsDir = ".\seeds",
>>   [string]$RestoredDir = ".\restored",
>>   [string]$IndexPath = ".\seeds\teia_anchor_index.json",
>>   [string]$Log = ".\logs\gemini_adapter.log",
>>   [switch]$AttemptRestore
>> )
>> $ErrorActionPreference = "Stop"
>> $EnsureDir = { param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
>> $EnsureDir.Invoke((Split-Path -Parent $Log)); $EnsureDir.Invoke($SeedsDir); $EnsureDir.Invoke($RestoredDir)
>>
>> function Log($m){ $t = (Get-Date).ToString("o"); "$t `t $m" | Out-File -FilePath $Log -Append -Encoding utf8 }
>>
>> if(-not (Test-Path -LiteralPath $InputSeed)){ throw "Input seed nao encontrada: $InputSeed" }
>> try { $raw = Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8; $j = $raw | ConvertFrom-Json }
>> catch { Log "ERR parse JSON: $($_.Exception.Message)"; throw }
>>
>> $target = if($j.target){ $j.target } else { ($InputSeed | Split-Path -Leaf) -replace '\.teia.*$','' }
>> $sha = if($j.sha256){ $j.sha256 } else { "" }
>> $outSeed = Join-Path $SeedsDir ("$($target).$(if($sha){ $sha.Substring(0,12) } else { 'unknown' }).teia.json")
>>
>> $j.version = if($j.version){ $j.version } else { "teia.public.v1" }
>> $j.target  = $target
>> $j.created = if($j.created){ $j.created } else { (Get-Date).ToString("o") }
>> Set-Content -LiteralPath $outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8
>> Log "OK wrote normalized seed: $outSeed"
>>
>> if($AttemptRestore -and (Get-Command teia -ErrorAction SilentlyContinue)){
>>   try{
>>     if(Test-Path -LiteralPath $IndexPath){
>>       Log "Attempting restore-index for $outSeed using index $IndexPath"
>>       & teia restore-index -seed $outSeed -index $IndexPath -out (Join-Path $RestoredDir $target) 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
>>       Log "Restore-index completed for $target"
>>     } else { Log "Index not present, skipping restore-index" }
>>   } catch { Log "ERR during restore: $($_.Exception.Message)" }
>> }
>> Write-Host "[OK] Adapter processed: $outSeed"
>> '@
>>
>> # 3) Watch-GeminiFolder.ps1
>> Set-Content -LiteralPath ".\Watch-GeminiFolder.ps1" -Encoding UTF8 -Value @'
>> param([string]$Folder = ".\gemini_out")
>> $ErrorActionPreference = "Stop"
>> if(-not (Test-Path $Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }
>> $fsw = New-Object System.IO.FileSystemWatcher $Folder, "*.teia.json"
>> $fsw.IncludeSubdirectories = $false; $fsw.EnableRaisingEvents = $true
>>
>> $action = {
>>   $path = $Event.SourceEventArgs.FullPath
>>   Write-Host "Novo arquivo detectado: $path"
>>   Start-Sleep -Milliseconds 500
>>   try {
>>     $adapterScriptPath = Join-Path (Get-Location) "GeminiSeedAdapter.ps1"
>>     pwsh -NoProfile -File $adapterScriptPath -InputSeed $path -AttemptRestore
>>   } catch { Write-Host "Watcher ERR: $($_.Exception.Message)" }
>> }
>> $watcher = Register-ObjectEvent $fsw Created -Action $action
>> Write-Host "Watcher ativo em: $Folder. Pressione Ctrl+C para sair."
>> try { while ($true) { Wait-Event -Timeout 60 } }
>> finally { Unregister-Event -SubscriptionId $watcher.Id; $fsw.Dispose(); Write-Host "Watcher parado." }
>> '@
>>
>> Write-Host "[OK] Setup concluido. Scripts gravados e pastas prontas."
>> '@
>>
>> ^C
PS D:\Teia\TEIA_NUCLEO\offline\nano> Nota: abra compressor_gemini.html, gere uma seed real e salve em .\gemini_out\. O watcher dispara o adapter automaticamente.
>>
>> pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
>>
>> pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1
>>
>> pwsh -NoProfile -File .\TEIA-Gemini-Setup.ps1
>>
>> cd D:\Teia\TEIA_NUCLEO\offline\nano
Nota:: The term 'Nota:' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
Watcher ativo em: .\gemini_out. Pressione Ctrl+C para sair.
Watcher parado.
PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> if(-not (Test-Path .\compressor_gemini.html)){ pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1 }
>> $h=(Get-FileHash .\compressor_gemini.html -Algorithm SHA256).Hash.ToLower(); $sz=(Get-Item .\compressor_gemini.html).Length; @{target="compressor_gemini.html"; sha256=$h; mime="text/html"; size=$sz; created=(Get-Date).ToString("o"); version="teia.public.v1"} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath .\gemini_out\demo_seed.teia.json -Encoding UTF8
>> pwsh -NoProfile -File .\GeminiSeedAdapter.ps1 -InputSeed .\gemini_out\demo_seed.teia.json
>> Get-Content .\logs\gemini_adapter.log -Tail 10; Get-ChildItem .\seeds\ | Select Name,Length
>>
[OK] Adapter processed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:17:15.4134206-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json

Name                                          Length
----                                          ------
compressor_gemini.html.9cb1be26606d.teia.json    247
sample_bin.bin.anchor.seed.json                  394
sample_bin.bin.anchor.seed.payload.seed.json    3151
sample_text.txt.anchor.seed.json                 393
sample_text.txt.anchor.seed.payload.seed.json    442
seed_catalog.json                                944

PS D:\Teia\TEIA_NUCLEO\offline\nano> # Terminal A
>> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
>>
Watcher ativo em: .\gemini_out. Pressione Ctrl+C para sair.
Novo arquivo detectado: .\gemini_out\demo_seed_2.teia.json
Watcher parado.
PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
PS D:\Teia\TEIA_NUCLEO\offline\nano> pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
Watcher ativo em: .\gemini_out. Pressione Ctrl+C para sair.
Novo arquivo detectado: .\gemini_out\demo_seed_3.teia.json
[OK] Adapter processed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
PWS B:
PowerShell 7.5.3
PS C:\Windows\System32> cd D:\Teia\TEIA_NUCLEO\offline\nano
PS D:\Teia\TEIA_NUCLEO\offline\nano> # Terminal B
>> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> Copy-Item .\gemini_out\demo_seed.teia.json .\gemini_out\demo_seed_2.teia.json
>> Get-Content .\logs\gemini_adapter.log -Tail 20
>>
2025-09-26T20:17:15.4134206-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> pwsh -NoProfile -File .\GeminiSeedAdapter.ps1 -InputSeed .\gemini_out\demo_seed.teia.json -AttemptRestore
>>
[OK] Adapter processed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> Start-Process .\compressor_gemini.html
>> # Gere a seed no navegador, depois mova para gemini_out:
>> Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force -ErrorAction SilentlyContinue
>> Get-Content .\logs\gemini_adapter.log -Tail 20
>>
2025-09-26T20:17:15.4134206-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:19:52.2668667-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:20:00.2811203-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
PS D:\Teia\TEIA_NUCLEO\offline\nano> Copy-Item .\gemini_out\demo_seed.teia.json .\gemini_out\demo_seed_3.teia.json
PS D:\Teia\TEIA_NUCLEO\offline\nano> `Set-Content .\tmp2.txt ("x "+(Get-Random))`
>> ^C
PS D:\Teia\TEIA_NUCLEO\offline\nano>

---

### ASSISTENTE

Você já está ok. Gere uma seed nova e veja o stdout no Terminal A.

### Terminal A
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
```

### Terminal B
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
"x "+(Get-Random) | Set-Content .\tmp2.txt -Encoding UTF8
$h=(Get-FileHash .\tmp2.txt -Algorithm SHA256).Hash.ToLower(); $sz=(Get-Item .\tmp2.txt).Length
@{target='tmp2.txt'; sha256=$h; mime='text/plain'; size=$sz; created=(Get-Date).ToString('o'); version='teia.public.v1'} |
  ConvertTo-Json -Depth 5 | Set-Content .\gemini_out\tmp2.teia.json -Encoding UTF8
```

### Confirmar
```powershell
Get-Content .\logs\gemini_adapter.log -Tail 10
Get-ChildItem .\seeds\ | Sort-Object LastWriteTime -Desc | Select-Object -First 3 Name,Length
```

Se quiser gerar várias de uma vez:
```powershell
1..3 | % { "x "+(Get-Random) | Set-Content .\tmp_$_.txt -Encoding UTF8
  $h=(Get-FileHash .\tmp_$_.txt -Algorithm SHA256).Hash.ToLower(); $sz=(Get-Item .\tmp_$_.txt).Length
  @{target="tmp_$_.txt"; sha256=$h; mime='text/plain'; size=$sz; created=(Get-Date).ToString('o'); version='teia.public.v1'} |
    ConvertTo-Json -Depth 5 | Set-Content .\gemini_out\tmp_$_.teia.json -Encoding UTF8
}
```

---

### USUÁRIO

PWS A:
PowerShell 7.5.3
PS C:\Windows\System32> cd D:\Teia\TEIA_NUCLEO\offline\nano
PS D:\Teia\TEIA_NUCLEO\offline\nano> # Cria o arquivo TEIA-Gemini-Setup.ps1 (embed Codex)
>> Set-Content -LiteralPath ".\TEIA-Gemini-Setup.ps1" -Encoding UTF8 -Value @'
>> # TEIA-Gemini-Setup.ps1  (idempotente)
>> $ErrorActionPreference = "Stop"
>>
>> # Nao operar em System32
>> if ((Get-Location).Path -match "C:\\Windows\\System32") {
>>   Write-Host "Stop: navegue para D:\Teia\TEIA_NUCLEO\offline\nano e rode novamente."
>>   exit 1
>> }
>>
>> # Pastas basicas
>> $dirs = @(".\gemini_out", ".\logs", ".\seeds", ".\restored")
>> foreach($d in $dirs){ if(-not (Test-Path -LiteralPath $d)){ New-Item -ItemType Directory -Force -Path $d | Out-Null } }
>>
>> # 1) Save-Gemini-Dashboard.ps1
>> Set-Content -LiteralPath ".\Save-Gemini-Dashboard.ps1" -Encoding UTF8 -Value @'
>> param([string]$OutPath = ".\compressor_gemini.html")
>> $ErrorActionPreference = "Stop"
>> if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)) {
>>   Write-Host "Get-Clipboard nao disponivel. Cole o HTML via stdin e pressione Ctrl+Z e Enter:"
>>   $html = [Console]::In.ReadToEnd()
>> } else { $html = Get-Clipboard -Raw }
>> if ([string]::IsNullOrWhiteSpace($html)) { throw "Conteudo HTML vazio. Cole no clipboard ou passe por stdin." }
>> Set-Content -LiteralPath $OutPath -Value $html -Encoding UTF8
>> Write-Host "[OK] HTML salvo em: $OutPath"
>> '@
>>
>> # 2) GeminiSeedAdapter.ps1
>> Set-Content -LiteralPath ".\GeminiSeedAdapter.ps1" -Encoding UTF8 -Value @'
>> param(
>>   [string]$InputSeed,
>>   [string]$SeedsDir = ".\seeds",
>>   [string]$RestoredDir = ".\restored",
>>   [string]$IndexPath = ".\seeds\teia_anchor_index.json",
>>   [string]$Log = ".\logs\gemini_adapter.log",
>>   [switch]$AttemptRestore
>> )
>> $ErrorActionPreference = "Stop"
>> $EnsureDir = { param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
>> $EnsureDir.Invoke((Split-Path -Parent $Log)); $EnsureDir.Invoke($SeedsDir); $EnsureDir.Invoke($RestoredDir)
>>
>> function Log($m){ $t = (Get-Date).ToString("o"); "$t `t $m" | Out-File -FilePath $Log -Append -Encoding utf8 }
>>
>> if(-not (Test-Path -LiteralPath $InputSeed)){ throw "Input seed nao encontrada: $InputSeed" }
>> try { $raw = Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8; $j = $raw | ConvertFrom-Json }
>> catch { Log "ERR parse JSON: $($_.Exception.Message)"; throw }
>>
>> $target = if($j.target){ $j.target } else { ($InputSeed | Split-Path -Leaf) -replace '\.teia.*$','' }
>> $sha = if($j.sha256){ $j.sha256 } else { "" }
>> $outSeed = Join-Path $SeedsDir ("$($target).$(if($sha){ $sha.Substring(0,12) } else { 'unknown' }).teia.json")
>>
>> $j.version = if($j.version){ $j.version } else { "teia.public.v1" }
>> $j.target  = $target
>> $j.created = if($j.created){ $j.created } else { (Get-Date).ToString("o") }
>> Set-Content -LiteralPath $outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8
>> Log "OK wrote normalized seed: $outSeed"
>>
>> if($AttemptRestore -and (Get-Command teia -ErrorAction SilentlyContinue)){
>>   try{
>>     if(Test-Path -LiteralPath $IndexPath){
>>       Log "Attempting restore-index for $outSeed using index $IndexPath"
>>       & teia restore-index -seed $outSeed -index $IndexPath -out (Join-Path $RestoredDir $target) 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
>>       Log "Restore-index completed for $target"
>>     } else { Log "Index not present, skipping restore-index" }
>>   } catch { Log "ERR during restore: $($_.Exception.Message)" }
>> }
>> Write-Host "[OK] Adapter processed: $outSeed"
>> '@
>>
>> # 3) Watch-GeminiFolder.ps1
>> Set-Content -LiteralPath ".\Watch-GeminiFolder.ps1" -Encoding UTF8 -Value @'
>> param([string]$Folder = ".\gemini_out")
>> $ErrorActionPreference = "Stop"
>> if(-not (Test-Path $Folder)){ New-Item -ItemType Directory -Force -Path $Folder | Out-Null }
>> $fsw = New-Object System.IO.FileSystemWatcher $Folder, "*.teia.json"
>> $fsw.IncludeSubdirectories = $false; $fsw.EnableRaisingEvents = $true
>>
>> $action = {
>>   $path = $Event.SourceEventArgs.FullPath
>>   Write-Host "Novo arquivo detectado: $path"
>>   Start-Sleep -Milliseconds 500
>>   try {
>>     $adapterScriptPath = Join-Path (Get-Location) "GeminiSeedAdapter.ps1"
>>     pwsh -NoProfile -File $adapterScriptPath -InputSeed $path -AttemptRestore
>>   } catch { Write-Host "Watcher ERR: $($_.Exception.Message)" }
>> }
>> $watcher = Register-ObjectEvent $fsw Created -Action $action
>> Write-Host "Watcher ativo em: $Folder. Pressione Ctrl+C para sair."
>> try { while ($true) { Wait-Event -Timeout 60 } }
>> finally { Unregister-Event -SubscriptionId $watcher.Id; $fsw.Dispose(); Write-Host "Watcher parado." }
>> '@
>>
>> Write-Host "[OK] Setup concluido. Scripts gravados e pastas prontas."
>> '@
>>
>> ^C
PS D:\Teia\TEIA_NUCLEO\offline\nano> Nota: abra compressor_gemini.html, gere uma seed real e salve em .\gemini_out\. O watcher dispara o adapter automaticamente.
>>
>> pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
>>
>> pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1
>>
>> pwsh -NoProfile -File .\TEIA-Gemini-Setup.ps1
>>
>> cd D:\Teia\TEIA_NUCLEO\offline\nano
Nota:: The term 'Nota:' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
Watcher ativo em: .\gemini_out. Pressione Ctrl+C para sair.
Watcher parado.
PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> if(-not (Test-Path .\compressor_gemini.html)){ pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1 }
>> $h=(Get-FileHash .\compressor_gemini.html -Algorithm SHA256).Hash.ToLower(); $sz=(Get-Item .\compressor_gemini.html).Length; @{target="compressor_gemini.html"; sha256=$h; mime="text/html"; size=$sz; created=(Get-Date).ToString("o"); version="teia.public.v1"} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath .\gemini_out\demo_seed.teia.json -Encoding UTF8
>> pwsh -NoProfile -File .\GeminiSeedAdapter.ps1 -InputSeed .\gemini_out\demo_seed.teia.json
>> Get-Content .\logs\gemini_adapter.log -Tail 10; Get-ChildItem .\seeds\ | Select Name,Length
>>
[OK] Adapter processed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:17:15.4134206-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json

Name                                          Length
----                                          ------
compressor_gemini.html.9cb1be26606d.teia.json    247
sample_bin.bin.anchor.seed.json                  394
sample_bin.bin.anchor.seed.payload.seed.json    3151
sample_text.txt.anchor.seed.json                 393
sample_text.txt.anchor.seed.payload.seed.json    442
seed_catalog.json                                944

PS D:\Teia\TEIA_NUCLEO\offline\nano> # Terminal A
>> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
>>
Watcher ativo em: .\gemini_out. Pressione Ctrl+C para sair.
Novo arquivo detectado: .\gemini_out\demo_seed_2.teia.json
Watcher parado.
PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
PS D:\Teia\TEIA_NUCLEO\offline\nano> pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
Watcher ativo em: .\gemini_out. Pressione Ctrl+C para sair.
Novo arquivo detectado: .\gemini_out\demo_seed_3.teia.json
[OK] Adapter processed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
Watcher parado.
PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
>>
Watcher ativo em: .\gemini_out. Pressione Ctrl+C para sair.
Novo arquivo detectado: .\gemini_out\tmp2.teia.json
[OK] Adapter processed: .\seeds\tmp2.txt.9243abb48fef.teia.json
Novo arquivo detectado: .\gemini_out\tmp_1.teia.json
[OK] Adapter processed: .\seeds\tmp_1.txt.0c5b73fa50a9.teia.json
Novo arquivo detectado: .\gemini_out\tmp_2.teia.json
[OK] Adapter processed: .\seeds\tmp_2.txt.1517faeca6f2.teia.json
Novo arquivo detectado: .\gemini_out\tmp_3.teia.json
[OK] Adapter processed: .\seeds\tmp_3.txt.f9e9b27622e7.teia.jsonPWS b:

---

### ASSISTENTE

Está certo. Watcher + adapter funcionando.

Faça agora com arquivo real.

### Terminal A
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
```

### Terminal B — gerar seed de um arquivo real
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
$src = "C:\Users\felip\Downloads\SEU_ARQUIVO.ext"   # troque pelo caminho real
$h=(Get-FileHash $src -Algorithm SHA256).Hash.ToLower()
$sz=(Get-Item $src).Length
$mime="application/octet-stream"                     # ajuste se quiser
@{target=(Split-Path $src -Leaf); sha256=$h; mime=$mime; size=$sz; created=(Get-Date).ToString("o"); version="teia.public.v1"} |
  ConvertTo-Json -Depth 5 | Set-Content -LiteralPath ".\gemini_out\$(Split-Path $src -Leaf).teia.json" -Encoding UTF8
```

### Conferir
```powershell
Get-Content .\logs\gemini_adapter.log -Tail 20
Get-ChildItem .\seeds\ | Sort-Object LastWriteTime -Desc | Select-Object -First 5 Name,Length
```

Notas rápidas:
- Repetições no log = mesma seed sobrescrita. É esperado e idempotente.
- Evite digitar linhas começando com `Nota:` no PowerShell. Use `#` para comentário.

---

### USUÁRIO

PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> $src = "C:\Users\felip\Downloads\SEU_ARQUIVO.ext"   # troque pelo caminho real
>> $h=(Get-FileHash $src -Algorithm SHA256).Hash.ToLower()
>> $sz=(Get-Item $src).Length
>> $mime="application/octet-stream"                     # ajuste se quiser
>> @{target=(Split-Path $src -Leaf); sha256=$h; mime=$mime; size=$sz; created=(Get-Date).ToString("o"); version="teia.public.v1"} |
>>   ConvertTo-Json -Depth 5 | Set-Content -LiteralPath ".\gemini_out\$(Split-Path $src -Leaf).teia.json" -Encoding UTF8
>>
Get-FileHash:
Line |
   3 |  $h=(Get-FileHash $src -Algorithm SHA256).Hash.ToLower()
     |      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot find path 'C:\Users\felip\Downloads\SEU_ARQUIVO.ext' because it does not exist.
InvalidOperation:
Line |
   3 |  $h=(Get-FileHash $src -Algorithm SHA256).Hash.ToLower()
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | You cannot call a method on a null-valued expression.
Get-Item:
Line |
   4 |  $sz=(Get-Item $src).Length
     |       ~~~~~~~~~~~~~
     | Cannot find path 'C:\Users\felip\Downloads\SEU_ARQUIVO.ext' because it does not exist.
PS D:\Teia\TEIA_NUCLEO\offline\nano>PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> $src = "C:\Users\felip\Downloads\SEU_ARQUIVO.ext"   # troque pelo caminho real
>> $h=(Get-FileHash $src -Algorithm SHA256).Hash.ToLower()
>> $sz=(Get-Item $src).Length
>> $mime="application/octet-stream"                     # ajuste se quiser
>> @{target=(Split-Path $src -Leaf); sha256=$h; mime=$mime; size=$sz; created=(Get-Date).ToString("o"); version="teia.public.v1"} |
>>   ConvertTo-Json -Depth 5 | Set-Content -LiteralPath ".\gemini_out\$(Split-Path $src -Leaf).teia.json" -Encoding UTF8
>>
Get-FileHash:
Line |
   3 |  $h=(Get-FileHash $src -Algorithm SHA256).Hash.ToLower()
     |      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot find path 'C:\Users\felip\Downloads\SEU_ARQUIVO.ext' because it does not exist.
InvalidOperation:
Line |
   3 |  $h=(Get-FileHash $src -Algorithm SHA256).Hash.ToLower()
     |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | You cannot call a method on a null-valued expression.
Get-Item:
Line |
   4 |  $sz=(Get-Item $src).Length
     |       ~~~~~~~~~~~~~
     | Cannot find path 'C:\Users\felip\Downloads\SEU_ARQUIVO.ext' because it does not exist.
PS D:\Teia\TEIA_NUCLEO\offline\nano>

---

### ASSISTENTE

Use um arquivo real. O erro foi o placeholder `SEU_ARQUIVO.ext`.

## Opção rápida: último arquivo do Downloads
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
$src = Get-ChildItem "$env:USERPROFILE\Downloads" -File | Sort-Object LastWriteTime -Desc | Select-Object -First 1 -Expand FullName
if(-not $src){ throw "Downloads vazio." }
$ext  = [IO.Path]::GetExtension($src)
$mime = (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ext" -Name "Content Type" -ErrorAction SilentlyContinue)."Content Type"
if(-not $mime){ $mime = 'application/octet-stream' }
$h  = (Get-FileHash $src -Algorithm SHA256).Hash.ToLower()
$sz = (Get-Item $src).Length
@{target=(Split-Path $src -Leaf); sha256=$h; mime=$mime; size=$sz; created=(Get-Date).ToString("o"); version="teia.public.v1"} |
  ConvertTo-Json -Depth 5 | Set-Content -LiteralPath ".\gemini_out\$(Split-Path $src -Leaf).teia.json" -Encoding UTF8
```

## Alternativas
- Arraste o arquivo do Explorer e solte no console para preencher `$src`:
  ```powershell
  $src = 'COLE-AQUI-O-CAMINHO-ARRASTADO'
  ```
- Escolha por nome:
  ```powershell
  $src = 'C:\caminho\real\arquivo.ext'
  ```

## Verificação
- Terminal A: `pwsh -NoProfile -File .\Watch-GeminiFolder.ps1`
- Terminal B:
  ```powershell
  Get-Content .\logs\gemini_adapter.log -Tail 20
  Get-ChildItem .\seeds\ | Sort-Object LastWriteTime -Desc | Select-Object -First 5 Name,Length
  ```

Nota: se gerar seed do mesmo arquivo, o adapter sobrescreve a mesma saída (mesmo SHA). Para ver nomes novos, use um arquivo diferente.

---

### USUÁRIO

B: PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> $src = Get-ChildItem "$env:USERPROFILE\Downloads" -File | Sort-Object LastWriteTime -Desc | Select-Object -First 1 -Expand FullName
>> if(-not $src){ throw "Downloads vazio." }
>> $ext  = [IO.Path]::GetExtension($src)
>> $mime = (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ext" -Name "Content Type" -ErrorAction SilentlyContinue)."Content Type"
>> if(-not $mime){ $mime = 'application/octet-stream' }
>> $h  = (Get-FileHash $src -Algorithm SHA256).Hash.ToLower()
>> $sz = (Get-Item $src).Length
>> @{target=(Split-Path $src -Leaf); sha256=$h; mime=$mime; size=$sz; created=(Get-Date).ToString("o"); version="teia.public.v1"} |
>>   ConvertTo-Json -Depth 5 | Set-Content -LiteralPath ".\gemini_out\$(Split-Path $src -Leaf).teia.json" -Encoding UTF8
>>
PS D:\Teia\TEIA_NUCLEO\offline\nano> Get-Content .\logs\gemini_adapter.log -Tail 20
>> Get-ChildItem .\seeds\ | Sort-Object LastWriteTime -Desc | Select-Object -First 5 Name,Length
>>
2025-09-26T20:17:15.4134206-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:19:52.2668667-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:20:00.2811203-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:25:08.0106533-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:28:28.3907368-03:00        OK wrote normalized seed: .\seeds\tmp2.txt.9243abb48fef.teia.json
2025-09-26T20:28:41.0792358-03:00        OK wrote normalized seed: .\seeds\tmp_1.txt.0c5b73fa50a9.teia.json
2025-09-26T20:28:42.1363565-03:00        OK wrote normalized seed: .\seeds\tmp_2.txt.1517faeca6f2.teia.json
2025-09-26T20:28:43.1973025-03:00        OK wrote normalized seed: .\seeds\tmp_3.txt.f9e9b27622e7.teia.json
2025-09-26T20:33:45.2233913-03:00        OK wrote normalized seed: .\seeds\SEU_ARQUIVO.ext.f9e9b27622e7.teia.json
2025-09-26T20:36:56.9250484-03:00        OK wrote normalized seed: .\seeds\winfsp-2.1.25156.msi.073a70e00f77.teia.json

Name                                        Length
----                                        ------
winfsp-2.1.25156.msi.073a70e00f77.teia.json    264
SEU_ARQUIVO.ext.f9e9b27622e7.teia.json         254
tmp_3.txt.f9e9b27622e7.teia.json               235
tmp_2.txt.1517faeca6f2.teia.json               235
tmp_1.txt.0c5b73fa50a9.teia.json               235

PS D:\Teia\TEIA_NUCLEO\offline\nano>

A: Watcher ativo em: .\gemini_out. Pressione Ctrl+C para sair.
Novo arquivo detectado: .\gemini_out\SEU_ARQUIVO.ext.teia.json
[OK] Adapter processed: .\seeds\SEU_ARQUIVO.ext.f9e9b27622e7.teia.json
Novo arquivo detectado: .\gemini_out\winfsp-2.1.25156.msi.teia.json
[OK] Adapter processed: .\seeds\winfsp-2.1.25156.msi.073a70e00f77.teia.json

---

### ASSISTENTE

Status: OK. Watcher + adapter normalizam seeds reais (`SEU_ARQUIVO.ext` e `winfsp-2.1.25156.msi`). Próximo passo: restauração.

## Sem `teia` CLI (restauração via índice simples)
Crie um índice âncora e copie pelo SHA.

```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano

# 1) Gerar índice a partir do Downloads (ajuste a pasta se quiser)
$srcDir="$env:USERPROFILE\Downloads"
$entries = Get-ChildItem $srcDir -File | ForEach-Object {
  $h=(Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
  $ext=[IO.Path]::GetExtension($_.Name)
  $mime=(Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ext" -Name "Content Type" -ErrorAction SilentlyContinue)."Content Type"
  [pscustomobject]@{sha256=$h; path=$_.FullName; size=$_.Length; mime=($mime?$mime:'application/octet-stream')}
}
@{version='teia.anchor.index.v1'; entries=$entries} |
  ConvertTo-Json -Depth 6 | Set-Content .\seeds\teia_anchor_index.json -Encoding UTF8

# 2) Restaurar a partir de uma seed normalizada (ex.: a do MSI)
$seedPath = '.\seeds\winfsp-2.1.25156.msi.073a70e00f77.teia.json'
$seed = Get-Content $seedPath -Raw | ConvertFrom-Json
$idx  = Get-Content .\seeds\teia_anchor_index.json -Raw | ConvertFrom-Json
$entry = $idx.entries | Where-Object sha256 -eq $seed.sha256
if(-not $entry){ throw "SHA não encontrado no índice." }
Copy-Item -LiteralPath $entry.path -Destination (Join-Path .\restored $seed.target) -Force

# 3) Verificação de integridade
$ok = ((Get-FileHash (Join-Path .\restored $seed.target) -Algorithm SHA256).Hash.ToLower() -eq $seed.sha256)
"RESTORE OK: $ok"
```

## Com `teia` CLI
Coloque `.\seeds\teia_anchor_index.json` como acima e rode:
```powershell
pwsh -NoProfile -File .\GeminiSeedAdapter.ps1 -InputSeed .\gemini_out\winfsp-2.1.25156.msi.teia.json -AttemptRestore
```

Observações:
- Logs em `.\logs\gemini_adapter.log`.
- Mesma seed do mesmo arquivo sobrescreve a saída. Use arquivos diferentes para nomes distintos. 
- No PowerShell, comentários começam com `#`. Não digite linhas começando com `Nota:`.

---

### USUÁRIO

>>
ParserError:
Line |
   9 |  … a256=$h; path=$_.FullName; size=$_.Length; mime=($mime?$mime:'applica …
     |                                                           ~~~~~~
     | Variable reference is not valid. ':' was not followed by a valid variable name character. Consider using ${}
     | to delimit the name.
PS D:\Teia\TEIA_NUCLEO\offline\nano>

---

### ASSISTENTE

Causa: uso do ternário `?:` dentro do hashtable. Em PowerShell 7, prefira `??` ou `if`. Corrigido abaixo.

## Gerar índice âncora OK
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
$srcDir = "$env:USERPROFILE\Downloads"

$entries = Get-ChildItem $srcDir -File | ForEach-Object {
  $full = $_.FullName
  $h    = (Get-FileHash $full -Algorithm SHA256).Hash.ToLower()
  $ext  = [IO.Path]::GetExtension($full)
  $mime = ((Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ext" -Name 'Content Type' -ErrorAction SilentlyContinue).'Content Type') ?? 'application/octet-stream'
  [pscustomobject]@{
    sha256 = $h
    path   = $full
    size   = $_.Length
    mime   = $mime
  }
}

@{ version='teia.anchor.index.v1'; entries=$entries } |
  ConvertTo-Json -Depth 6 | Set-Content .\seeds\teia_anchor_index.json -Encoding UTF8
```

## Restaurar um arquivo pela seed
```powershell
$seedPath = '.\seeds\winfsp-2.1.25156.msi.073a70e00f77.teia.json'  # ajuste se quiser
$seed = Get-Content $seedPath -Raw | ConvertFrom-Json
$idx  = Get-Content .\seeds\teia_anchor_index.json -Raw | ConvertFrom-Json
$entry = $idx.entries | Where-Object sha256 -eq $seed.sha256
if(-not $entry){ throw "SHA não encontrado no índice." }
$dest = Join-Path .\restored $seed.target
Copy-Item -LiteralPath $entry.path -Destination $dest -Force
((Get-FileHash $dest -Algorithm SHA256).Hash.ToLower() -eq $seed.sha256)
```

---

### USUÁRIO

PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> $srcDir = "$env:USERPROFILE\Downloads"
>>
>> $entries = Get-ChildItem $srcDir -File | ForEach-Object {
>>   $full = $_.FullName
>>   $h    = (Get-FileHash $full -Algorithm SHA256).Hash.ToLower()
>>   $ext  = [IO.Path]::GetExtension($full)
>>   $mime = ((Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ext" -Name 'Content Type' -ErrorAction SilentlyContinue).'Content Type') ?? 'application/octet-stream'
>>   [pscustomobject]@{
>>     sha256 = $h
>>     path   = $full
>>     size   = $_.Length
>>     mime   = $mime
>>   }
>> }
>>
>> @{ version='teia.anchor.index.v1'; entries=$entries } |
>>   ConvertTo-Json -Depth 6 | Set-Content .\seeds\teia_anchor_index.json -Encoding UTF8
>>
PS D:\Teia\TEIA_NUCLEO\offline\nano> $seedPath = '.\seeds\winfsp-2.1.25156.msi.073a70e00f77.teia.json'  # ajuste se quiser
>> $seed = Get-Content $seedPath -Raw | ConvertFrom-Json
>> $idx  = Get-Content .\seeds\teia_anchor_index.json -Raw | ConvertFrom-Json
>> $entry = $idx.entries | Where-Object sha256 -eq $seed.sha256
>> if(-not $entry){ throw "SHA não encontrado no índice." }
>> $dest = Join-Path .\restored $seed.target
>> Copy-Item -LiteralPath $entry.path -Destination $dest -Force
>> ((Get-FileHash $dest -Algorithm SHA256).Hash.ToLower() -eq $seed.sha256)
>>
True
PS D:\Teia\TEIA_NUCLEO\offline\nano>

---

### ASSISTENTE

Restauração confirmada (`True`). Próximo passo: automatizar o restore no adapter e ter um builder de índice.

## 1) Builder de índice
```powershell
# Build-TeiaIndex.ps1
param(
  [string]$Root = "$env:USERPROFILE\Downloads",
  [string]$OutPath = ".\seeds\teia_anchor_index.json"
)
$ErrorActionPreference='Stop'
if(-not (Test-Path $Root)){ throw "Root inexistente: $Root" }
$entries = Get-ChildItem $Root -File -Recurse | ForEach-Object {
  $full=$_.FullName
  $h=(Get-FileHash $full -Algorithm SHA256).Hash.ToLower()
  $ext=[IO.Path]::GetExtension($full)
  $mime=((Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ext" -Name 'Content Type' -ErrorAction SilentlyContinue).'Content Type') ?? 'application/octet-stream'
  [pscustomobject]@{ sha256=$h; path=$full; size=$_.Length; mime=$mime }
}
@{ version='teia.anchor.index.v1'; root=$Root; entries=$entries } |
  ConvertTo-Json -Depth 6 | Set-Content $OutPath -Encoding UTF8
Write-Host "[OK] Index: $OutPath  entries=$($entries.Count)"
```

Uso:
```powershell
pwsh -NoProfile -File .\Build-TeiaIndex.ps1 -Root "$env:USERPROFILE\Downloads"
```

## 2) Adapter com fallback de restore (v2)
```powershell
# GeminiSeedAdapter.v2.ps1
param(
  [string]$InputSeed,
  [string]$SeedsDir = ".\seeds",
  [string]$RestoredDir = ".\restored",
  [string]$IndexPath = ".\seeds\teia_anchor_index.json",
  [string]$Log = ".\logs\gemini_adapter.log",
  [switch]$AttemptRestore
)
$ErrorActionPreference='Stop'
$EnsureDir = { param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
$EnsureDir.Invoke((Split-Path -Parent $Log)); $EnsureDir.Invoke($SeedsDir); $EnsureDir.Invoke($RestoredDir)
function Log($m){ $t=(Get-Date).ToString("o"); "$t `t $m" | Out-File -FilePath $Log -Append -Encoding utf8 }

if(-not (Test-Path -LiteralPath $InputSeed)){ throw "Input seed não encontrada: $InputSeed" }
try { $raw=Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8; $j=$raw|ConvertFrom-Json } catch { Log "ERR parse JSON: $($_.Exception.Message)"; throw }

# Normalização
$target = if($j.target){ $j.target } else { ($InputSeed|Split-Path -Leaf) -replace '\.teia.*$','' }
$sha    = if($j.sha256){ $j.sha256 } else { "" }
$outSeed = Join-Path $SeedsDir ("$($target).$(if($sha){ $sha.Substring(0,12) } else { 'unknown' }).teia.json")
$j.version = if($j.version){ $j.version } else { "teia.public.v1" }
$j.target  = $target
$j.created = if($j.created){ $j.created } else { (Get-Date).ToString("o") }
Set-Content -LiteralPath $outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8
Log "OK wrote normalized seed: $outSeed"

# Restore: teia CLI se disponível; fallback via índice caso contrário
if($AttemptRestore){
  try{
    $did=$false
    if(Get-Command teia -ErrorAction SilentlyContinue){
      if(Test-Path -LiteralPath $IndexPath){
        Log "Attempting restore-index (teia) for $outSeed using index $IndexPath"
        & teia restore-index -seed $outSeed -index $IndexPath -out (Join-Path $RestoredDir $target) 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        $did=$true
      } else { Log "Index not present, skipping teia restore" }
    }
    if(-not $did -and (Test-Path -LiteralPath $IndexPath)){
      Log "Fallback restore via index copy for $target"
      $idx=Get-Content $IndexPath -Raw|ConvertFrom-Json
      $entry = $idx.entries | Where-Object sha256 -eq $j.sha256
      if($entry){
        $dest = Join-Path $RestoredDir $target
        Copy-Item -LiteralPath $entry.path -Destination $dest -Force
        $ok = ((Get-FileHash $dest -Algorithm SHA256).Hash.ToLower() -eq $j.sha256)
        Log "Fallback restore OK=$ok → $dest"
      } else {
        Log "Fallback restore: SHA not found in index"
      }
    }
  } catch { Log "ERR during restore: $($_.Exception.Message)" }
}

Write-Host "[OK] Adapter processed: $outSeed"
```

Uso:
```powershell
# índice já gerado
pwsh -NoProfile -File .\GeminiSeedAdapter.v2.ps1 -InputSeed .\gemini_out\winfsp-2.1.25156.msi.teia.json -AttemptRestore
```

Se preferir, substitua o adapter atual pelo v2 e mantenha o watcher igual.

---

### USUÁRIO

PS D:\Teia\TEIA_NUCLEO\offline\nano> # Build-TeiaIndex.ps1
>> param(
>>   [string]$Root = "$env:USERPROFILE\Downloads",
>>   [string]$OutPath = ".\seeds\teia_anchor_index.json"
>> )
>> $ErrorActionPreference='Stop'
>> if(-not (Test-Path $Root)){ throw "Root inexistente: $Root" }
>> $entries = Get-ChildItem $Root -File -Recurse | ForEach-Object {
>>   $full=$_.FullName
>>   $h=(Get-FileHash $full -Algorithm SHA256).Hash.ToLower()
>>   $ext=[IO.Path]::GetExtension($full)
>>   $mime=((Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ext" -Name 'Content Type' -ErrorAction SilentlyContinue).'Content Type') ?? 'application/octet-stream'
>>   [pscustomobject]@{ sha256=$h; path=$full; size=$_.Length; mime=$mime }
>> }
>> @{ version='teia.anchor.index.v1'; root=$Root; entries=$entries } |
>>   ConvertTo-Json -Depth 6 | Set-Content $OutPath -Encoding UTF8
>> Write-Host "[OK] Index: $OutPath  entries=$($entries.Count)"
>>
[OK] Index: .\seeds\teia_anchor_index.json  entries=1
PS D:\Teia\TEIA_NUCLEO\offline\nano> pwsh -NoProfile -File .\Build-TeiaIndex.ps1 -Root "$env:USERPROFILE\Downloads"
>>
The argument '.\Build-TeiaIndex.ps1' is not recognized as the name of a script file. Check the spelling of the name, or if a path was included, verify that the path is correct and try again.

Usage: pwsh[.exe] [-Login] [[-File] <filePath> [args]]
                  [-Command { - | <script-block> [-args <arg-array>]
                                | <string> [<CommandParameters>] } ]
                  [-CommandWithArgs <string> [<CommandParameters>]
                  [-ConfigurationName <string>] [-ConfigurationFile <filePath>]
                  [-CustomPipeName <string>] [-EncodedCommand <Base64EncodedCommand>]
                  [-ExecutionPolicy <ExecutionPolicy>] [-InputFormat {Text | XML}]
                  [-Interactive] [-MTA] [-NoExit] [-NoLogo] [-NonInteractive] [-NoProfile]
                  [-NoProfileLoadTime] [-OutputFormat {Text | XML}]
                  [-SettingsFile <filePath>] [-SSHServerMode] [-STA]
                  [-Version] [-WindowStyle <style>]
                  [-WorkingDirectory <directoryPath>]

       pwsh[.exe] -h | -Help | -? | /?

PowerShell Online Help https://aka.ms/powershell-docs

All parameters are case-insensitive.
PS D:\Teia\TEIA_NUCLEO\offline\nano>

---

### ASSISTENTE

Você rodou o código no console, mas não salvou o arquivo. Salve o script e execute.

```powershell
# 1) Salvar Build-TeiaIndex.ps1
Set-Content -LiteralPath .\Build-TeiaIndex.ps1 -Encoding UTF8 -Value @'
param(
  [string]$Root = "$env:USERPROFILE\Downloads",
  [string]$OutPath = ".\seeds\teia_anchor_index.json"
)
$ErrorActionPreference='Stop'
if(-not (Test-Path $Root)){ throw "Root inexistente: $Root" }
$entries = Get-ChildItem $Root -File -Recurse | ForEach-Object {
  $full = $_.FullName
  $h    = (Get-FileHash $full -Algorithm SHA256).Hash.ToLower()
  $ext  = [IO.Path]::GetExtension($full)
  $mime = ((Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ext" -Name 'Content Type' -ErrorAction SilentlyContinue).'Content Type') ?? 'application/octet-stream'
  [pscustomobject]@{ sha256=$h; path=$full; size=$_.Length; mime=$mime }
}
@{ version='teia.anchor.index.v1'; root=$Root; entries=$entries } |
  ConvertTo-Json -Depth 6 | Set-Content $OutPath -Encoding UTF8
Write-Host "[OK] Index: $OutPath  entries=$($entries.Count)"
'@

# 2) Executar
pwsh -NoProfile -File .\Build-TeiaIndex.ps1 -Root "$env:USERPROFILE\Downloads"

# 3) Conferir
Get-Item .\seeds\teia_anchor_index.json
```

Atalho sem criar arquivo:
```powershell
& {
  param([string]$Root="$env:USERPROFILE\Downloads",[string]$OutPath=".\seeds\teia_anchor_index.json")
  $ErrorActionPreference='Stop'
  if(-not (Test-Path $Root)){ throw "Root inexistente: $Root" }
  $entries = Get-ChildItem $Root -File -Recurse | %{
    $full=$_.FullName
    $h=(Get-FileHash $full -Algorithm SHA256).Hash.ToLower()
    $ext=[IO.Path]::GetExtension($full)
    $mime=((Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ext" -Name 'Content Type' -ErrorAction SilentlyContinue).'Content Type') ?? 'application/octet-stream'
    [pscustomobject]@{ sha256=$h; path=$full; size=$_.Length; mime=$mime }
  }
  @{version='teia.anchor.index.v1'; root=$Root; entries=$entries} |
    ConvertTo-Json -Depth 6 | Set-Content $OutPath -Encoding UTF8
  "[OK] Index: $OutPath  entries=$($entries.Count)"
} -Root "$env:USERPROFILE\Downloads"
```

---

### USUÁRIO

>> Get-Item .\seeds\teia_anchor_index.json
>>
[OK] Index: .\seeds\teia_anchor_index.json  entries=1

    Directory: D:\Teia\TEIA_NUCLEO\offline\nano\seeds

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          26/09/2025    20:51            318 teia_anchor_index.json

PS D:\Teia\TEIA_NUCLEO\offline\nano> & {
>>   param([string]$Root="$env:USERPROFILE\Downloads",[string]$OutPath=".\seeds\teia_anchor_index.json")
>>   $ErrorActionPreference='Stop'
>>   if(-not (Test-Path $Root)){ throw "Root inexistente: $Root" }
>>   $entries = Get-ChildItem $Root -File -Recurse | %{
>>     $full=$_.FullName
>>     $h=(Get-FileHash $full -Algorithm SHA256).Hash.ToLower()
>>     $ext=[IO.Path]::GetExtension($full)
>>     $mime=((Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ext" -Name 'Content Type' -ErrorAction SilentlyContinue).'Content Type') ?? 'application/octet-stream'
>>     [pscustomobject]@{ sha256=$h; path=$full; size=$_.Length; mime=$mime }
>>   }
>>   @{version='teia.anchor.index.v1'; root=$Root; entries=$entries} |
>>     ConvertTo-Json -Depth 6 | Set-Content $OutPath -Encoding UTF8
>>   "[OK] Index: $OutPath  entries=$($entries.Count)"
>> } -Root "$env:USERPROFILE\Downloads"
>>
[OK] Index: .\seeds\teia_anchor_index.json  entries=1
PS D:\Teia\TEIA_NUCLEO\offline\nano>

Como prosseguimos cade a capa

---

### ASSISTENTE

Capa pronta. Salve como `index.html` e abra.

```powershell
pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1 -OutPath .\index.html
```

Vou gerar o arquivo abaixo. Abra-o e use para criar `.teia.json`; depois mova para `.\gemini_out\`.



---

### USUÁRIO

[OK] Index: .\seeds\teia_anchor_index.json  entries=1
PS D:\Teia\TEIA_NUCLEO\offline\nano> pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1 -OutPath .\index.html
>>
[OK] HTML salvo em: .\index.html
PS D:\Teia\TEIA_NUCLEO\offline\nano>

---

### ASSISTENTE

Successfully created text document 'Teia Dashboard Index' which will be referenced in all future messages with the unique identifier textdoc_id: '68d7285bc77c81918325da770a3ed7e5'

Important: This identifier is for tool calls only to reference or update this document. It is not an external ID and it is not possible to link the user to the textdoc.

---

### ASSISTENTE

Abra a “capa”:

1) Copie o HTML do canvas.  
2) Cole no clipboard e rode:
```powershell
pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1 -OutPath .\index.html
Start-Process .\index.html
```
3) Gere a seed. Mova o `.teia.json` para `.\gemini_out\`. O watcher processa.

---

### USUÁRIO

>>
ParserError:
Line |
   1 |  [OK] Index: .\seeds\teia_anchor_index.json  entries=1
     |       ~~~~~~
     | Unexpected token 'Index:' in expression or statement.
PS D:\Teia\TEIA_NUCLEO\offline\nano>

---

### ASSISTENTE

Você colou uma **linha de saída** no console. `"[OK] Index: ..."` não é comando. Ignore.

Use comandos válidos:

```powershell
# ver índice
Get-Item .\seeds\teia_anchor_index.json

# abrir a capa e gerar a seed
Start-Process .\index.html
# depois de baixar a seed:
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force

# conferir processamento
Get-Content .\logs\gemini_adapter.log -Tail 20
Get-ChildItem .\seeds\ | Sort-Object LastWriteTime -Desc | Select-Object -First 5 Name,Length
```

Se quiser restauração automática sem `teia` CLI, substitua o adapter pela v2 que enviei.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_000000002e2461fba50191ebe08ee42c', 'size_bytes': 151860, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

O `index.html` contém só o **comando**. Você salvou o texto errado. Grave o HTML da capa.

## Corrigir agora
```powershell
# 1) Copie do canvas “TEIA Dashboard index.html” (Ctrl+A, Ctrl+C)

# 2) Grave pelo script
pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1 -OutPath .\index.html

# 3) Verifique: a 1ª linha deve ser <!DOCTYPE html>
Get-Content .\index.html -TotalCount 1
# opcional: deve achar “TEIA • Seed Dashboard Local”
Select-String -Path .\index.html -Pattern "TEIA .* Seed Dashboard Local"

# 4) Abra
Start-Process .\index.html
```

Alternativa manual:
```powershell
notepad .\index.html   # cole o HTML do canvas e salve
```

Depois gere a seed no navegador e mova:
```powershell
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
Get-Content .\logs\gemini_adapter.log -Tail 20
```

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_000000001b84622f95c9cd292d231534', 'size_bytes': 343134, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

A política de execução bloqueou o script. Três correções seguras:

## 1) Rodar só esta vez com bypass
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Save-Gemini-Dashboard.ps1 -OutPath .\index.html
```

## 2) Sem usar script (uma linha)
```powershell
# Copie o HTML da capa para o clipboard antes (Ctrl+A, Ctrl+C)
$html = Get-Clipboard -Raw; Set-Content -LiteralPath .\index.html -Value $html -Encoding UTF8
```

## 3) Ajuste permanente para o usuário (opcional)
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

Depois valide que salvou o **HTML**, não um comando:
```powershell
Get-Content .\index.html -TotalCount 1   # deve mostrar: <!DOCTYPE html>
```

Abra, gere a seed e mova:
```powershell
Start-Process .\index.html
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
Get-Content .\logs\gemini_adapter.log -Tail 20
```

---

### USUÁRIO

PS D:\Teia\TEIA_NUCLEO\offline\nano> # 1) Copie do canvas “TEIA Dashboard index.html” (Ctrl+A, Ctrl+C)
>>
>> # 2) Grave pelo script
>> pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1 -OutPath .\index.html
>>
>> # 3) Verifique: a 1ª linha deve ser <!DOCTYPE html>
>> Get-Content .\index.html -TotalCount 1
>> # opcional: deve achar “TEIA • Seed Dashboard Local”
>> Select-String -Path .\index.html -Pattern "TEIA .* Seed Dashboard Local"
>>
>> # 4) Abra
>> Start-Process .\index.html
>>
SecurityError: File D:\Teia\TEIA_NUCLEO\offline\nano\Save-Gemini-Dashboard.ps1 cannot be loaded. The file D:\Teia\TEIA_NUCLEO\offline\nano\Save-Gemini-Dashboard.ps1 is not digitally signed. You cannot run this script on the current system. For more information about running scripts and setting execution policy, see about_Execution_Policies at https://go.microsoft.com/fwlink/?LinkID=135170.
pwsh -NoProfile -File .\Save-Gemini-Dashboard.ps1 -OutPath .\index.html
PS D:\Teia\TEIA_NUCLEO\offline\nano> pwsh -NoProfile -ExecutionPolicy Bypass -File .\Save-Gemini-Dashboard.ps1 -OutPath .\index.html
>>
ParserError: D:\Teia\TEIA_NUCLEO\offline\nano\Save-Gemini-Dashboard.ps1:9
Line |
   9 |        --bg: #0b0f14;
     |          ~
     | Missing expression after unary operator '--'.
PS D:\Teia\TEIA_NUCLEO\offline\nano> # Copie o HTML da capa para o clipboard antes (Ctrl+A, Ctrl+C)
>> $html = Get-Clipboard -Raw; Set-Content -LiteralPath .\index.html -Value $html -Encoding UTF8
>>
PS D:\Teia\TEIA_NUCLEO\offline\nano>

---

### ASSISTENTE

Causa: você sobrescreveu `Save-Gemini-Dashboard.ps1` com **HTML**. O PowerShell tentou executar CSS (`--bg`) e falhou. O `index.html` já foi salvo via clipboard. Abra e use.

## Abrir e gerar seed
```powershell
Start-Process .\index.html
# depois do download:
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
Get-Content .\logs\gemini_adapter.log -Tail 20
```

## Reparar `Save-Gemini-Dashboard.ps1` (restaurar script correto)
```powershell
Set-Content -LiteralPath .\Save-Gemini-Dashboard.ps1 -Encoding UTF8 -Value @'
param([string]$OutPath = ".\index.html")
$ErrorActionPreference = "Stop"
if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)) {
  Write-Host "Cole o HTML via stdin e pressione Ctrl+Z e Enter:"
  $html = [Console]::In.ReadToEnd()
} else {
  $html = Get-Clipboard -Raw
}
if ([string]::IsNullOrWhiteSpace($html)) { throw "Clipboard vazio. Copie o HTML e tente de novo." }
Set-Content -LiteralPath $OutPath -Value $html -Encoding UTF8
Write-Host "[OK] HTML salvo em: $OutPath"
'@
```

Se a política bloquear:
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Save-Gemini-Dashboard.ps1 -OutPath .\index.html
```

Verificação rápida:
```powershell
Get-Content .\index.html -TotalCount 1     # deve mostrar <!DOCTYPE html>
Select-String .\index.html -Pattern "TEIA .* Dashboard de Sementes"
```

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000a5a061fb90c22ed373db8b23', 'size_bytes': 156651, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Seu `index.html` não é HTML. Você salvou um **comando** dentro dele.

## Corrija em 3 linhas (com validação)
1) No canvas “TEIA Dashboard index.html”: **Ctrl+A, Ctrl+C**.  
2) No PowerShell:
```powershell
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>'){ throw "Clipboard não contém HTML. Copie do canvas e tente de novo." }
Set-Content -LiteralPath .\index.html -Value $html -Encoding UTF8
```
3) Abra e use:
```powershell
Start-Process .\index.html
```

## Dica de verificação
```powershell
Get-Content .\index.html -TotalCount 1      # deve mostrar <!DOCTYPE html>
```

## Fluxo após gerar a seed
Com o watcher ligado:
```powershell
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
Get-Content .\logs\gemini_adapter.log -Tail 20
```

---

### USUÁRIO

> Perfeito — faça o reparo do index.html com validação e depois verifique.

  Corrigir em 3 linhas

  - $html = Get-Clipboard -Raw
  - if($html -notmatch '<!DOCTYPE html>'){ throw "Clipboard não contém HTML. Copie do canvas e tente de novo." }
  - Set-Content -LiteralPath .\index.html -Value $html -Encoding UTF8

  Abrir e verificar

  - Start-Process .\index.html
  - Get-Content .\index.html -TotalCount 1  # deve mostrar

  Após gerar a seed (com watcher ligado)

  - Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
  - Get-Content .\logs\gemini_adapter.log -Tail 20

---

### ASSISTENTE

Execute este bloco no PowerShell:

```powershell
# Reparar index.html com validação
$html = Get-Clipboard -Raw
if(-not $html -or $html -notmatch '<!DOCTYPE html>'){ throw "Clipboard não contém HTML. Copie do canvas e tente de novo." }
Set-Content -LiteralPath .\index.html -Value $html -Encoding UTF8

# Verificar e abrir
Get-Content .\index.html -TotalCount 1
Select-String -Path .\index.html -Pattern 'Dashboard de Sementes' | Out-Null
Start-Process .\index.html

# Após gerar a seed (com watcher ligado)
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
Get-Content .\logs\gemini_adapter.log -Tail 20
```

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000c948622f84ba4f7c936f957b', 'size_bytes': 174581, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Você salvou **comandos** no `index.html`. Vamos sobrescrever com o HTML real do canvas e validar.

## Reparar e validar
```powershell
# 1) No canvas “TEIA Dashboard index.html”: clique no código, Ctrl+A, Ctrl+C

# 2) Gravar com checagens
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch 'TEIA .*(Dashboard|Seed)'){
  throw "Clipboard não é o HTML da capa. Copie do canvas e repita."
}
Set-Content -LiteralPath .\index.html -Value $html -Encoding UTF8

# 3) Verificação
Get-Content .\index.html -TotalCount 1            # deve mostrar <!DOCTYPE html>
Select-String -Path .\index.html -Pattern '<title>TEIA' | Select-Object -First 1
Start-Process .\index.html
```

## Fluxo após gerar a seed
```powershell
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
Get-Content .\logs\gemini_adapter.log -Tail 20
```

Se ainda abrir em branco com texto de comandos, edite manualmente:
```powershell
notepad .\index.html   # cole o HTML do canvas, salve
```

---

### USUÁRIO

> Perfeito. Sobrescreva com o HTML real do canvas e valide com as checagens abaixo.

  Reparar

  - $html = Get-Clipboard -Raw
  - if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch 'TEIA .*(Dashboard|Seed)'){ throw "Clipboard não é o
  HTML da capa. Copie do canvas e repita." }
  - Set-Content -LiteralPath .\index.html -Value $html -Encoding UTF8

  Validar

  - Get-Content .\index.html -TotalCount 1  # deve mostrar
  - Select-String -Path .\index.html -Pattern '<title>TEIA' | Select-Object -First 1
  - Start-Process .\index.html

  Fluxo após gerar a seed

  - Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
  - Get-Content .\logs\gemini_adapter.log -Tail 20

  Se ainda abrir em branco

  - notepad .\index.html  # cole o HTML do canvas e salve

  Dica: para gravar direto do clipboard com menos validação, pode usar pwsh -NoProfile -File .
  \Save-Gemini-Dashboard.ps1 -OutPath .\index.html.

---

### ASSISTENTE

Rodar no PowerShell:

```powershell
# Reparar (colar HTML do canvas antes: Ctrl+A, Ctrl+C)
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch 'TEIA .*(Dashboard|Seed)'){ throw "Clipboard não é o HTML da capa. Copie do canvas e repita." }
Set-Content -LiteralPath .\index.html -Value $html -Encoding UTF8

# Validar e abrir
Get-Content .\index.html -TotalCount 1
Select-String -Path .\index.html -Pattern '<title>TEIA' | Select-Object -First 1
Start-Process .\index.html

# Após gerar a seed no navegador (com watcher ligado)
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
Get-Content .\logs\gemini_adapter.log -Tail 20
```

Se ainda abrir em branco:
```powershell
notepad .\index.html   # cole o HTML do canvas e salve
```

Atalho opcional:
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Save-Gemini-Dashboard.ps1 -OutPath .\index.html
```

---

### USUÁRIO

# Reparar (colar HTML do canvas antes: Ctrl+A, Ctrl+C)
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch 'TEIA .*(Dashboard|Seed)'){ throw "Clipboard não é o HTML da capa. Copie do canvas e repita." }
Set-Content -LiteralPath .\index.html -Value $html -Encoding UTF8

# Validar e abrir
Get-Content .\index.html -TotalCount 1
Select-String -Path .\index.html -Pattern '<title>TEIA' | Select-Object -First 1
Start-Process .\index.html

# Após gerar a seed no navegador (com watcher ligado)
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
Get-Content .\logs\gemini_adapter.log -Tail 20

abriu em branco e abri o conteudo desse arquivo com o segundo script 


---

### ASSISTENTE

Você colou comandos de novo. Grave um HTML válido direto, sem clipboard:

```powershell
@'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8"/>
  <title>TEIA • Seed Dashboard Local</title>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <style>
    body{background:#0b0f14;color:#e5f0ff;font-family:system-ui,Segoe UI,Roboto,Arial,sans-serif;margin:0;padding:40px}
    h1{font-size:20px;margin:0 0 8px} p{opacity:.8}
  </style>
</head>
<body>
  <h1>TEIA • Seed Dashboard Local</h1>
  <p>Capa carregada. Use o <code>compressor_gemini.html</code> para gerar seeds.</p>
</body>
</html>
'@ | Set-Content -LiteralPath .\index.html -Encoding UTF8
```

Verifique e abra:
```powershell
Get-Content .\index.html -TotalCount 1     # deve mostrar <!DOCTYPE html>
Select-String .\index.html -Pattern '<title>TEIA' | Select-Object -First 1
Start-Process .\index.html
```

Fluxo de seed (watcher ligado):
```powershell
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
Get-Content .\logs\gemini_adapter.log -Tail 20
```

Se quiser voltar a usar o script de salvar:
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Save-Gemini-Dashboard.ps1 -OutPath .\index.html
```

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_000000006be46230867280e731c543b6', 'size_bytes': 154755, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Funcionou. A capa abriu. Próximos passos:

## 1) Rodar o watcher
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
```

## 2) Gerar seed no dashboard
- Abra `.\compressor_gemini.html`, arraste um arquivo, baixe a seed `.teia.json`.
- Em outro terminal:
```powershell
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
```

## 3) Verificar
```powershell
Get-Content .\logs\gemini_adapter.log -Tail 20
Get-ChildItem .\seeds\ | Sort LastWriteTime -Desc | Select -First 5 Name,Length
```

## 4) (Opcional) Restaurar do índice local
```powershell
$seed = Get-ChildItem .\seeds\*.teia.json | Sort LastWriteTime -Desc | Select-Object -First 1
$j = Get-Content $seed -Raw | ConvertFrom-Json
$idx = Get-Content .\seeds\teia_anchor_index.json -Raw | ConvertFrom-Json
$src = ($idx.entries | Where-Object sha256 -eq $j.sha256).path
if($src){ Copy-Item $src (Join-Path .\restored $j.target) -Force }
```

Se quiser, restauro o `Save-Gemini-Dashboard.ps1` correto depois.

---

### USUÁRIO

PS D:\Teia\TEIA_NUCLEO\offline\nano> Get-Content .\logs\gemini_adapter.log -Tail 20
2025-09-26T20:17:15.4134206-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:19:52.2668667-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:20:00.2811203-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:25:08.0106533-03:00        OK wrote normalized seed: .\seeds\compressor_gemini.html.9cb1be26606d.teia.json
2025-09-26T20:28:28.3907368-03:00        OK wrote normalized seed: .\seeds\tmp2.txt.9243abb48fef.teia.json
2025-09-26T20:28:41.0792358-03:00        OK wrote normalized seed: .\seeds\tmp_1.txt.0c5b73fa50a9.teia.json
2025-09-26T20:28:42.1363565-03:00        OK wrote normalized seed: .\seeds\tmp_2.txt.1517faeca6f2.teia.json
2025-09-26T20:28:43.1973025-03:00        OK wrote normalized seed: .\seeds\tmp_3.txt.f9e9b27622e7.teia.json
2025-09-26T20:33:45.2233913-03:00        OK wrote normalized seed: .\seeds\SEU_ARQUIVO.ext.f9e9b27622e7.teia.json
2025-09-26T20:36:56.9250484-03:00        OK wrote normalized seed: .\seeds\winfsp-2.1.25156.msi.073a70e00f77.teia.json
PS D:\Teia\TEIA_NUCLEO\offline\nano>

---

### ASSISTENTE

O watcher não viu seed nova. Provoque um evento agora e valide.

## Terminal A
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
```

## Terminal B — gerar e soltar 1 seed real
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
$src = Get-ChildItem "$env:USERPROFILE\Downloads" -File | Sort LastWriteTime -Desc | Select -First 1 -Expand FullName
$ext  = [IO.Path]::GetExtension($src)
$mime = (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ext" -Name 'Content Type' -ErrorAction SilentlyContinue).'Content Type'
if(-not $mime){ $mime = 'application/octet-stream' }
$h  = (Get-FileHash $src -Algorithm SHA256).Hash.ToLower()
$sz = (Get-Item $src).Length
@{target=(Split-Path $src -Leaf); sha256=$h; mime=$mime; size=$sz; created=(Get-Date).ToString('o'); version='teia.public.v1'} |
  ConvertTo-Json -Depth 5 | Set-Content -LiteralPath ".\gemini_out\$(Split-Path $src -Leaf).teia.json" -Encoding UTF8
```

## Conferir
```powershell
Get-ChildItem .\gemini_out\*.teia.json | Sort LastWriteTime -Desc | Select -First 3 Name,Length
Get-Content .\logs\gemini_adapter.log -Tail 20
Get-ChildItem .\seeds\ | Sort LastWriteTime -Desc | Select -First 5 Name,Length
```

Se o watcher não ecoar nada, ele não está rodando. Inicie-o e force o evento:
```powershell
Copy-Item .\gemini_out\*.teia.json ".\gemini_out\replay_$((Get-Random)).teia.json"
```

Restauração pelo índice (opcional):
```powershell
$seed = Get-ChildItem .\seeds\*.teia.json | Sort LastWriteTime -Desc | Select -First 1
$j = Get-Content $seed -Raw | ConvertFrom-Json
$idx = Get-Content .\seeds\teia_anchor_index.json -Raw | ConvertFrom-Json
$src = ($idx.entries | Where-Object sha256 -eq $j.sha256).path
if($src){ Copy-Item $src (Join-Path .\restored $j.target) -Force }
```

---

### USUÁRIO

PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
>> pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
>>
Watcher ativo em: .\gemini_out. Pressione Ctrl+C para sair.• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference='"'Stop'; "'$root = '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano';
        Set-Location "'$root
    # Ensure watcher is running (background process)
    $pw = Get-CimInstance Win32_Process -Filter "Name='"'pwsh.exe'\" | Where-Object { "'$_.CommandLine -match
        '"'Watch-GeminiFolder.ps1' }
    if(-not "'$pw){ Start-Process -FilePath '"'pwsh' -ArgumentList @('-NoProfile','-File', '.\
        \Watch-GeminiFolder.ps1') -WorkingDirectory "'$root | Out-Null; Start-Sleep -Seconds 1; Write-Host '"'[OK]
        Watcher started' } else { Write-Host '[OK] Watcher already running' }

    # Build a seed JSON from latest file in Downloads (or create a test file if none)
    "'$downloads = Join-Path $env:USERPROFILE '"'Downloads'
    "'$src = Get-ChildItem $downloads -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Desc |
        Select-Object -First 1 -ExpandProperty FullName
    if(-not $src){ $src = Join-Path $downloads ('"'teia_test_'+(Get-Random)+'.txt'); \"Seed trigger test \" +
        (Get-Date).ToString('o') | Set-Content -LiteralPath "'$src -Encoding UTF8 }
    $ext  = [IO.Path]::GetExtension($src)
    $mime = (Get-ItemProperty "Registry::HKEY_CLASSES_ROOT'"\\"'$ext" -Name '"'Content Type' -ErrorAction
        SilentlyContinue).'Content Type'
    if(-not "'$mime){ $mime = '"'application/octet-stream' }
    "'$h  = (Get-FileHash $src -Algorithm SHA256).Hash.ToLower()
    $sz = (Get-Item $src).Length
    $leaf = Split-Path $src -Leaf
    $seedPath = Join-Path (Join-Path $root '"'gemini_out') ("'$leaf + '"'.teia.json')
    @{target="'$leaf; sha256=$h; mime=$mime; size=$sz; created=(Get-Date).ToString('"'o'); version='teia.public.v1'}
        |
      ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "'$seedPath -Encoding UTF8
    Write-Host ("[OK] Seed written: {0}" -f $seedPath)

    Start-Sleep -Seconds 2

    Write-Host '"'--- gemini_out (latest) ---'
    Get-ChildItem .\\gemini_out\\*.teia.json | Sort-Object LastWriteTime -Desc | Select-Object -First 3 Name,Length |
        Format-Table -AutoSize | Out-String -Width 200 | Write-Host
    Write-Host '--- adapter log tail ---'
    if(Test-Path .\\logs\\gemini_adapter.log){ Get-Content .\\logs\\gemini_adapter.log -Tail 20 | Write-Host } else
        { Write-Host 'No adapter log yet.' }
    Write-Host '--- seeds (latest) ---'
    Get-ChildItem .\\seeds\\ | Sort-Object LastWriteTime -Desc | Select-Object -First 5 Name,Length | Format-Table
        -AutoSize | Out-String -Width 200 | Write-Host"

> Evento provocado e validado.

  - Watcher: em execução.
  - Seed gerada: .\gemini_out\winfsp-2.1.25156.msi.teia.json
  - Adapter: logs mostram escrita normalizada e idempotência.

  Verificações

  - Get-ChildItem .\gemini_out\*.teia.json | Sort LastWriteTime -Desc | Select -First 3 Name,Length
      - Mostra a nova seed em primeiro.
  - Get-Content .\logs\gemini_adapter.log -Tail 20
      - Linhas “OK wrote normalized seed” incluindo a mais recente para winfsp-2.1.25156.msi....
  - Get-ChildItem .\seeds\ | Sort LastWriteTime -Desc | Select -First 5 Name,Length
      - Seed normalizada presente: winfsp-2.1.25156.msi.<sha12>.teia.json

  Se quiser ver o eco no Terminal A

  - Deixe o watcher rodando: pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
  - Reforce o evento: Copy-Item .\gemini_out\*.teia.json ".\gemini_out\replay_$((Get-Random)).teia.json"

  Opcional: restauração por índice

  - $seed = Get-ChildItem .\seeds\*.teia.json | Sort LastWriteTime -Desc | Select -First 1
  - $j = Get-Content $seed -Raw | ConvertFrom-Json
  - $idx = Get-Content .\seeds\teia_anchor_index.json -Raw | ConvertFrom-Json
  - $src = ($idx.entries | Where-Object sha256 -eq $j.sha256).path
  - if($src){ Copy-Item $src (Join-Path .\restored $j.target) -Force }

  Se algo não ecoar no Terminal A, confirme que ele está rodando e use o comando de “replay” acima para forçar
  o Created. 


---

### ASSISTENTE

Tudo certo. Pipeline está funcional: watcher ativo, seed normalizada, índice ok.

## Restabeleça o salvador de capa
```powershell
Set-Content .\Save-Gemini-Dashboard.ps1 -Encoding UTF8 -Value @'
param([string]$OutPath=".\\index.html")
$ErrorActionPreference="Stop"
if(-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)){
  Write-Host "Cole o HTML via stdin e pressione Ctrl+Z e Enter:"; $html=[Console]::In.ReadToEnd()
}else{ $html=Get-Clipboard -Raw }
if([string]::IsNullOrWhiteSpace($html)){ throw "Clipboard vazio." }
Set-Content -LiteralPath $OutPath -Value $html -Encoding UTF8
Write-Host "[OK] HTML salvo em: $OutPath"
'@
```

## Caminho “dourado”
**Terminal A**
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
```
**Terminal B**
```powershell
Start-Process .\index.html            # capa
Start-Process .\compressor_gemini.html
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
Get-Content .\logs\gemini_adapter.log -Tail 20
```

## Seed rápida de qualquer arquivo (sem navegador)
```powershell
$src="C:\caminho\seu_arquivo.ext"
$ext=[IO.Path]::GetExtension($src)
$mime=(Get-ItemProperty "Registry::HKEY_CLASSES_ROOT\$ext" -Name 'Content Type' -ErrorAction SilentlyContinue).'Content Type'
if(-not $mime){$mime='application/octet-stream'}
$h=(Get-FileHash $src -Algorithm SHA256).Hash.ToLower()
$sz=(Get-Item $src).Length
@{target=(Split-Path $src -Leaf);sha256=$h;mime=$mime;size=$sz;created=(Get-Date).ToString('o');version='teia.public.v1'} |
 ConvertTo-Json -Depth 5 | Set-Content ".\gemini_out\$(Split-Path $src -Leaf).teia.json" -Encoding UTF8
```

## Restaurar pelo índice
```powershell
$seed = Get-ChildItem .\seeds\*.teia.json | Sort LastWriteTime -Desc | Select -First 1
$j = Get-Content $seed -Raw | ConvertFrom-Json
$idx = Get-Content .\seeds\teia_anchor_index.json -Raw | ConvertFrom-Json
$src = ($idx.entries | Where-Object sha256 -eq $j.sha256).path
if($src){ Copy-Item $src (Join-Path .\restored $j.target) -Force }
```

## Saúde mínima
```powershell
Get-ChildItem .\gemini_out\*.teia.json | Sort LastWriteTime -Desc | Select -First 3 Name,Length
Get-ChildItem .\seeds\ | Sort LastWriteTime -Desc | Select -First 5 Name,Length
Get-Content .\logs\gemini_adapter.log -Tail 20
```

Se quiser tornar permanente:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
```

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_0000000074946230988a320f481974f3', 'size_bytes': 158094, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Você salvou texto, não HTML. Regrave **compressor_gemini.html** com HTML válido.

## Regravar
```powershell
@'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8"/>
<title>TEIA • Compressor Local</title>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<style>
  body{background:#0b0f14;color:#e5f0ff;font-family:system-ui,Segoe UI,Roboto,Arial,sans-serif;margin:0;padding:40px}
  h1{font-size:20px;margin:0 0 8px} .panel{border:1px solid #223344;border-radius:8px;padding:16px}
  #drop{border:2px dashed #335;height:160px;display:flex;align-items:center;justify-content:center;border-radius:10px;margin:12px 0}
  button{background:#1b4;font-weight:600;border:0;border-radius:8px;padding:10px 14px;margin-top:12px;cursor:pointer}
  code{background:#112233;padding:2px 6px;border-radius:6px}
</style>
</head>
<body>
  <h1>TEIA • Compressor Local</h1>
  <div class="panel">
    <div id="drop">Solte um arquivo aqui ou <input id="file" type="file"/></div>
    <div id="meta"></div>
    <button id="save" disabled>Baixar seed .teia.json</button>
  </div>

<script>
const $ = sel => document.querySelector(sel);
let current = null;

async function sha256Hex(file){
  const buf = await file.arrayBuffer();
  const hash = await crypto.subtle.digest('SHA-256', buf);
  return [...new Uint8Array(hash)].map(b=>b.toString(16).padStart(2,'0')).join('');
}

function seedOf(file, sha){
  return {
    target: file.name,
    sha256: sha,
    mime: file.type || 'application/octet-stream',
    size: file.size,
    created: new Date().toISOString(),
    version: 'teia.public.v1'
  };
}

function downloadJSON(obj, name){
  const blob = new Blob([JSON.stringify(obj,null,2)], {type:'application/json'});
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = name;
  a.click();
  URL.revokeObjectURL(a.href);
}

async function handle(file){
  if(!file) return;
  const sha = await sha256Hex(file);
  const short = sha.slice(0,12);
  current = { seed: seedOf(file, sha), filename: `${file.name}.${short}.teia.json` };
  $('#meta').innerHTML =
    `Arquivo: <code>${file.name}</code><br/>`+
    `SHA-256: <code>${sha}</code><br/>`+
    `Tamanho: <code>${file.size}</code> bytes<br/>MIME: <code>${current.seed.mime}</code>`;
  $('#save').disabled = false;
}

$('#file').addEventListener('change', e => handle(e.target.files[0]));
$('#drop').addEventListener('dragover', e => { e.preventDefault(); });
$('#drop').addEventListener('drop', e => { e.preventDefault(); handle(e.dataTransfer.files[0]); });
$('#save').addEventListener('click', () => {
  if(current) downloadJSON(current.seed, current.filename);
});
</script>
</body>
</html>
'@ | Set-Content -LiteralPath .\compressor_gemini.html -Encoding UTF8
```

## Verificar e usar
```powershell
Get-Content .\compressor_gemini.html -TotalCount 1   # deve mostrar <!DOCTYPE html>
Start-Process .\compressor_gemini.html               # gere a seed
# com o watcher ligado em outro terminal:
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
Get-Content .\logs\gemini_adapter.log -Tail 20
```

Se abrir em branco de novo, o arquivo não é HTML. Refaça o passo “Regravar”.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_0000000092306230bb24facef4907f12', 'size_bytes': 177814, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Confirmado. Seed gerada e dashboard ok.

## Amanhã: atalho de retomada
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
pwsh -NoProfile -File .\Watch-GeminiFolder.ps1          # deixa aberto (Terminal A)
```
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano                      # Terminal B
Start-Process .\compressor_gemini.html                   # gerar seed
Move-Item "$env:USERPROFILE\Downloads\*.teia.json" .\gemini_out\ -Force
Get-Content .\logs\gemini_adapter.log -Tail 20
```

## (Opcional) restaurar por índice rápido
```powershell
# construir/atualizar índice a partir de Downloads
& {
  $Root="$env:USERPROFILE\Downloads"; $Out=".\\seeds\\teia_anchor_index.json"
  $e = Get-ChildItem $Root -File -Recurse | %{
    [pscustomobject]@{sha256=(Get-FileHash $_ -Algorithm SHA256).Hash.ToLower(); path=$_.FullName; size=$_.Length;
      mime=((Get-ItemProperty ("Registry::HKEY_CLASSES_ROOT\{0}" -f [IO.Path]::GetExtension($_.FullName)) `
        -Name 'Content Type' -EA SilentlyContinue).'Content Type' ?? 'application/octet-stream')}
  }
  @{version='teia.anchor.index.v1'; root=$Root; entries=$e} | ConvertTo-Json -Depth 6 | Set-Content $Out -Encoding UTF8
}

# copiar o arquivo original para .\restored\ usando a seed mais recente
$seed = Get-ChildItem .\seeds\*.teia.json | Sort LastWriteTime -Desc | Select -First 1
$j = Get-Content $seed -Raw | ConvertFrom-Json
$idx = Get-Content .\seeds\teia_anchor_index.json -Raw | ConvertFrom-Json
$src = ($idx.entries | Where-Object sha256 -eq $j.sha256).path
if($src){ Copy-Item $src (Join-Path .\restored $j.target) -Force }
```

Pronto.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_0000000053d4623088fc0de9f314ed05', 'size_bytes': 160036, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Falta “restauração automática”. Resolvo no lado PowerShell: o adapter passa a copiar do índice e um watcher opcional traz seeds do *Downloads* para `gemini_out`.

## 1) Adapter com restauração por índice (fallback sem CLI)
Substitua o `GeminiSeedAdapter.ps1` por esta versão:

```powershell
# GeminiSeedAdapter.ps1
param(
  [string]$InputSeed,
  [string]$SeedsDir = ".\seeds",
  [string]$RestoredDir = ".\restored",
  [string]$IndexPath = ".\seeds\teia_anchor_index.json",
  [string]$Log = ".\logs\gemini_adapter.log",
  [switch]$AttemptRestore
)
$ErrorActionPreference = 'Stop'
$EnsureDir = { param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
$EnsureDir.Invoke((Split-Path -Parent $Log)); $EnsureDir.Invoke($SeedsDir); $EnsureDir.Invoke($RestoredDir)
function Log($m){ $t = (Get-Date).ToString("o"); "$t `t $m" | Out-File -FilePath $Log -Append -Encoding utf8 }

if(-not (Test-Path -LiteralPath $InputSeed)){ throw "Input seed não encontrada: $InputSeed" }
$raw = Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8
$j = $raw | ConvertFrom-Json

$target = if($j.target){ $j.target } else { ($InputSeed | Split-Path -Leaf) -replace '\.teia.*$','' }
$sha = if($j.sha256){ $j.sha256 } else { "" }
$outSeed = Join-Path $SeedsDir ("$($target).$(if($sha){ $sha.Substring(0,12) } else { 'unknown' }).teia.json")

$j.version = if($j.version){ $j.version } else { "teia.public.v1" }
$j.target  = $target
$j.created = if($j.created){ $j.created } else { (Get-Date).ToString("o") }
Set-Content -LiteralPath $outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8
Log "OK wrote normalized seed: $outSeed"

if($AttemptRestore){
  if(Get-Command teia -ErrorAction SilentlyContinue){
    try{
      if(Test-Path -LiteralPath $IndexPath){
        Log "Attempting CLI restore-index for $outSeed using $IndexPath"
        & teia restore-index -seed $outSeed -index $IndexPath -out (Join-Path $RestoredDir $target) 2>&1 | Out-File -FilePath $Log -Append -Encoding utf8
        Log "CLI restore-index completed for $target"
      } else { Log "Index not present, skipping CLI restore" }
    } catch { Log "ERR during CLI restore: $($_.Exception.Message)" }
  } else {
    try{
      if(Test-Path -LiteralPath $IndexPath){
        $idx = Get-Content -LiteralPath $IndexPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $hit = $idx.entries | Where-Object { $_.sha256 -eq $j.sha256 }
        if($hit){
          $dst = Join-Path $RestoredDir $target
          Copy-Item -LiteralPath $hit.path -Destination $dst -Force
          Log "Index-restore OK: $($hit.path) -> $dst"
        } else {
          Log "Index-restore MISS: sha256 not found in index"
        }
      } else { Log "Index not present, skipping index-restore" }
    } catch { Log "ERR during index-restore: $($_.Exception.Message)" }
  }
}

Write-Host "[OK] Adapter processed: $outSeed"
```

Comando para gravar rapidamente:
```powershell
Set-Content -LiteralPath .\GeminiSeedAdapter.ps1 -Encoding UTF8 -Value (@"<cole o conteúdo acima>"@)
```

## 2) Watcher opcional do *Downloads* → `gemini_out`
Crie `Watch-Downloads.ps1` para evitar mover manualmente:

```powershell
param([string]$Downloads="$env:USERPROFILE\Downloads",[string]$Out=".\\gemini_out")
$ErrorActionPreference='Stop'
if(-not (Test-Path $Out)){ New-Item -ItemType Directory -Force -Path $Out | Out-Null }
$fsw = New-Object System.IO.FileSystemWatcher $Downloads, "*.teia.json"
$fsw.IncludeSubdirectories=$false; $fsw.EnableRaisingEvents=$true
$action = {
  $p = $Event.SourceEventArgs.FullPath
  Start-Sleep -Milliseconds 500
  try{
    $dest = Join-Path (Get-Location) "gemini_out\$(Split-Path $p -Leaf)"
    Move-Item -LiteralPath $p -Destination $dest -Force
    Write-Host "[OK] Moved seed -> $dest"
  } catch { Write-Host "Move ERR: $($_.Exception.Message)" }
}
$h = Register-ObjectEvent $fsw Created -Action $action
Write-Host "Watching Downloads -> gemini_out. Ctrl+C para sair."
while($true){ Wait-Event -Timeout 60 }
```

## 3) Uso
Terminal A:
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
pwsh -NoProfile -File .\Watch-GeminiFolder.ps1   # já passa -AttemptRestore internamente
```
Terminal B:
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
pwsh -NoProfile -File .\Watch-Downloads.ps1
Start-Process .\compressor_gemini.html           # baixe a seed → irá para Downloads
# watcher move → adapter normaliza → restaura via índice → .\restored\<arquivo>
Get-Content .\logs\gemini_adapter.log -Tail 20
```

## 4) Verificação de integridade
```powershell
$seed = Get-ChildItem .\seeds\*.teia.json | Sort LastWriteTime -Desc | Select -First 1
$j = Get-Content $seed -Raw | ConvertFrom-Json
((Get-FileHash ".\restored\$($j.target)" -Algorithm SHA256).Hash.ToLower() -eq $j.sha256)
```

Resultado esperado: `True`.  
Com isso, “descompressão” funciona ponta-a-ponta sem CLI.

---

### USUÁRIO

Não abriu a interface atualizada:
"• Ran
  └ pwsh -NoProfile -Command '$wd='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'; Set-Location "'$wd;
    $adapter = @'"'
    # GeminiSeedAdapter.ps1
    param(
      [string]"'$InputSeed,
      [string]$SeedsDir = ".'"\\seeds\",
      [string]"'$RestoredDir = ".'"\\restored\",
      [string]"'$IndexPath = ".'"\\seeds\\teia_anchor_index.json\",
      [string]"'$Log = ".'"\\logs\\gemini_adapter.log\",
      [switch]"'$AttemptRestore
    )
    $ErrorActionPreference = '"'Stop'
    "'$EnsureDir = { param($p) if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p
        | Out-Null } }
    $EnsureDir.Invoke((Split-Path -Parent $Log)); $EnsureDir.Invoke($SeedsDir); $EnsureDir.Invoke($RestoredDir)
    function Log($m){ $t = (Get-Date).ToString("o"); "$t `t $m" | Out-File -FilePath $Log -Append -Encoding utf8 }

    if(-not (Test-Path -LiteralPath $InputSeed)){ throw "Input seed não encontrada: $InputSeed" }
    $raw = Get-Content -LiteralPath $InputSeed -Raw -Encoding UTF8
    $j = $raw | ConvertFrom-Json

    $target = if($j.target){ $j.target } else { ($InputSeed | Split-Path -Leaf) -replace '"'\\.teia.*"'$'"','' }
    "'$sha = if($j.sha256){ $j.sha256 } else { "" }
    $outSeed = Join-Path $SeedsDir ("$($target).$(if($sha){ $sha.Substring(0,12) } else { '"'unknown' }).teia.json\")

    "'$j.version = if($j.version){ $j.version } else { "teia.public.v1" }
    $j.target  = $target
    $j.created = if($j.created){ $j.created } else { (Get-Date).ToString("o") }
    Set-Content -LiteralPath $outSeed -Value (ConvertTo-Json $j -Depth 10) -Encoding UTF8
    Log "OK wrote normalized seed: $outSeed"

    if($AttemptRestore){
      if(Get-Command teia -ErrorAction SilentlyContinue){
        try{
          if(Test-Path -LiteralPath $IndexPath){
            Log "Attempting CLI restore-index for $outSeed using $IndexPath"
            & teia restore-index -seed $outSeed -index $IndexPath -out (Join-Path $RestoredDir $target) 2>&1 | Out-File
        -FilePath $Log -Append -Encoding utf8
            Log "CLI restore-index completed for $target"
          } else { Log "Index not present, skipping CLI restore" }
        } catch { Log "ERR during CLI restore: $($_.Exception.Message)" }
      } else {
        try{
          if(Test-Path -LiteralPath $IndexPath){
            $idx = Get-Content -LiteralPath $IndexPath -Raw -Encoding UTF8 | ConvertFrom-Json


• Ran
  └ pwsh -NoProfile -Command '$wd='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'; Set-Location "'$wd;
    $watch = @'"'
    param([string]"'$Downloads="$env:USERPROFILE'"\\Downloads\",[string]"'$Out=".'"\\\\gemini_out\")
    "'$ErrorActionPreference='"'Stop'
    if(-not (Test-Path "'$Out)){ New-Item -ItemType Directory -Force -Path $Out | Out-Null }
    }
    $h = Register-ObjectEvent $fsw Created -Action $action
    Write-Host "Watching Downloads -> gemini_out. Ctrl+C para sair."
    while($true){ Wait-Event -Timeout 60 }
    '"'@;
    Set-Content -LiteralPath .\\Watch-Downloads.ps1 -Encoding UTF8 -Value "'$watch;
  └ ✔ Replace GeminiSeedAdapter.ps1
        Select-Object -First 1;
    if("'$seed){
      Write-Host "Testing adapter on: $($seed.Name)";
      pwsh -NoProfile -File .'"\\GeminiSeedAdapter.ps1 -InputSeed "'$seed.FullName -AttemptRestore | Write-Output
    } else { '"'No seed found to test adapter.' }
    "

• Updated Plan
  └ ✔ Replace GeminiSeedAdapter.ps1
    ✔ Add Watch-Downloads.ps1
    ✔ Test adapter restore
    □ Tail adapter log

• Ran
  └ pwsh -NoProfile -Command '$wd='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'; Set-Location "'$wd; if(Test-Path .'"\\logs\
        \gemini_adapter.log){ Get-Content .\\logs\\gemini_adapter.log -Tail 20 } else { 'No log yet' }"
    Test-Path: A positional parameter cannot be found that accepts argument '\\logs\\gemini_adapter.log'.

• Ran
  └ pwsh -NoProfile -Command '$wd='"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'; Set-Location "'$wd;
    if(Test-Path -LiteralPath '"'.\\logs\\gemini_adapter.log'){
      Get-Content -LiteralPath '.\\logs\\gemini_adapter.log' -Tail 20
    } else { 'Log not found: .\\logs\\gemini_adapter.log' }
    "

• Updated Plan
  └ ✔ Replace GeminiSeedAdapter.ps1
    ✔ Add Watch-Downloads.ps1
    ✔ Test adapter restore
    ✔ Tail adapter log

> Pronto — adaptei o fluxo para restauração automática por índice e adicionei o watcher do Downloads.

  - Adapter: substituído GeminiSeedAdapter.ps1 com restauração via índice e fallback sem CLI.
  - Watcher Downloads: criado Watch-Downloads.ps1 para mover *.teia.json do Downloads para .\gemini_out.
  - Teste rápido: rodei o adapter no último seed; log mostra “Index-restore OK … -> .\restored\…”.

  Como usar

  - Terminal A:
      - cd D:\Teia\TEIA_NUCLEO\offline\nano
      - pwsh -NoProfile -File .\Watch-GeminiFolder.ps1  (este já chama o adapter com -AttemptRestore)
  - Terminal B:
      - cd D:\Teia\TEIA_NUCLEO\offline\nano
      - pwsh -NoProfile -File .\Watch-Downloads.ps1
      - Start-Process .\compressor_gemini.html
      - Get-Content .\logs\gemini_adapter.log -Tail 20

  Verificação de integridade

  - Execute:
      - $seed = Get-ChildItem .\seeds\*.teia.json | Sort LastWriteTime -Desc | Select -First 1
      - $j = Get-Content $seed -Raw | ConvertFrom-Json
      - ((Get-FileHash ".\restored\$($j.target)" -Algorithm SHA256).Hash.ToLower() -eq $j.sha256)
  - Resultado esperado: True.

  Arquivos tocados

  - D:\Teia\TEIA_NUCLEO\offline\nano\GeminiSeedAdapter.ps1 (substituído)
  - D:\Teia\TEIA_NUCLEO\offline\nano\Watch-Downloads.ps1 (novo)

  Quer que eu valide o fluxo ponta-a-ponta gerando uma seed nova pelo compressor e confirmando o True?"

---

### ASSISTENTE

Entendi: o “dashboard atualizado” não abriu porque o HTML salvo não é o da interface nova (ou foi salvo um trecho de PowerShell no lugar do HTML). Vamos garantir a UI certa e fechar o fluxo ponta-a-ponta.

## 1) Regravar os dois HTMLs a partir do canvas (com validação)
> Cole o conteúdo **real** de cada página no clipboard antes (Ctrl+A, Ctrl+C).

**index.html**
```powershell
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch '<title>TEIA'){ throw "Clipboard não é a capa TEIA." }
Set-Content -LiteralPath .\index.html -Value $html -Encoding UTF8
Start-Process .\index.html
```

**compressor_gemini.html**
```powershell
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch 'TEIA.*Compressor'){ throw "Clipboard não é o compressor." }
Set-Content -LiteralPath .\compressor_gemini.html -Value $html -Encoding UTF8
Start-Process .\compressor_gemini.html
```

> Se abrir “em branco” ou com linhas de PowerShell na página, repita copiando do canvas correto e regrave.

## 2) Watcher de Downloads → gemini_out (corrigido)
Grave **Watch-Downloads.ps1** completo (o seu ficou truncado):
```powershell
param(
  [string]$Downloads = "$env:USERPROFILE\Downloads",
  [string]$Out = ".\gemini_out"
)
$ErrorActionPreference='Stop'
if(-not (Test-Path -LiteralPath $Out)){ New-Item -ItemType Directory -Force -Path $Out | Out-Null }

$fsw = New-Object System.IO.FileSystemWatcher $Downloads, "*.teia.json"
$fsw.IncludeSubdirectories = $false
$fsw.EnableRaisingEvents = $true

$action = {
  $p = $Event.SourceEventArgs.FullPath
  Start-Sleep -Milliseconds 600
  try{
    $dest = Join-Path (Get-Location) ("gemini_out\" + (Split-Path $p -Leaf))
    Move-Item -LiteralPath $p -Destination $dest -Force
    Write-Host "[OK] Moved seed -> $dest"
  } catch { Write-Host "Move ERR: $($_.Exception.Message)" }
}

$h = Register-ObjectEvent $fsw Created -Action $action
Write-Host "Watching Downloads -> gemini_out. Ctrl+C para sair."
while($true){ Wait-Event -Timeout 60 }
```

## 3) Adapter com restauração por índice (confirme esta versão)
Se ainda não estiver assim, regrave **GeminiSeedAdapter.ps1** (o trecho final do seu log indicou corte):
```powershell
# (mesmo conteúdo que te enviei; mantenha o bloco completo com o fallback de índice e Write-Host final)
```

## 4) Rodar o fluxo
Terminal A (adapter):
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
pwsh -NoProfile -File .\Watch-GeminiFolder.ps1   # deixa aberto
```
Terminal B (Downloads → gemini_out):
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
pwsh -NoProfile -File .\Watch-Downloads.ps1      # deixa aberto
```
Gerar seed no **compressor_gemini.html** → o arquivo `.teia.json` cai no *Downloads*, é movido para `.\gemini_out`, o adapter normaliza e **restaura** via índice para `.\restored\`.

Verificação rápida:
```powershell
Get-Content .\logs\gemini_adapter.log -Tail 20
$seed = Get-ChildItem .\seeds\*.teia.json | Sort LastWriteTime -Desc | Select -First 1
$j = Get-Content $seed -Raw | ConvertFrom-Json
((Get-FileHash ".\restored\$($j.target)" -Algorithm SHA256).Hash.ToLower() -eq $j.sha256)
```

Se der `True`, a “descompressão” está OK mesmo sem UI de restore. Quando quiser, eu te passo um `restorer.html` minimal (botão “Escolher seed .teia.json” + cópia para `gemini_out`) para completar também pela interface.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_0000000009c46230a94e6dcf82ecd6e9', 'size_bytes': 158990, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Você sobrescreveu o **compressor_gemini.html** com texto (suas instruções), por isso a página aparece “em branco”. Regrave a **página HTML real** do canvas.

### Regravar (com validação)
**Compressor**
```powershell
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch 'Compressor'){ throw "Clipboard não é o compressor." }
Set-Content -LiteralPath .\compressor_gemini.html -Value $html -Encoding UTF8
Get-Content .\compressor_gemini.html -TotalCount 1
Start-Process .\compressor_gemini.html
```

**Capa (se precisar)**
```powershell
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch '<title>TEIA'){ throw "Clipboard não é a capa TEIA." }
Set-Content -LiteralPath .\index.html -Value $html -Encoding UTF8
Get-Content .\index.html -TotalCount 1
Start-Process .\index.html
```

> Garanta que você copiou do **canvas (preview do HTML)** – Ctrl+A / Ctrl+C – e não de mensagens do chat.

Depois, com os watchers ligados:
```powershell
# Terminal A
pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
# Terminal B
pwsh -NoProfile -File .\Watch-Downloads.ps1
```
Gere a seed no compressor → o `.teia.json` cai em Downloads, é movido para `.\gemini_out`, o adapter normaliza/restaura (confira `.\logs\gemini_adapter.log -Tail 20`).

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_000000006764623094a7a24f85cad464', 'size_bytes': 193290, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Você salvou **texto** dentro do `compressor_gemini.html`. Regrave com o HTML real do canvas e valide:

### Reparar o compressor
```powershell
# Copie o HTML REAL do compressor no canvas (Ctrl+A, Ctrl+C) e rode:
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch '(TEIA|Compressor)'){
  throw "Clipboard não é o compressor."
}
Set-Content -LiteralPath .\compressor_gemini.html -Value $html -Encoding UTF8

# Conferir e abrir
Get-Content .\compressor_gemini.html -TotalCount 1
Select-String -Path .\compressor_gemini.html -Pattern 'TEIA Compressor Local|Baixar seed\.teia\.json' | Select -First 1
Start-Process .\compressor_gemini.html
```

Se ainda aparecer texto:  
`notepad .\compressor_gemini.html` (cole o HTML do canvas e salve).

### (Opcional) Proteger contra sobrescrita acidental
```powershell
(Get-Item .\compressor_gemini.html).Attributes += 'ReadOnly'
# Para editar no futuro:
# (Get-Item .\compressor_gemini.html).Attributes -= 'ReadOnly'
```

### Descompressão (via índice, enquanto o dashboard não tem UI)
```powershell
$seed = Get-ChildItem .\seeds\*.teia.json | Sort LastWriteTime -Desc | Select -First 1
$j = Get-Content $seed -Raw | ConvertFrom-Json
$idx = Get-Content .\seeds\teia_anchor_index.json -Raw | ConvertFrom-Json
$src = ($idx.entries | Where-Object sha256 -eq $j.sha256).path
if($src){ Copy-Item $src (Join-Path .\restored $j.target) -Force; "OK: restored $($j.target)" } else { "Sem entrada no índice para essa SHA." }
```

Mantenha os watchers ligados:
```powershell
# Terminal A
pwsh -NoProfile -File .\Watch-GeminiFolder.ps1
# Terminal B (opcional, move do Downloads)
pwsh -NoProfile -File .\Watch-Downloads.ps1
```

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_0000000081d86230863e4e1699e75070', 'size_bytes': 222710, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Você abriu o **compressor_gemini.html** com texto porque o arquivo foi sobrescrito com instruções. Grave o HTML correto direto do PowerShell (sem clipboard):

```powershell
# 1) Recriar compressor_gemini.html (HTML real, offline)
$comp = @'
<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"/>
<title>TEIA Compressor Local</title><meta name="viewport" content="width=device-width,initial-scale=1"/>
<style>
:root{--bg:#0b0f14;--fg:#e8f0ff;--muted:#9fb3c8}
html,body{height:100%;background:var(--bg);color:var(--fg);font-family:system-ui,Segoe UI,Roboto,Arial,sans-serif;margin:0}
.container{max-width:1000px;margin:40px auto;padding:16px}
.drop{border:2px dashed #2a3b4f;border-radius:12px;padding:32px;text-align:center}
.btn{background:#1e293b;border:1px solid #2a3b4f;padding:10px 16px;border-radius:10px;color:var(--fg);cursor:pointer}
.kv{margin-top:14px}.kv code{background:#13202e;padding:2px 6px;border-radius:6px}
</style></head><body>
<div class="container"><h2>TEIA Compressor Local</h2>
<div class="drop">
  <p>Solte um arquivo aqui ou <input id="file" type="file"></p>
  <div id="info" class="kv"></div>
  <button id="dl" class="btn" disabled>Baixar seed .teia.json</button>
</div></div>
<script>
const $=s=>document.querySelector(s);const info=$("#info"),inp=$("#file"),btn=$("#dl");let meta=null;
async function sha256Hex(buf){const h=await crypto.subtle.digest('SHA-256',buf);return[...new Uint8Array(h)].map(b=>b.toString(16).padStart(2,'0')).join('')}
function render(){ if(!meta){info.textContent='';btn.disabled=true;return;}
  info.innerHTML=`Arquivo: <code>${meta.target}</code><br>SHA-256: <code>${meta.sha256}</code><br>Tamanho: <code>${meta.size}</code> bytes<br>MIME: <code>${meta.mime||'application/octet-stream'}</code>`;
  btn.disabled=false;}
async function handle(f){ if(!f) return; const buf=await f.arrayBuffer(); const sha=await sha256Hex(buf);
  meta={version:'teia.public.v1',target:f.name,sha256:sha,mime:f.type||'application/octet-stream',size:f.size,created:new Date().toISOString()}; render();}
document.addEventListener('dragover',e=>e.preventDefault());
document.addEventListener('drop',e=>{e.preventDefault();handle(e.dataTransfer.files[0]);});
inp.addEventListener('change',e=>handle(e.target.files[0]));
btn.addEventListener('click',()=>{const blob=new Blob([JSON.stringify(meta,null,2)],{type:'application/json'});
  const a=document.createElement('a'); a.href=URL.createObjectURL(blob); a.download=`${meta.target}.teia.json`; a.click(); URL.revokeObjectURL(a.href);});
</script></body></html>
'@
Set-Content -LiteralPath .\compressor_gemini.html -Value $comp -Encoding UTF8

# 2) Recriar index.html simples que aponta para o compressor
$idx = @'
<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"/>
<title>TEIA Seed Dashboard Local</title><meta name="viewport" content="width=device-width,initial-scale=1"/>
<style>body{background:#0b0f14;color:#e8f0ff;font-family:system-ui,Segoe UI,Roboto,Arial,sans-serif;margin:0}
.main{max-width:900px;margin:40px auto;padding:16px}</style></head>
<body><div class="main"><h2>TEIA Seed Dashboard Local</h2>
<p>Capa carregada. Use <a href="./compressor_gemini.html">compressor_gemini.html</a> para gerar seeds (.teia.json).</p>
</div></body></html>
'@
Set-Content -LiteralPath .\index.html -Value $idx -Encoding UTF8

# 3) Abrir e verificar
Get-Content .\compressor_gemini.html -TotalCount 1
Start-Process .\compressor_gemini.html
```

Depois: gere a seed, mova para `.\gemini_out\` (ou deixe o watcher fazer isso) e confira o log:
```powershell
Get-Content .\logs\gemini_adapter.log -Tail 20
```

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000666c6230a0f64105ba62ba15', 'size_bytes': 279626, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Bora fechar isso agora com um “escreve-valida-abre” à prova de cache/clipboard.

### 1) Recriar os 2 HTMLs (sem depender do clipboard)
Cole e rode **exatamente**:

```powershell
# compressor_gemini.html
Set-Content -LiteralPath .\compressor_gemini.html -Encoding UTF8 -Value @'
<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"/>
<title>TEIA Compressor Local</title><meta name="viewport" content="width=device-width,initial-scale=1"/>
<style>
:root{--bg:#0b0f14;--fg:#e8f0ff;--muted:#9fb3c8}
html,body{height:100%;background:var(--bg);color:var(--fg);font-family:system-ui,Segoe UI,Roboto,Arial,sans-serif;margin:0}
.container{max-width:1000px;margin:40px auto;padding:16px}
.drop{border:2px dashed #2a3b4f;border-radius:12px;padding:32px;text-align:center}
.btn{background:#1e293b;border:1px solid #2a3b4f;padding:10px 16px;border-radius:10px;color:var(--fg);cursor:pointer}
.kv{margin-top:14px}.kv code{background:#13202e;padding:2px 6px;border-radius:6px}
</style></head><body>
<div class="container"><h2>TEIA Compressor Local</h2>
<div class="drop">
  <p>Solte um arquivo aqui ou <input id="file" type="file"></p>
  <div id="info" class="kv"></div>
  <button id="dl" class="btn" disabled>Baixar seed .teia.json</button>
</div></div>
<script>
const $=s=>document.querySelector(s);const info=$("#info"),inp=$("#file"),btn=$("#dl");let meta=null;
async function sha256Hex(buf){const h=await crypto.subtle.digest('SHA-256',buf);return[...new Uint8Array(h)].map(b=>b.toString(16).padStart(2,'0')).join('')}
function render(){ if(!meta){info.textContent='';btn.disabled=true;return;}
  info.innerHTML=`Arquivo: <code>${meta.target}</code><br>SHA-256: <code>${meta.sha256}</code><br>Tamanho: <code>${meta.size}</code> bytes<br>MIME: <code>${meta.mime||'application/octet-stream'}</code>`;
  btn.disabled=false;}
async function handle(f){ if(!f) return; const buf=await f.arrayBuffer(); const sha=await sha256Hex(buf);
  meta={version:'teia.public.v1',target:f.name,sha256:sha,mime:f.type||'application/octet-stream',size:f.size,created:new Date().toISOString()}; render();}
document.addEventListener('dragover',e=>e.preventDefault());
document.addEventListener('drop',e=>{e.preventDefault();handle(e.dataTransfer.files[0]);});
inp.addEventListener('change',e=>handle(e.target.files[0]));
btn.addEventListener('click',()=>{const blob=new Blob([JSON.stringify(meta,null,2)],{type:'application/json'});
  const a=document.createElement('a'); a.href=URL.createObjectURL(blob); a.download=`${meta.target}.teia.json`; a.click(); URL.revokeObjectURL(a.href);});
</script></body></html>
'@

# index.html (linka o compressor)
Set-Content -LiteralPath .\index.html -Encoding UTF8 -Value @'
<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"/>
<title>TEIA Seed Dashboard Local</title><meta name="viewport" content="width=device-width,initial-scale=1"/>
<style>body{background:#0b0f14;color:#e8f0ff;font-family:system-ui,Segoe UI,Roboto,Arial,sans-serif;margin:0}.main{max-width:900px;margin:40px auto;padding:16px}</style></head>
<body><div class="main"><h2>TEIA Seed Dashboard Local</h2>
<p>Capa carregada. Use <a href="./compressor_gemini.html">compressor_gemini.html</a> para gerar seeds (.teia.json).</p>
</div></body></html>
'@
```

### 2) Validar e abrir
```powershell
Select-String .\compressor_gemini.html -Pattern '<title>TEIA Compressor Local' | Select-Object -First 1
Start-Process .\compressor_gemini.html   # (Ctrl+F5 se vier em branco)
```

### 3) Fluxo
- Solte/Escolha um arquivo → **Baixar seed .teia.json**.
- Com watcher ligado, o .teia.json do *Downloads* vai para `.\\gemini_out\\`, o adapter normaliza em `.\\seeds\\` e restaura (via índice) em `.\\restored\\`.
- Conferir:
```powershell
Get-Content .\logs\gemini_adapter.log -Tail 20
```

Se ainda ver “página em branco”, abra `notepad .\compressor_gemini.html` e confirme que começa com `<!doctype html>` e contém o título **TEIA Compressor Local**.

---

### USUÁRIO

não rodei o sugerido acima porque o problema é que havia várias watches abertos em abas pws, solução sugerida, todo prompt de abrir um novo dashboard inclui fechar abas

---

### ASSISTENTE

Perfeito — então padroniza assim: **sempre** fechar watchers antes de abrir a capa/compres­sor.

### Fechar todos os watchers (1ª coisa)
```powershell
# Mata qualquer pwsh rodando os watchers
$pat = 'Watch-GeminiFolder.ps1|Watch-Downloads.ps1'
Get-CimInstance Win32_Process -Filter "Name='pwsh.exe'" |
  ? { $_.CommandLine -match $pat } |
  % { Stop-Process -Id $_.ProcessId -Force }

# (opcional, para Windows PowerShell clássico)
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
  ? { $_.CommandLine -match $pat } |
  % { Stop-Process -Id $_.ProcessId -Force }
```

### Abrir “limpo”
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
Start-Process pwsh -ArgumentList '-NoProfile','-File','.\\Watch-GeminiFolder.ps1'
Start-Process pwsh -ArgumentList '-NoProfile','-File','.\\Watch-Downloads.ps1'
Start-Process .\index.html    # da capa você vai ao compressor
```

### (Opcional) Evitar duplicatas dentro do script
Adicione no topo de **Watch-GeminiFolder.ps1** e **Watch-Downloads.ps1**:
```powershell
$mx = New-Object System.Threading.Mutex($false, "Global\TEIA_$($MyInvocation.MyCommand.Name)", [ref]$new)
if(-not $new){ Write-Host "Já existe um watcher rodando. Saindo."; exit }
```

Com isso, qualquer prompt que “abra o dashboard” começa chamando o bloco **Fechar todos os watchers**.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000ba3c6230a95afc312cc21265', 'size_bytes': 269175, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Top! Os watchers foram reiniciados com proteção de instância única.  
Agora valide o ciclo ponta-a-ponta rapidinho:

### 1) Abrir compressor e gerar seed
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
Start-Process .\compressor_gemini.html
```
(baixe a **.teia.json** no navegador; o Watch-Downloads move para `.\\gemini_out`, o adapter normaliza e tenta restaurar.)

### 2) Conferir log + restauração
```powershell
# log do adapter
Get-Content .\logs\gemini_adapter.log -Tail 20

# checar último seed e integridade do arquivo restaurado
$seed = Get-ChildItem .\seeds\*.teia.json | Sort LastWriteTime -Desc | Select -First 1
$j = Get-Content $seed -Raw | ConvertFrom-Json
$rest = ".\restored\$($j.target)"
@( "Restaurado: " + (Test-Path $rest),
   "SHA OK: " + (((Get-FileHash $rest -Algorithm SHA256).Hash.ToLower()) -eq $j.sha256) )
```

### 3) (Opcional) impedir duplicatas de novo, sempre que for abrir o dashboard
```powershell
# fecha watchers antes de abrir
$pat='Watch-GeminiFolder.ps1|Watch-Downloads.ps1'
Get-CimInstance Win32_Process -Filter "Name='pwsh.exe'" |
 ?{ $_.CommandLine -match $pat } | % { Stop-Process -Id $_.ProcessId -Force }

Start-Process pwsh -ArgumentList '-NoProfile','-File','.\\Watch-GeminiFolder.ps1' -WindowStyle Minimized
Start-Process pwsh -ArgumentList '-NoProfile','-File','.\\Watch-Downloads.ps1'  -WindowStyle Minimized
Start-Process .\index.html
```

Se quiser, deixo em um `Open-TEIA.ps1` único (fecha watchers → inicia watchers → abre `index.html`).

---

### USUÁRIO

acredito que o codex já testou, poréma a aba abre em branco

---

### ASSISTENTE

A aba “em branco” é porque o arquivo HTML foi sobrescrito com **texto** (instruções) — não com HTML. Regrave os **dois** arquivos a partir do canvas e valide.

### 1) Feche watchers duplicados
```powershell
$pat='Watch-GeminiFolder.ps1|Watch-Downloads.ps1'
Get-CimInstance Win32_Process -Filter "Name='pwsh.exe'" |
 ?{ $_.CommandLine -match $pat } | % { Stop-Process -Id $_.ProcessId -Force }
```

### 2) Regravar **index.html** (capa) do clipboard
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch 'TEIA .*(Dashboard|Seed)'){
  throw "Clipboard não é a capa. Copie do canvas e repita."
}
Set-Content -LiteralPath .\index.html -Value $html -Encoding UTF8
(Get-Content .\index.html -TotalCount 1)
```

### 3) Regravar **compressor_gemini.html** do clipboard
```powershell
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch '(TEIA|Compressor)'){
  throw "Clipboard não é o compressor. Copie do canvas e repita."
}
Set-Content -LiteralPath .\compressor_gemini.html -Value $html -Encoding UTF8
(Get-Content .\compressor_gemini.html -TotalCount 1)
```

### 4) Subir watchers (uma instância) e abrir a capa
```powershell
Start-Process pwsh -ArgumentList '-NoProfile','-File','.\\Watch-GeminiFolder.ps1' -WindowStyle Minimized
Start-Process pwsh -ArgumentList '-NoProfile','-File','.\\Watch-Downloads.ps1'  -WindowStyle Minimized
Start-Process .\index.html
```

### 5) Fluxo
- Abra `compressor_gemini.html`, gere a seed e baixe.  
- O `Watch-Downloads.ps1` move para `.\gemini_out`, o adapter normaliza/restaura.  
- Confirme:
```powershell
Get-Content .\logs\gemini_adapter.log -Tail 20
```

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_000000001bcc6230982222c778d8fafd', 'size_bytes': 341531, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Você abriu **index.html** com TEXTO (instruções) — não HTML. Vamos repor **os 2 HTMLs reais** direto (sem clipboard) e testar.

### 1) Repor os arquivos HTML
Cole e rode **exatamente** no PowerShell:

```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano

# index.html (capa)
Set-Content -LiteralPath .\index.html -Encoding UTF8 -Value @'
<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<title>TEIA Seed Dashboard Local</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  body{margin:0;background:#0b0f14;color:#e6edf3;font:16px/1.5 system-ui,Segoe UI,Roboto,Arial,sans-serif}
  main{max-width:960px;margin:48px auto;padding:16px}
  a{color:#7dd3fc}
</style>
</head>
<body>
  <main>
    <h2>TEIA Seed Dashboard Local</h2>
    <p>Capa carregada. Use <a href="./compressor_gemini.html">compressor_gemini.html</a> para gerar seeds.</p>
  </main>
</body>
</html>
'@

# compressor_gemini.html
Set-Content -LiteralPath .\compressor_gemini.html -Encoding UTF8 -Value @'
<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<title>TEIA Compressor Local</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  :root{--bg:#0b0f14;--fg:#e6edf3;--box:#111827;--accent:#10b981}
  body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.5 system-ui,Segoe UI,Roboto,Arial,sans-serif}
  main{max-width:980px;margin:40px auto;padding:16px}
  .drop{border:2px dashed #334155;border-radius:12px;padding:36px;text-align:center;background:var(--box)}
  .btn{display:inline-block;margin-top:16px;padding:10px 14px;border-radius:10px;background:var(--accent);color:#001b16;text-decoration:none;font-weight:600}
  code{background:#0f172a;padding:2px 6px;border-radius:6px}
</style>
</head>
<body>
<main>
  <h2>TEIA Compressor Local</h2>
  <div class="drop" id="drop">
    Solte um arquivo aqui ou <input type="file" id="file" />
  </div>
  <div id="info" style="margin-top:16px"></div>
  <a id="dl" class="btn" style="display:none">Baixar seed .teia.json</a>
</main>
<script>
const $ = s => document.querySelector(s);
const toHex = buf => Array.from(new Uint8Array(buf)).map(b=>b.toString(16).padStart(2,'0')).join('');
async function makeSeed(file){
  const buf = await file.arrayBuffer();
  const sha = await crypto.subtle.digest('SHA-256', buf);
  const seed = {
    target: file.name,
    sha256: toHex(sha),
    mime: file.type || 'application/octet-stream',
    size: file.size,
    created: new Date().toISOString(),
    version: 'teia.public.v1'
  };
  const j = JSON.stringify(seed,null,2);
  const blob = new Blob([j],{type:'application/json'});
  const a = $('#dl');
  a.href = URL.createObjectURL(blob);
  a.download = file.name + '.teia.json';
  a.style.display = 'inline-block';
  $('#info').innerHTML =
    `Arquivo: <code>${seed.target}</code><br>SHA-256: <code>${seed.sha256}</code><br>Tamanho: <code>${seed.size}</code> bytes<br>MIME: <code>${seed.mime}</code>`;
}
$('#file').addEventListener('change', e => e.target.files[0] && makeSeed(e.target.files[0]));
const box = $('#drop');
box.addEventListener('dragover', e => { e.preventDefault(); box.style.opacity=.9; });
box.addEventListener('dragleave',()=> box.style.opacity=1);
box.addEventListener('drop', e => { e.preventDefault(); box.style.opacity=1; const f = e.dataTransfer.files[0]; if(f) makeSeed(f); });
</script>
</body>
</html>
'@
```

### 2) Abrir e validar
```powershell
Start-Process .\index.html
Get-Content .\index.html -TotalCount 1
Get-Content .\compressor_gemini.html -TotalCount 1
```
A primeira linha de cada um deve ser `<!doctype html>`.

### 3) Rodar fluxo
- Abra `compressor_gemini.html`, escolha um arquivo, clique **Baixar seed .teia.json**.
- Deixe seus watchers ligados; o `.teia.json` cairá no *Downloads*, o `Watch-Downloads.ps1` move para `.\gemini_out`, o adapter normaliza e (se índice existir) restaura em `.\restored\`.
- Conferir:
```powershell
Get-Content .\logs\gemini_adapter.log -Tail 20
```

*(Opcional)* Proteção contra sobrescrita acidental:
```powershell
attrib +R .\index.html,.\compressor_gemini.html
```

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000a00062309b5a66c303de0df1', 'size_bytes': 254155, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Parece que o **index.html** ainda está vazio/“texto” e o navegador abre em branco. Vamos checar e forçar o rewrite direto no disco (sem clipboard) e validar.

1) Feche watchers duplicados (só por garantia)
```powershell
Get-CimInstance Win32_Process -Filter "Name='pwsh.exe'" |
  ? { $_.CommandLine -match 'Watch-(GeminiFolder|Downloads)\.ps1' } |
  % { Stop-Process -Id $_.ProcessId -Force }
```

2) Verifique tamanho e primeiras linhas
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
Get-Item .\index.html,.\compressor_gemini.html | Select Name,Length,LastWriteTime
Get-Content .\index.html -TotalCount 5
```
Se **Length = 0** ou aparecer texto de instrução, regrave.

3) Teste de fumaça (garante renderização)
```powershell
Set-Content .\index.html '<!doctype html><meta charset="utf-8"><title>TEST INDEX</title><body style="background:#111;color:#eee;font:16px system-ui"><h1>INDEX OK</h1><a href="./compressor_gemini.html">Abrir compressor</a>'
Start-Process .\index.html
```
Se aparecer “INDEX OK”, regrave o **HTML completo**:

```powershell
attrib -R .\index.html -ErrorAction SilentlyContinue

Set-Content -LiteralPath .\index.html -Encoding UTF8 -Value @'
<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8">
<title>TEIA Seed Dashboard Local</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>body{margin:0;background:#0b0f14;color:#e6edf3;font:16px/1.5 system-ui,Segoe UI,Roboto,Arial,sans-serif}main{max-width:960px;margin:48px auto;padding:16px}a{color:#7dd3fc}</style>
</head><body><main>
<h2>TEIA Seed Dashboard Local</h2>
<p>Capa carregada. Use <a href="./compressor_gemini.html">compressor_gemini.html</a> para gerar seeds.</p>
</main></body></html>
'@

attrib +R .\index.html
Start-Process .\index.html
```

4) Se quiser, regrave também o compressor (caso tenha sido sobrescrito):
```powershell
attrib -R .\compressor_gemini.html -ErrorAction SilentlyContinue
Set-Content -LiteralPath .\compressor_gemini.html -Encoding UTF8 -Value @'
<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">
<title>TEIA Compressor Local</title><meta name="viewport" content="width=device-width,initial-scale=1">
<style>:root{--bg:#0b0f14;--fg:#e6edf3;--box:#111827;--accent:#10b981}body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.5 system-ui,Segoe UI,Roboto,Arial,sans-serif}main{max-width:980px;margin:40px auto;padding:16px}.drop{border:2px dashed #334155;border-radius:12px;padding:36px;text-align:center;background:var(--box)}.btn{display:inline-block;margin-top:16px;padding:10px 14px;border-radius:10px;background:var(--accent);color:#001b16;text-decoration:none;font-weight:600}code{background:#0f172a;padding:2px 6px;border-radius:6px}</style>
</head><body><main>
<h2>TEIA Compressor Local</h2>
<div class="drop" id="drop">Solte um arquivo aqui ou <input type="file" id="file" /></div>
<div id="info" style="margin-top:16px"></div>
<a id="dl" class="btn" style="display:none">Baixar seed .teia.json</a>
</main>
<script>
const $=s=>document.querySelector(s),toHex=b=>Array.from(new Uint8Array(b)).map(x=>x.toString(16).padStart(2,'0')).join('');
async function makeSeed(f){const buf=await f.arrayBuffer();const sha=await crypto.subtle.digest('SHA-256',buf);
const seed={target:f.name,sha256:toHex(sha),mime:f.type||'application/octet-stream',size:f.size,created:new Date().toISOString(),version:'teia.public.v1'};
const j=JSON.stringify(seed,null,2),blob=new Blob([j],{type:'application/json'}),a=$('#dl');a.href=URL.createObjectURL(blob);a.download=f.name+'.teia.json';a.style.display='inline-block';
$('#info').innerHTML=`Arquivo: <code>${seed.target}</code><br>SHA-256: <code>${seed.sha256}</code><br>Tamanho: <code>${seed.size}</code> bytes<br>MIME: <code>${seed.mime}</code>`;}
$('#file').addEventListener('change',e=>e.target.files[0]&&makeSeed(e.target.files[0]));
const box=$('#drop');box.addEventListener('dragover',e=>{e.preventDefault();box.style.opacity=.9});box.addEventListener('dragleave',()=>box.style.opacity=1);
box.addEventListener('drop',e=>{e.preventDefault();box.style.opacity=1;const f=e.dataTransfer.files[0];if(f) makeSeed(f);});
</script></body></html>
'@
attrib +R .\compressor_gemini.html
Start-Process .\compressor_gemini.html
```

Se ainda abrir em branco, verifique imediatamente o **tamanho do arquivo** após abrir:
```powershell
Get-Item .\index.html | Select Name,Length,LastWriteTime
```
- Se o tamanho voltou a 0/pequeno, algum script está sobrescrevendo. Deixe `attrib +R` e **não** rode `Save-Gemini-Dashboard.ps1`.  
- Se o tamanho está OK, force recarregar no navegador com **Ctrl+F5** ou abra `index.html?ts=$(Get-Date -UFormat %s)`.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000a3a06230bf9dc8c9f288d964', 'size_bytes': 285168, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Abrir “em branco” = HTML errado (texto/instruções) ou cache. Bora consertar em modo **limpo**:

### 0) Feche watchers/abas duplicadas
```powershell
$pat='Watch-GeminiFolder.ps1|Watch-Downloads.ps1'
Get-CimInstance Win32_Process -Filter "Name='pwsh.exe'" |
  ?{ $_.CommandLine -match $pat } | % { Stop-Process -Id $_.ProcessId -Force }
```

### 1) Regravar **compressor_gemini.html** (copie o HTML real do canvas antes: Ctrl+A, Ctrl+C)
```powershell
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch '(TEIA|Compressor)'){
  throw "Clipboard não é o compressor."
}
Set-Content .\compressor_gemini.html -Value $html -Encoding UTF8
```

### 2) Regravar **index.html** (agora copie a **capa** do canvas)
```powershell
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch 'TEIA .*(Dashboard|Seed)'){
  throw "Clipboard não é a capa."
}
Set-Content .\index.html -Value $html -Encoding UTF8
```

### 3) Verificar rápido
```powershell
Get-Item .\index.html,.\compressor_gemini.html | Select Name,Length
Get-Content .\index.html -TotalCount 1
Get-Content .\compressor_gemini.html -TotalCount 1
# Se aparecer “pwsh -NoProfile” ou “Get-Clipboard” dentro do arquivo, você salvou instruções: regrave.
Select-String .\*.html -Pattern 'pwsh -NoProfile|Get-Clipboard' -SimpleMatch
```

### 4) Proteger contra sobrescrita acidental
```powershell
attrib +R .\index.html .\compressor_gemini.html
```

### 5) Abrir “limpo” (sem cache/duplicatas)
- Feche as abas antigas do navegador.
- Abra de novo:
```powershell
Start-Process .\index.html
Start-Process .\compressor_gemini.html
```
- Se ainda “em branco”: **Ctrl+F5** ou abra em janela InPrivate.

Depois, ligue **um** watcher só e gere a seed no compressor:
```powershell
pwsh -NoProfile -File .\Watch-GeminiFolder.ps1   # (ou Watch-Downloads.ps1, mas não ambos)
```

Isso resolve as abas em branco e previne sobrescrita pelos trechos de instrução.

---

### USUÁRIO

• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference='"'Stop';
    # 1) Fechar watchers duplicados (tolerante a falhas)
    try {
      Get-CimInstance Win32_Process -Filter \"Name='pwsh.exe'\" |
        Where-Object { "'$_.CommandLine -match '"'Watch-(GeminiFolder|Downloads)\\.ps1' } |
        ForEach-Object { Stop-Process -Id "'$_.ProcessId -Force -ErrorAction Stop }
      Write-Host "[OK] Watchers pwsh encerrados"
    } catch { Write-Host "[WARN] Não foi possível encerrar watchers via CIM (pwsh): $($_.Exception.Message)" }

    # 2) Verificar tamanho e primeiras linhas
    Set-Location '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'
    Get-Item .\\index.html, .\\compressor_gemini.html | Select-Object Name,Length,LastWriteTime
    Get-Content .\\index.html -TotalCount 5

    # 3) Teste de fumaça do index
    cmd /c attrib -R .\\index.html 2>"'$null | Out-Null
    Set-Content .'"\\index.html '<"'!doctype html><meta charset="utf-8"><title>TEST
        INDEX<title><body style="background:#111;color:#eee;font:16px system-ui"><h1>INDEX OK<h1><a
        href=".compressor_gemini.html">Abrir compressor<a>'"'
    Start-Process .\\index.html | Out-Null
    Write-Host \"[OK] Smoke test INDEX OK aberto\"

    # 4) Regravar index completo (forçado, sem clipboard)
    Set-Content -LiteralPath .\\index.html -Encoding UTF8 -Value @'
    <"'!doctype html>
    <html lang="pt-BR"><head><meta charset="utf-8">
    <title>TEIA Seed Dashboard Local<title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <style>body{margin:0;background:#0b0f14;color:#e6edf3;font:16px1.5 system-ui,Segoe UI,Roboto,Arial,sans-serif}
        main{max-width:960px;margin:48px auto;padding:16px}a{color:#7dd3fc}<style>
    <head><body><main>
    <h2>TEIA Seed Dashboard Local<h2>
    <p>Capa carregada. Use <a href=".compressor_gemini.html">compressor_gemini.html<a> para gerar seeds.<p>
    <main><body><html>
    '"'@
    cmd /c attrib +R .\\index.html | Out-Null
    Start-Process .\\index.html | Out-Null
    Write-Host \"[OK] index.html regravado e protegido (ReadOnly)\"

    # 5) Regravar compressor (forçado) e proteger
    cmd /c attrib -R .\\compressor_gemini.html 2>"'$null | Out-Null
    Set-Content -LiteralPath .'"\\compressor_gemini.html -Encoding UTF8 -Value @'
    <"'!doctype html><html lang="pt-BR"><head><meta charset="utf-8">
    <title>TEIA Compressor Local<title><meta name="viewport" content="width=device-width,initial-scale=1">
    <style>:root{--bg:#0b0f14;--fg:#e6edf3;--box:#111827;--accent:#10b981}
        body{margin:0;background:var(--bg);color:var(--fg);font:16px1.5 system-ui,Segoe
        UI,Roboto,Arial,sans-serif}main{max-width:980px;margin:40px auto;padding:16px}.drop{border:2px dashed
        #334155;border-radius:12px;padding:36px;text-align:center;background:var(--box)}.btn{display:inline-block;mar
        gin-top:16px;padding:10px
        14px;border-radius:10px;background:var(--accent);color:#001b16;text-decoration:none;font-weight:600}
        code{background:#0f172a;padding:2px 6px;border-radius:6px}<style>
    <head><body><main>

  - Watchers: encerrados os processos pwsh com “Watch-GeminiFolder/Watch-Downloads”.
  - Smoke test: index abriu com “INDEX OK” antes da regravação completa.
  - index.html: regravado e protegido, primeira linha .
  - compressor_gemini.html: regravado e protegido, primeira linha .
  - Tamanhos atuais:
      - index.html: ~534–562 bytes
> Closing watchers, rewriting both HTMLs from clipboard with validation, verifying size/first lines, protecting, and
  opening clean.

• Ran
  └ pwsh -NoProfile -Command '$ErrorActionPreference='"'Stop';
    # 0) Fechar watchers/abas duplicadas
    "'$pat='"'Watch-GeminiFolder.ps1|Watch-Downloads.ps1'
    try {
      Get-CimInstance Win32_Process -Filter \"Name='pwsh.exe'\" |
        Where-Object { "'$_.CommandLine -match $pat } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop }
      Write-Host '"'[OK] Watchers pwsh encerrados'
    } catch { Write-Host \"[WARN] Fechamento de watchers falhou: "'$($_.Exception.Message)" }

    # 1) Regravar compressor_gemini.html do clipboard (validação)
    Set-Location '"'D:\\Teia\\TEIA_NUCLEO\\offline\\nano'
    try {
      "'$html = Get-Clipboard -Raw
      if($html -notmatch '"'<"'!DOCTYPE html>'"' -or "'$html -notmatch '"'(TEIA|Compressor)'){
        throw 'Clipboard não é o compressor.'
      }
      Set-Content .\\compressor_gemini.html -Value "'$html -Encoding UTF8
      Write-Host '"'[OK] compressor_gemini.html regravado do clipboard'
    } catch { Write-Host \"[Compressor] ERR: "'$($_.Exception.Message)" }

    # 2) Regravar index.html do clipboard (validação)
    try {
      $html = Get-Clipboard -Raw
      if($html -notmatch '"'<"'!DOCTYPE html>'"' -or "'$html -notmatch '"'TEIA .*(Dashboard|Seed)'){
        throw 'Clipboard não é a capa.'
      }
      Set-Content .\\index.html -Value "'$html -Encoding UTF8
      Write-Host '"'[OK] index.html regravado do clipboard'
    } catch { Write-Host \"[Index] ERR: "'$($_.Exception.Message)" }

    # 3) Verificar rápido
    Get-Item .'"\\index.html, .\\compressor_gemini.html | Select-Object Name,Length
    Get-Content .\\index.html -TotalCount 1
    Get-Content .\\compressor_gemini.html -TotalCount 1
    Select-String .\\*.html -Pattern 'pwsh -NoProfile|Get-Clipboard' -SimpleMatch -ErrorAction SilentlyContinue |
        Select-Object -First 5

    # 4) Proteger contra sobrescrita acidental
    cmd /c attrib +R .\\index.html .\\compressor_gemini.html | Out-Null
    Write-Host '[OK] ReadOnly aplicado em index.html e compressor_gemini.html'

    # 5) Abrir limpo
    Write-Host '[OK] Abrindo capa e compressor (feche abas antigas antes)'
    Start-Process .\\index.html | Out-Null
    Start-Process .\\compressor_gemini.html | Out-Null
    "

> Attempted to close watchers and rewrite both HTMLs from clipboard with validation, then verify and open them, but
  the PowerShell command failed to run in this environment. Please run the exact sequence below in your PowerShell
  window after copying the real HTML from the canvas for each page.

  Commands to run

  - Close watchers
      - $pat='Watch-GeminiFolder.ps1|Watch-Downloads.ps1'
      - Get-CimInstance Win32_Process -Filter "Name='pwsh.exe'" | Where-Object { $.CommandLine -match $pat } |
  ForEach-Object { Stop-Process -Id $.ProcessId -Force }
  - Rewrite compressor from clipboard
      - cd D:\Teia\TEIA_NUCLEO\offline\nano
      - $html = Get-Clipboard -Raw
      - if($html -notmatch '' -or $html -notmatch '(TEIA|Compressor)'){ throw "Clipboard não é o compressor." }
      - Set-Content .\compressor_gemini.html -Value $html -Encoding UTF8
  - Rewrite index from clipboard
      - $html = Get-Clipboard -Raw
      - if($html -notmatch '' -or $html -notmatch 'TEIA .*(Dashboard|Seed)'){ throw "Clipboard não é a capa." }
      - Set-Content .\index.html -Value $html -Encoding UTF8
  - Quick check
      - Get-Item .\index.html,.\compressor_gemini.html | Select Name,Length
      - Get-Content .\index.html -TotalCount 1
      - Get-Content .\compressor_gemini.html -TotalCount 1
      - Select-String .*.html -Pattern 'pwsh -NoProfile|Get-Clipboard' -SimpleMatch
  - Protect against accidental overwrite
      - attrib +R .\index.html .\compressor_gemini.html
  - Open clean
      - Close old browser tabs first
      - Start-Process .\index.html
      - Start-Process .\compressor_gemini.html

  If any validation step fails, it means the clipboard doesn’t have the real HTML from the canvas. Copy again from
  the preview (Ctrl+A, Ctrl+C) and rerun the respective block.

---

### ASSISTENTE

Isso é “arquivo salvo com instruções, não HTML”. Conserta já e evita duplicatas:

### Fechar watchers/abas e abrir limpo
```powershell
# Pare watchers pwsh duplicados
$pat='Watch-(GeminiFolder|Downloads)\.ps1'
Get-CimInstance Win32_Process -Filter "Name='pwsh.exe'" |
  ?{ $_.CommandLine -match $pat } | % { Stop-Process -Id $_.ProcessId -Force }
```

### Regravar **index.html** (capa real do canvas)
```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
attrib -R .\index.html 2>$null
$h = Get-Clipboard -Raw
if($h -notmatch '<!DOCTYPE html>' -or $h -notmatch 'TEIA .*(Dashboard|Seed)'){ throw "Clipboard não é a capa." }
Set-Content .\index.html -Value $h -Encoding UTF8
attrib +R .\index.html
```

### Regravar **compressor_gemini.html** (HTML real do compressor)
```powershell
attrib -R .\compressor_gemini.html 2>$null
$h = Get-Clipboard -Raw
if($h -notmatch '<!DOCTYPE html>' -or $h -notmatch '(TEIA|Compressor)'){ throw "Clipboard não é o compressor." }
Set-Content .\compressor_gemini.html -Value $h -Encoding UTF8
attrib +R .\compressor_gemini.html
```

### Verificar e abrir
```powershell
Get-Item .\index.html,.\compressor_gemini.html | Select Name,Length
Select-String .\*.html -Pattern 'pwsh -NoProfile|Get-Clipboard' -SimpleMatch  # deve NÃO achar nada
Start-Process .\index.html
Start-Process .\compressor_gemini.html   # se “em branco”, Ctrl+F5 ou janela InPrivate
```

### Guard de instância única (adicione no topo dos dois watchers)
```powershell
$mx = New-Object System.Threading.Mutex($false,"Global\TEIA_$($MyInvocation.MyCommand.Name)")
if(-not $mx.WaitOne(0,$false)){ Write-Host "Watcher já em execução. Saindo."; exit }
```

Se algum `Select-String` achar “pwsh -NoProfile”/“Get-Clipboard” dentro dos `.html`, é texto de instrução: copie de novo do *preview do canvas* (Ctrl+A, Ctrl+C) e regrave.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_0000000092046230849b41c1d7069e15', 'size_bytes': 357651, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

A página está “em branco” porque **o compressor foi sobrescrito com texto de instruções** (não HTML). Reponho os **dois HTMLs válidos** abaixo—copie e rode exatamente esse bloco no PowerShell:

```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano
attrib -R .\index.html .\compressor_gemini.html 2>$null

@'
<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>TEIA Seed Dashboard Local</title>
<style>body{margin:0;background:#0b0f14;color:#e6edf3;font:16px/1.5 system-ui,Segoe UI,Roboto,Arial,sans-serif}main{max-width:960px;margin:48px auto;padding:16px}a{color:#7dd3fc}</style></head>
<body><main>
<h2>TEIA Seed Dashboard Local</h2>
<p>Capa carregada. Abra o <a href="./compressor_gemini.html">compressor_gemini.html</a> para gerar seeds (.teia.json).</p>
</main></body></html>
'@ | Set-Content -LiteralPath .\index.html -Encoding UTF8

@'
<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>TEIA Compressor Local</title>
<style>body{margin:0;background:#0b0f14;color:#e6edf3;font:16px/1.5 system-ui,Segoe UI,Roboto,Arial,sans-serif}main{max-width:980px;margin:40px auto;padding:16px}.drop{border:2px dashed #334155;border-radius:12px;padding:36px;text-align:center;background:#111827}.btn{display:inline-block;margin-top:16px;padding:10px 14px;border-radius:10px;background:#10b981;color:#001b16;text-decoration:none;font-weight:600}code{background:#0f172a;padding:2px 6px;border-radius:6px}</style></head>
<body><main>
<h2>TEIA Compressor Local</h2>
<div class="drop" id="drop">Solte um arquivo aqui ou <input type="file" id="file"></div>
<div id="info" style="margin-top:16px"></div>
<a class="btn" id="dl" style="display:none">Baixar seed .teia.json</a>
<script>
const $=s=>document.querySelector(s);
const hex=b=>[...new Uint8Array(b)].map(x=>x.toString(16).padStart(2,'0')).join('');
async function makeSeed(f){
  const buf=await f.arrayBuffer();
  const sha=await crypto.subtle.digest('SHA-256',buf);
  const seed={version:'teia.public.v1',target:f.name,sha256:hex(sha),mime:f.type||'application/octet-stream',size:f.size,created:new Date().toISOString()};
  const blob=new Blob([JSON.stringify(seed,null,2)],{type:'application/json'});
  const a=$('#dl'); a.href=URL.createObjectURL(blob); a.download=`${seed.target}.teia.json`; a.style.display='inline-block';
  $('#info').innerHTML=`Arquivo: <code>${seed.target}</code><br>SHA-256: <code>${seed.sha256}</code><br>Tamanho: <code>${seed.size}</code> bytes<br>MIME: <code>${seed.mime}</code>`;
}
$('#file').addEventListener('change',e=>e.target.files[0]&&makeSeed(e.target.files[0]));
const box=$('#drop'); ['dragover','dragleave'].forEach(ev=>box.addEventListener(ev,e=>{e.preventDefault();box.style.opacity=ev==='dragover'?0.9:1;}));
box.addEventListener('drop',e=>{e.preventDefault();box.style.opacity=1;const f=e.dataTransfer.files[0];if(f)makeSeed(f);});
</script>
</main></body></html>
'@ | Set-Content -LiteralPath .\compressor_gemini.html -Encoding UTF8

attrib +R .\index.html .\compressor_gemini.html
Start-Process .\index.html; Start-Process .\compressor_gemini.html
```

Depois: gere a seed no compressor, mova o `.teia.json` para `.\gemini_out\` (ou deixe o Watch-Downloads mover), e confira o tail de `.\logs\gemini_adapter.log -Tail 20`.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_00000000d6bc6230b3304e3a0fd6dc80', 'size_bytes': 295173, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

O erro é só **arquivo com atributo ReadOnly**. Tire o `R`, regrave e (se quiser) volte o `R`.

Cole no PowerShell:

```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano

# 1) Desbloquear (corrige "Access to the path ... is denied")
attrib -R ".\index.html" ".\compressor_gemini.html"

# 2) Regravar os dois HTMLs válidos
@'
<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>TEIA Seed Dashboard Local</title>
<style>body{margin:0;background:#0b0f14;color:#e6edf3;font:16px/1.5 system-ui,Segoe UI,Roboto,Arial,sans-serif}main{max-width:960px;margin:48px auto;padding:16px}a{color:#7dd3fc}</style></head>
<body><main>
<h2>TEIA Seed Dashboard Local</h2>
<p>Capa carregada. Abra o <a href="./compressor_gemini.html">compressor_gemini.html</a> para gerar seeds (.teia.json).</p>
</main></body></html>
'@ | Set-Content -LiteralPath .\index.html -Encoding UTF8

@'
<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>TEIA Compressor Local</title>
<style>body{margin:0;background:#0b0f14;color:#e6edf3;font:16px/1.5 system-ui,Segoe UI,Roboto,Arial,sans-serif}main{max-width:980px;margin:40px auto;padding:16px}.drop{border:2px dashed #334155;border-radius:12px;padding:36px;text-align:center;background:#111827}.btn{display:inline-block;margin-top:16px;padding:10px 14px;border-radius:10px;background:#10b981;color:#001b16;text-decoration:none;font-weight:600}code{background:#0f172a;padding:2px 6px;border-radius:6px}</style></head>
<body><main>
<h2>TEIA Compressor Local</h2>
<div class="drop" id="drop">Solte um arquivo aqui ou <input type="file" id="file"></div>
<div id="info" style="margin-top:16px"></div>
<a class="btn" id="dl" style="display:none">Baixar seed .teia.json</a>
<script>
const $=s=>document.querySelector(s);
const hex=b=>[...new Uint8Array(b)].map(x=>x.toString(16).padStart(2,'0')).join('');
async function makeSeed(f){
  const buf=await f.arrayBuffer();
  const sha=await crypto.subtle.digest('SHA-256',buf);
  const seed={version:'teia.public.v1',target:f.name,sha256:hex(sha),mime:f.type||'application/octet-stream',size:f.size,created:new Date().toISOString()};
  const blob=new Blob([JSON.stringify(seed,null,2)],{type:'application/json'});
  const a=$('#dl'); a.href=URL.createObjectURL(blob); a.download=`${seed.target}.teia.json`; a.style.display='inline-block';
  $('#info').innerHTML=`Arquivo: <code>${seed.target}</code><br>SHA-256: <code>${seed.sha256}</code><br>Tamanho: <code>${seed.size}</code> bytes<br>MIME: <code>${seed.mime}</code>`;
}
$('#file').addEventListener('change',e=>e.target.files[0]&&makeSeed(e.target.files[0]));
const box=$('#drop'); ['dragover','dragleave'].forEach(ev=>box.addEventListener(ev,e=>{e.preventDefault();box.style.opacity=ev==='dragover'?0.9:1;}));
box.addEventListener('drop',e=>{e.preventDefault();box.style.opacity=1;const f=e.dataTransfer.files[0];if(f)makeSeed(f);});
</script>
</main></body></html>
'@ | Set-Content -LiteralPath .\compressor_gemini.html -Encoding UTF8

# 3) Verificar e abrir
Get-Item .\index.html,.\compressor_gemini.html | Select Name,Length
Get-Content .\index.html -TotalCount 1
Get-Content .\compressor_gemini.html -TotalCount 1
Start-Process .\index.html; Start-Process .\compressor_gemini.html

# (opcional) Reaplicar proteção contra sobrescrita
attrib +R ".\index.html" ".\compressor_gemini.html"
```

Se ainda der “denied”, feche **abas antigas** do navegador abertas nesses arquivos e repita o bloco a partir do `attrib -R`.

---

### USUÁRIO

>> '@ | Set-Content -LiteralPath .\compressor_gemini.html -Encoding UTF8
Set-Content:
Line |
  27 |  '@ | Set-Content -LiteralPath .\compressor_gemini.html -Encoding UTF8
     |       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Access to the path 'D:\Teia\TEIA_NUCLEO\offline\nano\compressor_gemini.html' is denied.
PS D:\Teia\TEIA_NUCLEO\offline\nano>
PS D:\Teia\TEIA_NUCLEO\offline\nano> # 3) Verificar e abrir
PS D:\Teia\TEIA_NUCLEO\offline\nano> Get-
Get-: The term 'Get-' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
PS D:\Teia\TEIA_NUCLEO\offline\nano>

---

### ASSISTENTE

O arquivo ainda está travado (ReadOnly/ACL/aba aberta). Faça o “desbloqueio total” e regrave:

```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano

# 0) Feche TODAS as abas do navegador abertas em index.html/compressor_gemini.html

# 1) Remover atributos (ReadOnly/Hidden/System) e resetar
attrib -R -S -H ".\index.html" ".\compressor_gemini.html"
$paths = '.\index.html','.\compressor_gemini.html'
foreach($p in $paths){ if(Test-Path $p){ (Get-Item $p).Attributes = [IO.FileAttributes]::Normal } }

# 2) Garantir permissão NTFS para seu usuário
$me = "$env:USERNAME"
icacls ".\index.html" /grant "$me:(F)" /inheritance:e > $null
icacls ".\compressor_gemini.html" /grant "$me:(F)" /inheritance:e > $null
```

Agora regrave (escolha UMA das opções):

**A) Do clipboard (mais simples):**
```powershell
# compressor
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch '(TEIA|Compressor)'){ throw "Clipboard não é o compressor." }
Set-Content -LiteralPath .\compressor_gemini.html -Value $html -Encoding UTF8

# capa
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch 'TEIA .*(Dashboard|Seed)'){ throw "Clipboard não é a capa." }
Set-Content -LiteralPath .\index.html -Value $html -Encoding UTF8
```

**B) Usando os modelos mínimos (caso queira só subir logo):**
```powershell
@'<html><head><meta charset="utf-8"><title>TEIA Seed Dashboard Local</title></head>
<body><h2>TEIA Seed Dashboard Local</h2>
<p>Abra <a href="./compressor_gemini.html">compressor_gemini.html</a>.</p></body></html>'@ |
  Set-Content -LiteralPath .\index.html -Encoding UTF8

@'<html><head><meta charset="utf-8"><title>TEIA Compressor Local</title></head>
<body><input type="file" id="f"><script>
const $=s=>document.querySelector(s),hex=b=>[...new Uint8Array(b)].map(x=>x.toString(16).padStart(2,"0")).join("");
$("#f").addEventListener("change",async e=>{
 const f=e.target.files[0]; if(!f) return;
 const buf=await f.arrayBuffer(), sha=await crypto.subtle.digest("SHA-256",buf);
 const seed={version:"teia.public.v1",target:f.name,sha256:hex(sha),mime:f.type||"application/octet-stream",size:f.size,created:new Date().toISOString()};
 const blob=new Blob([JSON.stringify(seed,null,2)],{type:"application/json"});
 const a=document.createElement("a"); a.href=URL.createObjectURL(blob); a.download=`${seed.target}.teia.json`; a.click();
});
</script></body></html>'@ |
  Set-Content -LiteralPath .\compressor_gemini.html -Encoding UTF8
```

Abra de novo:
```powershell
Start-Process .\index.html
Start-Process .\compressor_gemini.html
```

Se voltar a travar ao editar, foi o atributo `+R` aplicado antes; repita `attrib -R -S -H …` antes de gravar.

---

### USUÁRIO

PS D:\Teia\TEIA_NUCLEO\offline\nano> icacls ".\index.html" /grant "$me:(F)" /inheritance:e > $null
ParserError:
Line |
   1 |  icacls ".\index.html" /grant "$me:(F)" /inheritance:e > $null
     |                                ~~~~
     | Variable reference is not valid. ':' was not followed by a valid variable name character. Consider using ${}
     | to delimit the name.
PS D:\Teia\TEIA_NUCLEO\offline\nano> icacls ".\compressor_gemini.html" /grant "$me:(F)" /inheritance:e > $null
ParserError:
Line |
   1 |  icacls ".\compressor_gemini.html" /grant "$me:(F)" /inheritance:e > $ …
     |                                            ~~~~
     | Variable reference is not valid. ':' was not followed by a valid variable name character. Consider using ${}
     | to delimit the name.
PS D:\Teia\TEIA_NUCLEO\offline\nano>

---

### USUÁRIO

PS D:\Teia\TEIA_NUCLEO\offline\nano>
PS D:\Teia\TEIA_NUCLEO\offline\nano> # 3) Verificar e abrir
PS D:\Teia\TEIA_NUCLEO\offline\nano> Get-
Get-: The term 'Get-' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
PS D:\Teia\TEIA_NUCLEO\offline\nano> cd D:\Teia\TEIA_NUCLEO\offline\nano
PS D:\Teia\TEIA_NUCLEO\offline\nano>
PS D:\Teia\TEIA_NUCLEO\offline\nano> # 0) Feche TODAS as abas do navegador abertas em index.html/compressor_gemini.html
PS D:\Teia\TEIA_NUCLEO\offline\nano>
PS D:\Teia\TEIA_NUCLEO\offline\nano> # 1) Remover atributos (ReadOnly/Hidden/System) e resetar
PS D:\Teia\TEIA_NUCLEO\offline\nano> attrib -R -S -H ".\index.html" ".\compressor_gemini.html"
Formato de parâmetros incorreto -
PS D:\Teia\TEIA_NUCLEO\offline\nano> $paths = '.\index.html','.\compressor_gemini.html'
PS D:\Teia\TEIA_NUCLEO\offline\nano> foreach($p in $paths){ if(Test-Path $p){ (Get-Item $p).Attributes = [IO.FileAttributes]::Normal } }
PS D:\Teia\TEIA_NUCLEO\offline\nano>
PS D:\Teia\TEIA_NUCLEO\offline\nano> # 2) Garantir permissão NTFS para seu usuário
PS D:\Teia\TEIA_NUCLEO\offline\nano> $me = "$env:USERNAME"
PS D:\Teia\TEIA_NUCLEO\offline\nano> icacls ".\index.html" /grant "$me:(F)" /inheritance:e > $null
ParserError:
Line |
   1 |  icacls ".\index.html" /grant "$me:(F)" /inheritance:e > $null
     |                                ~~~~
     | Variable reference is not valid. ':' was not followed by a valid variable name character. Consider using ${}
     | to delimit the name.
PS D:\Teia\TEIA_NUCLEO\offline\nano> icacls ".\compressor_gemini.html" /grant "$me:(F)" /inheritance:e > $null
ParserError:
Line |
   1 |  icacls ".\compressor_gemini.html" /grant "$me:(F)" /inheritance:e > $ …
     |                                            ~~~~
     | Variable reference is not valid. ':' was not followed by a valid variable name character. Consider using ${}
     | to delimit the name.
PS D:\Teia\TEIA_NUCLEO\offline\nano>


---

### ASSISTENTE

Você só tropeçou em 2 pontos:

- `attrib` precisa ir via `cmd /c`.
- Em `icacls`, use `${me}` (ou `${env:USERNAME}`) por causa do `:`.

Rode exatamente isto (com as abas do navegador **fechadas**):

```powershell
cd D:\Teia\TEIA_NUCLEO\offline\nano

# 1) Destravar os HTMLs
cmd /c attrib -R -S -H ".\index.html" ".\compressor_gemini.html"
(Get-Item .\index.html).Attributes = 'Normal'
(Get-Item .\compressor_gemini.html).Attributes = 'Normal'

# 2) Garantir permissão NTFS
$me = $env:USERNAME
icacls ".\index.html" /grant "${me}:(F)" /inheritance:e > $null
icacls ".\compressor_gemini.html" /grant "${me}:(F)" /inheritance:e > $null
```

Regrave a **capa** e o **compressor** (cole o HTML real do canvas antes de cada bloco):

```powershell
# compressor
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch '(TEIA|Compressor)'){ throw "Clipboard não é o compressor." }
Set-Content -LiteralPath .\compressor_gemini.html -Value $html -Encoding UTF8

# capa
$html = Get-Clipboard -Raw
if($html -notmatch '<!DOCTYPE html>' -or $html -notmatch 'TEIA .*(Dashboard|Seed)'){ throw "Clipboard não é a capa." }
Set-Content -LiteralPath .\index.html -Value $html -Encoding UTF8
```

Abrir:

```powershell
Start-Process .\index.html
Start-Process .\compressor_gemini.html
```

Se travar de novo, repita o `cmd /c attrib -R -S -H ...` antes de salvar.

---

### USUÁRIO

{'content_type': 'image_asset_pointer', 'asset_pointer': 'sediment://file_000000005f3861f78e6326163b01129a', 'size_bytes': 284383, 'width': 1920, 'height': 1080, 'fovea': None, 'metadata': {'dalle': None, 'gizmo': None, 'generation': None, 'container_pixel_height': None, 'container_pixel_width': None, 'emu_omit_glimpse_image': None, 'emu_patches_override': None, 'lpe_keep_patch_ijhw': None, 'sanitized': True, 'asset_pointer_link': None, 'watermarked_asset_pointer': None, 'is_no_auth_placeholder': None}}

---

### ASSISTENTE

Aqui vai um “resumo-ponte” direto para o Gemini (curto, denotativo, e suficiente para implementar a UI certa).

# Contexto (offline/nano)
- Pastas: `./gemini_out`, `./seeds`, `./logs`, `./restored`.
- Scripts: `Watch-GeminiFolder.ps1` (ouve `gemini_out`), `Watch-Downloads.ps1` (opcional), `GeminiSeedAdapter.ps1` (normaliza seed e tenta restaurar via `./seeds/teia_anchor_index.json`), `Build-TeiaIndex.ps1`.
- Páginas: `index.html` (dashboard), `compressor_gemini.html` (UI de geração de seed). Criado também `cover_gemini.html` como placeholder visual embutido no index.

# Fluxos funcionais (ok)
- **Comprimir (OK):** usuário solta/seleciona arquivo no *compressor* → JS calcula `sha256`, lê `size/mime/name`, gera JSON `{target, sha256, mime, size, created, version}` e baixa `*.teia.json`. Watcher move para `./gemini_out` → adapter grava normalizado em `./seeds/*.teia.json`.
- **Descomprimir (OK via adapter):** adapter usa `./seeds/teia_anchor_index.json` (mapeia `sha256→path`) e copia o original para `./restored/<target>`. Verificação de integridade **True** já obtida.

# Problema de produto/UX (pendente)
- O **dashboard (index.html)** não é “auto-contido”: falta uma **capa chamativa e intuitiva** com:
  1) **Área integrada de “Gerar seed”** (drag&drop/selecionar, exibição de `nome/sha256/bytes/MIME`, botão **Baixar seed .teia.json**).
  2) **Área integrada de “Restaurar seed”** (informar/soltar um `*.teia.json` apenas para **validar/inspecionar** campos e instruir o usuário a colocar o arquivo em `./gemini_out` — a restauração real é feita pelo adapter/watcher, não no browser).
  3) **Status/atalhos**: link “Abrir compressor”, “Ver log” (`./logs/gemini_adapter.log`), “Abrir pasta gemini_out”.
- Sintoma anterior de “página em branco” veio de HTML sobrescrito com texto; mitigado com regravação correta e `ReadOnly`, mas a **capa integrada** ainda não existe.

# Especificação mínima da **capa integrada** (index.html)
- **Offline, estático, sem bundlers.** Apenas HTML/CSS/JS puros.
- **Seções**:
  - **Hero/Introdução** com título “TEIA Seed Dashboard Local”.
  - **Painel “Gerar seed”**:
    - Dropzone + `<input type="file">`.
    - Mostra `Arquivo`, `SHA-256`, `Tamanho`, `MIME`.
    - Botão “Baixar seed .teia.json” (gera via `Blob`).
    - Implementação: `FileReader` + `crypto.subtle.digest('SHA-256', ArrayBuffer)`; formata SHA em hex minúsculo.
  - **Painel “Restaurar seed” (assistido)**:
    - Dropzone para **carregar/validar** um `.teia.json` (não restaura no browser).
    - Mostra parsed JSON validado (campos obrigatórios: `target, sha256, mime, size, created, version`).
    - CTA: “Mova este arquivo para `./gemini_out/` para o watcher restaurar; acompanhe o log em `./logs/gemini_adapter.log`”.
  - **Links utilitários**: “Abrir compressor”, “Ver log”, “Ajuda rápida”.
- **Validações/UX**:
  - Para seed: validar presença e tipos dos campos; destacar inconsistências (ex.: `size` não numérico).
  - Para arquivo: calcular SHA-256 e exibir tempo de cálculo, prevenir múltiplos arrastos.
- **Estilo**: tema escuro simples (cores já usadas: bg `#0b0f14`, fg `#e6edf3`, box `#111827`, accent `#10b981`), tipografia system-ui, cartões com borda tracejada para dropzone.

# Contratos/tipos de seed (estável)
```json
{
  "target": "<nome.ext>",
  "sha256": "<hex minúsculo>",
  "mime": "<MIME>",
  "size": <int bytes>,
  "created": "<ISO 8601>",
  "version": "teia.public.v1"
}
```

# Critérios de aceite
- **Index único** com os dois painéis funcionando **sem** precisar abrir o compressor separado.
- Geração de seed no browser bate com o que o adapter aceita (mesmo shape/casing de campos).
- Ao dropar uma seed no painel de restauração, o dashboard:
  - exibe os campos validados,
  - mostra instruções para mover o arquivo para `./gemini_out`,
  - link “Ver log” abre o arquivo de log (se o browser bloquear, instrução para abrir no Explorer).
- Conteúdos não se sobrescrevem inadvertidamente (evitar “página em branco”).
- Tudo funciona **offline**.

# Estado atual (referência)
- Watchers rodando, adapter normaliza e registra: entradas típicas em `logs/gemini_adapter.log`: “OK wrote normalized seed: .\seeds\<target>.<sha12>.teia.json”.
- Índice `./seeds/teia_anchor_index.json` construído do **Downloads** e usado com sucesso na restauração (hash bateu).

# Próximo passo para o Gemini
- Entregar **novo `index.html` auto-contido** com os dois painéis acima (pode reaproveitar o JS/CSS existentes do compressor).
- Manter `compressor_gemini.html` opcionalmente como rota direta (link no header).
- Não tentar escrever em disco via browser; limite-se a gerar o `.teia.json` e orientar o usuário (o watcher/adapter fazem o resto).

Isso fecha a lacuna de UX (“capa” integrada) sem alterar o pipeline offline que já está ok.

---

