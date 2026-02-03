# Block Diagram: Lunar Lander RTL Structure

## System-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     LUNARLANDER (Top-Level)                 │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  INPUT SYNCHRONIZATION                              │   │
│  │  ┌────────────────┐                                 │   │
│  │  │   Keysync      │ Async buttons → 5-bit code      │   │
│  │  │  (Double-Flop) │                                 │   │
│  │  └────────────────┘                                 │   │
│  │        ↓                                             │   │
│  │    [4:0] keyout                                      │   │
│  │    [0] keyclk (synchronized pulse)                  │   │
│  └──────────────────────────────────────────────────────┘   │
│         ↓                                                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  CLOCK DOMAIN MANAGEMENT                            │   │
│  │  ┌────────────────┐     ┌────────────────┐          │   │
│  │  │  Clock PSC #1  │     │  Clock PSC #2  │          │   │
│  │  │ (hz100 → hz1)  │     │ (hz100 → hz16) │          │   │
│  │  └────────────────┘     └────────────────┘          │   │
│  │    100 Hz → 1 Hz         100 Hz → 16 Hz             │   │
│  │    (game clock)           (display clock)            │   │
│  └──────────────────────────────────────────────────────┘   │
│         ↓                          ↓                         │
│  ┌──────────────────┐      ┌──────────────────┐            │
│  │   LL_MEMORY      │      │   LL_DISPLAY     │            │
│  │  (State Store)   │      │ (Mux + Encoder)  │            │
│  │                  │      │                  │            │
│  │ Regs:            │      │ Display modes:   │            │
│  │  • altitude      │◄────►│  • ALT           │            │
│  │  • velocity      │      │  • VEL (with −)  │            │
│  │  • fuel          │      │  • GAS           │            │
│  │  • thrust        │      │  • THR           │            │
│  │                  │      │                  │            │
│  │ Write on wen=1   │      │ 7-seg outputs    │            │
│  └──────────────────┘      └──────────────────┘            │
│      ↑         ↓                    │                        │
│      │    [16:0]×4                 │                        │
│      │     (state)                 │                        │
│      │                             ↓                        │
│      │                      [6:0]×8 → LEDS                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              LL_ALU                                   │  │
│  │  (Physics Engine)                                    │  │
│  │                                                       │  │
│  │  Computes:                                           │  │
│  │  • alt_n = alt + vel (clamped ≥ 0)                 │  │
│  │  • vel_n = vel - 5 + thrust (if fuel > 0)         │  │
│  │  • fuel_n = fuel - thrust (clamped ≥ 0)           │  │
│  │                                                       │  │
│  │  Uses 4-digit BCD adders/subtractors               │  │
│  └───────────────────────────────────────────────────────┘  │
│      ↑                           ↓                           │
│      │                    [16:0]×3                          │
│      │                   (next_state)                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              LL_CONTROL                              │  │
│  │  (FSM: Land/Crash Detection)                        │  │
│  │                                                       │  │
│  │  Inputs:  altitude, velocity                         │  │
│  │  Outputs: land, crash, wen (write-enable)           │  │
│  │                                                       │  │
│  │  Logic:                                              │  │
│  │  • If alt+vel ≤ 0 AND vel ≥ -30 AND thr ≤ 5 →    │  │
│  │    land = 1                                          │  │
│  │  • If vel < -30 OR (at_ground AND thr > 5) →       │  │
│  │    crash = 1                                         │  │
│  │  • wen = 0 when landed or crashed (freeze state)   │  │
│  └───────────────────────────────────────────────────────┘  │
│      ↓                                                       │
│   [land, crash] → Red/Green LEDs                            │
└─────────────────────────────────────────────────────────────┘
```

## Dataflow Details

### Primary State Flow (Per Game Cycle)

```
Clock (hz1 = 1 Hz)
        ↓
┌───────────────────────────┐
│  LL_MEMORY (read state)   │  alt, vel, fuel, thrust
│  Outputs: current values  │                ↓
└───────────────────────────┘                │
                                             ↓
                            ┌─────────────────────────────┐
                            │  LL_ALU (compute physics)   │
                            │ alt_n, vel_n, fuel_n (next) │
                            └─────────────────────────────┘
                                             ↓
                            ┌─────────────────────────────┐
                            │  LL_CONTROL (check landing) │
                            │ wen, land, crash            │
                            └─────────────────────────────┘
                                             ↓
                            Rising clock edge + wen=1
                            ↓
                    ┌───────────────────────────┐
                    │  LL_MEMORY (write state)  │
                    │  If wen=1: load next      │
                    │  If wen=0: hold current   │
                    └───────────────────────────┘
                            ↓
                    State updated for next cycle
```

### Display Refresh (Per Display Cycle @ 16 Hz)

```
Clock (hz16 = 16 Hz)
    ↓
┌──────────────────────────────────────────┐
│  LL_MEMORY (read state)                  │
│  alt, vel, fuel, thrust → ALL FOUR       │
└──────────────────────────────────────────┘
    ↓
┌──────────────────────────────────────────┐
│  LL_DISPLAY (select and encode)          │
│  Input: [4:0] keyout (display mode)      │
│  Output: 32-bit display code (4×8-bit)   │
│  • Selects one of {alt, vel, fuel,       │
│    thrust} based on keyout               │
│  • Converts to 7-segment encoding        │
│  • Handles negative velocity display     │
└──────────────────────────────────────────┘
    ↓
Parallel output to 4×8-bit LEDs (32 total)
```

## Critical Path Analysis

**Game Logic Path (worst-case):**
```
LL_MEMORY (async read) 
  → LL_ALU (3× BCD add/sub)
  → LL_CONTROL (comparisons + FSM)
  → Setup time into LL_MEMORY
```

The critical path is the ALU's three cascaded BCD operations. Each BCD adder operates on 4-digit values, so there is carry propagation through all four nibbles. At 1 Hz, timing is not a concern, but at higher frequencies the ALU would be pipelined.

**Display Path (lower priority):**
```
LL_MEMORY (async read)
  → LL_DISPLAY (mux + 7-seg encoder)
  → LED drivers
```

Display updates are synchronous at 16 Hz (faster than user perception), allowing smooth multiplexing.

## Module Interfaces (Simplified)

### ll_memory
```
Input:  clk, rst, wen
        [16:0] alt_n, vel_n, fuel_n, thrust_n
Output: [16:0] alt, vel, fuel, thrust
```

### ll_alu
```
Input:  [16:0] alt, vel, fuel, thrust
Output: [16:0] alt_n, vel_n, fuel_n
```

### ll_control
```
Input:  clk, rst
        [16:0] alt, vel
Output: land, crash, wen
```

### ll_display
```
Input:  clk, rst, hz16
        [4:0] keyout (mode select)
        [16:0] alt, vel, fuel, thrust
Output: [6:0]×8 seven_segment_displays
```

### lunarlander (integration)
```
Input:  hz100 (100 MHz clock)
        rst
        [19:0] keypad buttons
Output: [7:0]×8 display segments
        red, green (status LEDs)
```

## Clock Domain Relationships

| Domain | Frequency | Purpose | Modules |
|--------|-----------|---------|---------|
| Clock (input) | 100 MHz | Raw oscillator | External |
| hz1 | 1 Hz | Game loop | ll_memory, ll_control, ll_alu |
| hz16 | 16 Hz | Display refresh | ll_display |
| Async | N/A | Button inputs | keysync synchronizer |

Synchronization points:
- **Async → hz1:** Keysync double-flops (2-cycle latency)
- **hz1 → hz16:** Display samples game state every 16 hz1 cycles
