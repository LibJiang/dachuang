`timescale 1ns / 1ps

module uart_rx #(
    parameter integer CLK_HZ = 100000000,
    parameter integer BAUD = 115200
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx_i,
    output reg  [7:0] data_o,
    output reg        data_valid_o,
    output reg        framing_error_o
);

    localparam integer CLKS_PER_BIT = CLK_HZ / BAUD;
    localparam integer HALF_BIT_TICKS = CLKS_PER_BIT / 2;

    localparam [1:0] STATE_IDLE  = 2'd0;
    localparam [1:0] STATE_START = 2'd1;
    localparam [1:0] STATE_DATA  = 2'd2;
    localparam [1:0] STATE_STOP  = 2'd3;

    reg        rx_meta;
    reg        rx_sync;
    reg [1:0]  state;
    reg [31:0] baud_count;
    reg [2:0]  bit_index;
    reg [7:0]  shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx_i;
            rx_sync <= rx_meta;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_o <= 8'h00;
            data_valid_o <= 1'b0;
            framing_error_o <= 1'b0;
            state <= STATE_IDLE;
            baud_count <= 32'd0;
            bit_index <= 3'd0;
            shift_reg <= 8'h00;
        end else begin
            data_valid_o <= 1'b0;
            framing_error_o <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    baud_count <= 32'd0;
                    if (!rx_sync)
                        state <= STATE_START;
                end

                STATE_START: begin
                    if (baud_count == HALF_BIT_TICKS - 1) begin
                        baud_count <= 32'd0;
                        if (!rx_sync) begin
                            bit_index <= 3'd0;
                            state <= STATE_DATA;
                        end else begin
                            state <= STATE_IDLE;
                        end
                    end else begin
                        baud_count <= baud_count + 1'b1;
                    end
                end

                STATE_DATA: begin
                    if (baud_count == CLKS_PER_BIT - 1) begin
                        baud_count <= 32'd0;
                        shift_reg[bit_index] <= rx_sync;
                        if (bit_index == 3'd7)
                            state <= STATE_STOP;
                        else
                            bit_index <= bit_index + 1'b1;
                    end else begin
                        baud_count <= baud_count + 1'b1;
                    end
                end

                STATE_STOP: begin
                    if (baud_count == CLKS_PER_BIT - 1) begin
                        baud_count <= 32'd0;
                        if (rx_sync) begin
                            data_o <= shift_reg;
                            data_valid_o <= 1'b1;
                        end else begin
                            framing_error_o <= 1'b1;
                        end
                        state <= STATE_IDLE;
                    end else begin
                        baud_count <= baud_count + 1'b1;
                    end
                end

                default: begin
                    state <= STATE_IDLE;
                    baud_count <= 32'd0;
                end
            endcase
        end
    end

endmodule
