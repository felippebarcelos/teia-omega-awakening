import importlib.util
import os
import sys

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
        "functools","inspect","logging","runpy"
    ]
    conflicts = detect_shadowing(names)
    if conflicts:
        lines = [f"{n} -> {p}" for n, p in conflicts]
        msg = "Import shadowing detectado: " + "; ".join(lines)
        if raise_on_conflict:
            raise ImportError(msg + "\nRenomeie/mova esses ficheiros do projeto para evitar colisões com stdlib/pip packages.")
        else:
            print("AVISO:", msg)
    return conflicts

if __name__ == "__main__":
    cs = ensure_no_shadowing(raise_on_conflict=False)
    if cs:
        print("Conflitos detectados:", cs)
    else:
        print("Nenhum conflito detectado.")
