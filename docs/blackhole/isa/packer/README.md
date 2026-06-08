# Packer Operations

The Tensix coprocessor has 4 packers. Each reads data from Dst registers, optionally applies post-processing, converts format, and writes to L1.

## Instructions

### `PACR` — Give Work to Packers

Give work to between one and four packers, or flush the output buffers just before L1.

**Syntax:**
