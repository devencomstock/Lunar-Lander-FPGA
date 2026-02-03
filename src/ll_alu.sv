// Arithmetic Logic Unit: Computes next state based on physics equations
// All values use BCD (binary coded decimal) format for direct display on 7-seg LEDs
// Equations:
//   altitude_new = altitude + velocity
//   velocity_new = velocity - gravity + thrust (if fuel > 0)
//   fuel_new = fuel - thrust
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

    // Calculate new altitude: alt + vel
    logic [15:0] alt_c;
    bcdaddsub4 alt_add (.a(alt), .b(vel), .op(1'b0), .s(alt_c));

    // Calculate new fuel: fuel - thrust
    logic [15:0] fuel_c;
    bcdaddsub4 fuel_sub (.a(fuel), .b(thrust), .op(1'b1), .s(fuel_c));

    // Calculate new velocity: vel - gravity + thrust
    // Must handle no fuel case (thrust clamped to 0 if fuel empty)
    logic [15:0] vel_grav;
    logic [15:0] thrust_c;

    // Clamp thrust: no fuel means 0 thrust, max thrust is 9 (0x0009)
    assign thrust_c = (fuel == 16'h0000) ? 16'h0000 : ((thrust > 16'h0010) ? 16'h0010 : thrust);
    bcdaddsub4 grav_sub (.a(vel), .b(GRAVITY), .op(1'b1), .s(vel_grav));

    // Apply thrust after gravity: vel - grav + thrust
    logic [15:0] vel_c;
    bcdaddsub4 thrust_add (.a(vel_grav), .b(thrust_c), .op(1'b0), .s(vel_c));

    // Clamp results to prevent invalid BCD values
    // If altitude goes negative (MSNibble = 0x9), we've hit ground (alt=0)
    // This stops the lander's descent
    always_comb begin
        if (alt_c[15:12] == 4'h9 || alt_c == 16'h0000) begin
            // Landed - stop all motion
            alt_n = 16'h0000;
            vel_n = 16'h0000;
        end 
        else begin
            alt_n = alt_c;
            vel_n = vel_c;
        end
    end

    // Clamp fuel: negative fuel becomes 0 (BCD underflow check)
    always_comb begin
        if (fuel_c[15:12] == 4'h9 || fuel_c == 16'h0000) begin
            fuel_n = 16'h0000;
        end 
        else begin
            fuel_n = fuel_c;
        end
    end
    
endmodule



    



