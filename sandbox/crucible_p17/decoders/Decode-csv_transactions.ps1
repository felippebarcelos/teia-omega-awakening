[CmdletBinding()]
param([string]$SeedFile='',[string]$OutputFile='')
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
$B = Split-Path $PSCommandPath -Parent
if (-not $SeedFile)   { $SeedFile   = (Resolve-Path "$B\..\seeds\seed_csv_transactions.json").Path }
if (-not $OutputFile) { $OutputFile = (Resolve-Path "$B\..\datasets\csv_transactions.csv").Path }

Add-Type @"
using System; using System.IO; using System.Text;
public static class Dec_CsvTransactions {
    static DateTime BASE = new DateTime(2024,1,1,0,0,0,DateTimeKind.Utc);
    static string Dt(long i,long s) => BASE.AddSeconds(i*s).ToString("yyyy-MM-dd");
    static long MC(long i,long m,long a,long mod,long min) => (i*m+a)%mod+min;
    public static void Decode(string path, int count) {
        string[] re = {"north","south","east","west","central"};
        using var sw = new StreamWriter(path, false, new UTF8Encoding(false));
        sw.WriteLine("txn_id,date,cust_id,product_id,quantity,unit_price,region");
        for (int i = 0; i < count; i++) {
            sw.Write(1000001+i); sw.Write(',');
            sw.Write(Dt(i,900)); sw.Write(',');
            sw.Write("C"+MC(i,41,0,500,1001).ToString("D4")); sw.Write(',');
            sw.Write("P"+MC(i,13,0,200,1).ToString("D4")); sw.Write(',');
            sw.Write(MC(i,3,1,20,1)); sw.Write(',');
            sw.Write(MC(i,37,100,9900,100)); sw.Write(',');
            sw.WriteLine(re[i%5]);
        }
    }
}
"@

$seed = Get-Content $SeedFile | ConvertFrom-Json
[Dec_CsvTransactions]::Decode($OutputFile, [int]$seed.count)
$sha = (Get-FileHash -LiteralPath $OutputFile -Algorithm SHA256).Hash.ToLower()
$exp = $seed.sha256_original
if ($sha -eq $exp) { Write-Host "SHA-256 PASS: $sha" -ForegroundColor Green }
else               { Write-Host "SHA-256 FAIL`n  got=$sha`n  exp=$exp" -ForegroundColor Red }
