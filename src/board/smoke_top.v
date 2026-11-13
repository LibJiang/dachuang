`timescale 1ns / 1ps

module smoke_top #(
    parameter integer CLK_HZ = 100000000,
    parameter integer BAUD = 115200,
    parameter integer COUNTER_WIDTH = 32,
    parameter integer LED_COUNT_BIT = 25
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       uart_rx_i,
    output wire       uart_tx_o,
    output wire [3:0] led_o
);

    wire [COUNTER_WIDTH-1:0] count;
    wire [7:0] rx_data;
    wire       rx_valid;
    wire       rx_framing_error;
    wire       tx_busy;

    reg  [7:0] tx_data;
    reg        tx_start;
    reg        uart_seen;
    reg  [7:0] pending_data;
    reg        pending_valid;
    reg        overflow;

    counter #(
        .WIDTH(COUNTER_WIDTH)
    ) u_counter (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (1'b1),
        .count (count)
    );

    uart_rx #(
        .CLK_HZ(CLK_HZ),
        .BAUD  (BAUD)
    ) u_uart_rx (
        .clk             (clk),
        .rst_n           (rst_n),
        .rx_i            (uart_rx_i),
        .data_o          (rx_data),
        .data_valid_o    (rx_valid),
        .framing_error_o (rx_framing_error)
    );

    uart_tx #(
        .CLK_HZ(CLK_HZ),
        .BAUD  (BAUD)
    ) u_uart_tx (
        .clk          (clk),
        .rst_n        (rst_n),
        .data_i       (tx_data),
        .data_valid_i (tx_start),
        .tx_o         (uart_tx_o),
        .busy_o       (tx_busy)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data <= 8'h00;
            tx_start <= 1'b0;
            uart_seen <= 1'b0;
            pending_data <= 8'h00;
            pending_valid <= 1'b0;
            overflow <= 1'b0;
        end else begin
            tx_start <= 1'b0;

            if (pending_valid && !tx_busy && !tx_start) begin
                tx_data <= pending_data;
                tx_start <= 1'b1;
                pending_valid <= 1'b0;
            end

            if (rx_valid) begin
                uart_seen <= 1'b1;
                if (!pending_valid || (!tx_busy && !tx_start)) begin
                    pending_data <= rx_data;
                    pending_valid <= 1'b1;
                end else begin
                    overflow <= 1'b1;
                end
            end

            if (rx_framing_error)
                overflow <= 1'b1;
        end
    end

    assign led_o[0] = count[LED_COUNT_BIT];
    assign led_o[1] = uart_seen;
    assign led_o[2] = tx_busy;
    assign led_o[3] = 1'b0;

endmodule
