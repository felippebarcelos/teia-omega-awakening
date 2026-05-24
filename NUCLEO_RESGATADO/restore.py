import base64
import time
from typing import Dict, Optional
from teia_core.utils import calculate_sha256

def restore_seed_aut(seed: Dict, region: Optional[Dict[str, int]] = None) -> Dict:
    """
    Restaura arquivo a partir de seed SR-AUT (AION-RISPA0.3a).
    Infla o gzip e valida SHA-256.
    
    Args:
        seed: Seed JSON no formato 0.3a
        
    Returns:
        {
            "ok": bool,
            "out_sha256": str,
            "bytes": int,
            "restored_data": bytes,
            "validation_time_ms": float
        }
    """
    start_time = time.time()
    
    if seed.get("vm") != "AION-RISPA0.3a":
        raise ValueError(f"VM incompatível: {seed.get('vm')}. Esperado: AION-RISPA0.3a")
    
    program = seed.get("program", [])
    if len(program) != 1 or program[0].get("op") != "HUF_DET_CHUNK":
        raise ValueError("Programa inválido para SR-AUT 0.3a (esperado HUF_DET_CHUNK)")
    
    step = program[0]
    if step.get("algo") != "huffman.det":
        raise ValueError(f"Operador inesperado: {step.get('algo')}")
    
    code_lengths = step.get("code_lengths")
    bitstream_b64 = step.get("bitstream_b64")
    original_len = step.get("original_len", seed.get("out_len"))
    if code_lengths is None or bitstream_b64 is None:
        raise ValueError("code_lengths ou bitstream ausentes em HUF_DET_CHUNK")
    
    restored = _huffman_det_decompress(code_lengths, base64.b64decode(bitstream_b64), original_len)
    
    out_sha256 = calculate_sha256(restored)
    out_len = len(restored)
    
    expected_sha256 = seed.get("out_sha256")
    expected_len = seed.get("out_len")
    
    sha_ok = (out_sha256 == expected_sha256)
    len_ok = (out_len == expected_len)
    
    if not sha_ok:
        raise ValueError(f"SHA-256 mismatch! Esperado: {expected_sha256}, Obtido: {out_sha256}")
    
    if not len_ok:
        raise ValueError(f"Tamanho mismatch! Esperado: {expected_len}, Obtido: {out_len}")
    
    region_slice, region_meta = _extract_region(restored, region)
    
    end_time = time.time()
    validation_time_ms = round((end_time - start_time) * 1000, 2)
    
    return {
        "ok": True,
        "out_sha256": out_sha256,
        "bytes": out_len,
        "restored_data": restored if region is None else region_slice,
        "validation_time_ms": validation_time_ms,
        "region": region_meta
    }

def restore_seed_ref(seed: Dict, core_path: str, region: Optional[Dict[str, int]] = None) -> Dict:
    """
    Restaura arquivo a partir de seed SR-REF (AION-RISPA0.2r).
    Aplica program com REF_CORE_RANGE e LITERAL_B64 usando o NDC.
    
    Args:
        seed: Seed JSON no formato 0.2r
        core_path: Caminho para o arquivo do núcleo
        
    Returns:
        {
            "ok": bool,
            "out_sha256": str,
            "bytes": int,
            "restored_data": bytes,
            "validation_time_ms": float
        }
    """
    start_time = time.time()
    
    if seed.get("vm") != "AION-RISPA0.2r":
        raise ValueError(f"VM incompatível: {seed.get('vm')}. Esperado: AION-RISPA0.2r")
    
    core_data = _load_and_validate_core(seed, core_path)
    
    program = seed.get("program", [])
    if not program:
        raise ValueError("Program vazio. Seeds devem ser sempre verificáveis.")
    
    restored = bytearray()
    
    for instruction in program:
        op = instruction.get("op")
        
        if op == "LZ_DET_RANGE":
            offset = instruction.get("offset")
            length = instruction.get("length")
            
            if offset is None or length is None:
                raise ValueError("REF_CORE_RANGE requer offset e length")
            
            if offset < 0 or offset + length > len(core_data):
                raise ValueError(f"Range inválido: offset={offset}, length={length}, core_len={len(core_data)}")
            
            chunk = core_data[offset:offset + length]
            restored.extend(chunk)
            
        elif op == "LZ_DET_LITERAL":
            b64_data = instruction.get("b64")
            if not b64_data:
                raise ValueError("LITERAL_B64 requer campo b64")
            
            literal = base64.b64decode(b64_data)
            restored.extend(literal)
            
        else:
            raise ValueError(f"Operação desconhecida: {op}")
    
    restored_bytes = bytes(restored)
    out_sha256 = calculate_sha256(restored_bytes)
    out_len = len(restored_bytes)
    
    expected_sha256 = seed.get("out_sha256")
    expected_len = seed.get("out_len")
    
    sha_ok = (out_sha256 == expected_sha256)
    len_ok = (out_len == expected_len)
    
    if not sha_ok:
        raise ValueError(f"SHA-256 mismatch! Esperado: {expected_sha256}, Obtido: {out_sha256}")
    
    if not len_ok:
        raise ValueError(f"Tamanho mismatch! Esperado: {expected_len}, Obtido: {out_len}")
    
    region_slice, region_meta = _extract_region(restored_bytes, region)
    
    end_time = time.time()
    validation_time_ms = round((end_time - start_time) * 1000, 2)
    
    return {
        "ok": True,
        "out_sha256": out_sha256,
        "bytes": out_len,
        "restored_data": restored_bytes if region is None else region_slice,
        "validation_time_ms": validation_time_ms,
        "region": region_meta
    }

def _load_and_validate_core(seed: Dict, core_path: str) -> bytes:
    """
    Carrega e valida o arquivo do núcleo.
    """
    try:
        with open(core_path, 'rb') as f:
            core_data = f.read()
    except FileNotFoundError:
        raise ValueError(f"Núcleo não encontrado: {core_path}")
    except Exception as e:
        raise ValueError(f"Erro ao carregar núcleo: {e}")
    
    core_sha256 = calculate_sha256(core_data)
    expected_core_sha256 = seed.get("core_sha256")
    
    if core_sha256 != expected_core_sha256:
        raise ValueError(f"SHA-256 do núcleo inválido! Esperado: {expected_core_sha256}, Obtido: {core_sha256}")
    
    core_len = len(core_data)
    expected_core_len = seed.get("core_len")
    
    if core_len != expected_core_len:
        raise ValueError(f"Tamanho do núcleo inválido! Esperado: {expected_core_len}, Obtido: {core_len}")
    
    return core_data

def restore_seed(seed: Dict, core_path: Optional[str] = None, region: Optional[Dict[str, int]] = None) -> Dict:
    """
    Endpoint POST /restore principal.
    Restaura arquivo a partir de seed (SR-AUT ou SR-REF).
    
    Args:
        seed: Seed JSON
        core_path: Caminho para o núcleo (necessário para SR-REF)
        
    Returns:
        Resultado da restauração com dados validados
    """
    vm = seed.get("vm")
    
    if not vm:
        raise ValueError("Campo 'vm' ausente na seed")
    
    if vm == "AION-RISPA0.3a":
        return restore_seed_aut(seed, region=region)
    elif vm == "AION-RISPA0.2r":
        if not core_path:
            raise ValueError("core_path é necessário para restaurar seeds SR-REF (0.2r)")
        return restore_seed_ref(seed, core_path, region=region)
    else:
        raise ValueError(f"VM não suportada: {vm}")


def _extract_region(data: bytes, region: Optional[Dict[str, int]]) -> tuple[bytes, Optional[Dict[str, int]]]:
    """
    Retorna o recorte da região solicitada e suas métricas.
    """
    if not region:
        return data, None
    
    offset = int(region.get("offset", 0))
    length = region.get("length")
    if offset < 0:
        raise ValueError("offset não pode ser negativo")
    if length is None or length <= 0:
        raise ValueError("length deve ser positivo para restore.region")
    end = offset + length
    if end > len(data):
        raise ValueError("restore.region excede o tamanho do artefato restaurado")
    
    region_bytes = data[offset:end]
    return region_bytes, {
        "offset": offset,
        "length": length,
        "sha256": calculate_sha256(region_bytes),
    }


def _huffman_det_decompress(code_lengths: list[dict], bitstream: bytes, output_len: int) -> bytes:
    if not code_lengths or not output_len:
        return b""

    entries = sorted(code_lengths, key=lambda item: (item["length"], item["symbol"]))

    if not bitstream and len(entries) == 1:
        symbol = entries[0]["symbol"]
        return bytes([symbol] * output_len)

    code = 0
    prev_len = 0
    length_lookup = {}
    for entry in entries:
        length = entry["length"]
        symbol = entry["symbol"]
        code <<= (length - prev_len)
        length_lookup.setdefault(length, {})[code] = symbol
        code += 1
        prev_len = length

    output = bytearray()
    bit_buffer = 0
    bit_len = 0
    lengths_sorted = sorted(length_lookup.keys())

    for byte in bitstream:
        bit_buffer = (bit_buffer << 8) | byte
        bit_len += 8
        while True:
            matched = False
            for length in lengths_sorted:
                if bit_len < length:
                    break
                code_val = (bit_buffer >> (bit_len - length)) & ((1 << length) - 1)
                symbol = length_lookup[length].get(code_val)
                if symbol is not None:
                    output.append(symbol)
                    bit_len -= length
                    bit_buffer &= (1 << bit_len) - 1 if bit_len else 0
                    matched = True
                    break
            if not matched or len(output) >= output_len:
                break
        if len(output) >= output_len:
            break
    return bytes(output[:output_len])
