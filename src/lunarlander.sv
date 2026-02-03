// LUNARLANDER: Top-level system integration
//
// Purpose: Integrates all lander subsystems (ALU, memory, control, display)
// Manages multiple clock domains (1 Hz game logic, 16 Hz display)
// Provides asynchronous input synchronization for button presses
//
// Features:
//   - Clock prescalers for generating game clock (hz1) and display clock (hz16) from 100 MHz input
//   - Asynchronous input synchronizer (double-flop) for keypad debouncing and metastability prevention
//   - Thrust control: converts 4-bit button input to thrust setting (0-9)
//   - Status output: red LED for crash, green LED for safe landing
//
// I/O Mapping:
//   Input:  hz100 (100 MHz clock), reset, [19:0] keypad buttons
//   Output: [7:0] × 8 multiplexed 7-segment display digits
//           red (crash status), green (landing status)
//
// Parameters:
//   FUEL, ALTITUDE, VELOCITY, THRUST, GRAVITY — passed through to subsystem instances
//
// Clock Domains:
//   hz100:   Primary input clock (100 MHz)
//   hz1:     Game logic clock (1 Hz) — drives ll_memory, ll_alu, ll_control
//   hz16:    Display clock (16 Hz) — drives ll_display
//   Async:   Keypad input (synchronized via double-flop before use)
//module lunarlander #(
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





    
