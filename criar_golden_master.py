"""
criar_golden_master.py — Recria TEIA_CORE_GOLDEN_MASTER_v1.zip com ambos os repositórios.
Exclui: node_modules, dist/, .pnpm-store/, coverage/, __pycache__, *.pyc, o próprio ZIP.
"""

import hashlib
import pathlib
import zipfile
from datetime import datetime, timezone

ZIP_PATH   = pathlib.Path(r"D:\TEIA_CLAUDE_AWAKENING\TEIA_CORE_GOLDEN_MASTER_v1.zip")
SOURCES    = [
    (pathlib.Path(r"D:\Teia\Agents\PaperclipAI"),   "PaperclipAI"),
    (pathlib.Path(r"D:\TEIA_CLAUDE_AWAKENING"),       "TEIA_CLAUDE_AWAKENING"),
]

SKIP_DIRS = {
    "node_modules", "dist", ".pnpm-store", "coverage",
    "__pycache__", ".vite", "storybook-static", ".agents",
    "restored", "restored_test",   # evitar restaurações de seeds
}
SKIP_EXTS = {".pyc", ".pyo"}
SKIP_FILES = {ZIP_PATH.name}     # não incluir o próprio ZIP


def ts():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def deve_incluir(path: pathlib.Path, raiz: pathlib.Path) -> bool:
    if path.name in SKIP_FILES:
        return False
    if path.suffix.lower() in SKIP_EXTS:
        return False
    # Verificar se algum componente do path relativo é um dir proibido
    try:
        rel = path.relative_to(raiz)
    except ValueError:
        return False
    for part in rel.parts:
        if part in SKIP_DIRS:
            return False
    return True


def sha256_file(p: pathlib.Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def main():
    print(f"[Delta] {ts()} | Iniciando criação de TEIA_CORE_GOLDEN_MASTER_v1.zip")
    print(f"[Delta] {ts()} | Destino: {ZIP_PATH}")

    if ZIP_PATH.exists():
        ZIP_PATH.unlink()
        print(f"[Delta] {ts()} | ZIP anterior removido")

    total_arquivos = 0
    total_bytes    = 0

    with zipfile.ZipFile(ZIP_PATH, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for raiz, prefixo in SOURCES:
            if not raiz.exists():
                print(f"[Delta] {ts()} | [AVISO] Diretório não encontrado: {raiz}")
                continue

            print(f"[Delta] {ts()} | Adicionando: {raiz}  →  {prefixo}\\")
            count_dir = 0

            for arquivo in sorted(raiz.rglob("*")):
                if not arquivo.is_file():
                    continue
                if not deve_incluir(arquivo, raiz):
                    continue

                rel = arquivo.relative_to(raiz)
                arc_name = prefixo + "\\" + str(rel)

                try:
                    zf.write(arquivo, arc_name)
                    count_dir    += 1
                    total_arquivos += 1
                    total_bytes  += arquivo.stat().st_size
                except Exception as e:
                    print(f"[Delta] {ts()} | [SKIP] {arquivo.name}: {e}")

            print(f"[Delta] {ts()} | {prefixo}: {count_dir} arquivos adicionados")

    tamanho_zip = ZIP_PATH.stat().st_size
    hash_zip    = sha256_file(ZIP_PATH)

    print(f"[Delta] {ts()} | ={'='*60}")
    print(f"[Delta] {ts()} | GOLDEN MASTER COMPLETO")
    print(f"[Delta] {ts()} | Total de arquivos : {total_arquivos}")
    print(f"[Delta] {ts()} | Bytes originais   : {total_bytes:,}")
    print(f"[Delta] {ts()} | Tamanho ZIP       : {tamanho_zip:,} bytes ({tamanho_zip/1024/1024:.2f} MB)")
    print(f"[Delta] {ts()} | SHA-256 ZIP       : {hash_zip}")
    print(f"[Delta] {ts()} | ={'='*60}")


if __name__ == "__main__":
    main()
