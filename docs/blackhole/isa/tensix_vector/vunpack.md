# `vunpack` – Vector Unpack (Unpacker)

**Category:** Data Format Conversion

**Hardware unit:** Unpacker (x2 per Tensix core)

**SFPU mnemonic:** `UNPACR_Regular`

**Operation:** Read data from L1 in specified format, expand to FP32 lanes in the SFPU LReg or Dst registers.

Supported input formats: INT8, INT16, FP16, BF16, FP32, TF32, custom formats.

**x86 Equivalent (widening):**
| x86 intrinsic | Description | Tensix equivalent |
|---|---|---|
| `vpmovzxbd` / `vpmovzxwd` | Zero-extend byte/word → dword | `UNPACR` with unsigned format |
| `vpmovsxbd` / `vpmovsxwd` | Sign-extend byte/word → dword | `UNPACR` with signed format |
| `PUNPCKLBW` / `PUNPCKHBW` | Interleave low/high bytes from two vectors | No single instruction; requires two `UNPACR` calls + lane interleave via `SFPTRANSP` + `SFPSTORE`/`SFPLOAD` |

**Interleave (PUNPCK) pattern:**
```asm
; To interleave two tiles from L1 into alternating lanes:
UNPACR tileA, Dst[0:15]     ; Load even rows
UNPACR tileB, Dst[16:31]   ; Load odd rows
SFPLOAD 0, 1                ; LReg[1] = Dst rows 0-3 (tileA)
SFPLOAD 8, 2                ; LReg[2] = Dst rows 8-11 (tileB)
; Then use SFPTRANSP + register interleave or manual SFPSTORE/SFPLOAD
```

**Latency:** 1 cycle (pipeline, but depends on data availability from L1)

**IPC:** 1

**Notes:**
- Two unpackers can operate in parallel for higher throughput (Unpacker 0 → Dst/SrcA, Unpacker 1 → SrcB).
- Format conversion includes exponent adjustment, sign extension, zero padding.
- Unpacker also handles tile layout conversion (interleaved → row-major), upsampling, and decompression.
- There is no single-instruction lane interleave (PUNPCKLBW equivalent). The recommended approach for interleaving two vectors is to unpack them to separate Dst regions, move to LReg via SFPLOAD, and manually interleave using SFPTRANSP and/or SFPMOV.
