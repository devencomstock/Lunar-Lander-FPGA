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




