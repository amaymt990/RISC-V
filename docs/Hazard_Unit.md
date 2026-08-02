# Hazard Handling

Pipelining creates a correctness problem that a single-cycle design never
has: multiple instructions are in flight at once, so an instruction can
reach a stage that needs a value another, still-in-flight instruction
hasn't produced yet. This document covers the three mechanisms that make
the pipeline produce the same result as the single-cycle CPU despite
that: **forwarding**, **stalling**, and **flushing**.

---

## Data Hazards: Read-After-Write

A data hazard happens when an instruction needs a register value that a
recent, not-yet-written-back instruction is about to produce. There are
three distinct cases, each handled by a different mechanism, depending on
how far apart the producer and consumer are:

| Distance | Example | Mechanism |
|---|---|---|
| 1 apart (back-to-back) | `add x2,x1,x1` right after producing `x1` | Forwarding, from EX/MEM |
| 2 apart | one instruction in between | Forwarding, from MEM/WB |
| 3 apart | two instructions in between | Register file write-first bypass (no forwarding needed) |
| Load, 1 apart | `lw` immediately followed by a dependent instruction | **Stall** — forwarding can't save this one |

### Forwarding (`forwarding_unit.v`)

Compares the source registers of the instruction currently in EX
(`id_ex_rs1`/`id_ex_rs2`) against the destination registers sitting in
EX/MEM and MEM/WB:

```verilog
if (ex_mem_regwrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1))
    forwardA = 2'b10;   // forward from EX/MEM
else if (mem_wb_regwrite && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1))
    forwardA = 2'b01;   // forward from MEM/WB
else
    forwardA = 2'b00;   // no hazard, use the value latched in ID/EX
```

(Same logic, independently, for `forwardB`/`rs2`.) EX/MEM is checked
*first* — if a register happens to match both a pending EX/MEM result and
an older pending MEM/WB result, EX/MEM wins because it's the more recent
value.

These `forwardA`/`forwardB` signals feed directly into `ex_stage.v`'s
ALU-operand muxes (see `datapath.md`) — the forwarded value is used
*instead of* whatever's sitting in the ID/EX register, with zero cycles
lost. This also feeds the branch comparator, so a branch depending on the
immediately preceding instruction's result still evaluates correctly.

### Load-Use Hazard (`hazard_detection_unit.v`)

Forwarding from EX/MEM works because an ALU result is ready at the *end*
of the EX stage — in time to forward into the *next* instruction's EX
stage the following cycle. A load's result isn't ready until the *end of
MEM*, one stage later. If the consumer is immediately behind the load,
there's no cycle in which forwarding could deliver the value in time.

```verilog
if (id_ex_memread && (id_ex_rd != 5'd0) &&
    ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)))
    stall = 1'b1;
```

When this fires, the pipeline stalls for exactly one cycle:

- `pc_write = 0` — freeze the PC
- IF/ID's `stall` input — freeze the fetched instruction in place
- ID/EX gets a bubble (`flush`, forcing all its control signals to zero)

After one stall cycle, the load's result is in EX/MEM and reachable by
ordinary EX/MEM forwarding, so the pipeline resumes normally.

### Register File Write-First Bypass

Covered in `datapath.md` in detail — this is what handles the case where
the producer is *exactly* 3 instructions ahead, meaning it's in WB the
same cycle the consumer is in ID (reading the register file directly,
before ever reaching EX where forwarding operates). Without this,
forwarding alone would miss this case entirely, since the forwarding
unit only compares against instructions in EX/MEM and MEM/WB — not
against WB itself.

---

## Control Hazards: Branches and Jumps

`branch_comparator` resolves in the **EX** stage — by the time a branch
is known to be taken, two more instructions have already been fetched
down what turns out to be the wrong path (one in IF/ID, one about to
enter EX itself as ID/EX gets loaded this same cycle).

```verilog
assign pipeline_flush = (id_ex_Branch && ex_branch_taken) || id_ex_Jump;
```

Any jump (`JAL`/`JALR`, unconditional) or a branch that evaluates taken
sets this signal, which does two things simultaneously:

1. Redirects the IF stage's `next_pc` to the computed `branch_target`
   instead of `pc + 4`
2. Flushes **both** IF/ID and ID/EX — forcing both to a zeroed bubble —
   since both currently hold wrong-path instructions

This costs **2 cycles per taken branch or jump** (no branch prediction —
every branch is implicitly "predict not-taken," and every jump always
"mispredicts" since there's no way to know the target early). This is a
real, intentional simplicity/performance tradeoff, not a bug — worth
knowing if you're evaluating this pipeline's IPC.

---

## Priority When Multiple Hazards Overlap

- **IF/ID**: `flush` (branch/jump) is checked before `stall` (load-use) —
  in the `always` block's if/else chain, reset > flush > stall > normal load.
- **ID/EX**: a single `flush` input covers both cases
  (`pipeline_flush || hazard_stall`) — either one inserts a bubble.
- **EX/MEM, MEM/WB**: no flush logic at all — by the time an instruction
  reaches these registers, it's guaranteed to be on the correct path (it
  either wasn't a hazard-causing instruction, or it *was* the branch/jump
  itself, which is never wrong-path relative to its own resolution).

---

## Worked Example

The pipeline's own test program (`testbench/cpu_pipeline_tb.v`) exercises
all of the above in one sequence:

```assembly
addi x1, x0, 5         # x1 = 5
add  x2, x1, x1        # x2 = 10   -- 1-apart RAW, needs EX/MEM forward
addi x3, x2, 0         # x3 = 10   -- 2-apart RAW, needs MEM/WB forward
sw   x2, 0(x1)         # mem[5] = 10
lw   x4, 0(x1)         # x4 = 10
addi x5, x4, 0         # x5 = 10   -- load-use hazard, must stall 1 cycle
beq  x1, x1, +8        # always taken -- flush 2 bubbles
addi x6, x0, 85        # must be skipped (wrong-path, flushed)
addi x7, x0, 99        # branch target
```

Every register lands on its expected value — confirming forwarding,
stalling, and flushing all work correctly, not just individually but
together in sequence. Full results and waveform-level verification in
`verification.md`.