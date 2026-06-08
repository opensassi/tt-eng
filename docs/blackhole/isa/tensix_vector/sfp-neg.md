# `SFPMOV` – Negate (Mode)

**Category:** SFPU Data Movement

**Backend:** Vector Unit (SFPU), simple sub-unit. Can be parallelized with MAD/round/store sub-units via SFPLOADMACRO.

**Syntax:** `SFPMOV 0, VC, VD, SFPMOV_MOD1_NEGATE`

*This is the negate mode of the `SFPMOV` instruction. The assembler mnemonic is `SFPMOV`, not `SFPNEG`.*

**Operation:** `for lane in 0..31: VD[lane] = -VC[lane]`

**Mechanism:** Negation is `x ^= 0x80000000` — flips the sign bit. No NaN or denormal special-casing. Works on both FP32 and sign-magnitude integers (sign is MSB for both).

**Mod1 encoding:** `SFPMOV_MOD1_NEGATE = 1`

**Combinability:** Can be ORed with ALL_LANES_ENABLED (Mod1=1|2=3)

**Latency:** 1 cycle, IPC=1

**x86 Equivalent:** `vxorps` with sign mask

**Register Constraints:**
- VD write range: 0–7, or 16
- VC read range: 0–11, or any if `LaneConfig.DISABLE_BACKDOOR_LOAD` is set
- Lane predication: operation gated by `LaneEnabled || Mod1 == SFPMOV_MOD1_ALL_LANES_ENABLED`

**Configuration Requirements:**
- `LaneConfig.DISABLE_BACKDOOR_LOAD`: when true, the instruction always executes (no backdoor load redirection). When false, instructions with VD ≥ 12 are treated as writes to LoadMacroConfig.

**Known Bugs & Errata:**
- Mod1 bit 2 (value 4) is reserved and triggers NonContractualBehavior — software must not set it. Current silicon clears the bit silently.

**Example:**
```asm
SFPMOV 0, 0, 1, SFPMOV_MOD1_NEGATE   ; LReg[1] = -LReg[0]  (negate, SFPMOV with negate Mod1)
