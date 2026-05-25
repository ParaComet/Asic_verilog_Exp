`timescale 1ns/1ps

module tb_pe;
    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH  = 24;

    reg                             clk;
    reg                             rst_n;
    reg                             clear_acc;
    reg                             fm_valid_in;
    reg                             wt_valid_in;
    reg                             psum_valid_in;
    reg signed [DATA_WIDTH-1:0]     fm_in;
    reg signed [DATA_WIDTH-1:0]     weight_in;
    reg signed [ACC_WIDTH-1:0]      psum_in;

    wire                            fm_valid_out;
    wire                            wt_valid_out;
    wire                            psum_valid_out;
    wire signed [DATA_WIDTH-1:0]    fm_out;
    wire signed [DATA_WIDTH-1:0]    weight_out;
    wire signed [ACC_WIDTH-1:0]     psum_out;
    wire                            overflow;
    wire signed [DATA_WIDTH-1:0]    sr_dbg;
    wire signed [DATA_WIDTH-1:0]    wr_dbg;
    wire signed [DATA_WIDTH-1:0]    fmr_dbg;

    integer pass_cnt;
    integer fail_cnt;
    integer case_id;
    string  dumpfile;

    pe3_pipe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear_acc(clear_acc),
        .fm_valid_in(fm_valid_in),
        .wt_valid_in(wt_valid_in),
        .psum_valid_in(psum_valid_in),
        .fm_in(fm_in),
        .weight_in(weight_in),
        .psum_in(psum_in),
        .fm_valid_out(fm_valid_out),
        .wt_valid_out(wt_valid_out),
        .psum_valid_out(psum_valid_out),
        .fm_out(fm_out),
        .weight_out(weight_out),
        .psum_out(psum_out),
        .overflow(overflow),
        .sr_dbg(sr_dbg),
        .wr_dbg(wr_dbg),
        .fmr_dbg(fmr_dbg)
    );

    always #5 clk = ~clk;

    task check_psum;
        input signed [ACC_WIDTH-1:0] expected;
        input [255:0]                name;
        begin
            if (psum_valid_out !== 1'b1) begin
                $display("[FAIL] %0d %0s: psum_valid_out=%b", case_id, name, psum_valid_out);
                fail_cnt = fail_cnt + 1;
            end else if (psum_out !== expected) begin
                $display("[FAIL] %0d %0s: psum_out=%0d expected=%0d", case_id, name, psum_out, expected);
                fail_cnt = fail_cnt + 1;
            end else begin
                $display("[PASS] %0d %0s: psum_out=%0d", case_id, name, psum_out);
                pass_cnt = pass_cnt + 1;
            end
        end
    endtask

    task check_bit;
        input       actual;
        input       expected;
        input [255:0] name;
        begin
            if (actual !== expected) begin
                $display("[FAIL] %0d %0s: actual=%b expected=%b", case_id, name, actual, expected);
                fail_cnt = fail_cnt + 1;
            end else begin
                $display("[PASS] %0d %0s: actual=%b", case_id, name, actual);
                pass_cnt = pass_cnt + 1;
            end
        end
    endtask

    task preload_weight;
        input signed [DATA_WIDTH-1:0] value;
        begin
            @(negedge clk);
            wt_valid_in   = 1'b1;
            weight_in     = value;
            fm_valid_in   = 1'b0;
            psum_valid_in = 1'b0;
            fm_in         = '0;
            psum_in       = '0;
            @(negedge clk);
            wt_valid_in   = 1'b0;
            weight_in     = '0;
            @(negedge clk);
        end
    endtask

    task do_mac;
        input signed [DATA_WIDTH-1:0] value_fm;
        input signed [ACC_WIDTH-1:0]  value_psum;
        begin
            @(negedge clk);
            fm_valid_in   = 1'b1;
            psum_valid_in = 1'b1;
            fm_in         = value_fm;
            psum_in       = value_psum;
            @(negedge clk);
            fm_valid_in   = 1'b0;
            psum_valid_in = 1'b0;
            fm_in         = '0;
            psum_in       = '0;
        end
    endtask

    initial begin
        if (!$value$plusargs("DUMPFILE=%s", dumpfile)) begin
            dumpfile = "tb_pe.vcd";
        end
        $dumpfile(dumpfile);
        $dumpvars(0, tb_pe);

        clk           = 1'b0;
        rst_n         = 1'b0;
        clear_acc     = 1'b0;
        fm_valid_in   = 1'b0;
        wt_valid_in   = 1'b0;
        psum_valid_in = 1'b0;
        fm_in         = '0;
        weight_in     = '0;
        psum_in       = '0;
        pass_cnt      = 0;
        fail_cnt      = 0;
        case_id       = 0;

        repeat (4) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        case_id = 1;
        preload_weight(8'sd3);
        do_mac(8'sd2, 24'sd4);
        check_psum(24'sd10, "2x3+4");
        check_bit(overflow, 1'b0, "no_overflow");

        case_id = 2;
        preload_weight(-8'sd7);
        do_mac(-8'sd4, -24'sd3);
        check_psum(24'sd25, "-4x-7-3");

        case_id = 3;
        preload_weight(8'sd0);
        do_mac(8'sd5, 24'sd3);
        check_psum(24'sd3, "zero_weight");

        case_id = 4;
        @(negedge clk);
        wt_valid_in = 1'b1;
        weight_in   = 8'sd11;
        @(negedge clk);
        if (wt_valid_out !== 1'b1 || weight_out !== 8'sd11) begin
            $display("[FAIL] %0d first weight shift: valid=%b weight_out=%0d expected=11",
                     case_id, wt_valid_out, weight_out);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] %0d first weight shift outputs current SR", case_id);
            pass_cnt = pass_cnt + 1;
        end
        weight_in = 8'sd22;
        @(negedge clk);
        if (wt_valid_out !== 1'b1 || weight_out !== 8'sd22) begin
            $display("[FAIL] %0d second weight shift: valid=%b weight_out=%0d expected=22",
                     case_id, wt_valid_out, weight_out);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] %0d second weight shift outputs current SR", case_id);
            pass_cnt = pass_cnt + 1;
        end
        wt_valid_in = 1'b0;
        weight_in   = '0;
        #1;
        if (wt_valid_out !== 1'b0 || weight_out !== 8'sd22) begin
            $display("[FAIL] %0d weight drain check: valid=%b weight_out=%0d expected valid=0 data=22",
                     case_id, wt_valid_out, weight_out);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] %0d weight_out holds latest SR after preload", case_id);
            pass_cnt = pass_cnt + 1;
        end

        case_id = 5;
        @(negedge clk);
        fm_valid_in = 1'b1;
        fm_in       = 8'sd42;
        @(negedge clk);
        fm_valid_in = 1'b0;
        if (fm_valid_out !== 1'b1 || fm_out !== 8'sd42 || fmr_dbg !== 8'sd42) begin
            $display("[FAIL] %0d fm propagation: valid=%b fm_out=%0d fmr=%0d",
                     case_id, fm_valid_out, fm_out, fmr_dbg);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] %0d fm propagation", case_id);
            pass_cnt = pass_cnt + 1;
        end

        case_id = 6;
        preload_weight(8'sd127);
        do_mac(8'sd127, 24'sd8380000);
        check_bit(overflow, 1'b1, "positive_overflow");

        case_id = 7;
        @(negedge clk);
        clear_acc = 1'b1;
        @(negedge clk);
        clear_acc = 1'b0;
        if (psum_out !== '0 || overflow !== 1'b0 || psum_valid_out !== 1'b0) begin
            $display("[FAIL] %0d clear_acc: psum=%0d overflow=%b valid=%b",
                     case_id, psum_out, overflow, psum_valid_out);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] %0d clear_acc", case_id);
            pass_cnt = pass_cnt + 1;
        end

        repeat (2) @(negedge clk);
        $display("PE test summary: PASS=%0d FAIL=%0d", pass_cnt, fail_cnt);
        if (fail_cnt != 0) begin
            $fatal(1, "PE tests failed");
        end
        $finish;
    end
endmodule
