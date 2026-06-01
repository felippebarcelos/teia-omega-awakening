<#
.SYNOPSIS
    Test-DomainCrucible.ps1 — P17.0 Esteira de Dominios Ontoprocedurais

.DESCRIPTION
    Gera 10 datasets sinteticos deterministas (JSON/CSV/SVG) entre 1-5 MB cada,
    executa a Lente Semantica sobre cada arquivo, mede baselines GZip e Brotli,
    grava seeds (.json) e exporta Prompts de Forja para sandbox\crucible_p17\.

    INVARIANTE: "Delta" sempre por extenso. Simbolo matematico proibido.
    IDEMPOTENCIA: Re-execucao produz exatamente os mesmos artefatos (mesmo SHA-256).

.PARAMETER DataDir
    Diretorio de saida dos datasets gerados.

.PARAMETER SeedDir
    Diretorio de saida dos arquivos seed.json.

.PARAMETER PromptDir
    Diretorio de saida dos Prompts de Forja.

.PARAMETER SemanticTool
    Caminho para Analyze-SemanticSchema.ps1.

.PARAMETER SkipGenerate
    Pula a fase de geracao (assume que os arquivos ja existem).
#>
[CmdletBinding()]
param(
    [string]$DataDir      = 'D:\TEIA_CLAUDE_AWAKENING\sandbox\crucible_p17\datasets',
    [string]$SeedDir      = 'D:\TEIA_CLAUDE_AWAKENING\sandbox\crucible_p17\seeds',
    [string]$PromptDir    = 'D:\TEIA_CLAUDE_AWAKENING\sandbox\crucible_p17\prompts',
    [string]$DecoderDir   = 'D:\TEIA_CLAUDE_AWAKENING\sandbox\crucible_p17\decoders',
    [string]$SemanticTool = 'D:\TEIA_CLAUDE_AWAKENING\tools\Analyze-SemanticSchema.ps1',
    [switch]$SkipGenerate
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$enc = New-Object System.Text.UTF8Encoding($false)
$IC  = [System.Globalization.CultureInfo]::InvariantCulture

foreach ($d in @($DataDir, $SeedDir, $PromptDir, $DecoderDir)) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

Write-Host ''
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host '  TEIA P17.0 — DOMAIN CRUCIBLE BENCHMARK' -ForegroundColor Cyan
Write-Host ('=' * 72) -ForegroundColor Cyan

# ── Motor C# de geracao determinista ──────────────────────────────────────────
Add-Type @"
using System;
using System.IO;
using System.Text;
using System.Security.Cryptography;

namespace TEIA.P17 {

public static class Gen {

    static readonly DateTime BASE = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);

    // ── Primitivas de formula ─────────────────────────────────────────────
    static string Ts(long i, long stepSec) =>
        BASE.AddSeconds(i * stepSec).ToString("yyyy-MM-ddTHH:mm:ssZ");

    static string DateOnly(long i, long stepSec) =>
        BASE.AddSeconds(i * stepSec).ToString("yyyy-MM-dd");

    static long MC(long i, long m, long a, long mod, long min) =>
        (i * m + a) % mod + min;

    static string FileSha256(string path) {
        using var sha = SHA256.Create();
        using var fs  = File.OpenRead(path);
        return BitConverter.ToString(sha.ComputeHash(fs)).Replace("-","").ToLower();
    }

    static string JA(string[] arr) {
        var sb = new StringBuilder("[");
        for (int k = 0; k < arr.Length; k++) {
            if (k > 0) sb.Append(',');
            sb.Append('"'); sb.Append(arr[k]); sb.Append('"');
        }
        sb.Append(']'); return sb.ToString();
    }

    static string JIA(int[] arr) {
        var sb = new StringBuilder("[");
        for (int k = 0; k < arr.Length; k++) {
            if (k > 0) sb.Append(','); sb.Append(arr[k]);
        }
        sb.Append(']'); return sb.ToString();
    }

    // ── 01: json_api_events.json ──────────────────────────────────────────
    public static string GenJsonApiEvents(string outPath, string seedPath, int count) {
        string[] levels    = {"INFO","INFO","INFO","INFO","WARN","WARN","ERROR","DEBUG"};
        string[] hosts     = {"web-01","web-02","db-01","cache-01","cache-02"};
        string[] methods   = {"GET","POST","PUT","DELETE"};
        string[] endpoints = {"/api/users","/api/orders","/api/products","/api/auth",
                               "/api/health","/api/metrics","/api/logs","/api/events"};
        int[]    statuses  = {200,201,400,401,404};

        using (var sw = new StreamWriter(outPath, false, new UTF8Encoding(false))) {
            sw.Write("{\"events\":[");
            for (int i = 0; i < count; i++) {
                if (i > 0) sw.Write(',');
                sw.Write(
                    "{\"id\":"     + (i+1) +
                    ",\"ts\":\""  + Ts(i,60) + "\"" +
                    ",\"level\":\"" + levels[i % levels.Length] + "\"" +
                    ",\"host\":\""  + hosts[i % hosts.Length]   + "\"" +
                    ",\"method\":\"" + methods[i % methods.Length] + "\"" +
                    ",\"endpoint\":\"" + endpoints[i % endpoints.Length] + "\"" +
                    ",\"status\":" + statuses[i % statuses.Length] +
                    ",\"lat_ms\":"+ MC(i,17,1000,1999,1) + "}"
                );
            }
            sw.Write("]}");
        }
        string sha = FileSha256(outPath);
        var s = new StringBuilder();
        s.Append("{\"domain\":\"json\",\"file\":\"json_api_events.json\"");
        s.Append(",\"sha256_original\":\"" + sha + "\"");
        s.Append(",\"count\":" + count + ",\"root_key\":\"events\"");
        s.Append(",\"fields\":[");
        s.Append("{\"name\":\"id\",\"type\":\"seq\",\"start\":1,\"step\":1,\"fmt\":\"int\"}");
        s.Append(",{\"name\":\"ts\",\"type\":\"ts_seq\",\"step_sec\":60,\"fmt\":\"str\"}");
        s.Append(",{\"name\":\"level\",\"type\":\"cycle\",\"period\":" + levels.Length + ",\"values\":" + JA(levels) + ",\"fmt\":\"str\"}");
        s.Append(",{\"name\":\"host\",\"type\":\"cycle\",\"period\":" + hosts.Length + ",\"values\":" + JA(hosts) + ",\"fmt\":\"str\"}");
        s.Append(",{\"name\":\"method\",\"type\":\"cycle\",\"period\":" + methods.Length + ",\"values\":" + JA(methods) + ",\"fmt\":\"str\"}");
        s.Append(",{\"name\":\"endpoint\",\"type\":\"cycle\",\"period\":" + endpoints.Length + ",\"values\":" + JA(endpoints) + ",\"fmt\":\"str\"}");
        s.Append(",{\"name\":\"status\",\"type\":\"cycle\",\"period\":" + statuses.Length + ",\"values\":" + JIA(statuses) + ",\"fmt\":\"int\"}");
        s.Append(",{\"name\":\"lat_ms\",\"type\":\"mc\",\"m\":17,\"a\":1000,\"mod\":1999,\"min\":1,\"fmt\":\"int\"}");
        s.Append("]}");
        File.WriteAllText(seedPath, s.ToString(), new UTF8Encoding(false));
        return sha;
    }

    // ── 02: json_products.json ────────────────────────────────────────────
    public static string GenJsonProducts(string outPath, string seedPath, int count) {
        string[] cats  = {"electronics","clothing","food","sports","home","beauty","books",
                          "toys","automotive","garden","health","jewelry","music","office","pets"};
        string[] brands= {"AlphaGen","BetaCorp","GammaWorks","DeltaLabs","EpsilonTech",
                          "ZetaSystems","EtaCo","ThetaInc","IotaGroup","KappaWorks",
                          "LambdaNet","MuTech","NuDesign","XiMakers","OmicronBrand",
                          "PiFactory","RhoLogic","SigmaForm","TauSoft","UpsilonPro"};
        string[] active= {"true","true","true","true","true","true","true","true","true","false"};

        using (var sw = new StreamWriter(outPath, false, new UTF8Encoding(false))) {
            sw.Write("{\"products\":[");
            for (int i = 0; i < count; i++) {
                if (i > 0) sw.Write(',');
                long price = MC(i, 31, 5000, 99900, 100);
                long stock = MC(i, 7, 0, 500, 0);
                sw.Write(
                    "{\"id\":"    + (i+1) +
                    ",\"sku\":\"SKU-" + (i+1).ToString("D6") + "\"" +
                    ",\"category\":\"" + cats[i % cats.Length] + "\"" +
                    ",\"brand\":\""    + brands[i % brands.Length] + "\"" +
                    ",\"price_cents\":" + price +
                    ",\"stock\":"       + stock +
                    ",\"active\":"      + active[i % active.Length] + "}"
                );
            }
            sw.Write("]}");
        }
        string sha = FileSha256(outPath);
        var s = new StringBuilder();
        s.Append("{\"domain\":\"json\",\"file\":\"json_products.json\"");
        s.Append(",\"sha256_original\":\"" + sha + "\"");
        s.Append(",\"count\":" + count + ",\"root_key\":\"products\"");
        s.Append(",\"fields\":[");
        s.Append("{\"name\":\"id\",\"type\":\"seq\",\"start\":1,\"step\":1,\"fmt\":\"int\"}");
        s.Append(",{\"name\":\"sku\",\"type\":\"sku_template\",\"prefix\":\"SKU-\",\"digits\":6,\"fmt\":\"str\"}");
        s.Append(",{\"name\":\"category\",\"type\":\"cycle\",\"period\":" + cats.Length + ",\"values\":" + JA(cats) + ",\"fmt\":\"str\"}");
        s.Append(",{\"name\":\"brand\",\"type\":\"cycle\",\"period\":" + brands.Length + ",\"values\":" + JA(brands) + ",\"fmt\":\"str\"}");
        s.Append(",{\"name\":\"price_cents\",\"type\":\"mc\",\"m\":31,\"a\":5000,\"mod\":99900,\"min\":100,\"fmt\":\"int\"}");
        s.Append(",{\"name\":\"stock\",\"type\":\"mc\",\"m\":7,\"a\":0,\"mod\":500,\"min\":0,\"fmt\":\"int\"}");
        s.Append(",{\"name\":\"active\",\"type\":\"cycle\",\"period\":" + active.Length + ",\"values\":" + JA(active) + ",\"fmt\":\"raw\"}");
        s.Append("]}");
        File.WriteAllText(seedPath, s.ToString(), new UTF8Encoding(false));
        return sha;
    }

    // ── 03: json_metrics.json ─────────────────────────────────────────────
    public static string GenJsonMetrics(string outPath, string seedPath, int count) {
        string[] regions  = {"us-east","us-west","eu-central","ap-south","ap-northeast"};
        string[] services = {"auth-svc","api-gw","db-primary","cache-redis","search-svc",
                             "billing-svc","mail-svc","media-svc","analytics-svc",
                             "storage-svc","queue-svc","monitor-svc"};
        string[] metrics  = {"cpu_percent","mem_percent","disk_io","net_rx","net_tx","req_rate"};
        string[] units    = {"percent","percent","MB/s","KB/s","KB/s","req/s"};

        using (var sw = new StreamWriter(outPath, false, new UTF8Encoding(false))) {
            sw.Write("{\"metrics\":[");
            for (int i = 0; i < count; i++) {
                if (i > 0) sw.Write(',');
                int mIdx = i % metrics.Length;
                sw.Write(
                    "{\"id\":"    + (i+1) +
                    ",\"ts\":\""  + Ts(i,30) + "\"" +
                    ",\"region\":\"" + regions[i % regions.Length] + "\"" +
                    ",\"service\":\"" + services[i % services.Length] + "\"" +
                    ",\"metric\":\"" + metrics[mIdx] + "\"" +
                    ",\"value\":"  + MC(i,23,0,100,0) +
                    ",\"unit\":\"" + units[mIdx] + "\"}"
                );
            }
            sw.Write("]}");
        }
        string sha = FileSha256(outPath);
        var s = new StringBuilder();
        s.Append("{\"domain\":\"json\",\"file\":\"json_metrics.json\"");
        s.Append(",\"sha256_original\":\"" + sha + "\"");
        s.Append(",\"count\":" + count + ",\"root_key\":\"metrics\"");
        s.Append(",\"fields\":[");
        s.Append("{\"name\":\"id\",\"type\":\"seq\",\"start\":1,\"step\":1,\"fmt\":\"int\"}");
        s.Append(",{\"name\":\"ts\",\"type\":\"ts_seq\",\"step_sec\":30,\"fmt\":\"str\"}");
        s.Append(",{\"name\":\"region\",\"type\":\"cycle\",\"period\":" + regions.Length + ",\"values\":" + JA(regions) + ",\"fmt\":\"str\"}");
        s.Append(",{\"name\":\"service\",\"type\":\"cycle\",\"period\":" + services.Length + ",\"values\":" + JA(services) + ",\"fmt\":\"str\"}");
        s.Append(",{\"name\":\"metric\",\"type\":\"cycle\",\"period\":" + metrics.Length + ",\"values\":" + JA(metrics) + ",\"fmt\":\"str\"}");
        s.Append(",{\"name\":\"value\",\"type\":\"mc\",\"m\":23,\"a\":0,\"mod\":100,\"min\":0,\"fmt\":\"int\"}");
        s.Append(",{\"name\":\"unit\",\"type\":\"cycle\",\"period\":" + units.Length + ",\"values\":" + JA(units) + ",\"fmt\":\"str\"}");
        s.Append("]}");
        File.WriteAllText(seedPath, s.ToString(), new UTF8Encoding(false));
        return sha;
    }

    // ── 04: csv_sensor_data.csv ───────────────────────────────────────────
    public static string GenCsvSensorData(string outPath, string seedPath, int count) {
        string[] locs   = {"room_a","room_b","room_c","room_d","room_e",
                           "lab_1","lab_2","server_1","server_2","warehouse_a",
                           "warehouse_b","office_1","office_2","lobby","roof",
                           "basement","floor_1","floor_2","floor_3","floor_4"};
        string[] types  = {"temperature","humidity","pressure","co2","light"};
        string[] status = {"OK","OK","OK","OK","OK","OK","OK","OK","OK","WARN"};

        using (var sw = new StreamWriter(outPath, false, new UTF8Encoding(false))) {
            sw.WriteLine("id,timestamp,sensor_id,location,type,reading,status");
            for (int i = 0; i < count; i++) {
                sw.Write((i+1));                    sw.Write(',');
                sw.Write(Ts(i,60));                 sw.Write(',');
                sw.Write("SENSOR-" + (MC(i,11,0,50,1)).ToString("D3")); sw.Write(',');
                sw.Write(locs[i % locs.Length]);    sw.Write(',');
                sw.Write(types[i % types.Length]);  sw.Write(',');
                sw.Write(MC(i,19,0,1000,0));        sw.Write(',');
                sw.WriteLine(status[i % status.Length]);
            }
        }
        string sha = FileSha256(outPath);
        var s = new StringBuilder();
        s.Append("{\"domain\":\"csv\",\"file\":\"csv_sensor_data.csv\"");
        s.Append(",\"sha256_original\":\"" + sha + "\"");
        s.Append(",\"count\":" + count);
        s.Append(",\"header\":\"id,timestamp,sensor_id,location,type,reading,status\"");
        s.Append(",\"fields\":[");
        s.Append("{\"name\":\"id\",\"type\":\"seq\",\"start\":1,\"step\":1}");
        s.Append(",{\"name\":\"timestamp\",\"type\":\"ts_seq\",\"step_sec\":60}");
        s.Append(",{\"name\":\"sensor_id\",\"type\":\"mc_pad\",\"m\":11,\"a\":0,\"mod\":50,\"min\":1,\"prefix\":\"SENSOR-\",\"digits\":3}");
        s.Append(",{\"name\":\"location\",\"type\":\"cycle\",\"period\":" + locs.Length + ",\"values\":" + JA(locs) + "}");
        s.Append(",{\"name\":\"type\",\"type\":\"cycle\",\"period\":" + types.Length + ",\"values\":" + JA(types) + "}");
        s.Append(",{\"name\":\"reading\",\"type\":\"mc\",\"m\":19,\"a\":0,\"mod\":1000,\"min\":0}");
        s.Append(",{\"name\":\"status\",\"type\":\"cycle\",\"period\":" + status.Length + ",\"values\":" + JA(status) + "}");
        s.Append("]}");
        File.WriteAllText(seedPath, s.ToString(), new UTF8Encoding(false));
        return sha;
    }

    // ── 05: csv_transactions.csv ──────────────────────────────────────────
    public static string GenCsvTransactions(string outPath, string seedPath, int count) {
        string[] regions = {"north","south","east","west","central"};

        using (var sw = new StreamWriter(outPath, false, new UTF8Encoding(false))) {
            sw.WriteLine("txn_id,date,cust_id,product_id,quantity,unit_price,region");
            for (int i = 0; i < count; i++) {
                sw.Write(1000001 + i);                          sw.Write(',');
                sw.Write(DateOnly(i, 900));                     sw.Write(',');
                sw.Write("C" + MC(i,41,0,500,1001).ToString("D4")); sw.Write(',');
                sw.Write("P" + MC(i,13,0,200,1).ToString("D4"));    sw.Write(',');
                sw.Write(MC(i,3,1,20,1));                       sw.Write(',');
                sw.Write(MC(i,37,100,9900,100));                sw.Write(',');
                sw.WriteLine(regions[i % regions.Length]);
            }
        }
        string sha = FileSha256(outPath);
        var s = new StringBuilder();
        s.Append("{\"domain\":\"csv\",\"file\":\"csv_transactions.csv\"");
        s.Append(",\"sha256_original\":\"" + sha + "\"");
        s.Append(",\"count\":" + count);
        s.Append(",\"header\":\"txn_id,date,cust_id,product_id,quantity,unit_price,region\"");
        s.Append(",\"fields\":[");
        s.Append("{\"name\":\"txn_id\",\"type\":\"seq\",\"start\":1000001,\"step\":1}");
        s.Append(",{\"name\":\"date\",\"type\":\"ts_date\",\"step_sec\":900}");
        s.Append(",{\"name\":\"cust_id\",\"type\":\"mc_pad\",\"m\":41,\"a\":0,\"mod\":500,\"min\":1001,\"prefix\":\"C\",\"digits\":4}");
        s.Append(",{\"name\":\"product_id\",\"type\":\"mc_pad\",\"m\":13,\"a\":0,\"mod\":200,\"min\":1,\"prefix\":\"P\",\"digits\":4}");
        s.Append(",{\"name\":\"quantity\",\"type\":\"mc\",\"m\":3,\"a\":1,\"mod\":20,\"min\":1}");
        s.Append(",{\"name\":\"unit_price\",\"type\":\"mc\",\"m\":37,\"a\":100,\"mod\":9900,\"min\":100}");
        s.Append(",{\"name\":\"region\",\"type\":\"cycle\",\"period\":" + regions.Length + ",\"values\":" + JA(regions) + "}");
        s.Append("]}");
        File.WriteAllText(seedPath, s.ToString(), new UTF8Encoding(false));
        return sha;
    }

    // ── 06: csv_server_logs.csv ───────────────────────────────────────────
    public static string GenCsvServerLogs(string outPath, string seedPath, int count) {
        string[] servers = {"srv-01","srv-02","srv-03","srv-04","srv-05","srv-06","srv-07","srv-08"};
        string[] levels  = {"INFO","INFO","INFO","INFO","WARN","WARN","ERROR","DEBUG"};
        string[] modules = {"auth","api","db","cache","queue","storage","scheduler",
                            "notifier","reporter","exporter","importer","validator"};
        string[] status  = {"200","200","200","200","200","404","500","202"};

        using (var sw = new StreamWriter(outPath, false, new UTF8Encoding(false))) {
            sw.WriteLine("line_id,ts,server,level,module,duration_ms,status");
            for (int i = 0; i < count; i++) {
                sw.Write((i+1));                          sw.Write(',');
                sw.Write(Ts(i,30));                       sw.Write(',');
                sw.Write(servers[i % servers.Length]);    sw.Write(',');
                sw.Write(levels[i % levels.Length]);      sw.Write(',');
                sw.Write(modules[i % modules.Length]);    sw.Write(',');
                sw.Write(MC(i,23,50,200,10));             sw.Write(',');
                sw.WriteLine(status[i % status.Length]);
            }
        }
        string sha = FileSha256(outPath);
        var s = new StringBuilder();
        s.Append("{\"domain\":\"csv\",\"file\":\"csv_server_logs.csv\"");
        s.Append(",\"sha256_original\":\"" + sha + "\"");
        s.Append(",\"count\":" + count);
        s.Append(",\"header\":\"line_id,ts,server,level,module,duration_ms,status\"");
        s.Append(",\"fields\":[");
        s.Append("{\"name\":\"line_id\",\"type\":\"seq\",\"start\":1,\"step\":1}");
        s.Append(",{\"name\":\"ts\",\"type\":\"ts_seq\",\"step_sec\":30}");
        s.Append(",{\"name\":\"server\",\"type\":\"cycle\",\"period\":" + servers.Length + ",\"values\":" + JA(servers) + "}");
        s.Append(",{\"name\":\"level\",\"type\":\"cycle\",\"period\":" + levels.Length + ",\"values\":" + JA(levels) + "}");
        s.Append(",{\"name\":\"module\",\"type\":\"cycle\",\"period\":" + modules.Length + ",\"values\":" + JA(modules) + "}");
        s.Append(",{\"name\":\"duration_ms\",\"type\":\"mc\",\"m\":23,\"a\":50,\"mod\":200,\"min\":10}");
        s.Append(",{\"name\":\"status\",\"type\":\"cycle\",\"period\":" + status.Length + ",\"values\":" + JA(status) + "}");
        s.Append("]}");
        File.WriteAllText(seedPath, s.ToString(), new UTF8Encoding(false));
        return sha;
    }

    // ── 07: csv_orders.csv ───────────────────────────────────────────────
    public static string GenCsvOrders(string outPath, string seedPath, int count) {
        string[] sts    = {"pending","processing","shipped","delivered","cancelled"};
        string[] prios  = {"normal","normal","normal","high","urgent"};
        string[] ctypes = {"individual","business","premium","enterprise"};
        string[] ctries = {"US","CA","MX","BR","AR","GB","DE","FR","IT","ES","NL","SE",
                           "NO","DK","FI","PL","RU","JP","CN","KR","AU","NZ","IN","ZA","NG"};

        using (var sw = new StreamWriter(outPath, false, new UTF8Encoding(false))) {
            sw.WriteLine("order_id,created_at,status,priority,customer_type,items_count,country");
            for (int i = 0; i < count; i++) {
                sw.Write(5000001 + i);                     sw.Write(',');
                sw.Write(Ts(i,120));                       sw.Write(',');
                sw.Write(sts[i % sts.Length]);             sw.Write(',');
                sw.Write(prios[i % prios.Length]);         sw.Write(',');
                sw.Write(ctypes[i % ctypes.Length]);       sw.Write(',');
                sw.Write(MC(i,7,1,15,1));                  sw.Write(',');
                sw.WriteLine(ctries[i % ctries.Length]);
            }
        }
        string sha = FileSha256(outPath);
        var s = new StringBuilder();
        s.Append("{\"domain\":\"csv\",\"file\":\"csv_orders.csv\"");
        s.Append(",\"sha256_original\":\"" + sha + "\"");
        s.Append(",\"count\":" + count);
        s.Append(",\"header\":\"order_id,created_at,status,priority,customer_type,items_count,country\"");
        s.Append(",\"fields\":[");
        s.Append("{\"name\":\"order_id\",\"type\":\"seq\",\"start\":5000001,\"step\":1}");
        s.Append(",{\"name\":\"created_at\",\"type\":\"ts_seq\",\"step_sec\":120}");
        s.Append(",{\"name\":\"status\",\"type\":\"cycle\",\"period\":" + sts.Length + ",\"values\":" + JA(sts) + "}");
        s.Append(",{\"name\":\"priority\",\"type\":\"cycle\",\"period\":" + prios.Length + ",\"values\":" + JA(prios) + "}");
        s.Append(",{\"name\":\"customer_type\",\"type\":\"cycle\",\"period\":" + ctypes.Length + ",\"values\":" + JA(ctypes) + "}");
        s.Append(",{\"name\":\"items_count\",\"type\":\"mc\",\"m\":7,\"a\":1,\"mod\":15,\"min\":1}");
        s.Append(",{\"name\":\"country\",\"type\":\"cycle\",\"period\":" + ctries.Length + ",\"values\":" + JA(ctries) + "}");
        s.Append("]}");
        File.WriteAllText(seedPath, s.ToString(), new UTF8Encoding(false));
        return sha;
    }

    // ── 08: svg_scatter_20k.svg ───────────────────────────────────────────
    public static string GenSvgScatter(string outPath, string seedPath, int count) {
        string[] fills = {"#3498db","#e74c3c","#2ecc71","#f39c12","#9b59b6"};
        int[]    radii = {3, 5, 8};

        using (var sw = new StreamWriter(outPath, false, new UTF8Encoding(false))) {
            sw.WriteLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
            sw.WriteLine("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"800\" height=\"600\" viewBox=\"0 0 800 600\">");
            for (int i = 0; i < count; i++) {
                long cx = MC(i, 37, 20, 761, 20);
                long cy = MC(i, 53, 20, 561, 20);
                int  r  = radii[i % radii.Length];
                string f = fills[i % fills.Length];
                sw.WriteLine("<circle cx=\"" + cx + "\" cy=\"" + cy + "\" r=\"" + r + "\" fill=\"" + f + "\"/>");
            }
            sw.WriteLine("</svg>");
        }
        string sha = FileSha256(outPath);
        var s = new StringBuilder();
        s.Append("{\"domain\":\"svg\",\"file\":\"svg_scatter_20k.svg\"");
        s.Append(",\"sha256_original\":\"" + sha + "\"");
        s.Append(",\"count\":" + count);
        s.Append(",\"svg_width\":800,\"svg_height\":600");
        s.Append(",\"element\":\"circle\"");
        s.Append(",\"fields\":[");
        s.Append("{\"name\":\"cx\",\"type\":\"mc\",\"m\":37,\"a\":20,\"mod\":761,\"min\":20,\"fmt\":\"int\"}");
        s.Append(",{\"name\":\"cy\",\"type\":\"mc\",\"m\":53,\"a\":20,\"mod\":561,\"min\":20,\"fmt\":\"int\"}");
        s.Append(",{\"name\":\"r\",\"type\":\"cycle\",\"period\":" + radii.Length + ",\"values\":" + JIA(radii) + ",\"fmt\":\"int\"}");
        s.Append(",{\"name\":\"fill\",\"type\":\"cycle\",\"period\":" + fills.Length + ",\"values\":" + JA(fills) + ",\"fmt\":\"str\"}");
        s.Append("]}");
        File.WriteAllText(seedPath, s.ToString(), new UTF8Encoding(false));
        return sha;
    }

    // ── 09: svg_network_10k.svg ───────────────────────────────────────────
    public static string GenSvgNetwork(string outPath, string seedPath, int nodeCount, int edgeCount) {
        string[] nFills = {"#3498db","#e74c3c","#2ecc71","#f39c12"};
        string[] eStrokes = {"#95a5a6","#7f8c8d","#bdc3c7"};

        // Pre-compute node positions
        int[] ncx = new int[nodeCount];
        int[] ncy = new int[nodeCount];
        for (int j = 0; j < nodeCount; j++) {
            ncx[j] = (int)MC(j, 41, 50, 701, 50);
            ncy[j] = (int)MC(j, 59, 50, 501, 50);
        }

        using (var sw = new StreamWriter(outPath, false, new UTF8Encoding(false))) {
            sw.WriteLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
            sw.WriteLine("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"800\" height=\"600\" viewBox=\"0 0 800 600\">");
            for (int j = 0; j < nodeCount; j++) {
                string f = nFills[j % nFills.Length];
                sw.WriteLine("<circle cx=\"" + ncx[j] + "\" cy=\"" + ncy[j] + "\" r=\"6\" fill=\"" + f + "\"/>");
            }
            for (int e = 0; e < edgeCount; e++) {
                int src = (int)(MC(e, 37, 0, nodeCount, 0));
                int dst = (int)(MC(e, 53, nodeCount/2, nodeCount, 0));
                string st = eStrokes[e % eStrokes.Length];
                sw.WriteLine("<line x1=\"" + ncx[src] + "\" y1=\"" + ncy[src] + "\" x2=\"" + ncx[dst] + "\" y2=\"" + ncy[dst] + "\" stroke=\"" + st + "\" stroke-width=\"1\"/>");
            }
            sw.WriteLine("</svg>");
        }
        string sha = FileSha256(outPath);
        var s = new StringBuilder();
        s.Append("{\"domain\":\"svg\",\"file\":\"svg_network_10k.svg\"");
        s.Append(",\"sha256_original\":\"" + sha + "\"");
        s.Append(",\"node_count\":" + nodeCount + ",\"edge_count\":" + edgeCount);
        s.Append(",\"svg_width\":800,\"svg_height\":600");
        s.Append(",\"node_cx\":{\"type\":\"mc\",\"m\":41,\"a\":50,\"mod\":701,\"min\":50}");
        s.Append(",\"node_cy\":{\"type\":\"mc\",\"m\":59,\"a\":50,\"mod\":501,\"min\":50}");
        s.Append(",\"node_r\":6");
        s.Append(",\"node_fills\":" + JA(nFills));
        s.Append(",\"node_fill_period\":" + nFills.Length);
        s.Append(",\"edge_src\":{\"type\":\"mc\",\"m\":37,\"a\":0,\"mod\":" + nodeCount + ",\"min\":0}");
        s.Append(",\"edge_dst\":{\"type\":\"mc\",\"m\":53,\"a\":" + (nodeCount/2) + ",\"mod\":" + nodeCount + ",\"min\":0}");
        s.Append(",\"edge_strokes\":" + JA(eStrokes));
        s.Append(",\"edge_stroke_period\":" + eStrokes.Length);
        s.Append("}");
        File.WriteAllText(seedPath, s.ToString(), new UTF8Encoding(false));
        return sha;
    }

    // ── 10: svg_heatmap_20k.svg ───────────────────────────────────────────
    public static string GenSvgHeatmap(string outPath, string seedPath, int cols, int rows) {
        string[] palette = {
            "#0d0221","#1a0442","#270663","#340884","#2e1a6e","#3829a5",
            "#2255c8","#1a7fd4","#12aacc","#0acfc4","#05e8b0","#17f09a",
            "#2aea7a","#4de050","#70d42a","#96c414","#bcb00e","#e09920",
            "#f07832","#f95044","#ff2a55","#f20966","#cc0078","#99008a"
        };
        int count = cols * rows;

        using (var sw = new StreamWriter(outPath, false, new UTF8Encoding(false))) {
            sw.WriteLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
            sw.WriteLine("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" + (cols*4+20) + "\" height=\"" + (rows*5+20) + "\" viewBox=\"0 0 " + (cols*4+20) + " " + (rows*5+20) + "\">");
            for (int i = 0; i < count; i++) {
                int col = i % cols;
                int row = i / cols;
                int x   = col * 4 + 10;
                int y   = row * 5 + 10;
                string f = palette[i % palette.Length];
                sw.WriteLine("<rect x=\"" + x + "\" y=\"" + y + "\" width=\"3\" height=\"4\" fill=\"" + f + "\"/>");
            }
            sw.WriteLine("</svg>");
        }
        string sha = FileSha256(outPath);
        var s = new StringBuilder();
        s.Append("{\"domain\":\"svg\",\"file\":\"svg_heatmap_20k.svg\"");
        s.Append(",\"sha256_original\":\"" + sha + "\"");
        s.Append(",\"cols\":" + cols + ",\"rows\":" + rows);
        s.Append(",\"element\":\"rect\"");
        s.Append(",\"x_formula\":\"col*4+10\",\"y_formula\":\"row*5+10\"");
        s.Append(",\"width\":3,\"height\":4");
        s.Append(",\"fill_cycle\":\"i%" + palette.Length + "\",\"palette\":" + JA(palette));
        s.Append("}");
        File.WriteAllText(seedPath, s.ToString(), new UTF8Encoding(false));
        return sha;
    }
}

} // namespace TEIA.P17
"@

# ── Compressao baseline via .NET ───────────────────────────────────────────────
function Measure-Baselines([string]$filePath) {
    $bytes  = [System.IO.File]::ReadAllBytes($filePath)
    $opts   = [System.IO.Compression.CompressionLevel]::Optimal

    $ms1 = New-Object System.IO.MemoryStream
    $gz  = New-Object System.IO.Compression.GZipStream($ms1, $opts, $true)
    $gz.Write($bytes, 0, $bytes.Length); $gz.Dispose()
    $gzSize = [long]$ms1.Length; $ms1.Dispose()

    $ms2 = New-Object System.IO.MemoryStream
    $br  = New-Object System.IO.Compression.BrotliStream($ms2, $opts, $true)
    $br.Write($bytes, 0, $bytes.Length); $br.Dispose()
    $brSize = [long]$ms2.Length; $ms2.Dispose()

    return @{ GZip=$gzSize; Brotli=$brSize }
}

# ── Tabela de datasets ─────────────────────────────────────────────────────────
$datasets = @(
    @{ Name='json_api_events';   Domain='JSON'; Gen={ [TEIA.P17.Gen]::GenJsonApiEvents("$DataDir\json_api_events.json","$SeedDir\seed_json_api_events.json",40000) }; File="$DataDir\json_api_events.json" }
    @{ Name='json_products';     Domain='JSON'; Gen={ [TEIA.P17.Gen]::GenJsonProducts("$DataDir\json_products.json","$SeedDir\seed_json_products.json",25000) };     File="$DataDir\json_products.json" }
    @{ Name='json_metrics';      Domain='JSON'; Gen={ [TEIA.P17.Gen]::GenJsonMetrics("$DataDir\json_metrics.json","$SeedDir\seed_json_metrics.json",35000) };        File="$DataDir\json_metrics.json" }
    @{ Name='csv_sensor_data';   Domain='CSV';  Gen={ [TEIA.P17.Gen]::GenCsvSensorData("$DataDir\csv_sensor_data.csv","$SeedDir\seed_csv_sensor_data.json",70000) };   File="$DataDir\csv_sensor_data.csv" }
    @{ Name='csv_transactions';  Domain='CSV';  Gen={ [TEIA.P17.Gen]::GenCsvTransactions("$DataDir\csv_transactions.csv","$SeedDir\seed_csv_transactions.json",55000) }; File="$DataDir\csv_transactions.csv" }
    @{ Name='csv_server_logs';   Domain='CSV';  Gen={ [TEIA.P17.Gen]::GenCsvServerLogs("$DataDir\csv_server_logs.csv","$SeedDir\seed_csv_server_logs.json",80000) };   File="$DataDir\csv_server_logs.csv" }
    @{ Name='csv_orders';        Domain='CSV';  Gen={ [TEIA.P17.Gen]::GenCsvOrders("$DataDir\csv_orders.csv","$SeedDir\seed_csv_orders.json",50000) };                 File="$DataDir\csv_orders.csv" }
    @{ Name='svg_scatter_20k';   Domain='SVG';  Gen={ [TEIA.P17.Gen]::GenSvgScatter("$DataDir\svg_scatter_20k.svg","$SeedDir\seed_svg_scatter_20k.json",20000) };     File="$DataDir\svg_scatter_20k.svg" }
    @{ Name='svg_network_10k';   Domain='SVG';  Gen={ [TEIA.P17.Gen]::GenSvgNetwork("$DataDir\svg_network_10k.svg","$SeedDir\seed_svg_network_10k.json",10000,15000) }; File="$DataDir\svg_network_10k.svg" }
    @{ Name='svg_heatmap_20k';   Domain='SVG';  Gen={ [TEIA.P17.Gen]::GenSvgHeatmap("$DataDir\svg_heatmap_20k.svg","$SeedDir\seed_svg_heatmap_20k.json",200,100) };   File="$DataDir\svg_heatmap_20k.svg" }
)

# ── FASE 1: Geracao ────────────────────────────────────────────────────────────
if (-not $SkipGenerate) {
    Write-Host ''
    Write-Host '  [FASE 1] Gerando datasets deterministas...' -ForegroundColor Yellow
    foreach ($ds in $datasets) {
        Write-Host "    > $($ds.Name)..." -NoNewline
        $sha = & $ds.Gen
        $sz  = (Get-Item $ds.File).Length
        Write-Host (" {0:N0} bytes  SHA256={1}" -f $sz, $sha.Substring(0,16) + '...') -ForegroundColor Green
    }
}

# ── FASE 2: Analise semantica ──────────────────────────────────────────────────
Write-Host ''
Write-Host '  [FASE 2] Executando Lente Semantica...' -ForegroundColor Yellow

$results = @{}
foreach ($ds in $datasets) {
    Write-Host "    > $($ds.Name)..." -NoNewline
    $skeletonPath = "$PromptDir\skeleton_$($ds.Name).txt"
    & $SemanticTool -InputFile $ds.File -OutputJson "$PromptDir\blueprint_$($ds.Name).json" | `
        Out-File -FilePath $skeletonPath -Encoding UTF8
    Write-Host ' OK' -ForegroundColor Green
    $results[$ds.Name] = @{ Skeleton = Get-Content $skeletonPath -Raw -Encoding UTF8 }
}

# ── FASE 3: Baselines GZip + Brotli ───────────────────────────────────────────
Write-Host ''
Write-Host '  [FASE 3] Medindo baselines de compressao...' -ForegroundColor Yellow
foreach ($ds in $datasets) {
    Write-Host "    > $($ds.Name)..." -NoNewline
    $bl = Measure-Baselines $ds.File
    $fi = Get-Item $ds.File
    $results[$ds.Name].OrigSize   = $fi.Length
    $results[$ds.Name].GZipSize   = $bl.GZip
    $results[$ds.Name].BrotliSize = $bl.Brotli
    $results[$ds.Name].SeedPath   = "$SeedDir\seed_$($ds.Name).json"
    $results[$ds.Name].SeedSize   = (Get-Item "$SeedDir\seed_$($ds.Name).json").Length
    Write-Host (" orig={0:N0}  gzip={1:N0}  brotli={2:N0}  seed={3}" -f `
        $fi.Length, $bl.GZip, $bl.Brotli, (Get-Item "$SeedDir\seed_$($ds.Name).json").Length) -ForegroundColor Cyan
}

# ── FASE 4: Exporta Prompts de Forja ──────────────────────────────────────────
Write-Host ''
Write-Host '  [FASE 4] Exportando Prompts de Forja...' -ForegroundColor Yellow

foreach ($ds in $datasets) {
    $r         = $results[$ds.Name]
    $seedJson  = Get-Content $r.SeedPath -Raw -Encoding UTF8
    $target    = [Math]::Min($r.GZipSize, $r.BrotliSize)
    $promptFile= "$PromptDir\forge_$($ds.Name).txt"

    $prompt = @"
═══ FORGE PROMPT P17.0: $($ds.Name) ═══
DOMAIN: $($ds.Domain)
FILE: $($ds.File | Split-Path -Leaf)
SIZE_ORIGINAL: $($r.OrigSize) bytes
SHA256_ORIGINAL: $((Get-Content $r.SeedPath -Raw | ConvertFrom-Json).sha256_original)
SIZE_GZIP: $($r.GZipSize) bytes
SIZE_BROTLI: $($r.BrotliSize) bytes
SIZE_SEED: $($r.SeedSize) bytes
TARGET_BASELINE: $target bytes (min(gzip,brotli))

SEED (salvar em: $DecoderDir\seed_$($ds.Name).json):
$seedJson

SKELETON SEMANTICO:
$($r.Skeleton)

TASK:
Escreva $DecoderDir\Decode-$($ds.Name).ps1
O decoder deve:
  1. Ler seed (parametro -SeedFile) e reconstruir o arquivo original em -OutputFile
  2. Usar Add-Type com C# para reconstrucao rapida (mesmo algoritmo do gerador)
  3. Verificar SHA-256 e imprimir "SHA-256 PASS: <hash>" ou "SHA-256 FAIL"
  4. Formulas: seq(i)=start+i*step | ts_seq(i)=BASE.AddSeconds(i*step_sec).ToString("yyyy-MM-ddTHH:mm:ssZ")
             | ts_date(i)=BASE.AddSeconds(i*step_sec).ToString("yyyy-MM-dd")
             | cycle(i)=values[i%period] | mc(i)=((long)i*m+a)%mod+min
             | mc_pad(i)=prefix+(mc_value).ToString("D{digits}")
             | sku_template(i)=prefix+(i+1).ToString("D{digits}")
  5. Para JSON: {root_key}:[{field1:val1,...},{...},...]} sem espacos, virgula entre records
  6. Para CSV: header\nrow\nrow\n... (LF apos cada linha incluindo ultima)
  7. Para SVG: <?xml...?>\n<svg...>\n<element.../>\n...\n</svg>\n
  BASE = new DateTime(2024,1,1,0,0,0,DateTimeKind.Utc)

INVARIANTE: Hash(Reconstruido) == SHA256_ORIGINAL. Zero tolerancia para perda.
DELTA esperado: (SeedSize + CodigoDecoder) versus $target bytes baseline.
"@
    [System.IO.File]::WriteAllText($promptFile, $prompt, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "    > $promptFile" -ForegroundColor Gray
}

# ── Sumario ────────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host '  SUMARIO P17.0 — CRUCIBLE COMPLETO' -ForegroundColor Cyan
Write-Host ('=' * 72) -ForegroundColor Cyan
Write-Host ''
$fmt = '{0,-22} {1,-4} {2,9} {3,9} {4,9} {5,7}'
Write-Host ($fmt -f 'Dataset','Dom','Original','GZip','Brotli','Seed') -ForegroundColor White
Write-Host ($fmt -f ('─'*22),'────','─────────','─────────','─────────','───────') -ForegroundColor DarkGray
foreach ($ds in $datasets) {
    $r = $results[$ds.Name]
    Write-Host ($fmt -f $ds.Name,$ds.Domain,$r.OrigSize,$r.GZipSize,$r.BrotliSize,$r.SeedSize)
}
Write-Host ''
Write-Host "  Datasets: $DataDir"    -ForegroundColor DarkGray
Write-Host "  Seeds:    $SeedDir"    -ForegroundColor DarkGray
Write-Host "  Prompts:  $PromptDir"  -ForegroundColor DarkGray
Write-Host "  Decoders: $DecoderDir" -ForegroundColor DarkGray
Write-Host ''
Write-Host '  Proxima etapa: ler forge_*.txt e escrever Decode-*.ps1 + seed_*.json' -ForegroundColor Yellow
