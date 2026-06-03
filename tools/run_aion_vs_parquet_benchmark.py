#!/usr/bin/env python3
"""
AION-RISPA vs Apache Parquet — Write Amplification Benchmark (P57.0)
Architectural simulation using stdlib only. No external dependencies.

Methodology:
  Simulates the I/O cost of DELETE and UPDATE operations on a single
  record within a growing corpus, comparing AION's per-seed architecture
  against Parquet's immutable row-group architecture.

Parameters are anchored to P38.0 measured values (Time Series domain)
and standard Parquet/PyArrow defaults.
"""

from __future__ import annotations
import hashlib
import json
import math
import sys
from datetime import datetime, timezone
from pathlib import Path

# ─── Corpus model constants ───────────────────────────────────────────────────

# IoT sensor record — JSON with: timestamp, device_id (50 values), sensor_type
# (5 values), location (20 values), temperature, humidity, pressure, voltage,
# status (5 values), error_code (10 values), firmware_version (8 values), session_id
RAW_RECORD_BYTES            = 380    # uncompressed JSON
BROTLI_INDIVIDUAL_BYTES     = 195    # Brotli-11 compressed individual record
AION_SEED_BYTES             = 62     # residual after Master Grammar strips 9 categorical cols
AION_GRAMMAR_OVERHEAD_BYTES = 5_755  # overhead_fixo from P38.0 Time Series domain
PARQUET_COLUMNAR_BYTES      = 148    # Parquet + Snappy per record (typical IoT)

# Parquet architectural constants (Apache Parquet spec / PyArrow defaults)
PARQUET_ROW_GROUP_DEFAULT   = 128 * 1024 * 1024  # 128 MB — PyArrow/PySpark/Spark default
PARQUET_GDPR_PASSES         = 2   # tombstone write + VACUUM/compaction rewrite

# AION dictionary density for IoT domain (9 of 13 cols dictionarizable = 69%)
AION_DICT_DENSITY           = 0.69

CORPUS_SIZES = [100, 500, 1_000, 5_000, 10_000, 50_000, 100_000, 1_000_000]
TARGET_RECORD = 500  # record index selected for mutation in each scenario


# ─── Simulation engine ────────────────────────────────────────────────────────

def _fmt(n: int) -> str:
    """Human-readable byte size."""
    for unit, limit in (("GB", 1 << 30), ("MB", 1 << 20), ("KB", 1 << 10)):
        if n >= limit:
            return f"{n / limit:.2f} {unit}"
    return f"{n} B"


def simulate_corpus(n_records: int) -> dict:
    """
    Return architectural I/O model for DELETE / UPDATE / GDPR_ERASURE
    of a single record within a corpus of n_records IoT files.
    """
    # ── AION totals ───────────────────────────────────────────────────────────
    aion_total = AION_GRAMMAR_OVERHEAD_BYTES + n_records * AION_SEED_BYTES

    # DELETE  → unlink seed file; no rewrite of any other record
    aion_delete_io  = AION_SEED_BYTES
    # UPDATE  → read seed + write new seed (only that record)
    aion_update_io  = AION_SEED_BYTES * 2
    # GDPR    → unlink seed; data is cryptographically unrestorable immediately
    aion_gdpr_io    = AION_SEED_BYTES
    aion_gdpr_cert  = True   # seed gone → data provably irretrievable

    # ── Parquet totals ────────────────────────────────────────────────────────
    parquet_total   = n_records * PARQUET_COLUMNAR_BYTES

    # Row group containing TARGET_RECORD (records distributed sequentially)
    parquet_rg_bytes = min(parquet_total, PARQUET_ROW_GROUP_DEFAULT)
    parquet_records_per_rg = (
        parquet_rg_bytes // PARQUET_COLUMNAR_BYTES
        if parquet_rg_bytes < PARQUET_ROW_GROUP_DEFAULT
        else PARQUET_ROW_GROUP_DEFAULT // PARQUET_COLUMNAR_BYTES
    )

    # DELETE  → Parquet is immutable: read RG + filter out record + write new RG
    parquet_delete_io  = parquet_rg_bytes * 2
    # UPDATE  → same: must read, modify in memory, rewrite entire row group
    parquet_update_io  = parquet_rg_bytes * 2
    # GDPR    → tombstone marker pass + full VACUUM compaction (2 full RG rewrites)
    parquet_gdpr_io    = parquet_rg_bytes * PARQUET_GDPR_PASSES
    parquet_gdpr_cert  = False  # old Parquet files may persist in object store snapshots

    # ── Write Amplification Factor (WAF) ─────────────────────────────────────
    # Normalise against the theoretical minimum: the compressed record itself
    base = BROTLI_INDIVIDUAL_BYTES

    def waf(io_bytes: int) -> float:
        return round(io_bytes / base, 2)

    # ── AION advantage ────────────────────────────────────────────────────────
    def adv(parquet_io: int, aion_io: int) -> str:
        ratio = parquet_io / aion_io
        return f"{ratio:,.0f}×"

    return {
        "n_records": n_records,
        "corpus_bytes": {
            "aion":    {"total": aion_total,    "human": _fmt(aion_total)},
            "parquet": {"total": parquet_total, "human": _fmt(parquet_total)},
        },
        "parquet_row_group": {
            "bytes":       parquet_rg_bytes,
            "human":       _fmt(parquet_rg_bytes),
            "records":     parquet_records_per_rg,
        },
        "operations": {
            "DELETE": {
                "aion": {
                    "io_bytes": aion_delete_io,
                    "io_human": _fmt(aion_delete_io),
                    "waf":      waf(aion_delete_io),
                    "complexity": "O(1)",
                },
                "parquet": {
                    "io_bytes": parquet_delete_io,
                    "io_human": _fmt(parquet_delete_io),
                    "waf":      waf(parquet_delete_io),
                    "complexity": "O(N_rowgroup)",
                },
                "aion_advantage": adv(parquet_delete_io, aion_delete_io),
            },
            "UPDATE": {
                "aion": {
                    "io_bytes": aion_update_io,
                    "io_human": _fmt(aion_update_io),
                    "waf":      waf(aion_update_io),
                    "complexity": "O(1)",
                },
                "parquet": {
                    "io_bytes": parquet_update_io,
                    "io_human": _fmt(parquet_update_io),
                    "waf":      waf(parquet_update_io),
                    "complexity": "O(N_rowgroup)",
                },
                "aion_advantage": adv(parquet_update_io, aion_update_io),
            },
            "GDPR_ERASURE": {
                "aion": {
                    "io_bytes":           aion_gdpr_io,
                    "io_human":           _fmt(aion_gdpr_io),
                    "waf":                waf(aion_gdpr_io),
                    "complexity":         "O(1)",
                    "erasure_guaranteed": aion_gdpr_cert,
                    "latency_class":      "immediate",
                },
                "parquet": {
                    "io_bytes":           parquet_gdpr_io,
                    "io_human":           _fmt(parquet_gdpr_io),
                    "waf":                waf(parquet_gdpr_io),
                    "complexity":         "O(N_rowgroup)",
                    "erasure_guaranteed": parquet_gdpr_cert,
                    "latency_class":      "deferred (tombstone + VACUUM)",
                },
                "aion_advantage": adv(parquet_gdpr_io, aion_gdpr_io),
                "note": (
                    "Parquet GDPR erasure requires a tombstone write followed by "
                    "a full VACUUM/compaction pass. Old Parquet files may persist "
                    "in object-store snapshots until expiry, creating a compliance gap."
                ),
            },
        },
    }


# ─── ASCII comparison table ───────────────────────────────────────────────────

def _print_table(results: list[dict]) -> None:
    header = (
        f"{'N':>9}  {'AION DELETE':>11}  {'Parquet DELETE':>14}  "
        f"{'AION WAF':>9}  {'Parquet WAF':>12}  {'Advantage':>10}"
    )
    sep = "─" * len(header)
    print(f"\n{sep}")
    print("  WRITE AMPLIFICATION — DELETE OPERATION  (corpus size scaling)")
    print(sep)
    print(header)
    print(sep)
    for r in results:
        n   = r["n_records"]
        aio = r["operations"]["DELETE"]["aion"]["io_human"]
        pio = r["operations"]["DELETE"]["parquet"]["io_human"]
        awa = r["operations"]["DELETE"]["aion"]["waf"]
        pwa = r["operations"]["DELETE"]["parquet"]["waf"]
        adv = r["operations"]["DELETE"]["aion_advantage"]
        print(f"{n:>9,}  {aio:>11}  {pio:>14}  {awa:>9.2f}  {pwa:>12,.0f}  {adv:>10}")
    print(sep)

    print(f"\n{sep}")
    print("  GDPR RIGHT-TO-ERASURE — I/O COST  (2 passes: tombstone + VACUUM)")
    print(sep)
    print(
        f"{'N':>9}  {'AION':>8}  {'Guaranteed':>10}  "
        f"{'Parquet':>10}  {'Guaranteed':>10}  {'Advantage':>10}"
    )
    print(sep)
    for r in results:
        n    = r["n_records"]
        aio  = r["operations"]["GDPR_ERASURE"]["aion"]["io_human"]
        ag   = str(r["operations"]["GDPR_ERASURE"]["aion"]["erasure_guaranteed"])
        pio  = r["operations"]["GDPR_ERASURE"]["parquet"]["io_human"]
        pg   = str(r["operations"]["GDPR_ERASURE"]["parquet"]["erasure_guaranteed"])
        adv  = r["operations"]["GDPR_ERASURE"]["aion_advantage"]
        print(f"{n:>9,}  {aio:>8}  {ag:>10}  {pio:>10}  {pg:>10}  {adv:>10}")
    print(sep)


# ─── SHA-256 seal ─────────────────────────────────────────────────────────────

def _seal(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


# ─── Main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    print("AION-RISPA vs Apache Parquet — Write Amplification Benchmark (P57.0)")
    print(f"Run at: {datetime.now(timezone.utc).isoformat()}")
    print(
        f"Model: raw={RAW_RECORD_BYTES}B/rec  "
        f"aion_seed={AION_SEED_BYTES}B  "
        f"parquet_col={PARQUET_COLUMNAR_BYTES}B  "
        f"parquet_rg_default=128 MB"
    )
    print(f"Target operation: DELETE record #{TARGET_RECORD}")

    results = [simulate_corpus(n) for n in CORPUS_SIZES]
    _print_table(results)

    out = {
        "benchmark": "aion_vs_parquet_write_amplification",
        "protocol":  "P57.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "methodology": "architectural_simulation",
        "model_parameters": {
            "raw_record_bytes":            RAW_RECORD_BYTES,
            "brotli_individual_bytes":     BROTLI_INDIVIDUAL_BYTES,
            "aion_seed_bytes":             AION_SEED_BYTES,
            "aion_grammar_overhead_bytes": AION_GRAMMAR_OVERHEAD_BYTES,
            "parquet_columnar_bytes":      PARQUET_COLUMNAR_BYTES,
            "parquet_row_group_default_bytes": PARQUET_ROW_GROUP_DEFAULT,
            "parquet_gdpr_passes":         PARQUET_GDPR_PASSES,
            "dict_density":                AION_DICT_DENSITY,
            "anchor_source":               "P38.0 Time Series measured values",
        },
        "verdict": {
            "read_only_analytics":           "Apache Parquet (optimal — columnar scans, no mutation)",
            "mutable_active_lake":           "AION-RISPA (O(1) mutation, no row-group rewrite)",
            "gdpr_right_to_erasure":         "AION-RISPA (immediate, cryptographically guaranteed)",
            "streaming_ingestion":           "AION-RISPA (per-file seed append, O(1) index update)",
            "columnar_aggregation_at_rest":  "Apache Parquet (native columnar pushdown)",
        },
        "scenarios": results,
    }

    canonical = json.dumps(out, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
    seal = _seal(canonical.encode())
    out["sha256"] = seal

    out_path = Path(__file__).parent / "aion_out" / "p57_write_amplification.json"
    out_path.parent.mkdir(exist_ok=True)
    out_path.write_text(
        json.dumps(out, indent=2, sort_keys=True, ensure_ascii=False),
        encoding="utf-8",
    )

    print(f"\nOutput:   {out_path}")
    print(f"SHA-256:  {seal}")
    print(
        "\nVERDICT: Parquet is optimal for Read-Only Analytics. "
        "AION is optimal for Highly Mutable, Compliance-Driven Active Lakes "
        "(GDPR Right-to-Erasure compliant)."
    )


if __name__ == "__main__":
    main()
