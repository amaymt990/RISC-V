<!--
  IMAGE CHECKLIST — replace the placeholders below before publishing.
  Save all images into docs/images/ using these exact filenames, or update
  the paths if you name them differently.

  1. docs/images/pipeline_architecture.png
     Screenshot of the pipeline diagram Claude generated in chat (the
     IF/ID/EX/MEM/WB + forwarding + hazard/flush diagram). Right-click it
     in the conversation -> Save Image, or use the download button on the
     widget.

  2. docs/images/waveform_hazard.png
     GTKWave / VS Code waveform viewer, zoomed to ~70-120ns, showing
     hazard_stall and pipeline_flush pulsing high. This is your proof
     shot -- it's the single most convincing image in the repo.

  3. docs/images/simulation_output.png
     Terminal screenshot of the pipeline testbench passing (the x1..x7
     register comparison output). Quick to capture, very legible on
     GitHub's dark mode.

  4. docs/images/banner.png  (optional)
     A simple repo banner/hero image. Not required -- remove that section
     if you'd rather keep the README text-first.
-->

<div align="center">

# RV32I RISC-V Processor in Verilog

**A 5-stage pipelined RISC-V CPU, built from scratch in Verilog — with real forwarding, hazard detection, and branch resolution, verified in simulation.**

[![Verilog](https://img.shields.io/badge/HDL-Verilog-blue)](https://en.wikipedia.org/wiki/Verilog)
[![ISA](https://img.shields.io/badge/ISA-RV32I-informational)](https://riscv.org/technical/specifications/)
[![Simulator](https://img.shields.io/badge/Simulator-Icarus%20Verilog-brightgreen)](http://iverilog.icarus.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

<!-- Optional hero image -- delete this block if you skip it -->
<!-- <img src="docs/images/banner.png" alt="RV32I pipeline banner" width="800"/> -->

</div>

---

## Overview

This is a from-scratch implementation of a 32-bit RISC-V (RV32I) processor,
built up in stages: a working single-cycle CPU first, then a full 5-stage
pipeline with forwarding, hazard detection, and branch resolution layered
on top. Every module — ALU, register file, control unit, pipeline
registers, hazard logic — has its own testbench, and the pipeline as a
whole is verified against a program specifically designed to exercise
back-to-back and load-use data hazards, plus a taken branch.

Built to understand processor architecture from first principles: not
just "does it produce the right output" but "does it produce the right
output *under pipelining hazards*", which is where most from-scratch CPU
projects quietly fall apart.

---

## Architecture

![Pipeline architecture](docs/images/pipeline_architecture.png)

The pipeline resolves branches in EX (costing 2 flushed cycles per taken
branch — no branch prediction yet), forwards EX/MEM and MEM/WB results
directly into the EX stage's ALU inputs, and stalls the front end for
exactly one cycle on a load-use hazard.

---

## Features

**Single-cycle processor**
- 32-bit Harvard-architecture datapath
- Program counter, instruction memory, data memory, 32×32-bit register file
- Immediate generator supporting I/S/B/U/J formats
- Control unit, ALU control, ALU, branch comparator

**5-stage pipelined processor**
- Full IF → ID → EX → MEM → WB datapath with IF/ID, ID/EX, EX/MEM, and MEM/WB pipeline registers
- **Forwarding unit** — resolves RAW hazards 1 and 2 instructions apart by forwarding EX/MEM and MEM/WB results directly into EX, without waiting for a register-file write
- **Hazard detection unit** — stalls the PC and IF/ID for exactly one cycle on a load-use hazard (a load immediately followed by a dependent instruction)
- **Register file write-first bypass** — handles the same-cycle write-in-WB / read-in-ID case forwarding alone can't cover
- **Branch/jump resolution in EX** — a taken branch or JAL flushes the two instructions already fetched down the wrong path and redirects the PC

---

## Implemented Instructions

The ALU supports **ADD, SUB, AND, OR, XOR, SLL, SRL, SLT**, and the control
unit decodes both R-type and I-type encodings through it generically. The
instructions below, however, are the ones **verified end-to-end** with a
dedicated CPU-level testbench:

| Category | Instructions |
|---|---|
| Arithmetic | `ADD`, `SUB`, `ADDI` |
| Memory | `LW`, `SW` |
| Control flow | `BEQ`, `JAL` |

### Known limitations

- **`LUI`** is decoded by the control unit, but U-type instructions have no
  `rs1` field — the register file read still uses `instruction[19:15]`
  unconditionally, so `LUI` currently adds garbage register contents to
  the immediate instead of loading it directly. Needs a dedicated U-type
  path.
- **`branch_comparator` only implements equality.** The control unit sets
  `Branch = 1` for any branch opcode (`BEQ`/`BNE`/`BLT`/`BGE`/`BLTU`/`BGEU`
  all share one opcode), but the comparator doesn't yet look at `funct3` —
  so only `BEQ` branches correctly today.
- `AND`/`OR`/`XOR`/`SLL`/`SRL`/`SLT` and their immediate forms are wired
  through the ALU and control path but have no dedicated CPU-level test
  yet — should work, not yet verified.

---

## Verification

Every module has its own testbench (ALU, register file, PC, immediate
generator, control unit, ALU control, branch comparator, instruction/data
memory), plus integration-level testbenches for both the single-cycle and
pipelined CPUs.

The pipeline testbench runs this program, deliberately built to hit three
hazard types and a control hazard in one pass:

```assembly
addi x1, x0, 5         # x1 = 5
add  x2, x1, x1        # x2 = 10   -- back-to-back RAW, needs EX/MEM forward
addi x3, x2, 0         # x3 = 10   -- 2-apart RAW, needs MEM/WB forward
sw   x2, 0(x1)         # mem[5] = 10
lw   x4, 0(x1)         # x4 = 10
addi x5, x4, 0         # x5 = 10   -- load-use hazard, must stall 1 cycle
beq  x1, x1, +8        # always taken, skips next instruction
addi x6, x0, 85        # must be skipped
addi x7, x0, 99        # branch target
```

**Result — every register lands on the expected value:**

![Simulation output](docs/images/simulation_output.png)

```text
x1 = 5  (expect 5)
x2 = 10 (expect 10)
x3 = 10 (expect 10)
x4 = 10 (expect 10)
x5 = 10 (expect 10)
x6 = 0  (expect 0, must be skipped by branch)
x7 = 99 (expect 99)
```

**Waveform — the stall and flush caught in the act:**

![Hazard and flush waveform](docs/images/waveform_hazard.png)

`hazard_stall` pulses high for one cycle around the load-use hazard;
`pipeline_flush` pulses high for one cycle when the branch resolves, with
the squashed instruction showing up as `00000000` (a bubble) the cycle
after.

---

## Getting Started

Requires [Icarus Verilog](http://iverilog.icarus.com/).

```bash
# clone the repo
git clone https://github.com/<your-username>/RISC-V.git
cd RISC-V

# compile and run the pipelined CPU testbench
iverilog -g2012 -o cpu_pipeline.out -s cpu_pipeline_tb rtl/*.v testbench/cpu_pipeline_tb.v
vvp cpu_pipeline.out

# compile and run the single-cycle CPU testbench
iverilog -g2012 -o cpu.out -s cpu_tb rtl/*.v testbench/cpu_tb.v
vvp cpu.out

# inspect waveforms (opens pipeline.vcd / cpu.vcd)
gtkwave pipeline.vcd
```

---

## Project Structure

```
RISC-V/
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
├── testbench/
│   ├── cpu_tb.v
│   ├── cpu_pipeline_tb.v
│   └── ...                      # per-module testbenches
├── docs/
│   ├── Development_Log.md
│   └── images/
├── synthesis/                    # not started
├── timing/                       # not started
├── floorplan/                    # not started
├── gds/                          # not started
└── README.md
```

---

## Roadmap

**Completed**
- [x] Single-cycle CPU (ADD, SUB, ADDI, LW, SW, BEQ, JAL)
- [x] 5-stage pipeline with IF/ID, ID/EX, EX/MEM, MEM/WB registers
- [x] Forwarding unit (EX/MEM and MEM/WB → EX)
- [x] Hazard detection unit (load-use stall)
- [x] Register file write-first bypass
- [x] Branch/jump resolution in EX with pipeline flush
- [x] Pipeline hazard testbench, verified end-to-end

**In progress**
- [ ] Widen `branch_comparator` to support `BNE`/`BLT`/`BGE`/`BLTU`/`BGEU`
- [ ] Fix `LUI`'s U-type register-read path
- [ ] Add CPU-level tests for `AND`/`OR`/`XOR`/`SLL`/`SRL`/`SLT` and their immediate forms
- [ ] Add `JALR`

**Planned**
- [ ] RTL synthesis (Yosys)
- [ ] Static timing analysis (OpenSTA)
- [ ] Floorplanning, placement & routing
- [ ] GDSII generation (OpenROAD)

See [`docs/Development_Log.md`](docs/Development_Log.md) for the full
day-by-day build log, including how each hazard type was diagnosed and
fixed.

---

## Tools Used

Verilog HDL · Icarus Verilog · GTKWave · Git

Planned: Yosys · OpenROAD · OpenSTA

---

## References

- [RISC-V Unprivileged ISA Specification](https://riscv.org/technical/specifications/)
- Patterson & Hennessy — *Computer Organization and Design*
- Harris & Harris — *Digital Design and Computer Architecture*

---

## Author

**Amay M Thamban**
Electronics and Communication Engineering

[GitHub](https://github.com/amaymt990) · [LinkedIn](https://linkedin.com/in/aymt)

---

## License

Released under the [MIT License](LICENSE).
