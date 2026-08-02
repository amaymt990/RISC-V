# Verification

This document covers how the design has been tested: the testbench
structure, what each level of testing checks, the toolchain used, and —
notably — two real bugs that simulation never caught, found only once the
design went through actual synthesis.

---

## Testing Levels

### 1. Per-Module Unit Tests

Every combinational/small sequential module has its own testbench in
`testbench/`: `alu_tb.v`, `alu_control_tb.v`, `branch_comparator_tb.v`,
`control_unit_tb.v`, `immediate_generator_tb.v`, `instruction_memory_tb.v`,
`program_counter_tb.v`, `register_file_tb.v`, `data_memory_tb.v`.

These test each module's logic in isolation, independent of the rest of
the datapath — e.g. `branch_comparator_tb.v` directly drives `rs1_data`/
`rs2_data`/`funct3` combinations and checks `branch_taken` against hand-
computed expected values for all six branch types, including signed vs.
unsigned edge cases (`BLTU`/`BGEU` with a negative-as-unsigned operand).

### 2. Single-Cycle CPU Integration Test

`cpu_tb.v` runs a small instruction sequence through the complete
single-cycle datapath (`cpu.v`) and checks final register values. This
also serves as a **ground-truth reference** — since the single-cycle CPU
has no pipelining hazards to get wrong, its output for a given program is
the "correct answer" the pipelined CPU's output can be checked against.

### 3. Pipeline Integration Tests

Several testbenches target `cpu_pipeline.v` directly, each built around a
specific instruction sequence designed to exercise particular hazards or
instruction categories:

- **`cpu_pipeline_tb.v`** — the core hazard test: back-to-back RAW,
  2-apart RAW, load-use stall, and a taken branch, in one program (see
  the full listing in `hazard_unit.md`)
- **`cpu_pipeline_v11_tb.v`** — 25 instructions covering all six branch
  types (`BNE`/`BLT`/`BGE`/`BLTU`/`BGEU`, each with both a taken and a
  skip case), `SRA`/`SRAI`/`SRLI`, `AUIPC`, `LUI` (see the regression
  case below), and `FENCE`
- **`cpu_pipeline_jalr_tb.v`** — `JALR`, `SLTU`, `SLTIU`, including a
  sentinel instruction planted at the exact computed jump target address
  to confirm the CPU actually *lands* there, not just that it doesn't
  crash

Each of these checks final register values against hand-computed expected
results — including, in the JALR case, deliberately encoding the jump
offset so the target address is independently verifiable by inspection.

---

## Two Bugs That Only Synthesis Found

Both of the following simulated *correctly* — every testbench passed —
and were only caught when the design was run through Yosys. This is
worth documenting explicitly, since it's a real illustration of why
"the testbench passes" isn't the same as "the RTL is synthesizable."

### Bug 1: `if (reset || flush)` breaks async/sync reset inference

`id_ex_register.v` originally combined its asynchronous reset and
synchronous flush conditions into a single `if (reset || flush)` inside
an `always @(posedge clk or posedge reset)` block. This simulates
identically to writing them as two separate branches — a simulator
doesn't care how the condition is structured, only what value it
evaluates to. But Yosys's `proc_dff`/`proc_arst` passes need to separate
"this responds to the async edge on `reset`" from "this is a synchronous
condition that happens to be checked first," and the `||`-combined form
confused that separation:

```
ERROR: Multiple edge sensitive events found for this signal!
```

**Fix**: restructured as `if(reset) ... else if(flush) ...` — functionally
identical, synthesizes cleanly.

### Bug 2: an ADDI with a negative immediate could synthesize as a subtract

`alu_control.v`'s first rewrite used `funct7[5]` as a single bit to
distinguish `ADD`/`SUB` and `SRL`/`SRA`. Correct for R-type. Also correct
for I-type *shift*-immediates (`SLLI`/`SRLI`/`SRAI` genuinely encode this
bit meaningfully in their immediate field, by RISC-V's design). **Wrong**
for plain `ADDI`: there is no `SUBI` instruction, so `funct3 = 000` with
an immediate operand is always `ADDI` — but a *negative* immediate's
upper bits can coincidentally equal the real `SUB` funct7 pattern
(`0100000`), which would wrongly select `SUB`.

This one was actually caught by simulation, specifically because the
V1.1 test program included `addi x6, x0, -1`, which should produce
`x6 = -1` but came out as `x6 = 1` — i.e. `0 - (-1)` computed instead of
`0 + (-1)`. Every *positive*-immediate `ADDI` in the same test still
passed, which was the clue that pointed at the immediate's sign-extended
upper bits specifically.

**Fix**: added an `is_itype` input to `alu_control` (wired to `ALUSrc`,
already `1` for exactly the I-type ALU ops), gating the `ADD`/`SUB` check
on it — the `SRL`/`SRA` check deliberately does *not* gate on it, since
that bit is meaningful for I-type shifts too.

**Regression test**: `alu_control_tb.v` now explicitly feeds
`funct3=000, funct7=1111111, is_itype=1` and confirms it still resolves
to `ADD`. `cpu_pipeline_v11_tb.v` still includes the original
`addi x6, x0, -1` case that surfaced it.

---

## Toolchain

- **Icarus Verilog** — primary simulator. Also specifically verified
  against a from-source build of **iverilog-13** (a newer/stricter dev
  branch than the packaged version), after discovering it enforces
  stricter signal-declaration-before-use rules that the packaged version
  only warns about. All RTL compiles clean (zero errors, zero implicit
  wires) on both.
- **GTKWave / VS Code's waveform viewer** — used to directly confirm
  hazard-handling signals (`hazard_stall`, `pipeline_flush`) pulse for
  exactly the expected number of cycles at the expected simulation
  times, not just that final register values happen to come out right.
- **Yosys** (both the packaged version and a newer pip-installed build)
  — generic synthesis, and the source of both bugs documented above.
- **OpenROAD** (via its Python API) — real static timing analysis
  against the sky130 standard-cell library. See `synthesis/
  SYNTHESIS_REPORT_SKY130.md`.

---

## What's Verified vs. What Isn't

**Verified end-to-end** (decoded, executed, and checked via a full
fetch→writeback test): `ADD`, `SUB`, `ADDI`, `AND`/`OR`/`XOR` (via ALU
unit tests, not yet a dedicated CPU-level test — see below), `SLL`/`SRL`/
`SRA` and their immediate forms, `SLT`/`SLTU`/`SLTI`/`SLTIU`, `LW`/`SW`,
all six branches, `JAL`/`JALR`, `LUI`/`AUIPC`, `FENCE`.

**Known gap**: `AND`/`OR`/`XOR`/`SLL`/`SRL`/`SLT` are verified at the ALU
and ALU-control unit-test level (i.e. "does the ALU compute the right
result for this opcode"), but don't yet have a dedicated CPU-level test
exercising them through a full fetch→decode→execute→writeback path the
way `ADDI`/`SLTU`/etc. do. Worth closing this gap before treating ISA
coverage as fully proven rather than "very likely correct."

**Out of scope for this test suite**: `ECALL`/`EBREAK`/CSR instructions
— not implemented (see `architecture.md`), so nothing to test yet.