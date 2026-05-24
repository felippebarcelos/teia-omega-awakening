# teia_patch_autocontido.ps1
# Uso: pwsh -NoProfile -File .\teia_patch_autocontido.ps1 -Target 'D:\OPS-Move-Teia.ps1'
param(
  [Parameter(Mandatory=$true)][string] $Target
)

if (-not (Test-Path $Target)) { throw "Arquivo alvo não encontrado: $Target" }

# 1) backup
$ts = (Get-Date).ToString('yyyyMMdd_HHmmss')
$bak = "$Target.bak.$ts"
Copy-Item -LiteralPath $Target -Destination $bak -Force
Write-Host "Backup criado em: $bak"

# 2) carregar conteúdo
$content = Get-Content -Raw -LiteralPath $Target

# 3) inserir função helper se ainda não existir
$helperName = '__Teia_GetRelative'
if ($content -notmatch "function\s+$helperName") {
  $helper = @'
function __Teia_GetRelative([string]$root, [string]$path) {
  try {
    # Usa System.IO.Path para obter caminho relativo e remove separadores iniciais extras
    return [System.IO.Path]::GetRelativePath($root, $path) -replace "^[\\/]+", ""
  } catch {
    # fallback: tente remover prefixo root de forma simples
    $r = $path -replace [regex]::Escape($root), ''
    return $r -replace "^[\\/]+",""
  }
}
'@
  # Inserir helper logo após a variável ManualPath ou no início do arquivo se não achar
  if ($content -match "ManualPath\s*=\s*Join-Path") {
    $content = $content -replace "(ManualPath\s*=\s*Join-Path[^\r\n]*\r?\n)", "`$1`r`n$helper"
  } else {
    $content = $helper + "`r`n" + $content
  }
  Write-Host "Helper '$helperName' inserido."
} else {
  Write-Host "Helper '$helperName' já existe — não será inserido novamente."
}

# 4) substituir padrões problemáticos de TrimStart por chamada ao helper
# Considera formas comuns encontradas: Replace($RootOut,'').TrimStart('\\','/') e Replace($using:RootOut,'').TrimStart('\\','/')
# Substitui a expressão completa pela chamada __Teia_GetRelative($RootOut,$destPath) ou com using: se existir
$replacements = @(
  @{from="\.Replace\(\$using:RootOut\s*,\s*''\)\.TrimStart\('\\\\','/'\)"; to="__Teia_GetRelative($using:dRoot, \$destPath)"},
  @{from="\.Replace\(\$RootOut\s*,\s*''\)\.TrimStart\('\\\\','/'\)"; to="__Teia_GetRelative($RootOut, \$destPath)"},
  @{from="\.Replace\(\$RootOut\s*,\s*''\)\.TrimStart\('\\\\'\s*,\s*'/'\)"; to="__Teia_GetRelative($RootOut, \$destPath)"},
  @{from="\.Replace\(\$using:RootOut\s*,\s*''\)\.TrimStart\('\\\\'\s*,\s*'/'\)"; to="__Teia_GetRelative($using:dRoot, \$destPath)"}
)

foreach ($r in $replacements) {
  $pattern = $r.from
  $newExpr = $r.to
  $newContent = [regex]::Replace($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  # If regex found and replaced, update content and inform
  if ($newContent -ne $content) {
    $content = $newContent -replace $pattern, $newExpr
    Write-Host "Substituído padrão: $pattern  ->  $newExpr"
  }
}

# 5) procurar ocorrências de TrimStart(...) simples (ex: .TrimStart('\\','/')), substituir por expressão com destPath
if ($content -match "\.TrimStart\(\s*'\\\\'\s*,\s*'/'\s*\)") {
  $content = $content -replace "\.TrimStart\(\s*'\\\\'\s*,\s*'/'\s*\)", "__Teia_GetRelative($RootOut, \$destPath)"
  Write-Host "Substituídas ocorrências genéricas de TrimStart por __Teia_GetRelative."
}

# 6) Escrever arquivo temporário e validar (não sobrescreve até ok)
$tmp = "$Target.tmp.$ts"
Set-Content -LiteralPath $tmp -Value $content -Encoding UTF8
Write-Host "Arquivo temporário gerado: $tmp"

# 7) mostrar resumo e pedir confirmação para sobrescrever o original
Write-Host ""
Write-Host "Resumo das alterações:"
Write-Host " - Backup: $bak"
Write-Host " - Temp:   $tmp"
Write-Host ""
$ans = Read-Host "Deseja aplicar as alterações e sobrescrever $Target ? (Sim/Não)"
if ($ans -match '^(s|S|sim|Sim)$') {
  Move-Item -Force -LiteralPath $tmp -Destination $Target
  Write-Host "Arquivo $Target atualizado. Revise e teste com DRY-RUN."
} else {
  Remove-Item -LiteralPath $tmp -Force
  Write-Host "Alterações canceladas. Arquivo original preservado em $bak"
}

