**Session ID:** 2026-06-07-isa-documentation-audit

**Date / Duration:** 2026-06-07; prompter active ≈ 3.5 hours

**Project / Context:**
Large-scale audit and enrichment of TT-Metalium Blackhole ISA documentation (62 instruction detail files). The session involved reading source ISA documentation, cross-referencing against generated docs, applying corrections via automated sub-agent audits, building a rubric-based audit pipeline using opencode session forking, and applying AI-driven fixes to all 62 detail files.

**Top-Level Component:**
62 ISA detail files under `docs/blackhole/isa/` audited and corrected, with two reusable pipeline scripts (`audit_isa_files.sh`, `apply_audit_fixes.sh`).

**Second-Level Modules:**
- ISA detail file enrichment: syntax, register constraints, scheduling, IEEE754, known bugs added to all 62 files
- Source-to-detail cross-reference mapping: heuristic mnemonic matching against `external/tt-isa-documentation/`
- `prompts/isa-audit-rubric.md`: 12-category evaluation rubric for deep ISA doc audit
- `scripts/audit_isa_files.sh`: parallel audit pipeline using opencode session forking
- `prompts/isa-audit-fixer.md`: fixer priming for AI-driven doc correction
- `scripts/apply_audit_fixes.sh`: parallel fix application from audit results
- Critical bug fixes: destructive operand corrections (16 files), MMIO vs L1 address space (2 files), signedness errors (3 files), IEEE754 conformance notes

**Prompter Contributions:**
- Defined the scope and methodology of the ISA documentation audit
- Identified gaps in the instruction detail files and requested specific enrichments
- Diagnosed script failures (session ID management, heredoc escaping, grep anchoring, ANSI stripping)
- Directed the architecture of the audit pipeline (rubric session → fork per file → JSON extraction)
- Made design decisions about MODE (clean vs incremental), PARALLEL_JOBS, session ID recording
- Reviewed intermediate outputs and course-corrected when pipelines produced bad results

**Model Contributions:**
- Executed 7 parallel sub-agent audits comparing 62 detail files against 100+ source files
- Identified and documented ~500+ issues (syntax errors, missing scheduling, register constraints, known bugs)
- Implemented the audit script with deterministic checks, ANSI stripping, JSON extraction
- Implemented the apply script with path decoding, markdown extraction, incremental skip
- Fixed 59/62 detail files with AI-generated corrections
- Created the 12-category rubric prompt and fixer priming prompt
- Designed and validated the reverse path naming scheme for result-to-original mapping

**Prompter Time Estimate:**
- Reading and digesting model responses: ~1.5 hours
- Thinking, strategizing, and weighing options: ~1.0 hours
- Writing messages and directives: ~1.0 hours
- **Total: 3.5 hours**

**Model-Equivalent SME Time Estimate:**
~40-60 hours of a senior systems engineer with Tenstorrent ISA expertise:
- Learning TT-Metalium ISA model from source docs: 8 hours
- Manual audit of 62 detail files against source: 20 hours
- Fixing syntax/register/IEEE754/scheduling issues: 15 hours
- Building audit/fix pipeline scripts: 8 hours
- Regression testing and validation: 5 hours

**Required SME Expertise:**
- Tenstorrent Blackhole/Wormhole Tensix ISA architecture
- SFPU vector unit pipeline and scheduling constraints
- Matrix/FPU unit operation and fidelity phases
- TT-Metalium kernel programming model (CBs, NoC, DMA)
- Bash scripting with GNU parallel and jq
- opencode session management and CLI tools
- Markdown documentation engineering for AI-assisted coding
- IEEE754 floating-point conformance and edge cases

**Aggregation Tags:**
ISA documentation, Tenstorrent, Blackhole, Tensix, instruction set architecture, automated audit, opencode, SFPU, FPU, pipeline automation, documentation generation

---
## Extracted Session Stats

- **Duration:** 16820s (280.3m)
  - First message: 19:30:34
  - Last message:  00:10:54
- **Messages:** 378 total (73 user, 305 assistant)
- **Tool call parts:** 356
- **Words:** 12,034 assistant, 6,577 user

### Tokens & Cost

| Metric | Value |
|--------|-------|
| Input Tokens — Total | 74,766,659 |
| Input Tokens — Cached | 73,581,824 (98.4%) |
| Input Tokens — Uncached | 1,184,835 |
| Output Tokens | 113,653 |
| Reasoning Tokens | 55,434 |
| Total Billed | 74,935,746 |
| Cost | $0.419250 |

### Tool Usage

| Tool      | Calls | % |
|------------|-------|---|
| bash      |   167 |  46.9% |
| read      |    96 |  27.0% |
| edit      |    51 |  14.3% |
| write     |    15 |   4.2% |
| task      |    14 |   3.9% |
| todowrite |     7 |   2.0% |
| grep      |     5 |   1.4% |
| glob      |     1 |   0.3% |

### Mode & Finish

| Mode | Count | % |
|------|-------|---|
| build | 203 | 66.6% |
| plan | 102 | 33.4% |

| Finish Reason | Count | % |
|---------------|-------|---|
| tool-calls | 242 | 81.8% |
| stop | 54 | 18.2% |

### Prompter Active Time (gap-based)

- **Prompter active:** 56.4m
- **Wall clock:** 280.3m
- **Idle/waiting:** 223.9m
- **Gaps >60s (capped):** 38 of 72

| Gap Range | Count |
|-----------|-------|
| 0-15s | 2 |
| 15-30s | 13 |
| 30-45s | 12 |
| 45-60s | 7 |
| >60s | 38 |
