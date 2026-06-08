# `vshift` – Vector Shift, Rotate, and Shuffle (SFPU)

**Category:** SFPU Bit Manipulation

**SFPU mnemonic:** `SFPSHFT` / `SFPSHFT2`

## `SFPSHFT` – Lanewise Shift

**Syntax:** `SFPSHFT VA, VB, VC, VD, Mod1`

**Operation:**
- `VD = VD << (VC % 32)` or `VD = VC << (Imm12 & 31)` (left shift)
- `VD = VD >> (-VC % 32)` or `VD = VC >> (-(Imm12 & 31))` (arithmetic right shift)
- `VD = VD >>> (-VC % 32)` or `VD = VC >>> (-(Imm12 & 31))` (logical right shift)

Per-lane variable shift: each lane reads its shift amount from the corresponding lane of `VC`, modulo 32. Immediate shift applies the same `(Imm12 & 31)` to all lanes.

**Modifiers:** `SFPSHFT_MOD1_ARG_IMM`, `SFPSHFT_MOD1_ARITHMETIC`, `SFPSHFT_MOD1_ARG_IMM_USE_VC`

**x86 Equivalent:** `vpsllw` / `vpsrlw` / `vpsraw` (AVX2), `vpsllvd` / `vpsrlvd` / `vpsravd` (AVX2 variable shift)

**Latency:** 1 cycle (lanewise modes)

**IPC:** 1

**Example:**
```asm
; Lane-wise variable left shift
SFPSHFT 0, 0, 1, 0, 0    ; LReg[0] = LReg[0] << (LReg[1] % 32)
                          ; each lane uses its own shift amount from LReg[1]

; Immediate arithmetic right shift (all lanes by 4)
SFPSHFT 0, 0, 0, 2, SFPSHFT_MOD1_ARG_IMM | SFPSHFT_MOD1_ARITHMETIC
                          ; with Imm12=4: LReg[2] = LReg[0] >> 4 (arithmetic)
```
```markdown
# `vshift` – Vector Shift, Rotate, and Shuffle (SFPU)

**Category:** SFPU Bit Manipulation

**SFPU mnemonic:** `SFPSHFT` / `SFPSHFT2`

## `SFPSHFT` – Lanewise Shift

**Syntax:** `SFPSHFT VA, VB, VC, VD, Mod1`

**Operation:**
- `VD = VD << (VC % 32)` or `VD = VC << (Imm12 & 31)` (left shift)
- `VD = VD >> (-VC % 32)` or `VD = VC >> (-(Imm12 & 31))` (arithmetic right shift)
- `VD = VD >>> (-VC % 32)` or `VD = VC >>> (-(Imm12 & 31))` (logical right shift)

Per-lane variable shift: each lane reads its shift amount from the corresponding lane of `VC`, modulo 32. Immediate shift applies the same `(Imm12 & 31)` to all lanes.

**Modifiers:** `SFPSHFT_MOD1_ARG_IMM`, `SFPSHFT_MOD1_ARITHMETIC`, `SFPSHFT_MOD1_ARG_IMM_USE_VC`

**x86 Equivalent:** `vpsllw` / `vpsrlw` / `vpsraw` (AVX2), `vpsllvd` / `vpsrlvd` / `vpsravd` (AVX2 variable shift)

**Latency:** 1 cycle (lanewise modes)

**IPC:** 1

**Example:**
```asm
; Lane-wise variable left shift
SFPSHFT 0, 0, 1, 0, 0    ; LReg[0] = LReg[0] << (LReg[1] % 32)
                          ; each lane uses its own shift amount from LReg[1]

; Immediate arithmetic right shift (all lanes by 4)
SFPSHFT 0, 0, 0, 2, SFPSHFT_MOD1_ARG_IMM | SFPSHFT_MOD1_ARITHMETIC
                          ; with Imm12=4: LReg[2] = LReg[0] >> 4 (arithmetic)
