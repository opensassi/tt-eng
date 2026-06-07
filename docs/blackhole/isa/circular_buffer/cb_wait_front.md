# `cb_wait_front` – Circular Buffer Wait Front

**Category:** Circular Buffer

**Syntax:** `cb_wait_front(cb_id, n_tiles)`

**Operation:** Block until `n_tiles` are available at the front of circular buffer `cb_id`. Returns when data is ready.

**x86 Equivalent:** No direct equivalent

**Notes:**
- Used by consumer kernels (compute or writer) to wait for data
- Blocks the Baby RISC-V core until data arrives
- Tile size is configured at CB creation time
