`timescale 1ns / 1ps

// AC701-only wrapper; clock primitives stay outside portable smoke RTL.
// Pins and 200 MHz clock follow Jiang's board/smoke/constraints/ac701_smoke.xdc.
module ac701_smoke_top (
    input  wire       sys_clk_p,
    input  wire       sys_clk_n,
    input  wire       rst,
    input  wire       uart_rxd,
    output wire       uart_txd,
    output wire [3:0] led
);
    wire clk_unbuffered;
    wire clk;
    wire rst_n;
    // Asynchronous assertion, two-clock synchronous release.
    (* ASYNC_REG = "TRUE" *) reg [1:0] reset_release;

    IBUFDS u_ibufds (
        .I(sys_clk_p), .IB(sys_clk_n), .O(clk_unbuffered)
    );
    BUFG u_bufg (.I(clk_unbuffered), .O(clk));

    always @(posedge clk or posedge rst) begin
        if (rst)
            reset_release <= 2'b00;
        else
            reset_release <= {reset_release[0], 1'b1};
    end
    assign rst_n = reset_release[1];

    smoke_top #(
        .CLK_HZ(200000000), .BAUD(115200),
        .COUNTER_WIDTH(32), .LED_COUNT_BIT(25)
    ) u_smoke (
        .clk(clk), .rst_n(rst_n),
        .uart_rx_i(uart_rxd), .uart_tx_o(uart_txd), .led_o(led)
    );
endmodule
