[CmdletBinding()]
param()
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$B          = 'D:\TEIA_CLAUDE_AWAKENING'
$AuditDir   = "$B\sandbox\audit_p18"
$GenDir     = "$AuditDir\generated"
$DecDir     = "$AuditDir\decoded"
$SeedDir    = "$B\sandbox\crucible_p17\seeds"
$DecoderDir = "$B\sandbox\crucible_p17\decoders"

foreach ($d in @($AuditDir, $GenDir, $DecDir)) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

Write-Host ''
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host '  TEIA P18.0 — AUDITORIA DE REPRODUTIBILIDADE (CLAIM-SAFE)' -ForegroundColor Cyan
Write-Host '  Prova: Hash(Generator) == Hash(Decoder) == sha256_original' -ForegroundColor Cyan
Write-Host ('=' * 72) -ForegroundColor Cyan

# ── Motor C# isolado — namespace TEIA.P18 para evitar conflito com P17 ────────
if (-not ([System.Management.Automation.PSTypeName]'TEIA.P18.AuditGen').Type) {
    Add-Type @"
using System;
using System.IO;
using System.Text;
using System.Security.Cryptography;

namespace TEIA.P18 {
public static class AuditGen {

    static readonly DateTime BASE = new DateTime(2024,1,1,0,0,0,DateTimeKind.Utc);
    static string Ts(long i,long s)       => BASE.AddSeconds(i*s).ToString("yyyy-MM-ddTHH:mm:ssZ");
    static string DateOnly(long i,long s) => BASE.AddSeconds(i*s).ToString("yyyy-MM-dd");
    static long   MC(long i,long m,long a,long mod,long min) => (i*m+a)%mod+min;

    public static string Sha256File(string path) {
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

    public static void GenSvgNetwork(string p, int nodeCount, int edgeCount) {
        string[] nf={"#3498db","#e74c3c","#2ecc71","#f39c12"};
        string[] es={"#95a5a6","#7f8c8d","#bdc3c7"};
        int[] ncx=new int[nodeCount]; int[] ncy=new int[nodeCount];
        for(int j=0;j<nodeCount;j++){ncx[j]=(int)MC(j,41,50,701,50);ncy[j]=(int)MC(j,59,50,501,50);}
        using var sw = new StreamWriter(p,false,new UTF8Encoding(false));
        sw.WriteLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        sw.WriteLine("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"800\" height=\"600\" viewBox=\"0 0 800 600\">");
        for(int j=0;j<nodeCount;j++)
            sw.WriteLine("<circle cx=\""+ncx[j]+"\" cy=\""+ncy[j]+"\" r=\"6\" fill=\""+nf[j%4]+"\"/>");
        for(int e=0;e<edgeCount;e++){
            int src=(int)MC(e,37,0,nodeCount,0);
            int dst=(int)MC(e,53,nodeCount/2,nodeCount,0);
            sw.WriteLine("<line x1=\""+ncx[src]+"\" y1=\""+ncy[src]
                +"\" x2=\""+ncx[dst]+"\" y2=\""+ncy[dst]
                +"\" stroke=\""+es[e%3]+"\" stroke-width=\"1\"/>");
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
} // namespace TEIA.P18
"@
}

# ── FASE 1: Geracao isolada em audit_p18\generated\ ──────────────────────────
Write-Host "`n[FASE 1] Regeneracao isolada em $GenDir" -ForegroundColor Yellow

$s1 = Get-Content "$SeedDir\seed_json_api_events.json"  | ConvertFrom-Json
$s2 = Get-Content "$SeedDir\seed_json_products.json"    | ConvertFrom-Json
$s3 = Get-Content "$SeedDir\seed_json_metrics.json"     | ConvertFrom-Json
$s4 = Get-Content "$SeedDir\seed_csv_sensor_data.json"  | ConvertFrom-Json
$s5 = Get-Content "$SeedDir\seed_csv_transactions.json" | ConvertFrom-Json
$s6 = Get-Content "$SeedDir\seed_csv_server_logs.json"  | ConvertFrom-Json
$s7 = Get-Content "$SeedDir\seed_csv_orders.json"       | ConvertFrom-Json
$s8 = Get-Content "$SeedDir\seed_svg_scatter_20k.json"  | ConvertFrom-Json
$s9 = Get-Content "$SeedDir\seed_svg_network_10k.json"  | ConvertFrom-Json
$s10= Get-Content "$SeedDir\seed_svg_heatmap_20k.json"  | ConvertFrom-Json

[TEIA.P18.AuditGen]::GenJsonApiEvents("$GenDir\json_api_events.json",  [int]$s1.count)
Write-Host "  gen json_api_events.json" -ForegroundColor DarkGray
[TEIA.P18.AuditGen]::GenJsonProducts( "$GenDir\json_products.json",    [int]$s2.count)
Write-Host "  gen json_products.json"   -ForegroundColor DarkGray
[TEIA.P18.AuditGen]::GenJsonMetrics(  "$GenDir\json_metrics.json",     [int]$s3.count)
Write-Host "  gen json_metrics.json"    -ForegroundColor DarkGray
[TEIA.P18.AuditGen]::GenCsvSensorData("$GenDir\csv_sensor_data.csv",   [int]$s4.count)
Write-Host "  gen csv_sensor_data.csv"  -ForegroundColor DarkGray
[TEIA.P18.AuditGen]::GenCsvTransactions("$GenDir\csv_transactions.csv",[int]$s5.count)
Write-Host "  gen csv_transactions.csv" -ForegroundColor DarkGray
[TEIA.P18.AuditGen]::GenCsvServerLogs("$GenDir\csv_server_logs.csv",   [int]$s6.count)
Write-Host "  gen csv_server_logs.csv"  -ForegroundColor DarkGray
[TEIA.P18.AuditGen]::GenCsvOrders(    "$GenDir\csv_orders.csv",        [int]$s7.count)
Write-Host "  gen csv_orders.csv"       -ForegroundColor DarkGray
[TEIA.P18.AuditGen]::GenSvgScatter(   "$GenDir\svg_scatter_20k.svg",   [int]$s8.count)
Write-Host "  gen svg_scatter_20k.svg"  -ForegroundColor DarkGray
[TEIA.P18.AuditGen]::GenSvgNetwork(   "$GenDir\svg_network_10k.svg",   [int]$s9.node_count, [int]$s9.edge_count)
Write-Host "  gen svg_network_10k.svg"  -ForegroundColor DarkGray
[TEIA.P18.AuditGen]::GenSvgHeatmap(   "$GenDir\svg_heatmap_20k.svg",   [int]$s10.cols, [int]$s10.rows)
Write-Host "  gen svg_heatmap_20k.svg"  -ForegroundColor DarkGray

# ── FASE 2: Decodificacao isolada em audit_p18\decoded\ ──────────────────────
Write-Host "`n[FASE 2] Decodificacao isolada em $DecDir" -ForegroundColor Yellow

$decoders = @(
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

foreach ($d in $decoders) {
    $decScript  = "$DecoderDir\$($d.Dec)"
    $seedFile   = "$SeedDir\$($d.Seed)"
    $outputFile = "$DecDir\$($d.Out)"
    & $decScript -SeedFile $seedFile -OutputFile $outputFile 2>&1 | Out-Null
    Write-Host "  dec $($d.Out)" -ForegroundColor DarkGray
}

# ── FASE 3: Verificacao cruzada SHA-256 ──────────────────────────────────────
Write-Host "`n[FASE 3] Verificacao cruzada SHA-256: Generator == Decoder == Seed" -ForegroundColor Yellow

$files = @(
    @{ Name='json_api_events.json';  Seed=$s1  }
    @{ Name='json_products.json';    Seed=$s2  }
    @{ Name='json_metrics.json';     Seed=$s3  }
    @{ Name='csv_sensor_data.csv';   Seed=$s4  }
    @{ Name='csv_transactions.csv';  Seed=$s5  }
    @{ Name='csv_server_logs.csv';   Seed=$s6  }
    @{ Name='csv_orders.csv';        Seed=$s7  }
    @{ Name='svg_scatter_20k.svg';   Seed=$s8  }
    @{ Name='svg_network_10k.svg';   Seed=$s9  }
    @{ Name='svg_heatmap_20k.svg';   Seed=$s10 }
)

$results = @()
$allPass = $true

foreach ($f in $files) {
    $expected = $f.Seed.sha256_original
    $shaGen   = [TEIA.P18.AuditGen]::Sha256File("$GenDir\$($f.Name)")
    $shaDec   = [TEIA.P18.AuditGen]::Sha256File("$DecDir\$($f.Name)")
    $genOk    = ($shaGen -eq $expected)
    $decOk    = ($shaDec -eq $expected)
    $crossOk  = ($shaGen -eq $shaDec)
    $pass     = $genOk -and $decOk -and $crossOk
    if (-not $pass) { $allPass = $false }

    $color    = if ($pass) { 'Green' } else { 'Red' }
    $mark     = if ($pass) { 'PASS' } else { 'FAIL' }
    $genStr   = if ($genOk)   { 'OK' } else { 'FAIL' }
    $decStr   = if ($decOk)   { 'OK' } else { 'FAIL' }
    $crossStr = if ($crossOk) { 'OK' } else { 'FAIL' }
    Write-Host ("  [{0}] {1,-28}  gen={2}  dec={3}  cross={4}" -f `
        $mark, $f.Name, $genStr, $decStr, $crossStr) -ForegroundColor $color

    $results += [PSCustomObject]@{
        File      = $f.Name
        Expected  = $expected
        ShaGen    = $shaGen
        ShaDec    = $shaDec
        GenMatch  = $genOk
        DecMatch  = $decOk
        CrossMatch= $crossOk
        Status    = $mark
    }
}

# ── Resultado final ───────────────────────────────────────────────────────────
Write-Host ''
Write-Host ('=' * 72) -ForegroundColor Cyan
if ($allPass) {
    $passCount = ($results | Where-Object { $_.Status -eq 'PASS' }).Count
    Write-Host "  RESULTADO: $passCount/10 PASS — IDEMPOTENCIA WRITE==READ PROVADA" -ForegroundColor Green
} else {
    $failList = ($results | Where-Object { $_.Status -eq 'FAIL' } | ForEach-Object { $_.File }) -join ', '
    Write-Host "  RESULTADO: FALHAS DETECTADAS — $failList" -ForegroundColor Red
}
Write-Host ('=' * 72) -ForegroundColor Cyan

# ── Exporta resultado JSON para o manifesto ───────────────────────────────────
$auditReport = @{
    protocol   = 'P18.0'
    date       = (Get-Date -Format 'yyyy-MM-dd')
    total      = $results.Count
    passed     = ($results | Where-Object { $_.Status -eq 'PASS' }).Count
    failed     = ($results | Where-Object { $_.Status -eq 'FAIL' }).Count
    results    = $results
}
$reportPath = "$AuditDir\audit_report_p18.json"
$auditReport | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath -Encoding UTF8
Write-Host "`n  Relatorio JSON salvo em: $reportPath" -ForegroundColor DarkGray

if (-not $allPass) { exit 1 }
