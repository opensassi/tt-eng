# `SFPMOV` – Advance PRNG (Mode)

**Category:** Vector Unit (SFPU), simple sub-unit

**Syntax:** `SFPMOV VC, VD, Mod1` (PRNG mode: VC=9, Mod1 bit 3 set)

**Constants:**
- `SFPMOV_MOD1_FROM_SPECIAL = 8` — bit 3, triggers PRNG mode
- `SFPMOV_MOD1_ALL_LANES_ENABLED = 2` — bypasses per-lane enable gating

**Operation:** `for lane in 0..31: VD[lane] = AdvancePRNG(lane)`

Advances a 32-bit LFSR PRNG per lane. Statistical properties are poor; software should build its own PRNG if high quality randomness is required.

