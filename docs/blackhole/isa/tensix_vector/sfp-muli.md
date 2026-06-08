# `SFPMULI` – Vector FP32 Multiply Immediate

**Category:** SFPU FP32 Arithmetic

**Syntax:** `SFPMULI VD, Imm16, Mod1`

**Operation:** `VD = (±VD * BF16ToFP32(Imm16)) + 0`

**Latency:** 2 cycles, IPC=1

**Backend:** Vector Unit (SFPU), MAD sub-unit

**Example:**
```asm
SFPMULI 0, 0x3F00, 0   ; LReg[0] *= 0.5f  (multiply all lanes by BF16 immediate 0x3F00)
