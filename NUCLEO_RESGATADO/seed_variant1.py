import base64
import heapq
import io
import time
from collections import Counter
from typing import Dict, Optional, List, Tuple
from teia_core.utils import calculate_sha256, deterministic_json

def generate_seed_aut(file_b64: str) -> Dict:
    """
    Gera seed autônoma SR-AUT (AION-RISPA0.3a).
    Comprime o arquivo com gzip e codifica em base64.
    
    Args:
        file_b64: Arquivo original em base64
        
    Returns:
        Seed JSON no formato SR-AUT (0.3a)
    """
    file_bytes = base64.b64decode(file_b64)
    
    out_sha256 = calculate_sha256(file_bytes)
    out_len = len(file_bytes)
    
    compressed = _huffman_det_compress(file_bytes)
    
    operators = {
        "taxonomy": [
            {
                "family": "huffman.det.chunk",
                "op": "HUF_DET_CHUNK",
                "chunk": 65536,
                "codec": "gzip",
                "mtime": 0,
            }
        ]
    }

    seed = {
        "vm": "AION-RISPA0.3a",
        "out_len": out_len,
        "out_sha256": out_sha256,
        "operators": operators["taxonomy"],
        "program": [
            {
                "op": "HUF_DET_CHUNK",
                "algo": "huffman.det",
                "chunk": 65536,
                "code_lengths": compressed["code_lengths"],
                "bitstream_b64": compressed["bitstream_b64"],
                "original_len": out_len,
            }
        ],
    }
    
    seed_json = deterministic_json(seed)
    seed_size = len(seed_json.encode('utf-8'))
    
    return {
        "seed": seed,
        "seed_json": seed_json,
        "seed_size": seed_size,
        "original_size": out_len,
        "compression_ratio": out_len / seed_size if seed_size > 0 else 0
    }

def generate_seed_ref(file_b64: str, core_id: str, core_sha256: str, 
                      core_path: Optional[str] = None, 
                      coverage_threshold: float = 0.3) -> Dict:
    """
    Gera seed referencial SR-REF (AION-RISPA0.2r).
    Usa referências ao NDC (Núcleo Determinístico Compartilhado) quando possível.
    
    Args:
        file_b64: Arquivo original em base64
        core_id: ID do núcleo (ex: "teia.public.v2")
        core_sha256: SHA-256 do núcleo
        core_path: Caminho para o arquivo do núcleo (opcional para geração)
        coverage_threshold: Threshold de cobertura para usar SR-REF (default 0.3)
        
    Returns:
        Seed JSON no formato SR-REF (0.2r) ou fallback para SR-AUT se cobertura baixa
    """
    file_bytes = base64.b64decode(file_b64)
    out_sha256 = calculate_sha256(file_bytes)
    out_len = len(file_bytes)
    
    chunk_size = 65536
    
    if core_path and _check_core_exists(core_path):
        core_data = _load_core(core_path)
        core_len = len(core_data)
        
        coverage = _calculate_coverage(file_bytes, core_data, chunk_size)
        
        if coverage >= coverage_threshold:
            program = _build_ref_program(file_bytes, core_data, chunk_size)
            
            seed = {
                "vm": "AION-RISPA0.2r",
                "core_id": core_id,
                "core_sha256": core_sha256,
                "core_len": core_len,
                "chunk": chunk_size,
                "index": "fnv32-64k",
                "out_len": out_len,
                "out_sha256": out_sha256,
                "program": program
            }
            
            seed_json = deterministic_json(seed)
            seed_size = len(seed_json.encode('utf-8'))
            
            return {
                "seed": seed,
                "seed_json": seed_json,
                "seed_size": seed_size,
                "original_size": out_len,
                "core_size": core_len,
                "compression_ratio": out_len / (seed_size + core_len) if (seed_size + core_len) > 0 else 0,
                "mode": "SR-REF"
            }
    
    return generate_seed_aut(file_b64)

def _check_core_exists(core_path: str) -> bool:
    """Verifica se o arquivo do núcleo existe."""
    try:
        with open(core_path, 'rb') as f:
            return True
    except:
        return False

def _load_core(core_path: str) -> bytes:
    """Carrega o arquivo do núcleo."""
    with open(core_path, 'rb') as f:
        return f.read()

def _calculate_coverage(file_bytes: bytes, core_data: bytes, chunk_size: int) -> float:
    """
    Calcula a cobertura do arquivo pelo núcleo.
    Retorna a porcentagem de bytes que podem ser referenciados do core.
    """
    if len(file_bytes) == 0:
        return 0.0
    
    matched_bytes = 0
    file_len = len(file_bytes)
    
    for i in range(0, file_len, chunk_size):
        chunk = file_bytes[i:i + chunk_size]
        if chunk in core_data:
            matched_bytes += len(chunk)
    
    return matched_bytes / file_len

def _build_ref_program(file_bytes: bytes, core_data: bytes, chunk_size: int) -> List[Dict]:
    """
    Constrói o programa de referências e literais para SR-REF.
    """
    program = []
    file_len = len(file_bytes)
    i = 0
    
    while i < file_len:
        chunk = file_bytes[i:min(i + chunk_size, file_len)]
        
        offset = core_data.find(chunk)
        
        if offset != -1 and len(chunk) >= 1024:
            program.append({
                "op": "LZ_DET_RANGE",
                "family": "lz.det.chunk",
                "offset": offset,
                "length": len(chunk)
            })
            i += len(chunk)
        else:
            literal_end = min(i + chunk_size, file_len)
            literal = file_bytes[i:literal_end]
            literal_b64 = base64.b64encode(literal).decode('utf-8')
            
            program.append({
                "op": "LZ_DET_LITERAL",
                "family": "lz.det.chunk",
                "b64": literal_b64
            })
            i = literal_end
    
    return program
def _huffman_det_compress(data: bytes) -> Dict[str, List[Dict[str, int]]]:
    if not data:
        return {"code_lengths": [], "bitstream_b64": ""}

    freq = Counter(data)
    if len(freq) == 1:
        symbol = next(iter(freq.keys()))
        canonical = [{"symbol": symbol, "length": 1}]
        bit_bytes = b""
    else:
        class Node:
            __slots__ = ("freq", "symbol", "left", "right", "order")

            def __init__(self, freq, symbol=None, left=None, right=None, order=0):
                self.freq = freq
                self.symbol = symbol
                self.left = left
                self.right = right
                self.order = order

        heap = []
        order = 0
        for symbol, count in freq.items():
            heapq.heappush(heap, (count, order, Node(count, symbol=symbol, order=order)))
            order += 1

        while len(heap) > 1:
            c1, _, left = heapq.heappop(heap)
            c2, _, right = heapq.heappop(heap)
            parent = Node(c1 + c2, left=left, right=right, order=order)
            order += 1
            heapq.heappush(heap, (parent.freq, parent.order, parent))

        _, _, root = heap[0]
        lengths = {}

        def _assign(node, depth):
            if node.symbol is not None:
                lengths[node.symbol] = depth or 1
                return
            _assign(node.left, depth + 1)
            _assign(node.right, depth + 1)

        _assign(root, 0)

        canonical = [
            {"symbol": symbol, "length": length}
            for symbol, length in sorted(lengths.items(), key=lambda item: (item[1], item[0]))
        ]

        code = 0
        prev_len = 0
        codes = {}
        for entry in canonical:
            length = entry["length"]
            symbol = entry["symbol"]
            code <<= (length - prev_len)
            codes[symbol] = (code, length)
            code += 1
            prev_len = length

        bit_buffer = 0
        bit_len = 0
        output = bytearray()
        for b in data:
            bits, blen = codes[b]
            bit_buffer = (bit_buffer << blen) | bits
            bit_len += blen
            while bit_len >= 8:
                bit_len -= 8
                output.append((bit_buffer >> bit_len) & 0xFF)
        if bit_len:
            output.append((bit_buffer << (8 - bit_len)) & 0xFF)
        bit_bytes = bytes(output)

    return {
        "code_lengths": canonical,
        "bitstream_b64": base64.b64encode(bit_bytes).decode("utf-8"),
    }

def generate_seed(mode: str, file_b64: str, core_id: Optional[str] = None, 
                  core_sha256: Optional[str] = None, 
                  core_path: Optional[str] = None,
                  params: Optional[Dict] = None) -> Dict:
    """
    Endpoint POST /seed principal.
    Gera seed SR-AUT ou SR-REF baseado no modo.
    
    Args:
        mode: "aut" para SR-AUT ou "ref" para SR-REF
        file_b64: Arquivo em base64
        core_id: ID do núcleo (necessário para modo ref)
        core_sha256: SHA-256 do núcleo (necessário para modo ref)
        core_path: Caminho para o arquivo do núcleo (opcional)
        params: Parâmetros adicionais
        
    Returns:
        Resultado da geração da seed
    """
    start_time = time.time()
    
    if mode == "aut":
        result = generate_seed_aut(file_b64)
    elif mode == "ref":
        if not core_id or not core_sha256:
            raise ValueError("core_id e core_sha256 são necessários para modo 'ref'")
        result = generate_seed_ref(file_b64, core_id, core_sha256, core_path, 
                                   params.get('coverage_threshold', 0.3) if params else 0.3)
    else:
        raise ValueError(f"Modo inválido: {mode}. Use 'aut' ou 'ref'")
    
    end_time = time.time()
    result['generation_time_ms'] = round((end_time - start_time) * 1000, 2)
    
    return result
