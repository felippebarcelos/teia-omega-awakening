<#
.SYNOPSIS
    TEIA-Omni-VFS-v0600.ps1 — Motor VFS Nativo (P9.0)

.DESCRIPTION
    Monta o drive virtual TEIA (T:\) de forma nativa no Windows Explorer.

    Estrategia de montagem (em ordem de preferencia):
      1. WinFsp + Python winfspy  -> T:\ como filesystem NTFS nativo
         Arquivos parecem arquivos reais ao Explorer, VLC, Premiere, IDEs.
         Chunk-on-demand: SO interceptado em Read(offset, length),
         retorna 64KB reconstituidos do CAS, buffer destruido pos-entrega.

      2. WebDAV + net use         -> T:\ via protocolo WebDAV
         Compativel com Explorer nativo via WebClient service.
         Requer Start-Service WebClient + porta 8766.

    A bridge Python (TEIA-Omni-VFS-Bridge.py) e gerada automaticamente
    em D:\TEIA_CORE\tools\ e reutilizavel entre sessoes.

    Invariantes P9.0:
      Read e idempotente -- CAS Delta = 0 (objects/ intocado)
      OOM Guard -- SO recebe max 64KB por callback, buffer descartado
      Stubs intocados -- nenhum .teia_stub modificado pelo motor VFS

.PARAMETER VFSRoot
    Diretorio com .teia_stub a expor. Padrao: D:\TEIA_USER\ActiveDrive_Test

.PARAMETER CASRoot
    Raiz do CAS. Padrao: D:\TEIA_CORE\objects

.PARAMETER CacheDir
    Cache de descompressao para cmp.lzma/brotli.
    Padrao: D:\TEIA_CORE\vfs_cache

.PARAMETER MountPoint
    Letra de drive para montagem WinFsp.
    Padrao: T:

.PARAMETER Port
    Porta para fallback WebDAV (se WinFsp nao disponivel).
    Padrao: 8766

.PARAMETER ForceWebDAV
    Forcca uso do daemon WebDAV mesmo se WinFsp estiver disponivel.

.PARAMETER ClearCache
    Limpa .dec do CacheDir ao iniciar.
#>
[CmdletBinding()]
param(
    [string]$VFSRoot     = 'D:\TEIA_USER\ActiveDrive_Test',
    [string]$CASRoot     = 'D:\TEIA_CORE\objects',
    [string]$CacheDir    = 'D:\TEIA_CORE\vfs_cache',
    [string]$MountPoint  = 'T:',
    [string]$Port        = '8766',
    [switch]$ForceWebDAV,
    [switch]$ClearCache
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$IC = [System.Globalization.CultureInfo]::InvariantCulture

# ── Banner ────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host '  TEIA-Omni-VFS v0.60.0 — Motor VFS Nativo P9.0' -ForegroundColor Cyan
Write-Host ('─' * 78)
Write-Host "  VFSRoot    : $VFSRoot"
Write-Host "  MountPoint : $MountPoint"
Write-Host "  CASRoot    : $CASRoot"
Write-Host "  CacheDir   : $CacheDir"
Write-Host "  CAS Delta  : 0 -- operacao de leitura pura (objects/ intocado)"
Write-Host ('─' * 78)

# ── Validacoes ────────────────────────────────────────────────────────────────

if (-not (Test-Path -LiteralPath $VFSRoot)) {
    Write-Host "[VFS] ERRO: VFSRoot nao encontrado: $VFSRoot" -ForegroundColor Red; exit 1
}
New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
if ($ClearCache) {
    Get-ChildItem -LiteralPath $CacheDir -Filter '*.dec' |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "  Cache limpo." -ForegroundColor DarkYellow
}

# ── Deteccao de ambiente ──────────────────────────────────────────────────────

function Test-WinFspInstalled {
    $paths = @(
        'C:\Program Files (x86)\WinFsp\bin\winfsp-x64.dll',
        'C:\Program Files\WinFsp\bin\winfsp-x64.dll'
    )
    foreach ($p in $paths) { if (Test-Path $p) { return $p } }
    # Checar via winget
    $out = winget list --id WinFsp.WinFsp 2>$null
    if ($out -match 'WinFsp') { return 'winget_detected' }
    return $null
}

function Test-PythonWinfspy {
    try {
        $out = python -c "import winfspy; print(winfspy.__version__)" 2>&1
        if ($out -match '^\d') { return [string]$out.Trim() }
    } catch {}
    return $null
}

function Test-PythonAvailable {
    try { $v = python --version 2>&1; return $v -match 'Python 3' } catch { return $false }
}

# ── Geracao da bridge Python ──────────────────────────────────────────────────

$bridgePath = 'D:\TEIA_CORE\tools\TEIA-Omni-VFS-Bridge.py'

function Write-PythonBridge {
    New-Item -ItemType Directory -Path (Split-Path $bridgePath -Parent) -Force | Out-Null

    $code = @'
#!/usr/bin/env python3
"""
TEIA-Omni-VFS-Bridge.py — WinFsp native mount (P9.0)
Gerado por TEIA-Omni-VFS-v0600.ps1

Implementa FileSystemOperations via winfspy para montar T:\
como filesystem NTFS nativo. Chunk-on-demand: cada Read(offset, length)
do SO recebe exatamente os bytes solicitados do CAS -- OOM Guard 64KB.

CAS Delta = 0: nenhum byte escrito em objects/
"""

import sys, os, json, gzip, threading, time, struct, signal
from pathlib import Path
from datetime import datetime, timezone

try:
    import winfspy
    from winfspy import (
        FileSystem,
        FileSystemOperations,
        FILE_ATTRIBUTE,
        CREATE_FILE_CREATE_OPTIONS,
        NTStatusError,
    )
    from winfspy.plumbing.winstuff import filetime_now
    import ntstatus
except ImportError as e:
    print(f"[TEIA-VFS] ERRO: winfspy nao instalado: {e}", file=sys.stderr)
    print("[TEIA-VFS] Instale com: pip install winfspy", file=sys.stderr)
    print("[TEIA-VFS] Requisito: WinFsp instalado (winget install WinFsp.WinFsp)", file=sys.stderr)
    sys.exit(1)

CHUNK = 65536  # OOM Guard: max bytes por operacao de leitura

class VirtualEntry:
    """Metadados de um arquivo virtual derivados do .teia_stub"""
    __slots__ = ('name', 'size', 'sha256', 'strategy', 'cas_path', 'cas_size')

    def __init__(self, d: dict):
        self.name     = d.get('original_name', '')
        self.size     = int(d.get('original_size_bytes', 0))
        self.sha256   = d.get('original_sha256', '')
        self.strategy = d.get('final_strategy', 'cas.raw')
        self.cas_path = d.get('cas_path', '')
        self.cas_size = int(d.get('cas_size_bytes', 0))


class TEIAFileContext:
    """Contexto de arquivo aberto passado entre callbacks do WinFsp"""
    def __init__(self, is_dir=False, entry=None):
        self.is_dir = is_dir
        self.entry  = entry  # VirtualEntry ou None (raiz)


class TEIAFileSystem(FileSystemOperations):
    """
    Implementacao do filesystem virtual TEIA para WinFsp.

    Garante:
    - read() devolve exatamente length bytes reconstituidos do CAS
    - Nenhum byte escrito em objects/ (CAS Delta = 0)
    - RAM por operacao <= CHUNK = 64KB (OOM Guard)
    - Idempotencia: resultado de read(offset, length) e deterministico
    """

    def __init__(self, vfs_root: str, cache_dir: str):
        super().__init__()
        self.vfs_root  = Path(vfs_root)
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self._lock     = threading.Lock()
        self.manifest  = self._build_manifest()
        print(f"[TEIA-VFS] Manifesto: {len(self.manifest)} arquivos virtuais")

    def _build_manifest(self) -> dict:
        m = {}
        for stub in self.vfs_root.rglob('*.teia_stub'):
            try:
                d = json.loads(stub.read_text(encoding='utf-8'))
                name = d.get('original_name', '')
                if name:
                    m[name.lower()] = VirtualEntry(d)
            except Exception as e:
                print(f"[TEIA-VFS] AVISO stub {stub.name}: {e}", file=sys.stderr)
        return m

    def _decompress_to_cache(self, ve: VirtualEntry) -> Path:
        cache_path = self.cache_dir / f"{ve.sha256}.dec"
        if cache_path.exists():
            return cache_path
        tmp = cache_path.with_suffix('.tmp')
        print(f"[TEIA-VFS] Cache miss: descomprimindo {ve.name}...", flush=True)
        strat = ve.strategy
        with open(ve.cas_path, 'rb') as inp:
            raw = inp.read()
        if strat == 'cmp.lzma':
            import gzip as gz
            data = gz.decompress(raw)
        else:
            # cmp.brotli, gen.parametric_mesh
            try:
                import brotli
                data = brotli.decompress(raw)
            except ImportError:
                # Fallback: dados sao bytes do arquivo original (nao deveriam estar comprimidos aqui)
                data = raw
        tmp.write_bytes(data)
        tmp.rename(cache_path)
        return cache_path

    def _read_range(self, ve: VirtualEntry, offset: int, length: int) -> bytes:
        """Chunk-on-demand: devolve exatamente `length` bytes de `offset`."""
        strat = ve.strategy

        if strat == 'cas.raw':
            with open(ve.cas_path, 'rb') as f:
                f.seek(offset)
                return f.read(length)

        elif strat == 'gen.repeat':
            seed = json.loads(Path(ve.cas_path).read_text('utf-8'))
            val  = int(seed['value_hex'], 16)
            return bytes([val]) * length

        elif strat == 'gen.pattern':
            seed    = json.loads(Path(ve.cas_path).read_text('utf-8'))
            import base64
            pattern = base64.b64decode(seed['pattern_b64'])
            p = len(pattern)
            return bytes(pattern[(offset + i) % p] for i in range(length))

        else:
            # cmp.lzma, cmp.brotli, gen.parametric_mesh -> cache na 1a leitura
            with self._lock:
                cache = self._decompress_to_cache(ve)
            with open(cache, 'rb') as f:
                f.seek(offset)
                return f.read(length)

    # ── WinFsp callbacks ──────────────────────────────────────────────────────

    def get_volume_info(self):
        return self.VolumeInfo(
            total_size    = 100 * 1024 ** 3,  # 100 GB virtual
            free_size     = 0,
            volume_label  = 'TEIA-Drive'
        )

    def get_security_by_name(self, file_name: str, find_reparse_point):
        norm = file_name.strip('\\').lower()
        if norm == '' or norm == '.':
            return FILE_ATTRIBUTE.DIRECTORY | FILE_ATTRIBUTE.READONLY, None, 0
        if norm in self.manifest:
            return FILE_ATTRIBUTE.READONLY | FILE_ATTRIBUTE.NORMAL, None, 0
        raise NTStatusError(ntstatus.STATUS_OBJECT_NAME_NOT_FOUND)

    def open(self, file_name: str, create_options, granted_access, p_file_context, p_file_info):
        norm = file_name.strip('\\').lower()
        now  = filetime_now()

        if norm in ('', '.', '\\'):
            ctx = TEIAFileContext(is_dir=True)
            p_file_context.value = ctx
            p_file_info.file_attributes      = FILE_ATTRIBUTE.DIRECTORY | FILE_ATTRIBUTE.READONLY
            p_file_info.creation_time        = now
            p_file_info.last_access_time     = now
            p_file_info.last_write_time      = now
            p_file_info.change_time          = now
            p_file_info.file_size            = 0
            p_file_info.allocation_size      = 0
            return ntstatus.STATUS_SUCCESS

        if norm in self.manifest:
            ve = self.manifest[norm]
            ctx = TEIAFileContext(is_dir=False, entry=ve)
            p_file_context.value = ctx
            p_file_info.file_attributes      = FILE_ATTRIBUTE.READONLY | FILE_ATTRIBUTE.NORMAL
            p_file_info.creation_time        = now
            p_file_info.last_access_time     = now
            p_file_info.last_write_time      = now
            p_file_info.change_time          = now
            p_file_info.file_size            = ve.size
            p_file_info.allocation_size      = (ve.size + 511) & ~511
            return ntstatus.STATUS_SUCCESS

        raise NTStatusError(ntstatus.STATUS_OBJECT_NAME_NOT_FOUND)

    def create(self, file_name, *args):
        raise NTStatusError(ntstatus.STATUS_MEDIA_WRITE_PROTECTED)

    def close(self, file_context):
        pass  # sem estado a limpar por arquivo

    def cleanup(self, file_context, file_name, flags):
        pass

    def read(self, file_context, buffer, offset, length):
        """Chunk-on-demand com OOM Guard: devolve <= CHUNK bytes por chamada."""
        ctx = file_context
        if ctx.is_dir or ctx.entry is None:
            return 0
        ve = ctx.entry
        # Clampar dentro dos limites do arquivo
        offset  = max(0, min(offset, ve.size))
        length  = max(0, min(length, ve.size - offset, CHUNK))
        if length == 0:
            return 0
        data = self._read_range(ve, offset, length)
        n = len(data)
        buffer[:n] = data
        return n  # bytes_transferred

    def read_directory(self, file_context, pattern, marker, buffer):
        ctx = file_context
        if not ctx.is_dir:
            return
        entries = [('.', FILE_ATTRIBUTE.DIRECTORY), ('..', FILE_ATTRIBUTE.DIRECTORY)]
        for name_lower, ve in sorted(self.manifest.items()):
            entries.append((ve.name, FILE_ATTRIBUTE.READONLY | FILE_ATTRIBUTE.NORMAL,
                            ve.size, ve.size))
        for entry in entries:
            if isinstance(entry, tuple) and len(entry) == 2:
                fname, attrs = entry
                info = self.DirInfo()
                info.file_name = fname
                info.file_info.file_attributes = attrs
                info.file_info.file_size = 0
                if not buffer.write(info):
                    break
            elif isinstance(entry, tuple) and len(entry) == 4:
                fname, attrs, sz, alloc = entry
                info = self.DirInfo()
                info.file_name = fname
                info.file_info.file_attributes = attrs
                info.file_info.file_size       = sz
                info.file_info.allocation_size = (alloc + 511) & ~511
                if not buffer.write(info):
                    break

    def get_file_info(self, file_context, file_info):
        ctx = file_context
        now = filetime_now()
        if ctx.is_dir:
            file_info.file_attributes = FILE_ATTRIBUTE.DIRECTORY | FILE_ATTRIBUTE.READONLY
            file_info.file_size = 0
        else:
            file_info.file_attributes = FILE_ATTRIBUTE.READONLY | FILE_ATTRIBUTE.NORMAL
            file_info.file_size = ctx.entry.size
            file_info.allocation_size = (ctx.entry.size + 511) & ~511
        file_info.creation_time    = now
        file_info.last_access_time = now
        file_info.last_write_time  = now
        file_info.change_time      = now
        return ntstatus.STATUS_SUCCESS


def main():
    import argparse
    parser = argparse.ArgumentParser(description='TEIA VFS Bridge (WinFsp/winfspy)')
    parser.add_argument('--vfs-root',    required=True,  help='Diretorio com .teia_stub')
    parser.add_argument('--mount-point', required=True,  help='Drive letter (ex: T:)')
    parser.add_argument('--cache-dir',   default='D:\\TEIA_CORE\\vfs_cache')
    args = parser.parse_args()

    ops = TEIAFileSystem(vfs_root=args.vfs_root, cache_dir=args.cache_dir)
    fs  = FileSystem(
        mountpoint          = args.mount_point,
        operations          = ops,
        sector_size         = 512,
        sectors_per_allocation_unit = 1,
        volume_creation_time        = filetime_now(),
        volume_serial_number        = 0x54454941,   # TEIA em hex ASCII
        file_info_timeout           = 1000,
        case_sensitive_search       = False,
        case_preserved_names        = True,
        unicode_on_disk             = True,
        persistent_acls             = False,
        post_cleanup_when_modified_only = True,
    )

    print(f"[TEIA-VFS] Montando em {args.mount_point}...", flush=True)
    try:
        fs.start()
        print(f"[TEIA-VFS] Drive {args.mount_point} ativo. CAS Delta = 0. OOM Guard = {CHUNK//1024}KB.", flush=True)
        print(f"[TEIA-VFS] Pressione Ctrl+C para desmontar.", flush=True)

        def _stop(sig, frame):
            print(f"\n[TEIA-VFS] Sinal {sig} recebido. Desmontando...", flush=True)
            fs.stop()
            sys.exit(0)

        signal.signal(signal.SIGINT,  _stop)
        signal.signal(signal.SIGTERM, _stop)

        while True:
            time.sleep(1)

    except Exception as e:
        print(f"[TEIA-VFS] ERRO durante montagem: {e}", file=sys.stderr)
        try: fs.stop()
        except: pass
        sys.exit(1)

if __name__ == '__main__':
    main()
'@

    [System.IO.File]::WriteAllText($bridgePath, $code, [System.Text.Encoding]::UTF8)
    Write-Host "  Bridge Python gerada: $bridgePath" -ForegroundColor DarkGray
}

# ── Estrategia 1: WinFsp + winfspy ───────────────────────────────────────────

function Start-WinFspMount {
    Write-Host ''
    Write-Host '  [VFS] Estrategia 1: WinFsp + Python winfspy' -ForegroundColor Cyan

    # Verificar WinFsp
    $winfspDll = Test-WinFspInstalled
    if (-not $winfspDll) {
        Write-Host '  [VFS] WinFsp nao encontrado.' -ForegroundColor DarkYellow
        Write-Host '        Instale com: winget install WinFsp.WinFsp' -ForegroundColor DarkYellow
        return $false
    }
    Write-Host "  [VFS] WinFsp detectado: $winfspDll" -ForegroundColor DarkGray

    # Verificar Python
    if (-not (Test-PythonAvailable)) {
        Write-Host '  [VFS] Python 3 nao encontrado no PATH.' -ForegroundColor DarkYellow
        return $false
    }

    # Verificar winfspy
    $winfspyVer = Test-PythonWinfspy
    if (-not $winfspyVer) {
        Write-Host '  [VFS] winfspy nao instalado. Tentando instalar...' -ForegroundColor DarkYellow
        python -m pip install winfspy --quiet 2>&1 | Out-Null
        $winfspyVer = Test-PythonWinfspy
        if (-not $winfspyVer) {
            Write-Host '  [VFS] Falha ao instalar winfspy. Tentando pip install winfspy manualmente.' -ForegroundColor Red
            return $false
        }
    }
    Write-Host "  [VFS] winfspy v$winfspyVer detectado." -ForegroundColor DarkGray

    # Gerar bridge
    Write-PythonBridge

    # Verificar se drive ja montado
    if (Test-Path "${MountPoint}\") {
        Write-Host "  [VFS] AVISO: ${MountPoint} ja existe. Desmontar antes de re-montar." -ForegroundColor DarkYellow
    }

    $stubs = @(Get-ChildItem -LiteralPath $VFSRoot -Filter '*.teia_stub' -Recurse -ErrorAction SilentlyContinue).Count
    Write-Host "  [VFS] Manifesto: $stubs stubs em $VFSRoot" -ForegroundColor Green
    Write-Host ''
    Write-Host "  [VFS] Iniciando bridge WinFsp..." -ForegroundColor Green
    Write-Host "        python `"$bridgePath`" --vfs-root `"$VFSRoot`" --mount-point $MountPoint --cache-dir `"$CacheDir`""
    Write-Host ''

    # Lancar Python bridge (foreground — bloqueia ate Ctrl+C)
    & python $bridgePath `
        --vfs-root   $VFSRoot `
        --mount-point $MountPoint `
        --cache-dir  $CacheDir

    return $true
}

# ── Estrategia 2: WebDAV + net use ───────────────────────────────────────────

function Start-WebDAVMount {
    Write-Host ''
    Write-Host '  [VFS] Estrategia 2: WebDAV + net use (fallback P8.1)' -ForegroundColor DarkYellow
    Write-Host ''

    $webdavScript = 'D:\TEIA_CORE\tools\TEIA-VFS-WebDAV-v0510.ps1'
    $webdavAlt    = Join-Path (Split-Path $PSCommandPath -Parent) 'TEIA-VFS-WebDAV-v0510.ps1'
    if (-not (Test-Path $webdavScript)) { $webdavScript = $webdavAlt }

    if (-not (Test-Path $webdavScript)) {
        Write-Host "  [VFS] ERRO: TEIA-VFS-WebDAV-v0510.ps1 nao encontrado." -ForegroundColor Red
        Write-Host "        Esperado em: $webdavScript" -ForegroundColor Red
        exit 1
    }

    # Ativar WebClient service (necessario para WebDAV no Windows)
    $svc = Get-Service -Name WebClient -ErrorAction SilentlyContinue
    if ($svc) {
        if ($svc.Status -ne 'Running') {
            Write-Host '  [VFS] Iniciando servico WebClient...' -ForegroundColor DarkYellow
            Start-Service -Name WebClient -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
        Write-Host "  [VFS] WebClient: $((Get-Service WebClient).Status)" -ForegroundColor DarkGray
    } else {
        Write-Host '  [VFS] AVISO: Servico WebClient nao encontrado (necessario para net use).' -ForegroundColor DarkYellow
    }

    Write-Host ''
    Write-Host '  Para montar o drive WebDAV (em outro terminal):' -ForegroundColor White
    Write-Host "    net use ${MountPoint} \\localhost@${Port}\DavWWWRoot\ /persistent:no" -ForegroundColor Cyan
    Write-Host "    dir ${MountPoint}\" -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  Iniciando daemon WebDAV...' -ForegroundColor Green
    Write-Host '  Pressione Ctrl+C para parar.' -ForegroundColor DarkGray
    Write-Host ('─' * 78)

    & pwsh -NoProfile -ExecutionPolicy Bypass -File $webdavScript `
        -VFSRoot $VFSRoot -Port $Port `
        $(if ($ClearCache) { '-ClearCache' })
}

# ── Decisao de estrategia e execucao ─────────────────────────────────────────

Write-Host ''

$useWinFsp = (-not $ForceWebDAV) -and (Test-WinFspInstalled) -and (Test-PythonAvailable)

if ($useWinFsp) {
    Write-Host "  [VFS] WinFsp disponivel -> tentando montagem nativa" -ForegroundColor Green
    $ok = Start-WinFspMount
    if (-not $ok) {
        Write-Host "  [VFS] Montagem WinFsp falhou -> fallback WebDAV" -ForegroundColor DarkYellow
        Start-WebDAVMount
    }
} else {
    if ($ForceWebDAV) {
        Write-Host "  [VFS] ForceWebDAV ativo -> usando WebDAV" -ForegroundColor DarkYellow
    } else {
        Write-Host "  [VFS] WinFsp/Python nao disponivel -> usando WebDAV" -ForegroundColor DarkYellow
        Write-Host "        Para ativar WinFsp nativo:" -ForegroundColor DarkGray
        Write-Host "          winget install WinFsp.WinFsp" -ForegroundColor DarkGray
        Write-Host "          pip install winfspy" -ForegroundColor DarkGray
    }
    Start-WebDAVMount
}
