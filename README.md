<!--
  IMAGE CHECKLIST -- see docs/images/ for the architecture/datapath/pipeline
  diagrams already exported. If any are missing, re-export from the chat
  history or regenerate from the Visualizer diagrams built during development.
-->

<div align="center">

# RV32I RISC-V Processor in Verilog

**A 5-stage pipelined RISC-V CPU, built from scratch in Verilog — with full RV32I coverage, real forwarding/hazard/branch resolution, and verified against a real sky130 standard-cell library.**

[![Verilog](https://img.shields.io/badge/HDL-Verilog-blue)](https://en.wikipedia.org/wiki/Verilog)
[![ISA](https://img.shields.io/badge/ISA-RV32I-informational)](https://riscv.org/technical/specifications/)
[![Simulator](https://img.shields.io/badge/Simulator-Icarus%20Verilog-brightgreen)](http://iverilog.icarus.com/)
[![Synthesis](https://img.shields.io/badge/Synthesis-Yosys%20%2B%20sky130-orange)](synthesis/sky130/SYNTHESIS_REPORT_SKY130.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## Overview

A from-scratch 32-bit RISC-V (RV32I) processor: a working single-cycle
CPU first, then a full 5-stage pipeline with data forwarding, hazard
detection, and branch/jump resolution layered on top. Every module has
its own testbench, the pipeline is verified against programs specifically
built to exercise real hazards, and the design has been carried through
actual synthesis — against both a generic cell library and the real,
open-source sky130 process — with genuine static timing analysis, not
estimates.

Two real RTL bugs were found and fixed during this process — both
invisible to simulation, both only caught by actually running a
synthesis tool. See `docs/verification.md` for the full story.

---

## Documentation

Full documentation lives in `docs/`:

| Doc | Covers |
|---|---|
| [`architecture.md`](docs/architecture.md) | High-level overview, ISA coverage, module map, control signal reference |
| [`datapath.md`](docs/datapath.md) | The combinational logic: ALU, register file, immediate generator, branch comparator |
| [`pipeline.md`](docs/pipeline.md) | The 5 pipeline stages and pipeline registers, stage by stage |
| [`hazard_unit.md`](docs/hazard_unit.md) | Forwarding, load-use stalling, and branch/jump flush logic |
| [`control_unit.md`](docs/control_unit.md) | Full opcode → control signal decode table |
| [`verification.md`](docs/verification.md) | Testing methodology, and the two bugs synthesis caught that simulation didn't |

Day-by-day build history: [`docs/V1_Development_Log.md`](docs/V1_Development_Log.md), [`V1.1`](docs/Development_Log_V1.1.md), [`V1.2`](docs/V1.2_Development_Log.md), [`V1.3`](docs/V1.3_Development_Log.md).

---

## Architecture

![Pipeline architecture](docs/images/pipeline_architecture.png)

Branches and jumps resolve in EX (costing 2 flushed cycles per taken
branch — no branch prediction yet), EX/MEM and MEM/WB results forward
directly into EX, and the front end stalls for exactly one cycle on a
load-use hazard. Full detail in [`docs/hazard_unit.md`](docs/hazard_unit.md).

---

## Instruction Set Coverage

**Complete RV32I base integer ISA**, verified end-to-end:

| Category | Instructions |
|---|---|
| Register-register ALU | `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA`, `SLT`, `SLTU` |
| Register-immediate ALU | `ADDI`, `ANDI`, `ORI`, `XORI`, `SLLI`, `SRLI`, `SRAI`, `SLTI`, `SLTIU` |
| Memory | `LW`, `SW` |
| Branches | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |
| Jumps | `JAL`, `JALR` |
| Upper immediate | `LUI`, `AUIPC` |
| Misc | `FENCE` (architectural NOP — single-issue in-order pipeline has no reordering to fence against) |

**Out of scope by design**: `ECALL`/`EBREAK`/CSR instructions belong to
the Zicsr extension, not RV32I base.

**One known test coverage gap**: `AND`/`OR`/`XOR`/`SLL`/`SRL`/`SLT` are
verified at the ALU/ALU-control unit-test level but don't yet have a
dedicated CPU-level (full fetch→writeback) test the way most other
instructions do. Tracked in [`docs/verification.md`](docs/verification.md).

---

## Synthesis & Timing

Two synthesis passes, both real (not estimated):

**Generic technology mapping** (no target library) —
[`synthesis/SYNTHESIS_REPORT.md`](synthesis/SYNTHESIS_REPORT.md):
core CPU logic (excluding the data memory array) comes to **8,621 cells
/ 1,497 flip-flops**.

**Real sky130 standard-cell synthesis + STA** —
[`synthesis/sky130/SYNTHESIS_REPORT_SKY130.md`](synthesis/sky130/SYNTHESIS_REPORT_SKY130.md):
21,215 real sky130 cell instances, with genuine timing analysis via
OpenROAD's embedded STA engine. Two honest numbers, not one cherry-picked
one:
- **283.3 ns worst-case (~3.5 MHz)** — bottlenecked by `data_memory`'s
  256-word array, which isn't mapped to a real RAM macro without a
  memory compiler, and unrolls into 8,192 individual flip-flops instead
- **4.77 ns core logic path (~210 MHz)** — the register-file writeback
  path, excluding the memory-array artifact above; the more honest
  estimate of what this pipeline's actual logic can run at

Currently exploring the full OpenLane/sky130 physical design flow
(floorplanning, placement, routing) for post-placement/post-route timing
instead of the wire-load-estimated numbers above.

---

## Verification

Every module has its own testbench (ALU, register file, PC, immediate
generator, control unit, ALU control, branch comparator, instruction/data
memory), plus integration-level testbenches for the single-cycle CPU and
several targeted pipeline test programs (core hazard test, full branch
coverage, `JALR`/`SLTU` test). Full methodology, including the two
synthesis-only bugs found and fixed, in
[`docs/verification.md`](docs/verification.md).

Example — the core pipeline hazard test, exercising a back-to-back RAW
hazard, a 2-apart RAW hazard, a load-use stall, and a taken branch in one
program:

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

## Getting Started

Requires [Icarus Verilog](http://iverilog.icarus.com/).

```bash
git clone https://github.com/amaymt990/RISC-V.git
cd RISC-V

# compile and run the pipelined CPU testbench
iverilog -g2012 -o build/cpu_pipeline.out -s cpu_pipeline_tb rtl/*.v testbench/cpu_pipeline_tb.v
vvp build/cpu_pipeline.out

# compile and run the single-cycle CPU testbench
iverilog -g2012 -o build/cpu.out -s cpu_tb rtl/*.v testbench/cpu_tb.v
vvp build/cpu.out

# inspect waveforms
gtkwave pipeline.vcd
```

For synthesis, see [`synthesis/SYNTHESIS_REPORT.md`](synthesis/SYNTHESIS_REPORT.md)
(generic) and [`synthesis/sky130/SYNTHESIS_REPORT_SKY130.md`](synthesis/sky130/SYNTHESIS_REPORT_SKY130.md)
(real sky130 + STA) for exact reproduction steps.

---

## Project Structure

```
RISC-V/
├── rtl/                          # all synthesizable Verilog
├── testbench/                    # per-module + integration testbenches
├── docs/                         # architecture, datapath, pipeline, hazard,
│                                  # control unit, verification docs + dev logs
├── synthesis/
│   ├── SYNTHESIS_REPORT.md       # generic synthesis results
│   ├── cpu_pipeline_synth_top.v  # synthesis-only debug-port wrapper
│   └── sky130/                   # real sky130 synthesis + STA
├── OpenLane/                     # (local only, not committed -- see below)
└── README.md
```

> **Note**: `OpenLane/` and any PDK archives (`*.tar.zst`) are gitignored
> and kept local-only — they're external toolchains/downloads, not part
> of this repo's source.

---

## Roadmap

**Completed**
- [x] Single-cycle CPU
- [x] 5-stage pipeline: forwarding, hazard detection, branch/jump flush
- [x] Complete RV32I base ISA
- [x] Full documentation suite
- [x] Generic synthesis (Yosys)
- [x] Real sky130 synthesis + STA (OpenROAD)

**In progress**
- [ ] Full OpenLane physical flow: floorplanning, placement, routing
- [ ] CPU-level tests for `AND`/`OR`/`XOR`/`SLL`/`SRL`/`SLT`
- [ ] `data_memory` RAM-macro mapping (would resolve the timing gap above)

**Planned**
- [ ] FPGA implementation & validation
- [ ] Branch prediction
- [ ] Cache integration (I-cache/D-cache)
- [ ] AXI4-Lite interface + UART peripheral (minimal SoC)

---

## Tools Used

Verilog HDL · Icarus Verilog · GTKWave · Yosys · OpenROAD · sky130 PDK · Git

---

## References

- [RISC-V Unprivileged ISA Specification](https://riscv.org/technical/specifications/)
- Patterson & Hennessy — *Computer Organization and Design*
- Harris & Harris — *Digital Design and Computer Architecture*

---

## Author

**Amay M Thamban** — Electronics and Communication Engineering

[GitHub](https://github.com/amaymt990) · [LinkedIn](https://linkedin.com/in/aymt)

---

## License

Released under the [MIT License](LICENSE).
