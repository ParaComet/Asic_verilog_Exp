`timescale 1ns/1ps

module tb;
    parameter DW = 8;
    parameter AW = 24;

    reg clk;
    reg rst_n;
    reg start;
    reg signed [9*DW-1:0] a_mat_flat;
    reg signed [9*DW-1:0] b_mat_flat;

    wire done;
    wire signed [AW-1:0] c00,c01,c02,c10,c11,c12,c20,c21,c22;

    integer fd;
    integer r;
    integer case_id;
    integer timeout_cnt;
    integer pass_cnt, fail_cnt;

    integer a0,a1,a2,a3,a4,a5,a6,a7,a8;
    integer b0,b1,b2,b3,b4,b5,b6,b7,b8;
    integer e0,e1,e2,e3,e4,e5,e6,e7,e8;

    top_matmul_3x3 #(DW,AW) dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .a_mat_flat(a_mat_flat), .b_mat_flat(b_mat_flat),
        .done(done),
        .c00(c00), .c01(c01), .c02(c02),
        .c10(c10), .c11(c11), .c12(c12),
        .c20(c20), .c21(c21), .c22(c22)
    );

    always #5 clk = ~clk;

    task pulse_start;
    begin
        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
    end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        a_mat_flat = '0;
        b_mat_flat = '0;
        case_id = 0;
        pass_cnt = 0;
        fail_cnt = 0;

        repeat(5) @(negedge clk);
        rst_n = 1'b1;

        fd = $fopen("vectors.txt", "r");
        if (fd == 0) begin
            $display("ERROR: cannot open vectors.txt");
            $finish;
        end

        while (!$feof(fd)) begin
            r = $fscanf(fd,
                "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
                a0,a1,a2,a3,a4,a5,a6,a7,a8,
                b0,b1,b2,b3,b4,b5,b6,b7,b8,
                e0,e1,e2,e3,e4,e5,e6,e7,e8);

            if (r != 27) begin
                if (!$feof(fd))
                    $display("WARN: skip malformed line, r=%0d", r);
            end else begin
                case_id = case_id + 1;
                a_mat_flat = { $signed(a0[DW-1:0]), $signed(a1[DW-1:0]), $signed(a2[DW-1:0]),
                               $signed(a3[DW-1:0]), $signed(a4[DW-1:0]), $signed(a5[DW-1:0]),
                               $signed(a6[DW-1:0]), $signed(a7[DW-1:0]), $signed(a8[DW-1:0]) };

                b_mat_flat = { $signed(b0[DW-1:0]), $signed(b1[DW-1:0]), $signed(b2[DW-1:0]),
                               $signed(b3[DW-1:0]), $signed(b4[DW-1:0]), $signed(b5[DW-1:0]),
                               $signed(b6[DW-1:0]), $signed(b7[DW-1:0]), $signed(b8[DW-1:0]) };

                pulse_start();

                timeout_cnt = 0;
                while ((done !== 1'b1) && (timeout_cnt < 100)) begin
                    @(negedge clk);
                    timeout_cnt = timeout_cnt + 1;
                end

                if (timeout_cnt >= 100) begin
                    $display("CASE %0d TIMEOUT", case_id);
                end else begin
                    $display("CASE %0d DONE", case_id);
                    $display("GOT = [%0d %0d %0d; %0d %0d %0d; %0d %0d %0d]",
                        c00,c01,c02,c10,c11,c12,c20,c21,c22);
                    $display("EXP = [%0d %0d %0d; %0d %0d %0d; %0d %0d %0d]",
                        e0,e1,e2,e3,e4,e5,e6,e7,e8);

                    if ((c00!==e0)||(c01!==e1)||(c02!==e2)||
                        (c10!==e3)||(c11!==e4)||(c12!==e5)||
                        (c20!==e6)||(c21!==e7)||(c22!==e8)) begin
                        $display("CASE %0d FAIL", case_id);
                        fail_cnt = fail_cnt + 1;
                    end else begin
                        $display("CASE %0d PASS", case_id);
                        pass_cnt = pass_cnt + 1;
                    end
                end

                repeat(4) @(negedge clk);
            end
        end
        $display("==========================================================");
        $display("Systolic Matrix Multiplication Integration Test Summary:");
        $display("  PASS: %0d", pass_cnt);
        $display("  FAIL: %0d", fail_cnt);
        $display("==========================================================");
        $fclose(fd);
        repeat(10) @(negedge clk);
        $finish;
    end
endmodule