# `SFPLOADI` – Load Immediate to LReg

**Category:** SFPU Immediate

**Syntax:** `SFPLOADI VD, Mod0, Imm16`

**Operation (modes):**
- `Mod0 = 0 (SFPLOADI_MOD0_FLOATB): VD = BF16toFP32(Imm16)` — BF16 immediate to FP32
- `Mod0 = 1 (SFPLOADI_MOD0_FLOATA): VD = FP16toFP32(Imm16)` — FP16 immediate to FP32
- `Mod0 = 2 (SFPLOADI_MOD0_USHORT): VD = ZeroExtend(Imm16)` — 16-bit zero-extended
- `Mod0 = 4 (SFPLOADI_MOD0_SHORT): VD = SignExtend(Imm16)` — sign-extended 16-bit
- `Mod0 = 8 (SFPLOADI_MOD0_UPPER): VD.High16 = Imm16, VD.Low16 preserved` — replace upper 16 bits, preserve lower 16 bits
- `Mod0 = 10 (SFPLOADI_MOD0_LOWER): VD.Low16 = Imm16, VD.High16 preserved` — replace lower 16 bits, preserve upper 16 bits

**Mod0 reserved values:** 3, 5, 6, 7, 9, 11–15 hit `UndefinedBehavior()`.

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vmovaps` + `vbroadcastss`

Broadcasts a scalar immediate to all 32 lanes.

**Backend:** Vector Unit (SFPU), load sub-unit

**Example:**
```asm
SFPLOADI 2, 0, 0x3F80   ; LReg[2] = 1.0f  (SFPLOADI_MOD0_FLOATB, BF16 0x3F80 → FP32 1.0, all lanes)
SFPLOADI 3, 2, 100       ; LReg[3] = 100    (SFPLOADI_MOD0_USHORT, zero-extended 16-bit immediate, all lanes)
