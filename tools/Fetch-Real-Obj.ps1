<#
.SYNOPSIS
    Fetch-Real-Obj.ps1 — Baixa arquivos .obj reais para benchmark P4.3

.DESCRIPTION
    Tenta baixar 5 modelos 3D orgânicos/low-poly de domínio público.
    Filtra arquivos > 500 KB (limite do protocolo P4.3).
    Idempotente: pula arquivos já presentes.

.PARAMETER OutDir
    Diretório de destino. Padrão: D:\TEIA_CORE\benchmarks\obj_realworld
#>
[CmdletBinding()]
param([string]$OutDir = 'D:\TEIA_CORE\benchmarks\obj_realworld')

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ua      = 'Mozilla/5.0 (compatible; TEIA-Fetch/1.0; +educational)'
$maxSize = 500KB

$dataset = @(
    # FSU Burkardt OBJ collection — bem testada (cube.obj já funcionou)
    [ordered]@{
        url  = 'https://people.sc.fsu.edu/~jburkardt/data/obj/teapot.obj'
        file = 'teapot.obj'
        desc = 'Utah Teapot — curvas orgânicas NURBS-to-mesh clássicas'
    },
    [ordered]@{
        url  = 'https://people.sc.fsu.edu/~jburkardt/data/obj/beethoven.obj'
        file = 'beethoven.obj'
        desc = 'Busto de Beethoven — malha orgânica, geometria facial'
    },
    [ordered]@{
        url  = 'https://people.sc.fsu.edu/~jburkardt/data/obj/cow.obj'
        file = 'cow.obj'
        desc = 'Vaca low-poly — modelo orgânico com topologia animal'
    },
    [ordered]@{
        url  = 'https://people.sc.fsu.edu/~jburkardt/data/obj/trumpet.obj'
        file = 'trumpet.obj'
        desc = 'Trompete — geometria curvilínea de instrumento musical'
    },
    # Alec Jacobson common test models (GitHub)
    [ordered]@{
        url  = 'https://raw.githubusercontent.com/alecjacobson/common-3d-test-models/master/data/spot_control_mesh.obj'
        file = 'spot_control_mesh.obj'
        desc = 'Spot the cow — subdivisão low-poly, malha de controle (~70 vértices)'
    }
)

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$ok = 0; $skip = 0; $fail = 0

Write-Host @"
======================================================================
 [FETCH-OBJ] Fetch-Real-Obj.ps1 — Dataset OBJ Real P4.3
 Destino  : $OutDir
 Arquivos : $($dataset.Count)
 Tamanho  : máx $([math]::Round($maxSize/1KB))KB por arquivo
======================================================================
"@ -ForegroundColor Cyan

foreach ($item in $dataset) {
    $dest = Join-Path $OutDir $item.file
    if (Test-Path $dest) {
        $sz = (Get-Item $dest).Length
        Write-Host ("[SKIP] {0,-35} já existe ({1} KB)" -f $item.file, [math]::Round($sz/1KB,1)) -ForegroundColor DarkGray
        $skip++; continue
    }

    Write-Host ("[FETCH] {0}" -f $item.desc) -ForegroundColor Yellow -NoNewline
    try {
        Invoke-WebRequest -Uri $item.url -OutFile $dest -UserAgent $ua `
            -TimeoutSec 45 -UseBasicParsing -ErrorAction Stop

        $sz = (Get-Item $dest).Length
        if ($sz -gt $maxSize) {
            Remove-Item $dest -Force
            Write-Host (" → DESCARTADO ({0} KB > 500 KB)" -f [math]::Round($sz/1KB,1)) -ForegroundColor DarkYellow
            $fail++
        } else {
            Write-Host (" → OK ({0} KB)" -f [math]::Round($sz/1KB,1)) -ForegroundColor Green
            $ok++
        }
    } catch {
        Write-Host (" → FALHA: $($_.Exception.Message -replace '`n',' ')") -ForegroundColor Red
        if (Test-Path $dest) { Remove-Item $dest -Force }
        $fail++
    }
}

Write-Host ''
Write-Host ('=' * 70) -ForegroundColor Cyan
Write-Host " OK: $ok  |  Skip: $skip  |  Falha/Descarte: $fail  |  Total: $($dataset.Count)"
Write-Host ''
Get-ChildItem $OutDir -Filter '*.obj' | Sort-Object Name | ForEach-Object {
    Write-Host ("   {0,-40} {1,7} KB" -f $_.Name, [math]::Round($_.Length/1KB,1))
}
Write-Host ('=' * 70)
