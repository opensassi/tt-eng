# `cb_push_back` – Circular Buffer Push Back

**Category:** Circular Buffer

**Syntax:** `cb_push_back(cb_id, n_tiles)`

**Operation:** Commits `n_tiles` of data to the back of circular buffer `cb_id` by advancing the write pointer. The data is already present in L1 (written via prior stores). After this call, the tiles are visible to the consumer kernel. The operation acts as a release fence: all previous writes to the buffer region are made visible before the consumer can acquire the tiles via `cb_wait_front`.

**x86 Equivalent:** No direct equivalent

**Notes:**
- Used by producer kernels (reader or compute) to signal data availability
- Must be preceded by `cb_reserve_back` to allocate space
- Consumer waits with `cb_wait_front`
- Data must already be written to L1 before calling `cb_push_back`; the call does not copy or move data
- The write pointer is advanced by `n_tiles * tile_size` bytes, where `tile_size` is inferred from the circular buffer configuration at compile time

**Configuration Requirements:**
- Valid `cb_id` range: 0–31 (implementation-defined; may vary by device)
- Tile size is set at buffer configuration time; all tiles pushed must match the configured size
- The buffer base address must be 32-byte aligned; tile size must be a multiple of 32 bytes
- `n_tiles` must not exceed the number of reserved tiles from `cb_reserve_back`

**Performance Characteristics:**
- Latency: ~4–6 cycles in the write-pointer advance pipeline (typical); actual wall time depends on memory subsystem congestion and is dominated by preceding L1 writes rather than the push-back itself

**Usage Example:**
```cpp
// Producer kernel (reader or compute)
uint32_t cb_id = tt::CB::c_in0;
uint32_t n_tiles = 4;

cb_reserve_back(cb_id, n_tiles);

uint32_t l1_addr = get_write_ptr(cb_id);
for (uint32_t i = 0; i < n_tiles; i++) {
    uint32_t tile_offset = i * TILE_SIZE_WORDS;
    // Write tile data directly to L1 at l1_addr + tile_offset
    l1_buffer[l1_addr + tile_offset] = tile_data[i];
}

// Signal consumer that tiles are ready
cb_push_back(cb_id, n_tiles);

// Consumer kernel
cb_wait_front(cb_id, n_tiles);
uint32_t read_addr = get_read_ptr(cb_id);
// ... process tiles at read_addr ...
cb_pop_front(cb_id, n_tiles);
