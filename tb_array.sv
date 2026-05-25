`timescale 1ns/1ps
// ============================================================================
// 阶段四：3x3 脉动阵列集成测试
// 测试 systolic_array_3x3 模块（9个PE互联）
// 使用与顶层一致的权重预加载、A 波前输入和输出捕获节拍，验证矩阵乘法结果。
// ============================================================================
module tb_array;
    parameter DW = 8;
    parameter AW = 24;

    reg                       clk;
    reg                       rst_n;
    reg                       clear_acc;
    reg                       start_capture;
    reg                       fm_valid_0, fm_valid_1, fm_valid_2;
    reg  signed [DW-1:0]      fm_left_0, fm_left_1, fm_left_2;
    reg                       wt_valid_in;
    reg  signed [DW-1:0]      wt_top_0, wt_top_1, wt_top_2;
    wire                      out_valid_0, out_valid_1, out_valid_2;
    wire signed [AW-1:0]      out_psum_0, out_psum_1, out_psum_2;
    wire                      done;
    wire signed [AW-1:0]      c00, c01, c02, c10, c11, c12, c20, c21, c22;

    integer                   pass_cnt, fail_cnt, case_id;

    systolic_array_3x3 #(DW, AW) u_array (
        .clk(clk), .rst_n(rst_n), .clear_acc(clear_acc),
        .fm_valid_0(fm_valid_0), .fm_valid_1(fm_valid_1), .fm_valid_2(fm_valid_2),
        .fm_left_0(fm_left_0), .fm_left_1(fm_left_1), .fm_left_2(fm_left_2),
        .wt_valid_in(wt_valid_in), .wt_top_0(wt_top_0), .wt_top_1(wt_top_1), .wt_top_2(wt_top_2),
        .out_valid_0(out_valid_0), .out_valid_1(out_valid_1), .out_valid_2(out_valid_2),
        .out_psum_0(out_psum_0), .out_psum_1(out_psum_1), .out_psum_2(out_psum_2)
    );

    result_buffer_3x3 #(AW) u_capture (
        .clk(clk), .rst_n(rst_n), .clear_acc(clear_acc), .start_capture(start_capture),
        .in_valid_0(out_valid_0), .in_valid_1(out_valid_1), .in_valid_2(out_valid_2),
        .in_psum_0(out_psum_0), .in_psum_1(out_psum_1), .in_psum_2(out_psum_2),
        .done(done),
        .c00(c00), .c01(c01), .c02(c02),
        .c10(c10), .c11(c11), .c12(c12),
        .c20(c20), .c21(c21), .c22(c22)
    );

    always #5 clk = ~clk;

    task drive_array_input;
        input fv0, fv1, fv2;
        input signed [DW-1:0] fl0, fl1, fl2;
        input wtv;
        input signed [DW-1:0] wt0, wt1, wt2;
        input cap;
        begin
            @(negedge clk);
            fm_valid_0   = fv0; fm_valid_1 = fv1; fm_valid_2 = fv2;
            fm_left_0    = fl0; fm_left_1  = fl1; fm_left_2  = fl2;
            wt_valid_in  = wtv;
            wt_top_0     = wt0; wt_top_1   = wt1; wt_top_2   = wt2;
            start_capture = cap;
        end
    endtask

    task idle_cycle;
        begin
            drive_array_input(1'b0, 1'b0, 1'b0, '0, '0, '0, 1'b0, '0, '0, '0, 1'b0);
        end
    endtask

    task run_matmul_case;
        input string desc;
        input signed [DW-1:0] A00, A01, A02, A10, A11, A12, A20, A21, A22;
        input signed [DW-1:0] B00, B01, B02, B10, B11, B12, B20, B21, B22;
        input signed [AW-1:0] E00, E01, E02, E10, E11, E12, E20, E21, E22;
        integer done_seen;
        integer i;
        begin
            case_id = case_id + 1;
            done_seen = 0;

            @(negedge clk);
            clear_acc = 1'b1;
            start_capture = 1'b0;
            @(negedge clk);
            clear_acc = 1'b0;

            // B 按行从顶部输入。经过 SR 下移后，计算开始时每列自上而下
            // 为 B2j/B1j/B0j，与 PPT 中的权重固定阵列状态一致。
            drive_array_input(1'b0, 1'b0, 1'b0, '0, '0, '0, 1'b1, B00, B01, B02, 1'b0);
            drive_array_input(1'b0, 1'b0, 1'b0, '0, '0, '0, 1'b1, B10, B11, B12, 1'b0);
            drive_array_input(1'b0, 1'b0, 1'b0, '0, '0, '0, 1'b1, B20, B21, B22, 1'b0);

            // A 以列反向的对角线波前输入，同时启动输出捕获。
            drive_array_input(1'b1, 1'b0, 1'b0, A02, '0, '0, 1'b0, '0, '0, '0, 1'b1);
            drive_array_input(1'b1, 1'b1, 1'b0, A12, A01, '0, 1'b0, '0, '0, '0, 1'b0);
            drive_array_input(1'b1, 1'b1, 1'b1, A22, A11, A00, 1'b0, '0, '0, '0, 1'b0);
            drive_array_input(1'b0, 1'b1, 1'b1, '0, A21, A10, 1'b0, '0, '0, '0, 1'b0);
            drive_array_input(1'b0, 1'b0, 1'b1, '0, '0, A20, 1'b0, '0, '0, '0, 1'b0);

            for (i = 0; i < 8; i = i + 1) begin
                idle_cycle();
                if (done)
                    done_seen = 1;
            end

            if (!done_seen) begin
                $display("[FAIL] Case %0d (%0s): done was not observed", case_id, desc);
                fail_cnt = fail_cnt + 1;
            end else if (c00 !== E00 || c01 !== E01 || c02 !== E02 ||
                         c10 !== E10 || c11 !== E11 || c12 !== E12 ||
                         c20 !== E20 || c21 !== E21 || c22 !== E22) begin
                $display("[FAIL] Case %0d (%0s): matrix mismatch", case_id, desc);
                $display("  GOT = [%0d %0d %0d; %0d %0d %0d; %0d %0d %0d]",
                         c00,c01,c02,c10,c11,c12,c20,c21,c22);
                $display("  EXP = [%0d %0d %0d; %0d %0d %0d; %0d %0d %0d]",
                         E00,E01,E02,E10,E11,E12,E20,E21,E22);
                fail_cnt = fail_cnt + 1;
            end else begin
                $display("[PASS] Case %0d (%0s): C=[%0d %0d %0d; %0d %0d %0d; %0d %0d %0d]",
                         case_id, desc, c00,c01,c02,c10,c11,c12,c20,c21,c22);
                pass_cnt = pass_cnt + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        clear_acc = 1'b0;
        start_capture = 1'b0;
        fm_valid_0 = 1'b0; fm_valid_1 = 1'b0; fm_valid_2 = 1'b0;
        fm_left_0 = '0; fm_left_1 = '0; fm_left_2 = '0;
        wt_valid_in = 1'b0;
        wt_top_0 = '0; wt_top_1 = '0; wt_top_2 = '0;
        pass_cnt = 0;
        fail_cnt = 0;
        case_id = 0;

        repeat(5) @(negedge clk);
        rst_n = 1'b1;
        repeat(2) @(negedge clk);

        $display("========== Systolic Array Matrix Tests ==========");
        run_matmul_case("Identity Matrix",
            8'sd1,8'sd0,8'sd0, 8'sd0,8'sd1,8'sd0, 8'sd0,8'sd0,8'sd1,
            8'sd1,8'sd0,8'sd0, 8'sd0,8'sd1,8'sd0, 8'sd0,8'sd0,8'sd1,
            24'sd1,24'sd0,24'sd0, 24'sd0,24'sd1,24'sd0, 24'sd0,24'sd0,24'sd1);

        run_matmul_case("All-2 x All-3",
            8'sd2,8'sd2,8'sd2, 8'sd2,8'sd2,8'sd2, 8'sd2,8'sd2,8'sd2,
            8'sd3,8'sd3,8'sd3, 8'sd3,8'sd3,8'sd3, 8'sd3,8'sd3,8'sd3,
            24'sd18,24'sd18,24'sd18, 24'sd18,24'sd18,24'sd18, 24'sd18,24'sd18,24'sd18);

        run_matmul_case("A=[1..9], B=[2,1,0;1,2,1;0,1,2]",
            8'sd1,8'sd2,8'sd3, 8'sd4,8'sd5,8'sd6, 8'sd7,8'sd8,8'sd9,
            8'sd2,8'sd1,8'sd0, 8'sd1,8'sd2,8'sd1, 8'sd0,8'sd1,8'sd2,
            24'sd4,24'sd8,24'sd8, 24'sd13,24'sd20,24'sd17, 24'sd22,24'sd32,24'sd26);

        run_matmul_case("Negative Values",
            8'sd1,8'sd0,-8'sd2, 8'sd3,-8'sd1,8'sd0, 8'sd0,8'sd2,-8'sd3,
            8'sd2,8'sd1,8'sd0, -8'sd1,8'sd0,8'sd2, 8'sd0,8'sd1,-8'sd1,
            24'sd2,-24'sd1,24'sd2, 24'sd7,24'sd3,-24'sd2, -24'sd2,-24'sd3,24'sd7);

        repeat(3) @(negedge clk);
        $display("==============================================");
        $display("Systolic Array Integration Test Summary:");
        $display("  PASS: %0d", pass_cnt);
        $display("  FAIL: %0d", fail_cnt);
        $display("==============================================");
        if (fail_cnt > 0)
            $display("SOME TESTS FAILED!");
        else
            $display("ALL TESTS PASSED!");
        $finish;
    end
endmodule
