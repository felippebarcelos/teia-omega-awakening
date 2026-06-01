<#
.SYNOPSIS
    TEIA P19.0 — Public Demo: Storage as Computation (Claim-Safe Exhibition)
.DESCRIPTION
    Generates 10 structured datasets (JSON/CSV/SVG, up to 5 MB each) from scratch,
    reconstructs them byte-for-byte from stored seeds and decoder scripts,
    measures GZip/Brotli baselines using .NET, and proves SHA-256 identity.

    Requirements: PowerShell 7+ on Windows. No external dependencies.
    Usage: pwsh -ExecutionPolicy Bypass -File .\audit-one-click.ps1
#>
[CmdletBinding()]
param()
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$DemoRoot = Split-Path $PSCommandPath -Parent
$TempDir  = "$DemoRoot\temp"
$OutDir   = "$DemoRoot\out"
$SeedDir  = "$DemoRoot\seeds"
$DecDir   = "$DemoRoot\decoders"

foreach ($d in @($TempDir, $OutDir)) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

# ─── Banner ───────────────────────────────────────────────────────────────────
$w = 78
Write-Host ''
Write-Host ('=' * $w) -ForegroundColor Cyan
Write-Host '  TEIA — Storage as Computation' -ForegroundColor Cyan
Write-Host '  P19.0 Public Demo | Claim-Safe Exhibition' -ForegroundColor Cyan
Write-Host '  Claim: Seed + Decoder << GZip/Brotli  AND  SHA-256 identity bit-a-bit' -ForegroundColor Cyan
Write-Host ('=' * $w) -ForegroundColor Cyan
Write-Host "  Demo root : $DemoRoot" -ForegroundColor DarkGray
Write-Host "  Timestamp : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host ('=' * $w) -ForegroundColor Cyan
Write-Host ''

# ─── Motor C# de geracao determinista (namespace isolado TEIA.P19) ─────────────
if (-not ([System.Management.Automation.PSTypeName]'TEIA.P19.Demo').Type) {
    Add-Type @"
using System;
using System.IO;
using System.Text;
using System.Security.Cryptography;

namespace TEIA.P19 {
public static class Demo {

    static readonly DateTime BASE = new DateTime(2024,1,1,0,0,0,DateTimeKind.Utc);
    static string Ts(long i,long s)       => BASE.AddSeconds(i*s).ToString("yyyy-MM-ddTHH:mm:ssZ");
    static string DateOnly(long i,long s) => BASE.AddSeconds(i*s).ToString("yyyy-MM-dd");
    static long   MC(long i,long m,long a,long mod,long min) => (i*m+a)%mod+min;

    public static string Sha256(string path) {
        using var sha = SHA256.Create();
        using var fs  = File.OpenRead(path);
        return BitConverter.ToString(sha.ComputeHash(fs)).Replace("-","").ToLower();
    }

    public static void GenJsonApiEvents(string p, int n) {
        string[] lv={"INFO","INFO","INFO","INFO","WARN","WARN","ERROR","DEBUG"};
        string[] ho={"web-01","web-02","db-01","cache-01","cache-02"};
        string[] me={"GET","POST","PUT","DELETE"};
        string[] ep={"/api/users","/api/orders","/api/products","/api/auth",
                     "/api/health","/api/metrics","/api/logs","/api/events"};
        int[]    st={200,201,400,401,404};
        using var sw = new StreamWriter(p,false,new UTF8Encoding(false));
        sw.Write("{\"events\":[");
        for(int i=0;i<n;i++){
            if(i>0)sw.Write(',');
            sw.Write("{\"id\":"+(i+1)+",\"ts\":\""+Ts(i,60)+"\",\"level\":\""+lv[i%8]
                +"\",\"host\":\""+ho[i%5]+"\",\"method\":\""+me[i%4]
                +"\",\"endpoint\":\""+ep[i%8]+"\",\"status\":"+st[i%5]
                +",\"lat_ms\":"+MC(i,17,1000,1999,1)+"}");
        }
        sw.Write("]}");
    }
    public static void GenJsonProducts(string p, int n) {
        string[] ca={"electronics","clothing","food","sports","home","beauty","books",
                     "toys","automotive","garden","health","jewelry","music","office","pets"};
        string[] br={"AlphaGen","BetaCorp","GammaWorks","DeltaLabs","EpsilonTech",
                     "ZetaSystems","EtaCo","ThetaInc","IotaGroup","KappaWorks",
                     "LambdaNet","MuTech","NuDesign","XiMakers","OmicronBrand",
                     "PiFactory","RhoLogic","SigmaForm","TauSoft","UpsilonPro"};
        string[] ac={"true","true","true","true","true","true","true","true","true","false"};
        using var sw = new StreamWriter(p,false,new UTF8Encoding(false));
        sw.Write("{\"products\":[");
        for(int i=0;i<n;i++){
            if(i>0)sw.Write(',');
            sw.Write("{\"id\":"+(i+1)+",\"sku\":\"SKU-"+(i+1).ToString("D6")
                +"\",\"category\":\""+ca[i%15]+"\",\"brand\":\""+br[i%20]
                +"\",\"price_cents\":"+MC(i,31,5000,99900,100)
                +",\"stock\":"+MC(i,7,0,500,0)+",\"active\":"+ac[i%10]+"}");
        }
        sw.Write("]}");
    }
    public static void GenJsonMetrics(string p, int n) {
        string[] rg={"us-east","us-west","eu-central","ap-south","ap-northeast"};
        string[] sv={"auth-svc","api-gw","db-primary","cache-redis","search-svc",
                     "billing-svc","mail-svc","media-svc","analytics-svc",
                     "storage-svc","queue-svc","monitor-svc"};
        string[] mt={"cpu_percent","mem_percent","disk_io","net_rx","net_tx","req_rate"};
        string[] un={"percent","percent","MB/s","KB/s","KB/s","req/s"};
        using var sw = new StreamWriter(p,false,new UTF8Encoding(false));
        sw.Write("{\"metrics\":[");
        for(int i=0;i<n;i++){
            if(i>0)sw.Write(',');
            int mi=i%6;
            sw.Write("{\"id\":"+(i+1)+",\"ts\":\""+Ts(i,30)
                +"\",\"region\":\""+rg[i%5]+"\",\"service\":\""+sv[i%12]
                +"\",\"metric\":\""+mt[mi]+"\",\"value\":"+MC(i,23,0,100,0)
                +",\"unit\":\""+un[mi]+"\"}");
        }
        sw.Write("]}");
    }
    public static void GenCsvSensorData(string p, int n) {
        string[] lo={"room_a","room_b","room_c","room_d","room_e",
                     "lab_1","lab_2","server_1","server_2","warehouse_a",
                     "warehouse_b","office_1","office_2","lobby","roof",
                     "basement","floor_1","floor_2","floor_3","floor_4"};
        string[] ty={"temperature","humidity","pressure","co2","light"};
        string[] st={"OK","OK","OK","OK","OK","OK","OK","OK","OK","WARN"};
        using var sw = new StreamWriter(p,false,new UTF8Encoding(false));
        sw.WriteLine("id,timestamp,sensor_id,location,type,reading,status");
        for(int i=0;i<n;i++){
            sw.Write((i+1)); sw.Write(','); sw.Write(Ts(i,60)); sw.Write(',');
            sw.Write("SENSOR-"+MC(i,11,0,50,1).ToString("D3")); sw.Write(',');
            sw.Write(lo[i%20]); sw.Write(','); sw.Write(ty[i%5]); sw.Write(',');
            sw.Write(MC(i,19,0,1000,0)); sw.Write(','); sw.WriteLine(st[i%10]);
        }
    }
    public static void GenCsvTransactions(string p, int n) {
        string[] rg={"north","south","east","west","central"};
        using var sw = new StreamWriter(p,false,new UTF8Encoding(false));
        sw.WriteLine("txn_id,date,cust_id,product_id,quantity,unit_price,region");
        for(int i=0;i<n;i++){
            sw.Write(1000001+i); sw.Write(','); sw.Write(DateOnly(i,900)); sw.Write(',');
            sw.Write("C"+MC(i,41,0,500,1001).ToString("D4")); sw.Write(',');
            sw.Write("P"+MC(i,13,0,200,1).ToString("D4")); sw.Write(',');
            sw.Write(MC(i,3,1,20,1)); sw.Write(',');
            sw.Write(MC(i,37,100,9900,100)); sw.Write(',');
            sw.WriteLine(rg[i%5]);
        }
    }
    public static void GenCsvServerLogs(string p, int n) {
        string[] sv={"srv-01","srv-02","srv-03","srv-04","srv-05","srv-06","srv-07","srv-08"};
        string[] lv={"INFO","INFO","INFO","INFO","WARN","WARN","ERROR","DEBUG"};
        string[] mo={"auth","api","db","cache","queue","storage","scheduler",
                     "notifier","reporter","exporter","importer","validator"};
        string[] st={"200","200","200","200","200","404","500","202"};
        using var sw = new StreamWriter(p,false,new UTF8Encoding(false));
        sw.WriteLine("line_id,ts,server,level,module,duration_ms,status");
        for(int i=0;i<n;i++){
            sw.Write((i+1)); sw.Write(','); sw.Write(Ts(i,30)); sw.Write(',');
            sw.Write(sv[i%8]); sw.Write(','); sw.Write(lv[i%8]); sw.Write(',');
            sw.Write(mo[i%12]); sw.Write(','); sw.Write(MC(i,23,50,200,10)); sw.Write(',');
            sw.WriteLine(st[i%8]);
        }
    }
    public static void GenCsvOrders(string p, int n) {
        string[] st={"pending","processing","shipped","delivered","cancelled"};
        string[] pr={"normal","normal","normal","high","urgent"};
        string[] ct={"individual","business","premium","enterprise"};
        string[] co={"US","CA","MX","BR","AR","GB","DE","FR","IT","ES","NL","SE",
                     "NO","DK","FI","PL","RU","JP","CN","KR","AU","NZ","IN","ZA","NG"};
        using var sw = new StreamWriter(p,false,new UTF8Encoding(false));
        sw.WriteLine("order_id,created_at,status,priority,customer_type,items_count,country");
        for(int i=0;i<n;i++){
            sw.Write(5000001+i); sw.Write(','); sw.Write(Ts(i,120)); sw.Write(',');
            sw.Write(st[i%5]); sw.Write(','); sw.Write(pr[i%5]); sw.Write(',');
            sw.Write(ct[i%4]); sw.Write(','); sw.Write(MC(i,7,1,15,1)); sw.Write(',');
            sw.WriteLine(co[i%25]);
        }
    }
    public static void GenSvgScatter(string p, int n) {
        string[] fi={"#3498db","#e74c3c","#2ecc71","#f39c12","#9b59b6"};
        int[]    ra={3,5,8};
        using var sw = new StreamWriter(p,false,new UTF8Encoding(false));
        sw.WriteLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        sw.WriteLine("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"800\" height=\"600\" viewBox=\"0 0 800 600\">");
        for(int i=0;i<n;i++){
            sw.WriteLine("<circle cx=\""+MC(i,37,20,761,20)+"\" cy=\""+MC(i,53,20,561,20)
                +"\" r=\""+ra[i%3]+"\" fill=\""+fi[i%5]+"\"/>");
        }
        sw.WriteLine("</svg>");
    }
    public static void GenSvgNetwork(string p, int nc, int ec) {
        string[] nf={"#3498db","#e74c3c","#2ecc71","#f39c12"};
        string[] es={"#95a5a6","#7f8c8d","#bdc3c7"};
        int[] ncx=new int[nc]; int[] ncy=new int[nc];
        for(int j=0;j<nc;j++){ncx[j]=(int)MC(j,41,50,701,50);ncy[j]=(int)MC(j,59,50,501,50);}
        using var sw = new StreamWriter(p,false,new UTF8Encoding(false));
        sw.WriteLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        sw.WriteLine("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"800\" height=\"600\" viewBox=\"0 0 800 600\">");
        for(int j=0;j<nc;j++)
            sw.WriteLine("<circle cx=\""+ncx[j]+"\" cy=\""+ncy[j]+"\" r=\"6\" fill=\""+nf[j%4]+"\"/>");
        for(int e=0;e<ec;e++){
            int src=(int)MC(e,37,0,nc,0); int dst=(int)MC(e,53,nc/2,nc,0);
            sw.WriteLine("<line x1=\""+ncx[src]+"\" y1=\""+ncy[src]+"\" x2=\""+ncx[dst]
                +"\" y2=\""+ncy[dst]+"\" stroke=\""+es[e%3]+"\" stroke-width=\"1\"/>");
        }
        sw.WriteLine("</svg>");
    }
    public static void GenSvgHeatmap(string p, int cols, int rows) {
        string[] pal={
            "#0d0221","#1a0442","#270663","#340884","#2e1a6e","#3829a5",
            "#2255c8","#1a7fd4","#12aacc","#0acfc4","#05e8b0","#17f09a",
            "#2aea7a","#4de050","#70d42a","#96c414","#bcb00e","#e09920",
            "#f07832","#f95044","#ff2a55","#f20966","#cc0078","#99008a"
        };
        int svgW=cols*4+20; int svgH=rows*5+20; int count=cols*rows;
        using var sw = new StreamWriter(p,false,new UTF8Encoding(false));
        sw.WriteLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        sw.WriteLine("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\""+svgW+"\" height=\""+svgH
            +"\" viewBox=\"0 0 "+svgW+" "+svgH+"\">");
        for(int i=0;i<count;i++){
            int col=i%cols; int row=i/cols;
            sw.WriteLine("<rect x=\""+(col*4+10)+"\" y=\""+(row*5+10)
                +"\" width=\"3\" height=\"4\" fill=\""+pal[i%24]+"\"/>");
        }
        sw.WriteLine("</svg>");
    }
}
} // namespace TEIA.P19
"@
}

# ─── Funcao de medicao de baseline classica ───────────────────────────────────
function Measure-Baselines([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $opts  = [System.IO.Compression.CompressionLevel]::Optimal

    $ms1 = [System.IO.MemoryStream]::new()
    $gz  = [System.IO.Compression.GZipStream]::new($ms1, $opts, $true)
    $gz.Write($bytes, 0, $bytes.Length); $gz.Dispose()
    $gzSz = $ms1.Length; $ms1.Dispose()

    $ms2 = [System.IO.MemoryStream]::new()
    $br  = [System.IO.Compression.BrotliStream]::new($ms2, $opts, $true)
    $br.Write($bytes, 0, $bytes.Length); $br.Dispose()
    $brSz = $ms2.Length; $ms2.Dispose()

    return [PSCustomObject]@{ GZip = $gzSz; Brotli = $brSz }
}

function Format-Bytes([long]$b) {
    if ($b -ge 1MB) { return '{0:F2} MB' -f ($b / 1MB) }
    if ($b -ge 1KB) { return '{0:F1} KB' -f ($b / 1KB) }
    return "$b B"
}

# ─── FASE 1: Geracao dos datasets originais ───────────────────────────────────
Write-Host '[1/4] Gerando 10 datasets originais em temp\ ...' -ForegroundColor Yellow
$t1 = Get-Date

[TEIA.P19.Demo]::GenJsonApiEvents("$TempDir\json_api_events.json",  40000)
[TEIA.P19.Demo]::GenJsonProducts( "$TempDir\json_products.json",    25000)
[TEIA.P19.Demo]::GenJsonMetrics(  "$TempDir\json_metrics.json",     35000)
[TEIA.P19.Demo]::GenCsvSensorData("$TempDir\csv_sensor_data.csv",   70000)
[TEIA.P19.Demo]::GenCsvTransactions("$TempDir\csv_transactions.csv",55000)
[TEIA.P19.Demo]::GenCsvServerLogs("$TempDir\csv_server_logs.csv",   80000)
[TEIA.P19.Demo]::GenCsvOrders(    "$TempDir\csv_orders.csv",        50000)
[TEIA.P19.Demo]::GenSvgScatter(   "$TempDir\svg_scatter_20k.svg",   20000)
[TEIA.P19.Demo]::GenSvgNetwork(   "$TempDir\svg_network_10k.svg",   10000, 15000)
[TEIA.P19.Demo]::GenSvgHeatmap(   "$TempDir\svg_heatmap_20k.svg",   200, 100)

$elapsed1 = [Math]::Round(((Get-Date) - $t1).TotalSeconds, 1)
Write-Host "    Concluido em ${elapsed1}s" -ForegroundColor DarkGray

# ─── FASE 2: Reconstrucao via decoders + seeds (Storage as Computation) ───────
Write-Host '[2/4] Reconstruindo a partir de seeds + decoders (Storage as Computation) ...' -ForegroundColor Yellow
$t2 = Get-Date

$decoderMap = @(
    @{ Dec='Decode-json_api_events.ps1';  Seed='seed_json_api_events.json';  Out='json_api_events.json'  }
    @{ Dec='Decode-json_products.ps1';    Seed='seed_json_products.json';    Out='json_products.json'    }
    @{ Dec='Decode-json_metrics.ps1';     Seed='seed_json_metrics.json';     Out='json_metrics.json'     }
    @{ Dec='Decode-csv_sensor_data.ps1';  Seed='seed_csv_sensor_data.json';  Out='csv_sensor_data.csv'   }
    @{ Dec='Decode-csv_transactions.ps1'; Seed='seed_csv_transactions.json'; Out='csv_transactions.csv'  }
    @{ Dec='Decode-csv_server_logs.ps1';  Seed='seed_csv_server_logs.json';  Out='csv_server_logs.csv'   }
    @{ Dec='Decode-csv_orders.ps1';       Seed='seed_csv_orders.json';       Out='csv_orders.csv'        }
    @{ Dec='Decode-svg_scatter_20k.ps1';  Seed='seed_svg_scatter_20k.json';  Out='svg_scatter_20k.svg'   }
    @{ Dec='Decode-svg_network_10k.ps1';  Seed='seed_svg_network_10k.json';  Out='svg_network_10k.svg'   }
    @{ Dec='Decode-svg_heatmap_20k.ps1';  Seed='seed_svg_heatmap_20k.json';  Out='svg_heatmap_20k.svg'   }
)

foreach ($d in $decoderMap) {
    & "$DecDir\$($d.Dec)" `
        -SeedFile   "$SeedDir\$($d.Seed)" `
        -OutputFile "$OutDir\$($d.Out)" 2>&1 | Out-Null
}

$elapsed2 = [Math]::Round(((Get-Date) - $t2).TotalSeconds, 1)
Write-Host "    Concluido em ${elapsed2}s" -ForegroundColor DarkGray

# ─── FASE 3: Medicao e verificacao ────────────────────────────────────────────
Write-Host '[3/4] Medindo baselines e verificando SHA-256 ...' -ForegroundColor Yellow
$t3 = Get-Date

$fileList = @(
    'json_api_events.json', 'json_products.json', 'json_metrics.json',
    'csv_sensor_data.csv',  'csv_transactions.csv', 'csv_server_logs.csv', 'csv_orders.csv',
    'svg_scatter_20k.svg',  'svg_network_10k.svg',  'svg_heatmap_20k.svg'
)

$results   = @()
$allPass   = $true
$totalSaved = [long]0

foreach ($f in $fileList) {
    $base    = $f -replace '\.[^.]+$'
    $orig    = (Get-Item "$TempDir\$f").Length
    $bl      = Measure-Baselines "$TempDir\$f"
    $seedSz  = (Get-Item "$SeedDir\seed_${base}.json").Length
    $decSz   = (Get-Item "$DecDir\Decode-${base}.ps1").Length
    $teiaSum = $seedSz + $decSz
    $best    = [Math]::Min($bl.GZip, $bl.Brotli)
    $saved   = $best - $teiaSum
    $totalSaved += $saved
    $deltaPct= [Math]::Round($saved / $best * 100, 1)
    $shaOrig = [TEIA.P19.Demo]::Sha256("$TempDir\$f")
    $shaDec  = [TEIA.P19.Demo]::Sha256("$OutDir\$f")
    $pass    = ($shaOrig -eq $shaDec)
    if (-not $pass) { $allPass = $false }

    $results += [PSCustomObject]@{
        File     = $f
        Orig     = $orig
        GZip     = $bl.GZip
        Brotli   = $bl.Brotli
        TEIA     = $teiaSum
        Best     = $best
        DeltaPct = $deltaPct
        Pass     = $pass
    }
}

$elapsed3 = [Math]::Round(((Get-Date) - $t3).TotalSeconds, 1)
Write-Host "    Concluido em ${elapsed3}s" -ForegroundColor DarkGray

# ─── FASE 4: Tabela de resultados ─────────────────────────────────────────────
Write-Host ''
Write-Host '[4/4] RESULTADOS:' -ForegroundColor Yellow
Write-Host ''

$header = '{0,-28} {1,9} {2,9} {3,9} {4,9} {5,16} {6}' -f `
    'Arquivo', 'Original', 'GZip', 'Brotli', 'TEIA', 'Delta (Ganho)', 'SHA-256'
$sep    = '-' * $w

Write-Host $sep -ForegroundColor DarkGray
Write-Host $header -ForegroundColor Cyan
Write-Host $sep -ForegroundColor DarkGray

foreach ($r in $results) {
    $mark  = if ($r.Pass) { 'PASS' } else { 'FAIL' }
    $color = if ($r.Pass) { 'Green' } else { 'Red' }
    $line = '{0,-28} {1,9} {2,9} {3,9} {4,9} {5,14}%  {6}' -f `
        $r.File,
        (Format-Bytes $r.Orig),
        (Format-Bytes $r.GZip),
        (Format-Bytes $r.Brotli),
        (Format-Bytes $r.TEIA),
        $r.DeltaPct,
        $mark
    Write-Host $line -ForegroundColor $color
}

Write-Host $sep -ForegroundColor DarkGray
Write-Host ''

$passCount = ($results | Where-Object { $_.Pass }).Count
$totalSavedFmt = Format-Bytes $totalSaved

if ($allPass) {
    Write-Host "  VEREDICTO: $passCount/10 SHA-256 PASS  |  Delta total ganho: $totalSavedFmt vs. melhor classico" -ForegroundColor Green
} else {
    $fail = ($results | Where-Object { -not $_.Pass } | ForEach-Object { $_.File }) -join ', '
    Write-Host "  VEREDICTO: FALHAS DETECTADAS — $fail" -ForegroundColor Red
}

$totalElapsed = [Math]::Round(((Get-Date) - $t1).TotalSeconds, 1)
Write-Host "  Tempo total: ${totalElapsed}s" -ForegroundColor DarkGray
Write-Host ''

# ─── Limpeza ──────────────────────────────────────────────────────────────────
Write-Host 'Limpando arquivos temporarios...' -ForegroundColor DarkGray
Remove-Item -Recurse -Force $TempDir
Remove-Item -Recurse -Force $OutDir
Write-Host 'Limpeza concluida. Nenhum dataset residual deixado na maquina.' -ForegroundColor DarkGray
Write-Host ''
Write-Host ('=' * $w) -ForegroundColor Cyan
Write-Host '  TEIA P19.0 Demo encerrada.' -ForegroundColor Cyan
Write-Host ('=' * $w) -ForegroundColor Cyan
Write-Host ''
