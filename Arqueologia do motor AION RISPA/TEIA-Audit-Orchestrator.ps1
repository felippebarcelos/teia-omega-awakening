TEIA-Audit-Orchestrator.ps1
Set-StrictMode -Version Latest
param([switch]$Loop,[int]$PauseSeconds=60,[int]$MaxIterations=0,[switch]$DryRun)
$CodexCliPath = "codex"
$GPTApiKey = $env:OPENAI_API_KEY
$GPTModel = "gpt-4"
$PromptFile = "teia_codex_prompt.txt"
$ScriptOutput = "delta_generated_script.ps1"
$LogDir = "logs_audit"
$DeltaDir = "."
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
function Write-Log([string]$m){ Write-Host ("[TEIA] {0}" -f $m) }
function MaskKey([string]$k){ if ([string]::IsNullOrWhiteSpace($k)) { return "" } ; $pref = $k.Substring(0,[math]::Min(7,$k.Length)); $suf = if ($k.Length -gt 6) { $k.Substring($k.Length-6) } else { $k.Substring([math]::Max(0,$k.Length-6)) }; return ("{0}...{1}" -f $pref,$suf) }
function Normalize-OutputFile([string]$path){
if (-not (Test-Path $path)) { return $false }
$raw = Get-Content -Path $path -Raw -ErrorAction Stop
$m = [regex]::Match($raw,'(?ms)powershell\s*(.*?)\s*')
if ($m.Success) { $clean = $m.Groups[1].Value } else { $clean = $raw }
Set-Content -Path $path -Value $clean -Encoding UTF8
return $true
}
function Save-Manifest($manifestObj,[string]$ts){
$manifestPath = ("manifest_autossintese_{0}.json" -f $ts)
try { ($manifestObj | ConvertTo-Json -Depth 10) | Set-Content -Path $manifestPath -Encoding UTF8; Write-Log ("Manifest saved: {0}" -f $manifestPath); return $manifestPath } catch { Write-Log "AVISO manifest save failed"; return $null }
}
function Audit-With-GPT([string]$execOutput,[string]$iteration,[string]$ts){
if ([string]::IsNullOrWhiteSpace($GPTApiKey)) { Write-Log "OPENAI_API_KEY missing; skipping audit"; return @("",$false) }
$auditPrompt = @"
Agent executed script with output below. Provide a short symbolic audit: summary, fragilities, and suggested improvements.

===== EXECUTION OUTPUT =====
$execOutput
===== CONTEXT =====
Iteration: $iteration
Timestamp: $ts
"@
$uri = "https://api.openai.com/v1/chat/completions
"
$headers = @{ Authorization = ("Bearer {0}" -f $GPTApiKey) }
$bodyObj = @{
model = $GPTModel
messages = @(@{ role = "user"; content = $auditPrompt })
temperature = 0.2
}
$body = $bodyObj | ConvertTo-Json -Depth 8
$maxAttempts = 3
$attempt = 0
while ($attempt -lt $maxAttempts) {
try {
$attempt++
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
if ($response -and $response.choices -and $response.choices.Count -gt 0) { return @($response.choices[0].message.content,$true) } else { return @("","true") }
} catch {
if ($attempt -ge $maxAttempts) { Write-Log ("ERRO contacting GPT API: {0}" -f $.Exception.Message); return @("","false") }
Start-Sleep -Seconds (2 * $attempt)
}
}
return @("","false")
}
$iteration = 0
while ($true) {
$iteration++
$ts = (Get-Date).ToString("yyyyMMdd_HHmmss")
Write-Log ("iteration {0} start {1}" -f $iteration,$ts)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$invokeOk = $false
$normalized = $false
$execOutput = ""
$execOk = $false
$logPath = Join-Path $LogDir ("audit{0}.log" -f $ts)
if ($DryRun) {
Write-Log "DryRun enabled; simulating Codex invocation and execution"
$simContent = 'Write-Host "TEIA-DELTA-OK"; exit 0'
Set-Content -Path $ScriptOutput -Value $simContent -Encoding UTF8
$invokeOk = $true
$normalized = $true
} else {
try {
if (-not (Get-Command $CodexCliPath -ErrorAction SilentlyContinue)) { Write-Log ("Codex CLI not found: {0}" -f $CodexCliPath); $invokeOk = $false } else {
if (-not (Test-Path $PromptFile)) { Write-Log ("Prompt file not found: {0}" -f $PromptFile); $invokeOk = $false } else {
Write-Log "Invoking Codex CLI"
try {
Get-Content -Raw $PromptFile | & $CodexCliPath exec - --output-last-message $ScriptOutput 2>&1 | Out-Null
$invokeOk = $true
} catch {
Write-Log ("ERRO Codex invocation: {0}" -f $.Exception.Message)
$invokeOk = $false
}
}
}
} catch {
Write-Log ("ERRO Codex invocation outer: {0}" -f $.Exception.Message)
$invokeOk = $false
}
}
try {
if (Test-Path -Path $ScriptOutput -PathType Leaf) {
$ok = Normalize-OutputFile -path $ScriptOutput
if ($ok) { $normalized = $true; Write-Log "Normalized generated script" } else { Write-Log "Normalization skipped" }
} else {
Write-Log ("AVISO output file not found: {0}" -f $ScriptOutput)
}
} catch {
Write-Log "AVISO Normalization failed"
}
try {
if (Test-Path -Path $ScriptOutput -PathType Leaf) {
Write-Log "Executing generated script"
$execOutput = & pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptOutput 2>&1 | Out-String
Set-Content -Path $logPath -Value $execOutput -Encoding UTF8
Write-Log ("Execution log saved: {0}" -f $logPath)
if ($LASTEXITCODE -eq 0 -or ($execOutput -match "TEIA-DELTA-OK")) { $execOk = $true } else { $execOk = $false }
} else {
Write-Log "No generated script to execute"
}
} catch {
Write-Log ("ERRO executing generated script: {0}" -f $.Exception.Message)
}
$sw.Stop()
$auditSummary = ""
$auditOk = $false
try {
$auditResult = Audit-With-GPT -execOutput $execOutput -iteration $iteration -ts $ts
$auditSummary = $auditResult[0]
$auditOk = [bool]$auditResult[1]
} catch {
Write-Log ("ERRO audit step: {0}" -f $.Exception.Message)
}
$scriptSize = 0
$sha256 = ""
try {
if (Test-Path -Path $ScriptOutput -PathType Leaf) {
$scriptItem = Get-Item -Path $ScriptOutput -ErrorAction SilentlyContinue
if ($scriptItem) { $scriptSize = $scriptItem.Length }
$hash = Get-FileHash -Path $ScriptOutput -Algorithm SHA256 -ErrorAction Stop
$sha256 = $hash.Hash
}
} catch {
Write-Log "AVISO hash calculation failed"
}
$errorsDetected = 0
try {
if ($execOutput) {
$lines = $execOutput -split "(rn|n)" foreach ($l in $lines) { if ($l -match "(?i)\b(erro|error|exception|fail)\b") { $errorsDetected++ } } } } catch {} $tags = @() if (-not $invokeOk) { $tags += "codex" } if ($normalized) { $tags += "normalizacao" } if ($auditOk) { $tags += "rede" } else { $tags += "auditoria_pendente" } if ($errorsDetected -gt 0) { $tags += "desempenho" } $tags += "dissonancia_sequencial" $manifest = [ordered]@{ timestamp = $ts iteration = $iteration script_path = (if (Test-Path $ScriptOutput) { (Resolve-Path -LiteralPath $ScriptOutput).Path } else { $ScriptOutput }) script_sha256 = $sha256 prompt_original = (if (Test-Path $PromptFile) { Get-Content -Raw $PromptFile } else { "" }) auditoria_resumo = $auditSummary desempenho = @{ tamanho_bytes = $scriptSize duracao_ms = $sw.ElapsedMilliseconds erros_detectados = $errorsDetected execucao_ok = $execOk invocacao_codex_ok = $invokeOk auditoria_ok = $auditOk log_path = $logPath } tags = $tags exec_output_snippet = (($execOutput -split "(rn|n)")[0..([math]::Min(20, (($execOutput -split "(rn|n)").Count-1)))] -join "n")
}
$manifestPath = Save-Manifest $manifest $ts
Write-Log ("iteration {0} done (execOk={1} errors={2})" -f $iteration,$execOk,$errorsDetected)
if (-not $execOk -or $errorsDetected -gt 0) {
try {
$diagPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "diagnose-fractal.ps1"
if (Test-Path $diagPath) { Write-Log "Invoking diagnose-fractal for investigation"; & pwsh -NoProfile -ExecutionPolicy Bypass -File $diagPath -TargetDir . } else { Write-Log "diagnose-fractal.ps1 not found; skipping" }
} catch {
Write-Log ("ERRO invoking diagnose-fractal: {0}" -f $_.Exception.Message)
}
}
if (-not $Loop) { break }
if ($MaxIterations -gt 0 -and $iteration -ge $MaxIterations) { Write-Log "MaxIterations reached"; break }
Start-Sleep -Seconds $PauseSeconds
}
Write-Log "Fluxo concluido"