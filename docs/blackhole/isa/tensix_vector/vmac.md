# `vmac` – Vector Multiply-Accumulate (SFPU)

**Category:** SFPU Vector Arithmetic

**SFPU mnemonic:** `SFPMAD`

**Syntax:** `SFPMAD VA, VB, VC, VD, Mod1`

**Operation:** `for lane in 0..31: VD[lane] = VA[lane] × ±VB[lane] ± VC[lane]`

Elementwise FP32 fused multiply-accumulate. The most general SFPU arithmetic instruction.

**x86 Equivalent:** `vfmadd231ps` / `vfmadd231pd` (AVX2 FMA)

**Latency:** 2 cycles (pipelined)

**IPC:** 1

**Example:**
```asm
SFPMAD 1, 2, 3, 0, 0   ; LReg[0] = LReg[1] × LReg[2] + LReg[3]
```

**Mod1:**
| Bit | Constant | Description |
|-----|----------|-------------|
| 0 | `SFPMAD_MOD1_NEGATE_VA` (1) | Negate VA before MAD (new in Blackhole) |
| 1 | `SFPMAD_MOD1_NEGATE_VC` (2) | Negate VC before MAD (new in Blackhole) |
| 2 | `SFPMAD_MOD1_INDIRECT_VA` (4) | VA = LReg[7].u32 & 15 instead of instruction field |
| 3 | `SFPMAD_MOD1_INDIRECT_VD` (8) | VD = LReg[7].u32 & 15 instead of instruction field (if VD != 16) |

**Indirect Addressing:**
- When `MOD1_INDIRECT_VA` is set, VA = LReg[7].u32 & 15
- When `MOD1_INDIRECT_VD` is set and VD != 16, VD = LReg[7].u32 & 15

**Register Constraints:**
- VD must be < 8 or == 16 for writes; otherwise the instruction is a NOP
- Result LReg write requires VD < 12 or `DISABLE_BACKDOOR_LOAD` must be set

**Instruction Scheduling:**
Automatic hardware stalling on BH prevents RAW hazards (1 cycle). Does NOT apply within SFPLOADMACRO sequences — manual SFPNOP required. Known bug: automatic stalling fails for SFPAND, SFPOR, SFPIADD, SFPSHFT, SFPCONFIG, SFPSWAP, SFPSHFT2 — insert NOP after these.

**IEEE754 Conformance:**
- Canonical NaN output 0x7fc00000
- Round-to-nearest-ties-to-even
- Partially fused (not fully IEEE754 FMA)
- Denormals flushed to sign-preserved zero

**Blackhole Upgrade:**
- `MOD1_NEGATE_VA` and `MOD1_NEGATE_VC` are new in Blackhole. On Wormhole, Mod1 bits 0-1 are reserved (NonContractualBehavior).

**Notes:**
- Has semantics between separate multiply/add and true FMA (not IEEE754 fused multiply-add conformant)
- Denormals flushed to zero
- Supports indirect VA/VD modes for non-uniform control flow
