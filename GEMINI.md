# AION-RISPA-NDC Project Instructions

## Architectural Principles
- **Core Precedence (Invariante Supra):** 
  - P0 (Core Anexado/DNA_ESSENCIAL.txt) > P1 (Patches Aprovados) > P2 (Resumos da Sessão Delta-Mestre) > P3 (Modelos de Base).
  - Never contradict a higher precedence tier.

## Coding Standards & Workflow
- **Naming Constraints:** 
  - NEVER use the Greek Delta symbol (Δ/δ) in code, logs, or documentation. 
  - ALWAYS write the word "Delta" or "Delta-Mestre" by extenso.
- **HTTP Server Stability:**
  - All request handlers must be wrapped in absolute `try/finally` blocks.
  - Connection closure (`$ctx.Response.Close()`) is mandatory in the `finally` block to prevent `CLOSE_WAIT` socket blocking.
- **Offline AI Integration:**
  - Primary LLM Engine: Ollama.
  - Cognitive Core: `teia-supra-sensei` (derived from `deepseek-r1:14b`).
  - Strict adherence to the `Supra_Modelfile` logic for all AI-generated audits.

## System Components
- **PocketKernel:** Unified bootstrap for the AION-RISPA-NDC environment.
- **Watcher:** Monitors the `aion_restore_queue.jsonl` for automated processing.
