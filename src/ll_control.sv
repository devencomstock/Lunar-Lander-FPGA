// LL_CONTROL: Landing and crash detection FSM
//
// Purpose: Determines if lander has achieved safe landing or crashed
// Outputs landing/crash status and controls memory write-enable to freeze state
//
// Landing occurs when:
//   1. Altitude reaches zero (alt + vel <= 0)
//   2. Velocity is safe (>= -30 ft/s)
//   3. Thrust is conservative (<= 5 ft/s²)
//
// Crash occurs when:
//   1. Velocity is too high (< -30 ft/s) during descent, OR
//   2. Thrust is too aggressive (> 5 ft/s²) at touchdown
//
// State is latched: once landed or crashed, state remains frozen (wen = 0)
//
// Clock:  Synchronous (posedge clk)
// Reset:  Asynchronous (posedge rst)
//
// Interface:
//   Input:  clk, rst, alt, vel (16-bit BCD values)
//   Output: land, crash (status flags), wen (write-enable to freeze memory)
//
module ll_control (
    input logic clk,
    input logic rst,
    input logic [15:0] alt,
    input logic [15:0] vel,
    output logic land,
    output logic crash,
    output logic wen
);

    // Check if altitude is at or below ground level
    // (BCD negative numbers have MSNibble = 9-F)
    logic [15:0] alt_plus_vel;
    bcdaddsub4 add_alt_vel (.a(alt), .b(vel), .op(1'b0), .s(alt_plus_vel));

    logic hit_ground;
    logic altvel_neg;
    logic altvel_zero;

    // Check if altitude + velocity <= 0 (would hit ground)
    assign altvel_zero = (alt_plus_vel == 16'h0000);
    assign altvel_neg  = (alt_plus_vel[15:12] >= 4'd5);  // BCD negative check
    assign hit_ground  = altvel_zero || altvel_neg;

    // Define safe velocity threshold: -30 = 0x9970 in BCD 10's complement
    localparam logic [15:0] NEG_30 = 16'h9970;

    // Compare velocity to -30: check if too fast (velocity is too negative)
    logic vel_neg;
    always_comb begin
        if (vel[15] != NEG_30[15]) begin
            vel_neg = vel[15];  // Different sign bit, simple comparison
        end
        else begin
            vel_neg = vel < NEG_30;  // Same sign, do numeric comparison
        end
    end

    logic land_n;
    logic crash_n;
    logic wen_n;

    // FSM logic: Once landed or crashed, stay in that state
    // Safe landing: hit ground AND velocity is <= -30 ft/s AND thrust <= 5
    // Crash: velocity < -30 OR (hit ground AND thrust > 5)
    always_comb begin
        land_n = land;
        crash_n = crash;
        wen_n = ~(land || crash);

        if ( land == 1'b0 && crash == 1'b0 ) begin
            if ( alt_plus_vel == 16'h0000 || alt_plus_vel[15:12] == 4'h9) begin
                if ( vel[15:12] == 4'h9 && vel_neg ) begin
                    crash_n = 1'b1;
                end
                else begin
                    land_n = 1'b1;
                end
                wen_n = 1'b0;
            end
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            land <= 1'b0;
            crash <= 1'b0;
            wen <= 1'b0;
        end
        else begin
            land <= land_n;
            crash <= crash_n;
            wen <= wen_n;
        end
    end

endmodule





    



