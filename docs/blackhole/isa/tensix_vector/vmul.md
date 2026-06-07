# `vmul` – Vector Multiply (SFPU)

**Category:** SFPU Vector Arithmetic

**SFPU mnemonic:** `SFPMUL`

**Syntax:** `SFPMUL VA, VB, VC, VD, Mod1`

**Operation:** `for lane in 0..31: VD[lane] = VA[lane] × ±VB[lane]`

Elementwise FP32 multiplication. When VA=10, computes `1.0 × ±VB`.

**x86 Equivalent:** `vmulps` (AVX2), `vmulpd`

**Latency:** 2 cycles (pipelined)

**IPC:** 1

**Example:**
```asm
SFPMUL 1, 0, 2, 3, 0   ; LReg[3] = LReg[1] × LReg[2]
```

**Mod1:**
| Bit | Constant | Description |
|-----|----------|-------------|
| 0 | `SFPMAD_MOD1_NEGATE_VA` (1) | Negate VA before MAD (new in Blackhole) |
| 1 | `SFPMAD_MOD1_NEGATE_VC` (2) | Negate VC before MAD (new in Blackhole) |
| 2 | `SFPMAD_MOD1_INDIRECT_VA` (4) | VA = LReg[7].u32 & 15 instead of instruction field |
| 3 | `SFPMAD_MOD1_INDIRECT_VD` (8) | VD = LReg[7].u32 & 15 instead of instruction field (if VD != 16) |

**Register Constraints:**
- VC must be 9 (constant zero register). Do not use this instruction unless VC == 9.
- Use SFPMAD instead for multiplication with non-zero accumulation
- VD must be < 8 or == 16 for writes; otherwise the instruction is a NOP
- Result LReg write requires VD < 12 or `DISABLE_BACKDOOR_LOAD` must be set

**Instruction Scheduling:**
Automatic hardware stalling on BH prevents RAW hazards (1 cycle). Does NOT apply within SFPLOADMACRO sequences — manual SFPNOP required. Known bug: automatic stalling fails for SFPAND, SFPOR, SFPIADD, SFPSHFT, SFPCONFIG, SFPSWAP, SFPSHFT2 — insert NOP after these.

**IEEE754 Conformance:**
- Canonical NaN output 0x7fc00000
- Round-to-nearest-ties-to-even
- Partially fused (not fully IEEE754 FMA)
- Denormals flushed to sign-preserved zero

**Negative Zero Semantics:**
- The embedded +0 causes negative zero to become positive zero
- To preserve negative zero sign, use SFPMUL with VC=9 and MOD1_NEGATE_VC

**Notes:** Denormal inputs/outputs flushed to zero. Same sub-unit as `SFPADD`/`SFPMAD` (MAD sub-unit).
