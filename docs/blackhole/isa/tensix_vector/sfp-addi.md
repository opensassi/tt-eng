# `SFPADDI` – Vector FP32 Add/Subtract Immediate

**Category:** SFPU FP32 Arithmetic

**Syntax:** `SFPADDI VD, Imm16, Mod1`

**Operation:** Lanewise FP32 `VD = BF16ToFP32(Imm16) ± VD` with MAD sub-unit semantics and Mod1-controlled operand modification.

**Latency:** 2 cycles, IPC=1

## Mod1 Encoding

| Bits | Constant                  | Value | Semantics                              |
|------|---------------------------|-------|----------------------------------------|
| 0    | —                         | 0     | Reserved (must be 0)                   |
| 1    | `SFPMAD_MOD1_NEGATE_VC`   | 2     | Negate accumulator before addition     |
| 2    | —                         | 4     | Reserved (must be 0)                   |
| 3    | `SFPMAD_MOD1_INDIRECT_VD` | 8     | Indirect VD via `LReg[7] & 15`         |
| 4–15 | —                         | —     | Reserved (must be 0)                   |

All reserved modifier bits must be zero; undefined behavior if set.

## Functional Model

```c
unsigned VC = VD;
lanewise {
  if (VD < 12 || LaneConfig[Lane].DISABLE_BACKDOOR_LOAD) {
    if (LaneEnabled) {
      float c = LReg[VC].f32;
      if (Mod1 & SFPMAD_MOD1_NEGATE_VC) c = -c;
      float d = BF16ToFP32(Imm16) * 1.0f + c;
      unsigned vd;
      if ((Mod1 & SFPMAD_MOD1_INDIRECT_VD) && VD != 16) {
        vd = LReg[7].u32 & 15;
      } else {
        vd = VD;
      }
      if (vd < 8 || vd == 16) {
        LReg[vd].f32 = d;
      }
    }
  }
}
