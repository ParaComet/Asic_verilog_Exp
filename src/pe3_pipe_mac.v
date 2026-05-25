`timescale 1ns/1ps

module pe3_pipe_mac #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 24
)(
    input  wire signed [DATA_WIDTH-1:0] fm,
    input  wire signed [DATA_WIDTH-1:0] weight,
    input  wire signed [ACC_WIDTH-1:0]  psum_in,

    output wire signed [ACC_WIDTH-1:0]  psum_next,
    output wire                         overflow
);
    localparam PRODUCT_WIDTH = 2 * DATA_WIDTH;

    wire signed [PRODUCT_WIDTH-1:0] product;
    wire signed [ACC_WIDTH-1:0]     product_ext;

    assign product     = fm * weight;
    assign product_ext = {{(ACC_WIDTH-PRODUCT_WIDTH){product[PRODUCT_WIDTH-1]}}, product}; // 进行符号扩展
    assign psum_next   = psum_in + product_ext;

    assign overflow = (psum_in[ACC_WIDTH-1] == product_ext[ACC_WIDTH-1]) &&
                      (psum_next[ACC_WIDTH-1] != psum_in[ACC_WIDTH-1]);
endmodule
