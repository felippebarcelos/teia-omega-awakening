[CmdletBinding()]
param([string]$SeedFile='',[string]$OutputFile='')
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
$B = Split-Path $PSCommandPath -Parent
if (-not $SeedFile)   { $SeedFile   = (Resolve-Path "$B\..\seeds\seed_csv_server_logs.json").Path }
if (-not $OutputFile) { $OutputFile = (Resolve-Path "$B\..\datasets\csv_server_logs.csv").Path }

if (-not ([System.Management.Automation.PSTypeName]'Dec_CsvServerLogs').Type) {
Add-Type @"
using System; using System.IO; using System.Text;
public static class Dec_CsvServerLogs {
    static DateTime BASE = new DateTime(2024,1,1,0,0,0,DateTimeKind.Utc);
    static string Ts(long i,long s) => BASE.AddSeconds(i*s).ToString("yyyy-MM-ddTHH:mm:ssZ");
    static long MC(long i,long m,long a,long mod,long min) => (i*m+a)%mod+min;
    public static void Decode(string path, int count) {
        string[] sv = {"srv-01","srv-02","srv-03","srv-04","srv-05","srv-06","srv-07","srv-08"};
        string[] lv = {"INFO","INFO","INFO","INFO","WARN","WARN","ERROR","DEBUG"};
        string[] mo = {"auth","api","db","cache","queue","storage","scheduler",
                       "notifier","reporter","exporter","importer","validator"};
        string[] st = {"200","200","200","200","200","404","500","202"};
        using var sw = new StreamWriter(path, false, new UTF8Encoding(false));
        sw.WriteLine("line_id,ts,server,level,module,duration_ms,status");
        for (int i = 0; i < count; i++) {
            sw.Write((i+1)); sw.Write(',');
            sw.Write(Ts(i,30)); sw.Write(',');
            sw.Write(sv[i%8]); sw.Write(',');
            sw.Write(lv[i%8]); sw.Write(',');
            sw.Write(mo[i%12]); sw.Write(',');
            sw.Write(MC(i,23,50,200,10)); sw.Write(',');
            sw.WriteLine(st[i%8]);
        }
    }
}
"@
}

$seed = Get-Content $SeedFile | ConvertFrom-Json
[Dec_CsvServerLogs]::Decode($OutputFile, [int]$seed.count)
$sha = (Get-FileHash -LiteralPath $OutputFile -Algorithm SHA256).Hash.ToLower()
$exp = $seed.sha256_original
if ($sha -eq $exp) { Write-Host "SHA-256 PASS: $sha" -ForegroundColor Green }
else               { Write-Host "SHA-256 FAIL`n  got=$sha`n  exp=$exp" -ForegroundColor Red }
