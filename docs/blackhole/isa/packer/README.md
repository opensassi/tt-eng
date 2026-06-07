# Packer Operations

The Tensix coprocessor has 4 packers. Each reads data from Dst registers, optionally applies post-processing, converts format, and writes to L1.

## Main Pack Operation

Reads from Dst accumulator, applies:
1. Optional ReLU (clamp negative to zero)
2. Optional downsampling
3. Format conversion (FP32 → INT8, INT16, BF16, etc.)
4. Edge masking
5. Write to L1

## Post-Processing Stages

| Stage | Description |
|-------|-------------|
| `ReLU` | Clamp negative output values to zero |
| `Downsampling` | Skip spatial positions (reduce resolution) |
| `EdgeMasking` | Suppress edge tiles beyond valid region |
| `Compression` | Lossless compression of output data |
| `ExponentHistogram` | Track exponent distribution across tile |
| `ExponentThresholding` | Adapt exponent range based on histogram |
| `FormatConversion` | Internal FP32 → output format (INT8, INT16, BF16, FP16) |

## Address Generation

| Unit | Purpose |
|------|---------|
| `InputAddressGenerator` | Compute read addresses from Dst (tile walk patterns) |
| `OutputAddressGenerator` | Compute write addresses for L1 (strided, interleaved, planar) |

## Format Conversion Options

| Input | Output | When |
|-------|--------|------|
| FP32 | BF16 | Default for neural network inference |
| FP32 | FP16 | Higher precision than BF16 |
| FP32 | INT8 | Quantized inference |
| FP32 | INT16 | Higher-precision quantized |
| FP32 | TF32 | TensorFloat-32 (truncated mantissa) |
