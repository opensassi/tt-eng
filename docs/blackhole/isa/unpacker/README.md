# Unpacker Instructions

The Tensix coprocessor has 2 unpackers. Each reads data from L1, converts formats, and writes to Dst or LReg registers.

## `UNPACR_Regular`

**Operation:** Read tile data from L1, optionally convert format, write to Dst registers.

- Source: L1 (address from DMA registers)
- Destination: Dst accumulator registers
- Format conversion: INT8, INT16, FP16, BF16, FP32, TF32 → internal format
- Tile dimensions: software-configured (typically 32×32)

**Performance modes:** UNPACR fetch speeds: x1 (16B/cyc), x2 (32B/cyc), x4 (64B/cyc). Decompression forces x1. DiscontiguousInputRows forces x4.

**TileDescriptor config:** Tile layout is configured via TileDescriptor fields: InDataFormat, IsUncompressed, XDim, YDim, ZDim, WDim, etc.

**Decompression:** RLE-based with 4-bit zero-count per datum. Data interleaved: 32 datums, then 32 RLE values. Uses Row Start Index (RSI) array produced by Packer. RSI cache maintained across instructions.

**Upsampling:**

| Upsample_rate | Interleave | Behavior |
|---|---|---|
| 0 | any | No upsampling |
| 1 | false | Insert 1 zero after each datum |
| 2 | false | Insert 2 zeroes after each datum |
| 3 | false | Insert 4 zeroes after each datum |
| 1 | true | Skip 1 output position after each datum |
| 2 | true | Skip 2 output positions after each datum |
| 3 | true | Skip 4 output positions after each datum |

## `UNPACR_FlushCache`

Flush the unpacker's internal cache. Required before reading new data that may overlap with cached tiles.

## `UNPACR_IncrementContextCounter`

Advance the unpacker's context counter (used for multi-context pipelining).

## `UNPACR_NOP_*` Operations

| Variant | Purpose |
|---------|---------|
| `NOP` | Zero-overhead NOP |
| `SETREG` | Set unpacker register value (SetRegBase via TDMA-RISC) |
| `SETDVALID` | Assert DVALID |
| `ZEROSRC` | Zero unpacker source |
| `OverlayClear` | Clear overlay (stream) data |
| `Nop` | No operation (explicit) |

## `UNPACR_NOP_SETREG`

MMIO register write sequenced with UNPACR. Accumulate mode available. SetRegBase via TDMA-RISC.

## `CLEARDVALID`

> **BUG:** CLEARDVALID with Reset mode = UnsupportedFunctionality — can cause nondeterministic hangs (GitHub issue #22383). Avoid Reset mode.
