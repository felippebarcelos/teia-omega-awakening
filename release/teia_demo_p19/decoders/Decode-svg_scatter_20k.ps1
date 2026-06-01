[CmdletBinding()]
param([string]$SeedFile='',[string]$OutputFile='')
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
$B = Split-Path $PSCommandPath -Parent
if (-not $SeedFile)   { $SeedFile   = (Resolve-Path "$B\..\seeds\seed_svg_scatter_20k.json").Path }
if (-not $OutputFile) { $OutputFile = (Resolve-Path "$B\..\datasets\svg_scatter_20k.svg").Path }

if (-not ([System.Management.Automation.PSTypeName]'Dec_SvgScatter').Type) {
Add-Type @"
using System; using System.IO; using System.Text;
public static class Dec_SvgScatter {
    static long MC(long i,long m,long a,long mod,long min) => (i*m+a)%mod+min;
    public static void Decode(string path, int count) {
        string[] fi = {"#3498db","#e74c3c","#2ecc71","#f39c12","#9b59b6"};
        int[]    ra = {3,5,8};
        using var sw = new StreamWriter(path, false, new UTF8Encoding(false));
        sw.WriteLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        sw.WriteLine("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"800\" height=\"600\" viewBox=\"0 0 800 600\">");
        for (int i = 0; i < count; i++) {
            long cx = MC(i,37,20,761,20);
            long cy = MC(i,53,20,561,20);
            sw.WriteLine("<circle cx=\""+cx+"\" cy=\""+cy+"\" r=\""+ra[i%3]+"\" fill=\""+fi[i%5]+"\"/>");
        }
        sw.WriteLine("</svg>");
    }
}
"@
}

$seed = Get-Content $SeedFile | ConvertFrom-Json
[Dec_SvgScatter]::Decode($OutputFile, [int]$seed.count)
$sha = (Get-FileHash -LiteralPath $OutputFile -Algorithm SHA256).Hash.ToLower()
$exp = $seed.sha256_original
if ($sha -eq $exp) { Write-Host "SHA-256 PASS: $sha" -ForegroundColor Green }
else               { Write-Host "SHA-256 FAIL`n  got=$sha`n  exp=$exp" -ForegroundColor Red }
