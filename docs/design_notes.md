# Design Notes: Lunar Lander Control Logic and Arithmetic

## Ten's-Complement BCD Representation

All values in the lander are represented as 16-bit BCD ten's-complement integers. This format enables direct display on 7-segment LEDs without floating-point conversion.

### Encoding Rules

**Positive Numbers (0x0000 to 0x4999):**
- Each 4-bit nibble encodes one decimal digit (0-9)
- MSN (most significant nibble) in range 0x0-0x4 indicates positive value
- Example: 0x1234 represents +1234

**Negative Numbers (0x5000 to 0xFFFF):**
- MSN in range 0x5-0xF indicates negative value (ten's complement)
- To convert to decimal: compute 10000 - value, then negate
- Examples:
  - 0x9999 = -(10000 - 9999) = -1
  - 0x9970 = -(10000 - 9970) = -30
  - 0x9500 = -(10000 - 9500) = -500

### Why Ten's Complement?

Ten's complement is the BCD equivalent of two's complement in binary. It provides:
1. Automatic sign representation (no separate sign bit needed)
2. Subtraction via addition of the ten's complement value
3. Natural ordering (larger numbers are "less negative")

## Control Logic: Landing and Crash Detection

The `ll_control` module implements a simple but critical state machine:

### State Variables

```verilog
logic land;     // Latched: 1 if safely landed
logic crash;    // Latched: 1 if crashed
logic wen;      // Write-enable: 1 until landing/crash
```

### Ground Contact Detection

The lander reaches ground level when `alt + vel <= 0` (i.e., next-cycle altitude would be non-positive).

```verilog
logic altvel_zero = (alt_plus_vel == 16'h0000);
logic altvel_neg  = (alt_plus_vel[15:12] >= 4'd5);  // BCD MSN check
logic hit_ground = altvel_zero || altvel_neg;
```

This checks are performed combinationally so the decision is immediate.

### Velocity Comparison

Safe landing velocity is -30 ft/s, represented as 0x9970 in BCD ten's-complement:

```verilog
localparam logic [15:0] NEG_30 = 16'h9970;

logic vel_neg;
always_comb begin
    if (vel[15] != NEG_30[15]) begin
        // Different signs: compare MSN only
        vel_neg = vel[15];
    end
    else begin
        // Same sign: full numeric comparison
        vel_neg = vel < NEG_30;
    end
end
```

The MSN comparison detects sign differences cheaply. If signs match, a full comparison is needed.

### Landing vs Crash Decision

Once ground is contacted:

```verilog
if (hit_ground) begin
    if (vel_neg && thrust <= 16'h0005) begin
        land_n = 1'b1;      // Safe: velocity <= -30 and thrust <= 5
    end
    else begin
        crash_n = 1'b1;     // Crash: too fast or too much thrust
    end
end
```

State latching ensures once `land` or `crash` is asserted, it remains asserted:

```verilog
land_n = land ? 1'b1 : (hit_ground && vel_neg && thrust <= 5);
crash_n = crash ? 1'b1 : (vel_neg || (hit_ground && thrust > 5));
wen_n = land || crash ? 1'b0 : 1'b1;  // Freeze memory when terminal state reached
```

## Display Mode Selection

The `ll_display` module uses 4-bit pushbutton input to select display mode:

### Mode Encoding

| Mode | Buttons | Display Value | Notes |
|------|---------|---------------|-------|
| ALT | 5/13 | altitude | Always positive (0 to 4500) |
| VEL | 6/14 | velocity | Negative formatted with sign (0x9999 to 0x0030) |
| GAS | 7/15 | fuel | Always positive (0 to 2048) |
| THR | 4/12 | thrust | Always positive (0 to 9) |

### Negative Velocity Formatting

When displaying velocity, the module must convert BCD ten's-complement to a human-readable format:

**Input:** 0x9970 (-30 in ten's-complement)
**Output:** Displays as "-30" on LEDs (with special encoding for minus sign)

The specific encoding depends on the 7-segment display hardware. Typically, a specific bit pattern (e.g., 0xF0) is used to display a minus sign.

## Physics Integration

The arithmetic logic unit (ll_alu) performs three operations per cycle:

### 1. Altitude Update: alt_n = max(0, alt + vel)

```verilog
bcdaddsub4 alt_add (.a(alt), .b(vel), .op(1'b0), .s(alt_c));

// Clamp to zero if negative
if (alt_c[15:12] == 4'h9 || alt_c == 16'h0000) begin
    alt_n = 16'h0000;
    vel_n = 16'h0000;  // Stop velocity when landing
end else begin
    alt_n = alt_c;
    vel_n = vel_c;
end
```

Clamping `vel_n` to zero when the lander reaches ground prevents the model from drifting below ground level.

### 2. Fuel Consumption: fuel_n = max(0, fuel - thrust)

```verilog
bcdaddsub4 fuel_sub (.a(fuel), .b(thrust), .op(1'b1), .s(fuel_c));

if (fuel_c[15:12] == 4'h9 || fuel_c == 16'h0000) begin
    fuel_n = 16'h0000;
end else begin
    fuel_n = fuel_c;
end
```

Fuel can never go negative; it saturates at zero.

### 3. Velocity Update: vel_n = vel - gravity + thrust

Thrust is applied only if fuel remains:

```verilog
assign thrust_c = (fuel == 16'h0000) ? 16'h0000 : thrust;

bcdaddsub4 grav_sub (.a(vel), .b(GRAVITY), .op(1'b1), .s(vel_grav));
bcdaddsub4 thrust_add (.a(vel_grav), .b(thrust_c), .op(1'b0), .s(vel_c));
```

## Edge Cases and Their Handling

### Empty Fuel Tank
When `fuel == 0x0000`, thrust is forced to zero. The lander can no longer change velocity and will accelerate downward at 5 ft/s² (gravity alone).

### Altitude Underflow
If altitude would go below zero, it is clamped to 0x0000 and velocity is also zeroed. This prevents the model from representing sub-surface positions.

### Velocity Extremes
BCD ten's-complement can represent velocities from -9999 to +4999 ft/s. In practice, the lander's velocity is constrained by:
1. Initial conditions (0 ft/s)
2. Gravity (−5 ft/s² every cycle)
3. Maximum thrust (≤9 ft/s² countermeasure)

A worst-case descent (no thrust) from 4500 ft would result in roughly:
- After 30 cycles: vel ≈ −150 ft/s
- Impact certain (velocity << −30 ft/s)

## Synchronization and Clock Domains

The design uses a single primary clock domain (1 Hz game clock) with input synchronization:

### Double-Flop Synchronizer
Asynchronous button presses are synchronized via two flip-flops:

```verilog
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        sync_ff1 <= 1'b0;
        sync_ff2 <= 1'b0;
    end
    else begin
        sync_ff1 <= raw_signal;
        sync_ff2 <= sync_ff1;
    end
end

assign synchronized_output = sync_ff2;
```

This eliminates metastability by ensuring the signal is stable for one full clock cycle before the second flip-flop samples it. Trade-off: 2-cycle latency on button presses.

## Module Interface Summary

| Module | Clocked | Reset Type | Key I/O |
|--------|---------|------------|---------|
| ll_memory | Yes (sync) | Async | 4 inputs, 4 outputs (16-bit each) |
| ll_alu | No | N/A | 4 inputs, 3 outputs (16-bit each) |
| ll_control | Yes (sync) | Async | 2 inputs, 3 outputs (16-bit + flags) |
| ll_display | Yes (sync) | Async | 4×16-bit inputs, 8×7-bit outputs |
| lunarlander | Yes (sync) | Async | Buttons, display outputs, LED status |
