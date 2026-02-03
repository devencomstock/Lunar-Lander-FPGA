# Verification Test Suite

This directory contains the verification testbenches for the Lunar Lander FPGA design.

## Test Attribution

All testbenches in this directory were provided by Purdue University ECE 270 course staff.

- `tb_ll.sv` — SystemVerilog module-level integration testbench
- `tb_part1.cpp` — Verilator C++ testbench for Part 1 modules (ll_alu, ll_memory, ll_control)
- `tb_part2.cpp` — Verilator C++ testbench for Part 2 modules (ll_display, lunarlander)

## Test Results

All student-authored RTL passes 882 automated test cases:

| Module | Tests | Result |
|--------|-------|--------|
| ll_alu | 639 | PASS |
| ll_memory | 12 | PASS |
| ll_control | 15 | PASS |
| ll_display | 117 | PASS |
| lunarlander (integration) | 99 | PASS |
| **Total** | **882** | **100%** |

## Running Tests

See top-level README.md for build and test instructions.

```bash
make PART=1 verify_ll_alu
make PART=1 verify_ll_memory
make PART=1 verify_ll_control
make PART=2 verify_ll_display
make PART=2 verify_lunarlander
```

## Test Coverage

Testbenches verify:
- Correct arithmetic behavior under BCD 10's-complement representation
- State machine transitions (landing vs crash detection)
- Display multiplexing and 7-segment encoding
- Edge cases (zero altitude, negative velocity, fuel depletion)
- Full system integration with clock prescaling and input synchronization
