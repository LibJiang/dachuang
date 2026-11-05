`timescale 1ns / 1ps

module tb_counter;

    localparam WIDTH  = 8;
    localparam MAXVAL = (1 << WIDTH) - 1;

    reg              clk   = 1'b0;
    reg              rst_n = 1'b0;
    reg              en    = 1'b0;
    wire [WIDTH-1:0] count;

    integer          errors = 0;
    integer          checks = 0;
    integer          i;
    reg [WIDTH-1:0]  expected;

    counter #(.WIDTH(WIDTH)) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (en),
        .count (count)
    );

    always #5 clk = ~clk;

    task check;
        begin
            checks = checks + 1;
            if (count !== expected) begin
                errors = errors + 1;
                $display("FAIL @%0t: count=%0d expected=%0d", $time, count, expected);
            end
        end
    endtask

    initial begin
        rst_n = 1'b0;
        en    = 1'b0;
        expected = 0;
        @(negedge clk);
        check;

        rst_n = 1'b1;
        for (i = 0; i < 300; i = i + 1) begin
            en = 1'b1;
            expected = (expected == MAXVAL) ? 0 : expected + 1'b1;
            @(negedge clk);
            check;
        end

        for (i = 0; i < 100; i = i + 1) begin
            en = 1'b0;
            @(negedge clk);
            check;
        end

        for (i = 0; i < 1024; i = i + 1) begin
            en = $random;
            if (en)
                expected = (expected == MAXVAL) ? 0 : expected + 1'b1;
            @(negedge clk);
            check;
        end

        rst_n = 1'b0;
        en    = 1'b1;
        @(negedge clk);
        expected = 0;
        check;
        rst_n = 1'b1;

        if (errors == 0)
            $display("PASS: %0d/%0d checks", checks, checks);
        else
            $display("FAIL: %0d errors in %0d checks", errors, checks);

        $finish;
    end

endmodule
