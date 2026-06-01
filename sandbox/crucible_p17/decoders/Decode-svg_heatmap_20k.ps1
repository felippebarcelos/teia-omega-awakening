[CmdletBinding()]
param([string]$SeedFile='',[string]$OutputFile='')
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
$B = Split-Path $PSCommandPath -Parent
if (-not $SeedFile)   { $SeedFile   = (Resolve-Path "$B\..\seeds\seed_svg_heatmap_20k.json").Path }
if (-not $OutputFile) { $OutputFile = (Resolve-Path "$B\..\datasets\svg_heatmap_20k.svg").Path }

Add-Type @"
using System; using System.IO; using System.Text;
public static class Dec_SvgHeatmap {
    public static void Decode(string path, int cols, int rows) {
        string[] pal = {
            "#0d0221","#1a0442","#270663","#340884","#2e1a6e","#3829a5",
            "#2255c8","#1a7fd4","#12aacc","#0acfc4","#05e8b0","#17f09a",
            "#2aea7a","#4de050","#70d42a","#96c414","#bcb00e","#e09920",
            "#f07832","#f95044","#ff2a55","#f20966","#cc0078","#99008a"
        };
        int svgW = cols*4+20, svgH = rows*5+20;
        int count = cols*rows;
        using var sw = new StreamWriter(path, false, new UTF8Encoding(false));
        sw.WriteLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        sw.WriteLine("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\""+svgW+"\" height=\""+svgH+"\" viewBox=\"0 0 "+svgW+" "+svgH+"\">");
        for (int i = 0; i < count; i++) {
            int col = i % cols;
            int row = i / cols;
            sw.WriteLine("<rect x=\""+(col*4+10)+"\" y=\""+(row*5+10)+"\" width=\"3\" height=\"4\" fill=\""+pal[i%24]+"\"/>");
        }
        sw.WriteLine("</svg>");
    }
}
"@

$seed = Get-Content $SeedFile | ConvertFrom-Json
[Dec_SvgHeatmap]::Decode($OutputFile, [int]$seed.cols, [int]$seed.rows)
$sha = (Get-FileHash -LiteralPath $OutputFile -Algorithm SHA256).Hash.ToLower()
$exp = $seed.sha256_original
if ($sha -eq $exp) { Write-Host "SHA-256 PASS: $sha" -ForegroundColor Green }
else               { Write-Host "SHA-256 FAIL`n  got=$sha`n  exp=$exp" -ForegroundColor Red }
