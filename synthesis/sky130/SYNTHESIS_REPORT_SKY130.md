# Synthesis + STA Report — Real sky130 Standard Cell Library

## What this is

Unlike `SYNTHESIS_REPORT.md` (generic technology mapping, no target
library), this report uses the **actual open-source sky130 PDK** —
real standard cells, real LEF physical data, real liberty timing —
and a **real STA engine** (OpenROAD's embedded OpenSTA) to get genuine
timing numbers, not estimates.

Full OpenLane (the usual way people run this flow) needs Docker, which
isn't available in the environment this was built in. Instead, this uses
the same underlying engines OpenLane orchestrates — Yosys for synthesis,
OpenROAD (via its Python API) for STA — driven directly.

## How to reproduce

```bash
# Real OpenROAD, via pip (not the toy/stub package -- this is the genuine
# ~600MB build with full floorplanning/placement/CTS/routing/STA engine)
pip install openroad --break-system-packages

# Real sky130 PDK (standard cells + LEF + liberty), via the official
# volare release artifacts
curl -L -o sky130_fd_sc_hd.tar.zst \
  "https://github.com/efabless/volare/releases/download/sky130-c6d73a35f524070e85faff4a6a9eef49553ebc2b/sky130_fd_sc_hd.tar.zst"
curl -L -o common.tar.zst \
  "https://github.com/efabless/volare/releases/download/sky130-c6d73a35f524070e85faff4a6a9eef49553ebc2b/common.tar.zst"
tar --use-compress-program=unzstd -xf sky130_fd_sc_hd.tar.zst -C pdk/
tar --use-compress-program=unzstd -xf common.tar.zst -C pdk/

# Synthesis mapped to real sky130 cells
yowasp-yosys -s synthesis/sky130/synth_sky130.ys
```

(Note: `volare enable` — the normal, documented way to fetch the PDK —
hit a GitHub API rate limit in this environment; downloading the release
assets directly via `github.com/.../releases/download/...` worked around
it and produces an identical result.)

## Synthesis result

Confirmed real sky130 standard cells throughout the netlist, e.g.:

| Cell | Count | What it is |
|---|---|---|
| `sky130_fd_sc_hd__edfxtp_1` | 8,192 | scan D-FF (data_memory's 256×32 array, unrolled) |
| `sky130_fd_sc_hd__dfrtp_1` | 1,497 | D-FF with reset (core pipeline registers) |
| `sky130_fd_sc_hd__clkinv_1` | 1,591 | clock/signal inverter |
| `sky130_fd_sc_hd__mux4_2` | 1,557 | 4:1 mux |
| `sky130_fd_sc_hd__a22oi_1` | 1,232 | AND-OR-invert |
| `sky130_fd_sc_hd__mux2_1` | 1,072 | 2:1 mux |
| `sky130_fd_sc_hd__nand2_1` | 701 | 2-input NAND |

21,215 total cell instances. The `dfrtp_1` count (1,497) matches the
generic-synthesis flip-flop count from the earlier report exactly — a
good cross-check that both flows produced a consistent result.

## STA result — two numbers, and why there are two

**Worst-case path (data_memory-bound): 283.3 ns → ~3.5 MHz**

```
Startpoint: EX_MEM/_433_ (dfrtp_1)
Endpoint:   MEM/dm/_37278_ (edfxtp_1)
  46.885 ns  register clock-to-Q
 191.901 ns  buffer driving into the write-enable decoder's huge fanout
  38.359 ns  NAND3 in the decode path
   6.156 ns  NOR2 in the decode path
 283.301 ns  data arrival time
```

This is the same root cause flagged in `SYNTHESIS_REPORT.md`:
`data_memory`'s 256-word array was never mapped to a real SRAM macro, so
its write-enable signal fans out to 8,192 individual flip-flops. That one
buffer driving 8,192 loads (`191.9 ns` of the `283.3 ns` path) is the
entire story — this is an artifact of the memory model, not a real
statement about how fast the CPU's actual logic runs.

**Core pipeline logic path (register file write, excluding data_memory): 4.77 ns → ~210 MHz**

```
Startpoint: MEM_WB/_313_ (dfrtp_1)
Endpoint:   ID/rf/_14625_ (dfrtp_1)
  0.532 ns  register clock-to-Q
  0.195 ns  OR4
  0.291 ns  NAND3B
  3.332 ns  NOR4 (widest gate on this path)
  0.417 ns  MUX2
  4.766 ns  data arrival time
```

This is the more representative number: it's the actual writeback →
register-file path, through real combinational logic, with no
memory-array artifact in it. **~210 MHz is a defensible estimate for what
this pipeline could run at once `data_memory` is properly mapped to an
SRAM macro** (which is exactly what a real ASIC or FPGA flow would do
automatically).

## Why this two-number result is worth reporting as-is

A single "Fmax: 3.5 MHz" number would be technically true but
misleading — it says much more about an unmapped test-bench memory model
than about the processor. A single "Fmax: 210 MHz" number would be
optimistic — it ignores a real bottleneck that exists in the current
netlist. Reporting both, with the reasoning connecting them, is the
honest version of "what does this design's timing actually look like."

## Known limitations of this STA pass

- Ideal clock network (no clock tree synthesis / skew modeling yet —
  that's the next step, using OpenROAD's `TritonCTS`)
- No placement/routing yet — these are estimated (Elmore/wire-load-style)
  delays from LEF capacitance data, not post-route parasitics
- Single PVT corner (`tt_025C_1v80` — typical process, 25°C, 1.8V) — a
  real signoff would check `ss` (slow) and `ff` (fast) corners too

## Future Work

- Fix `data_memory`'s RAM mapping (the single highest-leverage next step
  — would likely make the "worst-case" and "core logic" numbers converge)
- Run OpenROAD's floorplanning (`InitFloorplan`) and placement (`Opendp`)
  stages for real (not wire-load-estimated) parasitics
- Clock tree synthesis (`TritonCTS`) for a real clock network instead of
  an ideal one
- Multi-corner STA (`ss`/`ff` in addition to `tt`)
