`timescale 1ns/1ps
// ============================================================================
// 阶段三：输出缓冲模块单元测试
// 测试 result_buffer_3x3 模块的结果捕获和映射功能
// ============================================================================
module tb_buffer;
    parameter AW = 24;
    reg                       clk;
    reg                       rst_n;
    reg                       clear_acc;
    reg                       start_capture;
    reg                       in_valid_0, in_valid_1, in_valid_2;
    reg  signed [AW-1:0]      in_psum_0, in_psum_1, in_psum_2;
    wire                      done;
    wire signed [AW-1:0]      c00, c01, c02, c10, c11, c12, c20, c21, c22;
    integer                   pass_cnt;
    integer                   fail_cnt;
    integer                   case_id;
    integer                   cyc;
    result_buffer_3x3 #(AW) u_buf (
        .clk(clk), .rst_n(rst_n), .clear_acc(clear_acc), .start_capture(start_capture),
        .in_valid_0(in_valid_0), .in_valid_1(in_valid_1), .in_valid_2(in_valid_2),
        .in_psum_0(in_psum_0), .in_psum_1(in_psum_1), .in_psum_2(in_psum_2),
        .done(done),
        .c00(c00), .c01(c01), .c02(c02),
        .c10(c10), .c11(c11), .c12(c12),
        .c20(c20), .c21(c21), .c22(c22)
    );
    always #5 clk = ~clk;
    // 任务：在 negedge 设置输入信号
    task set_input;
        input v0, v1, v2;
        input [AW-1:0] p0, p1, p2;
        begin
            @(negedge clk);
            in_valid_0 = v0;
            in_valid_1 = v1;
            in_valid_2 = v2;
            in_psum_0  = p0;
            in_psum_1  = p1;
            in_psum_2  = p2;
        end
    endtask
    // 任务：清除所有输入
    task clear_input;
        begin
            @(negedge clk);
            in_valid_0 = 1'b0;
            in_valid_1 = 1'b0;
            in_valid_2 = 1'b0;
            in_psum_0  = '0;
            in_psum_1  = '0;
            in_psum_2  = '0;
        end
    endtask
    // ---------------------------------------------------------------
    // 主测试流程
    // ---------------------------------------------------------------
    initial begin
        clk           = 1'b0;
        rst_n         = 1'b0;
        clear_acc     = 1'b0;
        start_capture = 1'b0;
        in_valid_0    = 1'b0;
        in_valid_1    = 1'b0;
        in_valid_2    = 1'b0;
        in_psum_0     = '0;
        in_psum_1     = '0;
        in_psum_2     = '0;
        pass_cnt      = 0;
        fail_cnt      = 0;
        case_id       = 0;
        repeat(5) @(negedge clk);
        rst_n = 1'b1;
        repeat(2) @(negedge clk);
        // =============================================================
        // 测试 1: 模拟完整的 3x3 脉动阵列输出时序
        // 模拟矩阵 A=[1 2 3; 4 5 6; 7 8 9] × B=[1 0 0; 0 1 0; 0 0 1]
        // 预期结果 C=A (单位矩阵乘)
        // 按脉动阵列出图时序给 psum：
        //   T2: col0=1 -> c00
        //   T3: col0=4 -> c10, col1=2 -> c01
        //   T4: col0=7 -> c20, col1=5 -> c11, col2=3 -> c02
        //   T5: col1=8 -> c21, col2=6 -> c12
        //   T6: col2=9 -> c22
        // =============================================================
        $display("========== Test 1: Simulated Systolic Output Sequence ==========");
        // 发 start_capture 脉冲
        @(negedge clk);
        start_capture = 1'b1;
        @(negedge clk);
        start_capture = 1'b0;
        // 模拟 cap_cnt 从 0 开始递增
        // cnt=0: (start_capture 刚过)
        // cnt=1: 无有效输出
        clear_input();
        // cnt=2: col0=c00=1
        set_input(1'b1, 1'b0, 1'b0, 24'd1, '0, '0);
        // cnt=3: col0=c10=4, col1=c01=2
        set_input(1'b1, 1'b1, 1'b0, 24'd4, 24'd2, '0);
        // cnt=4: col0=c20=7, col1=c11=5, col2=c02=3
        set_input(1'b1, 1'b1, 1'b1, 24'd7, 24'd5, 24'd3);
        // cnt=5: col1=c21=8, col2=c12=6
        set_input(1'b0, 1'b1, 1'b1, '0, 24'd8, 24'd6);
        // cnt=6: col2=c22=9, done=1
        set_input(1'b0, 1'b0, 1'b1, '0, '0, 24'd9);
        clear_input();
        // 检查 done
        if (done !== 1'b1) begin
            $display("[FAIL] done should be 1 after last capture");
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] done asserted");
            pass_cnt = pass_cnt + 1;
        end
        // 检查结果矩阵
        if (c00 !== 1  || c01 !== 2  || c02 !== 3  ||
            c10 !== 4  || c11 !== 5  || c12 !== 6  ||
            c20 !== 7  || c21 !== 8  || c22 !== 9) begin
            $display("[FAIL] Matrix mismatch:");
            $display("  GOT = [%0d %0d %0d; %0d %0d %0d; %0d %0d %0d]",
                     c00,c01,c02,c10,c11,c12,c20,c21,c22);
            $display("  EXP = [1 2 3; 4 5 6; 7 8 9]");
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] Result matrix correct: [1 2 3; 4 5 6; 7 8 9]");
            pass_cnt = pass_cnt + 1;
        end
        // =============================================================
        // 测试 2: clear_acc 后寄存器清零
        // =============================================================
        $display("========== Test 2: clear_acc Resets Registers ==========");
        @(negedge clk);
        clear_acc = 1'b1;
        @(negedge clk);
        clear_acc = 1'b0;
        if (c00 !== '0 || c01 !== '0 || c02 !== '0 ||
            c10 !== '0 || c11 !== '0 || c12 !== '0 ||
            c20 !== '0 || c21 !== '0 || c22 !== '0) begin
            $display("[FAIL] Registers not cleared after clear_acc");
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] All registers cleared after clear_acc");
            pass_cnt = pass_cnt + 1;
        end
        // =============================================================
        // 测试 3: 第二次捕获 — 不同矩阵值
        // C = [10 20 30; 40 50 60; 70 80 90]
        // =============================================================
        $display("========== Test 3: Second Capture with Different Values ==========");
        @(negedge clk);
        start_capture = 1'b1;
        @(negedge clk);
        start_capture = 1'b0;
        clear_input();
        set_input(1'b1, 1'b0, 1'b0, 24'd10, '0, '0);     // cnt=2: c00
        set_input(1'b1, 1'b1, 1'b0, 24'd40, 24'd20, '0);  // cnt=3: c10,c01
        set_input(1'b1, 1'b1, 1'b1, 24'd70, 24'd50, 24'd30); // cnt=4: c20,c11,c02
        set_input(1'b0, 1'b1, 1'b1, '0, 24'd80, 24'd60);  // cnt=5: c21,c12
        set_input(1'b0, 1'b0, 1'b1, '0, '0, 24'd90);      // cnt=6: c22
        clear_input();
        if (c00 !== 10 || c01 !== 20 || c02 !== 30 ||
            c10 !== 40 || c11 !== 50 || c12 !== 60 ||
            c20 !== 70 || c21 !== 80 || c22 !== 90) begin
            $display("[FAIL] Second capture matrix mismatch");
            $display("  GOT = [%0d %0d %0d; %0d %0d %0d; %0d %0d %0d]",
                     c00,c01,c02,c10,c11,c12,c20,c21,c22);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] Second capture matrix correct");
            pass_cnt = pass_cnt + 1;
        end
        // =============================================================
        // 测试 4: 负数结果
        // =============================================================
        $display("========== Test 4: Negative Results ==========");
        @(negedge clk);
        clear_acc = 1'b1;
        @(negedge clk);
        clear_acc = 1'b0;
        repeat(2) @(negedge clk);
        @(negedge clk);
        start_capture = 1'b1;
        @(negedge clk);
        start_capture = 1'b0;
        clear_input();
        set_input(1'b1, 1'b0, 1'b0, -24'd5, '0, '0);
        set_input(1'b1, 1'b1, 1'b0, -24'd15, -24'd10, '0);
        set_input(1'b1, 1'b1, 1'b1, -24'd25, -24'd20, -24'd15);
        set_input(1'b0, 1'b1, 1'b1, '0, -24'd30, -24'd25);
        set_input(1'b0, 1'b0, 1'b1, '0, '0, -24'd35);
        clear_input();
        if (c00 !== -5  || c01 !== -10 || c02 !== -15 ||
            c10 !== -15 || c11 !== -20 || c12 !== -25 ||
            c20 !== -25 || c21 !== -30 || c22 !== -35) begin
            $display("[FAIL] Negative values mismatch");
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] Negative values captured correctly");
            pass_cnt = pass_cnt + 1;
        end
        // =============================================================
        // 测试总结
        // =============================================================
        repeat(3) @(negedge clk);
        $display("==============================================");
        $display("Output Buffer Unit Test Summary:");
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
