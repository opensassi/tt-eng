# `vshift` – Vector Shift, Rotate, and Shuffle (SFPU)

**Category:** SFPU Bit Manipulation

**SFPU mnemonic:** `SFPSHFT` / `SFPSHFT2`

## `SFPSHFT` – Lanewise Shift

**Syntax:** `SFPSHFT VA, VB, VC, VD, Mod1`

**Operation:**
- `VD = VD << (VC % 32)` or `VD = VC << Imm5` (left shift)
- `VD = VD >> (-VC % 32)` or `VD = VC >> -Imm5` (arithmetic right shift)
- `VD = VD >>> (-VC % 32)` or `VD = VC >>> -Imm5` (logical right shift)

Per-lane variable shift: each lane reads its shift amount from the corresponding lane of `VC`, modulo 32. Immediate shift applies the same `Imm5` to all lanes.

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

## `SFPSHFT2` – Cross-Lane Shuffle and Bitwise Shift

**Syntax:** `TT_SFPSHFT2(VB, VC, VD, Mod1)` or `TT_SFPSHFT2(Imm12, 0, VD, Mod1)`

Provides lane rotation, sub-vector shuffle, and register-to-register bitwise shift. Executes on the **round sub-unit**.

| Mode | Operation | Use case |
|------|-----------|----------|
| `SFPSHFT2_MOD1_COPY4` | L0←L1, L1←L2, L2←L3, L3←0 (within each lane) | Register rotation |
| `SFPSHFT2_MOD1_SUBVEC_CHAINED_COPY4` | L0←L1, L1←L2, L2←L3, L3←L0[Lane+8] (within each group of 8 lanes) | Sub-vector shift |
| `SFPSHFT2_MOD1_SUBVEC_SHFLROR1_AND_COPY4` | L0←L1, L1←L2, L2←L3, L3←ror8(L0) + rotate VC right by 1 within each 8-lane group | Butterfly reduction |
| `SFPSHFT2_MOD1_SUBVEC_SHFLROR1` | VD = rotate-right VC by 1 lane within each 8-lane group | Butterfly reduction |
| `SFPSHFT2_MOD1_SUBVEC_SHFLSHR1` | VD = shift-right VC by 1 lane within each 8-lane group (**buggy on Wormhole**) | Avoid if possible |
| `SFPSHFT2_MOD1_SHFT_LREG` | VD = VB << (VC % 32) or VD = VB >> ((-VC) % 32) | Variable shift (alternate) |
| `SFPSHFT2_MOD1_SHFT_IMM` | VD = VB << (Imm12 & 31) or VD = VB >> ((-Imm12) & 31) | Immediate shift (limited) |

**Latency:** 1 cycle (lanewise modes), 2 cycles (cross-lane modes)

**IPC:** 1 (lanewise), ≤ 1 (cross-lane modes due to scheduling restrictions)

**Scheduling:** On Blackhole, hardware auto-stalls for 1 cycle after cross-lane modes — no explicit NOP required. On Wormhole, insert SFPNOP. Auto-stall does NOT apply inside SFPLOADMACRO sequences — manual NOP required there regardless.

**Example:**
```asm
; Butterfly reduction: rotate each 8-lane group right by 1
SFPSHFT2 0, 1, 2, SFPSHFT2_MOD1_SUBVEC_SHFLROR1  ; LReg[2] = rotate_right(LReg[1])
SFPNOP                                              ; scheduling hazard (WH only)
```

**Register Constraints (SFPSHFT2):**
- COPY4: VD < 12 || DISABLE_BACKDOOR_LOAD
- SUBVEC_SHFLSHR1, SHFT_LREG, SHFT_IMM: VD < 8 || VD == 16

**Reserved Mod1:**
- `switch default`: `UndefinedBehavior()` for unrecognized Mod1 values

**BH upgrade note:** SUBVEC_SHFLSHR1 bug (UnpredictableValue on WH) is fixed on Blackhole.

**Mod1 (SFPSHFT):**
| Bit | Constant | Description |
|-----|----------|-------------|
| 0 | `SFPSHFT_MOD1_ARG_IMM` (1) | Use Imm12 as shift amount instead of VC |
| 1 | `SFPSHFT_MOD1_ARITHMETIC` (2) | Arithmetic right shift (sign-extend) instead of logical |
| 2 | `SFPSHFT_MOD1_ARG_IMM_USE_VC` (4) | Source operand comes from VC shift amount field instead of VD |

**Register Constraints (SFPSHFT):**
- VD < 8 or VD == 16

**Reserved Modifier Warning:**
- Mod1 values > 7 or Mod1 == 4 or Mod1 == 6 trigger NonContractualBehavior

**Lane Predication:**
- Operation gated by LaneEnabled per lane

**Notes:** Cross-lane variants can rotate or shift data within 8-lane sub-vectors. For general cross-lane permute (VPERM equivalent), see note in [sfp-transp.md](tensix_vector/sfp-transp.md).
