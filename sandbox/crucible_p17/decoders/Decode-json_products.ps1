[CmdletBinding()]
param([string]$SeedFile='',[string]$OutputFile='')
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
$B = Split-Path $PSCommandPath -Parent
if (-not $SeedFile)   { $SeedFile   = (Resolve-Path "$B\..\seeds\seed_json_products.json").Path }
if (-not $OutputFile) { $OutputFile = (Resolve-Path "$B\..\datasets\json_products.json").Path }

Add-Type @"
using System; using System.IO; using System.Text;
public static class Dec_JsonProducts {
    static long MC(long i,long m,long a,long mod,long min) => (i*m+a)%mod+min;
    public static void Decode(string path, int count) {
        string[] ca = {"electronics","clothing","food","sports","home","beauty","books",
                       "toys","automotive","garden","health","jewelry","music","office","pets"};
        string[] br = {"AlphaGen","BetaCorp","GammaWorks","DeltaLabs","EpsilonTech",
                       "ZetaSystems","EtaCo","ThetaInc","IotaGroup","KappaWorks",
                       "LambdaNet","MuTech","NuDesign","XiMakers","OmicronBrand",
                       "PiFactory","RhoLogic","SigmaForm","TauSoft","UpsilonPro"};
        string[] ac = {"true","true","true","true","true","true","true","true","true","false"};
        using var sw = new StreamWriter(path, false, new UTF8Encoding(false));
        sw.Write("{\"products\":[");
        for (int i = 0; i < count; i++) {
            if (i > 0) sw.Write(',');
            sw.Write("{\"id\":"+(i+1)+",\"sku\":\"SKU-"+(i+1).ToString("D6")+
                "\",\"category\":\""+ca[i%15]+"\",\"brand\":\""+br[i%20]+
                "\",\"price_cents\":"+MC(i,31,5000,99900,100)+
                ",\"stock\":"+MC(i,7,0,500,0)+
                ",\"active\":"+ac[i%10]+"}");
        }
        sw.Write("]}");
    }
}
"@

$seed = Get-Content $SeedFile | ConvertFrom-Json
[Dec_JsonProducts]::Decode($OutputFile, [int]$seed.count)
$sha = (Get-FileHash -LiteralPath $OutputFile -Algorithm SHA256).Hash.ToLower()
$exp = $seed.sha256_original
if ($sha -eq $exp) { Write-Host "SHA-256 PASS: $sha" -ForegroundColor Green }
else               { Write-Host "SHA-256 FAIL`n  got=$sha`n  exp=$exp" -ForegroundColor Red }
