[CmdletBinding()]
param([string]$OutDir = 'D:\TEIA_CORE\benchmarks\obj_parametric_p47')

$ErrorActionPreference = 'Stop'
$IC = [System.Globalization.CultureInfo]::InvariantCulture
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

function fv([double]$x) { return $x.ToString('0.000000', $IC) }

function Write-CubeObj {
    param([string]$Name, [double[]]$Min, [double[]]$Max, [string]$Tag, [switch]$NoNormals)
    $x0 = fv $Min[0]; $y0 = fv $Min[1]; $z0 = fv $Min[2]
    $x1 = fv $Max[0]; $y1 = fv $Max[1]; $z1 = fv $Max[2]
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# TEIA Stress Dataset P4.7 -- $Tag")
    [void]$sb.AppendLine("# cube | AABB ($x0,$y0,$z0)-($x1,$y1,$z1) | v8 f12")
    [void]$sb.AppendLine("g $([System.IO.Path]::GetFileNameWithoutExtension($Name))")
    [void]$sb.AppendLine('')
    foreach ($v in @("$x0 $y0 $z0","$x0 $y0 $z1","$x0 $y1 $z0","$x0 $y1 $z1",
                     "$x1 $y0 $z0","$x1 $y0 $z1","$x1 $y1 $z0","$x1 $y1 $z1")) {
        [void]$sb.AppendLine("v $v")
    }
    [void]$sb.AppendLine('')
    if (-not $NoNormals) {
        foreach ($n in @('-1.000000 0.000000 0.000000','1.000000 0.000000 0.000000',
                         '0.000000 -1.000000 0.000000','0.000000 1.000000 0.000000',
                         '0.000000 0.000000 -1.000000','0.000000 0.000000 1.000000')) {
            [void]$sb.AppendLine("vn $n")
        }
        [void]$sb.AppendLine('')
        foreach ($f in @('1//6 7//6 5//6','1//6 3//6 7//6','1//5 4//5 3//5','1//5 2//5 4//5',
                         '3//4 8//4 7//4','3//4 4//4 8//4','5//2 7//2 8//2','5//2 8//2 6//2',
                         '1//3 5//3 6//3','1//3 6//3 2//3','2//1 6//1 8//1','2//1 8//1 4//1')) {
            [void]$sb.AppendLine("f $f")
        }
    } else {
        foreach ($f in @('1 7 5','1 3 7','1 4 3','1 2 4','3 8 7','3 4 8',
                         '5 7 8','5 8 6','1 5 6','1 6 2','2 6 8','2 8 4')) {
            [void]$sb.AppendLine("f $f")
        }
    }
    $content = $sb.ToString().TrimEnd().Replace("`r`n","`n") + "`n"
    [System.IO.File]::WriteAllText("$OutDir\$Name", $content, [System.Text.Encoding]::UTF8)
}

function Write-PlaneObj {
    param([string]$Name, [double[]]$MinXZ, [double[]]$MaxXZ, [double]$Y, [string]$Tag)
    $x0 = fv $MinXZ[0]; $z0 = fv $MinXZ[1]; $y0 = fv $Y
    $x1 = fv $MaxXZ[0]; $z1 = fv $MaxXZ[1]
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# TEIA Stress Dataset P4.7 -- $Tag")
    [void]$sb.AppendLine("# plane XZ | Y=$y0 | ($x0,$z0)-($x1,$z1)")
    [void]$sb.AppendLine('# Exported from Blender 4.1.0 | Object: Plane')
    [void]$sb.AppendLine("g $([System.IO.Path]::GetFileNameWithoutExtension($Name))")
    [void]$sb.AppendLine('')
    # Scrambled vertex order vs canonical plane_v1_ccw → original_sha256 ≠ canonical_sha256
    foreach ($v in @("$x0 $y0 $z1","$x1 $y0 $z1","$x0 $y0 $z0","$x1 $y0 $z0")) {
        [void]$sb.AppendLine("v $v")
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('vt 0.000000 1.000000')
    [void]$sb.AppendLine('vt 1.000000 1.000000')
    [void]$sb.AppendLine('vt 0.000000 0.000000')
    [void]$sb.AppendLine('vt 1.000000 0.000000')
    [void]$sb.AppendLine('vn 0.000000 1.000000 0.000000')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('f 1/1/1 3/3/1 4/4/1')
    [void]$sb.AppendLine('f 1/1/1 4/4/1 2/2/1')
    $content = $sb.ToString().TrimEnd().Replace("`r`n","`n") + "`n"
    [System.IO.File]::WriteAllText("$OutDir\$Name", $content, [System.Text.Encoding]::UTF8)
}

function Write-DiamondObj {
    param([string]$Name, [double[]]$Center, [double]$Radius, [string]$Tag)
    $cx = [double]$Center[0]; $cy = [double]$Center[1]; $cz = [double]$Center[2]
    [double]$vTop   = $cz + $Radius;  [double]$vRight = $cx + $Radius
    [double]$vFront = $cy + $Radius;  [double]$vLeft  = $cx - $Radius
    [double]$vBack  = $cy - $Radius;  [double]$vBot   = $cz - $Radius
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# TEIA Stress Dataset P4.7 -- $Tag")
    [void]$sb.AppendLine("# octahedron | center=($(fv $cx),$(fv $cy),$(fv $cz)) r=$(fv $Radius)")
    [void]$sb.AppendLine('# v6 f8 | gen.parametric_mesh candidate')
    [void]$sb.AppendLine("g $([System.IO.Path]::GetFileNameWithoutExtension($Name))")
    [void]$sb.AppendLine('')
    foreach ($v in @("$(fv $cx) $(fv $cy) $(fv $vTop)",
                     "$(fv $vRight) $(fv $cy) $(fv $cz)",
                     "$(fv $cx) $(fv $vFront) $(fv $cz)",
                     "$(fv $vLeft) $(fv $cy) $(fv $cz)",
                     "$(fv $cx) $(fv $vBack) $(fv $cz)",
                     "$(fv $cx) $(fv $cy) $(fv $vBot)")) {
        [void]$sb.AppendLine("v $v")
    }
    [void]$sb.AppendLine('')
    foreach ($f in @('1 2 3','1 3 4','1 4 5','1 5 2','6 3 2','6 4 3','6 5 4','6 2 5')) {
        [void]$sb.AppendLine("f $f")
    }
    $content = $sb.ToString().TrimEnd().Replace("`r`n","`n") + "`n"
    [System.IO.File]::WriteAllText("$OutDir\$Name", $content, [System.Text.Encoding]::UTF8)
}

# === 10 STRESS FILES ===
Write-CubeObj    'cube_unit.obj'        @(0.0,0.0,0.0)          @(1.0,1.0,1.0)          'scale=1.0 origin=0'
Write-CubeObj    'cube_small.obj'       @(0.0,0.0,0.0)          @(0.001,0.001,0.001)     'scale=0.001 stress-small' -NoNormals
Write-CubeObj    'cube_offset.obj'      @(1.333333,2.666667,-0.5) @(2.333333,3.666667,0.5) 'offset+fractional-coords'
Write-CubeObj    'cube_large.obj'       @(0.0,0.0,0.0)          @(1000.0,1000.0,1000.0)  'scale=1000 stress-large'
Write-PlaneObj   'plane_unit.obj'       @(0.0,0.0)              @(1.0,1.0)     0.0        'unit XZ Y=0'
Write-PlaneObj   'plane_huge.obj'       @(0.0,0.0)              @(100.0,100.0) 0.0        'huge XZ scale=100 Y=0'
Write-PlaneObj   'plane_offset.obj'     @(-5.5,-3.333333)       @(4.5,6.666667) 2.0       'offset+fractional Y=2'
Write-DiamondObj 'diamond_unit.obj'     @(0.0,0.0,0.0)          1.0                       'center=origin r=1'
Write-DiamondObj 'diamond_negative.obj' @(-1.5,-2.5,0.5)        1.0                       'center=negative-offset r=1'
Write-DiamondObj 'diamond_small.obj'    @(0.0,0.0,0.0)          0.333333                  'center=origin r=0.333333'

$files = Get-ChildItem $OutDir -Filter '*.obj' | Sort-Object Name
Write-Host "Generated $($files.Count) OBJ files in $OutDir"
$files | Select-Object Name,@{N='Bytes';E={$_.Length}} | Format-Table -AutoSize
