`timescale 1ns / 1ps

module sparse_qc_mult #(
    parameter integer N     = 64,
    parameter integer W     = 3,
    parameter integer LANES = 1
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        start,
    output reg         busy,
    output reg         done,
    output reg         error,

    input  wire        dense_we,
    input  wire [15:0] dense_addr,
    input  wire [63:0] dense_wdata,

    input  wire        pos_we,
    input  wire [7:0]  pos_addr,
    input  wire [15:0] pos_wdata,

    input  wire [15:0] prod_addr,
    output reg  [63:0] prod_rdata
);

    localparam integer WORDS = (N + 63) / 64;

    localparam [1:0] S_IDLE    = 2'd0;
    localparam [1:0] S_CLEAR   = 2'd1;
    localparam [1:0] S_COMPUTE = 2'd2;
    localparam [1:0] S_DONE    = 2'd3;

    reg [63:0] dense_mem [0:WORDS-1];
    reg [63:0] prod_mem  [0:WORDS-1];
    reg [15:0] pos_mem   [0:W-1];

    reg [1:0]  state;
    integer    clear_idx;
    integer    pos_idx;
    integer    word_idx;
    integer    i;

    reg [15:0] p;
    reg [15:0] q;
    reg [5:0]  s;
    integer    a;
    integer    prev;
    reg [63:0] shifted;

    always @* begin
        p = pos_mem[pos_idx];
        q = p >> 6;
        s = p[5:0];
        a = word_idx - q;
        if (a < 0) begin
            a = a + WORDS;
        end
        prev = (a == 0) ? (WORDS - 1) : (a - 1);
        if (s == 6'd0) begin
            shifted = dense_mem[a];
        end else begin
            shifted = (dense_mem[a] << s) | (dense_mem[prev] >> (64 - s));
        end
    end

    always @* begin
        prod_rdata = prod_mem[prod_addr];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            busy      <= 1'b0;
            done      <= 1'b0;
            error     <= 1'b0;
            clear_idx <= 0;
            pos_idx   <= 0;
            word_idx  <= 0;
            for (i = 0; i < WORDS; i = i + 1) begin
                prod_mem[i] <= 64'd0;
            end
        end else begin
            done <= 1'b0;

            if (dense_we && !busy && (dense_addr < WORDS)) begin
                dense_mem[dense_addr] <= dense_wdata;
            end
            if (pos_we && !busy && (pos_addr < W)) begin
                pos_mem[pos_addr] <= pos_wdata;
            end

            case (state)
                S_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        busy      <= 1'b1;
                        clear_idx <= 0;
                        pos_idx   <= 0;
                        word_idx  <= 0;
                        state     <= S_CLEAR;
                    end
                end

                S_CLEAR: begin
                    prod_mem[clear_idx] <= 64'd0;
                    if (clear_idx == (WORDS - 1)) begin
                        clear_idx <= 0;
                        state     <= S_COMPUTE;
                    end else begin
                        clear_idx <= clear_idx + 1;
                    end
                end

                S_COMPUTE: begin
                    prod_mem[word_idx] <= prod_mem[word_idx] ^ shifted;
                    if (word_idx == (WORDS - 1)) begin
                        word_idx <= 0;
                        if (pos_idx == (W - 1)) begin
                            state <= S_DONE;
                        end else begin
                            pos_idx <= pos_idx + 1;
                        end
                    end else begin
                        word_idx <= word_idx + 1;
                    end
                end

                S_DONE: begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
