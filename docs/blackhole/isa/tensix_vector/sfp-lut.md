# `SFPLUT` – 8-Entry Linear Interpolation LUT

**Category:** SFPU Special Function

**Syntax:** `SFPLUT VD, Mod0`

**Operation:** 8-entry lookup table with linear interpolation:

```
i = {0, 1, 2} depending on magnitude of LReg[3]
VD = Lut8ToFp32(LReg[i] >> 8) * Abs(LReg[3]) + Lut8ToFp32(LReg[i])
```

The LUT base address and interpolation factor come from LReg registers.

**Implicit reads:** Reads LReg[0], LReg[1], LReg[2], LReg[3] (LUT entries) and LReg[7] (indirect VD). Not shown as explicit operands.

**Latency:** 2 cycles, IPC=1

**Usage:** Approximating functions (log, exp, sin, etc.) via piecewise-linear approximation with 8 entries.

**x86 Equivalent:** `vpermps` + `vfmadd213ps` sequence

**Mod0 constants:** `SFPLUT_MOD0_SGN_RETAIN = 4`, `SFPLUT_MOD0_INDIRECT_VD = 8`

**IEEE754 conformance:** Computation follows SFPMAD rules (see vmac.md): partially fused, denormals flushed, canonical NaN.

**Example:**
```asm
; 8-entry piecewise-linear approx: LReg[2] = LUT(LReg[0])
SFPLUT 2, 0          ; LReg[2] = Lut8(LReg[0])  (LUT base pre-configured via SFPCONFIG)
```

**Notes:** `LReg[7]` provides indirect VD mode support.

**Scheduling:** WH: next cycle must not read SFPLUT destination — insert SFPNOP. BH: automatic stalling as per SFPMAD.
