`timescale 1ns/1ps

module tb_input_ctrl;
    parameter DW = 8;

    reg                    clk;
    reg                    rst_n;
    reg                    start;
    reg  signed [9*DW-1:0] a_mat_flat;
    reg  signed [9*DW-1:0] b_mat_flat;

    wire                   busy;
    wire                   clear_acc;
    wire                   start_capture;
    wire                   wt_valid_in;
    wire signed [DW-1:0]   wt_top_0;
    wire signed [DW-1:0]   wt_top_1;
    wire signed [DW-1:0]   wt_top_2;
    wire                   fm_valid_0;
    wire                   fm_valid_1;
    wire                   fm_valid_2;
    wire signed [DW-1:0]   fm_left_0;
    wire signed [DW-1:0]   fm_left_1;
    wire signed [DW-1:0]   fm_left_2;

    integer pass_cnt;
    integer fail_cnt;
    integer case_id;

    input_ctrl_3x3 #(DW) u_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .a_mat_flat(a_mat_flat),
        .b_mat_flat(b_mat_flat),
        .busy(busy),
        .clear_acc(clear_acc),
        .start_capture(start_capture),
        .wt_valid_in(wt_valid_in),
        .wt_top_0(wt_top_0),
        .wt_top_1(wt_top_1),
        .wt_top_2(wt_top_2),
        .fm_valid_0(fm_valid_0),
        .fm_valid_1(fm_valid_1),
        .fm_valid_2(fm_valid_2),
        .fm_left_0(fm_left_0),
        .fm_left_1(fm_left_1),
        .fm_left_2(fm_left_2)
    );

    always #5 clk = ~clk;

    task do_start;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task check_wt;
        input [DW-1:0] exp_0;
        input [DW-1:0] exp_1;
        input [DW-1:0] exp_2;
        input [127:0]  desc;
        begin
            @(negedge clk);
            if (wt_valid_in !== 1'b1) begin
                $display("[FAIL] Case %0d (%0s): wt_valid_in=%b", case_id, desc, wt_valid_in);
                fail_cnt = fail_cnt + 1;
            end else if (wt_top_0 !== exp_0 || wt_top_1 !== exp_1 || wt_top_2 !== exp_2) begin
                $display("[FAIL] Case %0d (%0s): wt=[%0d,%0d,%0d] exp=[%0d,%0d,%0d]",
                         case_id, desc, wt_top_0, wt_top_1, wt_top_2, exp_0, exp_1, exp_2);
                fail_cnt = fail_cnt + 1;
            end else begin
                $display("[PASS] Case %0d (%0s): wt=[%0d,%0d,%0d]",
                         case_id, desc, wt_top_0, wt_top_1, wt_top_2);
                pass_cnt = pass_cnt + 1;
            end
        end
    endtask

    task check_fm;
        input [DW-1:0] exp_0;
        input [DW-1:0] exp_1;
        input [DW-1:0] exp_2;
        input          fv0;
        input          fv1;
        input          fv2;
        input [127:0]  desc;
        begin
            @(negedge clk);
            if (fm_valid_0 !== fv0 || fm_valid_1 !== fv1 || fm_valid_2 !== fv2) begin
                $display("[FAIL] Case %0d (%0s): fm_valid=[%b,%b,%b] exp=[%b,%b,%b]",
                         case_id, desc, fm_valid_0, fm_valid_1, fm_valid_2, fv0, fv1, fv2);
                fail_cnt = fail_cnt + 1;
            end else if (fv0 && fm_left_0 !== exp_0) begin
                $display("[FAIL] Case %0d (%0s): fm_left_0=%0d exp=%0d", case_id, desc, fm_left_0, exp_0);
                fail_cnt = fail_cnt + 1;
            end else if (fv1 && fm_left_1 !== exp_1) begin
                $display("[FAIL] Case %0d (%0s): fm_left_1=%0d exp=%0d", case_id, desc, fm_left_1, exp_1);
                fail_cnt = fail_cnt + 1;
            end else if (fv2 && fm_left_2 !== exp_2) begin
                $display("[FAIL] Case %0d (%0s): fm_left_2=%0d exp=%0d", case_id, desc, fm_left_2, exp_2);
                fail_cnt = fail_cnt + 1;
            end else begin
                $display("[PASS] Case %0d (%0s): fm=[%0d,%0d,%0d] valid=[%b,%b,%b]",
                         case_id, desc, fm_left_0, fm_left_1, fm_left_2,
                         fm_valid_0, fm_valid_1, fm_valid_2);
                pass_cnt = pass_cnt + 1;
            end
        end
    endtask

    initial begin
        clk        = 1'b0;
        rst_n      = 1'b0;
        start      = 1'b0;
        a_mat_flat = '0;
        b_mat_flat = '0;
        pass_cnt   = 0;
        fail_cnt   = 0;
        case_id    = 0;

        repeat (5) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        $display("========== Test 1: Simple Matrix (A=1..9, B=Identity) ==========");
        case_id = 1;
        a_mat_flat = {8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8, 8'd9};
        b_mat_flat = {8'd1, 8'd0, 8'd0, 8'd0, 8'd1, 8'd0, 8'd0, 8'd0, 8'd1};

        if (busy !== 1'b0) begin
            $display("[FAIL] busy should be 0 in IDLE");
            fail_cnt = fail_cnt + 1;
        end

        do_start();
        if (busy !== 1'b1 || clear_acc !== 1'b1) begin
            $display("[FAIL] busy=%b clear_acc=%b after start", busy, clear_acc);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] start triggers busy=1, clear_acc=1");
            pass_cnt = pass_cnt + 1;
        end

        case_id = 2;
        check_wt(8'd1, 8'd0, 8'd0, "B row0");
        case_id = 3;
        check_wt(8'd0, 8'd1, 8'd0, "B row1");
        case_id = 4;
        check_wt(8'd0, 8'd0, 8'd1, "B row2");
        case_id = 5;
        check_fm(8'd3, '0, '0, 1'b1, 1'b0, 1'b0, "T0 A02");
        case_id = 6;
        check_fm(8'd6, 8'd2, '0, 1'b1, 1'b1, 1'b0, "T1 A12 A01");
        case_id = 7;
        check_fm(8'd9, 8'd5, 8'd1, 1'b1, 1'b1, 1'b1, "T2 A22 A11 A00");
        case_id = 8;
        check_fm('0, 8'd8, 8'd4, 1'b0, 1'b1, 1'b1, "T3 A21 A10");
        case_id = 9;
        check_fm('0, '0, 8'd7, 1'b0, 1'b0, 1'b1, "T4 A20");

        $display("========== Test 2: All-Ones Matrix ==========");
        repeat (20) @(negedge clk);
        a_mat_flat = {8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2, 8'd2};
        b_mat_flat = {8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3};
        do_start();
        case_id = 11;
        check_wt(8'd3, 8'd3, 8'd3, "All-3 row0");
        case_id = 12;
        check_wt(8'd3, 8'd3, 8'd3, "All-3 row1");
        case_id = 13;
        check_wt(8'd3, 8'd3, 8'd3, "All-3 row2");
        case_id = 14;
        check_fm(8'd2, '0, '0, 1'b1, 1'b0, 1'b0, "All-2 T0");
        case_id = 15;
        check_fm(8'd2, 8'd2, '0, 1'b1, 1'b1, 1'b0, "All-2 T1");
        case_id = 16;
        check_fm(8'd2, 8'd2, 8'd2, 1'b1, 1'b1, 1'b1, "All-2 T2");
        case_id = 17;
        check_fm('0, 8'd2, 8'd2, 1'b0, 1'b1, 1'b1, "All-2 T3");
        case_id = 18;
        check_fm('0, '0, 8'd2, 1'b0, 1'b0, 1'b1, "All-2 T4");

        $display("========== Test 3: Negative Value Matrix ==========");
        repeat (20) @(negedge clk);
        a_mat_flat = {-8'd1, -8'd2, -8'd3, -8'd4, -8'd5, -8'd6, -8'd7, -8'd8, -8'd9};
        b_mat_flat = {8'd1, 8'd0, 8'd0, 8'd0, 8'd1, 8'd0, 8'd0, 8'd0, 8'd1};
        do_start();
        case_id = 19;
        check_wt(8'd1, 8'd0, 8'd0, "neg row0");
        check_wt(8'd0, 8'd1, 8'd0, "neg row1");
        check_wt(8'd0, 8'd0, 8'd1, "neg row2");
        check_fm(-8'd3, '0, '0, 1'b1, 1'b0, 1'b0, "neg T0");
        check_fm(-8'd6, -8'd2, '0, 1'b1, 1'b1, 1'b0, "neg T1");
        check_fm(-8'd9, -8'd5, -8'd1, 1'b1, 1'b1, 1'b1, "neg T2");
        check_fm('0, -8'd8, -8'd4, 1'b0, 1'b1, 1'b1, "neg T3");
        check_fm('0, '0, -8'd7, 1'b0, 1'b0, 1'b1, "neg T4");

        repeat (5) @(negedge clk);
        $display("==============================================");
        $display("Input Control Unit Test Summary:");
        $display("  PASS: %0d", pass_cnt);
        $display("  FAIL: %0d", fail_cnt);
        $display("==============================================");
        if (fail_cnt > 0) begin
            $fatal(1, "SOME TESTS FAILED!");
        end else begin
            $display("ALL TESTS PASSED!");
        end
        $finish;
    end
endmodule
