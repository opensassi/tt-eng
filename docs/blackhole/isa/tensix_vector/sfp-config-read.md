# `SFPMOV` – Read Configuration (Mode)

**Category:** SFPU Data Movement

**Syntax:** `SFPMOV 0, VC, VD, Mod1` (config read mode)

**Operation:** `for lane in 0..31: VD[lane] = ConfigValue(VC)`

Reads an SFPU configuration value from the register addressed by VC:

| VC value | Returns |
|----------|---------|
| 0-3 | LoadMacroConfig.InstructionTemplate[VC] |
| 4-7 | LoadMacroConfig.Sequence[VC-4] |
| 8 | LoadMacroConfig.Misc |
| 9 | AdvancePRNG() — advances PRNG state and returns previous value |
| 15 | LaneConfig (full 18-bit LaneConfig for this lane) |
| other | 0 |

**Mod1:** `SFPMOV_MOD1_FROM_SPECIAL = 8`. Can be combined with ALL_LANES_ENABLED (Mod1=8|2=10) to bypass lane mask.

**Register constraint:** VD must be < 8 or == 16

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** None (no vector read of FP control register in AVX)

**Example:**
```asm
SFPMOV 0, 9, 1, MOD_CFG_READ   ; LReg[1] = PRNG previous value, advances PRNG state
```
