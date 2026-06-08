# `SFPARECIP` – Approximate Reciprocal and Exponential

**Category:** SFPU Special Function (new in Blackhole)

**Syntax:** `SFPARECIP VB, VC, VD, Mod1`

**Backend:** SFPU simple sub-unit

## Modes

| Mode | Operation |
|------|-----------|
| Reciprocal | `VD = Approx(1.0 / VC)` |
| Conditional | `VD = (VB (as int32) < 0) ? Approx(1.0 / Abs(VC)) : VC` |
| Exponential | `VD = Approx(e^Abs(VC)) × (VC <= -0 ? -1 : +1)` |

## Mod1 Constants

| Constant | Value | Mode |
|----------|:-----:|------|
| `SFPARECIP_MOD1_RECIP` | 0 | Reciprocal |
| `SFPARECIP_MOD1_COND_RECIP` | 1 | Conditional Reciprocal |
| `SFPARECIP_MOD1_EXP` | 2 | Exponential |
| Reserved (3–15) | 3–15 | Defaults to EXP (NonContractualBehavior) |

## Approximation Accuracy

**Reciprocal:** `0.9944 × 1/x < ApproxRecip(x) < 1.0054 × 1/x` for 2^-126 ≤ x < 2^126. ApproxRecip(1.0) = 0.99609375.

**Exponential:** `0.9922 × e^x < ApproxExp(x) < 1.016 × e^x` for 0 ≤ x < 2. ApproxExp(1.0) = 2.703125.

## Range Limits

- **Recip:** Input < 2^-126 → Inf; input ≥ 2^126 → 0.
- **Exp:** Input < 2^-126 → 1.0; input ≥ 2 → not useful (software strongly discouraged).

## Sign Handling per Mode

- **RECIP:** Sign removed, re-joined.
- **COND_RECIP:** Sign removed, NOT re-joined (produces only positive results).
- **EXP:** Sign removed, re-joined (gives sign(x) × e^|x|, not e^x).

## Edge Cases

| Condition | RECIP | COND_RECIP | EXP |
|-----------|-------|------------|-----|
| NaN input | 0 (or -0) | 0 | 0 (or -0) |
| Denormal (< 2^-126) | ±Inf | +Inf | +1.0 (positive denormal), −1.0 (negative denormal) |
| +0 | +Inf | +Inf¹ | +1.0 |
| −0 | −Inf | +Inf¹ | −1.0 |

¹ COND_RECIP only approximates when VB (as int32) < 0; otherwise VC is passed through unmodified.

## VD Constraint

VD must be < 8 or == 16. Read registers must satisfy VD < 12 or DISABLE_BACKDOOR_LOAD.

## Notes

- **Gated by LaneEnabled:** The operation is enabled per lane by the LaneEnabled signal.
- **Blackhole auto-stall:** The Blackhole pipeline handles data hazards with automatic stall insertion. No explicit NOP scheduling is required for operand readiness in most cases.
- **RAW hazards:** When reading a destination register that was written by a previous SFPU instruction, the programmer must ensure the write has completed. Auto-stall may not cover all RAW hazard scenarios across different functional units.
- **SFPLOADMACRO:** Instructions that load from LReg via SFPLOADMACRO mechanisms may require NOPs to complete before the loaded value is available for consumption by SFPARECIP. Refer to SFPLOADMACRO documentation for the required NOP count.
- **Reserved Mod1 values:** Mod1 values 3–15 silently default to EXP behavior. Software must not rely on this mapping as it may change in future architectures (NonContractualBehavior).

## Future Portability

Future architectures might change approximation formulas. Portable software should not rely on exact bit patterns.

**Latency:** 1 cycle, IPC=1

**New in Blackhole** — not available on Wormhole.

**x86 Equivalent:** `vrcp14ps` / `vexp2ps`

**See also:** SFPU unit documentation, SFPLOADMACRO constraints guide.

**Examples:**
```asm
SFPARECIP 0, 1, 2, SFPARECIP_MOD1_RECIP        ; LReg[2] = Approx(1.0 / LReg[1])
SFPARECIP 4, 1, 2, SFPARECIP_MOD1_COND_RECIP    ; LReg[2] = (LReg[4].i32 < 0) ? Approx(1.0 / Abs(LReg[1])) : LReg[1]
SFPARECIP 0, 1, 2, SFPARECIP_MOD1_EXP          ; LReg[2] = Approx(e^|LReg[1]|) × sign(LReg[1])
