# `dma_write` – TDMA Bulk Write

**Category:** Data Movement (TDMA-RISC)

**Syntax:** Configured via TDMA-RISC registers (`0xFFB1_1000-1FFF`)

**Operation:** Initiate a bulk DMA write from local L1 to DRAM or remote L1. Offloaded from the Baby RISC-V to the TDMA-RISC coprocessor.

**x86 Equivalent:** Non-temporal store sequence / DMA engine

**Notes:** Same TDMA-RISC engine as `dma_read`. Supports strided and rectangular layouts.
