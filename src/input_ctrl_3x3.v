`timescale 1ns/1ps

module input_ctrl_3x3 #(
    parameter DW = 8
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    start,
    input  wire signed [9*DW-1:0]  a_mat_flat,
    input  wire signed [9*DW-1:0]  b_mat_flat,

    output reg                     busy,
    output reg                     clear_acc,
    output reg                     start_capture,
    output reg                     wt_valid_in,
    output reg signed [DW-1:0]     wt_top_0,
    output reg signed [DW-1:0]     wt_top_1,
    output reg signed [DW-1:0]     wt_top_2,

    output reg                     fm_valid_0,
    output reg                     fm_valid_1,
    output reg                     fm_valid_2,
    output reg signed [DW-1:0]     fm_left_0,
    output reg signed [DW-1:0]     fm_left_1,
    output reg signed [DW-1:0]     fm_left_2
);
    localparam S_IDLE    = 2'b00;
    localparam S_PRELOAD = 2'b01;
    localparam S_COMPUTE = 2'b10;

    reg [1:0] state_cur;
    reg [1:0] state_next;
    reg [2:0] cnt;
    reg [2:0] cnt_next;

    wire signed [DW-1:0] a00 = a_mat_flat[9*DW-1 -: DW];
    wire signed [DW-1:0] a01 = a_mat_flat[8*DW-1 -: DW];
    wire signed [DW-1:0] a02 = a_mat_flat[7*DW-1 -: DW];
    wire signed [DW-1:0] a10 = a_mat_flat[6*DW-1 -: DW];
    wire signed [DW-1:0] a11 = a_mat_flat[5*DW-1 -: DW];
    wire signed [DW-1:0] a12 = a_mat_flat[4*DW-1 -: DW];
    wire signed [DW-1:0] a20 = a_mat_flat[3*DW-1 -: DW];
    wire signed [DW-1:0] a21 = a_mat_flat[2*DW-1 -: DW];
    wire signed [DW-1:0] a22 = a_mat_flat[1*DW-1 -: DW];

    wire signed [DW-1:0] b00 = b_mat_flat[9*DW-1 -: DW];
    wire signed [DW-1:0] b01 = b_mat_flat[8*DW-1 -: DW];
    wire signed [DW-1:0] b02 = b_mat_flat[7*DW-1 -: DW];
    wire signed [DW-1:0] b10 = b_mat_flat[6*DW-1 -: DW];
    wire signed [DW-1:0] b11 = b_mat_flat[5*DW-1 -: DW];
    wire signed [DW-1:0] b12 = b_mat_flat[4*DW-1 -: DW];
    wire signed [DW-1:0] b20 = b_mat_flat[3*DW-1 -: DW];
    wire signed [DW-1:0] b21 = b_mat_flat[2*DW-1 -: DW];
    wire signed [DW-1:0] b22 = b_mat_flat[1*DW-1 -: DW];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_cur <= S_IDLE;
            cnt       <= 3'd0;
        end else begin
            state_cur <= state_next;
            cnt       <= cnt_next;
        end
    end

    always @(*) begin
        state_next = state_cur;
        cnt_next   = cnt;

        case (state_cur)
            S_IDLE: begin
                cnt_next = 3'd0;
                if (start) begin
                    state_next = S_PRELOAD;
                end
            end

            S_PRELOAD: begin
                if (cnt == 3'd2) begin
                    cnt_next   = 3'd0;
                    state_next = S_COMPUTE;
                end else begin
                    cnt_next = cnt + 3'd1;
                end
            end

            S_COMPUTE: begin
                if (cnt == 3'd6) begin
                    cnt_next   = 3'd0;
                    state_next = S_IDLE;
                end else begin
                    cnt_next = cnt + 3'd1;
                end
            end

            default: begin
                state_next = S_IDLE;
                cnt_next   = 3'd0;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy          <= 1'b0;
            clear_acc     <= 1'b0;
            start_capture <= 1'b0;
            wt_valid_in   <= 1'b0;
            wt_top_0      <= {DW{1'b0}};
            wt_top_1      <= {DW{1'b0}};
            wt_top_2      <= {DW{1'b0}};
            fm_valid_0    <= 1'b0;
            fm_valid_1    <= 1'b0;
            fm_valid_2    <= 1'b0;
            fm_left_0     <= {DW{1'b0}};
            fm_left_1     <= {DW{1'b0}};
            fm_left_2     <= {DW{1'b0}};
        end else begin
            busy          <= (state_next != S_IDLE);
            clear_acc     <= 1'b0;
            start_capture <= 1'b0;
            wt_valid_in   <= 1'b0;
            wt_top_0      <= {DW{1'b0}};
            wt_top_1      <= {DW{1'b0}};
            wt_top_2      <= {DW{1'b0}};
            fm_valid_0    <= 1'b0;
            fm_valid_1    <= 1'b0;
            fm_valid_2    <= 1'b0;
            fm_left_0     <= {DW{1'b0}};
            fm_left_1     <= {DW{1'b0}};
            fm_left_2     <= {DW{1'b0}};

            case (state_cur)
                S_IDLE: begin
                    if (start) begin
                        clear_acc <= 1'b1;
                    end
                end

                S_PRELOAD: begin
                    wt_valid_in <= 1'b1;

                    case (cnt)
                        3'd0: begin
                            wt_top_0 <= b00;
                            wt_top_1 <= b01;
                            wt_top_2 <= b02;
                        end
                        3'd1: begin
                            wt_top_0 <= b10;
                            wt_top_1 <= b11;
                            wt_top_2 <= b12;
                        end
                        default: begin
                            wt_top_0 <= b20;
                            wt_top_1 <= b21;
                            wt_top_2 <= b22;
                        end
                    endcase
                end

                S_COMPUTE: begin
                    case (cnt)
                        3'd0: begin
                            start_capture <= 1'b1;
                            fm_valid_0    <= 1'b1;
                            fm_left_0     <= a02;
                        end
                        3'd1: begin
                            fm_valid_0 <= 1'b1;
                            fm_valid_1 <= 1'b1;
                            fm_left_0  <= a12;
                            fm_left_1  <= a01;
                        end
                        3'd2: begin
                            fm_valid_0 <= 1'b1;
                            fm_valid_1 <= 1'b1;
                            fm_valid_2 <= 1'b1;
                            fm_left_0  <= a22;
                            fm_left_1  <= a11;
                            fm_left_2  <= a00;
                        end
                        3'd3: begin
                            fm_valid_1 <= 1'b1;
                            fm_valid_2 <= 1'b1;
                            fm_left_1  <= a21;
                            fm_left_2  <= a10;
                        end
                        3'd4: begin
                            fm_valid_2 <= 1'b1;
                            fm_left_2  <= a20;
                        end
                        default: begin
                        end
                    endcase
                end

                default: begin
                end
            endcase
        end
    end
endmodule
