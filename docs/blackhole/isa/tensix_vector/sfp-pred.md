# SFPU Lane Predication (SIMT Stack)

## Architecture

Each lane has a stack of flag entries `{ LaneFlags, UseLaneFlagsForLaneEnable }`. When `UseLaneFlags = true`, lanes with `LaneFlags = false` are disabled. Used to implement SIMT `if/else` control flow.

## `SFPENCC` – Enable/Disable Conditional Execution

**Syntax:** `SFPENCC Mode`

**Operation:** Set `UseLaneFlagsForLaneEnable` per lane. Once set to `true`, lane flags control which lanes execute subsequent instructions.

## `SFPPUSHC` – Push / Mutate Flag Stack

Push current flags onto stack, or compute new flags based on current state.

## `SFPCOMPC` – SIMT `else` Mapping

Computes the inverse of current lane flags for `else` branch execution.

## `SFPPOPC` – Pop Flag Stack

Restore previous flag state.

## Programming Model

```
SFPENCC ON                    ; Enable predication
SFPSETCC ...                  ; Set flags: lanes where condition is true get LaneFlags=true
  ... instructions for true branch ...
SFPPUSHC ...                  ; Invert flags
  ... instructions for false branch ...
SFPPOPC                       ; Restore
```

**Latency:** 1 cycle each, IPC=1

**Stack Depth Limit:**
- Flag stack supports max 8 elements
- `SFPPUSHC` with Mod1=0 (plain push) must not be used when stack is full
- `SFPPUSHC` with Mod1 != 0 requires stack non-empty
- `SFPPOPC` with Mod1=0 (plain pop) must not be used when stack is empty

**BooleanOp Function Table (SFPPUSHC/SFPPOPC Mod1 values 1-12):**

| Mod1 | BooleanOp(A, B) | Description |
|------|----------------|-------------|
| 1 | B | Pass B |
| 2 | !B | Not B |
| 3 | A && B | And |
| 4 | A \|\| B | Or |
| 5 | A && !B | And-not B |
| 6 | A \|\| !B | Or-not B |
| 7 | !A && B | Not-A-and B |
| 8 | !A \|\| B | Not-A-or B |
| 9 | !A && !B | Nor |
| 10 | !A \|\| !B | Nand |
| 11 | A != B | Xor |
| 12 | A == B | Xnor |

For `SFPPUSHC`: A = stack top LaneFlags, B = current LaneFlags. Result replaces stack top LaneFlags.
For `SFPPOPC` (Mod1=1-12): A = current LaneFlags, B = stack top LaneFlags. Result replaces current LaneFlags.

**Scheduling Notes:**
- All predication instructions execute on the simple sub-unit (1 cycle, no stalling)
- `SFPPOPC` complex modes (Mod1 != 0) have a hardware bug on Wormhole when stack is full; fixed in Blackhole
- Single-cycle throughput, fully pipelined
