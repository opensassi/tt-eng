# `SFPMOV` – Advance PRNG (Mode)

**Category:** SFPU PRNG

**Syntax:** `SFPMOV VD, Mod1` (PRNG mode)

**Operation:** `for lane in 0..31: VD[lane] = AdvancePRNG(lane)`

Advances a 32-bit LFSR PRNG per lane. Statistical properties are poor; software should build its own PRNG if high quality randomness is required.

```
uint32_t AdvancePRNG(unsigned Lane) {
  static uint32_t State[32];
  uint32_t Result = State[Lane];
  uint32_t Taps = __builtin_popcount(Result & 0x80200003);
  State[Lane] = (~Taps << 31) | (Result >> 1);
  return Result;
}
```

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** None
