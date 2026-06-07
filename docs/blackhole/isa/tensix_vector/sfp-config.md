# `SFPCONFIG` – SFPU Configuration

**Category:** SFPU Special

**Syntax:** `SFPCONFIG Imm16, VD, Mod1`

**Operation:** Set SFPU configuration from `Broadcast(LReg[0][0:8])` or `Imm16`.

**Broadcast:** Takes input from first 8 lanes of LReg[0], broadcasts vertically to 32 lanes.

## VD Target Table

| VD | Target | Source |
|----|--------|--------|
| 0-3 | LoadMacroConfig.InstructionTemplate[VD] | LReg[0] only (Imm16 ignored) |
| 4-7 | LoadMacroConfig.Sequence[VD-4] | Imm16 (if MOD1_IMM16_IS_VALUE) or LReg[0] |
| 8 | LoadMacroConfig.Misc | Imm16 or LReg[0]; Mod1[1:2] selects write/OR/AND/XOR |
| 9-10 | NonContractualBehavior (does nothing) | — |
| 11 | Write LReg[11] = -1.0f (0xBF800000) | Imm16 uses default; else LReg[0] |
| 12 | Write LReg[12] = 1/512 (0x3B000000) | Imm16 uses default; else LReg[0] |
| 13 | Write LReg[13] = -0.67487759f (0xBF2CC4C7) | Imm16 uses default; else LReg[0] |
| 14 | Write LReg[14] = -0.34484843f (0xBEB08FF9) | Imm16 uses default; else LReg[0] |
| 15 | LaneConfig (18 bits) | Imm16 or LReg[0]; Mod1[1:2] selects write/OR/AND/XOR |

## Mod1 Flags

| Value | Constant | Meaning |
|-------|----------|---------|
| 1 | MOD1_IMM16_IS_VALUE | Imm16 provides the value (when clear, value comes from LReg[0]) |
| 2 | MOD1_BITWISE_OR | Bitwise OR operation (for VD=8 or 15) |
| 4 | MOD1_BITWISE_AND | Bitwise AND operation (for VD=8 or 15) |
| 6 | MOD1_BITWISE_XOR | Bitwise XOR operation (for VD=8 or 15) |
| 8 | MOD1_IMM16_IS_LANE_MASK | Bits of Imm16 select which lanes participate |

## LaneConfig Bit Layout (18 bits)

| Bit | Name | Purpose |
|-----|------|---------|
| 0 | ENABLE_FP16A_INF | Controls SFPLOAD FP16 infinity interpretation |
| 1 | DISABLE_BACKDOOR_LOAD | Disables backdoor writes to LoadMacroConfig |
| 2 | ENABLE_DEST_INDEX | SFPSWAP does argmin/argmax vs min/max |
| 3 | CAPTURE_DEFAULT_DEST_INDEX | SFPLOAD captures Dst index |
| 4 | BLOCK_DEST_WR_FROM_SFPU | SFPSTORE skips Dst write |
| 5 | BLOCK_SFPU_RD_FROM_DEST | SFPLOAD skips LReg write |
| 6 | DEST_RD_COL_EXCHANGE | SFPLOAD loads from odd Dst columns |
| 7 | DEST_WR_COL_EXCHANGE | SFPSTORE stores to odd Dst columns |
| 8 | EXCHANGE_SRCB_SRCC | Inverts SFPSWAP comparison |
| 9-10 | BLOCK_DEST_MOV | Disables columns during MOVA2D/MOVB2D/MOVD2A/MOVD2B |
| 12-15 | ROW_MASK | Part of lane predication |

## Scheduling

If DISABLE_BACKDOOR_LOAD is changed, the next SFPU instruction might see old or new value. Insert SFPNOP after SFPCONFIG.

**Latency:** ≤ 2 cycles, IPC=1

**Example:**
```asm
; Write -1.0f to LReg[11] (default for VD=11 with MOD1_IMM16_IS_VALUE)
SFPCONFIG 0x0000, 11, MOD1_IMM16_IS_VALUE
```
