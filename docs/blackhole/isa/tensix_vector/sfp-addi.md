# `SFPADDI` – Vector FP32 Add Immediate

**Category:** SFPU FP32 Arithmetic

**Syntax:** `SFPADDI VD, Imm16, Mod1`

**Operation:** `for lane in 0..31: VD[lane] += BF16ToFP32(Imm16)`

**Latency:** 2 cycles, IPC=1

**Example:**
```asm
SFPADDI 0, 0x3F80, 0   ; LReg[0] += 1.0f  (add BF16 immediate 0x3F80 to all lanes)
```

**Notes:** Immediate is stored as BF16 (16 bits), converted to FP32 for the computation. Executes on MAD sub-unit. Same IEEE754 caveats as `SFPMAD`.
