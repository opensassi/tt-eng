**Session ID:** 2026-06-07-test-project-tenstorrent-llm-plan

**Date / Duration:** June 7, 2026; prompter active ≈ 3.5 hours

**Project / Context:**
Building a deterministic test harness for validating LLM agent capabilities in generating, testing, and optimizing TT-Metalium kernel code for Tenstorrent Blackhole hardware. The project uses ttsim (a full-system simulator) as the target backend, with a staged pipeline for environment bootstrap, kernel compilation, correctness testing, benchmarking, and iterative optimization.

**Top-Level Component:**
TT-Metalium LLM Agent Validation Pipeline — a full project with specification, stage scripts, evaluation tools, prompt templates, reference kernels, and comprehensive Blackhole architecture documentation.

**Second-Level Modules:**
- `technical-specification.md` — 7-section specification with architecture diagrams, JSON schema contracts, compile/link contract, and required runtime environment
- `AGENTS.md` — Pipeline guide with 9 sections covering environment setup, stage execution, kernel writing, mock agent testing, feedback loops, and error resolution
- Stage scripts — `run-stage.sh`, `stage[0-4]-run.sh` with compile→test→bench→archive workflow
- Evaluation framework — `parse-tt-npe.py`, `parse-perf.py`, `compare.py` for deterministic performance analysis
- Reference kernels — DRAM loopback and eltwise-addition kernels that compile and pass on real ttsim
- `docs/blackhole/` — 61 files, 2031 lines of Tenstorrent Blackhole architecture documentation covering all instructions, memory hierarchy, NoC topology, and workload mapping
- `config/` — stage definitions, hardware config with version pins, regression thresholds
- `prompts/` — LLM prompt templates for kernel generation and system context

**Prompter Contributions:**
- Defined the project scope and architecture decisions (stage pipeline, agent-driven iteration, A/B experiment archive)
- Provided design constraints (deterministic evaluation, two feedback loops, mock agent for CI)
- Supplied the Tenstorrent plan and reference documentation links (ttsim, tt-metal, tt-isa-documentation)
- Debugged build issues (ulimit, MPI initialization, env vars)
- Reviewed and refined documentation structure and ISA reference completeness
- Provided feedback on x86 equivalency batching vs. individual instruction files

**Model Contributions:**
- Drafted the full `technical-specification.md` with architecture diagrams, sequence diagrams, D3 visualization, and testing requirements
- Created all 30+ stage and utility scripts (compile, env-check, mock agent, flamegraph generation)
- Wrote reference kernels using the modern `tt-metalium` MeshDevice API
- Built and tested compilation against tt-metal with correct include/link flags extracted from the build system
- Debugged 12 distinct errors (API version mismatch, missing firmware directories, CPM cache paths, MPI linking, bfloat16 precision, etc.)
- Produced 61-file Blackhole architecture documentation from ISA source
- Created `prompts/refine-docs.md` — a process prompt for recursively loading modular documentation and responding to structured feedback

**Prompter Time Estimate:**
- Reading and digesting model responses: ~1.5 hours (24000+ words at 250 wpm × 1.2 overhead)
- Thinking, strategizing, and weighing options: ~1.0 hours
- Writing messages and directives: ~1.0 hours (9000+ words at ~150 wpm)
- **Total: 3.5 hours**

**Model-Equivalent SME Time Estimate:**
Approximately 40-60 hours of senior engineer / architect time:
- Project architecture and pipeline design: 6 hours
- tt-metal/toolchain environment setup and debugging: 8 hours
- Stage script implementation (compile/test/bench/archive): 6 hours
- Evaluation framework (Python tools): 4 hours
- Reference kernel development and debugging: 6 hours
- Technical specification documentation: 8 hours
- Blackhole ISA documentation (61 files): 12-16 hours
- Prompt template design: 2 hours
- Testing and integration: 4 hours

**Required SME Expertise:**
- TT-Metalium C++ API and programming model
- Tenstorrent Blackhole architecture (Tensix cores, NoC, SFPU, circular buffers)
- Linux system administration and build toolchain (cmake, MPI, shared library linking)
- Python development for evaluation tooling
- C++ cross-compilation for RISC-V firmware targets
- Simulation/debug of accelerator hardware
- Technical writing for hardware documentation

**Aggregation Tags:**
tt-metalium, tenstorrent, blackhole, ttsim, kernel-generation, llm-validation, test-harness, c++, risc-v, simd, isa-documentation, ci-pipeline

---
## Extracted Session Stats

- **Duration:** 20292s (338.2m)
  - First message: 13:41:04
  - Last message:  19:19:16
- **Messages:** 354 total (29 user, 325 assistant)
- **Tool call parts:** 444
- **Words:** 8,631 assistant, 9,711 user

### Tokens & Cost

| Metric | Value |
|--------|-------|
| Input Tokens — Total | 79,758,531 |
| Input Tokens — Cached | 77,977,472 (97.8%) |
| Input Tokens — Uncached | 1,781,059 |
| Output Tokens | 157,384 |
| Reasoning Tokens | 40,953 |
| Total Billed | 79,956,868 |
| Cost | $0.523220 |

### Tool Usage

| Tool      | Calls | % |
|------------|-------|---|
| bash      |   179 |  40.3% |
| write     |   116 |  26.1% |
| edit      |    72 |  16.2% |
| read      |    54 |  12.2% |
| todowrite |    14 |   3.2% |
| glob      |     3 |   0.7% |
| webfetch  |     2 |   0.5% |
| question  |     2 |   0.5% |
| grep      |     2 |   0.5% |

### Mode & Finish

| Mode | Count | % |
|------|-------|---|
| build | 293 | 90.2% |
| plan | 32 | 9.8% |

| Finish Reason | Count | % |
|---------------|-------|---|
| tool-calls | 297 | 91.7% |
| stop | 27 | 8.3% |

### Prompter Active Time (gap-based)

- **Prompter active:** 23.1m
- **Wall clock:** 338.2m
- **Idle/waiting:** 315.1m
- **Gaps >60s (capped):** 15 of 28

| Gap Range | Count |
|-----------|-------|
| 15-30s | 4 |
| 30-45s | 5 |
| 45-60s | 4 |
| >60s | 15 |
