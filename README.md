# RV32I RISC-V Processor in Verilog

A 32-bit RV32I RISC-V processor designed and implemented in Verilog HDL. This project started as a single-cycle processor and is being extended into a fully pipelined 5-stage architecture with hazard detection, forwarding, and RTL-to-GDS implementation.

---

## Project Overview

This project is a hands-on implementation of a RISC-V processor following the RV32I instruction set architecture. The goal is to understand processor architecture from the ground up by designing, integrating, verifying, and eventually synthesizing a complete CPU.

The processor is written entirely in Verilog and verified using simulation.

---

## Current Features

### Single-Cycle Processor

- 32-bit datapath
- Harvard Architecture
- Program Counter (PC)
- Instruction Memory
- Register File (32 × 32-bit registers)
- Immediate Generator
- Control Unit
- ALU Control
- Arithmetic Logic Unit (ALU)
- Data Memory
- Branch Comparator

---

## Implemented Instructions

### Arithmetic
- ADD
- SUB
- ADDI

### Memory
- LW
- SW

### Control Flow
- BEQ
- JAL

---

## Verification

All implemented instructions have been verified using dedicated Verilog testbenches.

Verified operations include:

- Register read/write
- Arithmetic execution
- Memory load/store
- Conditional branching
- Jump instructions
- Reset functionality

Example simulation output:

```text
x1 = 10
x2 = 10
x3 = 0
x4 = 99
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
│   ├── cpu.v
│   ├── data_memory.v
│   ├── immediate_generator.v
│   ├── instruction_memory.v
│   ├── program_counter.v
│   └── register_file.v
│
├── testbench/
│   └── cpu_tb.v
│
├── docs/
├── diagrams/
├── synthesis/
├── timing/
├── floorplan/
├── gds/
└── README.md
```

---

## Development Progress

### Completed

- [x] Single-cycle CPU
- [x] Instruction Fetch
- [x] Instruction Decode
- [x] Execute Stage
- [x] Memory Access
- [x] Write Back
- [x] Branch Support
- [x] Jump Support

### Currently Working On

- [ ] 5-stage Pipeline
- [ ] IF/ID Register
- [ ] ID/EX Register
- [ ] EX/MEM Register
- [ ] MEM/WB Register
- [ ] Forwarding Unit
- [ ] Hazard Detection Unit
- [ ] Branch Flush Logic

### Future Work

- RTL Synthesis (Yosys)
- Static Timing Analysis
- Floorplanning
- Placement & Routing
- GDSII Generation using OpenROAD

---

## Tools Used

- Verilog HDL
- Icarus Verilog
- GTKWave
- VS Code
- Git
- GitHub

Planned:

- Yosys
- OpenROAD
- OpenSTA

---

## Learning Objectives

This project focuses on understanding:

- Computer Architecture
- Processor Datapath Design
- Control Logic
- Pipeline Architecture
- Hazard Handling
- RTL Design
- Digital System Verification
- ASIC Design Flow

---

## References

- RISC-V Unprivileged ISA Specification
- Patterson & Hennessy — Computer Organization and Design
- Digital Design and Computer Architecture (Harris & Harris)

---

## Author

**Amay M Thamban**

Electronics and Communication Engineering

GitHub: https://github.com/amaymt990

LinkedIn: https://linkedin.com/in/aymt

---

## License

This project is released under the MIT License.