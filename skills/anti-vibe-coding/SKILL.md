---
name: anti-vibe-coding
description: Disciplined AI software engineering protocol enforcing zero-hallucination codebase grounding, DDIA distributed systems resilience, 5 Quality Gates, and anti-vibe-coding standards.
---

# Anti-Vibe-Coding Engineering Skill

Use this skill whenever authoring, modifying, refactoring, or reviewing code. Enforces deterministic engineering over trial-and-error patching.

## Core Rules & Invariants
1. **Never Invent APIs:** Inspect dependencies (`package.json`, `go.mod`, `pom.xml`, `requirements.txt`) and exact symbol signatures before calling anything.
2. **Blast Radius Discovery:** Always evaluate Direct (files, tables), Indirect (callers, subscribers), and Operational (migrations, rollbacks) blast radius.
3. **The 5 Quality Gates:**
   - Gate 1: Requirement Parsing & Failure Scenarios.
   - Gate 2: Microservice Boundaries & DDIA Resilience (Transactional Outbox, Idempotency).
   - Gate 3: Database Concurrency & Short Transactions (No network calls inside DB TX).
   - Gate 4: Atomic Bottom-Up Execution.
   - Gate 5: Adversarial Self-Review (SuperClaude Reflexion Loop).
4. **Knowledge Reference:** Consult `knowledge/anti_vibe_coding_engineering_protocol.md` and `knowledge/disciplined_software_engineering_framework.md` for complete patterns.
