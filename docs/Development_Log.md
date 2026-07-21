# Development Log

## Day 1 – Project Setup
- Created project repository.
- Set up directory structure.
- Installed Icarus Verilog, GTKWave, and Yosys.
- Configured development environment.

---

## Day 2 – ALU
- Designed 32-bit ALU.
- Implemented:
  - ADD
  - SUB
  - AND
  - OR
  - XOR
  - SLL
  - SRL
  - SLT
- Added zero flag.
- Created and verified ALU testbench.

---

## Day 3 – Core Components
- Implemented 32×32 Register File.
- Implemented Program Counter.
- Implemented Instruction Memory.
- Implemented Data Memory.
- Verified each module using dedicated testbenches.

---

## Day 4 – Instruction Decode
- Implemented Immediate Generator.
- Added support for:
  - I-type
  - S-type
  - B-type
  - U-type
  - J-type
- Verified immediate extraction.

---

## Day 5 – Control Logic
- Designed Control Unit.
- Implemented ALU Control.
- Implemented Branch Comparator.
- Verified control signal generation for supported RV32I instructions.

---

## Day 6 – CPU Integration (Instruction Fetch & Decode)
### Completed
- Created top-level `cpu.v`.
- Instantiated Program Counter.
- Connected Instruction Memory.
- Connected Control Unit.
- Connected Immediate Generator.
- Connected Register File.
- Verified successful top-level compilation.

### Current Datapath

PC
↓
Instruction Memory
↓
Instruction
├──► Control Unit
├──► Immediate Generator
└──► Register File

### Next Steps
- Integrate ALU Control.
- Connect ALU.
- Add ALU input multiplexer.
- Complete Execute stage.