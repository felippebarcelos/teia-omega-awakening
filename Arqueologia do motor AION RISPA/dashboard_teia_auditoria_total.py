"""
dashboard_teia_auditoria_total.py

Painel TEIA: Auditoria Total (CLI + Streamlit optional)
Gera relatórios por arquivo, salva seeds, restored, relatório JSON e .zip final.
Funcionalidades principais:
 - Leitura e medição de tempo (time.perf_counter)
 - Geração de seed (usa procedural_codec.encode/decode se disponível)
 - Salva seed (.seed base64) e metadados
 - Restauração e verificação bit-a-bit + hashes
 - Comparação com zip/gzip/lzma/bz2
 - Entropia do arquivo
 - Estimativas simbólicas de RAM/energia
 - Score de inovação (configurável)
 - Modo watch/poll para reprocessar quando inputs mudarem
 - Modo CLI (default) + opção de iniciar UI Streamlit (se instalado)

Como usar (CLI):
 python dashboard_teia_auditoria_total.py --inputs bench_inputs --reports bench_reports --restored bench_restored

Como usar (UI):
 python -m streamlit run dashboard_teia_auditoria_total.py

Observação: Se não houver módulo `procedural_codec`, um fallback (zlib+base64) será usado.
"""

import argparse
import base64
import hashlib
import io
import json
import math
import mimetypes
import os
import shutil
import sys
import tempfile
import time
import traceback
from collections import Counter
from pathlib import Path

# compressions
import gzip
import zipfile
import lzma
import bz2

# tentativa de importar codec procedural (opcional)
HAS_PROC_CODEC = False
try:
    import procedural_codec as _pc
    if hasattr(_pc, "encode") and hasattr(_pc, "decode"):
        HAS_PROC_CODEC = True
        proc_encode = _pc.encode
        proc_decode = _pc.decode
except Exception:
    HAS_PROC_CODEC = False

# identidade técnica do método (hash do código se existir)
def identity_of_codec():
    info = {"has_proc_codec": HAS_PROC_CODEC}
    if HAS_PROC_CODEC:
        try:
            src = Path(_pc.__file__).read_bytes()
            info["codec_path"] = str(Path(_pc.__file__).resolve())
            info["codec_sha256"] = hashlib.sha256(src).hexdigest()
        except Exception:
            info["codec_path"] = getattr(_pc, "__file__", None)
    else:
        info["codec_path"] = None
    return info

# utilitários

def sha256_hex(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def bytes_to_mb(n: int) -> float:
    return round(float(n) / (1024.0 * 1024.0), 6)


def now_ts():
    return time.strftime("%Y%m%d_%H%M%S")


def entropy_bytes(b: bytes) -> float:
    if not b:
        return 0.0
    freq = Counter(b)
    l = len(b)
    e = -sum((count / l) * math.log2(count / l) for count in freq.values())
    return round(e, 6)


# fallback procedural encoder: zlib compress + base64
import zlib

def fallback_encode(data: bytes):
    comp = zlib.compress(data, level=6)
    seed = base64.b64encode(comp)
    meta = {"method": "zlib+base64", "orig_len": len(data), "seed_len": len(seed)}
    return seed, meta


def fallback_decode(seed: bytes):
    comp = base64.b64decode(seed)
    return zlib.decompress(comp)


# compressions helpers (return size_bytes, time_s)

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
    return int(size), float(t1 - t0)


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


def compress_bz2_bytes(data: bytes):
    t0 = time.perf_counter()
    out = bz2.compress(data, compresslevel=9)
    t1 = time.perf_counter()
    return len(out), t1 - t0


# salvar seed em arquivo (base64)

def save_seed_file(outdir: Path, filename: str, seed: bytes, meta: dict):
    outdir.mkdir(parents=True, exist_ok=True)
    seed_name = outdir / f"{filename}.seed"
    seed_name.write_bytes(seed)
    meta_name = outdir / f"{filename}.seed.meta.json"
    with meta_name.open("w", encoding="utf8") as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)
    return seed_name


# montagem do relatório por arquivo

def process_file(fp: Path, out_reports_dir: Path, seeds_dir: Path, restored_dir: Path, use_proc_codec=True, score_params=None):
    report = {}
    t_read0 = time.perf_counter()
    raw = fp.read_bytes()
    t_read1 = time.perf_counter()

    report['nome_arquivo'] = fp.name
    report['caminho'] = str(fp.resolve())
    report['tipo_mime'] = mimetypes.guess_type(fp.name)[0] or "unknown"
    report['tamanho_original_bytes'] = len(raw)
    report['tamanho_original_MB'] = bytes_to_mb(len(raw))
    report['entropia_arquivo'] = entropy_bytes(raw)
    report['tempo_leitura_s'] = round(t_read1 - t_read0, 9)

    # procedural encode
    t_seed0 = time.perf_counter()
    try:
        if use_proc_codec and HAS_PROC_CODEC:
            seed, seed_meta = proc_encode(raw)
            seed_bytes = seed if isinstance(seed, (bytes, bytearray)) else seed.encode('utf8')
        else:
            seed, seed_meta = fallback_encode(raw)
            seed_bytes = seed
        seed_ok = True
    except Exception as e:
        seed_bytes = b""
        seed_meta = {"error": str(e)}
        seed_ok = False
    t_seed1 = time.perf_counter()

    report['seed_meta'] = seed_meta
    report['tamanho_seed_bytes'] = len(seed_bytes)
    report['tamanho_seed_MB'] = bytes_to_mb(len(seed_bytes))
    report['tempo_seed_s'] = round(t_seed1 - t_seed0, 9)
    report['hash_seed'] = sha256_hex(seed_bytes) if seed_bytes else None

    # save seed file
    if seed_ok and seed_bytes:
        try:
            save_seed_file(seeds_dir, fp.name, seed_bytes, seed_meta)
        except Exception:
            pass

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
    report['tempo_restauracao_s'] = round(t_rest1 - t_rest0, 9)

    report['hash_original'] = sha256_hex(raw)
    report['hash_restaurado'] = sha256_hex(restored) if restored_ok else None
    report['bitwise_ok'] = bool(restored_ok and raw == restored)
    report['integridade_ok'] = report['bitwise_ok'] and (report['hash_original'] == report['hash_restaurado'])

    # save restored if OK
    if report['bitwise_ok']:
        try:
            restored_dir.mkdir(parents=True, exist_ok=True)
            (restored_dir / fp.name).write_bytes(restored)
        except Exception:
            pass

    # compressions
    try:
        z_size, z_time = compress_zip_bytes(raw)
    except Exception:
        z_size, z_time = None, None
    try:
        g_size, g_time = compress_gzip_bytes(raw)
    except Exception:
        g_size, g_time = None, None
    try:
        l_size, l_time = compress_lzma_bytes(raw)
    except Exception:
        l_size, l_time = None, None
    try:
        b_size, b_time = compress_bz2_bytes(raw)
    except Exception:
        b_size, b_time = None, None

    report['zip'] = {'tamanho_bytes': z_size, 'tamanho_MB': bytes_to_mb(z_size) if z_size else None, 'tempo_s': round(z_time,9) if z_time else None}
    report['gzip'] = {'tamanho_bytes': g_size, 'tamanho_MB': bytes_to_mb(g_size) if g_size else None, 'tempo_s': round(g_time,9) if g_time else None}
    report['lzma'] = {'tamanho_bytes': l_size, 'tamanho_MB': bytes_to_mb(l_size) if l_size else None, 'tempo_s': round(l_time,9) if l_time else None}
    report['bz2'] = {'tamanho_bytes': b_size, 'tamanho_MB': bytes_to_mb(b_size) if b_size else None, 'tempo_s': round(b_time,9) if b_time else None}

    # compression metrics
    def comp_pct(original, new):
        try:
            if original is None or new is None:
                return None
            return round(((original - new) / original) * 100.0, 6)
        except Exception:
            return None

    orig_len = len(raw)
    report['compressao_procedural_%'] = comp_pct(orig_len, len(seed_bytes)) if seed_bytes else None
    report['compressao_zip_%'] = comp_pct(orig_len, z_size)
    report['compressao_gzip_%'] = comp_pct(orig_len, g_size)
    report['compressao_lzma_%'] = comp_pct(orig_len, l_size)
    report['compressao_bz2_%'] = comp_pct(orig_len, b_size)

    # times summary
    report['tempo_zip_s'] = report['zip']['tempo_s']
    report['tempo_unzip_s'] = None

    # environment
    try:
        import platform as _pf
        env = {
            "platform": _pf.platform(),
            "python_version": _pf.python_version(),
            "processor": _pf.processor(),
            "machine": _pf.machine(),
            "timestamp": now_ts()
        }
    except Exception:
        env = {"platform": sys.platform, "python_version": sys.version}
    report['ambiente'] = env

    # simulated resources
    tempo_total = sum(x for x in [report.get('tempo_leitura_s') or 0.0, report.get('tempo_seed_s') or 0.0, report.get('tempo_restauracao_s') or 0.0, report.get('tempo_zip_s') or 0.0] if x is not None)
    report['tempo_total_pipeline_s'] = round(tempo_total, 9)
    report['ram_simulada_MB'] = round(1 + (report['tamanho_original_MB'] * 0.1), 3)
    report['energia_simulada_mWh'] = round(tempo_total * 0.05, 6)

    # innovation score (configurable params)
    score = 0
    p = score_params or {}
    # weights and thresholds (defaults close to checklist)
    if report.get('compressao_procedural_%') is not None and report['compressao_procedural_%'] > 0:
        score += p.get('compressao_positiva', 15)
    if report.get('tempo_restauracao_s') is not None and report['tempo_restauracao_s'] < p.get('tempo_restauracao_thresh', 0.02):
        score += p.get('tempo_restauracao_bonus', 10)
    if report.get('bitwise_ok') and report.get('hash_original') == report.get('hash_restaurado'):
        score += p.get('integridade_bonus', 25)
    if report.get('tamanho_seed_MB') is not None and report['tamanho_seed_MB'] < (p.get('seed_frac_thresh', 0.10) * report['tamanho_original_MB']):
        score += p.get('seed_size_bonus', 20)
    faster_than_zip = False
    try:
        faster_than_zip = report.get('tempo_seed_s') is not None and report.get('tempo_zip_s') is not None and report['tempo_seed_s'] < report['tempo_zip_s']
    except Exception:
        faster_than_zip = False
    if faster_than_zip:
        score += p.get('faster_than_zip_bonus', 15)
    # Pyto / ios detection
    pf = env.get('platform','').lower()
    if 'ios' in pf or 'pyto' in env.get('python_version','').lower():
        score += p.get('pyto_bonus', 15)
    report['score_inovacao'] = min(100, score)

    # identity block
    report['identidade_metodo'] = identity_of_codec()

    # save report
    out_reports_dir.mkdir(parents=True, exist_ok=True)
    report_path = out_reports_dir / f"relatorio_{fp.name}.json"
    with report_path.open('w', encoding='utf8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)

    return report, report_path


# orchestration: run benchmark over folder

def run_benchmark(input_dir: Path,
                  reports_dir: Path,
                  export_restored_dir: Path,
                  seeds_dir: Path,
                  use_proc_codec=True,
                  score_params=None):
    results = []
    input_dir = Path(input_dir)
    reports_dir = Path(reports_dir)
    export_restored_dir = Path(export_restored_dir)
    seeds_dir = Path(seeds_dir)
    reports_dir.mkdir(parents=True, exist_ok=True)
    export_restored_dir.mkdir(parents=True, exist_ok=True)
    seeds_dir.mkdir(parents=True, exist_ok=True)

    files = sorted([p for p in input_dir.iterdir() if p.is_file()])
    t0 = time.perf_counter()
    for p in files:
        try:
            r, path = process_file(p, reports_dir, seeds_dir, export_restored_dir, use_proc_codec=use_proc_codec, score_params=score_params)
            results.append(r)
        except Exception:
            tb = traceback.format_exc()
            results.append({"nome_arquivo": p.name, "error": tb})
    t1 = time.perf_counter()
    summary = {
        "run_timestamp": now_ts(),
        "num_files": len(files),
        "total_time_s": round(t1 - t0, 6),
        "reports_dir": str(reports_dir),
        "seeds_dir": str(seeds_dir),
        "restored_dir": str(export_restored_dir)
    }
    with (reports_dir / "summary.json").open('w', encoding='utf8') as f:
        json.dump({"summary": summary, "results": results}, f, indent=2, ensure_ascii=False)
    return summary, results


# quick export zip

def export_full_zip(reports_dir: Path, seeds_dir: Path, restored_dir: Path, out_zip: Path):
    with zipfile.ZipFile(out_zip, 'w', compression=zipfile.ZIP_DEFLATED) as zf:
        if reports_dir.exists():
            for f in reports_dir.glob('*.json'):
                zf.write(f, arcname=f"reports/{f.name}")
        if seeds_dir.exists():
            for f in seeds_dir.glob('*'):
                zf.write(f, arcname=f"seeds/{f.name}")
        if restored_dir.exists():
            for f in restored_dir.glob('*'):
                zf.write(f, arcname=f"restored/{f.name}")
    return out_zip


# simple poll/watch loop to re-run when inputs change

def watch_and_run(input_dir: Path, interval_s: float, **kwargs):
    last_mtimes = {}
    input_dir = Path(input_dir)
    try:
        while True:
            changed = False
            current_files = [p for p in input_dir.iterdir() if p.is_file()]
            cur_m = {}
            for p in current_files:
                try:
                    cur_m[p.name] = p.stat().st_mtime
                except Exception:
                    cur_m[p.name] = None
            # compare
            if set(cur_m.keys()) != set(last_mtimes.keys()):
                changed = True
            else:
                for k, v in cur_m.items():
                    if last_mtimes.get(k) != v:
                        changed = True
                        break
            if changed:
                print(f"[{now_ts()}] Mudança detectada — rodando benchmark...")
                run_benchmark(**kwargs)
                last_mtimes = cur_m
            time.sleep(interval_s)
    except KeyboardInterrupt:
        print("Watch interrompido pelo usuário.")


# CLI/entrypoint

def main():
    parser = argparse.ArgumentParser(description='TEIA Auditoria Total')
    parser.add_argument('--inputs', default='bench_inputs')
    parser.add_argument('--reports', default='bench_reports')
    parser.add_argument('--restored', default='bench_restored')
    parser.add_argument('--seeds', default='bench_seeds')
    parser.add_argument('--watch', action='store_true', help='Ficar observando pasta de inputs e reprocessar quando mudar')
    parser.add_argument('--watch-interval', type=float, default=3.0)
    parser.add_argument('--no-proc', action='store_true', help='Não usar procedural_codec mesmo se disponível')
    parser.add_argument('--export-zip', action='store_true', help='Gerar zip final após execução')
    parser.add_argument('--ui', action='store_true', help='Iniciar Streamlit UI (se streamlit disponível)')
    args = parser.parse_args()

    inputs = Path(args.inputs)
    reports = Path(args.reports)
    restored = Path(args.restored)
    seeds = Path(args.seeds)

    if args.ui:
        # try to import streamlit and delegate to the app view
        try:
            import streamlit as st
            import pandas as pd
            import plotly.express as px
        except Exception as e:
            print("Streamlit / pandas / plotly não disponíveis no ambiente:", e)
            sys.exit(1)

        st.set_page_config(layout="wide", page_title="TEIA Auditoria Total")
        st.title("TEIA — Auditoria Técnica Completa (Procedural)")

        st.sidebar.header("Config")
        in_dir = st.sidebar.text_input("Pasta de inputs", value=str(inputs))
        reports_dir = st.sidebar.text_input("Pasta de relatórios", value=str(reports))
        restored_dir = st.sidebar.text_input("Pasta de restaurados", value=str(restored))
        seeds_dir = st.sidebar.text_input("Pasta de seeds", value=str(seeds))
        use_proc = st.sidebar.checkbox("Usar procedural_codec se disponível", value=HAS_PROC_CODEC and not args.no_proc)
        run_btn = st.sidebar.button("Run benchmark (processar todos arquivos)")

        if run_btn:
            with st.spinner("Rodando pipeline..."):
                summary, results = run_benchmark(Path(in_dir), Path(reports_dir), Path(restored_dir), Path(seeds_dir), use_proc)
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
                st.dataframe(df)

                # Gráficos simplificados
                comp_df = []
                for r in all_reports:
                    comp_df.append({
                        "arquivo": r["nome_arquivo"],
                        "original_MB": r["tamanho_original_MB"],
                        "seed_MB": r["tamanho_seed_MB"],
                        "zip_MB": r["zip"]["tamanho_MB"] if r.get("zip") else None,
                        "gzip_MB": r["gzip"]["tamanho_MB"] if r.get("gzip") else None,
                        "lzma_MB": r["lzma"]["tamanho_MB"] if r.get("lzma") else None,
                        "bz2_MB": r["bz2"]["tamanho_MB"] if r.get("bz2") else None,
                    })
                cdf = pd.DataFrame(comp_df).set_index("arquivo")
                st.subheader("Tamanhos: Original vs Seed vs Zip/Gzip/Lzma/Bz2")
                st.plotly_chart(px.bar(cdf.reset_index().melt(id_vars="arquivo"), x="arquivo", y="value", color="variable", barmode="group"), use_container_width=True)

                # exportar zip
                if st.button("Exportar .zip completo (relatórios + seeds + restaurados)"):
                    tmpzip = Path(tempfile.gettempdir()) / f"teia_audit_{now_ts()}.zip"
                    export_full_zip(reports, seeds, restored, tmpzip)
                    with tmpzip.open('rb') as fh:
                        st.download_button("Download .zip", fh.read(), file_name=tmpzip.name, mime="application/zip")
            else:
                st.info("Nenhum relatório encontrado em " + str(rep_path))
        else:
            st.info(f"Pasta de relatórios '{reports_dir}' não existe ainda. Rode o benchmark primeiro.")

        return

    # modo CLI: run once or watch
    use_proc_codec = HAS_PROC_CODEC and not args.no_proc
    if args.watch:
        print("Entrando em modo watch (poll). Ctrl-C para sair.")
        watch_and_run(str(inputs), args.watch_interval, input_dir=inputs, reports_dir=reports, export_restored_dir=restored, seeds_dir=seeds, use_proc_codec=use_proc_codec)
        return

    summary, results = run_benchmark(inputs, reports, restored, seeds, use_proc_codec=use_proc_codec)
    print("Resumo:", summary)

    if args.export_zip:
        outzip = Path(tempfile.gettempdir()) / f"teia_audit_{now_ts()}.zip"
        export_full_zip(reports, seeds, restored, outzip)
        print("Zip gerado:", outzip)


if __name__ == '__main__':
    main()
