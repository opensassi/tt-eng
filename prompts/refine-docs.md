# Refine Documentation — Process for Responding to Feedback

## §1 Objective

Process feedback on `docs/blackhole/` by recursively loading the modular documentation tree, evaluating each claim in the feedback against the files and the source ISA documentation, and producing a structured response with any needed corrections.

## §2 Entry Point

Read these files in order:

1. `docs/blackhole/06_instruction_set_index.md` — the master index of all ISA files
2. The specific file(s) mentioned in the feedback (if any)
3. Any `isa/<category>/<file>` cross-referenced by the index for claims about instructions

## §3 Modular Decomposition Walkthrough

For each distinct claim in the feedback, trace the modular chain:

**Step 1 — Identify the affected doc category**

| Feedback mentions | Load this first |
|------------------|-----------------|
| Chip composition, tile types, dataflow philosophy | `01_architecture_overview.md` |
| Core components: RISC-V, SFPU, FPU, L1, pipeline | `02_tensix_core_deep_dive.md` |
| L2CPU clusters, boot flow, control plane | `03_l2cpu_and_system_control.md` |
| DRAM, L1, L0, address spaces, alignment | `04_memory_hierarchy.md` |
| NoC topology, routing, CBs, ordering, semaphores | `05_noc_and_communication.md` |
| An instruction mnemonic, x86 equivalent, or ISA category | `06_instruction_set_index.md` → then `isa/<cat>/<file>.md` |
| Cycle counts, bandwidth, latency, bottlenecks | `07_performance_characteristics.md` |
| Pipeline stage placement, L1 budgeting, mapping examples | `08_workload_mapping_guide.md` |

**Step 2 — Load the top-level file**

Read the identified `.md` file in full. Note all cross-references it makes to `isa/` subdirectory files.

**Step 3 — Load linked ISA detail files**

For every instruction or topic referenced in the feedback claim, read the corresponding `isa/<category>/<file>.md` file. Confirm the claim against the detail file's content.

**Step 4 — Cross-reference with source documentation**

If the claim contradicts the docs or the docs lack information the feedback expects, verify against the source ISA documentation:

- `external/tt-isa-documentation/BlackholeA0/` — Blackhole-specific content
- `external/tt-isa-documentation/WormholeB0/` — shared content where Blackhole docs delegate (e.g., MatrixUnit, L1 memory map details)

Search the source for specific numbers (latency, bandwidth, register addresses, instruction encodings) that may not have been captured in the docs.

**Step 5 — Classify the gap**

| Classification | Meaning | Action |
|----------------|---------|--------|
| ✅ Covered | Claim is already addressed in docs | Cite file + line |
| ⚠️ Partially | Addressed but incomplete | Add missing details to existing file |
| ❌ Missing | Not documented anywhere | Create new content in appropriate file |
| 🔴 Incorrect | Docs contain wrong information | Correct the file |
| 📡 Unverifiable | Claim cannot be confirmed from source ISA docs | Note "not specified in source" |

## §4 Response Format

For each distinct claim in the feedback, produce:

```
### Claim: <verbatim quote from feedback>

**Category**: coverage / correctness / missing
**Files checked**: <list of file paths>
**Status**: ✅ Covered / ⚠️ Partially / ❌ Missing / 🔴 Incorrect / 📡 Unverifiable

**Response**:
<explanation of what the docs say, what the feedback expects,
 and whether a change is needed>

Examples:
  - "The claim is already addressed in `docs/blackhole/05_noc_and_communication.md` lines 11-12. No change required."
  - "The x86 equivalent for `SFPGT` is listed as `vcmpps` with GT predicate, matching the feedback. Already covered."

**Action taken**: <none / updated file X / added file Y / created new file Z>
```

If no action was needed for any claim, end with:
```
**Summary**: All claims verified. No changes required.
```

If changes were made, end with:
```
**Summary**: N changes made across M files.
- <file1>: <brief description of change>
- <file2>: <brief description of change>
```

## §5 File Reference — Dependency Map

```
┌─────────────────────────┬──────────────────────────────────────────┐
│ Feedback topic          │ Files to load                            │
├─────────────────────────┼──────────────────────────────────────────┤
│ Architecture overview   │ 01_architecture_overview.md              │
│ Tensix pipeline / cores │ 02_tensix_core_deep_dive.md             │
│ L2CPU / control plane   │ 03_l2cpu_and_system_control.md          │
│ Memory hierarchy        │ 04_memory_hierarchy.md                  │
│ NoC / CBs / routing     │ 05_noc_and_communication.md             │
│ ISA instruction / x86   │ 06_instruction_set_index.md             │
│                         │ → isa/tensix_vector/<file>.md           │
│                         │ → isa/tensix_matrix/<file>.md           │
│                         │ → isa/data_movement/<file>.md           │
│                         │ → isa/circular_buffer/<file>.md         │
│ Performance numbers     │ 07_performance_characteristics.md       │
│ Workload / pipeline map │ 08_workload_mapping_guide.md            │
│ Configuration           │ isa/configuration/README.md             │
│ Synchronization         │ isa/synchronization/README.md           │
│ Unpacker / Packer       │ isa/unpacker/README.md                  │
│                         │ isa/packer/README.md                    │
│ Scalar ops / misc       │ isa/misc/README.md                      │
└─────────────────────────┴──────────────────────────────────────────┘
```

## §6 Source Verification Checklist

For each data point in the feedback, run through these checks:

- [ ] Is the claim about a documented **value** (latency, bandwidth, capacity)?
  → Check `07_performance_characteristics.md` for the number
  → If missing, check `external/tt-isa-documentation/BlackholeA0/` source
  → If ambiguous, check `external/tt-isa-documentation/WormholeB0/` (shared content)

- [ ] Is the claim about an **instruction** (mnemonic, syntax, latency, x86 equivalent)?
  → Check `06_instruction_set_index.md` for the instruction row
  → Load the linked `isa/<category>/<file>.md` for the detail
  → If latency not in our doc, check the source `.md` in `external/tt-isa-documentation/BlackholeA0/`

- [ ] Is the claim about the **programming model** (kernel structure, CBs, NoC API)?
  → Check `02_tensix_core_deep_dive.md` + `05_noc_and_communication.md`

- [ ] Is the claim about **workload mapping** (stage placement, L1 budgeting)?
  → Check `08_workload_mapping_guide.md`

- [ ] Is the claim about a **chip specification** (core count, memory size, frequency)?
  → Check `01_architecture_overview.md` for the high-level number
  → Verify against `external/tt-isa-documentation/BlackholeA0/README.md`

## §7 Update Protocol

If a gap is found that requires a change:

1. **Update the affected `.md` file** — make the minimal change needed. Never delete existing content unless it is proven incorrect by the source documentation; only append or correct. For instruction files, follow the existing template (syntax, operation, latency, x86 equivalent, notes). If the instruction lacks an **Example:** section, add a minimal code snippet using `asm volatile(...)` syntax as used in TT-Metalium kernels, placed in a dedicated `**Example:**` section.

2. **If adding a new instruction file**:
   - Write the file to the appropriate `isa/<category>/` directory
   - Register it in `06_instruction_set_index.md` with the correct table row
   - Follow the batching convention of the category: some files cover a single instruction (e.g., `sfp-and.md`), others batch related instructions with different x86 equivalents into separate files (e.g., `vadd.md` contains `SFPADD` while `vsub.md` contains the sign-variant). Check existing files in the same category to determine the convention.

3. **If fixing an incorrect value**:
   - Cite the source file from `external/tt-isa-documentation/` in a comment or note
   - Only change the value if the source ISA documentation supports the correction

4. **Re-verify cross-references**:
   - Every file in `isa/` must be referenced from `06_instruction_set_index.md`
   - Every link in `06_instruction_set_index.md` must resolve to a real file
   - Run the cross-reference check from the project root:
     ```bash
     cd docs/blackhole
     grep -oP 'isa/[a-z0-9_/-]+\.md' 06_instruction_set_index.md | sort -u | while read f; do test -f "$f" || echo "BROKEN: $f"; done
     ```

5. **Flag for human review** if the source ISA documentation was ambiguous, contradictory, or missing the specific data point.

## §8 Gap Prioritisation

When feedback raises multiple issues, fix them in this order:

| Priority | Category | Examples |
|----------|----------|----------|
| 🔴 High | Syntax/operand errors, missing essential instructions, incorrect performance numbers | Wrong latency value, missing instruction, incorrect register name |
| 🟡 Medium | Missing examples, incomplete x86 equivalents, unclear descriptions | No code snippet, ambiguous x86 mapping, missing notes |
| 🟢 Low | Formatting, cross-reference styling, section ordering | Inconsistent heading style, broken intra-doc link, table alignment |

Within the same priority tier, fix issues in the order they appear in the feedback.
