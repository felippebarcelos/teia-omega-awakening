#!/usr/bin/env python3
"""
TEIA-Benchmark-Chunked.py
Prova empirica AION RISPA — naive load vs stream chunk on demand

Arquivo matricial virtual: 40 GB (gerado deterministicamente, sem disco)
Hardware alvo            : 16 GB RAM
Invariante               : palavra "Delta" nunca como simbolo matematico
"""
import sys, os, gc, time, hashlib, json, ctypes, subprocess
from datetime import datetime
from pathlib import Path

TARGET_BYTES = 40  * 1024 ** 3   # 40 GB
CHUNK_BYTES  = 512 * 1024 ** 2   # 512 MB
LOG_PATH     = Path("D:/TEIA_CLAUDE_AWAKENING/TEIA-Benchmark-Chunked.log.json")

# Padrao base do chunk virtual (256 bytes deterministicos, semente do stream)
_BASE_PATTERN = bytes(range(256))

# ── Medicao de RAM via Windows API (sem dependencias externas) ────────────────
# Python 3.14: restype/argtypes obrigatorios — windll infere c_int por padrao,
# truncando o handle de 64 bits e silenciando o erro de GetProcessMemoryInfo.
class _PMC(ctypes.Structure):
    _fields_ = [
        ("cb",                         ctypes.c_uint32),
        ("PageFaultCount",             ctypes.c_uint32),
        ("PeakWorkingSetSize",         ctypes.c_size_t),
        ("WorkingSetSize",             ctypes.c_size_t),
        ("QuotaPeakPagedPoolUsage",    ctypes.c_size_t),
        ("QuotaPagedPoolUsage",        ctypes.c_size_t),
        ("QuotaPeakNonPagedPoolUsage", ctypes.c_size_t),
        ("QuotaNonPagedPoolUsage",     ctypes.c_size_t),
        ("PagefileUsage",              ctypes.c_size_t),
        ("PeakPagefileUsage",          ctypes.c_size_t),
    ]

_kernel32 = ctypes.WinDLL("kernel32")
_psapi    = ctypes.WinDLL("psapi")

_kernel32.GetCurrentProcess.restype  = ctypes.c_void_p
_kernel32.GetCurrentProcess.argtypes = []

_psapi.GetProcessMemoryInfo.restype  = ctypes.c_bool
_psapi.GetProcessMemoryInfo.argtypes = [
    ctypes.c_void_p,
    ctypes.POINTER(_PMC),
    ctypes.c_uint32,
]

def _pmc() -> _PMC:
    p   = _PMC()
    p.cb = ctypes.sizeof(p)
    handle = _kernel32.GetCurrentProcess()
    ok = _psapi.GetProcessMemoryInfo(handle, ctypes.byref(p), p.cb)
    if not ok:
        raise OSError(f"GetProcessMemoryInfo falhou (handle={handle:#x})")
    return p

def rss_mb()         -> float: return _pmc().WorkingSetSize    / (1024 * 1024)
def peak_commit_mb() -> float: return _pmc().PeakPagefileUsage / (1024 * 1024)

# ── Gerador de chunk virtual deterministico (sem I/O de disco) ───────────────
def make_virtual_chunk(size: int) -> bytes:
    """
    Gera 'size' bytes via repeticao do padrao [0x00..0xFF].
    Nenhum arquivo em disco — puramente in-memory, descartavel apos o uso.
    """
    q, r = divmod(size, 256)
    return _BASE_PATTERN * q + _BASE_PATTERN[:r]

# ── FASE 1: Prova de colapso — alocacao ingenua de 40 GB ─────────────────────
# Executada em subprocesso isolado para nao arriscar a sessao principal.
_FASE1_INNER = r"""
import ctypes, gc, time, sys

class _PMC(ctypes.Structure):
    _fields_ = [
        ("cb",                         ctypes.c_uint32),
        ("PageFaultCount",             ctypes.c_uint32),
        ("PeakWorkingSetSize",         ctypes.c_size_t),
        ("WorkingSetSize",             ctypes.c_size_t),
        ("QuotaPeakPagedPoolUsage",    ctypes.c_size_t),
        ("QuotaPagedPoolUsage",        ctypes.c_size_t),
        ("QuotaPeakNonPagedPoolUsage", ctypes.c_size_t),
        ("QuotaNonPagedPoolUsage",     ctypes.c_size_t),
        ("PagefileUsage",              ctypes.c_size_t),
        ("PeakPagefileUsage",          ctypes.c_size_t),
    ]

_k32   = ctypes.WinDLL("kernel32")
_psapi = ctypes.WinDLL("psapi")
_k32.GetCurrentProcess.restype  = ctypes.c_void_p
_k32.GetCurrentProcess.argtypes = []
_psapi.GetProcessMemoryInfo.restype  = ctypes.c_bool
_psapi.GetProcessMemoryInfo.argtypes = [ctypes.c_void_p, ctypes.POINTER(_PMC), ctypes.c_uint32]

def rss():
    p = _PMC(); p.cb = ctypes.sizeof(p)
    ok = _psapi.GetProcessMemoryInfo(_k32.GetCurrentProcess(), ctypes.byref(p), p.cb)
    return p.WorkingSetSize / (1024 * 1024) if ok else -1.0

TARGET = 40 * 1024**3
baseline = rss()
sys.stdout.write(f"BASELINE:{baseline:.1f}\n"); sys.stdout.flush()
sys.stdout.write(f"TENTANDO:bytearray({TARGET} bytes) — aguardando resposta do OS...\n")
sys.stdout.flush()
t0 = time.perf_counter()
try:
    buf = bytearray(TARGET)
    elapsed = time.perf_counter() - t0
    peak = rss()
    del buf; gc.collect()
    sys.stdout.write(f"RESULTADO:SUCESSO_PAGING:{peak:.1f}:{elapsed:.2f}\n")
except MemoryError:
    elapsed = time.perf_counter() - t0
    sys.stdout.write(f"RESULTADO:MemoryError:{rss():.1f}:{elapsed:.3f}\n")
sys.stdout.flush()
"""

def fase1_naive_probe() -> dict:
    print()
    print("=" * 70)
    print(" FASE 1 — O PADRAO INGENUO: Carga Massiva na RAM")
    print("=" * 70)
    print(f"  Alvo     : {TARGET_BYTES // (1024**3)} GB de bytearray em uma unica alocacao")
    print(f"  Hardware : 16 GB RAM")
    print(f"  Esperado : MemoryError — OS recusa commit de 40 GB")
    print(f"  Metodo   : subprocesso isolado (timeout 30 s) para proteger sessao")
    print("-" * 70)
    sys.stdout.flush()

    t0 = time.perf_counter()
    try:
        proc = subprocess.run(
            [sys.executable, "-c", _FASE1_INNER],
            capture_output=True, text=True, timeout=30
        )
        elapsed_total = time.perf_counter() - t0
        output = proc.stdout.strip()
        for line in output.splitlines():
            print(f"  [subproc] {line}")

        # Parsear saida
        baseline_mb, resultado, peak_mb, elapsed_alloc = 0.0, "DESCONHECIDO", 0.0, 0.0
        for line in output.splitlines():
            if line.startswith("BASELINE:"):
                baseline_mb = float(line.split(":")[1])
            elif line.startswith("RESULTADO:"):
                parts = line.split(":")
                resultado     = parts[1]
                peak_mb       = float(parts[2])
                elapsed_alloc = float(parts[3])

        delta_ram = peak_mb - baseline_mb
        veredicto = ("COLAPSO CONFIRMADO — MemoryError"
                     if resultado == "MemoryError"
                     else f"ALOCOU COM PAGING em {elapsed_alloc:.1f}s (pagefile extenso)")

    except subprocess.TimeoutExpired:
        elapsed_total = time.perf_counter() - t0
        proc.kill()
        resultado     = "TIMEOUT_30S"
        baseline_mb   = 0.0
        peak_mb       = 0.0
        delta_ram     = 0.0
        elapsed_alloc = 30.0
        veredicto     = "TIMEOUT — sistema entrou em paginacao pesada antes de OOM"
        print(f"  [TIMEOUT] Subprocesso morto apos 30 s — sistema estava paginando 40 GB")

    print()
    print(f"  VEREDICTO FASE 1 : {veredicto}")
    print(f"  Baseline RAM     : {baseline_mb:.1f} MB")
    print(f"  Pico RSS         : {peak_mb:.1f} MB")
    print(f"  Delta RAM        : +{delta_ram:.1f} MB")
    print(f"  Tempo ate resp.  : {elapsed_alloc:.3f} s")
    print(f"  (tempo total c/ subproc overhead: {elapsed_total:.2f} s)")

    return {
        "fase": 1,
        "veredicto": veredicto,
        "resultado_raw": resultado,
        "baseline_rss_mb": round(baseline_mb, 1),
        "peak_rss_mb": round(peak_mb, 1),
        "delta_ram_mb": round(delta_ram, 1),
        "elapsed_alloc_s": round(elapsed_alloc, 3),
        "elapsed_total_s": round(elapsed_total, 2),
    }

# ── FASE 2: AION RISPA — stream chunk on demand ──────────────────────────────
def fase2_stream_chunk(target_bytes: int = TARGET_BYTES,
                       chunk_bytes:  int = CHUNK_BYTES) -> dict:
    target_gb  = target_bytes / (1024 ** 3)
    chunk_mb   = chunk_bytes  / (1024 ** 2)
    num_chunks = -(-target_bytes // chunk_bytes)   # divisao teto

    print()
    print("=" * 70)
    print(" FASE 2 — AION RISPA: Stream Chunk On Demand")
    print("=" * 70)
    print(f"  Alvo total   : {target_gb:.0f} GB")
    print(f"  Chunk size   : {chunk_mb:.0f} MB")
    print(f"  Num chunks   : {num_chunks}")
    print(f"  Operacao     : SHA-256 incremental por chunk")
    print(f"  Fonte dados  : stream virtual deterministico (sem arquivo em disco)")
    print(f"  Invariante   : pico de RAM < 1 GB durante todo o ciclo")
    print("-" * 70)
    sys.stdout.flush()

    gc.collect()
    baseline_rss = rss_mb()
    peak_rss     = baseline_rss
    print(f"  RAM baseline : {baseline_rss:.1f} MB")
    print()

    hasher       = hashlib.sha256()
    t0           = time.perf_counter()
    total_hashed = 0
    chunk_log    = []
    invariante_ok = True

    for i in range(num_chunks):
        remaining  = min(chunk_bytes, target_bytes - total_hashed)
        t_chunk    = time.perf_counter()

        # --- Alocar chunk virtual (sem disco) ---
        chunk = make_virtual_chunk(remaining)
        rss_apos_alloc = rss_mb()

        # --- Processar: SHA-256 incremental ---
        hasher.update(chunk)
        rss_apos_hash = rss_mb()

        # --- Liberar chunk ---
        del chunk
        gc.collect()
        rss_apos_free = rss_mb()

        # Pico deste ciclo
        pico_ciclo = max(rss_apos_alloc, rss_apos_hash)
        if pico_ciclo > peak_rss:
            peak_rss = pico_ciclo
        if peak_rss >= 1024:
            invariante_ok = False   # violou < 1 GB

        total_hashed  += remaining
        elapsed        = time.perf_counter() - t0
        chunk_elapsed_ms = (time.perf_counter() - t_chunk) * 1000
        pct            = total_hashed / target_bytes * 100
        throughput     = (total_hashed / (1024 ** 3)) / elapsed if elapsed > 0 else 0.0

        status = "OK " if pico_ciclo < 1024 else "OOM!"
        print(f"  [{status}] Chunk {i+1:3d}/{num_chunks}"
              f" | {pct:5.1f}%"
              f" | {total_hashed/(1024**3):5.2f}/{target_gb:.0f} GB"
              f" | RSS: {rss_apos_free:6.1f} MB"
              f" | Pico: {peak_rss:6.1f} MB"
              f" | {throughput:.2f} GB/s"
              f" | {elapsed:.1f}s")
        sys.stdout.flush()

        chunk_log.append({
            "chunk_num":             i + 1,
            "size_mb":               round(remaining / (1024 ** 2), 1),
            "rss_apos_alloc_mb":     round(rss_apos_alloc, 1),
            "rss_apos_hash_mb":      round(rss_apos_hash, 1),
            "rss_apos_free_mb":      round(rss_apos_free, 1),
            "pico_ciclo_mb":         round(pico_ciclo, 1),
            "chunk_elapsed_ms":      round(chunk_elapsed_ms, 1),
        })

    elapsed_total = time.perf_counter() - t0
    digest        = hasher.hexdigest()
    delta_ram     = peak_rss - baseline_rss
    throughput    = target_bytes / (1024 ** 3) / elapsed_total

    veredicto_ram = (f"APROVADO — pico {peak_rss:.1f} MB < 1024 MB (1 GB)"
                     if invariante_ok
                     else f"REPROVADO — pico {peak_rss:.1f} MB ultrapassou 1 GB")

    print()
    print(f"  VEREDICTO FASE 2   : {veredicto_ram}")
    print(f"  Total processado   : {target_bytes / (1024**3):.0f} GB")
    print(f"  Tempo total        : {elapsed_total:.2f} s")
    print(f"  Throughput medio   : {throughput:.3f} GB/s")
    print(f"  Baseline RAM       : {baseline_rss:.1f} MB")
    print(f"  Pico RAM absoluto  : {peak_rss:.1f} MB")
    print(f"  Delta RAM          : +{delta_ram:.1f} MB")
    print(f"  SHA-256 acumulado  : {digest}")

    return {
        "fase": 2,
        "target_gb": target_gb,
        "chunk_mb": chunk_mb,
        "num_chunks": num_chunks,
        "elapsed_s": round(elapsed_total, 2),
        "throughput_gbs": round(throughput, 3),
        "baseline_rss_mb": round(baseline_rss, 1),
        "peak_rss_mb": round(peak_rss, 1),
        "delta_ram_mb": round(delta_ram, 1),
        "invariante_ram_ok": invariante_ok,
        "veredicto_ram": veredicto_ram,
        "sha256_acumulado": digest,
        "chunks": chunk_log,
    }

# ── Main ─────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print()
    print("=" * 70)
    print(" [TCT/BENCHMARK_CHUNKED] TEIA-Benchmark-Chunked.py")
    print(" Prova empirica AION RISPA — naive load vs stream chunk on demand")
    print(f" Arquivo matricial virtual : {TARGET_BYTES // (1024**3)} GB")
    print(f" Chunk size                : {CHUNK_BYTES // (1024**2)} MB")
    print(f" Hardware                  : 16 GB RAM")
    print(f" Alvo invariante           : pico RAM < 1 GB na Fase 2")
    print(f" Data                      : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)

    results: dict = {
        "timestamp":       datetime.now().isoformat(),
        "hardware_ram_gb": 16,
        "target_gb":       TARGET_BYTES / (1024 ** 3),
        "chunk_mb":        CHUNK_BYTES  / (1024 ** 2),
        "python_version":  sys.version,
        "phases":          [],
    }

    r1 = fase1_naive_probe()
    results["phases"].append(r1)

    r2 = fase2_stream_chunk(TARGET_BYTES, CHUNK_BYTES)
    results["phases"].append(r2)

    # ── Veredicto Final ───────────────────────────────────────────────────────
    f1_colapsou  = r1["resultado_raw"] in ("MemoryError", "TIMEOUT_30S")
    f2_ram_ok    = r2["invariante_ram_ok"]
    f2_peak      = r2["peak_rss_mb"]
    f1_peak      = r1["peak_rss_mb"]
    delta_entre_fases = f1_peak - f2_peak  # reducao de pico RAM entre Fase1 e Fase2

    print()
    print("=" * 70)
    print(" VEREDICTO FINAL — AUDITORIA EMPIRICA AION RISPA")
    print("=" * 70)
    print(f"  Fase 1 — Naive Load (40 GB)  : {r1['veredicto']}")
    print(f"  Fase 2 — Stream Chunk (40 GB): {r2['veredicto_ram']}")
    print(f"  Delta pico RAM Fase1/Fase2   : {delta_entre_fases:+.1f} MB")
    print(f"  Throughput Fase 2            : {r2['throughput_gbs']:.3f} GB/s")
    print(f"  SHA-256 acumulado (40 GB)    : {r2['sha256_acumulado']}")
    print()

    if f1_colapsou and f2_ram_ok:
        print("  [PROVA EMPIRICA VALIDADA]")
        print(f"  O motor AION RISPA processou {int(r2['target_gb'])} GB em blocos de")
        print(f"  {int(r2['chunk_mb'])} MB, mantendo pico de RAM em {f2_peak:.1f} MB ({f2_peak/1024:.3f} GB),")
        print(f"  enquanto a abordagem ingenua colapsou ({r1['resultado_raw']}) ao")
        print(f"  tentar alocar os mesmos {int(r2['target_gb'])} GB de uma vez.")
    elif not f1_colapsou:
        print("  [AVISO] Fase 1 nao atingiu OOM — pagefile do sistema e maior que 40 GB.")
        if f2_ram_ok:
            print(f"  Fase 2 valida: {int(r2['target_gb'])} GB processados com pico de {f2_peak:.1f} MB.")
    elif not f2_ram_ok:
        print("  [FALHA] Fase 2 ultrapassou o limite de 1 GB de RAM.")

    results["veredicto_final"] = {
        "fase1_colapso":            f1_colapsou,
        "fase1_resultado_raw":      r1["resultado_raw"],
        "fase2_ram_invariante_ok":  f2_ram_ok,
        "fase2_peak_mb":            f2_peak,
        "delta_pico_fases_mb":      round(delta_entre_fases, 1),
        "throughput_gbs":           r2["throughput_gbs"],
        "sha256_40gb":              r2["sha256_acumulado"],
        "prova_validada":           f1_colapsou and f2_ram_ok,
    }

    # Salvar log
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(LOG_PATH, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    print()
    print(f"  Log JSON salvo: {LOG_PATH}")
    print("=" * 70)
    print()
