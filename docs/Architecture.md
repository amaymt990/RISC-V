# Architecture

## Overview

This project implements a 32-bit RISC-V processor (RV32I base integer
ISA) in Verilog, in two forms:

- **`cpu.v`** — a single-cycle implementation. Every instruction
  completes in one clock cycle; simplest to reason about, useful as a
  reference/ground-truth for checking the pipeline's behavior.
- **`cpu_pipeline.v`** — a 5-stage pipelined implementation
  (Fetch → Decode → Execute → Memory → Writeback), with data forwarding,
  hazard detection, and branch/jump resolution. This is the primary,
  actively-developed implementation.

Both share the same underlying combinational building blocks (ALU,
control unit, immediate generator, register file, branch comparator) —
the pipeline just adds pipeline registers between stages and the
hazard/forwarding logic needed to keep a multi-instruction-in-flight
design correct.

See `datapath.md` for how data flows through the combinational logic,
`pipeline.md` for how the 5 stages are structured, `hazard_unit.md` for
how RAW/control hazards are resolved, and `verification.md` for how all
of this has been tested.

---

## Instruction Set Coverage

The processor implements the complete RV32I base integer instruction
set, with one intentional scope boundary and one known incomplete case:

| Category | Instructions |
|---|---|
| Register-register ALU | `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA`, `SLT`, `SLTU` |
| Register-immediate ALU | `ADDI`, `ANDI`, `ORI`, `XORI`, `SLLI`, `SRLI`, `SRAI`, `SLTI`, `SLTIU` |
| Memory | `LW`, `SW` |
| Branches | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |
| Jumps | `JAL`, `JALR` |
| Upper immediate | `LUI`, `AUIPC` |
| Misc | `FENCE` (decoded as an architectural NOP — see below) |

**Not implemented**: `ECALL`, `EBREAK`, and CSR instructions (`CSRRW`,
`CSRRS`, etc.). These belong to the Zicsr extension, not RV32I base —
out of scope by design, not an oversight.

**`FENCE` as a NOP**: this is a single-issue, in-order pipeline with no
caching and no out-of-order memory access, so there is no memory
reordering for `FENCE` to actually guard against. It's explicitly decoded
in `control_unit.v` (rather than silently falling through to default
signals) so the intent is visible in the code.

---

## Module Map

```
rtl/
├── cpu.v                    # single-cycle top module
├── cpu_pipeline.v           # 5-stage pipeline top module
│
├── program_counter.v        # PC register, with stall support
├── instruction_memory.v     # 256-word instruction ROM
├── data_memory.v            # 256-word data RAM
├── register_file.v          # 32×32-bit regfile, write-first bypass
│
├── control_unit.v           # opcode -> control signals
├── immediate_generator.v    # instruction -> sign-extended immediate
├── alu.v                    # the ALU itself
├── alu_control.v            # ALUOp/funct3/funct7 -> ALU operation code
├── branch_comparator.v      # funct3-aware branch condition evaluation
│
├── if_id_register.v         # IF/ID pipeline register
├── id_stage.v                # ID stage (regfile read + control_unit)
├── id_ex_register.v         # ID/EX pipeline register
├── ex_stage.v                 # EX stage (ALU + forwarding muxes + branch target)
├── ex_mem_register.v        # EX/MEM pipeline register
├── mem_stage.v                # MEM stage (data_memory access)
├── mem_wb_register.v        # MEM/WB pipeline register
├── wb_stage.v                 # WB stage (writeback data mux)
│
├── forwarding_unit.v        # EX/MEM, MEM/WB -> EX forwarding logic
└── hazard_detection_unit.v  # load-use hazard -> stall logic
```

---

## Control Signal Reference

These are the signals `control_unit.v` produces from a 7-bit opcode, and
that flow through the pipeline (or directly, in the single-cycle CPU) to
drive the rest of the datapath.

| Signal | Width | Meaning |
|---|---|---|
| `RegWrite` | 1 | Write the ALU/memory/link result back to the register file |
| `ALUSrc` | 1 | ALU's second operand is the immediate (1) instead of `rs2` (0) |
| `MemRead` | 1 | Read `data_memory` (load) |
| `MemWrite` | 1 | Write `data_memory` (store) |
| `MemtoReg` | 1 | Writeback value comes from memory, not the ALU |
| `Branch` | 1 | This is a branch instruction (comparator result gates the PC redirect) |
| `Jump` | 1 | Unconditional jump (`JAL`/`JALR`) — always redirects the PC |
| `JALR` | 1 | Jump target is `(rs1 + immediate) & ~1`, not `(pc + immediate)` |
| `ALUOp` | 2 | `00`=force ADD (loads/stores/AUIPC/JAL link/LUI), `01`=branch (legacy), `10`=decode from `funct3`/`funct7` |
| `Op1Sel` | 2 | ALU operand 1 source: `00`=register, `01`=PC (AUIPC), `10`=zero (LUI) |

### Why `Op1Sel` exists

`AUIPC` and `LUI` are U-type instructions. In every *other* instruction
format, `instruction[19:15]` is the `rs1` field. In U-type, those same
bit positions are part of the immediate — there is no real `rs1`. Early
in this project, `LUI` had a real bug because of this: the datapath was
reading `instruction[19:15]` as if it were a register number regardless
of instruction type, so `LUI` would add garbage register contents to the
value it was supposed to just load directly.

`Op1Sel` fixes this generally: it lets the EX stage's first ALU operand
be overridden to `PC` (for `AUIPC`'s `rd = pc + immediate`) or `0` (for
`LUI`'s `rd = 0 + immediate = immediate`), instead of always defaulting
to whatever's in the register file at that (possibly meaningless) address.

---

## Known Limitations

- **No branch prediction** — branches and jumps resolve in EX, so a
  taken branch always costs 2 flushed cycles. See `hazard_unit.md`.
- **`data_memory` isn't RAM-mapped for synthesis** — its 256-word array
  synthesizes as 8,192 individual flip-flops without a target library
  that understands block RAM/SRAM macros. This doesn't affect
  simulation correctness, but it dominates both cell count and the
  worst-case critical path in physical synthesis (see the `synthesis/`
  reports).
- **No exception/interrupt handling** — `ECALL`/`EBREAK`/CSR are out of
  ISA scope for the same reason.
- **Single-issue, in-order** — one instruction per stage per cycle, no
  superscalar or out-of-order execution.