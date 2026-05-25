`timescale 1ns/1ps

module result_buffer_3x3 #(
    parameter ACC_WIDTH = 24
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         clear_acc,
    input  wire                         start_capture,
    input  wire                         in_valid_0,
    input  wire                         in_valid_1,
    input  wire                         in_valid_2,
    input  wire signed [ACC_WIDTH-1:0]  in_psum_0,
    input  wire signed [ACC_WIDTH-1:0]  in_psum_1,
    input  wire signed [ACC_WIDTH-1:0]  in_psum_2,

    output reg                          done,
    output reg signed [ACC_WIDTH-1:0]   c00,
    output reg signed [ACC_WIDTH-1:0]   c01,
    output reg signed [ACC_WIDTH-1:0]   c02,
    output reg signed [ACC_WIDTH-1:0]   c10,
    output reg signed [ACC_WIDTH-1:0]   c11,
    output reg signed [ACC_WIDTH-1:0]   c12,
    output reg signed [ACC_WIDTH-1:0]   c20,
    output reg signed [ACC_WIDTH-1:0]   c21,
    output reg signed [ACC_WIDTH-1:0]   c22
);

    reg       active;
    reg [2:0] cap_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active  <= 1'b0;
            cap_cnt <= 3'd0;
            done    <= 1'b0;
            c00     <= {ACC_WIDTH{1'b0}};
            c01     <= {ACC_WIDTH{1'b0}};
            c02     <= {ACC_WIDTH{1'b0}};
            c10     <= {ACC_WIDTH{1'b0}};
            c11     <= {ACC_WIDTH{1'b0}};
            c12     <= {ACC_WIDTH{1'b0}};
            c20     <= {ACC_WIDTH{1'b0}};
            c21     <= {ACC_WIDTH{1'b0}};
            c22     <= {ACC_WIDTH{1'b0}};
        end else if (clear_acc) begin
            active  <= 1'b0;
            cap_cnt <= 3'd0;
            done    <= 1'b0;
            c00     <= {ACC_WIDTH{1'b0}};
            c01     <= {ACC_WIDTH{1'b0}};
            c02     <= {ACC_WIDTH{1'b0}};
            c10     <= {ACC_WIDTH{1'b0}};
            c11     <= {ACC_WIDTH{1'b0}};
            c12     <= {ACC_WIDTH{1'b0}};
            c20     <= {ACC_WIDTH{1'b0}};
            c21     <= {ACC_WIDTH{1'b0}};
            c22     <= {ACC_WIDTH{1'b0}};
        end else begin
            if (start_capture) begin
                active  <= 1'b1;
                cap_cnt <= 3'd0;
                done    <= 1'b0;
            end else if (active) begin
                case (cap_cnt)
                    3'd2: begin
                        if (in_valid_0) begin
                            c00 <= in_psum_0;
                        end
                    end

                    3'd3: begin
                        if (in_valid_0) begin
                            c10 <= in_psum_0;
                        end
                        if (in_valid_1) begin
                            c01 <= in_psum_1;
                        end
                    end

                    3'd4: begin
                        if (in_valid_0) begin
                            c20 <= in_psum_0;
                        end
                        if (in_valid_1) begin
                            c11 <= in_psum_1;
                        end
                        if (in_valid_2) begin
                            c02 <= in_psum_2;
                        end
                    end

                    3'd5: begin
                        if (in_valid_1) begin
                            c21 <= in_psum_1;
                        end
                        if (in_valid_2) begin
                            c12 <= in_psum_2;
                        end
                    end

                    3'd6: begin
                        if (in_valid_2) begin
                            c22 <= in_psum_2;
                        end
                        active <= 1'b0;
                        done   <= 1'b1;
                    end

                    default: begin
                        done <= 1'b0;
                    end
                endcase

                cap_cnt <= cap_cnt + 3'd1;
            end else begin
                done <= 1'b0;
            end
        end
    end

endmodule
