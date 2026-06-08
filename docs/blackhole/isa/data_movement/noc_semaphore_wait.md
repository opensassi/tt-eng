# `noc_semaphore_wait` – NoC Semaphore Wait

**Category:** Synchronization

**Syntax:** `noc_semaphore_wait(volatile tt_l1_ptr uint32_t* sem_addr, uint32_t val)`

**Operation:** Spin-wait until a semaphore value in local L1 becomes exactly equal to the specified target value.

**x86 Equivalent:** `pause` + spin loop / `futex`

**Latency:** Dependent on producer timing

**Preconditions:**
- `sem_addr` must point to a semaphore word in **local** L1 (not remote)
- The semaphore must be initialized before calling (e.g., via `noc_semaphore_set`)
- The pointer must be `volatile` to prevent compiler elision of the load

**Notes:**
- Spin-wait; consumes CPU cycles
- Typically paired with `noc_semaphore_inc` on a remote core
- Used for barrier synchronization and producer-consumer handshakes
- L1 data cache is invalidated on each iteration of the spin loop to ensure visibility of remote writes; without this, stale cached values can cause missed wakeups or infinite spinning
- Callers often cast a raw address: `reinterpret_cast<volatile tt_l1_ptr uint32_t*>(addr)`
- For `>=` (greater-or-equal) semantics, use `noc_semaphore_wait_min`
- This is a TT-Metalium API function (`tt_metal/hw/inc/api/dataflow/dataflow_api.h:1929-1937`), not a native Tensix ISA instruction; it compiles to a polling loop on the RISC-V core

**Example:**
```cpp
volatile tt_l1_ptr uint32_t* sem = reinterpret_cast<volatile tt_l1_ptr uint32_t*>(sem_l1_addr);
noc_semaphore_set(sem, 0);
// ... remote core calls noc_semaphore_inc(sem, 1) ...
noc_semaphore_wait(sem, 1);  // Spin until value becomes exactly 1
