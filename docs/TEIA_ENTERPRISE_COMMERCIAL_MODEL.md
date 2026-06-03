# TEIA Cognitive Router — Enterprise Commercial Model

**Protocol P50.0 | Open-Core Strategy | 2026-06-02**

---

## Executive Summary

TEIA Cognitive Router is a **deterministic, compliance-first LLM routing engine** that routes AI prompts to the cheapest tier capable of handling them without quality degradation — using a fixed 6-axis heuristic formula with cryptographically sealed audit trails.

The commercial model is **Open-Core**:

- The **routing engine, local audit chain, and gateway** are free and open (Apache 2.0)
- The **compliance automation layer** — continuous RFC 3161 notarization, multi-tenant audit dashboards, SSO/RBAC, and regulator-formatted reports — is a paid commercial product

The open layer drives adoption. The commercial layer captures value from the regulated industries (fintech, healthcare, government) that **require** the closed features to pass audits.

---

## What Is Open (Apache 2.0 — Free Forever)

| Component | What it Does | Why It's Open |
|---|---|---|
| **6-Axis Semantic Entropy Router** | Routes prompts to Local / Hybrid / Cloud based on deterministic math | Drives adoption, referenceability, academic citation |
| **Cryptographic Audit Seal** | SHA-256 body hash on every routing decision — same input, same hash, always | Establishes trust baseline; auditors can self-verify |
| **Temporal Chain (Merkle Ledger)** | Links each decision to the previous: `SHA-256(prev:body_sha256)` | Proves the log is append-only; detectable tampering |
| **teia-verify CLI** | Verifies document seals and full temporal chains from the command line | Allows compliance officers to audit without vendor dependency |
| **Deterministic LLM Gateway** | FastAPI proxy that routes every OpenAI-compatible request and logs the chain | Drop-in infrastructure for any LLM stack |
| **PyPI package** | `pip install teia-cognitive-router` — 0 dependencies, < 5 MB | Low friction onboarding; no sales touch required |
| **RFC 3161 Notary Script** | `teia_rfc3161_notary.py` — submits any anchor hash to a free TSA | Proves existence of timestamp; customers own the proof |

**License**: Apache 2.0 — use, modify, redistribute, embed in commercial products.

---

## What Is Closed (Commercial License — Paid)

The commercial product is **TEIA Compliance Shield** — the layer that turns raw audit data into regulator-readable evidence packages without requiring manual OpenSSL expertise or custom tooling.

### Tier 1 — Compliance Shield Professional

**Target**: Engineering teams at regulated companies (fintech, health-tech, insurtech)
**Pricing**: $299 / seat / month or $2,500 / seat / year

| Feature | Description |
|---|---|
| **Continuous RFC 3161 Notarization** | Automatic submission of every `time_anchor_hash` to a TSA after each routing decision — no manual script invocation required |
| **Notarization Ledger UI** | Web dashboard showing every notarized anchor: timestamp, hash, TSR download, chain position |
| **Chain Integrity Monitor** | Continuous background verification of the temporal chain; alerts on gap or tamper detection |
| **Single Sign-On (SSO)** | SAML 2.0 / OIDC integration (Okta, Azure AD, Google Workspace) |
| **Role-Based Access Control (RBAC)** | Separate roles for engineers (read-write), auditors (read-only), compliance officers (report export) |

### Tier 2 — Compliance Shield Enterprise

**Target**: Legal/compliance teams at financial institutions, health systems, government contractors
**Pricing**: $1,200 / seat / month or $10,000 / seat / year (minimum 3 seats)

Includes everything in Professional, plus:

| Feature | Description |
|---|---|
| **EU AI Act Report Generator** | Automated generation of Annex IV technical documentation for high-risk AI systems — routing rationale, decision reproducibility proof, risk classification |
| **SOC 2 Type II Evidence Package** | Pre-formatted audit evidence export: routing logs, seal verification proofs, access logs — maps directly to SOC 2 CC6/CC7 controls |
| **HIPAA Audit Controls Package** | PHI locality proof (prompts never leave local process), access control logs, minimum-necessary routing evidence |
| **SEC/FINRA Algorithmic Accountability Report** | SHA-256-anchored decision log in SEC-standard format; demonstrates that routing decisions are reproducible and explainable |
| **Multi-Tenant Dashboard** | Isolated audit workspaces per department / legal entity; consolidated executive view |
| **Dedicated Onboarding + SLA** | 4-hour response SLA; dedicated Slack channel; compliance engineer onboarding session |

### Tier 3 — OEM / Embedded License

**Target**: LLM platform vendors, cloud providers, compliance software companies embedding TEIA in their product
**Pricing**: Custom — revenue share or flat annual fee, negotiated per deal

| Feature | Description |
|---|---|
| **White-label routing engine** | Ship TEIA under your brand in your product |
| **Custom compliance report templates** | Co-developed report formats for your customers' regulatory frameworks |
| **Source access to commercial modules** | Under escrow agreement |
| **Priority roadmap influence** | Quarterly roadmap sessions; named features in release notes |

---

## Pricing Rationale

### Market Reference Points

| Comparable Product | Category | Pricing |
|---|---|---|
| Datadog APM | Observability SaaS | $31 / host / month |
| Vanta (SOC 2 automation) | Compliance SaaS | $12,000–$25,000 / year |
| OneTrust (GDPR/AI governance) | Compliance SaaS | $50,000–$200,000 / year |
| LlamaIndex Enterprise | LLM infrastructure | Custom, ~$50k–$200k / year |
| Arize AI (LLM observability) | AI governance | Custom, ~$30k–$150k / year |

### TEIA's Value Wedge

TEIA's pricing sits **below compliance software** (Vanta/OneTrust) because TEIA is scoped to AI routing governance only — not full GRC. It sits **above pure infrastructure** (Datadog) because the output is regulator-facing evidence, not just metrics.

A single failed EU AI Act audit at a regulated EU company costs **€15,000–€100,000** in remediation (legal fees, consulting, operational delays). TEIA Compliance Shield Enterprise at $10,000/seat/year has a 10x–100x ROI on audit failure prevention alone.

---

## Go-To-Market Strategy

### Phase 1 — Pilot Acquisition (Month 1–3)

**Objective**: Sign 3–5 paying pilot customers at $0 (design partners) or $500–$1,000/month (early adopter discount).

**Target profile**: Engineering or compliance lead at a Series B+ fintech, health-tech, or insurtech company that:
- Already uses GPT-4 or another frontier LLM in production
- Has received or anticipates a compliance inquiry about AI governance
- Does not yet have an LLM routing or audit trail solution

**Channels**:
- Direct outreach via LinkedIn to Head of Compliance / VP Engineering at 50 target companies
- Conference presence: Fintech Meetups, HIMSS (healthcare IT), RSA Conference
- Content marketing: publish "How to pass an EU AI Act audit for LLM systems" on Substack / Medium

**Pilot deliverable**: Working integration of TEIA in their LLM stack + one formatted compliance report. Pilot success = they can show the report to their compliance team and it's accepted.

### Phase 2 — Product-Led Growth (Month 3–12)

**Objective**: Convert PyPI downloads (open-source users) into paying customers via in-product upgrade prompts.

- Add upgrade CTA to `teia-verify` CLI output when a user verifies a large chain: `"Automate this verification with TEIA Compliance Shield — https://teia.dev/compliance"`
- Add GitHub Sponsors / Ko-fi for individual developers
- Publish case study from pilot customers (anonymized if required)

### Phase 3 — OEM Partnership (Month 6–18)

**Objective**: Embed TEIA in one LLM infrastructure platform (LangChain, LlamaIndex, or a cloud provider's AI safety toolkit).

- Approach LangSmith (LangChain), Arize, or a cloud provider's AI safety team
- Offer OEM license: they white-label TEIA's routing + compliance layer; revenue share 15–25%

---

## Defensibility

| Moat | Description |
|---|---|
| **Temporal chain lock-in** | Once a customer's audit ledger is built with TEIA's chain, migrating to a different routing system breaks the chain continuity — a switching cost |
| **Regulator familiarity** | Compliance officers become familiar with TEIA's report format; switching means re-educating their auditors |
| **Formula stability guarantee** | TEIA's routing formula is version-pinned (P40.0). This is a unique promise no ML router can make. Customers who build compliance programs around it cannot easily swap it out |
| **Open core trust** | The core router is Apache 2.0 and inspectable. Enterprise customers can verify that no hidden telemetry or backdoor exists in the routing logic — a trust signal that proprietary competitors cannot match |

---

## What TEIA Does NOT Sell

- LLM inference (we route to your LLMs; we don't run them)
- General GRC / SOC 2 automation (scoped to AI routing governance only)
- Data labeling, model training, or fine-tuning
- Legal advice (reports are "audit-ready evidence packages"; legal review remains with the customer)

---

*TEIA Cognitive Router | Protocol P50.0 | Open-Core Commercial Model | 2026-06-02*
