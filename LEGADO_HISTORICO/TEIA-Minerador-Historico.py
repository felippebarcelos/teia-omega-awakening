"""
TEIA-Minerador-Historico.py
Orquestrador de mineracao do historico ChatGPT com Honestidade Entropica.
Extrai o dito (intencao explicita) e o nao dito (padrao cognitivo latente)
de cada conversa, usando o teia-supra-sensei como Auditor Logico.

Invariante: "Delta" por extenso — nenhum simbolo matematico grego em triangulo.
"""

import argparse
import json
import re
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime
from pathlib import Path

# ── Caminhos canonicos ─────────────────────────────────────────────────────────
DIR_CHATS            = Path('D:/ChatGPT_2438')
DIR_SEEDS            = Path('D:/TEIA_SEEDS')
ARQUIVO_ESTADO       = DIR_SEEDS / 'mineracao_estado.json'
ARQUIVO_RESULTADO    = DIR_SEEDS / 'Conhecimento_Supra_Sensei.jsonl'

# ── Ollama ─────────────────────────────────────────────────────────────────────
OLLAMA_URL  = 'http://localhost:11434/api/generate'
MODELO      = 'teia-supra-sensei'

# ── Limites de destilacao (Honestidade Entropica) ─────────────────────────────
MAX_CHARS_USUARIO    = 800    # chars por mensagem do usuario (Felippe)
MAX_CHARS_ASSISTENTE = 400    # chars por mensagem do assistente (conclusao util)
MAX_CHARS_DESTILADO  = 2000   # total do extrato enviado ao modelo
NUM_PREDICT          = 256    # max tokens de resposta (controla tempo de inferencia)

# ── Prompt de mineracao (verbatim conforme especificacao) ─────────────────────
PROMPT_MINERACAO = (
    "Atue como o Supra-Sensei da TEIA. Analise este extrato do meu historico. "
    "Extraia em formato de topicos curtos: "
    "1. A intencao explicita (o dito). "
    "2. O padrao cognitivo latente e conexoes com a arquitetura TEIA (o nao dito). "
    "3. Conhecimento catalisavel aplicavel hoje. "
    "Seja extremamente denso e direto, sem preambulos."
)

# ── Limpeza de texto (descarta metadados, links, base64) ──────────────────────
_RE_URL        = re.compile(r'https?://\S+')
_RE_BLOCO_CODE = re.compile(r'```[\s\S]*?```')
_RE_INLINE_CODE= re.compile(r'`[^`\n]{1,200}`')
_RE_BASE64     = re.compile(r'[A-Za-z0-9+/=]{200,}')
_RE_WHITESPACE = re.compile(r'\n{3,}')

def limpar_texto(texto: str) -> str:
    texto = _RE_URL.sub('[URL]', texto)
    texto = _RE_BLOCO_CODE.sub('[CODIGO]', texto)
    texto = _RE_INLINE_CODE.sub('[inline]', texto)
    texto = _RE_BASE64.sub('[BASE64]', texto)
    texto = _RE_WHITESPACE.sub('\n\n', texto)
    return texto.strip()

# ── Extracao de mensagens do formato ChatGPT export ───────────────────────────
def extrair_mensagens(chat_json: dict) -> list:
    """Retorna lista de {'role': str, 'texto': str, 'create_time': float}."""
    nos = []
    for _key, node in chat_json.get('mapping', {}).items():
        msg = node.get('message')
        if not msg:
            continue
        role = msg.get('author', {}).get('role', '')
        if role not in ('user', 'assistant'):
            continue
        parts = msg.get('content', {}).get('parts', [])
        texto = ' '.join(str(p) for p in parts if isinstance(p, str)).strip()
        if len(texto) < 10:
            continue
        create_time = float(msg.get('create_time') or 0)
        nos.append({'role': role, 'texto': texto, 'create_time': create_time})

    nos.sort(key=lambda x: x['create_time'])
    return nos

# ── Destilacao com Honestidade Entropica ──────────────────────────────────────
def destilar_chat(mensagens: list, max_total: int) -> str:
    """
    Reduz o ruido da conversa ao seu nucleo semantico.
    Retorna o extrato destilado pronto para injecao no Supra-Sensei.
    """
    partes = []
    chars_usados = 0

    for m in mensagens:
        role  = m['role']
        texto = limpar_texto(m['texto'])
        if role == 'user':
            limite  = MAX_CHARS_USUARIO
            prefixo = '[Felippe]'
        else:
            limite  = MAX_CHARS_ASSISTENTE
            prefixo = '[Resp]'

        trecho = texto[:limite]
        if len(texto) > limite:
            trecho += '...'

        linha = f"{prefixo}: {trecho}"
        if chars_usados + len(linha) + 1 > max_total:
            break

        partes.append(linha)
        chars_usados += len(linha) + 1

    return '\n'.join(partes)

# ── Chamada ao Ollama (sem stream, timeout generoso) ─────────────────────────
def chamar_supra_sensei(titulo: str, destilado: str) -> dict | None:
    prompt_completo = (
        f"{PROMPT_MINERACAO}\n\n"
        f"=== EXTRATO ===\n"
        f"Titulo: {titulo}\n\n"
        f"{destilado}"
    )

    payload = json.dumps({
        'model':   MODELO,
        'prompt':  prompt_completo,
        'stream':  False,
        'think':   False,           # desabilita COT do DeepSeek-R1 — resposta direta
        'options': {
            'num_predict': NUM_PREDICT,
            'temperature': 0.1,
        },
    }, ensure_ascii=False).encode('utf-8')

    # Timeout: NUM_PREDICT / 2.5 tok/s + 180s de overhead (prefill + scheduler)
    timeout_s = int(NUM_PREDICT / 2.5) + 180

    req = urllib.request.Request(
        OLLAMA_URL,
        data=payload,
        headers={'Content-Type': 'application/json; charset=utf-8'},
        method='POST',
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout_s) as resp:
            return json.loads(resp.read().decode('utf-8'))
    except urllib.error.URLError as e:
        print(f"  [ERRO rede] {e}", flush=True)
    except Exception as e:
        print(f"  [ERRO Ollama] {type(e).__name__}: {e}", flush=True)
    return None

# ── Estado de idempotencia ─────────────────────────────────────────────────────
def carregar_estado() -> dict:
    if ARQUIVO_ESTADO.exists():
        try:
            return json.loads(ARQUIVO_ESTADO.read_text(encoding='utf-8'))
        except Exception:
            pass
    return {
        'processados':        [],
        'total_no_diretorio': 0,
        'inicio_sessao':      '',
        'ultimo_processado':  '',
        'total_tokens_gerados': 0,
        'delta_chars_eliminados': 0,
    }

def salvar_estado(estado: dict) -> None:
    DIR_SEEDS.mkdir(parents=True, exist_ok=True)
    ARQUIVO_ESTADO.write_text(
        json.dumps(estado, indent=2, ensure_ascii=False),
        encoding='utf-8',
    )

# ── Persistencia do conhecimento extraido ─────────────────────────────────────
def persistir_resultado(entrada: dict) -> None:
    DIR_SEEDS.mkdir(parents=True, exist_ok=True)
    with open(ARQUIVO_RESULTADO, 'a', encoding='utf-8') as f:
        f.write(json.dumps(entrada, ensure_ascii=False) + '\n')

# ── Loop principal ─────────────────────────────────────────────────────────────
def main() -> None:
    ap = argparse.ArgumentParser(
        description='TEIA-Minerador-Historico — Honestidade Entropica sobre o historico ChatGPT'
    )
    ap.add_argument('--limite',   type=int, default=0,     help='Limitar a N arquivos (0=todos)')
    ap.add_argument('--verbose',  action='store_true',     help='Exibir destilado completo')
    ap.add_argument('--dry-run',  action='store_true',     help='Apenas extrai, nao chama Ollama')
    args = ap.parse_args()

    DIR_SEEDS.mkdir(parents=True, exist_ok=True)

    # Inventario
    arquivos = sorted(DIR_CHATS.glob('*.json'))
    total    = len(arquivos)
    print(f"[MINERADOR] Diretorio       : {DIR_CHATS}", flush=True)
    print(f"[MINERADOR] Arquivos JSON   : {total}", flush=True)

    # Estado de idempotencia
    estado = carregar_estado()
    if not estado['inicio_sessao']:
        estado['inicio_sessao']      = datetime.now().isoformat()
        estado['total_no_diretorio'] = total
    processados_set = set(estado['processados'])

    pendentes = [f for f in arquivos if f.name not in processados_set]
    print(f"[MINERADOR] Ja processados  : {len(processados_set)}", flush=True)
    print(f"[MINERADOR] Pendentes       : {len(pendentes)}", flush=True)

    if args.limite > 0:
        pendentes = pendentes[:args.limite]
        print(f"[MINERADOR] Limite sessao   : {args.limite} arquivos", flush=True)

    print(f"[MINERADOR] Modelo          : {MODELO}", flush=True)
    print(f"[MINERADOR] Destino         : {ARQUIVO_RESULTADO}", flush=True)
    print(f"[MINERADOR] Estado          : {ARQUIVO_ESTADO}", flush=True)
    print('', flush=True)

    delta_chars_sessao   = 0
    tokens_sessao        = 0
    tempo_sessao_inicio  = time.perf_counter()

    for idx, caminho in enumerate(pendentes, 1):
        titulo = caminho.stem
        print(f"{'='*70}", flush=True)
        print(f"[{idx:04d}/{len(pendentes)}] {titulo}", flush=True)

        # Parse
        try:
            chat_json = json.loads(caminho.read_text(encoding='utf-8', errors='replace'))
        except Exception as e:
            print(f"  [ERRO parse] {e} — pulando", flush=True)
            estado['processados'].append(caminho.name)
            salvar_estado(estado)
            continue

        # Extracao
        mensagens = extrair_mensagens(chat_json)
        if not mensagens:
            print(f"  [SKIP] Sem mensagens user/assistant validas.", flush=True)
            estado['processados'].append(caminho.name)
            salvar_estado(estado)
            continue

        chars_brutos = sum(len(m['texto']) for m in mensagens)
        destilado    = destilar_chat(mensagens, MAX_CHARS_DESTILADO)
        chars_dest   = len(destilado)
        delta_reducao_chars = chars_brutos - chars_dest
        delta_chars_sessao += delta_reducao_chars

        n_user = sum(1 for m in mensagens if m['role'] == 'user')
        n_asst = sum(1 for m in mensagens if m['role'] == 'assistant')

        print(f"  Mensagens       : {len(mensagens)} ({n_user} usuario, {n_asst} assistente)", flush=True)
        print(f"  Chars brutos    : {chars_brutos}", flush=True)
        print(f"  Chars destilados: {chars_dest}  (Delta reducao: {delta_reducao_chars} chars eliminados)", flush=True)

        if args.verbose:
            print(f"  --- DESTILADO ---", flush=True)
            for linha in destilado.split('\n')[:8]:
                print(f"    {linha}", flush=True)
            if destilado.count('\n') >= 8:
                print(f"    ... (truncado)", flush=True)
            print(f"  ---", flush=True)

        if args.dry_run:
            print(f"  [DRY-RUN] Inferencia ignorada.", flush=True)
            estado['processados'].append(caminho.name)
            salvar_estado(estado)
            continue

        # Inferencia
        print(f"  Enviando ao {MODELO}...", flush=True)
        t_ini    = time.perf_counter()
        resultado = chamar_supra_sensei(titulo, destilado)
        t_fim    = time.perf_counter()
        elapsed  = t_fim - t_ini

        if resultado is None:
            print(f"  [ERRO] Inferencia falhou. Nao marcando como processado.", flush=True)
            continue

        resposta         = resultado.get('response', '').strip()
        tokens_gerados   = resultado.get('eval_count', 0)
        tokens_prompt    = resultado.get('prompt_eval_count', 0)
        throughput       = tokens_gerados / elapsed if elapsed > 0 else 0.0

        tokens_sessao += tokens_gerados
        estado['total_tokens_gerados'] = estado.get('total_tokens_gerados', 0) + tokens_gerados
        estado['delta_chars_eliminados'] = estado.get('delta_chars_eliminados', 0) + delta_reducao_chars

        print(f"  Inferencia      : {elapsed:.1f}s | prompt={tokens_prompt}tok | "
              f"gerados={tokens_gerados}tok | {throughput:.2f} tok/s", flush=True)
        print(f"  --- EXTRACAO LATENTE (dito + nao dito) ---", flush=True)
        for linha in resposta.split('\n'):
            if linha.strip():
                print(f"    {linha}", flush=True)
        print('', flush=True)

        # Persistir no JSONL
        entrada = {
            'arquivo':              caminho.name,
            'titulo':               titulo,
            'timestamp':            datetime.now().isoformat(),
            'n_mensagens':          len(mensagens),
            'chars_brutos':         chars_brutos,
            'chars_destilados':     chars_dest,
            'delta_reducao_chars':  delta_reducao_chars,
            'tokens_prompt':        tokens_prompt,
            'tokens_gerados':       tokens_gerados,
            'throughput_tps':       round(throughput, 3),
            'elapsed_s':            round(elapsed, 2),
            'resposta':             resposta,
        }
        persistir_resultado(entrada)

        # Atualizar estado (idempotencia)
        estado['processados'].append(caminho.name)
        estado['ultimo_processado'] = caminho.name
        salvar_estado(estado)

    # ── Sumario da sessao ──────────────────────────────────────────────────────
    tempo_sessao = time.perf_counter() - tempo_sessao_inicio
    print(f"{'='*70}", flush=True)
    print(f"[MINERADOR] SESSAO CONCLUIDA", flush=True)
    print(f"  Arquivos minerados (sessao) : {idx if pendentes else 0}", flush=True)
    print(f"  Total processados historico : {len(estado['processados'])} / {estado['total_no_diretorio']}", flush=True)
    print(f"  Tokens gerados (sessao)     : {tokens_sessao}", flush=True)
    print(f"  Delta chars eliminados      : {delta_chars_sessao} (Honestidade Entropica)", flush=True)
    print(f"  Tempo sessao                : {tempo_sessao:.1f}s", flush=True)
    print(f"  Resultados JSONL            : {ARQUIVO_RESULTADO}", flush=True)
    print(f"  Estado idempotencia         : {ARQUIVO_ESTADO}", flush=True)
    print(f"{'='*70}", flush=True)


if __name__ == '__main__':
    main()
