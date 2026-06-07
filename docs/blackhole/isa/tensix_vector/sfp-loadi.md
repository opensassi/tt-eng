# `SFPLOADI` – Load Immediate to LReg

**Category:** SFPU Immediate

**Syntax:** `SFPLOADI VD, Imm16, Mode`

**Operation (modes):**
- `VD = BF16ToFP32(Imm16)` — BF16 immediate to FP32
- `VD = FP16ToFP32(Imm16)` — FP16 immediate to FP32
- `VD = Imm16` — 16-bit zero-extended
- `VD = ±Imm15` — sign-extended 15-bit
- `VD.High16 = Imm16` — replace upper 16 bits
- `VD.Low16 = Imm16` — replace lower 16 bits

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vmovaps` + `vbroadcastss`

Broadcasts a scalar immediate to all 32 lanes.

**Example:**
```asm
SFPLOADI 2, 0x3F80, MOD_BF16   ; LReg[2] = 1.0f  (BF16 0x3F80 → FP32 1.0, all lanes)
SFPLOADI 3, 100, MOD_UINT16    ; LReg[3] = 100    (zero-extended 16-bit immediate, all lanes)
```

**Register Constraints:**
- Only LReg[0..7] can be written
- Write to LReg[11..14] requires SFPCONFIG

**Lane Predication:**
- Write gated by LaneEnabled
