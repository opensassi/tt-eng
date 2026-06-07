# `SFPMULI` – Vector FP32 Multiply Immediate

**Category:** SFPU FP32 Arithmetic

**Syntax:** `SFPMULI VD, Imm16, Mod1`

**Operation:** `for lane in 0..31: VD[lane] *= BF16ToFP32(Imm16)`

**Latency:** 2 cycles, IPC=1

**Example:**
```asm
SFPMULI 0, 0x3F00, 0   ; LReg[0] *= 0.5f  (multiply all lanes by BF16 immediate 0x3F00)
```

**Notes:** Immediate is BF16; converted to FP32 for computation. Has indirect `VD` mode for non-uniform lane scaling.
