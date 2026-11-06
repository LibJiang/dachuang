`timescale 1ns / 1ps

module tb_sparse_qc_mult;

    localparam integer N = 64;
    localparam integer W = 3;

    reg               clk = 1'b0;
    reg               rst_n = 1'b0;
    reg               start = 1'b0;
    wire              busy;
    wire              done;
    wire              error;

    reg               dense_we = 1'b0;
    reg  [15:0]       dense_addr = 16'd0;
    reg  [63:0]       dense_wdata = 64'd0;

    reg               pos_we = 1'b0;
    reg  [7:0]        pos_addr = 8'd0;
    reg  [15:0]       pos_wdata = 16'd0;

    reg  [15:0]       prod_addr = 16'd0;
    wire [63:0]       prod_rdata;

    integer           checks = 0;
    integer           errors = 0;
    integer           timeout;

    sparse_qc_mult #(
        .N(N),
        .W(W),
        .LANES(1)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .done(done),
        .error(error),
        .dense_we(dense_we),
        .dense_addr(dense_addr),
        .dense_wdata(dense_wdata),
        .pos_we(pos_we),
        .pos_addr(pos_addr),
        .pos_wdata(pos_wdata),
        .prod_addr(prod_addr),
        .prod_rdata(prod_rdata)
    );

    always #5 clk = ~clk;

    task write_dense(input [15:0] addr, input [63:0] data);
        begin
            @(negedge clk);
            dense_we = 1'b1;
            dense_addr = addr;
            dense_wdata = data;
            @(negedge clk);
            dense_we = 1'b0;
        end
    endtask

    task write_pos(input [7:0] addr, input [15:0] data);
        begin
            @(negedge clk);
            pos_we = 1'b1;
            pos_addr = addr;
            pos_wdata = data;
            @(negedge clk);
            pos_we = 1'b0;
        end
    endtask

    task start_dut;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task wait_done;
        begin
            timeout = 0;
            while (!done && (timeout < 1000)) begin
                @(negedge clk);
                timeout = timeout + 1;
            end
            if (!done) begin
                $display("FAIL: timeout waiting for done");
                errors = errors + 1;
            end
        end
    endtask

    task check_case(
        input [63:0] dense,
        input [15:0] p0,
        input [15:0] p1,
        input [15:0] p2,
        input [63:0] expected
    );
        begin
            write_dense(16'd0, dense);
            write_pos(8'd0, p0);
            write_pos(8'd1, p1);
            write_pos(8'd2, p2);
            start_dut;
            wait_done;
            checks = checks + 1;
            if (prod_rdata !== expected) begin
                errors = errors + 1;
                $display("FAIL: dense=%h pos=%0d,%0d,%0d got=%h expected=%h",
                         dense, p0, p1, p2, prod_rdata, expected);
            end else begin
                $display("PASS: dense=%h pos=%0d,%0d,%0d -> %h",
                         dense, p0, p1, p2, prod_rdata);
            end
        end
    endtask

    initial begin
        prod_addr = 16'd0;
        rst_n = 1'b0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        check_case(64'h0000_0000_0000_0001, 16'd0, 16'd1, 16'd63, 64'h8000_0000_0000_0003);
        check_case(64'hFFFF_FFFF_FFFF_FFFF, 16'd0, 16'd1, 16'd63, 64'hFFFF_FFFF_FFFF_FFFF);
        check_case(64'h0000_0000_0000_0000, 16'd0, 16'd1, 16'd63, 64'h0000_0000_0000_0000);
        check_case(64'h0000_0000_0000_0001, 16'd5, 16'd6, 16'd7, 64'h0000_0000_0000_00E0);

        if (errors == 0) begin
            $display("PASS: %0d/%0d checks", checks, checks);
        end else begin
            $display("FAIL: %0d errors in %0d checks", errors, checks);
        end
        $finish;
    end

endmodule
