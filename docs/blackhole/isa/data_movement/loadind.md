# `LOADIND` – Indirect Scalar Load from L1

**Category:** Scalar Memory (Tensix Coprocessor)

**Syntax:** `LOADIND ResultReg, AddrReg, OffsetHalfReg`

**Operation:** Load a scalar value from L1 at address `GPRs[AddrReg] × 16 + OffsetHalfReg`. The OffsetHalfReg is a half-register (16 bits); after use, OffsetHalfReg is incremented by 16 (auto-increment) unless targeting SrcA/SrcB.

**Addressing:**
- Base address: `GPRs[AddrReg] × 16` (AddrReg is a 32-bit GPR)
- Offset: `OffsetHalfReg` (16-bit half-register)
- Auto-increment: OffsetHalfReg += 16 after execution (unless mode is SrcA/SrcB)

**Size parameter (2 bits):**

| Value | Width | Behavior |
|-------|-------|----------|
| 0 | 128-bit | Loads 4 GPRs (128 bits) starting at ResultReg |
| 1 | 32-bit | Loads 1 GPR (32 bits) |
| 2 | 16-bit | Loads 16 bits; high 16 bits of GPR unchanged |
| 3 | 8-bit | Loads 8 bits; high 24 bits of GPR unchanged |

**Completion:** Instruction completes when the read request is *sent*. Data is not yet available at completion. Use `STALLWAIT(C0)` or `FLUSHDMA(C0)` before reading the result.

**Backend:** Scalar Unit (ThCon). Blocks all threads while executing; the issuing thread is fully blocked.

**Performance:** ≥3 cycles.
