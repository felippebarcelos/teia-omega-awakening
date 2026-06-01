[CmdletBinding()]
param([string]$SeedFile='',[string]$OutputFile='')
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
$B = Split-Path $PSCommandPath -Parent
if (-not $SeedFile)   { $SeedFile   = (Resolve-Path "$B\..\seeds\seed_svg_network_10k.json").Path }
if (-not $OutputFile) { $OutputFile = (Resolve-Path "$B\..\datasets\svg_network_10k.svg").Path }

if (-not ([System.Management.Automation.PSTypeName]'Dec_SvgNetwork').Type) {
Add-Type @"
using System; using System.IO; using System.Text;
public static class Dec_SvgNetwork {
    static long MC(long i,long m,long a,long mod,long min) => (i*m+a)%mod+min;
    public static void Decode(string path, int nodeCount, int edgeCount) {
        string[] nf = {"#3498db","#e74c3c","#2ecc71","#f39c12"};
        string[] es = {"#95a5a6","#7f8c8d","#bdc3c7"};
        int[] ncx = new int[nodeCount];
        int[] ncy = new int[nodeCount];
        for (int j = 0; j < nodeCount; j++) {
            ncx[j] = (int)MC(j,41,50,701,50);
            ncy[j] = (int)MC(j,59,50,501,50);
        }
        using var sw = new StreamWriter(path, false, new UTF8Encoding(false));
        sw.WriteLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        sw.WriteLine("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"800\" height=\"600\" viewBox=\"0 0 800 600\">");
        for (int j = 0; j < nodeCount; j++)
            sw.WriteLine("<circle cx=\""+ncx[j]+"\" cy=\""+ncy[j]+"\" r=\"6\" fill=\""+nf[j%4]+"\"/>");
        for (int e = 0; e < edgeCount; e++) {
            int src = (int)MC(e,37,0,nodeCount,0);
            int dst = (int)MC(e,53,nodeCount/2,nodeCount,0);
            sw.WriteLine("<line x1=\""+ncx[src]+"\" y1=\""+ncy[src]+"\" x2=\""+ncx[dst]+"\" y2=\""+ncy[dst]+"\" stroke=\""+es[e%3]+"\" stroke-width=\"1\"/>");
        }
        sw.WriteLine("</svg>");
    }
}
"@
}

$seed = Get-Content $SeedFile | ConvertFrom-Json
[Dec_SvgNetwork]::Decode($OutputFile, [int]$seed.node_count, [int]$seed.edge_count)
$sha = (Get-FileHash -LiteralPath $OutputFile -Algorithm SHA256).Hash.ToLower()
$exp = $seed.sha256_original
if ($sha -eq $exp) { Write-Host "SHA-256 PASS: $sha" -ForegroundColor Green }
else               { Write-Host "SHA-256 FAIL`n  got=$sha`n  exp=$exp" -ForegroundColor Red }
