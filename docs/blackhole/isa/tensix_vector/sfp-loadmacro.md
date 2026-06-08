# `SFPLOADMACRO` – Load + Schedule Additional Instructions

**Category:** SFPU Data Movement

**Summary:** This instruction starts by executing as per [`SFPLOAD`](SFPLOAD.md) to move (up to) 32 datums from [`Dst`](Dst.md) to an `LReg`. It then schedules up to four additional Vector Unit (SFPU) instructions for execution in future cycles, consisting of at most one instruction from each of the following four columns:

|Simple (at most one †)|MAD (at most one)|Round (at most one †)|Store (at most one)|
|---|---|---|---|
|`SFPABS`<br/>`SFPAND`<br/>`SFPARECIP`<br/>`SFPCAST`<br/>`SFPCOMPC`<br/>`SFPCONFIG`<br/>`SFPDIVP2`<br/>`SFPENCC`<br/>`SFPEXEXP`<br/>`SFPEXMAN`<br/>`SFPGT`<br/>`SFPIADD`<br/>`SFPLE`<br/>`SFPLZ`<br/>`SFPMOV`<br/>`SFPNOP`<br/>`SFPNOT`<br/>`SFPOR`<br/>`SFPPOPC`<br/>`SFPPUSHC`<br/>`SFPSETCC`<br/>`SFPSETEXP`<br/>`SFPSETMAN`<br/>`SFPSETSGN`<br/>`SFPSHFT`<br/>`SFPSWAP` (‡)<br/>`SFPTRANSP`<br/>`SFPXOR`|`SFPADD`<br/>`SFPADDI`<br/>`SFPLUT`<br/>`SFPLUTFP32`<br/>`SFPMAD`<br/>`SFPMUL`<br/>`SFPMULI`<br/>`SFPMUL24`<br/>`SFPNOP`|`SFPNOP`<br/>`SFPSHFT2`<br/>`SFPSTOCHRND`|`SFPSTORE`|

(†) If a Simple instruction and a Round instruction execute on the same cycle, then one of them needs to have `VD == 16` and the other needs to have `VD != 16`.

(‡) If `SFPSWAP` is scheduled to the Simple sub-unit, then `SFPNOP` needs to be scheduled to the MAD sub-unit for the same time, and both of the Simple and Round sub-units either need to be idle on the next cycle or have `SFPNOP` scheduled for then.

The Vector Unit (SFPU) is capable of executing up to five instructions per cycle: one load-style instruction (`SFPLOAD` or `SFPLOADI` or `SFPLOADMACRO` or `SFPNOP`), and then one instruction from each of the above four columns. `SFPLOADMACRO` is the only mechanism for attaining more than one instruction per cycle.

**Backend execution unit:** [Vector Unit (SFPU)](VectorUnit.md), load sub-unit

## Syntax

```c
TT_SFPLOADMACRO(((/* u2 */ MacroIndex) << 2) +
                  /* u2 */ VDLo,
                  /* u4 */ Mod0,
                  /* u3 */ AddrMod,
                ((/* u9 */ Imm9) << 1) +
                  /* u1 */ VDHi)
