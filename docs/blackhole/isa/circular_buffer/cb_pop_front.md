# `cb_pop_front` – Circular Buffer Pop Front

**Category:** Circular Buffer

**Syntax:** `cb_pop_front(cb_id, n_tiles)`

**Operation:** Remove `n_tiles` from the front of circular buffer `cb_id`. Frees the space for the producer to write new data.

**x86 Equivalent:** No direct equivalent

**Notes:**
- Called after processing data obtained via `cb_wait_front`
- Frees CB space for the producer to fill
- Must match the number consumed
