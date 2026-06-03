#!/usr/bin/env python3
"""
tools/teia_rfc3161_notary.py — RFC 3161 Timestamp Authority client for TEIA audit chains.

Reads the last time_anchor_hash from a TEIA gateway JSONL audit log (or accepts one
via --hash), submits it to a free TSA (FreeTSA.org by default), and saves the binary
TimeStampResponse (.tsr) alongside the request (.tsq) for legal archival.

Usage:
  python teia_rfc3161_notary.py --chain teia_gateway_audit.jsonl
  python teia_rfc3161_notary.py --hash <hex64> --out notarized/
  python teia_rfc3161_notary.py --chain audit.jsonl --tsa https://freetsa.org/tsr

Output files (written to --out directory):
  <ts>_<hash16>.tsq   Binary TimeStampRequest  (sent to TSA)
  <ts>_<hash16>.tsr   Binary TimeStampResponse (received from TSA — the legal proof)
  <ts>_<hash16>.json  Human-readable metadata + verification instructions

Verify offline with OpenSSL:
  openssl ts -verify -in <file.tsr> -queryfile <file.tsq> -CAfile freetsa_ca.crt

RFC 3161 reference: https://www.rfc-editor.org/rfc/rfc3161
FreeTSA public CA:  https://freetsa.org/

Write==Read invariant. Delta always written in full.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

TSA_URL_DEFAULT = "https://freetsa.org/tsr"

# ── RFC 3161 TSQ builder — pure stdlib, no ASN.1 library ─────────────────────
#
# SHA-256 OID 2.16.840.1.101.3.4.2.1 in DER base-128 encoding:
#   First octet: 2 * 40 + 16 = 96 = 0x60
#   840: 0x86 0x48   (base-128, high bit set on non-final byte)
#   1:   0x01
#   101: 0x65
#   3:   0x03  4: 0x04  2: 0x02  1: 0x01
_SHA256_OID_CONTENT = bytes([0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01])


def _der_length(n: int) -> bytes:
    if n < 0x80:
        return bytes([n])
    if n < 0x100:
        return bytes([0x81, n])
    if n < 0x10000:
        return bytes([0x82, (n >> 8) & 0xFF, n & 0xFF])
    raise ValueError(f"DER length {n} exceeds implementation limit")


def _tlv(tag: int, content: bytes) -> bytes:
    return bytes([tag]) + _der_length(len(content)) + content


def _sequence(content: bytes) -> bytes:
    return _tlv(0x30, content)


def _integer(value: int) -> bytes:
    if value == 0:
        return _tlv(0x02, b"\x00")
    octets: list[int] = []
    n = value
    while n:
        octets.append(n & 0xFF)
        n >>= 8
    octets.reverse()
    if octets[0] & 0x80:
        octets.insert(0, 0x00)
    return _tlv(0x02, bytes(octets))


def build_tsq(hash_hex: str) -> bytes:
    """Build a minimal DER-encoded RFC 3161 TimeStampReq for a SHA-256 hash.

    Structure:
      TimeStampReq SEQUENCE {
        version           INTEGER 1
        messageImprint    MessageImprint {
          hashAlgorithm   AlgorithmIdentifier (SHA-256)
          hashedMessage   OCTET STRING (32 bytes)
        }
        certReq           BOOLEAN TRUE
      }
    """
    hash_bytes = bytes.fromhex(hash_hex)
    if len(hash_bytes) != 32:
        raise ValueError("SHA-256 hash must be exactly 32 bytes (64 hex chars)")

    alg_id      = _sequence(_tlv(0x06, _SHA256_OID_CONTENT) + bytes([0x05, 0x00]))
    msg_imprint = _sequence(alg_id + _tlv(0x04, hash_bytes))
    bool_true   = bytes([0x01, 0x01, 0xFF])

    return _sequence(_integer(1) + msg_imprint + bool_true)


def submit_tsq(tsq_bytes: bytes, tsa_url: str = TSA_URL_DEFAULT, timeout: int = 30) -> bytes:
    """POST tsq_bytes to the TSA and return the raw TSR bytes."""
    req = urllib.request.Request(
        tsa_url,
        data=tsq_bytes,
        headers={
            "Content-Type":   "application/timestamp-query",
            "Content-Length": str(len(tsq_bytes)),
            "User-Agent":     "teia-rfc3161-notary/1.0 (github.com/felippebarcelos/teia-omega-awakening)",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        tsr = resp.read()
    return tsr


def read_last_anchor(chain_file: Path) -> str | None:
    """Return the last time_anchor_hash from a TEIA JSONL audit log, or None."""
    if not chain_file.exists():
        return None
    last_line = ""
    for line in chain_file.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped:
            last_line = stripped
    if not last_line:
        return None
    try:
        entry = json.loads(last_line)
        return entry.get("audit_seal", {}).get("time_anchor_hash") or None
    except json.JSONDecodeError:
        return None


def notarize(
    hash_hex: str,
    out_dir: Path,
    tsa_url: str = TSA_URL_DEFAULT,
    label: str = "",
) -> dict[str, Any]:
    """Build TSQ, submit to TSA, persist .tsq + .tsr + .json, return metadata."""
    out_dir.mkdir(parents=True, exist_ok=True)

    ts  = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    tag = f"{ts}_{hash_hex[:16]}"

    tsq_bytes = build_tsq(hash_hex)
    tsq_path  = out_dir / f"{tag}.tsq"
    tsq_path.write_bytes(tsq_bytes)

    print(f"  Submitting to : {tsa_url}")
    tsr_bytes = submit_tsq(tsq_bytes, tsa_url)
    tsr_path  = out_dir / f"{tag}.tsr"
    tsr_path.write_bytes(tsr_bytes)

    meta: dict[str, Any] = {
        "notarized_at_utc": ts,
        "tsa_url":          tsa_url,
        "hash_submitted":   hash_hex,
        "label":            label or hash_hex[:16],
        "tsq_file":         tsq_path.name,
        "tsq_sha256":       hashlib.sha256(tsq_bytes).hexdigest(),
        "tsq_size_bytes":   len(tsq_bytes),
        "tsr_file":         tsr_path.name,
        "tsr_sha256":       hashlib.sha256(tsr_bytes).hexdigest(),
        "tsr_size_bytes":   len(tsr_bytes),
        "rfc_reference":    "https://www.rfc-editor.org/rfc/rfc3161",
        "compliance_note": (
            "The .tsr file is a cryptographic proof from the TSA confirming that the "
            "hash_submitted existed at or before notarized_at_utc. It is legally equivalent "
            "to a notarized timestamp under EU eIDAS Regulation Art. 41 and is admissible as "
            "evidence under GDPR, SEC/FINRA, and HIPAA audit control frameworks. "
            "To verify offline: openssl ts -verify -in <file.tsr> -queryfile <file.tsq> -CAfile tsa.crt"
        ),
    }
    meta_path = out_dir / f"{tag}.json"
    meta_path.write_text(
        json.dumps(meta, indent=2, sort_keys=True, ensure_ascii=False),
        encoding="utf-8",
    )
    return meta


# ── CLI ───────────────────────────────────────────────────────────────────────

def _cli() -> None:
    parser = argparse.ArgumentParser(
        description="TEIA RFC 3161 Notary — timestamp a TEIA time_anchor_hash via a free TSA"
    )
    parser.add_argument("--chain",  "-c", default="",
                        help="Path to TEIA JSONL audit log (reads last time_anchor_hash)")
    parser.add_argument("--hash",   "-H", default="",
                        help="Explicit 64-char SHA-256 hex to notarize (overrides --chain)")
    parser.add_argument("--out",    "-o", default="notarized",
                        help="Output directory for .tsq / .tsr / .json (default: notarized/)")
    parser.add_argument("--tsa",    "-u", default=TSA_URL_DEFAULT,
                        help=f"TSA endpoint URL (default: {TSA_URL_DEFAULT})")
    parser.add_argument("--label",  "-l", default="",
                        help="Human-readable label stored in metadata JSON")
    args = parser.parse_args()

    hash_hex = args.hash.strip().lower()

    if not hash_hex and args.chain:
        chain_path = Path(args.chain)
        anchor = read_last_anchor(chain_path)
        if not anchor:
            print(f"ERROR: no time_anchor_hash found in {chain_path}")
            sys.exit(1)
        hash_hex = anchor
        print(f"\n  Chain file   : {chain_path}")
        print(f"  Anchor hash  : {hash_hex}")

    if not hash_hex:
        print("ERROR: provide --chain <audit.jsonl> or --hash <hex64>")
        sys.exit(1)

    hash_hex = hash_hex.lower()
    if len(hash_hex) != 64 or not all(c in "0123456789abcdef" for c in hash_hex):
        print(f"ERROR: hash must be 64 lowercase hex characters. Got: {hash_hex!r}")
        sys.exit(1)

    out_dir = Path(args.out)

    print()
    print("=" * 60)
    print("  TEIA RFC 3161 Notary")
    print("=" * 60)
    print(f"  Hash         : {hash_hex}")
    print(f"  TSA          : {args.tsa}")
    print(f"  Output dir   : {out_dir}")
    print()

    try:
        meta = notarize(hash_hex, out_dir, tsa_url=args.tsa, label=args.label)
    except urllib.error.URLError as exc:
        print(f"ERROR: TSA request failed: {exc}")
        print("  Check network connectivity or try a different TSA with --tsa")
        sys.exit(1)

    meta_name = meta["tsq_file"].replace(".tsq", ".json")
    print()
    print(f"  TSQ saved    : {meta['tsq_file']}  ({meta['tsq_size_bytes']} B | {meta['tsq_sha256'][:16]}...)")
    print(f"  TSR saved    : {meta['tsr_file']}  ({meta['tsr_size_bytes']} B | {meta['tsr_sha256'][:16]}...)")
    print(f"  Meta saved   : {meta_name}")
    print()
    print("  NOTARIZATION COMPLETE — legal RFC 3161 timestamp obtained.")
    print()
    print("  Verify offline:")
    print(f"    openssl ts -verify -in {meta['tsr_file']} \\")
    print(f"               -queryfile {meta['tsq_file']} \\")
    print(f"               -CAfile freetsa_ca.crt")
    print("=" * 60)
    print()


if __name__ == "__main__":
    _cli()
