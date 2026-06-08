# SFPU Lane Predication (SIMT Stack)

## Architecture

Each lane has a stack of flag entries `{ LaneFlags, UseLaneFlagsForLaneEnable }`. When `UseLaneFlags = true`, lanes with `LaneFlags = false` are disabled. Used to implement SIMT `if/else` control flow.

**Source file(s):**
- `BlackholeA0/TensixTile/TensixCoprocessor/SFPENCC.md`
- `BlackholeA0/TensixTile/TensixCoprocessor/SFPPUSHC.md`
- `BlackholeA0/TensixTile/TensixCoprocessor/SFPCOMPC.md`
- `BlackholeA0/TensixTile/TensixCoprocessor/SFPPOPC.md`

**See also:** `LReg.md`, `VectorUnit.md`, `SFPSETCC.md`, `SFPCONFIG.md`

---

## `SFPENCC` – Enable/Disable Conditional Execution

**Syntax C-macro:** `TT_SFPENCC(Imm2, 0, VD, Mod1)`

**Operands:**
- `VD` (u4, 0–15) — destination flag register
- `Imm2` (u2, 0–3) — immediate mode
- `Mod1` (u4, 0–15) — modifier flags (OR-able)

**Constants:**
- `SFPENCC_IMM2_E` = 1 — enable predication
- `SFPENCC_IMM2_R` = 2 — reset `LaneFlags` from operand
- `SFPENCC_MOD1_EC` = 1 — enable conditional
- `SFPENCC_MOD1_EI` = 2 — enable inverted
- `SFPENCC_MOD1_RI` = 8 — reset `LaneFlags` from `Imm2_R`

**Operation:**
- Sets `UseLaneFlagsForLaneEnable` per lane based on `Imm2` and `Mod1`.
- When `Mod1` has `RI` bit set and `Imm2` has `R` bit set, `LaneFlags` are reset from the `Imm2_R` operand.
- Once enabled, lane flags control which lanes execute subsequent instructions.

**Register Constraints:**
- All four instructions: if `VD < 12 || LaneConfig.DISABLE_BACKDOOR_LOAD`. Values 12–15 require `DISABLE_BACKDOOR_LOAD` to be set.

---

## `SFPPUSHC` – Push / Mutate Flag Stack

**Syntax C-macro:** `TT_SFPPUSHC(0, 0, VD, Mod1)`

**Operands:**
- `VD` (u4, 0–15) — destination flag register
- `Mod1` (u4, 0–15) — operation mode

**Constants:** (Mod1 values)
- 0: Plain push — push current flags onto stack
- 1–12: BooleanOp function (see table below): A = stack top `LaneFlags`, B = current `LaneFlags`. Result replaces stack top.
- 13: Invert and push — `LaneFlags = !LaneFlags`, then push
- 14: Set true and push — `LaneFlags = {true, true}`, then push
- 15: Set false and push — `LaneFlags = {true, false}`, then push

**Architecture Note:** Mod1 != 0 is Blackhole-specific. Wormhole only supports Mod1 = 0 (plain push).

**UndefinedBehavior():**
- `SFPPUSHC` with Mod1 = 0 (plain push) on a full stack (8 entries)
- `SFPPUSHC` with Mod1 != 0 on an empty stack

**Register Constraints:**
- If `VD < 12 || LaneConfig.DISABLE_BACKDOOR_LOAD`. Values 12–15 require `DISABLE_BACKDOOR_LOAD`.

---

## `SFPCOMPC` – SIMT `else` Mapping

**Syntax C-macro:** `TT_SFPCOMPC(0, 0, VD, 0)`

**Operands:**
- `VD` (u4, 0–15) — destination flag register

**Operation:**
Computes the inverse of current lane flags for `else` branch execution:
