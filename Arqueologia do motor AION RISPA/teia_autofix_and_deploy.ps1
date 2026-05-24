# teia_autofix_and_deploy.ps1
# Executar em: D:\Teia\TEIA_NUCLEO\offline\nano
# Faz backup de arquivos que shadowam stdlib, cria guard, escreve dashboard e inicia streamlit.

$ErrorActionPreference = "Stop"

$ROOT = (Get-Location).ProviderPath
Write-Host "ROOT: $ROOT"

# timestamp
$ts = Get-Date -Format yyyyMMdd_HHmmss

# 1) Lista de nomes que tipicamente causam shadowing
$conflictNames = @(
  "watchdog","packaging","sysconfig","importlib","types","copy","functools",
  "inspect","logging","re","enum","runpy","ast","operator","typing","json"
)

# 1.a) mover arquivos conflitantes (wildcards)
Write-Host "Procurando e movendo arquivos potencialmente conflitantes..."
foreach ($name in $conflictNames) {
  # arquivos e pastas
  $patterns = @("$name.py","$name.pyc","$name*.py","$name*.pyc","$name")
  foreach ($pat in $patterns) {
    Get-ChildItem -Path $ROOT -Filter $pat -File -ErrorAction SilentlyContinue | ForEach-Object {
      $src = $_.FullName
      $dst = "$src.teia_bak_$ts"
      try {
        Move-Item -LiteralPath $src -Destination $dst -Force
        Write-Host "➡️ Movido: $src -> $dst"
      } catch {
        Write-Warning "Falha mover $src : $_"
      }
    }
    # também diretórios com esse nome
    Get-ChildItem -Path $ROOT -Filter $pat -Directory -ErrorAction SilentlyContinue | ForEach-Object {
      $src = $_.FullName
      $dst = "$src.teia_bak_$ts"
      try {
        Move-Item -LiteralPath $src -Destination $dst -Force
        Write-Host "➡️ Movido dir: $src -> $dst"
      } catch {
        Write-Warning "Falha mover dir $src : $_"
      }
    }
  }
}

# 2) criar teia_shadow_guard.py (idempotente)
$guardPath = Join-Path $ROOT "teia_shadow_guard.py"
if (-not (Test-Path $guardPath)) {
  @'
import importlib.util
import os

_PROJECT_ROOT = os.path.abspath(os.path.dirname(__file__))

def detect_shadowing(names):
    bad = []
    for name in names:
        try:
            spec = importlib.util.find_spec(name)
        except Exception:
            spec = None
        if spec and getattr(spec, "origin", None):
            origin = os.path.abspath(spec.origin)
            try:
                if os.path.commonpath([origin, _PROJECT_ROOT]) == _PROJECT_ROOT:
                    bad.append((name, origin))
            except Exception:
                if origin.startswith(_PROJECT_ROOT):
                    bad.append((name, origin))
    return bad

def ensure_no_shadowing(raise_on_conflict=True):
    names = [
        "watchdog","packaging","sysconfig","importlib","typing","operator",
        "functools","inspect","logging","runpy","ast","json"
    ]
    conflicts = detect_shadowing(names)
    if conflicts:
        lines = [f"{n} -> {p}" for n, p in conflicts]
        msg = "Import shadowing detectado: " + "; ".join(lines)
        if raise_on_conflict:
            raise ImportError(msg + "\\nRenomeie/mova esses ficheiros do projeto para evitar colisões com stdlib/pip packages.")
        else:
            print("AVISO:", msg)
    return conflicts

if __name__ == "__main__":
    cs = ensure_no_shadowing(raise_on_conflict=False)
    if cs:
        print("Conflitos detectados:", cs)
    else:
        print("Nenhum conflito detectado.")
'@ | Out-File -FilePath $guardPath -Encoding utf8 -Force
  Write-Host "Criado: $guardPath"
} else {
  Write-Host "Guard já existe: $guardPath"
}

# 3) criar dashboard_teia_auditoria_total.py (idempotente: sobrescreve se já existir)
$dashPath = Join-Path $ROOT "dashboard_teia_auditoria_total.py"
@'
# dashboard_teia_auditoria_total.py
"""
Painel TEIA: Auditoria Total (Streamlit + processamento)
Salvar este arquivo no diretório do projeto e rodar:
python -m streamlit run dashboard_teia_auditoria_total.py
"""

import os
import time
import hashlib
import json
import base64
import zlib
import shutil
import tempfile
import mimetypes
import math
import platform
import zipfile
import gzip
import lzma
from pathlib import Path
from collections import Counter

# tente importar opcional procedural codec (substitua pelo seu)
try:
    from procedural_codec import encode as proc_encode, decode as proc_decode
    HAS_PROC_CODEC = True
except Exception:
    HAS_PROC_CODEC = False

# utilidades
def sha256_hex(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()

def entropy_bytes(b: bytes) -> float:
    if not b:
        return 0.0
    freq = Counter(b)
    l = len(b)
    e = -sum((count/l) * math.log2(count/l) for count in freq.values())
    return e

def bytes_to_mb(n: int) -> float:
    return round(n / (1024*1024), 6)

def now_ts():
    return time.strftime("%Y%m%d_%H%M%S")

# fallback procedural: compress with zlib then b64
def fallback_encode(data: bytes):
    comp = zlib.compress(data, level=6)
    seed = base64.b64encode(comp)
    meta = {"method": "zlib+base64", "orig_len": len(data), "seed_len": len(seed)}
    return seed, meta

def fallback_decode(seed: bytes):
    comp = base64.b64decode(seed)
    return zlib.decompress(comp)

# compressions: returns (size_bytes, time_s)
def compress_zip_bytes(data: bytes):
    t0 = time.perf_counter()
    tmp = tempfile.TemporaryDirectory()
    p = Path(tmp.name) / "tmpfile.bin"
    p.write_bytes(data)
    zippath = Path(tmp.name) / "tmp.zip"
    with zipfile.ZipFile(zippath, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.write(p, arcname="tmpfile.bin")
    size = zippath.stat().st_size
    t1 = time.perf_counter()
    tmp.cleanup()
    return size, t1 - t0

def compress_gzip_bytes(data: bytes):
    t0 = time.perf_counter()
    out = gzip.compress(data, compresslevel=6)
    t1 = time.perf_counter()
    return len(out), t1 - t0

def compress_lzma_bytes(data: bytes):
    t0 = time.perf_counter()
    out = lzma.compress(data, preset=6)
    t1 = time.perf_counter()
    return len(out), t1 - t0

# pipeline por arquivo
def process_file(fp: Path, out_reports_dir: Path, use_proc_codec=True):
    report = {}
    t_read0 = time.perf_counter()
    raw = fp.read_bytes()
    t_read1 = time.perf_counter()

    report['nome_arquivo'] = fp.name
    report['caminho'] = str(fp)
    report['tipo_mime'] = mimetypes.guess_type(fp.name)[0] or "unknown"
    report['tamanho_original_bytes'] = len(raw)
    report['tamanho_original_MB'] = bytes_to_mb(len(raw))
    report['entropia_arquivo'] = entropy_bytes(raw)
    report['tempo_leitura_s'] = round(t_read1 - t_read0, 6)

    # procedural encode
    t_seed0 = time.perf_counter()
    if use_proc_codec and HAS_PROC_CODEC:
        seed, seed_meta = proc_encode(raw)
    else:
        seed, seed_meta = fallback_encode(raw)
    t_seed1 = time.perf_counter()
    report['seed_meta'] = seed_meta
    report['tamanho_seed_bytes'] = len(seed)
    report['tamanho_seed_MB'] = bytes_to_mb(len(seed))
    report['tempo_seed_s'] = round(t_seed1 - t_seed0, 6)
    report['hash_seed'] = sha256_hex(seed)

    # restoration
    t_rest0 = time.perf_counter()
    try:
        if use_proc_codec and HAS_PROC_CODEC:
            restored = proc_decode(seed)
        else:
            restored = fallback_decode(seed)
        restored_ok = True
    except Exception as e:
        restored = b""
        restored_ok = False
        report['restoration_error'] = str(e)
    t_rest1 = time.perf_counter()
    report['tempo_restauracao_s'] = round(t_rest1 - t_rest0, 6)
    report['hash_original'] = sha256_hex(raw)
    report['hash_restaurado'] = sha256_hex(restored) if restored_ok else None
    report['bitwise_ok'] = (raw == restored)
    report['integridade_ok'] = report['bitwise_ok'] and (report['hash_original'] == report['hash_restaurado'])

    # compressions
    z_size, z_time = compress_zip_bytes(raw)
    g_size, g_time = compress_gzip_bytes(raw)
    l_size, l_time = compress_lzma_bytes(raw)
    report['zip'] = {'tamanho_bytes': z_size, 'tamanho_MB': bytes_to_mb(z_size), 'tempo_s': round(z_time,6)}
    report['gzip'] = {'tamanho_bytes': g_size, 'tamanho_MB': bytes_to_mb(g_size), 'tempo_s': round(g_time,6)}
    report['lzma'] = {'tamanho_bytes': l_size, 'tamanho_MB': bytes_to_mb(l_size), 'tempo_s': round(l_time,6)}

    # compression metrics
    def comp_pct(original, new):
        try:
            return round(((original - new) / original) * 100.0, 4)
        except Exception:
            return None

    orig_len = len(raw)
    report['compressao_procedural_%'] = comp_pct(orig_len, len(seed))
    report['compressao_zip_%'] = comp_pct(orig_len, z_size)
    report['compressao_gzip_%'] = comp_pct(orig_len, g_size)
    report['compressao_lzma_%'] = comp_pct(orig_len, l_size)

    # times
    report['tempo_zip_s'] = report['zip']['tempo_s']
    report['tempo_unzip_s'] = None  # not measured separately here

    # environment (snapshot)
    env = {
        "platform": platform.platform(),
        "python_version": platform.python_version(),
        "processor": platform.processor(),
        "machine": platform.machine(),
        "timestamp": now_ts()
    }
    report['ambiente'] = env

    # simulated resources (simple formulas)
    tempo_total = report['tempo_leitura_s'] + report['tempo_seed_s'] + report['tempo_restauracao_s'] + report['tempo_zip_s']
    report['tempo_total_pipeline_s'] = round(tempo_total, 6)
    report['ram_simulada_MB'] = round(1 + (report['tamanho_original_MB'] * 0.1), 3)
    report['energia_simulada_mWh'] = round(tempo_total * 0.05, 6)
    # innovation score (basic)
    score = 0
    if report['compressao_procedural_%'] and report['compressao_procedural_%'] > 0:
        score += 15
    if report['tempo_restauracao_s'] < 0.02:
        score += 10
    if report['bitwise_ok'] and report['hash_original'] == report['hash_restaurado']:
        score += 25
    if report['tamanho_seed_MB'] < (0.10 * report['tamanho_original_MB']):
        score += 20
    faster_than_zip = report['tempo_seed_s'] < report['tempo_zip_s'] if report['tempo_zip_s'] is not None else False
    if faster_than_zip:
        score += 15
    # Pyto check (just presence of 'ios' in platform as rough)
    if 'ios' in platform.platform().lower() or 'pyto' in platform.python_version().lower():
        score += 15
    report['score_inovacao'] = min(100, score)

    # save report per file
    out_reports_dir.mkdir(parents=True, exist_ok=True)
    report_path = out_reports_dir / f"relatorio_{fp.name}.json"
    with open(report_path, "w", encoding="utf8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    return report, report_path

# orchestration: process a folder (synchronous for simplicity)
def run_benchmark(input_dir: Path, reports_dir: Path, export_restored_dir: Path, use_proc_codec=True):
    results = []
    input_dir = Path(input_dir)
    reports_dir = Path(reports_dir)
    export_restored_dir = Path(export_restored_dir)
    reports_dir.mkdir(parents=True, exist_ok=True)
    export_restored_dir.mkdir(parents=True, exist_ok=True)

    files = [p for p in input_dir.iterdir() if p.is_file()] if input_dir.exists() else []
    t0 = time.perf_counter()
    for p in files:
        r, path = process_file(p, reports_dir, use_proc_codec=use_proc_codec)
        results.append(r)
        # save restored file for manual inspection (if bitwise_ok)
        if r.get("bitwise_ok"):
            try:
                with open(p, "rb") as fo:
                    raw = fo.read()
                if use_proc_codec and HAS_PROC_CODEC:
                    seed, _ = proc_encode(raw)
                    restored = proc_decode(seed)
                else:
                    seed, _ = fallback_encode(raw)
                    restored = fallback_decode(seed)
                outpath = export_restored_dir / p.name
                outpath.write_bytes(restored)
            except Exception:
                pass
    t1 = time.perf_counter()
    summary = {
        "run_timestamp": now_ts(),
        "num_files": len(files),
        "total_time_s": round(t1 - t0, 6),
        "reports_dir": str(reports_dir),
    }
    # write aggregate summary
    with open(reports_dir / "summary.json", "w", encoding="utf8") as f:
        json.dump({"summary": summary, "results": results}, f, indent=2, ensure_ascii=False)
    return summary, results

# CLI / Streamlit app
if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="TEIA Auditoria Total (CLI)")
    parser.add_argument("--inputs", default="bench_inputs", help="Pasta com arquivos originais")
    parser.add_argument("--reports", default="bench_reports", help="Pasta de relatórios JSON")
    parser.add_argument("--restored", default="bench_restored", help="Pasta para arquivos restaurados")
    args = parser.parse_args()
    s, r = run_benchmark(Path(args.inputs), Path(args.reports), Path(args.restored))
    print("Resumo:", s)
else:
    try:
        import streamlit as st
        import pandas as pd
        import plotly.express as px
    except Exception as e:
        raise RuntimeError("Streamlit / pandas / plotly necessários para UI: " + str(e))

    st.set_page_config(layout="wide", page_title="TEIA Auditoria Total")
    st.title("TEIA — Auditoria Técnica Completa (Procedural)")

    st.sidebar.header("Config")
    in_dir = st.sidebar.text_input("Pasta de inputs", value="bench_inputs")
    reports_dir = st.sidebar.text_input("Pasta de relatórios", value="bench_reports")
    restored_dir = st.sidebar.text_input("Pasta de restaurados", value="bench_restored")
    use_proc = st.sidebar.checkbox("Usar procedural_codec se disponível", value=True)
    run_btn = st.sidebar.button("Run benchmark (processar todos arquivos)")

    if run_btn:
        with st.spinner("Rodando pipeline..."):
            summary, results = run_benchmark(Path(in_dir), Path(reports_dir), Path(restored_dir), use_proc_codec=use_proc)
        st.success("Execução concluída")
        st.write("Resumo:", summary)

    rep_path = Path(reports_dir)
    if rep_path.exists():
        all_reports = []
        for f in rep_path.glob("relatorio_*.json"):
            try:
                all_reports.append(json.load(open(f, "r", encoding="utf8")))
            except Exception:
                pass
        if all_reports:
            df = pd.DataFrame(all_reports)
            st.subheader("Tabela técnica (por arquivo)")
            cols = [c for c in [
                "nome_arquivo","tipo_mime","tamanho_original_MB","tamanho_seed_MB",
                "tempo_leitura_s","tempo_seed_s","tempo_restauracao_s",
                "tempo_total_pipeline_s","bitwise_ok","integridade_ok","score_inovacao"
            ] if c in df.columns]
            st.dataframe(df[cols].fillna(""))

            comp_df = []
            for r in all_reports:
                comp_df.append({
                    "arquivo": r["nome_arquivo"],
                    "original_MB": r.get("tamanho_original_MB",0),
                    "seed_MB": r.get("tamanho_seed_MB",0),
                    "zip_MB": r.get("zip",{}).get("tamanho_MB",0),
                    "gzip_MB": r.get("gzip",{}).get("tamanho_MB",0),
                    "lzma_MB": r.get("lzma",{}).get("tamanho_MB",0)
                })
            cdf = pd.DataFrame(comp_df).set_index("arquivo")
            st.subheader("Tamanhos: Original vs Seed vs Zip/Gzip/Lzma")
            st.plotly_chart(px.bar(cdf.reset_index().melt(id_vars="arquivo"), x="arquivo", y="value", color="variable", barmode="group"), use_container_width=True)

            times = []
            for r in all_reports:
                times.append({
                    "arquivo": r["nome_arquivo"],
                    "seed_s": r.get("tempo_seed_s",0),
                    "zip_s": r.get("zip",{}).get("tempo_s",0)
                })
            tdf = pd.DataFrame(times)
            st.subheader("Tempos: procedural vs zip")
            st.plotly_chart(px.bar(tdf.melt(id_vars="arquivo"), x="arquivo", y="value", color="variable", barmode="group"), use_container_width=True)

            df_mime = pd.DataFrame(all_reports)
            df_mime['mime_top'] = df_mime['tipo_mime'].fillna("unknown").apply(lambda s: s.split('/')[0])
            heat = df_mime.groupby('mime_top').agg({'compressao_procedural_%':'mean','score_inovacao':'mean'}).reset_index()
            if not heat.empty:
                st.subheader("Eficiência média por tipo (mime top)")
                st.plotly_chart(px.imshow(heat.set_index('mime_top').T, text_auto=True), use_container_width=True)

            zip_btn = st.button("Exportar .zip completo (relatórios + restaurados)")
            if zip_btn:
                tmpzip = Path(tempfile.gettempdir()) / f"teia_audit_{now_ts()}.zip"
                with zipfile.ZipFile(tmpzip, "w", compression=zipfile.ZIP_DEFLATED) as zf:
                    for f in rep_path.glob("*.json"):
                        zf.write(f, arcname=f"reports/{f.name}")
                    rest = Path(restored_dir)
                    if rest.exists():
                        for f in rest.glob("*"):
                            zf.write(f, arcname=f"restored/{f.name}")
                with open(tmpzip, "rb") as fh:
                    st.download_button("Download .zip", fh.read(), file_name=tmpzip.name, mime="application/zip")
        else:
            st.info("Nenhum relatório encontrado em " + str(rep_path))
    else:
        st.info(f"Pasta de relatórios '{reports_dir}' não existe ainda. Rode o benchmark primeiro.")
'@ | Out-File -FilePath $dashPath -Encoding utf8 -Force

Write-Host "Criado/Atualizado: $dashPath"

# 4) criar pastas auxiliares
$dirs = @("bench_inputs","bench_reports","bench_restored")
foreach ($d in $dirs) {
  $p = Join-Path $ROOT $d
  if (-not (Test-Path $p)) {
    New-Item -ItemType Directory -Path $p | Out-Null
    Write-Host "Criado: $p"
  } else {
    Write-Host "Existe: $p"
  }
}

# 5) preparar logs dir
$logs = "C:\Temp\teia_streamlit_logs"
if (-not (Test-Path $logs)) { New-Item -ItemType Directory -Path $logs | Out-Null; Write-Host "Criado logs: $logs" }

# 6) localizar python
$pythonCmd = $null
$cmd = Get-Command python -ErrorAction SilentlyContinue
if ($cmd) { $pythonCmd = $cmd.Source } else {
  $py = Get-ChildItem -Path "$env:USERPROFILE\AppData\Local\Programs\Python" -Recurse -Filter python.exe -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($py) { $pythonCmd = $py.FullName }
}
if (-not $pythonCmd) {
  Write-Error "Python não encontrado no PATH. Abra o terminal do seu ambiente Python e instale dependências manualmente."
  exit 1
}
Write-Host "Usando Python: $pythonCmd"

# 7) instalar sympy (e opcionalmente streamlit/pandas/plotly) — idempotente
Write-Host "Instalando / garantindo dependências (sympy)..."
& $pythonCmd -m pip install --upgrade pip | Out-Null
& $pythonCmd -m pip install sympy streamlit pandas plotly --disable-pip-version-check

# 8) rodar o guard para checar se ainda há shadowing
Write-Host "Executando guard de shadowing..."
& $pythonCmd -c "import teia_shadow_guard; teia_shadow_guard.ensure_no_shadowing(raise_on_conflict=False); print('Guard executed')"

# 9) iniciar Streamlit em background: dashboard_teia_auditoria_total.py
$dashFile = Join-Path $ROOT "dashboard_teia_auditoria_total.py"
if (-not (Test-Path $dashFile)) { Write-Error "Dashboard não encontrado: $dashFile"; exit 1 }

Write-Host "Iniciando Streamlit em background..."
$stdout = Join-Path $logs "streamlit_stdout_$ts.log"
$stderr = Join-Path $logs "streamlit_stderr_$ts.log"

# Start-Process: use ArgumentList as array to avoid quoting headaches
$argList = "-m streamlit run `"$dashFile`" --server.headless true"
$proc = Start-Process -FilePath $pythonCmd -ArgumentList $argList -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru

if ($proc) {
  Write-Host "Streamlit iniciado (PID: $($proc.Id)). Logs: $stdout  $stderr"
  Write-Host "Abra: http://localhost:8501"
  # salvar PID para possível Stop
  $pidfile = Join-Path $ROOT "teia_streamlit_pid.txt"
  Set-Content -Path $pidfile -Value $proc.Id
  Write-Host "PID salvo em: $pidfile"
} else {
  Write-Warning "Falha ao iniciar Streamlit via Start-Process. Tente rodar manualmente: python -m streamlit run $dashFile"
}

Write-Host "Operação concluída."
