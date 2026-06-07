# `SFPLUTFP32` – FP32 Lookup Table

**Category:** SFPU Special Function

**Syntax:** `SFPLUTFP32 VD, Mod1`

## Modes

1. **Interpolated**: `VD = LReg[i] * Abs(LReg[3]) + LReg[4+i]`
   Where `i = {0,1,2}` based on magnitude of `LReg[3]`.

2. **16-entry LUT**: Uses upper/lower 16 bits of LReg as index into 16-entry LUT with FP32 entries, with linear interpolation.

3. **Dual 16-entry LUT**: Two independent 16-entry lookups interpolated together.

**Latency:** 2 cycles, IPC=1

**x86 Equivalent:** `vpermps` + `vfmadd213ps`

**Example:**
```asm
; FP32 LUT with interpolation: LReg[4] = LReg[0] × Abs(LReg[3]) + LReg[4]
SFPLUTFP32 4, MOD_INTERP
```

**Mod1 constants:** FP32_INTERP=0, FP16_2ENTRY_TABLE=1, FP16_3ENTRY_TABLE=2, DUAL_FP16_TABLE=3

**Hardware bug (FP16_3ENTRY_TABLE, mode 2):** This mode is known to malfunction on certain Blackhole steppings. Use DUAL_FP16_TABLE (mode 3) as a workaround where possible.

## Mod1Mirror Scheduling

BH-specific: Mod1Mirror field controls automatic stalling. When INDIRECT_VD is set in Mod1Mirror, stalling assumes all-LReg reads/writes. When clear, assumes reads from all except LReg[7], writes to VD.

## FP16_3ENTRY_TABLE Conservatism

FP16_3ENTRY_TABLE conservatively reads LReg[4-6] even when unused. Workaround: disable automatic stalling.

## Lut16ToFp32 Conversion

Treats Exp=31→0, Exp=0→normalized (not IEEE754 compliant). See the BH/SFPLUTFP32.md conversion table for full details.

## IEEE754 Conformance

Computation follows SFPMAD rules (see vmac.md): partially fused, denormals flushed, canonical NaN.
