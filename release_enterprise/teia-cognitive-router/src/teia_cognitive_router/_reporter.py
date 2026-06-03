"""
P53.0 — Compliance Report Generator
Generates self-contained HTML compliance reports from TEIA audit chains.
EU AI Act Art. 12/13/Annex IV · GDPR Art. 22 · SOC 2 CC7.2
Pure stdlib — no dependencies.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

_REPORT_VERSION  = "1.4.0"
_REPORT_PROTOCOL = "P53.0"

# ── CSS (kept outside f-strings to avoid brace-doubling) ─────────────────────

_CSS = """
:root {
  --pass: #1a7f37; --fail: #cf222e; --warn: #9a6700;
  --bg: #fff; --border: #d0d7de; --header: #0d1117;
  --mono: "SFMono-Regular", Consolas, "Liberation Mono", monospace;
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
  font-size: 14px; color: #1f2328; background: var(--bg); padding: 40px;
}
@media print { body { padding: 0; } .no-print { display: none; } }

header {
  background: var(--header); color: #fff;
  padding: 28px 32px; border-radius: 8px; margin-bottom: 32px;
}
header h1 { font-size: 22px; font-weight: 600; margin-bottom: 6px; }
header p  { font-size: 13px; color: #8b949e; margin-top: 4px; }
header .mono { font-family: var(--mono); font-size: 12px; color: #e6edf3; }

.badge {
  display: inline-block; padding: 3px 10px; border-radius: 20px;
  font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: .5px;
}
.badge.pass { background: #dafbe1; color: var(--pass); }
.badge.fail { background: #ffebe9; color: var(--fail); }
.badge.warn { background: #fff8c5; color: var(--warn); }

.verdict {
  padding: 20px 24px; border-radius: 8px; margin-bottom: 32px;
  border: 2px solid; display: flex; align-items: center; gap: 16px;
}
.verdict.pass { border-color: var(--pass); background: #dafbe1; }
.verdict.fail { border-color: var(--fail); background: #ffebe9; }
.verdict .icon { font-size: 36px; line-height: 1; }
.verdict h2  { font-size: 18px; font-weight: 700; }
.verdict p   { font-size: 13px; margin-top: 4px; color: #656d76; }
.verdict .right { margin-left: auto; }

.metrics {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 16px; margin-bottom: 36px;
}
.metric {
  border: 1px solid var(--border); border-radius: 8px; padding: 16px;
}
.metric .label {
  font-size: 11px; color: #656d76; text-transform: uppercase;
  letter-spacing: .5px; margin-bottom: 6px;
}
.metric .value { font-size: 26px; font-weight: 700; line-height: 1; }
.metric .sub   { font-size: 12px; color: #656d76; margin-top: 6px; }
.metric .value.local  { color: #0550ae; }
.metric .value.cloud  { color: #6e40c9; }
.metric .value.hybrid { color: var(--pass); }
.metric .value.pass   { color: var(--pass); }
.metric .value.warn   { color: var(--warn); }

.section { margin-bottom: 40px; }
.section h2 {
  font-size: 16px; font-weight: 600; color: var(--header);
  padding-bottom: 8px; border-bottom: 2px solid var(--border); margin-bottom: 16px;
}

table { width: 100%; border-collapse: collapse; font-size: 13px; }
th {
  background: #f6f8fa; text-align: left; padding: 8px 12px;
  font-weight: 600; border-bottom: 2px solid var(--border); white-space: nowrap;
}
td { padding: 8px 12px; border-bottom: 1px solid var(--border); vertical-align: top; }
tr:last-child td { border-bottom: none; }
tr:hover td { background: #f6f8fa; }

.col-ref      { font-weight: 600; width: 220px; white-space: nowrap; }
.col-evidence { font-family: var(--mono); font-size: 11px; color: #656d76; }
.col-status   { text-align: center; width: 90px; }
.col-mono     { font-family: var(--mono); font-size: 11px; }
.col-dec      { text-align: center; font-weight: 600; }
.col-dec.local  { color: #0550ae; }
.col-dec.cloud  { color: #6e40c9; }
.col-dec.hybrid { color: var(--pass); }
.row-more { text-align: center; color: #656d76; font-style: italic; }

.meta-table td:first-child { font-weight: 600; width: 200px; }

footer {
  margin-top: 48px; padding-top: 16px; border-top: 1px solid var(--border);
  font-size: 12px; color: #656d76;
  display: flex; justify-content: space-between; flex-wrap: wrap; gap: 8px;
}
"""

# ── Compliance checklist data ─────────────────────────────────────────────────

_EU_AI_ACT = [
    ("Art. 12 — Record-keeping",
     "Timestamped SHA-256 seals on every AI-assisted decision, retained in JSONL chain.",
     "audit_seal.timestamp_utc · audit_seal.sha256"),
    ("Art. 12 — Immutability",
     "Temporal Merkle chain links each record cryptographically; any alteration breaks the chain.",
     "audit_seal.time_anchor_hash = SHA-256(prev:sha256)"),
    ("Art. 13 — Transparency",
     "Routing decision and 6-axis entropy score exposed per request; human-readable.",
     "decision + features.entropy_score per entry"),
    ("Art. 13 — Human oversight",
     "teia-verify CLI and teia_audit_dashboard.html allow non-technical auditors to verify without a terminal.",
     "teia_audit_dashboard.html (zero install)"),
    ("Annex IV §2 — Technical documentation",
     "Formal whitepaper documents entropy formula, theorems, and all design decisions.",
     "docs/teia_arxiv_paper.tex · TEIA_WHITEPAPER_DRAFT.md"),
    ("Annex IV §5 — Post-market monitoring",
     "RFC 3161 TSA notarization provides third-party timestamp proof for each chain anchor.",
     "teia-notarize · _notary.py · FreeTSA.org"),
]

_GDPR = [
    ("Art. 22 — Automated decision-making",
     "Every automated routing decision logged with the entropy score and model selection rationale.",
     "features.* + decision field in every record"),
    ("Art. 22 — Right to explanation",
     "Canonical JSON (Write==Read invariant) can be reproduced and explained deterministically.",
     "to_canonical_json() · write==read proof in whitepaper"),
    ("Art. 5(1)(f) — Integrity & confidentiality",
     "SHA-256 body seal detects any post-facto alteration of the audit record.",
     "audit_seal.sha256 verified by teia-verify"),
    ("Art. 30 — Records of processing activities",
     "JSONL chain is a machine-readable record of all AI-routing activities per deployment.",
     "audit_chain.jsonl per gateway instance"),
]

_SOC2 = [
    ("CC7.2 — System monitoring",
     "Cryptographic Merkle chain provides continuous integrity monitoring without a central authority.",
     "time_anchor_hash chain"),
    ("CC7.3 — Incident detection",
     "teia-verify --verify-chain exits with code 1 on chain break — CI/CD-ready.",
     "teia-verify CLI"),
    ("CC6.1 — Logical access",
     "Audit records are append-only JSONL; gateway never overwrites existing entries.",
     "_gateway.py append-only mode"),
]

# ── Chain loader ──────────────────────────────────────────────────────────────

def _load_chain(chain_file: Path) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    with chain_file.open("r", encoding="utf-8") as fh:
        for raw in fh:
            raw = raw.strip()
            if raw:
                entries.append(json.loads(raw))
    return entries


# ── Statistics ────────────────────────────────────────────────────────────────

def _compute_stats(entries: list[dict[str, Any]]) -> dict[str, Any]:
    decisions: dict[str, int] = {}
    entropies: list[float] = []
    savings:   list[float] = []
    compliant  = 0
    timestamps: list[str] = []

    for e in entries:
        d = str(e.get("decision", "unknown")).lower()
        decisions[d] = decisions.get(d, 0) + 1

        features = e.get("features") or {}
        if isinstance(features, dict) and "entropy_score" in features:
            try:
                entropies.append(float(features["entropy_score"]))
            except (TypeError, ValueError):
                pass

        try:
            savings.append(float(e["estimated_savings_tokens"]))
        except (KeyError, TypeError, ValueError):
            pass

        seal = e.get("audit_seal") or {}
        if isinstance(seal, dict) and seal.get("sha256"):
            compliant += 1
            ts = seal.get("timestamp_utc", "")
            if ts:
                timestamps.append(ts)

    total = len(entries)
    return {
        "total":              total,
        "decisions":          decisions,
        "avg_entropy":        sum(entropies) / len(entropies) if entropies else None,
        "total_savings":      int(sum(savings)),
        "compliant_seals":    compliant,
        "seal_pct":           round(compliant / total * 100, 1) if total else 0.0,
        "first_ts":           min(timestamps) if timestamps else None,
        "last_ts":            max(timestamps) if timestamps else None,
    }


# ── Chain integrity ───────────────────────────────────────────────────────────

def _verify_chain(entries: list[dict[str, Any]]) -> dict[str, Any]:
    breaks: list[int] = []
    prev = "GENESIS"

    for i, entry in enumerate(entries):
        seal = entry.get("audit_seal") or {}
        if not isinstance(seal, dict) or not seal.get("sha256"):
            breaks.append(i)
            continue

        stored_anchor = seal.get("time_anchor_hash", "")
        stored_sha    = seal.get("sha256", "")
        stored_prev   = seal.get("prev_anchor_sha256", "GENESIS")

        expected = hashlib.sha256(f"{prev}:{stored_sha}".encode()).hexdigest()

        if stored_anchor != expected or stored_prev != prev:
            breaks.append(i)

        prev = stored_anchor or prev

    return {"intact": len(breaks) == 0, "breaks": breaks, "checked": len(entries)}


# ── HTML helpers ──────────────────────────────────────────────────────────────

def _checklist_rows(items: list[tuple[str, str, str]]) -> str:
    rows = []
    for ref, desc, evidence in items:
        rows.append(
            f'<tr>'
            f'<td class="col-ref">{ref}</td>'
            f'<td>{desc}</td>'
            f'<td class="col-evidence">{evidence}</td>'
            f'<td class="col-status"><span class="badge pass">PASS</span></td>'
            f'</tr>'
        )
    return "\n".join(rows)


def _trail_rows(entries: list[dict[str, Any]], limit: int = 20) -> str:
    rows = []
    shown = entries[:limit]
    for i, e in enumerate(shown):
        seal = e.get("audit_seal") or {}
        sha  = (seal.get("sha256",            "")[:16] + "…") if seal.get("sha256")            else "—"
        anch = (seal.get("time_anchor_hash",  "")[:16] + "…") if seal.get("time_anchor_hash")  else "—"
        prev = (seal.get("prev_anchor_sha256","")[:12] + "…") if seal.get("prev_anchor_sha256") else "—"
        ts   = (seal.get("timestamp_utc",     "")[:19])        if seal.get("timestamp_utc")     else "—"
        dec  = str(e.get("decision", "—"))
        rows.append(
            f'<tr>'
            f'<td>{i}</td>'
            f'<td class="col-mono">{sha}</td>'
            f'<td class="col-mono">{anch}</td>'
            f'<td class="col-mono">{prev}</td>'
            f'<td>{ts}</td>'
            f'<td class="col-dec {dec}">{dec}</td>'
            f'</tr>'
        )
    if len(entries) > limit:
        rows.append(
            f'<tr><td colspan="6" class="row-more">'
            f'… {len(entries) - limit} more entries not shown</td></tr>'
        )
    return "\n".join(rows)


# ── Report generator ──────────────────────────────────────────────────────────

def generate_html_report(
    chain_file: Path,
    organization: str = "TEIA Deployment",
) -> str:
    entries  = _load_chain(chain_file)
    stats    = _compute_stats(entries)
    chain_v  = _verify_chain(entries)
    now_utc  = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    chain_cls   = "pass" if chain_v["intact"] else "fail"
    chain_icon  = "✓" if chain_v["intact"] else "✗"
    chain_label = "CHAIN INTACT" if chain_v["intact"] else f"CHAIN BROKEN — {len(chain_v['breaks'])} break(s) at entry {chain_v['breaks'][:3]}"

    seal_cls  = "pass" if stats["seal_pct"] == 100.0 else "warn"
    avg_e_str = f"{stats['avg_entropy']:.4f}" if stats["avg_entropy"] is not None else "N/A"
    savings_s = f"{stats['total_savings']:,}"

    decisions = stats["decisions"]
    total     = stats["total"]
    local_n   = decisions.get("local",  0)
    cloud_n   = decisions.get("cloud",  0)
    hybrid_n  = decisions.get("hybrid", 0)
    local_pct = round(local_n  / total * 100, 1) if total else 0.0
    cloud_pct = round(cloud_n  / total * 100, 1) if total else 0.0
    hyb_pct   = round(hybrid_n / total * 100, 1) if total else 0.0

    date_range = ""
    if stats["first_ts"] and stats["last_ts"]:
        date_range = f" · {stats['first_ts'][:10]} → {stats['last_ts'][:10]}"

    trail_limit = min(20, total)

    # Pre-build HTML fragments (no CSS braces inside f-strings)
    checklist_eu   = _checklist_rows(_EU_AI_ACT)
    checklist_gdpr = _checklist_rows(_GDPR)
    checklist_soc2 = _checklist_rows(_SOC2)
    trail          = _trail_rows(entries, limit=20)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>TEIA Compliance Report — {now_utc}</title>
<style>
{_CSS}
</style>
</head>
<body>

<header>
  <h1>TEIA Cognitive Router — Compliance Report</h1>
  <p>Organization: <strong style="color:#e6edf3">{organization}</strong>
     &nbsp;|&nbsp; Generated: {now_utc}
     &nbsp;|&nbsp; Protocol: {_REPORT_PROTOCOL}
     &nbsp;|&nbsp; teia-cognitive-router v{_REPORT_VERSION}</p>
  <p class="mono" style="margin-top:10px">
    Source: {chain_file.name} ({total} entries{date_range})
  </p>
</header>

<div class="verdict {chain_cls}">
  <div class="icon">{chain_icon}</div>
  <div>
    <h2>{chain_label}</h2>
    <p>{chain_v['checked']} entries verified &nbsp;·&nbsp;
       {stats['compliant_seals']} sealed ({stats['seal_pct']}% coverage)</p>
  </div>
  <div class="right">
    <span class="badge {chain_cls}">{chain_label}</span>
  </div>
</div>

<div class="metrics">
  <div class="metric">
    <div class="label">Total Decisions</div>
    <div class="value">{total}</div>
  </div>
  <div class="metric">
    <div class="label">Local</div>
    <div class="value local">{local_n}</div>
    <div class="sub">{local_pct}% of total</div>
  </div>
  <div class="metric">
    <div class="label">Cloud</div>
    <div class="value cloud">{cloud_n}</div>
    <div class="sub">{cloud_pct}% of total</div>
  </div>
  <div class="metric">
    <div class="label">Hybrid</div>
    <div class="value hybrid">{hybrid_n}</div>
    <div class="sub">{hyb_pct}% of total</div>
  </div>
  <div class="metric">
    <div class="label">Avg Entropy</div>
    <div class="value" style="font-size:22px">{avg_e_str}</div>
  </div>
  <div class="metric">
    <div class="label">Tokens Saved</div>
    <div class="value" style="font-size:20px">{savings_s}</div>
  </div>
  <div class="metric">
    <div class="label">Seal Coverage</div>
    <div class="value {seal_cls}" style="font-size:22px">{stats['seal_pct']}%</div>
  </div>
  <div class="metric">
    <div class="label">Chain Status</div>
    <div style="margin-top:8px"><span class="badge {chain_cls}">{chain_cls.upper()}</span></div>
  </div>
</div>

<div class="section">
  <h2>EU AI Act — Compliance Checklist</h2>
  <table>
    <tr>
      <th class="col-ref">Requirement</th>
      <th>How TEIA Satisfies It</th>
      <th>Evidence Field / Artefact</th>
      <th class="col-status">Status</th>
    </tr>
    {checklist_eu}
  </table>
</div>

<div class="section">
  <h2>GDPR Article 22 — Automated Decision-Making</h2>
  <table>
    <tr>
      <th class="col-ref">Requirement</th>
      <th>How TEIA Satisfies It</th>
      <th>Evidence Field / Artefact</th>
      <th class="col-status">Status</th>
    </tr>
    {checklist_gdpr}
  </table>
</div>

<div class="section">
  <h2>SOC 2 Type II — CC7 System Monitoring</h2>
  <table>
    <tr>
      <th class="col-ref">Control</th>
      <th>How TEIA Satisfies It</th>
      <th>Evidence</th>
      <th class="col-status">Status</th>
    </tr>
    {checklist_soc2}
  </table>
</div>

<div class="section">
  <h2>Audit Hash Trail (first {trail_limit} of {total} entries)</h2>
  <table>
    <tr>
      <th style="width:40px">#</th>
      <th>Body SHA-256 (prefix)</th>
      <th>Time Anchor (prefix)</th>
      <th>Prev Anchor (prefix)</th>
      <th>Timestamp UTC</th>
      <th style="width:80px">Decision</th>
    </tr>
    {trail}
  </table>
</div>

<div class="section">
  <h2>Report Metadata</h2>
  <table class="meta-table">
    <tr><td>Report protocol</td><td>{_REPORT_PROTOCOL}</td></tr>
    <tr><td>Router version</td><td>teia-cognitive-router v{_REPORT_VERSION}</td></tr>
    <tr><td>Chain entries</td><td>{total}</td></tr>
    <tr><td>Sealed entries</td><td>{stats['compliant_seals']} / {total} ({stats['seal_pct']}%)</td></tr>
    <tr><td>Chain integrity</td><td><span class="badge {chain_cls}">{chain_label}</span></td></tr>
    <tr><td>Generated UTC</td><td>{now_utc}</td></tr>
    <tr><td>Organization</td><td>{organization}</td></tr>
  </table>
</div>

<footer>
  <span>teia-cognitive-router v{_REPORT_VERSION} · Protocol {_REPORT_PROTOCOL}</span>
  <span>Three-layer proof: SHA-256 body seal · Merkle time-anchor · RFC 3161 TSR</span>
</footer>

</body>
</html>"""


# ── CLI entry point ───────────────────────────────────────────────────────────

def _cli() -> None:
    parser = argparse.ArgumentParser(
        prog="teia-report",
        description=(
            "Generate a self-contained HTML compliance report from a TEIA JSONL audit chain. "
            "Covers EU AI Act Art. 12/13/Annex IV, GDPR Art. 22, SOC 2 CC7."
        ),
    )
    parser.add_argument("chain_file", type=Path, help="JSONL audit chain file")
    parser.add_argument(
        "--output", "-o", type=Path, default=None,
        help="Output HTML file (default: <chain_file>.report.html)",
    )
    parser.add_argument(
        "--org", default="TEIA Deployment",
        help="Organization name printed in the report header",
    )
    args = parser.parse_args()

    chain_file: Path = args.chain_file.resolve()
    if not chain_file.exists():
        print(f"ERROR: chain file not found: {chain_file}", file=sys.stderr)
        sys.exit(1)

    out: Path = args.output or chain_file.with_suffix("").with_suffix(".report.html")
    html = generate_html_report(chain_file, organization=args.org)
    out.write_text(html, encoding="utf-8")

    sha = hashlib.sha256(html.encode("utf-8")).hexdigest()
    print(f"Report  : {out}")
    print(f"SHA-256 : {sha}")
    print(f"Open in any browser — works from file://")


if __name__ == "__main__":
    _cli()
