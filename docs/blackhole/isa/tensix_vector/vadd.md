# `vadd` – Vector Add (SFPU)

**Category:** SFPU Vector Arithmetic

**SFPU mnemonic:** `SFPADD`

**Syntax:** `SFPADD VA, VB, VC, VD, Mod1` where VA=10

**Operation:** `for lane in 0..31: VD[lane] = ±(1.0 × VB[lane]) ± VC[lane]`

Performs elementwise FP32 addition of two source vectors. The sign of VB and VC is controlled by Mod1.

**x86 Equivalent:** `vaddps` (AVX2), `vaddpd`

**Latency:** 2 cycles (pipelined)

**IPC:** 1

**Example:**
```asm
SFPADD 10, 1, 2, 0, 0   ; LReg[0] = LReg[1] + LReg[2]
```

**Mod1:**
| Bit | Constant | Description |
|-----|----------|-------------|
| 0 | `SFPMAD_MOD1_NEGATE_VA` (1) | Negate VA before MAD (new in Blackhole) |
| 1 | `SFPMAD_MOD1_NEGATE_VC` (2) | Negate VC before MAD (new in Blackhole) |
| 2 | `SFPMAD_MOD1_INDIRECT_VA` (4) | VA = LReg[7].u32 & 15 instead of instruction field |
| 3 | `SFPMAD_MOD1_INDIRECT_VD` (8) | VD = LReg[7].u32 & 15 instead of instruction field (if VD != 16) |

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

**Notes:**
- When VA != 10, use `SFPMAD` instead
- Executes on the MAD sub-unit of the SFPU
- IEEE754 conformance except denormals are flushed to zero
- 16-byte alignment required for LReg operands
