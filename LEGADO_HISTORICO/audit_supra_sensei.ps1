$body = @{
    model = "teia-supra-sensei"
    prompt = "Identifique-se e declare sua lei de precedência operacional."
    stream = $false
} | ConvertTo-Json

$response = Invoke-RestMethod -Method Post -Uri "http://localhost:11434/api/generate" -Body $body -ContentType "application/json"
Write-Host "--- LOG DE AUDITORIA DE NASCIMENTO ---"
Write-Host "Modelo: teia-supra-sensei"
Write-Host "Status: NASCIDO"
Write-Host "Resposta: $($response.response)"
Write-Host "--------------------------------------"
