"""
TEIA-Mmap-Engine.py — Motor de ingestao de alta entropia via mmap
Processa arquivos massivos em blocos sem carregar em RAM fisica.
Saida: linhas de progresso para stdout + SR-REF JSON em <seeds-dir>.
"""

import argparse
import ctypes
import hashlib
import json
import mmap
import os
import sys
import time
from pathlib import Path
from datetime import datetime

CHUNK_MB_PADRAO = 256

# ── RSS via Win32 API (mesmo padrao validado no benchmark chunked) ─────────────
class _PMC(ctypes.Structure):
    _fields_ = [
        ('cb',                         ctypes.c_uint32),
        ('PageFaultCount',             ctypes.c_uint32),
        ('PeakWorkingSetSize',         ctypes.c_size_t),
        ('WorkingSetSize',             ctypes.c_size_t),
        ('QuotaPeakPagedPoolUsage',    ctypes.c_size_t),
        ('QuotaPagedPoolUsage',        ctypes.c_size_t),
        ('QuotaPeakNonPagedPoolUsage', ctypes.c_size_t),
        ('QuotaNonPagedPoolUsage',     ctypes.c_size_t),
        ('PagefileUsage',              ctypes.c_size_t),
        ('PeakPagefileUsage',          ctypes.c_size_t),
    ]

_k32 = ctypes.WinDLL('kernel32')
_ps  = ctypes.WinDLL('psapi')
_k32.GetCurrentProcess.restype  = ctypes.c_void_p
_k32.GetCurrentProcess.argtypes = []
_ps.GetProcessMemoryInfo.restype  = ctypes.c_bool
_ps.GetProcessMemoryInfo.argtypes = [
    ctypes.c_void_p, ctypes.POINTER(_PMC), ctypes.c_uint32
]

def _get_pmc() -> _PMC:
    pmc = _PMC()
    pmc.cb = ctypes.sizeof(_PMC)
    h = _k32.GetCurrentProcess()
    _ps.GetProcessMemoryInfo(h, ctypes.byref(pmc), pmc.cb)
    return pmc

def get_rss_mb() -> float:
    try:
        return _get_pmc().WorkingSetSize / (1024 * 1024)
    except Exception:
        return 0.0

def get_peak_rss_mb() -> float:
    try:
        return _get_pmc().PeakWorkingSetSize / (1024 * 1024)
    except Exception:
        return 0.0

# ── Ingestao principal ─────────────────────────────────────────────────────────
_ALLOC_GRAN = getattr(mmap, 'ALLOC_GRANULARITY', 65536)  # 64 KB no Windows

def ingest_file(input_path: Path, seeds_dir: Path, chunk_mb: int) -> dict:
    chunk_size   = chunk_mb * 1024 * 1024
    file_size    = input_path.stat().st_size
    chunks_total = (file_size + chunk_size - 1) // chunk_size

    rss_inicial = get_rss_mb()
    print(f"[MMAP] Arquivo      : {input_path.name}", flush=True)
    print(f"[MMAP] Tamanho      : {file_size / (1024**3):.4f} GB ({file_size} bytes)", flush=True)
    print(f"[MMAP] Chunk size   : {chunk_mb} MB | Chunks total: {chunks_total}", flush=True)
    print(f"[MMAP] Estrategia   : mmap parcial por chunk (map + unmap) + zero-copy memoryview", flush=True)
    print(f"[MMAP] RSS inicial  : {rss_inicial:.1f} MB", flush=True)

    sha       = hashlib.sha256()
    t_start   = time.perf_counter()
    rss_max   = rss_inicial
    chunks_ok = 0
    offset    = 0

    with open(input_path, 'rb') as fh:
        fd = fh.fileno()
        while offset < file_size:
            # Alinha offset ao ALLOC_GRANULARITY (exigencia do Windows para mmap com offset)
            aligned = (offset // _ALLOC_GRAN) * _ALLOC_GRAN
            adjust  = offset - aligned                       # bytes de ajuste dentro do map
            to_read = min(chunk_size, file_size - offset)
            map_len = adjust + to_read                       # tamanho do mapeamento parcial

            # Mapeia apenas este chunk — zero-copy via memoryview — fecha ao final
            # Ao fechar mm, o OS pode liberar as paginas fisicas: RSS permanece marginal
            mm = mmap.mmap(fd, map_len, access=mmap.ACCESS_READ, offset=aligned)
            try:
                sha.update(memoryview(mm)[adjust: adjust + to_read])
            finally:
                mm.close()   # UnmapViewOfFile — libera paginas do chunk anterior

            offset    += to_read
            chunks_ok += 1

            rss_now = get_rss_mb()
            if rss_now > rss_max:
                rss_max = rss_now

            elapsed = time.perf_counter() - t_start
            mbps    = (offset / (1024**2)) / elapsed if elapsed > 0 else 0.0
            pct     = int(offset * 100 / file_size)
            print(
                f"[MMAP] [{pct:3d}%] Chunk {chunks_ok:02d}/{chunks_total} | "
                f"{offset/(1024**2):.0f} / {file_size/(1024**2):.0f} MB | "
                f"{mbps:.0f} MB/s | RSS {rss_now:.1f} MB",
                flush=True,
            )

    elapsed_total = time.perf_counter() - t_start
    sha256_hex    = sha.hexdigest()
    pico_rss      = get_peak_rss_mb()
    throughput    = (file_size / (1024**2)) / elapsed_total if elapsed_total > 0 else 0.0

    delta_ram_economia = file_size / (1024**2) - pico_rss
    print(f"[MMAP] Concluido    : {elapsed_total:.2f}s | {throughput:.1f} MB/s", flush=True)
    print(f"[MMAP] Pico RSS     : {pico_rss:.1f} MB (Delta RAM economizado: {delta_ram_economia:.0f} MB)", flush=True)
    print(f"[MMAP] SHA-256      : {sha256_hex}", flush=True)

    srref = {
        "v":                   "SR-REF-1.0",
        "tipo":                "referencial",
        "motor":               "mmap-sha256",
        "arquivo_original":    input_path.name,
        "sha256":              sha256_hex,
        "tamanho_bytes":       file_size,
        "tamanho_gb":          round(file_size / (1024**3), 6),
        "chunk_mb":            chunk_mb,
        "chunks_processados":  chunks_ok,
        "rss_inicial_mb":      round(rss_inicial, 2),
        "pico_rss_mb":         round(pico_rss, 2),
        "delta_ram_economia_mb": round(delta_ram_economia, 2),
        "throughput_mbs":      round(throughput, 2),
        "elapsed_s":           round(elapsed_total, 3),
        "gerado_em":           datetime.now().strftime('%Y-%m-%dT%H:%M:%S'),
    }

    seed_name = input_path.name + '.srref.json'
    seed_path = seeds_dir / seed_name
    seeds_dir.mkdir(parents=True, exist_ok=True)
    with open(seed_path, 'w', encoding='utf-8') as sf:
        json.dump(srref, sf, indent=2, ensure_ascii=False)

    print(f"[MMAP] SR-REF salva : {seed_path}", flush=True)
    # Ultima linha e o JSON canonico (facil de parsear pelo watcher)
    print("SRREF_JSON:" + json.dumps(srref, ensure_ascii=False), flush=True)
    return srref


def main():
    ap = argparse.ArgumentParser(description='TEIA-Mmap-Engine — ingestao via mmap')
    ap.add_argument('--input',     required=True, help='Arquivo a ingerir')
    ap.add_argument('--seeds-dir', required=True, help='Pasta destino da SR-REF')
    ap.add_argument('--chunk-mb',  type=int, default=CHUNK_MB_PADRAO, help='Chunk em MB')
    args = ap.parse_args()

    input_path = Path(args.input).resolve()
    seeds_dir  = Path(args.seeds_dir).resolve()

    if not input_path.exists():
        print(f"[ERRO] Arquivo nao encontrado: {input_path}", file=sys.stderr, flush=True)
        sys.exit(1)

    try:
        ingest_file(input_path, seeds_dir, args.chunk_mb)
        sys.exit(0)
    except Exception as exc:
        print(f"[ERRO] {exc}", file=sys.stderr, flush=True)
        import traceback
        traceback.print_exc(file=sys.stderr)
        sys.exit(2)


if __name__ == '__main__':
    main()
