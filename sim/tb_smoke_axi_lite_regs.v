`timescale 1ns / 1ps

module tb_smoke_axi_lite_regs;

    reg         clk = 1'b0;
    reg         rst_n = 1'b0;
    reg  [31:0] awaddr = 32'd0;
    reg         awvalid = 1'b0;
    wire        awready;
    reg  [31:0] wdata = 32'd0;
    reg  [3:0]  wstrb = 4'd0;
    reg         wvalid = 1'b0;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready = 1'b0;
    reg  [31:0] araddr = 32'd0;
    reg         arvalid = 1'b0;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready = 1'b0;
    reg  [31:0] counter_i = 32'h12345678;
    reg         uart_seen_i = 1'b0;
    reg         uart_busy_i = 1'b0;
    reg         overflow_i = 1'b0;
    integer     checks = 0;
    integer     errors = 0;

    smoke_axi_lite_regs dut (
        .s_axi_aclk      (clk),
        .s_axi_aresetn   (rst_n),
        .s_axi_awaddr    (awaddr),
        .s_axi_awvalid   (awvalid),
        .s_axi_awready   (awready),
        .s_axi_wdata     (wdata),
        .s_axi_wstrb     (wstrb),
        .s_axi_wvalid    (wvalid),
        .s_axi_wready    (wready),
        .s_axi_bresp     (bresp),
        .s_axi_bvalid    (bvalid),
        .s_axi_bready    (bready),
        .s_axi_araddr    (araddr),
        .s_axi_arvalid   (arvalid),
        .s_axi_arready   (arready),
        .s_axi_rdata     (rdata),
        .s_axi_rresp     (rresp),
        .s_axi_rvalid    (rvalid),
        .s_axi_rready    (rready),
        .counter_i       (counter_i),
        .uart_seen_i     (uart_seen_i),
        .uart_busy_i     (uart_busy_i),
        .overflow_i      (overflow_i)
    );

    always #5 clk = ~clk;

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

    task send_aw;
        input [31:0] address;
        begin
            awaddr = address;
            awvalid = 1'b1;
            while (!awready)
                @(negedge clk);
            @(negedge clk);
            awvalid = 1'b0;
        end
    endtask

    task send_w;
        input [31:0] value;
        input [3:0] strobe;
        begin
            wdata = value;
            wstrb = strobe;
            wvalid = 1'b1;
            while (!wready)
                @(negedge clk);
            @(negedge clk);
            wvalid = 1'b0;
        end
    endtask

    task axi_write;
        input [31:0] address;
        input [31:0] value;
        input [3:0] strobe;
        input aw_first;
        input [1:0] expected_response;
        begin
            @(negedge clk);
            bready = 1'b0;
            if (aw_first) begin
                send_aw(address);
                send_w(value, strobe);
            end else begin
                send_w(value, strobe);
                send_aw(address);
            end
            while (!bvalid)
                @(negedge clk);
            check(bresp === expected_response, "AXI write response");
            repeat (2) begin
                @(negedge clk);
                check(bvalid && bresp === expected_response,
                      "AXI write response held under backpressure");
            end
            bready = 1'b1;
            @(negedge clk);
            bready = 1'b0;
        end
    endtask

    task axi_read;
        input [31:0] address;
        input [31:0] expected_data;
        input [1:0] expected_response;
        begin
            @(negedge clk);
            araddr = address;
            arvalid = 1'b1;
            rready = 1'b0;
            while (!arready)
                @(negedge clk);
            @(negedge clk);
            arvalid = 1'b0;
            while (!rvalid)
                @(negedge clk);
            check(rresp === expected_response, "AXI read response");
            check(rdata === expected_data, "AXI read data");
            repeat (2) begin
                @(negedge clk);
                check(rvalid && rresp === expected_response,
                      "AXI read response held under backpressure");
                check(rdata === expected_data,
                      "AXI read data held under backpressure");
            end
            rready = 1'b1;
            @(negedge clk);
            rready = 1'b0;
        end
    endtask

    initial begin
        repeat (4) @(negedge clk);
        check(!bvalid && !rvalid, "responses clear during reset");
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        axi_read(32'h00000000, 32'h534D4F4B, 2'b00);
        axi_read(32'h00000004, 32'h00000000, 2'b00);

        axi_write(32'h00000004, 32'hDEADBEEF, 4'b1111, 1'b1, 2'b00);
        axi_read(32'h00000004, 32'hDEADBEEF, 2'b00);

        axi_write(32'h00000004, 32'h11223344, 4'b0101, 1'b0, 2'b00);
        axi_read(32'h00000004, 32'hDE22BE44, 2'b00);

        axi_write(32'h00000000, 32'hFFFFFFFF, 4'b1111, 1'b1, 2'b10);
        axi_read(32'h00000000, 32'h534D4F4B, 2'b00);
        axi_read(32'h00000005, 32'h00000000, 2'b10);

        axi_read(32'h00000008, 32'h12345678, 2'b00);
        uart_seen_i = 1'b1;
        overflow_i = 1'b1;
        axi_read(32'h0000000C, 32'h00000005, 2'b00);
        axi_read(32'h00000010, 32'h00000000, 2'b00);

        if (errors == 0)
            $display("PASS: %0d/%0d checks", checks, checks);
        else
            $display("FAIL: %0d errors in %0d checks", errors, checks);
        $finish;
    end

    initial begin
        #100000;
        $display("FAIL: timeout after %0d checks", checks);
        $finish;
    end

endmodule
