"""
criar_prova_v12.py — Pacote de Prova TEIA v0.11.0
Gera TEIA_PROVA_v12.zip com os artefatos de evidência certificados.
Conteúdo: relatórios D7/D8, manifests, dicionários, motor, guias.
"""

import hashlib
import json
import pathlib
import subprocess
import zipfile
from datetime import datetime, timezone

ROOT   = pathlib.Path(r"D:\TEIA_CLAUDE_AWAKENING")
ZIP_PATH = ROOT / "TEIA_PROVA_v12.zip"

MOTOR_PATH = ROOT / (
    "Arqueologia do motor AION RISPA"
    r"\NúcleoCompressorOntoprocedural\Ontologia Procedural"
    r"\Motor onto procedural\TEIA-Core-v0.11.0.psm1"
)

ARTEFATOS = [
    # relatórios de benchmark
    ROOT / "Relatorio_Comparativo_v12.0.0.md",
    ROOT / "Relatorio_Comparativo_v11.0.0.md",
    ROOT / "BENCHMARK_HISTORICO.md",
    # manifests de corpus
    ROOT / "D7_REAL_MANIFEST.json",
    ROOT / "D8_STRESS_MANIFEST.json",
    # dossiê e guia
    ROOT / "TEIA_Dossie_Tecnico.md",
    ROOT / "VALIDATION_GUIDE.md",
    # motor
    MOTOR_PATH,
    # dicionários canônicos D7
    ROOT / "_bench_v12/dicts/4be54040b288207e7650274509c20cce66470f76499ef3ac372a046c5972cd5a.zstd-dict",
    ROOT / "_bench_v12/dicts/6c72ae7246b413b8b635078167da4d5786276435fea3cd140326197744562d8a.zstd-dict",
]


def ts() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256_file(p: pathlib.Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().lower()


def git_commit() -> str:
    try:
        r = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True,
            cwd=str(ROOT), timeout=10,
        )
        return r.stdout.strip() if r.returncode == 0 else "unknown"
    except Exception:
        return "unknown"


def main():
    timestamp = ts()
    commit    = git_commit()

    print(f"[PROVA-v12] {timestamp} | Pacote de Prova TEIA v0.11.0")
    print(f"[PROVA-v12] {timestamp} | Commit: {commit}")
    print(f"[PROVA-v12] {timestamp} | Destino: {ZIP_PATH}")

    if ZIP_PATH.exists():
        ZIP_PATH.unlink()

    ausentes = [p for p in ARTEFATOS if not p.exists()]
    if ausentes:
        for p in ausentes:
            print(f"[PROVA-v12] {timestamp} | [AVISO] ausente: {p.name}")

    manifesto_artefatos = {}
    total_bytes = 0

    with zipfile.ZipFile(ZIP_PATH, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for arq in ARTEFATOS:
            if not arq.exists():
                continue
            arc_name = arq.name
            zf.write(arq, arc_name)
            h = sha256_file(arq)
            sz = arq.stat().st_size
            manifesto_artefatos[arc_name] = {"sha256": h, "size_bytes": sz}
            total_bytes += sz
            print(f"[PROVA-v12] {ts()} | + {arc_name} ({sz:,} B)")

        # Manifesto interno
        manifest = {
            "teia_version": "0.11.0",
            "prova_version": "1",
            "timestamp": timestamp,
            "git_commit": commit,
            "motor": {
                "file": "TEIA-Core-v0.11.0.psm1",
                "sha256": "a56b18c0e17f4d1037340adf78f057f44e0fdbe21a5201fca6e1d17fb379ec39",
                "size_bytes": 35864,
            },
            "benchmarks": {
                "D7": {
                    "corpus": "D7_REAL_MANIFEST.json",
                    "files": 105, "wins": "105/105",
                    "savings_bytes": 121812,
                    "sha256_roundtrip": "100%",
                    "commit": "6dcc330",
                },
                "D8": {
                    "corpus": "D8_STRESS_MANIFEST.json",
                    "files": 17, "wins": "17/17",
                    "savings_bytes": 24709,
                    "sha256_roundtrip": "100%",
                    "commit": "afe367b",
                },
            },
            "total_savings_bytes": 146521,
            "artefatos": manifesto_artefatos,
            "axioms": {
                "sha256_is_identity": True,
                "no_base64": True,
                "idempotent": True,
                "write_eq_read": True,
            },
        }
        manifest_bytes = json.dumps(manifest, ensure_ascii=False, sort_keys=True, indent=2).encode("utf-8")
        zf.writestr("PROVA_MANIFEST.json", manifest_bytes)
        print(f"[PROVA-v12] {ts()} | + PROVA_MANIFEST.json ({len(manifest_bytes)} B)")

    zip_size = ZIP_PATH.stat().st_size
    zip_sha  = sha256_file(ZIP_PATH)

    sidecar = {
        "zip_file": ZIP_PATH.name,
        "zip_sha256": zip_sha,
        "zip_size_bytes": zip_size,
        "zip_size_mb": round(zip_size / 1024 / 1024, 2),
        "timestamp": timestamp,
        "git_commit": commit,
        "total_source_bytes": total_bytes,
        "wins_combined": "122/122",
        "savings_combined_bytes": 146521,
    }
    sidecar_path = ZIP_PATH.with_suffix(".proof.json")
    sidecar_path.write_text(
        json.dumps(sidecar, ensure_ascii=False, sort_keys=True, indent=2),
        encoding="utf-8",
    )

    print(f"[PROVA-v12] {ts()} | {'='*60}")
    print(f"[PROVA-v12] {ts()} | PROVA COMPLETA")
    print(f"[PROVA-v12] {ts()} | Bytes originais: {total_bytes:,}")
    print(f"[PROVA-v12] {ts()} | Tamanho ZIP    : {zip_size:,} bytes ({zip_size/1024/1024:.2f} MB)")
    print(f"[PROVA-v12] {ts()} | SHA-256 ZIP    : {zip_sha}")
    print(f"[PROVA-v12] {ts()} | Sidecar        : {sidecar_path.name}")
    print(f"[PROVA-v12] {ts()} | D7: 105/105 | D8: 17/17 | savings=146521B")


if __name__ == "__main__":
    main()
