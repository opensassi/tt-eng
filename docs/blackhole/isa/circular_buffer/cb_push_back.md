# `cb_push_back` – Circular Buffer Push Back

**Category:** Circular Buffer

**Syntax:** `cb_push_back(cb_id, n_tiles)`

**Operation:** Commit `n_tiles` of data to the back of circular buffer `cb_id`. Makes the tiles visible to the consumer kernel.

**x86 Equivalent:** No direct equivalent

**Notes:**
- Used by producer kernels (reader or compute) to signal data availability
- Must be preceded by `cb_reserve_back` to allocate space
- Consumer waits with `cb_wait_front`
