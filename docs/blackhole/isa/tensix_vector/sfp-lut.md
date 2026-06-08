# `SFPLUT` – 8-Entry Linear Interpolation LUT

**Category:** SFPU Special Function, MAD sub-unit

**Syntax:** `SFPLUT VD, Mod0`

**Operation:** 8-entry lookup table with linear interpolation, indexed by `Abs(LReg[3])`:

|Input Range|Computation|
|---|---|
|0.0 ≤ `Abs(LReg[3])` < 1.0|`VD = Lut8ToFp32(LReg[0] >> 8) * Abs(LReg[3]) + Lut8ToFp32(LReg[0])`|
|1.0 ≤ `Abs(LReg[3])` < 2.0|`VD = Lut8ToFp32(LReg[1] >> 8) * Abs(LReg[3]) + Lut8ToFp32(LReg[1])`|
|2.0 ≤ `Abs(LReg[3])`|`VD = Lut8ToFp32(LReg[2] >> 8) * Abs(LReg[3]) + Lut8ToFp32(LReg[2])`|

Optionally the sign bit of the result can be replaced with the original sign bit of `LReg[3]` (`SFPLUT_MOD0_SGN_RETAIN`). In indirect VD mode (`SFPLUT_MOD0_INDIRECT_VD`), the VD index comes from the low four bits of `LReg[7]`.

**Implicit reads:** Reads LReg[0], LReg[1], LReg[2] (coefficient tables), LReg[3] (lookup index), and LReg[7] (indirect VD). Not shown as explicit operands.

**Register Constraints:**
- **Write (VD):** Only `vd < 8` or `vd == 16` may be written; writes to other register indices are silently dropped.
- **Read enable:** Instruction executes only when `VD < 12 || LaneConfig[Lane].DISABLE_BACKDOOR_LOAD`.
- **Lane enable:** `LaneEnabled` must be set for the lane; otherwise the operation is skipped.

**Latency:** 2 cycles (inferred from SFPMAD rules), IPC=1

**Usage:** Approximating functions (log, exp, sin, etc.) via piecewise-linear approximation with 8 entries.

**x86 Equivalent:** `vpermps` + `vfmadd213ps` sequence

**Mod0 constants:** `SFPLUT_MOD0_SGN_RETAIN = 4`, `SFPLUT_MOD0_INDIRECT_VD = 8`

**IEEE754 conformance:** Computation follows SFPMAD rules (see vmac.md): partially fused, denormals flushed, canonical NaN.

**Example:**
```asm
; 8-entry piecewise-linear approx using coefficients in LReg[0..2] indexed by Abs(LReg[3])
SFPLUT 2, 0          ; LReg[2] = Lut8(Abs(LReg[3])) via coeffs LReg[0..2]
