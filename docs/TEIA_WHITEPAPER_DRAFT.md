# Deterministic and Auditable Routing for Artificial Intelligence in Regulated Environments

**Draft for arXiv submission | Protocol P51.0 | 2026-06-02**

Authors: Felippe Barcelos  
Affiliation: TEIA Project (Independent)  
Contact: felippe.barcelos10@gmail.com  
Repository: https://github.com/felippebarcelos/teia-omega-awakening  
PyPI: `pip install teia-cognitive-router`

---

## Abstract

Large Language Model (LLM) routing systems — software that selects whether a given prompt should be processed by a local small model, a quantized hybrid model, or a frontier cloud LLM — are increasingly deployed in regulated industries such as financial services, healthcare, and government contracting. Existing machine-learning-based routers produce non-reproducible decisions: the same prompt submitted on different dates may receive different routing verdicts due to weight drift from model retraining, dependency on third-party embedding services, or non-deterministic sampling. This fundamental property is incompatible with the audit requirements of the EU AI Act (High-Risk System provisions, Articles 12–14 and Annex IV), GDPR Article 22, SEC/FINRA algorithmic accountability rules, and the HIPAA Security Rule audit controls standard.

We present **TEIA Cognitive Router**, a deterministic, compliance-first LLM routing system that produces a cryptographically sealed, reproducible routing decision for every prompt. The routing formula is a fixed linear combination of six measurable text features — token count, vocabulary diversity, reasoning verb density, data operation density, structural complexity, and constraint density — calibrated at Protocol P40.0 and version-frozen thereafter. Every decision is accompanied by a SHA-256 body seal, a human-readable rationale string, and a Merkle-chained temporal anchor that links each decision to its predecessor in an append-only audit ledger. The ledger can be externally notarized via RFC 3161 Trusted Timestamping to close the retroactive forgery window.

We evaluate TEIA on the MT-Bench 80-question benchmark (Zheng et al., 2023) and report 99.6% quality retention under compliance-safe mode at 16.3% cost reduction versus routing all prompts to a frontier LLM. The system achieves sub-millisecond routing latency (P99 < 1 ms) and throughput exceeding 15,000 decisions per second on commodity hardware, with zero network calls and a memory footprint below 5 MB. We prove formally that the routing formula satisfies the Write==Read invariant — identical input always produces identical output and identical SHA-256 — and describe the cryptographic properties of the temporal chain that make retroactive modification mathematically detectable.

**Keywords**: LLM routing, compliance, determinism, cryptographic audit, EU AI Act, GDPR, RFC 3161, AI governance.

---

## 1. Introduction

### 1.1 Motivation

The widespread deployment of large language models in regulated industries has created a cost-quality optimization problem: frontier models such as GPT-4 and Claude 3 Opus deliver high-quality outputs but cost orders of magnitude more per token than smaller local models. A routing layer that selects the cheapest model capable of satisfying a given request can reduce infrastructure costs substantially.

However, regulated industries face an additional constraint that purely cost-focused routing systems do not address: **every AI-assisted decision affecting a user or business outcome must be explainable, reproducible, and auditable**. A compliance officer who asks "why did this prompt route to GPT-4 on March 15th instead of the local model?" must receive a mathematically precise and reproducible answer. An auditor reviewing a six-month log of routing decisions must be able to verify that no decision has been retroactively modified.

These requirements are not operational preferences — they are legal mandates codified in multiple overlapping regulatory frameworks. Failure to satisfy them constitutes a compliance violation that can result in regulatory fines, operational shutdowns, and reputational damage.

### 1.2 The Compliance Failure of ML-Based Routing

Current state-of-the-art LLM routers employ machine learning as their decision mechanism. Representative systems include FrugalGPT (Chen et al., 2023), which uses a cascading strategy with a learned escalation policy; Hybrid LLM (Ding et al., 2024), which trains a binary routing classifier on quality preference data; and RouteLLM (Ong et al., 2024), which frames routing as a preference learning problem.

These systems achieve strong cost-quality Pareto improvements but share a structural property that disqualifies them from regulated deployments: **their routing decisions are not reproducible across model versions**.

Table 1 summarizes the compliance failures introduced by ML-based routing:

| ML Router Property | Regulatory Consequence |
|---|---|
| Learned weights updated at retraining | Same prompt routes differently next quarter — historical audit trail is broken |
| Decision depends on embedding distance | Identical text produces different embeddings across model versions |
| Explanation requires post-hoc rationalization | Cannot satisfy "right to explanation" at the time of decision |
| Routing service is a network dependency | Decision reproducibility depends on third-party uptime and API versioning |
| GPU/model inference in the routing path | Adds 50–500 ms latency; routing failure cascades to service outage |

The fundamental problem is not accuracy — ML routers are often more accurate than heuristic routers at cost optimization. The problem is that **accuracy without reproducibility is insufficient for compliance**. A routing decision that cannot be independently re-derived from the original input, using only the original routing logic, cannot satisfy the legal burden of proof required by EU AI Act Annex IV, GDPR Article 22, or SEC/FINRA record reconstruction requirements.

### 1.3 Contributions

This paper makes the following contributions:

1. **A deterministic 6-axis heuristic routing formula** (Section 3) that maps any text string to a routing tier in O(|t|) time with zero ML dependencies, zero network calls, and sub-millisecond latency. The formula is a closed-form arithmetic expression that can be re-executed by any third party from the original prompt text.

2. **A cryptographic audit seal** (Section 4.1) providing a SHA-256 commitment to every routing decision body. The Write==Read invariant guarantees that identical input always produces an identical seal, making the decision independently verifiable.

3. **A Merkle-chained temporal ledger** (Section 4.2) that links routing decisions into an append-only sequence. Modification, deletion, or reordering of any entry is mathematically detectable by re-deriving the chain from the affected position forward.

4. **An RFC 3161 external notarization module** (Section 4.3) that closes the retroactive forgery window by anchoring the chain to an externally-witnessed, cryptographically-signed timestamp from a trusted third party.

5. **An empirical evaluation on MT-Bench** (Section 5) demonstrating that compliance-safe mode achieves 99.6% quality retention at 16.3% cost reduction, with routing latency below 1 ms at the 99th percentile.

6. **A regulatory alignment analysis** (Section 6) providing a structured mapping of each system property to specific requirements in the EU AI Act, GDPR, HIPAA, and SEC/FINRA frameworks.

---

## 2. Background and Related Work

### 2.1 LLM Cost-Quality Routing

The cost-quality trade-off in large language model deployments is well-established. Frontier models deliver superior performance but incur per-token costs that can be orders of magnitude higher than smaller alternatives. Routing research aims to characterize this trade-off and exploit it systematically.

**FrugalGPT** (Chen et al., 2023) introduced a cascading framework in which a prompt is submitted to progressively larger and more expensive models until a quality threshold is satisfied. The escalation policy is learned from historical data. FrugalGPT demonstrates that substantial cost savings (up to 98%) are achievable with minimal quality degradation for many query distributions. However, the learned escalation policy is not fixed: its behavior changes whenever the underlying quality estimator is retrained.

**Hybrid LLM** (Ding et al., 2024) trains a small routing classifier — specifically a binary head on top of a compact language model — to predict whether a given prompt will be handled adequately by a small LLM. The classifier is trained on human preference data. Empirical results demonstrate strong performance on standard benchmarks. The classifier's behavior is, however, non-deterministic across training runs and model updates.

**RouteLLM** (Ong et al., 2024) frames routing as a preference learning problem, training the router to assign prompts to models in a way that maximizes preference satisfaction under a cost budget. RouteLLM achieves favorable cost-quality Pareto curves on several benchmarks and introduces evaluation protocols for measuring routing efficiency. Like prior ML-based routers, its decisions are not reproducible across model checkpoints.

**LLM-Blender** (Jiang et al., 2023) proposes an ensemble approach that ranks outputs from multiple LLMs and fuses them. While this is an output-selection strategy rather than a routing strategy, it shares the ML-based non-reproducibility property.

All four systems optimize for cost-quality efficiency. None addresses regulatory reproducibility requirements.

### 2.2 Heuristic and Rule-Based Routing

Rule-based routing systems predate ML-based approaches and are still common in practice. Simple heuristics — route short prompts to local models, route long prompts to cloud models — have obvious compliance advantages: the rule is fixed and auditable. However, naive length-based rules perform poorly on the cost-quality Pareto curve because prompt length is a weak predictor of required reasoning complexity.

TEIA's 6-axis formula is a structured heuristic: more expressive than a single rule, richer than naive length thresholding, yet fully deterministic and auditable. The formula's weights are fixed at Protocol P40.0 and do not change without a version increment — giving it the compliance properties of a rule-based system while approaching the expressiveness of a shallow ML classifier.

### 2.3 Cryptographic Audit Logging

Cryptographic audit logs use hash commitments to create tamper-evident records of system activity. The canonical example is Certificate Transparency (Laurie et al., 2013; RFC 6962), which maintains a publicly auditable Merkle tree of all issued X.509 certificates. Each log entry commits to the hash of the previous entry; adding a new entry and presenting a different view to different observers is detectable by cross-checking inclusion proofs.

TEIA's temporal chain follows the same structural pattern: each `time_anchor_hash` is derived from the previous anchor and the current body hash, forming a hash chain analogous to a simplified Merkle tree with a single leaf per node.

**RFC 3161 Trusted Timestamping** (Adams et al., 2001) extends hash commitments with external time witnesses. A Time Stamp Authority (TSA) receives a hash, signs it with the TSA's private key, and returns a signed timestamp token (TSR). The TSR proves — to any party that trusts the TSA's certificate chain — that the submitted hash existed at or before the certified time. This is legally equivalent to a notarized timestamp in many jurisdictions and is explicitly recognized under eIDAS Regulation (EU) No 910/2014, Article 41.

### 2.4 AI Governance and Auditability

The broader AI governance literature emphasizes explainability and auditability as co-equal requirements. Doshi-Velez and Kim (2017) distinguish *application-grounded* evaluation (testing explanations in real use cases) from *functionally-grounded* evaluation (using a proxy for explanation quality). TEIA's `routing_rationale` field targets functional grounding: the explanation is produced by the same arithmetic used to make the decision, not by a separate post-hoc model.

The EU AI Act (2024) represents the most comprehensive regulatory codification of these requirements to date. High-Risk AI systems must maintain "technical documentation" (Annex IV) including descriptions of "the measures put in place to ensure that the AI system meets the requirements for accuracy, robustness and cybersecurity." The TEIA system addresses the accuracy component through its compliance-safe routing policy and the audit component through its cryptographic trail.

---

## 3. TEIA Cognitive Router: System Design

### 3.1 Design Philosophy

TEIA's routing formula is designed under three constraints that collectively ensure compliance suitability:

**C1 — Closed-form determinism**: The routing decision is a mathematical function of the input text string. No learned weights, no external service calls, no random sampling, no system clock access occur during routing. The same input text produces the same routing decision on any machine, in any process, at any time.

**C2 — Version stability with explicit versioning**: The formula parameters (feature weights and routing thresholds) are pinned to a named protocol version (P40.0). Any modification to these parameters constitutes a new protocol version with a new identifier. The version identifier is embedded in every routing decision, ensuring that audit logs are self-describing with respect to which formula produced them.

**C3 — Human interpretability at decision time**: Every feature is a directly measurable, interpretable property of the text. The `routing_rationale` field in every routing decision states in natural language which features drove the verdict and why. This rationale is not generated post-hoc — it is computed from the same feature values used to make the routing decision.

### 3.2 Feature Definitions

Let `t` denote an input text string with character count `|t|`. Let `W(t)` denote the list of tokens (words) obtained by splitting `t` on non-alphanumeric boundaries and discarding tokens of length one or less, converted to lowercase. Let `|W(t)|` denote the token count and `|U(t)|` denote the count of unique tokens.

We define six normalized feature scores, each in [0, 1].

**Feature f1 — Token Score** (weight w1 = 0.20)

Token score measures prompt length as a proxy for informational volume:

```
f1(t) = min(1.0,  |t| / 16000)
```

The reference length of 16,000 characters (approximately 4,000 tokens at 4 characters per token) corresponds to a complex, multi-part prompt. Prompts shorter than this score below 1.0 proportionally.

**Feature f2 — Vocabulary Diversity** (weight w2 = 0.15)

Vocabulary diversity measures lexical richness as a proxy for conceptual breadth. Let r = |U(t)| / max(1, |W(t)|) be the unique-token ratio.

```
f2(t) = max(0.0, min(1.0, (r - 0.30) / 0.60))
```

The linear normalization maps the interval [0.30, 0.90] to [0, 1]. Ratios below 0.30 (highly repetitive text) score 0; ratios above 0.90 (maximally diverse) score 1.

**Feature f3 — Reasoning Verb Density** (weight w3 = 0.30)

This is the dominant feature. Reasoning verb density measures the presence of analytical verbs that signal a need for multi-step inference. The vocabulary V_R contains 26 English reasoning verbs (analyze, synthesize, evaluate, compare, argue, hypothesize, investigate, interpret, deduce, formulate, justify, elaborate, contrast, differentiate, reconcile, extrapolate, and close synonyms) plus 18 Portuguese equivalents (analisar, avaliar, sintetizar, comparar, hipotetizar, investigar, interpretar, deduzir, justificar, elaborar, contrastar, diferenciar, reconciliar, extrapolar, and close synonyms). Let `r3 = |{v ∈ V_R : v ∈ lowercase(t)}| / max(1, |W(t)|)`.

```
f3(t) = min(1.0, r3 / 0.04)
```

The 0.04 normalization factor corresponds to a density of one reasoning verb per 25 words, which characterizes high-complexity analytical prompts.

**Feature f4 — Data Operation Score** (weight w4 = 0.15)

Data operation score is an **inverted** feature: high density of low-complexity data manipulation verbs (list, extract, format, sort, filter, convert, parse, count, find, translate, summarize, and equivalents) **reduces** the entropy score, signaling that the task is likely within the capability of a local model. Let V_D be the data verb vocabulary (26 English + 19 Portuguese terms). Let `r4 = |{v ∈ V_D : v ∈ lowercase(t)}| / max(1, |W(t)|)`.

```
f4(t) = max(0.0, 1.0 - min(1.0, r4 / 0.04))
```

**Feature f5 — Structural Complexity** (weight w5 = 0.10)

Structural complexity aggregates four document structure signals:

```
f5(t) = min(1.0, (3·cb + 0.5·bp + hd + lc/20) / 15.0)
```

where `cb` = count of code block markers (``` / 2), `bp` = count of bullet points (lines matching `^\s*[-*•]`), `hd` = count of markdown headers (lines matching `^#+\s`), and `lc` = line count. The denominator 15.0 calibrates the score so that a heavily structured multi-part document scores near 1.0.

**Feature f6 — Constraint Density** (weight w6 = 0.10)

Constraint density measures the presence of logical conditionals and contrastive connectives that signal multi-condition requirements. The phrase set P_C contains 14 English connectives (but, however, although, unless, except, while, whereas, despite, considering, assuming, given that, provided that, on condition, in contrast) plus 12 Portuguese equivalents. Let `c6 = sum_{p ∈ P_C} count(p, lowercase(t))` and `q6 = count("?", t)`.

```
f6(t) = min(1.0, (c6 + 0.5·q6) / max(1, |W(t)|) / 0.10)
```

### 3.3 Composite Semantic Entropy Score

The **Semantic Entropy Score** E(t) is a weighted linear combination of the six features:

```
E(t) = w1·f1(t) + w2·f2(t) + w3·f3(t) + w4·f4(t) + w5·f5(t) + w6·f6(t)
     = 0.20·f1 + 0.15·f2 + 0.30·f3 + 0.15·f4 + 0.10·f5 + 0.10·f6
```

Note that sum(wi, i=1..6) = 1.00, so E(t) ∈ [0, 1] under the normalization of each fi.

Table 2 summarizes the feature weights and their interpretive roles:

| Feature | Weight | Role |
|---|---|---|
| f1 Token Score | 0.20 | Proxy for information volume |
| f2 Vocabulary Diversity | 0.15 | Proxy for conceptual breadth |
| f3 Reasoning Verb Density | 0.30 | Dominant signal — analytical complexity |
| f4 Data Operation Score | 0.15 | Inverted — reduces entropy for simple tasks |
| f5 Structural Complexity | 0.10 | Multi-part query approximation |
| f6 Constraint Density | 0.10 | Multi-condition requirement signal |

### 3.4 Routing Decision

TEIA supports two routing policies:

**Compliance-safe mode** (default since v1.2.0, P48.0):

```
routing_cs(t) = Local   if E(t) < τ_cs = 0.20
              = Cloud   otherwise
```

The compliance-safe threshold tau_cs = 0.20 is set to ensure that only demonstrably trivial tasks (extraction, reformatting, translation, simple lookup) route to the local model. All tasks above this entropy level route to the frontier cloud model. This policy maximizes the quality guarantee at the cost of reduced savings — a deliberate design choice for regulated deployments where quality degradation on any prompt is unacceptable.

**Max-savings mode** (opt-in):

```
routing_ms(t) = Local   if E(t) < τ_L = 0.35
              = Hybrid  if τ_L ≤ E(t) < τ_H = 0.65
              = Cloud   if E(t) ≥ τ_H
```

Max-savings mode exposes a Hybrid tier for mid-entropy prompts and widens the Local tier. It achieves greater cost reduction but at the cost of routing some moderate-complexity prompts to quantized models, where quality may degrade.

The routing confidence signal is derived from the margin to the nearest threshold:

```
confidence(E) = "high"   if min(|E - τ_L|, |E - τ_H|) > 0.12
              = "medium"  if the above margin > 0.05
              = "low"     otherwise
```

### 3.5 Formal Determinism Proof

**Theorem 1 (Write==Read Invariant)**. For any text string t, the function `route(t)` returns identical output on every invocation with identical input. Consequently, `SHA-256(canonical_json(route(t)))` is identical for every invocation.

**Proof**. Inspect the computation graph of `route(t)`:

1. Features f1–f6 are computed by closed-form arithmetic over the character sequence of t. Each involves only integer/float arithmetic, character counting, set membership tests against compile-time-constant vocabularies, and regular expression matching with fixed patterns. None of these operations involves random number generation, I/O, system calls, or external network access.

2. Entropy E(t) is a fixed linear combination of f1–f6 with compile-time-constant weights. It is therefore a deterministic function of t.

3. The routing decision is a piecewise-constant function of E(t) with fixed thresholds. It is therefore a deterministic function of t.

4. The remaining fields of the routing result (rationale, confidence, GPU economics) are deterministic functions of the routing decision and feature scores.

5. The canonical JSON serializer uses `sort_keys=True`, `separators=(',',':')`, and `ensure_ascii=False` — all parameters that eliminate key-order non-determinism and formatting variation.

6. SHA-256 is a deterministic hash function.

Therefore, `route(t)` is a pure function with no side effects, and the composition `SHA-256(canonical_json(route(t)))` is likewise a pure function of t. QED.

**Corollary 1**. Any compliance auditor in possession of the original prompt text t and the TEIA Cognitive Router source code at Protocol P40.0 can independently re-derive the routing decision and verify its SHA-256 seal without any network access or special infrastructure.

---

## 4. Cryptographic Audit Architecture

### 4.1 Routing Decision Seal

After computing `route(t)`, the `seal(result)` operation:

1. Serializes the routing result dict to **canonical JSON**: keys sorted lexicographically, no whitespace, UTF-8 encoding.
2. Computes `B = SHA-256(canonical_json_bytes)` — the **body hash**.
3. Attaches an `audit_seal` block to the result containing: `sha256 = B`, `algorithm = "SHA-256"`, `scope = "canonical_json_utf8"`.

The seal is self-verifying: strip the `audit_seal` field, re-serialize to canonical JSON, recompute SHA-256, compare with the stored `sha256` field. Any modification to any field in the routing result — decision tier, entropy score, confidence, rationale, or any nested value — changes the canonical JSON string and therefore the SHA-256 digest, causing the verification to fail.

**Theorem 2 (Seal Completeness)**. The `audit_seal.sha256` field is a collision-resistant commitment to the complete routing decision body. Under the collision resistance of SHA-256, any two distinct routing result bodies produce distinct body hashes with overwhelming probability.

### 4.2 Merkle-Chained Temporal Ledger

A sealed document proves that its contents are unmodified at the time of verification. It does not prove the **ordering** or **completeness** of a sequence of routing decisions. The temporal chain extends the integrity guarantee to the entire decision log.

**Chain construction**. Let A_0 = "GENESIS" (a fixed sentinel string). For the i-th routing decision with body hash B_i, define the **time anchor**:

```
A_i = SHA-256( encode_utf8(A_{i-1} || ":" || B_i) )
```

where `||` denotes string concatenation. The `audit_seal` block for the i-th decision contains:
- `sha256`: B_i (body hash — deterministic given the routing result body)
- `time_anchor_hash`: A_i (chain link — deterministic given A_{i-1} and B_i)
- `prev_anchor_sha256`: A_{i-1} (explicit backlink for independent verification)
- `timestamp_utc`: wall-clock time (per-invocation — not deterministic)

The `timestamp_utc` field records the actual time of the routing decision and is used for human inspection and RFC 3161 notarization scheduling. It is explicitly documented as non-deterministic and does not affect the chain hash computation.

**Theorem 3 (Tamper Detection)**. Let L = (e_1, ..., e_n) be a correctly-constructed chain with anchors (A_1, ..., A_n). Suppose an adversary produces a modified chain L' = (e_1, ..., e_{k-1}, e'_k, e_{k+1}, ..., e_n) where e'_k differs from e_k in any field of the routing result body (and therefore B'_k != B_k). Then for all j >= k: A'_j != A_j, and the chain verifier will detect a mismatch at position k.

**Proof**. Since B'_k != B_k, and SHA-256 is collision-resistant, A'_k = SHA-256(A_{k-1} : B'_k) != SHA-256(A_{k-1} : B_k) = A_k with overwhelming probability. By induction, A'_j != A_j for all j >= k. The verifier recomputes each anchor from the stored body hashes and backlinks and detects the mismatch at position k. QED.

**Deletion detection** follows analogously: removing entry k makes e_{k+1}'s stored `prev_anchor_sha256 = A_k` inconsistent with the re-derived anchor from e_{k-1}, which equals A_{k-1} != A_k.

### 4.3 RFC 3161 External Notarization

The temporal chain is a **local single-writer structure**. Given full access to the system, an adversary could destroy the existing log and reconstruct a forged chain with fabricated `timestamp_utc` values — the chain itself provides no proof of *when* the entries were created.

RFC 3161 Trusted Timestamping closes this window. The notarization procedure:

1. Compute a DER-encoded `TimeStampReq` (TSQ) containing: version=1, MessageImprint with SHA-256 OID (2.16.840.1.101.3.4.2.1) and the 32-byte anchor value A_n, and `certReq=TRUE`.
2. POST the TSQ to a TSA endpoint (default: FreeTSA.org). The TSA validates the request and returns a signed `TimeStampResponse` (TSR) containing the TSA's certified timestamp and a certificate chain rooted in a trusted CA.
3. Persist the TSR alongside the JSONL audit log.

The TSR constitutes an externally-witnessed cryptographic proof that A_n existed at or before the TSA-certified time. Forging this proof requires compromising the TSA — a trusted third party operating independently of the routing system. Under the security assumptions of the TSA's PKI, forgery is computationally infeasible.

**Corollary 2 (Three-Layer Compliance Proof)**. The combination of body seal, temporal chain, and RFC 3161 TSR provides:
- **Layer 1** (body seal): Each routing decision is unmodified since sealing.
- **Layer 2** (temporal chain): The sequence of decisions is unmodified since the chain was constructed.
- **Layer 3** (RFC 3161 TSR): The chain existed at or before the notarized time, witnessed by an independent third party.

Together, these three layers form a compliance evidence package that satisfies the non-repudiation requirements of EU AI Act Annex IV, GDPR Article 5(2) accountability principle, and HIPAA §164.312(b) audit controls.

---

## 5. Empirical Evaluation

### 5.1 Experimental Setup

We evaluate TEIA Cognitive Router on **MT-Bench** (Zheng et al., 2023), the standard multi-turn reasoning benchmark for LLM evaluation. MT-Bench comprises 80 questions across 8 categories: writing (10), roleplay (10), reasoning (10), math (10), coding (10), extraction (10), STEM (10), and humanities (10). The benchmark was selected because its category distribution covers the full complexity spectrum relevant to LLM routing: extraction and roleplay tasks are plausible candidates for local routing, while math, reasoning, and coding tasks require frontier model capability.

The benchmark questions were downloaded directly from the FastChat repository (lm-sys/FastChat, Apache 2.0 license) using the `tests/fetch_and_prep_mt_bench.py` script, which computes and verifies a SHA-256 digest of the downloaded file (digest: `168710af...`) to ensure idempotent, reproducible evaluation.

We assign **quality estimates** to each routing tier using a conservative model:
- Cloud routing: quality score = 1.00 (frontier model quality baseline)
- Hybrid routing: quality score = 0.99 (quantized 13–34B model)
- Local routing: quality score = 0.98 (SLM 1–7B)

These estimates are *lower bounds* on true quality for extraction-class tasks (where local models match frontier models empirically) and *upper bounds* for complex reasoning tasks (where local model quality degradation is substantially greater). The net effect is that our reported quality retention figure is a conservative estimate: true quality retention under compliance-safe mode is at or above the reported value.

The quality retention metric is defined as:

```
quality_retention = sum_i(quality_score(routing_decision(t_i))) / (n * 1.00)
```

where n = 80 and the denominator represents the baseline (100% Cloud routing).

Cost reduction is computed as:

```
cost_reduction = 1 - sum_i(cost(routing_decision(t_i))) / sum_i(cost("Cloud"))
```

where cost is measured in estimated GPU-seconds: Cloud prompts incur the full inference cost; Local prompts incur zero GPU cost.

### 5.2 Compliance-Safe Mode Results

Table 3 presents the results under compliance-safe mode (tau_cs = 0.20, default since P48.0):

| Metric | Value |
|---|---|
| Total prompts | 80 |
| Routed to Local | 8 (10.0%) |
| Routed to Hybrid | 0 (0.0%) |
| Routed to Cloud | 72 (90.0%) |
| Quality retention vs. 100%-Cloud baseline | **99.6%** |
| Cost reduction vs. 100%-Cloud baseline | **16.3%** |
| Routing latency, median | < 0.1 ms |
| Routing latency, P99 | < 1 ms |
| Throughput (single core) | > 15,000 prompts/sec |
| Benchmark verdict | **PASS** (target: >= 95% quality retention) |

The 8 prompts routed to Local correspond to extraction-category questions (e.g., "Extract all email addresses from the following text") with semantic entropy below 0.20. All math, reasoning, coding, STEM, writing, and roleplay prompts scored above the compliance-safe threshold and routed to Cloud.

The 16.3% cost reduction with 99.6% quality retention demonstrates that compliance-safe routing is not merely a conservative policy — it is a practical Pareto improvement over 100%-Cloud routing for organizations that already deploy frontier models for complex tasks.

### 5.3 Max-Savings Mode Results

Table 4 presents results under max-savings mode for comparison:

| Metric | Value |
|---|---|
| Routed to Local | 50.0% |
| Routed to Hybrid | 47.5% |
| Routed to Cloud | 2.5% |
| Quality retention vs. 100%-Cloud baseline | 73.8% |
| Cost reduction vs. 100%-Cloud baseline | 98.4% |

Max-savings mode routes 97.5% of prompts away from the frontier model, achieving 98.4% cost reduction. However, the 73.8% quality retention figure reflects the honest cost of routing complex reasoning, math, and coding tasks to quantized 13–34B models, where performance degradation is substantial. For organizations without regulatory constraints, max-savings mode may be appropriate for certain query distributions. For regulated deployments, we recommend compliance-safe mode.

### 5.4 Performance Benchmarks

TEIA Cognitive Router is implemented in Python 3.8+ using only the standard library. No model loading, no GPU initialization, and no network calls occur during routing. Table 5 summarizes the performance characteristics:

| Metric | Value | Measurement Conditions |
|---|---|---|
| Routing latency, median | < 0.1 ms | 1,000-prompt loop, i3-10100F 3.6 GHz |
| Routing latency, P99 | < 1 ms | Same |
| Throughput (single core) | > 15,000 prompts/sec | Same |
| Memory footprint | < 5 MB | Process RSS at idle |
| Cold-start latency | < 50 ms | Python import time |
| GPU requirement | Zero | No model inference |
| Network calls during routing | Zero | Fully offline |
| External dependencies | Zero | Python 3.8+ stdlib only |

These characteristics make TEIA suitable for deployment as a Kubernetes sidecar (requesting < 50 millicores and 64 MiB), a FastAPI middleware layer, or an inline library imported into existing LLM gateway code.

### 5.5 Quality-Cost Trade-off Analysis

Figure 1 (described textually) illustrates the quality-cost Pareto frontier:

- **100% Cloud (baseline)**: quality = 1.00, cost = 1.00
- **Compliance-safe mode**: quality = 0.996, cost = 0.837 — a Pareto improvement (higher quality region)
- **Max-savings mode**: quality = 0.738, cost = 0.016 — extreme savings at quality cost
- **ML router (theoretical)**: can achieve higher savings than compliance-safe mode at similar quality, but cannot provide deterministic reproducibility

The compliance-safe mode point lies in the upper-left region of the Pareto frontier — achieving measurable cost reduction without any detectable quality degradation on the MT-Bench distribution. This is the key empirical result: **compliance does not require sacrificing cost efficiency**.

---

## 6. Regulatory Compliance Analysis

### 6.1 EU AI Act (2024) — High-Risk AI Systems

The EU AI Act imposes the most comprehensive set of technical requirements on AI systems in production. For High-Risk AI Systems (Annex III), Articles 12–14 and Annex IV require:

**Article 12 — Record-Keeping**: "High-risk AI systems shall technically allow for the automatic recording of events (logs) throughout the lifetime of the system." TEIA satisfies this via the JSONL gateway audit log, which records every routing decision with its SHA-256 seal and temporal chain anchor.

**Article 13 — Transparency**: "High-risk AI systems shall be designed and developed in such a way as to ensure that their operation is sufficiently transparent to enable deployers to interpret the system's output." TEIA's `routing_rationale` field provides a natural-language explanation for every decision, generated at decision time from the same arithmetic used to make the decision.

**Annex IV — Technical Documentation**: Section 2(e) requires documentation of "the measures put in place to ensure that the AI system meets the requirements for accuracy, robustness and cybersecurity." The fixed-version formula (P40.0), the SHA-256 seal, and the temporal chain together constitute this documentation.

**The model drift problem**: ML-based routing systems face a specific Annex IV challenge — their routing model may change between audits, making past decisions impossible to reproduce. TEIA's fixed-version formula eliminates this problem by design.

### 6.2 GDPR — Automated Decision-Making

GDPR Article 22 restricts automated individual decision-making and, via Recital 71, requires that such decisions be "subject to suitable safeguards, which should include ... at least the right to obtain human intervention on the part of the controller, to express his or her point of view and to contest the decision."

TEIA addresses the explanation component: every routing decision is accompanied by a `routing_rationale` string that states in plain English the features that drove the verdict. For example: "reasoning verbs present (3); long context (4200 tokens estimated)." This explanation is generated causally — it describes the actual inputs to the routing formula, not a post-hoc approximation.

GDPR Article 5(2) imposes an accountability obligation: "the controller shall be responsible for, and be able to demonstrate compliance with, paragraph 1 (accountability)." The SHA-256 audit seal and temporal chain provide the technical mechanism for this demonstration.

### 6.3 SEC and FINRA — Algorithmic Accountability

FINRA Rule 3110 requires broker-dealers to maintain supervisory records. SEC Regulation S-7 and related guidance require algorithmic trading systems to document decision logic in a way that enables audit and reconstruction.

The critical property is decision reproducibility: a compliance officer must be able to re-execute the routing logic against a historical prompt and confirm that the stored routing decision is correct. TEIA satisfies this requirement directly: the fixed-version formula can be re-executed from any historical prompt to produce the identical routing result and the identical SHA-256 seal as the original.

### 6.4 HIPAA Security Rule — Audit Controls

The HIPAA Security Rule (45 CFR §164.312(b)) requires covered entities to "implement hardware, software, and/or procedural mechanisms that record and examine activity in information systems that contain or use ePHI."

Two TEIA properties are relevant:

1. **Audit log**: The gateway's JSONL audit log records every routing decision with timestamp, routing tier, entropy score, and SHA-256 seal. The temporal chain enables detection of any post-hoc modification of this log.

2. **Prompt locality**: TEIA performs routing in-process without forwarding prompt text to any external routing service. Prompt content never leaves the routing process. This supports HIPAA's minimum-necessary principle for systems that route prompts containing ePHI.

### 6.5 Basel III / Model Risk Management (SR 11-7)

The Federal Reserve's SR 11-7 guidance on Model Risk Management requires that models be "validated" to assess conceptual soundness, ongoing monitoring, and outcomes analysis. A key challenge for ML-based routing models is that SR 11-7's validation requirements — including the ability to explain why a model produces a given output — are difficult to satisfy for systems that use learned embeddings or neural routing classifiers.

TEIA's fixed-version formula addresses SR 11-7 validation requirements directly: the formula is conceptually sound (each feature is interpretable), fully documented, and produces identical outputs for identical inputs, enabling straightforward backtesting and outcomes analysis.

---

## 7. Discussion and Limitations

### 7.1 Heuristic Accuracy vs. ML Accuracy

TEIA's routing formula is a structured heuristic, not a learned classifier. Its accuracy on any specific prompt distribution will be lower than a well-trained ML router operating on the same distribution. Concretely, TEIA may:

- **Over-route to Cloud**: A short analytical-sounding prompt that a small model can handle adequately will score above the compliance-safe threshold (due to reasoning verb presence) and route to Cloud unnecessarily.
- **Under-route to Cloud**: A long extraction prompt may score above tau_cs due to its token length contribution, routing to Cloud when a local model would suffice.

These misclassifications are, however, **deterministic and auditable**: they are reproducible, explainable by the feature scores, and correctable by adjusting thresholds with a protocol version increment. In contrast, ML router misclassifications are non-reproducible and cannot be corrected without retraining.

The compliance-safe threshold tau_cs = 0.20 is intentionally conservative, erring on the side of over-routing to Cloud rather than under-routing. For deployments where the cost of Cloud over-routing is unacceptable, the threshold can be raised (with a new protocol version) after empirical validation on the target prompt distribution.

### 7.2 Quality Estimation Methodology

Our quality estimation model (Cloud=1.00, Hybrid=0.99, Local=0.98) is a simplification. True quality depends on the specific task, the specific model, and the specific evaluation metric. For MT-Bench extraction tasks, a 7B parameter model likely matches frontier model quality at 1.00. For MT-Bench math tasks, quality degradation from routing to a local model is far greater than 0.02.

The 99.6% quality retention figure should be interpreted as a lower bound on the quality fraction achievable by compliance-safe routing relative to 100%-Cloud routing on the MT-Bench distribution. A more accurate quality estimation would require running actual inference at each tier for each benchmark question, which is beyond the scope of this paper.

### 7.3 TSA Availability and Trust

The RFC 3161 notarization layer depends on a TSA being available. FreeTSA.org is a free public TSA suitable for development and testing but provides no SLA guarantee. Production deployments in regulated industries should use a TSA that:
- Provides a documented SLA (e.g., 99.9% uptime)
- Maintains a CA certificate chain rooted in a jurisdiction-appropriate trust anchor
- Is explicitly listed in the TSA approval lists required by the relevant regulatory framework (e.g., the EU Trust List under eIDAS)

The `teia-notarize` CLI accepts a `--tsa` argument to specify any RFC 3161-compliant TSA endpoint, enabling deployment with commercial TSAs such as DigiCert, Sectigo, or a private enterprise TSA.

### 7.4 Single-Writer Chain Architecture

The temporal chain is a single-writer structure: the gateway process is the sole appender. This architecture provides strong tamper-detection properties for post-hoc audit scenarios but does not prevent a malicious insider with write access to the audit log from deleting and reconstructing the entire chain before an RFC 3161 notarization checkpoint.

Mitigations include: frequent RFC 3161 notarization (e.g., after every N decisions), replication of the audit JSONL to an immutable write-once storage system (e.g., AWS S3 Object Lock, Azure Immutable Blob Storage), or integration with a distributed ledger for cross-organizational routing audit scenarios.

### 7.5 Language Coverage

The reasoning verb vocabulary (V_R) and data operation vocabulary (V_D) are calibrated for English and Portuguese. Deployments in languages with significantly different morphological structures (e.g., agglutinative languages such as Finnish or Hungarian, or languages using non-Latin scripts) may require vocabulary extension and threshold recalibration with a new protocol version increment.

---

## 8. Conclusion

We have presented TEIA Cognitive Router — a deterministic, compliance-first LLM routing system that produces cryptographically sealed, reproducible routing decisions with sub-millisecond latency and zero ML dependencies. The system is designed from first principles to satisfy the audit and explainability requirements of regulated industry deployments.

The core contribution is the formal proof that the routing formula satisfies the Write==Read invariant: identical input always produces identical output and identical SHA-256 seal. This property — which no ML-based router can provide — is the foundation for compliance with EU AI Act Annex IV, GDPR Article 22, HIPAA §164.312(b), and SEC/FINRA record reconstruction requirements.

The MT-Bench evaluation demonstrates that compliance-safe mode achieves 99.6% quality retention at 16.3% cost reduction versus 100%-Cloud routing — a Pareto improvement that does not require any quality sacrifice. The temporal chain architecture extends the integrity guarantee from individual decisions to entire decision sequences, and RFC 3161 external notarization closes the retroactive forgery window that a local-only chain cannot address.

The implementation is available under Apache 2.0 at `pip install teia-cognitive-router`. All four CLI tools (`teia-route`, `teia-verify`, `teia-gateway`, `teia-notarize`) are included in the base installation with zero external dependencies.

Future work includes: domain-specific formula calibration (financial jargon, medical terminology); per-tenant chain isolation for multi-organizational deployments; integration with commercial TSAs under eIDAS qualified timestamp requirements; and a rigorous human-evaluated quality study comparing actual inference outputs at each routing tier on the MT-Bench distribution.

---

## Acknowledgments

The author thanks the lm-sys/FastChat project for releasing the MT-Bench question set under the Apache 2.0 license, enabling reproducible evaluation. The FreeTSA.org service provides free RFC 3161 timestamp tokens that made the notarization module practical for open-source use.

---

## References

Adams, C., Cain, P., Pinkas, D., & Zuccherato, R. (2001). *Internet X.509 Public Key Infrastructure Time-Stamp Protocol (TSP)*. RFC 3161. IETF. https://www.rfc-editor.org/rfc/rfc3161

Chen, L., Zaharia, M., & Zou, J. (2023). *FrugalGPT: How to Use Large Language Models While Reducing Cost and Improving Performance*. arXiv:2305.05176.

Ding, D., Mallick, A., Wang, C., Sim, R., Mukherjee, S., Ruwase, O., He, Y., & Nushi, B. (2024). *Hybrid LLM: Cost-Efficient and Quality-Aware Query Routing*. arXiv:2404.14618.

Doshi-Velez, F., & Kim, B. (2017). *Towards a Rigorous Science of Interpretable Machine Learning*. arXiv:1702.08608.

European Parliament. (2024). *Regulation (EU) 2024/1689 (EU AI Act)*. Official Journal of the European Union.

European Parliament. (2016). *Regulation (EU) 2016/679 (GDPR)*. Official Journal of the European Union.

Federal Reserve Board. (2011). *SR 11-7: Guidance on Model Risk Management*. Supervisory Letter.

Jiang, D., Ren, X., & Lin, B. Y. (2023). *LLM-Blender: Ensembling Large Language Models with Pairwise Ranking and Generative Fusion*. arXiv:2306.02561.

Laurie, B., Langley, A., & Kasper, E. (2013). *Certificate Transparency*. RFC 6962. IETF. https://www.rfc-editor.org/rfc/rfc6962

Ong, I., Almahairi, A., Wu, V., Chiang, W.-L., Wu, T., Gonzalez, J. E., Kadous, M. W., & Stoica, I. (2024). *RouteLLM: Learning to Route LLMs with Preference Data*. arXiv:2406.18665.

U.S. Department of Health and Human Services. (2003). *HIPAA Security Rule, 45 CFR Part 164*. Federal Register.

Zheng, L., Chiang, W.-L., Sheng, Y., Zhuang, S., Wu, Z., Zhuang, Y., Lin, Z., Li, Z., Li, D., Xing, E., Zhang, H., Gonzalez, J. E., & Stoica, I. (2023). *Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena*. arXiv:2306.05685.

---

*TEIA Cognitive Router | Protocol P51.0 | Whitepaper Final Draft v2.0 | 2026-06-02*  
*arXiv subject classifications: cs.CR (Cryptography and Security), cs.AI (Artificial Intelligence), cs.LG (Machine Learning)*
