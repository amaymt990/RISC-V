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


## Day 7 – Single-Cycle CPU Verification

### Completed
- Integrated ALU Control
- Connected ALU
- Added ALU input multiplexer
- Connected Data Memory
- Added Write-Back multiplexer
- Added sequential PC update
- Developed CPU testbench

### Verification Program

```assembly
addi x1, x0, 5
addi x2, x0, 10
add  x3, x1, x2
```

### Simulation Results

```
x1 = 5
x2 = 10
x3 = 15
```

---

## Day 8 – Pipeline Wiring: Forwarding, Hazard Detection, Branch Flush

### Context

Stages `id_stage`, `ex_stage`, `mem_stage`, `wb_stage`, and all four pipeline
registers had been written individually, but `cpu_pipeline.v` only
instantiated the PC, instruction memory, and the IF/ID register — the rest
of the pipeline wasn't connected yet. Today's work: wire the full datapath
and make it actually correct under hazards, not just "compiles."

### Problems solved (and why each one exists)

**1. WB-writes / ID-reads on the same clock edge.**
In a 5-stage pipeline, the write-back stage writes to the register file in
the same cycle that instruction decode reads from it. A register file that
only updates its internal array on the clock edge would give ID a stale
value. Fixed by adding a write-first bypass directly in `register_file.v`:
if the register being read is also being written this cycle, forward the
write data instead of the array contents.

**2. Back-to-back and 2-apart RAW hazards.**
Added `forwarding_unit.v`. It compares the source registers of the
instruction in EX (`id_ex_rs1/rs2`) against the destination registers
sitting in EX/MEM and MEM/WB, and forwards whichever is more recent
directly into the ALU's operands — instead of waiting for the result to be
written back to the register file. This also feeds the branch comparator,
so a branch depending on the immediately preceding instruction's result
still compares the correct values.

**3. Load-use hazard.**
Forwarding can't save a load followed immediately by a dependent
instruction — the loaded value isn't ready until MEM, one cycle too late.
Added `hazard_detection_unit.v`: if the instruction in EX is a load and its
destination register matches a source register of the instruction in ID,
stall the PC and IF/ID for one cycle and insert a bubble into ID/EX.

**4. Control hazards (branches / jumps).**
`branch_comparator` resolves in EX, so by the time a taken branch is known,
two wrong-path instructions have already been fetched. `cpu_pipeline.v` now
flushes IF/ID and ID/EX and redirects the PC to the computed branch target
in the same cycle the branch resolves.

**5. JAL's link value didn't survive the pipeline.**
`pc+4` needed to reach the WB stage for JAL's `rd = pc+4` write-back, but
none of the pipeline registers carried it. Threaded `pc_plus4` through
`ex_stage` → `ex_mem_register` → `mem_wb_register` → `wb_stage`.

### Toolchain note

Hit a real (and instructive) bug: `cpu_pipeline.v` used a few signals in an
`assign` before their `wire` declaration appeared later in the file. The
Icarus Verilog build installed via package manager quietly patches over
this with an implicit 1-bit wire and a warning. Building `iverilog` from
source (the newer dev branch) is stricter — it creates the implicit wire,
then fails to bind it to the "real" declaration further down, producing
hard elaboration errors instead of warnings. Fixed by declaring every
signal at the top of the module before any usage. Good reminder that
"compiles cleanly on my machine" depends on which toolchain build you're
running.

### Test Program

```assembly
addi x1, x0, 5        # x1 = 5
add  x2, x1, x1        # x2 = 10   -- back-to-back RAW, needs EX/MEM forward
addi x3, x2, 0         # x3 = 10   -- 2-apart RAW, needs MEM/WB forward
sw   x2, 0(x1)         # mem[5] = 10
lw   x4, 0(x1)         # x4 = 10
addi x5, x4, 0         # x5 = 10   -- load-use hazard, must stall 1 cycle
beq  x1, x1, +8        # always taken, skips next instruction
addi x6, x0, 85        # must be skipped
addi x7, x0, 99        # branch target
```

### Simulation Results

```text
x1 = 5  (expect 5)
x2 = 10 (expect 10)
x3 = 10 (expect 10)
x4 = 10 (expect 10)
x5 = 10 (expect 10)
x6 = 0  (expect 0, must be skipped by branch)
x7 = 99 (expect 99)
```

Verified `hazard_stall` pulses high for exactly one cycle around the
load-use hazard, and `pipeline_flush` pulses high for exactly one cycle
when the branch resolves, with the fetched-but-squashed instruction
showing up as `00000000` (bubble) in the following cycle — confirmed via
waveform inspection, not just the register values.

### Next Steps
- Widen `branch_comparator` to take `funct3` and support BNE/BLT/BGE/BLTU/BGEU
- Fix LUI's register-read path (U-type has no `rs1`)
- Add CPU-level tests for the ALU ops beyond ADD/SUB/ADDI
- Start the Yosys synthesis flow on the single-cycle core


V1-------x------- CLOSED