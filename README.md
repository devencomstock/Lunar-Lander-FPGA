# Lunar Lander: FPGA Physics Simulator

## Project Overview

FPGA-based lunar lander game implemented in SystemVerilog targeting the Lattice ICE40HX8K. Simulates altitude, velocity, and fuel dynamics in real-time using BCD ten's-complement arithmetic. Determines safe landing versus crash conditions via finite state machine. Outputs status and display data to 4-digit 7-segment LEDs.

## What I Built

All student-authored RTL modules in `src/`:

- **ll_alu** — Physics engine: computes altitude, velocity, and fuel using BCD arithmetic
- **ll_memory** — 16-bit register file: stores and synchronously updates lander state
- **ll_control** — Landing/crash FSM: detects ground contact and evaluates landing criteria
- **ll_display** — Multiplexed 7-segment driver: displays altitude, velocity, fuel, or thrust
- **lunarlander** — Top-level integration: clock prescaling, input synchronization, LED output
- **bcd_arithmetic** — 1-digit and 4-digit BCD adder/subtractor primitives
- **top** — Module hierarchy definition

## Results

- **882 automated tests passing** (100% pass rate)
  - ll_alu: 639 tests
  - ll_memory: 12 tests
  - ll_control: 15 tests
  - ll_display: 117 tests
  - lunarlander integration: 99 tests
- **Data representation:** 16-bit BCD ten's-complement (0x0000 to 0x9999)
- **Display modes:** 4 (altitude, velocity, fuel, thrust)

## Physics Model

- altₙ = max(0, alt + vel)
- velₙ = vel − 5 (gravity) + thrust (if fuel > 0)
- fuelₙ = max(0, fuel − thrust)
- **Landing:** altitude = 0 AND velocity ≥ −30 ft/s AND thrust ≤ 5 ft/s²
- **Crash:** velocity < −30 ft/s OR (at ground AND thrust > 5 ft/s²)

## How to Run

**Verification:**
```bash
make PART=1 verify_ll_alu       # 639 tests
make PART=2 verify_lunarlander  # Full system (99 tests)
```

**FPGA deployment:**
1. Connect custom I/O board (pushbuttons, 7-segment display, LEDs)
2. Compile: `make PART=2 cram` (Yosys → nextpnr → IceStorm bitstream)
3. Program FPGA via SRAM (non-persistent)
4. Control thrust with buttons 0–9; mode select with Z/Y/X/W

## Provided Infrastructure

The following were provided by course staff and are not student-authored:

- **Testbenches** (sim/): tb_ll.sv, tb_part1.cpp, tb_part2.cpp — full verification logic
- **Pin constraints** (constraints/): pinmap.pcf — board I/O mapping
- **Support libraries** (support/, uart/): I/O primitives and simulation models
- **Build tooling**: Makefile, Yosys/nextpnr/IceStorm integration

## Documentation

- [docs/block_diagram.md](docs/block_diagram.md) — RTL architecture and dataflow
- [docs/design_notes.md](docs/design_notes.md) — BCD representation, control logic, clock domains
