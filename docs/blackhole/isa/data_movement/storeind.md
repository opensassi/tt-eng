# `STOREIND` – Indirect Scalar Store to L1

**Category:** Scalar Memory (Tensix Coprocessor)

**Backend execution unit:** Scalar Unit (ThCon)

## Syntax

Three distinct modes, selected by Mod1/Mod0 mode-select bits:

| Mode | Mod1 | Mod0 | Assembly Form | Operands |
|------|------|------|---------------|----------|
| L1 | 1 | 0 | `STOREIND.L1` | `Size(2), OffsetHalfReg, OffsetIncrement(2), DataReg, AddrReg` |
| MMIO | 0 | 1 | `STOREIND.MMIO` | `OffsetHalfReg, OffsetIncrement(2), DataReg, AddrReg` |
| SrcA/SrcB | 0 | 0 | `STOREIND.SRC` | `StoreToSrcB(1), OffsetHalfReg, OffsetIncrement(2), DataReg, AddrReg` |

**Functional encoding:**
- L1:   `TT_STOREIND(1,0,Size,OffsetHalfReg,OffsetIncrement,DataReg,AddrReg)`
- MMIO: `TT_STOREIND(0,1,0,OffsetHalfReg,OffsetIncrement,DataReg,AddrReg)`
- Src:  `TT_STOREIND(0,0,StoreToSrcB,OffsetHalfReg,OffsetIncrement,DataReg,AddrReg)`

## Encoding

| Bit(s) | Field | Description |
|--------|-------|-------------|
| 31:28 | Opcode | `0xC` |
| 27 | Mod1 | Mode-select bit 1 |
| 26 | Mod0 | Mode-select bit 0 |
| 25:20 | AddrReg | u6 — GPR address register index (0–63) |
| 19:14 | DataReg | u6 — GPR data register index (masked per mode, see Register Constraints) |
| 13 | StoreToSrcB | Src mode: 0=SrcA, 1=SrcB |
| 12:11 | Size | L1 mode: 2-bit width encoding (see below) |
| 10:4 | OffsetHalfReg | u7 — half-GPR register index (0–127) |
| 3:2 | OffsetIncrement | 2-bit auto-increment (see Operation) |
| 1:0 | (reserved) | |

## Operation

Store a scalar register value to address `GPRs[AddrReg] × 16 + OffsetHalfReg`.

### Auto-increment (all modes)

After use, `OffsetHalfReg` is incremented by the value of the 2-bit `OffsetIncrement` field:

| OffsetIncrement | Increment |
|:---------------:|:---------:|
| 0 | 0 (no increment) |
| 1 | 2 |
| 2 | 4 |
| 3 | 16 |

### L1 Mode (Mod1=1, Mod0=0)

Address: `GPRs[AddrReg] × 16 + OffsetHalfReg`

**Size parameter (2 bits):**

| Value | Width | Behavior |
|-------|-------|----------|
| 0 | 128-bit | Stores 4 consecutive GPRs starting at `DataReg & 0x3c` (16 bytes): `memcpy(L1Address & ~15, &GPRs[DataReg & 0x3c], 16)` |
| 1 | 32-bit | Stores 1 GPR (`DataReg & 0x3f`) |
| 2 | 16-bit | Stores low 16 bits of GPR (`DataReg & 0x3f`) |
| 3 | 8-bit | Stores low 8 bits of GPR (`DataReg & 0x3f`) |

### MMIO Mode (Mod1=0, Mod0=1)

Address: `0xFFB00000 + (GPRs[AddrReg] + (OffsetHalfReg >> 4)) & 0x000FFFFC`

### SrcA/SrcB Mode (Mod1=0, Mod0=0)

Writes 4 BF16 values packed in 2 GPRs to the destination register file.

### Completion

Instruction completes when the write request is *sent*, not when it reaches the destination.

## Register Constraints

| Operand | Width | Constraint |
|---------|-------|------------|
| AddrReg | u6 | Valid GPR index 0–63 |
| OffsetHalfReg | u7 | Valid half-GPR index 0–127 (selects a 16-bit half of a GPR) |
| DataReg (L1 Size=0) | u6 | Aligned to 4-GPR boundary: `DataReg & 0x3c` |
| DataReg (L1 Size>0) | u6 | `DataReg & 0x3f` |
| DataReg (Src mode) | u6 | Aligned to 4-GPR boundary: `DataReg & 0x3c` |

## Configuration Requirements (SrcA/SrcB Mode)

Src mode execution depends on the following ThreadConfig and Unpacker state:

- `Unpackers[...].SrcBank` — source bank selection
- `SrcRow[CurrentThread]` — source row for the current thread
- `AllowedClient` — arbitration client ownership

SrcA mode additionally depends on:
- `SRCA_SET_SetOvrdWithAddr` — when set, overrides the row bound from 16 to 64

## Performance Characteristics

- **Latency:** Occupies the Scalar Unit (ThCon) for at least 3 cycles in all three modes.
- May be longer if the memory subsystem is busy (L1/MMIO modes).
- May be longer if waiting for `AllowedClient` arbitration to change (Src mode).

## Examples

### L1 Mode
```asm
STOREIND.L1 1, 4, 3, 12, 8   ; Size=1 (32-bit), OffsetHalfReg=R4, OffsetIncrement=3 (16), DataReg=R12, AddrReg=R8
