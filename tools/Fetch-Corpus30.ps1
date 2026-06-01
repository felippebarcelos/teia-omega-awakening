#Requires -Version 7
<#
.SYNOPSIS
    Fetch-Corpus30.ps1 - P25.0 public organic corpus fetcher.

.DESCRIPTION
    Downloads 30 public datasets into D:\TEIA_USER\MyRealData\Corpus30.
    The target mix is 10 CSV, 10 JSON, 5 SVG/XML, and 5 system logs.
    Failures are captured in a deterministic manifest and do not stop the run.

    Invariant: Delta is written as a word only. The mathematical symbol is
    forbidden in generated code, reports, and commit messages.
#>
[CmdletBinding()]
param(
    [string]$OutputDir = 'D:\TEIA_USER\MyRealData\Corpus30',
    [string]$ManifestPath = '',
    [int]$TimeoutSec = 90,
    [switch]$Force,
    [switch]$Quiet
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$enc = New-Object System.Text.UTF8Encoding($false)
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $OutputDir 'corpus30_manifest.json'
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$datasets = @(
    [ordered]@{ Id=1;  Kind='csv'; Name='csv_covid_countries_aggregated.csv'; Url='https://raw.githubusercontent.com/datasets/covid-19/main/data/countries-aggregated.csv'; Source='GitHub datasets/covid-19'; Description='COVID-19 cases by country and date' },
    [ordered]@{ Id=2;  Kind='csv'; Name='csv_gapminder_five_year.csv'; Url='https://raw.githubusercontent.com/plotly/datasets/master/gapminderDataFiveYear.csv'; Source='GitHub plotly/datasets'; Description='Gapminder country indicators' },
    [ordered]@{ Id=3;  Kind='csv'; Name='csv_iris.csv'; Url='https://raw.githubusercontent.com/mwaskom/seaborn-data/master/iris.csv'; Source='GitHub seaborn-data'; Description='Iris measurements' },
    [ordered]@{ Id=4;  Kind='csv'; Name='csv_titanic.csv'; Url='https://raw.githubusercontent.com/mwaskom/seaborn-data/master/titanic.csv'; Source='GitHub seaborn-data'; Description='Titanic passenger table' },
    [ordered]@{ Id=5;  Kind='csv'; Name='csv_penguins.csv'; Url='https://raw.githubusercontent.com/mwaskom/seaborn-data/master/penguins.csv'; Source='GitHub seaborn-data'; Description='Palmer penguins table' },
    [ordered]@{ Id=6;  Kind='csv'; Name='csv_flights.csv'; Url='https://raw.githubusercontent.com/mwaskom/seaborn-data/master/flights.csv'; Source='GitHub seaborn-data'; Description='Monthly passenger flights' },
    [ordered]@{ Id=7;  Kind='csv'; Name='csv_gdp.csv'; Url='https://raw.githubusercontent.com/datasets/gdp/master/data/gdp.csv'; Source='GitHub datasets/gdp'; Description='GDP by country and year' },
    [ordered]@{ Id=8;  Kind='csv'; Name='csv_population.csv'; Url='https://raw.githubusercontent.com/datasets/population/master/data/population.csv'; Source='GitHub datasets/population'; Description='Population by country and year' },
    [ordered]@{ Id=9;  Kind='csv'; Name='csv_co2_global.csv'; Url='https://raw.githubusercontent.com/datasets/co2-fossil-global/master/data/global.csv'; Source='GitHub datasets/co2-fossil-global'; Description='Global fossil CO2 emissions' },
    [ordered]@{ Id=10; Kind='csv'; Name='csv_seattle_weather.csv'; Url='https://raw.githubusercontent.com/vega/vega-datasets/main/data/seattle-weather.csv'; Source='GitHub vega-datasets'; Description='Seattle weather observations' },

    [ordered]@{ Id=11; Kind='json'; Name='json_countries_mledoze.json'; Url='https://raw.githubusercontent.com/mledoze/countries/master/countries.json'; Source='GitHub mledoze/countries'; Description='Country reference data' },
    [ordered]@{ Id=12; Kind='json'; Name='json_worldbank_gdp.json'; Url='https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CD?format=json&per_page=20000'; Source='World Bank API'; Description='World Bank GDP indicator JSON' },
    [ordered]@{ Id=13; Kind='json'; Name='json_worldbank_countries.json'; Url='https://api.worldbank.org/v2/country?format=json&per_page=400'; Source='World Bank API'; Description='World Bank country metadata JSON' },
    [ordered]@{ Id=14; Kind='json'; Name='json_world_geojson.json'; Url='https://raw.githubusercontent.com/johan/world.geo.json/master/countries.geo.json'; Source='GitHub world.geo.json'; Description='World country GeoJSON' },
    [ordered]@{ Id=15; Kind='json'; Name='json_us_10m_topo.json'; Url='https://raw.githubusercontent.com/vega/vega-datasets/main/data/us-10m.json'; Source='GitHub vega-datasets'; Description='US TopoJSON mesh' },
    [ordered]@{ Id=16; Kind='json'; Name='json_miserables_graph.json'; Url='https://raw.githubusercontent.com/vega/vega-datasets/main/data/miserables.json'; Source='GitHub vega-datasets'; Description='Les Miserables graph JSON' },
    [ordered]@{ Id=17; Kind='json'; Name='json_movies.json'; Url='https://raw.githubusercontent.com/vega/vega-datasets/main/data/movies.json'; Source='GitHub vega-datasets'; Description='Movie metadata JSON' },
    [ordered]@{ Id=18; Kind='json'; Name='json_flights_2k.json'; Url='https://raw.githubusercontent.com/vega/vega-datasets/main/data/flights-2k.json'; Source='GitHub vega-datasets'; Description='Flight records JSON' },
    [ordered]@{ Id=19; Kind='json'; Name='json_cars.json'; Url='https://raw.githubusercontent.com/vega/vega-datasets/main/data/cars.json'; Source='GitHub vega-datasets'; Description='Cars table JSON' },
    [ordered]@{ Id=20; Kind='json'; Name='json_barley.json'; Url='https://raw.githubusercontent.com/vega/vega-datasets/main/data/barley.json'; Source='GitHub vega-datasets'; Description='Barley yield JSON' },

    [ordered]@{ Id=21; Kind='xml'; Name='xml_cd_catalog.xml'; Url='https://www.w3schools.com/xml/cd_catalog.xml'; Source='W3Schools XML sample'; Description='CD catalog XML' },
    [ordered]@{ Id=22; Kind='xml'; Name='xml_plant_catalog.xml'; Url='https://www.w3schools.com/xml/plant_catalog.xml'; Source='W3Schools XML sample'; Description='Plant catalog XML' },
    [ordered]@{ Id=23; Kind='svg'; Name='svg_switzerland_flag.svg'; Url='https://upload.wikimedia.org/wikipedia/commons/f/f3/Flag_of_Switzerland.svg'; Source='Wikimedia Commons'; Description='Swiss flag SVG' },
    [ordered]@{ Id=24; Kind='svg'; Name='svg_ghostscript_tiger.svg'; Url='https://upload.wikimedia.org/wikipedia/commons/f/fd/Ghostscript_Tiger.svg'; Source='Wikimedia Commons'; Description='Ghostscript tiger SVG' },
    [ordered]@{ Id=25; Kind='svg'; Name='svg_commons_logo.svg'; Url='https://upload.wikimedia.org/wikipedia/commons/4/4a/Commons-logo.svg'; Source='Wikimedia Commons'; Description='Commons logo SVG' },

    [ordered]@{ Id=26; Kind='log'; Name='log_hdfs_2k.log'; Url='https://raw.githubusercontent.com/logpai/loghub/master/HDFS/HDFS_2k.log'; Source='GitHub logpai/loghub'; Description='HDFS system log sample' },
    [ordered]@{ Id=27; Kind='log'; Name='log_apache_2k.log'; Url='https://raw.githubusercontent.com/logpai/loghub/master/Apache/Apache_2k.log'; Source='GitHub logpai/loghub'; Description='Apache system log sample' },
    [ordered]@{ Id=28; Kind='log'; Name='log_linux_2k.log'; Url='https://raw.githubusercontent.com/logpai/loghub/master/Linux/Linux_2k.log'; Source='GitHub logpai/loghub'; Description='Linux system log sample' },
    [ordered]@{ Id=29; Kind='log'; Name='log_mac_2k.log'; Url='https://raw.githubusercontent.com/logpai/loghub/master/Mac/Mac_2k.log'; Source='GitHub logpai/loghub'; Description='Mac system log sample' },
    [ordered]@{ Id=30; Kind='log'; Name='log_openssh_2k.log'; Url='https://raw.githubusercontent.com/logpai/loghub/master/OpenSSH/OpenSSH_2k.log'; Source='GitHub logpai/loghub'; Description='OpenSSH system log sample' }
)

function Get-Sha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Save-DeterministicJson([string]$Path, [object]$Value) {
    $json = $Value | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllBytes($Path, $enc.GetBytes($json))
}

$results = @()
foreach ($ds in $datasets) {
    $dest = Join-Path $OutputDir $ds.Name
    $tmp = "$dest.download"
    $status = 'OK'
    $errorText = ''

    try {
        if ($Force -or -not (Test-Path -LiteralPath $dest) -or ((Get-Item -LiteralPath $dest).Length -le 0)) {
            Invoke-WebRequest -Uri $ds.Url -OutFile $tmp -UseBasicParsing -TimeoutSec $TimeoutSec | Out-Null
            if (-not (Test-Path -LiteralPath $tmp) -or ((Get-Item -LiteralPath $tmp).Length -le 0)) {
                throw 'download produced no bytes'
            }
            Move-Item -LiteralPath $tmp -Destination $dest -Force
        }

        $item = Get-Item -LiteralPath $dest -ErrorAction Stop
        $results += [pscustomobject]@{
            Id = $ds.Id
            Kind = $ds.Kind
            Name = $ds.Name
            Source = $ds.Source
            Url = $ds.Url
            Description = $ds.Description
            Path = $dest
            Bytes = [int64]$item.Length
            SHA256 = Get-Sha256 $dest
            Status = $status
            Error = $errorText
        }
    } catch {
        $status = 'FAIL'
        $errorText = $_.Exception.Message
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        $results += [pscustomobject]@{
            Id = $ds.Id
            Kind = $ds.Kind
            Name = $ds.Name
            Source = $ds.Source
            Url = $ds.Url
            Description = $ds.Description
            Path = $dest
            Bytes = 0
            SHA256 = ''
            Status = $status
            Error = $errorText
        }
    }
}

$ordered = @($results | Sort-Object Id)
Save-DeterministicJson $ManifestPath $ordered

if (-not $Quiet) {
    $ok = @($ordered | Where-Object { $_.Status -eq 'OK' })
    $fail = @($ordered | Where-Object { $_.Status -ne 'OK' })
    [pscustomobject]@{
        OutputDir = $OutputDir
        ManifestPath = $ManifestPath
        Requested = $ordered.Count
        DownloadedOrPresent = $ok.Count
        Failed = $fail.Count
        Csv = @($ok | Where-Object Kind -eq 'csv').Count
        Json = @($ok | Where-Object Kind -eq 'json').Count
        SvgXml = @($ok | Where-Object { $_.Kind -in @('svg','xml') }).Count
        Logs = @($ok | Where-Object Kind -eq 'log').Count
    }
}
