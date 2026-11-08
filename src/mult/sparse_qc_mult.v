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

    localparam integer WORDS     = (N + 63) / 64;
    localparam integer ACC_WORDS = 2 * WORDS;
    localparam integer QN        = N / 64;
    localparam integer SN        = N % 64;

    localparam [63:0] LAST_MASK = (SN == 0)
                                ? 64'hFFFFFFFFFFFFFFFF
                                : ((64'd1 << SN) - 64'd1);

    localparam [2:0] S_IDLE    = 3'd0;
    localparam [2:0] S_CLEAR   = 3'd1;
    localparam [2:0] S_COMPUTE = 3'd2;
    localparam [2:0] S_FOLD    = 3'd3;
    localparam [2:0] S_DONE    = 3'd4;

    reg [63:0] dense_mem [0:WORDS-1];
    reg [63:0] acc_mem   [0:ACC_WORDS-1];
    reg [63:0] prod_mem  [0:WORDS-1];
    reg [15:0] pos_mem   [0:W-1];

    reg [2:0]  state;
    integer    clear_idx;
    integer    pos_idx;
    integer    src_idx;
    integer    fold_idx;
    reg        half;

    reg [15:0] p;
    reg [15:0] q;
    reg [5:0]  s;
    integer    dest;
    reg [63:0] shift_lo;
    reg [63:0] shift_hi;
    reg [63:0] folded;

    always @* begin
        p = pos_mem[pos_idx];
        q = p >> 6;
        s = p[5:0];
        dest = src_idx + q;
        if (s == 6'd0) begin
            shift_lo = dense_mem[src_idx];
            shift_hi = 64'd0;
        end else begin
            shift_lo = dense_mem[src_idx] << s;
            shift_hi = dense_mem[src_idx] >> (64 - s);
        end
    end

    always @* begin
        if (SN == 0) begin
            folded = acc_mem[fold_idx + QN];
        end else begin
            folded = (acc_mem[fold_idx + QN] >> SN)
                   | (acc_mem[fold_idx + QN + 1] << (64 - SN));
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
            src_idx   <= 0;
            fold_idx  <= 0;
            half      <= 1'b0;
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
                        src_idx   <= 0;
                        fold_idx  <= 0;
                        half      <= 1'b0;
                        state     <= S_CLEAR;
                    end
                end

                S_CLEAR: begin
                    acc_mem[clear_idx] <= 64'd0;
                    if (clear_idx == (ACC_WORDS - 1)) begin
                        clear_idx <= 0;
                        state     <= S_COMPUTE;
                    end else begin
                        clear_idx <= clear_idx + 1;
                    end
                end

                S_COMPUTE: begin
                    if (half == 1'b0) begin
                        acc_mem[dest] <= acc_mem[dest] ^ shift_lo;
                        if (s != 6'd0) begin
                            half <= 1'b1;
                        end
                    end else begin
                        acc_mem[dest + 1] <= acc_mem[dest + 1] ^ shift_hi;
                        half <= 1'b0;
                    end

                    if ((half == 1'b1) || (s == 6'd0)) begin
                        if (src_idx == (WORDS - 1)) begin
                            src_idx <= 0;
                            if (pos_idx == (W - 1)) begin
                                state <= S_FOLD;
                            end else begin
                                pos_idx <= pos_idx + 1;
                            end
                        end else begin
                            src_idx <= src_idx + 1;
                        end
                    end
                end

                S_FOLD: begin
                    if (fold_idx == (WORDS - 1)) begin
                        prod_mem[fold_idx] <= (acc_mem[fold_idx] ^ folded) & LAST_MASK;
                        fold_idx <= 0;
                        state    <= S_DONE;
                    end else begin
                        prod_mem[fold_idx] <= acc_mem[fold_idx] ^ folded;
                        fold_idx <= fold_idx + 1;
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
