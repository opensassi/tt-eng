# `cb_pop_front` – Circular Buffer Pop Front

**Category:** Circular Buffer

**Syntax:** `cb_pop_front(cb_id, n_tiles)`

**Operation:** Remove `n_tiles` from the front of circular buffer `cb_id`. Frees the space for the producer to write new data.

CB follows a producer/consumer convention: the producer pushes tiles to the back of the buffer, and the consumer reads (via `cb_wait_front`) and pops from the front. Reading tile data with `cb_wait_front` does NOT free CB space — waiting and popping are deliberately separated into two operations. The consumer must first wait for tiles to be available, read them, then call `cb_pop_front` to free the space.

For correct read pointer wrap behavior, the total number of tiles popped across all `cb_pop_front` calls within one complete cycle must sum exactly to the CB size (`fifo_num_pages`). If the sum is less, the read pointer does not wrap correctly; if it exceeds the CB size, behavior is undefined.

**Example (CB size 12):**
- `cb_pop_front(cb_id, 5)` then `cb_pop_front(cb_id, 7)` — correct (5 + 7 = 12)
- `cb_pop_front(cb_id, 7)` then `cb_pop_front(cb_id, 7)` — error (7 + 7 > 12)

**x86 Equivalent:** No direct equivalent

**Parameters:**

| Parameter | Type | Valid Range | Description |
|-----------|------|-------------|-------------|
| `cb_id` | `uint32_t` | 0–31 | Circular buffer index |
| `n_tiles` | `uint32_t` | ≤ CB size | Number of tiles to remove from front |

**Return Value:** None

**C++ Example:**

```cpp
// Producer-consumer pattern with paired wait/pop
cb_wait_front(cb_id, 4);  // Wait for 4 tiles to be available
// Read tile data from CB (e.g., via l1_read)
cb_pop_front(cb_id, 4);   // Free the 4 tiles for producer reuse
