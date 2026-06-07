# `STOREIND` – Indirect Scalar Store to L1

**Category:** Scalar Memory (Tensix Coprocessor)

**Syntax:** `STOREIND DataReg, AddrReg, OffsetHalfReg`

**Operation:** Store a scalar register value to address `GPRs[AddrReg] × 16 + OffsetHalfReg`. After use, OffsetHalfReg is incremented by 16 (auto-increment) unless targeting SrcA/SrcB.

**Addressing:**
- Base address: `GPRs[AddrReg] × 16`
- Offset: `OffsetHalfReg` (16-bit half-register)
- Auto-increment: OffsetHalfReg += 16 after execution

**Size parameter (2 bits):** Same encoding as LOADIND:

| Value | Width | Behavior |
|-------|-------|----------|
| 0 | 128-bit | Stores 4 GPRs (128 bits) |
| 1 | 32-bit | Stores 1 GPR (32 bits) |
| 2 | 16-bit | Stores low 16 bits of GPR |
| 3 | 8-bit | Stores low 8 bits of GPR |

**Three modes:**
1. **L1 write** — destination is L1 memory
2. **MMIO write** — destination is MMIO register space (`0xFFB00000` region)
3. **SrcA/SrcB write** — writes 4 BF16 values packed in 2 GPRs to destination register file

**Completion:** Instruction completes when the write request is *sent*, not when it reaches the destination.
