[CmdletBinding()]
param([string]$SeedFile='',[string]$OutputFile='')
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
$B = Split-Path $PSCommandPath -Parent
if (-not $SeedFile)   { $SeedFile   = (Resolve-Path "$B\..\seeds\seed_csv_orders.json").Path }
if (-not $OutputFile) { $OutputFile = (Resolve-Path "$B\..\datasets\csv_orders.csv").Path }

Add-Type @"
using System; using System.IO; using System.Text;
public static class Dec_CsvOrders {
    static DateTime BASE = new DateTime(2024,1,1,0,0,0,DateTimeKind.Utc);
    static string Ts(long i,long s) => BASE.AddSeconds(i*s).ToString("yyyy-MM-ddTHH:mm:ssZ");
    static long MC(long i,long m,long a,long mod,long min) => (i*m+a)%mod+min;
    public static void Decode(string path, int count) {
        string[] st = {"pending","processing","shipped","delivered","cancelled"};
        string[] pr = {"normal","normal","normal","high","urgent"};
        string[] ct = {"individual","business","premium","enterprise"};
        string[] co = {"US","CA","MX","BR","AR","GB","DE","FR","IT","ES","NL","SE",
                       "NO","DK","FI","PL","RU","JP","CN","KR","AU","NZ","IN","ZA","NG"};
        using var sw = new StreamWriter(path, false, new UTF8Encoding(false));
        sw.WriteLine("order_id,created_at,status,priority,customer_type,items_count,country");
        for (int i = 0; i < count; i++) {
            sw.Write(5000001+i); sw.Write(',');
            sw.Write(Ts(i,120)); sw.Write(',');
            sw.Write(st[i%5]); sw.Write(',');
            sw.Write(pr[i%5]); sw.Write(',');
            sw.Write(ct[i%4]); sw.Write(',');
            sw.Write(MC(i,7,1,15,1)); sw.Write(',');
            sw.WriteLine(co[i%25]);
        }
    }
}
"@

$seed = Get-Content $SeedFile | ConvertFrom-Json
[Dec_CsvOrders]::Decode($OutputFile, [int]$seed.count)
$sha = (Get-FileHash -LiteralPath $OutputFile -Algorithm SHA256).Hash.ToLower()
$exp = $seed.sha256_original
if ($sha -eq $exp) { Write-Host "SHA-256 PASS: $sha" -ForegroundColor Green }
else               { Write-Host "SHA-256 FAIL`n  got=$sha`n  exp=$exp" -ForegroundColor Red }
