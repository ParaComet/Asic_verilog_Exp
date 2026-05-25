`timescale 1ns/1ps

module pe3_pipe #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 24
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         clear_acc,

    input  wire                         fm_valid_in,
    input  wire                         wt_valid_in,
    input  wire                         psum_valid_in,

    input  wire signed [DATA_WIDTH-1:0] fm_in,
    input  wire signed [DATA_WIDTH-1:0] weight_in,
    input  wire signed [ACC_WIDTH-1:0]  psum_in,

    output reg                          fm_valid_out,
    output wire                         wt_valid_out,
    output reg                          psum_valid_out,

    output reg signed [DATA_WIDTH-1:0]  fm_out,
    output wire signed [DATA_WIDTH-1:0]  weight_out,
    output reg signed [ACC_WIDTH-1:0]   psum_out,
    output reg                          overflow,

    output wire signed [DATA_WIDTH-1:0] sr_dbg,
    output wire signed [DATA_WIDTH-1:0] wr_dbg,
    output wire signed [DATA_WIDTH-1:0] fmr_dbg
);
    reg signed [DATA_WIDTH-1:0] shift_reg;
    reg signed [DATA_WIDTH-1:0] weight_reg;
    reg signed [DATA_WIDTH-1:0] fmr_reg;
    reg                         shift_reg_valid;

    wire                         mac_valid;
    wire signed [ACC_WIDTH-1:0]  mac_psum_next;
    wire                         mac_overflow;
    wire signed [DATA_WIDTH-1:0] mac_weight;
    assign mac_valid = fm_valid_in && psum_valid_in;

    assign sr_dbg  = shift_reg;
    assign wr_dbg  = weight_reg;
    assign fmr_dbg = fmr_reg;
    assign weight_out = shift_reg;
    assign wt_valid_out = wt_valid_in && shift_reg_valid;
    assign mac_weight = mac_valid ? shift_reg : weight_reg;
    pe3_pipe_mac #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_mac (
        .fm(fm_in),
        .weight(mac_weight),
        .psum_in(psum_in),
        .psum_next(mac_psum_next),
        .overflow(mac_overflow)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg      <= {DATA_WIDTH{1'b0}};
            weight_reg     <= {DATA_WIDTH{1'b0}};
            fmr_reg        <= {DATA_WIDTH{1'b0}};
            shift_reg_valid <= 1'b0;
            fm_valid_out   <= 1'b0;
        
            psum_valid_out <= 1'b0;
            fm_out         <= {DATA_WIDTH{1'b0}};
        
            psum_out       <= {ACC_WIDTH{1'b0}};
            overflow       <= 1'b0;
        end else if (clear_acc) begin
            fm_valid_out   <= 1'b0;
            psum_valid_out <= 1'b0;
            psum_out       <= {ACC_WIDTH{1'b0}};
            overflow       <= 1'b0;
            shift_reg_valid <= 1'b0;
        end else begin
            fm_valid_out   <= fm_valid_in;
            psum_valid_out <= mac_valid;

            if (wt_valid_in) begin
                shift_reg  <= weight_in;
                shift_reg_valid <= 1'b1;
            end else begin
                shift_reg_valid <= 1'b0;
            end

            if (fm_valid_in) begin
                fmr_reg <= fm_in;
                fm_out  <= fm_in;
            end

            if (mac_valid) begin
                weight_reg <= shift_reg;
                psum_out   <= mac_psum_next;
                overflow   <= overflow | mac_overflow;
            end
        end
    end
endmodule
