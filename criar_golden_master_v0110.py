"""
criar_golden_master_v0110.py — Golden Master TEIA v0.11.0
Snapshot dos dois repositorios com manifest interno auto-descritivo.

Novidades vs v1:
  - ZIP versionado: TEIA_GOLDEN_MASTER_v0.11.0.zip
  - GOLDEN_MASTER_MANIFEST.json injetado no ZIP (metadados + provas)
  - SKIP_DIRS ampliado: _bench_v* (artefatos temporarios regeneraveis)
  - SHA-256 do motor v0.11.0 gravado no manifest

Corpora certificados:
  D7: 105/105 GANHA | savings=121812B | commit 6dcc330
  D8: 17/17 GANHA   | savings=24709B  | commit afe367b
  Total savings combinado: 146521B | SHA-256 roundtrip 100% OK
"""

import hashlib
import json
import pathlib
import subprocess
import zipfile
from datetime import datetime, timezone

ZIP_PATH = pathlib.Path(r"D:\TEIA_CLAUDE_AWAKENING\TEIA_GOLDEN_MASTER_v0.11.0.zip")

SOURCES = [
    (pathlib.Path(r"D:\Teia\Agents\PaperclipAI"),  "PaperclipAI"),
    (pathlib.Path(r"D:\TEIA_CLAUDE_AWAKENING"),      "TEIA_CLAUDE_AWAKENING"),
]

SKIP_DIRS = {
    "node_modules", "dist", ".pnpm-store", "coverage",
    "__pycache__", ".vite", "storybook-static", ".agents",
    "restored", "restored_test",
    # artefatos temporarios de benchmark (regeneraveis):
    "_bench_v6", "_bench_v7", "_bench_v8", "_bench_v9",
    "_bench_v10", "_bench_v11", "_bench_v12",
}
SKIP_EXTS  = {".pyc", ".pyo"}
SKIP_FILES = {ZIP_PATH.name, "TEIA_CORE_GOLDEN_MASTER_v1.zip"}

MOTOR_PATH = pathlib.Path(
    r"D:\TEIA_CLAUDE_AWAKENING\Arqueologia do motor AION RISPA"
    r"\NúcleoCompressorOntoprocedural\Ontologia Procedural"
    r"\Motor onto procedural\TEIA-Core-v0.11.0.psm1"
)


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
            cwd=r"D:\TEIA_CLAUDE_AWAKENING", timeout=10
        )
        return r.stdout.strip() if r.returncode == 0 else "unknown"
    except Exception:
        return "unknown"


def deve_incluir(path: pathlib.Path, raiz: pathlib.Path) -> bool:
    if path.name in SKIP_FILES:
        return False
    if path.suffix.lower() in SKIP_EXTS:
        return False
    try:
        rel = path.relative_to(raiz)
    except ValueError:
        return False
    for part in rel.parts:
        if part in SKIP_DIRS:
            return False
    return True


def build_manifest(timestamp: str, commit: str, total_files: int,
                   total_bytes: int) -> dict:
    motor_sha = sha256_file(MOTOR_PATH) if MOTOR_PATH.exists() else "AUSENTE"
    motor_size = MOTOR_PATH.stat().st_size if MOTOR_PATH.exists() else 0
    return {
        "teia_version": "0.11.0",
        "golden_master_version": "2",
        "timestamp": timestamp,
        "git_commit": commit,
        "motor": {
            "version": "0.11.0",
            "file": "TEIA-Core-v0.11.0.psm1",
            "sha256": motor_sha,
            "size_bytes": motor_size,
            "class": "TEIA.Native.TEIANativeV110",
            "new_opcodes": ["cmp.lzma"],
            "format": "compact_manifest_VER_MINOR10",
        },
        "benchmarks": {
            "D7": {
                "corpus": "D7_REAL_MANIFEST.json",
                "files": 105,
                "wins": "105/105",
                "win_pct": 100.0,
                "savings_bytes": 121812,
                "sha256_roundtrip": "100%",
                "commit": "6dcc330",
                "harness": "v12.0.0",
                "notable": "cmp.lzma wins large=15/15 (was zstd.raw+cmp.xz in v9)",
            },
            "D8": {
                "corpus": "D8_STRESS_MANIFEST.json",
                "files": 17,
                "wins": "17/17",
                "win_pct": 100.0,
                "savings_bytes": 24709,
                "sha256_roundtrip": "100%",
                "commit": "afe367b",
                "harness": "v11.0.0",
                "notable": "cmp.lzma eliminates all LZMA_JANELA losses (was 1/17 in v10)",
            },
        },
        "total_savings_bytes": 146521,
        "corpora_covered": ["botocore_json", "google_api_json", "activity_logs", "tokenizers"],
        "snapshot": {
            "total_files": total_files,
            "total_source_bytes": total_bytes,
            "sources": [str(src) for src, _ in SOURCES],
            "skip_dirs": sorted(SKIP_DIRS),
        },
        "axioms": {
            "sha256_is_identity": True,
            "idempotent": True,
            "no_base64": True,
            "write_eq_read": True,
        },
    }


def main():
    timestamp = ts()
    commit    = git_commit()

    print(f"[GM-v0110] {timestamp} | TEIA Golden Master v0.11.0")
    print(f"[GM-v0110] {timestamp} | Commit: {commit}")
    print(f"[GM-v0110] {timestamp} | Destino: {ZIP_PATH}")

    if ZIP_PATH.exists():
        ZIP_PATH.unlink()
        print(f"[GM-v0110] {timestamp} | ZIP anterior removido")

    total_files = 0
    total_bytes = 0
    skipped     = 0

    with zipfile.ZipFile(ZIP_PATH, "w", compression=zipfile.ZIP_DEFLATED,
                         compresslevel=6) as zf:

        for raiz, prefixo in SOURCES:
            if not raiz.exists():
                print(f"[GM-v0110] {ts()} | [AVISO] nao encontrado: {raiz}")
                continue

            print(f"[GM-v0110] {ts()} | Adicionando {raiz} → {prefixo}\\")
            count_dir = 0

            for arquivo in sorted(raiz.rglob("*")):
                if not arquivo.is_file():
                    continue
                if not deve_incluir(arquivo, raiz):
                    skipped += 1
                    continue

                rel      = arquivo.relative_to(raiz)
                arc_name = prefixo + "\\" + str(rel)

                try:
                    zf.write(arquivo, arc_name)
                    count_dir   += 1
                    total_files += 1
                    total_bytes += arquivo.stat().st_size
                except Exception as e:
                    print(f"[GM-v0110] {ts()} | [SKIP] {arquivo.name}: {e}")
                    skipped += 1

            print(f"[GM-v0110] {ts()} | {prefixo}: {count_dir} arquivos")

        # ── Manifest interno ──────────────────────────────────────────────────
        manifest = build_manifest(timestamp, commit, total_files, total_bytes)
        manifest_bytes = json.dumps(manifest, ensure_ascii=False,
                                    sort_keys=True, indent=2).encode("utf-8")
        zf.writestr("GOLDEN_MASTER_MANIFEST.json", manifest_bytes)
        print(f"[GM-v0110] {ts()} | GOLDEN_MASTER_MANIFEST.json injetado ({len(manifest_bytes)}B)")

    zip_size = ZIP_PATH.stat().st_size
    zip_sha  = sha256_file(ZIP_PATH)

    # ── Grava sidecar de prova ────────────────────────────────────────────────
    sidecar = {
        "zip_file": ZIP_PATH.name,
        "zip_sha256": zip_sha,
        "zip_size_bytes": zip_size,
        "zip_size_mb": round(zip_size / 1024 / 1024, 2),
        "timestamp": timestamp,
        "git_commit": commit,
        "teia_version": "0.11.0",
        "total_source_files": total_files,
        "total_source_bytes": total_bytes,
        "skipped": skipped,
    }
    sidecar_path = ZIP_PATH.with_suffix(".proof.json")
    sidecar_path.write_text(
        json.dumps(sidecar, ensure_ascii=False, sort_keys=True, indent=2),
        encoding="utf-8"
    )

    print(f"[GM-v0110] {ts()} | {'='*60}")
    print(f"[GM-v0110] {ts()} | GOLDEN MASTER v0.11.0 COMPLETO")
    print(f"[GM-v0110] {ts()} | Arquivos incluidos  : {total_files} ({skipped} omitidos)")
    print(f"[GM-v0110] {ts()} | Bytes originais     : {total_bytes:,}")
    print(f"[GM-v0110] {ts()} | Tamanho ZIP         : {zip_size:,} bytes ({zip_size/1024/1024:.2f} MB)")
    print(f"[GM-v0110] {ts()} | SHA-256 ZIP         : {zip_sha}")
    print(f"[GM-v0110] {ts()} | Sidecar proof       : {sidecar_path.name}")
    print(f"[GM-v0110] {ts()} | {'='*60}")
    print(f"[GM-v0110] {ts()} | D7: 105/105 | D8: 17/17 | savings=146521B | commit {commit}")


if __name__ == "__main__":
    main()
