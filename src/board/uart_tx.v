`timescale 1ns / 1ps

module uart_tx #(
    parameter integer CLK_HZ = 100000000,
    parameter integer BAUD = 115200
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data_i,
    input  wire       data_valid_i,
    output reg        tx_o,
    output reg        busy_o
);

    localparam integer CLKS_PER_BIT = CLK_HZ / BAUD;

    localparam [1:0] STATE_IDLE  = 2'd0;
    localparam [1:0] STATE_START = 2'd1;
    localparam [1:0] STATE_DATA  = 2'd2;
    localparam [1:0] STATE_STOP  = 2'd3;

    reg [1:0]  state;
    reg [31:0] baud_count;
    reg [2:0]  bit_index;
    reg [7:0]  shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_o <= 1'b1;
            busy_o <= 1'b0;
            state <= STATE_IDLE;
            baud_count <= 32'd0;
            bit_index <= 3'd0;
            shift_reg <= 8'h00;
        end else begin
            case (state)
                STATE_IDLE: begin
                    tx_o <= 1'b1;
                    busy_o <= 1'b0;
                    baud_count <= 32'd0;
                    if (data_valid_i) begin
                        shift_reg <= data_i;
                        bit_index <= 3'd0;
                        tx_o <= 1'b0;
                        busy_o <= 1'b1;
                        state <= STATE_START;
                    end
                end

                STATE_START: begin
                    if (baud_count == CLKS_PER_BIT - 1) begin
                        baud_count <= 32'd0;
                        tx_o <= shift_reg[0];
                        state <= STATE_DATA;
                    end else begin
                        baud_count <= baud_count + 1'b1;
                    end
                end

                STATE_DATA: begin
                    if (baud_count == CLKS_PER_BIT - 1) begin
                        baud_count <= 32'd0;
                        if (bit_index == 3'd7) begin
                            tx_o <= 1'b1;
                            state <= STATE_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                            tx_o <= shift_reg[bit_index + 1'b1];
                        end
                    end else begin
                        baud_count <= baud_count + 1'b1;
                    end
                end

                STATE_STOP: begin
                    if (baud_count == CLKS_PER_BIT - 1) begin
                        baud_count <= 32'd0;
                        busy_o <= 1'b0;
                        state <= STATE_IDLE;
                    end else begin
                        baud_count <= baud_count + 1'b1;
                    end
                end

                default: begin
                    tx_o <= 1'b1;
                    busy_o <= 1'b0;
                    state <= STATE_IDLE;
                    baud_count <= 32'd0;
                end
            endcase
        end
    end

endmodule
