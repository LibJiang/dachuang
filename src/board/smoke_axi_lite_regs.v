`timescale 1ns / 1ps

module smoke_axi_lite_regs (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,

    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,

    input  wire [31:0] counter_i,
    input  wire        uart_seen_i,
    input  wire        uart_busy_i,
    input  wire        overflow_i
);

    localparam [1:0] AXI_OKAY = 2'b00;
    localparam [1:0] AXI_SLVERR = 2'b10;

    reg [31:0] scratch_reg;
    reg [31:0] awaddr_hold;
    reg [31:0] wdata_hold;
    reg [3:0]  wstrb_hold;
    reg        aw_hold;
    reg        w_hold;

    integer byte_index;

    assign s_axi_awready = !aw_hold && !s_axi_bvalid;
    assign s_axi_wready = !w_hold && !s_axi_bvalid;
    assign s_axi_arready = !s_axi_rvalid;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            scratch_reg <= 32'h00000000;
            awaddr_hold <= 32'h00000000;
            wdata_hold <= 32'h00000000;
            wstrb_hold <= 4'b0000;
            aw_hold <= 1'b0;
            w_hold <= 1'b0;
            s_axi_bresp <= AXI_OKAY;
            s_axi_bvalid <= 1'b0;
        end else begin
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            if (s_axi_awvalid && s_axi_awready) begin
                awaddr_hold <= s_axi_awaddr;
                aw_hold <= 1'b1;
            end

            if (s_axi_wvalid && s_axi_wready) begin
                wdata_hold <= s_axi_wdata;
                wstrb_hold <= s_axi_wstrb;
                w_hold <= 1'b1;
            end

            if (aw_hold && w_hold && !s_axi_bvalid) begin
                s_axi_bresp <= AXI_SLVERR;
                if (awaddr_hold == 32'h00000004) begin
                    for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1) begin
                        if (wstrb_hold[byte_index])
                            scratch_reg[byte_index*8 +: 8] <= wdata_hold[byte_index*8 +: 8];
                    end
                    s_axi_bresp <= AXI_OKAY;
                end
                aw_hold <= 1'b0;
                w_hold <= 1'b0;
                s_axi_bvalid <= 1'b1;
            end
        end
    end

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_rdata <= 32'h00000000;
            s_axi_rresp <= AXI_OKAY;
            s_axi_rvalid <= 1'b0;
        end else begin
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;

            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rdata <= 32'h00000000;
                s_axi_rresp <= AXI_OKAY;
                s_axi_rvalid <= 1'b1;
                case (s_axi_araddr)
                    32'h00000000: s_axi_rdata <= 32'h534D4F4B;
                    32'h00000004: s_axi_rdata <= scratch_reg;
                    32'h00000008: s_axi_rdata <= counter_i;
                    32'h0000000C: s_axi_rdata <= {
                        29'd0, overflow_i, uart_busy_i, uart_seen_i
                    };
                    32'h00000010: s_axi_rdata <= 32'h00000000;
                    default: begin
                        s_axi_rdata <= 32'h00000000;
                        s_axi_rresp <= AXI_SLVERR;
                    end
                endcase
            end
        end
    end

endmodule
