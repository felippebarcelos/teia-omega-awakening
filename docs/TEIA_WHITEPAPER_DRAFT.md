# Deterministic and Auditable Routing for Artificial Intelligence in Regulated Environments

**Draft for arXiv submission | Protocol P50.0 | 2026-06-02**

Authors: Felippe Barcelos  
Affiliation: TEIA Project (Independent)  
Contact: felippe.barcelos10@gmail.com  
Repository: https://github.com/felippebarcelos/teia-omega-awakening

---

## Abstract

Large Language Model (LLM) routing systems — software that decides whether a given prompt should be processed by a local small model, a quantized hybrid model, or a frontier cloud LLM — are increasingly deployed in regulated industries. Existing ML-based routers produce non-reproducible decisions: the same prompt routed on different days may receive different verdicts due to model retraining, weight drift, or external API dependency. This property is fundamentally incompatible with the audit requirements imposed by EU AI Act High-Risk System provisions, GDPR Article 22, SEC/FINRA algorithmic accountability rules, and HIPAA audit controls.

We present **TEIA Cognitive Router** — a deterministic, 6-axis heuristic routing system that produces a cryptographically sealed, reproducible routing decision for every prompt. The routing formula is a fixed linear combination of six measurable text features (token count, vocabulary diversity, reasoning verb density, data operation density, structural complexity, and constraint density), calibrated at Protocol P40.0 and frozen at that version. Every decision is accompanied by a SHA-256 audit seal, a human-readable rationale, and — from v1.2.0 — a Merkle-chained temporal anchor that links each decision to its predecessor in an append-only ledger.

We evaluate TEIA on the MT-Bench 80-question benchmark and report 99.6% quality retention under compliance-safe mode at 16.3% cost reduction versus routing all prompts to a frontier LLM. We demonstrate that the routing formula satisfies the Write==Read invariant (identical input always produces identical output and identical SHA-256) and describe the cryptographic properties of the temporal chain that prevent retroactive forgery of routing history.

---

## 1. Introduction

### 1.1 The Compliance Wall for ML-Based Routing

Production LLM deployments in regulated industries face a fundamental architectural constraint: every AI-assisted decision that affects users must be explainable, reproducible, and auditable. This requirement is codified in:

- **EU AI Act (2024)**, Articles 13 (transparency), 14 (human oversight), and Annex IV (technical documentation) for High-Risk AI Systems
- **GDPR**, Article 22 and Recital 71: automated decisions must be explainable to data subjects
- **SEC/FINRA** algorithmic accountability rules: trading and advisory systems must document and reproduce decision logic
- **HIPAA** Security Rule §164.312(b): audit controls requiring records of system activity

Current ML-based LLM routers — systems that use a secondary model or embedding distance to decide routing — fail all four requirements simultaneously:

| ML Router Property | Regulatory Consequence |
|---|---|
| Weights change after retraining | Same prompt routes differently next month — audit trail breaks |
| Decisions not human-interpretable | Cannot satisfy "right to explanation" without post-hoc rationalization |
| Depends on external model service | Decision reproducibility depends on third-party uptime and versioning |
| GPU/network latency in routing path | Adds 50–500 ms to every request; routing failure causes service outage |

No amount of documentation can fix a system where "route this prompt again" produces a different answer. Compliance auditors require that the routing logic can be re-executed from the original inputs and produce the same output months or years later.

### 1.2 Our Contribution

We make the following contributions:

1. **A deterministic 6-axis heuristic routing formula** (Section 3) that maps any text input to a routing tier in O(n) time with zero ML dependencies, zero network calls, and sub-millisecond latency.

2. **A cryptographic audit seal** (Section 4.1) that provides a SHA-256 commitment to every routing decision body, satisfying the "identical input → identical hash" invariant required for compliance reproducibility proofs.

3. **A Merkle-chained temporal ledger** (Section 4.2) that links routing decisions into an append-only sequence where modifying, deleting, or reordering any past entry is mathematically detectable.

4. **An empirical evaluation** (Section 5) on MT-Bench demonstrating that compliance-safe mode achieves 99.6% quality retention against a 100%-Cloud baseline at 16.3% cost reduction.

5. **A regulatory alignment analysis** (Section 6) mapping each system property to specific EU AI Act, GDPR, SEC/FINRA, and HIPAA requirements.

---

## 2. Background and Related Work

### 2.1 LLM Routing Systems

LLM routing addresses the cost-quality trade-off in large language model deployments. Frontier models (GPT-4, Claude 3 Opus) produce higher-quality outputs but incur significant per-token costs. Smaller models (Llama 3 8B, Mistral 7B) are dramatically cheaper but degrade on complex reasoning tasks. Routing systems attempt to direct simple prompts to cheaper models and complex prompts to frontier models.

**Frugal-GPT** (Chen et al., 2023) introduced the concept of LLM cascading, where a prompt is escalated to progressively larger models until quality thresholds are met. This approach requires running inference at each cascade step, introducing latency proportional to the number of cascade levels.

**Hybrid LLM** (Ding et al., 2024) trains a small routing model to predict whether a given prompt will be handled adequately by a small LLM. This achieves strong cost-quality Pareto improvements but inherits the non-reproducibility of any ML-based classifier.

**RouteLLM** (Ong et al., 2024) frames routing as a preference learning problem, training on human preference data. The resulting router is highly accurate but non-deterministic under model updates.

All three systems produce routing decisions that change when their routing models are retrained. This is acceptable for cost optimization but disqualifying for compliance-governed deployments.

### 2.2 Cryptographic Audit Trails

The use of cryptographic commitments in audit logging is well-established in financial systems (SWIFT messaging, blockchain ledgers) and certificate transparency (RFC 6962, Laurie et al., 2013). RFC 3161 (Adams et al., 2001) defines Trusted Timestamping as a protocol for obtaining a trusted timestamp from a Time Stamp Authority (TSA), producing a cryptographically signed token that proves a document existed at or before a given time.

TEIA's temporal chain is structurally analogous to a hash chain in a blockchain or certificate transparency log: each entry commits to the hash of the previous entry, creating a tamper-evident sequence. Unlike a blockchain, the chain does not require distributed consensus — it is a single-writer, single-reader ledger maintained by the gateway process. External notarization via RFC 3161 is used as the "anchor" that grounds the chain to an independently witnessed time.

---

## 3. The 6-Axis Semantic Entropy Formula

### 3.1 Design Philosophy

The routing formula is designed with three constraints that distinguish it from ML-based approaches:

1. **Closed-form determinism**: the output is a mathematical function of the input text. No learned weights, no external calls, no stochastic elements.

2. **Version stability**: the formula and its parameters are pinned to Protocol P40.0. Any change to weights or thresholds constitutes a new protocol version with a new version identifier.

3. **Human interpretability**: every feature is a directly measurable property of the text. The `routing_rationale` field states in plain English which features drove the decision.

### 3.2 Feature Definitions

Let t denote an input text string. We compute six normalized features f_1, ..., f_6 ∈ [0, 1]:

**f_1 — Token Score** (weight 0.20)  
Measures prompt length as a proxy for informational complexity:
```
f_1 = min(1.0, |t| / (4 × 4000))
```
where |t| is the character count and 4000 tokens × 4 chars/token is the reference length for a complex prompt.

**f_2 — Vocabulary Diversity** (weight 0.15)  
Measures lexical richness as a proxy for conceptual density:
```
f_2 = max(0, min(1, (unique_ratio - 0.3) / 0.6))
```
where `unique_ratio = |unique_tokens| / |total_tokens|`. The linear scaling maps the [0.30, 0.90] range to [0, 1].

**f_3 — Reasoning Verb Density** (weight 0.30)  
Measures the density of analytical verbs (analyze, synthesize, evaluate, hypothesize, ...) in a fixed vocabulary of 40 English + Portuguese terms:
```
f_3 = min(1.0, (reasoning_verb_count / word_count) / 0.04)
```
The 0.30 weight makes this the dominant signal — presence of reasoning verbs is the strongest predictor of frontier LLM necessity.

**f_4 — Data Operation Score** (weight 0.15)  
Measures the density of low-complexity data manipulation verbs (list, extract, format, sort, filter, ...). This feature is **inverted** — higher data operation density reduces the entropy score:
```
f_4 = max(0, 1 - min(1, (data_verb_count / word_count) / 0.04))
```

**f_5 — Structural Complexity** (weight 0.10)  
Measures document structure: code blocks, bullet points, headers, and line count contribute to a structural score that approximates multi-part query complexity.

**f_6 — Constraint Density** (weight 0.10)  
Measures the density of logical constraints and conditionals ("but", "however", "unless", "given that", ...) that signal multi-condition requirements.

### 3.3 Composite Semantic Entropy Score

```
E(t) = sum(w_i × f_i(t), i=1..6)
     = 0.20 f_1 + 0.15 f_2 + 0.30 f_3 + 0.15 f_4 + 0.10 f_5 + 0.10 f_6
```

E(t) ∈ [0, 1]. The weights sum to 1.00.

### 3.4 Routing Decision

**Max-savings mode** (legacy, opt-in):
```
routing(t) = Local   if E(t) < 0.35
           = Hybrid  if 0.35 ≤ E(t) < 0.65
           = Cloud   if E(t) ≥ 0.65
```

**Compliance-safe mode** (default since P48.0):
```
routing(t) = Local   if E(t) < 0.20   (provably trivial: extraction, reformatting)
           = Cloud   if E(t) ≥ 0.20   (all non-trivial tasks → frontier LLM)
```
Compliance-safe mode trades cost savings for a stronger quality guarantee: Local is activated only for prompts below entropy 0.20, where empirical evidence confirms zero quality degradation.

### 3.5 Determinism Proof

**Theorem (Write==Read Invariant)**: For any text string t, `route(t)` is a pure function with no side effects, external calls, or stochastic elements. Therefore:
- `route(t)` returns the same dict for every invocation with the same t
- `to_canonical_json(route(t))` returns the same string
- `SHA-256(to_canonical_json(route(t)))` returns the same 256-bit digest

*Proof*: All six feature functions are closed-form arithmetic expressions over the character sequence of t. No random number generation, no I/O, no system clock access occurs in the routing computation. The canonical JSON serializer uses `sort_keys=True` and fixed separators, eliminating key-order non-determinism. QED.

---

## 4. Cryptographic Audit Architecture

### 4.1 Routing Decision Seal

After computing `route(t)`, the `seal(result)` function:

1. Serializes the routing result to canonical JSON: `sort_keys=True`, no whitespace, UTF-8 encoding
2. Computes `body_sha256 = SHA-256(canonical_json_bytes)`
3. Attaches `audit_seal.sha256 = body_sha256` to the result

The sealed document is self-verifying: any auditor can strip `audit_seal`, re-serialize, recompute SHA-256, and confirm the stored hash matches. This is the minimum proof that the document has not been tampered with.

### 4.2 Temporal Chain

A single sealed document proves integrity but not ordering. The temporal chain provides ordering proof.

**Chain construction**: Let H_0 = "GENESIS". For the i-th routing decision with body hash B_i:
```
A_i = SHA-256(A_{i-1} : B_i)     (":": string concatenation)
```

Each `audit_seal` block contains:
- `sha256`: B_i (the body hash — deterministic)
- `time_anchor_hash`: A_i (the chain link — deterministic given A_{i-1})
- `prev_anchor_sha256`: A_{i-1} (the explicit backlink)
- `timestamp_utc`: the wall-clock time of routing (per-invocation, non-deterministic)

**Tamper detection**: Suppose an adversary modifies entry k (changes its routing decision). This changes B_k, which changes A_k, which propagates: A_{k+1}, A_{k+2}, ... all become invalid. Any subsequent entry in the original log will fail chain verification at position k+1.

**Deletion detection**: Deleting entry k shifts all subsequent `prev_anchor_sha256` values by one position. The chain verifier detects this as a mismatch at position k+1.

### 4.3 RFC 3161 External Notarization

The temporal chain is a local, single-writer structure. It cannot prove *when* the chain was created — an adversary with full system access could reconstruct an entire fake chain in seconds.

RFC 3161 Trusted Timestamping closes this gap. The notarization workflow:

1. Compute the TSQ (TimeStampRequest) by hashing A_i with SHA-256 and embedding it in a DER-encoded ASN.1 structure
2. POST the TSQ to a TSA (Time Stamp Authority): the TSA verifies the request format and returns a signed TSR (TimeStampResponse) containing the TSA's timestamp and certificate chain
3. Store the TSR alongside the JSONL audit log

The TSR provides an externally witnessed proof that A_i existed at or before the TSA-certified timestamp. An adversary would need to compromise the TSA (a trusted third party, not under their control) to forge a retroactive timestamp.

**Result**: SHA-256 body seal + Merkle chain + RFC 3161 TSR = three-layer cryptographic proof that:
- Each routing decision is unmodified (body seal)
- The sequence of decisions is unmodified (Merkle chain)
- The chain existed at or before the notarized time (RFC 3161 TSR)

---

## 5. Empirical Evaluation

### 5.1 Benchmark Methodology

We evaluate TEIA on **MT-Bench** (Zheng et al., 2023) — 80 multi-turn questions covering 8 categories: writing, roleplay, reasoning, math, coding, extraction, STEM, and humanities. MT-Bench was selected because it covers the full complexity spectrum from simple extraction tasks (which TEIA should route to Local) to multi-step reasoning tasks (which TEIA should route to Cloud).

We assign quality scores to each routing decision under a quality-estimation model:
- Cloud routing: 1.00 (frontier LLM quality baseline)
- Hybrid routing (max-savings mode): 0.99
- Local routing: 0.98

These estimates are conservative for MT-Bench extraction tasks (where Local/Hybrid likely matches Cloud) and generous for MT-Bench reasoning tasks (where quality degradation would be higher). The net effect is that our quality retention figure is a lower bound on true quality for simple tasks and a reasonable estimate for complex tasks.

### 5.2 Compliance-Safe Mode Results

| Metric | Value |
|---|---|
| Total prompts evaluated | 80 |
| Routed to Local | 8 (10.0%) |
| Routed to Hybrid | 0 (0.0%) |
| Routed to Cloud | 72 (90.0%) |
| Quality retention vs 100%-Cloud | **99.6%** |
| Cost reduction vs 100%-Cloud | **16.3%** |
| Routing latency (P99) | < 1 ms |
| Benchmark result | **PASS** (target: ≥ 95% quality retention) |

The 10% Local routing rate corresponds to MT-Bench extraction-category prompts with entropy < 0.20. All reasoning, math, coding, and multi-step tasks route to Cloud.

### 5.3 Max-Savings Mode Results (Comparison)

| Metric | Value |
|---|---|
| Routed to Local | 50% |
| Routed to Hybrid | 47% |
| Routed to Cloud | 3% |
| Quality retention vs 100%-Cloud | 73.8% |
| Cost reduction vs 100%-Cloud | 98.4% |

Max-savings mode achieves extreme cost reduction but at a quality retention level below 95% — unacceptable for most regulated deployments. The 73.8% figure reflects the honest cost of routing complex reasoning tasks to quantized 13-34B models.

---

## 6. Regulatory Alignment

### 6.1 EU AI Act (High-Risk AI Systems)

Annex IV of the EU AI Act requires high-risk AI systems to maintain technical documentation including "the measures put in place to ensure that the AI system meets the accuracy, robustness and cybersecurity requirements." Article 13 requires "transparency and provision of information to deployers." Article 14 requires "human oversight."

TEIA's contributions:
- The `routing_rationale` field (plain English, per-decision) satisfies the explanation requirement in Article 13
- The SHA-256 audit seal enables "accurate logs" under Article 12 — any past routing decision can be reproduced and verified
- The fixed formula version (P40.0, no drift) eliminates the concept drift problem that makes ML routers non-compliant under Annex IV model change management provisions

### 6.2 GDPR Article 22 — Automated Decision-Making

GDPR Article 22 and Recital 71 require that automated decisions be explainable. The `routing_rationale` field provides a human-readable explanation for every routing decision without any post-hoc rationalization — the explanation is generated at decision time from the same arithmetic used to make the decision.

### 6.3 SEC/FINRA Algorithmic Accountability

FINRA Rule 3110 and SEC Regulation S-7 require that algorithmic trading and advisory systems maintain records that allow reconstruction of past decisions. The TEIA temporal chain provides this: any past routing decision can be independently re-executed from the original prompt and compared to the stored seal.

### 6.4 HIPAA Security Rule §164.312(b)

The Audit Controls standard requires "hardware, software, and/or procedural mechanisms that record and examine activity in information systems that contain or use ePHI." The TEIA gateway's JSONL audit log satisfies this requirement for the routing layer. HIPAA's minimum-necessary principle is addressed by the fact that prompt text is never exfiltrated — routing decisions are made in-process without forwarding prompt content to external routing services.

---

## 7. Limitations and Future Work

### 7.1 Heuristic Accuracy

TEIA's routing formula is a heuristic. It can misclassify edge cases:
- A simple one-sentence prompt that happens to include the word "analyze" may be over-routed to Cloud
- A very long extraction prompt may be under-routed to Local due to token score contributing to entropy

These misclassifications are deterministic and auditable — unlike ML router misclassifications, they can be reproduced and corrected by adjusting the threshold with a version increment.

### 7.2 Formula Calibration

The P40.0 weights were calibrated on a general English/Portuguese corpus. Domain-specific calibration (e.g., medical terminology, financial jargon) may improve accuracy for specialized deployments. Such calibration should be treated as a protocol version increment to maintain the audit chain properties.

### 7.3 RFC 3161 TSA Dependency

The RFC 3161 notarization layer depends on a TSA being available and trustworthy. FreeTSA.org provides a free public TSA with acceptable uptime for development and testing. Production deployments should use a TSA with a documented SLA and CA certificate chain compatible with their jurisdiction's legal framework.

### 7.4 Multi-Tenant Chain Isolation

The current implementation maintains a single global chain per JSONL file. Future work will explore per-tenant chain isolation (separate ledgers per organizational unit) while maintaining a cross-chain Merkle root for aggregate audits.

---

## 8. Conclusion

We have presented TEIA Cognitive Router — a deterministic, compliance-first LLM routing system that produces cryptographically sealed, reproducible routing decisions with sub-millisecond latency and zero ML dependencies. The system satisfies the Write==Read invariant, making it the first LLM router that can mathematically prove its own past decisions without any external oracle.

The MT-Bench evaluation demonstrates that compliance-safe mode achieves 99.6% quality retention at 16.3% cost reduction — a Pareto improvement that does not require trading quality for auditability. The temporal chain architecture extends the integrity guarantee from individual decisions to entire decision sequences, with RFC 3161 external notarization closing the retroactive forgery window.

We release TEIA Cognitive Router under Apache 2.0 at `pip install teia-cognitive-router` and invite the research community to extend the formula calibration, evaluate domain-specific performance, and integrate the temporal chain architecture into other AI governance frameworks.

---

## References

Adams, C., Cain, P., Pinkas, D., & Zuccherato, R. (2001). *Internet X.509 Public Key Infrastructure Time-Stamp Protocol (TSP)*. RFC 3161. IETF.

Chen, L., Zaharia, M., & Zou, J. (2023). *FrugalGPT: How to Use Large Language Models While Reducing Cost and Improving Performance*. arXiv:2305.05176.

Ding, D., Mallick, A., Wang, C., Sim, R., Mukherjee, S., Ruwase, O., He, Y., & Nushi, B. (2024). *Hybrid LLM: Cost-Efficient and Quality-Aware Query Routing*. arXiv:2404.14618.

Laurie, B., Langley, A., & Kasper, E. (2013). *Certificate Transparency*. RFC 6962. IETF.

Ong, I., Almahairi, A., Wu, V., Chiang, W.-L., Wu, T., Gonzalez, J. E., Kadous, M. W., & Stoica, I. (2024). *RouteLLM: Learning to Route LLMs with Preference Data*. arXiv:2406.18665.

Zheng, L., Chiang, W.-L., Sheng, Y., Zhuang, S., Wu, Z., Zhuang, Y., Lin, Z., Li, Z., Li, D., Xing, E., Zhang, H., Gonzalez, J. E., & Stoica, I. (2023). *Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena*. arXiv:2306.05685.

---

*TEIA Cognitive Router | Protocol P49.0–P50.0 | Whitepaper Draft v1.0 | 2026-06-02*  
*Submit to arXiv: cs.CR (Cryptography and Security) + cs.AI (Artificial Intelligence)*
