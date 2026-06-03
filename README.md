# TEIA — Information Economics Engine

**Storage as Computation · Cognitive Routing · Entropy-Honest Decision Making**

> *"TEIA is not always the best format.*
> *TEIA is the system that discovers which format must win."*

**Latest release:** [v19.0.0-policy-engine](https://github.com/felippebarcelos/teia-omega-awakening/releases/tag/v19.0.0-policy-engine) — Routing Policy Engine · Hard Compliance Rules · Deterministic policy_seal · teia-policy CLI · P54.0

---

## The Problem: Structured Data Dominates Storage Costs

In modern data centers and Big Data pipelines, **70-85% of stored data is structured or
semi-structured** — logs, telemetry, event streams, time-series metrics, database exports.
These datasets share a critical property: they carry massive internal redundancy across files.

Conventional compressors (Brotli, LZMA, Zstd) treat each file in isolation. They cannot
exploit the grammar shared across thousands of homogeneous CSV files because they see
each file as an independent byte stream. The result: disk costs scale linearly with data
volume, even when the information content grows much more slowly.

**TEIA solves this by treating storage as computation.**

---

## What TEIA Does

TEIA is an **Information Economics Engine** that extracts a shared Master Grammar from a
corpus of homogeneous structured files, then stores each file as a compact `seed.bin` —
a minimal residual that can be deterministically reconstructed by executing the grammar.

The core insight: for N files sharing the same schema, the grammar overhead is a **fixed
one-time cost**. As N grows, that overhead is amortized across more files, and each file
occupies progressively fewer bytes on disk while remaining fully recoverable with O(1)
random access.

### Storage as Computation

A TEIA archive is not a compressed blob — it is a **program**:

```
original_file = TeiaMasterDecoder.Decode(schema, dict_columns, seed.bin)
```

The disk stores code (Master Grammar + C# JIT decoder) and parameters (seed.bin).
Reconstruction is execution, not decompression. As N → ∞, the overhead per file → 0.

---

## Architecture: Four Operational Layers

```
┌─────────────────────────────────────────────────────────────────┐
│  Layer 4 — Cognitive Router (P40.0) · Python v9.0.0             │
│  Semantic Entropy analysis of AI prompts → Local/Hybrid/Cloud   │
│  15k prompts/sec · SHA-256 audit logs · zero network calls      │
│  Integration-ready: vLLM / Kubernetes / LiteLLM / OpenAI        │
├─────────────────────────────────────────────────────────────────┤
│  Layer 3 — NStar Predictor (P39.0)                              │
│  Heuristic lens: reads sample, predicts N* in milliseconds      │
│  No compression · No file modification · Canonical JSON output  │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2 — Adaptive Archive Router (P36.0)                      │
│  Measures 3 candidates with real Brotli compression             │
│  Scores by objective (Size / Latency / Balanced)                │
│  Projects N* = ceil(overhead / delta_per_file) exactly          │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1 — AION Transversal Motor (P33.0)                       │
│  Master Grammar extraction across N uniform-schema CSV files    │
│  Per-file seed.bin + shared decoder compiled by C# JIT          │
│  Random access: O(1) · Incremental update: O(1)                 │
└─────────────────────────────────────────────────────────────────┘
```

### The Three Routing Candidates

| Candidate | Mechanism | Access | Incremental |
|---|---|:---:|:---:|
| **TEIA (AION)** | Master Grammar + C# JIT decoder | O(1) | O(1) |
| **Brotli/file** | Each file compressed individually | O(1) | O(1) |
| **Concat+Brotli** | Corpus concatenated + single Brotli | **O(N)** | **O(N)** |

### The Three Business Objectives

| Objective | Size Weight | Access Weight | Incremental Weight |
|---|:---:|:---:|:---:|
| `Size` | 100% | 0% | 0% |
| `Latency` | 0% | 70% | 30% |
| `Balanced` | 35% | 40% | 25% |

---

## Entropy Honesty — The Fundamental Principle

TEIA is the only engine that knows when to retreat.

| Scenario | Decision | Reason |
|---|---|---|
| Binaries · media · already-compressed | **Pass-Through** | Compressing compressed data wastes CPU |
| Zero dict columns (pure random data) | **Pass-Through** | No grammar possible |
| N < N\* (corpus too small) | **Brotli/file** | Overhead not yet amortized |
| N >= N\*, Balanced objective | **TEIA** | Grammar amortized + O(1) access |
| Any objective, any N | **Concat+Brotli** never wins on Latency | O(N) penalty grows with corpus |

> A Routing decision that selects Brotli or Pass-Through is not a TEIA failure —
> it is the system making the economically correct call.

---

## Benchmark Results — P38.0 Multi-Domain (Real + Synthetic Corpora)

All results measured with real `CompressionLevel.SmallestSize` Brotli compression.
N = 30 files per corpus. Access latency: O(1) for TEIA and Brotli/file in all cases.

### Decision Table — Balanced Objective

| Domain | Dict Density | N\* Measured | Winner (Balanced) | Access |
|---|:---:|:---:|:---:|:---:|
| Time-Series Metrics (srv/svc) | 71% | **9** | **TEIA** | O(1) |
| Apache CLF Logs (synthetic) | 67% | **12** | **TEIA** | O(1) |
| Apache CLF Logs (real) | 67% | **15** | Brotli (N<15) | O(1) |
| Source Code Commits | 43% | **9** | **TEIA** | O(1) |
| High Entropy (control) | 0% | 1489 | Brotli | O(1) |

### Key Finding: N\* is Determined by Two Variables

N\* is not solely a function of dict column density. The **compressibility of residual
columns** (format structure in hex strings, ISO-8601 timestamps, sequential IDs) is equally
deterministic. Source code commits achieve N\*=9 despite only 43% dict density because
their residual data (commit hashes, timestamps) has exploitable format structure.

**Refinement of H-01:** N\* scales with dict_density × residual_compressibility,
not with dict_density alone.

### P36.0 Real-Corpus Results (Apache CLF, N=10 files)

| Metric | TEIA | Brotli/file | Concat+Brotli |
|---|---:|---:|---:|
| Total size | 100.0 KB | 98.7 KB | **73.8 KB** |
| Random access latency | 1 ms | **0 ms** | 1 ms (O(N)) |
| Incremental update | 195 ms | **124 ms** | 1560 ms (O(N)) |
| **Balanced score** | 0.357 | **0.332** | 0.650 |

*N\*=15 for this corpus: at N>=15, TEIA wins even in size.*

---

## Cognitive Router — Quick Start (Python, v9.0.0)

No dependencies beyond Python 3.8+ stdlib.

```bash
# Route a single prompt
python tools/teia_cognitive_router.py --text "List all files in this directory"
# → { "routing_decision": "Local", "semantic_entropy_score": 0.15, ... }

python tools/teia_cognitive_router.py \
  --text "Analyze root cause of this distributed outage across 6 services" \
  --output result.json
# → VERDICT: Cloud | entropy: 0.72 | SHA-256 audit seal attached

# 100-prompt MT-Bench/AlpacaEval scale benchmark
python tools/run_router_benchmark.py
# → 15,361 prompts/sec · 98.4% savings · USD 230/mo projected
```

```python
from teia_cognitive_router import route_and_seal

sealed, json_str = route_and_seal("Extract all dates from this document")
print(sealed["routing_decision"])          # Local
print(sealed["gpu_economics"]["delta_usd_saved"])  # 0.000440
print(sealed["audit_seal"]["sha256"])      # deterministic SHA-256
```

### Audit Verifier — For Compliance Officers

Prove that any stored routing decision is mathematically reproducible and untampered:

```bash
# Verify document seal (integrity check)
python tools/teia_audit_verifier.py --file routing_result.json

# Full determinism proof: re-run the math from the original prompt
python tools/teia_audit_verifier.py \
  --file routing_result.json \
  --text "Your original prompt text"
# → AUDIT PASS: The routing decision is mathematically proven and unmodified.

# Run any public benchmark dataset locally (MT-Bench, RouterBench, generic JSON)
python tools/teia_router_bench_harness.py --input mt_bench_questions.json
```

---

## Storage Router — Quick Start (PowerShell)

### Prerequisites
- PowerShell 7+
- Windows (WinFsp optional for virtual filesystem features)
- Internet connection (for real Apache CLF corpus download)

### Run the Adaptive Router Audit (1 Click)

```powershell
git clone https://github.com/felippebarcelos/teia-omega-awakening.git
cd teia-omega-awakening

# Full 6-permutation audit: 2 corpora × 3 objectives (~2 minutes)
pwsh -ExecutionPolicy Bypass -File .\release\adaptive_router_v6\audit-one-click-router.ps1
```

### Predict N\* for Your Corpus (Instant, No Compression)

```powershell
# Heuristic prediction in milliseconds — no files modified
pwsh -ExecutionPolicy Bypass -File .\tools\TEIA-NStar-Predictor.ps1 `
     -InputPath "D:\your\csv\directory" `
     -OutputJson "nstar_prediction.json"
```

### Audit a Real-World Directory (Dry-Run)

```powershell
# Classifies all files into Zone A/B/C, projects routing, generates idempotent manifest
pwsh -ExecutionPolicy Bypass -File .\tools\Run-TeiaRealWorldAudit.ps1 `
     -TargetDirectory "D:\your\logs\directory"
```

### Multi-Domain Benchmark (4 Domains × 3 Objectives)

```powershell
# Validates H-01 (Dict Density vs N*) across divergent corpora
pwsh -ExecutionPolicy Bypass -File .\tools\Benchmark-MultiDomain.ps1
```

### Verify Release Integrity

```powershell
(Get-FileHash .\release\TEIA_ADAPTIVE_ARCHIVE_ROUTER_v6.0.0.zip -Algorithm SHA256).Hash.ToLower()
# Expected: 7f6732a218eb260f2f3c73ef29982fdcfeb073bd47e42334721210b99c031069
```

---

## Tool Reference

### Python (v10.0.0 — vLLM / Kubernetes / LiteLLM ready)

| Script | Purpose | Output |
|---|---|---|
| `teia_cognitive_router.py` | Semantic Entropy routing for AI prompts · SHA-256 audit seal | canonical JSON |
| `run_router_benchmark.py` | 100-prompt MT-Bench/AlpacaEval benchmark · GPU economics | `benchmark_results.json` |
| `run_quality_cost_benchmark.py` | Cost vs Quality benchmark · 3 tiers · deterministic quality model | `quality_cost_results.json` |
| `teia_router_bench_harness.py` | Public benchmark harness · accepts MT-Bench/RouterBench/generic JSON · offline | `public_benchmark_evaluation.json` |
| `teia_audit_verifier.py` | **Cryptographic audit verifier** · proves routing decision is mathematically unmodified · exit 0/1 | `AUDIT PASS / FAIL` |

### PowerShell

| Script | Purpose | Output |
|---|---|---|
| `TEIA-Cognitive-Router.ps1` | Cognitive routing (PowerShell, P40.0) | canonical JSON |
| `Run-CognitiveEconomicValidation.ps1` | P41.0 dogfooding validation | routing table + USD savings |
| `TEIA-AION-Transversal.ps1` | Master Grammar extraction + C# JIT forging | seeds + decoder |
| `TEIA-Archive-Router.ps1` | 3-candidate router with real compression | routing decision + N\* |
| `TEIA-NStar-Predictor.ps1` | Heuristic N\* prediction without compression | canonical JSON |
| `Run-TeiaRealWorldAudit.ps1` | Dry-run audit of real directories | idempotent JSON manifest |
| `Benchmark-MultiDomain.ps1` | 4-domain × 3-objective benchmark | markdown report |
| `audit-one-click-router.ps1` | 1-click full audit orchestrator | decision table |

---

## The N\* Formula

The critical mass N\* is the number of files at which TEIA's overhead is amortized
and each file occupies fewer bytes than its Brotli-compressed equivalent:

```
TEIA_total(N)   = overhead_fixed + N × seed_average
Brotli_total(N) = N × brotli_average

N* = ceil(overhead_fixed / (brotli_average minus seed_average))
```

When `N >= N*`, TEIA wins on disk size. When combined with O(1) access and O(1) incremental
updates, TEIA dominates on the Balanced objective for any sufficiently large corpus.

**Heuristic estimation (NStar Predictor, calibrated on P36/P38 empirical data):**

```
brotli_ratio    = 0.021 + 0.52 × mean_column_entropy
delta_per_file  = brotli_per_file × dict_density × (0.040 + 0.050 × residual_entropy)
N*              = ceil(overhead / delta_per_file)
```

Calibration accuracy:
- Apache CLF real (N\*=15): predicted delta=279 B vs measured 270 B — error < 4%
- Corpus30 synthetic (N\*=10): predicted delta=597 B vs measured 590 B — error < 2%

---

## Technical Documentation

| Document | Protocol | Description |
|---|---|---|
| [Python Integration Guide](docs/TEIA_PYTHON_INTEGRATION_GUIDE.md) | P42.0 | vLLM / K8s / LiteLLM integration · Compliance-first routing |
| [P41.0 Economics Proof](docs/TEIA_P41_COGNITIVE_ECONOMICS_PROOF.md) | P41.0 | Empirical GPU savings — sealed by SHA-256 |
| [Cognitive Routing Theory](docs/TEIA_COGNITIVE_ROUTING_THEORY.md) | P40.0 | Ontoprocedural Ontogenesis applied to AI inference |
| [Release Notes v7.0.0](docs/TEIA_RELEASE_NOTES_v7.0.0_ECONOMICS_ENGINE.md) | P39.0 | Information Economics Engine — The Awakening |
| [Release Notes v6.0.0](docs/TEIA_RELEASE_NOTES_v6.0.0_ROUTER.md) | P37.0 | Adaptive Archive Router |
| [Adaptive Router Report P36.0](docs/TEIA_ADAPTIVE_ROUTER_REPORT_P36.md) | P36.0 | 6-permutation audit with real Apache CLF |
| [Multi-Domain Benchmark P38.0](docs/TEIA_MULTIDOMAIN_BENCHMARK_REPORT.md) | P38.0 | N\* across 4 divergent domains |
| [Research Frontier](TEIA_RESEARCH_FRONTIER.md) | P38.0 | Active hypotheses and future experiments |
| [Dogfooding Protocol](docs/TEIA_DOGFOODING_PROTOCOL.md) | P38.1 | Protocol for real-world entropy testing |

---

## Version Evolution

| Version | Paradigm | Central Result |
|---|---|---|
| v1.3.0 | Procedural Compressor | COVID data: +58.7% vs Brotli Optimal |
| v4.0.0 | Gatekeeper Oracle | Zero negative deltas guaranteed |
| v5.0.0 | O(1) Archive Format | 43x faster access · 42.7x faster incremental · C# JIT |
| v6.0.0 | Adaptive Supervisor | 6/6 honest verdicts · N\* projected mathematically |
| v7.0.0 | Information Economics Engine | Heuristic N\* prediction · Multi-domain P38.0 · Real-world audit |
| v8.0.0 | Cognitive Economics Engine | Semantic Entropy routing · GPU-seconds savings · P41.0 dogfooding |
| v9.0.0 | Python Port + Scale Benchmark | 15,361 prompts/sec · 98.4% GPU cost reduction · vLLM/K8s/LiteLLM ready |
| v10.0.0 | Cost vs Quality Benchmark | Honest 3-tier quality model · compliance language corrected · P43.0 |
| v11.0.0 | Cryptographic Audit Verifier | SHA-256 routing proofs · public benchmark harness · compliance-grade determinism |
| v12.0.0 | Enterprise Spin-Off | Clean Python package · zero philosophy · vLLM/LiteLLM drop-in · compliance-first README · P45.0 |
| v13.0.0 | PyPI + Deterministic Gateway | `pip install teia-cognitive-router` · FastAPI proxy · SHA-256 audit JSONL · P46.0–P47.0 |
| v14.0.0 | Compliance-Safe Mode | MT-Bench 99.6% quality retention · compliance_safe default · GRC-ready branding · P48.0 |
| v15.0.0 | Cryptographic Time Chain | Merkle-chained audit ledger · time_anchor_hash per decision · RFC 3161 foundation · teia-verify --verify-chain · P49.0 |
| v16.0.0 | Open-Core Transition | RFC 3161 notary script · Open-Core commercial model doc · arXiv whitepaper draft · go-to-market · P50.0 |
| v17.0.0 | Enterprise Audit Dashboard | Self-contained HTML audit UI · LaTeX whitepaper compiler · Zenodo DOI instructions · pure-JS SHA-256 · P52.0 |
| v18.0.0 | Compliance Report Generator | teia-report CLI · HTML compliance report from JSONL · EU AI Act Art.12/13 · GDPR Art.22 · SOC 2 CC7 · P53.0 |
| **v19.0.0** | **Routing Policy Engine** | **teia-policy CLI · enforce() API · JSON policy rules · HIPAA/GDPR/SOC2 overrides · deterministic policy_seal · P54.0** |

---

## Design Invariants

All scripts in this repository enforce the following invariants:

- **Idempotence (Write==Read):** every script is safe to re-execute; same inputs produce identical outputs including SHA-256 hashes
- **Delta by name:** the word "delta" is always written out in full in all code, comments, and documentation — the mathematical symbol is prohibited to prevent parser corruption
- **Absolute paths:** all file operations use absolute paths; never relative execution from system directories
- **UTF-8 without BOM:** all generated text files use UTF-8 encoding without byte-order mark
- **Entropy Honesty:** the router never forces TEIA on incompressible data; every Brotli or Pass-Through verdict is declared a correct system decision

---

## License

Research prototype. All scripts are provided as-is for reproducibility of results.
See individual files for usage instructions.

---

*TEIA Information Economics Engine v19.0.0 | Protocol P54.0 | 2026-06-03*
*Built on hardware: i3-10100F · 16 GB RAM · PowerShell 7+ · Python 3.8+ · WinFsp*
*"Ferrari di papelão — using code efficiency to overcome silicon constraints."*
