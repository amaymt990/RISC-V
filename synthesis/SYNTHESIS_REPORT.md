# Synthesis Report — Generic Technology Mapping (Yosys)

## Scope

This is a **generic** synthesis pass (`yosys`, `synth -top cpu_pipeline`,
no target cell library) — it proves the design is synthesizable and gives
a real cell/flip-flop count, but it does **not** produce a timing/Fmax
number. That requires mapping to an actual standard-cell or FPGA library
(e.g. sky130 + OpenSTA, or a Xilinx/Lattice toolchain) and is listed as
future work below.

## How to reproduce

```bash
pip install yowasp-yosys --break-system-packages
yowasp-yosys -s synthesis/synth_pipeline.ys
```

`synthesis/cpu_pipeline_synth_top.v` is a **synthesis-only** wrapper
around `cpu_pipeline.v` that adds four debug/monitor output ports
(`dbg_pc`, `dbg_wb_data`, `dbg_wb_rd`, `dbg_wb_regwrite`). It is not used
for simulation — see "Bugs found" below for why it exists.

## Results

| Module | Cells (excl. submodules) |
|---|---|
| `data_memory` | 27,486 |
| `register_file` | 5,336 |
| `alu` | 1,289 |
| `ex_stage` (own logic) | 696 |
| `branch_comparator` | 175 |
| `if_id_register` | 129 |
| `id_ex_register` | 330 |
| `ex_mem_register` | 140 |
| `mem_wb_register` | 104 |
| `program_counter` | 32 |
| `immediate_generator` | 92 |
| `control_unit` | 26 |
| `alu_control` | 25 |
| `wb_stage` | 64 |
| `forwarding_unit` | 52 |
| `hazard_detection_unit` | 33 |
| `instruction_memory` | 3 |
| `cpu_pipeline` (top, own logic) | 95 |
| **Total (whole design)** | **36,107 cells / 9,689 flip-flops** |
| **Core CPU logic (excl. `data_memory`)** | **8,621 cells / 1,497 flip-flops** |

## Why `data_memory` dominates the total

`data_memory` alone accounts for 27,486 of the 36,107 total cells —
because its 256×32-bit array wasn't inferred as a RAM macro; without a
target library telling Yosys what block RAM or SRAM looks like, its
default generic flow instead unrolled the whole array into 8,192
individual flip-flops (256 words × 32 bits). This is expected and
correct behavior for a "no target library" pass — a real FPGA flow (with
`synth_ice40`/`synth_xilinx`, which know their device's block RAM
primitives) or a real ASIC flow (with a memory compiler) would map this
to a handful of actual RAM macros instead, and the total cell count would
look completely different — dramatically smaller and RAM-dominated
instead of flip-flop-dominated.

For that reason, the **core CPU logic figure (8,621 cells / 1,497
flip-flops), excluding `data_memory`**, is the more representative number
for describing the processor itself.

## Bugs found and fixed during this pass

Two real RTL issues surfaced only during synthesis — neither affected
simulation, which is exactly why they're worth documenting:

**1. `if (reset || flush)` inside an async-reset-sensitive block.**
`id_ex_register.v` originally combined the asynchronous reset condition
and the synchronous flush condition into a single `if (reset || flush)`.
This simulates identically to writing them as separate branches, but it
confused Yosys's `proc_dff`/`proc_arst` passes trying to separate "truly
asynchronous" logic from "synchronous, just checked first" — Yosys
reported `ERROR: Multiple edge sensitive events found for this signal!`
on `pc_out`. Fixed by nesting them: `if(reset) ... else if(flush) ...`
instead of OR-ing the conditions together.

**2. Zero-observable-output top module gets optimized to nothing.**
`cpu_pipeline`'s only ports are `clk` and `reset` — all state lives in
internal register/memory arrays. A synthesis tool has no way to know any
of that internal state is meant to be observed, so it correctly (if
unhelpfully) swept the *entire design* away as unreachable dead logic —
`stat` reported an empty module. Standard fix, used here: a
synthesis-only wrapper (`cpu_pipeline_synth_top.v`) exposing a handful of
internal signals as debug output ports, without touching the
simulation-verified `cpu_pipeline.v`.

## Known limitations of this report

- No real Fmax/timing number — needs a target cell library + STA (Yosys
  generic synthesis alone doesn't produce this).
- `data_memory` is memory-inefficient in this generic mapping (see above)
  — not representative of a real FPGA/ASIC implementation.
- No area/power estimate — both require a real target library too.

## Future Work

- Target a real FPGA library (`synth_ice40` or `synth_xilinx`) for a
  device-realistic cell/BRAM/DSP count
- Add a standard-cell PDK (e.g. sky130) + OpenSTA for a genuine Fmax number
- Investigate proper block-RAM inference for `data_memory`