`timescale 1ns / 1ps

module tb_board_smoke;

    localparam integer CLK_HZ = 100000000;
    localparam integer BAUD = 1000000;
    localparam integer CLK_NS = 10;
    localparam integer BIT_NS = 1000000000 / BAUD;

    reg        clk = 1'b0;
    reg        rst_n = 1'b0;
    reg        uart_rx_i = 1'b1;
    wire       uart_tx_o;
    wire [3:0] led_o;
    reg  [7:0] received;
    integer    checks = 0;
    integer    errors = 0;
    integer    i;

    smoke_top #(
        .CLK_HZ          (CLK_HZ),
        .BAUD            (BAUD),
        .COUNTER_WIDTH   (8),
        .LED_COUNT_BIT   (2)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .uart_rx_i (uart_rx_i),
        .uart_tx_o (uart_tx_o),
        .led_o     (led_o)
    );

    always #(CLK_NS / 2) clk = ~clk;

    task check;
        input condition;
        input [255:0] name;
        begin
            checks = checks + 1;
            if (!condition) begin
                errors = errors + 1;
                $display("FAIL @%0t: %0s", $time, name);
            end
        end
    endtask

    task send_uart_byte;
        input [7:0] value;
        begin
            uart_rx_i = 1'b0;
            #(BIT_NS);
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx_i = value[i];
                #(BIT_NS);
            end
            uart_rx_i = 1'b1;
            #(BIT_NS);
        end
    endtask

    task receive_uart_byte;
        output [7:0] value;
        integer bit_index;
        begin
            @(negedge uart_tx_o);
            #(BIT_NS + BIT_NS / 2);
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                value[bit_index] = uart_tx_o;
                #(BIT_NS);
            end
            check(uart_tx_o === 1'b1, "UART stop bit is high");
        end
    endtask

    task expect_echo;
        input [7:0] value;
        begin
            fork
                send_uart_byte(value);
                receive_uart_byte(received);
            join
            check(received === value, "UART echoed byte matches");
        end
    endtask

    initial begin
        repeat (4) @(negedge clk);
        check(uart_tx_o === 1'b1, "UART TX idle during reset");
        check(led_o === 4'b0000, "LED reset value");
        rst_n = 1'b1;
        repeat (4) @(negedge clk);
        check(led_o[3] === 1'b0, "reserved LED stays low");

        expect_echo(8'h00);
        expect_echo(8'h55);
        expect_echo(8'hAA);
        expect_echo(8'hFF);
        check(led_o[1] === 1'b1, "UART activity LED is sticky");

        if (errors == 0)
            $display("PASS: %0d/%0d checks", checks, checks);
        else
            $display("FAIL: %0d errors in %0d checks", errors, checks);
        $finish;
    end

    initial begin
        #(2000000);
        $display("FAIL: timeout after %0d checks", checks);
        $finish;
    end

endmodule
