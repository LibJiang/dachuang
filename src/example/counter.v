`timescale 1ns / 1ps

module counter #(
    parameter WIDTH  = 8,
    parameter MAXVAL = (1 << WIDTH) - 1
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             en,
    output reg  [WIDTH-1:0] count
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= {WIDTH{1'b0}};
        else if (en)
            count <= (count == MAXVAL) ? {WIDTH{1'b0}} : count + 1'b1;
    end

endmodule
