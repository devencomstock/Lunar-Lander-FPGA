// LL_MEMORY: Register file for lander state
// 
// Purpose: Stores and updates altitude, velocity, fuel, and thrust values
// Synchronously updates state on rising clock edge when write-enable (wen) is asserted
// Asynchronously resets to parameter-defined initial values on reset assertion
//
// All values represented in 16-bit BCD ten's-complement format
//
// Clock:  Synchronous (posedge clk)
// Reset:  Asynchronous (posedge rst) — must use async reset for initialization
// Enable: wen (1 = update state, 0 = hold current values)
//
// Interface:
//   Input:  clk, rst, wen, alt_n, vel_n, fuel_n, thrust_n
//   Output: alt, vel, fuel, thrust (current state)
//
module ll_memory #(
    parameter ALTITUDE = 16'h4500,  // Start at 4500 feet
    parameter VELOCITY = 16'h0,     // Start at rest
    parameter FUEL = 16'h800,       // 2048 units of fuel
    parameter THRUST = 16'h5        // Initial thrust = 5
)(
    input logic clk,
    input logic rst,                // Async reset
    input logic wen,                // Write enable - update on clock edge if high

    input logic [15:0] alt_n,    
    input logic [15:0] vel_n,    
    input logic [15:0] fuel_n,   
    input logic [15:0] thrust_n, 

    output logic [15:0] alt,     
    output logic [15:0] vel,      
    output logic [15:0] fuel,   
    output logic [15:0] thrust    
);

    // All registers update synchronously on clock, but only when wen=1
    // This allows control logic to freeze state during landing/crash
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialize to parameter values on reset
            alt <= ALTITUDE;
            vel <= VELOCITY;
            fuel <= FUEL;
            thrust <= THRUST;
        end
        else if (wen) begin
            // Update all state values from ALU outputs
            alt <= alt_n;
            vel <= vel_n;
            fuel <= fuel_n;
            thrust <= thrust_n;
            vel <= vel_n;
            fuel <= fuel_n;
            thrust <= thrust_n;
        end
    end

endmodule




