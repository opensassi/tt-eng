# `SFPLZ` – Test Zero / Count Leading Zeros

**Category:** SFPU Comparison

**Syntax:** `SFPLZ VC, VD, Mod1`

**Operation (flag mode):** `LaneFlags[lane] = (VC[lane] != 0)` or `(VC[lane] == 0)`

**Operation (int count):** `VD[lane] = CountLeadingZeros(VC[lane])`

**Latency:** 1 cycle, IPC=1

**x86 Equivalent (CLZ):** `lzcnt` (scalar) / no direct vector CLZ in AVX2

**Example:**
```asm
SFPLZ 1, 2, MOD_CLZ     ; LReg[2] = count_leading_zeros(LReg[1])  per lane
SFPLZ 1, 2, MOD_ZEROTEST ; Set LaneFlags where LReg[1] != 0
```
