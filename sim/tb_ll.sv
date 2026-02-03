`timescale 1ms/1ns
`default_nettype none
module tb_lunarlander();
    logic hz100;
    logic hzX;
    logic reset;
    logic [19:0] pb;
    logic crash, exp_crash;
    logic land, exp_land;
    logic red, green;
    assign land = green;
    assign crash = red;
    logic [7:0] ss7t; logic [6:0] ss7, exp_ss7;
    logic [7:0] ss6t; logic [6:0] ss6, exp_ss6;
    logic [7:0] ss5t; logic [6:0] ss5, exp_ss5;
    logic [7:0] ss3t; logic [6:0] ss3, exp_ss3;
    logic [7:0] ss2t; logic [6:0] ss2, exp_ss2;
    logic [7:0] ss1t; logic [6:0] ss1, exp_ss1;
    logic [7:0] ss0t; logic [6:0] ss0, exp_ss0;
    logic [7:0] u;
    
    lunarlander ll (
        .hz100(hz100), .reset(reset), .in(pb[19:0]), 
        .red(red), .green(green),                       // for crashed/landed
        .ss0({u[0],ss0}), .ss1({u[1],ss1}), .ss2({u[2],ss2}), .ss3({u[3],ss3}),     // for values
        .ss5({u[5],ss5}), .ss6({u[6],ss6}), .ss7({u[7],ss7})                 // for display message
    );

    always begin
        #25 hz100 = ~hz100;
    end
    logic [3:0] hzXctr = 0;
    always_ff @(posedge hz100) begin
        hzXctr = hzXctr + 1;
        if (hzXctr == 4) begin
            hzX = ~hzX;
            hzXctr = 0;
        end
    end

    string msg;
    task check_outputs; 
        // print current time
        $display("Time: %t", $time);
        // check if the outputs are correct
        $display("Checking outputs for %s", msg);
        if (crash == exp_crash) begin
            $display("PASSED: %s, crash == %x", msg, crash);
            passed_subtests = passed_subtests + 1;
        end
        else
            $display("FAILED: %s, crash == %x, expected %x", msg, crash, exp_crash);
        if (land == exp_land) begin
            $display("PASSED: %s, land == %x", msg, land);
            passed_subtests = passed_subtests + 1;
        end
        else
            $display("FAILED: %s, land == %x, expected %x", msg, land, exp_land);
        if (ss7 == exp_ss7) begin
            $display("PASSED: %s, ss7 == %x", msg, ss7);
            passed_subtests = passed_subtests + 1;
        end
        else
            $display("FAILED: %s, ss7 == %x, expected %x", msg, ss7, exp_ss7);
        if (ss6 == exp_ss6) begin
            $display("PASSED: %s, ss6 == %x", msg, ss6);
            passed_subtests = passed_subtests + 1;
        end
        else
            $display("FAILED: %s, ss6 == %x, expected %x", msg, ss6, exp_ss6);
        if (ss5 == exp_ss5) begin
            $display("PASSED: %s, ss5 == %x", msg, ss5);
            passed_subtests = passed_subtests + 1;
        end
        else
            $display("FAILED: %s, ss5 == %x, expected %x", msg, ss5, exp_ss5);
        if (ss3 == exp_ss3) begin
            $display("PASSED: %s, ss3 == %x", msg, ss3);
            passed_subtests = passed_subtests + 1;
        end
        else
            $display("FAILED: %s, ss3 == %x, expected %x", msg, ss3, exp_ss3);
        if (ss2 == exp_ss2) begin
            $display("PASSED: %s, ss2 == %x", msg, ss2);
            passed_subtests = passed_subtests + 1;
        end
        else
            $display("FAILED: %s, ss2 == %x, expected %x", msg, ss2, exp_ss2);
        if (ss1 == exp_ss1) begin
            $display("PASSED: %s, ss1 == %x", msg, ss1);
            passed_subtests = passed_subtests + 1;
        end
        else
            $display("FAILED: %s, ss1 == %x, expected %x", msg, ss1, exp_ss1);
        if (ss0 == exp_ss0) begin
            $display("PASSED: %s, ss0 == %x", msg, ss0);
            passed_subtests = passed_subtests + 1;
        end
        else
            $display("FAILED: %s, ss0 == %x, expected %x", msg, ss0, exp_ss0);
        // debug: print decoded numeric digits from the seven-seg outputs
        $display("DEBUG DIGITS: ss3 ss2 ss1 ss0 => %x %x %x %x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        total_subtests = total_subtests + 9;
        $display("");
    endtask

    function logic [6:0] hex_to_ss(input logic [3:0] in);
        case (in)
            0: hex_to_ss = 7'b0111111;
            1: hex_to_ss = 7'b0000110;
            2: hex_to_ss = 7'b1011011;
            3: hex_to_ss = 7'b1001111;
            4: hex_to_ss = 7'b1100110;
            5: hex_to_ss = 7'b1101101;
            6: hex_to_ss = 7'b1111101;
            7: hex_to_ss = 7'b0000111;
            8: hex_to_ss = 7'b1111111;
            9: hex_to_ss = 7'b1100111;
            10: hex_to_ss = 7'b1110111;
            11: hex_to_ss = 7'b1111100;
            12: hex_to_ss = 7'b0111001;
            13: hex_to_ss = 7'b1011110;
            14: hex_to_ss = 7'b1111001;
            15: hex_to_ss = 7'b1110001;
            default: hex_to_ss = 7'b0000000;
        endcase
    endfunction

    function logic [27:0] num_to_ss(input [15:0] in);
        logic [6:0] ss0x, ss1x, ss2x, ss3x;
        ss0x = hex_to_ss(in[3:0]);
        ss1x = hex_to_ss(in[7:4]);
        ss2x = hex_to_ss(in[11:8]);
        ss3x = hex_to_ss(in[15:12]);
        // do not show leading zeroes - if the number is 0, show a blank
        if (in[15:4] == 0)
            num_to_ss = {21'b0, ss0x};
        else if (in[15:8] == 0)
            num_to_ss = {14'b0, ss1x, ss0x};
        else if (in[15:12] == 0)
            num_to_ss = {7'b0, ss2x, ss1x, ss0x};
        else
            num_to_ss = {ss3x, ss2x, ss1x, ss0x};
    endfunction

    function logic [3:0] ss_to_num(input [6:0] in);
        case(in)
            7'b0111111: ss_to_num = 0;
            7'b0000110: ss_to_num = 1;
            7'b1011011: ss_to_num = 2;
            7'b1001111: ss_to_num = 3;
            7'b1100110: ss_to_num = 4;
            7'b1101101: ss_to_num = 5;
            7'b1111101: ss_to_num = 6;
            7'b0000111: ss_to_num = 7;
            7'b1111111: ss_to_num = 8;
            7'b1100111: ss_to_num = 9;
            7'b1110111: ss_to_num = 10;
            7'b1111100: ss_to_num = 11;
            7'b0111001: ss_to_num = 12;
            7'b1011110: ss_to_num = 13;
            7'b1111001: ss_to_num = 14;
            7'b1110001: ss_to_num = 15;
        endcase
    endfunction

    logic [20:0] STR_ALT, STR_VEL, STR_GAS, STR_THR;
    assign STR_ALT = 21'b111011101110001111000;
    assign STR_VEL = 21'b011111011110010111000;
    assign STR_GAS = 21'b110111111101111101101;
    assign STR_THR = 21'b111100011101101010000;

    logic [27:0] old_ss;

    logic [15:0] alt, vel, thr, gas;
    integer i;

    integer passed_subtests, total_subtests;
    integer ctr;

    initial begin
        $dumpfile("lunarlander.vcd");
        $dumpvars(0, tb_lunarlander);
        $dumplimit(9000000);
        ctr = 0;
        msg = "1. Reset and check altitude";
        hz100 = 0;
        hzX = 0;
        reset = 0;
        pb = 0;
        passed_subtests = 0;
        total_subtests = 0;
        @(posedge hz100);
        {alt, vel, gas, thr} = {16'h4500, 16'h0, 16'h800, 16'h5};
        // init expected
        exp_crash = 0; exp_land = 0;
        {exp_ss7, exp_ss6, exp_ss5, exp_ss3, exp_ss2, exp_ss1, exp_ss0} = {STR_ALT, num_to_ss(alt)};
        // init inputs
        reset = 1;
        pb = 0;
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge hz100);
        end
        check_outputs;
        msg = "2. Check velocity";
        // check velocity
        reset = 0;
        @(posedge hz100);
        @(posedge hz100);
        pb[18] = 1;
        {exp_ss7, exp_ss6, exp_ss5, exp_ss3, exp_ss2, exp_ss1, exp_ss0} = {STR_VEL, num_to_ss(vel)};
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        check_outputs;
        pb = 0;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        msg = "3. Check gas";
        // check gas
        reset = 0;
        @(posedge hz100);
        @(posedge hz100);
        pb[17] = 1;
        {exp_ss7, exp_ss6, exp_ss5, exp_ss3, exp_ss2, exp_ss1, exp_ss0} = {STR_GAS, num_to_ss(gas)};
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        check_outputs;
        pb = 0;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        msg = "4. Check thrust";
        // check thrust
        reset = 0;
        @(posedge hz100);
        @(posedge hz100);
        pb[16] = 1;
        {exp_ss7, exp_ss6, exp_ss5, exp_ss3, exp_ss2, exp_ss1, exp_ss0} = {STR_THR, num_to_ss(thr)};
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        check_outputs;
        pb = 0;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        ///////////////////////////////////////
        // set thrust to 0
        msg = "5. Set thrust to 0";
        pb[0] = 1;
        thr = 0;
        {exp_ss7, exp_ss6, exp_ss5, exp_ss3, exp_ss2, exp_ss1, exp_ss0} = {STR_THR, num_to_ss(thr)};
        for (i = 0; i < 7; i=i+1) @(posedge hzX);   // not a typo - waiting for thrust to change
        check_outputs;
        pb = 0;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);

        // switch to alt
        msg = "6. Switch to alt";
        pb[19] = 1;
        {exp_ss7, exp_ss6, exp_ss5, exp_ss3, exp_ss2, exp_ss1, exp_ss0} = {STR_ALT, num_to_ss(alt)};
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        check_outputs;
        // $display("alt: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        pb = 0;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);

        // wait until alt falls to 2000
        while ({ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0)} > 16'h3000 && (ctr < 2000)) begin
            @(posedge hzX);
            ctr++;
            // $display("alt: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        end

        // switch to vel
        msg = "7. Set thrust to 9, show velocity";
        pb[9] = 1;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        pb = 0;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        pb[18] = 1;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        pb = 0;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        // $display("vel: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        while ({ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0)} >= 12'h100 && (ctr < 2000)) begin
            @(posedge hzX);
            ctr++;
            // $display("vel: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        end
        ctr = 0;
        while ({ss_to_num(ss1), ss_to_num(ss0)} >= 8'h30 && (ctr < 2000)) begin
            @(posedge hzX);
            ctr++;
            // $display("vel: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        end
        vel = 16'h26;
        {exp_ss7, exp_ss6, exp_ss5, exp_ss3, exp_ss2, exp_ss1, exp_ss0} = {STR_VEL, 7'h40, 7'h0, hex_to_ss(vel[7:4]), hex_to_ss(vel[3:0])};
        check_outputs;

        msg = "8. Set thrust to 5, show altitude - should land";
        pb[5] = 1;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        pb = 0;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        pb[19] = 1;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        pb = 0;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        // $display("alt: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        while (({ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0)} >= 12'h100) && (ctr < 2000)) begin
            @(posedge hzX);
            ctr++;
            // $display("alt: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        end
        ctr = 0;
        while (({ss_to_num(ss1), ss_to_num(ss0)} >= 8'h10) && (ctr < 2000)) begin
            @(posedge hzX);
            ctr++;
            // $display("alt: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        end
        ctr = 0;
        while ((ss_to_num(ss0) > 4'h0) && (ctr < 2000)) begin
            @(posedge hzX);
            ctr++;
            // $display("alt: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        end
        exp_land = 1;
        alt = 0;
        {exp_ss7, exp_ss6, exp_ss5, exp_ss3, exp_ss2, exp_ss1, exp_ss0} = {STR_ALT, num_to_ss(alt)};
        check_outputs;

        ///////////////////////////////////////
        // now test a crash
        msg = "9. Reset for testing crash";
        reset = 1;
        exp_land = 0;
        exp_crash = 0;
        alt = 16'h4500;
        #200;
        {exp_ss7, exp_ss6, exp_ss5, exp_ss3, exp_ss2, exp_ss1, exp_ss0} = {STR_ALT, num_to_ss(alt)};
        check_outputs;

        // test fuel drop
        msg = "10. Show fuel until zero";
        reset = 0;
        pb[17] = 1;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        pb = 0;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);

        ctr = 0;
        while ({ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0)} >= 12'h100 && (ctr < 2000)) begin
            @(posedge hzX);
            ctr++;
            // $display("fuel: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        end
        ctr = 0;
        while ({ss_to_num(ss1), ss_to_num(ss0)} >= 8'h10 && (ctr < 2000)) begin
            @(posedge hzX);
            ctr++;
            // $display("fuel: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        end
        ctr = 0;
        while (ss_to_num(ss0) > 4'h0 && (ctr < 2000)) begin
            @(posedge hzX);
            ctr++;
            // $display("fuel: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        end
        gas = 0;
        {exp_ss7, exp_ss6, exp_ss5, exp_ss3, exp_ss2, exp_ss1, exp_ss0} = {STR_GAS, num_to_ss(gas)};
        check_outputs;

        msg = "11. Let lander fall until crash";
        pb[19] = 1;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);
        pb = 0;
        for (i = 0; i < 3; i=i+1) @(posedge hz100);

        ctr = 0;
        while ({ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0)} >= 16'h1000 && (ctr < 2000)) begin
            @(posedge hzX);
            ctr++;
            // $display("alt: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        end 
        ctr = 0;
        while ({ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0)} >= 12'h100 && (ctr < 2000)) begin
            @(posedge hzX);
            ctr++;
            // $display("alt: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        end 
        ctr = 0;
        while ({ss_to_num(ss1), ss_to_num(ss0)} >= 8'h10 && (ctr < 2000)) begin
            @(posedge hzX);
            ctr++;
            // $display("alt: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        end 
        ctr = 0;
        while (ss_to_num(ss0) > 4'h0 && (ctr < 2000)) begin
            @(posedge hzX);
            ctr++;
            // $display("alt: %x%x%x%x", ss_to_num(ss3), ss_to_num(ss2), ss_to_num(ss1), ss_to_num(ss0));
        end

        exp_crash = 1;
        alt = 0;
        {exp_ss7, exp_ss6, exp_ss5, exp_ss3, exp_ss2, exp_ss1, exp_ss0} = {STR_ALT, num_to_ss(alt)};
        check_outputs;

        ///////////////////////////////////////
        // put some viewing distance
        #1000;
        if (passed_subtests == total_subtests)
            $display("ALL %1d TESTS PASSED", passed_subtests);
        else
            $display("%1d out of %1d tests passed.", passed_subtests, total_subtests);  
        $finish;
    end

endmodule
