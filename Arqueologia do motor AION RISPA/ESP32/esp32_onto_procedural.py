# esp32_onto_procedural.py
# Núcleo MicroPython determinístico para execução "ontoProcedural" em ESP32.
# Compatível com ESP32/ESP32-S2/ESP32-S3 e MicroPython recente.
# Este módulo implementa: manifesto JSON, agenda por prioridade, registro de ações,
# hashing SHA256, log de eventos e protocolo de linha JSON (JLines) via UART/STDIO.

import sys
import ujson as json
import machine
import time
import ubinascii
import uhashlib
import os

VERSION = "0.2.0"

# ---------- Utilidades determinísticas ----------

def sha256_bytes(data: bytes) -> str:
    h = uhashlib.sha256()
    h.update(data)
    return ubinascii.hexlify(h.digest()).decode()

def sha256_file(path: str) -> str:
    h = uhashlib.sha256()
    with open(path, "rb") as f:
        while True:
            b = f.read(4096)
            if not b:
                break
            h.update(b)
    return ubinascii.hexlify(h.digest()).decode()

def jprint(obj):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()

def now_ms():
    return time.ticks_ms()

# ---------- Log local ----------

LOG_PATH = "/log_onto.txt"

def logln(msg: str):
    ts = now_ms()
    line = "[%d] %s\n" % (ts, msg)
    try:
        with open(LOG_PATH, "a") as f:
            f.write(line)
    except Exception as e:
        # Se falhar log em arquivo, ainda emitimos por STDOUT
        jprint({"kind": "warn", "msg": "log_write_failed", "err": str(e)})

# ---------- Registro de Ações ----------

class ActionRegistry:
    def __init__(self):
        self._actions = {}

    def register(self, name, fn):
        self._actions[name] = fn

    def run(self, name, ctx):
        if name not in self._actions:
            raise ValueError("action_not_found: %s" % name)
        return self._actions[name](ctx)

REG = ActionRegistry()

# ---------- Ações básicas ----------

def act_sleep_ms(ctx):
    dur = int(ctx.get("ms", 0))
    time.sleep_ms(dur)
    return {"slept_ms": dur}

def act_gpio_write(ctx):
    pin = int(ctx["pin"])
    val = 1 if int(ctx.get("value", 1)) else 0
    p = machine.Pin(pin, machine.Pin.OUT)
    p.value(val)
    return {"pin": pin, "value": val}

def act_gpio_pulse(ctx):
    pin = int(ctx["pin"])
    high_ms = int(ctx.get("high_ms", 10))
    low_ms = int(ctx.get("low_ms", 10))
    reps = int(ctx.get("reps", 1))
    p = machine.Pin(pin, machine.Pin.OUT)
    for _ in range(reps):
        p.on(); time.sleep_ms(high_ms)
        p.off(); time.sleep_ms(low_ms)
    return {"pin": pin, "reps": reps, "high_ms": high_ms, "low_ms": low_ms}

def act_file_read(ctx):
    path = ctx["path"]
    with open(path, "rb") as f:
        b = f.read()
    return {"path": path, "size": len(b), "sha256": sha256_bytes(b)}

def act_file_write(ctx):
    path = ctx["path"]
    data_b64 = ctx.get("data_b64")
    data_hex = ctx.get("data_hex")
    raw = None
    if data_b64 is not None:
        raw = ubinascii.a2b_base64(data_b64)
    elif data_hex is not None:
        raw = ubinascii.unhexlify(data_hex)
    else:
        raise ValueError("missing data_b64 or data_hex")
    with open(path, "wb") as f:
        f.write(raw)
    return {"path": path, "size": len(raw), "sha256": sha256_bytes(raw)}

def act_file_hash(ctx):
    path = ctx["path"]
    return {"path": path, "sha256": sha256_file(path)}

def act_echo(ctx):
    return {"echo": ctx}

def act_listdir(ctx):
    path = ctx.get("path", "/")
    try:
        items = os.ilistdir(path)
        files = []
        for it in items:
            name = it[0]
            files.append(name)
        return {"path": path, "items": files}
    except Exception as e:
        return {"path": path, "err": str(e)}

REG.register("sleep_ms", act_sleep_ms)
REG.register("gpio_write", act_gpio_write)
REG.register("gpio_pulse", act_gpio_pulse)
REG.register("file_read", act_file_read)
REG.register("file_write", act_file_write)
REG.register("file_hash", act_file_hash)
REG.register("echo", act_echo)
REG.register("listdir", act_listdir)

# ---------- Executor OntoProcedural ----------

def execute_manifest(mani: dict) -> dict:
    tasks = mani.get("tasks", [])
    # Ordena por prioridade ascendente; tie-break: id lexicográfico
    tasks_sorted = sorted(tasks, key=lambda t: (int(t.get("priority", 1000)), str(t.get("id", ""))))
    results = []
    start_ms = now_ms()
    for t in tasks_sorted:
        tid = t.get("id", "unnamed")
        act = t.get("action")
        ctx = t.get("ctx", {})
        try:
            out = REG.run(act, ctx)
            res = {"id": tid, "action": act, "ok": True, "out": out}
            results.append(res)
            logln("OK %s %s" % (tid, act))
            jprint({"kind": "task_ok", "id": tid, "action": act, "out": out})
        except Exception as e:
            err = {"id": tid, "action": act, "ok": False, "err": str(e)}
            results.append(err)
            logln("ERR %s %s %s" % (tid, act, str(e)))
            jprint({"kind": "task_err", "id": tid, "action": act, "err": str(e)})
            if mani.get("fail_fast", True):
                break
    total_ms = time.ticks_diff(now_ms(), start_ms)
    return {"count": len(results), "elapsed_ms": total_ms, "results": results}

def main():
    # Modo 1: se houver argumento arquivo JSON -> executa
    # Modo 2: stdin com linhas JSON; cada linha é um objeto {"manifest": {...}}
    argv = sys.argv
    jprint({"kind": "hello", "version": VERSION})
    if len(argv) >= 2:
        path = argv[1]
        with open(path, "rb") as f:
            mani = json.loads(f.read())
        res = execute_manifest(mani)
        jprint({"kind": "summary", "res": res})
        return
    # Loop interativo (JSON lines)
    while True:
        line = sys.stdin.readline()
        if not line:
            time.sleep_ms(10)
            continue
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
            if "manifest" in obj:
                res = execute_manifest(obj["manifest"])
                jprint({"kind": "summary", "res": res})
            elif "ping" in obj:
                jprint({"kind": "pong", "ts": now_ms()})
            else:
                jprint({"kind": "error", "msg": "unknown_command"})
        except Exception as e:
            jprint({"kind": "error", "msg": "bad_json", "err": str(e)})

if __name__ == "__main__":
    main()
