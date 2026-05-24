# 2004 - Erro campo fn vazio

### USUÁRIO

PS D:\Teia\TEIA_NUCLEO\offline\nano> Set-Location 'D:\Teia\TEIA_NUCLEO\offline\nano'
>> [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
>> $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
>>
>> $code = @'
>> # TEIA-Fractal-Gen.ps1 — v1.7c (inline/caminho com cascata forte + diag)
>> [CmdletBinding()]
>> param(
>>   [Parameter(Mandatory=$true)] $Manifest,     # PSCustomObject | string | string[] | JSON inline | caminho
>>   [Parameter(Mandatory=$true)][string]$Out,
>>   [switch]$Verify
>> )
>> $ErrorActionPreference='Stop'
>> $script:WRAPPER_VERSION='TEIA-Fractal-Gen v1.7c'
>> if (-not ($PSVersionTable.PSVersion.Major -ge 7)) { throw "Requer PowerShell 7+. Use 'pwsh'." }
>> [Console]::OutputEncoding=[System.Text.Encoding]::UTF8
>> $env:DOTNET_SYSTEM_GLOBALIZATION_INVARIANT="false"
>>
>> function Invoke-JsonCascade {
>>   param([string]$Text,[int]$MaxPasses=6)
>>   if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
>>   $t=$Text; if ($t.Length -gt 0 -and [int]$t[0] -eq 0xFEFF) { $t=$t.Substring(1) }
>>   $t=$t.Trim()
>>   if (($t.StartsWith('"') -and $t.EndsWith('"')) -or ($t.StartsWith("'") -and $t.EndsWith("'"))) {
>>     $t=$t.Substring(1,$t.Length-2).Trim()
>>   }
>>   $current=$t
>>   for($i=0;$i -lt $MaxPasses;$i++){
>>     try { $obj=$current|ConvertFrom-Json -Depth 64 } catch { $obj=$null }
>>     if($obj -is [pscustomobject]){ return $obj }
>>     if($obj -is [System.Collections.IDictionary]){ return [pscustomobject]$obj }
>>     if($obj -is [string]){ $current=([string]$obj).Trim(); continue }
>>     if(-not($current.StartsWith('{') -or $current.StartsWith('['))){
>>       try{
>>         $rp = (Resolve-Path -LiteralPath $current -ErrorAction Stop).Path
>>         $current = (Get-Content -LiteralPath $rp -Raw -Encoding UTF8)
>>         if ($current.Length -gt 0 -and [int]$current[0] -eq 0xFEFF) { $current=$current.Substring(1) }
>>         $current=$current.Trim()
>>         continue
>>       }catch{}
>>     }
>>     break
>>   }
>>   return $null
>> }
>>
>> # Saída
>> $fullOut = if([System.IO.Path]::IsPathRooted($Out)){ $Out } else { Join-Path (Get-Location).Path $Out }
>> $fullOutDir = Split-Path -Parent $fullOut
>> if(-not(Test-Path -LiteralPath $fullOutDir)){ New-Item -ItemType Directory -Path $fullOutDir -Force|Out-Null }
>>
>> # Funções
>> $functionsFile=Join-Path $PSScriptRoot 'GenFunctions.ps1'
>> if(-not(Test-Path -LiteralPath $functionsFile)){ throw "Funções não encontradas: $functionsFile" }
>> . $functionsFile
>>
>> # Diag tipo de Manifest
>> $mnType = if($null -eq $Manifest){'null'}elseif($Manifest.GetType().IsArray){'array'}else{$Manifest.GetType().FullName}
>> Write-Host "[DEBUG] Wrapper=$script:WRAPPER_VERSION"
>> Write-Host "[DEBUG] Param.Manifest.Type=$mnType"
>> if($null -eq $Manifest){ throw "Manifest nulo. Forneça PSCustomObject, caminho .json ou JSON inline." }
>> if($Manifest.GetType().IsArray){ $Manifest=($Manifest -join '') }
>>
>> # Resolver Manifest -> PSCustomObject
>> $manifestObj=$null
>> if($Manifest -is [pscustomobject]){
>>   $manifestObj=$Manifest
>> }else{
>>   $manifestObj = Invoke-JsonCascade -Text ([string]$Manifest) -MaxPasses 6
>> }
>>
>> # Peek
>> try{
>>   $peek=if($manifestObj){($manifestObj|ConvertTo-Json -Depth 5)}else{"<null>"}
>>   Write-Host "[DEBUG] Manifest.peek=" ($peek.Substring(0,[Math]::Min(120,$peek.Length)))
>> }catch{}
>>
>> # Validação final
>> if($null -eq $manifestObj -or -not($manifestObj -is [pscustomobject])){
>>   $detected = if($null -eq $manifestObj){'null'}else{$manifestObj.GetType().FullName}
>>   throw "Manifesto não é objeto JSON. Tipo: $detected."
>> }
>>
>> # Seleção
>> $fn=([string]$manifestObj.fn); if($null -eq $fn){$fn=''}; $fn=$fn.Trim()
>> Write-Host "[DEBUG] Manifest.fn = '$fn'"
>> if([string]::IsNullOrWhiteSpace($fn)){ throw "Campo 'fn' ausente ou vazio no manifesto." }
>>
>> switch($fn){
>>   'gen_checkered_png'{
>>     $seed=[string]$manifestObj.seed
>>     $width=[int]$manifestObj.params.width
>>     $height=[int]$manifestObj.params.height
>>     $color1=[string]$manifestObj.params.color1
>>     $color2=[string]$manifestObj.params.color2
>>     if($width -le 0 -or $height -le 0){ throw "Parâmetros inválidos: width/height > 0." }
>>     gen_checkered_png -Seed $seed -Width $width -Height $height -Color1 $color1 -Color2 $color2 -Out $fullOut
>>   }
>>   default{ throw "Função desconhecida no manifesto: '$fn'." }
>> }
>>
>> # Hash e verificação
>> if(-not(Test-Path -LiteralPath $fullOut)){ throw "Arquivo não gerado: $fullOut" }
>> $genHash=(Get-FileHash -LiteralPath $fullOut -Algorithm SHA256).Hash
>> Write-Host "[Gen] $fullOut (SHA=$genHash)"
>> if($Verify){
>>   $verHash=(Get-FileHash -LiteralPath $fullOut -Algorithm SHA256).Hash
>>   Write-Host "[Verify] SHA256=$verHash"
>>   if($genHash -ne $verHash){ throw "Falha de verificação: hashes diferentes" }
>> }
>> '@
>>
>> [System.IO.File]::WriteAllText('.\TEIA-Fractal-Gen.ps1', $code, $utf8NoBom)
>> (Get-Content '.\TEIA-Fractal-Gen.ps1' -TotalCount 2 -Encoding UTF8) | Write-Host
>>
>> # Teste 1 — INLINE (string JSON)
>> $raw = Get-Content '.\.gen.json' -Raw -Encoding UTF8; if ($raw.Length -gt 0 -and [int]$raw[0] -eq 0xFEFF) { $raw = $raw.Substring(1) }
>> & '.\TEIA-Fractal-Gen.ps1' -Manifest $raw -Out '.\restaurados\checkered.png' -Verify
>>
>> # Teste 2 — CAMINHO
>> & '.\TEIA-Fractal-Gen.ps1' -Manifest '.\.gen.json' -Out '.\restaurados\checkered.png' -Verify
>>
>> # Teste 3 — OBJETO (PSCustomObject)
>> $mn = (Get-Content '.\.gen.json' -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 64)
>> & '.\TEIA-Fractal-Gen.ps1' -Manifest $mn -Out '.\restaurados\checkered.png' -Verify
>>
# TEIA-Fractal-Gen.ps1 — v1.7 (inline/caminho com cascata + trim robusto)
[CmdletBinding()]
[DEBUG] Wrapper=TEIA-Fractal-Gen v1.7
[DEBUG] Param.Manifest.Type=System.String
[DEBUG] Manifest.peek= "{\n  \"kind\": \"gen\",\n  \"fn\": \"gen_checkered_png\",\n  \"seed\": \"0xAB12CD34\",\n  \"params\": { \"width\": 128,
[DEBUG] Manifest.fn = ''
Exception: D:\Teia\TEIA_NUCLEO\offline\nano\TEIA-Fractal-Gen.ps1:75
Line |
  75 |  … hiteSpace($fn)) { throw "Campo 'fn' ausente ou vazio no manifesto." }
     |                      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Campo 'fn' ausente ou vazio no manifesto.
PS D:\Teia\TEIA_NUCLEO\offline\nano>

---

### ASSISTENTE

Obrigado por compartilhar o script e o erro. O erro está bem claro:

```
Campo 'fn' ausente ou vazio no manifesto.
```

Ou seja, o campo `fn` no objeto `manifestObj` está **nulo ou vazio**, e isso faz com que o script lance uma exceção.

---

### 🔍 Análise passo a passo

Você faz três testes diferentes:

1. **Manifesto inline (string JSON)**
2. **Caminho para `.gen.json`**
3. **Objeto PowerShell (`PSCustomObject`)**

Mas todos estão falhando no mesmo ponto: `fn` está vazio. O log mostra isso:

```
[DEBUG] Manifest.fn = ''
```

---

### ✅ O que o script espera

O campo `fn` é **obrigatório** e determina qual função será chamada no switch:

```powershell
switch($fn){
  'gen_checkered_png'{
    ...
  }
  default{ throw "Função desconhecida no manifesto: '$fn'." }
}
```

Portanto, o seu `.gen.json` **precisa conter algo como**:

```json
{
  "fn": "gen_checkered_png",
  "seed": "0xAB12CD34",
  "params": {
    "width": 128,
    "height": 128,
    "color1": "#FFFFFF",
    "color2": "#000000"
  }
}
```

---

### 🛠 Como corrigir

1. Abra seu arquivo `.gen.json` e verifique se contém o campo `fn` no nível superior.
2. Certifique-se de que o JSON seja válido e que o valor de `fn` seja exatamente:

```json
"fn": "gen_checkered_png"
```

3. Evite comentários ou trailing commas (`,`) que quebrem o JSON.
4. Se estiver usando UTF-8 com BOM, o script já trata isso, mas certifique-se de que o arquivo está salvo como **UTF-8 sem BOM**, se possível.

---

### 🧪 Exemplo de `.gen.json` válido

```json
{
  "kind": "gen",
  "fn": "gen_checkered_png",
  "seed": "0xAB12CD34",
  "params": {
    "width": 128,
    "height": 128,
    "color1": "#FF0000",
    "color2": "#00FF00"
  }
}
```

---

Se quiser, posso validar o seu arquivo `.gen.json` ou te ajudar a montar um do zero. Deseja isso?

---

