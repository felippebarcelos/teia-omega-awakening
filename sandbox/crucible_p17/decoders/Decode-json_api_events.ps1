[CmdletBinding()]
param(
    [string]$SeedFile   = '',
    [string]$OutputFile = ''
)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
$BASE_DIR = Split-Path $PSCommandPath -Parent
if (-not $SeedFile)   { $SeedFile   = (Resolve-Path "$BASE_DIR\..\seeds\seed_json_api_events.json").Path }
if (-not $OutputFile) { $OutputFile = (Resolve-Path "$BASE_DIR\..\datasets\json_api_events.json").Path }

Add-Type @"
using System; using System.IO; using System.Text;
public static class Dec_JsonApiEvents {
    static DateTime BASE = new DateTime(2024,1,1,0,0,0,DateTimeKind.Utc);
    static string Ts(long i,long s) => BASE.AddSeconds(i*s).ToString("yyyy-MM-ddTHH:mm:ssZ");
    static long MC(long i,long m,long a,long mod,long min) => (i*m+a)%mod+min;
    public static void Decode(string path, int count) {
        string[] lv = {"INFO","INFO","INFO","INFO","WARN","WARN","ERROR","DEBUG"};
        string[] ho = {"web-01","web-02","db-01","cache-01","cache-02"};
        string[] me = {"GET","POST","PUT","DELETE"};
        string[] ep = {"/api/users","/api/orders","/api/products","/api/auth",
                       "/api/health","/api/metrics","/api/logs","/api/events"};
        int[]    st = {200,201,400,401,404};
        using var sw = new StreamWriter(path, false, new UTF8Encoding(false));
        sw.Write("{\"events\":[");
        for (int i = 0; i < count; i++) {
            if (i > 0) sw.Write(',');
            sw.Write("{\"id\":"+(i+1)+",\"ts\":\""+Ts(i,60)+"\",\"level\":\""+lv[i%8]+
                "\",\"host\":\""+ho[i%5]+"\",\"method\":\""+me[i%4]+
                "\",\"endpoint\":\""+ep[i%8]+"\",\"status\":"+st[i%5]+
                ",\"lat_ms\":"+MC(i,17,1000,1999,1)+"}");
        }
        sw.Write("]}");
    }
}
"@

$seed = Get-Content $SeedFile | ConvertFrom-Json
[Dec_JsonApiEvents]::Decode($OutputFile, [int]$seed.count)
$sha = (Get-FileHash -LiteralPath $OutputFile -Algorithm SHA256).Hash.ToLower()
$exp = $seed.sha256_original
if ($sha -eq $exp) { Write-Host "SHA-256 PASS: $sha" -ForegroundColor Green }
else               { Write-Host "SHA-256 FAIL`n  got=$sha`n  exp=$exp" -ForegroundColor Red }
