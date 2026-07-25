# RV32I 5-Stage Pipelined RISC-V Processor

<p align="center">
  <b>A 32-bit pipelined RISC-V processor implemented in Verilog HDL featuring hazard detection, forwarding, branch handling, and a modular RTL architecture.</b>
</p>

<p align="center">

![Verilog](https://img.shields.io/badge/Language-Verilog-blue)
![Architecture](https://img.shields.io/badge/Architecture-RV32I-success)
![Pipeline](https://img.shields.io/badge/Pipeline-5--Stage-orange)
![Simulator](https://img.shields.io/badge/Simulator-Icarus_Verilog-red)
![Waveform](https://img.shields.io/badge/Waveform-GTKWave-purple)
![License](https://img.shields.io/badge/License-MIT-green)

</p>

---

# Architecture

<p align="center">
  <img src="images/cpu arch.png" width="1000">
</p>

<p align="center">
<b>Figure 1.</b> CPU ARCHITECTURE
</p>

The processor follows the classical **five-stage RISC-V pipeline**, separating execution into independent stages to improve throughput while maintaining correctness through hazard detection and forwarding.

Pipeline Stages:

- Instruction Fetch (IF)
- Instruction Decode (ID)
- Execute (EX)
- Memory Access (MEM)
- Write Back (WB)

---

# Features

- 32-bit RV32I Processor
- Five-stage pipelined architecture
- Modular RTL implementation
- Hazard Detection Unit
- Data Forwarding Unit
- Branch & Jump Handling
- Pipeline Flush Logic
- Immediate Generator
- Register File
- Separate Instruction & Data Memory
- ALU Control Unit
- Verified using Icarus Verilog
- Waveform analysis using GTKWave

---

# Pipeline Overview

<p align="center">
  <img src="images/5_pipeline.png" width="1000">
</p>

<p align="center">
<b>Figure 1.</b> 5 STAGE PIPELINE
</p>

| Stage | Description |
|--------|-------------|
| IF | Fetch instruction from Instruction Memory |
| ID | Decode instruction, register read, immediate generation |
| EX | ALU execution, branch evaluation, forwarding |
| MEM | Data memory read/write |
| WB | Register write back |

---

# Processor Datapath

<p align="center">
  <img src="images/datapath.png" width="1000">
</p>

<p align="center">
<b>Figure 1.</b> Complete RV32I Processor Datapath
</p>
```

The datapath consists of:

- Program Counter
- Instruction Memory
- Register File
- Immediate Generator
- ALU
- Data Memory
- Pipeline Registers
- Control Unit
- Hazard Detection Unit
- Forwarding Unit
- Branch Handling
- RTL Simulation using Icarus Verilog
- Waveform Analysis using GTKWave
- Logic Synthesis using Yosys
- Open-source ASIC flow (OpenLane/Sky130) *(planned)*

## Current Progress

- [x] Arithmetic Logic Unit (ALU)
- [x] Register File
- [x] Program Counter
- [ ] Instruction Memory
- [ ] Data Memory
- [ ] Immediate Generator
- [ ] Control Unit
- [ ] ALU Control
- [ ] Branch Comparator
- [ ] Single-Cycle CPU
- [ ] Pipeline Registers
- [ ] Forwarding Unit
- [ ] Hazard Detection Unit
- [ ] 5-Stage Pipeline
- [ ] Verification
- [ ] Synthesis
- [ ] Physical Design

## Tools

- Verilog HDL
- Icarus Verilog
- GTKWave
- VS Code
- Git

## Status

🚧 Under Development
