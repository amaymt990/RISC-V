# Datapath

This document walks through the combinational logic each instruction
passes through — the building blocks that are shared between the
single-cycle CPU (`cpu.v`) and the pipelined CPU's EX stage
(`ex_stage.v`). For how these blocks are arranged across pipeline stages
and clock cycles, see `pipeline.md`.

---

## Register File (`register_file.v`)

32 registers, 32 bits each. `x0` is hardwired to zero (writes to it are
silently discarded; reads always return `0`).

**Ports:**
```verilog
input clk, reset, we,
input [4:0] rs1, rs2, rd,
input [31:0] write_data,
output [31:0] read_data1, read_data2
```

**Write-first bypass.** In the pipeline, the writeback (WB) stage writes
to the register file in the *same cycle* that the decode (ID) stage reads
from it — a real structural hazard, not just a timing coincidence. If the
read logic only reflected the array's state from the previous clock edge,
a value being written back this cycle would appear stale to a
simultaneous read of the same register. The fix, in `register_file.v`:

```verilog
assign read_data1 = (rs1 == 5'd0) ? 32'd0 :
                     (we && rd == rs1 && rd != 5'd0) ? write_data :
                     registers[rs1];
```

If the register being written this cycle is the same one being read,
forward the write data directly instead of the (stale) array contents.
This is the mechanism that makes it safe for an instruction 3 positions
behind its producer to read the correct value straight out of the
register file, without needing the forwarding unit's help (see
`hazard_unit.md` for why forwarding alone doesn't cover this case).

---

## Immediate Generator (`immediate_generator.v`)

Extracts and sign-extends the immediate field for every RV32I instruction
format:

| Format | Used by | Bit layout |
|---|---|---|
| I-type | `ADDI`/loads/`JALR` | `instruction[31:20]`, sign-extended |
| S-type | Stores | `{instruction[31:25], instruction[11:7]}`, sign-extended |
| B-type | Branches | `{instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}`, sign-extended |
| U-type | `LUI`/`AUIPC` | `{instruction[31:12], 12'b0}` |
| J-type | `JAL` | `{instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}`, sign-extended |

`JALR` uses the same opcode-driven case as I-type (it shares the exact
same immediate encoding as `ADDI`/loads) — this needed to be added
explicitly, since `JALR`'s opcode (`1100111`) is distinct from
`ADDI`/loads' opcodes and wasn't originally covered by the I-type case
list.

---

## ALU Operand Selection (`ex_stage.v`)

Every instruction's two ALU operands are built the same way, regardless
of instruction type — the differences between instruction types are all
expressed as different *mux selections*, not different code paths:

```verilog
assign operand1 = (Op1Sel == 2'b01) ? pc :      // AUIPC
                   (Op1Sel == 2'b10) ? 32'd0 :   // LUI
                                       operand1_fwd;  // everything else: rs1 (forwarded)

assign operand2 = ALUSrc ? immediate : operand2_base;  // operand2_base = rs2 (forwarded)
```

`operand1_fwd` and `operand2_base` already include the forwarding-unit
muxing described in `hazard_unit.md` — the `Op1Sel` override sits
*after* that, so `AUIPC`/`LUI` always get a clean `PC`/`0` regardless of
what the (in their case, meaningless) forwarding comparison produced.

---

## ALU Control (`alu_control.v`)

Translates `{ALUOp, funct3, funct7}` into a 4-bit operation code for the
ALU itself:

| `ALUOp` | Meaning |
|---|---|
| `00` | Force `ADD` — used by loads, stores, `AUIPC`, `JAL`'s link value, `LUI` |
| `01` | `SUB` — legacy branch-comparison code path; `alu_result` is actually unused for branches (see below), kept for backward compatibility |
| `10` | Decode from `funct3`/`funct7` — covers all R-type and I-type ALU ops |

For `ALUOp == 10`, the specific operation is chosen by `funct3`, with one
extra wrinkle for two funct3 values that have two variants sharing the
same `funct3`:

```verilog
wire sub_alt   = funct7[5] && !is_itype;
wire shift_alt = funct7[5];
```

`funct7[5]` distinguishes `ADD`/`SUB` and `SRL`/`SRA` — but **only for
R-type**. This matters because there is no `SUBI` instruction: `funct3 =
000` with an immediate operand is *always* `ADDI`, never a subtract. A
*negative* I-type immediate's upper bits can coincidentally equal
`0100000` (the real `SUB` funct7 pattern), which would wrongly select
`SUB` if this weren't gated. `is_itype` (wired to `ALUSrc`, which is
already `1` for exactly the I-type ALU ops) gates that check so it only
applies to R-type. The `SRL`/`SRA` check deliberately does **not** gate
on `is_itype` — for shift instructions specifically, `funct7[5]` really
is meaningful in both the R-type and I-type-shift-immediate encodings.
(Full story of how this bug was found — a synthesis pass, not simulation
— is in `verification.md`.)

---

## ALU (`alu.v`)

| Code | Operation |
|---|---|
| `0000` | `ADD` |
| `0001` | `SUB` |
| `0010` | `AND` |
| `0011` | `OR` |
| `0100` | `XOR` |
| `0101` | `SLL` |
| `0110` | `SRL` |
| `0111` | `SLT` (signed compare) |
| `1000` | `SRA` — `$signed(a) >>> b[4:0]` |
| `1001` | `SLTU` (unsigned compare) |

`SLTU` compares `a < b` directly as unsigned Verilog wires (no `$signed`
cast) — this is what makes e.g. `0xFFFFFFFF` correctly compare as "larger
than" `5`, unlike a signed comparison where it would read as `-1`.

---

## Branch Comparator (`branch_comparator.v`)

Evaluates all six RV32I branch conditions from `funct3`:

```verilog
case(funct3)
    3'b000:  branch_taken = (rs1_data == rs2_data);                   // BEQ
    3'b001:  branch_taken = (rs1_data != rs2_data);                   // BNE
    3'b100:  branch_taken = ($signed(rs1_data) <  $signed(rs2_data)); // BLT
    3'b101:  branch_taken = ($signed(rs1_data) >= $signed(rs2_data)); // BGE
    3'b110:  branch_taken = (rs1_data <  rs2_data);                   // BLTU
    3'b111:  branch_taken = (rs1_data >= rs2_data);                   // BGEU
endcase
```

Note it receives `operand1`/`operand2_base` from `ex_stage.v` — i.e. the
*forwarded* values, not the raw register-file outputs. This matters: a
branch depending on the result of the immediately preceding instruction
needs the forwarding-corrected value to compare correctly, exactly like
the ALU does.

---

## Jump/Branch Target Computation

There are two different target address formulas in this ISA, and
`ex_stage.v` selects between them with the `JALR` control signal:

```verilog
assign branch_target = JALR ? ((operand1 + immediate) & ~32'd1)
                             : (pc + immediate);
```

- **Branches and `JAL`**: target is `pc + immediate` (PC-relative).
- **`JALR`**: target is `(rs1 + immediate)` with the low bit cleared —
  register-relative, not PC-relative. This is the one case in the whole
  ISA where the jump target depends on a register value rather than the
  current instruction's own address.

`pc_plus4` (`pc + 4`) is computed unconditionally alongside this — it's
the link value written back to `rd` for `JAL`/`JALR`, selected in the WB
stage by the `Jump` control signal.

---

## Memory Access (`data_memory.v`, `instruction_memory.v`)

Both are simple word-addressed 256-entry arrays (`instruction_memory` is
read-only; `data_memory` supports byte-addressed word reads/writes gated
by `MemRead`/`MemWrite`). Addressing uses `address[9:2]` (word-aligned),
matching how the PC itself is word-aligned via `pc[31:2]` in
`instruction_memory`.

**Synthesis note**: neither is inferred as a RAM/ROM macro by generic
synthesis (no target cell library knows what block RAM looks like)
— `data_memory` in particular unrolls into 8,192 individual flip-flops
(256 words × 32 bits), which dominates cell count and worst-case timing
in the synthesis reports under `synthesis/`. This doesn't affect
functional correctness — it's a physical-implementation-only concern,
addressed in `synthesis/SYNTHESIS_REPORT_SKY130.md`.