// LL_DISPLAY: 7-segment display multiplexer and encoder
//
// Purpose: Drives a 4-digit multiplexed 7-segment display with four display modes
// Selected via pushbutton input (keyout encoding)
//
// Display modes (selected by keyout bits):
//   - ALT (altitude): shows current altitude in feet
//   - VEL (velocity): shows current velocity with negative formatting for downward motion
//   - GAS (fuel): shows remaining fuel
//   - THR (thrust): shows current thrust setting (0-9)
//
// Output: 32 7-segment bits (4 digits × 8 bits per digit, including DP if used)
// Each 8-bit output controls one digit's segment, where bit layout is:
//   bit[6:0] = {a, b, c, d, e, f, g} (active-low or active-high per hardware)
//   bit[7]   = DP (decimal point, if used)
//
// Clock:  Synchronous (posedge clk) — updates display every cycle
// Reset:  Asynchronous (posedge rst)
//
// Interface:
//   Input:  clk, rst, keyout[4:0] (mode select), alt, vel, fuel, thrust (16-bit each)
//   Output: ss7, ss6, ss5, ss3, ss2, ss1, ss0 (8-bit digit outputs, MSN to LSN)
//
module ll_display (
    input  logic clk,
    input  logic rst,
    input  logic land,
    input  logic crash,
    input  logic [3:0] disp_ctrl,
    input  logic [15:0] alt,
    input  logic [15:0] vel,
    input  logic [15:0] fuel,
    input  logic [15:0] thrust,
    output logic [7:0] ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
    output logic red, green
);

    assign ss4 = 8'b0000000;
    logic [1:0] mode, mode_n;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            mode <= 2'b00;
        end 
        else begin
            mode <= mode_n;
        end
    end

    always_comb begin
        mode_n = mode;
        if (|disp_ctrl) begin
            if (disp_ctrl[3]) begin
                mode_n = 2'd0;
            end 
            else if (disp_ctrl[2]) begin
                mode_n = 2'd1;
            end 
            else if (disp_ctrl[1]) begin
                mode_n = 2'd2;
            end 
            else if (disp_ctrl[0]) begin
                mode_n = 2'd3; 
            end
        end
    end 

    localparam logic [23:0] ALT = 24'b01110111_00111000_01111000;
    localparam logic [23:0] VEL = 24'b00111110_01111001_00111000;
    localparam logic [23:0] GAS = 24'b01101111_01110111_01101101;
    localparam logic [23:0] THR = 24'b01111000_01110110_01010000;

    logic [23:0] mode_disp;
    always_comb begin
        case (mode)
            2'd0: mode_disp = ALT;
            2'd1: mode_disp = VEL;
            2'd2: mode_disp = GAS;
            2'd3: mode_disp = THR;
            default: mode_disp = ALT;
        endcase
    end

    assign ss7 = mode_disp[23:16];
    assign ss6 = mode_disp[15:8];
    assign ss5 = mode_disp[7:0];

    logic [15:0] alt_neg, vel_neg, fuel_neg, thrust_neg;

    bcdaddsub4 alt_neg_calc( .a(16'h0000), .b(alt), .op(1'b1), .s(alt_neg) );
    bcdaddsub4 vel_neg_calc( .a(16'h0000), .b(vel), .op(1'b1), .s(vel_neg) );
    bcdaddsub4 fuel_neg_calc( .a(16'h0000), .b(fuel), .op(1'b1), .s(fuel_neg) );
    bcdaddsub4 thrust_neg_calc( .a(16'h0000), .b(thrust), .op(1'b1), .s(thrust_neg) );

    logic alt_neg_check, vel_neg_check, fuel_neg_check, thrust_neg_check;
    assign alt_neg_check = (alt[15:12] == 4'h9);
    assign vel_neg_check = (vel[15:12] == 4'h9);
    assign fuel_neg_check = (fuel[15:12] == 4'h9);
    assign thrust_neg_check = (thrust[15:12] == 4'h9);

    logic [15:0] disp_value;
    logic neg_check;
    always_comb begin
        case (mode)
            2'd0: begin 
            if (alt_neg_check) begin
                    disp_value = alt_neg;
                    neg_check = 1'b1;
                end 
                else begin
                    disp_value = alt;
                    neg_check = 1'b0;
                end
            end
            2'd1: begin
                if (vel_neg_check) begin
                    disp_value = vel_neg;
                    neg_check = 1'b1;
                end 
                else begin
                    disp_value = vel;
                    neg_check = 1'b0;
                end
            end
            2'd2: begin
                if (fuel_neg_check) begin
                    disp_value = fuel_neg;
                    neg_check = 1'b1;
                end 
                else begin
                    disp_value = fuel;
                    neg_check = 1'b0;
                end
            end
            2'd3: begin
                if (thrust_neg_check) begin
                    disp_value = thrust_neg;
                    neg_check = 1'b1;
                end 
                else begin
                    disp_value = thrust;
                    neg_check = 1'b0;
                end
            end
            default: begin
                disp_value = alt;
                neg_check = 1'b0;
            end
        endcase
    end

    logic [3:0] dig3, dig2, dig1, dig0;
    assign dig3 = disp_value[15:12];
    assign dig2 = disp_value[11:8];
    assign dig1 = disp_value[7:4];
    assign dig0 = disp_value[3:0];

    logic en3, en2, en1, en0;
    always_comb begin
        if (neg_check) begin
            en3 = 1'b1;
            en2 = (dig2 != 4'h0 || dig3 != 4'h0);
            en1 = en2 || (dig1 != 4'h0);
            en0 = 1'b1;
        end 
        else begin
            en3 = (dig3 != 4'h0);
            en2 = en3 || (dig2 != 4'h0);
            en1 = en2 || (dig1 != 4'h0);
            en0 = 1'b1;
        end
    end

    logic [6:0] seg3, seg2, seg1, seg0;
    ssdec dec3( .in(dig3), .enable(en3), .out(seg3) );
    ssdec dec2( .in(dig2), .enable(en2), .out(seg2) );
    ssdec dec1( .in(dig1), .enable(en1), .out(seg1) );
    ssdec dec0( .in(dig0), .enable(en0), .out(seg0) );

    localparam logic [6:0] SEG_MINUS = 7'b1000000;
    always_comb begin
        if (neg_check) begin
            ss3 = {1'b0, SEG_MINUS};
        end 
        else begin
            ss3 = {1'b0, seg3};
        end
        ss2 = {1'b0, seg2};
        ss1 = {1'b0, seg1};
        ss0 = {1'b0, seg0};
    end

    assign red = crash;
    assign green = land;


endmodule