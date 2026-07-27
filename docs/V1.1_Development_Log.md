# Development Log — V1.1

## Goal

Widen instruction coverage per the V1.1 roadmap: a full branch comparator
(`BNE`/`BLT`/`BGE`/`BLTU`/`BGEU`, not just `BEQ`), the remaining RV32I
instructions `SRA`/`SRAI`, `AUIPC`, and `FENCE`, plus a cleaner, more
modular ALU decoder.

---

## Branch Comparator

Rewrote `branch_comparator.v` to take `funct3` and implement all six
branch types in one case statement — `BLT`/`BGE` use `$signed()`
comparison, `BLTU`/`BGEU` compare the raw unsigned bits directly. Wired
`funct3` into the comparator's instantiation in both `ex_stage.v`
(pipeline) and `cpu.v` (single-cycle), since previously only `BEQ`
actually branched correctly even though the control unit flagged
`Branch = 1` for every branch opcode.

---

## SRA / SRAI

Added `SRA` to the ALU using `$signed(a) >>> b[4:0]`. On the decode side,
`SRLI`/`SRAI` (I-type) legitimately encode the same distinguishing bit at
`instruction[30]` that `SRL`/`SRA` (R-type) encode in their `funct7`
field — this is intentional in the RISC-V encoding, so no extra
special-casing was needed there.

---

## AUIPC — and a bug it exposed

`AUIPC` (`rd = pc + immediate`) is U-type, which means
`instruction[19:15]` isn't a real `rs1` — it's part of the immediate. The
datapath had always been reading it as a register regardless. Added a new
`Op1Sel` control signal (`register` / `PC` / `zero`) so the EX stage's
first ALU operand can be overridden for U-type instructions, threaded
through `control_unit` → `id_stage` → `id_ex_register` → `ex_stage`.

This mechanism turned out to be the exact fix for `LUI`'s previously
documented bug too (garbage register contents leaking into the loaded
immediate) — same root cause, so it rode along for free. Added a
regression test for it: `lui x15, 0x8` was deliberately chosen so the
immediate's bit pattern sets `instruction[19:15] = 1` — i.e. it would have
been misread as `rs1 = x1`, a register holding a nonzero value elsewhere
in the test program. Confirmed the result is exactly `0x8000`, not
`0x8000 + x1`.

---

## FENCE

Explicitly decoded as a documented NOP. This pipeline is single-issue,
in-order, with no caching, so there's no memory reordering to fence
against. The default control signals already produced this behavior — the
explicit case just makes the intent visible in the code instead of
silently relying on "falls through to defaults."

---

## ALU Decoder Cleanup — and a self-inflicted bug

The first rewrite of `alu_control.v` used `funct7[5]` as a single bit to
distinguish `ADD`/`SUB` and `SRL`/`SRA`. Correct for R-type, and correct
for I-type *shift*-immediates (`SRLI`/`SRAI` really do encode that bit
meaningfully) — but wrong for `ADDI`: there is no `SUBI` in RV32I, so
`funct3=000` with an immediate is *always* `ADDI`. A negative immediate's
upper bits can coincidentally equal `0100000`, and the naive bit check
would wrongly select `SUB` instead.

Caught immediately because the new test program includes
`addi x6, x0, -1`, which should give `x6 = -1` but instead came out as
`x6 = 1` — i.e. `0 - (-1)` instead of `0 + (-1)`, a clean signal that the
wrong ALU operation was being selected. Root-caused it by noticing every
*positive*-immediate `ADDI` in the test still passed, and only the
negative-immediate cases (`-1`, `-16`) broke — pointing straight at the
sign-extended upper bits of the immediate being misread as a `funct7`.

**Fix**: added an `is_itype` input to `alu_control` (wired to `ALUSrc`,
which is already `1` for exactly the I-type ALU ops and `0` for R-type),
and only apply the `ADD`/`SUB` bit-check when `is_itype` is false. The
`SRL`/`SRA` check deliberately ignores `is_itype`, since that bit *is*
meaningful for both R-type and I-type shifts.

Added a dedicated regression case to `alu_control_tb.v`: feed it
`funct3=000, funct7=1111111, is_itype=1` and confirm it still resolves to
`ADD`, not `SUB`.

---

## Stale Testbenches

Widening `alu_control` and `branch_comparator`'s interfaces left two
per-module testbenches with dangling ports. Updated both instead of
leaving them silently untested:

- `alu_control_tb.v` — added `is_itype` coverage and the ADDI regression case
- `branch_comparator_tb.v` — now covers all six branch types

While cleaning up, also found two testbenches left stale from the earlier
pipeline work:

- `program_counter_tb.v` — was missing the `pc_write` port
- `register_file_tb.v` — was missing the `reset` port; also added a
  same-cycle write-first bypass test while in there

---

## Test Program

25 instructions covering: `BNE`/`BLT`/`BGE`/`BLTU`/`BGEU` (each with a
taken-branch skip check), `SRAI`, `SRLI`, `SRA`, `AUIPC`, `LUI`
(regression test), and `FENCE` (confirmed the instruction immediately
after it still executes normally).

## Simulation Results

```text
x1  = 5    (expect 5)
x2  = 10   (expect 10)
x3  = 7    (expect 7, must skip 111)
x4  = 8    (expect 8, must skip 222)
x5  = 9    (expect 9, must skip 233)
x6  = -1   (expect -1 / 0xffffffff)
x7  = 11   (expect 11, must skip 244)
x8  = 12   (expect 12, must skip 255)
x9  = 5    (expect 5, sentinel: executes normally right after fence)
x10 = -16  (expect -16)
x11 = -4   (expect -4, SRAI)
x12 = 268435455 (expect 268435455, SRLI)
x13 = -1   (expect -1, SRA)
x14 = 4184 (expect 4184, AUIPC)
x15 = 32768 (expect 32768, LUI -- regression test for the old rs1-garbage bug)
```

Also re-ran the original hazard/forwarding pipeline test and the
single-cycle CPU test: both still pass, zero regressions. The full
`rtl/*.v testbench/*.v` suite compiled clean (zero errors, zero dangling
ports) on both the packaged Icarus Verilog and a from-source build of
iverilog-13.

---

## Known Gaps Still Open After V1.1

- `SLTU`/`SLTIU` decode but fall back to `ADD` (not implemented — flagged
  explicitly in `alu_control.v`)
- `JALR` not implemented
- No dedicated CPU-level (fetch→writeback) test yet for
  `AND`/`OR`/`XOR`/`SLL`/`SRL`/`SLT` in isolation — covered indirectly via
  the ALU and ALU-control unit tests, but not through a full instruction

## Next Steps

- `SLTU`/`SLTIU`
- `JALR`
- CPU-level tests for the remaining ALU ops
- Start the Yosys synthesis flow