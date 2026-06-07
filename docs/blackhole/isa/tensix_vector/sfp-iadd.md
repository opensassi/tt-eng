# `SFPIADD` – Vector Integer Add

**Category:** SFPU Integer Arithmetic

**Syntax:** `SFPIADD Imm12, VC, VD, Mod1`

**Operation:** `for lane in 0..31: VD[lane] = VC[lane] ± VD[lane]` or `VD = VC ± Imm12`

32-bit two's complement integer addition or subtraction with lane flags output.

**x86 Equivalent:** `vpaddd`

**Latency:** 1 cycle, IPC=1

**Example:**
```asm
SFPIADD 0, 1, 2, MOD_IADD_ADD   ; LReg[2] = LReg[1] + LReg[2]  (32-bit integer add)
SFPIADD 0, 1, 2, MOD_IADD_SUB   ; LReg[2] = LReg[1] - LReg[2]  (32-bit integer sub)
SFPIADD 42, 2, 0, MOD_IADD_IMM  ; LReg[0] = LReg[2] + 42       (add immediate)
```

**Notes:** Can also set `LaneFlags` based on overflow/result. Used for integer averaging (combined with `SFPMUL24`).

Result LReg must be index 0-7 or 16 (VD < 8 || VD == 16).

Executes on the **simple** sub-unit of the SFPU backend.
