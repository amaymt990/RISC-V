# Pipeline

`cpu_pipeline.v` implements a classic 5-stage RISC pipeline:
**IF → ID → EX → MEM → WB**, with one instruction (nominally) in each
stage every cycle. This document covers how the stages and pipeline
registers are structured; see `hazard_unit.md` for how the pipeline stays
*correct* when instructions in different stages depend on each other.

```
   IF        ID        EX        MEM       WB
 ┌────┐    ┌────┐    ┌────┐    ┌─────┐   ┌────┐
 │fetch├───▶│decode├──▶│exec ├──▶│memory├─▶│write│
 └────┘    └────┘    └────┘    └─────┘   │back │
                                          └────┘
   │IF/ID│    │ID/EX│    │EX/MEM│   │MEM/WB│
   └─────┘    └─────┘    └──────┘   └──────┘
```

---

## Stage-by-Stage

### IF — Instruction Fetch

- `program_counter.v` holds the current PC, updated to `next_pc` each
  cycle (or held, if `pc_write` is deasserted by a stall — see
  `hazard_unit.md`)
- `instruction_memory.v` returns the instruction at that address
  (combinational read)
- `next_pc` is either `pc + 4` (the normal case) or the EX stage's
  computed `branch_target`, selected by `pipeline_flush`

### IF/ID Register (`if_id_register.v`)

Latches `pc` and `instruction` for the ID stage. Has two control inputs
beyond the usual `clk`/`reset`:

- `stall` — hold current contents (load-use hazard, see `hazard_unit.md`)
- `flush` — force contents to zero, i.e. insert a bubble (branch/jump
  resolved taken)

`flush` takes priority over `stall` in the implementation (checked first
in the `always` block) — in practice these two conditions come from
different pipeline positions and don't typically fire on the exact same
cycle for the same reason, but the priority ordering is there for
correctness regardless.

### ID — Instruction Decode

`id_stage.v` does two things every cycle:

1. Reads `rs1`/`rs2` from the register file (`register_file.v`),
   simultaneously accepting the writeback stage's write (`write_data`,
   `write_reg`, `reg_write` inputs) — this is the same-cycle read/write
   the register file's write-first bypass exists for.
2. Decodes the instruction's opcode into control signals via
   `control_unit.v` (see `architecture.md` for the full signal list).

Also derives `rs1`/`rs2` directly from the *IF/ID* stage's raw
instruction bits (`if_id_instruction[19:15]`/`[24:20]`) at the top level
in `cpu_pipeline.v` — this is needed one cycle *before* the ID stage
finishes decoding, specifically for the hazard detection unit (see
`hazard_unit.md`).

### ID/EX Register (`id_ex_register.v`)

The widest pipeline register — carries every decoded field and control
signal an instruction needs for the rest of its pipeline lifetime: `pc`,
`read_data1`/`read_data2`, `immediate`, `rs1`/`rs2`/`rd`, `funct3`/
`funct7`, and all the control signals (`RegWrite`, `ALUSrc`, `MemRead`,
`MemWrite`, `MemtoReg`, `Branch`, `Jump`, `JALR`, `ALUOp`, `Op1Sel`).

Has a single `flush` input (no separate `stall`) — a bubble is inserted
here for *either* a load-use stall or a branch/jump flush:

```verilog
.flush(pipeline_flush || hazard_stall)
```

### EX — Execute

`ex_stage.v` — the ALU, the forwarding muxes, the branch comparator, and
both jump/branch target address calculations all live here. Full detail
in `datapath.md` (combinational logic) and `hazard_unit.md` (forwarding).

This is also where control-flow decisions are finalized:

```verilog
assign pipeline_flush = (id_ex_Branch && ex_branch_taken) || id_ex_Jump;
```

A taken branch or any jump (`JAL`/`JALR`) sets `pipeline_flush`, which
both redirects the PC (via the IF stage's `next_pc` mux) and flushes the
two instructions already fetched down the wrong path (IF/ID and ID/EX).

### EX/MEM Register (`ex_mem_register.v`)

Carries `alu_result`, `store_data` (the possibly-forwarded value to
write for `SW`), `rd`, `branch_target`/`branch_taken` (unused past this
point except by the flush logic above, which reads them the same cycle),
`pc_plus4` (for the `JAL`/`JALR` link value), and the remaining relevant
control signals.

No `flush` input — unlike IF/ID and ID/EX, an instruction reaching EX/MEM
is never a wrong-path instruction being squashed; if it caused a flush
(because it was a taken branch or jump), it's still the *correct*
instruction and needs to complete normally.

### MEM — Memory Access

`mem_stage.v` — a thin wrapper around `data_memory.v`, gated by the
`MemRead`/`MemWrite` control signals carried from EX/MEM.

### MEM/WB Register (`mem_wb_register.v`)

Carries `read_data` (from memory), `alu_result`, `pc_plus4`, `rd`, and
the control signals still needed at this point: `RegWrite`, `MemtoReg`,
`Jump`.

### WB — Writeback

`wb_stage.v` — picks the final value to write back to the register file:

```verilog
assign write_back_data =
        Jump     ? pc_plus4 :
        MemtoReg ? read_data :
                   alu_result;
```

This value feeds back to two places simultaneously: the register file's
write port (via `id_stage.v`, for the write-first bypass) and the
forwarding unit's MEM/WB forwarding path (see `hazard_unit.md`).

---

## Instruction Timing Example

For a simple, hazard-free instruction sequence, each instruction is one
stage ahead of the next every cycle:

```
Cycle:      1    2    3    4    5    6
Instr A:   IF   ID   EX   MEM  WB
Instr B:        IF   ID   EX   MEM  WB
Instr C:             IF   ID   EX   MEM  WB
```

Throughput is one instruction per cycle in the ideal case. Hazards
(data dependencies, taken branches) reduce this — see `hazard_unit.md`
for exactly how much each hazard type costs and why.

---

## Single-Cycle vs. Pipelined: What's Different

`cpu.v` (single-cycle) uses the *same* ALU, control unit, immediate
generator, and branch comparator modules as the pipeline's EX/ID stages
— but wires them directly together with no pipeline registers, no
forwarding, and no hazard detection, since only one instruction is ever
in flight. Its `Op1Sel` and `JALR` handling mirror `ex_stage.v` exactly
(see `datapath.md`), just without the forwarding-mux layer in between,
since there's nothing to forward from — everything is combinationally
available in the same cycle.