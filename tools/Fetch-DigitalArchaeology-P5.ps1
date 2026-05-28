<#
.SYNOPSIS
    Fetch-DigitalArchaeology-P5.ps1 — Escavadeira Digital P5.1

.DESCRIPTION
    Baixa 25-30 arquivos públicos variados para D:\TEIA_USER\Inbox\Archaeology\.
    Falhas de download são tratadas com graceful skip/continue.

    Categorias:
      - Textos / Livros / HTML        (5 arquivos)
      - Estruturados: JSON, CSV, XML  (5 arquivos)
      - Imagens / Mídia               (5 arquivos)
      - Documentos / PDFs / RFCs      (5 arquivos)
      - Modelos 3D / Código-Fonte     (8 arquivos: 3 inline OBJ + 5 download)

    OBJ inline garantem acionamento do HR6 (gen.parametric_mesh).
    Delta de arquivos no CAS = 0 (este script não toca objects/).

.PARAMETER OutDir
    Diretório de destino. Padrão: D:\TEIA_USER\Inbox\Archaeology
#>
[CmdletBinding()]
param(
    [string]$OutDir = 'D:\TEIA_USER\Inbox\Archaeology'
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC  = [System.Globalization.CultureInfo]::InvariantCulture
$enc = New-Object System.Text.UTF8Encoding($false)   # BOM-less UTF-8

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

# ── Catálogo de downloads ──────────────────────────────────────────────────────
$downloads = [ordered]@{}

# ── CATEGORIA 1: Textos / Livros / HTML ───────────────────────────────────────
$downloads['alice_wonderland.txt']       = 'https://www.gutenberg.org/files/11/11-0.txt'
$downloads['pride_prejudice.txt']        = 'https://www.gutenberg.org/files/1342/1342-0.txt'
$downloads['rfc791_ip_spec.txt']         = 'https://www.rfc-editor.org/rfc/rfc791.txt'
$downloads['gpl3_license.txt']           = 'https://www.gnu.org/licenses/gpl-3.0.txt'
$downloads['iana_reserved_domains.html'] = 'https://www.iana.org/domains/reserved'

# ── CATEGORIA 2: Estruturados (JSON / CSV / XML) ──────────────────────────────
$downloads['github_linux_repo.json']     = 'https://api.github.com/repos/torvalds/linux'
$downloads['jsonplaceholder_todos.json'] = 'https://jsonplaceholder.typicode.com/todos'
$downloads['iana_tld_list.txt']          = 'https://data.iana.org/TLD/tlds-alpha-by-domain.txt'
$downloads['npm_react_latest.json']      = 'https://registry.npmjs.org/react/latest'
$downloads['world_cities.csv']           = 'https://raw.githubusercontent.com/datasets/world-cities/main/data/world-cities.csv'

# ── CATEGORIA 3: Imagens / Mídia ──────────────────────────────────────────────
$downloads['ant_macro.jpg']              = 'https://upload.wikimedia.org/wikipedia/commons/a/a7/Camponotus_flavomarginatus_ant.jpg'
$downloads['png_transparency.png']       = 'https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png'
$downloads['mandelbrot_zoom.jpg']        = 'https://upload.wikimedia.org/wikipedia/commons/2/21/Mandel_zoom_00_mandelbrot_set.jpg'
$downloads['stonehenge.jpg']             = 'https://upload.wikimedia.org/wikipedia/commons/1/1e/Stonehenge.jpg'
$downloads['bilinear_interp.png']        = 'https://upload.wikimedia.org/wikipedia/commons/3/3f/Bilinear_interpolation_visualisation.png'

# ── CATEGORIA 4: Documentos / PDFs / RFCs ─────────────────────────────────────
$downloads['rfc2616_http11.pdf']         = 'https://www.rfc-editor.org/rfc/rfc2616.pdf'
$downloads['rfc3550_rtp.pdf']            = 'https://www.rfc-editor.org/rfc/rfc3550.pdf'
$downloads['rfc2119_keywords.pdf']       = 'https://www.rfc-editor.org/rfc/rfc2119.pdf'
$downloads['rfc7159_json.pdf']           = 'https://www.rfc-editor.org/rfc/rfc7159.pdf'
$downloads['rfc4648_base64.pdf']         = 'https://www.rfc-editor.org/rfc/rfc4648.pdf'

# ── CATEGORIA 5: Código-Fonte (download) ──────────────────────────────────────
$downloads['linux_makefile.mk']          = 'https://raw.githubusercontent.com/torvalds/linux/master/Makefile'
$downloads['cpython_os_module.py']       = 'https://raw.githubusercontent.com/python/cpython/main/Lib/os.py'
$downloads['threejs_vector3.js']         = 'https://raw.githubusercontent.com/mrdoob/three.js/dev/src/math/Vector3.js'
$downloads['nodejs_http_module.js']      = 'https://raw.githubusercontent.com/nodejs/node/main/lib/http.js'
$downloads['react_index.js']             = 'https://raw.githubusercontent.com/facebook/react/main/packages/react/index.js'

# ── CATEGORIA 5: Modelos 3D inline (garantem HR6) ─────────────────────────────
# Estes arquivos são gerados localmente — não dependem de conectividade.

$inlineObjs = [ordered]@{

    'prim_cube.obj' = @"
# TEIA P5.1 DigitalArchaeology — inline primitive
# cube_v1_ccw | AABB (0,0,0)-(1,1,1) | v8 f12
g prim_cube

v 0.000000 0.000000 0.000000
v 0.000000 0.000000 1.000000
v 0.000000 1.000000 0.000000
v 0.000000 1.000000 1.000000
v 1.000000 0.000000 0.000000
v 1.000000 0.000000 1.000000
v 1.000000 1.000000 0.000000
v 1.000000 1.000000 1.000000

f 1 7 5
f 1 3 7
f 1 4 3
f 1 2 4
f 3 8 7
f 3 4 8
f 5 7 8
f 5 8 6
f 1 5 6
f 1 6 2
f 2 6 8
f 2 8 4
"@

    'prim_plane.obj' = @"
# TEIA P5.1 DigitalArchaeology — inline primitive
# plane_v1_ccw | AABB (0,0,0)-(10,0,10) | v4 f2
g prim_plane

v 0.000000 0.000000 0.000000
v 10.000000 0.000000 0.000000
v 10.000000 0.000000 10.000000
v 0.000000 0.000000 10.000000

f 1 2 3
f 1 3 4
"@

    'prim_octahedron.obj' = @"
# TEIA P5.1 DigitalArchaeology — inline primitive
# octahedron_v1_ccw | center=(0,0,0) r=1 | v6 f8
g prim_octahedron

v 0.000000 0.000000 1.000000
v 1.000000 0.000000 0.000000
v 0.000000 1.000000 0.000000
v -1.000000 0.000000 0.000000
v 0.000000 -1.000000 0.000000
v 0.000000 0.000000 -1.000000

f 1 2 3
f 1 3 4
f 1 4 5
f 1 5 2
f 6 3 2
f 6 4 3
f 6 5 4
f 6 2 5
"@
}

# ── Escrever OBJs inline ───────────────────────────────────────────────────────

Write-Host ''
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host '  Fetch-DigitalArchaeology-P5 — Escavadeira Digital TEIA P5.1' -ForegroundColor Cyan
Write-Host "  Destino : $OutDir"
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host ''
Write-Host '  [INLINE] Escrevendo primitivos OBJ (garantem HR6)...' -ForegroundColor Green

foreach ($name in $inlineObjs.Keys) {
    $path    = Join-Path $OutDir $name
    $content = $inlineObjs[$name].TrimEnd().Replace("`r`n", "`n") + "`n"
    [System.IO.File]::WriteAllText($path, $content, $enc)
    Write-Host ("  [OK]     $name ($((Get-Item $path).Length) B)") -ForegroundColor Green
}

# ── Downloads ─────────────────────────────────────────────────────────────────

$okCount   = 0
$skipCount = 0
$results   = [System.Collections.Generic.List[hashtable]]::new()

Write-Host ''
Write-Host "  [FETCH]  Iniciando $($downloads.Count) downloads..." -ForegroundColor Cyan
Write-Host ''

$ua = 'Mozilla/5.0 TEIA-P5-DigitalArchaeology/1.0'

foreach ($name in $downloads.Keys) {
    $url  = $downloads[$name]
    $dest = Join-Path $OutDir $name

    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -TimeoutSec 45 `
            -UserAgent $ua -MaximumRedirection 5 -ErrorAction Stop
        $sw.Stop()
        $bytes = (Get-Item -LiteralPath $dest).Length
        $kb    = [math]::Round($bytes / 1KB, 1)
        Write-Host ("  [OK]     {0,-40} {1,7} KB  {2}ms" -f $name, $kb, $sw.ElapsedMilliseconds) -ForegroundColor Green
        $okCount++
        $results.Add([ordered]@{ name=$name; status='ok'; bytes=$bytes; ms=$sw.ElapsedMilliseconds; url=$url })
    }
    catch {
        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
        $msg = $_.Exception.Message.Split("`n")[0].Trim()
        Write-Host ("  [SKIP]   {0,-40} {1}" -f $name, $msg.Substring(0,[Math]::Min(55,$msg.Length))) -ForegroundColor DarkYellow
        $skipCount++
        $results.Add([ordered]@{ name=$name; status='skip'; bytes=0; ms=0; url=$url; error="$msg" })
    }
}

# ── Sumário ───────────────────────────────────────────────────────────────────

$inlineCount = $inlineObjs.Count
$totalOk     = $okCount + $inlineCount
$allFiles    = Get-ChildItem -LiteralPath $OutDir -File | Sort-Object Name
$totalBytes  = ($allFiles | Measure-Object -Property Length -Sum).Sum

Write-Host ''
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host '  SUMARIO DE COLETA' -ForegroundColor Cyan
Write-Host ('─' * 72)
Write-Host ("  OBJ inline escritos : $inlineCount")   -ForegroundColor Green
Write-Host ("  Downloads OK        : $okCount")        -ForegroundColor Green
Write-Host ("  Downloads SKIP      : $skipCount")      -ForegroundColor $(if ($skipCount -gt 0) { 'DarkYellow' } else { 'White' })
Write-Host ("  Total arquivos      : $totalOk")
Write-Host ("  Total bytes         : $([math]::Round($totalBytes / 1MB, 2)) MB")
Write-Host ("  CAS Delta bytes     : 0 (contencao mantida)")
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host ''
Write-Host "  Arquivos em: $OutDir"
Write-Host ''

$allFiles | Select-Object Name, @{N='KB';E={[math]::Round($_.Length/1KB,1)}} | Format-Table -AutoSize
