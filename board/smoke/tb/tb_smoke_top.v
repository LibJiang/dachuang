`timescale 1ns / 1ps

// AC701 board smoke testbench
// - DUT: smoke_top (RTL line provides)
// - UART: 115200 8N1, idle high, expect "SMOKE_PASS"
// - LED must change at least once
// - 200 MHz differential system clock
module tb_smoke_top;

    localparam integer CLK_HZ       = 200_000_000;
    localparam integer BAUD         = 115200;
    localparam integer CLKS_PER_BIT = CLK_HZ / BAUD; // 1736
    localparam integer HALF_BIT     = CLKS_PER_BIT / 2;

    reg         sys_clk_p;
    wire        sys_clk_n;
    reg         rst;
    wire [3:0]  led;
    wire        uart_txd;
    reg         uart_rxd;

    integer     errors;
    integer     rx_index;
    reg [7:0]   expected [0:9];
    reg [7:0]   rx_byte;
    reg         pass_seen;
    reg         led_changed;
    reg [3:0]   led_prev;

    assign sys_clk_n = ~sys_clk_p;

    smoke_top dut (
        .sys_clk_p (sys_clk_p),
        .sys_clk_n (sys_clk_n),
        .rst       (rst),
        .led       (led),
        .uart_txd  (uart_txd),
        .uart_rxd  (uart_rxd)
    );

    // 200 MHz: 5 ns period
    initial begin
        sys_clk_p = 1'b0;
        forever #2.5 sys_clk_p = ~sys_clk_p;
    end

    // UART receiver: sample at bit center, LSB first
    task uart_rx_byte;
        output [7:0] data;
        integer k;
        begin
            @(negedge uart_txd); // start bit
            repeat (HALF_BIT) @(posedge sys_clk_p);
            for (k = 0; k < 8; k = k + 1) begin
                repeat (CLKS_PER_BIT) @(posedge sys_clk_p);
                data[k] = uart_txd;
            end
            repeat (CLKS_PER_BIT) @(posedge sys_clk_p);
            if (uart_txd !== 1'b1) begin
                $display("FAIL: UART stop bit is not high at %0t", $time);
                errors = errors + 1;
            end
        end
    endtask

    // Track LED activity
    always @(posedge sys_clk_p) begin
        if (led !== led_prev) begin
            led_changed <= 1'b1;
            led_prev    <= led;
        end
    end

    initial begin
        errors     = 0;
        rx_index   = 0;
        pass_seen  = 1'b0;
        led_changed = 1'b0;
        led_prev   = 4'b0000;
        rst        = 1'b1;
        uart_rxd   = 1'b1;

        // "SMOKE_PASS"
        expected[0] = 8'h53; // S
        expected[1] = 8'h4D; // M
        expected[2] = 8'h4F; // O
        expected[3] = 8'h4B; // K
        expected[4] = 8'h45; // E
        expected[5] = 8'h5F; // _
        expected[6] = 8'h50; // P
        expected[7] = 8'h41; // A
        expected[8] = 8'h53; // S
        expected[9] = 8'h53; // S

        repeat (20) @(posedge sys_clk_p);
        rst = 1'b0;

        forever begin
            uart_rx_byte(rx_byte);

            if (rx_byte == expected[rx_index]) begin
                if (rx_index == 9) begin
                    pass_seen = 1'b1;
                end else begin
                    rx_index = rx_index + 1;
                end
            end else begin
                rx_index = 0;
                if (rx_byte == expected[0]) begin
                    rx_index = 1;
                end
            end

            if (pass_seen) begin
                if (!led_changed) begin
                    $display("FAIL: no LED change");
                    errors = errors + 1;
                end
                if (errors == 0) begin
                    $display("PASS: smoke UART SMOKE_PASS + LED");
                end else begin
                    $display("FAIL: errors=%0d", errors);
                end
                $finish;
            end
        end
    end

    // 10 ms timeout at 200 MHz
    initial begin
        #10_000_000;
        if (!pass_seen) begin
            $display("FAIL: timeout waiting for SMOKE_PASS");
            $finish;
        end
    end

endmodule
