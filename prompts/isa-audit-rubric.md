# ISA Documentation Audit Rubric

You are evaluating a generated ISA detail file against its official source documentation from `external/tt-isa-documentation/`. Your goal is to determine whether the generated file is complete, correct, and useful for an autonomous coding agent writing TT-Metalium kernels.

## Evaluation Categories

Check each category and flag any discrepancy, omission, or error. If a category is fully satisfied, skip it.

---

### 1. Syntax & Operands

- Does the syntax line match the source? Check operand count, order, and names.
- Are Mod0/Mod1 fields documented with their constant names and numeric values?
- Are reserved or undefined modifier values documented as triggering NonContractualBehavior?
- Does the syntax match the actual instruction encoding (e.g., destructive 2-operand vs 3-operand)?

### 2. Operation Semantics

- Does the functional model match the source? Check for simplifications that change meaning.
- Is the exact computation described (e.g., `VD = VA × VB + VC` vs `VD += VC × Imm16`)?
- Are there hidden operations (e.g., `+ 0` that converts negative zero to positive zero)?

### 3. Register Constraints

- Which LReg indices are valid for VD? (typically `VD < 8 || VD == 16`)
- Which LReg indices are valid for reads? (`VD < 12 || DISABLE_BACKDOOR_LOAD`)
- Are there special read-only registers? (LReg[8]=0.8373, LReg[9]=0, LReg[10]=1.0)
- Is operation gated by LaneEnabled per lane?
- Are there indirect addressing modes using LReg[7]?

### 4. Scheduling Restrictions

- Does hardware auto-stall for RAW hazards? (Blackhole-specific)
- Are there known bugs where auto-stalling fails? (SFPAND, SFPOR, SFPIADD, SFPSHFT, SFPCONFIG, SFPSWAP, SFPSHFT2)
- Does auto-stall apply inside SFPLOADMACRO sequences? (No — manual SFPNOP required)
- Are there Wormhole-specific NOP requirements that differ from Blackhole?
- Is there a Dst read-after-write hazard? (≥3 instructions gap for Matrix Unit writes)
- Are there per-mode scheduling restrictions? (SFPSHFT2 modes have different constraints)

### 5. Known Bugs & Errata

- NonContractualBehavior — reserved modifier values, undocumented behavior
- Specific silicon bugs with workarounds (e.g., FP16_3ENTRY_TABLE writes wrong destination)
- RDCFG hardware bug (multiple threads silently dropped)
- CLEARDVALID Reset mode = UnsupportedFunctionality (GitHub #22383)
- SFPSTOCHRND rounding bugs (specific FP32 values that break RZ mode)
- MOP Template 1 bug (OuterCount += 128 under specific conditions)
- Any `UnsupportedFunctionality()`, `UndefinedBehavior()`, or `NonContractualBehavior` markers

### 6. IEEE754 & Edge Cases

- NaN handling — canonical NaN output pattern (0x7fc00000)? NaN passthrough?
- Denormal handling — flushed to zero? flushed to sign-preserved zero?
- Rounding mode — round-to-nearest-ties-to-even? stochastic? round-to-zero?
- Negative zero — preserved, converted to positive, or depends on mode?
- Overflow/saturation behavior — clamped? wrapped? saturated to max?
- Precision limits — FP16 mantissa bits discarded? INT8 range -255..+255?

### 7. Configuration Requirements

- Does the instruction require prior SFPCONFIG?
- Does it depend on ThreadConfig fields? (ALU_ACC_CTRL, FIDELITY_BASE, etc.)
- Does it depend on ConfigState fields? (DEST_REGW_BASE, ALU_FORMAT_SPEC_REG, etc.)
- Are fidelity phases required? How many for full precision?
- Does it interact with LaneConfig bits? (DISABLE_BACKDOOR_LOAD, BLOCK_DEST_WR_FROM_SFPU, etc.)

### 8. Performance Characteristics

- Latency in cycles (pipelined or not)
- IPC (instructions per cycle) for throughput
- TFLOP/s or TOP/s for vector/matrix unit instructions
- Fidelity phase impact on throughput
- Sub-unit occupancy (which sub-unit, can it be parallelized with other instructions?)

### 9. Backend Sub-Unit

- Which SFPU sub-unit executes this instruction? (simple, MAD, round, load, store)
- Can it be scheduled alongside other instructions via SFPLOADMACRO?
- Are there conflicts with other instructions on the same sub-unit?

### 10. Blackhole vs Wormhole Differences

- Is this instruction new in Blackhole?
- Are modifier bits that are reserved on Wormhole now meaningful on Blackhole?
- Are there behavior differences? (auto-stall, negative zero handling, NaN ordering)
- Are there instruction encodings that are UnsupportedFunctionality on Blackhole?

### 11. Completeness for Code Generation

- Is there at least one working assembly example?
- Does the example use correct operand order and register indices?
- Are all necessary preconditions documented? (UNPACR before MVMUL, SFPCONFIG before SFPLOADMACRO)
- Are error conditions or undefined behavior documented?
- Does the file cross-reference related instructions or configuration?

### 12. Missing Source Documentation

- If the source file does not exist in `external/tt-isa-documentation/`, recommend one of:
  - `keep` — instruction exists but source is elsewhere (e.g., TT-Metalium API)
  - `stub` — instruction likely exists but details unknown; flag for manual review
  - `delete` — instruction doesn't exist on Blackhole Tensix

## Output Format

Return a JSON object with these keys:

```json
{
  "status": "PASS" | "MINOR_ISSUES" | "MISSING_CRITICAL" | "WRONG",
  "issues": [
    {
      "category": "<category name from above>",
      "severity": "high" | "medium" | "low",
      "finding": "<what is wrong or missing>",
      "source_truth": "<what the source actually says>",
      "fix": "<what to change in the generated file>"
    }
  ],
  "missing_sections": ["Syntax", "Example", "Latency", "Notes"],
  "suggested_example": "<assembly snippet if missing>",
  "suggested_syntax": "<corrected syntax line if wrong>",
  "suggested_latency": "<latency value if missing>",
  "suggested_notes": "<notable errata, restrictions, or edge cases>",
  "see_also": ["<related instruction files>"],
  "confidence": "high" | "medium" | "low"
}
```

If the file is fully correct, return `"status": "PASS"` with an empty `issues` array.

## Prerequisites for Use

This rubric is designed to be used with:
1. The generated ISA detail file (under `docs/blackhole/isa/`)
2. The corresponding source file(s) (under `external/tt-isa-documentation/`)
3. Supporting files: `LReg.md`, `Dst.md`, `SrcASrcB.md`, `RWCs.md`, `VectorUnit.md`, `MatrixUnit.md`, `ScalarUnit.md`

Both the generated file content and the source file content will be provided in the evaluation prompt.
