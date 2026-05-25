`timescale 1ns/1ps

module systolic_array_3x3 #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 24
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         clear_acc,

    input  wire                         fm_valid_0,
    input  wire                         fm_valid_1,
    input  wire                         fm_valid_2,
    input  wire signed [DATA_WIDTH-1:0] fm_left_0,
    input  wire signed [DATA_WIDTH-1:0] fm_left_1,
    input  wire signed [DATA_WIDTH-1:0] fm_left_2,

    input  wire                         wt_valid_in,
    input  wire signed [DATA_WIDTH-1:0] wt_top_0,
    input  wire signed [DATA_WIDTH-1:0] wt_top_1,
    input  wire signed [DATA_WIDTH-1:0] wt_top_2,

    output wire                         out_valid_0,
    output wire                         out_valid_1,
    output wire                         out_valid_2,
    output wire signed [ACC_WIDTH-1:0]  out_psum_0,
    output wire signed [ACC_WIDTH-1:0]  out_psum_1,
    output wire signed [ACC_WIDTH-1:0]  out_psum_2
);
    wire signed [ACC_WIDTH-1:0] zero_psum;
    assign zero_psum = {ACC_WIDTH{1'b0}};

    wire psum_valid_00, psum_valid_01, psum_valid_02;
    wire psum_valid_10, psum_valid_11, psum_valid_12;
    wire psum_valid_20, psum_valid_21, psum_valid_22;

    wire fm_valid_00, fm_valid_01, fm_valid_02;
    wire fm_valid_10, fm_valid_11, fm_valid_12;
    wire fm_valid_20, fm_valid_21, fm_valid_22;

    wire signed [DATA_WIDTH-1:0] fm_out_00, fm_out_01, fm_out_02;
    wire signed [DATA_WIDTH-1:0] fm_out_10, fm_out_11, fm_out_12;
    wire signed [DATA_WIDTH-1:0] fm_out_20, fm_out_21, fm_out_22;

    wire signed [ACC_WIDTH-1:0] psum_out_00, psum_out_01, psum_out_02;
    wire signed [ACC_WIDTH-1:0] psum_out_10, psum_out_11, psum_out_12;
    wire signed [ACC_WIDTH-1:0] psum_out_20, psum_out_21, psum_out_22;

    wire wt_valid_00, wt_valid_01, wt_valid_02;
    wire wt_valid_10, wt_valid_11, wt_valid_12;
    wire wt_valid_20, wt_valid_21, wt_valid_22;

    wire signed [DATA_WIDTH-1:0] wt_out_00, wt_out_01, wt_out_02;
    wire signed [DATA_WIDTH-1:0] wt_out_10, wt_out_11, wt_out_12;
    wire signed [DATA_WIDTH-1:0] wt_out_20, wt_out_21, wt_out_22;

    pe3_pipe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) pe00 (
        .clk(clk),
        .rst_n(rst_n),
        .clear_acc(clear_acc),
        .fm_valid_in(fm_valid_0),
        .wt_valid_in(wt_valid_in),
        .psum_valid_in(1'b1),
        .fm_in(fm_left_0),
        .weight_in(wt_top_0),
        .psum_in(zero_psum),
        .fm_valid_out(fm_valid_00),
        .wt_valid_out(wt_valid_00),
        .psum_valid_out(psum_valid_00),
        .fm_out(fm_out_00),
        .weight_out(wt_out_00),
        .psum_out(psum_out_00),
        .overflow()
    );

    pe3_pipe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) pe01 (
        .clk(clk),
        .rst_n(rst_n),
        .clear_acc(clear_acc),
        .fm_valid_in(fm_valid_00),
        .wt_valid_in(wt_valid_in),
        .psum_valid_in(1'b1),
        .fm_in(fm_out_00),
        .weight_in(wt_top_1),
        .psum_in(zero_psum),
        .fm_valid_out(fm_valid_01),
        .wt_valid_out(wt_valid_01),
        .psum_valid_out(psum_valid_01),
        .fm_out(fm_out_01),
        .weight_out(wt_out_01),
        .psum_out(psum_out_01),
        .overflow()
    );

    pe3_pipe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) pe02 (
        .clk(clk),
        .rst_n(rst_n),
        .clear_acc(clear_acc),
        .fm_valid_in(fm_valid_01),
        .wt_valid_in(wt_valid_in),
        .psum_valid_in(1'b1),
        .fm_in(fm_out_01),
        .weight_in(wt_top_2),
        .psum_in(zero_psum),
        .fm_valid_out(fm_valid_02),
        .wt_valid_out(wt_valid_02),
        .psum_valid_out(psum_valid_02),
        .fm_out(fm_out_02),
        .weight_out(wt_out_02),
        .psum_out(psum_out_02),
        .overflow()
    );

    pe3_pipe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) pe10 (
        .clk(clk),
        .rst_n(rst_n),
        .clear_acc(clear_acc),
        .fm_valid_in(fm_valid_1),
        .wt_valid_in(wt_valid_00),
        .psum_valid_in(psum_valid_00),
        .fm_in(fm_left_1),
        .weight_in(wt_out_00),
        .psum_in(psum_out_00),
        .fm_valid_out(fm_valid_10),
        .wt_valid_out(wt_valid_10),
        .psum_valid_out(psum_valid_10),
        .fm_out(fm_out_10),
        .weight_out(wt_out_10),
        .psum_out(psum_out_10),
        .overflow()
    );

    pe3_pipe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) pe11 (
        .clk(clk),
        .rst_n(rst_n),
        .clear_acc(clear_acc),
        .fm_valid_in(fm_valid_10),
        .wt_valid_in(wt_valid_01),
        .psum_valid_in(psum_valid_01),
        .fm_in(fm_out_10),
        .weight_in(wt_out_01),
        .psum_in(psum_out_01),
        .fm_valid_out(fm_valid_11),
        .wt_valid_out(wt_valid_11),
        .psum_valid_out(psum_valid_11),
        .fm_out(fm_out_11),
        .weight_out(wt_out_11),
        .psum_out(psum_out_11),
        .overflow()
    );

    pe3_pipe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) pe12 (
        .clk(clk),
        .rst_n(rst_n),
        .clear_acc(clear_acc),
        .fm_valid_in(fm_valid_11),
        .wt_valid_in(wt_valid_02),
        .psum_valid_in(psum_valid_02),
        .fm_in(fm_out_11),
        .weight_in(wt_out_02),
        .psum_in(psum_out_02),
        .fm_valid_out(fm_valid_12),
        .wt_valid_out(wt_valid_12),
        .psum_valid_out(psum_valid_12),
        .fm_out(fm_out_12),
        .weight_out(wt_out_12),
        .psum_out(psum_out_12),
        .overflow()
    );

    pe3_pipe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) pe20 (
        .clk(clk),
        .rst_n(rst_n),
        .clear_acc(clear_acc),
        .fm_valid_in(fm_valid_2),
        .wt_valid_in(wt_valid_10),
        .psum_valid_in(psum_valid_10),
        .fm_in(fm_left_2),
        .weight_in(wt_out_10),
        .psum_in(psum_out_10),
        .fm_valid_out(fm_valid_20),
        .wt_valid_out(wt_valid_20),
        .psum_valid_out(psum_valid_20),
        .fm_out(fm_out_20),
        .weight_out(wt_out_20),
        .psum_out(psum_out_20),
        .overflow()
    );

    pe3_pipe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) pe21 (
        .clk(clk),
        .rst_n(rst_n),
        .clear_acc(clear_acc),
        .fm_valid_in(fm_valid_20),
        .wt_valid_in(wt_valid_11),
        .psum_valid_in(psum_valid_11),
        .fm_in(fm_out_20),
        .weight_in(wt_out_11),
        .psum_in(psum_out_11),
        .fm_valid_out(fm_valid_21),
        .wt_valid_out(wt_valid_21),
        .psum_valid_out(psum_valid_21),
        .fm_out(fm_out_21),
        .weight_out(wt_out_21),
        .psum_out(psum_out_21),
        .overflow()
    );

    pe3_pipe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) pe22 (
        .clk(clk),
        .rst_n(rst_n),
        .clear_acc(clear_acc),
        .fm_valid_in(fm_valid_21),
        .wt_valid_in(wt_valid_12),
        .psum_valid_in(psum_valid_12),
        .fm_in(fm_out_21),
        .weight_in(wt_out_12),
        .psum_in(psum_out_12),
        .fm_valid_out(fm_valid_22),
        .wt_valid_out(wt_valid_22),
        .psum_valid_out(psum_valid_22),
        .fm_out(fm_out_22),
        .weight_out(wt_out_22),
        .psum_out(psum_out_22),
        .overflow()
    );

    assign out_valid_0 = psum_valid_20;
    assign out_valid_1 = psum_valid_21;
    assign out_valid_2 = psum_valid_22;
    assign out_psum_0  = psum_out_20;
    assign out_psum_1  = psum_out_21;
    assign out_psum_2  = psum_out_22;

endmodule
