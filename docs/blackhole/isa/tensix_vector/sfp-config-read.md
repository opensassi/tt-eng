# `SFPMOV` – Read Configuration (Mode)

**Category:** SFPU Data Movement

**Syntax:** `TT_SFPMOV(0, VC, VD, Mod1)`

**Mod1 Fields:**

| Bit | Value | Field | Description |
|-----|-------|-------|-------------|
| 0 | 1 | SFPMOV_MOD1_NEGATE | Negate the result |
| 1 | 2 | SFPMOV_MOD1_ALL_LANES_ENABLED | Bypass lane mask when set |
| 2 | 4 | (reserved) | Setting this triggers NonContractualBehavior |
| 3 | 8 | SFPMOV_MOD1_FROM_SPECIAL | Selects config read mode |

**Operation:**
