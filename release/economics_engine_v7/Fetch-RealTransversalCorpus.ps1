#Requires -Version 7
# Fetch-RealTransversalCorpus.ps1 — Corpus Real para TEIA Transversal P35.0
# Tenta baixar logs de acesso HTTP reais (Apache CLF) de fontes públicas.
# Parseia, limpa e particiona em N arquivos CSV com schema idêntico.
# Fallback: corpus sintético com distribuições autênticas (não Random(42)).

param(
    [string]$OutputDir       = "D:\TEIA_USER\MyRealData\Corpus_Transversal\RealLogs",
    [int]   $MinPartitions   = 10,
    [int]   $MaxLinesPerPart = 2000
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

# Schema canônico: IP acesso HTTP
$HEADER = "IP,Ident,User,Date,Time,Method,Resource,Protocol,Status,Bytes"

# ─── Regex para Apache Common/Combined Log Format ────────────────────────────
# 83.149.9.216 - - [17/May/2015:10:05:03 +0000] "GET /path HTTP/1.1" 200 203023
$clfRx = [regex]'^(\S+) (\S+) (\S+) \[(\d{2}/\w+/\d{4}):(\d{2}:\d{2}:\d{2}) [^\]]+\] "(\S+) ([^"]*) (HTTP/\S+)" (\d{3}) (\S+)'

function ConvertTo-CsvField([string]$v) {
    if ($v -match '[,"\r\n]') { return '"' + ($v -replace '"', '""') + '"' }
    return $v
}

Write-Host ""
Write-Host "=== TEIA Corpus Real — Downloader P35.0 ===" -ForegroundColor Cyan
Write-Host "  Destino      : $OutputDir"                  -ForegroundColor White
Write-Host "  Partições min: $MinPartitions"              -ForegroundColor White
Write-Host ""

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# ─── Verificar arquivos já existentes ────────────────────────────────────────
$existing = @(Get-ChildItem -Path $OutputDir -Filter "*.csv" -ErrorAction SilentlyContinue)
if ($existing.Count -ge $MinPartitions) {
    Write-Host "  Corpus já presente ($($existing.Count) arquivos) — ignorado." -ForegroundColor DarkGray
    $total = ($existing | Measure-Object -Property Length -Sum).Sum
    Write-Host "  Tamanho total: $([math]::Round($total/1KB,1)) KB" -ForegroundColor Green
    exit 0
}

# ─── Fontes de download (Apache CLF) ─────────────────────────────────────────
$sources = @(
    # Elastic examples — logs reais de site de conferência (Mai/2015, ~10k linhas)
    "https://raw.githubusercontent.com/elastic/examples/master/Common%20Data%20Formats/apache_logs/apache_logs",
    # logpai/loghub — Apache access log sample
    "https://raw.githubusercontent.com/logpai/loghub/master/Apache/Apache_2k.log"
)

$parsedRows = [System.Collections.Generic.List[hashtable]]::new()

foreach ($url in $sources) {
    if ($parsedRows.Count -ge 500) { break }
    try {
        Write-Host "  Baixando: $url" -ForegroundColor DarkGray
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 45
        $rawLines = $resp.Content -split "`n"
        $matched  = 0
        foreach ($line in $rawLines) {
            $m = $clfRx.Match($line.Trim())
            if ($m.Success) {
                $parsedRows.Add(@{
                    IP       = $m.Groups[1].Value
                    Ident    = $m.Groups[2].Value
                    User     = $m.Groups[3].Value
                    Date     = $m.Groups[4].Value        # DD/Mon/YYYY
                    Time     = $m.Groups[5].Value        # HH:MM:SS
                    Method   = $m.Groups[6].Value
                    Resource = ($m.Groups[7].Value -replace '\s+.*$', '' -replace ',', '%2C')  # strip query params; encode commas to prevent CSV split ambiguity
                    Protocol = $m.Groups[8].Value
                    Status   = $m.Groups[9].Value
                    Bytes    = $m.Groups[10].Value
                })
                $matched++
            }
        }
        Write-Host "    $matched linhas CLF válidas" -ForegroundColor $(if ($matched -gt 100) {'Green'} else {'Yellow'})
    }
    catch {
        Write-Host "    Falha: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

$downloadSuccess = $parsedRows.Count -ge 200
Write-Host ""
if ($downloadSuccess) {
    Write-Host "  Download OK: $($parsedRows.Count) linhas reais de log." -ForegroundColor Green
} else {
    Write-Host "  Download insuficiente ($($parsedRows.Count) linhas). Usando corpus realístico." -ForegroundColor Yellow
}

# ─── Particionamento ──────────────────────────────────────────────────────────
function Write-PartitionFile {
    param([string]$Path, [hashtable[]]$Rows)
    $sb = [System.Text.StringBuilder]::new(($Rows.Count + 1) * 80)
    $null = $sb.AppendLine($HEADER)
    foreach ($r in $Rows) {
        $null = $sb.AppendLine(
            (ConvertTo-CsvField $r.IP)       + ',' +
            $r.Ident                          + ',' +
            $r.User                           + ',' +
            $r.Date                           + ',' +
            $r.Time                           + ',' +
            $r.Method                         + ',' +
            (ConvertTo-CsvField $r.Resource)  + ',' +
            $r.Protocol                       + ',' +
            $r.Status                         + ',' +
            $r.Bytes
        )
    }
    [System.IO.File]::WriteAllText($Path, $sb.ToString(), $utf8NoBom)
}

if ($downloadSuccess) {
    # Agrupar por data
    $byDate = [ordered]@{}
    foreach ($row in $parsedRows) {
        $k = $row.Date
        if (!$byDate.Contains($k)) { $byDate[$k] = [System.Collections.Generic.List[hashtable]]::new() }
        $byDate[$k].Add($row)
    }

    # Se menos datas que MinPartitions, sub-dividir em batches sequenciais
    if ($byDate.Keys.Count -lt $MinPartitions) {
        $allRows  = [hashtable[]]@($parsedRows)
        $n        = $allRows.Count
        $batchSz  = [int][math]::Ceiling($n / $MinPartitions)
        $batches  = [ordered]@{}
        for ($b = 0; $b -lt $MinPartitions; $b++) {
            $start = $b * $batchSz
            if ($start -ge $n) { break }
            $end   = [math]::Min($start + $batchSz - 1, $n - 1)
            $batches["batch_{0:D2}" -f ($b + 1)] = $allRows[$start..$end]
        }
        $partMap = $batches
    } else {
        $partMap = $byDate
    }

    $idx = 0
    foreach ($key in $partMap.Keys) {
        $rows  = @($partMap[$key])
        $limit = [math]::Min($rows.Count, $MaxLinesPerPart)
        $rows  = $rows[0..($limit - 1)]
        $safeName = $key -replace '[/: ]','_'
        $filePath = Join-Path $OutputDir "access_log_${safeName}.csv"
        Write-PartitionFile -Path $filePath -Rows $rows
        Write-Host "  $([System.IO.Path]::GetFileName($filePath)) — $limit linhas" -ForegroundColor DarkGreen
        $idx++
    }
}
else {
    # ─── Fallback: corpus sintético com distribuições autênticas ─────────────
    Write-Host "  Gerando corpus sintético com distribuições reais..." -ForegroundColor Yellow

    # Seed baseado em data do dia (reproduzível no mesmo dia, diferente em outros dias)
    $dateStr  = [datetime]::UtcNow.ToString("yyyy-MM-dd")
    $seedHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                    [System.Text.Encoding]::UTF8.GetBytes("TEIA-$env:COMPUTERNAME-$dateStr"))
    $rng      = [System.Random]::new([System.BitConverter]::ToInt32($seedHash, 0))

    # Distribuições autênticas baseadas em estudos de tráfego HTTP público
    $ipBlocks   = @("66.249","157.55","54.91","17.58","151.80","66.102","178.255",
                    "185.20","104.196","216.58","172.217","34.101","203.0","1.179",
                    "95.108","123.125","220.181","180.76","119.63","207.46")
    $idents     = @("-","-","-","-","-","-","-","-","-","rfc931") # 90% -
    $users      = @("-","-","-","-","-","-","-","-","admin","api")  # 80% -
    # HTTP method distribution: GET 80%, POST 15%, HEAD 4%, PUT 1%
    $methods    = (@("GET") * 80) + (@("POST") * 15) + (@("HEAD") * 4) + @("PUT")
    # HTTP status distribution: 200=60%, 304=15%, 404=10%, 302=6%, 301=4%, 400=3%, 500=2%
    $statuses   = (@("200") * 60) + (@("304") * 15) + (@("404") * 10) + (@("302") * 6) +
                  (@("301") * 4)  + (@("400") * 3)  + (@("500") * 2)
    $protocols  = @("HTTP/1.1","HTTP/1.1","HTTP/1.1","HTTP/1.1","HTTP/1.0")
    $resources  = @(
        "/", "/index.html", "/about", "/contact", "/products", "/services",
        "/css/style.css", "/js/app.js", "/js/jquery.min.js", "/images/logo.png",
        "/favicon.ico", "/robots.txt", "/sitemap.xml", "/api/v1/status",
        "/api/v1/users", "/api/v1/data", "/blog/", "/search", "/login", "/logout",
        "/static/bootstrap.min.css", "/fonts/opensans.woff2", "/images/banner.jpg",
        "/downloads/guide.pdf", "/docs/", "/privacy", "/terms", "/404.html"
    )
    # Tamanhos de resposta típicos por status
    $bytesByStatus = @{
        "200"=@(200,5000,15000,50000,200000); "304"=@(0); "404"=@(150,200,250);
        "302"=@(0); "301"=@(0); "400"=@(200,300); "500"=@(500,1000)
    }

    $startDate = [datetime]::new(2024, 3, 1)

    for ($f = 0; $f -lt $MinPartitions; $f++) {
        $date     = $startDate.AddDays($f)
        $fileName = "access_log_{0:yyyy_MM_dd}.csv" -f $date
        $filePath = Join-Path $OutputDir $fileName
        $dateStr2 = "{0:dd}/$(([cultureinfo]"en-US").DateTimeFormat.AbbreviatedMonthNames[$date.Month-1])/{0:yyyy}" -f $date

        $sb      = [System.Text.StringBuilder]::new(($MaxLinesPerPart + 1) * 90)
        $null    = $sb.AppendLine($HEADER)
        $nLines  = $MaxLinesPerPart

        for ($r = 0; $r -lt $nLines; $r++) {
            # Temporal distribution: higher traffic 08-22h UTC (Poisson-like)
            $hour   = [int]([math]::Floor(([math]::Abs([math]::Sin($rng.NextDouble() * [math]::PI * 2)) * 14) + 8) % 24)
            $min    = $rng.Next(0, 60)
            $sec    = $rng.Next(0, 60)
            $time   = "{0:D2}:{1:D2}:{2:D2}" -f $hour, $min, $sec

            $ipB    = $ipBlocks[$rng.Next(0, $ipBlocks.Length)]
            $ip     = "$ipB.$($rng.Next(0,256)).$($rng.Next(0,256))"
            $ident  = $idents[$rng.Next(0, $idents.Length)]
            $user   = $users[$rng.Next(0, $users.Length)]
            $method = $methods[$rng.Next(0, $methods.Length)]
            $res    = $resources[$rng.Next(0, $resources.Length)]
            $proto  = $protocols[$rng.Next(0, $protocols.Length)]
            $status = $statuses[$rng.Next(0, $statuses.Length)]
            $szArr  = if ($bytesByStatus.ContainsKey($status)) { $bytesByStatus[$status] } else { @(500) }
            $bytes  = if ($szArr[0] -eq 0) { "0" } else { [string]$szArr[$rng.Next(0, $szArr.Length)] }

            $null   = $sb.AppendLine("$ip,$ident,$user,$dateStr2,$time,$method,$(ConvertTo-CsvField $res),$proto,$status,$bytes")
        }

        [System.IO.File]::WriteAllText($filePath, $sb.ToString(), $utf8NoBom)
        Write-Host "  $fileName — $nLines linhas (sintético realístico)" -ForegroundColor DarkGreen
    }
}

$csvFiles  = @(Get-ChildItem -Path $OutputDir -Filter "*.csv")
$totalSize = ($csvFiles | Measure-Object -Property Length -Sum).Sum
Write-Host ""
Write-Host "Corpus pronto: $($csvFiles.Count) arquivos" -ForegroundColor Green
Write-Host "Tamanho total: $([math]::Round($totalSize/1KB,1)) KB ($totalSize bytes)" -ForegroundColor Cyan
Write-Host "Fonte        : $(if ($downloadSuccess) {'Real (HTTP logs públicos)'} else {'Sintético realístico (fallback)'})" -ForegroundColor White
