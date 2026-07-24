# RV32I RISC-V Processor in Verilog

A 32-bit RV32I RISC-V processor implemented in Verilog HDL, built up from a
single-cycle design into a fully pipelined 5-stage architecture with
forwarding, hazard detection, and branch resolution.

---

## Project Overview

This project is a hands-on implementation of a RISC-V processor, built to
understand processor architecture from the ground up: datapath design,
control logic, pipelining, hazard handling, and (eventually) the RTL-to-GDS
physical design flow.

Written entirely in Verilog, verified using Icarus Verilog simulation and
waveform inspection in GTKWave / VS Code.

---

## Current Features

### Single-Cycle Processor
- 32-bit datapath, Harvard architecture
- Program Counter, Instruction Memory, Data Memory
- 32×32-bit Register File
- Immediate Generator (I/S/B/U/J formats)
- Control Unit, ALU Control, ALU
- Branch Comparator

### 5-Stage Pipelined Processor
- Full IF → ID → EX → MEM → WB datapath
- Pipeline registers: IF/ID, ID/EX, EX/MEM, MEM/WB
- **Forwarding unit** — resolves back-to-back and 2-cycle-apart RAW hazards
  by forwarding EX/MEM and MEM/WB results directly into the EX stage
- **Hazard detection unit** — stalls PC and IF/ID for one cycle on a
  load-use hazard (a load immediately followed by a dependent instruction)
- **Register file write-first bypass** — handles the same-cycle
  write-in-WB / read-in-ID case that forwarding alone can't cover
- **Branch/jump resolution in EX** — a taken branch or JAL flushes the two
  instructions fetched down the wrong path and redirects the PC

---

## Implemented Instructions

The ALU itself supports **ADD, SUB, AND, OR, XOR, SLL, SRL, SLT**, and the
control unit generically decodes both R-type and I-type encodings through
it — so e.g. `AND`/`ANDI`, `OR`/`ORI`, `SLL`/`SLLI` etc. should work through
the datapath. However, only the instructions below have been **verified
end-to-end** with a dedicated testbench:

### Arithmetic
- ADD, SUB (R-type)
- ADDI (I-type)

### Memory
- LW, SW

### Control Flow
- BEQ
- JAL

### Known limitations (not yet correct / not yet tested)
- **LUI** is decoded by the control unit, but U-type instructions have no
  `rs1` field — the current register file read still uses
  `instruction[19:15]` unconditionally, so LUI will add garbage register
  contents to the immediate instead of loading it directly. This needs a
  dedicated U-type path before it can be trusted.
- **`branch_comparator` only implements equality.** The control unit sets
  `Branch = 1` for *any* branch opcode (BEQ, BNE, BLT, BGE, BLTU, BGEU all
  share the same opcode), but the comparator itself doesn't look at
  `funct3` — so only BEQ actually branches correctly today. Using BNE/BLT/
  etc. in a program will silently produce the wrong branch decision.
- AND/OR/XOR/SLL/SRL/SLT and their immediate forms are implemented at the
  ALU level and should be wired correctly through the control path, but
  have no dedicated CPU-level testbench yet — treat as "should work,
  unverified" rather than "verified."

---

## Verification

Every module (ALU, register file, PC, immediate generator, control unit,
ALU control, branch comparator, instruction/data memory) has its own
testbench. The single-cycle CPU and the pipelined CPU each have their own
integration-level testbench.

The pipeline testbench in particular exercises three hazard types in one
program: a back-to-back RAW hazard, a two-instructions-apart RAW hazard, a
load-use hazard, and a taken branch — and checks every affected register
against its expected value.

Example pipeline simulation output:

```text
x1 = 5  (expect 5)
x2 = 10 (expect 10)
x3 = 10 (expect 10)
x4 = 10 (expect 10)
x5 = 10 (expect 10)
x6 = 0  (expect 0, must be skipped by branch)
x7 = 99 (expect 99)
```

---

## Project Structure

```
RISC-V/
│
├── rtl/
│   ├── alu.v
│   ├── alu_control.v
│   ├── branch_comparator.v
│   ├── control_unit.v
│   ├── cpu.v                    # single-cycle top module
│   ├── cpu_pipeline.v           # 5-stage pipeline top module
│   ├── data_memory.v
│   ├── ex_mem_register.v
│   ├── ex_stage.v
│   ├── forwarding_unit.v
│   ├── hazard_detection_unit.v
│   ├── id_ex_register.v
│   ├── id_stage.v
│   ├── if_id_register.v
│   ├── immediate_generator.v
│   ├── instruction_memory.v
│   ├── mem_stage.v
│   ├── mem_wb_register.v
│   ├── program_counter.v
│   ├── register_file.v
│   └── wb_stage.v
│
├── testbench/
│   ├── cpu_tb.v
│   ├── cpu_pipeline_tb.v
│   └── ... (per-module testbenches)
│
├── docs/
├── diagrams/
├── synthesis/     # empty — not started
├── timing/        # empty — not started
├── floorplan/     # empty — not started
├── gds/           # empty — not started
└── README.md
```

---

## Development Progress

### Completed
- [x] Single-cycle CPU (ADD, SUB, ADDI, LW, SW, BEQ, JAL)
- [x] 5-stage pipeline: IF/ID, ID/EX, EX/MEM, MEM/WB registers
- [x] Forwarding unit (EX/MEM and MEM/WB → EX)
- [x] Hazard detection unit (load-use stall)
- [x] Register file write-first bypass (WB/ID same-cycle hazard)
- [x] Branch/jump resolution in EX with pipeline flush
- [x] Pipeline hazard testbench (forwarding + stall + flush all verified)

### Currently Working On
- [ ] Widen branch comparator to support BNE/BLT/BGE/BLTU/BGEU (`funct3`-aware)
- [ ] Fix LUI's U-type register-read path
- [ ] Add CPU-level tests for AND/OR/XOR/SLL/SRL/SLT and their immediate forms
- [ ] Add JALR

### Future Work
- RTL Synthesis (Yosys)
- Static Timing Analysis (OpenSTA)
- Floorplanning
- Placement & Routing
- GDSII Generation (OpenROAD)

---

## Tools Used

- Verilog HDL, Icarus Verilog, GTKWave, VS Code, Git, GitHub

Planned: Yosys, OpenROAD, OpenSTA

---

## Learning Objectives

- Computer Architecture & Processor Datapath Design
- Control Logic
- Pipeline Architecture & Hazard Handling
- RTL Design & Digital System Verification
- ASIC Design Flow

---

## References

- RISC-V Unprivileged ISA Specification
- Patterson & Hennessy — *Computer Organization and Design*
- Harris & Harris — *Digital Design and Computer Architecture*

---

## Author

**Amay M Thamban**


GitHub: https://github.com/amaymt990
LinkedIn: https://linkedin.com/in/aymt

---

## License

This project is released under the MIT License.