# `SFPIADD` – Vector Integer Add

**Category:** SFPU Integer Arithmetic

**Syntax:** `SFPIADD Imm12, VC, VD, Mod1`

**Operation:** `for lane in 0..31: VD[lane] = VC[lane] ± VD[lane]` or `VD = VC ± Imm12`

32-bit two's complement integer addition or subtraction with lane flags output.

**x86 Equivalent:** `vpaddd`

**Latency:** 1 cycle, IPC=1

## Operands

### Mod1 (composite: ARG | CC)

`Mod1` is a composite of two sub-fields: `ARG` (bits 0-1) selects the operation mode, `CC` (bits 2-3) controls `LaneFlags` behavior.

| Field | Bits | Constant | Value | Description |
|-------|------|----------|-------|-------------|
| ARG | 0-1 | `SFPIADD_MOD1_ARG_LREG_DST` | 0 | Add: `VD = VC + VD` |
| ARG | 0-1 | `SFPIADD_MOD1_ARG_IMM` | 1 | Add immediate: `VD = VC + SignExtend(Imm12)` |
| ARG | 0-1 | `SFPIADD_MOD1_ARG_2SCOMP_LREG_DST` | 2 | Subtract: `VD = VC - VD` |
| CC | 2-3 | `SFPIADD_MOD1_CC_LT0` | 0 | Set LaneFlags on result sign (negative=true); default |
| CC | 2-3 | `SFPIADD_MOD1_CC_NONE` | 4 | Leave LaneFlags unchanged |
| CC | 2-3 | `SFPIADD_MOD1_CC_GTE0` | 8 | Invert the sign check on LaneFlags |

`CC_LT0` is default (0) — LaneFlags set on result sign. `CC_NONE` leaves flags unchanged. `CC_GTE0` inverts the sign check.

### Constant Name Mapping

The shorthand constants used in examples map to canonical source constants as follows:

| Shorthand | Canonical Source Constant | Value |
|-----------|---------------------------|-------|
| `MOD_IADD_ADD` | `SFPIADD_MOD1_ARG_LREG_DST` | 0 |
| `MOD_IADD_IMM` | `SFPIADD_MOD1_ARG_IMM` | 1 |
| `MOD_IADD_SUB` | `SFPIADD_MOD1_ARG_2SCOMP_LREG_DST` | 2 |

**Example:**
```asm
SFPIADD 0, 1, 2, MOD_IADD_ADD   ; LReg[2] = LReg[1] + LReg[2]  (32-bit integer add)
SFPIADD 0, 1, 2, MOD_IADD_SUB   ; LReg[2] = LReg[1] - LReg[2]  (32-bit integer sub)
SFPIADD 42, 2, 0, MOD_IADD_IMM  ; LReg[0] = LReg[2] + 42       (add immediate)
