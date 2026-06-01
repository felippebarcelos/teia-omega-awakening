[CmdletBinding()]
param([string]$SeedFile='',[string]$OutputFile='')
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
$B = Split-Path $PSCommandPath -Parent
if (-not $SeedFile)   { $SeedFile   = (Resolve-Path "$B\..\seeds\seed_csv_sensor_data.json").Path }
if (-not $OutputFile) { $OutputFile = (Resolve-Path "$B\..\datasets\csv_sensor_data.csv").Path }

Add-Type @"
using System; using System.IO; using System.Text;
public static class Dec_CsvSensorData {
    static DateTime BASE = new DateTime(2024,1,1,0,0,0,DateTimeKind.Utc);
    static string Ts(long i,long s) => BASE.AddSeconds(i*s).ToString("yyyy-MM-ddTHH:mm:ssZ");
    static long MC(long i,long m,long a,long mod,long min) => (i*m+a)%mod+min;
    public static void Decode(string path, int count) {
        string[] lo = {"room_a","room_b","room_c","room_d","room_e",
                       "lab_1","lab_2","server_1","server_2","warehouse_a",
                       "warehouse_b","office_1","office_2","lobby","roof",
                       "basement","floor_1","floor_2","floor_3","floor_4"};
        string[] ty = {"temperature","humidity","pressure","co2","light"};
        string[] st = {"OK","OK","OK","OK","OK","OK","OK","OK","OK","WARN"};
        using var sw = new StreamWriter(path, false, new UTF8Encoding(false));
        sw.WriteLine("id,timestamp,sensor_id,location,type,reading,status");
        for (int i = 0; i < count; i++) {
            sw.Write((i+1)); sw.Write(',');
            sw.Write(Ts(i,60)); sw.Write(',');
            sw.Write("SENSOR-"+MC(i,11,0,50,1).ToString("D3")); sw.Write(',');
            sw.Write(lo[i%20]); sw.Write(',');
            sw.Write(ty[i%5]); sw.Write(',');
            sw.Write(MC(i,19,0,1000,0)); sw.Write(',');
            sw.WriteLine(st[i%10]);
        }
    }
}
"@

$seed = Get-Content $SeedFile | ConvertFrom-Json
[Dec_CsvSensorData]::Decode($OutputFile, [int]$seed.count)
$sha = (Get-FileHash -LiteralPath $OutputFile -Algorithm SHA256).Hash.ToLower()
$exp = $seed.sha256_original
if ($sha -eq $exp) { Write-Host "SHA-256 PASS: $sha" -ForegroundColor Green }
else               { Write-Host "SHA-256 FAIL`n  got=$sha`n  exp=$exp" -ForegroundColor Red }
