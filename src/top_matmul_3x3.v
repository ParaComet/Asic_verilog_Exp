`timescale 1ns/1ps

module top_matmul_3x3 #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 24
)(
    input  wire                             clk,
    input  wire                             rst_n,
    input  wire                             start,

    input  wire signed [9*DATA_WIDTH-1:0]  a_mat_flat,
    input  wire signed [9*DATA_WIDTH-1:0]  b_mat_flat,
    output wire                             done,

    output wire signed [ACC_WIDTH-1:0]     c00,
    output wire signed [ACC_WIDTH-1:0]     c01,
    output wire signed [ACC_WIDTH-1:0]     c02,
    output wire signed [ACC_WIDTH-1:0]     c10,
    output wire signed [ACC_WIDTH-1:0]     c11,
    output wire signed [ACC_WIDTH-1:0]     c12,
    output wire signed [ACC_WIDTH-1:0]     c20,
    output wire signed [ACC_WIDTH-1:0]     c21,
    output wire signed [ACC_WIDTH-1:0]     c22
);
    wire busy_unused;
    wire clear_acc;
    wire start_capture;
    wire fm_valid_0, fm_valid_1, fm_valid_2;
    wire signed [DATA_WIDTH-1:0] fm_left_0, fm_left_1, fm_left_2;
    wire wt_valid_in;
    wire signed [DATA_WIDTH-1:0] wt_top_0, wt_top_1, wt_top_2;
    wire out_valid_0, out_valid_1, out_valid_2;
    wire signed [ACC_WIDTH-1:0] out_psum_0, out_psum_1, out_psum_2;

    input_ctrl_3x3 #(
        .DW(DATA_WIDTH)
    ) u_input_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .a_mat_flat(a_mat_flat),
        .b_mat_flat(b_mat_flat),
        .busy(busy_unused),
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

    systolic_array_3x3 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_systolic_array (
        .clk(clk),
        .rst_n(rst_n),
        .clear_acc(clear_acc),
        .fm_valid_0(fm_valid_0),
        .fm_valid_1(fm_valid_1),
        .fm_valid_2(fm_valid_2),
        .fm_left_0(fm_left_0),
        .fm_left_1(fm_left_1),
        .fm_left_2(fm_left_2),
        .wt_valid_in(wt_valid_in),
        .wt_top_0(wt_top_0),
        .wt_top_1(wt_top_1),
        .wt_top_2(wt_top_2),
        .out_valid_0(out_valid_0),
        .out_valid_1(out_valid_1),
        .out_valid_2(out_valid_2),
        .out_psum_0(out_psum_0),
        .out_psum_1(out_psum_1),
        .out_psum_2(out_psum_2)
    );

    result_buffer_3x3 #(
        .ACC_WIDTH(ACC_WIDTH)
    ) u_result_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .clear_acc(clear_acc),
        .start_capture(start_capture),
        .in_valid_0(out_valid_0),
        .in_valid_1(out_valid_1),
        .in_valid_2(out_valid_2),
        .in_psum_0(out_psum_0),
        .in_psum_1(out_psum_1),
        .in_psum_2(out_psum_2),
        .done(done),
        .c00(c00),
        .c01(c01),
        .c02(c02),
        .c10(c10),
        .c11(c11),
        .c12(c12),
        .c20(c20),
        .c21(c21),
        .c22(c22)
    );
endmodule 
