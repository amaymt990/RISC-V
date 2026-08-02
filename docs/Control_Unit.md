# Control Unit

`control_unit.v` is the single source of truth for instruction decode in
this design — every control signal that drives the rest of the datapath
(ALU operand selection, memory access, register writeback, branch/jump
behavior) originates here, decoded purely from the instruction's 7-bit
opcode field. Both `cpu.v` (single-cycle) and `id_stage.v` (pipeline's ID
stage) instantiate the same module.

```verilog
module control_unit(
    input [6:0] opcode,
    output reg RegWrite,
    output reg ALUSrc,
    output reg MemRead,
    output reg MemWrite,
    output reg MemtoReg,
    output reg Branch,
    output reg Jump,
    output reg JALR,
    output reg [1:0] ALUOp,
    output reg [1:0] Op1Sel
);
```

For how each of these signals is *consumed* downstream (ALU muxing,
pipeline register fields, etc.), see `datapath.md` and `pipeline.md`.
This document focuses on the decode logic itself.

---

## Design Pattern: Defaults First, Then Override

The module is a single combinational `always @(*)` block that sets every
output to a safe default before the `case` statement runs:

```verilog
always @(*) begin
    RegWrite = 0;
    ALUSrc   = 0;
    MemRead  = 0;
    MemWrite = 0;
    MemtoReg = 0;
    Branch   = 0;
    Jump     = 0;
    JALR     = 0;
    ALUOp    = 2'b00;
    Op1Sel   = OP1_REG;

    case(opcode)
        ...
    endcase
end
```

This means every `case` branch only needs to set the signals that differ
from "do nothing" — and, just as importantly, it means an *unrecognized*
opcode (or `FENCE`, which intentionally has no body in its case branch)
automatically produces a full NOP: no register write, no memory access,
no branch, no jump. This is what makes `FENCE`'s decode case legitimately
just an empty `begin end` block with a comment — the defaults already do
the right thing, the empty case just documents that this was a deliberate
decision, not a missing one.

---

## Full Decode Table

| Opcode (binary) | Instruction(s) | `RegWrite` | `ALUSrc` | `MemRead` | `MemWrite` | `MemtoReg` | `Branch` | `Jump` | `JALR` | `ALUOp` | `Op1Sel` |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `0110011` | R-type (`ADD`/`SUB`/`AND`/`OR`/`XOR`/`SLL`/`SRL`/`SRA`/`SLT`/`SLTU`) | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | `10` | `REG` |
| `0010011` | I-type ALU (`ADDI`/`ANDI`/`ORI`/`XORI`/`SLLI`/`SRLI`/`SRAI`/`SLTI`/`SLTIU`) | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | `10` | `REG` |
| `0000011` | `LW` | 1 | 1 | 1 | 0 | 1 | 0 | 0 | 0 | `00` | `REG` |
| `0100011` | `SW` | 0 | 1 | 0 | 1 | 0 | 0 | 0 | 0 | `00` | `REG` |
| `1100011` | Branches (`BEQ`/`BNE`/`BLT`/`BGE`/`BLTU`/`BGEU`) | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | `01` | `REG` |
| `1101111` | `JAL` | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | `00` | `REG` |
| `1100111` | `JALR` | 1 | 1 | 0 | 0 | 0 | 0 | 1 | 1 | `00` | `REG` |
| `0110111` | `LUI` | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | `00` | `ZERO` |
| `0010111` | `AUIPC` | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | `00` | `PC` |
| `0001111` | `FENCE` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | `00` | `REG` |
| *(anything else)* | unrecognized | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | `00` | `REG` |

(`REG`/`PC`/`ZERO` are `Op1Sel`'s three `localparam` values — see below.)

---

## Per-Opcode Notes

**R-type / I-type ALU (`0110011` / `0010011`)** — the only difference
between these two cases is `ALUSrc`. Both set `ALUOp = 10`, deferring the
*specific* operation (`ADD` vs `AND` vs `SLL`, etc.) entirely to
`alu_control.v`, which decodes `funct3`/`funct7` — `control_unit.v`
itself never looks at those fields. This keeps the two decoders cleanly
separated: this module answers "what kind of instruction is this," not
"which exact ALU operation does it need."

**Loads and stores (`0000011` / `0100011`)** — both use `ALUOp = 00`
(force `ADD`), since the address calculation is always `rs1 + immediate`
regardless of instruction type. `MemtoReg` is the signal that
distinguishes them at writeback: only `LW` sets it, routing the
writeback mux to `data_memory`'s output instead of the ALU result.

**Branches (`1100011`)** — sets `ALUOp = 01`, which `alu_control.v`
maps to a fixed `SUB` — but this is a legacy/unused code path.
`alu_result` is never actually consulted for a branch's outcome;
`branch_comparator.v` (fed directly from the EX stage's, possibly
forwarded, operands — see `hazard_unit.md`) does the real, `funct3`-aware
comparison. `control_unit.v` sets `Branch = 1` identically for all six
branch types — `BEQ` through `BGEU` all share this single opcode, and
it's `branch_comparator.v`'s job, not this module's, to tell them apart.

**`JAL` vs `JALR` (`1101111` / `1100111`)** — both set `Jump = 1`
(unconditional redirect), but only `JALR` sets the `JALR` bit, which
`ex_stage.v` uses to select between the two different jump-target
formulas (`pc + immediate` vs `(rs1 + immediate) & ~1` — see
`datapath.md`). `JALR` also needs `ALUSrc = 1`, since — unlike `JAL`,
which needs no immediate for anything but its target address — `JALR`'s
immediate is added to `rs1` as part of that target calculation.

**`LUI` vs `AUIPC` (`0110111` / `0010111`)** — structurally identical
except for `Op1Sel`. Both are U-type (no real `rs1` field — see below),
both need `ALUSrc = 1` to route the immediate into the ALU's second
operand, and both rely on `Op1Sel` to supply a correct *first* operand
instead of a garbage register read.

**`FENCE` (`0001111`)** — see "Design Pattern" above. All-defaults NOP,
kept as an explicit (empty) case purely so the intent reads clearly in
the source rather than relying on silent fallthrough.

---

## `Op1Sel`: Why a Third Control Signal Was Needed

```verilog
localparam OP1_REG  = 2'b00;
localparam OP1_PC   = 2'b01;
localparam OP1_ZERO = 2'b10;
```

Every RV32I instruction format *except* U-type places `rs1` at
`instruction[19:15]`. U-type (`LUI`, `AUIPC`) has no `rs1` field at
all — those same bit positions are part of the 20-bit immediate. Earlier
in this project, that distinction wasn't respected: the datapath read
`instruction[19:15]` as `rs1` unconditionally, so `LUI` had a real bug —
it would add whatever register that bit pattern happened to name to the
immediate, instead of just loading the immediate directly.

`Op1Sel` fixes this at the decode level: it tells the EX stage's operand-1
mux (in `datapath.md`) to substitute `PC` (for `AUIPC`'s `rd = pc +
immediate`) or `0` (for `LUI`'s `rd = 0 + immediate = immediate`) instead
of trusting whatever's in the register file at that (potentially
meaningless) address. `JALR`, despite also needing special handling for
its jump target, does *not* need `Op1Sel` — it's I-type, with a real
`rs1`, so `Op1Sel` correctly defaults to `OP1_REG` for it.

---

## Where It's Instantiated

- **`id_stage.v`** (pipeline) — `opcode = instruction[6:0]` from the
  freshly-fetched instruction; its outputs are latched into `id_ex_
  register.v` the same cycle, to be consumed later by `ex_stage.v`.
- **`cpu.v`** (single-cycle) — same instantiation pattern, but its
  outputs drive the datapath combinationally within the same cycle, since
  there's no pipeline register in between.

Both share the exact same `control_unit.v` file — there is no
single-cycle-specific or pipeline-specific version of the decode logic.