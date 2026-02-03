`default_nettype none
// Top-level module that defines I/O ports for FPGA board
// Submodules like lunarlander would be instantiated here in a full design
module top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports for serial communication
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);

  logic [7:0] ss7_int, ss6_int, ss5_int;
  logic [7:0] ss3_int, ss2_int, ss1_int, ss0_int;
  logic red_int, green_int;

  
endmodule

// Add more modules down here...
// Converts raw 20-bit keypad input to 5-bit encoded output with metastability protection
// Encodes which buttons are pressed as a binary value (0-19)
// The synchronizer flops prevent metastability from async button presses
module keysync (
    input logic clk,
    input logic rst,
    input logic [19:0] keyin,
    output logic [4:0] keyout,
    output logic keyclk
);

    // Encode keypad as 5-bit value based on priority encoder logic
    assign keyout[0] = keyin[1] | keyin[3] | keyin[5] | keyin[7] | keyin[9] | keyin[11] | keyin[13] | keyin[15] | keyin[17] | keyin[19];
    assign keyout[1] = keyin[2] | keyin[3] | keyin[6] | keyin[7] | keyin[10] | keyin[11] | keyin[14] | keyin[15] | keyin[18] | keyin[19];
    assign keyout[2] = keyin[4] | keyin[5] | keyin[6] | keyin[7] | keyin[12] | keyin[13] | keyin[14] | keyin[15];
    assign keyout[3] = keyin[8] | keyin[9] | keyin[10] | keyin[11] | keyin[12] | keyin[13] | keyin[14] | keyin[15];
    assign keyout[4] = keyin[16] | keyin[17] | keyin[18] | keyin[19];

    logic raw_keyclk;
    assign raw_keyclk = |keyin;  // Pulse when any key is pressed
    logic sync_ff1;
    logic sync_ff2;

    // Double-flop synchronizer to safely cross async domain
    // Delays keyclk pulse by 2 cycles to prevent metastability issues
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end
        else begin
            sync_ff1 <= raw_keyclk;
            sync_ff2 <= sync_ff1;
        end
// Programmable clock prescaler for generating lower frequency clocks
// lim=0: output = input clock (pass-through)
// lim>0: output toggles every lim+1 cycles
module clock_psc (
    input logic clk,
    input logic rst,
    input logic [31:0] lim,
    output logic hzX
);

    logic [31:0] c;       // Counter
    logic hzX_div;        // Divided clock signal

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            c <= 0;
            hzX_div <= 0;
        end 
        else if (lim != 0) begin
            // Count up to lim, then toggle output and reset counter
            if (c >= lim) begin
                c <= 0;
                hzX_div <= ~hzX_div;
            end 
            else begin
                c <= c + 1;
            end
        end
        else begin
            // When disabled (lim=0), hold counter at 0
            c <= 0;
            hzX_div <= hzX_div;
        end
    end
    
    always_comb begin
        // Mux between input clock and divided clock
        if (lim == 0)
            hzX = clk;     // Pass through input when disabled
        else
            hzX = hzX_div; // Use prescaled output when enabled
    end
    always_comb begin
        if (lim == 0)
            hzX = clk;
        else
            hzX = hzX_div;
    end

endmodule

module ssdec (
    input logic [3:0] in, 
    output logic [6:0] out, 
    input logic enable
);
    always_comb begin
        if (!enable) begin
            out = 7'b0000000;
        end
        else begin
            case (in)
                4'd0: out = 7'b0111111; 
                4'd1: out = 7'b0000110;
                4'd2: out = 7'b1011011;
                4'd3: out = 7'b1001111;
                4'd4: out = 7'b1100110;
                4'd5: out = 7'b1101101;
                4'd6: out = 7'b1111101;
                4'd7: out = 7'b0000111;
                4'd8: out = 7'b1111111;
                4'd9: out = 7'b1100111;
                default: out = 7'b0000000;
            endcase
        end
    end
endmodule

module fa (
    input logic a,
    input logic b,
    input logic ci,
    output logic s,
    output logic co
);

    assign s  = a ^ b ^ ci;
    assign co = (a & b) | (a & ci) | (b & ci);

endmodule

module fa4 (
    input logic [3:0] a,
    input logic [3:0] b,
    input logic ci,
    output logic [3:0] s,
    output logic co
);

    logic c1, c2, c3;
    fa fa0(.a(a[0]), .b(b[0]), .ci(ci), .s(s[0]), .co(c1));
    fa fa1(.a(a[1]), .b(b[1]), .ci(c1), .s(s[1]), .co(c2));
    fa fa2(.a(a[2]), .b(b[2]), .ci(c2), .s(s[2]), .co(c3));
    fa fa3(.a(a[3]), .b(b[3]), .ci(c3), .s(s[3]), .co(co));

endmodule

module bcdadd1 (
    input logic [3:0] a,
    input logic [3:0] b,
    input logic ci,   
    output logic [3:0] s,    
    output logic co   
);

    logic [3:0] s1;  
    logic co1, co2;

    fa4 add0 (.a(a), .b(b), .ci(ci), .s(s1), .co(co1));

    logic check;
    assign check = co1 | (s1[3] & (s1[2] | s1[1]));

    logic [3:0] corr;
    assign corr = check ? 4'b0110 : 4'b0000;

    fa4 add_corr (.a(s1), .b(corr), .ci(1'b0), .s(s), .co(co2));

    assign co = co1 | co2;

endmodule

module bcdadd4 (
    input logic [15:0] a,
    input logic [15:0] b,
    input logic ci,   
    output logic [15:0] s,    
    output logic co   
);


    logic c1, c2, c3;
    bcdadd1 d0 (.a(a[3:0]), .b(b[3:0]), .ci(ci), .s(s[3:0]), .co(c1));
    bcdadd1 d1 (.a(a[7:4]), .b(b[7:4]), .ci(c1), .s(s[7:4]), .co(c2));
    bcdadd1 d2 (.a(a[11:8]), .b(b[11:8]), .ci(c2), .s(s[11:8]), .co(c3));
    bcdadd1 d3 (.a(a[15:12]), .b(b[15:12]), .ci(c3), .s(s[15:12]), .co(co));

endmodule

module bcd9comp1 (
    input logic [3:0] in,
    output logic [3:0] out
);

    always_comb begin
        case (in)
            4'd0: out = 4'd9;
            4'd1: out = 4'd8;
            4'd2: out = 4'd7;
            4'd3: out = 4'd6;
            4'd4: out = 4'd5;
            4'd5: out = 4'd4;
            4'd6: out = 4'd3;
            4'd7: out = 4'd2;
            4'd8: out = 4'd1;
            4'd9: out = 4'd0;
            default: out = 4'd0;
        endcase
    end

endmodule

module bcdaddsub4 (
    input logic [15:0] a,
    input logic [15:0] b,
    input logic op,   
    output logic [15:0] s
);

    logic [3:0] b0_comp, b1_comp, b2_comp, b3_comp;
    logic [3:0] comp0, comp1, comp2, comp3;
    logic co;

    bcd9comp1 c0 (.in(b[3:0]), .out(comp0));
    bcd9comp1 c1 (.in(b[7:4]), .out(comp1));
    bcd9comp1 c2 (.in(b[11:8]), .out(comp2));
    bcd9comp1 c3 (.in(b[15:12]), .out(comp3));

    assign b0_comp = op ? comp0 : b[3:0];
    assign b1_comp = op ? comp1 : b[7:4];
    assign b2_comp = op ? comp2 : b[11:8];
    assign b3_comp = op ? comp3 : b[15:12]; 

    logic [15:0] b_n;
    assign b_n = {b3_comp, b2_comp, b1_comp, b0_comp};
    bcdadd4 addsub (.a(a), .b(b_n), .ci(op), .s(s), .co(co));

endmodule

module ll_memory #(
    parameter ALTITUDE = 16'h4500, 
    parameter VELOCITY = 16'h0, 
    parameter FUEL = 16'h800, 
    parameter THRUST = 16'h5 
)(
    input logic clk,
    input logic rst, 
    input logic wen,

    input logic [15:0] alt_n,    
    input logic [15:0] vel_n,    
    input logic [15:0] fuel_n,   
    input logic [15:0] thrust_n, 

    output logic [15:0] alt,     
    output logic [15:0] vel,      
    output logic [15:0] fuel,   
    output logic [15:0] thrust    
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            alt <= ALTITUDE;
            vel <= VELOCITY;
            fuel <= FUEL;
            thrust <= THRUST;
        end
        else if (wen) begin
            alt <= alt_n;
            vel <= vel_n;
            fuel <= fuel_n;
            thrust <= thrust_n;
        end
    end

endmodule



module ll_alu #(
    parameter GRAVITY = 16'h0005
)(
    input logic [15:0] alt,
    input logic [15:0] vel,
    input logic [15:0] fuel,
    input logic [15:0] thrust,

    output logic [15:0] alt_n,       
    output logic [15:0] vel_n,    
    output logic [15:0] fuel_n        
);

    logic [15:0] alt_c;
    bcdaddsub4 alt_add (.a(alt), .b(vel), .op(1'b0), .s(alt_c));

    logic [15:0] fuel_c;
    bcdaddsub4 fuel_sub (.a(fuel), .b(thrust), .op(1'b1), .s(fuel_c));

    logic [15:0] vel_grav;
    logic [15:0] thrust_c;

    assign thrust_c = (fuel == 16'h0000) ? 16'h0000 : ((thrust > 16'h0010) ? 16'h0010 : thrust);
    bcdaddsub4 grav_sub (.a(vel), .b(GRAVITY), .op(1'b1), .s(vel_grav));

    logic [15:0] vel_c;
    bcdaddsub4 thrust_add (.a(vel_grav), .b(thrust_c), .op(1'b0), .s(vel_c));

    always_comb begin
        if (alt_c[15:12] == 4'h9 || alt_c == 16'h0000) begin
            alt_n = 16'h0000;
            vel_n = 16'h0000;
        end 
        else begin
            alt_n = alt_c;
            vel_n = vel_c;
        end
    end

    always_comb begin
        if (fuel_c[15:12] == 4'h9 || fuel_c == 16'h0000) begin
            fuel_n = 16'h0000;
        end 
        else begin
            fuel_n = fuel_c;
        end
    end
    
endmodule

module ll_control (
    input logic clk,
    input logic rst,
    input logic [15:0] alt,
    input logic [15:0] vel,
    output logic land,
    output logic crash,
    output logic wen
);

    logic [15:0] alt_plus_vel;
    bcdaddsub4 add_alt_vel (.a(alt), .b(vel), .op(1'b0), .s(alt_plus_vel));

    logic hit_ground;
    logic altvel_neg;
    logic altvel_zero;

    assign altvel_zero = (alt_plus_vel == 16'h0000);
    assign altvel_neg  = (alt_plus_vel[15:12] >= 4'd5);
    assign hit_ground  = altvel_zero || altvel_neg;

    localparam logic [15:0] NEG_30 = 16'h9970;

    logic vel_neg;
    always_comb begin
        if (vel[15] != NEG_30[15]) begin
            vel_neg = vel[15];
        end
        else begin
            vel_neg = vel < NEG_30;
        end
    end

    logic land_n;
    logic crash_n;
    logic wen_n;

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

module lunarlander #(
    parameter FUEL = 16'h800,
    parameter ALTITUDE = 16'h4500,
    parameter VELOCITY = 16'h0,
    parameter THRUST = 16'h5,
    parameter GRAVITY = 16'h5
    )(
    input logic hz100, reset,
    input logic [19:0] in,
    output logic [7:0] ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
    output logic red, green
);

    logic [4:0] keyout;
    logic keyclk;
    logic hz1;

    clock_psc psc(.clk(hz100), .rst(reset), .lim(32'd24), .hzX(hz1));
    keysync ks(.clk(hz100), .rst(reset), .keyin(in), .keyout(keyout), .keyclk(keyclk)); 
    
    logic [15:0] thrust_n;
    logic [3:0] keyout_n;
    always_comb begin
        case(keyout)
            5'd19: keyout_n = 4'b1000;
            5'd18: keyout_n = 4'b0100;
            5'd17: keyout_n = 4'b0010;
            5'd16: keyout_n = 4'b0001;
            default: keyout_n = 4'b0000;
        endcase
    end

    always_ff @(posedge keyclk or posedge reset) begin
        if (reset) begin
            thrust_n <= THRUST;
        end 
        else if (~keyout[4]) begin
            thrust_n <= {12'b0, keyout[3:0]};
        end
        else begin
            thrust_n <= thrust_n;
        end
    end

    logic [15:0] alt, vel, fuel, thrust;
    logic [15:0] alt_n, vel_n, fuel_n;
    logic wen;

    ll_alu alu (.alt(alt), .vel(vel), .fuel(fuel), .thrust(thrust), .alt_n(alt_n), .vel_n(vel_n), .fuel_n(fuel_n));
    ll_memory mem (.clk(hz1), .rst(reset), .wen(wen), .alt_n(alt_n), .vel_n(vel_n), .fuel_n(fuel_n), .thrust_n(thrust_n), .alt(alt), .vel(vel), .fuel(fuel), .thrust(thrust));

    logic land, crash;
    ll_control crtl (.clk(hz1), .rst(reset), .alt(alt), .vel(vel), .land(land), .crash(crash), .wen(wen));
    ll_display disp (.clk(keyclk), .rst(reset), .alt(alt), .vel(vel), .fuel(fuel), .thrust(thrust), .land(land), .crash(crash), .disp_ctrl(keyout_n), .ss7(ss7), .ss6(ss6), .ss5(ss5), .ss4(ss4), .ss3(ss3), .ss2(ss2), .ss1(ss1), .ss0(ss0), .red(red), .green(green));



endmodule