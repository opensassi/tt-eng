# `dma_write` – TDMA Bulk Write

**Category:** Data Movement (TDMA-RISC)

**Syntax:** `dma_write(src_addr, dst_addr, size, mode)` — programmed via TDMA-RISC registers (`0xFFB1_1000–1014`)

**Operation:** Initiate a bulk memcpy from local L1 to local L1, Backend Configuration, or NC Instruction RAM, or a memset-zero to those destinations. Offloaded to the TDMA-RISC coprocessor.

**x86 Equivalent:** Non-temporal store sequence / DMA engine

**Notes:** Same TDMA-RISC engine as `dma_read`. Supports strided and rectangular layouts. Source documentation only available under `WormholeB0/TensixTile/`; Blackhole-specific differences are unknown.

## Register Map

| Offset | Register | Width | Description |
|--------|----------|-------|-------------|
| `0x000` | `XMOV_SRC_ADDR` | 32 | Source address in L1 (or L0 for zero-fill) |
| `0x004` | `XMOV_DST_ADDR` | 32 | Destination address in L1 / Backend Config / NC RAM |
| `0x008` | `XMOV_SIZE` | 32 | Transfer size in bytes |
| `0x00C` | `XMOV_DIRECTION` | 32 | Mover mode (see Direction / Mode enum) |
| `0x010` | `COMMAND_ADDR` | 32 | Base address of command parameter block in L1 |
| `0x014` | `STATUS` | 32 | Status bits + credits |

## Command Formats

Commands are enqueued via `EnqueueCmd(opcode)`. Two formats exist:

| Format | Bit 31 | Encoding |
|--------|--------|----------|
| **Parameterized** | 0 | Parameters read from `CmdParams[0..3]` at `COMMAND_ADDR` in L1 |
| **Compact** | 1 | All parameters packed into the lower 31 bits of the command word |

### Supported Opcodes

| Opcode | Mnemonic | Description |
|--------|----------|-------------|
| `0x40` | MOVER | Start mover transfer |
| `0x46` | MOVER_WAIT | Wait for mover completion |
| `0x66` | L1_WRITE | L1 write via TDMA |
| `0x89` | NOP | No-op (used as workaround for hardware bug) |

## Direction / Mode Enum

| Value | Constant | Operation |
|-------|----------|-----------|
| `0` | `XFER_L0_L1` | Memset-zero from L0 → L1 |
| `1` | `XFER_L1_L0` | Memcpy from L1 → L0 (Backend Config / NC RAM) |
| `2` | `XFER_L0_L0` | Memset-zero from L0 → L0 |
| `3` | `XFER_L1_L1` | Memcpy from L1 → L1 |

- **L0 → \*** modes perform a **memset-zero** (write zeros, no data read from source).
- **L1 → \*** modes perform a **memcpy** (copy data between addresses).

## Latency / Performance

| Mode | Condition | Throughput |
|------|-----------|------------|
| `XFER_L1_TO_L1` | No port contention (ideal) | 93.1 bits/cycle |
| `XFER_L1_TO_L1` | With port contention | 32 bits/cycle |
| `XFER_L0_TO_L1` (memset) | Ideal | 128 bits/cycle |

Actual performance depends on L1 access port contention. See `Mover.md §56–64` for full details.

## Example

```asm
// Setup: memcpy 1024 bytes from L1 0x20000 to L1 0x30000
// Mode: XFER_L1_TO_L1 (3)

// Write register parameters
XMOV_SRC_ADDR = 0x20000       // src address
XMOV_DST_ADDR = 0x30000       // dst address
XMOV_SIZE     = 1024           // size in bytes
XMOV_DIRECTION = 3             // XFER_L1_TO_L1

// Enqueue mover command (parameterized format)
EnqueueCmd(0x40)
// Workaround for ParameterCredits bug
EnqueueCmd(0x80000089)         // NOP with compact bit set

// Wait for completion
MOVER_WAIT:
  status = STATUS
  if (status & DONE) goto DONE
  jump MOVER_WAIT
DONE:
