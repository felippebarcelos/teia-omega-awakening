descompactador_resonante.ps1
Set-StrictMode -Version Latest
param([string]$DirPath=".",[Parameter(Mandatory=$true)][string]$Tarefa)
$files = @()
try { $files = Get-ChildItem -Path $DirPath -Filter "manifest_autossintese_*.json" -File -ErrorAction Stop } catch { Write-Host "[AVISO] Falha ao listar manifestos" }
if (-not $files -or $files.Count -eq 0) { Write-Host "[AVISO] Nenhum manifesto encontrado"; exit 0 }
function Tokenize([string]$Text){
if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
$t = $Text.ToLowerInvariant()
$t = [regex]::Replace($t,"[^a-z0-9]+"," ")
return $t.Split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)
}
function Similarity([string]$A,[string]$B){
$ta = Tokenize $A
$tb = Tokenize $B
if ($ta.Count -eq 0 -and $tb.Count -eq 0) { return 0.0 }
$overlap = ($ta | Where-Object { $tb -contains $_ }).Count
if (($ta.Count + $tb.Count) -gt 0) { return (2.0 * $overlap) / ($ta.Count + $tb.Count) } else { return 0.0 }
}
$results = @()
foreach ($f in $files) {
try {
$obj = Get-Content -Path $f.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
$summary = "" + ($obj.auditoria_resumo -as [string])
$prompt = "" + ($obj.prompt_original -as [string])
$tags = @()
if ($obj.tags) { $tags = @($obj.tags) }
$perf = $obj.desempenho
$dur = 0.0; $err = 0; $size = 0.0
if ($perf) {
if ($perf.duracao_ms) { $dur = [double]$perf.duracao_ms }
if ($perf.erros_detectados) { $err = [int]$perf.erros_detectados }
if ($perf.tamanho_bytes) { $size = [double]$perf.tamanho_bytes }
}
$sim1 = Similarity -A $Tarefa -B $summary
$sim2 = Similarity -A $Tarefa -B $prompt
$tagBoost = 0.0
foreach ($t in $tags) { if ($Tarefa.ToLowerInvariant().Contains(("" + $t).ToLowerInvariant())) { $tagBoost += 0.05 } }
$perfScore = 1.0
if ($dur -gt 0) { $perfScore *= [Math]::Min(1.0, 60000.0 / $dur) }
if ($err -gt 0) { $perfScore *= [Math]::Max(0.1, 1.0 - [Math]::Min(0.9, $err * 0.1)) }
if ($size -gt 0) { $perfScore *= [Math]::Min(1.0, 131072.0 / $size) }
$recency = 0.0
try { $ts = Get-Date $obj.timestamp; $age = (Get-Date) - $ts; $recency = [Math]::Max(0.0,[Math]::Min(1.0,1.0 - ($age.TotalDays / 30.0))) } catch {}
$score = (0.6 * [Math]::Max($sim1,$sim2)) + (0.3 * $perfScore) + (0.1 * $recency) + $tagBoost
$results += [pscustomobject]@{ manifest = $f.FullName; script = ("" + $obj.script_path); score = [double]$score; sim = [double][Math]::Max($sim1,$sim2); perf = [double]$perfScore; recency = [double]$recency }
} catch { Write-Host ("[AVISO] Falha ao processar {0}" -f $f.Name) }
}
if (-not $results -or $results.Count -eq 0) { Write-Host "[AVISO] Nenhum resultado valido"; exit 0 }
$best = $results | Sort-Object -Property score -Descending | Select-Object -First 1
Write-Host "[TEIA] Melhor ressonancia"
Write-Host ("Manifesto: {0}" -f $best.manifest)
Write-Host ("Script: {0}" -f $best.script)
Write-Host ("Score: {0:N3} (sim={1:N3}, perf={2:N3}, rec={3:N3})" -f $best.score,$best.sim,$best.perf,$best.recency)
Write-Host "[TEIA] Descompactador ressonante concluido"