# `UNPACR` – Vector Unpack (Move datums from L1 to SrcA/SrcB/Dst)

**Category:** Data Format Conversion

**Hardware unit:** Unpacker (x2 per Tensix core)

**Backend execution unit:** [Unpackers](Unpackers/README.md)

**Operation:** Issue work to one unpacker, moving datums from L1 to [`SrcA` or `SrcB`](SrcASrcB.md) or [`Dst`](Dst.md). UNPACR reads data in the specified input format, converts to the specified output format, and writes to the destination. It is **not** an SFPU instruction; it is an Unpacker pipeline instruction.

## Syntax

```c
TT_OP_UNPACR(/* u1 */ WhichUnpacker,
           ((/* u2 */ Ch1YInc) << 6) +
           ((/* u2 */ Ch1ZInc) << 4) +
           ((/* u2 */ Ch0YInc) << 2) +
             /* u2 */ Ch0ZInc,
             false,
             /* u3 */ ContextNumber,
             /* u2 */ ContextADC,
             /* bool */ MultiContextMode,
             /* bool */ FlipSrc,
             false,
             /* bool */ AllDatumsAreZero,
             /* bool */ UseContextCounter,
             /* bool */ RowSearch,
             false,
             false)
