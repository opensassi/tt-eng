# `LOADIND` – Indirect Scalar Load from L1

**Category:** Scalar Memory (Tensix Coprocessor)

**Syntax:** `LOADIND Size, ResultReg, AddrReg, OffsetHalfReg, OffsetIncrement`

**Operation:** Load a scalar value from L1 at address `GPRs[AddrReg] × 16 + offset`, where `offset` is the 16-bit value in half-register OffsetHalfReg. After use, the half-register is incremented according to OffsetIncrement.

**Addressing:**
- Base address: `GPRs[AddrReg] × 16` (AddrReg is a 32-bit GPR)
- Offset: 16-bit value in half-register OffsetHalfReg
- Auto-increment: OffsetHalfReg value adjusted by OffsetIncrement after execution

**OffsetIncrement parameter (2 bits):**

| Value | Increment |
|-------|-----------|
| 0 | 0 bytes |
| 1 | 2 bytes |
| 2 | 4 bytes |
| 3 | 16 bytes |

**Size parameter (2 bits):**

| Value | Width | Behavior |
|-------|-------|----------|
| 0 | 128-bit | Loads 4 GPRs (128 bits) starting at ResultReg; ResultReg must be a multiple of 4 |
| 1 | 32-bit | Loads 1 GPR (32 bits) |
| 2 | 16-bit | Loads 16 bits; high 16 bits of GPR unchanged |
| 3 | 8-bit | Loads 8 bits; high 24 bits of GPR unchanged |

**Completion:** Instruction completes when the read request is *sent*. Data is not yet available at completion. Use `STALLWAIT(C0)` or `FLUSHDMA(C0)` before reading the result.

**Backend:** Scalar Unit (ThCon). Blocks all threads while executing; the issuing thread is fully blocked.

**Performance:** ≥3 cycles (may be longer if memory subsystem is busy).

**Example:**
`LOADIND 1, r10, r5, h3, 2  ; 32-bit load from L1[r5*16 + h3]; increment offset by 4 bytes`

**Notes:**
- For 128-bit loads (Size=0), ResultReg must be a multiple of 4 (4 consecutive GPRs are written).
- L1 address must be < TENSIX_SRAM_SIZE; out-of-range access triggers UndefinedBehavior.
