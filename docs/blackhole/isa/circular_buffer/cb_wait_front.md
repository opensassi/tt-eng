# `cb_wait_front` – Circular Buffer Wait Front

**Category:** Circular Buffer

**Syntax:** `cb_wait_front(CBHandle cb_id, uint32_t n_tiles)`

**Operation:** Block the calling Baby RISC-V core until `n_tiles` are available at the front of circular buffer `cb_id`. Returns when data is ready. The call interacts with the circular buffer manager's semaphore mechanism: "available" means the write pointer has advanced past the read pointer by at least `n_tiles` worth of data. Once the producer (e.g. `cb_push_back`) signals the semaphore, the blocked consumer is released.

**x86 Equivalent:** No direct equivalent

**Notes:**
- Used by consumer kernels (reader, compute) to wait for data
- Blocks only the calling Baby RISC-V core until data arrives; no hardware-level effects beyond the core
- Tile size is configured at CB creation time
- Typically used in reader or compute kernels; writer kernels should not call this unless repurposing a CB
- Ordering: `cb_reserve_back` / `cb_push_back` (producer) must be paired with `cb_wait_front` / `cb_pop_front` (consumer). Calling `cb_wait_front` after a matching `cb_reserve_back`/`cb_push_back` sequence is undefined if the buffer is shared across directions.
- Valid `cb_id` range: [`cb_0`, `cb_31`] (device-dependent; see chip-specific CB allocation table)
- `n_tiles` must be ≤ the CB's total tile capacity; exceeding this causes permanent deadlock

**Performance Characteristics:**
- Variable-latency blocking call — dependent on the producer filling the buffer
- Minimum latency is 0 cycles if data is already present (fast-path check)
- No deterministic cycle count; the core stalls until the semaphore is signaled

**Example (C++ kernel — acquire → read → release):**
```cpp
// Consumer kernel (reader/compute)
CBHandle cb_id = cb_0;       // circular buffer handle
uint32_t n_tiles = 1;         // tiles to consume

cb_wait_front(cb_id, n_tiles);
uint32_t* ptr = get_read_ptr(cb_id);  // or cb_read_tile(cb_id, ...)
// ... use data ...
cb_pop_front(cb_id, n_tiles);
