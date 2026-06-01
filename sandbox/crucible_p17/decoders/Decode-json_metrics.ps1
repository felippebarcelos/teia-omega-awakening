[CmdletBinding()]
param([string]$SeedFile='',[string]$OutputFile='')
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
$B = Split-Path $PSCommandPath -Parent
if (-not $SeedFile)   { $SeedFile   = (Resolve-Path "$B\..\seeds\seed_json_metrics.json").Path }
if (-not $OutputFile) { $OutputFile = (Resolve-Path "$B\..\datasets\json_metrics.json").Path }

Add-Type @"
using System; using System.IO; using System.Text;
public static class Dec_JsonMetrics {
    static DateTime BASE = new DateTime(2024,1,1,0,0,0,DateTimeKind.Utc);
    static string Ts(long i,long s) => BASE.AddSeconds(i*s).ToString("yyyy-MM-ddTHH:mm:ssZ");
    static long MC(long i,long m,long a,long mod,long min) => (i*m+a)%mod+min;
    public static void Decode(string path, int count) {
        string[] re = {"us-east","us-west","eu-central","ap-south","ap-northeast"};
        string[] sv = {"auth-svc","api-gw","db-primary","cache-redis","search-svc",
                       "billing-svc","mail-svc","media-svc","analytics-svc",
                       "storage-svc","queue-svc","monitor-svc"};
        string[] mk = {"cpu_percent","mem_percent","disk_io","net_rx","net_tx","req_rate"};
        string[] un = {"percent","percent","MB/s","KB/s","KB/s","req/s"};
        using var sw = new StreamWriter(path, false, new UTF8Encoding(false));
        sw.Write("{\"metrics\":[");
        for (int i = 0; i < count; i++) {
            if (i > 0) sw.Write(',');
            int m = i % mk.Length;
            sw.Write("{\"id\":"+(i+1)+",\"ts\":\""+Ts(i,30)+"\",\"region\":\""+re[i%5]+
                "\",\"service\":\""+sv[i%12]+"\",\"metric\":\""+mk[m]+
                "\",\"value\":"+MC(i,23,0,100,0)+",\"unit\":\""+un[m]+"\"}");
        }
        sw.Write("]}");
    }
}
"@

$seed = Get-Content $SeedFile | ConvertFrom-Json
[Dec_JsonMetrics]::Decode($OutputFile, [int]$seed.count)
$sha = (Get-FileHash -LiteralPath $OutputFile -Algorithm SHA256).Hash.ToLower()
$exp = $seed.sha256_original
if ($sha -eq $exp) { Write-Host "SHA-256 PASS: $sha" -ForegroundColor Green }
else               { Write-Host "SHA-256 FAIL`n  got=$sha`n  exp=$exp" -ForegroundColor Red }
