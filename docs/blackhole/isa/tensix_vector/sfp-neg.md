# `SFPMOV` – Negate (Mode)

**Category:** SFPU Data Movement

**Syntax:** `SFPMOV 0, VC, VD, Mod1` (negate mode)

**Operation:** `for lane in 0..31: VD[lane] = -VC[lane]`

**Mechanism:** Negation is `x ^= 0x80000000` — flips the sign bit. No NaN or denormal special-casing. Works on both FP32 and sign-magnitude integers (sign is MSB for both).

**Mod1 encoding:** `SFPMOV_MOD1_NEGATE = 1`

**Combinability:** Can be ORed with ALL_LANES_ENABLED (Mod1=1|2=3)

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vxorps` with sign mask

**Example:**
```asm
SFPMOV 0, 0, 1, MOD_NEG   ; LReg[1] = -LReg[0]  (negate, SFPMOV with negate Mod1)
```
