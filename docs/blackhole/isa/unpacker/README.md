# Unpacker Instructions

The Tensix coprocessor has 2 unpackers. Unpacker 0 moves data from L1 to Dst or SrcA, while Unpacker 1 moves data from L1 to SrcB. Each reads data from L1, converts formats, and writes to Dst, SrcA, or SrcB registers.

## `UNPACR`

**Operation:** Move datums from L1 to SrcA or SrcB or Dst.

**Syntax:** `UNPACR [Mod0] [Mod1]`

- Source: L1 (address from DMA registers)
- Destination: Dst, SrcA, or SrcB — depends on which unpacker issues the instruction (Unpacker 0 → Dst/SrcA, Unpacker 1 → SrcB)
- Format conversion: INT8, INT16, FP16, BF16, FP32, TF32 → internal format
- Tile dimensions: software-configured (typically 32×32)

**Performance modes:** UNPACR fetch speeds: x1 (16B/cyc), x2 (32B/cyc), x4 (64B/cyc). Decompression forces x1. DiscontiguousInputRows forces x4.

**TileDescriptor config:** Tile layout is configured via TileDescriptor fields: InDataFormat, IsUncompressed, XDim, YDim, ZDim, WDim, etc.

**Decompression:** RLE-based with 4-bit zero-count per datum. Data interleaved: 32 datums, then 32 RLE values. Uses Row Start Index (RSI) array produced by Packer. RSI cache maintained across instructions.

To enable decompression, one of `ConfigState.THCON_SEC[WhichUnpacker].Disable_zero_compress_cntx[WhichContext]` or `ConfigDescriptor.IsUncompressed` must be set to `false` (which one depends on the value of `MultiContextMode`).

**Upsampling:**

| Upsample_rate | Upsample_and_interleave | Behavior |
|---|---|---|
| 0 | any | No upsampling |
| 1 | false | Insert 1 zero after each datum |
| 2 | false | Insert 2 zeroes after each datum |
| 3 | false | Insert 4 zeroes after each datum |
| 1 | true | Skip 1 output position after each datum |
| 2 | true | Skip 2 output positions after each datum |
| 3 | true | Skip 4 output positions after each datum |

## `UNPACR_FlushCache`

Flush the unpacker's decompression row start cache. Required before reading new data that may overlap with cached tiles.

## `UNPACR_IncrementContextCounter`

Advance the unpacker's context counter (used for multi-context pipelining).

## `UNPACR_NOP_*` Operations

| Variant | Purpose |
|---------|---------|
| `ZEROSRC` | Set SrcA or SrcB to zero, sequenced with UNPACR |
| `SETDVALID` | Assert DVALID (give SrcA or SrcB banks to Matrix Unit), sequenced with UNPACR |
| `SETREG` | MMIO register write sequenced with UNPACR (SetRegBase via TDMA-RISC) |
| `OverlayClear` | Clear overlay (stream) data via MMIO register write to `STREAM_MSG_DATA_CLEAR_REG_INDEX`, sequenced with UNPACR |
| `Nop` | Occupy Unpacker for one cycle (no operation) |

## `UNPACR_NOP_SETREG`

MMIO register write sequenced with UNPACR. Accumulate mode available. SetRegBase via TDMA-RISC.

## Register Constraints

- Unpacker 0 writes to **Dst or SrcA**; Unpacker 1 writes to **SrcB**.
- Each destination register file has per-thread access limitations — see [SrcASrcB.md](SrcASrcB.md) and [Dst.md](Dst.md) for register access constraints and sharing rules.
- There are two copies each of SrcA and SrcB; unpackers access one copy while the Matrix Unit (FPU) accesses the other. Software must manage flipping between the two copies, along with ensuring each relevant backend execution unit is only in use by one thread at a time.

## Scheduling

- UNPACR executes **asynchronously**: the RISCV core pushes the instruction and continues immediately. The Tensix Coprocessor executes it when it reaches the front of the instruction queue.
- If there are many queued instructions, the RISCV can get quite far ahead before UNPACR actually executes.
- Use `STALLWAIT` to synchronize: wait until the unpacker has finished processing before consuming the unpacked data.
- Use `TTSync` for RISCV–Tensix coprocessor synchronization.
- The Unpacker, Packer, and Matrix Unit are independent backend units; software should assign threads to different units for maximum throughput.

## Configuration Requirements

Decompression and format conversion are controlled by the following configuration registers:

| Register | Role |
|----------|------|
| `ConfigState.THCON_SEC[WhichUnpacker].Disable_zero_compress_cntx[WhichContext]` | Controls decompression enable per-unpacker, per-context |
| `ConfigDescriptor.IsUncompressed` | Per-descriptor uncompressed flag |
| `MultiContextMode` | Selects which of the above controls decompression |
| `InDataFormat` | Input data format (INT8, INT16, FP16, BF16, FP32, TF32) |
| `Upsample_rate` | Upsampling rate (0–3) |
| `Upsample_and_interleave` | Upsampling interleave mode |

## Edge Cases (IEEE754 & Format Conversion)

- **NaN passthrough:** NaN values are preserved through unpacking (no NaN-to-zero conversion).
- **Denormal flush:** Denormalized inputs are flushed to zero (FTZ mode) during format conversion.
- **Negative zero:** Negative zero is preserved as zero in the internal format.
- **Overflow/saturation:** Values exceeding the destination format range clamp to the nearest representable value (saturation, not wrap).
- **Rounding:** Round-to-nearest-even (RNE) is used for all format conversions where rounding is required.
- See [FormatConversion.md](FormatConversion.md) for full details on format-specific behavior.

## Performance Characteristics

UNPACR throughput is data-dependent:
- **Minimum latency:** 1 cycle per datum (x4 mode, 64B/cyc, no decompression, no upsampling)
- **Maximum latency:** Bound by L1 bank conflicts, decompression overhead, and upsampling rate
- Decompression forces x1 mode (16B/cyc) and adds RLE decode latency.
- `DiscontiguousInputRows` forces x4 mode regardless of other settings.
- Cycle-accurate latency figures vary by tile configuration and L1 bank contention; profile on target hardware for precise measurements.

## Blackhole vs Wormhole

UNPACR behavior is architecturally common across Blackhole and Wormhole. No Blackhole-specific differences are documented for this instruction.

## Assembly Example

```asm
; Example: Unpacker 0 reads tile from L1 to SrcA, then synchronize
UNPACR                       ; unpack tile from L1 to SrcA/Dst (Unpacker 0)
STALLWAIT Unpacker0          ; wait until Unpacker 0 finishes
                             ; unpacked data is now available in SrcA/Dst
